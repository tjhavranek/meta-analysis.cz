"""Tier C: harmonised estimate-level table (beta)."""
import json, os, re, warnings; warnings.filterwarnings("ignore")
import numpy as np, pandas as pd
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE

OUT=os.path.join(WORK,"out"); DV="v1"
res=json.load(open(os.path.join(WORK,"resolved2.json"),encoding="utf-8"))
man={m["project"]:m for m in json.load(open(os.path.join(WORK,"convert_manifest.json"),encoding="utf-8"))}
OVR=json.load(open(os.path.join(WORK,"overrides.json"),encoding="utf-8")) if \
    os.path.exists(os.path.join(WORK,"overrides.json")) else {}

_u=os.path.join(WORK,"units.json")
UNITS=json.load(open(_u,encoding="utf-8")) if os.path.exists(_u) else {}

def norm(c): return re.sub(r"[^a-z0-9]+","_",str(c).strip().lower()).strip("_")

# concept -> regex over normalized column names (first match wins)
MOD = {
 "study_id":    r"^(idstudy|study_?id|id_?study|studyid)$",
 "study_label": r"^(study|study_?name|paper|reference|author|authors|label)$",
 "estimate_id": r"^(idcoeff|id_?coeff|id_?est\w*|est\w*_?id|obs_?id|id_in_study)$",
 "n_obs":       r"^(nobs|no_?obs|n_?obs|obs|observations|sample_?size|samplesize|n)$",
 "df":          r"^(df|degrees_?of_?freedom)$",
 "pub_year":    r"^(pubyear|pub_?year|publication_?year|yearpub|publicationyear|year_?publication|year_?published)$",
 "citations":   r"^(citations|cit|cit_?google|num_?citations|google|cits)$",
 "impact_factor":r"^(impact|impact_?factor|if|sjr|recursiveif)$",
 "published":   r"^(published|pubpr|reviewed|pblshd)$",
 "top_journal": r"^(top|top3|top5)$",
 "country":     r"^(country|countries)$",
 "country_id":  r"^(idcountry|country_?id|countrya)$",
 "data_start":  r"^(start|startyear|start_?year|syear|first_?year)$",
 "data_end":    r"^(end|endyear|end_?year|eyear|last_?year)$",
 "data_midyear":r"^(midyear|mid_?year|avyear|avg_?year|data_?year|data_?midyear|midpoint|datyear|dat_?year)$",
 "pcc":         r"^(pcc|partial_?correlation)$",
 "se_pcc":      r"^(se_?pcc|pcc_?se|pccse)$",
 "is_usa":      r"^(usa|us|united_?states|country_?us)$",
 "is_europe":   r"^(europe|eu|country_?eur)$",
 "is_panel":    r"^(panel|paneldata|data_?panel|panel_?data)$",
 "is_cross_section":r"^(cs|crosssec|cross_?section\w*|csection|data_?cross_?section)$",
 "is_time_series":r"^(ts|timeser\w*|time_?series|tseries)$",
 "freq_annual": r"^(annual|annu|yearly)$",
 "freq_quarterly":r"^(quarterly|quart|quar)$",
 "freq_monthly":r"^(monthly|mon)$",
 "method_ols":  r"^(ols|pols|ols_?method\d?)$",
 "method_iv":   r"^(iv|tsls|2sls|sls|instrument|iv_?method\d?)$",
 "method_gmm":  r"^(gmm)$",
 "method_ml":   r"^(ml|mle|bayes)$",
 "method_fe":   r"^(fe|fixed|fixed_?effects|unit_?fixed_?effects)$",
 "horizon":     r"^(horizon|horizon_?months|irf_?horizon)$",
}
BINARY_ONLY={"is_usa","is_europe","is_panel","is_cross_section","is_time_series","freq_annual",
             "freq_quarterly","freq_monthly","method_ols","method_iv","method_gmm","method_ml",
             "method_fe","published","top_journal"}

def find(df, pat, binary=False):
    for c in df.columns:
        if re.match(pat, norm(c)):
            s=pd.to_numeric(df[c],errors="coerce")
            if binary:
                u=set(np.round(s.dropna().unique(),6))
                if not u or not u.issubset({0.0,1.0}): continue
            return c
    return None

