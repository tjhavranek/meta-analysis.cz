# run.R -- replication package for "border"
# Paper: "Do Borders Really Slash Trade? A Meta-Analysis", IMF Economic Review
# (2017), doi 10.1057/s41308-016-0001-5.
#
# Target table: paper's Table 6, "Robustness Check--OLS and Fixed Effects"
# (the frequentist double-check of the same country-group border effects that
# make up the paper's headline Table 5). Table 5 itself is NOT attempted here:
# it is a Bayesian-Model-Averaging-implied prediction (Table 4 BMA posterior
# coefficients combined with "best practice" covariate values), and the BMA
# step is entirely inside a Stata comment block in the author's own border.do
# ("*BAYESIAN MODEL AVERAGING" / "*//Switch to R" / "*border = bms(...)") --
# i.e. never executed by Stata at all, only a record of what was run
# separately in R's BMS package with burn=1e6/iter=2e6 MCMC settings. No
# wrapper in stata_compat.R emulates bms(), so Table 5 is UNSUPPORTED. See
# REPLICATION_STATUS.md.
#
# Uses ONLY the wrappers in stata_compat.R (st_ivreg2, st_xtreg_fe, st_regress,
# st_coefs). No feols/lm/ivreg call is made directly anywhere in this file.

suppressMessages(library(jsonlite))

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/border/replication/stata_compat.R")

results <- list()
notes <- character(0)
add_note <- function(x) notes <<- c(notes, x)

# ---------------------------------------------------------------------------
# 1. Data -- the published CSV. Its column list (61 columns) already carries
#    every variable border.do uses for the Table 6 regressions.
# ---------------------------------------------------------------------------
d <- read.csv(
  (if (file.exists("border.csv")) "border.csv" else
     "https://meta-analysis.cz/data/v1/border/border.csv"),
  stringsAsFactors = FALSE
)
add_note(sprintf("Data: published data/v1/border/border.csv (%d rows).", nrow(d)))
stopifnot(nrow(d) == 1271)

# ---------------------------------------------------------------------------
# 2. Variable construction, replicating border.do lines 14-21 IN ORDER
# ---------------------------------------------------------------------------
#   14  gen prec = 1/se                        (not needed for Table 6)
#   15  replace avyear = avyear - 1899
#   16  gen lncsunits = ln(csunits)
#   17  gen lnyears   = ln(years)
#   18  gen lnobs     = ln(nobs)                (not needed for Table 6)
#   19  replace firstpub = firstpub - 1995
#   20  gen lnyearcits = ln(yearcits + 1)
#   21  xtset idstudy                           (panel variable for xtreg, fe)
d$avyear    <- d$avyear - 1899
d$lncsunits <- log(d$csunits)
d$lnyears   <- log(d$years)
d$firstpub  <- d$firstpub - 1995
d$lnyearcits <- log(d$yearcits + 1)

stopifnot(length(unique(d$idstudy)) == 61)   # matches Table 6's "Studies 61"

# ---------------------------------------------------------------------------
# 3. Table 6, OLS column.
#
#    border.do line 123 (HETEROGENEITY section), run verbatim (weights,
#    variable list and order, and clustering exactly as printed):
#
#      ivreg2 b avyear panel disagg lncsunits lnyears canada us eu oecd emerg
#        nointflow ddiff dactual totalt asym gdpendog remote countryfe ratio
#        avw nores plusone tobit ppml nozeros adjacency language fta published
#        impact lnyearcits firstpub [pweight=invperst], cluster(idstudy idcountry2)
#
#    This 32-regressor list, in this exact order, is also exactly the row
#    order of Table 6. ivreg2 without `small` -> large-sample VCE, z inference.
# ---------------------------------------------------------------------------
ols_fml <- b ~ avyear + panel + disagg + lncsunits + lnyears +
  canada + us + eu + oecd + emerg +
  nointflow + ddiff + dactual + totalt + asym + gdpendog +
  remote + countryfe + ratio + avw + nores +
  plusone + tobit + ppml + nozeros +
  adjacency + language + fta +
  published + impact + lnyearcits + firstpub

