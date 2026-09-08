# bma — Determinants of Horizontal Spillovers from FDI

Havránek & Iršová, *What determines horizontal spillovers from FDI? Evidence from a large
meta-analysis*, **World Development** 42(1), 2013.

`run.R` reads only `site/data/v1/bma/bma.csv`, sources `stata_compat.R`, and writes
`results.json`.

**Score: 21 of 24 targets reproduce. Three do not, and they are all the same cell.**

---

## What the package reproduces

| Target | Paper | Produced |
|---|---|---|
| Table 4 col 1, Constant — coef / SE / p | 0.021 / 0.015 / 0.150 | 0.0214298 / 0.0146649 / 0.150068 |
| Table 4 col 1, Se (publication bias) — coef / SE / p | −0.325 / 0.262 / 0.220 | −0.325028 / 0.262003 / 0.220449 |
| Table 4 col 1, N | 1,199 | 1199 |
| Table 4 col 2, Constant — coef / SE / p | 0.021 / 0.015 / 0.183 | 0.0206846 / 0.0153147 / 0.182774 |
| Table 4 col 2, N | 1,199 | 1199 |
| Table 1, mean of *e* | −0.002 | −0.0022291 |
| `metan e se, fixed` | 0.017 | 0.0168957 |
| `metan e se, random` | −0.011 | −0.0106492 |
| Table 2 OLS check, Technology gap — coef / SE / p | −0.260 / 0.145 / 0.080 | −0.260321 / 0.144858 / 0.079877 |
| Table 2 OLS check, Fully owned — coef / SE / p | −0.104 / 0.057 / 0.077 | −0.103647 / 0.057075 / 0.076876 |
| Table 2 OLS check, N | 1,195 | 1195 |

## What it does not

| Target | Paper | Produced |
|---|---|---|
| Table 4 col 2, Se (publication bias) — coef / SE / p | −0.284 / 0.305 / 0.357 | not computed |

---

## How Table 4 is estimated

The table's note says the model is "estimated by weighted least squares with the precision
(the inverse of standard error) taken as the weight." The author's published do-file
(`site/bma/determinants.do`) never writes that as an `[aweight=]` regression. It builds
`prec = 1/se` (line 17) and, after `xtset idstudy`, runs

```stata
xtreg t prec, fe vce(cluster idstudy)                     // line 136 — column 1
xi: xtreg t prec i.idcountry, fe vce(cluster idstudy)     // line 137 — column 2
```

`t` is each estimate's own t-statistic, already a column in the published data. Dividing
`e = b0 + b1·se + u` through by `se` gives `t = b0·prec + b1 + u/se`, so regressing `t` on
`prec` *is* the precision-weighted regression of `e` on `se`, with no weight argument
anywhere. The printed rows therefore map as

* **Constant** = the coefficient on `prec`
* **Se (publication bias)** = the model's reported `_cons`

Column 1 reproduces to seven digits on both rows. Column 2's Constant row reproduces to all
three printed digits, p-value included.

*(An earlier version of this package claimed the do-file contained no estimation line for
column 2. That was wrong — line 137 is the line, and it is quoted above.)*

---

## Why column 2's "Se (publication bias)" cannot be reproduced

**Not a coding gap. The quantity is not identified by the data.**

42 countries appear in the estimation sample. 21 of the 42 country dummies are perfectly
collinear with the study fixed effects: a study covering exactly one country adds no country
variation of its own. Stata drops 21 of them — one as the `xi` base, 20 more "omitted because
of collinearity". The slope on `prec`, its clustered standard error and every fitted value are
invariant to *which* 21 are dropped. The split of the fit between `_cons` and the surviving
dummies is not, because `xtreg` reports `_cons` as `ȳ − x̄'β̂` taken over **all** regressors,
the dummies included. In this column the constant is a normalisation of the dropping order,
not an estimated quantity.

