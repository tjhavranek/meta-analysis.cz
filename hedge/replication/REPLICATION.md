# Replication package: "hedge" (Is research on hedge fund performance published selectively?)

Journal of Economic Surveys, 2024. doi: 10.1111/joes.12574.

## Table reproduced

**Table 4, "Risk models," Panel A only** (the linear FAT-PET / precision-effect-test
specifications — OLS, FE, BE, IV, WLS, wNOBS), both Part 1 (one-factor model,
`model_1factor==1`) and Part 2 (seven-factor model, `model_7factor==1`). Both rows
("Publication bias λ" and "Effect beyond bias κ"), their standard errors, the
first-stage robust F-stat, Studies, and Observations.

Table 4's Panel B (Top10, WAAP, Stem-based, Kinked-meta, Selection model, p-uniform*)
and Table 6 (top3/top5 journal subsamples) are **not attempted**: the author-code
excerpt supplied to this package contains no commands at all for Panel B's five
nonlinear estimators, and no explicit `if top3==1` / `if top5==1` block for Table 6 —
so there is nothing in the record to provenance those cells against. Tables 3 and 5
were not chosen because Table 4 was picked as the headline risk-model comparison; the
author code for those two tables' Panel A follows the identical pattern documented
below and would reproduce the same way if attempted.

## Provenance

Every regression below is a direct line-by-line reading of the author's `hedge.do`:

- Shared data construction, run once on the full 1019-row sample before any
  subsetting (do-file order matches this — winsorising happens right after import,
  and every subsequent `if` clause operates on the already-winsorised variables):
  - `instrument = 1/sqrt(sample_size)` — line 18
  - `winsor2 alpha, suffix(_w) cuts(1 99)` — line 19
  - `winsor2 se, suffix(_w) cuts(1 99)` — line 20
  - `tstat_w = alpha_w/se_w` — line 21
  - `precision_w = 1/se_w` — line 22
- Part 1 (one-factor model), lines 205–223: `egen count_M1f ... if model_1factor==1`
  (205), `gen weight_M1f = 1/count_M1f` (206), OLS `ivreg2 alpha_w se_w if
  model_1factor==1, cluster(study_id)` (207), FE `xtreg alpha_w se_w if
  model_1factor==1, fe vce(cluster study_id)` (210), BE `xtreg alpha_w se_w if
  model_1factor==1, be` (213), IV `ivreg2 alpha_w (se_w=instrument) if
  model_1factor==1, cluster(study_id) first` (214), WLS `ivreg2 tstat_w precision_w if
  model_1factor==1, cluster(study_id)` (218), wNOBS `ivreg2 alpha_w se_w
  [pweight=weight_M1f] if model_1factor==1, cluster(study_id)` (221).
- Part 2 (seven-factor model), lines 229–244 give the identical pattern for
  `model_7factor==1` through OLS/FE/BE/IV/WLS (229 count, 230 weight, 231 OLS, 234 FE,
  237 BE, 238 IV, 242 WLS); the brief's code excerpt is truncated at line 244, one line
  before the wNOBS `eststo` for this block. The wNOBS command for Part 2 is not shown
  verbatim, but the same 19-line block structure repeats identically five times
  earlier in the file (survivorship-treated/untreated, IV/non-IV method,
  1-factor/7-factor) with only the `if` condition and the weight variable name
  changing, and `weight_M7f` is already defined at line 230 for exactly this purpose —
  so the Part 2 wNOBS regression is `ivreg2 alpha_w se_w [pweight=weight_M7f] if
  model_7factor==1, cluster(study_id)`, by direct analogy to the five other blocks
  actually shown.

## Wrapper mapping

| Column | Stata command | R call |
|---|---|---|
| OLS | `ivreg2 alpha_w se_w, cluster(study_id)` | `st_ivreg2(alpha_w ~ se_w, cluster = ~study_id)` |
| FE (λ) | `xtreg alpha_w se_w, fe vce(cluster study_id)` | `st_xtreg_fe(alpha_w ~ se_w, panel = "study_id")` |
| FE (κ, i.e. `_cons`) | (same command, `_cons`) | `st_xtreg_fe_cons(y="alpha_w", x="se_w", panel="study_id", ...)` |
| BE | `xtreg alpha_w se_w, be` | study-mean aggregation (`aggregate`, base R, not an estimator call) then `st_regress(alpha_w ~ se_w)` on the collapsed data |
| IV | `ivreg2 alpha_w (se_w=instrument), cluster(study_id) first` | `st_ivreg2(alpha_w ~ 1 \| se_w ~ instrument, cluster = ~study_id)` |
| WLS | `ivreg2 tstat_w precision_w, cluster(study_id)` | `st_ivreg2(tstat_w ~ precision_w, cluster = ~study_id)` |
| wNOBS | `ivreg2 alpha_w se_w [pweight=weight], cluster(study_id)` | `st_ivreg2(alpha_w ~ se_w, cluster = ~study_id, weights = ~w_nobs)` |
| First-stage F | `ivreg2 ..., first` | see "One repair" below |

