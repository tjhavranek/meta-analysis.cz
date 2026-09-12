"""Remove hidden metadata that exposes private details from the site's Excel, PDF and zip files.

Found on 12 Sep 2026, in files published for years:
  - Excel keeps the folder a workbook was last saved in (x15ac:absPath in xl/workbook.xml):
    user names of the owners and of coauthors, and one coauthor's e-mail inside a folder name.
  - Printer-settings blocks (xl/printerSettings/*.bin) carry laptop and user names and an
    internal print-server name; two legacy .xls files carry the print-server name in their
    printer record.
  - External-link targets in one workbook carry a coauthor's local folders.
  - The threaded-comment person list and custom document properties carry e-mail addresses.
  - PDFs carry e-mail addresses and Outlook send-for-review fields in their metadata (the
    document information, the XMP packet, and old copies of both left in the file), and user
    folders in saved-file paths (figure alt text, pdfTeX figure references, XMP file paths).
  - The replication and LaTeX zips republish workbooks and figure PDFs with the same metadata.
None of this is research data. This removes exactly those things. Cell values, formulas,
styles, comments, page content and every other part of each file stay as they were, and every
changed file is verified before it is written. Text files inside the zips (scripts, logs) are
left alone: a folder name written in a script is visible content, not hidden metadata.

Usage (from the site root):
  python tools/scrub_office_metadata.py            # report what would change (dry run)
  python tools/scrub_office_metadata.py --apply    # rewrite the files, verifying each one
  python tools/scrub_office_metadata.py --check    # exit 1 if any tracked file still leaks
"""
import io
import logging
import os
import re
import subprocess
import sys
import zipfile

import pandas as pd
import pypdf
from pypdf.generic import (ArrayObject, ByteStringObject, DictionaryObject, IndirectObject, NameObject,
                           StreamObject, TextStringObject)

logging.getLogger("pypdf").setLevel(logging.ERROR)     # free or damaged objects: noise, not findings
SITE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH =re.compile(r"(?<![A-Za-z])[A-Za-z]:\\|(?<![A-Za-z/])[A-Za-z]:/(?!/)|/Users/|/home/", re.I)
# a path inside someone's own user folder: this is what names a person or an account
USERPATH = re.compile(r"[\\/]Users[\\/]|Documents and Settings|(?<![\w.])/home/", re.I)
URL = re.compile(r"^\s*(?:https?|ftp)://", re.I)                # a web address is public
EMAIL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
# XMP namespace boilerplate from publishers, and the owners' own published addresses
EMAIL_OK = re.compile(r"@(prismstandard\.org|yahoogroups\.com)$|^tomas\.havranek@ies-prague\.org$", re.I)
ABS_BLOCK = re.compile(r"<mc:AlternateContent[^>]*>\s*<mc:Choice[^>]*>\s*<x15ac:absPath[^>]*/>\s*"
                       r"</mc:Choice>\s*</mc:AlternateContent>")
# Outlook's send-for-review properties, written into custom.xml, PDF document info and XMP
OUTLOOK_PROPS = {"_AuthorEmail", "_AuthorEmailDisplayName", "_EmailSubject", "_AdHocReviewCycleID",
                 "_ReviewingToolsShownOnce", "_NewReviewCycle", "_PreviousAdHocReviewCycleID"}
XMP_OUTLOOK = "|".join(sorted(p.lstrip("_") for p in OUTLOOK_PROPS))
PRINTER_REL = "/relationships/printerSettings"
# a UNC printer path (\\server\queue) stored as UTF-16 in a legacy .xls printer record
UNC16 = re.compile(rb"(?:\\\x00){2}(?:[A-Za-z0-9._-]\x00)+\\\x00(?:[\x21-\x7e]\x00)+")
UNC8 = re.compile(rb"\\\\[A-Za-z0-9._-]{2,}\\[\x21-\x7e]+")
# files that cannot be read and so cannot be checked, each with the reason it is accepted
SKIP_OK = {"conference/Magkonis_MAER-Prague.pdf": "encrypted with a password: nobody can open it, and no page links it"}


def personal_emails(text):
    return [e for e in EMAIL.findall(text) if not EMAIL_OK.search(e)]


def basename(s):
    return s.strip().replace("\\", "/").rstrip("/").rsplit("/", 1)[-1]


