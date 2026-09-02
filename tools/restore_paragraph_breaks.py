"""Put back the paragraph breaks a conversion lost, using the PDF's own typography.

A transcript that fuses ten paragraphs into one is faithful in its words and unreadable on
the page: /beauty/ carried a single block of 14,667 characters. The breaks are recoverable
rather than a matter of taste, because a justified paragraph ends on a SHORT line and the
next one starts back at the margin. A break is restored only where three things agree:

  * the PDF shows a paragraph starting there (short previous line, next line at the margin);
  * the transcript has a sentence boundary at that exact point, so no sentence can be cut;
  * the opening phrase occurs exactly once, so it cannot land in the wrong place.

It inserts a blank line and nothing else. The word sequence is asserted unchanged.
"""
import collections
import io
import os
import re
import sys

import fitz

ROOT = r"C:\Users\thavr\Dropbox\Study\Other\Agents\Joint\web_meta\site"
LIG = {"\ufb01": "fi", "\ufb02": "fl", "\ufb00": "ff", "\ufb03": "ffi", "\ufb04": "ffl"}


def clean(t):
    for k, v in LIG.items():
        t = t.replace(k, v)
    return t


def pdf_para_starts(pdf):
    d = fitz.open(pdf)
    out = []
    try:
        for i in range(d.page_count):
            L = []
            for b in d.load_page(i).get_text("dict")["blocks"]:
                for l in b.get("lines", []):
                    t = "".join(s["text"] for s in l["spans"]).strip()
                    if t:
                        L.append((l["bbox"][0], l["bbox"][2], l["bbox"][1], t))
            if len(L) < 6:
                continue
            L.sort(key=lambda r: r[2])
            right = collections.Counter(round(r[1]) for r in L).most_common(1)[0][0]
            left = collections.Counter(round(r[0]) for r in L).most_common(1)[0][0]
            for j in range(len(L) - 1):
                cur, nxt = L[j], L[j + 1]
                if (cur[1] < right - 28
                        and (abs(nxt[0] - left) < 6 or left + 8 <= nxt[0] <= left + 30)
                        and len(nxt[3].split()) >= 5):
                    out.append(clean(nxt[3]))
    finally:
        d.close()
    return out


def restore(project, pdf, apply):
    path = os.path.join(ROOT, "tools", "transcripts", "%s.md" % project)
    tr = io.open(path, encoding="utf-8").read().replace("\r\n", "\n")
    before_words = tr.split()
    cuts = []
    for t in pdf_para_starts(pdf):
        probe = " ".join(t.split()[:7])
        if tr.count(probe) != 1:
            continue
        pos = tr.find(probe)
        if pos <= 0 or "\n\n" in tr[max(0, pos - 3):pos]:
            continue
        head = tr[:pos].rstrip()
        if head.endswith((".", "!", "?", '."', "\u201d", ".'")):
            cuts.append(pos)
    for pos in sorted(set(cuts), reverse=True):
        tr = tr[:pos].rstrip(" ") + "\n\n" + tr[pos:]
    assert tr.split() == before_words, "%s: the words changed" % project
    if apply:
        io.open(path, "w", encoding="utf-8", newline="\n").write(tr)
    return len(set(cuts))


def main(argv):
    apply = "--apply" in argv
    names = [a for a in argv if a != "--apply"]
    total = 0
    for project in names:
        pdfs = [p for p in sorted(os.listdir(os.path.join(ROOT, project)))
                if p.endswith(".pdf")]
        if not pdfs:
            print("%-18s no pdf" % project)
            continue
        n = restore(project, os.path.join(ROOT, project, pdfs[0]), apply)
        total += n
        print("%-18s %3d break(s) %s" % (project, n, "restored" if apply else "would restore"))
    print("\n%s %d paragraph break(s) across %d paper(s)"
          % ("restored" if apply else "would restore", total, len(names)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
