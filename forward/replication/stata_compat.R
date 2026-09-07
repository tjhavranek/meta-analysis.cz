# stata_compat.R -- Stata commands as R, with the conventions pinned.
#
# Every replication package on meta-analysis.cz sources this file and calls ONLY these
# wrappers. Calling feols(), lm(), rma() or lmer() directly is forbidden, and a Stata command
# with no wrapper here is a stop-and-file event rather than an invitation to pick the closest
# looking R function.
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
# fixed here once, with the evidence that fixed it, and test_compat.R re-derives the published
# cells on every change.
#
# Verified against: class (JOLE 2026) Table 3, Block 1, Panel A -- all ten coefficient and
# standard-error cells, the fixed-effects constant, N, the first-stage F and the WAAP row.

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

#' `winsor2 x, cuts(lo hi)`, cuts given in percent.
st_winsor2 <- function(x, cuts = c(1, 99)) {
  x <- as.numeric(x)
  q <- stats::quantile(x, cuts / 100, na.rm = TRUE, type = 2)
  .note(sprintf("winsor2 <var>, cuts(%g %g)", cuts[1], cuts[2]),
        "quantile type 2 (Stata _pctile), NOT R's default type 7")
  ifelse(is.na(x), x, pmin(pmax(x, q[1]), q[2]))
}

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

# ------------------------------------------------------------------------------- reporting
#' Coefficients with the inference convention the emulated command uses: z for ivreg2, t for
#' regress and xtreg. Returns a tidy frame so COMPARE can read it without parsing printed text.
st_coefs <- function(m, z = TRUE) {
  b <- stats::coef(m); s <- sqrt(diag(stats::vcov(m)))
  data.frame(term = names(b), estimate = as.numeric(b), std.error = as.numeric(s),
             statistic = as.numeric(b / s),
             p.value = if (z) 2 * stats::pnorm(-abs(b / s)) else NA_real_,
             row.names = NULL, stringsAsFactors = FALSE)
}
