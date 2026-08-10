"""Draw the research-revision figure for /conventional_wisdom/ from that paper's Tables 2 and 3.

The question the owner kept asking -- when a meta-analysis corrects for bias, how far does
the number move from what the field believed? -- cannot be answered from this site's own
data: only three of the 54 rows in estimates.csv carry both a corrected value and its
uncorrected comparator. It can be answered from a published paper of his own, which reviews
24 literatures and reports, for each, the seminal study's conventional wisdom, the simple
mean of the literature, and the bias-corrected mean.

So the figure plots the paper's numbers, not ours. Nothing is recomputed and nothing is
pooled. The build asserts the medians of all three published indices before it will write,
which is what catches a transcription slip.

It lives on the paper's own page and nowhere else. It spent one commit on /results/, under
a heading that said "Headline results from 54 papers", and that was a real error: 20 of the
24 bars are other researchers' meta-analyses, so on a page of HIS results the figure read
as a claim on all of them. Anything that moves it back belongs on this page too.

    python tools_seo/build_revision_figure.py [--check]

Writes redesign/_fragments/revision_figure.html and inlines it between the
revision-figure markers in site/conventional_wisdom/index.html.
"""
import json, os, statistics, sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(BASE, "tools_seo", "research_revision.json")
FRAG = os.path.join(BASE, "redesign", "_fragments", "revision_figure.html")

E = lambda s: (str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
               .replace('"', "&quot;"))


