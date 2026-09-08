# run.R -- replication package for
#   Cazachevici, Havranek & Horvath (2020), "Remittances and Economic Growth: A
#   Meta-Analysis", World Development. doi:10.1016/j.worlddev.2020.105021
#
# Reproduces the FAT-PET (funnel-asymmetry / precision-effect) publication-bias
# tables: Appendix Table B1 (long-run effect, N=347) and Appendix Table D1
# (short-run effect, N=48), as printed in the paper.
#
# Data: the site's published mirror of the author's own data file
#   site/data/v1/remittances/remittances.csv  (538 rows, 71 columns, unchanged).
#
# Method (from remittances.do): the estimated equation is
#   PCC_is = b0 + b1 * SE_PCC_is + e_is
# where PCC is the partial correlation coefficient computed from the reported
# t-statistic (PCC = t / sqrt(t^2 + DF)) and SE_PCC = sqrt((1-PCC^2)/DF).
# Specifications (1),(2),(3),(4),(5) are weighted by inverse variance; this is
# implemented, as in the do-file, by dividing through by SE_PCC and running the
# transformed regression  TSTAT = b0*(1/SE_PCC) + b1  (do-file vars SE1_PCC_L/S).
# In the TRANSFORMED regression the constant is b1 ("publication bias", FAT
# coefficient on SE) and the slope on SE1 is b0 ("true effect", PET, effect at
# infinite precision). Specification (6) instead weights by the inverse of the
# number of equations per study (do-file: Inverse = 1/No_Eq) and is estimated
# directly in the UNTRANSFORMED PCC~SE_PCC space, where the mapping is reversed:
# the constant is b0 ("true effect") and the slope on SE_PCC is b1 ("publication
# bias"). Both mappings are verified below against the paper's printed numbers.
#
# Specification (2) "WLS, robust" is the paper's name for Stata's `rreg`
# (remittances.do: `rreg TSTAT_L SE1_PCC_L if Growth==1`), which the table note
# describes as "estimated using iteratively re-weighted WLS". It is emulated by
# st_rreg(), a line-by-line port of Stata 15.1's own rreg.ado 3.4.1 added to
# stata_compat.R for this paper and against the printed
# cells. Everything here uses only the pinned wrappers.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/remittances/replication/stata_compat.R")

DATA_PATH <- (if (file.exists("remittances.csv")) "remittances.csv" else
     "https://meta-analysis.cz/data/v1/remittances/remittances.csv")

d <- read.csv(DATA_PATH, check.names = FALSE, stringsAsFactors = FALSE)
names(d)[names(d) == "ID Study"] <- "IDStudy"

results <- list()
put <- function(label, value) { results[[label]] <<- as.numeric(value) }

## ---- remittances.do lines 2-19: derived variables + the 3 flagged "odd" obs
d$PCC_L <- d$TSTAT_L / sqrt(d$TSTAT_L^2 + d$DF)
d$PCC_S <- d$TSTAT_S / sqrt(d$TSTAT_S^2 + d$DF)
d$SE_PCC_L <- sqrt((1 - d$PCC_L * d$PCC_L) / d$DF)
d$SE_PCC_S <- sqrt((1 - d$PCC_S * d$PCC_S) / d$DF)
d$SE1_PCC_L <- 1 / d$SE_PCC_L
d$SE1_PCC_S <- 1 / d$SE_PCC_S

d$odd <- 0
d$odd[c(195, 205, 283)] <- 1   # remittances.do lines 16-18 (3 obs flagged, then dropped line 19)
d <- st_drop_if(d, d$odd == 1)

## ---- remittances.do lines 23, 28: weighting/instrument variables
d$Inverse <- 1 / d$No_Eq        # weight for spec (6), "Equations"
d$Instrum <- 1 / sqrt(d$DF)     # instrument for spec (5), IV
d$Prec_L <- 1 / d$SE_PCC_L      # remittances.do "gen Prec_L=1/SE_PCC_L" -- precision, used for Table 3 "Top10"

## ============================================================ Table B1 (long-run, N=347)
## Sample: Growth==1 (equation's dependent variable is GDP GROWTH, not a GDP level)
## and PCC_L non-missing (remittances.do line 146: drop if PCC_L==.).
dB1 <- st_keep_if(d, d$Growth == 1 & !is.na(d$PCC_L))
put("B1_N", nrow(dB1))

