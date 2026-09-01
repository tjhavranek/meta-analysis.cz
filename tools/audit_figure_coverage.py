#!/usr/bin/env python3
"""Does the page carry every figure the PDF actually draws?

    python3 tools/audit_figure_coverage.py [--json <path>] [<project> ...]

tools/check_paper_pages.py already compares the figure NUMBERS the paper mentions against
the numbers the page prints, which catches a figure that is missing and is referred to by
name. It cannot catch one the text never numbers, and it believes the text layer about what
exists.

This asks the PDF instead. Every figure is either an embedded raster or a cluster of vector
drawing operations, and both are enumerable without rendering anything or looking at
anything. A page of running prose draws almost nothing; a page with a plot on it draws
hundreds of strokes inside one band. So: count the drawing ink per page, find the pages that
carry artwork, and compare that against the figures the site extracted from this paper.

The output is deliberately a ratio and a list of suspect pages rather than a verdict. A
paper that draws on nine pages and shows four figures may be missing five, or may print
four multi-panel figures and five tables ruled with vector lines. Deciding which needs a
look at the page. This says where to look.
"""

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import fitz                                                   # noqa: E402

from build_paper_page import documents, page_dir, transcript_pdf_paths   # noqa: E402

PAPERS = {p["project"]: p for p in
          json.load(open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
PAPERS.update(documents())

# A drawing cluster smaller than this is a rule under a table heading or a maths glyph,
# not artwork. Measured as a fraction of the page area.
MIN_AREA = 0.02
# Below this many drawing operations a band is decoration, not a plot.
MIN_OPS = 25


def artwork_pages(pdf):
    """Pages that draw something big enough to be a figure, and how much."""
    out = []
    doc = fitz.open(pdf)
    try:
        for pno in range(doc.page_count):
            page = doc.load_page(pno)
            parea = abs(page.rect.width * page.rect.height) or 1.0
            try:
                paths = page.get_drawings()
            except Exception:
                paths = []
            ops = len(paths)
            # union bounding box of the drawing, as a share of the page
            area = 0.0
            if paths:
                x0 = min(p["rect"].x0 for p in paths)
                y0 = min(p["rect"].y0 for p in paths)
                x1 = max(p["rect"].x1 for p in paths)
                y1 = max(p["rect"].y1 for p in paths)
                area = abs((x1 - x0) * (y1 - y0)) / parea
            imgs = 0
            try:
                imgs = len([i for i in page.get_images(full=True)])
            except Exception:
                pass
            if (ops >= MIN_OPS and area >= MIN_AREA) or imgs:
                out.append(dict(page=pno + 1, ops=ops, area=round(area, 3), rasters=imgs))
    finally:
        doc.close()
    return out


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
            pdfs = []
        if not pdfs:
            continue
        idx = os.path.join(page_dir(p, meta), "index.html")
        page = open(idx, encoding="utf-8").read()
        shown = len(re.findall(r'<img src="figures/', page))
        art = []
        for f in pdfs:
            try:
                art += artwork_pages(f)
            except Exception as exc:
                rows.append(dict(project=p, error=str(exc)[:60]))
                art = None
                break
        if art is None:
            continue
        rows.append(dict(project=p, shown=shown, art_pages=len(art),
                         rasters=sum(a["rasters"] for a in art),
                         pages=[a["page"] for a in art][:20]))
    rows.sort(key=lambda r: -(r.get("art_pages", 0) - r.get("shown", 0)))
    print("%-22s %6s %9s %8s  %s" % ("project", "shown", "art pages", "rasters", "gap"))
    for r in rows:
        if "error" in r:
            print("%-22s ERROR %s" % (r["project"], r["error"]))
            continue
        gap = r["art_pages"] - r["shown"]
        flag = "  <-- more artwork pages than figures shown" if gap > 0 else ""
        print("%-22s %6d %9d %8d  %+d%s" % (r["project"], r["shown"], r["art_pages"],
                                            r["rasters"], gap, flag))
    if jpath:
        json.dump(rows, open(jpath, "w", encoding="utf-8"), indent=1)
        print("\nwritten to %s" % jpath)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
