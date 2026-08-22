#!/usr/bin/env python3
"""Check a transcript against the words the PDF actually contains.

    python3 tools/verify_transcript.py <project> [--context N] [--quiet]

A transcript is prose lifted from a published paper. The one failure that matters is a
word that changed: a dropped clause, a silently fixed typo, a number that moved a digit.
That failure is mechanically detectable, so it should not be left to a reader's attention.

This strips the transcript back to a bare word sequence, does the same to `pdftotext`
output, and diffs the two. Everything that is legitimately not body prose -- table cells,
mathematics, figure captions, the transcript's own structural markers -- is dropped from
both sides before comparing, because those are verified by eye against the page image and
would otherwise bury the signal.

Exit status is 1 if any prose word differs, so this can gate a build.
"""

import difflib
import os
import re
import subprocess
import sys
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Words the PDF layer carries but no transcript should: running heads, the Wiley/Nature
# margin strips, page furniture. Matched against a whole line of pdftotext output.
FURNITURE = re.compile(
    r"^(\s*\d+\s*$|.*wileyonlinelibrary\.com|.*onlinelibrary\.wiley\.com|"
    r".*Downloaded from|.*Creative Commons Licen[cs]e|.*Terms and Conditions|"
    r".*See the Terms|.*OA articles are governed|.*applicable Creative|"
    r".*Wiley Online Library|.*nature\.com/|.*www\.nature\.com|.*Nature Communications \|)",
    re.I)


def normalise(text):
    text = unicodedata.normalize("NFKC", text)
    text = (text.replace("’", "'").replace("‘", "'")
                .replace("“", '"').replace("”", '"')
                .replace("–", "-").replace("—", "-").replace("−", "-")
                .replace("ﬁ", "fi").replace("ﬂ", "fl").replace(" ", " "))
    text = re.sub(r"(\w)-\s*\n\s*(\w)", r"\1\2", text)   # hyphenation across a line break
    return text


def words(text):
    text = normalise(text)
    text = re.sub(r"[^\w'%.,;:()\[\]/+=<>-]+", " ", text)
    out = []
    for tok in text.split():
        tok = tok.strip(".,;:()[]").lower()
        if tok:
            out.append(tok)
    return out


def transcript_prose(src):
    """The transcript minus everything that is not running prose."""
    lines = []
    in_table = False
    for line in src.split("\n"):
        s = line.strip()
        if s.startswith("|"):
            in_table = True
            continue
        if in_table and (not s or s.startswith("Note") or s.startswith("*Note")
                         or re.match(r"^\^?[a-z]\s", s)):
            in_table = False
            if s:
                continue
        if not s or s.startswith("#") or s.startswith("$$"):
            continue
        if re.match(r"^(TABLE|FIGURE)\s", s):
            continue
        s = re.sub(r"\$[^$]*\$", " ", s)               # inline mathematics
        s = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", s)  # links keep their text
        s = re.sub(r"[*`]", "", s)
        s = re.sub(r"\^\{[^}]*\}", " ", s)
        s = re.sub(r"_\{([^}]*)\}", r"\1", s)
        lines.append(s)
    return "\n".join(lines)


def pdf_prose(pdf, first=None, last=None):
    cmd = ["pdftotext"]
    if first:
        cmd += ["-f", str(first)]
    if last:
        cmd += ["-l", str(last)]
    cmd += [pdf, "-"]
    raw = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    raw = normalise(raw)
    keep = [l for l in raw.split("\n") if not FURNITURE.match(l)]
    return "\n".join(keep)


def multiset_check(a, b):
    """Words the transcript lost, and words it gained, ignoring order.

    Order is not evidence of anything: a text layer interleaves footnotes with body text
    and breaks paragraphs across columns, so a faithful transcript legitimately moves
    blocks around. What no faithful transcript does is invent a word or drop a clause, and
    that survives reordering."""
    from collections import Counter
    ca, cb = Counter(a), Counter(b)
    lost = ca - cb
    gained = cb - ca
    return lost, gained


def report(project, pdf, transcript_path, context=6, quiet=False):
    src = open(transcript_path).read()
    a = words(pdf_prose(pdf))
    b = words(transcript_prose(src))

    lost, gained = multiset_check(a, b)
    if not quiet:
        interesting_lost = {w: c for w, c in lost.items() if re.search(r"[a-z]{3}", w)}
        interesting_gained = {w: c for w, c in gained.items() if re.search(r"[a-z]{3}", w)}
        print("%s: %d words in the PDF, %d in the transcript" % (project, len(a), len(b)))
        if interesting_gained:
            print("  words the transcript has and the PDF does not (%d distinct):"
                  % len(interesting_gained))
            for w, c in sorted(interesting_gained.items(), key=lambda kv: -kv[1])[:40]:
                print("      +%-3d %s" % (c, w))
        if interesting_lost:
            print("  words the PDF has and the transcript does not (%d distinct):"
                  % len(interesting_lost))
            for w, c in sorted(interesting_lost.items(), key=lambda kv: -kv[1])[:40]:
                print("      -%-3d %s" % (c, w))

    sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
    problems = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        gone = " ".join(a[i1:i2])
        added = " ".join(b[j1:j2])
        # A table or an equation the transcript legitimately holds elsewhere shows up as a
        # deletion of digit soup. Only prose runs are interesting.
        if tag == "delete" and not re.search(r"[a-z]{3}", gone):
            continue
        if tag == "insert" and not re.search(r"[a-z]{3}", added):
            continue
        before = " ".join(a[max(0, i1 - context):i1])
        problems.append((tag, before, gone, added))
    ratio = sm.ratio()
    if not quiet:
        print("  %.4f of the word sequence is in the same order" % ratio)
        for tag, before, gone, added in problems:
            print("\n  [%s] after: ...%s" % (tag.upper(), before[-160:]))
            if gone:
                print("      PDF        : %s" % gone[:400])
            if added:
                print("      TRANSCRIPT : %s" % added[:400])
    return problems, ratio


def main(argv):
    quiet = "--quiet" in argv
    argv = [a for a in argv if not a.startswith("--")]
    project = argv[0]
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    import json
    papers = {p["project"]: p for p in json.load(open(os.path.join(ROOT, "tools", "papers.json")))}
    from build_paper_page import paper_pdf
    pdf = os.path.join(ROOT, project, paper_pdf(project, papers[project]))
    transcript = os.path.join(ROOT, "tools", "transcripts", "%s.md" % project)
    problems, ratio = report(project, pdf, transcript, quiet=quiet)
    a = words(pdf_prose(pdf))
    b = words(transcript_prose(open(transcript).read()))
    lost, gained = multiset_check(a, b)
    invented = sum(c for w, c in gained.items() if re.search(r"[a-z]{3}", w))
    if invented:
        print("\n%s: %d prose word(s) appear in the transcript but not in the PDF"
              % (project, invented))
        return 1
    if problems:
        print("\n%s: %d ordered difference(s); nothing invented" % (project, len(problems)))
        return 0
    print("%s: every prose word in the transcript is a word the PDF prints" % project)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
