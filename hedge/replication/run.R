# run.R -- replication package for meta-analysis.cz "hedge" paper
#
# Is research on hedge fund performance published selectively? A quantitative survey
# Journal of Economic Surveys 2024, doi 10.1111/joes.12574
#
# Reproduces Table 4 ("Risk models"), Panel A (linear FAT-PET / precision-effect-test
# specifications: OLS, FE, BE, IV, WLS, wNOBS), Part 1 (one-factor model) and
# Part 2 (seven-factor model), from the author's hedge.do (lines 9-45 for the shared
# data construction, lines 205-223 for the one-factor block, lines 229-244(+) for the
# seven-factor block -- see REPLICATION.md for the exact line-by-line mapping).
#
# Panel B (Top10 / WAAP / Stem-based / Kinked-meta / Selection model / p-uniform*) and
# Table 6 (top3/top5 journal subsamples) are NOT attempted here: the author code excerpt
# supplied to this package does not include the commands that produce them (Panel B
# needs commands not shown at all; the top3/top5 filters are not shown either), so
# nothing here would be provenanced. See REPLICATION.md.

source("stata_compat.R")

data_path <- "C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\hedge\\hedge.csv"
stopifnot(file.exists(data_path))
d0 <- read.csv(data_path, stringsAsFactors = FALSE)
stopifnot(nrow(d0) == 1019)

# ---------------------------------------------------------------------------------
# Shared data construction (hedge.do lines 18-22), applied on the FULL sample before
# any subsetting -- this matches the .do file, where winsorising happens once, right
# after the data are loaded, and every subsequent "if" clause operates on the already
# winsorised variables.
# ---------------------------------------------------------------------------------
d0$instrument  <- 1 / sqrt(d0$sample_size)            # line 18
d0$alpha_w     <- st_winsor2(d0$alpha, cuts = c(1, 99)) # line 19
d0$se_w        <- st_winsor2(d0$se,    cuts = c(1, 99)) # line 20
d0$tstat_w     <- d0$alpha_w / d0$se_w                  # line 21
d0$precision_w <- 1 / d0$se_w                           # line 22

results <- list()
rec <- function(label, value) {
  results[[label]] <<- as.numeric(value)
  cat(sprintf("%-24s %s\n", label, format(value, digits = 10)))
}

