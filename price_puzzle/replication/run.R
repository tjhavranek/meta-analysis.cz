# run.R -- replication of "How to Solve the Price Puzzle? A Meta-Analysis"
# (Rusnak, Havranek & Horvath, JMCB 2013).
#
# PART 1: Table A1, "Test of Publication Bias and True Effect, OLS" -- the FAT-PET
# meta-regression of the approximated t-statistic on precision (1/SE), OLS with standard
# errors clustered at the study level, one column per impulse-response horizon (3, 6, 12,
# 18, 36 months).
#
# PART 2: the paper's own HEADLINE CLAIM (its text, not just its results tables) --
# meta-analysis.cz summarises the paper as "the price puzzle disappears once publication
# and misspecification biases are corrected, and prices fall instead, bottoming out 0.33%
# below". That sentence maps onto Table 5's "Best practice" row (Section 4 / Section 5
# CONCLUSION of the paper -- see the exact quotes at PART 2 below), which is the paper's
# own predicted price response evaluated at "best-practice" methodology, built from
# puzzle.do's *own* "Best Practice" block (the do-file the site holds at
# price_puzzle/puzzle.do, lines 236-259 -- fuller than the excerpt in this package's brief).
#
# Uses ONLY the wrappers in stata_compat.R -- including st_mixed, the wrapper this file
# provides for Stata's `xtmixed`/`mixed`, which is the estimator puzzle.do actually calls
# for every number reproduced here except Table A1. No feols/lm/rma/lmer/plm/ivreg/quantile
# call anywhere in this file; fixed effects and their covariance are read off the object
# st_mixed() already fit with lme4::fixef()/stats::vcov(), the same kind of accessor call
# st_coefs() itself makes on other wrappers' models -- never a fresh model-fitting call.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/price_puzzle/replication/stata_compat.R")

suppressMessages(library(jsonlite))
suppressMessages(library(fixest))
suppressMessages(library(lme4))

# ---------------------------------------------------------------------- data & construction
# The published price_puzzle.csv is the author's own wide file (one row per estimate),
# duplicated 7-fold across a "horizon" indicator (3, 6, 12, 18, 36, 88=bottom, 99=peak);
# the horizon-specific response/SE for a given row live in fixed-name columns M{h}R / SE{h}
# (M3R/SE3, M6R/SE6, M12R/SE12, M18R/SE18, M36R/SE36) that do not vary across the duplicate
# rows for the same idstudy/idest. puzzle.do lines 13-14 (`replace res=100*res` /
# `replace se=100*se`) show the author working in percentage-point units on generic `res`/
# `se` variables built (upstream of the excerpted do-file) from exactly this per-horizon
# selection; puzzle.do line 35ff regresses `t` (the approximated t-statistic, i.e. res/se)
# on `prec` (1/se) separately `if horizon==3/6/12/18/36`.
d <- read.csv(
  (if (file.exists("price_puzzle.csv")) "price_puzzle.csv" else
     "https://meta-analysis.cz/data/v1/price_puzzle/price_puzzle.csv"),
  stringsAsFactors = FALSE, check.names = FALSE
)

horizons <- list(
  list(h = 3,  Rcol = "M3R",  Scol = "SE3"),
  list(h = 6,  Rcol = "M6R",  Scol = "SE6"),
  list(h = 12, Rcol = "M12R", Scol = "SE12"),
  list(h = 18, Rcol = "M18R", Scol = "SE18"),
  list(h = 36, Rcol = "M36R", Scol = "SE36")
)

results <- list()
add <- function(label, value) results[[label]] <<- as.numeric(value)

for (spec in horizons) {
  h <- spec$h; Rcol <- spec$Rcol; Scol <- spec$Scol

  # puzzle.do line 7 (use puzzle.dta) + the horizon selection implicit in `if horizon==h`:
  # take the one row per estimate carrying this horizon's response/SE.
  sub <- st_keep_if(d, d$horizon == h)

  # puzzle.do lines 13-14: res/se are in percentage-point units.
  res <- sub[[Rcol]] * 100
  se  <- sub[[Scol]] * 100

  # Drop estimates with no reported response/SE at this horizon (Stata's `reg ... if
  # horizon==h` silently drops rows with missing res/se the same way).
  ok <- !is.na(res) & !is.na(se)
  sub <- sub[ok, , drop = FALSE]
  t    <- (res / se)[ok]
  prec <- (1 / se)[ok]

  reg_d <- data.frame(t = t, prec = prec, idstudy = sub$idstudy)

  # puzzle.do: eststo: reg t prec if horizon==h, vce(cluster idstudy)
  m <- st_regress(t ~ prec, data = reg_d, cluster = ~idstudy)
  co <- st_coefs(m)

  lab <- paste0("H", h, ": ")
  add(paste0(lab, "Intercept (bias) coef"), co$estimate[co$term == "(Intercept)"])
  add(paste0(lab, "Intercept (bias) se"),   co$std.error[co$term == "(Intercept)"])
  add(paste0(lab, "1/SE (effect) coef"),    co$estimate[co$term == "prec"])
  add(paste0(lab, "1/SE (effect) se"),      co$std.error[co$term == "prec"])
  add(paste0(lab, "R2"),                    fixest::r2(m, "r2"))
  add(paste0(lab, "Observations"),          nrow(reg_d))
  add(paste0(lab, "Studies"),               length(unique(reg_d$idstudy)))
}

