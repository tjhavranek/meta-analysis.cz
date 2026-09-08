# run.R -- replication of Table A3 (Tests of publication bias, currencies of developed
# countries), Panels A (FAT-PET) and B (PEESE), from:
#   "How Puzzling Is the Forward Premium Puzzle? A Meta-Analysis", European Economic Review 2021
#
# Data: the site-published forward.csv (mirrors the author's forward.dta 1:1, same 82 columns,
# same 3643 rows, just renamed from the author's lowercase Stata names to Title_Case site names).
#
# ---------------------------------------------------------------------------------------------
# WHERE THE SPECIFICATIONS COME FROM
# ---------------------------------------------------------------------------------------------
# The published forward.do contains the FULL-SAMPLE version of this table (Table 2, N = 2989)
# but NOT the developed-country version (Table A3, N = 2582): no line in the do-file carries a
# country-scope restriction. The do-file also stops short of the FE column of Panel B, which the
# paper prints for Tables 2, A1 and A3 alike. Both gaps were closed by running Stata 15.1 on the
# published forward.dta and matching the do-file's own commands against the printed tables (probe
# files under repl/stata_work_forward/). What the do-file does give, for the full sample:
#
#   9   use "forward.dta", clear
#   10  xtset studyid
#   21  winsor2 beta se, cuts(5 95) replace
#   22  gen tstat = beta/se
#   23  gen double inv_se = 1/se
#   24  gen double root=sqrt(sample_size_full)
#   25  gen double inv_root=1/root
#   28  gen double inv_nobs=1/nobs if lnspot==0
#   106 gen tstat_w = tstat*sqrt(inv_nobs)
#   107 gen inv_se_w = inv_se*sqrt(inv_nobs)
#   108 gen root_w = root*sqrt(inv_nobs)
#   109 gen inv_sqrt_nobs=sqrt(inv_nobs)
#   110 eststo: xtreg tstat inv_se if lnspot==0 [pweight=inv_nobs], fe                  -> A, FE
#   111 *note: fixed effects not weighted here, recalculate bootstrapped se's
#   112 bootstrap _b, reps(100): xtreg tstat_w inv_se_w if lnspot==0, fe                -> A, FE ses
#   113 eststo: bootstrap _b, reps(100): ivreg2 tstat_w inv_sqrt_nobs inv_se_w if lnspot==0, noconstant                -> A, WLS
#   114 eststo: bootstrap _b, reps(100): ivreg2 tstat_w inv_sqrt_nobs (inv_se_w=root_w) if lnspot==0, noconstant       -> A, IV
#   119 gen se_w = se*sqrt(inv_nobs)
#   120 gen inv_root_w = inv_root*sqrt(inv_nobs)
#   121 eststo: bootstrap _b, reps(100): reg tstat_w se_w inv_se_w if lnspot==0, noconstant                            -> B, WLS
#   122 eststo: bootstrap _b, reps(100): ivreg2 tstat_w (inv_se_w se_w = inv_root_w root_w) if lnspot==0, noconstant   -> B, IV
#
# SAMPLE. Table A3's note: "Only difference estimates (Eq. 3) for the currencies of advanced
# countries are included." lnSpot == 0 is the differences specification; the advanced-country
# restriction is not written anywhere in the published code, so it is pinned empirically:
# lnSpot == 0 & Emerging_currencies == 0 gives EXACTLY N = 2582, the Observations row printed
# under all six columns of Table A3, and every deterministic cell below then lands on the
# printed digit. Stata, same filter: `count if lnspot==0 & emerging_currencies==0` -> 2,582.
#
# nobs. `gen double inv_nobs=1/nobs if lnspot==0` (line 28) sits before any country restriction,
# so a study's count of difference-equation estimates is taken over the WHOLE lnSpot == 0
# population (2989 obs, all currency scopes), not over the advanced-only subsample. Recomputing
# it on the subsample moves every coefficient 5-15% off the printed value.
#
# PANEL B, FE COLUMN (no do-file line exists). Recovered in Stata and confirmed on three
# independent printed tables at once, which is why it is trusted:
#
#     xtreg tstat_w se_w inv_se_w, fe          <- unweighted, on the sqrt(inv_nobs)-scaled vars
#       "Mean beyond bias (1/SE)"  = _b[inv_se_w]
#       "Publication bias (SE)"    = _cons
#
#                              Stata            printed
#     Table 2  (N = 2989)      0.621751        0.622        -0.362320      -0.362
#     Table A1 (N =  654)      0.932814        0.933         0.298343       0.298
#     Table A3 (N = 2582)      0.666179        0.666        -0.389727      -0.390
#
# The row labelled "(SE)" is therefore the model's intercept, not the coefficient on se_w (which
# is +0.3316 here, and matches nothing printed). Three tables, six cells, all to the printed
# digit: the label in the paper is off, the number is not. Note that because sqrt(inv_nobs) is
# constant within a study, the FE absorb it, so this unweighted fit on scaled variables and the
# [pweight=inv_nobs] fit on raw variables give IDENTICAL slopes -- they differ only in the
# intercept, and Panel B prints the one from the scaled fit while Panel A prints the one from the
# weighted fit (Stata: -2.833 vs -2.331 for A3; the printed value is -2.331).
#
# PANEL A, PUBLICATION BIAS (the constant of a [pweight]-ed xtreg, fe). st_xtreg_fe_cons() in
# stata_compat.R takes no weights, and its unweighted answer here is -2.33236, which rounds to
# -2.332 and misses the printed -2.331. Stata's reported _cons for `xtreg, fe` is documented in
# that same wrapper as "the grand mean of y minus the fitted within slope times the grand mean of
# x"; with pweights the grand means are the WEIGHTED ones. Checked in Stata on this sample:
#
#     xtreg tstat inv_se [pweight=inv_nobs], fe      _cons              = -2.33147601
#     sum tstat [aweight=inv_nobs] ; sum inv_se [aweight=inv_nobs]
#       ybar_w - b*xbar_w = 0.03516583 - 0.65720749*3.60105731          = -2.33147601
#
# identical to eight decimals, so the constant below is that documented identity evaluated with
# aweighted means. No estimator outside the wrapper set is used to obtain it.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/forward/replication/stata_compat.R")

