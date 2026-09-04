#!/usr/bin/env python3
"""Does each figure still follow from the page and box it was cut from?

    python3 tools/check_figure_crops.py [<project> ...] [--coverage] [--json]

Thirty figures on this site were cut wrong, and every one was invisible afterwards.
extract_figure.py trims a crop back to its own ink, so a box that stopped early yields a
tidy picture of PART of a figure: no ragged edge, no missing file, no broken caption. The
fidelity gate reads prose and never opens an image; the missing-figure screen counts figures
and never measures one. They were found by people reading pages against PDFs.

What made them undetectable was not that they were subtle. It was that nothing knew where
any figure was supposed to have come from -- the page number and the box lived in a shell
command and vanished when it finished. tools/figure_crops.json now records them, and this
re-cuts each recorded figure and compares.

What a failure means, precisely: the stored PNG is no longer what that PDF page and that box
produce. Either the file was edited or replaced outside the extractor, or the source PDF
changed under it (a publisher's updated proof, a working paper swapped for the article), or
the extractor's own behaviour moved. All three are worth knowing and none is currently
visible any other way.

What this does NOT establish: that a recorded box was RIGHT. A figure cut too tight and
recorded faithfully passes here forever. That is why --coverage reports how many figures
have no provenance at all: those are the ones where a person still has to look, and the
count should fall over time rather than being quietly ignored.
"""

import hashlib
import io
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import extract_figure
from PIL import Image


def sha(path):
    return hashlib.sha256(io.open(path, "rb").read()).hexdigest()


def main(argv):
    show_coverage = "--coverage" in argv
    as_json = "--json" in argv
    only = [a for a in argv if not a.startswith("--")]

    try:
        man = json.load(io.open(extract_figure.MANIFEST, encoding="utf-8"))
    except (IOError, OSError, ValueError):
        man = {}

    from build_paper_page import documents, page_dir
    papers = {p["project"]: p for p in
              json.load(io.open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    papers.update(documents())

    fails, checked, missing_file = [], 0, []
    for project in sorted(man):
        if only and project not in only:
            continue
        for fig, rec in sorted(man[project].items()):
            out = os.path.join(page_dir(project, papers.get(project, {})), "figures",
                               "fig%s.png" % fig)
            if not os.path.isfile(out):
                missing_file.append("%s fig%s" % (project, fig))
                continue
            pdf = os.path.join(ROOT, rec["pdf"].replace("/", os.sep))
            if not os.path.isfile(pdf):
                fails.append((project, fig, "source PDF is gone: %s" % rec["pdf"]))
                continue
            checked += 1
            # Re-cut exactly as extract_figure.extract() would, without writing anything.
            im = extract_figure.render(pdf, rec["page"], rec["dpi"])
            x0, y0, x1, y1 = rec["box"]
            im = im.crop((int(x0 * im.width), int(y0 * im.height),
                          int(x1 * im.width), int(y1 * im.height)))
            im = extract_figure.trim(im)
            have = Image.open(out)
            if (im.width, im.height) != (have.width, have.height):
                fails.append((project, fig,
                              "re-cut is %dx%d, the stored file is %dx%d"
                              % (im.width, im.height, have.width, have.height)))
            elif sha(out) != rec["sha256"]:
                # Same shape, different bytes: the file was replaced or re-encoded. Not
                # necessarily wrong, but it did not come from this recorded cut.
                fails.append((project, fig, "same size, but the file is not the recorded one"))

    recorded = {(p, f) for p in man for f in man[p]}
    on_disk = set()
    for project in sorted(papers):
        d = os.path.join(page_dir(project, papers[project]), "figures")
        if os.path.isdir(d):
            for f in os.listdir(d):
                if f.startswith("fig") and f.endswith(".png"):
                    on_disk.add((project, f[3:-4]))
    unrecorded = sorted(on_disk - recorded)

    print("%d figure(s) re-cut and compared, %d differ" % (checked, len(fails)))
    for project, fig, why in fails:
        print("  FAIL %-22s fig%-6s %s" % (project, fig, why))
    if missing_file:
        print("\nrecorded but no file on disk (%d): %s"
              % (len(missing_file), ", ".join(missing_file[:12])))
    if show_coverage or not man:
        print("\nprovenance covers %d of %d figures; %d have none and can only be checked by eye"
              % (len(recorded & on_disk), len(on_disk), len(unrecorded)))
        by_project = {}
        for p, f in unrecorded:
            by_project.setdefault(p, []).append(f)
        for p in sorted(by_project):
            print("  %-22s %d" % (p, len(by_project[p])))
    if as_json:
        print(json.dumps({"checked": checked,
                          "failures": [{"project": p, "fig": f, "why": w} for p, f, w in fails],
                          "unrecorded": ["%s/%s" % (p, f) for p, f in unrecorded]}, indent=1))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
