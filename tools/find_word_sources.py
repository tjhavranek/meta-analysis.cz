#!/usr/bin/env python3
"""Find, for each republished paper, a Word manuscript on disk that is that paper.

The older papers were not written in LaTeX. tools/find_tex_sources.py therefore comes up
empty for a third of the corpus, and the sixteen it misses are mostly 2012-2020, which is
exactly the era of .doc and .docx.

Same identification as the LaTeX matcher, for the same reasons: score on running prose
against the BUILT PAGE, award each file to one paper only, and require the title to agree
before believing it. A meta-analysis group's Word folders are full of grant text, referee
replies and habilitation drafts that share vocabulary with the papers, so the ownership and
title tests do most of the work here.

    python tools/find_word_sources.py --search <dir> [--search <dir>] --out manifest.json

.docx is read directly (it is a zip of XML). Legacy .doc is binary; its text is recovered
well enough for scoring by pulling the readable runs, which is all the matcher needs. Use
the manifest to open the real file, not to read text from.
"""

import argparse
import glob
import html as H
import io
import json
import os
import re
import sys
import zipfile
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP = {".git", "node_modules", "__pycache__", ".venv", ".dropbox.cache"}
TAG = re.compile(r"<[^>]+>")
NONWORD = re.compile(r"[^a-zA-Z ]")
STOP = {"with", "from", "that", "this", "meta", "analysis", "evidence", "does", "using",
        "what", "when", "study", "studies", "effect", "effects"}


def words(s):
    return [w for w in NONWORD.sub(" ", s).lower().split() if len(w) > 3]


def docx_text(p):
    try:
        with zipfile.ZipFile(p) as z:
            names = [n for n in z.namelist()
                     if n.startswith("word/") and n.endswith(".xml")
                     and ("document" in n or "footnotes" in n or "endnotes" in n)]
            out = []
            for n in names:
                x = z.read(n).decode("utf-8", "replace")
                x = re.sub(r"</w:p>", "\n", x)
                out.append(H.unescape(TAG.sub(" ", x)))
            return "\n".join(out)
    except Exception:
        return ""


def doc_text(p):
    """Legacy .doc: keep the printable runs. Crude, but enough to score on."""
    try:
        b = io.open(p, "rb").read()
    except OSError:
        return ""
    out, run = [], []
    for ch in b:
        if 32 <= ch < 127:
            run.append(chr(ch))
        else:
            if len(run) >= 5:
                out.append("".join(run))
            run = []
    return " ".join(out)


def read_any(p):
    return docx_text(p) if p.lower().endswith("x") else doc_text(p)


def page_counter(pr):
    s = io.open(os.path.join(ROOT, pr, "paper", "index.html"),
                encoding="utf-8", errors="replace").read()
    s = re.sub(r"(?s)<(script|style).*?</\1>", " ", s)
    return Counter(words(H.unescape(TAG.sub(" ", s))))


def keyw(s):
    return {w for w in re.sub(r"[^a-z0-9 ]", " ", s.lower()).split()
            if len(w) > 3 and w not in STOP}


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--search", action="append", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--only", help="comma-separated projects to look for")
    ap.add_argument("--min-cover", type=float, default=0.50)
    a = ap.parse_args(argv)

    papers = {p["project"]: p for p in
              json.load(io.open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    want = set(a.only.split(",")) if a.only else None
    pages = {}
    for p in glob.glob(os.path.join(ROOT, "*", "paper", "index.html")):
        pr = os.path.basename(os.path.dirname(os.path.dirname(p)))
        if want and pr not in want:
            continue
        c = page_counter(pr)
        if sum(c.values()) > 300:
            pages[pr] = (c, sum(c.values()))
    print("looking for %d paper(s)" % len(pages))

    files = []
    for R in a.search:
        for dp, dn, fn in os.walk(R):
            dn[:] = [d for d in dn if d not in SKIP and not d.startswith(".")]
            files += [os.path.join(dp, f) for f in fn
                      if f.lower().endswith((".doc", ".docx")) and not f.startswith("~$")]
    print("candidate Word files: %d" % len(files))

    best = {}
    for i, f in enumerate(files):
        if i and i % 200 == 0:
            print("  ...%d/%d" % (i, len(files)), flush=True)
        t = read_any(f)
        if len(t) < 4000:
            continue
        tc = Counter(words(t))
        if sum(tc.values()) < 500:
            continue
        for pr, (pc, tot) in pages.items():
            cov = sum((pc & tc).values()) / tot
            if cov > best.get(pr, (0.0, ""))[0]:
                best[pr] = (cov, f)

    owners = {}
    for pr, (cov, f) in best.items():
        k = f.lower()
        if k not in owners or cov > owners[k][0]:
            owners[k] = (cov, pr)
    out = {}
    print("\n%-20s %6s  %s" % ("project", "cover", "best Word file"))
    for pr in sorted(best, key=lambda p: -best[p][0]):
        cov, f = best[pr]
        if owners[f.lower()][1] != pr:
            continue
        A = keyw(papers[pr]["title"])
        head = " ".join(read_any(f).split()[:400])
        j = len(A & keyw(head)) / len(A) if A else 0.0
        mark = "OK " if (cov >= a.min_cover and j >= 0.5) else ("?  " if cov >= a.min_cover else "   ")
        print("%-20s %6.3f %s%.2f  %s" % (pr, cov, mark, j, f[-72:]))
        if mark == "OK ":
            out[pr] = f
    json.dump(out, io.open(a.out, "w", encoding="utf-8"), indent=1)
    print("\nconfirmed: %d -> %s" % (len(out), a.out))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
