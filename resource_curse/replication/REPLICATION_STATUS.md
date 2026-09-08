# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**24 of the 30 numbers this paper prints for these tables are reproduced.**

## Not matching the printed paper (6)

Cells are named as they are in `results.json`. The reason for each follows the table.

| cell | paper | this code |
|---|---|---|
| Panel A: OLS SE (publication selection) coef | -1.016 | -1.016527 |
| Panel A: OLS Constant (true effect) t | 1.69 | 1.605356 |
| Panel A: OLS Constant (true effect) p | 0.099 | 0.108939 |
| Panel A: IV SE (publication selection) coef | -1.234 | -1.234917 |
| Panel A: IV Constant (true effect) coef | 0.038 | 0.038692 |
| Panel B: Mixed Constant (effect beyond bias) z | 1.43 | -1.427388 |

Table 3's note says the standard errors are clustered at the study level. The published Panel A was estimated without clustering: heteroskedasticity-robust standard errors reproduce every printed t-statistic exactly, and the authors' log of the published run carries no cluster option. This package reports both. Clustered by study the coefficients are unchanged and the inference is weaker: the standard-error term gives t = -1.73, p = 0.091 by OLS and t = -1.76 by IV, against printed t of -5.18 and -4.81, and the constant gives t = 0.87, p = 0.388 against a printed 1.69 and 0.099. Both sets are in results.json. The printed values are left exactly as published.

The printed z carries no sign. It must be negative: the coefficient is -0.133, the p-value is 0.153, and every other cell in the table is signed. The authors' log gives -1.43. The printed value is left as published.

## Reproduced (24)

| cell | paper | this code |
|---|---|---|
| Panel A: N (OLS) | 605 | 605 |
| Panel A: N (IV) | 605 | 605 |
| Panel B: N (FE) | 605 | 605 |
| Panel B: N (Mixed) | 605 | 605 |
| Panel B: groups (FE) | 43 | 43 |
| Panel B: groups (Mixed) | 43 | 43 |
| Panel A: OLS SE (publication selection) t | -5.18 | -5.1834 |
| Panel A: OLS SE (publication selection) p | 0 | 0.0 |
| Panel A: OLS Constant (true effect) coef | 0.026 | 0.026083 |
| Panel A: IV SE (publication selection) t | -4.81 | -4.807745 |
| Panel A: IV SE (publication selection) p | 0 | 2e-06 |
| Panel A: IV Constant (true effect) t | 2.41 | 2.412304 |
| Panel A: IV Constant (true effect) p | 0.016 | 0.01615 |
| Panel B: FE SE (publication bias) coef | -0.011 | -0.011368 |
| Panel B: FE SE (publication bias) t | -0.58 | -0.582306 |
| Panel B: FE SE (publication bias) p | 0.563 | 0.563474 |
| Panel B: FE Constant (effect beyond bias) coef | -0.589 | -0.589039 |
| Panel B: FE Constant (effect beyond bias) t | -2.64 | -2.643401 |
| Panel B: FE Constant (effect beyond bias) p | 0.011 | 0.011488 |
| Panel B: Mixed SE (publication bias) coef | 0.09 | 0.090078 |
| Panel B: Mixed SE (publication bias) z | 0.14 | 0.135245 |
| Panel B: Mixed SE (publication bias) p | 0.892 | 0.892418 |
| Panel B: Mixed Constant (effect beyond bias) coef | -0.133 | -0.133343 |
| Panel B: Mixed Constant (effect beyond bias) p | 0.153 | 0.153468 |

