# run.R -- replication of Irsova & Havranek (2020, JIE), Table 2
# "Estimating the Armington Elasticity: The Importance of Study Design and Publication Bias"
#
# Reproduces Panel A (Unweighted OLS, Fixed effects) and Panel B, row 1 (Weighted by the
# inverse of the number of estimates per study) of Table 2, plus the three N's shared by the
# table (All / Short-run / Long-run).
#
# Not attempted (see REPLICATION.md): Hierarchical Bayes (Panel A row 3 -- Gibbs sampler for a
# hierarchical linear model, following Rossi et al. 2005; no wrapper exists and the paper reports
# posterior standard deviations, not standard errors), Panel B row 2 "weighted by the inverse of
# the standard error" (the author's line is `ivreg2 tstats_w invse_w, cluster(idstudy)` -- a
# t-statistic-on-precision regression whose coefficients are NOT the ones printed in that row of
# Table 2, so the printed cells cannot be read off it), and Panel C's nonlinear estimators
# WAAP / Andrews-Kasy / Furukawa (no wrapper; WAAP would additionally need a raw `quantile()`
# call, which stata_compat.R forbids). None of those rows is in targets.json.
#
# THE TWO `robust` CONVENTIONS IN THE AUTHOR'S .DO FILE, both now handled:
#
# 1. `ivreg2 y x, robust` (short-run OLS, and short-run weighted OLS). Without `small`, ivreg2's
#    robust variance is HC0 -- the plain sandwich, with NO (N-1)/(N-K) factor -- and inference is
#    z-based. That is exactly fixest's "hetero" vcov under the large-sample ssc that st_ivreg2
#    already installs, which is what the note inside stata_compat.R records ("heteroskedastic,
#    where fixest with adj = FALSE is already ivreg2's HC0"). So the model is fitted with the
#    wrapper and only its vcov is switched to "hetero"; the ssc, the weights and the point
#    estimates all stay the wrapper's. Verified against Stata 15.1 on the site's own published
#    CSV (stata_work_armington/probe1.do):
#        ivreg2 armel_w se_w if srun==1, robust
#            Stata  se_w .082595774015   _cons .024903172290
#            here   se_w .082595774015   _cons .024903172290
#        ivreg2 armel_w se_w if srun==1 [pweight=invnobs_short], robust
#            Stata  se_w .072138331707   _cons .082115246107
#            here   se_w .072138331707   _cons .082115246107
#    Stata's `regress ..., robust` is NOT a substitute: it is HC1 with t inference and returns
#    .082744729545, which prints as 0.0827 against the paper's 0.0826.
#
# 2. `xtreg y x, fe vce(robust)` (short-run FE). For xtreg,fe Stata's vce(robust) IS the
#    cluster-robust estimator clustered on the panel variable -- the two are the same command.
#    Same probe, same data, byte-identical output:
#        xtreg armel_w se_w if srun==1, fe vce(robust)     se_w .104212974140  _cons .019190181907
#        xtreg armel_w se_w if srun==1, fe cluster(idstudy) se_w .104212974140  _cons .019190181907
#    so st_xtreg_fe()/st_xtreg_fe_cons(), which cluster on the panel variable, are already right
#    and no special handling is needed.
#
# ONE TARGET IS NOT REACHED, and it is not an estimation problem: T2_wols_invnobs_long_const_coef.
# The paper prints 1.134. Running the author's own line in Stata 15.1 on this same data gives
# _cons = 1.134784556951 (stata_work_armington/probe2.do), which rounds to 1.135; this code gives
# 1.134784562, the same number. Its standard error (0.168) and both other cells of that row match
# the paper exactly, as do the other 35 printed values. The paper's cell is one unit off in the
# third decimal of its own estimate. Nothing here is adjusted to hit it.


if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/armington/replication/stata_compat.R")

data_path <- (if (file.exists("armington.csv")) "armington.csv" else
     "https://meta-analysis.cz/data/v1/armington/armington.csv")
d <- read.csv(data_path, stringsAsFactors = FALSE)

## ---- construct the inverse-count weights used in the author's .do file (lines 13-15) --------
d$invnobs       <- 1 / d$nobs
d$invnobs_short <- 1 / d$nobs_short
d$invnobs_long  <- 1 / d$nobs_long

## ---- samples: All / Short-run (srun==1) / Long-run (srun==0) --------------------------------
d_all   <- d
d_short <- st_keep_if(d, d$srun == 1)
d_long  <- st_keep_if(d, d$srun == 0)

results <- list()
put <- function(label, value) results[[label]] <<- value

