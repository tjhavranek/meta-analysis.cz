"""Build the homepage answer board and fold the 54 sentences into a <details>.

The board is one tile per paper: the question the paper asks, the answer it gives.
Nothing here is a new claim. Three existing artifacts supply the content --

  question  <- redesign/results_questions.json   (already owner-reviewed, used on /results/)
  tail      <- estimates.csv `caveat`            (already published beneath each result)
  value     <- tools_seo/answer_board.json       (the ONLY curated text: a tile-sized form of
                                                  `headline`, produced by deletion, never rounded)

and the build refuses to run if any number in a `value` is absent from that row's `headline`.

The 54 full sentences are NOT removed. They keep their existing markup, byte for byte, inside a
collapsed <details>: a reader sees a short page, and every extraction pipeline still sees the
sentences, because <details> content is ordinary DOM text. That was the point of the change.

    python tools_seo/build_answer_board.py [--check]

--check reports what would change and writes nothing.
"""
import csv, html, json, os, re, sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE = os.path.join(BASE, "site")
INDEX = os.path.join(SITE, "index.html")

FIELDS = [("Macroeconomics", "macro"),
          ("Micro and experimental economics", "micro"),
          ("Energy and environmental economics", "energy"),
          ("International economics", "intl"),
          ("Labor and education economics", "labor"),
          ("Financial economics", "fin"),
          ("Meta-research methods", "meth")]

START = '<h2 class="title" id="results">Headline results from these papers</h2>'
E = lambda s: html.escape(s, quote=True)


def numbers(s):
    """Digits only, with the dash variants normalised, so a value can be compared with the
    headline it was cut down from."""
    return set(re.findall(r"\d+(?:\.\d+)?", s.replace("−", "-").replace("–", "-")))


