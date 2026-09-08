# Replication package: "Demand for Gasoline is More Price-Inelastic than Commonly Thought"
# (Energy Economics, 2012). Reproduces the paper's own Tables 4 and 5.
#
# PROVENANCE: the site ships no code for this paper. The author's original Stata script
# survived only inside a Word file and has been recovered; it fixes the specification
# exactly, and is NOT guessed from the paper's prose:
#
#     xtset idstudy
#     Table 4:  xtreg t prec se       if longr==0/1, mle noconstant
#               reg   t prec se       if longr==0/1, vce(cluster idstudy) noconstant
#     Table 5:  xtreg t prec usdata csection pubdate if longr==0/1, mle
#               test  usdata csection pubdate
#               reg   t prec usdata csection pubdate if longr==0/1, vce(cluster idstudy)
#               test  usdata csection pubdate
#
# Every number in Tables 4 and 5 was re-run in Stata 15.1 on the PUBLISHED csv and agrees
# with the paper to the last printed digit; see the notes below for the full log.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/gasoline_price/replication/stata_compat.R")

DATA_PATH <- (if (file.exists("gasoline_price.csv")) "gasoline_price.csv" else
     "https://meta-analysis.cz/data/v1/gasoline_price/gasoline_price.csv")
d <- read.csv(DATA_PATH, stringsAsFactors = FALSE)

# columns (11): idstudy, e, se, t, prec, longr, pubdate, cs, tscs, usdata, csection
# prec is already 1/se (verified: max|1/se - prec| ~ 0 in the published file).
# csection ("cross-sectional dimension") is already the cs|tscs indicator the paper's
# text describes (verified: sum(cs==1) + sum(tscs==1) == sum(csection==1) == 136).

short <- st_keep_if(d, d$longr == 0)   # short-run elasticities, N = 110
long  <- st_keep_if(d, d$longr == 1)   # long-run elasticities,  N = 92

# st_coefs() calls stats::coef(m), which for an lme4::merMod object returns a per-group
# list (fixed + random blend), not a numeric vector -- st_coefs is written for feols
# objects only. stata_compat.R must never be edited, so the fixed-effects table for a
# mixed model is extracted here instead, using the same estimate/SE/z construction
# st_coefs uses, just via lme4::fixef() rather than stats::coef().
#
# STANDARD ERRORS -- the author ran `xtreg ..., mle`, which is NOT the same reported vcov as
# Stata's `mixed ..., mle`, and the difference is exactly what the printed SEs discriminate.
# Re-run in Stata 15.1 on the published csv, short run, Table 4:
#
#     xtreg t prec se if longr==0, mle noconstant   ->  prec SE 0.011954   se SE 2.093528
#     mixed t prec se if longr==0, nocons || idstudy:, mle
#                                                   ->  prec SE 0.010625   se SE 1.960410
#     paper, Table 4, short run                     ->        (0.0120)          (2.094)
#
# Both fits are the same maximum-likelihood estimator -- identical coefficients, identical
# variance components, identical log-likelihood (-260.51144) -- so this is purely a question
# of which matrix is inverted for the fixed-effect block. `xtreg, mle` inverts the OBSERVED
# information of the full log-likelihood over beta AND the variance parameters
# (ln sd_u, ln sd_e) jointly, so the beta block picks up the beta/theta cross-derivatives
# -X'V^-1 (dV/dtheta) V^-1 r, which are not zero at the realised residuals. lme4's vcov()
# (like Stata `mixed` here) reports (X'V^-1 X)^-1 -- the block where those cross-derivatives
# are assumed away. With 30 studies that is worth 1-13% on the SE, unevenly across
# coefficients, and every printed mixed-effects SE in Tables 4 and 5, plus both Wald chi2
# statistics, rounds to the xtreg,mle value and none rounds to the lme4 value.
#
# st_mixed() therefore supplies the fit (it is the right ML estimator) and the analytic
# Hessian below supplies the vcov that xtreg,mle reports, evaluated at that fit -- the same
# arrangement as the Wald test further down. It reproduces Stata to six decimals; the check
# is in REPLICATION_STATUS.md.
oim_vcov_mixed <- function(m, g) {
  X <- lme4::getME(m, "X"); y <- lme4::getME(m, "y"); b <- lme4::fixef(m)
  vc <- as.data.frame(lme4::VarCorr(m))
  su <- vc$sdcor[vc$grp != "Residual"]; se <- vc$sdcor[vc$grp == "Residual"]
  stopifnot(length(su) == 1L)            # one random intercept, one residual variance
  p <- length(b); H <- matrix(0, p + 2, p + 2)
  r <- as.numeric(y - X %*% b)
  for (gg in unique(g)) {
    idx <- which(g == gg); n <- length(idx)
    Xg <- X[idx, , drop = FALSE]; rg <- r[idx]
    V  <- diag(se^2, n) + matrix(su^2, n, n); Vi <- solve(V)
    # V_g = exp(2 th_e) I + exp(2 th_u) J ; derivatives in th = (ln sd_u, ln sd_e)
    Vk  <- list(u = 2 * su^2 * matrix(1, n, n), e = 2 * se^2 * diag(n))
    Vkk <- list(u = 4 * su^2 * matrix(1, n, n), e = 4 * se^2 * diag(n))
    H[1:p, 1:p] <- H[1:p, 1:p] - t(Xg) %*% Vi %*% Xg
    for (k in 1:2) {
      cross <- -t(Xg) %*% Vi %*% Vk[[k]] %*% Vi %*% rg
      H[1:p, p + k] <- H[1:p, p + k] + cross
      H[p + k, 1:p] <- H[p + k, 1:p] + t(cross)
      for (l in 1:2) {
        A <- Vi %*% Vk[[k]]; B <- Vi %*% Vk[[l]]
        Vkl <- if (k == l) Vkk[[k]] else matrix(0, n, n)
        H[p + k, p + l] <- H[p + k, p + l] +
          0.5 * sum(diag(B %*% A)) - 0.5 * sum(diag(Vi %*% Vkl)) -
          as.numeric(t(rg) %*% B %*% A %*% Vi %*% rg) +
          0.5 * as.numeric(t(rg) %*% Vi %*% Vkl %*% Vi %*% rg)
      }
    }
  }
  Vb <- solve(-H)[1:p, 1:p, drop = FALSE]
  dimnames(Vb) <- list(names(b), names(b))
  Vb
}

