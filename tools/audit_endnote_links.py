#!/usr/bin/env python3
"""Check that every endnote marker has a note and every note has a marker.

A paper's notes survive the conversion as two separate things: a superscript marker in the
body, and an entry in the endnote list. Nothing so far checks that the two agree. Both
failures are silent and both are visible to a reader:

  orphan marker   the body carries a raised 7 that links to a note that is not there, so
                  the link goes nowhere
  orphan note     a note exists with no marker anywhere in the body, so the reader is never
                  sent to it and cannot tell what it belongs to
  duplicate       the same marker number twice in one paper, so one of the two links is
                  certainly wrong

Read from the BUILT pages, where the markers are real anchors and the notes are real list
items, so this checks what a reader actually gets rather than what the transcript intended.
"""

import glob
import html as H
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main(argv):
    only = argv[1] if len(argv) > 1 else None
    bad = 0
    pages = sorted(glob.glob(os.path.join(ROOT, "*", "paper", "index.html")) +
                   glob.glob(os.path.join(ROOT, "*", "supplement", "index.html")))
    for p in pages:
        proj = os.path.basename(os.path.dirname(os.path.dirname(p)))
        if only and proj != only:
            continue
        s = io.open(p, encoding="utf-8", errors="replace").read()

        # the endnote list: <ol class="endnotes"> ... <li id="note-N">
        m = re.search(r'(?s)<ol class="endnotes">(.*?)</ol>', s)
        notes = set()
        if m:
            notes = set(re.findall(r'id="note-([^"]+)"', m.group(1)))
            if not notes:                       # unnumbered ids: count the items
                notes = {str(i + 1) for i in range(len(re.findall(r"<li", m.group(1))))}

        body = s[:m.start()] if m else s
        markers = re.findall(r'href="#note-([^"]+)"', body)
        seen = set()
        dupes = {x for x in markers if x in seen or seen.add(x)}

        missing = sorted(set(markers) - notes, key=lambda x: (len(x), x))
        unused = sorted(notes - set(markers), key=lambda x: (len(x), x))
        if missing or unused or dupes:
            bad += 1
            print("  %-20s markers %-3d notes %-3d%s%s%s"
                  % (proj, len(set(markers)), len(notes),
                     "  orphan marker(s): " + ",".join(missing[:8]) if missing else "",
                     "  note(s) with no marker: " + ",".join(unused[:8]) if unused else "",
                     "  duplicate marker(s): " + ",".join(sorted(dupes)[:8]) if dupes else ""))
    print("\n%d page(s) with an endnote mismatch, of %d." % (bad, len(pages)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
