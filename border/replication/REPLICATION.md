# Replication package: border

**Paper**: "Do Borders Really Slash Trade? A Meta-Analysis", *IMF Economic Review* (2017),
doi [10.1057/s41308-016-0001-5](https://doi.org/10.1057/s41308-016-0001-5).

**Target table**: Table 6, "Robustness Check--OLS and Fixed Effects" -- a frequentist
double-check, reported alongside the paper's headline Bayesian-model-averaging table
(Table 5), of the same border-effect estimates for Canada, the US, the EU, OECD and
emerging/developing countries.

**All 41 targets reproduce at the printed precision.**

**Table 5 (the paper's actual headline numbers -- 2.19/0.67/1.46/0.54/3.16/1.76 etc.)
was NOT attempted.** It is not a regression this package can run: it is a *prediction*,
built from (a) Bayesian model averaging over the same 32-variable specification, run in
R's `BMS` package (`bms(..., burn=1000000, iter=2000000, g="UIP"/"BRIC",
mprior="uniform"/"random", nmodel=5000, mcmc="bd")`), and (b) the analyst's "best
practice" covariate values plugged into the resulting posterior means. In the author's
own `border.do` this entire block is a Stata comment -- every line begins with `*`, and
the block is headed "`*BAYESIAN MODEL AVERAGING`" / "`*//Switch to R`" -- meaning it
documents what was run in R, not something `border.do` itself executes. No wrapper in
`stata_compat.R` performs Bayesian model averaging, so this is a genuine
`unsupported_command`, not a mismatch to repair.

## Data

`data/v1/border/border.csv` (1,271 rows, 61 columns), the site's published mirror of the
author's `border.dta`. All variables Table 6 needs are present under their original
names; no other file was read for data. Variable construction follows `border.do` lines
14-21 verbatim (`avyear - 1899`, `ln(csunits)`, `ln(years)`, `firstpub - 1995`,
`ln(yearcits + 1)`); no observation is dropped anywhere in the do-file, and none is
dropped here (N = 1,271, 61 studies, both columns).

## Provenance

### OLS column -- `border.do` line 123, run verbatim

```
ivreg2 b avyear panel disagg lncsunits lnyears canada us eu oecd emerg nointflow
  ddiff dactual totalt asym gdpendog remote countryfe ratio avw nores plusone
  tobit ppml nozeros adjacency language fta published impact lnyearcits firstpub
  [pweight=invperst], cluster(idstudy idcountry2)
```

This 32-regressor list, in this order, is exactly Table 6's row order. `ivreg2` without
`small` means a large-sample two-way cluster VCE with z inference -- `st_ivreg2()`'s
convention.

**The two-way variance is assembled by hand, and here is why.** With
`cluster(idstudy idcountry2)` the Cameron-Gelbach-Miller variance

```
V = V(idstudy) + V(idcountry2) - V(idstudy x idcountry2)
```

is *not* positive semi-definite on this sample: its smallest eigenvalue is -0.0029.
Stata's `ivreg2` prints that matrix as it stands and only warns ("*estimated covariance
matrix of moment conditions not of full rank ... standard errors and model tests should
be interpreted with caution*" -- the warning is in the Stata output for this very
regression). fixest instead repairs it, zeroing the negative eigenvalues and emitting
"*The VCOV matrix is not positive definite and was 'fixed'*". The repair is a defensible
thing for fixest to do and it is not what produced Table 6.

Measured against Stata 15.1, running `border.do` line 123 verbatim on the same data:

| term | Stata `ivreg2` | CGM, un-repaired (this package) | fixest, repaired |
|---|---:|---:|---:|
| avyear | 0.010649017 | 0.010649017 | 0.010659282 |
| canada | 0.350592488 | 0.350592487 | 0.350604255 |
| us | 0.236777609 | 0.236777608 | 0.236816954 |
| eu | 0.394870507 | 0.394870505 | 0.395052429 |
| oecd | 0.335636620 | 0.335636619 | 0.336187479 |
| **emerg** | **0.248487765** | **0.248487765** | **0.248539034** |
| _cons | 1.384253856 | 1.384253840 | 1.384253857 |

The repair is small everywhere and decisive in one place: Emerging's SE crosses the
0.2485 rounding boundary and prints 0.249 against the paper's 0.248. That single cell
was this package's last miss. (An earlier draft of this file recorded that
`vcov(m, vcov_fix = FALSE)` "gives the same 0.248539 to six digits, so the earlier
suggestion that this correction explained the cell was wrong". That conclusion was
wrong: `vcov.fixest` returns the VCOV cached at fit time unless the clustering is
respecified in the same call, so the flag was silently doing nothing. The repair *is*
the cause.)

So `run.R` estimates the three CGM terms separately, each through `st_ivreg2` with the
layer's own large-sample profile -- each single clustering is positive definite on its
own, so no repair is triggered inside any of them -- and adds them the way `ivreg2` adds
them. The three fits share identical point estimates (asserted to 1e-12 in `run.R`);
only the variance differs. Agreement with Stata is then to nine significant digits, and
all 21 OLS cells reproduce.

