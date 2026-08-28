"""Verification gate. Must print ALL CHECKS PASS before anything is published."""
import html as html_mod
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

# 1c. every paper URL the catalogue advertises is a page that exists, and its page_title is
# that page's actual <title>. The HTML gates check the HTML; nothing checked the machine layer,
# and three defects lived there at once: excluded_resources pointed at /ews/, a directory with
# no index.html, so the catalogue's only dead link was the one handle that record had; and
# spillovers_bias carried a page_title no page on the site uses. A consumer keying either
# field against the site fails silently.
_TITLE_RE = re.compile(r"<title>(.*?)</title>", re.S | re.I)
for d in idx["datasets"] + idx.get("excluded_resources", []):
    pap = d.get("paper") or {}
    u = pap.get("url")
    if not u:
        continue
    if not u.startswith(BASE + "/"):
        fail.append(f"{d['id']}: paper.url is not on this site ({u})")
        continue
    page = os.path.join(SITE, u[len(BASE) + 1:].replace("/", os.sep), "index.html")
    if not os.path.isfile(page):
        fail.append(f"{d['id']}: paper.url has no page ({u})")
        continue
    if pap.get("page_title"):
        m = _TITLE_RE.search(open(page, encoding="utf-8", errors="replace").read())
        got = html_mod.unescape(re.sub(r"\s+", " ", m.group(1)).strip()) if m else None
        if got and got != pap["page_title"]:
            fail.append("%s: page_title is not the page's <title>\n"
                        "        record: %s\n        page:   %s" % (d["id"], pap["page_title"], got))

# 1d. one DOI, one title. The pages emit citation_title and api/v1/papers.json carries its own,
# and they were allowed to disagree on the two flagship papers, so a crawler got two title
# strings for one DOI -- the defect 517a121 set out to close, still open one layer down.
_pj = os.path.join(OUT, "api", DV, "papers.json")
if os.path.isfile(_pj):
    _pp = json.load(open(_pj, encoding="utf-8"))
    _pp = _pp.get("papers", _pp) if isinstance(_pp, dict) else _pp
    # Two records may share a DOI on purpose, and then they are not two titles for one
    # document. A SUPPLEMENT is cited by the article it belongs to, so it carries that
    # article's DOI and its own name. A WORKING PAPER entry cites the article it became --
    # crisis_ews and crisis_jfs both carry the JFS DOI, on the owner's instruction to keep
    # both pages -- and names its own, earlier title, with a version_note saying which is
    # which. Neither is the defect this looks for: one PUBLISHED record, two title strings.
    _by_doi = {}
    for r in _pp:
        if not (r.get("doi") and r.get("title")):
            continue
        if (r.get("document_type") not in (None, "paper")
                or r.get("parent") or r.get("parent_label")
                or r.get("version") == "working_paper"):
            continue
        _by_doi.setdefault(r["doi"], set()).add(r["title"])
    for _d, _ts in _by_doi.items():
        if len(_ts) > 1:
            fail.append("two titles for one DOI in papers.json (%s): %s" % (_d, " | ".join(sorted(_ts))))
    for r in _pp:
        _page = r.get("full_text_url") or ""
        if not (r.get("doi") and _page.startswith(BASE + "/")):
            continue
        _f = os.path.join(SITE, _page[len(BASE) + 1:].replace("/", os.sep), "index.html")
        if not os.path.isfile(_f):
            continue
        _m = re.search(r'name="citation_title" content="([^"]*)"',
                       open(_f, encoding="utf-8", errors="replace").read())
        if _m and html_mod.unescape(_m.group(1)) != r["title"]:
            fail.append("%s: papers.json title and the page's citation_title differ\n"
                        "        api:  %s\n        page: %s"
                        % (r.get("project"), r["title"], html_mod.unescape(_m.group(1))))

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
        # >= 1, not > 1. A correlation of exactly +/-1 beside a finite standard error is as
        # impossible as one of 1.372, and both come from the same upstream defect: inverting
        # pcc = t/sqrt(t^2 + df) on these rows returns df <= 0, because the sample size entered
        # the source's own transform as missing. Testing only > 1 disclosed 2 rows and hid 73.
        bad_r=int((g["effect"].abs()>1).sum()); at_one=int((g["effect"].abs()==1).sum())
        if bad_r or at_one:
            bits=[]
            if bad_r:  bits.append(f"{bad_r} outside [-1,1] (max |{g['effect'].abs().max():.3f}|)")
            if at_one: bits.append(f"{at_one} at exactly +/-1")
            warn.append(f"{ds}: {' and '.join(bits)} but labelled a partial correlation "
                        f"— source coding error, must be documented")
    n=g["n_obs"].dropna()
    if len(n) and (n<=1).any():
        warn.append(f"{ds}: {int((n<=1).sum())} rows with n_obs <= 1 — not a plausible sample "
                    f"size on its face; check this dataset's sample_size_note and direction_note "
                    f"in datasets.json, which say what the column is, before assuming a defect")

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

# The documentation publishes a publication-bias count computed from this very table. A
# hand-computed number in published prose is one dataset revision away from being quietly
# wrong, and a reader cannot check it, so it is recomputed here and disagreement is a
# failure like any other.
import subprocess as _sp
_claim = _sp.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                               "98_fat_claim.py")],
                 capture_output=True, text=True)
if _claim.returncode != 0:
    fail.append("the publication-bias counts in api/v1/README.md no longer match the data:\n"
                + "        " + (_claim.stdout or _claim.stderr).strip().replace("\n", "\n        "))

# Nothing else here asks whether the catalogue is COMPLETE -- every other check tests the
# data that is present. A file no surface names produces no inconsistency, so it can only be
# caught by scanning the site itself. Same delegation as the claim check above.
_cat = _sp.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                             "98_catalogue_complete.py")],
               capture_output=True, text=True)
if _cat.returncode != 0:
    fail.append("the catalogue does not account for every file the site serves:\n"
                + "        " + (_cat.stdout or _cat.stderr).strip().replace("\n", "\n        "))

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
