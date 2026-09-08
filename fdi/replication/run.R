# Replication package: "Foreign Capital and Domestic Productivity in the Czech
# Republic: A Meta-Regression Analysis" (Applied Economics, 2020)
# Reproduces Table 2 ("Factors influencing the reported spillover estimates"):
# General model and Specific model.
#
# Both models are OLS of the winsorised spillover estimate on the study-design
# moderators, with standard errors clustered at the level of the primary study
# ("note that in all models we cluster the standard errors at the level of
# individual studies, because we suspect that estimates reported within
# individual studies are not independent", Section IV).

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/fdi/replication/stata_compat.R")

d <- read.csv((if (file.exists("fdi.csv")) "fdi.csv" else
     "https://meta-analysis.cz/data/v1/fdi/fdi.csv"))

# ---------------------------------------------------------------- study identifier
# The published file carries no explicit study ID, but the clustering is not
# optional: it is the whole variance convention of Table 2. The ID has to be
# rebuilt from the published columns, and doing it naively is wrong in a way
# that is invisible in the point estimates and visible in every standard error.
#
# Three columns are study-level constructs: Impact_factor (impact factor of the
# outlet), Citations (citations per year of the study) and Pub_year. The rows
# are in study order, so runs of a constant (Impact_factor, Citations,
# Pub_year) triple look like the study blocks -- and grouping on them gives 8
# blocks, which is the right NUMBER of studies. But the blocks are in the wrong
# PLACE: they are each shifted one row early, because in the source data the
# three quality columns lag the rest of the record by one observation, so the
# last estimate of every study carries the following study's quality values.
#
# That shift is detectable from the published file alone. Three moderators --
# Competition, Assets and Real_linkages -- are constant within a primary study
# and change between them, so a change in any of them must be a study boundary.
# Those changes sit at rows 13, 105, 164 and 180 (1-based). The quality-triple
# changes sit at 12, 104, 163 and 179: one row earlier, at all four, in the same
# direction. So the study block starts one row AFTER the quality triple changes,
# i.e. the study ID is the run index of the LAGGED quality triple. The check
# below is the actual test -- it fails on the naive grouping and passes on this
# one -- and the resulting partition has 8 contiguous blocks of 12, 92, 48, 3,
# 8, 16, 69 and 84 estimates.
#
# This affects no point estimate. It moves every standard error in Table 2.

qual <- d[, c("Impact_factor", "Citations", "Pub_year")]
qual_change <- c(TRUE, rowSums(qual[-1, ] != qual[-nrow(qual), ]) > 0)
qual_block  <- cumsum(qual_change)
d$study     <- c(qual_block[1], qual_block[-length(qual_block)])   # lag one row

# validation, from published columns only: every change in a moderator that is
# constant within a study must coincide with a study boundary.
const_vars   <- d[, c("Competition", "Assets", "Real_linkages")]
const_change <- which(rowSums(const_vars[-1, ] != const_vars[-nrow(const_vars), ]) > 0) + 1
study_start  <- which(c(TRUE, d$study[-1] != d$study[-length(d$study)]))
stopifnot(all(const_change %in% study_start))
stopifnot(length(unique(d$study)) == 8L)
stopifnot(!is.unsorted(d$study))                 # blocks are contiguous

cat(sprintf("Study clusters rebuilt: %d studies, sizes %s\n",
            length(unique(d$study)), paste(as.vector(table(d$study)), collapse = " ")))

results <- list()
add <- function(label, value) results[[label]] <<- unname(value)

# ---------------------------------------------------------------- General model
# `reg e_w forward horizontal lagged square diff lnobs avyear yearfe sectfe
#  competition fully joint services assets output pols random gmm realpart
#  impact yearcits pubyear, cluster(idstudy)`
fml_general <- e_w ~ Forward + Horizontal + Lagged + Quadratic + Differences +
  No_of_firms + Data_year + Year_FE + Sector_FE + Competition + Fully_owned +
  Joint_ventures + Services + Assets + Output + POLS + Random + GMM +
  Real_linkages + Impact_factor + Citations + Pub_year

m_general <- st_regress(fml_general, data = d, cluster = ~study)
tab_general <- st_coefs(m_general)
rownames(tab_general) <- tab_general$term

for (v in setdiff(tab_general$term, "(Intercept)")) {
  add(paste("T2 general", v, "coef"), tab_general[v, "estimate"])
  add(paste("T2 general", v, "se"),   tab_general[v, "std.error"])
}
add("T2 general Constant coef", tab_general["(Intercept)", "estimate"])
add("T2 general Constant se",   tab_general["(Intercept)", "std.error"])
add("T2 general N", nobs(m_general))

# ---------------------------------------------------------------- Specific model
# The paper reaches the specific model "by discarding variables that are jointly
# insignificant at the 5% level". The elimination path itself is not re-derived
# here; what is re-estimated is the model the paper reports as its outcome --
# `reg e_w gmm assets square random pols avyear yearfe realpart competition
#  joint output, cluster(idstudy)` -- on the same sample and the same clusters.
fml_specific <- e_w ~ Quadratic + Data_year + Year_FE + Competition +
  Joint_ventures + Assets + Output + POLS + Random + GMM + Real_linkages

m_specific <- st_regress(fml_specific, data = d, cluster = ~study)
tab_specific <- st_coefs(m_specific)
rownames(tab_specific) <- tab_specific$term

for (v in setdiff(tab_specific$term, "(Intercept)")) {
  add(paste("T2 specific", v, "coef"), tab_specific[v, "estimate"])
  add(paste("T2 specific", v, "se"),   tab_specific[v, "std.error"])
}
add("T2 specific Constant coef", tab_specific["(Intercept)", "estimate"])
add("T2 specific Constant se",   tab_specific["(Intercept)", "std.error"])
add("T2 specific N", nobs(m_specific))

# ---------------------------------------------------------------- report
cat("\n==== Produced values ====\n")
for (nm in names(results)) cat(sprintf("%-32s %s\n", nm, format(results[[nm]], digits = 8)))

stata_compat_log()

jsonlite_ok <- requireNamespace("jsonlite", quietly = TRUE)
if (jsonlite_ok) {
  jsonlite::write_json(results, "results.json", auto_unbox = TRUE, digits = 10)
} else {
  esc <- function(x) gsub('"', '\\\\"', x)
  lines <- sprintf('  "%s": %s', esc(names(results)),
                    sapply(results, function(v) format(v, digits = 10, scientific = FALSE)))
  writeLines(c("{", paste(lines, collapse = ",\n"), "}"), "results.json")
}
cat("\nWrote results.json\n")