def tracked(pattern):
    out = subprocess.run(["git", "ls-files", pattern], cwd=SITE, capture_output=True,
                         text=True, encoding="utf-8").stdout
    return [f for f in out.split("\n") if f]


# ---------------------------------------------------------------- Excel (.xlsx, .xlsm)

def is_cell_part(name):
    """Research content, never touched or scanned: cells, strings, comments, drawings."""
    return (name.startswith(("xl/worksheets/sheet", "xl/sharedStrings", "xl/comments", "xl/threadedComments/",
                             "xl/media/", "xl/drawings/", "xl/charts/"))
            and not name.endswith(".rels"))


def leaks_xlsx(data):
    z = zipfile.ZipFile(io.BytesIO(data))
    found = []
    for n in z.namelist():
        if is_cell_part(n) or n == "xl/vbaProject.bin":
            continue
        if n.startswith("xl/printerSettings/"):
            found.append((n, "printer settings"))
            continue
        t = z.read(n).decode("utf-8", "ignore")
        for m in PATH.finditer(t):
            found.append((n, t[m.start():m.start() + 60]))
        for e in personal_emails(t):
            found.append((n, e))
    return found


def scrub_xlsx(data):
    """Return (new bytes, list of changes) for one workbook; the caller verifies."""
    z = zipfile.ZipFile(io.BytesIO(data))
    parts = {i.filename: z.read(i.filename) for i in z.infolist()}
    changes, drop = [], set()

    # 1. the saved-folder path
    if "xl/workbook.xml" in parts:
        t = parts["xl/workbook.xml"].decode("utf-8")
        t2, n = ABS_BLOCK.subn("", t)
        if n:
            assert n == 1 and "absPath" not in t2
            parts["xl/workbook.xml"] = t2.encode("utf-8")
            changes.append("absPath removed from xl/workbook.xml")

    # 2. custom properties holding e-mail (Outlook review properties)
    if "docProps/custom.xml" in parts:
        t = parts["docProps/custom.xml"].decode("utf-8")

        def keep(m):
            name, inner = m.group(1), m.group(0)
            return "" if name in OUTLOOK_PROPS or personal_emails(inner) else inner
        t2 = re.sub(r'<property\b[^>]*\bname="([^"]*)"[^>]*>.*?</property>', keep, t, flags=re.S)
        if t2 != t:
            parts["docProps/custom.xml"] = t2.encode("utf-8")
            changes.append("e-mail properties removed from docProps/custom.xml")

    # 3. the person list of threaded comments: an e-mail as userId becomes the display name
    for n in [p for p in parts if p.startswith("xl/persons/") and p.endswith(".xml")]:
        t = parts[n].decode("utf-8")

        def fix(m):
            el = m.group(0)
            uid = re.search(r'\buserId="([^"]*)"', el)
            if not uid or not (personal_emails(uid.group(1)) or PATH.search(uid.group(1))):
                return el
            dn = re.search(r'\bdisplayName="([^"]*)"', el)
            el = el.replace(uid.group(0), 'userId="%s"' % (dn.group(1) if dn else "author"))
            return re.sub(r'\bproviderId="[^"]*"', 'providerId="None"', el)
        t2 = re.sub(r"<(?:\w+:)?person\b[^>]*/?>", fix, t)
        if t2 != t:
            parts[n] = t2.encode("utf-8")
            changes.append("e-mail user ids replaced in " + n)

    # 4. external-link targets pointing into someone's folders: keep only the file name
    for n in [p for p in parts if p.startswith("xl/externalLinks/_rels/")]:
        t = parts[n].decode("utf-8")

        def rel(m):
            tgt = m.group(1)
            if PATH.search(tgt) or tgt.lower().startswith("file:"):
                return 'Target="../%s"' % tgt.replace("\\", "/").rsplit("/", 1)[-1]
            return m.group(0)
        t2 = re.sub(r'Target="([^"]*)"', rel, t)
        if t2 != t:
            parts[n] = t2.encode("utf-8")
            changes.append("external-link targets reduced to file names in " + n)

    # 5. printer settings: drop the parts, their relationships, the pageSetup reference and
    #    the content-type entries; nothing else in the sheet changes
    printer = [p for p in parts if p.startswith("xl/printerSettings/")]
    if printer:
        for n in [p for p in parts if re.match(r"xl/(worksheets|chartsheets)/_rels/[^/]+\.rels$", p)]:
            t = parts[n].decode("utf-8")
            for rid, target in re.findall(r'<Relationship\b[^>]*\bId="([^"]+)"[^>]*\bType="[^"]*' + re.escape(PRINTER_REL)
                                          + r'"[^>]*\bTarget="([^"]+)"[^>]*/>', t) + \
                    [(b, a) for a, b in re.findall(r'<Relationship\b[^>]*\bTarget="([^"]+)"[^>]*\bType="[^"]*'
                                                   + re.escape(PRINTER_REL) + r'"[^>]*\bId="([^"]+)"[^>]*/>', t)]:
                t = re.sub(r'<Relationship\b[^>]*\bId="%s"[^>]*/>' % re.escape(rid), "", t, count=1)
                sheet = n.replace("_rels/", "").rsplit(".rels", 1)[0]
                s = parts[sheet].decode("utf-8")
                s2, k = re.subn(r'(<pageSetup\b[^>]*?)\s+r:id="%s"' % re.escape(rid), r"\1", s, count=1)
                assert k == 1, (sheet, rid)
                parts[sheet] = s2.encode("utf-8")
            parts[n] = t.encode("utf-8")
        referenced = any(re.search(r"printerSettings\d*\.bin", parts[p].decode("utf-8", "ignore"))
                         for p in parts if p.endswith(".rels"))
        assert not referenced, "a printer-settings part is still referenced"
        drop.update(printer)
        ct = parts["[Content_Types].xml"].decode("utf-8")
        ct = re.sub(r'<Override\b[^>]*PartName="/xl/printerSettings/[^"]*"[^>]*/>', "", ct)
        if not any(p.endswith(".bin") for p in parts if p not in drop):
            ct = re.sub(r'<Default\b[^>]*Extension="bin"[^>]*/>', "", ct)
        parts["[Content_Types].xml"] = ct.encode("utf-8")
        changes.append("printer settings removed (%d part(s))" % len(printer))

    if not changes:
        return data, []
    out = io.BytesIO()
    with zipfile.ZipFile(out, "w") as zo:
        for i in z.infolist():
            if i.filename in drop:
                continue
            zo.writestr(i, parts[i.filename], compress_type=i.compress_type)
    return out.getvalue(), changes


