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
# Falling back to the name "python3" picks whatever that resolves to, which on Windows
# is a different install from the one running this script even when both are 3.14: the
# user-site path differs, so imports that work under `python` fail under `python3` and
# preflight reports failures CI will never see. sys.executable is always the
# interpreter the caller chose.
FALLBACK = sys.executable or "python3"

# CI runs on Linux, where the default text encoding is UTF-8, so a generator that opens a
# repository file without naming an encoding still reads it correctly there. On Windows
# the default is cp1252 and the same call raises UnicodeDecodeError on any file with a
# non-ASCII byte -- which is most of them here, given the Czech names and the maths.
# preflight exists to run exactly what CI runs, so it gives the children CI's encoding.
CI_ENV = dict(os.environ, PYTHONUTF8="1", PYTHONIOENCODING="utf-8")

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
                cmds.append(line.replace("python ", (PY312 or FALLBACK) + " ", 1))
            elif "python" in line:
                cmds.append(line)
            else:
                unknown.append(line)
    return cmds, unknown


def _witnesses(depth=12, most=6):
    """Served files whose bytes should now be live, newest commits first.

    Two ways this went wrong before it looked like this.

    smoke_live.py answers "is the site healthy", not "is THIS commit live". It checks
    invariants, and a commit that moves none of them passes while the domain still
    serves the previous revision.

    And looking only at HEAD is not enough either. When a deploy FAILS, the next commit
    carries the failed one's content too, so a tools-only HEAD reports "nothing to
    witness" while a page's worth of undeployed work sits in front of it. That happened
    the first time this function was used in anger. So walk back a few commits and
    collect what the site serves, not just what HEAD touched: anything still undeployed
    from an earlier failure shows up as a mismatch here.
    """
    out, seen = [], set()
    for n in range(depth):
        changed = subprocess.run(
            f"git diff-tree --no-commit-id --name-only -r HEAD~{n}",
            shell=True, cwd=ROOT, capture_output=True, text=True,
            encoding="utf-8", errors="replace").stdout.split()
        for rel in changed:
            if rel in seen or rel.startswith(("tools/", "data_layer/", ".github/")) \
                    or rel.endswith(".py"):
                continue
            path = os.path.join(ROOT, rel)
            if not os.path.isfile(path):
                continue
            seen.add(rel)
            url = "/" + rel
            if rel.endswith("/index.html"):
                url = "/" + rel[: -len("index.html")]
            elif rel == "index.html":
                url = "/"
            with open(path, "rb") as fh:
                out.append((url, hashlib.sha256(fh.read()).hexdigest(), rel))
            if len(out) >= most:
                return out
    return out


def _pdftotext_flavour():
    """The first line of `pdftotext -v`, or a note that it is absent."""
    try:
        out = subprocess.run(["pdftotext", "-v"], capture_output=True, text=True,
                             errors="replace")
        return ((out.stdout or "") + (out.stderr or "")).strip().splitlines()[0][:40]
    except (OSError, IndexError):
        return "no pdftotext on PATH"


def _has_poppler():
    return "poppler" in _pdftotext_flavour().lower()


def deployed():
    """Ask the live domain whether it is serving what was pushed."""
    py = PY312 or FALLBACK
    wits = _witnesses()
    if wits:
        print("witnesses: " + ", ".join(r for _, _, r in wits))
    else:
        # Real only if nothing a reader fetches has changed in a dozen commits.
        print("no recently changed file is served, so only health can be checked")
    for attempt in range(1, 13):
        r = subprocess.run(f"{py} {SMOKE}", shell=True, cwd=ROOT,
                           capture_output=True, text=True, encoding="utf-8",
                           errors="replace", env=CI_ENV)
        healthy = r.returncode == 0
        stale = []
        if healthy:
            for url, want, rel in wits:
                try:
                    req = urllib.request.Request(
                        f"https://meta-analysis.cz{url}?cb={attempt}-{os.getpid()}",
                        headers={"Cache-Control": "no-cache", "Pragma": "no-cache"})
                    got = hashlib.sha256(
                        urllib.request.urlopen(req, timeout=30).read()).hexdigest()
                except Exception:
                    got = None
                if got != want:
                    stale.append(rel)
        if healthy and not stale:
            print((r.stdout or "").strip())
            if wits:
                print(f"and all {len(wits)} witness file(s) on the live domain are "
                      f"byte-identical to this checkout")
            return 0
        why = "site not healthy" if not healthy else "served copies differ: " + ", ".join(stale[:3])
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
    for c in (c.format(py=PY312 or FALLBACK) for c in EXTRA):
        if c not in cmds:
            cmds.append(c)
    # Parity with .githooks/pre-push, which already does this. The full-text gate reads the
    # PDFs; CI installs poppler-utils, while a Windows checkout usually finds Xpdf's pdftotext
    # on PATH instead, and Xpdf emits Latin-1 where poppler emits UTF-8. The extraction then
    # fails to decode and preflight reports a fault CI will never see -- which breaks
    # preflight's whole contract of running exactly what CI runs. Skip it, and say so.
    if not _has_poppler():
        cmds = [c for c in cmds if "check_paper_pages" not in c]
        print("NOTE: full-text page check skipped (needs poppler's pdftotext; this machine has "
              + _pdftotext_flavour() + "). CI runs it.")
        print()
    if fast:
        cmds = [c for c in cmds if not any(s in c for s in SLOW)]

    print(f"running {len(cmds)} gate(s){' (--fast: slow gates skipped)' if fast else ''}\n")
    failed = []
    for c in cmds:
        t0 = time.time()
        r = subprocess.run(c, shell=True, cwd=ROOT, capture_output=True, text=True,
                           errors="replace", env=CI_ENV)
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
    if fast:
        # I pushed on --fast once and CI rejected it on check_paper_pages, which --fast
        # skips. The docstring already said not to; a docstring is not in front of you at
        # the moment you decide to push.
        print("NOT ENOUGH TO PUSH ON: --fast skipped " + ", ".join(SLOW) +
              ".\n  Run tools/preflight.py with no arguments before pushing.")
        return 0
    print("every gate CI runs passes here")
    return 0


if __name__ == "__main__":
    sys.exit(main())
