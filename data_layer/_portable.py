"""One-off: replace hardcoded absolute paths with the shared resolver, in both copies."""
import os, re, glob, shutil

PRE = ("import os, sys\n"
       "sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))\n"
       "from _paths import WORK, SITE")
MARKER = "C:" + chr(92) + "Users" + chr(92) + "Havranek"

pat_site = re.compile(r'^\s*SITE\s*=\s*r?"[^"]*"\s*$', re.M)
pat_work = re.compile(r'^\s*WORK\s*=\s*r?"[^"]*"\s*$', re.M)
pat_derived = re.compile(r'^\s*SITE\s*=\s*os\.path\.join\(os\.path\.dirname\(WORK\),\s*"site"\)\s*$', re.M)

ROOT = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.dirname(ROOT)
changed = []
for d in (os.path.join(BASE, "data_layer"), os.path.join(BASE, "site", "data_layer")):
    if not os.path.isdir(d):
        continue
    src = os.path.join(BASE, "data_layer", "_paths.py")
    if os.path.abspath(d) != os.path.abspath(os.path.dirname(src)):
        shutil.copy2(src, os.path.join(d, "_paths.py"))
    for f in sorted(glob.glob(os.path.join(d, "*.py"))):
        base = os.path.basename(f)
        if base in ("_paths.py", "_portable.py"):
            continue
        s = open(f, encoding="utf-8").read()
        if MARKER not in s:
            continue
        s = pat_derived.sub("", s)
        s = pat_site.sub("", s)
        s = pat_work.sub("", s)
        lines = s.split("\n")
        ins = 0
        for i, l in enumerate(lines[:14]):
            if l.startswith(("import ", "from ")):
                ins = i + 1
        lines.insert(ins, PRE)
        open(f, "w", encoding="utf-8").write("\n".join(lines))
        changed.append(os.path.join(os.path.basename(d), base))

print(f"rewrote {len(changed)} files")
for c in changed:
    print("   ", c)
