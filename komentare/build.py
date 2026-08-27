#!/usr/bin/env python3
"""
Build meta-analysis.cz/komentare/ — Czech-language publicistika in three sections.

    /komentare/              hub, every item, filterable
    /komentare/celostatni/   national op-eds
    /komentare/litomysl/     Lilie columns (Litomyšl municipal monthly)
    /komentare/rozhovory/    interviews
    /komentare/<slug>/       one page per text item
    /komentare/feed.xml      RSS, full text

Reads komentare/src/*.md — YAML-ish frontmatter plus body.

Frontmatter
    outlet      required   "Hospodářské noviny", "Lilie", "CzechCrunch", …
    date        required   YYYY-MM-DD  (Lilie: first of the issue month)
    headline    required
    category               celostatni | litomysl | rozhovory | english
                           (default celostatni)
    genre                  "press_release" — files under celostatni but is not an
                           op-ed: Article rather than OpinionNewsArticle, and its
                           provenance line reads "rozeslaná redakcím"
    media                  text | video | audio                (default text)
    url                    link to the original
    byline                 comma-separated; every name is credited
    interviewer            for rozhovory
    issue                  for Lilie, e.g. "2025/10"
    date_precision         "month" when only the issue month is known
    body_note              rendered as an editorial note above the text
    mirror                 slug of a second copy at /notes/<slug>/ (English research
                           writing is published in both places); points rel=canonical
                           and og:url there. Maintained by redesign/sync_notes.py.
    written_by             who wrote a reported piece the author only speaks in
    written_by_type        "Person" when written_by names a journalist, not a newsroom
    audio_url              a broadcast/podcast version of a text interview; linked
    audio_label            visible text for that link (default "podcast")

Design notes
  * The complete item list is in the HTML. JavaScript only filters what is already
    there — SeznamBot's JS rendering is experimental and Seznam is ~13% of Czech search.
  * video/audio items get a row with a link out, never a page of their own: a page
    whose only content is "here is a link" is thin content.
  * Schema is OpinionNewsArticle for op-eds, Article for interviews with an
    interviewee/interviewer pair. Never ScholarlyArticle — that is for the papers
    elsewhere on this domain.

No third-party dependencies.  python komentare/build.py
"""

import hashlib
import html
import io
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

KDIR = Path(__file__).resolve().parent
ROOT = KDIR.parent
SITE = "https://meta-analysis.cz"
# The canonical Person entities on the site root, keyed by ORCID. Every author node for
# the two owners points there, joining the Czech archive to the English research graph.
CANON_ID = {
    "https://orcid.org/0000-0002-3158-2539": f"{SITE}/#th",
    "https://orcid.org/0000-0002-0753-8124": f"{SITE}/#zi",
}
BASE = f"{SITE}/komentare"      # absolute: canonical, og:url, JSON-LD
PATH = "/komentare"             # root-relative: every internal link and asset

AUTHOR = "Tomáš Havránek"
# Whose archive this is. AUTHOR stays single: it is the default byline for items that
# name no author, so widening it would silently reassign every unattributed piece.
# The masthead carries her full form once, so readers who know her international
# byline "Irsova" can connect the two. Everywhere else she is as Czech media print her.
SITE_AUTHORS_TOP = "Tomáš Havránek, Zuzana Iršová Havránková"
SITE_AUTHORS = "Tomáš Havránek, Zuzana Havránková"
# One person can appear under several name forms: the married name in Czech outlets,
# the maiden name in English ones, with or without diacritics. Every form must map to
# the same ORCID or the author silently loses attribution on some items.
ORCIDS = {
    "Tomáš Havránek": "https://orcid.org/0000-0002-3158-2539",
    "Tomas Havranek": "https://orcid.org/0000-0002-3158-2539",
    "Zuzana Iršová Havránková": "https://orcid.org/0000-0002-0753-8124",
    "Zuzana Havránková": "https://orcid.org/0000-0002-0753-8124",
    "Zuzana Iršová": "https://orcid.org/0000-0002-0753-8124",
    "Zuzana Irsová": "https://orcid.org/0000-0002-0753-8124",
    "Zuzana Irsova": "https://orcid.org/0000-0002-0753-8124",
    # no byline uses this form today; the Posts pages print it, so a future byline
    # copied from there would otherwise land here with no ORCID and no Zuzana tag
    "Zuzana Irsova Havrankova": "https://orcid.org/0000-0002-0753-8124",
}

ZI_NAMES = {"Zuzana Iršová Havránková", "Zuzana Havránková", "Zuzana Iršová",
            "Zuzana Irsová", "Zuzana Irsova", "Zuzana Irsova Havrankova"}

SECTIONS = {
    "celostatni": dict(
        title="Celostátní komentáře",
        short="Celostátní",
        desc="Komentáře a sloupky pro celostátní média — měnová politika, inflace, "
             "veřejné finance, důchody a ceny energií. Patří sem i stanoviska "
             "poradce bankovní rady ČNB k situačním zprávám, která ČNB zveřejňuje "
             "po uplynutí šestileté lhůty omezeného přístupu, a dopisy, které "
             "nikde nevyšly.",
    ),
    "litomysl": dict(
        title="Litomyšlské sloupky",
        short="Litomyšl",
        desc="Především sloupky pro Lilii, měsíčník města Litomyšle — doprava, zeleň, "
             "školství, sport a další místní témata. Několik textů vyšlo jinde v "
             "Litomyšli: na webu ZŠ Zámecká a v participativním rozpočtu města.",
    ),
    "rozhovory": dict(
        title="Rozhovory",
        short="Rozhovory",
        desc="Rozhovory pro česká média. U audio a video rozhovorů uvádíme pouze odkaz "
             "na původní zdroj.",
        lang="cs",
    ),
    "english": dict(
        title="In English",
        short="English",
        desc="Columns and commentary written in English: policy pieces for VoxEU/CEPR, "
             "posts on meta-analysis methods for MAER-Net, and English translations of the "
             "advisor's opinions written for the Bank Board of the Czech National Bank.",
        lang="en",
    ),
}
for _k, _v in SECTIONS.items():
    _v.setdefault("lang", "cs")

HUB_DESC = ("Publicistika Tomáše Havránka a Zuzany Havránkové: komentáře pro celostátní média, sloupky pro "
            "litomyšlskou Lilii, rozhovory, stanoviska poradce bankovní rady ČNB "
            "a kratší příspěvky ze sítí. Texty jsou zde "
            "archivovány v plném znění s odkazem na původní vydání.")
# What the reader sees first. The sentence about full text and original sources is true
# and worth saying to a crawler, but it delays the actual list, so it stays in HUB_DESC
# (the meta description) and off the page.
# The feed carries the posts too, now that each has a page of its own rather than an
# anchor. It keeps its own wording only because the hub description says more about how
# the archive stores its texts than a channel blurb needs to.
FEED_DESC =("Publicistika Tomáše Havránka a Zuzany Havránkové: komentáře pro celostátní "
             "média, sloupky pro litomyšlskou Lilii, rozhovory a kratší příspěvky ze "
             "sítí, v plném znění.")
HUB_LEDE = ("Publicistika Tomáše Havránka a Zuzany Havránkové: komentáře pro celostátní "
            "média, sloupky pro litomyšlskou Lilii, rozhovory a kratší příspěvky ze sítí.")

# genitive, for a full date: "5. října 2019"
MONTHS = ["ledna", "února", "března", "dubna", "května", "června",
          "července", "srpna", "září", "října", "listopadu", "prosince"]
# nominative, for a month alone: "říjen 2019" — the genitive is wrong without a day
MONTHS_NOM = ["leden", "únor", "březen", "duben", "květen", "červen",
              "červenec", "srpen", "září", "říjen", "listopad", "prosinec"]

OUTLET_IN = {
    "Hospodářské noviny": "v Hospodářských novinách",
    "Seznam Zprávy": "na Seznam Zprávách",
    "Lilie": "v Lilii, měsíčníku města Litomyšle",
    "CzechCrunch": "na CzechCrunch",
    "Forbes": "ve Forbesu",
    "E15": "na E15",
    "iDNES.cz": "na iDNES.cz",
    "Roklen24": "na Roklen24",
    "Ekonomický magazín": "v Ekonomickém magazínu",
    "Ekonom": "v týdeníku Ekonom",
    "Věda na FSV UK (podcast De Facto)": "na webu Věda na FSV UK",
    "ZŠ Litomyšl, Zámecká": "na webu ZŠ Litomyšl, Zámecká",
    "Forbes NEXT": "ve Forbes NEXT",
    "Participativní rozpočet města Litomyšle": "v participativním rozpočtu města Litomyšle",
}

MEDIA_LABEL = {"video": "video", "audio": "audio"}

# Where a text was self-published rather than edited by an outlet. The archive mixes
# both, and a retrieval corpus should be able to tell them apart: an HN op-ed passed an
# editor, a manifesto on the author's own site did not.
SELF_PUBLISHED = re.compile(
    r"(?i)^(LinkedIn|MAER\-Net|Zrušme inflaci|zrusme\-inflaci|SYRI|KdoVyhrajeVolby\.cz)$")

# headlines carried by more than one item; filled in main(). Such items always show
# their byline so that two rows never render as the same link text.
DUP_HEADLINES = set()
BY_SLUG = {}

# How complete the stored text is. Derived from the item's own provenance note so
# that no source file has to repeat it, and so the machine-readable corpus never
# implies it holds a published text when it holds a draft or a teaser.
# Note: source == "image" means the text was read off a scanned page — still the
# published text, so it stays published_full_text. Only source == "draft" means the
# stored words are the author's version rather than what the outlet printed.
_EXCERPT_RE = re.compile(r"(?i)ukázka zveřejněná|úvodní ukázka")


def text_status(a):
    """published_full_text | author_manuscript | publisher_excerpt | link_only
    | unpublished_manuscript"""
    # Written and sent to the outlet, but never printed. Not the same as
    # author_manuscript, which is the author's version of something that DID run.
    if a.get("genre") == "correspondence":
        return "correspondence"
    if a.get("unpublished"):
        return "unpublished_manuscript"
    if a["media"] != "text":
        return "link_only"
    if _EXCERPT_RE.search(a.get("body_note") or ""):
        return "publisher_excerpt"
    if a.get("source") == "draft":
        return "author_manuscript"
    return "published_full_text"


# ----------------------------------------------------------------- helpers ---

def esc(s):
    return html.escape(s or "", quote=True)


def fix_quotes(s):
    """The Seznam extraction leg closed Czech „…“ pairs with an ASCII quote."""
    return re.sub(r'„([^„“"]{0,400}?)"', r"„\1“", s or "")


MONTHS_EN = ["January", "February", "March", "April", "May", "June",
             "July", "August", "September", "October", "November", "December"]


def cs_date(iso, precision=None, lang="cs"):
    """Czech months are inflected: genitive with a day, nominative alone. English
    items get English dates — a Czech genitive month is unreadable to that audience."""
    d = datetime.strptime(iso, "%Y-%m-%d")
    if lang == "en":
        return (f"{MONTHS_EN[d.month - 1]} {d.year}" if precision == "month"
                else f"{d.day} {MONTHS_EN[d.month - 1]} {d.year}")
    if precision == "month":
        return f"{MONTHS_NOM[d.month - 1]} {d.year}"
    return f"{d.day}. {MONTHS[d.month - 1]} {d.year}"


def rfc822(iso):
    return datetime.strptime(iso, "%Y-%m-%d").replace(tzinfo=timezone.utc) \
        .strftime("%a, %d %b %Y %H:%M:%S +0000")


# a trailing  cannot match after "z. s." because "." is not a word character
ORG_SUFFIX = re.compile(r"(?i)^(z\.\s?s\.|s\.\s?r\.\s?o\.|a\.\s?s\.|o\.\s?p\.\s?s\.|"
                        r"z\.\s?ú\.|spol\.\s?s\s?r\.\s?o\.)$")
ORG_WORD = re.compile(r"(?i)(spolek|institut|agentura|univerzita|redakce|fakulta|"
                      r"nakladatelstv[ií]|vydavatelstv[ií]|Pro\s+\w+)")


def people(raw):
    """Split a byline into names.

    Semicolons are authoritative. Commas are ambiguous: "Tomáš Havránek, Pro
    Litomyšl, z. s." is one person and one organisation, not three people. So a
    comma-separated fragment is joined back on when it is a legal-form suffix, or
    when the preceding fragment already looks like an organisation.
    """
    raw = (raw or AUTHOR).strip()
    if ";" in raw:
        return [n.strip() for n in raw.split(";") if n.strip()]
    parts = [p.strip() for p in re.split(r",| a ", raw) if p.strip()]
    out = []
    for p in parts:
        if out and (ORG_SUFFIX.match(p) or ORG_WORD.search(out[-1])):
            out[-1] = out[-1] + ", " + p
        else:
            out.append(p)
    return out or [AUTHOR]


# ---------------------------------------------------------------- markdown ---

def _inline(t):
    t = html.escape(t, quote=False)
    t = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', t)
    t = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", t)
    # An opening "*" must not be followed by whitespace — CommonMark's left-flanking
    # rule. Without it, a literal asterisk that belongs to the text opened an emphasis
    # span: "p-uniform* method. *Tilburg University …*" italicised " method. " and ate
    # the star in p-uniform*, which is part of the estimator's name. The closing rule
    # stays lax on purpose: the reference lists throughout the archive are written
    # "*Journal Name *2019", with a space before the closing star, and strict
    # CommonMark would leave every one of those asterisks visible to the reader.
    t = re.sub(r"(?<!\*)\*(?!\s)([^*]+)\*(?!\*)", r"<em>\1</em>", t)
    # Inline code was never handled, so a source written with backticks showed them to
    # the reader: `install.packages("MAIVE")` appeared literally, backticks and all.
    t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)
    return t


