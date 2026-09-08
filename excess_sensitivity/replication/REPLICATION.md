# Replication package: excess_sensitivity

**Paper:** "Do Consumers Really Follow a Rule of Thumb? Three Thousand Estimates from 144
Studies Say 'Probably Not'", *Review of Economic Dynamics* 2020.
https://doi.org/10.1016/j.red.2019.05.004

**Table reproduced:** Table 2, "Excess sensitivity explained by macro data, publication bias,
and liquidity constraints" (5 columns: Bias only / Baseline / Bias ignored / Precision / Study).

## Why Table 2, not Table 1 or Table 4

Table 1 needs `xtreg ..., fe` **and** `xtreg ..., be` (between effects) split by micro/macro
subsample. `stata_compat.R` has a wrapper for `xtreg, fe` (`st_xtreg_fe`) but none for `xtreg,
be` — between-effects estimation (group-mean regression with its own weighting and
degrees-of-freedom convention) is exactly the kind of command the wrapper file's own preamble
warns against re-deriving by hand. Table 4 is a Bayesian model-averaging exercise (R's `bms`
package) with no corresponding wrapper at all. Table 2 needs only pooled OLS/WLS with two-way
clustering — every column maps onto `st_ivreg2()`, so it is reproducible without inventing an
estimator the site's compatibility layer does not cover.

## Provenance

All five columns trace to `data_code.zip:excess.do`:

| Column | Line | Stata call |
|---|---|---|
| Bias only | 194 | `ivreg2 excess micro microse, cluster(idstudy countryyear)` |
| Baseline | 196 | `ivreg2 excess micro microse LC_not_bind, cluster(idstudy countryyear)` |
| Bias ignored | 198 | `ivreg2 excess micro LC_not_bind, cluster(idstudy countryyear)` |
| Precision | 200 | `ivreg2 excess micro microse LC_not_bind [pweight=prec], cluster(idstudy countryyear)` |
| Study | 202 | `ivreg2 excess micro microse LC_not_bind [pweight=invperstudy], cluster(idstudy countryyear)` |

Variable construction, also from `excess.do`:
- line 14: `gen prec = 1/se`
- line 32: `replace LC_not_bind = 0 if switch==1` (59 of 3,127 rows change)
- line 42: `gen microse = micro*se`
- `invperstudy` (used at line 202, `gen invperstudy = 1/perstudy` at line 38): `perstudy` is not
  itself a marked line in the brief, but its definition is pinned unambiguously by the table
  note: *"Study = the inverse of the number of estimates reported per study is used as the
  weight."* Reconstructed as the count of rows sharing the same `idstudy`, taken over the full
  3,127-row analysis sample (Table 2 applies no `if` filter, so there is no subsample-timing
  ambiguity here of the kind that would matter for Table 1).

All five specifications run on the full published file, no subsetting: N = 3,127, 144 studies,
which is exactly what the paper reports for every column of this table and cross-checks against
the raw CSV (`idstudy` has 144 unique values, 3,127 rows, no missing `excess`/`se`/`micro`/
`LC_not_bind`/`switch`/`countryyear`).

Two derived rows in the table ("Implied RoT share" and "RoT share with LC") are not separate
regressions but linear combinations of already-estimated coefficients, per the table note:
*"The implied share of rule-of-thumb consumers is computed as the sum of constant, micro, and
liquidity unconstr... The rule-of-thumb share with liquidity constraints is the implied estimate
of excess sensitivity of liquidity-constrained households in micro studies"* (i.e. the same sum
without the liquidity-unconstrained adjustment: constant + micro). These are computed directly
from the `st_ivreg2()` coefficient vectors already produced — no additional estimator.

## Data

`web_meta/site/data/v1/excess_sensitivity/excess_sensitivity.csv` (3,127 rows, 75 columns,
published by the site) — the only data source `run.R` reads.

## Wrappers used

Only `st_ivreg2()` (pooled/weighted `ivreg2` with two-way clustering, no `small`) and
`st_coefs()`. No other `stata_compat.R` function was needed for this table.

## Results

47 of 48 targets matched at the printed precision. Both count targets (N and number of studies)
matched exactly.

