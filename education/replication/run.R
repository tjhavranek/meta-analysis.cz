# run.R -- Table 6 of Havranek & Zeynalova, "Forecasting Tuition Fees and Enrolment"
# (Oxford Bulletin of Economics and Statistics, 2019): "Best practice estimation yields a
# tuition-enrolment effect that is close to zero".
#
# Table 6 reports, for seven synthetic "best practice" studies, the fitted partial
# correlation implied by
#   (a) Bayesian model averaging (BMA), and
#   (b) frequentist Mallows model averaging (FMA),
# each with a 95% interval.
#
# ---------------------------------------------------------------------------------------
# WHAT PRODUCES THESE NUMBERS
# ---------------------------------------------------------------------------------------
# The recipe is fully specified by material the SITE publishes:
#
#   1. site/education/education.do, block "HETEROGENEITY - BAYESIAN MODEL AVERAGING in R",
#      carries the exact BMA call as a comment:
#          bms(data, burn=1000000, iter=2000000, g="UIP", mprior="uniform",
#              nmodel=5000, mcmc="bd", user.int=FALSE)
#   2. the next block of the same do-file carries the whole Mallows/FMA program
#      (orthogonalised covariate space, LowRankQP for the weights) verbatim;
#   3. the final block, "BEST PRACTICE", builds the weighted variables
#          gen `x'_nobs = `x' * invperst
#      runs
#          ivreg2 pcc_nobs <18 regressors>_nobs, cluster(idstudy idcountry)
#      and then seven lincom lines whose coefficient vectors ARE the best-practice designs.
#      Those seven vectors are transcribed below, unchanged, from that file.
#
# So all three ingredients -- the BMA priors, the FMA program, and the best-practice
# covariate vectors -- come from published files. Nothing here needs the author's private
# workspace. (That workspace was consulted once, to CHECK this reconstruction: the design
# matrix built below agrees with the author's saved dataeducation_nobs to 5e-10, and the
# posterior means below agree with the author's saved fitted bms object to about 2e-4.)
#
# Weighting: every variable, including the dependent one, is multiplied by
# invperst = 1/(estimates per study) -- this is what the paper means by "weighted using the
# inverse of the number of estimates reported per study". The intercept is NOT weighted,
# because neither bms nor the author's FMA program weights it, and because ivreg2's _cons
# is a column of ones. Not textbook WLS, but it is what produced the published table.
#
# ---------------------------------------------------------------------------------------
# TWO DELIBERATE CONVENTIONS, BOTH TAKEN FROM THE AUTHOR'S OWN CODE
# ---------------------------------------------------------------------------------------
# (i)  BMA by ENUMERATION, not MCMC. With K = 18 the model space is 2^18 = 262,144, which
#      bms enumerates exactly in under a minute. The author ran the MCMC approximation to
#      that same posterior (his log reports Corr PMP = 0.9998). Enumeration is the exact
#      object the chain approximates, it is deterministic, and it is therefore what makes
#      this package reproducible; re-running a 2,000,000-draw chain would not return the
#      author's draws anyway. Scored against Table 6 the two are equally good: enumeration
#      gets 20 of the 21 BMA numbers and the author's own saved chain also gets 20 of 21 --
#      they miss DIFFERENT ones. See REPLICATION.md.
#
# (ii) FMA coefficients are used ROUNDED TO 4 DECIMALS. Not a fudge: the author's Mallows
#      program, as published in education.do, ends with
#          MMA.fls <- round(results.reduced,4)
#      so the 4-decimal table is the only FMA output that ever existed outside that R
#      session, it is what Table 5 prints, and Table 6's FMA column was computed from it.
#      Both versions are computed below and both are written to results.json; with
#      unrounded coefficients 10 of the 21 FMA numbers miss by exactly one unit in the
#      third decimal, always in the same direction, which is what pinned the rounding down.
#
# ---------------------------------------------------------------------------------------
# THE INTERVALS
# ---------------------------------------------------------------------------------------
# Table 6's note: "Because Bayesian model averaging (BMA) does not work with the concept of
# standard errors, the confidence intervals for BMA are approximate and constructed using
# the standard errors estimated by simple OLS with robust standard errors clustered at the
# study and country level." That OLS is the ivreg2 of the BEST PRACTICE block, and the
# half-width is 1.96 times the lincom standard error of the same best-practice vector. The
# SAME half-width is applied to the FMA point estimate, which is what the printed table
# does: in every row the BMA and FMA intervals have the same width to the printed digit.
#
# Checked against Stata 15.1: ivreg2's coefficients and all seven lincom standard errors
# reproduce here through st_ivreg2 to six decimals (large-sample VCE, z inference).
#
# Requires: BMS, LowRankQP (both on CRAN), plus the fixest/jsonlite the compat layer uses.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/education/replication/stata_compat.R")
suppressMessages(library(BMS))
suppressMessages(library(LowRankQP))

