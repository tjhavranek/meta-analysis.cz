# Replication package: competition (Zigraiova & Havranek 2016, JEconSurveys)

Zigraiova, D. and Havranek, T. (2016). "Bank Competition and Financial Stability:
Much Ado About Nothing?" *Journal of Economic Surveys*, 30(5), 944-981.
doi: 10.1111/joes.12131

**Status: 149 of the 150 frozen targets reproduce.** The single miss is described in
full under "The one miss" below; it is a fourth-decimal disagreement with a number the
paper's text carries truncated rather than rounded, not a failure to compute it.

## What is reproduced

| Block | Targets | Matched |
|---|---:|---:|
| Table 9, OLS column (35 coefficients + 35 SEs + Constant + its SE + N + Studies) | 74 | 74 |
| Table 9, FE column (28 coefficients + 28 SEs + Constant + its SE + N + Studies) | 60 | 60 |
| Table 2, Fixed Effects columns (4 specifications: slope + Constant) | 8 | 8 |
| Table 1 / Figure 3 text ("close to zero") | 8 | 7 |
| **Total** | **150** | **149** |

**Table 9, "Results for Frequentist Methods"** is the paper's fully-frequentist
robustness table: OLS and study-fixed-effects regressions of the partial correlation
coefficient (PCC) of the reported competition-stability effect on all 35 collected
moderators, weighted by the inverse of the number of estimates reported per study
(`investperst`), with standard errors clustered by study (`IDStudy`). It was chosen
over the candidate BMA tables (7, 8, 10) because BMA has no wrapper in
`stata_compat.R`, whereas Table 9 uses only OLS and fixed effects.

## Provenance

`site/competition/competition.do` (the archived author file) documents:

  - `ivreg2 PCC <PIP>0.5 subset> [pweight=investperst], cluster(IDStudy)` (line 74) --
    the weighted OLS "frequentist check" of the paper's baseline table.
  - `xtreg PCC SEPCC [pweight=investperst], fe vce(cluster IDStudy)` (line 49) -- the
    weighted fixed-effects funnel-asymmetry test of Table 2.
  - `bysort IDStudy: egen PCCmed = median(PCC)` (line 13) and `mean PCCmed` (line 21) --
    the "mean of the study-level medians" quoted on p.959.

Table 9 itself -- the ALL-35-variable OLS and FE check -- is not literally in that file
(p.965 introduces it as the third of four robustness checks added after the baseline,
very likely run from a later, unarchived revision of the do-file). Its estimator,
weight and cluster choices come from the paper's own text and table note:

  - p.965: "we run the BMA exercise with the same priors as in our baseline
    specification but ... we only use frequentist methods (OLS and fixed effects)."
  - Table 9's note: "In the frequentist check we include all explanatory variables. The
    standard errors ... are clustered at the study level. The regressions are estimated
    by weighted least squares, where the inverse of the number of estimates reported per
    study is taken as the weight."

Same weight and same cluster as the archived do-file's own checks, so `st_ivreg2` (OLS)
and `st_xtreg_fe` (FE) are used with the conventions the do-file already establishes.

Stata 15.1 was then used directly as the oracle. `xtreg PCC <the 35 moderators>
[pweight=investperst], fe vce(cluster IDStudy)` on the published CSV reproduces the
whole FE column of Table 9 as printed, constant included -- `_cons = -.1783160`,
`se = .1655518` against the printed -0.1783 (0.1656) -- and omits exactly the seven
regressors the table marks "(omitted)". So the specification below is checked against
Stata, not only against the PDF. The probe do-files are in
`stata_work_competition/` (probe1, probe3, probe5) with their R counterparts
(probeA.R, probeB.R).

## Variable construction

- `SEPCC` <- CSV column `SE PCC` (renamed; identical values, cosmetic only).
- `TSLS` <- CSV column `2SLS` (renamed; not a valid bare R name).
- `Samplesize` <- `log(Samplesize)`. Table 4's variable-description column states the
  "Sample size" regressor is "the logarithm of the number of cross-sectional units",
  and reports mean 7.835 / SD 1.615, which is exactly `mean(log(Samplesize))` /
  `sd(log(Samplesize))` on the published CSV (7.835073 / 1.614506) and nothing like the
  raw column's mean of ~8382. (`T` needed no transformation: its raw mean/SD, 2.224 /
  0.743, already match Table 4 verbatim.)
- No other transformations.

## Two things that had to be worked around, and how

### 1. A formula-width limitation in `st_xtreg_fe`

