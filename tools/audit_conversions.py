#!/usr/bin/env python3
"""Catalogue every conversion defect this repository knows how to recognise.

    python3 tools/audit_conversions.py [--json <path>] [<project> ...]

Written for a sweep of all seventy-one converted papers at once. Nothing here judges
anything a person has to judge; it finds the cases where the machinery demonstrably went
wrong, so that attention and model time go only where they are needed.

Each check exists because the defect it looks for was actually found on this site:

  markers      /beauty/ served eight instructions to a journal's typesetter, "Figure 1
               around here", which read as figures that had failed to load.
  hyphen       fourteen words were split across a line break and never rejoined, so a page
               said "per- 4.28 6.28 5.21 cent".
  flattened    a table can land inside the paragraph before it, and /beauty/ carried
               fifteen thousand characters of one, duplicating tables the page also
               rendered properly a screen further down.
  dup          /discrate/ printed one footnote twice, byte for byte.
  figure_text  a crop located from word coordinates sometimes lands on prose.
               tools/audit_figures.py measures how often the image flips between inked and
               blank rows, which needs enough text lines to establish a rhythm; a two-line
               strip off the foot of a bibliography flips twice and passes. /inflation/'s
               fig4 is exactly that and was about to become its social card. So this also
               asks whether any long unbroken stroke exists at all -- an axis, a frame, a
               box rule -- because prose has none.
  caption      a caption that stops mid-clause, or that begins in lower case because the
               converter mistook a body sentence for one.
  census       a figure or table the paper numbers that the page does not carry.
  para         a paragraph long enough that its line breaks were probably lost.

Exit status is 0 always: this reports, it does not gate. The gate is
tools/check_paper_pages.py.
"""

import html
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import numpy as np                                            # noqa: E402
from PIL import Image                                         # noqa: E402

from build_paper_page import documents, page_dir              # noqa: E402

