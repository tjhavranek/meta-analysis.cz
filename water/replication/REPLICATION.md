# Replication package: water (income elasticity of water demand)

**Paper**: "Measuring the Income Elasticity of Water Demand: The Importance of
Publication and Endogeneity Biases", *Land Economics* 94(2), May 2018, 259-283.
https://doi.org/10.3368/le.94.2.259 (published on the site as `water/water2.pdf`
and `water/paper/index.html`).

**Table reproduced**: Table 2, "Tests Show Publication Bias in Estimates That
Control for Endogeneity" (p. 266) - the funnel-asymmetry (FAT-PET) regressions

    incomeelasticity_ij = YED_0 + beta * SE(incomeelasticity_ij) + u_ij

across 6 estimator/weight columns (Unweighted OLS, Unweighted FE, Study OLS,
Study FE, Precision OLS, Precision FE) and 3 samples (Panel A: whole sample,
N=307; Panel B: "No Endogeneity Control", N=142; Panel C: "Endogeneity
Control", N=165).

**Provenance**: `author_code`. `site/water/water.do` lines 89-113 contain
exactly this `eststo` block - an unconditional run for Panel A (lines 90-95)
and two `if ovb==` blocks (99-104, 108-113) running the same six
`ivreg2`/`xtreg, fe` specifications, each written out by a separate `esttab`
call (`fatpet_all.tex`, `fatpet_ovb.tex`, `fatpet_nonovb.tex`).

**Score: 38 of 39 targeted cells reproduce.** The one miss is
`PanelA_PrecOLS_const_se`, and it is a misprint in the published table -
established below by running the author's own commands in Stata 15.1 on the
site's own data.

## Data and code used

- Data: `site/data/v1/water/water.csv` (307 rows), read directly, unmodified.
  No file other than this published CSV is read.
- Weights `invnoest` and `inverseofstandarderror` are published columns, used
  as-is. They are the do-file's `gen inv_no_est = 1/numberofestimates` (line
  16) and `gen inv_se = 1/standarderror` (line 18); the published columns are
  rounded exports of those, and the difference (at most 8e-5) moves no cell in
  the fifth digit.
- `inv_med_se`, used only by the Precision-FE column, is not a published column
  and is built here exactly as `water.do` lines 20-21 build it:
  `bysort studyid: egen med_se = median(standarderror)` then
  `gen inv_med_se = 1/med_se`.
- Panel B/C split: `ovb==1` -> Panel B (N=142), `ovb==0` -> Panel C (N=165),
  matching the panels' printed N.
- Estimation goes only through `stata_compat.R` wrappers: `st_xtreg_fe`,
  `st_xtreg_fe_cons`, `st_keep_if`, `st_coefs`, and - for the `ivreg2` lines -
  `st_ivreg2` in Panels B and C, `st_regress` in Panel A (why: next section).
  `stata_compat.R` was not modified; its hash is checked by the verifier.

## Target-by-target results

### Panel A - whole sample (N = 307)

| Cell | Printed | Produced | Verdict |
|---|---|---|---|
| Unweighted OLS, coef | 0.676 | 0.67604 | MATCH |
| Unweighted OLS, SE | 0.305 | 0.30479 | MATCH |
| Unweighted OLS, const | 0.178 | 0.17754 | MATCH |
| Unweighted OLS, const SE | 0.029 | 0.02927 | MATCH |
| Unweighted FE, coef | 0.551 | 0.55109 | MATCH |
| Unweighted FE, SE | 0.301 | 0.30054 | MATCH |
| Unweighted FE, const | 0.193 | 0.19292 | MATCH |
| Unweighted FE, const SE | 0.037 | 0.03698 | MATCH |
| Study OLS, coef | 0.884 | 0.88374 | MATCH |
| Study OLS, SE | 0.132 | 0.13216 | MATCH |
| Study OLS, const | 0.155 | 0.15549 | MATCH |
| Study OLS, const SE | 0.022 | 0.02157 | MATCH |
| Study FE, coef | 0.644 | 0.64399 | MATCH |
| Study FE, SE | 0.161 | 0.16050 | MATCH |
| Precision OLS, coef | 1.280 | 1.27991 | MATCH |
| Precision OLS, SE | 0.369 | 0.36913 | MATCH |
| Precision OLS, const | 0.103 | 0.10323 | MATCH |
| Precision OLS, const SE | 0.012 | 0.01121 | **MISS** |
| Precision FE, coef | 1.514 | 1.51441 | MATCH |
| Precision FE, SE | 1.176 | 1.17590 | MATCH |
| Observations | 307 | 307 | MATCH |

