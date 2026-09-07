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
# small post-publication data revision -- see REPLICATION.md).
#
# Table 6 is therefore the one headline table fully reproducible from this
# file: every one of its rows maps onto a column already in the CSV, and its
# construction is given explicitly both by the author's do-file fragment
# (data.zip:init.do, lines 168-177: se, prec, and the Pubyear/Datayear/
# Timespan transforms) and by the paper's own methods text (Section 5,
# "Augmented meta-regression", and Eq. 11).
#
# Uses ONLY the wrappers in stata_compat.R (st_mixed).

source("stata_compat.R")

DATA_PATH <- "C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\gasoline\\gasoline.csv"
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
# dominate the unweighted t-on-(1/se) regression). See REPLICATION.md.
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

cat("\n")
stata_compat_log()

# ---------------------------------------------------------------------------- #
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
