# Replication package: "Structural Reforms and Growth in Transition: A Meta-Analysis"

Babecká Kucharčuková, Havránek & Iršová-style meta-analysis, *Economics of Transition* (2014),
doi 10.1111/ecot.12029.

**Tables reproduced:** all of Table 3, "Test of publication bias" (Short run / Long run, each with
Fixed / Robust / Clustered — coefficients, standard errors and N), plus the "Simple average" /
"Fixed effects" / "Random effects" rows of Table 2 and the two bias-corrected effects the Section-4
text quotes, so `run.R` also prints the numbers behind the paper's own headline sentence rather
than only table cells.

**Status: 38 of 38 targets reproduce**, all at the paper's printed precision.

## Provenance

`author_code`, with one caveat worth stating plainly. The task brief marked every relevant line of
`reform.do` as inside `/* */` and "does not run." Re-reading the actual file on disk
(`site/reforms/reform.do`), those lines are **not** commented out there — the file matches the
brief's line list token-for-token, in the same order, with no comment delimiters around them. The
likely explanation is that whatever automated tool produced the brief tried to execute the do-file
standalone and had to skip lines calling SSC or add-on commands absent in that environment
(`metan`, `rreg`) or depending on `foreach`/`local` scaffolding not reproduced in the excerpt — not
that the author's script treats them as dead code. Since the do-file matches Table 3's footnote
description exactly, it is treated as genuine author code.

## What the code does

From `reform.do`:

```
gen pcor = lib/sqrt(lib*lib+df)
gen pcor_cum = lib_cum/sqrt(lib_cum*lib_cum+df)
gen se_pcor = sqrt((1-pcor*pcor)/df)
gen se_pcor_cum = sqrt((1-pcor_cum*pcor_cum)/df)
gen se1_pcor = 1/se_pcor
gen se1_pcor_cum = 1/se_pcor_cum
gen odd = 1 if se1_pcor>15 & pcor>0.3 & lib<12

reg lib se1_pcor if rg!=0 & lib<12 & odd!=1                          " Short run, Fixed
reg lib_cum se1_pcor_cum if rg!=0 & lib_cum<7.5                      " Long run, Fixed
rreg lib se1_pcor if rg!=0 & lib<12 & odd!=1                         " Short run, Robust
rreg lib_cum se1_pcor_cum if rg!=0 & lib_cum<7.5                     " Long run, Robust
reg lib se1_pcor if rg!=0 & lib<12 & odd!=1, vce(cluster study)      " Short run, Clustered
reg lib_cum se1_pcor_cum if rg!=0 & lib_cum<7.5, vce(cluster study)  " Long run, Clustered
```

`lib` is the primary study's reported t-statistic on the reform variable, not a correlation itself:
`pcor = lib/sqrt(lib^2+df)` is the standard t-to-partial-correlation identity, which inverts to
`lib = pcor/se_pcor`. So an unweighted OLS of `lib` on `se1_pcor = 1/se_pcor` is algebraically
identical to a WLS regression of `pcor` on `se_pcor` weighted by `1/se_pcor^2` — exactly what
Table 3's note describes for "Fixed" ("weighted least squares; weighted by the inverse of the
standard error of the partial correlation coefficient"). No explicit weights argument is needed;
the `lib`/`se1_pcor` transform *is* the weighting, and `run.R` uses
`st_regress(lib ~ se1_pcor, data = ...)` unweighted, matching the do-file line for line.

