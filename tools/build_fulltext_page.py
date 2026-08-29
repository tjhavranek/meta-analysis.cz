#!/usr/bin/env python3
"""Build /papers/, the index of the papers this site carries in full.

    python3 tools/build_fulltext_page.py

Lists every project that has a /<project>/paper/ page, newest first, taking the title,
authors and journal from tools/papers.json so the entry cannot disagree with the page it
points at. Regenerate it whenever a conversion lands; it is derived, not written.
"""

import html
import csv
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

from build_paper_page import article_title, documents, page_href, venue_line  # noqa: E402

PAPERS = {p["project"]: p for p in json.load(open(os.path.join(ROOT, "tools", "papers.json")))}


def _published_in():
    """Volume, issue and pages for each paper, by DOI, out of the publication lists.

    papers.json says which journal a paper is in and not where in it. That is enough for a
    row that reads "Journal, 2026" -- until the row also has to say the text on the page is
    the author's manuscript, at which point a journal and a bare year look like a paper that
    has been accepted and not yet appeared. Volume and pages are what say otherwise, and
    publications.json already has them for every article that has any: the six it does not
    cover are the four still forthcoming and the two without a DOI to match on, which have
    no volume to print. Matched on DOI rather than on title, because a title is written twice
    and a DOI once."""
    out = {}
    path = os.path.join(ROOT, "tools", "publications.json")
    for records in json.load(open(path, encoding="utf-8")).values():
        for r in records:
            doi = (r.get("doi") or "").strip().lower()
            if doi and (r.get("volume") or r.get("page") or r.get("article_number")):
                out.setdefault(doi, r)
    return out


PUBLISHED_IN = _published_in()

# The two pages built by hand before the toolchain existed live at their own addresses.
# One definition, in build_paper_page.py, so this index and the checker agree with it.
from build_paper_page import HAND_BUILT as _HB                     # noqa: E402
HAND_BUILT = {k: "/%s/" % v for k, v in _HB.items()}


def editions():
    out = []
    for project, meta in PAPERS.items():
        # A paper's own `slug` is the address it actually lives at, and the only reason
        # HAND_BUILT still exists is the three pages that predate that field. Asking
        # HAND_BUILT alone silently dropped the 2026 guidelines from this index while
        # they were in papers.json, the API, llms.txt, the sitemap, the search index and
        # both publication lists, so /papers/ said 63 when the site carried 64.
        href = HAND_BUILT.get(project) or (meta.get("slug") and "/%s/" % meta["slug"].strip("/"))
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


def hanging(href):
    """Documents that belong to the paper at this address.

    A supplement is not a paper and does not get a row of its own, but a reader who has
    found the paper should be able to find it."""
    out = []
    for project, doc in sorted(documents().items()):
        if doc.get("parent") == href:
            out.append('<a href="%s">%s</a>'
                       % (page_href(project, doc), html.escape(doc.get("short") or "Supplement")))
    return out