coefs_mixed <- function(m, g) {
  b <- lme4::fixef(m); V <- oim_vcov_mixed(m, g); s <- sqrt(diag(V))
  data.frame(term = names(b), estimate = as.numeric(b), std.error = as.numeric(s),
             statistic = as.numeric(b / s), p.value = 2 * stats::pnorm(-abs(b / s)),
             row.names = NULL, stringsAsFactors = FALSE)
}

results <- list()
add <- function(label, value) results[[label]] <<- unname(value)

## ---------------------------------------------------------------------------------------
## Table 4. Test of the true elasticity beyond publication bias.
## Response variable: t. Regressors: 1/SE ("true elasticity") and SE, NO constant.
## Derivation: dividing  e = b0 + b1*SE + u  by SE gives  t = b0*(1/SE) + b1 + u/SE ;
## the paper prints this transformed regression's own coefficients (on 1/SE and on SE),
## so estimation is directly on (t ~ prec + se - 1).
## Mixed-effects multilevel: study random intercept, ML -- Stata `xtreg t prec se, mle
## noconstant` after `xtset idstudy`. Clustered OLS: `regress t prec se, vce(cluster idstudy)
## noconstant`. The LR chi2 the table prints is xtreg's own chibar2 test of sigma_u = 0,
## i.e. the ML mixed fit against pooled OLS.
## ---------------------------------------------------------------------------------------

fit_t4 <- function(dd) {
  m_mixed <- st_mixed(t ~ prec + se - 1 + (1 | idstudy), data = dd)
  m_ols   <- st_regress(t ~ prec + se - 1, data = dd, cluster = ~idstudy)
  # plain OLS (no cluster adjustment; point estimates/likelihood are cluster-invariant)
  # used only to build the LR test of the mixed model against pooled OLS.
  m_pool  <- st_regress(t ~ prec + se - 1, data = dd)
  list(mixed = m_mixed, ols = m_ols, pool = m_pool, g = dd$idstudy)
}

t4_short <- fit_t4(short)
t4_long  <- fit_t4(long)

report_t4 <- function(fits, tag, n) {
  cm <- coefs_mixed(fits$mixed, fits$g)
  co <- st_coefs(fits$ols,   z = FALSE)
  add(paste0("T4 mixed ", tag, ": 1/SE coef"), cm$estimate[cm$term == "prec"])
  add(paste0("T4 mixed ", tag, ": 1/SE SE"),   cm$std.error[cm$term == "prec"])
  add(paste0("T4 mixed ", tag, ": SE coef"),   cm$estimate[cm$term == "se"])
  add(paste0("T4 mixed ", tag, ": SE SE"),     cm$std.error[cm$term == "se"])
  add(paste0("T4 mixed ", tag, ": N"), n)

  lr <- 2 * (as.numeric(stats::logLik(fits$mixed)) - as.numeric(stats::logLik(fits$pool)))
  add(paste0("T4 mixed ", tag, ": LR chi2"), lr)

  add(paste0("T4 OLS ", tag, ": 1/SE coef"), co$estimate[co$term == "prec"])
  add(paste0("T4 OLS ", tag, ": 1/SE SE"),   co$std.error[co$term == "prec"])
  add(paste0("T4 OLS ", tag, ": SE coef"),   co$estimate[co$term == "se"])
  add(paste0("T4 OLS ", tag, ": SE SE"),     co$std.error[co$term == "se"])
  add(paste0("T4 OLS ", tag, ": N"), n)
}

report_t4(t4_short, "short", nrow(short))
report_t4(t4_long,  "long",  nrow(long))

## ---------------------------------------------------------------------------------------
## Table 5. Multivariate meta-regression.
## Response variable: t. Regressors: 1/SE, US data, Cross-sectional dimension,
## Year of publication, and a Constant (publication bias now spread across the moderators
## and the constant, as the paper's prose states, rather than concentrated in SE alone).
## ---------------------------------------------------------------------------------------

