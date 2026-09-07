# Replication package: gasoline (Havranek & Kokes 2015)

**Paper.** Tomas Havranek & Ondrej Kokes (2015), "Income elasticity of gasoline
demand: A meta-analysis," *Energy Economics* 47, 77-86.
https://doi.org/10.1016/j.eneco.2014.11.004

**Table reproduced.** Table 6, "Determinants of heterogeneity in the reported
long-run estimates" — the paper's augmented (multivariate) meta-regression,
all three specifications, all rows, including the Observations row: **135
target cells, 135 matched, 0 misses.**

**Provenance.** `author_code` (data.zip:init.do, lines 168-177, define `se`,
`prec`, and the Pubyear/Datayear/Timespan transforms used as regressors)
combined with the paper's own methods text (Section 3.2, Eq. 11; Section 5),
which supplies the exact model equation the do-file fragment stops short of.

**Verdict: CONCORDANT.**

## Why Table 6, not Tables 2-5

The site's published CSV (`data/v1/gasoline/gasoline.csv`, 701 rows, no
short-run/long-run indicator column) turns out to be the paper's **long-run
sample only**: its `e` range (-1.13 to 2.98) matches exactly the long-run
range printed in the paper's Table 2, not the short-run range (-1.17 to 3),
and its `Carstock` column splits the file almost exactly in half (350/351),
matching the paper's two long-run sub-samples (346/346 after a further trim,
see below). Tables 2-5 report a "Whole sample" (short-run, N=831) column that
needs short-run estimates the published file does not carry, so those columns
cannot be reproduced from what the site publishes; that is a data
availability limit of the published file, not an estimation error.