Term mapping (worth spelling out, because it is easy to get backwards): dividing the WLS
specification `pcor = b_PET + b_pub*se_pcor + e` through by `se_pcor` gives
`lib = b_PET*(1/se_pcor) + b_pub + u`. So in `reg lib se1_pcor`, the **intercept** is the
funnel-asymmetry / publication-bias coefficient (Table 3's "Publication bias (coef. β0)" row), and
the **slope on se1_pcor** is the precision-effect estimate of the true, bias-corrected effect
(Table 3's "Effect beyond bias (Constant)" row — named for what it estimates, not for being
literally Stata's `_cons`).

Stata missing-value semantics matter here: `rg`, `lib_cum` and `odd` can be missing, and Stata
treats missing as +infinity, so `rg!=0` and `odd!=1` are *true* when those variables are missing,
while `lib<12` and `lib_cum<7.5` are *false* when `lib`/`lib_cum` are missing. `run.R` builds each
comparison with an explicit `ifelse(is.na(x), Inf, x)` substitution before combining them, then
passes the fully-resolved logical vector to `st_keep_if`.

## The Robust column: what it is, and how it is reproduced

This is where the package used to fail, and the diagnosis was mine to get wrong twice over. The
earlier version of `run.R` recorded the two Robust columns as unresolvable and emitted `NA` for
all ten of their cells, on the reasoning that Stata's `rreg` has no wrapper in `stata_compat.R` and
that no allowed primitive is equivalent to it. The second half of that is true. The first half is
not a reason to stop: `rreg` is a *published algorithm*, not a black box, and the algorithm is
short.

Table 3's note says "'Robust': estimated by iteratively re-weighted least squares", the text cites
Hamilton (2006, pp. 239–256), Hamilton wrote the program Stata ships as `rreg`, and the author's
do-file runs `rreg` and nothing else for that column. So `run.R` now ports `rreg` step by step from
Stata's own `rreg.ado` (version 3.4.1, 21sep2017, from the Stata 15.1 installed on this machine),
with **every regression inside the algorithm done by `st_regress()`** — the loop is the only thing
that lives in `run.R`, exactly the treatment `stata_compat.R` already gives `hadimvo`:

1. OLS; drop observations with Cook's D > 1; refit OLS.
2. Huber iterations, `w_i = min(1, 2*median|res - median(res)| / |res_i|)`, refitting by weighted
   least squares until `max_i |w_i - w_i,old| <= 5*tolerance` (tolerance 0.01).
3. Tukey biweight iterations, `scale = median(absdev)/0.6745`, tuning constant `tune*4.685/7 =
   4.685` at Stata's default `tune(7)`, `w_i = max(1-(res_i/(c*scale))^2, 0)^2`, until
   `max_i |w_i - w_i,old| <= tolerance`. `rreg` always runs at least one biweight pass.
4. Standard errors from pseudo-values: the last weighted fit's fitted values plus
   `(lambda*scale/a)*(res/scale)*w` are regressed on the same regressors by plain OLS, and *that*
   regression's coefficient table is what `rreg` prints. Because the weighted normal equations give
   `X'(w*res) = 0`, this OLS returns the weighted point estimates unchanged; the construction only
   sets the variance.

Note what this is **not**. It is not `regress, robust` (heteroskedasticity-consistent SEs on the
OLS fit — a different column of the same table would then be a duplicate), and it is not
`MASS::rlm()`, which is plain Huber or bisquare M-estimation with neither the Cook's D pre-filter,
nor Stata's specific Huber-then-biweight sequencing, nor the pseudo-value variance. Substituting
either would have produced numbers in the right neighbourhood and wrong in the third decimal, which
is the failure mode this whole build exists to avoid.

### Evidence the port is right, not merely close

Stata 15.1 was run on the **same published CSV** `run.R` reads
(`repl/stata_work_reforms/probe1.do`, log `probe1.log`). Stata prints the maximum weight change at
every IRLS iteration, which makes the internals checkable and not just the endpoint. The port
reproduces every iteration count, every printed weight change, and both coefficient tables to eight
significant digits:

| | Stata 15.1 `rreg` | this port |
|---|---|---|
| short, Huber iter 1 | .59448662 | 0.59448654 |
| short, Huber iter 2 | .02352864 | 0.02352853 |
| short, biweight iters 3/4/5 | .15406792 / .012021 / .00473194 | 0.15406791 / 0.01202087 / 0.00473197 |
| short, `_cons` | 4.179459367647 (.960626196871) | 4.179459373820 (0.960626190126) |
| short, `se1_pcor` | −0.394543955583 (.074212137293) | −0.394543957039 (0.074212136776) |
| long, Huber iters 1/2 | .51483801 / .01294374 | 0.51483804 / 0.01294368 |
| long, biweight iters 3/4 | .15771416 / .00034534 | 0.15771417 / 0.00034534 |
| long, `_cons` | 0.265400999752 (.299820245690) | 0.265400961671 (0.299820244038) |
| long, `se1_pcor_cum` | 0.115588507061 (.026217452582) | 0.115588510753 (0.026217452453) |

Stata's own `rreg` output rounds to the paper's printed Table 3 cells exactly, which also confirms
the published CSV is the same data the paper was written from: 4.179 (0.961), −0.395 (0.074),
N = 245; 0.265 (0.300), 0.116 (0.026), N = 292. The residual disagreement between Stata and the
port is at the 8th significant digit and comes from the CSV's float32 storage interacting with
`median()` on the absolute deviations; it moves no printed digit.

The Cook's D screen removes nothing in either sample (max D = 0.112 short, 0.042 long), so N stays
at 245 and 292 — as the paper prints. The screen is implemented anyway, because leaving it out
would make the port agree here by luck rather than by construction.

## Target-by-target results

Values are the model's raw output; "printed" is the paper's Table 3 / Table 2 value.

| Label | Printed | Produced | Verdict |
|---|---|---|---|
| pb_short_fixed_coef | 4.137 | 4.137296 | MATCH |
| pb_short_fixed_se | 0.947 | 0.946862 | MATCH |
| pb_short_robust_coef | 4.179 | 4.179459 | MATCH |
| pb_short_robust_se | 0.961 | 0.960626 | MATCH |
| pb_short_clustered_coef | 4.137 | 4.137296 | MATCH |
| pb_short_clustered_se | 2.036 | 2.035729 | MATCH |
| pb_long_fixed_coef | 0.313 | 0.313417 | MATCH |
| pb_long_fixed_se | 0.290 | 0.290147 | MATCH |
| pb_long_robust_coef | 0.265 | 0.265401 | MATCH |
| pb_long_robust_se | 0.300 | 0.299820 | MATCH |
| pb_long_clustered_coef | 0.313 | 0.313417 | MATCH |
| pb_long_clustered_se | 0.586 | 0.586295 | MATCH |
| eff_short_fixed_coef | −0.394 | −0.394162 | MATCH |
| eff_short_fixed_se | 0.073 | 0.073149 | MATCH |
| eff_short_robust_coef | −0.395 | −0.394544 | MATCH |
| eff_short_robust_se | 0.074 | 0.074212 | MATCH |
| eff_short_clustered_coef | −0.394 | −0.394162 | MATCH |
| eff_short_clustered_se | 0.164 | 0.164444 | MATCH |
| eff_long_fixed_coef | 0.110 | 0.110220 | MATCH |
| eff_long_fixed_se | 0.025 | 0.025372 | MATCH |
| eff_long_robust_coef | 0.116 | 0.115589 | MATCH |
| eff_long_robust_se | 0.026 | 0.026217 | MATCH |
| eff_long_clustered_coef | 0.110 | 0.110220 | MATCH |
| eff_long_clustered_se | 0.056 | 0.056185 | MATCH |
| n_short_fixed | 245 | 245 | MATCH |
| n_short_robust | 245 | 245 | MATCH |
| n_short_clustered | 245 | 245 | MATCH |
| n_long_fixed | 292 | 292 | MATCH |
| n_long_robust | 292 | 292 | MATCH |
| n_long_clustered | 292 | 292 | MATCH |

One rounding detail is worth flagging rather than hiding: `eff_short_robust_coef` produces
−0.394544, and the paper prints −0.395. Those agree, because −0.394544 rounds to −0.395 at three
decimals — the same value Stata's `rreg` returns (−0.394543955583). The neighbouring Fixed and
Clustered cells print −0.394 from −0.394162. So the paper's Table 3 is internally consistent, and
the port's third decimal is not a near miss dressed up as a match.

## Numbers from the paper's text

meta-analysis.cz summarises the paper as: **"reforms in transition countries cost growth in the
short run but raise it strongly in the long run."** That is the paper's own abstract: "an average
reform caused substantial costs in the short run, but had strong positive effects on long-run
growth... The findings hold even after correction for publication bias." Two passages give the
magnitudes, and `run.R` computes and prints both.

**(a) Table 2, "Estimating the average reform effect"** — the *uncorrected* averages, on the
identical samples as Table 3 (the paper states N = 245 short / 292 long for both). `run.R`
reproduces all three rows with `mean()` for "Simple average" (an unweighted arithmetic mean, not a
model call) and `st_metan()` for "Fixed effects" (equal-effects, precision-weighted) and "Random
effects" (DerSimonian–Laird) — Table 2's own definitions.

| Label | Claim | Paper | Produced | Verdict |
|---|---|---|---|---|
| simple_avg_short | Table 2, Simple average, short run | −0.052 | −0.052305 | MATCH |
| simple_avg_long | Table 2, Simple average, long run | 0.146 | 0.145520 | MATCH |
| fe_avg_short | Table 2, Fixed effects, short run | −0.081 | −0.081409 | MATCH |
| fe_avg_long | Table 2, Fixed effects, long run | 0.135 | 0.135468 | MATCH |
| re_avg_short | Table 2, Random effects, short run | −0.056 | −0.055989 | MATCH |
| re_avg_long | Table 2, Random effects, long run | 0.143 | 0.142683 | MATCH |

**(b) Section 4 text, discussing Table 3** — the bias-*corrected* effects (Table 3's "Effect beyond
bias" row, re-emitted as standalone headline numbers so a reader sees them without parsing the
table):

> "the corrected estimates of the short-run reform effect are consistent and significant at the
> 5 percent level across all three methods: they reach −0.39, which is approximately four times
> more than the simple averages reported in the previous section... after correction for
> publication bias, the long-term effect of an average reform on economic growth is still positive
> and small... the corrected effect is very close to the simple average (approximately 0.1)."

| Label | Claim | Paper | Produced | Verdict |
|---|---|---|---|---|
| corrected_short | Section 4, short-run corrected effect ("−0.39") | −0.394 | −0.394162 | MATCH |
| corrected_long | Section 4, long-run corrected effect ("approximately 0.1") | 0.110 | 0.110220 | MATCH |

The "across all three methods" claim can now be checked rather than assumed, since the third method
is computed: −0.394 (Fixed), −0.395 (Robust), −0.394 (Clustered) short-run; 0.110 / 0.116 / 0.110
long-run.

**"Approximately four times":** a rounded qualitative comparison, not a stated ratio, so `run.R`
reports the numbers that justify it rather than pinning one figure as a target. The corrected
short-run effect (−0.394) over each of Table 2's three short-run averages gives 7.54× (vs. simple
average −0.052), 4.84× (vs. fixed-effects average −0.081) and 7.04× (vs. random-effects average
−0.056). The fixed-effects comparison lands closest to "approximately four"; against the plain
unweighted average the multiple is larger. Either way the qualitative claim holds: none of the
ratios is near 1×.

**"Very close to the simple average (approximately 0.1)":** the corrected long-run effect (0.110)
and all three Table 2 long-run averages (0.135–0.146) cluster tightly, and none of the comparisons
flips sign or changes order of magnitude the way the short-run correction does — consistent with
the paper's statement that publication bias is not significant for the long-run effect.

## Misses

None. All 38 targets are computed and match.

## Repairs made

One, and it closed every outstanding gap: **Stata's `rreg` is now ported into `run.R` instead of
being declared unsupported.** The previous package computed the Fixed and Clustered columns
correctly on the first attempt and wrote `NA` for the ten Robust-column cells. The diagnosis
recorded there — "`rreg` has no wrapper and is not one of the allowed primitives" — described the
tooling, not the estimator; `rreg.ado` is 60 lines of IRLS whose every regression step is an
ordinary (weighted) `regress`, so it composes out of `st_regress()` without inventing anything. The
port was written against `rreg.ado` and checked against a Stata 15.1 run on the published CSV, per
the iteration-by-iteration table above.

`stata_compat.R` was **not** modified. Nothing about Stata's regression conventions changed; only
an algorithm built on top of them was added, in the package that needs it.

## How to run

```
Rscript run.R
```

Reads only `site/data/v1/reforms/reforms.csv`. No manual steps, no author-only files. `run.R` prints
the IRLS iteration diagnostics, so a reader can compare them line for line against the Stata log in
`probe1.log` rather than taking the final coefficients on trust.

## Verdict

**FULL.** 38 of 38 deterministic targets reproduce at the paper's printed precision: every cell of
Table 3 (all three methods × both horizons, coefficients, standard errors and N), the three Table 2
average rows for both horizons, and the two Section-4 corrected effects. The ten cells that
previously missed were a tooling gap, not a data or specification problem, and they are closed by
porting the estimator the author actually ran and checking that port against Stata itself.