PAPERS = {p["project"]: p for p in
          json.load(open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
PAPERS.update(documents())
TRANSCRIPTS = os.path.join(ROOT, "tools", "transcripts")

# A typesetter's placement instruction, in any of the dash styles these manuscripts use.
MARKER = re.compile(r"[‐-―\-]{1,3}\s*(?:Figure|Table)\s+\w+\s+around here\s*"
                    r"[‐-―\-]{1,3}")
# A line-break hyphen that was never closed up. The second half of a real suspended
# compound is a connector ("short- and long-run"), so those are not breaks.
CONNECTOR = {"and", "or", "to", "versus", "vs", "und", "of", "the", "in", "a", "an"}
HYPHEN = re.compile(r"\b([A-Za-z]{2,})-\s+((?:[-−(\[]?[\d.,)\]]+\s+){0,6})([a-z]{2,})\b")


def _reviewed():
    p = os.path.join(ROOT, "tools", "figures_reviewed.json")
    if not os.path.exists(p):
        return set()
    return {k for k in json.load(open(p, encoding="utf-8")) if not k.startswith("_")}


def figure_stats(path):
    """Shape, ink, line rhythm and the longest straight stroke, in one pass."""
    a = np.asarray(Image.open(path).convert("L"))
    dark = a < 200
    h, w = dark.shape
    rows = dark.any(axis=1).astype(np.int8)
    flips = (float(np.abs(np.diff(rows)).sum()) / len(rows) * 100.0) if len(rows) > 3 else 99.0

    def longest(v):
        # longest run of True, without a Python loop over every pixel
        if not v.any():
            return 0
        idx = np.flatnonzero(np.diff(np.concatenate(([0], v.view(np.int8), [0]))))
        return int((idx[1::2] - idx[0::2]).max())

    step_r = max(1, h // 400)
    step_c = max(1, w // 400)
    hrun = max((longest(dark[r]) for r in range(0, h, step_r)), default=0) / max(1, w)
    vrun = max((longest(dark[:, c]) for c in range(0, w, step_c)), default=0) / max(1, h)
    return dict(w=w, h=h, ink=round(float(dark.mean()), 4), flips=round(flips, 2),
                hrun=round(float(hrun), 3), vrun=round(float(vrun), 3))


def figure_verdict(s):
    """What the numbers say this crop is."""
    if s["h"] < 200 or s["w"] < 200:
        return "sliver"
    if max(s["hrun"], s["vrun"]) < 0.20:
        # nothing in it is straight for any distance: no axis, no frame, no rule
        return "no-stroke"
    if s["flips"] > 2.5:
        return "prose"
    if s["ink"] < 0.005:
        return "near-blank"
    return "plot"


def audit(project):
    meta = PAPERS[project]
    d = page_dir(project, meta)
    idx = os.path.join(d, "index.html")
    out = {"project": project, "issues": []}
    if not os.path.exists(idx):
        return None
    page = open(idx, encoding="utf-8").read()
    tr = os.path.join(TRANSCRIPTS, "%s.md" % project)
    src = open(tr, encoding="utf-8").read() if os.path.exists(tr) else ""
    add = lambda kind, **kw: out["issues"].append(dict(kind=kind, **kw))

    # -- transcript-level defects
    for m in MARKER.finditer(src):
        add("marker", text=m.group(0).strip())
    for m in HYPHEN.finditer(src):
        if m.group(3).lower() in CONNECTOR:
            continue
        add("hyphen", text=("%s- %s%s" % (m.group(1), m.group(2), m.group(3)))[:70])
    seen = {}
    for ln in src.split("\n"):
        t = ln.strip()
        if len(t) > 45 and not t.startswith(("|", "<", "$", "!")):
            seen[t] = seen.get(t, 0) + 1
    for t, n in seen.items():
        if n > 1 and not re.search(r"\(continued\)|^Notes?:", t):
            add("dup", n=n, text=t[:70])
    for ln in src.split("\n"):
        if len(ln) > 4000 and not ln.lstrip().startswith(("|", "<")):
            toks = ln.split()
            num = sum(1 for w in toks if re.fullmatch(r"[-(\[{]?[\d.,)\]}]*\d[\d.,)\]}]*", w))
            frac = num / max(1, len(toks))
            add("flattened" if frac > 0.12 else "para",
                chars=len(ln), numeric=round(frac, 3), text=ln[:70])

    # -- captions
    for m in re.finditer(r"<figcaption><b>(Figure [A-Za-z0-9.]+)\.</b>(.*?)</figcaption>",
                         page, re.S):
        body = html.unescape(re.sub(r"<[^>]+>", "", m.group(2))).strip()
        # A figure title legitimately has no full stop -- "Currency in Circulation
        # (year-on-year changes in %)" is complete -- so missing punctuation proves
        # nothing. What does prove something is a caption that begins in the middle of a
        # sentence, because then its head was lost: /house_prices/ carries "following a
        # one-percentage-point increase in the policy rate", which is the tail of a
        # sentence whose beginning is gone. Likewise one that opens with a verb, which is
        # how a body sentence ("Figure 3 shows visual diagnostics...") gets mistaken for a
        # caption and then cut at the paragraph break.
        first = (body.split() or [""])[0].rstrip(",.:;")
        if not body:
            add("caption", fig=m.group(1), why="empty")
        elif first.lower() in ("shows", "show", "presents", "reports", "plots",
                               "displays", "illustrates", "compares", "summarises",
                               "summarizes", "depicts", "gives"):
            add("caption", fig=m.group(1), why="opens with a verb: a body sentence was "
                "taken for a caption", text=body[:70])
        elif first[:1].islower() and first.lower() not in ("p", "t", "z", "n"):
            add("caption", fig=m.group(1), why="begins mid-sentence: the head was lost",
                text=body[:70])
        elif body.rstrip().endswith((" the", " a", " an", " of", " in", " for", " and",
                                     " or", " to", " with", " on", " at", " from", " by")):
            add("caption", fig=m.group(1), why="ends on a dangling word",
                text=body[-60:])

    # -- figures on the page
    for m in re.finditer(r'<img src="(figures/[^"]+)"', page):
        p = os.path.join(d, m.group(1))
        if not os.path.exists(p):
            add("missing_file", file=m.group(1))
            continue
        try:
            s = figure_stats(p)
        except Exception as exc:
            add("unreadable", file=m.group(1), why=str(exc)[:60])
            continue
        v = figure_verdict(s)
        if v != "plot":
            add("figure_text", file=m.group(1), verdict=v, **s)

    # -- what the paper numbers versus what the page carries
    try:
        from scout_paper import scout
        sc = scout(project, PAPERS)
        alias = meta.get("figure_labels") or {}
        want_f = {alias.get(n, n) for n in sc.get("figures", {})}
        want_t = set(sc.get("tables", {}))
        got_f = set(re.findall(r"<b>Figure ([A-Za-z0-9.]+)\.</b>", page))
        got_t = set(re.findall(r"<caption><b>Table ([A-Za-z0-9.]+)\.</b>", page))
        for label, want, got in (("figure", want_f, got_f), ("table", want_t, got_t)):
            seen2 = got | {n[:-1] for n in got if n[-1:].isalpha()}
            miss = {n for n in want if not (n[-1:].isalpha() and n[:-1] in seen2)} - seen2
            if miss:
                add("census", what=label, missing=sorted(miss)[:8])
    except Exception as exc:
        add("scout_failed", why=str(exc)[:70])

    # -- things that should never survive
    if "tex-fallback" in page:
        add("tex_fallback", n=page.count("tex-fallback"))
    if "<<" in page:
        add("placeholder")
    targets = set(re.findall(r'id="(ref-[^"]+|note-[^"]+)"', page))
    broken = {h for h in re.findall(r'href="#(ref-[^"]+|note-[^"]+)"', page)} - targets
    if broken:
        add("dead_link", n=len(broken), sample=sorted(broken)[:4])
    return out


def main(argv):
    jpath = None
    if "--json" in argv:
        i = argv.index("--json")
        jpath = argv[i + 1]
        argv = argv[:i] + argv[i + 2:]
    projects = argv or sorted(p for p in PAPERS
                              if os.path.exists(os.path.join(page_dir(p, PAPERS[p]),
                                                             "index.html")))
    reviewed = _reviewed()
    results, counts = [], {}
    for p in projects:
        r = audit(p)
        if not r:
            continue
        r["issues"] = [i for i in r["issues"]
                       if not (i["kind"] == "figure_text"
                               and "%s/%s" % (p, os.path.basename(i["file"])) in reviewed)]
        results.append(r)
        for i in r["issues"]:
            counts[i["kind"]] = counts.get(i["kind"], 0) + 1
    print("audited %d page(s)" % len(results))
    print("issues by kind: %s" % (dict(sorted(counts.items(), key=lambda x: -x[1])) or "none"))
    print()
    for r in sorted(results, key=lambda r: -len(r["issues"])):
        if not r["issues"]:
            continue
        print("%-22s %d" % (r["project"], len(r["issues"])))
        for i in r["issues"][:6]:
            rest = {k: v for k, v in i.items() if k != "kind"}
            print("     %-13s %s" % (i["kind"], str(rest)[:120]))
        if len(r["issues"]) > 6:
            print("     ... %d more" % (len(r["issues"]) - 6))
    if jpath:
        json.dump(results, open(jpath, "w", encoding="utf-8"), indent=1)
        print("\nwritten to %s" % jpath)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