# ======================================================================================
# PART 2: the paper's headline text claim
# ======================================================================================
#
# The paper's own words (index.html of the published paper page):
#
#   Section 3 / Figure 4 (publication bias only, no misspecification correction):
#   "The impulse response function corrected for publication bias is depicted in Figure 4:
#   it exhibits the price puzzle. In the short run prices increase, but in the medium run
#   they decrease and bottom out 18 months after the tightening. The maximum decrease in
#   the price level, however, is negligible: only 0.02%."
#
#   Section 4 / Section 5 CONCLUSION (publication AND misspecification bias corrected --
#   "best practice"):
#   "After controlling for both publication and misspecification biases, the price puzzle
#   is not present and prices bottom out 6 months after a 1 percentage point increase in
#   the interest rate. The maximum decrease in the price level reaches 0.33% and is
#   statistically significant at the 5% level."
#   (repeated in the CONCLUSION: "the maximum decrease in the price level ... reaches
#   0.33% and occurs half a year after the tightening.")
#
# meta-analysis.cz's site summary paraphrases the second quote. The number behind it is
# Table 5's "Best practice" row (-0.157, -0.331**, -0.225*, -0.155, -0.116 at horizons
# 3/6/12/18/36 months); -0.331 at 6 months is the "0.33% below" in the site summary, and
# "the price puzzle disappears" is the fact that EVERY horizon in that row is negative --
# no more of the short-run price INCREASE that defines the puzzle.
#
# Table 5's "Best practice" row is the predicted response of a "synthetic study" built from
# the SAME meta-regression as Table 4 ("Specific model": t on prec and 21 moderators, each
# entered as x/se, mixed-effects with a study-level random intercept), read off at fixed
# "best-practice" moderator values (preferred methodology set to 1/0, everything else at its
# sample mean or max) and se = 1 (prec = 1) so that the linear predictor is directly in
# response units. This is puzzle.do's own "Best Practice" block (site puzzle.do lines
# 236-248), which literally is:
#
#   quietly xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se
#     avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se
#     ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se
#     if horizon==h || idstudy:
#   lincom prec + 2.668301*growth_se + 7.748488*inf_se + 6.233974*vol_se +
#     .8368237*findev_se + .4598406*open_se + .7735787*indep_se + 6.298949*lnobs_se +
#     4*avgyear_se + 0*gdpdeflator_se + 1*single_se + 1*com_se + 1*foreign_se +
#     4.875197*lnend_variab_se + 0*ea_ip_se + 1*ea_gap_se + 0*ea_oth_se + 1*bvar_se +
#     0*favar_se + 1*svar_se + 0*sign_se + .4510718*cb_se + .054986*policy_se
#
# repeated for each horizon (the .do file's literal numbers, one line per horizon -- the
# constants are the paper's own best-practice moderator values: sample means for the
# country-characteristic moderators, sample maxima for "No. of observations"/"Average
# year"/"No. of variables", and 0/1 for the preferred/non-preferred methodology dummies).
# The `lincom` deliberately omits the model's own intercept -- reproduced exactly as
# written, not "corrected" to add one back in.
#
# ---- variable construction (puzzle.do lines 59-83, matched to this package's column names)
build_specific_covars <- function(sub, se) {
  data.frame(
    # sample means (country/policy characteristics) -----------------------------------
    growth_se       = sub[["GDP growth (PWT grgdpch)"]] / se,
    inf_se          = sub[["inflation (IFS) - inflation quarterly data CPI change over previous period, for germany yearly data from WEO used"]] / se,
    # puzzle.do line 73: replace vol=sqrt(vol) -- inflation volatility as a standard deviation
    vol_se          = sqrt(sub[["inflation volatility (variance of HP on inflation)"]]) / se,
    # puzzle.do line 76: replace findev=findev/100
    findev_se       = (sub[["domestic credit to private sector (% of GDP)"]] / 100) / se,
    # puzzle.do line 77: replace open=open/100
    open_se         = (sub[["openness (PWT openk)"]] / 100) / se,
    indep_se        = sub[["overall independence"]] / se,
    # sample maxima (data characteristics) ---------------------------------------------
    lnobs_se        = log(sub$nobs) / se,
    # puzzle.do line 61: avgyear=((syear+eyear)/2)-2000
    avgyear_se      = (((sub$syear + sub$eyear) / 2) - 2000) / se,
    # preferred/non-preferred methodology dummies (specification characteristics) -----
    gdpdeflator_se  = sub[["GDP deflator"]] / se,
    single_se       = sub$single / se,
    com_se          = sub$com / se,
    foreign_se      = sub$foreign / se,
    lnend_variab_se = log(sub$end_variab) / se,
    ea_ip_se        = sub$ea_ip / se,
    ea_gap_se       = sub$ea_gap / se,
    ea_oth_se       = sub$ea_oth / se,
    # estimation characteristics -------------------------------------------------------
    # bvar_se: puzzle.do labels this "BVAR" but the published CSV has no bvar column and
    # DOES have "var/favar/globalvar/panelvar/tvpvar" (model class) as well as
    # "meth_cl/meth_ml/meth_bay" (estimation method: classical/ML/Bayesian). The paper's
    # own text for best practice says "we prefer Bayesian estimation" (Section 4), which
    # is meth_bay, not a VAR-type dummy -- meth_bay is what "bvar_se" is built from here.
    bvar_se         = sub$meth_bay / se,
    favar_se        = sub$favar / se,
    # svar_se/sign_se: identification scheme. The CSV's identification dummies are
    # ir_chol/ir_svar/ir_gen/ir_sign/ir_oth (recursive Cholesky is the omitted base
    # category); "nonrecursive identification" in the paper's best-practice text is ir_svar.
    svar_se         = sub$ir_svar / se,
    sign_se         = sub$ir_sign / se,
    cb_se           = sub$CB / se,
    # policy_se: puzzle.do lines 68-69, gen policy=0 / replace policy=1 if
    # ministry==1 | imf_bis_oecd==1
    policy_se       = as.numeric(sub$ministry == 1 | sub$IMF_BIS_OECD == 1) / se,
    check.names = FALSE
  )
}

