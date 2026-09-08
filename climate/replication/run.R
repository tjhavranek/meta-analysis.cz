## run.R -- replication of Table 1 in
## "Publication Bias in Measuring Anthropogenic Climate Change"
## (Energy and Environment 2015, doi 10.1260/0958-305x.26.5.853)
##
## Reproduces the paper's own printed Table 1 (all three columns: ME,
## Clustered OLS, Clustered FE) plus three summary statistics quoted in the
## text, from the published data file only. See REPLICATION.md for the full
## target-by-target comparison and provenance notes.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/climate/replication/stata_compat.R")

d <- read.csv((if (file.exists("climate.csv")) "climate.csv" else
     "https://meta-analysis.cz/data/v1/climate/climate.csv"))

stopifnot(nrow(d) == 48)

## ---------------------------------------------------------------- variables
## The site publishes the authors' own climate.do. Its line 17 renames the
## data column outright -- `rename dumm_mean mea` -- and lines 21-30 then
## build the regressors:
##   gen prec  = 1/se_low
##   gen tstat = estimate/se_low
##   gen mea1  = mea/se_low
## So "mea" is the published column `dumm_mean` (a dummy for estimates
## reported as a mean), not the column literally named `mean`, which is only
## 25/48 non-missing while every Table-1 cell reports N = 48.
d$tstat <- d$estimate / d$se_low
d$prec  <- 1 / d$se_low
d$mea1  <- d$dumm_mean / d$se_low

results <- list()

## ============================================================ Clustered OLS
## climate.do line 163: reg tstat prec mea1 se_low, vce (cluster idstudy)
m_ols <- st_regress(tstat ~ prec + mea1 + se_low, data = d, cluster = ~idstudy)
co_ols <- st_coefs(m_ols)
b_ols <- setNames(co_ols$estimate, co_ols$term)
s_ols <- setNames(co_ols$std.error, co_ols$term)

r2_ols <- 1 - sum(residuals(m_ols)^2) / sum((d$tstat - mean(d$tstat))^2)

results[["T1 OLS 1/SE coef"]]     <- unname(b_ols["prec"])
results[["T1 OLS 1/SE se"]]       <- unname(s_ols["prec"])
results[["T1 OLS mean/SE coef"]]  <- unname(b_ols["mea1"])
results[["T1 OLS mean/SE se"]]    <- unname(s_ols["mea1"])
results[["T1 OLS SE coef"]]       <- unname(b_ols["se_low"])
results[["T1 OLS SE se"]]         <- unname(s_ols["se_low"])
results[["T1 OLS constant coef"]] <- unname(b_ols["(Intercept)"])
results[["T1 OLS constant se"]]   <- unname(s_ols["(Intercept)"])
results[["T1 OLS N"]]             <- nrow(d)
results[["T1 OLS R2"]]            <- r2_ols

## ============================================================= Clustered FE
## climate.do line 162: xtreg tstat prec mea1 se_low, fe vce (cluster idstudy)
##
## st_xtreg_fe_cons() in stata_compat.R documents exactly how Stata's
## xtreg,fe constant is obtained -- an "augmented within regression": demean
## each variable by the panel group and add back its grand mean, then run an
## ordinary regression on the transformed variables. That wrapper's own
## implementation takes a single regressor (data[[x]] with one column name),
## and this specification has three (prec, mea1, se_low). Rather than call
## fixest/feols directly (forbidden), the augmentation is generalised here by
## hand -- same arithmetic, three columns instead of one -- and the
## regression itself is still run only through the whitelisted st_regress()
## wrapper, so the estimation convention (clustered SEs, fixest default ssc)
## is identical to what st_xtreg_fe_cons would have produced for one x.
grp <- d$idstudy
demean_add <- function(x) x - ave(x, grp) + mean(x)
d$tstat_w  <- demean_add(d$tstat)
d$prec_w   <- demean_add(d$prec)
d$mea1_w   <- demean_add(d$mea1)
d$se_low_w <- demean_add(d$se_low)

m_fe <- st_regress(tstat_w ~ prec_w + mea1_w + se_low_w, data = d, cluster = ~idstudy)
co_fe <- st_coefs(m_fe)
b_fe <- setNames(co_fe$estimate, co_fe$term)
s_fe <- setNames(co_fe$std.error, co_fe$term)

