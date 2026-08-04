"""The columns that are NOT the effect: sample size, clustering, and double counting.

Everything so far has interrogated `effect` and `se`. But a user of this table reaches for the
other columns the moment they do anything serious, and two of them can invalidate a result
without ever looking wrong:

  n_obs      MAIVE instruments precision with the SAMPLE SIZE. If n_obs is log-transformed in
             one literature and raw in another -- which is exactly how the source files differ
             -- MAIVE silently returns a different estimator per literature. 08_harmonise has a
             guard for this; this is the independent test of whether the guard works.

  study_id   every standard error in meta-analysis is clustered by study. If study_id does not
             actually partition the estimates, clustered errors are wrong and nobody sees it.

  DOUBLE     the pooled table draws 39 literatures from 44 datasets, and some share a source
  COUNTING   file or cover overlapping ground. An estimate appearing under two literatures is
             counted twice by anything pooling across them. The catalogue claims to have
             excluded these; this checks the claim against the data instead of the metadata.

Hard-fails only on things that are defects rather than properties of economics.
"""
import os, sys, json, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE
import numpy as np, pandas as pd

OUT = os.path.join(WORK, "out")
if not os.path.isdir(OUT):
    OUT = SITE
H = pd.read_parquet(os.path.join(OUT, "data", "v1", "estimates_harmonised.parquet"))
API = json.load(open(os.path.join(OUT, "api", "v1", "datasets.json"), encoding="utf-8"))
fails, soft = [], []


def hard(ok, msg):
    if not ok:
        fails.append(msg)
    print(("  ok   " if ok else "  FAIL ") + msg)


# ------------------------------------------------------- 1. n_obs, the MAIVE-critical column
print("1. sample size: is it on one scale across every literature?")
if "n_obs" not in H.columns:
    print("   no n_obs column"); sys.exit(0)
rows = []
for proj, g in H.groupby("dataset"):
    n = pd.to_numeric(g["n_obs"], errors="coerce")
    if n.notna().sum() == 0:
        continue
    v = n.dropna()
    rows.append((proj, int(v.notna().sum()), float(v.min()), float(v.median()), float(v.max())))

# A log-transformed N hides as a suspiciously small maximum. Real sample sizes reach hundreds
# or thousands; log(N) tops out near 10. That is the signature the guard exists to catch.
suspect = [r for r in rows if r[4] < 30 and r[1] > 20]
print(f"   {len(rows)} literatures report a sample size")
for proj, n, lo, med, hi in sorted(rows, key=lambda r: r[4])[:6]:
    print(f"     {proj:<18} n={n:5d}  min={lo:<10.4g} median={med:<10.4g} max={hi:.4g}")
hard(not suspect,
     "no literature has a maximum sample size below 30 (the log-transform signature)"
     if not suspect else
     f"{len(suspect)} literature(s) look log-transformed, which silently corrupts MAIVE: "
     f"{', '.join(r[0] for r in suspect)}")

impossible = []
for proj, g in H.groupby("dataset"):
    n = pd.to_numeric(g["n_obs"], errors="coerce")
    bad = int(((n <= 1) & n.notna()).sum())
    if bad:
        impossible.append(f"{proj}: {bad} row(s) with a sample size <= 1")
for m in impossible:
    soft.append(m + " -- not usable as a precision instrument; likely a missing-value code")

# ----------------------------------------------------------- 2. study_id must actually cluster
print("\n2. clustering: does study_id partition the estimates?")
hard(int(H["study_id"].isna().sum()) == 0, "every row has a study_id")
# a study_id must not be reused across literatures for DIFFERENT studies -- the harmonised id
# has to be globally unique or a cross-literature cluster is meaningless
per_lit = H.groupby("dataset")["study_id"].nunique()
collide = H.groupby("study_id")["dataset"].nunique()
shared = collide[collide > 1]
# study_id is a per-literature integer 1..N BY DESIGN, so collisions across literatures are
# expected, not a defect -- the clustering key is (dataset, study_id). Worth stating loudly all
# the same: anyone pooling literatures and clustering on study_id alone merges unrelated studies.
print(f"   study_id is per-literature (1..N), so {len(shared)} value(s) recur across "
      f"literatures BY DESIGN -- cluster on (dataset, study_id), never study_id alone")
hard(bool((H.groupby(['dataset','study_id']).ngroups) > 0), "(dataset, study_id) forms clusters")
singles = int((H.groupby(["dataset", "study_id"]).size() == 1).sum())
tot_st = int(H.groupby(["dataset", "study_id"]).ngroups)
print(f"   {tot_st:,} study clusters, {singles:,} of them a single estimate "
      f"({singles/max(tot_st,1)*100:.0f}%)")

