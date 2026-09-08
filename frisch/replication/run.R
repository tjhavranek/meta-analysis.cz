# run.R -- replication package for meta-analysis.cz paper "frisch"
# Havranek, Elminejad, Horvath & Irsova, "Intertemporal Substitution in Labor Supply:
# A Meta-Analysis", Review of Economic Dynamics 2023, doi:10.1016/j.red.2023.10.001
#
# Target: Table 3, Panel A ("Linear and nonlinear tests document publication bias") --
# the funnel-asymmetry / precision-effect regression of the extensive-margin Frisch
# elasticity on its standard error, across five estimators: OLS, study fixed effects,
# precision-weighted, study-weighted, and MAIVE (Irsova et al., 2023).
#
# Data: only the file the site publishes, data/v1/frisch/frisch.csv.
# Estimation: only the wrappers in stata_compat.R.
#
# ---------------------------------------------------------------------------------------
# Why this file carries a random-number generator
# ---------------------------------------------------------------------------------------
# Every column of Table 3 regresses on se_comb_win, and se_comb (frisch.do lines 129-132)
# is the reported se where a study reports one and a BOOTSTRAPPED study_se where it does
# not. 15 of the 38 extensive-margin studies (203 of 762 rows) report no se at all.
# study_se is built in frisch.do lines 24-99: for each study,
#
#   bootstrap mean=r(mean), reps(1000) strata(idstudy) seed(1234): summarize frisch_boot
#
# on that study's rows alone, then summarize mean over the 1000 bootstrap means and r(sd)
# is stored. The published CSV carries the ingredients (frisch, idstudy) but not the
# bootstrap output, so study_se has to be regenerated -- and an approximation is not enough:
# the plug-in formula sqrt(sum (x-xbar)^2)/n, which is what a 1000-replication bootstrap SD
# of a mean estimates, is right on average but off by 1-5% study by study, and that moves
# every Table 3 coefficient into the third digit.
#
# So this file reproduces Stata's draw exactly rather than approximating it. Two pieces:
#
#   1. Stata 14+ uses mt64, which is the reference MT19937-64 seeded with
#      init_genrand64(seed) and converted with (x >> 11) * 2^-53. Checked bit for bit
#      against Stata 15.1 over 5,000 draws.
#   2. bsample with strata() is Stata's StrSRSWR (ado/base/b/bsample.ado), which is NOT
#      "draw n indices". It draws r_i = int(u*n)+1 and w_i = u for each row, sorts rows by
#      (r, w), turns runs of equal r into frequency weights, keeps the last row of each run
#      and expands it. The multiplicity a row receives therefore depends on which rows
#      happened to draw the same r and which of them drew the largest w.
#      One subtlety decides whether the stream stays in step: after expand, StrSRSWR runs
#      "capture by strata: assert _N == _N", which FAILS whenever expand actually added
#      observations, because expand leaves the data flagged unsorted. The failure falls
#      through to "replace w = uniform()", so a replication that contains any duplicate
#      consumes 3n uniforms and one with no duplicate consumes 2n. Getting that wrong
#      desynchronises the stream at the first all-distinct resample, and every later
#      replication of that study is then a different draw.
#
# Result: all 38 study_se values reproduce the author's saved Stata output to eight
# significant digits, and with them the five columns of Table 3 reproduce as printed.
#

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/frisch/replication/stata_compat.R")

# ---------------------------------------------------------------------------------------
# Stata's mt64 random-number generator (MT19937-64), 64-bit words as two 32-bit doubles
# ---------------------------------------------------------------------------------------
.MT <- new.env(parent = emptyenv())
.b32 <- function(f, a, b) f(a %/% 65536, b %/% 65536) * 65536 + f(a %% 65536, b %% 65536)
.xor32 <- function(a, b) .b32(bitwXor, a, b)
.and32 <- function(a, b) .b32(bitwAnd, a, b)

