#!/usr/bin/env python3
"""Does every number in a transcribed table appear in the paper it was transcribed from?

    python3 tools/check_table_numbers.py [<project> ...] [--verbose] [--json]

The fidelity gate reads PROSE. verify_transcript.transcript_prose() drops every table row,
every FIGURE/TABLE/ALT line and every $...$ span before comparing, so the densest content on
this site -- 975 tables, 71,000 cells -- has never been checked by anything. That is how pcc
Table 3 came to ship 0.8945 where the article prints 0.8845: one digit, in a cell, invisible
to every gate, found only because a person read the page against the PDF.

WHAT THIS CHECKS, precisely: for every numeric cell in every transcribed table, does that
number appear ANYWHERE in the source PDF's text layer. It cannot tell whether a number sits in
the right cell, the right row or the right table, and it does not pretend to. It tells you
when a number is in the transcript and in no page of the paper, which is what a typo looks
like, and what a table taken from the wrong edition looks like.

WHY IT IS WORTH HAVING ANYWAY: a wrong digit almost never lands on another number that the
paper also prints. Of 39,085 tokens across 64 transcripts, 61 transcripts match completely.

MOST OF THE WORK IS NOT COMPARING, IT IS NORMALISING. Four artifacts each produced dozens of
false alarms before they were handled, and each is a property of PDFs rather than of this
site:

  * a thousands separator is followed by EXACTLY three digits. Without that guard the
    parameter range "U(30,1000)" collapses to the token 301000, which appears in no paper
    because it is not a number.
  * several publishers encode the decimal point as a colon and "=" as a fraction glyph, so
    the text layer reads "Prob > F 1/4 0:006" for what the page prints as "Prob > F = 0.006".
  * a text layer splits a number across spans, so the digits are there but "0.8845" is not.
  * a p-value is often set without its leading zero.

Tokens with fewer than two significant digits are skipped: 0, 5 and 0.5 appear on every page
of every paper and prove nothing either way.
"""

import collections
import io
import json
import os
import re
import sys

import fitz

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

from build_paper_page import documents, transcript_pdf_path            # noqa: E402

EXCEPTIONS = os.path.join(ROOT, "tools", "table_number_exceptions.json")
DASHES = dict.fromkeys(map(ord, "\u2010\u2011\u2012\u2013\u2014\u2015\u2212"), "-")
NUM = re.compile(r"-?\d[\d,\u00a0\u202f']*(?:\.\d+)?")


def norm_text(t):
    t = t.translate(DASHES).replace("\ufb01", "fi").replace("\ufb02", "fl")
    t = re.sub(r"(?<=\d):(?=\d)", ".", t)
    t = re.sub(r"(?<=\d)[,\u00a0\u202f'](?=\d{3}(?!\d))", "", t)
    return t


def tokens(s):
    out = set()
    for m in NUM.finditer(norm_text(s)):
        v = m.group(0).lstrip("-")
        if v.count(".") > 1:
            continue
        if len(v.replace(".", "").lstrip("0")) < 2:
            continue
        out.add(v)
    return out


def pdf_numbers(pdf):
    seen = set()
    with fitz.open(pdf) as doc:
        flat = norm_text("".join(doc.load_page(i).get_text()
                                 for i in range(doc.page_count)))
    for m in NUM.finditer(flat):
        v = m.group(0).lstrip("-")
        if v.count(".") <= 1:
            seen.add(v)
    return seen, flat


def tables_of(md):
    out, cur, heading = [], [], None
    for line in md.splitlines():
        s = line.strip()
        if s.startswith("#") or re.match(r"^\*{0,2}TABLE\b", s, re.I):
            heading = s[:110]
        if s.startswith("|") and s.count("|") >= 3:
            if not re.fullmatch(r"[\|\s:\-]+", s):
                cur.append((heading, s))
            continue
        if cur:
            out.extend(cur)
            cur = []
    out.extend(cur)
    return out


def main(argv):
    verbose = "--verbose" in argv
    as_json = "--json" in argv
    only = [a for a in argv if not a.startswith("--")]

    try:
        exc = json.load(io.open(EXCEPTIONS, encoding="utf-8"))
    except (IOError, OSError, ValueError):
        exc = {}

    papers = {p["project"]: p for p in
              json.load(io.open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    papers.update(documents())
    tdir = os.path.join(ROOT, "tools", "transcripts")

    results, totals = {}, collections.Counter()
    for f in sorted(os.listdir(tdir)):
        if not f.endswith(".md"):
            continue
        proj = f[:-3]
        if only and proj not in only:
            continue
        if proj not in papers:
            continue
        try:
            pdf = transcript_pdf_path(proj, papers[proj])
        except Exception:
            continue
        if not pdf or not os.path.isfile(pdf):
            continue
        rows = tables_of(io.open(os.path.join(tdir, f), encoding="utf-8").read())
        if not rows:
            continue
        seen, flat = pdf_numbers(pdf)
        missing, n_tok = [], 0
        for heading, row in rows:
            for cell in row.strip("|").split("|"):
                for tok in tokens(cell):
                    n_tok += 1
                    if tok in seen:
                        continue
                    if tok.startswith("0.") and tok[1:] in seen:
                        continue
                    if re.search(r"\s*".join(re.escape(c) for c in tok), flat):
                        continue
                    missing.append({"heading": heading, "row": row.strip()[:160],
                                    "token": tok})
        totals["projects"] += 1
        totals["tokens"] += n_tok
        totals["missing"] += len(missing)
        results[proj] = {"tokens": n_tok, "missing": missing}

    failing = {p: r for p, r in results.items() if r["missing"]}
    new = {p: r for p, r in failing.items() if p not in exc}

    print("%d transcripts, %d numeric table tokens checked against their own PDF"
          % (totals["projects"], totals["tokens"]))
    print("%d transcript(s) fully clean" % (totals["projects"] - len(failing)))
    for p in sorted(failing):
        tag = "!" if p in new else "-"
        why = exc.get(p, "%d token(s) not found in the paper" % len(failing[p]["missing"]))
        print("   %s %-18s %4d of %5d not found   %s"
              % (tag, p, len(failing[p]["missing"]), failing[p]["tokens"], why[:88]))
        if verbose or p in new:
            for m in failing[p]["missing"][:8]:
                print("        %-10s %s" % (m["token"], m["row"][:104]))
    if as_json:
        print(json.dumps(results, indent=1, ensure_ascii=False))
    if new:
        print("\n%d transcript(s) fail and are NOT recorded in "
              "tools/table_number_exceptions.json" % len(new))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
