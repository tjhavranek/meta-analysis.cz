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
CSV = os.path.join(ROOT, "maive", "how-to", "education.csv")


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
    for key in ("edu_maive", "euro_maive", "comp_maive", "comp_waive"):
        p = runs[key]["request_parameters"]
        if p.get("includeStudyClustering") is not True:
            fail("%s ran without includeStudyClustering -- its SEs are not clustered" % key)
        if p.get("useLogFirstStage") is not True:
            fail("%s did not request the log first stage" % key)
        if p.get("standardErrorTreatment") != "clustered_cr2":
            fail("%s did not request the CR2 correction" % key)
        got = (runs[key]["response"].get("firstStage") or {}).get("mode")
        if got != "log":
            fail("%s ran with firstStage.mode=%r -- parameters did not take effect" % (key, got))
    if runs["comp_waive"]["request_parameters"].get("modelType") != "WAIVE":
        fail("the WAIVE run did not ask for WAIVE")

    # 2. Each example is the kind of example the page claims.
    eduF = runs["edu_maive"]["response"].get("firstStageFStatistic")
    euroF = runs["euro_maive"]["response"].get("firstStageFStatistic")
    if not isinstance(eduF, (int, float)) or eduF < 10:
        fail("education F is %r; the page presents it as strong" % eduF)
    if not isinstance(euroF, (int, float)) or euroF >= 10:
        fail("euro F is %r, not below 10; the weak-first-stage card is wrong" % euroF)
    if not (runs["euro_maive"]["response"].get("andersonRubinCI") or [None])[0]:
        fail("the euro run carries no Anderson-Rubin interval")
    ep = (runs["edu_maive"]["response"].get("publicationBias") or {}).get("pValue")
    if not isinstance(ep, (int, float)) or ep >= 0.05:
        fail("education's Egger p is %r; the page says the bias test rejects" % ep)

    # 3. WAIVE must differ from MAIVE with wider uncertainty, or the card shows nothing --
    #    and identical estimates are the signature of the async endpoint's dropped modelType.
    cm, cw = runs["comp_maive"]["response"], runs["comp_waive"]["response"]
    if cm.get("effectEstimate") == cw.get("effectEstimate"):
        fail("WAIVE returned MAIVE's estimate -- modelType was dropped somewhere")
    if not (cw.get("standardError") or 0) > (cm.get("standardError") or 1):
        fail("WAIVE's SE is not wider than MAIVE's; 'less precision' would be false")

    # 4. The RTMA failure the euro card cites must actually be a failure. The count is
    #    unstable run to run (itself a symptom), so the gate asks 'did it fail', not 'by
    #    exactly how much'.
    dg = runs["euro_rtma"]["response"].get("diagnostics") or {}
    if not (dg.get("divergences") or 0) > 0:
        fail("euro RTMA reports no divergences; the page says its sampler fails")
    # 5. The caliper counts on the page must be recomputable from the shipped data.
    import pandas as pd
    d = pd.read_csv(os.path.join(ROOT, "data", "v1", "estimates_harmonised.csv"),
                    low_memory=False)
    g = d[d.dataset == "competition"].dropna(subset=["effect", "se", "n_obs"])
    g = g[(g.se > 0) & (g.n_obs > 0)]
    t = abs(g.effect / g.se)
    above = int(((t >= 1.96) & (t < 2.46)).sum())
    below = int(((t >= 1.46) & (t < 1.96)).sum())
    if (above, below) != (ds["competition"]["caliper_above"], ds["competition"]["caliper_below"]):
        fail("competition caliper counts %r do not recompute from the data (%d, %d)"
             % ((ds["competition"]["caliper_above"], ds["competition"]["caliper_below"]),
                above, below))

    # 6. The page is exactly what the sidecar renders -- the check that catches hand edits.
    from build_maive_howto import render
    if render(doc) != page:
        fail("the page is not what the sidecar renders; run build_maive_howto.py")

    # 7. The artefacts the page links must exist and agree.
    if not os.path.exists(FUNNEL) or os.path.getsize(FUNNEL) < 10000:
        fail("funnel.png missing or truncated")
    if doc["funnel"].get("async_first_stage_f") != eduF:
        fail("the funnel's run and the page's run disagree on F -- wrong plot")
    if not os.path.exists(CSV):
        fail("education.csv missing")
    else:
        lines = open(CSV, encoding="utf-8").read().strip().split("\n")
        if lines[0] != "effect,se,n_obs,study_id":
            fail("education.csv header is not the canonical four columns")
        if len(lines) - 1 != ds["education"]["estimates"]:
            fail("education.csv has %d rows, sidecar says %d"
                 % (len(lines) - 1, ds["education"]["estimates"]))

    if "--live" in sys.argv:
        print("re-running recorded requests against %s" % doc["api"])
        from build_maive_howto import usable
        rows = {k: usable(name)[0] for k, name in
                (("edu_maive", "education"), ("euro_maive", "euro"),
                 ("comp_maive", "competition"), ("comp_waive", "competition"))}
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
