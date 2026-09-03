#!/usr/bin/env python3
"""Find a table's or figure's own note rendered as ordinary body prose.

build_paper_page.py styles a "Notes:" block as the exhibit's note only when it follows the
exhibit with no blank line between them. A blank line in the transcript therefore demotes
the note to a paragraph: same words, but set in the body face at body size, as though the
paper had said it in running text.

Both halves of the same slip are reported:

  stray-note   a Notes:/Note: paragraph immediately after a table or figure that is NOT
               marked as that exhibit's note, while sibling exhibits on the same page are
  in-caption   a caption line that swallowed its own Notes: text, so the note is set as
               part of the caption instead of below it

Neither is visible to any other check: no word is missing, invented or out of order.
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
    only = argv[1] if len(argv) > 1 else None
    stray = incap = 0
    pages = sorted(glob.glob(os.path.join(ROOT, "*", "paper", "index.html")) +
                   glob.glob(os.path.join(ROOT, "*", "supplement", "index.html")))
    for p in pages:
        proj = os.path.basename(os.path.dirname(os.path.dirname(p)))
        if only and proj != only:
            continue
        s = io.open(p, encoding="utf-8", errors="replace").read()

        # a plain <p>Notes: ...</p> straight after a table or figure
        for m in re.finditer(r"(?s)</(table|figure)>\s*(?:</div>\s*)?<p(?![^>]*table-note)"
                             r"(?![^>]*fig-note)[^>]*>\s*(Notes?:.{0,80})", s):
            stray += 1
            print("  %-20s stray note after </%s>: %s..."
                  % (proj, m.group(1), txt(m.group(2))[:58]))

        # a figcaption that contains its own Notes:
        for m in re.finditer(r"(?s)<figcaption[^>]*>(.*?)</figcaption>", s):
            t = txt(m.group(1))
            if re.search(r"\.\s+Notes?:\s", t):
                incap += 1
                print("  %-20s note inside a caption: %s..." % (proj, t[:70]))

    print("\n%d stray note(s), %d note(s) trapped in a caption, across %d page(s)."
          % (stray, incap, len(pages)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
