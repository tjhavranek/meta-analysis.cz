#!/usr/bin/env python3
"""Prove the crop check can see a same-size pixel change.

    python3 tools/test_check_figure_crops.py

This exists because the first version of check_figure_crops.py could not. It compared the
re-cut's WIDTH and HEIGHT against the stored file and then hashed the stored file against
its own recorded hash. Both of those pass when a renderer stops drawing a glyph but leaves
the picture the same size -- which is the exact defect the checker was written for, after
poppler drew alphas Figure 8's ZapfDingbats markers as nothing and 2,014 marker pixels
became zero.

A check that cannot fail on the thing it exists to catch is worse than no check, because it
is quoted as evidence. So this changes one pixel in a stored figure, without touching its
dimensions, and requires the checker to fail; then restores the file and requires it to
pass. The stored file is restored from the bytes read at the start, in a finally block, so
an interrupted run cannot leave a published image altered.
"""

import io
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

from PIL import Image

import extract_figure


def run_check(project):
    r = subprocess.run([sys.executable, "-X", "utf8",
                        os.path.join(ROOT, "tools", "check_figure_crops.py"), project],
                       capture_output=True, text=True, encoding="utf-8", errors="replace",
                       cwd=ROOT)
    return r.returncode, (r.stdout or "") + (r.stderr or "")


def main():
    man = json.load(io.open(extract_figure.MANIFEST, encoding="utf-8"))
    if not man:
        raise SystemExit("no crop manifest to test against")
    from build_paper_page import documents, page_dir
    papers = {p["project"]: p for p in
              json.load(io.open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    papers.update(documents())

    # The smallest recorded figure, so the test renders as little as possible.
    cands = [(rec["width"] * rec["height"], proj, fig)
             for proj in man for fig, rec in man[proj].items()]
    _, project, fig = min(cands)
    path = os.path.join(page_dir(project, papers[project]), "figures", "fig%s.png" % fig)
    original = io.open(path, "rb").read()
    print("using %s fig%s (%s)" % (project, fig, os.path.relpath(path, ROOT)))

    failures = []
    try:
        rc, out = run_check(project)
        if rc != 0:
            raise SystemExit("the checker already fails on an untouched %s:\n%s" % (project, out))
        print("  clean tree: exit 0, as expected")

        im = Image.open(path).convert("RGB")
        before = im.size
        px = im.load()
        # One pixel, in the middle, forced to a colour it is not. Middle rather than a
        # corner because a corner is padding and a future trim change could crop it away.
        x, y = im.width // 2, im.height // 2
        r, g, b = px[x, y]
        px[x, y] = (255 - r, 255 - g, 255 - b)
        # Save WITHOUT re-quantising, so only the pixels differ and the size cannot.
        im.save(path, optimize=True)
        after = Image.open(path).size
        if after != before:
            failures.append("the tampered file changed size (%s -> %s); the test is invalid"
                            % (before, after))

        rc, out = run_check(project)
        if rc == 0:
            failures.append("one changed pixel did NOT fail the check:\n%s" % out)
        elif "pixel" not in out:
            failures.append("the check failed, but not on pixels:\n%s" % out)
        else:
            line = [l for l in out.splitlines() if "FAIL" in l]
            print("  one changed pixel: exit %d — %s" % (rc, (line[0].strip() if line else "")))
    finally:
        io.open(path, "wb").write(original)
        print("  restored %s" % os.path.relpath(path, ROOT))

    rc, out = run_check(project)
    if rc != 0:
        failures.append("the checker still fails after restoring the file:\n%s" % out)
    else:
        print("  after restore: exit 0, as expected")

    if failures:
        print("\nFAILED")
        for f in failures:
            print("  " + f)
        return 1
    print("\nPASS — the crop check detects a same-size pixel change")
    return 0


if __name__ == "__main__":
    sys.exit(main())