def md_to_html(md, figs=None):
    out, lines, i = [], (md or "").replace("\r\n", "\n").split("\n"), 0
    while i < len(lines):
        line = lines[i].rstrip()
        if not line.strip():
            i += 1
            continue
        # A chart caption becomes the figure it captions, in place. Without this the
        # charts sat in a block after the text, far from the paragraph that reads
        # "Chart 3 shows that...", or stayed in the PDF and not on the page at all.
        fm = FIG_CAPTION.match(line.strip()) if figs else None
        if fm and fm.group(2) in figs:
            f, alt = figs[fm.group(2)]
            out.append(figure_html(f, alt, fm.group(1)))
            i += 1
            continue
        m = re.match(r"^(#{2,4})\s+(.*)$", line)
        if m:
            lvl = min(len(m.group(1)), 4)
            out.append(f"<h{lvl}>{_inline(m.group(2))}</h{lvl}>")
            i += 1
            continue
        # Authors separate list items with a blank line ("loose list"), which every
        # Markdown implementation treats as ONE list. Ending the list at the first blank
        # line split them into a list per item — visibly wrong for numbered lists, which
        # restarted at 1 on every item, and wrong for a screen reader on bullet lists too.
        def _gather(is_item, strip_item):
            items, j = [], i
            while j < len(lines):
                if is_item(lines[j]):
                    items.append(f"<li>{_inline(strip_item(lines[j]))}</li>")
                    j += 1
                    continue
                if lines[j].strip() == "":
                    k = j
                    while k < len(lines) and lines[k].strip() == "":
                        k += 1
                    if k < len(lines) and is_item(lines[k]):
                        j = k
                        continue
                break
            return items, j

        if line.lstrip().startswith(("- ", "* ")):
            it, i = _gather(lambda l: l.lstrip().startswith(("- ", "* ")),
                            lambda l: l.lstrip()[2:].strip())
            out.append("<ul>\n" + "\n".join(it) + "\n</ul>")
            continue
        if re.match(r"^\s*\d+[.)]\s+", line):
            it, i = _gather(lambda l: bool(re.match(r"^\s*\d+[.)]\s+", l)),
                            lambda l: re.sub(r"^\s*\d+[.)]\s+", "", l).strip())
            out.append("<ol>\n" + "\n".join(it) + "\n</ol>")
            continue
        if line.lstrip().startswith("> "):
            # Same blank-line rule as the lists above: a quotation whose paragraphs are
            # separated by a blank line is ONE quotation. Ending at the first blank line
            # produced five adjacent <blockquote>s for one five-paragraph quote.
            paras, cur, j = [], [], i
            while j < len(lines):
                if lines[j].lstrip().startswith("> "):
                    cur.append(lines[j].lstrip()[2:].strip())
                    j += 1
                    continue
                if lines[j].strip() == "":
                    k = j
                    while k < len(lines) and lines[k].strip() == "":
                        k += 1
                    if k < len(lines) and lines[k].lstrip().startswith("> "):
                        if cur:
                            paras.append(" ".join(cur))
                            cur = []
                        j = k
                        continue
                break
            if cur:
                paras.append(" ".join(cur))
            i = j
            inner = "".join(f"<p>{_inline(p)}</p>" for p in paras)
            out.append(f"<blockquote>{inner}</blockquote>")
            continue
        para = []
        while (i < len(lines) and lines[i].strip()
               and not lines[i].lstrip().startswith(("#", "- ", "* ", "> "))
               and not re.match(r"^\s*\d+[.)]\s+", lines[i])):
            para.append(lines[i].strip())
            i += 1
        # A line that matched no branch above and is also excluded here -- a bare "##", a
        # lone "-", a hashtag -- left `para` empty and `i` unmoved: an infinite loop that
        # hung the whole build with no error and no output. It cost a debugging round when
        # a converted CNB document happened to contain one. Always make progress.
        if not para:
            para.append(lines[i].strip())
            i += 1
        out.append(f"<p>{_inline(' '.join(para))}</p>")
    return "\n".join(out)


# ------------------------------------------------------------------ parsing ---

def parse(path):
    raw = io.open(path, encoding="utf-8-sig").read()
    m = re.match(r"---\s*\n(.*?)\n---\s*\n(.*)$", raw, re.S)
    if not m:
        sys.exit(f"error: no frontmatter in {path.name}")
    a = {}
    for line in m.group(1).split("\n"):
        if ":" not in line:
            continue
        k, v = line.split(":", 1)
        v = v.strip()
        if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
            v = v[1:-1]
        close = "“" if "„" in v else '"'
        v = re.sub(r'\\+"', close, v)
        a[k.strip()] = v
    body = re.sub(r"^\s*#\s+.*?\n", "", m.group(2), count=1).strip()
    a["body"] = body
    a["slug"] = re.sub(r"^[0-9]{4}-[0-9]{2}(-[0-9]{2})?[_-]", "", path.stem)
    a["file"] = path.name
    a.setdefault("category", "celostatni")
    a.setdefault("media", "text")
    a["headline"] = fix_quotes(a.get("headline", ""))
    for req in ("date", "headline", "outlet"):
        if not a.get(req):
            sys.exit(f"error: {path.name} missing '{req}'")
    if a["category"] not in SECTIONS:
        sys.exit(f"error: {path.name} has unknown category '{a['category']}'")
    return a


# --------------------------------------------------------------- templates ---

def shell(title, desc, canonical, jsonld, body, active, extra_head="", lang="cs",
          canonical_link=None):
    # The chrome is Czech on every page, including the English and Slovak ones. WCAG
    # 3.1.2 wants those runs marked, or a screen reader reads them with the wrong
    # phonetics. Any non-Czech page needs the marking, not just the English ones.
    cs = ' lang="cs"' if lang != "cs" else ""
    nav = "".join(
        f'<a href="{PATH}/{k}/"'
        f'{"" if k == "english" else cs}'
        f'{" aria-current=\"page\"" if active == k else ""}>{esc(v["short"])}</a>'
        for k, v in SECTIONS.items())
    # Not a SECTION: the social posts are not src items, so a section entry would put an
    # empty chip on the hub filter. It gets a nav link and nothing else.
    nav += (f'<a href="{PATH}/posts/"'
            f'{" aria-current=\"page\"" if active == "posts" else ""}>Posts</a>')
    rss_title = f"Komentáře — {SITE_AUTHORS}"
    _en = lang == "en"
    ies = ("https://ies.fsv.cuni.cz/en/contacts/institute-members/78067720" if _en
           else "https://ies.fsv.cuni.cz/contacts/institute-members/78067720")
    ies_zi = ("https://ies.fsv.cuni.cz/en/contacts/institute-members/73504033" if _en
              else "https://ies.fsv.cuni.cz/contacts/institute-members/73504033")
    # one paragraph each, so neither author is a footnote to the other
    bio = (
        "<strong>Tomáš Havránek</strong> is Professor of Economics at the Institute of "
        "Economic Studies, Charles University, Prague. He works on monetary policy, "
        "meta-analysis and meta-research, and was an adviser to the Vice-Governor and "
        "the Board of the Czech National Bank. He is a Research Affiliate at CEPR (London) "
        "and at Stanford METRICS."
        "</p><p class=\"about-bio\">"
        "<strong>Zuzana Havránková</strong> is Professor of Economics at the same institute. "
        "She works on meta-analysis and meta-research, labour economics and international "
        "economics, and is an affiliate researcher at Stanford METRICS. She publishes in "
        "English as Zuzana Irsova."
        "</p><p class=\"about-bio\">"
        "This section archives their published commentary, columns and interviews."
        if _en else
        "<strong>Tomáš Havránek</strong> je profesor ekonomie na Institutu ekonomických "
        "studií FSV Univerzity Karlovy v Praze. Zabývá se měnovou politikou, metaanalýzou "
        "a metavýzkumem; byl poradcem viceguvernéra a bankovní rady ČNB. Je Research "
        "Affiliate v CEPR (Londýn) a ve Stanford METRICS."
        "</p><p class=\"about-bio\">"
        "<strong>Zuzana Havránková</strong> je profesorka ekonomie na témže institutu. "
        "Zabývá se metaanalýzou a metavýzkumem, ekonomií práce a mezinárodní ekonomií; "
        "je affiliate researcher ve Stanford METRICS. V angličtině publikuje jako "
        "Zuzana Irsova."
        "</p><p class=\"about-bio\">"
        "Tato stránka archivuje jejich publicistiku — komentáře, sloupky a rozhovory.")
    return f"""<!DOCTYPE html>
<html lang="{lang}">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>{esc(title)}</title>
<meta name="description" content="{esc(desc)}" />
<link rel="stylesheet" href="{PATH}/style.css" />
<link rel="canonical" href="{canonical_link or canonical}" />
<link rel="alternate" type="application/rss+xml" title="{rss_title}" href="{PATH}/feed.xml" />
<meta property="og:site_name" content="Komentáře — {SITE_AUTHORS}" />
<meta property="og:locale" content="{"en_GB" if lang == "en" else "cs_CZ"}" />
<meta property="og:title" content="{esc(title)}" />
<meta property="og:description" content="{esc(desc)}" />
<meta property="og:url" content="{canonical_link or canonical}" />
{extra_head}<script type="application/ld+json">
{json.dumps(jsonld, indent=1, ensure_ascii=False)}
</script>
<script>document.documentElement.className+=" has-js";</script>
</head>
<body>
<header class="masthead">
  <div class="wrap">
    <p class="site-name"><a href="{PATH}/">Komentáře<small>{SITE_AUTHORS_TOP}</small></a></p>
    <nav class="nav">{nav}</nav>
  </div>
</header>
<main>
  <div class="wrap">
{body}
  </div>
</main>
<footer class="foot">
  <div class="wrap about">
    <p class="about-bio">{bio}</p>
    <ul class="about-links">
      <li class="who">Tomáš Havránek</li>
      <li><a href="https://www.tomashavranek.cz/">tomashavranek.cz</a></li>
      <li><a href="{ies}">IES FSV UK</a></li>
      <li><a href="https://orcid.org/0000-0002-3158-2539">ORCID</a></li>
      <li><a href="https://scholar.google.com/citations?user=BF0BvBkAAAAJ">Google Scholar</a></li>
      <li><a href="https://ideas.repec.org/f/pha418.html">RePEc</a></li>
      <li><a href="https://www.scopus.com/authid/detail.uri?authorId=24453189000">Scopus</a></li>
      <li><a href="https://cepr.org/about/people/tomas-havranek">CEPR</a></li>
      <li><a href="https://metrics.stanford.edu/people/tomas-havranek">Stanford METRICS</a></li>
    </ul>
    <ul class="about-links">
      <li class="who">Zuzana Iršová Havránková</li>
      <li><a href="https://www.irsova.com/">irsova.com</a></li>
      <li><a href="{ies_zi}">IES FSV UK</a></li>
      <li><a href="https://orcid.org/0000-0002-0753-8124">ORCID</a></li>
      <li><a href="https://scholar.google.com/citations?user=LaHrICUAAAAJ">Google Scholar</a></li>
      <li><a href="https://ideas.repec.org/e/pir23.html">RePEc</a></li>
      <li><a href="https://www.scopus.com/authid/detail.uri?authorId=37080793200">Scopus</a></li>
      <li><a href="https://cepr.org/about/people/zuzana-irsova">CEPR</a></li>
      <li><a href="https://metrics.stanford.edu/people/zuzana-irsova">Stanford METRICS</a></li>
    </ul>
    <ul class="about-links">
      <li class="who">{"Projekty" if lang == "cs" else "Projects"}</li>
      <li><a href="{SITE}/">meta-analysis.cz</a></li>
      <li><a href="https://zrusme-inflaci.cz/">Zrušme inflaci</a></li>
      <li><a href="{PATH}/feed.xml">RSS</a></li>
    </ul>
    <p class="about-machine" lang="en">For machines:
      <a href="{PATH}/data/">the corpus</a> (JSONL, JSON, Markdown, checksums) ·
      <a href="{PATH}/llms.txt">llms.txt</a> ·
      <a href="{PATH}/index.json">index.json</a> (metadata for every item, full text where available) ·
      <a href="{PATH}/all.md">all.md</a> (every text in one file) ·
      <a href="{PATH}/feed.xml">RSS</a>. The Markdown source of each item is in
      <a href="{PATH}/src/">/komentare/src/</a>. Text and metadata may be freely
      indexed, quoted and used for research, with attribution to the original outlet.</p>
  </div>
</footer>
</body>
</html>
"""


FILTER = """    <div class="filter">
      <div class="filter-row js-only">
        <input type="search" id="q" placeholder="Hledat v titulcích, médiích a autorech…" aria-label="Hledat" />
        <button class="chip" data-cat="all" aria-pressed="true">Vše</button>
        <button class="chip" data-cat="celostatni" aria-pressed="false">Celostátní</button>
        <button class="chip" data-cat="litomysl" aria-pressed="false">Litomyšl</button>
        <button class="chip" data-cat="rozhovory" aria-pressed="false">Rozhovory</button>
        <button class="chip" data-cat="english" aria-pressed="false">English</button>
        <button class="chip" data-cat="zuzana" aria-pressed="false">Zuzana</button>
      </div>
      <p class="count js-only" id="count" role="status" aria-live="polite"></p>
      <p class="count js-only" id="zi-posts" hidden>Zuzana má navíc kratší příspěvky ze
        sítí, které tento seznam nevede: <a href="/komentare/posts/">všechny příspěvky</a>.</p>
    </div>
"""

SCRIPT = """<script>
(function () {
  var q = document.getElementById('q'), chips = document.querySelectorAll('.chip'),
      items = Array.prototype.slice.call(document.querySelectorAll('.item')),
      years = Array.prototype.slice.call(document.querySelectorAll('.year')),
      count = document.getElementById('count'), cat = 'all';
  function norm(s){return s.toLowerCase().normalize('NFD').replace(/[\\u0300-\\u036f]/g,'');}
  items.forEach(function(el){ el.dataset.hay = norm(el.textContent); });
  function apply() {
    var term = norm(q.value.trim()), n = 0;
    items.forEach(function (el) {
      var ok = (cat === 'all' ||
                (cat === 'zuzana' ? el.dataset.zi === '1' : el.dataset.cat === cat)) &&
               (!term || el.dataset.hay.indexOf(term) > -1);
      el.hidden = !ok; if (ok) n++;
    });
    years.forEach(function (h) {
      var vis = false, s = h.nextElementSibling;
      if (s) Array.prototype.forEach.call(s.children, function (li) { if (!li.hidden) vis = true; });
      h.hidden = !vis; if (s) s.hidden = !vis;
    });
    count.textContent = n + (n === 1 ? ' položka' : (n > 1 && n < 5 ? ' položky' : ' položek'));
    var zp = document.getElementById('zi-posts'); if (zp) zp.hidden = (cat !== 'zuzana');
  }
  q.addEventListener('input', apply);
  function select(c) {
    cat = c.dataset.cat;
    chips.forEach(function (o) { o.setAttribute('aria-pressed', o === c ? 'true' : 'false'); });
    apply();
  }
  chips.forEach(function (c) {
    c.addEventListener('click', function () { select(c); });
  });
  // A filter can be linked to: /komentare/?filtr=zuzana. Zuzana points at that from
  // her own site, so the link has to survive being shared. Without JS every item is
  // still in the HTML, so the link degrades to the full list rather than to nothing.
  var want = new URLSearchParams(location.search).get('filtr');
  var pre = want && Array.prototype.find.call(chips, function (c) {
    return c.dataset.cat === want;
  });
  if (pre) { select(pre); } else { apply(); }
})();
</script>
"""


def item_row(a, show_cat):
    lang = a.get("lang") or SECTIONS[a["category"]]["lang"]
    url = f"{PATH}/{a['slug']}/" if a["media"] == "text" else (a.get("url") or "#")
    ext = "" if a["media"] == "text" else ' rel="external"'
    tag = ""
    if a["media"] in MEDIA_LABEL:
        tag = f'<span class="tag tag-av">{MEDIA_LABEL[a["media"]]}</span>'
    elif show_cat:
        tag = f'<span class="tag">{esc(SECTIONS[a["category"]]["short"])}</span>'
    bits = [f'<span>{esc(cs_date(a["date"], a.get("date_precision"), lang))}</span>',
            f'<span class="outlet">{esc(a["outlet"])}</span>']
    names_row = people(a.get("byline"))
    # The byline is normally suppressed when it is just the site's own author. Keep it
    # when two items share a headline, otherwise a screen reader's link list shows two
    # identical entries pointing at different pages.
    if len(names_row) > 1 or names_row[0] != AUTHOR or a["headline"] in DUP_HEADLINES:
        bits.append(f'<span class="authors">{esc(", ".join(names_row))}</span>')
    if a.get("issue"):
        bits.append(f'<span>č.&nbsp;{esc(a["issue"])}</span>')
    if a.get("interviewer"):
        bits.append(f'<span>{asked_by(a["interviewer"])}: '
                    f'{esc(a["interviewer"])}</span>')
    # A row that looks exactly like the published ones would imply this ran. It did not.
    if a.get("unpublished"):
        bits.append('<span class="tag tag-unpub">nevyšlo</span>')
    elif a.get("genre") == "correspondence":
        bits.append('<span class="tag tag-unpub">korespondence</span>')
    if tag:
        bits.append(tag)
    zi = ' data-zi="1"' if any(n in ZI_NAMES for n in names_row) else ""
    return (f'  <li class="item" data-cat="{a["category"]}"{zi}>\n'
            f'    <h3><a href="{url}"{ext}>{esc(a["headline"])}</a></h3>\n'
            f'    <div class="meta">{"".join(bits)}</div>\n'
            f'  </li>')