set.seed(NULL)  # author's bootstrap carries no seed() option -> genuinely stochastic; not repaired

data_path <- (if (file.exists("forward.csv")) "forward.csv" else
     "https://meta-analysis.cz/data/v1/forward/forward.csv")
d <- read.csv(data_path, stringsAsFactors = FALSE)

results <- list()
add <- function(label, value) results[[label]] <<- value

# Stata's `sum x [aweight=w]`: the weighted mean over the rows where x is present.
wmean <- function(x, w) {
  ok <- !is.na(x) & !is.na(w)
  sum(w[ok] * x[ok]) / sum(w[ok])
}

# ---------------------------------------------------------------------- prep (whole dataset)
# winsor2 beta se, cuts(5 95) replace  -- on the FULL just-loaded dataset, before any `if`.
d$Coeff_w <- st_winsor2(d$Coeff, cuts = c(5, 95))
d$SE_w    <- st_winsor2(d$SE,    cuts = c(5, 95))
d$tstat   <- d$Coeff_w / d$SE_w
d$inv_se  <- 1 / d$SE_w

# ------------------------------------------------------------- Table A3 sample (Advanced, Eq.3)
d0 <- st_keep_if(d, d$lnSpot == 0)
nobs_tab <- table(d0$StudyID)
d0$nobs     <- as.numeric(nobs_tab[as.character(d0$StudyID)])
d0$inv_nobs <- 1 / d0$nobs

dA <- st_keep_if(d0, d0$Emerging_currencies == 0)
n_adv <- nrow(dA)
add("A3_PanelA_Obs", n_adv)
add("A3_PanelB_Obs", n_adv)

