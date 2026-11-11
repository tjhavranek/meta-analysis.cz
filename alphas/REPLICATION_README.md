# Replication package: What Matters in Explaining the Variation in Hedge Fund Performance?

Data and code for the meta-analysis of 1,019 hedge fund alpha estimates reported in 74 studies published between 2001 and 2021. Alphas are in percentage points per month.

## Contents

```
data/
  alphas.xlsx         the 1,019 estimates and the coded variables (sheet "data";
                      sheet "variables" defines the columns used by the code)
  studies.xlsx        the 74 primary studies (Table 1)
  new_studies.xlsx    studies not covered by the original search, screened for
                      Tables A3 and A3b and Figure A2
stata/
  run_stata.do        runs the three scripts below
  descriptives.do     summary statistics and means by category (Table 2), Figures 3-6,
                      OLS regressions with study-clustered standard errors
  figure2.do          Figure 2
  figure_A2.do        Figure A2
R/
  run_frequentist.R   Tables A1, A3, A3b, A4 and A6, the database checks and the OLS
                      at the evaluation vectors
  run_bma.R           Bayesian model averaging: Tables 3 and 5, credible intervals,
                      prior comparison, Figures 7 and 8
  run_bootstrap.R     study bootstrap: intervals of Tables 4, A2 and A5
  lib/                functions used by the three scripts
results/
  tables/             Tables 2-5 and A1-A6 and the online-appendix tables as CSV
  figures/            Figures 2-8 and A2
  bootstrap/          the 1,999 bootstrap estimates of each specification
```

## Running the code

All commands are run from this folder.

1. Stata: `do stata/run_stata.do`. About two minutes. Needs the user-written commands winsor2, ivreg2, ranktest and collin (see `stata/run_stata.do` for the installation commands). The run writes its logs to `results/`; they are not part of the archive.
2. `Rscript R/run_frequentist.R`. A few seconds.
3. `Rscript R/run_bma.R`. Estimates 21 MCMC chains of 7 million draws (three chains for each of seven BMA fits) in parallel and pools them. About four hours on twelve cores; each worker needs about 2 GB of memory. The chains are saved in `work/fits/` and reused if the script is run again.
4. `Rscript R/run_bootstrap.R`. Re-estimates the BMA on 1,999 bootstrap samples of studies for each of the four time specifications (7,996 short chains). About a day on twelve cores. The draws are saved in `work/bootstrap/` and an interrupted run resumes where it stopped.

`Rscript R/run_bma.R quick` and `Rscript R/run_bootstrap.R quick` run the same code with chains one hundred times shorter and 20 bootstrap draws, writing to `results_quick/` and `work_quick/`. They finish in minutes and are meant for checking that the code runs; their numbers are not the paper's.

Steps 3 and 4 use fixed seeds and reproduce the results in `results/` to machine precision with the software versions below.

## Where each result comes from

| In the paper | File |
|---|---|
| Table 1 | `data/studies.xlsx` |
| Table 2 | `results/tables/table2_means.csv` |
| Table 3 | `results/tables/table3.csv` |
| Table 4 | `results/tables/table4.csv` |
| Table 5 | `results/tables/table5.csv` |
| Table A1 | `results/tables/tableA1.csv`; all evaluation vectors in `evaluation_vectors.csv` |
| Table A2 | `results/tables/tableA2.csv` |
| Tables A3 and A3b | `results/tables/tableA3.csv`, `tableA3b.csv` |
| Table A4 | `results/tables/tableA4.csv`; every omission in `leave_one_study_out.csv` |
| Table A5 | `results/tables/tableA5.csv` |
| Table A6 | `results/tables/tableA6.csv` |
| Online appendix: database checks | `results/tables/oa_database_checks.csv`, `database_combinations.csv` |
| Online appendix: bootstrap intervals | `results/tables/oa_bootstrap_intervals.csv`; `bootstrap_full_support_comparison.csv` compares them with intervals from the draws in which no benchmark indicator is dropped |
| Online appendix: alternative priors | `results/tables/oa_prior_coefficients.csv`, `oa_prior_best_practice.csv` |
| Figure 1 | Count of articles in five journals; not produced by the code |
| Figure 2 | `results/figures/F2_trend.pdf` |
| Figures 3-6 | `results/figures/F3_histogram.pdf`, `F4_studies.pdf`, `F5_countries.pdf`, `F6_pattern1.pdf` to `F6_pattern6.pdf` |
| Figure 7 | `results/figures/F7_bma.png` (also as `F7_bma.pdf`) |
| Figure 8 | `results/figures/F8_comparison.pdf` |
| Figure A2 | `results/figures/FA2_trend.pdf` |
| Figure A1 | Flow diagram of the search, drawn in the manuscript source; not produced by the code |