def listing(items, show_cat):
    out, year = [], None
    for a in items:
        y = a["date"][:4]
        if y != year:
            if year is not None:
                out.append("</ul>")
            year = y
            out.append(f'<h2 class="year">{y}</h2>')
            out.append('<ul class="items">')
        out.append(item_row(a, show_cat))
    if year is not None:
        out.append("</ul>")
    return "\n".join(out)


# ------------------------------------------------------------------ writers ---

def write_item(a):
    canonical = f"{BASE}/{a['slug']}/"
    # `mirror: "<slug>"` means this English text is ALSO published at /notes/<slug>/, the
    # English research-facing surface. Both copies stay live -- this archive is deliberately
    # complete -- but rel=canonical points at /notes/ so the two do not compete in search
    # and an English research query lands in an English shell. Inbound links here keep
    # working and pass their authority through. JSON-LD still identifies this page as
    # itself; only the canonical and og:url move. Written by redesign/sync_notes.py.
    mirror = a.get("mirror")
    canonical_link = f"{SITE}/notes/{mirror}/" if mirror else None
    lang = a.get("lang") or SECTIONS[a["category"]]["lang"]
    names = people(a.get("byline"))
    is_iv = a["category"] == "rozhovory"
    # schema.org has no PressRelease type, so a press release is an Article carrying
    # genre — never OpinionNewsArticle, which would claim it is the author's opinion
    # column when it is material written for newsrooms to quote.
    is_pr = a.get("genre") == "press_release"
    # Nothing was ever printed, so there is no publisher and no publication date. The
    # page has always said so in Czech; the markup used to say the opposite, which is
    # the version a machine reads. datePublished + publisher on a withdrawn draft
    # asserts he published it in Lilie. Report the writing date as dateCreated instead.
    # Correspondence is unpublished in exactly the sense the markup
    # cares about: no publisher, no publication date. Its date is real, though —
    # the day it was sent — so the Czech wording differs from a withdrawn draft.
    unpub = bool(a.get("unpublished")) or a.get("genre") == "correspondence"
    # Not everything in the archive is an opinion column. A match report is straight
    # factual reporting; OpinionNewsArticle would tell a machine it is his argument.
    is_report = a.get("genre") == "report"

    node = {
        "@type": ("Article" if (is_iv or is_pr or unpub or is_report)
                  else "OpinionNewsArticle"),
        "@id": canonical + "#article",
        # A mirrored post's master copy lives at /notes/. The canonical link and og:url
        # already say so; the structured data has to agree, or a corpus reader counts the
        # same text as two works. The local @id stays, and sameAs names the master.
        "mainEntityOfPage": canonical_link or canonical,
        "url": canonical_link or canonical,
        **({"sameAs": canonical_link} if canonical_link else {}),
        "headline": a["headline"],
        "inLanguage": lang,
        # An advisor opinion was written on `date` and released by the institution on
        # `released`, years later. datePublished = date asserted the CNB published it
        # the day he typed it, which the record's own note denies.
        **({"dateCreated": a["date"], "datePublished": a["released"]}
           if (not unpub and a.get("genre") == "advisor_opinion" and a.get("released"))
           else {("dateCreated" if unpub else "datePublished"): a["date"]}),
        "isAccessibleForFree": True,
        "articleSection": SECTIONS[a["category"]]["title"],
    }
    # A translation is a different work from the thing it translates, and the dates and the
    # publisher belong to whichever one they describe. Left alone, the English page inherited
    # the Czech original's: publisher "Czech National Bank" with datePublished on the day the
    # CNB released the CZECH memo, which told any machine reading only the structured data
    # that the bank had published an official English version that day. It did not; this
    # archive translated it. `translated:` is the date the ENGLISH work went up here.
    _orig = BY_SLUG.get(a.get("translation") or "")
    _is_tr = bool(_orig and a.get("translated"))
    if _is_tr:
        node["datePublished"] = a["translated"]
        node["dateCreated"] = a["translated"]
        _o_lang = _orig.get("lang") or SECTIONS[_orig["category"]]["lang"]
        node["translationOfWork"] = {
            "@type": "CreativeWork",
            "@id": f"{BASE}/{_orig['slug']}/#article",
            "url": f"{BASE}/{_orig['slug']}/",
            "name": _orig["headline"],
            "inLanguage": _o_lang,
            **({"dateCreated": _orig["date"], "datePublished": _orig["released"]}
               if _orig.get("released") else {"datePublished": _orig["date"]}),
            **({"publisher": {"@type": "Organization", "name": _orig["outlet"]}}
               if _orig.get("outlet") else {}),
        }
    if unpub:
        node["creativeWorkStatus"] = "Unpublished"
    elif not _is_tr:
        node["publisher"] = {"@type": "Organization", "name": a["outlet"]}
    persons = [{k: v for k, v in (("@type", "Person"),
                                  ("@id", CANON_ID.get(ORCIDS.get(n))),
                                  ("name", n),
                                  ("sameAs", ORCIDS.get(n))) if v} for n in names]
    if is_iv:
        node["about"] = persons
        if a.get("written_by"):
            # written_by is usually a newsroom or an institute, but a reported piece
            # built on an interview is signed by a person, and typing that person as
            # an Organization would be a plain factual error in the markup.
            node["author"] = [{"@type": a.get("written_by_type", "Organization"),
                               "name": a["written_by"]}]
        elif a.get("interviewer"):
            # usually a journalist, but sometimes a whole newsroom put the questions,
            # and typing "redakce Hospodářských novin" as a Person is simply wrong
            node["author"] = [{"@type": a.get("interviewer_type", "Person"),
                               "name": a["interviewer"]}]
        else:
            node["author"] = [{"@type": "Organization", "name": a["outlet"]}]
    else:
        node["author"] = persons
    if is_pr:
        node["genre"] = "press release"
    # isBasedOn names the work this one derives FROM. On a published piece that is the
    # outlet's page, which is right. On a letter it was pointing the other way: the
    # 2021 memo's `url` is the strategic plan the memo fed INTO, published a year later,
    # so the graph asserted the memo was based on its own consequence.
    if a.get("url") and not unpub:
        node["isBasedOn"] = a["url"]
    if a.get("date_precision") == "month":
        node["dateCreated" if unpub else "datePublished"] = a["date"][:7]
    if a.get("audio_url"):
        # the same interview as an audio recording — a distinct media object, not a
        # duplicate work, so schema.org's `audio` says exactly that
        node["audio"] = {"@type": "AudioObject", "contentUrl": a["audio_url"],
                         "name": a["headline"]}

    body_html = fix_quotes(md_to_html(a["body"], item_figures(a)))
    plain = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", body_html)).strip()
    desc = a.get("perex") or ((plain[:190].rsplit(" ", 1)[0] + "…") if len(plain) > 190 else plain)
    node["description"] = desc
    if a.get("perex"):
        node["abstract"] = a["perex"]

    meta = [f'<span>{esc(cs_date(a["date"], a.get("date_precision"), lang))}</span>',
            f'<span>{esc(a["outlet"])}</span>']
    if a.get("issue"):
        meta.append(f'<span>č.&nbsp;{esc(a["issue"])}</span>')
    meta.append("<span>" + esc(", ".join(names)) + "</span>")
    if a.get("written_by"):
        meta.append(f'<span>{"written by" if lang == "en" else "text"}: '
                    f'{esc(a["written_by"])}</span>')
    if a.get("interviewer"):
        meta.append(f'<span>{asked_by(a["interviewer"], lang == "en")}: '
                    f'{esc(a["interviewer"])}</span>')

    # Every sentence below is generated, so it can follow the item's OWN language.
    # Site chrome stays Czech by design (see shell()), but a reader who opens an
    # English piece should not meet a Czech sentence explaining where it came from.
    en = lang == "en"

    if is_pr:
        # "Poprvé vyšlo" would be false: a release is sent, and whether anyone printed
        # it is a separate question the archive does not answer.
        prov = (("Press release sent to newsrooms " if en
                 else "Tisková zpráva rozeslaná redakcím ")
                + f'{cs_date(a["date"], a.get("date_precision"), lang)}.'
                + (f' <a href="{esc(a["url"])}" rel="external">'
                   f'{esc(a.get("url_label", "Project site" if en else "Web projektu"))}</a>.'
                   if a.get("url") else ""))
    elif a.get("genre") == "correspondence":
        # A letter or memo he sent, never printed anywhere. "Nevyšlo … pro vydání" would
        # be wrong twice over: it was not written for an issue, and the date is real —
        # the day it was sent — not an intention.
        prov = (("Correspondence, not a published text. Sent " if en
                 else "Korespondence, nikoli publikovaný text. Zasláno ")
                + f'{cs_date(a["date"], a.get("date_precision"), lang)}. '
                + f'{esc(a.get("context", ""))}'
                + (f' <a href="{esc(a["url"])}" rel="external">'
                   f'{esc(a.get("url_label", "Related document" if en else "Související dokument"))}</a>.'
                   if a.get("url") else ""))
    elif a.get("unpublished"):
        # "Poprvé vyšlo" would be a plain lie. Say what actually happened, and give the
        # issue it was written for as an intention rather than a publication date.
        where = OUTLET_IN.get(a["outlet"], f'v médiu {a["outlet"]}')
        # "Written for the issue of" is the wording for a column that missed its
        # print date. An advisor opinion was written for a Bank Board MEETING, was
        # never submitted, and its date is the day the author last worked on it.
        if a.get("genre") == "advisor_opinion":
            prov = ((f'Never published. Written for a meeting of the CNB Bank Board and never submitted; the date is the day it was last worked on, not a date of publication. '
                     if en else
                     f'Nevyšlo. Stanovisko bylo psáno pro jednání bankovní rady ČNB, ale nebylo předloženo; uvedené datum je datum poslední úpravy, nikoli datum vydání. ')
                    + f'{esc(a["unpublished"])}')
        else:
          prov = ((f'Never published. Written for the {cs_date(a["date"], a.get("date_precision"), lang)} '
                   f'issue of {esc(a["outlet"])}; the date is therefore the intended one, '
                   f'not a date of publication. ' if en else
                   f'Nevyšlo. Text byl napsán pro vydání '
                   f'{cs_date(a["date"], a.get("date_precision"), lang)} '
                   f'{where}; datum je tedy zamýšlené, nikoli datum otištění. ')
                  + f'{esc(a["unpublished"])}')
    else:
        where = OUTLET_IN.get(a["outlet"], f'v médiu {a["outlet"]}')
        # An outlet named with an apposition ("v Lilii, měsíčníku města Litomyšle")
        # has to close it before the date, or the sentence runs "…města Litomyšle
        # červenec 2017", which is not Czech. Outlets without a comma read fine as is.
        sep = ", " if "," in where else " "
        # An advisor opinion was WRITTEN on the record's date and released by the
        # institution years later, once its six-year restricted access lapsed.
        # "Poprvé vyšlo … 29. března 2016" asserted publication on the writing day,
        # contradicting the record's own note and the manifest's definition of
        # institutional_record. `released:` carries the actual release date.
        if a.get("genre") == "advisor_opinion" and a.get("released"):
            prov = ((f'Written {cs_date(a["date"], a.get("date_precision"), lang)} as an opinion for the CNB Bank Board and carrying six years of restricted access; the CNB released it {cs_date(a["released"], None, lang)}. ' if en else
                     f'Napsáno {cs_date(a["date"], a.get("date_precision"), lang)} jako stanovisko pro bankovní radu ČNB, s šestiletou lhůtou omezeného přístupu; ČNB dokument zveřejnila {cs_date(a["released"], None, lang)}. '))
        else:
          prov = ((f'First published in {esc(a["outlet"])}, ' if en
                   else f'Poprvé vyšlo {where}{sep}')
                + f'{cs_date(a["date"], a.get("date_precision"), lang)}.'
                # url_label matters when the link is not a permalink: the school's
                # "Školní úspěchy" is a rolling feed, so "Původní vydání" would promise
                # a page that is only about this item.
                + (f' <a href="{esc(a["url"])}" rel="external">'
                   f'{esc(a.get("url_label", "Original publication" if en else "Původní vydání"))}</a>.'
                   if a.get("url") else ""))
    # be honest about which text this is: an author manuscript can differ from what
    # the magazine printed, and for at least one Lilie column it demonstrably does.
    # Meaningless when nothing was printed, so unpublished items skip it.
    if a.get("source") == "draft" and not a.get("unpublished"):
        prov += (" This is the author's own manuscript; the printed version may differ in"
                 " details." if en else
                 " Text vychází z autorova rukopisu; tištěná verze se může v detailech lišit.")
    elif a.get("source") == "image":
        prov += (" Transcribed from the printed edition." if en else
                 " Text byl přepsán z tištěného vydání.")
    # Same interview, second format: a text item may also exist as a broadcast the
    # reader can listen to. The transcript is the archived text; the audio is a link.
    if a.get("audio_url"):
        prov += ((" The interview can also be heard as audio: " if en else
                  " Rozhovor je k poslechu také jako audio: ")
                 + f'<a href="{esc(a["audio_url"])}" rel="external">'
                   f'{esc(a.get("audio_label", "podcast"))}</a>.')

    _figs, _figfiles = item_images(a)
    figs = (_figs + "\n") if _figs else ""
    if _figfiles:
        node["image"] = [f"{SITE}{PATH}/item-img/{f}" for f in _figfiles]

    # The note is authored prose and routinely carries a link to a hosted PDF or to a
    # sibling record. Escaping it without running the inline markdown pass shipped the
    # raw "[text](url)" to the reader on every record that used one.
    note = (f'<div class="provenance"><p>{_inline(a["body_note"])}</p></div>\n'
            if a.get("body_note") else "")
    # The reader has to know this was never printed BEFORE reading it as a column, not
    # in the provenance line under the last paragraph. The full story stays down there.
    flag = ((f'      <p class="unpublished-flag">Correspondence &mdash; not a published text.</p>\n'
             if en else
             f'      <p class="unpublished-flag">Korespondence &mdash; nejde o publikovaný text.</p>\n')
            if a.get("genre") == "correspondence" else
            (f'      <p class="unpublished-flag">Never published &mdash; this text did not appear in print.</p>\n'
             if en else
             f'      <p class="unpublished-flag">Nevyšlo &mdash; tento text nebyl otištěn.</p>\n')
            if unpub else "")
    # the outlet's standfirst: part of the published piece, but the editor's words,
    # not the author's — so it is set apart rather than folded into the prose
    perex = (f'      <p class="perex">{esc(fix_quotes(a["perex"]))}</p>\n'
             if a.get("perex") else "")

    body = f"""    <article>
      <div class="article-head">
        <h1>{esc(a["headline"])}</h1>
        <div class="byline">{"".join(meta)}</div>
      </div>
{flag}{note}{perex}      <div class="prose reading">
{body_html}
{figs}      </div>
      <div class="provenance"><p>{prov}</p></div>
      <nav class="pager">
        <a href="{PATH}/{a["category"]}/">← {esc(SECTIONS[a["category"]]["title"])}</a>
        <a href="{PATH}/">{"All texts" if en else "Všechny texty"}</a>
      </nav>
    </article>"""

    head = (f'<meta property="og:type" content="article" />\n'
            + "".join(f'<meta name="author" content="{esc(n)}" />\n' for n in names)
            # only for things that actually appeared; see `unpub` above
            # Month precision has to survive here too, and an advisor opinion's
            # publication date is the institution's release, not the writing day.
            # "2026-07"; this tag went on asserting "2026-07-01", a day nobody knows,
            # to every crawler that reads meta tags rather than the graph.
            + ("" if unpub else
               f'<meta property="article:published_time" content='
               f'"{a.get("translated") or a.get("released") or (a["date"][:7] if a.get("date_precision") == "month" else a["date"])}"'
               f' />\n')
            # plain-text source of this page, for anything that would rather not parse HTML
            + f'<link rel="alternate" type="text/markdown" '
              f'href="{PATH}/src/{esc(a["file"])}" title="Zdrojový text (Markdown)" />\n')

    # A translation and its original are the same document in two languages. They linked
    # each other in prose, which a reader follows and a search engine does not: without
    # hreflang the two look like duplicates competing with one another. `translation:`
    # names the other slug; the pair is declared from both sides, and each page also
    # names itself, which the specification requires.
    other = BY_SLUG.get(a.get("translation") or "")
    if other:
        o_lang = other.get("lang") or SECTIONS[other["category"]]["lang"]
        head += (f'<link rel="alternate" hreflang="{lang}" href="{canonical}" />\n'
                 f'<link rel="alternate" hreflang="{o_lang}" '
                 f'href="{BASE}/{esc(other["slug"])}/" />\n')

    # some pieces share a printed headline — two letters under one title, or an item
    # inside a shared rubric. Disambiguate the <title> so search results are distinct.
    tt = a["headline"]
    if a.get("title_suffix"):
        tt += f' ({a["title_suffix"]})'
    page = shell(f'{tt} — {", ".join(names)}', desc, canonical,
                 {"@context": "https://schema.org", "@graph": [node]},
                 body, a["category"], head, lang, canonical_link)
    d = KDIR / a["slug"]
    d.mkdir(exist_ok=True)
    (d / "index.html").write_text(page, encoding="utf-8")


