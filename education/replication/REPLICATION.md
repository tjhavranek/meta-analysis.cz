# education — Table 6, "Best practice estimation yields a tuition–enrolment effect that is close to zero"

**40 of 42 printed numbers reproduce.** The two that do not miss by one unit in the third
decimal, and in both cases the paper's own printed interval contradicts the paper's own
printed mean, so the residual is arithmetic in the table rather than in the estimation.
Details at the bottom.

Paper: Havránek & Zeynalova, *Oxford Bulletin of Economics and Statistics* (2019).
Data read: `site/data/v1/education/education.csv` (442 estimates, 43 studies, 6 countries).
Code read: nothing — but the reconstruction below follows `site/education/education.do`,
which the site also publishes, line for line.

## What Table 6 is

Seven synthetic "best practice" studies (short-run, long-run, private, public, male,
female, all estimates). For each, two fitted partial correlations — one from Bayesian
model averaging, one from frequentist Mallows model averaging — with a 95% interval.

The earlier version of this package computed nothing and reported BMA/FMA as an
unsupported command. That was wrong on the facts: the site's own `education.do` carries
the BMA call, the entire FMA program, and the seven best-practice covariate vectors. The
only thing missing from the site is the *result* of running them, not the specification.

## The three ingredients, and where each comes from

**1. Weighting.** Every variable, the dependent one included, is multiplied by
`invperst = 1/(estimates per study)`. This is the do-file's `gen `x'_nobs = `x' * invperst`,
and it is what the paper means by "weighted using the inverse of the number of estimates
reported per study". The intercept is *not* weighted: `bms` and the author's FMA program
both append a plain column of ones, as does `ivreg2`'s `_cons`. That is not textbook WLS,
but it is the regression that produced the published table, and reproducing the table means
reproducing it.

**2. BMA.** `bms(data, g="UIP", mprior="uniform")` over the 18 regressors of Table 5 —
`pcc_se, shortrun, panel, cross, unemployment, income, linear, doublelog, ols, endogeneity,
male, female, private, public, usa, ln_pub_year, ln_google, published`. The do-file records
the author's call as MCMC with 10⁶ burn-in and 2×10⁶ draws. **This package enumerates the
full model space instead** (2¹⁸ = 262,144 models, under a minute). Enumeration is the exact
posterior that the chain approximates — the author's own log reports Corr PMP = 0.9998 — it
is deterministic, and it is what makes the package re-runnable by a visitor. Re-running a
two-million-draw chain would not return the author's draws in any case.

The posterior means this produces agree with Table 5's BMA column at every printed digit,
e.g. `pcc_se −0.649` (paper −0.650), `male −0.351` (−0.351), `private −0.169` (−0.169),
`ln_google 0.043` (0.043), constant `0.002` (0.002).

