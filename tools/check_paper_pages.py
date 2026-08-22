#!/usr/bin/env python3
"""Check every full-text page against the paper it reproduces.

    python3 tools/check_paper_pages.py [<project> ...]

Three things can go wrong in a conversion, and each is checkable without an opinion:

  * something was invented -- prose on the page that is not in the PDF;
  * something is missing -- a table, a figure or a whole section the PDF has and the page
    does not, which the word-count ratio and the table/figure census catch;
  * something is broken -- a leftover placeholder, a citation pointing at a reference that
    is not there, a figure whose file was never written, an equation that failed to convert.

Exit status is 1 if any page fails, so this can gate a deploy.
"""

import html
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

from build_paper_page import paper_pdf                      # noqa: E402
from scout_paper import scout                               # noqa: E402
from verify_transcript import (multiset_check, pdf_counts,  # noqa: E402
                               pdf_prose, transcript_prose, words)

PAPERS = {p["project"]: p for p in json.load(open(os.path.join(ROOT, "tools", "papers.json")))}


def visible_text(page):
    body = page
    body = re.sub(r"<script.*?</script>", " ", body, flags=re.S)
    body = re.sub(r"<style.*?</style>", " ", body, flags=re.S)
    body = re.sub(r"<[^>]+>", " ", body)
    return html.unescape(body)


def check(project):
    fails, notes = [], []
    page_path = os.path.join(ROOT, project, "paper", "index.html")
    tr_path = os.path.join(ROOT, "tools", "transcripts", "%s.md" % project)
    if not os.path.exists(page_path):
        return ["no page at %s/paper/" % project], []
    if not os.path.exists(tr_path):
        # /maive/paper/ and /guidelines/guide/ were built by hand before the toolchain
        # existed. They are checked by eye, not by this gate.
        return [], ["hand-built page, no transcript to check against"]

    page = open(page_path).read()
    src = open(tr_path).read()
    pdf = os.path.join(ROOT, project, paper_pdf(project, PAPERS[project]))

    # -- nothing invented
    a = pdf_counts(pdf)
    b = words(transcript_prose(src))
    _lost, gained = multiset_check(a, b)
    invented = sum(c for w, c in gained.items() if re.search(r"[a-z]{3}", w))
    if invented > 6:
        fails.append("%d prose words on the page are not in the PDF (%s)"
                     % (invented, ", ".join(sorted(w for w in gained if re.search(r"[a-z]{3}", w))[:8])))
    elif invented:
        notes.append("%d word(s) not in the text layer: %s"
                     % (invented, ", ".join(sorted(w for w in gained if re.search(r"[a-z]{3}", w)))))

    # -- nothing wholesale missing. Tables and captions live outside the prose comparison,
    #    so the ratio is never 1; a page that dropped a section falls far below its peers.
    ratio = len(b) / max(1, sum(a.values()))
    if ratio < 0.45:
        fails.append("transcript holds %.0f%% of the PDF's words -- a section may be missing"
                     % (100 * ratio))
    elif ratio < 0.60:
        notes.append("transcript holds %.0f%% of the PDF's words" % (100 * ratio))

    # -- the tables and figures the paper has, the page has
    sc = scout(project, PAPERS)
    want_t, want_f = len(sc.get("tables", {})), len(sc.get("figures", {}))
    got_t = page.count("<table>")
    got_f = page.count("<figure>") + page.count('class="fig-inpdf"')
    if want_t and got_t < want_t:
        fails.append("%d tables in the paper, %d on the page" % (want_t, got_t))
    if want_f and got_f < want_f:
        fails.append("%d figures in the paper, %d on the page" % (want_f, got_f))

    # -- nothing broken
    if "<<" in page:
        fails.append("a placeholder marker survived into the page")
    if "tex-fallback" in page:
        fails.append("%d equation(s) failed to convert to MathML" % page.count("tex-fallback"))
    if re.search(r"\bTODO\b", visible_text(page)):
        fails.append("the word TODO is visible on the page")
    for m in re.finditer(r'<img src="(figures/[^"]+)"', page):
        f = os.path.join(ROOT, project, "paper", m.group(1))
        if not os.path.exists(f):
            fails.append("missing figure file %s" % m.group(1))
        elif os.path.getsize(f) < 2000:
            notes.append("%s is only %d bytes -- check it is the artwork"
                         % (m.group(1), os.path.getsize(f)))
    targets = set(re.findall(r'id="(ref-[^"]+|note-[^"]+)"', page))
    broken = {h for h in re.findall(r'href="#(ref-[^"]+|note-[^"]+)"', page)} - targets
    if broken:
        fails.append("%d citation link(s) point at nothing: %s"
                     % (len(broken), ", ".join(sorted(broken)[:6])))
    if 'class="attribution"' not in page:
        fails.append("no attribution block")
    for blob in re.findall(r'<script type="application/ld\+json">(.*?)</script>', page, re.S):
        try:
            json.loads(blob)
        except Exception as exc:
            fails.append("JSON-LD does not parse: %s" % exc)
    if "permission" in visible_text(page).lower():
        notes.append("the word 'permission' appears in visible text")

    return fails, notes


def main(argv):
    if argv:
        projects = argv
    else:
        projects = sorted(p for p in PAPERS
                          if os.path.exists(os.path.join(ROOT, p, "paper", "index.html")))
    bad = 0
    for project in projects:
        fails, notes = check(project)
        mark = "FAIL" if fails else "ok  "
        print("%s %-22s %s" % (mark, project,
                               "" if fails or notes else "clean"))
        for f in fails:
            print("       ! %s" % f)
        for n in notes:
            print("       - %s" % n)
        bad += bool(fails)
    print("\n%d page(s) checked, %d with failures" % (len(projects), bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
