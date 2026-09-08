# Replication package -- armington

**Paper:** Irsova, Z. & Havranek, T. (2020). "Estimating the Armington Elasticity: The
Importance of Study Design and Publication Bias." *Journal of International Economics*, 127,
103383. https://doi.org/10.1016/j.jinteco.2020.103383

**Table reproduced:** Table 2, "All tests indicate publication bias among long-run Armington
elasticities" -- Panel A (Unweighted OLS, Fixed effects) and Panel B, row 1 (Weighted by the
inverse of the number of estimates reported per study), all three columns (All / Short-run /
Long-run), plus the shared Observations row.

**Provenance:** `author_code`. Every regression in scope is a direct read of a line in the
author's `armington.do`, which the site publishes at `site/armington/armington.do` (lines 93-106):
the sample filters (`srun==1`, `srun==0`), the vcov options (`cluster(idstudy idcountry)`,
`cluster(idstudy)`, `robust`, `vce(robust)`), the weight construction (`gen invnobs = 1/nobs`,
`gen invnobs_short = 1/nobs_short`, `gen invnobs_long = 1/nobs_long`, lines 13-15) and the
`xtset idstudy` panel structure all come from that file, not from the paper's methods section.

**Data:** `data/v1/armington/armington.csv` as published by the site (3524 rows, 76 columns).
`armel_w` and `se_w` are used as published -- they are already the winsorized effect and standard
error the paper describes, so no winsorizing step is run here. The site's `armington.xlsx` (the
`data.xlsx` the do file imports) was checked column by column against this CSV for every variable
Table 2 uses: `armel_w`, `se_w`, `nobs`, `nobs_long`, `nobs_short`, `srun`, `idstudy`,
`idcountry` are bit-identical, so nothing in this package turns on which of the two is read.

**Run:** `Rscript run.R` from this directory. Sources `...\scratchpad\repl\stata_compat.R` and
reads only the published CSV. Writes `results.json`.

## Why Table 2 and not Tables 3-5

Tables 3-5 are BMA-based (Bayesian model averaging over a large candidate meta-regression space)
and, for Tables 3-4, synthetic-study country predictions built from that BMA fit plus external
Feenstra et al. (2018) / Imbs and Mejean (2015) inputs. None of that machinery has -- or should
have -- a `stata_compat.R` wrapper. Table 2 is the paper's funnel-asymmetry (FAT-PET) table, built
from OLS/FE/WLS regressions of the effect on its standard error, which is exactly what
`st_ivreg2` and `st_xtreg_fe` exist to emulate.

## Target-by-target results

Produced values are as written to `results.json`, shown to five decimals. "Match" means the
produced value rounds to the printed value at the printed precision.

