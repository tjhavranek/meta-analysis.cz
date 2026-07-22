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
    category               celostatni | litomysl | rozhovory   (default celostatni)
    media                  text | video | audio                (default text)
    url                    link to the original
    byline                 comma-separated; every name is credited
    interviewer            for rozhovory
    issue                  for Lilie, e.g. "2025/10"
    date_precision         "month" when only the issue month is known
    body_note              rendered as an editorial note above the text

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
BASE = f"{SITE}/komentare"      # absolute: canonical, og:url, JSON-LD
PATH = "/komentare"             # root-relative: every internal link and asset

AUTHOR = "Tomáš Havránek"
ORCIDS = {
    "Tomáš Havránek": "https://orcid.org/0000-0002-3158-2539",
    "Zuzana Havránková": "https://orcid.org/0000-0002-0753-8124",
    "Zuzana Irsová": "https://orcid.org/0000-0002-0753-8124",
}

SECTIONS = {
    "celostatni": dict(
        title="Celostátní komentáře",
        short="Celostátní",
        desc="Komentáře a sloupky pro celostátní média — měnová politika, inflace, "
             "veřejné finance, důchody a ceny energií.",
    ),
    "litomysl": dict(
        title="Litomyšlské sloupky",
        short="Litomyšl",
        desc="Sloupky pro Lilii, měsíčník města Litomyšle — doprava, zeleň, školství, "
             "sport a další místní témata.",
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
        desc="Columns and commentary written in English — policy pieces for VoxEU/CEPR "
             "and posts on meta-analysis methods for MAER-Net.",
        lang="en",
    ),
}
for _k, _v in SECTIONS.items():
    _v.setdefault("lang", "cs")

HUB_DESC = ("Publicistika Tomáše Havránka: komentáře pro celostátní média, sloupky pro "
            "litomyšlskou Lilii a rozhovory. Texty jsou zde archivovány v plném znění "
            "s odkazem na původní vydání.")

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
}

MEDIA_LABEL = {"video": "video", "audio": "audio"}

# headlines carried by more than one item; filled in main(). Such items always show
# their byline so that two rows never render as the same link text.
DUP_HEADLINES = set()

# How complete the stored text is. Derived from the item's own provenance note so
# that no source file has to repeat it, and so the machine-readable corpus never
# implies it holds a published text when it holds a draft or a teaser.
# Note: source == "image" means the text was read off a scanned page — still the
# published text, so it stays published_full_text. Only source == "draft" means the
# stored words are the author's version rather than what the outlet printed.
_EXCERPT_RE = re.compile(r"(?i)ukázka zveřejněná|úvodní ukázka")


def text_status(a):
    """published_full_text | author_manuscript | publisher_excerpt | link_only"""
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
    t = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<em>\1</em>", t)
    return t


def md_to_html(md):
    out, lines, i = [], (md or "").replace("\r\n", "\n").split("\n"), 0
    while i < len(lines):
        line = lines[i].rstrip()
        if not line.strip():
            i += 1
            continue
        m = re.match(r"^(#{2,4})\s+(.*)$", line)
        if m:
            lvl = min(len(m.group(1)), 4)
            out.append(f"<h{lvl}>{_inline(m.group(2))}</h{lvl}>")
            i += 1
            continue
        if line.lstrip().startswith(("- ", "* ")):
            it = []
            while i < len(lines) and lines[i].lstrip().startswith(("- ", "* ")):
                it.append(f"<li>{_inline(lines[i].lstrip()[2:].strip())}</li>")
                i += 1
            out.append("<ul>\n" + "\n".join(it) + "\n</ul>")
            continue
        if re.match(r"^\s*\d+[.)]\s+", line):
            it = []
            while i < len(lines) and re.match(r"^\s*\d+[.)]\s+", lines[i]):
                it.append(f'<li>{_inline(re.sub(r"^\s*\d+[.)]\s+", "", lines[i]).strip())}</li>')
                i += 1
            out.append("<ol>\n" + "\n".join(it) + "\n</ol>")
            continue
        if line.lstrip().startswith("> "):
            q = []
            while i < len(lines) and lines[i].lstrip().startswith("> "):
                q.append(lines[i].lstrip()[2:].strip())
                i += 1
            out.append(f"<blockquote><p>{_inline(' '.join(q))}</p></blockquote>")
            continue
        para = []
        while (i < len(lines) and lines[i].strip()
               and not lines[i].lstrip().startswith(("#", "- ", "* ", "> "))
               and not re.match(r"^\s*\d+[.)]\s+", lines[i])):
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

