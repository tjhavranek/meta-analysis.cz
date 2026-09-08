# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**33 of 33 numbers from the paper are reproduced.**

Counting every number this file lists, the paper prints **39**, of which this package does not produce **6**.

## Recorded but not scored (6)

Numbers that cannot be a pass or a fail. `discrepancy`: computed correctly and
disagreeing with the printed paper. `approximation`: rebuilt from inputs the paper
printed rounded, so it lands near but cannot land exactly. `not_reproduced`: quoted
from the paper, not computed here. `stochastic`: depends on a random draw.

| number | paper | this package | kind |
|---|---|---|---|
| HEADLINE_ivmethod_FE_implied_elasticity | 4 | 6.692244 | not_reproduced |
| HEADLINE_ivmethod_IV_implied_elasticity | 4 | 2.502045 | not_reproduced |
| HEADLINE_developing_FE_implied_elasticity | 2.5 | 2.86581 | not_reproduced |
| HEADLINE_developing_IV_implied_elasticity | 2.5 | 2.18678 | not_reproduced |
| HEADLINE_developed_FE_implied_elasticity | 4 | -51.427116 | not_reproduced |
| HEADLINE_developed_IV_implied_elasticity | 4 | -14.843814 | not_reproduced |

**HEADLINE_ivmethod_FE_implied_elasticity** -- NOT PRODUCED BY THIS PACKAGE. The paper's '4' and '2.5' are rounded verbal summaries of Bayesian model averaging results (Table 5's 3.7, 95% CI 2 to 20), which the sanctioned wrappers cannot fit. The numbers shown are the FE and IV implied elasticities on the same subsample, which bracket the paper's figure but are a different estimator. Abstract/Sec.I: 'the elasticity of substitution around 4' (Panel B, IV-method primary studies). FE and IV are the only two of Table 1's five estimators with a stata_compat.R wrapper; their implied elasticities (-1/effect_coef) bracket the stated 4 from above.

**HEADLINE_ivmethod_IV_implied_elasticity** -- NOT PRODUCED BY THIS PACKAGE. The paper's '4' and '2.5' are rounded verbal summaries of Bayesian model averaging results (Table 5's 3.7, 95% CI 2 to 20), which the sanctioned wrappers cannot fit. The numbers shown are the FE and IV implied elasticities on the same subsample, which bracket the paper's figure but are a different estimator. Same claim as above; brackets 4 from below. The paper's precise '4' (and Table 5's 3.7, 95% CI 2-20) is a Bayesian-model-averaging combination over 24 moderators with no stata_compat.R wrapper, not independently reproducible; these two bracketing numbers are the closest evidence obtainable from the allowed toolkit.

**HEADLINE_developing_FE_implied_elasticity** -- NOT PRODUCED BY THIS PACKAGE. The paper's '4' and '2.5' are rounded verbal summaries of Bayesian model averaging results (Table 5's 3.7, 95% CI 2 to 20), which the sanctioned wrappers cannot fit. The numbers shown are the FE and IV implied elasticities on the same subsample, which bracket the paper's figure but are a different estimator. Sec.III: 'developing countries (around 2.5)' (online appendix table C3-C5, developing_country==1 & inverted_estimate==1 subsample). Matches closely: 2.87.

**HEADLINE_developing_IV_implied_elasticity** -- NOT PRODUCED BY THIS PACKAGE. The paper's '4' and '2.5' are rounded verbal summaries of Bayesian model averaging results (Table 5's 3.7, 95% CI 2 to 20), which the sanctioned wrappers cannot fit. The numbers shown are the FE and IV implied elasticities on the same subsample, which bracket the paper's figure but are a different estimator. Same claim; IV column gives 2.19, also close to the stated 'around 2.5'.

**HEADLINE_developed_FE_implied_elasticity** -- NOT PRODUCED BY THIS PACKAGE. The paper's '4' and '2.5' are rounded verbal summaries of Bayesian model averaging results (Table 5's 3.7, 95% CI 2 to 20), which the sanctioned wrappers cannot fit. The numbers shown are the FE and IV implied elasticities on the same subsample, which bracket the paper's figure but are a different estimator. Sec.III: 'developed countries (above 4)'. The FE corrected inverse elasticity for this subsample is statistically indistinguishable from zero (t=0.22), so -1/coefficient is large in magnitude but its sign is not meaningful, reported as an honest miss on the point value, though a near-zero corrected inverse elasticity is qualitatively consistent with 'a large elasticity'.

**HEADLINE_developed_IV_implied_elasticity** -- NOT PRODUCED BY THIS PACKAGE. The paper's '4' and '2.5' are rounded verbal summaries of Bayesian model averaging results (Table 5's 3.7, 95% CI 2 to 20), which the sanctioned wrappers cannot fit. The numbers shown are the FE and IV implied elasticities on the same subsample, which bracket the paper's figure but are a different estimator. Same claim, IV column; also not statistically distinguishable from zero (t=1.00) and first-stage F=8.7 signals a weak instrument for this subsample, reported as an honest miss on the point value, same qualitative caveat as the FE column.

## Reproduced (33)

| number in the paper | paper | this package |
|---|---|---|
| A_FE_pubbias_coef | -5.804 | -5.804008 |
| A_FE_pubbias_se | 1.999 | 1.999206 |
| A_FE_effect_coef | -0.0207 | -0.020657 |
| A_FE_effect_se | 0.103 | 0.103498 |
| A_FE_N | 347 | 347.0 |
| A_IV_pubbias_coef | -6.962 | -6.961687 |
| A_IV_pubbias_se | 1.694 | 1.69429 |
| A_IV_effect_coef | 0.0103 | 0.010272 |
| A_IV_effect_se | 0.104 | 0.104236 |
| A_IV_firstF | 46.17 | 46.174972 |
| A_IV_N | 251 | 251.0 |
| B_FE_pubbias_coef | -2.287 | -2.287243 |
| B_FE_pubbias_se | 0.843 | 0.842717 |
| B_FE_effect_coef | -0.149 | -0.149427 |
| B_FE_effect_se | 0.109 | 0.108786 |
| B_FE_N | 264 | 264.0 |
| B_IV_pubbias_coef | -0.553 | -0.553337 |
| B_IV_pubbias_se | 0.681 | 0.681457 |
| B_IV_effect_coef | -0.4 | -0.399673 |
| B_IV_effect_se | 0.114 | 0.113518 |
| B_IV_firstF | 69.98 | 69.982395 |
| B_IV_N | 212 | 212.0 |
| C_FE_pubbias_coef | -3.557 | -3.557342 |
| C_FE_pubbias_se | 0.0178 | 0.017772 |
| C_FE_effect_coef | 0.0496 | 0.04962 |
| C_FE_effect_se | 0.00246 | 0.002458 |
| C_FE_N | 40 | 40.0 |
| C_IV_pubbias_coef | -3.176 | -3.176358 |
| C_IV_pubbias_se | 0.853 | 0.853213 |
| C_IV_effect_coef | -0.00307 | -0.003072 |
| C_IV_effect_se | 0.0297 | 0.029706 |
| C_IV_firstF | 260.41 | 260.411431 |
| C_IV_N | 40 | 40.0 |
