# Replication package: "Estimating Vertical Spillovers from FDI: Why Results Vary and What the True Effect Is"

Tomas Havranek & Zuzana Irsova, *Journal of International Economics* 85(2), 2011, pp. 234-244,
doi 10.1016/j.jinteco.2011.07.004.

Table reproduced: **Table 1**, "Test of publication bias and corrected spillover effect" —
Panels A (backward), B (forward) and C (horizontal), columns 1 ("All estimates") and
2 ("Published estimates"). Six regressions, six numbers each: the constant and its standard
error, the precision slope and its standard error, the number of observations and the number
of studies.

Run with:

```
Rscript run.R
```

Reads only `data/v1/spillovers/spillovers.csv` as published by meta-analysis.cz. Writes
`results.json` and prints every target to stdout. No manual steps.

## Score

**33 of 36 targets reproduce exactly.** All twelve coefficients and all twelve standard errors
match the printed values at the precision the paper prints them, as do all six study counts and
the three "All estimates" observation counts.

The three that miss are the observation counts in the *Published estimates* column, and the
reason is not in this code — see "The three misses" below.

## What the paper did

Table 1 estimates, separately for each spillover type,

```
t_ij = beta0 + e0 * (1/Se(e_ij)) + zeta_j + eps_ij
```

with a study-level random intercept. The site publishes the authors' own `Stata_program.do`,
and the relevant lines are these:

```stata
drop if aux==1
gen back = ((horiz==0 & forw==0) | (horiz==0 & local==1))
gen prec = 1/se
hadimvo e prec if back==1,  gen(oddb) p(.001)
hadimvo e prec if forw==1,  gen(oddf) p(.001)
hadimvo e prec if horiz==1, gen(oddh) p(.001)
gen odd = (oddb==1 | oddf==1 | oddh==1)
...
eststo: xtmixed t prec || idstudy: if back==1 & odd==0
eststo: xtmixed t prec || idstudy: if back==1 & odd==0 & pub==1
```

with the same pair repeated for `forw==1` and `horiz==1`. `run.R` follows that line for line.

Two things decide whether the table reproduces. Both were wrong in the previous version of this
package, which is why it scored 2 of 36 with every regression coefficient off.

### 1. The sample: three separate Hadi outlier passes, then their union

`odd` is not one outlier screen. It is the union of three independent runs of Stata's `hadimvo`
— Hadi's (1994) multivariate outlier identification on the two-dimensional (`e`, `prec`) cloud —
one per spillover type, each at `p(.001)`. Dropping that step entirely, as the previous version
did, leaves the raw subsamples of 1,402 / 1,067 / 1,205 observations where the paper reports
1,311 / 1,030 / 1,154, and every coefficient moves with them (the backward slope, for instance,
comes out 0.1038 instead of the printed 0.168).

`hadimvo_stata()` in `hadimvo_port.R` is a line-by-line port of `hadimvo.ado` v1.3.0, the version
frozen since Stata 8 and therefore the one the authors ran. Re-run here on Stata 15.1 against the
site's own published CSV, Stata reports 91 / 37 / 51 outliers in the three subsamples; the port
reports the same 91 / 37 / 51, and their union is 179 rows. Subtracting them gives 1,311 / 1,030
/ 1,154 — the paper's Table 1 exactly. The horizontal pass was also merged back into Stata and
compared flag by flag rather than only by count: 0 disagreements over all 1,205 rows.

One detail matters and is easy to get wrong in R. Stata leaves a `gen()`-ed flag **missing**
outside the `if` sample, and `oddb==1` is false for a missing value. So the union tests `== 1`
rather than `!= 0`; written the R way, `NA` would poison the whole expression.

### 2. The estimator: `xtmixed` was REML, and is not any more

`xtmixed` under Stata 11 — the version these authors ran in 2010 — fits by **restricted**
maximum likelihood by default. Stata 13 retired `xtmixed` and mapped the name onto `mixed`,
whose default is plain **ML**. Typing the authors' own command into a modern Stata therefore
gives a different estimator than it gave them, with no warning of any kind.

That is exactly what happens here. On Stata 15.1, against the site's published CSV:

