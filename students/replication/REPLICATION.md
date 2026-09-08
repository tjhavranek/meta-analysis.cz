# Replication package: "The Impact of Student Employment on Educational Outcomes" (EER 2024)

**Table reproduced:** Table 2, "Tests suggest small publication bias overall" — Panel A
(Linear techniques: OLS / IV / Study / Precision), Panel B (Between/within: FE column only),
and the WAAP row of Panel C. This is the paper's headline publication-bias table, estimated on
the full sample of 861 estimates rather than the endogeneity-split Table 3.

**Provenance:** `students.do` as published at `web_meta/site/students/students.do`, section
"PUBLICATION BIAS - testing larger sample" (the first of the two near-duplicate passes in the
do-file). Data: `data/v1/students/students.csv` (892 rows, the file the site publishes).

**Score: 27 of 28 deterministic targets reproduce.** The single miss is the WAAP standard
error, and the evidence below says the paper's cell is wrong, not this code.

## What was not attempted (and why)

- **Panel B, BE and RE columns.** The do-file uses `xtreg ..., be` and `xtreg ..., re`.
  `stata_compat.R` wraps only `xtreg ..., fe` (`st_xtreg_fe` / `st_xtreg_fe_cons`); there is no
  wrapper for the between- or random-effects panel estimator. Per the package rules that is a
  stop, not license to hand-build one with a bare `lm`/`feols` call, so these two columns are
  excluded from `targets.json` rather than guessed at.
- **Panel C: Stem method, Kinked model, Selection model, p-uniform\*.** The do-file routes
  these to tools with no Stata-command (and no `stata_compat.R`) analogue: the stem method to a
  separate R script (`stem_method.R`, Furukawa 2019), the kinked model to the user-written
  Stata command `kink` (Bom & Rachinger 2020), p-uniform\* to `puniform::puni_star()`. None is
  attempted.
- **Panel C, WAAP row IS attempted**, because the do-file builds it with plain `reg` (Stata
  `regress`), which `st_regress` covers:
  ```
  summarize pcc_w [aweight=precision_w*precision_w]
  gen waapbound = abs(r(mean))/2.8
  reg tstat precision_w if se_pcc < waapbound, noconstant
  ```
- **The bracketed confidence intervals** in Panel A come from wild-cluster bootstrap
  (`boottest`, no seed set) and are stochastic; they are not targets.

## Target-by-target results

Sample after `drop if idstudy>69 | missing(pcc) | missing(se_pcc)`: N = 861, which is the N
Table 2 prints in every panel.

### Panel A: Linear techniques

| Spec | Cell | Printed | Produced | Verdict |
|---|---|---|---|---|
| OLS | Standard error (coef) | -0.881 | -0.88105 | match |
| OLS | SE | 0.312 | 0.31171 | match |
| OLS | Constant | 0.00597 | 0.0059714 | match |
| OLS | Constant SE | 0.0123 | 0.0123163 | match |
| OLS | N | 861 | 861 | match |
| IV | Standard error (coef) | -0.914 | -0.91361 | match |
| IV | SE | 0.343 | 0.34332 | match |
| IV | Constant | 0.00692 | 0.0069193 | match |
| IV | Constant SE | 0.0126 | 0.0125937 | match |
| IV | N | 861 | 861 | match |
| Study | Standard error (coef) | -1.094 | -1.09370 | match |
| Study | SE | 0.444 | 0.44402 | match |
| Study | Constant | 0.0136 | 0.0136084 | match |
| Study | Constant SE | 0.0176 | 0.0176167 | match |
| Study | N | 861 | 861 | match |
| Precision | Standard error (coef) | -0.544 | -0.54399 | match |
| Precision | SE | 0.310 | 0.31003 | match |
| Precision | Constant | -0.00299 | -0.0029893 | match |
| Precision | Constant SE | 0.00673 | 0.0067321 | match |
| Precision | N | 861 | 861 | match |

