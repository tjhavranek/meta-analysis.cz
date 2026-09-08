# Replication of Havranek & Kokes (2015), "Income elasticity of gasoline
# demand: A meta-analysis", Energy Economics 47, 77-86.
# https://doi.org/10.1016/j.eneco.2014.11.004
#
# Target: Table 6, "Determinants of heterogeneity in the reported long-run
# estimates" -- the paper's augmented (multivariate) meta-regression, three
# specifications, estimated as a mixed-effects multilevel model with a
# random intercept by study (paper's Eq. 11, Section 5).
#
# ---------------------------------------------------------------------------
# WHY TABLE 6 AND NOT TABLES 2-5
# ---------------------------------------------------------------------------
# The paper's data set (Dahl 2012) covers BOTH short-run (N=831) and
# long-run (N=346+346=692, split by whether the model controls for vehicle
# stock) estimates. Tables 2-5 report results for all three of those
# sub-samples side by side ("Short-run / Long-run vehicle stock / Long-run
# no vehicle stock"), so their "Whole sample" (short-run) column needs
# short-run estimates.
#
# The CSV the site publishes (data/v1/gasoline/gasoline.csv, 701 rows) does
# NOT carry a short-run/long-run indicator, and its range of the dependent
# variable `e` (-1.13 to 2.98) matches exactly the LONG-RUN range printed in
# the paper's Table 2 -- not the short-run range (-1.17 to 3). Its `Carstock`
# column splits ~50/50 (350/351), matching the paper's two long-run
# sub-samples (346/346) almost exactly. This means the published CSV is the
# LONG-RUN sample only (pooling the vehicle-stock and no-vehicle-stock
# groups, with Carstock as a regressor) -- i.e. exactly the sample used for
# Table 6 (paper's own N = 692; our revision file has 701 rows, presumably a
# small post-publication data revision).
#
# Table 6 is therefore the one headline table fully reproducible from this
# file: every one of its rows maps onto a column already in the CSV, and its
# construction is given explicitly both by the author's do-file fragment
# (data.zip:init.do, lines 168-177: se, prec, and the Pubyear/Datayear/
# Timespan transforms) and by the paper's own methods text (Section 5,
# "Augmented meta-regression", and Eq. 11).
#
# Uses ONLY the wrappers in stata_compat.R (st_mixed).

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/gasoline/replication/stata_compat.R")

DATA_PATH <- (if (file.exists("gasoline.csv")) "gasoline.csv" else
     "https://meta-analysis.cz/data/v1/gasoline/gasoline.csv")
d <- read.csv(DATA_PATH, stringsAsFactors = FALSE)

stopifnot(nrow(d) == 701)

# ---------------------------------------------------------------------------
# data.zip:init.do lines 168-169: se and precision from the reported
# elasticity and its t-statistic.
d$se   <- abs(d$e / d$tstat)
d$prec <- 1 / d$se

stopifnot(all(is.finite(d$se)), all(d$se > 0))

# ---------------------------------------------------------------------------
# TRIM: precision (1/se) >= 100 is excluded. This is not spelled out in the
# do-file fragment we have (which stops at line 185, before any regression
# command), but data.zip:init.do lines 85-87 apply exactly this bound
# ("Ysrseinv < 100", "Ystatseinv < 100") when identifying observations for a
# related robustness statistic, so a same-threshold cut for the main
# regression sample is a documented author convention, not an invented one.
# It is confirmed empirically: dropping the 9 rows with prec >= 100 takes
# N from 701 to exactly 692 -- the paper's own N for Table 6 (and for the
# Carstock-split Tables 2-5, splitting further into 346 + 346, again exactly
# the paper's printed N). Every cell of Tables 3, 4 and 6 recomputed below
# matches the printed value only once this trim is applied; without it the
# coefficients are systematically off (a handful of extreme-precision points
# dominate the unweighted t-on-(1/se) regression).
n_before <- nrow(d)
d <- d[d$prec < 100, ]
stopifnot(nrow(d) == 692)

# lines 174-177: recentre/rescale the data-characteristic moderators.
d$pubyear_c   <- d$Pubyear  - 1966     # line 174
d$datayear_c  <- d$Datayear - 1946.5   # line 175
d$timespan_ln <- log(d$Timespan)       # line 176
# (line 177's sqrtn is not one of Table 6's regressors and is unused here.)

stopifnot(all(is.finite(d$timespan_ln)))

# ---------------------------------------------------------------------------
# Paper Section 5 / Eq. (11): every moderator is divided by se EXCEPT the two
# "publication characteristics" (Published, Publication year), which enter
# undivided (the S_l terms of Eq. 11); footnote to Table 6 states this
# explicitly ("All variables except those in italics are divided by the
# standard error").
divse <- function(x) x / d$se

