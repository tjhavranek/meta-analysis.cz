#!/usr/bin/env python3
"""Rejoin sentences that a float was transcribed into the middle of, and move the float out.

Reads the same candidates as audit_split_by_float.py. For each, it

    1. joins the two halves back into one paragraph, undoing hyphenation across the break,
    2. moves the intervening FIGURE/TABLE blocks to just after the rejoined paragraph,

so the float still sits where the paper puts it relative to the surrounding text, but no
longer interrupts a sentence.

Nothing is written unless the transcript's word multiset is unchanged apart from a
hyphenated word being made whole. Moving a float changes word ORDER, so order cannot be
the invariant; the guard is on the multiset, which catches a dropped or duplicated block.

    --dry-run   show what would change
    --project P restrict to one paper
    --only N    apply only the Nth candidate of each project (1-based)

Confirm candidates first with tools/confirm_split_geometry.py. This tool does not consult
the PDF; it trusts the caller.
"""

import argparse
import io
import os
import re
import sys
import unicodedata
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

from audit_split_by_float import blocks, is_float, is_prose, ends_open, starts_lower


def bag(t):
    t = unicodedata.normalize("NFKD", t)
    t = "".join(c for c in t if not unicodedata.combining(c))
    # a word split by hyphenation becomes whole, so compare on letters only
    t = re.sub(r"([A-Za-z])-\s+([a-z])", r"\1\2", t)
    return Counter(re.findall(r"[A-Za-z0-9]+", t))


def join(a, b):
    a, b = a.rstrip(), b.lstrip()
    if a.endswith("-"):
        return a[:-1] + b
    return a + " " + b


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--project")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args(argv)

    tdir = os.path.join(ROOT, "tools", "transcripts")
    total = 0
    for fn in sorted(os.listdir(tdir)):
        proj = fn[:-3]
        if a.project and proj != a.project:
            continue
        path = os.path.join(tdir, fn)
        raw = io.open(path, encoding="utf-8", errors="replace").read()
        bs = blocks(raw)
        out, i, n = [], 0, 0
        while i < len(bs):
            b = bs[i]
            if is_prose(b) and ends_open(b):
                j = i + 1
                fl = []
                while j < len(bs) and is_float(bs[j]):
                    fl.append(bs[j])
                    j += 1
                if fl and j < len(bs) and is_prose(bs[j]) and starts_lower(bs[j]):
                    out.append(join(b, bs[j]))
                    out.extend(fl)
                    n += 1
                    i = j + 1
                    continue
            out.append(b)
            i += 1
        if not n:
            continue
        new = "\n\n".join(out) + "\n"
        lost = bag(raw) - bag(new)
        gained = bag(new) - bag(raw)
        # Undoing hyphenation is the one legitimate change: the halves of a word split
        # across the page break ("het-" + "erogeneity") become one word. Cancel any pair
        # in `lost` that concatenates to a word in `gained`, and require the rest to be
        # empty. Anything else means a block was dropped or duplicated.
        for w in list(gained):
            for x in list(lost):
                for y in list(lost):
                    if x != y and x + y == w and lost[x] and lost[y] and gained[w]:
                        lost[x] -= 1
                        lost[y] -= 1
                        gained[w] -= 1
        lost = +lost
        gained = +gained
        if lost or gained:
            print("%-20s REFUSED: word multiset changed (lost %s, gained %s)"
                  % (proj, dict(lost), dict(gained)))
            continue
        total += n
        print("%-20s %d sentence(s) rejoined, float(s) moved after" % (proj, n))
        if not a.dry_run:
            io.open(path, "w", encoding="utf-8", newline="").write(new)
    print("\n%d rejoin(s) %s." % (total, "would be applied" if a.dry_run else "applied"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
