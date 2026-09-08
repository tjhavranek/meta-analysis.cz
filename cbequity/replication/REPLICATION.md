# cbequity replication package

**Paper:** "Central Bank Equity as an Instrument of Monetary Policy", *Comparative Economic
Studies* (2020). https://doi.org/10.1057/s41294-019-00092-1

**Tables reproduced:** Table 1 (all 176 estimates, 9 studies) and Table 2 (146 "comparable"
estimates, `good==1`, 4 studies): five meta-regressions each (OLS / study FE / study-weighted /
precision-weighted / IV), 64 target cells in total.

**Provenance: `author_code`.** The site publishes the author's Stata script,
`site/cbequity/code.txt` (31 lines). The brief given to the first version of this package stated
that no author code existed, and that version reconstructed the specification from the paper's
prose. This version follows `code.txt` line by line. That correction is the whole story of what
changed; see "What the author's code does" and "Revision history" below.

## What the author's code does (code.txt, estimation lines verbatim)

```
xtset idstudy
gen invsqrtnobs = 1/sqrt(nobs)
eststo: reg r ser, vce(bootstrap, seed(22))                      (1) OLS
eststo: xtreg r ser, fe vce(bootstrap, seed(22))                 (2) FE
eststo: reg r ser [pweight=invperstudy], vce(robust)             (3) Study
eststo: reg r ser [pweight=prec], vce(robust)                    (4) Precision
eststo: ivreg2 r (ser=invsqrtnobs), robust                       (5) IV
esttab using fat.rtf, replace se star(* 0.10 ** 0.05 *** 0.01)
```
then the same five commands with `if good==1` for Table 2. The remaining lines are descriptive
(`sum`, `mean`, a scatter) and produce nothing that appears in Tables 1-2.

| Col | Stata | R (wrappers only) | Standard error |
|---|---|---|---|
| (1) | `reg r ser, vce(bootstrap, seed(22))` | `st_regress(r ~ ser)` | bootstrap, **observations** resampled, Stata default reps(50) |
| (2) | `xtreg r ser, fe vce(bootstrap, seed(22))` | `st_xtreg_fe(..., panel="idstudy")` + `st_xtreg_fe_cons` | bootstrap, **panels** resampled (Stata's bootstrap for xt commands is `cluster(panelvar) idcluster()` by default), reps(50) |
| (3) | `reg r ser [pweight=invperstudy], vce(robust)` | `st_regress(..., weights=invperstudy, robust=TRUE)` | robust HC1 (N/(N-k)), deterministic |
| (4) | `reg r ser [pweight=prec], vce(robust)` | `st_regress(..., weights=precr, robust=TRUE)` | robust HC1, deterministic |
| (5) | `ivreg2 r (ser=invsqrtnobs), robust` | `st_ivreg2(r ~ 1 \| ser ~ invsqrtnobs)` | robust HC0 (no `small`), unclustered, deterministic |

Points that matter for the numbers:

- **Only (1) and (2) are bootstrapped.** The table note says "Bootstrapped standard errors are
  shown in parentheses", but the code uses `vce(robust)` / `robust` for (3)-(5). Those six SE
  cells per table are deterministic and reproduce to the printed digit.
- **`[pweight=prec]`.** The published file mirrors the author's (same columns); there is no
  variable `prec`, so Stata resolves the abbreviation to the unique match `precr`, which is
  exactly `1/ser` (verified to machine precision). The "Precision" column is therefore weighted by
  `1/ser`, not by inverse variance `1/ser^2` as the table note suggests; `1/ser^2` reproduces
  neither table (T1 -2.290 vs printed -2.321; T2 -2.276 vs -2.455). `pweight` and `aweight` give
  identical point estimates, and Stata's `pweight` VCE is the same weighted HC1 sandwich as
  `aweight` + `vce(robust)`; `run.R` asserts that the wrapper's vcov equals that sandwich written
  out by hand.
- **`ivreg2 ..., robust` with no `small`.** `st_ivreg2` exposes `cluster()` but not a bare
  `robust`, so the robust VCE is taken as a post-estimation `vcov(m, vcov="hetero", ssc=.SSC_LARGE)`
  on the wrapper's own model object (the wrapper's large-sample profile, i.e. HC0) and asserted
  equal to the hand-written sandwich on the first-stage fitted regressor. No estimator is called
  outside the wrappers. RMSE for this column is `sqrt(SSR/N)` with **no** dof adjustment, which
  is what `ivreg2` reports without `small` (residuals against the actual `ser`).
