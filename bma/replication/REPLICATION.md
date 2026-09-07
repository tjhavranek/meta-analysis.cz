# bma -- replication of Table 4 ("Test of publication bias")

Paper: Havranek & Irsova, "Determinants of Horizontal Spillovers from FDI: Evidence from a
Large Meta-Analysis," *World Development* 42 (2013).
DOI: https://doi.org/10.1016/j.worlddev.2012.07.001

## Table and provenance

Table 4 is the headline result targeted here. It reports a funnel-asymmetry / precision-effect
test of publication selection in two columns: (1) study fixed effects, (2) study and country
fixed effects. Both are described as "Estimated by weighted least squares with the precision
(the inverse of standard error) taken as the weight," with standard errors clustered at the
study level.

The author's own do-file, `determinants.do`, does not run this as a literal `regress e se
[aweight=prec]`. Instead (lines 17, 135-136 in the brief's line numbering):

```
gen prec=1/se
...
xtset idstudy
xtreg t prec, fe vce(cluster idstudy)
```

`t` (the coefficient's own t-statistic, e/se) is already a column in the published data. Dividing
the level regression `e = b0 + b1*se + u` through by `se` gives
`t = b0*(1/se) + b1 + u/se = b0*prec + b1 + v` -- an unweighted OLS regression of `t` on `prec`
is algebraically the weighted regression of `e` on `se` with the implied variance weight, done
without ever passing a `weights=` argument. Under a fixed-effects `xtreg`, the coefficient on
`prec` is Stata's reported constant term (b0), and the model's own `_cons` is the coefficient on
`se` (b1) -- i.e. the two rows swap places relative to the untransformed regression. This
identity was validated numerically below: the coefficient on `prec` (0.021, se 0.015) and the
model constant (-0.325, se 0.262) reproduce Table 4 column 1 to three decimals, including the
p-values, which only happens if both the sample and the transformation are exactly right.

No second estimation line survives the do-file scan for column 2 (country fixed effects added):
the extraction keeps every line matching `ivreg2|xtreg|regress|reg|areg|reghdfe|...`, and only
one `xtreg`/`regress` line exists in the excerpt. Column 2 is therefore reproduced as the natural
Stata idiom for "study AND country fixed effects" given that only `xtreg` (single-panel FE) is
evidenced: study absorbed as the `xtreg` panel, country entered as explicit `i.idcountry` dummies,
same clustering --

```
xtreg t prec i.idcountry, fe vce(cluster idstudy)
```

This reproduces the column-2 "Constant" row (coefficient on `prec`) exactly, including the
p-value (0.183), which is a specific enough match that it is very unlikely to be the wrong
specification. Its "Se (publication bias)" row -- the model's own `_cons` in a fixed-effects
regression that also carries country dummies -- is not reproduced: `st_xtreg_fe_cons` (the
package's only wrapper for an `xtreg,fe`-reported constant) supports only the bivariate `y ~ x`
case, and a naive grand-mean identity (`mean(t) - sum(beta_k * mean(x_k))` over all regressors)
does not reproduce it once country dummies are added (tested: gives -0.065, nowhere near the
printed -0.284), so it is reported as not computed rather than guessed.

## Sample construction

`determinants.do` lines 14, 26 and 123 (81 in the brief's numbering):

```
drop if aux==1
drop if horiz!=1
drop if abs(e)>10
```

applied in that order to the published `bma.csv` (4,147 rows) leaves exactly **1,199**
observations -- matching the paper's printed N for both Table 4 columns precisely, and
confirming the sample filter is right before any regression is run.

## Target-by-target results

| # | Target | Printed | Produced | Verdict |
|---|---|---|---|---|
| 1 | T4 col1 Constant coef | 0.021 | 0.021430 | MATCH |
| 2 | T4 col1 Constant SE | 0.015 | 0.014665 | MATCH |
| 3 | T4 col1 Constant p | 0.150 | 0.150068 | MATCH |
| 4 | T4 col1 Se(pub.bias) coef | -0.325 | -0.325028 | MATCH |
| 5 | T4 col1 Se(pub.bias) SE | 0.262 | 0.262003 | MATCH |
| 6 | T4 col1 Se(pub.bias) p | 0.220 | 0.220449 | MATCH |
| 7 | T4 col1 N | 1,199 | 1,199 | MATCH |
| 8 | T4 col2 Constant coef | 0.021 | 0.020685 | MATCH |
| 9 | T4 col2 Constant SE | 0.015 | 0.015315 | MATCH |
| 10 | T4 col2 Constant p | 0.183 | 0.182774 | MATCH |
| 11 | T4 col2 Se(pub.bias) coef | -0.284 | NA | MISS |
| 12 | T4 col2 Se(pub.bias) SE | 0.305 | NA | MISS |
| 13 | T4 col2 Se(pub.bias) p | 0.357 | NA | MISS |
| 14 | T4 col2 N | 1,199 | 1,199 | MATCH |

11 of 14 targets matched. All three misses are the same cell family (column 2's
"Se (publication bias)" row) and share one cause.

## Misses

- **T4 col2 Se(pub.bias) coef / SE / p** -- not computed. Cause: the package's `xtreg,fe`
  constant wrapper (`st_xtreg_fe_cons`) is built for the bivariate `y ~ x` case only, and no
  wrapper here handles a fixed-effects model's reported constant when other covariates (here,
  22 surviving country dummies) are also in the regression. A hand-rolled grand-mean identity
  was tried and rejected because it does not reproduce the already-validated column-1 logic
  once covariates are added (see above) -- reporting a guessed number here would risk exactly
  the "close but wrong by a hidden convention" failure mode this package is built to avoid, so
  it is left unresolved rather than repaired by picking whichever formula lands nearest 0.284.
  No repair was attempted (this needs a different wrapper, not a sample/construction/target fix).

## What was NOT attempted

Table 1 (descriptive statistics) and the BMA model-inclusion results (Figure 3) were in the
brief's candidate list but are not reproduced here: Table 4 was chosen as the headline
quantitative target per the task's instruction to pick one table, and BMA itself (posterior
inclusion probabilities from a Bayesian model-averaging search over 43 candidate regressors) has
no wrapper in `stata_compat.R` and was out of scope for this exercise regardless.

## Run

```
Rscript run.R
```
reads only `data/v1/bma/bma.csv` (the file the site publishes), prints every produced number, and
writes `results.json`. No manual steps.