dA$root          <- sqrt(dA$Sample_size)
dA$inv_root      <- 1 / dA$root
dA$tstat_w       <- dA$tstat * sqrt(dA$inv_nobs)
dA$inv_se_w      <- dA$inv_se * sqrt(dA$inv_nobs)
dA$root_w        <- dA$root * sqrt(dA$inv_nobs)
dA$inv_sqrt_nobs <- sqrt(dA$inv_nobs)
dA$se_w          <- dA$SE_w * sqrt(dA$inv_nobs)
dA$inv_root_w    <- dA$inv_root * sqrt(dA$inv_nobs)

# ----------------------------------------------------------------------- bootstrap SE helper
# Mirrors Stata's `bootstrap _b, reps(R): <cmd>`: no cluster() given in the author's bootstrap
# prefix, so this is plain obs-level resampling with replacement, refit each time through the
# SAME wrapper used for the point estimate. SD across reps is the bootstrap SE. Stochastic --
# reported for completeness, never used to judge the verdict.
BOOT_REPS <- 100   # the author's reps(100)

boot_se <- function(fit_fun, data, term, reps = BOOT_REPS) {
  n <- nrow(data)
  ests <- rep(NA_real_, reps)
  for (i in seq_len(reps)) {
    idx <- sample.int(n, n, replace = TRUE)
    est <- tryCatch({
      m <- fit_fun(data[idx, , drop = FALSE])
      cf <- st_coefs(m)
      cf$estimate[cf$term == term]
    }, error = function(e) NA_real_)
    ests[i] <- if (length(est) == 1) est else NA_real_
  }
  stats::sd(ests, na.rm = TRUE)
}

# Same resampling, but for a statistic that is a FUNCTION of the fit and the resampled data
# (here: the reported _cons, which Stata forms from the fitted slope and the sample's own
# grand means -- so the means must be recomputed inside each replication, exactly as Stata does).
boot_se_stat <- function(stat_fun, data, reps = BOOT_REPS) {
  n <- nrow(data)
  ests <- rep(NA_real_, reps)
  for (i in seq_len(reps)) {
    ests[i] <- tryCatch(stat_fun(data[sample.int(n, n, replace = TRUE), , drop = FALSE]),
                        error = function(e) NA_real_)
  }
  stats::sd(ests, na.rm = TRUE)
}

# =========================================================== Panel A: FAT-PET (N = 2582)

## FE: xtreg tstat inv_se if <sample> [pweight=inv_nobs], fe
fit_fe_A <- function(dat) st_xtreg_fe(tstat ~ inv_se, data = dat, panel = "StudyID",
                                      weights = ~inv_nobs)
m_fe_A  <- fit_fe_A(dA)
cf_fe_A <- st_coefs(m_fe_A)
b_fe_A  <- cf_fe_A$estimate[cf_fe_A$term == "inv_se"]
add("A3_PanelA_FE_MeanBeyondBias", b_fe_A)

## Publication bias = the _cons Stata prints for that command (see header note).
cons_fe_A <- function(dat) {
  m  <- fit_fe_A(dat)
  cf <- st_coefs(m)
  b  <- cf$estimate[cf$term == "inv_se"]
  wmean(dat$tstat, dat$inv_nobs) - b * wmean(dat$inv_se, dat$inv_nobs)
}
add("A3_PanelA_FE_PubBias", cons_fe_A(dA))

# Standard errors. The author's own note at do-file line 111 -- "fixed effects not weighted here,
# recalculate bootstrapped se's" -- says the FE column's parentheses are bootstrapped, not the
# analytic clustered ones this command reports (0.173 / 0.622 here against a printed 0.117 /
# 0.340). Stata refuses `bootstrap` over a weighted command ("weights not allowed", r(101)),
# which is exactly why line 112 re-runs the fit unweighted on the scaled variables. Reproduced
# that way here: 400 reps in Stata give 0.1096 for the slope against a printed 0.117, well inside
# the noise of the author's 100 reps. The constant's bootstrap comes out at 0.29 against a
# printed 0.340; -- that one cell is NOT matched and is not claimed to be.
fit_fe_A_scaled <- function(dat) st_xtreg_fe(tstat_w ~ inv_se_w, data = dat, panel = "StudyID")
add("A3_PanelA_FE_MeanBeyondBias_SE", boot_se(fit_fe_A_scaled, dA, "inv_se_w"))
add("A3_PanelA_FE_PubBias_SE",        boot_se_stat(cons_fe_A, dA))

