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
            head = [t[4] for t in ln[:3]]
            if head and CAP.match(head[0].rstrip(".")) and any(
                    t.strip(".:") == num for t in head[1:3]):
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
        gap = 6.0
        y0 = max(0.0, (top - gap) / h)
        y1 = min(1.0, (cap_top - 2.0) / h)
        if y1 - y0 < 0.04:                       # nothing between: art sits above the text
            y0, y1 = max(0.0, y0 - 0.18), y1
        print("python3 tools/extract_figure.py %s %s %d %.4f %.4f %.4f %.4f"
              % (project, num, page, 0.04, y0, 0.97, y1))


if __name__ == "__main__":
    args = sys.argv[1:]
    locate(args[0], set(args[1:]) or None)
