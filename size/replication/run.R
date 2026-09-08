# run.R -- replication of Havranek & Zeynalova (2019), "Firm Size and Stock
# Returns: A Quantitative Survey", Journal of Economic Surveys.
#
# Target table: Table 4, "Estimating the Mediating Factors of Publication
# Bias" (all 6 columns, every coefficient/SE/N cell), plus one bonus cell
# from Table 3 (the publication-bias-corrected size effect, spec (1)).
#
# Uses ONLY the wrappers in stata_compat.R (st_ivreg2, st_xtreg_fe, st_regress,
# st_winsor2, st_coefs). No feols/lm/rma/lmer call is made directly anywhere
# in this file.

suppressMessages(library(jsonlite))

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/size/replication/stata_compat.R")

results <- list()
notes <- character(0)

add_note <- function(x) notes <<- c(notes, x)

# ---------------------------------------------------------------------------
# 1. Data
# ---------------------------------------------------------------------------
# The published CSV. It is a faithful export of the size.dta that size.do
# itself reads (`use size.dta, clear`): same 1746 rows, same 407 columns,
# `se`, `impact` and `pubyear` all present, `geo` identical string for string,
# and the same missing-value pattern (83 missing `impact`, 4 missing `obs`).
# The CSV and the .dta agree. The only real difference is
# print precision -- the CSV's `se` column is written to fewer digits than the
# .dta's float, differing by at most 1.7e-07 -- which is far below the third
# significant digit every Table 4 cell is printed to, and all 47 targets
# reproduce identically from either file (checked side by side).
d <- utils::read.csv(
  (if (file.exists("size.csv")) "size.csv" else
     "https://meta-analysis.cz/data/v1/size/size.csv"),
  stringsAsFactors = FALSE
)
add_note(sprintf("Data: the site's published CSV, data/v1/size/size.csv (%d rows, %d cols).",
                  nrow(d), ncol(d)))

stopifnot(nrow(d) == 1746)

# ---------------------------------------------------------------------------
# 2. Variable construction, replicating size.do lines 14-162 IN ORDER
# ---------------------------------------------------------------------------
# size.do:
#   14  gen prec = 1/se
#   15  gen invsqrtobs = 1/sqrt(obs)
#   150 gen lnobs = ln(obs)
#   151 gen se_impact  = se*impact      <- built from the ORIGINAL (pre-winsor) se
#   153 gen se_pubyear = se*pubyear     <- built from the ORIGINAL (pre-winsor) se
#   162 winsor2 size se prec tstat invsqrtobs, replace cuts(2.5 97.5)
#
# Critically, se_impact/se_pubyear are generated BEFORE the winsor2 call and
# are never regenerated afterwards, so the Table 4 regressions mix a
# winsorized `se` (as a stand-alone regressor) with interaction terms built
# from the un-winsorized `se`. This is exactly what the .do file does, and we
# replicate it faithfully rather than "fixing" it.

d$prec       <- 1 / d$se
d$invsqrtobs <- 1 / sqrt(d$obs)
d$lnobs      <- log(d$obs)
d$se_impact  <- d$se * d$impact     # pre-winsor se
d$se_pubyear <- d$se * d$pubyear    # pre-winsor se

d$size       <- st_winsor2(d$size,       cuts = c(2.5, 97.5))
d$se         <- st_winsor2(d$se,         cuts = c(2.5, 97.5))
d$prec       <- st_winsor2(d$prec,       cuts = c(2.5, 97.5))
d$tstat      <- st_winsor2(d$tstat,      cuts = c(2.5, 97.5))
d$invsqrtobs <- st_winsor2(d$invsqrtobs, cuts = c(2.5, 97.5))

# ---------------------------------------------------------------------------
# 3. Table 4 -- OLS columns (1)-(3): ivreg2 size se [se_impact] [se_pubyear],
#    cluster(idstudy geo)   -- no `small`, i.e. large-sample variance (z-based)
# ---------------------------------------------------------------------------
d1 <- d[stats::complete.cases(d$size, d$se, d$se_impact), , drop = FALSE]           # N=1663
d2 <- d[stats::complete.cases(d$size, d$se, d$se_pubyear), , drop = FALSE]          # N=1746
d3 <- d[stats::complete.cases(d$size, d$se, d$se_impact, d$se_pubyear), , drop = FALSE]  # N=1663

