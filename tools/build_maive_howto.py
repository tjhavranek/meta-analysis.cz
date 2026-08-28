"""Build /maive/how-to/ -- run MAIVE in EasyMeta on real data, in very few words.

The page shows one worked example (tuition and university enrolment), the two standard
complications (a weak first stage; suspected p-hacking), EasyMeta's own funnel plot, and a
collapsed block for AI assistants and code. Every number is fetched live, recorded verbatim
in api/v1/maive-howto.json, and the page is rendered from that file, so the gate can prove
the page says what the API said.

    python tools/build_maive_howto.py --refresh   # call the API, rewrite sidecar + funnel + CSV
    python tools/build_maive_howto.py             # rebuild the page from the sidecar

THE TRAPS, all verified live and all invisible in a 200 response:

1. Parameters must be NESTED under "parameters"; top-level ones are silently ignored.
2. The async endpoint ignores modelType and runs MAIVE whatever is asked. Numbers therefore
   come from the sync endpoint only; the funnel exists only on async, so it is fetched from
   an async MAIVE run and accepted only if async and sync agree on the headline statistics.
3. standardErrorTreatment alone does NOT cluster by study -- it only
   picks the small-sample correction, and without "includeStudyClustering": true every
   estimate is its own cluster (MAIVE's validation.r builds g = seq_len(M)). The flag
   changes the standard errors, the first-stage F, and -- because PET-vs-PEESE selection
   tests the PET intercept with the clustered variance -- it can move the point estimate
   itself. On one literature here the flag moves 0.195 to 0.091 and F from 347 to 8.
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
CSV_OUT = os.path.join(OUT_DIR, "alpha.csv")
TABLE = os.path.join(ROOT, "data", "v1", "estimates_harmonised.csv")

# One recipe everywhere. standardErrorTreatment names the variance estimator;
# includeStudyClustering is what actually clusters by study_id. Both, always.
# bootstrap is the cluster wild bootstrap, which is guideline 14 on this site below 40
# studies: the worked example has nine. It is SE = 3 in the MAIVE R package, and the two
# agree to every printed digit.
CANON = {"modelType": "MAIVE", "maiveMethod": "PET-PEESE", "weight": "equal_weights",
         "useLogFirstStage": True, "standardErrorTreatment": "bootstrap",
         "includeStudyClustering": True, "winsorize": 0, "computeAndersonRubin": True}


# The flagship is a subset of the hedge-fund alpha literature: asset-based-style pricing
# models estimated on cross-sectional samples. Both filters are on the page, because a reader
# starting from alphas.xlsx has to be able to rebuild these 75 rows. Nothing is winsorised,
# trimmed or otherwise cleaned: the alphas paper does not winsorise, and neither does this.
def flagship():
    import pandas as pd
    d = pd.read_excel(os.path.join(ROOT, "alphas", "alphas.xlsx"))
    d = d.dropna(subset=["alpha", "se", "study_id", "sample_size"])
    d = d[(d.se > 0) & (d.sample_size > 0)]
    d = d[(d.model_asset_based == 1) & (d.data_cross_section == 1)]
    d = d.rename(columns={"alpha": "effect", "sample_size": "n_obs"})
    d = d[["effect", "se", "n_obs", "study_id"]].copy()
    rows = [{"effect": float(r.effect), "se": float(r.se),
             "n_obs": int(r.n_obs), "study_id": str(r.study_id)} for r in d.itertuples()]
    return rows, d


def usable(dataset):
    import pandas as pd
    d = pd.read_csv(TABLE, low_memory=False)
    d = d[d.dataset == dataset].dropna(subset=["effect", "se", "n_obs"])
    d = d[(d.se > 0) & (d.n_obs > 0)]
    rows = [{"effect": float(r.effect), "se": float(r.se),
             "n_obs": int(r.n_obs), "study_id": str(r.study_id)} for r in d.itertuples()]
    return rows, d


def descriptives(d):
    import numpy as np
    e, se, n = d.effect.values, d.se.values, d.n_obs.values
    t = abs(e / se)
    x, y = np.log(n), np.log(se ** 2)
    X = np.column_stack([np.ones(len(d)), x])
    b, *_ = np.linalg.lstsq(X, y, rcond=None)
    r = y - X @ b
    r2 = 1 - (r @ r) / ((y - y.mean()) @ (y - y.mean()))
    return {"estimates": len(d), "studies": int(d.study_id.nunique()),
            "simple_mean": round(float(e.mean()), 4),
            "share_negative": round(float((e < 0).mean()), 4),
            "caliper_above": int(((t >= 1.96) & (t < 2.46)).sum()),
            "caliper_below": int(((t >= 1.46) & (t < 1.96)).sum()),
            "r2_logse2_logn": round(float(r2), 4)}


def post(path, body):
    r = subprocess.run(["curl", "-sS", "--max-time", "170", "-A", UA, API + path,
                        "-H", "Content-Type: application/json", "--data-binary", "@-"],
                       input=json.dumps(body), capture_output=True, text=True)
    if r.returncode or not r.stdout.strip().startswith("{"):
        raise SystemExit("API call failed: %s%s" % (r.stderr[:300], r.stdout[:300]))
    out = json.loads(r.stdout)
    if "error" in out:
        raise SystemExit("API error: %s" % out["error"])
    return out


def get(path, query=""):
    r = subprocess.run(["curl", "-sS", "--max-time", "60", "-A", UA, API + path + query],
                       capture_output=True, text=True)
    return json.loads(r.stdout) if r.stdout.strip().startswith("{") else {}


def async_funnel(rows, params):
    job = post("/v1/runs", {"data": rows, "parameters": params}).get("jobId")
    for _ in range(40):
        out = get("/v1/runs/%s" % job, "?include=plot")
        if out.get("status") in ("succeeded", "failed", "timedout"):
            return out.get("result") or {}
        time.sleep(5)
    raise SystemExit("async run did not finish")


def refresh():
    runs, data = {}, {}

    def run(key, rows, params, path="/v1/run-model"):
        resp = post(path, {"data": rows, "parameters": params})
        runs[key] = {"request_parameters": params, "n_rows": len(rows), "response": resp}
        print("  %-14s %s" % (key, {k: resp.get(k) for k in
                                    ("effectEstimate", "standardError",
                                     "firstStageFStatistic", "mu") if k in resp}))
        time.sleep(2)
        return resp

    print("sync runs (the endpoint that honours modelType):")
    # No run uses the app's winsorize setting. The MAIVE R package has no winsorisation
    # argument -- the app applies its own rule before calling -- and that rule is not plain
    # quantile clipping, so a run using it could not be reproduced by the R code this page
    # prints. Everything here runs on the data as published.
    alpha_rows, alpha_d = flagship()
    data["alpha"] = descriptives(alpha_d)
    data["alpha"]["subset"] = "alphas: model_asset_based == 1 and data_cross_section == 1"
    alpha = run("alpha_maive", alpha_rows, dict(CANON))

    euro_rows, euro_d = usable("euro")
    data["euro"] = descriptives(euro_d)
    run("euro_maive", euro_rows, dict(CANON))
    # RTMA on euro is archived as evidence for naming it as the weak-first-stage cross-check,
    # not for any number: the page quotes none of it. Worth knowing when reading the record:
    # this run has 84 divergent transitions and R-hat near 1.05, so its posterior should not be
    # quoted from here without rerunning. favorPositive true because this literature's mean and
    # selection direction are positive.
    run("euro_rtma", [{"effect": r["effect"], "se": r["se"]} for r in euro_rows],
        {"favorPositive": True, "alphaSelect": 0.05, "ciLevel": 0.95, "seed": 2025},
        "/v1/run-rtma")

    # The p-hacking example needs a first stage that is evidence, not arithmetic:
    # in partial-correlation literatures SE is a function of N by construction, so
    # log(SE^2) ~ log N fits perfectly and WAIVE has nothing left to find.
    esg_rows, esg_d = usable("esg")
    data["esg"] = descriptives(esg_d)
    run("esg_maive", esg_rows, dict(CANON))
    run("esg_waive", esg_rows, dict(CANON, modelType="WAIVE"))

    print("async funnel (flagship; accepted only if async agrees with sync):")
    plot = async_funnel(alpha_rows, dict(CANON))
    for f in ("effectEstimate", "standardError", "firstStageFStatistic"):
        if plot.get(f) != alpha.get(f):
            raise SystemExit("async %s=%r disagrees with sync %r -- funnel rejected"
                             % (f, plot.get(f), alpha.get(f)))
    os.makedirs(OUT_DIR, exist_ok=True)
    img = plot.get("funnelPlot") or ""
    open(FUNNEL, "wb").write(base64.b64decode(img.split(",")[-1]))
    print("  funnel.png %d bytes, async==sync on all headline statistics"
          % os.path.getsize(FUNNEL))

    with open(CSV_OUT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("effect,se,n_obs,study_id\n")
        for r in alpha_rows:
            fh.write("%s,%s,%d,%s\n" % (r["effect"], r["se"], r["n_obs"],
                                        r["study_id"].replace(",", ";")))
    print("  alpha.csv: %d rows" % len(alpha_rows))

    doc = {
        "what": "Every number on https://meta-analysis.cz/maive/how-to/, with the request "
                "that produced it.",
        "how": "tools/build_maive_howto.py --refresh. Numbers from the SYNCHRONOUS endpoint "
               "(async ignores modelType). Parameters nested under 'parameters' (top-level "
               "is silently ignored). includeStudyClustering true everywhere: the SE "
               "alone only selects the small-sample correction, not the clustering.",
        # The rows printed in the API example. Recorded so the page cannot drift from the
        # CSV it ships: they are real rows, not illustrative ones.
        "example_rows": alpha_rows[:5] + [r for r in alpha_rows if r["study_id"] == "20"][:1],
        "api": API, "retrieved": datetime.date.today().isoformat(),
        "datasets": data, "settings": CANON, "runs": runs,
        "funnel": {"file": "/maive/how-to/funnel.png",
                   "from": "async MAIVE run, accepted after matching the sync run on "
                           "estimate, SE and first-stage F",
                   "async_first_stage_f": plot.get("firstStageFStatistic")},
    }
    os.makedirs(os.path.dirname(SIDECAR), exist_ok=True)
    json.dump(doc, open(SIDECAR, "w", encoding="utf-8"), indent=1, ensure_ascii=False,
              sort_keys=True)
    print("wrote %s" % SIDECAR)
    return doc


def sig1(x):
    """One-significant-digit scientific notation with a real multiplication sign."""
    m = "%.0e" % float(x)
    mant, exp = m.split("e")
    return "%s&#215;10<sup>&#8722;%d</sup>" % (mant, abs(int(exp)))


def n(x, d=3):
    return "NA" if x is None or x == "NA" else ("%.*f" % (d, float(x)))


PAGE = """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" \
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>How to run MAIVE</title>
<meta name="description" content="Run MAIVE in EasyMeta on real data: the four columns it \
needs, a worked example with the funnel, and what to do when the first stage is weak or \
p-hacking is suspected." />
<link rel="canonical" href="https://meta-analysis.cz/maive/how-to/" />
<meta property="og:site_name" content="meta-analysis.cz" />
<meta property="og:type" content="website" />
<meta property="og:title" content="How to run MAIVE" />
<meta property="og:description" content="Run MAIVE in EasyMeta on real data: the four columns it needs, a worked example with the funnel, and what to do when the first stage is weak or p-hacking is suspected." />
<meta property="og:url" content="https://meta-analysis.cz/maive/how-to/" />
<link href="/style.css" rel="stylesheet" type="text/css" />
<link href="/paper.css" rel="stylesheet" type="text/css" />
<script type="application/ld+json">%(jsonld)s</script>
</head>
<body>
<div id="wrapper">
<div id="logo">
\t<a class="masthead-home" href="/">meta-analysis.cz</a>
\t<p class="site-name"><a href="/maive/how-to/">How to run MAIVE</a></p>
\t<h2> <span class="mk">&raquo;</span>&nbsp;&nbsp;&nbsp; in EasyMeta, on real data</h2>
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
</div>
<!-- start page -->
<div id="page" class="single">
\t<div id="content">
\t\t<div class="post">
\t\t\t<div class="entry">

