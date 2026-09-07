# Replication of Zigraiova and Havranek (2016, JEconSurveys) "Bank Competition and
# Financial Stability: Much Ado About Nothing?" -- Table 9 ("Results for Frequentist
# Methods"), the paper's fully-frequentist robustness table: OLS and study-fixed-effects
# regressions of the PCC of the competition-stability coefficient on all 35 moderators,
# weighted by the inverse of the number of estimates reported per study, clustered by
# study (IDStudy).
#
# Provenance: the author's competition.do (shipped beside the data at
# site/competition/competition.do) documents the "weighted best-practice" OLS check for
# the BASELINE table (Table 5/7's PIP>0.5 subset, `ivreg2 ... [pweight=investperst],
# cluster(IDStudy)`, do-file lines 74-76) and the funnel-asymmetry `xtreg ..., fe
# vce(cluster IDStudy)` weighted-FE convention (lines 49-50). Table 9 itself -- the
# ALL-35-variable OLS/FE check -- is not literally present in that .do file (it was very
# likely run from a later revision's do-file, added for a referee, that was not archived
# on the site), so its estimator/weight/cluster choices are taken from the paper's own
# text and table notes:
#   - p.965: "we run the BMA exercise with the same priors ... [but this time] we only
#     use frequentist methods (OLS and fixed effects)"
#   - Table 9 notes: "In the frequentist check we include all explanatory variables. The
#     standard errors ... are clustered at the study level. The regressions are estimated
#     by weighted least squares, where the inverse of the number of estimates reported
#     per study is taken as the weight."
# This is exactly the same weight (investperst) and cluster (IDStudy) as the do-file's own
# BMA-check regressions, so st_ivreg2 (OLS) and st_xtreg_fe (FE) are used with the same
# conventions validated below.
#
# VALIDATION (not part of the printed targets, done here as a sanity check before
# freezing the specification): running st_ivreg2 with weights=investperst, cluster=IDStudy
# on the PIP>0.5 subset from do-file line 74 reproduces the "Frequentist check (OLS)"
# column of Table 5/7 EXACTLY (e.g. SEPCC -1.1940 (0.6511), citations 0.0461 (0.0095),
# Constant -0.1184 (0.0860) -- all four printed digits). Running st_xtreg_fe with
# weights=investperst on `PCC ~ SEPCC` reproduces Table 2's weighted "Fixed effects" row
# (-1.568, matching "-1.568***" printed). Both confirm the weight variable, the cluster
# variable, and the st_ivreg2 / st_xtreg_fe conventions before they are applied to the
# full 35-variable Table 9 specification below.

source("stata_compat.R")

d <- read.csv(
  "C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\competition\\competition.csv",
  stringsAsFactors = FALSE, check.names = FALSE
)

cat("Rows read:", nrow(d), "  Studies:", length(unique(d$IDStudy)), "\n")

# ---------------------------------------------------------------------------
# Variable construction.
# ---------------------------------------------------------------------------
# The CSV mirrors the author's own column names except for two cosmetic
# differences: the SE of the PCC is published as "SE PCC" (with a space) and
# two-stage least squares as "2SLS" (leading digit, not a valid bare R name).
# The paper's tables call these SEPCC and TSLS.
d$SEPCC <- d$`SE PCC`
d$TSLS  <- d$`2SLS`

# Table 4's own variable-description column states that the "Sample size"
# regressor is "the logarithm of the number of cross-sectional units", not
# the raw Samplesize column: Table 4 reports mean 7.835, SD 1.615 for it,
# which is exactly mean(log(Samplesize)) / sd(log(Samplesize)) on this data
# (7.835073 / 1.614506) and nothing like the raw column's mean of ~8382.
# ("T", by contrast, is already published pre-logged: its raw mean/SD in the
# CSV, 2.224/0.743, already match Table 4's "T" description verbatim.)
d$Samplesize <- log(d$Samplesize)

