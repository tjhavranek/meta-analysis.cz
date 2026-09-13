"""Stop a push that makes the site much bigger, and say what grew.

GitHub Pages publishes the whole checkout (seo.yml uploads `path: .`), and a published site may
be no larger than 1 GB. GitHub gives no timely warning: deploy-pages logs a line only once the
COMPRESSED artifact passes 1 GB, which for this site is roughly 1.4 GB uncompressed. So the
warning has to come from here. All sizes are the uncompressed bytes of the tracked files, which
is what Pages serves.

Three limits:
    - a push that adds more than 10 MB. Of the 100 pushes before this gate existed, only the
      three that added the teaching section crossed it (54, 42 and 23 MB); the next largest
      added 4 MB. A large addition is a decision, not a side effect: look at what grew
      (full-size figures, duplicate PDFs, source bundles that belong on Zenodo) before it is
      published.
    - a site larger than 900 MB, the owner's point for planning to move a large chunk out
      (to Zenodo, or to a second Pages repository).
    - a new or grown file over 50 MB, where git starts warning (it refuses 100 MB).

Any of them stops the push with a report. Every push prints the site size. When the growth is
intended, push again with SIZE_OK=1 (bash: `SIZE_OK=1 git push`; PowerShell:
`$env:SIZE_OK=1; git push`).

    python tools/check_site_size.py [BASE]      # what HEAD adds to BASE (default: upstream)
    python tools/check_site_size.py --worktree  # before committing: what the tree adds to HEAD
"""
import argparse
import os
import subprocess
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PUSH_LIMIT_MB = 10
TOTAL_LIMIT_MB = 900
FILE_LIMIT_MB = 50
PAGES_LIMIT_MB = 1000
MB = 1e6


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, check=True).stdout


def tree(ref):
    """Path -> size of every file in a commit, as git stores it (what Pages serves)."""
    out = {}
    for rec in git("ls-tree", "-r", "-l", "-z", ref).split(b"\0"):
        if not rec:
            continue
        meta, path = rec.split(b"\t", 1)
        size = meta.split()[3]
        if size != b"-":
            out[path.decode("utf-8", "replace")] = int(size)
    return out


def worktree():
    """HEAD's files, with the size on disk of every file that is new, changed or deleted.

    Untracked files count (they are what a commit would add); ignored files do not, because
    CI checks out only what is tracked. A changed text file is measured with this checkout's
    line endings, which can overstate it slightly on Windows; that errs on the safe side."""
    out = tree("HEAD")
    entries = git("status", "--porcelain", "-z", "--untracked-files=all").split(b"\0")
    i = 0
    while i < len(entries):
        entry = entries[i]
        i += 1
        if not entry:
            continue
        code, path = entry[:2].decode(), entry[3:].decode("utf-8", "replace")
        if code[0] in "RC":                     # a rename or copy carries its source next
            old = entries[i].decode("utf-8", "replace")
            i += 1
            if code[0] == "R":
                out.pop(old, None)
        full = os.path.join(ROOT, path)
        if "D" in code or not os.path.isfile(full):
            out.pop(path, None)
        else:
            out[path] = os.path.getsize(full)
    return out


def upstream():
    try:
        return git("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}").decode().strip()
    except subprocess.CalledProcessError:
        return "origin/main"


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("base", nargs="?", help="compare HEAD with this ref (default: the upstream branch)")
    ap.add_argument("--worktree", action="store_true", help="compare the working tree with HEAD")
    ap.add_argument("--push-limit-mb", type=float, default=PUSH_LIMIT_MB)
    ap.add_argument("--total-limit-mb", type=float, default=TOTAL_LIMIT_MB)
    a = ap.parse_args()
    sys.stdout.reconfigure(errors="replace")

    if a.worktree:
        what, base, new = "the uncommitted work", tree("HEAD"), worktree()
    else:
        ref = a.base or upstream()
        try:
            base = tree(ref)
        except subprocess.CalledProcessError:
            base = None                          # a fresh clone with no upstream: total only
        what, new = f"this push (against {ref})", tree("HEAD")

    total = sum(new.values())
    problems, grew = [], []
    line = f"site size: {total / MB:.1f} MB of the {PAGES_LIMIT_MB:,} MB Pages limit"
    if base is not None:
        added = total - sum(base.values())
        grew = sorted(((new[p] - base.get(p, 0), p) for p in new if new[p] > base.get(p, 0)),
                      reverse=True)
        line += f"; {what} adds {added / MB:+.1f} MB"
        if added > a.push_limit_mb * MB:
            problems.append(f"{what} adds {added / MB:.1f} MB, more than the "
                            f"{a.push_limit_mb:g} MB a push may add without a decision")
    if total > a.total_limit_mb * MB:
        problems.append(f"the site would be {total / MB:.0f} MB, past {a.total_limit_mb:g} MB: "
                        "time to plan moving a large chunk out (Zenodo, or a second Pages repository)")
    base_sizes = base or {}
    big = sorted((new[p], p) for p in new if new[p] > FILE_LIMIT_MB * MB and new[p] != base_sizes.get(p))
    for size, path in big:
        problems.append(f"{path} is {size / MB:.1f} MB; git warns above {FILE_LIMIT_MB} MB and refuses 100 MB")
    print(line)
    if not problems:
        return 0

    grew = [(d, p) for d, p in grew if d >= 0.05 * MB]   # below what the report can show
    if grew:
        by_folder = defaultdict(int)
        for d, p in grew:
            by_folder[p.split("/")[0] + "/" if "/" in p else "(top level)"] += d
        print("\nwhere it grew, by folder:")
        for folder, d in sorted(by_folder.items(), key=lambda kv: -kv[1])[:8]:
            print(f"  {d / MB:8.1f} MB  {folder}")
        print("largest new or grown files:")
        for d, p in grew[:12]:
            print(f"  {d / MB:8.1f} MB  {p}")
    print("\nSIZE CHECK:")
    for p in problems:
        print(f"  - {p}")
    if os.environ.get("SIZE_OK") == "1":
        print("allowed: SIZE_OK=1 is set")
        return 0
    print("Before publishing, check what grew: full-size images that could be smaller, PDFs the "
          "site already has, bundles that belong on Zenodo. If the growth is intended, push "
          "again with SIZE_OK=1.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
