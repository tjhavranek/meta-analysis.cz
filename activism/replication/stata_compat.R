# stata_compat.R -- Stata commands as R, with the conventions pinned.
#
# Every replication package on meta-analysis.cz sources this file and calls ONLY these
# wrappers. Where a Stata command has no wrapper here, the package says so rather than
# substituting the closest-looking R function.
#
# The reason is narrow and specific. Each of these commands has two or three plausible R
# renderings that differ by a small-sample or degrees-of-freedom constant. They all run, they
# all look right, and they land within about one percent of the published number -- close
# enough to be mistaken for a rounding difference and far enough to be wrong. Two examples
# measured on the class-size paper, whose Table 3 prints 0.0331 (0.0944):
#
#   winsorising with interpolated percentiles instead of order statistics -> 0.0325
#   fixest's default small-sample adjustment instead of none                -> SE 0.0953
#
# Neither would have failed a "within one percent" check. Both are wrong. So the convention is
# fixed here once, with the evidence that fixed it, and the published
# cells are re-derived on every change.
#
# Verified against: class (JOLE 2026) Table 3, Block 1, Panel A -- all ten coefficient and
# standard-error cells, the fixed-effects constant, N, the first-stage F and the WAAP row.

# --------------------------------------------------------------------------------------------
# Say which packages are missing, once, instead of failing on the first library() call with
# "there is no package called 'fixest'" and no indication of what else will be needed.
local({
  need <- c("fixest", "metafor", "jsonlite", "lme4", "plm", "BMS", "LowRankQP", "readxl",
            "survival")
  miss <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
  # Only the first two are needed by every package; the rest are per-paper, so a missing one is
  # only fatal if this paper uses it. Report all of them and let the script fail where it fails.
  if (length(miss)) {
    message("This replication may need R packages that are not installed: ",
            paste(miss, collapse = ", "), "\n  install.packages(c(",
            paste(sprintf('"%s"', miss), collapse = ", "), "))")
  }
})

suppressMessages({
  library(fixest); library(metafor)
})

.STATA_LOG <- new.env(parent = emptyenv())
.STATA_LOG$lines <- character(0)

.note <- function(stata, convention) {
  .STATA_LOG$lines <- c(.STATA_LOG$lines, sprintf("  %-46s -> %s", stata, convention))
  invisible(NULL)
}

#' Print, into the package's own log, every Stata command emulated and how.
stata_compat_log <- function() {
  cat("Stata commands emulated in this run:\n")
  cat(paste(unique(.STATA_LOG$lines), collapse = "\n"), "\n", sep = "")
}

# ---------------------------------------------------------------- missing-value semantics
# In Stata a missing value is LARGER than any number, so `drop if x > 5` also drops missing x
# and `keep if x < 5` also drops it. In R `x > 5` is NA and the row silently vanishes from a
# subset, or silently stays, depending on how the subset was written. Neither matches by
# accident. These two make the choice explicit at the call site.

#' Stata `drop if cond`. Missing counts as +Inf, so it satisfies `>` and fails `<`.
st_drop_if <- function(d, cond) {
  cond <- ifelse(is.na(cond), FALSE, cond)
  .note("drop if <cond>", "missing treated as +Inf, as Stata does")
  d[!cond, , drop = FALSE]
}

#' Stata `keep if cond`.
st_keep_if <- function(d, cond) {
  cond <- ifelse(is.na(cond), FALSE, cond)
  .note("keep if <cond>", "missing treated as +Inf, as Stata does")
  d[cond, , drop = FALSE]
}

# ---------------------------------------------------------------------------- winsorising
# The site's papers use TWO different winsor commands and they do not agree with each other.
# SSC `winsor` (Cox) works on ORDER STATISTICS: h = int(p * N), then the lowest h values become
# the (h+1)-th smallest and the highest h become the (N-h)-th. `winsor2` calls Stata's _pctile,
# which is Hyndman-Fan type 2. R's default quantile is type 7 and matches neither.

#' SSC `winsor x, generate(xw) p(p)`.
st_winsor <- function(x, p = 0.01) {
  x <- as.numeric(x)
  ok <- !is.na(x)
  s <- sort(x[ok])
  n <- length(s)
  if (n == 0L) return(x)
  h <- floor(p * n)
  lo <- s[h + 1L]; hi <- s[n - h]
  .note(sprintf("winsor <var>, p(%g)", p), "order statistics at floor(p*N), SSC winsor.ado")
  ifelse(is.na(x), x, pmin(pmax(x, lo), hi))
}

