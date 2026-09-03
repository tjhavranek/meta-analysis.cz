#!/usr/bin/env python3
"""Find prose the PDF has and the transcript does not.

    python3 tools/audit_dropped_text.py [--min 8] [--json <path>] [<project> ...]

The fidelity gate asks whether the page says anything the paper does not. It cannot ask the
opposite question, because a transcript legitimately leaves out a great deal: running heads,
page numbers, table bodies rendered separately, reference-list formatting. So a clause that
falls out mid-sentence at a page break is invisible to it, and one did:

    the PDF   "Panel (b) in Figure 3 suggests that, for the literature on the beauty
               effect, the funnel plot is not symmetrical. Large imprecise estimates are
               much more common than small..."
    the page  "Panel (b) in Large imprecise estimates are much more common than small..."

Nothing was invented, the word counts barely moved, and every existing check passed.

This aligns the two word sequences and reports runs the transcript dropped. Noise is
expected -- headers, folios, table cells -- so it filters to runs that begin and end inside
running prose, which is where a dropped clause does its damage. Read what it prints; it is a
list of places to look, not a list of defects.
"""

import difflib
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

from build_paper_page import (documents, page_dir,             # noqa: E402
                              transcript_pdf_paths)
from verify_transcript import transcript_prose                 # noqa: E402
import _poppler