## WLS: ivreg2 tstat_w inv_sqrt_nobs inv_se_w if lnspot==0, noconstant  (bootstrap, reps(100))
fit_wls_A <- function(dat) st_ivreg2(tstat_w ~ inv_sqrt_nobs + inv_se_w - 1, data = dat)
m_wls_A <- fit_wls_A(dA)
cf_wls_A <- st_coefs(m_wls_A)
add("A3_PanelA_WLS_MeanBeyondBias", cf_wls_A$estimate[cf_wls_A$term == "inv_se_w"])
add("A3_PanelA_WLS_PubBias",        cf_wls_A$estimate[cf_wls_A$term == "inv_sqrt_nobs"])
add("A3_PanelA_WLS_MeanBeyondBias_SE", boot_se(fit_wls_A, dA, "inv_se_w"))
add("A3_PanelA_WLS_PubBias_SE",        boot_se(fit_wls_A, dA, "inv_sqrt_nobs"))

## IV: ivreg2 tstat_w inv_sqrt_nobs (inv_se_w=root_w) if lnspot==0, noconstant  (bootstrap 100)
fit_iv_A <- function(dat) st_ivreg2(tstat_w ~ inv_sqrt_nobs - 1 | inv_se_w ~ root_w, data = dat)
m_iv_A <- fit_iv_A(dA)
cf_iv_A <- st_coefs(m_iv_A)
add("A3_PanelA_IV_MeanBeyondBias", cf_iv_A$estimate[cf_iv_A$term == "fit_inv_se_w"])
add("A3_PanelA_IV_PubBias",        cf_iv_A$estimate[cf_iv_A$term == "inv_sqrt_nobs"])
add("A3_PanelA_IV_MeanBeyondBias_SE", boot_se(fit_iv_A, dA, "fit_inv_se_w"))
add("A3_PanelA_IV_PubBias_SE",        boot_se(fit_iv_A, dA, "inv_sqrt_nobs"))

# =========================================================== Panel B: PEESE (N = 2582)

## FE: xtreg tstat_w se_w inv_se_w, fe   (recovered in Stata; see header note)
fit_fe_B <- function(dat) st_xtreg_fe(tstat_w ~ se_w + inv_se_w, data = dat, panel = "StudyID")
m_fe_B  <- fit_fe_B(dA)
cf_fe_B <- st_coefs(m_fe_B)
add("A3_PanelB_FE_MeanBeyondBias", cf_fe_B$estimate[cf_fe_B$term == "inv_se_w"])

## The row the paper labels "Publication bias (SE)" is this model's reported _cons.
cons_fe_B <- function(dat) {
  cf <- st_coefs(fit_fe_B(dat))
  b_se  <- cf$estimate[cf$term == "se_w"]
  b_inv <- cf$estimate[cf$term == "inv_se_w"]
  mean(dat$tstat_w, na.rm = TRUE) - b_se * mean(dat$se_w, na.rm = TRUE) -
    b_inv * mean(dat$inv_se_w, na.rm = TRUE)
}
add("A3_PanelB_FE_PubBias", cons_fe_B(dA))

# Bootstrapped, as for every other cell in Panels A and B. Stata with 400 reps on this same
# design returns 0.1103 and 0.0569 against the printed 0.109 and 0.0537 -- both inside the noise
# of the author's reps(100), which is the strongest available evidence that this IS the command
# behind the FE column of Panel B.
add("A3_PanelB_FE_MeanBeyondBias_SE", boot_se(fit_fe_B, dA, "inv_se_w"))
add("A3_PanelB_FE_PubBias_SE",        boot_se_stat(cons_fe_B, dA))