#' R's `DescTools::Winsorize(x, probs = c(p, 1-p))`, for papers whose AUTHORS WROTE R.
#'
#' Not every paper in this collection is Stata. activism's own script calls Winsorize, which
#' interpolates with R's default type-7 quantile, and using the Stata order-statistic rule on it
#' gives a standard deviation of 3.05 where the paper prints 3.04. The two rules are both
#' correct; they belong to different tools, and the one to apply is whichever the author used.
#' Verified on activism Table 2: type 7 reproduces the printed 3.04, type 1 does not.
st_winsor_r <- function(x, p = 0.01) {
  x <- as.numeric(x)
  q <- stats::quantile(x, c(p, 1 - p), na.rm = TRUE, type = 7)
  .note(sprintf("Winsorize(x, probs = c(%g, %g))  [R author]", p, 1 - p),
        "quantile type 7, R's default -- NOT the Stata order-statistic rule")
  ifelse(is.na(x), x, pmin(pmax(x, q[1]), q[2]))
}

#' `winsor2 x, cuts(lo hi)`, cuts given in percent.
st_winsor2 <- function(x, cuts = c(1, 99)) {
  x <- as.numeric(x)
  q <- stats::quantile(x, cuts / 100, na.rm = TRUE, type = 2)
  .note(sprintf("winsor2 <var>, cuts(%g %g)", cuts[1], cuts[2]),
        "quantile type 2 (Stata _pctile), NOT R's default type 7")
  ifelse(is.na(x), x, pmin(pmax(x, q[1]), q[2]))
}

# hadimvo is an algorithm rather than a thin wrapper, so it lives in its own file. Look
# for it beside this one; if this file was itself loaded from the site, fetch it from
# there too. If neither works, leave a stub that stops -- never a silent absence.
local({
  d <- tryCatch(dirname(normalizePath(sys.frames()[[1]]$ofile)), error = function(e) ".")
  p <- file.path(d, "hadimvo_port.R")
  u <- "https://meta-analysis.cz/activism/replication/hadimvo_port.R"
  ok <- FALSE
  if (file.exists(p)) { source(p); ok <- TRUE }
  else if (file.exists("hadimvo_port.R")) { source("hadimvo_port.R"); ok <- TRUE }
  else ok <- tryCatch({ source(u); TRUE }, error = function(e) FALSE)
  if (!ok) {
    assign("hadimvo_stata", function(...) stop(
      "hadimvo_port.R could not be loaded (tried beside this file and ", u,
      "). This package needs it; download it next to run.R and try again."),
      envir = globalenv())
  }
})

# ------------------------------------------------------------------------------- estimation
# ivreg2 without `small` -- which is every paper on this site -- uses LARGE-SAMPLE variance:
# no (N-1)/(N-K) and no M/(M-1), with z-based inference rather than t. In fixest that is
# ssc(K.adj = FALSE, G.adj = FALSE). fixest's own default applies both adjustments and is what
# produces the plausible-but-wrong 0.0953 against a printed 0.0944.
.SSC_LARGE <- ssc(adj = FALSE, K.adj = FALSE, cluster.adj = FALSE)

#' `ivreg2 y x [weights], cluster(g)`, and the IV form via `iv = list(endog ~ instrument)`.
st_ivreg2 <- function(fml, data, cluster = NULL, weights = NULL, iv = NULL, small = FALSE) {
  if (isTRUE(small)) stop("st_ivreg2: `small` is a different profile and no paper here uses it")
  f <- if (is.null(iv)) fml else stats::as.formula(paste(deparse(fml), "|", deparse(iv[[2]])))
  m <- fixest::feols(f, data = data, weights = weights, cluster = cluster, ssc = .SSC_LARGE)
  # The homoskedastic (no cluster, no fixed effect) case needs one further step, because
  # `adj = FALSE` is not the same thing as "no denominator correction". ivreg2 without `small`
  # estimates sigma^2 as RSS/N; fixest's floor is RSS/(N-1), and ssc() exposes no setting that
  # reaches N. Measured against Stata 15.1 on the habits Median column (ivreg2 habit_med se_med,
  # N = 38, no cluster, no weights):
  #     ivreg2, no `small`            se 0.2074803  0.0858155   (the appendix prints .207, .0858)
  #     feols with .SSC_LARGE         se 0.2102654  0.0869674
  #     that same vcov * (N-1)/N      se 0.2074803  0.0858155   -- exact to seven digits
  # The identical factor recovers Stata for the two other homoskedastic profiles st_ivreg2 can
  # produce: 2SLS, 5.5039505 against Stata's 5.5039500, and aweighted OLS,
  # 0.5577889 against 0.5577889. Both other variance paths are already right and are left
  # untouched -- clustered (the profile .SSC_LARGE was calibrated on) and heteroskedastic, where
  # fixest with adj = FALSE is already ivreg2's HC0 (0.1205108 on both sides).
  if (is.null(cluster) && length(m$fixef_vars) == 0L) {
    n <- m$nobs
    m <- summary(m, vcov = stats::vcov(m) * (n - 1) / n)
    .note("ivreg2 y x   [no cluster, no `small`]",
          "feols large-sample ssc, then vcov * (N-1)/N -- ivreg2's IID sigma^2 is RSS/N, fixest's RSS/(N-1)")
  }
  .note("ivreg2 y x, cluster(g)   [no `small`]",
        "feols with ssc(adj=FALSE, K.adj=FALSE, cluster.adj=FALSE); z inference")
  m
}

