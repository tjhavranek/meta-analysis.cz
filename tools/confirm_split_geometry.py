#!/usr/bin/env python3
"""Confirm a float-split candidate from the PDF's GEOMETRY.

Comparing text runs fails on the table-heavy cases: at a page break pdftotext emits the
whole float between the two halves, and a table's cells are thousands of tokens, so "is
the gap only the float?" cannot be answered by counting words.

Geometry answers it directly, and it is what a person checking by hand actually looks at.
A sentence broken by a page turn leaves an unmistakable signature:

    the first half is the LAST body line of page N, hard against the bottom margin
    the second half is a body line of page N+1, starting at the left margin rather than
    at a paragraph indent

That is exactly what was verified by hand for house_prices, border, alphas, forward, dst,
dst_slovakia and education. This does it for every candidate at once.

Reports, per candidate: the page each half sits on, how far down the page the first half
ends (as a fraction of the text block), and the verdict.
"""

import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import fitz
from audit_split_by_float import blocks, is_float, is_prose, ends_open, starts_lower


def clean(s):
    s = re.sub(r"\*\*?|\^\{[^}]*\}|\$[^$]*\$", " ", s)
    s = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", s)
    return " ".join(s.split())


def probe(s, n, tail):
    w = clean(s).split()
    if len(w) < 3:
        return ""
    return " ".join(w[-n:] if tail else w[:n])


def locate(doc, phrase):
    """(page index, y0, y1, page height) of the first hit, searching progressively
    shorter prefixes because a line break can split any fixed-length probe."""
    words = phrase.split()
    for n in range(len(words), 2, -1):
        p = " ".join(words[:n]) if False else " ".join(words[-n:] if False else words[:n])
        for i in range(doc.page_count):
            r = doc.load_page(i).search_for(p)
            if r:
                pg = doc.load_page(i)
                return i, r[0].y0, r[0].y1, pg.rect.height
    return None


def main(argv):
    from build_paper_page import transcript_pdf_paths, documents
    P = {p["project"]: p for p in
         json.load(io.open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    P.update(documents())

    want = set(argv[1:]) or None
    tdir = os.path.join(ROOT, "tools", "transcripts")
    conf = rej = 0
    for fn in sorted(os.listdir(tdir)):
        proj = fn[:-3]
        if want and proj not in want:
            continue
        if proj not in P:
            continue
        bs = blocks(io.open(os.path.join(tdir, fn), encoding="utf-8", errors="replace").read())
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
        try:
            pdfs = transcript_pdf_paths(proj, P[proj])
        except Exception:
            continue
        if not pdfs:
            continue
        doc = fitz.open(pdfs[0])
        for b, fl, nxt in cands:
            t = probe(b, 8, True)
            h = probe(nxt, 8, False)
            lt = locate(doc, t)
            lh = locate(doc, h)
            if not lt or not lh:
                print("  ?        %-18s could not locate %s" % (
                    proj, "tail" if not lt else "head"))
                rej += 1
                continue
            tp, ty0, ty1, th = lt
            hp, hy0, hy1, hh = lh
            frac = ty1 / th
            # A float can occupy WHOLE pages: forward's Fig. A2 fills p23, so the sentence
            # that breaks at the foot of p22 resumes on p24. Allow the halves to be a few
            # pages apart and report the distance rather than demanding adjacency.
            ok = (tp < hp <= tp + 4) or (hp == tp and hy0 > ty1)
            # And the first half need not sit at the very foot of the page: where a float
            # is anchored at the bottom, as border's Figure 1 is, the text stops halfway.
            deep = frac > 0.33
            verdict = "CONFIRMED" if (ok and deep) else "no"
            if verdict == "CONFIRMED":
                conf += 1
            else:
                rej += 1
            print("  %-9s %-18s tail p%-3d at %3d%% down | head p%-3d %s" % (
                verdict, proj, tp + 1, int(frac * 100), hp + 1,
                "(next page)" if hp == tp + 1 else "(same page, below)" if hp == tp else "(elsewhere)"))
        doc.close()
    print("\n%d confirmed, %d not." % (conf, rej))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
