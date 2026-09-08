# Replication: skill

R code that regenerates the numbers this paper reports, from the data published on this site.

## Run it

    Rscript run.R

`run.R` is the whole package. It reads `skill.csv` if that file sits beside it and otherwise reads
it straight from meta-analysis.cz, and it loads `stata_compat.R` the same way, so the script also
runs on its own in an empty directory.

It needs R with `fixest`, and depending on the paper `lme4`, `metafor`, `plm`, `BMS` or
`LowRankQP`. It writes `results.json`: one value per number, named for where it appears in the
paper.

## What it reproduces

`REPLICATION_STATUS.md` lists every number, whether it reproduced, and where it did not, why.
That file is generated from this package's own output, so it cannot claim more than the code does.

## Files

- `run.R` -- the replication
- `stata_compat.R` -- Stata's estimation conventions, stated once and shared by every package on
  this site: `ivreg2`'s large-sample variance, SSC `winsor`'s order statistics, `xtreg`'s
  handling of singleton groups, `xtmixed`'s restricted-ML default
- `targets.json` -- the numbers as printed in the paper, recorded before the code was written
- `results.json` -- the numbers this code produced
- `REPLICATION_STATUS.md` -- the comparison

## Terms

Same as the rest of the site; see meta-analysis.cz.
