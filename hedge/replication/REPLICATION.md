# Replication package: "hedge" (Is research on hedge fund performance published selectively?)

Journal of Economic Surveys, 2024. doi: 10.1111/joes.12574.

## Tables reproduced

**Table 4, "Risk models," Panel A only** (the linear FAT-PET / precision-effect-test
specifications — OLS, FE, BE, IV, WLS, wNOBS), both Part 1 (one-factor model,
`model_1factor==1`) and Part 2 (seven-factor model, `model_7factor==1`). Both rows
("Publication bias λ" and "Effect beyond bias κ"), their standard errors, the
first-stage robust F-stat, Studies, and Observations.

**Table 2, "Full sample results," Panel A only** (same six linear specifications, no
`if` restriction at all — `hedge.do` lines 88–106). This is the table the paper's
headline "30–40 basis points" claim is actually built from; see "Numbers from the
paper's text" below.

Table 4's Panel B (Top10, WAAP, Stem-based, Kinked-meta, Selection model, p-uniform*),
Table 2's Panel B (the same five nonlinear estimators plus Top10), and Table 6
(top3/top5 journal subsamples) are **not attempted**: the author-code excerpt supplied
to this package contains no commands at all for the five nonlinear estimators, and no
explicit `if top3==1` / `if top5==1` block for Table 6 — so there is nothing in the
record to provenance those cells against, and no `stata_compat.R` wrapper implements
any of Top10/WAAP/Stem-based/Kinked-meta/Selection-model/p-uniform* either. Tables 3
and 5 were not chosen because Table 4 was picked as the headline risk-model
comparison; the author code for those two tables' Panel A follows the identical
pattern documented below and would reproduce the same way if attempted.

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
- **Table 2 Panel A (full sample), lines 88–106** — the un-subsetted block that every
  Table-3/4/5/6 `if`-conditioned block above is a copy of. `xtset study_id` (88), OLS
  `ivreg2 alpha_w se_w, cluster(study_id)` (91), FE `xtreg alpha_w se_w, fe
  vce(cluster study_id)` (94), BE `xtreg alpha_w se_w, be` (97), IV `ivreg2 alpha_w
  (se_w=instrument), cluster(study_id) first` (98), WLS `ivreg2 tstat_w precision_w,
  cluster(study_id)` (102), wNOBS `ivreg2 alpha_w se_w [pweight=weight],
  cluster(study_id)` (105) — `weight` here is `1/count(alpha)` with no `if` clause,
  i.e. `1 / (number of alphas for that study in the full 1019-row sample)`, computed in
  `run.R` the same way as every other `w_nobs` block (`table(sub$study_id)` on the
  un-subsetted data). Reuses the shared `run_panelA()` helper with
  `condition = rep(TRUE, nrow(d0))`, i.e. no row is dropped.

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

## Numbers from the paper's text

