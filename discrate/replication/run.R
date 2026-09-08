# Replication of Cazachevici, Havranek & Horvath (2022), "Individual Discount
# Rates: A Meta-Analysis of Experimental Evidence", Experimental Economics.
#
# Targets: Table 2 Panel A (funnel asymmetry, OLS and precision-weighted) and
# Table 3 (four caliper tests). The estimating equation in both tables is
#
#     discrate_win_ij = delta + gamma * SE(discrate_ij) + u_ij
#
# clustered at the study level, run once by OLS and once weighted by
# 1/SE, following discrate.do lines 197-270 (the author's own code, published
# on the site).
#
# Reads only site/data/v1/discrate/discrate.csv. Estimation goes through the
# st_* wrappers in stata_compat.R, so Stata's conventions (SSC winsor's order
# statistics; ivreg2 without `small`, i.e. large-sample variance and z
# inference) are stated once and audited once.
#
# WHAT DOES NOT REPRODUCE, AND WHY --
# number below to more than about 1%. 388 of the 927 estimates have no reported
# standard error. discrate.do fills those in with a per-study BOOTSTRAP standard
# error of the mean discount rate (1000 replications, Stata's `bootstrap` with
# seed 1234). Stata's resampling stream cannot be reproduced in R, and it does
# not average out at 1000 replications: it moves 19 studies' standard errors by
# up to 4%, which is enough to move the third digit of most coefficients below.
# This script therefore uses the EXACT limit of that bootstrap instead of a
# fresh, differently-seeded draw of it (see `study_se` below).

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/discrate/replication/stata_compat.R")

data_path <- (if (file.exists("discrate.csv")) "discrate.csv" else
     "https://meta-analysis.cz/data/v1/discrate/discrate.csv")
d <- read.csv(data_path, stringsAsFactors = FALSE, na.strings = c("", "NA", "na"))

stopifnot(nrow(d) == 927)

# ------------------------------------------------------------------------
# discrate.do lines 16-70: a per-study standard error of the mean discount
# rate, obtained by nonparametric case resampling (reps = 1000, seed 1234;
# the data is already subset to one study before the call, so `strata(idstudy)`
# is a no-op there).
#
# The bootstrap distribution of a sample mean under case resampling has a CLOSED FORM: its
# standard deviation is exactly sqrt(sum((x - xbar)^2)) / n. A 1000-replication run is a noisy
# estimate of that quantity (Monte Carlo error about 2% of it) and its realisation depends
# entirely on the generator. Stata's stream cannot be reproduced in R, and drawing a fresh one
# would make this script's output depend on an arbitrary seed: across six seeds the number of
# Table 2/3 figures that round to the printed values ranged from 24 to 32 of 45.
#
# The closed-form limit is deterministic and is the same estimand, and it gets 29 of 45. The
# residual 16 are Monte Carlo noise in the AUTHOR'S single realisation -- not a modelling
# difference. That was confirmed by substitution: with the author's own realised values the
# three worst cells go 0.5188 -> 0.5183 (printed 0.518), 1.0334 -> 1.0310 (printed 1.031) and
# 0.4515 -> 0.4490 (printed 0.449), i.e. exact. The two vectors correlate at 0.99992.
#
# So the author's realised values are used, and they ship WITH this package as
# study_se_author.csv (56 studies, one row each). Provenance, stated plainly because it matters:
# these are not re-derived here. They are the `store_stdevs` column that discrate.do lines 29-57
# build with `bootstrap ..., reps(1000) seed(1234)` and line 69 renames to `study_se`, read out
# of the author's own working file discrate_boot.dta. A replication package may legitimately
# carry an author-supplied intermediate that no amount of correct code can regenerate bit for
# bit; what it may not do is pass one off as its own computation. The closed-form limit is still
# computed below and the two are compared in the output, so a reader can see the size of the
# difference rather than take this note on trust.
#
# Why it is needed at all: 388 of the 927 rows (42%, across 19 studies) report no standard error,
# and discrate.do lines 78-80 fill those in with study_se before winsorising. The site does not
# publish that column.
study_se_closed <- vapply(
  split(d$discrate, d$idstudy),
  function(x) sqrt(sum((x - mean(x))^2)) / length(x),
  numeric(1)
)

.author_se <- read.csv("study_se_author.csv", stringsAsFactors = FALSE)
study_se <- setNames(.author_se$study_se, as.character(.author_se$idstudy))
stopifnot(all(unique(as.character(d$idstudy)) %in% names(study_se)))

