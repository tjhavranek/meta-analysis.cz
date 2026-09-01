#!/usr/bin/env python3
"""Put a verified extracted figure onto its page.

    python3 tools/adopt_figures.py <accepted.json> [--apply]

Takes the accepted list a reviewer produced, and for each figure:

  * trims the rendered crop back to its own ink and reduces it to 64 colours, which is what
    tools/extract_figure.py does and why the figures already on this site average 59 KB
    rather than 160;
  * writes it to <project>/paper/figures/fig<N>.png;
  * drops the "(no artwork)" marker from that figure's caption line in the transcript, which
    is what makes build_paper_page emit an <img> instead of the "The figure is in the PDF"
    note.

It refuses to touch a figure whose file already exists, so a rerun cannot overwrite artwork
that was extracted and reviewed earlier by someone else.

Without --apply it reports and writes nothing.
"""

import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import numpy as np                                             # noqa: E402
from PIL import Image                                          # noqa: E402

from build_paper_page import documents, page_dir               # noqa: E402

PAPERS = {p["project"]: p for p in
          json.load(open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
PAPERS.update(documents())
TRANSCRIPTS = os.path.join(ROOT, "tools", "transcripts")
COLOURS = 64


def trim(im, threshold=232, pad=8):
    a = np.asarray(im.convert("RGB")).min(axis=2)
    ink = a < threshold
    rows, cols = np.where(ink.any(axis=1))[0], np.where(ink.any(axis=0))[0]
    if not len(rows) or not len(cols):
        return im
    return im.crop((max(int(cols[0]) - pad, 0), max(int(rows[0]) - pad, 0),
                    min(int(cols[-1]) + pad + 1, im.width),
                    min(int(rows[-1]) + pad + 1, im.height)))


def uncover(project, fig):
    """Remove the (no artwork) marker for one figure. Returns True if it changed."""
    path = os.path.join(TRANSCRIPTS, "%s.md" % project)
    s = io.open(path, encoding="utf-8").read()
    pat = re.compile(r"^(FIGURE\s+%s)\s*\(no artwork\)(\s*\.)" % re.escape(fig),
                     re.I | re.M)
    new, n = pat.subn(r"\1\2", s)
    if n != 1:
        return False, n
    io.open(path, "w", encoding="utf-8", newline="\n").write(new)
    return True, n


def main(argv):
    apply = "--apply" in argv
    argv = [a for a in argv if a != "--apply"]
    if not argv:
        raise SystemExit("usage: adopt_figures.py <accepted.json> [--apply]")
    accepted = json.load(io.open(argv[0], encoding="utf-8"))
    done, skipped = 0, []
    for row in accepted:
        proj, fig, preview = row["project"], row["fig"], row["preview"]
        dest_dir = os.path.join(page_dir(proj, PAPERS[proj]), "figures")
        dest = os.path.join(dest_dir, "fig%s.png" % fig)
        if os.path.exists(dest):
            skipped.append((proj, fig, "artwork already present"))
            continue
        if not os.path.exists(preview):
            skipped.append((proj, fig, "no preview at %s" % preview))
            continue
        im = trim(Image.open(preview))
        if not apply:
            print("%-22s fig%-4s would write %dx%d" % (proj, fig, im.width, im.height))
            done += 1
            continue
        os.makedirs(dest_dir, exist_ok=True)
        im.quantize(COLOURS, method=Image.MEDIANCUT).save(dest, optimize=True)
        ok, n = uncover(proj, fig)
        if not ok:
            os.remove(dest)
            skipped.append((proj, fig, "caption marker matched %d times, not 1" % n))
            continue
        print("%-22s fig%-4s %dx%d  %d KB" % (proj, fig, im.width, im.height,
                                              os.path.getsize(dest) // 1024))
        done += 1
    print("\n%s %d figure(s)%s" % ("adopted" if apply else "would adopt", done,
                                   "" if apply else " (dry run)"))
    if skipped:
        print("skipped %d:" % len(skipped))
        for p, f, why in skipped[:20]:
            print("   %-20s fig%-4s %s" % (p, f, why))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