<p class="lede"><b>MAIVE corrects meta-analyses for publication bias and for many forms of
p-hacking.</b> Besides effect and standard error, it also asks for sample size.</p>

<p><b>You will need:</b> <code>effect</code> &middot; <code>se</code> &middot;
<code>n_obs</code> &middot; <code>study_id</code> (the latter is needed when a study reports
several estimates, and inference then clusters on it)</p>

<p class="cta"><a class="button" href="https://www.easymeta.org/">Open EasyMeta</a>
<a class="button quiet" href="/maive/how-to/alpha.csv">Download the example data
(CSV)</a></p>

<p class="run-ai"><b>Or hand it to an AI assistant.</b> Attach your spreadsheet and say:
<code>Run MAIVE on this dataset, following the protocol at
https://meta-analysis.cz/maive/how-to/#ai</code>. If your assistant cannot read links, open
<a href="#ai">the protocol block at the foot of this page</a> and paste the protocol
instead.</p>

<h2 id="example">Worked example: do hedge funds earn alpha?</h2>

<p><a href="/alphas/">%(alpha_k)s estimates from %(alpha_g)s studies</a>, restricted in this
tutorial to asset-based-style models (the ones that price a fund against benchmarks you can
trade) estimated on cross-sectional data. The mean reported alpha is %(alpha_mean)s%% per
month.</p>

