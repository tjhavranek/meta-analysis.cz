# Replication of Havranek (2015, JEEA) "Measuring Intertemporal Substitution:
# The Importance of Method Choices and Selective Reporting"
# -- Table 2 (the paper's headline publication-bias / heterogeneity table).
#
# Provenance: an author .do file for this paper was found in the working scratch
# tree (scratchpad/eiswork/eis/eis.do), even though the brief said none ships.
# It is used here as the specification source for Table 2's "EXPLAINING
# HETEROGENEITY" block (the seven `reg tstat ... [pweight=invperstudy],
# vce(cluster idstudy)` lines). Table 2's own row/column numbers (the printed
# targets) come only from the paper text, per the brief.

source("stata_compat.R")

d <- read.csv(
  "C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\eis\\eis.csv",
  stringsAsFactors = FALSE
)

cat("Rows read:", nrow(d), "  Studies:", length(unique(d$idstudy)), "\n")

# ---------------------------------------------------------------------------
# Variable construction, following eis.do exactly.
# ---------------------------------------------------------------------------
d$prec  <- 1 / d$se
d$tstat <- d$eis / d$se

d$lncsunits  <- log(d$csunits)
d$lnyears    <- log(d$years)
d$lnavyear   <- log(d$avyear)
d$lnpubyear  <- log(d$pubyear)
d$lnyearcits <- log(d$yearcits + 1)
d$lntastes   <- log(d$tastes + 1)

d$noyearfe <- 0
d$noyearfe[d$micro == 1 & d$quasipan == 0 & d$food == 1 & d$yearfe == 0] <- 1

d$invperstudy <- 1 / d$perstudy

# every method/study characteristic divided by SE, as in eis.do's `foreach x
# of varlist rhsvars { gen `x'_se = `x' / se }` loop -- the whole regression
# is the levels FAT-PET-MRA model divided through by SE to homogenize the
# error variance, then estimated as tstat on (prec, X/se, ...).
rhsvars <- c("lncsunits", "lnpubyear", "lnyears", "lnavyear", "lnyearcits",
             "lntastes", "noyearfe", "micro", "quasipan", "sepdur", "sepgov",
             "septrd", "seprisk", "habits", "inverse", "exact", "totalc",
             "food", "ml", "tsls", "ols", "income", "firstlag", "stockhold",
             "irstock", "ircap", "annual", "monthly", "top", "impact")
for (v in rhsvars) d[[paste0(v, "_se")]] <- d[[v]] / d$se

# ---------------------------------------------------------------------------
# Table 2, columns (1)-(7): cumulative blocks of controls, exactly as the
# seven `eststo: reg tstat ... [pweight=invperstudy], vce(cluster idstudy)`
# lines in eis.do's "EXPLAINING HETEROGENEITY" section.
# ---------------------------------------------------------------------------
blocks <- list(
  c("prec", "micro_se", "stockhold_se"),
  c("seprisk_se", "habits_se", "sepdur_se", "sepgov_se", "septrd_se"),
  c("lncsunits_se", "lnyears_se", "lnavyear_se", "annual_se", "monthly_se"),
  c("quasipan_se", "inverse_se", "firstlag_se", "noyearfe_se", "income_se", "lntastes_se"),
  c("totalc_se", "food_se", "irstock_se", "ircap_se"),
  c("exact_se", "ml_se", "tsls_se", "ols_se"),
  c("lnpubyear_se", "lnyearcits_se", "top_se", "impact_se")
)

rhs_cum <- character(0)
results <- list()
n_clusters <- length(unique(d$idstudy))

for (col in seq_along(blocks)) {
  rhs_cum <- c(rhs_cum, blocks[[col]])
  fml <- stats::as.formula(paste("tstat ~", paste(rhs_cum, collapse = " + ")))
  m <- st_regress(fml, data = d, cluster = ~idstudy, weights = ~invperstudy)
  co <- st_coefs(m, z = FALSE)
  results[[col]] <- list(model = m, coefs = co)

  se_row    <- co[co$term == "(Intercept)", ]
  micro_row <- co[co$term == "micro_se", ]
  asset_row <- co[co$term == "stockhold_se", ]

  cat(sprintf("\n--- Table 2, column (%d) --- N=%d, clusters=%d\n",
              col, stats::nobs(m), n_clusters))
  cat(sprintf("T2 col%d SE coef = %.4f\n", col, se_row$estimate))
  cat(sprintf("T2 col%d SE se = %.4f\n", col, se_row$std.error))
  cat(sprintf("T2 col%d Micro coef = %.4f\n", col, micro_row$estimate))
  cat(sprintf("T2 col%d Micro se = %.4f\n", col, micro_row$std.error))
  cat(sprintf("T2 col%d Asset coef = %.4f\n", col, asset_row$estimate))
  cat(sprintf("T2 col%d Asset se = %.4f\n", col, asset_row$std.error))
}