### Panel B: Between- and within-study variation (FE column only)

| Cell | Printed | Produced | Verdict |
|---|---|---|---|
| Standard error (coef) | 0.189 | 0.18904 | match |
| SE | 0.573 | 0.57321 | match |
| Constant | -0.0225 | -0.022477 | match |
| Constant SE | 0.0152 | 0.0152389 | match |
| N | 861 | 861 | match |

### Panel C: WAAP row only

| Cell | Printed | Produced | Verdict |
|---|---|---|---|
| Effect beyond bias (coef) | 0.00756 | 0.0075581 | match |
| SE | 0.0130 | 0.0135726 | **MISS — typo in the paper (see below)** |
| Observations | 861 | 861 | match |

## The WAAP row, settled

The WAAP procedure keeps the estimates with adequate power, `se_pcc < waapbound` where
`waapbound = |precision²-weighted mean of pcc_w| / 2.8`. On the published data the bound is
0.0043907 and exactly four estimates clear it, all four from idstudy 19; the next-nearest
estimate sits at `se_pcc` 0.004873, so the cut is not a rounding-boundary accident. Those four
share one winsorized standard error, so `precision_w` is a single constant (204.8305) across
the WAAP subsample and the regression reduces to `b = mean(tstat)/204.8305`.

**The regression itself is now confirmed three ways, not inferred.**

1. **Stata 15.1, re-run here** on the author's own `students.xlsx` with the author's own
   commands (probe: `repl/stata_work_students/waap.do`) prints

   ```
   reg tstat precision_w if se_pcc < waapbound, noconstant
        Number of obs =  4        Root MSE = 5.5602
    precision_w |   .0075581   .0135726     0.56   0.616
   b =  0.007558107010686   se =  0.013572586893858   e(N) = 4   df_r = 3
   ```

2. **The author's own log of the published run** — found on the owner's disk at
   `Tomas_Zuzka_sdilene\2_papers\paper_students\_revision\calculation\calculation_final_version\students.log`
   (and again in `..\_revision\calculation\students.log`) — records the identical block, twice
   (the do-file runs WAAP at lines 74-76 and again at 406-408):

   ```
      Source |       SS       df       MS      Number of obs =         4
    Residual |  92.7460989      3  30.9153663
    precision_w |   .0075581   .0135726     0.56   0.616   -.0356359   .0507521
   ```

   So the number the author's machine produced for the number the paper prints is 0.0135726,
   not 0.0130.

3. **The paper prints the correct value elsewhere for the same regression.** The appendix table
   on the expanded 872-estimate / 73-study sample (`students.pdf` p. 48, `appendix.pdf` p. 12)
   reports WAAP as `0.00756` with `(0.0136)`. The WAAP coefficient is identical in the two
   tables because the four adequately powered estimates are the same in both samples — so the
   standard error must be identical too, and 0.0136 is what 0.0135726 rounds to. In the LaTeX
   source (`__revision2\latex\students.tex`) the two rows sit in one file: line 331 reads
   `& (0.0130) & (0.0265) & (0.00270) & (0.005) & (0.0178)` and line 1049 reads
   `& (0.0136) & (0.0266) & (0.00268) & (0.005) & (0.0169)`. Every other Panel C standard error
   moves a little between the two samples; only WAAP's jumps from 0.0136 to 0.0130 while its
   coefficient does not move at all.

4. `0.0130` is also, to the digit, the **Selection-model coefficient printed one column to the
   right in the same row** of Table 2 (`-0.0130***`).