- **R2 / RMSE rows were hand-copied from Stata's screen**: `esttab` with no `stats()` option
  prints only N, so those rows are not in `fat.rtf`. For `regress` they are R-squared and Root
  MSE (`sqrt(SSR/(N-k))`, aweight-normalised weights for (3)-(4)); for `ivreg2` R-squared and Root
  MSE as above; for `xtreg, fe` the "overall" R-sq (`corr(x*b, y)^2`, which with one regressor
  equals the OLS R2, hence 0.29/0.29 and 0.41/0.41) and `sigma_e = sqrt(within-SSR/(N-N_g-k))`.
- **Sample.** No column used has a missing value, so `if good==1` is a plain subset; N (176/146)
  and study counts (9/4) match.

## Verified against Stata 15.1 (2026-09-08)

Every line of `code.txt` was re-run in Stata 15.1 on the site's own published file,
`data/v1/cbequity/cbequity.csv` (probe do-files under `stata_work_cbequity/`). This is the
oracle for every convention claimed above; nothing below is inferred from documentation.

| Stata command | R-sq / Centered R2 | Root MSE / sigma_e | rounds to |
|---|---|---|---|
| `reg r ser` | .28624651 | .13227723 | 0.29 / 0.13 |
| `xtreg r ser, fe` | overall .28624651 | sigma_e .11753025 | 0.29 / 0.12 |
| `reg r ser [pw=invperstudy], robust` | .39717227 | .11858428 | 0.40 / 0.12 |
| `reg r ser [pw=prec], robust` | .29898292 | .10037388 | 0.30 / 0.10 |
| `ivreg2 r (ser=invsqrtnobs), robust` | .28237878 | .13187938 | 0.28 / 0.13 |
| `reg r ser if good==1` | .40817385 | .10521271 | 0.41 / 0.11 |
| `xtreg r ser if good==1, fe` | overall .40817385 | **sigma_e .10407703** | 0.41 / **0.10** |
| `reg .. [pw=invperstudy] if good==1` | .37185019 | .10643506 | 0.37 / 0.11 |
| `reg .. [pw=prec] if good==1` | .33620340 | .08398695 | 0.34 / 0.08 |
| `ivreg2 .. if good==1, robust` | .40298240 | .10494688 | 0.40 / 0.10 |

Stata's coefficients and robust SEs agree with `run.R` to every digit Stata prints, so the R
package is not approximating the author's commands, it is reproducing them. Two side results
from the same run: Stata accepts `[pweight=prec]` on this dataset and returns the paper's
Precision column, which settles the abbreviation question (`prec` -> `precr` = 1/ser); and
`tab idstudy if good==1` gives four studies (ids 2, 4, 6, 7 with 23, 38, 27 and 58 estimates),
which is where the `T2 studies` target's value of 4 comes from.

## Target-by-target results

Legend: `match` = agrees at the printed digits; `stoch` = bootstrap cell, reported not repaired.
Bootstrap cells show the 2000-replication value of the author's resampling scheme (what the
author's 50-replication printed number is a noisy estimate of); the literal 50-replication R
draw is in parentheses in the "Bootstrap" section below.

**Table 1** (N = 176, 9 studies)

| Cell | Printed | Produced | Verdict |
|---|---|---|---|
| OLS bias / SE | -2.354 (0.589) | -2.35443 (0.489) | match / stoch |
| OLS const / SE | 0.0261 (0.0316) | 0.026130 (0.0274) | match / stoch |
| OLS R2 / RMSE | 0.29 / 0.13 | 0.2862 / 0.13228 | match |
| FE bias / SE | -2.392 (1.708) | -2.39236 (1.893) | match / stoch |
| FE const / SE | 0.0288 (0.0954) | 0.028791 (0.1018) | match / stoch |
| FE R2 / RMSE | 0.29 / 0.12 | 0.2862 / 0.11753 | match |
| Study bias / SE | -2.773 (0.441) | -2.77280 (0.441275) | match / match |
| Study const / SE | 0.0428 (0.0245) | 0.042773 (0.024508) | match / match |
| Study R2 / RMSE | 0.40 / 0.12 | 0.3972 / 0.11858 | match |
| Precision bias / SE | -2.321 (0.380) | -2.32149 (0.380104) | match / match |
| Precision const / SE | 0.0238 (0.0197) | 0.023819 (0.019730) | match / match |
| Precision R2 / RMSE | 0.30 / 0.10 | 0.2990 / 0.10037 | match |
| IV bias / SE | -2.081 (0.405) | -2.08075 (0.404592) | match / match |
| IV const / SE | 0.00693 (0.0228) | 0.0069288 (0.022840) | match / match |
| IV R2 / RMSE | 0.28 / 0.13 | 0.2824 / 0.13188 | match |
| N / studies | 176 / 9 | 176 / 9 | match |

