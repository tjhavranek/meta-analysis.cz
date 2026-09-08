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

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/competition/replication/stata_compat.R")

d <- read.csv(
  (if (file.exists("competition.csv")) "competition.csv" else
     "https://meta-analysis.cz/data/v1/competition/competition.csv"),
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
# The one piece of Stata that has to be written out by hand: the within
# transformation `xtreg, fe` performs before it fits, generalized to weights.
# ---------------------------------------------------------------------------
# Stata subtracts each group mean and adds the grand mean back, then fits an
# ordinary regression WITH a constant on the transformed data; that constant is
# the `_cons` xtreg prints and fixest does not report for an absorbed fixed
# effect. stata_compat.R's frozen st_xtreg_fe_cons() does exactly this, but only
# unweighted and only for one regressor. Both of this paper's fixed-effects
# tables (Table 2 and Table 9) are weighted by investperst, so the transformation
# is spelled out here with weighted group means and a weighted grand mean. It is
# bare arithmetic -- tapply() and sum(), no estimator -- and every model fit that
# uses its output goes through a sanctioned st_* wrapper.
demean_add_weighted <- function(v, w, g) {
  grp_sum_w  <- tapply(w, g, sum)
  grp_sum_wv <- tapply(w * v, g, sum)
  grp_mean_w <- (grp_sum_wv / grp_sum_w)[as.character(g)]
  v - as.numeric(grp_mean_w) + sum(w * v) / sum(w)
}

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

# ---------------------------------------------------------------------------
# Table 9, FE column: the Constant (-0.1783, SE 0.1656).
# ---------------------------------------------------------------------------
# feols reports no intercept for an absorbed fixed effect. Stata's does, and it
# is simply the intercept of the within regression described above: PCC and the
# 35 moderators demeaned by their WEIGHTED study means with the WEIGHTED grand
# mean added back, fitted with a constant, weighted by investperst and clustered
# by IDStudy. The seven regressors that are constant within every study become
# constant outright under that transformation and are dropped for collinearity --
# the same seven Stata reports as "(omitted)": developed, dummies, Logit,
# citations, firstpub, IFrecursive, reviewed_journal.
#
# The wrapper choice here is the whole ballgame and was settled against Stata
# 15.1 rather than argued (stata_work_competition/probe3.do, probeA.R):
#
#   Stata   xtreg PCC <35 vars> [pweight=investperst], fe vce(cluster IDStudy)
#             _cons = -0.1783159629   se = 0.1655517838
#   st_regress on the transformed data (fixest DEFAULT ssc = Stata small-sample,
#   which is what st_xtreg_fe and st_xtreg_fe_cons already use)
#             _cons = -0.1783159609   se = 0.1655517902     <- nine digits
#   st_ivreg2 on the same transformed data (ivreg2's LARGE-SAMPLE variance)
#             _cons = -0.1783159609   se = 0.1589946934     <- point right, SE wrong
#
# Stata's own run of the full Table 9 FE specification reproduces every printed
# cell of that column, constant included, so the -0.1783 (0.1656) below is
# checked against Stata and not only against the PDF.
d_cons <- data.frame(
  ya = demean_add_weighted(d$PCC, d$investperst, d$IDStudy),
  g  = d$IDStudy,
  w  = d$investperst
)
d_cons$X <- as.matrix(
  vapply(fe_vars,
         function(v) demean_add_weighted(d[[v]], d$investperst, d$IDStudy),
         numeric(nrow(d)))
)
m_fe_cons  <- st_regress(ya ~ X, data = d_cons, cluster = ~g, weights = ~w)
co_fe_cons <- st_coefs(m_fe_cons, z = FALSE)
fe_cons    <- co_fe_cons[co_fe_cons$term == "(Intercept)", ]
cat(sprintf("\nT9 FE Constant coef = %.4f   se = %.4f   (Table 9 prints -0.1783, 0.1656)\n",
            fe_cons$estimate, fe_cons$std.error))

# ===========================================================================
# Numbers stated in the paper's own text: the site's "close to zero" claim.
# ===========================================================================
# meta-analysis.cz summarises this paper as "close to zero". That is the
# paper's own phrase, and it appears (at least) five times. The clearest,
# most load-bearing occurrence is the paper's own summary of its results, in
# Section 7 ("Concluding Remarks", p.977):
#
#   "We conduct a meta-regression analysis of 598 estimates of the
#   relationship between bank competition and financial stability reported
#   in 31 studies. ... Our results suggest that the mean reported estimate
#   of the relationship is close to zero, even after correcting for
#   publication bias and potential misspecification problems."
#
# That sentence bundles together two distinct quantities, both computable
# from the published CSV:
#   (a) "the mean reported estimate" -- the RAW, uncorrected mean PCC across
#       all 598 estimates (and the weighted version, and the developed /
#       developing subsamples) -- Table 1 (p.958) and Figure 3's text
#       (p.959), both of which use the identical phrase "close to zero":
#         Table 1 note: "the mean PCCs of the competition coefficient
#         estimates ... over all countries and for selected country groups."
#         Text (p.959): "the PCCs are symmetrically distributed around zero
#         with a mean of -0.0009 ... the mean of the study-level medians is
#         also close to zero and equals 0.0099."
#   (b) "even after correcting for publication bias" -- the intercept
#       ("Constant", labelled "effect beyond bias") of the funnel-asymmetry
#       (FAT-PET) regression in Table 2 (p.960, Equation 7):
#         PCC_ij = beta0 + beta1 * SE(PCC)_ij + e_ij
#       run with study fixed effects, clustered by study, in four flavours
#       (unweighted / weighted-by-investperst, all studies / published only).
#       Table 2's own text (p.961): "the estimated size of the
#       competition-stability effect beyond publication bias appears to be
#       close to zero, especially for weighted results." beta0 is exactly
#       the number that JUSTIFIES the phrase: a small, mostly-still-positive
#       intercept, next to a publication-bias slope (beta1) an order of
#       magnitude larger in absolute value.
#
# ---------------------------------------------------------------------------
# (a) Raw (uncorrected) mean PCC -- Table 1 and Figure 3's text.
# ---------------------------------------------------------------------------
# Plain (weighted) means -- no estimator involved, so no stata_compat.R
# wrapper is needed or used here; this is arithmetic identical to what Stata's
# `summarize` / `sum ... [aw=investperst]` would report.
w_all <- d$investperst
mean_all_unw   <- mean(d$PCC)
mean_all_w     <- sum(w_all * d$PCC) / sum(w_all)
mean_dev_unw   <- mean(d$PCC[d$developed == 1])
mean_dev_w     <- {ww <- w_all[d$developed == 1]; sum(ww * d$PCC[d$developed == 1]) / sum(ww)}
mean_undev_unw <- mean(d$PCC[d$undeveloped == 1])
mean_undev_w   <- {ww <- w_all[d$undeveloped == 1]; sum(ww * d$PCC[d$undeveloped == 1]) / sum(ww)}
mean_published <- mean(d$PCC[d$reviewed_journal == 1])

# (Printed together with the Table 2 numbers at the very end of this script,
# after the Table 9 output, so the paper's headline claim is the last thing
# printed rather than buried in the middle of the run.)

# p.959 also states "the mean of the study-level medians is also close to zero
# and equals 0.0099." The author's own published do-file builds that quantity in
# two lines (competition.do, lines 13 and 21):
#
#     bysort IDStudy: egen PCCmed = median(PCC)
#     mean PCCmed
#
# `egen` writes a study's median onto EVERY estimate of that study, so `mean
# PCCmed` averages over the 598 estimates and not over the 31 studies: a study
# enters in proportion to how many estimates it reports. That is a different
# number from the mean across studies, and it is the one the paper quotes. An
# earlier version of this file took the other reading -- mean(tapply(d$PCC,
# d$IDStudy, median)) across the 31 studies, which is -0.0042 -- and reported
# the figure as not reproduced. The do-file settles which was meant.
#
# Stata on the published CSV agrees to every digit
# (stata_work_competition/probe1.do):
#     egen med = median(PCC), by(IDStudy)  /  summarize med   ->  mean .0099988
# and this script gets 0.00999882.
#
# One caveat, stated plainly rather than rounded away: Stata displays that mean
# as .0099988, and the paper's text carries it TRUNCATED rather than rounded, as
# "0.0099". The value the author's own command returns rounds to 0.0100 at four
# decimals, so this one target still misses in its fourth digit -- not because a
# different quantity is being computed, but because the printed digit is one
# below what the computation gives. The computed value is reported unadjusted.
mean_study_medians <- mean(as.numeric(
  tapply(d$PCC, d$IDStudy, median)[as.character(d$IDStudy)]
))

# ---------------------------------------------------------------------------
# (b) Publication-bias-corrected effect ("close to zero, especially for
#     weighted results") -- Table 2's Fixed Effects columns.
# ---------------------------------------------------------------------------
# Table 2 also has "Instrument" columns (SE instrumented by log sample size).
# Those were attempted and set aside: reproducing the point estimate is easy
# (a study-demeaned 2SLS via st_ivreg2's `y ~ 1 | endog ~ instrument` syntax
# recovers beta1 = -1.614, matching the printed -1.614 to 3 decimals), but the
# recovered clustered SE does not reproduce the printed significance stars
# (produced p = 0.11, vs. the paper's "***"), so the Instrument column is not
# claimed as reproduced and is left out of the targets below -- only the plain
# Fixed Effects columns, which match on point estimate, SE, AND significance
# together, are reported as headline numbers.
#
# `st_xtreg_fe` gives the slope (beta1) directly. Stata's `xtreg, fe` also
# prints a constant (beta0) that `feols` does not report for an absorbed
# fixed effect; `stata_compat.R`'s own `st_xtreg_fe_cons()` helper recovers it
# for the UNWEIGHTED case (grand mean of y minus the within slope times the
# grand mean of x, via an augmented within regression -- see stata_compat.R).
# For the WEIGHTED case the two steps are the ones already used above for Table
# 9's FE constant:
#   1. demean_add_weighted() -- PCC and SEPCC demeaned by their WEIGHTED study
#      mean with the WEIGHTED grand mean added back, which is Stata's own
#      construction of the `xtreg, fe` constant generalized to weights (bare
#      arithmetic: tapply()/sum(), no estimator);
#   2. st_regress() on the transformed variables, weighted and clustered -- the
#      wrapper carrying the small-sample convention xtreg applies.
# CHECKED AGAINST STATA 15.1 (stata_work_competition/probe5.do and probeB.R),
# not only against the paper's three printed digits:
#      xtreg PCC SEPCC [pweight=investperst], fe vce(cluster IDStudy)
#        Stata  _cons 0.0342221630 (0.0068533321)
#        here   _cons 0.0342221630 (0.0068533322)
#      the same on reviewed_journal == 1
#        Stata  _cons 0.0436049459 (0.0081765678)
#        here   _cons 0.0436049455 (0.0081765676)
# Fitting step 2 with st_ivreg2 instead reproduces the constant itself -- the
# point estimate is the same under either wrapper -- but attaches ivreg2's
# LARGE-SAMPLE variance to it, giving 0.0067 and 0.0080
# where Stata reports 0.0069 and 0.0082. The paper prints only three digits of
# these coefficients and no standard error for them, so nothing in targets.json
# could catch that; Stata did.
fe_variant <- function(data, weights_col = NULL, label) {
  if (is.null(weights_col)) {
    m_fe   <- st_xtreg_fe(PCC ~ SEPCC, data = data, panel = "IDStudy")
    m_cons <- st_xtreg_fe_cons("PCC", "SEPCC", "IDStudy", data)
    co_cons <- st_coefs(m_cons)
  } else {
    w <- data[[weights_col]]
    m_fe <- st_xtreg_fe(PCC ~ SEPCC, data = data, panel = "IDStudy", weights = ~investperst)
    ya <- demean_add_weighted(data$PCC, w, data$IDStudy)
    xa <- demean_add_weighted(data$SEPCC, w, data$IDStudy)
    d2 <- data.frame(ya = ya, xa = xa, g = data$IDStudy, w = w)
    m_cons <- st_regress(ya ~ xa, data = d2, cluster = ~g, weights = ~w)
    co_cons <- st_coefs(m_cons, z = FALSE)
  }
  co_fe <- st_coefs(m_fe)
  list(
    slope_coef = co_fe$estimate[co_fe$term == "SEPCC"],
    slope_se   = co_fe$std.error[co_fe$term == "SEPCC"],
    cons_coef  = co_cons$estimate[co_cons$term == "(Intercept)"],
    cons_se    = co_cons$std.error[co_cons$term == "(Intercept)"],
    label = label
  )
}

t2_variants <- list(
  fe_variant(d,                              NULL,          "T2 FE (unweighted, all)"),
  fe_variant(d[d$reviewed_journal == 1, ],   NULL,          "T2 FE (unweighted, published)"),
  fe_variant(d,                              "investperst", "T2 FE (weighted, all)"),
  fe_variant(d[d$reviewed_journal == 1, ],   "investperst", "T2 FE (weighted, published)")
)
t2_printed <- list(
  "T2 FE (unweighted, all)"          = c(slope = -1.671, cons = 0.044),
  "T2 FE (unweighted, published)"    = c(slope = -1.898, cons = 0.073),
  "T2 FE (weighted, all)"            = c(slope = -1.568, cons = 0.034),
  "T2 FE (weighted, published)"      = c(slope = -1.636, cons = 0.044)
)

# (Printed together with the Table 1 numbers at the very end of this script --
# see "Numbers from the paper's text, printed" below, after the Table 9 output.)

# ---------------------------------------------------------------------------
# Assemble results.json
# ---------------------------------------------------------------------------
out <- list()
out[["T9 OLS N"]] <- stats::nobs(m_ols)
out[["T9 OLS Studies"]] <- n_studies
out[["T9 FE N"]] <- stats::nobs(m_fe)
out[["T9 FE Studies"]] <- n_studies

# --- Numbers from the paper's text ("close to zero" claim) ---------------
out[["Text T1 All mean PCC unweighted"]]         <- mean_all_unw
out[["Text T1 All mean PCC weighted"]]           <- mean_all_w
out[["Text T1 Developed mean PCC unweighted"]]   <- mean_dev_unw
out[["Text T1 Developed mean PCC weighted"]]     <- mean_dev_w
out[["Text T1 Undeveloped mean PCC unweighted"]] <- mean_undev_unw
out[["Text T1 Undeveloped mean PCC weighted"]]   <- mean_undev_w
out[["Text F3 Published mean PCC"]]              <- mean_published
# The key below keeps the label targets.json froze for this number, back when the
# quantity had not been identified. The oracle is frozen and is not edited, label
# included, so the stale parenthetical stays: what changed is the value under it,
# which is now the author's own do-file computation (0.0099988) rather than the
# wrong-aggregation -0.0042.
out[["Text F3 mean of study-level medians (NOT reproduced, see run.R)"]] <- mean_study_medians

for (v in t2_variants) {
  out[[sprintf("%s SEPCC coef", v$label)]]    <- unname(v$slope_coef)
  out[[sprintf("%s SEPCC se", v$label)]]      <- unname(v$slope_se)
  out[[sprintf("%s Constant coef", v$label)]] <- unname(v$cons_coef)
  out[[sprintf("%s Constant se", v$label)]]   <- unname(v$cons_se)
}

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

out[["T9 FE Constant coef"]] <- unname(fe_cons$estimate)
out[["T9 FE Constant se"]]   <- unname(fe_cons$std.error)

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

# ===========================================================================
# Numbers from the paper's text, printed last so they are the headline
# takeaway of the run: meta-analysis.cz summarises this paper as
# "close to zero", drawn from the paper's own Concluding Remarks (Section 7,
# p.977): "Our results suggest that the mean reported estimate of the
# relationship is close to zero, even after correcting for publication bias
# and potential misspecification problems."
# ===========================================================================
cat("\n================================================================\n")
cat("PAPER'S HEADLINE CLAIM: \"close to zero\"\n")
cat("  (Concluding Remarks, p.977: \"the mean reported estimate of the\n")
cat("   relationship is close to zero, even after correcting for\n")
cat("   publication bias and potential misspecification problems.\")\n")
cat("================================================================\n\n")

cat("-- (a) The raw, uncorrected mean reported estimate (Table 1 / Figure 3) --\n")
cat(sprintf("Text T1 All, unweighted mean PCC         = %.4f  (paper: -0.001; p.959 states -0.0009)\n", mean_all_unw))
cat(sprintf("Text T1 All, weighted mean PCC           = %.4f  (paper: -0.012)\n", mean_all_w))
cat(sprintf("Text T1 Developed, unweighted mean PCC   = %.4f  (paper: 0.020)\n", mean_dev_unw))
cat(sprintf("Text T1 Developed, weighted mean PCC     = %.4f  (paper: 0.011)\n", mean_dev_w))
cat(sprintf("Text T1 Undeveloped, unweighted mean PCC = %.4f  (paper: 0.001)\n", mean_undev_unw))
cat(sprintf("Text T1 Undeveloped, weighted mean PCC   = %.4f  (paper: -0.019)\n", mean_undev_w))
cat(sprintf("Text F3 Published studies, mean PCC      = %.4f  (paper: 0.0116)\n", mean_published))
cat(sprintf("Text F3 Mean of study-level medians       = %.7f  (paper: 0.0099, truncated from Stata's .0099988 -- see comment above mean_study_medians)\n", mean_study_medians))

cat("\n-- (b) The estimate corrected for publication bias (Table 2, Fixed Effects columns) --\n")
for (v in t2_variants) {
  printed <- t2_printed[[v$label]]
  cat(sprintf(
    "%-32s  SE(pub.bias) coef = %8.4f (se %.4f, paper %.3f)   Constant(effect beyond bias) = %7.4f (se %.4f, paper %.3f)\n",
    v$label, v$slope_coef, v$slope_se, printed["slope"], v$cons_coef, v$cons_se, printed["cons"]
  ))
}
cat(paste0(
  "\nThese four 'Constant (effect beyond bias)' values (0.034 to 0.073) are the numbers that\n",
  "justify the paper's own phrase: small, and an order of magnitude below the |beta1| ~ 1.6-1.9\n",
  "publication-bias slope estimated alongside each of them -- exactly Table 2's own reading\n",
  "(p.961): 'the estimated size of the competition-stability effect beyond publication bias\n",
  "appears to be close to zero, especially for weighted results' -- 0.034 being the smallest,\n",
  "and the full-sample weighted value the paper itself highlights.\n"
))
cat("================================================================\n")

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
