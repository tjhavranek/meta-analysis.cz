# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**29 of the 31 numbers this paper prints for these tables are reproduced.**

## Not matching the printed paper (2)

Cells are named as they are in `results.json`. The reason for each follows the table.

| cell | paper | this code |
|---|---|---|
| T3 col5 MAIVE: First-stage F | 31.2 | 38.235431 |
| T3 col5 MAIVE: Studies | 23 | 33 |

The MAIVE column's coefficients, standard errors and 603 observations all reproduce. Two cells do not. Running the authors' own line in Stata 15.1 on their own saved data gives a cluster-robust first-stage F of 37.02 (Kleibergen-Paap rk Wald F 37.015, Cragg-Donald 46.53) against a printed 31.2, and the regression has 33 clusters, which is the number ivreg2 reports, against a printed 23. Neither figure follows from the estimation as the do-file specifies it. The printed values are left exactly as published.

## Reproduced (29)

| cell | paper | this code |
|---|---|---|
| T3 col1 OLS: Publication bias coef | 1.689 | 1.688932 |
| T3 col1 OLS: Publication bias SE | 0.264 | 0.264293 |
| T3 col1 OLS: Effect-beyond-bias coef | 0.288 | 0.287948 |
| T3 col1 OLS: Effect-beyond-bias SE | 0.0442 | 0.04422 |
| T3 col1 OLS: Observations | 762 | 762 |
| T3 col1 OLS: Studies | 38 | 38 |
| T3 col2 FE: Publication bias coef | 0.887 | 0.88652 |
| T3 col2 FE: Publication bias SE | 0.271 | 0.271197 |
| T3 col2 FE: Effect-beyond-bias coef | 0.356 | 0.356381 |
| T3 col2 FE: Effect-beyond-bias SE | 0.0252 | 0.025243 |
| T3 col2 FE: Observations | 762 | 762 |
| T3 col2 FE: Studies | 38 | 38 |
| T3 col3 Precision: Publication bias coef | 2.592 | 2.591705 |
| T3 col3 Precision: Publication bias SE | 0.53 | 0.530059 |
| T3 col3 Precision: Effect-beyond-bias coef | 0.211 | 0.210956 |
| T3 col3 Precision: Effect-beyond-bias SE | 0.0441 | 0.044144 |
| T3 col3 Precision: Observations | 762 | 762 |
| T3 col3 Precision: Studies | 38 | 38 |
| T3 col4 Study: Publication bias coef | 2.173 | 2.173124 |
| T3 col4 Study: Publication bias SE | 0.227 | 0.226899 |
| T3 col4 Study: Effect-beyond-bias coef | 0.243 | 0.243257 |
| T3 col4 Study: Effect-beyond-bias SE | 0.047 | 0.047043 |
| T3 col4 Study: Observations | 762 | 762 |
| T3 col4 Study: Studies | 38 | 38 |
| T3 col5 MAIVE: Publication bias coef | 3.056 | 3.056334 |
| T3 col5 MAIVE: Publication bias SE | 1.5 | 1.500197 |
| T3 col5 MAIVE: Effect-beyond-bias coef | 0.35 | 0.349877 |
| T3 col5 MAIVE: Effect-beyond-bias SE | 0.0463 | 0.046283 |
| T3 col5 MAIVE: Observations | 603 | 603 |

