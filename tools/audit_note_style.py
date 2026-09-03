#!/usr/bin/env python3
"""Report papers that style their exhibit notes BOTH ways.

Two renderings of a "Notes:" block exist across the corpus:

  separate   the note is its own paragraph under the exhibit, styled .fig-note/.table-note
  caption    the note is part of the caption line, set inside the <figcaption>

Neither is wrong on its own, and a first pass at this counted 167 captions carrying their
own notes, i.e. it is a settled convention in much of the corpus, not a defect. Rewriting
them all would be a restyle of the site, not a repair.

What IS a defect is a paper doing both, because then two figures a page apart are set
differently for no reason the reader can see. That is what this reports: per paper, the
counts each way, and a flag when both occur.

Nothing here is a fidelity question; the words are identical either way. Treat the output
as a tidiness list and fix the minority style within a paper, never across the corpus.
"""

import glob
import html as H
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TAG = re.compile(r"<[^>]+>")


def txt(s):
    return re.sub(r"\s+", " ", H.unescape(TAG.sub("", s))).strip()


def main(argv):
    rows = []
    for p in sorted(glob.glob(os.path.join(ROOT, "*", "paper", "index.html")) +
                    glob.glob(os.path.join(ROOT, "*", "supplement", "index.html"))):
        proj = os.path.basename(os.path.dirname(os.path.dirname(p)))
        s = io.open(p, encoding="utf-8", errors="replace").read()
        incap = sum(1 for m in re.finditer(r"(?s)<figcaption[^>]*>(.*?)</figcaption>", s)
                    if re.search(r"\.\s+Notes?:\s", txt(m.group(1))))
        sep = len(re.findall(r'<p class="fig-note"', s))
        tnote = len(re.findall(r'<p class="table-note"', s))
        stray = len(re.findall(r"(?s)</(?:table|figure)>\s*(?:</div>\s*)?"
                               r"<p(?![^>]*(?:table-note|fig-note))[^>]*>\s*Notes?:", s))
        if incap or sep or stray:
            rows.append((proj, incap, sep, tnote, stray))
    print("%-22s %8s %8s %9s %7s" % ("project", "inCapt", "figNote", "tableNote", "stray"))
    print("-" * 60)
    mixed = 0
    for proj, incap, sep, tnote, stray in rows:
        flag = ""
        if incap and sep:
            flag = "  <== MIXED: both styles for figures"
            mixed += 1
        elif stray:
            flag = "  <== %d note(s) not styled as the exhibit's own" % stray
        print("%-22s %8d %8d %9d %7d%s" % (proj, incap, sep, tnote, stray, flag))
    print("\n%d paper(s) use both figure-note styles." % mixed)
    print("A paper that is internally consistent needs no change, whichever style it uses.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