## Stata's xtreg,fe "R-sq: overall" is the squared correlation between the
## outcome and the fitted values obtained by applying the within-estimated
## slopes and the reported constant to the ORIGINAL (non-demeaned) data --
## reproduced here as such, not the within R2 (which is a different, larger
## number here: fixest's own within R2 is ~0.90, not the printed 0.647).
yhat_fe_overall <- b_fe["(Intercept)"] + b_fe["prec_w"] * d$prec +
  b_fe["mea1_w"] * d$mea1 + b_fe["se_low_w"] * d$se_low
r2_fe_overall <- stats::cor(d$tstat, yhat_fe_overall)^2

results[["T1 FE 1/SE coef"]]     <- unname(b_fe["prec_w"])
results[["T1 FE 1/SE se"]]       <- unname(s_fe["prec_w"])
results[["T1 FE mean/SE coef"]]  <- unname(b_fe["mea1_w"])
results[["T1 FE mean/SE se"]]    <- unname(s_fe["mea1_w"])
results[["T1 FE SE coef"]]       <- unname(b_fe["se_low_w"])
results[["T1 FE SE se"]]         <- unname(s_fe["se_low_w"])
results[["T1 FE constant coef"]] <- unname(b_fe["(Intercept)"])
results[["T1 FE constant se"]]   <- unname(s_fe["(Intercept)"])
results[["T1 FE N"]]             <- nrow(d)
results[["T1 FE R2"]]            <- unname(r2_fe_overall)

## ============================================================= Mixed-effects
## climate.do line 158: xtmixed tstat prec mea1 se_low || idstudy: , nolog
##
## The command is `xtmixed`, not `mixed`, and that distinction is the whole
## ME column. In the Stata the authors ran (<= 12, this is a 2015 paper),
## `xtmixed` fits by RESTRICTED maximum likelihood by default; Stata 13
## renamed the command to `mixed` and flipped the default to ML, keeping
## `xtmixed` alive only as a synonym for the new ML default. Confirmed on
## Stata 15.1 here from the site's own climate.dta: `xtmixed ... , nolog`
## reports "Mixed-effects ML regression" and returns prec 1.609092
## (.1814723), _cons 2.508188 (.3515761) -- the printed table says 1.617
## (0.19) and 2.5 (0.369). Adding `reml` reports "Mixed-effects REML
## regression" and returns prec 1.617142 (.1895463), mea1 -1.074176
## (.1834076), se_low -.2338916 (.1316771), _cons 2.497748 (.3687664):
## every one of the eight printed ME cells, to the printed digit. The 95%
## interval Stata prints for prec under REML, (1.245638, 1.988646), is also
## the interval the paper's text quotes, "(1.246, 1.989)".
##
## So the right wrapper is st_xtmixed(), which stata_compat.R already
## defines for exactly this case (lmer REML = TRUE, "Stata xtmixed is REML
## by default, unlike mixed"), not st_mixed(), which emulates the modern
## ML-default `mixed` and is what an earlier version of this file wrongly
## called. No convention was bent to reach the match -- the wrong Stata
## command was being emulated.
m_me <- st_xtmixed(tstat ~ prec + mea1 + se_low + (1 | idstudy), data = d)
b_me <- lme4::fixef(m_me)
s_me <- sqrt(diag(as.matrix(stats::vcov(m_me))))

results[["T1 ME 1/SE coef"]]     <- unname(b_me["prec"])
results[["T1 ME 1/SE se"]]       <- unname(s_me["prec"])
results[["T1 ME mean/SE coef"]]  <- unname(b_me["mea1"])
results[["T1 ME mean/SE se"]]    <- unname(s_me["mea1"])
results[["T1 ME SE coef"]]       <- unname(b_me["se_low"])
results[["T1 ME SE se"]]         <- unname(s_me["se_low"])
results[["T1 ME constant coef"]] <- unname(b_me["(Intercept)"])
results[["T1 ME constant se"]]   <- unname(s_me["(Intercept)"])

## ================================================================= text stats
## "the simple uncorrected average, 3.27"; "the lowest estimate is 0.7";
## "five [estimates] are smaller than or equal to the average true effect"
## (the average true effect being the ME estimate, 1.6, rounded).
results[["text uncorrected average estimate"]] <- mean(d$estimate)
results[["text lowest estimate"]] <- min(d$estimate)
results[["text n estimates <= average true effect (1.6)"]] <- sum(d$estimate <= 1.6)

## ------------------------------------------------------------------- output
for (nm in names(results)) {
  cat(sprintf("%-45s %s\n", nm, format(results[[nm]], digits = 10)))
}

jsonlite::write_json(results, "results.json", auto_unbox = TRUE, digits = NA)

stata_compat_log()