def shell(title, desc, canonical, jsonld, body, active, extra_head="", lang="cs"):
    # The chrome is Czech on every page, including the English ones. WCAG 3.1.2 wants
    # those runs marked, or a screen reader reads them with English phonetics.
    cs = ' lang="cs"' if lang == "en" else ""
    nav = "".join(
        f'<a href="{PATH}/{k}/"'
        f'{"" if k == "english" else cs}'
        f'{" aria-current=\"page\"" if active == k else ""}>{esc(v["short"])}</a>'
        for k, v in SECTIONS.items())
    rss_title = "Komentáře — Tomáš Havránek"
    ies = ("https://ies.fsv.cuni.cz/en/contacts/institute-members/78067720" if lang == "en"
           else "https://ies.fsv.cuni.cz/contacts/institute-members/78067720")
    bio = ("<strong>Tomáš Havránek</strong> is Professor of Economics at the Institute of "
           "Economic Studies, Charles University, Prague. He works on monetary policy, "
           "meta-analysis and meta-research, and was an adviser to the Vice-Governor and "
           "the Board of the Czech National Bank. He is a Research Affiliate at CEPR (London) "
           "and at Stanford METRICS. This section archives his published commentary, "
           "columns and interviews."
           if lang == "en" else
           "<strong>Tomáš Havránek</strong> je profesor ekonomie na Institutu ekonomických "
           "studií FSV Univerzity Karlovy v Praze. Zabývá se měnovou politikou, metaanalýzou "
           "a metavýzkumem; byl poradcem viceguvernéra a bankovní rady ČNB. Je Research "
           "Affiliate v CEPR (Londýn) a ve Stanford METRICS. Tato stránka archivuje "
           "jeho publicistiku — komentáře, sloupky a rozhovory.")
    return f"""<!DOCTYPE html>
<html lang="{lang}">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>{esc(title)}</title>
<meta name="description" content="{esc(desc)}" />
<link rel="stylesheet" href="{PATH}/style.css" />
<link rel="canonical" href="{canonical}" />
<link rel="alternate" type="application/rss+xml" title="{rss_title}" href="{PATH}/feed.xml" />
<meta property="og:site_name" content="Komentáře — Tomáš Havránek" />
<meta property="og:locale" content="{"en_GB" if lang == "en" else "cs_CZ"}" />
<meta property="og:title" content="{esc(title)}" />
<meta property="og:description" content="{esc(desc)}" />
<meta property="og:url" content="{canonical}" />
{extra_head}<script type="application/ld+json">
{json.dumps(jsonld, indent=1, ensure_ascii=False)}
</script>
<script>document.documentElement.className+=" has-js";</script>
</head>
<body>
<header class="masthead">
  <div class="wrap">
    <p class="site-name"><a href="{PATH}/">Komentáře<small>Tomáš Havránek</small></a></p>
    <nav class="nav">{nav}<a href="{PATH}/"{cs}>Vše</a></nav>
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
      <li><a href="https://www.tomashavranek.cz/"{cs}>Osobní stránka</a></li>
      <li><a href="{SITE}/">meta-analysis.cz</a></li>
      <li><a href="{ies}">IES FSV UK</a></li>
      <li><a href="https://zrusme-inflaci.cz/">Zrušme inflaci</a></li>
      <li><a href="https://orcid.org/0000-0002-3158-2539">ORCID</a></li>
      <li><a href="https://scholar.google.com/citations?user=BF0BvBkAAAAJ">Google Scholar</a></li>
      <li><a href="https://ideas.repec.org/f/pha418.html">RePEc / IDEAS</a></li>
      <li><a href="https://www.scopus.com/authid/detail.uri?authorId=24453189000">Scopus</a></li>
      <li><a href="https://cepr.org/about/people/tomas-havranek">CEPR</a></li>
      <li><a href="https://metrics.stanford.edu/people/tomas-havranek">Stanford METRICS</a></li>
      <li><a href="{PATH}/feed.xml">RSS</a></li>
    </ul>
    <p class="about-machine" lang="en">For machines:
      <a href="{PATH}/data/">the corpus</a> (JSONL, JSON, Markdown, checksums) ·
      <a href="{PATH}/llms.txt">llms.txt</a> ·
      <a href="{PATH}/index.json">index.json</a> (metadata for every item, full text where available) ·
      <a href="{PATH}/all.md">all.md</a> (every text in one file) ·
      <a href="{PATH}/feed.xml">RSS</a>. The Markdown source of each textual item is in
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
      </div>
      <p class="count js-only" id="count" role="status" aria-live="polite"></p>
      <p class="count js-only search-note">Hledá se v titulcích, názvech médií a jménech autorů.
        Fulltext ve všech textech nabízí
        <a href="https://www.google.com/search?q=site%3Ameta-analysis.cz%2Fkomentare+">Google</a>
        nebo <a href="/komentare/index.json">index.json</a>.</p>
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
      var ok = (cat === 'all' || el.dataset.cat === cat) &&
               (!term || el.dataset.hay.indexOf(term) > -1);
      el.hidden = !ok; if (ok) n++;
    });
    years.forEach(function (h) {
      var vis = false, s = h.nextElementSibling;
      if (s) Array.prototype.forEach.call(s.children, function (li) { if (!li.hidden) vis = true; });
      h.hidden = !vis; if (s) s.hidden = !vis;
    });
    count.textContent = n + (n === 1 ? ' položka' : (n < 5 ? ' položky' : ' položek'));
  }
  q.addEventListener('input', apply);
  chips.forEach(function (c) {
    c.addEventListener('click', function () {
      cat = c.dataset.cat;
      chips.forEach(function (o) { o.setAttribute('aria-pressed', o === c ? 'true' : 'false'); });
      apply();
    });
  });
  apply();
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
        bits.append(f'<span>ptal se: {esc(a["interviewer"])}</span>')
    if tag:
        bits.append(tag)
    return (f'  <li class="item" data-cat="{a["category"]}">\n'
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
    lang = a.get("lang") or SECTIONS[a["category"]]["lang"]
    names = people(a.get("byline"))
    is_iv = a["category"] == "rozhovory"

    node = {
        "@type": "Article" if is_iv else "OpinionNewsArticle",
        "@id": canonical + "#article",
        "mainEntityOfPage": canonical,
        "url": canonical,
        "headline": a["headline"],
        "inLanguage": lang,
        "datePublished": a["date"],
        "isAccessibleForFree": True,
        "publisher": {"@type": "Organization", "name": a["outlet"]},
        "articleSection": SECTIONS[a["category"]]["title"],
    }
    persons = [{k: v for k, v in (("@type", "Person"), ("name", n),
                                  ("sameAs", ORCIDS.get(n))) if v} for n in names]
    if is_iv:
        node["about"] = persons
        if a.get("written_by"):
            node["author"] = [{"@type": "Organization", "name": a["written_by"]}]
        elif a.get("interviewer"):
            node["author"] = [{"@type": "Person", "name": a["interviewer"]}]
        else:
            node["author"] = [{"@type": "Organization", "name": a["outlet"]}]
    else:
        node["author"] = persons
    if a.get("url"):
        node["isBasedOn"] = a["url"]
    if a.get("date_precision") == "month":
        node["datePublished"] = a["date"][:7]

    body_html = fix_quotes(md_to_html(a["body"]))
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
        meta.append(f'<span>text: {esc(a["written_by"])}</span>')
    if a.get("interviewer"):
        meta.append(f'<span>ptal se: {esc(a["interviewer"])}</span>')

    where = OUTLET_IN.get(a["outlet"], f'v médiu {a["outlet"]}')
    prov = (f'Poprvé vyšlo {where} {cs_date(a["date"], a.get("date_precision"), "cs")}.'
            + (f' <a href="{esc(a["url"])}" rel="external">Původní vydání</a>.'
               if a.get("url") else ""))
    # be honest about which text this is: an author manuscript can differ from what
    # the magazine printed, and for at least one Lilie column it demonstrably does
    if a.get("source") == "draft":
        prov += (" Text vychází z autorova rukopisu; tištěná verze se může v detailech lišit.")
    elif a.get("source") == "image":
        prov += (" Text byl přepsán z tištěného vydání.")

    note = f'<div class="provenance"><p>{esc(a["body_note"])}</p></div>\n' if a.get("body_note") else ""
    # the outlet's standfirst: part of the published piece, but the editor's words,
    # not the author's — so it is set apart rather than folded into the prose
    perex = (f'      <p class="perex">{esc(fix_quotes(a["perex"]))}</p>\n'
             if a.get("perex") else "")

    body = f"""    <article>
      <div class="article-head">
        <h1>{esc(a["headline"])}</h1>
        <div class="byline">{"".join(meta)}</div>
      </div>
{note}{perex}      <div class="prose reading">
{body_html}
      </div>
      <div class="provenance"><p>{prov}</p></div>
      <nav class="pager">
        <a href="{PATH}/{a["category"]}/">← {esc(SECTIONS[a["category"]]["title"])}</a>
        <a href="{PATH}/">Všechny texty</a>
      </nav>
    </article>"""

    head = (f'<meta property="og:type" content="article" />\n'
            + "".join(f'<meta name="author" content="{esc(n)}" />\n' for n in names)
            + f'<meta property="article:published_time" content="{a["date"]}" />\n'
            # plain-text source of this page, for anything that would rather not parse HTML
            + f'<link rel="alternate" type="text/markdown" '
              f'href="{PATH}/src/{esc(a["file"])}" title="Zdrojový text (Markdown)" />\n')

    # some pieces share a printed headline — two letters under one title, or an item
    # inside a shared rubric. Disambiguate the <title> so search results are distinct.
    tt = a["headline"]
    if a.get("title_suffix"):
        tt += f' ({a["title_suffix"]})'
    page = shell(f'{tt} — {", ".join(names)}', desc, canonical,
                 {"@context": "https://schema.org", "@graph": [node]},
                 body, a["category"], head, lang)
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
        "@id": f"{BASE}/#author",
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
    node = {
        "@type": "CollectionPage",
        "@id": canonical + "#collection",
        "url": canonical,
        "name": f"{title} — {AUTHOR}",
        "description": desc,
        "inLanguage": sec["lang"] if sec else "cs",
        "about": {"@id": f"{BASE}/#author"},
        "hasPart": [{
            "@type": "Article",
            "@id": (f"{BASE}/{a['slug']}/#article" if a["media"] == "text" else a.get("url", "")),
            "url": (f"{BASE}/{a['slug']}/" if a["media"] == "text" else a.get("url", "")),
            "headline": a["headline"], "datePublished": a["date"],
        } for a in sel],
    }
    counts = ""
    if not key:
        c = {k: sum(1 for a in items if a["category"] == k) for k in SECTIONS}
        counts = ("      <p>" + " · ".join(
            f'<a href="{PATH}/{k}/">{esc(SECTIONS[k]["short"])} ({c[k]})</a>'
            for k in SECTIONS if c[k]) + "</p>\n")

    body = (f'    <div class="lede">\n      <h1>{esc(title)}</h1>\n'
            f'      <p>{esc(desc)}</p>\n{counts}    </div>\n'
            + (FILTER if not key else "")
            + listing(sel, show_cat=not key))
    page = shell(f"{title} — {AUTHOR}", desc, canonical,
                 {"@context": "https://schema.org", "@graph": [node, person]},
                 body, key or "", lang=(sec["lang"] if sec else "cs"))
    if not key:
        page = page.replace("</body>", SCRIPT + "</body>")
    d = KDIR if not key else KDIR / key
    d.mkdir(exist_ok=True)
    (d / "index.html").write_text(page, encoding="utf-8")


def write_feed(items):
    it = []
    for a in items:
        url = f"{BASE}/{a['slug']}/" if a["media"] == "text" else (a.get("url") or BASE)
        content = (f"<![CDATA[{fix_quotes(md_to_html(a['body']))}]]>"
                   if a["media"] == "text" else
                   f"<![CDATA[<p>{MEDIA_LABEL.get(a['media'], '')} — "
                   f'<a href="{a.get("url", "")}">{esc(a["outlet"])}</a></p>]]>')
        it.append(f"""    <item>
      <title>{esc(a["headline"])}</title>
      <link>{url}</link>
      <guid isPermaLink="true">{url}</guid>
      <pubDate>{rfc822(a["date"])}</pubDate>
      <category>{esc(SECTIONS[a["category"]]["title"])}</category>
      <dc:language>{a.get("lang") or SECTIONS[a["category"]]["lang"]}</dc:language>
      <source url="{esc(a.get("url", ""))}">{esc(a["outlet"])}</source>
      <content:encoded>{content}</content:encoded>
    </item>""")
    (KDIR / "feed.xml").write_text(f"""<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Komentáře — {esc(AUTHOR)}</title>
    <link>{BASE}/</link>
    <atom:link href="{BASE}/feed.xml" rel="self" type="application/rss+xml" />
    <description>{esc(HUB_DESC)}</description>
    <language>cs</language>
    <lastBuildDate>{rfc822(items[0]["date"])}</lastBuildDate>
{chr(10).join(it)}
  </channel>
