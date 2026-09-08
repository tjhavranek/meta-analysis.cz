# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**24 of 24 numbers from the paper are reproduced.**

Counting every number this file lists, the paper prints **30**, of which this package does not produce **0**.

## Recorded but not scored (6)

Numbers that cannot be a pass or a fail. `discrepancy`: computed correctly and
disagreeing with the printed paper. `approximation`: rebuilt from inputs the paper
printed rounded, so it lands near but cannot land exactly. `not_reproduced`: quoted
from the paper, not computed here. `stochastic`: depends on a random draw.

| number | paper | this package | kind |
|---|---|---|---|
| Panel A: OLS SE (publication selection) coef | -1.016 | -1.016527 | discrepancy |
| Panel A: OLS Constant (true effect) t | 1.69 | 1.605356 | discrepancy |
| Panel A: OLS Constant (true effect) p | 0.099 | 0.108939 | discrepancy |
| Panel A: IV SE (publication selection) coef | -1.234 | -1.234917 | discrepancy |
| Panel A: IV Constant (true effect) coef | 0.038 | 0.038692 | discrepancy |
| Panel B: Mixed Constant (effect beyond bias) z | 1.43 | -1.427388 | discrepancy |

**Panel A: OLS SE (publication selection) coef** -- The authors' own log of the published run (Study/Papers/25_Resource_curse/REVISION/latex/natural_resource.log, 1 June 2016) gives -1.016527 at line 202, 'PCC_SE | -1.016527  .196112  -5.18  0.000' -- which is what this package computes. The paper prints -1.016. The log's own formatted table (line 306) reads 'PCC_SE  -1.017***  -1.235***', i.e. the author's output rounds the way this package does and not the way the printed table does. All five Panel A cells that miss show this pattern, and the same pattern appears in risk's Panel C and in spillovers' sample sizes: the printed tables were built from a run that differs slightly from the archived one. Recorded for the author; the printed value is untouched.

**Panel A: OLS Constant (true effect) t** -- The authors' own log of the published run (Study/Papers/25_Resource_curse/REVISION/latex/natural_resource.log, 1 June 2016) gives 1.61 at line 203, '_cons | .0260833  .0162477  1.61  0.109' -- which is what this package computes. The paper prints 1.69. The log's own formatted table (line 306) reads 'PCC_SE  -1.017***  -1.235***', i.e. the author's output rounds the way this package does and not the way the printed table does. All five Panel A cells that miss show this pattern, and the same pattern appears in risk's Panel C and in spillovers' sample sizes: the printed tables were built from a run that differs slightly from the archived one. Recorded for the author; the printed value is untouched.

**Panel A: OLS Constant (true effect) p** -- The authors' own log of the published run (Study/Papers/25_Resource_curse/REVISION/latex/natural_resource.log, 1 June 2016) gives 0.109 at line 203, the same row's p-value -- which is what this package computes. The paper prints 0.099. The log's own formatted table (line 306) reads 'PCC_SE  -1.017***  -1.235***', i.e. the author's output rounds the way this package does and not the way the printed table does. All five Panel A cells that miss show this pattern, and the same pattern appears in risk's Panel C and in spillovers' sample sizes: the printed tables were built from a run that differs slightly from the archived one. Recorded for the author; the printed value is untouched.

**Panel A: IV SE (publication selection) coef** -- The authors' own log of the published run (Study/Papers/25_Resource_curse/REVISION/latex/natural_resource.log, 1 June 2016) gives -1.234917 at line 220, 'PCC_SE | -1.234917  .25686  -4.81  0.000' -- which is what this package computes. The paper prints -1.234. The log's own formatted table (line 306) reads 'PCC_SE  -1.017***  -1.235***', i.e. the author's output rounds the way this package does and not the way the printed table does. All five Panel A cells that miss show this pattern, and the same pattern appears in risk's Panel C and in spillovers' sample sizes: the printed tables were built from a run that differs slightly from the archived one. Recorded for the author; the printed value is untouched.

**Panel A: IV Constant (true effect) coef** -- The authors' own log of the published run (Study/Papers/25_Resource_curse/REVISION/latex/natural_resource.log, 1 June 2016) gives 0.0386915 at line 221, '_cons | .0386915  .0160392  2.41  0.016' -- which is what this package computes. The paper prints 0.038. The log's own formatted table (line 306) reads 'PCC_SE  -1.017***  -1.235***', i.e. the author's output rounds the way this package does and not the way the printed table does. All five Panel A cells that miss show this pattern, and the same pattern appears in risk's Panel C and in spillovers' sample sizes: the printed tables were built from a run that differs slightly from the archived one. Recorded for the author; the printed value is untouched.

**Panel B: Mixed Constant (effect beyond bias) z** -- The paper's Panel B prints this z as '1.43', unsigned. It must be NEGATIVE: the same row's coefficient is -0.133 and its p-value is 0.153, and z = -1.43 is the only value consistent with both. Every other cell in the table carries its sign (-0.58, -2.64, 0.14), so this reads as a dropped minus in typesetting rather than a different quantity. This package computes -1.427388, which agrees with the paper on magnitude to the printed digits. Recorded as a discrepancy for the author, not scored as a defect: the printed value is left exactly as published.

## Reproduced (24)

| number in the paper | paper | this package |
|---|---|---|
| Panel A: N (OLS) | 605 | 605.0 |
| Panel A: N (IV) | 605 | 605.0 |
| Panel B: N (FE) | 605 | 605.0 |
| Panel B: N (Mixed) | 605 | 605.0 |
| Panel B: groups (FE) | 43 | 43.0 |
| Panel B: groups (Mixed) | 43 | 43.0 |
| Panel A: OLS SE (publication selection) t | -5.18 | -5.1834 |
| Panel A: OLS SE (publication selection) p | 0.0 | 0.0 |
| Panel A: OLS Constant (true effect) coef | 0.026 | 0.026083 |
| Panel A: IV SE (publication selection) t | -4.81 | -4.807745 |
| Panel A: IV SE (publication selection) p | 0.0 | 2e-06 |
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
