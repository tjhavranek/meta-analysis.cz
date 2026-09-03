#!/usr/bin/env python3
"""Attach an exhibit's note to the exhibit, so it stops reading as the author's prose.

A "Notes:" block separated from its table or figure by a blank line is rendered by
build_paper_page.py as an ordinary paragraph: body face, body size, full-strength ink. On
the page it then reads as a sentence of the article rather than as the small print under an
exhibit. 125 of them across the corpus.

Two different repairs, because the builder has two different constructs:

  TABLE   the paragraph on the line directly after a table IS that table's note; the rule
          is documented at the top of the builder. Deleting the blank line is the whole fix
          and it comes out as <p class="table-note">.

  FIGURE  there is no such rule for figures, and .fig-note is dead CSS the builder never
          emits. The corpus convention, 167 captions strong, is to carry the note in the
          caption line, and the builder plainly expects that: when it derives alt text it
          splits the caption on "Notes:" and keeps only the part before, so that the alt
          describes the picture and the note does not land mid-word in it.

So: tables lose a blank line, figures gain their note on the caption line. No wording
changes either way, and nothing moves between exhibits.

    --dry-run   report only
"""

import io
import os
import re
import sys
import unicodedata
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NOTE = re.compile(r"^(Notes?|Source):\s")
# Numbers run from "2" through "A2" and "S13" to "I.4.1"; a narrower pattern left
# a dotted-appendix figure behind.
FIG = re.compile(r"^FIGURE\s+[A-Za-z]*[\d.]+[A-Za-z]?\b")
SEP = re.compile(r"^\|[\s\-:|]+\|$")


def bag(t):
    t = unicodedata.normalize("NFKD", t)
    t = "".join(c for c in t if not unicodedata.combining(c))
    return Counter(re.findall(r"[A-Za-z0-9]+", t))


def is_row(s):
    return s.startswith("|") and s.rstrip().endswith("|")


def main(argv):
    dry = "--dry-run" in argv
    tot_t = tot_f = 0
    tdir = os.path.join(ROOT, "tools", "transcripts")
    for fn in sorted(os.listdir(tdir)):
        p = os.path.join(tdir, fn)
        src = io.open(p, encoding="utf-8", errors="replace").read()
        lines = src.split("\n")
        out, i, nt, nf = [], 0, 0, 0
        while i < len(lines):
            s = lines[i].strip()
            # blank line between a table's last row and its note
            if (s == "" and out and is_row(out[-1].strip())
                    and i + 1 < len(lines) and NOTE.match(lines[i + 1].strip())):
                nt += 1
                i += 1                      # drop the blank line
                continue
            # blank line between a figure caption and its note
            if (s == "" and out and FIG.match(out[-1].strip())
                    and i + 1 < len(lines) and NOTE.match(lines[i + 1].strip())):
                out[-1] = out[-1].rstrip() + " " + lines[i + 1].strip()
                nf += 1
                i += 2
                continue
            # note on the line DIRECTLY under the caption, no blank line. Unlike a table,
            # where adjacency is what makes a note a note, a figure caption is one line:
            # the builder closes the figure and the next line becomes a paragraph anyway.
            if (NOTE.match(s) and out and FIG.match(out[-1].strip())):
                out[-1] = out[-1].rstrip() + " " + s
                nf += 1
                i += 1
                continue
            out.append(lines[i])
            i += 1
        if not (nt or nf):
            continue
        new = "\n".join(out)
        if bag(new) != bag(src):
            print("  %-20s REFUSED: word multiset changed" % fn[:-3])
            continue
        tot_t += nt
        tot_f += nf
        print("  %-20s %2d table note(s) attached, %2d figure note(s) moved into the caption"
              % (fn[:-3], nt, nf))
        if not dry:
            io.open(p, "w", encoding="utf-8", newline="").write(new)
    print("\n%d table note(s) and %d figure note(s) %s."
          % (tot_t, tot_f, "would be fixed" if dry else "fixed"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
