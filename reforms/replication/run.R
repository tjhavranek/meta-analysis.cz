# run.R -- replication of Havranek & Irsova-style "Structural Reforms and Growth in
# Transition: A Meta-Analysis" (Economics of Transition, 2014), Table 3 (Test of publication
# bias). Reproduces only what the author's own reform.do computes for that table; no estimator
# substitutions.
#
# Author code (verbatim, from site/reforms/reform.do -- the brief's "x"/`/* */` markings turned
# out to flag lines the automated scan could not execute stand-alone, e.g. because they call
# SSC-installed commands (metan, rreg) or Stata `foreach`/`local` machinery, NOT that the do-file
# has them commented out. The plain-text reform.do on disk carries none of these lines inside a
# comment block, and it matches the brief's line list 1:1. Provenance is therefore genuine
# author code.):
#
#   gen pcor = lib/sqrt(lib*lib+df)
#   gen pcor_cum = lib_cum/sqrt(lib_cum*lib_cum+df)
#   gen se_pcor = sqrt((1-pcor*pcor)/df)
#   gen se_pcor_cum = sqrt((1-pcor_cum*pcor_cum)/df)
#   gen se1_pcor = 1/se_pcor
#   gen se1_pcor_cum = 1/se_pcor_cum
#   gen odd = 1 if se1_pcor>15 & pcor>0.3 & lib<12
#   reg lib se1_pcor if rg!=0 & lib<12 & odd!=1                          -- Short run, Fixed
#   reg lib_cum se1_pcor_cum if rg!=0 & lib_cum<7.5                      -- Long run, Fixed
#   rreg lib se1_pcor if rg!=0 & lib<12 & odd!=1                         -- Short run, Robust
#   rreg lib_cum se1_pcor_cum if rg!=0 & lib_cum<7.5                     -- Long run, Robust
#   reg lib se1_pcor if rg!=0 & lib<12 & odd!=1, vce(cluster study)      -- Short run, Clustered
#   reg lib_cum se1_pcor_cum if rg!=0 & lib_cum<7.5, vce(cluster study)  -- Long run, Clustered
#
# "lib" is the primary study's t-statistic on the reform variable (not itself a partial
# correlation): pcor = lib/sqrt(lib^2+df) is the textbook t -> partial-correlation identity, so
# lib = pcor*sqrt(df)/sqrt(1-pcor^2) = pcor/se_pcor. Consequently OLS of lib on se1_pcor=1/se_pcor
# is algebraically identical to WLS of pcor on se_pcor with weights 1/se_pcor^2 -- exactly the
# "'Fixed' ... weighted least squares ... weighted by the inverse of the standard error of the
# partial correlation coefficient" the paper's Table 3 note describes. No separate weights
# argument is needed; the transform IS the weighting.
#
# The table's "Publication bias (coef. beta0)" row is the INTERCEPT of `reg lib se1_pcor`
# (equivalently `reg lib_cum se1_pcor_cum`); the "Effect beyond bias (Constant)" row is the SLOPE
# on se1_pcor / se1_pcor_cum. See the derivation just above the `results <- list(...)` block.
#
# UNSUPPORTED: Stata's `rreg` (iteratively re-weighted robust regression, Cook's-distance
# pre-filter + Huber then biweight iterations) has no wrapper in stata_compat.R and is not one
# of feols/lm/rma/lmer/plm/quantile, so it cannot be built from an allowed primitive either.
# Per the brief, this is reported as an unresolved miss for the two "Robust" columns rather than
# improvised with rlm() or similar.

source("stata_compat.R")

library(jsonlite)

data_path <- "C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\reforms\\reforms.csv"
d <- read.csv(data_path, stringsAsFactors = FALSE)

stopifnot(all(c("lib", "lib_cum", "df", "rg", "study") %in% names(d)))

# ---- generate partial correlations and their standard errors (verbatim from reform.do) -------
d$pcor         <- d$lib     / sqrt(d$lib * d$lib         + d$df)
d$pcor_cum     <- d$lib_cum / sqrt(d$lib_cum * d$lib_cum + d$df)
d$se_pcor      <- sqrt((1 - d$pcor * d$pcor)         / d$df)
d$se_pcor_cum  <- sqrt((1 - d$pcor_cum * d$pcor_cum) / d$df)
d$se1_pcor     <- 1 / d$se_pcor
d$se1_pcor_cum <- 1 / d$se_pcor_cum

# "strange observations (outliers)": gen odd = 1 if se1_pcor>15 & pcor>0.3 & lib<12
d$odd <- ifelse(!is.na(d$se1_pcor) & !is.na(d$pcor) & !is.na(d$lib) &
                   d$se1_pcor > 15 & d$pcor > 0.3 & d$lib < 12, 1, NA)