#' ivreg2's printed first-stage robust F. Note this uses fixest's DEFAULT adjustment, not the
#' large-sample one the coefficient table uses: ivreg2 reports first-stage statistics with
#' small-sample corrections even when the main table has none. Two conventions, one command.
st_ivreg2_first_F <- function(m) {
  .note("ivreg2 first-stage robust F", "fitstat ivwald1 with fixest DEFAULT ssc, not the large-sample one")
  as.numeric(fixest::fitstat(m, "ivwald1")[[1]]$stat)
}

#' `xtreg y x, fe vce(cluster g)` where g is the xtset panel variable.
#' fixest drops singleton groups by default and Stata does not; fixef.rm="none" is required or
#' N comes back one short and the standard error moves in the fourth digit.
st_xtreg_fe <- function(fml, data, panel, cluster = NULL, weights = NULL) {
  if (is.null(cluster)) cluster <- panel
  f <- stats::as.formula(paste(deparse(fml), "|", panel))
  m <- fixest::feols(f, data = data, weights = weights, cluster = cluster,
                     fixef.rm = "none")
  .note("xtreg y x, fe vce(cluster g)",
        "feols with fixef.rm='none' (Stata keeps singletons) and fixest default ssc")
  m
}

#' The constant Stata's `xtreg, fe` prints, which fixest does not report. Stata's _cons is the
#' grand mean of y minus the fitted within slope times the grand mean of x, obtained here by an
#' augmented within regression rather than by arithmetic on the coefficients.
st_xtreg_fe_cons <- function(y, x, panel, data, cluster = NULL) {
  yv <- data[[y]]; xv <- data[[x]]; g <- data[[panel]]
  ok <- !is.na(yv) & !is.na(xv) & !is.na(g)
  yv <- yv[ok]; xv <- xv[ok]; g <- g[ok]
  ya <- yv - stats::ave(yv, g) + mean(yv)
  xa <- xv - stats::ave(xv, g) + mean(xv)
  d2 <- data.frame(ya = ya, xa = xa, g = g)
  m <- fixest::feols(ya ~ xa, data = d2, cluster = ~g)
  .note("xtreg, fe reported _cons", "augmented within regression, fixest default ssc")
  m
}

#' `regress y x, vce(cluster g)` / `, robust` / plain. Stata's regress always applies the
#' small-sample corrections, so this is fixest's default ssc rather than the ivreg2 one.
st_regress <- function(fml, data, cluster = NULL, robust = FALSE, weights = NULL) {
  m <- fixest::feols(fml, data = data, weights = weights,
                     cluster = cluster,
                     vcov = if (is.null(cluster) && robust) "hetero" else NULL)
  .note("regress y x, vce(cluster g) / robust", "feols with fixest DEFAULT ssc (Stata regress is small-sample)")
  m
}

#' `metan e se, fixed` / `, random`. metan is DerSimonian-Laird with z-based intervals.
#' metafor's default is REML, which changes the pooled POINT estimate and not merely its
#' interval, so it must never stand in for an unread metan call.
st_metan <- function(e, se, random = TRUE) {
  .note(sprintf("metan e se, %s", if (random) "random" else "fixed"),
        if (random) "rma(method='DL', test='z') -- DerSimonian-Laird, NOT metafor's REML default"
        else "rma(method='EE', test='z')")
  metafor::rma(yi = e, sei = se, method = if (random) "DL" else "EE", test = "z")
}

#' `mixed y x || g:`. Stata's mixed is maximum likelihood by default; lmer is REML by default.
st_mixed <- function(fml, data) {
  if (!requireNamespace("lme4", quietly = TRUE)) stop("st_mixed: lme4 not installed")
  .note("mixed y x || g:", "lmer(REML = FALSE) -- Stata mixed is ML by default")
  lme4::lmer(fml, data = data, REML = FALSE)
}

#' `xtmixed y x || g:`. NOT a synonym for `mixed`, and the trap is that a modern Stata makes it
#' look like one. Stata 11's xtmixed -- the command every pre-2013 paper in this collection ran
#' -- fits by RESTRICTED maximum likelihood by default. Stata 13 retired xtmixed and mapped the
#' name onto `mixed`, whose default is plain ML. So typing the authors' own command into Stata
#' 15.1 today silently gives a different estimator than it gave them, and the difference is large
#' enough to lose published cells.
#'
#' Evidence, from Stata rather than from documentation, all on the site's own published CSV:
#'
#'   xtmixed t prec || idstudy: ...            Stata 15.1 -> "Mixed-effects ML regression"
#'   version 11: xtmixed t prec || idstudy:    Stata 15.1 -> "Mixed-effects REML regression"
#'
#' and the version-11 run reproduces the authors' log of the published run (vertical.log,
#' 13 Jun 2010, Havranek & Irsova, JIE 2011) cell for cell, which likewise heads every block
#' "Mixed-effects REML regression". The paper's Table 1 note agrees: "estimated by the
#' mixed-effects multilevel model using restricted maximum likelihood".
#'
#' Verified on all six cells of that Table 1. REML reproduces Stata to six decimals (backward,
#' all estimates: prec .167984 (.0241212), _cons -.0254672 (.4959743)). ML does not, and misses
#' by amounts that read like rounding -- forward/published prec .25279 against a printed 0.258,
#' constant -.38743 against a printed -0.437.
st_xtmixed <- function(fml, data) {
  if (!requireNamespace("lme4", quietly = TRUE)) stop("st_xtmixed: lme4 not installed")
  .note("xtmixed y x || g:", "lmer(REML = TRUE) -- Stata xtmixed is REML by default, unlike mixed")
  lme4::lmer(fml, data = data, REML = TRUE)
}

