# Replication package: "Cross-Country Heterogeneity in Intertemporal Substitution"

Journal of International Economics, 2015. doi: https://doi.org/10.1016/j.jinteco.2015.01.012

## Table reproduced

**Table 7**, "Frequentist check (OLS)" columns (Coef., Std. er., p-value) — robustness check
using alternative proxies for liquidity constraints and institutions (financial reform instead
of credit availability; generalized trust instead of rule of law).

Only this half of Table 7 is reproduced. The other half of the same table (Bayesian model
averaging: posterior mean, posterior std. dev., PIP) is a BMA estimation for which no
wrapper exists in `stata_compat.R` and no author BMA code was supplied in the brief — see
"Unsupported" below.

## Provenance

`author_code`. The author's do-file `eis_det.do` contains the exact regression command
reproduced here, at line 191:

```stata
reg eis marketpartic gdppc finref realrate trust inverse top totalc lnyears ols irstock
    stockhold lnyearcits ircap sepdur if abs(eis)<10, vce(cluster idcountry)
```

Variable order in this command matches the row order of Table 7's frequentist columns exactly
(Stock market partic. = `marketpartic`, GDP per capita = `gdppc`, Financial reform = `finref`,
Real interest = `realrate`, Trust = `trust`, Inverse estimation = `inverse`, Top journal =
`top`, Total consumption = `totalc`, No. of years = `lnyears`, OLS = `ols`, Stock return =
`irstock`, Asset holders = `stockhold`, Citations = `lnyearcits`, Capital return = `ircap`,
Nonsep. durables = `sepdur`), and the resulting N (2254, computed independently from the
published CSV before ever running the regression — see below) matches the table's printed
"Observations 2254" exactly. That match, together with the variable-order match, is what
identifies this do-file command as the source of the target cells.

Two upstream steps come from earlier in the same do-file and were applied before the
regression, exactly as written there:

- Line 100: `drop if abs(eis)>=10` (re-stated at the regression as `if abs(eis)<10`).
- Line 80: `replace gdppc = ln(gdppc)` — the do-file overwrites `gdppc` with its own log in
  place, so every later use of `gdppc` (including in this regression) is the log, not the level.
- Lines 73/75: `gen lnyears = ln(years)`, `gen lnyearcits = ln(yearcits + 1)`.

The cluster variable (`idcountry`) is legible from the do-file line itself (`vce(cluster ...`
is cut off in the brief's excerpt, but `idcountry` is the only country-level clustering
variable in the dataset and is used identically in the file's other `reg` commands at lines
122, 140, 157). The resulting SEs match the printed SEs to 3 decimals for all 16 rows, which
confirms this reading.

## Method

- `st_regress()` from `stata_compat.R`, which implements Stata `regress ..., vce(cluster g)`
  as `fixest::feols()` with fixest's *default* small-sample correction (the convention noted
  in `stata_compat.R` as matching Stata `regress`, as opposed to the large-sample `ivreg2`
  convention used elsewhere on this site).
- Coefficients and standard errors are read via `summary(m)$coeftable`. `st_coefs()` was not
  used for this table because it only ever reports z-based p-values (`p.value = NA` when
  `z = FALSE`), while Stata's `regress` prints t-based p-values with `df = G - 1` (number of
  clusters minus one). `summary()` on the same `fixest` model object already applies exactly
  that t-based inference — it is the model's own accessor, not a different vcov or estimator —
  so the coefficient table is read from there instead of recomputed by hand.
- No estimator, clustering, weighting, winsorising, or degrees-of-freedom convention was
  changed from what `stata_compat.R` already fixes for `st_regress()`.

## Sample-count cross-check (done before running any regression)

Before touching `stata_compat.R`, N = 2254 was verified independently in Python by applying
listwise deletion on the 16 model variables plus `abs(eis) < 10` to the published CSV — it
returned exactly 2254, matching Table 7's "Observations" row and confirming both the variable
set and the sample filter before any R code was written.

## Targets: printed vs. produced

All values from Table 7, "Frequentist check (OLS)" columns. A cell matches when the produced
value rounds to the printed value at the printed precision (3 decimals for coefficients/SEs/
p-values, exact for N).

| Variable | Printed coef | Produced coef | Printed SE | Produced SE | Printed p | Produced p | Verdict |
|---|---|---|---|---|---|---|---|
| Stock market partic. (`marketpartic`) | 2.342 | 2.342 | 0.848 | 0.848 | 0.011 | 0.011 | OK |
| GDP per capita (`gdppc`, logged) | 0.198 | 0.198 | 0.114 | 0.114 | 0.095 | 0.095 | OK |
| Financial reform (`finref`) | -0.777 | -0.777 | 0.394 | 0.394 | 0.060 | 0.060 | OK |
| Real interest (`realrate`) | 0.023 | 0.023 | 0.032 | 0.032 | 0.493 | 0.493 | OK |
| Trust (`trust`) | -0.005 | -0.005 | 0.004 | 0.004 | 0.257 | 0.257 | OK |
| Inverse estimation (`inverse`) | 0.627 | 0.627 | 0.103 | 0.103 | 0.000 | 0.000 | OK |
| Top journal (`top`) | 0.602 | 0.602 | 0.114 | 0.114 | 0.000 | 0.000 | OK |
| Total consumption (`totalc`) | 0.416 | 0.416 | 0.147 | 0.147 | 0.009 | 0.009 | OK |
| No. of years (`lnyears`) | -0.228 | -0.228 | 0.058 | 0.058 | 0.001 | 0.001 | OK |
| OLS (`ols`) | 0.443 | 0.443 | 0.189 | 0.189 | 0.028 | 0.028 | OK |
| Stock return (`irstock`) | -0.299 | -0.299 | 0.136 | 0.136 | 0.037 | 0.037 | OK |
| Asset holders (`stockhold`) | 0.406 | 0.406 | 0.130 | 0.130 | 0.005 | 0.005 | OK |
| Citations (`lnyearcits`) | -0.093 | -0.093 | 0.057 | 0.057 | 0.119 | 0.119 | OK |
| Capital return (`ircap`) | -0.265 | -0.265 | 0.061 | 0.061 | 0.000 | 0.000 | OK |
| Nonsep. durables (`sepdur`) | 0.465 | 0.465 | 0.273 | 0.273 | 0.101 | 0.101 | OK |
| Constant | -0.797 | -0.797 | 1.093 | 1.093 | 0.473 | 0.473 | OK |
| Observations | 2254 | 2254 | — | — | — | — | OK |

49/49 target cells matched. No repairs were needed.

## Misses

None.

## Unsupported

The Bayesian model averaging half of Table 7 (Post. mean / Post. std. dev. / PIP columns) is
**not** attempted. `stata_compat.R` has no BMA wrapper (Stata's `bma`/`wbma` command family,
or the `bms` R package's equivalent), the brief's author-code excerpt for `eis_det.do`
contains no BMA-fitting lines, and the task instructions forbid substituting an estimator the
package does not provide a wrapper for. `unsupported_command`: BMA (Bayesian model averaging).

## How to run

```
Rscript run.R
```

Reads `substitution.csv` from the site's published data path, runs start to finish, prints
every target value, and writes `results.json`.
