"""Check that /maive/how-to/ still says what the API actually returned.

The sidecar api/v1/maive-howto.json records every request and response; the page renders
from it. This gate proves, offline on every push: the page is exactly what the sidecar
renders, the settings the page teaches are the settings that ran, each example is the kind
of example the page says it is, and the artefacts the page links exist. With --live it
re-runs the recorded requests and reports drift; that is a weekly job, never a deploy gate.

    python tools/check_maive_howto.py          # the gate
    python tools/check_maive_howto.py --live   # re-run against the API and diff
"""
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_paper_page import ROOT  # noqa: E402

SIDECAR = os.path.join(ROOT, "api", "v1", "maive-howto.json")
PAGE = os.path.join(ROOT, "maive", "how-to", "index.html")
FUNNEL = os.path.join(ROOT, "maive", "how-to", "funnel.png")
CSV = os.path.join(ROOT, "maive", "how-to", "alpha.csv")


def main():
    bad = []
    fail = bad.append
    if not os.path.exists(SIDECAR):
        print("no sidecar; run build_maive_howto.py --refresh")
        return 1
    doc = json.load(open(SIDECAR, encoding="utf-8"))
    runs, ds = doc["runs"], doc["datasets"]
    page = open(PAGE, encoding="utf-8").read()

    # 1. Every MAIVE-family request carried the settings the page teaches -- nested, with
    #    the clustering flag. clustered_cr2 alone does not cluster (singleton clusters), so
    #    the flag's absence would make every printed SE and F wrong while returning 200.
    for key in ("alpha_maive", "euro_maive", "esg_maive", "esg_waive"):
        p = runs[key]["request_parameters"]
        if p.get("includeStudyClustering") is not True:
            fail("%s ran without includeStudyClustering -- its SEs are not clustered" % key)
        if p.get("useLogFirstStage") is not True:
            fail("%s did not request the log first stage" % key)
        if p.get("standardErrorTreatment") != "bootstrap":
            fail("%s did not request the wild bootstrap" % key)
        got = (runs[key]["response"].get("firstStage") or {}).get("mode")
        if got != "log":
            fail("%s ran with firstStage.mode=%r -- parameters did not take effect" % (key, got))
    if runs["esg_waive"]["request_parameters"].get("modelType") != "WAIVE":
        fail("the WAIVE run did not ask for WAIVE")
    # No run may use the app's winsorize setting. The page ships R code that must return the
    # same numbers, and the MAIVE package has no winsorisation argument -- the app applies its
    # own rule before calling, and that rule is not plain quantile clipping, so a run using the
    # setting cannot be reproduced from R. Verified: winsorised at 1% through the setting, the
    # first-stage F drifts (33.24 in R against 33.27 from the app). The flagship's 2% is applied
    # to the rows instead, and those rows are what ship as alpha.csv (check 5c).
    for key in ("alpha_maive", "euro_maive", "esg_maive", "esg_waive"):
        if runs[key]["request_parameters"].get("winsorize") != 0:
            fail("%s used the app's winsorize setting; R could not reproduce it" % key)

    # 2. Each example is the kind of example the page claims.
    flagF = runs["alpha_maive"]["response"].get("firstStageFStatistic")
    euroF = runs["euro_maive"]["response"].get("firstStageFStatistic")
    if not isinstance(flagF, (int, float)) or flagF < 10:
        fail("the flagship F is %r; the page presents it as strong" % flagF)
    if not isinstance(euroF, (int, float)) or euroF >= 10:
        fail("euro F is %r, not below 10; the weak-first-stage card is wrong" % euroF)
    if not (runs["euro_maive"]["response"].get("andersonRubinCI") or [None])[0]:
        fail("the euro run carries no Anderson-Rubin interval")
    ep = (runs["alpha_maive"]["response"].get("publicationBias") or {}).get("pValue")
    if not isinstance(ep, (int, float)) or ep >= 0.05:
        fail("the flagship's Egger p is %r; the page says the bias test rejects" % ep)
    # The page's closing line on the worked example is that the alpha is gone, so the
    # corrected estimate must NOT be significant. If a future rerun makes it significant the
    # sentence becomes false and this fails.
    if runs["alpha_maive"]["response"].get("isSignificant") is not False:
        fail("the flagship's corrected effect is significant; the page says the alpha is gone")

    # 3. The p-hacking card's whole point is that WAIVE reaches a different conclusion from
    #    MAIVE on the same rows. Identical estimates are the signature of a dropped modelType.
    em, ew = runs["esg_maive"]["response"], runs["esg_waive"]["response"]
    if em.get("effectEstimate") == ew.get("effectEstimate"):
        fail("WAIVE returned MAIVE's estimate -- modelType was dropped somewhere")
    if not (em.get("isSignificant") is True and ew.get("isSignificant") is False):
        fail("the page says MAIVE finds an effect and WAIVE does not; this run says "
             "MAIVE %r, WAIVE %r" % (em.get("isSignificant"), ew.get("isSignificant")))
    # The first stage has to be evidence rather than arithmetic: where SE is a function of N
    # by construction (partial correlations), log(SE^2) ~ log N fits perfectly and there is
    # no over-precision left for WAIVE to find.
    if ds["esg"]["r2_logse2_logn"] > 0.6:
        fail("the p-hacking example's log(SE^2) ~ log N R2 is %.3f; its first stage is "
             "arithmetic, not evidence" % ds["esg"]["r2_logse2_logn"])

    # 4. The euro card names RTMA as the cross-check for a weak first stage. The run stays
    #    in the record so the claim is not made on nothing, but the page quotes no number
    #    from it, so there is nothing here to hold to a value.
    if "euro_rtma" not in runs:
        fail("the page names RTMA as the cross-check but no RTMA run is archived")
    # 5. The caliper counts on the page must be recomputable from the shipped data.
    import pandas as pd
    d = pd.read_csv(os.path.join(ROOT, "data", "v1", "estimates_harmonised.csv"),
                    low_memory=False)
    g = d[d.dataset == "esg"].dropna(subset=["effect", "se", "n_obs"])
    g = g[(g.se > 0) & (g.n_obs > 0)]
    t = abs(g.effect / g.se)
    above = int(((t >= 1.96) & (t < 2.46)).sum())
    below = int(((t >= 1.46) & (t < 1.96)).sum())
    if (above, below) != (ds["esg"]["caliper_above"], ds["esg"]["caliper_below"]):
        fail("esg caliper counts %r do not recompute from the data (%d, %d)"
             % ((ds["esg"]["caliper_above"], ds["esg"]["caliper_below"]), above, below))
    # The page states the window; a reader who takes it literally must land on these counts.
    if "windows 0.5 wide" not in page:
        fail("the page no longer states the caliper window it reports counts for")

    # 5b. The R block must encode the same recipe the API requests used. A reader who runs
    #     it has to land on the numbers beside it, so the mapping is checked rather than
    #     trusted: MAIVE package arguments against the API's parameter names.
    p = runs["alpha_maive"]["request_parameters"]
    r_expected = {
        "method = 3": p.get("maiveMethod") == "PET-PEESE",
        "weight = 0": p.get("weight") == "equal_weights",
        "instrument = 1": p.get("modelType") == "MAIVE",
        "studylevel = 2": p.get("includeStudyClustering") is True,
        "SE = 3": p.get("standardErrorTreatment") == "bootstrap",
        "AR = 1": p.get("computeAndersonRubin") is True,
        "first_stage = 1": p.get("useLogFirstStage") is True,
    }
    for arg, agrees in r_expected.items():
        if arg not in page:
            fail("the R block does not pass %s" % arg)
        elif not agrees:
            fail("the R block passes %s but the request did not ask for the matching "
                 "setting" % arg)

    # 5c. The shipped CSV must BE the subset the page describes, row for row: the R code on
    #     the page reads this file, and the page says nothing is winsorised or trimmed. Any
    #     silent cleaning between alphas.xlsx and alpha.csv would make the prose false and
    #     the R reproduction a coincidence.
    import pandas as pd
    from build_maive_howto import flagship
    shipped = pd.read_csv(CSV)
    built = pd.DataFrame(flagship()[0])
    if len(shipped) != len(built):
        fail("alpha.csv has %d rows, the described subset has %d" % (len(shipped), len(built)))
    elif abs(float(shipped.effect.sum()) - float(built.effect.sum())) > 1e-9 or \
            abs(float(shipped.se.sum()) - float(built.se.sum())) > 1e-9:
        fail("alpha.csv is not the subset the page describes; something cleaned the rows")
    if abs(float(shipped.effect.mean()) - ds["alpha"]["simple_mean"]) > 5e-4:
        fail("the shipped CSV's mean effect (%.4f) is not the sidecar's (%.4f)"
             % (shipped.effect.mean(), ds["alpha"]["simple_mean"]))
    if "winsoris" in page or "trimmed" in page:
        fail("the page mentions winsorising or trimming, but flagship() does neither; "
             "either the prose or the subset has drifted")

    # 5d. The funnel caption says the line is straight "as here". True only while the rule
    #     selects PET: a refresh that flipped to PEESE would ship a caption contradicting the
    #     plot beside it.
    sel = runs["alpha_maive"]["response"].get("petpeese_selected")
    if "picks PET when the intercept" in page and sel != "PET":
        fail("the caption says the line is straight but this run selected %r" % sel)

    # 5e. The page tells readers to reuse seInstrumented in other estimators. That is only
    #     useful advice while the field is actually there, one value per estimate.
    si = runs["alpha_maive"]["response"].get("seInstrumented")
    if "seInstrumented" in page and not (
            isinstance(si, list) and len(si) == runs["alpha_maive"]["n_rows"]):
        fail("the page points readers at seInstrumented but the response carries %s"
             % ("no such field" if si is None else "%d of %d values"
                % (len(si), runs["alpha_maive"]["n_rows"])))

    # 5f. Every row printed in the API example must be a real row of the shipped CSV. These
    #     were once typed by hand and went stale the moment the data stopped being winsorised:
    #     two different estimates ended up sharing one standard error, the 2% cap. Rounded to
    #     the 4 places the page prints, each example row must appear in alpha.csv.
    if doc.get("example_rows"):
        have = {(round(float(r["effect"]), 4), round(float(r["se"]), 4),
                 int(float(r["n_obs"])), str(r["study_id"])) for r in shipped.to_dict("records")}
        for r in doc["example_rows"]:
            key = (round(float(r["effect"]), 4), round(float(r["se"]), 4),
                   int(float(r["n_obs"])), str(r["study_id"]))
            if key not in have:
                fail("API example row %s is not in alpha.csv" % (key,))
    else:
        fail("the sidecar records no example_rows, so the API example cannot be checked")

    # 6. The page is exactly what the sidecar renders -- the check that catches hand edits.
    from build_maive_howto import render
    if render(doc) != page:
        fail("the page is not what the sidecar renders; run build_maive_howto.py")

    # 7. The artefacts the page links must exist and agree.
    if not os.path.exists(FUNNEL) or os.path.getsize(FUNNEL) < 10000:
        fail("funnel.png missing or truncated")
    if doc["funnel"].get("async_first_stage_f") != flagF:
        fail("the funnel's run and the page's run disagree on F -- wrong plot")
    if not os.path.exists(CSV):
        fail("alpha.csv missing")
    else:
        lines = open(CSV, encoding="utf-8").read().strip().split("\n")
        if lines[0] != "effect,se,n_obs,study_id":
            fail("alpha.csv header is not the canonical four columns")
        if len(lines) - 1 != ds["alpha"]["estimates"]:
            fail("alpha.csv has %d rows, sidecar says %d"
                 % (len(lines) - 1, ds["alpha"]["estimates"]))

    if "--live" in sys.argv:
        print("re-running recorded requests against %s" % doc["api"])
        from build_maive_howto import usable
        rows = {k: usable(name)[0] for k, name in
                (("euro_maive", "euro"), ("esg_maive", "esg"), ("esg_waive", "esg"))}
        from build_maive_howto import flagship
        rows["alpha_maive"] = flagship()[0]
        rows["euro_rtma"] = [{"effect": r["effect"], "se": r["se"]}
                             for r in usable("euro")[0]]
        for key, r in runs.items():
            path = "/v1/run-rtma" if key.endswith("rtma") else "/v1/run-model"
            out = subprocess.run(["curl", "-sS", "--max-time", "170",
                                  doc["api"] + path, "-H", "Content-Type: application/json",
                                  "--data-binary", "@-"],
                                 input=json.dumps({"data": rows[key],
                                                   "parameters": r["request_parameters"]}),
                                 capture_output=True, text=True)
            try:
                fresh = json.loads(out.stdout)
            except ValueError:
                print("  %-12s UNREACHABLE" % key)
                continue
            for f in ("effectEstimate", "standardError", "firstStageFStatistic", "mu"):
                was, now = r["response"].get(f), fresh.get(f)
                if was is not None and now is not None and was != now:
                    print("  %-12s %s moved: %s -> %s" % (key, f, was, now))
            print("  %-12s checked" % key)

    for b in bad:
        print("FAIL %s" % b)
    print("maive/how-to: %d check(s) failed (numbers retrieved %s)" % (len(bad), doc["retrieved"]))
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