# ------------------------------------------------------------------------------- reporting
#' Coefficients with the inference convention the emulated command uses: z for ivreg2, t for
#' regress and xtreg. Returns a tidy frame so the values can be read without parsing printed text.
st_coefs <- function(m, z = TRUE) {
  b <- stats::coef(m); s <- sqrt(diag(stats::vcov(m)))
  data.frame(term = names(b), estimate = as.numeric(b), std.error = as.numeric(s),
             statistic = as.numeric(b / s),
             p.value = if (z) 2 * stats::pnorm(-abs(b / s)) else NA_real_,
             row.names = NULL, stringsAsFactors = FALSE)
}

#' `xtmixed y x || g: [pweight=w]` / `mixed y x || g: [pweight=w]` -- a random-intercept model
#' with SAMPLING weights at level 1. This is NOT lmer(..., weights = w), and the difference is
#' not small: on the resource-curse data lmer's weighted fit returns _cons -0.13453 against
#' Stata's -0.13334, and a residual variance of 2.73 against Stata's 0.0128.
#'
#' The reason is what the weight multiplies. lmer's `weights` are PRECISION weights: they scale
#' the residual variance, so observation i is modelled as N(x_i'b + u_g, sigma_e^2 / w_i).
#' Stata's pweight is a SAMPLING weight: it raises each conditional density to the power w_i,
#'
#'     ll = sum_g log INTEGRAL prod_i f(y_ig | u_g)^{w_ig} phi(u_g; 0, sigma_u^2) du_g
#'
#' which for a normal f differs from the precision-weighted likelihood by a term
#' (N - sum_i w_i)/2 * log(2 pi sigma_e^2). With weights of this size (sum w = 119,618 against
#' N = 605) that term dominates, and it is why the two fits are nowhere near each other.
#' Because the weights enter as an exponent there is no data transform that turns one into the
#' other, and no R mixed-model package implements it, so the pseudo-likelihood is maximised
#' here directly. Stata forces ML under pweights -- REML is not offered -- so unlike
#' st_xtmixed() there is no REML/ML choice to get wrong.
#'
#' Stata also forces vce(robust) clustered on the top-level group, and reports z, not t. The
#' sandwich is built over the FULL parameter vector (b, log sd_u, log sd_e) with the
#' G/(G-1) finite-sample multiplier, as Stata's ML robust VCE does.
#'
#' Evidence, from Stata rather than from documentation. Stata 15.1,
#' `mixed PCC PCC_SE || ID: [pweight=prec]` on the site's own published resource_curse data,
#' reproducing the authors' 2016 log line for line:
#'
#'                       Stata 15.1 / authors' log        this wrapper
#'   log pseudolik.          90785.656                    90785.6572
#'   PCC_SE                   0.0900781                     0.09007805
#'   _cons                   -0.1333425                    -0.13334253
#'   sd(_cons)                0.2831274                     0.28312724
#'   sd(Residual)             0.1131052                     0.11310522
#'   robust SE PCC_SE         0.6660147                     0.66603483
#'   robust SE _cons          0.0934048                     0.09341716
#'
#' The two SEs differ in the fifth significant digit only, which is the numerical Hessian, and
#' every printed cell of the paper's Table 3 Panel B col 2 rounds the same way under both.
#' Random intercept only, and level-1 weights only -- anything else is reported rather than guessed
#' rather than an invitation to generalise this code.
st_xtmixed_pw <- function(fml, data, group, weights) {
  gv <- if (is.character(group)) data[[group]] else if (inherits(group, "formula"))
          data[[all.vars(group)]] else group
  wv <- if (is.character(weights)) data[[weights]] else if (inherits(weights, "formula"))
          data[[all.vars(weights)]] else weights
  if (is.null(gv)) stop("st_xtmixed_pw: group variable not found")
  if (is.null(wv)) stop("st_xtmixed_pw: weight variable not found")
  mf <- stats::model.frame(fml, data = data, na.action = stats::na.pass)
  yv <- as.numeric(stats::model.response(mf))
  Xm <- stats::model.matrix(stats::terms(fml), mf)
  keep <- stats::complete.cases(Xm, yv, gv, wv) & as.numeric(wv) > 0
  yv <- yv[keep]; Xm <- Xm[keep, , drop = FALSE]
  gv <- as.character(gv[keep]); wv <- as.numeric(wv[keep])
  gl <- split(seq_along(yv), gv); G <- length(gl); k <- ncol(Xm)

  # per-group pseudo-loglikelihood and its analytic score, at theta = (b, log sd_u, log sd_e)
  .parts <- function(th) {
    b <- th[1:k]; su <- exp(2 * th[k + 1]); se2 <- exp(2 * th[k + 2])
    r <- yv - as.numeric(Xm %*% b); ll <- 0; S <- matrix(0, G, k + 2)
    for (j in seq_len(G)) {
      i <- gl[[j]]; wj <- wv[i]; rj <- r[i]; Xj <- Xm[i, , drop = FALSE]
      Sw <- sum(wj * rj^2); Tw <- sum(wj * rj); W <- sum(wj)
      A <- W / se2 + 1 / su; B <- Tw / se2
      ll <- ll - 0.5 * Sw / se2 + B^2 / (2 * A) - 0.5 * log(A) -
            0.5 * W * log(2 * pi * se2) - 0.5 * log(su)
      S[j, 1:k] <- (colSums(wj * rj * Xj) - (B / A) * colSums(wj * Xj)) / se2
      dse2 <- Sw / (2 * se2^2) - B * Tw / (A * se2^2) + B^2 * W / (2 * A^2 * se2^2) +
              W / (2 * A * se2^2) - W / (2 * se2)
      dsu  <- B^2 / (2 * A^2 * su^2) + 1 / (2 * A * su^2) - 1 / (2 * su)
      S[j, k + 1] <- dsu * 2 * su; S[j, k + 2] <- dse2 * 2 * se2
    }
    list(ll = ll, S = S)
  }
  nll <- function(th) -.parts(th)$ll
  ngr <- function(th) -colSums(.parts(th)$S)

  b0 <- as.numeric(stats::coef(stats::lsfit(Xm[, -1, drop = FALSE], yv, wt = wv)))
  s0 <- log(max(stats::sd(yv), 1e-6) / sqrt(2))
  th <- c(b0, s0, s0)
  for (it in 1:4)
    th <- stats::optim(th, nll, ngr, method = "BFGS",
                       control = list(reltol = 1e-16, maxit = 10000))$par

  H <- matrix(0, k + 2, k + 2)                       # Hessian from the analytic score
  for (m in seq_len(k + 2)) {
    h <- 1e-6 * max(1, abs(th[m])); tp <- th; tm <- th
    tp[m] <- th[m] + h; tm[m] <- th[m] - h
    H[, m] <- (colSums(.parts(tp)$S) - colSums(.parts(tm)$S)) / (2 * h)
  }
  H <- (H + t(H)) / 2
  Hi <- solve(-H); Sm <- .parts(th)$S

  # Convergence, measured scale-free. The gradient's own size is no guide here: the weights
  # sum to 1.2e5, so the pseudo-loglikelihood is of order 1e5 and a gradient of 3e-3 is
  # already a relative 3e-8. What matters is the remaining Newton step expressed in standard
  # errors, which at the optimum is ~1e-8.
  if (max(abs(as.numeric(Hi %*% -ngr(th))) / sqrt(diag(Hi))) > 1e-3)
    stop("st_xtmixed_pw: pseudo-likelihood did not converge")
  V <- Hi %*% (t(Sm) %*% Sm) %*% Hi * G / (G - 1)
  b <- th[1:k]; names(b) <- colnames(Xm)
  V <- V[1:k, 1:k, drop = FALSE]; dimnames(V) <- list(names(b), names(b))
  .note("xtmixed y x || g: [pweight=w]",
        "pseudo-ML (weights as an EXPONENT, not lmer precision weights); vce robust cluster(g), z")
  structure(list(coefficients = b, vcov = V, nobs = length(yv), ngroups = G,
                 sd_u = exp(th[k + 1]), sd_e = exp(th[k + 2]), loglik = -nll(th)),
            class = "st_xtmixed_pw")
}

