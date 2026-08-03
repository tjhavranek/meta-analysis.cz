"""Verification gate. Must print ALL CHECKS PASS before anything is published."""
import json, os, re, sys, warnings; warnings.filterwarnings("ignore")
import numpy as np, pandas as pd
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE

# In the development layout OUT is the build output. In the PUBLISHED copy there is no
# out/ -- the built files are the live tree itself -- so verify those. That makes the gate
# usable from the pre-push hook, which runs the published copy, and means it checks what
# will actually be served rather than a staging directory.
OUT=os.path.join(WORK,"out")
if not os.path.isdir(OUT):
    OUT=SITE
DV="v1"; BASE="https://meta-analysis.cz"

fail=[]; warn=[]

idx=json.load(open(os.path.join(OUT,"api",DV,"datasets.json"),encoding="utf-8"))
H=pd.read_parquet(os.path.join(OUT,"data",DV,"estimates_harmonised.parquet"))
rep=json.load(open(os.path.join(WORK,"harmonised_report.json"),encoding="utf-8"))
OVR=json.load(open(os.path.join(WORK,"overrides.json"),encoding="utf-8"))

# 1. every advertised file exists on disk
for d in idx["datasets"]:
    if not d.get("n_estimates"): continue
    for kind,url in (d["files"] or {}).items():
        if not url: continue
        p=os.path.join(OUT,url.replace(BASE+"/","").replace("/",os.sep))
        if not os.path.exists(p): fail.append(f"{d['id']}: advertised {kind} missing on disk ({url})")

# 1b. source_file points into site/, not into the build output. A dataset read from
# inside a zip must advertise the ZIP: site/euro/trade_meta.dta does not exist.
# This is a real 404 class that only shows up after deploy, so it is checked here.
import urllib.parse
for d in idx["datasets"]:
    u=d.get("source_file")
    if not u or not u.startswith(BASE+"/"): continue
    rel=urllib.parse.unquote(u[len(BASE)+1:])
    if not os.path.exists(os.path.join(SITE,rel.replace("/",os.sep))):
        fail.append(f"{d['id']}: source_file 404s ({rel})")
    if d.get("source_member") and not rel.lower().endswith(".zip"):
        fail.append(f"{d['id']}: source_member set but source_file is not a zip ({rel})")

# 2. no index.html anywhere under api/ or data/  (generate_seo.py would ingest it as a paper)
for root in ("api","data"):
    for dp,_,fs in os.walk(os.path.join(OUT,root)):
        if "index.html" in fs: fail.append(f"index.html present under {root}/ -> would be indexed as a paper")

# 3. parquet and csv agree
for d in idx["datasets"]:
    if not d.get("n_estimates") or not (d["files"] or {}).get("csv"): continue
    pq=pd.read_parquet(os.path.join(OUT,"data",DV,d["id"],f"{d['id']}.parquet"))
    cs=pd.read_csv(os.path.join(OUT,"data",DV,d["id"],f"{d['id']}.csv"),low_memory=False)
    if len(pq)!=len(cs): fail.append(f"{d['id']}: parquet {len(pq)} vs csv {len(cs)} rows")
    if pq.shape[1]!=cs.shape[1]: fail.append(f"{d['id']}: parquet {pq.shape[1]} vs csv {cs.shape[1]} cols")

# 4. harmonised table integrity
if H["se"].le(0).any(): fail.append("harmonised: non-positive standard errors present")
if H[["effect","se"]].isna().any().any(): fail.append("harmonised: null effect or se present")
bad=(H["t_stat"]-H["effect"]/H["se"]).abs().gt(1e-6).sum()
if bad: fail.append(f"harmonised: t_stat != effect/se on {bad} rows")
dups=H.duplicated(subset=["dataset","estimate_id"]).sum()
if dups: fail.append(f"harmonised: {dups} duplicate (dataset, estimate_id) keys")

# 4b. NO TWO LITERATURES MAY CARRY THE SAME ESTIMATES.
# Several projects on this site are two papers written on one dataset (eis/substitution,
# alphas/hedge). Keeping both silently double counts, and it is invisible in every other
# check: row counts, t-statistics and reconciliation all look perfectly normal.
import itertools
sig={}
for ds,g in H.groupby("dataset"):
    sig[ds]=set(zip(np.round(g["effect"].astype(float),8), np.round(g["se"].astype(float),8)))
