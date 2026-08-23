"""Build /maive/how-to/ -- how to run MAIVE on your own data, with a worked example.

MAIVE corrects a meta-analysis for publication bias and for p-hacking that runs through the
reported standard error. It is published, it has a free web app and a free API, and until now
this site had no page that showed a reader how to actually run it. The paper explains the
estimator; this shows the four columns it needs and the three numbers to read off the result.

Every number on the page comes from a real run against EasyMeta's API, recorded verbatim in
api/v1/maive-howto.json -- the request bodies included -- so the page, the gate and any bot
read one file. Nothing here is typed by hand.

    python tools/build_maive_howto.py --refresh   # call the API, rewrite the sidecar + funnel
    python tools/build_maive_howto.py             # rebuild the page from the sidecar

TWO THINGS THE API DOES THAT WILL BITE ANYONE WHO COPIES ITS OWN DOCS:

1. Model parameters must be NESTED under "parameters". Sent at the top level they are
   silently ignored -- HTTP 200, default settings, no warning. easymeta.org/api-docs shows an
   async example that does exactly this. A dropped useLogFirstStage moves the first-stage F
   on one of this site's datasets from 148.6 to 1.04, which is the difference between "strong
   instrument" and "MAIVE is unstable here". That is why the page prints the wrapper and why
   the gate asserts firstStage.mode.

2. The async endpoint (/v1/runs) ignores modelType and returns MAIVE whatever you ask for,
   while the sync endpoint honours it. Verified reproducibly: WAIVE on the same body returns
   0.1427 sync and 0.1854 async, and 0.1854 is MAIVE's answer. The funnel plot is ONLY
   available on async. So every NUMBER here comes from sync, the funnel comes from an async
   MAIVE run (where the bug cannot bite), and the gate cross-checks the two agree on F.
"""
import base64
import datetime
import json
import os
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_paper_page import ROOT  # noqa: E402
from build_search_page import homepage_footer  # noqa: E402

API = "https://api.maive.eu"
UA = "meta-analysis-cz-howto/1.0 (mailto:t.havranek@gmail.com)"
OUT_DIR = os.path.join(ROOT, "maive", "how-to")
SIDECAR = os.path.join(ROOT, "api", "v1", "maive-howto.json")
FUNNEL = os.path.join(OUT_DIR, "funnel.png")
TABLE = os.path.join(ROOT, "data", "v1", "estimates_harmonised.csv")

DATASET = "excess_sensitivity"

# The settings the page teaches. clustered_cr2 and PET-PEESE are already the API's defaults;
# useLogFirstStage is not, and should be: MAIVE's first stage regresses the squared standard
# error on the inverse sample size, and in levels that regression is dominated by a handful of
# imprecise estimates. In logs it is a proportional relationship, which is what the theory
# says it is. The authors' own advice is to use logs.
SETTINGS = {"modelType": "MAIVE", "useLogFirstStage": True,
            "standardErrorTreatment": "clustered_cr2", "winsorize": 0}


def circularity_r2(d):
    """R-squared of log(SE^2) on log(N) -- how much of the standard error is just arithmetic.

    MAIVE instruments the standard error with the sample size because the standard error can
    be manipulated and the sample size cannot. When SE is a formula in N -- as it is for a
    partial correlation, SE = sqrt((1-r^2)/(n-2)) -- that regression is an identity, the
    first-stage F is a tautology, and the instrument purges nothing. The page tells the reader
    to run this on their own data before calling anything, so it had better be computed here
    rather than asserted."""
    import numpy as np
    x = np.log(d.n_obs.values.astype(float))
    y = np.log(d.se.values.astype(float) ** 2)
    X = np.column_stack([np.ones(len(d)), x])
    beta, *_ = np.linalg.lstsq(X, y, rcond=None)
    resid = y - X @ beta
    return float(1 - (resid @ resid) / ((y - y.mean()) @ (y - y.mean())))


