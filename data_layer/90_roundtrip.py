"""INDEPENDENT round-trip verification of the harmonised table.

Deliberately does NOT reuse the pipeline's reading or mapping code. It goes back to the
ORIGINAL published files (xlsx / dta / csv, including inside zips), reads them fresh, and
asks one question per literature:

    does every (effect, se) pair in the harmonised table actually occur in the source?

That is the check that catches fabrication, a mangled conversion, a column misread or an
off-by-one join -- none of which the existing structural gates can see, because they all
compare generated artefacts against each other.

Three categories, because not every effect is a column read:
  DIRECT     effect and se are columns; the pair must appear in the source
  COMPUTED   reforms (pcc from t and df), activism (rescaled) -- re-derived here from
             the source columns using the formula stated in overrides.json, independently
  RESHAPED   price_puzzle (wide horizons -> long); pairs re-derived from the wide columns

Prints one line per literature. Exit 1 on any failure.
"""
import os, sys, json, io, zipfile, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE
import numpy as np, pandas as pd

OUT = os.path.join(WORK, "out")
# An EMPTY out/ is a Dropbox artefact, not a staging directory: rebuild.py clears it
# with shutil.rmtree(..., ignore_errors=True) and the sync holds handles, so removal
# partially fails. Test for the artefact, not the directory, or this selects the empty
# one and dies on FileNotFoundError. CI never sees it: a fresh checkout has no out/.
if not os.path.isfile(os.path.join(OUT, "api", "v1", "datasets.json")):
    OUT = SITE
H = pd.read_parquet(os.path.join(OUT, "data", "v1", "estimates_harmonised.parquet"))
PRIM = json.load(open(os.path.join(WORK, "primaries.json"), encoding="utf-8"))
OVR = json.load(open(os.path.join(WORK, "overrides.json"), encoding="utf-8"))
REP = json.load(open(os.path.join(WORK, "harmonised_report.json"), encoding="utf-8"))

R = 8  # rounding for value matching


def _read_one(folder, source, archive, member, proj):
    if source == "loose":
        src, name = os.path.join(folder, member), member
    else:
        z = zipfile.ZipFile(os.path.join(folder, archive))
        src, name = io.BytesIO(z.read(member)), member
    ext = os.path.splitext(name)[1].lower()
    if ext == ".dta":
        return pd.read_stata(src, convert_categoricals=False)
    if ext == ".csv":
        return pd.read_csv(src, low_memory=False)
    sheet = (OVR.get(proj) or {}).get("sheet") or REP["projects"][proj].get("sheet")
    xl = pd.ExcelFile(src)
    if sheet and sheet in xl.sheet_names:
        return xl.parse(sheet)
    return None if not xl.sheet_names else xl.parse(xl.sheet_names[0])


def read_source(proj):
    """Read the ORIGINAL published file. Independent of 06_convert.

    This must follow the same PIN the catalogue advertises, or it verifies a file nobody
    publishes. It read primaries.json alone, so for frisch it opened the loose 723-row
    frisch.dta that the resolver had preferred and the override rejects, and reported 538 of
    917 harmonised pairs as absent from "the source" -- a failure of the check, not of the
    data. `source_member` has been pinned since 1.2.1 and `source_members` since 1.3.0; both
    are honoured here now. Reading the pinned file is not the same as trusting 06_convert:
    nothing of that module's mapping, filtering or coalescing logic is used.
    """
    folder = os.path.join(SITE, proj)
    _ov = OVR.get(proj) or {}
    if _ov.get("source_members"):
        parts = [_read_one(folder, _ov.get("source_kind", "zip"), _ov.get("source_archive"),
                           s["member"], proj) for s in _ov["source_members"]]
        return pd.concat([p for p in parts if p is not None], ignore_index=True, sort=False)
    if _ov.get("source_member"):
        return _read_one(folder, _ov.get("source_kind", "zip"), _ov.get("source_archive"),
                         _ov["source_member"], proj)
    rec = PRIM[proj]
    if rec["source"] == "loose":
        src, name = os.path.join(folder, rec["member"]), rec["member"]
    else:
        z = zipfile.ZipFile(os.path.join(folder, rec["archive"]))
        src, name = io.BytesIO(z.read(rec["member"])), rec["member"]
    ext = os.path.splitext(name)[1].lower()
    if ext == ".dta":
        return pd.read_stata(src, convert_categoricals=False)
    if ext == ".csv":
        return pd.read_csv(src, low_memory=False)
    sheet = (OVR.get(proj) or {}).get("sheet") or REP["projects"][proj].get("sheet")
    xl = pd.ExcelFile(src)
    if sheet and sheet in xl.sheet_names:
        return xl.parse(sheet)
    # same widest-clean-sheet rule the converter uses, restated independently
    best = None
    for sh in xl.sheet_names:
        try:
            d = xl.parse(sh)
        except Exception:
            continue
        if d.shape[0] < 5 or d.shape[1] < 3:
            continue
        un = sum(1 for c in d.columns if str(c).startswith(("Unnamed", "nan")) or not str(c).strip())
        sc = (1 - un / max(d.shape[1], 1)) * 3 + min(d.shape[0], 4000) / 4000 + min(d.shape[1], 80) / 80
        if best is None or sc > best[0]:
            best = (sc, d)
    return best[1] if best else None