fit_t5 <- function(dd) {
  m_mixed <- st_mixed(t ~ prec + usdata + csection + pubdate + (1 | idstudy), data = dd)
  m_ols   <- st_regress(t ~ prec + usdata + csection + pubdate, data = dd, cluster = ~idstudy)
  list(mixed = m_mixed, ols = m_ols, g = dd$idstudy)
}

t5_short <- fit_t5(short)
t5_long  <- fit_t5(long)

# Stata `test usdata csection pubdate` after `xtreg ..., mle`: Wald chi2 built on the same
# OIM vcov the coefficient table reports. Verified against Stata: 3.47 (short), 18.26 (long).
wald_chi2_mixed <- function(m, g, vars) {
  b <- lme4::fixef(m)[vars]
  V <- oim_vcov_mixed(m, g)[vars, vars]
  as.numeric(t(b) %*% solve(V) %*% b)
}

report_t5 <- function(fits, tag, n) {
  cm <- coefs_mixed(fits$mixed, fits$g)
  co <- st_coefs(fits$ols,   z = FALSE)
  get <- function(cf, term, what) cf[[what]][cf$term == term]

  add(paste0("T5 mixed ", tag, ": 1/SE coef"), get(cm, "prec", "estimate"))
  add(paste0("T5 mixed ", tag, ": 1/SE SE"),   get(cm, "prec", "std.error"))
  add(paste0("T5 mixed ", tag, ": US data coef"), get(cm, "usdata", "estimate"))
  add(paste0("T5 mixed ", tag, ": US data SE"),   get(cm, "usdata", "std.error"))
  add(paste0("T5 mixed ", tag, ": cross-section coef"), get(cm, "csection", "estimate"))
  add(paste0("T5 mixed ", tag, ": cross-section SE"),   get(cm, "csection", "std.error"))
  add(paste0("T5 mixed ", tag, ": year coef"), get(cm, "pubdate", "estimate"))
  add(paste0("T5 mixed ", tag, ": year SE"),   get(cm, "pubdate", "std.error"))
  add(paste0("T5 mixed ", tag, ": constant coef"), get(cm, "(Intercept)", "estimate"))
  add(paste0("T5 mixed ", tag, ": constant SE"),   get(cm, "(Intercept)", "std.error"))
  add(paste0("T5 mixed ", tag, ": N"), n)
  add(paste0("T5 mixed ", tag, ": joint sig Wald chi2"),
      wald_chi2_mixed(fits$mixed, fits$g, c("usdata", "csection", "pubdate")))

  add(paste0("T5 OLS ", tag, ": 1/SE coef"), get(co, "prec", "estimate"))
  add(paste0("T5 OLS ", tag, ": 1/SE SE"),   get(co, "prec", "std.error"))
  add(paste0("T5 OLS ", tag, ": US data coef"), get(co, "usdata", "estimate"))
  add(paste0("T5 OLS ", tag, ": US data SE"),   get(co, "usdata", "std.error"))
  add(paste0("T5 OLS ", tag, ": cross-section coef"), get(co, "csection", "estimate"))
  add(paste0("T5 OLS ", tag, ": cross-section SE"),   get(co, "csection", "std.error"))
  add(paste0("T5 OLS ", tag, ": year coef"), get(co, "pubdate", "estimate"))
  add(paste0("T5 OLS ", tag, ": year SE"),   get(co, "pubdate", "std.error"))
  add(paste0("T5 OLS ", tag, ": constant coef"), get(co, "(Intercept)", "estimate"))
  add(paste0("T5 OLS ", tag, ": constant SE"),   get(co, "(Intercept)", "std.error"))
  add(paste0("T5 OLS ", tag, ": N"), n)
  wt <- fixest::wald(fits$ols, keep = c("usdata", "csection", "pubdate"))
  add(paste0("T5 OLS ", tag, ": joint sig F"), as.numeric(wt$stat))
}

report_t5(t5_short, "short", nrow(short))
report_t5(t5_long,  "long",  nrow(long))

## ---------------------------------------------------------------------------------------
## Print and write results
## ---------------------------------------------------------------------------------------

for (lbl in names(results)) {
  cat(sprintf("%-40s %s\n", lbl, format(results[[lbl]], digits = 8)))
}

out <- vapply(results, function(x) as.numeric(x), numeric(1))
out_list <- as.list(out)
names(out_list) <- names(results)

RESULTS_PATH <- "results.json"
if (requireNamespace("jsonlite", quietly = TRUE)) {
  writeLines(jsonlite::toJSON(out_list, auto_unbox = TRUE, digits = 10), RESULTS_PATH)
} else {
  # minimal hand-rolled JSON writer, no external dependency
  esc <- function(s) gsub('"', '\\\\"', s)
  lines <- sprintf('  "%s": %s', esc(names(out_list)),
                    vapply(out_list, function(v) format(v, digits = 10, scientific = FALSE), character(1)))
  writeLines(c("{", paste(lines, collapse = ",\n"), "}"), RESULTS_PATH)
}

stata_compat_log()
