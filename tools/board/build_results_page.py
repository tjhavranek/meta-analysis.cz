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
def _resolve_site(start):
    """Locate the site directory under either layout.

    Both this repo's scripts assumed the DEVELOPMENT layout (a `site/` folder beside the
    tools), so run from the PUBLISHED repo -- where the tools live inside the site they
    build -- they pointed at a directory that does not exist. data_layer/_paths.py already
    resolves both; this is the same rule for the board scripts.
    """
    import os as _os
    env = _os.environ.get("SEO_SITE_DIR")
    if env:
        return env
    sibling = _os.path.join(start, "site")
    if _os.path.isdir(sibling):
        return sibling
    here = start
    for _ in range(3):
        here = _os.path.dirname(here)
        if _os.path.isdir(_os.path.join(here, "api")) and _os.path.isdir(_os.path.join(here, "data")):
            return here
    return sibling

SITE = _resolve_site(os.path.normpath(os.path.join(HERE, "..")))
CSV = os.path.join(SITE, "estimates.csv")
QUESTIONS = os.path.join(HERE, "results_questions.json")
OUT = os.path.join(SITE, "results", "index.html")
# Stamped, not computed: the page states when the figures were last assembled so a
# reader can judge whether one has been superseded. Bump when estimates.csv changes.
# Derived, not typed: this was hand-bumped and went stale twice, so JSON-LD said the
# page was last modified days before the estimates it renders actually changed.
def _last_change(path):
    import subprocess
    r = subprocess.run(["git", "-C", os.path.dirname(path), "log", "-1",
                        "--format=%cs", "--", os.path.basename(path)],
                       capture_output=True, text=True)
    return (r.stdout or "").strip()

BUILD_DATE = None   # set in build(), from estimates.csv's last commit

# fields in the order the homepage uses them
FIELD_ORDER = ["Macroeconomics", "International economics", "Financial economics",
               "Labor and education economics", "Micro and experimental economics",
               "Energy and environmental economics", "Meta-research methods"]


def esc(s):
    return html.escape(s or "", quote=True)



def dot_strip(rows, fields):
    """One square per paper on this page, coloured by field, hollow where the paper's own
    answer is about zero.

    Everything here is already audited and already on the site: the field is the row's own
    `field`, the colours are the homepage board's seven field colours, and the about-zero
    mark reads the same `zero` flag in tools_seo/answer_board.json that mutes a homepage
    tile. No comparison is computed, nothing is pooled, and every square is one of HIS
    papers -- which is the property the previous figure lost.
    """
    board = os.path.join(HERE, "..", "tools_seo", "answer_board.json")
    flags = {k: v.get("zero", False)
             for k, v in json.load(open(board, encoding="utf-8"))["values"].items()}
    missing = [r["project"] for r in rows if r["project"] not in flags]
    if missing:
        sys.exit(f"no board zero flag for {missing}; the strip and the homepage would disagree")

    CLS = {"Macroeconomics": "macro", "Micro and experimental economics": "micro",
           "Energy and environmental economics": "energy", "International economics": "intl",
           "Labor and education economics": "labor", "Financial economics": "fin",
           "Meta-research methods": "meth"}
    n_zero = sum(1 for r in rows if flags[r["project"]])
    S, G, FG, H = 15, 4, 13, 15
    x, sq, legend = 0, [], []
    for f in fields:
        group = [r for r in rows if r["field"] == f]
        start = x
        for r in group:
            z = flags[r["project"]]
            sq.append('<a href="#%s"><rect x="%d" y="0" width="%d" height="%d" rx="2.5" '
                      'fill="%s" stroke="%s" stroke-width="%s"><title>%s%s</title></rect></a>'
                      % (r["project"], x, S, S,
                         "var(--paper)" if z else f"var(--bf-{CLS[f]})",
                         f"var(--bf-{CLS[f]})", "2" if z else "0",
                         esc(r["parameter"]), " — about zero" if z else ""))
            x += S + G
        legend.append((f, start, x - G))
        x += FG
    w = x - G - FG
    return ('<figure class="dotstrip">\n'
            f'<svg viewBox="0 0 {w} {H}" width="100%" height="{H}" role="img" '
            f'aria-label="One square per paper on this page, grouped and coloured by field; '
            f'{n_zero} of {len(rows)} are drawn hollow because the paper answers its question '
            'with about zero">\n' + "".join(sq) + "\n</svg>\n"
            '<figcaption class="table-note">One square per paper below, in the order they '
            'appear and coloured by field &mdash; the same seven colours as the homepage. '
            f'The <b>{n_zero} hollow squares</b> are the papers whose own answer is about '
            'zero: class size, financial incentives, tuition and enrolment, working while '
            'studying, bank competition and stability, daylight saving, and the euro’s '
            'effect on trade. Hover a square for the question it answers.'
            '</figcaption>\n</figure>')