data_path <- (if (file.exists("education.csv")) "education.csv" else
     "https://meta-analysis.cz/data/v1/education/education.csv")
stopifnot(file.exists(data_path))
d <- read.csv(data_path, stringsAsFactors = FALSE)
cat(sprintf("Loaded %d rows x %d cols from the published education.csv\n", nrow(d), ncol(d)))

# ---------------------------------------------------------------- weighted design matrices
# Column ORDER matters for FMA and only for FMA: Mallows averaging over the orthogonalised
# space walks nested models x[,1:i], so the sequence of regressors defines the model set.
# The order used here is the order education.do lists them in the BEST PRACTICE ivreg2
# (and the order Table 5 prints the FMA column in).
bma_vars <- c("pcc", "pcc_se", "shortrun", "panel", "cross", "unemployment", "income",
              "linear", "doublelog", "ols", "endogeneity", "male", "female", "private",
              "public", "usa", "ln_pub_year", "ln_google", "published")
fma_vars <- c("pcc", "pcc_se", "shortrun", "ols", "endogeneity", "linear", "doublelog",
              "unemployment", "income", "cross", "panel", "male", "female", "private",
              "public", "usa", "ln_pub_year", "ln_google", "published")
stopifnot(setequal(bma_vars, fma_vars))

weighted_frame <- function(vs) {
  W <- as.data.frame(lapply(vs, function(v) d[[v]] * d$invperst))
  names(W) <- vs
  W
}
Wb <- weighted_frame(bma_vars)
Wf <- weighted_frame(fma_vars)

# --------------------------------------------------------------------------------- (a) BMA
cat("BMA: enumerating all 2^18 = 262144 models (UIP g-prior, uniform model prior)...\n")
bma_fit <- bms(Wb, g = "UIP", mprior = "uniform", nmodel = 5000,
               mcmc = "enumerate", user.int = FALSE)
bma_tab <- coef(bma_fit, order.by.pip = FALSE, exact = FALSE, include.constant = TRUE)
bma <- setNames(bma_tab[, "Post Mean"], rownames(bma_tab))
bma_cons <- unname(bma["(Intercept)"])
cat("BMA posterior means (Table 5, column 'Post. mean'):\n")
print(round(bma[c(bma_vars[-1], "(Intercept)")], 4))

# --------------------------------------------------------------------------------- (b) FMA
# Port of the Mallows program printed in education.do. One line differs: the author's
# full-model OLS fit is routed through st_regress, which is the same estimator.
mydata <- Wf
x.data <- cbind(const_ = 1, mydata[, -1])
xmat <- sapply(seq_len(ncol(x.data)), function(i) x.data[, i] / max(x.data[, i]))
scale.vector <- as.matrix(sapply(seq_len(ncol(x.data)), function(i) max(x.data[, i])))
Y <- as.matrix(mydata[, 1])
output.colnames <- colnames(x.data)

