# `/datasets/` — final copy, ready to place

For the redesign session. This is the **words**, matching the spec in
`DATA_PAGE_SPEC.md`. Layout, order on the page and visual weight are yours; the
generated fragments in `site/api/v1/fragments/` supply every number, so nothing
below hardcodes one.

Written in the site's register: plain, factual, no selling. Numbers appear as
`{{fragment_name}}` — substitute the fragment file of that name at build time.

---

## Title

> Datasets

## Opening (immediately under the title)

> This catalogue collects {{count_datasets}} estimate-level datasets from the
> empirical meta-analyses on this site, in standard formats, each with a
> machine-readable codebook and explicit rights information.
>
> The converted source files hold {{count_estimates}} rows, every one keeping the
> variables coded for its original paper. After each paper's own analysis filters,
> the catalogue below represents {{count_analysis}} estimates.

## The main offer — the most prominent thing on the page

> ### One file, every literature
>
> {{count_harmonised_estimates}} estimates from {{count_harmonised_literatures}}
> literatures in a single table, one row per estimate, with the effect, its
> standard error, the sample size, and the characteristics that recur across
> literatures.
>
> **[estimates_harmonised.csv](/data/v1/estimates_harmonised.csv)** ·
> [Parquet](/data/v1/estimates_harmonised.parquet)

Then the two-line example, in the monospace treatment already used by the
citation block:

```r
df <- read.csv("https://meta-analysis.cz/data/v1/estimates_harmonised.csv")
```

```python
df = pd.read_parquet("https://meta-analysis.cz/data/v1/estimates_harmonised.parquet")
```

## One caveat, close to the download and not buried

> Raw effect levels are not comparable across literatures. An elasticity, a partial
> correlation and a dollar value per tonne of carbon all sit in the same column;
> `effect_units` records which is which. Analyse within each literature. Comparing
> across them needs an explicitly standardised measure, and relative changes are
> meaningful only where the baseline is safely away from zero.

## A single beta line

> The harmonised table is version {{harmonised_version}}: {{count_harmonised_estimates}}
> estimates from {{count_harmonised_literatures}} literatures. Every row records the
> file and the columns it came from, so any value can be traced back to the published
> dataset and checked.
>
> **{{count_domain_reviewed}} of the {{count_harmonised_literatures}} pooled literatures
> have been checked against their paper's own replication code. The remaining
> {{count_pairing_only}} rest on arithmetic effect/standard-error matching alone and
> are provisional.** Every dataset publishes an `audit_status` saying which it is.

## The per-dataset route

> ### One literature at a time
>
> Each dataset is also published on its own, with all of the variables coded for
> its paper rather than the shared subset, and a codebook describing every column.

Then `{{datasets_table}}`.

## Not pooled

> Five datasets are published but stay out of the pooled table: **two** carry no
> per-estimate standard error, and **three** overlap with a dataset already
> included, which would otherwise be counted twice.

Then `{{not_pooled}}`.

## Machine-readable

> The whole collection is available as JSON: an
> [index of every dataset](/api/v1/datasets.json) with paper, DOI, file URLs and
> column roles, a [Frictionless data package](/api/v1/datapackage.json), and a
> [Croissant record](/api/v1/croissant.json). Full documentation is in the
> [API README](/api/v1/README.md).

## Licence and citation

> The index, the codebooks, the harmonisation and this documentation are released
> under [CC BY 4.0](/LICENSE): the datasets, their CSV and Parquet conversions, the
> pooled table, the codebooks, the documentation and the papers deposited here. Use
> any of it, including for training, provided you give credit.
>
> **Each dataset was assembled for a specific paper. When you use one, cite that
> paper.** The index carries every paper's title, authors and DOI. That is how
> attribution under CC BY is satisfied here.
>
> To cite the collection:
>
> Havránek, T. and Z. Iršová (2026). meta-analysis.cz: harmonised estimate-level
> data from meta-analyses in economics. Zenodo. https://doi.org/10.5281/zenodo.21773678

---

## Notes for whoever builds this

- **Order matters more than styling here.** A visitor arrives wanting data. The
  single-file download should be reachable without scrolling; the catalogue table
  is what they scroll to.
- The caveat about units is not boilerplate. A reader who pools an elasticity with
  a dollar value gets a confident wrong answer, so it belongs next to the download
  rather than in a footnote.
- "Nearly every paper collected here comes with its data and its estimation code"
  already appears on the homepage. Don't repeat it; link here instead.
- Nothing on this page needs JavaScript.
- Do not hand-write any count. Every number is a fragment, regenerated by
  `data_layer/10_fragments.py` whenever the data is rebuilt.
