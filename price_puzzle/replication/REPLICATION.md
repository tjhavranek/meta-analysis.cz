# Replication package -- price_puzzle (price puzzle meta-analysis)

**Paper**: "How to Solve the Price Puzzle? A Meta-Analysis", *Journal of Money, Credit and
Banking* 2013, https://doi.org/10.1111/j.1538-4616.2012.00561.x

**Tables/claims reproduced**:

1. Table A1, "Test of Publication Bias and True Effect, OLS" -- the funnel-asymmetry/
   precision-effect (FAT-PET) meta-regression of the approximated t-statistic on precision
   (1/SE), OLS with standard errors clustered at the study level, one column per
   impulse-response horizon (3, 6, 12, 18, 36 months): 5 horizons x 7 numbers (intercept
   coefficient and SE, slope coefficient and SE, R2, observations, studies) = 35 targets.
2. The paper's own **headline text claim** (Section 4 / CONCLUSION): "After controlling for
   both publication and misspecification biases, the price puzzle is not present and prices
   bottom out 6 months ... The maximum decrease in the price level reaches 0.33%." This is
   Table 5's "Best practice" row, built from the same specification as Table 4. See "Numbers
   from the paper's text" below for the full derivation, provenance, and an explicit,
   disclosed limitation on the estimator used.
3. Context for (2): the paper's other quoted number, Table 2's publication-bias-only
   correction ("only 0.02%," still exhibiting the puzzle) -- same section below.

**Provenance for (1)**: author's own Stata do-file (`puzzle.do`), line 7
(`use "puzzle.dta", clear`), lines 13-14 (`replace res=100*res` / `replace se=100*se`), and
lines 35-39 (`eststo: reg t prec if horizon==3/6/12/18/36, vce(cluster idstudy)`), matched
against the printed numbers in Table A1.

## A note on the do-file

The version of `puzzle.do` excerpted into this package's original brief was truncated past
line ~90, which is why an earlier draft of this file said Table 2/Table 4's mixed-effects
specifications and covariate lists could not be read with confidence. The site holds the FULL
do-file (`price_puzzle/puzzle.do`, 428 lines), which does contain the exact `xtmixed` commands,
full covariate lists, and the literal "best-practice" `lincom` constants used for the headline
claim reproduced below -- so that limitation no longer applies to the headline-claim numbers.
Table A2's *general* model (line 155, `reg t prec gdppc_se growth_se ... `, ~30 covariates) and
Tables 2/4's own full coefficient tables remain out of scope, as before, simply because
verifying every one of their individual cells was not what this extension was asked to do.

## Data

`data/v1/price_puzzle/price_puzzle.csv` (1,519 rows, 152 columns) is the published mirror of
the author's wide file. It is **not** already in the long, one-row-per-horizon shape the
do-file's `if horizon==h` filters expect from `puzzle.dta`; instead every estimate (identified
by `idstudy`/`idest`) appears as 7 duplicate rows, one for each value of a `horizon` indicator
(3, 6, 12, 18, 36, 88, 99 -- the last two evidently code "bottom" and "peak"), with the actual
horizon-specific response and SE living in fixed-name columns that do **not** vary across an
estimate's 7 duplicate rows: `M3R`/`SE3`, `M6R`/`SE6`, `M12R`/`SE12`, `M18R`/`SE18`,
`M36R`/`SE36` (confirmed by inspecting all 7 rows for `idstudy==1, idest==1`: these columns
are identical across the duplicate). Selecting the row's own-horizon `M{h}R`/`SE{h}` pair and
restricting to `horizon==h` therefore reconstructs exactly the generic `res`/`se` variables
`puzzle.do` operates on, and reproduces the paper's own N and study counts per horizon
(verified below) -- this is the reading used throughout `run.R`.

## Construction (`puzzle.do` lines 7, 13-14, 35-39)

For each horizon h in {3, 6, 12, 18, 36}:

1. Keep the rows of the published CSV with `horizon == h` (`st_keep_if`).
2. `res <- M{h}R * 100`, `se <- SE{h} * 100` (do-file lines 13-14: `replace res=100*res` /
   `replace se=100*se`, i.e. percentage-point units).
3. Drop rows with missing `res`/`se` at this horizon -- the same rows Stata's `if horizon==h`
   filter silently excludes from `reg`. This reproduces the paper's printed N and study count
   exactly for every horizon (208/69, 215/70, 215/70, 217/70, 205/63) and is the check that the
   `M{h}R`/`SE{h}` reading of the data is the right one.
4. `t <- res / se` (the "approximated t-statistic" the paper's own notes describe as the
   response variable), `prec <- 1 / se`.
5. `eststo: reg t prec if horizon==h, vce(cluster idstudy)` -> `st_regress(t ~ prec, cluster =
   ~idstudy)`.

No estimator, clustering, weighting, or degrees-of-freedom convention was changed from what
the do-file specifies; `st_regress`'s documented convention (fixest's own default small-sample
correction) is exactly Stata `regress`'s.

