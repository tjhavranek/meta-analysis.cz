"""Generated HTML fragments for the /datasets/ landing page.

Bare fragments: no wrapper div, no inline styles, no <script>. One class on the
table so the redesign can style it without fighting specificity. The page owns
all presentation; this owns only the facts, which change when the data is rebuilt.
"""
import json, os, html, re
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE

OUT=os.path.join(WORK,"out"); DV="v1"
api=json.load(open(os.path.join(OUT,"api",DV,"datasets.json"),encoding="utf-8"))
FR=os.path.join(OUT,"api",DV,"fragments"); os.makedirs(FR,exist_ok=True)

def w(name, s):
    open(os.path.join(FR,name),"w",encoding="utf-8",newline="\n").write(s)

e=html.escape
# literatures whose rows are horizon-level rather than one-per-estimate
RESHAPED={"price_puzzle","house_prices"}
rows=[d for d in api["datasets"] if d.get("n_estimates")]
nlit=lambda d: d.get("n_estimates_in_literature") or d.get("n_estimates") or 0
rows.sort(key=lambda d: -nlit(d))
H=api["harmonised_table"]

# ---- one-line count fragments, so the page never hardcodes a number ----
w("count_datasets.html", f"{api['counts']['datasets']}")
w("count_estimates.html", f"{api['counts']['rows_in_source_files']:,}")
w("count_harmonised_estimates.html", f"{H['n_rows']:,}")
w("count_harmonised_literatures.html", f"{H['n_literatures']}")
w("harmonised_version.html", e(H["version"]))
# ALWAYS write these, empty when there is no version DOI. Writing them conditionally left the
# PREVIOUS release's DOI on disk when 1.0.0 nulled it, so the page was about to pair
# "10.5281/zenodo.21773679" with "version 1.0.0" -- the last release's identifier attached to
# this release's data. A conditional write does not leave a blank, it leaves a stale value, and
# a stale value is indistinguishable from a current one to everything downstream. Caught by the
# redesign session during the 1.0.0 rebuild, 2026-08-04.
w("doi.html", e(api["doi"]) if api.get("doi") else "")
w("doi_url.html", e(api["doi_url"]) if api.get("doi_url") else "")
if api.get("cite_as"):
    w("cite_as.html", e(api["cite_as"]))
if api.get("concept_doi"):
    w("concept_doi.html", e(api["concept_doi"]))
    w("concept_doi_url.html", e(api["concept_doi_url"]))
w("count_analysis.html", f"{api['counts']['estimates_in_analysis_samples']:,}")
_dr=sum(1 for d in rows if d.get("audit_status")=="domain_reviewed" and d.get("in_harmonised_table"))
_po=sum(1 for d in rows if d.get("audit_status")=="arithmetic_pairing_only" and d.get("in_harmonised_table"))
w("count_domain_reviewed.html", str(_dr))
w("count_pairing_only.html", str(_po))
_ct=sum(1 for d in rows if d.get("audit_status")=="code_traced" and d.get("in_harmonised_table"))
w("count_code_traced.html", str(_ct))
w("count_code_checked.html", str(_dr+_ct))          # domain_reviewed + code_traced
assert _dr+_ct+_po == H["n_literatures"], (
    f"audit statuses do not sum to the pooled total: {_dr}+{_ct}+{_po} != {H['n_literatures']}")

# ---- the catalogue table ----
t=['<table class="dataset-catalogue">',
   f'<caption>{api["counts"]["datasets"]} datasets, '
   f'{api["counts"]["estimates_in_analysis_samples"]:,} estimates in their analysis samples '
   f'({api["counts"]["rows_in_source_files"]:,} rows in the source files). '
   f'{H["n_literatures"]} literatures are pooled into the harmonised table.</caption>',
   '<thead>','<tr>',
   '<th scope="col">Literature</th>',
   '<th scope="col">Estimates</th>',
   '<th scope="col">Effect measure</th>',
   '<th scope="col">Data</th>',
   '<th scope="col">Paper</th>',
   '</tr>','</thead>','<tbody>']
