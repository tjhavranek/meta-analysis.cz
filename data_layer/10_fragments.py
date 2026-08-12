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
    # these numbers already do -- 1,415 for price_puzzle against the paper's own "more than
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

    _pp = _H[_H["dataset"] == "price_puzzle"]
    if len(_pp):
        _g = _pp.groupby(["study_id", "horizon", "effect", "se"]).size()
        if len(_g) and int(_g.min()) > 1:
            _m = int(_g.min())
            out.append(f"<code>price_puzzle</code> repeats every estimate {_m} times: "
                       f"{len(_pp):,} rows where {len(_g):,} are distinct. The source file is already "
                       "long on <code>horizon</code> while its response columns are wide, and the "
                       "reshape did not deduplicate. A weighted average is unchanged, but any count "
                       "of estimates, any unweighted statistic and any method treating rows as "
                       "independent observations will be wrong for this literature.")
    return out


_ki = _known_issues()
if _ki:
    _items = "\n".join(f"<li>{x}</li>" for x in _ki)
    w("known_issues.html",
      "<p>These defects are present in the files published here and in the archived deposit. "
      "Each will be fixed in the next release. Nothing else in the table is affected.</p>\n"
      "<ul>\n" + _items + "\n</ul>\n")
else:
    # emit an EMPTY file rather than none, so the page inlines nothing and the box vanishes
    w("known_issues.html", "")

print(f"fragments written to api/{DV}/fragments/:")
for f in sorted(os.listdir(FR)):
    print(f"   {f:38s} {os.path.getsize(os.path.join(FR,f)):>7,} bytes")