## WLS: reg tstat_w se_w inv_se_w if lnspot==0, noconstant  (bootstrap, reps(100))
fit_wls_B <- function(dat) st_regress(tstat_w ~ se_w + inv_se_w - 1, data = dat)
m_wls_B <- fit_wls_B(dA)
cf_wls_B <- st_coefs(m_wls_B, z = FALSE)
add("A3_PanelB_WLS_MeanBeyondBias", cf_wls_B$estimate[cf_wls_B$term == "inv_se_w"])
add("A3_PanelB_WLS_PubBias",        cf_wls_B$estimate[cf_wls_B$term == "se_w"])
add("A3_PanelB_WLS_MeanBeyondBias_SE", boot_se(fit_wls_B, dA, "inv_se_w"))
add("A3_PanelB_WLS_PubBias_SE",        boot_se(fit_wls_B, dA, "se_w"))

## IV: ivreg2 tstat_w (inv_se_w se_w = inv_root_w root_w) if lnspot==0, noconstant (bootstrap 100)
fit_iv_B <- function(dat) st_ivreg2(tstat_w ~ 0 | inv_se_w + se_w ~ inv_root_w + root_w, data = dat)
m_iv_B <- fit_iv_B(dA)
cf_iv_B <- st_coefs(m_iv_B)
add("A3_PanelB_IV_MeanBeyondBias", cf_iv_B$estimate[cf_iv_B$term == "fit_inv_se_w"])
add("A3_PanelB_IV_PubBias",        cf_iv_B$estimate[cf_iv_B$term == "fit_se_w"])
add("A3_PanelB_IV_MeanBeyondBias_SE", boot_se(fit_iv_B, dA, "fit_inv_se_w"))
add("A3_PanelB_IV_PubBias_SE",        boot_se(fit_iv_B, dA, "fit_se_w"))

# ===========================================================================================
# The site's headline: "0.23-0.45 for developed and 0.95-1.16 for emerging currencies"
# ===========================================================================================
#
# That sentence is Table 5's "Advanced currencies" row (0.309 / 0.448 / 0.231) and "Emerging
# currencies" row (0.945 / 1.164 / 0.947), read as a min-max range across its three columns, and
# it is repeated verbatim in the abstract and in Section 5.4.
#
# ---- Why these six numbers are NOT produced here ------------------------------------------
# Section 5.4 states the provenance: "we calculate an implied estimate of beta by using the
# results of BMA in Subsection 5.3 and calculating a linear combination of BMA coefficients and
# the chosen values for each variable." BMA here is literal Bayesian model averaging, run in R
# with the BMS package. forward.do lines 590-608 keep the call, commented out because it was run
# outside Stata:
#
#   bma_dilut = bms(dataforward, burn=1e6, iter=5e6, g="UIP", mprior="dilut", nmodel=5000,
#                    mcmc="bd", user.int=FALSE)
#   coef(bma_dilut, order.by.pip = F, exact=T, include.constant=T)
#
# A 5-million-draw MCMC model average over 2^43 candidate specifications, with no seed, has no
# counterpart among st_ivreg2 / st_xtreg_fe / st_regress / st_metan / st_winsor* / st_keep_if /
# st_drop_if / st_coefs, and reaching for BMS::bms() would be exactly the kind of unaudited
# estimator this layer exists to prevent. The six headline cells are therefore left NA.
#
# ---- What the do-file's own frequentist analog gives (corroborating context, not the target) --
# forward.do also contains an uncommented, directly runnable answer to the same question -- one
# weighted OLS fit plus `lincom`, lines 683-736, "Heterogeneity - Best practice". Every step is a
# wrappers in stata_compat.R, so it is computed below. It is a DIFFERENT ESTIMATOR (a single fit, no model
# averaging), and it does not reproduce Table 5 -- verified in Stata 15.1 on the published
# forward.dta, which returns
#
#                       this code / Stata      Table 5 (BMA)
#     Advanced, preferred    0.274726             0.309
#     Advanced, F&P          0.421931             0.448
#     Advanced, Breedon     -0.078089             0.231
#     Emerging,  preferred   1.035289             0.945
#     Emerging,  F&P         1.132662             1.164
#     Emerging,  Breedon     0.690812             0.947
#
# Right sign and rough magnitude in five of six, and the F&P column within 0.03, but not the
# printed digits -- which is what a model-averaged posterior mean versus a single OLS fit should
# look like. Reported under Context_* labels so nothing here can be mistaken for Table 5.
#
# ---- One caveat on the mapping -------------------------------------------------------------
# The site publishes a FINER coding than the 42 moderators the author regressed on: several of
# the do-file's variables are aggregates built before the data were exported, and the site does
# not document how. They were recovered from the Mean/SD columns of the paper's own Table 3
# (computed on lnSpot == 0, N = 2989), which pins them uniquely for the ones used below:
#     controls           = Forward_premium_power2_3 | Other_controls        -> 0.0435 / 0.204
#                          (Table 3 "Controls": 0.04 / 0.21)
#     large_differential = Large_differential | Large_positive_interest_diff -> 0.0335 / 0.180
#                          (Table 3 "Large differential": 0.03 / 0.18)
#     small_differential = Small_differential | Low_Negative_interest_diff   -> 0.0348 / 0.183
#                          (Table 3 "Small differential": 0.03 / 0.18)
#     firstdraft_year    = firstpub  -> mean 30.1138 (Table 3 "First-draft year": 30.11 / 8.03);
#                          firstpubo is the raw year and does NOT match.
# The 1:1 names below were pinned the same way (Advanced_currencies 0.3878 vs 0.39, N 0.5496 vs
# 0.55, Time_diff 1.0083 vs 1.01, IF_recursive 0.4592 vs 0.46, Normcit 1.7047 vs 1.70, ...).

