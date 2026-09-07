# Replication package -- class (Class Size, publication bias)

**Paper**: "Publication Bias and Model Uncertainty in Measuring the Effect of Class Size on
Achievement", *Journal of Labor Economics* 2026, https://doi.org/10.1086/737989

**Table reproduced**: Table 3, Block 1 ("All estimates"), Panel A -- the linear publication-bias
tests (OLS / FE / IV / Study / Precision columns), plus the IV column's first-stage robust
F-stat and the block's base sample size.

**Provenance**: author's own Stata do-file (`class.do`), lines 22-53 (data construction) and
219-234 (the five Panel-A regressions), matched against the printed numbers in Table 3.

## What is and is not covered

Panel A of Block 1 is the paper's headline publication-bias test and is fully reproduced here:
10 coefficients, 10 standard errors, the first-stage F, and the base N -- 22 deterministic
targets, all matched.

Not attempted, and why:

- **Table 3 Block 2 ("Preferred estimates")** and **Tables B4/B5** apply the same Panel-A
  models to different subsamples/effect definitions, but the do-file excerpt available to this
  package shows no code that constructs the "preferred" subsample filter or that reruns these
  regressions restricted to it -- only Block 1's code is present. Reproducing Block 2 would mean
  guessing the sample filter, which the task instructions rule out.
- **Table 3 Panel B (WAAP, Stem, Kink, p-uniform\*, Selection)**: several of the do-file lines
  behind these estimates are themselves marked as not running in the release (`x` lines
  331-437, which build the selection-model bootstrap series `bs`/`sebs`), and the remaining
  visible lines (455 onward) reference `r(mean)` from a preceding command that is not included
  in the excerpt, so the WAAP cutoff cannot be reconstructed from evidence. Stem, Kink and
  p-uniform\* additionally have no wrapper in `stata_compat.R` (they are not `ivreg2`/`xtreg`/
  `regress`/`metan`/`mixed`). These are left out rather than approximated.
- **The bracketed/braced confidence intervals** printed next to each Panel-A coefficient come
  from `boottest` (wild-cluster bootstrap) and, for the IV column, also `twostepweakiv`
  (weak-instrument-robust). No seed is set anywhere in the visible do-file, `stata_compat.R` has
  no wild-cluster-bootstrap wrapper, and these are stochastic quantities in any case -- they are
  not included as targets, consistent with the task's treatment of unseeded bootstrap output.

## Data

`data/v1/class/class.csv` (2,908 rows) has every column the Panel-A regressions need
(`idstudy`, `effect_true`, `effect`, `se_effect`, `sample_size`, `weight`), so the published CSV
was used directly; the original `class.xlsx` was not needed.

## Construction (class.do lines 22-53)

- `drop if effect_true==0` -> N = 2,434 (matches; used `st_drop_if`).
- `winsor effect, generate(effect_w) p(0.01)` / same for `se_effect_w`, `sample_size_w` ->
  `st_winsor(x, p = 0.01)` (SSC `winsor.ado` order-statistic convention, per `stata_compat.R`).
- `precision_w = 1/se_effect_w`; `sqrt_sample_size_w = sqrt(sample_size_w)` (the excluded
  instrument for the IV column).

## The five Panel-A columns (class.do lines 219-234)

| Column | Stata command | R call |
|---|---|---|
| OLS | `ivreg2 effect_w se_effect_w, cluster(idstudy)` | `st_ivreg2(effect_w ~ se_effect_w, cluster=~idstudy)` |
| FE | `xtreg effect_w se_effect_w, fe vce(cluster idstudy)` | `st_xtreg_fe(...)` for the slope, `st_xtreg_fe_cons(...)` for the reported `_cons` |
| IV | `ivreg2 effect_w (se_effect_w = sqrt_sample_size_w), cluster(idstudy) first` | `st_ivreg2(effect_w ~ 1 \| se_effect_w ~ sqrt_sample_size_w, cluster=~idstudy)` |
| Study | `ivreg2 effect_w se_effect_w [pweight=weight], cluster(idstudy)` | `st_ivreg2(..., weights=~weight)` |
| Precision | `ivreg2 effect_w se_effect_w [pweight=precision_w], cluster(idstudy)` | `st_ivreg2(..., weights=~precision_w)` |

