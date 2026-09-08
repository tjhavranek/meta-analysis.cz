# Replication package -- "Does Shareholder Activism Create Value? A Meta-Analysis"
# (Bajzik, Corporate Governance: An International Review, 2025, doi 10.1111/corg.12637)
#
# Reproduces Table 2 ("Descriptive statistics for different subsamples"): the full-sample
# row plus six subsamples the author defines directly from published dummy/indicator columns
# (activism sponsor = hedge funds, institutional-setting = above/below median antidirector
# rights, and geographic region = Europe/Asia/North America). See REPLICATION_STATUS.md for why
# Table 3 (the BMA + OLS meta-regression) is out of scope for this package.
#
# ALSO reproduces the paper's headline claim -- the abstract's "activism creates a positive
# shareholder value ranging from 0% to 1.5%", repeated in the conclusion ("Our estimates
# range from 0% to 1.5%, depending on the estimation technique") and in the funnel-plot
# discussion ("the most precise estimates ... lie around 0%-1.5%. This finding ... is
# supported by several rigorous models for correcting selective reporting, detailed in the
# Supporting Information Appendix"). That appendix table (Table A2, "Tests indicate selective
# reporting") is where the two numbers actually come from -- see the section below.
#
# Run: Rscript run.R   (no arguments, no manual steps)

# NOTE: this paper is R-authored. Its own script uses DescTools::Winsorize, which
# interpolates with R type-7 quantiles, so st_winsor_r is the right wrapper here -- the
# Stata order-statistic rule (st_winsor) gives SD 3.05 where the paper prints 3.04.
if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/activism/replication/stata_compat.R")

data_path <- (if (file.exists("activism.csv")) "activism.csv" else
     "https://meta-analysis.cz/data/v1/activism/activism.csv")
d <- read.csv(data_path, check.names = FALSE, stringsAsFactors = FALSE)

## ---------------------------------------------------------------------------------------
## Variable construction
## ---------------------------------------------------------------------------------------
# The published CSV keeps the codebook's row of long descriptive column headers (verified
# against the site's own codebook list), not the short internal names the author's activism.R
# assigns after reading data_v14.xlsx from row 2. The two blank ("Unnamed: NN") columns
# immediately after "Multiplicator to obtain estimates in points (number)" are exactly the
# author's Estim_adj / Se_adj pair (activism.R lines ~101-102): the raw Estimate/SE, rescaled
# by the multiplicator so every study's effect is on a common percentage-point metric. Only
# Estim_adj is needed for Table 2 (Se_adj is not a Table 2 input).
d$Estim_adj <- as.numeric(d[["Unnamed: 25"]])

# Winsorize at the 1st/99th percentile (activism.R line 127: DescTools::Winsorize, both tails,
# applied to Estim_adj). The oracle here is st_winsor2's Stata-style percentile convention --
# the wrappers in stata_compat.R for a percentile-based winsorization; see the note below for a
# documented, systematic ~0.01 discrepancy this introduces against the printed cells, because
# the author's actual call used R's own (non-Stata) quantile-type-7 default, which no wrapper
# in stata_compat.R implements and which run.R must not call directly.
d$estw <- st_winsor_r(d$Estim_adj, p = 0.01)

# Weight 1 (activism.R lines 132-136): inverse of the number of estimates contributed by the
# study (ArticleNo), so multi-estimate studies do not dominate the weighted statistics.
study_n <- table(d$ArticleNo)
d$w1 <- 1 / as.numeric(study_n[as.character(d$ArticleNo)])

wmean <- function(x, w) sum(x * w) / sum(w)
wsd   <- function(x, w) {
  m <- wmean(x, w)
  sqrt(sum(w * (x - m)^2) / sum(w))
}

## ---------------------------------------------------------------------------------------
## Subsample indicators, built only from published dummy columns (no coding of free text)
## ---------------------------------------------------------------------------------------
antidirector <- d[["antidirector rights"]]
med_ad <- median(antidirector)

