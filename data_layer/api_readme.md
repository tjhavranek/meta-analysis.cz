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
| `/estimates.csv` | One headline result per paper — the table behind `/results/`, with its caveat and citation |

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

**Read the Parquet where you can, and pass `float_precision="round_trip"` where you
cannot.** The CSV is not the problem: it carries every value at full precision and
round-trips exactly. Pandas' default CSV parser is the problem, and it is not exact. It
moves 17,310 of the 49,669 `se` values, 10,026 `effect` values and 9,213 `t_stat` values,
each by up to about 1.5e-11. So this applies to any column you read, not only the derived
ones, and recomputing `effect / se` yourself does not avoid it.

That is invisible almost everywhere and decisive at a threshold. 96 estimates sit within
1e-9 of |t| = 1.96 and 26 sit exactly on it, so any count either side of that line has to
state its convention: bins here are closed on the left, and an estimate reported as
exactly 1.96 is counted above. On that convention the caliper comes out as 508 below and
633 above
from the Parquet, 503 and 639 from the same CSV at pandas' defaults, and 506 and 634 if
you recompute the ratio from a default-parsed CSV. The figures published on this site
quote the Parquet. Writing the CSV with more digits does not help; it makes the default
parse worse. The Parquet is canonical. Read the CSV as:

```python
pd.read_csv("https://meta-analysis.cz/data/v1/estimates_harmonised.csv",
            float_precision="round_trip")
```

```bash
curl -s https://meta-analysis.cz/api/v1/datasets.json | jq '.datasets[] | {id, n_estimates}'
```

## The harmonised table

One row per harmonised **observation**, pooled across literatures: **49,669 rows
from 41 literatures**. Rows are not always independent estimates — `price_puzzle`
carries one row per impulse response per horizon (the five month horizons plus
the trough, coded 99, and the peak, coded 88), and `house_prices` ships about
seven horizons per impulse response. Check `horizon` before treating rows as
independent. Version **1.1.1**.

1.1.0 added `finance_growth`, taking the table to 41 literatures, and 1.1.1
removed 20 `price_puzzle` rows that corresponded to no source estimate, leaving
49,669.

Core columns are present for every row: `dataset`, `study_id`, `estimate_id`,
`effect`, `se`, `t_stat`, `precision`. The rest are harmonised moderators, and
they are populated only where the source dataset recorded them — coverage per
column runs from about 90% (`n_obs`) down to under 20% for the more specialised
ones. Check for nulls rather than assuming.

`precision` is exactly `1 / se`. It is provided because most meta-analysis
software expects it, not as independent information — it carries nothing `se`
does not, and weighting by both would double-count.

Provenance travels with every row. `source_file`, `effect_col` and `se_col` name
the file and the exact columns each value came from, so any number can be traced
back to the published dataset and checked. `se_is_derived` marks rows whose
standard error was reconstructed rather than read directly (from a reported
t-statistic, or as the mean of an asymmetric confidence interval).

**Raw effect levels are not comparable across literatures.** An elasticity, a
partial correlation and a dollar value per tonne of carbon all live in the
`effect` column; `effect_units` tells you which is which. Within a literature the
units are *usually* consistent, which is what estimator comparisons need. Do not
assume it. In several literatures the source papers themselves mix scales: in
`size`, `trust`, `habits` and `eis` the per-study median absolute effect spans
four to seven orders of magnitude, which no real heterogeneity produces and which
a percent-versus-decimal split does. `activism` carries a direction note recording
exactly that, reconstructed; the others do not, and are not yet resolved.

The practical consequence is sharp, because it survives the remedy this page
recommends. On `habits` a precision-weighted mean after 1st–99th winsorising
returns about 0.001 for a literature whose median estimate is 0.47. **Check the
per-study spread of `effect` before pooling a literature**, and treat a span of
more than about two orders of magnitude as a scale problem rather than as
heterogeneity. Comparing across literatures needs an explicitly standardised
measure — and ratios are unsuitable where the denominator may sit near zero or
change sign.

The harmonisation may still be revised. For a reference that does not move, cite
the archived deposit:

> **https://doi.org/10.5281/zenodo.21773678** — cite this. It always resolves to the newest version.
>
> **https://doi.org/10.5281/zenodo.22050272** — version 1.1.1 specifically, which is this
> release. Cite this in a replication package, where the exact files matter.
>
> `https://doi.org/10.5281/zenodo.21789702` is version 1.0.0, superseded by 1.1.1, which
> removes 20 `price_puzzle` rows that corresponded to no source estimate.
>
> `https://doi.org/10.5281/zenodo.21773679` is version 0.9.0-beta, superseded; do not start
> new work from it.

The deposit is immutable: it holds that version's harmonised table, index,
codebooks and documentation, with checksums. The live files here may change; the
DOI will not.

## Before you pool

