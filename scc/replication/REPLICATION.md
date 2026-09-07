# Replication package: "Selective Reporting and the Social Cost of Carbon"

Havránek & Irsová, *Energy Economics* (2015). https://doi.org/10.1016/j.eneco.2015.08.009

## Table reproduced

**Table 3, "Funnel asymmetry tests, estimates with uncertainty"** — both panels.
This is the paper's headline test for selective reporting / publication bias
among the subsample of SCC estimates for which a measure of uncertainty is
reported (`dataset == 1` in the published data, N = 267, matching the table's
printed observation count exactly).

- Panel A: `SCC_ij = SCC0 + beta * SE(SCC_ij) + u_ij`, five specifications
  (OLS, study fixed effects, weighted by 1/SE, weighted by 1/(estimates per
  study), study-level mixed effects).
- Panel B: adds the upper-bound approximate SE as a second regressor,
  same five specifications.

## Provenance

- Data: `site/data/v1/scc/scc.csv` (the file the site publishes; column list
  matches the brief exactly).
- Code: author's `scc.do`, as excerpted in `briefs_repl/scc.md` (lines 10–174,
  none of them commented out). The four Panel-A/Panel-B regression commands for
  each panel (`reg`, `xtreg ..., fe`, and the two `[pweight=...]` regressions)
  appear verbatim at lines 87–91 (Panel A) and 99–102 (Panel B). The excerpt
  jumps from line 91 to line 99 and never shows a `mixed` or `xtmixed` command,
  so the fifth ("ME") column of each panel is not literally present in the
  brief — it is inferred from the table's own footnote ("ME = study-level
  mixed effects") as a random-intercept model on `idstudy`, using
  `st_mixed()`, which the harness provides specifically for `mixed y x || g:`
  and which is Stata-ML by convention (matching Stata's `mixed` default). This
  inference is flagged `stochastic` in `targets.json`, but every ME cell it
  produced landed exactly on the printed value (see table below), which is
  strong evidence the inferred specification is the one the authors ran.

## Estimator mapping (stata_compat.R wrappers only)

| Stata (scc.do)                                              | Wrapper used |
|---|---|
| `reg scc stdlow [stdup] if dataset==1, cluster(idstudy)`    | `st_regress(..., cluster=~idstudy)` |
| `xtset idstudy` + `xtreg scc stdlow [stdup] ..., fe cluster(idstudy)` | `st_xtreg_fe(...)` for coefficients |
| `xtreg`'s reported `_cons` (1 regressor, Panel A)           | `st_xtreg_fe_cons(...)` |
| `reg ... [pweight=preclow] ..., cluster(idstudy)`           | `st_regress(..., weights = 1/stdlow)` |
| `reg ... [pweight=invperstudy] ..., cluster(idstudy)`       | `st_regress(..., weights = 1/perstudy)` |
| `mixed scc stdlow [stdup] || idstudy:` (inferred, ME column)| `st_mixed(..., data)` |

`preclow` and `invperstudy` are generated exactly as in scc.do lines 16 and 22
(`gen preclow = 1/stdlow`, `gen invperstudy = 1/perstudy`).

## Target-by-target results

All values below round to the printed value at the printed precision unless
noted. N = 267 for every specification, exactly as printed, for all ten
columns (Panel A x5, Panel B x5).

### Panel A ("estimates with uncertainty" regression, N=267)

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
| ME | SE coef (se) | 1.819 (0.0825) | 1.8194 (0.08252) | match |
| ME | Constant (se) | -18.69 (48.43) | -18.685 (48.435) | match |

### Panel B (adds upper-bound SE, N=267)

| Spec | Cell | Printed | Produced | Verdict |
|---|---|---|---|---|
| OLS | SE coef (se) | 1.662 (0.663) | 1.6618 (0.6630) | match |
| OLS | Upper-SE coef (se) | 0.0246 (0.0254) | 0.02459 (0.02537) | match |
| OLS | Constant (se) | 112.0 (50.00) | 112.03 (49.999) | match |
| FE | SE coef (se) | 1.907 (0.779) | 1.9070 (0.7788) | match |
| FE | Upper-SE coef (se) | -0.0109 (0.00676) | -0.01088 (0.006763) | match |
| FE | Constant (se) | 114.1 (118.6) | not produced | **unresolved** |
| Std.err.-weighted | SE coef (se) | 2.451 (0.538) | 2.4510 (0.5379) | match |
| Std.err.-weighted | Upper-SE coef (se) | 0.00283 (0.0107) | 0.002830 (0.01066) | match |
| Std.err.-weighted | Constant (se) | 9.555 (6.133) | 9.5547 (6.1327) | match |
| Study-weighted | SE coef (se) | 0.780 (0.548) | 0.7803 (0.5475) | match |
| Study-weighted | Upper-SE coef (se) | 0.222 (0.143) | 0.2222 (0.1429) | match |
| Study-weighted | Constant (se) | 45.29 (29.63) | 45.292 (29.626) | match |
| ME | SE coef (se) | 1.835 (0.0843) | 1.8345 (0.08429) | match |
| ME | Upper-SE coef (se) | -0.00788 (0.0100) | -0.007879 (0.010000) | match |
| ME | Constant (se) | -17.78 (48.81) | -17.785 (48.811) | match |

## Misses

Only one cause of miss, applied to two cells:

- **`T3B_FE_const` and `T3B_FE_const_se`** (Panel B, FE column, constant and
  its SE): `stata_compat.R` provides `st_xtreg_fe_cons()` for the constant
  Stata's `xtreg, fe` reports, but that wrapper's augmented-within-regression
  trick (`y - group_mean(y) + grand_mean(y)` etc.) is hard-coded for exactly
  one regressor. Panel B's FE specification has two regressors (`stdlow` and
  `stdup`), and there is no provided wrapper for the multi-regressor case.
  Writing a bespoke `feols()` call to extend the trick to two regressors would
  mean calling `feols` directly, which the brief and `stata_compat.R` both
  forbid ("Never call feols... directly... a Stata command with no wrapper
  here is a stop-and-file event"). Rather than guess at an extension of a
  hash-checked, calibrated file, this run leaves those two cells unproduced
  and reports them as unresolved. Every other Panel B FE cell (both
  coefficients and their SEs, and N) matched exactly, so the FE model itself
  is being fit correctly — only its intercept-reporting convention for >1
  covariate is out of scope for the current wrapper set.

No other cell in either panel missed. All ten N=267 counts matched exactly.
The ME column, whose exact specification had to be inferred because it does
not appear verbatim in the excerpted `scc.do`, matched on all ten of its cells
across both panels (coefficients, upper-SE coefficient, constants, and all
their standard errors) — the random-intercept-on-`idstudy`, ML (not REML)
specification via `st_mixed()` is confirmed correct by that agreement, not
merely plausible.

## Verdict

**PARTIAL.** 49 of 51 targets matched exactly (all deterministic coefficients,
standard errors, and observation counts across both panels of Table 3); 2
targets (Panel B's FE-column constant and its SE) are unresolved because the
one wrapper for the reported FE constant does not extend to a two-regressor
specification, and extending it was out of scope ("never call feols directly").
No target was repaired, and no target failed on a genuine mismatch.
