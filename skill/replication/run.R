# run.R -- replication of Havranek et al. "Publication and Attenuation Biases in Measuring
# Skill Substitution" (Review of Economics and Statistics 2024), Table 1.
#
# Reproduces the FE and IV columns of Table 1 (Panels A/B/C = OLS-method, IV-method and
# natural-experiment subsamples), all of which are estimated on the coefficient
# (negative-inverse-elasticity) transform of the raw estimates, per skill.do lines 16-51 and
# 159-228. The BE, EK and SM columns of the printed table use estimators with no wrapper in
# stata_compat.R (between-effects `xtreg ... be`, the Bom-Rachinger endogenous-kink method, and
# the Andrews-Kasy selection model) and are out of scope -- see REPLICATION.md.

source("stata_compat.R")

data_path <- "C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\skill\\skill.csv"
d <- read.csv(data_path, stringsAsFactors = FALSE)

stopifnot(nrow(d) == 1097)

## ---------------------------------------------------------------------- skill.do lines 16-18
## coefficient = -1/elasticity ; se_coefficient = se/elasticity^2 (delta method), computed on
## the raw imported elasticity/se for every row.
d$coefficient    <- -1 / d$elasticity
d$se_coefficient <- d$se / (d$elasticity^2)

## ---------------------------------------------------------------- skill.do lines 29-35 (kept)
## coefficient_new / se_coefficient_new: valid only where inverted_estimate == 1, else missing
## (elasticity_new/se_new, the inverted_estimate==0 branch, are not needed for Table 1: every
## panel in Table 1 filters on inverted_estimate==1).
coefficient_new    <- ifelse(d$inverted_estimate == 1, d$coefficient, NA_real_)
se_coefficient_new <- ifelse(d$inverted_estimate == 1, d$se_coefficient, NA_real_)

## a handful of rows have elasticity == 0 (coefficient = -Inf) or missing se (se_coefficient
## missing); Stata's `winsor2`/regression commands silently drop these as missing, so make that
## explicit here rather than letting Inf propagate.
coefficient_new[!is.finite(coefficient_new)]       <- NA_real_
se_coefficient_new[!is.finite(se_coefficient_new)] <- NA_real_

## ------------------------------------------------------------------------ skill.do lines 40-41
## winsor2 coefficient, se_coefficient, cuts(1 99) -- done ONCE on the full inverted_estimate==1
## sample, before any panel-specific subsetting.
coefficient_w    <- st_winsor2(coefficient_new,    cuts = c(1, 99))
se_coefficient_w <- st_winsor2(se_coefficient_new, cuts = c(1, 99))

## ------------------------------------------------------------------------ skill.do lines 43-46
d$tstat_coefficient_w     <- coefficient_w / se_coefficient_w
d$precision_coefficient_w <- 1 / se_coefficient_w

results <- list()
add <- function(label, value) results[[label]] <<- unname(value)