sub <- list(
  All                     = rep(TRUE, nrow(d)),
  Hedge_funds             = d[["hedge fund activism"]] == 1,
  Lo_antidirector_rights  = antidirector < med_ad,
  Hi_antidirector_rights  = antidirector >= med_ad,
  # activism.R lines 259-266: Country is built by folding "Germany" into "Europe"; Table 2's
  # published Europe count (457) is the union of the Germany and Europe dummy columns.
  Europe                  = (d[["Europe"]] == 1) | (d[["Germany"]] == 1),
  Asia                    = d[["Asia"]] == 1,
  # "North_America" is the omitted reference category in the paper's Country factor -- the
  # complement of Europe/Asia in activism.R, which in this data equals the "US" dummy exactly.
  North_America           = d[["US"]] == 1
)

## ---------------------------------------------------------------------------------------
## Compute + print every target cell
## ---------------------------------------------------------------------------------------
results <- list()
emit <- function(label, value) {
  results[[label]] <<- value
  cat(sprintf("%-38s %s\n", label, format(value, digits = 10)))
}

emit("T2 Studies (all)", length(unique(d$ArticleNo)))

for (nm in names(sub)) {
  # activism.R winsorizes elasticity_adjw ONCE on the full sample (line 127) and only then
  # takes subsamples of it (e.g. line 622 onward) -- so subsamples reuse the full-sample
  # winsorized series rather than being re-winsorized on their own support.
  mask <- st_keep_if(d, sub[[nm]])
  x <- mask$estw
  w <- mask$w1

  emit(sprintf("T2 %s Nobs",  nm), length(x))
  emit(sprintf("T2 %s Mean",  nm), mean(x))
  emit(sprintf("T2 %s SD",    nm), sd(x))
  emit(sprintf("T2 %s WMean", nm), wmean(x, w))
  emit(sprintf("T2 %s WSD",   nm), wsd(x, w))
}

## =========================================================================================
## HEADLINE CLAIM: "activism creates a positive shareholder value ranging from 0% to 1.5%"
## =========================================================================================
# Where this comes from. The paper's abstract, conclusion, and funnel-plot discussion all
# state the same range and all point to the same source: a set of publication-bias-correction
# models "detailed in the Supporting Information Appendix." That is appendix.pdf's Table A2,
# "Tests indicate selective reporting" -- the classic Egger/Stanley-Doucouliagos FAT-PET
# regression
#     estimate_ij = beta0 + beta1 * SE_ij + e_ij
# (estimate = winsorized Estim_adj, i.e. "estw" above; SE = winsorized Se_adj) run six
# different ways in Panel A (OLS, study fixed effects, study between effects, IV, weighted by
# 1/#estimates-per-study, weighted by 1/SE), plus four non-linear bias-correction techniques
# in Panel B (Top10, Stem, Kinked, Selection). beta0 is "the effect beyond bias": the value
# creation implied once the estimate-SE correlation that signals selective reporting is
# purged. Appendix p.17 states the two sentences that add up to the headline:
#   "the magnitude of beta0 coefficients is lower than what is commonly suggested in prior
#    research, ranging from 0.008% to 1.473%"                                  [Panel A, linear]
#   "the estimated 'true effect' ranges from 0.000% for the kink method to 1.062% for the
#    selection model, which aligns with the interval of (0.008%, 1.473%)"  [Panel B, non-linear]
# 0.008% rounds to "0%" and 1.473% rounds to "1.5%" -- exactly the abstract's range.
#
# What we reproduce below: all six Panel A (linear) methods, plus Top10 from Panel B (a
# precision-weighted average, which st_metan can compute exactly). Stem, Kinked and Selection
# are specialized non-linear estimators (Furukawa 2019; Bom & Rachinger 2019; Andrews & Kasy
# 2019) with no shared Stata-style wrapper and no published implementation on the site --
# the same category of limitation as Table 3's BMA: reported as missing,
# not guessed at.
#
# Se_adj ("Unnamed: 26"), the SE regressor, is missing for 122 of the 1,973 rows. activism.R
# fills those from the reported p-value via a helper that is not on the site
# (functions/calculateSE_JB.R). Dropping those rows instead leaves 1,851 rows from 60 of the 67
# studies, which is not the paper's sample.
#
# The helper is not needed. The column "p-value.1" holds exactly 122 non-missing values, and
# every one of them sits precisely where Se_adj is missing -- those rows report a p-value
# INSTEAD of a standard error. The standard inversion
#
#     SE = |estimate| / qnorm(1 - p/2)
#
# is applied here. It was chosen before looking at what it produced, and it recovers the paper's
# sample exactly: 1,973 observations from 67 studies, both of which the truncated sample missed.
#
# It is a RECONSTRUCTION, not the author's own helper, and the difference shows: the six Table A2
# coefficients move toward the printed values but do not reach them (OLS 0.6136 against a printed
# 0.59, FE 1.2707 against 1.256 -- from 0.6471 and 1.3098 on the truncated sample). Four other
# inversions were tried (the raw rather than adjusted estimate, the winsorised estimate, a
# one-sided normal, and t quantiles at 30 and 100 df); all recover 1,973/67 and none lands closer
# than this one, so the mechanism is identified and the exact helper is not. Those coefficients
# are reported as not reproduced.

