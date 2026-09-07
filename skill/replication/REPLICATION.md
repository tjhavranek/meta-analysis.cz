# Replication: Havranek, Irsova, Laslopova & Zeynalova, "Publication and Attenuation Biases
# in Measuring Skill Substitution" (Review of Economics and Statistics, 2024)

## Table reproduced

**Table 1**, "IV Estimation of the Negative Inverse Elasticity Shows Less Bias and a Larger
Corrected Effect in Magnitude Compared to Both OLS and Natural Experiments." Panels A, B and C
correspond to the OLS-, IV- and natural-experiment method subsamples (`ols_method2==1`,
`iv_method2==1`, `natural_experiment==1`, all further restricted to `inverted_estimate==1`).

Table 1 prints five columns per panel (FE, BE, IV, EK, SM). Only **FE** (`xtreg ..., fe
vce(cluster idstudy)`) and **IV** (`ivreg2 ... (x=instrument), cluster(idstudy)`) are estimated
with commands that have a wrapper in `stata_compat.R`. **BE** (`xtreg ..., be`, between-effects)
has no wrapper at all. **EK** and **SM** are not run from the data with `ivreg2`/`xtreg` in the
visible `.do` file — they are the Bom and Rachinger (2019) endogenous-kink method and the
Andrews and Kasy (2019) selection model, both external procedures with no equivalent command in
`stata_compat.R`. All three (BE, EK, SM) are **unsupported_command** and out of scope; targets
were chosen only from the FE and IV columns.

## Provenance

`author_code`. `skill.do` gives the exact filter conditions, the exact regressed variables
(`tstat_coefficient_w`, `precision_coefficient_w`), the winsorizing cuts (1/99), and the
clustering variable (`idstudy`) for every cell targeted.

## Data reconstruction

The published `skill.csv` mirrors the author's *raw imported* file: it carries `elasticity` and
`se` in whatever unit each row was originally reported in, not the derived `coefficient` /
`se_coefficient` / `tstat_coefficient_w` variables the `.do` file computes with `gen`. `run.R`
reconstructs them exactly as `skill.do` lines 16-46 do:

1. `coefficient = -1/elasticity`, `se_coefficient = se/elasticity^2` (delta method) — every row.
2. Keep `coefficient`/`se_coefficient` only where `inverted_estimate==1` (else missing); rows
   with `elasticity==0` or missing `se` become missing coefficient/se_coefficient, exactly as a
   Stata `gen` off a division by zero or a missing operand would.
3. `winsor2 coefficient se_coefficient, cuts(1 99)` — done **once**, on the full
   `inverted_estimate==1` sample (683 rows), *before* any panel-specific subsetting. This matters:
   winsorizing per panel instead of globally would change the cutoffs.
4. `tstat_coefficient_w = coefficient_w/se_coefficient_w`, `precision_coefficient_w =
   1/se_coefficient_w`.
5. Per panel, `st_keep_if` on `<method>==1 & inverted_estimate==1`.

The raw-row counts recovered this way (363/264/40 for panels A/B/C before dropping missing
`se`/`elasticity==0`, reducing to 347/264/40 for the FE column, and further to 251/212/40 for the
IV column once rows with missing `instrument_sec` are also dropped) match the printed
`Observations` row in every one of the six FE/IV columns exactly — the sample-reconstruction
step is independently confirmed by six count targets, not just inferred from a coefficient match.

## Which cell is "Publication bias" and which is "Effect beyond bias"

The regression is the WLS transform of `coefficient_i = b0 + b1*SE_i + e_i` divided through by
`SE_i`: `tstat_i = b0*precision_i + b1 + e_i/SE_i`. So the **slope** on `precision_coefficient_w`
recovers `b0`, the "Effect beyond bias" row, and the **intercept** recovers `b1`, the coefficient
that would multiply `SE` in the untransformed model — the "Publication bias" row. (An initial
pass had this backwards; the printed magnitudes made the swap obvious — "Publication bias" is
consistently the large, precisely-estimated coefficient of a few units, "Effect beyond bias" is
the small one near zero — and re-checking against the transform above confirmed the assignment
used in the final `run.R`.)

## Target-by-target results

All coefficients, standard errors and observation counts below match to the printed precision.
kind = deterministic unless noted.