M <- k <- ncol(xmat)
n <- nrow(xmat)
fullfr <- as.data.frame(xmat)
names(fullfr) <- paste0("z", seq_len(M))
fullfr$yy <- as.numeric(Y)
full.fit <- st_regress(
  stats::as.formula(paste("yy ~ 0 +", paste(names(fullfr)[1:M], collapse = " + "))),
  data = fullfr)
beta.full <- as.matrix(unname(coef(full.fit)))

beta <- matrix(0, k, M); resid <- matrix(0, n, M); K_vector <- matrix(seq_len(M))
var.matrix <- matrix(0, k, M); bias.sq <- matrix(0, k, M)
for (i in seq_len(M)) {
  X <- as.matrix(xmat[, 1:i])
  ortho <- eigen(t(X) %*% X)
  Q <- ortho$vectors; lambda <- ortho$values
  x.tilda <- X %*% Q %*% (diag(lambda^-0.5, i, i))
  beta.star <- t(x.tilda) %*% Y
  beta[1:i, i] <- Q %*% diag(lambda^-0.5, i, i) %*% beta.star
  resid[, i] <- Y - x.tilda %*% as.matrix(beta.star)
  bias.sq[, i] <- (beta[, i] - beta.full)^2
  var.star <- diag(as.numeric((t(resid[, i]) %*% resid[, i]) / (n - i)), i, i)
  var.hat <- var.star %*% (Q %*% diag(lambda^-1, i, i) %*% t(Q))
  var.matrix[1:i, i] <- diag(var.hat)
  var.matrix[, i] <- var.matrix[, i] + bias.sq[, i]
}
e_k <- resid[, M]
sigma_hat <- as.numeric((t(e_k) %*% e_k) / (n - M))
G <- t(resid) %*% resid
qp <- LowRankQP(Vmat = G, dvec = (sigma_hat^2) * K_vector, Amat = matrix(1, 1, M),
                bvec = matrix(1, 1, 1), uvec = matrix(1, M, 1), method = "LU", verbose = FALSE)
mma_w <- as.matrix(qp$alpha)
fma_exact <- setNames(as.numeric((beta %*% mma_w) / scale.vector), output.colnames)
fma <- round(fma_exact, 4)          # the author's own round(results.reduced, 4)
cat("FMA (Mallows) coefficients, as the author's program reports them:\n")
print(fma[c("const_", fma_vars[-1])])

# ---------------------------------------------- (c) the OLS the intervals are measured from
regs <- fma_vars[-1]
for (v in c("pcc", regs)) d[[paste0(v, "_nobs")]] <- d[[v]] * d$invperst
ols_fml <- stats::as.formula(paste("pcc_nobs ~", paste(paste0(regs, "_nobs"), collapse = " + ")))
ols_fit <- st_ivreg2(ols_fml, data = d, cluster = ~ idstudy + idcountry)
V <- vcov(ols_fit); onames <- names(coef(ols_fit))
cat(sprintf("ivreg2: N = %d, clusters = %d studies / %d countries\n",
            nobs(ols_fit), length(unique(d$idstudy)), length(unique(d$idcountry))))

# ------------------------------------------- (d) the seven best-practice vectors, verbatim
# Straight out of the lincom lines of education.do's BEST PRACTICE block. The provenance
# check below confirms what the paper says these are: publication characteristics and the
# preferred data/method choices at the sample extremes, everything else at the sample mean
# (means weighted by invperst, as the estimation is).
bp_base <- c(pcc_se = 0, shortrun = 0.480, ols = 0, endogeneity = 1, linear = 0,
             doublelog = 1, unemployment = 1, income = 1, cross = 0, panel = 1,
             male = 0.075, female = 0.051, private = 0.233, public = 0.454, usa = 0.839,
             ln_pub_year = 7.609, ln_google = 3.970, published = 1)
overrides <- list("short-run"     = c(shortrun = 1),
                  "long-run"      = c(shortrun = 0),
                  "private"       = c(private = 1, public = 0),
                  "public"        = c(private = 0, public = 1),
                  "male"          = c(male = 1, female = 0),
                  "female"        = c(male = 0, female = 1),
                  "all-estimates" = c())
