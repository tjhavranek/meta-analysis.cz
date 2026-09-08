# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**47 of 54 numbers from the paper are reproduced.**

Counting every number this file lists, the paper prints **78**, of which this package does not produce **7**.

## Not reproduced (7)

| number in the paper | paper | this package |
|---|---|---|
| C_WLS_prec_coef | 1.859 | 1.853297 |
| C_WLS_cons_coef | 2.39 | 2.390683 |
| C_FE_prec_coef | 3.476 | 3.471143 |
| C_BE_prec_coef | 0.817 | 0.804429 |
| C_BE_prec_se | 3.061 | 3.059787 |
| C_BE_cons_coef | 3.223 | 3.223592 |
| C_BE_cons_se | 0.423 | 0.422384 |

## Recorded but not scored (24)

Numbers that cannot be a pass or a fail. `discrepancy`: computed correctly and
disagreeing with the printed paper. `approximation`: rebuilt from inputs the paper
printed rounded, so it lands near but cannot land exactly. `not_reproduced`: quoted
from the paper, not computed here. `stochastic`: depends on a random draw.

| number | paper | this package | kind |
|---|---|---|---|
| A_WLS_prec_ci_lo | 0.956 | - | stochastic |
| A_WLS_prec_ci_hi | 2.577 | - | stochastic |
| A_WLS_cons_ci_lo | 0.725 | - | stochastic |
| A_WLS_cons_ci_hi | 2.13 | - | stochastic |
| A_Study_prec_ci_lo | 1.251 | - | stochastic |
| A_Study_prec_ci_hi | 4.9 | - | stochastic |
| A_Study_cons_ci_lo | 0.673 | - | stochastic |
| A_Study_cons_ci_hi | 2.476 | - | stochastic |
| B_WLS_prec_ci_lo | 0.383 | - | stochastic |
| B_WLS_prec_ci_hi | 2.506 | - | stochastic |
| B_WLS_cons_ci_lo | 0.654 | - | stochastic |
| B_WLS_cons_ci_hi | 2.059 | - | stochastic |
| B_Study_prec_ci_lo | 2.007 | - | stochastic |
| B_Study_prec_ci_hi | 5.293 | - | stochastic |
| B_Study_cons_ci_lo | 0.351 | - | stochastic |
| B_Study_cons_ci_hi | 1.464 | - | stochastic |
| C_WLS_prec_ci_lo | 0.05 | - | stochastic |
| C_WLS_prec_ci_hi | 2.895 | - | stochastic |
| C_WLS_cons_ci_lo | 0.812 | - | stochastic |
| C_WLS_cons_ci_hi | 4.006 | - | stochastic |
| C_Study_prec_ci_lo | -1.197 | - | stochastic |
| C_Study_prec_ci_hi | 5.548 | - | stochastic |
| C_Study_cons_ci_lo | 1.062 | - | stochastic |
| C_Study_cons_ci_hi | 4.89 | - | stochastic |

## Reproduced (47)

| number in the paper | paper | this package |
|---|---|---|
| A_WLS_prec_coef | 1.865 | 1.865201 |
| A_WLS_prec_se | 0.362 | 0.362367 |
| A_WLS_cons_coef | 1.199 | 1.198759 |
| A_WLS_cons_se | 0.257 | 0.256803 |
| A_FE_prec_coef | 2.287 | 2.286764 |
| A_FE_prec_se | 0.713 | 0.712763 |
| A_FE_cons_coef | 1.084 | 1.083819 |
| A_FE_cons_se | 0.194 | 0.194336 |
| A_BE_prec_coef | 2.837 | 2.837186 |
| A_BE_prec_se | 1.76 | 1.760214 |
| A_BE_cons_coef | 1.59 | 1.590088 |
| A_BE_cons_se | 0.235 | 0.234654 |
| A_Study_prec_coef | 3.062 | 3.061965 |
| A_Study_prec_se | 0.893 | 0.892801 |
| A_Study_cons_coef | 1.533 | 1.532541 |
| A_Study_cons_se | 0.412 | 0.411624 |
| A_obs | 1021 | 1021.0 |
| A_studies | 92 | 92.0 |
| B_WLS_prec_coef | 1.392 | 1.392145 |
| B_WLS_prec_se | 0.54 | 0.539942 |
| B_WLS_cons_coef | 1.085 | 1.085251 |
| B_WLS_cons_se | 0.261 | 0.261305 |
| B_FE_prec_coef | 1.411 | 1.410921 |
| B_FE_prec_se | 1.146 | 1.145759 |
| B_FE_cons_coef | 1.082 | 1.081791 |
| B_FE_cons_se | 0.211 | 0.211159 |
| B_BE_prec_coef | 4.119 | 4.118888 |
| B_BE_prec_se | 1.361 | 1.360639 |
| B_BE_cons_coef | 0.714 | 0.7142 |
| B_BE_cons_se | 0.178 | 0.177905 |
| B_Study_prec_coef | 3.604 | 3.603604 |
| B_Study_prec_se | 0.827 | 0.8268 |
| B_Study_cons_coef | 0.822 | 0.822396 |
| B_Study_cons_se | 0.243 | 0.242564 |
| B_obs | 590 | 590.0 |
| B_studies | 58 | 58.0 |
| C_WLS_prec_se | 0.449 | 0.449054 |
| C_WLS_cons_se | 0.675 | 0.674694 |
| C_FE_prec_se | 0.169 | 0.168622 |
| C_FE_cons_coef | 1.107 | 1.10733 |
| C_FE_cons_se | 0.134 | 0.133759 |
| C_Study_prec_coef | 2.168 | 2.167978 |
| C_Study_prec_se | 1.654 | 1.653952 |
| C_Study_cons_coef | 2.888 | 2.887926 |
| C_Study_cons_se | 0.732 | 0.732317 |
| C_obs | 431 | 431.0 |
| C_studies | 34 | 34.0 |
