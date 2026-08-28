"""Tier B: Parquet mirrors + per-dataset codebooks. Originals untouched."""
import json, os, re, io, zipfile, warnings, hashlib; warnings.filterwarnings("ignore")
import numpy as np, pandas as pd
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE

OUT=os.path.join(WORK,"out")
prim=json.load(open(os.path.join(WORK,"primaries.json"),encoding="utf-8"))
res=json.load(open(os.path.join(WORK,"resolved2.json"),encoding="utf-8"))
_o=os.path.join(WORK,"overrides.json")
OVR=json.load(open(_o,encoding="utf-8")) if os.path.exists(_o) else {}
inv=json.load(open(os.path.join(WORK,"inventory_raw.json"),encoding="utf-8"))

def norm(c): return re.sub(r"[^a-z0-9]+","_",str(c).strip().lower()).strip("_")

def pick_sheet(xl):
    best=None
    for sh in xl.sheet_names:
        try: d=xl.parse(sh)
        except Exception: continue
        if d.shape[0]<5 or d.shape[1]<3: continue
        un=sum(1 for c in d.columns if str(c).startswith("Unnamed") or str(c).strip()=="" or str(c).startswith("nan"))
        sc=(1-un/max(d.shape[1],1))*3+np.mean([pd.to_numeric(d[c],errors="coerce").notna().mean() for c in d.columns]) \
           +min(d.shape[0],4000)/4000+min(d.shape[1],80)/80
        if best is None or sc>best[0]: best=(sc,sh,d)
    return (best[1],best[2]) if best else (None,None)

def read_member(project, source, archive, member, sheet=None):
    p=os.path.join(SITE,project)
    if source=="loose": src,name=os.path.join(p,member),member
    else:
        z=zipfile.ZipFile(os.path.join(p,archive)); src,name=io.BytesIO(z.read(member)),member
    e=os.path.splitext(name)[1].lower()
    if e==".dta": return pd.read_stata(src,convert_categoricals=False),None
    if e==".csv": return pd.read_csv(src,low_memory=False),None
    xl=pd.ExcelFile(src)
    if sheet and sheet in xl.sheet_names: return xl.parse(sheet),sheet
    return pick_sheet(xl)

# Text that means "no value", not a value. "NA" is here because a CSV reader takes it as
# missing by default, so a Parquet that kept it as a string would disagree with the CSV of
# the same data, and there is no way to write a literal "NA" to CSV that a default reader
# reads back as text. The only column on the site that carries it is inflation's
# Affiliation_Class, whose other values are university, central_bank, mixed and other.
MISSING_TEXT = {"nan": None, "None": None, "": None, "NA": None}


def clean_for_parquet(df):
    df=df.copy()
    seen={}; cols=[]
    for c in df.columns:                                  # unique, non-empty names
        n=str(c).strip() or "col"
        n=re.sub(r"\s+"," ",n)
        if n in seen: seen[n]+=1; n=f"{n}__{seen[n]}"
        else: seen[n]=0
        cols.append(n)
    df.columns=cols
    # object -> numeric where clean, else str. Unchanged: this is what has always run for
    # the Excel-sourced files, and dropping it would turn real numeric columns into text.
    for c in df.columns:
        if df[c].dtype==object:
            num=pd.to_numeric(df[c],errors="coerce")
            if num.notna().sum()>=0.95*df[c].notna().sum() and df[c].notna().sum()>0: df[c]=num
            else: df[c]=df[c].astype(str).replace(MISSING_TEXT)
        elif str(df[c].dtype)=="str":
            # pandas 3 reads text as dtype "str", not "object", so the guard above never saw
            # the Stata-sourced columns and their string-missing ("" in the .dta) stayed in
            # the Parquet while a CSV reader saw NaN. Normalise the missing values only: the
            # numeric coercion above is deliberately not applied here, because at its 95%
            # threshold it silently turns the other 5% into NaN, which on size alone would
            # destroy 153 real values across industry, trim3, penny_stock, size_quint and
            # comment4.
            df[c]=df[c].where(~df[c].isin(list(MISSING_TEXT)), None)
    return df

VERIFIED_ROLES={"effect_estimate","standard_error"}   # set from the resolved mapping, not a guess


def df_like(df):
    """The file's degrees-of-freedom column, if it has one."""
    for c in df.columns:
        if re.match(r"^(df|dof|deg_?free\w*|degrees_?of_?freedom)$", norm(c)):
            v = pd.to_numeric(df[c], errors="coerce")
            if v.notna().sum() >= 10:
                return v
    return None


