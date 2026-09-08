# run.R -- replication package for meta-analysis.cz "excess_sensitivity"
#
# Paper: "Do Consumers Really Follow a Rule of Thumb? Three Thousand Estimates
#         from 144 Studies Say 'Probably Not'", Review of Economic Dynamics 2020.
#
# Target: Table 2. "Excess sensitivity explained by macro data, publication
# bias, and liquidity constraints." Five columns (Bias only / Baseline / Bias
# ignored / Precision / Study), all on the FULL 3,127-observation, 144-study
# sample (unlike Table 1, which splits into micro/macro and needs xtreg,fe/be
# -- Table 2 needs only pooled OLS/WLS with two-way clustering, all covered
# by st_ivreg2()).
#
# Author code provenance (data_code.zip:excess.do, lines as marked in the brief):
#   line 14  gen prec = 1/se
#   line 32  replace LC_not_bind = 0 if switch==1
#   line 38  gen invperstudy = 1/perstudy   (perstudy = # of estimates per idstudy;
#                                             not itself a marked line, but pinned
#                                             by the Table-1/2 note: "Study = the
#                                             inverse of the number of estimates
#                                             reported per study is used as the weight")
#   line 42  gen microse = micro*se
#   line 194 eststo: ivreg2 excess micro microse, cluster(idstudy countryyear)                       -> col "Bias only"
#   line 196 eststo: ivreg2 excess micro microse LC_not_bind, cluster(idstudy countryyear)            -> col "Baseline"
#   line 198 eststo: ivreg2 excess micro LC_not_bind, cluster(idstudy countryyear)                    -> col "Bias ignored"
#   line 200 eststo: ivreg2 excess micro microse LC_not_bind [pweight=prec], cluster(idstudy countryyear)        -> col "Precision"
#   line 202 eststo: ivreg2 excess micro microse LC_not_bind [pweight=invperstudy], cluster(idstudy countryyear) -> col "Study"

suppressMessages(library(jsonlite))

if (file.exists("stata_compat.R")) source("stata_compat.R") else
  source("https://meta-analysis.cz/excess_sensitivity/replication/stata_compat.R")

data_path <- (if (file.exists("excess_sensitivity.csv")) "excess_sensitivity.csv" else
     "https://meta-analysis.cz/data/v1/excess_sensitivity/excess_sensitivity.csv")
stopifnot(file.exists(data_path))
d <- read.csv(data_path, stringsAsFactors = FALSE)

# ---- variable construction, exactly as in excess.do -------------------------------------

# line 32: replace LC_not_bind = 0 if switch==1
d$LC_not_bind <- ifelse(d$switch == 1, 0, d$LC_not_bind)

# line 14: gen prec = 1/se
d$prec <- 1 / d$se

# line 38 (perstudy definition not marked, pinned by the table note): number of estimates
# reported per study, over the full 3,127-row analysis sample used throughout Table 2 (no
# "if" filter applies here, unlike Table 1's micro/macro split).
perstudy <- ave(rep(1, nrow(d)), d$idstudy, FUN = length)
d$invperstudy <- 1 / perstudy

# line 42: gen microse = micro*se
d$microse <- d$micro * d$se

results <- list()
add <- function(label, value) results[[label]] <<- unname(value)

# ---- counts -------------------------------------------------------------------------------
add("N_obs_all_specs", nrow(d))
add("N_studies_all_specs", length(unique(d$idstudy)))

# ---- five specifications, all via st_ivreg2 (ivreg2, no `small`, two-way cluster) ---------

grab <- function(m, term) {
  cf <- st_coefs(m)
  row <- cf[cf$term == term, ]
  stopifnot(nrow(row) == 1)
  c(coef = row$estimate, se = row$std.error)
}

# --- spec 1: Bias only ---
m1 <- st_ivreg2(excess ~ micro + microse, data = d, cluster = ~idstudy + countryyear)
v <- grab(m1, "micro");    add("spec1_biasonly_micro_coef", v["coef"]);    add("spec1_biasonly_micro_se", v["se"])
v <- grab(m1, "microse");  add("spec1_biasonly_microse_coef", v["coef"]); add("spec1_biasonly_microse_se", v["se"])
v <- grab(m1, "(Intercept)"); add("spec1_biasonly_constant_coef", v["coef"]); add("spec1_biasonly_constant_se", v["se"])
b1 <- coef(m1)
impliedRoT1 <- b1["(Intercept)"] + b1["micro"]
RoTwithLC1  <- b1["(Intercept)"] + b1["micro"]
add("spec1_biasonly_impliedRoT", impliedRoT1)
add("spec1_biasonly_RoTwithLC", RoTwithLC1)

# --- spec 2: Baseline ---
m2 <- st_ivreg2(excess ~ micro + microse + LC_not_bind, data = d, cluster = ~idstudy + countryyear)
v <- grab(m2, "micro");       add("spec2_baseline_micro_coef", v["coef"]);       add("spec2_baseline_micro_se", v["se"])
v <- grab(m2, "microse");     add("spec2_baseline_microse_coef", v["coef"]);     add("spec2_baseline_microse_se", v["se"])
v <- grab(m2, "LC_not_bind"); add("spec2_baseline_LCunconstr_coef", v["coef"]);  add("spec2_baseline_LCunconstr_se", v["se"])
v <- grab(m2, "(Intercept)"); add("spec2_baseline_constant_coef", v["coef"]);    add("spec2_baseline_constant_se", v["se"])
b2 <- coef(m2)
add("spec2_baseline_impliedRoT", b2["(Intercept)"] + b2["micro"] + b2["LC_not_bind"])
add("spec2_baseline_RoTwithLC",  b2["(Intercept)"] + b2["micro"])