def verify_xlsx(old, new):
    """Cells, sheets and every untouched part must be exactly as before."""
    zo, zn = zipfile.ZipFile(io.BytesIO(old)), zipfile.ZipFile(io.BytesIO(new))
    for n in zn.namelist():
        if is_cell_part(n) or n in ("xl/workbook.xml", "docProps/custom.xml", "[Content_Types].xml") \
                or n.startswith(("xl/persons/", "xl/externalLinks/_rels/", "xl/worksheets/_rels/", "xl/chartsheets/_rels/")):
            continue
        assert zo.read(n) == zn.read(n), "part changed unexpectedly: " + n
    for n in zo.namelist():
        if is_cell_part(n) and n in zn.namelist() and zo.read(n) != zn.read(n):
            # only the printer reference may go, and nothing else in the sheet
            a, b = zo.read(n).decode("utf-8"), zn.read(n).decode("utf-8")
            assert re.sub(r'(<pageSetup\b[^>]*?)\s+r:id="[^"]+"', r"\1", a) == b, "sheet changed beyond pageSetup: " + n
    a = pd.read_excel(io.BytesIO(old), sheet_name=None, header=None)
    b = pd.read_excel(io.BytesIO(new), sheet_name=None, header=None)
    assert list(a) == list(b), "sheet list changed"
    for k in a:
        assert a[k].equals(b[k]), "cells changed in sheet " + k
    import openpyxl
    wb = openpyxl.load_workbook(io.BytesIO(new))          # opens as a valid workbook
    assert wb.sheetnames == list(a)
    assert not leaks_xlsx(new), leaks_xlsx(new)


# ---------------------------------------------------------------- legacy Excel (.xls)

def leaks_xls(data):
    return [("printer record", m.group(0).decode("utf-16-le")) for m in UNC16.finditer(data)] + \
           [("8-bit string", m.group(0).decode("latin-1")) for m in UNC8.finditer(data)]


def scrub_xls(data):
    """Blank the print-server name inside the fixed-width printer record, byte for byte: the
    file keeps its size and layout, and the record simply names no device."""
    hits = list(UNC16.finditer(data))
    if not hits:
        return data, []
    b = bytearray(data)
    for m in hits:
        b[m.start():m.end()] = b"\x00" * (m.end() - m.start())
    return bytes(b), ["print-server name blanked in %d printer record(s)" % len(hits)]


