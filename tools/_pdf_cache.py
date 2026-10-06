"""A local cache of what poppler reads out of the site's PDFs, for the full-text gates.

Reading the PDFs was most of what the slow gates spent their time on (6 Oct 2026):
check_paper_pages.py 97% (about 288 s for 75 pages), build_paper_page.py --all --check
80% (159 of 198 s), while what a push changes is the pages. A PDF's reading depends only
on its bytes, the code that reads it, the poppler build and the Python, so those make the
key, and every check on a page still runs fresh. The cache lives outside the repository and
outside Dropbox, one file per PDF, kind and code version: two clones on different versions of
these tools (this one and the komentare clone, each in its pre-push hook, 6 Oct 2026)
otherwise overwrote each other's entries on every run. A file unused for 14 days is removed.
CI keeps no
cache and reads every PDF, so a wrong entry could at worst move a failure from the local
hook to CI, never past it. PAPER_CHECK_NO_CACHE=1 turns it off. The key sees the poppler
executables but not poppler's separately installed encoding data, so after reinstalling
poppler delete the folder.
"""

import gzip
import hashlib
import json
import os
import subprocess
import sys
import time

import _poppler

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
CACHE_DIR = None
if not (os.environ.get("CI") or os.environ.get("PAPER_CHECK_NO_CACHE")):
    CACHE_DIR = os.path.join(os.environ.get("LOCALAPPDATA")
                             or os.path.join(os.path.expanduser("~"), ".cache"),
                             "meta-analysis-cz", "paper-pdf-readings")
_code_keys = {}
_pruned = []


def code_key(sources):
    """The Python, the named tools/ sources plus this module and _poppler.py, and poppler."""
    sources = tuple(sources) + ("_pdf_cache.py", "_poppler.py")
    if sources not in _code_keys:
        h = hashlib.sha256(sys.version.encode())
        for name in sources:
            with open(os.path.join(TOOLS, name), "rb") as f:
                h.update(b"\0" + name.encode() + b"\0" + f.read())
        for name in ("pdftotext", "pdfinfo"):
            exe = _poppler.tool(name)
            v = subprocess.run([exe, "-v"], capture_output=True, text=True,
                               encoding="utf-8", errors="replace")
            h.update(("\0%s\0%s\0%s" % (exe, v.stdout, v.stderr)).encode())
        _code_keys[sources] = h.hexdigest()
    return _code_keys[sources]


def cached(kind, pdf, compute, sources, dump=lambda v: v, load=lambda d: d, keep=lambda v: True):
    """compute(), or its stored result for these PDF bytes. Any trouble with the cache
    (no poppler, an unreadable or corrupt file) just means computing it as before; an
    exception from compute() itself propagates as it would without the cache. A result
    that keep() rejects is used once and not stored."""
    if not CACHE_DIR or not pdf:
        return compute()
    try:
        rel = os.path.relpath(pdf, ROOT)
        ck = code_key(sources)
        with open(pdf, "rb") as f:
            key = hashlib.sha256(("%s\0%s\0%s\0" % (kind, ck, rel)).encode()
                                 + f.read()).hexdigest()
        path = os.path.join(CACHE_DIR, "%s-%s-%s.json.gz"
                            % (kind, ck[:12], hashlib.sha256(rel.encode()).hexdigest()[:20]))
    except Exception:
        return compute()
    try:
        with gzip.open(path, "rt", encoding="utf-8") as f:
            stored = json.load(f)
        if stored["key"] == key:
            try:
                os.utime(path)          # in use, so not pruned
            except OSError:
                pass
            return load(stored["value"])
    except Exception:
        pass
    value = compute()
    if not keep(value):
        return value
    tmp = "%s.%d.tmp" % (path, os.getpid())
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        _prune()
        with gzip.open(tmp, "wt", encoding="utf-8") as f:
            json.dump({"key": key, "value": dump(value)}, f)
        os.replace(tmp, path)
    except Exception:
        pass
    finally:
        try:
            os.remove(tmp)
        except OSError:
            pass
    return value


def _prune(days=14):
    """Once a run, remove the cache files nobody has used for `days` days (older versions)."""
    if _pruned:
        return
    _pruned.append(True)
    cutoff = time.time() - days * 86400
    for name in os.listdir(CACHE_DIR):
        path = os.path.join(CACHE_DIR, name)
        try:
            if os.path.getmtime(path) < cutoff:
                os.remove(path)
        except OSError:
            pass
