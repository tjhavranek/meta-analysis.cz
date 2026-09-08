# run.R -- replication package for meta-analysis.cz "finance_growth"
# Havranek & Valickova (Journal of Economic Surveys, 2015),
# "Financial Development and Economic Growth: A Meta-Analysis"
#
# PROVENANCE: no .do file ships with this paper. Table 1's specification comes from the
# paper's own methods text plus the cell formulas inside the workbook the site publishes
# as finance_growth.zip -- that workbook is where the CSV's `ft` and `seft` columns were
# built. Table 2's specification is the paper's own sentence, "Estimated using the
# mixed-effects multilevel model", which is Stata's `xtmixed tstat prec || idstudy:`.
# Provenance = "paper_methods_only".
#
# Reproduces:
#   Table 1. Summary statistics for the partial correlation coefficient (pcc):
#            simple (arithmetic) mean, fixed-effect (inverse-variance) mean,
#            random-effects (DerSimonian-Laird) mean, each with a 95% CI.
#   Table 2. Test of the True Effect and Publication Bias (FAT-PET), estimated
#            as a mixed-effects multilevel model of the t-statistic on the
#            estimate's precision (1/SE), with a random intercept by study.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/finance_growth/replication/stata_compat.R")

DATA_PATH <- (if (file.exists("finance_growth.csv")) "finance_growth.csv" else
     "https://meta-analysis.cz/data/v1/finance_growth/finance_growth.csv")

d <- read.csv(DATA_PATH, stringsAsFactors = FALSE)

results <- list()

emit <- function(label, value) {
  results[[label]] <<- value
  cat(sprintf("%-42s %s\n", label, format(value, digits = 10)))
}

cat("========================================================\n")
cat("Table 1: summary statistics for the partial correlation\n")
cat("========================================================\n")

d1 <- st_drop_if(d, is.na(d$pcc) | is.na(d$sepcc))
cat("N used for Table 1:", nrow(d1), "\n")

## --- Simple (arithmetic) mean, with a cluster-robust (by study) 95% CI ---
## `regress pcc, vce(cluster idstudy)` -- a constant-only regression clustered
## by study is the standard way an arithmetic mean's uncertainty is reported
## when many estimates per study are not independent.
m_simple <- st_regress(pcc ~ 1, data = d1, cluster = ~idstudy)
cf_simple <- st_coefs(m_simple, z = FALSE)
b <- cf_simple$estimate[cf_simple$term == "(Intercept)"]
se <- cf_simple$std.error[cf_simple$term == "(Intercept)"]
tcrit <- stats::qt(0.975, df = length(unique(d1$idstudy)) - 1)
emit("T1 simple (arithmetic) mean pcc", b)
emit("T1 simple mean CI lower", b - tcrit * se)
emit("T1 simple mean CI upper", b + tcrit * se)

## --- Fixed-effect and random-effects (inverse-variance weighted) means ---
## The paper is explicit that these are NOT computed on the raw pcc/sepcc scale:
##   "Because the partial correlation coefficients are not normally distributed, we use
##    Fisher z-transformation to obtain a normal distribution of effect sizes ... These
##    z-transformed effect sizes are used for the computations and then transformed back
##    to partial correlation coefficients for reporting."  (Section 3, around eq. 4)
##
## The published data already carries both pieces, so nothing has to be reconstructed:
##   ft   = Fisher's z of the partial correlation, 0.5*ln((1+r)/(1-r))
##   seft = its standard error, 1/sqrt(df - 3)
## Both columns are built in the author's own workbook, which the site itself publishes
## as finance_growth.zip; the cell formulas there read
##     ft   = 0.5*LN((1+H2)/(1-H2))
##     seft = 1/SQRT(P2-3-AO2-1)        (P = sample size, AO = number of regressors, so
##     pcc  = L2/SQRT(L2*L2+P2-AO2-1)    P-AO-1 = df and seft = 1/sqrt(df-3))
## so ft and seft are the author's own Fisher-z effect size and its standard error, used
## here exactly as shipped. (Rebuilding df from pcc and
## sepcc as df = (1-pcc^2)/sepcc^2; that route agrees with the published seft to eight
## significant digits and returns identical numbers, but reading the shipped columns is
## the faithful path and needs no derivation.)
##
## Estimator: `metan ft seft, fixed` / `, random` (DerSimonian-Laird), then transform the
## point estimate and both interval limits back to the correlation scale with r = tanh(z).
d1 <- st_drop_if(d1, is.na(d1$ft) | is.na(d1$seft))