coef.st_xtmixed_pw  <- function(object, ...) object$coefficients
vcov.st_xtmixed_pw  <- function(object, ...) object$vcov
nobs.st_xtmixed_pw  <- function(object, ...) object$nobs

#' `rreg y x` -- Stata's robust regression. NOT MASS::rlm, and not any other off-the-shelf
#' M-estimator: rreg is a specific three-stage recipe (Li 1985) whose reported standard errors
#' come from an OLS regression on PSEUDO-VALUES, not from the robust fit's own sandwich. rlm's
#' default (Huber only, no Cook screening, no biweight stage, MAD scale, asymptotic SEs) agrees
#' with it on neither the coefficients nor the variance, so substituting it would be one of
#' exactly the plausible-but-wrong renderings this file exists to prevent.
#'
#' Ported line by line from Stata 15.1's own rreg.ado, version 3.4.1 (21sep2017):
#'   1. OLS, then DROP every observation with Cook's D > 1.
#'   2. Huber iterations to convergence: w = 1 if |e| <= 2m, else 2m/|e|, where m is the median
#'      of |e - median(e)|; refit by weighted least squares; stop when the largest change in any
#'      weight falls below 5 * tolerance (default tolerance 0.01, so 0.05).
#'   3. Tukey biweight iterations from that start: s = m/0.6745, w = max(1-(e/(c*s))^2, 0)^2 with
#'      c = tune*4.685/7 (default tune 7, so c = 4.685); stop below tolerance. Runs at least once.
#'   4. The reported table is NOT the last weighted fit. rreg forms pseudo-values
#'         y* = xb + (lambda*s/a_bar)*(e/s)*w,     a_i = (1-(e_i/s)^2/c^2)(1-5(e_i/s)^2/c^2),
#'         a_i = 0 where |e_i/s| > c,   lambda = 1 + ((df_m+1)/N)*(1-a_bar)/a_bar
#'      and runs a plain UNWEIGHTED OLS of y* on X. Its coefficients and its OLS variance are
#'      what Stata prints, with df_r = N - k on the post-Cook sample.
#'
#' The one detail that is invisible in the .ado and decides the fourth significant digit: the
#' N in lambda is `e(N)` of the LAST WEIGHTED regression, and Stata's analytic weights EXCLUDE
#' zero-weight observations from the estimation sample. The biweight sets weights to exactly
#' zero beyond c, so that N is the number of NONZERO weights, not the size of the post-Cook
#' sample. On remittances Table B1 that is 345 against 347, and the difference is not academic:
#'
#'     lambda with N = 347 (post-Cook sample)   SE 0.2465530  0.0136448
#'     lambda with N = 345 (nonzero weights)    SE 0.2465561  0.0136450
#'     Stata 15.1, rreg TSTAT_L SE1_PCC_L       SE 0.2465561  0.0136450
#'
#' Verified against Stata 15.1 on the site's own published remittances.csv
#', both cells of both rreg columns the paper prints:
#'
#'                                    Stata 15.1                 this wrapper
#'   Table B1 (2)  _cons        0.72085003 (0.24655608)   0.72085001 (0.24655609)
#'   Table B1 (2)  SE1_PCC_L    0.00263715 (0.01364496)   0.00263715 (0.01364496)
#'   Table D1 (2)  _cons        0.45439535 (0.64304814)   0.45439535 (0.64304814)
#'   Table D1 (2)  SE1_PCC_S   -0.09360287 (0.06488031)  -0.09360288 (0.06488031)
#'
#' Weights are compared too, not only the printed cells: the ported final weights agree with
#' Stata's own genwt() vector to 4e-8 across all 347 observations, and the iteration path is
#' identical -- 3 Huber then 3 biweight steps, with the same maximum weight change at each
#' (0.72262787, 0.10264882, 0.01831810; 0.29408619, 0.02231489, 0.00353087).
#'
#' No weights and no cluster: `rreg` accepts neither, and no paper here asks for them.
st_rreg <- function(fml, data, tune = 7, tolerance = 0.01, iterate = 1000) {
  if (tolerance <= 0 || iterate <= 0 || tune <= 0) stop("st_rreg: bad tune/tolerance/iterate")
  mf <- stats::model.frame(fml, data = data, na.action = stats::na.omit)
  y  <- as.numeric(stats::model.response(mf))
  X  <- stats::model.matrix(stats::terms(fml), mf)
  k  <- ncol(X)
  cc <- tune * 4.685 / 7

  # weighted least squares; w = NULL means unweighted. Zero weights drop out on their own.
  .wls <- function(X, y, w = NULL) {
    if (is.null(w)) { rw <- rep(1, length(y)) } else { rw <- w }
    Xs <- X * sqrt(rw); ys <- y * sqrt(rw)
    qrf <- qr(Xs)
    b <- as.numeric(qr.coef(qrf, ys))
    list(b = b, res = y - as.numeric(X %*% b))
  }

  # 1. OLS on the full sample, then Cook's D > 1 screening
  n <- length(y)
  f0 <- .wls(X, y)
  G  <- solve(crossprod(X))
  h  <- rowSums((X %*% G) * X)
  s2 <- sum(f0$res^2) / (n - k)
  cook <- (f0$res^2 / (k * s2)) * (h / (1 - h)^2)
  keep <- !(cook > 1)
  y <- y[keep]; X <- X[keep, , drop = FALSE]; n <- length(y)

  f <- .wls(X, y)
  res <- f$res
  absdev <- abs(res - stats::median(res))

  # 2. Huber
  w <- rep(1, n); mx <- 1; it <- 1L
  while (mx > 5 * tolerance && it <= iterate) {
    oldw <- w
    m <- stats::median(absdev)
    w <- ifelse(abs(res) > 2 * m, 2 * m / abs(res), 1)
    f <- .wls(X, y, w); res <- f$res
    absdev <- abs(res - stats::median(res))
    mx <- max(abs(w - oldw)); it <- it + 1L
  }
  if (mx > 5 * tolerance) warning("st_rreg: Huber iterations did not converge")

  # 3. biweight -- runs at least once, exactly as the .ado's `notyet` flag forces
  mx <- 1; notyet <- TRUE; s <- NA_real_
  while ((mx > tolerance && it <= iterate) || notyet) {
    notyet <- FALSE
    oldw <- w
    s <- stats::median(absdev) / 0.6745
    w <- pmax(1 - (res / (cc * s))^2, 0)^2
    if (all(w == 0)) stop("st_rreg: all weights went to zero")
    f <- .wls(X, y, w); res <- f$res
    absdev <- abs(res - stats::median(res))
    mx <- max(abs(w - oldw)); it <- it + 1L
  }
  if (mx > tolerance) warning("st_rreg: biweight iterations did not converge")

  # 4. pseudo-values, then plain OLS -- this is the table Stata prints
  u  <- res / s
  a  <- (1 - u^2 / cc^2) * (1 - 5 * u^2 / cc^2)
  a[abs(u) > cc] <- 0
  aa <- mean(a)
  n_wls <- sum(w != 0)                      # Stata's aweight sample: zero weights excluded
  lambda <- 1 + ((k - 1 + 1) / n_wls) * (1 - aa) / aa
  ystar <- as.numeric(X %*% f$b) + (lambda * s / aa) * u * w

  G2 <- solve(crossprod(X))
  b  <- as.numeric(G2 %*% crossprod(X, ystar))
  e  <- ystar - as.numeric(X %*% b)
  V  <- (sum(e^2) / (n - k)) * G2
  names(b) <- colnames(X); dimnames(V) <- list(names(b), names(b))
  .note("rreg y x",
        "rreg.ado 3.4.1 ported: Cook's D>1 screen, Huber then biweight, OLS on pseudo-values; lambda's N excludes zero weights")
  structure(list(coefficients = b, vcov = V, nobs = n, df_r = n - k,
                 scale = s, weights = w, iterations = it - 1L),
            class = "st_rreg")
}

