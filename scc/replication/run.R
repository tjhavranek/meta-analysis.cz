# run.R -- Replication of Havranek & Irsova, "Selective Reporting and the Social
# Cost of Carbon" (Energy Economics, 2015), Table 3 (funnel-asymmetry / selective
# reporting tests, "estimates with uncertainty" sample, dataset == 1, N = 267).
#
# Source: author's scc.do (see briefs_repl/scc.md). Uses ONLY the wrappers in
# stata_compat.R -- never feols/lm/rma/lmer/plm/ivreg/quantile directly.

source("stata_compat.R")

d <- read.csv(
  "C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\scc\\scc.csv",
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
## st_xtreg_fe_cons only implements the single-regressor augmented-within
## constant; there is no wrapper for the FE-reported constant with two
## covariates, so T3B_FE_const{,_se} cannot be produced without writing a
## bespoke feols call, which is forbidden. Coefficients are still exact.
m_fe_b <- st_xtreg_fe(scc ~ stdlow + stdup, data = d1, panel = "idstudy", cluster = ~idstudy)
co <- st_coefs(m_fe_b, z = FALSE)
put("T3B_FE_se_coef",   co$estimate[co$term == "stdlow"])
put("T3B_FE_se_se",     co$std.error[co$term == "stdlow"])
put("T3B_FE_upse_coef", co$estimate[co$term == "stdup"])
put("T3B_FE_upse_se",   co$std.error[co$term == "stdup"])
put("T3B_FE_const",     NA)     # unsupported: no multi-regressor xtreg-FE constant wrapper
put("T3B_FE_const_se",  NA)     # unsupported: ditto
put("T3B_FE_N",         nobs(m_fe_b))

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

# ---------------------------------------------------------------- output
cat("\n==== Produced values ====\n")
for (lbl in names(results)) cat(sprintf("%-22s %s\n", lbl, format(results[[lbl]], digits = 8)))

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
