#!/usr/bin/env python3
"""Lift one figure out of a paper's PDF and save it for the full-text page.

    python3 tools/extract_figure.py <project> <fig> <page> <x0> <y0> <x1> <y1> [--dpi 200]

The four coordinates are fractions of the page, measured from the top left, so they can be
read off a rendered preview without knowing the page size: 0.08 0.55 0.95 0.90 means the
lower middle band of the page. The crop is then trimmed back to its own ink, which removes
the slack in a hand-read box and, more usefully, removes the caption line and the margin
strip if the box caught their edge.

Writes <project>/paper/figures/fig<fig>.png, colour-reduced because these are line plots:
a funnel plot in 64 colours is indistinguishable from the same plot in millions and is
twenty times smaller.
"""

import os
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def render(pdf, page, dpi):
    with tempfile.TemporaryDirectory() as tmp:
        stem = os.path.join(tmp, "p")
        subprocess.run(["pdftoppm", "-f", str(page), "-l", str(page), "-r", str(dpi),
                        "-png", pdf, stem], check=True, capture_output=True)
        name = [f for f in os.listdir(tmp) if f.endswith(".png")][0]
        return Image.open(os.path.join(tmp, name)).convert("RGB").copy()


def trim(im, threshold=232, pad=8):
    a = np.asarray(im).min(axis=2)
    ink = a < threshold
    rows, cols = np.where(ink.any(axis=1))[0], np.where(ink.any(axis=0))[0]
    if not len(rows) or not len(cols):
        return im
    return im.crop((max(int(cols[0]) - pad, 0), max(int(rows[0]) - pad, 0),
                    min(int(cols[-1]) + pad + 1, im.width),
                    min(int(rows[-1]) + pad + 1, im.height)))


def extract(project, fig, page, box, dpi=200, colours=64, pdf=None):
    import json
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    from build_paper_page import documents, page_dir, pdf_path
    papers = {p["project"]: p for p in json.load(open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    papers.update(documents())
    pdf = pdf or pdf_path(project, papers[project])

    im = render(pdf, page, dpi)
    x0, y0, x1, y1 = box
    im = im.crop((int(x0 * im.width), int(y0 * im.height),
                  int(x1 * im.width), int(y1 * im.height)))
    im = trim(im)
    outdir = os.path.join(page_dir(project, papers[project]), "figures")
    os.makedirs(outdir, exist_ok=True)
    out = os.path.join(outdir, "fig%s.png" % fig)
    im.quantize(colours, method=Image.MEDIANCUT).save(out, optimize=True)
    print("%s fig%s: page %s -> %s (%dx%d, %d KB)"
          % (project, fig, page, os.path.relpath(out, ROOT), im.width, im.height,
             os.path.getsize(out) // 1024))
    return out


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dpi = 200
    for a in sys.argv[1:]:
        if a.startswith("--dpi"):
            dpi = int(a.split("=", 1)[1] if "=" in a else sys.argv[sys.argv.index(a) + 1])
    project, fig, page = args[0], args[1], int(args[2])
    box = tuple(float(v) for v in args[3:7])
    extract(project, fig, page, box, dpi=dpi)
