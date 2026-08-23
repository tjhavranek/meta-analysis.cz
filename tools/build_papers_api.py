#!/usr/bin/env python3
"""Build /api/v1/papers.json: one small record per paper, for machines.

    python3 tools/build_papers_api.py

llms-full.txt carries the whole corpus, 5.4 MB of it, which is the right artifact for
ingesting everything and the wrong one for deciding what to read. This is the map: 54 cheap
records naming what each paper is, where its full text lives, and what sections it has, so a
reader that wants one section can fetch one page instead of the corpus.

Everything here is derived. The title, authors, journal and DOI come from the catalogue, the
section list is read out of the built page, the headline question comes from estimates.csv,
and the data URL from datasets.json. Nothing is typed here that is stated somewhere else.
"""
import csv, html, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from build_paper_page import (article_title, documents, page_dir,   # noqa: E402
                              page_href, pdf_href)

BASE = "https://meta-analysis.cz"


def sections(path):
    """The page's own headings, in order, with the anchors it already carries."""
    src = open(path, encoding="utf-8").read()
    m = re.search(r'<div class="entry">(.*)</div>', src, re.S)
    body = m.group(1) if m else src
    out = []
    for mm in re.finditer(r'<(h[23])[^>]*id="([^"]+)"[^>]*>(.*?)</\1>', body, re.S):
        title = html.unescape(re.sub(r"<[^>]+>", "", mm.group(3))).strip()
        if title:
            out.append({"level": int(mm.group(1)[1]), "title": title, "anchor": mm.group(2)})
    return out


def build():
    papers = {p["project"]: p for p in json.load(
        open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    papers.update(documents())
    try:
        cat = {d["id"]: d for d in json.load(
            open(os.path.join(ROOT, "api", "v1", "datasets.json"), encoding="utf-8"))["datasets"]}
    except Exception:
        cat = {}
    try:
        est = {r["project"]: r for r in csv.DictReader(
            open(os.path.join(ROOT, "estimates.csv"), encoding="utf-8"))}
    except Exception:
        est = {}

    records = []
    for proj, meta in sorted(papers.items()):
        page = os.path.join(page_dir(proj, meta), "index.html")
        if not os.path.exists(page):
            continue
        doi = (meta.get("doi_or_publisher_url") or "")
        rec = {
            "project": proj,
            "title": article_title(meta),
            "authors": meta.get("authors") or [],
            "year": meta.get("year"),
            "journal": meta.get("journal"),
            "doi": doi if doi.startswith("https://doi.org/") else None,
            "publisher_url": doi if doi and not doi.startswith("https://doi.org/") else None,
            "full_text_url": BASE + page_href(proj, meta),
            "project_url": (BASE + (meta.get("parent") or "/%s/" % proj)),
            "pdf_url": (BASE + pdf_href(proj, meta)) if pdf_href(proj, meta) else None,
            "abstract": (meta.get("abstract") or "") or None,
            "sections": sections(page),
        }
        e = est.get(proj)
        if e:
            rec["headline_question"] = e.get("question") or None
            rec["headline"] = e.get("headline") or None
            rec["headline_url"] = BASE + "/results/#" + proj
        d = cat.get(proj)
        if d:
            files = d.get("files") or {}
            rec["data"] = {k: v for k, v in files.items() if v}
            rec["codebook_url"] = files.get("codebook")
        records.append(rec)

    out = {
        "name": "meta-analysis.cz papers",
        "description": ("One record per paper republished in full on meta-analysis.cz: what it "
                        "is, where its full text and PDF are, and the sections it contains. "
                        "Fetch this first and one page after, rather than the whole corpus."),
        "license": "https://creativecommons.org/licenses/by/4.0/",
        "full_corpus": BASE + "/llms-full.txt",
        "count": len(records),
        "papers": records,
    }
    path = os.path.join(ROOT, "api", "v1", "papers.json")
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=1, ensure_ascii=False)
        fh.write("\n")
    secs = sum(len(r["sections"]) for r in records)
    print("api/v1/papers.json: %d papers, %d sections, %d with a headline question"
          % (len(records), secs, sum(1 for r in records if r.get("headline_question"))))


if __name__ == "__main__":
    build()