For OLS/IV/WLS/wNOBS the printed "Publication bias (λ)" is the coefficient on `se_w`
(or the intercept for the WLS column, since it is estimated on the SE-divided form of
the FAT-PET equation), and "Effect beyond bias (κ)" is the intercept (or the
coefficient on `precision_w` for WLS) — this follows directly from dividing the
FAT-PET equation `alpha = κ + λ·SE + e` through by SE to get
`alpha/SE = κ/SE + λ + e/SE`, i.e. `tstat = κ·precision + λ + e'`, which is exactly
the WLS column's regression command.

`xtreg, be` has no dedicated wrapper in `stata_compat.R`. Stata's between estimator
is mechanically OLS on the group (here, study-level) means with classical
(non-clustered) small-sample-corrected standard errors — the "regress" convention.
It is implemented here as an explicit `aggregate()` to study-level means (plain data
reshaping, not an estimator call) followed by `st_regress()`, one of the sanctioned
wrappers, on the collapsed one-row-per-study data. No new estimator is introduced;
`st_regress`'s own small-sample convention is unchanged.

## Target-by-target results

All 54 targets in `targets.json` matched at the printed precision.

| Label | Printed | Produced | Verdict |
|---|---|---|---|
| T4_P1_studies | 18 | 18 | MATCH |
| T4_P1_obs | 167 | 167 | MATCH |
| T4_P1_OLS_lambda | -0.456 | -0.45572 → -0.456 | MATCH |
| T4_P1_OLS_lambda_se | 0.488 | 0.48836 → 0.488 | MATCH |
| T4_P1_OLS_kappa | 0.562 | 0.56198 → 0.562 | MATCH |
| T4_P1_OLS_kappa_se | 0.0447 | 0.044657 → 0.0447 | MATCH |
| T4_P1_FE_lambda | -0.328 | -0.32756 → -0.328 | MATCH |
| T4_P1_FE_lambda_se | 0.657 | 0.65715 → 0.657 | MATCH |
| T4_P1_FE_kappa | 0.534 | 0.53371 → 0.534 | MATCH |
| T4_P1_FE_kappa_se | 0.145 | 0.14498 → 0.145 | MATCH |
| T4_P1_BE_lambda | 0.0326 | 0.032624 → 0.0326 | MATCH |
| T4_P1_BE_lambda_se | 0.494 | 0.49437 → 0.494 | MATCH |
| T4_P1_BE_kappa | 0.411 | 0.41097 → 0.411 | MATCH |
| T4_P1_BE_kappa_se | 0.119 | 0.11878 → 0.119 | MATCH |
| T4_P1_IV_lambda | -1.115 | -1.11482 → -1.115 | MATCH |
| T4_P1_IV_lambda_se | 0.819 | 0.81920 → 0.819 | MATCH |
| T4_P1_IV_kappa | 0.707 | 0.70739 → 0.707 | MATCH |
| T4_P1_IV_kappa_se | 0.175 | 0.17505 → 0.175 | MATCH |
| T4_P1_IV_firstF | 14.47 | 14.4722 → 14.47 | MATCH |
| T4_P1_WLS_lambda | 0.453 | 0.45341 → 0.453 | MATCH |
| T4_P1_WLS_lambda_se | 0.602 | 0.60166 → 0.602 | MATCH |
| T4_P1_WLS_kappa | 0.404 | 0.40432 → 0.404 | MATCH |
| T4_P1_WLS_kappa_se | 0.0883 | 0.088252 → 0.0883 | MATCH |
| T4_P1_wNOBS_lambda | -0.338 | -0.33820 → -0.338 | MATCH |
| T4_P1_wNOBS_lambda_se | 0.249 | 0.24950 → 0.249 | MATCH |
| T4_P1_wNOBS_kappa | 0.482 | 0.48241 → 0.482 | MATCH |
| T4_P1_wNOBS_kappa_se | 0.0931 | 0.093105 → 0.0931 | MATCH |
| T4_P2_studies | 33 | 33 | MATCH |
| T4_P2_obs | 298 | 298 | MATCH |
| T4_P2_OLS_lambda | -0.142 | -0.14203 → -0.142 | MATCH |
| T4_P2_OLS_lambda_se | 0.137 | 0.13713 → 0.137 | MATCH |
| T4_P2_OLS_kappa | 0.326 | 0.32577 → 0.326 | MATCH |
| T4_P2_OLS_kappa_se | 0.0392 | 0.039168 → 0.0392 | MATCH |
| T4_P2_FE_lambda | -0.0729 | -0.072868 → -0.0729 | MATCH |
| T4_P2_FE_lambda_se | 0.0547 | 0.054706 → 0.0547 | MATCH |
| T4_P2_FE_kappa | 0.308 | 0.30796 → 0.308 | MATCH |
| T4_P2_FE_kappa_se | 0.0141 | 0.014086 → 0.0141 | MATCH |
| T4_P2_BE_lambda | 0.305 | 0.30479 → 0.305 | MATCH |
| T4_P2_BE_lambda_se | 0.155 | 0.15493 → 0.155 | MATCH |
| T4_P2_BE_kappa | 0.200 | 0.20018 → 0.200 | MATCH |
| T4_P2_BE_kappa_se | 0.0730 | 0.072999 → 0.0730 | MATCH |
| T4_P2_IV_lambda | 0.624 | 0.62449 → 0.624 | MATCH |
| T4_P2_IV_lambda_se | 0.557 | 0.55666 → 0.557 | MATCH |
| T4_P2_IV_kappa | 0.128 | 0.12840 → 0.128 | MATCH |
| T4_P2_IV_kappa_se | 0.150 | 0.14997 → 0.150 | MATCH |
| T4_P2_IV_firstF | 3.41 | 3.41300 → 3.41 | MATCH |
| T4_P2_WLS_lambda | 0.0683 | 0.068279 → 0.0683 | MATCH |
| T4_P2_WLS_lambda_se | 0.296 | 0.29650 → 0.296 | MATCH |
| T4_P2_WLS_kappa | 0.284 | 0.28373 → 0.284 | MATCH |
| T4_P2_WLS_kappa_se | 0.0330 | 0.033003 → 0.0330 | MATCH |
| T4_P2_wNOBS_lambda | 0.226 | 0.22585 → 0.226 | MATCH |
| T4_P2_wNOBS_lambda_se | 0.265 | 0.26550 → 0.265 | MATCH |
| T4_P2_wNOBS_kappa | 0.222 | 0.22206 → 0.222 | MATCH |
| T4_P2_wNOBS_kappa_se | 0.0641 | 0.064127 → 0.0641 | MATCH |