for d in rows:
    pap=d.get("paper") or {}
    # Column 1 is headed "Literature" and now carries a literature: a short noun phrase naming
    # the body of primary studies. It used to carry the page's search-facing title, so the
    # column read as a second, paraphrased Paper column.
    title=e(pap.get("literature") or pap.get("page_title") or pap.get("title") or d["id"])
    n=f"{nlit(d):,}"
    units=e(d.get("effect_units") or "\u2014")
    files=[]
    if (d["files"] or {}).get("csv"):
        files.append(f'<a href="{e(d["files"]["csv"])}">CSV</a>')
    if (d["files"] or {}).get("parquet"):
        files.append(f'<a href="{e(d["files"]["parquet"])}">Parquet</a>')
    files.append(f'<a href="{e(d["files"]["codebook"])}">codebook</a>')
    # Every row, the same shape: the title the journal printed, linked to the DOI where there
    # is one, with the venue and year beneath. Two earlier attempts were worse. Showing only
    # the journal meant the published title appeared nowhere on a page that promises "the index
    # carries every paper's title"; showing the title only where it differed from column 1 made
    # the column look arbitrary. The venue was also taken from the DOI rather than the journal
    # field, so `lags` -- International Journal of Central Banking, 2013 -- was labelled a
    # working paper because it has no DOI.
    doi=pap.get("doi")
    ptitle=e(pap.get("title") or d["id"])
    venue=(pap.get("journal") or "").strip()
    year=pap.get("year")
    href=doi or pap.get("url") or "/"+d["id"]+"/"
    label=e(venue) if venue else "Working paper"
    if year: label += f" &middot; {year}"
    paper=(f'<a href="{e(href)}">{ptitle}</a>'
           f'<br /><span class="cat-venue">{label}</span>')
    mark="" if d.get("in_harmonised_table") else ' <span class="not-pooled">not pooled</span>'
    # The two impulse-response literatures used to carry a "per horizon" tag here, warning that
    # the count was rows rather than independent estimates. The owner's ruling is that a
    # horizon-specific response IS a point estimate and should be counted as one, which is what
    # these numbers already do -- 1,395 for price_puzzle against the paper's own "more than
    # 1,000 point estimates". The tag contradicted the count it annotated. Each dataset's own
    # record still carries the horizon note for anyone modelling the dependence.
    horizon_note=""
    t += ['<tr>',
          f'<td><a href="{e(pap.get("url") or "/"+d["id"]+"/")}">{title}</a>{mark}</td>',
          f'<td class="num">{n}{horizon_note}</td>',
          f'<td>{units}</td>',
          f'<td>{" ".join(files)}</td>',
          f'<td>{paper}</td>',
          '</tr>']
t += ['</tbody>','</table>']
w("datasets_table.html", "\n".join(t)+"\n")

# ---- why four datasets are published but not pooled ----
ex=H.get("excluded") or {}
if ex:
    u=['<dl class="not-pooled-reasons">']
    for k,v in sorted(ex.items()):
        u += [f'<dt>{e(k)}</dt>', f'<dd>{e(v)}</dd>']
    u.append('</dl>')
    w("not_pooled.html", "\n".join(u)+"\n")

# Hand-written files that live in generated territory. Keeping the canonical copy
# in data_layer/ means a rebuild cannot silently delete them.
import shutil
for src,dst in (("api_readme.md", os.path.join(OUT,"api",DV,"README.md")),
                ("citation.cff",  os.path.join(OUT,"CITATION.cff")),
                ("licence.txt",   os.path.join(OUT,"LICENSE")),
                ("zenodo.json",   os.path.join(OUT,".zenodo.json"))):
    sp=os.path.join(WORK,src)
    if os.path.exists(sp):
        os.makedirs(os.path.dirname(dst),exist_ok=True); shutil.copy2(sp,dst)
    else:
        print(f"   WARNING: canonical {src} missing from data_layer/")

