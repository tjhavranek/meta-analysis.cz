"""Build /results/ — every headline finding on one page, phrased as the question it answers.

WHY. Codex, Fable and two independent agents converged on the same observation: the
"Headline results" list is the most reusable thing on the site and it sits at the bottom of
the homepage, below a 52-row catalogue, keyed by technical parameter names. An economist who
needs one number, a journalist, and an AI answering "does class size affect achievement" all
want the same object, and none of them will scroll to it. This gives that material its own
URL, its own place in the navigation, and question-form headings that match how the question
is actually asked.

SOURCE OF TRUTH. Everything except the question wording comes from site/estimates.csv, which
already carries, per paper: the parameter, the headline finding, the caveat, the evidence
basis, the source citation, a confidence flag, the page URL, the DOI, the full sentence, the
verbatim quote from the paper the figure came from, and the PDF. Nothing here is retyped and
no number is authored. The questions live in redesign/results_questions.json.

    python redesign/build_results_page.py [--check]

--check verifies without writing. The script refuses to write a page that fails its own
self-checks, so a broken run leaves the previous page in place.
"""
import csv, html, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SITE = os.path.normpath(os.path.join(HERE, "..", "site"))
CSV = os.path.join(SITE, "estimates.csv")
QUESTIONS = os.path.join(HERE, "results_questions.json")
OUT = os.path.join(SITE, "results", "index.html")
# Stamped, not computed: the page states when the figures were last assembled so a
# reader can judge whether one has been superseded. Bump when estimates.csv changes.
BUILD_DATE = "2026-08-05"

# fields in the order the homepage uses them
FIELD_ORDER = ["Macroeconomics", "International economics", "Financial economics",
               "Labor and education economics", "Micro and experimental economics",
               "Energy and environmental economics", "Meta-research methods"]


def esc(s):
    return html.escape(s or "", quote=True)


