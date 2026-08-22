#!/usr/bin/env python3
"""Draft a transcript mechanically from a paper's own text layer.

    python3 tools/draft_transcript.py <project> [--pages 1-12] [--force]

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


def pdftotext(pdf, layout=False):
    cmd = ["pdftotext"] + (["-layout"] if layout else []) + [pdf, "-"]
    return subprocess.run(cmd, capture_output=True, text=True, check=True).stdout


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
            if re.fullmatch(r"\d{1,4}", s):                       # a page number alone
                continue
            if re.fullmatch(r"[|]?\s*\d{1,4}\s*[|]?", s):
                continue
            # the vertical rights strip comes out as one very long unspaced run
            if len(s) > 120 and " " not in s[:60]:
                continue
            keep.append(line)
        out.append("\n".join(keep))
    return out


def dehyphenate(text):
    return re.sub(r"(\w)[-‐‑]\s*\n\s*([a-z])", r"\1\2", text)


def paragraphs(text):
    """Reflow lines into paragraphs. A new paragraph starts at a blank line, at an indent,
    or after a line that ended a sentence and left the measure short."""
    lines = text.split("\n")
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


def draft(project, page_range=None):
    import json
    from build_paper_page import paper_pdf
    papers = {p["project"]: p for p in json.load(open(os.path.join(ROOT, "tools", "papers.json")))}
    meta = papers[project]
    rel = paper_pdf(project, meta)
    pdf = os.path.join(ROOT, project, rel)

    raw = pdftotext(pdf)
    pages = raw.split("\f")
    if page_range:
        first, last = page_range
        pages = pages[first - 1:last]
    pages = strip_furniture(pages)
    body = dehyphenate("\n\n".join(pages))

    out = ["# %s" % meta.get("title", project),
           "",
           "<!-- Drafted from %s by tools/draft_transcript.py. The prose is the PDF's own text" % rel,
           "     layer, unedited. Every <<...>> marker is work for a reader of the page image:",
           "     fill it in, then delete the marker. Run tools/verify_transcript.py when done. -->",
           ""]
    n_tables = n_figs = n_eqs = 0
    for para in paragraphs(body):
        kind, payload = classify(para, False)
        if kind == "table":
            num, cap = payload
            n_tables += 1
            out += ["TABLE %s. %s" % (num, cap),
                    "<<TABLE %s: replace this line with the pipe table, read off the page image>>"
                    % num, ""]
        elif kind == "figure":
            num, cap = payload
            n_figs += 1
            out += ["FIGURE %s. %s" % (num, cap),
                    "<<FIGURE %s: check the caption above is complete; extract the artwork with "
                    "tools/extract_figure.py>>" % num, ""]
        elif kind == "equation":
            n_eqs += 1
            m = EQ_TAIL_RE.search(payload)
            num = m.group(1) if m else ""
            out += ["<<EQUATION%s from the text layer: %s>>" % (" " + num if num else "", payload),
                    "$$ %s $$%s" % ("\\text{TODO}", " (%s)" % num if num else ""), ""]
        elif kind == "heading":
            num, text = payload
            level = "###" if (num and num.count(".") >= 1) else "##"
            out += ["%s %s" % (level, ("%s | %s" % (num, text)) if num else text), ""]
        elif kind == "backmatter":
            out += ["## %s" % payload, ""]
        else:
            out += [payload, ""]

    path = os.path.join(ROOT, "tools", "transcripts", "%s.draft.md" % project)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        fh.write("\n".join(out).rstrip() + "\n")
    print("%-22s %s -> %s  (%d tables, %d figures, %d equations to fill)"
          % (project, rel, os.path.relpath(path, ROOT), n_tables, n_figs, n_eqs))
    return path


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    rng = None
    for a in sys.argv[1:]:
        if a.startswith("--pages"):
            val = a.split("=", 1)[1] if "=" in a else sys.argv[sys.argv.index(a) + 1]
            first, last = val.split("-")
            rng = (int(first), int(last))
    for project in args:
        draft(project, rng)
