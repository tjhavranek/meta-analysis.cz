# euro -- "Rose Effect and the Euro: Is the Magic Gone?" (Review of World Economics 2010)
# Reproduces Table 1 (eurozone studies) and Table 2 (non-euro studies) FAT-PET rows:
# the funnel-asymmetry / precision-effect test (FAT-PET), i.e.
#   reg tstat prec if euro==1, vce(robust)     <- data.zip:trade_meta.do line 98
#   reg tstat prec if euro==0, vce(robust)     <- data.zip:trade_meta.do line 133
# tstat = gamma/se, prec = 1/se (line 86: `gen prec=1/se`).
#
# ROBUST (Table 1/2 second column) is Stata `rreg` (iteratively re-weighted least-squares
# robust regression). stata_compat.R has no wrapper for `rreg` -- calling fixest/lm/MASS::rlm
# by hand would be picking an unreviewed convention, which is exactly what this whole
# tooling exists to prevent. So the ROBUST column is out of scope for this package; see
# REPLICATION.md / unsupported_command.
#
# RIM/RCM (Table 1/2 third column, "random intercept/coefficients model ... restricted
# maximum likelihood") requires Stata `mixed`/`xtmixed`. No `mixed`/`xtmixed` call is visible
# anywhere in the supplied author code (data.zip:trade_meta.do as excerpted stops at line
# 313 without one), so the exact model (which grouping variable, which regressors, ML vs
# REML) cannot be pinned to author code. Rather than guess a specification, this package
# omits RIM/RCM as well; see REPLICATION.md.

source("stata_compat.R")

data_path <- "C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\euro\\euro.csv"
d <- read.csv(data_path, stringsAsFactors = FALSE)

# gen prec=1/se   (trade_meta.do line 86, computed on the full sample before subsetting)
d$prec <- 1 / d$se

rmse <- function(m) {
  r <- stats::resid(m)
  k <- length(stats::coef(m))
  n <- length(r)
  sqrt(sum(r^2) / (n - k))
}

results <- list()

## ---- Table 1: eurozone studies (euro==1), FAT-PET ----------------------------------------
d1 <- st_keep_if(d, d$euro == 1)
m1 <- st_regress(tstat ~ prec, data = d1, robust = TRUE)
co1 <- st_coefs(m1, z = FALSE)

results$T1_FATPET_prec_coef  <- co1$estimate[co1$term == "prec"]
results$T1_FATPET_prec_t     <- co1$statistic[co1$term == "prec"]
results$T1_FATPET_const_coef <- co1$estimate[co1$term == "(Intercept)"]
results$T1_FATPET_const_t    <- co1$statistic[co1$term == "(Intercept)"]
results$T1_FATPET_N          <- stats::nobs(m1)
results$T1_FATPET_RMSE       <- rmse(m1)

## ---- Table 2: non-euro studies (euro==0), FAT-PET -----------------------------------------
d0 <- st_keep_if(d, d$euro == 0)
m0 <- st_regress(tstat ~ prec, data = d0, robust = TRUE)
co0 <- st_coefs(m0, z = FALSE)

results$T2_FATPET_prec_coef  <- co0$estimate[co0$term == "prec"]
results$T2_FATPET_prec_t     <- co0$statistic[co0$term == "prec"]
results$T2_FATPET_const_coef <- co0$estimate[co0$term == "(Intercept)"]
results$T2_FATPET_const_t    <- co0$statistic[co0$term == "(Intercept)"]
results$T2_FATPET_N          <- stats::nobs(m0)
results$T2_FATPET_RMSE       <- rmse(m0)

for (nm in names(results)) {
  cat(sprintf("%-22s %s\n", nm, format(results[[nm]], digits = 10)))
}

jsonify <- function(x) {
  vals <- vapply(x, function(v) {
    if (is.numeric(v)) format(v, digits = 15, scientific = FALSE) else paste0('"', v, '"')
  }, character(1))
  paste0("{\n", paste(sprintf('  "%s": %s', names(x), vals), collapse = ",\n"), "\n}\n")
}
writeLines(jsonify(results), "results.json")

stata_compat_log()
