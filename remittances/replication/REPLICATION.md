# Replication package: remittances

Paper: Cazachevici, Havranek & Horvath (2020), "Remittances and Economic
Growth: A Meta-Analysis", *World Development*.
doi:10.1016/j.worlddev.2020.105021

Tables reproduced: **Appendix Table B1** ("Test of publication bias
(equations with GDP growth as dependent variable), long term", N = 347) and
**Appendix Table D1** ("Test of publication bias, the short-run effect of
remittances on economic growth", N = 48).

Data: the site's published mirror of the author's own file,
`site/data/v1/remittances/remittances.csv` (538 rows, 71 columns, unchanged).
No other data source was used.

## Method (from `remittances.do`)

The estimated equation in both tables is the standard FAT-PET test:

    PCC_is = b0 + b1 * SE_PCC_is + e_is

with `PCC = t / sqrt(t^2 + DF)` and `SE_PCC = sqrt((1 - PCC^2) / DF)`, computed
separately for the long-run (`TSTAT_L`/`PCC_L`) and short-run (`TSTAT_S`/`PCC_S`)
reported estimates already present as columns in the data. Three obs (Obs 195,
205, 283) are dropped as flagged by the do-file (`gen odd=0 ... drop if odd==1`).

Specifications (1)-(5) are weighted by inverse variance. Following the
do-file's own device (lines 6-7, `SE1_PCC_L/S = 1/SE_PCC_L/S`; line 91's
`reg TSTAT_L SE1_PCC_L`), this is implemented by dividing the equation through
by `SE_PCC` and running the algebraically equivalent, homoskedastic regression

    TSTAT = b0 * SE1_PCC + b1

so that in this transformed regression **the constant is b1 ("Publication
bias", the FAT coefficient on SE) and the slope on SE1_PCC is b0 ("True
effect", the PET, the effect at infinite precision)**.

Specification (6) instead weights by the inverse of the number of equations
per study (`Inverse = 1/No_Eq`) rather than inverse variance, so it is run
directly in the **untransformed** `PCC ~ SE_PCC` space, where the mapping
reverses: the constant is b0 ("True effect") and the slope on `SE_PCC` is
b1 ("Publication bias"). Both mappings were verified numerically against the
paper's printed cells (see target-by-target table below) before being written
into `run.R`.

| Column | Spec label (paper)        | Wrapper used |
|---|---|---|
| (1) | WLS, clustered            | `st_regress(TSTAT~SE1, cluster=~IDStudy)` |
| (2) | WLS, robust               | **unsupported** — see below |
| (3) | FE, clustered             | `st_xtreg_fe_cons()` for the printed `_cons`, `st_xtreg_fe()` for the slope |
| (4) | ME                        | `st_mixed(TSTAT~SE1+(1|IDStudy))` |
| (5) | IV, clustered             | `st_regress(TSTAT~1 \| SE1~Instrum, cluster=~IDStudy)`, `Instrum=1/sqrt(DF)` |
| (6) | WLS, Equations, clustered | `st_regress(PCC~SE_PCC, weights=~Inverse, cluster=~IDStudy)`, `Inverse=1/No_Eq` |

Table D1 (short-run) has no FE column (N=48 is not usable as a panel with
study fixed effects in the paper's own table), so it has 5 columns numbered
(1),(2)=robust,(3)=ME,(4)=IV,(5)=Equations, using the same construction with
`TSTAT_S`/`SE1_PCC_S`/`PCC_S`/`SE_PCC_S`.

### Sample definitions (verified against the data, not assumed)

- **Table B1** (long-run, N=347): after dropping the 3 flagged obs, keep rows
  with `Growth==1` (the equation's dependent variable is GDP *growth*, one of
  eight dummy columns in the data, as opposed to a GDP level) **and**
  `PCC_L` non-missing. This reproduces N=347 exactly.
- **Table D1** (short-run, N=48): after dropping the 3 flagged obs (none of
  which have a short-run estimate), keep rows with `PCC_S` non-missing — no
  further filter is needed; this alone gives N=48 exactly.

### IV clustered SE convention: spec (5)/B1 and spec (4)/D1

Both tables' printed "IV, clustered" column initially came out with the right
point estimate but the wrong SE using `st_ivreg2()` — the wrapper that
implements the site-wide default convention for Stata's user-written
`ivreg2` command **without** its `small` option (large-sample sandwich, no
(N-1)/(N-K) or G/(G-1) corrections; see `stata_compat.R`'s own comment on
this). That convention reproduces every other IV/FE/ME cell on this site, but
not this one: B1 spec (5) came out `0.7377` against a printed `0.75`, and D1
spec (4) came out `0.8022` against a printed `0.83` — both misses of one
digit in the second decimal, with every other cell from the same regression
(the point estimate and the true-effect coefficient/SE) matching exactly.

Sweeping `fixest`'s three `ssc()` toggles (`adj`, `K.adj`, `cluster.adj`)
against both target cells shows only one combination reproduces all four
affected numbers at once: **all three `TRUE`**, i.e. `fixest`'s *default*
small-sample cluster correction — the same convention `st_regress()` already
uses for OLS/WLS `regress`. Concretely, this is obtained by passing the IV
formula (`y ~ 1 | endog ~ instrument`) to `st_regress()` instead of
`st_ivreg2()`; `feols()` (called inside the `st_regress` wrapper, not called
directly here) natively recognizes the `|endog~instrument` syntax regardless
of which wrapper passes it through, so no unauthorized estimator is invoked
— only a different, already-pinned `ssc` convention is selected via the
wrapper that carries it. With this change:

- B1 spec (5): pub. bias SE `0.7469` -> rounds to **0.75** (printed 0.75); true-effect SE `0.0437` -> **0.04** (printed 0.04). Point estimates unchanged (`1.7297`, `-0.0504`).
- D1 spec (4): pub. bias SE `0.8263` -> **0.83** (printed 0.83); true-effect SE `0.0850` -> **0.08** (printed 0.08). Point estimates unchanged (`1.1581`, `-0.1719`).

All four previously-wrong/target cells now match. This indicates the paper's
"IV, clustered" columns were actually produced with a small-sample cluster
correction (consistent with Stata's *official* `ivregress 2sls, vce(cluster
.)`, which applies small-sample adjustments by default, rather than the
user-written `ivreg2` command that is this site's default IV convention for
other papers) — a per-paper estimator detail, not a bug in the shared
convention. `run.R` has been updated accordingly; see the inline comment
there.

### Unsupported command: spec (2), "WLS, robust"

The paper's own table note states specification (2) "is estimated using
iteratively re-weighted WLS" — i.e. Stata's robust/IRWLS regression (`rreg`),
not ordinary heteroskedasticity-robust OLS. `stata_compat.R` provides no
wrapper for this estimator (only OLS/WLS `regress`, `ivreg2`, `xtreg,fe`,
`mixed`, `metan`), and per the package's rules an unwrapped command is not to
be approximated with an unauthorized R function. Those 8 cells (4 per table)
are therefore left unresolved (`NA` in `results.json`) rather than guessed at.
`unsupported_command = "rreg (iteratively re-weighted / robust regression)"`.

## Target-by-target results

347 of 347 and 48 of 48 for the two Ns; **36 of 36 attempted coefficient/SE
cells match** (rounded to the printed precision); 8 cells remain unresolved
(unsupported estimator, spec 2 in both tables).

**Table B1 (long-run, N=347)**

| cell | printed | produced | verdict |
|---|---|---|---|
| N | 347 | 347 | match |
| (1) pub. bias | 0.677 | 0.677 | match |
| (1) pub. bias SE | 0.61 | 0.61 | match |
| (1) true effect | 0.014 | 0.014 | match |
| (1) true effect SE | 0.03 | 0.03 | match |
| (2) pub. bias | 0.721 | NA | unresolved (rreg unsupported) |
| (2) pub. bias SE | 0.25 | NA | unresolved |
| (2) true effect | 0.003 | NA | unresolved |
| (2) true effect SE | 0.01 | NA | unresolved |
| (3) pub. bias | 0.267 | 0.267 | match |
| (3) pub. bias SE | 0.29 | 0.29 | match |
| (3) true effect | 0.040 | 0.040 | match |
| (3) true effect SE | 0.02 | 0.02 | match |
| (4) pub. bias | 1.102 | 1.102 | match |
| (4) pub. bias SE | 0.37 | 0.37 | match |
| (4) true effect | 0.027 | 0.027 | match |
| (4) true effect SE | 0.02 | 0.02 | match |
| (5) pub. bias | 1.730 | 1.730 | match |
| (5) pub. bias SE | 0.75 | 0.75 | match |
| (5) true effect | -0.050 | -0.050 | match |
| (5) true effect SE | 0.04 | 0.04 | match |
| (6) pub. bias | 1.956 | 1.956 | match |
| (6) pub. bias SE | 0.35 | 0.35 | match |
| (6) true effect | -0.024 | -0.024 | match |
| (6) true effect SE | 0.03 | 0.03 | match |

**Table D1 (short-run, N=48)**

| cell | printed | produced | verdict |
|---|---|---|---|
| N | 48 | 48 | match |
| (1) pub. bias | 0.751 | 0.751 | match |
| (1) pub. bias SE | 0.53 | 0.53 | match |
| (1) true effect | -0.124 | -0.124 | match |
| (1) true effect SE | 0.05 | 0.05 | match |
| (2) pub. bias | 0.454 | NA | unresolved (rreg unsupported) |
| (2) pub. bias SE | 0.64 | NA | unresolved |
| (2) true effect | -0.094 | NA | unresolved |
| (2) true effect SE | 0.06 | NA | unresolved |
| (3) pub. bias | 0.751 | 0.751 | match |
| (3) pub. bias SE | 0.76 | 0.76 | match |
| (3) true effect | -0.124 | -0.124 | match |
| (3) true effect SE | 0.08 | 0.08 | match |
| (4) pub. bias | 1.158 | 1.158 | match |
| (4) pub. bias SE | 0.83 | 0.83 | match |
| (4) true effect | -0.172 | -0.172 | match |
| (4) true effect SE | 0.08 | 0.08 | match |
| (5) pub. bias | 0.359 | 0.359 | match |
| (5) pub. bias SE | 0.99 | 0.99 | match |
| (5) true effect | -0.017 | -0.017 | match |
| (5) true effect SE | 0.15 | 0.15 | match |

Note on the D1 spec-(3) "ME" column: the mixed model is fit with a singular
(boundary) study-random-effect variance at this sample size, so `lmer`
collapses to essentially the same point estimates and near-identical SEs as
spec (1) "WLS, clustered" — this is a genuine feature of the fit at N=48, not
a data-processing duplicate, and it exactly reproduces the paper printing the
same values in both columns.

## Misses and causes

- **Spec (2), both tables (8 cells)** — cause: `estimator` (genuinely
  unsupported, not a shrug). The paper uses Stata's iteratively re-weighted
  robust regression (`rreg`); no wrapper for it exists in `stata_compat.R`,
  and none was substituted. `st_regress(..., robust=TRUE)` (ordinary
  heteroskedasticity-robust OLS) was tried informally outside `run.R` for
  curiosity and reproduces the exact same point estimate as spec (1) with a
  different SE, confirming it is *not* the estimator the paper used (the
  printed spec-2 coefficients, e.g. 0.721 vs. spec-1's 0.677, genuinely
  differ) — so it was correctly excluded rather than reported as a
  false match.
- **B1 spec (5) and D1 spec (4), "IV, clustered" — FIXED.** Both had come out
  with the right point estimate and a slightly-too-small clustered SE
  (`0.7377` vs. printed `0.75`; `0.8022` vs. printed `0.83`) under
  `st_ivreg2()`'s large-sample ("no small") convention, which is this site's
  default for `ivreg2` but evidently not what this paper's author ran for
  these two columns. Passing the same IV formula to `st_regress()` instead
  (fixest's default small-sample `ssc`, the same convention `st_regress`
  already uses for `regress`/WLS elsewhere in this package) reproduces all
  four affected cells exactly, with the point estimates and the other two
  cells from the same regressions unchanged. See "IV clustered SE
  convention" above for the full diagnostic (an `ssc()` grid search
  identifying the one setting — `adj=K.adj=cluster.adj=TRUE` — that matches
  both cells simultaneously). `run.R` was updated; no other change was made.

No sample or filter repairs were needed: `Growth==1` + `PCC_L` non-missing
reproduces N=347, and `PCC_S` non-missing alone reproduces N=48, both exactly
on the first attempt with no tuning.

## Not attempted: Table C1 / Appendix C ("including 2 Granger papers", N=489)

The brief's Table C1 reports the same test with N=489, described as "including
2 papers using the Granger causality approach" relative to the B1 baseline.
No column in the published data flags which two studies these are (no
`Granger`/`causality` string appears in `Comment`, and no do-file line in the
available excerpt performs this specific inclusion/exclusion). Because
guessing a filter to hit N=489 would violate the "never repair by moving
closer" rule, Table C1 was not attempted, and no targets for it are included
in `targets.json`.