def looks_log(s):
    """A sample-size column that is really log(N): small, and not whole numbers."""
    v=s.dropna()
    if len(v)<10: return False
    return v.max()<20 and v.median()<15 and (v==v.round()).mean()<0.9 and (v>=0).all()

YEAR_CONCEPTS = {"pub_year", "data_start", "data_end", "data_midyear"}


def find_year(df, pat):
    """Pick a column that actually holds years, not a standardised copy of them.

    The same trap as find_n_obs, and it bit five literatures. alphas, beauty, skill, students
    and discrate each ship a BMA regressor literally NAMED `publication_year` holding
    standardised values (0..3.4, or -2.5..1.4) right beside the real column, which is called
    something the pattern did not even match -- `year_publication`, `pubyear`, `year`. Name
    matching therefore picked the transformed regressor, and the published pub_year was not a
    year at all on 4,543 rows. Found by 95_columns.py.

    Match on VALUES, not names: a publication year lies between 1900 and 2030. A name match
    that fails that test returns nothing, because a null is honest and a standardised regressor
    masquerading as a year is not.
    """
    for c in df.columns:
        if not re.match(pat, norm(c)):
            continue
        v = pd.to_numeric(df[c], errors="coerce").dropna()
        if len(v) < 5:
            continue
        if 1900 <= float(v.median()) <= 2030:
            return c
    return None


def find_n_obs(df, pat):
    """Pick the primary-study sample size, not a log of it.

    Several datasets carry BOTH (discrate has sample_size=log(nobs) alongside nobs;
    exp(sample_size) reproduces nobs exactly). Taking the first name match gives the
    log, which silently corrupts anything using N as a precision instrument -- MAIVE
    above all. Prefer a genuine count; exponentiate only if a log is all there is.
    """
    cands=[]
    for c in df.columns:
        if not re.match(pat, norm(c)): continue
        s=pd.to_numeric(df[c],errors="coerce")
        if s.notna().sum()<10: continue
        cands.append((c,s))
    if not cands: return None,False
    counts=[(c,s) for c,s in cands if not looks_log(s)
            and (s.dropna()==s.dropna().round()).mean()>0.9 and s.dropna().median()>=1]
    if counts:
        counts.sort(key=lambda t:-t[1].dropna().median())
        return counts[0][0], False
    logs=[(c,s) for c,s in cands if looks_log(s)]
    if logs: return logs[0][0], True
    return cands[0][0], False

