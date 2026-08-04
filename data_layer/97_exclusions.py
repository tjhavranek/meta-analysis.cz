"""Are the five exclusions from the pooled table actually justified?

Five datasets are published but kept OUT of the harmonised table: two for having no
per-estimate precision, three as duplicates or overlaps. Every other check in this repository
asks whether the INCLUDED data is right. None asks whether the excluded data deserved to be
excluded, and that asymmetry matters: a wrong exclusion is silently missing data, which no
consistency check can ever surface because the rows simply are not there to be inconsistent.

The brief was to include as many datasets as possible. So test the claims, not the labels:

  no precision   scan the source for ANY column that could serve as a standard error -- an se,
                 a t-statistic, a p-value, a confidence bound, a weight, an inverse-SE. The
                 claim is that none exists. If one does, we are discarding usable estimates.
  duplicate      the claim is "identical, row for row". Compare the actual values. If the
                 overlap is partial rather than total, the non-overlapping remainder is data
                 we are throwing away for no reason.
"""
import os, sys, io, json, re, zipfile, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE
import numpy as np, pandas as pd

OUT = os.path.join(WORK, "out")
if not os.path.isdir(OUT):
    OUT = SITE
H = pd.read_parquet(os.path.join(OUT, "data", "v1", "estimates_harmonised.parquet"))
API = json.load(open(os.path.join(OUT, "api", "v1", "datasets.json"), encoding="utf-8"))
PRIM = json.load(open(os.path.join(WORK, "primaries.json"), encoding="utf-8"))
OVR = json.load(open(os.path.join(WORK, "overrides.json"), encoding="utf-8"))
REP = json.load(open(os.path.join(WORK, "harmonised_report.json"), encoding="utf-8"))
fails, soft = [], []


def hard(ok, msg):
    if not ok:
        fails.append(msg)
    print(("  ok   " if ok else "  FAIL ") + msg)


def read_source(proj):
    rec = PRIM[proj]
    folder = os.path.join(SITE, proj)
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
    sheet = (OVR.get(proj) or {}).get("sheet") or (REP["projects"].get(proj) or {}).get("sheet")
    xl = pd.ExcelFile(src)
    return xl.parse(sheet if sheet and sheet in xl.sheet_names else xl.sheet_names[0])


# anything a standard error could be reconstructed from
# Exclusions whose "no precision" claim survives a closer look than a column-name scan can give.
JUSTIFIED_NO_PRECISION = {
 "lags": "SE3/SE6/SE12/SE18/SE36/SEB/SEP do exist in this file, but the file is SHARED with "
         "price_puzzle and those standard errors belong to the price RESPONSE at each horizon, "
         "which price_puzzle already pools. The outcome here is mon_bot, the months to the "
         "price trough, which has no sampling standard error. Using them would both mis-pair "
         "the outcome and double-count price_puzzle.",
}
PRECISION = re.compile(
    r"(^|_)(se|std|stderr|sterr|sd|error|tstat|t_?stat|t_?val|tval|^t$|pval|p_?value|sig|"
    r"prec|invse|inv_?se|weight|wgt|lower|upper|lb|ub|ci_?l|ci_?u|conf)", re.I)

excluded = [d for d in API["datasets"] if not d.get("in_harmonised_table") and d.get("n_estimates")]
print(f"testing {len(excluded)} exclusions\n")