Other files in `results/tables/`: `bma_<fit>_coefficients.csv` and `bma_<fit>_best_practice.csv` hold the posterior inclusion probabilities, posterior moments and best-practice alphas of each of the seven BMA fits (`log`, `linear`, `quad_hier`, `nocit`, `prior_uniform`, `prior_bric`, `prior_dilution`); `bma_chain_diagnostics.csv` reports the number of retained models and the agreement of the three chains of each fit; `bootstrap_diagnostics.csv` reports the sample size, dropped regressors and chain retention of each bootstrap draw (`unsupported` counts the evaluation vectors that lie outside the row space of the resampled design); `ols_best_practice.csv` and `ols_time_specifications.csv` evaluate the full-variable OLS of each time specification at the evaluation vectors, with study-clustered confidence intervals; `global_funds_quantiles.csv` gives the quartiles of the alphas of global funds quoted with Figure 5; `prior_correlation_screen.csv` gives the correlations used in the discussion of Figure 8; `study_points.csv` and `new_studies_band.csv` are the study medians and the prediction band of Figure A2. In `table5.csv`, the percentage columns express each change relative to the all-strategies best-practice alpha, which is negative.

## Methods notes

- Alpha and its standard error are winsorized at the 1st and 99th percentiles (Stata `winsor2`, replicated in R with `quantile(type = 2)`). Table 2 and all regressions use the winsorized values; the figures plot the reported alphas (Figures 3-6 restrict them to the range -3 to 3).
- The data year and the publication year enter as ln(year of data - 1989) and ln(year of publication - 2000). The `linear` specification uses the shifted years instead, and `quad_hier` adds their squares.
- BMA: BMS 0.3.5 with the unit information g-prior and the beta-binomial ("random") model prior with expected model size K/2. The quadratic specification uses a hierarchical version of this prior that excludes models containing a squared year without the corresponding linear term. The prior comparison uses the uniform model prior, the BRIC g-prior and the dilution prior of George (2010). Each fit pools three chains of 1 million burn-in draws and 6 million retained draws, started from the null model, from the nine-variable OLS specification and from the full model; the retained models of the three chains are merged and reweighted with their exact marginal likelihoods. `BMS::bms` reseeds from the clock, so `R/lib/bma.R` uses a copy of the function without that line; the installed package is not modified.
- Best-practice alphas are the posterior of the fitted value at the evaluation vectors of Table A1, a mixture of Student t distributions over the retained models. Credible intervals are its 2.5th and 97.5th percentiles.
- Study bootstrap: studies are resampled with replacement (1,999 samples, the same samples for every specification), the data are winsorized again, and the BMA is re-estimated with 100,000 burn-in and 300,000 draws. Regressors that are constant or collinear in a sample are dropped for that draw. Intervals are the percentile intervals of the 1,999 best-practice alphas (`quantile(type = 7)`); the online appendix also reports basic and bias-corrected intervals.
- Jorion (2021) reports an alpha of 0.05 (t = 0.07) in Table 5 without a unit label. We read it as annual and divide the alpha and its standard error by 12.

## Software

R 4.6 with BMS 0.3.5, readxl 1.5, sandwich 3.1, clubSandwich 0.7.0 and parallel; Stata/MP 15 with winsor2 1.1, ivreg2 4.1.12 and ranktest 2.0.04 from SSC and collin 1.6 from UCLA OARC.
