#!/usr/bin/env python3
"""Check a transcript against the words the PDF actually contains.

    python3 tools/verify_transcript.py <project> [--context N] [--quiet]

A transcript is prose lifted from a published paper. What this catches, and gates on, is
prose the transcript has that the paper does not: an invented sentence, a reworded clause, a
duplicated block. That direction is decidable, because a word absent from both extractions
of the PDF was not in the paper.

The other direction is not symmetric and this tool does not pretend to decide it. A word the
PDF has and the transcript does not is usually a table cell, an axis label, a running head or
a fragment of mathematics -- all of which the transcript legitimately holds elsewhere or not
at all. Those are reported, and worth reading, but they do not fail the command. For how far
a missing SECTION can be detected, see the coverage measure in tools/check_paper_pages.py,
which is a proportion, not a proof.

This strips the transcript back to a bare word sequence, does the same to `pdftotext`
output, and diffs the two. Everything that is legitimately not body prose -- table cells,
mathematics, figure captions, the transcript's own structural markers -- is dropped from
both sides before comparing, because those are verified by eye against the page image and
would otherwise bury the signal.

Exit status is 1 when the transcript contains prose the PDF does not, so that can gate a
build. Words missing in the other direction are reported without failing.
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
                .replace("‐", "-").replace("‑", "-").replace("‒", "-")
                .replace("\u00ad", "")            # soft hyphen, left inside words by some PDFs
                .replace("ﬁ", "fi").replace("ﬂ", "fl").replace(" ", " "))
    text = re.sub(r"(\w)-\s*\n\s*(\w)", r"\1\2", text)   # hyphenation across a line break
    return text


def words(text):
    """Letters-and-digits runs, lowercased.

    Punctuation is dropped rather than trimmed, because it is where the false alarms live:
    a superscript citation makes the PDF read "Pratt).3" against the transcript's "Pratt).",
    and any rule that trims edges keeps one of those and not the other. What is being
    checked is which words are present, so the punctuation between them is noise."""
    text = normalise(text)
    # Hyphens are removed rather than kept or split on. A line break inside "meta-analysis"
    # is rejoined by dehyphenation as "metaanalysis" on the PDF side while the transcript
    # keeps "meta-analysis"; with hyphens gone both read the same, which retires a whole
    # class of false alarm without hiding any real one.
    text = text.replace("-", "")
    return [t.lower() for t in re.findall(r"[A-Za-z0-9]+(?:'[A-Za-z]+)?", text)]


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
    """The paper's words, extracted the same way the draft was.

    This must use the column-aware path: in a plain extraction the publisher's rights
    strip lands on the same line as body text, and dropping the strip then silently drops
    the sentence it was sitting next to -- which makes the gate report the transcript as
    having invented the words it faithfully kept."""
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    from draft_transcript import pdftotext, uncolumn, strip_furniture
    pages = pdftotext(pdf).split("\f")
    if first or last:
        pages = pages[(first or 1) - 1:(last or len(pages))]
    pages = strip_furniture([uncolumn(p) for p in pages])
    raw = normalise("\n\n".join(pages))
    keep = [l for l in raw.split("\n") if not FURNITURE.match(l)]
    return "\n".join(keep)


def joined_runs(tokens, upto=3):
    """Every run of two or three consecutive words, concatenated.

    Some text layers break a word apart -- "Anglo-\u00adS axon" for "Anglo-Saxon", "1- day"
    for "1-day" -- so the paper's own word is present only as two or three fragments in a
    row. A transcript word that is exactly such a run is the paper's word, not a new one."""
    out = set()
    for n in range(2, upto + 1):
        for i in range(len(tokens) - n + 1):
            out.add("".join(tokens[i:i + n]))
    return out


def pdf_counts(pdf):
    """How many times the PDF contains each word, taking the best of both extractions.

    Layout-preserving extraction is what the draft is built from, because it is the only
    mode that shows where the columns are. But on a page carrying a wide table it silently
    drops running text: a sentence printed on page 10 of the social-cost-of-carbon paper is
    absent from the layout extraction and present in the plain one. Trusting either mode
    alone therefore means either inventing accusations against a faithful transcript, or --
    worse -- failing to notice a paragraph the transcript really did drop.

    Counts are the element-wise maximum rather than the sum, so a word stays as frequent as
    the paper actually prints it, and a word in neither extraction is still invented."""
    from collections import Counter
    lay_tokens = words(pdf_prose(pdf))
    plain_tokens = words(normalise(subprocess.run(
        ["pdftotext", pdf, "-"], capture_output=True, text=True, check=True).stdout))
    layout, plain = Counter(lay_tokens), Counter(plain_tokens)
    best = Counter()
    for w in set(layout) | set(plain):
        best[w] = max(layout[w], plain[w])
    best.joined = joined_runs(lay_tokens) | joined_runs(plain_tokens)
    return best


def multiset_check(a, b):
    """Words the transcript lost, and words it gained, ignoring order.

    Order is not evidence of anything: a text layer interleaves footnotes with body text
    and breaks paragraphs across columns, so a faithful transcript legitimately moves
    blocks around. What no faithful transcript does is invent a word or drop a clause, and
    that survives reordering.

    One artefact is discounted, because it fires on nearly every paper and always in the
    transcript's favour: a text layer glues a superscript to the word beside it, storing
    "Havranek^c" as "havranekc" and "^bLSE" as "blse". A transcript word that appears
    inside a PDF word with a letter or two stuck on is that word, not an invented one."""
    from collections import Counter
    ca = a if isinstance(a, Counter) else Counter(a)
    cb = b if isinstance(b, Counter) else Counter(b)
    lost = ca - cb
    gained = cb - ca
    glued = set()
    runs = getattr(ca, "joined", set())
    for w in gained:
        if len(w) < 4:
            continue
        if w in runs:                      # the paper's word, broken apart by the text layer
            glued.add(w)
            continue
        for t in ca:
            if len(t) - len(w) in (1, 2) and (t.endswith(w) or t.startswith(w)):
                glued.add(w)
                break
    for w in glued:
        del gained[w]
    return lost, gained


def report(project, pdf, transcript_path, context=6, quiet=False):
    src = open(transcript_path).read()
    a = words(pdf_prose(pdf))
    b = words(transcript_prose(src))

    lost, gained = multiset_check(pdf_counts(pdf), b)
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
    b = words(transcript_prose(open(transcript).read()))
    lost, gained = multiset_check(pdf_counts(pdf), b)
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