`st_xtreg_fe` builds its fixed-effects formula as
`as.formula(paste(deparse(fml), "|", panel))`. R's `deparse()` line-wraps any formula
whose text exceeds about 60 characters into a character VECTOR rather than a single
string; with 35 additive terms this always happens and the wrapper's own
`paste()`/`as.formula()` step then fails (`Error ... unexpected '|'`). Packing the 35
moderators into one matrix column (`d_fe$X <- as.matrix(d[, fe_vars])`, `PCC ~ X`) keeps
`deparse(fml)` at the seven characters `"PCC ~ X"`, so the wrapper behaves as it does
for every short formula elsewhere, while `feols` underneath fits the identical model --
same estimator, weights, cluster and degrees of freedom. Verified cell by cell against
the printed FE column and against Stata.

`undeveloped` is listed before `developed` in `fe_vars`, against the table's own print
order. In the study-FE model the two are perfectly collinear within any study that
reports estimates for only one group, so one must be dropped; `feols` drops whichever
collinear column comes second, and Table 9 prints "developed (omitted)" with
`undeveloped` estimated. Stata drops the same seven columns (`developed`, `dummies`,
`Logit`, `citations`, `firstpub`, `IFrecursive`, `reviewed_journal`). Every other
coefficient is numerically identical under either order.

### 2. The constant of a WEIGHTED `xtreg, fe` (this is what the last repair fixed)

`feols` reports no intercept for an absorbed fixed effect. Stata's `xtreg, fe` does,
and it is simply the intercept of the within regression: each variable demeaned by its
group mean with the grand mean added back, fitted with a constant. `stata_compat.R`'s
frozen `st_xtreg_fe_cons()` performs exactly that, but only UNWEIGHTED and only for a
single regressor; both fixed-effects tables in this paper are weighted by
`investperst`. An earlier version of this package therefore left Table 9's FE constant
uncomputed.

It is computed now. The within transformation is written out with weighted group means
and a weighted grand mean (`demean_add_weighted()` in `run.R` -- `tapply()` and `sum()`,
bare arithmetic, no estimator), and the single model fit on the transformed data goes
through `st_regress()`, the sanctioned wrapper carrying fixest's DEFAULT small-sample
adjustment, which is the convention `xtreg` applies and the one `st_xtreg_fe` and
`st_xtreg_fe_cons` already use. `stata_compat.R` was not touched.

The wrapper choice is the whole of it, and Stata settled it:

