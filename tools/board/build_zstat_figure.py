"""Draw the |t| distribution of all 48,355 pooled estimates, with the 1.96 caliper.

Static inline SVG generated at build time from the published CSV: no JavaScript, no
charting library, no external request, real text in the DOM for every number that
carries an argument. The figure and the sentence under it are produced by the same
pass, so the prose cannot drift from the picture.

Two panels, because one alone would mislead:

  left   the distribution of |t| from 0 to 6, with the three conventional critical
         values marked. It shows the shape, and it shows honestly that the mass is
         not piled at any of them.
  right  a caliper around 1.96 -- 0.05-wide bins across +-0.25 -- which is where the
         discontinuity actually lives and the only place it can be read.

The honest part is that the caption says the excess appears at 1.96 ONLY: at 1.645
and 2.576 the counts fall slightly as the threshold is crossed. A figure that marked
all three and implied a general pattern would be overclaiming, and the data is public,
so anyone can check.

    python tools_seo/build_zstat_figure.py            # writes the fragment + data csv
    python tools_seo/build_zstat_figure.py --check    # prints the numbers, writes nothing

The fragment lands in redesign/_fragments/zstat_figure.html and is inlined by
redesign/build_datasets_page.py; the numbers land in site/data/v1/t_distribution.csv
so a reader can redraw it.
"""
import bisect, csv, os, sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE = os.path.join(BASE, "site")
SRC = os.path.join(SITE, "data", "v1", "estimates_harmonised.csv")
FRAG = os.path.join(BASE, "redesign", "_fragments", "zstat_figure.html")
DATA = os.path.join(SITE, "data", "v1", "t_distribution.csv")

CRIT = [(1.645, "1.645"), (1.96, "1.96"), (2.576, "2.576")]
XMAX, BIN = 6.0, 0.1          # main panel
CAL, CBIN = 0.25, 0.05        # caliper half-width and bin


