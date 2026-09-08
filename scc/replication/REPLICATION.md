# Replication package: "Selective Reporting and the Social Cost of Carbon"

Havranek, Irsova, Janda & Zilberman, *Energy Economics* (2015).
https://doi.org/10.1016/j.eneco.2015.08.009

## What this package reproduces

**Table 3, "Funnel asymmetry tests, estimates with uncertainty"** -- both
panels, all ten columns -- plus every number behind the paper's headline
sentence ("range between USD 0 and 134 per ton of carbon") and the arithmetic
of the Conclusion's exaggeration claims.

- Panel A: `SCC_ij = SCC0 + beta * SE(SCC_ij) + u_ij`, five specifications
  (OLS, study fixed effects, weighted by 1/SE, weighted by 1/(estimates per
  study), study-level mixed effects).
- Panel B: adds the upper-bound approximate SE as a second regressor, same
  five specifications.

Sample: `dataset == 1` in the published data, N = 267, matching the printed
observation count in all ten columns.

## Provenance

- Data: `site/data/v1/scc/scc.csv` -- the file the site publishes. Nothing else
  is read.
- Code: the author's `scc.do`, published at `site/scc/scc.do`. Panel A's four
  estimated columns are its lines 87-91, Panel B's are lines 99-102, verbatim.
  The do-file's `xtmixed` lines were not in the excerpt this package was built
  from, so the "ME" column was inferred from the table footnote as a
  random-intercept model on `idstudy`; those cells are flagged `stochastic` in
  `targets.json` and are not scored, but all ten of them land on the printed
  values, which is strong evidence the inferred specification is the one that
  was run.
- `preclow` and `invperstudy` are generated exactly as in `scc.do` lines 16
  and 22 (`gen preclow = 1/stdlow`, `gen invperstudy = 1/perstudy`).

## Estimator mapping (stata_compat.R wrappers only)

| Stata (scc.do) | Wrapper used |
|---|---|
| `reg scc stdlow [stdup] if dataset==1, cluster(idstudy)` | `st_regress(..., cluster=~idstudy)` |
| `xtset idstudy` then `xtreg scc stdlow [stdup], fe cluster(idstudy)` | `st_xtreg_fe(...)` for the slopes |
| `xtreg`'s reported `_cons`, one regressor (Panel A) | `st_xtreg_fe_cons(...)` |
| `xtreg`'s reported `_cons`, two regressors (Panel B) | the same augmented-within construction, written out for two regressors and run through `st_regress(..., cluster=~idstudy)` -- see below |
| `reg ... [pweight=preclow], cluster(idstudy)` | `st_regress(..., weights = 1/stdlow)` |
| `reg ... [pweight=invperstudy], cluster(idstudy)` | `st_regress(..., weights = 1/perstudy)` |
| `reg scc stdlow if dataset==2, vce(robust)` (Table 4 OLS) | `st_regress(..., robust = TRUE)` |
| mixed-effects ME column (inferred, not in the excerpt) | `st_mixed(...)` |

### The Panel B FE constant (previously the only unresolved cell)

Stata's `xtreg, fe` prints a `_cons` that fixest does not report.
`stata_compat.R` recovers it with `st_xtreg_fe_cons()`, which replaces every
variable by (value - its panel mean + its grand mean) and runs OLS with the
same clustering; that regression's intercept and intercept SE are exactly the
ones `xtreg` prints. The wrapper's `x` argument takes a single column name, so
it cannot be called for Panel B, which has two regressors. The identical
construction is therefore written out in `run.R` for `stdlow` and `stdup` and
handed to `st_regress()` with the same cluster variable. `st_xtreg_fe_cons()`
is itself nothing but a clustered OLS of the augmented variables at fixest's
default ssc, which is precisely what `st_regress()` does, so only the arity
changes: no new estimator, variance convention, or degrees-of-freedom rule is
introduced. The `border` and `habits` packages generalise the same wrapper the
same way. `stata_compat.R` was **not** modified.

