#!/usr/bin/env python3
"""Draft a transcript mechanically from a paper's own text layer.

    python3 tools/draft_transcript.py <project> [--pages 1-12] [--out PATH]

Writes tools/transcripts/<project>.draft.md.

The prose in a published paper is already inside the PDF as characters. Retyping it, by a
person or by a model, can only lose fidelity; so this lifts it verbatim and spends
attention on the parts a text layer genuinely cannot carry:

  * running heads, page numbers and the publisher's margin strip, which are removed by
    finding the lines that repeat across pages rather than by guessing at their wording;
  * hyphenation at line ends and paragraph reflow, which are undone by rule;
  * headings, which are proposed from numbering and case and marked for review;
  * tables, equations and figures, which come out of a text layer scrambled, and are cut
    out and replaced by a placeholder for a reader of the page image to fill in.

What it emits is a draft: every placeholder is a question addressed to whoever finishes
it. What it guarantees is that the prose between the placeholders is the paper's own,
character for character, which is what tools/verify_transcript.py later checks.
"""

import os
import re
import subprocess
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

CAPTION_RE = re.compile(
    r"^\s*(T\s?A\s?B\s?L\s?E|TABLE|Table|F\s?I\s?G\s?U\s?R\s?E|FIGURE|Figure|Fig\.)\s*"
    r"([0-9]+[A-Za-z]?)\s*[.:]?\s*(.*)$")
# A numbered section heading: "3 | METHOD", "3.2 Reducing bias", "IV. Results"
HEADING_RE = re.compile(r"^\s*(\d+(?:\.\d+)*)\s*[|.]?\s+([A-Z][^.]{2,80})\s*$")
CAPS_HEADING_RE = re.compile(r"^\s*([A-Z][A-Z\s&'-]{3,60})\s*$")
BACKMATTER = ("REFERENCES", "References", "ACKNOWLEDGEMENTS", "ACKNOWLEDGMENTS",
              "Acknowledgements", "Acknowledgments", "APPENDIX", "Appendix",
              "ENDNOTES", "ENDNOTE", "Notes", "NOTES", "AUTHOR CONTRIBUTIONS",
              "DATA AVAILABILITY STATEMENT", "CONFLICT OF INTEREST STATEMENT",
              "SUPPORTING INFORMATION", "ORCID", "AUTHOR BIOGRAPHIES", "Bibliography")
EQ_TAIL_RE = re.compile(r"\(\s*(\d{1,2}[a-z]?)\s*\)\s*$")
MATHY = re.compile(r"[=∑√∫±≤≥≈∼×·⋅αβγδεθλμπρστφχψωΓΔΘΛΣΦΨΩ]|\b(?:ln|log|exp|max|min)\b")


def pdftotext(pdf, layout=True):
    cmd = ["pdftotext"] + (["-layout"] if layout else []) + [pdf, "-"]
    return subprocess.run(cmd, capture_output=True, text=True, check=True).stdout