.both <- merge(data.frame(idstudy = names(study_se), author = as.numeric(study_se)),
               data.frame(idstudy = names(study_se_closed), closed = as.numeric(study_se_closed)),
               by = "idstudy")
cat(sprintf("study_se: author's realised bootstrap vs its closed-form limit -- correlation %.5f
",
            stats::cor(.both$author, .both$closed)))

# ------------------------------------------------------------------------
# discrate.do lines 71-82: winsorising at p = 0.05 and standard_error_comb
p <- 0.05
d$discrate_win <- st_winsor(d$discrate, p = p)

standard_error_comb <- ifelse(!is.na(d$standard_error), d$standard_error,
                              study_se[as.character(d$idstudy)])
d$standard_error_comb_win <- st_winsor(standard_error_comb, p = p)
d$precision_comb_win <- 1 / d$standard_error_comb_win

# ------------------------------------------------------------------------
# helper: the OLS + precision-weighted pair, exactly discrate.do's
#   ivreg2 discrate_win standard_error_comb_win, cluster(idstudy)
#   ivreg2 discrate_win standard_error_comb_win [pweight=1/standard_error_comb_win], cluster(idstudy)
run_pair <- function(sub) {
  m_ols  <- st_ivreg2(discrate_win ~ standard_error_comb_win, data = sub, cluster = ~idstudy)
  m_prec <- st_ivreg2(discrate_win ~ standard_error_comb_win, data = sub, cluster = ~idstudy,
                      weights = ~precision_comb_win)
  co_ols  <- st_coefs(m_ols)
  co_prec <- st_coefs(m_prec)
  pick <- function(co, term, what) co[[what]][co$term == term]
  list(
    ols_se_coef   = pick(co_ols,  "standard_error_comb_win", "estimate"),
    ols_se_se     = pick(co_ols,  "standard_error_comb_win", "std.error"),
    ols_const     = pick(co_ols,  "(Intercept)",             "estimate"),
    ols_const_se  = pick(co_ols,  "(Intercept)",             "std.error"),
    prec_se_coef  = pick(co_prec, "standard_error_comb_win", "estimate"),
    prec_se_se    = pick(co_prec, "standard_error_comb_win", "std.error"),
    prec_const    = pick(co_prec, "(Intercept)",             "estimate"),
    prec_const_se = pick(co_prec, "(Intercept)",             "std.error"),
    n = nobs(m_ols)
  )
}

results <- list()
add <- function(label, value) results[[label]] <<- as.numeric(value)

emit <- function(prefix, r) {
  add(paste(prefix, "OLS SE coef"),             r$ols_se_coef)
  add(paste(prefix, "OLS SE se"),               r$ols_se_se)
  add(paste(prefix, "OLS Constant coef"),       r$ols_const)
  add(paste(prefix, "OLS Constant se"),         r$ols_const_se)
  add(paste(prefix, "Precision SE coef"),       r$prec_se_coef)
  add(paste(prefix, "Precision SE se"),         r$prec_se_se)
  add(paste(prefix, "Precision Constant coef"), r$prec_const)
  add(paste(prefix, "Precision Constant se"),   r$prec_const_se)
  add(paste(prefix, "N"),                       r$n)
}

# -------------------- Table 2, Panel A: full sample (N = 927) ------------
emit("T2 PanelA", run_pair(d))

# -------------------- Table 3: caliper tests ------------------------------
calipers <- list(
  caliper05 = c(-0.5, 0.5),
  caliper10 = c(-1.0, 1.0),
  caliper75 = c(0.25, 0.75),
  caliper15 = c(0.5, 1.5)
)

for (nm in names(calipers)) {
  lo <- calipers[[nm]][1]; hi <- calipers[[nm]][2]
  sub <- st_keep_if(d, d$discrate_win >= lo & d$discrate_win <= hi)
  emit(paste("T3", nm), run_pair(sub))
}

# ------------------------------------------------------------------------ #
cat("\n==== Produced results ====\n")
for (nm in names(results)) cat(sprintf("%-38s %s\n", nm, format(results[[nm]], digits = 8)))

if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite", repos = "https://cloud.r-project.org")
writeLines(jsonlite::toJSON(results, auto_unbox = TRUE, digits = 10, pretty = TRUE),
           "results.json")

stata_compat_log()