Checked against Stata 15.1 on this same published CSV
(`stata_work_scc/feb.do`):

```
xtreg scc stdlow stdup, fe cluster(idstudy)
  _cons = 114.132402651147   se = 118.550006349356

reg a_scc a_stdlow a_stdup, cluster(idstudy)     (augmented within)
  _cons = 114.132402651147   se = 118.550006349356
```

Identical to all twelve reported decimals. R returns 114.132405 (118.550004);
the paper prints 114.1 (118.6). `run.R` also asserts that the augmented
regression's two slopes and their SEs equal `st_xtreg_fe()`'s to 1e-8, so this
cell cannot silently drift away from the FE model it is supposed to describe.

## Target-by-target results

N = 267 in all ten columns, exactly as printed.

### Panel A

| Spec | Cell | Printed | Produced | Verdict |
|---|---|---|---|---|
| OLS | SE coef (se) | 1.705 (0.630) | 1.7051 (0.6303) | match |
| OLS | Constant (se) | 134.1 (58.16) | 134.07 (58.157) | match |
| FE | SE coef (se) | 1.889 (0.762) | 1.8890 (0.7625) | match |
| FE | Constant (se) | 104.2 (123.9) | 104.20 (123.86) | match |
| Std.err.-weighted | SE coef (se) | 2.467 (0.480) | 2.4672 (0.4798) | match |
| Std.err.-weighted | Constant (se) | 10.27 (7.361) | 10.268 (7.3610) | match |
| Study-weighted | SE coef (se) | 1.213 (0.527) | 1.2131 (0.5270) | match |
| Study-weighted | Constant (se) | 63.14 (40.12) | 63.139 (40.120) | match |
| ME | SE coef (se) | 1.819 (0.0825) | 1.8194 (0.08252) | match (not scored) |
| ME | Constant (se) | -18.69 (48.43) | -18.685 (48.435) | match (not scored) |

### Panel B

| Spec | Cell | Printed | Produced | Verdict |
|---|---|---|---|---|
| OLS | SE coef (se) | 1.662 (0.663) | 1.6618 (0.6630) | match |
| OLS | Upper-SE coef (se) | 0.0246 (0.0254) | 0.02459 (0.02537) | match |
| OLS | Constant (se) | 112.0 (50.00) | 112.03 (49.999) | match |
| FE | SE coef (se) | 1.907 (0.779) | 1.9070 (0.7788) | match |
| FE | Upper-SE coef (se) | -0.0109 (0.00676) | -0.01088 (0.006763) | match |
| FE | **Constant (se)** | **114.1 (118.6)** | **114.13 (118.55)** | **match** (was unresolved) |
| Std.err.-weighted | SE coef (se) | 2.451 (0.538) | 2.4510 (0.5379) | match |
| Std.err.-weighted | Upper-SE coef (se) | 0.00283 (0.0107) | 0.002830 (0.01066) | match |
| Std.err.-weighted | Constant (se) | 9.555 (6.133) | 9.5547 (6.1327) | match |
| Study-weighted | SE coef (se) | 0.780 (0.548) | 0.7803 (0.5475) | match |
| Study-weighted | Upper-SE coef (se) | 0.222 (0.143) | 0.2222 (0.1429) | match |
| Study-weighted | Constant (se) | 45.29 (29.63) | 45.292 (29.626) | match |
| ME | SE coef (se) | 1.835 (0.0843) | 1.8345 (0.08429) | match (not scored) |
| ME | Upper-SE coef (se) | -0.00788 (0.0100) | -0.007879 (0.010000) | match (not scored) |
| ME | Constant (se) | -17.78 (48.81) | -17.785 (48.811) | match (not scored) |

**All 50 scored Table 3 targets now match.** Ten further ME cells match but are
recorded as `stochastic` and are not scored.

## Numbers from the paper's text

meta-analysis.cz summarises this paper as "0-134 USD per metric ton of
carbon", straight from the abstract:

> "Our estimates of the mean reported SCC corrected for the selective
> reporting bias range between USD 0 and 134 per ton of carbon at 2010 prices
> for emission year 2015."

| Claim | Quantity | Paper | Produced | Verdict |
|---|---|---|---|---|
| upper end of "USD 0 and 134"; "the largest corrected mean SCC we get for estimates with uncertainty is USD 134" | Table 3 Panel A OLS constant | 134 | 134.07 | match |
| lower end of "USD 0 and 134", as literally printed | max(0, Panel A ME constant) | 0 | 0 | match |
| lower end, the underlying estimate itself | Panel A ME constant | -18.69 (Table 3) | -18.685 | see Misses |
| "because the uncorrected mean of these estimates is 411" | mean(scc), `dataset==1` | 411 | 411.06 | match |
| "exaggerated at least threefold" | 411 / 134 | 3 | 3.07 | match |
| "the largest corrected mean SCC ... for study-level estimates ... is 61" | Table 4 OLS constant, `reg scc stdlow if dataset==2, vce(robust)`, N=68 | 61 | 61.07 | match |
| "the overall mean of 290" | mean(scc), `dataset==0`, N=809 | 290 | 290.00 | match |
| "more than four times less" | 290 / 61 | "four times" | 4.75 | see Misses |
| "The result is USD 39 (= 134 x 1.07/3.67)" | unit conversion | 39 | 39.07 (paper's rounded 134) / 39.09 (our 134.07) | match |

The three subsamples all live in `scc.csv` (1144 rows = 809 + 267 + 68),
distinguished by the `dataset` column. The USD/tCO2 conversion is arithmetic,
not estimation, so no wrapper is involved.

## Misses

Two of the sixty scored targets do not match, and neither is an estimation
problem. Both are headline targets whose recorded `printed` value is not a
number the corresponding quantity can equal.

1. **`HL_lower_corrected_mean_raw`** -- recorded as `printed: 0`, `digits: 0`.
   Its own note in `targets.json` defines the quantity as the Panel A
   mixed-effects constant, "-18.69 (s.e. 48.43)", and says the value is
   reported "so nothing is hidden". The package computes -18.685, which is
   the paper's Table 3 Panel A, ME column, "Constant -18.69 (48.43)". It can
   never round to 0. The abstract's literal "0" is a separate target,
   `HL_lower_corrected_mean_floor0`, which computes max(0, ME constant) and
   does match. So the paper's printed number for the raw quantity is -18.69,
   not 0; this looks like a transcription slip in the oracle rather than a
   defect in the code. `targets.json` was not touched -- the mismatch is left
   standing.

2. **`HL_studylevel_ratio`** -- recorded as `printed: 4`, `digits: 0`. The
   paper prints no such figure. The Conclusion says the study-level corrected
   mean "is 61, which is more than four times less than the overall mean of
   290" -- a verbal lower bound, not a printed quantity. 290/61 = 4.75, which
   is what "more than four times" describes, but at zero decimals it rounds to
   5, so a target of exactly 4 cannot be hit by any honest computation. Its
   sibling `HL_exaggeration_factor`, from the parallel phrase "at least
   threefold", matches only because 411/134 = 3.07 happens to round to 3. Both
   components of this ratio -- 61.07 and 290.00 -- reproduce exactly and are
   scored separately, so the substance of the claim is verified even though
   the derived target is not.

Nothing was rounded, reweighted, or dropped to close either gap, and the
hash-locked `stata_compat.R` was not edited.

## Verdict

**58 of 60 scored targets reproduce**, up from 56. All 50 scored Table 3
targets match, including the Panel B fixed-effects constant and its standard
error, which are new in this revision and were confirmed against Stata 15.1
before being coded. Eight of the ten headline targets match. The two that do
not are described above: one appears to be a mis-transcribed oracle value (the
paper prints -18.69, the target says 0), the other asks a rounded ratio to
equal a word ("four times") rather than a printed number.
