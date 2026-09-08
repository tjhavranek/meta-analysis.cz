# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**33 of 33 numbers from the paper are reproduced.**

## Recorded but not scored (3)

Numbers that cannot be a pass or a fail. `discrepancy`: computed correctly and
disagreeing with the printed paper. `approximation`: rebuilt from inputs the paper
printed rounded, so it lands near but cannot land exactly. `not_reproduced`: quoted
from the paper, not computed here. `stochastic`: depends on a random draw.

| number | paper | this package | kind |
|---|---|---|---|
| PanelA_Pub_N | 370 | 378.0 | discrepancy |
| PanelB_Pub_N | 241 | 249.0 | discrepancy |
| PanelC_Pub_N | 305 | 321.0 | discrepancy |

**PanelA_Pub_N** -- The paper prints N = 370 for this published-only column; this package computes 378. The authors' OWN LOG of the published run (Study/Papers/3_Vertical_Spillovers/Stata/vertical.log, 13 Jun 2010) contains 378 -- as 'Mixed-effects REML regression, Number of obs = 378, Group variable: idstudy, Number of groups = 26' -- and contains no regression anywhere with N = 370. So this package reproduces what the authors' code actually produced, and the printed figure differs from it. All three published-only columns show the same pattern (paper 370/241/305, log and this package 378/249/321), which points to the table being built from an earlier run rather than to an error here. The coefficients and standard errors of these same columns reproduce. Recorded for the author; the printed value is left exactly as published.

**PanelB_Pub_N** -- The paper prints N = 241 for this published-only column; this package computes 249. The authors' OWN LOG of the published run (Study/Papers/3_Vertical_Spillovers/Stata/vertical.log, 13 Jun 2010) contains 249 -- as 'Mixed-effects REML regression, Number of obs = 249, Group variable: idstudy, Number of groups = 19' -- and contains no regression anywhere with N = 241. So this package reproduces what the authors' code actually produced, and the printed figure differs from it. All three published-only columns show the same pattern (paper 370/241/305, log and this package 378/249/321), which points to the table being built from an earlier run rather than to an error here. The coefficients and standard errors of these same columns reproduce. Recorded for the author; the printed value is left exactly as published.

**PanelC_Pub_N** -- The paper prints N = 305 for this published-only column; this package computes 321. The authors' OWN LOG of the published run (Study/Papers/3_Vertical_Spillovers/Stata/vertical.log, 13 Jun 2010) contains 321 -- as 'Mixed-effects REML regression, Number of obs = 321, Group variable: idstudy, Number of groups = 27' -- and contains no regression anywhere with N = 305. So this package reproduces what the authors' code actually produced, and the printed figure differs from it. All three published-only columns show the same pattern (paper 370/241/305, log and this package 378/249/321), which points to the table being built from an earlier run rather than to an error here. The coefficients and standard errors of these same columns reproduce. Recorded for the author; the printed value is left exactly as published.

## Reproduced (33)

| number in the paper | paper | this package |
|---|---|---|
| PanelA_All_Constant_coef | -0.0255 | -0.025467 |
| PanelA_All_Constant_se | 0.496 | 0.495974 |
| PanelA_All_Precision_coef | 0.168 | 0.167984 |
| PanelA_All_Precision_se | 0.0241 | 0.024121 |
| PanelA_All_N | 1311 | 1311.0 |
| PanelA_All_Studies | 55 | 55.0 |
| PanelA_Pub_Constant_coef | 1.083 | 1.083344 |
| PanelA_Pub_Constant_se | 0.656 | 0.656104 |
| PanelA_Pub_Precision_coef | 0.178 | 0.178111 |
| PanelA_Pub_Precision_se | 0.0295 | 0.02948 |
| PanelA_Pub_Studies | 26 | 26.0 |
| PanelB_All_Constant_coef | 0.729 | 0.729031 |
| PanelB_All_Constant_se | 0.776 | 0.776052 |
| PanelB_All_Precision_coef | 0.0872 | 0.087234 |
| PanelB_All_Precision_se | 0.0287 | 0.028661 |
| PanelB_All_N | 1030 | 1030.0 |
| PanelB_All_Studies | 44 | 44.0 |
| PanelB_Pub_Constant_coef | -0.437 | -0.437278 |
| PanelB_Pub_Constant_se | 1.033 | 1.033228 |
| PanelB_Pub_Precision_coef | 0.258 | 0.257727 |
| PanelB_Pub_Precision_se | 0.0454 | 0.045415 |
| PanelB_Pub_Studies | 19 | 19.0 |
| PanelC_All_Constant_coef | 0.363 | 0.363313 |
| PanelC_All_Constant_se | 0.295 | 0.294726 |
| PanelC_All_Precision_coef | 0.00466 | 0.004657 |
| PanelC_All_Precision_se | 0.00722 | 0.007224 |
| PanelC_All_N | 1154 | 1154.0 |
| PanelC_All_Studies | 52 | 52.0 |
| PanelC_Pub_Constant_coef | 0.512 | 0.512065 |
| PanelC_Pub_Constant_se | 0.498 | 0.498352 |
| PanelC_Pub_Precision_coef | 0.0137 | 0.013681 |
| PanelC_Pub_Precision_se | 0.00837 | 0.008365 |
| PanelC_Pub_Studies | 27 | 27.0 |
