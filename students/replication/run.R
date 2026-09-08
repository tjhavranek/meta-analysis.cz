# run.R -- replication of "The Impact of Student Employment on Educational Outcomes:
# A Meta-Analysis" (Economics of Education Review, 2024), Table 2 ("Tests suggest small
# publication bias overall"), Panels A, B (FE only) and the WAAP row of Panel C.
#
# Provenance: author's own students.do (published at
# web_meta/site/students/students.do), section "PUBLICATION BIAS - testing larger sample"
# (first pass, "FULL SAMPLE on 876 obs" comment -- the comment is stale, the actual N is 861
# once the idstudy>69 / missing(pcc) / missing(se_pcc) filters are applied to the published
# data, which matches every N cell printed in Table 2).
#
# Not attempted, and excluded from targets.json:
#  - Panel B, BE and RE columns: `xtreg ..., be` and `xtreg ..., re` have no wrapper in
#    stata_compat.R (only `xtreg ..., fe` does, via st_xtreg_fe/st_xtreg_fe_cons). Per the
#    package rules this is a stop, not an invitation to hand-roll a between/random-effects
#    estimator with a different R construction.
#  - Panel C, Stem method / Kinked model / Selection model / p-uniform*: the do-file itself
#    hands these off to external tools with no Stata-command analogue here -- the Stem method
#    to a separate R script (Furukawa 2019, stem_method.R), the Kinked model to the
#    user-written Stata command `kink` (Bom & Rachinger 2020), and p-uniform* to the R
#    package `puniform`'s `puni_star()`. None of these is `feols`/`lm`/`rma`/`lmer` wrapped by
#    stata_compat.R, so none is attempted.
#  - The WAAP row of Panel C *is* attempted: the do-file builds it with plain `reg` (Stata
#    regress), which st_regress covers.
#
# One cell of Table 2 is not reproduced, and the evidence says the paper is wrong rather than
# this code: the WAAP standard error, printed as (0.0130). This script produces 0.0135726. So
# does Stata 15.1 run on the author's own students.xlsx with the author's own commands, and so
# does the author's own log of the published run
# (Tomas_Zuzka_sdilene\2_papers\paper_students\_revision\calculation\calculation_final_version\
# students.log): "precision_w | .0075581 | .0135726 | 0.56 | 0.616". The paper itself prints
# the correct value for the same regression in its appendix table on the expanded 872-estimate
# sample -- 0.00756 (0.0136), students.pdf p. 48 -- where the WAAP coefficient is identical
# because the adequately powered subset is the same four estimates. 0.0130 is also, to the
# digit, the Selection-model coefficient printed one column to the right in the same row of
# Table 2. See REPLICATION.md.

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/students/replication/stata_compat.R")
suppressMessages(library(jsonlite))

d <- read.csv(
  (if (file.exists("students.csv")) "students.csv" else
     "https://meta-analysis.cz/data/v1/students/students.csv"),
  stringsAsFactors = FALSE
)

## ---- sample construction (students.do lines 14-28) ------------------------------------
d <- st_drop_if(d, d$idstudy > 69)
d <- st_drop_if(d, is.na(d$pcc))
d <- st_drop_if(d, is.na(d$se_pcc))

d$pcc_w              <- st_winsor(d$pcc, p = 0.01)
d$se_pcc_w           <- st_winsor(d$se_pcc, p = 0.01)
d$sample_size_full_w <- st_winsor(d$sample_size_full, p = 0.01)

d$precision_w <- 1 / d$se_pcc_w
d$nobs        <- sqrt(d$sample_size_full_w)
d$inv_nobs    <- 1 / d$nobs

cat(sprintf("N after sample filters: %d\n", nrow(d)))

results <- list()

## ================================================================================
## Panel A: Linear techniques (students.do lines 49-60)
## ================================================================================

## -- OLS: ivreg2 pcc_w se_pcc_w, cluster(idstudy)
m_ols <- st_ivreg2(pcc_w ~ se_pcc_w, data = d, cluster = ~idstudy)
co <- st_coefs(m_ols)
results$T2_PanelA_OLS_coef     <- co$estimate[co$term == "se_pcc_w"]
results$T2_PanelA_OLS_se       <- co$std.error[co$term == "se_pcc_w"]
results$T2_PanelA_OLS_const    <- co$estimate[co$term == "(Intercept)"]
results$T2_PanelA_OLS_const_se <- co$std.error[co$term == "(Intercept)"]
results$T2_PanelA_OLS_N        <- m_ols$nobs

## -- IV: ivreg2 pcc (se_pcc_w = inv_nobs), cluster(idstudy)
m_iv <- st_ivreg2(pcc ~ 1 | se_pcc_w ~ inv_nobs, data = d, cluster = ~idstudy)
co <- st_coefs(m_iv)
print(co)
results$T2_PanelA_IV_coef     <- co$estimate[grepl("se_pcc_w", co$term)]
results$T2_PanelA_IV_se       <- co$std.error[grepl("se_pcc_w", co$term)]
results$T2_PanelA_IV_const    <- co$estimate[co$term == "(Intercept)"]
results$T2_PanelA_IV_const_se <- co$std.error[co$term == "(Intercept)"]
results$T2_PanelA_IV_N        <- m_iv$nobs

