# Replication package -- fdi

**Paper**: Mojmir Hampl, Tomas Havranek and Zuzana Irsova (2020), "Foreign
Capital and Domestic Productivity in the Czech Republic: A Meta-Regression
Analysis." *Applied Economics* 52(18), 1949-1958.
https://doi.org/10.1080/00036846.2020.1726864

**Table reproduced**: Table 2, "Factors influencing the reported spillover
estimates" -- General model and Specific model. Table 1 (funnel asymmetry)
needs the standard error of each primary estimate as a regressor and the
published file does not carry one; Table 3 (Bayesian model averaging) is a
one-million-draw MCMC and is outside the deterministic scope of this package.

## Data

`site/data/v1/fdi/fdi.csv` -- 332 rows, 23 columns (`e_w` plus the 22
moderators). No other file is read. The identical table also ships as
`site/data/v1/fdi/fdi.parquet` and inside `site/fdi/spillovers.zip`
(`spillovers.dta`).

## Method

Both models are `st_regress()` -- Stata's `regress y x, vce(cluster study)` --
of the winsorised spillover estimate `e_w` on the moderators, with no
weighting and no sample restriction (N = 332 in both). The paper states the
variance convention explicitly: "note that in all models we cluster the
standard errors at the level of individual studies, because we suspect that
estimates reported within individual studies are not independent."

- **General model**: all 22 published moderators.
- **Specific model**: the 11 moderators the paper reports as surviving its
  general-to-specific reduction (Quadratic, Data year, Year FE, Competition,
  Joint ventures, Assets, Output, POLS, Random, GMM, Real linkages). The
  elimination *path* is not re-derived here -- only the model the paper
  reports as its outcome is re-estimated. See "What is not reproduced".

## The study identifier, and the bug that was in this package

The published file has no study ID column, and the clustering is not a detail:
it is the entire content of the parenthesised numbers in Table 2. The ID has
to be rebuilt from the published columns, and the obvious way to do it is
wrong.

`Impact_factor`, `Citations` and `Pub_year` are study-level constructs, and the
rows are in study order, so runs of a constant (Impact_factor, Citations,
Pub_year) triple look like the study blocks. Grouping on them gives 8
contiguous blocks -- the right *number* of studies. The previous version of
this package did exactly that, and got every coefficient right and every
standard error wrong.

The blocks are in the wrong *place*. Each is shifted one row early, because in
the source data the three quality columns lag the rest of the record by one
observation: the last estimate of every study carries the *following* study's
impact factor, citation count and publication year. Five of the 332 rows land
in the wrong cluster. With only 8 clusters against 23 parameters that is
enough to move every standard error in the table, some by a factor of four,
while leaving every point estimate untouched -- because clustering never
touches a point estimate. That is precisely the symptom this package showed.

The shift is detectable from the published file alone. Three moderators --
`Competition`, `Assets`, `Real_linkages` -- are constant within a primary study
and change between studies, so a change in any of them must be a study
boundary. Those changes sit at rows 13, 105, 164 and 180 (1-based). The
quality-triple changes sit at 12, 104, 163 and 179: one row earlier, at all
four, in the same direction. So the study block begins one row *after* the
quality triple changes, and the study ID is the run index of the **lagged**
quality triple. `run.R` builds it that way and then asserts the consistency
check -- every change in a within-study-constant moderator must coincide with
a study start -- which fails on the naive grouping and passes on this one.

The resulting partition is 8 contiguous blocks of 12, 92, 48, 3, 8, 16, 69 and
84 estimates.

**Independently confirmed.** The author's own working file (not published, and
not read by `run.R`) carries the real `idstudy`. The reconstruction above
matches it row for row, all 332: Gersl (2008) 12, Vacek (2010) 92, Vacek
(2007) 48, Damijan et al. (2003) 3, Damijan et al. (2013) 8, Gersl et al.
(2007) 16, Stancik (2007) 69, Stancik (2009) 84. Running the author's own
Stata commands on that file in Stata 15.1 reproduces Table 2 to the last
printed digit, which is what fixes the diagnosis rather than merely making it
plausible. The published package reads only `fdi.csv`.

## Results

**72 of 72 targets match: 35/35 coefficients, 35/35 standard errors, 2/2
observation counts.**

### General model

