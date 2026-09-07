# Replication package -- price_puzzle (price puzzle meta-analysis)

**Paper**: "How to Solve the Price Puzzle? A Meta-Analysis", *Journal of Money, Credit and
Banking* 2013, https://doi.org/10.1111/j.1538-4616.2012.00561.x

**Table reproduced**: Table A1, "Test of Publication Bias and True Effect, OLS" -- the
funnel-asymmetry/precision-effect (FAT-PET) meta-regression of the approximated t-statistic
on precision (1/SE), OLS with standard errors clustered at the study level, one column per
impulse-response horizon (3, 6, 12, 18, 36 months): 5 horizons x 7 numbers (intercept
coefficient and SE, slope coefficient and SE, R2, observations, studies) = 35 targets.

**Provenance**: author's own Stata do-file (`puzzle.do`), line 7 (`use "puzzle.dta", clear`),
lines 13-14 (`replace res=100*res` / `replace se=100*se`), and lines 35-39
(`eststo: reg t prec if horizon==3/6/12/18/36, vce(cluster idstudy)`), matched against the
printed numbers in Table A1.

## Why Table A1, not Table 2 or Table 4

Table 2 ("Test of True Effect and Publication Bias") reports the same publication-bias test
but as a **mixed-effects multilevel** model, and Table 4 extends it with many structural,
data, and specification covariates, also mixed-effects. The excerpt of `puzzle.do` available
to this package shows the exact Stata line for the **OLS** version (`reg ... , vce(cluster
idstudy)`, lines 35-39) but no line invoking `mixed` (or any multilevel command) for the
headline Table 2/4 specifications, and the OLS-with-covariates lines further down the do-file
(155 onward, `reg t prec gdppc_se growth_se inf_se ... `) are themselves truncated
mid-command in the excerpt, so the full covariate list and any `vce`/weight options cannot be
read off with confidence. Building Table 2's mixed model would mean guessing the random-effects
structure and estimation options `stata_compat.R`'s `st_mixed` wrapper (`lme4::lmer`, ML) does
not by itself pin down, and building Table 4 would mean guessing a covariate list past the
point the excerpt cuts off -- both ruled out by the task's "never estimator ... not evidenced"
constraint. Table A1 is the one candidate table whose exact Stata command is fully visible,
so it is the headline table reproduced here.

## Data

`data/v1/price_puzzle/price_puzzle.csv` (1,519 rows, 152 columns) is the published mirror of
the author's wide file. It is **not** already in the long, one-row-per-horizon shape the
do-file's `if horizon==h` filters expect from `puzzle.dta`; instead every estimate (identified
by `idstudy`/`idest`) appears as 7 duplicate rows, one for each value of a `horizon` indicator
(3, 6, 12, 18, 36, 88, 99 -- the last two evidently code "bottom" and "peak"), with the actual
horizon-specific response and SE living in fixed-name columns that do **not** vary across an
estimate's 7 duplicate rows: `M3R`/`SE3`, `M6R`/`SE6`, `M12R`/`SE12`, `M18R`/`SE18`,
`M36R`/`SE36` (confirmed by inspecting all 7 rows for `idstudy==1, idest==1`: these columns
are identical across the duplicate). Selecting the row's own-horizon `M{h}R`/`SE{h}` pair and
restricting to `horizon==h` therefore reconstructs exactly the generic `res`/`se` variables
`puzzle.do` operates on, and reproduces the paper's own N and study counts per horizon
(verified below) -- this is the reading used throughout `run.R`.

## Construction (`puzzle.do` lines 7, 13-14, 35-39)

For each horizon h in {3, 6, 12, 18, 36}:

1. Keep the rows of the published CSV with `horizon == h` (`st_keep_if`).
2. `res <- M{h}R * 100`, `se <- SE{h} * 100` (do-file lines 13-14: `replace res=100*res` /
   `replace se=100*se`, i.e. percentage-point units).
3. Drop rows with missing `res`/`se` at this horizon -- the same rows Stata's `if horizon==h`
   filter silently excludes from `reg`. This reproduces the paper's printed N and study count
   exactly for every horizon (208/69, 215/70, 215/70, 217/70, 205/63) and is the check that the
   `M{h}R`/`SE{h}` reading of the data is the right one.
4. `t <- res / se` (the "approximated t-statistic" the paper's own notes describe as the
   response variable), `prec <- 1 / se`.
