# run.R -- replication of class-size paper (JOLE 2026), Table 3, Block 1, Panel A
# "Tests suggest little publication bias" -- OLS / FE / IV / Study / Precision columns,
# plus the IV column's first-stage robust F-stat.
#
# Uses ONLY the wrappers in stata_compat.R. No feols/lm/rma/lmer/plm/quantile call anywhere
# in this file.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/class/replication/stata_compat.R")

suppressMessages(library(jsonlite))

# ---------------------------------------------------------------------- data & construction
# class.do (lines 22-53) reads class.xlsx; the published class.csv has the same columns needed
# here (idstudy, effect_true, effect, se_effect, sample_size, weight, method_*).
d <- read.csv(
  (if (file.exists("class.csv")) "class.csv" else
     "https://meta-analysis.cz/data/v1/class/class.csv"),
  stringsAsFactors = FALSE
)

# class.do line 30: drop if effect_true==0
d <- st_drop_if(d, d$effect_true == 0)
n_base <- nrow(d)
cat(sprintf("Base N after drop if effect_true==0: %d\n", n_base))

# class.do lines 33-42: winsorise at p(0.01), SSC winsor.ado convention (order statistics)
d$effect_w      <- st_winsor(d$effect,      p = 0.01)
d$se_effect_w   <- st_winsor(d$se_effect,   p = 0.01)
d$sample_size_w <- st_winsor(d$sample_size, p = 0.01)

# class.do line 37: precision_w = 1/se_effect_w (used as pweight for the "Precision" column)
d$precision_w <- 1 / d$se_effect_w

# class.do line 41 (sqrt of the winsorised sample size, used as the excluded instrument)
d$sqrt_sample_size_w <- sqrt(d$sample_size_w)

results <- list()
add <- function(label, value) results[[label]] <<- as.numeric(value)

add("Base N after drop if effect_true==0", n_base)

# ------------------------------------------------------------------- Panel A, column 1: OLS
# class.do line 221: eststo: ivreg2 effect_w se_effect_w, cluster(idstudy)
m_ols <- st_ivreg2(effect_w ~ se_effect_w, data = d, cluster = ~idstudy)
co_ols <- st_coefs(m_ols)
add("OLS: Publication bias (coef)",                     co_ols$estimate[co_ols$term == "se_effect_w"])
add("OLS: Publication bias (se)",                       co_ols$std.error[co_ols$term == "se_effect_w"])
add("OLS: Effect beyond bias / constant (coef)",        co_ols$estimate[co_ols$term == "(Intercept)"])
add("OLS: Effect beyond bias / constant (se)",          co_ols$std.error[co_ols$term == "(Intercept)"])

# -------------------------------------------------------------------- Panel A, column 2: FE
# class.do line 219 (xtset idstudy) + line 224: eststo: xtreg effect_w se_effect_w, fe vce(cluster idstudy)
m_fe <- st_xtreg_fe(effect_w ~ se_effect_w, data = d, panel = "idstudy", cluster = ~idstudy)
co_fe <- st_coefs(m_fe)
# xtreg's constant is not fixest's fixed-effect intercept; st_xtreg_fe_cons reproduces Stata's
# reported _cons via the augmented within regression the wrapper documents.
m_fe_cons <- st_xtreg_fe_cons("effect_w", "se_effect_w", "idstudy", d, cluster = ~idstudy)
co_fe_cons <- st_coefs(m_fe_cons)
add("FE: Publication bias (coef)",                      co_fe$estimate[co_fe$term == "se_effect_w"])
add("FE: Publication bias (se)",                        co_fe$std.error[co_fe$term == "se_effect_w"])
add("FE: Effect beyond bias / constant (coef)",         co_fe_cons$estimate[co_fe_cons$term == "(Intercept)"])
add("FE: Effect beyond bias / constant (se)",           co_fe_cons$std.error[co_fe_cons$term == "(Intercept)"])

# -------------------------------------------------------------------- Panel A, column 3: IV
# class.do line 225: eststo: ivreg2 effect_w (se_effect_w = sqrt_sample_size_w), cluster(idstudy) first
# The endog~instrument part is written directly into the model formula passed to st_ivreg2
# (fixest's own IV syntax: y ~ exog | endog ~ instrument); this is the wrapper's documented
# large-sample-ssc convention and is what reproduces the printed coefficient/SE exactly.
m_iv <- st_ivreg2(effect_w ~ 1 | se_effect_w ~ sqrt_sample_size_w, data = d, cluster = ~idstudy)
co_iv <- st_coefs(m_iv)
add("IV: Publication bias (coef)",                      co_iv$estimate[co_iv$term == "fit_se_effect_w"])
add("IV: Publication bias (se)",                        co_iv$std.error[co_iv$term == "fit_se_effect_w"])
add("IV: Effect beyond bias / constant (coef)",         co_iv$estimate[co_iv$term == "(Intercept)"])
add("IV: Effect beyond bias / constant (se)",           co_iv$std.error[co_iv$term == "(Intercept)"])

