# run.R -- replication of Gechert, Havranek, Irsova & Kolcunova (2022, RED),
# "Measuring Capital-Labor Substitution: The Importance of Method Choices and
# Publication Bias", Table 5 "Potential sources of endogeneity."
#
# Source order follows sigma.zip:sigma.do lines 9-262 (see brief). Reads ONLY
# the published data file.

source("stata_compat.R")

d <- read.csv(
  "C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\sigma\\sigma.csv",
  stringsAsFactors = FALSE
)

stopifnot(nrow(d) == 3186)

# --- do-file lines 25-38: basic derived variables --------------------------
# line 25: replace se=0.001 if se==0   (no rows in the published file have
# se==0, but the replacement is applied for fidelity to the author's code)
d$se <- ifelse(d$se == 0, 0.001, d$se)

# line 38: gen invsqrtnobs = 1/sqrt(nobs)
d$invsqrtnobs <- 1 / sqrt(d$nobs)

# line 54: gen stacoudata = stadata + coudata
d$stacoudata <- d$stadata + d$coudata

# --- do-file line 83: winsor2 sigma se invsqrtnobs, cuts(5 95) -------------
# winsor2 winsorizes each listed variable independently at its own 5th/95th
# percentile (Stata _pctile / quantile type 2).
d$sigma_win5      <- st_winsor2(d$sigma, cuts = c(5, 95))
d$se_win5         <- st_winsor2(d$se, cuts = c(5, 95))
d$invsqrtnobs_win5 <- st_winsor2(d$invsqrtnobs, cuts = c(5, 95))  # unused below, kept for fidelity

# --- do-file lines 240-252: SE-interaction terms ---------------------------
d$se_identif    <- d$se_win5 * d$identif
d$se_stacoudata <- d$se_win5 * d$stacoudata
d$se_ind_disagg <- d$se_win5 * d$ind_disagg
d$se_k_perpet   <- d$se_win5 * d$k_perpet
# translog: formula_code==6 | formula_code==7, built from the raw "formula"
# string variable (sigma.do lines 58-72). That variable is NOT among the
# published sigma.csv columns (verified against the brief's complete column
# list), so `translog` cannot be reconstructed from the site's published
# data. Left as NA; see REPLICATION.md.
d$translog   <- NA_real_
d$se_translog <- NA_real_
d$se_short   <- d$se_win5 * d$shortrun_expl

results <- list()

## NOTE on the "Constant" row of Table 5: Stata's xtreg, fe reports a model
## _cons that is the (weighted) grand mean of the estimated study fixed
## effects: cons = ybar - sum_j(beta_j * xbar_j), taken over ALL regressors
## in the model (SE plus the interaction terms together), where ybar/xbar
## are simple overall means. This is exactly the identity stata_compat.R's
## own st_xtreg_fe_cons wrapper implements for a single regressor (its
## "demean, add back the grand mean, refit" trick has intercept = ybar -
## beta*xbar by construction of OLS) -- it just has no multivariate form.
## Rather than calling feols()/lm() a second time (forbidden), the
## multivariate cons and its SE are obtained by plain linear algebra on the
## ALREADY-FITTED wrapper model `m`: cons = ybar - t(beta) %*% xbar, and
## since cons is a linear function of beta with xbar/ybar fixed given the
## data, Var(cons) = t(xbar) %*% vcov(beta) %*% xbar using m's own
## cluster-robust vcov. Verified against Table 5's "Identif." column before
## use: this reproduces 0.512 (0.0357) exactly (see check_cons.R).
xtreg_fe_cons <- function(m, data) {
  b <- stats::coef(m)
  V <- stats::vcov(m)
  xbar <- colMeans(data[, names(b), drop = FALSE])
  ybar <- mean(data$sigma_win5)
  cons <- ybar - sum(b * xbar)
  se_cons <- sqrt(as.numeric(t(xbar) %*% V %*% xbar))
  list(estimate = cons, std.error = se_cons)
}

run_col <- function(label, extra_terms) {
  fml <- stats::as.formula(
    paste("sigma_win5 ~ se_win5", if (length(extra_terms)) paste("+", paste(extra_terms, collapse = " + ")) else "")
  )
  m <- st_xtreg_fe(fml, data = d, panel = "idstudy")   # cluster defaults to panel = idstudy
  co <- st_coefs(m)
  se_row <- co[co$term == "se_win5", ]
  cons <- xtreg_fe_cons(m, d)
  list(m = m, se_coef = se_row$estimate, se_se = se_row$std.error, coefs = co,
       cons_coef = cons$estimate, cons_se = cons$std.error)
}

## Column: Identif.
r_identif <- run_col("Identif", "se_identif + identif")
results[["T5 Identif: SE coef"]]         <- r_identif$se_coef
results[["T5 Identif: SE se"]]           <- r_identif$se_se
results[["T5 Identif: Constant coef"]] <- r_identif$cons_coef
results[["T5 Identif: Constant se"]] <- r_identif$cons_se
row <- r_identif$coefs[r_identif$coefs$term == "se_identif", ]
results[["T5 Identif: SE*Identif coef"]] <- row$estimate
results[["T5 Identif: SE*Identif se"]]   <- row$std.error

