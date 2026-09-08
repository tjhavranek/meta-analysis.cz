# dst -- replication package

**Paper:** "Does Daylight Saving Save Electricity? A Meta-Analysis", *Energy Journal* (2018),
doi.org/10.5547/01956574.39.2.thav

**Table reproduced:** Table 3, "Funnel Asymmetry Tests Show No Publication Bias" -- three of its
six columns (OLS, FE, ME); see Scope below for why the other three (BE, Country, IV) are not
attempted.

**Provenance:** author code (`dst.do`, provided in the brief as a line excerpt) plus the
published data file `data/v1/dst/dst.csv` (174 rows as listed on the site; 162 parse as data
rows once quoted multi-line REFERENCE fields are handled correctly by a real CSV reader -- the
174 count in the site's own description counts raw lines, not records).

## The model

The paper's stated equation (Table 3 notes) is the levels form

    ESTIMATE_ij = DST0 + beta * SE(ESTIMATE_ij) + u_ij

"estimated by weighted least squares with the inverse of the reported estimate's standard error
taken as the weight." Dividing that regression through by SE_ij gives the algebraically
identical, correctly precision-weighted form

    TSTAT_ij = beta + DST0 * PRECISION_ij + eps_ij,   TSTAT = ESTIMATE/SE, PRECISION = 1/SE

the standard Stanley-Doucouliagos precision-effect/funnel-asymmetry test. In this form, the row
the paper labels **"SE (publication bias)"** is the regression's *intercept*, and the row labeled
**"Constant (true effect)"** is the *coefficient on PRECISION*. This is exactly what the author's
own do-file runs for the neighbouring specifications in the excerpt (`ivreg2 TSTAT PRECISION,
cluster(...)` at line 167; `xtreg TSTAT PRECISION, fe vce(cluster IDSTUDY)` at line 168; `xtreg
TSTAT PRECISION, be` at line 169), and it is what reproduces Table 3's numbers.

This was not the first thing tried. The literal levels form, `ivreg2 ESTIMATE SE [pweight=1/SE],
cluster(IDSTUDY IDCOUNTRY)` (dst.do line 163, which textually matches the notes' "inverse of SE
as weight" description most directly), was tried first and does **not** reproduce the table: it
gives an OLS constant-row SE around 0.014 against a printed 0.000778, off by more than an order
of magnitude. The TSTAT/PRECISION form matches to the last printed digit on every cell tried,
including that same striking near-zero SE -- a known feature of precision-weighted funnel
regressions when a couple of very precise estimates dominate the weighting, not an artifact.

## Data preparation

The funnel-test estimation sample is every row with a reported standard error (the test only
makes sense where an SE exists to check for asymmetry against). Table 3's own notes state
"Outliers are excluded from the figure but included in all statistical tests," so no outlier
trimming is applied. `TSTAT` and `PRECISION` are derived as `ESTIMATE/SE` and `1/SE`; these match
the published `TSTAT`/`PRECISION` columns in `dst.csv` to floating-point precision (max
discrepancy 1.4e-14), confirming the derivation is exactly what the site's own published columns
already encode.

Filtering to non-missing `SE` gives N = 101, matching the printed N for every column attempted
(and for BE, per its printed row, even though BE is not attempted here).

## Target-by-target results

| Target | Printed | Produced | Verdict |
|---|---|---|---|
| OLS SE coef (intercept) | -0.410 | -0.410004 | MATCH |
| OLS SE se | 0.265 | 0.264681 | MATCH |
| OLS const coef (PRECISION) | -0.293 | -0.293442 | MATCH |
| OLS const se | 0.000778 | 0.000778 | MATCH |
| OLS N | 101 | 101 | MATCH |
| FE SE coef (xtreg _cons) | -1.217 | -1.216880 | MATCH |
| FE SE se | 0.790 | 0.790254 | MATCH |
| FE const coef (PRECISION) | -0.222 | -0.221972 | MATCH |
| FE const se | 0.0700 | 0.069998 | MATCH |
| FE N | 101 | 101 | MATCH |
| ME SE coef (intercept) | -0.449 | -0.449060 | MATCH |
| ME SE se | 0.688 | 0.688257 | MATCH |
| ME const coef (PRECISION) | -0.291 | -0.291006 | MATCH |
| ME const se | 0.00731 | 0.007313 | MATCH |
| ME N | 101 | 101 | MATCH |

15 of 15 attempted (deterministic + count) targets match at the printed precision. No repairs
were needed -- the only correction made before the first clean run was the model-form correction
above (levels-WLS to the algebraically equivalent TSTAT/PRECISION form), which is a
transformation choice, not a change of estimator, weights, clustering, or degrees-of-freedom
convention: both forms are the same regression.

## Scope: three columns of Table 3 are not reproduced

**BE (between effects).** Stata's `xtreg ..., be` has no wrapper in `stata_compat.R` --
`st_xtreg_fe` implements only the within (fixed-effects) estimator, and Stata's between
estimator has its own degrees-of-freedom convention that a manual "collapse to group means, then
regress" does not reproduce exactly (in particular, Stata's `xtreg` reports the *original* N in
this column, 101, not the number of groups, 13 -- consistent with genuine `xtreg` behavior and
inconsistent with a naive collapsed OLS, which would report N=13). Per the brief, a needed Stata
command with no wrapper is a stop-and-report, not a substitute. `unsupported_command`: `xtreg
..., be`.

**Country (country-level fixed effects).** Every panel/cluster variable actually evidenced in
the data was tried under `st_xtreg_fe`:
- `COUNTRY` (8 groups in the SE-present subsample), clustered on itself, on `IDSTUDY`, and
  two-way: PRECISION coefficient -0.2733 in every case (cluster choice does not move the point
  estimate, only its SE) -- printed is -0.278.
- `COUNTRYA` (the do-file's own adjusted grouping, visible in the published CSV, which merges
  Australia into USA and Sweden into Norway: 6 groups), same three clustering choices:
  PRECISION coefficient -0.2789 -- closer, but rounds to -0.279 against a printed -0.278, and no
  clustering choice reproduces the printed SE of 0.805 (closest obtained: 0.0109-0.0686 depending
  on cluster spec).

Neither grouping variable reproduces both the coefficient and its SE, and the provided do-file
excerpt contains no explicit "Country" `xtreg`/`ivreg2` line to check the construction against
(the excerpt's `xtreg`/`ivreg2` lines cover the OLS, FE, BE, and per-country single-country
subsample regressions of Section 5.2, not a pooled country-FE specification). Rather than guess
a construction not evidenced anywhere in the brief, this column is left unresolved.

**IV.** Table 3's footnote describes the instrument only in prose ("the number of observations
(if the study is based on regression analysis)"), and no `ivreg2 ... (SE = ...)` line appears
anywhere in the provided author-code excerpt. The column's own printed N (90) is one row short
of the `REGRESSION==1` subsample (91 rows), so some further, unstated restriction is also in
play. Reconstructing the exact instrument and sample restriction would mean guessing an
estimator input the brief does not evidence -- left unresolved.

## Kind classification (per assignment's cause taxonomy)

- BE: cause `estimator` (no wrapper for Stata's between estimator).
- Country: cause `unresolved` (plausible grouping variables tried; none reproduce both
  coefficient and SE; construction not evidenced in the provided code excerpt).
- IV: cause `unresolved` (instrument construction and sample restriction not evidenced in the
  provided code excerpt).

## How to run

```
Rscript run.R
```
from this directory. Reads only `data/v1/dst/dst.csv` (a file the site publishes) and
`stata_compat.R` (sourced from its frozen, hash-checked location as required by the assignment;
ships alongside `run.R` on publication). Writes `results.json` and prints every produced number.
No manual steps.

## Verdict (Table 3)

**PARTIAL.** All 15 targets attempted (three of Table 3's six columns) match the printed values
to the printed precision, with zero repairs needed beyond the initial model-form identification.
Three columns (BE, Country, IV) are excluded from `targets.json` rather than guessed, for the
reasons above.

## Numbers from the paper's text

meta-analysis.cz's own summary of this paper reads: "essentially zero, 0.01% savings, against a
0.34% simple average of reported estimates." Both halves are the paper's own words, and `run.R`
now reproduces both, printed clearly at the end of the run.

| Claim | Quantity | Paper's value | Produced | Verdict |
|---|---|---|---|---|
| Abstract: "...find that the mean reported estimate indicates slight electricity savings: 0.34% during the days when DST applies." | Unweighted mean of `ESTIMATE` across all 162 published estimates | -0.34% (abstract); Table 2, "All observations": -0.334 | -0.334454 | **MATCH** (to the printed 3rd decimal) |
| Section 4.3 / Table 6: "The resulting global estimate is -0.01%, quite distant from -0.34%, the simple average effect reported in the literature." | The "best-practice" BMA-implied DST effect, averaged across all 21 countries in the sample | -0.01% (text); Table 6, "All countries": -0.014 (95% CI -0.760, 0.732) | -0.019053 | **CLOSE, not exact** -- see below |

### How the -0.34% is produced

Read directly off `st_regress(ESTIMATE ~ 1, data = d)$estimate` -- the OLS intercept with no
regressors is the sample mean, computed via the sanctioned wrapper rather than a bare `mean()`
call. `d` is the full 162-row published sample (matches the paper's "162 estimates from 44
studies" exactly). No estimation choices are involved; this is a plain arithmetic average.

### How the -0.01% is produced, and why it is close but not exact

This number is **not a regression this package can re-run from scratch**. The paper builds it in
two stages: (1) fit a Bayesian model averaging (BMS) regression of `ESTIMATE` on 14 explanatory
variables (Table 5), using a specific g-prior/model-prior combination; (2) evaluate that fitted
model at a "best practice" combination of covariate values, once per country, then average across
countries. Stage (1) is a BMS model -- not `feols`/`lm`/`rma`/`lmer`, and not among
`st_ivreg2`/`st_xtreg_fe`/`st_regress`/`st_metan`/... -- so it is a stop-and-report by the same
rule that governs Table 3's BE/Country/IV columns: no wrapper exists for it, and one is not
invented here.

What **is** reproducible from the published data, without re-fitting BMS, is stage (2): the linear
combination itself, using Table 5's own printed posterior-mean coefficients (already a published
number, quoted verbatim in `run.R`, not something this package estimates) and the paper's
prose definition of "best practice" (Section 4.3, quoted verbatim in `run.R`). Every input that
*can* come from the data does:

- `imp_95`, the 95th percentile of `IMPACT`, via `st_winsor2(IMPACT, cuts = c(0, 95))` and
  `max()` of the result -- winsorising at the 95th percentile caps every value above it at that
  percentile, so the winsorized maximum recovers the percentile itself, using the sanctioned
  wrapper's Stata-`_pctile` (type-2) convention rather than calling `quantile()` directly.
- `max_citations` and `log(max_citations + 1)` -- "Citations" enters the BMA as
  log(citations + 1): Table 4 reports its sample mean as 1.91, which matches
  `log(CITATIONS + 1)` computed here (1.9095) and not `log(CITATIONS)` (1.7241, undefined at
  `CITATIONS = 0`).
- `max_pubyear - 1970` -- "Publication year" is `PUBYEAR - 1970` (Table 4: "base = 1970"; its
  reported sample mean, 34.8, matches `mean(PUBYEAR) - 1970` = 34.82 computed here).
- Per-country average `DAYLIGHT`, and per-country `WEIGHT` sums (the paper's own inverse
  per-study weight column, the same one behind Table 2's "weighted by the inverse of the number
  of estimates reported per study" right-hand columns) -- both plain aggregation, no estimation.

Combined with the fixed best-practice values from Section 4.3's prose (Data period = 9,
Main estimate = 1, Daily data = 0, Difference-in-differences = 1 with Regression = Simulation = 0,
Residential = Lighting = 0, Journal publication = 1, USA = 1 for the USA row only), this gives one
predicted effect per country, aggregated to "All countries" using the same WEIGHT-weighted average
the paper uses for all its other equal-per-study aggregates.

**This reconstruction gives -0.019, not -0.014.** The gap is small (0.005 percentage points) and
traced, not papered over: comparing this package's own 21 per-country predictions against Table
6's own printed per-country values (computed in `run.R`, printed as a diagnostic, not a target)
shows a near-constant offset of about 0.005-0.007 across every single country, in the same
direction. That is the signature of compounding rounding in Table 5's coefficients, which are
printed to only 3 decimals across 14 terms -- not a wrong model or wrong best-practice values. As
a check on the AGGREGATION rule specifically (not the model): re-applying the identical
WEIGHT-weighted average directly to the paper's **own printed** Table 6 country estimates (no
data-derived inputs at all, just re-averaging numbers already in the paper) gives -0.0134, matching
the printed -0.014 almost exactly. That confirms the weighting scheme used here is the right one,
and that the residual gap in the -0.019 figure is precision in Table 5's printed coefficients, not
a methodological error. Both figures are printed by `run.R`, clearly labelled as diagnostics rather
than targets.

**Honesty on this number**: `-0.014` is entered in `targets.json` as the value the paper states
(kind `"headline"`), and `results.json` records what this package actually produces, -0.019. It is
reported as a **close, not exact** reproduction, for the reason given above -- a genuine
data-and-formula-driven approximation of a number whose exact reproduction would require re-fitting
the authors' BMS specification, which is outside the sanctioned toolkit.
