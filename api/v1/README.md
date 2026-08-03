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

One row per estimate, pooled across literatures: **56,466 estimates from 39 literatures**. Version **0.9.0-beta**.

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
against a null of 1. Sixteen of the 39 literatures show a
publication-bias intercept beyond ±1.96.

Per-column minimum, maximum, median and quartiles for every dataset are in its
codebook, so you can see the tails before you load anything.

One more thing worth knowing if you use `n_obs` as an instrument, as MAIVE does:
two source files store the sample size as its logarithm rather than as a count.
`n_obs` here is always a count — a log column is either replaced by the raw one
from the same file or exponentiated, and `datasets.json` records where that
happened. Check `effect_units` and the direction notes too: a few literatures
store proportions where the paper reports percentages, and two store inverse
elasticities, where dropping the inversion reverses the finding.

## What is not in the harmonised table, and why

Every dataset on the site is published. Some cannot join a pooled
effect/standard-error table, and the reason is recorded for each in
`datasets.json`.

**No per-estimate precision exists:**

- **`fdi`** — no standard error, t-statistic or weight anywhere in the file.
  Model averaging over its moderators still works; that is what the paper does.
- **`lags`** — its outcome is a transmission lag in months, which has no
  sampling standard error.
- **`ews`**, **`pcc`** — a country-level crisis database and a literature search
  listing. Neither is a set of extracted estimates.

**Two papers written on one dataset.** Keeping both would count the same
estimates twice and present one literature as two independent ones:

- **`hedge`** — the same 1,019 estimates as `alphas`, identical row by row.
  `alphas` is pooled; cite the published *Journal of Economic Surveys* 2024
  version for these estimates.
- **`substitution`** — the same 2,735 estimates as `eis`. Two papers, one
  dataset. It carries additional country-level moderators and is published in
  full.
- **`trust`** — shares 1,256 estimates with `size`. Not an exact duplicate:
  `trust` is a later, larger collection (105 studies) of the same literature,
  the size premium, that `size` (98 studies) first assembled. `size` is pooled
  because it carries far more of the shared moderators, but **if the size
  premium is your subject, use `trust`** — it is the more recent and more
  complete collection.

`price_puzzle` and `lags` share a source *file* but use different columns of it,
so both are kept. So are `bma` and `spillovers`, which take the horizontal and
vertical halves of one FDI database.

These overlaps were found by comparing the (effect, standard error) value sets
of every pair of literatures. That check now runs on every build: a complete
overlap fails outright, and a partial one fails too unless it has been ruled on
explicitly. Row counts, t-statistics and reconciliation against the papers all
looked entirely normal while the duplicates were present, which is why the
check exists.

## Column resolution

Which column holds the effect, and which its standard error, was resolved
arithmetically rather than by column name: the correct pair is the one where
`effect / se` reproduces the t-statistic the dataset already reports. That test
settles most datasets outright. Where it could not — no t-statistic column, an
asymmetric confidence interval, a wide layout, an outcome that is itself a
t-statistic — the mapping was taken from the paper's own published replication
code, and `verified_by` in the harmonisation report records which file and which
line of reasoning settled it.

## Two products, not one

**The archive is stable. The harmonised table is a beta.** They are separate
things and should be trusted differently.

*Archive* — the original files, faithful CSV and Parquet mirrors, codebooks, and
paper/DOI metadata. Faithful conversions of what was published.

*Harmonised table* — 54,087 selected estimates, automatically mapped and in some
cases transformed, with **varying levels of review** and no independent
end-to-end reproduction.

Every dataset carries an `audit_status` so you can filter on review quality
rather than read prose:

| status | meaning | count |
|---|---|---|
| `domain_reviewed` | checked against the paper's own replication code | 19 of 39 pooled |
| `arithmetic_pairing_only` | effect/se pair proven by reproducing the reported t-statistic, estimand **not** independently confirmed | 20 of 39 pooled |
| `duplicate_excluded` | same estimates as another literature | 3 |
| `excluded_no_precision` | no per-estimate standard error exists | 2 |

The arithmetic test proves that two columns form a statistical pair. It cannot
distinguish a headline estimand from a robustness one, a short-run from a
long-run effect, or a baseline sample from a filtered one. Four of the errors
found so far were exactly that kind, which is why the status is published rather
than assumed away.

## Licence

**CC BY 4.0 covers the compilation** — this API, the codebooks, the harmonisation
mappings and the documentation. **It does not cover the underlying research
datasets, their format conversions, or the papers' own replication code**, none
of which are ours to license: those datasets were assembled by author teams that
mostly extend beyond this site's maintainers.

Each dataset carries a `rights_status`. Where it reads `unspecified`, no open
licence has been established — treat the data as all rights reserved unless the
paper or its publisher says otherwise. Attribution is not the same as permission.

**If you use an individual dataset, cite its paper** — `datasets.json` carries the
title, authors and DOI of each one. See `/LICENSE` for the full scoping.

Cite the collection as:

> Havránek, T. and Z. Iršová (2026). meta-analysis.cz: data and code for
> meta-analyses in economics. https://meta-analysis.cz
