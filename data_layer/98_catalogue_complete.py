"""Does the catalogue account for every tabular file this site serves?

Every other check here asks whether the data IN the catalogue is right. None asked whether
anything was MISSING from it, and that gap is invisible by construction: a file nobody
inventoried produces no inconsistency, because it is not there to be inconsistent with.

It bit four paper folders. cbequity, contagion and dst_slovakia were added after the
inventory was last built, and data_layer/rebuild.py deliberately starts at 06 -- the
discovery steps 01-05 write curated state and are not part of the blessed order -- so the
files they ship never entered any surface. cbequity/CBFS.xlsx is a complete 176-estimate
meta-analysis, and the catalogue said nothing about it at all: a reader who found it on the
paper page had no way to tell whether it had been considered and set aside or simply missed.

So this scans the SITE ITSELF rather than the stored inventory, which is the point -- a stale
inventory is exactly the failure being checked for. Names only, no parsing: the question is
whether a project shipping data appears in the catalogue, and answering it does not require
opening the workbook.

Accounted for means listed in datasets[] as a real dataset, or in excluded_resources with a
reason. Either is a decision on the record. Silence is not.
"""
import json, os, sys, zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE

OUT = os.path.join(WORK, "out")
if not os.path.isdir(OUT):
    OUT = SITE

# Kept identical to 01_inventory.py on purpose: the two must agree on what counts as a
# tabular file, or this gate passes projects the inventory would have picked up.
TAB = (".xlsx", ".xlsm", ".xls", ".dta", ".csv", ".rdata", ".rds")
SKIP_DIRS = {"images", "tools", "komentare", "notes", ".git", ".github", "backup"}


def ships_data(folder):
    """Whether a project folder serves a tabular file, loose or inside a zip."""
    fp = os.path.join(SITE, folder)
    for f in sorted(os.listdir(fp)):
        full = os.path.join(fp, f)
        if not os.path.isfile(full):
            continue
        ext = os.path.splitext(f)[1].lower()
        if ext in TAB:
            return f
        if ext == ".zip":
            try:
                z = zipfile.ZipFile(full)
            except Exception:
                continue
            for zi in z.infolist():
                if not zi.is_dir() and os.path.splitext(zi.filename)[1].lower() in TAB:
                    return "%s:%s" % (f, zi.filename)
    return None


idx = json.load(open(os.path.join(OUT, "api", "v1", "datasets.json"), encoding="utf-8"))
accounted = {d["id"] for d in idx["datasets"]}
accounted |= {e["id"] for e in idx.get("excluded_resources", [])}

missing = []
for folder in sorted(os.listdir(SITE)):
    if not os.path.isdir(os.path.join(SITE, folder)) or folder in SKIP_DIRS:
        continue
    if folder.startswith(".") or folder in ("data", "api"):
        continue
    if folder in accounted:
        continue
    found = ships_data(folder)
    if found:
        missing.append((folder, found))

if missing:
    print("%d project(s) serve a tabular file the catalogue never names:" % len(missing))
    for folder, f in missing:
        print("   X %-18s %s" % (folder, f))
    print("\nEach must appear in datasets[] as a real dataset, or in excluded_resources with a\n"
          "reason. Add it to the hand-written excluded list in 07_api.py if it is not\n"
          "estimate-level, or resolve it into a dataset if it is.")
    sys.exit(1)
print("catalogue accounts for every project that ships a tabular file")
