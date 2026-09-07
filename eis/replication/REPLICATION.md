# Replication package: Havránek (2015), "Measuring Intertemporal Substitution:
# The Importance of Method Choices and Selective Reporting", JEEA

**Table reproduced:** Table 2, "Explaining the differences in the reported
estimates of the EIS" — all seven columns (1)-(7), the rows SE, Micro data,
and Asset holders (coefficient and standard error each), the column-(1)
constant (EIS0), N and study count, and the four derived quantities the
paper's prose quotes from column (1) (the corrected elasticity for micro
studies, the corrected elasticity for micro asset holders, and its 95% CI).

## Provenance

The task brief said no author code ships with this paper. That is true of the
package handed to this task, but an author `.do` file for this exact paper
(`eis.do`, dated February 6, 2013, "PUBLICATION BIAS IN MEASURING
INTERTEMPORAL SUBSTITUTION") turned up already extracted in the working
scratch tree from earlier processing of the paper's zip
(`scratchpad/eiswork/eis/eis.do`). It is used here as the specification
source — provenance is **author code**, not the paper's methods section
alone. The paper's own printed numbers (targets.json) still come only from
the paper text, per the brief.

The relevant block is "EXPLAINING HETEROGENEITY":

```stata
gen prec = 1/se
gen tstat = eis/se
... (log transforms, noyearfe construction) ...
gen invperstudy = 1/perstudy
foreach x of varlist `rhsvars' {
    gen `x'_se = `x' / se
}
eststo: reg tstat prec micro_se stockhold_se [pweight=invperstudy], vce(cluster idstudy)
eststo: reg tstat prec micro_se stockhold_se seprisk_se habits_se sepdur_se sepgov_se septrd_se [pweight=invperstudy], vce(cluster idstudy)
... (columns 3-7 add further cumulative blocks of _se controls) ...
```

This is the levels model `EIS = EIS0 + beta*SE + sum(gamma_k * X_k) + u`
divided through by `SE` to homogenize the error variance (the standard
FAT-PET-MRA transform): `tstat = beta + EIS0*prec + sum(gamma_k * X_k/se) + v`.
So in the transformed regression the **intercept** is the paper's "SE"
(publication-bias) row, the coefficient on **prec** is the paper's constant
(EIS0, "a negligible EIS beyond the bias for macro studies"), and the
coefficients on `micro_se` / `stockhold_se` are the paper's "Micro data" /
"Asset holders" rows. Weights are `1/perstudy` (inverse of the number of
estimates reported by the study — exactly what the paper's prose says), and
standard errors are clustered by `idstudy`, matching "I do not use fixed
effects as I need both between- and within-study variation."

Mapped onto `stata_compat.R`, `reg y x [pweight=w], vce(cluster g)` is
`st_regress(fml, data, cluster = ~idstudy, weights = ~invperstudy)` — no
other wrapper is involved, and no unsupported Stata command was needed for
this table.

## Sample

Full sample, no filter: all 2,735 estimates from 169 studies (verified
against `perstudy` — the per-study count column matches `table(idstudy)`
exactly, and no relevant column has missing, zero, or negative values that
would break the log transforms used in later columns), matching the paper's
reported N = 2,735 and 169 studies.

## Target-by-target results

All targets are deterministic (OLS/WLS point estimates, standard errors, a
delta-method linear combination, and counts — nothing bootstrapped or
seed-dependent).

| Label | Printed | Produced (full precision) | Verdict |
|---|---:|---:|---|
| T2 col1 SE coef | 2.465 | 2.465089 | MATCH |
| T2 col1 SE se | 0.394 | 0.394230 | MATCH |
| T2 col1 Micro coef | 0.200 | 0.200064 | MATCH |
| T2 col1 Micro se | 0.0250 | 0.024983 | MATCH |
| T2 col1 Asset coef | 0.136 | 0.135878 | MATCH |
| T2 col1 Asset se | 0.0303 | 0.030341 | MATCH |
| T2 col1 Constant (EIS0) | 0.0237 | 0.023702 | MATCH |
| T2 col1 N | 2735 | 2735 | MATCH |
| T2 col1 Studies | 169 | 169 | MATCH |
| T2 col2 SE coef | 1.926 | 1.926300 | MATCH |
| T2 col2 SE se | 0.251 | 0.251070 | MATCH |
| T2 col2 Micro coef | 0.209 | 0.208765 | MATCH |
| T2 col2 Micro se | 0.0308 | 0.030779 | MATCH |
| T2 col2 Asset coef | 0.174 | 0.174224 | MATCH |
| T2 col2 Asset se | 0.0365 | 0.036462 | MATCH |
| T2 col3 SE coef | 1.864 | 1.863539 | MATCH |
| T2 col3 SE se | 0.243 | 0.242858 | MATCH |
| T2 col3 Micro coef | 0.269 | 0.268686 | MATCH |
| T2 col3 Micro se | 0.0495 | 0.049464 | MATCH |
| T2 col3 Asset coef | 0.195 | 0.195373 | MATCH |
| T2 col3 Asset se | 0.0626 | 0.062618 | MATCH |
| T2 col4 SE coef | 2.109 | 2.108906 | MATCH |
| T2 col4 SE se | 0.268 | 0.267988 | MATCH |
| T2 col4 Micro coef | 0.350 | 0.350182 | MATCH |
| T2 col4 Micro se | 0.0986 | 0.098561 | MATCH |
| T2 col4 Asset coef | 0.189 | 0.189472 | MATCH |
| T2 col4 Asset se | 0.0565 | 0.056542 | MATCH |
| T2 col5 SE coef | 1.975 | 1.974697 | MATCH |
| T2 col5 SE se | 0.261 | 0.261405 | MATCH |
| T2 col5 Micro coef | 0.476 | 0.476356 | MATCH |
| T2 col5 Micro se | 0.0854 | 0.085361 | MATCH |
| T2 col5 Asset coef | 0.228 | 0.227879 | MATCH |
| T2 col5 Asset se | 0.0482 | 0.048217 | MATCH |
| T2 col6 SE coef | 1.961 | 1.961071 | MATCH |
| T2 col6 SE se | 0.262 | 0.262157 | MATCH |
| T2 col6 Micro coef | 0.502 | 0.502018 | MATCH |
| T2 col6 Micro se | 0.0865 | 0.086468 | MATCH |
| T2 col6 Asset coef | 0.236 | 0.235677 | MATCH |
| T2 col6 Asset se | 0.0460 | 0.046046 | MATCH |
| T2 col7 SE coef | 1.809 | 1.808657 | MATCH |
| T2 col7 SE se | 0.248 | 0.248083 | MATCH |
| T2 col7 Micro coef | 0.430 | 0.429747 | MATCH |
| T2 col7 Micro se | 0.106 | 0.105804 | MATCH |
| T2 col7 Asset coef | 0.316 | 0.316187 | MATCH |
| T2 col7 Asset se | 0.0586 | 0.058562 | MATCH |
| T2 col7 N | 2735 | 2735 | MATCH |
| T2 col7 Studies | 169 | 169 | MATCH |
| Corrected elasticity, micro (col1) | 0.22 | 0.223767 | MATCH |
| Corrected elasticity, micro asset holders (col1) | 0.36 | 0.359645 | MATCH |
| 95% CI lower, micro asset holders (col1) | 0.33 | 0.327613 | MATCH |
| 95% CI upper, micro asset holders (col1) | 0.39 | 0.391678 | MATCH |

**51 / 51 targets matched.** No misses, no repairs were needed.

## What was NOT attempted, and why

Table 3 (the IV/Proxy x FE/Pooled funnel-asymmetry robustness table) was left
out of the target set on purpose. Three of its four columns reduce to
`ivreg2`/`regress`-style commands this site's wrapper set already covers, but
column 1 ("IV FE") is the author's `xtivreg tstat (prec = invsqrtnobs), fe` —
an instrumented **and** fixed-effects estimator in one command. `stata_compat.R`
has `st_ivreg2` (IV, no FE) and `st_xtreg_fe` (FE, no IV) but no wrapper that
combines both, and the brief forbids picking the "closest looking" estimator
for an unsupported command. Rather than build partial coverage of a
secondary robustness table around one unsupported cell, this package scopes
to Table 2 — the paper's own headline result, the one that carries the
reporting-bias coefficient, the corrected elasticities, and the confidence
interval quoted in the abstract and conclusion — and reproduces all of it.

## Files

- `targets.json` — the oracle, frozen before `run.R` was written.
- `run.R` — sources `stata_compat.R`, reads
  `data/v1/eis/eis.csv`, builds the seven cumulative WLS specifications via
  `st_regress`, and writes `results.json`.
- `results.json` — produced values, full precision.
