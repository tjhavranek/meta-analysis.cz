############################################################################################
#  Applied Meta-Analysis in Economics: R Script for RTMA and BMA
#  -------------------------------------------------------------
#  Example: "Beauty and Professional Success" (Bortnikova, Havranek, Bartos, Irsova, Luskova)
#
#  Version:       2.1 (Course Edition)
#  Author:        Tomas Havranek
#  Institution:   Charles University | CEPR | METRICS @ Stanford
#  Date:          March 6, 2026
#  License:       MIT License (https://opensource.org/licenses/MIT)
#
# ------------------------------------------------------------------------------------------
#  Purpose:
#  This R script implements two advanced tools for meta-analysis:
#
#   • Right-Truncated Meta-Analysis (RTMA): to correct for p-hacking (Mathur, 2024).
#   • Bayesian Model Averaging (BMA): to explore model uncertainty.
#
#  Both tools are demonstrated on data from a meta-analysis of the beauty premium in labor
#  markets. This script complements the Stata materials used in the University of Osaka workshop.
#
# ------------------------------------------------------------------------------------------
#  Requirements (must be installed before the course begins):
#
#  Software:
#     • R version 4.5.0 or newer
#
#  Core packages:
#     install.packages("BMS")
#     install.packages("phacking")
#
#  Dependencies for 'phacking':
#     install.packages(c(
#       "rstan", "StanHeaders", "rstantools", "truncnorm",
#       "metafor", "metabias",
#       "Rcpp", "RcppParallel", "RcppEigen",
#       "dplyr", "ggplot2", "rlang", "purrr", "Rdpack"
#     ))
#
#  Data file:
#     • Place the file "beauty_bma.csv" in your working directory before running this script.
#       Use getwd() to check or setwd() to change your working directory in R.
#
############################################################################################


############################################################################################
# SECTION 1: Load Required Packages and Dataset
############################################################################################

library(phacking)
library(BMS)

# Load the dataset (semicolon-separated CSV with dot as decimal separator)
databeauty <- read.csv("beauty_bma.csv",
                       sep = ";", dec = ".",
                       header = TRUE, stringsAsFactors = FALSE)

# Inspect structure of the dataset
str(databeauty)

############################################################################################
# SECTION 2: Right-Truncated Meta-Analysis (RTMA)
# ------------------------------------------------------------------------------------------
# Corrects for p-hacking using only nonaffirmative (insignificant) estimates.
# Based on the assumption that only significant results are selectively reported, while
# insignificant ones reflect the true distribution of effects (Mathur, 2024).
############################################################################################

# Define key variables
yi  <- databeauty$premium_w                 # Effect sizes
vi  <- databeauty$se_premium_w^2            # Variances
sei <- sqrt(vi)                             # Standard errors

# Visualize the Z-score distribution (to motivate RTMA)
plot.new()
z_density(yi, vi, sei = sei,
          alpha_select = 0.05, crit_color = "red")

# Count number of nonaffirmative (insignificant) estimates
z_scores       <- yi / sei
nonaffirmative <- abs(z_scores) < 1.96
num_insig      <- sum(nonaffirmative)
total          <- length(z_scores)
prop_insig     <- round(100 * num_insig / total, 1)
cat(sprintf("Number of nonaffirmative (insignificant) estimates: %d out of %d (%.1f%%)\n",
            num_insig, total, prop_insig))

# Run RTMA using 'phacking_meta()'
rtma_fit <- phacking_meta(
  yi             = yi,
  vi             = vi,
  favor_positive = TRUE,                   # Assume selection favors positive results
  alpha_select   = 0.05,                   # Significance threshold
  ci_level       = 0.95,                   # 95% credible interval
  stan_control   = list(adapt_delta = 0.98, max_treedepth = 20),
  parallelize    = TRUE
)

# View summary of posterior estimates
summary(rtma_fit)


############################################################################################
# SECTION 3: Bayesian Model Averaging (BMA) under Two Prior Settings
############################################################################################

set.seed(20260316)

# Dilution prior + Unit Information Prior (UIP) for g
beauty1 <- bms(databeauty,
               burn = 1e4, iter = 3e4,
               g = "UIP", mprior = "dilut",
               nmodel = 50000, mcmc = "bd", user.int = FALSE)

# Random model prior + BRIC prior for g
beauty2 <- bms(databeauty,
               burn = 1e4, iter = 3e4,
               g = "BRIC", mprior = "random",
               nmodel = 50000, mcmc = "bd", user.int = FALSE)


############################################################################################
# SECTION 4: Summarize and Visualize BMA Results
############################################################################################

# Posterior inclusion probabilities and coefficients
coef(beauty1, order.by.pip = TRUE, exact = TRUE, include.constant = TRUE)
coef(beauty2, order.by.pip = TRUE, exact = TRUE, include.constant = TRUE)

# Posterior summaries
summary(beauty1)
summary(beauty2)

# Visualize inclusion probabilities and effect estimates
image(beauty1, yprop2pip = FALSE, order.by.pip = TRUE,
      do.par = TRUE, do.grid = TRUE, do.axis = TRUE, cex.axis = 0.7)

image(beauty2, yprop2pip = FALSE, order.by.pip = TRUE,
      do.par = TRUE, do.grid = TRUE, do.axis = TRUE, cex.axis = 0.7)

# Densities for key variables
density(beauty1, reg = "se_premium_w")
density(beauty1, reg = "cognitive_skill_control")
density(beauty1, reg = "prostitutes")
density(beauty1, reg = "salary")

# Diagnostic trace and density plots
plot(beauty1)
plot(beauty2)