**Table 2** (`good==1`, N = 146, 4 studies)

| Cell | Printed | Produced | Verdict |
|---|---|---|---|
| OLS bias / SE | -2.705 (0.549) | -2.70535 (0.534) | match / stoch |
| OLS const / SE | 0.0490 (0.0299) | 0.049023 (0.0289) | match / stoch |
| OLS R2 / RMSE | 0.41 / 0.11 | 0.4082 / 0.10521 | match |
| FE bias / SE | -2.438 (1.906) | -2.43808 (1.771) | match / stoch |
| FE const / SE | 0.0321 (0.106) | 0.032141 (0.0958) | match / stoch |
| FE R2 | 0.41 | 0.4082 | match |
| **FE RMSE** | **0.11** | **0.10408** | **miss -- see below** |
| Study bias / SE | -2.517 (0.562) | -2.51702 (0.561781) | match / match |
| Study const / SE | 0.0334 (0.0297) | 0.033381 (0.029735) | match / match |
| Study R2 / RMSE | 0.37 / 0.11 | 0.3719 / 0.10644 | match |
| Precision bias / SE | -2.455 (0.406) | -2.45509 (0.405842) | match / match |
| Precision const / SE | 0.0332 (0.0205) | 0.033216 (0.020491) | match / match |
| Precision R2 / RMSE | 0.34 / 0.08 | 0.3362 / 0.083987 | match |
| IV bias / SE | -2.400 (0.401) | -2.40025 (0.401218) | match / match |
| IV const / SE | 0.0298 (0.0212) | 0.029752 (0.021152) | match / match |
| IV R2 / RMSE | 0.40 / 0.10 | 0.4030 / 0.10495 | match |
| N / studies | 146 / 4 | 146 / 4 | match |

Of the 56 cells outside the eight genuinely bootstrapped ones, 55 match; the exception is T2 FE
RMSE. Twelve SE cells that the first version treated as unreproducible bootstrap output are
deterministic under the author's code and match exactly. On the verifier's own count -- which
marks all 20 SE cells stochastic and checks the other 44 -- that is 43 of 44.

## The one remaining miss: T2 FE RMSE (printed 0.11, produced 0.10408)

Cause: `paper_inconsistent`.

1. The FE RMSE convention is not free. `xtreg, fe` prints `sigma_e = sqrt(within-SSR/(N-N_g-k))`;
   that gives T1 FE 0.11753 -> 0.12 (printed 0.12) and T2 0.10408 -> 0.10 (printed 0.11). Every
   other dof one could plausibly copy (N, N-1, N-2, N-N_g) gives T2 between 0.1023 and 0.1037,
   all rounding to 0.10; the dof that would be needed (<= 138.6) corresponds to no Stata quantity.
2. The other numbers on the `xtreg, fe` screen were checked as candidates for a transcription
   from the wrong line. Stata's `sigma` (`sqrt(sigma_u^2 + sigma_e^2)`) is 0.1087 in T2, which
   does round to 0.11 -- but it is 0.172 in T1, where the printed 0.12 is unmistakably `sigma_e`.
   No single screen quantity reproduces the FE RMSE row in both tables.
3. Everything else in that column (coefficient, constant, overall R2, N) matches on the same
   sample and fit, so this is not a sample or specification difference. The printed 0.11 is also
   the value of the two neighbouring cells in that row (OLS 0.11, Study 0.11).

4. Settled in Stata, not by argument: `xtreg r ser if good==1, fe` in Stata 15.1, on the site's
   own CSV, prints `sigma_e = .10407703` and stores `e(rmse) = .10407703`. `run.R` produces
   .1040770354. The gap to the printed 0.11 is therefore not an R-versus-Stata difference and
   not a wrong convention in this package: it is a gap between the author's own command and the
   author's own table.

The author's code, run on the author's data in Stata, cannot produce 0.11 in this cell. The
`esttab` line was run with no `stats()` option, so `fat2.rtf` contained only N and the R2/RMSE
rows were copied off the screen by hand; a slip on one of ten such cells is the explanation that
fits. `targets.json` records 0.11 because the paper prints 0.11 (checked in the published PDF,
Table 2, RMSE row: `0.11 0.11 0.11 0.08 0.10`), and it stays at 0.11. The package reports what
the command produces and says so in its own run output.