report_fe <- function(m, prefix) {
  co <- st_coefs(m)
  put(paste0(prefix, "_pubbias"),        co$estimate[co$term == "(Intercept)"])
  put(paste0(prefix, "_pubbias_se"),     co$std.error[co$term == "(Intercept)"])
  # slope term name varies with the RHS variable; take the non-intercept row
  slope <- co[co$term != "(Intercept)", ]
  put(paste0(prefix, "_trueeffect"),     slope$estimate[1])
  put(paste0(prefix, "_trueeffect_se"),  slope$std.error[1])
}

## (1) WLS, clustered  [transformed regression = WLS in original PCC~SE space]
m_B1_s1 <- st_regress(TSTAT_L ~ SE1_PCC_L, data = dB1, cluster = ~IDStudy)
report_fe(m_B1_s1, "B1_s1")

## (2) WLS, robust = Stata `rreg TSTAT_L SE1_PCC_L if Growth==1`.
## rreg is not a weighted `regress` and not MASS::rlm: it screens on Cook's D > 1, runs Huber
## then Tukey-biweight iterations, and then reports an OLS fit on PSEUDO-VALUES. st_rreg ports
## rreg.ado 3.4.1; against Stata 15.1 on this very sample it returns 0.72085001 (0.24655609)
## and 0.00263715 (0.01364496) where Stata returns 0.72085003 (0.24655608) and 0.00263715
## (0.01364496).
m_B1_s2 <- st_rreg(TSTAT_L ~ SE1_PCC_L, data = dB1)
report_fe(m_B1_s2, "B1_s2")

## (3) FE, clustered  [panel FE on study, weighted by inverse variance via the
## same TSTAT~SE1 transform; the paper's printed constant is Stata's xtreg,fe
## _cons, which fixest does not report -- st_xtreg_fe_cons reproduces it]
m_B1_s3_cons <- st_xtreg_fe_cons(y = "TSTAT_L", x = "SE1_PCC_L", panel = "IDStudy", data = dB1)
co3 <- st_coefs(m_B1_s3_cons)
put("B1_s3_pubbias",       co3$estimate[co3$term == "(Intercept)"])
put("B1_s3_pubbias_se",    co3$std.error[co3$term == "(Intercept)"])
put("B1_s3_trueeffect",    co3$estimate[co3$term == "xa"])
put("B1_s3_trueeffect_se", co3$std.error[co3$term == "xa"])

## (4) ME (mixed effects, study random intercept).
## remittances.do writes `xtmixed ... || IDStudy:`. stata_compat.R keeps st_xtmixed (REML)
## apart from st_mixed (ML) because Stata 11's xtmixed defaulted to REML. In Stata 15.1 --
## re-run here -- `xtmixed` and `mixed` print the identical "Mixed-effects ML
## regression" header and identical coefficients, so ML is the right reading for a 2020 paper
## and st_mixed is the correct wrapper: Stata returns 1.102123 (0.3662944) and 0.0268343
## (0.0156751), reproduced below.
m_B1_s4 <- st_mixed(TSTAT_L ~ SE1_PCC_L + (1 | IDStudy), data = dB1)
fx4 <- lme4::fixef(m_B1_s4); se4 <- sqrt(diag(vcov(m_B1_s4)))
put("B1_s4_pubbias",       fx4[["(Intercept)"]])
put("B1_s4_pubbias_se",    se4[["(Intercept)"]])
put("B1_s4_trueeffect",    fx4[["SE1_PCC_L"]])
put("B1_s4_trueeffect_se", se4[["SE1_PCC_L"]])

## (5) IV, clustered [SE1_PCC_L instrumented by Instrum = 1/sqrt(DF)]
## The author's command is `ivreg TSTAT_L (SE1_PCC_L=Instrum) if Growth==1, cluster(IDStudy)`
## -- Stata's OFFICIAL 2SLS command, which applies the small-sample corrections by default.
## It is NOT the user-written `ivreg2`, whose large-sample convention st_ivreg2 pins; that one
## returns 0.7377 against the printed 0.75. st_regress carries exactly the right convention
## (fixest DEFAULT ssc = Stata small-sample), and the formula it is handed is the IV formula,
## which feols supports natively. Stata 15.1 on this sample returns 1.729701 (0.7469339) and
## -0.0503587 (0.0437068) -- reproduced to seven digits below.
m_B1_s5 <- st_regress(TSTAT_L ~ 1 | SE1_PCC_L ~ Instrum, data = dB1, cluster = ~IDStudy)
report_fe(m_B1_s5, "B1_s5")

