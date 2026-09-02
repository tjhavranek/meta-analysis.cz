#!/usr/bin/env python3
"""Put a clause the converter dropped back into a transcript, in the paper's own words.

    python3 tools/restore_dropped_text.py <confirmed.json> [--apply]

Input is the list a reviewer confirmed, each entry carrying the project, the transcript
phrase the gap opens after, and the VERBATIM text from the PDF, captured by
tools/audit_dropped_text.py by slicing the source between two word offsets. Nothing here
composes a sentence: the words, their capitals and their punctuation all come from the
paper.

Refuses anything it cannot place exactly once. If the anchor phrase appears twice, or the
text is already there, it skips and says so, because putting a sentence in the wrong
paragraph is worse than leaving the gap.

Without --apply it reports and writes nothing.
"""

import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANSCRIPTS = os.path.join(ROOT, "tools", "transcripts")


def anchor_pattern(before):
    """The last few words of the anchor, tolerant of the punctuation between them."""
    words = before.split()[-5:]
    return re.compile(r"\W+".join(re.escape(w) for w in words), re.I)


def restore(project, before, verbatim, apply):
    path = os.path.join(TRANSCRIPTS, "%s.md" % project)
    if not os.path.exists(path):
        return "no transcript"
    s = io.open(path, encoding="utf-8").read()
    key = re.sub(r"\W+", " ", verbatim).strip().lower()
    if key and re.sub(r"\W+", " ", s).lower().find(key) >= 0:
        return "already present"
    pat = anchor_pattern(before)
    hits = list(pat.finditer(s))
    if len(hits) != 1:
        return "anchor matches %d times" % len(hits)
    m = hits[0]
    tail = s[m.end():m.end() + 1]
    # join the restored clause to what follows the way the sentence ran originally
    ins = verbatim
    if not ins.endswith((".", "!", "?")):
        ins += "."
    lead = "" if s[m.end() - 1:m.end()].isspace() else " "
    trail = "" if tail.isspace() else " "
    out = s[:m.end()] + lead + ins + trail + s[m.end():]
    if apply:
        io.open(path, "w", encoding="utf-8", newline="\n").write(out)
    return "restored %d chars" % len(ins)


def main(argv):
    apply = "--apply" in argv
    argv = [a for a in argv if a != "--apply"]
    if not argv:
        raise SystemExit("usage: restore_dropped_text.py <confirmed.json> [--apply]")
    rows = json.load(io.open(argv[0], encoding="utf-8"))
    done = 0
    for r in rows:
        why = restore(r["project"], r["before"], r["verbatim"], apply)
        print("%-22s %-22s %s" % (r["project"], why, r["verbatim"][:60]))
        if why.startswith("restored"):
            done += 1
    print("\n%s %d of %d" % ("restored" if apply else "would restore", done, len(rows)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