The first version of this package called both T2 FE RMSE and T2 IV RMSE a "transposition"
because its produced values were each other's printed number. That was an artefact of using
`sqrt(SSR/(N-2))` for the IV column: `ivreg2` without `small` uses `sqrt(SSR/N)`, which puts T2 IV
at 0.10495 -> 0.10 (and T1 IV at 0.13188 -> 0.13), so the IV cell was a code error here, not in
the paper, and the transposition story collapses to a single cell.

## Bootstrap standard errors (columns 1 and 2, eight cells)

**In Stata these eight cells reproduce exactly.** Re-running the two bootstrap lines of
`code.txt` at the author's defaults -- `reps(50)`, `seed(22)` -- in Stata 15.1 on the published
CSV returns the printed numbers to the last digit:

| Cell | Stata reps(50) seed(22) | Printed |
|---|---|---|
| T1 `reg` ser / _cons | .58867394 / .03164586 | (0.589) / (0.0316) |
| T1 `xtreg, fe` ser / _cons | 1.70779 / .09538525 | (1.708) / (0.0954) |
| T2 `reg` ser / _cons | .54877164 / .02988239 | (0.549) / (0.0299) |
| T2 `xtreg, fe` ser / _cons | 1.9056772 / .10573602 | (1.906) / (0.106) |

That also settles the resampling units, which are the one thing that could have been specified
wrongly here: the cluster version of the OLS line gives 1.224, nothing like the printed 0.589,
so `reg ..., vce(bootstrap)` really does resample observations, while Stata's own log for the
`xtreg` line says "Replications based on 9 clusters in idstudy". `run.R` implements exactly
those two schemes.

What R cannot do is reproduce the draws: the two programs do not share a PRNG stream, so
`seed(22)` carries no information across them, and at Stata's default of 50 replications the
printed number is one noisy draw (the SE of a bootstrap SE at 50 replications is roughly 10% of
its value, more for a 4-cluster panel bootstrap).

The estimator can still be checked, by letting both programs run far past 50. Stata at
`reps(2000)`, `seed(22)`, against this package's 2000-replication value:

| Cell | Stata 2000 | R 2000 |
|---|---|---|
| T1 OLS ser / _cons | .48849776 / .0271411 | .48906 / .027353 |
| T1 FE ser / _cons | 1.8493341 / .09757217 | 1.89279 / .101829 |
| T2 OLS ser / _cons | .53409918 / .02858014 | .53372 / .028856 |
| T2 FE ser / _cons | 1.7540135 / .09543565 | 1.77061 / .095757 |

The two agree to Monte Carlo error. The whole distance between the reported 0.489 and the
printed 0.589 is the noise of a 50-replication bootstrap, not a specification difference.

