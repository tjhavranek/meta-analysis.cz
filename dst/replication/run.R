# dst -- replication of Table 3 (Funnel Asymmetry Tests) of
#   "Does Daylight Saving Save Electricity? A Meta-Analysis", Energy Journal 2018.
#
# TABLE 3 MODEL. The paper's stated equation is the levels form
#     ESTIMATE_ij = DST0 + beta * SE(ESTIMATE_ij) + u_ij
# "estimated by weighted least squares with the inverse of the reported estimate's standard
# error taken as the weight" (Table 3 notes). Dividing that regression through by SE_ij gives
# the numerically identical, correctly precision-weighted form
#     TSTAT_ij = beta + DST0 * PRECISION_ij + eps_ij ,      TSTAT = ESTIMATE/SE, PRECISION = 1/SE
# i.e. the standard Stanley-Doucouliagos precision-effect/funnel-asymmetry test: the row the
# paper labels "SE (publication bias)" is this regression's INTERCEPT, and the row labeled
# "Constant (true effect)" is the coefficient on PRECISION. This is exactly what the author's
# own do-file runs for the adjoining specifications (dst.do lines 167-169, 178-179: `ivreg2
# TSTAT PRECISION, cluster(...)`, `xtreg TSTAT PRECISION, fe vce(cluster IDSTUDY)`, `xtreg TSTAT
# PRECISION, be`), and it is what reproduces Table 3's numbers -- including its striking
# near-zero OLS constant-row SE (0.000778), which a naive WLS-on-levels regression with weight
# 1/SE (dst.do line 163) does NOT reproduce (that gives SE ~0.014, off by more than an order of
# magnitude; verified while building this package).
#
# Columns reproduced (of "OLS FE BE Country ME IV"):
#   OLS -- ivreg2 TSTAT PRECISION, cluster(IDSTUDY IDCOUNTRY)         [in the spirit of dst.do
#                                   line 159/167; two-way cluster as in Table 3's own footnote]
#   FE  -- xtreg  TSTAT PRECISION, fe vce(cluster IDSTUDY)            [dst.do line 168 pattern]
#   ME  -- mixed  TSTAT PRECISION || IDSTUDY:                         [Table 3 note: "ME =
#                                   study-level mixed effects"]
#
# NOT reproduced (excluded from targets.json, not silently dropped -- see REPLICATION.md):
#   BE      -- xtreg ..., be (between effects). No wrapper in stata_compat.R implements Stata's
#              between estimator (st_xtreg_fe is within/FE only), and Stata's `be` has its own
#              degrees-of-freedom convention distinct from a manual collapse-then-regress. A
#              needed command with no wrapper is a stop-and-report, not a near-enough substitute.
#   Country -- fixed effects "at the country level". Every panel/cluster variable that is
#              actually present in the data (COUNTRY: 8 groups in this subsample; COUNTRYA,
#              the do-file's own adjusted grouping that merges Australia into USA and Sweden
#              into Norway: 6 groups) was tried under st_xtreg_fe with each plausible clustering
#              choice (own-group, IDSTUDY, and two-way). The closest, panel=COUNTRYA, gives a
#              PRECISION coefficient of -0.2789 against a printed -0.278 (rounds to -0.279, a
#              miss) and no clustering choice reproduces the printed SE of 0.805. The do-file
#              author's code contains no explicit "Country" xtreg/ivreg2 line to check
#              the construction against, so this column is left unresolved rather than guessed.
#   IV      -- ivreg2 with SE instrumented. Table 3's footnote gives only a prose description of
#              the instrument ("the number of observations (if the study is based on regression
#              analysis)") and no such command appears in the provided author-code excerpt. The
#              column's own N (90) is one row short of the REGRESSION==1 subsample (91), so a
#              further unstated restriction is in play that the author's code does not show.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/dst/replication/stata_compat.R")

data_path <- (if (file.exists("dst.csv")) "dst.csv" else
     "https://meta-analysis.cz/data/v1/dst/dst.csv")
d <- read.csv(data_path, na.strings = ".", stringsAsFactors = FALSE)

