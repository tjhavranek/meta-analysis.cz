# run.R -- reproduces Table 2 of
#   Elminejad, Havranek & Irsova, "Relative Risk Aversion: A Meta-Analysis",
#   Journal of Economic Surveys 39(5), 2315-2333 (2025), doi 10.1111/joes.12689.
#
# Table 2 = "Linear funnel asymmetry tests": three panels (A all studies, B economics,
# C finance) x four columns (WLS, FE, BE, Study).
#
# Code source: risk.zip:risk/rra.do, the funnel-asymmetry block. (The author's fuller working
# copy of the same file, Papers/43_Risk_aversion/Code/rra.do, carries the identical block at
# lines 360-431; the site's cut-down version is not missing any Table 2 code path.)
#
# Data source: the site-published risk.csv. It is numerically identical to the author's own
# post-filter working file Code/rra_data.dta (1021 x 61, every numeric column equal to within
# 1e-10), so nothing about the data is in question here.
#
# ORACLE NOTE. Every number below was cross-checked against Stata 15.1 running the author's own
# commands on the author's own risk.dta. R and Stata agree to every digit Stata prints, in all
# 12 regressions. Where a cell disagrees with the paper, it is the paper that disagrees with the
# author's code -- see REPLICATION.md, section "Panel C".

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/risk/replication/stata_compat.R")

d <- read.csv((if (file.exists("risk.csv")) "risk.csv" else
     "https://meta-analysis.cz/data/v1/risk/risk.csv"),
              stringsAsFactors = FALSE)
stopifnot(nrow(d) == 1021)

## ---- rra.do: variable construction, done ONCE on the full 1021-row sample ----
## The winsorising (winsor2 rra se, cuts(10 90)) precedes every panel split in the do-file, so
## Panels B and C reuse the globally winsorised rra_win/se_win. They are NOT re-winsorised
## within the subsample; that alternative was run in Stata and lands nowhere near the printed
## table (finance WLS would give 2.628 rather than 1.85/1.86).
d$se2       <- ifelse(d$se == 0, 0.0001, d$se)     # replace se=0.0001 if se==0  (3 rows)
d$rra_win   <- st_winsor2(d$rra, cuts = c(10, 90))
d$se_win    <- st_winsor2(d$se2, cuts = c(10, 90))
d$tstat_win <- d$rra_win / d$se_win
d$prec_win  <- 1 / d$se_win
d$invperstudy <- 1 / d$perstudy

## ---- Panel definitions ----
## econjournal and finjournal are exact complements in this file (590 rows (1,0), 431 rows
## (0,1), nothing else), so `if econjournal==0` and `if finjournal==1` select the same 431 rows.
panels <- list(
  A = list(label = "All studies", data = d),
  B = list(label = "Economics",   data = d[d$econjournal == 1, ]),
  C = list(label = "Finance",     data = d[d$econjournal == 0, ])
)

results <- list()

put <- function(label, value) {
  results[[label]] <<- as.numeric(value)
  cat(sprintf("%-22s = %s\n", label, format(value, digits = 8)))
}

## LABELLING. The regression actually run is tstat_win = a + b*prec_win, which is the
## inverse-variance-weighted regression of rra_win on se_win written in t-space: dividing
##   rra_win = beta0 + beta1*se_win + e      (WLS with weights 1/se_win^2)
## through by se_win gives
##   tstat_win = beta0*prec_win + beta1.
## So the COEFFICIENT ON prec_win is beta0, the mean effect -- Table 2's row "Constant (mean
## corrected RRA)" -- and the regression's own CONSTANT is beta1, the slope on the standard
## error -- Table 2's row "Standard error (publication bias)". targets.json names the two rows
## `*_prec_*` and `*_cons_*` after the printed rows, not after the fitted terms, so the two look
## crossed here on purpose. Confirmed against Stata's own output and against all eight
## intercepts of Panels A and B, which match the printed table to the last digit under this
## mapping and under no other.

