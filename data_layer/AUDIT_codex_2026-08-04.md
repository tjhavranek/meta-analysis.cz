## Gaps

| Rank | Defect class that can still pass 90--97 | Check that is missing | Rough cost |
|---:|---|---|---|
| 1 | **Wrong estimand on a faithfully copied pair.** A coefficient can reproduce the source `t`, be named in code, and still be the wrong target for synthesis (mixed dependent variables, inverse elasticities, different horizons, null other than zero). `effect_units` records dimensional units, not the estimand, transformation, outcome, horizon, sign convention, or null. | For every literature, trace the paper's headline estimating equation through all generated variables and record machine-readable `estimand`, `transform_to_headline`, `null_value`, outcome and horizon. Numerically reproduce at least one headline estimate after the transform. | High: about 1--3 expert hours per literature, roughly 1--2 expert-weeks for 39.
| 2 | **Wrong multiplicity or reshape.** Set membership can be perfect even if every legitimate row is repeated, rows are dropped, or a wide record is melted more than once. | Give each source record a stable `source_row_id` (and IRF/specification ID where needed); compare source-to-output as a multiset with expected expansion factors. Assert row counts and multiplicities, not sets of values. | Low-medium: 1 day for the framework, then 15--60 minutes per nontrivial reshape.
| 3 | **Moderator semantics and scale.** Regex first-match treats raw counts, logs, rates, standardised regressors, recursive impact factors, `top3`/`top5`, and `MLE`/`Bayes` as if each were one harmonised concept. All effect/SE checks can pass while MAIVE or meta-regression uses the wrong covariate. | Carry `*_source_col`, transformation and units for every harmonised moderator. Add value and relational gates (count/integer, year, `df < N`, nonnegative citations, one-hot logic) and compare moderator definitions with codebooks. | Medium-high: 2--4 engineering days plus domain review of ambiguous columns.
| 4 | **Dependence and study-level leverage.** The suite checks the largest row weight, but not the aggregate weight of a study, repeated IRF, sample, country, or author. A hundred individually innocuous rows from one study can be the whole estimator. | Report top-cluster weight, effective number of estimates and studies, leave-one-study-out estimates, and leverage by every available nesting key. Require an IRF/specification key for repeated-horizon data. | Low for diagnostics (<1 day); medium to repair missing dependence keys.
| 5 | **Analysis-sample selection.** A reproduced column pair does not show that the right outcomes, horizons, studies, outlier rule, missing-SE treatment or winsorisation policy were selected. Missing precision can make the benchmark a nonrandom subset of the paper. | Reproduce every paper's final `N estimates / N studies` by named exclusion step; compare included and excluded rows on effect, significance, year and study. Flag raw, winsorised, imputed and derived inputs explicitly. | Medium-high: 1--2 hours per literature with code; longer where the analysis file is unpublished.
| 6 | **Estimator validity rather than mere finiteness.** A finite PET/PEESE number can come from a rank-deficient or one-row design. The battery does not run MAIVE, RoBMA, clustered inference, or the actual production implementations the table benchmarks. | Run the production estimators, record rank/condition number and row/study leverage, and rerun after dropping the top row/study, trimming SE, deduplicating, and applying the paper's transformation. Compare coefficients and uncertainty, not just `isfinite`. | Medium: 2--5 days including R dependencies and golden outputs.
| 7 | **Cross-literature identity.** Matching `(effect,se)` cannot find the same primary paper re-entering with a differently transformed estimate; bare `study_id` is not global. Numeric non-overlap therefore does not establish independent literatures. | Create `literature_study_id` and a canonical primary-study key from DOI/title/authors/year; measure overlap on that key and document deliberately shared study universes. | Medium: 2--4 days plus manual resolution of fuzzy matches.
| 8 | **Upstream values that are faithfully invalid.** “Verbatim upstream” establishes provenance, not usability. Boundary PCCs with positive SE, sentinel values, impossible date order and rounded-zero SEs can break transformations or dominate weights. | Apply definitional and cross-column constraints; quarantine rather than silently pass invalid upstream rows, while retaining raw values and a reason flag. | Low: <1 day for generic gates, then manual adjudication of a small exception list.
| 9 | **Release equality outside the three core numbers.** A moderator, cluster ID, unit or provenance field can drift between CSV/parquet/site/Zenodo without failing check 91. | Hash canonicalised values for all 41 columns, with explicit float/string/null rules. Validate the complete Frictionless/Croissant schema and counts, not selected fields. | Low: a few hours.