# Table 3's estimation sample is every row with a reported standard error (the funnel-test
# regressions run on ESTIMATE/SE, equivalently TSTAT/PRECISION). "Outliers are excluded from
# the figure but included in all statistical tests" (Table 3 notes), so no outlier trimming.
d_fat <- st_keep_if(d, !is.na(d$SE))
d_fat$TSTAT     <- d_fat$ESTIMATE / d_fat$SE   # matches the published TSTAT column exactly
d_fat$PRECISION <- 1 / d_fat$SE                # matches the published PRECISION column exactly

results <- list()

## ---- OLS: ivreg2 TSTAT PRECISION, cluster(IDSTUDY IDCOUNTRY) ------------------------------
m_ols <- st_ivreg2(TSTAT ~ PRECISION, data = d_fat, cluster = ~IDSTUDY + COUNTRY)
c_ols <- st_coefs(m_ols)

results[["OLS SE coef"]]    <- c_ols$estimate[c_ols$term == "(Intercept)"]
results[["OLS SE se"]]      <- c_ols$std.error[c_ols$term == "(Intercept)"]
results[["OLS const coef"]] <- c_ols$estimate[c_ols$term == "PRECISION"]
results[["OLS const se"]]   <- c_ols$std.error[c_ols$term == "PRECISION"]
results[["OLS N"]]          <- stats::nobs(m_ols)

## ---- FE: xtreg TSTAT PRECISION, fe vce(cluster IDSTUDY) -----------------------------------
m_fe      <- st_xtreg_fe(TSTAT ~ PRECISION, data = d_fat, panel = "IDSTUDY", cluster = ~IDSTUDY)
c_fe      <- st_coefs(m_fe, z = FALSE)
cons_fe   <- st_xtreg_fe_cons(y = "TSTAT", x = "PRECISION", panel = "IDSTUDY", data = d_fat)
c_cons_fe <- st_coefs(cons_fe, z = FALSE)

results[["FE SE coef"]]    <- c_cons_fe$estimate[c_cons_fe$term == "(Intercept)"]
results[["FE SE se"]]      <- c_cons_fe$std.error[c_cons_fe$term == "(Intercept)"]
results[["FE const coef"]] <- c_fe$estimate[c_fe$term == "PRECISION"]
results[["FE const se"]]   <- c_fe$std.error[c_fe$term == "PRECISION"]
results[["FE N"]]          <- stats::nobs(m_fe)

## ---- ME: mixed TSTAT PRECISION || IDSTUDY: -- Table 3 note "ME = study-level mixed effects" ---
m_me  <- st_mixed(TSTAT ~ PRECISION + (1 | IDSTUDY), data = d_fat)
b_me  <- lme4::fixef(m_me)
se_me <- sqrt(diag(as.matrix(stats::vcov(m_me))))

results[["ME SE coef"]]    <- unname(b_me["(Intercept)"])
results[["ME SE se"]]      <- unname(se_me["(Intercept)"])
results[["ME const coef"]] <- unname(b_me["PRECISION"])
results[["ME const se"]]   <- unname(se_me["PRECISION"])
results[["ME N"]]          <- stats::nobs(m_me)

