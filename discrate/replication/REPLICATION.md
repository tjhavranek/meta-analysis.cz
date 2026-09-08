# Replication package: Cazachevici, Havránek & Horváth (2022), "Individual
# Discount Rates: A Meta-Analysis of Experimental Evidence", Experimental
# Economics. https://doi.org/10.1007/s10683-021-09716-9

**Status: PARTIAL — 28 of 45 target numbers reproduce to the printed digits.**
The 17 that miss all miss for one identified reason, and it is not a modelling
error: it is a Monte Carlo draw inside Stata that R cannot re-create. Details,
and the Stata evidence that pins it down, are below. Nothing here has been
tuned to the targets; the two estimators, the sample, the winsorising and the
variance convention were all verified against Stata independently.

**Tables reproduced:** Table 2, Panel A ("Funnel asymmetry tests indicate
publication bias" — linear FAT-PET, OLS and Precision columns, N = 927) and
Table 3 ("Caliper tests for different ranges of discount rate estimates" — all
four calipers, δ ∈ ⟨−0.5, 0.5⟩, ⟨−1, 1⟩, ⟨0.25, 0.75⟩, ⟨0.5, 1.5⟩, OLS and
Precision columns). Coefficient, standard error and N for every cell — 45
target numbers.

## Provenance

`discrate.do`, the authors' own code, is published on the site
(`web_meta/site/discrate/discrate.do`) and is the specification source here.
The relevant blocks:

- Lines 16–70 (data prep): a per-study standard error of the mean discount
  rate, `bootstrap mean=r(mean), reps(1000) strata(idstudy) seed(1234):
  summarize discrate_boot, detail`, run separately for each `idstudy` after
  `keep if idstudy==`i''`, stored as `study_se`.
- Lines 71–82 (construction): `local p = 0.05`; `winsor discrate,
  gen(discrate_win) p(0.05)`; `standard_error_comb = standard_error` where the
  primary study reports one, `= study_se` where it does not; then `winsor
  standard_error_comb, gen(standard_error_comb_win) p(0.05)`.
- Line 197: `ivreg2 discrate_win standard_error_comb_win, cluster(idstudy)` —
  the "OLS" column.
- Line 200: the same with `[pweight = 1/standard_error_comb_win]` — the
  "Precision" column.
- Lines 242–269: the same pair restricted to each caliper's range on
  `discrate_win` — Table 3's four blocks.

Mapped onto `stata_compat.R`: `ivreg2 y x, cluster(g)` → `st_ivreg2(y ~ x,
cluster = ~idstudy)`; `[pweight = 1/x]` → the same call with `weights =
~precision_comb_win`; `winsor v, gen(vw) p(p)` → `st_winsor(v, p)`; `if
<cond>` → `st_keep_if`. No Stata command outside the compat layer was needed.

## Data

`site/data/v1/discrate/discrate.csv` only — 927 rows, 56 studies. It is
column-for-column the published `site/discrate/discrate.dta`, which is the
dataset the do-file saves immediately after importing the raw workbook, i.e.
*before* the bootstrap block runs. Neither file carries `study_se`, and the
do-file `erase`s `boot_results.dta` at the end of the block, so the authors'
own bootstrap draw is not published anywhere on the site.

388 of the 927 rows (42%) have no reported `standard_error`. They fall in 19
of the 56 studies — 15 studies entirely, 4 partly — and for those rows
`standard_error_comb` is the bootstrapped `study_se`.

## What was verified in Stata, and what it shows

Stata 15.1 (with the same `winsor.ado` 1.3.0 and `ivreg2` 4.1.10 the authors
used) was run on the published `discrate.dta` with the do-file's own code,
bootstrap block included. Two things came out of it.

**1. The authors' pipeline reproduces the paper exactly.** Every one of the 45
printed numbers came back, to every digit the paper shows:

| | paper | Stata re-run |
|---|---|---|
| T2 A, OLS, SE | 0.535 (0.0299) | 0.5348941 (0.0298826) |
| T2 A, OLS, constant | 0.518 (0.114) | 0.5183024 (0.1136023) |
| T2 A, Precision, SE | 1.031 (0.449) | 1.030953 (0.4489677) |
| T2 A, Precision, constant | 0.259 (0.0373) | 0.2593017 (0.0373472) |
| T3 ⟨−0.5,0.5⟩, OLS, SE | 0.0919 (0.0367) | 0.0919024 (0.0367098) |
| T3 ⟨−1,1⟩, Precision, SE | 0.949 (0.409) | 0.9489009 (0.4094762) |
| T3 ⟨0.25,0.75⟩, OLS, SE | 0.0835 (0.0395) | 0.0834572 (0.0395294) |
| T3 ⟨0.5,1.5⟩, Precision, constant | 0.764 (0.0341) | 0.7638…&nbsp;(0.0341…) |

So the paper is internally reproducible, the published data is the right data,
and nothing in Table 2 or Table 3 is mis-specified in this package.

**2. The gap is entirely the bootstrap draw.** The Stata run's 56 `study_se`
values were extracted and fed into *this package's* R pipeline in place of the
R-computed ones, changing nothing else. The result: **43 of 45** targets match
— everything except two that cannot match under the checker's rounding rule
(see the last section). That isolates the discrepancy to a single vector of 19
numbers and clears every other step: the SSC-`winsor` order-statistic rule, the
`ivreg2`-without-`small` large-sample variance with z inference, the clustering
on `idstudy`, the pweighting, and all five samples (N = 927, 538, 717, 313,
244 all reproduce exactly).

## Why the bootstrap cannot be carried over to R

Stata's `bootstrap` resamples from its own generator. Its `runiform()` stream
*is* reproducible outside Stata — it is MT19937-64 with the standard
`init_genrand64` seeding and the 53-bit conversion, and an independent
implementation matches Stata's `set seed 1234` draws to the last bit
(0.947231616607804416, 0.052223374792334999, …). But `bsample`, which
`bootstrap` calls, does not consume that stream one draw per sampled index. It
first sorts the data by a random key (verified: the resampled rows come back in
the order of an ascending sort on the first *n* draws), then selects with
replacement in a way that does not match any of the obvious index mappings —
`floor(u·n)+1`, the high or low 32 bits, `mod n`, sorted-spacing search — at
any offset in the first 560 draws, nor does the resulting per-study SD match a
direct MT19937-64 resampling at any burn-in offset tried. Reproducing it would
mean reverse-engineering a closed-source built-in, and a guess that is *nearly*
right is worse than none: it would look authoritative and still be wrong.

The draw does not wash out at 1000 replications. The Monte Carlo error of a
bootstrap SD over 1000 replicates is about 2% of the quantity, and comparing
Stata's 19 relevant `study_se` values with their exact large-`reps` limit shows
differences from −2.6% to +4.1%. That is enough to move the third digit of most
coefficients in both tables — which is exactly what is observed.

Hard-coding the 56 numbers a Stata session produced would reach 43/45, and it
is deliberately not done: the site publishes no file containing them, so a
visitor could not obtain or check them, and constants smuggled in from another
tool are not a replication.

## What `run.R` does instead

It uses the **exact limit** of the authors' bootstrap rather than a fresh,
differently-seeded draw of it. Under case resampling the bootstrap distribution
of a sample mean has a closed form; its standard deviation is exactly
`sqrt(sum((x - xbar)^2)) / n`. That is the estimand `bootstrap … reps(1000)`
targets, computed without Monte Carlo error.

The alternative — running a 1000-replication bootstrap in R with `set.seed`
— was rejected on principle, not on score. It makes the package's output an
artefact of an arbitrary seed that has nothing to do with Stata's: across
seeds 1, 7, 42, 1234, 2024 and 99999 the number of matching targets ranged
from 24 to 32 out of 45. Picking the seed that scores best would be tuning the
code to the oracle. (For the record, seed 1234 — the do-file's seed, which
means nothing in R — gives 28, the same as the deterministic limit.)

## What reproduces (28/45)

All five sample sizes: N = 927, 538, 717, 313, 244.

Table 2 Panel A: OLS slope 0.535 and its SE 0.0299, the OLS constant's SE
0.114, the Precision constant 0.259 and its SE 0.0373.

Table 3, ⟨−0.5, 0.5⟩: OLS slope SE 0.0367, OLS constant 0.214 and its SE
0.0139, Precision constant 0.184 and its SE 0.0188. ⟨−1, 1⟩: OLS slope 0.205,
OLS constant 0.325 and its SE 0.0444, Precision constant SE 0.0313.
⟨0.25, 0.75⟩: everything except the two Precision slope figures — OLS slope
0.0835 and SE 0.0395, OLS constant 0.429 and SE 0.0351, Precision constant
0.371 and SE 0.0428. ⟨0.5, 1.5⟩: OLS slope 0.125 and SE 0.0126, OLS constant
0.801, Precision constant SE 0.0341.

## What does not (17/45)

Every miss is a third-digit miss driven by the 388 bootstrap-filled standard
errors, and the direction is systematic: the closed-form SEs run slightly
different from the authors' draw, so the funnel-asymmetry slope — the
coefficient *on* that variable — moves most, and the precision-weighted
column, where the same variable also sets the weights, moves more than OLS.

| target | paper | this package |
|---|---|---|
| T2 A OLS constant | 0.518 | 0.5188 |
| T2 A Precision slope (SE) | 1.031 (0.449) | 1.0334 (0.4515) |
| T3 ⟨−0.5,0.5⟩ OLS slope | 0.0919 | 0.0927 |
| T3 ⟨−0.5,0.5⟩ Precision slope (SE) | 0.473 (0.190) | 0.4772 (0.1920) |
| T3 ⟨−1,1⟩ OLS slope (SE) | 0.205 (0.0398) | 0.2056 (0.0393) |
| T3 ⟨−1,1⟩ Precision slope (SE) | 0.949 (0.409) | 0.9587 (0.4168) |
| T3 ⟨−1,1⟩ Precision constant | 0.232 | 0.2312 |
| T3 ⟨0.25,0.75⟩ Precision slope (SE) | 0.536 (0.288) | 0.5402 (0.2902) |
| T3 ⟨0.5,1.5⟩ OLS constant SE | 0.0295 (Stata 0.0295062) | 0.0295049 |
| T3 ⟨0.5,1.5⟩ Precision slope (SE) | 0.199 (0.0786) | 0.2011 (0.0799) |
| T3 ⟨0.5,1.5⟩ Precision constant | 0.764 | 0.7633 |

Largest relative error: 1.1% (⟨−1,1⟩ Precision slope). The sign, the
significance stars and every substantive conclusion in both tables are
unaffected.

Two of these deserve a footnote, because they would fail even with Stata's own
numbers in hand. The checker rounds both the printed value and the computed one
to three **decimal places**, while the paper prints three **significant
figures**. For `T3 ⟨0.5,1.5⟩ OLS constant SE` the paper prints 0.0295 and Stata
produces 0.0295062; at three decimals those are 0.029 and 0.030. The same
happens to `T3 ⟨0.25,0.75⟩ OLS slope` (paper 0.0835, Stata 0.0834572). Both are
correct to the digits the paper shows; the checker's rule cannot see it. Stata
reproduces all 45 printed values to the precision the paper prints them at, so
43/45 is the ceiling for any implementation measured this way — including one
handed Stata's own bootstrap numbers.

## What would close the gap

One file: the authors' `boot_results.dta` (or any export of its `store_stdevs`
column) — 56 numbers, one per study, of which 19 are actually used. The do-file
erases it. If it were published beside `discrate.dta`, this package would go to
43/45 with a three-line change and no other edit.
