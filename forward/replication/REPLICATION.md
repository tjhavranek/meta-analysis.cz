# Replication: *How Puzzling Is the Forward Premium Puzzle? A Meta-Analysis*

Gnezdilov, Havránek, Iršová, *European Economic Review*, 2021.

`run.R` reproduces **Table A3** — Tests of publication bias, currencies of developed countries —
Panels A (FAT-PET) and B (PEESE), all six columns. It also records, but does not reproduce, the
six numbers behind the site's headline range for Table 5.

**14 of the 20 scored targets reproduce to the printed digit. Six do not, and are left blank
rather than approximated.** The six are Table 5's implied betas; the reason is given below.

Run it with `Rscript run.R`. It reads one file the site publishes,
`data/v1/forward/forward.csv`, and writes `results.json`.

---

## What reproduces

| Table A3 cell | printed | produced |
|---|---|---|
| Panel A, Observations | 2582 | 2582 |
| Panel A, FE, mean beyond bias | 0.657 | 0.6572075 |
| Panel A, FE, publication bias | −2.331 | −2.3314760 |
| Panel A, WLS, mean beyond bias | 0.639 | 0.6385066 |
| Panel A, WLS, publication bias | −2.264 | −2.2641330 |
| Panel A, IV, mean beyond bias | 0.359 | 0.3592227 |
| Panel A, IV, publication bias | −1.258 | −1.2584157 |
| Panel B, Observations | 2582 | 2582 |
| Panel B, FE, mean beyond bias | 0.666 | 0.6661793 |
| Panel B, FE, publication bias | −0.390 | −0.3897269 |
| Panel B, WLS, mean beyond bias | 0.582 | 0.5815099 |
| Panel B, WLS, publication bias | −0.219 | −0.2189747 |
| Panel B, IV, mean beyond bias | 0.275 | 0.2754964 |
| Panel B, IV, publication bias | −0.597 | −0.5966861 |

Every one of these is a re-run number, not a transcription. The standard errors in the paper's
parentheses are bootstrapped without a seed, so they are stochastic and are reported for
completeness only (see "Standard errors" below).

## The two things the published code does not contain

The site publishes `forward.do`. That file produces the **full-sample** version of this table
(Table 2, N = 2989) but not the developed-country version, and it stops short of one column. Two
specifications therefore had to be recovered. Both were recovered by running **Stata 15.1** on
the published `forward.dta` and checking the candidates against the paper's own printed numbers;
the probe do-files are in `repl/stata_work_forward/`.

### 1. The sample (N = 2582)

Table A3's note says "Only difference estimates (Eq. 3) for the currencies of advanced countries
are included", but no line anywhere in `forward.do` carries a country-scope restriction. The
filter is pinned empirically: `lnSpot == 0 & Emerging_currencies == 0` gives exactly 2582 rows —
the Observations figure printed under all six columns — and under that filter every deterministic
cell lands on the printed digit. Confirmed in Stata:
`count if lnspot==0 & emerging_currencies==0` → 2,582.

One detail matters. `gen double inv_nobs=1/nobs if lnspot==0` (do-file line 28) runs before any
country restriction, so a study's count of difference estimates is taken over the whole
`lnSpot == 0` population (2989 rows, all currency scopes), not over the advanced subsample.
Recomputing it on the subsample moves every coefficient 5–15% off the printed value.

### 2. The FE column of Panel B

There is no do-file line for it. The specification recovered in Stata is

```stata
xtreg tstat_w se_w inv_se_w, fe
    "Mean beyond bias (1/SE)" = _b[inv_se_w]
    "Publication bias (SE)"   = _cons
```

— i.e. an *unweighted* fit on the `sqrt(inv_nobs)`-scaled variables. It is trusted because it
reproduces this column on three independent printed tables at once, six cells, all to the printed
digit:

| | Stata `_b[inv_se_w]` | printed | Stata `_cons` | printed |
|---|---|---|---|---|
| Table 2 (N = 2989) | 0.621751 | 0.622 | −0.362320 | −0.362 |
| Table A1 (N = 654) | 0.932814 | 0.933 | 0.298343 | 0.298 |
| Table A3 (N = 2582) | 0.666179 | 0.666 | −0.389727 | −0.390 |

