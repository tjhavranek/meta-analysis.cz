"""Tier A+D: static JSON API — datasets index, Frictionless datapackage, Croissant."""
import collections, json, os, re, warnings; warnings.filterwarnings("ignore")
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE

OUT=os.path.join(WORK,"out"); BASE="https://meta-analysis.cz"
VERSION="1.0.0"; DATA_V="v1"
# The DATA artefact's version, in ONE place. It was hardcoded in four, which is how a
# consumer once saw the Croissant record say 1.0.0 while the table said 0.9.0-beta.
DATA_VERSION="1.1.1"; DATA_STATUS="stable"
# The VERSION DOI, set once Zenodo minted it. None until deposited -- publishing the
# previous version's DOI beside a new version tells a citing reader the wrong thing.
DATA_DOI="10.5281/zenodo.22050272"   # 1.1.1 version DOI, reserved on the Zenodo draft and embedded
                                  # before the bundle was built, so the archived files name it.

papers={p["project"]:p for p in json.load(open(os.path.join(SITE,"tools","papers.json"),encoding="utf-8"))}
man={m["project"]:m for m in json.load(open(os.path.join(WORK,"convert_manifest.json"),encoding="utf-8"))}
res=json.load(open(os.path.join(WORK,"resolved2.json"),encoding="utf-8"))
def _load(n):
    q=os.path.join(WORK,n)
    return json.load(open(q,encoding="utf-8")) if os.path.exists(q) else {}
UNITS=_load("units.json"); OVR=_load("overrides.json"); PRIM=_load("primaries.json")
try:
    harm=json.load(open(os.path.join(WORK,"harmonised_report.json"),encoding="utf-8"))
    harm.setdefault("version",DATA_VERSION)
except Exception: harm={"projects":{},"n_rows":None,"columns":[]}

import pandas as _pd
try: _H=_pd.read_parquet(os.path.join(OUT,"data",DATA_V,"estimates_harmonised.parquet"))
except Exception: _H=None
_NH=(_H.groupby("dataset").size().to_dict() if _H is not None else {})


def _weight_share():
    """Share of total 1/se^2 held by the single most precise estimate, per literature.

    Every precision-weighted estimator this collection exists to serve -- UWLS, PET, PEESE,
    MAIVE -- weights by 1/se^2, so one estimate whose standard error the original paper rounded
    to 8.6e-08 carries a weight of 1.4e14 and silently BECOMES the result. Three literatures
    here are effectively a single observation under such weighting. A user comparing estimators
    on this table needs to know that before they read anything into the comparison, so it is
    published per dataset rather than left to be rediscovered. Found by 94_sanity.py.
    """
    if _H is None:
        return {}
    import numpy as _np
    out={}
    for proj,g in _H.groupby("dataset"):
        se=_pd.to_numeric(g["se"],errors="coerce").astype("float64").values
        k=_np.isfinite(se)&(se>0)
        if k.sum()<10: continue
        w=1.0/se[k]**2
        out[proj]=round(float(w.max()/w.sum()),4)
    return out


_WS=_weight_share()

def claimed_n(pap):
    """How many estimates the paper itself says it uses."""
    t=((pap or {}).get("one_line") or "")+" "+((pap or {}).get("abstract") or "")
    m=re.search(r"([\d,]{3,})\s+estimates",t)
    return int(m.group(1).replace(",","")) if m else None

# Which literatures actually received a domain review, and which rest on the
# arithmetic pairing alone. Published as a field so users can filter on review
# quality instead of reading prose. The arithmetic test proves an (effect, se)
# PAIRING; it cannot tell a headline estimand from a robustness one.
DOMAIN_REVIEWED = {"activism","gasoline","frisch","dst","electricity","excess_sensitivity",
                   "discrate","learning","eis","incentives","habits","reforms",
                   "lags","price_puzzle","climate","house_prices","forward",
                   "fdi","scc","bma","spillovers",
                   # No replication code exists for gasoline_price, so it was reviewed against
                   # the paper's published results directly: our means reproduce the twofold
                   # exaggeration its abstract reports, and the long/short-run ordering. That is
                   # a domain review, not a code trace. See overrides.gasoline_price.verified_by.
                   "gasoline_price"}

