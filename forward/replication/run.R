# run.R -- replication of Table A3 (Tests of publication bias, currencies of developed
# countries), Panels A (FAT-PET) and B (PEESE), from:
#   "How Puzzling Is the Forward Premium Puzzle? A Meta-Analysis", European Economic Review 2021
#
# Data: the site-published forward.csv (mirrors the author's forward.dta 1:1, same 82 columns,
# same 3643 rows, just renamed from the author's lowercase Stata names to Title_Case site names).
#
# Author code (forward.do), as given in the brief, for this block:
#   9   use "forward.dta", clear
#   10  xtset studyid
#   21  winsor2 beta se, cuts(5 95) replace
#   22  gen tstat = beta/se
#   23  gen double inv_se = 1/se
#   24  gen double root=sqrt(sample_size_full)
#   25  gen double inv_root=1/root
#   28  gen double inv_nobs=1/nobs if lnspot==0
#   106 gen tstat_w = tstat*sqrt(inv_nobs)
#   107 gen inv_se_w = inv_se*sqrt(inv_nobs)
#   108 gen root_w = root*sqrt(inv_nobs)
#   109 gen inv_sqrt_nobs=sqrt(inv_nobs)
#   110 eststo: xtreg tstat inv_se if lnspot==0 [pweight=inv_nobs], fe                        -> Panel A, FE
#   113 eststo: bootstrap _b, reps(100): ivreg2 tstat_w inv_sqrt_nobs inv_se_w if lnspot==0, noconstant                -> Panel A, WLS
#   114 eststo: bootstrap _b, reps(100): ivreg2 tstat_w inv_sqrt_nobs (inv_se_w=root_w) if lnspot==0, noconstant       -> Panel A, IV
#   119 gen se_w = se*sqrt(inv_nobs)
#   120 gen inv_root_w = inv_root*sqrt(inv_nobs)
#   121 eststo: bootstrap _b, reps(100): reg tstat_w se_w inv_se_w if lnspot==0, noconstant                            -> Panel B, WLS
#   122 eststo: bootstrap _b, reps(100): ivreg2 tstat_w (inv_se_w se_w = inv_root_w root_w) if lnspot==0, noconstant   -> Panel B, IV
#
# Table A3's note: "Only difference estimates (Eq. 3) for the currencies of advanced countries
# are included." In the site's column names: lnSpot == 0 is the differences specification; the
# "advanced countries" sample is not spelled out by an explicit `if`/`drop` line in the brief's
# code excerpt, so it is pinned empirically instead (see REPLICATION.md): lnSpot==0 &
# Emerging_currencies==0 (i.e. advanced + mixed-currency studies, excluding emerging-market
# currencies) gives EXACTLY N = 2582, the Observations row printed under every column of Table
# A3. That is treated as decisive evidence for the sample filter.
#
# Two cells are NOT attempted (see REPLICATION.md / misses): the FE column's "Publication bias"
# (constant) in Panel A, because st_xtreg_fe_cons() has no `weights` argument and the FE model
# here is estimated with [pweight = inv_nobs] -- inventing a weighted variant would mean editing
# or working around stata_compat.R, which is forbidden; and the entire FE column of Panel B,
# because no do-file line for it appears anywhere in the brief.

source("stata_compat.R")

set.seed(NULL)  # author's bootstrap carries no seed() option -> genuinely stochastic; not repaired

data_path <- "C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\forward\\forward.csv"
d <- read.csv(data_path, stringsAsFactors = FALSE)

results <- list()
add <- function(label, value) results[[label]] <<- value

# ---------------------------------------------------------------------- prep (whole dataset)
# winsor2 beta se, cuts(5 95) replace  -- on the FULL just-loaded dataset, before any `if`.
d$Coeff_w <- st_winsor2(d$Coeff, cuts = c(5, 95))
d$SE_w    <- st_winsor2(d$SE,    cuts = c(5, 95))
d$tstat   <- d$Coeff_w / d$SE_w
d$inv_se  <- 1 / d$SE_w

