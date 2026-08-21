"""Assemble the CURATED Zenodo deposit. Never deposit the repository wholesale.

Everything on the site is CC BY 4.0, so the exclusions below are about SIZE and
citability, not rights. A repo-wide deposit would be 422 MB and would bury the citable
artefact among 173 PDFs and 23 replication packages. This bundle is the harmonised table,
the index, the codebooks and the documentation: the part someone actually cites.

The per-dataset mirrors are left out for the same reason. They remain on the site and
are covered by the same CC BY 4.0 grant.
"""
import os, shutil, hashlib, json, re
HERE=os.path.dirname(os.path.abspath(__file__))
# Build from the BUILT tree (data_layer/out), not from site/. Reading site/ made this script
# depend on 13_publish.py having run first, and on the release where CITATION.cff and README.md
# were corrected it silently packaged the PREVIOUS versions of both -- the zip went to the
# owner's desktop still describing 0.9.0-beta, twice. An ordering dependency nobody wrote down is
# a defect; out/ is always what the pipeline just produced.
SITE=os.path.join(HERE,"out")
if not os.path.isdir(SITE):
    raise SystemExit("data_layer/out is missing -- run 06/08/07/10 before building the deposit")
# The version comes from the build, never from a literal. Hardcoded "v1.0.0" meant a correct
# 1.1.0 bundle was written into a folder claiming 1.0.0 -- and, worse, ON TOP of the maintainer's
# archival copy of what was actually deposited at 1.0.0. 96_metadata.py derives the same version for its own deposit scan, so the two stay in step
# without a hardcoded literal in either.
VER=json.load(open(os.path.join(SITE,"api","v1","datasets.json"),
                   encoding="utf-8"))["harmonised_table"]["version"]
if not re.fullmatch(r"[0-9A-Za-z.\-]+", VER):   # VER reaches rmtree; never let it traverse
    raise SystemExit(f"refusing to build: implausible version {VER!r}")
OUT=os.path.join(os.path.dirname(HERE),"zenodo_deposit",
                 f"meta-analysis-cz-harmonised-v{VER}")
if os.path.isdir(OUT):
    # Never merge into a previous bundle. A file dropped from the release survives on disk,
    # is absent from SHA256SUMS.txt, and gets uploaded as an unmanifested extra.
    shutil.rmtree(OUT)
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
# Every file in the folder must appear in the manifest exactly once, and every manifest entry
# must exist. The upload is a drag of the folder's CONTENTS, so anything on disk ships whether
# or not it is listed -- an unmanifested file is an undeclared file in an immutable deposit.
_disk={os.path.relpath(os.path.join(dp,f),OUT).replace(os.sep,"/")
       for dp,_,fs in os.walk(OUT) for f in fs}-{"SHA256SUMS.txt"}
_man={n for n,_,_ in man}
if _disk!=_man:
    raise SystemExit(f"bundle/manifest mismatch: on disk but unmanifested {sorted(_disk-_man)}; "
                     f"manifested but missing {sorted(_man-_disk)}")

print(f"bundle: {len(man)} manifested payload files plus SHA256SUMS.txt, "
      f"{sum(s for _,s,_ in man)/1048576:.1f} MB -> {OUT}")

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
