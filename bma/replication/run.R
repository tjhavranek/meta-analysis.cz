# bma -- Determinants of Horizontal Spillovers from FDI: Evidence from a Large Meta-Analysis
# Havranek & Irsova, World Development 42(1), 2013. Reproduces Table 4 ("Test of publication
# bias") plus the paper's headline numbers: the average spillover, and the Table 2 OLS
# "frequentist check" rows for the technology gap and ownership structure.
#
# ------------------------------------------------------------------------------------------
# What Table 4 actually estimates
# ------------------------------------------------------------------------------------------
# The table's note says the model was "estimated by weighted least squares with the precision
# (the inverse of standard error) taken as the weight." The author's own published do-file
# (site/bma/determinants.do) does not write that as an explicit aweighted regression of e on
# se. It precomputes prec = 1/se (line 17) and, after xtset idstudy, runs
#
#     xtreg t prec, fe vce(cluster idstudy)                        (determinants.do line 136)
#     xi: xtreg t prec i.idcountry, fe vce(cluster idstudy)        (determinants.do line 137)
#
# where t is the study's own t-statistic (e/se), already a column in the published data.
# Dividing e = b0 + b1*se + u through by se gives t = b0*(1/se) + b1 + u/se, so an OLS
# regression of t on prec IS the precision-weighted regression of e on se, run without ever
# passing a weights= argument. Hence, in both columns:
#
#     printed "Constant"              = the coefficient on prec
#     printed "Se (publication bias)" = the model's reported _cons
#
# Column 1 reproduces exactly: 0.021 (0.015) p 0.150 and -0.325 (0.262) p 0.220, N = 1,199.
#
# ------------------------------------------------------------------------------------------
# Column 2, and the one cell this package does NOT reproduce
# ------------------------------------------------------------------------------------------
# Column 2 adds country fixed effects. Its "Constant" row reproduces exactly -- 0.021, 0.015,
# and p 0.183 to all three printed digits. Its "Se (publication bias)" row is reported as NA,
# and the reason is a property of the model rather than a defect in this code.
#
# 42 countries appear in the estimation sample, but 21 of the 42 country dummies are perfectly
# collinear with the study fixed effects: a study that covers exactly one country contributes
# no independent country variation. Stata drops 21 of them, one as the xi base category and 20
# more "omitted because of collinearity". The slope on prec, its standard error and every
# fitted value are invariant to WHICH 21 are dropped; the split of the fit between _cons and
# the surviving country dummies is not. xtreg reports _cons as ybar - xbar'bhat taken over ALL
# regressors including those dummies, so in this column the constant is a normalisation of the
# dropping order rather than an estimated quantity.
#
# Measured, not asserted. All three of the following run on the site's own published bma.csv,
# all give N = 1,199 and an identical prec coefficient of 0.0206846 with clustered SE
# 0.0153147, and all three report a different constant:
#
#     paper, Table 4 col 2                        _cons  -0.284  (0.305)  p 0.357
#     authors' own Stata 11 log, 1 Aug 2011       _cons  -0.2485 (0.3185) p 0.439
#     Stata 15.1 re-run of the same command       _cons  -0.0649 (0.3099) p 0.835
#
# Stata 11 and Stata 15.1 drop different collinear dummies -- Stata 11 omits _Iidcountry_145
# and _155, Stata 15.1 keeps those two and omits _146 and _157 instead -- and so print
# different constants for an identical fit. The paper's value matches neither, so it comes
# from a still earlier run; the printed -0.284 / 0.305 / 0.357 is already in the earliest
# conference-version LaTeX source of this table, and no other Stata log for the paper survives.
# There is no honest way to land on it from the published data: reordering the country dummies
# moves this constant anywhere in roughly (-0.77, +0.35), so picking an ordering that produced
# -0.284 would be choosing it because it matches, not because it is right. Left uncomputed.
#
# ------------------------------------------------------------------------------------------
# Inference convention for the Table 2 OLS check
# ------------------------------------------------------------------------------------------
# Stata's regress y x, vce(cluster g) reports t on G - 1 degrees of freedom, where G is the
# number of clusters -- not z. Here G = 41 countries, so df = 40, which is visible in the
# authors' log as "F( 16, 40)" and "41 clusters in idcountry". Taking the p-values from
# summary()$coeftable applies fixest's default small-sample rule (t.df = "min", i.e. G - 1),
# which is Stata's. Reading them instead off st_coefs(), whose default is z, understates them:
# 0.072 against the printed 0.080, and 0.069 against 0.077 -- close enough to be mistaken for
# rounding, and wrong. That was the defect in the previous version of this file.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/bma/replication/stata_compat.R")

