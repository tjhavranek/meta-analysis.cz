# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**14 of 20 numbers from the paper are reproduced.**

Counting every number this file lists, the paper prints **32**, of which this package does not produce **6**.

## Not reproduced (6)

| number in the paper | paper | this package |
|---|---|---|
| Headline_ImpliedBeta_Developed_Preferred_BMA | 0.309 | not computed |
| Headline_ImpliedBeta_Developed_FrankelPoonawala_BMA | 0.448 | not computed |
| Headline_ImpliedBeta_Developed_Breedon_BMA | 0.231 | not computed |
| Headline_ImpliedBeta_Emerging_Preferred_BMA | 0.945 | not computed |
| Headline_ImpliedBeta_Emerging_FrankelPoonawala_BMA | 1.164 | not computed |
| Headline_ImpliedBeta_Emerging_Breedon_BMA | 0.947 | not computed |

## Recorded but not scored (12)

Numbers that cannot be a pass or a fail. `discrepancy`: computed correctly and
disagreeing with the printed paper. `approximation`: rebuilt from inputs the paper
printed rounded, so it lands near but cannot land exactly. `not_reproduced`: quoted
from the paper, not computed here. `stochastic`: depends on a random draw.

| number | paper | this package | kind |
|---|---|---|---|
| A3_PanelA_FE_MeanBeyondBias_SE | 0.117 | 0.11386 | stochastic |
| A3_PanelA_FE_PubBias_SE | 0.34 | 0.273147 | stochastic |
| A3_PanelA_WLS_MeanBeyondBias_SE | 0.108 | 0.086327 | stochastic |
| A3_PanelA_WLS_PubBias_SE | 0.262 | 0.22121 | stochastic |
| A3_PanelA_IV_MeanBeyondBias_SE | 0.196 | 0.205043 | stochastic |
| A3_PanelA_IV_PubBias_SE | 0.523 | 0.574269 | stochastic |
| A3_PanelB_FE_MeanBeyondBias_SE | 0.109 | 0.092275 | stochastic |
| A3_PanelB_FE_PubBias_SE | 0.0537 | 0.052615 | stochastic |
| A3_PanelB_WLS_MeanBeyondBias_SE | 0.0883 | 0.107085 | stochastic |
| A3_PanelB_WLS_PubBias_SE | 0.0226 | 0.023666 | stochastic |
| A3_PanelB_IV_MeanBeyondBias_SE | 0.182 | 0.168377 | stochastic |
| A3_PanelB_IV_PubBias_SE | 0.301 | 0.326147 | stochastic |

## Reproduced (14)

| number in the paper | paper | this package |
|---|---|---|
| A3_PanelA_Obs | 2582 | 2582.0 |
| A3_PanelA_FE_MeanBeyondBias | 0.657 | 0.657207 |
| A3_PanelA_FE_PubBias | -2.331 | -2.331476 |
| A3_PanelA_WLS_MeanBeyondBias | 0.639 | 0.638507 |
| A3_PanelA_WLS_PubBias | -2.264 | -2.264133 |
| A3_PanelA_IV_MeanBeyondBias | 0.359 | 0.359223 |
| A3_PanelA_IV_PubBias | -1.258 | -1.258416 |
| A3_PanelB_Obs | 2582 | 2582.0 |
| A3_PanelB_FE_MeanBeyondBias | 0.666 | 0.666179 |
| A3_PanelB_FE_PubBias | -0.39 | -0.389727 |
| A3_PanelB_WLS_MeanBeyondBias | 0.582 | 0.58151 |
| A3_PanelB_WLS_PubBias | -0.219 | -0.218975 |
| A3_PanelB_IV_MeanBeyondBias | 0.275 | 0.275496 |
| A3_PanelB_IV_PubBias | -0.597 | -0.596686 |
