#!/usr/bin/env python3
"""Build /publications/ and /publications/irsova/ from tools/publications.json.

    python3 tools/build_publications_page.py [--check]

One dataset, two pages: a complete journal bibliography for each of the two people who run
this site. Their records overlap almost entirely -- of Zuzana Irsova's thirty-seven articles,
thirty-six are co-authored with Tomas Havranek -- and that is what a bibliography of a research
pair looks like. Each page is that person's own record, so the joint work appears on both,
exactly as it does on their ORCID profiles. A page built by subtracting one from the other
would say something false about how the work was done.

SOURCE OF TRUTH is tools/publications.json, built from both ORCID records and enriched from
Crossref. The `project` field of a record is the folder on this site that carries its full
text; it is filled by matching DOIs against tools/papers.json, so it cannot drift from what the
site actually holds without the mismatch showing up as a missing link rather than a wrong one.

Czech names are written without diacritics here, as everywhere in the site's English text.
"""
import html
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
DATA = os.path.join(ROOT, "tools", "publications.json")
PAPERS = os.path.join(ROOT, "tools", "papers.json")
BASE = "https://meta-analysis.cz"
E = lambda s: html.escape(s or "", quote=True)

PEOPLE = {
    "havranek": dict(
        slug="publications", name="Tomas Havranek", orcid="0000-0002-3158-2539",
        person_id=BASE + "/#th", other="irsova",
        blurb="Every journal article, newest first.",
    ),
    "irsova": dict(
        slug="publications/irsova", name="Zuzana Irsova", orcid="0000-0002-0753-8124",
        person_id=BASE + "/#zi", other="havranek",
        blurb="Every journal article, newest first.",
    ),
}


# A 347-author consortium paper would otherwise print a page of names.
AUTHOR_CAP = 8


def author_line(names):
    # One name over the cap is not worth a truncation notice: "and 1 others" is not English,
    # and printing the name is shorter than saying it was withheld.
    if len(names) <= AUTHOR_CAP + 1:
        return ", ".join(names)
    return ", ".join(names[:AUTHOR_CAP]) + f", and {len(names) - AUTHOR_CAP} others"


def citation(r):
    bits = []
    if r["authors"]:
        bits.append(author_line(r["authors"]))
    elif r.get("n_authors"):
        bits.append(f"{r['n_authors']} authors")
    where = r["venue"]
    if r.get("volume"):
        where += f" {r['volume']}"
    if r.get("page"):
        where += f", {r['page']}"
    return bits, where


def item(r):
    bits, where = citation(r)
    out = [f'<li id="pub-{E(r["doi"].replace("/", "-")) if r["doi"] else ""}">'
           if r["doi"] else "<li>"]
    out.append(f'<span class="pub-year">{r["year"] or ""}</span> ')
    out.append(f'<b>{E(r["title"])}</b>')
    if bits:
        out.append(f'<br /><span class="pub-authors">{E(bits[0])}</span>')
    out.append(f'<br /><span class="pub-where"><i>{E(where)}</i></span>')
    links = []
    if r["doi"]:
        links.append(f'<a href="https://doi.org/{E(r["doi"])}">doi</a>')
    if r["project"]:
        links.append(f'<a href="{site_url(r["project"])}">full text on this site</a>')
    if links:
        out.append(' &middot; ' + " &middot; ".join(links))
    out.append("</li>")
    return "".join(out)


def site_url(project):
    """Where this paper actually lives on the site.

    Not every project is a folder at the root: an entry with a `parent` is filed under
    another project's landing, and asking the site's own map rather than assuming
    /<project>/ is what keeps this page from linking a 404 -- /reporting/ does not exist,
    /guidelines/reporting/ does."""
    from build_paper_page import HAND_BUILT
    meta = {e["project"]: e for e in json.load(open(PAPERS, encoding="utf-8"))}.get(project)
    if meta and meta.get("slug"):
        return f"{BASE}/{meta['slug'].strip('/')}/"
    if project in HAND_BUILT:
        return f"{BASE}/{HAND_BUILT[project]}/"
    return f"{BASE}/{project}/"


def load_footer():
    """One footer for the whole site, taken from the homepage.

    verify_seo compares every page's footer against the homepage's byte for byte, so a copy
    restated here would drift the first time the real one is edited. Same rule as
    notes/build_notes.py and the board scripts."""
    src = open(os.path.join(ROOT, "index.html"), encoding="utf-8").read()
    m = re.search(r'<footer class="site-foot">.*?</footer>', src, re.S)
    if not m:
        raise SystemExit('the homepage has no <footer class="site-foot"> to copy')
    return m.group(0)