d$controls_agg <- as.numeric(d$Forward_premium_power2_3 == 1 | d$Other_controls == 1)
d$large_diff   <- as.numeric(d$Large_differential == 1 | d$Large_positive_interest_diff == 1)
d$small_diff   <- as.numeric(d$Small_differential == 1 | d$Low_Negative_interest_diff == 1)
d$fd_year      <- d$firstpub

d5 <- st_keep_if(d, d$lnSpot == 0)                      # 2989 differences estimates
nobs5 <- table(d5$StudyID)
d5$nobs          <- as.numeric(nobs5[as.character(d5$StudyID)])
d5$inv_sqrt_nobs <- 1 / sqrt(d5$nobs)

# do-file variable -> site column, for the 43-regressor "Best practice" model (line 697)
map5 <- c(
  se                       = "SE_w",
  spot_rate_percentage     = "Diff_ln_spot_percent",
  advanced_currencies      = "Advanced_currencies",
  emerging_currencies      = "Emerging_currencies",
  german_mark              = "German_mark",
  french_franc             = "French_franc",
  british_pound            = "GBP",
  italian_lira             = "Italian_lira",
  japanese_yen             = "JPY",
  swiss_franc              = "Swiss_franc",
  euro                     = "Euro",
  european_currencies      = "geo_Europe",
  other_country_currencies = "geo_Other",
  british_pound_base       = "GBP_base",
  euro_base                = "Euro_base",
  german_mark_base         = "German_mark_base",
  shorter_horizon          = "Less_1month",
  onemonth_horizon         = "month",
  onemonth_oneyear_horizon = "month_to_1year",
  oneyear_horizon          = "year",
  daily_frequency          = "Daily",
  weekly_frequency         = "Weekly",
  monthly_frequency        = "Monthly",
  time_difference          = "Time_diff",
  number_of_currencies     = "N",
  overlapping_problem      = "Overlapping_problem",
  controls                 = "controls_agg",
  ols_method               = "OLS",
  fixed_effects_method     = "FE",
  regime_switching_model   = "Regime_switching",
  sur_method               = "SUR",
  large_positive_premium   = "Large_positive_forward_premium",
  low_negative_premium     = "Low_negative_forward_premium",
  overvalued_currency      = "Overvalued_currency",
  undervalued_currency     = "Undervalued_currency",
  large_differential       = "large_diff",
  small_differential       = "small_diff",
  datastream_source        = "Datastream",
  bank_data_source         = "Bank_data_sources",
  dataresources_source     = "Data_Resources_Inc",
  impact_factor            = "IF_recursive",
  citations                = "Normcit",
  firstdraft_year          = "fd_year")

