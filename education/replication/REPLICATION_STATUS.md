# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**40 of 40 numbers from the paper are reproduced.**

Counting every number this file lists, the paper prints **42**, of which this package does not produce **0**.

## Recorded but not scored (2)

Numbers that cannot be a pass or a fail. `discrepancy`: computed correctly and
disagreeing with the printed paper. `approximation`: rebuilt from inputs the paper
printed rounded, so it lands near but cannot land exactly. `not_reproduced`: quoted
from the paper, not computed here. `stochastic`: depends on a random draw.

| number | paper | this package | kind |
|---|---|---|---|
| T6 long-run FMA mean | -0.07 | -0.069406 | discrepancy |
| T6 female BMA CI low | -0.12 | -0.120548 | discrepancy |

**T6 long-run FMA mean** -- This package computes -0.069406, which rounds to -0.069; the paper prints -0.070. The paper's own interval for the SAME row, (-0.089, -0.050), is reproduced here exactly, and it sits 0.019 below and 0.020 above the printed mean, so it is not symmetric about -0.070. It IS symmetric about roughly -0.0694. The printed mean and the printed interval cannot both come from one underlying number, and this package agrees with the interval. Recorded as a discrepancy for the author; the printed value is left exactly as published.

**T6 female BMA CI low** -- This package computes -0.120548, which rounds to -0.121; the paper prints -0.120. The paper's own mean for that row (-0.017) and upper bound (0.087) give a half-width of 0.104 and hence a lower bound of -0.121, so the printed -0.120 disagrees with the rest of its own row. The gap is 5e-5, entirely in the fourth decimal of the BMA posterior mean. Checked rather than assumed: reading the author's own saved bms object out of education_nobs.RData also scores 20 of 21 on the BMA half, it fixes this cell and breaks 'short-run BMA CI low' instead. No BMA configuration, his or ours, reaches 21 of 21, so the residual is rounding in the printed table, not the estimator.

## Reproduced (40)

| number in the paper | paper | this package |
|---|---|---|
| T6 short-run BMA mean | -0.01 | -0.009761 |
| T6 short-run BMA CI low | -0.032 | -0.031538 |
| T6 short-run BMA CI high | 0.012 | 0.012016 |
| T6 short-run FMA mean | 0.069 | 0.068694 |
| T6 short-run FMA CI low | 0.047 | 0.046917 |
| T6 short-run FMA CI high | 0.09 | 0.09047 |
| T6 long-run BMA mean | -0.062 | -0.061713 |
| T6 long-run BMA CI low | -0.081 | -0.081061 |
| T6 long-run BMA CI high | -0.042 | -0.042365 |
| T6 long-run FMA CI low | -0.089 | -0.088754 |
| T6 long-run FMA CI high | -0.05 | -0.050059 |
| T6 private BMA mean | -0.167 | -0.166901 |
| T6 private BMA CI low | -0.19 | -0.190183 |
| T6 private BMA CI high | -0.144 | -0.143618 |
| T6 private FMA mean | -0.141 | -0.140633 |
| T6 private FMA CI low | -0.164 | -0.163916 |
| T6 private FMA CI high | -0.117 | -0.11735 |
| T6 public BMA mean | 0.003 | 0.003283 |
| T6 public BMA CI low | -0.033 | -0.032665 |
| T6 public BMA CI high | 0.039 | 0.03923 |
| T6 public FMA mean | 0.043 | 0.043267 |
| T6 public FMA CI low | 0.007 | 0.00732 |
| T6 public FMA CI high | 0.079 | 0.079215 |
| T6 male BMA mean | -0.361 | -0.360821 |
| T6 male BMA CI low | -0.529 | -0.529413 |
| T6 male BMA CI high | -0.192 | -0.192228 |
| T6 male FMA mean | -0.348 | -0.348251 |
| T6 male FMA CI low | -0.517 | -0.516844 |
| T6 male FMA CI high | -0.18 | -0.179659 |
| T6 female BMA mean | -0.017 | -0.016739 |
| T6 female BMA CI high | 0.087 | 0.087071 |
| T6 female FMA mean | -0.112 | -0.111951 |
| T6 female FMA CI low | -0.216 | -0.21576 |
| T6 female FMA CI high | -0.008 | -0.008142 |
| T6 all-estimates BMA mean | -0.037 | -0.036776 |
| T6 all-estimates BMA CI low | -0.055 | -0.0546 |
| T6 all-estimates BMA CI high | -0.019 | -0.018952 |
| T6 all-estimates FMA mean | -0.003 | -0.003118 |
| T6 all-estimates FMA CI low | -0.021 | -0.020943 |
| T6 all-estimates FMA CI high | 0.015 | 0.014706 |