d <- read.csv((if (file.exists("bma.csv")) "bma.csv" else
     "https://meta-analysis.cz/data/v1/bma/bma.csv"),
              stringsAsFactors = FALSE)
cat("raw rows read:", nrow(d), "\n")

## ---- sample construction (determinants.do lines 14, 26, 123) ----
d <- st_drop_if(d, d$aux == 1)      # line 14:  drop if aux==1
d <- st_drop_if(d, d$horiz != 1)    # line 26:  drop if horiz!=1 (keep horizontal spillovers)
d <- st_drop_if(d, abs(d$e) > 10)   # line 123: drop if abs(e)>10
d$prec <- 1 / d$se                  # line 17:  gen prec = 1/se
d$idcountry_f <- factor(d$idcountry)

cat("N after sample construction:", nrow(d), "\n\n")

## ---- Table 4, column 1: study fixed effects ----
## xtreg t prec, fe vce(cluster idstudy)
m1 <- st_xtreg_fe(t ~ prec, data = d, panel = "idstudy", cluster = "idstudy")
s1 <- summary(m1)$coeftable
constant1 <- c(coef = s1["prec", "Estimate"], se = s1["prec", "Std. Error"], p = s1["prec", "Pr(>|t|)"])

cons1_m <- st_xtreg_fe_cons(y = "t", x = "prec", panel = "idstudy", data = d, cluster = ~idstudy)
s1c <- summary(cons1_m)$coeftable
sepub1 <- c(coef = s1c["(Intercept)", "Estimate"], se = s1c["(Intercept)", "Std. Error"],
            p = s1c["(Intercept)", "Pr(>|t|)"])
N1 <- nobs(m1)

## ---- Table 4, column 2: study and country fixed effects ----
## xi: xtreg t prec i.idcountry, fe vce(cluster idstudy)
m2 <- st_xtreg_fe(t ~ prec + idcountry_f, data = d, panel = "idstudy", cluster = "idstudy")
s2 <- summary(m2)$coeftable
constant2 <- c(coef = s2["prec", "Estimate"], se = s2["prec", "Std. Error"], p = s2["prec", "Pr(>|t|)"])
N2 <- nobs(m2)

## How many of the country dummies survive their collinearity with the study fixed effects.
## This count is the whole reason the column-2 constant is not reported: the fit is identical
## for every choice of which dummies are dropped, and the reported constant is not.
n_country <- length(unique(d$idcountry))
n_kept    <- sum(grepl("^idcountry_f", rownames(s2)))
cat(sprintf("Table 4 col 2: %d countries; %d country dummies estimable alongside the study\n",
            n_country, n_kept))
cat(sprintf("               fixed effects, %d absorbed by them. The constant xtreg prints is a\n",
            n_country - n_kept))
cat("               normalisation of the dropped set, so it is left uncomputed here.\n")
sepub2 <- c(coef = NA_real_, se = NA_real_, p = NA_real_)

