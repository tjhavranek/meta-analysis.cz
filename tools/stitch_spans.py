#!/usr/bin/env python3
"""Join the per-span transcripts of a paper into one.

    python3 tools/stitch_spans.py <project> [<project> ...]

Each span of pages is transcribed separately and left in /tmp/span-<project>-<n>.md. Joining
them is mechanical: concatenate in order, drop the drafting header, rejoin the paragraph the
seam cut in half, and collapse a heading that both sides of a seam repeated. Nothing here
rewrites a word, so the fidelity gate still means what it means.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HEADER = re.compile(r"^<!--.*?-->\s*$", re.S | re.M)


def spans(project):
    out = []
    for name in os.listdir("/tmp"):
        m = re.fullmatch(r"span-%s-(\d+)\.md" % re.escape(project), name)
        if m:
            out.append((int(m.group(1)), os.path.join("/tmp", name)))
    return [p for _, p in sorted(out)]


def clean(text):
    text = HEADER.sub("", text)
    text = re.sub(r"^#\s+.*$", "", text, count=1, flags=re.M)      # the drafting title
    text = re.sub(r"<<[^>]*?>>", "", text)                          # any surviving marker
    return text.strip("\n")


def stitch(project):
    parts = [clean(open(p).read()) for p in spans(project)]
    if not parts:
        return None
    body = parts[0]
    for nxt in parts[1:]:
        prev_lines = body.rstrip("\n").split("\n")
        next_lines = nxt.lstrip("\n").split("\n")
        tail = prev_lines[-1].strip()
        head = next_lines[0].strip()
        # a sentence cut by the seam: the span ended mid-clause and the next starts lower-case
        joinable = (tail and head
                    and not re.search(r"[.!?:;\"')\]]$", tail)
                    and not tail.startswith(("#", "|", "TABLE", "FIGURE", "$$"))
                    and re.match(r"^[a-z(]", head))
        if joinable:
            prev_lines[-1] = tail + " " + head
            next_lines = next_lines[1:]
            body = "\n".join(prev_lines + next_lines)
            continue
        # the same heading repeated on both sides of the seam
        if head.startswith("#") and head == tail:
            next_lines = next_lines[1:]
        body = "\n".join(prev_lines) + "\n\n" + "\n".join(next_lines)
    # A span sometimes carries the paper's back matter as well as its own pages, so the
    # endnotes or a figure caption arrive twice. A paper does not repeat a long sentence
    # verbatim, nor number two figures alike, so a second identical one is the seam's fault.
    seen, kept = set(), []
    for line in body.split("\n"):
        t = line.strip()
        key = None
        if len(t) >= 80 and re.match(r"^[A-Za-z0-9(]", t) and not t.startswith("|"):
            key = t
        m = re.match(r"^(TABLE|FIGURE)\s+([A-Za-z0-9.]+)", t)
        if m:
            key = m.group(0)
        if key is not None:
            if key in seen:
                continue
            seen.add(key)
        kept.append(line)
    body = "\n".join(kept)
    # Back matter split across spans arrives as two "## ENDNOTES" sections holding notes
    # 1-3 and 4-9. They are one list; the later blocks fold into the first.
    for heading in ("ENDNOTES", "REFERENCES"):
        blocks = [m.start() for m in re.finditer(r"^##\s+%s\s*$" % heading, body, re.M)]
        if len(blocks) < 2:
            continue
        chunks = re.split(r"^##\s+%s\s*$" % heading, body, flags=re.M)
        head, rest = chunks[0], chunks[1:]
        # each chunk runs until the next heading of any kind
        items, trailing = [], []
        for c in rest:
            m = re.search(r"^##\s+", c, re.M)
            items.append(c[:m.start()] if m else c)
            trailing.append(c[m.start():] if m else "")
        body = head + "## %s\n" % heading + "\n".join(x.strip("\n") for x in items) \
            + "\n" + "\n".join(t for t in trailing if t.strip())
    body = re.sub(r"\n{3,}", "\n\n", body)
    out = os.path.join(ROOT, "tools", "transcripts", "%s.md" % project)
    with open(out, "w") as fh:
        fh.write(body.strip("\n") + "\n")
    return len(parts), len(body.split())


if __name__ == "__main__":
    for proj in sys.argv[1:]:
        r = stitch(proj)
        print("%-22s %s" % (proj, "no spans found" if not r
                            else "%d spans -> %d words" % r))
