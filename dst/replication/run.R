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
#              actually evidenced in the brief (COUNTRY: 8 groups in this subsample; COUNTRYA,
#              the do-file's own adjusted grouping that merges Australia into USA and Sweden
#              into Norway: 6 groups) was tried under st_xtreg_fe with each plausible clustering
#              choice (own-group, IDSTUDY, and two-way). The closest, panel=COUNTRYA, gives a
#              PRECISION coefficient of -0.2789 against a printed -0.278 (rounds to -0.279, a
#              miss) and no clustering choice reproduces the printed SE of 0.805. The do-file
#              excerpt in the brief contains no explicit "Country" xtreg/ivreg2 line to check
#              the construction against, so this column is left unresolved rather than guessed.
#   IV      -- ivreg2 with SE instrumented. Table 3's footnote gives only a prose description of
#              the instrument ("the number of observations (if the study is based on regression
#              analysis)") and no such command appears in the provided author-code excerpt. The
#              column's own N (90) is one row short of the REGRESSION==1 subsample (91), so a
#              further unstated restriction is in play that the brief does not evidence.

source("stata_compat.R")

data_path <- "C:/Users/thavr/Dropbox/Study/Other/Agents/Joint/web_meta/site/data/v1/dst/dst.csv"
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

## ---------------------------------------------------------------------------------------------
for (lab in names(results)) cat(sprintf("%-16s %s\n", lab, format(results[[lab]], digits = 8)))

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