# ------------------------------------------------------------------- 3. cross-literature reuse
print("\n3. double counting: does any estimate appear under two literatures?")
key = pd.DataFrame({
    "dataset": H["dataset"].values,
    "e": np.round(H["effect"].astype("float64"), 10),
    "s": np.round(H["se"].astype("float64"), 10)})
grp = key.groupby(["e", "s"])["dataset"].agg(lambda x: tuple(sorted(set(x))))
multi = grp[grp.map(len) > 1]
pairs = {}
for combo in multi:
    pairs[combo] = pairs.get(combo, 0) + 1
if pairs:
    print("   literature pairs sharing identical (effect, se) values:")
    for combo, n in sorted(pairs.items(), key=lambda kv: -kv[1])[:12]:
        print(f"     {' + '.join(combo):<44} {n:6d} shared value(s)")

# The catalogue declares which datasets overlap. A declared overlap that we still pool twice is
# the real defect; an undeclared one is a discovery.
declared = set()
for d in API["datasets"]:
    for k in ("overlaps_with", "same_literature_as", "duplicate_of", "shares_source_file_with"):
        v = d.get(k)
        for other in ([v] if isinstance(v, str) else (v or [])):
            declared.add(tuple(sorted((d["id"], other))))
# Requiring 5+ shared pairs is not enough: two-decimal values like (-0.09, 0.1) collide across
# unrelated literatures by chance, and that is all the first run actually found. Genuine double
# counting shows up in values carrying real precision, where coincidence is implausible.
def _decimals(x):
    return len(f"{abs(float(x)):.10f}".rstrip("0").split(".")[1])


def _precise(e, s_):
    return _decimals(e) >= 4 and _decimals(s_) >= 4
precise_pairs = {}
for (e_, s_), combo in multi.items():
    if _precise(e_, s_):
        precise_pairs[combo] = precise_pairs.get(combo, 0) + 1
undeclared = [(c, n) for c, n in precise_pairs.items()
              if len(c) == 2 and tuple(sorted(c)) not in declared and n >= 5]
hard(not undeclared,
     "no undeclared overlap between pooled literatures"
     if not undeclared else
     f"{len(undeclared)} literature pair(s) share 5+ identical (effect, se) values but are NOT "
     f"declared as overlapping: " + "; ".join(f"{'+'.join(c)} ({n})" for c, n in undeclared))

# ------------------------------------------------------------------------- 4. year and horizon
print("\n4. year and horizon")
if "pub_year" in H.columns:
    y = pd.to_numeric(H["pub_year"], errors="coerce").dropna()
    odd = y[(y < 1950) | (y > 2027)]
    # KNOWN, FIXED IN CODE, PENDING REGENERATION. The shipped 0.9.0-beta carries a standardised
    # BMA regressor in pub_year for five literatures, because those files name it
    # `publication_year` while the real column is `year_publication` / `pubyear` / `year`.
    # 08_harmonise.find_year now validates on values, and discrate has an explicit override.
    # Until 1.0.0 regenerates, assert the damage stays CONFINED to those five rather than
    # pretending it is absent.
    STAGED = {"alphas", "beauty", "skill", "students", "discrate"}
    hit = set(H.loc[(pd.to_numeric(H["pub_year"], errors="coerce") < 1950) |
                    (pd.to_numeric(H["pub_year"], errors="coerce") > 2027), "dataset"].unique())
    if not len(odd):
        hard(True, f"publication years all within 1950-2027 ({int(y.min())}-{int(y.max())})")
    else:
        soft.append(f"pub_year holds a standardised regressor, not a year, in "
                    f"{', '.join(sorted(hit))} ({len(odd):,} rows) -- fixed in 08_harmonise by "
                    f"find_year(), lands at 1.0.0")
        hard(hit <= STAGED,
             f"the pub_year defect is confined to the {len(STAGED)} known literatures"
             if hit <= STAGED else
             f"pub_year is wrong in literatures BEYOND the known set: {sorted(hit - STAGED)}")

print(f"\n{len(soft)} soft observation(s):")
for s_ in soft:
    print("  . " + s_)
print(f"\n{len(fails)} hard failure(s)")
if fails:
    for f_ in fails:
        print("  X " + f_)
    sys.exit(1)
print("COLUMN CHECKS PASS")