def rows_for(subset):
    import pandas as pd
    d = pd.read_csv(TABLE, low_memory=False)
    d = d[d.dataset == DATASET]
    if subset == "iv_panel":
        d = d[(d.method_iv == 1) & (d.is_panel == 1)]
    d = d.dropna(subset=["effect", "se", "n_obs"])
    d = d[(d.se > 0) & (d.n_obs > 0)]
    return [{"effect": float(r.effect), "se": float(r.se),
             "n_obs": int(r.n_obs), "study_id": str(r.study_id)} for r in d.itertuples()], d


def post(path, body, query=""):
    url = "%s%s%s" % (API, path, query)
    r = subprocess.run(["curl", "-sS", "--max-time", "170", "-A", UA, url,
                        "-H", "Content-Type: application/json", "--data-binary", "@-"],
                       input=json.dumps(body), capture_output=True, text=True)
    if r.returncode or not r.stdout.strip().startswith("{"):
        raise SystemExit("API call failed: %s%s" % (r.stderr[:300], r.stdout[:300]))
    return json.loads(r.stdout)


def get(path, query=""):
    r = subprocess.run(["curl", "-sS", "--max-time", "60", "-A", UA, "%s%s%s" % (API, path, query)],
                       capture_output=True, text=True)
    return json.loads(r.stdout) if r.stdout.strip().startswith("{") else {}


def async_funnel(rows):
    """The funnel, from an async MAIVE run -- the only path that returns a plot."""
    job = post("/v1/runs", {"data": rows, "parameters": dict(SETTINGS)}).get("jobId")
    for _ in range(40):
        out = get("/v1/runs/%s" % job, "?include=plot")
        if out.get("status") in ("succeeded", "failed", "timedout"):
            return out.get("result") or {}
        time.sleep(5)
    raise SystemExit("async run did not finish")


def refresh():
    full, dfull = rows_for("all")
    sub, dsub = rows_for("iv_panel")
    runs = {}

    def run(key, rows, params, path="/v1/run-model"):
        body = {"data": rows, "parameters": params}
        resp = post(path, body)
        if "error" in resp:
            raise SystemExit("%s: %s" % (key, resp["error"]))
        runs[key] = {"request_parameters": params, "n_rows": len(rows), "response": resp}
        print("  %-12s %s" % (key, {k: resp.get(k) for k in
                                    ("effectEstimate", "standardError", "firstStageFStatistic")}))
        time.sleep(2)

    print("calling the API (sync, so modelType is honoured):")
    run("maive", full, dict(SETTINGS))
    run("waive", full, dict(SETTINGS, modelType="WAIVE"))
    run("weak_maive", sub, dict(SETTINGS, computeAndersonRubin=True))
    run("weak_rtma", sub, {"favorPositive": True, "alphaSelect": 0.05,
                           "ciLevel": 0.95, "seed": 2025}, "/v1/run-rtma")

    print("fetching the funnel (async MAIVE -- the only path that returns one):")
    plot = async_funnel(full)
    os.makedirs(OUT_DIR, exist_ok=True)
    img = plot.get("funnelPlot") or ""
    open(FUNNEL, "wb").write(base64.b64decode(img.split(",")[-1]))
    print("  funnel.png %d bytes, async F %s vs sync F %s"
          % (os.path.getsize(FUNNEL), plot.get("firstStageFStatistic"),
             runs["maive"]["response"].get("firstStageFStatistic")))

    doc = {
        "what": "Every number on https://meta-analysis.cz/maive/how-to/, with the request "
                "that produced it.",
        "how": "tools/build_maive_howto.py --refresh. Numbers come from the SYNCHRONOUS "
               "endpoint: the async endpoint ignores modelType and returns MAIVE whatever is "
               "asked for. Parameters must be nested under 'parameters' or they are silently "
               "ignored.",
        "api": API,
        "retrieved": datetime.date.today().isoformat(),
        "dataset": {
            "project": DATASET,
            "title": "Excess sensitivity of consumption to anticipated income",
            "source": "https://meta-analysis.cz/excess_sensitivity/",
            "full_text": "https://meta-analysis.cz/excess_sensitivity/paper/",
            "estimates": len(full), "studies": int(dfull.study_id.nunique()),
            "simple_mean": round(float(dfull.effect.mean()), 4),
            "circularity_r2": round(circularity_r2(dfull), 3),
            "subset": {"filter": "method_iv == 1 and is_panel == 1",
                       "estimates": len(sub), "studies": int(dsub.study_id.nunique()),
                       "simple_mean": round(float(dsub.effect.mean()), 4)},
        },
        "settings": SETTINGS,
        "runs": runs,
        "funnel": {"file": "/maive/how-to/funnel.png",
                   "from": "async MAIVE run; the sync endpoint returns no plot",
                   "async_first_stage_f": plot.get("firstStageFStatistic")},
    }
    os.makedirs(os.path.dirname(SIDECAR), exist_ok=True)
    json.dump(doc, open(SIDECAR, "w", encoding="utf-8"), indent=1, ensure_ascii=False,
              sort_keys=True)
    print("wrote %s" % SIDECAR)
    return doc