def load():
    ts = []
    with open(SRC, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            try:
                ts.append(abs(float(row["t_stat"])))
            except (TypeError, ValueError):
                pass
    return ts


def edges(lo, hi, width):
    """Bin edges rounded to a fixed number of decimals. int((t - lo) / width) is NOT
    safe here: 1.96 - 0.25 is 1.7100000000000002, and dividing through that offset
    moved 13 estimates across the 1.96 boundary, so the drawn bars and the published
    CSV disagreed with the counts quoted in the caption. Comparing against exact
    decimal edges removes the question."""
    n = int(round((hi - lo) / width))
    return [round(lo + i * width, 6) for i in range(n + 1)]


def histogram(ts, lo, hi, width):
    e = edges(lo, hi, width)
    bins = [0] * (len(e) - 1)
    for t in ts:
        if e[0] <= t < e[-1]:
            k = bisect.bisect_right(e, t) - 1
            bins[min(k, len(bins) - 1)] += 1
    return bins


def esc(s):
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def build(check=False):
    ts = load()
    total = len(ts)
    shown = sum(1 for t in ts if t < XMAX)
    main = histogram(ts, 0.0, XMAX, BIN)
    peak = max(main)

    # the caliper: equal-width bins either side of each conventional threshold
    calipers = []
    for c, label in CRIT:
        below = sum(1 for t in ts if c - CBIN <= t < c)
        above = sum(1 for t in ts if c <= t < c + CBIN)
        calipers.append((c, label, below, above, above / below if below else float("nan")))

    cal_bins = histogram(ts, 1.96 - CAL, 1.96 + CAL, CBIN)
    cal_peak = max(cal_bins)

    # the bars, the published CSV and the caption must be the same counts; assert it
    # rather than trust it, because they were computed two different ways once already
    ce = edges(1.96 - CAL, 1.96 + CAL, CBIN)
    k = ce.index(round(1.96, 6))
    if (cal_bins[k - 1], cal_bins[k]) != (calipers[1][2], calipers[1][3]):
        sys.exit(f"caliper bars {cal_bins[k-1]}/{cal_bins[k]} disagree with the counted "
                 f"{calipers[1][2]}/{calipers[1][3]} -- do not publish either")

    if check:
        print(f"{total:,} estimates, {shown:,} ({100*shown/total:.1f}%) below |t| = {XMAX:g}")
        for c, label, b, a, r in calipers:
            print(f"  {label:>5}: {b:>4} below, {a:>4} above, ratio {r:.2f}")
        return 0

    # ---- geometry ------------------------------------------------------------
    W, H = 640, 260
    L, R, T, B = 38, 8, 14, 34          # main panel margins
    GAP, CW = 26, 172                   # gap before the caliper, caliper width
    MW = W - L - R - GAP - CW           # main plotting width
    PH = H - T - B                      # plotting height
    x = lambda t: L + MW * t / XMAX
    y = lambda n: T + PH - PH * n / peak

    p = ['<svg viewBox="0 0 %d %d" width="100%%" role="img" '
         'aria-labelledby="zsig-t zsig-d" class="zfig">' % (W, H),
         '<title id="zsig-t">Distribution of absolute t-statistics across '
         f'{total:,} estimates</title>',
         '<desc id="zsig-d">Most estimates sit below the conventional thresholds. In a '
         '0.05-wide window either side of 1.96 there are %d estimates just below and %d '
         'just above. At 1.645 and 2.576 the count falls as the threshold is crossed.'
         '</desc>' % (calipers[1][2], calipers[1][3])]

    # bars
    bw = MW / len(main)
    p.append('<g fill="var(--rule)">')
    for i, n in enumerate(main):
        if not n:
            continue
        p.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f"/>'
                 % (L + i * bw, y(n), max(0.8, bw - 0.4), T + PH - y(n)))
    p.append("</g>")

    # critical values
    for c, label in CRIT:
        emph = c == 1.96
        p.append('<line x1="%.2f" y1="%d" x2="%.2f" y2="%d" stroke="%s" stroke-width="%s"%s/>'
                 % (x(c), T - 2, x(c), T + PH,
                    "var(--accent)" if emph else "var(--control)",
                    "1.5" if emph else "1",
                    "" if emph else ' stroke-dasharray="3 3"'))
        # 1.645 sits close enough to 1.96 that centred labels collide: push the two
        # dashed ones outward and leave only the emphasised label centred
        p.append('<text x="%.2f" y="%d" text-anchor="%s" class="zl%s">%s</text>'
                 % (x(c) + (0 if emph else (-3 if c < 1.96 else 3)), T - 4,
                    "middle" if emph else ("end" if c < 1.96 else "start"),
                    " zk" if emph else "", label))

    # axes
    p.append('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="var(--control)"/>'
             % (L, T + PH, L + MW, T + PH))
    for t in range(0, int(XMAX) + 1):
        p.append('<text x="%.2f" y="%d" text-anchor="middle" class="za">%d</text>'
                 % (x(t), T + PH + 14, t))
    p.append('<text x="%.2f" y="%d" text-anchor="middle" class="za">|t|</text>'
             % (L + MW / 2, T + PH + 30))
    p.append('<text x="%d" y="%d" text-anchor="end" class="za">%d</text>' % (L - 4, T + 8, peak))
    p.append('<text x="%d" y="%d" text-anchor="end" class="za">0</text>' % (L - 4, T + PH))

    # ---- caliper panel -------------------------------------------------------
    CX = L + MW + GAP
    cx = lambda t: CX + CW * (t - (1.96 - CAL)) / (2 * CAL)
    cy = lambda n: T + PH - PH * n / cal_peak
    cbw = CW / len(cal_bins)
    p.append('<g fill="var(--rule)">')
    for i, n in enumerate(cal_bins):
        left = 1.96 - CAL + i * CBIN
        p.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" fill="%s"/>'
                 % (cx(left), cy(n), cbw - 0.6, T + PH - cy(n),
                    "var(--tint)" if left < 1.96 else "var(--accent)"))
    p.append("</g>")
    p.append('<line x1="%.2f" y1="%d" x2="%.2f" y2="%d" stroke="var(--accent)" '
             'stroke-width="1.5"/>' % (cx(1.96), T - 2, cx(1.96), T + PH))
    p.append('<text x="%.2f" y="%d" text-anchor="middle" class="zl zk">1.96</text>'
             % (cx(1.96), T - 4))
    p.append('<line x1="%.2f" y1="%d" x2="%.2f" y2="%d" stroke="var(--control)"/>'
             % (CX, T + PH, CX + CW, T + PH))
    p.append('<text x="%.2f" y="%d" text-anchor="middle" class="za">1.71</text>'
             % (CX, T + PH + 14))
    p.append('<text x="%.2f" y="%d" text-anchor="middle" class="za">2.21</text>'
             % (CX + CW, T + PH + 14))
    p.append('<text x="%.2f" y="%d" text-anchor="middle" class="za">a 0.5-wide caliper, '
             'its own scale</text>' % (CX + CW / 2, T + PH + 30))
    # inside the panel, not left of it: at 390px the panel scrolls off and a label
    # placed outside it hung alone in the fade, which read as a broken chart
    p.append('<text x="%.2f" y="%d" text-anchor="end" class="za">%d</text>'
             % (CX + CW, T + 8, cal_peak))
    p.append("</svg>")

    b, a = calipers[1][2], calipers[1][3]
    lo_r, hi_r = calipers[0][4], calipers[2][4]
    caption = (
        '<p class="table-note"><b>Where the estimates fall.</b> Absolute t-statistics for all '
        f'{total:,} pooled estimates; the first panel shows the {100*shown/total:.0f}% below 6, '
        'and the second panel magnifies half a unit around 1.96 on its own vertical scale. '
        f'In equal 0.05-wide bins there are <b>{b} estimates just below 1.96 and {a} just '
        f'above</b>, {a/b:.2f} times as many. The observed step is modest, and it is specific '
        'to that one '
        f'threshold: at 1.645 the ratio is {lo_r:.2f} and at 2.576 it is {hi_r:.2f}, so the '
        'count falls rather than jumps as those are crossed. Read it as a distributional '
        'diagnostic, not as a measurement of p-hacking: selective reporting, specification '
        'search and genuinely large effects all leave marks here, and estimates are clustered '
        'within studies. The bin counts are in '
        '<a href="/data/v1/t_distribution.csv">t_distribution.csv</a>.</p>')

    os.makedirs(os.path.dirname(FRAG), exist_ok=True)
    open(FRAG, "w", encoding="utf-8", newline="\n").write(
        # only the drawing scrolls sideways: the caption carries the numbers and must not
        # be dragged off a phone screen along with the chart
        '<figure class="zfig-wrap">\n<div class="zfig-scroll">\n'
        + "\n".join(p) + "\n</div>\n" + caption + "\n</figure>\n")

    with open(DATA, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["panel", "bin_lower", "bin_upper", "count"])
        for i, n in enumerate(main):
            w.writerow(["main", round(i * BIN, 4), round((i + 1) * BIN, 4), n])
        for i, n in enumerate(cal_bins):
            lo = 1.96 - CAL + i * CBIN
            w.writerow(["caliper", round(lo, 4), round(lo + CBIN, 4), n])

    print(f"  wrote {os.path.relpath(FRAG, BASE)} and {os.path.relpath(DATA, BASE)}")
    print(f"  {total:,} estimates | 1.96 caliper {b} below / {a} above = {a/b:.2f}x")
    _publish()
    return 0


def _publish():
    """Keep site/tools/board/ -- the copy a reader can regenerate from -- identical to
    the sources that just ran. See tools_seo/publish_board_sources.py."""
    import subprocess, sys as _s, os as _o
    subprocess.run([_s.executable, _o.path.join(BASE, "tools_seo",
                                                "publish_board_sources.py")], check=False)

if __name__ == "__main__":
    sys.exit(build("--check" in sys.argv))