cat("\nProvenance of the best-practice constants (do-file value vs the published data):\n")
for (v in c("shortrun", "male", "female", "private", "public", "usa")) {
  cat(sprintf("  %-12s do-file %.3f   invperst-weighted sample mean %.4f\n",
              v, bp_base[[v]], stats::weighted.mean(d[[v]], d$invperst)))
}
cat(sprintf("  %-12s do-file %.3f   sample maximum %.4f\n",
            "ln_pub_year", bp_base[["ln_pub_year"]], max(d$ln_pub_year)))
cat(sprintf("  %-12s do-file %.3f   sample maximum %.4f   [the paper censors citations at\n",
            "ln_google", bp_base[["ln_google"]], max(d$ln_google)))
cat("               the 99% level; that censoring point is not recoverable from the\n")
cat("               published columns, so the do-file's own value stands]\n")
cat(sprintf("  %-12s do-file %.3f   sample minimum %.4f   [publication bias switched off]\n",
            "pcc_se", bp_base[["pcc_se"]], min(d$pcc_se)))

# --------------------------------------------------------------------------------- results
z <- stats::qnorm(0.975)
results <- list(); diagnostic <- list()
cat("\n")
for (r in names(overrides)) {
  v <- bp_base
  o <- overrides[[r]]
  if (length(o)) v[names(o)] <- o
  cvec <- setNames(rep(0, length(onames)), onames)
  cvec[paste0(names(v), "_nobs")] <- v
  se <- sqrt(as.numeric(t(cvec) %*% V %*% cvec))          # exactly Stata's lincom SE
  fit_bma <- bma_cons + sum(bma[names(v)] * v)
  fit_fma <- unname(fma["const_"]) + sum(fma[names(v)] * v)
  fit_fma_exact <- unname(fma_exact["const_"]) + sum(fma_exact[names(v)] * v)
  results[[sprintf("T6 %s BMA mean", r)]] <- fit_bma
  results[[sprintf("T6 %s BMA CI low", r)]] <- fit_bma - z * se
  results[[sprintf("T6 %s BMA CI high", r)]] <- fit_bma + z * se
  results[[sprintf("T6 %s FMA mean", r)]] <- fit_fma
  results[[sprintf("T6 %s FMA CI low", r)]] <- fit_fma - z * se
  results[[sprintf("T6 %s FMA CI high", r)]] <- fit_fma + z * se
  diagnostic[[r]] <- list(lincom_se = se, fma_mean_from_unrounded_coefs = fit_fma_exact)
  cat(sprintf("%-14s se=%.6f | BMA %+.4f [%+.4f, %+.4f] | FMA %+.4f [%+.4f, %+.4f]\n",
              r, se, fit_bma, fit_bma - z * se, fit_bma + z * se,
              fit_fma, fit_fma - z * se, fit_fma + z * se))
}

targets <- jsonlite::fromJSON("targets.json")
hit <- sapply(seq_along(targets$label), function(i)
  isTRUE(round(results[[targets$label[i]]], targets$digits[i]) ==
           round(targets$printed[i], targets$digits[i])))
cat(sprintf("\nAgainst the frozen targets: %d of %d match at 3 decimals.\n", sum(hit), length(hit)))
if (any(!hit)) {
  cat("Still missing:\n")
  for (i in which(!hit))
    cat(sprintf("  %-28s produced %+.6f (rounds to %+.3f), paper prints %+.3f\n",
                targets$label[i], results[[targets$label[i]]],
                round(results[[targets$label[i]]], 3), targets$printed[i]))
}

jsonlite::write_json(list(results = results, diagnostic_only = diagnostic),
                     "results.json", auto_unbox = TRUE, pretty = TRUE, na = "null", digits = 10)
cat("\nWrote results.json\n")
stata_compat_log()