This is a convention `stata_compat.R` has no switch for, and it belongs there rather
than in a package. `st_ivreg2()` calls `feols(..., ssc = .SSC_LARGE)` and does not pass
`vcov_fix = FALSE`, so any package that clusters two ways on a rank-deficient sample
will silently get fixest's repaired SEs rather than `ivreg2`'s. **The shared file was
deliberately not modified here** (it is hash-locked and every other package depends on
it); the Stata evidence above is the evidence a future edit would need.

### Fixed Effects column -- `xtreg ..., fe vce(cluster idstudy)`, confirmed in Stata

`border.do` (dated February 2014) contains no command for the FE column; the robustness
column was evidently added in a later revision without the do-file being updated. An
early draft of this package took the paper's note -- "*standard errors are clustered at
both the study and dataset levels*" -- at face value and ran the OLS `ivreg2` line with
study dummies (LSDV, two-way cluster). That reproduced every FE coefficient but none of
the standard errors (Canada 0.296 vs printed 0.321; US 0.263 vs 0.221), the signature of
a wrong *variance* convention rather than a wrong sample or specification.

Two facts printed in the table pointed at what was actually run:

1. **The FE p-values are t(60), not z.** Emerging: |t| = 1.129/0.558 = 2.02, for which a
   z-test gives .043 and t with 60 df gives .048 -- the printed value. Likewise OECD
   (z .061 / t .066 printed), EU (z .013 / t .016 printed), Constant (z .110 / t .115
   printed). The OLS column's p-values are z (Canada: 2.34 -> z .019 printed, t .023).
   t with G-1 = 60 df is the inference Stata's `xtreg`/`regress` use with 61 study
   clusters; `ivreg2` never reports it.
2. **The FE standard errors are the one-way study-clustered sandwich times Stata's
   `xtreg, fe` small-sample factor** G/(G-1)·(N-1)/(N-K) with K = 27 slopes + constant
   (absorbed study effects not counted, because they are nested in the cluster). The
   `areg`-style factor (K counting the 61 study dummies) gives Canada .329, and any
   two-way variant gives .296 or lower.

That inference was then **checked directly in Stata 15.1**, which settles it:

```
xtreg b avyear panel disagg lncsunits lnyears canada us eu oecd emerg nointflow ddiff
  dactual totalt asym gdpendog remote countryfe avw nores plusone tobit ppml nozeros
  adjacency language fta [pweight=invperst], fe vce(cluster idstudy)
```

reproduces **every printed cell of Table 6's Fixed Effects column**, not only the seven
this package targets: Midyear -0.059 (0.039) 0.130, Panel -0.035 (0.205) 0.864,
Disaggregated 0.155 (0.475) 0.745, Obs. per year 0.195 (0.134) 0.151, No. of years
-0.015 (0.090) 0.866, No internal trade 0.117 (0.451) 0.796, Inconsistent dist 0.919
(0.248) 0.000, Actual distance -0.754 (0.034) 0.000, Total trade 0.142 (0.154) 0.360,
Asymmetry 0.171 (0.123) 0.170, Instruments 0.001 (0.138) 0.992, Remoteness 0.304 (0.124)
0.017, Country fixed eff 0.059 (0.127) 0.643, Anderson est 0.419 (0.130) 0.002, No
control for MR 0.117 (0.166) 0.485, Zero plus one 0.522 (0.375) 0.170, Tobit -0.747
(0.354) 0.039, PPML 0.211 (0.771) 0.785, Zeros omitted -0.093 (0.180) 0.605, Adjacency
0.078 (0.103) 0.449, Language -0.269 (0.103) 0.011, FTA 0.347 (0.162) 0.037, Constant
6.149 (3.842) 0.115. Stata reports `e(df_r) = 60`, `e(N) = 1271`, `e(N_g) = 61`.

The 27 regressors are the 32 OLS regressors minus the five Table 6 leaves blank for
lacking within-study variation (`ratio`, `published`, `impact`, `lnyearcits`,
`firstpub`). **The paper's "clustered at both the study and dataset levels" sentence
does not describe the printed FE column.** It describes the OLS column and the rest of
the paper's `ivreg2` output. This is a documentation slip in the paper, not an error in
its numbers.

**Wrapper used**: `st_xtreg_fe(b ~ ..ctrl, data, panel = "idstudy", cluster = ~idstudy,
weights = ~invperst)` -- fixest default ssc (= Stata's `xtreg` factor when the FE is
nested in the cluster) and `fixef.rm = "none"` (singletons kept, N stays 1,271). The
wrapper's internal `paste(deparse(fml), "|", panel)` line-wraps a 27-term formula at
`deparse()`'s fixed 60-character cutoff and then appends `| idstudy` to every fragment,
so a written-out formula cannot pass through it. A fixest formula macro
(`setFixest_fml(..ctrl = ~ avyear + ... + fta)`, a formula helper, not an estimator)
keeps the formula handed to the wrapper to `b ~ ..ctrl`, which fixest expands at fit
time. The estimation is done by `st_xtreg_fe` exactly as written. p-values are
`2*pt(-|t|, 60)`, arithmetic on `st_coefs(m, z = FALSE)`.