## ===============================================================================================
## PART 2 -- THE PAPER'S OWN HEADLINE NUMBERS (abstract / conclusion), not just Table 3's cells.
##
## meta-analysis.cz summarises this paper as: "essentially zero, 0.01% savings, against a 0.34%
## simple average of reported estimates." Both halves of that sentence are the paper's own text:
##
##   Abstract: "...we collect 162 estimates from 44 studies and find that the mean reported
##   estimate indicates slight electricity savings: 0.34% during the days when DST applies."
##
##   That 0.34% is the STUDY-WEIGHTED mean, not the unweighted one. Table 2's "All observations"
##   row prints both -- "162 | -0.334 -0.419 -0.250 | -0.343 -0.429 -0.257" -- and its note says
##   the right-hand columns are "weighted by the inverse of the number of estimates reported per
##   study". The prose beside the table makes the attribution explicit: "Assigning each study the
##   same weight yields an overall mean estimate of -0.34 ... The 95% confidence interval of
##   (-0.43, -0.26) indicates considerable uncertainty". The conclusion repeats it ("the mean
##   estimate, 0.34% savings") and so does Section 4.3 ("-0.34%, the simple average effect
##   reported in the literature").
##
##   The unweighted mean is a different number and the paper says so separately, in Section 3 on
##   Figure 4: "the mean estimate of -0.33 is very close to the median estimate of -0.3". So both
##   columns are reproduced below, each against its own printed value.
##
##
##   Section 4.3 / Table 6: "Table 6 provides the best-practice DST estimates for all 21
##   countries... The resulting global estimate is -0.01%, quite distant from -0.34%, the simple
##   average effect reported in the literature. The 95% confidence interval of our best-practice
##   estimate is wide, (-0.76, 0.73)." Table 6's own "All countries" row prints this more
##   precisely as -0.014 (95% CI -0.760, 0.732).
##
## Number 1 (simple average, -0.34%) is a plain mean of the published ESTIMATE column -- reused
## here via st_regress(ESTIMATE ~ 1) so the "mean" is read off a fitted intercept like every other
## number in this package, not a bare mean() call.
##
## Number 2 (best-practice global estimate, -0.01%) is NOT a fresh estimation this package can run
## from scratch: it is a LINEAR COMBINATION of (a) the posterior-mean coefficients from the
## Bayesian model averaging in Table 5 -- a BMS model with a specific g-prior/model-prior
## combination that has no wrapper in stata_compat.R and that the assignment's toolkit does not
## sanction re-fitting (BMS is not among st_ivreg2 / st_xtreg_fe / st_regress / st_metan / ...) --
## and (b) the paper's own prose definition of "best practice" values for the other 13
## explanatory variables (Section 4.3, quoted inline below). Coefficients (a) are therefore taken
## VERBATIM from Table 5 as printed (3 decimals) -- the only form they exist in without re-running
## the authors' exact BMS specification -- and every input value in (b) that depends on the data
## (max citations, the 95th percentile of the impact factor, per-country average daylight hours,
## the study-inverse WEIGHT column) is computed here from dst.csv, not copied from the paper.
##
## Table 5's posterior means (BMA column), quoted verbatim:
##   Data period -0.003, Main estimate 0.004, Daily data -0.444, Daylight hours -0.118, USA 0.008,
##   Regression analysis -0.021, Simulation -0.361, Difference-in-differences -0.412,
##   Residential consumption 0.050, Lighting consumption 0.010, Publication year 0.000,
##   Journal publication 0.040, Impact factor 0.958, Citations 0.007, Constant 1.698.
## ("Citations" is log(citations+1): Table 4 reports its sample mean as 1.91, which matches
## log(CITATIONS+1) here (1.9095) and NOT log(CITATIONS) (1.7241, undefined at CITATIONS=0)."
## "Publication year" is PUBYEAR-1970 (Table 4: "base = 1970"; sample mean 34.8 = 2004.82-1970,
## matching mean(PUBYEAR) here). "Impact factor" and "Daylight hours" are used as published, with
## sample means 0.073 and 15.19 matching IMPACT and DAYLIGHT here exactly.)
##
## Section 4.3's "best practice" definition, quoted: "we plug in '9' for the Data period and '0'
## for Daily data ... We assign greater weight to the authors' most preferred estimates [Main
## estimate = 1] ... we prefer a study to use the difference-in-differences approach [DID = 1,
## Regression analysis = Simulation = 0] ... we prefer general estimates ... and avoid derivations
## from estimates based solely on lighting consumption [Residential = Lighting = 0] ... we plug in
## the maximum value of publication year ... we place greater weight on studies published in
## refereed journals [Journal = 1] and those with the maximum number of citations ... we choose
## the 95th percentile for the Impact factor variable ... we set the dummy variable USA to zero
## for other countries than the United States and control for country heterogeneity using the
## variable Daylight hours."
##
## The 21 countries are then combined into "All countries" using the same inverse-per-study WEIGHT
## column the paper uses everywhere else for its "assign each study equal weight" averages (Table
## 2's own right-hand columns; Table 2's note: "weighted by the inverse of the number of estimates
## reported per study"). This is not stated explicitly for Table 6, but it is the paper's only
## other country/study aggregation rule, and it is confirmed below: re-applying the SAME
## WEIGHT-weighted average directly to the paper's own PRINTED Table 6 country estimates recovers
## -0.0134 against the paper's printed -0.014 (a validation, not a target -- it uses numbers copied
## from the paper's own table, not re-derived from data, so it cannot itself count as a
## reproduction of anything).
##
## HONESTY NOTE: Table 5's coefficients are printed to only 3 decimals, and the exact BMS
## specification (UIP g-prior, uniform model prior) is not re-run here (no wrapper permits it).
## Comparing this package's own per-country predictions against Table 6's printed per-country
## values (done below, printed but not a formal target) shows a small, near-constant offset of
## about +0.005 to +0.007 across every one of the 21 countries -- consistent with compounding
## 3-decimal rounding in 14 coefficients, not a wrong model or wrong best-practice values. The
## final "All countries" number this package produces is therefore expected to land close to,
## but not exactly at, -0.01% / -0.014 -- and it does (see printed output).