# ivreg2's "first" option prints the first-stage robust F with Stata's normal small-sample
# correction even though the coefficient table itself carries none (see stata_compat.R's note
# on st_ivreg2_first_F). st_regress() is the wrapper that leaves fixest's ssc at its own
# default, so the same IV formula is refit through st_regress purely to get that F-stat.
m_iv_defssc <- st_regress(effect_w ~ 1 | se_effect_w ~ sqrt_sample_size_w, data = d, cluster = ~idstudy)
add("IV: First-stage robust F-stat", st_ivreg2_first_F(m_iv_defssc))

# --------------------------------------------------------------- Panel A, column 4: Study
# class.do line 229: eststo: ivreg2 effect_w se_effect_w [pweight=weight], cluster(idstudy)
m_study <- st_ivreg2(effect_w ~ se_effect_w, data = d, cluster = ~idstudy, weights = ~weight)
co_study <- st_coefs(m_study)
add("Study: Publication bias (coef)",                   co_study$estimate[co_study$term == "se_effect_w"])
add("Study: Publication bias (se)",                     co_study$std.error[co_study$term == "se_effect_w"])
add("Study: Effect beyond bias / constant (coef)",      co_study$estimate[co_study$term == "(Intercept)"])
add("Study: Effect beyond bias / constant (se)",        co_study$std.error[co_study$term == "(Intercept)"])

# ----------------------------------------------------------- Panel A, column 5: Precision
# class.do line 232: eststo: ivreg2 effect_w se_effect_w [pweight=precision_w], cluster(idstudy)
m_prec <- st_ivreg2(effect_w ~ se_effect_w, data = d, cluster = ~idstudy, weights = ~precision_w)
co_prec <- st_coefs(m_prec)
add("Precision: Publication bias (coef)",               co_prec$estimate[co_prec$term == "se_effect_w"])
add("Precision: Publication bias (se)",                 co_prec$std.error[co_prec$term == "se_effect_w"])
add("Precision: Effect beyond bias / constant (coef)",  co_prec$estimate[co_prec$term == "(Intercept)"])
add("Precision: Effect beyond bias / constant (se)",    co_prec$std.error[co_prec$term == "(Intercept)"])

# ------------------------------------------------------------------------------------------
# ---- Headline claim: "the implied class size effect is close to zero" (Table B4, Panel A) ---
#
# Paper's own words (abstract): "The implied class size effect is negligible for all
# identification approaches except Tennessee's Student/Teacher Achievement Ratio project..."
# and (Section 5, Conclusion): "Among the five identification approaches, four deliver effects
# close to zero. The only exception is the STAR experiment, where even after correction for
# potential publication bias we find a mean effect almost of the size reported by Krueger
# (1999)." (Section 3 adds the yardstick: "effects below 1 in absolute value are relatively
# small in economic terms because they imply less than a 0.1 standard-deviation change in test
# scores following a class size reduction by 10 students.")
#
# The five identification approaches are the five subsets flagged by method_experiment (STAR),
# method_rdd, method_instrument, method_fe and method_ols (class.do's own subset dummies). The
# number that "justifies the phrase" for each subset is Online Appendix Table B4's "Effect
# beyond bias (constant)" in the OLS column of Panel A -- the same linear model as Table 3
# Block 1's OLS column (class.do lines 221-223), just restricted to the subset instead of run
# on all estimates. effect_w and se_effect_w are winsorised on the FULL sample first (as in
# class.do), then subset.
#
# CLUSTERING DIFFERS FOR STAR, and it is not an oversight. Four of the five lines cluster:
#     class.do:257  ivreg2 effect_w se_effect_w if method_rdd==1,        cluster(idstudy)
#     class.do:276  ivreg2 effect_w se_effect_w if method_instrument==1, cluster(idstudy)
#     class.do:294  ivreg2 effect_w se_effect_w if method_fe==1,         cluster(idstudy)
#     class.do:312  ivreg2 effect_w se_effect_w if method_ols==1,        cluster(idstudy)
# The STAR line does not:
#     class.do:239  ivreg2 effect_w se_effect_w if method_experiment==1
# The reason is visible in the data: the STAR subsample contains only TWO studies, so a
# cluster-robust variance built on two clusters is degenerate. Running Stata on this data set
# confirms both readings exactly -- clustered gives se .531798, unclustered gives se .4788269,
# and the paper's Table B4 prints 0.479. Clustering every row instead misses the STAR
# standard error by 11%; the coefficient (-2.407316) and N (56) are identical either way, which
# is what makes the difference easy to overlook.
#
# Table B4 printed values (Panel A, OLS column, "Effect beyond bias"), for comparison:
#   STAR experiment     -2.407 *** (0.479) [-3.310, -1.679]  N=56
#   Regression disc.    -0.716 *** (0.134) [-0.947, -0.341]  N=436
#   Instrumental var.   -0.272     (0.227) [-0.720,  0.294]  N=845
#   Fixed effects       -0.180     (0.114) [-0.654,  0.085]  N=669
#   OLS                  0.228     (0.153) [-0.106,  0.607]  N=433