def verify_xls(old, new):
    import xlrd
    assert len(old) == len(new), "size changed"
    diff = [i for i in range(len(old)) if old[i] != new[i]]
    spans = [(m.start(), m.end()) for m in UNC16.finditer(old)]
    assert all(any(s <= i < e for s, e in spans) for i in diff), "bytes changed outside the printer records"
    a, b = xlrd.open_workbook(file_contents=old), xlrd.open_workbook(file_contents=new)
    assert a.sheet_names() == b.sheet_names(), "sheet list changed"
    for sa, sb in zip(a.sheets(), b.sheets()):
        assert (sa.nrows, sa.ncols) == (sb.nrows, sb.ncols), "shape changed in " + sa.name
        for r in range(sa.nrows):
            assert sa.row_values(r) == sb.row_values(r), "cells changed in %s row %d" % (sa.name, r)
            assert [c.ctype for c in sa.row(r)] == [c.ctype for c in sb.row(r)]
    assert not leaks_xls(new), leaks_xls(new)


# ---------------------------------------------------------------- PDF

def _strings(o):
    """(key, text) for every string inside one object, without following references."""
    stack = [(None, o)]
    while stack:
        k, v = stack.pop()
        if isinstance(v, IndirectObject):
            continue
        if isinstance(v, DictionaryObject):          # stream dictionaries included
            stack.extend((kk, v.raw_get(kk)) for kk in list(v.keys()))
        elif isinstance(v, ArrayObject):
            stack.extend((k, x) for x in v)
        elif isinstance(v, TextStringObject):
            yield k, str(v)
        elif isinstance(v, ByteStringObject):
            yield k, bytes(v).decode("latin-1")


def _is_xmp(o):
    return isinstance(o, StreamObject) and o.get("/Type") == "/Metadata"


def _all_objects(r):
    """Every object the cross-reference tables list, referenced or not: orphans included."""
    refs = sorted({(i, g) for g, ids in r.xref.items() for i in ids} | {(i, 0) for i in r.xref_objStm})
    for i, g in refs:
        try:
            o = r.get_object(IndirectObject(i, g, r))
        except Exception:
            continue
        if o is not None:
            yield o


def _xmp_leaks(t):
    return [("XMP", e) for e in personal_emails(t)] + \
           [("XMP", t[m.start():m.start() + 60]) for m in PATH.finditer(t)] + \
           [("XMP", m.group(0)) for m in re.finditer(r"pdfx:_(?:%s)\b" % XMP_OUTLOOK, t)]


def leaks_pdf(data):
    r = pypdf.PdfReader(io.BytesIO(data))
    if r.is_encrypted:
        raise ValueError("encrypted")
    found = [("Info" + k, str(v)[:80]) for k, v in (r.metadata or {}).items()
             if PATH.search(str(v)) or personal_emails(str(v)) or k.lstrip("/") in OUTLOOK_PROPS]
    page_emails = None
    for o in _all_objects(r):
        if _is_xmp(o):
            found += _xmp_leaks(o.get_data().decode("utf-8", "ignore"))
        for k, s in _strings(o):
            if k and k.lstrip("/") in OUTLOOK_PROPS:
                found.append((k, s[:60]))
            elif k != "/URI" and not URL.match(s) and USERPATH.search(s):
                found.append((k or "string", s[:80]))
            elif personal_emails(s) and k != "/URI" and not s.lower().startswith("mailto:"):
                if k in ("/Author", "/Title", "/Subject", "/Keywords", "/Creator", "/Producer"):
                    found.append((k, s[:80]))            # document information, wherever it sits
                    continue
                if page_emails is None:                  # an address printed on a page is public
                    page_emails = set(EMAIL.findall(" ".join(p.extract_text() or "" for p in r.pages)))
                found += [(k or "string", e) for e in personal_emails(s) if e not in page_emails]
    return found


