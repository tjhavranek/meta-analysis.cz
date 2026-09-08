# run.R -- replication of Havranek & Rusnak, "Transmission Lags of Monetary Policy:
# A Meta-Analysis", International Journal of Central Banking 9(4), 2013, pp. 39-75.
#
# The paper collects 198 estimates of the transmission lag -- the number of months after a
# monetary contraction at which the price level bottoms out -- from sixty-seven published VAR
# studies, and asks what explains their spread. Reproduced here:
#
#   Table 2   summary statistics of the transmission lag, for all impulse responses and
#             separately for the hump-shaped and the strictly decreasing ones
#   Table 3   average lag by country
#   Table 4   means and standard deviations of all thirty-three explanatory variables
#   Table 6   average lag by country, hump-shaped impulse responses only
#   Table 7   average lag by country, impulse responses without the price puzzle
#   Table 8   censored (Tobit) regression, specific model
#   Table 12  censored (Tobit) regression, general model, appendix 2
#
# Table 5 and figures 3-5 come from Bayesian model averaging run as an MCMC sampler over
# 2^33 models; those are not reproduced here and the reasons are recorded in targets.json
# and printed at the end of this script.
#
# Uses ONLY the wrappers in stata_compat.R. No feols/lm/rma/lmer/plm/ivreg/quantile call
# anywhere in this file.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/lags/replication/stata_compat.R")

suppressMessages(library(jsonlite))

results <- list()
add <- function(label, value) results[[label]] <<- as.numeric(value)

