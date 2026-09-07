# run.R -- replication package for meta-analysis.cz "house_prices"
#
# Paper: "When Does Monetary Policy Sway House Prices? A Meta-Analysis"
#        IMF Economic Review 2023, doi 10.1057/s41308-022-00185-5
#
# Reproduces Table 1, PANEL A (Linear models): the regression of reported estimates
# on their standard errors (FAT-PET test), by OLS and by WLS (weights proportional to
# inverse variance), separately at each of the six impulse-response horizons
# (1, 2, 4, 8, 12, 16 quarters after a monetary policy shock).
#
# Author Stata code (house.do), lines actually executed (not inside /* */):
#   41   use house_prices.dta, clear
#   44   replace est = 100*est
#   45   gen se_avg = (SE_l + SE_u)/2
#   46   replace se_avg = 100*se_avg
#   47   gen prec_avg = 1/se_avg
#   48   gen t_avg = est/se_avg
#   112  keep if inlevels==1
#   162  xtset idstudy
#   164  eststo: ivreg2 est SE                  if            horizon==1,  cluster(idstudy idcountry)
#   167  eststo: ivreg2 est SE                  if t>-50   &  horizon==2,  cluster(idstudy idcountry)
#   170  eststo: ivreg2 est SE                  if t>-50   &  horizon==4,  cluster(idstudy idcountry)
#   173  eststo: ivreg2 est SE                  if t>-50   &  horizon==8,  cluster(idstudy idcountry)
#   176  eststo: ivreg2 est SE                  if t>-50   &  horizon==12, cluster(idstudy idcountry)
#   179  eststo: ivreg2 est SE                  if t>-50   &  horizon==16, cluster(idstudy idcountry)
#   186  eststo: ivreg2 est SE [pweight=prec]   if t>-50   &  horizon==1,  cluster(idstudy idcountry)
#   189..201  (same, weighted, for horizon 2/4/8/12/16)
#
# Two variables used downstream (`SE`, `prec`) are never `gen`-erated verbatim in the
# extracted line list -- only `se_avg` (line 45-46) and `prec_avg` (line 47) are. The
# extraction dropped non-substantive lines (labels, esttab/outreg formatting, renames),
# and `SE`/`prec` are the only candidates with the right units and role, so we take
# SE == se_avg and prec == prec_avg (i.e. a `rename se_avg SE` / `rename prec_avg prec`
# happened between lines 48 and 162 and was not captured). Likewise `t` in the `if t>-50`
# filters is taken to be `t_avg` (line 48) under the same reasoning.
#
# This assumption is LOW-STAKES here: in the published data, t_avg never falls below
# -50 (min t_avg ~= -9.66), so the `t>-50` filter never actually removes an observation.
# The unfiltered "N used" for horizon==1 (no filter in the author code) and the
# t>-50-filtered N for horizons 2/4/8/12/16 come out identical either way, and match the
# paper's printed "Observations" row (222, 227, 237, 237, 232, 226) exactly -- see
# REPLICATION.md for the verification.
#
# ivreg2 with no instrument, no `small`, is OLS with the large-sample (z-based, no
# small-sample df correction) two-way-clustered variance -- exactly st_ivreg2()'s
# convention below.

source("stata_compat.R")

data_path <- "C:/Users/thavr/Dropbox/Study/Other/Agents/Joint/web_meta/site/data/v1/house_prices/house_prices.csv"
d <- read.csv(data_path, stringsAsFactors = FALSE)

# line 112: keep if inlevels==1
d <- st_keep_if(d, d$inlevels == 1)

# lines 44-48
d$est    <- 100 * d$est
d$se_avg <- 100 * (d$SE_l + d$SE_u) / 2
d$SE     <- d$se_avg                # assumed rename, see header note
d$prec   <- 1 / d$se_avg            # assumed rename, see header note
d$t      <- d$est / d$se_avg        # assumed rename, see header note

horizons <- c(1, 2, 4, 8, 12, 16)
results <- list()

for (h in horizons) {
  sub <- if (h == 1) {
    d[d$horizon == h, ]
  } else {
    st_keep_if(d, d$t > -50 & d$horizon == h)
  }

  m_ols <- st_ivreg2(est ~ SE, data = sub, cluster = ~idstudy + idcountry)
  m_wls <- st_ivreg2(est ~ SE, data = sub, cluster = ~idstudy + idcountry,
                      weights = sub$prec)

  co_ols <- st_coefs(m_ols)
  co_wls <- st_coefs(m_wls)

  tag <- paste0("T1_h", h, "_")
  results[[paste0(tag, "OLS_SE_coef")]]    <- co_ols$estimate[co_ols$term == "SE"]
  results[[paste0(tag, "OLS_SE_se")]]      <- co_ols$std.error[co_ols$term == "SE"]
  results[[paste0(tag, "OLS_const_coef")]] <- co_ols$estimate[co_ols$term == "(Intercept)"]
  results[[paste0(tag, "OLS_const_se")]]   <- co_ols$std.error[co_ols$term == "(Intercept)"]

  results[[paste0(tag, "WLS_SE_coef")]]    <- co_wls$estimate[co_wls$term == "SE"]
  results[[paste0(tag, "WLS_SE_se")]]      <- co_wls$std.error[co_wls$term == "SE"]
  results[[paste0(tag, "WLS_const_coef")]] <- co_wls$estimate[co_wls$term == "(Intercept)"]
  results[[paste0(tag, "WLS_const_se")]]   <- co_wls$std.error[co_wls$term == "(Intercept)"]

  results[[paste0(tag, "N")]] <- stats::nobs(m_ols)
}

# Notes to Table 1 (continued): "The mean uncorrected effect at the 8-quarter horizon was -1.2."
sub8 <- d[d$horizon == 8 & !is.na(d$est), ]
results[["T1_h8_mean_uncorrected"]] <- mean(sub8$est)

cat("\n================ PRODUCED RESULTS ================\n")
for (nm in names(results)) {
  cat(sprintf("%-28s = %s\n", nm, format(results[[nm]], digits = 8)))
}

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("jsonlite is required to write results.json (install.packages('jsonlite'))")
}
jsonlite::write_json(results, "results.json", auto_unbox = TRUE, digits = NA, pretty = TRUE)
cat("\nWrote results.json\n")

stata_compat_log()