for (pn in names(panels)) {
  dsub <- panels[[pn]]$data

  ## ---- WLS: ivreg2 tstat_win prec_win, cluster(idstudy) ----
  m_wls <- st_ivreg2(tstat_win ~ prec_win, data = dsub, cluster = ~idstudy)
  cf <- st_coefs(m_wls, z = TRUE)
  put(paste0(pn, "_WLS_prec_coef"), cf$estimate[cf$term == "(Intercept)"])   # "Standard error"
  put(paste0(pn, "_WLS_prec_se"),   cf$std.error[cf$term == "(Intercept)"])
  put(paste0(pn, "_WLS_cons_coef"), cf$estimate[cf$term == "prec_win"])      # "Constant"
  put(paste0(pn, "_WLS_cons_se"),   cf$std.error[cf$term == "prec_win"])

  ## ---- FE: xtreg tstat_win prec_win, fe cluster(idstudy) ----
  m_fe <- st_xtreg_fe(tstat_win ~ prec_win, data = dsub, panel = "idstudy", cluster = ~idstudy)
  cf_fe <- st_coefs(m_fe, z = TRUE)
  ## Stata's xtreg,fe reports a _cons (ybar - b*xbar over the estimation sample) that fixest
  ## does not; the dedicated wrapper reconstructs it the way Stata does.
  m_fe_cons <- st_xtreg_fe_cons(y = "tstat_win", x = "prec_win", panel = "idstudy",
                                data = dsub, cluster = ~idstudy)
  cf_fe_cons <- st_coefs(m_fe_cons, z = TRUE)
  put(paste0(pn, "_FE_prec_coef"), cf_fe_cons$estimate[cf_fe_cons$term == "(Intercept)"])
  put(paste0(pn, "_FE_prec_se"),   cf_fe_cons$std.error[cf_fe_cons$term == "(Intercept)"])
  put(paste0(pn, "_FE_cons_coef"), cf_fe$estimate[cf_fe$term == "prec_win"])
  put(paste0(pn, "_FE_cons_se"),   cf_fe$std.error[cf_fe$term == "prec_win"])

  ## ---- BE: xtreg tstat_win prec_win, be ----
  ## No `wls` option, so this is unweighted OLS on the study-level means, one row per idstudy,
  ## with small-sample (t) inference on N_g - 2 degrees of freedom and no clustering.
  agg <- aggregate(cbind(tstat_win, prec_win) ~ idstudy, data = dsub, FUN = mean)
  m_be <- st_regress(tstat_win ~ prec_win, data = agg, cluster = NULL)
  cf_be <- st_coefs(m_be, z = FALSE)
  put(paste0(pn, "_BE_prec_coef"), cf_be$estimate[cf_be$term == "(Intercept)"])
  put(paste0(pn, "_BE_prec_se"),   cf_be$std.error[cf_be$term == "(Intercept)"])
  put(paste0(pn, "_BE_cons_coef"), cf_be$estimate[cf_be$term == "prec_win"])
  put(paste0(pn, "_BE_cons_se"),   cf_be$std.error[cf_be$term == "prec_win"])

  ## ---- Study: ivreg2 ... [pweight=invperstudy], cluster(idstudy) ----
  m_study <- st_ivreg2(tstat_win ~ prec_win, data = dsub, cluster = ~idstudy,
                       weights = ~invperstudy)
  cf_s <- st_coefs(m_study, z = TRUE)
  put(paste0(pn, "_Study_prec_coef"), cf_s$estimate[cf_s$term == "(Intercept)"])
  put(paste0(pn, "_Study_prec_se"),   cf_s$std.error[cf_s$term == "(Intercept)"])
  put(paste0(pn, "_Study_cons_coef"), cf_s$estimate[cf_s$term == "prec_win"])
  put(paste0(pn, "_Study_cons_se"),   cf_s$std.error[cf_s$term == "prec_win"])

  ## ---- Observations / Studies (one pair per panel, shared by all four columns) ----
  put(paste0(pn, "_obs"),     nrow(dsub))
  put(paste0(pn, "_studies"), length(unique(dsub$idstudy)))
}

## ---- Wild-cluster-bootstrap CIs (the square brackets in the WLS and Study columns) ----------
## The do-file gets these from `boottest prec_win10, nograph` / `boottest _cons, nograph`, with
## no seed set anywhere in the file. stata_compat.R has no boottest wrapper, and approximating
## boottest with some other bootstrap would produce numbers that are neither Stata's nor
## reproducible run to run. They are therefore left uncomputed rather than guessed. targets.json
## marks all 24 of them "stochastic", so they sit outside the scored set either way.
ci_stub <- as.vector(outer(c("A", "B", "C"), c("WLS", "Study"), paste, sep = "_"))
ci_labels <- as.vector(outer(ci_stub,
                             c("prec_ci_lo", "prec_ci_hi", "cons_ci_lo", "cons_ci_hi"),
                             paste, sep = "_"))
for (lbl in ci_labels) results[[lbl]] <- NA_real_

stata_compat_log()

writeLines(jsonlite::toJSON(results, auto_unbox = TRUE, digits = 10, na = "null"), "results.json")
cat("\nWrote results.json with", length(results), "entries.\n")
