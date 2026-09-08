# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**58 of 60 numbers from the paper are reproduced.**

## Not reproduced (2)

| number in the paper | paper | this package |
|---|---|---|
| HL_lower_corrected_mean_raw | 0 | -18.685314 |
| HL_studylevel_ratio | 4 | 4.748807 |

## Recorded but not scored (10)

Numbers that cannot be a pass or a fail. `discrepancy`: computed correctly and
disagreeing with the printed paper. `approximation`: rebuilt from inputs the paper
printed rounded, so it lands near but cannot land exactly. `not_reproduced`: quoted
from the paper, not computed here. `stochastic`: depends on a random draw.

| number | paper | this package | kind |
|---|---|---|---|
| T3A_ME_se_coef | 1.819 | 1.819393 | stochastic |
| T3A_ME_se_se | 0.0825 | 0.082516 | stochastic |
| T3A_ME_const | -18.69 | -18.685314 | stochastic |
| T3A_ME_const_se | 48.43 | 48.434829 | stochastic |
| T3B_ME_se_coef | 1.835 | 1.834541 | stochastic |
| T3B_ME_se_se | 0.0843 | 0.084288 | stochastic |
| T3B_ME_upse_coef | -0.00788 | -0.007879 | stochastic |
| T3B_ME_upse_se | 0.01 | 0.01 | stochastic |
| T3B_ME_const | -17.78 | -17.784719 | stochastic |
| T3B_ME_const_se | 48.81 | 48.811386 | stochastic |

**T3A_ME_se_coef** -- ML mixed-effects (study random intercept); exact numerical optimum, not a resampling statistic, but 'ME' spec details (REML vs ML, which random effects) are inferred, not shown verbatim in the excerpted code

**T3B_ME_se_coef** -- ML mixed-effects (study random intercept); ME spec details inferred, not verbatim in the excerpted code

## Reproduced (58)

| number in the paper | paper | this package |
|---|---|---|
| T3A_OLS_se_coef | 1.705 | 1.705099 |
| T3A_OLS_se_se | 0.63 | 0.630295 |
| T3A_OLS_const | 134.1 | 134.068554 |
| T3A_OLS_const_se | 58.16 | 58.15668 |
| T3A_OLS_N | 267 | 267.0 |
| T3A_FE_se_coef | 1.889 | 1.888967 |
| T3A_FE_se_se | 0.762 | 0.762462 |
| T3A_FE_const | 104.2 | 104.199261 |
| T3A_FE_const_se | 123.9 | 123.861356 |
| T3A_FE_N | 267 | 267.0 |
| T3A_StdErrW_se_coef | 2.467 | 2.467188 |
| T3A_StdErrW_se_se | 0.48 | 0.479768 |
| T3A_StdErrW_const | 10.27 | 10.267829 |
| T3A_StdErrW_const_se | 7.361 | 7.360953 |
| T3A_StdErrW_N | 267 | 267.0 |
| T3A_StudyW_se_coef | 1.213 | 1.213117 |
| T3A_StudyW_se_se | 0.527 | 0.527021 |
| T3A_StudyW_const | 63.14 | 63.139288 |
| T3A_StudyW_const_se | 40.12 | 40.120459 |
| T3A_StudyW_N | 267 | 267.0 |
| T3A_ME_N | 267 | 267.0 |
| T3B_OLS_se_coef | 1.662 | 1.6618 |
| T3B_OLS_se_se | 0.663 | 0.663046 |
| T3B_OLS_upse_coef | 0.0246 | 0.024589 |
| T3B_OLS_upse_se | 0.0254 | 0.025368 |
| T3B_OLS_const | 112.0 | 112.026423 |
| T3B_OLS_const_se | 50.0 | 49.998642 |
| T3B_OLS_N | 267 | 267.0 |
| T3B_FE_se_coef | 1.907 | 1.907011 |
| T3B_FE_se_se | 0.779 | 0.778844 |
| T3B_FE_upse_coef | -0.0109 | -0.010879 |
| T3B_FE_upse_se | 0.00676 | 0.006763 |
| T3B_FE_const | 114.1 | 114.132405 |
| T3B_FE_const_se | 118.6 | 118.550004 |
| T3B_FE_N | 267 | 267.0 |
| T3B_StdErrW_se_coef | 2.451 | 2.450976 |
| T3B_StdErrW_se_se | 0.538 | 0.537918 |
| T3B_StdErrW_upse_coef | 0.00283 | 0.00283 |
| T3B_StdErrW_upse_se | 0.0107 | 0.010664 |
| T3B_StdErrW_const | 9.555 | 9.554683 |
| T3B_StdErrW_const_se | 6.133 | 6.132708 |
| T3B_StdErrW_N | 267 | 267.0 |
| T3B_StudyW_se_coef | 0.78 | 0.780279 |
| T3B_StudyW_se_se | 0.548 | 0.547526 |
| T3B_StudyW_upse_coef | 0.222 | 0.222232 |
| T3B_StudyW_upse_se | 0.143 | 0.142865 |
| T3B_StudyW_const | 45.29 | 45.292462 |
| T3B_StudyW_const_se | 29.63 | 29.625582 |
| T3B_StudyW_N | 267 | 267.0 |
| T3B_ME_N | 267 | 267.0 |
| HL_upper_corrected_mean_134 | 134 | 134.068554 |
| HL_lower_corrected_mean_floor0 | 0 | 0.0 |
| HL_uncorrected_mean_d1_411 | 411 | 411.060508 |
| HL_exaggeration_factor | 3 | 3.066047 |
| HL_studylevel_largest_corrected_mean_61 | 61 | 61.068832 |
| HL_overall_mean_d0_290 | 290 | 290.004099 |
| HL_usd_per_tCO2_2014prices_paper_rounded | 39 | 39.06812 |
| HL_usd_per_tCO2_2014prices_from_exact_estimate | 39 | 39.088107 |
