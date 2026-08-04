"""Assemble the CURATED Zenodo deposit. Never deposit the repository wholesale.

Everything on the site is CC BY 4.0, so the exclusions below are about SIZE and
citability, not rights. A repo-wide deposit would be 422 MB and would bury the citable
artefact among 173 PDFs and 23 replication packages. This bundle is the harmonised table,
the index, the codebooks and the documentation: the part someone actually cites.

The 44 per-dataset mirrors are left out for the same reason. They remain on the site and
are covered by the same CC BY 4.0 grant.
"""
import os, shutil, hashlib
HERE=os.path.dirname(os.path.abspath(__file__))
# Build from the BUILT tree (data_layer/out), not from site/. Reading site/ made this script
# depend on 13_publish.py having run first, and on the release where CITATION.cff and README.md
# were corrected it silently packaged the PREVIOUS versions of both -- the zip went to the
# owner's desktop still describing 0.9.0-beta, twice. An ordering dependency nobody wrote down is
# a defect; out/ is always what the pipeline just produced.
SITE=os.path.join(HERE,"out")
if not os.path.isdir(SITE):
    raise SystemExit("data_layer/out is missing -- run 06/08/07/10 before building the deposit")
OUT=os.path.join(os.path.dirname(HERE),"zenodo_deposit","meta-analysis-cz-harmonised-v1.0.0")
ITEMS=[("data/v1/estimates_harmonised.csv","estimates_harmonised.csv"),
       ("data/v1/estimates_harmonised.parquet","estimates_harmonised.parquet"),
       ("api/v1/datasets.json","datasets.json"),
       ("api/v1/README.md","README.md"),
       ("LICENSE","LICENSE"), ("CITATION.cff","CITATION.cff")]
os.makedirs(os.path.join(OUT,"codebooks"),exist_ok=True)
man=[]
for src,dst in ITEMS:
    d=os.path.join(OUT,dst); shutil.copy2(os.path.join(SITE,src),d)
    man.append((dst,os.path.getsize(d),hashlib.sha256(open(d,"rb").read()).hexdigest()))
cb=os.path.join(SITE,"api","v1","codebooks")
for f in sorted(os.listdir(cb)):
    d=os.path.join(OUT,"codebooks",f); shutil.copy2(os.path.join(cb,f),d)
    man.append(("codebooks/"+f,os.path.getsize(d),hashlib.sha256(open(d,"rb").read()).hexdigest()))
with open(os.path.join(OUT,"SHA256SUMS.txt"),"w",encoding="utf-8",newline="\n") as fh:
    for n,_,h in man: fh.write(f"{h}  {n}\n")
print(f"bundle: {len(man)} files, {sum(s for _,s,_ in man)/1048576:.1f} MB -> {OUT}")

# GATE. This bundle is the thing that leaves the building and becomes immutable under a DOI, so
# it gets its own check rather than trusting whatever ran earlier. Twice in one day a deposit was
# built carrying documentation that described the PREVIOUS release: once because CITATION.cff and
# README.md are hand-written and nothing regenerates their numbers, once because this script read
# site/ before the corrected files had been published there. Assert against datasets.json.
import json as _json, re as _re
_api = _json.load(open(os.path.join(OUT, "datasets.json"), encoding="utf-8"))
_v = _api["harmonised_table"]["version"]
_st = _api["harmonised_table"].get("status")
_c = _api["counts"]
_bad = []
for _f, _wants in (
        ("README.md", [f"**{_v}**", f"{_c['estimates_in_harmonised_table']:,}",
                       f"{_c['literatures_in_harmonised_table']} literatures"]),
        ("CITATION.cff", [f'"{_v}"', f"{_c['estimates_in_harmonised_table']:,}",
                          f"{_c['estimates_in_analysis_samples']:,}",
                          str(_c['literatures_in_harmonised_table'])])):
    _t = open(os.path.join(OUT, _f), encoding="utf-8", errors="replace").read()
    for _w in _wants:
        if _w not in _t:
            _bad.append(f"{_f} does not state {_w!r}")
    if _st != "beta" and _re.search(r"\bis a beta\b", _t, _re.I):
        _bad.append(f"{_f} still calls the table a beta while status is {_st!r}")
if _bad:
    print("\nDEPOSIT NOT SAFE TO PUBLISH:")
    for _b in _bad:
        print("  X " + _b)
    raise SystemExit(1)
print(f"gate: README.md and CITATION.cff describe {_v} ({_st}), "
      f"{_c['estimates_in_harmonised_table']:,} rows, "
      f"{_c['literatures_in_harmonised_table']} literatures")
