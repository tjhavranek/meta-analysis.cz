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
# available for this paper does not include the commands that produce them (Panel B
# needs commands not shown at all; the top3/top5 filters are not shown either), so
# nothing here would be provenanced. See REPLICATION.md.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/hedge/replication/stata_compat.R")

data_path <- (if (file.exists("hedge.csv")) "hedge.csv" else
     "https://meta-analysis.cz/data/v1/hedge/hedge.csv")
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

# ===================================================================================
# Table 2, Panel A (linear FAT-PET specifications), FULL SAMPLE -- hedge.do lines
# 88-106, no `if` restriction at all (this is the un-subsetted block that every
# Table-3/4/5/6 subsample block in the .do file is a copy of, with an `if` clause
# stapled on). This is the source data for the paper's headline claim.
#
# Abstract: "Most of our monthly alpha estimates adjusted for the (small) bias fall
#   within a relatively narrow range of 30-40 basis points" [monthly alpha, in %].
# Body text, Section 4.4 ("we thus conclude that clustering of standard errors at the
#   level of a research team leads us to similar conclusions ... as our main results"):
#   "the kappa coefficients fall within a fairly narrow interval of (0.301, 0.369) that
#   is fully subsumed by the corresponding interval that we observe for our main
#   results (0.274, 0.386)."
# Table 7 ("Results overview"), row "Table 2 / Full sample": #Studies 74, #Alphas 1019,
#   Mean 0.335, StDev 0.033, Min 0.274, Md 0.338, Max 0.386.
# Figure 3 / Section 3: "the unconditional sample mean of monthly alphas of 0.36%,
#   which corresponds to 4.3% per annum".
#
# What (0.301, 0.369) and (0.274, 0.386) actually are, worked out from Table 2 itself:
# Table 2 has two panels, twelve "effect beyond bias" (kappa) cells in total for the
# full sample -- Panel A: OLS/FE/BE/IV/WLS/wNOBS (the linear FAT-PET/PEESE family, run
# below); Panel B: Top10/WAAP/Stem-based/Kinked-meta/Selection model/p-uniform* (five
# non-linear meta-analysis estimators). Since clustering choice changes standard
# errors, not point estimates, Panel A's own six kappas are IDENTICAL whether the paper
# clusters by study_id (its main Table 2) or by team_id (its Table A.2 robustness
# check) -- which is exactly why the (0.301, 0.369) interval quoted for the
# team-clustered Table A.2 equals the min/max of the SAME six numbers we reproduce
# below for the main Table 2. The wider headline interval (0.274, 0.386) is the min/max
# across all TWELVE cells (Panel A + Panel B): 0.274 is Panel B's Selection model, 0.386
# is Panel B's p-uniform*. Table 7's Mean 0.335 / Md 0.338 are like-wise the mean/median
# of all twelve kappas, not of Panel A's six alone (verified by hand against the
# printed Panel A and Panel B cells: mean = 0.3354, median = 0.3375, both rounding to
# the printed 0.335 / 0.338).
# ===================================================================================
cat("\n=== Table 2 Panel A: Full sample (no subsetting) -- source of the headline claim ===\n")
run_panelA(d0, rep(TRUE, nrow(d0)), "T2")

kappa_labels <- c("T2_OLS_kappa", "T2_FE_kappa", "T2_BE_kappa",
                  "T2_IV_kappa", "T2_WLS_kappa", "T2_wNOBS_kappa")
kappa_vals <- unlist(results[kappa_labels])
rec("T2_kappa_min",    min(kappa_vals))
rec("T2_kappa_max",    max(kappa_vals))
rec("T2_kappa_mean",   mean(kappa_vals))
rec("T2_kappa_median", median(kappa_vals))

## "unconditional sample mean of 0.36%" (Figure 3's vertical line / text) -- the plain
## mean of the winsorised alpha variable across the full sample, no regression at all.
rec("T2_alpha_unconditional_mean", mean(d0$alpha_w))
rec("T2_alpha_unconditional_mean_annualized", mean(d0$alpha_w) * 12)

## Panel B (Top10, WAAP, Stem-based, Kinked-meta, Selection model, p-uniform*) is NOT
## computed here -- no stata_compat.R wrapper implements any of these five
## meta-analysis estimators, and the author's code for this paper
## contains no commands for them either (see REPLICATION.md), so there is nothing to
## provenance an implementation against. The five "kind not_reproduced" targets below
## record the paper's own printed Panel B cells verbatim, for arithmetic cross-checking
## only (e.g. confirming that combining them with our reproduced Panel A cells recovers
## Table 7's printed Mean/Md/Min/Max) -- they are NOT independently recomputed from
## hedge.csv and results.json labels them accordingly.
panelB_kappa_paper <- c(Top10 = 0.310, WAAP = 0.325, Stem = 0.355,
                        Kinked = 0.320, Selection = 0.274, puniform = 0.386)
for (nm in names(panelB_kappa_paper)) {
  results[[paste0("T2_PanelB_", nm, "_kappa_PAPER_VALUE_NOT_REPRODUCED")]] <- as.numeric(panelB_kappa_paper[nm])
}
all12 <- c(kappa_vals, panelB_kappa_paper)
rec("T2_all12_min",    min(all12))
rec("T2_all12_max",    max(all12))
rec("T2_all12_mean",   mean(all12))
rec("T2_all12_median", median(all12))

cat("\n")
cat("=====================================================================\n")
cat("PAPER'S HEADLINE CLAIM (abstract & conclusion): \"30-40 basis points\"\n")
cat("=====================================================================\n")
cat("REPRODUCED from hedge.csv (Table 2 Panel A, six linear specifications,\n")
cat("OLS/FE/BE/IV/WLS/wNOBS -- exact same point estimates the paper reports whether\n")
cat("clustered by study_id [main Table 2] or by team_id [Table A.2 robustness]):\n")
cat(sprintf("    kappa range  : %.3f to %.3f  (%.1f to %.1f bp)   paper quote: \"(0.301, 0.369)\"\n",
            results$T2_kappa_min, results$T2_kappa_max, results$T2_kappa_min*100, results$T2_kappa_max*100))
cat(sprintf("    unconditional (plain) sample mean of alpha_w : %.4f%% (%.1f bp)   paper: \"0.36%%\"\n",
            results$T2_alpha_unconditional_mean, results$T2_alpha_unconditional_mean*100))
cat(sprintf("    ... annualized (x12): %.2f%% p.a.   paper: \"4.3%% per annum\" (from its own rounded 0.36 x 12 = 4.32%%)\n",
            results$T2_alpha_unconditional_mean_annualized))
cat("\n")
cat("NOT independently reproduced (no wrapper / no author code for these 5 estimators):\n")
cat("Panel B nonlinear kappas are the paper's own printed cells, used only to show the\n")
cat("arithmetic of the FULL 12-cell headline range and Table 7's mean/median checks out:\n")
cat(sprintf("    combined 12-cell (6 reproduced Panel A + 6 paper-quoted Panel B) range : %.3f to %.3f   paper: \"0.274 to 0.386\"\n",
            results$T2_all12_min, results$T2_all12_max))
cat(sprintf("    combined 12-cell mean   : %.4f   paper Table 7 Mean : 0.335\n", results$T2_all12_mean))
cat(sprintf("    combined 12-cell median : %.4f   paper Table 7 Md   : 0.338\n", results$T2_all12_median))
cat("=====================================================================\n\n")

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