Note what this implies: **the row the paper labels "Publication bias (SE)" is the model's
intercept, not the coefficient on `se_w`.** The coefficient on `se_w` is +0.3316 on this sample
and matches nothing printed anywhere. Three tables and six cells agreeing to the printed digit is
strong enough evidence that the label in the paper is loose while the numbers are right; the
package reproduces the numbers and says so here rather than silently reinterpreting the row.

Because `sqrt(inv_nobs)` is constant within a study, the fixed effects absorb it, so this
unweighted fit on scaled variables and a `[pweight=inv_nobs]` fit on raw variables give
**identical slopes**. They differ only in the intercept — and Panel A prints the intercept from
the weighted fit while Panel B prints the one from the scaled fit (for Table A3: −2.331 vs
−2.833). That asymmetry is why the two panels need two different commands.

### And one convention: the `_cons` of a pweighted `xtreg, fe`

Panel A's publication bias is the constant of `xtreg tstat inv_se [pweight=inv_nobs], fe`.
`st_xtreg_fe_cons()` in `stata_compat.R` takes no weights, and its unweighted answer here is
−2.33236, which rounds to −2.332 and misses the printed −2.331. That wrapper documents what
Stata's reported `_cons` is: "the grand mean of y minus the fitted within slope times the grand
mean of x". With pweights those grand means are the weighted ones. Checked against Stata on this
sample:

```
xtreg tstat inv_se [pweight=inv_nobs], fe    _cons                     = -2.33147601
sum tstat [aw=inv_nobs] ; sum inv_se [aw=inv_nobs]
    0.03516583 - 0.65720749 * 3.60105731                               = -2.33147601
```

Identical to eight decimals. `run.R` evaluates that documented identity with aweighted means. No
estimator outside the wrapper set is used, and `stata_compat.R` was not modified.

## Standard errors

The paper's parentheses are bootstrap standard errors, `reps(100)`, with no `seed()` — so they
are not reproducible to the digit by anyone, including the authors, and the verifier does not
score them. The package still bootstraps the right thing rather than reporting the wrong
analytic quantity:

* Do-file line 111 says in as many words, "fixed effects not weighted here, recalculate
  bootstrapped se's". Stata refuses `bootstrap` over a weighted command (`weights not allowed`,
  r(101)), which is why line 112 re-runs the FE fit unweighted on the scaled variables. The
  package bootstraps that.
* **Panel B FE, confirmed:** Stata with 400 reps on the recovered command returns 0.1103 for the
  slope and 0.0569 for the constant, against printed 0.109 and 0.0537 — both inside the sampling
  noise of `reps(100)`. This is independent evidence that the recovered command is the right one.
* **Panel A FE, one cell not matched.** The slope's bootstrap comes out at ≈0.110 (Stata, 400
  reps) against a printed 0.117, comfortably within noise. The constant's comes out at ≈0.29
  against a printed 0.340 — about 2 standard deviations away, so it may well be a different
  resampling scheme than the one used here. That cell is not claimed to reproduce. It is a
  standard error, not an estimate, and it is not scored.

## What does NOT reproduce, and why: Table 5 / the site's headline range

The site summarises the paper as **"0.23–0.45 for developed and 0.95–1.16 for emerging
currencies"**. That is Table 5 read as a min–max across its three columns: the *Advanced
currencies* row is 0.309 / 0.448 / 0.231 and the *Emerging currencies* row is 0.945 / 1.164 /
0.947. The same range appears verbatim in the abstract and in Section 5.4.

**These six numbers come from Bayesian model averaging and are left blank.** Section 5.4 states
the provenance directly: the implied beta is "calculated using the results of BMA in Subsection
5.3 and calculating a linear combination of BMA coefficients and the chosen values for each
variable". `forward.do` lines 590–608 keep the call, commented out because it was run in R:

```r
bma_dilut = bms(dataforward, burn=1e6, iter=5e6, g="UIP", mprior="dilut",
                nmodel=5000, mcmc="bd", user.int=FALSE)
coef(bma_dilut, order.by.pip = F, exact=T, include.constant=T)
```