PAPERS = {p["project"]: p for p in
          json.load(open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
PAPERS.update(documents())
TRANSCRIPTS = os.path.join(ROOT, "tools", "transcripts")

WORD = re.compile(r"[A-Za-z][A-Za-z'-]*")


STOP = set("""a an the of and or in to for on at by with from that this those these is are
was were be been being it its as not but if than then so such which who whom whose we our
us they their them he she his her you your i""".split())
FURNITURE = re.compile(r"\b(issn|copyright|http|www|doi|e-?mail|phone|fax|reserved|"
                       r"downloaded|jstor|elsevier|springer|wiley|volume|pp)\b")


def reads_as_prose(run):
    """Whether a dropped run is running English rather than furniture, references or maths.

    A reference list, a journal's copyright block and a line of algebra all show up as
    "missing" because the transcript never carried them, and they made up the great bulk of
    what the alignment reported. Ordinary prose is roughly a third function words; a
    bibliography is almost none, and algebra is single letters.
    """
    if len(run) < 6:
        return False
    text = " ".join(run)
    if FURNITURE.search(text):
        return False
    if sum(1 for w in run if len(w) == 1) > 0.25 * len(run):
        return False
    return (sum(1 for w in run if w in STOP) / len(run)) >= 0.22


def splices(raw, before, after):
    """True when the transcript joins these two phrases with no sentence boundary.

    Both sides are word lists taken from the alignment, so they are matched back against
    the real text allowing any punctuation between words. What is then examined is the
    join itself: a full stop, question mark, colon or a paragraph break there means the
    gap fell between two sentences and the transcript simply does not carry what is
    missing. Anything else means a sentence was cut in half.
    """
    if not before or not after:
        return False
    pat = r"\W+".join(re.escape(w) for w in before.split()[-4:])
    pat += r"(?P<join>\W{0,12})"
    pat += r"\W*".join([""] + [re.escape(w) for w in after.split()[:3]])
    m = re.search(pat, raw, re.I)
    if not m:
        return False
    return not re.search(r"[.!?:;]|\n\s*\n", m.group("join"))


FLOAT = re.compile(r"^\s*(table|figure|fig\.|appendix|notes?|source|panel|references|"
                   r"acknowledg|supplementary|keywords|jel|annex)\b", re.I)


def is_float(verbatim):
    """Whether a block is a table or figure the transcript renders in its own right.

    These dominate what the block channel reports and none of them is a defect: a table's
    body is not prose the page lost, it is prose the page never carried as prose. Two marks
    give them away -- the paper's own label at the start of the block, and a density of
    numbers no paragraph reaches.
    """
    if FLOAT.match(verbatim):
        return True
    toks = verbatim.split()
    return bool(toks) and sum(1 for t in toks if re.search(r"\d", t)) > 0.18 * len(toks)


def elsewhere(flat, run):
    """Whether this run is in the transcript after all, somewhere the alignment did not look.

    A transcript does not follow the PDF's reading order: it gathers footnotes into endnotes
    and moves a table out of the middle of a paragraph. The alignment is a single pass, so
    anything moved reads as deleted here and inserted there, and every large block it
    reported this way turned out to be present -- an entire section of /incentives/ among
    them. Taking a phrase from the middle of the run and looking for it in the whole
    transcript settles it: found means moved, not lost.
    """
    if len(run) < 12:
        return False
    mid = len(run) // 2
    probe = " ".join(run[max(0, mid - 6):mid + 6])
    return probe in flat


def pdf_words(pdfs):
    """Lower-cased words, plus the source text and each word's offset into it.

    The offsets are what make a repair possible: the alignment works on bare words, but
    what has to go back into the transcript is the paper's own sentence, with its capitals,
    its commas and its full stop. Slicing the original text between two offsets gives
    exactly that, so nothing is ever retyped from memory.
    """
    words, spans, whole = [], [], []
    base = 0
    for f in pdfs:
        txt = subprocess.run([_poppler.tool("pdftotext"), f, "-"], capture_output=True,
                             encoding="utf-8", errors="replace").stdout or ""
        for m in WORD.finditer(txt):
            words.append(m.group(0).lower())
            spans.append((base + m.start(), base + m.end()))
        whole.append(txt)
        base += len(txt)
    return words, spans, "".join(whole)


def audit(project, minrun):
    meta = PAPERS[project]
    tr = os.path.join(TRANSCRIPTS, "%s.md" % project)
    if not os.path.exists(tr):
        return None
    pdfs = transcript_pdf_paths(project, meta)
    if not pdfs:
        return None
    a, spans, src = pdf_words(pdfs)
    raw = transcript_prose(open(tr, encoding="utf-8").read())
    b = [w.lower() for w in WORD.findall(raw)]
    if not a or not b:
        return None
    flat = " ".join(b)
    sm = difflib.SequenceMatcher(a=a, b=b, autojunk=False)
    hits, blocks = [], []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag not in ("delete", "replace") or (i2 - i1) < minrun:
            continue
        # Only report a gap that opens INSIDE running prose: the transcript's words on
        # both sides of it are ordinary text. A gap at the edge of a table or a reference
        # list is the transcript leaving out something it never carried.
        before = " ".join(b[max(0, j1 - 6):j1])
        after = " ".join(b[j1:j1 + 6])
        if len(before.split()) < 4 or len(after.split()) < 4:
            continue
        run = a[i1:i2]
        # A whole section, table or reference list is not what this is for: the transcript
        # renders tables as tables and drops page furniture on purpose, so those are
        # expected and huge. What matters is a CLAUSE lost mid-sentence.
        if (i2 - i1) > 60:
            # Too big to be a lost clause, but a lost PARAGRAPH looks exactly like this and
            # would otherwise never be reported. It cannot be found by the splice test,
            # because a whole paragraph goes missing between two complete sentences. So it
            # is collected separately, on the weaker evidence that it reads as prose, and
            # reported for a human to look at rather than repaired.
            v = re.sub(r"\s+", " ", src[spans[i1][0]:spans[i2 - 1][1]]).strip()
            if (reads_as_prose(a[i1:i2]) and not elsewhere(flat, a[i1:i2])
                    and not is_float(v)):
                blocks.append({"n": i2 - i1, "before": before, "after": after,
                               "verbatim": v})
            continue
        # The test that separates damage from an intended omission: does the transcript
        # now run the two sides together WITHOUT a sentence boundary? "Panel (b) in" +
        # "Large imprecise estimates..." is a splice. A gap that falls between two whole
        # sentences is the transcript leaving out something it never carried.
        if not reads_as_prose(run):
            continue
        if not splices(raw, before, after):
            continue
        # the paper's own words, with punctuation and capitals, ready to put back
        verbatim = src[spans[i1][0]:spans[i2 - 1][1]]
        verbatim = re.sub(r"\s+", " ", verbatim).strip()
        hits.append({"n": i2 - i1, "dropped": " ".join(run)[:200], "verbatim": verbatim,
                     "before": before, "after": after})
    hits.sort(key=lambda h: -h["n"])
    blocks.sort(key=lambda h: -h["n"])
    return {"project": project, "pdf_words": len(a), "transcript_words": len(b),
            "hits": hits, "blocks": blocks}


def main(argv):
    minrun, jpath = 8, None
    if "--min" in argv:
        i = argv.index("--min"); minrun = int(argv[i + 1]); argv = argv[:i] + argv[i + 2:]
    if "--json" in argv:
        i = argv.index("--json"); jpath = argv[i + 1]; argv = argv[:i] + argv[i + 2:]
    projects = argv or sorted(p for p in PAPERS
                              if os.path.exists(os.path.join(TRANSCRIPTS, "%s.md" % p)))
    out, total, big = [], 0, 0
    for p in projects:
        try:
            r = audit(p, minrun)
        except Exception as exc:
            print("%-22s ERROR %s" % (p, str(exc)[:60]))
            continue
        if not r or not (r["hits"] or r["blocks"]):
            continue
        out.append(r)
        total += len(r["hits"])
        big += len(r["blocks"])
    out.sort(key=lambda r: -len(r["hits"]))
    print("%d paper(s) with a dropped run of %d+ words inside prose; %d run(s) total\n"
          % (len(out), minrun, total))
    for r in out:
        print("%-22s %d" % (r["project"], len(r["hits"])))
        for h in r["hits"][:3]:
            print("     %d words missing between %r and %r" % (h["n"], h["before"][-46:],
                                                               h["after"][:46]))
            print("        dropped: %s" % h["dropped"][:150])
    if big:
        print("\n%d block(s) of 60+ words that read as prose, for a human to look at.\n"
              "A lost clause splices two sentences and can be repaired mechanically; a lost\n"
              "PARAGRAPH falls between two whole sentences and cannot, so these are only\n"
              "reported. Most are legitimate: an abstract the page carries once, a footnote,\n"
              "a table note. Read them against the transcript before concluding anything.\n"
              % big)
        for r in out:
            for h in r["blocks"][:3]:
                print("%-22s %d words between %r and %r" % (r["project"], h["n"],
                                                            h["before"][-40:], h["after"][:40]))
                print("        %s" % h["verbatim"][:160])
    if jpath:
        json.dump(out, open(jpath, "w", encoding="utf-8"), indent=1)
        print("\nwritten to %s" % jpath)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