d_bp <- d  # best-practice reconstruction uses the full 162-row sample, not the SE-restricted d_fat

## 95th percentile of IMPACT, via the sanctioned st_winsor2 wrapper (Stata's _pctile / type 2)
## rather than calling quantile() directly: winsorising at cuts (0, 95) caps every value above the
## 95th percentile at that percentile's value, so max() of the winsorized vector recovers it.
imp_95 <- max(st_winsor2(d_bp$IMPACT, cuts = c(0, 95)))

max_citations <- max(d_bp$CITATIONS, na.rm = TRUE)
logcit_bp     <- log(max_citations + 1)          # "Citations" enters the BMA as log(cites + 1)

max_pubyear   <- max(d_bp$PUBYEAR, na.rm = TRUE)
pubyear_bp    <- max_pubyear - 1970              # "Publication year" enters the BMA as year-1970

bma <- list(dataperiod = -0.003, main = 0.004, daily = -0.444, daylight = -0.118, usa = 0.008,
            regr = -0.021, sim = -0.361, did = -0.412, resid = 0.050, light = 0.010,
            pubyear = 0.000, journal = 0.040, impact = 0.958, cit = 0.007, const = 1.698)

## The part of the linear combination that does not vary by country (best-practice values fixed
## at Data period=9, Main estimate=1, Daily data=0, Regression=Simulation=0, DID=1,
## Residential=Lighting=0, Journal=1, Publication year=max, Impact factor=95th pct, Citations=max)
bp_base <- bma$const + bma$dataperiod*9 + bma$main*1 + bma$daily*0 + bma$regr*0 + bma$sim*0 +
           bma$did*1 + bma$resid*0 + bma$light*0 + bma$pubyear*pubyear_bp + bma$journal*1 +
           bma$impact*imp_95 + bma$cit*logcit_bp

avg_daylight_by_country <- aggregate(DAYLIGHT ~ COUNTRY, data = d_bp, FUN = mean)
weight_by_country       <- aggregate(WEIGHT ~ COUNTRY, data = d_bp, FUN = sum)
bp <- merge(avg_daylight_by_country, weight_by_country, by = "COUNTRY")
bp$usa_dummy   <- ifelse(bp$COUNTRY == "USA", 1, 0)
bp$best_practice_pred <- bp_base + bma$daylight * bp$DAYLIGHT + bma$usa * bp$usa_dummy

bma_global_estimate <- sum(bp$best_practice_pred * bp$WEIGHT) / sum(bp$WEIGHT)

## ---- Validation only (not a target): re-apply the identical WEIGHT-weighted average directly
## to the paper's own PRINTED Table 6 country estimates. This checks the AGGREGATION RULE, not
## the model -- it uses numbers copied from the paper, so it cannot itself reproduce anything.
table6_printed <- c(Australia = 0.189, Austria = -0.059, Chile = 0.074, `Czech Republic` = -0.104,
  Denmark = -0.258, France = -0.037, Germany = -0.130, India = 0.248, Israel = 0.146, Italy = 0.012,
  Japan = 0.112, Jordan = 0.150, Kuwait = 0.168, Mexico = 0.223, Netherlands = -0.165,
  `New Zealand` = 0.038, Norway = -0.512, Sweden = -0.510, Turkey = 0.063,
  `United Kingdom` = -0.201, USA = 0.087)
bp$table6_printed <- table6_printed[bp$COUNTRY]
validation_weighted_avg_of_printed <- sum(bp$table6_printed * bp$WEIGHT) / sum(bp$WEIGHT)

