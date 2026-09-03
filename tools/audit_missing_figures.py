#!/usr/bin/env python3
"""Which figures does the paper caption that the page does not show?

    python3 tools/audit_missing_figures.py [--json <path>] [<project> ...]

tools/check_paper_pages.py already compares figure numbers, but it asks tools/scout_paper.py
what the paper contains, and scout reads the same text layer the transcript came from. When
a figure is missed at conversion it is usually missed by scout too, and the census then
compares one incomplete list against another and reports agreement. Five papers on this site
show no figures at all while their PDFs caption between one and four.

So this goes back to the PDF and looks for caption LINES specifically -- a line that begins
"Figure 3." or "FIGURE 3:" and continues into a title -- rather than every mention of the
word, which would count every cross-reference in the prose. It then asks the page what it
carries.

A gap listed here is a claim about the PDF, not a proven defect: a paper may caption a
figure that is genuinely absent from the manuscript this site hosts, and a supplement may
number its figures from one and collide with the body. Look before extracting.
"""

import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

from build_paper_page import (documents, page_dir,             # noqa: E402
                              transcript_pdf_paths)
import _poppler

PAPERS = {p["project"]: p for p in
          json.load(open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
PAPERS.update(documents())

# A caption opens a line, names a number, and runs on into a title. Requiring the title
# is what separates it from a cross-reference sitting at the start of a wrapped line.
CAPTION = re.compile(
    r"(?m)^\s{0,12}(?:FIGURE|Figure|Fig\.)\s+([A-Z]{0,2}\d{1,2}[A-Za-z]?)\s*[.:]?\s+(\S.{6,})")


def pdf_captions(pdfs):
    seen = {}
    for f in pdfs:
        for flags in ([], ["-raw"]):
            txt = subprocess.run([_poppler.tool("pdftotext")] + flags + [f, "-"], capture_output=True,
                                 encoding="utf-8", errors="replace").stdout or ""
            for m in CAPTION.finditer(txt):
                n = m.group(1).lstrip("0") or m.group(1)
                seen.setdefault(n, m.group(2).strip()[:70])
    return seen


def main(argv):
    jpath = None
    if "--json" in argv:
        i = argv.index("--json")
        jpath, argv = argv[i + 1], argv[:i] + argv[i + 2:]
    projects = argv or sorted(p for p in PAPERS
                              if os.path.exists(os.path.join(page_dir(p, PAPERS[p]),
                                                             "index.html")))
    rows = []
    for p in projects:
        meta = PAPERS[p]
        try:
            pdfs = transcript_pdf_paths(p, meta)
        except Exception:
            continue
        if not pdfs:
            continue
        page = open(os.path.join(page_dir(p, meta), "index.html"), encoding="utf-8").read()
        shown = set(re.findall(r"<b>Figure ([A-Za-z0-9.]+)\.</b>", page))
        shown |= {n[:-1] for n in shown if n[-1:].isalpha()}
        caps = pdf_captions(pdfs)
        alias = {v: k for k, v in (meta.get("figure_labels") or {}).items()}
        missing = {n: t for n, t in caps.items()
                   if n not in shown and alias.get(n, n) not in shown}
        rows.append(dict(project=p, shown=len(shown), captioned=len(caps),
                         missing=sorted(missing), titles=missing))
    rows.sort(key=lambda r: -len(r["missing"]))
    tot = sum(len(r["missing"]) for r in rows)
    print("%d paper(s) audited; %d captioned figure(s) not shown on any page\n" %
          (len(rows), tot))
    print("%-22s %6s %10s  %s" % ("project", "shown", "captioned", "missing"))
    for r in rows:
        if not r["missing"]:
            continue
        print("%-22s %6d %10d  %s" % (r["project"], r["shown"], r["captioned"],
                                      ", ".join(r["missing"][:12])))
        for n in r["missing"][:3]:
            print("%30s %s. %s" % ("", n, r["titles"][n][:66]))
    if jpath:
        json.dump(rows, open(jpath, "w", encoding="utf-8"), indent=1)
        print("\nwritten to %s" % jpath)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