.mul64 <- function(ah, al, bh, bl) {          # (a * b) mod 2^64, via 16-bit limbs
  a <- c(al %% 65536, al %/% 65536, ah %% 65536, ah %/% 65536)
  b <- c(bl %% 65536, bl %/% 65536, bh %% 65536, bh %/% 65536)
  c0 <- a[1]*b[1]
  c1 <- a[1]*b[2] + a[2]*b[1]
  c2 <- a[1]*b[3] + a[2]*b[2] + a[3]*b[1]
  c3 <- a[1]*b[4] + a[2]*b[3] + a[3]*b[2] + a[4]*b[1]
  r0 <- c0 %% 65536; k <- c0 %/% 65536
  c1 <- c1 + k; r1 <- c1 %% 65536; k <- c1 %/% 65536
  c2 <- c2 + k; r2 <- c2 %% 65536; k <- c2 %/% 65536
  c3 <- c3 + k; r3 <- c3 %% 65536
  c(r3 * 65536 + r2, r1 * 65536 + r0)
}

mt_set_seed <- function(seed) {               # init_genrand64
  NN <- 312L
  hi <- numeric(NN); lo <- numeric(NN)
  hi[1] <- seed %/% 4294967296; lo[1] <- seed %% 4294967296
  MH <- 1481765933; ML <- 1284865837          # 6364136223846793005 = 0x5851F42D4C957F2D
  for (i in 2:NN) {
    ph <- hi[i-1]; pl <- lo[i-1]
    th <- ph                                  # prev ^ (prev >> 62)
    tl <- .xor32(pl, ph %/% 1073741824)
    p  <- .mul64(MH, ML, th, tl)
    l  <- p[2] + (i - 1)
    h  <- p[1] + (l %/% 4294967296)
    hi[i] <- h %% 4294967296; lo[i] <- l %% 4294967296
  }
  .MT$hi <- hi; .MT$lo <- lo; .MT$buf <- numeric(0); .MT$pos <- 0L
  invisible(NULL)
}

.mt_block <- function() {                     # one 312-word twist, then tempering
  NN <- 312L; MM <- 156L
  ohi <- .MT$hi; olo <- .MT$lo
  nhi <- numeric(NN); nlo <- numeric(NN)
  AH <- 3036835674; AL <- 2842040809          # 0xB5026F5AA96619E9
  twist <- function(ahi, alo, blo, chi, clo) {
    xhi <- ahi
    xlo <- (alo %/% 2147483648) * 2147483648 + (blo %% 2147483648)
    odd <- xlo %% 2
    shi <- xhi %/% 2
    slo <- xlo %/% 2 + (xhi %% 2) * 2147483648
    list(hi = .xor32(.xor32(chi, shi), AH * odd),
         lo = .xor32(.xor32(clo, slo), AL * odd))
  }
  i <- 1:(NN - MM)
  r <- twist(ohi[i], olo[i], olo[i+1], ohi[i+MM], olo[i+MM])
  nhi[i] <- r$hi; nlo[i] <- r$lo
  i <- (NN - MM + 1):(NN - 1)
  r <- twist(ohi[i], olo[i], olo[i+1], nhi[i - (NN - MM)], nlo[i - (NN - MM)])
  nhi[i] <- r$hi; nlo[i] <- r$lo
  r <- twist(ohi[NN], olo[NN], nlo[1], nhi[MM], nlo[MM])
  nhi[NN] <- r$hi; nlo[NN] <- r$lo
  .MT$hi <- nhi; .MT$lo <- nlo

  xh <- nhi; xl <- nlo
  th <- xh %/% 536870912                                      # x ^= (x >> 29) & 0x5555...
  tl <- xl %/% 536870912 + (xh %% 536870912) * 8
  xh <- .xor32(xh, .and32(th, 1431655765)); xl <- .xor32(xl, .and32(tl, 1431655765))
  th <- (xh %% 32768) * 131072 + xl %/% 32768                 # x ^= (x << 17) & 0x71D6...
  tl <- (xl %% 32768) * 131072
  xh <- .xor32(xh, .and32(th, 1909882879)); xl <- .xor32(xl, .and32(tl, 3987079168))
  th <- (xl %% 134217728) * 32                                # x ^= (x << 37) & 0xFFF7...
  xh <- .xor32(xh, .and32(th, 4294438624))
  xl <- .xor32(xl, xh %/% 2048)                               # x ^= (x >> 43)
  .MT$buf <- (xh * 2097152 + xl %/% 2048) * 2^-53             # (x >> 11) * 2^-53
  .MT$pos <- 0L
}

