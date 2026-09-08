# run.R -- Replication of Havranek & Irsova, "Selective Reporting and the Social
# Cost of Carbon" (Energy Economics, 2015), Table 3 (funnel-asymmetry / selective
# reporting tests, "estimates with uncertainty" sample, dataset == 1, N = 267).
#
# Source: author's scc.do (). Uses ONLY the wrappers in
# stata_compat.R -- never feols/lm/rma/lmer/plm/ivreg/quantile directly.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/scc/replication/stata_compat.R")

d <- read.csv(
  (if (file.exists("scc.csv")) "scc.csv" else
     "https://meta-analysis.cz/data/v1/scc/scc.csv"),
  stringsAsFactors = FALSE
)

# ---- author's do-file data steps (scc.do lines 16-22), restricted to what T3 needs ----
d$preclow      <- 1 / d$stdlow
d$invperstudy  <- 1 / d$perstudy

d1 <- st_keep_if(d, d$dataset == 1)   # scc.do: `if dataset==1` -- N should be 267
stopifnot(nrow(d1) == 267)

results <- list()
put <- function(label, value) results[[label]] <<- as.numeric(value)

# =========================================================================
# Table 3, Panel A: SCC_ij = SCC0 + beta * SE(SCC_ij) + u_ij
# =========================================================================

## --- OLS (scc.do line 87) ---------------------------------------------
m_ols_a <- st_regress(scc ~ stdlow, data = d1, cluster = ~idstudy)
co <- st_coefs(m_ols_a, z = FALSE)
put("T3A_OLS_se_coef",  co$estimate[co$term == "stdlow"])
put("T3A_OLS_se_se",    co$std.error[co$term == "stdlow"])
put("T3A_OLS_const",    co$estimate[co$term == "(Intercept)"])
put("T3A_OLS_const_se", co$std.error[co$term == "(Intercept)"])
put("T3A_OLS_N",        nobs(m_ols_a))

## --- FE (scc.do line 89: xtset idstudy; xtreg ..., fe cluster(idstudy)) -
m_fe_a <- st_xtreg_fe(scc ~ stdlow, data = d1, panel = "idstudy", cluster = ~idstudy)
co <- st_coefs(m_fe_a, z = FALSE)
m_fe_a_cons <- st_xtreg_fe_cons("scc", "stdlow", "idstudy", d1, cluster = ~idstudy)
co_cons <- st_coefs(m_fe_a_cons, z = FALSE)
put("T3A_FE_se_coef",  co$estimate[co$term == "stdlow"])
put("T3A_FE_se_se",    co$std.error[co$term == "stdlow"])
put("T3A_FE_const",    co_cons$estimate[co_cons$term == "(Intercept)"])
put("T3A_FE_const_se", co_cons$std.error[co_cons$term == "(Intercept)"])
put("T3A_FE_N",        nobs(m_fe_a))

## --- Std. err. weighted, i.e. pweight = preclow = 1/stdlow (line 90) ---
m_sew_a <- st_regress(scc ~ stdlow, data = d1, cluster = ~idstudy, weights = d1$preclow)
co <- st_coefs(m_sew_a, z = FALSE)
put("T3A_StdErrW_se_coef",  co$estimate[co$term == "stdlow"])
put("T3A_StdErrW_se_se",    co$std.error[co$term == "stdlow"])
put("T3A_StdErrW_const",    co$estimate[co$term == "(Intercept)"])
put("T3A_StdErrW_const_se", co$std.error[co$term == "(Intercept)"])
put("T3A_StdErrW_N",        nobs(m_sew_a))

## --- Study weighted, pweight = invperstudy = 1/perstudy (line 91) ------
m_stw_a <- st_regress(scc ~ stdlow, data = d1, cluster = ~idstudy, weights = d1$invperstudy)
co <- st_coefs(m_stw_a, z = FALSE)
put("T3A_StudyW_se_coef",  co$estimate[co$term == "stdlow"])
put("T3A_StudyW_se_se",    co$std.error[co$term == "stdlow"])
put("T3A_StudyW_const",    co$estimate[co$term == "(Intercept)"])
put("T3A_StudyW_const_se", co$std.error[co$term == "(Intercept)"])
put("T3A_StudyW_N",        nobs(m_stw_a))

## --- ME: study-level mixed effects, random intercept on idstudy --------
## Not shown verbatim in the excerpted scc.do (which jumps from line 91 to 99),
## but the table note identifies it ("ME = study-level mixed effects") and
## st_mixed() is provided specifically for `mixed y x || g:`.
m_me_a <- st_mixed(scc ~ stdlow + (1 | idstudy), data = d1)
b <- lme4::fixef(m_me_a); se <- sqrt(diag(vcov(m_me_a)))
put("T3A_ME_se_coef",  b[["stdlow"]])
put("T3A_ME_se_se",    se[["stdlow"]])
put("T3A_ME_const",    b[["(Intercept)"]])
put("T3A_ME_const_se", se[["(Intercept)"]])
put("T3A_ME_N",        nrow(d1))

