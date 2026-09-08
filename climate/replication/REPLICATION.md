# Replication package: "Publication Bias in Measuring Anthropogenic Climate Change"

Reckova & Irsova, *Energy and Environment* 26(5), 853-862 (2015), doi 10.1260/0958-305x.26.5.853.

Table reproduced: **Table 1** ("Test of true climate sensitivity beyond publication bias"),
all three columns (ME, Clustered OLS, Clustered FE), plus three summary statistics quoted
in the text just after Table 1.

Run with:

```
Rscript run.R
```

Reads only `data/v1/climate/climate.csv` as published by meta-analysis.cz. Writes
`results.json` and prints every target to stdout. No manual steps.

## Status

**31 / 31 targets match.** Every printed cell of Table 1 — all eight ME cells, all ten
Clustered-OLS cells, all ten Clustered-FE cells — plus the three text statistics reproduce
to the digit the paper prints. Nothing is left missing.

## Provenance

The site publishes the authors' own Stata code at `climate/climate.do`, complete, 194
lines. The three Table-1 columns are lines 158, 162 and 163 of that file:

```
158  xtmixed tstat prec mea1 se_low || idstudy: , nolog
162  xtreg  tstat prec mea1 se_low, fe vce(cluster idstudy)
163  reg    tstat prec mea1 se_low, vce (cluster idstudy)
```

No line relevant to Table 1 is commented out.

## Variable mapping: "mea" is the published column `dumm_mean`

`climate.do` line 17 renames the column outright:

```
17  rename dumm_mean mea
```

and lines 21-30 then build the regressors used in Table 1:

```
21  gen prec  = 1/se_low
22  gen tstat = estimate/se_low
30  gen mea1  = mea/se_low
```

So `mea` is the published column `dumm_mean`, a dummy for estimates reported as a mean.
It is *not* the column literally named `mean`, which Stata's unambiguous-prefix
abbreviation might otherwise suggest: `mean` is non-missing on only 25 of the 48 rows,
while every Table-1 cell reports N = 48. The mapping is confirmed three times over —
substituting `dumm_mean` reproduces all ten printed cells of the OLS column, all ten of
the FE column, and all eight of the ME column.

## Estimation

- **Clustered OLS** (line 163) — `st_regress(..., cluster = ~idstudy)`. Stata's `regress`
  small-sample convention is what that wrapper encodes.
- **Clustered FE** (line 162) — Stata's `xtreg, fe` constant comes from the "augmented
  within regression" documented in `stata_compat.R`'s `st_xtreg_fe_cons()`: demean each
  variable by the panel group, add back its grand mean, then regress on the transformed
  variables. That wrapper takes one regressor; this specification has three (`prec`,
  `mea1`, `se_low`), so the augmentation arithmetic is written out for three columns here
  and the regression itself still runs through `st_regress()`, leaving the estimation
  convention (clustered SEs, fixest default small-sample correction) exactly as the wrapper
  encodes it. The printed "R2" for this column is Stata's `xtreg, fe` **overall** R2 — the
  squared correlation between the outcome and fitted values built from the within slopes
  plus the reported constant, evaluated on the original (non-demeaned) data — 0.647. The
  *within* R2 of the same model is a different number and is not what is printed. Stata
  confirms both: `e(r2_o) = .6465058`, `R-sq: within = 0.8958`.
- **Mixed-effects (ME)** (line 158) — `st_xtmixed()`, i.e. `lmer(REML = TRUE)`. See below.

## The ME column: `xtmixed` means REML, and that was the whole gap

This package previously reported six misses, all in the ME column. The cause was that
`run.R` called `st_mixed()` (ML) where the do-file's command is `xtmixed`. In the Stata the
authors ran (12 or earlier — this is a 2015 paper), `xtmixed` fits by **restricted** maximum
likelihood by default. Stata 13 renamed the command to `mixed`, flipped the default to ML,
and kept `xtmixed` alive only as a synonym for that new ML default. `stata_compat.R` already
carries both conventions as two separate wrappers, `st_mixed()` (ML) and `st_xtmixed()`
(REML); the package was calling the wrong one. Nothing in the compat layer was touched.

Verified directly against Stata 15.1, run on the site's own `climate/climate.dta` with the
do-file's own variable construction:

| ME cell | printed | `xtmixed` (Stata 15 default = ML) | `xtmixed, reml` | this package |
|---|---|---|---|---|
| 1/SE coef | 1.617 | 1.609092 | 1.617142 | 1.617142 |
| 1/SE se | 0.19 | .1814723 | .1895463 | 0.1895463 |
| mean/SE coef | -1.074 | -1.066051 | -1.074176 | -1.074176 |
| mean/SE se | 0.183 | .1754883 | .1834076 | 0.1834076 |
| SE coef | -0.234 | -.2343807 | -.2338916 | -0.2338916 |
| SE se | 0.132 | .1266212 | .1316771 | 0.1316771 |
| Constant coef | 2.5 | 2.508188 | 2.497748 | 2.497748 |
| Constant se | 0.369 | .3515761 | .3687664 | 0.3687664 |

