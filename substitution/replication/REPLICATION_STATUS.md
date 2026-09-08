# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**75 of the 88 numbers this paper prints for these tables are reproduced.**

## Not produced by this code (13)

| number in the paper | paper | this code |
|---|---|---|
| HL_stockpartic_10pp_effect_ols | 0.24 | not computed |
| HL_assetholders_core_ols | 0.21 | not computed |
| HL_assetholders_all_ols | 0.35 | not computed |
| HL_econsig_max_stockpartic_ols | 0.931 | not computed |
| HL_econsig_sd_stockpartic_ols | 0.141 | not computed |
| HL_econsig_max_gdppc_ols | 0.683 | not computed |
| HL_econsig_sd_gdppc_ols | 0.088 | not computed |
| HL_econsig_max_eascredit_ols | -0.119 | not computed |
| HL_econsig_sd_eascredit_ols | -0.02 | not computed |
| HL_econsig_max_realrate_ols | -0.265 | not computed |
| HL_econsig_sd_realrate_ols | -0.019 | not computed |
| HL_econsig_max_ruleoflaw_ols | -0.087 | not computed |
| HL_econsig_sd_ruleoflaw_ols | -0.012 | not computed |

This number is not produced here. The paper's figure is a Bayesian model averaging posterior mean, and no wrapper in stata_compat.R fits BMA, so it is quoted rather than computed. The number shown beside it is the OLS/frequentist-check coefficient on the same variable in the same table, a different estimator, reported for orientation only. Scoring it against the BMA figure would record a failure of the code where the truth is that the quantity was never computed. paper value is a BMA posterior mean (2.4) x 0.10; produced value is the OLS/frequentist-check counterpart (Table 2 marketpartic coef x 0.10), not the same estimator, see REPLICATION_STATUS.md

This number is not produced here. The paper's figure is a Bayesian model averaging posterior mean, and no wrapper in stata_compat.R fits BMA, so it is quoted rather than computed. The number shown beside it is the OLS/frequentist-check coefficient on the same variable in the same table, a different estimator, reported for orientation only. Scoring it against the BMA figure would record a failure of the code where the truth is that the quantity was never computed. paper value is the BMA posterior mean for Asset holders, core-countries specification (Table 2); produced value is the OLS/frequentist-check coefficient on the same variable in the same table

This number is not produced here. The paper's figure is a Bayesian model averaging posterior mean, and no wrapper in stata_compat.R fits BMA, so it is quoted rather than computed. The number shown beside it is the OLS/frequentist-check coefficient on the same variable in the same table, a different estimator, reported for orientation only. Scoring it against the BMA figure would record a failure of the code where the truth is that the quantity was never computed. paper value is the BMA posterior mean for Asset holders, all-countries specification (Table 1); produced value is the OLS/frequentist-check coefficient on the same variable in the same table

This number is not produced here. The paper's figure is a Bayesian model averaging posterior mean, and no wrapper in stata_compat.R fits BMA, so it is quoted rather than computed. The number shown beside it is the OLS/frequentist-check coefficient on the same variable in the same table, a different estimator, reported for orientation only. Scoring it against the BMA figure would record a failure of the code where the truth is that the quantity was never computed. Table 3 economic-significance figure, BMA-based; produced value uses the OLS coefficient in place of the BMA posterior mean, same sample

This number is not produced here. The paper's figure is a Bayesian model averaging posterior mean, and no wrapper in stata_compat.R fits BMA, so it is quoted rather than computed. The number shown beside it is the OLS/frequentist-check coefficient on the same variable in the same table, a different estimator, reported for orientation only. Scoring it against the BMA figure would record a failure of the code where the truth is that the quantity was never computed.

## Reproduced (75)