PAGE = """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" \
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>How to run MAIVE</title>
<meta name="description" content="MAIVE corrects a meta-analysis for publication bias and \
for p-hacking that runs through the reported standard error. It needs three columns you \
already have and one you may not: the sample size. A worked example on real data, with the \
request that produced every number." />
<link rel="canonical" href="https://meta-analysis.cz/maive/how-to/" />
<link href="/style.css" rel="stylesheet" type="text/css" />
<link href="/paper.css" rel="stylesheet" type="text/css" />
<script type="application/ld+json">%(jsonld)s</script>
</head>
<body>
<div id="wrapper">
<div id="logo">
\t<a class="masthead-home" href="/">meta-analysis.cz</a>
\t<p class="site-name"><a href="/maive/how-to/">How to run MAIVE</a></p>
\t<h2> <span class="mk">&raquo;</span>&nbsp;&nbsp;&nbsp; three columns and one call</h2>
</div>
<div id="header">
\t<div id="menu">
\t\t<ul>
\t\t\t<li class="current_page_item"><a href="/maive/how-to/">How to</a></li>
\t\t\t<li><a href="/maive/">MAIVE</a></li>
\t\t\t<li><a href="/maive/paper/">The paper</a></li>
\t\t\t<li><a href="https://www.easymeta.org/">EasyMeta</a></li>
\t\t\t<li><a href="/">All meta-analyses</a></li>
\t\t</ul>
\t</div>
</div>
<div id="page" class="single">
\t<div id="content">
\t\t<div class="post">
\t\t\t<div class="entry">

<p class="lede"><b>MAIVE corrects a meta-analysis for publication bias and for the p-hacking
that runs through reported standard errors &#8212; estimates made to look more precise than
their samples can support.</b> It needs one column ordinary meta-analysis does not: the
sample size behind each estimate.</p>

<h2 id="what-you-need">What you need</h2>

<table class="cols">
<caption>One row per estimate.</caption>
<tbody>
<tr><th><code>effect</code></th><td>the reported estimate</td></tr>
<tr><th><code>se</code></th><td>its standard error</td></tr>
<tr><th><code>n_obs</code></th><td>the sample size behind it</td></tr>
<tr><th><code>study_id</code></th><td>optional; add it when a study reports more than one
estimate and MAIVE will cluster on it</td></tr>
</tbody>
</table>

<p>Ordinary meta-analysis needs the first two. MAIVE needs the third. That is the whole
extra ask, and it is why <a href="/datasets/">every dataset here</a> ships those column
names.</p>

<h2 id="run-it">Run it</h2>

<p>The web app at <a href="https://www.easymeta.org/">easymeta.org</a> takes a spreadsheet
and needs no code. To call it directly, POST to the free API &#8212; no key, no sign-up:</p>

<pre class="code"><code>curl -s https://api.maive.eu/v1/run-model \\
  -H 'Content-Type: application/json' -d '%(request)s'</code></pre>

<p class="warn"><b>The parameters must be nested under <code>parameters</code>.</b> Sent at
the top level they are silently ignored: you get HTTP 200, default settings, and no warning.
Use the synchronous endpoint above &#8212; the asynchronous one ignores
<code>modelType</code> and runs MAIVE whatever you ask for.</p>

<h2 id="ask-an-ai">Ask an AI to run it</h2>

<p>Give an assistant your data and this, and check what it reports against the three numbers
below.</p>

<pre class="code prompt"><code>%(ai)s</code></pre>

<h2 id="example">A worked example</h2>

<p>The <a href="/excess_sensitivity/">excess sensitivity of consumption</a> to anticipated
income: %(k)s estimates from %(studies)s studies, the whole dataset, unmodified.</p>

<table class="ladder">
<tbody>
<tr><th>Simple mean of the literature</th><td>%(mean)s</td></tr>
<tr><th>MAIVE</th><td><b>%(maive)s</b> <span class="se">(%(maive_se)s)</span></td></tr>
<tr><th>WAIVE</th><td>%(waive)s <span class="se">(%(waive_se)s)</span></td></tr>
</tbody>
</table>

<div class="funnel">%(funnel_svg)s</div>

<p class="figcap">Hollow points are the standard errors the studies reported; filled points
are what MAIVE instruments them to. The axis stops at the 95th percentile of reported
standard errors (%(se_cap)s) so the cloud is visible; estimation uses every one of the
%(k)s estimates. Publication bias costs roughly half the effect &#8212; the paper's own
correction, which also removes aggregation bias, lands at 0.11. The API's own plot is in
<a href="/maive/how-to/funnel.png">funnel.png</a>.</p>

<h2 id="read-three-numbers">Read three numbers before the estimate</h2>

<table class="cols">
<tbody>
<tr><th><code>firstStage.mode</code></th><td><b>%(mode)s</b> &#8212; if this says
<code>levels</code>, your parameters never took effect</td></tr>
<tr><th><code>firstStageFStatistic</code></th><td><b>%(F)s</b> &#8212; below 10 the
instrument is weak and the point estimate should not be quoted</td></tr>
<tr><th><code>publicationBias.pValue</code></th><td><b>%(bias_p)s</b> &#8212; whether there
was bias to correct at all</td></tr>
</tbody>
</table>

<h2 id="weak-first-stage">If the first stage is weak</h2>

<p>Restrict the same literature to instrumental-variable estimates on panel data
&#8212; %(sub_k)s estimates from %(sub_studies)s studies, one of the dataset's own coding
dimensions &#8212; and the first stage collapses to <b>F = %(sub_F)s</b>.</p>

<p>MAIVE still returns a number, %(sub_maive)s (%(sub_se)s). Do not quote it. Re-run with
<code>"computeAndersonRubin": true</code> and report the interval instead:
<b>[%(ar_lo)s, %(ar_hi)s]</b>, which is wide and contains zero.</p>

<p>Then run <a href="https://www.easymeta.org/">RTMA</a> at
<code>/v1/run-rtma</code>, which does not depend on the instrument. It must be told which
sign the literature selects for: <code>"favorPositive": true</code> where the literature
hunts positive estimates, as here, <code>false</code> where it hunts negative ones. The
default is <code>true</code>, so on a literature of negative effects the default quietly
returns an uncorrected mean with a deceptively tight interval. The tell is a warning,
<code>"Favored direction is opposite of the pooled estimate."</code> &#8212; if you see it,
flip the setting and run again.</p>

<p><b>&#956; = %(mu)s</b>, 95%% CI [%(mu_lo)s, %(mu_hi)s], with %(affirm)s of the
%(sub_k)s estimates affirmative and no warnings. Check the diagnostics before quoting any of
it: R-hat at or below 1.01, effective sample size above 400, no divergent transitions
&#8212; here %(rhat)s, %(neff)s and %(divergences)s.</p>

<h2 id="p-hacking">If you suspect p-hacking</h2>

<p>Send <code>"modelType": "WAIVE"</code>, which downweights estimates whose precision the
sample size does not support: <b>%(waive)s</b> (%(waive_se)s) against MAIVE's %(maive)s.</p>

<p>Suspect, not demonstrated: this literature shows no significant bunching of
<i>t</i>-statistics just above 1.96 (350 against 321, p = 0.28). WAIVE is the estimator to
reach for when you have reason to think reported precision is manufactured, not a verdict
that it was.</p>

<h2 id="limits">What this does not fix</h2>

<p>MAIVE removes bias that runs through the standard error. It does not repair an estimate
whose standard error is honest but whose specification was hacked &#8212; dropped controls,
sample cuts, outcome switching. No method that reads only effect, standard error and sample
size can.</p>

<p>It also needs standard errors that are not pure arithmetic in the sample size. Before
you call the API, run one line on your own data:</p>

<pre class="code"><code>summary(lm(log(se^2) ~ log(n_obs)))$r.squared</code></pre>

<p>Above about 0.8, the first-stage F is measuring your metric's algebra rather than the
strength of the instrument. Partial correlation coefficients, where
SE = &#8730;((1&#8722;r&#178;)/(n&#8722;2)) by construction, sit at R&#178; near 1 and can
print an F in the millions. For the literature on this page it is %(r2)s.</p>

<h2 id="newer-than-the-paper">This is newer than the paper</h2>

<p>The <a href="/maive/paper/">Nature Communications paper</a> runs the first stage in
levels. The app and the API are newer, and we recommend the log first stage used
throughout this page &#8212; <code>"useLogFirstStage": true</code>. Where this page
and the paper disagree, the page is the more current advice.</p>

<p class="provenance">Every number here came from the API on %(retrieved)s. The requests
that produced them, and the full responses, are in
<a href="/api/v1/maive-howto.json">maive-howto.json</a>.</p>

\t\t\t</div>
\t\t</div>
\t</div>
</div>
</div>
%(footer)s
</body>
</html>
"""