def _audit_status(proj):
    o=OVR.get(proj) or {}; r=res.get(proj) or {}
    # `trust` shares a literature with `size` but is now INCLUDED, contributing only the
    # estimates size does not carry, so the alias must not mark it excluded.
    if o.get("alias_of") and not o.get("subtract_overlap_with"): return "duplicate_excluded"
    if o.get("exclude"):  return "excluded_no_precision"
    # An explicit declaration then wins over every inference below -- but NOT over the two
    # exclusions above, which are structural facts about whether the dataset is in the table
    # at all, not judgements about how well its mapping is evidenced.
    # `verified_by` normally means the paper's code was read, and promotes to code_traced; a
    # mapping can be recorded there for another reason. finance_growth's was settled by
    # identifying the rival column as tstat/sepcc, not by reading replication code, and
    # letting it inherit code_traced would say the estimand had been confirmed when it has not.
    if o.get("audit_status"): return o["audit_status"]
    # A reviewed literature that needed NO change has no override. Absence of an
    # override is evidence it passed, not evidence it was never looked at.
    if proj in DOMAIN_REVIEWED: return "domain_reviewed"
    # A staged, known defect outranks the evidence: a literature whose verified_by records
    # that we ship the WRONG estimand must not be promoted to code_traced on the strength of
    # the evidence that condemns it. No override carries this flag today -- remittances was
    # the one that did, and it was resolved -- so the branch is dormant, not dead: it is the
    # mechanism for the next such case. Prefer an explicit `audit_status` for new ones.
    if o.get("pending_1_0_0"): return "arithmetic_pairing_only"
    if o.get("verified_by"): return "code_traced"
    ev=(r.get("evidence") or "")
    if ev.startswith("t_match:") and (r.get("score") or 0)>=90: return "arithmetic_pairing_only"
    return "unresolved"

# Two projects can share one source FILE while being different literatures
# (bma/spillovers take the horizontal and vertical halves of one FDI database;
# lags/price_puzzle use different columns of one monetary-policy database).
# That is NOT duplication and must not be reported as it.
SHARED_SOURCE = {"bma":"spillovers", "spillovers":"bma",
                 "lags":"price_puzzle", "price_puzzle":"lags"}

# `duplicate_of` is reserved for genuinely identical data (hedge == alphas, row for row).
# `trust` is the LATER (2026 vs 2019) but SMALLER collection of the same literature -- 1,613 rows
# against size's 1,746 -- overlapping it on 83.5% of its usable pairs. From 1.0.0 it is INCLUDED,
# contributing only the estimates size does not carry, so it is not excluded at all.
EXACT_DUPLICATES = {"hedge", "substitution"}

def _overlap_fields(proj, r):
    o = OVR.get(proj) or {}
    alias = o["alias_of"] if "alias_of" in o else r.get("alias_of")
    if not alias:
        return dict(duplicate_of=None, overlaps_with=None, same_literature_as=None,
                    excluded_to_avoid_double_counting=False)
    exact = proj in EXACT_DUPLICATES
    return dict(duplicate_of=(alias if exact else None),
                overlaps_with=alias,
                same_literature_as=alias,
                # true only for the collections actually held out of the table; `trust`
                # overlaps `size` but contributes the estimates size does not carry
                excluded_to_avoid_double_counting=exact,
                overlap_kind=("identical row for row" if exact
                              else "same literature, partially overlapping collections"))

def _core_cols(proj):
    o=OVR.get(proj) or {}; r=res.get(proj) or {}
    cmp_=o.get("compute")
    if cmp_ and cmp_.get("type")=="pcc_from_t":
        return dict(effect=f"partial correlation computed from {cmp_['t_col']} and {cmp_['df_col']}",
                    standard_error=f"computed as sqrt((1-r^2)/{cmp_['df_col']})",
                    standard_error_note="derived, not read from a column", evidence="paper's replication code")
    if cmp_ and cmp_.get("type")=="rescale_from_t":
        return dict(effect=f"{cmp_['col']} rescaled by {cmp_.get('constant',1)} x {cmp_['factor_col']}",
                    standard_error=f"derived as |effect/{cmp_['t_col']}|",
                    standard_error_note="derived, not read from a column", evidence="paper's replication code")
    eff=o.get("effect") or r.get("effect")
    se=o.get("se") or (None if r.get("se_derived") else r.get("se"))
    if o.get("se_mean_of"): se="mean of "+" and ".join(o["se_mean_of"])
    return dict(effect=eff, standard_error=se,
                standard_error_note=(r.get("se") if r.get("se_derived") and not se else None),
                # Same trap as _audit_status: verified_by normally means the code was read,
                # but it can record a mapping settled another way. An explicit `evidence`
                # declaration wins, so the catalogue cannot claim a source it does not have.
                evidence=(o.get("evidence") or
                          ("paper's replication code" if o.get("verified_by") else r.get("evidence"))))