def write_index(items, key=None):
    sec = SECTIONS.get(key)
    title = sec["title"] if sec else "Komentáře, sloupky a rozhovory"
    desc = sec["desc"] if sec else HUB_DESC
    canonical = f"{BASE}/{key}/" if key else f"{BASE}/"
    sel = [a for a in items if not key or a["category"] == key]

    person = {
        "@type": "Person",
        "@id": f"{SITE}/#th",
        "name": AUTHOR,
        "givenName": "Tomáš", "familyName": "Havránek",
        "jobTitle": "profesor ekonomie",
        "description": ("Profesor ekonomie na Institutu ekonomických studií FSV Univerzity "
                        "Karlovy. Měnová politika, metaanalýza a metavýzkum. Bývalý poradce "
                        "viceguvernéra a bankovní rady ČNB."),
        "affiliation": {"@type": "Organization",
                        "name": "Institut ekonomických studií, FSV Univerzita Karlova",
                        "url": "https://ies.fsv.cuni.cz/"},
        "url": "https://www.tomashavranek.cz/",
        "sameAs": [
            "https://orcid.org/0000-0002-3158-2539",
            "https://scholar.google.com/citations?user=BF0BvBkAAAAJ",
            "https://ideas.repec.org/f/pha418.html",
            "https://www.scopus.com/authid/detail.uri?authorId=24453189000",
            "https://ies.fsv.cuni.cz/contacts/institute-members/78067720",
            "https://cepr.org/about/people/tomas-havranek",
            "https://metrics.stanford.edu/people/tomas-havranek",
            "https://www.tomashavranek.cz/",
            "https://meta-analysis.cz/",
            "https://zrusme-inflaci.cz/",
        ],
    }
    # This is a joint archive, so the structured data has to name both people or an
    # entity resolver reads every item as his. Her node carries every name form she
    # publishes under, which is how a crawler connects "Irsova" to "Havránková".
    person_zi = {
        "@type": "Person",
        "@id": f"{SITE}/#zi",
        "name": "Zuzana Iršová Havránková",
        "givenName": "Zuzana", "familyName": "Havránková",
        "alternateName": ["Zuzana Havránková", "Zuzana Iršová", "Zuzana Irsová",
                          "Zuzana Irsova", "Zuzana Irsova Havrankova"],
        "jobTitle": "profesorka ekonomie",
        "description": ("Profesorka ekonomie na Institutu ekonomických studií FSV "
                        "Univerzity Karlovy. Metaanalýza a metavýzkum, trh práce a "
                        "mezinárodní ekonomie. V angličtině publikuje jako Zuzana Irsova."),
        "affiliation": {"@type": "Organization",
                        "name": "Institut ekonomických studií, FSV Univerzita Karlova",
                        "url": "https://ies.fsv.cuni.cz/"},
        "url": "https://www.irsova.com/",
        "sameAs": [
            "https://orcid.org/0000-0002-0753-8124",
            "https://ies.fsv.cuni.cz/contacts/institute-members/73504033",
            "https://www.irsova.com/",
            "https://meta-analysis.cz/",
        ],
    }
    node = {
        "@type": "CollectionPage",
        "@id": canonical + "#collection",
        "url": canonical,
        "name": f"{title} — {SITE_AUTHORS}",
        "description": desc,
        "inLanguage": sec["lang"] if sec else "cs",
        "about": [{"@id": f"{SITE}/#th"}, {"@id": f"{SITE}/#zi"}],
        # These share the per-page node's @id, so anything merging the graph would end up
        # with dateCreated from the page AND datePublished from here on one entity. An
        # unpublished draft must carry the same date field in both places.
        "hasPart": [dict(
            {"@type": "Article",
             "@id": (f"{BASE}/{a['slug']}/#article" if a["media"] == "text" else a.get("url", "")),
             "url": (f"{BASE}/{a['slug']}/" if a["media"] == "text" else a.get("url", "")),
             "headline": a["headline"],
             # Month precision has to be stated the same way the item page states it, or
             # one @id carries two different dates and 2026-07-01 asserts a day nobody
             # knows. Likewise the status: a reference to a never-published text must not
             # look like a reference to a published one. An advisor opinion was written
             # on `date` and released by the CNB years later, so this node has to split
             # the two exactly as the item page does: the listing used to assert
             # datePublished = the writing day on the very @id whose page says otherwise.
             **({"dateCreated": a["date"], "datePublished": a["released"]}
                if (not (a.get("unpublished") or a.get("genre") == "correspondence")
                    and a.get("genre") == "advisor_opinion" and a.get("released"))
                else {("dateCreated"
                       if (a.get("unpublished") or a.get("genre") == "correspondence")
                       else "datePublished"): (a["date"][:7]
                                               if a.get("date_precision") == "month"
                                               else a["date"])})},
            **({"creativeWorkStatus": "Unpublished"}
               if (a.get("unpublished") or a.get("genre") == "correspondence") else {})
        ) for a in sel],
    }
    counts = ""
    if not key:
        c = {k: sum(1 for a in items if a["category"] == k) for k in SECTIONS}
        links = [f'<a href="{PATH}/{k}/">{esc(SECTIONS[k]["short"])} ({c[k]})</a>'
                 for k in SECTIONS if c[k]]
        # Ze sítí is not a SECTION (its posts are not src items), so it has to be added
        # here by hand or the hub gives no route to it but the nav.
        n_soc = (len(json.loads(SOCIAL_JSON.read_text(encoding="utf-8")))
                 if SOCIAL_JSON.exists() else 0)
        if n_soc:
            links.append(f'<a href="{PATH}/posts/">Posts ({n_soc})</a>')
        counts = "      <p>" + " · ".join(links) + "</p>\n"
        # WHY THE POSTS ARE NOT ROWS IN THIS LISTING. Reviewed again 2026-08-01, and
        # the original note here had rotted: it argued from "22 rows pointing at
        # #anchors yield ONE indexable destination" and counted "179 press items".
        # Both are false now — every post has had its own page since July 2026, and the
        # listing holds 211. That dead reasoning nearly justified a merge. Keep these
        # counts current — a rotted comment here has already caused one wrong call.
        # The reasons
        # that do survive:
        #
        #  1. Register. Every one of the 211 items is a formal text with a headline its
        #     author wrote, addressed to readers through an outlet or a formal act of
        #     writing — including the four letters and the 103-word MAER-Net note. About
        #     a third of the posts are personal (a boxing gym in Palo Alto, spare
        #     festival tickets). The line here is register, not length or pedigree.
        #  2. Audience. The posts page is English on purpose for readers who arrive
        #     there directly; see SOCIAL_DESC below.
        #  3. Cross-posting makes duplicates, and would keep making them. At least four
        #     posts announce, within two days, an item this listing already carries —
        #     „🔎 MAIVE is now on CRAN…" the same day as the MAER-Net item "MAIVE Is Now
        #     on CRAN". Merged, those are adjacent near-identical rows pointing at
        #     different pages; DUP_HEADLINES cannot catch them because the strings
        #     differ. The defect grows with normal posting behaviour.
        #  4. Proportion. 18 of the 23 posts are from 2026 against 16 items, so a merge
        #     makes the top of the page — the first thing anyone reads — majority
        #     LinkedIn, on a page called "Komentáře, sloupky a rozhovory".
        #  5. The filter would lie. 20 items are English and so are 20 posts; filing
        #     posts under their own category would stop the English chip matching half
        #     the English texts on the page.
        #
        # What the hub owes the posts instead is a route and freshness: the counts link
        # above, and the newest post QUOTED below — its opening line in quotation marks,
        # never dressed up as a headline the author never wrote.
        if SOCIAL_JSON.exists():
            _sp = json.loads(SOCIAL_JSON.read_text(encoding="utf-8"))
            _sp.sort(key=lambda p: p.get("datetime", p["date"]), reverse=True)
            if _sp:
                _n = _sp[0]
                counts += (f'      <p class="latest-post">Nejnovější příspěvek ze sítí, '
                           f'{esc(cs_date(_n["date"]))}: „{esc(_headline(_n["text"]))}“ — '
                           f'<a href="{PATH}/posts/{esc(_n["slug"])}/">celý příspěvek</a>'
                           f'</p>\n')

    body = (f'    <div class="lede">\n      <h1>{esc(title)}</h1>\n'
            f'      <p>{esc(HUB_LEDE if not key else desc)}</p>\n{counts}    </div>\n'
            + (FILTER if not key else "")
            + listing(sel, show_cat=not key))
    page = shell(f"{title} — {SITE_AUTHORS}", desc, canonical,
                 {"@context": "https://schema.org", "@graph": [node, person, person_zi]},
                 body, key or "", lang=(sec["lang"] if sec else "cs"))
    if not key:
        page = page.replace("</body>", SCRIPT + "</body>")
    d = KDIR if not key else KDIR / key
    d.mkdir(exist_ok=True)
    (d / "index.html").write_text(page, encoding="utf-8")


def write_feed(items, social=()):
    _newest = max([a["date"] for a in items] + [p["date"] for p in social])
    it = []
    for a in items:
        url = f"{BASE}/{a['slug']}/" if a["media"] == "text" else (a.get("url") or BASE)
        body = fix_quotes(md_to_html(a["body"]))
        # A reader who only ever sees the feed must not be told this ran in Lilie.
        if a.get("genre") == "correspondence":
            _en = (a.get("lang") or SECTIONS[a["category"]]["lang"]) == "en"
            body = ((f'<p><em>Correspondence, not a published text. The date is the'
                     f' day it was sent.</em></p>' + chr(10) if _en else
                     f'<p><em>Korespondence, nikoli publikovaný text. Uvedené datum'
                     f' je datum odeslání.</em></p>' + chr(10)) + body)
        elif a.get("unpublished") and a.get("genre") == "advisor_opinion":
            body = ('<p><em>Nevyšlo. Stanovisko bylo psáno pro jednání bankovní rady ČNB, ale nebylo předloženo; uvedené datum je datum poslední úpravy.</em></p>'
                    + chr(10) + body)
        elif a.get("unpublished"):
            body = (f'<p><em>Nevyšlo. Text byl napsán pro otištění '
                    f'{OUTLET_IN.get(a["outlet"], "v " + a["outlet"])}; uvedené datum '
                    f"je zamýšlené, nikoli datum otištění.</em></p>\n" + body)
        content = (f"<![CDATA[{body}]]>"
                   if a["media"] == "text" else
                   f"<![CDATA[<p>{MEDIA_LABEL.get(a['media'], '')} — "
                   f'<a href="{a.get("url", "")}">{esc(a["outlet"])}</a></p>]]>')
        _never = a.get("genre") == "correspondence" or a.get("unpublished")
        # `url` is a required attribute of <source>; emitting it empty is invalid RSS,
        # and a piece that was never published has no original to point at. That was the
        # stated intent, but the guard only tested for a url — and the letters do carry
        # one, pointing at a related document rather than an origin. <source> then told
        # a feed reader the letter had run there.
        source = (f'\n      <source url="{esc(a["url"])}">{esc(a["outlet"])}</source>'
                  if a.get("url") and not _never else "")
        # RSS pubDate means "when this was published". Six records were never published
        # anywhere — four letters and two withdrawn drafts — so they get no pubDate. An
        # earlier pass kept it for sort order and said so in a comment; two independent
        # reviews called that wrong, and they are right: an archive that states an
        # invariant should not carry a documented exception to it. Readers fall back to
        # feed order, and the item body opens by saying it was never published.
        # pubDate is a publication date. For an advisor opinion that is the day the
        # institution released it, not the day it was written.
        _pub = ("" if _never else
                f'<pubDate>{rfc822(a.get("released") or a["date"])}</pubDate>'
                + chr(10) + "      ")
        it.append((a["date"], f"""    <item>
      <title>{esc(a["headline"])}</title>
      <link>{url}</link>
      <guid isPermaLink="true">{url}</guid>
      {_pub}<category>{esc(SECTIONS[a["category"]]["title"])}</category>
      <dc:language>{a.get("lang") or SECTIONS[a["category"]]["lang"]}</dc:language>{source}
      <content:encoded>{content}</content:encoded>
    </item>"""))
    # The posts used to be kept out of the feed, on the reasoning that back-filling
    # them would land as unread items in every subscriber's reader. Now that each has
    # its own page, they are ordinary entries and belong in the channel; the one-time
    # burst is the price of having left them out until now.
    for p in social:
        url = f"{BASE}/posts/{p['slug']}/"
        body = "".join(f"<p>{esc(x)}</p>" for x in p["text"].split("\n\n") if x.strip())
        it.append((p["date"], f"""    <item>
      <title>{esc(_headline(p["text"]))}</title>
      <link>{url}</link>
      <guid isPermaLink="true">{url}</guid>
      <pubDate>{rfc822(p["date"])}</pubDate>
      <category>Posts (ze sítí)</category>
      <dc:language>{p.get("lang", "en")}</dc:language>
      <source url="{esc(p.get("url", ""))}">LinkedIn</source>
      <content:encoded><![CDATA[{body}]]></content:encoded>
    </item>"""))
    it.sort(key=lambda t: t[0], reverse=True)
    it = [x[1] for x in it]
    (KDIR / "feed.xml").write_text(f"""<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Komentáře — {esc(SITE_AUTHORS)}</title>
    <link>{BASE}/</link>
    <atom:link href="{BASE}/feed.xml" rel="self" type="application/rss+xml" />
    <description>{esc(FEED_DESC)}</description>
    <language>cs</language>
    <lastBuildDate>{rfc822(_newest)}</lastBuildDate>
{chr(10).join(it)}
  </channel>
</rss>
""", encoding="utf-8")