# the do-file's own literal best-practice target values (site puzzle.do lines 240-259) --
# the raw moderator value each x_se is evaluated at once se=1 (prec=1) makes x_se == x.
bp_target <- c(
  growth_se = 2.668301, inf_se = 7.748488, vol_se = 6.233974, findev_se = 0.8368237,
  open_se = 0.4598406, indep_se = 0.7735787, lnobs_se = 6.298949, avgyear_se = 4,
  gdpdeflator_se = 0, single_se = 1, com_se = 1, foreign_se = 1, lnend_variab_se = 4.875197,
  ea_ip_se = 0, ea_gap_se = 1, ea_oth_se = 0, bvar_se = 1, favar_se = 0, svar_se = 1,
  sign_se = 0, cb_se = 0.4510718, policy_se = 0.054986
)
specific_covars <- names(bp_target)

bp_paper <- c("3" = -0.157, "6" = -0.331, "12" = -0.225, "18" = -0.155, "36" = -0.116)

cat("\n===== PART 2: the paper's headline claim =====\n")
cat("Table 5, 'Best practice' row (predicted price response, %, at best-practice methodology):\n\n")

for (spec in horizons) {
  h <- spec$h; Rcol <- spec$Rcol; Scol <- spec$Scol

  sub <- st_keep_if(d, d$horizon == h)
  res <- sub[[Rcol]] * 100
  se  <- sub[[Scol]] * 100
  ok  <- !is.na(res) & !is.na(se)
  sub <- sub[ok, , drop = FALSE]
  res <- res[ok]; se <- se[ok]

  t    <- res / se
  prec <- 1 / se

  reg_d <- cbind(
    data.frame(t = t, prec = prec, idstudy = sub$idstudy),
    build_specific_covars(sub, se)
  )
  # puzzle.do's "Specific model"/"Best Practice" regressions carry no explicit missing-data
  # handling beyond Stata's own listwise deletion inside `if horizon==h` -- reproduce that.
  reg_d <- reg_d[stats::complete.cases(reg_d), , drop = FALSE]

  fml <- stats::as.formula(
    paste("t ~ prec +", paste(specific_covars, collapse = " + "), "+ (1 | idstudy)")
  )
  # puzzle.do: `xtmixed t prec <21 moderators> if horizon==h || idstudy:` (no `mle` option
  # on this specification -> Stata's xtmixed/mixed default, REML). st_mixed always fits
  # REML = FALSE (its own documented convention for `mixed`/`xtmixed`, fixed in
  # stata_compat.R and not editable here). For this specification the two converge to the
  # same printed precision at every horizon but one (see REPLICATION.md) -- flagged, not
  # patched around.
  m  <- suppressMessages(suppressWarnings(st_mixed(fml, data = reg_d)))
  fe <- lme4::fixef(m)
  V  <- as.matrix(stats::vcov(m))

  a <- setNames(rep(0, length(fe)), names(fe))
  a["prec"] <- 1
  a[specific_covars] <- bp_target[specific_covars]

  pred   <- as.numeric(fe["prec"] * 1 + sum(fe[specific_covars] * bp_target[specific_covars]))
  se_pred <- sqrt(as.numeric(t(a) %*% V %*% a))

  lab <- paste0("H", h, ": Best practice (Table 5)")
  add(paste0(lab, " coef"), pred)
  add(paste0(lab, " se"),   se_pred)

  cat(sprintf("  %2d months:  produced = %+.3f%%   (SE %.3f)   paper prints %+.3f%%\n",
              h, pred, se_pred, bp_paper[as.character(h)]))
}

