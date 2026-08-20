# meta-analysis.cz data layer — v1.0.0

First release of the data layer: a licence, a machine-readable index, and every
dataset on the site published in standard formats with a column-level codebook.

Use this text for the GitHub release. Once the repository is linked to Zenodo, a
release tagged `data-v1.0.0` mints the DOI automatically.

## What is in it

**{{count_datasets}} datasets, {{count_estimates}} estimates.** Each one is the
estimate-level data assembled for a published meta-analysis, together with the
study and design characteristics hand-coded for that paper — between 17 and 407
variables per dataset.

Every dataset is published as **Parquet and CSV**, alongside a **codebook**
giving each column's type, missingness, distinct values and quartiles.

A **harmonised table** pools the literatures that share a common
effect-and-standard-error structure: {{count_harmonised_estimates}} estimates
from {{count_harmonised_literatures}} literatures in one file, one row per
estimate, with the moderators that recur across literatures. It is version
{{harmonised_version}}.

A **static JSON API** at `/api/v1/` indexes all of it: paper, DOI, file URLs,
row counts, which columns hold the effect and its standard error, what the
effect measures, and how each mapping was established. Also published as a
Frictionless data package and an MLCommons Croissant record.

## How the column mappings were established

Column names are unreliable across these files — matching on them selects a
t-statistic instead of the effect in one dataset, and a functional-form dummy in
another. The mappings were therefore resolved **arithmetically**: the correct
effect-and-standard-error pair is the one for which effect divided by standard
error reproduces the t-statistic the dataset already reports. That settled most
datasets outright.

Where it could not — no reported t-statistic, an asymmetric confidence interval,
a wide layout with one column per horizon, or an outcome that is itself a
t-statistic — the mapping was taken from **the paper's own published replication
code**, and the evidence is recorded per dataset in the index.

Applying each paper's own filters reproduces its published estimate count
exactly for several literatures, including the horizontal FDI spillovers (1,205)
and the house-price response (1,555).

## Known limits

- The harmonised table is a **beta**. Every row records the file and the columns
  it came from, so any value can be traced back and checked, but the pooling has
  not been reviewed literature by literature.
- **Effects are not comparable across literatures in raw units.** An elasticity,
  a partial correlation and a dollar value per tonne of carbon share one column;
  `effect_units` records which is which. Compare ratios, not levels.
- Several literatures are **heavy-tailed** — one runs from −10,000 to 100,000 in
  the source file. A raw mean, or an unwinsorised inverse-variance weight, gives
  nonsense. Winsorise or use medians, as the underlying papers do.
- Five datasets are published but stay out of the pooled table: three have no
  per-estimate standard error, and two are a second paper written on a dataset
  already included.

## Licence

The collection, index, codebooks and harmonised table are **CC BY 4.0**.

Each underlying dataset was assembled for a specific paper with its own authors
and co-authors. **If you use an individual dataset, cite its paper** — the index
carries every paper's title, authors and DOI.

Cite the collection as:

> Havranek, T. and Z. Irsova (2026). meta-analysis.cz: harmonised
> estimate-level data from meta-analyses in economics. Zenodo.
> https://doi.org/10.5281/zenodo.21773678

---

*Numbers marked `{{...}}` are read from `site/api/v1/fragments/` at release time
so this file cannot drift from the data.*
