# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**35 of 39 numbers from the paper are reproduced.**

Counting every number this file lists, the paper prints **40**, of which this package does not produce **5**.

## Not reproduced (4)

| number in the paper | paper | this package |
|---|---|---|
| T5 Translog: SE coef | 0.664 | not computed |
| T5 Translog: Constant coef | 0.529 | not computed |
| TEXT mean elasticity, simple (paper: 0.8) | 0.8 | 0.747053 |
| TEXT share of 0.9->0.3 reduction due to publication bias alone (paper: 'at least half', i.e. >= 0.5) | 0.5 | 0.680206 |

## Recorded but not scored (1)

Numbers that cannot be a pass or a fail. `discrepancy`: computed correctly and
disagreeing with the printed paper. `approximation`: rebuilt from inputs the paper
printed rounded, so it lands near but cannot land exactly. `not_reproduced`: quoted
from the paper, not computed here. `stochastic`: depends on a random draw.

| number | paper | this package | kind |
|---|---|---|---|
| TEXT 'best practice' implied elasticity -- OUR st_regress proxy (paper's Table 9 value: 0.30, 95% CI -0.01 to 0.60; NOT independently reproduced -- see comment above) | 0.3 | 0.433293 | headline_not_independently_reproduced |

## Reproduced (35)

| number in the paper | paper | this package |
|---|---|---|
| T5 Identif: SE coef | 0.649 | 0.649102 |
| T5 Identif: SE se | 0.219 | 0.218781 |
| T5 Identif: Constant coef | 0.512 | 0.512427 |
| T5 Identif: Constant se | 0.0357 | 0.035718 |
| T5 Identif: SE*Identif coef | -0.0323 | -0.032346 |
| T5 Identif: SE*Identif se | 0.332 | 0.332017 |
| T5 Data aggr: SE coef | 0.803 | 0.803261 |
| T5 Data aggr: SE se | 0.318 | 0.318004 |
| T5 Data aggr: Constant coef | 0.553 | 0.552973 |
| T5 Data aggr: Constant se | 0.042 | 0.042018 |
| T5 Data aggr: SE*Dataaggr coef | -0.299 | -0.299006 |
| T5 Data aggr: SE*Dataaggr se | 0.334 | 0.333974 |
| T5 Results aggr: SE coef | 0.624 | 0.624405 |
| T5 Results aggr: SE se | 0.146 | 0.145939 |
| T5 Results aggr: Constant coef | 0.569 | 0.569362 |
| T5 Results aggr: Constant se | 0.0449 | 0.044878 |
| T5 Results aggr: SE*Resultsaggr coef | 0.0616 | 0.061558 |
| T5 Results aggr: SE*Resultsaggr se | 0.249 | 0.249142 |
| T5 K perpetual: SE coef | 0.754 | 0.754315 |
| T5 K perpetual: SE se | 0.259 | 0.259364 |
| T5 K perpetual: Constant coef | 0.551 | 0.550855 |
| T5 K perpetual: Constant se | 0.0337 | 0.033671 |
| T5 K perpetual: SE*Kperpet coef | -0.334 | -0.33355 |
| T5 K perpetual: SE*Kperpet se | 0.289 | 0.288768 |
| T5 Short run: SE coef | 0.473 | 0.472779 |
| T5 Short run: SE se | 0.0903 | 0.090292 |
| T5 Short run: Constant coef | 0.587 | 0.586511 |
| T5 Short run: Constant se | 0.0155 | 0.015453 |
| T5 Short run: SE*Shortrun coef | 1.741 | 1.740647 |
| T5 Short run: SE*Shortrun se | 0.885 | 0.885405 |
| T5 Studies (all columns) | 121 | 121.0 |
| T5 Observations (all columns) | 3186 | 3186.0 |
| TEXT mean elasticity, equal weight per study (paper: 0.9) | 0.9 | 0.867015 |
| TEXT publication-bias coefficient, Table 1 OLS (paper: 0.881) | 0.881 | 0.881304 |
| TEXT mean elasticity corrected for publication bias, Table 1 OLS constant (paper: 0.5, printed 0.492) | 0.492 | 0.491876 |
