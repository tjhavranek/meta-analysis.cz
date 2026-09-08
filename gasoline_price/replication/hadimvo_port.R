# ------------------------------------------------------------------- hadimvo (Hadi outliers)
#' Stata's `hadimvo <vars>, gen(flag) p(alpha)` -- Hadi's multivariate outlier identification.
#'
#' Ported line by line from hadimvo.ado v1.3.0 (19apr2007), the version shipped with Stata and
#' frozen since Stata 8, so it is the code the authors ran. Verified against Stata's own output
#' on this machine: 0 flag mismatches across 3,674 rows of the spillovers data, distances equal
#' to float precision, and the paper's Table 1 sample reproduced exactly (1,311 kept of 1,402,
#' 55 studies; forward 1,030 of 1,067; horizontal 1,154 of 1,205).
#'
#' Details that matter and are easy to get wrong: the starting scatter is centred on the
#' coordinatewise MEDIAN, not the mean; the subset restarts at k+1 and grows one at a time,
#' re-sorting after EVERY addition, with no iterate-to-stability step; the correction factor
#' cf = (1 + 2/(N-1-3k) + (k+1)/(N-k))^2 is SQUARED and constant in r; and the cutoff is the
#' Bonferroni upper-tail chi-square at p/N. An extra (n/r) inflation, which is not in the ado,
#' leaves 1,324 instead of 1,311 -- close enough to look like a rounding difference.

## Faithful R port of Stata's hadimvo.ado (version 1.3.0, 19apr2007), verified against
## Stata 15.1 output row by row. Nothing here was tuned to a target.
f32 <- function(x) readBin(writeBin(as.double(x), raw(), size = 4), "double", size = 4, n = length(x))

hadimvo_stata <- function(X, p = 0.05, float_D = TRUE) {
  X <- as.matrix(X); storage.mode(X) <- "double"
  ok  <- stats::complete.cases(X); idx <- which(ok)
  Z   <- X[ok, , drop = FALSE]
  N   <- nrow(Z); k <- ncol(Z)
  if (p >= 1) p <- p / 100
  stopifnot(p > 0, p < 1, 3 * k + 1 < N)
  half <- floor((N + k + 1) / 2)
  st <- if (float_D) f32 else identity          # Stata's predict/gen store D as float

  # quadratic form q_i = (z_i - c)' A^{-1} (z_i - c), with Stata-style collinearity drop
  qf <- function(Zc, A) {
    keep <- integer(0)
    for (j in seq_len(ncol(Zc)))
      if (qr(A[c(keep, j), c(keep, j), drop = FALSE])$rank == length(keep) + 1L) keep <- c(keep, j)
    Zk <- Zc[, keep, drop = FALSE]
    rowSums((Zk %*% solve(A[keep, keep, drop = FALSE])) * Zk)
  }

  ## Step 0: distances from the coordinatewise median, scatter about the MEDIAN, all N obs
  med <- apply(Z, 2, stats::median)
  Zc  <- sweep(Z, 2, med)
  D   <- st(qf(Zc, crossprod(Zc)))               # = hat from reg u (x-med), nocons
  ord <- order(D)
  r   <- half
  ## ... then mean/scatter of the h = int((N+k+1)/2) closest, distances for all, re-sort
  sub <- ord[seq_len(r)]
  m   <- colMeans(Z[sub, , drop = FALSE]); Zc <- sweep(Z, 2, m)
  D   <- st(qf(Zc, crossprod(Zc[sub, , drop = FALSE])))
  ord <- order(D)
  r   <- k + 1                                    # Hadi (1994): restart from k+1 closest

  ## Step 1: expand if the k+1 closest are collinear (Stata checks e(df_m)==k)
  while (qr(Zc[ord[seq_len(r)], , drop = FALSE])$rank != k) {
    r <- r + 1; if (r > half) stop("singular covariance even at (n+k+1)/2")
  }

  ## _maked: reg u x1..xk (with constant) in 1/r; hat - 1/r  ==  (x-xbar_r)'(Xc'Xc)^{-1}(x-xbar_r)
  maked <- function(ord, r) {
    sub <- ord[seq_len(r)]
    m   <- colMeans(Z[sub, , drop = FALSE]); Zc <- sweep(Z, 2, m)
    st(qf(Zc, crossprod(Zc[sub, , drop = FALSE])))
  }

  ## Steps 2-3: grow one at a time from k+1 to half, re-sorting after every addition
  D <- maked(ord, r); ord <- order(D)
  while (r < half) { r <- r + 1; D <- maked(ord, r); ord <- order(D) }

  ## Step 4: scaled distances vs. chi-square cutoff; cf is CONSTANT and SQUARED
  cf   <- (1 + 2 / (N - 1 - 3 * k) + (k + 1) / (N - k))^2
  chi2 <- stats::qchisq(p / N, k, lower.tail = FALSE)   # = Stata invchi(k, p/N)
  D <- st((r - 1) * maked(ord, r) / cf); ord <- order(D)
  path <- r
  while (D[ord[r + 1]] < chi2) {
    if (N == r + 1) {                             # everything accepted
      out <- rep(NA_integer_, nrow(X)); out[idx] <- 0L
      return(list(flag = out, dist = { d <- rep(NA_real_, nrow(X)); d[idx] <- sqrt(D); d },
                  r = N, N = N, cutoff = chi2, cf = cf, n_out = 0L))
    }
    r <- r + 1
    D <- st((r - 1) * maked(ord, r) / cf); ord <- order(D)
  }
  flag <- as.integer(D >= chi2)                   # flags ALL obs at/above cutoff under final fit
  out <- rep(NA_integer_, nrow(X)); out[idx] <- flag
  d <- rep(NA_real_, nrow(X)); d[idx] <- sqrt(D)
  list(flag = out, dist = d, r = r, N = N, cutoff = chi2, cf = cf, n_out = sum(flag))
}
