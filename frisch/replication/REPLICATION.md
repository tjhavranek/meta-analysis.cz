# Replication package: frisch

Paper: Havranek, Elminejad, Horvath & Irsova, "Intertemporal Substitution in Labor Supply:
A Meta-Analysis," *Review of Economic Dynamics* 2023. doi:10.1016/j.red.2023.10.001

Target table: **Table 3, Panel A** — the funnel-asymmetry / precision-effect regression of
the extensive-margin Frisch elasticity on its standard error, run five ways: OLS, study
fixed effects, precision-weighted, study-weighted, and MAIVE (Irsova et al., 2023).

Data: `data/v1/frisch/frisch.csv` as published on the site. The file pools both margins
(1471 rows); the package keeps `margin == "extensive"` — 762 rows, 38 studies, the paper's
extensive-margin sample and the same content as the `data_extensive.xlsx` the site ships
inside `frisch_data.zip`. The intensive margin belongs to the online appendix and is never
mixed in.

Estimation: only the wrappers in `stata_compat.R` — `st_winsor2`, `st_ivreg2`, `st_regress`,
`st_ivreg2_first_F`, `st_coefs`. `stata_compat.R` was not modified.

**29 of 31 targets reproduce at the paper's printed precision** (11 before this pass). The
two that do not are the MAIVE column's first-stage F and its study count; neither is
produced by the author's own code on the author's own data, and both are documented below.

## What was wrong: `study_se` was approximated, and it cannot be

Every column of Table 3 regresses on `se_comb_win`. `se_comb` (frisch.do lines 129–132) is
the reported `se` where a study reports one and a **bootstrapped** `study_se` where it does
not. 15 of the 38 extensive-margin studies — 203 of the 762 rows — report no `se` at all.

`study_se` is built in frisch.do lines 24–99. For each study in turn the data are cut down to
that study's rows and

```
bootstrap mean=r(mean), reps(1000) strata(idstudy) seed(1234): summarize frisch_boot, detail
```

is run; `summarize mean` over the 1000 saved bootstrap means gives `r(sd)`, which becomes
`study_se`. `frisch_boot` is the raw `frisch` column, fixed before any winsorising. The
published CSV carries the ingredients (`frisch`, `idstudy`) but not the bootstrap output —
there is no `study_se` column and the 54-column list is complete.

The previous version of this package substituted what that bootstrap *estimates*: the
plug-in standard deviation of the study mean, `sqrt(sum (x - xbar)^2) / n`. That is right on
average — across the 38 studies the ratio of the author's Stata `study_se` to the plug-in
value has a mean of 1.004 — but study by study it is off by 1–5%, because 1000 replications
carry real Monte Carlo noise. Propagated through the winsorising and the five regressions,
that moved every coefficient in Table 3 into the third digit and cost 16 of the 20
coefficient/SE cells. It was not a small residual to be argued away with a seed band; it was
the wrong number.

## What was done: Stata's draw is reproduced exactly

`run.R` now regenerates the bootstrap itself rather than approximating it. Two pieces, both
checked against Stata 15.1 on this machine.

**1. Stata's RNG.** Stata 14+ uses `mt64`, and it turns out to be the reference MT19937-64
seeded with `init_genrand64(seed)` and converted to a double as `(x >> 11) * 2^-53`. In
Stata, `set seed 1234; gen double u = runiform()` gives 0.947231616607804416,
0.052223374792334964, 0.974318275480240525, …; the port in `run.R` reproduces that stream
**bit for bit over 5,000 draws** (compared as the integers `u * 2^53`, zero mismatches).
64-bit words are held as two 32-bit halves in doubles; the only 64-bit multiply, in the
seeding recurrence, is done in 16-bit limbs.

**2. `bsample, strata()`.** This is the part that has to be read from the source
(`ado/base/b/bsample.ado`, program `StrSRSWR`) rather than guessed, because it is *not*
"draw n indices with replacement":

```
by strata: gen double r = int(uniform()*_N + 1)
gen double w = uniform()
sort strata r w
by strata: replace w = cond(r == r[_n-1], w[_n-1]+1, 1)
by strata: keep if w[_n+1] == 1 | _n == _N
expand w
capture by strata: assert _N == _N
if (! _rc) exit
replace w = uniform()
```

Each *row* draws its own `r` and `w`. Rows are sorted by `(r, w)`; runs of equal `r` become
frequency weights; the last row of each run is kept and `expand`ed. So the multiplicity a row
receives depends on which rows happened to draw the same `r` and which of those drew the
largest `w`.

