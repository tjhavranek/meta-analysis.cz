"""Build api/v1/people.json: the shared facts about the two maintainers, for their personal sites.

meta-analysis.cz is the hub (owner, 11 Oct 2026): awards, roles, paper statuses and new papers are
entered here first, and tomashavranek.cz and irsova.com follow. A daily job on the owner's PC reads
this feed and reports where a personal site differs; it does not rewrite their wording.

Sources, all in this repo:
  tools/people.json        awards, roles, and the paper statuses the paper records do not carry
  tools/publications.json  each person's journal articles (built from ORCID; /publications/)
  tools/papers.json        the papers this site carries, for working papers and forthcoming ones
  api/v1/datasets.json, api/v1/papers.json   the counts, with their definitions

  python tools/build_people_api.py           write api/v1/people.json
  python tools/build_people_api.py --check   fail if it differs from a fresh build (CI)

The output carries no timestamp, so the same inputs always give the same file and --check holds;
"updated" is the date in tools/people.json, and the commit that changed the file is in git.
"""
import json
import os
import re
import sys
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "api", "v1", "people.json")
BASE = "https://meta-analysis.cz"
WHO = {"tomas": ("havranek", ["tomas havranek"]),
       "zuzana": ("irsova", ["zuzana irsova", "zuzana havrankova", "zuzana irsova havrankova"])}


def load(rel):
    return json.load(open(os.path.join(ROOT, rel), encoding="utf-8"))


def fold(s):
    s = unicodedata.normalize("NFKD", s or "")
    return "".join(c for c in s if not unicodedata.combining(c)).lower().strip()


def slug(s):
    return re.sub(r"[^a-z0-9]+", "-", fold(s)).strip("-")[:60]


def build():
    facts, pubs, papers = load("tools/people.json"), load("tools/publications.json"), load("tools/papers.json")
    status = facts.get("paper_status", {})
    people = {}
    for who, (key, names) in WHO.items():
        recs, seen = [], set()
        for r in pubs[key]:
            proj = r.get("project")
            st = status.get(proj, {})
            doi = r.get("doi") or ""
            recs.append({
                "id": proj or slug(doi or r["title"]), "title": r["title"], "authors": r["authors"],
                "year": r["year"], "journal": r.get("venue"), "volume": r.get("volume"),
                "issue": r.get("issue"), "pages": r.get("page"), "doi": doi or None,
                "status": st.get("status", "published"), "status_venue": st.get("status_venue"),
                "url": f"{BASE}/{proj}/" if proj else (f"https://doi.org/{doi}" if doi else r.get("url"))})
            if proj:
                seen.add(proj)
        # papers this site carries that are not (yet) journal articles in the ORCID-built list
        for p in papers:
            proj = p["project"]
            if proj in seen or not any(fold(a) in names for a in p.get("authors") or []):
                continue
            st = status.get(proj, {})
            recs.append({
                "id": proj, "title": p.get("served_title") or p["title"], "authors": p["authors"],
                "year": p.get("year"), "journal": p.get("journal"), "volume": p.get("volume"),
                "issue": p.get("issue"), "pages": p.get("page"), "doi": None,
                "status": st.get("status", "published" if p.get("journal") else "working_paper"),
                "status_venue": st.get("status_venue"), "url": f"{BASE}/{proj}/"})
        recs.sort(key=lambda x: (-(int(x["year"]) if str(x["year"] or "").isdigit() else 0), x["title"]))
        ids = [x["id"] for x in recs]
        dup = {i for i in ids if ids.count(i) > 1}
        if dup:
            sys.exit(f"build_people_api: duplicate publication ids for {who}: {sorted(dup)}")
        people[who] = {"publications": recs, "awards": facts["people"][who]["awards"],
                       "roles": facts["people"][who]["roles"]}
    ds, pa = load("api/v1/datasets.json")["counts"], load("api/v1/papers.json")
    return {
        "schema_version": 1,
        "name": "meta-analysis.cz people feed",
        "description": ("Shared facts about Tomas Havranek and Zuzana Irsova, the maintainers of "
                        "meta-analysis.cz: publications with their status, awards, roles, and the "
                        "site's counts. meta-analysis.cz is the source; their personal sites follow."),
        "license": "https://creativecommons.org/licenses/by/4.0/",
        "updated": facts["updated"],
        "statuses": {"published": "in print or online with a DOI",
                     "forthcoming": "accepted; status_venue names the journal",
                     "rr": "revise and resubmit; status_venue names the journal",
                     "working_paper": "not yet accepted"},
        "counts": {"papers": pa["paper_count"], "datasets": ds["datasets"],
                   "estimates": ds["estimates_in_analysis_samples"]},
        "counts_definitions": {
            "papers": "papers in full on meta-analysis.cz (api/v1/papers.json paper_count)",
            "datasets": "published datasets (api/v1/datasets.json counts.datasets)",
            "estimates": ("estimates in analysis samples, the figure the catalogue table shows "
                          "(api/v1/datasets.json counts.estimates_in_analysis_samples); the "
                          "harmonised table and the papers' own samples are counted separately "
                          "there")},
        "people": people,
    }


def main():
    text = json.dumps(build(), ensure_ascii=False, indent=1) + "\n"
    if sys.argv[1:] == ["--check"]:
        old = open(OUT, encoding="utf-8").read() if os.path.isfile(OUT) else ""
        if old.replace("\r\n", "\n") != text:
            sys.exit("build_people_api: api/v1/people.json differs from a fresh build; "
                     "run python tools/build_people_api.py")
        print("build_people_api: api/v1/people.json matches a fresh build")
        return
    open(OUT, "w", encoding="utf-8", newline="\n").write(text)
    p = json.loads(text)["people"]
    print("wrote api/v1/people.json:", {w: {k: len(v) for k, v in d.items()} for w, d in p.items()})


if __name__ == "__main__":
    main()
