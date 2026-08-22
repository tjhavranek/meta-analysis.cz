#!/usr/bin/env python3
"""Tell a plot from a paragraph, in an already-extracted figure.

    python3 tools/audit_figures.py [<project> ...]        # report
    python3 tools/audit_figures.py --delete [<project>]   # and remove the paragraphs

Locating a figure from the PDF's word coordinates sometimes lands on body text instead, and
a crop of a paragraph looks entirely plausible in a file listing: right size, right shape,
plenty of ink. What separates them is that a plot has long unbroken strokes -- axes, frames,
box rules, plotted lines -- and running prose has none. Counting rows that contain one
sorts them without anybody looking.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def reviewed():
    """Crops a person has already looked at and kept.

    The screen is a screen, not a proof: a sparse two-panel line plot with a row of axis
    ticks lands between the two calibrated bands and gets called prose. Deleting it would be
    wrong and leaving it reported forever is worse, because a standing warning is one nobody
    reads and a real bad crop then hides behind it."""
    path = os.path.join(ROOT, "tools", "figures_reviewed.json")
    if not os.path.exists(path):
        return {}
    return {k: v for k, v in json.load(open(path)).items() if not k.startswith("_")}


def line_rhythm(path):
    """How often the image alternates between inked and blank rows, per hundred rows.

    Running prose is a stack of text lines separated by blank gaps, so it flips between
    inked and blank every dozen rows or so. A plot is one connected mass of drawing and
    flips a handful of times over its whole height. Measured over the papers converted so
    far the two do not overlap: artwork sits at 0.6-1.4 flips per hundred rows and text
    crops at 3.4-7.0."""
    a = np.asarray(Image.open(path).convert("L"))
    dark = a < 200
    rows = dark.any(axis=1).astype(np.int8)
    if len(rows) < 4:
        return 99.0, dark.shape
    return float(np.abs(np.diff(rows)).sum()) / len(rows) * 100.0, dark.shape


def verdict(path):
    flips, shape = line_rhythm(path)
    if shape[0] < 200:
        return "sliver", flips, shape
    if flips > 2.5:
        return "prose", flips, shape
    return "plot", flips, shape


def main(argv):
    delete = "--delete" in argv
    projects = [a for a in argv if not a.startswith("--")]
    if not projects:
        projects = sorted(d for d in os.listdir(ROOT)
                          if os.path.isdir(os.path.join(ROOT, d, "paper", "figures")))
    bad = 0
    seen = 0
    for project in projects:
        d = os.path.join(ROOT, project, "paper", "figures")
        if not os.path.isdir(d):
            continue
        for name in sorted(os.listdir(d)):
            if not name.endswith(".png"):
                continue
            path = os.path.join(d, name)
            v, share, shape = verdict(path)
            if v == "plot":
                continue
            if "%s/%s" % (project, name) in reviewed():
                seen += 1
                continue
            bad += 1
            print("%-20s %-12s %-7s flips/100rows %4.1f  %dx%d"
                  % (project, name, v, share, shape[1], shape[0]))
            if delete:
                os.remove(path)
    print("\n%d crop(s) look like text rather than artwork%s%s"
          % (bad, " -- deleted" if delete else "",
             "; %d reviewed and kept (tools/figures_reviewed.json)" % seen if seen else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