def build(check=False):
    rows = list(csv.DictReader(open(CSV, encoding="utf-8")))
    qs = {q["project"]: q for q in json.load(open(QUESTIONS, encoding="utf-8"))}

    missing = [r["project"] for r in rows if r["project"] not in qs]
    if missing:
        sys.exit(f"no question for: {missing}")
    extra = [p for p in qs if p not in {r['project'] for r in rows}]
    if extra:
        sys.exit(f"question for a project not in estimates.csv: {extra}")

    fields = sorted({r["field"] for r in rows},
                    key=lambda f: FIELD_ORDER.index(f) if f in FIELD_ORDER else 99)

    # Full, paste-able reference lines. papers.json is the data session's file; this only
    # reads it, the same way build_datasets_page.py reads their fragments.
    papers = json.load(open(os.path.join(SITE, "tools", "papers.json"), encoding="utf-8"))
    refs = {m["project"]: m.get("reference_line") for m in papers if m.get("reference_line")}

    # Each answer's author is THAT PAPER'S author list, taken from papers.json. An earlier
    # draft hard-coded the site's two Person nodes on every answer, which was a
    # misattribution: /house_prices/ is Ehrenbergerova, Bajzik and Havranek, and /climate/ is
    # Reckova and Irsova with no Havranek at all. Crediting him for a paper he did not write
    # is worse than crediting nobody, and it would have travelled in machine-readable form.
    by_project = {m["project"]: m for m in papers}
    ORCID = {"Tomas Havranek": "https://orcid.org/0000-0002-3158-2539",
             "Zuzana Irsova": "https://orcid.org/0000-0002-0753-8124"}

    def authors_ld(project):
        names = (by_project.get(project) or {}).get("authors") or []
        out = []
        for n in names:
            person = {"@type": "Person", "name": n}
            if n in ORCID:
                person["@id"] = ("https://meta-analysis.cz/#th"
                                 if n == "Tomas Havranek" else "https://meta-analysis.cz/#zi")
                person["sameAs"] = ORCID[n]
            out.append(person)
        return out
    # Two working papers have no reference_line in papers.json yet. Supplied here on the
    # owner's instruction so every entry is citable; remove each once papers.json carries it.
    refs.setdefault("debate",
        'Tomas Havranek, Zuzana Irsova (2026), "Does Multi-Agent Debate Improve AI Feedback '
        'on Research Papers?" arXiv:2607.14713. Available at meta-analysis.cz/debate.')
    refs.setdefault("esg",
        'Karolina Hozova, Tomas Havranek, Zuzana Irsova (2026), "Do Female Directors Raise '
        'ESG Ratings? A Meta-Analysis." Charles University, Prague. '
        'Available at meta-analysis.cz/esg.')

    # ---- body -----------------------------------------------------------
    chips = "\n".join(
        f'<button type="button" class="chip" data-field="{esc(f)}">{esc(f)}</button>'
        for f in fields)

    sections, jsonld_items = [], []
    for f in fields:
        items = []
        for r in [x for x in rows if x["field"] == f]:
            p = r["project"]
            q = qs[p]["question"]
            links = [f'<a href="{esc(r["url"])}">Paper page</a>']
            if r.get("pdf"):
                links.append(f'<a href="{esc(r["pdf"])}">PDF</a>')
            if r.get("doi"):
                doi_txt = re.sub(r"^https?://(dx\.)?doi\.org/", "", r["doi"])
                links.append(f'<a href="{esc(r["doi"])}">{esc(doi_txt)}</a>')
            # The visible answer is the CSV's `sentence`, not `headline`. Fifteen of the 52
            # headlines are bare fragments -- "about 0", "0.3-0.4" -- which answer nothing on
            # their own and cannot be quoted by anything. `sentence` is self-contained: it
            # carries the parameter, the corrected figure, the caveat in parentheses, the
            # evidence count and the citation. Checked across all 52 rows: every sentence
            # already contains its own source, basis and caveat, so rendering those again
            # underneath would only repeat them.
            # `confidence` is the site's own flag on how firmly the figure is established;
            # say so rather than hiding it, and only when it is not the default.
            flag = ('<p class="r-flag">The site records this figure as medium confidence.</p>\n'
                    if r.get("confidence") and r["confidence"].lower() != "high" else "")
            # A reader who found their number still had to click through for a citation:
            # "Ehrenbergerova et al. 2023, IMF Economic Review" is not something you can
            # paste into a bibliography. papers.json already holds the full reference line
            # for 50 of the 52; the other two are working papers whose page carries it.
            cite = (f'<p class="r-cite"><b>Cite as</b> {esc(refs[p])}</p>\n'
                    if refs.get(p) else "")
            items.append(
                f'<div class="result" id="{esc(p)}" data-field="{esc(f)}" '
                f'data-search="{esc((q + " " + r["parameter"] + " " + r["headline"] + " " + p).lower())}">\n'
                f'<h3>{esc(q)}</h3>\n'
                f'<p class="r-answer">{esc(r["sentence"])}</p>\n'
                f'{flag}{cite}'
                f'<p class="r-links">{" &middot; ".join(links)}</p>\n'
                f'</div>')
            # The creator sits on the ItemList, but an engine extracting a single Q&A drops
            # the container -- so author and DOI go on the Answer itself, or the quote
            # travels with no attribution. Same reason the confidence flag is repeated here:
            # it existed only in the HTML, so a machine quoting the figure lost the
            # qualifier that a human reader could see.
            answer = {"@type": "Answer",
                      "text": r["sentence"] or r["headline"],
                      "url": r["url"],
                      "author": authors_ld(p),
                      "publisher": {"@type": "Organization", "name": "meta-analysis.cz",
                                    "url": "https://meta-analysis.cz/"},
                      "license": "https://creativecommons.org/licenses/by/4.0/"}
            if r.get("doi"):
                answer["citation"] = r["doi"]
            if refs.get(p):
                answer["citation"] = ([answer["citation"], refs[p]]
                                      if "citation" in answer else refs[p])
            if r.get("confidence") and r["confidence"].lower() != "high":
                answer["disambiguatingDescription"] = (
                    f"meta-analysis.cz records this figure as {r['confidence']} confidence.")
            jsonld_items.append({
                "@type": "Question",
                "name": q,
                "url": f"https://meta-analysis.cz/results/#{p}",
                "acceptedAnswer": answer,
            })
        sections.append(f'<section class="r-field" data-field="{esc(f)}">\n'
                        f'<h2>{esc(f)}</h2>\n' + "\n".join(items) + "\n</section>")

    jsonld = json.dumps({
        "@context": "https://schema.org",
        # An ItemList of Question nodes, NOT an FAQPage. These are research findings, not
        # frequently asked questions, and claiming the FAQ type for them would be a
        # misdeclaration a reviewer would be right to call out. The Question/acceptedAnswer
        # shape is what answer engines parse; the container type is the honest one.
        "@type": "ItemList",
        "@id": "https://meta-analysis.cz/results/#results",
        "name": "Headline results from meta-analyses in economics",
        "numberOfItems": len(jsonld_items),
        "creator": [{"@id": "https://meta-analysis.cz/#th"},
                    {"@id": "https://meta-analysis.cz/#zi"}],
        "license": "https://creativecommons.org/licenses/by/4.0/",
        "dateModified": BUILD_DATE,
        "itemListElement": [{"@type": "ListItem", "position": i + 1, "item": it}
                            for i, it in enumerate(jsonld_items)],
    }, indent=1, ensure_ascii=False)

    page = f"""<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta name="viewport" content="width=device-width, initial-scale=1" />
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<title>Headline results from {len(rows)} meta-analyses in economics</title>
<meta name="description" content="One answer per meta-analysis: {len(rows)} headline findings in economics, each corrected for publication bias, with its caveat, the evidence behind it, and a citation." />
<link href="/style.css" rel="stylesheet" type="text/css" />
<script type="application/ld+json">
{jsonld}
</script>
<link rel="canonical" href="https://meta-analysis.cz/results/" />
<!-- seo-meta:start -->
<!-- seo-meta:end -->
</head>
<body>
<div id="wrapper">
<div id="logo">
\t<a class="masthead-home" href="/">meta-analysis.cz</a>
\t<p class="site-name"><a href="/results/">Headline results</a></p>
\t<h2> <span class="mk">&raquo;</span>&nbsp;&nbsp;&nbsp; one answer per meta-analysis</h2>
</div>
<div id="header">
\t<div id="menu">
\t\t<ul>
\t\t\t<li class="current_page_item"><a href="/results/">Results</a></li>
\t\t\t<li><a href="/">Data &amp; code</a></li>
\t\t\t<li><a href="/datasets/">Datasets</a></li>
\t\t\t<li><a href="/guidelines/">Guidelines</a></li>
\t\t\t<li><a href="/maive/">MAIVE</a></li>
\t\t</ul>
\t</div>
</div>
</div>
<div id="page">
\t<div id="content">
\t\t<div class="post">
\t\t\t<h1 class="title">Headline results</h1>
\t\t\t<div class="entry results">

<p>One line per meta-analysis: the result the paper itself headlines, after correcting for
publication bias. Each is the answer to a question someone actually asks, with the caveat that
belongs to it, the evidence it rests on, and a citation.</p>

<p class="r-updated">Figures last assembled {BUILD_DATE}. Each is the paper's own headline
result; the paper's page carries the full abstract, the data and the code.</p>

<p><b>Read the caveat before you reuse a number.</b> Definitions, samples and units differ
across literatures, and a corrected mean is not a law of nature. The paper's own page carries
the full abstract, the data and the code; the figure here is a summary of it, not a substitute
for it. The same table is available as a spreadsheet:
<a href="/estimates.csv">estimates.csv</a>, which also carries the sentence in the paper each
figure came from.</p>

<form class="r-filter" onsubmit="return false;">
<fieldset>
<label for="rq">Search these results</label>
<input type="search" id="rq" placeholder="class size, elasticity, publication bias&hellip;" />
</fieldset>
<div class="chips">
<button type="button" class="chip is-on" data-field="">All fields</button>
{chips}
</div>
<p class="r-count" id="rcount"></p>
</form>

{chr(10).join(sections)}

\t\t\t</div>
\t\t</div>
\t</div>
\t<div style="clear: both;">&nbsp;</div>
</div>
<script>
/* Progressive enhancement only: with JavaScript off every result is visible and the page
   works as a plain document, which is also what a crawler sees. */
(function () {{
  var q = document.getElementById('rq'),
      chips = [].slice.call(document.querySelectorAll('.chip')),
      results = [].slice.call(document.querySelectorAll('.result')),
      fields = [].slice.call(document.querySelectorAll('.r-field')),
      count = document.getElementById('rcount'),
      field = '';
  function apply() {{
    var term = (q.value || '').trim().toLowerCase(), shown = 0;
    results.forEach(function (r) {{
      var ok = (!field || r.getAttribute('data-field') === field) &&
               (!term || r.getAttribute('data-search').indexOf(term) > -1);
      r.hidden = !ok;
      if (ok) shown++;
    }});
    fields.forEach(function (s) {{
      s.hidden = !s.querySelector('.result:not([hidden])');
    }});
    count.textContent = shown === results.length
      ? results.length + ' results'
      : shown + ' of ' + results.length + ' results';
  }}
  q.addEventListener('input', apply);
  chips.forEach(function (c) {{
    c.addEventListener('click', function () {{
      field = c.getAttribute('data-field');
      chips.forEach(function (o) {{ o.classList.toggle('is-on', o === c); }});
      apply();
    }});
  }});
  apply();
}})();
</script>
</body>
</html>
"""

    # ---- self-checks ----------------------------------------------------
    problems = []
    if page.count("<h1") != 1:
        problems.append(f"{page.count('<h1')} h1")
    if len(re.findall(r"<div[ >]", page)) != len(re.findall(r"</div>", page)):
        problems.append("div imbalance")
    if len(re.findall(r"<section[ >]", page)) != len(re.findall(r"</section>", page)):
        problems.append("section imbalance")
    if re.search(r"\{\{|\}\}", page):
        problems.append("unsubstituted placeholder")
    if page.count('class="result"') != len(rows):
        problems.append(f"{page.count('class=\"result\"')} results, expected {len(rows)}")
    try:
        parsed = json.loads(jsonld)
        if parsed["numberOfItems"] != len(rows):
            problems.append("JSON-LD count mismatch")
        # never let the markup credit someone who is not an author of that paper
        for li in parsed["itemListElement"]:
            slug = li["item"]["url"].rsplit("#", 1)[-1]
            got = [a["name"] for a in li["item"]["acceptedAnswer"]["author"]]
            want = (by_project.get(slug) or {}).get("authors") or []
            if got != want:
                problems.append(f"JSON-LD authors for {slug} are {got}, papers.json says {want}")
    except Exception as e:
        problems.append(f"JSON-LD does not parse: {e}")
    for r in rows:  # every number on the page must be traceable to the CSV
        if r["sentence"] and esc(r["sentence"]) not in page:
            problems.append(f"answer sentence missing for {r['project']}")
    if problems:
        sys.exit("REFUSING TO WRITE: " + "; ".join(problems))

    if check:
        print(f"  check clean: {len(rows)} results, {len(fields)} fields, "
              f"{len(jsonld_items)} JSON-LD questions")
        return
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, "w", encoding="utf-8", newline="").write(page)
    print(f"  wrote {os.path.relpath(OUT, SITE)}  ({len(page):,} bytes)")
    print(f"  {len(rows)} results across {len(fields)} fields; self-checks clean")


if __name__ == "__main__":
    build(check="--check" in sys.argv)