</rss>
""", encoding="utf-8")


def write_machine_readable(items):
    """Three bulk formats, so a crawler or a training pipeline never has to parse HTML.

    llms.txt   a plain index in the llms.txt convention
    index.json full metadata for every item, one JSON document
    all.md     every text in one Markdown file, in reverse-chronological order
    """
    # --- llms.txt -------------------------------------------------------------
    L = [f"# Komentáře — {AUTHOR}", "",
         "> " + HUB_DESC, "",
         f"Publicistika: {len(items)} položek, "
         f"{items[-1]['date'][:4]}–{items[0]['date'][:4]}. "
         "Plné znění každého textu je na uvedené adrese; "
         "zdrojový Markdown je v /komentare/src/.", ""]
    for k, sec in SECTIONS.items():
        sel = [a for a in items if a["category"] == k]
        if not sel:
            continue
        L += [f"## {sec['title']}", "", sec["desc"], ""]
        for a in sel:
            d = cs_date(a["date"], a.get("date_precision"))
            if a["media"] == "text":
                L.append(f"- [{a['headline']}]({BASE}/{a['slug']}/) — {a['outlet']}, {d}")
            else:
                L.append(f"- [{a['headline']}]({a.get('url','')}) — {a['outlet']}, {d} "
                         f"({MEDIA_LABEL.get(a['media'], '')}, pouze odkaz)")
        L.append("")
    L += ["## Další zdroje", "",
          "- [Osobní stránka](https://www.tomashavranek.cz/)",
          "- [meta-analysis.cz](https://meta-analysis.cz/)",
          "- [Zrušme inflaci](https://zrusme-inflaci.cz/) — autorova iniciativa k cenové stabilitě",
          "- [ORCID](https://orcid.org/0000-0002-3158-2539)",
          "- [Google Scholar](https://scholar.google.com/citations?user=BF0BvBkAAAAJ)",
          "- [RePEc](https://ideas.repec.org/f/pha418.html)",
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
             "media": a["media"], "original_url": a.get("url", ""),
             "text_status": text_status(a)}
        if a.get("perex"):
            d["standfirst"] = a["perex"]
            d["standfirst_note"] = "Written by the original outlet, not by the author."
        if a.get("interviewer"):
            d["interviewer"] = a["interviewer"]
        if a.get("issue"):
            d["issue"] = a["issue"]
        if a["media"] == "text":
            d["url"] = f"{BASE}/{a['slug']}/"
            d["source_markdown"] = f"{BASE}/src/{a['file']}"
            d["word_count"] = len(a["body"].split())
            d["text"] = a["body"]
        docs.append(d)
    (KDIR / "index.json").write_text(json.dumps({
        "name": f"Komentáře — {AUTHOR}",
        "description": HUB_DESC,
        "url": f"{BASE}/",
        "author": {"name": AUTHOR, "orcid": ORCIDS[AUTHOR],
                   "affiliation": "Institut ekonomických studií, FSV Univerzita Karlova"},
        "license": "Texty jsou majetkem autora a původních vydavatelů; "
                   "archiv slouží ke čtení a citaci s uvedením původního zdroje.",
        "count": len(docs), "generated_from": "komentare/src/*.md",
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
    A = [f"# Komentáře — {AUTHOR}", "", HUB_DESC, "",
         f"Tento soubor obsahuje plné znění všech textových položek "
         f"({sum(1 for a in items if a['media'] == 'text')} z celkem {len(items)}). "
         f"Zbývající položky jsou audio a video, které archiv vede pouze odkazem, "
         f"a v tomto souboru nejsou; jejich metadata najdete v index.json a corpus.jsonl.",
         "", "---", ""]
    for a in items:
        if a["media"] != "text":
            continue
        A += [f"## {a['headline']}", "",
              f"*{a['outlet']}, {cs_date(a['date'], a.get('date_precision'))}"
              + (f", ptal se {a['interviewer']}" if a.get("interviewer") else "")
              + f". {', '.join(people(a.get('byline')))}.*", "",
              f"Zdroj: {a.get('url') or BASE + '/' + a['slug'] + '/'}", "",
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
            blob = p.read_bytes()
            files[name] = {"url": f"{BASE}/{name}", "bytes": len(blob),
                           "sha256": hashlib.sha256(blob).hexdigest()}
    (KDIR / "manifest.json").write_text(json.dumps({
        "name": f"Komentáře — {AUTHOR}",
        "url": f"{BASE}/data/",
        "corpus_updated": items[0]["date"],
        "temporal_coverage": f"{items[-1]['date']}/{items[0]['date']}",
        "records": {
            "total": len(docs),
            "by_text_status": counts,
            "by_section": {SECTIONS[k]["title"]: len([a for a in items
                                                      if a["category"] == k])
                           for k in SECTIONS},
        },
        "text_status_meanings": {
            "published_full_text": "the text as published",
            "author_manuscript": "the author's own version, as sent to the outlet",
            "publisher_excerpt": "only the outlet's free teaser; the original is paywalled",
            "link_only": "audio or video; no text is stored, the record links to the source",
        },
        "files": files,
        "generated_from": "komentare/src/*.md",
    }, ensure_ascii=False, indent=1), encoding="utf-8")

    return len([a for a in items if a["media"] == "text"])


def write_data_page(items):
    """A landing page for the corpus itself, carrying schema.org Dataset markup.
    Without it the bulk files are only discoverable from a footer line; with it a
    crawler (and Google Dataset Search) gets one entry point that names the
    distributions, the licence and the coverage."""
    docs_total = len(items)
    n_text = len([a for a in items if a["media"] == "text"])
    counts = {}
    for a in items:
        counts[text_status(a)] = counts.get(text_status(a), 0) + 1
    # The page itself is Czech; the corpus it describes is Czech and English. Those
    # are two different nodes — the site's convention puts the page node first.
    jsonld = {
        "@context": "https://schema.org",
        "@graph": [
            {"@type": "WebPage", "@id": f"{BASE}/data/",
             "url": f"{BASE}/data/",
             "name": f"Korpus ke stažení — Komentáře — {AUTHOR}",
             "inLanguage": "cs",
             "isPartOf": {"@id": f"{BASE}/"},
             "about": {"@id": f"{BASE}/data/#dataset"}},
            {"@type": "Dataset", "@id": f"{BASE}/data/#dataset",
             "name": f"Komentáře — {AUTHOR}",
             "description": HUB_DESC,
             "url": f"{BASE}/data/",
             "inLanguage": ["cs", "en"],
             "isAccessibleForFree": True,
             "creator": {"@type": "Person", "name": AUTHOR,
                         "identifier": f"https://orcid.org/{ORCIDS[AUTHOR]}"},
             "temporalCoverage": f"{items[-1]['date']}/{items[0]['date']}",
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
        <li><a href="{PATH}/src/">/komentare/src/</a> — zdrojový Markdown každé položky.</li>
      </ul>
      <h2>Úplnost textu</h2>
      <p>Každý záznam nese pole <code>text_status</code>, aby bylo zřejmé, co archiv
        skutečně obsahuje:</p>
      <ul class="items">{rows}</ul>
      <p class="about-machine" lang="en">Every record carries a <code>text_status</code>
        field, so a consumer can tell a published text from the author's own version,
        from a publisher's teaser, from an audio/video record that stores no text.</p>"""
    page = shell(f"Korpus ke stažení — Komentáře — {AUTHOR}",
                 f"Strojově čitelný korpus: {docs_total} záznamů, "
                 "corpus.jsonl, index.json, all.md a manifest s kontrolními součty.",
                 f"{BASE}/data/", jsonld, body, "", lang="cs")
    (KDIR / "data").mkdir(exist_ok=True)
    (KDIR / "data" / "index.html").write_text(page, encoding="utf-8")