## ================================================================================
## HEADLINE NUMBERS FROM THE PAPER'S OWN TEXT
## ================================================================================
## meta-analysis.cz summarises this paper as: "spillovers are zero on average but depend
## systematically on the technology gap and ownership structure." That tracks the paper:
##   Abstract: "horizontal spillovers are on average zero, but their sign and magnitude
##   depend systematically on the characteristics of the domestic economy and foreign
##   investors."
##   Concluding remarks: "On average, horizontal spillovers are negligible... when the
##   technology gap ... is too large, horizontal spillovers are small... investment projects
##   in the form of joint ventures with domestic firms bring more positive spillovers than
##   fully foreign-owned projects."
##
## (A) "zero on average". Table 1 reports the raw mean of the collected estimates of e as
##     -0.002 (std. dev. 0.905). The do-file also computes a fixed-effect and a random-effect
##     precision-weighted pooled average, annotated inline with its own printed values:
##         metan e se, fixed    // 0.017     (determinants.do line 147)
##         metan e se, random   // -0.011    (determinants.do line 148)
##
## (B) "depend systematically on technology gap and ownership structure". Section 4 reports a
##     "Frequentist check (OLS)" column beside the BMA estimates in Table 2: all potential
##     spillover determinants plus the control variables with PIP > 0.1, "clustered at the
##     country level". That is the do-file's only other estimation line (line 143):
##         reg e lngap sim open findev gp95 human fdiint green serv cs aggr bothbf empl
##             local lnschcit lnciteaut, vce(cluster idcountry)
##     Matching that variable list, in order, to Table 2's printed OLS rows identifies the
##     Stata mnemonics: lngap = ln(Technology gap), green = Fully owned, sim = Similarity,
##     open/100 = Trade openness, findev/100 = Financial dev., gp95 = Patent rights,
##     human/100 = Human capital, fdiint/100 = FDI penetration, serv = Service sectors,
##     cs = Cross-sectional, aggr = Aggregated, bothbf = Forward, empl = Employment,
##     local = Regional, lnschcit = ln(1+schcit/(2010.6-pubdate)) = Study citations,
##     lnciteaut = ln(1+citeaut) = Author citations. The mapping check below confirms it:
##     every constructed variable reproduces Table 1's published mean for its named
##     counterpart. Table 2 prints, for the two determinants the conclusion singles out:
##         Technology gap   coef -0.260  se 0.145  p 0.080
##         Fully owned      coef -0.104  se 0.057  p 0.077

## ---- variable construction (determinants.do lines 41/45, 47, 56, 60-61, 65-66) ----
d$lngap     <- log(d$gap)                                    # line 56: gen lngap=ln(gap)
d$open100   <- d$open / 100                                  # line 66: replace open=open/100
d$findev100 <- d$findev / 100                                # line 65: replace findev=findev/100
d$human100  <- d$human / 100                                 # line 60: replace human=human/100
d$fdiint100 <- d$fdiint / 100                                # line 61: replace fdiint=fdiint/100
d$lnschcit  <- log(1 + d$schcit / (2010.6 - d$pubdate))      # lines 41, 45
d$lnciteaut <- log(1 + d$citeaut)                            # line 47

## ---- mapping check: constructed variables must reproduce Table 1's published moments ----
map_check <- data.frame(
  var   = c("lngap", "sim", "open100", "findev100", "gp95", "human100", "fdiint100",
            "green", "serv", "cs", "aggr", "bothbf", "empl", "local"),
  label = c("Technology gap", "Similarity", "Trade openness", "Financial dev.", "Patent rights",
            "Human capital", "FDI penetration", "Fully owned", "Service sectors",
            "Cross-sectional", "Aggregated", "Forward", "Employment", "Regional"),
  table1_mean = c(9.771, 0.628, 0.709, 0.600, 3.052, 0.269, 0.267, 0.078, 0.062, 0.088, 0.034, 0.704, 0.139, 0.048)
)
map_check$produced_mean <- sapply(map_check$var, function(v) mean(d[[v]], na.rm = TRUE))
cat("\n---- variable-mapping check against Table 1 ----\n")
print(map_check, digits = 3)

## ---- (A) average effect: raw mean and precision-weighted fixed/random pooling ----
mean_e <- mean(d$e)
fe_pool <- st_metan(d$e, d$se, random = FALSE)
re_pool <- st_metan(d$e, d$se, random = TRUE)
fe_coef <- unname(coef(fe_pool))
re_coef <- unname(coef(re_pool))

## ---- (B) OLS "frequentist check" of Table 2, clustered at the country level ----
m_freq <- st_regress(
  e ~ lngap + sim + open100 + findev100 + gp95 + human100 + fdiint100 + green + serv +
      cs + aggr + bothbf + empl + local + lnschcit + lnciteaut,
  data = d, cluster = ~idcountry
)
## Stata's regress, vce(cluster g) inference: t on G - 1 df, not z. summary()$coeftable
## carries exactly that (fixest default ssc, t.df = "min"); st_coefs() would report z.
fq <- summary(m_freq)$coeftable
gap_row   <- fq["lngap", ]
green_row <- fq["green", ]
N_freq <- nobs(m_freq)
df_freq <- fixest::degrees_freedom(m_freq, "t")
G_freq  <- length(unique(d$idcountry[fixest::obs(m_freq)]))