# --- spec 3: Bias ignored (no microse term) ---
m3 <- st_ivreg2(excess ~ micro + LC_not_bind, data = d, cluster = ~idstudy + countryyear)
v <- grab(m3, "micro");       add("spec3_biasignored_micro_coef", v["coef"]);      add("spec3_biasignored_micro_se", v["se"])
v <- grab(m3, "LC_not_bind"); add("spec3_biasignored_LCunconstr_coef", v["coef"]); add("spec3_biasignored_LCunconstr_se", v["se"])
v <- grab(m3, "(Intercept)"); add("spec3_biasignored_constant_coef", v["coef"]);   add("spec3_biasignored_constant_se", v["se"])
b3 <- coef(m3)
add("spec3_biasignored_impliedRoT", b3["(Intercept)"] + b3["micro"] + b3["LC_not_bind"])
add("spec3_biasignored_RoTwithLC",  b3["(Intercept)"] + b3["micro"])

# --- spec 4: Precision (pweight = prec) ---
m4 <- st_ivreg2(excess ~ micro + microse + LC_not_bind, data = d, cluster = ~idstudy + countryyear, weights = ~prec)
v <- grab(m4, "micro");       add("spec4_precision_micro_coef", v["coef"]);      add("spec4_precision_micro_se", v["se"])
v <- grab(m4, "microse");     add("spec4_precision_microse_coef", v["coef"]);    add("spec4_precision_microse_se", v["se"])
v <- grab(m4, "LC_not_bind"); add("spec4_precision_LCunconstr_coef", v["coef"]); add("spec4_precision_LCunconstr_se", v["se"])
v <- grab(m4, "(Intercept)"); add("spec4_precision_constant_coef", v["coef"]);   add("spec4_precision_constant_se", v["se"])
b4 <- coef(m4)
add("spec4_precision_impliedRoT", b4["(Intercept)"] + b4["micro"] + b4["LC_not_bind"])
add("spec4_precision_RoTwithLC",  b4["(Intercept)"] + b4["micro"])

# --- spec 5: Study (pweight = invperstudy) ---
m5 <- st_ivreg2(excess ~ micro + microse + LC_not_bind, data = d, cluster = ~idstudy + countryyear, weights = ~invperstudy)
v <- grab(m5, "micro");       add("spec5_study_micro_coef", v["coef"]);      add("spec5_study_micro_se", v["se"])
v <- grab(m5, "microse");     add("spec5_study_microse_coef", v["coef"]);    add("spec5_study_microse_se", v["se"])
v <- grab(m5, "LC_not_bind"); add("spec5_study_LCunconstr_coef", v["coef"]); add("spec5_study_LCunconstr_se", v["se"])
v <- grab(m5, "(Intercept)"); add("spec5_study_constant_coef", v["coef"]);   add("spec5_study_constant_se", v["se"])
b5 <- coef(m5)
add("spec5_study_impliedRoT", b5["(Intercept)"] + b5["micro"] + b5["LC_not_bind"])
add("spec5_study_RoTwithLC",  b5["(Intercept)"] + b5["micro"])

# ---- diagnostic only (not a target, not written to results.json) -------------------------
# One cell of Table 2 misses: spec4 "RoT share with LC" = _cons + micro, printed 0.004 * but
# produced 0.004922. The row is a linear combination, so its SE follows from the same clustered
# vcov by the delta method; Stata's `lincom _cons + micro` after the identical ivreg2 command
# returns exactly these numbers (0.004921758319, se 0.002405613813, p = 0.0408). Printed as a
# diagnostic so anyone re-running can see both the level and the significance level the cell
# would carry. See REPLICATION.md, "The one miss".
L4  <- c(1, 1, 0, 0)                       # (Intercept), micro, microse, LC_not_bind
est4 <- unname(b4["(Intercept)"] + b4["micro"])
se4  <- sqrt(as.numeric(t(L4) %*% vcov(m4) %*% L4))
z4   <- est4 / se4
cat(sprintf("
[diagnostic] spec4 _cons+micro = %.9f  se = %.9f  z = %.3f  p = %.4f
",
            est4, se4, z4, 2 * pnorm(-abs(z4))))
cat(sprintf("[diagnostic] spec4 |LC_not_bind| = %.9f  (printed -0.00440 *, p = %.4f)
",
            abs(unname(b4["LC_not_bind"])),
            2 * pnorm(-abs(unname(b4["LC_not_bind"]) / st_coefs(m4)$std.error[
              match("LC_not_bind", st_coefs(m4)$term)]))))

# ---- report -------------------------------------------------------------------------------
cat("\n==== Produced numbers (label = value) ====\n")
for (nm in names(results)) cat(sprintf("%-38s %s\n", nm, format(results[[nm]], digits = 10)))

writeLines(toJSON(results, auto_unbox = TRUE, digits = 10), "results.json")

cat("\n")
stata_compat_log()
