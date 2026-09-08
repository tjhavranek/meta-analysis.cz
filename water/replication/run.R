# run.R -- replication of Table 2 (funnel-asymmetry / FAT-PET regressions) from
# "Measuring the Income Elasticity of Water Demand: The Importance of Publication
#  and Endogeneity Biases", Land Economics 2018.
#
# Source data: the site's published water.csv (mirrors the author's dataset).
# Source code: water.do, lines 89-113 (the eststo block).
#
# Table 2 regresses incomeelasticity on standarderror (the funnel-asymmetry test):
#   YED_ij = YED_0 + beta * SE(YED_ij) + u_ij
# across 6 estimator/weight combinations (columns) and 3 samples (panels).
#
#   Unweighted OLS  : ivreg2 incomeelasticity standarderror, cluster(studyid)
#   Unweighted FE   : xtreg  incomeelasticity standarderror, fe cluster(studyid)
#   Study OLS       : ivreg2 ... [pweight = invnoest]              (1/numberofestimates)
#   Study FE        : xtreg  ... [pweight = invnoest], fe
#   Precision OLS   : ivreg2 ... [pweight = inverseofstandarderror] (1/standarderror)
#   Precision FE    : xtreg  ... [pweight = inv_med_se], fe        (1/study-level median SE)
#
# Panel A = whole sample (N = 307).
# Panel B = "No Endogeneity Control"   -> ovb == 1 (N = 142, confirmed against the data).
# Panel C = "Endogeneity Control"      -> ovb == 0 (N = 165, confirmed against the data).
#
# The weights `invnoest` (Study weight) and `inverseofstandarderror` (Precision weight)
# are published columns in water.csv -- not re-derived; they equal the do-file's
# `gen inv_no_est = 1/numberofestimates` (line 16) and `gen inv_se = 1/standarderror`
# (line 18). `inv_med_se`, used only by the Precision-FE column, is not a published column
# and is built here exactly as water.do lines 20-21 build it:
#     bysort studyid: egen med_se = median(standarderror)
#     gen inv_med_se = 1/med_se
# i.e. the per-study median of standarderror, inverted. Confirmed twice over: it reproduces
# the printed Precision-FE coefficient 1.514 and SE 1.176, and Stata 15.1 run on the site's
# CSV with these lines returns 1.5144078 (1.1758978), the same numbers this file produces.
#
# Scope note: for the two weighted fixed-effects columns (Study FE, Precision FE), only the
# slope (SE (publication bias)) is targeted, not the reported Stata `_cons`. stata_compat.R's
# st_xtreg_fe_cons() implements Stata's xtreg,fe constant (grand-mean-adjusted augmented
# regression) but takes no `weights` argument, so it cannot reproduce a *weighted* xtreg,fe
# constant without a change to that file, which is out of scope here. This is documented as
# an "unresolved" miss for those two cells rather than guessed at.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/water/replication/stata_compat.R")

d <- read.csv(
  (if (file.exists("water.csv")) "water.csv" else
     "https://meta-analysis.cz/data/v1/water/water.csv"),
  stringsAsFactors = FALSE
)

stopifnot(nrow(d) == 307)

# Per-study median standard error, used only as the Precision-FE weight (see note above).
d$med_se     <- ave(d$standarderror, d$studyid, FUN = median)
d$inv_med_se <- 1 / d$med_se

results <- list()
add <- function(label, value) results[[label]] <<- unname(value)