For the IV column's endog/instrument, the two-sided `endog ~ instrument` part is written
directly into the `fml` argument of `st_ivreg2` using fixest's own IV formula syntax
(`y ~ exog | endog ~ instrument`), rather than through the wrapper's separate `iv=` argument --
passing `iv=list(endog ~ instrument)` or a bare formula to that argument does not build a valid
fixest IV formula (confirmed by inspection and by testing: the first errors with "subscript out
of bounds", the second silently treats the endogenous variable as a fixed effect and drops the
coefficient). Encoding the IV part in `fml` itself uses no function besides `st_ivreg2` and
reproduces the printed numbers exactly.

For the first-stage F, `stata_compat.R`'s own comment on `st_ivreg2_first_F` says it needs
"fixest DEFAULT ssc, not the large-sample one the coefficient table uses" -- but the model
object returned by `st_ivreg2` is always fit with the large-sample ssc, and `fitstat()`
inherits whatever ssc the model was fit with (confirmed: refitting with the large-sample ssc
gives F = 22.93, not 22.5). The default-ssc model needed for the F-stat is obtained instead by
passing the same IV formula through `st_regress()`, which is the wrapper that leaves fixest's
ssc at its own default (matching Stata `regress`'s small-sample convention, exactly what
`ivreg2, first` uses for the first-stage diagnostics even when the main table has none).

## Target-by-target results

All 22 targets are deterministic (no bootstrap/simulation among them) and all matched at the
printed precision.

| Label | Printed | Produced | Verdict |
|---|---|---|---|
| Base N after drop if effect_true==0 | 2,434 | 2434 | MATCH |
| OLS: Publication bias (coef) | 0.0331 | 0.03314 | MATCH |
| OLS: Publication bias (se) | 0.0944 | 0.09444 | MATCH |
| OLS: Effect beyond bias / constant (coef) | -0.297 | -0.2966 | MATCH |
| OLS: Effect beyond bias / constant (se) | 0.114 | 0.1135 | MATCH |
| FE: Publication bias (coef) | 0.00613 | 0.006134 | MATCH |
| FE: Publication bias (se) | 0.0795 | 0.07954 | MATCH |
| FE: Effect beyond bias / constant (coef) | -0.262 | -0.2624 | MATCH |
| FE: Effect beyond bias / constant (se) | 0.101 | 0.1007 | MATCH |
| IV: Publication bias (coef) | 0.0644 | 0.06444 | MATCH |
| IV: Publication bias (se) | 0.150 | 0.1501 | MATCH |
| IV: Effect beyond bias / constant (coef) | -0.345 | -0.3449 | MATCH |
| IV: Effect beyond bias / constant (se) | 0.0929 | 0.09286 | MATCH |
| IV: First-stage robust F-stat | 22.5 | 22.49 | MATCH |
| Study: Publication bias (coef) | -0.0733 | -0.07332 | MATCH |
| Study: Publication bias (se) | 0.210 | 0.2095 | MATCH |
| Study: Effect beyond bias / constant (coef) | -0.625 | -0.6250 | MATCH |
| Study: Effect beyond bias / constant (se) | 0.212 | 0.2123 | MATCH |
| Precision: Publication bias (coef) | -0.0575 | -0.05755 | MATCH |
| Precision: Publication bias (se) | 0.140 | 0.1401 | MATCH |
| Precision: Effect beyond bias / constant (coef) | -0.182 | -0.1818 | MATCH |
| Precision: Effect beyond bias / constant (se) | 0.0577 | 0.05770 | MATCH |

**22 / 22 deterministic targets matched. No misses, no repairs needed.**

One documented (non-target) discrepancy: the IV column's own N is 2,426, eight fewer than the
block's base N of 2,434, because 8 rows have missing `sample_size` and so cannot form the
`sqrt_sample_size_w` instrument. The extracted table text does not print a per-column N for
Panel A (only a single "Observations 2,434" line appears, positioned under Panel B), so this
was not set up as a target and is reported here only as a sanity note.

## How to run

```
Rscript run.R       # writes results.json, prints every produced number
Rscript compare.R   # prints the target-by-target table above
```

## Verdict

**CONCORDANT** for Table 3, Block 1, Panel A (the paper's headline publication-bias test).
Block 2 and Panel B are out of scope for the reasons above, not misses against attempted
targets.