d$prec            <- d$prec                    # already 1/se
d$datayear_se     <- divse(d$datayear_c)
d$timespan_se     <- divse(d$timespan_ln)
d$quarterly_se    <- divse(d$Quarterly)
d$monthly_se      <- divse(d$Monthly)
d$cross_se        <- divse(d$Cross_section)
d$timeseries_se   <- divse(d$Timeseries)
d$carstock_se     <- divse(d$Carstock)
d$static_se       <- divse(d$Static)
d$ols_se          <- divse(d$ols)
d$iv_se           <- divse(d$iv)
d$sur_se          <- divse(d$sur)
d$ml_se           <- divse(d$ml)
d$ecm_se          <- divse(d$ecm)
d$gls_se          <- divse(d$gls)
d$developing_se   <- divse(d$Developing)
d$australia_se    <- divse(d$Australia)
d$canada_se       <- divse(d$Canada)
d$france_se       <- divse(d$France)
d$germany_se      <- divse(d$Germany)
d$japan_se        <- divse(d$Japan)
d$sweden_se       <- divse(d$Sweden)
d$usa_se          <- divse(d$usa)
# Published, pubyear_c enter undivided.

# ---------------------------------------------------------------------------
# Three specifications, `mixed t ... || Studyid:` (Stata) = lmer with a
# random intercept by Studyid, ML (not REML) -- st_mixed() pins this.
#
# Spec (1): data + method characteristics only (15 non-constant terms).
f1 <- tstat ~ prec + datayear_se + timespan_se + quarterly_se + monthly_se +
  cross_se + timeseries_se + carstock_se + static_se + ols_se + iv_se +
  sur_se + ml_se + ecm_se + gls_se + (1 | Studyid)

# Spec (2): (1) + 8 region/geography dummies.
f2 <- update(f1, . ~ . - (1 | Studyid) + developing_se + australia_se +
               canada_se + france_se + germany_se + japan_se + sweden_se +
               usa_se + (1 | Studyid))

# Spec (3): (2) + 2 publication characteristics (undivided).
f3 <- update(f2, . ~ . - (1 | Studyid) + Published + pubyear_c + (1 | Studyid))

m1 <- st_mixed(f1, data = d)
m2 <- st_mixed(f2, data = d)
m3 <- st_mixed(f3, data = d)

# ---------------------------------------------------------------------------
# Extract fixed-effect coefficients and t-values (lmer's `coef()` method
# returns per-group combined fixed+random effects, not what we want here --
# summary()$coefficients gives the fixed-effects table directly, following
# the same convention already used in packages/finance_growth/run.R and
# packages/dst/run.R).
term_map <- c(
  "1/se"                 = "prec",
  "Mean year of data"    = "datayear_se",
  "Time span"            = "timespan_se",
  "Quarterly data"       = "quarterly_se",
  "Monthly data"         = "monthly_se",
  "Cross-section"        = "cross_se",
  "Time series"          = "timeseries_se",
  "Vehicle stock"        = "carstock_se",
  "Static model"         = "static_se",
  "OLS"                  = "ols_se",
  "IV"                   = "iv_se",
  "SUR"                  = "sur_se",
  "ML"                   = "ml_se",
  "ECM"                  = "ecm_se",
  "GLS"                  = "gls_se",
  "Developing countries" = "developing_se",
  "Australia"            = "australia_se",
  "Canada"               = "canada_se",
  "France"               = "france_se",
  "Germany"              = "germany_se",
  "Japan"                = "japan_se",
  "Sweden"               = "sweden_se",
  "USA"                  = "usa_se",
  "Published"            = "Published",
  "Publication year"     = "pubyear_c",
  "Constant"             = "(Intercept)"
)

results <- list()
emit <- function(label, value) {
  results[[label]] <<- as.numeric(value)
  cat(sprintf("%-34s %s\n", label, format(value, digits = 10)))
}

models <- list(`1` = m1, `2` = m2, `3` = m3)
for (spec in names(models)) {
  m <- models[[spec]]
  fx <- summary(m)$coefficients
  for (label in names(term_map)) {
    term <- term_map[[label]]
    if (term %in% rownames(fx)) {
      emit(sprintf("T6 c%s %s coef", spec, label), fx[term, "Estimate"])
      emit(sprintf("T6 c%s %s t",    spec, label), fx[term, "Estimate"] / fx[term, "Std. Error"])
    }
  }
  emit(sprintf("T6 c%s Observations", spec), stats::nobs(m))
}

