#!/usr/bin/env python3
"""Restore the caption above a table continuation whose heading became a data row.

In the transcript the defect looks like this:

    | Leith, Moldovan, and Rossi (2012) | Review of Economic Dynamics | 2 |
                                        <- blank line
    | Study | Outlet | N |              <- the continuation's heading
    | --- | --- | --- |
    | Pontiggia (2012) | Journal of Macroeconomics | 2 |

The blank line ends nothing as far as the builder is concerned: with no caption to start a
new table it keeps appending, and the heading lands among the studies.

Putting the caption back is what the corpus already does wherever the transcription caught
the continuation, and it is what the PDF prints ("Table 1 continued"). The caption is
copied from the table this one continues, so the wording matches.

    --dry-run   report only
"""

import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAPTION = re.compile(r"^(TABLE\s+[A-Z]?\d+[A-Za-z]?)\.\s*(.*)$")
SEP = re.compile(r"^\|[\s\-:|]+\|$")


def is_row(line):
    return line.startswith("|") and line.rstrip().endswith("|")


def main(argv):
    dry = "--dry-run" in argv
    total = 0
    tdir = os.path.join(ROOT, "tools", "transcripts")
    for fn in sorted(os.listdir(tdir)):
        p = os.path.join(tdir, fn)
        lines = io.open(p, encoding="utf-8", errors="replace").read().split("\n")
        out, i, n = [], 0, 0
        last_caption = None
        while i < len(lines):
            line = lines[i]
            m = CAPTION.match(line.strip())
            if m:
                last_caption = (m.group(1), m.group(2))
            # blank, then a header row, then a separator, with a table row just before
            if (line.strip() == "" and i + 2 < len(lines)
                    and is_row(lines[i + 1]) and SEP.match(lines[i + 2].strip())
                    and out and is_row(out[-1].rstrip()) and last_caption):
                label, text = last_caption
                if "(continued)" in text.lower():
                    cap = "%s. %s" % (label, text)
                else:
                    cap = "%s (continued). %s" % (label, text)
                out.append("")
                out.append(cap)
                n += 1
                i += 1
                continue
            out.append(line)
            i += 1
        if n:
            total += n
            print("  %-20s %d continuation caption(s) restored" % (fn[:-3], n))
            if not dry:
                io.open(p, "w", encoding="utf-8", newline="").write("\n".join(out))
    print("\n%d caption(s) %s." % (total, "would be restored" if dry else "restored"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
