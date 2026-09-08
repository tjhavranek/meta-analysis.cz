# cbequity replication package
# Paper: "Central Bank Equity as an Instrument of Monetary Policy",
#        Comparative Economic Studies (2020), https://doi.org/10.1057/s41294-019-00092-1
#
# Provenance: AUTHOR CODE. The site publishes the author's Stata script at
# site/cbequity/code.txt (31 lines). This package follows code.txt line by line.
# The estimation lines, verbatim:
#
#   xtset idstudy
#   gen invsqrtnobs = 1/sqrt(nobs)
#   eststo: reg r ser, vce(bootstrap, seed(22))                        (1) OLS
#   eststo: xtreg r ser, fe vce(bootstrap, seed(22))                   (2) FE
#   eststo: reg r ser [pweight=invperstudy], vce(robust)               (3) Study
#   eststo: reg r ser [pweight=prec], vce(robust)                      (4) Precision
#   eststo: ivreg2 r (ser=invsqrtnobs), robust                         (5) IV
#   esttab using fat.rtf, replace se star(* 0.10 ** 0.05 *** 0.01)
#   ... and the same five lines with `if good==1` -> fat2.rtf         (Table 2)
#
# What this means for each table cell, and where the first version went wrong:
#
#  * Only columns (1) and (2) are bootstrapped. Columns (3)-(5) use vce(robust) / robust, so
#    their standard errors are DETERMINISTIC and must reproduce exactly. The paper's table note
#    ("Bootstrapped standard errors are shown in parentheses") is true only of (1) and (2).
#  * (1) `reg ..., vce(bootstrap)` with no cluster() option resamples OBSERVATIONS, with Stata's
#    default reps(50). The first version resampled studies (cluster bootstrap), which is why its
#    OLS/Study/Precision/IV SEs came out 2-3x too large.
#  * (2) `xtreg, fe vce(bootstrap)` on xtset data resamples PANELS (Stata's bootstrap for xt
#    commands is cluster(panelvar) idcluster(...) by default), reps(50). Cluster resampling is
#    what the first version did for every column; it was right only here.
#  * (4) `[pweight=prec]`: the data file (which mirrors the author's, same columns) has no
#    variable `prec`; Stata resolves the abbreviation to the unique match `precr` = 1/ser. So
#    the "Precision" column is weighted by 1/ser, not 1/ser^2. pweight and aweight give the same
#    point estimates; pweight forces the robust VCE, which is what vce(robust) asks for anyway.
#  * (5) `ivreg2 ..., robust` without `small`: HC0 sandwich, no small-sample factor, and RMSE
#    = sqrt(SSR/N) with NO degrees-of-freedom adjustment. The first version clustered by study
#    (wrong VCE) and used sqrt(SSR/(N-2)) (wrong RMSE) -- the RMSE convention is what put the
#    T2 IV RMSE on the wrong side of the 0.105 rounding boundary.
#  * `esttab` with no stats() option prints only N, so the R2 and RMSE rows of the published
#    tables were transcribed from Stata's screen output by hand: for regress/ivreg2 the printed
#    "R-squared" and "Root MSE"; for xtreg, fe the "overall" R-sq and sigma_e.
#
# ---------------------------------------------------------------------------------------------
# VERIFIED AGAINST STATA 15.1 (2026-09-08). Every line of code.txt was re-run in Stata 15.1 on
# the site's own published CSV (site/data/v1/cbequity/cbequity.csv); the probe do-files and logs
# are. The figures Stata produced are quoted below
# so a reader can see which conventions are being emulated, and which single cell of the paper
# cannot be reached by any of them.
#
#   Table 1 (all 176 estimates, 9 studies)
#     reg r ser                      R-squared .28624651   Root MSE .13227723
#     xtreg r ser, fe                overall R-sq .28624651  sigma_e .11753025  (-> 0.12)
#     reg .. [pweight=invperstudy]   R-squared .39717227   Root MSE .11858428
#     reg .. [pweight=prec]          R-squared .29898292   Root MSE .10037388
#     ivreg2 r (ser=invsqrtnobs)     Centered R2 .28237878  Root MSE .13187938
#   Table 2 (good==1: 146 estimates, 4 studies -- Stata `tab idstudy if good==1` gives
#            studies 2, 4, 6, 7 with 23, 38, 27 and 58 estimates)
#     reg r ser if good==1           R-squared .40817385   Root MSE .10521271
#     xtreg r ser if good==1, fe     overall R-sq .40817385  sigma_e .10407703  (-> 0.10)
#     reg .. [pweight=invperstudy]   R-squared .37185019   Root MSE .10643506
#     reg .. [pweight=prec]          R-squared .33620340   Root MSE .08398695
#     ivreg2 .. if good==1           Centered R2 .40298240  Root MSE .10494688
#
#   `prec` really is an abbreviation: Stata accepts `[pweight=prec]` on this dataset and returns
#   the paper's Precision column, confirming it resolves to `precr` = 1/ser.
#
# THE ONE CELL THAT DOES NOT REPRODUCE: Table 2, column (2), RMSE.
#   The paper prints 0.11. Stata's own `xtreg r ser if good==1, fe` reports sigma_e = .10407703,
#   which rounds to 0.10. This R package reproduces Stata to ten decimals (.1040770354), so the
#   gap is not an R/Stata difference and not a wrong convention: the same convention (sigma_e)
#   gives 0.12 for the Table 1 FE column, which is what the paper prints there, and the four
#   other RMSE cells of Table 2 all reproduce. The printed 0.11 equals the neighbouring OLS
#   cell (.10521271 -> 0.11), and the true FE value sits 0.0011 below the 0.105 rounding
#   boundary. It reads as a transcription slip in a hand-typed table -- `esttab` was run with no
#   stats() option, so it printed only N and every R2 and RMSE row was copied off the screen by
#   hand. The paper genuinely prints 0.11, so the target is correct and stays untouched; the
#   package reports the number the author's own command produces and flags the disagreement.
#
# BOOTSTRAP STANDARD ERRORS (columns 1 and 2), also settled in Stata rather than argued:
#   Stata reproduces all eight bootstrapped cells of the two tables exactly, at the author's
#   defaults reps(50), seed(22):
#     T1 reg   se(ser) .58867394  se(_cons) .03164586   printed (0.589)  (0.0316)
#     T1 xtreg 1.70779    .09538525                     printed (1.708)  (0.0954)
#     T2 reg    .54877164 .02988239                     printed (0.549)  (0.0299)
#     T2 xtreg 1.9056772  .10573602                     printed (1.906)  (0.106)
#   That confirms the resampling units: `reg ..., vce(bootstrap)` resamples OBSERVATIONS (the
#   cluster version gives 1.224, nothing like the printed 0.589), while `xtreg, fe
#   vce(bootstrap)` on xtset data resamples PANELS (Stata's log says "Replications based on 9
#   clusters in idstudy"). This package implements exactly those two schemes.
#   R cannot hit the printed digits because it does not share Stata's PRNG stream, and at
#   reps(50) the printed value is one noisy draw. What CAN be checked is the estimator, by
#   letting both programs run far past 50. Stata at reps(2000), seed(22), against this package's
#   2000-replication value:
#     T1 OLS  ser  Stata .48849776  R .4891      cons  Stata .0271411  R .0274
#     T1 FE   ser  Stata 1.8493341  R 1.8928     cons  Stata .0975722  R .1018
#     T2 OLS  ser  Stata .53409918  R .5337      cons  Stata .0285801  R .0289
#     T2 FE   ser  Stata 1.7540135  R 1.7706     cons  Stata .0954357  R .0958
#   The two programs agree to Monte Carlo error, so the whole distance between 0.489 and the
#   printed 0.589 is the noise of a 50-replication bootstrap, not a specification difference.
#   results.json therefore carries the 2000-replication value (what the author's estimator
#   converges to) and the literal reps(50) mirror is printed to the log so the reader can see
#   how wide that noise is.
# ---------------------------------------------------------------------------------------------

