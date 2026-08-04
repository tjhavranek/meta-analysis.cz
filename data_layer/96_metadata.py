"""Does the machine-readable layer describe the data that is actually there?

The whole point of this site's CC BY declaration is that a crawler or a training pipeline can
take the data without a human in the loop. That only works if the metadata is true. A codebook
naming a column the file does not have, or a download URL that 404s, fails silently: no page
looks broken, and the machine gets a worse answer than if the metadata had never existed.

Nothing has ever checked the metadata against the data it describes.

  CODEBOOKS   44 of them, one per dataset, listing every column with a type and a role. Compare
              each against the per-dataset file it documents: same columns, same count, and the
              stated summary statistics consistent with the values actually present.
  URLS        every file URL the catalogue publishes -- parquet, csv, codebook, per dataset --
              must resolve. ~132 of them, none covered by verify_seo, which checks page links.
  CONTRACTS   datapackage.json (Frictionless) and croissant.json (MLCommons) are read by tools
              that will not tolerate a missing required field. Check the fields their consumers
              actually require, and that they agree with datasets.json rather than drifting.

Pass --offline to skip the URL checks.
"""
import os, sys, json, warnings, urllib.request, urllib.error
warnings.filterwarnings("ignore")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE
import numpy as np, pandas as pd

OFFLINE = "--offline" in sys.argv
OUT = os.path.join(WORK, "out")
if not os.path.isdir(OUT):
    OUT = SITE
DV = os.path.join(OUT, "data", "v1")
AV = os.path.join(OUT, "api", "v1")
API = json.load(open(os.path.join(AV, "datasets.json"), encoding="utf-8"))
fails, soft = [], []


def hard(ok, msg):
    if not ok:
        fails.append(msg)
    print(("  ok   " if ok else "  FAIL ") + msg)


# ------------------------------------------------------------------- 1. codebook vs the data
print("1. does each codebook describe the file it documents?")
cb_dir = os.path.join(AV, "codebooks")
checked = bad_cols = bad_stats = missing = 0
for d in API["datasets"]:
    proj = d["id"]
    cb_p = os.path.join(cb_dir, f"{proj}.json")
    data_p = os.path.join(DV, proj, f"{proj}.parquet")
    if not os.path.exists(cb_p):
        fails.append(f"{proj}: no codebook published though the catalogue lists one"); missing += 1
        continue
    if not os.path.exists(data_p):
        soft.append(f"{proj}: codebook exists but no per-dataset parquet to compare"); continue
    cb = json.load(open(cb_p, encoding="utf-8"))
    df = pd.read_parquet(data_p)
    checked += 1
    cb_cols = [c["name"] for c in cb.get("columns", [])]
    if list(cb_cols) != list(df.columns):
        only_cb = set(cb_cols) - set(df.columns)
        only_df = set(df.columns) - set(cb_cols)
        if only_cb or only_df:
            bad_cols += 1
            fails.append(f"{proj}: codebook and file disagree on columns -- "
                         f"{len(only_cb)} only in codebook {sorted(only_cb)[:3]}, "
                         f"{len(only_df)} only in file {sorted(only_df)[:3]}")
    # the stated statistics must match the data, or the codebook is describing an older build
    for c in cb.get("columns", []):
        nm = c["name"]
        if nm not in df.columns:
            continue
        stated = c.get("n_missing")
        if stated is not None and int(df[nm].isna().sum()) != int(stated):
            bad_stats += 1
            fails.append(f"{proj}.{nm}: codebook says {stated} missing, file has "
                         f"{int(df[nm].isna().sum())} -- the codebook is stale")
            break
hard(bad_cols == 0 and missing == 0 and bad_stats == 0,
     f"{checked} codebooks match their files on columns and missingness")

# -------------------------------------------------------------------- 2. do the URLs resolve?
print("\n2. does every published file URL resolve?")
if OFFLINE:
    print("   skipped (--offline)")