## Defects found

### 1. `price_puzzle` is duplicated exactly sevenfold

Grouping its 7,420 rows by `(study_id, horizon, effect, se)` produces only **1,060 groups**, and **every one of the 1,060 has multiplicity exactly 7**. The same result holds after adding every published moderator to the key. The source catalogue count is 1,519, itself `217 * 7`; the five requested horizons contain 208, 215, 215, 217 and 205 unique records, totaling 1,060. This is the signature of melting wide horizon columns once for each of seven already-repeated source rows.

The correct selected-horizon row count is therefore 1,060, not 7,420. Removing the 6,360 extra copies would reduce the pooled table from 54,076 to **47,716** rows. `price_puzzle` currently supplies 13.72% of all rows; after correction it would supply 2.22%. Uniform sevenfold replication leaves simple point estimates unchanged, which helps this escape a coefficient battery, but it overstates an iid information count by 7 and understates an iid SE by `sqrt(7) = 2.646`; it also changes Bayesian model evidence and any estimator or benchmark score that treats rows as observations.

Computation: `groupby(['study_id','horizon','effect','se']).size()` had distribution `{7: 1060}`; no group had any other size.

### 2. `remittances.n_obs` is a row ordinal, not sample size

All **490/490** values are unique, strictly increasing, and span 1--538 with gaps; correlation with the regenerated `estimate_id` is **0.999702**. In the 490 rows that also have `df`, degrees of freedom exceed `n_obs` in **188 rows (38.4%)**, which is incompatible with `n_obs` being the regression sample size. The automatic `obs|observations|n` name match has almost certainly selected a source observation number. This directly corrupts MAIVE while passing the existing “maximum N >= 30” test.

The evidence is decisive for “not sample size”; locating the actual source column, if one exists, requires moderator provenance or the source codebook. Until then this field should be null for `remittances`.

### 3. The year bug also contaminates `data_midyear`

Beyond the five known `pub_year` failures (4,543 rows), `data_midyear` is impossible in **4,004 rows**: all 1,019 `alphas`, 1,159 `beauty`, 965 `skill`, and 861 `students` rows. Their ranges are respectively 0--3.239, 0--3.932, 3.434--4.382 and 0--3.912, rather than calendar years. These are the same log/standardised-style regressors that fooled `pub_year`.

The staged `find_year()` value gate applies to all year concepts, so regeneration should remove or remap this defect too; the distributed 0.9.0 table remains wrong now.

### 4. `citations` is not harmonised to one scale

`citations` is populated in 24 literatures. In **13 literatures / 21,701 rows**, at least 95% of values are integers, consistent with counts. In the other **11 literatures / 16,029 rows**, more than 5% are fractional; many values are recognisable natural-log/rate values. `students` is conclusive: **860/861** values are noninteger and **26** are negative (minimum -2.702), so that field cannot be a citation count. Other examples have medians of 1.404 (`alphas`), 1.237 (`beauty`), 2.287 (`class`) and 3.602 (`incentives`), against raw-count medians of 80 (`activism`), 106 (`eis`) and 265 (`size`).

This may faithfully copy each source's preferred citation regressor, but pooling it as a single column silently mixes counts, logs and rates. Because the table omits moderator source-column and transform metadata, the exact scale of each of the 11 cannot be recovered from the pooled file. That provenance would settle which should be logged, exponentiated, relabelled as a rate, or left literature-specific.

### 5. Study-level precision degeneracy is much worse than the row-level check reports

With `w=1/se^2`, **16/39** literatures assign more than half of all weight to one study. Nine assign more than 95%: `activism` 99.73%, `beauty` 95.46%, `dst` 97.35%, `electricity` 99.9997%, `excess_sensitivity` 99.78%, `habits` 99.99998%, `remittances` effectively 100%, `size` 97.04%, and `spillovers` 99.73%.

Five majority-study failures are invisible to check 94 because no single row reaches its 25% trigger:

| literature | largest row | largest study | rows in that study | effective studies |
|---|---:|---:|---:|---:|
| `activism` | 21.43% | 99.73% | 100 | 1.005 |
| `discrate` | 22.64% | 77.38% | 5 | 1.588 |
| `education` | 1.80% | 67.69% | 105 | 2.127 |
| `excess_sensitivity` | 18.72% | 99.78% | 40 | 1.004 |
| `sigma` | 5.02% | 78.99% | 290 | 1.583 |

