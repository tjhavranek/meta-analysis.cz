# Replication package: sigma

**Paper**: Gechert, S., Havranek, T., Irsova, Z. & Kolcunova, D. (2022). "Measuring
Capital-Labor Substitution: The Importance of Method Choices and Publication Bias."
*Review of Economic Dynamics* 45, 55–82. https://doi.org/10.1016/j.red.2021.05.003

**Reproduced**: Table 5, "Potential sources of endogeneity" — five of its seven
columns in full (Identif., Data aggr., Results aggr., K: perpetual, Short run),
plus the Studies/Observations row; and the numbers the paper states in its own
text (abstract, Section 1, Section 4.1). The Translog and All columns are
blocked by a variable the site does not publish.

**Provenance**: author_code. `sigma.zip:sigma.do` lines 9–38 (data prep), 54
(`stacoudata`), 83 (`winsor2`), 240–262 (interaction terms and the seven
`xtreg ..., fe cluster(idstudy)` columns).

**Data**: `site/data/v1/sigma/sigma.csv` (3,186 rows × 115 columns, 121
studies) — the only file read.

## Score

**35 of 39 scored targets reproduce exactly at printed precision.** Four do
not, and none of the four is a coding defect that this package can repair:
two are blocked by a missing published variable, one is a disagreement
between the paper's text and the paper's own data, and one is a target that
records a verbal bound as a number.

## Method

1. `replace se = 0.001 if se == 0` (line 25; no published row hits it, applied
   for fidelity).