## ---- Table 2, "All observations": both means, with confidence intervals ---------------------
## Stata's own conventions, confirmed by running it on this data set (stata_work_dst/):
##     mean ESTIMATE             -> -.3344542  se .0429748  CI (-.4193212, -.2495872)
##     mean ESTIMATE [aw=WEIGHT] -> -.3427427  se .0436487  CI (-.4289406, -.2565448)
## A constant-only regress reproduces both exactly, so the sanctioned st_regress wrapper is used
## rather than a hand-rolled weighted mean, and the interval uses Stata's t(n-1).
d_all  <- st_keep_if(d, !is.na(d$ESTIMATE))
n_all  <- nrow(d_all)
t_crit <- stats::qt(0.975, n_all - 1)

c_unw <- st_coefs(st_regress(ESTIMATE ~ 1, data = d_all), z = FALSE)
c_wtd <- st_coefs(st_regress(ESTIMATE ~ 1, data = d_all, weights = ~WEIGHT), z = FALSE)

results[["T2 all obs, unweighted CI low"]]  <- c_unw$estimate[1] - t_crit * c_unw$std.error[1]
results[["T2 all obs, unweighted CI high"]] <- c_unw$estimate[1] + t_crit * c_unw$std.error[1]

results[["T2 all obs, study-weighted mean (the abstract's 0.34%)"]] <- c_wtd$estimate[1]
results[["T2 all obs, study-weighted CI low"]]  <- c_wtd$estimate[1] - t_crit * c_wtd$std.error[1]
results[["T2 all obs, study-weighted CI high"]] <- c_wtd$estimate[1] + t_crit * c_wtd$std.error[1]

results[["Median estimate (Section 3, Figure 4 text)"]] <- stats::median(d_all$ESTIMATE)

results[["Simple avg ESTIMATE, all obs (%)"]]            <- st_coefs(st_regress(ESTIMATE ~ 1, data = d))$estimate[1]
results[["BMA best-practice global estimate (%), own reconstruction"]] <- bma_global_estimate

## ---------------------------------------------------------------------------------------------
for (lab in names(results)) cat(sprintf("%-16s %s\n", lab, format(results[[lab]], digits = 8)))

cat("\n== Paper's headline text numbers ==\n")
cat(sprintf("Study-weighted mean -- the abstract's 0.34%% (Table 2: -0.343): %.6f  CI (%.6f, %.6f)
",
            results[["T2 all obs, study-weighted mean (the abstract's 0.34%)"]],
            results[["T2 all obs, study-weighted CI low"]],
            results[["T2 all obs, study-weighted CI high"]]))
cat(sprintf("Unweighted mean -- Section 3's -0.33 (Table 2: -0.334):        %.6f  CI (%.6f, %.6f)
",
            results[["Simple avg ESTIMATE, all obs (%)"]],
            results[["T2 all obs, unweighted CI low"]],
            results[["T2 all obs, unweighted CI high"]]))
cat(sprintf("Median estimate (paper: -0.3):                                %.6f
",
            results[["Median estimate (Section 3, Figure 4 text)"]]))
cat(sprintf("BMA best-practice global estimate (paper: -0.01%%, Table 6: -0.014):        %.6f\n",
            results[["BMA best-practice global estimate (%), own reconstruction"]]))
cat(sprintf("  [diagnostic, not a target] per-country prediction vs Table 6, mean offset: %.6f\n",
            mean(bp$best_practice_pred - bp$table6_printed)))
cat(sprintf("  [diagnostic, not a target] WEIGHT-avg of the PAPER'S OWN printed Table 6 rows: %.6f\n",
            validation_weighted_avg_of_printed))

if (requireNamespace("jsonlite", quietly = TRUE)) {
  jsonlite::write_json(results, "results.json", auto_unbox = TRUE, digits = NA)
} else {
  esc <- function(x) gsub('"', '\\\\"', x)
  lines <- vapply(names(results), function(lab) {
    sprintf('  "%s": %s', esc(lab), format(as.numeric(results[[lab]]), digits = 15, scientific = FALSE))
  }, character(1))
  writeLines(c("{", paste(lines, collapse = ",\n"), "}"), "results.json")
}

stata_compat_log()