**Cluster on `(dataset, study_id)`, never on `study_id` alone.** `study_id` is unique within
a literature, not across the table. There are 524 distinct values but 2,963 real
literature-study pairs, so clustering on the bare column silently merges unrelated studies
and collapses 82% of your clusters, from 2,963 to 524. And if you deduplicate, do it
on `(dataset, estimate_id)`, which is unique by construction: rows elsewhere can legitimately
agree in every other column, so a blanket `drop_duplicates()` deletes real estimates. On a pooled regression the standard
errors happen to come out within 1% of the correct ones, so nothing looks wrong; the damage is
to the cluster count that cluster-robust inference depends on, and to any literature-level
statistic where the merged studies are genuinely unrelated.

These are real published estimates, and several literatures are heavy-tailed.
The `eis` file, for instance, runs from −10,000 to 100,000 with standard errors
to match; 68 rows across the collection have a standard error below 1e-4. Those
values are in the source files, not an artefact of the harmonisation, and they
are kept so the table stays faithful to what was published.

The practical consequence: a raw mean is meaningless on some literatures, and an
inverse-variance weight of 1/se² lets a handful of near-zero standard errors
dominate everything else. Winsorise, or work with medians, before pooling —
which is what the underlying papers do. As a worked check, FAT-PET run on the
1st–99th percentile winsorised data reproduces the published conclusions:
`education` corrects to about 0.02 and `excess_sensitivity` to about 0.01, both
of which their papers describe as near zero, and `forward` corrects to 0.92
against a null of 1. On the same winsorised data, with standard errors clustered
by study, the FAT publication-bias intercept lies beyond ±1.96 in 24 of the 41
literatures.

**All 41 pooled literatures are verified** — 21 `domain_reviewed`, 20 `code_traced`. Where a
paper ships no replication code, the mapping was checked against its published results by
hand: `gasoline_price`'s abstract reports corrected elasticities of -0.31 long-run and -0.09
short-run with published averages "exaggerated twofold", and the shipped data gives -0.691 and
-0.227, reproducing that; `finance_growth`'s shipped column reproduces its paper's Table 1
exactly — 67 studies, 1,334 estimates, median 0.14, mean 0.15, random-effects 0.14 with a
matching confidence interval.

Per-column minimum, maximum, median and quartiles for every dataset are in its
codebook, so you can see the tails before you load anything.

One more thing worth knowing if you use `n_obs` as an instrument, as MAIVE does:
two source files store the sample size as its logarithm rather than as a count.
`n_obs` here is always a count — a log column is either replaced by the raw one
from the same file or exponentiated, and `datasets.json` records where that
happened. Check `effect_units` and the direction notes too: a few literatures
store proportions where the paper reports percentages, and `migrant` stores a
**negative inverse** elasticity — take -1/effect to recover the elasticity, and
convert its standard error by the delta method rather than using the stored one.
`skill` is suspected of a similar inversion but it is **not confirmed**, so its
units are left as `elasticity`; that open question is recorded in `units.json`.

## Known defects in this release

**75 `class` estimates are invalid as partial correlations**: 2 lie outside `[-1, 1]`, to
|1.372|, and 73 sit at exactly ±1 beside a positive standard error. They are in the source
file, 72 of them in one study, and publication-bias tests on this literature are sensitive to
them: an unweighted regression of `effect` on `se` moves sharply when they are excluded, while
the precision-weighted form does not. A further 82 rows of the per-dataset `class` file store a
partial correlation of exactly zero beside a non-zero t-statistic; those do not enter the
pooled table. Everything is kept as published; correction is scheduled for the next data
revision. Until then, filter on `abs(effect) < 1` where you need strictly valid correlations.


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

### What a "literature" means here, and what is only name-harmonised

**Dataset IDs are not literature families.** The catalogue counts *contributing dataset
IDs*. Two of them describe the same literature: `trust` is a later, separate collection of
the size-premium literature that `size` also covers, which is why only the 284 estimates
`size` does not already carry are pooled. So "41 literatures" means 41 contributing dataset
IDs, not 41 independent bodies of evidence: `trust` and `size` cover the same size-premium
literature, so the 41 IDs represent at most 40 literature families. Treat those two as one
family in any analysis that assumes independence.

**Several pooled columns are literature-local.** `study_id` and `estimate_id` are unique
within a dataset, not across the table; a study appearing in two literatures carries two
different ids, and nothing here links them. Several moderators share a column name across
literatures while their source definitions differ — the name was harmonised, the definition
was not. Where the definition matters, read the per-dataset codebook rather than assuming
the column means the same thing everywhere. `effect`, `se`, `t_stat` and `precision` are
the columns harmonised by definition and arithmetic, not merely by name.

### A caveat on `citations`

`citations` is **not on one scale across literatures.** It is passed through from each
paper's own coding, and the papers did not agree:

- most literatures carry a raw count (`size` reaches 15,628);
- nine carry a log, with maxima between 4 and 10;
- `students` carries a standardised regressor, which is why 26 of its values are negative.

Nothing in the harmonisation reconciles these, and the column name does not distinguish
them, so **do not pool, rank, or regress on `citations` across literatures** without first
checking the scale within each. The next data revision nulls the
non-count literatures rather than silently rescaling them. `impact_factor` shows a
weaker version of the same signature and is under review.