rows=[]; report={}
for proj in sorted(man):
    m=man[proj]; r=res.get(proj,{}); o=OVR.get(proj,{})
    if m["status"]!="ok": continue
    # an override with an explicit effect or a compute rule rescues a dataset the resolver could not read
    if r.get("status")!="ok" and not (o.get("effect") or o.get("compute") or o.get("exclude")): continue
    alias=o["alias_of"] if "alias_of" in o else r.get("alias_of")
    # A dataset that shares a literature with another is normally dropped whole. `trust` is
    # included instead, contributing only the estimates `size` does not already carry, so it
    # must not be caught by the alias gate. Owner's decision, 2026-08-04.
    if alias and o.get("subtract_overlap_with"):
        alias=None
    if alias:
        # `trust` is a later, LARGER collection of the same literature, not a duplicate.
        # Saying "duplicate of size" contradicted the API record and reached the page.
        exact = proj in ("hedge","substitution")
        reason = (f"duplicate of {alias}: identical estimates, row for row" if exact
                  # NOT "larger": trust is 1,613 rows against size's 1,746 (1,631 pooled).
                  # Measured 2026-08-04 by 97_exclusions.py -- state the relation, not a size
                  # claim that happens to be backwards.
                  else f"a separate collection of the same literature as {alias}; partially "
                       f"overlaps it and is excluded to avoid double counting")
        report[proj]=dict(included=False,reason=reason,alias_of=alias,exact_duplicate=exact)
        continue
    if o.get("exclude"):
        report[proj]=dict(included=False,reason=o.get("reason","excluded by override")); continue
    eff=o.get("effect") or r.get("effect"); se=o.get("se") or (None if r.get("se_derived") else r.get("se"))
    if not eff and not o.get("compute"):
        report[proj]=dict(included=False,reason="no effect column"); continue
    df=pd.read_parquet(os.path.join(OUT,"data",DV,proj,f"{proj}.parquet"))
    if o.get("reshape_long"):                 # wide horizons -> one row per (estimate, horizon)
        rs=o["reshape_long"]; parts=[]
        # DEDUPE FIRST. puzzle.xls is a HYBRID: already long on `horizon` (7 rows per impulse
        # response, horizons 3/6/12/18/36/88/99) while the price-response columns M3R/SE3... are
        # WIDE and identical across all 7. Melting the wide columns once per row therefore
        # emitted each estimate 7 times: 7,420 rows where 1,060 are distinct, 6,360 spurious
        # copies -- 11.8% of the whole pooled table. Uniform replication leaves a weighted mean
        # unchanged, which is why the estimator battery never flinched, but it overstates the
        # information count sevenfold and understates any iid standard error by sqrt(7)=2.65.
        # 90_roundtrip could not see it either: it compares SETS, so duplicates are invisible.
        # Found by the Codex audit, 2026-08-04. Only `horizon` varies within a block, so
        # dropping duplicates on every other column is exact, not a heuristic.
        if rs.get("dedupe_on_all_but"):
            keep_cols=[c for c in df.columns if c not in rs["dedupe_on_all_but"]]
            before=len(df)
            df=df.drop_duplicates(subset=keep_cols).reset_index(drop=True)
            if before!=len(df):
                print(f"   {proj}: reshape dedupe {before} -> {len(df)} source records")
        carry=[c for c in df.columns if not any(c in (a,b) for _,a,b in rs["pairs"])]
        for h,ec,sc in rs["pairs"]:
            if ec not in df.columns or sc not in df.columns: continue
            p=df[carry].copy()
            p[rs["effect_name"]]=pd.to_numeric(df[ec],errors="coerce")
            p[rs["se_name"]]=pd.to_numeric(df[sc],errors="coerce")
            p[rs["id_col"]]=h
            parts.append(p)
        df=pd.concat(parts,ignore_index=True)
        df=df[df[rs["effect_name"]].notna()&df[rs["se_name"]].notna()].reset_index(drop=True)
    for f in ([o["filter"]] if o.get("filter") else []) + (o.get("filters") or []):
        col=f["column"]                       # row filters from the paper's own replication code
        if col not in df.columns: continue
        v=pd.to_numeric(df[col],errors="coerce")
        if "in" in f:      df=df[v.isin(f["in"])]
        if "not_in" in f:  df=df[~v.isin(f["not_in"])]
        if "max_abs" in f: df=df[v.abs()<=f["max_abs"]]
        if "str_not_in" in f:                    # string-valued exclusions
            df=df[~df[col].astype(str).isin(f["str_not_in"])]
        if "finite" in f and f["finite"]:
            df=df[np.isfinite(pd.to_numeric(df[col],errors="coerce"))]
        df=df.reset_index(drop=True)
    ev=r.get("evidence","") or ""
    tcol=o.get("t_col") or (ev.split(":",1)[1] if ev.startswith(("t_match:","se_derived_from:")) else None)
    se_derived=False
    cmp_=o.get("compute")
    if cmp_ and cmp_.get("type")=="rescale_from_t":
        # activism: the raw Estimate column mixes scales across studies (some studies
        # report decimals, some percentage points) and the paper rebuilds a comparable
        # column as Estimate * 100 * Multiplicator. That adjusted column is not in the
        # published file -- the analysis workbook it lives in was never released -- so it
        # is reconstructed here from the two columns that ARE published.
        base=pd.to_numeric(df[cmp_["col"]],errors="coerce")
        fac=pd.to_numeric(df[cmp_["factor_col"]],errors="coerce")
        e=base*cmp_.get("constant",1.0)*fac
        tv=pd.to_numeric(df[cmp_["t_col"]],errors="coerce").replace(0,np.nan)
        s=(e/tv).abs()
        eff=f'rescaled({cmp_["col"]}x{cmp_.get("constant",1)}x{cmp_["factor_col"]})'
        se=f'derived:|{eff}/{cmp_["t_col"]}|'; se_derived=True
    elif cmp_ and cmp_.get("type")=="pcc_from_t":
        # Stanley-Doucouliagos partial correlation: r = t/sqrt(t^2+df), se_r = sqrt((1-r^2)/df)
        tv=pd.to_numeric(df[cmp_["t_col"]],errors="coerce")
        dv=pd.to_numeric(df[cmp_["df_col"]],errors="coerce").where(lambda x:x>0)
        e=tv/np.sqrt(tv**2+dv); s=np.sqrt((1-e**2)/dv)
        eff=f"pcc_from({cmp_['t_col']},{cmp_['df_col']})"
        se=f"se_pcc_from({cmp_['df_col']})"; se_derived=True
        if cmp_.get("outlier_rule")=="reforms":
            # reform.do caps extreme t-statistics and drops a hand-flagged "strange
            # observations" set defined on the COMPUTED partial correlation, so the
            # rule cannot be expressed as a plain column filter. Reproduces the 245
            # short-run coefficients the paper reports.
            rg=pd.to_numeric(df["rg"],errors="coerce") if "rg" in df.columns else None
            odd=((1/s)>15)&(e>0.3)&(tv<12)
            keep_extra=(tv<12)&(~odd.fillna(False))
            if rg is not None: keep_extra&=(rg!=0)
            e=e.where(keep_extra); s=s.where(keep_extra)
    elif eff not in df.columns:
        report[proj]=dict(included=False,reason=f"effect '{eff}' absent"); continue
    else:
        e=pd.to_numeric(df[eff],errors="coerce")
        if o.get("se_mean_of"):                 # house_prices: SE = (SE_l + SE_u)/2, per house.do
            parts=[pd.to_numeric(df[c],errors="coerce") for c in o["se_mean_of"] if c in df.columns]
            s=pd.concat(parts,axis=1).mean(axis=1); se="mean:"+"+".join(o["se_mean_of"])
            # This SE is CONSTRUCTED -- averaged from two confidence-bound columns -- so it must
            # say so. It was the one derived standard error in the table still flagged
            # se_is_derived=False, which told a user it came straight from the source file.
            # Found by the Fable audit, 2026-08-04.
            se_derived=True
        elif se and se in df.columns and not str(se).startswith("<derived"):
            s=pd.to_numeric(df[se],errors="coerce")
        elif tcol and tcol in df.columns:
            s=(e/pd.to_numeric(df[tcol],errors="coerce").replace(0,np.nan)).abs()
            se=f"derived:|{eff}/{tcol}|"; se_derived=True
        else:
            report[proj]=dict(included=False,reason="no usable standard error"); continue
    s=s.where(s>0)
    keep=e.notna()&s.notna()
    if keep.sum()<5: report[proj]=dict(included=False,reason=f"only {int(keep.sum())} usable rows"); continue
    # float64 BEFORE deriving. Stata sources give float32, and t_stat/precision computed
    # in float32 then stored as float64 do not reproduce effect/se exactly -- a user who
    # recomputes gets a different number in the 8th digit. Immaterial for any estimator,
    # but a derived column should be exactly derivable. Affected climate, euro,
    # resource_curse; caught by 91_distribution.py.
    out=pd.DataFrame({"dataset":proj,
                      "effect":e[keep].astype("float64").values,
                      "se":s[keep].astype("float64").values})
    out["t_stat"]=out["effect"]/out["se"]
    out["precision"]=1.0/out["se"]
    n_obs_was_log=False
    for concept,pat in MOD.items():
        if concept=="n_obs" and concept not in o:
            col,n_obs_was_log=find_n_obs(df,pat)
        elif concept in YEAR_CONCEPTS and concept not in o:
            col=find_year(df,pat)
        else:
            col=o.get(concept) if concept in o else find(df,pat,binary=concept in BINARY_ONLY)
        if col and col in df.columns:
            v=df[col][keep]
            if concept in ("study_label","country"):
                t=v.astype(str).str.strip()
                out[concept]=t.mask(t.isin(["nan","None","NaN","","<NA>","."])).values
            else:
                vals=pd.to_numeric(v,errors="coerce")
                if concept=="n_obs" and n_obs_was_log:
                    vals=np.exp(vals)          # stored as log(N); publish N
                if concept=="n_obs":
                    # A sample size is a count. Exponentiating a log left values like
                    # 971.0000000000003, which is wrong on its face and differs in the last
                    # digit between BLAS builds, so the released table was not byte-reproducible.
                    vals=vals.round()
                out[concept]=vals.values
        else: out[concept]=np.nan
    if out["study_id"].isna().all() and "study_label" in out:
        out["study_id"]=pd.factorize(out["study_label"])[0]+1
    out["estimate_id"]=out.groupby("dataset").cumcount()+1
    _sub=o.get("subtract_overlap_with")
    if _sub:
        _twin=pd.concat([q for q in rows if str(q["dataset"].iloc[0])==_sub], ignore_index=True)               if any(str(q["dataset"].iloc[0])==_sub for q in rows) else None
        if _twin is None:
            raise SystemExit(f"{proj}: subtract_overlap_with='{_sub}' but '{_sub}' has not been "
                             f"built yet -- it must be processed first")
        _have=set(zip(np.round(_twin["effect"].astype("float64"),8),
                      np.round(_twin["se"].astype("float64"),8)))
        _mine=list(zip(np.round(out["effect"].astype("float64"),8),
                       np.round(out["se"].astype("float64"),8)))
        _keep=np.array([pr not in _have for pr in _mine])
        print(f"   {proj}: subtracting overlap with {_sub} -> {int(_keep.sum())} of {len(out)} "
              f"estimates are unique and kept")
        out=out[_keep].reset_index(drop=True)
    out["source_file"]=m["source"]; out["effect_col"]=eff; out["se_col"]=se
    out["se_is_derived"]=se_derived
    out["effect_units"]=(UNITS.get(proj) or {}).get("units") or o.get("units")
    rows.append(out)
    # len(out), NOT keep.sum(): with subtract_overlap_with the frame is filtered AFTER the keep
    # mask, so the pre-subtraction count would be reported and 09_verify would flag the mismatch.
    report[proj]=dict(included=True,n=int(len(out)),effect=eff,se=se,se_is_derived=se_derived,
                      n_obs_col=col if False else None, n_obs_from_log=bool(n_obs_was_log),
                      units=(UNITS.get(proj) or {}).get("units"),
                      direction_note=(UNITS.get(proj) or {}).get("direction_note"),
                      n_studies=int(pd.Series(out["study_id"]).nunique()),
                      moderators=int(sum(1 for c in MOD if out[c].notna().any())))