# ------------------------------------------------------------- Table A3 sample (Advanced, Eq.3)
# gen double inv_nobs=1/nobs if lnspot==0  (line 28) sits BEFORE any country-scope restriction
# in the do-file's line order, so `nobs` -- a study's count of difference-equation estimates --
# is computed on the WHOLE lnspot==0 population (2989 obs, all currency scopes), not on the
# advanced-only subsample. Confirmed empirically: computing nobs on the advanced-only subsample
# instead moves every coefficient 5-15% off the printed value; computed on the full lnspot==0
# population, every deterministic cell below matches to the printed digit.
d0 <- st_keep_if(d, d$lnSpot == 0)
nobs_tab <- table(d0$StudyID)
d0$nobs     <- as.numeric(nobs_tab[as.character(d0$StudyID)])
d0$inv_nobs <- 1 / d0$nobs

dA <- st_keep_if(d0, d0$Emerging_currencies == 0)
n_adv <- nrow(dA)
add("A3_PanelA_Obs", n_adv)
add("A3_PanelB_Obs", n_adv)

dA$root          <- sqrt(dA$Sample_size)
dA$inv_root      <- 1 / dA$root
dA$tstat_w       <- dA$tstat * sqrt(dA$inv_nobs)
dA$inv_se_w      <- dA$inv_se * sqrt(dA$inv_nobs)
dA$root_w        <- dA$root * sqrt(dA$inv_nobs)
dA$inv_sqrt_nobs <- sqrt(dA$inv_nobs)
dA$se_w          <- dA$SE_w * sqrt(dA$inv_nobs)
dA$inv_root_w    <- dA$inv_root * sqrt(dA$inv_nobs)

# ----------------------------------------------------------------------- bootstrap SE helper
# Mirrors Stata's `bootstrap _b, reps(R): <cmd>`: no cluster() given in the author's bootstrap
# prefix, so this is plain obs-level resampling with replacement, refit each time through the
# SAME wrapper used for the point estimate. SD across reps is the bootstrap SE. Stochastic --
# reported for completeness, never used to judge the verdict.
boot_se <- function(fit_fun, data, term, reps = 100) {
  n <- nrow(data)
  ests <- rep(NA_real_, reps)
  for (i in seq_len(reps)) {
    idx <- sample.int(n, n, replace = TRUE)
    est <- tryCatch({
      m <- fit_fun(data[idx, , drop = FALSE])
      cf <- st_coefs(m)
      cf$estimate[cf$term == term]
    }, error = function(e) NA_real_)
    ests[i] <- if (length(est) == 1) est else NA_real_
  }
  stats::sd(ests, na.rm = TRUE)
}

# =========================================================== Panel A: FAT-PET (N = 2582)

## FE: xtreg tstat inv_se if lnspot==0 [pweight=inv_nobs], fe
m_fe_A <- st_xtreg_fe(tstat ~ inv_se, data = dA, panel = "StudyID", weights = ~inv_nobs)
cf_fe_A <- st_coefs(m_fe_A)
add("A3_PanelA_FE_MeanBeyondBias",    cf_fe_A$estimate[cf_fe_A$term == "inv_se"])
add("A3_PanelA_FE_MeanBeyondBias_SE", cf_fe_A$std.error[cf_fe_A$term == "inv_se"])
# Publication bias (constant) for the WEIGHTED FE model: st_xtreg_fe_cons() takes no `weights`
# argument, and the FE model here is estimated with [pweight=inv_nobs] -- not attempted.
add("A3_PanelA_FE_PubBias", NA)
add("A3_PanelA_FE_PubBias_SE", NA)

## WLS: ivreg2 tstat_w inv_sqrt_nobs inv_se_w if lnspot==0, noconstant  (bootstrap, reps(100))
fit_wls_A <- function(dat) st_ivreg2(tstat_w ~ inv_sqrt_nobs + inv_se_w - 1, data = dat)
m_wls_A <- fit_wls_A(dA)
cf_wls_A <- st_coefs(m_wls_A)
add("A3_PanelA_WLS_MeanBeyondBias", cf_wls_A$estimate[cf_wls_A$term == "inv_se_w"])
add("A3_PanelA_WLS_PubBias",        cf_wls_A$estimate[cf_wls_A$term == "inv_sqrt_nobs"])
add("A3_PanelA_WLS_MeanBeyondBias_SE", boot_se(fit_wls_A, dA, "inv_se_w"))
add("A3_PanelA_WLS_PubBias_SE",        boot_se(fit_wls_A, dA, "inv_sqrt_nobs"))