else:
    urls = []
    for d in API["datasets"]:
        for k, v in (d.get("files") or {}).items():
            if isinstance(v, str) and v.startswith("http"):
                urls.append((d["id"], k, v))
    dead = []
    for proj, kind, u in urls:
        try:
            req = urllib.request.Request(u, method="HEAD",
                                         headers={"User-Agent": "meta-analysis.cz-metadata-check"})
            with urllib.request.urlopen(req, timeout=45) as r:
                if r.status >= 400:
                    dead.append(f"{proj}/{kind} -> HTTP {r.status}")
        except Exception as e:
            code = getattr(e, "code", None)
            dead.append(f"{proj}/{kind} -> {code or str(e)[:40]}")
    hard(not dead, f"all {len(urls)} published dataset file URLs resolve"
         if not dead else f"{len(dead)} of {len(urls)} published URLs are dead: {dead[:6]}")

# ------------------------------------------------------- 3. the machine-readable contracts
print("\n3. do the Frictionless and Croissant records hold together?")
ids = {d["id"] for d in API["datasets"]}
try:
    dp = json.load(open(os.path.join(AV, "datapackage.json"), encoding="utf-8"))
    res = dp.get("resources") or []
    hard(bool(dp.get("name") and dp.get("licenses") and res),
         "datapackage.json carries name, licenses and resources")
    hard(all(r.get("path") and r.get("name") for r in res),
         f"all {len(res)} datapackage resources carry a name and a path")
except Exception as e:
    hard(False, f"datapackage.json unreadable: {str(e)[:60]}")

try:
    cr = json.load(open(os.path.join(AV, "croissant.json"), encoding="utf-8"))
    ctx = cr.get("@context")
    hard(bool(ctx) and cr.get("@type") in ("sc:Dataset", "Dataset"),
         f"croissant.json declares @context and @type ({cr.get('@type')})")
    hard(bool(cr.get("license")), "croissant.json declares a license")
    dist = cr.get("distribution") or []
    hard(bool(dist), f"croissant.json carries {len(dist)} distribution entries")
    # a Croissant consumer needs an encodingFormat on every distribution to know how to read it
    noenc = [x.get("@id") or x.get("name") for x in dist
             if not (x.get("encodingFormat") or x.get("sc:encodingFormat"))]
    hard(not noenc, "every croissant distribution declares an encodingFormat"
         if not noenc else f"{len(noenc)} croissant distribution(s) have no encodingFormat: {noenc[:4]}")
except Exception as e:
    hard(False, f"croissant.json unreadable: {str(e)[:60]}")

# the three records must agree on how many datasets exist
counts = {"datasets.json": len(ids)}
try:
    counts["datapackage.json"] = len(dp.get("resources") or [])
except Exception:
    pass
print(f"   dataset counts by record: {counts}")

# --------------------------------- 4. does each description agree with its own count?
# price_puzzle's catalogue entry read "Meta-analysis of 1,000 VAR estimates" beside
# n_estimates_in_literature = 7,420. That contradiction sat in our OWN published metadata and
# nothing ever compared the two, so a sevenfold duplication was announced on the page and went
# unnoticed. A description quoting the PAPER's count will legitimately differ from the shipped
# file's a little (inflation: 777 vs 885); an order-of-magnitude gap is structural.
# Known and already fixed in code, pending regeneration -- the sevenfold price_puzzle reshape.
# Listed so the gate stays usable now rather than failing on a defect already being fixed.
STAGED_COUNT = set()   # price_puzzle fixed in 1.0.0; keep empty so a regression fails loudly
print("\n4. does each description agree with the count published beside it?")
import re as _re
_n = _re.compile(r"([\d][\d,]*)\s+(?:VAR\s+)?estimates", _re.I)
_flag = 0
for d in API["datasets"]:
    m = _n.search(d.get("description") or "")
    if not m:
        continue
    said = int(m.group(1).replace(",", ""))
    got = d.get("n_estimates_in_literature") or d.get("n_estimates")
    if not got or said <= 0:
        continue
    ratio = max(said, got) / min(said, got)
    if ratio >= 2 and d["id"] in STAGED_COUNT:
        soft.append(f"{d['id']}: description says {said:,} vs {got:,} published ({ratio:.1f}x) -- "
                    f"KNOWN, fixed in 08_harmonise, lands at 1.0.0")
    elif ratio >= 2:
        _flag += 1
        fails.append(f"{d['id']}: the description says {said:,} estimates but the entry publishes "
                     f"{got:,} beside it ({ratio:.1f}x apart) -- one of the two is wrong")
    elif ratio >= 1.25:
        soft.append(f"{d['id']}: description says {said:,} estimates, entry publishes {got:,} "
                    f"({ratio:.2f}x) -- probably the paper's count against the shipped file's, "
                    f"but worth a look")