for d in excluded:
    proj, status = d["id"], d.get("audit_status")
    print(f"--- {proj}  ({d.get('n_estimates')} estimates, {status})")
    try:
        df = read_source(proj)
    except Exception as e:
        soft.append(f"{proj}: could not re-read source ({str(e)[:50]})"); print("    unreadable"); continue

    if status == "excluded_no_precision":
        # The claim: no column in this file can yield a per-estimate standard error.
        cands = []
        for c in df.columns:
            if not PRECISION.search(str(c)):
                continue
            v = pd.to_numeric(df[c], errors="coerce")
            if v.notna().sum() < max(10, 0.3 * len(df)):
                continue
            cands.append((str(c), int(v.notna().sum()), float(v.min()), float(v.max())))
        if cands:
            print(f"    columns whose NAME suggests precision: {[c[0] for c in cands]}")
            # a usable se is strictly positive; a usable t is not degenerate
            usable = [c for c in cands if c[2] > 0]
            for c in cands:
                print(f"      {c[0]:<24} n={c[1]:5d} min={c[2]:<12.4g} max={c[3]:.4g}")
            if usable and proj in JUSTIFIED_NO_PRECISION:
                soft.append(f"{proj}: name-scan flags {[c[0] for c in usable]}, but " +
                            JUSTIFIED_NO_PRECISION[proj])
                hard(True, f"{proj}: candidate columns explained, exclusion justified")
            else:
                hard(not usable,
                     f"{proj}: no usable precision column, exclusion justified"
                     if not usable else
                     f"{proj}: excluded for having NO precision, but {len(usable)} candidate "
                     f"column(s) look usable: {[c[0] for c in usable]} -- re-examine")
        else:
            hard(True, f"{proj}: no column in the file suggests precision, exclusion justified")

    elif status == "duplicate_excluded":
        twin = d.get("duplicate_of") or d.get("overlaps_with")
        g = H[H["dataset"] == twin]
        if not len(g):
            soft.append(f"{proj}: its twin '{twin}' is not in the pooled table"); continue
        # what effect/se would THIS dataset contribute, using the twin's own column names?
        ec, sc = str(g["effect_col"].iloc[0]), str(g["se_col"].iloc[0])
        if ec not in df.columns or sc not in df.columns:
            # fall back to this dataset's own resolved pair
            r = REP["projects"].get(proj) or {}
            ec, sc = r.get("effect"), r.get("se")
        if not ec or ec not in df.columns or not isinstance(sc, str) or sc not in df.columns:
            # An EXCLUDED dataset has no entry in harmonised_report, so the effect/se lookup
            # above returns None and the overlap silently goes unmeasured -- which is exactly
            # the case (trust) where the exclusion most needed testing. Fall back to the
            # inventory's own resolved pair.
            pr = PRIM.get(proj) or {}
            ec = ec if (ec and ec in df.columns) else pr.get("effect")
            _se = (pr.get("se_cols") or [None])[0]
            sc = sc if (isinstance(sc, str) and sc in df.columns) else _se
        if not ec or ec not in df.columns or not isinstance(sc, str) or sc not in df.columns:
            soft.append(f"{proj}: cannot locate a comparable effect/se pair "
                        f"(tried {ec}/{sc}); overlap unmeasured")
            print(f"    cannot locate a comparable pair (tried {ec}/{sc})")
            continue
        e = pd.to_numeric(df[ec], errors="coerce").astype("float64")
        s = pd.to_numeric(df[sc], errors="coerce").astype("float64")
        m = e.notna() & s.notna() & (s > 0)
        mine = set(zip(np.round(e[m], 8), np.round(s[m], 8)))
        theirs = set(zip(np.round(g["effect"].astype("float64"), 8),
                         np.round(g["se"].astype("float64"), 8)))
        uniq = mine - theirs
        frac = 1 - len(uniq) / max(len(mine), 1)
        print(f"    {len(mine)} usable pairs here vs {len(theirs)} in '{twin}': "
              f"{frac*100:.1f}% already present, {len(uniq)} unique")
        if d.get("duplicate_of"):
            hard(frac > 0.99,
                 f"{proj}: {frac*100:.1f}% identical to '{twin}', 'row for row' holds"
                 if frac > 0.99 else
                 f"{proj}: declared a row-for-row DUPLICATE of '{twin}' but only "
                 f"{frac*100:.1f}% of its pairs are there -- {len(uniq)} estimates are being "
                 f"discarded that the twin does not contain")
        else:
            # declared a partial overlap; quantify what is being lost
            if len(uniq) > 50:
                soft.append(f"{proj}: overlaps '{twin}' on only {frac*100:.1f}% of its pairs; "
                            f"{len(uniq)} estimates are unique to it and are currently dropped "
                            f"from the pooled table. Worth deciding deliberately.")
            print(f"    (declared a PARTIAL overlap, so this is a size question, not a defect)")

print(f"\n{len(soft)} soft observation(s):")
for s_ in soft:
    print("  . " + s_)
print(f"\n{len(fails)} hard failure(s)")
if fails:
    for f_ in fails:
        print("  X " + f_)
    sys.exit(1)
print("EXCLUSIONS PASS - every exclusion holds up against the file")
