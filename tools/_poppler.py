#!/usr/bin/env python3
"""Resolve poppler's pdftotext/pdfinfo, rather than whatever PATH happens to answer to
that name.

The corpus checks compare a rendered page against its PDF's text layer, so they are only
reproducible if everyone runs the SAME extractor. CI installs poppler-utils and gets
poppler. A Windows checkout does not necessarily: Git for Windows ships an *Xpdf* build at
/mingw64/bin/pdftotext, which answers to the same name, takes the same flags, and returns a
different text layer. The result was 26 pages reported as failing locally that pass in CI,
with nothing on screen to say the two runs had used different programs. Nothing was wrong
with the pages.

Real poppler is usually present on such a machine anyway -- MiKTeX ships it -- just later
on PATH. So the rule here is to pick by identity rather than by name: run the candidate's
own -v and keep the first one that says poppler.

On Linux and in CI this changes nothing. PATH's pdftotext is poppler, the first candidate
matches, and the resolved path is the one PATH would have given.

Set POPPLER_BIN to a directory to override the search.
"""

import os
import shutil
import subprocess

_cache = {}

# Places a poppler build lives on Windows when it is not first on PATH. MiKTeX's copy is a
# genuine poppler (it prints "The Poppler Developers"), unlike the MSYS Xpdf one.
_WINDOWS_HINTS = (
    os.path.join(os.environ.get("LOCALAPPDATA", ""), "Programs", "MiKTeX", "miktex", "bin", "x64"),
    r"C:\Program Files\MiKTeX\miktex\bin\x64",
    r"C:\Program Files\poppler\bin",
)


def is_poppler(exe):
    """True if this binary identifies itself as poppler. -v goes to stderr on poppler and
    to stdout on some builds, so both are read."""
    try:
        r = subprocess.run([exe, "-v"], capture_output=True, text=True,
                           encoding="utf-8", errors="replace", timeout=20)
    except (OSError, subprocess.SubprocessError):
        return False
    return "poppler" in ((r.stdout or "") + (r.stderr or "")).lower()


def _candidates(name):
    override = os.environ.get("POPPLER_BIN")
    if override:
        yield os.path.join(override, name)
    seen = set()
    # every PATH entry, in order, not just the first hit
    for d in os.environ.get("PATH", "").split(os.pathsep):
        if not d or d in seen:
            continue
        seen.add(d)
        p = shutil.which(name, path=d)
        if p:
            yield p
    for d in _WINDOWS_HINTS:
        if d and os.path.isdir(d):
            p = shutil.which(name, path=d)
            if p:
                yield p


def tool(name):
    """Absolute path to a poppler `name`, or `name` itself if no poppler build is found.

    Falling back to the bare name keeps the failure where it belongs: the caller runs it,
    and a missing or foreign binary reports itself in the caller's own error, exactly as
    before this module existed.
    """
    if name in _cache:
        return _cache[name]
    found = name
    for cand in _candidates(name):
        if is_poppler(cand):
            found = cand
            break
    _cache[name] = found
    return found


if __name__ == "__main__":
    for n in ("pdftotext", "pdfinfo"):
        p = tool(n)
        ok = is_poppler(p)
        print("%-10s %-70s %s" % (n, p, "poppler" if ok else "NOT poppler"))
