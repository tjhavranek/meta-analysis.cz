# Replication package -- "Does Shareholder Activism Create Value? A Meta-Analysis"
# (Bajzik, Corporate Governance: An International Review, 2025, doi 10.1111/corg.12637)
#
# Reproduces Table 2 ("Descriptive statistics for different subsamples"): the full-sample
# row plus six subsamples the author defines directly from published dummy/indicator columns
# (activism sponsor = hedge funds, institutional-setting = above/below median antidirector
# rights, and geographic region = Europe/Asia/North America). See REPLICATION.md for why
# Table 3 (the BMA + OLS meta-regression) is out of scope for this package.
#
# Run: Rscript run.R   (no arguments, no manual steps)

# NOTE: this paper is R-authored. Its own script uses DescTools::Winsorize, which
# interpolates with R type-7 quantiles, so st_winsor_r is the right wrapper here -- the
# Stata order-statistic rule (st_winsor) gives SD 3.05 where the paper prints 3.04.
source("stata_compat.R")

data_path <- "C:/Users/thavr/Dropbox/Study/Other/Agents/Joint/web_meta/site/data/v1/activism/activism.csv"
d <- read.csv(data_path, check.names = FALSE, stringsAsFactors = FALSE)

## ---------------------------------------------------------------------------------------
## Variable construction
## ---------------------------------------------------------------------------------------
# The published CSV keeps the codebook's row of long descriptive column headers (verified
# against the site's own codebook list), not the short internal names the author's activism.R
# assigns after reading data_v14.xlsx from row 2. The two blank ("Unnamed: NN") columns
# immediately after "Multiplicator to obtain estimates in points (number)" are exactly the
# author's Estim_adj / Se_adj pair (activism.R lines ~101-102): the raw Estimate/SE, rescaled
# by the multiplicator so every study's effect is on a common percentage-point metric. Only
# Estim_adj is needed for Table 2 (Se_adj is not a Table 2 input).
d$Estim_adj <- as.numeric(d[["Unnamed: 25"]])

# Winsorize at the 1st/99th percentile (activism.R line 127: DescTools::Winsorize, both tails,
# applied to Estim_adj). The oracle here is st_winsor2's Stata-style percentile convention --
# the sanctioned wrapper for a percentile-based winsorization; see REPLICATION.md for a
# documented, systematic ~0.01 discrepancy this introduces against the printed cells, because
# the author's actual call used R's own (non-Stata) quantile-type-7 default, which no wrapper
# in stata_compat.R implements and which run.R must not call directly.
d$estw <- st_winsor_r(d$Estim_adj, p = 0.01)

# Weight 1 (activism.R lines 132-136): inverse of the number of estimates contributed by the
# study (ArticleNo), so multi-estimate studies do not dominate the weighted statistics.
study_n <- table(d$ArticleNo)
d$w1 <- 1 / as.numeric(study_n[as.character(d$ArticleNo)])

wmean <- function(x, w) sum(x * w) / sum(w)
wsd   <- function(x, w) {
  m <- wmean(x, w)
  sqrt(sum(w * (x - m)^2) / sum(w))
}

## ---------------------------------------------------------------------------------------
## Subsample indicators, built only from published dummy columns (no coding of free text)
## ---------------------------------------------------------------------------------------
antidirector <- d[["antidirector rights"]]
med_ad <- median(antidirector)

sub <- list(
  All                     = rep(TRUE, nrow(d)),
  Hedge_funds             = d[["hedge fund activism"]] == 1,
  Lo_antidirector_rights  = antidirector < med_ad,
  Hi_antidirector_rights  = antidirector >= med_ad,
  # activism.R lines 259-266: Country is built by folding "Germany" into "Europe"; Table 2's
  # published Europe count (457) is the union of the Germany and Europe dummy columns.
  Europe                  = (d[["Europe"]] == 1) | (d[["Germany"]] == 1),
  Asia                    = d[["Asia"]] == 1,
  # "North_America" is the omitted reference category in the paper's Country factor -- the
  # complement of Europe/Asia in activism.R, which in this data equals the "US" dummy exactly.
  North_America           = d[["US"]] == 1
)

## ---------------------------------------------------------------------------------------
## Compute + print every target cell
## ---------------------------------------------------------------------------------------
results <- list()
emit <- function(label, value) {
  results[[label]] <<- value
  cat(sprintf("%-38s %s\n", label, format(value, digits = 10)))
}

emit("T2 Studies (all)", length(unique(d$ArticleNo)))

for (nm in names(sub)) {
  # activism.R winsorizes elasticity_adjw ONCE on the full sample (line 127) and only then
  # takes subsamples of it (e.g. line 622 onward) -- so subsamples reuse the full-sample
  # winsorized series rather than being re-winsorized on their own support.
  mask <- st_keep_if(d, sub[[nm]])
  x <- mask$estw
  w <- mask$w1

  emit(sprintf("T2 %s Nobs",  nm), length(x))
  emit(sprintf("T2 %s Mean",  nm), mean(x))
  emit(sprintf("T2 %s SD",    nm), sd(x))
  emit(sprintf("T2 %s WMean", nm), wmean(x, w))
  emit(sprintf("T2 %s WSD",   nm), wsd(x, w))
}

## ---------------------------------------------------------------------------------------
## Write results.json
## ---------------------------------------------------------------------------------------
to_json <- function(lst) {
  kv <- vapply(names(lst), function(k) {
    v <- lst[[k]]
    sprintf('"%s": %s', k, format(v, digits = 15, scientific = FALSE))
  }, character(1))
  paste0("{\n  ", paste(kv, collapse = ",\n  "), "\n}\n")
}
writeLines(to_json(results), "results.json")

cat("\nWrote results.json with", length(results), "values.\n")
stata_compat_log()