# ---------------------------------------------------------------------------
# NUMBERS FROM THE PAPER'S OWN TEXT (abstract & conclusion)
# ---------------------------------------------------------------------------
# Abstract: "Our results suggest that the income elasticity of gasoline
# demand is on average much smaller than reported in previous surveys: the
# mean corrected for publication bias is 0.1 for the short run and 0.23 for
# the long run."
# Conclusion (Section 7): "the mean reported short-run elasticity is only
# 0.1 ... The long-run estimate corrected for publication bias is 0.23,
# about one-fourth the size of the estimate reported by Espey (1998)."
# Section 6 (discussion of "best practice" estimates) pins the 0.23 number
# down precisely: "The estimates ... are consistent with our corrected mean
# for all elasticities computed with control for vehicle stock presented in
# the last section, 0.23" -- i.e. the headline "0.23 long run" figure IS the
# Table 4 long-run/vehicle-stock "1/se" coefficient (printed 0.234), not an
# average across the vehicle-stock and no-vehicle-stock columns.
#
# Table 4's model is the Section 3.2 funnel-asymmetry test with the
# quadratic correction of Stanley & Doucouliagos (2007) added (paper's
# Eq. 10, extended to the mixed-effects model as Eq. 12):
#     t_ij = beta/se_ij + gamma0 * se_ij + u_i + eps_ij
# (no separate intercept alpha0 -- Table 4 as printed has no Constant row),
# with the same random-intercept-by-Studyid mixed model used for Table 6.
# We fit it on the two Carstock subsamples of the same 692-row trimmed
# sample used above (the trim, and the fact that this file is long-run-only
# data, are both established above and in REPLICATION_STATUS.md).
d_vs   <- d[d$Carstock == 1, ]   # long run, WITH vehicle-stock control (paper N = 346)
d_novs <- d[d$Carstock == 0, ]   # long run, WITHOUT vehicle-stock control (paper N = 346)
stopifnot(nrow(d_vs) == 346, nrow(d_novs) == 346)

f4 <- tstat ~ prec + se - 1 + (1 | Studyid)
m4_vs   <- st_mixed(f4, data = d_vs)
m4_novs <- st_mixed(f4, data = d_novs)

report_t4 <- function(m, label, n_expected) {
  fx       <- summary(m)$coefficients
  coef_val <- fx["prec", "Estimate"]
  t_val    <- coef_val / fx["prec", "Std. Error"]
  n        <- stats::nobs(m)
  stopifnot(n == n_expected)
  emit(sprintf("T4 %s 1/se coef", label), coef_val)
  emit(sprintf("T4 %s 1/se t",    label), t_val)
  emit(sprintf("T4 %s Observations", label), n)
  coef_val
}

coef_long_vs   <- report_t4(m4_vs,   "LongRun VehicleStock",   346)
coef_long_novs <- report_t4(m4_novs, "LongRun NoVehicleStock", 346)

# The paper's headline sentence rounds this Table 4 cell to one/two decimal
# places ("0.23"). Record that mapping explicitly as its own labeled result,
# separate from the full-precision Table 4 cell above, so the link between
# table cell and text sentence is checkable rather than implicit.
emit("Headline paper-text: long-run elasticity corrected for publication bias (paper says 0.23)",
     coef_long_vs)

cat("\n")
cat("========================================================================\n")
cat("NUMBERS FROM THE PAPER'S OWN TEXT (abstract & conclusion)\n")
cat("========================================================================\n")
cat('Paper: "the mean corrected for publication bias is 0.1 for the short\n')
cat(' run and 0.23 for the long run." (Abstract; restated in the Conclusion.)\n\n')

cat(sprintf("LONG RUN  -- paper states 0.23  -->  produced %.4f  (rounds to %.2f)\n",
            coef_long_vs, round(coef_long_vs, 2)))
cat("  Computed as: Table 4's Heckman-type quadratic meta-regression\n")
cat("  (t = beta/se + gamma0*se, mixed-effects by Studyid), the '1/se'\n")
cat("  coefficient, fit on the long-run/vehicle-stock subsample (N = 346).\n")
cat("  Section 6 of the paper explicitly identifies this Table 4 cell as\n")
cat("  the number behind the headline '0.23' figure.\n")
cat(sprintf("  [Context only, not part of the headline claim: the long-run/\n"))
cat(sprintf("   NO-vehicle-stock subsample gives %.4f, the paper's OTHER\n",
            coef_long_novs))
cat("   Table 4 long-run column (printed 0.644).]\n\n")

cat("SHORT RUN -- paper states 0.1  -->  NOT COMPUTABLE from this data set.\n")
cat("  The short-run elasticity (Table 4's printed 0.0999, N = 831) needs\n")
cat("  the short-run subsample of Dahl's (2012) data. The CSV this package\n")
cat("  reads (data/v1/gasoline/gasoline.csv) contains only the LONG-RUN\n")
cat("  sample (701 rows before trim / 692 after -- see the Table 6\n")
cat("  derivation above): its 'e' range and its\n")
cat("  Carstock 350/351 split match the paper's long-run sample exactly,\n")
cat("  and the file carries no short-run indicator or short-run rows.\n")
cat("  No short-run number is produced here -- none is fabricated to fill\n")
cat("  the gap. See targets.json, where this figure is listed with kind\n")
cat("  'headline' and no matching entry in results.json (NOT_COMPUTED).\n")

