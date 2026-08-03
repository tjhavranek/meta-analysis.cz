#!/usr/bin/env python3
"""Post-deploy smoke test: check what is actually SERVED, not what was pushed.

Every other check in this repository inspects the working tree or the commit. None of
them can answer "is production current?" -- and three separate reviews have now reported
a stale production tree when it was not, every one a crawler cache, each costing two
sessions to disprove by hand. This answers it in one command.

Fetches the public domain with cache-busting and no-cache headers. Standard library
only, so CI needs no dependencies. Exits non-zero on any failure.

    python tools/smoke_live.py [--base https://meta-analysis.cz]

Design follows redesign/audit.py --live, which is the richer local dev tool; this is the
CI-safe subset that lives inside the repository so the workflow can actually reach it.
"""
import json, sys, time, urllib.request, urllib.error

BASE = "https://meta-analysis.cz"
for i, a in enumerate(sys.argv):
    if a == "--base" and i + 1 < len(sys.argv):
        BASE = sys.argv[i + 1].rstrip("/")

fails, checks = [], 0


def get(path, as_json=False):
    url = f"{BASE}{path}" + ("&" if "?" in path else "?") + f"cb={int(time.time()*1000)}"
    req = urllib.request.Request(url, headers={
        "Cache-Control": "no-cache", "Pragma": "no-cache",
        "User-Agent": "meta-analysis.cz-smoke-test"})
    with urllib.request.urlopen(req, timeout=45) as r:
        body = r.read().decode("utf-8", "replace")
    return json.loads(body) if as_json else body


def check(label, ok, detail=""):
    global checks
    checks += 1
    if not ok:
        fails.append(f"{label}{(' — ' + detail) if detail else ''}")


# 1. the key pages are actually served
PAGES = ["/", "/datasets/", "/class/", "/maive/", "/guidelines/", "/404.html", "/komentare/"]
for p in PAGES:
    try:
        get(p)
        check(f"{p} reachable", True)
    except Exception as e:
        check(f"{p} reachable", False, str(e)[:60])

# 2. the live index, and the live page agreeing with it
try:
    api = get("/api/v1/datasets.json", as_json=True)
except Exception as e:
    print(f"SMOKE TEST FAIL: cannot read the live index — {e}")
    sys.exit(1)

c = api["counts"]
try:
    page = get("/datasets/")
except Exception as e:
    page = ""
    check("/datasets/ readable", False, str(e)[:60])

for key in ("datasets", "rows_in_source_files", "estimates_in_analysis_samples",
            "estimates_in_harmonised_table"):
    v = f"{c[key]:,}"
    check(f"/datasets/ shows live {key} ({v})", v in page,
          "the page is stale against the index it is built from")

# 3. the deposit is discoverable from the page
for label, doi in (("concept", api.get("concept_doi")), ("version", api.get("doi"))):
    if doi:
        check(f"/datasets/ carries the {label} DOI", doi in page)

# 4. the licence a machine reads, on every surface that declares one
ok_ds = [d for d in api["datasets"] if d.get("n_estimates")]
check("all datasets declare cc-by-4.0",
      all(d.get("rights_status") == "cc-by-4.0" for d in ok_ds),
      f"{sum(1 for d in ok_ds if d.get('rights_status') != 'cc-by-4.0')} do not")
check("all datasets carry a license_url",
      all(d.get("license_url") for d in ok_ds))
for path, probe in (("/api/v1/croissant.json", "creativecommons.org/licenses/by/4.0"),
                    ("/api/v1/datapackage.json", "CC-BY-4.0"),
                    ("/LICENSE", "CC BY 4.0"),
                    ("/llms.txt", "creativecommons.org/licenses/by/4.0")):
    try:
        check(f"{path} declares CC BY", probe in get(path))
    except Exception as e:
        check(f"{path} declares CC BY", False, str(e)[:60])

# The README is prose, so no field check reaches it. It sat live for hours telling readers
# the data was all rights reserved while every machine-readable surface said CC BY. Scan it.
try:
    _rd = get("/api/v1/README.md")
    check("README declares CC BY", "CC BY 4.0" in _rd)
    for _bad in ("all rights reserved", "does not cover the underlying",
                 "none of which are ours to license", "attribution is not the same as permission"):
        check(f"README free of restrictive text: {_bad!r}", _bad.lower() not in _rd.lower(),
              "contradicts the CC BY policy every other surface declares")
except Exception as e:
    check("README readable", False, str(e)[:60])

if fails:
    print(f"SMOKE TEST FAIL — {len(fails)} of {checks} checks failed")
    for f in fails:
        print("  X " + f)
    sys.exit(1)

print(f"SMOKE TEST PASS — {checks} checks against {BASE}")
print(f"  live: {c['datasets']} datasets, {c['rows_in_source_files']:,} source rows, "
      f"{c['estimates_in_analysis_samples']:,} analysis-sample estimates, "
      f"{c['estimates_in_harmonised_table']:,} harmonised")
print(f"  data version {api.get('data_version')} · concept DOI {api.get('concept_doi')}")
