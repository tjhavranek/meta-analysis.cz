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

## Numbers from the paper's text

meta-analysis.cz summarises this paper as: **"income and asset market participation are
the most effective factors explaining cross-country differences."** That sentence
paraphrases the paper's own Abstract: *"Our results suggest that income and asset market
participation are the most effective factors in explaining the heterogeneity: households
in rich countries and countries with high stock market participation substitute a larger
fraction of consumption intertemporally..."*

The paper backs that claim with four numbers in the running text (Introduction and
Section 4), all of them **Bayesian model averaging (BMA) posterior means** — not the
frequentist/OLS checks reproduced in Table 7 above:

1. Introduction: *"a 10-percentage-point increase in the rate of stock market
   participation is associated with an increase in the EIS of 0.24."* Section 4 names
   the source: *"the estimated posterior mean for the regression coefficient... is
   2.4"* — the core-countries BMA specification (same table as Table 2), 2.4 × 0.10.
2. Introduction: *"studies estimating the EIS using a sub-sample of rich households or
   asset holders find on average an EIS larger by 0.21."* — BMA posterior mean for
   "Asset holders" in the core-countries specification (Table 2: post. mean 0.210).
3. Section 4: *"the estimate tends to be substantially larger as well: by 0.35."* — BMA
   posterior mean for "Asset holders" in the all-countries specification (Table 1:
   post. mean 0.349).
4. Section 4 / Table 3, "The economic significance of differences in country
   characteristics": *"Out of the five country-level variables, stock market
   participation has the largest effect, followed by GDP per capita. The other
   variables do not seem to matter much."* Table 3 gives, for each variable, a
   "maximum effect" (BMA coefficient × sample range) and "standard-deviation effect"
   (BMA coefficient × sample SD) — this table is the paper's direct quantitative case
   for "most effective factors."

`stata_compat.R` has no BMA wrapper (no equivalent of Stata's `bma`/`wbma`, or the R
`bms` package), and the brief's author-code excerpt has no BMA-fitting lines — the same
reason the BMA half of Table 7 is unsupported (see below). **The BMA posterior means
behind numbers 1–4 above cannot be reproduced with the tools this package is restricted
to**, and nothing below is adjusted to force a match with them.

What run.R does instead: it reproduces, with `st_regress()`, the **frequentist/OLS
counterpart** the paper itself prints side by side with each BMA number, in the same two
tables (Table 1, all countries; Table 2, core countries) the BMA posterior means above
come from — `eis_det.do` lines 122 and 140 respectively. The paper states explicitly
that "the results of the frequentist check are very similar to the BMA results" (Section
4), so this is the paper's own robustness check on the same numbers, not a substitute
chosen after the fact.

**Table 1 (all countries) and Table 2 (core countries), frequentist check — full match.**
All 16 reproduced cells (5 country-level coefficients × {coef, SE, p} plus both N's) round
to the paper's printed values exactly:

| Table | Variable | Printed coef | Produced | Printed SE | Produced | Printed p | Produced |
|---|---|---|---|---|---|---|---|
| 1 (all countries) | GDP per capita | 0.126 | 0.126 | 0.084 | 0.084 | 0.138 | 0.138 |
| 1 | Credit availability | -0.033 | -0.033 | 0.055 | 0.055 | 0.553 | 0.553 |
| 1 | Real interest | -0.003 | -0.003 | 0.006 | 0.006 | 0.635 | 0.635 |
| 1 | Rule of law | -0.019 | -0.019 | 0.074 | 0.074 | 0.800 | 0.800 |
| 1 | Asset holders | 0.421 | 0.421 | 0.089 | 0.089 | 0.000 | 0.000 |
| 2 (core countries) | Stock market partic. | 2.221 | 2.221 | 0.542 | 0.542 | 0.000 | 0.000 |
| 2 | GDP per capita | 0.116 | 0.116 | 0.138 | 0.138 | 0.405 | 0.405 |
| 2 | Asset holders | 0.372 | 0.372 | 0.143 | 0.143 | 0.015 | 0.015 |
| — | N (Table 1) | 2526 | 2526 | | | | |
| — | N (Table 2) | 2254 | 2254 | | | | |

**The headline (BMA-based) quantities — reproduced OLS counterpart, honestly not identical:**

| # | Claim | Paper value (BMA) | Reproduced (OLS) | Verdict |
|---|---|---|---|---|
| 1 | 10pp ↑ stock mkt. partic. → ΔEIS | 0.24 | 0.222 (Table 2 marketpartic × 0.10) | Same order of magnitude and direction; not identical — OLS point estimate (2.221) vs. BMA posterior mean (2.4) |
| 2 | EIS premium, asset holders, core countries | 0.21 | 0.372 (Table 2 stockhold coef) | Same sign, larger in OLS — BMA shrinks toward zero because the variable's posterior inclusion probability is only 0.558 (i.e. BMA averages in models that exclude it); OLS always includes it |
| 3 | EIS premium, asset holders, all countries | 0.35 | 0.421 (Table 1 stockhold coef) | Same pattern; PIP = 0.849 here, so less shrinkage than in row 2, and the OLS/BMA gap is correspondingly smaller |
| 4a | Econ. significance, max effect: stock mkt. partic. | 0.931 | 0.846 | Same order of magnitude |
| 4a | Econ. significance, max effect: GDP per capita | 0.683 | 0.621 | Same order of magnitude |
| 4a | Econ. significance, max effect: credit availability | -0.119 | -0.104 | Same order of magnitude |
| 4a | Econ. significance, max effect: real interest | -0.265 | -0.148 | Same sign, smaller magnitude |
| 4a | Econ. significance, max effect: rule of law | -0.087 | -0.070 | Same order of magnitude |
| 4b | Econ. significance, SD effect (all 5 vars) | 0.141 / 0.088 / -0.020 / -0.019 / -0.012 | 0.126 / 0.075 / -0.017 / -0.011 / -0.010 | Same order of magnitude and, for every variable, the same sign |

**What is actually reproduced, and what is not.** Rows 1–3 are not exact matches, and
should not be read as such: they compare a BMA posterior mean (a weighted average across
many candidate models, each variable's weight given by its posterior inclusion
probability) against a single OLS point estimate from one fully-specified model. The gap
between the two grows with how far a variable's posterior inclusion probability is below
1 — exactly what row 2 (PIP 0.558, larger OLS/BMA gap) versus row 3 (PIP 0.849, smaller
gap) shows. What *is* fully reproduced, and is the load-bearing result for the
"most effective factors" claim: **the ranking**. By |max effect| in row 4, the
OLS-reproduced ordering is stock market participation (0.846) > GDP per capita (0.621) >
real interest (0.148) > credit availability (0.104) > rule of law (0.070) — the identical
ordering to the paper's own BMA-based Table 3. Income (GDP per capita) and asset market
participation (stock market participation, asset holders) are the two largest-magnitude,
correctly-signed effects among the country-level variables under OLS just as they are
under BMA; that ranking, not any single decimal figure, is the paper's actual evidence
for "most effective factors," and it survives switching estimators completely.

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
