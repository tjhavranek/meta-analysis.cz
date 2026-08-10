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
import csv, json, math, os, statistics, sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(BASE, "tools_seo", "correction_ratios.json")
DATA = os.path.join(BASE, "site", "data", "v1", "estimates_harmonised.csv")
EST = os.path.join(BASE, "site", "estimates.csv")
QUESTIONS = os.path.join(BASE, "redesign", "results_questions.json")
FRAG = os.path.join(BASE, "redesign", "_fragments", "correction_figure.html")

E = lambda s: (str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
               .replace('"', "&quot;"))


def winsorised_mean(values, p=0.01):
    v = sorted(values)
    n = len(v)
    lo, hi = v[int(p * (n - 1))], v[int((1 - p) * (n - 1))]
    return statistics.mean(min(max(x, lo), hi) for x in v)


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
    accounted = {r["project"] for r in spec["rows"]} | {e["project"] for e in spec["excluded"]}
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
        if r.get("mean_from") == "ratio":
            # the paper states the revision itself ("exaggerates the mean reported estimate
            # twofold"), so there is nothing to divide -- and nothing to get wrong either
            rev = r["revision_pct"]
            if rev is None:
                sys.exit(f"{p}: mean_from is 'ratio' but no revision_pct is given")
            mean = None
        else:
            if r.get("mean_from") == "paper":
                mean = r["mean"]
                if mean is None:
                    sys.exit(f"{p}: mean_from is 'paper' but no mean is given")
            else:
                if p not in effects:
                    sys.exit(f"{p}: no estimate-level data, so no comparator can be computed")
                mean = winsorised_mean(effects[p])
            if abs(mean) < 1e-9:
                sys.exit(f"{p}: the comparator is zero; the ratio is undefined")
            rev = (abs(r["corrected"]) - abs(mean)) / abs(mean) * 100.0
        out.append({**r, "mean": mean, "rev": rev, "tier": r.get("tier", "exact"),
                    "n": len(effects.get(p, [])),
                    "question": qs.get(p, {}).get("question", ""),
                    "title": qs.get(p, {}).get("short") or rows[p].get("parameter") or p})

    out.sort(key=lambda r: r["rev"])
    down = [r for r in out if r["rev"] < 0]
    med = statistics.median([r["rev"] for r in out])

    if check:
        print(f"{len(out)} of {n_all} papers qualify; median revision {med:+.0f}%")
        for r in out:
            src = {"paper": "paper", "ratio": "stated ratio"}.get(
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
    revs = [r["rev"] for r in out]
    lo = min(min(revs), 0.0)
    hi = max(max(revs), 0.0)
    lo = math.floor(lo / 25.0) * 25.0
    hi = math.ceil(hi / 25.0) * 25.0
    L, RM, W = 34, 34, 760   # room for the outermost tick label
    plot = W - L - RM
    X = lambda v: L + (v - lo) / (hi - lo) * plot
    AX, R = 92, 9                       # axis y, dot radius
    H = AX + 50

    p = [f'<svg viewBox="0 0 {W} {H}" width="100%" role="img" '
         f'aria-labelledby="cf-t cf-d" class="cfig">',
         '<title id="cf-t">What correcting for bias did to each number</title>',
         f'<desc id="cf-d">One dot per meta-analysis, placed by how far its corrected or '
         f'best-practice estimate sits from the average estimate that literature reported. '
         f'{len(down)} of the {len(out)} moved toward zero and {len(out) - len(down)} away '
         f'from it; the median revision is {med:+.0f}%.</desc>']

    # lay the dots out first: the two vertical guides have to clear the tallest stack, and
    # how tall that is depends on how many papers cluster at the same revision
    placed, lanes = [], []
    for r in sorted(out, key=lambda r: r["rev"]):
        x = X(r["rev"])
        lane = 0
        while lane < len(lanes) and lanes[lane] > x - 2 * R - 1:
            lane += 1
        if lane == len(lanes):
            lanes.append(x)
        else:
            lanes[lane] = x
        placed.append((r, x, AX - R - 3 - lane * (2 * R + 3)))
    top = min(y for _, _, y in placed) - R

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
        if r["mean"] is None:
            tip = f'{r["title"]}. The paper states the revision itself: {r["rev"]:+.0f}%.'
        else:
            tip = (f'{r["title"]}. Reported estimates average {r["mean"]:.3g}; '
                   f'corrected or best practice {r["corrected"]:g}. {r["rev"]:+.0f}%.')
        if r["tier"] != "exact" and r.get("approximation"):
            tip += " " + r["approximation"]
        p.append(f'<a href="#{E(r["project"])}"><title>{E(tip)}</title>')
        p.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{R}" fill="{fill}" '
                 f'fill-opacity="{op:.2f}"/>')
        if r["tier"] != "exact":
            # a ring, not a disc: the approximate rows have to be tellable apart at a glance,
            # or the caption's count of them is the only thing standing between a reader and
            # the impression that all of these pairs are equally solid
            p.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{R * 0.42:.1f}" '
                     f'fill="var(--paper)"/>')
        p.append("</a>")

    p.append(f'<text x="{L}" y="{AX + 40}" text-anchor="start" class="cfa">'
             f'correction shrinks the effect</text>')
    p.append(f'<text x="{W - RM}" y="{AX + 40}" text-anchor="end" class="cfa">'
             f'correction enlarges it</text>')
    p.append("</svg>")
    shift = max(0.0, 26.0 - top)
    p[0] = p[0].replace(f'viewBox="0 0 {W} {H}"', f'viewBox="0 {top - 20:.0f} {W} {H - (top - 20):.0f}"')

    excl = len(spec["excluded"])
    up = [r for r in out if r["rev"] > 0]
    # the same index under a comparator the figure does NOT use, so the caption can say what
    # happens if you disagree with the one it does
    alt = []
    for r in out:
        m = (r["mean"] if r.get("mean_from") == "paper"
             else statistics.median(effects[r["project"]]))
        alt.append((abs(r["corrected"]) - abs(m)) / abs(m) * 100.0)
    alt_med = statistics.median(alt)
    n_paper = sum(1 for r in out if r.get("mean_from") == "paper")
    n_approx = sum(1 for r in out if r["tier"] != "exact")

    caption = (
        '<figcaption class="table-note"><b>What best practice did to the number.</b> '
        'One dot per meta-analysis, placed by how far the correction moved it. '
        '<b>Red</b>: the corrected or best-practice estimate is smaller <i>in absolute '
        'magnitude</i> than the average estimate the literature reported. <b>Green</b>: '
        'larger. Stronger colour, bigger move. '
        f'<b>{len(down)} of the {len(out)}</b> moved toward zero and <b>{len(up)}</b> away '
        f'from it; the median revision is <b>{med:+.0f}%</b>. '
        'The comparator is the paper&rsquo;s own uncorrected mean wherever it states one '
        f'&mdash; {n_paper} of the {len(out)} do &mdash; and otherwise the average of that '
        'literature&rsquo;s estimates in the data on this site, winsorised at 1%. Against the '
        f'<i>median</i> reported estimate instead, the median revision would be {alt_med:+.0f}%. '
        + ((f'<b>One of the {len(out)}</b> is drawn as a ring rather than a disc: its pair '
            if n_approx == 1 else
            f'<b>{n_approx} of the {len(out)}</b> are drawn as rings rather than discs: their '
            'pair ')
           + 'is approximate &mdash; the central value of a range, the horizon the paper '
             'leads with, a number from a results table where the headline is verbal, or a '
             'revision the paper states directly rather than two levels. What is approximate '
             'is written beside it in the spec, and shown when you hover the dot. '
           if n_approx else '')
        + f'<b>{len(out)} of the {n_all} papers qualify.</b> Of the other {n_all - len(out)}, '
        'about a third are methods papers with no literature of their own to correct. The rest '
        'answer in words rather than a number, or measure the corrected effect as a different '
        'quantity from the one their estimate-level data holds, or give a headline that is not '
        'a correction at all, or sit against a comparator so near zero that the ratio is noise '
        '&mdash; and a few were dropped because two defensible comparators disagreed about which '
        'way they moved. The rule takes no account of which way a paper moved, and every one of '
        f'those {n_all - len(out)} is written down with its reason, individually, in '
        '<a href="/tools/board/correction_ratios.json">correction_ratios.json</a>. '
        'Most of these papers correct with estimators that shrink toward zero, so the '
        'direction is not a discovery; the size of the move is the point. The same index, '
        'applied to 24 literatures mostly by other researchers, is in '
        '<a href="/conventional_wisdom/">Gechert et al. (2025)</a>.'
        '</figcaption>')

    os.makedirs(os.path.dirname(FRAG), exist_ok=True)
    open(FRAG, "w", encoding="utf-8", newline="\n").write(
        '<figure class="cfig-wrap">\n' + "\n".join(p) + "\n" + caption + "\n</figure>\n")
    print(f"  wrote {os.path.relpath(FRAG, BASE)}  ({len(out)} of {n_all} papers, "
          f"{len(down)} down, median {med:+.0f}%, {excl} exclusions recorded)")
    import subprocess
    subprocess.run([sys.executable, os.path.join(BASE, "tools_seo",
                                                 "publish_board_sources.py")], check=False)
    return 0


if __name__ == "__main__":
    sys.exit(build("--check" in sys.argv))