run_panel <- function(prefix, filter_col) {
  sub <- st_keep_if(d, d[[filter_col]] == 1 & d$inverted_estimate == 1)

  ## ---- FE column: xtreg tstat_coefficient_w precision_coefficient_w, fe vce(cluster idstudy)
  ## The regression is the WLS transform of "coefficient = b0 + b1*SE" divided through by SE:
  ## t = b0*precision + b1. So the SLOPE on precision is b0 = "Effect beyond bias", and the
  ## INTERCEPT is b1 = "Publication bias" (the coefficient on SE in the untransformed model).
  m_fe <- st_xtreg_fe(tstat_coefficient_w ~ precision_coefficient_w, data = sub, panel = "idstudy")
  cf_fe <- st_coefs(m_fe, z = FALSE)
  slope_fe <- cf_fe[cf_fe$term == "precision_coefficient_w", ]

  m_fe_cons <- st_xtreg_fe_cons(y = "tstat_coefficient_w", x = "precision_coefficient_w",
                                 panel = "idstudy", data = sub)
  cf_fe_cons <- st_coefs(m_fe_cons, z = FALSE)
  intercept_fe <- cf_fe_cons[cf_fe_cons$term == "(Intercept)", ]

  n_fe <- sum(stats::complete.cases(sub[, c("tstat_coefficient_w", "precision_coefficient_w", "idstudy")]))

  add(paste0(prefix, "_FE_pubbias_coef"), intercept_fe$estimate)
  add(paste0(prefix, "_FE_pubbias_se"),   intercept_fe$std.error)
  add(paste0(prefix, "_FE_effect_coef"),  slope_fe$estimate)
  add(paste0(prefix, "_FE_effect_se"),    slope_fe$std.error)
  add(paste0(prefix, "_FE_N"),            n_fe)

  ## ---- IV column: ivreg2 tstat_coefficient_w (precision_coefficient_w=instrument_sec), cluster(idstudy)
  m_iv <- st_ivreg2(tstat_coefficient_w ~ 1 | precision_coefficient_w ~ instrument_sec,
                     data = sub, cluster = ~idstudy)
  cf_iv <- st_coefs(m_iv, z = TRUE)
  slope_iv <- cf_iv[grepl("precision_coefficient_w", cf_iv$term), ]
  intercept_iv <- cf_iv[cf_iv$term == "(Intercept)", ]

  ## ---- first-stage robust F: NOT st_ivreg2_first_F(m_iv).
  ## st_ivreg2_first_F asks fixest for `fitstat(m, "ivwald1")`, and its own comment says this is
  ## meant to use fixest's DEFAULT small-sample ssc (Stata's regress-style correction), deliberately
  ## different from the large-sample ssc the coefficient table uses. In practice it does not: the
  ## first-stage sub-model that fixest carries inside an IV fit is estimated (and cached) under the
  ## OUTER call's ssc, which for ivreg2 is .SSC_LARGE (see st_ivreg2) -- and fixest's own summary
  ## logic re-uses that cached/flagged ssc rather than fixest's package default even when asked
  ## fresh, so fitstat(m_iv, "ivwald1") silently returns the large-sample-ssc Wald stat (verified
  ## directly against fixest's fitstat() source: the "flags"-driven branch of the ivwald1 first-
  ## stage code path is always taken here, never the "recompute with the caller's ssc" branch).
  ## That is a ~4% inflation for Panel A/B (driven by (n-1)/(n-K) * G/(G-1)) and much larger for
  ## Panel C, where G is small -- exactly the pattern in the diff (48.14/46.17=1.043, 74.45/69.98=
  ## 1.064, 320.72/260.41=1.232, growing as N and cluster count shrink from A to C).
  ##
  ## The fix: fit the univariate first-stage regression directly with st_regress (which IS
  ## documented, and verified, to use fixest's default ssc -- "Stata's regress always applies the
  ## small-sample corrections") and read off its Wald stat -- the same statistic ivreg2's "first"
  ## option reports, just computed on a model that actually carries the default ssc instead of
  ## inheriting the outer ivreg2 call's large-sample one. This reproduces all three printed values
  ## (46.17 / 69.98 / 260.41) exactly.
  m_first <- st_regress(precision_coefficient_w ~ instrument_sec, data = sub, cluster = ~idstudy)
  f_iv <- as.numeric(fixest::fitstat(m_first, "wald")[[1]]$stat)

  n_iv <- sum(stats::complete.cases(sub[, c("tstat_coefficient_w", "precision_coefficient_w",
                                             "instrument_sec", "idstudy")]))

  add(paste0(prefix, "_IV_pubbias_coef"), intercept_iv$estimate)
  add(paste0(prefix, "_IV_pubbias_se"),   intercept_iv$std.error)
  add(paste0(prefix, "_IV_effect_coef"),  slope_iv$estimate)
  add(paste0(prefix, "_IV_effect_se"),    slope_iv$std.error)
  add(paste0(prefix, "_IV_firstF"),       f_iv)
  add(paste0(prefix, "_IV_N"),            n_iv)

  invisible(NULL)
}

run_panel("A", "ols_method2")
run_panel("B", "iv_method2")
run_panel("C", "natural_experiment")

## ------------------------------------------------------------------------------------- report
cat("\n===== Reproduced Table 1 numbers =====\n")
for (lab in names(results)) {
  cat(sprintf("%-22s %s\n", lab, format(results[[lab]], digits = 8)))
}

stata_compat_log()

jsonlite_ok <- requireNamespace("jsonlite", quietly = TRUE)
out_path <- "results.json"
if (jsonlite_ok) {
  jsonlite::write_json(results, out_path, auto_unbox = TRUE, digits = NA)
} else {
  # minimal hand-rolled JSON writer, no dependency needed
  esc <- function(x) as.character(x)
  lines <- sprintf('  "%s": %s', names(results), sapply(results, esc))
  writeLines(c("{", paste(lines, collapse = ",\n"), "}"), out_path)
}
cat(sprintf("\nWrote %s\n", normalizePath(out_path)))