# lines 581-586: every listed variable is replaced in place by variable*inv_sqrt_nobs
d5$dep_w <- d5$Coeff_w * d5$inv_sqrt_nobs
for (nm in names(map5)) d5[[paste0("w_", nm)]] <- d5[[map5[[nm]]]] * d5$inv_sqrt_nobs

reg_w <- paste0("w_", names(map5))
fml5_1 <- stats::as.formula(paste("dep_w ~", paste(reg_w, collapse = " + ")))
m5_1 <- st_ivreg2(fml5_1, data = d5)                                    # line 697 and line 725
cf5_1 <- st_coefs(m5_1)

fml5_2 <- stats::as.formula(paste("dep_w ~ inv_sqrt_nobs +", paste(reg_w, collapse = " + ")))
m5_2 <- st_ivreg2(fml5_2, data = d5)                                    # line 711 (F&P)
cf5_2 <- st_coefs(m5_2)

get_b   <- function(cf, nm) cf$estimate[cf$term == paste0("w_", nm)]
cons_of <- function(cf) cf$estimate[cf$term == "(Intercept)"]
mn <- function(nm) mean(d5[[paste0("w_", nm)]], na.rm = TRUE)
mi <- function(nm) min(d5[[paste0("w_", nm)]],  na.rm = TRUE)
mx <- function(nm) max(d5[[paste0("w_", nm)]],  na.rm = TRUE)

## lincom, lines 698/699: the authors' "preferred methodology" -- sample max/min/mean
lincom_preferred <- function(cf, curr) {
  b <- function(nm) get_b(cf, nm)
  cons_of(cf) +
    b("spot_rate_percentage") * mn("spot_rate_percentage") +
    b(curr) * mx(curr) +
    b("british_pound_base") * mn("british_pound_base") +
    b("euro_base") * mn("euro_base") + b("german_mark_base") * mn("german_mark_base") +
    b("shorter_horizon") * mi("shorter_horizon") +
    b("onemonth_horizon") * mn("onemonth_horizon") +
    b("onemonth_oneyear_horizon") * mx("onemonth_oneyear_horizon") +
    b("oneyear_horizon") * mx("oneyear_horizon") +
    b("daily_frequency") * mn("daily_frequency") + b("weekly_frequency") * mn("weekly_frequency") +
    b("monthly_frequency") * mn("monthly_frequency") +
    b("time_difference") * mx("time_difference") +
    b("number_of_currencies") * mn("number_of_currencies") +
    b("overlapping_problem") * mi("overlapping_problem") +
    b("controls") * mn("controls") +
    b("ols_method") * mi("ols_method") +
    b("fixed_effects_method") * mn("fixed_effects_method") +
    b("regime_switching_model") * mx("regime_switching_model") +
    b("sur_method") * mx("sur_method") +
    b("large_positive_premium") * mn("large_positive_premium") +
    b("low_negative_premium") * mn("low_negative_premium") +
    b("overvalued_currency") * mn("overvalued_currency") +
    b("undervalued_currency") * mn("undervalued_currency") +
    b("large_differential") * mn("large_differential") +
    b("small_differential") * mn("small_differential") +
    b("datastream_source") * mn("datastream_source") +
    b("bank_data_source") * mn("bank_data_source") +
    b("dataresources_source") * mn("dataresources_source") +
    b("impact_factor") * mx("impact_factor") +
    b("citations") * mx("citations") +
    b("firstdraft_year") * mx("firstdraft_year")
}

