# Replication package: house_prices

**Paper:** "When Does Monetary Policy Sway House Prices? A Meta-Analysis," IMF Economic
Review (2023), doi [10.1057/s41308-022-00185-5](https://doi.org/10.1057/s41308-022-00185-5).

**Table reproduced:** Table 1, Panel A ("Linear models") -- the FAT-PET publication-bias
test (regression of reported semi-elasticities on their standard errors), estimated by
OLS and by WLS (weights proportional to inverse variance), at each of the six impulse-
response horizons reported in the paper (1, 2, 4, 8, 12, 16 quarters after a monetary
policy shock). Also checks the "Observations" row under Panel B and the note "The mean
uncorrected effect at the 8-quarter horizon was -1.2."

Panel A is the headline table for which the author's Stata code (house.do) survives
uncommented in the brief and for which every ingredient has a wrapper in
`stata_compat.R`. Panel B's nonlinear corrections (stem-based method, selection model,
p-uniform*) and Table 2's Bayesian model averaging have no corresponding wrapper
(no BMA, no selection-model, no stem/p-uniform routine in `stata_compat.R`) and are out
of scope for this package.

## Provenance

`author_code` -- every number reproduced here traces to explicit lines of house.do
(reproduced in `run.R`'s header comment): `use`, the `replace est=100*est` /
`se_avg` / `prec_avg` / `t_avg` block, `keep if inlevels==1`, and the six pairs of
`ivreg2 est SE [pweight=prec] if ... , cluster(idstudy idcountry)` calls (one pair per
horizon, unweighted then weighted).

One inference was necessary: the extracted code list `gen`-erates `se_avg`, `prec_avg`
and `t_avg` (lines 45-48) but the regression lines that follow reference variables named
`SE`, `prec` and `t`. No `rename` line survived the extraction. We take
`SE == se_avg`, `prec == prec_avg`, `t == t_avg` -- the only candidates with matching
units and role. This is documented at the top of `run.R`. It turns out to be immaterial
to every number produced: in the published data `t_avg` never falls below -50 (min
observed value ~ -9.66), so the `if t>-50` filters in the horizon-2/4/8/12/16 regressions
never actually drop an observation, and the horizon==1 regression (which the author code
runs with no `t` filter at all) needs no such variable in the first place. The resulting
sample sizes match the paper's printed "Observations" row exactly for all six horizons,
which is the concrete check that this inference did not change any target.

## Data

`data/v1/house_prices/house_prices.csv`, filtered to `inlevels==1` (line 112 of
house.do), as published by the site. No other file was read.

## Targets vs. produced

All 55 targets are deterministic (coefficients, clustered standard errors, sample
counts, and one reported sample mean) -- none of the wild-bootstrap confidence intervals
(stochastic; not targeted, per instructions) enter here.

| Label | Printed | Produced | Verdict |
|---|---:|---:|---|
| T1_h1_OLS_SE_coef | -0.815 | -0.815 | MATCH |
| T1_h1_OLS_SE_se | 0.463 | 0.463 | MATCH |
| T1_h1_OLS_const_coef | -0.014 | -0.014 | MATCH |
| T1_h1_OLS_const_se | 0.168 | 0.168 | MATCH |
| T1_h1_WLS_SE_coef | -0.705 | -0.705 | MATCH |
| T1_h1_WLS_SE_se | 0.179 | 0.179 | MATCH |
| T1_h1_WLS_const_coef | -0.059 | -0.059 | MATCH |
| T1_h1_WLS_const_se | 0.046 | 0.046 | MATCH |
| T1_h1_N | 222 | 222 | MATCH |
| T1_h2_OLS_SE_coef | -1.117 | -1.117 | MATCH |
| T1_h2_OLS_SE_se | 0.367 | 0.367 | MATCH |
| T1_h2_OLS_const_coef | -0.020 | -0.020 | MATCH |
| T1_h2_OLS_const_se | 0.185 | 0.185 | MATCH |
| T1_h2_WLS_SE_coef | -0.874 | -0.874 | MATCH |
| T1_h2_WLS_SE_se | 0.147 | 0.147 | MATCH |
| T1_h2_WLS_const_coef | -0.147 | -0.147 | MATCH |
| T1_h2_WLS_const_se | 0.062 | 0.062 | MATCH |
| T1_h2_N | 227 | 227 | MATCH |
| T1_h4_OLS_SE_coef | -1.353 | -1.353 | MATCH |
| T1_h4_OLS_SE_se | 0.427 | 0.427 | MATCH |
| T1_h4_OLS_const_coef | -0.015 | -0.015 | MATCH |
| T1_h4_OLS_const_se | 0.248 | 0.248 | MATCH |
| T1_h4_WLS_SE_coef | -1.092 | -1.092 | MATCH |
| T1_h4_WLS_SE_se | 0.203 | 0.203 | MATCH |
| T1_h4_WLS_const_coef | -0.185 | -0.185 | MATCH |
| T1_h4_WLS_const_se | 0.093 | 0.093 | MATCH |
| T1_h4_N | 237 | 237 | MATCH |
| T1_h8_OLS_SE_coef | -1.160 | -1.160 | MATCH |
| T1_h8_OLS_SE_se | 0.308 | 0.308 | MATCH |
| T1_h8_OLS_const_coef | -0.233 | -0.233 | MATCH |
| T1_h8_OLS_const_se | 0.219 | 0.219 | MATCH |
| T1_h8_WLS_SE_coef | -1.160 | -1.160 | MATCH |
| T1_h8_WLS_SE_se | 0.204 | 0.204 | MATCH |
| T1_h8_WLS_const_coef | -0.234 | -0.234 | MATCH |
| T1_h8_WLS_const_se | 0.121 | 0.121 | MATCH |
| T1_h8_N | 237 | 237 | MATCH |
| T1_h12_OLS_SE_coef | -0.667 | -0.667 | MATCH |
| T1_h12_OLS_SE_se | 0.317 | 0.317 | MATCH |
| T1_h12_OLS_const_coef | -0.501 | -0.501 | MATCH |
| T1_h12_OLS_const_se | 0.252 | 0.252 | MATCH |
| T1_h12_WLS_SE_coef | -0.964 | -0.964 | MATCH |
| T1_h12_WLS_SE_se | 0.234 | 0.234 | MATCH |
| T1_h12_WLS_const_coef | -0.212 | -0.212 | MATCH |
| T1_h12_WLS_const_se | 0.135 | 0.135 | MATCH |
| T1_h12_N | 232 | 232 | MATCH |
| T1_h16_OLS_SE_coef | -0.375 | -0.375 | MATCH |
| T1_h16_OLS_SE_se | 0.215 | 0.215 | MATCH |
| T1_h16_OLS_const_coef | -0.560 | -0.560 | MATCH |
| T1_h16_OLS_const_se | 0.201 | 0.201 | MATCH |
| T1_h16_WLS_SE_coef | -0.732 | -0.732 | MATCH |
| T1_h16_WLS_SE_se | 0.199 | 0.199 | MATCH |
| T1_h16_WLS_const_coef | -0.175 | -0.175 | MATCH |
| T1_h16_WLS_const_se | 0.116 | 0.116 | MATCH |
| T1_h16_N | 226 | 226 | MATCH |
| T1_h8_mean_uncorrected | -1.2 | -1.2 | MATCH |

**55 / 55 targets matched. No repairs were needed.**

## Misses

None.

## How to run

```
Rscript run.R
```

Reads `data/v1/house_prices/house_prices.csv` from the site's published data
directory, prints every produced number, and writes `results.json`. `verify.R` (not
required to reproduce the numbers, provided for convenience) reloads `results.json`
and `targets.json` and prints the same target-by-target table above.

## Verdict

**CONCORDANT.** Every deterministic target (48 coefficient/SE cells, 6 sample-size
counts, and the 1 reported sample mean) matched the paper's printed Table 1, Panel A at
its printed precision, using only `stata_compat.R` wrappers (`st_ivreg2`, `st_coefs`,
`st_keep_if`) and data from the site's published CSV.