| label | printed | produced | verdict |
|---|---:|---:|---|
| T2_N_all | 3524 | 3524 | match |
| T2_N_short | 556 | 556 | match |
| T2_N_long | 2968 | 2968 | match |
| T2_ols_all_se_coef | 0.808 | 0.80785 | match |
| T2_ols_all_se_se | 0.0652 | 0.06523 | match |
| T2_ols_all_const_coef | 0.873 | 0.87255 | match |
| T2_ols_all_const_se | 0.133 | 0.13324 | match |
| T2_ols_short_se_coef | 0.0791 | 0.07907 | match |
| T2_ols_short_se_se | 0.0826 | 0.08260 | match |
| T2_ols_short_const_coef | 0.867 | 0.86702 | match |
| T2_ols_short_const_se | 0.0249 | 0.02490 | match |
| T2_ols_long_se_coef | 0.805 | 0.80463 | match |
| T2_ols_long_se_se | 0.0630 | 0.06300 | match |
| T2_ols_long_const_coef | 0.901 | 0.90137 | match |
| T2_ols_long_const_se | 0.168 | 0.16825 | match |
| T2_fe_all_se_coef | 0.621 | 0.62108 | match |
| T2_fe_all_se_se | 0.0588 | 0.05876 | match |
| T2_fe_all_const_coef | 1.007 | 1.00708 | match |
| T2_fe_all_const_se | 0.0423 | 0.04233 | match |
| T2_fe_short_se_coef | -0.00578 | -0.00578 | match |
| T2_fe_short_se_se | 0.104 | 0.10421 | match |
| T2_fe_short_const_coef | 0.883 | 0.88264 | match |
| T2_fe_short_const_se | 0.0192 | 0.01919 | match |
| T2_fe_long_se_coef | 0.627 | 0.62678 | match |
| T2_fe_long_se_se | 0.0580 | 0.05796 | match |
| T2_fe_long_const_coef | 1.047 | 1.04734 | match |
| T2_fe_long_const_se | 0.0476 | 0.04757 | match |
| T2_wols_invnobs_all_se_coef | 1.017 | 1.01684 | match |
| T2_wols_invnobs_all_se_se | 0.249 | 0.24897 | match |
| T2_wols_invnobs_all_const_coef | 1.011 | 1.01084 | match |
| T2_wols_invnobs_all_const_se | 0.254 | 0.25384 | match |
| T2_wols_invnobs_short_se_coef | 0.0674 | 0.06738 | match |
| T2_wols_invnobs_short_se_se | 0.0721 | 0.07214 | match |
| T2_wols_invnobs_short_const_coef | 0.899 | 0.89938 | match |
| T2_wols_invnobs_short_const_se | 0.0821 | 0.08212 | match |
| T2_wols_invnobs_long_se_coef | 0.821 | 0.82111 | match |
| T2_wols_invnobs_long_se_se | 0.139 | 0.13908 | match |
| T2_wols_invnobs_long_const_coef | 1.134 | 1.13478 | **miss (paper prints 1.134; Stata itself gives 1.13478)** |
| T2_wols_invnobs_long_const_se | 0.168 | 0.16840 | match |

**38 / 39 matched.**

## The two `robust` conventions, and how each was settled