def _recon_note(proj,pap):
    """Explain a gap between the abstract's count and the pooled rows.

    A smaller count is often CORRECT: several papers collect N estimates but analyse
    a documented subset, and we reproduce the subset by applying their own filters.
    Saying "fewer than the paper reports" there would imply a defect that is not one.
    """
    ovr_note=(OVR.get(proj) or {}).get("reconciliation_note")
    if ovr_note: return ovr_note
    c,n=claimed_n(pap),_NH.get(proj)
    if not (c and n): return None
    if n==c: return "matches the paper exactly"
    d=n-c
    if (OVR.get(proj) or {}).get("filters") or (OVR.get(proj) or {}).get("compute"):
        return (f"{d:+d} rows against the abstract's count, and correctly so: the paper's own replication "
                f"code restricts to an analysis subset, reproduced here. See column_mapping_verified_by.")
    if d > 0:
        return (f"{d:+d} rows MORE than the abstract states. The abstract's figure may count studies or a "
                f"sub-sample differently; the published file is the source of truth here. Unexplained.")
    return (f"{d:+d} rows against the paper's count, usually because the published file has no usable "
            f"standard error on the remainder. See this dataset's note and column_mapping_verified_by.")

def doi_of(p):
    u=(p or {}).get("doi_or_publisher_url") or ""
    m=re.search(r"(10\.\d{4,9}/[^\s\"'<>]+)",u)
    return "https://doi.org/"+m.group(1) if m else (u or None)

def published_title(p):
    """The title the journal printed.

    papers.json carries two names on purpose: `title` is a DISPLAY string written to match
    what someone would type into a search box, and it becomes the page's <title>; where it
    differs from what the journal printed, `citation_title` holds the real one. 21 of the 54
    differ. In THIS file every `title` we emit sits inside a record that means "the paper" --
    beside its authors, its journal and its DOI -- so it has to be the published one. A record
    that pairs an invented title with a real DOI is a claim about the literature, not a label,
    and it is the form of the error that propagates: Frictionless `sources` is a citation
    slot, Google Dataset Search reads croissant, and datasets.json tells a reader to "cite the
    paper named in this entry".
    """
    p=p or {}
    return p.get("citation_title") or p.get("title")

datasets=[]
for proj in sorted(man):
    m=man[proj]; r=res.get(proj,{}); pap=papers.get(proj,{})
    if m["status"]!="ok":
        datasets.append(dict(id=proj,status=m["status"],reason=m.get("reason"),
                             paper=dict(title=published_title(pap),page_title=pap.get("title"),
                                        url=f"{BASE}/{proj}/"))); continue
    d=dict(
      id=proj,
      # Three names, and each column takes the one it means. `title` is what the journal
      # printed; `page_title` is the search-facing string that is also the page's <title>;
      # `literature` is the short noun phrase naming the body of primary studies, which is
      # what a column headed "Literature" should carry.
      paper=dict(title=published_title(pap), page_title=pap.get("title"),
                 literature=pap.get("literature") or pap.get("title"),
                 authors=pap.get("authors"), year=pap.get("year"),
                 journal=pap.get("journal"), doi=doi_of(pap), url=f"{BASE}/{proj}/"),
      description=pap.get("one_line") or None,
      n_estimates=m["rows"], n_variables=m["cols"],
      # m["rows"] is rows in the published FILE. Where two papers share one file
      # (bma/spillovers take the horizontal and vertical halves of one FDI database)
      # that number belongs to neither literature on its own, so also expose the
      # count after the paper's own filters.
      n_estimates_in_literature=(_NH.get(proj) if _NH.get(proj) else m["rows"]),
      # A dataset extracted from a zip must advertise the ZIP, not the member path:
      # site/euro/trade_meta.dta does not exist, site/euro/data.zip does.
      source_file=(f"{BASE}/{proj}/{(PRIM.get(proj) or {}).get('archive')}"
                   if (PRIM.get(proj) or {}).get("source")=="zip"
                   else f"{BASE}/{proj}/{m['source']}"),
      source_member=((PRIM.get(proj) or {}).get("member")
                     if (PRIM.get(proj) or {}).get("source")=="zip" else None),
      source_sheet=m.get("sheet"),
      files=dict(
        parquet=f"{BASE}/data/{DATA_V}/{proj}/{proj}.parquet",
        csv=f"{BASE}/data/{DATA_V}/{proj}/{proj}.csv" if m.get("csv_bytes") else None,
        codebook=f"{BASE}/api/{DATA_V}/codebooks/{proj}.json"),
      # Must report the mapping ACTUALLY USED. An override supersedes the resolver, and
      # reporting the resolver's guess here advertised `cohens_d` for incentives while the
      # harmonised table used `pcc` — a machine-readable lie.
      core_columns=_core_cols(proj),
      effect_units=((UNITS.get(proj) or {}).get("units") or (OVR.get(proj) or {}).get("units")),
      direction_note=(UNITS.get(proj) or {}).get("direction_note"),
      column_mapping_verified_by=(OVR.get(proj) or {}).get("verified_by"),
      in_harmonised_table=bool((harm.get("projects",{}).get(proj) or {}).get("included")),
      reconciliation=dict(
        n_estimates_reported_in_paper=claimed_n(pap),
        n_rows_in_harmonised_table=_NH.get(proj),
        note=_recon_note(proj,pap)),
      excluded_from_harmonised_because=(None if (harm.get("projects",{}).get(proj) or {}).get("included")
                                        else (harm.get("projects",{}).get(proj) or {}).get("reason")),
      **_overlap_fields(proj, r),
      shares_source_file_with=SHARED_SOURCE.get(proj),
      # Owner's decision, 2026-08-03: EVERYTHING here is CC BY 4.0, the underlying research
      # data included, and he takes responsibility for the grant. (The comment that used to sit
      # here said the opposite -- that rights in the data were not ours to grant -- which was
      # the pre-reversal policy and contradicted the line below it. Do not reinstate it.)
      rights_status="cc-by-4.0",
      license_url="https://creativecommons.org/licenses/by/4.0/",
      rights_note=("CC BY 4.0. Free to use, adapt, and redistribute, including commercially "
                   "and including as training data. The only condition is credit: cite the "
                   "paper named in this entry."),
      # See _weight_share(): how much of this literature's precision weight sits on one estimate.
      max_precision_weight_share=_WS.get(proj),
      audit_status=_audit_status(proj))
    if d["duplicate_of"]:
        d["note"]=((OVR.get(proj) or {}).get("note")
                   or f"Same estimates as '{d['duplicate_of']}'; excluded from the harmonised "
                      f"table to avoid double counting.")
    elif d["shares_source_file_with"]:
        d["note"]=((OVR.get(proj) or {}).get("note")
                   or f"Shares a source FILE with '{d['shares_source_file_with']}' but uses different "
                      f"columns or rows. A distinct literature, NOT a duplicate, and pooled on its own.")
    datasets.append(d)

