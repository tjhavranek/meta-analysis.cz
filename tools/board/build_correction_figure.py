"""Draw the correction strip for /results/: what bias correction did to his own numbers.

One dot per paper, placed on a real axis by how far the correction moved the number, RED
where the corrected or best-practice estimate is smaller in absolute magnitude than the
average estimate the literature reported and GREEN where it is larger.

Only papers that qualify under the rule in correction_ratios.json appear, and the rule is
DIRECTION-BLIND -- an adversarial review found that an earlier version had put every upward
revision in the excluded set, which made "all of them moved toward zero" a property of the
rule rather than a finding. Every paper that does not qualify is listed there with its reason,
and the build refuses to run if one is missing.

**The comparator is the paper's own uncorrected mean wherever it states one**, and then the
shipped column is not consulted at all. That matters more than it sounds: the harmonised table
keeps only estimates that report a usable standard error -- 539 of discrate's 927, 532 of
frisch's 723 -- so a mean computed from it inherits whatever selection that introduces. Three
rows were wrong for exactly that reason before an audit caught them.

Otherwise the comparator is computed HERE and never typed into the JSON: a 1%-winsorised mean
of that literature's `effect` column. Winsorising moves the median revision by about a point
overall but decides one row outright -- the skill-substitution literature contains an estimate
of 1000, so its raw mean is set by a handful of such values.

The caption states the index under a second comparator, the literature's median, so a reader
who distrusts the mean can see what changes.

The index is (|corrected| - |mean|) / |mean|, which is the relative research revision of
Table 3 in Gechert et al. (2025), his own paper, already on this site at
/conventional_wisdom/. Using the same index twice is the point.

    python tools_seo/build_correction_figure.py [--check]

Writes redesign/_fragments/correction_figure.html, inlined by redesign/build_results_page.py.
"""
import csv, json, math, os, re, statistics, sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Either layout: in development the inputs sit at the top level, in the published repo the
# board's own files sit beside this script. Same rule as _resolve_site in the sibling
# scripts -- prefer the development path when it exists, otherwise look here.
HERE = os.path.dirname(os.path.abspath(__file__))


ROOT = os.path.dirname(BASE)          # BASE is tools/, the site root is one further up


def _either(dev, here):
    return dev if os.path.exists(dev) else here


SRC = _either(os.path.join(BASE, "tools_seo", "correction_ratios.json"),
              os.path.join(HERE, "correction_ratios.json"))
DATA = _either(os.path.join(BASE, "site", "data", "v1", "estimates_harmonised.csv"),
               os.path.join(ROOT, "data", "v1", "estimates_harmonised.csv"))
EST = _either(os.path.join(BASE, "site", "estimates.csv"),
              os.path.join(ROOT, "estimates.csv"))
QUESTIONS = _either(os.path.join(BASE, "redesign", "results_questions.json"),
                    os.path.join(HERE, "results_questions.json"))
FRAG = _either(os.path.join(BASE, "redesign", "_fragments", "correction_figure.html"),
               os.path.join(HERE, "_fragments", "correction_figure.html"))

CODEBOOKS = _either(os.path.join(BASE, "site", "api", "v1", "codebooks"),
                    os.path.join(ROOT, "api", "v1", "codebooks"))

TIER_ORDER = ["range", "horizon", "table", "subsample", "ratio", "method_median", "pooled",
              "data_mean", "benchmark", "illustration", "projection", "unmoved"]
TIER_WORDS = {
    "unmoved": "a literature whose own test finds no publication bias to correct, so the "
               "corrected value is the reported one",
    "range": "the central value of a range, or an upper bound",
    "horizon": "the horizon the paper leads with",
    "table": "a number read from a results table where the headline is verbal",
    "subsample": "the subsample the paper leads with",
    "ratio": "a revision the paper states directly rather than as two levels",
    "method_median": "the median of the correction methods the paper reports, where it "
                     "prefers none of them",
    "pooled": "the paper's own uncorrected pooled estimate, where it prints no simple mean",
    "data_mean": "a comparator computed from the released estimates, because the paper "
                 "pools none itself",
    "projection": "a best-practice value the paper evaluates at a preferred data year later "
                  "than any vintage in its own sample",
    "benchmark": "a canonical value the paper itself names, in place of a reported mean",
    "illustration": "the worked example a methods paper applies its correction to, rather "
                    "than a literature of its own",
}

E = lambda s: (str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
               .replace('"', "&quot;"))


def winsorised_mean(values, p=0.01):
    v = sorted(values)
    n = len(v)
    lo, hi = v[int(p * (n - 1))], v[int((1 - p) * (n - 1))]
    return statistics.mean(min(max(x, lo), hi) for x in v)