Here “effective studies” is `(sum W_study)^2 / sum(W_study^2)`. These are not merely large-study properties: they make nominally multi-study UWLS/PET/PEESE estimates effectively single-study results. At minimum, benchmark outputs need leave-one-study-out sensitivity and a reliability flag.

### 6. `effect_units` hides three material estimand transformations

- **`remittances`: confirmed wrong target.** On the shipped raw coefficients, the range is -10.986--191.018, the inverse-variance mean is `9.61e-13`, effective observations are 1.983, and one study has effectively 100% of weight. Recomputing the paper's PCC from the shipped `t=effect/se` and `df` gives 490 valid PCCs in [-0.9864, 0.9938], inverse-variance mean 0.05982, effective observations 190.3, and largest-study weight 14.92%. Thus the staged PCC change is not cosmetic: it changes the estimand and removes an artificial near-zero-SE singularity.
- **`migrant`: mislabeled inverse elasticity.** Although `effect_units` says `elasticity`, **969/1,091 (88.8%)** stored effects are negative and the median is -0.050. The median of `-1/effect` is **15.38**, on the scale of the catalogue's headline elasticity of roughly 13--22. The stored statistic should be labelled `negative inverse elasticity`; a headline-scale conversion also requires a delta-method SE, not the shipped SE unchanged.
- **`skill`: also an inverse statistic.** The raw median is 1.42. PET on the shipped scale is 0.32596; its reciprocal is **3.07**, close to the headline scale near 4. The metadata prose admits inversion is required, but the machine field still says `elasticity`. A consumer using only the table cannot distinguish this from the ten ordinary elasticity literatures.

`effect_units` is distributionally plausible for the remaining bounded units except the `class` rows below. Elasticity magnitudes alone cannot adjudicate the other unbounded literatures; a machine-readable transformation is required.

### 7. `class` contains invalid or sentinel PCC values

There are **2** effects outside the definitional range (1.371675 and 1.116313) and another **73 exactly at -1 or +1**, all with positive SEs. Of the boundary rows, 70 equal -1 and all come from `Cho et al. (2012)`; their SEs range 0.345 to 10.333. A PCC exactly at a perfect-correlation boundary with such positive uncertainty is not a coherent PCC/SE pair and strongly suggests a sentinel or upstream conversion failure. In total, 75/2,819 rows (2.66%) are at or beyond the boundary. Their combined precision weight is only `1.13e-6` of the literature total, so they barely move IVW estimates, but they are invalid input to correlation transforms and some likelihoods.

This needs source/codebook adjudication. Faithful provenance is a reason to retain the raw record, not to expose it as an unflagged valid PCC.

### 8. `study_id` is unsafe in the pooled table

There are **2,857** distinct `(dataset, study_id)` clusters but only **524** distinct bare `study_id` values. **175** IDs recur across literatures; 50,973/54,076 rows (94.3%) carry one of those recurring values. For example, `study_id=6` occurs in 36 literatures. Clustering pooled rows on the advertised column alone collapses the 2,857 real literature-study clusters to 524 artificial clusters, an 81.7% reduction.

Check 95 prints a warning, but the data contract still supplies no global cluster key. Add `literature_study_id` (for example `dataset + ':' + study_id`) and describe bare `study_id` as literature-local.

### 9. Smaller confirmed anomalies and unflagged judgment calls

- Date ordering catches plausible-but-wrong values that range checks miss: two `excess_sensitivity` rows have start/end 1972/1981 but `data_midyear=1986.5`; four `education` rows label a 2002 paper with `data_end=2006`. Which field is upstream-wrong is uncertain; the source paper/codebook would settle it.
- `inflation` uses `effect_col=Estimate_win`; **87/702 rows (12.4%)** sit exactly at the two winsorisation caps (-3.85: 45 rows; 6.0: 42). This is a defensible replication choice, but the pooled schema has no `effect_is_winsorised` field and most other literatures expose raw tails. Estimator comparisons therefore conflate data policy with estimator performance.
- The claimed row-level provenance is not a unique locator. Excluding the regenerated `estimate_id`, **7,753 rows** are exact duplicates of an earlier pooled row, and `(dataset,effect,se)` has **8,403 excess copies**. Some are legitimate equal estimates, but without `source_row_id` neither a user nor check 90 can distinguish equality from accidental duplication.

## Checks of mine you think are weak or wrong

