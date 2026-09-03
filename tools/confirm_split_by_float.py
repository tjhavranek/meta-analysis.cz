#!/usr/bin/env python3
"""Confirm a float-split candidate against the published PDF.

audit_split_by_float.py finds paragraphs of the shape

    <prose ending mid-clause>  <FIGURE/TABLE block>  <prose resuming lower case>

which is what a sentence looks like after a float has been transcribed into the middle of
it. That shape is suggestive, not proof: a paragraph can legitimately end on a colon, and
a few papers do start a sentence with a lower-case symbol.

The test here is the one that settles it. Take the last words before the break and the
first words after it, and ask whether the PDF prints them as ONE RUN OF TEXT once the
float's own words are taken out of the way. If it does, the two halves are one sentence in
the published paper and the page is wrong to separate them.

Hyphenation across the source line break is undone before comparing ("systemat- ically"),
and so is the running head, which pdftotext interleaves at a page boundary.

Exit status is 0 when every candidate examined is CONFIRMED, 1 otherwise, so this can gate
a fix-up run.
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
from audit_split_by_float import blocks, is_float, is_prose, ends_open, starts_lower


def pdf_text(pdf):
    return subprocess.run([_poppler.tool("pdftotext"), pdf, "-"],
                          capture_output=True, text=True,
                          encoding="utf-8", errors="replace").stdout or ""


def norm(s):
    s = re.sub(r"\*\*?|\^\{[^}]*\}|\$[^$]*\$|\[[^\]]*\]\([^)]*\)", " ", s)
    s = s.replace("­", "")
    s = re.sub(r"([A-Za-z])-\s+([a-z])", r"\1\2", s)      # undo hyphenation
    s = re.sub(r"[^A-Za-z0-9]+", " ", s)
    return " ".join(s.lower().split())


def tail_words(b, n=7):
    w = norm(b).split()
    return w[-n:] if len(w) >= n else w


def head_words(b, n=7):
    return norm(b).split()[:n]


def main(argv):
    from build_paper_page import transcript_pdf_paths, documents
    P = {p["project"]: p for p in
         json.load(io.open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    P.update(documents())

    want = argv[1:] or None
    files = sorted(os.listdir(os.path.join(ROOT, "tools", "transcripts")))
    cache = {}
    confirmed = rejected = 0

    for fn in files:
        proj = fn[:-3]
        if want and proj not in want:
            continue
        if proj not in P:
            continue
        path = os.path.join(ROOT, "tools", "transcripts", fn)
        bs = blocks(io.open(path, encoding="utf-8", errors="replace").read())
        cands = []
        for i, b in enumerate(bs):
            if not is_prose(b) or not ends_open(b):
                continue
            j = i + 1
            fl = []
            while j < len(bs) and is_float(bs[j]):
                fl.append(bs[j])
                j += 1
            if fl and j < len(bs) and is_prose(bs[j]) and starts_lower(bs[j]):
                cands.append((b, fl, bs[j]))
        if not cands:
            continue
        if proj not in cache:
            try:
                cache[proj] = " ".join(norm(pdf_text(p)) for p in transcript_pdf_paths(proj, P[proj]))
            except Exception as e:
                print("%-18s could not read PDF: %s" % (proj, e))
                continue
        hay = cache[proj]
        for b, fl, nxt in cands:
            t = " ".join(tail_words(b))
            h = " ".join(head_words(nxt))
            joined = t + " " + h
            ok = joined in hay
            gap = None
            if not ok and t in hay:
                # At a page break pdftotext emits the float's own text BETWEEN the two
                # halves, in visual order. So the halves are one sentence exactly when
                # everything separating them belongs to the float (plus the running head
                # and folio). Anything else in the gap means they are genuinely apart.
                i1 = hay.find(t) + len(t)
                i2 = hay.find(h, i1)
                if i2 >= 0:
                    gap = hay[i1:i2].strip()
                    allowed = set()
                    for blk in fl:
                        allowed |= set(norm(blk).split())
                    # the running head is the title and author words, already in the PDF
                    allowed |= set(norm(P[proj].get("title", "")).split())
                    allowed |= set(norm(P[proj].get("authors", "") if isinstance(
                        P[proj].get("authors", ""), str) else " ".join(
                        P[proj].get("authors", []))).split())
                    stray = [w for w in gap.split()
                             if w not in allowed and not w.isdigit()]
                    ok = len(stray) <= 3
            if ok:
                confirmed += 1
                print("CONFIRMED  %-18s ...%s | %s..." % (proj, t[-52:], h[:52]))
                if gap:
                    print("            (page furniture between: %r)" % gap[:70])
            else:
                rejected += 1
                print("not shown  %-18s ...%s | %s..." % (proj, t[-52:], h[:52]))
    print("\n%d confirmed, %d not confirmed by the PDF." % (confirmed, rejected))
    return 0 if rejected == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