out <- list()
for (col in seq_along(blocks)) {
  co <- results[[col]]$coefs
  se_row    <- co[co$term == "(Intercept)", ]
  micro_row <- co[co$term == "micro_se", ]
  asset_row <- co[co$term == "stockhold_se", ]
  out[[sprintf("T2 col%d SE coef", col)]]    <- unname(se_row$estimate)
  out[[sprintf("T2 col%d SE se", col)]]      <- unname(se_row$std.error)
  out[[sprintf("T2 col%d Micro coef", col)]] <- unname(micro_row$estimate)
  out[[sprintf("T2 col%d Micro se", col)]]   <- unname(micro_row$std.error)
  out[[sprintf("T2 col%d Asset coef", col)]] <- unname(asset_row$estimate)
  out[[sprintf("T2 col%d Asset se", col)]]   <- unname(asset_row$std.error)
}

m1 <- results[[1]]$model
co1 <- results[[1]]$coefs
prec_row <- co1[co1$term == "prec", ]

cat(sprintf("\nT2 col1 Constant (EIS0) = %.4f\n", prec_row$estimate))
out[["T2 col1 Constant (EIS0)"]] <- unname(prec_row$estimate)

n1 <- stats::nobs(m1)
cat(sprintf("T2 col1 N = %d\n", n1))
cat(sprintf("T2 col1 Studies = %d\n", n_clusters))
out[["T2 col1 N"]] <- n1
out[["T2 col1 Studies"]] <- n_clusters

m7 <- results[[7]]$model
n7 <- stats::nobs(m7)
cat(sprintf("T2 col7 N = %d\n", n7))
cat(sprintf("T2 col7 Studies = %d\n", n_clusters))
out[["T2 col7 N"]] <- n7
out[["T2 col7 Studies"]] <- n_clusters

# ---------------------------------------------------------------------------
# Derived quantities quoted in the paper's prose for column (1):
#   corrected elasticity, micro           = EIS0 + micro
#   corrected elasticity, micro & assets  = EIS0 + micro + stockhold
#   95% CI for the latter combination, via the delta method on the same
#   cluster-robust vcov (t-distribution, df = clusters - 1, as `regress`
#   with vce(cluster) uses -- matching Stata's `lincom` after this model).
# ---------------------------------------------------------------------------
b <- stats::coef(m1)
V <- stats::vcov(m1)
terms3 <- c("prec", "micro_se", "stockhold_se")

combo_micro <- b[["prec"]] + b[["micro_se"]]
cat(sprintf("\nCorrected elasticity, micro (col1) = %.4f\n", combo_micro))
out[["Corrected elasticity, micro (col1)"]] <- unname(combo_micro)

L <- setNames(rep(0, length(b)), names(b))
L[terms3] <- 1
combo_asset <- sum(L * b)
se_asset <- sqrt(as.numeric(t(L) %*% V %*% L))
tcrit <- stats::qt(0.975, df = n_clusters - 1)
ci_lo <- combo_asset - tcrit * se_asset
ci_hi <- combo_asset + tcrit * se_asset

cat(sprintf("Corrected elasticity, micro asset holders (col1) = %.4f (se=%.4f)\n",
            combo_asset, se_asset))
cat(sprintf("95%% CI micro asset holders (col1) = [%.4f, %.4f]\n", ci_lo, ci_hi))
out[["Corrected elasticity, micro asset holders (col1)"]] <- unname(combo_asset)
out[["95% CI lower, micro asset holders (col1)"]] <- unname(ci_lo)
out[["95% CI upper, micro asset holders (col1)"]] <- unname(ci_hi)

cat("\n")
stata_compat_log()

jsonlite_ok <- requireNamespace("jsonlite", quietly = TRUE)
if (jsonlite_ok) {
  writeLines(jsonlite::toJSON(out, auto_unbox = TRUE, digits = 10), "results.json")
} else {
  # minimal hand-rolled JSON writer (no external dependency required)
  esc <- function(s) gsub('"', '\\"', s, fixed = TRUE)
  lines <- vapply(names(out), function(k) {
    v <- out[[k]]
    sprintf('  "%s": %s', esc(k),
            if (is.numeric(v)) format(v, digits = 12, scientific = FALSE, trim = TRUE) else sprintf('"%s"', esc(v)))
  }, character(1))
  json_txt <- paste0("{\n", paste(lines, collapse = ",\n"), "\n}\n")
  writeLines(json_txt, "results.json")
}

cat("\nWrote results.json with", length(out), "entries.\n")
