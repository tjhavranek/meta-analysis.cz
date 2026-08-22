#!/usr/bin/env python3
"""Build /papers/, the index of the papers this site carries in full.

    python3 tools/build_fulltext_page.py

Lists every project that has a /<project>/paper/ page, newest first, taking the title,
authors and journal from tools/papers.json so the entry cannot disagree with the page it
points at. Regenerate it whenever a conversion lands; it is derived, not written.
"""

import html
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

from build_paper_page import article_title      # noqa: E402

PAPERS = {p["project"]: p for p in json.load(open(os.path.join(ROOT, "tools", "papers.json")))}

# The two pages built by hand before the toolchain existed live at their own addresses.
HAND_BUILT = {"maive": "/maive/paper/", "guidelines": "/guidelines/guide/"}


def editions():
    out = []
    for project, meta in PAPERS.items():
        href = HAND_BUILT.get(project)
        if href is None and os.path.exists(os.path.join(ROOT, project, "paper", "index.html")):
            href = "/%s/paper/" % project
        if href is None:
            continue
        if not os.path.exists(os.path.join(ROOT, href.strip("/"), "index.html")):
            continue
        # The published title, not the site's label for the literature -- the same rule the
        # pages themselves follow, so the index cannot disagree with what it links to.
        out.append((meta.get("year") or 0, article_title(meta), project, href, meta))
    return sorted(out, key=lambda r: (-r[0], r[1].lower()))


def entry(year, title, project, href, meta):
    authors = meta.get("authors") or []
    if len(authors) > 3:
        who = "%s and %d others" % (authors[0], len(authors) - 1)
    else:
        who = ", ".join(authors[:-1]) + (" and " if len(authors) > 1 else "") + authors[-1] \
            if authors else ""
    journal = meta.get("journal") or ""
    where = "<i>%s</i>" % html.escape(journal) if journal else "working paper"
    return ('<li><a href="%s"><b>%s</b></a><br /><span class="who">%s &middot; %s &middot; %s</span></li>'
            % (href, html.escape(title), html.escape(who), where, year or "n.d."))


def build():
    rows = editions()
    listed = "\n".join(entry(*r) for r in rows)
    journals = len({r[4].get("journal") for r in rows if r[4].get("journal")})

    page = """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Papers in Full</title>
<meta name="description" content="Every paper on this site that is republished here in full: {n} papers as HTML, with their tables, equations and references, readable without a PDF." />
<link href="/style.css" rel="stylesheet" type="text/css" />
<link href="/paper.css" rel="stylesheet" type="text/css" />
</head>
<body>
<div id="wrapper">
<!-- start header -->
<div id="logo">
\t<a class="masthead-home" href="/">meta-analysis.cz</a>
\t<p class="site-name"><a href="/papers/">Papers in full</a></p>
\t<h2> <span class="mk">&raquo;</span>&nbsp;&nbsp;&nbsp; read them without a PDF</h2>
</div>
<div id="header">
\t<div id="menu">
\t\t<ul>
\t\t\t<li class="current_page_item"><a href="/papers/">Papers in full</a></li>
\t\t\t<li><a href="/">All meta-analyses</a></li>
\t\t\t<li><a href="/results/">Results</a></li>
\t\t\t<li><a href="/datasets/">Datasets</a></li>
\t\t\t<li><a href="/guidelines/guide/">Practitioner&#8217;s guide</a></li>
\t\t</ul>
\t</div>
</div>
<!-- end header -->
<!-- start page -->
<div id="page">
\t<div id="content">
\t\t<div class="post">
\t\t\t<div class="entry">

<p><b>{n} of the papers on this site are republished here in full</b>, as HTML rather than as
a PDF: the whole text, the tables as tables, the mathematics as mathematics, and the
references as links. They read on a phone, they are searchable, a screen reader can read them
aloud, and a language model can quote them without guessing at a scanned column. Each one
also keeps its PDF and its link to the version of record.</p>

<p class="caveat">Figures are reproduced where the artwork could be lifted cleanly from the
page &#8212; {figs} of them so far. Where it could not, the figure&#8217;s caption is printed on its
own and the PDF has the picture. A caption standing alone is a gap, not a claim that the
paper has no figure there.</p>

<ul class="fulltext">
{listed}
</ul>

\t\t\t</div>
\t\t</div>
\t</div>
</div>
<!-- end page -->
{footer}
</div>
</body>
</html>
"""
    from build_paper_page import load_footer
    # Kept for reference: tools/generate_seo.py writes the canonical URL, the Open Graph
    # tags and the JSON-LD for every page it manages, and this is one of them.
    _ld_handled_by_generate_seo = {
        "@context": "https://schema.org",
        "@type": "CollectionPage",
        "@id": "https://meta-analysis.cz/papers/#page",
        "url": "https://meta-analysis.cz/papers/",
        "name": "Papers in Full",
        "description": "Meta-analyses republished in full as HTML on meta-analysis.cz.",
        "isPartOf": {"@id": "https://meta-analysis.cz/#website"},
        "hasPart": [{"@type": "ScholarlyArticle",
                     "name": r[1],
                     "url": "https://meta-analysis.cz%s" % r[3]} for r in rows],
    }
    figs = sum(len([f for f in os.listdir(os.path.join(ROOT, r[2], "paper", "figures"))
                    if f.endswith(".png")])
               for r in rows
               if os.path.isdir(os.path.join(ROOT, r[2], "paper", "figures")))
    out = page.format(n=len(rows), listed=listed, figs=figs, footer=load_footer())
    outdir = os.path.join(ROOT, "papers")
    os.makedirs(outdir, exist_ok=True)
    with open(os.path.join(outdir, "index.html"), "w") as fh:
        fh.write(out)
    print("papers/index.html: %d full-text editions across %d journals" % (len(rows), journals))


if __name__ == "__main__":
    build()
