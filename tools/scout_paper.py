#!/usr/bin/env python3
"""Report the shape of a paper's PDF: pages, where its tables and figures sit, whether it
cites by number, and where the back matter starts.

    python3 tools/scout_paper.py <project> [<project> ...]
    python3 tools/scout_paper.py --all [--json]

Everything here is read straight out of the text layer. It exists so that the expensive
part of a conversion -- a model reading page images -- is spent only on the pages that
actually hold a table, an equation or a figure, and never on finding out which pages those
are.
"""

import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

CAPTION = re.compile(r"^\s*(T\s?A\s?B\s?L\s?E|TABLE|Table|F\s?I\s?G\s?U\s?R\s?E|FIGURE|Figure|Fig\.)"
                     r"\s*([0-9]+[A-Za-z]?)\b", re.M)
BACK = re.compile(r"^\s*(R\s?E\s?F\s?E\s?R\s?E\s?N\s?C\s?E\s?S|REFERENCES|References|Bibliography)\s*$",
                  re.M)
EQNUM = re.compile(r"\(\s*(\d{1,2})\s*\)\s*$", re.M)


def pages_of(pdf):
    out = subprocess.run(["pdfinfo", pdf], capture_output=True, text=True).stdout
    for line in out.splitlines():
        if line.startswith("Pages:"):
            return int(line.split()[-1])
    return 0


def scout(project, papers):
    from build_paper_page import paper_pdf
    rel = paper_pdf(project, papers[project])
    if not rel:
        return {"project": project, "error": "no PDF"}
    pdf = os.path.join(ROOT, project, rel)
    n = pages_of(pdf)
    text = subprocess.run(["pdftotext", pdf, "-"], capture_output=True, text=True).stdout
    per_page = text.split("\f")

    tables, figures, eqpages, back_page = {}, {}, [], None
    for i, page in enumerate(per_page, 1):
        for kind, num in CAPTION.findall(page):
            key = num
            if kind.replace(" ", "").upper().startswith("T"):
                tables.setdefault(key, i)
            else:
                figures.setdefault(key, i)
        if EQNUM.search(page):
            eqpages.append(i)
        if back_page is None and BACK.search(page):
            back_page = i

    numbered = bool(re.search(r"^\s*1\.\s+[A-Z][a-z]+,?\s", text[text.find("REFERENCES"):] or "", re.M))
    words = len(text.split())
    return {
        "project": project,
        "pdf": rel,
        "pages": n,
        "words": words,
        "tables": {k: v for k, v in sorted(tables.items(), key=lambda kv: kv[1])},
        "figures": {k: v for k, v in sorted(figures.items(), key=lambda kv: kv[1])},
        "equation_pages": eqpages,
        "references_start_page": back_page,
        "numbered_references": numbered,
    }


def main(argv):
    papers = {p["project"]: p for p in json.load(open(os.path.join(ROOT, "tools", "papers.json")))}
    as_json = "--json" in argv
    argv = [a for a in argv if not a.startswith("--")]
    if not argv:
        projects = sorted(papers)
    else:
        projects = argv
    results = []
    for project in projects:
        try:
            results.append(scout(project, papers))
        except Exception as exc:                      # a missing or unreadable PDF is data
            results.append({"project": project, "error": str(exc)})
    if as_json:
        print(json.dumps(results, indent=1))
        return
    for r in results:
        if "error" in r:
            print("%-22s -- %s" % (r["project"], r["error"]))
            continue
        print("%-22s %3d pp %6d words  tables=%-22s figures=%-18s eq_pages=%-16s refs@%s%s"
              % (r["project"], r["pages"], r["words"],
                 ",".join("%s:p%d" % (k, v) for k, v in list(r["tables"].items())[:6]) or "-",
                 ",".join("%s:p%d" % (k, v) for k, v in list(r["figures"].items())[:5]) or "-",
                 ",".join(str(p) for p in r["equation_pages"][:6]) or "-",
                 r["references_start_page"], " (numbered)" if r["numbered_references"] else ""))


if __name__ == "__main__":
    main(sys.argv[1:])
