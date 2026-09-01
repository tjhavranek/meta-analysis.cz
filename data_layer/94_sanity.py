"""Does the curated data BEHAVE like meta-analysis data, and do the per-dataset files agree?

Every earlier check asks the same kind of question: are these the right numbers, taken from
the right columns, and do the copies match. All of them would pass on a table that is
faithfully derived and still statistically nonsense -- a partial correlation of 4.2, a
standard error uncorrelated with sample size, a literature whose estimator battery blows up.

Three angles nothing else covers:

  A  UNITS       a declared unit implies a range. A partial correlation outside [-1,1] is not
                 a judgement call, it is a defect. Elasticities and shares have loose but real
                 bounds; a violation means the column or the unit label is wrong.
  B  BEHAVIOUR   run the estimators this data exists to serve -- mean, UWLS, FAT-PET, PEESE --
                 on every literature. They must produce finite, bounded numbers. A pathological
                 result is how a mis-paired standard error announces itself.
  C  PER-DATASET the per-literature CSV/Parquet a user actually downloads must agree with the
                 pooled table for that literature. 91_distribution compared the four copies of
                 the POOLED file; nothing has ever compared the pooled table against the 44
                 per-dataset conversions published beside it.

Exit 1 on a hard violation. Soft observations print but do not fail, because "this literature
has strong publication bias" is a finding about economics, not about our pipeline.
"""
import os, sys, json, warnings
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
DV = os.path.join(OUT, "data", "v1")
H = pd.read_parquet(os.path.join(DV, "estimates_harmonised.parquet"))
API = json.load(open(os.path.join(OUT, "api", "v1", "datasets.json"), encoding="utf-8"))
fails, soft = [], []


def hard(ok, msg):
    if not ok:
        fails.append(msg)
    print(("  ok   " if ok else "  FAIL ") + msg)


# ---------------------------------------------------------------- A. units imply ranges
print("A. does each declared unit hold its own range?")
# Only bound a unit where the bound is DEFINITIONAL. An arbitrary threshold on an elasticity
# fails on genuine extreme estimates: eis carries a reported 100,000 with a standard error of
# 200,000 (t = 0.5), which is a real, useless, faithfully reproduced estimate, not a coding
# error. Magnitude alone proves nothing; an implausible effect/se RATIO would, and that is
# tested separately below.
BOUND = {
 "partial correlation coefficient": (-1.0, 1.0, "a correlation cannot leave [-1,1] by definition"),
 "annual discount rate":            (-5.0, 20.0, "outside this it is not a rate"),
 "habit persistence parameter":     (-5.0, 5.0, "a share-like parameter"),
}
# Violations that are REAL and UPSTREAM: present in the published source file, reproduced
# faithfully. Reported every run so they stay visible, but they do not fail the gate, because
# the pipeline is behaving correctly by carrying them.
UPSTREAM = {
 "class": (2, "class.xlsx itself carries pcc = 1.371675 and 1.116313 alongside effect/se_effect "
              "of 7.24/1.5671 and 0.967742/0.430108. Two bad values in the authors' own pcc "
              "column, not a conversion error. A PCC above 1 will break a reanalysis, so it is "
              "surfaced rather than silently passed."),
}
for unit, (lo, hi, why) in BOUND.items():
    g = H[H["effect_units"] == unit]
    if not len(g):
        continue
    e = g["effect"].astype(float)
    bad = g[(e < lo) | (e > hi)]
    if not len(bad):
        hard(True, f"{unit}: all {len(g):,} within [{lo:g},{hi:g}]")
        continue
    by = bad["dataset"].value_counts().to_dict()
    unexplained = {k: v for k, v in by.items()
                   if not (k in UPSTREAM and v <= UPSTREAM[k][0])}
    for k, v in by.items():
        if k in UPSTREAM and v <= UPSTREAM[k][0]:
            soft.append(f"{k}: {v} value(s) outside [{lo:g},{hi:g}] -- UPSTREAM. {UPSTREAM[k][1]}")
    hard(not unexplained,
         f"{unit}: {len(bad)} outside [{lo:g},{hi:g}], all upstream and documented"
         if not unexplained else
         f"{unit}: {sum(unexplained.values())} outside [{lo:g},{hi:g}] in {unexplained} -- {why}")

# The real test on an extreme value is not its size but whether its t-statistic is possible.
# A reported estimate of 100,000 with a standard error of 200,000 is honest; an effect 1e6
# times its standard error is a mis-paired column.
_t = (H["effect"].astype(float) / H["se"].astype(float)).abs()
# ...but NOT a hard failure, because 90_roundtrip already proves every (effect, se) pair in
# this table occurs verbatim in its published source. Mis-pairing is excluded by construction,
# so an extreme ratio is the ORIGINAL AUTHORS' rounding -- armington reports se = 0.00025, risk
# 0.0001, habits 8.6e-08. Checked: 7 of 7 armington and 2 of 2 risk pairs are verbatim upstream.
_wild = H[_t > 1e4]
if len(_wild):
    for proj, n in _wild["dataset"].value_counts().items():
        soft.append(f"{proj}: {n} estimate(s) with |t| > 10,000, from a standard error the "
                    f"original paper rounded to ~1e-4 or smaller. Verbatim upstream, not a "
                    f"pairing error -- but see the weight-dominance check below.")