What `run.R` does: (1) resample observations with replacement, refit `st_regress`; (2) resample
studies with replacement, relabel each drawn study as its own panel (Stata's `idcluster()`),
refit `st_xtreg_fe` and `st_xtreg_fe_cons`; drop replications that cannot be estimated (Stata
does the same; one T1 FE draw of 2000 consisted only of singleton studies).

| Cell | Printed (Stata, 50 reps) | R, 2000 reps (reported) | R, 50 reps, seed 22 (log only) |
|---|---|---|---|
| T1 OLS bias / const | 0.589 / 0.0316 | 0.489 / 0.0274 | 0.475 / 0.0270 |
| T1 FE bias / const | 1.708 / 0.0954 | 1.893 / 0.1018 | 1.989 / 0.1046 |
| T2 OLS bias / const | 0.549 / 0.0299 | 0.534 / 0.0289 | 0.522 / 0.0275 |
| T2 FE bias / const | 1.906 / 0.106 | 1.771 / 0.0958 | 1.082 / 0.0700 |

The pattern is now the one the author's code implies: OLS bootstrap SEs near the HC1 robust SE
(T1 HC1 = 0.490 / 0.0275), FE bootstrap SEs three to four times larger because they resample 9
(or 4) panels. The first version's cluster bootstrap for every column gave 1.35 / 0.072 for T1
OLS, which is why its SE cells were 2-3x off. T1 OLS printed (0.589) sits about 20% above the
converged value; with 50 Stata draws that is within the noise, and the T2 FE 50-draw R value
(1.08 against a converged 1.77) shows how wide that noise is with four clusters.

## Verdict

**PARTIAL**, one display cell short of concordant. Against the verifier's arithmetic -- 44
deterministic targets, the 20 SE cells being marked stochastic -- **43 of 44 match**. Across all
64 cells of the two tables: all 20 coefficient and constant point estimates, all 10 R2 cells,
both N and both study counts, 9 of 10 RMSE cells and all 12 robust SE cells match the paper at
the printed digits; the 8 genuinely bootstrapped cells reproduce exactly in Stata but not in R,
for the reason given above.

The single miss, T2 FE RMSE, cannot be produced by the author's own command in the author's own
Stata on the site's own data. It is classified `paper_inconsistent` and left as it falls.

Runtime: about 8 minutes, almost all of it the 2 x 2050 bootstrap refits.

## The targets.json timestamp flag: re-derived from the paper, and clean

The verifier flagged `targets.json` as modified after `run.R` -- the signature of an oracle
edited to match its code. That was checked here against the paper, not against the R.

- `site/cbequity/cbequity.pdf` was re-extracted with `pdftotext -layout`, independently of any
  earlier transcription, and both tables read off it directly. All 60 table cells in
  `targets.json` -- 5 columns x (bias, bias SE, constant, constant SE, R2, RMSE) x 2 tables --
  match the PDF exactly, as do both `Observations` rows (176, 146). The HTML edition at
  `site/cbequity/paper/index.html` agrees with the PDF.
- `T1 studies = 9` is printed in the prose, twice: "176 estimates from nine studies", and "they
  are drawn from only 9 studies".
- `T2 studies = 4` is the one target **not printed anywhere in the paper**. The paper defines the
  comparable subsample and gives its size (146) but never says how many studies it spans. The
  value 4 is derived from the data (Stata `tab idstudy if good==1`: studies 2, 4, 6, 7 with 23,
  38, 27 and 58 estimates). It is consistent with the paper and with the data, but it is a
  derived count rather than a quotation, and a reader should know that about one of the 64
  targets.

So the oracle's content is the paper's, cell for cell, and no target was tuned toward any code.
The flag came from file ordering: in v1 `targets.json` was re-saved at 20:48 on 2026-09-07,
three minutes after that version of `run.R`. Nothing in `targets.json` has been touched since
(mtime still 2026-09-07 20:48) and `run.R` is now newer than it, so the ordering check passes on
its own terms too. **False alarm -- confirmed against the paper, not against the code.**

## Revision history

- v1 (2026-09-07): brief said no author code; specification reconstructed from prose; cluster
  bootstrap for all five columns; `sqrt(SSR/(N-2))` for IV RMSE; IV clustered by study.
  `targets.json` was re-saved three minutes after that `run.R`, which is what tripped the
  oracle-must-predate-code check; see the section above.
- v2 (2026-09-08): follows `code.txt`. Changes to `run.R`: observation bootstrap for (1), panel
  bootstrap for (2), robust HC1 SEs for (3)-(4), robust HC0 SEs and `sqrt(SSR/N)` RMSE for (5),
  unclustered IV, sandwich assertions, 2000-rep reported / 50-rep mirror bootstrap. No target
  changed. This fixed T2 IV RMSE; T2 FE RMSE remained.
- v3 (2026-09-08): no number changed. Every convention re-verified in Stata 15.1 on the published
  CSV, and the header of `run.R` now quotes those figures instead of arguing from documentation.
  The eight bootstrap cells were confirmed to reproduce exactly in Stata at reps(50), seed(22),
  and the R implementation was cross-checked against Stata at reps(2000). `run.R` now prints an
  explicit disagreement banner for T2 FE RMSE. The panel bootstrap assembles each resample by
  row index instead of `rbind`-ing subsets -- same rows, same order, same seed -- so
  `results.json` came back with all 64 values identical, about 25% faster. `targets.json`
  untouched, and re-derived from the published PDF.

## Files

- `targets.json` -- 64 cells from Tables 1-2, verified against the paper text; never edited here.
- `run.R` -- reads only `data/v1/cbequity/cbequity.csv`; calls only `stata_compat.R` wrappers
  (`st_regress`, `st_xtreg_fe`, `st_xtreg_fe_cons`, `st_ivreg2`, `st_coefs`) plus post-estimation
  `vcov()`/`resid()`/`deviance()`/`r2()` on the wrapper-returned objects and plain matrix
  arithmetic for the sandwich cross-checks; writes `results.json`.
- `results.json` -- produced values keyed exactly as in `targets.json`.
