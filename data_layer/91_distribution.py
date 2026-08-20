"""Do the four distributed copies agree, and do the table's own invariants hold?

Round-trip (90_) proved the values come from the sources. This proves that what is
actually DISTRIBUTED is the same table, on all four surfaces a user can reach:

    local parquet  ->  local csv  ->  live csv (meta-analysis.cz)  ->  Zenodo deposit

A user citing the DOI and a user curling the site must get identical numbers. Nothing
else in the repo compares these; each was verified in isolation.

Then the invariants that must hold for any meta-analysis use.
"""
import os, sys, io, json, zipfile, hashlib, urllib.request, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE
import numpy as np, pandas as pd

OUT = os.path.join(WORK, "out")
if not os.path.isdir(OUT):
    OUT = SITE
DV = os.path.join(OUT, "data", "v1")
fails = []


def note(ok, msg):
    if not ok:
        fails.append(msg)
    print(("  ok   " if ok else "  FAIL ") + msg)


# ---------- the four copies ----------
pq = pd.read_parquet(os.path.join(DV, "estimates_harmonised.parquet"))
cs = pd.read_csv(os.path.join(DV, "estimates_harmonised.csv"), low_memory=False)
print("comparing the four distributed copies")

live = zen = None
try:
    req = urllib.request.Request(
        "https://meta-analysis.cz/data/v1/estimates_harmonised.csv?cb=verify",
        headers={"Cache-Control": "no-cache"})
    live = pd.read_csv(io.BytesIO(urllib.request.urlopen(req, timeout=120).read()), low_memory=False)
except Exception as e:
    note(False, f"could not fetch the live CSV: {str(e)[:60]}")

# Compare against the deposit OF THE LIVE VERSION. This was pinned to the 0.9.0-beta zip,
# so from 1.0.0 onwards it compared 48,355 live rows against the beta's 54,076 and reported a
# failure on every run -- a permanently red check says nothing, and trains you to ignore it.
# When the live version has no deposit yet, that is a fact to state, not a failure.
DEPOSITS = {"0.9.0-beta": "21773679", "1.0.0": "21789702"}
zen = None
try:
    _idx = json.load(io.BytesIO(urllib.request.urlopen(
        "https://meta-analysis.cz/api/v1/datasets.json?cb=verify", timeout=120).read()))
    _lv = (_idx.get("harmonised_table") or {}).get("version")
    _rec = DEPOSITS.get(_lv)
    if not _rec:
        print(f"   .. live data version {_lv} has no Zenodo deposit yet, so there is nothing to "
              f"compare it against. Deposit it, add its record id to DEPOSITS, and this check "
              f"resumes.")
    else:
        url = (f"https://zenodo.org/records/{_rec}/files/"
               f"ZENODO-UPLOAD-meta-analysis-cz-v{_lv}.zip?download=1")
        z = zipfile.ZipFile(io.BytesIO(urllib.request.urlopen(url, timeout=180).read()))
        zen = pd.read_csv(io.BytesIO(z.read("estimates_harmonised.csv")), low_memory=False)
except Exception as e:
    note(False, f"could not fetch the Zenodo deposit: {str(e)[:60]}")

KEY = ["dataset", "estimate_id", "effect", "se"]


def same(a, b, label):
    if a is None or b is None:
        return
    note(a.shape == b.shape, f"{label}: same shape {a.shape} vs {b.shape}")
    if a.shape != b.shape:
        return
    note(list(a.columns) == list(b.columns), f"{label}: same columns")
    for col in ("effect", "se", "t_stat"):
        x, y = a[col].astype(float).values, b[col].astype(float).values
        note(np.allclose(x, y, rtol=1e-12, atol=0, equal_nan=True),
             f"{label}: {col} identical to 1e-12")
    note((a["dataset"].values == b["dataset"].values).all(), f"{label}: dataset labels aligned")


same(pq, cs, "local parquet vs local csv")
same(cs, live, "local csv vs LIVE csv")
same(live, zen, "live csv vs ZENODO deposit")

# ---------- invariants any user relies on ----------
print("\ninvariants")
d = pq
note(bool((d["se"] > 0).all()), "every standard error is strictly positive")
note(int(d[["effect", "se"]].isna().sum().sum()) == 0, "no null effect or standard error")

# t_stat and precision must be reproducible from effect and se. In the SHIPPED 0.9.0-beta
# they are not exactly, for three Stata-sourced literatures: the source columns are float32,
# and the derived columns were computed before the widening to float64, so they carry float32
# precision. The deviation is ~5e-8 relative -- far below anything a meta-analysis estimator
# can see -- so the shipped table was left alone rather than desynchronising the site from the
# published deposit. 08_harmonise.py now widens first; the next release derives exactly.
# Until then this asserts the deviation stays BOUNDED and CONFINED, which is the real risk.
KNOWN_F32 = {"climate", "euro", "resource_curse"}
F32_EPS = 1.2e-7
for col, expect in (("t_stat", d["effect"].astype(float) / d["se"].astype(float)),
                    ("precision", 1.0 / d["se"].astype(float))):
    got = d[col].astype(float)
    off = ~np.isclose(got, expect, rtol=1e-9, equal_nan=True)
    if not off.any():
        note(True, f"{col} == its definition, exactly")
        continue
    rel = float(np.nanmax((np.abs(got - expect) / np.abs(expect))[off]))
    where = set(d.loc[off, "dataset"].unique())
    note(where <= KNOWN_F32,
         f"{col}: inexact only in the known float32 literatures "
         f"({', '.join(sorted(where))})")
    note(rel < F32_EPS,
         f"{col}: worst deviation {rel:.1e} stays within float32 epsilon "
         f"({int(off.sum())} of {len(d):,} rows)")
note(int(d.duplicated(subset=["dataset", "estimate_id"]).sum()) == 0,
     "(dataset, estimate_id) is unique")
note(int(d["study_id"].isna().sum()) == 0, "every row has a study_id for clustering")
note(bool(d["effect_units"].notna().all()), "every row declares effect_units")
note(bool((d.groupby("dataset")["effect_units"].nunique() == 1).all()),
     "effect_units is constant within each literature")
note(bool(np.isfinite(d["effect"].astype(float)).all()) and
     bool(np.isfinite(d["se"].astype(float)).all()), "no inf values in effect or se")

# provenance must be complete: every row traceable to a file and columns
for col in ("source_file", "effect_col", "se_col"):
    note(bool(d[col].notna().all()), f"every row carries {col}")

# the index must agree with the table it describes
api = json.load(open(os.path.join(OUT, "api", "v1", "datasets.json"), encoding="utf-8"))
note(api["counts"]["estimates_in_harmonised_table"] == len(d),
     f"index count {api['counts']['estimates_in_harmonised_table']:,} == table rows {len(d):,}")
note(api["counts"]["literatures_in_harmonised_table"] == d["dataset"].nunique(),
     f"index literatures {api['counts']['literatures_in_harmonised_table']} == "
     f"table {d['dataset'].nunique()}")
pooled = {x["id"] for x in api["datasets"] if x.get("in_harmonised_table")}
note(pooled == set(d["dataset"].unique()),
     "the literatures the index says are pooled are exactly those in the table")

print(f"\n{len(fails)} failure(s)")
if fails:
    for f in fails:
        print("  X " + f)
    sys.exit(1)
print("DISTRIBUTION AND INVARIANTS PASS")