def clean_xmp(b):
    """The XMP packet without personal e-mails, Outlook review entries or saved-file paths."""
    try:
        t = b.decode("utf-8")
    except UnicodeDecodeError:
        return b
    t = re.sub(r"\s*\(?[\w.+-]+@[\w-]+(?:\.[\w-]+)+\)?",
               lambda m: "" if personal_emails(m.group(0)) else m.group(0), t)
    t = re.sub(r"<pdfx:_(?:%s)\b[^>]*?(?:/>|>.*?</pdfx:_\w+>)" % XMP_OUTLOOK, "", t, flags=re.S)
    t = re.sub(r'\s+pdfx:_(?:%s)="[^"]*"' % XMP_OUTLOOK, "", t)
    t = re.sub(r">([^<>]+)<", lambda m: ">" + basename(m.group(1)) + "<" if PATH.search(m.group(1)) else m.group(0), t)
    t = re.sub(r'="([^"]*)"', lambda m: '="%s"' % basename(m.group(1)) if PATH.search(m.group(1)) else m.group(0), t)
    return t.encode("utf-8")


def _neutralise_paths(o):
    """Saved-file paths in figure alt text and pdfTeX figure references become the file name."""
    n, stack = 0, [o]
    while stack:
        v = stack.pop()
        if isinstance(v, IndirectObject):
            continue
        if isinstance(v, DictionaryObject):
            for k in list(v.keys()):
                x = v.raw_get(k)
                if k in ("/Alt", "/PTEX.FileName") and isinstance(x, (TextStringObject, ByteStringObject)):
                    s = str(x) if isinstance(x, TextStringObject) else bytes(x).decode("latin-1")
                    if PATH.search(s):
                        v[NameObject(k)] = TextStringObject(basename(s))
                        n += 1
                else:
                    stack.append(x)
        elif isinstance(v, ArrayObject):
            stack.extend(v)
    return n


LITERAL_PATH = re.compile(rb"(/PTEX\.FileName|/Alt)(\s*)\(((?:\\.|[^\\()])*)\)", re.S)


def _unescape(b):
    """A PDF literal string's bytes with its escapes (\\057, \\\\, \\( ...) decoded."""
    return re.sub(rb"\\([0-7]{1,3}|.)", lambda m: bytes([int(m.group(1), 8) & 0xFF]) if m.group(1)[:1].isdigit()
                  else {b"n": b"\n", b"r": b"\r", b"t": b"\t", b"b": b"\b", b"f": b"\f"}.get(m.group(1), m.group(1)), b, flags=re.S)


def _inplace_paths(data):
    """Saved-file paths in /PTEX.FileName and /Alt literal strings become the file name, written
    over the old string and padded with spaces to the same length: every other byte of the file,
    and every offset in its cross-reference table, stays as it was."""
    n = 0

    def rep(m):
        nonlocal n
        s = _unescape(m.group(3))
        if not PATH.search(s.decode("latin-1")):
            return m.group(0)
        name = re.split(rb"[\\/]", s.strip())[-1]
        name = name.replace(b"\\", b"\\\\").replace(b"(", b"\\(").replace(b")", b"\\)")
        out = m.group(1) + b" (" + name + b")"
        assert len(out) <= len(m.group(0))
        n += 1
        return out + b" " * (len(m.group(0)) - len(out))
    return LITERAL_PATH.sub(rep, data), n


def scrub_pdf(data):
    if not leaks_pdf(data):
        return data, []
    # the least invasive fix first: when the only leaks are saved-file paths written as plain
    # strings, change just those bytes. A rewrite normalises the whole file, and one of the
    # site's PDFs has a dictionary with a duplicated key that renders differently once rewritten.
    new, n = _inplace_paths(data)
    if n and not leaks_pdf(new):
        return new, ["%d saved-file path(s) reduced to the file name, in place" % n]
    r = pypdf.PdfReader(io.BytesIO(data))
    w = pypdf.PdfWriter(clone_from=r)
    w.pdf_header = r.pdf_header                        # keep the version the file declares
    changes = []
    info = w._info.get_object() if w._info is not None else DictionaryObject()
    fields = {k: str(v) for k, v in info.items()}
    review = {k for k in fields if k.lstrip("/") in OUTLOOK_PROPS}
    for k in sorted(review):          # Outlook review leftovers: display name, subject lines
        del info[NameObject(k)]
    if review:
        changes.append("Outlook review fields removed (%s)" % ", ".join(sorted(review)))
    for k in sorted(set(fields) - review):
        v = fields[k]
        if not (PATH.search(v) or personal_emails(v)):
            continue
        v2 = re.sub(r"\s*\(?[\w.+-]+@[\w-]+(?:\.[\w-]+)+\)?", "", v).strip()
        if PATH.search(v2) or not v2:
            del info[NameObject(k)]
            changes.append("metadata field %s removed" % k)
        else:
            info[NameObject(k)] = TextStringObject(v2)
            changes.append("e-mail removed from metadata field %s" % k)
    n_xmp = n_path = n_review = 0
    for o in w._objects:
        if o is None:
            continue
        if isinstance(o, DictionaryObject):  # review fields in a second information dictionary
            for k in [k for k in list(o.keys()) if k.lstrip("/") in OUTLOOK_PROPS]:
                del o[k]
                n_review += 1
        if _is_xmp(o):
            old = o.get_data()
            new = clean_xmp(old)
            if new != old:
                o.set_data(new)
                n_xmp += 1
        n_path += _neutralise_paths(o)
    if n_review:
        changes.append("%d more Outlook review field(s) removed" % n_review)
    if n_xmp:
        changes.append("XMP packet cleaned (%d)" % n_xmp)
    if n_path:
        changes.append("%d saved-file path(s) reduced to the file name" % n_path)
    # objects nothing points to any more (an old XMP packet, an earlier revision's
    # document information) would otherwise still be written into the file
    w.compress_identical_objects(remove_duplicates=False, remove_unreferenced=True)
    changes.append("unreferenced objects dropped")
    out = io.BytesIO()
    w.write(out)
    return out.getvalue(), changes