def funnel_svg(doc):
    """The funnel, drawn here from the sidecar rather than taken from the API.

    The API's own plot is honest but sized for its app: on 3,127 estimates whose standard
    errors span three orders of magnitude, the outliers own the axis and the cloud where the
    evidence lives is a smudge along the top. The site's own convention (the correction figure
    on /results/) is a hand-built SVG, so this is one too: reported SE against effect, hollow;
    instrumented SE, filled; the axis capped at the 95th percentile of the reported SEs with
    the cap stated in the caption. Estimation uses every row; only the picture is cropped."""
    rows = doc["_rows"]
    si = doc["runs"]["maive"]["response"]["seInstrumented"]
    mean = doc["dataset"]["simple_mean"]
    maive = doc["runs"]["maive"]["response"]["effectEstimate"]
    ses = sorted(r["se"] for r in rows)
    se_cap = ses[int(0.95 * len(ses))]
    effs = sorted(r["effect"] for r in rows)
    x_lo, x_hi = effs[int(0.005 * len(effs))], effs[int(0.995 * len(effs))]
    x_lo, x_hi = min(x_lo, -0.05), max(x_hi, 0.05)

    W, H, L, T, R, B = 720, 520, 64, 18, 16, 58
    def X(v): return L + (v - x_lo) / (x_hi - x_lo) * (W - L - R)
    def Y(se): return T + se / se_cap * (H - T - B)

    shown = dropped = 0
    hollow, filled = [], []
    for r, s_i in zip(rows, si):
        if r["se"] > se_cap and s_i > se_cap:
            dropped += 1
            continue
        shown += 1
        if x_lo <= r["effect"] <= x_hi:
            if r["se"] <= se_cap:
                hollow.append('<circle cx="%.1f" cy="%.1f" r="2.2"/>' % (X(r["effect"]), Y(r["se"])))
            if s_i <= se_cap:
                filled.append('<circle cx="%.1f" cy="%.1f" r="2.2"/>' % (X(r["effect"]), Y(s_i)))

    xt = []
    import math
    step = round((x_hi - x_lo) / 4, 1) or 0.1
    v = math.ceil(x_lo / step) * step
    while v <= x_hi + 1e-9:
        xt.append('<line x1="%.1f" y1="%d" x2="%.1f" y2="%d"/>' % (X(v), H - B, X(v), H - B + 5)
                  + '<text x="%.1f" y="%d">%.1f</text>' % (X(v), H - B + 20, v))
        v += step
    yt = []
    for frac in (0, 0.25, 0.5, 0.75, 1.0):
        se = frac * se_cap
        yt.append('<line x1="%d" y1="%.1f" x2="%d" y2="%.1f"/>' % (L - 5, Y(se), L, Y(se))
                  + '<text x="%d" y="%.1f">%.2f</text>' % (L - 9, Y(se) + 4, se))

    return (
        '<svg viewBox="0 0 %(W)d %(H)d" width="100%%" role="img" aria-label="Funnel plot: '
        'reported standard errors (hollow) and MAIVE-instrumented standard errors (filled) '
        'against effect size. The instrumented points sit higher, and the mass of the '
        'literature leans right of the corrected estimate.">'
        '<style>.h circle{fill:none;stroke:#5a6672;stroke-width:.8}'
        '.f circle{fill:#1d252c;opacity:.28}'
        '.ax line{stroke:#848e99;stroke-width:1}'
        '.ax text{font:11px ui-sans-serif,system-ui,sans-serif;fill:#5a6672;text-anchor:middle}'
        '.ay text{text-anchor:end}'
        '.ref{stroke-width:1.4;fill:none}'
        '.lab{font:12px ui-sans-serif,system-ui,sans-serif;fill:#1d252c}</style>'
        '<line class="ref" x1="%(xm).1f" y1="%(T)d" x2="%(xm).1f" y2="%(yb)d" '
        'stroke="#848e99" stroke-dasharray="5 4"/>'
        '<line class="ref" x1="%(xv).1f" y1="%(T)d" x2="%(xv).1f" y2="%(yb)d" stroke="#0b4a6e"/>'
        '<g class="h">%(hollow)s</g><g class="f">%(filled)s</g>'
        '<g class="ax">%(xt)s<g class="ay">%(yt)s</g>'
        '<line x1="%(L)d" y1="%(yb)d" x2="%(xr)d" y2="%(yb)d"/>'
        '<line x1="%(L)d" y1="%(T)d" x2="%(L)d" y2="%(yb)d"/></g>'
        '<text class="lab" x="%(xm).1f" y="%(H)d" text-anchor="middle">Effect size</text>'
        '<text class="lab" transform="rotate(-90)" x="%(ymid)d" y="14" '
        'text-anchor="middle">Standard error</text>'
        '<text class="lab" x="%(xv).1f" y="%(T2)d" fill="#0b4a6e" '
        'text-anchor="%(anch)s">&#160;MAIVE %(mv).3f</text>'
        '<text class="lab" x="%(xm2).1f" y="%(T2)d" fill="#5a6672" '
        'text-anchor="%(anch2)s">mean %(mn).3f&#160;</text>'
        % dict(W=W, H=H, T=T, L=L, yb=H - B, xr=W - R, T2=T + 12,
               xm=X(mean), xv=X(maive), xm2=X(mean), ymid=-(H - B + T) // 2,
               hollow="".join(hollow), filled="".join(filled),
               xt="".join(xt), yt="".join(yt), mv=maive, mn=mean,
               anch="end" if X(maive) < X(mean) else "start",
               anch2="start" if X(maive) < X(mean) else "end")
    ), se_cap, dropped