| Label | Printed | Produced | Verdict |
|---|---|---|---|
| A_FE_pubbias_coef | -5.804 | -5.80401 | match |
| A_FE_pubbias_se | 1.999 | 1.99921 | match |
| A_FE_effect_coef | -0.0207 | -0.02066 | match |
| A_FE_effect_se | 0.103 | 0.10350 | match |
| A_FE_N (count) | 347 | 347 | match |
| A_IV_pubbias_coef | -6.962 | -6.96169 | match |
| A_IV_pubbias_se | 1.694 | 1.69429 | match |
| A_IV_effect_coef | 0.0103 | 0.01027 | match |
| A_IV_effect_se | 0.104 | 0.10424 | match |
| A_IV_firstF | 46.17 | 46.17 | match |
| A_IV_N (count) | 251 | 251 | match |
| B_FE_pubbias_coef | -2.287 | -2.28724 | match |
| B_FE_pubbias_se | 0.843 | 0.84272 | match |
| B_FE_effect_coef | -0.149 | -0.14943 | match |
| B_FE_effect_se | 0.109 | 0.10879 | match |
| B_FE_N (count) | 264 | 264 | match |
| B_IV_pubbias_coef | -0.553 | -0.55334 | match |
| B_IV_pubbias_se | 0.681 | 0.68146 | match |
| B_IV_effect_coef | -0.400 | -0.39967 | match |
| B_IV_effect_se | 0.114 | 0.11352 | match |
| B_IV_firstF | 69.98 | 69.98 | match |
| B_IV_N (count) | 212 | 212 | match |
| C_FE_pubbias_coef | -3.557 | -3.55734 | match |
| C_FE_pubbias_se | 0.0178 | 0.01777 | match |
| C_FE_effect_coef | 0.0496 | 0.04962 | match |
| C_FE_effect_se | 0.00246 | 0.00246 | match |
| C_FE_N (count) | 40 | 40 | match |
| C_IV_pubbias_coef | -3.176 | -3.17636 | match |
| C_IV_pubbias_se | 0.853 | 0.85321 | match |
| C_IV_effect_coef | -0.00307 | -0.00307 | match |
| C_IV_effect_se | 0.0297 | 0.02971 | match |
| C_IV_firstF | 260.41 | 260.41 | match |
| C_IV_N (count) | 40 | 40 | match |

**33 of 33 targets match.**

## The first-stage F fix

`A_IV_firstF`, `B_IV_firstF` and `C_IV_firstF` initially came out wrong (48.14, 74.45, 320.72
against printed 46.17, 69.98, 260.41 — a different inflation factor in each panel: 1.04, 1.06,
1.23, ruling out a single missing constant). The cause was in how `run.R` was *using*
`st_ivreg2_first_F`, not in the sample, the coefficients, or `stata_compat.R` itself (which was
not touched).

`st_ivreg2_first_F`'s own comment states the intent correctly: ivreg2 reports the first-stage
robust F/Wald under fixest's *default* small-sample-corrected vcov, deliberately different from
the large-sample vcov (`.SSC_LARGE`) the main coefficient table uses. But calling
`fixest::fitstat(m_iv, "ivwald1")` on the full 2SLS object does not actually deliver that: fixest
carries the first-stage regression as a cached sub-model inside the IV fit, and that sub-model was
estimated (and has its vcov cached) under the *outer* call's ssc — `.SSC_LARGE`, since that is what
`st_ivreg2` always passes to `feols`. `fitstat`'s own "ivwald1" branch reuses that cached/flagged
ssc rather than recomputing with fixest's package default, even when the cache is cleared and a
fresh `ssc`/`cluster` argument is supplied to `fitstat()` directly (verified by inspecting
`fixest:::fitstat`'s source and by clearing `m_iv$iv_first_stage[[1]]$cov.scaled` and re-calling
with explicit `ssc = ssc()` — the stat did not move). So `st_ivreg2_first_F(m_iv)` silently returns
the large-sample-ssc Wald stat instead of the default-ssc one its own comment promises, and the gap
grows as the cluster count shrinks (Panel C has only a handful of studies), matching the observed
1.04 / 1.06 / 1.23 pattern (the small-sample correction factor is `((n-1)/(n-K)) * (G/(G-1))`,
which grows fastest when `G` is small).

The fix uses only wrappers already in `stata_compat.R`, unedited: fit the univariate first-stage
regression (`precision_coefficient_w ~ instrument_sec`, clustered on `idstudy`) with `st_regress`
— which *is* documented and verified to carry fixest's default ssc ("Stata's `regress` always
applies the small-sample corrections") — and read its Wald statistic via
`fixest::fitstat(m_first, "wald")`, the same joint-nullity-of-non-intercept-coefficients test
`ivwald1` reports, just computed on a model that actually has the default ssc baked in rather than
inheriting `ivreg2`'s large-sample one. `fitstat()` is a read-only post-estimation accessor (the
same role `st_coefs` plays via `stats::coef`/`stats::vcov`), not one of the forbidden raw estimator
calls (`feols`/`lm`/`rma`/`lmer`/`plm`/`ivreg`/`quantile`), and `stata_compat.R` was not modified.
This reproduces all three printed first-stage F values exactly: 46.175 -> 46.17, 69.982 -> 69.98,
260.411 -> 260.41. See `run.R`'s `run_panel()` for the implementation and inline note.

No other repairs were needed: all 20 coefficient/SE targets and all 6 observation-count targets
across the FE and IV columns matched from the start, confirming the sample, filters and
coefficient/SE conventions were already right — only the auxiliary first-stage F needed the fix
above.

## Unsupported / out of scope

- **BE** column (`xtreg ..., be`, between-effects): no wrapper in `stata_compat.R`.
- **EK** column (Bom and Rachinger 2019 endogenous-kink estimator): not run via `ivreg2`/`xtreg`
  in the visible code; no wrapper.
- **SM** column (Andrews and Kasy 2019 selection model, reported as the estimated relative
  publication probability `P`): not run via any wrapped command; no wrapper.
- The wild-bootstrap and two-step weak-instrument-robust confidence intervals shown in brackets
  next to the IV column (`boottest`, `twostepweakiv`) have no wrapper and are stochastic /
  specialized procedures in any case.

None of these were attempted; they are not counted as misses.

## Verdict

**MATCH.** 33/33 targets match at the printed precision after fixing how `run.R` computes the
IV first-stage F (see above); `stata_compat.R` was not modified.