meta-analysis.cz summarises this paper as **"30–40 basis points per month."** That
phrase is the abstract's own words: *"Most of our monthly alpha estimates adjusted for
the (small) bias fall within a relatively narrow range of 30–40 basis points."*
Working out what that range actually is (traced through the body text, Table 2, Table
A.2, and Table 7's "Results overview"):

Table 2 ("Full sample results") has two panels, **twelve** "effect beyond bias" (κ,
the publication-bias-*corrected* alpha) cells for the full 1019-observation sample —
Panel A: OLS/FE/BE/IV/WLS/wNOBS (the linear FAT-PET/PEESE family); Panel B: Top10,
WAAP, Stem-based, Kinked-meta, Selection model, p-uniform* (five nonlinear
meta-analysis estimators). The paper's own numbers, read straight off the printed
Table 2:

- Panel A κ: 0.366, 0.369, 0.350, 0.316, 0.301, 0.353 (OLS/FE/BE/IV/WLS/wNOBS)
- Panel B κ: 0.310, 0.325, 0.355, 0.320, 0.274, 0.386 (Top10/WAAP/Stem/Kinked/Selection/p-uniform*)

Min/max/mean/median of all twelve: 0.274 / 0.386 / 0.3355 / 0.3375 — exactly Table 7's
printed row for "Table 2, Full sample" (Min 0.274, Max 0.386, Mean 0.335, Md 0.338).
**The abstract's "30–40 basis points" is this twelve-cell range**, rounded outward to
whole tens of basis points (27.4 → "30", 38.6 → "40").

| Claim in the paper | Quantity | Paper's value | Produced by `run.R` | Reproduced? |
|---|---|---|---|---|
| "Most ... alpha estimates ... fall within a ... range of 30–40 basis points" (Abstract) | min/max of Table 2's 12 κ cells (Panel A + Panel B) | 0.274 to 0.386 | Panel A (6 cells): **0.301 to 0.369**, reproduced exactly from `hedge.csv`. Full 12-cell range (adding Panel B's paper-printed 0.274/0.386, not independently recomputed — see below): 0.274 to 0.386 | **Partially** — Panel A (6/12 cells) fully reproduced; Panel B (5 nonlinear estimators) cannot be, for lack of a wrapper or author code (see below) |
| "the κ coefficients fall within a fairly narrow interval of (0.301, 0.369)" (Section 4.4, discussing Table A.2's team-clustering robustness — same point estimates as Table 2, only SEs differ under a different clustering variable) | min/max of Table 2 Panel A's 6 κ cells | 0.301 to 0.369 | **0.301 to 0.369** | **Yes, exact** |
| Table 7 row "Table 2 / Full sample": Mean 0.335, Md 0.338 | mean/median of all 12 κ cells | 0.335 / 0.338 | Panel A (6 cells) alone: mean 0.343, median 0.352 (reproduced, but not the number quoted — that number needs all 12 cells). Full 12-cell mean/median (6 reproduced + 6 paper-quoted): **0.3355 / 0.3375** | **Partially**, same caveat |
| "the unconditional sample mean of monthly alphas of 0.36%, which corresponds to 4.3% per annum" (Section 3, Figure 3) | plain mean of `alpha_w` (winsorised alpha, no regression) across all 1019 rows | 0.36% (4.3% p.a.) | **0.3623%** (annualized 4.35%; the paper's "4.32%" in one passage comes from multiplying its own *rounded* 0.36 by 12, not the unrounded mean) | **Yes** |

**Why Panel B (5 of the 12 cells behind the headline range) is not reproduced:**
Top10, WAAP, Stem-based, Kinked-meta, the Andrews–Kasy (2019) selection model, and
p-uniform* are five distinct meta-analysis estimators, none of which has a wrapper in
`stata_compat.R` (whose sanctioned list is `st_ivreg2`, `st_xtreg_fe`, `st_regress`,
`st_metan`, the three winsorising wrappers, `st_drop_if`/`st_keep_if`, `st_coefs`, plus
a plain mixed-model wrapper — nothing that implements a selection model, a
weighted-adequately-powered filter, or `p-uniform*`). The brief's author-code excerpt
of `hedge.do` likewise contains no commands for them at any line. Implementing them
from scratch would mean calling an estimator (`rma`, or a hand-rolled likelihood) this
package is explicitly barred from calling directly, and inventing an ad hoc
implementation not tied to any author command would not be a *replication* of
anything — it would just be a new estimate with the same name. So `run.R` records the
five Panel B κ values exactly as the paper prints them (labelled
`..._PAPER_VALUE_NOT_REPRODUCED` in `results.json`, `"kind": "not_reproduced"` in
`targets.json`, excluded from the reproduced-target count below) purely so a reader can
see, by direct arithmetic, that combining them with this package's own from-data Panel
A numbers reconstructs Table 7's printed Mean/Md/Min/Max — not as a claim that Panel B
itself was recomputed.

**Bottom line:** every number this package's tools can actually compute from
`hedge.csv` for the "30–40bp" claim — the six Panel A linear specifications of Table 2,
and the plain unconditional sample mean — reproduces the paper's printed values
exactly. The claim's outer bounds (27.4bp and 38.6bp) come from two of the five
nonlinear Panel B estimators, which are out of reach of the tools this package is
allowed to use.

## Target-by-target results

All 54 original Table-4 targets in `targets.json` matched at the printed precision
(unchanged from the first version of this package). A further 41 targets from Table 2 /
the paper's text were appended for this task: 29 marked `"kind": "headline"` plus 2
`"kind": "count"` (i.e., 31 genuinely reproduced from `hedge.csv`, all matching
exactly) and 10 marked `"kind": "not_reproduced"`, which record the paper's own Panel B
values verbatim for the arithmetic cross-check above, are not computed by `run.R`, and
are excluded from the *reproduced*-target tally even though the raw match check reports
95/95, since those 10 are trivially equal to themselves by construction — see the
caveat above for what that does and does not demonstrate. The honest count is
**85 of 85 independently-reproduced targets matched** (54 original + 31 new), plus 10
paper-quoted reference values used only to check Table 7's published arithmetic.

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

**54 / 54 original Table-4 targets matched.** (The 41 new Table-2 / headline targets
from this task's extension are listed in the "Numbers from the paper's text" section
above rather than repeated cell-by-cell here; all of them matched too, per the same
`match()` rule used by `verify_packages.py`.)

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
(the file the site publishes), sources `stata_compat.R`, reproduces Table 4 (both risk
model parts) and Table 2 Panel A (full sample), prints every target's produced value —
including a labelled "PAPER'S HEADLINE CLAIM" block at the end that walks through the
30–40 basis points number — and writes `results.json`.