# Records with no data are not datasets. Iterating .datasets[] used to hand a consumer three
# entries with no files, rights, codebook or audit status, while counts.datasets promised 44.
excluded=[dict(id=d["id"], reason=d.get("reason"), paper=d.get("paper"),
               excluded_because="examined and not an estimate-level dataset")
          for d in datasets if not d.get("n_estimates")]
datasets=[d for d in datasets if d.get("n_estimates")]
ok=datasets
# No $schema key: there is no JSON Schema document for this index, and the URL that
# used to be advertised here 404s. An unresolvable $schema is worse than none — it
# tells a validator to fetch something that is not there.
index=dict(
  name="meta-analysis.cz data API", version=VERSION,
  # `version` is the API/descriptor version and clients may already read it, so it is
  # left alone. These two say which is which, because croissant.json carries the DATA
  # version and the two disagreeing looked like a defect.
  api_version=VERSION,
  data_version=(harm.get("version") or DATA_VERSION),
  version_note=("version and api_version describe this INTERFACE. data_version describes the "
                "harmonised table, and is what croissant.json reports. They move independently."),
  description=("Estimate-level datasets from meta-analyses in economics and the social sciences, "
               "with the hand-coded study characteristics collected for each paper."),
  license=dict(
    id="CC-BY-4.0",
    url="https://creativecommons.org/licenses/by/4.0/",
    terms=f"{BASE}/LICENSE",
    applies_to="everything on this site",
    note=("Everything here is CC BY 4.0: the research datasets, their CSV and Parquet "
          "conversions, the harmonised table, the index, the codebooks, the documentation "
          "and the deposited PDFs. Free to use, adapt, and redistribute, including commercially "
          "and including as training data for machine-learning models. The only condition is "
          "credit: cite the collection, and cite the paper whose dataset you used."),
    machine_readable=True),
  cite_as=("Havranek, T. and Z. Irsova (2026). meta-analysis.cz: harmonised estimate-level data "
           "from meta-analyses in economics. Zenodo. https://doi.org/10.5281/zenodo.21773678"),
  # The VERSION DOI is minted by Zenodo when the new version is published, so it cannot be
  # known at build time. Publishing the previous version's DOI here would tell a citing reader
  # that the 1.0.0 table is 0.9.0-beta. Null until minted; the concept DOI below always resolves
  # to the newest version and is the one to cite.
  doi=DATA_DOI, doi_url=(f"https://doi.org/{DATA_DOI}" if DATA_DOI else None),
  concept_doi="10.5281/zenodo.21773678", concept_doi_url="https://doi.org/10.5281/zenodo.21773678",
  doi_note=("Cite the CONCEPT DOI in prose - it always resolves to the newest version. "
            "Cite the version DOI in a replication package, where you need the exact files."),
  endpoints={
    "datasets":f"{BASE}/api/{DATA_V}/datasets.json",
    "codebook":f"{BASE}/api/{DATA_V}/codebooks/{{id}}.json",
    "datapackage":f"{BASE}/api/{DATA_V}/datapackage.json",
    "croissant":f"{BASE}/api/{DATA_V}/croissant.json",
    "harmonised_parquet":f"{BASE}/data/{DATA_V}/estimates_harmonised.parquet",
    "harmonised_csv":f"{BASE}/data/{DATA_V}/estimates_harmonised.csv",
    "headline_estimates":f"{BASE}/estimates.csv"},
  # THREE different numbers, all correct, previously conflated into one. The catalogue
  # sums to the middle one, so advertising only the first made ~4,000 estimates look lost.
  counts=dict(
    datasets=len(ok),
    rows_in_source_files=sum(d["n_estimates"] for d in ok),
    estimates_in_analysis_samples=sum(d.get("n_estimates_in_literature") or d["n_estimates"] for d in ok),
    estimates_in_harmonised_table=(harm.get("n_rows") or 0),
    literatures_in_harmonised_table=(harm.get("n_datasets") or 0),
    in_harmonised_table=sum(1 for d in ok if d["in_harmonised_table"]),
    counts_explained=(f"rows_in_source_files counts every row of the {len(ok)} converted files. "
                      "estimates_in_analysis_samples applies each paper's own filters and is what "
                      "the catalogue table shows. estimates_in_harmonised_table additionally drops "
                      "literatures that duplicate another exactly, overlap one already "
                      "included, or lack per-estimate precision.")),
  harmonised_table=dict(
    version=DATA_VERSION, status=DATA_STATUS,
    n_rows=harm.get("n_rows"), n_literatures=harm.get("n_datasets"),
    columns=harm.get("columns"),
    parquet=f"{BASE}/data/{DATA_V}/estimates_harmonised.parquet",
    csv=f"{BASE}/data/{DATA_V}/estimates_harmonised.csv",
    notes=[
      "One row per harmonised OBSERVATION, pooled across literatures. Some literatures contribute "
      "several horizon-specific observations per underlying estimate: price_puzzle reshapes wide "
      "impulse-response columns into one row per horizon, and house_prices ships ~7 horizons per "
      "impulse response. Do not treat rows as independent estimates without checking `horizon`.",
      "Raw effect levels are not comparable across literatures; see effect_units. Analyse within "
      "each literature. Comparing across them needs an explicitly standardised measure, and "
      "relative changes are meaningful only where the baseline is safely away from zero.",
      "Moderator columns are populated only where the source dataset recorded them; check for nulls.",
      "source_file, effect_col and se_col identify the origin of every value, so any row can be "
      "traced to the published dataset and checked.",
      "se_is_derived marks rows whose standard error was reconstructed rather than read directly.",
      "Column mappings were resolved arithmetically (effect/se must reproduce the reported "
      "t-statistic) and, where that was not decisive, taken from the paper's own replication code.",
      # DERIVED from DATA_STATUS, never hardcoded. This note said "Beta:" while
      # harmonised_table.status in the SAME object said "stable" -- a consumer reading one field
      # got the opposite of a consumer reading the other. The citation advice below is good
      # regardless of maturity; only the label was wrong.
      (("Beta: the harmonisation may be revised. " if DATA_STATUS == "beta"
        else "The harmonisation may still be revised. ") +
       "For a reference that does not move, cite the "
       "archived deposit https://doi.org/10.5281/zenodo.21773678 , the concept DOI, which always "
       "resolves to the newest archived version and carries checksums.")],
    excluded={p:v.get("reason") for p,v in (harm.get("projects") or {}).items()
              if not v.get("included")}),
  counts_note=("`datasets` contains exactly counts.datasets entries, all of them real datasets. "
               "Inputs that were examined and excluded live in `excluded_resources`."),
  excluded_resources=excluded,
  datasets=datasets)