**FE Constant**: Stata's `xtreg, fe` `_cons`. `stata_compat.R`'s `st_xtreg_fe_cons()`
documents the construction -- "the grand mean of y minus the fitted within slope times
the grand mean of x, obtained by an augmented within regression" -- but accepts one `x`
and no weights. The same construction is applied here for 27 regressors and pweights:
every variable is replaced by (value - study weighted mean + grand weighted mean) and
the augmented regression is run through `st_regress()` with the same cluster and
weights (`st_xtreg_fe_cons` is itself `feols` with default ssc and `cluster = ~g`, i.e.
what `st_regress` does). Its intercept is `_cons` (6.14942, Stata: 6.14942) and its
intercept SE is `_cons`'s SE (3.84176, Stata: 3.84176). `run.R` asserts that the slopes
and their SEs from this augmented regression equal `st_xtreg_fe`'s to 1e-8, so the two
routes are the same fit.

`stata_compat.R` is used only through its wrappers (`st_ivreg2`, `st_xtreg_fe`,
`st_regress`, `st_coefs`) and was **not** modified.

## Results

A value MATCHES when it rounds to the printed number at the printed precision (counts
exactly). **41 of 41 targets match** (earlier drafts: 30, 31, 40).

| Target | Printed | Produced | Verdict |
|---|---:|---:|---|
| N (observations) | 1271 | 1271 | MATCH |
| Studies | 61 | 61 | MATCH |
| OLS Midyear coef / se / p | -0.002 / 0.011 / 0.874 | -0.00169 / 0.01065 / 0.87403 | MATCH |
| OLS Canada coef / se / p | 0.822 / 0.351 / 0.019 | 0.82189 / 0.35059 / 0.01906 | MATCH |
| OLS US coef / se / p | -1.046 / 0.237 / 0.000 | -1.04595 / 0.23678 / 0.00001 | MATCH |
| OLS EU coef / se / p | -0.535 / 0.395 / 0.176 | -0.53476 / 0.39487 / 0.17565 | MATCH |
| OLS OECD coef / se / p | -0.833 / 0.336 / 0.013 | -0.83311 / 0.33564 / 0.01306 | MATCH |
| OLS Emerging coef / se / p | 0.653 / 0.248 / 0.009 | 0.65330 / 0.24849 / 0.00856 | MATCH |
| OLS Constant coef / se / p | 2.055 / 1.384 / 0.138 | 2.05458 / 1.38425 / 0.13774 | MATCH |
| FE Canada coef / se / p | 1.096 / 0.321 / 0.001 | 1.09615 / 0.32105 / 0.00115 | MATCH |
| FE US coef / se / p | -1.251 / 0.221 / 0.000 | -1.25146 / 0.22122 / 0.0000005 | MATCH |
| FE EU coef / se / p | -0.436 / 0.175 / 0.016 | -0.43587 / 0.17526 / 0.01568 | MATCH |
| FE OECD coef / se / p | -0.434 / 0.232 / 0.066 | -0.43380 / 0.23167 / 0.06602 | MATCH |
| FE Emerging coef / se / p | 1.129 / 0.558 / 0.048 | 1.12936 / 0.55846 / 0.04761 | MATCH |
| FE Constant coef / se / p | 6.149 / 3.842 / 0.115 | 6.14942 / 3.84176 / 0.11470 | MATCH |

Every produced value also agrees with Stata 15.1 run on the same data to at least eight
significant digits (OLS) or to the digits Stata prints (FE).

## What is not reproduced

Nothing in Table 6. Outside it:

- **Table 5**, the paper's headline column, for the BMA reason at the top of this file.
- **Table 4** (the BMA posterior means themselves) and **Table 7** (country-level
  characteristics, `ivreg2` on `size tariff ntb ...`) are outside this package's target
  set. Table 7 would be reachable with the same `st_ivreg2` route.

## Unsupported command

`bms()` (R package `BMS`, Bayesian model averaging) -- needed for the paper's headline
Table 5, not in `stata_compat.R`'s wrapper set, and stochastic on top of that (MCMC with
`burn=1000000, iter=2000000`) even were a wrapper to exist.

## Verdict

**CONCORDANT on Table 6** (41/41 at printed precision, every cell also checked against
Stata). Two conventions had to be got right and neither is in the paper's own text: the
FE column is `xtreg, fe vce(cluster idstudy)` with t(60) inference, not the two-way
clustering the table note describes; and the OLS column's two-way variance is
`ivreg2`'s un-repaired Cameron-Gelbach-Miller matrix, not fixest's positive-definite
repair of it. Table 5, the paper's headline number, remains unattempted for the BMA
reason above.
