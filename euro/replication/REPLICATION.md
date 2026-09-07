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