def n(x, d=3):
    return "&#8212;" if x is None or x == "NA" else ("%.*f" % (d, float(x)))


def render(doc):
    if "_rows" not in doc:
        doc["_rows"], _ = rows_for("all")
    ds, runs, S = doc["dataset"], doc["runs"], doc["settings"]
    mv, wv = runs["maive"]["response"], runs["waive"]["response"]
    wk, rt = runs["weak_maive"]["response"], runs["weak_rtma"]["response"]
    sub = ds["subset"]
    ar = wk.get("andersonRubinCI") or []
    mu_ci = rt.get("muCI") or []
    dg = rt.get("diagnostics") or {}

    # Hand-formatted, not json.dumps: pretty-printed this is 35 lines and swamps a page whose
    # whole point is that the method is small. Only the parameters that are not already the
    # API's defaults are shown.
    request = """{
  "data": [
    {"effect": 0.42, "se": 0.11, "n_obs": 120, "study_id": "Smith2020"},
    {"effect": 0.31, "se": 0.06, "n_obs":  90, "study_id": "Smith2020"},
    {"effect": 0.55, "se": 0.20, "n_obs":  45, "study_id": "Jones2019"}
  ],
  "parameters": {"modelType": "MAIVE", "useLogFirstStage": true,
                 "standardErrorTreatment": "clustered_cr2"}
}"""

    ai_prompt = (
        "Run MAIVE on my data with the free EasyMeta API and report the result.\n\n"
        "POST https://api.maive.eu/v1/run-model  (no API key needed)\n"
        "  {\"data\": [{\"effect\": .., \"se\": .., \"n_obs\": .., \"study_id\": \"..\"}, ...],\n"
        "   \"parameters\": {\"modelType\": \"MAIVE\", \"useLogFirstStage\": true,\n"
        "                  \"standardErrorTreatment\": \"clustered_cr2\"}}\n\n"
        "study_id is optional; include it if a study reports several estimates.\n\n"
        "Three things that will silently give you the wrong answer:\n"
        "- Parameters MUST be nested under \"parameters\". At the top level they are ignored\n"
        "  and you get defaults, with HTTP 200 and no warning.\n"
        "- Use this synchronous endpoint. The async one (/v1/runs) ignores modelType.\n"
        "- Check firstStage.mode is \"log\" in the response. If it says \"levels\", the\n"
        "  parameters did not take effect, so fix the nesting and run again.\n\n"
        "- Before running, compute the R-squared of log(se^2) on log(n_obs). Above 0.8 the\n"
        "  standard error is arithmetic in the sample size, MAIVE cannot help, and you should\n"
        "  say so and stop.\n\n"
        "Then: if firstStageFStatistic is below 10 the instrument is weak, so do not quote\n"
        "effectEstimate. Re-run with \"computeAndersonRubin\": true and report andersonRubinCI,\n"
        "and also run RTMA at /v1/run-rtma. When you run RTMA set \"favorPositive\": true if most\n"
        "of the statistically significant estimates are positive, false if most are negative;\n"
        "if the response warns about the favored direction, flip it and run again.\n\n"
        "Otherwise report effectEstimate, standardError, the first-stage F, and\n"
        "publicationBias.pValue. Report any warnings verbatim beside the numbers. Do not invent\n"
        "numbers.")

    # A HowTo, and nothing more. Not a ScholarlyArticle -- it is not a paper. Not a Dataset --
    # the page is not the data. And no WebAPI node for api.maive.eu: this site does not run
    # that service, and declaring somebody else's API here would be a claim of ownership.
    svg, se_cap, _dropped = funnel_svg(doc)

    ld = {
        "@context": "https://schema.org",
        "@type": "HowTo",
        "@id": "https://meta-analysis.cz/maive/how-to/#howto",
        "name": "How to run MAIVE",
        "description": "Correct a meta-analysis for publication bias and for p-hacking that "
                       "runs through the reported standard error, using three columns of data "
                       "and one API call.",
        "inLanguage": "en",
        "license": "https://creativecommons.org/licenses/by/4.0/",
        "isBasedOn": "https://meta-analysis.cz/maive/#paper",
        "about": {"@id": "https://meta-analysis.cz/maive/#paper"},
        "tool": {"@type": "SoftwareApplication", "name": "EasyMeta",
                 "url": "https://www.easymeta.org/"},
        "step": [
            {"@type": "HowToStep", "name": "Assemble the data",
             "url": "https://meta-analysis.cz/maive/how-to/#what-you-need",
             "text": "One row per estimate with effect, se and n_obs, plus study_id when a "
                     "study reports more than one estimate."},
            {"@type": "HowToStep", "name": "Run it",
             "url": "https://meta-analysis.cz/maive/how-to/#run-it",
             "text": "POST the rows to https://api.maive.eu/v1/run-model with the parameters "
                     "nested under \"parameters\": modelType MAIVE, useLogFirstStage true, "
                     "standardErrorTreatment clustered_cr2."},
            {"@type": "HowToStep", "name": "Read three numbers before the estimate",
             "url": "https://meta-analysis.cz/maive/how-to/#read-three-numbers",
             "text": "firstStage.mode must be log, firstStageFStatistic at or above 10, and "
                     "publicationBias.pValue says whether there was bias to correct."},
            {"@type": "HowToStep", "name": "Handle a weak first stage",
             "url": "https://meta-analysis.cz/maive/how-to/#weak-first-stage",
             "text": "Below an F of 10 do not quote the point estimate: report the "
                     "Anderson-Rubin interval and run RTMA as well."},
        ],
    }

    return PAGE % {
        "jsonld": json.dumps(ld, ensure_ascii=False, separators=(",", ":")),
        "footer": homepage_footer(),
        "k": "{:,}".format(ds["estimates"]), "studies": ds["studies"],
        "mean": n(ds["simple_mean"]),
        "maive": n(mv.get("effectEstimate")), "maive_se": n(mv.get("standardError")),
        "waive": n(wv.get("effectEstimate")), "waive_se": n(wv.get("standardError")),
        "F": n(mv.get("firstStageFStatistic"), 1),
        "bias_p": "%.0e" % float(mv["publicationBias"]["pValue"])
                  if mv.get("publicationBias", {}).get("pValue") else "&#8212;",
        "sub_k": "{:,}".format(sub["estimates"]), "sub_studies": sub["studies"],
        "sub_F": n(wk.get("firstStageFStatistic"), 2),
        "sub_maive": n(wk.get("effectEstimate")), "sub_se": n(wk.get("standardError")),
        "ar_lo": n(ar[0]) if ar else "&#8212;", "ar_hi": n(ar[1]) if ar else "&#8212;",
        "mu": n(rt.get("mu")), "mu_lo": n(mu_ci[0]) if mu_ci else "&#8212;",
        "mu_hi": n(mu_ci[1]) if mu_ci else "&#8212;",
        "rhat": n((dg.get("rHat") or {}).get("mu"), 3),
        "neff": "%.0f" % (dg.get("nEff") or {}).get("mu", 0),
        "affirm": rt.get("affirmativeCount"),
        "divergences": dg.get("divergences"),
        "funnel_svg": svg, "se_cap": "%.2f" % se_cap,
        "r2": "%.2f" % ds["circularity_r2"],
        "request": request, "ai": ai_prompt, "retrieved": doc["retrieved"],
        "mode": (mv.get("firstStage") or {}).get("mode", "?"),
    }


def main():
    if "--refresh" in sys.argv:
        doc = refresh()
    else:
        doc = json.load(open(SIDECAR, encoding="utf-8"))
    os.makedirs(OUT_DIR, exist_ok=True)
    page = render(doc)
    open(os.path.join(OUT_DIR, "index.html"), "w", encoding="utf-8").write(page)
    print("maive/how-to/index.html: %d bytes (numbers retrieved %s)" % (len(page), doc["retrieved"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
