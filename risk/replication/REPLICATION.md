# Replication package: "Relative Risk Aversion: A Meta-Analysis"

Elminejad, Havranek & Irsova, *Journal of Economic Surveys* 39(5), 2315-2333 (2025),
doi 10.1111/joes.12689.

Run with:

```
Rscript run.R
```

Reads only `data/v1/risk/risk.csv` as published by meta-analysis.cz. Writes `results.json`
and prints every target to stdout. No manual steps.

## Scope

Reproduces **Table 2**, "Linear funnel asymmetry tests" -- the paper's headline
publication-bias table. Three panels (A: All studies, B: Economics, C: Finance) x four columns
(WLS, FE, BE, Study), i.e. eight coefficient/SE pairs per panel plus Observations and Studies:
**54 deterministic and count numbers**. The 24 wild-bootstrap confidence-interval endpoints
printed in square brackets are marked stochastic in `targets.json` and are not computed; see
"What is not computed" below.

**Result: 47 of 54 reproduce exactly. All seven misses are in Panel C, and the evidence says
the package is right and the paper's Panel C is stale.** Details below.

## Provenance

Data: `site/data/v1/risk/risk.csv`, 1021 rows x 61 columns. This was checked column by column
against the author's own working file `Papers/43_Risk_aversion/Code/rra_data.dta` (the dataset
`rra.do` saves after `drop if estimated==0`): same 1021 rows, same 61 columns, every numeric
column equal to within 1e-10, every string column identical. There is no data question here.

Code: `risk.zip:risk/rra.do`. The author's longer working copy (`Code/rra.do`, 1754 lines
against the site zip's 972) contains the same Table 2 block at lines 360-431 and adds nothing
that Table 2 uses -- the extra length is graphs, BMA export and robustness work. The block is:

```stata
replace se=0.0001 if se==0
gen invperstudy = 1/perstudy
winsor2 rra se, suffix(_win10) cuts(10 90) label
gen tstat_win10 = rra_win10/se_win10
gen prec_win10  = 1/se_win10
xtset idstudy

ivreg2 tstat_win10 prec_win10, cluster(idstudy)                            /* WLS   */
xtreg  tstat_win10 prec_win10, fe cluster(idstudy)                         /* FE    */
xtreg  tstat_win10 prec_win10, be                                          /* BE    */
ivreg2 tstat_win10 prec_win10 [pweight=invperstudy], cluster(idstudy)      /* Study */
```

repeated with `if econjournal==1` (Panel B) and `if econjournal==0` (Panel C).

Two points the code settles:

- **Winsorising happens once, on the full 1021-row sample, before any panel split.** Panels B
  and C reuse the global `rra_win10`/`se_win10`. Re-winsorising inside the subsample was tested
  in Stata and is not what the paper did: it gives a finance WLS intercept of 2.628, nowhere
  near the printed 1.859 or the reproduced 1.853.
- **`econjournal` and `finjournal` are exact complements** in this file: 590 rows are (1,0) and
  431 are (0,1); no row is (1,1) or (0,0). So `if econjournal==0` and `if finjournal==1` are the
  same 431 rows, and the FINDS lead about the Finance subset being 431 rows / 34 studies "either
  way" is confirmed rather than being a lead to chase.

## The Stata oracle

Stata 15.1 was run on the author's own `risk.dta` with the commands above
(`repl/stata_work_risk/t2.do`). **R and Stata agree to every digit Stata prints, in all twelve
regressions**, including the three Panel C cells that miss the paper:

| Panel C cell | this package | Stata 15.1 | paper |
|---|---|---|---|
| WLS, Standard error (`_cons`) | 1.8532973 | 1.853297 | **1.859** |
| FE, Standard error (`_cons`)  | 3.4711425 | 3.471143 | **3.476** |
| BE, Standard error (`_cons`)  | 0.8044287 | .8044289 | **0.817** |
| BE, Standard error SE         | 3.0597874 | 3.059787 | **3.061** |
| BE, Constant (coef on prec)   | 3.2235922 | 3.223592 | **3.223** |
| BE, Constant SE               | 0.4223837 | .4223837 | **0.423** |
| WLS, Constant (coef on prec)  | 2.3906826 | 2.390683 | **2.390** |

So the seven misses are not an R-vs-Stata artefact, not a wrapper convention, and not a sample
or weighting choice. Running the author's code on the author's data does not produce the
author's Panel C.

## A labelling subtlety worth flagging

The fitted equation is `tstat_win = a + b * prec_win`, which is the inverse-variance-weighted
regression of `rra_win` on `se_win` rewritten in t-space: dividing
`rra_win = beta0 + beta1*se_win + e` (weights `1/se_win^2`) through by `se_win` gives

```
tstat_win = beta0*prec_win + beta1
```

So the **coefficient on `prec_win`** is `beta0`, the mean effect, which Table 2 prints in the
row **"Constant (mean corrected RRA)"**; and the regression's own **constant** is `beta1`, the
slope on the standard error, which Table 2 prints in the row **"Standard error (publication
bias)"**. `targets.json` names its labels after the printed rows, not the fitted terms, so
`*_prec_*` holds the intercept and `*_cons_*` holds the slope on precision. That looks crossed
and is deliberate. It is not a guess: it is what Stata prints, and it is the only mapping under
which all eight Panel A and B intercepts match the printed table to the last digit.

## What reproduces

