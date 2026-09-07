# bma -- Determinants of Horizontal Spillovers from FDI: Evidence from a Large Meta-Analysis
# Havranek & Irsova, World Development 2013. Reproduces Table 4 ("Test of publication bias").
#
# Table 4 regresses the effect size (e) on its standard error (se), with the coefficient on
# se interpreted as the funnel-asymmetry / publication-bias parameter, and the constant
# interpreted as the genuine effect beyond bias (precision-effect test). The paper says this
# is "Estimated by weighted least squares with the precision (the inverse of standard error)
# taken as the weight." The author's own do-file (determinants.do) does not run this as an
# explicit WLS regression of e on se; instead it precomputes prec = 1/se (line 17) and,
# after `xtset idstudy`, runs
#
#     xtreg t prec, fe vce(cluster idstudy)                       (line 135-136)
#
# where `t` is the study's own pre-computed t-statistic (e/se), already a column in the
# published data. Dividing the original model e = b0 + b1*se + u through by se gives
# t = b0*(1/se) + b1 + u/se, i.e. t = b0*prec + b1 + v -- an OLS regression of t on prec is
# therefore algebraically the weighted-least-squares regression of e on se with the implied
# variance-based weight, run without ever calling a `weights=` argument. This is confirmed
# below: with study fixed effects the coefficient on `prec` reproduces the printed "Constant"
# row (0.021, se 0.015, p 0.150) and the model's reported intercept reproduces the printed
# "Se (publication bias)" row (-0.325, se 0.262, p 0.220) to three decimals.
#
# Table 4's second column adds country fixed effects. No further estimation line survives in
# the extracted do-file for this column (the CMD-matching scan over determinants.do finds no
# second `xtreg`/`regress`/`areg` command), so the exact original command is not directly
# evidenced. We reproduce it as `xtreg t prec i.idcountry, fe vce(cluster idstudy)` -- study
# absorbed as the xtreg panel, country entered as explicit dummies, same clustering -- which
# is the natural Stata idiom for "study AND country fixed effects" the caption uses, and it
# reproduces the printed Constant row (0.021, 0.015, p 0.183) exactly. Its "Se (publication
# bias)" row is the model's *_cons* with country dummies also in the regression; this is not
# a bivariate y~x fixed-effects intercept (the only case `st_xtreg_fe_cons` supports), and a
# naive grand-mean identity does not reproduce it (see REPLICATION.md) -- reported as not
# computed rather than guessed.

source("stata_compat.R")

d <- read.csv("C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\bma\\bma.csv",
              stringsAsFactors = FALSE)
cat("raw rows read:", nrow(d), "\n")

## ---- sample construction (determinants.do lines 14-26, 81) ----
d <- st_drop_if(d, d$aux == 1)      # line 14: drop if aux==1
d <- st_drop_if(d, d$horiz != 1)    # line 26: drop if horiz!=1 (keep horizontal spillovers)
d <- st_drop_if(d, abs(d$e) > 10)   # line 123 (81 in this excerpt's ordering): drop if abs(e)>10
d$prec <- 1 / d$se                  # line 17: gen prec = 1/se
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
## xtreg t prec i.idcountry, fe vce(cluster idstudy)
m2 <- st_xtreg_fe(t ~ prec + idcountry_f, data = d, panel = "idstudy", cluster = "idstudy")
s2 <- summary(m2)$coeftable
constant2 <- c(coef = s2["prec", "Estimate"], se = s2["prec", "Std. Error"], p = s2["prec", "Pr(>|t|)"])
N2 <- nobs(m2)
## The "Se (publication bias)" row for column 2 is xtreg's reported _cons in a model that also
## carries country dummies. st_xtreg_fe_cons only supports the bivariate y~x case; there is no
## wrapper for a multivariate fixed-effects constant, and a naive grand-mean identity
## (mean(t) - sum(beta_k * mean(x_k))) does NOT reproduce column 1's already-validated value
## once extra covariates are added, so it is not trustworthy here either. Reported as NA.
sepub2 <- c(coef = NA_real_, se = NA_real_, p = NA_real_)

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
  "T4 col2 N"                                    = N2
)

cat("\n---- produced values ----\n")
for (nm in names(res)) cat(sprintf("%-45s %s\n", nm, format(res[[nm]], digits = 6)))

stata_compat_log()

if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite", repos = "https://cloud.r-project.org")
jsonlite::write_json(res, "results.json", auto_unbox = TRUE, na = "null", digits = 10)
cat("\nWrote results.json\n")
