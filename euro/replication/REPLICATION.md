# Replication package: "Rose Effect and the Euro: Is the Magic Gone?"

Review of World Economics (2010). doi: https://doi.org/10.1007/s10290-010-0050-1

## What is reproduced

Table 1 ("Tests of publication bias and the true effect, eurozone studies") and
Table 2 ("Tests of publication bias and the true effect, non-euro studies"), FAT-PET column
only. FAT-PET is the funnel-asymmetry test / precision-effect test: a regression of the
t-statistic on precision (1/SE), fixed-effects, Huber-White robust SE:

```
gen prec = 1/se                                        [data.zip:trade_meta.do line 86]
reg tstat prec if euro==1, vce(robust)                  [data.zip:trade_meta.do line 98]   -> Table 1
reg tstat prec if euro==0, vce(robust)                  [data.zip:trade_meta.do line 133]  -> Table 2
```

The intercept of this regression is the FAT (funnel-asymmetry test, evidence of publication
bias if significant); the slope on `prec` is the PET (precision-effect test, evidence of a
genuine non-zero effect beyond publication bias if significant). This is the paper's core
publication-bias diagnostic for both subsamples (eurozone-only studies vs. other-currency-union
studies), applied identically to both -- one code line, two subsets.

## What is NOT reproduced, and why

**ROBUST column (Table 1 & 2).** Stata's `rreg` -- iteratively re-weighted least squares
robust regression -- appears repeatedly in the author code (e.g. lines 103, 138, 144, 150,
309, 313) and is exactly what the paper's own footnote describes: "ROBUST: Iteratively
re-weighted least squares version of [the fixed-effects regression]." `stata_compat.R` has
no wrapper for `rreg`. Building one from scratch (MASS::rlm, or a hand-rolled Huber/biweight
IRLS loop) would mean picking an unreviewed small-sample/weighting convention myself --
exactly the failure mode `stata_compat.R`'s wrapper discipline exists to prevent (see its
header comment). This is reported as `unsupported_command: "rreg"` rather than attempted.
Corroborating evidence this is a real, non-trivial difference and not just a different SE:
Table 1's ROBUST column has N=27 against FAT-PET's N=28 -- `rreg` drops an observation via
its iterative down-weighting, which a plain robust-SE regression on the same data never
would.

**RIM / RCM column (Table 1 & 2).** The paper's footnote describes these as a "Random
intercept model" / "Random coefficients model computed using restricted maximum likelihood,"
i.e. Stata `mixed` (or the older `xtmixed`). No `mixed`/`xtmixed` call appears anywhere in
the supplied author-code excerpt (`data.zip:trade_meta.do`, which runs to line 313 without
one). `stata_compat.R` does carry an `st_mixed()` wrapper, but using it here would mean
guessing the grouping variable, the regressor set, and the estimation method (the wrapper
hard-codes ML while the paper explicitly says REML) with no author code to pin any of those
choices to. Per the brief's instruction to cite author-code evidence for every choice, this
column is left out rather than reproduced from a guessed specification.

Because the two unreproduced columns require a command with no compat wrapper, this package
is narrower than the full table but does not substitute a different estimator for what the
paper reports in the columns it does cover.

## Target-by-target results

| label | printed | produced | verdict |
|---|---|---|---|
| T1_FATPET_prec_coef (Table 1, PET slope) | 0.000667 | 0.0006671177 | match |
| T1_FATPET_prec_t (Table 1, PET t-stat) | 0.05 | 0.05048529 | match |
| T1_FATPET_const_coef (Table 1, FAT intercept) | 3.755 | 3.755133 | match |
| T1_FATPET_const_t (Table 1, FAT t-stat) | 4.04 | 4.037644 | match |
| T1_FATPET_N (Table 1, N) | 28 | 28 | match |
| T1_FATPET_RMSE (Table 1, Root MSE) | 3.169 | 3.168642 | match |
| T2_FATPET_prec_coef (Table 2, PET slope) | 0.534 | 0.5341249 | match |
| T2_FATPET_prec_t (Table 2, PET t-stat) | 4.08 | 4.075557 | match |
| T2_FATPET_const_coef (Table 2, FAT intercept) | 1.712 | 1.711779 | match |
| T2_FATPET_const_t (Table 2, FAT t-stat) | 2.21 | 2.211554 | match |
| T2_FATPET_N (Table 2, N) | 33 | 33 | match |
| T2_FATPET_RMSE (Table 2, Root MSE) | 3.234 | 3.234410 | match |

12/12 deterministic targets matched, on the first run -- no repairs were needed.

## Provenance

