# Replication files: hedge fund alphas

Data and code for "What Matters in Explaining the Variation in Hedge Fund Performance?". The data contain 1,019 alpha estimates from 74 studies published between 2001 and 2021. Alphas are in monthly percentage points.

## Contents

- data/alphas.xlsx (sheet "data"): the estimates and all coded variables. data/studies.xlsx lists the 74 primary studies; data/new_studies_to_code.xlsx codes the studies published after the search cutoff (Table A3).
- data/alphas.do: the Stata script of the first submission. The R code reads its regressor list and benchmark values; the script itself imports a file that is not distributed and is not meant to be run.
- code/alphas.do and code/alphas_reviewer_checks.do: Stata code for the descriptive figures and the OLS checks, both run by run_stata.do.
- work/compute/code: R code for the BMA, the study bootstrap and the OLS, CR2 and leave-one-study-out checks.
- work/compute/tables and work/compute/figures: all results as CSV files and figures. work/compute/NUMBERS.md lists each number used in the paper with its source file.

## Software

R 4.6.1 with BMS 0.3.5, readxl, sandwich, lmtest, clubSandwich 0.7.0, writexl and data.table; Stata/MP 15 with the SSC commands winsor2, ivreg2, ranktest and collin. software-sessionInfo.txt gives the full R session.

## Running the code

1. Stata, from this folder: `do run_stata.do`. Output goes to outputs/stata.
2. R, from this folder: `Rscript run_R.R` (OLS checks, CR2 inference, leave-one-study-out, Figure A2).
3. BMA and study bootstrap, from work/compute: `launch_production.ps1`, then `launch_bootstrap.ps1` (see README_RUNS.md). Both end with run_finalize.R, which writes Tables 3-5, A2 and A5 and NUMBERS.md. These runs take several days on a multi-core machine. The saved model fits and bootstrap draws are not included because of their size.

Jorion (2021) reports an alpha of 0.05 (t = 0.07) in Table 5 without a unit label. We read it as annual and divide the alpha and its standard error by 12.
