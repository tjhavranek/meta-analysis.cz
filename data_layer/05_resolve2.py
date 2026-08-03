"""Resolver v2: better sheet choice, validated t-column, SE derivable from t."""
import json, os, re, io, zipfile, warnings; warnings.filterwarnings("ignore")
import numpy as np, pandas as pd
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE

# not estimate-level meta-analysis data -> excluded from the harmonised table
EXCLUDE = {"ews":"country-level crisis database, not extracted estimates",
           "pcc":"Google Scholar search listing, not extracted estimates",
           "conference":"conference programme", "guidelines":"no dataset",
           "maive":"Bartos et al. cross-field archive (external), not a Havranek literature"}
# duplicate literatures: keep -> drop
ALIAS = {"spillovers":"bma", "substitution":"eis", "price_puzzle":"lags"}

def norm(c): return re.sub(r"[^a-z0-9]+","_",str(c).strip().lower()).strip("_")

def pick_sheet(xl):
    best=None
    for sh in xl.sheet_names:
        try: d=xl.parse(sh)
        except Exception: continue
        if d.shape[0]<5 or d.shape[1]<3: continue
        unnamed=sum(1 for c in d.columns if str(c).startswith("Unnamed") or str(c).strip()=="" or str(c).startswith("nan"))
        clean=1-unnamed/max(d.shape[1],1)
        numden=np.mean([pd.to_numeric(d[c],errors="coerce").notna().mean() for c in d.columns])
        score=clean*3+numden+min(d.shape[0],4000)/4000+min(d.shape[1],80)/80
        if best is None or score>best[0]: best=(score,sh,d)
    return (best[1],best[2]) if best else (None,None)

def load(rec):
    p=os.path.join(SITE,rec["project"])
    if rec["source"]=="loose": src,name=os.path.join(p,rec["member"]),rec["member"]
    else:
        z=zipfile.ZipFile(os.path.join(p,rec["archive"])); src,name=io.BytesIO(z.read(rec["member"])),rec["member"]
    e=os.path.splitext(name)[1].lower()
    if e==".dta": return pd.read_stata(src,convert_categoricals=False),None
    if e==".csv": return pd.read_csv(src,low_memory=False),None
    sh,d=pick_sheet(pd.ExcelFile(src)); return d,sh

def numeric(df):
    out={}
    for c in df.columns:
        s=pd.to_numeric(df[c],errors="coerce")
        if s.notna().sum()<max(8,0.2*len(df)): continue
        if len(s.dropna().unique())<=2: continue
        out[c]=s
    return out

def find_t(df,num):
    """A t column must (a) be named like one and (b) NOT be a panel dimension."""
    cands=[]
    for c in df.columns:
        n=norm(c)
        if not re.match(r"^(t|t_?stat\w*|t_?value|tstats?|z|z_?score|zscore)$",n): continue
        if c not in num: continue
        v=num[c].dropna()
        # panel time dimension: small positive integers, coexists with an N column
        if n=="t" and (v>=0).all() and (v==v.round()).mean()>0.95 and v.max()<200 \
           and any(re.match(r"^(n|nobs|obs|sample_?size)$",norm(x)) for x in df.columns):
            continue
        cands.append(c)
    return cands

prim=json.load(open(os.path.join(WORK,"primaries.json"),encoding="utf-8"))
GOOD=re.compile(r"^(estimate|effect|coef\w*|beta|b|e|es|d|pcc|elasticity|alpha|premium|gamma|"
                r"sigma|rra|eis|frisch|habit|discrate|scc|size|cohens_d|effect_size|est|pe|rg|lib)$")
BAD=re.compile(r"(^|_)(id|idstudy|studyid|idcountry|year|pubyear|nobs|obs|weight|precision|cit|"
               r"citations|impact|df|k|upper|lower|bound|ub|lb|start|end|midyear|rank|count|"
               r"page|volume|number|multiplicator)($|_)")

out={}
for proj,rec in sorted(prim.items()):
    if proj in EXCLUDE: out[proj]=dict(status="excluded",reason=EXCLUDE[proj]); continue
    try: df,sheet=load(rec)
    except Exception as ex: out[proj]=dict(status="error",reason=str(ex)[:100]); continue
    if df is None: out[proj]=dict(status="error",reason="no usable sheet"); continue
    num=numeric(df); tcols=find_t(df,num)
    ses=[c for c in num if re.search(r"(^|_)(se|std_?err\w*|standard_?error)($|_)",norm(c))
         and (num[c].dropna()<=0).mean()<0.15]
    best=None
    for s in ses:
        for e,ev in num.items():
            if e==s: continue
            ne=norm(e); r=(ev/num[s].replace(0,np.nan)).replace([np.inf,-np.inf],np.nan)
            if r.notna().sum()<max(8,0.2*len(df)): continue
            sc=0.0; kind="plausible"
            for tc in tcols:
                m=r.notna()&num[tc].notna()
                if m.sum()<8: continue
                f=float(((r[m]-num[tc][m]).abs()/(num[tc][m].abs()+1)<0.05).mean())
                if f*100>sc: sc,kind=f*100,f"t_match:{tc}"
            if kind=="plausible":
                med=float(r.abs().median()); sc=12.0 if 0.3<=med<=30 else 0.0
            if GOOD.match(ne) or ne==norm(proj): sc+=6
            if BAD.search(ne): sc-=8
            if best is None or sc>best["score"]:
                best=dict(effect=str(e),se=str(s),score=round(sc,2),evidence=kind,
                          se_derived=False,median_abs_t=round(float(r.abs().median()),3))
    # no SE column: derive se = |effect / t|
    if best is None and tcols:
        for tc in tcols:
            for e,ev in num.items():
                ne=norm(e)
                if norm(tc)==ne or BAD.search(ne): continue
                if not (GOOD.match(ne) or ne==norm(proj)): continue
                der=(ev/num[tc].replace(0,np.nan)).abs()
                if der.notna().sum()<max(8,0.2*len(df)): continue
                best=dict(effect=str(e),se=f"<derived: |{e}/{tc}|>",score=9.0,
                          evidence=f"se_derived_from:{tc}",se_derived=True,
                          median_abs_t=round(float(num[tc].abs().median()),3)); break
            if best: break
    out[proj]=dict(status="ok" if best else "unresolved", file=rec["member"], sheet=sheet,
                   rows=int(len(df)), ncols=int(df.shape[1]),
                   alias_of=ALIAS.get(proj), **(best or {}))

json.dump(out,open(os.path.join(WORK,"resolved2.json"),"w",encoding="utf-8"),indent=1)
ok=[p for p,r in out.items() if r["status"]=="ok"]
print(f"resolved: {len(ok)} | excluded: {sum(1 for r in out.values() if r['status']=='excluded')} "
      f"| unresolved: {sum(1 for r in out.values() if r['status']=='unresolved')} "
      f"| error: {sum(1 for r in out.values() if r['status']=='error')}")
print(f"duplicates flagged: {len([p for p in ok if out[p]['alias_of']])}\n")
print("%-18s %-20s %-20s %7s %-22s" % ("project","effect","se","score","evidence"))
for p in sorted(out):
    r=out[p]
    if r["status"]!="ok": print("%-18s  [%s] %s" % (p,r["status"],r.get("reason","")[:52])); continue
    print("%-18s %-20s %-20s %7s %-22s%s" % (p,r["effect"][:20],r["se"][:20],r["score"],
          r["evidence"][:22], "  DUP->"+r["alias_of"] if r["alias_of"] else ""))
