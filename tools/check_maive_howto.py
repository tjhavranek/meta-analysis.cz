"""Check that /maive/how-to/ still says what the API actually returned.

Numbers on this site are computed and checked, never asserted. This page's numbers come from
somebody else's service, so "checked" has to mean something slightly different here: the
sidecar api/v1/maive-howto.json records the exact request and the full response, and this
gate proves the page agrees with the sidecar and that the sidecar's runs were the runs the
page claims they were.

Offline by default -- it runs on every push and never touches the network. With --live it
re-POSTs the recorded requests and reports any number that has moved, which is a weekly job
and must never block a deploy: EasyMeta improving its estimator is not this site breaking.

    python tools/check_maive_howto.py          # the gate
    python tools/check_maive_howto.py --live   # re-run against the API and diff
"""
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_paper_page import ROOT  # noqa: E402

SIDECAR = os.path.join(ROOT, "api", "v1", "maive-howto.json")
PAGE = os.path.join(ROOT, "maive", "how-to", "index.html")
FUNNEL = os.path.join(ROOT, "maive", "how-to", "funnel.png")


def fail(msgs, m):
    msgs.append(m)


def main():
    bad = []
    if not os.path.exists(SIDECAR):
        print("no sidecar at api/v1/maive-howto.json; run build_maive_howto.py --refresh")
        return 1
    doc = json.load(open(SIDECAR, encoding="utf-8"))
    runs = doc["runs"]
    page = open(PAGE, encoding="utf-8").read()

    # 1. The settings the page teaches are the settings that ran. A dropped parameter returns
    #    HTTP 200 and default behaviour, so the only proof is the echo in the response.
    for key in ("maive", "waive", "weak_maive"):
        got = (runs[key]["response"].get("firstStage") or {}).get("mode")
        if got != "log":
            fail(bad, "%s ran with firstStage.mode=%r, not 'log' -- the parameters did not "
                      "take effect" % (key, got))
        sent = runs[key]["request_parameters"]
        if sent.get("useLogFirstStage") is not True:
            fail(bad, "%s did not request useLogFirstStage" % key)
        if sent.get("standardErrorTreatment") != "clustered_cr2":
            fail(bad, "%s did not request CR2 standard errors" % key)
    if runs["waive"]["request_parameters"].get("modelType") != "WAIVE":
        fail(bad, "the WAIVE run did not ask for WAIVE")

    # 2. The two branches of the page must actually be the two branches it describes.
    strong = runs["maive"]["response"].get("firstStageFStatistic")
    weak = runs["weak_maive"]["response"].get("firstStageFStatistic")
    if not isinstance(strong, (int, float)) or strong < 10:
        fail(bad, "the worked example's first-stage F is %r; the page calls it strong" % strong)
    if not isinstance(weak, (int, float)) or weak >= 10:
        fail(bad, "the weak-first-stage example's F is %r, which is not below 10" % weak)
    if runs["weak_maive"]["request_parameters"].get("computeAndersonRubin") is not True:
        fail(bad, "the weak-first-stage run did not request an Anderson-Rubin interval")

    # 3. WAIVE must differ from MAIVE, or the section demonstrates nothing. This also catches
    #    the async endpoint's habit of returning MAIVE for a WAIVE request.
    mv = runs["maive"]["response"].get("effectEstimate")
    wv = runs["waive"]["response"].get("effectEstimate")
    if mv == wv:
        fail(bad, "WAIVE returned MAIVE's estimate (%r) -- the run went to the async "
                  "endpoint, which ignores modelType" % mv)

    # 4. The page must be exactly what the sidecar renders. Checking that each printed
    #    number appears SOMEWHERE in the sidecar is too weak -- a hand-edited 0.195 to 0.421
    #    passed, because 0.421 happened to be a bootstrap bound. Re-rendering is the whole
    #    check: any edit to the page that the sidecar does not imply fails here.
    from build_maive_howto import render
    if render(doc) != page:
        fail(bad, "the page is not what the sidecar renders -- it has been edited by hand, "
                  "or the builder changed without a rebuild. Run build_maive_howto.py")

    # 5. RTMA ran in the direction the page claims. favorPositive defaults to true, and on a
    #    literature of negative effects that default returns an uncorrected mean with a
    #    deceptively tight interval -- and the only signal is a warning. So: the run must carry
    #    no warnings, and its affirmative count must be the one the page prints.
    rtma = runs["weak_rtma"]
    if rtma["request_parameters"].get("favorPositive") is not True:
        fail(bad, "the page says favorPositive true for this literature; the run did not send it")
    warn = rtma["response"].get("warnings") or []
    if warn:
        fail(bad, "the RTMA run carries warnings the page does not print: %r" % warn)
    if not isinstance(rtma["response"].get("affirmativeCount"), int):
        fail(bad, "the RTMA run reports no affirmative count, so its direction cannot be checked")

    # 6. The artefacts the page points at have to exist.
    if not os.path.exists(FUNNEL) or os.path.getsize(FUNNEL) < 10000:
        fail(bad, "maive/how-to/funnel.png is missing or truncated")
    if doc["funnel"].get("async_first_stage_f") != strong:
        fail(bad, "the funnel's run and the page's run disagree on the first-stage F "
                  "(%r vs %r); the plot may not be the plot of these numbers"
                  % (doc["funnel"].get("async_first_stage_f"), strong))

    if "--live" in sys.argv:
        print("re-running the recorded requests against %s" % doc["api"])
        import pandas as pd  # noqa: F401  (only needed for the live path's data rebuild)
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        from build_maive_howto import rows_for
        full, _ = rows_for("all")
        sub, _ = rows_for("iv_panel")
        data = {"maive": full, "waive": full, "weak_maive": sub, "weak_rtma": sub}
        for key, r in runs.items():
            path = "/v1/run-rtma" if key.endswith("rtma") else "/v1/run-model"
            body = {"data": data[key], "parameters": r["request_parameters"]}
            out = subprocess.run(["curl", "-sS", "--max-time", "170",
                                  "https://api.maive.eu" + path, "-H",
                                  "Content-Type: application/json", "--data-binary", "@-"],
                                 input=json.dumps(body), capture_output=True, text=True)
            try:
                fresh = json.loads(out.stdout)
            except ValueError:
                print("  %-12s UNREACHABLE" % key)
                continue
            for field in ("effectEstimate", "standardError", "firstStageFStatistic", "mu"):
                was, now = r["response"].get(field), fresh.get(field)
                if was is not None and now is not None and was != now:
                    print("  %-12s %s moved: %s -> %s" % (key, field, was, now))
            print("  %-12s checked" % key)

    for b in bad:
        print("FAIL %s" % b)
    print("maive/how-to: %d check(s) failed (numbers retrieved %s)" % (len(bad), doc["retrieved"]))
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
