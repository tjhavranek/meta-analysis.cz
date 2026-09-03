#!/usr/bin/env python3
"""Find terms the paper italicises that the page sets upright.

Italics carry meaning in these papers: a variable name, a method, a Latin abbreviation, the
first use of a term being defined. The PDF text layer does not record them, so a
transcription made from the text layer loses them silently, and no existing check can see
it -- every word is present, in order, and correctly spelled.

Three sources have to agree before anything is reported, because two of them lie in
opposite directions:

  1. the LaTeX marks the phrase \\emph or \\textit          (but it is usually a DRAFT, and
                                                            journals do drop emphasis)
  2. the page has the phrase, and not inside <i>            (the defect, if it is one)
  3. the PUBLISHED PDF sets it in an italic font            (the arbiter)

Only phrases passing all three are printed. Step 3 is what makes this worth running: on its
own, step 1 produces a long list of things the journal deliberately un-emphasised.

Read the output; do not act on it in bulk
-----------------------------------------
Run over the 49 sourced papers it confirms 172 phrases, and acting on them would make the
pages worse. Two reasons, both measured.

Most of the 172 are not lost emphasis at all. They are section headings, run-in labels and
table row headers, which the PDF sets in italic and the page styles its own way:
/price_puzzle/'s "Structural heterogeneity" is a <th scope="row">, not upright prose.

And step 3 asks whether the phrase is italic ANYWHERE in the PDF, which is too coarse for
exactly the phrases that look most promising. Counting the fonts at each occurrence instead:
"et al." is roman 29 times and italic twice in /dst/, roman 187 times and italic 27 in
/sigma/ -- the italic hits are reference lists, and italicising the body would have been
wrong 300 times over. "a priori" in /activism/ is italic 3 times and roman 2; "per se" is
mixed in both /elb/ and /house_prices/. A previous pass had already confirmed "per se"
upright in /habits/.

So: a shortlist for a human reading one paper, never a batch job. Nothing was changed on
the strength of it.

    python tools/audit_lost_emphasis.py <manifest.json> [project]

The manifest is project -> path to a .tex, as written by tools/find_tex_sources.py.
"""

import html as H
import io
import json
import os
import re
import sys
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import fitz

TAG = re.compile(r"<[^>]+>")
EMPH = re.compile(r"[\\](?:emph|textit)\s*\{([^{}]{3,60})\}")
LIG = {"ﬀ": "ff", "ﬁ": "fi", "ﬂ": "fl", "ﬃ": "ffi", "ﬄ": "ffl"}


def squash(t):
    for k, v in LIG.items():
        t = t.replace(k, v)
    t = unicodedata.normalize("NFKD", t)
    t = "".join(c for c in t if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]", "", t.lower())


def pdf_italic_text(pdf):
    """Everything the PDF sets in an italic font, squashed."""
    out = []
    d = fitz.open(pdf)
    for i in range(d.page_count):
        for b in d.load_page(i).get_text("dict")["blocks"]:
            for l in b.get("lines", []):
                for s in l.get("spans", []):
                    f = s.get("font", "")
                    if "Italic" in f or "Oblique" in f or "-It" in f or s.get("flags", 0) & 2:
                        out.append(s["text"])
    d.close()
    return squash(" ".join(out))


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    man = json.load(io.open(argv[1], encoding="utf-8"))
    only = argv[2] if len(argv) > 2 else None
    from build_paper_page import transcript_pdf_paths, documents
    P = {p["project"]: p for p in
         json.load(io.open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    P.update(documents())

    total = 0
    for proj in sorted(man):
        if only and proj != only:
            continue
        page_p = os.path.join(ROOT, proj, "paper", "index.html")
        if proj not in P or not os.path.isfile(page_p):
            continue
        try:
            tex = io.open(man[proj], encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        page = io.open(page_p, encoding="utf-8", errors="replace").read()
        plain = squash(H.unescape(TAG.sub(" ", page)))
        ital = squash(" ".join(re.findall(r"<i>(.*?)</i>", page)))

        cands, seen = [], set()
        for m in EMPH.finditer(tex):
            t = re.sub(r"[\\][a-zA-Z]+\s*", " ", m.group(1)).strip()
            k = squash(t)
            if len(k) < 4 or k in seen:
                continue
            seen.add(k)
            if k in plain and k not in ital:
                cands.append(t)
        if not cands:
            continue
        try:
            pdfs = transcript_pdf_paths(proj, P[proj])
        except Exception:
            continue
        if not pdfs:
            continue
        pit = pdf_italic_text(pdfs[0])
        confirmed = [t for t in cands if squash(t) in pit]
        if confirmed:
            total += len(confirmed)
            print("  %-18s %d confirmed by the PDF (of %d in the source)"
                  % (proj, len(confirmed), len(cands)))
            for t in confirmed[:8]:
                print("        %s" % t[:70])
    print("\n%d phrase(s) italic in the published PDF and upright on the page." % total)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