def entry(year, title, project, href, meta):
    authors = meta.get("authors") or []
    if len(authors) > 3:
        who = "%s and %d others" % (authors[0], len(authors) - 1)
    else:
        who = ", ".join(authors[:-1]) + (" and " if len(authors) > 1 else "") + authors[-1] \
            if authors else ""
    journal = meta.get("journal") or ""
    if journal:
        _m = re.search(r"10\.\d{4,9}/\S+", (meta.get("doi_or_publisher_url") or "").lower())
        _r = PUBLISHED_IN.get(_m.group(0)) if _m else None
        journal = venue_line(journal, _r.get("volume"), _r.get("issue"),
                             _r.get("page"), _r.get("article_number")) if _r else journal
    where = "<i>%s</i>" % html.escape(journal) if journal else "working paper"
    # Say which version the reader will get. Without this every row looks like a version
    # of record, and two rows can carry the same journal and year: the JFS article and the
    # ECB working paper behind it are separate texts, both listed, and the citation on both
    # is the JFS one, so the journal line alone cannot tell them apart.
    # "accepted manuscript" is a term of art -- after peer review, before the publisher's
    # copy-editing -- and no vaguer phrase will do: "author's manuscript" would cover the
    # submitted version and a preprint too, which is the distinction this site spends its
    # version notes on. It was briefly replaced because next to a journal and a bare year
    # it reads as the article's STATUS, and the Nature reproduction came to look
    # forthcoming on a row whose point was that it is published. The volume and pages the
    # row now carries are what settle that; the label can go back to being exact.
    VERSION_LABEL = {"accepted_manuscript": "accepted manuscript",
                     "working_paper": "working paper",
                     "corrected_manuscript": "corrected manuscript"}
    _label = VERSION_LABEL.get(meta.get("version") or "")
    # not when the journal is absent: "working paper (working paper)" reads as a stutter
    if _label and journal:
        where += " (%s)" % _label
    extra = hanging(href)
    # A paper can be published without THIS text being the published version. The page serves
    # the working paper and says so; the list must still say the research is published, and
    # where, or a reader scanning it takes "working paper" to mean unpublished. It goes after
    # the year, so the year belongs to the text on the page and not to the article.
    pub = meta.get("published_as") or {}
    if pub.get("journal"):
        extra = extra + ['published as <a href="%s"><i>%s</i> %s</a>'
                         % (html.escape(pub.get("doi") or "", quote=True),
                            html.escape(pub["journal"]), html.escape(str(pub.get("year") or "")))]
    tail = (" &middot; " + " &middot; ".join(extra)) if extra else ""
    return ('<li><a href="%s"><b>%s</b></a><br /><span class="who">%s &middot; %s &middot; %s%s</span></li>'
            % (href, html.escape(title), html.escape(who), where, year or "n.d.", tail))


