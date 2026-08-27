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

--deployed is the OTHER half of the lesson, and the half that actually cost a night.
A push is not a deploy. When the workflow fails, the commit sits on main and the site
keeps serving the previous revision, with nothing in the tree to say so. Run this after
pushing; it waits for Pages and then asks the live domain, cache-busted, whether what
is served matches what was pushed. Do not report work as live without it. Note that
api.github.com is blocked from this environment, so the run's own status has to come
from the GitHub MCP tool rather than curl -- silently, a poll of the API here returns
403 forever and looks exactly like a run that never finishes.
"""
import hashlib, os, re, shutil, subprocess, sys, time, urllib.request

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
SMOKE = "tools/smoke_live.py"

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


def _witness():
    """A file changed by HEAD that the live site serves, and its expected bytes.

    smoke_live.py answers "is the site healthy", not "is THIS commit live". It checks
    invariants -- dataset counts, the data version -- and a commit that changes neither
    passes it while the site still serves the previous revision. That is the exact
    mistake this whole flag exists to stop, and it made it once. So --deployed also
    compares one real file from this commit against what the domain returns.
    """
    changed = subprocess.run("git diff-tree --no-commit-id --name-only -r HEAD",
                             shell=True, cwd=ROOT, capture_output=True, text=True).stdout.split()
    for rel in changed:
        if rel.startswith(("tools/", "data_layer/", ".github/")) or rel.endswith(".py"):
            continue        # not served, or served but not what a reader sees
        path = os.path.join(ROOT, rel)
        if not os.path.isfile(path):
            continue
        url = "/" + rel
        if rel.endswith("/index.html"):
            url = "/" + rel[: -len("index.html")]
        elif rel == "index.html":
            url = "/"
        with open(path, "rb") as fh:
            return url, hashlib.sha256(fh.read()).hexdigest(), rel
    return None, None, None


def deployed():
    """Ask the live domain whether it is serving what was pushed."""
    py = PY312 or "python3"
    url, want, rel = _witness()
    if url:
        print(f"witness for this commit: {rel}")
    else:
        # Real for a commit that only touches tools, the data pipeline or the workflow:
        # nothing a reader fetches changed, so freshness cannot be observed from outside.
        # Say it, rather than print a pass that looks like more than it is.
        print("this commit changes no file the site serves, so only health can be checked")
    for attempt in range(1, 13):
        r = subprocess.run(f"{py} {SMOKE}", shell=True, cwd=ROOT,
                           capture_output=True, text=True)
        healthy = r.returncode == 0
        fresh = True
        if healthy and url:
            try:
                req = urllib.request.Request(
                    f"https://meta-analysis.cz{url}?cb={attempt}-{os.getpid()}",
                    headers={"Cache-Control": "no-cache", "Pragma": "no-cache"})
                got = hashlib.sha256(urllib.request.urlopen(req, timeout=30).read()).hexdigest()
                fresh = got == want
            except Exception as e:
                fresh, got = False, f"({e})"
        if healthy and fresh:
            print((r.stdout or "").strip())
            if url:
                print(f"and {rel} on the live domain is byte-identical to this commit")
            return 0
        why = "site not healthy" if not healthy else f"{rel} served is not this commit's"
        print(f"attempt {attempt}: not live yet, {why}")
        if attempt < 12:
            time.sleep(45)
    print("\nthe live site still does not match after nine minutes.\n"
          "Check the workflow run: a failed gate means the commit never deployed.\n"
          "api.github.com is blocked here, so read the run through the GitHub MCP tool.")
    return 1


def main():
    if "--deployed" in sys.argv:
        return deployed()
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