def jsonld(person, records):
    """A CollectionPage of ScholarlyArticle parts, the shape /papers/ already uses.

    Not an ItemList (that is /results/, a list of questions), and no Highwire citation_*
    tags: a bibliography has no author, year or abstract of its own, so those would be
    fabricated. This is why the page is SELF_MANAGED."""
    return json.dumps({
        "@context": "https://schema.org",
        "@type": "CollectionPage",
        "@id": f"{BASE}/{person['slug']}/#page",
        "url": f"{BASE}/{person['slug']}/",
        "name": f"Publications — {person['name']}",
        "isPartOf": {"@id": BASE + "/#website"},
        "about": {"@type": "Person", "@id": person["person_id"], "name": person["name"],
                  "sameAs": f"https://orcid.org/{person['orcid']}"},
        "hasPart": [
            {"@type": "ScholarlyArticle", "name": r["title"],
             **({"datePublished": str(r["year"])} if r["year"] else {}),
             **({"isPartOf": {"@type": "Periodical", "name": r["venue"]}} if r["venue"] else {}),
             **({"sameAs": f"https://doi.org/{r['doi']}"} if r["doi"] else {}),
             **({"url": site_url(r["project"])} if r["project"] else {})}
            for r in records],
    }, indent=1, ensure_ascii=False)


def page(key, records, all_data):
    p = PEOPLE[key]
    other = PEOPLE[p["other"]]
    n_full = sum(1 for r in records if r["project"])
    tab = chr(9)
    return f"""<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Publications &#8212; {E(p['name'])}</title>
<meta name="description" content="The complete journal publication record of {E(p['name'])}: {len(records)} articles, {n_full} of them republished in full text on this site." />
<link href="/style.css" rel="stylesheet" type="text/css" />
<link href="/paper.css" rel="stylesheet" type="text/css" />
<!-- seo-meta:start -->
<link rel="canonical" href="{BASE}/{p['slug']}/" />
<meta property="og:site_name" content="meta-analysis.cz" />
<meta property="og:type" content="website" />
<meta property="og:title" content="Publications &#8212; {E(p['name'])}" />
<meta property="og:description" content="Every journal article by {E(p['name'])}: {len(records)} of them, {n_full} republished in full text on this site." />
<meta property="og:url" content="{BASE}/{p['slug']}/" />
<script type="application/ld+json">
{jsonld(p, records)}
</script>
<!-- seo-meta:end -->
</head>
<body>
<div id="wrapper">
<div id="logo">
{tab}<a class="masthead-home" href="/">meta-analysis.cz</a>
{tab}<p class="site-name"><a href="/{p['slug']}/">Publications</a></p>
{tab}<h2> <span class="mk">&raquo;</span>&nbsp;&nbsp;&nbsp; {E(p['name'])}</h2>
</div>
<div id="header">
{tab}<div id="menu">
{tab}{tab}<ul>
{tab}{tab}{tab}<li class="current_page_item"><a href="/{p['slug']}/">{E(p['name'].split()[-1])}</a></li>
{tab}{tab}{tab}<li><a href="/{other['slug']}/">{E(other['name'].split()[-1])}</a></li>
{tab}{tab}{tab}<li><a href="/papers/">Papers in full</a></li>
{tab}{tab}{tab}<li><a href="/results/">Results</a></li>
{tab}{tab}{tab}<li><a href="/about/">About</a></li>
{tab}{tab}{tab}<li><a href="/">Data &amp; code</a></li>
{tab}{tab}</ul>
{tab}</div>
</div>
</div>
<div id="page" class="single">
{tab}<div id="content">
{tab}{tab}<div class="post">
{tab}{tab}{tab}<h1 class="title">Publications</h1>
{tab}{tab}{tab}<div class="entry">
<p>{E(p['blurb'])} {len(records)} journal articles by {E(p['name'])}
(<a href="https://orcid.org/{p['orcid']}">ORCID {p['orcid']}</a>), {n_full} of them republished
here in full text. Working papers and preprints are not listed separately: where a paper has
been published, the published version is what appears. The other half of this site's work is
<a href="/{other['slug']}/">{E(other['name'])}'s publication list</a>.</p>

<ol class="publist">
{chr(10).join(item(r) for r in records)}
</ol>
{tab}{tab}{tab}</div>
{tab}{tab}</div>
{tab}</div>
</div>
{load_footer()}
</body>
</html>
"""


def main():
    check = "--check" in sys.argv
    data = json.load(open(DATA, encoding="utf-8"))
    wrote = []
    for key, person in PEOPLE.items():
        records = data[key]
        out = os.path.join(ROOT, person["slug"], "index.html")
        body = page(key, records, data)
        if check:
            old = open(out, encoding="utf-8").read() if os.path.exists(out) else ""
            if old != body:
                sys.exit(f"{person['slug']}/index.html is stale: rebuild with "
                         f"tools/build_publications_page.py")
            continue
        os.makedirs(os.path.dirname(out), exist_ok=True)
        open(out, "w", encoding="utf-8", newline="\n").write(body)
        wrote.append(f"{person['slug']}/index.html: {len(records)} articles, "
                     f"{sum(1 for r in records if r['project'])} with full text here")
    print("\n".join(wrote) if wrote else "publications pages match a fresh build")


if __name__ == "__main__":
    main()
