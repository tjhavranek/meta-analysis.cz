"""Resolve (effect, se) numerically: the true pair satisfies effect/se == reported t."""
import json, os, re, io, zipfile, warnings
warnings.filterwarnings("ignore")
import numpy as np, pandas as pd
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE

prim = json.load(open(os.path.join(WORK, "primaries.json"), encoding="utf-8"))

def norm(c): return re.sub(r"[^a-z0-9]+", "_", str(c).strip().lower()).strip("_")

def load(rec):
    p = os.path.join(SITE, rec["project"])
    if rec["source"] == "loose":
        src, name = os.path.join(p, rec["member"]), rec["member"]
    else:
        z = zipfile.ZipFile(os.path.join(p, rec["archive"]))
        src, name = io.BytesIO(z.read(rec["member"])), rec["member"]
    ext = os.path.splitext(name)[1].lower()
    if ext == ".dta":  return pd.read_stata(src, convert_categoricals=False)
    if ext == ".csv":  return pd.read_csv(src, low_memory=False)
    return pd.ExcelFile(src).parse(rec["sheet"] if rec["sheet"] else 0)

BAD = re.compile(r"(^|_)(id|idstudy|studyid|year|pubyear|nobs|obs|n|weight|precision|"
                 r"cit|citations|impact|df|k|t|tstat|tstats|z|p|pvalue|prec|invse|"
                 r"upper|lower|bound|ub|lb|_min|_max|ci|start|end|midyear|rank|count)($|_)")
GOOD = re.compile(r"^(estimate|effect|coef\w*|beta|b|e|es|d|pcc|elasticity|alpha|"
                  r"premium|gamma|sigma|rra|eis|frisch|habit|discrate|scc|size|"
                  r"cohens_d|effect_size|est|point\w*|pe)$")

def numeric_cols(df):
    out = []
    for c in df.columns:
        s = pd.to_numeric(df[c], errors="coerce")
        if s.notna().sum() < max(10, 0.25 * len(df)): continue
        u = s.dropna().unique()
        if len(u) <= 2: continue                       # dummy
        out.append((c, s))
    return out

results = {}
for proj, rec in sorted(prim.items()):
    try: df = load(rec)
    except Exception as ex:
        results[proj] = dict(error=str(ex)[:120]); continue
    nc = numeric_cols(df)
    if not nc: results[proj] = dict(error="no numeric columns"); continue
    lookup = dict(nc)
    # reported t / z, if any
    tcol = None
    for c in df.columns:
        if re.match(r"^(t|t_?stat\w*|t_?value|tstats?|z|z_?score)$", norm(c)) and c in lookup:
            tcol = c; break
    tvals = lookup[tcol] if tcol is not None else None
    se_cands = [c for c, _ in nc if re.match(r"^(se|s_e|std_?err\w*|standard_?error|sterr)", norm(c))
                or re.search(r"(^|_)se($|_)", norm(c))]
    if not se_cands: se_cands = [c for c, _ in nc if "se" in norm(c)]
    best = None
    for s in se_cands:
        sv = lookup[s]
        if (sv.dropna() <= 0).mean() > 0.15: continue           # SEs are positive
        for e, ev in nc:
            if e == s: continue
            ne = norm(e)
            r = ev / sv.replace(0, np.nan)
            ok = r.replace([np.inf, -np.inf], np.nan).dropna()
            if len(ok) < max(10, 0.2 * len(df)): continue
            if tvals is not None:
                m = (~r.isna()) & (~tvals.isna())
                if m.sum() < 10: continue
                rel = (r[m] - tvals[m]).abs() / (tvals[m].abs() + 1)
                score = float((rel < 0.05).mean()) * 100          # hard evidence
                kind = "t_match"
            else:
                med = float(ok.abs().median())
                score = 12.0 if 0.3 <= med <= 30 else 0.0
                score += 4.0 if float(np.corrcoef(ev.dropna().abs()[:len(sv.dropna())],
                                    sv.dropna()[:len(ev.dropna().abs())])[0,1] or 0) > 0.2 else 0
                kind = "plausible"
            if GOOD.match(ne) or ne == norm(proj): score += 6
            if BAD.search(ne): score -= 8
            if re.search(r"(raw|orig)$", ne): score -= 1
            if best is None or score > best["score"]:
                best = dict(effect=str(e), se=str(s), score=round(score,2), kind=kind,
                            t_col=str(tcol) if tcol is not None else None,
                            median_abs_t=round(float(ok.abs().median()),3))
    results[proj] = best or dict(error="no viable (effect,se) pair")
    results[proj]["rows"] = int(len(df))
    results[proj]["file"] = rec["member"]

json.dump(results, open(os.path.join(WORK,"resolved.json"),"w",encoding="utf-8"), indent=1)
print("%-18s %-22s %-18s %7s %-10s %8s" % ("project","effect","se","score","evidence","med|t|"))
for p in sorted(results):
    r = results[p]
    if "error" in r: print("%-18s  !! %s" % (p, r["error"])); continue
    print("%-18s %-22s %-18s %7s %-10s %8s" % (p, r["effect"][:22], r["se"][:18],
          r["score"], r["kind"], r.get("median_abs_t")))