# All 35 moderators used in Table 9, in the table's own printed order.
allvars <- c(
  "SEPCC", "Samplesize", "T", "sampleyear",
  "developed", "undeveloped",
  "quadratic", "endogeneity", "macro", "someAveraged",
  "dummies", "NPL", "Zscore", "profit_volat", "profitability", "capitalization", "DtoD",
  "Hstatistic", "Boone", "Concentration", "Lerner", "HHI",
  "Logit", "OLS", "FE", "RE", "GMM", "TSLS",
  "regulation", "ownership", "global",
  "citations", "firstpub", "IFrecursive", "reviewed_journal"
)

n_studies <- length(unique(d$IDStudy))

# ---------------------------------------------------------------------------
# OLS column: st_ivreg2, weighted by investperst, clustered by IDStudy.
# ---------------------------------------------------------------------------
fml_ols <- stats::as.formula(paste("PCC ~", paste(allvars, collapse = " + ")))
m_ols <- st_ivreg2(fml_ols, data = d, cluster = ~IDStudy, weights = ~investperst)
co_ols <- st_coefs(m_ols)

cat("\n=== Table 9, OLS column === N =", stats::nobs(m_ols), " Studies =", n_studies, "\n")
print(co_ols)

# ---------------------------------------------------------------------------
# FE column: st_xtreg_fe, weighted by investperst, panel = IDStudy.
# ---------------------------------------------------------------------------
# st_xtreg_fe builds its fixed-effects formula as
#   as.formula(paste(deparse(fml), "|", panel))
# and deparse() line-wraps any formula whose text exceeds ~60 characters
# (here, 35 terms) into a character VECTOR, which breaks that paste/reformulate
# step (verified: as.formula() on the resulting multi-element character vector
# errors with "unexpected '|'"). This is a formula-width limitation of the
# frozen wrapper's own plumbing, not a difference in estimator, weights,
# clustering, or degrees of freedom -- feols itself has no such limit, and
# fixest documents passing a matrix-valued column as a single formula term
# (all of its columns are added to the model as separate regressors) for
# exactly this situation. Packing the 35 moderators into one matrix column X
# keeps deparse(fml) at the seven characters "PCC ~ X" -- a single string --
# so the wrapper's own paste/as.formula step behaves exactly as it does for
# every short-formula call elsewhere on this site, while feols underneath
# fits the identical linear model. This was verified by comparing coefficients
# and SEs against the printed Table 9 FE column, not assumed.
d_fe <- data.frame(PCC = d$PCC, IDStudy = d$IDStudy, investperst = d$investperst)
# "undeveloped" ordered before "developed": in the study-FE model, developed and
# undeveloped are perfectly collinear within any study that reports estimates for
# only one of the two groups plus no "mixed" estimates (developed = 1 - undeveloped
# within that study, once demeaned by the study fixed effect). Some redundant column
# must be dropped, and Table 9 reports "developed (omitted)" with undeveloped
# estimated -- i.e. the author's variable order in the (unarchived) Table 9 do-file
# put undeveloped ahead of developed. fixest drops whichever collinear column comes
# SECOND, so this ordering (a variable-construction choice, not a change to the
# estimator, weights, clustering, or dof) is what is needed to match which of the two
# names the paper reports a coefficient for; every other coefficient is numerically
# identical regardless of this order (verified).
fe_vars <- c(
  "SEPCC", "Samplesize", "T", "sampleyear",
  "undeveloped", "developed",
  "quadratic", "endogeneity", "macro", "someAveraged",
  "dummies", "NPL", "Zscore", "profit_volat", "profitability", "capitalization", "DtoD",
  "Hstatistic", "Boone", "Concentration", "Lerner", "HHI",
  "Logit", "OLS", "FE", "RE", "GMM", "TSLS",
  "regulation", "ownership", "global",
  "citations", "firstpub", "IFrecursive", "reviewed_journal"
)
d_fe$X <- as.matrix(d[, fe_vars])