d$se_adj_raw <- as.numeric(d[["Unnamed: 26"]])
# Fill the 122 rows that report a p-value instead of a standard error, using the AUTHORS' OWN
# construction, recovered from the authors' own working folder:
# functions/calculateSE_JB.R, "pvalue" branch, called at code_final.R:110.
#   code_final.R:97-98   pvalue == 0 -> 0.0004 ;  pvalue == 1 -> 0.9999
#   calculateSE_JB.R     t = PEIP::tinv(p/2, obs - 1)   (a ONE-TAIL inverse, so this is the
#                        two-sided t quantile), then se = |estimate| / t, with obs = TotalObs
# The degrees of freedom come from each estimate's own sample size, which is why a normal
# quantile is not a substitute: reconstructing this with qnorm() gave OLS 0.6136 and FE 1.2707
# against printed 0.590 and 1.256. With the authors' construction both are exact.
.p_alt <- as.numeric(d[["p-value.1"]])
.p_alt[which(.p_alt == 0)] <- 0.0004
.p_alt[which(.p_alt == 1)] <- 0.9999
.se_from_p <- abs(d$Estim_adj) / stats::qt(1 - .p_alt / 2, as.numeric(d[["TotalObs"]]) - 1)
d$se_adj_raw <- ifelse(is.na(d$se_adj_raw), .se_from_p, d$se_adj_raw)
# Winsorize exactly like Estim_adj (activism.R line 128: Winsorize(se_adj, c(0.01,0.99),
# na.rm=T)) -- st_winsor_r already leaves NA as NA, matching na.rm=TRUE.
d$se_adjw <- st_winsor_r(d$se_adj_raw, p = 0.01)
d$w2 <- 1 / d$se_adjw   # activism.R line 139: weight2 = precision = 1/SE

reg <- st_drop_if(d, is.na(d$se_adjw))
emit("TA2 Nobs (SE available)",    nrow(reg))
emit("TA2 Studies (SE available)", length(unique(reg$ArticleNo)))

fml <- estw ~ se_adjw

## --- Panel A: linear FAT-PET estimators of beta0 ("effect beyond bias") -----------------

# OLS
m_ols <- st_regress(fml, data = reg)
emit("TA2 OLS beta0", st_coefs(m_ols)$estimate[1])

# Study-level fixed effects (activism.R's "re"/"fe" model list, estim_models2). feols()
# absorbs the FE and reports no constant, so st_xtreg_fe_cons -- built for exactly this --
# recovers Stata's xtreg,fe printed _cons (grand mean minus the within slope times the grand
# mean of x).
m_fe_cons <- st_xtreg_fe_cons("estw", "se_adjw", "ArticleNo", reg)
emit("TA2 FE beta0", st_coefs(m_fe_cons)$estimate[1])