| number in the paper | paper | this code |
|---|---|---|
| T7_marketpartic_coef | 2.342 | 2.341689 |
| T7_marketpartic_se | 0.848 | 0.847503 |
| T7_marketpartic_p | 0.011 | 0.010587 |
| T7_gdppc_coef | 0.198 | 0.197567 |
| T7_gdppc_se | 0.114 | 0.113853 |
| T7_gdppc_p | 0.095 | 0.095003 |
| T7_finref_coef | -0.777 | -0.776813 |
| T7_finref_se | 0.394 | 0.393551 |
| T7_finref_p | 0.06 | 0.059546 |
| T7_realrate_coef | 0.023 | 0.022502 |
| T7_realrate_se | 0.032 | 0.032361 |
| T7_realrate_p | 0.493 | 0.493262 |
| T7_trust_coef | -0.005 | -0.005119 |
| T7_trust_se | 0.004 | 0.004409 |
| T7_trust_p | 0.257 | 0.256582 |
| T7_inverse_coef | 0.627 | 0.626863 |
| T7_inverse_se | 0.103 | 0.10322 |
| T7_inverse_p | 0 | 2e-06 |
| T7_top_coef | 0.602 | 0.602469 |
| T7_top_se | 0.114 | 0.113626 |
| T7_top_p | 0 | 1.7e-05 |
| T7_totalc_coef | 0.416 | 0.415893 |
| T7_totalc_se | 0.147 | 0.146861 |
| T7_totalc_p | 0.009 | 0.009008 |
| T7_lnyears_coef | -0.228 | -0.228447 |
| T7_lnyears_se | 0.058 | 0.05771 |
| T7_lnyears_p | 0.001 | 0.000551 |
| T7_ols_coef | 0.443 | 0.44297 |
| T7_ols_se | 0.189 | 0.189337 |
| T7_ols_p | 0.028 | 0.027593 |
| T7_irstock_coef | -0.299 | -0.299028 |
| T7_irstock_se | 0.136 | 0.135668 |
| T7_irstock_p | 0.037 | 0.036945 |
| T7_stockhold_coef | 0.406 | 0.406155 |
| T7_stockhold_se | 0.13 | 0.130194 |
| T7_stockhold_p | 0.005 | 0.004522 |
| T7_lnyearcits_coef | -0.093 | -0.092724 |
| T7_lnyearcits_se | 0.057 | 0.057441 |
| T7_lnyearcits_p | 0.119 | 0.119023 |
| T7_ircap_coef | -0.265 | -0.265191 |
| T7_ircap_se | 0.061 | 0.060594 |
| T7_ircap_p | 0 | 0.000188 |
| T7_sepdur_coef | 0.465 | 0.465375 |
| T7_sepdur_se | 0.273 | 0.273265 |
| T7_sepdur_p | 0.101 | 0.100968 |
| T7_constant_coef | -0.797 | -0.797209 |
| T7_constant_se | 1.093 | 1.093068 |
| T7_constant_p | 0.473 | 0.472577 |
| T7_N | 2254 | 2254 |
| T1_gdppc_coef | 0.126 | 0.12619 |
| T1_gdppc_se | 0.084 | 0.084205 |
| T1_gdppc_p | 0.138 | 0.137722 |
| T1_eascredit_coef | -0.033 | -0.032651 |
| T1_eascredit_se | 0.055 | 0.05478 |
| T1_eascredit_p | 0.553 | 0.552753 |
| T1_realrate_coef | -0.003 | -0.002652 |
| T1_realrate_se | 0.006 | 0.005566 |
| T1_realrate_p | 0.635 | 0.635011 |
| T1_ruleoflaw_coef | -0.019 | -0.018737 |
| T1_ruleoflaw_se | 0.074 | 0.073869 |
| T1_ruleoflaw_p | 0.8 | 0.800381 |
| T1_stockhold_coef | 0.421 | 0.421348 |
| T1_stockhold_se | 0.089 | 0.088613 |
| T1_stockhold_p | 0 | 8e-06 |
| T1_N | 2526 | 2526 |
| T2_marketpartic_coef | 2.221 | 2.220515 |
| T2_marketpartic_se | 0.542 | 0.542172 |
| T2_marketpartic_p | 0 | 0.000387 |
| T2_gdppc_coef | 0.116 | 0.116437 |
| T2_gdppc_se | 0.138 | 0.137576 |
| T2_gdppc_p | 0.405 | 0.405388 |
| T2_stockhold_coef | 0.372 | 0.371568 |
| T2_stockhold_se | 0.143 | 0.142919 |
| T2_stockhold_p | 0.015 | 0.01543 |
| T2_N | 2254 | 2254 |