put("T2_N_all",   nrow(d_all))
put("T2_N_short", nrow(d_short))
put("T2_N_long",  nrow(d_long))

## ================================================================================ Panel A: OLS
## eststo: ivreg2 armel_w se_w, cluster(idstudy idcountry)                     -- All
## eststo: ivreg2 armel_w se_w if srun==1, robust                              -- Short-run
## eststo: ivreg2 armel_w se_w if srun==0, cluster(idstudy idcountry)          -- Long-run

m_ols_all <- st_ivreg2(armel_w ~ se_w, data = d_all, cluster = ~idstudy + idcountry)
c_ols_all <- st_coefs(m_ols_all)
put("T2_ols_all_se_coef",    c_ols_all$estimate[c_ols_all$term == "se_w"])
put("T2_ols_all_se_se",      c_ols_all$std.error[c_ols_all$term == "se_w"])
put("T2_ols_all_const_coef", c_ols_all$estimate[c_ols_all$term == "(Intercept)"])
put("T2_ols_all_const_se",   c_ols_all$std.error[c_ols_all$term == "(Intercept)"])

# short-run: `robust`, i.e. ivreg2's HC0 sandwich with z inference. The model is fitted by the
# wrapper (large-sample ssc, no small-sample factor anywhere); only the vcov is switched from
# the iid default to "hetero", which under that ssc IS ivreg2's HC0 -- see note 1 at the top of
# this file for the Stata digits both sides agree on.
m_ols_short <- st_ivreg2(armel_w ~ se_w, data = d_short, cluster = NULL)
c_ols_short <- st_coefs(summary(m_ols_short, vcov = "hetero"))
put("T2_ols_short_se_coef",    c_ols_short$estimate[c_ols_short$term == "se_w"])
put("T2_ols_short_se_se",      c_ols_short$std.error[c_ols_short$term == "se_w"])
put("T2_ols_short_const_coef", c_ols_short$estimate[c_ols_short$term == "(Intercept)"])
put("T2_ols_short_const_se",   c_ols_short$std.error[c_ols_short$term == "(Intercept)"])

m_ols_long <- st_ivreg2(armel_w ~ se_w, data = d_long, cluster = ~idstudy + idcountry)
c_ols_long <- st_coefs(m_ols_long)
put("T2_ols_long_se_coef",    c_ols_long$estimate[c_ols_long$term == "se_w"])
put("T2_ols_long_se_se",      c_ols_long$std.error[c_ols_long$term == "se_w"])
put("T2_ols_long_const_coef", c_ols_long$estimate[c_ols_long$term == "(Intercept)"])
put("T2_ols_long_const_se",   c_ols_long$std.error[c_ols_long$term == "(Intercept)"])

## ================================================================================= Panel A: FE
## eststo: xtreg armel_w se_w, fe cluster(idstudy)                     -- All
## eststo: xtreg armel_w se_w if srun==1, fe vce(robust)               -- Short-run
## eststo: xtreg armel_w se_w if srun==0, fe cluster(idstudy)          -- Long-run

m_fe_all  <- st_xtreg_fe(armel_w ~ se_w, data = d_all, panel = "idstudy")
c_fe_all  <- st_coefs(m_fe_all)
cons_fe_all <- st_xtreg_fe_cons("armel_w", "se_w", "idstudy", d_all)
c_cons_fe_all <- st_coefs(cons_fe_all)
put("T2_fe_all_se_coef",    c_fe_all$estimate[c_fe_all$term == "se_w"])
put("T2_fe_all_se_se",      c_fe_all$std.error[c_fe_all$term == "se_w"])
put("T2_fe_all_const_coef", c_cons_fe_all$estimate[c_cons_fe_all$term == "(Intercept)"])
put("T2_fe_all_const_se",   c_cons_fe_all$std.error[c_cons_fe_all$term == "(Intercept)"])

# short-run: `vce(robust)`. For xtreg,fe that option is not a non-clustered HC vcov at all --
# Stata computes the cluster-robust (Arellano) variance on the panel variable, and prints
# "Std. Err. adjusted for 8 clusters in idstudy" when asked for it. `fe vce(robust)` and
# `fe cluster(idstudy)` return identical output on this sample (note 2 at the top of this file),
# so the wrappers' default clustering on the panel variable is already the right convention.
m_fe_short <- st_xtreg_fe(armel_w ~ se_w, data = d_short, panel = "idstudy")
c_fe_short <- st_coefs(m_fe_short)
cons_fe_short <- st_xtreg_fe_cons("armel_w", "se_w", "idstudy", d_short)
c_cons_fe_short <- st_coefs(cons_fe_short)
put("T2_fe_short_se_coef",    c_fe_short$estimate[c_fe_short$term == "se_w"])
put("T2_fe_short_se_se",      c_fe_short$std.error[c_fe_short$term == "se_w"])
put("T2_fe_short_const_coef", c_cons_fe_short$estimate[c_cons_fe_short$term == "(Intercept)"])
put("T2_fe_short_const_se",   c_cons_fe_short$std.error[c_cons_fe_short$term == "(Intercept)"])

