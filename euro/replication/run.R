# euro -- "Rose Effect and the Euro: Is the Magic Gone?" (Review of World Economics 2010)
# Reproduces Table 1 (eurozone studies) and Table 2 (non-euro studies) FAT-PET rows:
# the funnel-asymmetry / precision-effect test (FAT-PET), i.e.
#   reg tstat prec if euro==1, vce(robust)     <- data.zip:trade_meta.do line 98
#   reg tstat prec if euro==0, vce(robust)     <- data.zip:trade_meta.do line 133
# tstat = gamma/se, prec = 1/se (line 86: `gen prec=1/se`).
#
# Also reproduces the paper's own headline claim in the text (abstract/Sect. 3): the euro's
# publication-bias-corrected effect (Table 1 PET) is insignificant (t=0.05), while the
# corrected effect for other currency unions (Table 2 PEESE) is 65-115% with 95% probability.
# See the "Numbers stated in the paper's text" block below for the exact quotes and mapping.
#
# ROBUST (Table 1/2 second column) is Stata `rreg` (iteratively re-weighted least-squares
# robust regression). stata_compat.R has no wrapper for `rreg` -- calling fixest/lm/MASS::rlm
# by hand would be picking an unreviewed convention, which is exactly what this whole
# tooling exists to prevent. So the ROBUST column is out of scope for this package; see
# REPLICATION_STATUS.md / unsupported_command.
#
# RIM/RCM (Table 1/2 third column, "random intercept/coefficients model ... restricted
# maximum likelihood") requires Stata `mixed`/`xtmixed`. No `mixed`/`xtmixed` call is visible
# anywhere in the author's code (data.zip:trade_meta.do stops at line
# 313 without one), so the exact model (which grouping variable, which regressors, ML vs
# REML) cannot be pinned to author code. Rather than guess a specification, this package
# omits RIM/RCM as well;.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/euro/replication/stata_compat.R")

data_path <- (if (file.exists("euro.csv")) "euro.csv" else
     "https://meta-analysis.cz/data/v1/euro/euro.csv")
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

## ---- Numbers stated in the paper's text (the headline claim) -----------------------------
# meta-analysis.cz summarises this paper as: "no detectable effect once publication bias is
# corrected, while other currency unions raise trade." The paper's own words:
#
#   Abstract: "The estimated underlying effect for currency unions other than the eurozone
#   reaches more than 60%. However, according to the meta-regression analysis, the euro's
#   trade promoting effect corrected for publication bias is insignificant."
#
#   Sect. 3 (eurozone): "For eurozone studies, the corresponding t-statistic is only 0.05
#   ... there is not even a slight trace of any true underlying Rose effect of the euro
#   beyond publication bias ... there is therefore no significant aggregate effect of the
#   euro on trade."
#
#   Sect. 3 (non-euro): "PEESE estimates the true Rose effect of currency unions other than
#   the eurozone to lie between 65 and 115% with 95% probability."
#
# gamma is a semi-elasticity (site convention, see brief), so a PERCENTAGE trade effect is
# 100*(exp(gamma)-1). In the PET/PEESE regressions (paper's eqs. 2-4), dividing the original
# gamma_i = beta + beta0*SE_i + mu_i through by SE_i turns the "true effect" beta into the
# coefficient on `prec` (=1/SE) of the transformed regression -- i.e. the "prec (effect)" row
# already printed in Table 1/2 above IS the publication-bias-corrected gamma. Its 95% CI is
# coef +/- qt(0.975, df)*se(coef); exponentiating turns both the point estimate and the CI
# into the percentage terms the text quotes.

pct_from_gamma <- function(g) 100 * (exp(g) - 1)

## -- Eurozone: the euro's PET-corrected effect is T1's "prec (effect)" row (m1/co1 above).
df1    <- stats::nobs(m1) - length(stats::coef(m1))
tcrit1 <- stats::qt(0.975, df1)
euro_pet_coef <- co1$estimate[co1$term == "prec"]
euro_pet_se   <- co1$std.error[co1$term == "prec"]
euro_pet_lo   <- euro_pet_coef - tcrit1 * euro_pet_se
euro_pet_hi   <- euro_pet_coef + tcrit1 * euro_pet_se

results$EURO_corrected_effect_pct        <- pct_from_gamma(euro_pet_coef)
results$EURO_corrected_effect_CI_lo_pct  <- pct_from_gamma(euro_pet_lo)
results$EURO_corrected_effect_CI_hi_pct  <- pct_from_gamma(euro_pet_hi)
results$EURO_corrected_effect_tstat      <- euro_pet_coef / euro_pet_se  # = T1_FATPET_prec_t; "only 0.05"

## -- Non-euro: PEESE row of Table 2, eq. (4): tstat = delta0*se + delta*(1/se), no constant
##    (delta = "prec (effect)" = the bias-corrected true effect). NOTE: the paper's own
##    footnote calls Table 2's t-statistics "Huber-White heteroskedasticity-robust", but the
##    printed PEESE t-stat of 9.83 only reproduces under the CLASSICAL (non-robust) WLS
##    variance -- the robust version of the identical regression gives t=6.20. We use
##    st_regress(..., robust = FALSE), which is what actually reproduces the table's printed
##    9.83 and hence the 65-115% quoted in the text; for the check.
mP  <- st_regress(tstat ~ se + prec - 1, data = d0, robust = FALSE)
coP <- st_coefs(mP, z = FALSE)
dfP    <- stats::nobs(mP) - length(stats::coef(mP))
tcritP <- stats::qt(0.975, dfP)
peese_coef <- coP$estimate[coP$term == "prec"]
peese_se   <- coP$std.error[coP$term == "prec"]
peese_lo   <- peese_coef - tcritP * peese_se
peese_hi   <- peese_coef + tcritP * peese_se

results$NONEURO_PEESE_prec_coef          <- peese_coef                      # Table 2 PEESE row, "0.634"
results$NONEURO_PEESE_prec_t             <- peese_coef / peese_se           # Table 2 PEESE row, "(9.83)"
results$NONEURO_corrected_effect_pct       <- pct_from_gamma(peese_coef)
results$NONEURO_corrected_effect_CI_lo_pct <- pct_from_gamma(peese_lo)      # "between 65 ..."
results$NONEURO_corrected_effect_CI_hi_pct <- pct_from_gamma(peese_hi)      # "... and 115%"

cat("\n==================== Numbers from the paper's text (headline claim) ====================\n")
cat(sprintf("Eurozone, corrected effect:   %.4f%% (95%% CI %.2f%% to %.2f%%), t = %.3f  [paper: 'no significant aggregate effect of the euro on trade', t = 0.05]\n",
            results$EURO_corrected_effect_pct, results$EURO_corrected_effect_CI_lo_pct,
            results$EURO_corrected_effect_CI_hi_pct, results$EURO_corrected_effect_tstat))
cat(sprintf("Non-euro, PEESE effect (raw gamma coef, t):  %.4f (%.2f)  [paper Table 2 PEESE row: 0.634 (9.83)]\n",
            results$NONEURO_PEESE_prec_coef, results$NONEURO_PEESE_prec_t))
cat(sprintf("Non-euro, corrected effect:   %.2f%% (95%% CI %.2f%% to %.2f%%)  [paper: 'between 65 and 115%% with 95%% probability']\n",
            results$NONEURO_corrected_effect_pct, results$NONEURO_corrected_effect_CI_lo_pct,
            results$NONEURO_corrected_effect_CI_hi_pct))
cat("===========================================================================================\n\n")

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
