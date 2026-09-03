#!/usr/bin/env python3
"""Check that every section heading the PDF prints also appears on the page.

The worst thing a conversion can do is drop a whole section, and it is the thing the
existing gates are weakest at. The fidelity checker measures how much of the paper's
vocabulary the page accounts for, which is a blunt instrument: a paper with a large
supplement can be missing 43% of its long words legitimately, so the threshold sits at 45%
and a single lost section hides comfortably under it.

Headings are a better probe. They are short, distinctive, and a section that is gone takes
its heading with it.

The headings are read out of the PDF by type size: a line noticeably larger than the body,
short enough to be a heading and not a sentence. That over-collects -- running heads,
journal furniture, the odd emphasised phrase -- so a heading is only reported missing when
its words are absent from the page as a sequence, and single-word headings are ignored.

Every hit needs a look. A journal's own running head is not a section, and some papers
genuinely move a section to an online appendix the page does not reproduce.
"""

import glob
import html as H
import io
import json
import os
import re
import statistics
import unicodedata
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import fitz

TAG = re.compile(r"<[^>]+>")
JUNK = re.compile(r"^(table|figure|fig\.|notes?|source|appendix|references|acknowledge)",
                  re.I)


LIG = {"ﬀ": "ff", "ﬁ": "fi", "ﬂ": "fl", "ﬃ": "ffi",
       "ﬄ": "ffl", "ﬅ": "st", "ﬆ": "st"}


def squash(t):
    # PDF text layers carry real ligature codepoints where the page shows "ff"/"fi", and
    # the transcript spells them out. Without folding them, every heading containing
    # "different", "offset" or "find" looks absent and the report is all noise.
    for k, v in LIG.items():
        t = t.replace(k, v)
    t = unicodedata.normalize("NFKD", t)
    t = "".join(c for c in t if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]", "", t.lower())


def main(argv):
    only = argv[1] if len(argv) > 1 else None
    from build_paper_page import transcript_pdf_paths, documents
    P = {p["project"]: p for p in
         json.load(io.open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    P.update(documents())

    bad = 0
    for page in sorted(glob.glob(os.path.join(ROOT, "*", "paper", "index.html"))):
        proj = os.path.basename(os.path.dirname(os.path.dirname(page)))
        if only and proj != only:
            continue
        if proj not in P:
            continue
        try:
            pdfs = transcript_pdf_paths(proj, P[proj])
        except Exception:
            continue
        if not pdfs:
            continue
        hay = squash(H.unescape(TAG.sub(" ", io.open(page, encoding="utf-8",
                                                     errors="replace").read())))
        d = fitz.open(pdfs[0])
        sizes, heads = [], []
        for i in range(d.page_count):
            for b in d.load_page(i).get_text("dict")["blocks"]:
                for l in b.get("lines", []):
                    txt = "".join(s["text"] for s in l.get("spans", [])).strip()
                    if not l.get("spans"):
                        continue
                    sz = max(s["size"] for s in l["spans"])
                    if len(txt) > 25:
                        sizes.append(sz)
                    heads.append((i + 1, sz, txt))
        d.close()
        if not sizes:
            continue
        body = statistics.median(sizes)
        missing = []
        seen = set()
        for pg, sz, txt in heads:
            if sz < body + 0.6 or not (6 < len(txt) < 65):
                continue
            if JUNK.match(txt) or len(txt.split()) < 2:
                continue
            k = squash(txt)
            if not k or k in seen:
                continue
            seen.add(k)
            if k not in hay:
                missing.append((pg, txt))
        if missing:
            bad += 1
            print("  %-20s %d heading(s) not found on the page" % (proj, len(missing)))
            for pg, txt in missing[:6]:
                print("        p%-4d %s" % (pg, txt[:62]))
    print("\n%d page(s) with a heading the PDF prints and the page does not." % bad)
    print("Look before acting: running heads and journal furniture read as headings too.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