1. **Check 90 gives false confidence because it compares sets.** It discards order and multiplicity on both sides. `price_puzzle` is the direct counterexample: all 6,360 extra rows pass because each duplicated pair occurs once in the source-derived set. The concluding phrase “every harmonised value occurs” is true but materially weaker than “every harmonised row is correct.” Check 97 repeats the same set error for duplicate exclusions.

2. **Check 94's statement that round-trip excludes mis-pairing is wrong.** A wrong pair of columns from the same source passes round-trip; check 92's own docstring correctly says exactly this. `remittances` proves the distinction: COEF/SE is a real and internally paired source pair, yet it is not the paper's synthesis estimand. The unit gate also prints a hard pass for `class` despite two PCCs outside [-1,1], and misses 73 incoherent boundary PCCs. “Upstream” changes responsibility, not validity.

3. **The estimator battery tests finiteness, not behaviour.** All of the near-single-study designs above can return finite, ordinary-looking coefficients. It checks neither rank/condition/leverage nor sensitivity to the dominant study. Calling this “estimators behave” is too strong.

4. **Check 91 does not establish equality of the four tables.** Its `same()` compares shape, column names, `effect`, `se`, `t_stat`, and dataset labels: only 4 of 41 value columns. A changed `n_obs`, `study_id`, `effect_units` or provenance column passes. I independently compared all 41 local parquet/CSV columns and found **0 current mismatches at `rtol=1e-12`**, but the gate would not protect that result in a future release.

5. **Check 93 mixes extraction with hand-written acquittal.** `RESOLVED` contains **12** hard-coded cases; one is explicitly the real `remittances` estimand defect. `UNRELATED` does not fail, a stem match treats a winsorised pair as confirmation of a raw pair, and the regex cannot establish which regression is headline. It is useful triage, not confirmation of 37 literatures.

6. **Check 95's `n_obs` and clustering assertions are inadequate.** “Maximum N >= 30” cannot detect a 1--538 row counter. `(dataset,study_id).ngroups > 0` is tautological and does not validate the study mapping; the output itself shows the supplied key is not global. The numerical-overlap section again compares value sets, so it cannot see multiplicity or the same primary paper under different transformations.

7. **Check 94C checks only an effect-value subset.** It does not require paired SEs, multiplicities, row identities or expected counts, and silently skips computed/reshaped cases when column names are absent. That is why the sevenfold `price_puzzle` expansion can pass the per-dataset check.

8. **Check 96 validates much less than its contract language implies.** Codebooks are compared on column names and missing counts, not types, definitions, transforms, ranges or primary keys. Dataset/resource counts are printed but not asserted equal. These checks would not catch any semantic moderator defect above.

9. **Check 97's no-precision logic is technically wrong for signed reconstructors.** It calls a candidate usable only when its minimum is positive. A legitimate t-statistic normally crosses zero, yet `SE=abs(effect/t)` is reconstructible away from zero; such a column would be rejected. Candidate names also cannot establish that a bound, p-value or weight belongs to the chosen effect.

## What I would do next, in priority order

1. Fix `price_puzzle` by deduplicating to one source IRF/specification before melting; require exactly 1,060 selected-horizon rows and a multiset/source-key round trip. Regenerate all local artefacts and counts as a new version; do not mutate the archived 0.9.0 deposit in place.
2. Apply the staged `remittances` PCC transform, set its `n_obs` to null unless a real sample-size column is verified, regenerate both year fields, and add regression tests for the exact numbers above.
3. Add `source_row_id`, `literature_study_id`, moderator-source columns, and machine-readable `estimand`, outcome, horizon, transform, null, sign, winsorisation and SE-origin fields. These fields remove several classes of ambiguity at once.
4. Recompute top-row and top-study weights, effective estimates/studies, and leave-one-study-out results for every literature. Mark the 16 majority-study cases unsuitable for naive precision weighting; do not describe them as ordinary 39-literature benchmark cases without sensitivity results.
5. Domain-audit the 11 non-count `citations` mappings, the 75 boundary/out-of-range `class` PCCs, the six date-order anomalies, and `migrant`/`skill` transformations. Preserve raw upstream values but quarantine invalid rows from estimator-ready defaults.
6. Replace set-based checks with keyed multiset checks, compare all 41 distributed columns, and make checks 90--97 fail on unexplained multiplicity, invalid definitional units, stale resource counts and semantic scale violations.
7. Run MAIVE, PET-PEESE, UWLS and RoBMA from the production implementations on raw, corrected, deduplicated, dominant-study-dropped and paper-policy samples. Store golden coefficients, uncertainty, effective sample sizes and convergence/rank diagnostics per literature.