def codebook_mean(project, column):
    """The mean of one released column, read from the published codebook.

    Not every literature reaches the harmonised table -- it keeps only estimates that report
    a usable standard error, and a few datasets report none -- but every one of them has a
    codebook, generated from the source file and served at /api/v1/codebooks/. Reading the
    mean from there keeps the promise the file makes elsewhere: a comparator is either quoted
    from the paper or computed, never typed into the spec by hand."""
    path = os.path.join(CODEBOOKS, "%s.json" % project)
    if not os.path.isfile(path):
        sys.exit("%s: no codebook at %s" % (project, path))
    book = json.load(open(path, encoding="utf-8"))
    for col in book.get("columns", []):
        if col.get("name") == column or col.get("normalized") == column:
            if col.get("n_missing"):
                sys.exit("%s: codebook column %s has missing values; its mean would rest on "
                         "a subset" % (project, column))
            return col["stats"]["mean"], book.get("n_rows")
    sys.exit("%s: codebook has no column %r" % (project, column))


_PAGE_TEXT = {}


def _page_text(project, meta_slug=None):
    """The full text of a paper as this site serves it, flattened for matching."""
    if project in _PAGE_TEXT:
        return _PAGE_TEXT[project]
    import html as _h
    out = None
    for rel in ((meta_slug + "/index.html",) if meta_slug else ()) + (
            "%s/paper/index.html" % project,):
        path = os.path.join(ROOT, rel)
        if os.path.isfile(path):
            raw = open(path, encoding="utf-8").read()
            raw = re.sub(r"<(script|style|head)\b.*?</\1>", " ", raw, flags=re.S)
            out = _h.unescape(re.sub(r"<[^>]+>", " ", raw))
            break
    _PAGE_TEXT[project] = out
    return out


def _norm_quote(s):
    """Drop everything a transcription can legitimately differ on: spacing, the shape of a
    dash or a quote mark, subscripts written as plain digits."""
    return re.sub(r"[^a-z0-9]", "", s.lower())


def check_quote(project, quote, kind):
    """A quote the spec calls a sentence has to be findable in the paper as this site serves it.

    This exists because it was not caught by review: a corrected_quote sat in this file for a
    day reading "the best-practice estimate of the effect of reforms on growth for the short run
    reaches -0.38", a sentence that appears nowhere in that paper. The numbers in it were right
    and the paraphrase was fair, which is exactly why nobody noticed. The readme promises these
    are verbatim, so the promise is now a build step. Quotes assembled from a results table
    declare `quote_kind: "table"` and are exempt, because a table read into a sentence is not a
    sentence the paper contains."""
    if kind == "table":
        return
    text = _page_text(project)
    if text is None:                       # no full text on this site to check against
        return
    hay = _norm_quote(text)
    # An ellipsis in a quote is an elision the reader can see. Each side of it still has to be
    # in the paper, and in order.
    at = 0
    for part in [x for x in quote.split("...") if _norm_quote(x)]:
        i = hay.find(_norm_quote(part), at)
        if i < 0:
            sys.exit("%s: this quote is not in the paper as this site serves it. Either quote "
                     "the paper's own words, or declare it 'table' if it is assembled from a "
                     "results table.\n  %s" % (project, part.strip()[:120]))
        at = i + len(_norm_quote(part))


