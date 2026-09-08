# Replication: "Demand for Gasoline Is More Price-Inelastic than Commonly Thought"

Havranek, Irsova and Janda, *Energy Economics* (2012). This package reproduces the paper's
Tables 4 and 5 in full.

**Status: 70 of 70 printed numbers reproduce exactly, to the last digit the paper prints.**
Nothing is missing, nothing is approximated, and no target is met by a fudge factor.

## Data

`site/data/v1/gasoline_price/gasoline_price.csv` — 202 estimates from 30 studies, 11 columns:
`idstudy, e, se, t, prec, longr, pubdate, cs, tscs, usdata, csection`. The package reads this
published file and nothing else. `prec` is already 1/`se` in the file, and `csection` is
already the cs-or-tscs indicator (`sum(cs) + sum(tscs) == sum(csection) == 136`), so no
variable is constructed here that the site does not ship.

`longr == 0` gives the 110 short-run estimates, `longr == 1` the 92 long-run ones. Both counts
are what Tables 4 and 5 print.

## Specification: recovered, not guessed

An earlier version of this package reconstructed the estimating equation from the paper's
prose. That is no longer necessary. The author's original Stata script survived inside a Word
file and has been recovered, and it settles the specification outright:

```stata
xtset idstudy

* Table 4
xtreg t prec se if longr==0, mle noconstant
xtreg t prec se if longr==1, mle noconstant
reg   t prec se if longr==0, vce(cluster idstudy) noconstant
reg   t prec se if longr==1, vce(cluster idstudy) noconstant

* Table 5
xtreg t prec usdata csection pubdate if longr==0, mle
test  usdata csection pubdate
xtreg t prec usdata csection pubdate if longr==1, mle
test  usdata csection pubdate
reg   t prec usdata csection pubdate if longr==0, vce(cluster idstudy)
test  usdata csection pubdate
reg   t prec usdata csection pubdate if longr==1, vce(cluster idstudy)
test  usdata csection pubdate
```

The response variable is the t-statistic and `prec` = 1/SE, which is the FAT-PET regression
divided through by SE: `e = b0 + b1*SE + u` becomes `t = b0*(1/SE) + b1 + u/SE`. Table 4 adds
`se` as a regressor and drops the constant; Table 5 replaces `se` with the three moderators
and restores the constant.

Every one of these commands was re-run in Stata 15.1 here, on the published csv rather than on
the author's `papers.dta`, and every coefficient, standard error, chi2 and F agrees with the
printed table. The published csv is therefore the same data the paper was written from.

## The one thing that is genuinely subtle: which vcov `xtreg, mle` reports

This is where the package was previously wrong on 16 of the 70 numbers, and it is worth being
precise about, because the two candidate answers are both "the ML mixed model".

Stata's `xtreg, mle` and Stata's `mixed, mle` fit the *same* model and reach the *same*
optimum — identical coefficients, identical variance components, identical log-likelihood
(−260.51144 for Table 4 short run). They report *different* standard errors:

| Table 4, short run | 1/SE | SE |
|---|---|---|
| `xtreg t prec se, mle noconstant` | 0.011954 | 2.093528 |
| `mixed t prec se, nocons \|\| idstudy:, mle` | 0.010625 | 1.960410 |
| **paper, Table 4** | **(0.0120)** | **(2.094)** |

`xtreg, mle` inverts the observed information of the full log-likelihood over the coefficients
*and* the variance parameters (ln sd_u, ln sd_e) jointly, so the fixed-effect block carries the
coefficient/variance cross-derivatives −X'V⁻¹(∂V/∂θ)V⁻¹r. Those are not zero at the realised
residuals. lme4's `vcov()` — and Stata `mixed` here — reports (X'V⁻¹X)⁻¹ instead, the block in
which those cross-derivatives are assumed away. With 30 studies the gap is 1–13% of the SE,
unevenly across coefficients, which is exactly large enough to move the third printed digit.

Every printed mixed-effects SE in Tables 4 and 5, and both mixed-effects Wald chi2 statistics
(which are built on the same matrix), rounds to the `xtreg, mle` value; none rounds to the
lme4/`mixed` value. So the paper ran `xtreg, mle`, as the recovered script says.

`run.R` handles this by separating the fit from the vcov. `st_mixed()` supplies the fit — it is
lmer with `REML = FALSE`, the correct ML estimator, and it lands on the same optimum as Stata.
`oim_vcov_mixed()` then assembles the analytic observed-information Hessian of that same
log-likelihood at that fit and inverts it, reproducing what `xtreg, mle` prints to six decimal
places. This changes no estimate and no variance component; it changes only which matrix is
reported, and it is the matrix the paper reported. The joint-significance Wald chi2 for Table 5
is built on the same matrix, which is why 3.47 and 18.26 come out right as well.

`st_coefs()` is not used for the mixed models: it calls `stats::coef()`, which on a `merMod`
returns a per-group blend of fixed and random effects rather than a coefficient vector. The
fixed-effect table is built here from `lme4::fixef()` with the same estimate/SE/z construction
`st_coefs()` uses. `stata_compat.R` is not modified — the paper's convention lives in this
package, where it belongs, since no other package in the set needs `xtreg, mle`.

## The clustered-OLS columns and the LR test

The OLS columns are `st_regress(..., cluster = ~idstudy)`, which is fixest under Stata's
small-sample cluster convention — the wrapper's default and the right one, since Stata
`regress` applies the finite-sample correction. All 20 OLS numbers in Tables 4 and 5 match,
including both joint-significance F statistics on (3, 29) degrees of freedom.

The "Likelihood-ratio test (χ²)" row of Table 4 is `xtreg`'s own `chibar2` test of sigma_u = 0,
that is, the mixed fit against pooled OLS. `run.R` computes it as 2·(logLik(mixed) −
logLik(pooled OLS)): 37.2788 vs the printed 37.28, and 34.4453 vs the printed 34.45. Stata
reports 37.278753 and 34.445258 for the same quantity.

## What does not reproduce

Nothing. All 70 targets match at printed precision.

Two things in the paper are *outside* this package rather than failing in it: Table 3 (the
FAT-PET regression without the SE term) and the uncorrected mixed-effects means the text
quotes as −0.23 and −0.63 were not among the frozen targets, so they are neither claimed nor
computed here. The recovered script shows both, and the inline expected values it records
(`xtreg e if longr==0, mle ..... -0.232`, `longr==1 ..... -0.625`) match the paper's prose,
which is further evidence the published csv is the paper's own data.

## Reproducing

```
Rscript run.R
```

Needs `lme4`, `fixest`, and optionally `jsonlite`. Writes `results.json`. Runs in a few
seconds; no seed, nothing stochastic.