# ivreg2's two-way cluster-robust variance is the Cameron-Gelbach-Miller sum
#
#     V(idstudy, geo) = V(idstudy) + V(geo) - V(idstudy AND geo)
#
# and ivreg2 reports exactly that sum, unadjusted, even when the result is not
# positive semi-definite -- in which case it prints the warning "estimated
# covariance matrix of moment conditions not of full rank" and carries on.
# Column (3) is the one regression here that trips that warning (Stata 15.1,
# stata_work_size/probe2.do): the meat matrix has one negative eigenvalue
# (-0.203 against a leading eigenvalue of 1.1e9).
#
# Handing `cluster = ~idstudy + geo` straight to st_ivreg2() does NOT reproduce
# ivreg2 there, because fixest -- which st_ivreg2 wraps -- forces the multiway
# VCOV to be positive semi-definite before returning it. Where the raw CGM sum
# is already PSD the correction is a no-op and the two agree (columns 1 and 2
# are bit-for-bit identical either way); where it is not, they part company.
# On column (3)'s SE*Pub. Year cell, measured against Stata:
#
#     ivreg2 ... , cluster(idstudy geo)      SE  4.6045557593538e-05   -> 0.0000460 (printed)
#     st_ivreg2(cluster = ~idstudy + geo)    SE  4.6068549659009e-05   -> 0.0000461
#     V(idstudy) + V(geo) - V(idstudy^geo)   SE  4.6045559415019e-05   -> 0.0000460
#
# So the two-way variance is assembled here from three st_ivreg2() fits that
# differ only in their cluster variable, which is the estimator ivreg2 actually
# runs. Every one-way piece is already exact: fixest and Stata agree on each of
# V(idstudy), V(geo) and V(idstudy^geo) to 15 digits, and only their combination
# was in dispute. The point estimates and N are unaffected by the clustering, so
# they are read off the first fit.
st_ivreg2_2way <- function(fml, data) {
  ma <- st_ivreg2(fml, data = data, cluster = ~idstudy)
  mb <- st_ivreg2(fml, data = data, cluster = ~geo)
  mab <- st_ivreg2(fml, data = data, cluster = ~idstudy^geo)   # the intersection
  V <- stats::vcov(ma) + stats::vcov(mb) - stats::vcov(mab)
  cf <- st_coefs(ma)                     # correct estimates, wrong (one-way) SEs
  stopifnot(identical(cf$term, colnames(V)))
  cf$std.error <- sqrt(diag(V))
  cf$statistic <- cf$estimate / cf$std.error
  cf$p.value   <- 2 * stats::pnorm(-abs(cf$statistic))
  list(coefs = cf, n = stats::nobs(ma))
}

r1 <- st_ivreg2_2way(size ~ se + se_impact,              data = d1)
r2 <- st_ivreg2_2way(size ~ se + se_pubyear,             data = d2)
r3 <- st_ivreg2_2way(size ~ se + se_impact + se_pubyear, data = d3)
add_note("Table 4 columns (1)-(3): two-way cluster VCOV assembled as V(idstudy) + V(geo) - V(idstudy^geo) from three st_ivreg2() fits, which is what ivreg2 reports; fixest's own multiway VCOV applies a PSD correction that ivreg2 does not, and that correction moves column (3)'s SE*Pub. Year standard error from 0.0000460 to 0.0000461.")

c1 <- r1$coefs; c2 <- r2$coefs; c3 <- r3$coefs
g <- function(cf, term) cf[cf$term == term, c("estimate", "std.error")]

# ---------------------------------------------------------------------------
# 4. Table 4 -- FE columns (4)-(6): xtreg size se [se_impact] [se_pubyear], fe
#    vce(cluster idstudy)
# ---------------------------------------------------------------------------
d4 <- d1; d5 <- d2; d6 <- d3

m4 <- st_xtreg_fe(size ~ se + se_impact,              data = d4, panel = "idstudy")
m5 <- st_xtreg_fe(size ~ se + se_pubyear,             data = d5, panel = "idstudy")
m6 <- st_xtreg_fe(size ~ se + se_impact + se_pubyear, data = d6, panel = "idstudy")

c4 <- st_coefs(m4); c5 <- st_coefs(m5); c6 <- st_coefs(m6)