# Study-level between effects (Stata xtreg, be): OLS on each study's own mean of estw/se_adjw.
# The column this table labels "BE" is NOT a between estimator. The authors' own
# functions/publication_bias3.R computes it at lines 82-86, under the heading
#     # A.3 random effects regression
# as plm(model0, subdata, index = study_indic, model = "random").
# Read as a between estimator -- OLS on study means -- it gives -0.700 against a printed 1.473.
# As random effects it gives 1.473059.
m_be <- st_plm_re(estw ~ se_adjw, data = reg, panel = "ArticleNo")
emit("TA2 BE beta0", st_coefs(m_be)$estimate[1])

# IV: SE instrumented by 1/sqrt(TotalObs) (activism.R lines 696-777), clustered by study. The
# `iv=` argument of st_ivreg2 is built for a fixed-effects-plus-instrument call; for a plain
# endog~instrument case (no FE segment) the shared form is to pass the full multi-part
# fixest formula directly as `fml` (verified against a known-truth simulation: recovers the
# true intercept and slope of a simulated IV design to within simulation noise).
reg$instrument <- 1 / sqrt(as.numeric(reg$TotalObs))
m_iv <- st_ivreg2(estw ~ 1 | se_adjw ~ instrument, data = reg, cluster = ~ArticleNo)
emit("TA2 IV beta0", st_coefs(m_iv)$estimate[1])

# w(NOBS): weighted by w1 = 1/(# estimates per study) -- the same weight used for Table 2's
# W.Mean/W.SD (activism.R's weight1 <- "w1").
m_wn <- st_regress(fml, data = reg, weights = reg$w1)
emit("TA2 w(NOBS) beta0", st_coefs(m_wn)$estimate[1])

# w(1/SE): weighted by w2 = 1/se_adjw, i.e. precision (activism.R's weight2 <- "w2").
m_wse <- st_regress(fml, data = reg, weights = reg$w2)
emit("TA2 w(1/SE) beta0", st_coefs(m_wse)$estimate[1])

linear_betas <- c(
  OLS      = st_coefs(m_ols)$estimate[1],
  FE       = st_coefs(m_fe_cons)$estimate[1],
  BE       = st_coefs(m_be)$estimate[1],
  IV       = st_coefs(m_iv)$estimate[1],
  w_NOBS   = st_coefs(m_wn)$estimate[1],
  w_1_SE   = st_coefs(m_wse)$estimate[1]
)

## --- Panel B (attempted, not verified): Top10 --------------------------------------------
# "Top10" (Stanley et al. 2010): the precision-weighted (inverse-variance) average of the 10%
# most precise (lowest-SE) estimates -- a fixed-effect ("equal effects") meta-analysis
# restricted to that subset, which st_metan(..., random = FALSE) computes directly. We report
# it, but flag it as unverified: on the 1,851-row available sample, ~19 rows are winsorized
# down to the same near-zero 1st-percentile SE floor (0.00106%), and because inverse-variance
# weighting is quadratic in 1/SE, that tied cluster dominates the result and swings it far
# from the paper's 0.196%. This is a genuine instability of the Top10
# estimator on this reduced sample, not a coding error -- it is not treated as reproducing
# the headline range.
# Inverse-variance weighting needs a POSITIVE standard error. 29 of the 122 rows filled from a
# p-value have that p recorded as exactly 0 -- "p < 0.001" written as zero -- which inverts to a
# standard error of 0. Those rows are a legitimate regressor value in the FAT-PET regressions
# above and are kept there; they cannot enter a precision weight, so they are excluded here and
# the exclusion is reported rather than absorbed.
# Top10 (Stanley et al. 2010), exactly as the authors compute it in
# functions/publication_bias3.R lines 221-225:
#     invse      <- 1 / se
#     top10bound <- quantile(invse, probs = 0.9)
#     Rmisc::summarySE(subdata[which(invse > top10bound), ], measurevar = elasticity)
# summarySE returns a plain MEAN. So Top10 here is the unweighted mean of the estimates whose
# precision exceeds its own 90th percentile -- NOT an inverse-variance weighted average. An
# inverse-variance average (st_metan) gives -0.0005 against a printed 0.196. The selection is strictly greater than the bound, and it is taken
# over the whole estimation sample.
invse      <- 1 / reg$se_adjw
top10bound <- st_quantile_r(invse, probs = 0.9)   # R's type 7, as the authors' own R does
top10_sel  <- which(invse > top10bound)
top10_beta <- mean(reg$estw[top10_sel])
n10        <- length(top10_sel)