| | Constant | SE |
|---|---:|---:|
| Stata `xtreg ... [pweight=investperst], fe vce(cluster IDStudy)` | -0.1783159629 | 0.1655517838 |
| `st_regress` on the transformed data (fixest default ssc) | -0.1783159609 | **0.1655517902** |
| `st_ivreg2` on the same data (ivreg2's large-sample variance) | -0.1783159609 | 0.1589946934 |

The point estimate is the same under either wrapper; only `st_regress` reproduces the
printed SE. The same switch was applied to Table 2's two weighted constants, which the
earlier version fitted with `st_ivreg2`: those now read 0.0068533322 and 0.0081765676
against Stata's 0.0068533321 and 0.0081765678, where before they read 0.0067 and
0.0080. Nothing in `targets.json` could have caught that -- the paper prints three
digits of those coefficients and no standard error for them -- but Stata did.

## Table 9, target-by-target

All 150 frozen targets are listed in `targets.json` with the values produced in
`results.json`. Representative rows:

| Label | Printed | Produced | Verdict |
|---|---|---|---|
| T9 OLS SEPCC coef | -1.5708 | -1.5708 | match |
| T9 OLS SEPCC se | 0.8567 | 0.8567 | match |
| T9 OLS Samplesize coef | -0.0363 | -0.0363 | match |
| T9 OLS developed coef | 0.1689 | 0.1689 | match |
| T9 OLS Hstatistic coef | 0.1629 | 0.1629 | match |
| T9 OLS Logit coef | -0.1481 | -0.1481 | match |
| T9 OLS Constant coef | -0.1350 | -0.1350 | match |
| T9 OLS N / Studies | 598 / 31 | 598 / 31 | match |
| T9 FE SEPCC coef | -1.6234 | -1.6234 | match |
| T9 FE macro coef | 0.1882 | 0.1882 | match |
| T9 FE undeveloped coef (se) | 0.1020 (0.0760) | 0.1020 (0.0760) | match |
| T9 FE Boone coef | 0.0744 | 0.0744 | match |
| T9 FE Constant coef | -0.1783 | -0.1783 | match (was a gap) |
| T9 FE Constant se | 0.1656 | 0.1656 | match (was a gap) |
| T9 FE N / Studies | 598 / 31 | 598 / 31 | match |

## Numbers from the paper's text: the "close to zero" claim

meta-analysis.cz summarises this paper as **"close to zero,"** which is the paper's own
phrase, most load-bearing in Section 7, "Concluding Remarks" (p.977):

> "We conduct a meta-regression analysis of 598 estimates of the relationship between
> bank competition and financial stability reported in 31 studies. ... Our results
> suggest that **the mean reported estimate of the relationship is close to zero, even
> after correcting for publication bias and potential misspecification problems.**"

That sentence bundles two separately computable quantities, both in `run.R` and printed
at the end of the run.

### (a) The raw, uncorrected mean estimate -- Table 1 / Figure 3 (pp.958-959)

Plain (weighted) means of the published `PCC` column; no estimator, so no wrapper.

| Label | Paper | Produced | Verdict |
|---|---:|---:|---|
| All, unweighted mean PCC | -0.001 (text, p.959: -0.0009) | -0.0009 | match |
| All, weighted mean PCC | -0.012 | -0.0118 | match |
| Developed, unweighted mean PCC | 0.020 | 0.0204 | match |
| Developed, weighted mean PCC | 0.011 | 0.0109 | match |
| Undeveloped, unweighted mean PCC | 0.001 | 0.0007 | match |
| Undeveloped, weighted mean PCC | -0.019 | -0.0193 | match |
| Published studies, mean PCC (Figure 3 text) | 0.0116 | 0.0116 | match |
| Mean of the study-level medians (p.959) | 0.0099 | 0.0099988 | **miss -- see below** |

### (b) The estimate corrected for publication bias -- Table 2 (pp.960-961)

Table 2 runs the funnel-asymmetry (FAT-PET) regression `PCC = beta0 + beta1 * SE(PCC) +
e` with study fixed effects, clustered by study, in four flavours. `beta0` ("Constant,"
labelled "effect beyond bias") is the number that justifies the phrase; the paper's own
reading (p.961): "the estimated size of the competition-stability effect beyond
publication bias appears to be close to zero, **especially for weighted results**."

| Specification | SE (pub. bias), paper | produced | Constant, paper | produced |
|---|---:|---:|---:|---:|
| Fixed effects (unweighted, all) | -1.671 | -1.6706 | 0.044 | 0.0440 |
| Fixed Effects_Published (unweighted) | -1.898 | -1.8978 | 0.073 | 0.0732 |
| Fixed effects (weighted, all) | -1.568 | -1.5685 | 0.034 | 0.0342 |
| Fixed Effects_Published (weighted) | -1.636 | -1.6364 | 0.044 | 0.0436 |

All eight match. The unweighted constants come from the frozen `st_xtreg_fe_cons()`;
the weighted ones from the `demean_add_weighted()` + `st_regress()` construction
described above, whose constants and standard errors agree with Stata to nine digits.

**Table 2's "Instrument" columns** (SE instrumented by log sample size) were attempted
and set aside: a study-demeaned 2SLS via `st_ivreg2`'s `y ~ 1 | endog ~ instrument`
syntax recovers the point estimate (-1.6144 against the printed -1.614), but the
recovered clustered SE does not reproduce the printed significance (p = 0.11 against
the paper's three stars), so that column is not claimed and is not among the targets.

## The one miss

| Target | Printed | Produced | Cause |
|---|---:|---:|---|
| Mean of the study-level medians (p.959) | 0.0099 | 0.0099988 | the paper truncates, the fourth digit differs |

Page 959 states: "the PCCs are symmetrically distributed around zero with a mean of
-0.0009, while the mean of the study-level medians is also close to zero and equals
0.0099."

The computation is no longer in doubt -- the author's own published do-file performs it
in two lines (`competition.do`, lines 13 and 21):

```stata
bysort IDStudy: egen PCCmed = median(PCC)
mean PCCmed
```

`egen` writes a study's median onto EVERY estimate of that study, so `mean PCCmed`
averages over the 598 estimates rather than over the 31 studies: a study enters in
proportion to how many estimates it reports. Run on the published CSV, in Stata and in
this package alike, that gives **0.00999882**. (The earlier version of this package
averaged across the 31 studies instead -- `mean(tapply(d$PCC, d$IDStudy, median))` =
-0.0042 -- and reported the number as not reproduced. That was the wrong aggregation
level; the do-file settles it.)

What remains is a printing difference, and it is stated rather than smoothed over.
Stata displays the mean as `.0099988`; the paper's text carries it **truncated**, not
rounded, as "0.0099". At four decimals the computed value rounds to 0.0100, so the
frozen rounding rule scores this target as a miss even though the quantity, the
command, and the data all agree. No adjustment was made to close a gap of one unit in
the last printed digit, and `targets.json` was not touched. (Its label for this target
still carries the parenthetical "(NOT reproduced, see run.R)" from when the quantity was
genuinely unidentified; the label is frozen with the rest of the oracle and has been
left exactly as it was.)

## Stochastic targets

None. Every target is a plain (weighted, clustered) mean or an OLS/FE regression --
fully deterministic given the data. No bootstrap, wild-cluster or simulation statistic
appears anywhere in the reproduced tables.

## How to run

```
Rscript run.R
```

Reads only `data/v1/competition/competition.csv`, which the site publishes. Writes
`results.json` in the working directory. No manual steps.