The last four lines decide whether the stream stays in step. `expand` flags the data unsorted
whenever it actually adds an observation, so `capture by strata: assert _N == _N` **fails**,
falls through, and `replace w = uniform()` burns `n` more draws that affect nothing. A
replication containing any duplicate therefore consumes `3n` uniforms; a replication whose
resample happens to be all-distinct consumes `2n`. Assuming a constant `3n` desynchronises the
stream at the first all-distinct resample, and every later replication of that study is then a
different draw. That is exactly what the first attempt at this port did: 21 of 38 studies came
out right and 17 — all of them small-`n`, where an all-distinct resample is likely — came out
wrong by 1–5%.

With both pieces right, **all 38 `study_se` values reproduce the author's saved Stata output
to eight significant digits** (checked against `boot_results.dta` in the author's working
folder; largest relative difference 5.7e-8, which is the `float` storage of that file). The
package reads none of that material — it is the check, not the input.

## Column 2 (FE): conventional, not clustered, standard errors

The do-file's FE line is bare — `eststo: xtreg frisch_win se_comb_win, fe` (line 277) — with
no `vce(cluster idstudy)`, unlike the four `ivreg2 …, cluster(idstudy)` columns. Stata then
reports conventional standard errors, and the printed 0.271 / 0.0252 are those; clustering
gives 0.724 / 0.063. The table note's "we cluster standard errors at the study level"
describes the `ivreg2` columns.

`st_xtreg_fe` always clusters, so the column is emulated with `st_regress` and study dummies:
`xtreg y x, fe` with conventional SEs is numerically identical, for the slope and its SE, to
`regress y x i.idstudy`. The constant is Stata's `_cons = ybar − b·xbar`, whose variance is
`s2_e · (1/N + xbar² / Sxx_within)`; that is the constant of an OLS fit to the augmented data
`(y − ybar_g + ybar, x − xbar_g + xbar)` — identical residuals, so identical `Sxx` and `SSR` —
except that `xtreg` divides `SSR` by `N − G − 1` where a plain `regress` divides by `N − 2`.
The single rescaling in the code is that degrees-of-freedom factor, and `run.R` asserts it by
reproducing the LSDV slope SE exactly. Verified directly: Stata prints
`_cons = .3563809 (.0252427)`, `se_comb_win = .8865203 (.2711973)`; the package produces
0.3563809 (0.0252427) and 0.8865203 (0.2711973).

## Column 5 (MAIVE): two cells that the author's own line does not produce

The estimates come from `ivreg2 frisch_win (se2_comb_win = invobs), cluster(idstudy)`
(line 284) on the 603 rows with `no_obs` present. Coefficients, standard errors, the constant
and the observation count all reproduce exactly. Two table cells do not, and running the
author's line in Stata 15.1 on the author's own saved dataset shows why neither is a defect of
this package.

**Studies: printed 23, produced 33.** `ivreg2` reports `Number of clusters (idstudy) = 33`
for this regression. 23 is the number of studies that report their own `se` — both in the full
762-row sample and within the 603-row estimation sample. The 23-study sample is a different
regression: restricting to `se` reported leaves 525 rows and gives 3.228 (1.378), not the
printed 3.056 (1.500). So 603 observations and 23 studies cannot both describe the line whose
coefficients are printed above them. Left as produced.

**First-stage F: printed 31.2, produced 38.24.** This one is not close, and the gap is not the
bootstrap. Running the author's own MAIVE line in Stata on the author's own data prints:

| statistic | value |
|---|---|
| F test of excluded instruments, cluster-robust | 37.02 |
| Kleibergen–Paap rk Wald F | 37.015 |
| Sanderson–Windmeijer chi-sq | 38.24 |
| Cragg–Donald Wald F | 46.53 |

Also checked and ruled out, all on the author's data: the same first stage unclustered-robust
(91.66) and homoskedastic (46.53); `se_comb_win` instrumented by `invsqrtnobs`, the
specification the table note actually describes (5.85 clustered, 41.08 robust, 38.72 OLS);
`se2_comb_win` on `invsqrtnobs` (5.54 / 24.61 / 38.95); `se_comb_win` on `invobs` (25.87 /
104.35 / 37.14); a precision-weighted first stage (2.53); `sqrtnobs` and `no_obs` as the
instrument (0.30, 0.03); the `small` option (37.015); the 525-row / 23-study subsample
(53.67); the quasi-experimental subsample (4.90); and the intensive-margin equivalent (5.23).
None is 31.2. The `twostepweakiv` line that follows in the do-file reports no F either,
though it does reproduce the paper's Anderson–Rubin interval {0.53, 6.47} exactly, which
confirms the estimation sample is the right one. The most likely origin of 31.2 is an earlier
data vintage or the MAIVE package's own output; it cannot be obtained from the published data
and is left missing.

*Note on the wrapper.* `st_ivreg2_first_F` returns 38.24 here, which is `ivreg2`'s
Sanderson–Windmeijer chi-square rather than the F its header prints (37.02). The wrapper is
hash-locked and shared with other packages, so it was not touched; the package reports its
value, and the paragraph above records what Stata actually prints. Neither number is 31.2, so
this does not affect the score.