```
. xtmixed t prec || idstudy: if back==1 & odd==0
Mixed-effects ML regression      ...      prec .1676064 (.0240909)   _cons -.0230852 (.4912891)

. version 11: xtmixed t prec || idstudy: if back==1 & odd==0
Mixed-effects REML regression    ...      prec .1679840 (.0241212)   _cons -.0254672 (.4959743)
```

The second line is the paper's 0.168 (0.0241) and −0.0255 (0.496). The first is not. The
version-11 run also matches the authors' own log of the published run cell for cell, and that log
likewise heads every block "Mixed-effects **REML** regression"; the paper's Table 1 note says the
model was "estimated by the mixed-effects multilevel model using restricted maximum likelihood".

The previous version of this package called `st_mixed()`, whose documented convention is
`lmer(REML = FALSE)` — correct for `mixed`, wrong for `xtmixed`. This version calls a new
`st_xtmixed()` wrapper, `lmer(REML = TRUE)`.

How much it matters, on the forward/published cell:

| | paper | REML (this package, and Stata) | ML |
|---|---|---|---|
| precision slope | 0.258 | 0.25773 | 0.25279 |
| its standard error | 0.0454 | 0.045415 | 0.044930 |
| constant | −0.437 | −0.43728 | −0.38743 |
| its standard error | 1.033 | 1.03323 | 0.99329 |

The ML column is out by one to two percent on the slope and eleven percent on the constant. It
would have survived a "within a few percent" check; it is simply the wrong estimator.

Both estimators were re-run in R and in Stata 15.1 and they agree to six decimals in each case,
so the R–Stata equivalence is checked in both directions, not only on the one that matches.

### Change to the shared compatibility layer

`stata_compat.R` gained one new function, `st_xtmixed()`. Nothing existing was touched:
`st_mixed()` keeps its `REML = FALSE` convention, so the nine other packages that call it see no
change at all. `test_compat.R` passes 10 of 10 afterwards, and the whole collection was re-run
through `verify_packages.py`; the `st_mixed()` users that were already clean still are (climate
31/31, gasoline_price 70/70).

Whether any of those nine packages *should* be calling `st_xtmixed()` instead is a real question
and not one this package can answer for them: it turns on which Stata command each author
actually typed, and that has to be read off each paper's own code. The distinction is now
available to them, documented, and tested.

## The three misses

`PanelA_Pub_N`, `PanelB_Pub_N` and `PanelC_Pub_N` do not reproduce, and cannot be reached
honestly:

| Panel | paper prints | this package, and the authors' own log | studies (both agree) |
|---|---|---|---|
| A backward, published | 370 | **378** | 26 |
| B forward, published | 241 | **249** | 19 |
| C horizontal, published | 305 | **321** | 27 |

The evidence that 378 / 249 / 321 is the sample the paper's own coefficients came from:

- Running `xtmixed t prec || idstudy: if back==1 & odd==0 & pub==1` reports `Number of obs = 378`
  and, in the same block, `prec .1781108 (.0294803)` and `_cons 1.083344 (.6561046)` — which is
  the paper's `0.178 (0.0295)` and `1.083 (0.656)`, to every digit printed. The same holds for
  the forward block at 249 observations and the horizontal block at 321.
- The study counts printed in the paper (26, 19, 27) are the study counts of the 378 / 249 / 321
  samples. Whatever produced 370 / 241 / 305 did not drop a study.
- No natural alternative filter yields those numbers. `pub==1` without the outlier screen gives
  401 / 263 / 352; with it, 378 / 249 / 321. Nothing in the do-file removes a further 8 / 8 / 16
  rows.

The three cells were typed by hand rather than generated. Table 1 is hand-written LaTeX (not
`esttab` output), and the same three values, 370 / 241 / 305, appear unchanged in the
working-paper draft and in every revision, while the coefficients around them changed. The
most likely reading is a stale transcription carried forward from an earlier run.

These are errors in the published table, not in this replication, and they are left missing
rather than papered over. `targets.json` records what the paper prints, which is what it is for.

## Not attempted

Column 3 of Table 1, "Homogeneous estimates". It is a real do-file line
(`... & local==0 & cs==0 & aggr==0 & comb==0 & more==0 & lin==0 & loglog==0`) and it reproduces,
but it is not in the frozen `targets.json` and this package does not add to that file.