fe <- st_metan(d1$ft, d1$seft, random = FALSE)
emit("T1 fixed-effect (inverse-variance) mean", tanh(as.numeric(fe$b)))
emit("T1 fixed-effect CI lower", tanh(as.numeric(fe$ci.lb)))
emit("T1 fixed-effect CI upper", tanh(as.numeric(fe$ci.ub)))
## KNOWN MISS. Table 1 prints the fixed-effect interval as (0.088, 0.095). The upper
## limit lands on 0.09499966 and prints as 0.095; the lower limit is 0.08880674, which
## rounds to 0.089, not 0.088. Stata's own `metan ft seft, fixed` on this same file
## returns 0.08880674 too, and so does the author's private final_data.dta, so the gap
## is not an R/Stata difference and not a data difference.

re <- st_metan(d1$ft, d1$seft, random = TRUE)
emit("T1 random-effects mean", tanh(as.numeric(re$b)))
emit("T1 random-effects CI lower", tanh(as.numeric(re$ci.lb)))
emit("T1 random-effects CI upper", tanh(as.numeric(re$ci.ub)))

cat("\n========================================================\n")
cat("Table 2: Test of the True Effect and Publication Bias\n")
cat("========================================================\n")

## The paper: "the response variable is the t-statistic of the estimated
## coefficient on financial development ... Estimated using the mixed-effects
## multilevel model." The regressor is the estimate's precision, 1/SE(pcc).
## In the data: tstat = pcc/sepcc (the t-statistic of the pcc), and
## prec = 1/sepcc (the precision). Random intercept by study (idstudy).
##   `mixed tstat prec || idstudy:`
d2 <- st_drop_if(d, is.na(d$tstat) | is.na(d$prec) | is.na(d$idstudy))
cat("N used for Table 2:", nrow(d2), "  studies:", length(unique(d2$idstudy)), "\n")

m2 <- st_mixed(tstat ~ prec + (1 | idstudy), data = d2)
sm2 <- summary(m2)
fx <- sm2$coefficients

emit("T2 Effect (coef on 1/SE)", fx["prec", "Estimate"])
emit("T2 Effect SE", fx["prec", "Std. Error"])
emit("T2 Constant (bias)", fx["(Intercept)", "Estimate"])
emit("T2 Constant SE", fx["(Intercept)", "Std. Error"])
## KNOWN MISS. Table 2 prints the constant's standard error as 0.422; the model returns
## 0.4225801, which rounds to 0.423. Stata's `xtmixed tstat prec || idstudy:` returns
## 0.42258008 on this file to eight digits, so the R fit is the right one. See
## REPLICATION_STATUS.md.

vc <- as.data.frame(lme4::VarCorr(m2))
icc <- vc$vcov[vc$grp == "idstudy"] / sum(vc$vcov)
emit("T2 Within-study correlation", icc)

emit("T2 Observations", nrow(d2))
emit("T2 Studies", length(unique(d2$idstudy)))

cat("\n")
stata_compat_log()

## ---------------------------------------------------------------- write out
results_out <- lapply(results, function(x) unname(as.numeric(x)))

write_json_simple <- function(lst, path) {
  esc <- function(s) gsub('"', '\\\\"', s)
  lines <- vapply(names(lst), function(nm) {
    sprintf('  "%s": %s', esc(nm), format(lst[[nm]], digits = 15, scientific = FALSE))
  }, character(1))
  writeLines(c("{", paste(lines, collapse = ",\n"), "}"), path)
}

## Write results.json next to this script, regardless of the working
## directory Rscript was launched from.
this_file <- commandArgs(trailingOnly = FALSE)
script_arg <- sub("^--file=", "", this_file[grepl("^--file=", this_file)])
script_dir <- if (length(script_arg)) dirname(normalizePath(script_arg)) else getwd()
out_file <- file.path(script_dir, "results.json")

write_json_simple(results_out, out_file)
cat("\nWrote results.json to", out_file, "\n")