def write_machine_readable(items, social=()):
    n_social = len(social)
    """Three bulk formats, so a crawler or a training pipeline never has to parse HTML.

    llms.txt   a plain index in the llms.txt convention
    index.json full metadata for every item, one JSON document
    all.md     every text in one Markdown file, in reverse-chronological order
    """
    # --- llms.txt -------------------------------------------------------------
    L = [f"# Komentáře — {SITE_AUTHORS}", "",
         "> " + HUB_DESC, "",
         f"Publicistika: {len(items)} položek a {n_social} kratších příspěvků ze sítí "
         f"({len(items) + n_social} záznamů celkem), "
         f"{items[-1]['date'][:4]}–{items[0]['date'][:4]}. "
         "Plné znění každého textu je na uvedené adrese; zdrojový Markdown položek "
         "je v /komentare/src/ (příspěvky ze sítí zdrojový soubor nemají). "
         "Licence: CC BY 4.0, jako vše na meta-analysis.cz; u převzatých textů "
         "uveďte i původní vydání.", ""]
    for k, sec in SECTIONS.items():
        sel = [a for a in items if a["category"] == k]
        if not sel:
            continue
        L += [f"## {sec['title']}", "", sec["desc"], ""]
        for a in sel:
            d = cs_date(a["date"], a.get("date_precision"))
            # llms.txt is read by machines that will not open the page and see the
            # Czech "Nevyšlo" note, so the marker has to travel with the line itself.
            # The same argument covers the two statuses that qualify what the stored
            # text IS. A machine reading only this line would otherwise quote an
            # author's manuscript as the printed text, or quote a two-paragraph teaser
            # as a whole article.
            out = a["outlet"] + {"unpublished_manuscript": " (nevyšlo)",
                                 "correspondence": " (korespondence, nepublikováno)",
                                 "author_manuscript": " (autorská verze, ne otištěné znění)",
                                 "publisher_excerpt": " (jen ukázka, zbytek je za paywallem)",
                                 }.get(text_status(a), "")
            if a["media"] == "text":
                L.append(f"- [{a['headline']}]({BASE}/{a['slug']}/) — {out}, {d}")
            else:
                L.append(f"- [{a['headline']}]({a.get('url','')}) — {a['outlet']}, {d} "
                         f"({MEDIA_LABEL.get(a['media'], '')}, pouze odkaz)")
        L.append("")
    if social:
        L += ["## Posts (ze sítí)", "",
              f"Kratší příspěvky Zuzany Iršové Havránkové, publikované původně na "
              f"LinkedIn, zde v plném znění. Každý má vlastní stránku a všechny jsou "
              f"navíc pohromadě na {BASE}/posts/.", ""]
        for p in social:
            L.append(f"- [{_headline(p['text'])}]({BASE}/posts/{p['slug']}/) — "
                     f"{p['date']}")
        L.append("")
    L += ["## Další zdroje", "",
          "- [Osobní stránka](https://www.tomashavranek.cz/)",
          "- [meta-analysis.cz](https://meta-analysis.cz/)",
          "- [Zrušme inflaci](https://zrusme-inflaci.cz/) — autorova iniciativa k cenové stabilitě",
          "- [ORCID](https://orcid.org/0000-0002-3158-2539)",
          "- [Google Scholar](https://scholar.google.com/citations?user=BF0BvBkAAAAJ)",
          "- [RePEc](https://ideas.repec.org/f/pha418.html)",
          f"- [Posts]({BASE}/posts/) — {n_social} short posts by Zuzana Irsova "
          f"Havrankova, mostly English, in full",
          f"- [RSS]({BASE}/feed.xml)",
          f"- [Strojově čitelný index (JSON)]({BASE}/index.json)",
          f"- [Všechny texty v jednom souboru]({BASE}/all.md)", ""]
    (KDIR / "llms.txt").write_text(chr(10).join(L), encoding="utf-8")

    # --- index.json -----------------------------------------------------------
    docs = []
    for a in items:
        d = {"id": a["slug"], "title": a["headline"], "date": a["date"],
             "date_precision": a.get("date_precision", "day"),
             "section": SECTIONS[a["category"]]["title"], "category": a["category"],
             "language": a.get("lang") or SECTIONS[a["category"]]["lang"],
             "outlet": a["outlet"], "authors": people(a.get("byline")),
             "media": a["media"],
             # On every published record `original_url` means "where this ran". A letter
             # never ran anywhere, and its `url` points at something related — the plan
             # the memo fed into, the project page a circular announced. Calling that
             # `original_url` would state the one thing the record exists to deny.
             **({"related_url": a["url"]}
                if (a.get("url") and (a.get("genre") == "correspondence"
                                      or a.get("unpublished")))
                else {"original_url": a.get("url", "")}),
             "text_status": text_status(a)}
        if a.get("mirror"):
            # the master copy of a cross-posted English note lives at /notes/
            d["canonical_url"] = f"{SITE}/notes/{a['mirror']}/"
        if a.get("perex"):
            d["standfirst"] = a["perex"]
            d["standfirst_note"] = "Written by the original outlet, not by the author."
        if a.get("interviewer"):
            d["interviewer"] = a["interviewer"]
        if a.get("audio_url"):
            d["audio_url"] = a["audio_url"]
        if a.get("issue"):
            d["issue"] = a["issue"]
        if a["media"] == "text":
            d["url"] = f"{BASE}/{a['slug']}/"
            d["source_markdown"] = f"{BASE}/src/{a['file']}"
            d["word_count"] = len(a["body"].split())
            d["text"] = a["body"]
        # figures reached the per-page JSON-LD but not the corpus, so a consumer working
        # from index.json/corpus.jsonl could not tell a text had a map or a photo with it
        _imgs, _alts = _split(a.get("images")), _split(a.get("image_alt"))
        _creds = _split(a.get("image_credit"))
        if _imgs:
            d["images"] = [{"url": f"{BASE}/item-img/{f}", "alt": _alts[i],
                            **({"credit": _creds[i]} if i < len(_creds) else {})}
                           for i, f in enumerate(_imgs)]
        # "editorial" claims an editor stood between the author and the reader. For a
        # piece that was written, submitted and then never printed, no editor ever did.
        # "editorial" claims an outlet's editor stood between the author and the
        # reader. That is false for the ČNB advisor opinions: they were written as
        # internal Bank Board documents and the ČNB released them verbatim, years
        # later, as a record of its own proceedings. None of the other three values
        # fits either — the author did not post them, and they were published.
        d["provenance"] = ("correspondence" if a.get("genre") == "correspondence" else
                           "unpublished" if a.get("unpublished") else
                           "institutional_record"
                           if a.get("genre") == "advisor_opinion" else
                           "self_published"
                           if (SELF_PUBLISHED.search(a["outlet"])
                               or a.get("genre") == "press_release") else "editorial")
        if a.get("genre"):
            d["genre"] = a["genre"]
        docs.append(d)

    # The social posts are on one shared page rather than a page each, but they are
    # separate documents and a retrieval corpus must see them that way — otherwise the
    # only machine-readable trace of 25 texts is one page's JSON-LD.
    for p in social:
        docs.append({
            # The id is a compatibility contract with anything that stored it, so it
            # keeps the anchor form even though the URL below no longer does.
            "id": f"posts-{p['anchor']}", "title": _headline(p["text"]),
            "date": p["date"], "date_precision": "day",
            # same label the manifest and llms.txt use, so a consumer can join on it
            "section": "Posts (ze sítí)", "category": "posts",
            "language": p.get("lang", "en"), "outlet": "LinkedIn",
            "authors": ["Zuzana Havránková"], "media": "text",
            "original_url": p.get("url", ""),
            "url": f"{BASE}/posts/{p['slug']}/",
            "collection_url": f"{BASE}/posts/#{p['anchor']}",
            "text_status": "published_full_text",
            "genre": "social_post", "provenance": "self_published",
            "word_count": len(p["text"].split()), "text": p["text"],
            **({"image": [f"{SITE}{PATH}/social-img/{f}" for f in p["images"]]}
               if p.get("images") else {}),
            # so a consumer of the corpus can follow the post's links without having to
            # resolve a shortener that may no longer exist
            **({"link_map": p["link_map"]} if p.get("link_map") else {}),
            **({"comment_links": p["comment_links"]} if p.get("comment_links") else {}),
        })
    (KDIR / "index.json").write_text(json.dumps({
        "name": f"Komentáře — {SITE_AUTHORS}",
        "description": HUB_DESC,
        "url": f"{BASE}/",
        "authors": [
            {"name": AUTHOR, "orcid": ORCIDS[AUTHOR],
             "affiliation": "Institut ekonomických studií, FSV Univerzita Karlova"},
            {"name": "Zuzana Iršová Havránková", "orcid": ORCIDS["Zuzana Havránková"],
             "also_published_as": ["Zuzana Havránková", "Zuzana Iršová", "Zuzana Irsova"],
             "affiliation": "Institut ekonomických studií, FSV Univerzita Karlova"},
        ],
        "license": "https://creativecommons.org/licenses/by/4.0/",
        "license_note": "CC BY 4.0; u převzatých textů uveďte i původní vydání.",
        "count": len(docs),
        "generated_from": ["komentare/src/*.md", "komentare/social-posts.json"],
        "items": docs,
    }, ensure_ascii=False, indent=1), encoding="utf-8")

    # --- corpus.jsonl ---------------------------------------------------------
    # The same records, one self-contained JSON object per line. This is what data
    # pipelines read natively: it streams, so a loader never has to hold the whole
    # corpus in memory, and one malformed line cannot spoil the rest of the file.
    (KDIR / "corpus.jsonl").write_text(
        "".join(json.dumps(d, ensure_ascii=False) + chr(10) for d in docs),
        encoding="utf-8")

    # --- all.md ---------------------------------------------------------------
    A = [f"# Komentáře — {SITE_AUTHORS}", "", HUB_DESC, "",
         # "plné znění" was not true of every one of them: two records hold only the
         # outlet's free teaser, and a machine that trusted this line would quote a
         # tenth of an article as the whole of it.
         f"Tento soubor obsahuje text všech textových položek "
         f"({sum(1 for a in items if a['media'] == 'text')} z celkem {len(items)}), "
         f"u naprosté většiny v plném znění; výjimkou jsou položky označené v index.json "
         f"jako publisher_excerpt "
         f"({sum(1 for a in items if text_status(a) == 'publisher_excerpt')}), "
         f"kde je uložena jen volně dostupná ukázka, a author_manuscript "
         f"({sum(1 for a in items if text_status(a) == 'author_manuscript')}), "
         f"kde jde o autorskou verzi, která se může lišit od otištěné. "
         f"Zbývající položky jsou audio a video, které archiv vede pouze odkazem, "
         f"a v tomto souboru nejsou; jejich metadata najdete v index.json a corpus.jsonl. "
         f"Samostatně jsou vedeny kratší příspěvky ze sociálních sítí ({n_social}), "
         f"psané převážně anglicky. Mají vlastní stránku {BASE}/posts/ a v index.json "
         f"i corpus.jsonl jsou označeny jako genre=social_post.",
         "", "---", ""]
    for a in items:
        if a["media"] != "text":
            continue
        A += [f"## {a['headline']}", "",
              f"*{a['outlet']}, {cs_date(a['date'], a.get('date_precision'))}"
              + (f", {asked_by(a['interviewer'])} {a['interviewer']}"
                 if a.get("interviewer") else "")
              + f". {', '.join(people(a.get('byline')))}.*", ""]
        # this file is the one an AI is most likely to ingest whole
        if a.get("genre") == "correspondence":
            A += [f"*Korespondence, nikoli publikovaný text. "
                  f"Uvedené datum je datum odeslání.*", ""]
        elif a.get("unpublished") and a.get("genre") == "advisor_opinion":
            A += ["*Nevyšlo. Stanovisko bylo psáno pro jednání bankovní rady ČNB,"
                  " ale nebylo předloženo; uvedené datum je datum poslední úpravy.*", ""]
        elif a.get("unpublished"):
            A += [f"*Nevyšlo. Text byl napsán pro otištění "
                  f"{OUTLET_IN.get(a['outlet'], 'v ' + a['outlet'])}; uvedené datum "
                  f"je zamýšlené, nikoli datum otištění.*", ""]
        A += [f"Zdroj: {a.get('url') or BASE + '/' + a['slug'] + '/'}", "",
              a["body"], "", "---", ""]
    (KDIR / "all.md").write_text(chr(10).join(A), encoding="utf-8")

    # --- manifest.json --------------------------------------------------------
    # An inventory a consumer can verify against: how many records of each kind,
    # what each distribution weighs, and a checksum per file. Deliberately carries
    # no build timestamp — it is keyed to the newest item instead, so rebuilding an
    # unchanged corpus produces a byte-identical manifest and no git churn.
    counts = {}
    for d in docs:
        counts[d["text_status"]] = counts.get(d["text_status"], 0) + 1
    files = {}
    for name in ("corpus.jsonl", "index.json", "all.md", "llms.txt", "feed.xml"):
        p = KDIR / name
        if p.exists():
            # Hash what the SERVER will send, not what sits on this disk. Python's
            # write_text translates "\n" to "\r\n" on Windows, git commits LF, and Pages
            # therefore serves LF — so hashing the local bytes published a checksum that
            # never once matched the live file. Normalising here makes the manifest
            # verifiable, and makes it verifiable from any machine's checkout.
            blob = p.read_bytes().replace(b"\r\n", b"\n")
            files[name] = {"url": f"{BASE}/{name}", "bytes": len(blob),
                           "sha256": hashlib.sha256(blob).hexdigest()}
    (KDIR / "manifest.json").write_text(json.dumps({
        "name": f"Komentáře — {SITE_AUTHORS}",
        "url": f"{BASE}/data/",
        # Renamed from "corpus_updated", which promised something it never delivered:
        # it was always the newest record's date, so adding the two 2021/2025 pieces on
        # 26 July left it reading 25 July and anyone polling it for changes saw none.
        # It is the newest record, so it now says so. To detect that the corpus changed,
        # compare the per-file sha256 checksums below — that is what they are for.
        "newest_record": _span(items, social).split("/")[1],
        "temporal_coverage": _span(items, social),
        "records": {
            "total": len(docs),
            "by_text_status": counts,
            "by_section": {**{SECTIONS[k]["title"]: len([a for a in items
                                                         if a["category"] == k])
                              for k in SECTIONS},
                           "Posts (ze sítí)": len(social)},
        },
        "text_status_meanings": {
            "published_full_text": "the text as published",
            "author_manuscript": "the author's own version, as sent to the outlet",
            "publisher_excerpt": "only the outlet's free teaser; the original is paywalled",
            "link_only": "audio or video; no text is stored, the record links to the source",
            "correspondence": "a letter or memo the author sent — to a public body, to "
                                  "colleagues, to students — never published anywhere. The date "
                                  "is the day it was sent, and is exact",
            "unpublished_manuscript": "written for the outlet and submitted, but never "
                                      "printed; the date is the issue it was written for, "
                                      "not a publication date",
        },
        "provenance_meanings": {
            "editorial": "an outlet's editor stood between the author and the reader",
            "self_published": "posted by the author, with no outlet editing it",
            "unpublished": "never printed anywhere, so no editor and no publication date",
            "correspondence": "sent to named recipients rather than published; no editor "
                         "stood between the author and the reader",
            "institutional_record": "written inside an institution as an internal "
                         "document and released later by that institution as a record of "
                         "its own proceedings; no outlet editor stood between the author "
                         "and the reader, and the publication date is the institution's "
                         "release, not the writing",
        },
        "files": files,
        "generated_from": ["komentare/src/*.md", "komentare/social-posts.json"],
    }, ensure_ascii=False, indent=1), encoding="utf-8")

    return len([a for a in items if a["media"] == "text"])


