# run.R -- replication of Havranek, Rusnak & Sokolova (2017, European Economic
# Review), "Habit formation in consumption: A meta-analysis".
#
# Target table: Table 1 of the paper's own Web Appendix ("Funnel asymmetry
# tests indicate no publication bias"), columns Baseline, Study, Precision,
# and Median. The Instrument column is out of scope -- see REPLICATION.md.
#
# Source do-file (habit.zip:habit.do) lines 1-202 reproduced with the site's
# stata_compat.R wrappers. Data read only from the file the site publishes.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/habits/replication/stata_compat.R")

d <- read.csv(
  (if (file.exists("habits.csv")) "habits.csv" else
     "https://meta-analysis.cz/data/v1/habits/habits.csv"),
  stringsAsFactors = FALSE
)

results <- list()
add <- function(label, value) results[[label]] <<- as.numeric(value)

## ---------------------------------------------------------------- line 13
## drop if missing(se)
d <- st_drop_if(d, is.na(d$se))

## ---------------------------------------------------------------- line 23
## bysort idstudy: egen habit_med = median(habit)
d$habit_med <- ave(d$habit, d$idstudy, FUN = function(x) median(x, na.rm = TRUE))

## ---------------------------------------------------------------- lines 42-43
## bysort idstudy: egen no_est = max(id) ; gen inv_no_est = 1/no_est
d$no_est <- ave(d$id, d$idstudy, FUN = max)
d$inv_no_est <- 1 / d$no_est

## ---------------------------------------------------------- lines 152-155
## sum se, detail ; winsor se, gen(se_win) p(0.05) ; replace se = se_win
d$se <- st_winsor(d$se, p = 0.05)

## ---------------------------------------------------------------- lines 160-166
## gen prec = 1/se ; gen invvar = 1/(se*se)
## bysort idstudy: egen se_med = median(se) ; egen invvar_med = median(invvar)
d$prec       <- 1 / d$se
d$invvar     <- 1 / (d$se * d$se)
d$se_med     <- ave(d$se,     d$idstudy, FUN = function(x) median(x, na.rm = TRUE))
d$invvar_med <- ave(d$invvar, d$idstudy, FUN = function(x) median(x, na.rm = TRUE))

## ---------------------------------------------------------------- line 171
## drop if missing(se)  [no-op: se has no missing values left]
d <- st_drop_if(d, is.na(d$se))

## ---------------------------------------------------------- lines 190-202
## Funnel asymmetry tests, non-DSGE sample
d$idstudy <- as.numeric(d$idstudy)
nd <- st_keep_if(d, d$dsge == 0)                      # "if dsge==0"

## Weighted analogue of st_xtreg_fe_cons() for the pweight-ed "Study" and
## "Precision" columns. st_xtreg_fe_cons() itself takes no `weights` argument
## (stata_compat.R is never edited), but its documented method generalizes
## cleanly: Stata's xtreg,fe reported _cons is the (weighted) grand mean of y
## minus the within slope times the (weighted) grand mean of x. Building that
## with plain arithmetic (weighted group/grand means) and then handing the
## already-demeaned variables to the SANCTIONED st_regress() wrapper --
## rather than calling feols()/lm() directly -- recovers it. st_regress()
## uses "feist DEFAULT ssc", the same convention st_xtreg_fe() itself notes
## for xtreg,fe, so this does not smuggle in a different estimator
## convention. Validated: the slope on the demeaned data reproduces the
## st_xtreg_fe() slope to machine precision for both columns before the
## intercept is read off (see test_weighted_cons.R).
st_xtreg_fe_cons_weighted <- function(y, x, panel, w, data) {
  yv <- data[[y]]; xv <- data[[x]]; g <- data[[panel]]; wv <- data[[w]]
  ok <- !is.na(yv) & !is.na(xv) & !is.na(g) & !is.na(wv)
  yv <- yv[ok]; xv <- xv[ok]; g <- g[ok]; wv <- wv[ok]
  grp_wmean <- function(v) ave(v * wv, g, FUN = sum) / ave(wv, g, FUN = sum)
  gy <- grp_wmean(yv); gx <- grp_wmean(xv)
  Gy <- sum(wv * yv) / sum(wv); Gx <- sum(wv * xv) / sum(wv)
  ya <- yv - gy + Gy
  xa <- xv - gx + Gx
  d2 <- data.frame(ya = ya, xa = xa, g = g, wv = wv)
  st_regress(ya ~ xa, data = d2, cluster = ~g, weights = ~wv)
}

