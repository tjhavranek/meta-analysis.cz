# Replication: "Natural Resources and Economic Growth: A Meta-Analysis" (World Development, 2016)

Havránek, Horváth & Zeynalov, *World Development* 88, 134–151.

**Table reproduced:** Table 3, "Tests of the true effect and publication selection" — Panel A
(Clustered OLS / IV estimation) and Panel B (Fixed effects / Mixed-effects ML regression).

**Result: 24 of the 30 recorded cells reproduce.** All six that do not are cells where the
paper's printed number disagrees with the authors' own Stata output. None of them is a data or
estimator problem, and none is approximated here. Details below, with the evidence.

---

## Data

`data/v1/resource_curse/resource_curse.csv` — 605 estimates from 43 studies. Checked against the
site's own `resource_curse/resource_curse.dta`: same 112 columns, same 605 rows, and every
variable used here (`PCC`, `PCC_SE`, `prec`, `instrument`, `TSTAT`, `INVSE`, `ID`, `DF`) agrees to
float storage precision — the largest difference is 6e-5 on `prec`, whose values run into the
thousands. Rebuilding `PCC`, `PCC_SE` and `prec` from `EFFECT_SIZE` per the do-file changes no
estimate past the seventh digit. The data are not the problem anywhere in this table.

## Specification

The full do-file is published at `site/resource_curse/resource_curse.do`. The Table 3 block is
lines 164–167:

```
164  eststo: reg PCC PCC_SE [pweight=prec], cluster (ID)                 -> Panel A col 1
165  eststo: ivreg PCC (PCC_SE=instrument) [pweight=prec], cluster(ID)   -> Panel A col 2
166  eststo: xtreg TSTAT INVSE, fe vce(cluster ID)                       -> Panel B col 1
167  eststo: xtmixed PCC PCC_SE || ID: [pweight=prec]                    -> Panel B col 2
```

Three things in those lines are easy to miss and all three matter: the IV command is the old
Stata `ivreg` (retired in Stata 10, regress-style small-sample statistics), not `ivreg2`; the
mixed model carries a Stata *sampling* weight, which is not the same object as a precision
weight; and — the point of the next section — the `cluster` options on lines 164–165 were not
there when the table was produced.

---

## Three findings that decide the table

### 1. Panel A is heteroskedasticity-robust, not study-clustered

The table note says "The standard errors of the regression parameters are clustered at the study
level", and lines 164–165 carry `cluster (ID)`. Run that way on Stata 15.1 with the site's own
data, the coefficients come out exactly right and every t-statistic is wrong by about a factor of
three:

| | printed | `cluster(ID)` | robust (no cluster) |
|---|---|---|---|
| OLS, SE row | −5.18 | −1.73 | **−5.18** |
| OLS, constant | 1.69 | 0.87 | 1.61 |
| IV, SE row | −4.81 | −1.74 | **−4.81** |
| IV, constant | 2.41 | 1.12 | **2.41** |

The printed F-statistic settles it independently: Table 3 reports F = 26.87 for the OLS column,
and 26.87 = (−5.1834)² — the robust t squared. (The paper labels it F(1,42), which is the
clustered degrees of freedom; the value is the unclustered one.)

This is not an inference from the numbers alone. The version of the script that produced the
table has no `cluster` option on either line. The authors' own run log — `natural_resource.log`,
and the script beside it, `nat_res_meta_paper_results.do`, neither of which the site ships —
records

```
. eststo: reg PCC PCC_SE [pweight=prec]
       PCC_SE |  -1.016527    .196112    -5.18   0.000
        _cons |   .0260833   .0162477     1.61   0.109
. eststo: ivreg PCC (PCC_SE=instrument) [pweight=prec]
       PCC_SE |  -1.234917     .25686    -4.81   0.000
        _cons |   .0386915   .0160392     2.41   0.016
```