| Label | Printed | Produced | Verdict |
|---|---:|---:|---|
| N_obs_all_specs | 3127 | 3127 | match |
| N_studies_all_specs | 144 | 144 | match |
| spec1_biasonly_micro_coef | -0.373 | -0.37334 | match |
| spec1_biasonly_micro_se | 0.0495 | 0.049475 | match |
| spec1_biasonly_microse_coef | 0.518 | 0.51819 | match |
| spec1_biasonly_microse_se | 0.111 | 0.11102 | match |
| spec1_biasonly_constant_coef | 0.480 | 0.48029 | match |
| spec1_biasonly_constant_se | 0.0408 | 0.040770 | match |
| spec1_biasonly_impliedRoT | 0.11 | 0.10694 | match |
| spec1_biasonly_RoTwithLC | 0.11 | 0.10694 | match |
| spec2_baseline_micro_coef | -0.353 | -0.35290 | match |
| spec2_baseline_micro_se | 0.0476 | 0.047574 | match |
| spec2_baseline_microse_coef | 0.511 | 0.51149 | match |
| spec2_baseline_microse_se | 0.109 | 0.10868 | match |
| spec2_baseline_LCunconstr_coef | -0.113 | -0.11284 | match |
| spec2_baseline_LCunconstr_se | 0.0436 | 0.043559 | match |
| spec2_baseline_constant_coef | 0.488 | 0.48770 | match |
| spec2_baseline_constant_se | 0.0411 | 0.041109 | match |
| spec2_baseline_impliedRoT | 0.02 | 0.02196 | match |
| spec2_baseline_RoTwithLC | 0.13 | 0.13479 | match |
| spec3_biasignored_micro_coef | -0.252 | -0.25240 | match |
| spec3_biasignored_micro_se | 0.0530 | 0.053019 | match |
| spec3_biasignored_LCunconstr_coef | -0.120 | -0.12034 | match |
| spec3_biasignored_LCunconstr_se | 0.0422 | 0.042213 | match |
| spec3_biasignored_constant_coef | 0.488 | 0.48819 | match |
| spec3_biasignored_constant_se | 0.0411 | 0.041111 | match |
| spec3_biasignored_impliedRoT | 0.12 | 0.11544 | match |
| spec3_biasignored_RoTwithLC | 0.24 | 0.23579 | match |
| spec4_precision_micro_coef | -0.495 | -0.49467 | match |
| spec4_precision_micro_se | 0.0810 | 0.080974 | match |
| spec4_precision_microse_coef | 1.049 | 1.04942 | match |
| spec4_precision_microse_se | 0.224 | 0.22413 | match |
| spec4_precision_LCunconstr_coef | -0.00440 | -0.0043983 | match |
| spec4_precision_LCunconstr_se | 0.00257 | 0.0025715 | match |
| spec4_precision_constant_coef | 0.500 | 0.49959 | match |
| spec4_precision_constant_se | 0.0811 | 0.081059 | match |
| spec4_precision_impliedRoT | 0.00 | 0.00052 | match |
| **spec4_precision_RoTwithLC** | **0.004** | **0.00492** | **MISS (rounds to 0.005)** |
| spec5_study_micro_coef | -0.283 | -0.28338 | match |
| spec5_study_micro_se | 0.0506 | 0.050646 | match |
| spec5_study_microse_coef | 0.486 | 0.48604 | match |
| spec5_study_microse_se | 0.193 | 0.19251 | match |
| spec5_study_LCunconstr_coef | -0.0782 | -0.078157 | match |
| spec5_study_LCunconstr_se | 0.0413 | 0.041342 | match |
| spec5_study_constant_coef | 0.436 | 0.43634 | match |
| spec5_study_constant_se | 0.0434 | 0.043417 | match |
| spec5_study_impliedRoT | 0.07 | 0.07481 | match |
| spec5_study_RoTwithLC | 0.15 | 0.15297 | match |

## The one miss

`spec4_precision_RoTwithLC`: the paper prints `0.004*`; the package produces 0.0049218, which
prints as 0.005. This is the derived row "RoT share with LC" in the Precision column.

### The row's definition is not in doubt

The table note defines the row as "the implied estimate of excess sensitivity of
liquidity-constrained households in micro studies", i.e. micro = 1, SE = 0 (bias corrected),
liquidity unconstr. = 0, which is `_cons + micro`. That formula reproduces the printed value in
all four other columns exactly: 0.11, 0.13, 0.24, 0.15.

### Stata, run on the author's own dataset, returns our number

The author's `excess.do` runs `lincom` after each `ivreg2` (lines 195-204). Re-running the do
file's own construction block on `data_code.zip:excess.dta` in Stata 15.1 reproduces every cell
of Table 2, and `lincom _cons + micro` after the Precision regression returns

```
 ( 1)  micro + _cons = 0
         (1) |   .0049218   .0024056     2.05   0.041     .0002068    .0096367
   estimate 0.004921758319   se 0.002405613813   p 0.04076159
```

The R package returns 0.004921758339 — the same number to eleven digits — and the same
delta-method SE, 0.002405614. So this is not an R/Stata numerical difference, not a weighting
difference, and not a sample difference: the estimator is pinned. All four coefficient/SE pairs
of the Precision column also match to every printed digit in both systems, including the
liquidity-unconstrained coefficient at three significant figures (-0.0043983 vs printed
-0.00440, SE 0.0025715 vs 0.00257).