**No variant of the regression reaches 0.0130.** Because `precision_w` is constant on the
subsample, `b/SE` is fixed by the four `tstat` values alone (7.54, -0.06, 4.0811387,
-5.3686162) and is 0.557 for any scale of x; the printed pair implies 0.581. Stata's `df = N-1
= 3` gives 0.013573; dividing by `n` gives 0.011754; HC1 and HC2 collapse to the classical
standard error when x is constant; HC3 gives 0.015674. Clustering is impossible — all four rows
are one study. Substituting `tstat_w` or unwinsorized `precision` moves the coefficient away
from 0.00756 (to 0.0040 and 0.0021) as well as the standard error. Filtering on `se_pcc_w`
instead of `se_pcc` leaves no observations at all (Stata errors with `r(2000)`), so that is not
what was run either.

The conclusion is that **Table 2's WAAP standard error is a typographical error in the
published paper**, most likely made when the Panel C row was retyped for the 861-estimate
sample. `targets.json` transcribes the paper correctly at 0.0130; the paper's own code, the
author's own log, and the paper's own appendix all say 0.0136. This cell is left missing rather
than forced.

**The Observations cell, by contrast, was our error and is fixed.** Panel C's Observations row
prints 861 under all five columns, and the table note says the analysis covers "the whole
sample of 861 estimates". That row reports the sample the five techniques are *applied to*, not
each technique's estimation N — the kinked model's own regression does run on 861 (the log's EK
block shows `Number of obs = 861`), and Table 3 Block 1 prints 436 in the WAAP column's
Observations cell while the WAAP estimate itself is `⋅ (⋅)` because, as the text says, WAAP
there "does not identify any study that would have sufficient power". An Observations figure
printed under an estimator that ran on zero studies cannot be that estimator's `e(N)`. WAAP
consumes all 861 estimates — the power bound is a weighted mean over the whole sample — and then
averages the adequately powered subset. `run.R` previously reported that subset's size (4) in
this cell, which is a quantity the paper never prints anywhere. It now reports `nrow(d)` = 861,
the analysis sample, and prints the size of the adequately powered subset to the console as a
diagnostic:

```
WAAP: weighted mean pcc_w = -0.012294, bound = 0.004391, adequately powered subset = 4 obs
```

## Data check

The site's `students.xlsx` (sheet "data" — the exact file line 8 of the do-file imports) and the
published `data/v1/students/students.csv` are the same data: identical shape (892 x 59),
identical column names, and `pcc`, `se_pcc`, `tstat` agreeing to 1e-15 with the same missing
pattern. `tstat` equals `pcc/se_pcc` to machine precision on all 861 retained rows. Nothing the
do-file needs is unpublished, so this package is not blocked on data.

## Stata commands emulated (per stata_compat.R's own log)

```
drop if <cond>                          -> missing treated as +Inf, as Stata does
winsor <var>, p(0.01)                   -> order statistics at floor(p*N), SSC winsor.ado
ivreg2 y x, cluster(g)   [no `small`]   -> feols, ssc(adj=F,K.adj=F,cluster.adj=F); z inference
xtreg y x, fe vce(cluster g)            -> feols, fixef.rm='none', fixest default ssc
xtreg, fe reported _cons                -> augmented within regression, fixest default ssc
keep if <cond>                          -> missing treated as +Inf, as Stata does
regress y x, vce(cluster g) / robust    -> feols, fixest DEFAULT ssc (Stata regress is small-sample)
```

## Verdict

**PARTIAL, 27 of 28.** All of Panel A, all of the Panel B FE column, and both the WAAP
coefficient and the WAAP Observations cell reproduce exactly. The one miss is Table 2's WAAP
standard error. It is not a defect in this package: Stata 15.1 re-run here on the author's data
with the author's commands returns 0.0135726, the author's own log of the published run
returns 0.0135726, and the paper's appendix prints 0.0136 for the identical regression. Table
2's printed 0.0130 is a typo, and it happens to equal the Selection-model coefficient in the
neighbouring column. `targets.json` was not touched; the cell stays missing.

Re-verified 2026-09-08: `Rscript run.R` re-run from clean, `verify_packages.check("students")`
reports `matched 27 / total 28`, `wrong 1`, `reran true`, with `stata_compat.R` hash verified
and untouched.