def main():
    check = "--check" in sys.argv
    tiles_only = "--tiles-only" in sys.argv
    refresh = "--refresh-sentences" in sys.argv
    rows = {r["project"]: r for r in csv.DictReader(
        open(os.path.join(SITE, "estimates.csv"), encoding="utf-8"))}
    questions = {q["project"]: q["question"] for q in json.load(
        open(os.path.join(BASE, "redesign", "results_questions.json"), encoding="utf-8"))}
    values = json.load(open(os.path.join(BASE, "tools_seo", "answer_board.json"),
                            encoding="utf-8"))["values"]

    missing = sorted(set(rows) - set(values))
    if missing:
        sys.exit(f"no board value for: {missing}")
    missing_q = sorted(set(rows) - set(questions))
    if missing_q:
        sys.exit(f"no question in results_questions.json for: {missing_q}")

    # the gate: a tile may only ever say what the published headline says
    drift = [(p, sorted(numbers(v["value"]) - numbers(rows[p]["headline"])))
             for p, v in values.items() if numbers(v["value"]) - numbers(rows[p]["headline"])]
    if drift:
        sys.exit("board values carry numbers their headline does not:\n  " +
                 "\n  ".join(f"{p}: {n}" for p, n in drift))

    tiles = 0
    out = [START, '\t\t<div class="entry">',
           # This paragraph used to open with three caveats before the reader had seen a
           # single tile: the precision each paper reports, that units differ, that definitions
           # and samples differ, and "Look at the source first". Most of that is throat-clearing
           # and every tile links the paper anyway -- but units alone turned out not to carry
           # the warning, because eight tiles share "partial correlation coefficient" and a
           # reader could fairly conclude that those eight do compare. Hence the samples, in a
           # clause rather than the sentence of its own it used to have.
           '<p>One tile per paper: the question it asks and the answer it gives. Units differ '
           'from tile to tile, as do the samples behind them, so the numbers do not '
           'compare with one another. The same '
           'results run as full sentences below, and on '
           '<a href="/results/"><b>Headline results</b></a> each one carries the caveat, the '
           'evidence and the citation that belong to it. As a spreadsheet: '
           '<a href="https://meta-analysis.cz/estimates.csv">estimates.csv</a>.</p>']

    for field, cls in FIELDS:
        group = sorted([r for r in rows.values() if r["field"] == field],
                       key=lambda r: r["parameter"].lower())
        if not group:
            continue
        out.append(f'<section class="bf {cls}" aria-labelledby="f-{cls}">')
        out.append(f'<h3 id="f-{cls}">{E(field)}</h3>')
        out.append('<ul class="board" role="list">')
        for r in group:
            p = r["project"]
            v = values[p]
            li = ' class="z"' if v.get("zero") else ""
            # a few papers put the lay equivalent in the headline rather than the
            # caveat column, and the tile would otherwise drop it. An explicit `tail`
            # in the board file wins over the CSV caveat: it is the curated one, written
            # for a tile, and a tile that carries both would otherwise drop it silently.
            tail = v.get("tail") or r["caveat"].strip()
            out.append(f'  <li{li}><a href="/{p}/">')
            out.append(f'    <span class="q">{E(questions[p])}</span>')
            out.append(f'    <span class="a">{E(v["value"])}'
                       + (f' <span class="u">{E(tail)}</span>' if tail else "")
                       + "</span>")
            out.append("  </a></li>")
            tiles += 1
        out.append("</ul>")
        out.append("</section>")

    board = "\n".join(out)

    page = open(INDEX, encoding="utf-8").read()
    i = page.find(START)
    if i < 0:
        sys.exit("the results block is not where it was; look at index.html before rerunning")
    # \r?\n because a fresh Windows clone checks HTML out with CRLF
    m = re.search(r"\t\t</div>\r?\n\t\t</div>", page[i:])
    if not m:
        sys.exit("could not find the end of the results block")
    j = i + m.start()
    old = page[i:j]

    # the existing per-field <p><b>..</b></p><ul>..</ul> run, unchanged, minus the two
    # intro paragraphs the lede replaces
    # Refuse to rebuild on top of a built page. The per-field paragraphs are still there
    # after a build -- they live inside the <details> -- so keying off their absence is not
    # enough: it silently produced a page with one <details> and two </details>.
    if refresh:
        # The 54 sentences inside the <details> are generated by build_estimates.py into
        # tools_seo/estimates_draft.html and injected once. When a caveat is corrected at the
        # source, the tiles and /results/ pick it up but this block does not -- it did not, for
        # a commit, on two papers. This swaps the block for the current generated one.
        #
        # The draft run ends with a stray </div> that the page's copy does not have. Splicing
        # it in unbalanced #content and dropped the sidebar out of the page box -- exactly the
        # failure inject_estimates.py's docstring warns about. So: strip it, then assert.
        draft = open(os.path.join(BASE, "tools_seo", "estimates_draft.html"),
                     encoding="utf-8").read()
        di = draft.find("<p><b>")
        run = draft[di:].rstrip()
        while run.endswith("</div>"):
            run = run[: -len("</div>")].rstrip()
        d0 = old.find('<details class="sentences"')
        if d0 < 0:
            sys.exit("--refresh-sentences expects the built page, with the <details> present")
        p0 = old.find("<p><b>", d0)
        if p0 < 0:
            sys.exit("could not find the per-field sentence lists inside the <details>")
        d1 = old.find("</details>", p0)
        if run.count("<li>") != old[p0:d1].count("<li>"):
            sys.exit(f"the draft has {run.count('<li>')} sentences and the page "
                     f"{old[p0:d1].count('<li>')}; run build_estimates.py first")
        if run.count("<div") != run.count("</div>"):
            sys.exit("the replacement run is not div-balanced; refusing to write")
        merged = page[:i] + old[:p0] + run + "\n" + page[i + d1:]
        if merged.count("<div") != page.count("<div") or            merged.count("</div>") != page.count("</div>"):
            sys.exit("div counts would change; refusing to write")
        if check:
            print(f"would refresh {run.count('<li>')} sentences in place")
            return 0
        open(INDEX, "w", encoding="utf-8", newline="").write(merged)
        print(f"refreshed {run.count('<li>')} sentences from the generated draft")
        _publish()
        return 0

    if '<details class="sentences"' in old:
        # The page is already built, so the sentences must not be re-wrapped. The tiles
        # themselves can still be regenerated: they occupy exactly START..<details>, and
        # rebuilding only that span is how a corrected tile reaches the page without
        # anyone hand-editing HTML. Editing the tiles by hand is what put six answers
        # out of step with their own rows in the first place.
        d = old.find('<details class="sentences"')
        if not tiles_only:
            sys.exit('already built: the sentences are already inside <details>. To update '
                     'the TILES on the built page, rerun with --tiles-only; a full rebuild '
                     'needs the pre-board page:\n'
                     '    git -C site checkout <commit-before-the-board> -- index.html')
        if check:
            print(f"would rewrite {tiles} tiles in place, leaving the <details> alone")
            return 0
        open(INDEX, "w", encoding="utf-8", newline="").write(
            page[:i] + board + "\n" + page[i + d:])
        print(f"answer board: {tiles} tiles rewritten in place; sentences untouched")
        _publish()
        return 0
    if tiles_only:
        sys.exit("--tiles-only expects an already-built page; this one is not built")
    k = old.find("\t\t<p><b>")
    if k < 0:
        sys.exit("could not find the per-field sentence lists")
    sentences = old[k:].rstrip()
    n = sentences.count("<li>")

    block = (board
             + f'\n<details class="sentences">\n'
             + f'<summary>All {n} results as full sentences, with samples and source links'
               f'</summary>\n'
             + sentences + "\n</details>\n")

    if check:
        print(f"would write {tiles} tiles in {len([f for f,_ in FIELDS])} fields, "
              f"wrapping {n} sentences")
        print(f"block: {len(old):,} -> {len(block):,} bytes")
        return 0

    open(INDEX, "w", encoding="utf-8", newline="").write(page[:i] + block + page[j:])
    print(f"answer board: {tiles} tiles, {n} sentences folded into <details>")
    print(f"results block {len(old):,} -> {len(block):,} bytes")
    _publish()
    return 0


def _publish():
    """Keep site/tools/board/ -- the copy a reader can regenerate from -- identical to
    the sources that just ran. See tools_seo/publish_board_sources.py."""
    import subprocess, sys as _s, os as _o
    subprocess.run([_s.executable, _o.path.join(BASE, "tools_seo",
                                                "publish_board_sources.py")], check=False)

if __name__ == "__main__":
    sys.exit(main())