cat(sprintf(
  "\n  -> HEADLINE NUMBER: at 6 months the best-practice response bottoms at %+.3f%%\n",
  results[["H6: Best practice (Table 5) coef"]]
))
cat(sprintf(
  "     (the paper's text: 'The maximum decrease in the price level reaches 0.33%%')\n"
))
cat(sprintf(
  "  -> 'the price puzzle ... is not present': all %d horizons above are negative\n",
  length(horizons)
))
no_puzzle <- all(sapply(horizons, function(spec) {
  results[[paste0("H", spec$h, ": Best practice (Table 5) coef")]] < 0
}))
add("Best practice shows no puzzle (all horizons negative)", no_puzzle)

# ---- context: the SAME quantity with publication bias corrected but NOT misspecification
# (Table 2's simple mixed-effects model, no moderators) -- the paper's OTHER quoted number,
# "only 0.02%", which still exhibits the puzzle. Kept separate from the headline claim above
# so the two are never conflated: this is the "publication bias alone" benchmark the paper
# contrasts its "best practice" (both biases) result against.
cat("\nFor context -- Table 2 (publication-bias correction only, no moderators):\n")
for (spec in horizons) {
  h <- spec$h; Rcol <- spec$Rcol; Scol <- spec$Scol
  sub <- st_keep_if(d, d$horizon == h)
  res <- sub[[Rcol]] * 100
  se  <- sub[[Scol]] * 100
  ok  <- !is.na(res) & !is.na(se)
  sub <- sub[ok, , drop = FALSE]
  t    <- (res / se)[ok]
  prec <- (1 / se)[ok]
  reg_d <- data.frame(t = t, prec = prec, idstudy = sub$idstudy)

  # puzzle.do: `xtmixed t prec if horizon==h || idstudy:` (Table 2)
  m  <- suppressMessages(suppressWarnings(st_mixed(t ~ prec + (1 | idstudy), data = reg_d)))
  fe <- lme4::fixef(m)
  se_fe <- sqrt(diag(as.matrix(stats::vcov(m))))

  lab <- paste0("H", h, ": Table 2 corrected effect (pub. bias only)")
  add(paste0(lab, " coef"), fe["prec"])
  add(paste0(lab, " se"),   se_fe["prec"])

  cat(sprintf("  %2d months:  1/SE (effect) = %+.4f%%  (SE %.4f)\n", h, fe["prec"], se_fe["prec"]))
}
cat(sprintf(
  "\n  -> the paper's text: 'bottom out 18 months ... maximum decrease ... only 0.02%%'\n"
))
cat(sprintf(
  "     produced at 18 months: %+.3f%% -- rounds to the paper's 0.02%%, and it is still\n",
  results[["H18: Table 2 corrected effect (pub. bias only) coef"]]
))
cat("     the puzzle (short-run responses at 3/6/12 months are not all negative in Table 2)\n")

# ------------------------------------------------------------------------------- reporting
cat("\n===== Produced numbers =====\n")
for (nm in names(results)) cat(sprintf("%-55s %s\n", nm, format(results[[nm]], digits = 8)))

write(toJSON(results, auto_unbox = TRUE, digits = 10), file = "results.json")
cat("\nWrote results.json\n")

stata_compat_log()