def build(check=False):
    rows = editions()
    listed = "\n".join(entry(*r) for r in rows)
    journals = len({r[4].get("journal") for r in rows if r[4].get("journal")})

    page = """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Papers in Full</title>
<meta name="description" content="{lede}: {n} papers as HTML, with their text, tables, equations, and references, readable without a PDF." />
<link rel="canonical" href="https://meta-analysis.cz/papers/" />
<meta property="og:site_name" content="meta-analysis.cz" />
<meta property="og:type" content="website" />
<meta property="og:title" content="Papers in Full" />
<meta property="og:description" content="{lede}: {n} papers as HTML, with their text, tables, equations, and references, readable without a PDF." />
<meta property="og:url" content="https://meta-analysis.cz/papers/" />
<script type="application/ld+json">{jsonld}</script>
<link href="/style.css" rel="stylesheet" type="text/css" />
<link href="/paper.css" rel="stylesheet" type="text/css" />
</head>
<body>
<div id="wrapper">
<!-- start header -->
<div id="logo">
\t<a class="masthead-home" href="/">meta-analysis.cz</a>
\t<h1 class="site-name"><a href="/papers/">Papers in full</a></h1>
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
</div>
<!-- start page -->
<div id="page">
\t<div id="content">
\t\t<div class="post">
\t\t\t<div class="entry">

<p><b>{lede}</b>, in HTML alongside the PDF. Each page carries the PDF too and, where the
paper has one, a link to the version of record. {composition}</p>

<p class="caveat">Figures are reproduced wherever the artwork lifted cleanly off the page
&#8212; {figs} so far. Where it did not, the caption stands on its own and the PDF has the
picture.</p>

<ul class="fulltext">
{listed}
</ul>

\t\t\t</div>
\t\t</div>
\t</div>
</div>
<!-- end page -->
{footer}
</body>
</html>
"""
    from build_paper_page import load_footer
    # The page is SELF_MANAGED: this builder owns its head, and this block is embedded in it.
    # An earlier comment claimed generate_seo would write it; it never did, and /papers/ was
    # the one page of the site with a bare head.
    ld = {
        "@context": "https://schema.org",
        "@type": "CollectionPage",
        "@id": "https://meta-analysis.cz/papers/#page",
        "url": "https://meta-analysis.cz/papers/",
        "name": "Papers in Full",
        # Not "meta-analyses": hasPart below carries the guidelines, the reporting
        # standards and the applied papers, none of which is a meta-analysis. A parser
        # reads this line before it reads the list it describes.
        "description": "Research papers and methodological guidance carried in full "
                       "as HTML on meta-analysis.cz.",
        "isPartOf": {"@id": "https://meta-analysis.cz/#website"},
        "hasPart": [{"@type": "ScholarlyArticle",
                     "name": r[1],
                     "url": "https://meta-analysis.cz%s" % r[3]} for r in rows],
    }
    # The sentence on the page is about the papers it lists, so the count is what those
    # pages actually show: <figure> elements in the built HTML. Counting directory PNGs
    # silently swept in the MAIVE supplement's 29 and orphaned files, which is how the
    # page came to claim 227 where a reader can count 198.
    figs = 0
    for r in rows:
        built = os.path.join(ROOT, r[3].strip("/"), "index.html")
        if os.path.exists(built):
            figs += open(built, encoding="utf-8").read().count("<figure")
    # "All 54" only while it IS all of them. The moment a paper is added without a
    # conversion the sentence would be false, so the page counts rather than asserts.
    lede = ("All %d papers on this site are here in full" % len(rows)
            if len(rows) >= len(PAPERS)
            else "%d of the %d papers on this site are here in full" % (len(rows), len(PAPERS)))
    # What the list is made of. A page that says only "papers" leaves a reader to discover
    # by clicking that some of them are not meta-analyses. The number is derived from
    # estimates.csv, so it cannot drift from what /results/ shows -- but that is the ONLY
    # thing it means. The sentence used to call the remainder "not meta-analyses: applied
    # work in banking, monetary policy and energy", which was wrong three times over once
    # the list grew: cbequity contains a meta-analysis of 176 estimates and says so 29
    # times on its own page, and the two 2026 MAER-Net documents are neither applied work
    # nor about banking. Membership in estimates.csv means one thing, a headline result of
    # the paper's own, so that is what the sentence now says.
    _meta = sum(1 for _r in csv.DictReader(open(os.path.join(ROOT, "estimates.csv"),
                                                encoding="utf-8")))
    _other = len(rows) - _meta
    composition = (("%d are meta-analyses and meta-research, each answering a question on "
                    "<a href=\"/results/\">Headline results</a> \u2014 the "
                    "<a href=\"/guidelines/guide/\">practitioner\u2019s guide</a> and the 2020 "
                    "<a href=\"/guidelines/reporting/\">MAER-Net reporting guidelines</a> among "
                    "them. The other %d "
                    # Not the guidelines and the reporting standards: both of those DO
                    # have headline rows in estimates.csv. The two without are the 2026
                    # MAER-Net notes on AI. The reproduction is named separately because it
                    # is neither: it is not a note on AI, and a reproduction of 110 studies
                    # across economics and political science is not applied work in banking,
                    # monetary policy or energy. A sentence that enumerates has to enumerate
                    # everything, or the reader counts the categories and comes up short.
                    "include the two 2026 MAER-Net notes on AI, a mass reproduction of 110 "
                    "published studies, a retrospective on six meta-analyses and the lessons "
                    "they left behind, and applied work in banking, monetary policy, public "
                    "finance, and energy.")
                   % (_meta, _other)) if _other > 0 else ""
    out = page.format(n=len(rows), lede=lede, listed=listed, figs=figs, footer=load_footer(),
                      composition=composition,
                      jsonld=json.dumps(ld, ensure_ascii=False, separators=(",", ":")))
    outdir = os.path.join(ROOT, "papers")
    dest = os.path.join(outdir, "index.html")
    # /papers/ is linked from the footer of every page on the site, and nothing was checking
    # it: adding a paper left it a page short, and the sentence naming what the papers WITHOUT
    # a headline result are stayed behind the list it describes. Both happened. So the builder
    # answers --check like the other generated pages do, and CI asks it.
    if check:
        if not os.path.exists(dest) or open(dest, encoding="utf-8").read() != out:
            sys.exit("papers/index.html is stale: rebuild with tools/build_fulltext_page.py")
        print("papers/index.html matches a fresh build")
        return
    os.makedirs(outdir, exist_ok=True)
    with open(dest, "w") as fh:
        fh.write(out)
    print("papers/index.html: %d full-text editions across %d journals" % (len(rows), journals))


if __name__ == "__main__":
    build(check="--check" in sys.argv)