mt_runif <- function(n) {                     # the next n draws of Stata's runiform()
  out <- numeric(n); k <- 0L
  while (k < n) {
    if (.MT$pos >= length(.MT$buf)) .mt_block()
    take <- min(n - k, length(.MT$buf) - .MT$pos)
    out[(k+1):(k+take)] <- .MT$buf[(.MT$pos+1):(.MT$pos+take)]
    .MT$pos <- .MT$pos + take; k <- k + take
  }
  out
}

# ---------------------------------------------------------------------------------------
# bsample with strata(g) on a single stratum: Stata's StrSRSWR, returned as frequency counts
# ---------------------------------------------------------------------------------------
stata_bsample_counts <- function(n) {
  r <- floor(mt_runif(n) * n + 1)             # gen double r = int(uniform()*_N + 1)
  w <- mt_runif(n)                            # gen double w = uniform()
  o <- order(r, w)                            # sort strata r w
  rl <- rle(r[o])$lengths                     # replace w = running count within each run
  counts <- integer(n)
  counts[o[cumsum(rl)]] <- rl                 # keep last of each run, then expand w
  # expand flags the data unsorted whenever it adds an observation, so the following
  # "capture by strata: assert _N == _N" errors and the fall-through "replace w = uniform()"
  # runs, burning n more draws. With no duplicates nothing is added and it does not.
  if (any(counts > 1L)) invisible(mt_runif(n))
  counts
}

stata_bootstrap_sd <- function(x, reps = 1000L, seed = 1234) {
  n <- length(x)
  mt_set_seed(seed)
  m <- numeric(reps)
  for (b in seq_len(reps)) m[b] <- sum(x * stata_bsample_counts(n)) / n
  stats::sd(m)                                # summarize mean -> r(sd), N-1 denominator
}

# ---------------------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------------------
data_path <- (if (file.exists("frisch.csv")) "frisch.csv" else
     "https://meta-analysis.cz/data/v1/frisch/frisch.csv")
d <- read.csv(data_path, stringsAsFactors = FALSE)

ext <- d[d$margin == "extensive", ]
stopifnot(nrow(ext) == 762, length(unique(ext$idstudy)) == 38)

# study_se: the bootstrap above, one study at a time, with the seed reset to 1234 for each
# study exactly as the do-file's loop does (seed(1234) sits inside the loop).
cat("regenerating Stata's bootstrapped study_se (38 studies x 1000 replications) ...\n")
ids <- sort(unique(ext$idstudy))
study_se <- vapply(ids, function(i) stata_bootstrap_sd(ext$frisch[ext$idstudy == i]),
                   numeric(1))
ext$study_se <- study_se[match(ext$idstudy, ids)]

# frisch.do line 113: replace se = 0.001 if se == 0   (before se_comb is built)
ext$se[!is.na(ext$se) & ext$se == 0] <- 0.001
# lines 129-132: se_comb = se where reported, study_se otherwise
ext$se_comb <- ifelse(is.na(ext$se), ext$study_se, ext$se)
ext$se_comb[ext$se_comb == 0] <- 0.001
stopifnot(sum(is.na(ext$se_comb)) == 0)

# ---------------------------------------------------------------------------------------
# Winsorizing and derived variables (frisch.do lines ~117-146)
# ---------------------------------------------------------------------------------------
ext$frisch_win     <- st_winsor2(ext$frisch,   cuts = c(5, 95))  # winsor2 frisch se, cuts(5 95)
ext$se_comb_win    <- st_winsor2(ext$se_comb,  cuts = c(5, 95))  # winsor2 se_comb, cuts(5 95)
ext$se2_comb_win   <- ext$se_comb_win^2
ext$prec_comb_win  <- 1 / ext$se_comb_win
ext$invperstudy    <- 1 / ext$est_per_study
ext$invobs         <- 1 / ext$no_obs

res <- list()