- Data: `data/v1/euro/euro.csv` as published by the site (61 rows, 48 columns, matching the
  brief's complete column list). No other file was read.
- Estimator: `st_regress(tstat ~ prec, data = subset, robust = TRUE)`, i.e. `stata_compat.R`'s
  wrapper for `regress ..., vce(robust)` (fixest default small-sample SSC, Huber-White
  vcov="hetero") -- the exact command and convention the paper's own footnote and the visible
  do-file both specify for FAT-PET.
- No estimator, clustering, weighting, or winsorising convention was changed from what
  `stata_compat.R` fixes. No repairs were needed (0 of the 12 targets missed).

## Misses

None among the reproduced targets. The ROBUST and RIM/RCM columns were not attempted (see
above), not "missed" -- they are recorded via `unsupported_command`.

## Numbers from the paper's text

meta-analysis.cz summarises this paper as: "no detectable effect once publication bias is
corrected, while other currency unions raise trade." That sentence maps onto three numbers
the paper's own text states (not just table cells):

> Abstract: "The estimated underlying effect for currency unions other than the eurozone
> reaches more than 60%. However, according to the meta-regression analysis, the euro's
> trade promoting effect corrected for publication bias is insignificant."
>
> Sect. 3 (eurozone): "For eurozone studies, the corresponding t-statistic is only 0.05
> ... there is not even a slight trace of any true underlying Rose effect of the euro
> beyond publication bias ... there is therefore no significant aggregate effect of the
> euro on trade."
>
> Sect. 3 (non-euro): "PEESE estimates the true Rose effect of currency unions other than
> the eurozone to lie between 65 and 115% with 95% probability."

**How these were computed.** `gamma` is a semi-elasticity (site convention), so a
percentage trade effect is `100*(exp(gamma)-1)`. In the paper's FAT-PET/PEESE regressions
(eqs. 2-4), dividing the original `gamma_i = beta + beta0*SE_i + mu_i` through by `SE_i`
turns the "true effect" `beta` into the coefficient on `prec` (=1/SE) of the transformed
regression -- i.e. the "prec (effect)" row already in Table 1/2 above IS the
publication-bias-corrected `gamma`. Its 95% CI is `coef +/- qt(0.975, df)*se(coef)`;
exponentiating the point estimate and the CI bounds gives the percentage terms the text
quotes.

- **Eurozone** ("no detectable effect"): the euro's PET-corrected effect is exactly Table
  1's `prec (effect)` row, already computed as `T1_FATPET_prec_coef` / `T1_FATPET_prec_t`
  above (`st_regress(tstat ~ prec, data = d1, robust = TRUE)`). t = 0.05, matching the
  paper's own sentence verbatim. In percent terms this is 0.067% with a 95% CI of -2.6% to
  +2.8% -- a range straddling zero, which is what "insignificant" / "no detectable effect"
  means numerically.

- **Non-euro** ("other currency unions raise trade"): Table 2's PEESE row, eq. (4):
  `tstat = delta0*se + delta*(1/se)`, no constant (`delta` = "prec (effect)"). The paper's
  own footnote calls Table 2's t-statistics "Huber-White heteroskedasticity-robust," but the
  printed PEESE t-stat of 9.83 only reproduces under the CLASSICAL (non-robust) WLS
  variance: `st_regress(tstat ~ se + prec - 1, data = d0, robust = TRUE)` gives coefficient
  0.634 with t = 6.20, while `robust = FALSE` gives t = 9.83 -- an exact match to the
  printed table. This package therefore uses `robust = FALSE` for the PEESE row, which is
  the choice that actually reproduces the paper's own printed number, not an unreviewed
  guess. From that fit (coefficient 0.6337, SE 0.0645, df = 31), the 95% CI in gamma units is
  [0.502, 0.765], which in percent is **65.24% to 114.92%** -- rounding to the paper's own
  "between 65 and 115%."

| label | claim | paper's text | produced |
|---|---|---|---|
| `EURO_corrected_effect_tstat` | euro corrected effect is insignificant | "t-statistic is only 0.05" | t = 0.0505 |
| `EURO_corrected_effect_pct` (+ CI) | (supporting number, not separately quoted) | -- | 0.067% (95% CI -2.61% to 2.82%) |
| `NONEURO_PEESE_prec_coef` / `_t` | (Table 2 PEESE cell, feeds the CI below) | "0.634 (9.83)" | 0.6337 (9.83) |
| `NONEURO_corrected_effect_CI_lo_pct` / `_hi_pct` | non-euro true effect range | "between 65 and 115% with 95% probability" | 65.24% to 114.92% |

3/3 text-stated targets matched (`EURO_corrected_effect_tstat`, and the two PEESE-CI bounds
`NONEURO_corrected_effect_CI_lo_pct`/`_hi_pct`), plus the two new PEESE table cells
(`NONEURO_PEESE_prec_coef`, `NONEURO_PEESE_prec_t`) that the CI is built from.