That is not an argument from theory. Three runs of the identical command on the identical data
give N = 1,199 and `prec` = 0.0206846 (0.0153147) every time, and three different constants:

| source | `_cons` | SE | p |
|---|---|---|---|
| the paper, Table 4 col 2 | **−0.284** | 0.305 | 0.357 |
| the authors' own Stata 11 log, 1 Aug 2011 | −0.2485 | 0.3185 | 0.439 |
| Stata 15.1 here, same command, same CSV | −0.0649 | 0.3099 | 0.835 |

Stata 11 omits `_Iidcountry_145` and `_155`; Stata 15.1 keeps those two and omits `_146` and
`_157` instead. Same fit, different constant. The paper matches neither, so its number comes
from a run earlier than the surviving log — `−0.284 / 0.305 / 0.357` is already in the
earliest conference-version LaTeX source of this table, and no other Stata log for the paper
exists on the author's disk.

Reordering the country dummies moves this constant across roughly (−0.77, +0.35); a sweep over
all 42 possible base categories, in both ascending and descending dummy order, produced values
from −0.768 to +0.352 without landing on −0.284 (nearest: −0.281 with SE 0.300, −0.300 with SE
0.307 — neither is the printed pair). Choosing an ordering *because* it output −0.284 would be
fitting the code to the oracle, so the three cells are reported as `null` and left to fail.

Everything else in the column is right, and the substantive claim the column supports — that
adding country fixed effects leaves the publication-bias coefficient small and insignificant —
holds under every normalisation tried.

---

## The fix in this revision: p-values for the Table 2 OLS check

Before this revision the package produced 0.072 for Technology gap against a printed 0.080,
and 0.069 for Fully owned against 0.077. The coefficients and standard errors were already
exact, so the defect was purely in the inference convention.

Stata's `regress y x, vce(cluster g)` reports **t on G − 1 degrees of freedom**, where G is the
number of clusters. Here G = 41 countries (four of the 1,199 rows have missing determinants and
drop out, taking one country with them), so df = 40. The authors' log confirms it: `F( 16, 40)`
and "Std. Err. adjusted for 41 clusters in idcountry".

The package had been reading p-values from `st_coefs()`, whose default is `z = TRUE` — a normal
approximation, i.e. df = ∞. On t = 1.797 that is the difference between 0.0723 and 0.0799;
small enough to look like rounding, and wrong. The p-values now come from
`summary(m)$coeftable`, which applies fixest's default small-sample rule (`t.df = "min"`, i.e.
G − 1) — Stata's rule, and the same one the Table 4 code was already using.

`stata_compat.R` was **not** modified. `st_coefs()` is a reporting helper, not an estimator; its
`z = FALSE` branch returns `NA` p-values rather than t-based ones, which is worth fixing
centrally at some point, but not from inside one package — the file is hash-locked and shared,
and the call site here has a correct alternative that costs nothing.

---

## Sample construction

From `determinants.do`, in order:

```stata
drop if aux==1        // line 14   4,147 → 3,626
drop if horiz!=1      // line 26   3,626 → 1,205   (keep horizontal spillovers)
drop if abs(e)>10     // line 123  1,205 → 1,199
gen prec=1/se         // line 17
```

`st_drop_if()` is used throughout, so missing values count as +∞ the way Stata treats them.
The Table 2 OLS check loses a further four rows to missing determinants, giving the paper's
stated 1,195 of 1,199.

## Variable mapping for Table 2

The do-file's line 143 lists regressors by Stata mnemonic; Table 2 lists them by label. The
mapping (`lngap` = Technology gap, `green` = Fully owned, `open/100` = Trade openness, and so
on) is not assumed — `run.R` prints a check of all 14 constructed variables against Table 1's
published means, and every one agrees (e.g. `green` 0.078 against Fully owned's 0.078; `lngap`
9.771 against Technology gap's 9.771).

## Reproducing

```
Rscript run.R
```

Needs `fixest`, `metafor`, `jsonlite`. Runs in a few seconds.