#    ONE convention has to be spelled out here, because it is the one place where
#    fixest and ivreg2 disagree and the layer has no switch for it.
#
#    With cluster(idstudy idcountry2) the Cameron-Gelbach-Miller estimator
#
#        V = V(idstudy) + V(idcountry2) - V(idstudy x idcountry2)
#
#    is NOT positive semi-definite on this sample; its smallest eigenvalue is
#    -0.0029. Stata's ivreg2 prints that matrix as it stands and only warns
#    ("estimated covariance matrix of moment conditions not of full rank"),
#    which is what the paper's Table 6 reports. fixest instead repairs the
#    matrix by zeroing the negative eigenvalues (the "VCOV matrix is not
#    positive definite and was 'fixed'" message), and that repair moves the
#    standard errors in the fourth decimal -- enough to turn Emerging's
#    0.2485 into 0.2485+ and print 0.249 where the paper prints 0.248.
#
#    Measured against Stata 15.1 on the same data (ivreg2, line 123 verbatim):
#
#       term    Stata ivreg2   CGM as below   fixest repaired
#       avyear  0.010649017    0.010649017    0.010659282
#       canada  0.350592488    0.350592487    0.350604255
#       us      0.236777609    0.236777608    0.236816954
#       eu      0.394870507    0.394870505    0.395052429
#       oecd    0.335636620    0.335636619    0.336187479
#       emerg   0.248487765    0.248487765    0.248539034   <- the failing cell
#
#    So the three terms of CGM are estimated separately, each through
#    st_ivreg2 with the layer's own large-sample variance profile (each single
#    clustering is PSD on its own, so no repair is triggered in any of them),
#    and added the way ivreg2 adds them. The point estimates are identical in
#    all three fits; only the variance differs.
d$cl_study_country <- interaction(d$idstudy, d$idcountry2, drop = TRUE)
m_ols    <- st_ivreg2(ols_fml, data = d, cluster = ~idstudy,
                      weights = ~invperst)
m_ols_c  <- st_ivreg2(ols_fml, data = d, cluster = ~idcountry2,
                      weights = ~invperst)
m_ols_sc <- st_ivreg2(ols_fml, data = d, cluster = ~cl_study_country,
                      weights = ~invperst)
stopifnot(max(abs(stats::coef(m_ols) - stats::coef(m_ols_c))) < 1e-12,
          max(abs(stats::coef(m_ols) - stats::coef(m_ols_sc))) < 1e-12)
V_cgm <- stats::vcov(m_ols) + stats::vcov(m_ols_c) - stats::vcov(m_ols_sc)
stopifnot(min(eigen(V_cgm, symmetric = TRUE, only.values = TRUE)$values) < 0)

c_ols <- st_coefs(m_ols)                       # estimates + ivreg2's z convention
c_ols$std.error <- sqrt(diag(V_cgm))[c_ols$term]
c_ols$statistic <- c_ols$estimate / c_ols$std.error
c_ols$p.value   <- 2 * stats::pnorm(-abs(c_ols$statistic))

add_note(paste("OLS column: ivreg2 b <32 vars> [pweight=invperst],",
               "cluster(idstudy idcountry2) -- two-way Cameron-Gelbach-Miller variance",
               "assembled from three st_ivreg2 fits and left un-repaired, as ivreg2",
               "leaves it. fixest's automatic positive-definite repair is not Stata's",
               "convention and shifts the SEs in the 4th decimal (Emerging 0.2485 ->",
               "0.2485+, printing 0.249 against the paper's 0.248)."))
g <- function(cf, term) cf[cf$term == term, c("estimate", "std.error", "p.value")]