<p><img src="/maive/how-to/funnel.png" alt="EasyMeta funnel plot: %(alpha_k)s hedge-fund alpha
estimates against their standard errors. The cloud leans right as precision falls, and the MAIVE fit
lands near zero, well left of the simple mean." width="840" height="840" /></p>

<p class="aside"><b>Reading the funnel.</b> Each hollow point is a reported estimate
plotted against its standard error, so the most precise estimates sit at the top. The
filled points are the same estimates carrying the standard error MAIVE fits from sample size
instead of the reported one, and the solid line is MAIVE's fit through them. It is straight
because the PET-PEESE rule picks PET when the intercept is not significant, as here, and the
PEESE quadratic when it is.</p>

<p class="result"><b>MAIVE: %(alpha_est)s%% per month (SE %(alpha_se)s).</b><br />
<span class="settings">First-stage F: %(alpha_F)s. Settings: PET-PEESE, log first stage,
equal weights, wild bootstrap clustered by study.</span></p>

<p>Reading the output, as EasyMeta reports it:</p>

<ul class="reading">
<li><b>Bias test.</b> The Egger test rejects funnel symmetry
(p&nbsp;=&nbsp;%(alpha_egger_p)s): the less precise an estimate, the larger the alpha it
reports.</li>
<li><b>Spurious precision.</b> The Hausman statistic is %(alpha_haus)s against a critical
value of 3.84: MAIVE and plain PET-PEESE agree here, so the test does not detect inflated
precision, and the correction comes from the funnel asymmetry.</li>
<li><b>Corrected effect.</b> %(alpha_est)s%% per month against a reported %(alpha_mean)s%%.
Corrected, the alpha is gone.</li>
</ul>

