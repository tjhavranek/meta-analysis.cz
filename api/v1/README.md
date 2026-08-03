# meta-analysis.cz data API — v1

Static JSON and tabular files at stable URLs. There is no server: every endpoint
is a file, served over HTTPS with CORS enabled, so you can fetch it from a
browser, a script, or a notebook without a key, a quota, or a login.

Base: `https://meta-analysis.cz`

## Endpoints

| URL | What it is |
|---|---|
| `/api/v1/datasets.json` | Index of every dataset: paper, DOI, file URLs, row counts, which columns hold the effect and its standard error |
| `/api/v1/codebooks/{id}.json` | Every column of one dataset: type, missingness, distinct values, summary statistics, inferred role |
| `/api/v1/datapackage.json` | The same collection as a [Frictionless](https://frictionlessdata.io) tabular data package |
| `/api/v1/croissant.json` | [MLCommons Croissant](http://mlcommons.org/croissant/) record, for ML dataset tooling |
| `/data/v1/{id}/{id}.parquet` | One dataset, all original columns, original column names |
| `/data/v1/{id}/{id}.csv` | The same, as CSV (published for datasets under 4 MB) |
| `/data/v1/estimates_harmonised.parquet` | All literatures pooled into one estimate-level table |
| `/data/v1/estimates_harmonised.csv` | The same, as CSV |

## Quick start

```python
import pandas as pd

# every estimate from every literature, in one table
df = pd.read_parquet("https://meta-analysis.cz/data/v1/estimates_harmonised.parquet")
df.groupby("dataset")["t_stat"].median()

# or one literature at a time, with all of its hand-coded moderators
cls = pd.read_parquet("https://meta-analysis.cz/data/v1/class/class.parquet")
```

```r
# R
inst <- arrow::read_parquet("https://meta-analysis.cz/data/v1/estimates_harmonised.parquet")
# or, without arrow:
inst <- read.csv("https://meta-analysis.cz/data/v1/estimates_harmonised.csv")
```

```bash
curl -s https://meta-analysis.cz/api/v1/datasets.json | jq '.datasets[] | {id, n_estimates}'
```

## The harmonised table

One row per estimate, pooled across literatures. Version **0.9.0-beta**.

Core columns are present for every row: `dataset`, `study_id`, `estimate_id`,
`effect`, `se`, `t_stat`, `precision`. The rest are harmonised moderators, and
they are populated only where the source dataset recorded them — coverage per
column runs from about 90% (`n_obs`) down to under 20% for the more specialised
ones. Check for nulls rather than assuming.

Provenance travels with every row. `source_file`, `effect_col` and `se_col` name
the file and the exact columns each value came from, so any number can be traced
back to the published dataset and checked. `se_is_derived` marks rows whose
standard error was reconstructed rather than read directly (from a reported
t-statistic, or as the mean of an asymmetric confidence interval).

**Effects are not comparable across literatures in raw units.** An elasticity, a
partial correlation and a dollar value per tonne of carbon all live in the
`effect` column. `effect_units` tells you which is which. Within a literature the
units are consistent, which is what estimator comparisons need; across
literatures, compare ratios — corrected against uncorrected — not levels.

Being a beta, the harmonisation may be revised. Pin the version if you need
stability: the released files are also deposited with a DOI, and that deposit
does not move.

## Before you pool

These are real published estimates, and several literatures are heavy-tailed.
The `eis` file, for instance, runs from −10,000 to 100,000 with standard errors
to match; 72 rows across the collection have a standard error below 1e-4. Those
values are in the source files, not an artefact of the harmonisation, and they
are kept so the table stays faithful to what was published.

The practical consequence: a raw mean is meaningless on some literatures, and an
inverse-variance weight of 1/se² lets a handful of near-zero standard errors
dominate everything else. Winsorise, or work with medians, before pooling —
which is what the underlying papers do. As a worked check, FAT-PET run on the
1st–99th percentile winsorised data reproduces the published conclusions:
`education` corrects to about 0.02 and `excess_sensitivity` to about 0.01, both
of which their papers describe as near zero, and `forward` corrects to 0.92
against a null of 1. Sixteen of the 41 literatures show a
publication-bias intercept beyond ±1.96.

Per-column minimum, maximum, median and quartiles for every dataset are in its
codebook, so you can see the tails before you load anything.

## What is not in the harmonised table, and why

Four literatures on the site are published as datasets but cannot join an
effect/standard-error table. The reasons are recorded in `datasets.json` and in
the harmonisation report:

- **`fdi`** — the file carries no standard error, t-statistic or weight, so no
  per-estimate precision exists. Model averaging over its moderators still works;
  that is what the original paper does.
- **`lags`** — its outcome is a transmission lag in months, which has no sampling
  standard error.
- **`ews`**, **`pcc`** — a country-level crisis database and a literature search
  listing. Neither is a set of extracted estimates.

Two further projects (`spillovers`, `substitution`) share their underlying data
with another project and are excluded to avoid double counting. `price_puzzle`
shares a source *file* with `lags` but uses different columns, so both are kept.

## Column resolution

Which column holds the effect, and which its standard error, was resolved
arithmetically rather than by column name: the correct pair is the one where
`effect / se` reproduces the t-statistic the dataset already reports. That test
settles most datasets outright. Where it could not — no t-statistic column, an
asymmetric confidence interval, a wide layout, an outcome that is itself a
t-statistic — the mapping was taken from the paper's own published replication
code, and `verified_by` in the harmonisation report records which file and which
line of reasoning settled it.

## Licence

The collection, this API, the codebooks and the harmonised table are
**CC BY 4.0**. See `/LICENSE`.

Each underlying dataset was assembled for a specific paper with its own authors.
**If you use an individual dataset, cite its paper** — `datasets.json` carries the
title, authors and DOI of each one for exactly that purpose.

Cite the collection as:

> Havránek, T. and Z. Iršová (2026). meta-analysis.cz: data and code for
> meta-analyses in economics. https://meta-analysis.cz