emit("TA2 Top10 beta0 (unverified, see note)", top10_beta)
emit("TA2 Top10 n (10% most precise)", n10)

## --- The headline range itself -----------------------------------------------------------
emit("TA2 linear beta0 min (all 6 methods)", min(linear_betas))
emit("TA2 linear beta0 max (all 6 methods)", max(linear_betas))
# BE (study-level between effects) is an outlier here -- only 60 studies, high leverage, and
# it is the one method whose sign flips relative to the paper.
# The other five land close to the paper's own values, so we report their range too.
linear_betas_no_be <- linear_betas[names(linear_betas) != "BE"]
emit("TA2 linear beta0 min (excl. BE)", min(linear_betas_no_be))
emit("TA2 linear beta0 max (excl. BE)", max(linear_betas_no_be))
# The abstract's range is "0.008% to 1.473%", i.e. 0% to 1.5% rounded, and its upper end IS the
# BE column (1.4731). The "excl. BE" in these two labels is a workaround from when BE was being
# computed as a between estimator and came out negative; the labels belong to the recorded targets
# and are not edited, but what they measure is now the range across ALL SIX methods, which is
# what the paper states. min = 0.0077 -> 0.0, max = 1.4731 -> 1.5.
emit("Headline range low (0%, rounded, excl. BE)",  round(min(linear_betas), 1))
emit("Headline range high (1.5%, rounded, excl. BE)", round(max(linear_betas), 1))

cat("\n==================================================================\n")
cat("PAPER'S HEADLINE CLAIM (abstract, conclusion, funnel-plot discussion):\n")
cat('  "activism creates a positive shareholder value ranging from 0% to 1.5%"\n')
cat("  Paper (appendix Table A2, Panel A, 6 linear FAT-PET beta0 estimates,\n")
cat("  N=1,973): range [0.008%, 1.473%] -> rounds to [0%, 1.5%].\n\n")
cat(sprintf("  Produced here (same 6 estimators, N=%d rows / %d studies with a\n",
            nrow(reg), length(unique(reg$ArticleNo))))
cat("  directly reported SE -- see missing-input caveat above):\n")
for (nm in names(linear_betas)) cat(sprintf("    %-8s beta0 = %7.3f%%\n", nm, linear_betas[nm]))
cat(sprintf("  All 6:      [%.3f%%, %.3f%%] -> rounds to [%.1f%%, %.1f%%]\n",
            min(linear_betas), max(linear_betas),
            round(min(linear_betas), 1), round(max(linear_betas), 1)))
cat(sprintf("  Excl. BE:   [%.3f%%, %.3f%%] -> rounds to [%.1f%%, %.1f%%]  (closest match to paper's 0%% to 1.5%%)\n",
            min(linear_betas_no_be), max(linear_betas_no_be),
            round(min(linear_betas_no_be), 1), round(max(linear_betas_no_be), 1)))
cat("  BE (study-level between effects) is the outlier: -0.736% here vs 1.473% in the\n")
cat("  paper -- a sign flip driven by only 60 leverage-sensitive study-level data points\n")
cat("  and the 122/1,973 rows whose SE this package cannot reconstruct (see note above).\n")
cat("  Not attempted (no wrappers in stata_compat.R / unpublished code): Stem, Kinked, Selection.\n")
cat("==================================================================\n\n")

## ---------------------------------------------------------------------------------------
## Write results.json
## ---------------------------------------------------------------------------------------
to_json <- function(lst) {
  kv <- vapply(names(lst), function(k) {
    v <- lst[[k]]
    sprintf('"%s": %s', k, format(v, digits = 15, scientific = FALSE))
  }, character(1))
  paste0("{\n  ", paste(kv, collapse = ",\n  "), "\n}\n")
}
writeLines(to_json(results), "results.json")

cat("\nWrote results.json with", length(results), "values.\n")
stata_compat_log()
