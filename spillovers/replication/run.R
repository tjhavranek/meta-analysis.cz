# run.R -- Table 1 of Havranek & Irsova, "Estimating Vertical Spillovers from FDI:
# Why Results Vary and What the True Effect Is", Journal of International Economics
# 85(2), 2011, pp. 234-244.
#
# Table 1 is the publication-bias test and the bias-corrected spillover effect, in three
# panels (A backward, B forward, C horizontal) and, here, two columns each:
#
#     t_ij = beta0 + e0 * (1/Se(e_ij)) + zeta_j + eps_ij
#
# fitted as a two-level mixed model with a study-level random intercept. The third column
# of the paper ("Homogeneous estimates") is not in targets.json and is not attempted here.
#
# Everything below follows the authors' own do-file, which the site publishes as
# Stata_program.do, line for line:
#
#     drop if aux==1
#     gen back = ((horiz==0 & forw==0) | (horiz==0 & local==1))
#     gen prec = 1/se
#     hadimvo e prec if back==1,  gen(oddb) p(.001)
#     hadimvo e prec if forw==1,  gen(oddf) p(.001)
#     hadimvo e prec if horiz==1, gen(oddh) p(.001)
#     gen odd = (oddb==1 | oddf==1 | oddh==1)
#     eststo: xtmixed t prec || idstudy: if back==1 & odd==0
#     eststo: xtmixed t prec || idstudy: if back==1 & odd==0 & pub==1
#     ... and the same pair for forw==1 and for horiz==1
#
# Two things decide whether this reproduces, and both were got wrong before:
#
#   1. THE SAMPLE. The regressions run on odd==0, where `odd` is the union of three
#      SEPARATE Hadi (1994) multivariate-outlier passes -- one per spillover type, each on
#      (e, prec), each at p = .001. Skipping that step leaves 1402/1067/1205 observations
#      instead of the paper's 1311/1030/1154 and moves every coefficient. hadimvo_stata()
#      is a line-by-line port of Stata's hadimvo.ado, checked against Stata on this data.
#
#   2. THE ESTIMATOR. `xtmixed` (Stata 11) defaults to RESTRICTED maximum likelihood.
#      `mixed` (Stata 13+) defaults to plain ML. The authors ran xtmixed, and the paper's
#      Table 1 note says restricted maximum likelihood, so this script calls st_xtmixed()
#      and not st_mixed(). Under ML the forward/published slope comes out 0.2528 against a
#      printed 0.258 -- close enough to be mistaken for rounding, and wrong.
#
# Reads only C:/.../site/data/v1/spillovers/spillovers.csv, which the site publishes.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/spillovers/replication/stata_compat.R")

data_path <- (if (file.exists("spillovers.csv")) "spillovers.csv" else
     "https://meta-analysis.cz/data/v1/spillovers/spillovers.csv")
d <- read.csv(data_path, stringsAsFactors = FALSE)

# drop if aux==1   (Stata_program.do)
d <- st_drop_if(d, d$aux == 1)

# gen back / gen prec   (Stata_program.do)
d$back <- as.integer((d$horiz == 0 & d$forw == 0) | (d$horiz == 0 & d$local == 1))
d$prec <- 1 / d$se

# hadimvo e prec if <subsample>, gen(...) p(.001), then odd = the union of the three flags.
# Stata leaves the generated flag MISSING outside the `if` sample, and `oddb==1` is false for
# a missing value, so the union below tests ==1 rather than !=0.
hadi_flag <- function(rows) {
  f <- rep(NA_integer_, nrow(d))
  i <- which(rows)
  f[i] <- hadimvo_stata(cbind(d$e[i], d$prec[i]), p = .001)$flag
  f
}
oddb <- hadi_flag(d$back  == 1)
oddf <- hadi_flag(d$forw  == 1)
oddh <- hadi_flag(d$horiz == 1)
d$odd <- as.integer(oddb %in% 1 | oddf %in% 1 | oddh %in% 1)

cat(sprintf("hadimvo outliers: backward %d, forward %d, horizontal %d; union %d\n",
            sum(oddb %in% 1), sum(oddf %in% 1), sum(oddh %in% 1), sum(d$odd == 1)))

# xtmixed t prec || idstudy: if <panel> & odd==0 [& pub==1]
fit_panel <- function(sub) {
  sub <- sub[!is.na(sub$t) & !is.na(sub$prec) & !is.na(sub$idstudy), ]
  m  <- st_xtmixed(t ~ prec + (1 | idstudy), data = sub)
  cf <- lme4::fixef(m)
  se <- sqrt(diag(as.matrix(vcov(m))))
  list(const_coef = unname(cf["(Intercept)"]),
       const_se   = unname(se["(Intercept)"]),
       prec_coef  = unname(cf["prec"]),
       prec_se    = unname(se["prec"]),
       n          = nrow(sub),
       studies    = length(unique(sub$idstudy)))
}

panels <- list(
  PanelA_All = d[d$back  == 1 & d$odd == 0, ],
  PanelA_Pub = d[d$back  == 1 & d$odd == 0 & d$pub == 1, ],
  PanelB_All = d[d$forw  == 1 & d$odd == 0, ],
  PanelB_Pub = d[d$forw  == 1 & d$odd == 0 & d$pub == 1, ],
  PanelC_All = d[d$horiz == 1 & d$odd == 0, ],
  PanelC_Pub = d[d$horiz == 1 & d$odd == 0 & d$pub == 1, ]
)

results <- list()
for (nm in names(panels)) {
  r <- fit_panel(panels[[nm]])
  results[[paste0(nm, "_Constant_coef")]]  <- r$const_coef
  results[[paste0(nm, "_Constant_se")]]    <- r$const_se
  results[[paste0(nm, "_Precision_coef")]] <- r$prec_coef
  results[[paste0(nm, "_Precision_se")]]   <- r$prec_se
  results[[paste0(nm, "_N")]]              <- r$n
  results[[paste0(nm, "_Studies")]]        <- r$studies
}

cat("\n=== Table 1 ===\n")
for (lbl in names(results)) cat(sprintf("%-30s %s\n", lbl, format(results[[lbl]], digits = 8)))

cat("\n")
stata_compat_log()

writeLines(jsonlite::toJSON(results, auto_unbox = TRUE, digits = 10), "results.json")