Six of these cells -- every standard error in the Short-run column -- were previously reported as
`NA` on the grounds that neither wrapper could produce a "non-clustered heteroskedasticity-robust"
standard error. Both halves of that claim were wrong, and Stata 15.1 was used to settle each
against the author's own command lines on the site's published CSV. The probe do-files are in
`...\scratchpad\repl\stata_work_armington\` (`probe1.do`, `probe2.do`).

**1. `ivreg2 y x, robust` is HC0 with z inference.** Without `small`, ivreg2 applies no
small-sample factor anywhere, so its robust variance is the plain sandwich, and the coefficient
table is z-based. That is precisely fixest's `vcov = "hetero"` under the large-sample `ssc` that
`st_ivreg2()` already installs -- the case `stata_compat.R`'s own note calls out ("heteroskedastic,
where fixest with adj = FALSE is already ivreg2's HC0"). So `run.R` fits the model with the
wrapper and switches only its vcov; the `ssc`, the weights and the point estimates all stay the
wrapper's. Stata against this package, unrounded:

| command | quantity | Stata 15.1 | this package |
|---|---|---:|---:|
| `ivreg2 armel_w se_w if srun==1, robust` | SE(se_w) | 0.082595774015 | 0.082595774015 |
| | SE(_cons) | 0.024903172290 | 0.024903172290 |
| `ivreg2 armel_w se_w if srun==1 [pweight=invnobs_short], robust` | SE(se_w) | 0.072138331707 | 0.072138331707 |
| | SE(_cons) | 0.082115246107 | 0.082115246107 |

`st_regress(..., robust = TRUE)` is *not* a substitute and was rejected on evidence: it emulates
Stata's `regress, robust`, which is HC1 with t inference and returns 0.082744729545 -- printing as
0.0827 against the paper's 0.0826.

**2. `xtreg y x, fe vce(robust)` is not a non-clustered vcov at all.** For `xtreg, fe` Stata's
`vce(robust)` *is* the cluster-robust (Arellano) estimator on the panel variable; the output even
says "Std. Err. adjusted for 8 clusters in idstudy". Run side by side on this sample the two
commands are byte-identical:

```
xtreg armel_w se_w if srun==1, fe vce(robust)      se_w .104212974140   _cons .019190181907
xtreg armel_w se_w if srun==1, fe cluster(idstudy) se_w .104212974140   _cons .019190181907
```

So `st_xtreg_fe()` / `st_xtreg_fe_cons()`, which cluster on the panel variable, were already
emulating the right command and needed no change -- only the `NA` had to be removed.

`stata_compat.R` was not modified. Nothing in this repair required it.

## The one remaining miss

**T2_wols_invnobs_long_const_coef -- the paper prints a value its own code does not produce.**
The cell is the constant of

```
ivreg2 armel_w se_w if srun==0 [pweight=invnobs_long], cluster(idstudy idcountry)
```

(`armington.do` line 106). Run in Stata 15.1 on the site's published CSV (`probe2.do`):

```
_cons = 1.134784556951   (SE 0.168397771381)
se_w  = 0.821106924039   (SE 0.139082045232)
```

This package produces 1.134784562, 0.168397771, 0.821106921, 0.139082044 -- the same numbers to
eight significant figures. 1.134784... rounds to **1.135**; the paper prints **1.134**.

The mismatch is confined to that one printed digit. The same regression's slope (0.821), its two
standard errors (0.139 and 0.168) and both other columns of the same table row (1.011 and 0.899)
match the paper exactly, and so do the other 35 printed values in the table. A different sample,
a different weight column or a different cluster specification would have moved the slope and the
standard errors too; none of them moved. `[pweight]` and `[aweight]` were also checked in Stata
and give the identical constant, so the weight-type convention is not the explanation either.
Every printed cell in Table 2 except this one is consistent with ordinary rounding of the
estimate behind it; this one is one unit low in its last digit. Both the working-paper PDF and the
published JIE version carry 1.134, so `targets.json` records the paper faithfully -- the slip is in
the paper's typeset table, not in the transcription.

Nothing in the code is adjusted to hit it. The cell is left as a miss.

## Not attempted (out of scope, not misses -- none of these is in `targets.json`)

- **Panel A, "Hierarchical Bayes"** -- a Gibbs sampler for a hierarchical linear model following
  Rossi et al. (2005). The parentheses in that row are posterior standard deviations, not standard
  errors, and `stata_compat.R` has no Bayesian wrapper (`st_mixed`/`st_xtmixed` are frequentist
  `lme4` fits and would be a different estimator wearing the same row label).
- **Panel B, "Weighted by the the inverse of the standard error"** -- the author's lines are
  `ivreg2 tstats_w invse_w if <sample>, cluster(idstudy)` (lines 109-111), the
  t-statistic-on-precision form of the FAT-PET, in which the *constant* is the publication-bias
  coefficient and the *slope on precision* is the effect beyond bias -- the two rows of the panel
  are read off swapped relative to Panel A. Checked in Stata (`probe3.do`), those three lines do
  reproduce that row: 1.559/0.761 (All), 2.698/0.510 (Short-run), 0.906/0.922 (Long-run), with
  standard errors 0.969/0.217, 2.213/0.325 and 0.205 all matching the print; the one exception is
  the long-run publication-bias SE, where the `cluster(idstudy)` line gives 0.731 against a printed
  0.431. That row is not in `targets.json`, so this package does not compute it, and the swapped
  row/coefficient mapping is exactly the kind of thing a frozen oracle should pin down before code
  is written rather than after.
- **Panel C** (WAAP, Andrews-Kasy selection model, Furukawa stem-based method) -- no wrapper
  exists for any of the three, and WAAP would additionally require a raw `quantile()` call, which
  `stata_compat.R` forbids. The paper itself notes these run on reduced samples (all 3,440;
  short-run 555; long-run 2,885 for WAAP).
- **Tables 3, 4, 5** -- BMA and BMA-based synthetic-study predictions; see above.

## Verdict

**NEAR-COMPLETE.** 38 of 39 targets reproduce exactly at the printed precision, including all
three N's, every coefficient, and every standard error in the table's scope. The single miss is a
cell where the paper's printed constant (1.134) differs in its last digit from what the author's
own do-file line produces in Stata (1.134785, i.e. 1.135); it is reported as a miss rather than
matched by adjustment.