SOCIAL_JSON = KDIR / "social-posts.json"
# This section is written in English on purpose: the posts are mostly English and the
# page is meant for an international readership, who reach it directly rather than
# through the Czech archive around it.
SOCIAL_DESC = ("Short posts by Zuzana Irsova Havrankova on her own research, on meta-analysis "
               "and on how research gets done. Originally published on LinkedIn, "
               "archived here in full.")

_LINK = re.compile(r"https?://[^\s<>]+")

# Their own properties and stable scholarly identifiers. nofollowing these from their
# own archive is an own goal: they are author-chosen links, not user-generated content.
_OWN = re.compile(r"^https?://(www\.)?("
                  r"meta-analysis\.cz|tomashavranek\.cz|irsova\.com|zrusme-inflaci\.cz|"
                  r"easymeta\.org|spuriousprecision\.com|doi\.org|github\.com/tjhavranek|"
                  r"osf\.io|arxiv\.org|cepr\.org|ies\.fsv\.cuni\.cz)")


def _rel(u):
    return "" if _OWN.match(u) else ' rel="nofollow"'



def _trim_url(u):
    """A URL written inside a sentence ends before the sentence's punctuation.
    Keep a closing bracket only when the URL itself opened one."""
    while u and u[-1] in ".,;:!?“”’'":
        u = u[:-1]
    while u.endswith(")") and u.count("(") < u.count(")"):
        u = u[:-1]
    return u


def _social_html(text):
    """Post text is plain: escape it, then make the bare URLs clickable."""
    out = []
    for para in text.split("\n\n"):
        lines = [esc(l) for l in para.split("\n") if l.strip()]
        if not lines:
            continue
        body = "<br>".join(lines)
        def _a(m):
            u = _trim_url(m.group(0))
            return f'<a href="{u}"{_rel(u)}>{u}</a>{m.group(0)[len(u):]}'
        body = _LINK.sub(_a, body)
        out.append(f"<p>{body}</p>")
    return "\n        ".join(out)


def _headline(text):
    """First line, cut at a word boundary — a headline sliced mid-word reads as broken."""
    h = text.split(chr(10))[0].strip()
    if len(h) <= 110:
        return h
    return h[:110].rsplit(" ", 1)[0].rstrip(" ,;:") + "…"


def _social_body_after_headline(text):
    """The post's own text with its opening line removed.

    A post's headline IS its first line, so the single-post page showed that sentence
    twice running: once as the <h1>, then again as the first thing in the body. Drop it
    from the body there — the reader still sees it, as the heading. Only when the line
    was short enough to be used whole; a truncated headline ends in "…" and dropping the
    full line would lose words the heading never showed. The collection page and every
    machine surface keep the complete text.
    """
    first, _, rest = text.partition("\n")
    return rest.lstrip("\n") if _headline(text) == first.strip() and rest.strip() else text


SLUG_RE = re.compile(r"^\d{4}-\d{2}-\d{2}-[a-z0-9-]+$")


def _img_size(path):
    """(width, height) from the file's own header, so no hand-kept numbers can drift.
    PNG and JPEG only; anything else renders without width/height, which is valid but
    gives the browser no way to reserve the space."""
    try:
        b = path.read_bytes()
    except OSError:
        return None
    if b[:8] == b"\x89PNG\r\n\x1a\n" and b[12:16] == b"IHDR":
        return int.from_bytes(b[16:20], "big"), int.from_bytes(b[20:24], "big")
    if b[:2] == b"\xff\xd8":
        i = 2
        while i + 9 < len(b):
            if b[i] != 0xFF:
                i += 1
                continue
            m = b[i + 1]
            if m in (0xD8, 0x01) or 0xD0 <= m <= 0xD7:
                i += 2
                continue
            ln = int.from_bytes(b[i + 2:i + 4], "big")
            if m in (0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7,
                     0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF):
                return (int.from_bytes(b[i + 7:i + 9], "big"),
                        int.from_bytes(b[i + 5:i + 7], "big"))
            i += 2 + ln
    return None


def asked_by(name, en=False):
    """The label before an interviewer's name, in the right gender.

    It was hard-coded masculine as "ptal se", which is simply wrong in front of a
    woman's name — and most of the interviewers here are women, so the error sat on
    Zuzana's interview pages in particular. Czech female surnames are reliable enough
    to decide this: -ová and -á. "redakce" is feminine too, and two or more names take
    the plural.
    """
    if en:
        return "interviewed by"
    n = (name or "").strip()
    if "," in n or " a " in n:
        return "ptali se"
    last = n.split()[-1] if n.split() else ""
    if n.lower().startswith("redakce") or last.endswith(("ová", "á")):
        return "ptala se"
    return "ptal se"


def _split(v):
    """Front matter has no lists, so a few keys carry a pipe-separated one."""
    return [x.strip() for x in (v or "").split("|") if x.strip()]


# A chart caption as the source files carry it: "Graf 1: ..." or "*Graf 1: ...*" in the
# Czech records, "Chart 1. ..." in the English ones. The number is what binds a caption to
# its image, so a figure cannot silently land under the wrong chart.
FIG_CAPTION = re.compile(r"^\*?((?:Graf|Chart)\s+(\d+)\s*[.:]\s*.+?)\*?$")


def figure_html(f, alt, caption):
    """One chart, set inline where its caption stands in the text."""
    wh = _img_size(KDIR / "item-img" / f)
    dim = f' width="{wh[0]}" height="{wh[1]}"' if wh else ""
    return (f'<figure class="item-fig">'
            f'<img src="{PATH}/item-img/{esc(f)}" alt="{esc(alt)}"'
            f' loading="lazy" decoding="async"{dim}>'
            f'<figcaption>{_inline(caption)}</figcaption></figure>')


def item_figures(a):
    """Charts bound to the caption they belong under, by number.

    `image_figure` names the chart number of each entry in `images`, in the same order.
    Items that carry photographs rather than charts leave it out and keep the old
    behaviour: the figures are appended after the text, not woven into it."""
    nums = _split(a.get("image_figure"))
    if not nums:
        return {}
    files, alts = _split(a.get("images")), _split(a.get("image_alt"))
    if not (len(nums) == len(files) == len(alts)):
        sys.exit(f"error: {a['file']} has {len(files)} images, {len(alts)} alt texts "
                 f"and {len(nums)} figure numbers; the three must agree")
    out = {}
    for n, f, alt in zip(nums, files, alts):
        if not (KDIR / "item-img" / f).exists():
            sys.exit(f"error: {a['file']} references a missing image: {f}")
        out[n] = (f, alt)
    # A number with no caption in the body would place nothing, silently. Every declared
    # chart has to have somewhere to go.
    have = {m.group(2) for line in (a["body"] or "").split("\n")
            for m in [FIG_CAPTION.match(line.strip())] if m}
    missing = [n for n in out if n not in have]
    if missing:
        sys.exit(f"error: {a['file']} declares figure(s) {', '.join(missing)}, "
                 f"but the body has no caption for them")
    return out


def item_images(a):
    """Figures published alongside the text — the map, the photograph. Returns HTML.

    Every figure needs alt text: these are maps and match photographs that carry
    information, not decoration. The build refuses to run if one is missing, because a
    silent empty alt is exactly the failure a screen-reader user cannot detect."""
    files, alts = _split(a.get("images")), _split(a.get("image_alt"))
    if not files:
        return "", []
    # Charts placed inline by item_figures still belong in the page's image
    # list for the machine layer, but must not be appended a second time.
    if _split(a.get("image_figure")):
        return "", files
    if len(files) != len(alts):
        sys.exit(f"error: {a['file']} has {len(files)} images but {len(alts)} alt texts")
    creds = _split(a.get("image_credit"))
    out = []
    for i, f in enumerate(files):
        p = KDIR / "item-img" / f
        if not p.exists():
            sys.exit(f"error: {a['file']} references a missing image: {f}")
        wh = _img_size(p)
        dim = f' width="{wh[0]}" height="{wh[1]}"' if wh else ""
        cap = (f'\n          <figcaption>{esc(creds[i])}</figcaption>'
               if i < len(creds) else "")
        out.append(f'        <figure class="item-fig">\n'
                   f'          <img src="{PATH}/item-img/{esc(f)}" alt="{esc(alts[i])}"'
                   f' loading="lazy" decoding="async"{dim}>{cap}\n'
                   f'        </figure>')
    return "\n".join(out), files


def _post_desc(text):
    """Meta description for a post's own page: the opening, whole words, no markup."""
    t = re.sub(r"\s+", " ", text).strip()
    return t if len(t) <= 180 else t[:180].rsplit(" ", 1)[0].rstrip(" ,;:") + "…"


