# Replication package: "Structural Reforms and Growth in Transition: A Meta-Analysis"

Havránek & Iršová-style meta-analysis, *Economics of Transition* (2014), doi 10.1111/ecot.12029.

**Table reproduced:** Table 3, "Test of publication bias" (both columns of the table as printed
in the paper: Short run / Long run, each with Fixed / Robust / Clustered).

## Provenance

`author_code`, with one caveat worth stating plainly. The task brief marked every relevant line
of `reform.do` as inside `/* */` and "does not run." Re-reading the actual file on disk
(`site/reforms/reform.do`), those lines are **not** commented out there — the file matches the
brief's line list token-for-token, in the same order, with no comment delimiters around them.
The most likely explanation is that whatever automated tool produced the brief tried to
execute the do-file standalone and had to skip lines that call SSC add-on commands not present
in that environment (`metan`, `rreg`) or that depend on `foreach`/`local` scaffolding not
reproduced in the brief's excerpt — not that the author's own script treats them as dead code.
Given the do-file matches the paper's Table 3 footnote description exactly (see below), this
is treated as genuine author code, not a `paper_methods_only` reconstruction.

## What the code does

From `reform.do`:

```
gen pcor = lib/sqrt(lib*lib+df)
gen pcor_cum = lib_cum/sqrt(lib_cum*lib_cum+df)
gen se_pcor = sqrt((1-pcor*pcor)/df)
gen se_pcor_cum = sqrt((1-pcor_cum*pcor_cum)/df)
gen se1_pcor = 1/se_pcor
gen se1_pcor_cum = 1/se_pcor_cum
gen odd = 1 if se1_pcor>15 & pcor>0.3 & lib<12

reg lib se1_pcor if rg!=0 & lib<12 & odd!=1                          " Short run, Fixed
reg lib_cum se1_pcor_cum if rg!=0 & lib_cum<7.5                      " Long run, Fixed
rreg lib se1_pcor if rg!=0 & lib<12 & odd!=1                         " Short run, Robust
rreg lib_cum se1_pcor_cum if rg!=0 & lib_cum<7.5                     " Long run, Robust
reg lib se1_pcor if rg!=0 & lib<12 & odd!=1, vce(cluster study)      " Short run, Clustered
reg lib_cum se1_pcor_cum if rg!=0 & lib_cum<7.5, vce(cluster study)  " Long run, Clustered
```

`lib` is the primary study's reported t-statistic on the reform variable, not a correlation
itself: `pcor = lib/sqrt(lib^2+df)` is the standard t-to-partial-correlation identity, which
inverts to `lib = pcor/se_pcor`. So an unweighted OLS of `lib` on `se1_pcor = 1/se_pcor` is
algebraically identical to a WLS regression of `pcor` on `se_pcor` weighted by `1/se_pcor^2` —
exactly what Table 3's note describes for "Fixed" ("weighted least squares; weighted by the
inverse of the standard error of the partial correlation coefficient"). No explicit weights
argument is needed; the `lib`/`se1_pcor` transform *is* the weighting, and `run.R` uses
`st_regress(lib ~ se1_pcor, data = ...)` unweighted, matching the do-file line for line.