## Column: Data aggr.
r_data <- run_col("Data aggr", "se_stacoudata + stacoudata")
results[["T5 Data aggr: SE coef"]]          <- r_data$se_coef
results[["T5 Data aggr: SE se"]]            <- r_data$se_se
results[["T5 Data aggr: Constant coef"]] <- r_data$cons_coef
results[["T5 Data aggr: Constant se"]] <- r_data$cons_se
row <- r_data$coefs[r_data$coefs$term == "se_stacoudata", ]
results[["T5 Data aggr: SE*Dataaggr coef"]] <- row$estimate
results[["T5 Data aggr: SE*Dataaggr se"]]   <- row$std.error

## Column: Results aggr.
r_res <- run_col("Results aggr", "se_ind_disagg + ind_disagg")
results[["T5 Results aggr: SE coef"]]              <- r_res$se_coef
results[["T5 Results aggr: SE se"]]                <- r_res$se_se
results[["T5 Results aggr: Constant coef"]] <- r_res$cons_coef
results[["T5 Results aggr: Constant se"]] <- r_res$cons_se
row <- r_res$coefs[r_res$coefs$term == "se_ind_disagg", ]
results[["T5 Results aggr: SE*Resultsaggr coef"]] <- row$estimate
results[["T5 Results aggr: SE*Resultsaggr se"]]   <- row$std.error

## Column: K: perpetual
r_kp <- run_col("K perpetual", "se_k_perpet + k_perpet")
results[["T5 K perpetual: SE coef"]]         <- r_kp$se_coef
results[["T5 K perpetual: SE se"]]           <- r_kp$se_se
results[["T5 K perpetual: Constant coef"]] <- r_kp$cons_coef
results[["T5 K perpetual: Constant se"]] <- r_kp$cons_se
row <- r_kp$coefs[r_kp$coefs$term == "se_k_perpet", ]
results[["T5 K perpetual: SE*Kperpet coef"]] <- row$estimate
results[["T5 K perpetual: SE*Kperpet se"]]   <- row$std.error

## Column: Short run
r_sr <- run_col("Short run", "se_short + shortrun_expl")
results[["T5 Short run: SE coef"]]          <- r_sr$se_coef
results[["T5 Short run: SE se"]]            <- r_sr$se_se
results[["T5 Short run: Constant coef"]] <- r_sr$cons_coef
results[["T5 Short run: Constant se"]] <- r_sr$cons_se
row <- r_sr$coefs[r_sr$coefs$term == "se_short", ]
results[["T5 Short run: SE*Shortrun coef"]] <- row$estimate
results[["T5 Short run: SE*Shortrun se"]]   <- row$std.error

## Column: Translog -- BLOCKED. formula_code (translog==1 if formula_code
## is 6 or 7) is built in sigma.do lines 58-72 from a raw "formula" string
## variable that is NOT among the published sigma.csv columns (verified
## against the brief's complete 115-column list). It cannot be
## reconstructed from anything the site publishes. Reported as NA rather
## than omitted, so the miss is visible against targets.json.
## (The paper's "All" column, which also needs se_translog + translog, is
## excluded from this package for the same reason.)
results[["T5 Translog: SE coef"]]       <- NA_real_
results[["T5 Translog: Constant coef"]] <- NA_real_

## N and study count (common to all columns; the published sample is not
## subsetted for these regressions)
results[["T5 Studies (all columns)"]]      <- length(unique(d$idstudy))
results[["T5 Observations (all columns)"]] <- nrow(d)

# --- print every produced number, then write results.json ------------------
for (nm in names(results)) {
  cat(sprintf("%-45s %s\n", nm, format(results[[nm]], digits = 8)))
}

out_dir <- "C:\\Users\\thavr\\AppData\\Local\\Temp\\claude\\C--Users-thavr-Dropbox-Study-Other-Agents-Joint-web-meta\\9ad3402b-4800-46ed-898e-3beabcc032d0\\scratchpad\\repl\\packages\\sigma"
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  # minimal fallback if jsonlite is unavailable
  con <- file(file.path(out_dir, "results.json"), "w")
  cat("{\n", file = con)
  nms <- names(results)
  for (i in seq_along(nms)) {
    v <- results[[nms[i]]]
    vstr <- if (is.na(v)) "null" else format(v, digits = 15, scientific = FALSE)
    cat(sprintf('  "%s": %s%s\n', nms[i], vstr, if (i < length(nms)) "," else ""), file = con)
  }
  cat("}\n", file = con)
  close(con)
} else {
  writeLines(jsonlite::toJSON(results, auto_unbox = TRUE, digits = NA, na = "null"),
             file.path(out_dir, "results.json"))
}

cat("\n")
stata_compat_log()
