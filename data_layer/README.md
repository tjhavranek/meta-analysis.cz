# The pipeline that builds the data layer

Everything under `/api/v1/` and `/data/v1/` is generated from the papers' own published
files by the scripts here. This directory exists so the release can be **reproduced and
audited**, not merely trusted: an earlier version licensed this pipeline in `LICENSE` §1a
and referenced it from `.zenodo.json` without actually publishing it.

Run in order. `09_verify.py` is the gate and must print `ALL CHECKS PASS`.

**Pin the toolchain first: `pip install -r data_layer/requirements-pinned.txt`.** pandas and pyarrow both write their versions into every Parquet file, so an unpinned rebuild changes all 44 dataset checksums without changing any data.

| | |
|---|---|
| `01_inventory.py` | find every tabular file, including inside zips |
| `02_classify.py` | pick each project's primary table, guess its columns |
| `05_resolve2.py` | resolve (effect, standard error) **arithmetically** — the correct pair is the one where `effect/se` reproduces the dataset's own reported t-statistic |
| `06_convert.py` | Parquet + CSV mirrors, column-level codebooks |
| `08_harmonise.py` | the pooled table |
| `07_api.py` | `datasets.json`, datapackage, Croissant |
| `10_fragments.py` | generated HTML fragments for `/datasets/` |
| `12_zenodo_bundle.py` | assemble the curated Zenodo deposit |
| `09_verify.py` | **the gate** |

`overrides.json` is the important file to read. Column names in these datasets are
unreliable — matching on them selects a t-statistic instead of the effect in one dataset and
a functional-form dummy in another. Where the arithmetic test was not decisive, the mapping
comes from the paper's own replication code, and every such decision is recorded there under
`verified_by` with the evidence that settled it.

`units.json` records what each literature's effect measures and, where the sign convention
can be misread, a `direction_note`. Several are load-bearing: `dst` stores the impact on
consumption, so negative means savings; `skill` and `migrant` store inverse elasticities.

Not published here: `out/` (a byte-identical duplicate of `/api/v1/` and `/data/v1/`) and
`staging/` (scratch).

Licence: MIT, per `LICENSE` §1a. That covers these scripts. It does **not** cover the
research datasets they read.