def is_sample_size(df, col):
    """Whether a column that MATCHES the n_obs name pattern really is a sample size.

    A name match is not enough for this particular role. Three columns in this corpus match
    the pattern and are not sample sizes: remittances' `Obs` is the row index, exactly 1..538,
    and its `N` is the number of countries, 1..155 -- while the estimation sample size sits in
    `Sample`, a name the pattern never matched. n_obs is the one role whose misidentification
    corrupts MAIVE's first stage silently rather than failing loudly, so it is asserted only
    when the values agree.

    The two tests are ones the file can answer about itself, in the same spirit as find_year
    and find_n_obs in the harmoniser -- match on values, not on names:

      * a row index is the sequence 1..n and carries no information about any sample;
      * a sample cannot be smaller than the degrees of freedom of the regression that
        produced the estimate, so where the file states df, the candidate must clear it.
    """
    v = pd.to_numeric(df[col], errors="coerce")
    d = v.dropna()
    if len(d) < 10:
        return False, "fewer than ten values"
    if (d < 0).any():
        return False, "negative values"
    if (d != d.round()).mean() > 0.1:
        # A sample size is a count. The usual reason a named column is not one is that it
        # holds the LOG of one, which the harmoniser exponentiates; saying so is more use to
        # a reader than saying nothing.
        return False, ("not integer-valued -- this is the log of a count (exp() of it is "
                       "whole); the harmonised table carries the exponentiated value"
                       if looks_log_series(d) else "not integer-valued")
    # the row index: every row present, exactly once, 1..n
    if len(d) == len(df) and float(d.min()) == 1 and float(d.max()) == len(df) \
            and d.nunique() == len(df):
        return False, "the row index: exactly 1..%d, one per row" % len(df)
    dfree = df_like(df)
    if dfree is not None:
        both = pd.concat([v, dfree], axis=1).dropna()
        if len(both) >= 10:
            ok = (both.iloc[:, 0] >= both.iloc[:, 1]).mean()
            if ok < 0.9:
                return False, ("smaller than the degrees of freedom on %.0f%% of rows, so it "
                               "is not the estimation sample size" % (100 * (1 - ok)))
    return True, None


def looks_log_series(d):
    """Whether a non-integer column is plausibly the log of a count."""
    import numpy as _np
    if d.empty or float(d.min()) < 0 or float(d.max()) > 25:
        return False
    e = _np.exp(d.astype(float))
    return bool((_np.abs(e - e.round()) < 0.51).mean() > 0.8)

def describe(df, roles, rejected=None):
    cb=[]
    for c in df.columns:
        s=df[c]; e=dict(name=str(c), normalized=norm(c), dtype=str(s.dtype),
                        n_missing=int(s.isna().sum()), n_unique=int(s.nunique(dropna=True)))
        if rejected and str(c) in rejected:
            # The name says sample size and the values say otherwise. Recording the reason
            # is worth more than silence: it tells a reader why the obvious column is not
            # the one to use, and stops the next reader re-deriving it.
            # the key names the role the column was proposed for and refused, so a
            # t_stat rejection does not read as an n_obs one
            e[rejected[str(c)][0]]=rejected[str(c)][1]
        r=roles.get(str(c))
        if r:
            # `role` is asserted ONLY for columns confirmed by the arithmetic test or the
            # paper's replication code. Everything else is a NAME-BASED GUESS and is labelled
            # as such: price_puzzle's idauthor was being published as an effect_estimate.
            e["role" if r in VERIFIED_ROLES else "inferred_role"]=r
            if r not in VERIFIED_ROLES:
                e["inferred_role_confidence"]="name-match only, not verified"
        if pd.api.types.is_numeric_dtype(s) and s.notna().any():
            d=s.dropna().astype(float)
            e["stats"]=dict(min=round(float(d.min()),6), p25=round(float(d.quantile(.25)),6),
                            median=round(float(d.median()),6), p75=round(float(d.quantile(.75)),6),
                            max=round(float(d.max()),6), mean=round(float(d.mean()),6),
                            sd=round(float(d.std()),6) if len(d)>1 else None)
            u=d.unique()
            if len(u)<=2 and set(np.round(u,6)).issubset({0.0,1.0}): e["binary"]=True
        elif s.notna().any():
            e["top_values"]=[str(x) for x in s.dropna().astype(str).value_counts().head(5).index]
        cb.append(e)
    return cb

