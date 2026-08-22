#!/usr/bin/env python3
"""Find where a figure sits on its page, from the PDF's own word coordinates.

    python3 tools/locate_figures.py <project> [<fig> ...]

Extracting a figure needs a box. Reading that box off a rendered page by eye costs a page
image per figure, and there are hundreds of figures across these papers. The PDF already
knows where every word is, and a figure is precisely where the words are not: the band
above its caption, bounded by the body text before it.

So: take the caption's own coordinates, walk up the page until the text resumes, and treat
what lies between as the artwork. Axis labels inside a plot are words too, so the walk
tolerates sparse lines and stops only at a run of full-measure text lines.

Prints an extract_figure.py command per figure. Always look at what comes out.
"""

import json
import os
import re
import subprocess
import sys
import html

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

from build_paper_page import paper_pdf                 # noqa: E402
from scout_paper import scout                          # noqa: E402

PAPERS = {p["project"]: p for p in json.load(open(os.path.join(ROOT, "tools", "papers.json")))}
CAP = re.compile(r"^(FIG|Fig|FIGURE|Figure)\.?$")


def page_words(pdf, page):
    # Poppler writes XHTML with entities it does not declare, so the document is read with
    # regular expressions rather than a parser that is entitled to refuse it.
    xml = subprocess.run(["pdftotext", "-bbox", "-f", str(page), "-l", str(page), pdf, "-"],
                         capture_output=True, text=True, check=True).stdout
    m = re.search(r'<page width="([\d.]+)" height="([\d.]+)"', xml)
    if not m:
        return 0, 0, []
    w, h = float(m.group(1)), float(m.group(2))
    words = []
    for wm in re.finditer(
            r'<word xMin="([\d.-]+)" yMin="([\d.-]+)" xMax="([\d.-]+)" yMax="([\d.-]+)">'
            r'(.*?)</word>', xml, re.S):
        words.append((float(wm.group(1)), float(wm.group(2)), float(wm.group(3)),
                      float(wm.group(4)), html.unescape(wm.group(5))))
    return w, h, words


def lines_of(words, tol=3.0):
    """Group words into lines by their vertical position."""
    out = []
    for w in sorted(words, key=lambda t: (t[1], t[0])):
        if out and abs(w[1] - out[-1][0][1]) <= tol:
            out[-1].append(w)
        else:
            out.append([w])
    return out


_PAGE_CACHE = {}


def ink(pdf, page, band):
    """How much of a horizontal band of the page is dark. Rendered once per page."""
    y0, y1 = band
    if y1 - y0 < 0.02:
        return 0.0
    key = (pdf, page)
    if key not in _PAGE_CACHE:
        import tempfile
        import numpy as np
        from PIL import Image
        with tempfile.TemporaryDirectory() as tmp:
            stem = os.path.join(tmp, "p")
            subprocess.run(["pdftoppm", "-f", str(page), "-l", str(page), "-r", "50",
                            "-gray", "-png", pdf, stem], check=True, capture_output=True)
            f = [x for x in os.listdir(tmp) if x.endswith(".png")][0]
            _PAGE_CACHE[key] = np.asarray(Image.open(os.path.join(tmp, f)).convert("L"))
    import numpy as np
    arr = _PAGE_CACHE[key]
    a, b = int(y0 * arr.shape[0]), int(y1 * arr.shape[0])
    if b - a < 2:
        return 0.0
    dark = arr[a:b] < 200
    # Body text is dark too, so quantity of ink cannot tell a paragraph from a plot. What
    # a plot has and a paragraph does not is long unbroken strokes: axes, frames, rules.
    # Score the band by how many of its rows contain one.
    w = dark.shape[1]
    run = np.zeros(dark.shape[0], dtype=int)
    for row in range(dark.shape[0]):
        d = dark[row]
        if not d.any():
            continue
        idx = np.flatnonzero(np.diff(np.concatenate(([0], d.view(np.int8), [0]))))
        if len(idx):
            run[row] = (idx[1::2] - idx[::2]).max()
    return float((run > 0.25 * w).sum())


def locate(project, wanted=None):
    meta = PAPERS[project]
    pdf = os.path.join(ROOT, project, paper_pdf(project, meta))
    sc = scout(project, PAPERS)
    for num, page in sc["figures"].items():
        if wanted and num not in wanted:
            continue
        w, h, words = page_words(pdf, page)
        if not words:
            print("# %s fig%s: page %d has no text layer" % (project, num, page))
            continue
        lines = lines_of(words)
        # the caption line: starts with Fig/Figure and carries this number
        cap_i = None
        for i, ln in enumerate(lines):
            head = [t[4].strip() for t in ln[:4]]
            if not head or not CAP.match(head[0].rstrip(".")):
                continue
            # "Fig. 1." and "Figure 1:" and "FIGURE 1 —" all name the same figure
            if any(re.sub(r"[^\w]", "", t) == num for t in head[1:4]):
                cap_i = i
                break
        if cap_i is None:
            print("# %s fig%s: caption not found on page %d" % (project, num, page))
            continue
        cap_top = min(t[1] for t in lines[cap_i])
        # walk up while lines are sparse (axis labels, tick marks); stop at running text
        measure = max(t[2] for t in words) - min(t[0] for t in words)
        top = cap_top
        j = cap_i - 1
        full = 0
        while j >= 0:
            ln = lines[j]
            width = max(t[2] for t in ln) - min(t[0] for t in ln)
            if width > 0.55 * measure and len(ln) > 6:
                full += 1
                if full >= 2:
                    break
            else:
                full = 0
            top = min(t[1] for t in ln)
            j -= 1
        # The running head is the topmost line of the page with a wide gap below it. A
        # figure that fills the page otherwise swallows it.
        included = [ln for ln in lines[:cap_i] if min(t[1] for t in ln) >= top - 0.5]
        if included and min(t[1] for t in included[0]) < 0.08 * h:
            # a line in the top eighth of the page, above everything else, is the running
            # head; the artwork starts below it
            top = max(t[3] for t in included[0]) + 10.0
            if len(included) >= 2:
                top = min(top, min(t[1] for t in included[1]))
        # Some journals set the caption above the artwork and some below it, so both bands
        # are measured and the one that actually holds ink wins. Guessing the convention
        # from the journal would be guessing; counting dark pixels is not.
        cap_bot = max(t[3] for t in lines[cap_i])
        above = (max(0.0, (top - 6.0) / h), max(0.0, (cap_top - 2.0) / h))
        below_stop = h
        for ln in lines[cap_i + 1:]:
            width = max(t[2] for t in ln) - min(t[0] for t in ln)
            if width > 0.55 * measure and len(ln) > 6:
                below_stop = min(t[1] for t in ln)
                break
        below = (min(1.0, (cap_bot + 2.0) / h), min(1.0, (below_stop - 4.0) / h))
        best = max((above, below), key=lambda b: ink(pdf, page, b))
        y0, y1 = best
        if y1 - y0 < 0.03:
            print("# %s fig%s: no artwork band found on page %d" % (project, num, page))
            continue
        print("python3 tools/extract_figure.py %s %s %d %.4f %.4f %.4f %.4f"
              % (project, num, page, 0.04, y0, 0.97, y1))


if __name__ == "__main__":
    args = sys.argv[1:]
    locate(args[0], set(args[1:]) or None)