**3. FMA.** A direct port of the Mallows program printed in `education.do`: scale each
column by its maximum, walk the nested orthogonalised models `x[,1:i]`, and pick weights by
`LowRankQP` on Mallows' criterion. Column *order* is part of the specification here, because
the nested-model sequence is defined by it; the order used is the one `education.do` lists
in its best-practice `ivreg2` and the one Table 5 prints. The resulting coefficients
reproduce Table 5's FMA column exactly at all four printed decimals (`−0.7120, 0.1381,
−0.0155, 0.1648, …, 0.0531, −0.0538`, constant `0.0048`).

One line of the author's program is changed: his full-model `lm()` fit is routed through
`st_regress`. Same estimator, and it is only used for the bias term.

**4. The best-practice vectors.** Transcribed unchanged from the seven `lincom` lines of the
do-file's `BEST PRACTICE` block:

```
pcc_se 0, shortrun 0.480, ols 0, endogeneity 1, linear 0, doublelog 1, unemployment 1,
income 1, cross 0, panel 1, male 0.075, female 0.051, private 0.233, public 0.454,
usa 0.839, ln_pub_year 7.609, ln_google 3.970, published 1
```

with `shortrun` set to 1/0 for the short- and long-run rows, `private`/`public` to 1/0, and
`male`/`female` to 1/0 for those rows. `run.R` prints a provenance check against the data:
`0.480, 0.075, 0.051, 0.233, 0.454, 0.839` are the `invperst`-weighted sample means of
`shortrun, male, female, private, public, usa` (0.4802, 0.0752, 0.0514, 0.2328, 0.4537,
0.8392), `7.609` is the sample maximum of `ln_pub_year` (7.6089), and `pcc_se = 0` and
`ols = 0` are the sample minima the paper describes as switching publication and estimator
bias off. **One constant is not re-derivable from the published columns:** `ln_google =
3.970`. The paper says citations are censored at the 99% level; the published `ln_google`
has maximum 5.684 and 99th percentile 4.691, and 3.970 is neither. `ln_google` is
`ln(1 + citations)`, so 3.970 is the value a study with 52 citations carries; it does occur
in the published column, and was presumably fixed against a different citation vintage.
The do-file's own value is used, and it is flagged here rather than reverse-engineered.

**5. The intervals.** Table 6's note says the intervals come from "simple OLS with robust
standard errors clustered at the study and country level". That OLS is the do-file's
`ivreg2 pcc_nobs <18 regressors>_nobs, cluster(idstudy idcountry)`, and the half-width is
1.96 × the `lincom` standard error of the same best-practice vector. The *same* half-width
is applied to the FMA point estimate, which is what the printed table does — in every row
BMA and FMA intervals have equal width to the printed digit.

Checked directly against Stata 15.1 (`ivreg2` + the seven `lincom`s, run on the published
CSV). Every coefficient and every one of the seven standard errors reproduces here through
`st_ivreg2(..., cluster = ~idstudy + idcountry)` to six decimals — e.g. `pcc_se_nobs`
−0.711920 both ways, and `lincom` SEs 0.0111107 / 0.0098716 / 0.0118792 / 0.0183409 /
0.0860182 / 0.0529649 / 0.0090941. The compat layer's large-sample VCE with two-way
clustering is exactly `ivreg2` without `small`.

## One convention worth stating plainly

**The FMA coefficients enter the best-practice arithmetic rounded to four decimals.** This
is not a tuning knob added to make numbers fit; it is the last line of the author's own
program, published in `education.do`:

```
MMA.fls <- round(results.reduced,4)
```

The 4-decimal table is the only FMA output that ever existed outside that R session, it is
what Table 5 prints, and Table 6's FMA column was computed from it. The evidence is in the
pattern, not in the score: with unrounded coefficients, ten of the twenty-one FMA numbers
miss by exactly one unit in the third decimal, always in the same direction. `run.R`
computes both and writes the unrounded fitted values into `results.json` under
`diagnostic_only`, so nothing is hidden.

BMA gets no such treatment — its posterior means are used at full precision, because
`coef()` prints them at full precision. Rounding them to Table 5's three decimals destroys
all 21 BMA numbers, which is the control that shows the FMA rounding is a real feature of
the author's pipeline rather than a convenient assumption.

## What still misses, and why

| target | produced | paper |
|---|---|---|
| T6 long-run FMA mean | −0.069406 → **−0.069** | **−0.070** |
| T6 female BMA CI low | −0.120548 → **−0.121** | **−0.120** |

Both are one unit in the last printed digit, and in both cases the paper's own row is
internally inconsistent:

* **Long-run FMA.** The paper prints the interval (−0.089, −0.050) for this row, which this
  package reproduces exactly. That interval is not symmetric about −0.070 (it is 0.019 below
  and 0.020 above), so the number behind it is about −0.0694 — which is what is computed
  here. The printed mean and the printed interval cannot both come from the same underlying
  value.
* **Female BMA lower bound.** The paper prints mean −0.017 and upper bound 0.087, so the
  half-width is 0.104 and the lower bound should print as −0.121. It prints −0.120.
  This one is also on a knife-edge in the estimation: the value here misses the rounding
  boundary by 5×10⁻⁵, and that gap is entirely the fourth decimal of the BMA posterior mean,
  i.e. enumeration versus the author's Markov chain.

That last point was checked rather than assumed. Loading the author's own saved `bms` object
and reading his posterior means straight off it (not something the published `run.R` may do)
scores **20 of 21** on the BMA half of the table too — it fixes `female BMA CI low` and
breaks `short-run BMA CI low` instead. No BMA configuration reaches 21 of 21. The remaining
disagreement is therefore in the rounding of the printed table, not in the estimator, and it
is left standing rather than papered over.

## Running it

```
Rscript run.R
```

Needs `BMS` and `LowRankQP` from CRAN in addition to the compat layer's `fixest`/`jsonlite`.
Runtime is about a minute, nearly all of it the 262,144-model enumeration. Output is
deterministic: there is no Monte Carlo anywhere in the package.