## Target-by-target results

All 35 targets are deterministic (no bootstrap/simulation anywhere in this table) and all
matched at the printed precision.

| Label | Printed | Produced | Verdict |
|---|---|---|---|
| H3: Intercept (bias) coef | -0.277 | -0.27749 | MATCH |
| H3: Intercept (bias) se | 0.176 | 0.17648 | MATCH |
| H3: 1/SE (effect) coef | 0.032 | 0.03173 | MATCH |
| H3: 1/SE (effect) se | 0.014 | 0.01440 | MATCH |
| H3: R2 | 0.05 | 0.0477 | MATCH |
| H3: Observations | 208 | 208 | MATCH |
| H3: Studies | 69 | 69 | MATCH |
| H6: Intercept (bias) coef | -0.407 | -0.40713 | MATCH |
| H6: Intercept (bias) se | 0.186 | 0.18573 | MATCH |
| H6: 1/SE (effect) coef | 0.033 | 0.03337 | MATCH |
| H6: 1/SE (effect) se | 0.021 | 0.02065 | MATCH |
| H6: R2 | 0.03 | 0.0277 | MATCH |
| H6: Observations | 215 | 215 | MATCH |
| H6: Studies | 70 | 70 | MATCH |
| H12: Intercept (bias) coef | -0.341 | -0.34130 | MATCH |
| H12: Intercept (bias) se | 0.156 | 0.15623 | MATCH |
| H12: 1/SE (effect) coef | -0.007 | -0.00704 | MATCH |
| H12: 1/SE (effect) se | 0.016 | 0.01567 | MATCH |
| H12: R2 | 0.00 | 0.0009 | MATCH |
| H12: Observations | 215 | 215 | MATCH |
| H12: Studies | 70 | 70 | MATCH |
| H18: Intercept (bias) coef | -0.393 | -0.39336 | MATCH |
| H18: Intercept (bias) se | 0.147 | 0.14661 | MATCH |
| H18: 1/SE (effect) coef | -0.025 | -0.02490 | MATCH |
| H18: 1/SE (effect) se | 0.014 | 0.01390 | MATCH |
| H18: R2 | 0.02 | 0.0161 | MATCH |
| H18: Observations | 217 | 217 | MATCH |
| H18: Studies | 70 | 70 | MATCH |
| H36: Intercept (bias) coef | -0.784 | -0.78384 | MATCH |
| H36: Intercept (bias) se | 0.122 | 0.12198 | MATCH |
| H36: 1/SE (effect) coef | -0.018 | -0.01780 | MATCH |
| H36: 1/SE (effect) se | 0.008 | 0.00755 | MATCH |
| H36: R2 | 0.01 | 0.0150 | MATCH |
| H36: Observations | 205 | 205 | MATCH |
| H36: Studies | 63 | 63 | MATCH |

**35 / 35 deterministic targets matched. No misses, no repairs needed.**

## What is not attempted, and why

- **Table A2** ("Explaining the Differences in Reported Impulse Responses, OLS"): the do-file
  lines behind the *general* model (155-192) are truncated mid-command in the brief excerpt
  originally available to this package. The full do-file (recovered below, see "Numbers from
  the paper's text") shows the complete "general model" line, but it is a 30-covariate
  specification not needed for the headline claim and is left out here rather than added
  speculatively.
- Tables 2 and 4's own printed CELLS (as opposed to the "Best practice" predictions built
  *from* the same specifications, reproduced below) are not separately targeted: doing so
  would need every one of their ~20 coefficient/SE pairs individually verified, which the task
  at hand did not ask for. The specification underlying them is verified below via the "Best
  practice" prediction it feeds into Table 5, and via Table 2's own "1/SE (effect)" coefficient
  (see next section).

## Numbers from the paper's text (not just its results tables)

meta-analysis.cz summarises this paper as: *"the price puzzle disappears once publication and
misspecification biases are corrected, and prices fall instead, bottoming out 0.33% below."*
That sentence paraphrases the paper's own CONCLUSION (and Section 4):

> "After controlling for both publication and misspecification biases, the price puzzle is not
> present and prices bottom out 6 months after a 1 percentage point increase in the interest
> rate. The maximum decrease in the price level reaches 0.33% and is statistically significant
> at the 5% level." (repeated in the CONCLUSION: "... reaches 0.33% and occurs half a year
> after the tightening.")

The number behind it is **Table 5's "Best practice" row**: -0.157, -0.331\*\*, -0.225\*, -0.155,
-0.116 at horizons 3/6/12/18/36 months -- a "synthetic study" prediction from the same
meta-regression as Table 4 ("Specific model": t on prec and 21 methodology moderators, each
entered as x/se, mixed-effects with a study-level random intercept), evaluated at fixed
"best-practice" moderator values and se = 1.