**54 / 54 targets matched.**

## One repair (of at most 3 allowed)

**What was wrong:** the first attempt computed the IV column's "First-stage robust
F-stat" with `st_ivreg2_first_F(m_iv)`, the wrapper built for exactly this purpose. It
returned 15.42 (Part 1) and 3.53 (Part 2) against printed 14.47 and 3.41 — off by
precisely the factor `[G/(G-1)]·[(N-1)/(N-K)]` (checked arithmetically: 15.416/1.0652
= 14.469; the ratio for Part 2 works out the same way), i.e. a small-sample-adjustment
factor, not a rounding difference.

**Cause, cited from the wrapper's own documentation:** `stata_compat.R`'s comment on
`st_ivreg2_first_F` states explicitly: *"Note this uses fixest's DEFAULT adjustment,
not the large-sample one the coefficient table uses: ivreg2 reports first-stage
statistics with small-sample corrections even when the main table has none."*
Empirically, on the fixest build in this environment (0.14.2),
`fixest::fitstat(m, "ivwald1")` does not recompute with the default ssc as that
comment describes — it inherits the large-sample vcov already attached to `m` at
estimation time (`m` was built with `.SSC_LARGE` inside `st_ivreg2`, as required for
the main coefficient table). Passing an explicit `ssc=` argument to `fitstat()` made
no difference to the returned statistic (confirmed interactively).

**Fix:** the auxiliary first-stage regression `se_w ~ instrument` (clustered by
`study_id`) — the same regression `st_ivreg2_first_F`'s own comment describes — is run
directly through `st_regress()`, one of the sanctioned wrappers, which does apply
fixest's true default (small-sample) ssc. With a single excluded instrument, the
first-stage F collapses to the squared t-statistic on `instrument`, which reproduces
14.4722 and 3.4130 — both round to the printed 14.47 and 3.41. No estimator,
clustering variable, weight, winsorising convention, or degrees-of-freedom choice was
changed; the same first-stage OLS-with-cluster regression is run either way. Only the
R composition used to extract its small-sample-corrected F-stat changed, from a
wrapper call that (in this environment) silently fell back to the wrong vcov, to an
explicit call to the wrapper that is documented to carry the needed convention.

This was the only repair made. No other target required any change from the first
attempt.

## How to run

```
Rscript run.R
```

Reads `C:\Users\thavr\Dropbox\Study\Other\Agents\Joint\web_meta\site\data\v1\hedge\hedge.csv`
(the file the site publishes), sources `stata_compat.R`, prints every target's produced
value, and writes `results.json`.