<p class="aside">Shrinking the plain PET-PEESE estimate further is the usual outcome. In the
<a href="/maive/paper/">paper</a>, across 267 meta-analyses with a first-stage F above 10,
MAIVE landed closer to zero than PET-PEESE in 67%% of them, and in 75%% of those where
PET-PEESE was significant.</p>

<h2 id="weak-first-stage">If the first stage is weak</h2>

<p>Below an F of 10, report the Anderson-Rubin interval instead of the point estimate. In
the <a href="/euro/">euro-trade dataset</a> (%(euro_k)s estimates)
F is %(euro_F)s; MAIVE gives %(euro_est)s (SE %(euro_se)s), and the AR interval is
[%(euro_ar_lo)s, %(euro_ar_hi)s], so the corrected effect is only weakly identified. RTMA,
by Mathur, rests on different assumptions and is the cross-check to run when the first stage
is this weak. EasyMeta runs it too.</p>

<h2 id="p-hacking">If you suspect serious p-hacking</h2>

<p>In the <a href="/esg/">female directors and ESG ratings dataset</a> (%(ph_k)s estimates
from %(ph_g)s studies, mean %(ph_mean)s rating points), %(ph_above)s estimates sit just
above |z|&nbsp;=&nbsp;1.96 and %(ph_below)s just below, in windows 0.5 wide. Bunching like
that is what selective reporting leaves behind.</p>

