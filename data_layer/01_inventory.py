"""Enumerate every tabular dataset on meta-analysis.cz, loose or inside a zip."""
import os, glob, json, zipfile, hashlib, warnings, io
warnings.filterwarnings("ignore")
import pandas as pd
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE

STAGE = os.path.join(WORK, "staging")
TAB = (".xlsx", ".xlsm", ".xls", ".dta", ".csv", ".rdata", ".rds")
# .xlsm was missing until 2026-08-20, and finance_growth ships exactly one member,
# finance_growth.xlsm — so a whole published dataset was invisible to the inventory
# and to every surface built from it. Macro-enabled workbooks are still workbooks.
SKIP_DIRS = {"images", "tools", "komentare", "notes", ".git", ".github", "backup"}

def sniff(path=None, blob=None, name=""):
    """Return (nrows, ncols, columns) or None."""
    ext = os.path.splitext(name or path)[1].lower()
    try:
        src = io.BytesIO(blob) if blob is not None else path
        if ext == ".dta":
            df = pd.read_stata(src, convert_categoricals=False)
        elif ext == ".csv":
            df = pd.read_csv(src, low_memory=False)
        elif ext in (".xlsx", ".xlsm", ".xls"):   # .xlsm reads exactly like .xlsx;
            # listing it in TAB without adding it here enumerated the file and then
            # dropped it in sniff(), which is how the first half of this fix missed.
            xl = pd.ExcelFile(src)
            best = None
            for sh in xl.sheet_names:                    # pick the widest sheet
                try: d = xl.parse(sh)
                except Exception: continue
                if best is None or d.shape[1] * max(len(d), 1) > best[1].shape[1] * max(len(best[1]), 1):
                    best = (sh, d)
            if best is None: return None
            return (len(best[1]), best[1].shape[1], [str(c) for c in best[1].columns], best[0])
        else:
            return None
        return (len(df), df.shape[1], [str(c) for c in df.columns], None)
    except Exception:
        return None

records = []
for folder in sorted(os.listdir(SITE)):
    fp = os.path.join(SITE, folder)
    if not os.path.isdir(fp) or folder in SKIP_DIRS: continue
    for f in sorted(os.listdir(fp)):
        full = os.path.join(fp, f)
        if not os.path.isfile(full): continue
        ext = os.path.splitext(f)[1].lower()
        if ext in TAB:
            r = sniff(path=full, name=f)
            if r: records.append(dict(project=folder, source="loose", archive=None,
                                      member=f, ext=ext, rows=r[0], ncols=r[1],
                                      sheet=r[3], columns=r[2],
                                      bytes=os.path.getsize(full)))
        elif ext == ".zip":
            try: z = zipfile.ZipFile(full)
            except Exception: continue
            for zi in z.infolist():
                if zi.is_dir(): continue
                if os.path.splitext(zi.filename)[1].lower() not in TAB: continue
                if zi.file_size > 80_000_000: continue
                try: blob = z.read(zi)
                except Exception: continue
                r = sniff(blob=blob, name=zi.filename)
                if r: records.append(dict(project=folder, source="zip", archive=f,
                                          member=zi.filename, ext=os.path.splitext(zi.filename)[1].lower(),
                                          rows=r[0], ncols=r[1], sheet=r[3], columns=r[2],
                                          bytes=zi.file_size))

with open(os.path.join(WORK, "inventory_raw.json"), "w", encoding="utf-8") as fh:
    json.dump(records, fh, indent=1)

print("tabular members found:", len(records))
print("projects covered:", len(set(r["project"] for r in records)))
ziponly = sorted({r["project"] for r in records if r["source"]=="zip"} - {r["project"] for r in records if r["source"]=="loose"})
print("projects whose ONLY data is inside a zip:", ziponly)