suppressMessages({
  library(jsonlite)
})

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/cbequity/replication/stata_compat.R")

DATA_PATH <- (if (file.exists("cbequity.csv")) "cbequity.csv" else
     "https://meta-analysis.cz/data/v1/cbequity/cbequity.csv")
d <- read.csv(DATA_PATH, stringsAsFactors = FALSE)

# gen invsqrtnobs = 1/sqrt(nobs)
d$invsqrtnobs <- 1 / sqrt(d$nobs)

results <- list()
add <- function(label, value) results[[label]] <<- as.numeric(value)

# Plain sandwich arithmetic, used ONLY to cross-check the vcov the wrapper objects return
# (no estimator is fitted here).
sandwich_check <- function(X, e, w = rep(1, length(e)), adj = 1) {
  XtWX <- crossprod(X * w, X)
  meat <- crossprod(X * (w * e), X * (w * e))
  adj * solve(XtWX) %*% meat %*% solve(XtWX)
}

run_battery <- function(dat, label, boot_reps = 2000, boot_mirror_reps = 50, boot_seed = 22) {

  # The data has no missing values in any column used (checked below), so `if good==1` and the
  # full sample are the only sample definitions in play; N and study counts are reported.
  stopifnot(!anyNA(dat[, c("r", "ser", "nobs", "idstudy", "invperstudy", "precr")]))
  n   <- nrow(dat)
  ng  <- length(unique(dat$idstudy))
  X   <- cbind(1, dat$ser)

  ## ---- (1) reg r ser, vce(bootstrap, seed(22)) ----------------------------------------------
  m1 <- st_regress(r ~ ser, data = dat)
  c1 <- st_coefs(m1)

  ## ---- (2) xtreg r ser, fe vce(bootstrap, seed(22)) -----------------------------------------
  m2 <- st_xtreg_fe(r ~ ser, data = dat, panel = "idstudy")
  cons2 <- st_xtreg_fe_cons("r", "ser", "idstudy", dat)
  b2 <- coef(m2)[["ser"]]
  a2 <- coef(cons2)[["(Intercept)"]]

  ## ---- (3) reg r ser [pweight=invperstudy], vce(robust) -------------------------------------
  m3 <- st_regress(r ~ ser, data = dat, weights = dat$invperstudy, robust = TRUE)
  c3 <- st_coefs(m3)

  ## ---- (4) reg r ser [pweight=prec], vce(robust)   (prec -> precr = 1/ser) ------------------
  stopifnot(max(abs(dat$precr - 1 / dat$ser)) < 1e-12)
  m4 <- st_regress(r ~ ser, data = dat, weights = dat$precr, robust = TRUE)
  c4 <- st_coefs(m4)

  # Stata's regress with weights + vce(robust) is the weighted HC1 sandwich, N/(N-k). Confirm the
  # wrapper's vcov is exactly that (guards against a fixest ssc surprise).
  for (k in 3:4) {
    m <- if (k == 3) m3 else m4
    w <- if (k == 3) dat$invperstudy else dat$precr
    V <- sandwich_check(X, resid(m), w, adj = n / (n - 2))
    stopifnot(max(abs(sqrt(diag(V)) - sqrt(diag(vcov(m))))) < 1e-10)
  }

  ## ---- (5) ivreg2 r (ser=invsqrtnobs), robust   (no cluster, no `small`) -------------------
  m5 <- st_ivreg2(r ~ 1 | ser ~ invsqrtnobs, data = dat)
  a5 <- coef(m5)[["(Intercept)"]]; b5 <- coef(m5)[["fit_ser"]]
  # st_ivreg2 exposes cluster() but not a bare `robust`. The robust VCE is obtained as a
  # post-estimation vcov on the wrapper's own model object, with the wrapper's large-sample
  # profile (.SSC_LARGE: no small-sample adjustment) -- ivreg2's HC0. It is then cross-checked
  # against the sandwich written out by hand from the first-stage fitted regressor.
  V5 <- vcov(m5, vcov = "hetero", ssc = .SSC_LARGE)
  Z  <- cbind(1, dat$invsqrtnobs)
  xhat <- Z %*% solve(crossprod(Z), crossprod(Z, dat$ser))
  e5 <- as.numeric(dat$r - X %*% c(a5, b5))          # residual against ACTUAL ser
  V5_check <- sandwich_check(cbind(1, xhat), e5)
  stopifnot(max(abs(sqrt(diag(V5)) - sqrt(diag(V5_check)))) < 1e-10)
  se5 <- sqrt(diag(V5))

  ## ---- R2 / RMSE as each Stata command prints them --------------------------------------------
  # regress:    R-squared; Root MSE = sqrt(SSR/(N-k)); with [pweight] the weights are normalised
  #             to sum to N (aweight arithmetic) for both.
  # xtreg, fe:  "overall" R-sq = corr(x*b, y)^2 (= corr(x,y)^2 with one regressor, hence equal to
  #             the OLS R2 in both tables); sigma_e = sqrt(within-SSR / (N - N_g - k)).
  # ivreg2:     R-squared from residuals against the actual regressor; Root MSE = sqrt(SSR/N),
  #             no dof adjustment because `small` was not specified.
  r2_1   <- r2(m1, "r2")
  rmse_1 <- sqrt(sum(resid(m1)^2) / (n - 2))

  r2_2   <- cor(dat$r, dat$ser)^2
  rmse_2 <- sqrt(deviance(m2) / (n - ng - 1))

  wn3 <- dat$invperstudy / mean(dat$invperstudy)
  r2_3   <- r2(m3, "r2")
  rmse_3 <- sqrt(sum(wn3 * resid(m3)^2) / (n - 2))

  wn4 <- dat$precr / mean(dat$precr)
  r2_4   <- r2(m4, "r2")
  rmse_4 <- sqrt(sum(wn4 * resid(m4)^2) / (n - 2))

  r2_5   <- 1 - sum(e5^2) / sum((dat$r - mean(dat$r))^2)
  rmse_5 <- sqrt(sum(e5^2) / n)

  ## ---- bootstrap SEs for (1) and (2) ------------------------------------------------------------
  # (1) observation resampling, (2) panel resampling with re-labelled panels (idcluster).
  # Replications where the resample cannot be estimated (e.g. every drawn panel is a singleton,
  # so `ser` is collinear with the fixed effects) are dropped, as Stata's bootstrap drops them.
  boot <- function(B) {
    set.seed(boot_seed)
    ols <- matrix(NA_real_, B, 2)
    for (r_ in seq_len(B)) {
      bd <- dat[sample.int(n, n, replace = TRUE), ]
      bm <- tryCatch(st_regress(r ~ ser, data = bd), error = function(e) NULL)
      if (!is.null(bm)) ols[r_, ] <- c(coef(bm)[["(Intercept)"]], coef(bm)[["ser"]])
    }
    set.seed(boot_seed)
    studies <- unique(dat$idstudy)
    # Row indices of each panel, precomputed once. Assembling a resampled panel by index is
    # identical to rbind-ing the per-study subsets in the same order -- same rows, same order,
    # same seed, therefore the same numbers -- and it turns O(B) data-frame copying into one
    # subset per replication.
    rows_by_study <- lapply(studies, function(s) which(dat$idstudy == s))
    names(rows_by_study) <- as.character(studies)
    sizes <- vapply(rows_by_study, length, 1L)
    fe <- matrix(NA_real_, B, 2)
    for (r_ in seq_len(B)) {
      ss <- sample(studies, ng, replace = TRUE)
      key <- as.character(ss)
      bd <- dat[unlist(rows_by_study[key], use.names = FALSE), ]
      bd$boot_panel <- rep(seq_along(ss), sizes[key])
      bm <- tryCatch(st_xtreg_fe(r ~ ser, data = bd, panel = "boot_panel"), error = function(e) NULL)
      bc <- tryCatch(st_xtreg_fe_cons("r", "ser", "boot_panel", bd), error = function(e) NULL)
      if (!is.null(bm) && !is.null(bc)) fe[r_, ] <- c(coef(bc)[["(Intercept)"]], coef(bm)[["ser"]])
    }
    list(ols_se = apply(ols, 2, sd, na.rm = TRUE), fe_se = apply(fe, 2, sd, na.rm = TRUE),
         ols_dropped = sum(is.na(ols[, 1])), fe_dropped = sum(is.na(fe[, 1])))
  }
  bsm <- boot(boot_mirror_reps)  # literal mirror of the author's reps(50): one noisy draw, log only
  bs  <- boot(boot_reps)         # what the author's estimator converges to: this goes to results.json
  cat(sprintf("[%s] bootstrap reps=%d (author's reps(50), log only)  OLS SE (cons, ser) = %.4f %.4f  FE SE = %.4f %.4f  (dropped: %d / %d)\n",
              label, boot_mirror_reps, bsm$ols_se[1], bsm$ols_se[2], bsm$fe_se[1], bsm$fe_se[2], bsm$ols_dropped, bsm$fe_dropped))
  cat(sprintf("[%s] bootstrap reps=%d (reported)                    OLS SE (cons, ser) = %.4f %.4f  FE SE = %.4f %.4f  (dropped: %d / %d)\n",
              label, boot_reps, bs$ols_se[1], bs$ols_se[2], bs$fe_se[1], bs$fe_se[2], bs$ols_dropped, bs$fe_dropped))

  ## ---- assemble -------------------------------------------------------------------------------
  bias   <- c(c1$estimate[2], b2, c3$estimate[2], c4$estimate[2], b5)
  const  <- c(c1$estimate[1], a2, c3$estimate[1], c4$estimate[1], a5)
  se_b   <- c(bs$ols_se[2], bs$fe_se[2], c3$std.error[2], c4$std.error[2], se5[2])
  se_a   <- c(bs$ols_se[1], bs$fe_se[1], c3$std.error[1], c4$std.error[1], se5[1])
  r2v    <- c(r2_1, r2_2, r2_3, r2_4, r2_5)
  rmsev  <- c(rmse_1, rmse_2, rmse_3, rmse_4, rmse_5)
  cols   <- c("OLS", "FE", "Study", "Precision", "IV")

  for (i in 1:5) {
    add(sprintf("%s %s bias_coef", label, cols[i]), bias[i])
    add(sprintf("%s %s bias_se_boot", label, cols[i]), se_b[i])
    add(sprintf("%s %s const", label, cols[i]), const[i])
    add(sprintf("%s %s const_se_boot", label, cols[i]), se_a[i])
    add(sprintf("%s %s R2", label, cols[i]), r2v[i])
    add(sprintf("%s %s RMSE", label, cols[i]), rmsev[i])
  }
  add(sprintf("%s N", label), n)
  add(sprintf("%s studies", label), ng)

  invisible(NULL)
}

