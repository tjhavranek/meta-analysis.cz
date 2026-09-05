#!/usr/bin/env python3
"""Prove the table-number check can see a changed digit.

    python3 tools/test_check_table_numbers.py

check_table_numbers.py exists because pcc Table 3 shipped 0.8945 where the article prints
0.8845 and nothing on the site could tell. A gate that cannot fail on that is worse than no
gate, because it gets quoted as evidence -- which is exactly what happened to the first
version of check_figure_crops.py, and it took a separate test to find out.

So this alters one digit of one number in a clean transcript's table, requires the check to
fail on that transcript, and then restores the file. The original bytes are read first and
written back in a finally block, so an interrupted run cannot leave a published transcript
altered. The digit is changed to one that keeps the same length and is not a near-miss of
another value in the same row.
"""

import io
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TDIR = os.path.join(ROOT, "tools", "transcripts")


def run(project):
    r = subprocess.run([sys.executable, "-X", "utf8",
                        os.path.join(ROOT, "tools", "check_table_numbers.py"), project],
                       capture_output=True, text=True, encoding="utf-8", errors="replace",
                       cwd=ROOT)
    return r.returncode, (r.stdout or "") + (r.stderr or "")


def pick():
    """A transcript with tables that currently passes, and a numeric cell inside one."""
    exc = json.load(io.open(os.path.join(ROOT, "tools", "table_number_exceptions.json"),
                            encoding="utf-8"))
    for f in sorted(os.listdir(TDIR)):
        if not f.endswith(".md"):
            continue
        proj = f[:-3]
        if proj in exc:
            continue
        text = io.open(os.path.join(TDIR, f), encoding="utf-8").read()
        for line in text.splitlines():
            s = line.strip()
            if not (s.startswith("|") and s.count("|") >= 3):
                continue
            for m in re.finditer(r"(?<![\d.])\d\.\d{3,}(?![\d])", s):
                return proj, os.path.join(TDIR, f), line, m.group(0)
    return None, None, None, None


def main():
    project, path, line, token = pick()
    if not project:
        raise SystemExit("no clean transcript with a suitable table number to test against")
    original = io.open(path, "rb").read()
    # Change the LAST digit, to something it is not. Keeps the length, so nothing about the
    # table's shape changes -- only the value, which is the whole point.
    last = token[-1]
    tampered = token[:-1] + ("7" if last != "7" else "3")
    print("using %s: %s -> %s" % (project, token, tampered))

    failures = []
    try:
        rc, out = run(project)
        if rc != 0:
            raise SystemExit("%s already fails before tampering:\n%s" % (project, out))
        print("  clean tree: exit 0, as expected")

        text = original.decode("utf-8")
        if text.count(line) != 1:
            raise SystemExit("the chosen row is not unique in the file; cannot test safely")
        io.open(path, "w", encoding="utf-8", newline="").write(
            text.replace(line, line.replace(token, tampered, 1), 1))

        rc, out = run(project)
        if rc == 0:
            failures.append("a changed digit did NOT fail the check:\n%s" % out)
        elif tampered not in out:
            failures.append("the check failed, but did not name the changed number:\n%s" % out)
        else:
            print("  one changed digit: exit %d, and it names %s" % (rc, tampered))
    finally:
        io.open(path, "wb").write(original)
        print("  restored %s" % os.path.relpath(path, ROOT))

    rc, out = run(project)
    if rc != 0:
        failures.append("still failing after the file was restored:\n%s" % out)
    else:
        print("  after restore: exit 0, as expected")

    if failures:
        print("\nFAILED")
        for f in failures:
            print("  " + f)
        return 1
    print("\nPASS - the table-number check detects a changed digit")
    return 0


if __name__ == "__main__":
    sys.exit(main())
