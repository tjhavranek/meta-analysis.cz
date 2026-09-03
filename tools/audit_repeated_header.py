#!/usr/bin/env python3
"""Find a table's own header row printed again as a row of data.

A long table is continued over several PDF pages, and each new page repeats the column
headings under a "Table N continued" line. When the continuation is transcribed without
its caption, the builder has no reason to start a new table: it folds the rows into the
previous one, and the repeated headings arrive as an ordinary data row. The reader then
meets "Study | Outlet | N" sitting between two studies.

The test is exact and needs no source: inside one rendered table, does a body row carry
the same cells as the header row.

Fixing it means restoring the "TABLE N (continued)." caption above each continuation, which
is what the corpus already does where the transcription caught it, and what the PDF prints.
"""

import glob
import html as H
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TAG = re.compile(r"<[^>]+>")


def cells(row):
    """Every cell in document order. The builder marks the first cell of a body row as
    <th scope="row">, so collecting only <td> misses it -- and the first cell is exactly
    where the repeated heading sits."""
    return [re.sub(r"\s+", " ", H.unescape(TAG.sub("", c))).strip()
            for c in re.findall(r"<t[hd][^>]*>(.*?)</t[hd]>", row, re.S)]


def main(argv):
    only = argv[1] if len(argv) > 1 else None
    hits = 0
    pages = sorted(glob.glob(os.path.join(ROOT, "*", "paper", "index.html")) +
                   glob.glob(os.path.join(ROOT, "*", "supplement", "index.html")))
    for p in pages:
        proj = os.path.basename(os.path.dirname(os.path.dirname(p)))
        if only and proj != only:
            continue
        s = io.open(p, encoding="utf-8", errors="replace").read()
        for tbl in re.findall(r"(?s)<table.*?</table>", s):
            rows = re.findall(r"(?s)<tr[^>]*>.*?</tr>", tbl)
            thead = re.search(r"(?s)<thead.*?</thead>", tbl)
            head = [c for c in cells(thead.group(0)) if c] if thead else None
            if not head or len(head) < 2:
                continue
            body_part = tbl[thead.end():] if thead else tbl
            for r in re.findall(r"(?s)<tr[^>]*>.*?</tr>", body_part):
                body = [c for c in cells(r) if c]
                if body and body == head:
                    hits += 1
                    cap = re.search(r"<caption[^>]*>(.*?)</caption>", tbl, re.S)
                    cap = re.sub(r"\s+", " ", H.unescape(TAG.sub("", cap.group(1)))).strip() if cap else "(no caption)"
                    print("  %-20s %-46s repeated header: %s"
                          % (proj, cap[:46], " | ".join(head)[:60]))
    print("\n%d repeated header row(s) across %d page(s)." % (hits, len(pages)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