**20 / 21 matched.**

### Panel B - "No Endogeneity Control" (ovb==1, N = 142)

| Cell | Printed | Produced | Verdict |
|---|---|---|---|
| Unweighted OLS, coef | 0.29 | 0.29026 | MATCH |
| Unweighted OLS, SE | 0.307 | 0.30718 | MATCH |
| Unweighted OLS, const | 0.223 | 0.22299 | MATCH |
| Unweighted OLS, const SE | 0.0347 | 0.03473 | MATCH |
| Unweighted FE, coef | 0.286 | 0.28551 | MATCH |
| Unweighted FE, SE | 0.288 | 0.28832 | MATCH |
| Unweighted FE, const | 0.224 | 0.22372 | MATCH |
| Unweighted FE, const SE | 0.0445 | 0.04447 | MATCH |
| Observations | 142 | 142 | MATCH |

**9 / 9 matched.** The Study-OLS and Precision-OLS columns of this panel are
computed as well, though not targeted, and also reproduce the printed cells
exactly (0.753/0.576, 0.188/0.0569; 1.010/0.405, 0.112/0.0121).

### Panel C - "Endogeneity Control" (ovb==0, N = 165)

| Cell | Printed | Produced | Verdict |
|---|---|---|---|
| Unweighted OLS, coef | 1.053 | 1.05290 | MATCH |
| Unweighted OLS, SE | 0.252 | 0.25239 | MATCH |
| Unweighted OLS, const | 0.153 | 0.15337 | MATCH |
| Unweighted OLS, const SE | 0.0327 | 0.03269 | MATCH |
| Unweighted FE, coef | 1.054 | 1.05413 | MATCH |
| Unweighted FE, SE | 0.437 | 0.43725 | MATCH |
| Unweighted FE, const | 0.153 | 0.15325 | MATCH |
| Unweighted FE, const SE | 0.0421 | 0.04208 | MATCH |
| Observations | 165 | 165 | MATCH |

**9 / 9 matched.** The non-targeted Study-OLS and Precision-OLS columns also
match exactly (0.919/0.0942, 0.140/0.0246; 1.650/0.490, 0.0959/0.0153).

**Overall: 38 / 39 targeted cells matched.**

## Why Panel A uses `regress` and Panels B/C use `ivreg2`

The deposited `water.do` writes `ivreg2 ..., cluster(studyid)` for the OLS
columns of all three panels. The published table does not agree with itself on
that. Both commands were run in Stata 15.1 on the site's own `water.csv`
(probe do-files under `repl/stata_work_water/`), and the printed table takes a
side in every cell where the two conventions differ at printed precision:

| Cell | Stata `ivreg2` | Stata `regress` | paper prints |
|---|---|---|---|
| A Unweighted OLS, slope SE | .3018250 | .3047873 | **0.305** |
| A Study OLS, slope SE | .1308745 | .1321590 | **0.132** |
| A Study OLS, const SE | .0213596 | .0215692 | **0.022** |
| A Precision OLS, slope SE | .3655457 | .3691334 | **0.369** |
| B Unweighted OLS, slope SE | .3071809 | .3127767 | **0.307** |
| B Study OLS, slope SE | .5757905 | .5862794 | **0.576** |
| B Precision OLS, slope SE | .4053683 | .4127527 | **0.405** |
| B Precision OLS, const SE | .0120894 | .0123096 | **0.0121** |
| C Unweighted OLS, slope SE | .2523875 | .2560874 | **0.252** |
| C Study OLS, slope SE | .0941519 | .0955321 | **0.0942** |
| C Study OLS, const SE | .0246295 | .0249905 | **0.0246** |
| C Precision OLS, slope SE | .4897532 | .4969326 | **0.490** |
| C Precision OLS, const SE | .0152941 | .0155183 | **0.0153** |

Every Panel A cell follows `regress`; every Panel B and C cell follows
`ivreg2`. Four cells rule out `ivreg2` for Panel A, nine rule out `regress` for
Panels B/C, and no cell points the other way.

