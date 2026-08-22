#!/usr/bin/env python3
"""Find a page's artwork by looking at the page, not by guessing around its caption.

    python3 tools/scan_figures.py <project> [--apply]

tools/locate_figures.py anchors on the caption and walks outward, which fails whenever the
caption is not adjacent to the artwork -- a figure at the top of a page whose caption is at
the bottom, two figures sharing a page, a caption on the facing page. This instead segments
the page into blocks of ink separated by whitespace, asks of each block whether it is a plot
or a paragraph (tools/audit_figures.py's test), and gives each figure the plot block nearest
its caption.

Without --apply it only reports what it would do.
"""

import os
import re
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import json                                              # noqa: E402
from audit_figures import line_rhythm                    # noqa: E402
from build_paper_page import paper_pdf                   # noqa: E402
from extract_figure import extract                       # noqa: E402
from locate_figures import lines_of, page_words          # noqa: E402
from scout_paper import scout                            # noqa: E402

PAPERS = {p["project"]: p for p in json.load(open(os.path.join(ROOT, "tools", "papers.json")))}
CAP = re.compile(r"^(FIG|Fig|FIGURE|Figure)\.?$")


def render(pdf, page, dpi=100):
    with tempfile.TemporaryDirectory() as tmp:
        stem = os.path.join(tmp, "p")
        subprocess.run(["pdftoppm", "-f", str(page), "-l", str(page), "-r", str(dpi),
                        "-gray", "-png", pdf, stem], check=True, capture_output=True)
        f = [x for x in os.listdir(tmp) if x.endswith(".png")][0]
        return np.asarray(Image.open(os.path.join(tmp, f)).convert("L"))


def blocks_of(arr, gap=14, min_h=90):
    """Maximal runs of inked rows separated by at least `gap` blank rows."""
    inked = (arr < 200).any(axis=1)
    out, start, blank = [], None, 0
    for y, on in enumerate(inked):
        if on:
            if start is None:
                start = y
            blank = 0
        else:
            if start is not None:
                blank += 1
                if blank >= gap:
                    if y - blank - start >= min_h:
                        out.append((start, y - blank))
                    start, blank = None, 0
    if start is not None and len(inked) - start >= min_h:
        out.append((start, len(inked)))
    return out


def plot_blocks(pdf, page):
    arr = render(pdf, page)
    h = arr.shape[0]
    found = []
    for y0, y1 in blocks_of(arr):
        sub = arr[y0:y1]
        rows = (sub < 200).any(axis=1).astype(np.int8)
        flips = float(np.abs(np.diff(rows)).sum()) / max(1, len(rows)) * 100.0
        if flips <= 2.5:
            found.append((y0 / h, y1 / h, y1 - y0))
    return found


def caption_positions(pdf, page):
    w, h, words = page_words(pdf, page)
    if not words:
        return {}
    out = {}
    for ln in lines_of(words):
        head = [t[4].strip() for t in ln[:4]]
        if head and CAP.match(head[0].rstrip(".")):
            for t in head[1:4]:
                n = re.sub(r"[^\w]", "", t)
                if n and n[0].isdigit():
                    out.setdefault(n, min(x[1] for x in ln) / h)
                    break
    return out


def main(argv):
    apply = "--apply" in argv
    project = [a for a in argv if not a.startswith("--")][0]
    meta = PAPERS[project]
    pdf = os.path.join(ROOT, project, paper_pdf(project, meta))
    sc = scout(project, PAPERS)
    have = set()
    d = os.path.join(ROOT, project, "paper", "figures")
    if os.path.isdir(d):
        have = {f[3:-4] for f in os.listdir(d) if f.startswith("fig")}

    for num, page in sc["figures"].items():
        if num in have:
            continue
        plots = plot_blocks(pdf, page)
        if not plots:
            print("%-14s fig%-4s page %-3d no plot-like block on the page" % (project, num, page))
            continue
        caps = caption_positions(pdf, page)
        anchor = caps.get(num)
        if anchor is None:
            best = max(plots, key=lambda b: b[2])
        else:
            best = min(plots, key=lambda b: min(abs(b[0] - anchor), abs(b[1] - anchor)))
        print("%-14s fig%-4s page %-3d band %.3f-%.3f  (%d candidate block(s))"
              % (project, num, page, best[0], best[1], len(plots)))
        if apply:
            extract(project, num, page, (0.03, max(0, best[0] - 0.004),
                                         0.98, min(1, best[1] + 0.004)))


if __name__ == "__main__":
    main(sys.argv[1:])
