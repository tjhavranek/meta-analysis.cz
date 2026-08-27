#!/usr/bin/env python3
"""Run exactly what CI runs, in CI's order, before pushing.

    python tools/preflight.py [--fast]

Why this exists. On 27 August a push went out with every gate I had run locally
green, and the deploy failed: `data_layer/rebuild.py --check --data` is a BLOCKING
step in .github/workflows/seo.yml and was not in the battery I was running by hand.
The commit sat on main, undeployed, and the site quietly served the previous
revision. Nothing in the repository would have told me: a failed deploy leaves no
trace in the tree, and every local check still passed.

A hand-kept list of commands drifts from the workflow that actually gates the
deploy. So this script does not keep its own list. It PARSES the workflow and
refuses to run if it finds a `run:` step it does not recognise, which is what turns
"I forgot a gate" into a loud failure instead of a silent one.

--fast skips the two slow steps (the full-text page checker, about four minutes,
and the data layer rebuild, about forty seconds). Never push on --fast alone.
"""
import os, re, shutil, subprocess, sys, time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORKFLOW = os.path.join(ROOT, ".github", "workflows", "seo.yml")

# Steps CI runs that are not gates on the tree: installers, Pages actions, the
# post-deploy smoke test (needs a deploy), IndexNow, and the enrichment audit
# (fires only when the generator warned). Everything else must be a known gate.
IGNORE = re.compile(
    r"pip install|apt-get|actions/|KEY=|sleep|smoke_live|indexnow|"
    r"^echo|^for |^if |^fi$|^done$|^exit |^u=|^URLS|"
    r"^BASE=|^CHANGED=|^curl|^#|^-H |^-d |continue-on-error", re.I)

# CI pins Python 3.12 (actions/setup-python). komentare/build.py uses an f-string that
# 3.11 rejects, so a 3.11 default here reports a syntax error CI will never see. Use the
# interpreter CI uses, and say so if it is missing rather than testing the wrong thing.
PY312 = shutil.which("python3.12")

SLOW = ("check_paper_pages", "rebuild.py")

# Gates that should run here even if the workflow does not have them yet. Empty is the
# healthy state: anything listed here is a gap in CI, not a local extra, and belongs in
# the workflow instead. Duplicates of workflow steps are dropped below.
EXTRA = []


def ci_commands():
    """Every command the workflow actually runs against the tree, in order."""
    text = open(WORKFLOW, encoding="utf-8").read()
    cmds, unknown = [], []
    for m in re.finditer(r"^\s*run:\s*(\|)?\s*(.*?)(?=^\s*(?:-\s*name:|[a-z_]+:)\s|\Z)",
                         text, re.S | re.M):
        block = m.group(2)
        for line in block.splitlines():
            line = line.strip()
            if not line or IGNORE.match(line):
                continue
            if IGNORE.search(line):
                continue
            if line.startswith("python "):
                cmds.append(line.replace("python ", (PY312 or "python3") + " ", 1))
            elif "python" in line:
                cmds.append(line)
            else:
                unknown.append(line)
    return cmds, unknown


def main():
    fast = "--fast" in sys.argv
    if not PY312:
        print("WARNING: python3.12 not found. CI runs 3.12 and komentare/build.py needs it;\n"
              "         results below may not match CI.\n")
    cmds, unknown = ci_commands()
    if unknown:
        print("preflight does not recognise these workflow lines; check them by hand:")
        for u in unknown[:10]:
            print("   " + u)
    for c in (c.format(py=PY312 or "python3") for c in EXTRA):
        if c not in cmds:
            cmds.append(c)
    if fast:
        cmds = [c for c in cmds if not any(s in c for s in SLOW)]

    print(f"running {len(cmds)} gate(s){' (--fast: slow gates skipped)' if fast else ''}\n")
    failed = []
    for c in cmds:
        t0 = time.time()
        r = subprocess.run(c, shell=True, cwd=ROOT, capture_output=True, text=True)
        tail = (r.stdout or r.stderr).strip().splitlines()
        mark = "ok  " if r.returncode == 0 else "FAIL"
        print(f"{mark} {time.time()-t0:6.1f}s  {c}")
        if r.returncode != 0:
            failed.append(c)
            for ln in tail[-12:]:
                print("        " + ln)
    print()
    if failed:
        print(f"{len(failed)} gate(s) failed; CI would reject this push:")
        for c in failed:
            print("   " + c)
        return 1
    print("every gate CI runs passes here" + (" (slow gates skipped)" if fast else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
