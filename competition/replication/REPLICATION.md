# Replication package: competition (Zigraiova & Havranek 2016, JEconSurveys)

Zigraiova, D. and Havranek, T. (2016). "Bank Competition and Financial Stability:
Much Ado About Nothing?" *Journal of Economic Surveys*, 30(5), 944-981.
doi: 10.1111/joes.12131

## Table reproduced

**Table 9, "Results for Frequentist Methods."** This is the paper's headline
fully-frequentist robustness table: OLS and study-fixed-effects regressions of the
partial correlation coefficient (PCC) of the reported competition-stability effect on
all 35 collected moderators, weighted by the inverse of the number of estimates
reported per study (`investperst`), with standard errors clustered by study
(`IDStudy`). It was chosen over the candidate BMA tables (7, 8, 10) because BMA has no
wrapper in `stata_compat.R` (the repository's own comment: "a Stata command with no
wrapper here is a stop-and-file event"), whereas Table 9 uses only OLS and fixed
effects, both of which are supported.

## Provenance

`site/competition/competition.do` (the archived author file) documents:
  - `ivreg2 PCC <PIP>0.5 subset> [pweight=investperst], cluster(IDStudy)` (line 74) --
    the weighted OLS "frequentist check" used in the paper's baseline Table 5 (and
    reproduced in Tables 7/8's "Frequentist check (OLS)" column, PIP > 0.5 subset only).
  - `xtreg PCC SEPCC [pweight=investperst], fe vce(cluster IDStudy)` (line 49) -- the
    weighted fixed-effects funnel-asymmetry test in Table 2.

Table 9 itself -- the ALL-35-variable OLS and FE check -- is described only in the
paper's text and table notes, not literally present in the archived `.do` file (it was
very likely produced from a later, unarchived revision of the do-file, added in
response to a referee: p.965 introduces it as the "third" of four robustness checks
added after the baseline). Its estimator, weight, and cluster choices come from:

  - p.965: "we run the BMA exercise with the same priors as in our baseline
    specification but ... we only use frequentist methods (OLS and fixed effects)."
  - Table 9's own note: "In the frequentist check we include all explanatory
    variables. The standard errors ... are clustered at the study level. The
    regressions are estimated by weighted least squares, where the inverse of the
    number of estimates reported per study is taken as the weight."

This is exactly the same weight (`investperst`) and cluster (`IDStudy`) as the
archived do-file's own baseline OLS/FE checks, so `st_ivreg2` (OLS) and `st_xtreg_fe`
(FE) are used with the SAME conventions the do-file already establishes, rather than
guessed independently for Table 9.

**Validation performed before committing to this specification** (not part of the
frozen targets, done purely to confirm the weight variable and wrapper convention):
running `st_ivreg2` with `weights = ~investperst, cluster = ~IDStudy` on exactly the
15-variable PIP>0.5 subset from do-file line 74 reproduces the paper's Table 5/7
"Frequentist check (OLS)" column EXACTLY, to every printed digit (e.g. SEPCC -1.1940
(0.6511), citations 0.0461 (0.0095), Constant -0.1184 (0.0860)). Running
`st_xtreg_fe` with `weights = ~investperst` on `PCC ~ SEPCC` reproduces Table 2's
weighted "Fixed effects" row (-1.568, matching the printed "-1.568***"). Both checks
confirm the weight variable, the cluster variable, and the wrapper conventions before
they are extended to the full 35-variable Table 9 specification.

## Variable construction

- `SEPCC` <- CSV column `SE PCC` (renamed; identical values, cosmetic name only).
- `TSLS` <- CSV column `2SLS` (renamed; not a valid bare R name).
- `Samplesize` <- `log(Samplesize)`. Table 4's variable-description column states the
  "Sample size" regressor is "the logarithm of the number of cross-sectional units",
  and reports mean 7.835 / SD 1.615 for it -- which is exactly `mean(log(Samplesize))`
  / `sd(log(Samplesize))` on the published CSV (7.835073 / 1.614506), and nothing like
  the raw column's mean of ~8382. (By contrast `T` needed no transformation: its raw
  mean/SD in the CSV, 2.224/0.743, already match Table 4's description of `T` as "the
  logarithm of the number of time periods" verbatim.)
- No other transformations. All other regressors are used as published.

## A formula-width limitation in the frozen wrapper, and how it was worked around

`st_xtreg_fe` builds its fixed-effects formula internally as
`as.formula(paste(deparse(fml), "|", panel))`. R's `deparse()` line-wraps any formula
whose text exceeds about 60 characters into a character VECTOR rather than a single
string; with 35 additive terms this always happens, and the wrapper's own
`paste()`/`as.formula()` step then breaks (`Error ... unexpected '|'`), regardless of
how the formula was constructed. This is a formula-width limitation of the wrapper's
own plumbing -- feols itself has no such limit, and fixest documents passing a
matrix-valued column as a single formula term (all of its columns are added to the
model as separate regressors) as normal syntax.