def build(check=False):
    d = json.load(open(SRC, encoding="utf-8"))
    rows, src = d["rows"], d["source"]

    for key, want in src["published_median"].items():
        got = statistics.median([r[key] for r in rows if r[key] is not None])
        if abs(got - want) > 1:
            sys.exit(f"{key}: median {got:g} does not match the published {want}; "
                     "the transcription is wrong, do not publish")
    if check:
        print(f"{len(rows)} literatures; medians reproduce the paper")
        return 0

    rows = sorted(rows, key=lambda r: r["r3_seminal"])
    FLOOR = -100                       # bars are capped here; past it the sign flipped

    LW, BW, RH, TOP = 340, 150, 19, 26     # label, bar area, row height, header
    H = TOP + RH * len(rows) + 40          # the last 20px carry the source credit
    W = LW + BW + 34
    zero = LW + 26                      # x of the zero line; the gap is what a
                                    # leftward (green) bar needs, or it paints
                                    # over the end of its own label
    scale = BW / 100.0                  # 100% of revision spans the bar area

    p = [f'<svg viewBox="0 0 {W} {H}" width="100%" role="img" '
         f'aria-labelledby="rv-t rv-d" class="rvfig">',
         '<title id="rv-t">Research revision across 24 economics literatures</title>',
         f'<desc id="rv-d">For each of 24 literatures reviewed by Gechert et al. (2025), the '
         f'corrected or best-practice mean compared with the conventional wisdom of a seminal '
         f'study. The '
         f'median revision is {src["published_median"]["r3_seminal"]}%. Two literatures '
         f'changed sign; one, capital-energy substitution, rose by 7%.</desc>']

    # header: the axis, marked where it matters
    p.append(f'<text x="{zero}" y="12" text-anchor="middle" class="ra">no change</text>')
    p.append(f'<text x="{zero + BW}" y="12" text-anchor="end" class="ra">'
             f'&#8722;100% or beyond</text>')
    p.append(f'<line x1="{zero}" y1="{TOP - 8}" x2="{zero}" y2="{TOP + RH*len(rows)}" '
             f'stroke="var(--control)"/>')

    for i, r in enumerate(rows):
        y = TOP + i * RH
        v = r["r3_seminal"]
        flipped = v < FLOOR
        shown = max(v, FLOOR)
        w = abs(shown) * scale
        if v < 0:
            x, fill = zero, "var(--rv-down)"
        elif v > 0:
            x, fill = zero - w, "var(--rv-up)"
        else:
            x, fill = zero, "var(--rule)"
        # Name the two numbers' owners separately. The old wording -- "Study X:
        # conventional wisdom N, corrected M" -- read as if the meta-analysts held the
        # conventional wisdom. They do not: the CW number belongs to a different,
        # earlier, seminal study, which is the paper's whole point.
        title = (f'{r["topic"]}. Meta-analysis: {r["study"]}, corrected mean '
                 f'{r["corrected"]:g}. Conventional wisdom of the seminal study named in '
                 f'the paper’s Table 2: {r["cw"]:g}. '
                 + ("The corrected estimate has the opposite sign."
                    if flipped else f'{v:+g}% revision.'))
        p.append(f'<g><title>{E(title)}</title>')
        p.append(f'<text x="{LW}" y="{y + 12}" text-anchor="end" class="rl">'
                 f'{E(r["topic"])} <tspan class="rs">{E(r["study"])}</tspan></text>')
        p.append(f'<rect x="{x:.1f}" y="{y + 3}" width="{max(w, 1.5):.1f}" height="12" '
                 f'rx="1.5" fill="{fill}"/>')
        if flipped:
            # inside the bar, not past its end: at 390px the figure scrolls and a label
            # placed to the right of the plot was never seen
            p.append(f'<text x="{zero + BW - 5}" y="{y + 13}" text-anchor="end" '
                     f'class="ra rv-flip">sign flip</text>')
        p.append("</g>")
    # A credit inside the frame, not only in the caption: the image gets screenshotted and
    # reposted, and 20 of these 24 meta-analyses are other researchers' work.
    p.append(f'<text x="{LW}" y="{TOP + RH*len(rows) + 22}" text-anchor="end" class="ra">'
             f'24 meta-analyses reviewed in Gechert et al. (2025), J Econ Surveys'
             f'</text>')
    p.append(f'<text x="{zero + BW}" y="{TOP + RH*len(rows) + 22}" text-anchor="end" '
             f'class="ra">meta-analysis.cz</text>')
    p.append("</svg>")

    med = src["published_median"]
    # Derived, never typed: an earlier build said "three of the 24 are his" and was wrong
    # by one, because the count lived in the caption string instead of in the data.
    mine = sum(1 for r in rows if r["havranek"])
    NUM = {3: "Three", 4: "Four", 5: "Five", 6: "Six"}
    caption = (
        '<figcaption class="table-note"><b>What correcting for bias does to a number.</b> '
        'Each bar is one of the 24 meta-analyses reviewed in this paper, <b>almost all of '
        f'them by other researchers</b> &mdash; {NUM[mine].lower()} of the 24 are '
        'Havránek&rsquo;s own. Each '
        'compares that meta-analysis&rsquo;s corrected or best-practice mean with the conventional '
        'wisdom of the seminal study named in the paper&rsquo;s Table 2. '
        '<b>Red</b>: the corrected effect is smaller <i>in absolute magnitude</i> than the '
        'field believed. <b>Green</b>: larger. Two of them &mdash; the minimum wage and '
        'gender differences in response to performance pay &mdash; came out with the '
        'opposite sign, and revised by more than 100%, so their bars are capped at the end '
        'of the scale and marked <i>sign flip</i>. The median revision is '
        f'<b>{med["r3_seminal"]}%</b> against the seminal '
        f'study, {med["r3_ai"]}% against an AI\'s summary of the prior literature, and '
        f'{med["r3_meta"]}% against the literature\'s own simple mean. '
        f'Numbers from its Tables 2 and 3; <a href="{src["doi"]}">10.1111/joes.12630</a>.'
        '</figcaption>')

    os.makedirs(os.path.dirname(FRAG), exist_ok=True)
    open(FRAG, "w", encoding="utf-8", newline="\n").write(
        '<figure class="rvfig-wrap">\n<div class="rvfig-scroll">\n'
        + "\n".join(p) + "\n</div>\n" + caption + "\n</figure>\n")
    # inline it on the paper's own page, which is where it belongs: 21 of these 24
    # meta-analyses are other researchers' work, so on a page of HIS results it read as
    # a claim on all of them
    page = os.path.join(BASE, "site", "conventional_wisdom", "index.html")
    import re as _re
    html_ = open(page, encoding="utf-8").read()
    frag = open(FRAG, encoding="utf-8").read().strip()
    if "<!-- revision-figure:start -->" not in html_:
        sys.exit("conventional_wisdom/index.html has no revision-figure markers")
    open(page, "w", encoding="utf-8", newline="").write(
        _re.sub(r"<!-- revision-figure:start -->.*?<!-- revision-figure:end -->",
                lambda _m: ("<!-- revision-figure:start -->\n" + frag
                            + "\n<!-- revision-figure:end -->"), html_, flags=_re.S))
    print("  inlined on /conventional_wisdom/")
    print(f"  wrote {os.path.relpath(FRAG, BASE)}  ({len(rows)} literatures, "
          f"median {med['r3_seminal']}%)")
    import subprocess
    subprocess.run([sys.executable, os.path.join(BASE, "tools_seo",
                                                 "publish_board_sources.py")], check=False)
    return 0


if __name__ == "__main__":
    sys.exit(build("--check" in sys.argv))
