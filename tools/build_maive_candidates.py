"""Build /maive/how-to/candidates/ -- worked-example candidates, side by side, to choose from.

This page is a workbench, not a publication: it exists so the owner can look at real funnels
from real subsets and pick the one the how-to should use. It is deliberately not linked from
the site's navigation and is excluded from the sitemap and the search index.

    python tools/build_maive_candidates.py

It renders from tools/maive_candidates.json, which build_maive_candidates_fetch writes.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_paper_page import ROOT  # noqa: E402
from build_search_page import homepage_footer  # noqa: E402

DATA = os.path.join(ROOT, "tools", "maive_candidates.json")
OUT_DIR = os.path.join(ROOT, "maive", "how-to", "candidates")


def n(x, d=3):
    return "&#8212;" if x is None or x == "NA" else ("%.*f" % (d, float(x)))


CARD = """
<div class="cand">
<h2 id="%(slug)s">%(rank)d. %(title)s</h2>
<p class="what">%(what)s</p>
<p><img src="funnel-%(slug)s.png" alt="Funnel plot for %(title)s" width="840"
height="840" /></p>
<table class="nums">
<tbody>
<tr><th>Simple mean</th><td>%(mean)s</td></tr>
<tr><th>MAIVE</th><td><b>%(maive)s</b> (SE %(se)s)</td></tr>
<tr><th>First&#8209;stage F</th><td>%(F)s%(Fnote)s</td></tr>
<tr><th>Fit</th><td>%(sel)s</td></tr>
<tr><th>Bias test (Egger p)</th><td>%(eggp)s%(eggnote)s</td></tr>
<tr><th>Estimates / studies</th><td>%(k)s from %(studies)s</td></tr>
</tbody>
</table>
<p class="filter"><code>%(filter)s</code> &middot;
<a href="%(slug)s.csv">the exact CSV</a></p>
<p class="verdict">%(verdict)s</p>
</div>
"""

PAGE = """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" \
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<meta name="robots" content="noindex, nofollow" />
<title>Worked-example candidates</title>
<link href="/style.css" rel="stylesheet" type="text/css" />
<link href="/paper.css" rel="stylesheet" type="text/css" />
</head>
<body>
<div id="wrapper">
<div id="logo">
\t<a class="masthead-home" href="/">meta-analysis.cz</a>
\t<p class="site-name"><a href="/maive/how-to/candidates/">Worked-example candidates</a></p>
\t<h2> <span class="mk">&raquo;</span>&nbsp;&nbsp;&nbsp; pick one for the how-to</h2>
</div>
<div id="header">
\t<div id="menu">
\t\t<ul>
\t\t\t<li class="current_page_item"><a href="/maive/how-to/candidates/">Candidates</a></li>
\t\t\t<li><a href="/maive/how-to/">How to</a></li>
\t\t\t<li><a href="/maive/">MAIVE</a></li>
\t\t\t<li><a href="/">All meta-analyses</a></li>
\t\t</ul>
\t</div>
</div>
</div>
<!-- start page -->
<div id="page" class="single">
\t<div id="content">
\t\t<div class="post">
\t\t\t<div class="entry">

<p class="lede">Candidates for the worked example on <a href="/maive/how-to/">How to run
MAIVE</a>. Every funnel below is the plot EasyMeta returns for that subset, under the
same recipe the page teaches: PET&#8209;PEESE, log first stage, equal weights, CR2
clustered by study.</p>

<p class="aside">Winsorisation is applied to the data here, not passed as a setting: the
shipped CSV is what was analysed. That matters because the MAIVE R package has no
winsorisation argument, so a run that used the app's own setting could not be reproduced in
R, while these can &#8212; the R code on the how-to page returns these numbers from these
files.</p>

<p class="aside">What a good example needs, and why these were hard to find. The estimates
have to be spread no wider than their own standard errors, or the cloud is a flat band
instead of a triangle. The sample sizes have to vary a lot, or MAIVE's fitted standard
errors &#8212; the filled points &#8212; collapse into a horizontal line. The first stage
has to be strong. And there has to be real asymmetry to correct. Those pull against each
other: the subsets homogeneous enough to look like a funnel tend to have too little
variation in sample size to identify anything.</p>

%(cards)s

<p class="provenance">Numbers fetched live on %(retrieved)s. This page is a workbench: it
is not linked from the site and is excluded from the search index and the sitemap.</p>

\t\t\t</div>
\t\t</div>
\t</div>
</div>
<!-- end page -->
%(footer)s
</body>
</html>
"""


def main():
    doc = json.load(open(DATA, encoding="utf-8"))
    cards = []
    for i, c in enumerate(doc["candidates"], 1):
        m = c["maive"]
        F = m.get("firstStageFStatistic")
        eggp = (m.get("publicationBias") or {}).get("pValue")
        cards.append(CARD % {
            "rank": i, "slug": c["slug"], "title": c["title"], "what": c["what"],
            "mean": n(c["mean"], 2),
            "maive": n(m.get("effectEstimate")), "se": n(m.get("standardError")),
            "F": n(F, 1),
            "Fnote": "" if (isinstance(F, (int, float)) and F >= 10)
                     else ' <span class="warn">below 10</span>',
            "sel": m.get("petpeese_selected") or "&#8212;",
            "eggp": n(eggp, 3),
            "eggnote": "" if (isinstance(eggp, (int, float)) and eggp < 0.05)
                       else ' <span class="warn">not significant</span>',
            "k": c["k"], "studies": c["studies"],
            "filter": c["filter"], "verdict": c["verdict"],
        })
    os.makedirs(OUT_DIR, exist_ok=True)
    page = PAGE % {"cards": "\n".join(cards), "footer": homepage_footer(),
                   "retrieved": doc["retrieved"]}
    open(os.path.join(OUT_DIR, "index.html"), "w", encoding="utf-8").write(page)
    print("candidates page: %d bytes, %d candidates" % (len(page), len(doc["candidates"])))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