def _dest(d, pages):
    """A link destination with its target page as a page number, not an object number."""
    if d is None:
        return ""
    d = d.get_object() if isinstance(d, IndirectObject) else d
    if isinstance(d, ArrayObject) and len(d):
        first = list.__getitem__(d, 0)
        page = pages.get(first.idnum) if isinstance(first, IndirectObject) else first
        return str([page] + [str(v) for v in d[1:]])
    return str(d)


def _annots(r, i):
    """Subtype and target of each annotation on page i, in order."""
    pages = {p.indirect_reference.idnum: n for n, p in enumerate(r.pages) if p.indirect_reference is not None}
    a = r.pages[i].get("/Annots")
    out = []
    for x in (a.get_object() if a is not None else []):
        x = x.get_object()
        act = x.get("/A")
        act = act.get_object() if act is not None else {}
        out.append((str(x.get("/Subtype")), str(act.get("/URI", "")),
                    _dest(x.get("/Dest", act.get("/D")), pages)))
    return out


def _outline_count(r):
    def walk(items):
        return sum(walk(i) if isinstance(i, list) else 1 for i in items)
    try:
        return walk(r.outline)
    except Exception:
        return -1


def verify_pdf(old, new):
    a, b = pypdf.PdfReader(io.BytesIO(old)), pypdf.PdfReader(io.BytesIO(new))
    assert b.pdf_header == a.pdf_header, "version header changed"
    assert len(a.pages) == len(b.pages), "page count changed"
    for i in range(len(a.pages)):
        assert (a.pages[i].extract_text() or "") == (b.pages[i].extract_text() or ""), "text changed on page %d" % (i + 1)
        assert _annots(a, i) == _annots(b, i), "links or annotations changed on page %d" % (i + 1)
    assert _outline_count(a) == _outline_count(b), "outline changed"
    assert sorted(a.named_destinations) == sorted(b.named_destinations), "named destinations changed"
    for key in ("/StructTreeRoot", "/MarkInfo", "/Lang", "/Outlines", "/Names"):
        assert (key in a.trailer["/Root"]) == (key in b.trailer["/Root"]), key + " lost"
    assert set(b.metadata or {}) <= set(a.metadata or {}), "metadata field added"
    assert not leaks_pdf(new), leaks_pdf(new)


# ---------------------------------------------------------------- zip archives

def _member_kind(n):
    base_ = n.rsplit("/", 1)[-1]
    if "__MACOSX/" in n or base_.startswith("._"):      # macOS resource forks, not the files
        return None
    low = n.lower()
    return "xlsx" if low.endswith((".xlsx", ".xlsm")) else "pdf" if low.endswith(".pdf") else None


HANDLERS = {}          # kind -> (leaks, scrub, verify), filled in below


def leaks_zip(data):
    z = zipfile.ZipFile(io.BytesIO(data))
    found = []
    for i in z.infolist():
        kind = _member_kind(i.filename)
        if kind and not i.is_dir():
            try:
                found += [(i.filename + "::" + a, b) for a, b in HANDLERS[kind][0](z.read(i.filename))]
            except Exception as e:
                found.append((i.filename, "unreadable: %s" % str(e)[:60]))
    return found