m_fe_long  <- st_xtreg_fe(armel_w ~ se_w, data = d_long, panel = "idstudy")
c_fe_long  <- st_coefs(m_fe_long)
cons_fe_long <- st_xtreg_fe_cons("armel_w", "se_w", "idstudy", d_long)
c_cons_fe_long <- st_coefs(cons_fe_long)
put("T2_fe_long_se_coef",    c_fe_long$estimate[c_fe_long$term == "se_w"])
put("T2_fe_long_se_se",      c_fe_long$std.error[c_fe_long$term == "se_w"])
put("T2_fe_long_const_coef", c_cons_fe_long$estimate[c_cons_fe_long$term == "(Intercept)"])
put("T2_fe_long_const_se",   c_cons_fe_long$std.error[c_cons_fe_long$term == "(Intercept)"])

## ============================================================ Panel B, row 1: weighted by 1/nobs
## eststo: ivreg2 armel_w se_w [pweight=invnobs], cluster(idstudy idcountry)                 -- All
## eststo: ivreg2 armel_w se_w if srun==1 [pweight=invnobs_short], robust                    -- Short-run
## eststo: ivreg2 armel_w se_w if srun==0 [pweight=invnobs_long], cluster(idstudy idcountry) -- Long-run

m_w_all <- st_ivreg2(armel_w ~ se_w, data = d_all, cluster = ~idstudy + idcountry,
                      weights = ~invnobs)
c_w_all <- st_coefs(m_w_all)
put("T2_wols_invnobs_all_se_coef",    c_w_all$estimate[c_w_all$term == "se_w"])
put("T2_wols_invnobs_all_se_se",      c_w_all$std.error[c_w_all$term == "se_w"])
put("T2_wols_invnobs_all_const_coef", c_w_all$estimate[c_w_all$term == "(Intercept)"])
put("T2_wols_invnobs_all_const_se",   c_w_all$std.error[c_w_all$term == "(Intercept)"])

# same `robust` = HC0 convention as the unweighted short-run row above. Stata's [pweight] and
# [aweight] give the same point estimates here; what pweight changes is the variance, and
# ivreg2's robust sandwich under pweights is the same weighted HC0 fixest computes.
m_w_short <- st_ivreg2(armel_w ~ se_w, data = d_short, cluster = NULL,
                        weights = ~invnobs_short)
c_w_short <- st_coefs(summary(m_w_short, vcov = "hetero"))
put("T2_wols_invnobs_short_se_coef",    c_w_short$estimate[c_w_short$term == "se_w"])
put("T2_wols_invnobs_short_se_se",      c_w_short$std.error[c_w_short$term == "se_w"])
put("T2_wols_invnobs_short_const_coef", c_w_short$estimate[c_w_short$term == "(Intercept)"])
put("T2_wols_invnobs_short_const_se",   c_w_short$std.error[c_w_short$term == "(Intercept)"])

m_w_long <- st_ivreg2(armel_w ~ se_w, data = d_long, cluster = ~idstudy + idcountry,
                       weights = ~invnobs_long)
c_w_long <- st_coefs(m_w_long)
put("T2_wols_invnobs_long_se_coef",    c_w_long$estimate[c_w_long$term == "se_w"])
put("T2_wols_invnobs_long_se_se",      c_w_long$std.error[c_w_long$term == "se_w"])
put("T2_wols_invnobs_long_const_coef", c_w_long$estimate[c_w_long$term == "(Intercept)"])
put("T2_wols_invnobs_long_const_se",   c_w_long$std.error[c_w_long$term == "(Intercept)"])

## --------------------------------------------------------------------------------- report ----
cat("\n===== produced values =====\n")
for (nm in names(results)) {
  cat(sprintf("%-32s %s\n", nm, format(results[[nm]], digits = 8)))
}

writeLines(
  jsonlite::toJSON(results, auto_unbox = TRUE, na = "null", digits = NA),
  "results.json"
)

cat("\n")
stata_compat_log()