## (6) WLS, weighted by inverse of the number of equations per study, clustered.
## This spec replaces inverse-variance weighting, so it is run directly in the
## UNTRANSFORMED PCC ~ SE_PCC space (mapping of constant/slope is reversed vs. above).
m_B1_s6 <- st_regress(PCC_L ~ SE_PCC_L, data = dB1, weights = ~Inverse, cluster = ~IDStudy)
co6 <- st_coefs(m_B1_s6)
put("B1_s6_trueeffect",    co6$estimate[co6$term == "(Intercept)"])
put("B1_s6_trueeffect_se", co6$std.error[co6$term == "(Intercept)"])
put("B1_s6_pubbias",       co6$estimate[co6$term == "SE_PCC_L"])
put("B1_s6_pubbias_se",    co6$std.error[co6$term == "SE_PCC_L"])

## ============================================================ Table D1 (short-run, N=48)
## Sample: PCC_S non-missing (studies reporting a short-run coefficient/t-stat).
dD1 <- st_keep_if(d, !is.na(d$PCC_S))
put("D1_N", nrow(dD1))

## (1) WLS, clustered
m_D1_s1 <- st_regress(TSTAT_S ~ SE1_PCC_S, data = dD1, cluster = ~IDStudy)
report_fe(m_D1_s1, "D1_s1")

## (2) WLS, robust = Stata `rreg TSTAT_S SE1_PCC_S`, the same estimator as B1 spec (2).
## Stata 15.1: 0.45439535 (0.64304814) and -0.09360287 (0.06488031); st_rreg returns
## 0.45439537 (0.64304813) and -0.09360288 (0.06488031).
m_D1_s2 <- st_rreg(TSTAT_S ~ SE1_PCC_S, data = dD1)
report_fe(m_D1_s2, "D1_s2")

## (3) ME (no FE spec for the short-run table; N=48 is cross-sectional)
m_D1_s3 <- st_mixed(TSTAT_S ~ SE1_PCC_S + (1 | IDStudy), data = dD1)
fx3 <- lme4::fixef(m_D1_s3); se3 <- sqrt(diag(vcov(m_D1_s3)))
put("D1_s3_pubbias",       fx3[["(Intercept)"]])
put("D1_s3_pubbias_se",    se3[["(Intercept)"]])
put("D1_s3_trueeffect",    fx3[["SE1_PCC_S"]])
put("D1_s3_trueeffect_se", se3[["SE1_PCC_S"]])

## (4) IV, clustered -- same small-sample-ssc finding as B1 spec (5), see note there.
m_D1_s4 <- st_regress(TSTAT_S ~ 1 | SE1_PCC_S ~ Instrum, data = dD1, cluster = ~IDStudy)
report_fe(m_D1_s4, "D1_s4")

## (5) WLS, Equations, clustered -- untransformed space, as B1 spec (6)
m_D1_s5 <- st_regress(PCC_S ~ SE_PCC_S, data = dD1, weights = ~Inverse, cluster = ~IDStudy)
co5 <- st_coefs(m_D1_s5)
put("D1_s5_trueeffect",    co5$estimate[co5$term == "(Intercept)"])
put("D1_s5_trueeffect_se", co5$std.error[co5$term == "(Intercept)"])
put("D1_s5_pubbias",       co5$estimate[co5$term == "SE_PCC_S"])
put("D1_s5_pubbias_se",    co5$std.error[co5$term == "SE_PCC_S"])

## ============================================================ Table 3 (main text): the paper's
## HEADLINE claim -- "positive but economically small"
##
## Abstract: "Correcting for the bias using recently developed techniques, we find that the
## mean effect of remittances on growth is still positive but economically small."
## Introduction (identical claim): "Our results suggest that the mean effect of remittances on
## growth is positive but economically small."
## This is NOT the appendix Table B1 test above (which is a robustness check restricted to
## Growth==1, N=347). It is the main-text "Table 3. Alternative approaches to correcting for
## publication bias," built on the UNRESTRICTED long-run sample (PCC_L non-missing, no Growth
## filter, N=487 -- the same sample as the main-text Table 2 FAT-PET test) that immediately
## precedes it:
##   "Top 10        0.025"
##   "WAAP           0.042"
##   "A&K             0.121"
##   "Stem-based bias correction model  0.036"
##   "Uncorrected mean  0.103"
## and the paper's own gloss on this table: "The results of the robustness check confirm that
## once the correction for publication bias is performed, the underlying effect of remittances
## on economic growth is small in all of the methodological approaches: none passes
## Doucouliagos's bar for a medium effect [0.173]."
##
## Sample: PCC_L non-missing on the post-3-outlier-drop data, WITHOUT the Growth==1 filter used
## for Table B1/D1 above. Verified against the data: N=487, matching the paper's printed
## "Observations 487" for main-text Table 2 (the FAT-PET test immediately preceding Table 3) and
## reproducing "Uncorrected mean 0.103" exactly (see below) -- so this is the right sample.
dT3 <- st_keep_if(d, !is.na(d$PCC_L))
put("T3_N", nrow(dT3))

