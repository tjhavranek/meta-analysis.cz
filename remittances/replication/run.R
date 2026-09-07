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
# Specification (2) "WLS, robust" -- per the paper's own table note, "estimated
# using iteratively re-weighted WLS" (Stata `rreg`-type robust regression). No
# wrapper in stata_compat.R implements this (only OLS/WLS `regress`, `ivreg2`,
# `xtreg, fe`, `mixed`, `metan`). Per instructions, this is not approximated
# with an unauthorized function; those cells are left unresolved. Everything
# else uses only the pinned wrappers.

source("stata_compat.R")

DATA_PATH <- "C:/Users/thavr/Dropbox/Study/Other/Agents/Joint/web_meta/site/data/v1/remittances/remittances.csv"

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

## (2) WLS, robust  --  paper's note: "iteratively re-weighted WLS" (Stata rreg).
## No stata_compat.R wrapper implements this estimator -- left unresolved rather
## than substituted with an unauthorized function.
put("B1_s2_pubbias", NA); put("B1_s2_pubbias_se", NA)
put("B1_s2_trueeffect", NA); put("B1_s2_trueeffect_se", NA)

## (3) FE, clustered  [panel FE on study, weighted by inverse variance via the
## same TSTAT~SE1 transform; the paper's printed constant is Stata's xtreg,fe
## _cons, which fixest does not report -- st_xtreg_fe_cons reproduces it]
m_B1_s3_cons <- st_xtreg_fe_cons(y = "TSTAT_L", x = "SE1_PCC_L", panel = "IDStudy", data = dB1)
co3 <- st_coefs(m_B1_s3_cons)
put("B1_s3_pubbias",       co3$estimate[co3$term == "(Intercept)"])
put("B1_s3_pubbias_se",    co3$std.error[co3$term == "(Intercept)"])
put("B1_s3_trueeffect",    co3$estimate[co3$term == "xa"])
put("B1_s3_trueeffect_se", co3$std.error[co3$term == "xa"])

## (4) ME (mixed effects, study random intercept)
m_B1_s4 <- st_mixed(TSTAT_L ~ SE1_PCC_L + (1 | IDStudy), data = dB1)
fx4 <- lme4::fixef(m_B1_s4); se4 <- sqrt(diag(vcov(m_B1_s4)))
put("B1_s4_pubbias",       fx4[["(Intercept)"]])
put("B1_s4_pubbias_se",    se4[["(Intercept)"]])
put("B1_s4_trueeffect",    fx4[["SE1_PCC_L"]])
put("B1_s4_trueeffect_se", se4[["SE1_PCC_L"]])

## (5) IV, clustered [SE1_PCC_L instrumented by Instrum = 1/sqrt(DF)]
## st_ivreg2's large-sample ("no small") convention -- correct for the user-written Stata
## `ivreg2` command that is the site's default IV convention -- does NOT reproduce the
## paper's printed SEs here (0.7377 vs printed 0.75; 0.0432 still rounds to 0.04 but the
## intercept SE misses). Using st_regress with the same IV-formula instead (fixest's
## DEFAULT/full small-sample ssc, i.e. Stata's officialivregress-style small-sample cluster
## correction) reproduces ALL FOUR printed cells for this spec exactly: 1.730 (0.75) and
## -0.050 (0.04). This indicates the author ran the small-sample IV convention (e.g. Stata's
## official `ivregress 2sls, vce(cluster)`, which applies small-sample corrections by
## default) for this specification, not `ivreg2` without `small`. st_regress is used here
## deliberately for its ssc convention; the formula itself is the IV formula, which feols
## (called inside the wrapper) natively supports.
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

## (2) WLS, robust -- same unsupported IRWLS estimator as B1 spec (2).
put("D1_s2_pubbias", NA); put("D1_s2_pubbias_se", NA)
put("D1_s2_trueeffect", NA); put("D1_s2_trueeffect_se", NA)

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

## ================================================================== report + write
cat("==== Produced numbers ====\n")
for (nm in names(results)) {
  v <- results[[nm]]
  cat(sprintf("%-22s = %s\n", nm, if (is.na(v)) "NA (unsupported estimator, see notes)" else format(round(v, 6))))
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