Packing the 35 moderators into one matrix column `X` (`d_fe$X <- as.matrix(d[,
fe_vars])`, `fml <- PCC ~ X`) keeps `deparse(fml)` at the seven characters `"PCC ~ X"`
-- a single string -- so the wrapper's paste/as.formula step behaves exactly as it
does for every short-formula call elsewhere on this site, while `feols` underneath
fits the identical linear model (same estimator, same weights, same cluster, same
degrees of freedom -- only how the formula text is packed for the wrapper's own
string-handling changed). This was verified, not assumed: the resulting FE
coefficients and SEs are checked cell-by-cell against Table 9 below and match to the
printed precision.

One consequence of packing the regressors into a matrix column is that `developed`
and `undeveloped` needed reordering (`undeveloped` placed before `developed` in
`fe_vars`, against Table 9's own printed column order). In the study-FE model the two
are perfectly collinear within any study that reports estimates for only one of the
two groups (`developed = 1 - undeveloped` within that study once demeaned by the
study fixed effect), and one of the two must be dropped by `feols`. `feols` drops
whichever collinear column comes SECOND in the design matrix. Table 9 reports
"developed (omitted)" with `undeveloped` estimated at 0.1020 (0.0760) -- so the
(unarchived) do-file's own variable order for Table 9 must have listed `undeveloped`
before `developed`. Reordering to match is a variable-construction choice, not a
change to the estimator, weights, clustering, or degrees of freedom: every OTHER
coefficient is numerically identical regardless of this order (verified directly --
switching the order changes only which of the two dummies is reported and its sign,
not any other cell).

## Target-by-target results

All 134 frozen targets are from Table 9 (pp.970-971 of the PDF), OLS and FE columns,
every coefficient, every standard error, N, and study count. 132 of 134 matched
exactly (to the printed 4th decimal / exact count). The two misses are both for the
FE column's constant term; see "Misses" below.

Representative rows (see `targets.json` / `results.json` for the full 134-cell table):

| Label | Printed | Produced | Verdict |
|---|---|---|---|
| T9 OLS SEPCC coef | -1.5708 | -1.5708 | match |
| T9 OLS SEPCC se | 0.8567 | 0.8567 | match |
| T9 OLS Samplesize coef | -0.0363 | -0.0363 | match |
| T9 OLS developed coef | 0.1689 | 0.1689 | match |
| T9 OLS Hstatistic coef | 0.1629 | 0.1629 | match |
| T9 OLS Logit coef | -0.1481 | -0.1481 | match |
| T9 OLS Constant coef | -0.1350 | -0.1350 | match |
| T9 OLS N | 598 | 598 | match |
| T9 OLS Studies | 31 | 31 | match |
| T9 FE SEPCC coef | -1.6234 | -1.6234 | match |
| T9 FE macro coef | 0.1882 | 0.1882 | match |
| T9 FE undeveloped coef | 0.1020 | 0.1020 | match |
| T9 FE undeveloped se | 0.0760 | 0.0760 | match |
| T9 FE Boone coef | 0.0744 | 0.0744 | match |
| T9 FE N | 598 | 598 | match |
| T9 FE Studies | 31 | 31 | match |
| T9 FE Constant coef | -0.1783 | -- | **unresolved** |
| T9 FE Constant se | 0.1656 | -- | **unresolved** |

(All 28 non-omitted FE coefficients and all 35 OLS coefficients, plus their SEs, N,
and study counts for both columns -- 132 of 134 cells -- matched exactly; only the two
FE-column constant cells are unresolved.)

## Misses

| Target | Printed | Produced | Cause |
|---|---|---|---|
| T9 FE Constant coef | -0.1783 | (not computed) | unresolved |
| T9 FE Constant se | 0.1656 | (not computed) | unresolved |

`feols` does not report an intercept for a model with an absorbed fixed effect at
all. The frozen `st_xtreg_fe_cons()` helper recovers Stata's `xtreg, fe` constant (the
grand mean of y minus the within slope times the grand mean of x) via an augmented
within regression, but that helper's demeaning is UNWEIGHTED: it computes
`ave(y, group)` and the unweighted grand mean, with no `weights` argument at all. Table
9's FE column is weighted by `investperst`, and there is no weighted counterpart of
that helper available. Per the brief, `stata_compat.R` is not to be edited and no bare
`feols`/`lm` call is permitted outside the frozen wrappers, so a hand-rolled
weighted-demeaning formula was not used to fill this cell. This is a genuine gap
between what the frozen wrapper set can compute and what the paper prints for these
two cells specifically -- not a computational disagreement -- so it is reported as an
unresolved miss rather than guessed at.

No repairs were needed to the sample, variable construction, or target reading beyond
what is documented above (the `Samplesize` log-transform, confirmed against Table 4's
own summary statistics before running any regression, and the `developed`/`undeveloped`
collinearity-order fix, confirmed to leave every other coefficient unchanged).

## Stochastic targets

None. Table 9 contains no bootstrap, wild-cluster, or simulation-based statistic --
both columns are plain (weighted, clustered) OLS/FE, fully deterministic given the
data.

## How to run

```
Rscript run.R
```

Reads only `data/v1/competition/competition.csv` (published by the site). Writes
`results.json` in the working directory. No manual steps.