A five-million-draw MCMC model average over 2^43 candidate specifications, with no seed, has no
counterpart among the audited wrappers (`st_ivreg2`, `st_xtreg_fe`, `st_regress`, `st_metan`,
`st_winsor*`, `st_keep_if`, `st_drop_if`, `st_coefs`). Calling `BMS::bms()` directly would be
exactly the unaudited-estimator shortcut this layer exists to prevent, and an unseeded MCMC would
not land on three printed digits anyway. So the six cells are `null` in `results.json`.

### The frequentist analog, reported as context

`forward.do` does contain an uncommented, directly runnable answer to the same question — one
weighted OLS fit plus `lincom`, lines 683–736, "Heterogeneity – Best practice". Every step is a
permitted wrapper, so `run.R` computes it, under `Context_*` labels so that nothing here can be
mistaken for Table 5. Verified against Stata 15.1 on the published `forward.dta`
(`repl/stata_work_forward/probe7.do`):

| | this code | Stata | Table 5 (BMA) |
|---|---|---|---|
| Advanced, preferred | 0.2747 | 0.274726 | 0.309 |
| Advanced, Frankel & Poonawala | 0.4219 | 0.421931 | 0.448 |
| Advanced, Breedon et al. | −0.0781 | −0.078089 | 0.231 |
| Emerging, preferred | 1.0353 | 1.035289 | 0.945 |
| Emerging, Frankel & Poonawala | 1.1327 | 1.132662 | 1.164 |
| Emerging, Breedon et al. | 0.6908 | 0.690812 | 0.947 |

Right sign and rough magnitude in five of six, and the Frankel & Poonawala column within 0.03 —
which is about what a single OLS fit should look like next to a model-averaged posterior mean.
It is not Table 5 and is not reported as Table 5.

### A data gap worth recording

The site publishes a **finer coding** than the 42 moderators the authors actually regressed on.
Several do-file variables are aggregates built before the data were exported, and the site
documents neither the aggregation nor the original variable names. They were recovered from the
Mean/SD columns of the paper's own Table 3 (computed on `lnSpot == 0`, N = 2989), which pins the
ones used here uniquely:

| do-file variable | site columns | recovered mean / SD | Table 3 |
|---|---|---|---|
| `controls` | `Forward_premium_power2_3` \| `Other_controls` | 0.0435 / 0.204 | 0.04 / 0.21 |
| `large_differential` | `Large_differential` \| `Large_positive_interest_diff` | 0.0335 / 0.180 | 0.03 / 0.18 |
| `small_differential` | `Small_differential` \| `Low_Negative_interest_diff` | 0.0348 / 0.183 | 0.03 / 0.18 |
| `firstdraft_year` | `firstpub` | 30.1138 | 30.11 / 8.03 |

`firstpubo` is the raw calendar year and does not match; `Other_controls` and `Large_differential`
alone do not match either. The one-to-one names were pinned the same way
(`Advanced_currencies` 0.3878 vs 0.39, `N` 0.5496 vs 0.55, `Time_diff` 1.0083 vs 1.01,
`IF_recursive` 0.4592 vs 0.46, `Normcit` 1.7047 vs 1.70, and so on). The reference categories the
same exercise identifies — "Longer horizon" = `to3years|to10years|Mixed`, "Other frequency" =
`Quarterly|Other_freq`, "Other technique" = `Instrumental_variables|Error_correction|ML|Other_met`,
"Other base" = `USD_base|JPY_base|Swiss_base` — are consistent with this reading.

**What would close the remaining six targets:** the authors' BMA output, i.e. the posterior mean
coefficients from `bma_dilut` (the table behind Figure 5 / Section 5.3), or the `dataforward`
export the BMA was run on. Neither is published. With the posterior means in hand the six implied
betas are a linear combination that this package could evaluate directly.

## Files

* `run.R` — the replication. Reads `data/v1/forward/forward.csv`, writes `results.json`.
* `targets.json` — the paper's printed numbers, frozen before any code was written. Never edited.
* `results.json` — what the last run produced.
