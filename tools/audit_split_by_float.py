#!/usr/bin/env python3
"""Find sentences the conversion cut in half AROUND a figure or table.

The defect
----------
A journal sets a float at the top of a page. The sentence running across that page break
is therefore interrupted, in the PDF's reading order, by the float's caption. Transcribed
in page order, the page then reads:

    ... its specific forms are
    FIGURE 2. Reported effects of monetary policy on house prices ...
    also called selective reporting or p-hacking, ...

which is one sentence broken into two paragraphs with a caption wedged between them.

Why the existing screen misses it
---------------------------------
tools/audit_continuity.py compares ADJACENT paragraphs. Here the halves are not adjacent:
a caption, or a whole table, sits between them. Every instance below was invisible to it,
and to the fidelity checker, which sees every word present and none invented.

This has been confirmed by hand in house_prices, border, alphas, forward (three times),
dst (twice), dst_slovakia (twice) and education (three times), always with the same
signature and always against a real PDF page break.

What counts as a hit
--------------------
A prose paragraph that ends without terminal punctuation, followed by one or more float
blocks, followed by a prose paragraph that begins lower case. Both halves must look like
running prose, so headings, list items and the floats themselves are skipped.

Every hit is a CANDIDATE. Confirm against the PDF before joining anything: a paragraph can
legitimately end on a colon or a lower-case symbol, and some papers do start a sentence
with a lower-case variable name.
"""

import argparse
import glob
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FLOAT = re.compile(r"^(FIGURE|TABLE|Fig\.|Notes?:|\|)", re.I)
HEADING = re.compile(r"^(#|\^\{|\s*$)")
TERMINAL = re.compile(r"[.!?:;\"'’”\)\]]\s*$")
# a paragraph ending on a footnote marker is finished, e.g. "... in the literature.^{5}"
MARKER_END = re.compile(r"\^\{[^}]*\}\s*$")


def blocks(text):
    out, cur = [], []
    for line in text.split("\n"):
        if line.strip() == "":
            if cur:
                out.append("\n".join(cur))
                cur = []
        else:
            cur.append(line)
    if cur:
        out.append("\n".join(cur))
    return out


def is_float(b):
    return bool(FLOAT.match(b.strip()))


def is_prose(b):
    s = b.strip()
    if HEADING.match(s) or is_float(s):
        return False
    if s.startswith(("- ", "* ", "> ")):
        return False
    return len(s) > 40


def ends_open(b):
    s = b.strip()
    if MARKER_END.search(s):
        return False
    if TERMINAL.search(s):
        return False
    # a closing $...$ or a number can legitimately end a sentence without a stop only
    # rarely; treat anything not terminal as open, which is what the signature needs.
    return True


def starts_lower(b):
    s = b.strip()
    m = re.match(r"[\(\"'‘“]*([A-Za-z])", s)
    return bool(m) and m.group(1).islower()


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--project")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args(argv)

    files = sorted(glob.glob(os.path.join(ROOT, "tools", "transcripts", "*.md")))
    if a.project:
        files = [f for f in files if os.path.basename(f)[:-3] == a.project]

    hits = 0
    for f in files:
        proj = os.path.basename(f)[:-3]
        bs = blocks(io.open(f, encoding="utf-8", errors="replace").read())
        for i, b in enumerate(bs):
            if not is_prose(b) or not ends_open(b):
                continue
            j = i + 1
            floats = []
            while j < len(bs) and is_float(bs[j]):
                floats.append(bs[j])
                j += 1
            if not floats or j >= len(bs):
                continue
            nxt = bs[j]
            if not is_prose(nxt) or not starts_lower(nxt):
                continue
            hits += 1
            print("\n%s  [%d float block(s) between]" % (proj, len(floats)))
            print("   ends open : ...%s" % b.strip()[-95:].replace("\n", " "))
            print("   float     : %s..." % floats[0].strip()[:80].replace("\n", " "))
            print("   resumes   : %s..." % nxt.strip()[:95].replace("\n", " "))
    print("\n%d candidate(s) across %d transcript(s)." % (hits, len(files)))
    print("Each is a CANDIDATE. Confirm the PDF page break before joining.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