Term mapping (worth spelling out because it is easy to get backwards): dividing the WLS
specification `pcor = b_PET + b_pub*se_pcor + e` through by `se_pcor` gives
`lib = b_PET*(1/se_pcor) + b_pub + u`. So in `reg lib se1_pcor`, the **intercept** is the
funnel-asymmetry / publication-bias coefficient (Table 3's "Publication bias (coef. β0)" row),
and the **slope on se1_pcor** is the precision-effect estimate of the true, bias-corrected
effect (Table 3's "Effect beyond bias (Constant)" row — named for what it estimates, not for
being literally Stata's `_cons`).

"Clustered" reuses the same `st_regress` wrapper with `cluster = ~study`. "Robust" calls
Stata's `rreg` (Cook's-distance pre-filter, then iteratively re-weighted Huber/biweight
M-estimation), which has no wrapper in `stata_compat.R` and is not one of the primitives the
task allows (`feols`, `lm`, `rma`, `lmer`, `plm`, `quantile` are all explicitly off-limits, and
`rreg` isn't equivalent to any of them anyway — an `MASS::rlm()` stand-in would be a different,
uncalibrated estimator). Per the brief's instruction to stop rather than substitute, the two
Robust columns are reported as unresolved misses.

Stata missing-value semantics matter here: `rg`, `lib_cum` (for the short-run filter) and `odd`
can be missing, and Stata treats missing as +infinity, so `rg!=0` and `odd!=1` are *true* when
those variables are missing, while `lib<12` and `lib_cum<7.5` are *false* when `lib`/`lib_cum`
are missing. `run.R` builds each comparison with an explicit `ifelse(is.na(x), Inf, x)`
substitution before combining them, then passes the fully-resolved logical vector to
`st_keep_if` (which is otherwise a no-op safety net once the vector has no remaining `NA`s).

## Target-by-target results

Values are the model's raw output; "printed" is rounded to 3 decimals (or 0 for N) to match the
paper.

| Label | Printed | Produced | Verdict |
|---|---|---|---|
| pb_short_fixed_coef | 4.137 | 4.137296 | MATCH |
| pb_short_fixed_se | 0.947 | 0.946862 | MATCH |
| pb_short_robust_coef | 4.179 | NA | MISS (unsupported: `rreg` has no wrapper) |
| pb_short_robust_se | 0.961 | NA | MISS (unsupported) |
| pb_short_clustered_coef | 4.137 | 4.137296 | MATCH |
| pb_short_clustered_se | 2.036 | 2.035729 | MATCH |
| pb_long_fixed_coef | 0.313 | 0.313417 | MATCH |
| pb_long_fixed_se | 0.290 | 0.290147 | MATCH |
| pb_long_robust_coef | 0.265 | NA | MISS (unsupported) |
| pb_long_robust_se | 0.300 | NA | MISS (unsupported) |
| pb_long_clustered_coef | 0.313 | 0.313417 | MATCH |
| pb_long_clustered_se | 0.586 | 0.586295 | MATCH |
| eff_short_fixed_coef | -0.394 | -0.394162 | MATCH |
| eff_short_fixed_se | 0.073 | 0.073149 | MATCH |
| eff_short_robust_coef | -0.395 | NA | MISS (unsupported) |
| eff_short_robust_se | 0.074 | NA | MISS (unsupported) |
| eff_short_clustered_coef | -0.394 | -0.394162 | MATCH |
| eff_short_clustered_se | 0.164 | 0.164444 | MATCH |
| eff_long_fixed_coef | 0.110 | 0.110220 | MATCH |
| eff_long_fixed_se | 0.025 | 0.025372 | MATCH |
| eff_long_robust_coef | 0.116 | NA | MISS (unsupported) |
| eff_long_robust_se | 0.026 | NA | MISS (unsupported) |
| eff_long_clustered_coef | 0.110 | 0.110220 | MATCH |
| eff_long_clustered_se | 0.056 | 0.056185 | MATCH |
| n_short_fixed | 245 | 245 | MATCH |
| n_short_robust | 245 | NA | MISS (unsupported) |
| n_short_clustered | 245 | 245 | MATCH |
| n_long_fixed | 292 | 292 | MATCH |
| n_long_robust | 292 | NA | MISS (unsupported) |
| n_long_clustered | 292 | 292 | MATCH |

**20 of 20 computable (non-Robust) targets match to the printed precision. 10 targets (the two
Robust columns' 8 coefficient/SE cells plus their 2 N cells) are unresolved misses because Stata's
`rreg` has no wrapper in `stata_compat.R` and is not one of the allowed direct primitives.**

## Misses

All 10 misses share one cause: `rreg` (Stata's robust regression — Cook's-distance screening
followed by iteratively re-weighted Huber then biweight M-estimation) is not implemented by any
wrapper in `stata_compat.R`, and the task's rules forbid calling a substitute estimator
(`MASS::rlm()` or similar) directly. This is reported rather than worked around, per the brief's
"STOP and report unsupported_command" instruction — applied here at the level of the two
affected columns rather than the whole run, since the other four columns of the same table are
fully reproducible from allowed primitives.

## Repairs made

None were needed. The first run, using the filters and formulas transcribed directly from
`reform.do` with Stata's missing-as-+Inf semantics applied explicitly, reproduced all 20
computable targets to the printed precision on the first attempt.

## Verdict

**PARTIAL.** Every deterministic target that could be built from an allowed wrapper matched
exactly (Fixed and Clustered columns, both short-run and long-run, coefficients, standard
errors, and N). The Robust column is out of reach only because the estimator (`rreg`) has no
wrapper — not because of any specification or data mismatch.