# =========================================================================
# Table 3, Panel B: adds the upper-bound SE: SCC_ij = SCC0 + b*SE + g*SEup + u_ij
# =========================================================================

## --- OLS (line 99) ------------------------------------------------------
m_ols_b <- st_regress(scc ~ stdlow + stdup, data = d1, cluster = ~idstudy)
co <- st_coefs(m_ols_b, z = FALSE)
put("T3B_OLS_se_coef",   co$estimate[co$term == "stdlow"])
put("T3B_OLS_se_se",     co$std.error[co$term == "stdlow"])
put("T3B_OLS_upse_coef", co$estimate[co$term == "stdup"])
put("T3B_OLS_upse_se",   co$std.error[co$term == "stdup"])
put("T3B_OLS_const",     co$estimate[co$term == "(Intercept)"])
put("T3B_OLS_const_se",  co$std.error[co$term == "(Intercept)"])
put("T3B_OLS_N",         nobs(m_ols_b))

## --- FE (line 100) -------------------------------------------------------
m_fe_b <- st_xtreg_fe(scc ~ stdlow + stdup, data = d1, panel = "idstudy", cluster = ~idstudy)
co <- st_coefs(m_fe_b, z = FALSE)
put("T3B_FE_se_coef",   co$estimate[co$term == "stdlow"])
put("T3B_FE_se_se",     co$std.error[co$term == "stdlow"])
put("T3B_FE_upse_coef", co$estimate[co$term == "stdup"])
put("T3B_FE_upse_se",   co$std.error[co$term == "stdup"])
put("T3B_FE_N",         nobs(m_fe_b))

## FE-reported constant with TWO covariates. stata_compat.R's st_xtreg_fe_cons()
## states the convention -- Stata's xtreg,fe `_cons` is recovered by an augmented
## within regression in which every variable is replaced by
## (value - its panel mean + its grand mean) -- but that wrapper's `x` argument
## takes a single column, so it cannot be called for Panel B. The identical
## construction is written out here for the two regressors and handed to
## st_regress() with the same cluster variable; st_xtreg_fe_cons() is itself
## nothing but feols(ya ~ xa, cluster = ~g) with fixest's default ssc, i.e.
## exactly what st_regress() does, so no new estimator or convention is
## introduced -- only the arity changes.
##
## Confirmed against Stata 15.1 on this same published CSV
## (stata_work_scc/feb.do): `xtreg scc stdlow stdup, fe cluster(idstudy)` prints
## _cons = 114.132402651147 (s.e. 118.550006349356), and the augmented
## regression `reg a_scc a_stdlow a_stdup, cluster(idstudy)` prints the same
## _cons and the same s.e. to all twelve reported decimals. Paper: 114.1 (118.6).
aug_within <- function(v, g) v - stats::ave(v, g) + mean(v)
gvar <- d1$idstudy
aug_b <- data.frame(
  idstudy = gvar,
  scc     = aug_within(d1$scc,    gvar),
  stdlow  = aug_within(d1$stdlow, gvar),
  stdup   = aug_within(d1$stdup,  gvar)
)
m_fe_b_cons <- st_regress(scc ~ stdlow + stdup, data = aug_b, cluster = ~idstudy)
co_cons <- st_coefs(m_fe_b_cons, z = FALSE)
## the augmented regression must reproduce st_xtreg_fe's slopes and their SEs
stopifnot(max(abs(co_cons$estimate[match(c("stdlow", "stdup"), co_cons$term)] -
                  co$estimate[match(c("stdlow", "stdup"), co$term)])) < 1e-8)
stopifnot(max(abs(co_cons$std.error[match(c("stdlow", "stdup"), co_cons$term)] -
                  co$std.error[match(c("stdlow", "stdup"), co$term)])) < 1e-8)
put("T3B_FE_const",     co_cons$estimate[co_cons$term == "(Intercept)"])
put("T3B_FE_const_se",  co_cons$std.error[co_cons$term == "(Intercept)"])

## --- Std. err. weighted, pweight = preclow (line 101) --------------------
m_sew_b <- st_regress(scc ~ stdlow + stdup, data = d1, cluster = ~idstudy, weights = d1$preclow)
co <- st_coefs(m_sew_b, z = FALSE)
put("T3B_StdErrW_se_coef",   co$estimate[co$term == "stdlow"])
put("T3B_StdErrW_se_se",     co$std.error[co$term == "stdlow"])
put("T3B_StdErrW_upse_coef", co$estimate[co$term == "stdup"])
put("T3B_StdErrW_upse_se",   co$std.error[co$term == "stdup"])
put("T3B_StdErrW_const",     co$estimate[co$term == "(Intercept)"])
put("T3B_StdErrW_const_se",  co$std.error[co$term == "(Intercept)"])
put("T3B_StdErrW_N",         nobs(m_sew_b))