api=os.path.join(OUT,"api",DATA_V); os.makedirs(api,exist_ok=True)
json.dump(index,open(os.path.join(api,"datasets.json"),"w",encoding="utf-8"),indent=1,ensure_ascii=False)

# Frictionless Data Package

def _harmonised_fields():
    """Column types for the pooled CSV, inferred from ALL of it.

    A hardcoded list of text columns got `source_file` and `se_is_derived` wrong, so types
    are read from the data. That read the first 5,000 rows only -- and the table is ordered
    by literature, so nine columns (df, pcc, se_pcc, data_start, data_end, is_panel,
    method_ml, method_fe, horizon) had no value in that window at all. They were typed
    "number" by the [True] default and happened to be numeric in the rows nobody looked at.
    Reading all 49,669 costs nothing.

    A column with no value ANYWHERE is declared string: nothing observed, nothing asserted.
    A value counts as numeric only if Table Schema would accept it -- nan, inf and 1_0 are
    not, though float() takes all three.
    """
    import csv as _csv, math as _math
    path=os.path.join(OUT,"data",DATA_V,"estimates_harmonised.csv")
    try:
        with open(path,encoding="utf-8",newline="") as fh:
            r=_csv.reader(fh); head=next(r)
            numeric=[True]*len(head); seen=[False]*len(head)
            for row in r:
                for j,v in enumerate(row[:len(head)]):
                    if v=="" or not numeric[j]: continue
                    seen[j]=True
                    try: f=float(v)
                    except ValueError: numeric[j]=False; continue
                    if _math.isnan(f) or _math.isinf(f) or "_" in v: numeric[j]=False
    except Exception as e:
        WARNINGS.append(f"harmonised schema: cannot read {path} ({type(e).__name__}); the "
                        f"datapackage resource would ship without a schema -- run 08_harmonise.py")
        return []
    return [dict(name=c, type=("number" if (numeric[j] and seen[j]) else "string"))
            for j,c in enumerate(head)]