def load_effects():
    out = {}
    with open(DATA, encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            try:
                v = float(r["effect"])
            except (TypeError, ValueError):
                continue
            out.setdefault(r["dataset"], []).append(v)
    return out


def build(check=False):
    spec = json.load(open(SRC, encoding="utf-8"))
    effects = load_effects()
    rows = {r["project"]: r for r in csv.DictReader(open(EST, encoding="utf-8"))}
    # results_questions.json is the owner-reviewed list: one question and a SHORT label per
    # paper. The short label is what fits under a dot.
    qs = {q["project"]: q for q in json.load(open(QUESTIONS, encoding="utf-8"))}

    n_all = len(rows)
    # The caption says every paper that did not qualify is written down with its reason. That
    # was false once -- 41 papers did not qualify and 27 were listed -- so it is now a build
    # gate rather than a promise.
    plotted = {r["project"] for r in spec["rows"]}
    left_out = {e["project"] for e in spec["excluded"]}
    # Moving a paper between the two lists is a two-step edit, and leaving it in both passed
    # the coverage gate silently while the totals stopped adding up.
    both = sorted(plotted & left_out)
    if both:
        sys.exit("correction_ratios.json both plots and excludes: " + ", ".join(both))
    if len(spec["rows"]) + len(spec["excluded"]) != len(rows):
        sys.exit("correction_ratios.json has %d rows and %d exclusions, which is not the %d "
                 "papers in estimates.csv" % (len(spec["rows"]), len(spec["excluded"]),
                                              len(rows)))
    accounted = plotted | left_out
    unaccounted = sorted(set(rows) - accounted)
    if unaccounted:
        sys.exit("correction_ratios.json accounts for neither including nor excluding: "
                 + ", ".join(unaccounted)
                 + "\n  The caption claims every paper is listed. Add each one to "
                   "`excluded` with its reason.")
    out = []
    for r in spec["rows"]:
        p = r["project"]
        if p not in rows:
            sys.exit(f"{p} is not in estimates.csv")
        # Every corrected value has to be traceable to the paper's own words. Rows quoted
        # from the site's own estimates.csv are checked against it, so an edit there can
        # never silently drift from this file. Rows quoted from the PDF instead -- most of
        # them, because the uncorrected comparator usually lives in a results table rather
        # than in the abstract -- must carry a locator precise enough to check by hand.
        if r.get("quote_source", "site") == "site":
            q = (rows[p].get("source_quote") or "").strip()
            if r["corrected_quote"][:40] not in q:
                sys.exit(f"{p}: the quoted corrected sentence is not this paper's "
                         f"source_quote any more. Re-read the paper before publishing.\n"
                         f"  json : {r['corrected_quote'][:80]}\n  site : {q[:80]}")
        elif len((r.get("corrected_locator") or "").strip()) < 12:
            sys.exit(f"{p}: quote_source is 'pdf', so corrected_locator must say where in the "
                     f"paper the number is, precisely enough for a reader to check it")
        check_quote(p, r.get("corrected_quote") or "", r.get("quote_kind", "sentence"))
        if r.get("mean_quote"):
            check_quote(p, r["mean_quote"], r.get("mean_quote_kind",
                                                  r.get("quote_kind", "sentence")))
        # A row drawn as a solid disc claims its pair is exact, so the number a reader sees has
        # to be findable in the sentence quoted beside it. A row that cannot meet that is
        # approximate by definition, and then it owes the reader a note saying what is
        # approximate about it -- which is what the tooltip shows and the ring signals.
        tier = r.get("tier", "exact")
        shown = f'{r["corrected"]:g}'.lstrip("-")
        if tier == "exact":
            if shown not in (r["corrected_quote"] or "").replace("−", "-"):
                sys.exit(f"{p}: the corrected value {shown} does not appear in the sentence "
                         f"quoted for it. Either quote the sentence that contains it, or give "
                         f"the row a tier and an `approximation` note and let it draw as a ring.")
        elif not (r.get("approximation") or "").strip():
            sys.exit(f"{p}: tier '{tier}' is drawn as a ring, so it needs an `approximation` "
                     f"note saying what is approximate about the pair")
        # A corrected value the paper reports several ways and prefers none of: the median of
        # the methods it does report. Computed here rather than typed, so the spec can list
        # every method and the file cannot quietly drift from the number that is plotted.
        corrected = r["corrected"]
        if r.get("corrected_from") == "method_median":
            vals = [m["value"] for m in (r.get("methods") or [])]
            if len(vals) < 3:
                sys.exit(f"{p}: a method median needs at least three reported methods")
            got = statistics.median(vals)
            if abs(got - corrected) > 1e-9:
                sys.exit(f"{p}: the spec says corrected {corrected:g} but the median of the "
                         f"methods it lists is {got:g}")
            # The corrected hierarchy admits a median only where the methods agree on the
            # substantive conclusion. Enforced here rather than left to prose: resource_curse
            # reports +0.026, +0.038, -0.589 and -0.133 and would fail this line.
            if any(v * got < 0 for v in vals):
                sys.exit(f"{p}: the correction methods do not agree on the sign, so their "
                         f"median is not a corrected value this figure can plot")
            corrected = got
        mean_from = r.get("mean_from")
        if mean_from == "ratio":
            # the paper states the revision itself ("exaggerates the mean reported estimate
            # twofold"), so there is nothing to divide -- and nothing to get wrong either
            rev = r["revision_pct"]
            if rev is None:
                sys.exit(f"{p}: mean_from is 'ratio' but no revision_pct is given")
            mean = None
        else:
            if mean_from in ("paper", "pooled", "benchmark"):
                # quoted from the paper: its own simple mean, its own uncorrected pooled
                # summary, or the canonical value it names when it reports neither
                mean = r["mean"]
                if mean is None:
                    sys.exit(f"{p}: mean_from is {mean_from!r} but no mean is given")
                if mean_from != "paper" and not (r.get("mean_quote") or "").strip():
                    # `paper` is the ordinary case and its provenance is in the note. A pooled
                    # estimate or a canonical benchmark is not the comparator a reader expects,
                    # so each of those has to quote the sentence it came from.
                    sys.exit(f"{p}: mean_from is {mean_from!r}, so the comparator has to carry "
                             f"a `mean_quote` -- it is not the default, and a reader has to be "
                             f"able to find it in the paper")
            elif mean_from == "codebook":
                col = (r.get("mean_column") or "").strip()
                if not col:
                    sys.exit(f"{p}: mean_from is 'codebook' but no `mean_column` is named")
                mean, n_rows = codebook_mean(p, col)
                if abs(mean - r.get("mean", mean)) > 5e-6:
                    sys.exit(f"{p}: the spec says mean {r['mean']:g} but the codebook column "
                             f"{col} averages {mean:g}")
            elif mean_from in (None, "data"):
                if p not in effects:
                    sys.exit(f"{p}: no estimate-level data, so no comparator can be computed")
                mean = winsorised_mean(effects[p])
            else:
                # A typo in mean_from used to fall through to the data branch and quietly plot
                # a comparator nobody asked for.
                sys.exit(f"{p}: unknown mean_from {mean_from!r}")
            if abs(mean) < 1e-9:
                sys.exit(f"{p}: the comparator is zero; the ratio is undefined")
            rev = (abs(corrected) - abs(mean)) / abs(mean) * 100.0
        # A literature whose own publication-bias test comes back empty has nothing to correct,
        # so the honest revision is zero however the two printed numbers happen to divide. The
        # flag exists because the alternative -- dividing a near-zero corrected constant by a
        # near-zero simple mean -- reports a percentage that is an artefact of the denominator
        # and not a finding. It is not a licence to zero out an inconvenient ratio: the row
        # still has to quote the sentence in which the paper reports finding no bias.
        if r.get("verbal_zero"):
            if not (r.get("approximation") or "").strip():
                sys.exit(f"{p}: a verbal_zero row must say in `approximation` why the paper "
                         f"reports nothing to correct")
            rev = 0.0
        # Two facts a magnitude axis cannot carry, so they are carried in words instead.
        # A verbal_zero row asserts that neither number is distinguishable from zero, so the
        # arithmetic sign that separates them is noise. Calling that a sign reversal would
        # contradict the row's own claim on the same dot.
        flipped = (mean is not None and mean * corrected < 0
                   and not r.get("verbal_zero"))
        if r.get("small_base") and not (r.get("approximation") or "").strip():
            sys.exit(f"{p}: small_base rows must say in `approximation` why both levels are "
                     f"negligible, or the percentage is all a reader sees")
        out.append({**r, "corrected": corrected, "mean": mean, "rev": rev,
                    "tier": r.get("tier", "exact"), "flipped": flipped,
                    "n": len(effects.get(p, [])),
                    "question": qs.get(p, {}).get("question", ""),
                    "title": qs.get(p, {}).get("short") or rows[p].get("parameter") or p})

    out.sort(key=lambda r: r["rev"])
    # A revision of exactly 0% is neither toward zero nor away from it. Counting it as
    # "away", which `len(out) - len(down)` did, would report a paper whose corrected value
    # equals its comparator as having moved away from zero.
    EPS = 1e-9
    down = [r for r in out if r["rev"] < -EPS]
    up = [r for r in out if r["rev"] > EPS]
    flat = [r for r in out if abs(r["rev"]) <= EPS]
    # A sign reversal is the one thing a magnitude axis is structurally unable to say. It is
    # not a reason to drop the row -- the plotted index exists either way -- but it has to be
    # said in words, on the dot, in the tooltip, in the caption and in the description.
    flipped = [r for r in out if r.get("flipped")]
    small = [r for r in out if r.get("small_base")]
    med = statistics.median([r["rev"] for r in out])

    if check:
        print(f"{len(out)} of {n_all} papers qualify; median revision {med:+.0f}%")
        for r in out:
            src = {"paper": "paper mean", "ratio": "stated ratio",
                   "pooled": "paper pooled", "benchmark": "benchmark",
                   "codebook": f"codebook {r.get('mean_column')}"}.get(
                r.get("mean_from"), f"data n={r['n']}")
            m = "     --" if r["mean"] is None else f"{r['mean']:9.4g}"
            c = "  --" if r["corrected"] is None else f"{r['corrected']:g}"
            tier = "" if r["tier"] == "exact" else f"  [{r['tier']}]"
            print(f"  {r['rev']:+7.1f}%  {r['project']:20} corrected {c:>8} "
                  f"vs mean {m}  ({src}){tier}")
        return 0

    # ---- the strip -------------------------------------------------------------
    # A line of dots, as asked for -- but positioned on a real axis rather than spaced
    # evenly, because colour intensity cannot tell -35% from -70% and position can. The
    # colour is still there and still means direction; it now reinforces the position
    # instead of carrying the whole message alone.
    # One paper moved +631%. Letting the axis reach it would stretch the scale six times
    # and collapse the other twenty-seven dots into a smudge at the left, so the axis holds
    # the range the bulk of the papers live in and anything past it is drawn at the edge,
    # marked as off scale, with its exact value in the tooltip, the caption and the <desc>.
    # Dropping the paper instead would let the drawing decide the evidence.
    revs = [r["rev"] for r in out]
    lo = min(min(revs), 0.0)
    hi = max(max(revs), 0.0)
    lo = math.floor(lo / 25.0) * 25.0
    hi = math.ceil(hi / 25.0) * 25.0
    CAP = 150.0
    offscale = [r for r in out if r["rev"] > CAP]
    if offscale:
        hi = max(CAP, math.ceil(max((r["rev"] for r in out if r["rev"] <= CAP),
                                    default=CAP) / 25.0) * 25.0)
    L, RM, W = 34, 34, 760   # room for the outermost tick label
    plot = W - L - RM
    X = lambda v: L + (v - lo) / (hi - lo) * plot
    AX, R = 92, 9                       # axis y, dot radius
    H = AX + 50

    p = [f'<svg viewBox="0 0 {W} {H}" width="100%" role="img" '
         f'aria-labelledby="cf-t cf-d" class="cfig">',
         '<title id="cf-t">What meta-analysis did to each number</title>',
         f'<desc id="cf-d">One dot per meta-analysis, placed by how far its corrected or '
         f'best-practice estimate sits from the uncorrected number for that literature. '
         f'{len(down)} of the {len(out)} moved toward zero and {len(up)} away '
         f'from it; the median revision is {med:+.0f}%.'
         + (" " + " ".join(f'{r["title"]} moved {r["rev"]:+.0f}%, beyond the right-hand end '
                           f'of the scale.' for r in offscale) if offscale else "")
         + (' In ' + str(len(flipped)) + ' the correction also reversed the sign, which this '
            'axis cannot show: ' + ", ".join(r["title"] for r in flipped) + '.'
            if flipped else "")
         + '</desc>']

    # lay the dots out first: the two vertical guides have to clear the tallest stack, and
    # how tall that is depends on how many papers cluster at the same revision
    placed, lanes = [], []
    for r in sorted(out, key=lambda r: r["rev"]):
        x = X(min(r["rev"], hi))
        lane = 0
        while lane < len(lanes) and lanes[lane] > x - 2 * R - 1:
            lane += 1
        if lane == len(lanes):
            lanes.append(x)
        else:
            lanes[lane] = x
        placed.append((r, x, AX - R - 3 - lane * (2 * R + 3)))
    # an off-scale dot sits at the end of the axis, where a reader would otherwise take it
    # for a dot AT the end of the axis. A chevron pointing off the edge says it continues.
    arrows = [(x, y) for r, x, y in placed if r["rev"] > hi]
    top = min(y for _, _, y in placed) - R
    for ax_, ay_ in arrows:
        p.append(f'<path d="M {ax_ + R + 4:.1f} {ay_ - 5:.1f} l 5 5 l -5 5" fill="none" '
                 f'stroke="var(--rv-up)" stroke-width="2" stroke-linecap="round" '
                 f'stroke-linejoin="round"/>')

    # ticks every 25%, labelled every 50, plus the zero line the whole figure hangs on
    t = lo
    while t <= hi + 0.01:
        x = X(t)
        major = abs(t) % 50 < 0.01
        p.append(f'<line x1="{x:.1f}" y1="{AX}" x2="{x:.1f}" y2="{AX + (7 if major else 4)}" '
                 f'stroke="var(--rule)"/>')
        if major:
            p.append(f'<text x="{x:.1f}" y="{AX + 20}" text-anchor="middle" class="cfa">'
                     f'{t:+.0f}%</text>')
        t += 25.0
    p.append(f'<line x1="{L}" y1="{AX}" x2="{W - RM}" y2="{AX}" stroke="var(--rule)"/>')
    zx, mx = X(0.0), X(med)
    p.append(f'<line x1="{zx:.1f}" y1="{top - 6}" x2="{zx:.1f}" y2="{AX + 7}" '
             f'stroke="var(--control)"/>')
    p.append(f'<text x="{zx:.1f}" y="{top - 12}" text-anchor="middle" class="cfa">'
             f'no change</text>')
    p.append(f'<line x1="{mx:.1f}" y1="{top - 6}" x2="{mx:.1f}" y2="{AX}" '
             f'stroke="var(--rv-down)" stroke-dasharray="3 3"/>')
    p.append(f'<text x="{mx:.1f}" y="{top - 12}" text-anchor="middle" class="cfl">'
             f'median {med:+.0f}%</text>')

    for r, x, y in placed:
        mag = min(abs(r["rev"]), 100.0) / 100.0
        op = 0.30 + 0.70 * mag
        fill = "var(--rv-down)" if r["rev"] < 0 else "var(--rv-up)"
        # What the comparator IS depends on which rung of the hierarchy it came from, and a
        # tooltip that says "reported estimates average" over a pooled estimate or a policy
        # benchmark asserts the opposite of the ring beside it.
        LEAD = {"pooled": "The paper's own uncorrected pooled estimate is",
                "benchmark": "The benchmark the paper names is",
                "codebook": "The released estimates average"}
        lead = LEAD.get(r.get("mean_from"), "Reported estimates average")
        if r["mean"] is None:
            tip = f'{r["title"]}. The paper states the revision itself: {r["rev"]:+.0f}%.'
        elif r.get("verbal_zero"):
            tip = (f'{r["title"]}. {lead} {r["mean"]:.3g}; corrected or best practice '
                   f'{r["corrected"]:g}. The paper reports no publication bias worth '
                   f'correcting, so the figure plots no change.')
        else:
            tip = (f'{r["title"]}. {lead} {r["mean"]:.3g}; '
                   f'corrected or best practice {r["corrected"]:g}. {r["rev"]:+.0f}%.')
        if r["rev"] > hi:
            tip = (f'{r["title"]}. {lead} {r["mean"]:.3g}; '
                   f'corrected or best practice {r["corrected"]:g}. {r["rev"]:+.0f}%, '
                   f'drawn at the edge because it is off the scale.')
        if r["tier"] != "exact" and r.get("approximation"):
            ap = r["approximation"].strip()
            tip += " " + ap + ("" if ap.endswith((".", "!", "?")) else ".")
        if r.get("flipped"):
            tip += (f' The sign changed, from {r["mean"]:.3g} to {r["corrected"]:g}, which the '
                    f'axis cannot show: only the change in absolute magnitude is plotted.')
        if r.get("small_base"):
            tip += (' Both levels are economically negligible, so the percentage is a large '
                    'relative change from a small base.')
        p.append(f'<a href="#{E(r["project"])}"><title>{E(tip)}</title>')
        # an invisible target twice the dot: 18 user-units is a small thing to hit with a thumb
        p.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{R * 2}" fill="transparent"/>')
        p.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{R}" fill="{fill}" '
                 f'fill-opacity="{op:.2f}"/>')
        if r.get("flipped"):
            # a dot whose sign reversed is drawn outlined, so that the rows the axis cannot
            # describe are the ones a reader can pick out without reading a tooltip
            p.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{R}" fill="none" '
                     f'stroke="var(--ink)" stroke-width="1.6"/>')
        if r["tier"] != "exact":
            # a ring, not a disc: the approximate rows have to be tellable apart at a glance,
            # or the caption's count of them is the only thing standing between a reader and
            # the impression that all of these pairs are equally solid
            p.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{R * 0.42:.1f}" '
                     f'fill="var(--paper)"/>')
        p.append("</a>")

    p.append(f'<text x="{L}" y="{AX + 40}" text-anchor="start" class="cfa">'
             f'smaller after correction</text>')
    p.append(f'<text x="{W - RM}" y="{AX + 40}" text-anchor="end" class="cfa">'
             f'larger after correction</text>')
    p.append("</svg>")
    # The two labels above the plot sit on a baseline at `top - 12`, so a viewBox starting at
    # `top - 20` left 8 units of headroom for a 15px cap height: both "median -51%" and "no
    # change" had their tops sliced off. Headroom is now the label's own size plus its offset,
    # with a little to spare. The width is unchanged, so the labels render at the same size --
    # the box is taller, not the type smaller.
    LABEL_PX = 15
    head = top - 12 - LABEL_PX - 4
    p[0] = p[0].replace(f'viewBox="0 0 {W} {H}"',
                        f'viewBox="0 {head:.0f} {W} {H - head:.0f}"')

    excl = len(spec["excluded"])
    up = [r for r in out if r["rev"] > 0]
    # the same index under a comparator the figure does NOT use, so the caption can say what
    # happens if you disagree with the one it does
    # Substituting a median is only meaningful where the comparator came from that column in
    # the first place. Where the paper states its own mean, its corrected value need not be in
    # the column's units at all -- size is an annualised premium in percent against a column of
    # slopes, migrant an elasticity against a different transform -- and swapping in the column
    # median produced +25,961% and +33,900%. Those two artefacts were the whole of the reported
    # "5 turn upward".
    alt, n_alt = [], 0
    for r in out:
        v = effects.get(r["project"])
        if r.get("mean_from") == "data" and v:
            n_alt += 1
            m = statistics.median(v)
            alt.append((abs(r["corrected"]) - abs(m)) / abs(m) * 100.0)
        else:
            alt.append(r["rev"])
    alt_med = statistics.median(alt)
    alt_up = sum(1 for x in alt if x > 0)
    n_paper = sum(1 for r in out if r.get("mean_from") == "paper")
    n_computed = sum(1 for r in out
                     if r.get("mean_from") in (None, "data", "codebook"))
    n_approx = sum(1 for r in out if r["tier"] != "exact")
    n_up = len(up)
    tier_counts = {}
    for r in out:
        if r["tier"] != "exact":
            tier_counts[r["tier"]] = tier_counts.get(r["tier"], 0) + 1
    NOLIT = {"guidelines", "maive", "outliers", "pcc",
             "pcc_survey", "conventional_wisdom", "debate"}
    n_nolit = len([e for e in spec["excluded"] if e["project"] in NOLIT])

    # The caption had grown to hold the comparator rule, the sensitivity check, the ring
    # taxonomy, the exclusion taxonomy and a defence of the selection rule. All of it is worth
    # keeping and none of it is what a reader wants first. The finding stays visible; the
    # method goes in a <details>, whose content is ordinary DOM text and so still reaches
    # every crawler and every text corpus -- unlike a <script>, which they discard.
    caption = (
        '<figcaption class="table-note">'
        '<b>What meta-analysis did to the number.</b> '
        f'<b>{len(out)} of the {n_all} papers here can be compared this way</b>: an '
        'uncorrected figure for a literature against a corrected or best-practice estimate of '
        'the same thing. One dot each, placed by how far the second sits from the first. '
        '<b>Red</b>: smaller <i>in absolute magnitude</i>. <b>Green</b>: larger. '
        + (f'<b>All {len(out)} moved toward zero</b>. ' if len(down) == len(out) else
           f'<b>{len(down)} moved toward zero, {n_up} away</b> from it. ')
        + (f'<b>{len(flat)}</b> did not move. ' if flat else '')
        + f'The median revision is <b>{med:+.0f}%</b>. '
        + 'Hover a dot for its own numbers. The note below says how the figure is built, '
          'which papers it leaves out, and what the rings and outlines mean.'
        '<details class="figmethod"><summary>How this figure is built, and which papers it '
        'leaves out</summary>'

        '<p><b>What is plotted.</b> Each dot is one literature. The horizontal position is '
        '<i>(|corrected| &minus; |mean|) / |mean|</i>: how far the corrected or best-practice '
        'estimate sits from the uncorrected one, as a fraction of the uncorrected one, in '
        'absolute magnitude. Zero means the correction left the size of the number alone; '
        '&minus;50% means it halved it; +100% means it doubled it. It is the same relative '
        'revision as Table 3 of <a href="/conventional_wisdom/">Gechert et al. (2025)</a>, '
        'which applies it to 24 literatures mostly by other researchers. Vertical position '
        'carries no meaning: the dots are stacked only to keep them apart.</p>'

        f'<p><b>Where the uncorrected number comes from.</b> The comparator is the uncorrected '
        f'number. It is chosen by a fixed order, and the first one that exists wins. The '
        f'paper&rsquo;s own uncorrected mean for '
        f'the same quantity, which {n_paper} of the {len(out)} state. Failing that, the '
        'paper&rsquo;s own uncorrected pooled estimate of it. Failing that, the average of that '
        'literature&rsquo;s estimates as released here, winsorised at 1%. And only where a paper '
        'reports none of those, the canonical value the paper itself names as the number its '
        'field had been working with. The paper&rsquo;s own figure comes first because the '
        'harmonised table keeps only estimates that report a usable standard error, so a mean '
        'computed from it can rest on a subset of what the paper analysed.</p>'

        '<p><b>Where the corrected number comes from.</b> Several of these papers do not simply '
        'average their estimates. They evaluate their model at the literature&rsquo;s preferred '
        'values, for recent data, more observations, and better-cited outlets, and report that '
        'as the figure a careful study would have produced. It is the construction these authors '
        'use, it is what Gechert et al.&rsquo;s corrected column is built from, and in each case '
        'it is the paper&rsquo;s own headline conclusion. The rows concerned name it in the '
        'spec. Most of these papers correct with estimators that shrink toward zero; what the '
        'figure adds is the size of each move.</p>'

        '<p><b>What the marks mean.</b> A solid dot is a pair both of whose numbers the paper '
        'states for the same quantity. A ring is a pair that is approximate in a stated way, and '
        'hovering it says which way. An outline means the correction did not only change the '
        'size of the number but its direction, which an axis of magnitudes cannot show.</p>'

        + f'<p><b>{len(out)} of the {n_all} papers qualify.</b> Of the other {n_all - len(out)}, '
        f'{n_nolit} have no single literature effect to correct: methods papers, an '
        'experiment, and the review that supplies the companion figure. The rest answer in words '
        'rather than a number, or give a headline that is not a correction at all, or reach it '
        'by projecting the estimand beyond the sample rather than correcting it, or sit '
        'against a comparator so near zero that the ratio is undefined, or report correction '
        'methods that disagree with each other about the sign; and a literature that already '
        'has a dot does not get a second one. A reversal of sign is <i>not</i> a reason to '
        'leave a paper out. The rule takes no account of which way a paper moved, and every one '
        f'of those {n_all - len(out)} is written down with its reason, individually, in '
        '<a href="/tools/board/correction_ratios.json">correction_ratios.json</a>.</p>'

        + f'<p><b>If you distrust means</b>, there is a second reading. {n_computed} of the '
        f'{len(out)} comparators are computed here rather than quoted from a paper. For the '
        f'{n_alt} of those taken from the harmonised table they are winsorised means; use the '
        f'median of those literatures&rsquo; estimates instead and the overall median revision '
        f'becomes {alt_med:+.0f}%'
        + (f', with the number moving upward unchanged at {n_up}. ' if alt_up == n_up else
           f', and {alt_up} of the {len(out)} move upward rather than {n_up}. ')
        + 'The swap is confined to those rows on purpose: where a paper states its own mean, its '
        'corrected value need not be in the same units as the estimate column at all, so a '
        'median taken from that column would not be a comparator. The check covers only the '
        'estimates this site holds, under the same standard-error selection.</p>'

        + (f'<p><b>Off the scale.</b> {len(offscale)} of the dots are drawn at the right-hand '
           'edge because their revisions run past the end of it: '
           + ", ".join(f'{E(r["title"])} at <b>{r["rev"]:+.0f}%</b>' for r in offscale)
           + '.</p>' if offscale else '')
        + (f'<p><b>Where the sign reversed.</b> In {len(flipped)} the correction changed the '
           'direction of the number as well as its size: '
           + ", ".join(E(r["title"]) for r in flipped)
           + '. Those dots are drawn with an outline and say so when you hover them.</p>'
           if flipped else '')
        + (f'<p><b>The {n_approx} rings</b> are pairs that are approximate in a stated way: '
           + ", ".join(TIER_WORDS[t] + f" ({tier_counts[t]})" for t in TIER_ORDER
                       if tier_counts.get(t))
           + '. Hover a ring and it says which.</p>' if n_approx else '')
        + (f'<p><b>Where the base is small.</b> In {len(small)} of the {len(out)} both the '
           'reported and the corrected level are economically negligible in the paper&rsquo;s '
           'own terms ('
           + ", ".join(E(r["title"]) for r in small)
           + '), so a large percentage is a large relative change from a small base rather '
             'than a large effect.</p>' if small else '')
        + '</details></figcaption>')

    os.makedirs(os.path.dirname(FRAG), exist_ok=True)
    # The drawing scrolls; the caption does not. Without the wrapper the SVG scales its
    # 760-unit box to whatever width it is given -- 47% on a phone, which put the axis labels
    # at 5px. The other two figures on the site already scroll rather than shrink.
    open(FRAG, "w", encoding="utf-8", newline="\n").write(
        '<figure class="cfig-wrap">\n<div class="cfig-scroll">\n' + "\n".join(p)
        + "\n</div>\n" + caption + "\n</figure>\n")
    print(f"  wrote {os.path.relpath(FRAG, BASE)}  ({len(out)} of {n_all} papers, "
          f"{len(down)} down, median {med:+.0f}%, {excl} exclusions recorded)")
    import subprocess
    subprocess.run([sys.executable, os.path.join(BASE, "tools_seo",
                                                 "publish_board_sources.py")], check=False)
    return 0


if __name__ == "__main__":
    sys.exit(build("--check" in sys.argv))