def num(df, col):
    # MUST widen to float64 before any rounding. Stata files give float32, and
    # np.round on a float32 Series returns float32, where rounding to 8 decimals is a
    # no-op -- comparing that against a rounded float64 makes identical values look
    # different. That artefact produced three false failures on the first run.
    return pd.to_numeric(df[col], errors="coerce").astype("float64")


def source_pairs(proj, df):
    """The (effect, se) pairs the SOURCE can produce, derived here from scratch."""
    o = OVR.get(proj) or {}
    cmp_ = o.get("compute")
    if cmp_ and cmp_.get("type") == "pcc_from_t":              # reforms
        t = num(df, cmp_["t_col"]); dfree = num(df, cmp_["df_col"]).where(lambda x: x > 0)
        e = t / np.sqrt(t ** 2 + dfree); s = np.sqrt((1 - e ** 2) / dfree)
        return set(zip(np.round(e.dropna(), R), np.round(s.reindex(e.dropna().index), R))), "COMPUTED"
    if cmp_ and cmp_.get("type") == "rescale_from_t":          # activism
        base = num(df, cmp_["col"]); fac = num(df, cmp_["factor_col"])
        e = base * cmp_.get("constant", 1.0) * fac
        t = num(df, cmp_["t_col"]).replace(0, np.nan)
        s = (e / t).abs()
        m = e.notna() & s.notna()
        return set(zip(np.round(e[m], R), np.round(s[m], R))), "COMPUTED"
    if o.get("reshape_long"):                                   # price_puzzle
        rs = o["reshape_long"]; pairs = set()
        for _, ec, sc in rs["pairs"]:
            if ec in df.columns and sc in df.columns:
                e, s = num(df, ec), num(df, sc)
                m = e.notna() & s.notna() & (s > 0)
                pairs |= set(zip(np.round(e[m], R), np.round(s[m], R)))
        return pairs, "RESHAPED"
    eff = o.get("effect") or REP["projects"][proj]["effect"]
    e = num(df, eff)
    if o.get("se_mean_of"):                                     # house_prices
        s = pd.concat([num(df, c) for c in o["se_mean_of"] if c in df.columns], axis=1).mean(axis=1)
    else:
        se = o.get("se") or REP["projects"][proj]["se"]
        if isinstance(se, str) and se.startswith("derived:"):
            tcol = se.split("/")[-1].rstrip("|>")
            s = (e / num(df, tcol).replace(0, np.nan)).abs()
        else:
            s = num(df, se)
    m = e.notna() & s.notna() & (s > 0)
    return set(zip(np.round(e[m], R), np.round(s[m], R))), "DIRECT"


rows, fails = [], []
for proj in sorted(H["dataset"].unique()):
    g = H[H["dataset"] == proj]
    got = set(zip(np.round(g["effect"].astype(float), R), np.round(g["se"].astype(float), R)))
    try:
        df = read_source(proj)
        src, kind = source_pairs(proj, df)
    except Exception as ex:
        fails.append(f"{proj}: could not re-read the source ({str(ex)[:60]})")
        rows.append((proj, "ERROR", len(g), 0, 0.0)); continue
    missing = got - src
    frac = 1 - len(missing) / max(len(got), 1)
    rows.append((proj, kind, len(g), len(missing), frac))
    if missing:
        fails.append(f"{proj}: {len(missing)} of {len(got)} harmonised pairs "
                     f"({(1-frac)*100:.1f}%) do NOT occur in the source file")

print("%-20s %-9s %7s %9s %8s" % ("literature", "kind", "rows", "unmatched", "match"))
for p, k, n, miss, frac in rows:
    flag = "" if miss == 0 else "  <-- FAIL"
    print("%-20s %-9s %7d %9d %7.2f%%%s" % (p, k, n, miss, frac * 100, flag))

tot = sum(r[2] for r in rows); bad = sum(r[3] for r in rows)
print(f"\n{len(rows)} literatures | {tot:,} harmonised rows | {bad} values not found in a source file")
if fails:
    print(f"\n{len(fails)} FAILURE(S):")
    for f in fails:
        print("  X " + f)
    sys.exit(1)
print("\nROUND-TRIP PASS - every harmonised value occurs in its original published file")