## IV: ivreg2 tstat_w inv_sqrt_nobs (inv_se_w=root_w) if lnspot==0, noconstant  (bootstrap 100)
fit_iv_A <- function(dat) st_ivreg2(tstat_w ~ inv_sqrt_nobs - 1 | inv_se_w ~ root_w, data = dat)
m_iv_A <- fit_iv_A(dA)
cf_iv_A <- st_coefs(m_iv_A)
add("A3_PanelA_IV_MeanBeyondBias", cf_iv_A$estimate[cf_iv_A$term == "fit_inv_se_w"])
add("A3_PanelA_IV_PubBias",        cf_iv_A$estimate[cf_iv_A$term == "inv_sqrt_nobs"])
add("A3_PanelA_IV_MeanBeyondBias_SE", boot_se(fit_iv_A, dA, "fit_inv_se_w"))
add("A3_PanelA_IV_PubBias_SE",        boot_se(fit_iv_A, dA, "inv_sqrt_nobs"))

# =========================================================== Panel B: PEESE (N = 2582)

## FE column: no do-file line for it appears in the brief -- not attempted.
add("A3_PanelB_FE_MeanBeyondBias", NA)
add("A3_PanelB_FE_MeanBeyondBias_SE", NA)
add("A3_PanelB_FE_PubBias", NA)
add("A3_PanelB_FE_PubBias_SE", NA)

## WLS: reg tstat_w se_w inv_se_w if lnspot==0, noconstant  (bootstrap, reps(100))
fit_wls_B <- function(dat) st_regress(tstat_w ~ se_w + inv_se_w - 1, data = dat)
m_wls_B <- fit_wls_B(dA)
cf_wls_B <- st_coefs(m_wls_B, z = FALSE)
add("A3_PanelB_WLS_MeanBeyondBias", cf_wls_B$estimate[cf_wls_B$term == "inv_se_w"])
add("A3_PanelB_WLS_PubBias",        cf_wls_B$estimate[cf_wls_B$term == "se_w"])
add("A3_PanelB_WLS_MeanBeyondBias_SE", boot_se(fit_wls_B, dA, "inv_se_w"))
add("A3_PanelB_WLS_PubBias_SE",        boot_se(fit_wls_B, dA, "se_w"))

## IV: ivreg2 tstat_w (inv_se_w se_w = inv_root_w root_w) if lnspot==0, noconstant (bootstrap 100)
fit_iv_B <- function(dat) st_ivreg2(tstat_w ~ 0 | inv_se_w + se_w ~ inv_root_w + root_w, data = dat)
m_iv_B <- fit_iv_B(dA)
cf_iv_B <- st_coefs(m_iv_B)
add("A3_PanelB_IV_MeanBeyondBias", cf_iv_B$estimate[cf_iv_B$term == "fit_inv_se_w"])
add("A3_PanelB_IV_PubBias",        cf_iv_B$estimate[cf_iv_B$term == "fit_se_w"])
add("A3_PanelB_IV_MeanBeyondBias_SE", boot_se(fit_iv_B, dA, "fit_inv_se_w"))
add("A3_PanelB_IV_PubBias_SE",        boot_se(fit_iv_B, dA, "fit_se_w"))

# --------------------------------------------------------------------------------- report
cat("=== Produced values ===\n")
for (nm in names(results)) {
  v <- results[[nm]]
  cat(sprintf("%-32s %s\n", nm, if (is.na(v)) "NA" else format(round(v, 4), nsmall = 4)))
}

writeLines(
  paste0("{\n", paste(sprintf('  "%s": %s', names(results),
                               sapply(results, function(v) if (is.na(v)) "null" else format(v, digits = 10))),
                       collapse = ",\n"), "\n}"),
  "results.json"
)