5. `eststo: reg t prec if horizon==h, vce(cluster idstudy)` -> `st_regress(t ~ prec, cluster =
   ~idstudy)`.

No estimator, clustering, weighting, or degrees-of-freedom convention was changed from what
the do-file specifies; `st_regress`'s documented convention (fixest's own default small-sample
correction) is exactly Stata `regress`'s.

## Target-by-target results

All 35 targets are deterministic (no bootstrap/simulation anywhere in this table) and all
matched at the printed precision.

| Label | Printed | Produced | Verdict |
|---|---|---|---|
| H3: Intercept (bias) coef | -0.277 | -0.27749 | MATCH |
| H3: Intercept (bias) se | 0.176 | 0.17648 | MATCH |
| H3: 1/SE (effect) coef | 0.032 | 0.03173 | MATCH |
| H3: 1/SE (effect) se | 0.014 | 0.01440 | MATCH |
| H3: R2 | 0.05 | 0.0477 | MATCH |
| H3: Observations | 208 | 208 | MATCH |
| H3: Studies | 69 | 69 | MATCH |
| H6: Intercept (bias) coef | -0.407 | -0.40713 | MATCH |
| H6: Intercept (bias) se | 0.186 | 0.18573 | MATCH |
| H6: 1/SE (effect) coef | 0.033 | 0.03337 | MATCH |
| H6: 1/SE (effect) se | 0.021 | 0.02065 | MATCH |
| H6: R2 | 0.03 | 0.0277 | MATCH |
| H6: Observations | 215 | 215 | MATCH |
| H6: Studies | 70 | 70 | MATCH |
| H12: Intercept (bias) coef | -0.341 | -0.34130 | MATCH |
| H12: Intercept (bias) se | 0.156 | 0.15623 | MATCH |
| H12: 1/SE (effect) coef | -0.007 | -0.00704 | MATCH |
| H12: 1/SE (effect) se | 0.016 | 0.01567 | MATCH |
| H12: R2 | 0.00 | 0.0009 | MATCH |
| H12: Observations | 215 | 215 | MATCH |
| H12: Studies | 70 | 70 | MATCH |
| H18: Intercept (bias) coef | -0.393 | -0.39336 | MATCH |
| H18: Intercept (bias) se | 0.147 | 0.14661 | MATCH |
| H18: 1/SE (effect) coef | -0.025 | -0.02490 | MATCH |
| H18: 1/SE (effect) se | 0.014 | 0.01390 | MATCH |
| H18: R2 | 0.02 | 0.0161 | MATCH |
| H18: Observations | 217 | 217 | MATCH |
| H18: Studies | 70 | 70 | MATCH |
| H36: Intercept (bias) coef | -0.784 | -0.78384 | MATCH |
| H36: Intercept (bias) se | 0.122 | 0.12198 | MATCH |
| H36: 1/SE (effect) coef | -0.018 | -0.01780 | MATCH |
| H36: 1/SE (effect) se | 0.008 | 0.00755 | MATCH |
| H36: R2 | 0.01 | 0.0150 | MATCH |
| H36: Observations | 205 | 205 | MATCH |
| H36: Studies | 63 | 63 | MATCH |

**35 / 35 deterministic targets matched. No misses, no repairs needed.**

## What is not attempted, and why

- **Table 2** and **Table 4** (mixed-effects multilevel versions of the same and an extended
  specification): no visible do-file line invokes a multilevel/`mixed` command, and the visible
  OLS-with-covariates lines (155 onward) are truncated mid-command in the excerpt available to
  this package -- see "Why Table A1, not Table 2 or Table 4" above.
- **Table A2** ("Explaining the Differences in Reported Impulse Responses, OLS"): the do-file
  lines behind it (155-192, 371-383) are visible but truncated (each command is cut off after
  roughly a dozen of what are evidently 15+ covariates, e.g. `... com_se single_se money_se f`),
  so the full right-hand side cannot be reconstructed without guessing variable names -- left
  out rather than approximated, per the same evidentiary standard as above.

## How to run

```
Rscript run.R       # writes results.json, prints every produced number
Rscript compare.R   # prints the target-by-target table above
```

## Verdict

**CONCORDANT** for Table A1 (the one candidate table whose exact author code is fully visible
and evidenced). Tables 2, 4, and A2 are out of scope for lack of visible/complete author code,
not misses against attempted targets.
