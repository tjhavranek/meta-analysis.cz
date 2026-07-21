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


# ----------------------------------------------------------------- helpers ---

def esc(s):
    return html.escape(s or "", quote=True)


def fix_quotes(s):
    """The Seznam extraction leg closed Czech „…“ pairs with an ASCII quote."""
    return re.sub(r'„([^„“"]{0,400}?)"', r"„\1“", s or "")


def cs_date(iso, precision=None):
    d = datetime.strptime(iso, "%Y-%m-%d")
    if precision == "month":
        return f"{MONTHS_NOM[d.month - 1]} {d.year}"
    return f"{d.day}. {MONTHS[d.month - 1]} {d.year}"


def rfc822(iso):
    return datetime.strptime(iso, "%Y-%m-%d").replace(tzinfo=timezone.utc) \
        .strftime("%a, %d %b %Y %H:%M:%S +0000")


def people(raw):
    names = [n.strip() for n in re.split(r",| a ", raw or AUTHOR) if n.strip()]
    return names or [AUTHOR]


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
    nav = "".join(
        f'<a href="{PATH}/{k}/"{" aria-current=\"page\"" if active == k else ""}>{esc(v["short"])}</a>'
        for k, v in SECTIONS.items())
    rss_title = "Komentáře — Tomáš Havránek"
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
    <nav class="nav">{nav}<a href="{PATH}/">Vše</a></nav>
  </div>
</header>
<main>
  <div class="wrap">
{body}
  </div>
</main>
<footer class="foot">
  <div class="wrap about">
    <p class="about-bio"><strong>Tomáš Havránek</strong> je profesor ekonomie na Institutu
      ekonomických studií FSV Univerzity Karlovy v Praze. Zabývá se měnovou politikou,
      metaanalýzou a metavýzkumem; byl poradcem viceguvernéra a bankovní rady ČNB.
      Je výzkumným pracovníkem CEPR v Londýně a affiliate Stanford METRICS.
      Tato stránka archivuje jeho publicistiku — komentáře, sloupky a rozhovory.</p>
    <ul class="about-links">
      <li><a href="https://www.tomashavranek.cz/">Osobní stránka</a></li>
      <li><a href="{SITE}/">meta-analysis.cz</a></li>
      <li><a href="https://ies.fsv.cuni.cz/">IES FSV UK</a></li>
      <li><a href="https://orcid.org/0000-0002-3158-2539">ORCID</a></li>
      <li><a href="https://scholar.google.com/citations?user=BF0BvBkAAAAJ">Google Scholar</a></li>
      <li><a href="https://ideas.repec.org/f/pha418.html">RePEc / IDEAS</a></li>
      <li><a href="https://cepr.org/about/people/tomas-havranek">CEPR</a></li>
      <li><a href="https://metrics.stanford.edu/people/tomas-havranek">Stanford METRICS</a></li>
      <li><a href="{PATH}/feed.xml">RSS</a></li>
    </ul>
  </div>
</footer>
</body>
</html>
"""


FILTER = """    <div class="filter">
      <div class="filter-row js-only">
        <input type="search" id="q" placeholder="Hledat v titulcích a textu…" aria-label="Hledat" />
        <button class="chip" data-cat="all" aria-pressed="true">Vše</button>
        <button class="chip" data-cat="celostatni" aria-pressed="false">Celostátní</button>
        <button class="chip" data-cat="litomysl" aria-pressed="false">Litomyšl</button>
        <button class="chip" data-cat="rozhovory" aria-pressed="false">Rozhovory</button>
        <button class="chip" data-cat="english" aria-pressed="false">English</button>
      </div>
      <p class="count js-only" id="count"></p>
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
    url = f"{PATH}/{a['slug']}/" if a["media"] == "text" else (a.get("url") or "#")
    ext = "" if a["media"] == "text" else ' rel="external"'
    tag = ""
    if a["media"] in MEDIA_LABEL:
        tag = f'<span class="tag tag-av">{MEDIA_LABEL[a["media"]]}</span>'
    elif show_cat:
        tag = f'<span class="tag">{esc(SECTIONS[a["category"]]["short"])}</span>'
    bits = [f'<span>{esc(cs_date(a["date"], a.get("date_precision")))}</span>',
            f'<span class="outlet">{esc(a["outlet"])}</span>']
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
        node["author"] = ([{"@type": "Person", "name": a["interviewer"]}]
                          if a.get("interviewer") else
                          [{"@type": "Organization", "name": a["outlet"]}])
    else:
        node["author"] = persons
    if a.get("url"):
        node["isBasedOn"] = a["url"]
    if a.get("date_precision") == "month":
        node["datePublished"] = a["date"][:7]

    body_html = fix_quotes(md_to_html(a["body"]))
    plain = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", body_html)).strip()
    desc = (plain[:190].rsplit(" ", 1)[0] + "…") if len(plain) > 190 else plain
    node["description"] = desc

    meta = [f'<span>{esc(cs_date(a["date"], a.get("date_precision")))}</span>',
            f'<span>{esc(a["outlet"])}</span>']
    if a.get("issue"):
        meta.append(f'<span>č.&nbsp;{esc(a["issue"])}</span>')
    meta.append("<span>" + esc(", ".join(names)) + "</span>")
    if a.get("interviewer"):
        meta.append(f'<span>ptal se: {esc(a["interviewer"])}</span>')

    where = OUTLET_IN.get(a["outlet"], f'v médiu {a["outlet"]}')
    prov = (f'Poprvé vyšlo {where} {cs_date(a["date"], a.get("date_precision"))}.'
            + (f' <a href="{esc(a["url"])}" rel="external">Původní vydání</a>.'
               if a.get("url") else ""))

    note = f'<div class="provenance"><p>{esc(a["body_note"])}</p></div>\n' if a.get("body_note") else ""

    body = f"""    <article>
      <div class="article-head">
        <h1>{esc(a["headline"])}</h1>
        <div class="byline">{"".join(meta)}</div>
      </div>
{note}      <div class="prose reading">
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
            + f'<meta property="article:published_time" content="{a["date"]}" />\n')

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

    node = {
        "@type": "CollectionPage",
        "@id": canonical + "#collection",
        "url": canonical,
        "name": f"{title} — {AUTHOR}",
        "description": desc,
        "inLanguage": sec["lang"] if sec else "cs",
        "about": {"@type": "Person", "name": AUTHOR, "sameAs": ORCIDS[AUTHOR]},
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
                 {"@context": "https://schema.org", "@graph": [node]},
                 body, key or "", lang=(sec["lang"] if sec else "cs"))
    if not key:
        page = page.replace("</body>", SCRIPT + "</body>")
    d = KDIR if not key else KDIR / key
    d.mkdir(exist_ok=True)
    (d / "index.html").write_text(page, encoding="utf-8")


def write_feed(items):
    it = []
    for a in items[:60]:
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


def update_sitemap(items):
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

    items.sort(key=lambda a: (a["date"], a["headline"]), reverse=True)

    # remove pages whose source is gone — otherwise a deleted or renamed item keeps
    # serving, stays in search results, and can leak text we deliberately withdrew
    live = {a["slug"] for a in items if a["media"] == "text"} | set(SECTIONS)
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


if __name__ == "__main__":
    main()
