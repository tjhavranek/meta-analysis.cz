# Replication package: finance_growth

**Paper**: Valickova, Havranek & Horvath, "Financial Development and Economic Growth:
A Meta-Analysis", *Journal of Economic Surveys* 29(3), 2015, doi 10.1111/joes.12068.

**Provenance**: `paper_methods_only`. No `.do` file ships with this paper. Table 1's
specification comes from the paper's methods text together with the cell formulas inside
the workbook the site itself publishes as `finance_growth.zip` -- that workbook is where
the CSV's `ft` and `seft` columns were built. Table 2's specification is the paper's own
sentence, "Estimated using the mixed-effects multilevel model", i.e. Stata's
`xtmixed tstat prec || idstudy:`.

**Tables reproduced**: Table 1 (partial correlation coefficients -- simple mean,
fixed-effect and random-effects means, each with a 95% CI) and Table 2 (Test of the True
Effect and Publication Bias -- the FAT-PET regression).

**Data**: `site/data/v1/finance_growth/finance_growth.csv`, 1334 rows, 67 studies.
Columns used: `ft`, `seft` (Fisher's z of the partial correlation and its standard
error), `pcc`, `tstat` (= pcc/sepcc), `prec` (= 1/sepcc), `idstudy`.

## Score

**14 of 16 targets reproduce** at the precision the paper prints. The two that do not are
Table 1's fixed-effect CI lower limit and Table 2's constant standard error. Both are one
unit off in the last printed digit, and this session established -- by running Stata 15.1
itself -- that neither is caused by the code in this package.

## Table 1 -- Summary statistics

| Target | Printed | Produced | Verdict |
|---|---|---|---|
| Simple (arithmetic) mean | 0.15 | 0.148398 -> 0.15 | match |
| Simple mean, CI lower | 0.10 | 0.097237 -> 0.10 | match |
| Simple mean, CI upper | 0.20 | 0.199559 -> 0.20 | match |
| Fixed-effect mean | 0.09 | 0.091904 -> 0.09 | match |
| Fixed-effect, CI lower | 0.088 | 0.0888067 -> 0.089 | **MISS** |
| Fixed-effect, CI upper | 0.095 | 0.0949997 -> 0.095 | match |
| Random-effects mean | 0.14 | 0.139612 -> 0.14 | match |
| Random-effects, CI lower | 0.129 | 0.128860 -> 0.129 | match |
| Random-effects, CI upper | 0.15 | 0.150332 -> 0.15 | match |

The simple mean is computed on the raw partial correlations with a study-clustered 95% CI
(`regress pcc, vce(cluster idstudy)`); Stata returns 0.1483978 with CI (0.0972369,
0.1995588), matching this package to seven digits.

The two inverse-variance means are computed on the Fisher-z scale and transformed back, as
the paper's Section 3 states: "Because the partial correlation coefficients are not
normally distributed, we use Fisher z-transformation to obtain a normal distribution of
effect sizes ... These z-transformed effect sizes are used for the computations and then
transformed back to partial correlation coefficients for reporting."

## Table 2 -- Test of the True Effect and Publication Bias

| Target | Printed | Produced | Verdict |
|---|---|---|---|
| Effect (coef. on 1/SE) | 0.199 | 0.198852 -> 0.199 | match |
| Effect, SE | 0.018 | 0.017578 -> 0.018 | match |
| Constant (bias) | -0.353 | -0.353306 -> -0.353 | match |
| Constant, SE | 0.422 | 0.422580 -> 0.423 | **MISS** |
| Within-study correlation | 0.46 | 0.460048 -> 0.46 | match |
| Observations | 1334 | 1334 | match |
| Studies | 67 | 67 | match |

## What changed in this pass

Table 1's Fisher-z inputs now come from the CSV's own `ft` and `seft` columns instead of
being rebuilt inside `run.R` from `pcc` and `sepcc`.

The earlier version derived the residual degrees of freedom as `df = (1-pcc^2)/sepcc^2`
and then formed `z = atanh(pcc)`, `SE(z) = 1/sqrt(df-3)`. That reasoning was sound, but it
was unnecessary: the site publishes the author's own workbook as `finance_growth.zip`, and
the per-study sheets in it compute exactly

```
ft   = 0.5*LN((1+H2)/(1-H2))       Fisher's z of the partial correlation
seft = 1/SQRT(P2-3-AO2-1)          P = sample size, AO = regressors, so P-AO-1 = df
pcc  = L2/SQRT(L2*L2+P2-AO2-1)     L = t-statistic
```

so `ft` and `seft` in the CSV are the author's own effect size and standard error, and the
reconstruction was re-deriving quantities that were already shipped. The two routes agree
to eight significant digits (Stata's fixed-effect limits: 0.08880674 / 0.09499966 from
`seft`, 0.08880747 / 0.09500043 from the reconstruction), so this changed no printed
result. It is a provenance fix, not a numerical one.

The two misses were left in place rather than chased. `targets.json` was not touched.
`stata_compat.R` was not touched.

## The two misses, diagnosed against Stata

Stata 15.1 was run directly on the site's published CSV. It agrees with this package, not
with the paper.