Table 6 pools both long-run sub-samples with `Carstock` as a regressor
(paper's own N = 692 = 346+346), which is exactly what the published CSV
contains, and every one of its rows maps onto a column already in the file.
It is the one headline table fully reproducible from this data set alone,
and it is the paper's main contribution (Section 5, "Augmented
meta-regression").

## The precision trim (discovered, not assumed)

The do-file fragment we have stops at line 185 (a loop generating the `_se`
moderator variables), one line short of the actual `mixed`/`regress` command.
Fitting the model on the full 701/350/351 rows reproduces nothing in the
paper: e.g. a plain `tstat ~ prec + (1|Studyid)` mixed model on the
Carstock==1 subsample gives a precision coefficient around 0.45, nowhere near
the printed 0.209 (Table 3) or 0.234 (Table 4). A handful of extreme
observations (1/se as high as 166.7, one reported t-statistic of 160) get
enormous leverage in this unweighted-after-transformation regression.

`data.zip:init.do` lines 85-87 apply exactly the bound `Ysrseinv < 100` /
`Ystatseinv < 100` when identifying observations for a related robustness
statistic (the "top-precision" weighted means quoted in Section 4.2). Trying
the same threshold as a sample trim before the main regressions:

- it drops exactly 4 rows from Carstock==1 (350 -> 346) and 5 rows from
  Carstock==0 (351 -> 346) — the paper's own printed N for every one of
  Tables 2-5;
- dropping the same 9 rows from the pooled 701 gives exactly 692 — the
  paper's own printed N for Table 6.

This is confirmed, not merely plausible: applying the trim and re-estimating
Table 3 (`tstat ~ prec + (1|Studyid)`) and Table 4 (`tstat ~ prec + se - 1 +
(1|Studyid)`, no intercept — Table 4's printed table has no Constant row,
matching Eq. (10)) on the two Carstock subsamples reproduces **all eight**
coefficient-and-t-statistic cells of Tables 3 and 4 exactly (0.209/7.71,
1.573/1.97, 0.592/15.50, 3.032/1.77, 0.234/9.76, -0.0501/-0.11, 0.644/17.38,
0.965/2.73). Table 6 is the only table in `targets.json` (Tables 3-4 were
used only as an internal check, since our data cannot supply their
short-run column), but this cross-check is strong independent evidence the
trim and the estimation convention are both right, not curve-fit to Table 6
alone.

The repair is a **sample filter**, cited from the author's own code, applied
identically to the whole file before any other construction step — not a
change to the estimator, weights, clustering, or a targets.json edit.

## Model

Paper's Eq. (11) (Section 3.2, extended in Section 5):
```
t_ij = beta/se_ij + alpha0 + sum_l delta_l S_ijl + sum_k alpha_k Z_ijk/se_ij + u_i + eps_ij
```
`t` = reported t-statistic (`tstat` column, sign preserved); `se = |e/tstat|`
(do-file line 168); `1/se` = precision (line 169); `u_i` = random intercept
by `Studyid` (paper: "mixed-effects multilevel framework"); every moderator
is divided by `se` **except** the two publication characteristics (Published,
Publication year), which enter undivided — this is the paper's own footnote
to Table 6 ("All variables except those in italics are divided by the
standard error") and Section 5's text ("we do not divide the publication
characteristics by the standard error").

`Mean year of data` = `Datayear - 1946.5`, `Time span` = `log(Timespan)`,
`Publication year` = `Pubyear - 1966` (do-file lines 174-176, and these
centering constants are exactly the raw column minima in the site's own
codebook, confirming the published CSV is pre-transform).

Estimated via `st_mixed()` (`lme4::lmer(..., REML = FALSE)`, matching
Stata's `mixed`'s ML default) with `(1 | Studyid)`. Three specifications
built additively: (1) 1/se + 6 data-characteristic + 8 method-dummy
moderators (all /se); (2) + 8 region/geography dummies (/se); (3) + 2
publication characteristics (undivided) — reproducing the paper's own
"we control for 24 variables" (6+8+8+2) and the growing regressor list
across columns (1)-(3) of Table 6.

## Target-by-target results

All 135 target cells (coefficient and t-statistic for every non-blank cell
of Table 6's three columns, plus the three Observations rows) match the
printed value at the printed rounding precision. A representative sample
(full detail in `targets.json` / `results.json`):

| Row | Spec | Printed coef | Produced | Printed t | Produced t |
|---|---|---|---|---|---|
| 1/se | (1) | 0.257 | 0.2568 | 1.39 | 1.394 |
| 1/se | (2) | 0.892 | 0.8923 | 4.67 | 4.667 |
| 1/se | (3) | 0.827 | 0.8272 | 4.17 | 4.167 |
| Time span | (1) | 0.335 | 0.3351 | 7.61 | 7.609 |
| Vehicle stock | (1) | -0.860 | -0.8598 | -20.47 | -20.465 |
| Vehicle stock | (3) | -0.773 | -0.7735 | -19.86 | -19.861 |
| Canada | (2) | -0.822 | -0.8222 | -11.73 | -11.727 |
| Published | (3) | -1.184 | -1.1842 | -0.77 | -0.768 |
| Publication year | (3) | -0.124 | -0.1237 | -1.27 | -1.267 |
| Constant | (1) | 2.534 | 2.5342 | 2.48 | 2.479 |
| Constant | (2) | 1.690 | 1.6904 | 1.96 | 1.962 |
| Constant | (3) | 4.937 | 4.9372 | 2.19 | 2.188 |
| Observations | (1)/(2)/(3) | 692 | 692 | -- | -- |

Every other row (Mean year of data, Quarterly/Monthly data, Cross-section,
Time series, Static model, OLS, IV, SUR, ML, ECM, GLS, Developing countries,
Australia, France, Germany, Japan, Sweden, USA) matches identically across
all three specifications — see `results.json` for the full 135-value output.

## Misses

None. Every deterministic target (all 135 cells; no stochastic estimator is
used anywhere in this table) matches the printed value at the printed
rounding precision.

## Reproducing

```
Rscript run.R
```
reads `data/v1/gasoline/gasoline.csv` (the file the site publishes),
prints every produced number, and writes `results.json` next to itself.
No manual steps. Uses only `stata_compat.R`'s `st_mixed()` wrapper.
