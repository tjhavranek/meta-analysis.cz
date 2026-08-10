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

TIER_ORDER = ["range", "horizon", "table", "subsample", "ratio"]
TIER_WORDS = {
    "range": "the central value of a range, or an upper bound",
    "horizon": "the horizon the paper leads with",
    "table": "a number read from a results table where the headline is verbal",
    "subsample": "the subsample the paper leads with",
    "ratio": "a revision the paper states directly rather than as two levels",
}

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
         '<title id="cf-t">What correction and best practice did to each number</title>',
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
        # an invisible target twice the dot: 18 user-units is a small thing to hit with a thumb
        p.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{R * 2}" fill="transparent"/>')
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
    n_approx = sum(1 for r in out if r["tier"] != "exact")
    n_up = len(out) - len(down)
    tier_counts = {}
    for r in out:
        if r["tier"] != "exact":
            tier_counts[r["tier"]] = tier_counts.get(r["tier"], 0) + 1
    NOLIT = {"correlations", "guidelines", "maive", "outliers", "pcc", "pcc_survey",
             "conventional_wisdom", "debate"}
    n_nolit = len([e for e in spec["excluded"] if e["project"] in NOLIT])

    # The caption had grown to hold the comparator rule, the sensitivity check, the ring
    # taxonomy, the exclusion taxonomy and a defence of the selection rule. All of it is worth
    # keeping and none of it is what a reader wants first. The finding stays visible; the
    # method goes in a <details>, whose content is ordinary DOM text and so still reaches
    # every crawler and every text corpus -- unlike a <script>, which they discard.
    caption = (
        '<figcaption class="table-note">'
        '<b>What correction and best practice did to the number.</b> '
        'One dot per meta-analysis, placed by how far its corrected or best-practice estimate '
        'sits from the mean the literature reported. <b>Red</b>: smaller <i>in absolute '
        'magnitude</i>. <b>Green</b>: larger. '
        + (f'<b>All {len(out)} moved toward zero</b>; ' if len(down) == len(out) else
           f'<b>{len(down)} of the {len(out)}</b> moved toward zero and <b>{n_up}</b> away from '
           'it. ')
        + f'The median revision is <b>{med:+.0f}%</b>. '
        + (f'The {n_approx} drawn as rings are approximate pairs. ' if n_approx else '')
        + 'Vertical position carries no meaning. The dots are stacked only to keep them apart.'
        '<details class="figmethod"><summary>How this figure is built, and which papers it '
        'leaves out</summary>'
        '<p>The index is <i>(|corrected| &minus; |mean|) / |mean|</i>, the same relative revision '
        'as Table 3 of <a href="/conventional_wisdom/">Gechert et al. (2025)</a>, which applies '
        'it to 24 literatures mostly by other researchers.</p>'
        f'<p>The comparator is the paper&rsquo;s own uncorrected mean wherever it states '
        f'one, which {n_paper} of the {len(out)} do. Otherwise it is the average of that '
        'literature&rsquo;s estimates in the data on this site, winsorised at 1%. The '
        'paper&rsquo;s own number is preferred because the harmonised table keeps only '
        'estimates that '
        'report a usable standard error, so a mean computed from it can rest on a subset of what '
        'the paper analysed.</p>'
        f'<p>If you distrust means, there is a second reading. {n_alt} of the {len(out)} '
        f'comparators are computed here instead of quoted from a paper, and those are '
        f'winsorised means. Use the median '
        f'of those literatures&rsquo; estimates instead and the overall median revision becomes '
        f'{alt_med:+.0f}%'
        + (f', with the number moving upward unchanged at {n_up}. ' if alt_up == n_up else
           f', and {alt_up} of the {len(out)} move upward rather than {n_up}. ')
        + 'The swap is confined to those rows on purpose: where a paper states its own mean, its '
        'corrected value need not be in the same units as the estimate column at all, so a '
        'median taken from that column would not be a comparator. The check covers only the '
        'estimates this site holds, under the same standard-error selection.</p>'
        + (f'<p><b>The {n_approx} rings</b> are pairs that are approximate in a stated way: '
           + ", ".join(TIER_WORDS[t] + f" ({tier_counts[t]})" for t in TIER_ORDER
                       if tier_counts.get(t))
           + '. Hover a ring and it says which.</p>' if n_approx else '')
        + f'<p><b>{len(out)} of the {n_all} papers qualify.</b> Of the other {n_all - len(out)}, '
        f'{n_nolit} have no single literature effect to correct: methods papers, an '
        'experiment, and the review that supplies the companion figure. The rest answer in words '
        'rather than a number, or measure the corrected effect as a different quantity from the '
        'one their estimate-level data holds, or give a headline that is not a correction at '
        'all, or sit against a comparator so near zero that the ratio is noise; one was '
        'dropped because two defensible comparators disagreed about which way it moved. '
        'The rule takes no account of which way a paper moved, and every one of those '
        f'{n_all - len(out)} is written down with its reason, individually, in '
        '<a href="/tools/board/correction_ratios.json">correction_ratios.json</a>.</p>'
        '<p>Most of these papers correct with estimators that shrink toward zero. What the figure '
        'adds is the size of each move.</p>'
        '</details></figcaption>')

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