<p>WAIVE, an experimental option in EasyMeta, is the more aggressive correction: it
additionally downweights estimates that look too precise for their sample size.
MAIVE gives %(ph_maive)s (SE %(ph_maive_se)s), WAIVE %(ph_waive)s (SE %(ph_waive_se)s).
MAIVE still finds an effect here; WAIVE does not.</p>

<h2 id="in-r">The same run in R</h2>

<p>EasyMeta runs the <a href="https://cran.r-project.org/package=MAIVE">MAIVE package</a>.
These arguments are the settings above, and they return the same numbers to every digit
printed on this page.</p>

<pre class="code"><code>install.packages("MAIVE")
library(MAIVE)

d &lt;- read.csv("https://meta-analysis.cz/maive/how-to/alpha.csv")
dat &lt;- data.frame(bs = d$effect, sebs = d$se,
                  Ns = d$n_obs, study_id = d$study_id)

fit &lt;- maive(dat,
             method = 3,        # PET-PEESE
             weight = 0,        # equal weights
             instrument = 1,    # MAIVE; 0 gives plain PET-PEESE
             studylevel = 2,    # cluster by study
             SE = 3,            # wild bootstrap
             AR = 1,            # Anderson-Rubin interval
             first_stage = 1)   # log first stage; package defaults to levels

fit$beta                 # corrected estimate, and fit$SE its standard error
fit$SE_instrumented      # one corrected standard error per estimate</code></pre>

<h2 id="elsewhere">Corrected standard errors for any estimator</h2>

<p>You do not have to run a meta-regression to use MAIVE. Both the app and the package
return the fitted standard error of every estimate, <code>seInstrumented</code> in the API
response and <code>SE_instrumented</code> in R. Use those in place of the reported ones and
run whatever you would have run anyway: random effects, a selection model, anything that
takes a standard error. The p-hacking that operates through reported precision is corrected
before your estimator ever sees the data.</p>

<details class="forbots" id="ai">
<summary>For AI assistants and code</summary>
<pre class="code"><code>POST https://api.maive.eu/v1/run-model
{
%(example_rows)s
  "parameters": {
    "modelType": "MAIVE", "maiveMethod": "PET-PEESE", "weight": "equal_weights",
    "useLogFirstStage": true,
    "standardErrorTreatment": "bootstrap", "includeStudyClustering": true,
    "computeAndersonRubin": true, "winsorize": 0
  }
}</code></pre>
<p class="aside">Those are the first six of the 75 rows in
<a href="/maive/how-to/alpha.csv">alpha.csv</a>; send all of them to get the numbers above.</p>
<p>Full protocol, if your assistant cannot read links:</p>
<pre class="code prompt"><code>Run MAIVE on my data via the EasyMeta API (POST api.maive.eu/v1/run-model).
Send "data" as row objects with effect, se and n_obs. n_obs is the total
sample size behind the estimate, not degrees of freedom; never guess it or
back it out of the standard error. Add study_id only where several estimates
come from one primary study: never invent it, and ask if the grouping is
unclear. Giving every row its own study_id is rejected.

Nest exactly this under "parameters":
{"modelType": "MAIVE", "maiveMethod": "PET-PEESE", "weight": "equal_weights",
"useLogFirstStage": true, "standardErrorTreatment": "bootstrap",
"includeStudyClustering": true, "computeAndersonRubin": true, "winsorize": 0}.
Top-level settings are silently ignored. Use the synchronous endpoint.
includeStudyClustering is what clusters; dropping it changes the standard
errors and the F without any error. Check firstStage.mode is "log" in the
response; anything else means the settings did not take effect.