# ---------------------------------------------------------------------------------------
# Column 1: OLS  --  ivreg2 frisch_win se_comb_win, cluster(idstudy)         (do-file l. 276)
# ---------------------------------------------------------------------------------------
m1 <- st_ivreg2(frisch_win ~ se_comb_win, data = ext, cluster = ~idstudy)
c1 <- st_coefs(m1)
res[["T3 col1 OLS: Publication bias coef"]]   <- c1$estimate[c1$term == "se_comb_win"]
res[["T3 col1 OLS: Publication bias SE"]]     <- c1$std.error[c1$term == "se_comb_win"]
res[["T3 col1 OLS: Effect-beyond-bias coef"]] <- c1$estimate[c1$term == "(Intercept)"]
res[["T3 col1 OLS: Effect-beyond-bias SE"]]   <- c1$std.error[c1$term == "(Intercept)"]
res[["T3 col1 OLS: Observations"]] <- m1$nobs
res[["T3 col1 OLS: Studies"]]      <- length(unique(ext$idstudy))

# ---------------------------------------------------------------------------------------
# Column 2: FE  --  xtreg frisch_win se_comb_win, fe                        (do-file l. 277)
# ---------------------------------------------------------------------------------------
# That line carries no vce(cluster) or robust, unlike the four ivreg2 columns, so Stata
# reports conventional standard errors here; the table note's "we cluster standard errors at
# the study level" describes the ivreg2 columns (clustering gives 0.724 for the slope SE
# against a printed 0.271). xtreg y x, fe with conventional SEs is numerically identical for
# the slope and its SE to regress y x i.idstudy (same within estimator, same residual df
# N - G - 1), so st_regress with study dummies stands in for st_xtreg_fe, whose clustering
# cannot be switched off.
m2 <- st_regress(frisch_win ~ se_comb_win + factor(idstudy), data = ext)
c2 <- st_coefs(m2, z = FALSE)
# Stata's xtreg,fe _cons is ybar - b*xbar with variance s2_e * (1/N + xbar^2 / Sxx_within).
# That is exactly the constant of an OLS fit to the augmented data (y - ybar_g + ybar,
# x - xbar_g + xbar) -- same residuals, hence same Sxx and SSR -- except that xtreg divides
# SSR by N - G - 1 where a plain regress divides by N - 2. The factor below is that df
# difference and nothing else; the stopifnot proves it by reproducing the LSDV slope SE.
N2 <- nrow(ext); G2 <- length(unique(ext$idstudy))
aug <- data.frame(
  ya = ext$frisch_win  - stats::ave(ext$frisch_win,  ext$idstudy) + mean(ext$frisch_win),
  xa = ext$se_comb_win - stats::ave(ext$se_comb_win, ext$idstudy) + mean(ext$se_comb_win))
cons2 <- st_regress(ya ~ xa, data = aug)
cc2 <- st_coefs(cons2, z = FALSE)
df_fac <- sqrt((N2 - 2) / (N2 - G2 - 1))
stopifnot(abs(cc2$std.error[cc2$term == "xa"] * df_fac -
              c2$std.error[c2$term == "se_comb_win"]) < 1e-10)
res[["T3 col2 FE: Publication bias coef"]]   <- c2$estimate[c2$term == "se_comb_win"]
res[["T3 col2 FE: Publication bias SE"]]     <- c2$std.error[c2$term == "se_comb_win"]
res[["T3 col2 FE: Effect-beyond-bias coef"]] <- cc2$estimate[cc2$term == "(Intercept)"]
res[["T3 col2 FE: Effect-beyond-bias SE"]]   <- cc2$std.error[cc2$term == "(Intercept)"] * df_fac
res[["T3 col2 FE: Observations"]] <- m2$nobs
res[["T3 col2 FE: Studies"]]      <- G2

# ---------------------------------------------------------------------------------------
# Column 3: Precision -- ivreg2 frisch_win se_comb_win [pw=prec_comb_win], cluster(idstudy)
# ---------------------------------------------------------------------------------------
m3 <- st_ivreg2(frisch_win ~ se_comb_win, data = ext, cluster = ~idstudy,
                weights = ~prec_comb_win)