# ---- Stata missing-value semantics for the "if" filters ---------------------------------------
# In Stata, missing is treated as +infinity, so e.g. `lib<12` is FALSE when lib is missing, and
# `rg!=0` / `odd!=1` are TRUE when rg / odd are missing (a missing value is never equal to a
# non-missing number). Build each comparison with the +Inf substitution so this holds, then hand
# the fully-resolved logical vector to st_keep_if.
inf_if_na <- function(x) ifelse(is.na(x), Inf, x)

cond_rg      <- inf_if_na(d$rg)  != 0
cond_lib     <- inf_if_na(d$lib) < 12
cond_odd     <- inf_if_na(d$odd) != 1
cond_libcum  <- inf_if_na(d$lib_cum) < 7.5

short_df <- st_keep_if(d, cond_rg & cond_lib & cond_odd)
long_df  <- st_keep_if(d, cond_rg & cond_libcum)

cat(sprintf("Short-run sample: N = %d\n", nrow(short_df)))
cat(sprintf("Long-run sample:  N = %d\n", nrow(long_df)))

# ---- FAT-PET regressions -----------------------------------------------------------------------
m_short_fixed <- st_regress(lib ~ se1_pcor, data = short_df)
m_long_fixed  <- st_regress(lib_cum ~ se1_pcor_cum, data = long_df)

m_short_clust <- st_regress(lib ~ se1_pcor, data = short_df, cluster = ~study)
m_long_clust  <- st_regress(lib_cum ~ se1_pcor_cum, data = long_df, cluster = ~study)

c_short_fixed <- st_coefs(m_short_fixed, z = FALSE)
c_long_fixed  <- st_coefs(m_long_fixed,  z = FALSE)
c_short_clust <- st_coefs(m_short_clust, z = FALSE)
c_long_clust  <- st_coefs(m_long_clust,  z = FALSE)

get_est <- function(cf, term) cf$estimate[cf$term == term]
get_se  <- function(cf, term) cf$std.error[cf$term == term]

# NOTE on which term is which: transforming the WLS regression pcor = b_PET + b_pub*se_pcor + e
# (weights 1/se_pcor^2) by dividing through by se_pcor gives
#   lib = pcor/se_pcor = b_PET*(1/se_pcor) + b_pub + u,
# i.e. in `reg lib se1_pcor`, the INTERCEPT is the funnel-asymmetry / publication-bias
# coefficient (b_pub, Table 3's "Publication bias (coef. beta0)"), and the SLOPE on se1_pcor is
# the precision-effect estimate of the true effect (b_PET, Table 3's "Effect beyond bias
# (Constant)" row -- named for what it estimates, the effect once bias is netted out, not for
# being literally Stata's _cons).
results <- list(
  pb_short_fixed_coef     = get_est(c_short_fixed, "(Intercept)"),
  pb_short_fixed_se       = get_se(c_short_fixed,  "(Intercept)"),
  pb_short_robust_coef    = NA,  # rreg -- unsupported (no wrapper), see notes
  pb_short_robust_se      = NA,
  pb_short_clustered_coef = get_est(c_short_clust, "(Intercept)"),
  pb_short_clustered_se   = get_se(c_short_clust,  "(Intercept)"),

  pb_long_fixed_coef      = get_est(c_long_fixed, "(Intercept)"),
  pb_long_fixed_se        = get_se(c_long_fixed,  "(Intercept)"),
  pb_long_robust_coef     = NA,
  pb_long_robust_se       = NA,
  pb_long_clustered_coef  = get_est(c_long_clust, "(Intercept)"),
  pb_long_clustered_se    = get_se(c_long_clust,  "(Intercept)"),

  eff_short_fixed_coef     = get_est(c_short_fixed, "se1_pcor"),
  eff_short_fixed_se       = get_se(c_short_fixed,  "se1_pcor"),
  eff_short_robust_coef    = NA,
  eff_short_robust_se      = NA,
  eff_short_clustered_coef = get_est(c_short_clust, "se1_pcor"),
  eff_short_clustered_se   = get_se(c_short_clust,  "se1_pcor"),

  eff_long_fixed_coef      = get_est(c_long_fixed, "se1_pcor_cum"),
  eff_long_fixed_se        = get_se(c_long_fixed,  "se1_pcor_cum"),
  eff_long_robust_coef     = NA,
  eff_long_robust_se       = NA,
  eff_long_clustered_coef  = get_est(c_long_clust, "se1_pcor_cum"),
  eff_long_clustered_se    = get_se(c_long_clust,  "se1_pcor_cum"),

  n_short_fixed     = nobs(m_short_fixed),
  n_short_robust    = NA,
  n_short_clustered = nobs(m_short_clust),
  n_long_fixed      = nobs(m_long_fixed),
  n_long_robust     = NA,
  n_long_clustered  = nobs(m_long_clust)
)

for (nm in names(results)) {
  cat(sprintf("%-26s = %s\n", nm, format(results[[nm]])))
}

stata_compat_log()

write(toJSON(results, auto_unbox = TRUE, na = "null", digits = 10),
      file = "results.json")