Note that the author's do file only ever runs `lincom _cons + micro + LC_not_bind` (the "Implied
RoT share" row). There is no `lincom _cons + micro` in the do file at all for columns 2-5 — the
"RoT share with LC" row was produced outside the archived script and typed into the table by
hand. That matters for what follows.

### What the printed cell most likely is

`0.004*` matches, to the digit and to the star, the "Liquidity unconstr." cell two rows above it
in the same column:

| | value | p | prints as |
|---|---:|---:|---|
| Liquidity unconstr. (Precision) | -0.0043983 | 0.0872 | `-0.00440*` |
| `_cons + micro` (Precision) | 0.0049218 | 0.0408 | `0.005**` |
| **printed "RoT share with LC"** | **0.004** | | **`0.004*`** |

|-0.0043983| rounds to 0.004 at three decimals and carries exactly one star at the paper's
convention (10%), which is what the table shows. The correct linear combination rounds to 0.005
and carries two stars (5%). The printed cell therefore reproduces neither the value nor the
significance of the quantity the note defines, but reproduces both of the coefficient printed
two rows above it. The simplest reading is a hand-transcription slip in a row that, as the do
file shows, was assembled by hand.

An independent sign that this row block was typed by hand and carries more than one slip: in the
same table the "Implied RoT share" for the Study column is printed `0.07` with no star, while the
author's own `lincom _cons + micro + LC_not_bind` after that regression returns p = 0.0624, which
is significant at the 10% level and should carry one star. Both systems agree on that p-value.

### What was ruled out

- **A different construction of the variables.** Dropping `replace LC_not_bind = 0 if switch==1`
  gives `_cons + micro` = 0.00484 but moves the liquidity coefficient to -0.00421 (paper:
  -0.00440); setting those rows to 1 gives 0.00478 and -0.00408; `1/se^2` weights move every
  coefficient far off. No variant reaches 0.004 without breaking a printed cell.
- **A different reading of the row.** Adding the liquidity term gives 0.0005 (that is the other
  row, "Implied RoT share", printed 0.00). Evaluating at the micro-study mean SE gives 0.0039,
  which does print as 0.004 but is not what the note defines, contradicts the other four columns,
  and carries a 5% star (z = 2.14), so it does not rescue the printed `*` either.
- **A transcription error on our side.** The cell was re-read from the site's own copy of the
  published PDF (`excess_sensitivity_2.pdf`, p. 104: "RoT share with LC 0.11*** 0.13*** 0.24***
  0.004* 0.15***") and from the HTML rendering (`paper/index.html`). Both print 0.004*.
  `targets.json` records the paper correctly and was not edited.
- **An earlier printing to compare against.** The working-paper version (HSE WP 137/EC/2016, 133
  studies, 2,788 estimates) has no "RoT share with LC" row; it was added in the journal revision.
  The online appendix does not repeat the table.

### Verdict on this cell

Cause: **paper_inconsistent**. The package computes the row as the paper's own note defines it,
gets the same number as Stata does from the author's own data and code, and reports the
disagreement rather than bending it. `run.R` prints the level, the delta-method SE, the z and the
p of this sum, plus the magnitude and p of the liquidity coefficient, as diagnostic lines; neither
is a target and neither is written to `results.json`.

Note for whoever maintains the target file: the frozen `targets.json` classifies this target as
`kind: "deterministic"`, so the verifier scores it as computed-but-wrong. The evidence above says
it is a `kind: "discrepancy"` in the verifier's own taxonomy - computed correctly, disagreeing
with the paper. That is a change to the oracle and was deliberately **not** made here.

No repairs were needed for the other 47 targets; they matched on the first run, again after the
audit, and again against Stata.

## Stata commands with no wrapper (skipped, not used)

- `xtreg ..., be` (Table 1's "BE" columns) - no `stata_compat.R` wrapper.
- R `bms()` Bayesian model averaging (Table 4) - no wrapper, different code file
  (`data_code.zip:excess.R`) and different toolchain entirely.

Neither was needed for Table 2 and neither was invoked.

## Verdict

**PARTIAL** - 47 of 48 deterministic targets match at printed precision, including both exact
count targets (N = 3,127; 144 studies) and every coefficient and standard error in all five
columns. The single miss (`spec4_precision_RoTwithLC`) is a hand-assembled derived cell whose
printed value and star both correspond to a different cell of the same column; the regression it
derives from is reproduced to every printed digit, and Stata 15.1, run on the author's own
`excess.dta` with the author's own `ivreg2` and `lincom` commands, returns the package's number
(0.0049218, p = 0.041), not the printed one. Cause: **paper_inconsistent**. See "The one miss".