def write_socials_page():
    """The collection page for the social posts, plus one page per post.

    Every post also lives on its own URL. A fragment is not a document: search engines
    index /posts/ and nothing under it, so 22 texts had no title, no description, no
    sitemap entry and no citable address of their own. The collection page still carries
    every post in full — that is what it is for — and keeps the old #YYYY-MM-DD anchors,
    so every deep link ever taken still lands.

    The slug is stored in social-posts.json, never derived from the text here. A slug
    computed from the first line would move the page the day a typo in that line is
    fixed, orphaning the old directory and leaving a stale sitemap entry behind."""
    if not SOCIAL_JSON.exists():
        return []
    posts = json.loads(SOCIAL_JSON.read_text(encoding="utf-8"))
    posts.sort(key=lambda p: p.get("datetime", p["date"]), reverse=True)
    # Anchors are STORED in social-posts.json, not derived. The old per-day counter was
    # assigned in datetime order, so back-filling a post earlier in a day that already
    # had one would have renumbered the existing post from "2026-07-25" to
    # "2026-07-25-2" — moving both its #fragment and its corpus id "posts-<anchor>",
    # the one identifier this archive promises not to move. Only a post with no stored
    # anchor gets one, and it takes the first free suffix, touching nothing else.
    used = {p["anchor"] for p in posts if p.get("anchor")}
    for p in sorted(posts, key=lambda x: x.get("datetime", x["date"])):
        if p.get("anchor"):
            continue
        a, n = p["date"], 1
        while a in used:
            n += 1
            a = f"{p['date']}-{n}"
        p["anchor"] = a
        used.add(a)
    slugs = [p.get("slug", "") for p in posts]
    for p in posts:
        if not SLUG_RE.match(p.get("slug") or ""):
            sys.exit(f"error: post {p['date']} has no valid slug: {p.get('slug')!r}")
    if len(set(slugs)) != len(slugs):
        dup = [s for s in set(slugs) if slugs.count(s) > 1]
        sys.exit(f"error: duplicate post slug(s): {dup}")

    blocks, parts, cur_year = [], [], None
    for p in posts:
        if p["date"][:4] != cur_year:
            cur_year = p["date"][:4]
            blocks.append(f'      <h2 class="year" id="rok-{cur_year}">{cur_year}</h2>')
        lang = p.get("lang", "en")
        # Real width/height, so a lazy image cannot shift the layout as it loads, and a
        # real alt: these are result figures and screenshots, not decoration. alt=""
        # tells a screen reader to skip the image entirely.
        sizes, alts, imgs = p.get("image_size") or [], p.get("image_alt") or [], ""
        for i, f in enumerate(p.get("images", [])):
            wh = (f' width="{sizes[i][0]}" height="{sizes[i][1]}"'
                  if i < len(sizes) and sizes[i][0] else "")
            imgs += (f'\n        <img src="{PATH}/social-img/{esc(f)}"'
                     f' alt="{esc(alts[i] if i < len(alts) else "")}"'
                     f' loading="lazy" decoding="async"{wh}>')
        orig = (f' <a class="post-src" href="{esc(p["url"])}" rel="nofollow">'
                f'{"originál" if lang == "cs" else "original"}</a>') if p.get("url") else ""
        # Several posts say "link in the comments". Those links are in the export's
        # Comments file, so the post need not point at something unreachable.
        ro = ""
        if p.get("reshare_of"):
            r = p["reshare_of"]
            ro = ('\n        <p class="post-context">' + esc(r["label"]) + ': '
                  + f'<a href="{esc(r["url"])}">{esc(r["url_label"])}</a></p>')
        cl = ""
        if p.get("comment_links"):
            lab = ("Odkazy, které autorka doplnila v komentářích:" if lang == "cs"
                   else "Links the author added in the comments:")
            items = "".join(f'<li><a href="{esc(u)}"{_rel(u)}>{esc(u)}</a></li>'
                            for u in p["comment_links"])
            cl = f'\n        <div class="post-links"><p>{lab}</p><ul>{items}</ul></div>'
        # lnkd.in shorteners resolved to where they actually point. The post text keeps
        # the shortener the author published — that is what she wrote, and rewriting a
        # link's visible text to differ from its href is how phishing looks. The
        # destination is disclosed instead, so the record survives lnkd.in going away.
        lm = ""
        if p.get("link_map"):
            lab = ("Kam zkrácené odkazy vedou:" if lang == "cs"
                   else "Where the short links go:")
            items = "".join(
                f'<li><code>{esc(s.replace("https://", ""))}</code> → '
                f'<a href="{esc(d)}"{_rel(d)}>{esc(d)}</a></li>'
                for s, d in p["link_map"].items())
            lm = f'\n        <div class="post-links"><p>{lab}</p><ul>{items}</ul></div>'
        perma = f"{PATH}/posts/{p['slug']}/"
        content = f'        {_social_html(p["text"])}{ro}{cl}{lm}{imgs}'
        # The collection keeps the anchor id so old #YYYY-MM-DD links still scroll, and
        # its date is now the ordinary <a href> a crawler follows to reach the post's
        # own page. JSON-LD is not a discovery mechanism; a link is.
        blocks.append(
            f'      <article class="post" id="{esc(p["anchor"])}" lang="{lang}">\n'
            f'        <p class="post-date"><a href="{perma}">'
            f'<time datetime="{p["date"]}">{esc(cs_date(p["date"], lang=lang))}</time></a>'
            f'{orig}</p>\n{content}\n'
            f'      </article>')
        canon = f"{BASE}/posts/{p['slug']}/"
        head = _headline(p["text"])
        # The post's own opening line is its headline and stays the <h1> -- this is an
        # archive of what she wrote, so that line is not ours to reword. But two pages on
        # one domain must not compete for the same <title>: when a post opens with the
        # same words as the paper page it comments on, a search engine picks one and
        # suppresses the other. `page_title` renames the PAGE only. The h1 and the
        # SocialMediaPosting headline keep her words.
        ptitle = p.get("page_title") or head
        node = {
            "@type": "SocialMediaPosting",
            "@id": canon + "#post",
            "mainEntityOfPage": canon,
            "headline": head,
            # A post exported from LinkedIn carries a timestamp; one transcribed by
            # hand may only have its date. Appending a UTC offset to a bare date would
            # emit "2026-07-25+00:00", which is not a valid datetime — and inventing a
            # time to avoid that would be worse.
            "datePublished": (p["datetime"].replace(" ", "T") + "+00:00"
                              if p.get("datetime") else p["date"]),
            "inLanguage": lang,
            "url": canon,
            "author": {"@type": "Person", "@id": f"{SITE}/#zi", "name": "Zuzana Havránková",
                       "sameAs": ORCIDS["Zuzana Havránková"]},
            "text": p["text"],
        }
        if p.get("url"):
            node["sameAs"] = p["url"]
        if p.get("images"):
            node["image"] = [f"{SITE}{PATH}/social-img/{f}" for f in p["images"]]
        # One entity, one @id. The collection references the post; it does not restate
        # it. Two full nodes with identical text and different @ids would assert two
        # different things exist.
        parts.append({"@type": "SocialMediaPosting", "@id": canon + "#post",
                      "url": canon, "headline": head,
                      "datePublished": node["datePublished"], "inLanguage": lang})
        pbody = (
            '    <article class="post post-single reading" '
            f'lang="{lang}">\n'
            f'      <div class="article-head">\n        <h1>{esc(head)}</h1>\n'
            f'        <div class="byline"><span>'
            f'<time datetime="{p["date"]}">{esc(cs_date(p["date"], lang=lang))}</time>'
            f'</span><span>Zuzana Havránková</span><span>LinkedIn</span></div>\n'
            f'      </div>\n'
            f'        {_social_html(_social_body_after_headline(p["text"]))}'
            f'{ro}{cl}{lm}{imgs}\n'
            f'      <div class="provenance"><p>'
            + (((f'Původně zveřejněno na <a href="{esc(p["url"])}" rel="nofollow">'
                 'LinkedInu</a>. ') if lang == "cs" else
                (f'Originally posted on <a href="{esc(p["url"])}" rel="nofollow">'
                 'LinkedIn</a>. ')) if p.get("url") else "")
            + (f'V plném znění mezi <a href="{PATH}/posts/">všemi příspěvky</a>.'
               if lang == "cs" else
               f'Archived in full among <a href="{PATH}/posts/">all posts</a>.')
            + '</p></div>\n'
            '    </article>\n')
        pjson = {"@context": "https://schema.org", "@graph": [
            {"@type": "WebPage", "@id": canon, "url": canon, "name": ptitle,
             "inLanguage": lang, "isPartOf": {"@id": f"{BASE}/posts/#collection"},
             "about": {"@id": canon + "#post"}},
            node]}
        d = KDIR / "posts" / p["slug"]
        d.mkdir(parents=True, exist_ok=True)
        (d / "index.html").write_text(
            shell(ptitle, _post_desc(p["text"]), canon, pjson, pbody, "posts", lang=lang),
            encoding="utf-8")

    jsonld = {"@context": "https://schema.org", "@graph": [
        {"@type": "CollectionPage", "@id": f"{BASE}/posts/#collection",
         "url": f"{BASE}/posts/",
         "name": "Posts — Zuzana Irsova Havrankova", "description": SOCIAL_DESC,
         # This page is English, unlike the rest of the archive: the posts are mostly
         # English and the readership is international. Each post still declares its own
         # language, so the handful of Czech ones are marked.
         "inLanguage": "en",
         "hasPart": parts}]}

    # shell() already opens <main><div class="wrap">; a second one here doubled the
    # padding and made this the narrowest page on the site.
    years = sorted({p["date"][:4] for p in posts}, reverse=True)
    jump = " · ".join(f'<a href="#rok-{y}">{y}</a>' for y in years)
    body = (
        '    <div class="lede reading">\n'
        '      <h1>Posts</h1>\n'
        f'      <p>{esc(SOCIAL_DESC)}</p>\n'
        f'      <p class="post-jump">{jump}</p>\n'
        '    </div>\n'
        '    <div class="posts reading">\n' + "\n".join(blocks) + "\n    </div>\n")

    out = KDIR / "posts"
    out.mkdir(exist_ok=True)
    (out / "index.html").write_text(
        shell("Posts — Zuzana Irsova Havrankova", SOCIAL_DESC, f"{BASE}/posts/", jsonld, body,
              "posts", lang="en"),
        encoding="utf-8")
    # The section was briefly live at /ze-siti/. Leave a redirect so that address, and
    # anything that captured it, still lands in the right place.
    old = KDIR / "ze-siti"
    old.mkdir(exist_ok=True)
    (old / "index.html").write_text(
        '<!doctype html>\n<html lang="en">\n<meta charset="utf-8">\n'
        # The refresh fires immediately, so this is only ever seen when it does not --
        # and then it is a line of text a phone should not have to zoom into.
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
        f'<title>Moved to {BASE}/posts/</title>\n'
        f'<link rel="canonical" href="{BASE}/posts/">\n'
        f'<meta property="og:url" content="{BASE}/posts/">\n'
        '<meta name="robots" content="noindex,follow">\n'
        f'<meta http-equiv="refresh" content="0; url={BASE}/posts/">\n'
        f'<p>This page has moved to <a href="{BASE}/posts/">{BASE}/posts/</a>.</p>\n',
        encoding="utf-8")
    # main()'s orphan sweep only looks at top-level directories, and posts/ is on its
    # keep-list, so nothing would ever remove a stale posts/<slug>/. generate_seo.py
    # builds the sitemap from the filesystem, so a renamed slug would otherwise be
    # sitemapped forever.
    live = {p["slug"] for p in posts}
    for d in (KDIR / "posts").iterdir():
        if d.is_dir() and d.name not in live:
            for f in sorted(d.rglob("*"), reverse=True):
                f.unlink() if f.is_file() else f.rmdir()
            d.rmdir()
            print(f"  removed stale post page: posts/{d.name}/")
    print(f"  posts    {len(posts)} posts, {len(posts)} pages, "
          f"{sum(len(p.get('images', [])) for p in posts)} images")
    return posts


def _span(items, social):
    """Coverage of the whole download: the file-backed items and the social posts."""
    ds = [a["date"] for a in items] + [p["date"] for p in social]
    return f"{min(ds)}/{max(ds)}"


def write_data_page(items, social=()):
    """A landing page for the corpus itself, carrying schema.org Dataset markup.
    Without it the bulk files are only discoverable from a footer line; with it a
    crawler (and Google Dataset Search) gets one entry point that names the
    distributions, the licence and the coverage."""
    docs_total = len(items) + len(social)
    n_text = len([a for a in items if a["media"] == "text"]) + len(social)
    counts = {}
    for a in items:
        counts[text_status(a)] = counts.get(text_status(a), 0) + 1
    # the social posts are part of the download this page describes, so they belong in
    # its breakdown too; each stores its full text
    for _ in social:
        counts["published_full_text"] = counts.get("published_full_text", 0) + 1
    # The page itself is Czech; the corpus it describes is Czech and English. Those
    # are two different nodes — the site's convention puts the page node first.
    jsonld = {
        "@context": "https://schema.org",
        "@graph": [
            {"@type": "WebPage", "@id": f"{BASE}/data/",
             "url": f"{BASE}/data/",
             "name": f"Korpus ke stažení — Komentáře — {AUTHOR}",
             "inLanguage": "cs",
             # the hub's collection node, which is what this page is part of. Pointing
             # at BASE/ named nothing: no node with that @id exists in any graph.
             "isPartOf": {"@id": f"{BASE}/#collection"},
             "about": {"@id": f"{BASE}/data/#dataset"}},
            {"@type": "Dataset", "@id": f"{BASE}/data/#dataset",
             "name": f"Komentáře — {SITE_AUTHORS}",
             "description": HUB_DESC,
             "url": f"{BASE}/data/",
             # the page itself is Czech — its chrome, heading and lede. Each post carries
         # its own inLanguage, which is where the English/Czech mix is declared.
         "inLanguage": "cs",
             "isAccessibleForFree": True,
             "creator": [
                 {"@type": "Person", "@id": f"{SITE}/#th", "name": AUTHOR,
                  "identifier": ORCIDS[AUTHOR]},
                 {"@type": "Person", "@id": f"{SITE}/#zi", "name": "Zuzana Iršová Havránková",
                  "identifier": ORCIDS["Zuzana Havránková"]},
             ],
             "temporalCoverage": f"{_span(items, social)}",
             "license": "https://creativecommons.org/licenses/by/4.0/",
             "distribution": [
                 {"@type": "DataDownload", "name": "corpus.jsonl",
                  "encodingFormat": "application/x-ndjson",
                  "contentUrl": f"{BASE}/corpus.jsonl"},
                 {"@type": "DataDownload", "name": "index.json",
                  "encodingFormat": "application/json",
                  "contentUrl": f"{BASE}/index.json"},
                 {"@type": "DataDownload", "name": "all.md",
                  "encodingFormat": "text/markdown", "contentUrl": f"{BASE}/all.md"},
                 {"@type": "DataDownload", "name": "feed.xml",
                  "encodingFormat": "application/rss+xml",
                  "contentUrl": f"{BASE}/feed.xml"},
             ]},
        ],
    }
    rows = "".join(
        f"<li><strong>{esc(k)}</strong> — {v}</li>"
        for k, v in sorted(counts.items(), key=lambda kv: -kv[1]))
    body = f"""<h1>Korpus ke stažení</h1>
      <p class="lede">Celý archiv strojově čitelně: {docs_total} záznamů,
        z toho {n_text} s textem. Soubory se generují při každém sestavení webu.</p>
      <h2>Soubory</h2>
      <ul class="items">
        <li><a href="{PATH}/corpus.jsonl">corpus.jsonl</a> — jeden záznam na řádek
          (NDJSON), včetně plného textu. Formát, který čtou datové nástroje přímo.</li>
        <li><a href="{PATH}/index.json">index.json</a> — totéž jako jeden dokument JSON.</li>
        <li><a href="{PATH}/all.md">all.md</a> — všechny texty v jednom Markdownu.</li>
        <li><a href="{PATH}/manifest.json">manifest.json</a> — počty, rozsah a kontrolní
          součty SHA-256 každého souboru.</li>
        <li><a href="{PATH}/feed.xml">feed.xml</a> — RSS s plným textem.</li>
        <li><a href="{PATH}/src/">/komentare/src/</a> — zdrojový Markdown každé položky.
          Kratší příspěvky ze sítí zdrojový soubor nemají; jejich data jsou v
          <a href="{PATH}/social-posts.json">social-posts.json</a>.</li>
      </ul>
      <h2>Úplnost textu</h2>
      <p>Každý záznam nese pole <code>text_status</code>, aby bylo zřejmé, co archiv
        skutečně obsahuje:</p>
      <ul class="items">{rows}</ul>
      <p class="about-machine" lang="en">Every record carries a <code>text_status</code>
        field, so a consumer can tell a published text from the author's own version,
        from a publisher's teaser, from an audio/video record that stores no text.</p>"""
    page = shell(f"Korpus ke stažení — Komentáře — {SITE_AUTHORS}",
                 f"Strojově čitelný korpus: {docs_total} záznamů, "
                 "corpus.jsonl, index.json, all.md a manifest s kontrolními součty.",
                 f"{BASE}/data/", jsonld, body, "", lang="cs")
    (KDIR / "data").mkdir(exist_ok=True)
    (KDIR / "data" / "index.html").write_text(page, encoding="utf-8")


def write_src_index(items):
    """GitHub Pages serves no directory listing, so /komentare/src/ 404s even though
    every file under it is fetchable. The footer advertises that path, so give it a
    real index — it is also the most convenient entry point for a scraper."""
    # List every source file, including the link-only stubs. They are real files with
    # real front matter; the page used to omit them and then explain that they did not
    # exist, which was both a broken listing and a false statement.
    rows, n_text = [], 0
    for a in items:
        note = "" if a["media"] == "text" else f', {MEDIA_LABEL[a["media"]]}, odkaz'
        n_text += a["media"] == "text"
        rows.append(f'<li><a href="{PATH}/src/{esc(a["file"])}">{esc(a["file"])}</a> '
                    f'— {esc(a["headline"])} <span class="src-meta">({esc(a["outlet"])}, '
                    f'{a["date"]}{note})</span></li>')
    page = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Markdown sources — Komentáře</title>
<meta name="description" content="Plain Markdown source of every file-backed item in the Komentare archive." />
<link rel="stylesheet" href="{PATH}/style.css" />
<link rel="canonical" href="{BASE}/src/" />
<meta property="og:url" content="{BASE}/src/" />
<meta name="robots" content="noindex, follow" />
</head>
<body>
<header class="masthead"><div class="wrap">
  <p class="site-name"><a href="{PATH}/">Komentáře<small>{SITE_AUTHORS_TOP}</small></a></p>
  <nav class="nav"><a href="{PATH}/">Back to the archive</a></nav>
</div></header>
<main><div class="wrap">
  <div class="lede">
    <h1>Markdown sources</h1>
    <p>One file per item, with YAML front matter. {len(rows)} files: {n_text} carry the
       article text, the other {len(rows) - n_text} are audio or video and hold metadata
       only, since the archive links to those rather than transcribing them. The short
       posts are not here — they have no Markdown source and come from
       <a href="{PATH}/social-posts.json">social-posts.json</a>. For bulk use prefer
       <a href="{PATH}/index.json">index.json</a> (metadata for every record, full text
       where available) or <a href="{PATH}/all.md">all.md</a>.</p>
  </div>
  <ul class="items src-list">
{chr(10).join(rows)}
  </ul>
