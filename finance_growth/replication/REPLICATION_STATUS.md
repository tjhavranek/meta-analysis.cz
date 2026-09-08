# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**14 of the 16 numbers this paper prints for these tables are reproduced.**

## Not matching the printed paper (2)

Cells are named as they are in `results.json`. The reason for each follows the table.

| cell | paper | this code |
|---|---|---|
| T1 fixed-effect CI lower | 0.088 | 0.088807 |
| T2 Constant SE | 0.422 | 0.42258 |

## Reproduced (14)

| cell | paper | this code |
|---|---|---|
| T1 simple (arithmetic) mean pcc | 0.15 | 0.148398 |
| T1 simple mean CI lower | 0.1 | 0.097237 |
| T1 simple mean CI upper | 0.2 | 0.199559 |
| T1 fixed-effect (inverse-variance) mean | 0.09 | 0.091904 |
| T1 fixed-effect CI upper | 0.095 | 0.095 |
| T1 random-effects mean | 0.14 | 0.139612 |
| T1 random-effects CI lower | 0.129 | 0.12886 |
| T1 random-effects CI upper | 0.15 | 0.150332 |
| T2 Effect (coef on 1/SE) | 0.199 | 0.198852 |
| T2 Effect SE | 0.018 | 0.017578 |
| T2 Constant (bias) | -0.353 | -0.353306 |
| T2 Within-study correlation | 0.46 | 0.460048 |
| T2 Observations | 1334 | 1334 |
| T2 Studies | 67 | 67 |