def build(check=False):
    global BUILD_DATE
    BUILD_DATE = _last_change(CSV)
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", BUILD_DATE or ""):
        sys.exit("could not read estimates.csv's last commit date; refusing to stamp the "
                 "page with a guess")
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
    # These two working papers used to have their reference_line supplied here, because
    # papers.json had none -- and the paper pages, which never saw this file, synthesised their
    # own instead: /debate/ cited an arXiv paper as "Charles University, Prague" and printed
    # `Papers?."`. Both lines now live in papers.json, so every surface reads the same string.
    for _p in ("debate", "esg"):
        if not (refs.get(_p) or "").strip():
            sys.exit(f"{_p}: papers.json has lost its reference_line; /results/ used to carry a "
                     f"local copy of it and no longer does")

    # ---- body -----------------------------------------------------------
    # The research-revision figure was here for one build and is now on
    # /conventional_wisdom/ instead. It plots the 24 literatures reviewed by Gechert et
    # al., and 21 of those 24 are OTHER researchers' meta-analyses. On a page headed
    # "Headline results from 54 papers" that reads as a claim on work that is not his.
    # It belongs on the reviewing paper's own page, where the attribution is plain.
    n_rows = len(rows)
    # The field-coloured strip was pretty and said nothing -- his verdict, and he was right.
    # What replaces it answers the question he actually asked: when these papers correct for
    # bias, how far does the number move? Built by tools_seo/build_correction_figure.py from
    # the estimate-level data on this site plus each paper's own stated corrected value, and
    # only for the papers where a single honest ratio exists. dot_strip() is kept below in
    # case the comparison ever has to come out again.
    # The licence line, the Zenodo citation and both authors' ORCID / Scholar / RePEc /
    # Scopus / CEPR / METRICS links live in the site footer, and this page never had one.
    # Lifted verbatim from the homepage: one copy of the block to keep right, not two.
    home_ = open(os.path.join(SITE, "index.html"), encoding="utf-8").read()
    fi_ = home_.find('<footer class="site-foot">')
    fj_ = home_.find("</footer>", fi_)
    if fi_ < 0 or fj_ < 0:
        sys.exit('the homepage has no <footer class="site-foot"> to copy')
    FOOTER = home_[fi_:fj_ + len("</footer>")]

    frag = os.path.join(HERE, "_fragments", "correction_figure.html")
    if not os.path.isfile(frag):
        sys.exit("run tools_seo/build_correction_figure.py first: " + frag)
    strip = open(frag, encoding="utf-8").read().strip()
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
            # The confidence grade is no longer published. 51 of 54 were "high" silently
            # and 3 were flagged, which is an unfinished taxonomy rather than a rubric:
            # it invited "why is that one high?" for every paper, obliged a grade on every
            # future one, and all three flagged papers were his own. A caveat that matters
            # belongs in the answer prose, the way /hedge/ carries net-of-fees.
            flag = ""
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
        "name": "Headline results from research on meta-analysis in economics",
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
<title>Headline results from {len(rows)} papers on meta-analysis in economics</title>
<meta name="description" content="One answer per paper: {len(rows)} headline findings from meta-analyses and meta-research in economics, corrected for publication bias where the paper reports a corrected estimate, each with its caveat, the evidence behind it, and a citation." />
<link href="/style.css" rel="stylesheet" type="text/css" />
<script type="application/ld+json">
{jsonld}
</script>
<link rel="canonical" href="https://meta-analysis.cz/results/" />
<meta property="og:site_name" content="meta-analysis.cz" />
<meta property="og:type" content="website" />
<meta property="og:title" content="Headline results from {len(rows)} papers on meta-analysis in economics" />
<meta property="og:description" content="One answer per paper: {len(rows)} headline findings, corrected for publication bias where the paper reports a corrected estimate." />
<meta property="og:url" content="https://meta-analysis.cz/results/" />
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
\t\t\t<li><a href="/search/">Search</a></li>
\t\t</ul>
\t</div>
</div>
</div>
<div id="page">
\t<div id="content">
\t\t<div class="post">
\t\t\t<h1 class="title">Headline results</h1>
\t\t\t<div class="entry results">

<p>One answer per paper: the headline result of each of the {n_rows} papers below, with the
caveat, the evidence, and the citation that belong to it. Where the paper reports a
publication-bias-corrected number, that is the one shown.</p>

{strip}

<p class="r-updated">Figures last assembled {BUILD_DATE}.</p>

<p><b>Read the caveat before you reuse a number.</b> Definitions, samples, and units differ
across literatures, and a corrected mean is still an estimate. The paper's own page carries
the full abstract, and the data and code where they exist. Read it there when the number
matters. The same answers are available as a spreadsheet:
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
{FOOTER}
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
    n_results = page.count('class="result"')
    if n_results != len(rows):
        # The count is lifted out of the f-string: an f-string expression may not contain a
        # backslash before Python 3.12, so this file did not PARSE on 3.11 and the script
        # could not run at all, syntax error rather than a wrong number.
        problems.append(f"{n_results} results, expected {len(rows)}")
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