def write_src_index(items):
    """GitHub Pages serves no directory listing, so /komentare/src/ 404s even though
    every file under it is fetchable. The footer advertises that path, so give it a
    real index — it is also the most convenient entry point for a scraper."""
    rows = []
    for a in items:
        if a["media"] != "text":
            continue
        rows.append(f'<li><a href="{PATH}/src/{esc(a["file"])}">{esc(a["file"])}</a> '
                    f'— {esc(a["headline"])} <span class="src-meta">({esc(a["outlet"])}, '
                    f'{a["date"]})</span></li>')
    page = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Markdown sources — Komentáře</title>
<meta name="description" content="Plain Markdown source of every item in the Komentare archive." />
<link rel="stylesheet" href="{PATH}/style.css" />
<link rel="canonical" href="{BASE}/src/" />
<meta name="robots" content="noindex, follow" />
</head>
<body>
<header class="masthead"><div class="wrap">
  <p class="site-name"><a href="{PATH}/">Komentáře<small>Tomáš Havránek</small></a></p>
  <nav class="nav"><a href="{PATH}/">Back to the archive</a></nav>
</div></header>
<main><div class="wrap">
  <div class="lede">
    <h1>Markdown sources</h1>
    <p>The plain-text source of every <em>textual</em> item, one file each, with YAML
       front matter. {len(rows)} files; the archive holds {len(items)} items in total —
       the other {len(items) - len(rows)} are audio or video, kept as links only, so they
       have no source file. For bulk use prefer
       <a href="{PATH}/index.json">index.json</a> (metadata for every item, full text
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

    items.sort(key=lambda a: (a["date"], a["headline"]), reverse=True)

    # remove pages whose source is gone — otherwise a deleted or renamed item keeps
    # serving, stays in search results, and can leak text we deliberately withdrew
    # "data" is the corpus landing page: generated, not slug-backed, so it must be
    # named here or the orphan sweep below would delete it on every rebuild.
    live = {a["slug"] for a in items if a["media"] == "text"} | set(SECTIONS) | {"data"}
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
    write_index(items)
    for k in SECTIONS:
        write_index(items, k)
    write_feed(items)
    n_txt = write_machine_readable(items)
    write_data_page(items)
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
    pages = [p for p in KDIR.rglob("index.html") if "src" not in p.parts]
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
        if j["count"] != len(list((KDIR / "src").glob("*.md"))):
            fails.append("index.json count does not match the sources")
    except Exception as e:
        fails.append(f"index.json: {e}")
    print(f"checked {len(pages)} pages")
    for f in fails:
        print("  FAIL", f)
    print("OK" if not fails else f"{len(fails)} FAILURES")
    return 1 if fails else 0


if __name__ == "__main__":
    if "--check" in sys.argv:
        sys.exit(check())
    main()