**Table 1, fixed-effect CI lower.** `metan ft seft, fixed` returns a pooled z of
0.09216416 with CI (0.08904132, 0.09528701); back-transformed with `tanh` that is
0.09190409 with CI (0.08880674, 0.09499966). R's `st_metan()` returns the same values to
ten digits. The point estimate prints as 0.09 and the upper limit as 0.095, both matching
the paper; the lower limit is 0.0888067, which rounds to 0.089, while the paper prints
0.088.

Everything that could plausibly move that limit was tested, and it moves the wrong way or
not at all:

| variant | fixed-effect mean and CI |
|---|---|
| `metan ft seft` (the published columns) | 0.09190 (0.08881, 0.09500) |
| `metan z sez` with df rebuilt from pcc/sepcc | 0.09190 (0.08881, 0.09500) |
| `metan z sez` with `SE(z) = 1/sqrt(samsize-3)` | 0.09323 (0.09018, 0.09628) |
| `metan pcc sepcc` (no z-transform at all) | 0.10488 (0.10184, 0.10791) |

The third row is the SE(z) formula the co-author's thesis text writes down (1/sqrt(N-3),
N the sample size); the workbook formula that actually produced the data is the df-based
one, and it is the one that reproduces the printed point estimate. The fourth row is what
an earlier version of this package did, and it is badly off.

The author's private `final_data.dta` (1334 x 143, not published) was run through the same
`metan` call as a control: it returns 0.09190409 (0.08880674, 0.09499966) -- identical to
the site's CSV. The site's data is faithful; the gap is not a data-version problem.

The same interval, 0.088 to 0.095, appears in the co-author's 2013 master's thesis, in the
August 2013 working-paper draft, and in the published article, so it is not a typesetting
error introduced late. The most economical reading is that 0.0888067 was written down as
0.088 rather than rounded to 0.089. Nothing in the data or the estimator produces 0.088,
and this package will not manufacture it.

**Table 2, constant SE.** `xtmixed tstat prec || idstudy:` in Stata returns coefficient
0.19885175 (SE 0.01757769) and constant -0.35330645 (SE 0.42258008). R's `st_mixed()`
returns 0.19885174 (SE 0.01757769) and -0.35330632 (SE 0.42257993) -- agreement to seven
digits. So the R fit is the correct one, Stata prints 0.423 here too, and the claim in the
previous version of this file that the miss was "a benign optimizer difference between
Stata mixed and lme4" was wrong.

Alternatives were checked in Stata:

| command | constant | constant SE | prints as |
|---|---|---|---|
| `xtmixed tstat prec, ML (the default)` | -0.353306 | 0.4225801 | 0.423 |
| `xtmixed tstat prec, reml` | -0.356556 | 0.4255061 | 0.426 |
| `xtreg tstat prec, mle` | -0.353306 | 0.4237465 | 0.424 |
| `xtreg tstat prec, re` | -0.342929 | 0.4149182 | 0.415 |

(each with `|| idstudy:` or `xtset idstudy` as appropriate). Only the default ML mixed
model reproduces the printed constant (-0.353), the printed slope (0.199), its printed SE
(0.018) and the printed within-study correlation (0.46) all at once. The paper's sentence
about restricted maximum likelihood does not describe the fit that produced these numbers:
REML moves the constant to -0.357, which the paper does not print. As in Table 1,
0.4225801 looks like it was written down as 0.422 instead of rounded to 0.423.

Both misses are therefore reported as unreachable, not worked around. No constant, no
widened tolerance, no dropped observation.

**Do not switch this package to `st_xtmixed()`.** The compat layer now carries a second
random-intercept wrapper, `st_xtmixed()`, which fits by REML on the argument that Stata 11's
`xtmixed` -- the command a 2013 paper would have run -- defaulted to REML while its Stata 13
replacement `mixed` defaults to ML. That may well be right for the papers it was added for,
but it is wrong here, and the wrong direction is worth stating explicitly because the paper's
own text mentions restricted maximum likelihood and invites the swap. Two things rule it out.
First, on Stata 15.1 in this session, `xtmixed tstat prec || idstudy:` with no options printed
"Mixed-effects **ML** regression" (probe2.log:140, probe5.log:61), and `, reml` had to be
requested explicitly to get REML (probe2.log:182). Second, and decisively, REML does not
reproduce the paper: it puts the constant at -0.356556, which prints as -0.357, while the paper
prints -0.353 -- exactly the ML value. ML matches three of Table 2's four estimated cells and
REML matches one. This package therefore uses `st_mixed()` (ML) on the evidence, not on the
paper's methods sentence.

## One inconsistency inside the paper, for the record

Table 1 prints the simple average's confidence interval as **(0.095, 0.20)**, while the
body text two paragraphs later says "The arithmetic mean yields a partial correlation
coefficient of 0.15 with a 95% confidence interval [0.1, 0.2]". The clustered CI is
(0.0972, 0.1996), which agrees with the text's two-digit [0.1, 0.2] but not with the
table's three-digit 0.095. `targets.json` records the text's value (0.10, two digits) and
this package matches it. The table cell's 0.095 is not reproducible from the published
data by any route tested above.

## Reproducing this diagnosis

The Stata probe do-files used for the checks above sit outside the package, in
`repl/stata_work_finance_growth/` (`probe1.do` to `probe5.do`). They are not part of the
published package. All of them read only the site's CSV, except `probe5.do`, which reads
the author's private `.dta` as a control and is not needed to run `run.R`.