# ---------------------------------------------------------------------------
# 4. Table 6, Fixed Effects column.
#
#    border.do carries no command for this column (the do-file is dated
#    February 2014; the FE robustness column was evidently added in a later
#    revision without the do-file being updated). The estimator was identified
#    from the printed numbers and then CONFIRMED by running it in Stata 15.1:
#
#      xtreg b avyear panel disagg lncsunits lnyears canada us eu oecd emerg
#        nointflow ddiff dactual totalt asym gdpendog remote countryfe avw
#        nores plusone tobit ppml nozeros adjacency language fta
#        [pweight=invperst], fe vce(cluster idstudy)
#
#    reproduces EVERY printed cell of Table 6's Fixed Effects column, not only
#    the seven this package targets -- including Midyear -0.059 (0.039) 0.130,
#    Inconsistent dist 0.919 (0.248) 0.000, Actual distance -0.754 (0.034)
#    0.000, Anderson est 0.419 (0.130) 0.002 and Language -0.269 (0.103) 0.011.
#    Stata reports e(df_r) = 60, e(N) = 1271, e(N_g) = 61. The reasoning that
#    led there, before the Stata run:
#
#      * every FE p-value in Table 6 is a t(60) p-value, not a z p-value
#        (Emerging: |t| = 1.129/0.558 = 2.02 -> z gives .043, t(60) gives
#        .048 = printed; OECD .0614 vs .066 = printed; Constant .110 vs .115
#        = printed). The OLS column, by contrast, is z (Canada .019 = z).
#        t with G-1 = 60 df is Stata's xtreg/regress cluster convention with
#        61 study clusters -- so the FE column was NOT run through ivreg2.
#      * the printed FE standard errors equal the ONE-WAY study-clustered
#        sandwich with Stata's xtreg,fe small-sample factor
#        G/(G-1)*(N-1)/(N-K), K = 27 slopes + constant (absorbed FEs not
#        counted because they are nested in the cluster). All 26 slope SEs
#        and the constant's SE reproduce to the printed digit under this
#        convention; the two-way (idstudy, idcountry2) LSDV version used in
#        the unweighted variant does not (Canada .296 vs .321).
#
#    So the FE column is the do-file's own xtreg convention from line 110
#    ("xtreg b se, fe vce(cluster idstudy)") applied to the Table 6 spec:
#
#      xtreg b <26 vars> [pweight=invperst], fe vce(cluster idstudy)
#
#    where the 26 vars are the 32 OLS regressors minus the five Table 6
#    leaves blank for lacking within-study variation (ratio, published,
#    impact, lnyearcits, firstpub). The paper's note that the FE standard
#    errors are "clustered at both the study and dataset levels" is not what
#    produced the printed column;.
#
#    Wrapper: st_xtreg_fe(). Its internal paste(deparse(fml), "|", panel)
#    line-wraps a 26-term formula (deparse's fixed 60-char cutoff) and then
#    appends "| idstudy" to every fragment, so a written-out formula cannot be
#    passed through it. A fixest formula macro (setFixest_fml, a formula
#    helper, not an estimator) keeps the formula handed to the wrapper to
#    "b ~ ..ctrl", which fixest expands to the 26 regressors at fit time. The
#    estimation itself is done by st_xtreg_fe exactly as written.
# ---------------------------------------------------------------------------
fe_vars <- c("avyear", "panel", "disagg", "lncsunits", "lnyears",
             "canada", "us", "eu", "oecd", "emerg",
             "nointflow", "ddiff", "dactual", "totalt", "asym", "gdpendog",
             "remote", "countryfe", "avw", "nores",
             "plusone", "tobit", "ppml", "nozeros",
             "adjacency", "language", "fta")
fixest::setFixest_fml(..ctrl = stats::as.formula(paste("~", paste(fe_vars, collapse = " + "))))

m_fe <- st_xtreg_fe(b ~ ..ctrl, data = d, panel = "idstudy",
                    cluster = ~idstudy, weights = ~invperst)
stopifnot(stats::nobs(m_fe) == 1271)          # fixef.rm="none": singletons kept
G_fe <- length(unique(d$idstudy))             # 61 clusters -> t(60)
c_fe <- st_coefs(m_fe, z = FALSE)
c_fe$p.value <- 2 * stats::pt(-abs(c_fe$statistic), df = G_fe - 1)

add_note("FE column: st_xtreg_fe (xtreg b ... [pweight=invperst], fe vce(cluster idstudy)) -- one-way study clustering, Stata xtreg small-sample factor, t(G-1=60) p-values. CONFIRMED in Stata 15.1: this command reproduces every printed cell of Table 6's FE column. The paper's note that the FE standard errors are two-way clustered does not describe the printed FE numbers.")