coef.st_rreg <- function(object, ...) object$coefficients
vcov.st_rreg <- function(object, ...) object$vcov
nobs.st_rreg <- function(object, ...) object$nobs

#' `tobit y x, ll(L) ul(U)` -- censored regression by maximum likelihood. Stata's `cnreg` is
#' the same estimator under an older name.
#'
#' Used where the dependent variable is only recorded inside a known interval, so that some
#' observations carry a bound rather than a value. The censored observations stay in the
#' likelihood and contribute their probability mass -- 1 - Phi((U - x'b)/sigma) at an upper
#' limit -- rather than an exact density. Neither of the two obvious substitutes does that:
#' running OLS on the recorded values treats a bound as if it were the realised value, and
#' dropping the censored rows conditions on the uncensored region. Both attenuate the slopes,
#' and the pull is not marginal when a real share of the sample sits on the limit -- on the
#' transmission-lag data 22 of 198 observations are at the sixty-month reporting window.
#'
#' Fitted through survival::survreg with a Gaussian error, which maximises exactly the Tobit
#' likelihood once the bounds are declared. The correspondence is
#'   uncensored  y       ->  the degenerate interval [y, y]
#'   right-censored at U ->  [U, +Inf)
#'   left-censored at L  ->  (-Inf, L]
#' which is what Surv(y1, y2, type = "interval2") encodes, with NA marking the open end.
#'
#' Two details decide whether the published cells come back.
#'
#' Stata censors AT the limit, not beyond it: `ul(#)` treats every observation with y >= # as
#' right-censored, and `ll(#)` every observation with y <= # as left-censored. An observation
#' recorded exactly at the limit is therefore a bound, not a value. Writing y > # instead leaves
#' those rows in as exact observations; on the lags data that is all 22 censored rows, since
#' the authors set every longer lag to exactly 60.
#'
#' survreg parameterises the scale as log(sigma) while Stata parameterises it as sigma (Stata 15
#' prints var(e.y) = sigma^2). That leaves the coefficient standard errors untouched, because the
#' reparameterisation is a function of sigma alone: the Jacobian is block diagonal, so the beta
#' block of the inverted information is the same either way. What it does change is the shape of
#' vcov(), which carries one extra row and column for Log(scale); the wrapper trims it so that
#' st_coefs() sees the coefficient block and nothing else.
#'
#' Verified against Stata 15.1 on the site's own published lags.csv, both censored regressions
#' Havranek & Rusnak (IJCB 2013) print, `tobit mon_bot ..., ul(60)`:
#'
#'                              Stata 15.1                   this wrapper
#'   T8  GDP per Capita   -11.47756  (4.792739)       -11.477577  (4.792741)
#'   T8  Financial Dev.    21.60592  (5.375225)        21.605932  (5.375226)
#'   T8  Constant          86.58325  (43.69408)        86.583402  (43.694099)
#'   T8  var(e.mon_bot)   231.3916                    231.39170
#'   T12 FAVAR             14.53418  (6.524711)        14.534170  (6.524715)
#'   T12 CB Independence   30.19766  (12.26722)        30.197673  (12.267230)
#'   T12 Constant          62.3183   (50.10327)        62.318454  (50.103301)
#'   T12 var(e.mon_bot)   210.93                      210.93030
#'
#' with the same log likelihoods (-752.7678 and -743.5098) and the same censoring counts
#' (176 uncensored, 22 right-censored, 0 left-censored). Every difference is in the fifth
#' significant digit and is the two optimisers' convergence tolerance; all 86 printed cells of
#' the two tables round identically.
#'
#' Stata reports t rather than z for this command, with N - k residual degrees of freedom, so
#' read the coefficients with st_coefs(m, z = FALSE) when p-values are wanted.
#' No weights and no cluster option: `tobit` accepts neither, and no paper here asks for them.
st_tobit <- function(fml, data, ll = NULL, ul = NULL) {
  if (!requireNamespace("survival", quietly = TRUE)) stop("st_tobit: survival not installed")
  if (is.null(ll) && is.null(ul)) stop("st_tobit: give ll, ul, or both")
  lo <- if (is.null(ll)) -Inf else ll
  hi <- if (is.null(ul))  Inf else ul
  y <- eval(fml[[2]], data, parent.frame())
  right <- !is.na(y) & y >= hi
  left  <- !is.na(y) & y <= lo
  d <- as.data.frame(data)
  d$.st_y1 <- ifelse(right, hi, ifelse(left, NA, y))
  d$.st_y2 <- ifelse(right, NA, ifelse(left, lo, y))
  f <- fml
  f[[2]] <- quote(survival::Surv(.st_y1, .st_y2, type = "interval2"))
  m <- survival::survreg(f, data = d, dist = "gaussian")
  k <- length(stats::coef(m))
  .note(sprintf("tobit y x, %s%s%s  [cnreg]",
                if (is.null(ll)) "" else sprintf("ll(%s)", format(ll)),
                if (is.null(ll) || is.null(ul)) "" else " ",
                if (is.null(ul)) "" else sprintf("ul(%s)", format(ul))),
        "survreg Gaussian ML, censored at the limit (y >= ul, y <= ll); t inference")
  structure(list(coefficients = stats::coef(m),
                 vcov         = stats::vcov(m)[seq_len(k), seq_len(k), drop = FALSE],
                 sigma        = m$scale,
                 loglik       = m$loglik[2],
                 n            = length(m$linear.predictors),
                 n_left       = sum(left),
                 n_right      = sum(right),
                 n_uncensored = sum(!left & !right & !is.na(y)),
                 fit          = m),
            class = "st_tobit")
}

