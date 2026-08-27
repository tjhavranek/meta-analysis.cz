#!/usr/bin/env python3
"""Build /api/v1/papers.json: one small record per paper, for machines.

    python3 tools/build_papers_api.py

llms-full.txt carries the whole corpus, 5.4 MB of it, which is the right artifact for
ingesting everything and the wrong one for deciding what to read. This is the map: one cheap record per paper, small
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


VERSIONS = {"record", "accepted_manuscript", "working_paper", "corrected_manuscript"}


def _version(proj, meta):
    """Which version of itself this page serves. Declared, never assumed.

    This used to be `meta.get("version") or "record"`, so an entry that said nothing was
    reported to every API consumer as the version of record. One of them was not: the page
    had been corrected away from the PDF it links, its entry left `version` unset, and the
    API asserted the opposite of what the page's own visible note said. A supplement has no
    version of its own and is exempt; everything in papers.json must declare one.
    """
    v = meta.get("version")
    if v in VERSIONS:
        return v
    if v is None and meta.get("parent_label"):
        return "record"
    raise SystemExit(f"{proj}: version is {v!r}; papers.json must declare one of "
                     f"{sorted(VERSIONS)}. A missing value used to mean 'record', which "
                     f"is an assumption this file is no longer allowed to make.")


def build():
    papers = {p["project"]: p for p in json.load(
        open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    paper_projects = set(papers)
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
            "document_type": "paper" if proj in paper_projects else "supplement",
            # Which version of itself the full text is. The HTML says so in visible text and
            # in its citation tags; an API consumer was left to assume the version of record.
            "version": _version(proj, meta),
            # ... and the sentence the page shows a reader when "record" or "accepted
            # manuscript" is true but not the whole truth. It reached the HTML and
            # llms-full.txt and stopped there, so the one caveat that tells a consumer the
            # linked PDF is not what the HTML says was invisible to every machine reader.
            "version_note": meta.get("version_note") or None,
            # And, for a working paper, the article it was published as: a consumer that
            # cannot see this counts the two as one document or cites the wrong one.
            "published_as": meta.get("published_as") or None,
            "title": article_title(meta),
            "authors": meta.get("authors") or [],
            "year": meta.get("year"),
            "journal": meta.get("journal"),
            "doi": doi if doi.startswith("https://doi.org/") else None,
            "publisher_url": doi if doi and not doi.startswith("https://doi.org/") else None,
            "full_text_url": BASE + page_href(proj, meta),
            # A paper filed under another project's landing shares that landing with the
            # paper it is filed under, so project_url would hand a consumer the OTHER
            # paper's DOI and pages. Its own page is the honest answer.
            "project_url": (BASE + (page_href(proj, meta) if meta.get("parent")
                                    else "/%s/" % proj)),
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

    n_papers = sum(1 for r in records if r["document_type"] == "paper")
    out = {
        "name": "meta-analysis.cz papers",
        "description": ("One record per full-text document on meta-analysis.cz: %d papers "
                        "plus the MAIVE supplement, each with its full text, PDF and section "
                        "map. Fetch this first and one page after, rather than the whole "
                        "corpus." % n_papers),
        "license": "https://creativecommons.org/licenses/by/4.0/",
        "full_corpus": BASE + "/llms-full.txt",
        "count": len(records),
        "paper_count": n_papers,
        "supplement_count": len(records) - n_papers,
        "papers": records,
    }
    for r in records:
        ids = [x.get("anchor") for x in r["sections"] if x.get("anchor")]
        dup = {i for i in ids if ids.count(i) > 1}
        if dup:
            raise SystemExit("papers.json: duplicate section anchors in %s: %s"
                             % (r["project"], sorted(dup)))
    path = os.path.join(ROOT, "api", "v1", "papers.json")
    fresh = json.dumps(out, indent=1, ensure_ascii=False) + "\n"
    if "--check" in sys.argv:
        on_disk = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
        if on_disk != fresh:
            raise SystemExit("papers.json is stale: rebuild with tools/build_papers_api.py")
        print("papers.json: matches a fresh build (%d documents)" % len(records))
        return
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(fresh)
    secs = sum(len(r["sections"]) for r in records)
    print("api/v1/papers.json: %d papers, %d sections, %d with a headline question"
          % (len(records), secs, sum(1 for r in records if r.get("headline_question"))))


if __name__ == "__main__":
    build()