cat("\n---- Table 2 frequentist-check coefficients of interest ----\n")
print(fq[c("lngap", "green"), ], digits = 6)
cat("N used (matches the paper's stated 1,195 of 1,199):", N_freq, "\n")
cat("clusters in the estimation sample:", G_freq, "  t degrees of freedom used:", df_freq,
    " (the authors' log prints \"F( 16, 40)\" and \"41 clusters in idcountry\")\n")

## ---- collect and print ----
res <- list(
  "T4 col1 (study FE) Constant coef"         = unname(constant1["coef"]),
  "T4 col1 (study FE) Constant SE"           = unname(constant1["se"]),
  "T4 col1 (study FE) Constant p"            = unname(constant1["p"]),
  "T4 col1 (study FE) Se(pub.bias) coef"     = unname(sepub1["coef"]),
  "T4 col1 (study FE) Se(pub.bias) SE"       = unname(sepub1["se"]),
  "T4 col1 (study FE) Se(pub.bias) p"        = unname(sepub1["p"]),
  "T4 col1 N"                                = N1,

  "T4 col2 (study+country FE) Constant coef"     = unname(constant2["coef"]),
  "T4 col2 (study+country FE) Constant SE"       = unname(constant2["se"]),
  "T4 col2 (study+country FE) Constant p"        = unname(constant2["p"]),
  "T4 col2 (study+country FE) Se(pub.bias) coef" = unname(sepub2["coef"]),
  "T4 col2 (study+country FE) Se(pub.bias) SE"   = unname(sepub2["se"]),
  "T4 col2 (study+country FE) Se(pub.bias) p"    = unname(sepub2["p"]),
  "T4 col2 N"                                    = N2,

  "Headline: mean(e), all collected estimates"          = mean_e,
  "Headline: metan e se, fixed (pooled avg.)"           = fe_coef,
  "Headline: metan e se, random (pooled avg.)"          = re_coef,
  "Headline: Table2 OLS check, Technology gap coef"     = unname(gap_row["Estimate"]),
  "Headline: Table2 OLS check, Technology gap SE"       = unname(gap_row["Std. Error"]),
  "Headline: Table2 OLS check, Technology gap p"        = unname(gap_row["Pr(>|t|)"]),
  "Headline: Table2 OLS check, Fully owned coef"        = unname(green_row["Estimate"]),
  "Headline: Table2 OLS check, Fully owned SE"          = unname(green_row["Std. Error"]),
  "Headline: Table2 OLS check, Fully owned p"           = unname(green_row["Pr(>|t|)"]),
  "Headline: Table2 OLS check N"                        = N_freq
)

cat("\n---- produced values ----\n")
for (nm in names(res)) cat(sprintf("%-45s %s\n", nm, format(res[[nm]], digits = 6)))

cat("\n================================================================================\n")
cat("PAPER'S HEADLINE CLAIM: \"spillovers are zero on average but depend systematically\n")
cat("on the technology gap and ownership structure.\"\n")
cat("================================================================================\n")
cat(sprintf("  (A) zero on average:\n"))
cat(sprintf("      raw mean of e, N=%d ................. paper (Table 1): -0.002   produced: %8.4f\n", nrow(d), mean_e))
cat(sprintf("      precision-weighted, fixed effect ..... paper (do-file):  0.017   produced: %8.4f\n", fe_coef))
cat(sprintf("      precision-weighted, random effect .... paper (do-file): -0.011   produced: %8.4f\n", re_coef))
cat(sprintf("  (B) depends systematically on technology gap and ownership (Table 2, OLS check, N=%d):\n", N_freq))
cat(sprintf("      Technology gap:  coef %.3f (paper -0.260)  se %.3f (paper 0.145)  p %.3f (paper 0.080)\n",
            gap_row["Estimate"], gap_row["Std. Error"], gap_row["Pr(>|t|)"]))
cat(sprintf("      Fully owned:     coef %.3f (paper -0.104)  se %.3f (paper 0.057)  p %.3f (paper 0.077)\n",
            green_row["Estimate"], green_row["Std. Error"], green_row["Pr(>|t|)"]))
cat("================================================================================\n")

stata_compat_log()

if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite", repos = "https://cloud.r-project.org")
jsonlite::write_json(res, "results.json", auto_unbox = TRUE, na = "null", digits = 10)
cat("\nWrote results.json\n")
