#!/usr/bin/env python3
"""Check that each headline result's quoted evidence is really a sentence in that paper.

    python3 tools/check_evidence.py

estimates.csv carries a `source_quote` for every paper: the sentence the headline figure is
said to come from. While the papers were PDFs that claim could not be checked. They are HTML
now, so it can be: the sentence either appears in the paper or it does not.

Matching is EXACT on the normalised text -- letters, digits and single spaces. A fuzzy match
would answer a much weaker question, and this is a provenance check rather than a search box.
A quote that joins two passages with an ellipsis is split, and every part must be present.

The comparison is against the article body only. A page also prints its own citation and its
JSON-LD, and a quote taken from the site's catalogue entry will "match" there while being
absent from the paper -- which is the very thing this exists to catch.

Exit status is 1 when a quote fails that is not listed in tools/evidence_exceptions.json with
a reason. The known failures are recorded there rather than silently tolerated.
"""
import csv, html, json, os, re, sys, unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from build_paper_page import documents, page_dir            # noqa: E402

PAPERS = {p["project"]: p for p in json.load(
    open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
PAPERS.update(documents())


def normalise(s):
    s = unicodedata.normalize("NFKD", html.unescape(re.sub(r"<[^>]+>", " ", s)))
    s = re.sub(r"[‐-―−]", "-", s)
    return re.sub(r"\s+", " ", re.sub(r"[^A-Za-z0-9 ]", " ", s)).strip().lower()


def article_body(path):
    src = open(path, encoding="utf-8").read()
    m = re.search(r'<div class="entry">(.*)</div>', src, re.S)
    body = m.group(1) if m else src
    for pat in (r"<script.*?</script>", r"<style.*?</style>",
                r'<div class="attribution">.*?</div>',
                r'<(ol|ul) class="references[^"]*">.*?</\1>'):
        body = re.sub(pat, " ", body, flags=re.S)
    return normalise(body)


def check():
    rows = list(csv.DictReader(open(os.path.join(ROOT, "estimates.csv"), encoding="utf-8")))
    exc_path = os.path.join(ROOT, "tools", "evidence_exceptions.json")
    exceptions = {}
    if os.path.exists(exc_path):
        exceptions = {k: v for k, v in json.load(open(exc_path, encoding="utf-8")).items()
                      if not k.startswith("_")}
    found, failed = 0, []
    for r in rows:
        proj, quote = r["project"], (r.get("source_quote") or "").strip()
        meta = PAPERS.get(proj)
        page = os.path.join(page_dir(proj, meta), "index.html") if meta else None
        if not quote:
            failed.append((proj, "no source_quote")); continue
        if not page or not os.path.exists(page):
            failed.append((proj, "no full-text page")); continue
        body = article_body(page)
        parts = [p for p in re.split(r"\.\.\.|…", quote) if len(p.strip()) > 25] or [quote]
        if all(normalise(p) in body for p in parts):
            found += 1
        else:
            failed.append((proj, "quote is not a sentence in the article body"))
    print("headline quotes that are a sentence in their own paper: %d of %d"
          % (found, len(rows)))
    new = [p for p, _ in failed if p not in exceptions]
    for p, why in failed:
        print("   %s %-20s %s" % ("!" if p in new else "-", p, exceptions.get(p, why)[:92]))
    if new:
        print("\n%d quote(s) fail and are not recorded in tools/evidence_exceptions.json"
              % len(new))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(check())