Read effectEstimate, standardError, firstStageFStatistic, publicationBias,
hausmanTest, andersonRubinCI and seInstrumented from the response, and compute
the simple mean from the effects you sent. Report the corrected estimate
against that mean, the first-stage F, the Egger and Hausman tests, and the
Anderson-Rubin interval whenever F &lt; 10, in place of the point estimate.
Report any warnings verbatim. If you cannot issue the request, say so and tell
the user to upload their spreadsheet at easymeta.org. For R users, hand them
this rather than R from memory:
  library(MAIVE)
  fit &lt;- maive(data.frame(bs = effect, sebs = se, Ns = n_obs, study_id),
               method = 3, weight = 0, instrument = 1, studylevel = 2,
               SE = 3, AR = 1, first_stage = 1)
With no grouping, drop study_id from the data.frame and set studylevel = 0.
Never report numbers you did not receive or compute from the data you sent.</code></pre>
</details>

<p class="aside">MAIVE is not tied to PET-PEESE. EasyMeta will apply the same correction to
PET, PEESE or the endogenous kink model, and it also runs weighted least squares and
RTMA.</p>

<p class="provenance">Computed with EasyMeta on meta-analysis.cz data v1.1.1,
%(retrieved)s; every request and response archived in
<a href="/api/v1/maive-howto.json">maive-howto.json</a>. The settings on this page are the
specification we recommend as authors of MAIVE. It is newer than the
<a href="/maive/paper/">2025 Nature Communications paper</a>: the log first stage now
replaces the levels baseline used there.</p>

