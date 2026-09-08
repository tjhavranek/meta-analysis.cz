# Replication: Havranek & Zeynalova, "Firm Size and Stock Returns: A Quantitative Survey" (JOES 2019)

## Result

**47 of 47 targets reproduce**, at the precision the paper prints them.

That is all six columns of **Table 4, "Estimating the Mediating Factors of Publication
Bias"** -- three OLS and three fixed-effects specifications, every coefficient, every
standard error, every observation count (46 cells) -- plus the one number the text on
p.28 gives as "the adjusted value of size effect from specification (1) in Table 3."

Table 4 is the headline table here because it is the table for which the author's own
`size.do` contains the exact estimating commands, so the printed numbers can be checked
against code rather than against methods prose.

## Data

`run.R` reads the site's published CSV, `data/v1/size/size.csv`. Nothing else.

An earlier version of this package read the author's `.dta` instead, on the stated
grounds that the CSV "lacks the `se`, `impact` and `pubyear` columns Table 4 needs."
That was wrong, and the claim is retracted here. The CSV is a faithful export of the
`size.dta` that `size.do` itself opens: same 1746 rows, same 407 columns, all three of
those variables present, `geo` identical string for string, and the same missingness
(83 missing `impact`, 4 missing `obs`). The only difference is print precision -- the
CSV's `se` column carries fewer digits than the `.dta`'s float, by at most 1.7e-07,
which is nowhere near the third significant digit every Table 4 cell is printed to.
Both files were run side by side and all 47 targets reproduce identically from either.

## Author code

The full `size.do` (published at `site/size/size.do`) holds the estimating commands at
lines 176-224:

```
176  ivreg2 size se, cluster (idstudy geo)                       [Table 3, spec (1), "OLS"]
190  ivreg2 size se se_impact, cluster (idstudy geo)             [Table 4, col 1]
191  ivreg2 size se se_pubyear, cluster (idstudy geo)            [Table 4, col 2]
192  ivreg2 size se se_impact se_pubyear, cluster (idstudy geo)  [Table 4, col 3]
196  xtreg size se se_impact, fe vce(cluster idstudy)            [Table 4, col 4]
197  xtreg size se se_pubyear, fe vce(cluster idstudy)           [Table 4, col 5]
198  xtreg size se se_impact se_pubyear, fe vce(cluster idstudy) [Table 4, col 6]
```

## Wrappers used

`st_ivreg2` (the OLS columns; no `small`, so large-sample/z variance), `st_xtreg_fe`
(the FE columns), `st_winsor2` (`winsor2 ..., cuts(2.5 97.5)`), `st_regress` and
`st_coefs`. No `feols`/`lm`/`rma`/`lmer` call is made directly anywhere in `run.R`.

## The two-way cluster variance -- what closed the last cell

`ivreg2 ..., cluster(idstudy geo)` builds its variance as the Cameron-Gelbach-Miller sum

```
V(idstudy, geo) = V(idstudy) + V(geo) - V(idstudy AND geo)
```

and reports that sum **unadjusted**, even when it is not positive semi-definite. When it
is not, ivreg2 prints "estimated covariance matrix of moment conditions not of full
rank" and carries on with the raw sum. Column (3) is the one regression in this table
that trips that warning: its meat matrix has a negative eigenvalue (-0.203, against a
leading eigenvalue of 1.1e9). Columns (1) and (2) do not.

Handing `cluster = ~idstudy + geo` to `st_ivreg2()` does not reproduce ivreg2 in that
case, because fixest -- which `st_ivreg2` wraps -- forces its multiway VCOV to be
positive semi-definite before returning it. Where the raw sum is already PSD the
correction does nothing and the two agree bit for bit, which is why columns (1) and (2)
matched all along and only one cell in column (3) missed. Measured against Stata 15.1
(`stata_work_size/probe1.do`, `probe2.do`), on that cell:

| route | SE | printed as |
|---|---|---|
| `ivreg2 size se se_impact se_pubyear, cluster(idstudy geo)` | 4.6045557593538e-05 | 0.0000460 |
| `st_ivreg2(cluster = ~idstudy + geo)` | 4.6068549659009e-05 | 0.0000461 |
| `V(idstudy) + V(geo) - V(idstudy^geo)` | 4.6045559415019e-05 | 0.0000460 |

So `run.R` assembles the two-way variance from three `st_ivreg2()` fits that differ only
in their cluster variable, which is the estimator ivreg2 actually runs. Every one-way
piece was already exact -- fixest and Stata agree on each of `V(idstudy)`, `V(geo)` and
`V(idstudy^geo)` to fifteen digits, and only their combination was ever in dispute. The
point estimates and N do not depend on the clustering and are read off the first fit.

Nothing in `stata_compat.R` was changed. The frozen wrapper is right about what it
documents (one-way ivreg2 clustering); the multiway composition simply is not part of
what it promises, and is spelled out in `run.R` at the point of use.

The previous pass diagnosed this cell as "a minute difference between ivreg2's and
fixest's implementations of the two-way cluster-robust variance." That was the right
neighbourhood but too vague to act on. The specific cause is fixest's PSD correction,
and it only ever bites on a column whose raw CGM sum is indefinite.

## A faithfulness detail preserved from the .do file

`se_impact` and `se_pubyear` are built from the **original, pre-winsorized** `se` (lines
151/153), and `winsor2` (line 162) is applied afterwards to `size`, `se`, `prec`,
`tstat`, `invsqrtobs` only -- the interactions are never rebuilt from the winsorized
`se`. The Table 4 regressions therefore mix a winsorized `se` as a stand-alone regressor
with interaction terms built off the un-winsorized `se`. `run.R` reproduces that order
of operations rather than tidying it into one consistent `se`.

## FE constants

`xtreg, fe` reports a constant that `feols(y ~ x | panel)` does not. `stata_compat.R`
supplies `st_xtreg_fe_cons` for exactly one regressor (`_cons = ybar - beta*xbar`, via an
augmented within regression). Every FE column here has two or three regressors, so that
wrapper cannot be called as-is, and it may not be edited.

`run.R` generalizes the wrapper's own documented recipe: demean each `y` and `x` by the
panel and add back its grand mean, then pass the result through the sanctioned
`st_regress()` -- clustering on the same panel variable as xtreg's own
`vce(cluster idstudy)`. The transform is a pure per-panel location shift, so it cannot
move a slope; `run.R` asserts this, checking that the slopes it recovers match the
`st_xtreg_fe` slopes to 1e-6. The regression's intercept and its clustered SE are then
Stata's `_cons` and its SE. All twelve FE-constant cells match.

## The Table 3 cell

The target -0.0259 is not the main Table 3 column (1) constant, which is -0.0315
(SE 0.00814) on the full N=1746 sample. -0.0259 comes from the size-risk-premium
discussion on p.28, after the paper restricts the sample:

> "we repeat these computations excluding observations of the size effect with the
> returns being non-monthly, focusing on U.S. stocks only. This methodological
> modification reduces the number of sampled coefficients to 946 ... The adjusted value
> of size effect from specification (1) in Table 3 is -0.0259."

That restriction is the `*FOR SIZE RISK PREMIUM*` block of `size.do`: `keep if monthly
== 1`, `keep if geo == "US"`, then `ivreg2 size se, cluster (idstudy)` -- idstudy alone,
not idstudy geo. `run.R` applies it after winsorizing and gets N=946, matching the
paper's stated count, and a constant of -0.02595 -> **-0.0259**.

## Target-by-target results

All 47 deterministic. Every row matches.