| Variable | Printed coef (SE) | Produced coef (SE) |
|---|---|---|
| Forward | 0.0773 (0.401) | 0.07735 (0.40054) |
| Horizontal | 0.286 (0.311) | 0.28636 (0.31076) |
| Lagged | -0.0534 (0.0351) | -0.05343 (0.03510) |
| Quadratic | 0.390 (0.280) | 0.39013 (0.27976) |
| Differences | 0.0117 (0.0847) | 0.01170 (0.08473) |
| No. of firms | 0.0930 (0.0801) | 0.09301 (0.08010) |
| Data year | 0.150 (0.0184) | 0.14957 (0.01842) |
| Year FE | -0.278 (0.0713) | -0.27823 (0.07134) |
| Sector FE | 0.0136 (0.0650) | 0.01357 (0.06503) |
| Competition | -0.360 (0.363) | -0.36007 (0.36349) |
| Fully owned | 0.601 (0.439) | 0.60107 (0.43889) |
| Joint ventures | 1.282 (0.439) | 1.28231 (0.43889) |
| Services | 0.0143 (0.208) | 0.01434 (0.20834) |
| Assets | -0.466 (0.169) | -0.46614 (0.16937) |
| Output | -0.162 (0.106) | -0.16189 (0.10626) |
| POLS | 0.156 (0.0672) | 0.15578 (0.06717) |
| Random | 0.0585 (0.0561) | 0.05854 (0.05612) |
| GMM | -0.0951 (0.0303) | -0.09512 (0.03025) |
| Real linkages | 1.097 (0.428) | 1.09747 (0.42768) |
| Impact factor | -3.035 (2.975) | -3.03536 (2.97492) |
| Citations | 0.0471 (0.0406) | 0.04710 (0.04059) |
| Pub. year | -0.127 (0.0840) | -0.12739 (0.08403) |
| Constant | -0.704 (0.774) | -0.70403 (0.77390) |
| Observations | 332 | 332 |

### Specific model

| Variable | Printed coef (SE) | Produced coef (SE) |
|---|---|---|
| Quadratic | 0.565 (0.183) | 0.56533 (0.18262) |
| Data year | 0.135 (0.0190) | 0.13482 (0.01902) |
| Year FE | -0.333 (0.0237) | -0.33309 (0.02370) |
| Competition | -0.573 (0.0530) | -0.57335 (0.05298) |
| Joint ventures | 0.733 (0.0364) | 0.73287 (0.03638) |
| Assets | -0.463 (0.0542) | -0.46309 (0.05421) |
| Output | -0.188 (0.0503) | -0.18768 (0.05033) |
| POLS | 0.205 (0.00675) | 0.20451 (0.006747) |
| Random | 0.0909 (0.0258) | 0.09093 (0.02583) |
| GMM | -0.0765 (0.0307) | -0.07646 (0.03075) |
| Real linkages | 0.353 (0.0237) | 0.35308 (0.02372) |
| Constant | -0.202 (0.0832) | -0.20206 (0.08320) |
| Observations | 332 | 332 |

Fully owned and Joint ventures share a standard error (0.439) in the printed
table and in the reproduction. That is not a typo in the paper: with 8 clusters
the sandwich has rank at most 8 against 23 parameters, and the two dummies are
exact complements within the studies that identify them.

## What is not reproduced

- **The general-to-specific selection path.** The package re-estimates the
  model the paper prints; it does not re-derive which variables get dropped.
  The paper says only that variables "jointly insignificant at the 5% level"
  were excluded, and no code for that step is published. A naive
  one-at-a-time backward elimination does not land on the same 11 variables,
  so the reduction was evidently done in blocks the paper does not specify.
  The reported table is therefore reproduced conditional on the reported
  variable set, not derived from scratch.
- **Table 1** (funnel asymmetry, 6 numbers) and the two best-practice
  spillovers of 1.1 and 1.9. All of these need `se`, the standard error of
  each primary estimate, and its winsorised form `se_w`. The published file
  carries neither, only the winsorised effect size `e_w`. Publishing `se_w`
  alongside `e_w` would make Table 1 reproducible.
- **Table 3** (Bayesian model averaging). Stochastic; the site publishes the
  author's own `spillovers.R` that produces it.

## Verdict

**COMPLETE for Table 2.** 72/72 targets, coefficients and standard errors
alike, reproduced from the published data with no tuning, no dropped
observations and no adjustment to the variance convention. The single fix was
the study identifier: cluster on the lagged quality-variable runs, not the raw
ones.
