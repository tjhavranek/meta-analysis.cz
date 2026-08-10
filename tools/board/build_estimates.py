# Build the homepage "headline estimates" block from the quote-grounded,
# audit-corrected extraction. One self-contained sentence per row, grouped by
# field, so the parameter->number link survives the tag-stripping used to build
# LLM corpora while staying readable for humans. Emits an HTML fragment + CSV.
import json, os, csv, html, re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EST = json.load(open(os.path.join(BASE, "tools_seo", "headline_estimates.json"), encoding="utf-8"))
PAPERS = {p["project"]: p for p in json.load(
    open(os.path.join(BASE, "site", "tools", "papers.json"), encoding="utf-8"))}
SITE = "https://meta-analysis.cz"
# incentives appeared in JPE Micro on 2026-08-10 (10.1086/743543); the set is kept
# so the next forthcoming paper has somewhere to go
FORTHCOMING = set()
FIELD_ORDER = ["Macroeconomics", "Micro and experimental economics",
               "Energy and environmental economics", "International economics",
               "Labor and education economics", "Financial economics",
               "Meta-research methods"]

def cite(p):
    a = p.get("authors") or []
    if not a:
        return None
    last = a[0].split()[-1]
    who = last if len(a) == 1 else (
        f"{last} and {a[1].split()[-1]}" if len(a) == 2 else f"{last} et al.")
    out = f"{who} {p.get('year')}" if p.get("year") else who
    if p.get("journal"):
        out += f", {p['journal']}"
    return out

def pdf_url(proj):
    """The paper PDF already identified for Google Scholar on that project page.
    Used as the trailing link for working papers that have no DOI yet."""
    f = os.path.join(BASE, "site", proj, "index.html")
    if not os.path.isfile(f):
        return ""
    m = re.search(r'name="citation_pdf_url" content="([^"]+)"',
                  open(f, encoding="utf-8", errors="ignore").read())
    return m.group(1) if m else ""

rows = []
for e in EST:
    if not e.get("headline"):
        continue
    proj = e["project"]
    p = PAPERS.get(proj, {})
    src = cite(p) or (p.get("title") or proj)
    if proj in FORTHCOMING:
        src += ", forthcoming"
    ev = (e.get("evidence") or "").lower()
    numeric = bool(re.search(r"\d", e["headline"]))
    corrected = ("correct" in ev) or ("adjust" in ev)
    # phrasing chosen so the sentence reads naturally and never overclaims
    if e.get("lead") is not None:
        lead = e["lead"]                       # "" means: no lead-in at all
    elif e.get("kind"):
        lead = f"the {e['kind']} is"
    elif numeric and corrected:
        lead = "corrected for publication bias,"
    elif numeric:
        lead = "the meta-analytic estimate is"
    else:
        lead = "the meta-analytic finding is"
    # A headline that already ends in "(...)" plus a separate caveat produced two
    # parentheticals in a row -- the clearest machine tell on the page. Merge them.
    head = e["headline"].strip()
    extra = []
    # only when that trailing "(...)" is the headline's ONLY one -- rows like
    # exercise ("SMD 0.227 (cognition), 0.027 (memory), 0.012 (executive function)")
    # must not have their last bracket torn off and re-glued to a caveat
    m = re.search(r"\s*\(([^()]*)\)\s*$", head) if head.count("(") == 1 else None
    if m:
        head = head[:m.start()].rstrip()
        extra.append(m.group(1).strip())
    if e.get("caveat"):
        extra.append(e["caveat"].strip())
    paren = " (" + "; ".join(extra) + ")" if extra else ""
    basis = f", based on {e['basis']}" if e.get("basis") else ""
    sentence = f"{e['parameter']}: {lead + ' ' if lead else ''}{head}{paren}{basis} ({src})."
    rows.append({
        "field": e.get("field", ""), "project": proj, "parameter": e["parameter"],
        "headline": e["headline"], "caveat": e.get("caveat") or "",
        "basis": e.get("basis") or "", "source": src,
        "confidence": e.get("confidence", ""), "url": f"{SITE}/{proj}/",
        "doi": p.get("doi_or_publisher_url") or "",
        "sentence": sentence, "source_quote": e.get("evidence") or "",
        "pdf": pdf_url(proj),
    })

with open(os.path.join(BASE, "tools_seo", "estimates_draft.csv"), "w",
          encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader()
    for fld in FIELD_ORDER:
        for r in sorted([x for x in rows if x["field"] == fld],
                        key=lambda x: x["parameter"].lower()):
            w.writerow(r)

out = ['<h2 class="title" id="results">Headline results from these papers</h2>',
       '<div class="entry">',
       '<p>One line per paper: the result the paper itself headlines. Definitions and '
       'samples differ across literatures, so check the source before reusing a number. '
       f'Also as a spreadsheet: <a href="{SITE}/estimates.csv">estimates.csv</a>, which '
       'carries the sentence each figure came from.</p>']
for fld in FIELD_ORDER:
    group = sorted([r for r in rows if r["field"] == fld], key=lambda r: r["parameter"].lower())
    if not group:
        continue
    out.append(f'<p><b>{html.escape(fld)}</b></p>')
    out.append('<ul>')
    for r in group:
        t = html.escape(r["sentence"])
        t = t.replace(html.escape(r["parameter"]),
                      f'<a href="{r["url"]}">{html.escape(r["parameter"])}</a>', 1)
        target = r["doi"] or r["pdf"]
        if target:
            label = ("doi" if "doi.org" in target else
                     "pdf" if target.endswith(".pdf") else "link")
            t = t[:-1] + f' <a href="{html.escape(target)}">{label}</a>.'
        out.append(f"  <li>{t}</li>")
    out.append('</ul>')
out.append('</div>')
open(os.path.join(BASE, "tools_seo", "estimates_draft.html"), "w",
     encoding="utf-8", newline="\n").write("\n".join(out))
print(f"{len(rows)} rows in {len([f for f in FIELD_ORDER if any(r['field']==f for r in rows)])} field groups")

import subprocess as _sp, sys as _sys
_sp.run([_sys.executable, os.path.join(BASE, 'tools_seo', 'publish_board_sources.py')], check=False)