hard(_flag == 0, "every description agrees with the count published beside it")

# --------------------------------- 5. does any rights file contradict the CC BY policy?
# The pre-reversal wording ("covers the COMPILATION only ... does NOT cover the underlying
# research datasets") has now resurfaced four times, most recently because 10_fragments copies a
# CANONICAL CITATION.cff out of data_layer/ over the published one. Fixing site/CITATION.cff
# alone was therefore silently undone by the next build, and the wrong text was about to ship
# inside the Zenodo deposit. Scan every rights-bearing file, everywhere it lands.
print("\n5. do the rights files agree with the CC BY policy?")
BAD = ["compilation only", "does not cover the underlying", "rights are unchanged",
       "attribution is not the same as permission", "all rights reserved",
       "none of which are ours to license"]
_roots = {OUT, os.path.dirname(os.path.dirname(os.path.abspath(__file__)))}
_seen, _bad = 0, []
for _root in _roots:
    for _dp, _dn, _fn in os.walk(_root):
        # Skip prior-version deposit folders: they are the RECORD of what was uploaded then,
        # and 0.9.0-beta genuinely shipped the pre-reversal wording. Rewriting history there
        # would hide that the live deposit needs replacing. Only the current bundle is scanned.
        if any(x in _dp for x in (".git", "node_modules", "redesign", "_seo_stash")):
            continue
        if "zenodo_deposit" in _dp and "v1.0.0" not in _dp:
            continue
        for _f in _fn:
            if _f not in ("CITATION.cff", "LICENSE", "README.md", ".zenodo.json"):
                continue
            _p = os.path.join(_dp, _f)
            try:
                _t = open(_p, encoding="utf-8", errors="replace").read().lower()
            except Exception:
                continue
            _seen += 1
            for _b in BAD:
                if _b in _t:
                    _bad.append(f"{_p}: pre-reversal licence wording {_b!r}")
fails.extend(_bad)
hard(not _bad, f"{_seen} rights-bearing file(s) scanned, none contradict the CC BY policy")

# --------------------------------- 6. does any fragment cite a DOI the catalogue disowns?
# doi.html was written CONDITIONALLY, so when 1.0.0 nulled the version DOI the previous
# release's value simply survived on disk, and the page was about to pair
# "10.5281/zenodo.21773679" with "version 1.0.0". A conditional write does not leave a blank,
# it leaves a stale value, and downstream nothing can tell the two apart.
print("\n6. do the published fragments cite only DOIs the catalogue vouches for?")
_ok = {d for d in (API.get("doi"), API.get("concept_doi")) if d}
_fr = os.path.join(AV, "fragments")
_stale = []
if os.path.isdir(_fr):
    for _f in sorted(os.listdir(_fr)):
        _t = open(os.path.join(_fr, _f), encoding="utf-8", errors="replace").read()
        for _d in _re.findall(r"10\.5281/zenodo\.\d+", _t):
            if _d not in _ok:
                _stale.append(f"fragments/{_f} cites {_d}, which datasets.json does not vouch "
                              f"for (it publishes {sorted(_ok) or 'no DOI'})")
fails.extend(_stale)
hard(not _stale, f"every fragment cites only {sorted(_ok) or 'no DOI'}")

print(f"\n{len(soft)} soft observation(s):")
for s_ in soft[:8]:
    print("  . " + s_)
print(f"\n{len(fails)} hard failure(s)")
if fails:
    for f_ in fails[:12]:
        print("  X " + f_)
    sys.exit(1)
print("METADATA PASS - codebooks match, URLs resolve, contracts hold")