- **`trust`** — from 1.0.0 this is **pooled**, but only for the 284 estimates
  `size` does not already carry. It is the later collection (2026 against 2019)
  of the same literature, the size premium, and the *smaller* one at 1,613 rows
  against `size`'s 1,746; of those 1,613 rows, 1,329 (82.4%) already appear in
  `size` and are dropped here so nothing is counted twice, leaving the 284 above. That makes this literature a
  deliberate splice of two separately-assembled collections. **If the size
  premium is your subject, use either per-dataset file whole** rather than the
  pooled rows.

`price_puzzle` and `lags` share a source *file* but use different columns of it,
so both are kept. So are `bma` and `spillovers`, which take the horizontal and
vertical halves of one FDI database.

These overlaps were found by comparing the (effect, standard error) value sets
of every pair of literatures. That check now runs on every build: a complete
overlap fails outright, and a partial one fails too unless it has been ruled on
explicitly.

## Column resolution

Which column holds the effect, and which its standard error, was resolved
arithmetically rather than by column name: the correct pair is the one where
`effect / se` reproduces the t-statistic the dataset already reports. That test
settles most datasets outright. Where it could not — no t-statistic column, an
asymmetric confidence interval, a wide layout, an outcome that is itself a
t-statistic — the mapping was taken from the paper's own published replication
code or other documented evidence, and `verified_by` in the harmonisation report
records which file and which line of reasoning settled it.

## Two products, not one

**The archive is a faithful mirror. The harmonised table is an interpretation.**
They are separate things and should be trusted differently. All 41 literatures'
mappings are verified, but the table still involves judgement the archive does
not.

*Archive* — the original files, faithful CSV and Parquet mirrors, codebooks, and
paper/DOI metadata. Faithful conversions of what was published.

*Harmonised table* — 49,669 selected estimates, automatically mapped and in some
cases transformed. Every column mapping is verified against the paper's own
replication code or published results.

Every dataset carries an `audit_status` so you can filter on review quality
rather than read prose:

| status | meaning | count |
|---|---|---|
| `domain_reviewed` | checked by hand against the paper's own replication code, or against its published results where no code exists | 21 of 41 pooled |
| `code_traced` | mapping confirmed by reading the paper's code and comparing the variables it regresses | 20 of 41 pooled |
| `duplicate_excluded` | same estimates as another literature | 2 |
| `excluded_no_precision` | no per-estimate standard error exists | 2 |

The arithmetic test proves that two columns form a statistical pair. It cannot
distinguish a headline estimand from a robustness one, a short-run from a
long-run effect, or a baseline sample from a filtered one; `audit_status` records
which further check settled each literature.

## `/estimates.csv`, and why the headline is prose

One row per paper, fifteen columns. `project` joins to `datasets.json.id`, and
`source_quote` carries the verbatim sentence from the paper that the figure came
from, so every number can be traced to the words that state it.

**`headline` is prose on purpose, and only one of the fifty-four rows is a bare
number.** The others are ranges, qualitative statements, or clauses that carry
their own conditions -- a percentage change per one-percentage-point rise,
peaking after two years. Reducing those to a single numeric column would drop the
conditions and read as authoritative, and the ranges are not even the same kind
of object: one is a 95% credible interval, another a range across
specifications, another a range of corrected means. A file named
`estimates.csv`, on a site about publication bias, is exactly where an invented
midpoint would be quoted back as the result.

Three columns are derived mechanically and are safe to parse:

| column | what it is |
|---|---|
| `question` | the question the paper answers, the same string `/results/` marks up as a schema.org `Question` |
| `basis_n_estimates` | the estimate count stated in `basis`, or empty |
| `basis_n_studies` | the study count stated in `basis`, or empty |

They are named for `basis` because that is what they read. **They are not the
dataset's row counts** and will not always match `datasets.json`: `basis` states
what the paper's headline rests on, `n_estimates` counts rows in the published
file, and the two differ wherever the paper's headline uses a subset. Both are
empty wherever `basis` does not state the number unambiguously -- an approximate
count, or a unit that is not a study, such as a meta-analysis or an experiment.

## Licence

**Everything here is CC BY 4.0.** The datasets, their CSV and Parquet conversions,
the harmonised table, the index, the codebooks, this documentation and the papers
themselves.

You may use, adapt and redistribute any of it, for any purpose, including
commercially and **including as training data for machine-learning models**. You
do not need to ask. Every dataset in `datasets.json` carries
`rights_status: cc-by-4.0` and a `license_url`, so nothing here requires a
judgement call.

The only condition is credit. **If you use an individual dataset, cite its paper**
— `datasets.json` carries the title, authors and DOI of each one, so you do not
have to look it up. If you use the collection, cite that too. See `/LICENSE`.

Cite the collection as:

> Havranek, T. and Z. Irsova (2026). meta-analysis.cz: harmonised
> estimate-level data from meta-analyses in economics. Zenodo.
> https://doi.org/10.5281/zenodo.21773678
