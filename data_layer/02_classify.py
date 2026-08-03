"""Pick each project's primary estimate-level table and infer its core columns."""
import json, re, os
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE

recs = json.load(open(os.path.join(WORK, "inventory_raw.json"), encoding="utf-8"))

def norm(c): return re.sub(r"[^a-z0-9]+", "_", str(c).strip().lower()).strip("_")

ROLE = {
 "study_id": r"^(id_?study|study_?id|idstudy|studyid|id_?paper|paper_?id)$",
 "estimate_id":r"^(id_?est|est_?id|id_?estimate|estimate_?id|idcoeff|id_?coeff|obs_?id|id_in_study)$",
 "se":       r"^(se|s_e|std_?err\w*|standard_?error|sterr)$",
 "se_pref":  r"^(se|standard_?error|standarderror)$",
 "t_stat":   r"^(t|t_?stat\w*|t_?value|tstats?)$",
 "z_stat":   r"^(z|z_?score|z_?stat\w*)$",
 "p_value":  r"^(p|p_?value|pval)$",
 "n_obs":    r"^(n|nobs|no_?obs|n_?obs|obs|observations|sample_?size|samplesize|no_?observations)$",
 "df":       r"^(df|deg_?free\w*|degrees_?of_?freedom)$",
 "pub_year": r"^(pub_?year|publication_?year|yearpub|year_?publication|publicationyear)$",
 "study_lbl":r"^(study|paper|author|authors|label|reference|study_?name)$",
 "country":  r"^(country|countries|idcountry|country_?a)$",
 "citations":r"^(cit\w*|citations|num_?citations|google|cit_?google)$",
 "precision":r"^(precision|invse|inv_?se|inverse_?se|inverseofstandarderror)$",
 "weight":   r"^(weight|weights|sqrtweight)$",
 "pcc":      r"^(pcc|partial_?correlation|partial)$",
 "se_pcc":   r"^(se_?pcc|pcc_?se|pccse)$",
}
AUX_NAME = re.compile(r"(studies|excluded|search|classification|legend|codebook|readme|"
                      r"calibration|crises|cdec|manifest|list|refs?|biblio|appendix|"
                      r"output|result|table|figure|log|temp|tmp|sim|montecarlo)", re.I)

def roles_of(cols):
    n = [norm(c) for c in cols]
    out = {}
    for role, pat in ROLE.items():
        hits = [orig for orig, nc in zip(cols, n) if re.match(pat, nc)]
        if hits: out[role] = hits
    return out

def infer_effect(cols, se_cols):
    """Effect column: (a) SE named se_X / X_se -> X ; (b) column immediately before SE."""
    n = [norm(c) for c in cols]
    for se in se_cols:
        s = norm(se)
        for pref in ("se_", "s_e_", "std_err_", "standard_error_"):
            if s.startswith(pref):
                cand = s[len(pref):]
                if cand in n: return cols[n.index(cand)], "se_prefix"
        for suf in ("_se", "_stderr", "_standard_error"):
            if s.endswith(suf):
                cand = s[: -len(suf)]
                if cand in n: return cols[n.index(cand)], "se_suffix"
    for se in se_cols:                                   # adjacency fallback
        i = list(cols).index(se)
        if i > 0: return cols[i-1], "adjacent"
    return None, None

by_proj = {}
for r in recs:
    cols = r["columns"]
    rl = roles_of(cols)
    se_cols = rl.get("se_pref") or rl.get("se") or []
    if not se_cols:                                       # widen: any se-ish column
        se_cols = [c for c in cols if re.match(r"^(se|standard_?error)", norm(c))]
    eff, how = infer_effect(cols, se_cols) if se_cols else (None, None)
    aux = bool(AUX_NAME.search(os.path.basename(r["member"]))) or bool(r["sheet"] and AUX_NAME.search(str(r["sheet"])))
    score = (bool(rl.get("study_id")) * 3 + bool(se_cols) * 3 + bool(rl.get("n_obs")) * 2
             + bool(eff) * 3 + bool(rl.get("t_stat")) + min(r["ncols"], 60) / 60
             + min(r["rows"], 5000) / 5000 - (4 if aux else 0)
             - (1 if r["source"] == "zip" else 0))
    r2 = dict(r); r2.update(roles=rl, se_cols=se_cols, effect=eff, effect_how=how,
                            aux=aux, score=round(score, 3))
    by_proj.setdefault(r["project"], []).append(r2)

primaries, rejected = {}, {}
for p, lst in by_proj.items():
    lst.sort(key=lambda x: -x["score"])
    primaries[p] = lst[0]
    rejected[p] = lst[1:]

json.dump(primaries, open(os.path.join(WORK, "primaries.json"), "w", encoding="utf-8"), indent=1)

usable = [p for p, r in primaries.items() if r["effect"] and r["se_cols"]]
print("projects with an inferable (effect, se):", len(usable), "of", len(primaries))
print()
print("%-18s %-28s %6s %5s %-16s %-16s %-10s %s" % ("project","file","rows","cols","effect","se","N","how"))
for p in sorted(primaries):
    r = primaries[p]
    print("%-18s %-28s %6d %5d %-16s %-16s %-10s %s" % (
        p, os.path.basename(r["member"])[:28], r["rows"], r["ncols"],
        str(r["effect"])[:16], (r["se_cols"] or [""])[0][:16],
        (r["roles"].get("n_obs") or [""])[0][:10], r["effect_how"] or "-"))