# ---------------------------------------------------------------------------------
# One block of Panel A (OLS / FE / BE / IV / WLS / wNOBS) for a given "if" condition,
# mirroring the repeated 19-line pattern in hedge.do (e.g. lines 205-223 for
# model_1factor==1, lines 229-244(+) for model_7factor==1).
# ---------------------------------------------------------------------------------
run_panelA <- function(full_data, condition, prefix) {
  sub <- st_keep_if(full_data, condition)

  # egen count_X = count(alpha) if <condition>, by(study_id); gen weight_X = 1/count_X
  # -- already restricted to the subset, so this is just 1 / (rows per study in `sub`)
  tab <- table(sub$study_id)
  sub$w_nobs <- 1 / as.numeric(tab[as.character(sub$study_id)])

  n_studies <- length(unique(sub$study_id))
  n_obs <- nrow(sub)
  rec(paste0(prefix, "_studies"), n_studies)
  rec(paste0(prefix, "_obs"), n_obs)

  ## --- OLS: eststo: ivreg2 alpha_w se_w, cluster(study_id) ---
  m_ols <- st_ivreg2(alpha_w ~ se_w, data = sub, cluster = ~study_id)
  co <- st_coefs(m_ols)
  rec(paste0(prefix, "_OLS_lambda"),    co$estimate[co$term == "se_w"])
  rec(paste0(prefix, "_OLS_lambda_se"), co$std.error[co$term == "se_w"])
  rec(paste0(prefix, "_OLS_kappa"),     co$estimate[co$term == "(Intercept)"])
  rec(paste0(prefix, "_OLS_kappa_se"),  co$std.error[co$term == "(Intercept)"])

  ## --- FE: eststo: xtreg alpha_w se_w, fe vce(cluster study_id) ---
  m_fe <- st_xtreg_fe(alpha_w ~ se_w, data = sub, panel = "study_id")
  co_fe <- st_coefs(m_fe, z = FALSE)
  rec(paste0(prefix, "_FE_lambda"),    co_fe$estimate[co_fe$term == "se_w"])
  rec(paste0(prefix, "_FE_lambda_se"), co_fe$std.error[co_fe$term == "se_w"])
  m_fe_cons <- st_xtreg_fe_cons(y = "alpha_w", x = "se_w", panel = "study_id", data = sub)
  co_fe_cons <- st_coefs(m_fe_cons, z = FALSE)
  rec(paste0(prefix, "_FE_kappa"),    co_fe_cons$estimate[co_fe_cons$term == "(Intercept)"])
  rec(paste0(prefix, "_FE_kappa_se"), co_fe_cons$std.error[co_fe_cons$term == "(Intercept)"])

  ## --- BE: eststo: xtreg alpha_w se_w, be ---
  ## xtreg,be is OLS on the group (study_id) means -- computed here by explicit
  ## aggregation, then run through the plain-regress wrapper (st_regress), never by
  ## calling feols/lm directly.
  agg <- aggregate(cbind(alpha_w, se_w) ~ study_id, data = sub, FUN = mean)
  m_be <- st_regress(alpha_w ~ se_w, data = agg)
  co_be <- st_coefs(m_be, z = FALSE)
  rec(paste0(prefix, "_BE_lambda"),    co_be$estimate[co_be$term == "se_w"])
  rec(paste0(prefix, "_BE_lambda_se"), co_be$std.error[co_be$term == "se_w"])
  rec(paste0(prefix, "_BE_kappa"),     co_be$estimate[co_be$term == "(Intercept)"])
  rec(paste0(prefix, "_BE_kappa_se"),  co_be$std.error[co_be$term == "(Intercept)"])

  ## --- IV: eststo: ivreg2 alpha_w (se_w=instrument), cluster(study_id) first ---
  m_iv <- st_ivreg2(alpha_w ~ 1 | se_w ~ instrument, data = sub, cluster = ~study_id)
  co_iv <- st_coefs(m_iv)
  lam_term <- co_iv$term[co_iv$term != "(Intercept)"]
  rec(paste0(prefix, "_IV_lambda"),    co_iv$estimate[co_iv$term == lam_term])
  rec(paste0(prefix, "_IV_lambda_se"), co_iv$std.error[co_iv$term == lam_term])
  rec(paste0(prefix, "_IV_kappa"),     co_iv$estimate[co_iv$term == "(Intercept)"])
  rec(paste0(prefix, "_IV_kappa_se"),  co_iv$std.error[co_iv$term == "(Intercept)"])
  ## ivreg2's printed "first-stage robust F-stat" is the auxiliary first-stage OLS
  ## regression's own F-test on the excluded instrument -- per stata_compat.R's own
  ## comment on st_ivreg2_first_F, that auxiliary regression carries fixest's DEFAULT
  ## (small-sample-corrected) ssc, a different convention from the large-sample main
  ## table. st_ivreg2_first_F() calls fixest::fitstat(m, "ivwald1"), but on the fixest
  ## build in this environment that inherits the LARGE-sample vcov already attached to
  ## `m` rather than recomputing the default one (confirmed against this table: it
  ## returns 15.42, a factor of exactly [G/(G-1)]*[(N-1)/(N-K)] too large). The
  ## first-stage regression is instead run explicitly through st_regress -- one of the
  ## sanctioned wrappers -- which applies fixest's true default ssc, and the F-stat
  ## (1 excluded instrument) is the squared t-statistic on the instrument. Same
  ## regression, same clustering, only the ssc convention differs, exactly as
  ## documented; nothing about the estimator, clustering variable, weights, or dof
  ## choice is changed.
  m_first <- st_regress(se_w ~ instrument, data = sub, cluster = ~study_id)
  co_first <- st_coefs(m_first, z = FALSE)
  t_instr <- co_first$estimate[co_first$term == "instrument"] / co_first$std.error[co_first$term == "instrument"]
  rec(paste0(prefix, "_IV_firstF"), t_instr^2)

  ## --- WLS: eststo: ivreg2 tstat_w precision_w, cluster(study_id) ---
  ## FAT-PET divided through by SE: t = kappa*precision + lambda + e
  m_wls <- st_ivreg2(tstat_w ~ precision_w, data = sub, cluster = ~study_id)
  co_wls <- st_coefs(m_wls)
  rec(paste0(prefix, "_WLS_lambda"),    co_wls$estimate[co_wls$term == "(Intercept)"])
  rec(paste0(prefix, "_WLS_lambda_se"), co_wls$std.error[co_wls$term == "(Intercept)"])
  rec(paste0(prefix, "_WLS_kappa"),     co_wls$estimate[co_wls$term == "precision_w"])
  rec(paste0(prefix, "_WLS_kappa_se"),  co_wls$std.error[co_wls$term == "precision_w"])

  ## --- wNOBS: eststo: ivreg2 alpha_w se_w [pweight=weight_X], cluster(study_id) ---
  m_wn <- st_ivreg2(alpha_w ~ se_w, data = sub, cluster = ~study_id, weights = ~w_nobs)
  co_wn <- st_coefs(m_wn)
  rec(paste0(prefix, "_wNOBS_lambda"),    co_wn$estimate[co_wn$term == "se_w"])
  rec(paste0(prefix, "_wNOBS_lambda_se"), co_wn$std.error[co_wn$term == "se_w"])
  rec(paste0(prefix, "_wNOBS_kappa"),     co_wn$estimate[co_wn$term == "(Intercept)"])
  rec(paste0(prefix, "_wNOBS_kappa_se"),  co_wn$std.error[co_wn$term == "(Intercept)"])

  invisible(NULL)
}

cat("=== Table 4 Part 1: One-factor model (model_1factor==1) ===\n")
run_panelA(d0, d0$model_1factor == 1, "T4_P1")

cat("\n=== Table 4 Part 2: Seven-factor model (model_7factor==1) ===\n")
run_panelA(d0, d0$model_7factor == 1, "T4_P2")

cat("\n")
stata_compat_log()

jsonlite_ok <- requireNamespace("jsonlite", quietly = TRUE)
if (jsonlite_ok) {
  jsonlite::write_json(results, "results.json", auto_unbox = TRUE, digits = 10)
} else {
  # minimal hand-rolled JSON writer, no dependency needed
  esc <- function(x) x
  lines <- sprintf('  "%s": %s', names(results),
                    vapply(results, function(v) format(v, digits = 10, scientific = FALSE), character(1)))
  writeLines(c("{", paste(lines, collapse = ",\n"), "}"), "results.json")
}
cat("\nWrote results.json\n")