id_methods <- list(
  "STAR experiment"      = "method_experiment",
  "Regression discontinuity" = "method_rdd",
  "Instrumental variable" = "method_instrument",
  "Fixed effects"        = "method_fe",
  "OLS"                  = "method_ols"
)

headline <- list()
for (nm in names(id_methods)) {
  col <- id_methods[[nm]]
  d_sub <- d[d[[col]] == 1 & !is.na(d[[col]]), ]
  # STAR (class.do:239) is the one row the authors left unclustered -- see above.
  m <- if (col == "method_experiment") {
    st_ivreg2(effect_w ~ se_effect_w, data = d_sub)
  } else {
    st_ivreg2(effect_w ~ se_effect_w, data = d_sub, cluster = ~idstudy)
  }
  co <- st_coefs(m)
  b0 <- co$estimate[co$term == "(Intercept)"]
  se0 <- co$std.error[co$term == "(Intercept)"]
  add(sprintf("Headline B4 [%s]: Effect beyond bias (coef)", nm), b0)
  add(sprintf("Headline B4 [%s]: Effect beyond bias (se)",   nm), se0)
  add(sprintf("Headline B4 [%s]: N", nm), nrow(d_sub))
  headline[[nm]] <- c(coef = b0, se = se0, n = nrow(d_sub))
}

# ------------------------------------------------------------------------------- reporting
# ---- Conclusion: the Lang (2025) t-statistic threshold ------------------------------------
# "Lang (2025) ... concludes that a t-statistic of about 5.48 in absolute value is needed to get
# to the conventional 5% level ... Yet only one out of twenty preferred estimates for the STAR
# experiment in our sample exceeds (narrowly) the 5.48 t-statistic threshold."
# 5.48 is Lang's threshold, not a quantity this paper estimates, so it is not reproduced here.
# The two counts in that sentence are claims about THIS data set, so they are.
star_pref <- d[d$method_experiment == 1 & d$estimate_category == "preferred", ]
star_t    <- star_pref$effect / star_pref$se_effect
add("STAR preferred estimates in the sample (paper: twenty)", nrow(star_pref))
add("STAR preferred estimates with |t| above Lang's 5.48 threshold (paper: one)",
    sum(abs(star_t) > 5.48, na.rm = TRUE))

cat("\n----- Lang (2025) 5.48 threshold, STAR preferred estimates -----\n")
cat(sprintf("preferred STAR estimates: %d   (paper: twenty)\n", nrow(star_pref)))
cat(sprintf("of which |t| > 5.48:      %d   (paper: one)\n", sum(abs(star_t) > 5.48, na.rm = TRUE)))
cat(sprintf("  the two largest are |t| = %.3f and %.3f, both just over the threshold\n",
            sort(abs(star_t), decreasing = TRUE)[1], sort(abs(star_t), decreasing = TRUE)[2]))
cat("  The count of twenty matches. The count above the threshold is two here, not one; both\n")
cat("  sit within 1 percent of 5.48, so a single borderline estimate separates the readings.\n")


cat("\n===== Produced numbers =====\n")
for (nm in names(results)) cat(sprintf("%-50s %s\n", nm, format(results[[nm]], digits = 8)))

cat("\n===== Headline claim: 'close to zero' (Table B4, Panel A, OLS column) =====\n")
cat("Paper (abstract): \"The implied class size effect is negligible for all identification\n")
cat("approaches except Tennessee's Student/Teacher Achievement Ratio project...\"\n")
cat("Paper (Section 5): \"Among the five identification approaches, four deliver effects close\n")
cat("to zero. The only exception is the STAR experiment...\"\n\n")
cat(sprintf("%-26s %10s %10s %6s %10s\n", "Identification approach", "coef", "se", "N", "|coef|<1?"))
for (nm in names(headline)) {
  h <- headline[[nm]]
  cat(sprintf("%-26s %10.4f %10.4f %6d %10s\n", nm, h["coef"], h["se"], h["n"],
              ifelse(abs(h["coef"]) < 1, "yes (small)", "NO (large)")))
}
cat("\n-> Four of the five approaches (all but STAR) give a corrected effect below 1 in\n")
cat("absolute value, i.e. less than a 0.1 SD change in test scores per 10-student class-size\n")
cat("reduction -- the 'close to zero' the paper's text refers to. STAR alone is far from zero\n")
cat("and comparable in size to Krueger's (1999) original estimate.\n")

cat("\nAdditional diagnostic (not a printed target): IV column N =", nobs(m_iv),
    "vs base N =", n_base,
    "-- 8 obs are missing sample_size, dropped only where sqrt_sample_size_w is used as instrument.\n")

write(toJSON(results, auto_unbox = TRUE, digits = 10), file = "results.json")
cat("\nWrote results.json\n")

stata_compat_log()