2. `stacoudata = stadata + coudata` (line 54).
3. `winsor2 sigma se, cuts(5 95)` → `sigma_win5`, `se_win5` via `st_winsor2()`
   (each variable winsorized at its own 5th/95th percentile, Stata `_pctile`
   /quantile type 2 — not R's default type 7).
4. Interactions `se_X = se_win5 * X` for `X` in `identif`, `stacoudata`,
   `ind_disagg`, `k_perpet`, `shortrun_expl` (lines 240–252).
5. Each column: `xtreg sigma_win5 se_win5 se_X X, fe cluster(idstudy)` through
   `st_xtreg_fe()`, cluster defaulting to the panel `idstudy` (line 260).
6. The "Constant" row is Stata's `xtreg, fe` reported `_cons`,
   `cons = ybar − Σ_j beta_j·xbar_j` over every regressor in the column.
   `stata_compat.R`'s `st_xtreg_fe_cons()` implements that identity for a
   single regressor only. Rather than fitting a second model with a bare
   `feols()`/`lm()` (forbidden), the multivariate constant is obtained by
   linear algebra on the already-fitted wrapper model: `cons = ybar − betaᵀ·xbar`,
   and, `cons` being linear in `beta`, `Var(cons) = xbarᵀ·vcov(m)·xbar` using
   the model's own cluster-robust `vcov`.

### The two conventions, checked against Stata rather than assumed

Both were re-derived in Stata 15.1 on the published `sigma.dta`
(`stata_work_sigma/probe1.do`), not inferred from the printed table:

```
xtreg sigma_win5 se_win5, fe cluster(idstudy)
     se_win5 |   .6562768   .2009188
       _cons |   .5286297    .032816
```

which is Table 1's FE column, printed as 0.656 (0.201) and 0.529 (0.033). Two
things follow. First, the linear-algebra constant above is right: it returns
0.5286297 (0.0328160), Stata's `_cons` to seven digits. Second, Table 5's
footnote — "standard errors ... clustered at the study and country level" — is
loose. Clustering this regression on study *and* country gives 0.0839 where
the paper prints 0.201; clustering on study alone gives 0.2009. The do-file
clusters on `idstudy` only (lines 224, 260), and that is what reproduces every
printed standard error in Table 5, across cells that differ by an order of
magnitude (0.0155 against 0.885). The code was trusted over the footnote.

Stata also confirms the Table 5 columns cell for cell, e.g. Identif.:
`se_win5 .6491019 (.2187805)`, `se_identif −.0323456 (.3320166)`,
`_cons .5124265 (.0357178)`.

## Target-by-target results

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
| Translog | SE coef | 0.664 | not computed | **miss — blocked** |
| Translog | Constant coef | 0.529 | not computed | **miss — blocked** |
| Text (§1) | mean σ, equal weight per study | 0.9 | 0.867 | match at 1 d.p. |
| Text (§1) | simple mean σ | 0.8 | 0.747 | **miss — text vs. data** |
| Text (Table 1 OLS) | publication-bias coef | 0.881 | 0.881 | match |
| Text (Table 1 OLS) | mean beyond bias | 0.492 | 0.492 | match |
| Text (abstract) | share of the 0.9→0.3 fall from bias | "at least half" | 0.680 | **miss — bound, not a number** |
| Text (Table 9) | "best practice" σ | 0.30 | proxy 0.433 | not scored; not independently reproduced |

## Misses

### 1–2. Table 5, Translog column — blocked by a variable the site does not publish

The do-file (lines 247–249) builds

```
gen translog = 0
replace translog = 1 if formula_code==6 | formula_code==7
```

and `formula_code` (lines 58–72) is built by matching a **raw string
variable `formula`** — "Functional form of sigma actually estimated", with
values such as `"translog"`, `"CES-translog"`, `"Kmenta"`, `"1/sig"`:

```
replace formula_code=6 if formula=="translog"
replace formula_code=7 if formula=="CES-translog"
```

`formula` enters at line 9, `import excel sigma.xlsx, firstrow clear`. The
site does not publish `sigma.xlsx`. What it publishes is the table *after*
that import with the string columns dropped, and it publishes it three times
over — `data/v1/sigma/sigma.csv`, `site/sigma/sigma.parquet` and
`site/sigma/sigma.dta` are the same 3,186 × 115 matrix. None of the 115
columns is `formula`, `formula_code`, `limit_val` or `translog`. Confirmed in
all three files, in the site's own codebook (`api/v1/codebooks/sigma.json`),
and in Stata directly:

```
capture confirm variable formula        -> rc = 111   (does not exist)
capture confirm variable formula_code   -> rc = 111
capture confirm variable translog       -> rc = 111
```

`studies.xlsx` is a 121 × 6 bibliography. `appendix.pdf` and the article PDFs
describe the translog specification in prose and give no per-estimate coding.
No author material for this paper was recovered from the owner's disk either.

**It is not recoverable indirectly, and three routes were tried and closed:**

- *The `t` column.* Had `t` been the originally reported t-statistic of
  f(σ), then `t·se` would equal `f(σ)/|f′(σ)|` and would have identified the
  functional form estimate by estimate. It is not: `t` is populated for 642
  rows, every one of them `viadelta==0`, and on those rows `t == sigma/se`
  exactly. It is the t-statistic of σ itself and carries no formula
  information.
- *The nearest published dummy.* `e_ceslinapprox` is defined in the online
  appendix as "= 1 if the elasticity is estimated via Taylor series expansion
  (Kmenta approach **or** translog approach)". It merges translog with Kmenta,
  so it is a strict superset by construction, and it does not reproduce the
  column. The paper's own 71-variable list has no separate translog dummy.
- *An exhaustive screen.* Every one of the 88 published 0/1 columns was tried
  as `translog`, and so was every OR of two of them — 3,916 candidate
  definitions, each fitted in the Table 5 Translog specification. **None**
  reproduces the printed triple 0.664 / 0.529 / −0.127. The nearest were
  substantively meaningless (`database_OECD`: 0.6645 / 0.5289 / −0.1237;
  `ind_tertiary|l_years`: 0.6679 / 0.5285 / −0.1292).

**What the gap costs.** The same regression without the two translog terms is
Table 1's FE column, and the paper prints all four of its cells. run.R
computes it as a benchmark and prints it:

| | Table 1 FE (no translog terms) | Table 5 Translog (printed) |
|---|---|---|
| SE | 0.6563 (0.2009) | 0.664 (0.212) |
| Constant | 0.5286 (0.0328) | 0.529 (0.0321) |

So the missing dummy is worth about 0.008 on the SE coefficient and nothing
visible on the constant. That all four benchmark cells come back exactly says
the pipeline around the gap is sound; what is missing is one column of data.

**One temptation, named so nobody takes it later.** The benchmark constant is
0.5286, which rounds to the 0.529 that the Translog column prints. Emitting
that value would score the target while answering a different question, so it
is printed as a benchmark and deliberately kept out of `results.json`. Both
Translog cells are reported as not computed.

The **All** column of Table 5 needs `se_translog` too and is out of the
package for the same reason.

### 3. "A simple mean of all estimates is 0.8" — the paper's text against the paper's data

Section 1 reads: *"The mean reported estimate of the elasticity of
substitution is 0.9 when we give the same weight to each study; that is, when
we weight the estimates by the inverse of the number of observations reported
per study. A simple mean of all estimates is 0.8."*

The first figure reproduces exactly: the study-weighted mean is 0.8670149,
matching the do-file's own pasted output (`sum sigma [aweight=invperstudy]`)
digit for digit and rounding to 0.9. The second does not. Stata's `sum sigma`
on the published file returns

```
       sigma |      3,186    .7470532    4.555647    -85.981        200
```

0.747, which rounds to 0.7. No reading of "a simple mean of all estimates"
reaches 0.8, and every neighbouring variant is further away rather than
nearer: winsorised 5/95 gives 0.636, dropping the two extreme estimates gives
0.712, trimming to the [−2, 4] range Fig. 3 plots gives 0.650, the mean of the
121 study-level medians is 0.715, weighting by precision moves it down again.
The arithmetic that does land on 0.8 is rounding twice, 0.747 → 0.75 → 0.8,
which is the likeliest explanation. The computed value is reported as
computed and the target stays missed; nothing was adjusted to close it.

### 4. "Responsible for at least half of the overall reduction" — a bound recorded as a number

The abstract states a bound, not a value: publication bias *"is responsible
for at least half of the overall reduction in the mean elasticity from 0.9 to
0.3."* The paper prints no share anywhere. `targets.json` records 0.5 — the
phrase "at least half" written as a number — and the verifier scores it by
equality at one decimal, which no honest construction of the quantity can
satisfy:

| construction | share |
|---|---|
| with our reproduced corrected mean, (0.9 − 0.4919) / 0.6 | 0.680 |
| with the paper's own rounded 0.5, (0.9 − 0.5) / 0.6 | 0.667 |
| with Table 2's nonlinear corrections (0.52, 0.55, 0.43, 0.50) | 0.58 – 0.78 |

Every one clears the bound the paper actually claims, and every one rounds to
0.7. The paper's claim is confirmed; the recorded target is not matchable.
`targets.json` was not touched.

## Numbers from the paper's text

| Claim | Quantity | Paper | Produced | Verdict |
|---|---|---|---|---|
| "the literature on average, 0.9" | mean σ, weight 1/estimates-per-study | 0.9 | 0.867 | match at 1 d.p. |
| "A simple mean of all estimates is 0.8" | unweighted mean σ, all 3,186 | 0.8 | 0.747 | miss (see above) |
| "the mean elasticity drops from 0.9 to 0.5" | Table 1 OLS `sigma_win5 ~ se_win5`, two-way clustered | γ 0.881, σ₀ 0.492 | γ 0.881, σ₀ 0.492 | exact |
| "at least half of the reduction" | share of the 0.9→0.3 fall | ≥ 0.5 | 0.680 | claim confirmed, target missed |
| "conditional on the absence of these issues is 0.3" | Table 9 best practice | 0.30 (−0.01, 0.60) | proxy 0.433 | not independently reproduced |

Both means are averages of the raw, un-winsorized `sigma`; the weight is the
do-file's own `invperstudy` (1 / estimates reported by that study),
reconstructed here because `perstudy` is not a published column.

**Table 9's 0.30 is not independently reproduced, and is not scored as if it
were.** It is a synthetic-study fitted value from a Bayesian model average
over 71 candidate variables (`bms`: birth-death MCMC, 5,000–10,000 models,
UIP/BRIC g-priors — `sigma.zip:sigma_BMA_FMA.R` lines 54–106) *and* a
frequentist model average, evaluated at the covariate extremes of Section
5.4. `stata_compat.R` has no model-averaging wrapper, deliberately: it is a
hash-locked Stata-parity file and adding an estimator to it is out of scope.
What run.R produces instead is the paper's own published stand-in — Table 7's
"Frequentist check" column, whose note says "we include only explanatory
variables with PIP > 0.8" — as a single `st_regress()` fit on that 20-variable
subset, evaluated at the "best practice" settings Section 5.4 states. That
proxy is **0.433**: inside the paper's own 95% CI for the quantity, but not a
re-derivation of the point estimate, since it omits model-averaging
uncertainty and roughly 50 of the 71 candidate variables. The target is
flagged `headline_not_independently_reproduced` and the verifier does not
score it.

## Notes

- `xtset idstudy` (lines 10, 201, 254) is a panel declaration, not a
  computation; `st_xtreg_fe()`'s `panel` argument plays the same role.
- Every number in Table 5 is deterministic — OLS/FE with cluster-robust
  standard errors. Nothing here is simulated or bootstrapped.
- `invsqrtnobs` and its winsorized form are built for fidelity to the
  do-file and are not used by any reported column.

## Verdict

**PARTIAL, and complete as far as the published data goes.** The package runs
end to end with `Rscript run.R` and reads only `site/data/v1/sigma/sigma.csv`.
Thirty-five of thirty-nine scored targets reproduce exactly, and the four that
do not are accounted for individually above: two need a string variable the
site does not publish, one is a place where the paper's text disagrees with
the paper's own data file, and one is a verbal bound recorded as a numeric
target. No number was approximated, no tolerance was widened, no observation
was dropped, and `targets.json` was not edited.

## To close the two blocked cells

The site would need to publish the `formula` column (or `formula_code`, or
`translog` itself) from the authors' `sigma.xlsx` — one string or integer
column, 3,186 rows, alongside the 115 already published. With it, the Translog
and All columns of Table 5 follow immediately from the code already here.