def scrub_zip(data):
    """Scrub the workbooks and PDFs inside; every other member is copied unchanged."""
    z = zipfile.ZipFile(io.BytesIO(data))
    replaced, changes = {}, []
    for i in z.infolist():
        kind = _member_kind(i.filename)
        if not kind or i.is_dir():
            continue
        old = z.read(i.filename)
        leaks, scrub, verify = HANDLERS[kind]
        try:
            if not leaks(old):
                continue
        except Exception:                  # unreadable member: left as it is, and reported
            continue
        new, ch = scrub(old)
        if ch:
            verify(old, new)
            replaced[i.filename] = new
            changes.append("%s (%s)" % (i.filename, "; ".join(ch)))
    if not replaced:
        return data, []
    out = io.BytesIO()
    with zipfile.ZipFile(out, "w") as zo:
        for i in z.infolist():
            zi = zipfile.ZipInfo(i.filename, date_time=i.date_time)
            zi.compress_type, zi.external_attr, zi.create_system, zi.comment = \
                i.compress_type, i.external_attr, i.create_system, i.comment
            zo.writestr(zi, replaced.get(i.filename, z.read(i.filename)) if not i.is_dir() else b"")
        zo.comment = z.comment
    return out.getvalue(), changes


def verify_zip(old, new):
    a, b = zipfile.ZipFile(io.BytesIO(old)), zipfile.ZipFile(io.BytesIO(new))
    assert [i.filename for i in a.infolist()] == [i.filename for i in b.infolist()], "members changed"
    assert b.testzip() is None, "corrupt member"
    for i in a.infolist():
        if i.is_dir():
            continue
        if a.read(i.filename) != b.read(i.filename):
            assert _member_kind(i.filename), "a member other than a workbook or PDF changed: " + i.filename
    left = [l for l in leaks_zip(new) if not l[1].startswith("unreadable")]
    assert not left, left


HANDLERS.update(xlsx=(leaks_xlsx, scrub_xlsx, verify_xlsx), pdf=(leaks_pdf, scrub_pdf, verify_pdf))
TYPES = [("*.xlsx", leaks_xlsx, scrub_xlsx, verify_xlsx), ("*.xlsm", leaks_xlsx, scrub_xlsx, verify_xlsx),
         ("*.xls", leaks_xls, scrub_xls, verify_xls), ("*.pdf", leaks_pdf, scrub_pdf, verify_pdf),
         ("*.zip", leaks_zip, scrub_zip, verify_zip)]


def main():
    mode = "--apply" if "--apply" in sys.argv else "--check" if "--check" in sys.argv else "--dry-run"
    left, changed = [], 0
    for pattern, leaks_fn, scrub_fn, verify_fn in TYPES:
        for f in tracked(pattern):
            p = os.path.join(SITE, f)
            data = open(p, "rb").read()
            try:
                leaks = leaks_fn(data)
            except Exception as e:                 # encrypted or unreadable: never touch
                if f in SKIP_OK:
                    print("  not checked, accepted: %s (%s)" % (f, SKIP_OK[f]))
                else:
                    left.append((f, ["unreadable: %s" % str(e)[:60]]))
                continue
            bad = [l for l in leaks if l[1].startswith("unreadable")]     # a zip member that cannot be opened
            leaks = [l for l in leaks if not l[1].startswith("unreadable")]
            if bad:
                left.append((f, bad[:3]))
            if not leaks:
                continue
            if mode == "--check":
                left.append((f, leaks[:3]))
                continue
            new, changes = scrub_fn(data)
            if not changes:
                left.append((f, leaks[:3]))
                continue
            try:
                verify_fn(data, new)
            except Exception as e:                 # never write a file that fails verification
                left.append((f, ["verification failed: %s" % str(e)[:160]]))
                continue
            changed += 1
            print("%s %s: %s" % ("fixed" if mode == "--apply" else "would fix", f, "; ".join(changes)))
            if mode == "--apply":
                open(p, "wb").write(new)
    if left:
        print("\nstill leaking or not handled:")
        for f, l in left:
            print("  ", f, l)
    print("\n%s: %d file(s) %s, %d left" % (mode, changed, "fixed" if mode == "--apply" else "to fix", len(left)))
    return 1 if left else 0


if __name__ == "__main__":
    sys.exit(main())
