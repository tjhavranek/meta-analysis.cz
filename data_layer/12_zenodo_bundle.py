"""Assemble the CURATED Zenodo deposit. Never deposit the repository wholesale.

A repo-wide deposit would place 173 author-copy PDFs (journal copyright, see LICENSE 2e)
and 23 third-party replication packages under a single CC BY record, permanently. This
bundle contains only material whose rights are the maintainers' to grant: the harmonised
table (a NEW compilation - the selection of literatures, the common schema, the column
mappings), the index, the codebooks and the documentation.

The 44 per-dataset mirrors are deliberately EXCLUDED: each is a format conversion of a
co-authored dataset, and LICENSE 2b says rights inherit from the source.
"""
import os, shutil, hashlib
HERE=os.path.dirname(os.path.abspath(__file__))
SITE=os.path.join(os.path.dirname(HERE),"site")
OUT=os.path.join(os.path.dirname(HERE),"zenodo_deposit","meta-analysis-cz-harmonised-v0.9.0-beta")
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
