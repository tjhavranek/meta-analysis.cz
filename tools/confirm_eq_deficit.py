#!/usr/bin/env python3
"""Confirm a suspected equation deficit against the PUBLISHED PDF.

audit_tex_fidelity.py compares a page against the paper's LaTeX source, which may be an
older draft: a page rendering fewer equations than the .tex is only a CANDIDATE. This
settles it from the document the site actually transcribes.

A displayed, numbered equation leaves a distinctive trace in a PDF text layer: the number
in parentheses, alone at the end of a line. Counting the distinct numbers gives a floor on
how many displayed equations the published article has. If the page renders fewer than
that, the page is missing maths that is in the published paper, whatever the draft says.

Unnumbered display equations leave no such trace, so this UNDERCOUNTS. That is the right
direction to be wrong in: it never invents a defect, it only fails to notice one.
"""

import io
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import _poppler

EQNUM = re.compile(r"(?m)^\s*\(\s*(\d{1,2})\s*\)\s*$|\(\s*(\d{1,2})\s*\)\s*$")


def pdf_text(pdf):
    out = subprocess.run([_poppler.tool("pdftotext"), pdf, "-"],
                         capture_output=True, text=True,
                         encoding="utf-8", errors="replace").stdout or ""
    return out


def pdf_equation_numbers(pdf):
    nums = set()
    for m in EQNUM.finditer(pdf_text(pdf)):
        n = m.group(1) or m.group(2)
        if n:
            nums.add(int(n))
    # a run starting at 1 is an equation series; stray page-ish numbers are not
    series = set()
    k = 1
    while k in nums:
        series.add(k)
        k += 1
    return series, nums


def page_display_count(project):
    p = os.path.join(ROOT, project, "paper", "index.html")
    if not os.path.isfile(p):
        return None
    s = io.open(p, encoding="utf-8", errors="replace").read()
    return len(re.findall(r'class="eqn"', s))


def main(argv):
    import json as J
    projects = argv[1:]
    if not projects:
        print("usage: confirm_eq_deficit.py <project> [...]")
        return 2
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    from build_paper_page import transcript_pdf_paths, documents
    P = {p["project"]: p for p in J.load(io.open(os.path.join(ROOT, "tools", "papers.json"),
                                                 encoding="utf-8"))}
    P.update(documents())
    print("%-16s %8s %10s %9s  %s" % ("project", "pageEq", "pdfSeries", "verdict", "pdf"))
    print("-" * 78)
    for pr in projects:
        if pr not in P:
            print("%-16s  not in papers.json" % pr)
            continue
        pdfs = transcript_pdf_paths(pr, P[pr])
        if not pdfs:
            print("%-16s  no PDF" % pr)
            continue
        series, allnums = set(), set()
        for f in pdfs:
            s, a = pdf_equation_numbers(f)
            series |= s
            allnums |= a
        pg = page_display_count(pr)
        verdict = "ok"
        if pg is not None and len(series) > pg:
            verdict = "DEFICIT %d" % (len(series) - pg)
        print("%-16s %8d %10d %9s  %s" %
              (pr, pg or 0, len(series), verdict, os.path.basename(pdfs[0])))
    print("\npdfSeries counts consecutive numbered equations (1..n) in the published text "
          "layer.\nIt undercounts unnumbered displays, so 'ok' is not proof of no defect; "
          "a DEFICIT is real.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