# ---------------------------------------------------------------- known issues in the SHIPPED data
# A defect found after a release sits in the downloads until the next build. Recording it only in
# the pipeline notes leaves anyone who takes the CSV, the Parquet or the Zenodo deposit today with
# no way to know. So state it on the page that offers the download.
#
# SELF-RETIRING BY DESIGN: every issue below is emitted only if its condition is still TRUE of the
# data being described. When the fix lands and the table is rebuilt, the condition fails and the
# issue disappears on its own. A hand-maintained warning would outlive its defect and start lying
# in the other direction, which is how "known issues" sections usually rot.
def _known_issues():
    import pandas as _pd, numpy as _np
    try:
        _H = _pd.read_parquet(os.path.join(OUT, "data", DV, "estimates_harmonised.parquet"))
    except Exception:
        return []
    out = []

    _y = _pd.to_numeric(_H.get("pub_year"), errors="coerce")
    _bad = sorted(_H.loc[(_y < 1950) | (_y > 2027), "dataset"].unique()) if _y is not None else []
    if _bad:
        out.append(("<code>pub_year</code> is not a publication year in "
                    + ", ".join(f"<code>{e(b)}</code>" for b in _bad) +
                    ". Those source files carry a standardised regressor of the same name, and the "
                    "column was matched by name rather than by value. Do not use "
                    "<code>pub_year</code> for these literatures; every other column is unaffected."))

    _rem = _H[_H["dataset"] == "remittances"]
    if len(_rem) and str(_rem["effect_units"].iloc[0]).startswith("regression coefficient"):
        out.append("<code>remittances</code> reports the source file's raw regression coefficients "
                   "rather than the partial correlations its paper analyses. Those coefficients run "
                   "over five different dependent variables, so they are not comparable with each "
                   "other or with the other literatures. Treat this literature as unusable for now.")

    # 09_verify has flagged this since 1.0.0 with "must be documented", and it was
    # documented nowhere a reader would see. A partial correlation cannot lie outside
    # [-1,1]; a value that does will break any reanalysis that assumes the bound. Computed
    # from the data, so it lists whatever is actually wrong and vanishes when it is fixed.
    _u = _H.get("effect_units")
    if _u is not None:
        _pcc = _H[_u.astype(str).str.contains("partial correlation", case=False, na=False)]
        # >= 1, not > 1. An estimate of exactly +/-1 beside a finite standard error is as
        # impossible as one of 1.372, and both are the same defect: inverting the source's own
        # pcc = t/sqrt(t^2 + df) on these rows returns df <= 0, so the sample size entered that
        # transform as missing. Testing only > 1 disclosed 2 rows and left 73 undisclosed.
        _ab = _pd.to_numeric(_pcc["effect"], errors="coerce").abs()
        _oob = _pcc[_ab >= 1]
        if len(_oob):
            _ab_o = _pd.to_numeric(_oob["effect"], errors="coerce").abs()
            _gt, _eq = _oob[_ab_o > 1], _oob[_ab_o == 1]
            _fmt = lambda d: "; ".join(
                f"<code>{e(k)}</code> ({int(v)} row{'s' if int(v) != 1 else ''})"
                for k, v in d.groupby("dataset").size().items())
            _bits = []
            if len(_gt):
                _bits.append("outside <code>[-1, 1]</code> altogether, " + _fmt(_gt)
                             + f", to |{_ab_o.max():.3f}|")
            if len(_eq):
                _bits.append("at exactly &plusmn;1 while carrying a positive standard error, "
                             "which is not a coherent effect/error pair: "
                             + _fmt(_eq))
            out.append(
                f"{len(_oob):,} estimates are invalid under the source column's own "
                "partial-correlation construction: " + ", and ".join(_bits) + ". They come straight from the "
                "source file's own partial-correlation column. "
                "Elsewhere in that file the column reproduces <code>t / sqrt(t&sup2; + df)</code>, "
                "and inverting it on these rows returns a degrees-of-freedom argument of zero or "
                "below, which no sample can have. That restates the inconsistency rather than "
                "diagnosing its cause upstream, which is not established. "
                "The per-dataset mirror will keep reproducing the source faithfully, defect and "
                "all; the harmonised table is a derived product and may correct or null values "
                "the source's own formula contradicts, with the provenance recorded and a "
                "version bump. That is scheduled for the next data revision. Until then, filter "
                "on <code>abs(effect) &lt; 1</code> if you need strictly valid correlations. "
                "<strong>They are concentrated, and that makes them influential.</strong> "
                "72 of the 75 belong to a single study. An unweighted regression of effect on "
                "standard error, the form of the FAT bias test that does not down-weight them, "
                "gives a slope of -0.216 with these rows and -0.095 without, and its "
                "study-clustered t falls from -17.3 to -0.5. A precision-weighted FAT-PET on the "
                "same data, also clustered on study, is insignificant either way, because "
                "weighting by 1/se discounts exactly the rows whose standard errors are "
                "implausible. The sensitivity is to the specification, not to clustering. "
                "Which conclusion you reach about publication bias in this literature therefore "
                "depends on rows the source's own formula contradicts.")

    # The same class column carries a third family the [-1,1] test cannot see: a stored
    # partial correlation of exactly 0 beside a t-statistic that is not. Computed from the
    # per-dataset mirror, because the harmonised t_stat is derived from effect/se and is
    # therefore 0 by construction on exactly these rows.
    try:
        _cls = _pd.read_parquet(os.path.join(OUT, "data", DV, "class", "class.parquet"))
        _z = int(((_cls["pcc"] == 0) & (_cls["t_stat"].abs() > 0.01)).sum())
    except FileNotFoundError:
        _z = 0                    # not built yet, so the item does not apply
    except Exception as _e:
        # The mirror exists and will not read. Dropping the item silently would be the
        # same self-silencing defect this function was fixed for one branch below.
        raise SystemExit(f"known_issues: cannot read the class mirror: {_e}")
    if _z:
        out.append(f"A further {_z} rows of <code>class</code> store a partial correlation of "
                   "exactly zero beside a t-statistic that is not zero, which the same "
                   "<code>t / sqrt(t&sup2; + df)</code> relation contradicts. They are excluded "
                   "from the pooled table by that literature's own analysis selection, so they "
                   "affect the per-dataset file rather than the harmonised one. Recorded here "
                   "as a separate inconsistency in the same source column; whether it has "
                   "the same cause has not been shown.")

    # Rows can share every column without the pipeline having invented them: two estimates
    # rounded to the same coefficients really do recur. Worth stating, because the obvious
    # hygiene step destroys real data.
    # Computed before the paragraph that references it: when the price_puzzle fix lands,
    # that item retires itself, and a cross-reference to a vanished item would be left behind.
    _ppg = _H[_H["dataset"] == "price_puzzle"].groupby(
        ["study_id", "horizon", "effect", "se"]).size()
    _pp_flagged = bool(len(_ppg)) and int(_ppg.max()) > 1
    _dc = [c for c in _H.columns if c != "estimate_id"]
    _dup = int(_H.duplicated(subset=_dc, keep="first").sum())
    if _dup:
        _nlit = int(_H[_H.duplicated(subset=_dc, keep=False)]["dataset"].nunique())
        _w = _H[_H.duplicated(subset=_dc, keep="first")]["dataset"].value_counts()
        out.append(f"{_dup:,} rows across {_nlit} literatures are identical to another row in "
                   "every column except <code>estimate_id</code>."
                   + (" Apart from the <code>price_puzzle</code> rows noted separately, these"
                      if _pp_flagged else " These")
                   + " are not duplicates in the sense "
                   "of being manufactured: the source files carry them, either as genuinely "
                   "repeated coefficients or as distinct estimates that coincide once projected "
                   "onto the harmonised columns. The heaviest are "
                   + ", ".join(f"<code>{e(k)}</code> ({int(v):,})" for k, v in _w.head(3).items())
                   + ". Running <code>drop_duplicates()</code> as routine hygiene will delete "
                   "real estimates, over half of one literature in the worst case. Deduplicate "
                   "on <code>(dataset, estimate_id)</code> instead, which is unique by "
                   "construction.")

    _pp = _H[_H["dataset"] == "price_puzzle"]
    if len(_pp):
        _g = _pp.groupby(["study_id", "horizon", "effect", "se"]).size()
        # max(), not min(). min() > 1 only fires when EVERY estimate is duplicated, which was the
        # 0.9.0-beta 7x case. It is silent on partial duplication, so the 20 rows this release
        # actually carries went undisclosed beneath a sentence promising nothing else was affected.
        if len(_g) and int(_g.max()) > 1:
            _extra = int(_g.sum() - len(_g))
            if int(_g.min()) > 1:
                _m = int(_g.min())
                out.append(f"<code>price_puzzle</code> repeats every estimate {_m} times: "
                           f"{len(_pp):,} rows where {len(_g):,} are distinct. The source file is "
                           "already long on <code>horizon</code> while its response columns are "
                           "wide, and the reshape did not deduplicate. A weighted average is "
                           "unchanged, but any count of estimates, any unweighted statistic and any "
                           "method treating rows as independent observations will be wrong for this "
                           "literature.")
            else:
                out.append(f"<code>price_puzzle</code> carries {_extra} rows that duplicate another "
                           f"row exactly: {len(_pp):,} rows where {len(_g):,} are distinct on study, "
                           "horizon, effect and standard error. The source file is already long on "
                           "<code>horizon</code> while its response columns are wide; the reshape "
                           "deduplicates on every column except <code>horizon</code>, and three "
                           "impulse responses carry one inconsistent month-code cell, so each was "
                           "split in two before the reshape multiplied it. The source's own estimate "
                           "identifier declares 217 impulse responses where the pipeline built 220. "
                           "These rows correspond to no source observation. This is the only "
                           "literature built by a reshape, so it is the only one whose harmonised "
                           "rows can outnumber its source records; identical-looking rows elsewhere "
                           "in the table are identical in the source too. Correction is scheduled "
                           "for the next data revision. Estimate counts and unweighted statistics for this "
                           "literature are affected; the caliper counts and share-below-6 published "
                           "on this page are not.")
    return out


_ki = _known_issues()
if _ki:
    _items = "\n".join(f"<li>{x}</li>" for x in _ki)
    w("known_issues.html",
      "<p>These defects are present in the files published here. Those in the pooled "
      "table are also in the archived v1.0.0 deposit, which ships it; the per-dataset "
      "mirrors are not deposited. They are documented and retained rather than silently "
      "altered or dropped. Nothing else in the table is affected.</p>\n"
      "<ul>\n" + _items + "\n</ul>\n")
else:
    # emit an EMPTY file rather than none, so the page inlines nothing and the box vanishes
    w("known_issues.html", "")

print(f"fragments written to api/{DV}/fragments/:")
for f in sorted(os.listdir(FR)):
    print(f"   {f:38s} {os.path.getsize(os.path.join(FR,f)):>7,} bytes")
