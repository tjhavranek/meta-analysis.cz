# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**22 of the 23 numbers this paper prints for these tables are reproduced.**

## Not matching the printed paper (1)

Cells are named as they are in `results.json`. The reason for each follows the table.

| cell | paper | this code |
|---|---|---|
| BMA best-practice global estimate (%), own reconstruction | -0.014 | -0.019053 |

rebuilt from Table 5's BMA posterior means, which the paper prints to three decimals; the 14 rounded coefficients leave a near-constant offset of about +0.005 across all 21 countries. Re-running the authors' BMS chain is not possible with the wrappers in stata_compat.R, so this is an approximation, not a reproduction, and is not scored as either.

## Reproduced (22)

| cell | paper | this code |
|---|---|---|
| OLS SE coef | -0.41 | -0.410004 |
| OLS SE se | 0.265 | 0.264681 |
| OLS const coef | -0.293 | -0.293442 |
| OLS const se | 0.000778 | 0.000778 |
| OLS N | 101 | 101 |
| FE SE coef | -1.217 | -1.21688 |
| FE SE se | 0.79 | 0.790254 |
| FE const coef | -0.222 | -0.221972 |
| FE const se | 0.07 | 0.069998 |
| FE N | 101 | 101 |
| ME SE coef | -0.449 | -0.44906 |
| ME SE se | 0.688 | 0.688257 |
| ME const coef | -0.291 | -0.291006 |
| ME const se | 0.00731 | 0.007313 |
| ME N | 101 | 101 |
| Simple avg ESTIMATE, all obs (%) | -0.334 | -0.334454 |
| T2 all obs, study-weighted mean (the abstract's 0.34%) | -0.343 | -0.342743 |
| T2 all obs, study-weighted CI low | -0.429 | -0.428941 |
| T2 all obs, study-weighted CI high | -0.257 | -0.256545 |
| T2 all obs, unweighted CI low | -0.419 | -0.419321 |
| T2 all obs, unweighted CI high | -0.25 | -0.249587 |
| Median estimate (Section 3, Figure 4 text) | -0.3 | -0.3 |

