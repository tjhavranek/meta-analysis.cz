# run.R -- replication of "How to Solve the Price Puzzle? A Meta-Analysis"
# (Havranek, Rusnak & Sokolova, JMCB 2013), Table A1: "Test of Publication Bias and
# True Effect, OLS" -- the FAT-PET meta-regression of the approximated t-statistic on
# precision (1/SE), OLS with standard errors clustered at the study level, one column
# per impulse-response horizon (3, 6, 12, 18, 36 months).
#
# Uses ONLY the wrappers in stata_compat.R. No feols/lm/rma/lmer/plm/ivreg/quantile call
# anywhere in this file.

source("stata_compat.R")

suppressMessages(library(jsonlite))
suppressMessages(library(fixest))

# ---------------------------------------------------------------------- data & construction
# The published price_puzzle.csv is the author's own wide file (one row per estimate),
# duplicated 7-fold across a "horizon" indicator (3, 6, 12, 18, 36, 88=bottom, 99=peak);
# the horizon-specific response/SE for a given row live in fixed-name columns M{h}R / SE{h}
# (M3R/SE3, M6R/SE6, M12R/SE12, M18R/SE18, M36R/SE36) that do not vary across the duplicate
# rows for the same idstudy/idest. puzzle.do lines 13-14 (`replace res=100*res` /
# `replace se=100*se`) show the author working in percentage-point units on generic `res`/
# `se` variables built (upstream of the excerpted do-file) from exactly this per-horizon
# selection; puzzle.do line 35ff regresses `t` (the approximated t-statistic, i.e. res/se)
# on `prec` (1/se) separately `if horizon==3/6/12/18/36`.
d <- read.csv(
  "C:\\Users\\thavr\\Dropbox\\Study\\Other\\Agents\\Joint\\web_meta\\site\\data\\v1\\price_puzzle\\price_puzzle.csv",
  stringsAsFactors = FALSE, check.names = FALSE
)

horizons <- list(
  list(h = 3,  Rcol = "M3R",  Scol = "SE3"),
  list(h = 6,  Rcol = "M6R",  Scol = "SE6"),
  list(h = 12, Rcol = "M12R", Scol = "SE12"),
  list(h = 18, Rcol = "M18R", Scol = "SE18"),
  list(h = 36, Rcol = "M36R", Scol = "SE36")
)

results <- list()
add <- function(label, value) results[[label]] <<- as.numeric(value)

for (spec in horizons) {
  h <- spec$h; Rcol <- spec$Rcol; Scol <- spec$Scol

  # puzzle.do line 7 (use puzzle.dta) + the horizon selection implicit in `if horizon==h`:
  # take the one row per estimate carrying this horizon's response/SE.
  sub <- st_keep_if(d, d$horizon == h)

  # puzzle.do lines 13-14: res/se are in percentage-point units.
  res <- sub[[Rcol]] * 100
  se  <- sub[[Scol]] * 100

  # Drop estimates with no reported response/SE at this horizon (Stata's `reg ... if
  # horizon==h` silently drops rows with missing res/se the same way).
  ok <- !is.na(res) & !is.na(se)
  sub <- sub[ok, , drop = FALSE]
  t    <- (res / se)[ok]
  prec <- (1 / se)[ok]

  reg_d <- data.frame(t = t, prec = prec, idstudy = sub$idstudy)

  # puzzle.do: eststo: reg t prec if horizon==h, vce(cluster idstudy)
  m <- st_regress(t ~ prec, data = reg_d, cluster = ~idstudy)
  co <- st_coefs(m)

  lab <- paste0("H", h, ": ")
  add(paste0(lab, "Intercept (bias) coef"), co$estimate[co$term == "(Intercept)"])
  add(paste0(lab, "Intercept (bias) se"),   co$std.error[co$term == "(Intercept)"])
  add(paste0(lab, "1/SE (effect) coef"),    co$estimate[co$term == "prec"])
  add(paste0(lab, "1/SE (effect) se"),      co$std.error[co$term == "prec"])
  add(paste0(lab, "R2"),                    fixest::r2(m, "r2"))
  add(paste0(lab, "Observations"),          nrow(reg_d))
  add(paste0(lab, "Studies"),               length(unique(reg_d$idstudy)))
}

# ------------------------------------------------------------------------------- reporting
cat("\n===== Produced numbers =====\n")
for (nm in names(results)) cat(sprintf("%-35s %s\n", nm, format(results[[nm]], digits = 8)))

write(toJSON(results, auto_unbox = TRUE, digits = 10), file = "results.json")
cat("\nWrote results.json\n")

stata_compat_log()
