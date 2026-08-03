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
w("count_analysis.html", f"{api['counts']['estimates_in_analysis_samples']:,}")
_dr=sum(1 for d in rows if d.get("audit_status")=="domain_reviewed" and d.get("in_harmonised_table"))
_po=sum(1 for d in rows if d.get("audit_status")=="arithmetic_pairing_only" and d.get("in_harmonised_table"))
w("count_domain_reviewed.html", str(_dr))
w("count_pairing_only.html", str(_po))

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
    t += ['<tr>',
          f'<td><a href="{e(pap.get("url") or "/"+d["id"]+"/")}">{title}</a>{mark}</td>',
          f'<td class="num">{n}</td>',
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

print(f"fragments written to api/{DV}/fragments/:")
for f in sorted(os.listdir(FR)):
    print(f"   {f:38s} {os.path.getsize(os.path.join(FR,f)):>7,} bytes")