**Panel A (all studies) and Panel B (economics): 40 of 40, exactly.** Every coefficient, every
standard error, both counts. Several match to more digits than the paper prints (1.865201 for a
printed 1.865, 4.118888 for 4.119, 3.603604 for 3.604), which is what a genuine reproduction of
a single run looks like.

**Panel C: 7 of 14.** Observations (431), Studies (34), the whole **Study** column (2.168,
1.654, 2.888, 0.732 -- all four exact), the FE slope and its SE (1.107, 0.134), and the WLS and
FE standard errors (0.449, 0.169) all reproduce.

## Panel C: why seven numbers miss

The seven misses are the WLS/FE/BE intercepts and the four BE cells. They are small -- 1.853 vs
1.859, 3.471 vs 3.476, 0.804 vs 0.817, and four last-digit disagreements -- but they are real
under the round-to-three-digits rule, and no honest code path closes them.

What was ruled out, each by running it:

- **Wrong subsample.** 431 rows / 34 studies is matched exactly, and `econjournal==0` and
  `finjournal==1` are the same rows.
- **Wrong data vintage.** The published CSV equals the author's `rra_data.dta` to 1e-10. The
  larger `RRA_Studies.xlsx` filtered to `estimated==1` returns these same 1021 rows.
- **Subsample winsorising.** Tested in Stata, both as a `keep if` before `winsor2` and as
  `winsor2 ..., by(econjournal)`: finance WLS becomes 2.628 (0.253), FE 2.401, BE 4.474. Far
  worse, not better.
- **R-vs-Stata estimator conventions.** Stata itself returns our numbers.
- **A single changed or dropped observation.** The arithmetic is inconsistent with any such
  story. A level shift in one study that moves the FE intercept by the observed +0.0049 must
  move the BE and Study intercepts by the same amount (both weight each study 1/34); the paper's
  BE intercept moves by +0.0126 while its Study intercept matches ours to four digits. And a
  perturbation large enough to shift Panel C's intercept by 0.005 would shift Panel A's by
  ~0.002, which would break Panel A's exact match. No single data change fits all three panels.

What the archive shows instead. The paper's Table 2 was assembled by hand in LaTeX (the do-file
writes `wPETfin90.tex` via `esttab`, but the manuscript table is hand-typed), and the draft
history dates the Panel C cells:

- The **February 2022** draft (`x_old_stuff/old2/RRA_February 2022.pdf`, Table 4) has a
  six-column table (OLS/FE/WFE/BE/IV/Study) whose Panel A and Panel B are completely different
  from the final ones (Panel A "Standard error" is 1.358 (0.758), not 1.865 (0.362)). Its Panel
  C already reads **1.859 (0.449), 3.476 (0.169), 0.817 (3.061)**, with a Study column of
  **2.180 (1.656)** and constant **2.887**.
- The **March 2022** draft (`x_old_stuff/Ali_new/RRA March 14.pdf`, Table 5) is the four-column
  table of the published paper. Panels A and B have been recomputed to the values we reproduce
  exactly. Panel C's Study column has been refreshed too: 2.180 -> **2.168**, 2.887 -> **2.888**,
  1.656 -> **1.654** -- the values we reproduce. Panel C's OLS, FE and BE cells are **byte for
  byte the February numbers**.
- Every later version -- `Latex/`, `_revision/`, `__revision2/`, `JFE/`, `AER_no_stars/`,
  `Latex_Nature_Science_PNAS/` -- carries that same Panel C unchanged, and so does the published
  JOES article.

So Panel C's WLS, FE and BE columns were carried over from the earlier run when the table was
rebuilt in March 2022, while everything around them (both other panels, and Panel C's own Study
column) was recomputed. The size of the Study column's own February-to-March correction
(-0.012) is the same order as the three intercept gaps we cannot close (-0.006, -0.005, -0.013),
which is what one expects if all four columns needed the same refresh and only one got it.

This is a defect in the paper, not in the package. The package reports what the author's code
produces on the author's data, and leaves the seven cells missing.

## What is not computed

The 24 square-bracket confidence intervals in the WLS and Study columns come from
`boottest prec_win10, nograph` and `boottest _cons, nograph` -- Roodman et al.'s wild cluster
bootstrap. No seed is set anywhere in `rra.do`, and `stata_compat.R` has no `boottest` wrapper.
Substituting some other bootstrap would emit numbers that are neither Stata's nor stable across
runs, so `run.R` writes `null` for all 24. `targets.json` marks them `stochastic`, so they are
outside the scored set.

## Wrappers used

`st_winsor2`, `st_ivreg2`, `st_xtreg_fe`, `st_xtreg_fe_cons`, `st_regress`, `st_coefs`, from the
frozen `stata_compat.R`. No estimator is called directly and `stata_compat.R` was not modified.

Three conventions carry weight here and each was confirmed against Stata output:

- `st_winsor2` uses Stata's `_pctile` quantile definition (type 2), not R's default type 7. With
  type 7 the cut points move and Panel A no longer matches.
- `ivreg2` without `small` reports z-statistics and no small-sample correction, so
  `st_ivreg2` is used for the WLS and Study columns; `xtreg, fe vce(cluster)` is small-sample and
  t-based, so `st_xtreg_fe` is used for FE.
- `xtreg, be` with no `wls` option is unweighted OLS on the study-level means, one row per
  `idstudy`, with t inference on N_g - 2 degrees of freedom and no clustering (there is one
  observation per cluster). `run.R` aggregates and calls `st_regress` with `cluster = NULL`,
  which matches Stata's BE output exactly in all three panels.
