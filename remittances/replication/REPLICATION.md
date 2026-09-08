# Replication package: remittances

Paper: Cazachevici, Havranek & Horvath (2020), "Remittances and Economic Growth: A
Meta-Analysis", *World Development* 134, 105021. doi:10.1016/j.worlddev.2020.105021

Reproduced: **Appendix Table B1** (test of publication bias, equations with GDP growth as
dependent variable, long term, N = 347), **Appendix Table D1** (the same test for the short-run
effect, N = 48), and the rows of **main-text Table 3** ("Alternative approaches to correcting
for publication bias", N = 487) that carry the abstract's headline claim.

Data: the site's published mirror of the author's own file,
`site/data/v1/remittances/remittances.csv` (538 rows, 71 columns, unchanged). Code: the
author's own `site/remittances/remittances.do`. No other source was used.

**Score: 52 of 54 targets reproduce.** The two that do not are Table 3's Andrews & Kasy row and
its stem-based row; both are third-party estimators that never appear in the do-file, and the
reason they are left as gaps rather than approximated is set out at the end.

---

## Method (from `remittances.do`)

The estimated equation in all three tables is the FAT-PET test

    PCC_is = b0 + b1 * SE_PCC_is + e_is

with `PCC = t / sqrt(t^2 + DF)` and `SE_PCC = sqrt((1 - PCC^2) / DF)`, built separately from the
long-run and short-run t-statistics already in the data (`TSTAT_L`, `TSTAT_S`). Three
observations (rows 195, 205, 283) are dropped exactly as the do-file drops them
(`gen odd=0` / `replace odd=1 in ...` / `drop if odd==1`, "3 observations deleted").

Specifications (1)-(5) are weighted by inverse variance, implemented as the do-file implements
it: divide through by `SE_PCC` and run

    TSTAT = b0 * SE1_PCC + b1,      SE1_PCC = 1 / SE_PCC

so in the transformed regression **the constant is b1 ("Publication bias") and the slope on
`SE1_PCC` is b0 ("True effect")**. Specification (6) weights by `Inverse = 1/No_Eq` instead, so
it runs in the untransformed `PCC ~ SE_PCC` space, where the mapping reverses.

| Column | Spec label (paper) | Author's Stata command | Wrapper |
|---|---|---|---|
| (1) | WLS, clustered | `reg TSTAT_L SE1_PCC_L, cluster(IDStudy)` | `st_regress(..., cluster=~IDStudy)` |
| (2) | WLS, robust | `rreg TSTAT_L SE1_PCC_L` | `st_rreg()` |
| (3) | FE, clustered | `xtreg ..., fe vce(cluster IDStudy)` | `st_xtreg_fe_cons()` for the printed `_cons`, `st_xtreg_fe()` for the slope |
| (4) | ME | `xtmixed TSTAT_L SE1_PCC_L \|\| IDStudy:` | `st_mixed()` |
| (5) | IV, clustered | `ivreg TSTAT_L (SE1_PCC_L=Instrum), cluster(IDStudy)` | `st_regress()` with the IV formula |
| (6) | WLS, Equations, clustered | `reg PCC_L SE_PCC_L [pweight=Inverse], cluster(IDStudy)` | `st_regress(..., weights=~Inverse)` |

Table D1 has no FE column, so its five columns are (1) WLS, (2) rreg, (3) ME, (4) IV,
(5) Equations, built the same way from `TSTAT_S`/`SE1_PCC_S`/`PCC_S`/`SE_PCC_S`.

### Sample definitions (checked against the data, not assumed)

- **Table B1**, N = 347: after the 3-observation drop, `Growth==1` and `PCC_L` non-missing.
- **Table D1**, N = 48: after the drop, `PCC_S` non-missing. No further filter.
- **Table 3**, N = 487: after the drop, `PCC_L` non-missing, with *no* `Growth` filter -- the
  same sample as the main-text Table 2 that precedes it.

All three reproduce exactly. The flagged observations really were dropped, not kept: the
do-file drops them, and 538 - 3 = 535 rows give 487 long-run and 48 short-run estimates, which
are the Ns the paper prints.

---

## What was wrong, and what fixed it

Every estimator below was checked against **Stata 15.1 run on the site's own published CSV**,
not against the printed table alone. The probe files are in
`repl/stata_work_remittances/` (`probe1.do`, `probe2.do`, `probe3.do`).

### 1. Spec (2), "WLS, robust" -- 8 cells, all now reproduce

The paper's table note calls this "iteratively re-weighted WLS"; the do-file calls
`rreg`. The previous version of this package left all eight cells (four per table) unresolved
because `stata_compat.R` had no wrapper, and it was right not to guess: `rreg` is **not**
`regress, robust`, and it is **not** `MASS::rlm`. It is a specific three-stage recipe whose
reported standard errors do not come from the robust fit at all.

`stata_compat.R` now carries `st_rreg()`, ported line by line from Stata 15.1's own
`rreg.ado`, version 3.4.1 (21sep2017):

1. OLS, then drop every observation with Cook's D > 1.
2. Huber iterations: `w = 1` if `|e| <= 2m`, else `2m/|e|`, with `m` the median of
   `|e - median(e)|`; refit by WLS; stop when the largest weight change is below `5*tolerance`.
3. Tukey biweight iterations from there: `s = m/0.6745`, `w = max(1 - (e/(c*s))^2, 0)^2` with
   `c = tune*4.685/7 = 4.685`; stop below `tolerance`. Runs at least once.
4. **The printed table is not the last weighted fit.** `rreg` forms pseudo-values
   `y* = xb + (lambda*s/a)*(e/s)*w` and runs a plain *unweighted* OLS of `y*` on `X`; that
   regression's coefficients and OLS variance are what Stata prints, with `df_r = N - k`.

One detail decides the fourth significant digit and is invisible in the `.ado`: the `N` in
`lambda = 1 + ((df_m+1)/N)*(1-a)/a` is `e(N)` of the **last weighted** regression, and Stata's
analytic weights exclude zero-weight observations. The biweight sets weights to exactly zero
beyond `c`, so that `N` is the count of nonzero weights -- 345, not the 347 of the sample:

| `lambda` uses | pub. bias SE | true effect SE |
|---|---|---|
| N = 347 (sample) | 0.2465530 | 0.0136448 |
| N = 345 (nonzero weights) | **0.2465561** | **0.0136450** |
| Stata 15.1 `rreg` | 0.2465561 | 0.0136450 |

Agreement with Stata, both tables, all four cells each:

| | Stata 15.1 | `st_rreg()` | paper prints |
|---|---|---|---|
| B1 (2) `_cons` | 0.72085003 (0.24655608) | 0.72085001 (0.24655609) | 0.721 (0,25) |
| B1 (2) `SE1_PCC_L` | 0.00263715 (0.01364496) | 0.00263715 (0.01364496) | 0.003 (0,01) |
| D1 (2) `_cons` | 0.45439535 (0.64304814) | 0.45439537 (0.64304813) | 0454 (0,64) |
| D1 (2) `SE1_PCC_S` | -0.09360287 (0.06488031) | -0.09360288 (0.06488031) | -0094 (0,06) |

The weights are compared too, not just the printed cells: the ported final weight vector agrees
with Stata's own `genwt()` output to 4e-8 across all 347 observations, and the iteration path is
identical -- 3 Huber then 3 biweight steps, with the same maximum weight change at each
(0.72262787, 0.10264882, 0.01831810; 0.29408619, 0.02231489, 0.00353087).

`st_rreg()` was **appended** to `stata_compat.R`; every byte before it is unchanged (the
pre-edit file hashes `1953ca95...`, and the file's prefix still does), so no other package's
numbers can move. `test_compat.R` gained four assertions on Table B1 column (2) and now passes
20 of 20.

### 2. "Top 10" -- right answer, wrong reason; the derivation is now correct

The number was already 0.025. The justification written into the old `run.R` was not: it claimed
Stata's `summarize, detail` uses an interpolating percentile (R's quantile type 7) and that the
order-statistic rule gives N = 48 and 0.028. Stata contradicts the first half of that.

`summarize Prec_L, detail` in Stata 15.1 returns `r(p90) = 25.2752`, which **is** the 439th of
487 order statistics -- the same non-interpolating rule `st_winsor2()` pins for `_pctile`. On
paper `Prec_L > r(p90)` should then leave 48 observations. Stata leaves 49, and `probe3.do`
shows why:

    di %20.15f Prec_L[439]      25.275196075439453
    local b = r(p90)
    di %20.15f `b'              25.275196075439450     <- one ULP lower
    di %21x `b'                 +1.946733fffffffX+004  (variable: +1.9467340000000X+004)
    count if Prec_L > `b' & Prec_L!=.        49
    summarize PCC_L if Prec_L > `b'          N = 49, mean = .0254348

Passing `r(p90)` through a local macro loses the last bit, so the boundary estimate survives the
strict inequality. That is not a rounding curiosity: the 48-observation mean is 0.0278, which
prints as **0.028**; the paper prints **0.025**, and only the 49-observation mean (0.0254348)
gives it. `run.R` now takes `r(p90)` as the order statistic and selects `Prec_L >= r(p90)`,
which is the 49 estimates Stata actually summarised. The old code reached the same 49 by an
interpolated cutoff that happened to fall in the gap between the 438th and 439th order
statistics -- the right set for the wrong reason, and fragile.

### 3. "IV, clustered" -- the command is `ivreg`, not `ivreg2`

The earlier note here described an `ssc()` grid search that landed on fixest's default
small-sample correction. The search was unnecessary and the conclusion was under-evidenced: the
do-file plainly reads `ivreg TSTAT_L (SE1_PCC_L=Instrum) if Growth==1, cluster(IDStudy)`.
`ivreg` is Stata's **official** 2SLS command, which applies small-sample corrections by default;
it is not the user-written `ivreg2`, whose large-sample convention `st_ivreg2()` pins and which
returns 0.7377 against the printed 0.75. `st_regress()` carries exactly the right convention, and
Stata 15.1 confirms the target: 1.729701 (0.7469339) and -0.0503587 (0.0437068) for B1 (5),
1.158113 (0.826306) and -0.1719219 (0.084979) for D1 (4). Both reproduce to seven digits.

### 4. "ME" -- `xtmixed` is ML here, not REML

`stata_compat.R` keeps `st_xtmixed()` (REML) apart from `st_mixed()` (ML) because Stata 11's
`xtmixed` defaulted to REML. This is a 2020 paper, and in Stata 15.1 -- re-run in `probe2.do` --
`xtmixed` and `mixed` print the identical "Mixed-effects **ML** regression" header and identical
coefficients. `st_mixed()` is therefore the right wrapper, and it reproduces Stata's
1.102123 (0.3662944) / 0.0268343 (0.0156751) for B1 (4).

On D1 (3) the study random-effect variance is estimated at the boundary (Stata reports
`sd(_cons) = 9.59e-11`; `lmer` warns "singular fit"). Both tools collapse to the same point
estimates as column (1), which is why the paper prints 0.751 and -0.124 twice. That is a genuine
property of the fit at N = 48, not a copy-paste in the table or a duplicate in this code.

---

## Target-by-target results

**Table B1 (long-run, N = 347)** -- 25 of 25.

| cell | printed | produced | verdict |
|---|---|---|---|
| N | 347 | 347 | match |
| (1) pub. bias | 0.677 | 0.6771 | match |
| (1) pub. bias SE | 0.61 | 0.6052 | match |
| (1) true effect | 0.014 | 0.0143 | match |
| (1) true effect SE | 0.03 | 0.0303 | match |
| (2) pub. bias | 0.721 | 0.7209 | match |
| (2) pub. bias SE | 0.25 | 0.2466 | match |
| (2) true effect | 0.003 | 0.0026 | match |
| (2) true effect SE | 0.01 | 0.0136 | match |
| (3) pub. bias | 0.267 | 0.2670 | match |
| (3) pub. bias SE | 0.29 | 0.2911 | match |
| (3) true effect | 0.040 | 0.0395 | match |
| (3) true effect SE | 0.02 | 0.0179 | match |
| (4) pub. bias | 1.102 | 1.1021 | match |
| (4) pub. bias SE | 0.37 | 0.3663 | match |
| (4) true effect | 0.027 | 0.0268 | match |
| (4) true effect SE | 0.02 | 0.0157 | match |
| (5) pub. bias | 1.730 | 1.7297 | match |
| (5) pub. bias SE | 0.75 | 0.7469 | match |
| (5) true effect | -0.050 | -0.0504 | match |
| (5) true effect SE | 0.04 | 0.0437 | match |
| (6) pub. bias | 1.956 | 1.9555 | match |
| (6) pub. bias SE | 0.35 | 0.3473 | match |
| (6) true effect | -0.024 | -0.0237 | match |
| (6) true effect SE | 0.03 | 0.0303 | match |

**Table D1 (short-run, N = 48)** -- 21 of 21.

| cell | printed | produced | verdict |
|---|---|---|---|
| N | 48 | 48 | match |
| (1) pub. bias | 0.751 | 0.7505 | match |
| (1) pub. bias SE | 0.53 | 0.5339 | match |
| (1) true effect | -0.124 | -0.1236 | match |
| (1) true effect SE | 0.05 | 0.0536 | match |
| (2) pub. bias | 0.454 | 0.4544 | match |
| (2) pub. bias SE | 0.64 | 0.6430 | match |
| (2) true effect | -0.094 | -0.0936 | match |
| (2) true effect SE | 0.06 | 0.0649 | match |
| (3) pub. bias | 0.751 | 0.7505 | match |
| (3) pub. bias SE | 0.76 | 0.7626 | match |
| (3) true effect | -0.124 | -0.1236 | match |
| (3) true effect SE | 0.08 | 0.0769 | match |
| (4) pub. bias | 1.158 | 1.1581 | match |
| (4) pub. bias SE | 0.83 | 0.8263 | match |
| (4) true effect | -0.172 | -0.1719 | match |
| (4) true effect SE | 0.08 | 0.0850 | match |
| (5) pub. bias | 0.359 | 0.3588 | match |
| (5) pub. bias SE | 0.99 | 0.9930 | match |
| (5) true effect | -0.017 | -0.0172 | match |
| (5) true effect SE | 0.15 | 0.1503 | match |

**Main-text Table 3 (N = 487)** -- 6 of 8.

| Method | printed | produced | verdict |
|---|---|---|---|
| Observations | 487 | 487 | match |
| Uncorrected mean | 0.103 | 0.1026 | match |
| Top 10 | 0.025 | 0.0254 (N = 49) | match |
| WAAP | 0.042 | 0.0421 (N = 89) | match |
| A&K (Andrews & Kasy 2019) | 0.121 | -- | **not reproduced** |
| Stem-based (Furukawa 2019) | 0.036 | -- | **not reproduced** |

A note on how these numbers look in the article: Tables 2, B1, C1 and D1 print most coefficients
without a decimal point (1.499 appears as `1499`) and most standard errors with a decimal comma
(`(0,56)`), and two standard errors carry a stray minus sign inside the parentheses. The site's
own front matter records this. `targets.json` reads them as the numbers they are -- `0454` as
0.454, `(0,64)` as 0.64 -- and every one of them was re-checked against the article text before
this package was scored. No transcription error was found.

---

## What still does not reproduce, and why it is left alone

**Table 3's "A&K" (0.121) and "Stem-based bias correction model" (0.036).**

These are the only two gaps, and the reason is the same for both: `remittances.do` does not
contain them. Where every other row of every reproduced table is a Stata command, these two are
bare URLs in the author's script --

    *A&K
    *https://maxkasy.github.io/home/metastudy/
    *Stem
    *in R: https://github.com/Chishio318/stem-based_method

-- pointing at third-party code that ran outside the do-file. A&K is Andrews and Kasy's (2019)
publication-selection maximum-likelihood model, a bespoke MATLAB/Stata routine with its own
choices of p-value cutoffs and symmetry assumptions; the stem-based method is Furukawa's (2019)
R implementation, which is not on CRAN. Neither is a Stata command, so neither can be pinned in
`stata_compat.R` the way every other cell here is, and neither can be checked against Stata --
the oracle that settled all eight `rreg` cells, the Top-10 threshold and the IV convention above.

A from-scratch reimplementation of either could only be validated against the single printed
number it is trying to hit. That makes "it reproduces" and "it was tuned until it did"
indistinguishable, which is the one failure this package exists to avoid, so both are reported
as gaps. Nothing the paper concludes rests on them: the three Table 3 rows that do reproduce
(0.025 and 0.042 against an uncorrected 0.103) already bracket the claim, and A&K's 0.121 is the
largest of the five estimates, so restoring it would not make the corrected effect smaller.

---

## The paper's headline claim

The site summarises this paper as **"positive but economically small."** The phrase is the
paper's own, verbatim in the abstract and again in the introduction. The numbers behind it are
main-text Table 3, not the appendix tables: the uncorrected mean partial correlation is 0.103,
and the bias-corrected figures this package can compute are 0.025 (Top 10) and 0.042 (WAAP).
The paper's gloss is that "the underlying effect of remittances on economic growth is small in
all of the methodological approaches: none passes Doucouliagos's bar for a medium effect" --
the 0.173 threshold of Doucouliagos (2011). Both reproduced corrections sit well under it and
well below the uncorrected mean: positive, and shrinking toward zero once publication bias is
corrected for.

## Not attempted: Table C1 (Appendix C, N = 489)

Table C1 repeats the B1 test "including 2 Granger papers". No published column flags which two
studies those are, and the do-file has no block that performs that inclusion. Guessing a filter
until N came out at 489 would be exactly the kind of repair this build forbids, so Table C1 was
not attempted and carries no targets.

## Running it

    Rscript run.R

Reads only `site/data/v1/remittances/remittances.csv`, sources `stata_compat.R`, writes
`results.json` beside itself, and prints every produced number together with the Stata command
each one emulates.