</div></main>
<footer class="foot"><div class="wrap"></div></footer>
</body>
</html>
"""
    (KDIR / "src" / "index.html").write_text(page, encoding="utf-8")
    return len(rows)


def update_sitemap(items):
    """No longer writes sitemap.xml.

    tools/generate_seo.py owns sitemap.xml for the whole site and runs on every
    push; it lists this section's pages via its SELF_MANAGED handling. Two writers
    for one file meant whichever ran last silently dropped the other's URLs.
    """
    return sum(1 for a in items if a["media"] == "text") + 1 + len(SECTIONS)


def _retired_update_sitemap(items):
    sm = ROOT / "sitemap.xml"
    t = sm.read_text(encoding="utf-8")
    t = re.sub(r"\s*<url><loc>https://meta-analysis\.cz/komentare/[^<]*</loc>[^\n]*</url>", "", t)
    urls = [f"{BASE}/"] + [f"{BASE}/{k}/" for k in SECTIONS]
    rows = [f'  <url><loc>{u}</loc><lastmod>{items[0]["date"]}</lastmod></url>' for u in urls]
    rows += [f'  <url><loc>{BASE}/{a["slug"]}/</loc><lastmod>{a["date"]}</lastmod></url>'
             for a in items if a["media"] == "text"]
    sm.write_text(t.replace("</urlset>", "\n".join(rows) + "\n</urlset>"), encoding="utf-8")
    return len(rows)


def main():
    srcs = sorted((KDIR / "src").glob("*.md"))
    if not srcs:
        sys.exit("error: komentare/src/ is empty")
    items = [parse(p) for p in srcs]

    slugs = [a["slug"] for a in items]
    dup = {s for s in slugs if slugs.count(s) > 1}
    if dup:
        sys.exit(f"error: duplicate slugs: {', '.join(sorted(dup))}")

    heads = [a["headline"] for a in items]
    DUP_HEADLINES.update(h for h in heads if heads.count(h) > 1)

    BY_SLUG.update({a["slug"]: a for a in items})
    # `translation:` has to be declared from both sides, or one page would claim a pair
    # the other does not, which is worse than no hreflang at all.
    for a in items:
        t = a.get("translation")
        if t and BY_SLUG.get(t, {}).get("translation") != a["slug"]:
            sys.exit(f"error: {a['slug']} says translation: {t}, but {t} does not say so back")

    items.sort(key=lambda a: (a["date"], a["headline"]), reverse=True)

    # remove pages whose source is gone — otherwise a deleted or renamed item keeps
    # serving, stays in search results, and can leak text we deliberately withdrew
    # "data" is the corpus landing page: generated, not slug-backed, so it must be
    # named here or the orphan sweep below would delete it on every rebuild.
    # "posts" and "social-img" are generated the same way "data" is — not backed by a
    # slug — so they must be named here or the sweep below deletes them every rebuild.
    # "files" holds hosted documents (the CNB advisor-opinion PDFs); static, not
    # slug-backed, so the sweep must spare it like the other generated directories.
    live = ({a["slug"] for a in items if a["media"] == "text"} | set(SECTIONS)
            | {"data", "posts", "ze-siti", "social-img", "item-img", "files"})
    orphans = [d for d in KDIR.iterdir()
               if d.is_dir() and d.name not in live and d.name not in ("src", "__pycache__")]
    for d in orphans:
        for f in d.rglob("*"):
            if f.is_file():
                f.unlink()
        d.rmdir()
        print(f"  removed orphan page: {d.name}/")

    for a in items:
        if a["media"] == "text":
            write_item(a)
    # The posts page runs FIRST: it computes the anchors, and every writer below needs
    # the post list — the hub for its newest-post line, the feed for lastBuildDate, and
    # the corpus and data page for their counts.
    social = write_socials_page()
    write_index(items)
    for k in SECTIONS:
        write_index(items, k)
    write_feed(items, social)
    n_txt = write_machine_readable(items, social)
    write_data_page(items, social)
    n_src = write_src_index(items)
    n = update_sitemap(items)

    by = {}
    for a in items:
        by.setdefault(a["category"], []).append(a)
    for k, v in by.items():
        av = sum(1 for x in v if x["media"] != "text")
        print(f"  {SECTIONS[k]['short']:<12} {len(v):3}" + (f"  ({av} audio/video, odkaz)" if av else ""))
    print(f"  {'celkem':<12} {len(items):3}")
    print(f"\n  hub      {BASE}/")
    print(f"  feed     {BASE}/feed.xml")
    print(f"  sitemap  {n} URLs")


def check():
    """Validate the generated output. Run by CI so a broken page in this
    self-managed section cannot pass silently (the site-wide verifier skips it)."""
    import xml.etree.ElementTree as ET
    fails = []
    # ze-siti/ is a redirect stub left behind when the section moved to /posts/: no
    # JSON-LD, no chrome, deliberately noindex. Not a page to validate.
    pages = [p for p in KDIR.rglob("index.html")
             if "src" not in p.parts and "ze-siti" not in p.parts]
    for p in pages:
        t = p.read_text(encoding="utf-8")
        m = re.search(r'<script type="application/ld\+json">' + chr(92) + 'n(.*?)' + chr(92) + 'n</script>', t, re.S)
        if not m:
            fails.append(f"{p.name}: no JSON-LD")
            continue
        try:
            d = json.loads(m.group(1))
        except Exception as e:
            fails.append(f"{p}: JSON-LD does not parse ({e})")
            continue
        if "ScholarlyArticle" in m.group(1):
            fails.append(f"{p}: ScholarlyArticle leaked into commentary")
        if t.count('rel="canonical"') != 1:
            fails.append(f"{p}: {t.count('rel=canonical')} canonical tags, expected 1")
        for tag in ('property="og:title"', 'property="og:url"'):
            if t.count(tag) > 1:
                fails.append(f"{p}: duplicate {tag}")
        # Counting the tags said nothing about what they point AT. That mattered once
        # `mirror:` started sending a record's canonical to /notes/: a canonical aimed at
        # the wrong page is invisible to a count, and og:url or the JSON-LD drifting away
        # from it is exactly the disagreement this archive exists not to have.
        _can = re.search(r'<link rel="canonical" href="([^"]+)"', t)
        if not _can:
            fails.append(f"{p}: canonical tag has no href")
        else:
            _href = _can.group(1)
            _og = re.search(r'property="og:url" content="([^"]+)"', t)
            if _og and _og.group(1) != _href:
                fails.append(f"{p}: og:url {_og.group(1)} != canonical {_href}")
            # Every page emits {"@context": ..., "@graph": [...]}, so reading these keys
            # off the top level found nothing and the comparison silently passed on all
            # 228 pages. Walk the graph nodes for the article itself.
            _nodes = d.get("@graph") if isinstance(d.get("@graph"), list) else [d]
            _seen = 0
            for _n in _nodes:
                if not isinstance(_n, dict):
                    continue
                if not str(_n.get("@type", "")).endswith(("Article", "Posting")):
                    continue
                for _key in ("mainEntityOfPage", "url"):
                    _v = _n.get(_key)
                    if isinstance(_v, dict):
                        _v = _v.get("@id") or _v.get("url")
                    if isinstance(_v, str):
                        _seen += 1
                        if _v != _href:
                            fails.append(
                                f"{p}: JSON-LD {_key} {_v} != canonical {_href}")
            # Hub, section and data pages carry no article node and have nothing to
            # compare. Demand the comparison exactly where an article node exists --
            # that also catches an article node that has lost its url entirely.
            _isart = any(isinstance(_n, dict)
                         and str(_n.get("@type", "")).endswith(("Article", "Posting"))
                         for _n in _nodes)
            if _isart and not _seen:
                fails.append(f"{p}: no JSON-LD url to compare against the canonical")
        ml = re.search(r'<html lang="([a-z]+)"', t)
        if not ml:
            fails.append(f"{p}: no lang")
        else:
            want = "en_GB" if ml.group(1) == "en" else "cs_CZ"
            loc = re.search(r'og:locale" content="([^"]+)"', t)
            if loc and loc.group(1) != want:
                fails.append(f"{p}: lang {ml.group(1)} but og:locale {loc.group(1)}")
    for f in ("feed.xml",):
        try:
            ET.parse(KDIR / f)
        except Exception as e:
            fails.append(f"{f}: not well-formed ({e})")
    try:
        j = json.loads((KDIR / "index.json").read_text(encoding="utf-8"))
        # One record per source file, plus the social posts — they have no source file
        # of their own, coming from social-posts.json and sharing a single page.
        n_social = (len(json.loads(SOCIAL_JSON.read_text(encoding="utf-8")))
                    if SOCIAL_JSON.exists() else 0)
        expected = len(list((KDIR / "src").glob("*.md"))) + n_social
        if j["count"] != expected:
            fails.append(f"index.json count {j['count']} != {expected} "
                         f"(sources + {n_social} social posts)")
        if sum(1 for d in j["items"] if d.get("genre") == "social_post") != n_social:
            fails.append("index.json is missing the social posts")
        # The manifest and the data page each drifted to describing 176 records while
        # shipping 198, and nothing caught it. These four assertions close that class.
        mf = json.loads((KDIR / "manifest.json").read_text(encoding="utf-8"))
        if mf["records"]["total"] != expected:
            fails.append(f"manifest total {mf['records']['total']} != {expected}")
        for _k in ("by_section", "by_text_status"):
            if sum(mf["records"][_k].values()) != expected:
                fails.append(f"manifest {_k} sums to "
                             f"{sum(mf['records'][_k].values())}, not {expected}")
        if mf["newest_record"] != mf["temporal_coverage"].split("/")[1]:
            fails.append("manifest newest_record disagrees with temporal_coverage")
        # every status that occurs must also be explained, or the corpus ships a value
        # a consumer cannot interpret
        _un = set(mf["records"]["by_text_status"]) - set(mf["text_status_meanings"])
        if _un:
            fails.append(f"text_status values with no meaning given: {sorted(_un)}")
        _idx = json.loads((KDIR / "index.json").read_text(encoding="utf-8"))
        _pr = {r["provenance"] for r in _idx["items"] if r.get("provenance")}
        _unp = _pr - set(mf.get("provenance_meanings", {}))
        if _unp:
            fails.append(f"provenance values with no meaning given: {sorted(_unp)}")
        # The src/*.md files are served publicly and linked from every page as the
        # plain-text source, so a word_count in their front matter that disagrees with
        # the one in the corpus is a visible contradiction. It had drifted in 55 files.
        # Count from the source file itself, not from index.json. Reading the generated
        # file would let an edited source pass whenever the generated output happens to
        # be stale, which is exactly when the check is worth having.
        for _p in sorted((KDIR / "src").glob("*.md")):
            _t = _p.read_text(encoding="utf-8")
            _m = re.search(r'^word_count:\s*"(\d+)"', _t, re.M)
            if not _m:
                continue
            # strip front matter, then the H1, exactly as parse() does above — splitting
            # on the first blank line instead would swallow the opening paragraph of
            # every record whose heading is not followed by one
            _parts = _t.split("---\n", 2)
            _body = _parts[2] if len(_parts) > 2 else ""
            _want = len(re.sub(r"^\s*#\s+.*?\n", "", _body, count=1).strip().split())
            if int(_m.group(1)) != _want:
                fails.append(f"{_p.name}: front-matter word_count {_m.group(1)} "
                             f"!= body {_want}")
        _dp = (KDIR / "data" / "index.html").read_text(encoding="utf-8")
        if f"{expected} záznamů" not in _dp:
            fails.append(f"data page does not report {expected} záznamů")
        # match the breakdown rows themselves. An earlier version took the first three
        # "— N" runs in the stripped page, which silently broke the day a fourth
        # text_status appeared: the sum then covered part of the list and failed.
        _br = [int(x) for x in
               re.findall(r"<li><strong>[a-z_]+</strong> — (\d+)</li>", _dp)]
        if not _br:
            fails.append("data page has no text_status breakdown rows")
        if sum(_br) != expected:
            fails.append(f"data page text_status breakdown sums to {sum(_br)}, "
                         f"not {expected}")
        _fx = (KDIR / "feed.xml").read_text(encoding="utf-8")
        _lb = re.search(r"<lastBuildDate>(.*?)</lastBuildDate>", _fx)
        # check() reads from disk; there is no `items` in this scope
        _new = max(d["date"] for d in j["items"])
        if _lb and rfc822(_new) != _lb.group(1):
            fails.append(f"feed lastBuildDate {_lb.group(1)} is not the newest content "
                         f"({_new})")
        # the social data path has no src/*.md behind it, so nothing else checks it
        if SOCIAL_JSON.exists():
            sp = json.loads(SOCIAL_JSON.read_text(encoding="utf-8"))
            seen = {}
            for p in sp:
                for f in p.get("images", []):
                    if not (KDIR / "social-img" / f).exists():
                        fails.append(f"social image missing on disk: {f}")
                    if f in seen:
                        fails.append(f"social image used by two posts: {f}")
                    seen[f] = 1
                if len(p.get("image_alt") or []) != len(p.get("images") or []):
                    fails.append(f"social post {p['date']} has images without alt text")
            html_ze = (KDIR / "posts" / "index.html").read_text(encoding="utf-8")
            anch = re.findall(r'<article class="post" id="([^"]+)"', html_ze)
            if len(anch) != len(set(anch)):
                fails.append("posts page has duplicate anchors")
            if len(anch) != len(sp):
                fails.append(f"posts page renders {len(anch)} posts, data has {len(sp)}")
            # The only guard against editing social-posts.json and committing without a
            # rebuild: generate_seo.py sitemaps posts/ from the filesystem, so a missing
            # page is silently absent and a stale one is sitemapped forever.
            slugs = {p.get("slug") for p in sp}
            if len(slugs) != len(sp) or None in slugs:
                fails.append("post slugs are missing or not unique")
            # anchors must be stored, not recomputed, or a same-day post can move one
            anchors = [p.get("anchor") for p in sp]
            if None in anchors:
                fails.append("some posts have no stored anchor in social-posts.json")
            if len(set(anchors)) != len(anchors):
                fails.append("post anchors are not unique")
            on_disk = {d.name for d in (KDIR / "posts").iterdir() if d.is_dir()}
            for miss in sorted(slugs - on_disk):
                fails.append(f"post page not built: posts/{miss}/")
            for extra in sorted(on_disk - slugs):
                fails.append(f"stale post page on disk: posts/{extra}/")
            for p in sp:
                u = f"{BASE}/posts/{p['slug']}/"
                if u not in {d.get("url") for d in j["items"]}:
                    fails.append(f"post url absent from index.json: {u}")
    except Exception as e:
        fails.append(f"index.json: {e}")
    print(f"checked {len(pages)} pages")
    for f in fails:
        print("  FAIL", f)
    print("OK" if not fails else f"{len(fails)} FAILURES")
    return 1 if fails else 0


def check_fresh():
    """Is what is on disk what a fresh build produces?

    check() below validates the SHAPE of each page: its JSON-LD parses, its counts add
    up. It said OK with a stale komentare/english/index.html and a stale llms.txt on
    disk, because neither is an item page and nothing compared their bytes to anything.
    A category page or an llms.txt that no longer matches its own sources can therefore
    ship. Build, then compare: the build is idempotent, so any file whose bytes move is
    a file that was committed stale."""
    # everything the build writes; not the hand-kept inputs beside them
    def generated():
        skip = ("src", "files", "item-img")
        return sorted(f for f in KDIR.rglob("*")
                      if f.is_file() and not set(skip) & set(f.parts)
                      and f.suffix in (".html", ".txt", ".xml", ".md", ".json", ".jsonl"))
    before = {f: f.read_bytes() for f in generated()}
    main()
    drift = [f for f in generated() if before.get(f) != f.read_bytes()]
    for f in drift:
        print(f"  FAIL {f.relative_to(KDIR.parent)}: not what a fresh build produces")
    if drift:
        print(f"{len(drift)} stale file(s); run: python komentare/build.py")
    return 1 if drift else 0


if __name__ == "__main__":
    if "--check" in sys.argv:
        sys.exit(check_fresh() | check())
    main()