# ---------------------------------------------------------------------------
# 5. FE constants. fixest's `feols(y~x|panel)` does not report an intercept,
#    but Stata's `xtreg, fe` does: _cons = ybar - beta'xbar (the grand mean of
#    y minus the within slope(s) times the grand mean(s) of x), exactly as
#    documented in stata_compat.R's st_xtreg_fe_cons for the single-regressor
#    case ("obtained here by an augmented within regression rather than by
#    arithmetic on the coefficients"). st_xtreg_fe_cons only accepts one x, so
#    for the two/three-regressor columns here we generalize its own recipe
#    mechanically: demean every y and x by panel and add back its grand mean,
#    then run that through the shared st_regress() wrapper (a plain
#    clustered OLS, matching the wrapper's own approach) instead of a direct
#    feols call. The additive per-panel/grand-mean shift cannot change any
#    slope (only a location shift), so the resulting slopes are identical to
#    the FE slopes from st_xtreg_fe above -- checked below -- and the
#    regression's own intercept is exactly Stata's reported _cons, with a
#    proper clustered SE.
fe_cons <- function(yname, xnames, data, panel) {
  yv <- data[[yname]]
  g  <- data[[panel]]
  ya <- yv - stats::ave(yv, g) + mean(yv)
  d2 <- data.frame(ya = ya)
  for (xn in xnames) {
    xv <- data[[xn]]
    d2[[xn]] <- xv - stats::ave(xv, g) + mean(xv)
  }
  d2$.g <- g
  fml <- stats::as.formula(paste("ya ~", paste(xnames, collapse = " + ")))
  # cluster by the same panel variable as the FE model's vce(cluster idstudy)
  st_regress(fml, data = d2, cluster = ~.g, robust = FALSE)
}

mc4 <- fe_cons("size", c("se", "se_impact"),              d4, "idstudy")
mc5 <- fe_cons("size", c("se", "se_pubyear"),             d5, "idstudy")
mc6 <- fe_cons("size", c("se", "se_impact", "se_pubyear"), d6, "idstudy")

cc4 <- st_coefs(mc4); cc5 <- st_coefs(mc5); cc6 <- st_coefs(mc6)

# sanity check: slopes from the augmented-regression device must reproduce
# the FE slopes already obtained from st_xtreg_fe (they are the same
# quantity up to floating point, since the transform is a pure location shift)
chk <- function(a, b, tol = 1e-6) stopifnot(abs(a - b) < tol)
chk(g(cc4, "se")$estimate,        g(c4, "se")$estimate)
chk(g(cc4, "se_impact")$estimate, g(c4, "se_impact")$estimate)
chk(g(cc5, "se")$estimate,         g(c5, "se")$estimate)
chk(g(cc5, "se_pubyear")$estimate, g(c5, "se_pubyear")$estimate)
chk(g(cc6, "se")$estimate,         g(c6, "se")$estimate)
chk(g(cc6, "se_impact")$estimate,  g(c6, "se_impact")$estimate)
chk(g(cc6, "se_pubyear")$estimate, g(c6, "se_pubyear")$estimate)
add_note("Sanity check passed: FE slopes from the grand-mean-recentered st_regress() device match the slopes from st_xtreg_fe() to within 1e-6, confirming the constant-extraction device does not alter the estimated slopes.")

cons4 <- cc4[cc4$term == "(Intercept)", c("estimate", "std.error")]
cons5 <- cc5[cc5$term == "(Intercept)", c("estimate", "std.error")]
cons6 <- cc6[cc6$term == "(Intercept)", c("estimate", "std.error")]

# ---------------------------------------------------------------------------
# 6. Table 3, spec (1), on the RESTRICTED robustness subsample: the target
#    label's printed value -0.0259 is NOT the main Table 3 col-(1) constant
#    (that one is printed as -0.0351...no, -0.0315, see Table 3 in the PDF:
#    Constant = -0.0315*** on the full N=1746 sample; the text on p.24 calls
#    it "the estimated intercept of -0.032"). -0.0259 instead comes from the
#    robustness paragraph on p.28: "we repeat these computations excluding
#    observations of the size effect with the returns being non-monthly,
#    focusing on U.S. stocks only. This methodological modification reduces
#    the number of sampled coefficients to 946 ... The adjusted value of
#    size effect from specification (1) in Table 3 is -0.0259."  That
#    restriction is exactly the "*FOR SIZE RISK PREMIUM" block of size.do:
#        preserve
#        keep if monthly == 1
#        keep if geo == "US"
#        quietly eststo: ivreg2 size se, cluster (idstudy)
#        restore
#    i.e. spec (1)'s OLS-on-(size,se) re-run on the monthly-returns/US-only
#    subsample (N=946, matches the paper's stated count), clustered by
#    idstudy ONLY (not idstudy+geo -- geo is constant "US" in this
#    subsample anyway, and the .do file drops geo from the cluster list
#    here). This runs after winsor2, so size/se are the same winsorized
#    variables used everywhere else in this script.
# ---------------------------------------------------------------------------
d_premium <- d[d$monthly == 1 & d$geo == "US" &
                 !is.na(d$monthly) & !is.na(d$geo), , drop = FALSE]
add_note(sprintf("Table 3 robustness subsample (monthly==1 & geo=='US'): N=%d (paper text: 946).",
                  nrow(d_premium)))

d0 <- d_premium[stats::complete.cases(d_premium$size, d_premium$se), , drop = FALSE]
m0 <- st_ivreg2(size ~ se, data = d0, cluster = ~idstudy)
c0 <- st_coefs(m0)
t3_cons <- g(c0, "(Intercept)")