run_panel <- function(dd, prefix, weighted_fe = TRUE, ols_fn = st_ivreg2) {

  ## Unweighted OLS
  m <- ols_fn(incomeelasticity ~ standarderror, data = dd, cluster = "studyid")
  co <- st_coefs(m)
  add(paste0(prefix, "_UnwOLS_coef"),     co$estimate[co$term == "standarderror"])
  add(paste0(prefix, "_UnwOLS_se"),       co$std.error[co$term == "standarderror"])
  add(paste0(prefix, "_UnwOLS_const"),    co$estimate[co$term == "(Intercept)"])
  add(paste0(prefix, "_UnwOLS_const_se"), co$std.error[co$term == "(Intercept)"])

  ## Unweighted FE
  mfe <- st_xtreg_fe(incomeelasticity ~ standarderror, data = dd, panel = "studyid")
  cofe <- st_coefs(mfe, z = FALSE)
  add(paste0(prefix, "_UnwFE_coef"), cofe$estimate[cofe$term == "standarderror"])
  add(paste0(prefix, "_UnwFE_se"),   cofe$std.error[cofe$term == "standarderror"])
  cons <- st_xtreg_fe_cons("incomeelasticity", "standarderror", "studyid", dd)
  cocons <- st_coefs(cons, z = FALSE)
  add(paste0(prefix, "_UnwFE_const"),    cocons$estimate[cocons$term == "(Intercept)"])
  add(paste0(prefix, "_UnwFE_const_se"), cocons$std.error[cocons$term == "(Intercept)"])

  ## Study-weighted OLS  (pweight = invnoest = 1/numberofestimates, published column)
  mS <- ols_fn(incomeelasticity ~ standarderror, data = dd, cluster = "studyid",
                   weights = ~invnoest)
  coS <- st_coefs(mS)
  add(paste0(prefix, "_StudyOLS_coef"),     coS$estimate[coS$term == "standarderror"])
  add(paste0(prefix, "_StudyOLS_se"),       coS$std.error[coS$term == "standarderror"])
  add(paste0(prefix, "_StudyOLS_const"),    coS$estimate[coS$term == "(Intercept)"])
  add(paste0(prefix, "_StudyOLS_const_se"), coS$std.error[coS$term == "(Intercept)"])

  ## Precision-weighted OLS (pweight = inverseofstandarderror = 1/standarderror, published column)
  mP <- ols_fn(incomeelasticity ~ standarderror, data = dd, cluster = "studyid",
                   weights = ~inverseofstandarderror)
  coP <- st_coefs(mP)
  add(paste0(prefix, "_PrecOLS_coef"),     coP$estimate[coP$term == "standarderror"])
  add(paste0(prefix, "_PrecOLS_se"),       coP$std.error[coP$term == "standarderror"])
  add(paste0(prefix, "_PrecOLS_const"),    coP$estimate[coP$term == "(Intercept)"])
  add(paste0(prefix, "_PrecOLS_const_se"), coP$std.error[coP$term == "(Intercept)"])

  if (weighted_fe) {
    ## Study-weighted FE (pweight = invnoest)
    mSfe <- st_xtreg_fe(incomeelasticity ~ standarderror, data = dd, panel = "studyid",
                         weights = ~invnoest)
    coSfe <- st_coefs(mSfe, z = FALSE)
    add(paste0(prefix, "_StudyFE_coef"), coSfe$estimate[coSfe$term == "standarderror"])
    add(paste0(prefix, "_StudyFE_se"),   coSfe$std.error[coSfe$term == "standarderror"])

    ## Precision-weighted FE (pweight = inv_med_se; see construction note above)
    mPfe <- st_xtreg_fe(incomeelasticity ~ standarderror, data = dd, panel = "studyid",
                         weights = ~inv_med_se)
    coPfe <- st_coefs(mPfe, z = FALSE)
    add(paste0(prefix, "_PrecFE_coef"), coPfe$estimate[coPfe$term == "standarderror"])
    add(paste0(prefix, "_PrecFE_se"),   coPfe$std.error[coPfe$term == "standarderror"])
  }

  add(paste0(prefix, "_N"), nrow(dd))
}

## Panel A: whole sample
#
# Panel A's three OLS columns use st_regress, not st_ivreg2, even though the deposited
# do-file writes `ivreg2` on all three panels. This is not an inference from the R side --
# both commands were run in Stata 15.1 on the site's own water.csv,
# and the printed table picks a side in every
# discriminating cell:
#
#                              Stata ivreg2    Stata regress    paper prints
#   A Unw OLS  slope SE          .3018250        .3047873          0.305
#   A Study OLS slope SE         .1308745        .1321590          0.132
#   A Study OLS const SE         .0213596        .0215692          0.022
#   A Prec OLS slope SE          .3655457        .3691334          0.369
#
# Four independent Panel A cells match `regress` and none matches `ivreg2`. The two
# conventions differ by exactly sqrt(G/(G-1) * (N-1)/(N-K)) = 1.009815 here, so no data or
# weight change can move one of them onto the other; only the command can.
#
# Panels B and C are the mirror image and are left on st_ivreg2 (the default): their printed
# SEs match Stata's `ivreg2` exactly in all 16 OLS-family cells (e.g. B unweighted .3071809
# -> 0.307, C study .0941519 -> 0.0942, C precision .4897532 -> 0.490), and `regress` on the
# same subsamples misses them (.3127767, .0955321, .4969326). So the two conventions are not
# a modelling choice made here; they are what the paper's own two halves each reproduce.
#
# Reading: Panel A was reported from a different run than Panels B/C -- it also prints its
# SEs at 3 fixed decimals where B/C print 3 significant digits (0.0347, 0.0121, 0.0942),
# i.e. a different esttab format. The deposited do-file, as excerpted, records only the
# ivreg2 form and so does not reproduce its own paper's Panel A.
run_panel(d, "PanelA", weighted_fe = TRUE, ols_fn = st_regress)

## Panel B: "No Endogeneity Control"  -> ovb == 1 (N = 142)
dB <- st_keep_if(d, d$ovb == 1)
run_panel(dB, "PanelB", weighted_fe = FALSE)

## Panel C: "Endogeneity Control"     -> ovb == 0 (N = 165)
dC <- st_keep_if(d, d$ovb == 0)
run_panel(dC, "PanelC", weighted_fe = FALSE)

## ---- print + write ----------------------------------------------------------
for (nm in names(results)) {
  cat(sprintf("%-24s = %s\n", nm, format(results[[nm]], digits = 8)))
}

stata_compat_log()

jsonlite::write_json(results, "results.json", auto_unbox = TRUE, digits = NA)