# `version` is the DATA PACKAGE version, per the Frictionless standard: its own versioning
# recipe says to bump it when data resources are added or existing data is corrected. It is
# NOT an interface version. This shipped VERSION (the site's API-interface number) here, so
# a conforming client read the 1.1.0 package as 1.0.0. api_version keeps the interface
# concept as a custom property, which the spec permits.
dp=dict(profile="tabular-data-package", name="meta-analysis-cz",
        version=(harm.get("version") or DATA_VERSION),
        api_version=VERSION, data_version=(harm.get("version") or DATA_VERSION),
        title="meta-analysis.cz estimate-level datasets",
        # Package-level `licenses` IS set, deliberately. Under Frictionless semantics it
        # covers every resource, which is what the owner decided on 2026-08-03: he holds the
        # sublicensing authority and takes responsibility for the grant. This comment used to
        # say the opposite -- it predates that reversal and contradicted the line below it,
        # and the count it quoted (44 resources) is now 46.
        licenses=[dict(name="CC-BY-4.0", path="https://creativecommons.org/licenses/by/4.0/",
                       title="Creative Commons Attribution 4.0 International")],
        description=("Everything in this package is CC BY 4.0, including the data each resource "
                     "points to. Free to use, adapt, and redistribute, including commercially and "
                     "as training data. Credit is the only condition: cite the paper named on "
                     "each resource. See " + BASE + "/LICENSE."),
        homepage=BASE, resources=[])
for d in ok:
    try: cb=json.load(open(os.path.join(OUT,"api",DATA_V,"codebooks",f"{d['id']}.json"),encoding="utf-8"))
    except Exception: continue
    # `description` is OMITTED when there is no verified role. Emitting it as null made
    # every one of the 3,257 role-less fields a schema violation ("None is not of type
    # 'string'"), and the reference validator refused the whole descriptor over it.
    fields=[]
    for c in cb["columns"]:
        _f=dict(name=c["name"],
                type=("number" if c["dtype"].startswith(("float","int")) else "string"))
        if c.get("role"): _f["description"]=c["role"]
        fields.append(_f)
    if d["files"]["csv"]:
        dp["resources"].append(dict(name=d["id"], path=d["files"]["csv"], format="csv",
                                    # the package declares itself tabular-data-package, which
                                    # obliges every resource to declare this in turn
                                    profile="tabular-data-resource",
                                    mediatype="text/csv", schema=dict(fields=fields),
                                    title=(d["paper"] or {}).get("title"),
                                    licenses=[dict(name="CC-BY-4.0", path="https://creativecommons.org/licenses/by/4.0/")],
                                    rights_status=d.get("rights_status"),
                                    sources=[{"title": (d["paper"] or {}).get("title"),
                                              "path": (d["paper"] or {}).get("doi")
                                                      or (d["paper"] or {}).get("url")}],
                                    description=("Format conversion of the dataset published "
                                                 "with this paper. CC BY 4.0; cite the paper.")))
# The harmonised table is the flagship artifact and was described by neither machine
# description of the collection. It is labelled unmistakably as a DERIVED aggregate that
# overlaps the per-dataset resources, so nobody sums it together with them.
dp["resources"].append(dict(
    name="estimates_harmonised", profile="tabular-data-resource",
    path=f"{BASE}/data/{DATA_V}/estimates_harmonised.csv", format="csv", mediatype="text/csv",
    title="Harmonised estimate-level table (derived)",
    description=("DERIVED AGGREGATE VIEW, not an additional dataset. Every row here also appears in "
                 "one of the per-dataset resources above, reshaped to a common schema. Do not "
                 "sum this resource together with them, and note that literatures which "
                 "duplicate another, overlap one already included, or carry no per-estimate "
                 "standard error are absent."),
    licenses=[dict(name="CC-BY-4.0", path="https://creativecommons.org/licenses/by/4.0/")],
    schema=dict(fields=_harmonised_fields())))