`cluster (ID)` was added to the do-file afterwards and Table 3 was never re-estimated. Panel B's
fixed-effects column, by contrast, genuinely is `vce(cluster ID)` and matches exactly, so the two
panels really do use different variance estimators despite the single shared table note. (The log
is cited as provenance only; `run.R` reads nothing but the site's published CSV.)

### 2. The IV column is `ivreg`, not `ivreg2`

`ivreg` reports regress-style statistics — the robust variance times N/(N−K), inference against
t(N−K) — where `ivreg2` without `small` is large-sample z. Here that is the difference between a
printed −4.81 / 2.41 and a large-sample −4.82 / 2.42. Confirmed on Stata 15.1:
`ivregress 2sls PCC (PCC_SE=instrument) [pweight=prec], small` returns −1.234917 (.25686),
t = −4.81 and .0386915 (.0160392), t = 2.41 — the printed cells. `st_ivreg2()` refuses
`small = TRUE` by design, so `run.R` applies the N/(N−K) factor to its output; it is the
documented Stata adjustment for the command the authors ran, and it does not touch the point
estimates.

### 3. The Mixed column is a *sampling*-weighted model, and needed a new wrapper

`xtmixed PCC PCC_SE || ID: [pweight=prec]` is a random-intercept model in which the weight is an
exponent on each conditional density, not a scaling of the residual variance:

```
ll = sum_g  log INTEGRAL  prod_i f(y_ig | u_g)^{w_ig}  phi(u_g; 0, sigma_u^2) du_g
```

`lmer(..., weights = prec)` fits the other thing, and here the two are nowhere near each other:
lmer returns a constant of −0.13453 and a residual variance of 2.73 against Stata's −0.13334 and
0.0128. Because the weight enters as an exponent, no data transform converts one into the other,
and no R mixed-model package implements Stata's version. It was therefore added to the shared
layer as `st_xtmixed_pw()`, which maximises that pseudo-likelihood directly and takes the
cluster-robust sandwich Stata forces under pweights. Validation against Stata 15.1, which itself
reproduces the authors' 2016 log line for line:

| | Stata / authors' log | `st_xtmixed_pw()` |
|---|---|---|
| log pseudolikelihood | 90785.656 | 90785.6572 |
| PCC_SE | 0.0900781 | 0.09007805 |
| _cons | −0.1333425 | −0.13334253 |
| sd(_cons) | 0.2831274 | 0.28312724 |
| sd(Residual) | 0.1131052 | 0.11310522 |
| robust SE, PCC_SE | 0.6660147 | 0.66603483 |
| robust SE, _cons | 0.0934048 | 0.09341716 |

The two standard errors differ in the fifth significant digit, which is the numerical Hessian;
every printed cell rounds identically under both.

---

## Cell-by-cell

### Reproduces (24)

| cell | paper | produced |
|---|---|---|
| N, both panels; groups, Panel B | 605 / 43 | 605 / 43 |
| OLS, SE row: t, p | −5.18, 0.000 | −5.1834, 3.0e-07 |
| OLS, constant: coefficient | 0.026 | 0.0260833 |
| IV, SE row: t, p | −4.81, 0.000 | −4.8077, 1.9e-06 |
| IV, constant: t, p | 2.41, 0.016 | 2.4123, 0.01615 |
| FE, SE row: coefficient, t, p | −0.011, −0.58, 0.563 | −0.0113676, −0.5823, 0.56347 |
| FE, constant: coefficient, t, p | −0.589, −2.64, 0.011 | −0.5890386, −2.6434, 0.011488 |
| Mixed, SE row: coefficient, z, p | 0.090, 0.14, 0.892 | 0.0900780, 0.13525, 0.89242 |
| Mixed, constant: coefficient, p | −0.133, 0.153 | −0.1333425, 0.15347 |

### Does not reproduce (6) — every one is the paper disagreeing with its own Stata output

**(a) Three coefficients the paper truncated instead of rounding.**

| cell | Stata | correctly rounded | paper prints |
|---|---|---|---|
| OLS, SE row | −1.016527 | −1.017 | −1.016 |
| IV, SE row | −1.234917 | −1.235 | −1.234 |
| IV, constant | 0.0386915 | 0.039 | 0.038 |

The authors' own `esttab` output for these same regressions (`table3.tex`, written by line 169 of
the do-file) prints −1.017, −1.235 and 0.039 — correctly rounded. Table 3 in the paper prints the
truncated forms. Every coefficient cell in the paper that distinguishes the two rules goes the
truncation way, here and again in appendix Table A.1 Panel C (−0.15788 → −0.157, 0.30884 → 0.308);
none goes the other way. The estimates below are exact and unaltered, so these three cells fail a
round-to-three-decimals check by construction. That is a property of the paper's typesetting, not
of the estimation, and reproducing it would mean printing a wrong number on purpose.

**(b) The OLS constant's t-statistic and p-value are misprinted.**

Table 3 prints `0.026*` with t = 1.69 and p = 0.099. The authors' log for that exact regression
reads `_cons .0260833 .0162477 1.61 0.109`, and Stata 15.1 on the published data returns the same.
No variance estimator recovers 1.69: clustered gives 0.87, unweighted-OLS-style gives 1.92, robust
gives 1.61. The p-value moved with the t (0.109 → 0.099) and the cell also carries a significance
star that `table3.tex` does not have, so the printed row is significant at 10% where the estimated
one is not. The correct values, 1.61 and 0.109, are what `run.R` produces; the targets are 1.69 and
0.099, so these two cells are recorded as misses.

**(c) The Mixed constant's z lost its minus sign.**

Table 3 prints the constant as −0.133 with z = +1.43 and p = 0.153. A positive z cannot belong to
a negative coefficient with that p-value, and the authors' log reads
`_cons -.1333425 .0934048 -1.43 0.153`. `run.R` produces −1.4274. The target is +1.43, so the cell
is recorded as a miss rather than sign-flipped to match.

---

## Reproducing this

```
Rscript run.R
```

R 4.x with `fixest` and `metafor`. `run.R` sources `stata_compat.R` and calls only its wrappers —
`st_regress`, `st_ivreg2`, `st_xtreg_fe`, `st_xtreg_fe_cons`, `st_xtmixed_pw`, `st_coefs`. It
reads one file, the published CSV, and writes `results.json`.

**Change to the shared layer.** This package added `st_xtmixed_pw()` to `stata_compat.R`. The
addition is purely additive — no existing wrapper's code or behaviour was touched, so no other
package can change — and `test_compat.R` passes on the amended file. `compat.sha256` will need
re-blessing; it was already stale before this package's work began.