## lincom, lines 712/713: Frankel & Poonawala (2010) -- literal values copied from the do-file
lincom_fp <- function(cf, curr) {
  b <- function(nm) get_b(cf, nm)
  cons_of(cf) + b(curr) * mx(curr) +
    b("british_pound_base") * mn("british_pound_base") +
    b("euro_base") * mn("euro_base") + b("german_mark_base") * mn("german_mark_base") +
    b("onemonth_horizon") * 0.125 + b("monthly_frequency") * 0.125 +
    b("number_of_currencies") * 0.027 + b("ols_method") * 0.076 + b("sur_method") * 0.049 +
    b("impact_factor") * 0.072 + b("citations") * 3.882 + b("firstdraft_year") * 10.253
}

## lincom, lines 726/727: Breedon et al. (2016) -- literal values copied from the do-file. The
## do-file writes onemonth_horizon twice (0.042 and 0.083), and for the Advanced row writes
## number_of_currencies twice (0 and 0.027); `lincom` sums repeated terms, so they are summed.
lincom_breedon <- function(cf, curr, advanced) {
  b <- function(nm) get_b(cf, nm)
  cons_of(cf) + b(curr) * mx(curr) +
    b("british_pound_base") * mn("british_pound_base") +
    b("euro_base") * mn("euro_base") + b("german_mark_base") * mn("german_mark_base") +
    b("onemonth_horizon") * (0.042 + 0.083) + b("oneyear_horizon") * 0.042 +
    b("monthly_frequency") * 0.167 +
    b("number_of_currencies") * (if (advanced) 0.027 else 0) +
    b("overlapping_problem") * 0.125 + b("ols_method") * 0.111 +
    b("impact_factor") * 0.138 + b("citations") * 3.882 + b("firstdraft_year") * 7.937
}

# ---- headline targets: the paper's BMA-based Table 5 -- not reproducible with the permitted
# wrapper set (see the note above). Recorded as NA on purpose, not approximated.
add("Headline_ImpliedBeta_Developed_Preferred_BMA", NA)         # paper: 0.309
add("Headline_ImpliedBeta_Developed_FrankelPoonawala_BMA", NA)  # paper: 0.448
add("Headline_ImpliedBeta_Developed_Breedon_BMA", NA)           # paper: 0.231
add("Headline_ImpliedBeta_Emerging_Preferred_BMA", NA)          # paper: 0.945
add("Headline_ImpliedBeta_Emerging_FrankelPoonawala_BMA", NA)   # paper: 1.164
add("Headline_ImpliedBeta_Emerging_Breedon_BMA", NA)            # paper: 0.947

# ---- corroborating context: the do-file's own non-BMA analog, Stata-verified above
add("Context_ImpliedBeta_Developed_Preferred_WLS",
    lincom_preferred(cf5_1, "advanced_currencies"))
add("Context_ImpliedBeta_Developed_FrankelPoonawala_WLS",
    lincom_fp(cf5_2, "advanced_currencies"))
add("Context_ImpliedBeta_Developed_Breedon_WLS",
    lincom_breedon(cf5_1, "advanced_currencies", TRUE))
add("Context_ImpliedBeta_Emerging_Preferred_WLS",
    lincom_preferred(cf5_1, "emerging_currencies"))
add("Context_ImpliedBeta_Emerging_FrankelPoonawala_WLS",
    lincom_fp(cf5_2, "emerging_currencies"))
add("Context_ImpliedBeta_Emerging_Breedon_WLS",
    lincom_breedon(cf5_1, "emerging_currencies", FALSE))

# --------------------------------------------------------------------------------- report
cat("=== Produced values ===\n")
for (nm in names(results)) {
  v <- results[[nm]]
  cat(sprintf("%-42s %s\n", nm, if (is.na(v)) "NA" else format(round(v, 4), nsmall = 4)))
}

writeLines(jsonlite::toJSON(results, auto_unbox = TRUE, digits = 10, na = "null"),
           "results.json")