| Target | Printed | Produced (rounded) | Verdict |
|---|---|---|---|
| T4 C1 SE coef | -0.704 | -0.704 | match |
| T4 C1 SE se | 0.175 | 0.175 | match |
| T4 C1 SE*Impact coef | -0.0686 | -0.0686 | match |
| T4 C1 SE*Impact se | 0.0603 | 0.0603 | match |
| T4 C1 Constant coef | -0.0351 | -0.0351 | match |
| T4 C1 Constant se | 0.00771 | 0.00771 | match |
| T4 C1 N | 1663 | 1663 | match |
| T4 C2 SE coef | -1.294 | -1.294 | match |
| T4 C2 SE se | 0.156 | 0.156 | match |
| T4 C2 SE*Pub.Year coef | 0.000164 | 0.000164 | match |
| T4 C2 SE*Pub.Year se | 0.0000274 | 0.0000274 | match |
| T4 C2 Constant coef | -0.0241 | -0.0241 | match |
| T4 C2 Constant se | 0.00857 | 0.00857 | match |
| T4 C2 N | 1746 | 1746 | match |
| T4 C3 SE coef | -1.288 | -1.288 | match |
| T4 C3 SE se | 0.128 | 0.128 | match |
| T4 C3 SE*Impact coef | -0.185 | -0.185 | match |
| T4 C3 SE*Impact se | 0.0766 | 0.0766 | match |
| T4 C3 SE*Pub.Year coef | 0.000239 | 0.000239 | match |
| T4 C3 SE*Pub.Year se | 0.0000460 | 0.0000460 | match (repaired this pass) |
| T4 C3 Constant coef | -0.0247 | -0.0247 | match |
| T4 C3 Constant se | 0.00647 | 0.00647 | match |
| T4 C3 N | 1663 | 1663 | match |
| T4 C4 SE coef | -1.096 | -1.096 | match |
| T4 C4 SE se | 0.169 | 0.169 | match |
| T4 C4 SE*Impact coef | 0.247 | 0.247 | match |
| T4 C4 SE*Impact se | 0.170 | 0.170 | match |
| T4 C4 Constant coef | -0.0305 | -0.0305 | match |
| T4 C4 Constant se | 0.0153 | 0.0153 | match |
| T4 C4 N | 1663 | 1663 | match |
| T4 C5 SE coef | -1.272 | -1.272 | match |
| T4 C5 SE se | 0.178 | 0.178 | match |
| T4 C5 SE*Pub.Year coef | 0.000135 | 0.000135 | match |
| T4 C5 SE*Pub.Year se | 0.0000393 | 0.0000393 | match |
| T4 C5 Constant coef | -0.0197 | -0.0197 | match |
| T4 C5 Constant se | 0.0108 | 0.0108 | match |
| T4 C5 N | 1746 | 1746 | match |
| T4 C6 SE coef | -1.433 | -1.433 | match |
| T4 C6 SE se | 0.202 | 0.202 | match |
| T4 C6 SE*Impact coef | 0.234 | 0.234 | match |
| T4 C6 SE*Impact se | 0.159 | 0.159 | match |
| T4 C6 SE*Pub.Year coef | 0.000124 | 0.000124 | match |
| T4 C6 SE*Pub.Year se | 0.0000449 | 0.0000449 | match |
| T4 C6 Constant coef | -0.0266 | -0.0266 | match |
| T4 C6 Constant se | 0.0141 | 0.0141 | match |
| T4 C6 N | 1663 | 1663 | match |
| T3 spec (1) on the restricted subsample, Constant | -0.0259 | -0.0259 | match |

## What is not covered

Tables 1, 2, 3, 5 and 6 are not targets of this package, and neither is the Hedges
selection model (`size.do` fits it with a hand-written `ml` program that has no wrapper
here). Nothing about those is claimed either way.

## Files

- `targets.json` -- the frozen oracle, written before `run.R` and unedited since.
- `run.R` -- reads the published CSV, reproduces Table 4 and the Table 3 text cell,
  writes `results.json`.
- `results.json` -- produced values, one per target label.
- `compare.R`, `sanity.R`, `diagnose_t3.R` -- working scripts kept from earlier passes;
  not part of the pipeline.

## Verdict

**FULL.** 47 of 47.