for a,b in itertools.combinations(sorted(sig),2):
    sa,sb=sig[a],sig[b]
    if not sa or not sb: continue
    small,large=(sa,sb) if len(sa)<=len(sb) else (sb,sa)
    ov=len(small&large)/len(small)
    if ov>0.90:
        fail.append(f"{a} and {b} share {ov:.0%} of their (effect,se) pairs — "
                    f"same estimates in two literatures, double counting")
    elif ov>0.35:
        # A partial overlap is the same defect wearing a disguise: two papers on one
        # literature, one of them an extension of the other. It must be ruled on
        # explicitly in overrides.json, not left as a warning somebody scrolls past.
        ruled = any((OVR.get(x) or {}).get("alias_of") or (OVR.get(x) or {}).get("overlap_ok")
                    for x in (a,b))
        (warn if ruled else fail).append(
            f"{a}/{b}: {ov:.0%} of (effect,se) pairs shared — same literature twice? "
            f"Rule on it in overrides.json (alias_of, or overlap_ok to accept)")

# 4c. Unit violations and implausible sample sizes. Both were found by a bird's-eye
# review that every structural check had passed, so they are gates now.
for ds,g in H.groupby("dataset"):
    un=(g["effect_units"].dropna().iloc[0] if g["effect_units"].notna().any() else "")
    if "partial correlation" in str(un).lower():
        bad_r=int((g["effect"].abs()>1).sum())
        if bad_r:
            warn.append(f"{ds}: {bad_r} effect(s) outside [-1,1] but labelled a partial correlation "
                        f"(max |{g['effect'].abs().max():.3f}|) — source coding error, must be documented")
    n=g["n_obs"].dropna()
    if len(n) and (n<=1).any():
        warn.append(f"{ds}: {int((n<=1).sum())} rows with n_obs <= 1 — not a plausible sample size; "
                    f"n_obs may be mis-mapped or carry a missing-value code")

# 4d. A direction_note that contradicts the data it describes. The `size` note claimed
# positive meant the premium while 76% of its effects are negative, and the note on the
# SAME estimates under `trust` said the opposite. Cheap to check, embarrassing to miss.
_u=json.load(open(os.path.join(WORK,"units.json"),encoding="utf-8")) if \
   os.path.exists(os.path.join(WORK,"units.json")) else {}
for ds,g in H.groupby("dataset"):
    note=((_u.get(ds) or {}).get("direction_note") or "").lower()
    if not note: continue
    neg=float((g["effect"]<0).mean())
    if neg>0.65 and re.search(r"positive means|positive =|positive indicates", note):
        fail.append(f"{ds}: direction_note says positive carries the meaning, but {neg:.0%} of "
                    f"effects are negative — the note contradicts the data")

# 5. per-dataset plausibility — a wrong (effect,se) pairing shows up as an absurd |t|
print("per-dataset |t| distribution (median, p99) — implausible values flag a bad column pair:")
for ds,g in H.groupby("dataset"):
    at=g["t_stat"].abs(); med,p99=at.median(),at.quantile(.99)
    flag=""
    if med>50 or med<0.05: flag=" <-- SUSPECT"; warn.append(f"{ds}: median |t|={med:.2f}")
    elif p99>1e4: flag=" <-- heavy tail"; warn.append(f"{ds}: p99 |t|={p99:.0f}")
    print(f"   {ds:<20} n={len(g):>6}  med|t|={med:>8.2f}  p99|t|={p99:>10.1f}{flag}")

# 6. harmonised rows reconcile with the per-dataset report
for p,v in rep["projects"].items():
    if v.get("included"):
        n=int((H["dataset"]==p).sum())
        if n!=v["n"]: fail.append(f"{p}: report says {v['n']} rows, table has {n}")

# 7. anything the report marked excluded really is absent from the table
present=set(H["dataset"])
for p,v in rep["projects"].items():
    if not v.get("included") and p in present:
        fail.append(f"{p}: marked excluded ({v['reason']}) but present in harmonised table")
# and every included project actually made it in
for p,v in rep["projects"].items():
    if v.get("included") and p not in present:
        fail.append(f"{p}: marked included but absent from harmonised table")

print(f"\ndatasets in index: {idx['counts']['datasets']} | "
      f"source rows: {idx['counts']['rows_in_source_files']:,} | "
      f"analysis samples: {idx['counts']['estimates_in_analysis_samples']:,}")
print(f"harmonised: {len(H):,} rows, {H['dataset'].nunique()} literatures, {len(H.columns)} columns")
if warn:
    print(f"\n{len(warn)} WARNING(S):")
    for w in warn: print("   ! "+w)
if fail:
    print(f"\n{len(fail)} FAILURE(S):")
    for f in fail: print("   X "+f)
    sys.exit(1)
print("\nALL CHECKS PASS")