json.dump(dp,open(os.path.join(api,"datapackage.json"),"w",encoding="utf-8"),indent=1,ensure_ascii=False)

def _sha256(path):
    import hashlib
    h=hashlib.sha256()
    with open(path,"rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""): h.update(chunk)
    return h.hexdigest()


def _harmonised_parquet_types():
    """(name, Croissant dataType) read from the PARQUET's own schema.

    The RecordSet's source is the parquet, so its types must come from the parquet. Typing
    them from the CSV instead declared se_is_derived (a bool) as Text and study_id /
    estimate_id (int64) as Float -- a consumer extracting as declared would have been told
    the wrong thing. The datapackage keeps CSV-inferred types, correctly: its resource IS
    the CSV, which has no types of its own.
    """
    path = os.path.join(OUT, "data", DATA_V, "estimates_harmonised.parquet")
    try:
        import pyarrow.parquet as _pq
        sch = _pq.ParquetFile(path).schema_arrow
    except Exception:
        # No parquet to read: fall back to the CSV inference rather than emit nothing.
        return [(f["name"], "sc:Float" if f["type"] == "number" else "sc:Text")
                for f in _harmonised_fields()]
    out = []
    for nm, ty in zip(sch.names, sch.types):
        t = str(ty)
        out.append((nm, "sc:Boolean" if t == "bool"
                    else "sc:Integer" if t.startswith("int") or t.startswith("uint")
                    else "sc:Float" if t.startswith(("float", "double", "decimal"))
                    else "sc:Text"))
    return out


def _digest(path):
    """sha256 + contentSize for a local file, or nothing. Written as a helper because the
    harmonised FileObjects were added as inline dicts and so skipped _file_object() and its
    hashing entirely -- a FileObject with no digest fails any consumer that verifies."""
    if not os.path.exists(path):
        return {}
    return {"sha256": _sha256(path), "contentSize": str(os.path.getsize(path))}


def _file_object(d):
    """A real digest or no digest. Croissant defines sha256 as the file's actual hash;
    the string 'see codebook' sat there before, which fails any consumer that verifies."""
    rel=d["files"]["parquet"].replace(BASE+"/","")
    lp=os.path.join(OUT, rel.replace("/", os.sep))
    fo={"@type":"cr:FileObject","@id":d["id"]+".parquet","name":d["id"]+".parquet",
        "contentUrl":d["files"]["parquet"],
        "encodingFormat":"application/vnd.apache.parquet"}
    if os.path.exists(lp):
        fo["sha256"]=_sha256(lp); fo["contentSize"]=str(os.path.getsize(lp))
    return fo

def _record_set(d):
    """Fields from the dataset's own codebook. A RecordSet with no fields tells a consumer
    nothing, which is what made the earlier record standards-shaped but unusable."""
    rs={"@type":"cr:RecordSet","@id":d["id"],"name":d["id"],
        "description":(d["paper"] or {}).get("title")}
    if (d["paper"] or {}).get("doi"): rs["isBasedOn"]=d["paper"]["doi"]
    try:
        cb=json.load(open(os.path.join(OUT,"api",DATA_V,"codebooks",f"{d['id']}.json"),encoding="utf-8"))
    except Exception:
        return rs
    fields=[]
    # `normalized` collapses case and punctuation, so two distinct source columns can
    # normalise to one string. That made the @id non-unique inside a RecordSet, which is
    # invalid JSON-LD: a strict Croissant loader merges or drops one column of the pair.
    # Suffix the collisions instead, keeping the first occurrence's id stable.
    _seen=collections.Counter()
    for c in cb["columns"]:
        _base=f"{d['id']}/{c['normalized']}"
        _seen[_base]+=1
        _fid=_base if _seen[_base]==1 else f"{_base}_{_seen[_base]}"
        f={"@type":"cr:Field","@id":_fid,"name":c["name"],
           "dataType":("sc:Float" if c["dtype"].startswith("float")
                       else "sc:Integer" if c["dtype"].startswith("int") else "sc:Text"),
           "source":{"fileObject":{"@id":d["id"]+".parquet"},
                     "extract":{"column":c["name"]}}}
        if c.get("role"): f["description"]=f"verified role: {c['role']}"
        fields.append(f)
    rs["field"]=fields
    return rs

# MLCommons Croissant
cr={"@context":{"@vocab":"https://schema.org/","cr":"http://mlcommons.org/croissant/",
                "sc":"https://schema.org/","data":{"@id":"cr:data","@type":"@json"},
                "recordSet":"cr:recordSet","field":"cr:field","fileObject":"cr:fileObject",
                "distribution":"cr:distribution","dataType":{"@id":"cr:dataType","@type":"@vocab"}},
    "@type":"sc:Dataset","conformsTo":"http://mlcommons.org/croissant/1.0",
    "name":"meta-analysis-cz",
    # the DATASET's version, not the schema's. It used to read 1.0.0 while the artefact
    # declared 0.9.0-beta, which a consumer would read as a contradiction.
    "version":index["harmonised_table"]["version"],   # the ARTEFACT's version, not the schema's
    "description":("Estimate-level data from meta-analyses in economics and the social sciences. "
                   f"{len(ok)} datasets containing {sum(d['n_estimates'] for d in ok):,} converted source "
                   f"rows and {sum(d.get('n_estimates_in_literature') or d['n_estimates'] for d in ok):,} "
                   f"estimates in the papers' analysis samples, each with the "
                   "hand-coded study and design characteristics collected for the original paper. "
                   "LICENCE: everything here is CC BY 4.0, including the underlying research "
                   "data. Free to use, adapt, and redistribute, including commercially and as "
                   "training data for machine-learning models. Credit is the only condition: cite "
                   "the collection and the paper whose dataset you used."),
    "url":BASE,
    # A bare CC BY, deliberately: since the 2026-08-03 decision the licence does cover the
    # underlying research data, not only the compilation. ML tooling reads this field, and it
    # would now UNDERSTATE the grant to point at a terms page instead. The previous comment
    # here argued the reverse and predates the reversal.
    "license":"https://creativecommons.org/licenses/by/4.0/",
    "citeAs":index["cite_as"],
    # Issued date of the Zenodo deposit (DataCite dateType "Issued" on the concept DOI).
    "datePublished":"2026-08-04",   # concept deposit
    "dateModified":"2026-08-21",    # this version

    "keywords":["meta-analysis","publication bias","economics","effect size","research synthesis"],
    "creator":[{"@type":"Person","name":"Tomas Havranek"},{"@type":"Person","name":"Zuzana Irsova"}],
    "distribution":[_file_object(d) for d in ok]+[{
        "@type":"cr:FileObject","@id":"estimates_harmonised.csv",
        "name":"estimates_harmonised.csv",
        "description":("DERIVED AGGREGATE VIEW of the per-dataset files above, reshaped to a "
                       "common schema. Rows are not additional to them."),
        "contentUrl":f"{BASE}/data/{DATA_V}/estimates_harmonised.csv",
        "encodingFormat":"text/csv",
        **_digest(os.path.join(OUT,"data",DATA_V,"estimates_harmonised.csv"))},{
        "@type":"cr:FileObject","@id":"estimates_harmonised.parquet",
        "name":"estimates_harmonised.parquet",
        "description":"The same derived aggregate view, as Parquet.",
        "contentUrl":f"{BASE}/data/{DATA_V}/estimates_harmonised.parquet",
        "encodingFormat":"application/vnd.apache.parquet",
        **_digest(os.path.join(OUT,"data",DATA_V,"estimates_harmonised.parquet"))}],
    # The flagship artifact was a bare FileObject: no schema, and CSV only, while every
    # per-dataset entry ships Parquet with a typed RecordSet. A Croissant consumer could see
    # that the pooled table exists but not what is in it.
    "recordSet":[_record_set(d) for d in ok]+[{
        "@type":"cr:RecordSet","@id":"estimates_harmonised","name":"estimates_harmonised",
        "description":("DERIVED AGGREGATE VIEW of the per-dataset record sets, reshaped to a "
                       "common schema. Its rows are not additional to them."),
        "field":[{"@type":"cr:Field","@id":f"estimates_harmonised/{n}","name":n,
                  "dataType":t,
                  "source":{"fileObject":{"@id":"estimates_harmonised.parquet"},
                            "extract":{"column":n}}}
                 for n,t in _harmonised_parquet_types()]}]}
json.dump(cr,open(os.path.join(api,"croissant.json"),"w",encoding="utf-8"),indent=1,ensure_ascii=False)

print(f"datasets.json: {len(datasets)} entries ({len(ok)} with data), "
      f"{sum(d['n_estimates'] for d in ok):,} estimates")
print(f"with DOI: {sum(1 for d in ok if (d['paper'] or {}).get('doi'))} | "
      f"datapackage resources: {len(dp['resources'])}")
missing=[d["id"] for d in ok if not (d["paper"] or {}).get("title")]
if missing: print("no papers.json entry:", ", ".join(missing))