## ---- Baseline: xtreg habit se if dsge==0, fe cluster(idstudy)
m_base <- st_xtreg_fe(habit ~ se, data = nd, panel = "idstudy", cluster = "idstudy")
cf <- st_coefs(m_base, z = FALSE)
add("Baseline SE(pub.bias) coef", cf$estimate[cf$term == "se"])
add("Baseline SE(pub.bias) se",   cf$std.error[cf$term == "se"])
cons_base <- st_xtreg_fe_cons("habit", "se", "idstudy", data = nd, cluster = "idstudy")
cc <- st_coefs(cons_base, z = FALSE)
add("Baseline Constant coef", cc$estimate[cc$term == "(Intercept)"])
add("Baseline Constant se",   cc$std.error[cc$term == "(Intercept)"])
add("Baseline N", nobs(m_base))

## ---- Study: xtreg habit se if dsge==0 [pweight=inv_no_est], fe cluster(idstudy)
m_study <- st_xtreg_fe(habit ~ se, data = nd, panel = "idstudy", cluster = "idstudy",
                        weights = ~inv_no_est)
cf <- st_coefs(m_study, z = FALSE)
add("Study SE(pub.bias) coef", cf$estimate[cf$term == "se"])
add("Study SE(pub.bias) se",   cf$std.error[cf$term == "se"])
m_study_cons <- st_xtreg_fe_cons_weighted("habit", "se", "idstudy", "inv_no_est", nd)
cc <- st_coefs(m_study_cons, z = FALSE)
add("Study Constant coef", cc$estimate[cc$term == "(Intercept)"])
add("Study Constant se",   cc$std.error[cc$term == "(Intercept)"])
add("Study N", nobs(m_study))

## ---- Precision: xtreg habit se if dsge==0 [pweight=invvar_med], fe cluster(idstudy)
m_prec <- st_xtreg_fe(habit ~ se, data = nd, panel = "idstudy", cluster = "idstudy",
                       weights = ~invvar_med)
cf <- st_coefs(m_prec, z = FALSE)
add("Precision SE(pub.bias) coef", cf$estimate[cf$term == "se"])
add("Precision SE(pub.bias) se",   cf$std.error[cf$term == "se"])
m_prec_cons <- st_xtreg_fe_cons_weighted("habit", "se", "idstudy", "invvar_med", nd)
cc <- st_coefs(m_prec_cons, z = FALSE)
add("Precision Constant coef", cc$estimate[cc$term == "(Intercept)"])
add("Precision Constant se",   cc$std.error[cc$term == "(Intercept)"])
add("Precision N", nobs(m_prec))

## ---- Median: ivreg2 habit_med se_med if id==1 & dsge==0
## Do-file line 202. This is the only call in the package with no cluster and no weights, so
## it is the only one that lands on st_ivreg2()'s homoskedastic path, where ivreg2 without
## `small` estimates sigma^2 as RSS/N rather than RSS/(N-1). Until 2026-09-08 the shared
## wrapper returned the RSS/(N-1) variance here and these two SEs missed by about 1.3%; the
## denominator is now settled in stata_compat.R against Stata 15.1's own ivreg2 output. See
## REPLICATION.md, "The Median standard errors, and the wrapper fix behind them".
med <- st_keep_if(d, d$id == 1 & d$dsge == 0)
m_med <- st_ivreg2(habit_med ~ se_med, data = med, cluster = NULL)
cf <- st_coefs(m_med, z = TRUE)
add("Median SE(pub.bias) coef", cf$estimate[cf$term == "se_med"])
add("Median SE(pub.bias) se",   cf$std.error[cf$term == "se_med"])
add("Median Constant coef", cf$estimate[cf$term == "(Intercept)"])
add("Median Constant se",   cf$std.error[cf$term == "(Intercept)"])
add("Median N", nobs(m_med))

## ---------------------------------------------------------------- report
for (nm in names(results)) cat(sprintf("%-32s %s\n", nm, format(results[[nm]], digits = 10)))

writeLines(jsonlite::toJSON(results, auto_unbox = TRUE, digits = 10), "results.json")

stata_compat_log()