# ---------------------------------------------------------------------- data & construction
# The published lags.csv is the authors' source workbook: one row per estimate, repeated across
# seven horizon codes (3, 6, 12, 18, 36, 88 = peak, 99 = bottom), with the horizon-specific
# response and confidence band carried in fixed-name columns. The transmission lag is read off
# the bottom of the impulse response, so lags.do keeps horizon == 99 and works from there.
#
# Two things about the file need saying before any number is computed.
#
# First, the workbook exports each column under its DESCRIPTIVE HEADING where one exists, while
# lags.do refers to the short variable names. "GDPpc (PWC rgpch)" is gdppc, "domestic credit to
# private sector (% of GDP)" is findev, and so on. Three of the method dummies also carry names
# that describe the data-collection sheet rather than the regressor: meth_bay is the Bayesian-VAR
# dummy the paper calls BVAR, ir_svar is its non-recursive-identification dummy SVAR, and ir_sign
# is Sign Restrictions. The renaming below is one-to-one; every mapped column reproduces the
# corresponding series exactly.
#
# Second, several columns arrive as text, because the workbook writes an empty cell for some
# missing values and a literal "." for others. Read with both spellings declared as missing and
# coerce explicitly: a column left as character would be silently dropped from a regression, or
# would turn a summary statistic into NA, without any error being raised.
d <- read.csv(
  (if (file.exists("lags.csv")) "lags.csv" else
     "https://meta-analysis.cz/data/v1/lags/lags.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("NA", "", ".")
)

published_name <- c(
  "GDPpc (PWC rgpch)"                                    = "gdppc",
  "GDP growth (PWT grgdpch)"                             = "growth",
  "openness (PWT openk)"                                 = "open",
  "domestic credit to private sector (% of GDP)"         = "findev",
  "overall independence"                                 = "indep",
  "GDP deflator"                                         = "gdpdeflator",
  "recursiveIF"                                          = "if_repec",
  "CB"                                                   = "cb",
  "IMF_BIS_OECD"                                         = "imf_bis_oecd",
  "meth_bay"                                             = "bvar",
  "ir_svar"                                              = "svar",
  "ir_sign"                                              = "sign",
  "MBR"                                                  = "res"
)
# The inflation column's heading is a full sentence and is matched on its stem.
names(d)[startsWith(names(d), "inflation (IFS)")] <- "inf"
for (old in names(published_name)) {
  stopifnot(old %in% names(d))
  names(d)[names(d) == old] <- published_name[[old]]
}

numeric_cols <- c(
  "idstudy", "horizon", "lags", "mon_bot", "mon_peak", "no_bot", "freq", "syear", "eyear",
  "yearpub", "citations", "ministry", "imf_bis_oecd", "nobs", "end_variab", "gdppc", "growth",
  "inf", "findev", "open", "indep", "gdpdeflator", "single", "com", "money", "foreign",
  "trend", "seasonal", "ea_ip", "ea_gap", "ea_oth", "bvar", "favar", "svar", "sign",
  "if_repec", "native", "res"
)
for (v in numeric_cols) d[[v]] <- as.numeric(d[[v]])

# --------------------------------------------------------------------------- lags.do, cleaning
# lags.do lines 8-16, in the authors' order. The order is not incidental: the price-puzzle
# dummy is built BEFORE the lag is censored, so the seven impulse responses whose maximum
# decrease arrives after five years are compared against their true bottom rather than against
# the sixty-month limit. Reversing the two steps changes the dummy for those seven rows.
d <- st_keep_if(d, d$horizon == 99)
d <- st_drop_if(d, is.na(d$lags))

# "Lists studies in which the response is never negative" -- lags.do drops them, since a
# response that never falls has no month at which prices bottom out. mon_bot missing and
# mon_bot zero both mark that case.
d <- st_drop_if(d, is.na(d$mon_bot) | d$mon_bot == 0)

# The price puzzle is a rise in prices BEFORE the fall, so the peak has to come first. Stata
# treats a missing mon_peak as larger than any number, so an impulse response with no peak
# recorded fails the comparison and is coded zero; the same convention is written out here.
d$pricepuzzle <- as.numeric(!is.na(d$mon_peak) & d$mon_peak < d$mon_bot)

# Impulse responses are usually drawn over a five-year window, so a lag reported beyond it is
# an artefact of the reporting window rather than a longer transmission. lags.do censors at
# sixty months; seven observations are affected.
n_censored <- sum(d$mon_bot > 60)
d$mon_bot[d$mon_bot > 60] <- 60

# ------------------------------------------------------- lags.do, explanatory-variable recipes
d$monthly      <- as.numeric(!is.na(d$freq) & d$freq == 12)
d$avgyear      <- ((d$syear + d$eyear) / 2) - 2000
d$lagsf        <- d$lags / d$freq
d$studyage     <- 2010 - d$yearpub + 0.5
d$lncits       <- log(1 + d$citations / d$studyage)
d$yearpub      <- d$yearpub - 2000
d$policy       <- as.numeric((!is.na(d$ministry) & d$ministry == 1) |
                             (!is.na(d$imf_bis_oecd) & d$imf_bis_oecd == 1))
d$lnend_variab <- log(d$end_variab)
d$lnobs        <- log(d$nobs)
d$gdppc        <- log(d$gdppc)
d$findev       <- d$findev / 100
d$open         <- d$open / 100
d$inf          <- d$inf / 100

n_est     <- nrow(d)
n_studies <- length(unique(d$idstudy))
n_country <- length(unique(d$country))
cat(sprintf("Cleaned sample: %d estimates from %d studies covering %d countries\n",
            n_est, n_studies, n_country))
add("Primary studies in the sample", n_studies)
add("Countries covered", n_country)

# ------------------------------------------------------------------------------------ Table 2
# lags.do line 46: `bysort no_bot: sum mon_bot`. no_bot flags an impulse response whose maximum
# decrease falls in the last horizon shown, which is the paper's definition of strictly
# decreasing ("prices neither stabilize nor bounce back within the time frame reported by the
# authors ... so we label the last horizon as the transmission lag"). Its complement is the
# hump-shaped group. The split is 100 hump-shaped against 98 strictly decreasing, which is the
# division the paper states in section 2 and the one Table 4 records as a mean of 0.495.
#
# The price-puzzle dummy is a different cut of the same data and does NOT give this split: it
# divides the sample 105 to 93.
t2_rows <- list(
  "Estimates from all Impulse Responses"   = rep(TRUE, n_est),
  "Hump-Shaped Impulse Responses"          = d$no_bot == 0,
  "Strictly Decreasing Impulse Responses"  = d$no_bot == 1
)
cat("\n--- Table 2. Summary Statistics of the Estimated Transmission Lags ---\n")
cat(sprintf("%-40s %6s %9s %8s %10s %6s %6s\n",
            "Variable", "Obs.", "Mean", "Median", "Std. Dev.", "Min.", "Max."))
for (nm in names(t2_rows)) {
  x <- d$mon_bot[t2_rows[[nm]]]
  add(sprintf("Table 2 [%s]: Obs.", nm),       length(x))
  add(sprintf("Table 2 [%s]: Mean", nm),       mean(x))
  add(sprintf("Table 2 [%s]: Median", nm),     median(x))
  add(sprintf("Table 2 [%s]: Std. Dev.", nm),  sd(x))
  add(sprintf("Table 2 [%s]: Min.", nm),       min(x))
  add(sprintf("Table 2 [%s]: Max.", nm),       max(x))
  cat(sprintf("%-40s %6d %9.4f %8.1f %10.4f %6.0f %6.0f\n",
              nm, length(x), mean(x), median(x), sd(x), min(x), max(x)))
}

# ------------------------------------------------------------------------- Tables 3, 6 and 7
# The published script stops at the summaries it needs for the model averaging and never breaks
# the lag down by country, so these three tables have to be rebuilt from their notes. They say
# what the operation is: "the average number of months to the maximum decrease in prices taken
# from all the impulse responses reported for the corresponding country", over three samples --
# all impulse responses (table 3), the hump-shaped ones (table 6), and those without the price
# puzzle (table 7). Read literally that is a plain unweighted country mean of the cleaned
# sample, and it is worth checking rather than assuming, because the alternative reading -- a
# country average implied by the model-averaging exercise -- would look much the same in print.
# It is the literal one: every cell of all three tables follows from the data alone.
#
# Table 3 shows only the countries for which at least five impulse responses were collected,
# which is why twelve of the thirty appear. Tables 6 and 7 keep the same twelve rows on their
# smaller samples, so several of them rest on fewer than five estimates -- a caveat the paper
# makes itself, and the reason the per-cell counts are printed alongside the averages below.
#
# The paper prints countries by their full names; the data file abbreviates two of them.
country_label <- c("United States" = "US", "Euro Area" = "Euro Area", "Japan" = "Japan",
                   "Germany" = "Germany", "United Kingdom" = "UK", "France" = "France",
                   "Italy" = "Italy", "Poland" = "Poland",
                   "Czech Republic" = "Czech Republic", "Hungary" = "Hungary",
                   "Slovakia" = "Slovakia", "Slovenia" = "Slovenia")
country_tables <- list(
  "Table 3" = list(keep = rep(TRUE, n_est),   what = "all impulse responses"),
  "Table 6" = list(keep = d$no_bot == 0,      what = "hump-shaped impulse responses"),
  "Table 7" = list(keep = d$pricepuzzle == 0, what = "responses without the price puzzle")
)
for (tab in names(country_tables)) {
  spec <- country_tables[[tab]]
  cat(sprintf("\n--- %s. Average transmission lag by country (%s) ---\n", tab, spec$what))
  for (paper_name in names(country_label)) {
    sel <- spec$keep & d$country == country_label[[paper_name]]
    v <- mean(d$mon_bot[sel])
    add(sprintf("%s [%s]: Average Transmission Lag", tab, paper_name), v)
    cat(sprintf("  %-16s %8.4f   (n = %d)\n", paper_name, v, sum(sel)))
  }
}

# ------------------------------------------------------------------------------------ Table 4
# lags.do line 50 summarises the thirty-three candidate regressors. The order below is the
# order of that summarize command, which is also the order of the table.
explanatory <- list(
  c("gdppc", "GDP per Capita"),        c("growth", "GDP Growth"),
  c("inf", "Inflation"),               c("findev", "Financial Dev."),
  c("open", "Openness"),               c("indep", "CB Independence"),
  c("monthly", "Monthly"),             c("lnobs", "No. of Observations"),
  c("avgyear", "Average Year"),        c("gdpdeflator", "GDP Deflator"),
  c("single", "Single Regime"),        c("lagsf", "No. of Lags"),
  c("com", "Commodity Prices"),        c("money", "Money"),
  c("foreign", "Foreign Variables"),   c("trend", "Time Trend"),
  c("seasonal", "Seasonal"),           c("lnend_variab", "No. of Variables"),
  c("ea_ip", "Industrial Prod."),      c("ea_gap", "Output Gap"),
  c("ea_oth", "Other Measures"),       c("bvar", "BVAR"),
  c("favar", "FAVAR"),                 c("svar", "SVAR"),
  c("sign", "Sign Restrictions"),      c("no_bot", "Strictly Decreasing"),
  c("pricepuzzle", "Price Puzzle"),    c("lncits", "Study Citations"),
  c("if_repec", "Impact"),             c("cb", "Central Banker"),
  c("policy", "Policymaker"),          c("native", "Native"),
  c("yearpub", "Publication Year")
)
cat("\n--- Table 4. Description and Summary Statistics of Explanatory Variables ---\n")
for (e in explanatory) {
  v <- d[[e[1]]]
  stopifnot(!anyNA(v))
  add(sprintf("Table 4 [%s]: Mean", e[2]), mean(v))
  add(sprintf("Table 4 [%s]: Std. Dev.", e[2]), sd(v))
  cat(sprintf("  %-22s mean %10.5f   sd %10.5f\n", e[2], mean(v), sd(v)))
}

# --------------------------------------------------------------------------- Tables 8 and 12
# "The reporting window of primary studies is often set to five years, so we use sixty months
# as the upper limit and estimate the regression using the Tobit model." The censoring is the
# same operation applied to mon_bot above, so the 22 observations sitting at sixty months enter
# the likelihood as lower bounds rather than as observed lags. st_tobit is the wrapper for
# Stata's `tobit ..., ul(60)`; see stata_compat.R for the two conventions it pins down.
#
# Table 12 is the general model: every candidate regressor except Strictly Decreasing, which is
# left out because it is the variable that defines the censoring -- an impulse response is
# strictly decreasing precisely when its maximum decrease sits in the last horizon shown.
# Table 8 is the specific model reached from it by backward elimination at p = 0.1.
label_of <- c(gdppc = "GDP per Capita", growth = "GDP Growth", inf = "Inflation",
  findev = "Financial Dev.", open = "Openness", indep = "CB Independence",
  monthly = "Monthly", lnobs = "No. of Observations", avgyear = "Average Year",
  gdpdeflator = "GDP Deflator", single = "Single Regime", lagsf = "No. of Lags",
  com = "Commodity Prices", money = "Money", foreign = "Foreign Variables",
  trend = "Time Trend", seasonal = "Seasonal", lnend_variab = "No. of Variables",
  ea_ip = "Industrial Prod.", ea_gap = "Output Gap", ea_oth = "Other Measures",
  bvar = "BVAR", favar = "FAVAR", svar = "SVAR", sign = "Sign Restrictions",
  pricepuzzle = "Price Puzzle", lncits = "Study Citations", if_repec = "Impact",
  cb = "Central Banker", policy = "Policymaker", native = "Native",
  yearpub = "Publication Year", `(Intercept)` = "Constant")

report_tobit <- function(tab, model) {
  co <- st_coefs(model, z = FALSE)
  cat(sprintf("\n--- %s. Censored regression, upper limit 60 months ---\n", tab))
  cat(sprintf("    N = %d (%d uncensored, %d right-censored), sigma^2 = %.4f, log L = %.4f\n",
              nobs(model), model$n_uncensored, model$n_right, model$sigma^2, model$loglik))
  for (i in seq_len(nrow(co))) {
    nm <- label_of[[co$term[i]]]
    add(sprintf("%s [%s]: coef", tab, nm), co$estimate[i])
    add(sprintf("%s [%s]: se", tab, nm),   co$std.error[i])
    cat(sprintf("  %-22s %12.6f  (%10.6f)\n", nm, co$estimate[i], co$std.error[i]))
  }
  add(sprintf("%s: Observations", tab), nobs(model))
}

m_specific <- st_tobit(
  mon_bot ~ gdppc + pricepuzzle + inf + findev + open + indep + monthly + lnobs + policy,
  data = d, ul = 60)
report_tobit("Table 8", m_specific)

m_general <- st_tobit(
  mon_bot ~ gdppc + growth + inf + findev + open + indep + monthly + lnobs + avgyear +
    gdpdeflator + single + lagsf + com + money + foreign + trend + seasonal + lnend_variab +
    ea_ip + ea_gap + ea_oth + bvar + favar + svar + sign + pricepuzzle + lncits + if_repec +
    cb + policy + native + yearpub,
  data = d, ul = 60)
report_tobit("Table 12", m_general)

# ------------------------------------------------------------------- what is not reproduced
# Everything above follows from the data by arithmetic or by maximum likelihood. The paper's
# headline number does not, and nor do two further quantities its text reports. All three are
# recorded in targets.json with kind "not_reproduced" and no computed value, and the reasons
# are set out here so that a reader can see what stands behind each one.
#
# 1. THE BAYESIAN MODEL AVERAGING (Table 5, figures 3-5, and everything derived from them,
#    including the abstract's twenty-nine months). The averaging runs over 2^33 models, which
#    cannot be enumerated, so the authors sample the model space with an MCMC birth-death
#    chain -- 100 million burn-in and 200 million recorded draws. The posterior means are that
#    chain's output. Rerunning a chain here would produce a different set of numbers with the
#    same standing as the paper's, not a reproduction of them.
#
#    What can be checked without rerunning anything is the arithmetic the paper builds on top
#    of its own published posterior means. Section 3 defines an "ideal study": the sample
#    maximum for No. of Observations, Average Year, No. of Variables, Study Citations and
#    Impact; one for Single Regime, Commodity Prices, Foreign Variables, Seasonal, Output Gap,
#    BVAR and Sign Restrictions; zero for Industrial Prod., Other Measures, FAVAR and SVAR;
#    and the sample mean for everything else. Evaluating Table 5's printed posterior means at
#    those values is the check below.
bma_posterior_mean <- c(
  gdppc = -0.447, growth = 0.111, inf = -0.337, findev = 12.492, open = -0.056,
  indep = 13.370, monthly = -4.175, lnobs = -0.362, avgyear = 0.003, gdpdeflator = -0.052,
  single = 0.039, lagsf = 0.014, com = -0.009, money = -0.011, foreign = 0.039,
  trend = 3.681, seasonal = -0.004, lnend_variab = 0.036, ea_ip = 0.008, ea_gap = -1.464,
  ea_oth = 0.199, bvar = 0.337, favar = 0.304, svar = -0.468, sign = 0.954,
  no_bot = 26.122, pricepuzzle = 1.359, lncits = -0.005, if_repec = -0.305, cb = 0.075,
  policy = 0.858, native = -0.221, yearpub = 0.011)
bma_constant <- 7.271
best <- vapply(names(bma_posterior_mean), function(v) mean(d[[v]]), numeric(1))
for (v in c("lnobs", "avgyear", "lnend_variab", "lncits", "if_repec")) best[v] <- max(d[[v]])
for (v in c("single", "com", "foreign", "seasonal", "ea_gap", "bvar", "sign")) best[v] <- 1
for (v in c("ea_ip", "ea_oth", "favar", "svar")) best[v] <- 0
ideal_lag <- bma_constant + sum(bma_posterior_mean * best)
best_hump <- best; best_hump["no_bot"] <- 0
hump_lag <- bma_constant + sum(bma_posterior_mean * best_hump)

# 2. THE MAXIMUM DECREASE IN PRICES. The abstract puts it at 0.9 percent on average. The
#    normalised response at the bottom of the impulse response is the column the published file
#    calls MBR, which lags.do reads as `res`; the companion paper's script works with the same
#    series multiplied by 100 to put it in percentage points.
mean_max_decrease_pct <- mean(d$res) * 100

# 3. THE COUNT OF RESPONSES REACHING A 0.1 PERCENT DECREASE. Section 4 puts it at 173 of 198.
#    The response variable behind it -- the number of months to a 0.1 percent fall -- is a
#    separate series used for figure 5 and table 11 and is not among the published columns.
#    The closest thing the file supports is a count of the estimates whose maximum decrease
#    reaches that size at all.
n_reaching_point_one <- sum(d$res * 100 <= -0.1)

cat("\n===== Quantities NOT reproduced, and why =====\n")
cat("Bayesian model averaging (Table 5, figures 3-5, and the abstract's twenty-nine months):\n")
cat("  an MCMC chain over 2^33 models. Not rerun here; a fresh chain is not the paper's chain.\n")
cat("  Arithmetic on the paper's own printed posterior means, at its own definition of the\n")
cat(sprintf("  ideal study, gives %.3f months against a printed 29.2, and %.3f months\n",
            ideal_lag, hump_lag))
cat("  with Strictly Decreasing set to zero against a printed 16.3. Both round to the printed\n")
cat("  values, which also identifies the second one: the sentence about preferring hump-shaped\n")
cat("  responses refers to the baseline averaging of Table 5 with the shape dummy switched off,\n")
cat("  not to the separate hump-shaped-subsample estimation of figure 4.\n")
cat(sprintf("\nMaximum decrease in prices: the mean of the normalised response is %.4f percent,\n",
            mean_max_decrease_pct))
cat("  against 0.9 percent in the abstract.\n")
cat(sprintf("Estimates whose maximum decrease reaches 0.1 percent: %d, against 173 in section 4.\n",
            n_reaching_point_one))
cat("  No single scaling of the published response column delivers both printed figures, so\n")
cat("  the series the two sentences summarise is not the one the file carries.\n")

cat("\n===== Two Table 2 cells that do not follow from this sample =====\n")
cat(sprintf("  Mean of all impulse responses:      %.6f   paper 33.5\n",
            mean(d$mon_bot)))
cat(sprintf("  Std. dev. of hump-shaped responses: %.6f   paper 14.1\n",
            sd(d$mon_bot[d$no_bot == 0])))
cat("  The other sixteen cells reproduce, including all three counts, all three medians, both\n")
cat("  other standard deviations, and the hump-shaped mean, which is 18.150000 exactly and so\n")
cat("  is the 18.2 the paper prints once halves are rounded away from zero. Censoring at sixty\n")
cat("  months does not touch the hump-shaped subsample, whose maximum is 57, so the same 100\n")
cat("  values give both the reproduced and the unreproduced cell of that row.\n")
cat("\nOne further note on the published script: its comment at the censoring step reads\n")
cat(sprintf("  \"8 observations affected\", and the number affected in this data is %d.\n",
            n_censored))

write(toJSON(results, auto_unbox = TRUE, digits = 10), file = "results.json")
cat("\nWrote results.json\n\n")

stata_compat_log()