# ---------------------------------------------------------------------------
# 4b. FE column's Constant: Stata's xtreg,fe _cons. stata_compat.R's own
#     st_xtreg_fe_cons() documents the convention -- "the grand mean of y
#     minus the fitted within slope times the grand mean of x, obtained by an
#     augmented within regression" -- but that wrapper accepts a single x and
#     no weights. The same construction is applied here for 27 x's and
#     pweights: each variable is replaced by (value - study weighted mean +
#     grand weighted mean), and the augmented regression is run through
#     st_regress() with the same cluster and weights (st_xtreg_fe_cons itself
#     is feols with default ssc and cluster=~g, i.e. exactly st_regress).
#     Its intercept is xtreg's _cons and its intercept SE is xtreg's _cons SE.
#     Cross-check: the slope estimates and SEs from this augmented regression
#     equal those from st_xtreg_fe above (asserted below).
# ---------------------------------------------------------------------------
w_fe  <- d$invperst
wmean_by_study <- function(v) stats::ave(v * w_fe, d$idstudy, FUN = sum) /
                              stats::ave(w_fe, d$idstudy, FUN = sum)
aug <- data.frame(idstudy = d$idstudy, invperst = w_fe)
aug$b <- d$b - wmean_by_study(d$b) + stats::weighted.mean(d$b, w_fe)
for (v in fe_vars) aug[[v]] <- d[[v]] - wmean_by_study(d[[v]]) + stats::weighted.mean(d[[v]], w_fe)

m_cons <- st_regress(stats::as.formula(paste("b ~", paste(fe_vars, collapse = " + "))),
                     data = aug, cluster = ~idstudy, weights = ~invperst)
c_cons <- st_coefs(m_cons, z = FALSE)
c_cons$p.value <- 2 * stats::pt(-abs(c_cons$statistic), df = G_fe - 1)
stopifnot(max(abs(c_cons$estimate[match(fe_vars, c_cons$term)] -
                  c_fe$estimate[match(fe_vars, c_fe$term)])) < 1e-8)
stopifnot(max(abs(c_cons$std.error[match(fe_vars, c_cons$term)] -
                  c_fe$std.error[match(fe_vars, c_fe$term)])) < 1e-8)
fe_cons <- g(c_cons, "(Intercept)")

add_note("FE Constant: xtreg,fe _cons via the augmented within regression that st_xtreg_fe_cons() documents, generalised to 27 regressors and pweights and run through st_regress (same cluster/weights); slopes and their SEs from this regression equal st_xtreg_fe's to 1e-8.")

# ---------------------------------------------------------------------------
# 5. Collect + print + write results.json
# ---------------------------------------------------------------------------
put <- function(label, value) {
  results[[label]] <<- unname(value)
  cat(sprintf("%-35s %s\n", label, format(value, digits = 10)))
}

put("N (observations)", stats::nobs(m_ols))
put("Studies", length(unique(d$idstudy)))

for (v in c("Midyear", "Canada", "US", "EU", "OECD", "Emerging", "Constant")) {
  term <- switch(v,
    Midyear = "avyear", Canada = "canada", US = "us", EU = "eu",
    OECD = "oecd", Emerging = "emerg", Constant = "(Intercept)")
  row <- g(c_ols, term)
  put(sprintf("OLS %s coef", v), row$estimate)
  put(sprintf("OLS %s se",   v), row$std.error)
  put(sprintf("OLS %s p",    v), row$p.value)
}

for (v in c("Canada", "US", "EU", "OECD", "Emerging")) {
  term <- switch(v, Canada = "canada", US = "us", EU = "eu",
                 OECD = "oecd", Emerging = "emerg")
  row <- g(c_fe, term)
  put(sprintf("FE %s coef", v), row$estimate)
  put(sprintf("FE %s se",   v), row$std.error)
  put(sprintf("FE %s p",    v), row$p.value)
}
put("FE Constant coef", fe_cons$estimate)
put("FE Constant se",   fe_cons$std.error)
put("FE Constant p",    fe_cons$p.value)

jsonlite::write_json(results, "results.json", auto_unbox = TRUE, digits = NA)

cat("\n")
stata_compat_log()
cat("\nNotes:\n")
cat(paste(" -", notes, collapse = "\n"), "\n")