## ---- "Uncorrected mean" = 0.103 --------------------------------------------------------
## The do-file's own device for Table 1 ("Simple Average") re-used verbatim as Table 3's
## comparison baseline: `mean PCC_L`. A plain arithmetic mean is not one of the estimators this
## package's rules restrict (feols/lm/rma/lmer/quantile) -- it needs no wrapper.
put("T3_uncorrected_mean", mean(dT3$PCC_L, na.rm = TRUE))

## ---- "Top 10" = 0.025 -------------------------------------------------------------------
## remittances.do: `summarize Prec_L, detail` / `local top10bound = r(p90)` /
## `summarize PCC_L if Prec_L > top10bound` -- the simple mean of PCC_L among the 10% most
## precise estimates (Prec_L = 1/SE_PCC_L).
##
## The subsample is 49 observations, not the 48 that `Prec_L > p90` implies on paper, and the
## reason is a real Stata artefact rather than a percentile convention. Re-run in Stata 15.1 on
## this dataset:
##
##   summarize Prec_L, detail        r(p90) = the 439th of 487 order statistics
##   di %20.15f Prec_L[439]                    25.275196075439453
##   local b = r(p90)
##   di %20.15f `b'                            25.275196075439450   <- one ULP LOWER
##   count if Prec_L > `b' & Prec_L!=.         49
##   summarize PCC_L if Prec_L > `b'           N = 49, mean = .0254348
##
## Passing r(p90) through a local macro loses the last bit (%21x shows +1.946733fffffffX+004
## against the variable's +1.9467340000000X+004), so the boundary estimate itself survives the
## strict inequality. The paper's 0.025 is that 49-observation mean; the 48-observation mean is
## 0.0278, which prints as 0.028. So the reproduction here is the top 49 by precision, i.e.
## Prec_L >= r(p90), with r(p90) taken as Stata's percentile -- an ORDER STATISTIC, the same
## rule st_winsor2 pins for Stata's _pctile, not an interpolated quantile.
##
## (Computing an order statistic needs no wrapper: it is a sort and an index, exactly as
## st_winsor() in stata_compat.R computes its own cutoffs.)
pctile_stata <- function(x, p) {
  xs <- sort(x)
  n <- length(xs)
  h <- n * p
  if (h == floor(h)) (xs[h] + xs[h + 1]) / 2 else xs[ceiling(h)]
}
p90_prec_L <- pctile_stata(dT3$Prec_L, 0.90)
dT3_top10 <- st_keep_if(dT3, dT3$Prec_L >= p90_prec_L)
put("T3_top10_N", nrow(dT3_top10))
put("T3_top10", mean(dT3_top10$PCC_L, na.rm = TRUE))

## ---- "WAAP" = 0.042 ---------------------------------------------------------------------
## remittances.do: `reg TSTAT_L SE1_PCC_L if TSTAT_L > 2.8, cluster (IDStudy)` -- the same
## WLS-clustered FAT-PET regression as Table 2 spec (1), restricted to the "adequately powered"
## subsample (|t| > 2.8, the WAAP convention of Ioannidis, Stanley & Doucouliagos, 2017). As in
## Table 2 spec (1), in this TRANSFORMED regression the slope on SE1_PCC_L is the true/corrected
## effect (b0); the intercept is the (here largely irrelevant) residual publication-bias term.
dT3_waap <- st_keep_if(dT3, dT3$TSTAT_L > 2.8)
put("T3_waap_N", nrow(dT3_waap))
m_T3_waap <- st_regress(TSTAT_L ~ SE1_PCC_L, data = dT3_waap, cluster = ~IDStudy)
co_waap <- st_coefs(m_T3_waap)
put("T3_waap", co_waap$estimate[co_waap$term == "SE1_PCC_L"])