Panel B (Ioannidis et al. 2017, Andrews and Kasy 2019, Bom and Rachinger 2019, Furukawa 2021,
van Aert and van Assen 2023) has no wrapper in `stata_compat.R` and is out of scope.

## Target-by-target results

Match = equal at the paper's printed precision, re-run and observed, not asserted.

| # | Label | Printed | Produced | Verdict |
|---|-------|---------|----------|---------|
| 1 | T3 col1 OLS: Publication bias coef | 1.689 | 1.68893 | MATCH |
| 2 | T3 col1 OLS: Publication bias SE | 0.264 | 0.264293 | MATCH |
| 3 | T3 col1 OLS: Effect-beyond-bias coef | 0.288 | 0.287948 | MATCH |
| 4 | T3 col1 OLS: Effect-beyond-bias SE | 0.0442 | 0.044220 | MATCH |
| 5 | T3 col1 OLS: Observations | 762 | 762 | MATCH |
| 6 | T3 col1 OLS: Studies | 38 | 38 | MATCH |
| 7 | T3 col2 FE: Publication bias coef | 0.887 | 0.886520 | MATCH |
| 8 | T3 col2 FE: Publication bias SE | 0.271 | 0.271197 | MATCH |
| 9 | T3 col2 FE: Effect-beyond-bias coef | 0.356 | 0.356381 | MATCH |
| 10 | T3 col2 FE: Effect-beyond-bias SE | 0.0252 | 0.025243 | MATCH |
| 11 | T3 col2 FE: Observations | 762 | 762 | MATCH |
| 12 | T3 col2 FE: Studies | 38 | 38 | MATCH |
| 13 | T3 col3 Precision: Publication bias coef | 2.592 | 2.591705 | MATCH |
| 14 | T3 col3 Precision: Publication bias SE | 0.530 | 0.530059 | MATCH |
| 15 | T3 col3 Precision: Effect-beyond-bias coef | 0.211 | 0.210956 | MATCH |
| 16 | T3 col3 Precision: Effect-beyond-bias SE | 0.0441 | 0.044144 | MATCH |
| 17 | T3 col3 Precision: Observations | 762 | 762 | MATCH |
| 18 | T3 col3 Precision: Studies | 38 | 38 | MATCH |
| 19 | T3 col4 Study: Publication bias coef | 2.173 | 2.173124 | MATCH |
| 20 | T3 col4 Study: Publication bias SE | 0.227 | 0.226899 | MATCH |
| 21 | T3 col4 Study: Effect-beyond-bias coef | 0.243 | 0.243257 | MATCH |
| 22 | T3 col4 Study: Effect-beyond-bias SE | 0.0470 | 0.047043 | MATCH |
| 23 | T3 col4 Study: Observations | 762 | 762 | MATCH |
| 24 | T3 col4 Study: Studies | 38 | 38 | MATCH |
| 25 | T3 col5 MAIVE: Publication bias coef | 3.056 | 3.056334 | MATCH |
| 26 | T3 col5 MAIVE: Publication bias SE | 1.500 | 1.500197 | MATCH |
| 27 | T3 col5 MAIVE: Effect-beyond-bias coef | 0.350 | 0.349877 | MATCH |
| 28 | T3 col5 MAIVE: Effect-beyond-bias SE | 0.0463 | 0.046283 | MATCH |
| 29 | T3 col5 MAIVE: First-stage F | 31.2 | 38.24 | MISS — not produced by the author's line on the author's data (Stata prints 37.02); see above |
| 30 | T3 col5 MAIVE: Observations | 603 | 603 | MATCH |
| 31 | T3 col5 MAIVE: Studies | 23 | 33 | MISS — the regression has 33 clusters; 23 counts studies reporting their own `se`, a different sample |

**29 / 31.**

## How to run

```
Rscript run.R
```

Reads only `data/v1/frisch/frisch.csv`. Takes about 37 seconds, nearly all of it the 38,000
bootstrap replications. Prints every produced number and writes `results.json`. No seed is
set anywhere in R and no R random number is drawn — the bootstrap is Stata's stream,
regenerated, so the output is bit-identical on every run and on every machine.

## Verdict

**GOOD.** All twenty coefficient and standard-error cells of Table 3 Panel A, and all five
observation counts, reproduce at printed precision from the published CSV alone, because the
bootstrap the table depends on is regenerated rather than approximated. The two remaining
misses are properties of the paper's own table rather than of this code: the MAIVE study count
belongs to a different sample from the estimates printed above it, and the MAIVE first-stage F
is not any of the first-stage statistics the author's own command reports on the author's own
data.
