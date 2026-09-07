# run.R -- replication of class-size paper (JOLE 2026), Table 3, Block 1, Panel A
# "Tests suggest little publication bias" -- OLS / FE / IV / Study / Precision columns,
# plus the IV column's first-stage robust F-stat.
#
# Uses ONLY the wrappers in stata_compat.R. No feols/lm/rma/lmer/plm/quantile call anywhere
# in this file.

source("stata_compat.R")

suppressMessages(library(jsonlite))

# ---------------------------------------------------------------------- data & construction
# class.do (lines 22-53) reads class.xlsx; the published class.csv has the same columns needed
# here (idstudy, effect_true, effect, se_effect, sample_size, weight, method_*).
d <- read.csv(
  "C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\class\\class.csv",
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

# ------------------------------------------------------------------------------- reporting
cat("\n===== Produced numbers =====\n")
for (nm in names(results)) cat(sprintf("%-50s %s\n", nm, format(results[[nm]], digits = 8)))

cat("\nAdditional diagnostic (not a printed target): IV column N =", nobs(m_iv),
    "vs base N =", n_base,
    "-- 8 obs are missing sample_size, dropped only where sqrt_sample_size_w is used as instrument.\n")

write(toJSON(results, auto_unbox = TRUE, digits = 10), file = "results.json")
cat("\nWrote results.json\n")

stata_compat_log()