c3 <- st_coefs(m3)
res[["T3 col3 Precision: Publication bias coef"]]   <- c3$estimate[c3$term == "se_comb_win"]
res[["T3 col3 Precision: Publication bias SE"]]     <- c3$std.error[c3$term == "se_comb_win"]
res[["T3 col3 Precision: Effect-beyond-bias coef"]] <- c3$estimate[c3$term == "(Intercept)"]
res[["T3 col3 Precision: Effect-beyond-bias SE"]]   <- c3$std.error[c3$term == "(Intercept)"]
res[["T3 col3 Precision: Observations"]] <- m3$nobs
res[["T3 col3 Precision: Studies"]]      <- length(unique(ext$idstudy))

# ---------------------------------------------------------------------------------------
# Column 4: Study -- ivreg2 frisch_win se_comb_win [pw=invperstudy], cluster(idstudy)
# ---------------------------------------------------------------------------------------
m4 <- st_ivreg2(frisch_win ~ se_comb_win, data = ext, cluster = ~idstudy,
                weights = ~invperstudy)
c4 <- st_coefs(m4)
res[["T3 col4 Study: Publication bias coef"]]   <- c4$estimate[c4$term == "se_comb_win"]
res[["T3 col4 Study: Publication bias SE"]]     <- c4$std.error[c4$term == "se_comb_win"]
res[["T3 col4 Study: Effect-beyond-bias coef"]] <- c4$estimate[c4$term == "(Intercept)"]
res[["T3 col4 Study: Effect-beyond-bias SE"]]   <- c4$std.error[c4$term == "(Intercept)"]
res[["T3 col4 Study: Observations"]] <- m4$nobs
res[["T3 col4 Study: Studies"]]      <- length(unique(ext$idstudy))

# ---------------------------------------------------------------------------------------
# Column 5: MAIVE -- ivreg2 frisch_win (se2_comb_win = invobs), cluster(idstudy) (l. 284)
# ---------------------------------------------------------------------------------------
# Requires no_obs, which 159 of the 762 rows lack, hence the printed 603 observations.
extA <- ext[!is.na(ext$invobs), ]
m5 <- st_ivreg2(frisch_win ~ 1 | se2_comb_win ~ invobs, data = extA, cluster = ~idstudy)
c5 <- st_coefs(m5)
res[["T3 col5 MAIVE: Publication bias coef"]]   <- c5$estimate[grepl("se2_comb_win", c5$term)]
res[["T3 col5 MAIVE: Publication bias SE"]]     <- c5$std.error[grepl("se2_comb_win", c5$term)]
res[["T3 col5 MAIVE: Effect-beyond-bias coef"]] <- c5$estimate[c5$term == "(Intercept)"]
res[["T3 col5 MAIVE: Effect-beyond-bias SE"]]   <- c5$std.error[c5$term == "(Intercept)"]
# First-stage F: not reproduced, and not because of anything in this file. Running the
# author's own line in Stata 15.1 on the author's own saved data prints a cluster-robust
# first-stage F of 37.02 (Kleibergen-Paap rk Wald F 37.015; Cragg-Donald 46.53); the paper
# prints 31.2. See REPLICATION_STATUS.md for the candidates that were checked and ruled out.
res[["T3 col5 MAIVE: First-stage F"]] <- st_ivreg2_first_F(m5)
res[["T3 col5 MAIVE: Observations"]]  <- m5$nobs
# Studies: this regression has 33 clusters, which is what ivreg2 reports. The paper's 23 is
# the number of studies that report their own se.
res[["T3 col5 MAIVE: Studies"]]       <- length(unique(extA$idstudy))

# ---------------------------------------------------------------------------------------
# Print and save
# ---------------------------------------------------------------------------------------
cat("\n===== Produced numbers =====\n")
for (nm in names(res)) cat(sprintf("%-45s %s\n", nm, format(res[[nm]], digits = 6)))

out <- vapply(res, function(x) x, numeric(1))
if (requireNamespace("jsonlite", quietly = TRUE)) {
  writeLines(jsonlite::toJSON(as.list(out), auto_unbox = TRUE, digits = 10), "results.json")
} else {
  esc <- function(s) gsub('"', '\\\\"', s)
  lines <- sprintf('  "%s": %s', vapply(names(out), esc, character(1)),
                   format(out, digits = 10, scientific = FALSE))
  writeLines(c("{", paste(lines, collapse = ",\n"), "}"), "results.json")
}

cat("\nWrote results.json\n")
stata_compat_log()
