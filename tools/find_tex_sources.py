#!/usr/bin/env python3
"""Find, for each republished paper, the LaTeX source on disk it was written from.

    python tools/find_tex_sources.py --search <dir> [--search <dir>] --out manifest.json

The manifest it writes drives tools/audit_tex_fidelity.py. It is NOT committed: it holds
absolute paths into whoever's drive was searched, and this repository is public.

How a source is identified
--------------------------
Three tests, each defeating a failure of the one before.

1. PROSE OVERLAP against the BUILT PAGE, not against the PDF and not against a title. A
   response-to-referees letter, a title page, a co-author's neighbouring paper in the same
   folder: none of them reproduce a paper's running prose. This is the primary score.

2. UNIQUE OWNERSHIP. Meta-analyses in one research group share a great deal of boilerplate,
   so one file can score highly against several pages at once. Observed: a single MAIVE
   draft "matched" four different method papers, and one stray backup matched six. A file
   is therefore awarded to exactly one paper, the one it scores highest against, and the
   others lose it. A file that matches many papers is measuring house style, not identity.

3. TITLE AGREEMENT as the identity check. Overlap says two documents are about the same
   subject; the title says they are the same document.

A paper that fails 3 but passes 1 and 2 is reported as UNCONFIRMED rather than dropped,
because papers get renamed between draft and publication: one source titled "Tuition Fees
and University Enrollment" is genuinely the paper the site publishes as "Publication Bias
in Measuring the Impact of Tuition on Enrollment". Whoever uses the manifest has to settle
those by hand.

And the standing caveat for everything downstream: a source found this way is very often an
EARLIER DRAFT than the published article the site transcribes. It is evidence about FORM
(what is a formula, what is emphasised, what is a footnote) and never authority about
CONTENT. The published PDF decides.
"""

import argparse
import glob
import html as H
import io
import json
import os
import re
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = {".git", "node_modules", "__pycache__", ".venv", ".dropbox.cache"}

CMD = re.compile(r"[\\][a-zA-Z@]+\s*")
COMMENT = re.compile(r"(?m)(?<![\\])%.*$")
TAG = re.compile(r"<[^>]+>")
NONWORD = re.compile(r"[^a-zA-Z ]")
TITLE = re.compile(r"[\\](?:title|Title|TITLE)\s*(?:\[[^\]]*\])?\s*\{")

STOP = {"with", "from", "that", "this", "meta", "analysis", "evidence", "does", "using",
        "what", "when", "study", "studies", "effect", "effects"}


def words(s):
    return [w for w in NONWORD.sub(" ", s).lower().split() if len(w) > 3]


def tex_counter(path):
    try:
        s = io.open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return None
    if len(s) < 3000:
        return None
    s = CMD.sub(" ", COMMENT.sub(" ", s))
    s = re.sub(r"[{}$&~^_%#]", " ", s)
    w = words(s)
    return Counter(w) if len(w) > 400 else None


def page_counter(project):
    p = os.path.join(ROOT, project, "paper", "index.html")
    s = io.open(p, encoding="utf-8", errors="replace").read()
    s = re.sub(r"(?s)<(script|style).*?</\1>", " ", s)
    return Counter(words(H.unescape(TAG.sub(" ", s))))


def balanced(s):
    d, i, n = 1, 0, len(s)
    while i < n and d:
        if s[i] == "\\":
            i += 2
            continue
        if s[i] == "{":
            d += 1
        elif s[i] == "}":
            d -= 1
        i += 1
    return s[:i - 1]


def tex_title(path):
    try:
        s = io.open(path, encoding="utf-8", errors="replace").read(60000)
    except OSError:
        return ""
    m = TITLE.search(s)
    if not m:
        return ""
    t = balanced(s[m.end():])
    t = re.sub(r"\\[a-zA-Z@]+\s*", " ", t)
    return re.sub(r"\s+", " ", re.sub(r"[{}$&~^_%#\\]", " ", t)).strip()[:200]


def keyw(s):
    return {w for w in re.sub(r"[^a-z0-9 ]", " ", s.lower()).split()
            if len(w) > 3 and w not in STOP}


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--search", action="append", required=True,
                    help="directory to search (repeatable)")
    ap.add_argument("--out", required=True)
    ap.add_argument("--min-cover", type=float, default=0.55)
    a = ap.parse_args(argv)

    papers = {p["project"]: p for p in
              json.load(io.open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    pages = {}
    for p in glob.glob(os.path.join(ROOT, "*", "paper", "index.html")):
        pr = os.path.basename(os.path.dirname(os.path.dirname(p)))
        c = page_counter(pr)
        if sum(c.values()) > 300:
            pages[pr] = (c, sum(c.values()))
    print("republished pages: %d" % len(pages))

    tex = []
    for R in a.search:
        for dp, dn, fn in os.walk(R):
            dn[:] = [d for d in dn if d not in SKIP_DIRS and not d.startswith(".")]
            tex += [os.path.join(dp, f) for f in fn if f.lower().endswith(".tex")]
    print("candidate .tex files: %d" % len(tex))

    best = {}
    for i, t in enumerate(tex):
        if i and i % 500 == 0:
            print("  ...%d/%d" % (i, len(tex)), flush=True)
        tc = tex_counter(t)
        if tc is None:
            continue
        for pr, (pc, tot) in pages.items():
            cov = sum((pc & tc).values()) / tot
            if cov > best.get(pr, (0.0, ""))[0]:
                best[pr] = (cov, t)

    # (2) one file, one owner
    owners = {}
    for pr, (cov, t) in best.items():
        k = t.lower()
        if k not in owners or cov > owners[k][0]:
            owners[k] = (cov, pr)
    kept = {pr: t for pr, (cov, t) in best.items()
            if cov >= a.min_cover and owners[t.lower()][1] == pr}

    # (3) identity
    out, unconfirmed = {}, []
    for pr, t in sorted(kept.items()):
        st = papers.get(pr, {}).get("title", "")
        A, B = keyw(st), keyw(tex_title(t))
        j = len(A & B) / len(A) if A else 0.0
        out[pr] = t
        if j < 0.5:
            unconfirmed.append((pr, j, tex_title(t), st))

    json.dump(out, io.open(a.out, "w", encoding="utf-8"), indent=1)
    print("\nmatched %d of %d pages -> %s" % (len(out), len(pages), a.out))
    if unconfirmed:
        print("\nUNCONFIRMED BY TITLE (%d) -- settle these by hand before trusting them:"
              % len(unconfirmed))
        for pr, j, tt, st in unconfirmed:
            print("  %-20s title-overlap %.2f" % (pr, j))
            print("      tex : %s" % (tt or "(no \\title)")[:74])
            print("      site: %s" % st[:74])
    missing = sorted(set(pages) - set(out))
    if missing:
        print("\nno source found (%d): %s" % (len(missing), ", ".join(missing)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