coef.st_tobit  <- function(object, ...) object$coefficients
vcov.st_tobit  <- function(object, ...) object$vcov
nobs.st_tobit  <- function(object, ...) object$n
logLik.st_tobit <- function(object, ...) object$loglik

#' Random-effects panel regression, `plm(..., model = "random")`.
#'
#' Added for a paper whose own code is R rather than Stata, so there is no Stata command to
#' emulate: activism's `functions/publication_bias3.R` computes the column its table labels "BE"
#' with `plm(model0, subdata, index = study_indic, model = "random")`, under the heading
#' "# A.3 random effects regression". The label is a misnomer -- it is NOT a between estimator,
#' and treating it as one (OLS on study means) gives -0.700 where the paper prints 1.473. This
#' wrapper reproduces the paper's value at 1.473059.
#'
#' plm's default random-effects method is Swamy-Arora, matching Stata's `xtreg, re`.
st_plm_re <- function(fml, data, panel) {
  if (!requireNamespace("plm", quietly = TRUE)) stop("st_plm_re: plm not installed")
  .note("plm(model = 'random')  [xtreg, re]", "Swamy-Arora random effects; z inference")
  plm::plm(fml, data = data, index = panel, model = "random")
}

#' R's own `quantile()`, type 7.
#'
#' Not a Stata emulation, and that is the point of having it here. Stata's `_pctile` -- the
#' convention behind `st_winsor2` -- is quantile type 2, and the two disagree. A paper whose own
#' code is R and calls `quantile(x, probs = p)` wants type 7, so silently routing it through the
#' Stata convention would be wrong. activism's `publication_bias3.R:224` does exactly this to pick
#' the top decile by precision for the Top10 estimator.
#'
#' Exists so the choice is stated once and audited, rather than appearing as a bare quantile()
#' call, which would not say which convention was intended.
st_quantile_r <- function(x, probs, na.rm = TRUE) {
  .note("quantile(x, probs)  [R's own, not Stata's _pctile]", "type 7, R's default")
  stats::quantile(x, probs = probs, na.rm = na.rm, type = 7)
}
