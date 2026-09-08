# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**38 of the 39 numbers this paper prints for these tables are reproduced.**

## Not matching the printed paper (1)

The reason for each follows the table.

| number in the paper | paper | this code |
|---|---|---|
| STAR preferred estimates with \|t\| above Lang's 5.48 threshold (paper: one) | 1 | 2 |

The conclusion says that one of the twenty preferred STAR estimates exceeds the 5.48 t-statistic threshold of Lang (2025). The count of twenty is exact. Two exceed the threshold, at |t| = 5.538 and 5.500, both within 1 percent of it, so a t recomputed from rounded published effects and standard errors would move one across. The printed value is left as published.

## Reproduced (38)

| number in the paper | paper | this code |
|---|---|---|
| Base N after drop if effect_true==0 | 2434 | 2434 |
| OLS: Publication bias (coef) | 0.0331 | 0.033136 |
| OLS: Publication bias (se) | 0.0944 | 0.094438 |
| OLS: Effect beyond bias / constant (coef) | -0.297 | -0.296615 |
| OLS: Effect beyond bias / constant (se) | 0.114 | 0.113548 |
| FE: Publication bias (coef) | 0.00613 | 0.006134 |
| FE: Publication bias (se) | 0.0795 | 0.079542 |
| FE: Effect beyond bias / constant (coef) | -0.262 | -0.262424 |
| FE: Effect beyond bias / constant (se) | 0.101 | 0.100721 |
| IV: Publication bias (coef) | 0.0644 | 0.064437 |
| IV: Publication bias (se) | 0.15 | 0.150147 |
| IV: Effect beyond bias / constant (coef) | -0.345 | -0.344886 |
| IV: Effect beyond bias / constant (se) | 0.0929 | 0.092856 |
| IV: First-stage robust F-stat | 22.5 | 22.493972 |
| Study: Publication bias (coef) | -0.0733 | -0.073318 |
| Study: Publication bias (se) | 0.21 | 0.209503 |
| Study: Effect beyond bias / constant (coef) | -0.625 | -0.62503 |
| Study: Effect beyond bias / constant (se) | 0.212 | 0.212345 |
| Precision: Publication bias (coef) | -0.0575 | -0.057548 |
| Precision: Publication bias (se) | 0.14 | 0.140115 |
| Precision: Effect beyond bias / constant (coef) | -0.182 | -0.181785 |
| Precision: Effect beyond bias / constant (se) | 0.0577 | 0.057701 |
| Headline B4 [STAR experiment]: Effect beyond bias (coef) | -2.407 | -2.407316 |
| Headline B4 [STAR experiment]: Effect beyond bias (se) | 0.479 | 0.478827 |
| Headline B4 [STAR experiment]: N | 56 | 56 |
| Headline B4 [Regression discontinuity]: Effect beyond bias (coef) | -0.716 | -0.715716 |
| Headline B4 [Regression discontinuity]: Effect beyond bias (se) | 0.134 | 0.134426 |
| Headline B4 [Regression discontinuity]: N | 436 | 436 |
| Headline B4 [Instrumental variable]: Effect beyond bias (coef) | -0.272 | -0.271587 |
| Headline B4 [Instrumental variable]: Effect beyond bias (se) | 0.227 | 0.227292 |
| Headline B4 [Instrumental variable]: N | 845 | 845 |
| Headline B4 [Fixed effects]: Effect beyond bias (coef) | -0.18 | -0.179582 |
| Headline B4 [Fixed effects]: Effect beyond bias (se) | 0.114 | 0.113948 |
| Headline B4 [Fixed effects]: N | 669 | 669 |
| Headline B4 [OLS]: Effect beyond bias (coef) | 0.228 | 0.228383 |
| Headline B4 [OLS]: Effect beyond bias (se) | 0.153 | 0.153127 |
| Headline B4 [OLS]: N | 433 | 433 |
| STAR preferred estimates in the sample (paper: twenty) | 20 | 20 |