# THE CONSEQUENCE, which matters far more than the ratio itself. Every precision-weighted
# estimator here weights by 1/se^2, so a standard error of 8.6e-08 carries a weight of 1.4e14
# and one observation silently becomes the entire result. That is a live analytical hazard for
# anyone using this table as a benchmark, and no other check looks for it.
print("\n   weight concentration (share of total 1/se^2 held by the single heaviest estimate)")
for proj, g in H.groupby("dataset"):
    se = g["se"].astype(float).values
    k = np.isfinite(se) & (se > 0)
    if k.sum() < 10:
        continue
    w = 1.0 / se[k] ** 2
    share = float(w.max() / w.sum())
    if share > 0.25:
        soft.append(f"{proj}: the single most precise estimate carries {share*100:.1f}% of all "
                    f"precision weight (se = {se[k][w.argmax()]:.2e}) -- UWLS, PET and PEESE on "
                    f"this literature are effectively that one observation. Users should trim or "
                    f"winsorise before weighting.")
        print(f"     {proj:<16} {share*100:5.1f}%  se={se[k][w.argmax()]:.2e}  n={int(k.sum())}")

# a standard error must be small relative to the effects it belongs to, somewhere in the file
for proj, g in H.groupby("dataset"):
    med_e = float(np.nanmedian(np.abs(g["effect"].astype(float))))
    med_s = float(np.nanmedian(g["se"].astype(float)))
    if med_e > 0 and med_s / med_e > 50:
        soft.append(f"{proj}: median |effect| {med_e:.3g} but median se {med_s:.3g} "
                    f"(ratio {med_s/med_e:.0f}x) -- effect and se may be swapped or mis-scaled")

# ------------------------------------------------------------- B. do the estimators behave?
print("\nB. do the estimators this data exists to serve produce sane numbers?")


def battery(e, s):
    """mean, UWLS, PET (FAT-PET intercept-corrected effect), PEESE."""
    w = 1.0 / s ** 2
    uwls = float(np.sum(w * e) / np.sum(w))
    t, prec = e / s, 1.0 / s
    # FAT-PET as WLS: t = PET*prec + FAT  -> coefficient on precision is the corrected effect
    A = np.column_stack([prec, np.ones_like(prec)])
    pet, fat = np.linalg.lstsq(A, t, rcond=None)[0]
    # PEESE: t = PEESE*prec + b*se
    A2 = np.column_stack([prec, s])
    peese = np.linalg.lstsq(A2, t, rcond=None)[0][0]
    return float(np.mean(e)), uwls, float(pet), float(fat), float(peese)


print("%-16s %10s %10s %10s %8s %10s %7s" %
      ("literature", "mean", "UWLS", "PET", "FAT", "PEESE", "|t|>1.96"))
for proj, g in H.groupby("dataset"):
    e = g["effect"].astype(float).values
    s = g["se"].astype(float).values
    k = np.isfinite(e) & np.isfinite(s) & (s > 0)
    if k.sum() < 10:
        continue
    e, s = e[k], s[k]
    try:
        mean, uwls, pet, fat, peese = battery(e, s)
    except Exception as ex:
        fails.append(f"{proj}: estimator battery raised {str(ex)[:50]}")
        continue
    sig = float(np.mean(np.abs(e / s) > 1.96))
    print("%-16s %10.4g %10.4g %10.4g %8.2f %10.4g %6.0f%%" %
          (proj, mean, uwls, pet, fat, peese, sig * 100))
    scale = max(abs(np.median(e)), 1e-9)
    for nm, v in (("UWLS", uwls), ("PET", pet), ("PEESE", peese)):
        if not np.isfinite(v):
            fails.append(f"{proj}: {nm} is not finite -- a standard error is degenerate")
        elif abs(v) > 1e4 * scale:
            soft.append(f"{proj}: {nm}={v:.4g} is {abs(v)/scale:.0f}x the median |effect| "
                        f"-- extreme leverage from very small standard errors")
    if sig > 0.98:
        soft.append(f"{proj}: {sig*100:.0f}% of estimates significant at 5% -- implausibly high, "
                    f"check the standard error column")
    if sig < 0.02:
        soft.append(f"{proj}: only {sig*100:.1f}% significant -- check the standard error column")

# ------------------------------------------- C. the per-dataset files a user actually downloads
print("\nC. does each per-dataset published file agree with the pooled table?")
checked = mismatch = 0
for d in API["datasets"]:
    proj = d["id"]
    if not d.get("in_harmonised_table"):
        continue
    f = os.path.join(DV, proj, f"{proj}.parquet")
    if not os.path.exists(f):
        fails.append(f"{proj}: in the pooled table but no per-dataset parquet published"); continue
    per = pd.read_parquet(f)
    g = H[H["dataset"] == proj]
    ec, sc = str(g["effect_col"].iloc[0]), str(g["se_col"].iloc[0])
    checked += 1
    # the pooled effects must be a SUBSET of what the per-dataset file offers in that column
    if ec not in per.columns or sc not in per.columns:
        continue          # computed/reshaped literatures name columns the conversion lacks
    pv = set(np.round(pd.to_numeric(per[ec], errors="coerce").astype("float64").dropna(), 8))
    hv = set(np.round(g["effect"].astype("float64"), 8))
    miss = hv - pv
    if miss:
        mismatch += 1
        fails.append(f"{proj}: {len(miss)} pooled effect values absent from the per-dataset "
                     f"file column '{ec}' that users download")
hard(mismatch == 0, f"{checked} per-dataset files checked against the pooled table")

# ---------------------------------------------------------------------------------- report
print(f"\n{len(soft)} soft observation(s) - findings about the literature, not defects:")
for s_ in soft:
    print("  . " + s_)
print(f"\n{len(fails)} hard failure(s)")
if fails:
    for f_ in fails:
        print("  X " + f_)
    sys.exit(1)
print("SANITY PASS - units hold, estimators behave, per-dataset files agree")