Stata's ML run prints the banner "Mixed-effects ML regression"; adding `reml` prints
"Mixed-effects REML regression". Only the REML column matches the paper, and it matches in
all eight cells. Two independent corroborations of the same reading:

- The paper's text quotes the 95% interval for the true effect as "(1.246, 1.989)".
  Stata's REML fit prints `[1.245638, 1.988646]`; its ML fit prints `[1.253413, 1.964771]`.
- Table 1's likelihood-ratio row prints 8. Stata's REML fit reports
  `LR test vs. linear model: chibar2(01) = 8.00`; the ML fit reports 7.67.

`lme4::lmer(REML = TRUE)` — what `st_xtmixed()` calls — agrees with Stata's REML fit to
seven significant figures on every coefficient and standard error, so this is a real
convention match, not a coincidence at the printed precision.

Two other estimators were ruled out on the way: GLS random effects (`xtreg, re`,
Swamy-Arora) gives 1.555 / -1.012 / -0.238 / 2.579, and cluster-robust standard errors on
either mixed fit give roughly 0.30 / 0.35 / 0.34 / 0.03. So despite the table note's blanket
"clustered at the study level", the ME column's standard errors are model-based, as
`xtmixed` reports them by default.

Table 1's likelihood-ratio row (chi2 = 8) is not itself a target — it is a model diagnostic
rather than a coefficient, standard error, N or count — but it is quoted above as evidence,
and this package's fit does produce it.

## Target-by-target results

| Label | Printed | Produced | Verdict |
|---|---|---|---|
| T1 OLS 1/SE coef | 1.276 | 1.275823 | match |
| T1 OLS 1/SE se | 0.316 | 0.315583 | match |
| T1 OLS mean/SE coef | -0.732 | -0.732279 | match |
| T1 OLS mean/SE se | 0.286 | 0.286328 | match |
| T1 OLS SE coef | -0.316 | -0.315776 | match |
| T1 OLS SE se | 0.086 | 0.086334 | match |
| T1 OLS constant coef | 3.054 | 3.053939 | match |
| T1 OLS constant se | 0.232 | 0.232364 | match |
| T1 OLS N | 48 | 48 | match |
| T1 OLS R2 | 0.728 | 0.728097 | match |
| T1 FE 1/SE coef | 2.087 | 2.087063 | match |
| T1 FE 1/SE se | 0.086 | 0.086047 | match |
| T1 FE mean/SE coef | -1.55 | -1.549626 | match |
| T1 FE mean/SE se | 0.079 | 0.079328 | match |
| T1 FE SE coef | -0.226 | -0.225634 | match |
| T1 FE SE se | 0.017 | 0.017364 | match |
| T1 FE constant coef | 2.353 | 2.353343 | match |
| T1 FE constant se | 0.068 | 0.068041 | match |
| T1 FE N | 48 | 48 | match |
| T1 FE R2 | 0.647 | 0.646506 | match |
| T1 ME 1/SE coef | 1.617 | 1.617142 | match |
| T1 ME 1/SE se | 0.19 | 0.189546 | match |
| T1 ME mean/SE coef | -1.074 | -1.074176 | match |
| T1 ME mean/SE se | 0.183 | 0.183408 | match |
| T1 ME SE coef | -0.234 | -0.233892 | match |
| T1 ME SE se | 0.132 | 0.131677 | match |
| T1 ME constant coef | 2.5 | 2.497748 | match |
| T1 ME constant se | 0.369 | 0.368766 | match |
| text uncorrected average estimate | 3.27 | 3.274375 | match |
| text lowest estimate | 0.7 | 0.7 | match |
| text n estimates <= average true effect (1.6) | 5 | 5 | match |

## What was and was not done to reach 31/31

- `targets.json` was not touched. Every printed value in it was re-checked against the
  paper's own text and is correct as transcribed.
- `stata_compat.R` was not touched. The REML wrapper the ME column needs already existed,
  with its own Stata-log evidence documented in place.
- No tolerance was widened, no observation dropped, no constant introduced. The sample is
  the full published file: 48 rows, 16 studies, no missing values on any variable Table 1
  uses.
- The only substantive change was calling `st_xtmixed()` instead of `st_mixed()` for the
  do-file's `xtmixed` command. Two claims in the previous version of this file were also
  wrong and are corrected: that the supplied do-file "contains no `mixed`/`xtmixed` line",
  and that `mea` had to be inferred by testing candidate columns against the printed
  coefficients. `climate.do` is published in full on the site; it states the ME command on
  line 158 and the `dumm_mean` rename on line 17.

## Unsupported commands

None. `st_regress()` covers the OLS column and, with the documented augmented-within
transformation, the FE column; `st_xtmixed()` covers the ME column.