## ---- "A&K" = 0.121 and "Stem-based bias correction model" = 0.036 -- NOT REPRODUCED --------
## These two rows are the only cells in this package that do not reproduce, and the reason is
## the same for both: remittances.do does not contain them. Where the other rows are Stata
## commands, these two are bare URLs --
##   *A&K
##   *https://maxkasy.github.io/home/metastudy/
##   *Stem
##   *in R: https://github.com/Chishio318/stem-based_method
## -- pointing at third-party code that ran outside the do-file. A&K is Andrews & Kasy's (2019)
## publication-selection maximum-likelihood model (a bespoke MATLAB/Stata routine with its own
## choices of p-value cutoffs and symmetry); the stem-based method is Furukawa's (2019) R
## package, which is not on CRAN. Neither is a Stata command, so neither can be pinned in
## stata_compat.R the way every other cell here is, and neither can be checked against Stata.
##
## A from-scratch reimplementation of either could only be validated against the single printed
## number it is trying to hit, which makes "it reproduces" and "it was tuned until it did"
## indistinguishable. That is the one failure this package is built to avoid, so both are left
## as gaps. What the paper concludes does not turn on them: the three rows that DO reproduce
## (0.025, 0.042 against an uncorrected 0.103) already bracket the claim, and A&K's 0.121 is
## the largest of the five, so including it would not make the corrected effect smaller.
put("T3_andrewskasy", NA); put("T3_stem", NA)

## ================================================================== report + write

## ---- the paper's headline claim, reproduced -------------------------------------------------
cat("==== Headline claim: \"positive but economically small\" (abstract & introduction) ====\n")
cat("Paper's own words -- abstract: \"Correcting for the bias using recently developed\n")
cat("  techniques, we find that the mean effect of remittances on growth is still positive\n")
cat("  but economically small.\"\n")
cat("Paper's own numbers -- main-text Table 3, \"Alternative approaches to correcting for\n")
cat("  publication bias\" (long-run effect, N=487):\n\n")
cat(sprintf("  %-38s %10s %10s\n", "Method", "Paper", "Produced"))
cat(sprintf("  %-38s %10s %10.3f\n", "Uncorrected mean",              "0.103", results$T3_uncorrected_mean))
cat(sprintf("  %-38s %10s %10.3f  (N=%d)\n", "Top 10 (most precise decile)", "0.025", results$T3_top10, results$T3_top10_N))
cat(sprintf("  %-38s %10s %10.3f  (N=%d)\n", "WAAP",                         "0.042", results$T3_waap, results$T3_waap_N))
cat(sprintf("  %-38s %10s %10s\n", "Andrews & Kasy (2019) selection model", "0.121", "not reproduced -- third-party estimator, see notes"))
cat(sprintf("  %-38s %10s %10s\n", "Stem-based (Furukawa, 2019)",           "0.036", "not reproduced -- third-party estimator, see notes"))
cat("\nPaper's own gloss on this table: \"the underlying effect of remittances on economic\n")
cat("  growth is small in all of the methodological approaches: none passes Doucouliagos's\n")
cat("  bar for a medium effect\" (the 0.173 threshold of Doucouliagos, 2011).\n")
cat("Reproduced range across the three estimable bias-correction methods: 0.025-0.042,\n")
cat("  against an uncorrected raw mean of 0.103 -- i.e. positive, and shrinking toward zero\n")
cat("  once publication bias is corrected for: economically small.\n\n")

cat("==== Produced numbers ====\n")
for (nm in names(results)) {
  v <- results[[nm]]
  cat(sprintf("%-22s = %s\n", nm, if (is.na(v)) "not reproduced -- third-party estimator, see notes" else format(round(v, 6))))
}

jsonlite_ok <- requireNamespace("jsonlite", quietly = TRUE)
out_path <- "results.json"   # written into the working directory run.R is invoked from
if (jsonlite_ok) {
  jsonlite::write_json(results, out_path, auto_unbox = TRUE, na = "null", digits = 10)
} else {
  # minimal hand-rolled JSON writer, no dependency required
  esc <- function(x) if (is.na(x)) "null" else format(x, digits = 15, scientific = FALSE)
  lines <- paste0('  "', names(results), '": ', vapply(results, esc, character(1)))
  writeLines(c("{", paste(lines, collapse = ",\n"), "}"), out_path)
}
cat("\nWrote", normalizePath(out_path), "\n")

stata_compat_log()