## -- Study: ivreg2 pcc_w se_pcc_w [pweight=inv_nobs], cluster(idstudy)
m_study <- st_ivreg2(pcc_w ~ se_pcc_w, data = d, cluster = ~idstudy, weights = ~inv_nobs)
co <- st_coefs(m_study)
results$T2_PanelA_Study_coef     <- co$estimate[co$term == "se_pcc_w"]
results$T2_PanelA_Study_se       <- co$std.error[co$term == "se_pcc_w"]
results$T2_PanelA_Study_const    <- co$estimate[co$term == "(Intercept)"]
results$T2_PanelA_Study_const_se <- co$std.error[co$term == "(Intercept)"]
results$T2_PanelA_Study_N        <- m_study$nobs

## -- Precision: ivreg2 pcc_w se_pcc_w [pweight=precision_w], cluster(idstudy)
m_prec <- st_ivreg2(pcc_w ~ se_pcc_w, data = d, cluster = ~idstudy, weights = ~precision_w)
co <- st_coefs(m_prec)
results$T2_PanelA_Precision_coef     <- co$estimate[co$term == "se_pcc_w"]
results$T2_PanelA_Precision_se       <- co$std.error[co$term == "se_pcc_w"]
results$T2_PanelA_Precision_const    <- co$estimate[co$term == "(Intercept)"]
results$T2_PanelA_Precision_const_se <- co$std.error[co$term == "(Intercept)"]
results$T2_PanelA_Precision_N        <- m_prec$nobs

## ================================================================================
## Panel B: Between- and within-study variation -- FE only (students.do line 65)
## BE and RE have no wrapper in stata_compat.R and are not attempted (see header note).
## ================================================================================

m_fe <- st_xtreg_fe(pcc_w ~ se_pcc_w, data = d, panel = "idstudy", cluster = ~idstudy)
co <- st_coefs(m_fe)
results$T2_PanelB_FE_coef <- co$estimate[co$term == "se_pcc_w"]
results$T2_PanelB_FE_se   <- co$std.error[co$term == "se_pcc_w"]
results$T2_PanelB_FE_N    <- m_fe$nobs

m_fe_cons <- st_xtreg_fe_cons(y = "pcc_w", x = "se_pcc_w", panel = "idstudy", data = d,
                               cluster = ~idstudy)
co <- st_coefs(m_fe_cons)
results$T2_PanelB_FE_const    <- co$estimate[co$term == "(Intercept)"]
results$T2_PanelB_FE_const_se <- co$std.error[co$term == "(Intercept)"]

## ================================================================================
## Panel C, WAAP row only (students.do lines 68-76)
##   summarize precision_w, detail        -> top10bound (not used for WAAP itself)
##   summarize pcc_w [aweight=precision_w*precision_w]   -> r(mean)
##   gen waapbound = abs(r(mean))/2.8
##   reg tstat precision_w if se_pcc < waapbound, noconstant
## Stem/Kinked/Selection/p-uniform* are not attempted (see header note).
## ================================================================================

w_mean    <- stats::weighted.mean(d$pcc_w, w = d$precision_w^2)
waapbound <- abs(w_mean) / 2.8
d_waap    <- st_keep_if(d, d$se_pcc < waapbound)
cat(sprintf("WAAP: weighted mean pcc_w = %.6f, bound = %.6f, adequately powered subset = %d obs\n",
            w_mean, waapbound, nrow(d_waap)))

m_waap <- st_regress(tstat ~ precision_w - 1, data = d_waap)
co <- st_coefs(m_waap, z = FALSE)
results$T2_PanelC_WAAP_coef <- co$estimate[co$term == "precision_w"]
results$T2_PanelC_WAAP_se   <- co$std.error[co$term == "precision_w"]

## The "Observations" cell of Panel C is the size of the sample the five nonlinear techniques are
## APPLIED TO, not the estimation N of any one of them. The paper prints 861 under all five
## columns (WAAP, stem method, kinked model, selection model, p-uniform*), and the table note
## says the whole sample is "861 estimates". WAAP consumes all 861 -- its power bound is the
## precision-squared-weighted mean of pcc_w over the whole sample -- and then averages only the
## adequately powered subset, which here is 4 estimates, all from idstudy 19. That 4 is printed
## above as a diagnostic; it is not what the Observations row reports, and it appears nowhere in
## the paper. Hence nrow(d), the analysis sample the do-file's three drops leave behind.
results$T2_PanelC_WAAP_N    <- nrow(d)

## ---- print + write ----------------------------------------------------------------
for (nm in names(results)) cat(sprintf("%-28s = %s\n", nm, format(results[[nm]], digits = 8)))

results_num <- lapply(results, function(x) as.numeric(x))
writeLines(jsonlite::toJSON(results_num, auto_unbox = TRUE, digits = 10), "results.json")

stata_compat_log()
