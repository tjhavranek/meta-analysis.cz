# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**43 of 44 numbers from the paper are reproduced.**

Counting every number this file lists, the paper prints **64**, of which this package does not produce **1**.

## Not reproduced (1)

| number in the paper | paper | this package |
|---|---|---|
| T2 FE RMSE | 0.11 | 0.104077 |

## Recorded but not scored (20)

Numbers that cannot be a pass or a fail. `discrepancy`: computed correctly and
disagreeing with the printed paper. `approximation`: rebuilt from inputs the paper
printed rounded, so it lands near but cannot land exactly. `not_reproduced`: quoted
from the paper, not computed here. `stochastic`: depends on a random draw.

| number | paper | this package | kind |
|---|---|---|---|
| T1 OLS bias_se_boot | 0.589 | 0.48906 | stochastic |
| T1 OLS const_se_boot | 0.0316 | 0.027353 | stochastic |
| T1 FE bias_se_boot | 1.708 | 1.89279 | stochastic |
| T1 FE const_se_boot | 0.0954 | 0.101829 | stochastic |
| T1 Study bias_se_boot | 0.441 | 0.441275 | stochastic |
| T1 Study const_se_boot | 0.0245 | 0.024508 | stochastic |
| T1 Precision bias_se_boot | 0.38 | 0.380104 | stochastic |
| T1 Precision const_se_boot | 0.0197 | 0.01973 | stochastic |
| T1 IV bias_se_boot | 0.405 | 0.404592 | stochastic |
| T1 IV const_se_boot | 0.0228 | 0.02284 | stochastic |
| T2 OLS bias_se_boot | 0.549 | 0.533719 | stochastic |
| T2 OLS const_se_boot | 0.0299 | 0.028856 | stochastic |
| T2 FE bias_se_boot | 1.906 | 1.770611 | stochastic |
| T2 FE const_se_boot | 0.106 | 0.095757 | stochastic |
| T2 Study bias_se_boot | 0.562 | 0.561781 | stochastic |
| T2 Study const_se_boot | 0.0297 | 0.029735 | stochastic |
| T2 Precision bias_se_boot | 0.406 | 0.405842 | stochastic |
| T2 Precision const_se_boot | 0.0205 | 0.020491 | stochastic |
| T2 IV bias_se_boot | 0.401 | 0.401218 | stochastic |
| T2 IV const_se_boot | 0.0212 | 0.021152 | stochastic |

## Reproduced (43)

| number in the paper | paper | this package |
|---|---|---|
| T1 OLS bias_coef | -2.354 | -2.354433 |
| T1 OLS const | 0.0261 | 0.02613 |
| T1 OLS R2 | 0.29 | 0.286247 |
| T1 OLS RMSE | 0.13 | 0.132277 |
| T1 FE bias_coef | -2.392 | -2.392357 |
| T1 FE const | 0.0288 | 0.028791 |
| T1 FE R2 | 0.29 | 0.286247 |
| T1 FE RMSE | 0.12 | 0.11753 |
| T1 Study bias_coef | -2.773 | -2.772799 |
| T1 Study const | 0.0428 | 0.042773 |
| T1 Study R2 | 0.4 | 0.397172 |
| T1 Study RMSE | 0.12 | 0.118584 |
| T1 Precision bias_coef | -2.321 | -2.321487 |
| T1 Precision const | 0.0238 | 0.023819 |
| T1 Precision R2 | 0.3 | 0.298983 |
| T1 Precision RMSE | 0.1 | 0.100374 |
| T1 IV bias_coef | -2.081 | -2.080753 |
| T1 IV const | 0.00693 | 0.006929 |
| T1 IV R2 | 0.28 | 0.282379 |
| T1 IV RMSE | 0.13 | 0.131879 |
| T1 N | 176 | 176.0 |
| T1 studies | 9 | 9.0 |
| T2 OLS bias_coef | -2.705 | -2.705349 |
| T2 OLS const | 0.049 | 0.049023 |
| T2 OLS R2 | 0.41 | 0.408174 |
| T2 OLS RMSE | 0.11 | 0.105213 |
| T2 FE bias_coef | -2.438 | -2.438078 |
| T2 FE const | 0.0321 | 0.032141 |
| T2 FE R2 | 0.41 | 0.408174 |
| T2 Study bias_coef | -2.517 | -2.517021 |
| T2 Study const | 0.0334 | 0.033381 |
| T2 Study R2 | 0.37 | 0.37185 |
| T2 Study RMSE | 0.11 | 0.106435 |
| T2 Precision bias_coef | -2.455 | -2.45509 |
| T2 Precision const | 0.0332 | 0.033216 |
| T2 Precision R2 | 0.34 | 0.336203 |
| T2 Precision RMSE | 0.08 | 0.083987 |
| T2 IV bias_coef | -2.4 | -2.400247 |
| T2 IV const | 0.0298 | 0.029752 |
| T2 IV R2 | 0.4 | 0.402982 |
| T2 IV RMSE | 0.1 | 0.104947 |
| T2 N | 146 | 146.0 |
| T2 studies | 4 | 4.0 |