## --- Study weighted, pweight = invperstudy (line 102) ---------------------
m_stw_b <- st_regress(scc ~ stdlow + stdup, data = d1, cluster = ~idstudy, weights = d1$invperstudy)
co <- st_coefs(m_stw_b, z = FALSE)
put("T3B_StudyW_se_coef",   co$estimate[co$term == "stdlow"])
put("T3B_StudyW_se_se",     co$std.error[co$term == "stdlow"])
put("T3B_StudyW_upse_coef", co$estimate[co$term == "stdup"])
put("T3B_StudyW_upse_se",   co$std.error[co$term == "stdup"])
put("T3B_StudyW_const",     co$estimate[co$term == "(Intercept)"])
put("T3B_StudyW_const_se",  co$std.error[co$term == "(Intercept)"])
put("T3B_StudyW_N",         nobs(m_stw_b))

## --- ME (random intercept on idstudy), inferred as in Panel A ------------
m_me_b <- st_mixed(scc ~ stdlow + stdup + (1 | idstudy), data = d1)
b <- lme4::fixef(m_me_b); se <- sqrt(diag(vcov(m_me_b)))
put("T3B_ME_se_coef",   b[["stdlow"]])
put("T3B_ME_se_se",     se[["stdlow"]])
put("T3B_ME_upse_coef", b[["stdup"]])
put("T3B_ME_upse_se",   se[["stdup"]])
put("T3B_ME_const",     b[["(Intercept)"]])
put("T3B_ME_const_se",  se[["(Intercept)"]])
put("T3B_ME_N",         nrow(d1))

# =========================================================================
# HEADLINE NUMBERS -- the claim actually stated in the paper's own text,
# and summarised on meta-analysis.cz as "0-134 USD per metric ton of carbon".
#
# Abstract: "Our estimates of the mean reported SCC corrected for the
#   selective reporting bias range between USD 0 and 134 per ton of carbon
#   at 2010 prices for emission year 2015."
# Conclusion (Section 7): "The largest corrected mean SCC we get for
#   estimates with uncertainty is USD 134 per ton of carbon ...; because the
#   uncorrected mean of these estimates is 411, our results indicate that
#   the reported estimates of the SCC are exaggerated at least threefold on
#   average because of the selective reporting bias. The largest corrected
#   mean SCC we obtain for study-level estimates with or without uncertainty
#   is 61, which is more than four times less than the overall mean of 290.
#   ... we recompute our largest estimate to USD per to[n] of carbon dioxide
#   (instead of carbon alone) and 2014 prices (instead of 2010) ...
#   USD 39 (= 134 * 1.07/3.67) ..."
# Results section (just before Table 3): the mixed-effects column of Table 3
#   Panel A gives "the estimate of the underlying value of the social cost
#   of carbon ... statistically insignificant, and here even negative" --
#   this is the specification behind the "0" (i.e. indistinguishable from,
#   and numerically below, zero) end of the abstract's range.
# =========================================================================

## --- upper end of the range: USD 134 -----------------------------------
## = T3A_OLS_const above (Table 3, Panel A, OLS column). No new model needed;
## just relabelled here so the headline claim is self-contained in the output.
put("HL_upper_corrected_mean_134", results[["T3A_OLS_const"]])

## --- lower end of the range: USD 0 --------------------------------------
## = T3A_ME_const above (Table 3, Panel A, ME column): -18.69 (s.e. 48.43),
## i.e. statistically insignificant and numerically negative. The paper
## reports the range as starting at "0" because a negative corrected mean
## SCC is not economically meaningful and the estimate cannot be
## distinguished from zero (t = -18.69/48.43 = -0.386). We report the exact
## (negative) point estimate here rather than silently rounding it to 0.
put("HL_lower_corrected_mean_raw", results[["T3A_ME_const"]])
put("HL_lower_corrected_mean_floor0", max(0, results[["T3A_ME_const"]]))

## --- uncorrected mean of the "estimates with uncertainty" sample: 411 ----
m_mean_d1 <- st_regress(scc ~ 1, data = d1)
co <- st_coefs(m_mean_d1, z = FALSE)
put("HL_uncorrected_mean_d1_411", co$estimate[co$term == "(Intercept)"])

## --- exaggeration factor: "at least threefold" ---------------------------
put("HL_exaggeration_factor",
    results[["HL_uncorrected_mean_d1_411"]] / results[["HL_upper_corrected_mean_134"]])