**Provenance**: `price_puzzle/puzzle.do`, the FULL author do-file the site holds (fuller than
the excerpt in this package's original brief), lines 236-248 ("Best Practice" block):

```stata
quietly xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se
  avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se
  ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se
  if horizon==h || idstudy:
lincom prec + 2.668301*growth_se + 7.748488*inf_se + 6.233974*vol_se +
  .8368237*findev_se + .4598406*open_se + .7735787*indep_se + 6.298949*lnobs_se +
  4*avgyear_se + 0*gdpdeflator_se + 1*single_se + 1*com_se + 1*foreign_se +
  4.875197*lnend_variab_se + 0*ea_ip_se + 1*ea_gap_se + 0*ea_oth_se + 1*bvar_se +
  0*favar_se + 1*svar_se + 0*sign_se + .4510718*cb_se + .054986*policy_se
```
repeated once per horizon, with the *same* literal constants each time (the do-file's own
best-practice target values: sample means for the country/policy moderators, sample maxima for
"No. of observations"/"Average year"/"No. of variables", 0/1 for preferred methodology). The
`lincom` deliberately has no separate intercept term -- reproduced exactly as written, not
"corrected" to add one back in (and doing so empirically would break the match, not fix it).

Two variables in that right-hand side have no same-named column in the published CSV and had to
be traced to their raw source: `bvar_se` (labelled "BVAR" in the do-file but built, per the
paper's own best-practice text "we prefer Bayesian estimation," from `meth_bay`, the Bayesian
estimation-method dummy) and `svar_se`/`sign_se` (the CSV's identification dummies are
`ir_chol`/`ir_svar`/`ir_gen`/`ir_sign`/`ir_oth`; "nonrecursive identification" in the
best-practice text is `ir_svar`, recursive/Cholesky is the omitted base category).

**Estimator**: `xtmixed ... || idstudy:` with no `mle` option is Stata's default for that
command, which is **REML**. `stata_compat.R`'s `st_mixed()` wrapper always fits **ML**
(`lme4::lmer(REML = FALSE)`) -- its own documented convention for `mixed`/`xtmixed`, fixed in a
file this package may not edit. This is a real, disclosed limitation, not a rounding footnote:
for this specification the two estimators do not always land on the same printed digit.

| Horizon | Paper (Table 5, Best practice) | Produced (st_mixed, ML) | Verdict |
|---|---|---|---|
| 3 months  | -0.157  | -0.157 | MATCH |
| 6 months  | -0.331 \*\* | -0.331 | **MATCH -- this is the "0.33% below" headline number** |
| 12 months | -0.225 \*  | -0.228 | off by 0.003 (ML vs. Stata's default REML) |
| 18 months | -0.155  | -0.157 | off by 0.002 |
| 36 months | -0.116  | -0.114 | off by 0.002 |

All five signs match and all five are negative -- the paper's qualitative claim, "the price
puzzle is not present," reproduces exactly (`run.R` checks this explicitly: no horizon shows a
positive/puzzling response). Delta-method p-values on the produced numbers (0.32, 0.017, 0.036,
0.12, 0.50) also reproduce the paper's own star pattern at 6 months (p < .05, matching \*\*) and
are directionally consistent at 12 months (p = .036, paper's single \* suggests 10% rather than
5%, again attributable to ML vs. REML). **The specific "0.33%" claimed in the paper's text is
reproduced to the printed precision; the other four cells of the same row are close but not
exact, for the one documented, non-editable reason above.**

For contrast, the paper's OTHER quoted number -- publication-bias correction alone, without the
methodology moderators -- comes from Table 2 (`xtmixed t prec if horizon==h || idstudy:`, no
covariates), Section 3:

> "The impulse response function corrected for publication bias is depicted in Figure 4: it
> exhibits the price puzzle. In the short run prices increase, but in the medium run they
> decrease and bottom out 18 months after the tightening. The maximum decrease in the price
> level, however, is negligible: only 0.02%."

Table 2's "1/SE (effect)" coefficient at 18 months (the same st_mixed/ML estimator) produces
-0.0185%, which rounds to the paper's "0.02%" -- included in `run.R`'s output and in
`targets.json` as a headline target, kept clearly separate from the main Table 5 claim so the
two are never conflated. (Table 2 on its own still exhibits the puzzle -- the 3/6-month
responses are positive -- which is exactly the contrast the paper's text draws: publication
bias alone is not enough to remove it, both biases together are.)

## How to run

```
Rscript run.R       # writes results.json, prints every produced number
Rscript compare.R   # prints the target-by-target table above
```

## Verdict

**CONCORDANT** for Table A1 and for the paper's headline text claim (Table 5's "Best practice"
row, specifically the 6-month "0.33%" the site's summary quotes, which matches to the printed
digit) and for the qualitative "price puzzle disappears" claim (all five horizons negative).
**PARTIALLY CONCORDANT** for the other four cells of the same Table 5 row (within 0.002-0.003,
attributable to a disclosed, non-editable ML-vs-REML difference in the shared `st_mixed`
wrapper) and for Table 2's "0.02%" context number (matches at the printed precision).
Table A2's general model and Tables 2/4's own individual coefficient cells are out of scope, for
the reasons given above.