cat("\n")
stata_compat_log()

# ---------------------------------------------------------------------------- #

# ============================================================================ #
# THE PAPER'S OWN HEADLINE SENTENCE, and the summary statistics behind it.
#
# Abstract: "The studies cover many countries and report a mean elasticity of 0.28 for the short
# run and 0.66 for the long run." Section 1 repeats it: "The average reported elasticity for the
# short run is 0.28; for the long run it is 0.66."
#
# That 0.66 is a plain unweighted mean of the reported elasticities over the long-run estimation
# sample, and Table 5 prints it to three digits as 0.663 ("Sample mean", "Long-run Whole sample").
# Until now this package reproduced Tables 3, 4 and 6 but never the sentence a reader actually
# quotes, so it is computed here, together with the Table 2 summary statistics that decompose it.
#
# The 0.28 is the SHORT-RUN sample, which this site does not publish; it stays unproduced, as
# documented above.
lr_all  <- d$e
lr_vs   <- d$e[d$Carstock == 1]
lr_novs <- d$e[d$Carstock == 0]

results[["T5 sample mean, long run whole sample (the abstract's 0.66)"]] <- mean(lr_all)
results[["T5 sample mean, long run vehicle stock"]]                      <- mean(lr_vs)
results[["T5 sample mean, long run no vehicle stock"]]                   <- mean(lr_novs)

results[["T2 long run vehicle stock, median"]]    <- stats::median(lr_vs)
results[["T2 long run vehicle stock, sd"]]        <- stats::sd(lr_vs)
results[["T2 long run vehicle stock, max"]]       <- max(lr_vs)
results[["T2 long run no vehicle stock, sd"]]     <- stats::sd(lr_novs)
results[["T2 long run no vehicle stock, min"]]    <- min(lr_novs)
results[["T2 long run no vehicle stock, max"]]    <- max(lr_novs)

# Table 5's "Weighted mean" row (0.614 whole, 0.424 vehicle stock, 0.857 no vehicle stock) is
# NOT produced. The paper states no weighting scheme for it -- Table 5 carries no note, and
# nothing in the text defines the weights. Six candidate rules were tried against all three
# printed cells at once, and none reproduces them:
#
#   rule                                   whole     vehicle stock   no vehicle stock
#   paper                                  0.614     0.424           0.857
#   1 / estimates per study                0.618     0.404           0.859
#   1 / estimates per study (untrimmed)    0.619     0.400           0.863
#   1 / estimates per study, within cell   0.633     0.415           0.879
#   inverse variance 1/se^2                0.426     0.335           0.480
#   number of observations                 0.656     0.517           0.816
#   sqrt(number of observations)           0.667     0.486           0.870
#
# The study-equal-weight rule is close on the no-vehicle-stock cell and clearly wrong on the
# vehicle-stock one, so it is not the rule with a rounding difference -- it is a different rule.
# Guessing further would mean tuning a weight vector until three numbers landed, which is the one
# thing this package must not do. The three cells are listed in targets.json and left NOT
# COMPUTED. Recovering them needs the author's own code for Table 5, which is not on the site.

cat("\n== The paper's headline sentence ==\n")
cat(sprintf("Mean long-run income elasticity (abstract: 0.66; Table 5: 0.663): %.4f  [n=%d]\n",
            mean(lr_all), length(lr_all)))
cat(sprintf("  with vehicle stock    (Table 2/5: 0.465): %.4f  [n=%d]\n", mean(lr_vs), length(lr_vs)))
cat(sprintf("  without vehicle stock (Table 2/5: 0.861): %.4f  [n=%d]\n", mean(lr_novs), length(lr_novs)))
cat("Table 5's weighted means are NOT produced: the paper defines no weighting scheme for them.\n")


results_out <- lapply(results, function(x) unname(as.numeric(x)))

write_json_simple <- function(lst, path) {
  esc <- function(s) gsub('"', '\\\\"', s)
  lines <- vapply(names(lst), function(nm) {
    sprintf('  "%s": %s', esc(nm), format(lst[[nm]], digits = 15, scientific = FALSE))
  }, character(1))
  writeLines(c("{", paste(lines, collapse = ",\n"), "}"), path)
}

this_file <- commandArgs(trailingOnly = FALSE)
script_arg <- sub("^--file=", "", this_file[grepl("^--file=", this_file)])
script_dir <- if (length(script_arg)) dirname(normalizePath(script_arg)) else getwd()
out_file <- file.path(script_dir, "results.json")

write_json_simple(results_out, out_file)
cat("\nWrote results.json to", out_file, "\n")
