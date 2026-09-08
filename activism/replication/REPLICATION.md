# Replication package: "Does Shareholder Activism Create Value? A Meta-Analysis"

Bajzik, J. (2025), *Corporate Governance: An International Review*, doi 10.1111/corg.12637.

## Table reproduced

**Table 2, "Descriptive statistics for different subsamples"** -- the full-sample row plus
six subsamples defined directly by published 0/1 indicator columns: activism sponsor
(`Hedge_funds`), institutional setting (`Lo_/Hi_antidirector_rights`, split at the sample
median), and geographic region (`Europe`, `Asia`, `North_America`). 36 target cells: Nobs,
Mean, SD, W.Mean, W.SD for seven groups, plus the overall study count.

Table 2 was chosen over Table 3 ("Why the activism returns vary" -- the BMA + OLS
meta-regression) because Table 3 could not be attempted responsibly; see "Table 3: why it is
out of scope" below.

## Provenance

- Data: `data/v1/activism/activism.csv` as published by the site (1,973 rows, 159 columns --
  already the paper's final analysis sample: every row has `Relevant? ∈ {Odhad, Rovnice}`,
  and `ArticleNo` has exactly 67 distinct values, matching the paper's "1,973 estimates from
  67 studies" throughout).
- Code: `activism.R` (the author's script, as published at `site/activism/activism.R`) and the
  brief's line-numbered excerpt. The CSV publishes the codebook's row of long descriptive
  column headers (e.g. `"hedge fund activism"`, `"antidirector rights"`), not the short
  internal names `activism.R` uses internally after `read.xlsx(..., startRow = 2)` (e.g. `HF`,
  `AntidirectorRights`) -- run.R works from the published header names throughout and never
  invents a column that isn't in the site's own column list.
- The two blank-named columns immediately after `"Multiplicator to obtain estimates in points
  (number)"` (`Unnamed: 25`, `Unnamed: 26`) are the author's `Estim_adj` / `Se_adj` pair
  (`activism.R` lines ~101-102, ~113-114): raw `Estimate`/`SE` rescaled by the multiplicator so
  every study's effect is on a common percentage-point scale. Table 2 only needs `Estim_adj`
  (`Unnamed: 25`); `Se_adj` is not a Table 2 input.
- Winsorizing: `activism.R` line 127, `Winsorize(elasticity_adj, probs = c(0.01, 0.99))`,
  applied once to the full sample before any subsample is taken (confirmed by the code's own
  later subsetting, e.g. lines 622+, which always subsets the already-winsorized
  `elasticity_adjw`). `run.R` follows the same order: winsorize once on all 1,973 rows, then
  subset.
- Weighting: `activism.R` lines 132-136, `w1` = inverse of the number of estimates
  contributed by the study (`ArticleNo`), so a study with many estimates does not dominate the
  weighted mean/SD. `run.R` reproduces this exactly.
- Region grouping: `activism.R` lines 259-266 fold `Germany` into `Europe` before tabulating
  Country; `run.R` does the same (`Europe = Europe | Germany`, N = 457, matching the printed
  row exactly). The omitted reference category, `North_America`, is confirmed to equal the raw
  `US` dummy alone (N = 1,377, exact).

## Target-by-target results

| Target | Printed | Produced | Verdict |
|---|---:|---:|---|
| T2 Studies (all) | 67 | 67 | MATCH |
| T2 All Nobs | 1973 | 1973 | MATCH |
| T2 All Mean | 1.49 | 1.4938 | MATCH |
| T2 All SD | 3.04 | 3.0527 | MISS |
| T2 All WMean | 1.83 | 1.8375 | MISS |
| T2 All WSD | 3.42 | 3.4341 | MISS |
| T2 Hedge_funds Nobs | 467 | 467 | MATCH |
| T2 Hedge_funds Mean | 2.42 | 2.4330 | MISS |
| T2 Hedge_funds SD | 3.72 | 3.7453 | MISS |
| T2 Hedge_funds WMean | 3.10 | 3.1077 | MISS |
| T2 Hedge_funds WSD | 3.51 | 3.5215 | MISS |
| T2 Lo_antidirector_rights Nobs | 499 | 499 | MATCH |
| T2 Lo_antidirector_rights Mean | 1.54 | 1.5464 | MISS |
| T2 Lo_antidirector_rights SD | 3.04 | 3.0572 | MISS |
| T2 Lo_antidirector_rights WMean | 2.42 | 2.4256 | MISS |
| T2 Lo_antidirector_rights WSD | 3.49 | 3.5014 | MISS |
| T2 Hi_antidirector_rights Nobs | 1474 | 1474 | MATCH |
| T2 Hi_antidirector_rights Mean | 1.47 | 1.4760 | MISS |
| T2 Hi_antidirector_rights SD | 3.04 | 3.0520 | MISS |
| T2 Hi_antidirector_rights WMean | 1.70 | 1.7045 | MATCH |
| T2 Hi_antidirector_rights WSD | 3.39 | 3.4046 | MISS |
| T2 Europe Nobs | 457 | 457 | MATCH |
| T2 Europe Mean | 1.80 | 1.8033 | MATCH |
| T2 Europe SD | 3.16 | 3.1718 | MISS |
| T2 Europe WMean | 2.78 | 2.7835 | MATCH |
| T2 Europe WSD | 3.73 | 3.7386 | MISS |
| T2 Asia Nobs | 139 | 139 | MATCH |
| T2 Asia Mean | 1.23 | 1.2325 | MATCH |
| T2 Asia SD | 2.22 | 2.2429 | MISS |
| T2 Asia WMean | 1.21 | 1.2145 | MATCH |
| T2 Asia WSD | 1.93 | 1.9437 | MISS |
| T2 North_America Nobs | 1377 | 1377 | MATCH |
| T2 North_America Mean | 1.41 | 1.4175 | MISS |
| T2 North_America SD | 3.07 | 3.0777 | MISS |
| T2 North_America WMean | 1.70 | 1.7037 | MATCH |
| T2 North_America WSD | 3.42 | 3.4334 | MISS |

**15 / 36 match.** Every count (8/8: the study count and all 7 group Nobs) matches exactly,
and 7 of 28 continuous cells match. The 21 misses are not scattered -- every single one is a
small, one-directional overshoot of 0.01-0.03 in the same direction, on every group, on every
statistic. That pattern, not any individual cell, is the diagnostic.

## Cause of the misses: a winsorization-convention gap, not a modeling error

`activism.R` winsorizes with `DescTools::Winsorize(x, probs = c(0.01, 0.99))`, whose default
uses **R's own `quantile(type = 7)`** -- R's global default percentile method, not a Stata
command at all. `stata_compat.R` provides two winsorizing wrappers, both built for *Stata*
commands: `st_winsor` (SSC `winsor.ado`, order statistics at `floor(p*N)`) and `st_winsor2`
(Stata's `_pctile`, quantile type 2). Neither is R's type 7, and the run rules bar calling
`quantile()` directly, so `run.R` uses `st_winsor2` -- the closest sanctioned wrapper -- and
accepts whatever gap that leaves, per instruction: winsor convention is explicitly not
something to repair.

The size of that gap was confirmed once, outside `run.R`, as a diagnostic (not part of the
package, and not fed back into `targets.json`): recomputing the same 36 cells with a plain
`quantile(x, c(.01,.99))` (type 7) instead of `st_winsor2` reproduces **all 36 printed cells
exactly** -- every Mean, SD, W.Mean and W.SD, for every one of the seven groups, to the printed
second decimal. That rules out every other candidate explanation (wrong weight, wrong grouping,
wrong region fold, wrong reference category, a misread multiplicator column): the sample, the
weights, and the grouping are all already exactly right, since with the one substitution
(type 2 -> type 7 quantile) the fit is perfect. The only thing wrong is which of the two
*Stata* winsorizing conventions in `stata_compat.R` happens to match an *R-native* `Winsorize()`
default that isn't Stata at all, and isn't one either wrapper implements.

**Re-verified independently on this pass, two ways, both outside `run.R`:**

1. The full 36-cell reproduction above was re-run from scratch against
   `data/v1/activism/activism.csv` (fresh script, not reusing the earlier one) and reproduces
   every printed cell in Table 2 exactly under type-7 winsorization -- confirming the earlier
   diagnostic was not a fluke or a coding error in that one-off check.
2. `DescTools::Winsorize`'s actual source was printed directly (`print(DescTools::Winsorize)`
   after loading the installed package) rather than assumed from its documentation:

   ```r
   function (x, val = quantile(x, probs = c(0.05, 0.95), na.rm = FALSE))
   {
       x[x < val[1L]] <- val[1L]
       x[x > val[2L]] <- val[2L]
       return(x)
   }
   ```

   `val`'s default is `quantile(x, probs, na.rm = FALSE)` with **no `type=` argument at all**,
   so it resolves to `stats::quantile`'s own default, type 7. This is not an inference about
   what `Winsorize()` "probably" does -- it is the literal function body the author's
   `activism.R` line 127 call executes. There is no reading of `DescTools::Winsorize` under
   which it uses a Stata percentile convention, so neither `st_winsor` nor `st_winsor2` can
   ever close this gap without themselves becoming a type-7 wrapper, which `stata_compat.R`
   does not provide and which run.R is not permitted to add or approximate by calling
   `quantile()` directly.

Also independently confirmed on this pass: every specific line-number citation above (127 for
the `Winsorize()` call, 132-136 for `w1`, 259-266 for the Country/Europe/Germany fold) was
checked character-for-character against the site's published `activism.R` and is accurate. The
median-split construction of `Lo_`/`Hi_antidirector_rights` (not present as its own code block
in `activism.R`, since Table 2's prose describes it directly) is confirmed against the paper's
own text (Bajzik 2025, pp. 18-19): "We winsorize all continuous variables at the top and bottom
1% and define additional indicators prefixed 'Hi_' and 'Lo_' to represent observations above and
below the median of the full sample" -- exactly what `run.R` does with `median(antidirector)`.

## Table 3: why it is out of scope

Table 3 ("Why the activism returns vary") reports BMA posterior means/SDs/PIPs alongside a
"Frequentist Check (OLS)" on the ~18 variables BMA selects, clustered by study with Stata-style
(`se_type = "stata"`) standard errors -- confirmed against `activism.R` lines 1195-1213
(`lm_robust(y_ols ~ x_ols_sel, clusters = dataBMA$publid, se_type = "stata")`).

Two separate blockers ruled this table out for this package:

1. **BMA is explicitly out of repair scope.** The left panel's posterior means/SDs/PIPs come
   from a birth-death MC3 sampler (`bms(..., burn = 1e6, iter = 3e6, ...)`) -- squarely the
   "stochastic (bootstrap/wild-cluster ...)" category the brief instructs to report, never
   repair, and BMS's own MCMC is not seeded in the published code.
2. **The OLS "Frequentist Check" needs `Se_adj` (the SE regressor) for all 1,973 rows, and it
   is not fully recoverable from the published data.** `Se_adj` (`Unnamed: 26` in the CSV) is
   missing for 122 of 1,973 rows; `activism.R` fills those via a custom helper,
   `calculateSE(value, elasticity, type = "pvalue", obs)`, sourced from
   `functions/calculateSE_JB.R` -- a file the site does not publish and that is not part of
   `activism.R` itself. Of the 122 missing rows, 120 have a usable p-value and 2 have neither
   an SE nor a p-value at all. Without the exact formula (`obs` is passed in, suggesting a
   t-distribution with a specific, unstated degrees-of-freedom rule rather than a plain z
   approximation), any substitute formula is a guess that would silently contaminate 6% of the
   regressor, and there is no way to verify it against the published file, since the rows it
   would need to reproduce are exactly the ones missing. Table 3's own N = 1,973 for both panels
   confirms the author's pipeline does fill all 122; this package cannot, and reports that as a
   missing-input limitation rather than attempting a guessed imputation.

Given both, no cell of Table 3 is attempted here rather than publishing coefficients built on
an unverifiable regressor and an unseeded sampler.

## Repairs made

None, on this pass or the last. `run.R` was re-run unchanged and reproduces `results.json`
exactly (re-confirmed). The variable constructions (winsorization order, the weight, the
Europe/Germany fold, the antidirector-rights median split) were re-checked line-by-line against
the site's published `activism.R` and the paper's own text and are exactly right. The 21 misses
are not a bug to fix in `run.R`; they are the one documented, now doubly-verified winsorization
quantile-type gap (Stata type 2, the closest sanctioned wrapper, vs. R's native type 7, what
`DescTools::Winsorize`'s own source actually calls). Closing it would require either calling
`quantile()` directly in `run.R` or adding a type-7 wrapper to `stata_compat.R` -- both explicitly
forbidden by the run rules, so the gap is reported rather than papered over.

## Verdict

**PARTIAL.** 15 of 36 targets match exactly (all 8 counts, 7 of 28 continuous cells); the other
21 miss by a small, uniform, fully-diagnosed amount traceable to one documented convention gap
in the available toolkit, not to a wrong sample, wrong weight, or wrong estimator. Re-run and
re-verified on this pass: `Rscript run.R` still reproduces `results.json` exactly, and the
winsorization-convention diagnosis was independently re-derived from a fresh script plus a
direct read of `DescTools::Winsorize`'s source (see above), not merely repeated from the prior
write-up.
