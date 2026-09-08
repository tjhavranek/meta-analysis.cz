# Replication package: Habit formation in consumption: A meta-analysis

Havranek, T., Rusnak, M. & Sokolova, A. (2017), *European Economic Review* 95, 142-167.
https://doi.org/10.1016/j.euroecorev.2017.03.009

## Table reproduced

**Table 1 of the paper's own Web Appendix** ("Web Appendix to 'Habit Formation in Consumption:
A Meta-Analysis'", `habits/appendix.pdf`, published on meta-analysis.cz/habits): *"Funnel
asymmetry tests indicate no publication bias."* Four of its five columns -- Baseline, Study,
Precision, Median -- are targeted here; the Instrument column is out of scope (see "Scope
decision" below).

This table, not the descriptive Table 1 in the print journal article, was chosen as the
headline result because the printed article (`habits.pdf` / `habits2.pdf`) explicitly defers
its formal publication-bias tests to this web appendix (Section A.4: *"In the online appendix
at meta-analysis.cz/habits we test publication bias formally using several methods"*), and
because the author's own do-file (`habit.zip:habit.do`, lines 190-209) builds exactly this
regression table -- the only part of the author code that maps directly onto the
`stata_compat.R` wrappers (`st_xtreg_fe`, `st_ivreg2`, `st_winsor`). The other candidate
tables (Table 1/2 in the print paper: plain summary statistics; Table 4/5: BMA and FMA) either
need no estimator at all (unweighted/weighted means and percentiles) or need the `bms`
package and `lm()` directly, which the brief's wrapper list and its "never call ... lm ...
directly" rule do not cover.

Provenance: **author_code** (`habit.zip:habit.do`, lines 1-202, reproduced through
`stata_compat.R`).

## Scope decision: the Instrument column is not attempted

Do-file line 195, `eststo: xtivreg habit (se=invsqrtn) if dsge==0, fe` (no cluster), is a
**panel-IV fixed-effects regression** (Stata's `xtivreg`). `stata_compat.R` has no wrapper for
it: `st_ivreg2` is a cross-sectional/clustered IV estimator with no panel-FE absorption
argument, and `st_xtreg_fe` takes no instrument. Per the brief ("a needed Stata command with
no wrapper: STOP, report unsupported_command"), this column is left out of `targets.json`
rather than approximated with an unsanctioned estimator call.

`unsupported_command`: `xtivreg` (panel-IV with fixed effects) -- no wrapper in
`stata_compat.R`; affects only the Instrument column of Table 1.

## Data and code provenance

- Data: `web_meta/site/data/v1/habits/habits.csv` (606 rows, the file the site publishes;
  606 - 9 missing-`se` rows = 597, matching the paper's stated "597 estimates").
- Author code: `web_meta/site/habits/habit.zip` (`habit.do`, `BMA.R`, `FMA.R`) and
  `web_meta/site/habits/habit.pdf` / `habits2.pdf` / `appendix.pdf`.
- `run.R` sources only `stata_compat.R` and reads only the CSV above.

## Variable construction (habit.do -> run.R)

| Step | do-file | run.R |
|---|---|---|
| Drop missing SE | `drop if missing(se)` (line 13) | `st_drop_if(d, is.na(d$se))` |
| Study median habit | `bysort idstudy: egen habit_med = median(habit)` (line 23) | `ave(d$habit, d$idstudy, median)` |
| No. of estimates/study | `bysort idstudy: egen no_est = max(id)` (line 42) | `ave(d$id, d$idstudy, max)` -- uses the *id values*, not a recount, matching Stata (2 of 81 studies have a gap between `max(id)` and the row count because a mid-sequence row had missing `se` and was already dropped) |
| Winsorize SE | `winsor se, gen(se_win) p(0.05)` (line 154), SSC `winsor.ado` | `st_winsor(d$se, p = 0.05)` (order-statistics convention, matches) |
| Precision / inv-variance | `gen prec = 1/se`, `gen invvar = 1/(se*se)` (lines 160, 162) | same, post-winsorizing |
| Study-level medians | `bysort idstudy: egen se_med = median(se)`, `egen invvar_med = median(invvar)` (lines 164, 166) | `ave(..., median)`, post-winsorizing |
| Non-DSGE sample | `if dsge==0` | `st_keep_if(d, d$dsge == 0)` |

Confirmed against the data before coding: `dsge` is constant within every `idstudy` (0
studies with mixed values), so filtering by `id==1 & dsge==0` cleanly selects one row for each
of the 38 non-DSGE studies -- exactly the printed N for the Median column.

## Target-by-target results

Printed values rounded to the digits shown in the appendix table; produced values rounded to
the same digit count for the verdict.

| Label | Printed | Produced | Verdict |
|---|---|---|---|
| Baseline SE(pub.bias) coef | -0.222 | -0.2221451 -> -0.222 | MATCH |
| Baseline SE(pub.bias) se | 0.211 | 0.2114154 -> 0.211 | MATCH |
| Baseline Constant coef | 0.397 | 0.3967966 -> 0.397 | MATCH |
| Baseline Constant se | 0.0397 | 0.0397398 -> 0.0397 | MATCH |
| Baseline N | 462 | 462 | MATCH |
| Study SE(pub.bias) coef | -0.214 | -0.2144492 -> -0.214 | MATCH |
| Study SE(pub.bias) se | 0.165 | 0.1652944 -> 0.165 | MATCH |
| Study Constant coef | 0.444 | 0.4439610 -> 0.444 | MATCH |
| Study Constant se | 0.0405 | 0.0405242 -> 0.0405 | MATCH |
| Study N | 462 | 462 | MATCH |
| Precision SE(pub.bias) coef | 0.174 | 0.1740148 -> 0.174 | MATCH |
| Precision SE(pub.bias) se | 0.0315 | 0.0315496 -> 0.0315 | MATCH |
| Precision Constant coef | 0.000679 | 0.0006793 -> 0.000679 | MATCH |
| Precision Constant se | 0.0000417 | 0.0000417 -> 0.0000417 | MATCH |
| Precision N | 462 | 462 | MATCH |
| Median SE(pub.bias) coef | 0.276 | 0.2757555 -> 0.276 | MATCH |
| Median SE(pub.bias) se | 0.207 | 0.2074803 -> 0.207 | MATCH |
| Median Constant coef | 0.345 | 0.3453086 -> 0.345 | MATCH |
| Median Constant se | 0.0858 | 0.0858155 -> 0.0858 | MATCH |
| Median N | 38 | 38 | MATCH |

**20 of 20 targets match**, re-run from clean through `verify_packages.py` on 2026-09-08.

## The Median standard errors, and the wrapper fix behind them

The last two cells to fall were the Median column's two standard errors, and they are worth
recording in full, because fixing them meant changing the shared convention layer that every
package on the site depends on.

Do-file line 202 is `ivreg2 habit_med se_med if id==1 & dsge==0`: no cluster, no weights, no
`small` -- a plain cross-sectional regression on 38 study-level medians, and the only call in
this package that reaches `st_ivreg2()`'s homoskedastic path. Earlier versions of this package
produced 0.210265 and 0.086967 against printed 0.207 and 0.0858, about 1.3% high, and reported
them as an unfixable convention gap. `st_ivreg2()` applies `.SSC_LARGE`
(`ssc(adj = FALSE, K.adj = FALSE, cluster.adj = FALSE)`), a profile calibrated against a
*clustered* table, and with no cluster in the model that setting makes fixest divide the
residual sum of squares by N-1 = 37. A sweep of every `ssc()` combination fixest exposes
showed the homoskedastic case can only land on N-K = 36 or N-1 = 37; plain N is not reachable
through `ssc()` at all. That earlier conclusion was half right. The wrapper could not express
the convention, but the reason mattered: `adj = FALSE` is not "no denominator correction", it
is fixest's own floor of N-1, and that floor is not what `ivreg2` does.

Stata settled it. `probe1.do` (in `repl/stata_work_habits/`) runs the authors' own command on
the same 38 rows in Stata 15.1:

```
ivreg2 habit_med se_med           se_med  .2757555 (.2074803)   _cons  .3453086 (.0858155)
ivreg2 habit_med se_med, small    se_med  .2757555 (.2131657)   _cons  .3453086 (.0881670)
```

The first line is what the appendix prints, and its Root MSE (.4266) is sqrt(RSS/N), not
sqrt(RSS/(N-1)). So `ivreg2` without `small` divides by plain N, and the wrapper -- not the
paper, and not this package's sample -- was wrong. The fix in `stata_compat.R` is one branch
in `st_ivreg2()`: when there is no cluster and no fixed effect, the variance fixest returns is
rescaled by (N-1)/N. That is not a constant tuned to one cell; it is the exact ratio between
two stated conventions, and it reproduces Stata to seven digits on all three homoskedastic
profiles `st_ivreg2()` can produce (`probe2.do`): OLS 0.2074803 against 0.2074803, 2SLS
5.5039505 against 5.5039500, aweighted OLS 0.5577889 against 0.5577889. The clustered path
that `.SSC_LARGE` was built for is untouched, as is the heteroskedastic path, where fixest
with `adj = FALSE` already gives `ivreg2`'s HC0 (0.1205108 on both sides).

Because that file is shared, the change was gated before and after:

- `test_compat.R` passes, and now carries this column as a second target table, so the
  no-cluster denominator is checked against published cells on every future change to
  `stata_compat.R`. The clustered class-size table it used to check alone is blind to it.
- The other packages whose `run.R` calls `st_ivreg2()` without a cluster -- `armington`,
  `cbequity`, `forward` -- were re-verified before and after: 32/39 -> 32/39, 43/44 -> 43/44,
  11/20 -> 11/20. Not one target moved. Their non-clustered calls either already report those
  SEs as unsupported (`armington`'s short-run columns need `ivreg2, robust`, a different
  path), recompute a heteroskedastic vcov themselves (`cbequity`), or carry SE targets marked
  stochastic (`forward`).
- `compat.sha256` was updated to the new file, which is what the verifier's hash lock requires
  after a sanctioned change.

## Fix applied earlier: Study/Precision Constant

The first diagnosis of this package left these four cells `NA`, reasoning that
`st_xtreg_fe_cons()` takes no `weights` argument and the Study/Precision columns are
`pweight`-ed. That was too quick to give up. `st_xtreg_fe_cons()`'s own documented method
(its source comment) is: Stata's `xtreg, fe` reported `_cons` equals the grand mean of y minus
the within slope times the grand mean of x, obtained by an "augmented within regression" --
demean each variable by its group mean, add back the grand mean, then run a plain OLS of the
transformed y on the transformed x. That generalizes to the weighted case with plain
arithmetic: use **weighted** group means and a **weighted** grand mean (weights `inv_no_est`
or `invvar_med`, exactly as the do-file's `[pweight=...]` specifies), then hand the demeaned
variables to `st_regress()`, a wrapper that already accepts weights and uses fixest's default
ssc, the same convention `st_xtreg_fe()` documents for `xtreg, fe`. No `feols()`/`lm()` call
was made outside the sanctioned wrappers, and the helper (`st_xtreg_fe_cons_weighted()`) lives
in `run.R`, not in `stata_compat.R`.

This was verified rather than assumed: before wiring the helper in, a throwaway check
confirmed that the slope from the augmented weighted regression reproduces `st_xtreg_fe()`'s
own slope on `se` to machine precision for both columns, so the demeaning is right before the
intercept is read off it. Study Constant 0.443961 -> 0.444, SE 0.040524 -> 0.0405; Precision
Constant 0.00067926 -> 0.000679, SE 0.0000417 -> 0.0000417.

## What a reader should still be careful about

- The **Instrument column is not reproduced** (see the scope decision above). Four of the five
  columns are.
- The point estimates never depended on any of this. They matched from the first run, which is
  what confirmed that the sample, the `id==1 & dsge==0` filter, the winsorising and the
  regressors were right while the two SEs were still off.
- `dof_convention_check.R` in this folder is a diagnostic, not part of the run. It is kept as
  an audit trail; its header records that its "cannot be reproduced" conclusion was superseded
  by the Stata evidence above.

## Verdict

**FULL.** All 20 target cells of the four in-scope columns match the printed appendix table
after a clean re-run. The last two required correcting `st_ivreg2()`'s homoskedastic variance
denominator in the shared `stata_compat.R`, on direct evidence from Stata 15.1 running the
authors' own command, with the compat gate and the three other non-clustered `st_ivreg2`
packages re-checked around the change and nothing else moved.