# ---------------------------------------------------------------------------
# 7. Collect + print + write results.json
# ---------------------------------------------------------------------------
put <- function(label, value) {
  results[[label]] <<- unname(value)
  cat(sprintf("%-55s %s\n", label, format(value, digits = 10)))
}

put("T4 C1 (OLS) SE coef",          g(c1, "se")$estimate)
put("T4 C1 (OLS) SE se",            g(c1, "se")$std.error)
put("T4 C1 (OLS) SE*Impact coef",   g(c1, "se_impact")$estimate)
put("T4 C1 (OLS) SE*Impact se",     g(c1, "se_impact")$std.error)
put("T4 C1 (OLS) Constant coef",    g(c1, "(Intercept)")$estimate)
put("T4 C1 (OLS) Constant se",      g(c1, "(Intercept)")$std.error)
put("T4 C1 (OLS) N",                r1$n)

put("T4 C2 (OLS) SE coef",          g(c2, "se")$estimate)
put("T4 C2 (OLS) SE se",            g(c2, "se")$std.error)
put("T4 C2 (OLS) SE*Pub.Year coef", g(c2, "se_pubyear")$estimate)
put("T4 C2 (OLS) SE*Pub.Year se",   g(c2, "se_pubyear")$std.error)
put("T4 C2 (OLS) Constant coef",    g(c2, "(Intercept)")$estimate)
put("T4 C2 (OLS) Constant se",      g(c2, "(Intercept)")$std.error)
put("T4 C2 (OLS) N",                r2$n)

put("T4 C3 (OLS) SE coef",          g(c3, "se")$estimate)
put("T4 C3 (OLS) SE se",            g(c3, "se")$std.error)
put("T4 C3 (OLS) SE*Impact coef",   g(c3, "se_impact")$estimate)
put("T4 C3 (OLS) SE*Impact se",     g(c3, "se_impact")$std.error)
put("T4 C3 (OLS) SE*Pub.Year coef", g(c3, "se_pubyear")$estimate)
put("T4 C3 (OLS) SE*Pub.Year se",   g(c3, "se_pubyear")$std.error)
put("T4 C3 (OLS) Constant coef",    g(c3, "(Intercept)")$estimate)
put("T4 C3 (OLS) Constant se",      g(c3, "(Intercept)")$std.error)
put("T4 C3 (OLS) N",                r3$n)

put("T4 C4 (FE) SE coef",           g(c4, "se")$estimate)
put("T4 C4 (FE) SE se",             g(c4, "se")$std.error)
put("T4 C4 (FE) SE*Impact coef",    g(c4, "se_impact")$estimate)
put("T4 C4 (FE) SE*Impact se",      g(c4, "se_impact")$std.error)
put("T4 C4 (FE) Constant coef",     cons4$estimate)
put("T4 C4 (FE) Constant se",       cons4$std.error)
put("T4 C4 (FE) N",                 stats::nobs(m4))

put("T4 C5 (FE) SE coef",           g(c5, "se")$estimate)
put("T4 C5 (FE) SE se",             g(c5, "se")$std.error)
put("T4 C5 (FE) SE*Pub.Year coef",  g(c5, "se_pubyear")$estimate)
put("T4 C5 (FE) SE*Pub.Year se",    g(c5, "se_pubyear")$std.error)
put("T4 C5 (FE) Constant coef",     cons5$estimate)
put("T4 C5 (FE) Constant se",       cons5$std.error)
put("T4 C5 (FE) N",                 stats::nobs(m5))

put("T4 C6 (FE) SE coef",           g(c6, "se")$estimate)
put("T4 C6 (FE) SE se",             g(c6, "se")$std.error)
put("T4 C6 (FE) SE*Impact coef",    g(c6, "se_impact")$estimate)
put("T4 C6 (FE) SE*Impact se",      g(c6, "se_impact")$std.error)
put("T4 C6 (FE) SE*Pub.Year coef",  g(c6, "se_pubyear")$estimate)
put("T4 C6 (FE) SE*Pub.Year se",    g(c6, "se_pubyear")$std.error)
put("T4 C6 (FE) Constant coef",     cons6$estimate)
put("T4 C6 (FE) Constant se",       cons6$std.error)
put("T4 C6 (FE) N",                 stats::nobs(m6))

put("T3 C1 (OLS, size~se) Constant coef (pub-bias-corrected size effect)", t3_cons$estimate)

jsonlite::write_json(results, "results.json", auto_unbox = TRUE, digits = NA)

cat("\n")
stata_compat_log()
cat("\nNotes:\n")
cat(paste(" -", notes, collapse = "\n"), "\n")