\t\t\t</div>
\t\t</div>
\t</div>
</div>
<!-- end page -->
%(footer)s
</body>
</html>
"""


def example_rows(rows):
    """The "data" array in the API example, rendered from rows that actually ship in
    alpha.csv. Standard errors are printed to 4 places, which is what a reader retyping
    the example needs; the CSV carries full precision."""
    out = []
    for r in rows:
        out.append('    {"effect": %-7s "se": %-7s "n_obs": %-4s "study_id": "%s"},'
                   % ("%g," % round(r["effect"], 4), "%g," % round(r["se"], 4),
                      "%d," % int(r["n_obs"]), r["study_id"]))
    out[-1] = out[-1].rstrip(",")
    return '  "data": [\n' + "\n".join(out) + "\n  ],"


def render(doc):
    ds, runs = doc["datasets"], doc["runs"]
    alpha = runs["alpha_maive"]["response"]
    euro = runs["euro_maive"]["response"]
    rtma = runs["euro_rtma"]["response"]
    em, ew = runs["esg_maive"]["response"], runs["esg_waive"]["response"]
    ar = euro.get("andersonRubinCI") or ["NA", "NA"]

    ld = {
        "@context": "https://schema.org", "@type": "HowTo",
        "@id": "https://meta-analysis.cz/maive/how-to/#howto",
        "name": "How to run MAIVE",
        "description": "Correct a meta-analysis for publication bias and for many forms of "
                       "p-hacking, using four columns of data and the EasyMeta app or API.",
        "inLanguage": "en", "license": "https://creativecommons.org/licenses/by/4.0/",
        "isBasedOn": "https://meta-analysis.cz/maive/#paper",
        "about": {"@id": "https://meta-analysis.cz/maive/#paper"},
        "tool": {"@type": "SoftwareApplication", "name": "EasyMeta",
                 "url": "https://www.easymeta.org/"},
        "step": [
            {"@type": "HowToStep", "name": "Assemble four columns",
             "url": "https://meta-analysis.cz/maive/how-to/",
             "text": "One row per estimate: effect, se, n_obs, and study_id when a study "
                     "reports several estimates. With study_id, inference clusters on it."},
            {"@type": "HowToStep", "name": "Run MAIVE",
             "url": "https://meta-analysis.cz/maive/how-to/#example",
             "text": "Upload the CSV to easymeta.org, or POST the rows as JSON to "
                     "https://api.maive.eu/v1/run-model with parameters nested under "
                     "'parameters': modelType MAIVE, maiveMethod PET-PEESE, weight "
                     "equal_weights, useLogFirstStage true, standardErrorTreatment "
                     "bootstrap, includeStudyClustering true, computeAndersonRubin true, "
                     "winsorize 0."},
            {"@type": "HowToStep", "name": "Read the diagnostics before the estimate",
             "url": "https://meta-analysis.cz/maive/how-to/#example",
             "text": "The Egger test detects funnel asymmetry, which selective reporting "
                     "produces and genuine differences between studies can too; the Hausman "
                     "test compares MAIVE with plain PET-PEESE; the first-stage F says "
                     "whether the instrument is strong."},
            {"@type": "HowToStep", "name": "Reuse the corrected standard errors",
             "url": "https://meta-analysis.cz/maive/how-to/#elsewhere",
             "text": "The run returns a corrected standard error for every estimate, "
                     "seInstrumented in the API and SE_instrumented in R. Substitute them "
                     "for the reported ones in any other estimator: random effects, a "
                     "selection model, anything that takes a standard error."},
            {"@type": "HowToStep", "name": "Handle a weak first stage",
             "url": "https://meta-analysis.cz/maive/how-to/#weak-first-stage",
             "text": "Below an F of 10, report the Anderson-Rubin interval rather than the "
                     "point estimate, and check any RTMA cross-check against its own "
                     "convergence diagnostics before quoting it."},
        ],
    }

    return PAGE % {
        "example_rows": example_rows(doc["example_rows"]),
        "jsonld": json.dumps(ld, ensure_ascii=False, separators=(",", ":")),
        "footer": homepage_footer(), "retrieved": doc["retrieved"],
        "alpha_k": ds["alpha"]["estimates"], "alpha_g": ds["alpha"]["studies"],
        "alpha_mean": n(ds["alpha"]["simple_mean"], 2),
        "alpha_est": n(alpha.get("effectEstimate")), "alpha_se": n(alpha.get("standardError")),
        "alpha_F": n(alpha.get("firstStageFStatistic"), 1),
        "alpha_egger_p": n(alpha["publicationBias"]["pValue"], 3),
        "alpha_haus": n((alpha.get("hausmanTest") or {}).get("statistic"), 2),
        # No study count for euro. The pooled table's study_id is factorised from the author
        # label where no id column matches its name pattern, so euro's 61 studies -- one
        # estimate each, and 61 is what the paper states -- come through as 52. The run below
        # clusters on that same study_id, so the page stays exactly reproducible from the
        # pooled table; what it must not do is report 52 as a fact about the literature.
        # The mechanism is recorded in api/v1/README.md and is fixed at the next data revision.
        "euro_k": ds["euro"]["estimates"],
        "euro_F": n(euro.get("firstStageFStatistic"), 2),
        "euro_est": n(euro.get("effectEstimate"), 2),
        "euro_se": n(euro.get("standardError"), 2),
        "euro_ar_lo": n(ar[0], 2), "euro_ar_hi": n(ar[1], 2),
        "ph_k": ds["esg"]["estimates"], "ph_g": ds["esg"]["studies"],
        "ph_above": ds["esg"]["caliper_above"], "ph_below": ds["esg"]["caliper_below"],
        "ph_mean": n(ds["esg"]["simple_mean"], 2),
        "ph_maive": n(em.get("effectEstimate"), 3), "ph_maive_se": n(em.get("standardError"), 3),
        "ph_waive": n(ew.get("effectEstimate"), 3), "ph_waive_se": n(ew.get("standardError"), 3),
    }


def main():
    doc = refresh() if "--refresh" in sys.argv else json.load(open(SIDECAR, encoding="utf-8"))
    os.makedirs(OUT_DIR, exist_ok=True)
    page = render(doc)
    open(os.path.join(OUT_DIR, "index.html"), "w", encoding="utf-8").write(page)
    print("maive/how-to/index.html: %d bytes (numbers retrieved %s)"
          % (len(page), doc["retrieved"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
