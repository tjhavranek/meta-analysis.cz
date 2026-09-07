# Replication package: sigma

**Paper**: Gechert, S., Havranek, T., Irsova, Z. & Kolcunova, D. (2022). "Measuring
Capital-Labor Substitution: The Importance of Method Choices and Publication Bias."
*Review of Economic Dynamics*. https://doi.org/10.1016/j.red.2021.05.003

**Table reproduced**: Table 5, "Potential sources of endogeneity" (six individual
columns: Identif., Data aggr., Results aggr., K: perpetual, Short run; the
"Translog" and "All" columns are blocked, see Misses below).

**Provenance**: author_code. The regressions follow `sigma.zip:sigma.do` lines
9-38 (data prep), 54 (`stacoudata`), 83 (`winsor2`), and 240-261 (the
SE-interaction terms and the six `xtreg ..., fe cluster(idstudy)` columns),
exactly as given in the brief.

**Data**: `site/data/v1/sigma/sigma.csv` (3,186 rows, 121 studies) — the only
data source read.

## Method

1. `se <- 0.001 if se==0` (do-file line 25; no rows in the published file
   actually hit this, but applied for fidelity).
2. `stacoudata = stadata + coudata` (line 54).
3. `winsor2 sigma se, cuts(5 95)` -> `sigma_win5`, `se_win5` via
   `st_winsor2()` (each variable winsorized independently at its own 5th/95th
   percentile, Stata's `_pctile` / quantile type 2 convention).
4. Interaction terms `se_identif`, `se_stacoudata`, `se_ind_disagg`,
   `se_k_perpet`, `se_short` = `se_win5 * {identif, stacoudata, ind_disagg,
   k_perpet, shortrun_expl}` (lines 240-252).
5. Each column: `xtreg sigma_win5 se_win5 se_X X, fe cluster(idstudy)` via
   `st_xtreg_fe()`, cluster defaulting to the panel variable `idstudy` (lines
   256-261). SE coefficient/SE and the interaction coefficient/SE are read
   straight off `st_coefs()`.
6. The table's "Constant" row is Stata's `xtreg, fe` reported `_cons`, which
   equals the grand mean of the estimated study fixed effects: `cons = ybar -
   sum(beta_j * xbar_j)` over every regressor in the column's model.
   `stata_compat.R`'s `st_xtreg_fe_cons()` wrapper implements exactly this
   identity but only for a single regressor. Rather than calling
   `feols()`/`lm()` a second time (forbidden by the task rules), the
   multivariate constant and its standard error are obtained by linear
   algebra on the *already-fitted* `st_xtreg_fe()` model object `m`: `cons =
   ybar - t(beta) %*% xbar`, and since `cons` is a linear function of `beta`
   with `xbar`/`ybar` fixed given the data, `Var(cons) = t(xbar) %*% vcov(m)
   %*% xbar`. This was verified against the "Identif." column before use —
   it reproduces the printed 0.512 (0.0357) exactly — and is applied
   identically to the other four columns.

## Target-by-target results

Printed values rounded to the digits shown in the paper; produced values are
this run's raw output rounded to the same precision.

| Column | Cell | Printed | Produced | Verdict |
|---|---|---|---|---|
| Identif. | SE coef | 0.649 | 0.649 | match |
| Identif. | SE se | 0.219 | 0.219 | match |
| Identif. | Constant coef | 0.512 | 0.512 | match |
| Identif. | Constant se | 0.0357 | 0.0357 | match |
| Identif. | SE\*Identif coef | -0.0323 | -0.0323 | match |
| Identif. | SE\*Identif se | 0.332 | 0.332 | match |
| Data aggr. | SE coef | 0.803 | 0.803 | match |
| Data aggr. | SE se | 0.318 | 0.318 | match |
| Data aggr. | Constant coef | 0.553 | 0.553 | match |
| Data aggr. | Constant se | 0.0420 | 0.0420 | match |
| Data aggr. | SE\*Dataaggr coef | -0.299 | -0.299 | match |
| Data aggr. | SE\*Dataaggr se | 0.334 | 0.334 | match |
| Results aggr. | SE coef | 0.624 | 0.624 | match |
| Results aggr. | SE se | 0.146 | 0.146 | match |
| Results aggr. | Constant coef | 0.569 | 0.569 | match |
| Results aggr. | Constant se | 0.0449 | 0.0449 | match |
| Results aggr. | SE\*Resultsaggr coef | 0.0616 | 0.0616 | match |
| Results aggr. | SE\*Resultsaggr se | 0.249 | 0.249 | match |
| K: perpetual | SE coef | 0.754 | 0.754 | match |
| K: perpetual | SE se | 0.259 | 0.259 | match |
| K: perpetual | Constant coef | 0.551 | 0.551 | match |
| K: perpetual | Constant se | 0.0337 | 0.0337 | match |
| K: perpetual | SE\*Kperpet coef | -0.334 | -0.334 | match |
| K: perpetual | SE\*Kperpet se | 0.289 | 0.289 | match |
| Short run | SE coef | 0.473 | 0.473 | match |
| Short run | SE se | 0.0903 | 0.0903 | match |
| Short run | Constant coef | 0.587 | 0.587 | match |
| Short run | Constant se | 0.0155 | 0.0155 | match |
| Short run | SE\*Shortrun coef | 1.741 | 1.741 | match |
| Short run | SE\*Shortrun se | 0.885 | 0.885 | match |
| All columns | Studies | 121 | 121 | match |
| All columns | Observations | 3,186 | 3,186 | match |
| Translog | SE coef | 0.664 | NA | miss (blocked) |
| Translog | Constant coef | 0.529 | NA | miss (blocked) |

**32 of 34 targeted cells match exactly. 2 are blocked by a missing input.**

## Misses

Both misses are the same root cause:

- **Translog column (SE coef, Constant coef)**: the do-file builds
  `translog = 1 if formula_code==6 | formula_code==7`, and `formula_code`
  is in turn built (lines 58-72) from a raw string variable named `formula`
  (values like `"translog"`, `"1/sig"`, `"Kmenta"` etc. — the transformation
  applied to a study's reported regression coefficient to obtain `sigma`).
  `formula` is **not** among the 115 published columns of `sigma.csv` (the
  brief's column list was checked in full, and the live CSV header was
  re-checked directly — no `formula`, `formula_code`, `limit_val`, `idmax`,
  or `perstudy` column exists in the published file either). There is no
  proxy for it among the published dummies: the CES/translog method dummies
  that do exist (`e_cesnonlin`, `e_ceslinapprox`, `e_sys_cesfoc`, etc.)
  describe how the elasticity was *estimated*, not which algebraic formula
  converted a raw coefficient into `sigma`, and the do-file file never
  derives one from the other. This is a genuine missing-input gap in the
  published data, not a coding choice — cause: `unresolved`.
- The **"All" column** of Table 5 (which pools all six interaction terms,
  including `se_translog`) is excluded from this package for the identical
  reason: it cannot be built without `translog`.

No repair was attempted for these two cells — the task's repair budget
covers sample filters, variable construction, and mis-read targets, not
inventing data that the site does not publish.

## Notes

- `xtset idstudy` appears repeatedly in the do-file (lines 10, 201, 254) but
  is a no-op panel declaration, not a computation; `st_xtreg_fe()`'s `panel`
  argument plays the same role.
- The table's footnote states standard errors are "clustered at the study
  and country level," but the do-file's actual `xtreg ..., fe cluster
  (idstudy)` calls (lines 256-261) cluster on `idstudy` only. The code was
  trusted over the footnote text (which reads like boilerplate shared with
  a different table in the paper), and this call was verified: it reproduces
  every printed SE in this table on the nose, including cells with an
  order-of-magnitude difference (0.0155 vs 0.885), which would not happen
  under a different clustering scheme.
- All numbers in this table are deterministic (OLS/FE with cluster-robust
  SEs) — no bootstrap or simulation is involved, so there is no stochastic
  category here.

## Verdict

**PARTIAL.** The package runs start to finish with `Rscript run.R`, reading
only the site's published `sigma.csv`. Every one of the 32 deterministic
cells that could be constructed from the published data — across five of
Table 5's seven columns, plus the shared Studies/Observations row — matches
the printed value exactly at its printed precision. The remaining two cells
(and the "All" column) are blocked by one missing published variable
(`formula`), not by any mismatch in the reproduced numbers.
