"""Publish the built data layer into site/. Run this instead of copying files by hand.

CI runs `data_layer/09_verify.py` from site/, so it reads the PUBLISHED copy of the pipeline
state, not the dev copy. Publishing by hand meant keeping a mental list of what to copy, and on
the 1.0.0 release that list was missing one file: `harmonised_report.json`. The dev copy said
price_puzzle had 1,415 rows and trust was included; the published copy still said 7,420 and
excluded. Every local check passed, CI went red, and nothing deployed for an hour.

A hand-maintained list of files that must stay in step is the same defect as a hand-maintained
list of anything else: it is correct until the day it silently is not. This copies everything,
and says what moved.

    python data_layer/13_publish.py [--dry-run]
"""
import os, sys, shutil, filecmp

HERE = os.path.dirname(os.path.abspath(__file__))
SITE = os.path.join(os.path.dirname(HERE), "site")
DRY = "--dry-run" in sys.argv

# This script only makes sense in the DEVELOPMENT layout, where data_layer/ sits beside a
# separate site/. Run from the PUBLISHED repo -- where the pipeline lives inside the site it
# builds -- it used to CREATE an empty site/ and copy 204 files into it. _paths.py then saw
# that new directory, resolved SITE to it, and every source file appeared to 404. Refuse
# instead: there is nothing to publish when the source and the destination are the same tree.
_parent = os.path.dirname(HERE)
if not os.path.isdir(SITE) and (os.path.isdir(os.path.join(_parent, "api"))
                                or os.path.isdir(os.path.join(_parent, "data"))):
    sys.exit("Nothing to publish: this is the published layout, so data_layer/ is already "
             "inside the site. Run the numbered scripts here and commit; do not run this.")

# The pipeline's own state: everything 09_verify and the numbered scripts read at runtime.
# Listed by EXTENSION rather than by name, so a new state file is carried automatically.
STATE_EXT = (".json", ".py", ".md")
SKIP_DIRS = {"out", "__pycache__", ".pytest_cache"}
SKIP_NAMES = {"codegrep_evidence.json"}          # scratch side-output, not part of the release


def copy_tree(src, dst, label, name_filter=None):
    moved, same = [], 0
    for root, dirs, files in os.walk(src):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        rel = os.path.relpath(root, src)
        for f in sorted(files):
            if f in SKIP_NAMES or (name_filter and not name_filter(f)):
                continue
            s = os.path.join(root, f)
            d = os.path.join(dst, f) if rel == "." else os.path.join(dst, rel, f)
            if os.path.exists(d) and filecmp.cmp(s, d, shallow=False):
                same += 1
                continue
            moved.append(os.path.relpath(d, SITE).replace(os.sep, "/"))
            if not DRY:
                os.makedirs(os.path.dirname(d), exist_ok=True)
                shutil.copy2(s, d)
    print(f"{label}: {len(moved)} changed, {same} already identical")
    for m in moved[:12]:
        print(f"   {m}")
    if len(moved) > 12:
        print(f"   ... and {len(moved)-12} more")
    return moved


total = []
# 1. the built artefacts: data/, api/, LICENSE, CITATION.cff
total += copy_tree(os.path.join(HERE, "out"), SITE, "built artefacts")
# 2. the pipeline itself and its state, so the published tree can re-verify itself
total += copy_tree(HERE, os.path.join(SITE, "data_layer"), "pipeline + state",
                   name_filter=lambda f: f.endswith(STATE_EXT))

print(f"\n{len(total)} file(s) {'would be ' if DRY else ''}published")
if not DRY and total:
    print("Now run, from site/:  python data_layer/09_verify.py   (this is what CI runs)")