H=pd.concat(rows,ignore_index=True)
front=["dataset","study_id","estimate_id","study_label","effect","se","t_stat","precision",
       "n_obs","df","pcc","se_pcc","pub_year","citations","impact_factor","published","top_journal",
       "country","country_id","is_usa","is_europe","data_start","data_end","data_midyear",
       "is_panel","is_cross_section","is_time_series","freq_annual","freq_quarterly","freq_monthly",
       "method_ols","method_iv","method_gmm","method_ml","method_fe","horizon",
       "effect_units","source_file","effect_col","se_col","se_is_derived"]
H=H[[c for c in front if c in H.columns]]
d=os.path.join(OUT,"data",DV); os.makedirs(d,exist_ok=True)
H.to_parquet(os.path.join(d,"estimates_harmonised.parquet"),index=False,compression="snappy")
H.to_csv(os.path.join(d,"estimates_harmonised.csv"),index=False,encoding="utf-8",lineterminator=chr(10))
json.dump(dict(n_rows=int(len(H)),n_datasets=int(H["dataset"].nunique()),
               columns=list(H.columns),projects=report),
          open(os.path.join(WORK,"harmonised_report.json"),"w",encoding="utf-8"),indent=1)

inc=[p for p,v in report.items() if v["included"]]
print(f"HARMONISED: {len(H):,} estimates | {H['dataset'].nunique()} literatures | {len(H.columns)} columns")
print(f"parquet {os.path.getsize(os.path.join(d,'estimates_harmonised.parquet'))/1e6:.1f} MB | "
      f"csv {os.path.getsize(os.path.join(d,'estimates_harmonised.csv'))/1e6:.1f} MB\n")
cov=[(c,H[c].notna().mean()) for c in H.columns]
print("coverage of harmonised moderators:")
for c,f in cov:
    if c in MOD or c in ("effect","se","t_stat"): print(f"   {f*100:5.1f}%  {c}")
print("\nEXCLUDED:")
for p,v in sorted(report.items()):
    if not v["included"]: print(f"   {p}: {v['reason']}")