os.makedirs(OUT,exist_ok=True)
manifest=[]
for proj in sorted(prim):
    r=res.get(proj,{})
    if r.get("status")=="excluded":
        manifest.append(dict(project=proj,status="excluded",reason=r["reason"])); continue
    rec=prim[proj]
    want=(OVR.get(proj) or {}).get("sheet") or r.get("sheet")
    try: df,sheet=read_member(proj,rec["source"],rec["archive"],rec["member"],want)
    except Exception as ex:
        manifest.append(dict(project=proj,status="error",reason=str(ex)[:120])); continue
    if df is None or df.empty:
        manifest.append(dict(project=proj,status="error",reason="empty")); continue
    df=clean_for_parquet(df)
    roles={}; rejected={}
    # The OVERRIDE supersedes the resolver. Reading the resolver's guess here published
    # price_puzzle's `idauthor` as an effect_estimate, because the resolver guessed it and
    # the override (a wide->long reshape onto `res`/`se`) replaced that guess entirely.
    # Where the override reshapes or computes, no raw column IS the effect, so assert none.
    ov=OVR.get(proj) or {}
    if ov.get("reshape_long") or ov.get("compute"):
        pass                                   # effect is constructed, not a column here
    else:
        eff=ov.get("effect") or (r.get("effect") if r.get("status")=="ok" else None)
        se=ov.get("se") or (None if r.get("se_derived") else
                            (r.get("se") if r.get("status")=="ok" else None))
        if eff in df.columns: roles[eff]="effect_estimate"
        if se in df.columns: roles[se]="standard_error"
        for c in (ov.get("se_mean_of") or []):
            if c in df.columns: roles[c]="standard_error"
    for c in df.columns:
        n=norm(c)
        if re.match(r"^(id_?study|study_?id|idstudy|studyid)$",n): roles.setdefault(str(c),"study_id")
        # `sample` is in the pattern because remittances calls its sample size exactly that,
        # and every candidate must then clear is_sample_size: the name proposes, the values
        # decide. Without the value test the pattern asserts a row index as a sample size.
        elif re.match(r"^(n|nobs|no_?obs|n_?obs|obs|observations|sample|sample_?size|samplesize)$",n):
            ok,why=is_sample_size(df,c)
            if ok: roles.setdefault(str(c),"n_obs")
            else: rejected[str(c)]=("not_n_obs_because", why)
        elif re.match(r"^(pub_?year|publication_?year|yearpub|publicationyear)$",n): roles.setdefault(str(c),"pub_year")
        # The name proposes, the values decide -- the same rule n_obs already follows.
        # "tstat_adj" is a 0/1 flag saying whether the t was adjusted and
        # "tstat_type_comment" is free text naming the adjustment; both matched the
        # name pattern and were published as t-statistics.
        elif re.match(r"^(t|t_?stat\w*|t_?value|tstats?)$",n):
            _s = df[c]
            if pd.api.types.is_numeric_dtype(_s) and _s.dropna().nunique() > 2:
                roles.setdefault(str(c),"t_stat")
            else:
                rejected[str(c)] = ("not_t_stat_because",
                                    "not numeric" if not pd.api.types.is_numeric_dtype(_s)
                                    else "two or fewer distinct values: a flag, not a statistic")
        elif re.match(r"^(country|idcountry)$",n): roles.setdefault(str(c),"country")
    d=os.path.join(OUT,"data","v1",proj); os.makedirs(d,exist_ok=True)
    pq=os.path.join(d,f"{proj}.parquet"); df.to_parquet(pq,index=False,compression="snappy")
    csv_path=None
    if os.path.getsize(pq) < 4_000_000:
        csv_path=os.path.join(d,f"{proj}.csv"); df.to_csv(csv_path,index=False,encoding="utf-8",lineterminator=chr(10))
    cb=os.path.join(OUT,"api","v1","codebooks"); os.makedirs(cb,exist_ok=True)
    json.dump(dict(project=proj, source_file=rec["member"], source_archive=rec["archive"],
                   source_sheet=sheet, n_rows=int(len(df)), n_columns=int(df.shape[1]),
                   columns=describe(df,roles,rejected)),
              open(os.path.join(cb,f"{proj}.json"),"w",encoding="utf-8"), indent=1)
    manifest.append(dict(project=proj,status="ok",rows=int(len(df)),cols=int(df.shape[1]),
                         parquet_bytes=os.path.getsize(pq),
                         csv_bytes=os.path.getsize(csv_path) if csv_path else None,
                         source=rec["member"],sheet=sheet))

json.dump(manifest,open(os.path.join(WORK,"convert_manifest.json"),"w",encoding="utf-8"),indent=1)
ok=[m for m in manifest if m["status"]=="ok"]
tp=sum(m["parquet_bytes"] for m in ok); tc=sum(m["csv_bytes"] or 0 for m in ok)
print(f"converted {len(ok)} datasets | {sum(m['rows'] for m in ok):,} rows")
print(f"parquet total {tp/1e6:.1f} MB | csv total {tc/1e6:.1f} MB | combined {(tp+tc)/1e6:.1f} MB")
for m in manifest:
    if m["status"]!="ok": print(f"  [{m['status']}] {m['project']}: {m.get('reason','')[:60]}")