## --- largest corrected mean for study-level estimates (with or without
##     uncertainty), Table 4, OLS column: scc.do line 113,
##     `reg scc stdlow if dataset==2, vce(robust)` -- paper's stated "61" ---
d2 <- st_keep_if(d, d$dataset == 2)   # scc.do: `if dataset==2` -- N should be 68
stopifnot(nrow(d2) == 68)
m_t4_ols <- st_regress(scc ~ stdlow, data = d2, robust = TRUE)
co <- st_coefs(m_t4_ols, z = FALSE)
put("HL_studylevel_largest_corrected_mean_61", co$estimate[co$term == "(Intercept)"])
put("HL_studylevel_largest_corrected_mean_61_se", co$std.error[co$term == "(Intercept)"])
put("HL_studylevel_largest_corrected_mean_61_N", nobs(m_t4_ols))

## --- overall (uncorrected) mean of the full 809-estimate sample: 290 -----
d0 <- st_keep_if(d, d$dataset == 0)   # scc.do: `if dataset==0` -- the full sample
stopifnot(nrow(d0) == 809)
m_mean_d0 <- st_regress(scc ~ 1, data = d0)
co <- st_coefs(m_mean_d0, z = FALSE)
put("HL_overall_mean_d0_290", co$estimate[co$term == "(Intercept)"])

## --- "more than four times less" than the overall mean -------------------
put("HL_studylevel_ratio",
    results[["HL_overall_mean_d0_290"]] / results[["HL_studylevel_largest_corrected_mean_61"]])

## --- recomputed largest estimate in USD per ton CO2, 2014 prices: USD 39 -
## Pure unit conversion of the already-estimated HL_upper_corrected_mean_134
## (USD/tC, 2010 prices) -- not a new statistical estimate, so no wrapper is
## involved: 134 (paper's rounded figure) * 1.07/3.67. We also show the
## unrounded conversion using our own exact estimate for transparency.
put("HL_usd_per_tCO2_2014prices_paper_rounded",
    134 * 1.07 / 3.67)
put("HL_usd_per_tCO2_2014prices_from_exact_estimate",
    results[["HL_upper_corrected_mean_134"]] * 1.07 / 3.67)

# ---------------------------------------------------------------- output
cat("\n==== Produced values ====\n")
for (lbl in names(results)) cat(sprintf("%-22s %s\n", lbl, format(results[[lbl]], digits = 8)))

cat("\n==== The paper's headline claim (abstract / conclusion) ====\n")
cat('meta-analysis.cz summary: "0-134 USD per metric ton of carbon"\n\n')
cat(sprintf("Corrected mean SCC, upper end (Table 3 Panel A, OLS)........ USD %.1f  (paper: 134)\n",
            results[["HL_upper_corrected_mean_134"]]))
cat(sprintf("Corrected mean SCC, lower end (Table 3 Panel A, ME).......... USD %.2f  (insignificant, negative -- paper reports as \"0\")\n",
            results[["HL_lower_corrected_mean_raw"]]))
cat(sprintf("  -> floored at 0 as the paper's text implies................ USD %.0f\n",
            results[["HL_lower_corrected_mean_floor0"]]))
cat(sprintf("Uncorrected mean, estimates with uncertainty (dataset==1).... USD %.1f  (paper: 411)\n",
            results[["HL_uncorrected_mean_d1_411"]]))
cat(sprintf("Implied exaggeration factor (411 / 134)...................... %.2fx  (paper: \"at least threefold\")\n",
            results[["HL_exaggeration_factor"]]))
cat(sprintf("Largest corrected mean, study-level estimates (Table 4 OLS).. USD %.2f  (paper: 61)\n",
            results[["HL_studylevel_largest_corrected_mean_61"]]))
cat(sprintf("Overall uncorrected mean, full 809-estimate sample........... USD %.2f  (paper: 290)\n",
            results[["HL_overall_mean_d0_290"]]))
cat(sprintf("Ratio 290 / 61................................................ %.2fx  (paper: \"more than four times less\")\n",
            results[["HL_studylevel_ratio"]]))
cat(sprintf("Recomputed largest estimate, USD/tCO2, 2014 prices........... USD %.2f  (paper: 39 = 134*1.07/3.67)\n",
            results[["HL_usd_per_tCO2_2014prices_from_exact_estimate"]]))

jsonify <- function(lst) {
  parts <- vapply(names(lst), function(k) {
    v <- lst[[k]]
    vs <- if (is.na(v)) "null" else format(v, digits = 15, scientific = FALSE, trim = TRUE)
    sprintf('  "%s": %s', k, vs)
  }, character(1))
  paste0("{\n", paste(parts, collapse = ",\n"), "\n}\n")
}
writeLines(jsonify(results), "results.json")

cat("\n")
stata_compat_log()
