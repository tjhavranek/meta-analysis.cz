"""Generated HTML fragments for the /datasets/ landing page.

Bare fragments: no wrapper div, no inline styles, no <script>. One class on the
table so the redesign can style it without fighting specificity. The page owns
all presentation; this owns only the facts, which change when the data is rebuilt.
"""
import json, os, html
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
if api.get("doi"):
    w("doi.html", e(api["doi"]))
    w("doi_url.html", e(api["doi_url"]))
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
   '<th scope="col">Effect measured in</th>',
   '<th scope="col">Data</th>',
   '<th scope="col">Paper</th>',
   '</tr>','</thead>','<tbody>']
for d in rows:
    pap=d.get("paper") or {}
    title=e(pap.get("title") or d["id"])
    n=f"{nlit(d):,}"
    units=e(d.get("effect_units") or "\u2014")
    files=[]
    if (d["files"] or {}).get("csv"):
        files.append(f'<a href="{e(d["files"]["csv"])}">CSV</a>')
    if (d["files"] or {}).get("parquet"):
        files.append(f'<a href="{e(d["files"]["parquet"])}">Parquet</a>')
    files.append(f'<a href="{e(d["files"]["codebook"])}">codebook</a>')
    doi=pap.get("doi")
    paper=(f'<a href="{e(doi)}">{e(pap.get("journal") or "published version")}</a>' if doi
           else f'<a href="{e(pap.get("url") or "/"+d["id"]+"/")}">page</a>')
    mark="" if d.get("in_harmonised_table") else ' <span class="not-pooled">not pooled</span>'
    # A reshaped literature contributes one row per horizon, so its count is not comparable
    # with a paper's estimate count. Saying so in the cell stops it reading as an error.
    horizon_note=""
    if d["id"] in RESHAPED:
        horizon_note=(' <span class="horizon-note" title="One row per impulse-response horizon, '
                      'not per independent estimate">per horizon</span>')
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