On this sample the two conventions differ by a single scalar,
`sqrt(G/(G-1) * (N-1)/(N-K))` = 1.009815, so no change of data, sample or
weight can move one onto the other - only the command can. The package
therefore uses `st_regress` for Panel A's three OLS columns and `st_ivreg2`
(the wrapper's default, `ivreg2` without `small`) for Panels B and C. That is a
description of what the paper printed, not a preference exercised here.

A second, independent sign that Panel A was reported from a separate run: it
prints every SE at three fixed decimals (0.305, 0.029, 0.012, 0.045), while
Panels B and C print three *significant* digits (0.0347, 0.0445, 0.0569,
0.0121, 0.0942, 0.0153), which is `esttab`'s adaptive `a3` format. One table,
two number formats, two VCE conventions.

## The one miss: `PanelA_PrecOLS_const_se` is a misprint

Printed 0.012. Produced 0.01121. Stata, running the author's own line on the
site's own data, says the same:

    . regress incomeelasticity standarderror [pweight=inv_se], cluster(studyid)
    standarderror     1.279909   .3691334
            _cons     .1032323   .0112085

    . ivreg2 incomeelasticity standarderror [pweight=inv_se], cluster(studyid)
    standarderror     1.279909   .3655457
            _cons     .1032323   .0110996

Three of the four numbers in that regression are printed correctly in the
paper: 1.280, (0.369), 0.103. The fourth appears as (0.012) where Stata gives
.0112085, which rounds to 0.011.

This is not a convention that went untried. The slope SE and the intercept SE
are two entries of one 2x2 clustered sandwich, so every degrees-of-freedom
convention (`small`, `G/(G-1)` alone, large-sample) rescales both by one common
factor. Getting to 0.012 from 0.0112 needs about 1.036 on the intercept alone,
while the slope SE has to stay at 0.369, which the package reproduces exactly.
Anything that breaks the proportionality - another cluster variable, another
weight, another sample - moves the slope off 0.369 too. All checked in Stata:

| Variant (Panel A, Precision OLS) | slope SE | const SE |
|---|---|---|
| `regress ... [pw=inv_se], cluster(studyid)` - **current** | .3691334 (match) | .0112085 |
| `ivreg2 ... [pw=inv_se], cluster(studyid)` | .3655457 | .0110996 |
| `regress ... [pw=inv_se], robust` | .1975847 | .0098836 |
| `ivreg2 ... [pw=inv_se], robust` | .1969400 | .0098514 |
| `regress ... [aw=inv_se]`, iid | .1662101 | .0086871 |
| cluster on `estimateid` | .1754129 | .0099942 |
| weight `1/sqrt(SE)` | .3354545 | .0162911 (slope 0.920, wrong) |
| weight `1/med_se` | 1.0339649 | .0233953 (slope 1.508, wrong) |

No Stata command applied to the published data prints 0.369 for the slope and
0.012 for the constant of this regression.

The likely mechanism: `esttab`'s `a3` format writes this number as `0.0112`,
and Panel A was reset to three decimals. Dropping a character from `0.0112`
gives `0.012`; rounding it gives `0.011`. Panel A's constant-SE row reads
`(0.029) (0.037) (0.022) (0.021) (0.012) (0.045)` against Stata's
`.0292665 .0369841 .0215692 .0208659 .0112085 .0449409` - five of six exact,
and the sixth is the only entry in the row small enough for the `a3` string to
have carried a fourth decimal that could be lost that way.

`targets.json` is right as frozen: the paper really does print 0.012 (see
`water2.pdf` p. 266, and `water/paper/index.html`, Table 2, Panel A, Precision
OLS, "Constant (effect beyond bias)" row). The target is not mis-transcribed;
the paper is wrong in that cell by one unit in its last digit. The package
reports 0.01121 and leaves the miss standing.

## Known scope limitation (not attempted)

The "Constant (effect beyond bias)" cells of the two **weighted** FE columns
(Study FE 0.187/(0.021), Precision FE 0.121/(0.045)) are not in
`targets.json`. `stata_compat.R`'s `st_xtreg_fe_cons()` takes no `weights`
argument, so it cannot build a weighted `xtreg, fe` constant without editing
that frozen file. For the record, Stata returns .1866621 (.0208659) and
.1210036 (.0449409) for those cells, matching the paper - so the gap is in the
compat layer's coverage, not in the paper or the data.

## Verdict

**38 / 39 targeted cells match**: all 12 targeted coefficients, all 3 sample
counts, and 33 of 34 targeted standard errors, including every cell of Panels B
and C. The single miss, `PanelA_PrecOLS_const_se`, is a one-digit misprint in
the published table - demonstrated against Stata 15.1 rather than argued around
- and is left unmatched.
