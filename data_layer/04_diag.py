import json, os, re, io, zipfile, warnings; warnings.filterwarnings("ignore")
import numpy as np, pandas as pd
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE

prim=json.load(open(os.path.join(WORK,"primaries.json"),encoding="utf-8"))
def load(rec):
    p=os.path.join(SITE,rec["project"])
    if rec["source"]=="loose": src,name=os.path.join(p,rec["member"]),rec["member"]
    else:
        z=zipfile.ZipFile(os.path.join(p,rec["archive"])); src,name=io.BytesIO(z.read(rec["member"])),rec["member"]
    e=os.path.splitext(name)[1].lower()
    if e==".dta": return pd.read_stata(src,convert_categoricals=False)
    if e==".csv": return pd.read_csv(src,low_memory=False)
    return pd.ExcelFile(src).parse(rec["sheet"] if rec["sheet"] else 0)

print("### 1. DUPLICATE CHECK")
for a,b in [("bma","spillovers"),("eis","substitution"),("lags","price_puzzle")]:
    try:
        da,db=load(prim[a]),load(prim[b])
        shared=[c for c in da.columns if c in db.columns]
        same=0
        for c in shared[:40]:
            x,y=pd.to_numeric(da[c],errors="coerce"),pd.to_numeric(db[c],errors="coerce")
            if len(x)==len(y) and x.notna().sum()>10 and np.allclose(x.fillna(-9e9),y.fillna(-9e9)): same+=1
        print(f"  {a} {da.shape} vs {b} {db.shape}: shared cols={len(shared)}, numerically identical={same}")
    except Exception as ex: print(f"  {a}/{b}: {ex}")

print("\n### 2. forward: is t computed against beta=1 (forward premium puzzle)?")
d=load(prim["forward"]); c,s,t=pd.to_numeric(d["Coeff"],errors="coerce"),pd.to_numeric(d["SE"],errors="coerce"),pd.to_numeric(d["t"],errors="coerce")
for lab,r in [("(b-0)/se",c/s),("(b-1)/se",(c-1)/s)]:
    m=(~r.isna())&(~t.isna()); print(f"   {lab}: match={( (r[m]-t[m]).abs()/(t[m].abs()+1) <0.05).mean():.1%}")

print("\n### 3. remittances: which coef/se pair matches t?")
d=load(prim["remittances"]); t=pd.to_numeric(d["t"],errors="coerce")
for e_,s_ in [("COEF_L","SE_L"),("COEF_S","SE_S")]:
    r=pd.to_numeric(d[e_],errors="coerce")/pd.to_numeric(d[s_],errors="coerce")
    m=(~r.isna())&(~t.isna()); print(f"   {e_}/{s_}: match={((r[m]-t[m]).abs()/(t[m].abs()+1)<0.05).mean():.1%}  n={m.sum()}")

print("\n### 4. UNRESOLVED — numeric columns available")
for p in ["activism","ews","fdi","pcc","reforms","scc","gasoline","price_puzzle","lags"]:
    try:
        d=load(prim[p])
        cands=[c for c in d.columns if pd.to_numeric(d[c],errors="coerce").notna().sum()>len(d)*0.4]
        print(f"  {p} [{prim[p]['member']}] {d.shape}: {', '.join(str(c)[:22] for c in cands[:22])}")
    except Exception as ex: print(f"  {p}: ERR {ex}")
