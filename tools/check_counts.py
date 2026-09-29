#!/usr/bin/env python3
"""Every place the site states its current holdings must state the current number.

    python tools/check_counts.py

Why this exists. After data release 2.1.0 and three new full-text papers (September 2026),
the papers page, the papers API and llms.txt said 74 papers, but three hand-kept places
still said 71 (the impact page's link list, a note's sidebar link, and the search page)
and nothing noticed for days. The numbers that go stale are the ones written into prose
by hand, so this reads the truth from the machine-readable sources and checks the prose
against it:

    papers in full          api/v1/papers.json  paper_count
    datasets, literatures   api/v1/datasets.json  counts
    estimates in samples    api/v1/datasets.json  counts.estimates_in_analysis_samples

A dated note or slide deck that reported the count of its day is history, not a current
claim. Those passages are listed in HISTORICAL by the exact phrase, so they stay as
published while any new or current statement is still checked.
"""
import json
import re
import sys
from pathlib import Path

SITE = Path(__file__).resolve().parent.parent

# Exact phrases that report a past count on purpose. Add one only for text that describes
# a moment (a dated note, a talk), never for a page that describes the site as it is now.
HISTORICAL = {
    "all 71 papers in full HTML": "the MAER-Net rebuild note of 2 September 2026 and its abstract",
    "71 papers in full, most with data and code": "the Chemnitz slides, as presented",
}

SKIP_PREFIXES = ("komentare/", "teaching/", "data_layer/", ".git/", "node_modules/",
                 "api/v1/search-index.json", "api/v1/codebooks/")


def truth():
    papers = json.loads((SITE / "api/v1/papers.json").read_text(encoding="utf-8"))
    counts = json.loads((SITE / "api/v1/datasets.json").read_text(encoding="utf-8"))["counts"]
    return {"papers": papers["paper_count"],
            "datasets": counts["datasets"],
            "literatures": counts["literatures_in_harmonised_table"],
            "estimates": counts["estimates_in_analysis_samples"]}


# (pattern, [kind of each captured number, in order])
PATTERNS = [
    (r"\b(?:all\s+)?(\d{2,3})\s+(?:full-text\s+)?papers\s+in\s+full\b", ["papers"]),
    (r"\b(\d{2,3})\s+full-text\s+papers\b", ["papers"]),
    (r"\b(\d{2})\s+published\s+datasets\b", ["datasets"]),
    (r"\bpools\s+(\d{2})\s+of\s+the\s+(\d{2})\b", ["literatures", "datasets"]),
    (r"\b(\d{2})\s+datasets\s+with\b", ["datasets"]),
    (r"\b(\d{2})\s+estimate-level\s+datasets\b", ["datasets"]),
    (r"\b(\d{2},\d{3})\s+estimates\s+in\s+(?:their\s+|its\s+)?analysis\s+samples", ["estimates"]),
]
PATTERNS = [(re.compile(p, re.I), kinds) for p, kinds in PATTERNS]


def main():
    want = truth()
    fails = []
    checked = 0
    for f in sorted(SITE.rglob("*")):
        rel = f.relative_to(SITE).as_posix()
        if (not f.is_file() or f.suffix not in (".html", ".txt", ".md", ".json")
                or rel.startswith(SKIP_PREFIXES) or "/paper/" in rel):
            continue
        try:
            text = f.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for rx, kinds in PATTERNS:
            for m in rx.finditer(text):
                near = text[max(0, m.start() - 10): m.end() + 40]
                if any(h in re.sub(r"\s+", " ", near) for h in HISTORICAL):
                    continue
                for kind, raw in zip(kinds, m.groups()):
                    checked += 1
                    got = int(raw.replace(",", ""))
                    if got != want[kind]:
                        snippet = re.sub(r"\s+", " ", m.group(0))
                        fails.append(f"{rel}: \"{snippet}\" says {got} {kind}, "
                                     f"the site has {want[kind]:,}")
    print(f"checked {checked} stated counts against papers={want['papers']}, "
          f"datasets={want['datasets']}, literatures={want['literatures']}, "
          f"estimates={want['estimates']:,}")
    for x in fails:
        print("  FAIL", x)
    if fails:
        print(f"{len(fails)} stale count(s). Update the prose, or, if the passage reports a "
              f"past moment on purpose, add its exact phrase to HISTORICAL with a reason.")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
