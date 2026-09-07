# run.R -- replicate Table 7 (frequentist / OLS check), "Cross-Country Heterogeneity in
# Intertemporal Substitution", J. Int. Econ. 2015.
#
# Source table cell: Table 7, "Frequentist check (OLS)" columns (Coef., Std. er., p-value),
# for the alternative-proxies specification (financial reform instead of credit availability,
# trust instead of rule of law). This is the OLS half of eis_det.do's BMA-robustness block; the
# author's Stata command (eis_det.do, line 191) is:
#
#   reg eis marketpartic gdppc finref realrate trust inverse top totalc lnyears ols irstock
#       stockhold lnyearcits ircap sepdur if abs(eis)<10, vce(cluster idcountry)
#
# built on variables generated earlier in the same do-file (lines 68-80):
#   lnyears    = ln(years)
#   lnyearcits = ln(yearcits + 1)
#   gdppc      = ln(gdppc)          <- overwritten in place, so every later use of gdppc is logged
# and the sample restriction at line 100:
#   drop if abs(eis) >= 10
#
# Only the sample filter, variable construction, and cluster variable come from the do-file;
# the estimator is plain OLS with clustered SEs via st_regress(), exactly as written there.

source("stata_compat.R")

data_path <- "C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\substitution\\substitution.csv"
d <- read.csv(data_path, stringsAsFactors = FALSE)

# ---- variable construction (eis_det.do lines 68-80) ----
d$lnyears    <- log(d$years)
d$lnyearcits <- log(d$yearcits + 1)
d$gdppc      <- log(d$gdppc)     # do-file overwrites gdppc with its log in place

# ---- sample restriction (eis_det.do line 100, re-applied at line 191 as "if abs(eis)<10") ----
d <- st_drop_if(d, abs(d$eis) >= 10)

# ---- Table 7 frequentist (OLS) check (eis_det.do line 191) ----
m <- st_regress(
  eis ~ marketpartic + gdppc + finref + realrate + trust + inverse + top + totalc +
        lnyears + ols + irstock + stockhold + lnyearcits + ircap + sepdur,
  data = d, cluster = ~idcountry
)

# st_coefs() only ever reports z-based p-values (p.value = NA when z = FALSE); Stata's
# `regress` prints t-based p-values with df = G-1 (clusters), which is exactly what
# fixest's own summary() computes for this model (the vcov/ssc convention is already fixed
# by st_regress() above) -- so the coefficient table is read from summary(), not recomputed.
ct <- as.data.frame(summary(m)$coeftable)
ct$term <- rownames(ct)
names(ct)[names(ct) == "Estimate"]   <- "estimate"
names(ct)[names(ct) == "Std. Error"] <- "std.error"
names(ct)[names(ct) == "Pr(>|t|)"]   <- "p.value"
co <- ct

get_row <- function(term) co[co$term == term, ]

results <- list()
add <- function(label, value) results[[label]] <<- unname(value)

map <- list(
  marketpartic = "T7_marketpartic",
  gdppc        = "T7_gdppc",
  finref       = "T7_finref",
  realrate     = "T7_realrate",
  trust        = "T7_trust",
  inverse      = "T7_inverse",
  top          = "T7_top",
  totalc       = "T7_totalc",
  lnyears      = "T7_lnyears",
  ols          = "T7_ols",
  irstock      = "T7_irstock",
  stockhold    = "T7_stockhold",
  lnyearcits   = "T7_lnyearcits",
  ircap        = "T7_ircap",
  sepdur       = "T7_sepdur",
  "(Intercept)" = "T7_constant"
)

for (term in names(map)) {
  r <- get_row(term)
  lab <- map[[term]]
  add(paste0(lab, "_coef"), r$estimate)
  add(paste0(lab, "_se"),   r$std.error)
  add(paste0(lab, "_p"),    r$p.value)
}

add("T7_N", stats::nobs(m))

cat("---- results ----\n")
for (nm in names(results)) {
  cat(sprintf("%-22s %s\n", nm, format(results[[nm]], digits = 6)))
}

jsonlite_ok <- requireNamespace("jsonlite", quietly = TRUE)
if (jsonlite_ok) {
  jsonlite::write_json(results, "results.json", auto_unbox = TRUE, digits = 10)
} else {
  # minimal hand-rolled JSON writer (no external dependency required)
  esc <- function(x) x
  lines <- sprintf('  "%s": %s', names(results),
                    vapply(results, function(v) format(v, digits = 10, scientific = FALSE), character(1)))
  writeLines(c("{", paste(lines, collapse = ",\n"), "}"), "results.json")
}

cat("\nWrote results.json\n")
stata_compat_log()