def find_gutter(lines, min_share=0.80):
    """The column gap of a two-column page, as a (start, end) character range.

    In a layout-preserving extraction the gutter is the band of character positions that
    is blank on nearly every line of the page. Finding it by counting blanks means no page
    geometry has to be assumed, and a single-column page simply has no such band near the
    middle."""
    body = [l for l in lines if l.strip()]
    if len(body) < 12:
        return None
    # The publisher's vertical rights strip comes out as one enormously long line. Left in,
    # it triples the apparent width of the page and the real gutter stops looking central.
    lengths = sorted(len(l) for l in body)
    median = lengths[len(lengths) // 2]
    body = [l for l in body if len(l) <= max(90, int(median * 1.4))]
    if len(body) < 12:
        return None
    width = max(len(l) for l in body)
    if width < 60:
        return None
    blank = [sum(1 for l in body if pos >= len(l) or l[pos] == " ") for pos in range(width)]
    need = min_share * len(body)
    bands, run = [], None
    for pos, count in enumerate(blank):
        if count >= need:
            run = (run[0], pos) if run else (pos, pos)
        else:
            if run:
                bands.append(run)
            run = None
    if run:
        bands.append(run)
    # The right margin is a blank band too, and usually a wider one, so centrality is the
    # test and width only decides between candidates that pass it.
    central = [(a, b) for a, b in bands
               if 0.30 * width < (a + b) / 2 < 0.70 * width and b - a >= 2]
    if not central:
        return None
    return max(central, key=lambda ab: ab[1] - ab[0])


def uncolumn(page):
    """Put a two-column page back into reading order: all of the left column, then all of
    the right. Lines that span the page -- a full-width title, a table across the measure --
    are emitted where they stand, which keeps the zones around them in order.

    Every line is cut in exactly one place and both halves are kept, so no character can be
    lost in the gutter. The result is checked against the input before it is returned; if
    anything went missing the page is handed back untouched, because a page in the wrong
    order can be fixed by a reader and a page with a sentence deleted cannot."""
    lines = page.split("\n")
    gutter = find_gutter(lines)
    if not gutter:
        return page
    start, end = gutter
    lo, hi = max(0, start - 8), end + 9
    out, left, right = [], [], []

    def flush():
        if left or right:
            out.extend(left)
            out.append("")
            out.extend(right)
            out.append("")
        left.clear()
        right.clear()

    for line in lines:
        # Text does not respect the gutter exactly: a long word or a display equation
        # bleeds a character or two across it, so the cut goes at the widest run of spaces
        # near the gutter rather than at the gutter itself.
        window = line[lo:hi]
        gaps = [(m.end() - m.start(), m.start(), m.end())
                for m in re.finditer(r" {2,}", window)]
        if not gaps:
            if line[start:end + 1].strip() and line[:start].strip() and line[end + 1:].strip():
                flush()
                out.append(line)          # genuinely spans the measure
                continue
            cut = start if not line[start:end + 1].strip() else end + 1
        else:
            _, gs, ge = max(gaps)
            cut = lo + (gs + ge) // 2
        l, r = line[:cut].rstrip(), line[cut:].rstrip()
        if l.strip():
            left.append(l)
        elif not r.strip():
            left.append("")
        if r.strip():
            right.append(r)
    flush()
    result = "\n".join(out)
    if sorted(result.split()) != sorted(page.split()):
        return page
    return result


def strip_furniture(pages):
    """Drop the lines that repeat across pages: running heads, the journal's margin strip,
    bare page numbers. Found by counting, so no publisher needs to be named."""
    counts = Counter()
    for page in pages:
        for line in set(l.strip() for l in page.split("\n") if l.strip()):
            counts[line] += 1
    threshold = max(3, len(pages) // 3)
    repeated = {l for l, c in counts.items() if c >= threshold and len(l) < 200}
    out = []
    for page in pages:
        keep = []
        for line in page.split("\n"):
            s = line.strip()
            if not s:
                keep.append("")
                continue
            if s in repeated:
                continue
            if re.fullmatch(r"[|]?\s*\d{1,4}\s*[|]?", s):      # a page number alone
                continue
            # the vertical rights strip comes out as one very long unspaced run
            if len(s) > 120 and " " not in s[:60]:
                continue
            keep.append(line)
        out.append("\n".join(keep))
    return out


def dehyphenate(text):
    return re.sub(r"(\w)[-‐‑]\s*\n\s*([a-z])", r"\1\2", text)


def double_spaced(lines):
    """True when the extraction separates every line of prose with a blank one.

    Some PDFs -- typically LaTeX single-column ones -- come out of pdftotext with a blank
    line after each line of text and no indentation. Treating those blanks as paragraph
    breaks turns every line into its own paragraph, which is what the beauty paper's page
    looked like: a hundred one-line paragraphs where the paper has prose."""
    body = [i for i, l in enumerate(lines) if l.strip()]
    if len(body) < 20:
        return False
    singles = sum(1 for a, b in zip(body, body[1:]) if b - a == 2)
    return singles / max(1, len(body) - 1) > 0.6


def paragraphs(text):
    """Reflow lines into paragraphs. A new paragraph starts at a blank line, at an indent,
    or after a line that ended a sentence and left the measure short."""
    lines = text.split("\n")
    if double_spaced(lines):
        # Blank lines carry no information here, so paragraph boundaries come from the shape
        # of the text: a paragraph's last line ends a sentence and stops short of the measure.
        kept = [l for l in lines if l.strip()]
        measure = sorted(len(l.strip()) for l in kept)[len(kept) // 2] if kept else 0
        paras, buf = [], []
        for line in kept:
            t = line.strip()
            if buf:
                prev = buf[-1]
                if re.search(r"[.!?]['\"\u201d)]?$", prev) and len(prev) < 0.92 * measure:
                    paras.append(" ".join(buf))
                    buf = []
            buf.append(t)
        if buf:
            paras.append(" ".join(buf))
        return [re.sub(r"\s{2,}", " ", p).strip() for p in paras if p.strip()]
    paras, buf = [], []
    for i, raw in enumerate(lines):
        line = raw.rstrip()
        s = line.strip()
        if not s:
            if buf:
                paras.append(" ".join(buf))
                buf = []
            continue
        indented = len(line) - len(line.lstrip()) >= 3
        prev = buf[-1] if buf else ""
        starts_new = indented and buf and re.search(r"[.!?)\"']$", prev.strip())
        if starts_new:
            paras.append(" ".join(buf))
            buf = []
        buf.append(s)
    if buf:
        paras.append(" ".join(buf))
    return [re.sub(r"\s{2,}", " ", p).strip() for p in paras if p.strip()]


def classify(para, seen_backmatter):
    """What kind of block is this? Returns (kind, payload)."""
    s = para.strip()
    m = CAPTION_RE.match(s)
    if m and len(s) < 600:
        kind = "table" if m.group(1).replace(" ", "").upper().startswith("T") else "figure"
        return kind, (m.group(2), m.group(3).strip())
    for word in BACKMATTER:
        if s == word or s.upper() == word.upper():
            return "backmatter", s
    m = HEADING_RE.match(s)
    if m and len(s) < 90:
        return "heading", (m.group(1), m.group(2).strip())
    if CAPS_HEADING_RE.match(s) and len(s) < 70 and not s.endswith("."):
        return "heading", (None, s.strip())
    if EQ_TAIL_RE.search(s) and len(s) < 300 and (MATHY.search(s) or len(s.split()) < 14):
        return "equation", s
    if len(s) < 200 and MATHY.search(s) and len(s.split()) < 12 and not s.endswith("."):
        return "equation", s
    return "prose", s


def draft(project, page_range=None, out=None):
    import json
    from build_paper_page import pdf_path
    papers = {p["project"]: p for p in json.load(open(os.path.join(ROOT, "tools", "papers.json")))}
    from build_paper_page import documents
    papers.update(documents())
    meta = papers[project]
    pdf = pdf_path(project, meta)
    rel = os.path.relpath(pdf, ROOT)

    raw = pdftotext(pdf)
    pages = raw.split("\f")
    plain_pages = pdftotext(pdf, layout=False).split("\f")
    if page_range:
        first, last = page_range
        pages = pages[first - 1:last]
        plain_pages = plain_pages[first - 1:last]
        page_offset = first
    else:
        page_offset = 1
    # Layout mode is the only extraction that shows where the columns are, and on a page
    # carrying a wide table it silently drops running text. Say so, per page, rather than
    # let the omission travel silently into the transcript.
    from verify_transcript import words as _norm_words
    dropped = []
    for k, (lay, plain) in enumerate(zip(pages, plain_pages)):
        # Compare after the columns are split and hyphenation is undone. Before that, a word
        # hyphenated at the end of a left-column line is followed on the same physical line by
        # right-column text and can never rejoin, so half the vocabulary looks lost.
        seen = {w for w in _norm_words(dehyphenate(uncolumn(lay))) if len(w) >= 4}
        lost = sorted({w for w in _norm_words(plain) if len(w) >= 4} - seen)
        if len(lost) >= 3:
            dropped.append((page_offset + k, len(lost), " ".join(lost[:12])))
    pages = [uncolumn(p) for p in pages]
    pages = strip_furniture(pages)
    body = dehyphenate("\n\n".join(pages))

    lines_out = ["# %s" % meta.get("title", project),
           "",
           "<!-- Drafted from %s by tools/draft_transcript.py. The prose is the PDF's own text" % rel,
           "     layer, unedited. Every <<...>> marker is work for a reader of the page image:",
           "     fill it in, then delete the marker. Run tools/verify_transcript.py when done. -->",
           ""]
    for pageno, n, sample in dropped:
        lines_out += ["<<TEXT LAYER: page %d prints %d word(s) that the layout extraction does "
                      "not show at all: %s. The sentences they belong to are missing from the "
                      "prose below -- read page %d's image and put them back.>>"
                      % (pageno, n, sample, pageno), ""]
    n_tables = n_figs = n_eqs = 0
    for para in paragraphs(body):
        kind, payload = classify(para, False)
        if kind == "table":
            num, cap = payload
            n_tables += 1
            lines_out += ["TABLE %s. %s" % (num, cap),
                    "<<TABLE %s: replace this line with the pipe table, read off the page image>>"
                    % num, ""]
        elif kind == "figure":
            num, cap = payload
            n_figs += 1
            lines_out += ["FIGURE %s. %s" % (num, cap),
                    "<<FIGURE %s: check the caption above is complete; extract the artwork with "
                    "tools/extract_figure.py>>" % num, ""]
        elif kind == "equation":
            n_eqs += 1
            m = EQ_TAIL_RE.search(payload)
            num = m.group(1) if m else ""
            lines_out += ["<<EQUATION%s from the text layer: %s>>" % (" " + num if num else "", payload),
                    "$$ %s $$%s" % ("\\text{TODO}", " (%s)" % num if num else ""), ""]
        elif kind == "heading":
            num, text = payload
            level = "###" if (num and num.count(".") >= 1) else "##"
            lines_out += ["%s %s" % (level, ("%s | %s" % (num, text)) if num else text), ""]
        elif kind == "backmatter":
            lines_out += ["## %s" % payload, ""]
        else:
            lines_out += [payload, ""]

    path = out or os.path.join(ROOT, "tools", "transcripts", "%s.draft.md" % project)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        fh.write("\n".join(lines_out).rstrip() + "\n")
    print("%-22s %s -> %s  (%d tables, %d figures, %d equations to fill)"
          % (project, rel, os.path.relpath(path, ROOT), n_tables, n_figs, n_eqs))
    return path


if __name__ == "__main__":
    argv = sys.argv[1:]
    skip = set()
    for i, a in enumerate(argv):
        if a in ("--pages", "--out") and i + 1 < len(argv):
            skip.add(i + 1)
    args = [a for i, a in enumerate(argv) if not a.startswith("--") and i not in skip]
    rng = None
    out = None
    for a in sys.argv[1:]:
        if a.startswith("--pages"):
            val = a.split("=", 1)[1] if "=" in a else sys.argv[sys.argv.index(a) + 1]
            first, last = val.split("-")
            rng = (int(first), int(last))
        if a.startswith("--out"):
            out = a.split("=", 1)[1] if "=" in a else sys.argv[sys.argv.index(a) + 1]
    for project in args:
        draft(project, rng, out)