run_battery(d, "T1")
run_battery(subset(d, good == 1), "T2")   # `if good==1`; `good` has no missing values

## ---- the one cell of the two tables that this package does not reproduce -------------------
# Stated in the run's own output, not only in the notes. targets.json is the paper's printed
# table and is not touched; this is the package saying where it disagrees with the paper, and why.
cat("\n===== DISAGREEMENT WITH THE PRINTED TABLE (1 cell of 64) =====\n")
cat(sprintf(
  "Table 2, column (2) FE, RMSE: this package computes %.7f; the paper prints 0.11.\n",
  results[["T2 FE RMSE"]]))
cat("  Stata 15.1 running the author's own line -- xtreg r ser if good==1, fe -- on the site's\n",
    "  published CSV reports sigma_e = .10407703: the same number, and it rounds to 0.10.\n",
    "  The identical convention gives 0.12 for the Table 1 FE column, which is what the paper\n",
    "  prints there, and Table 2's other four RMSE cells reproduce. The printed 0.11 equals the\n",
    "  neighbouring OLS cell (.10521271), and the FE value sits 0.0011 under the 0.105 rounding\n",
    "  boundary. It reads as a hand-transcription slip: esttab ran with no stats() option, so it\n",
    "  printed only N and the R2/RMSE rows were copied off the screen. Left as it falls.\n",
    sep = "")

cat("\n===== Produced results (label -> value) =====\n")
for (nm in names(results)) cat(sprintf("%-28s %s\n", nm, format(results[[nm]], digits = 6)))

write_json(results, "results.json", auto_unbox = TRUE, digits = 10)
cat("\nWrote results.json with", length(results), "labeled values.\n")

stata_compat_log()