fml_fe <- PCC ~ X
m_fe <- st_xtreg_fe(fml_fe, data = d_fe, panel = "IDStudy", weights = ~investperst)
co_fe <- st_coefs(m_fe, z = FALSE)
# Strip the "X" prefix fixest gives matrix-column term names back to the plain
# moderator names used in Table 9 and in targets.json.
co_fe$term <- sub("^X", "", co_fe$term)

cat("\n=== Table 9, FE column === N =", stats::nobs(m_fe), " Studies =", n_studies, "\n")
print(co_fe)
cat(
  "\nNote: 'developed' does not appear above -- feols drops it for collinearity\n",
  "with the study fixed effects and 'undeveloped' (see comment above); this matches\n",
  "Table 9's own '(omitted)' entry for developed in the FE column.\n"
)

# The FE column's printed Constant (-0.1783, SE 0.1656) is NOT reproduced. Stata's
# xtreg,fe constant is the grand mean of y minus the within slopes times the grand
# means of x (feols does not report an intercept for an absorbed fixed effect at
# all), and the frozen st_xtreg_fe_cons() helper that recovers it does so only for
# an UNWEIGHTED xtreg (it demeans by the unweighted per-group mean and adds back
# the unweighted grand mean -- see stata_compat.R). Table 9's FE column is
# weighted by investperst, and there is no weighted equivalent of that helper
# available, so this one cell is left out of results.json rather than computed by
# a hand-rolled weighted-demeaning formula outside the frozen wrappers.

# ---------------------------------------------------------------------------
# Assemble results.json
# ---------------------------------------------------------------------------
out <- list()
out[["T9 OLS N"]] <- stats::nobs(m_ols)
out[["T9 OLS Studies"]] <- n_studies
out[["T9 FE N"]] <- stats::nobs(m_fe)
out[["T9 FE Studies"]] <- n_studies

for (v in c(allvars, "(Intercept)")) {
  lab <- if (v == "(Intercept)") "Constant" else v
  row <- co_ols[co_ols$term == v, ]
  if (nrow(row) == 1) {
    out[[sprintf("T9 OLS %s coef", lab)]] <- unname(row$estimate)
    out[[sprintf("T9 OLS %s se", lab)]]   <- unname(row$std.error)
    cat(sprintf("T9 OLS %s coef = %.4f\n", lab, row$estimate))
    cat(sprintf("T9 OLS %s se = %.4f\n", lab, row$std.error))
  }
}

for (v in fe_vars) {
  row <- co_fe[co_fe$term == v, ]
  if (nrow(row) == 1) {
    out[[sprintf("T9 FE %s coef", v)]] <- unname(row$estimate)
    out[[sprintf("T9 FE %s se", v)]]   <- unname(row$std.error)
    cat(sprintf("T9 FE %s coef = %.4f\n", v, row$estimate))
    cat(sprintf("T9 FE %s se = %.4f\n", v, row$std.error))
  }
}

cat("\n")
stata_compat_log()

jsonlite_ok <- requireNamespace("jsonlite", quietly = TRUE)
if (jsonlite_ok) {
  writeLines(jsonlite::toJSON(out, auto_unbox = TRUE, digits = 10), "results.json")
} else {
  esc <- function(s) gsub('"', '\\"', s, fixed = TRUE)
  lines <- vapply(names(out), function(k) {
    v <- out[[k]]
    sprintf('  "%s": %s', esc(k),
            if (is.numeric(v)) format(v, digits = 12, scientific = FALSE, trim = TRUE) else sprintf('"%s"', esc(v)))
  }, character(1))
  json_txt <- paste0("{\n", paste(lines, collapse = ",\n"), "\n}\n")
  writeLines(json_txt, "results.json")
}

cat("\nWrote results.json with", length(out), "entries.\n")
