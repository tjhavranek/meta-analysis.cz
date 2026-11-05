# Replication of the positive-rate results in Tsai, Cheng, Hung & Lin (2026),
# "Comparing positive rates in traditional articles and registered reports within
# sport and exercise science: A stage 2 registered report", Psychology of Sport
# and Exercise 86, 102995. Authors' data: https://osf.io/fbd9m/
#
# Input : data/ (the two coding workbooks, downloaded from OSF if absent)
# Output: labelled results on the console (reference run: output.txt)
# Run   : Rscript replicate.R   (from this folder)
#
# Packages: readxl, sandwich, lmtest, geepack, digest;
#           clubSandwich and Exact are optional (CR2, Boschloo and Barnard tests)

args <- commandArgs(FALSE)
script_path <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(script_path) == 1) setwd(dirname(normalizePath(script_path)))

suppressWarnings(suppressPackageStartupMessages({
  library(readxl); library(sandwich); library(lmtest); library(geepack); library(digest)
}))
has_cs    <- suppressPackageStartupMessages(requireNamespace("clubSandwich", quietly = TRUE))
has_exact <- requireNamespace("Exact", quietly = TRUE)

NPERM <- 100000   # article-label permutations
NBOOT <- 10000    # cluster bootstrap draws
SEED  <- 20261105

report <- function(label, ...) cat(sprintf("%-62s %s\n", label, paste(..., collapse = "  ")))
fmt4   <- function(x) formatC(x, format = "f", digits = 4)
section_banner <- function(txt) cat("\n", strrep("=", 78), "\n", txt, "\n", strrep("=", 78), "\n", sep = "")

# ---- 0. Get data --------------------------------------------------------------
osf_files <- data.frame(
  name = c("Stage 2 Supplement 2 Registered Reports Data.xlsx",
           "Stage 2 Supplement 3 Traditional Publications Data.xlsx"),
  url  = c("https://osf.io/download/2cmab/", "https://osf.io/download/efwys/"),
  sha256 = c("1c765f0f0066e9aeff661e4fe4fb29e134341eeae2a66b61d53563d40d11a9b4",
             "b071fdd8ea411d6a289f129a02abef4839bddf93667ee1e4f8ab7afd914fa6e2"),
  stringsAsFactors = FALSE)
dir.create("data", showWarnings = FALSE)
for (i in seq_len(nrow(osf_files))) {
  path <- file.path("data", osf_files$name[i])
  if (!file.exists(path)) {
    status <- tryCatch(download.file(osf_files$url[i], path, mode = "wb", quiet = TRUE),
                       error = function(e) 1L, warning = function(w) 1L)
    if (!identical(as.integer(status), 0L)) {
      unlink(path)
      stop("Download failed for ", osf_files$name[i], " (", osf_files$url[i], "). ",
           "Download it manually from https://osf.io/fbd9m/ into data/.")
    }
  }
  stopifnot(file.size(path) > 1e4)
  if (digest(file = path, algo = "sha256") != osf_files$sha256[i])
    stop("Checksum mismatch for ", osf_files$name[i], ": the deposited file has changed.")
}
file_s2 <- file.path("data", osf_files$name[1])
file_s3 <- file.path("data", osf_files$name[2])

# ---- 1. Read and build the data ----------------------------------------------
# Visible sheets only: hidden sheets are identified from the sheet states in workbook.xml.
sheet_states <- function(path) {
  tmp <- tempfile(); dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))
  unzip(path, files = "xl/workbook.xml", exdir = tmp)
  x <- paste(readLines(file.path(tmp, "xl/workbook.xml"), warn = FALSE), collapse = "")
  tags <- regmatches(x, gregexpr("<sheet [^>]*>", x))[[1]]
  nm <- sub('.*name="([^"]*)".*', "\\1", tags)
  nm <- gsub("&lt;", "<", nm); nm <- gsub("&gt;", ">", nm)
  nm <- gsub("&quot;", '"', nm); nm <- gsub("&apos;", "'", nm)
  nm <- gsub("&amp;", "&", nm)               # last, so that &amp;lt; decodes correctly
  data.frame(sheet = nm, hidden = grepl('state=["\'](very)?[Hh]idden["\']', tags),
             stringsAsFactors = FALSE)
}
# Columns: 1 type, 2 title, 3 inclusion, 6 support codes. Sheets without data rows are skipped.
read_sheet <- function(path, sheet) {
  d <- suppressMessages(read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text"))
  if (ncol(d) < 3) return(NULL)
  d <- as.data.frame(d[-1, ], stringsAsFactors = FALSE)       # drop header row
  d <- d[!is.na(d[[2]]), ]                                    # rows with a title
  if (nrow(d) == 0) return(NULL)
  data.frame(sheet = sheet, type = d[[1]], title = d[[2]], incl = d[[3]],
             codes = if (ncol(d) >= 6) d[[6]] else NA_character_, stringsAsFactors = FALSE)
}

rr_all <- read_sheet(file_s2, 1)
rr_all$arm <- "RR"
sheet_info <- sheet_states(file_s3)
visible_sheets <- sheet_info$sheet[!sheet_info$hidden]
tr_all <- do.call(rbind, lapply(visible_sheets, function(s) read_sheet(file_s3, s)))
tr_all$arm <- "TR"

parse_codes <- function(s) {
  if (is.na(s)) return(character(0))
  x <- tolower(trimws(strsplit(s, ",")[[1]]))
  x[x != ""]
}
rr <- rr_all[rr_all$incl %in% "Yes" | grepl("^In Stage 1", rr_all$incl), ]
tr <- tr_all[tr_all$incl %in% "Yes", ]
rr$stage1 <- grepl("^In Stage 1", rr$incl)
tr$stage1 <- FALSE
art <- rbind(rr, tr)
art$aid <- seq_len(nrow(art))
art$rr  <- as.integer(art$arm == "RR")

hyp <- do.call(rbind, lapply(seq_len(nrow(art)), function(i) {
  cd <- parse_codes(art$codes[i])
  if (length(cd) == 0) return(NULL)
  data.frame(aid = art$aid[i], rr = art$rr[i], pos = seq_along(cd), code = cd,
             stringsAsFactors = FALSE)
}))
hyp$sup  <- as.integer(hyp$code %in% c("full", "partial"))
hyp$full <- as.integer(hyp$code == "full")

# ---- 2. Helper functions ------------------------------------------------------
wilson <- function(x, n, z = qnorm(.975)) {
  p <- x / n
  (p + z^2 / (2 * n) + c(-1, 1) * z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))) / (1 + z^2 / n)
}
exact_ci <- function(x, n) binom.test(x, n)$conf.int

# Pooled two-proportion z test; x1/n1 is the registered-report arm. alt "less": RR lower.
# The continuity correction is capped at |d| so that it cannot reverse the sign of d.
ztest <- function(x1, n1, x2, n2, correct = FALSE, alt = "less") {
  p <- (x1 + x2) / (n1 + n2)
  se <- sqrt(p * (1 - p) * (1 / n1 + 1 / n2))
  d <- x1 / n1 - x2 / n2
  if (correct) d <- sign(d) * (abs(d) - min(abs(d), 0.5 * (1 / n1 + 1 / n2)))
  z <- d / se
  if (alt == "less") pnorm(z) else 2 * pnorm(-abs(z))
}
fisher_less <- function(x1, n1, x2, n2)
  fisher.test(matrix(c(x1, n1 - x1, x2, n2 - x2), 2, byrow = TRUE), alternative = "less")$p.value

counts <- function(h, col = "sup", first = FALSE) {
  if (first) h <- h[h$pos == 1, ]
  c(x1 = sum(h[[col]][h$rr == 1]), n1 = sum(h$rr == 1),
    x2 = sum(h[[col]][h$rr == 0]), n2 = sum(h$rr == 0))
}

icc_anova <- function(h, col = "sup") {
  k <- tapply(h[[col]], h$aid, length); m <- tapply(h[[col]], h$aid, mean)
  N <- sum(k); a <- length(k); g <- mean(h[[col]])
  msb <- sum(k * (m - g)^2) / (a - 1)
  msw <- sum((h[[col]] - m[as.character(h$aid)])^2) / (N - a)
  k0 <- (N - sum(k^2) / N) / (a - 1)
  (msb - msw) / (msb + (k0 - 1) * msw)
}

# Article-clustered analyses of the hypothesis-level comparison (one-sided: RR lower).
cluster_tests <- function(h, col = "sup", seed = SEED, nperm = NPERM, nboot = NBOOT) {
  h <- h[order(h$aid), ]
  h$y <- h[[col]]
  cnt <- counts(h, col)
  naive <- ztest(cnt["x1"], cnt["n1"], cnt["x2"], cnt["n2"])
  fish  <- fisher_less(cnt["x1"], cnt["n1"], cnt["x2"], cnt["n2"])
  m <- lm(y ~ rr, data = h)
  V <- vcovCL(m, cluster = h$aid)   # sandwich default: HC1 with the G/(G-1) cluster adjustment
  tv <- coeftest(m, vcov. = V)["rr", "t value"]
  G <- length(unique(h$aid))
  out <- list(diff = unname(coef(m)["rr"]), naive_z = unname(naive), fisher = unname(fish),
              crse_norm = unname(pnorm(tv)), crse_t = unname(pt(tv, G - 1)))
  if (has_cs) {
    ct <- clubSandwich::coef_test(m, vcov = "CR2", cluster = h$aid)
    p2s <- ct$p_Satt[ct$Coef == "rr"]
    out$cr2 <- unname(ifelse(coef(m)["rr"] < 0, p2s / 2, 1 - p2s / 2))
  }
  a <- aggregate(cbind(s = y, n = 1) ~ aid + rr, data = h, FUN = sum)
  s <- a$s; n <- a$n; lab <- a$rr
  dd <- function(l) sum(s[l == 1]) / sum(n[l == 1]) - sum(s[l == 0]) / sum(n[l == 0])
  d0 <- dd(lab)
  set.seed(seed)
  perm <- replicate(nperm, dd(sample(lab)))
  out$perm <- (sum(perm <= d0 + 1e-12) + 1) / (nperm + 1)
  i1 <- which(lab == 1); i0 <- which(lab == 0)
  boot <- replicate(nboot, {
    b1 <- sample(i1, replace = TRUE); b0 <- sample(i0, replace = TRUE)
    sum(s[b1]) / sum(n[b1]) - sum(s[b0]) / sum(n[b0])
  })
  out$boot <- unname(quantile(boot, c(.025, .975)))
  g <- geeglm(y ~ rr, id = aid, data = h, family = binomial, corstr = "exchangeable")
  out$gee <- summary(g)$coefficients["rr", "Pr(>|W|)"]
  share <- s / n
  out$mw <- wilcox.test(share[lab == 1], share[lab == 0], alternative = "less", exact = FALSE)$p.value
  out$share <- c(rr = mean(share[lab == 1]), tr = mean(share[lab == 0]))
  out
}
print_cluster <- function(o, tag = "") {
  report(paste0(tag, "difference in support rates (RR - TR)"), fmt4(o$diff))
  report(paste0(tag, "naive pooled z, one-sided"), fmt4(o$naive_z))
  report(paste0(tag, "Fisher, one-sided"), fmt4(o$fisher))
  report(paste0(tag, "cluster-robust LPM, one-sided, normal"), fmt4(o$crse_norm))
  report(paste0(tag, "cluster-robust LPM, one-sided, t(G-1)"), fmt4(o$crse_t))
  if (has_cs) report(paste0(tag, "CR2 (Satterthwaite), one-sided"), fmt4(o$cr2))
  report(paste0(tag, "article-label permutation, one-sided"), fmt4(o$perm))
  report(paste0(tag, "cluster bootstrap 95% interval"), paste(round(o$boot, 3), collapse = " to "))
  report(paste0(tag, "exchangeable GEE, two-sided"), fmt4(o$gee))
  report(paste0(tag, "Mann-Whitney on article shares, one-sided"), fmt4(o$mw))
  report(paste0(tag, "mean article share supported, RR / TR"), round(o$share[["rr"]], 3), "/",
         round(o$share[["tr"]], 3))
}

# ---- 3. Deposit counts --------------------------------------------------------
section_banner("1. Deposit counts")
report("Supplement 2: rows with a title", nrow(rr_all))
report("Supplement 2: included / not included", sum(art$arm == "RR"), "/", nrow(rr_all) - sum(art$arm == "RR"))
report("Supplement 3: sheets total / hidden (skipped)", nrow(sheet_info), "/", sum(sheet_info$hidden))
report("Supplement 3: visible rows with a title", nrow(tr_all))
report("Supplement 3: visible Yes / No / registered-report flag",
       sum(tr_all$incl %in% "Yes"), "/", sum(tr_all$incl %in% "No"), "/",
       sum(grepl("registered report", tr_all$incl, ignore.case = TRUE)))
cat("Candidate titles and included articles per visible Supplement 3 sheet:\n")
cand <- data.frame(candidates = sapply(visible_sheets, function(s) sum(tr_all$sheet == s)),
                   included = sapply(visible_sheets, function(s) sum(tr_all$sheet == s & tr_all$incl %in% "Yes")))
print(cand)
sport_tr <- sum(art$arm == "TR" & toupper(art$type) == "SP")
sport_rr <- sum(art$arm == "RR" & tolower(art$type) == "sports")
report("Sport-type included articles: traditional / registered", paste0(sport_tr, "/", sum(art$arm == "TR")),
       "vs", paste0(sport_rr, "/", sum(art$arm == "RR")))
report("'Null' support codes, Supplement 2 / Supplement 3 (visible)",
       sum(unlist(lapply(rr_all$codes, parse_codes)) == "null"), "/",
       sum(unlist(lapply(tr_all$codes, parse_codes)) == "null"))
lab_all <- c(rr_all$incl, tr_all$incl)
lab_all <- ifelse(grepl("^In Stage 1", lab_all), "In Stage 1 Report: <protocol title>", lab_all)
cat("Inclusion labels (both workbooks, visible sheets):\n")
print(table(lab_all))
report("Distinct literal inclusion strings", length(unique(c(rr_all$incl, tr_all$incl))))

# ---- 4. Table 1 ---------------------------------------------------------------
section_banner("2. Table 1 counts")
for (arm in c("RR", "TR")) {
  a <- art[art$arm == arm, ]; h <- hyp[hyp$rr == (arm == "RR"), ]
  none <- sum(sapply(a$codes, function(s) !any(parse_codes(s) %in% c("full", "partial"))))
  report(paste0(arm, ": articles"), nrow(a))
  report(paste0(arm, ": first hypothesis supported"), sum(h$sup[h$pos == 1]), "of", sum(h$pos == 1))
  report(paste0(arm, ": all hypotheses supported"), sum(h$sup), "of", nrow(h))
  report(paste0(arm, ": articles with no supported hypothesis"), none)
}

# ---- 5. First hypothesis -------------------------------------------------------
section_banner("3. First-hypothesis tests (7/10 vs 51/59), RR lower")
c1 <- counts(hyp, first = TRUE)
with(as.list(c1), {
  report("Pooled z, one-sided, uncorrected", fmt4(ztest(x1, n1, x2, n2)))
  report("Pooled z, one-sided, continuity-corrected", fmt4(ztest(x1, n1, x2, n2, correct = TRUE)))
  report("Pooled z, two-sided, uncorrected", fmt4(ztest(x1, n1, x2, n2, alt = "two")))
  report("Fisher, one-sided", fmt4(fisher_less(x1, n1, x2, n2)))
  if (has_exact) {
    # Exact::exact.test treats rows as the groups (columns: successes, failures)
    tab2 <- matrix(c(x1, n1 - x1, x2, n2 - x2), 2, byrow = TRUE)
    for (mth in c("Boschloo", "z-pooled")) {
      b <- Exact::exact.test(tab2, alternative = "less", method = mth, model = "Binomial",
                             to.plot = FALSE)
      report(paste0(ifelse(mth == "Boschloo", "Boschloo", "Barnard (z-pooled)"), ", one-sided"),
             fmt4(b$p.value))
    }
  } else report("Boschloo and Barnard, one-sided", "skipped (package Exact not installed)")
  tab <- matrix(c(x1, n1 - x1, x2, n2 - x2), 2, byrow = TRUE)
  report("Smallest expected cell count", round(min(outer(rowSums(tab), colSums(tab)) / sum(tab)), 2))
})

# ---- 6. All hypotheses ----------------------------------------------------------
section_banner("4. All hypotheses (22/41 vs 128/162), RR lower")
ca <- counts(hyp)
report("Hypotheses / articles", nrow(hyp), "/", nrow(art))
icc <- icc_anova(hyp)
mbar <- tapply(hyp$aid, hyp$rr, function(x) mean(table(x)))
# Design effect 1 + (mean cluster size - 1) * ICC: one pooled ICC, arm-specific mean cluster sizes
de <- 1 + (mbar - 1) * icc
report("ICC (one-way ANOVA estimator)", fmt4(icc))
report("Mean hypotheses per article, RR / TR", round(mbar["1"], 2), "/", round(mbar["0"], 2))
report("Design effects, RR / TR", round(de["1"], 3), "/", round(de["0"], 3))
p_de <- ztest(ca["x1"] / de["1"], ca["n1"] / de["1"], ca["x2"] / de["0"], ca["n2"] / de["0"])
report("Design-effect-adjusted pooled z, one-sided", fmt4(p_de))
o_sup <- cluster_tests(hyp)
print_cluster(o_sup)
cat("\nFull-only support (not the registered definition):\n")
cf <- counts(hyp, "full")
report("Full-only counts RR, TR", paste0(cf["x1"], "/", cf["n1"]), paste0(cf["x2"], "/", cf["n2"]))
o_full <- cluster_tests(hyp, "full")
print_cluster(o_full, "Full-only: ")

# ---- 7. Subsets -------------------------------------------------------------------
section_banner("5. Subsets")
subset_run <- function(drop_ids, label) {
  cat("\n--", label, "--\n")
  h <- hyp[!hyp$aid %in% drop_ids, ]
  c1 <- counts(h, first = TRUE); ca <- counts(h)
  report("Dropped articles", length(drop_ids))
  report("First hypothesis RR, TR", paste0(c1["x1"], "/", c1["n1"]), paste0(c1["x2"], "/", c1["n2"]))
  report("First hypothesis Fisher, one-sided",
         fmt4(fisher_less(c1["x1"], c1["n1"], c1["x2"], c1["n2"])))
  report("First hypothesis pooled z, one-sided",
         fmt4(ztest(c1["x1"], c1["n1"], c1["x2"], c1["n2"])))
  report("First hypothesis pooled z, one-sided, continuity-corrected",
         fmt4(ztest(c1["x1"], c1["n1"], c1["x2"], c1["n2"], correct = TRUE)))
  if (has_exact) {
    tab2 <- matrix(c(c1["x1"], c1["n1"] - c1["x1"], c1["x2"], c1["n2"] - c1["x2"]), 2, byrow = TRUE)
    b <- Exact::exact.test(tab2, alternative = "less", method = "Boschloo", model = "Binomial",
                           to.plot = FALSE)
    report("First hypothesis Boschloo, one-sided", fmt4(b$p.value))
  }
  report("All hypotheses RR, TR", paste0(ca["x1"], "/", ca["n1"]), paste0(ca["x2"], "/", ca["n2"]))
  o <- cluster_tests(h)
  report("All hypotheses: cluster-robust LPM, one-sided, normal", fmt4(o$crse_norm))
  if (has_cs) report("All hypotheses: CR2, one-sided", fmt4(o$cr2))
  report("All hypotheses: article-label permutation, one-sided", fmt4(o$perm))
  report("All hypotheses: cluster bootstrap 95% interval", paste(round(o$boot, 3), collapse = " to "))
}
has_title <- function(k) art$aid[art$arm == "RR" & grepl(k, art$title, fixed = TRUE)]
matched_drop <- unlist(lapply(c("Structured Supervised Exercise", "Mitigating Feelings of Loneliness",
                                "After-school Sport Sampling"), has_title))
subset_run(matched_drop, "Matched strata only (drop 3 RRs without included traditional articles)")
subset_run(art$aid[art$stage1], "Drop the two RRs coded from the Stage 1 report")
subset_run(has_title("resistance exercises on inhibitory control"), "Drop Lin et al. 2024a")

# ---- 8. Intervals and Table 3/4 p values ------------------------------------------
section_banner("6. Intervals and Table 3/4 p values")
for (xn in list(c(7, 10), c(51, 59), c(22, 41), c(128, 162), c(142, 148), c(15, 30))) {
  w <- wilson(xn[1], xn[2]); e <- exact_ci(xn[1], xn[2])
  report(sprintf("%d/%d  Wilson | exact", xn[1], xn[2]),
         sprintf("%.3f to %.3f | %.3f to %.3f", w[1], w[2], e[1], e[2]))
}
ptest <- function(x, n, correct) suppressWarnings(prop.test(x, n, correct = correct))$p.value
report("7/10 vs 15/30, two-sided, Yates", fmt4(ptest(c(7, 15), c(10, 30), TRUE)))
report("7/10 vs 15/30, two-sided, uncorrected", fmt4(ptest(c(7, 15), c(10, 30), FALSE)))
report("51/59 vs 142/148, two-sided, uncorrected", fmt4(ptest(c(51, 142), c(59, 148), FALSE)))
report("51/59 vs 142/148, two-sided, Yates", fmt4(ptest(c(51, 142), c(59, 148), TRUE)))

# ---- 9. Stage 1 sample size and power ----------------------------------------------
section_banner("7. Stage 1 sample size (Fleiss, Levin and Paik, formulas 4.18-4.19) and exact power")
# Formulas 4.18-4.19 of Fleiss, Levin and Paik (3rd ed.), as cited in the Stage 1 report:
# RR articles needed for p1 (RR) vs p2 (traditional), ratio r traditional per RR,
# one-sided alpha, continuity-corrected.
fleiss_n <- function(p1, p2, r, alpha = .05, power = .95) {
  za <- qnorm(1 - alpha); zb <- qnorm(power)
  pbar <- (p1 + r * p2) / (1 + r)
  m <- (za * sqrt((r + 1) * pbar * (1 - pbar)) + zb * sqrt(r * p1 * (1 - p1) + p2 * (1 - p2)))^2 /
    (r * (p2 - p1)^2)
  m / 4 * (1 + sqrt(1 + 2 * (r + 1) / (r * m * abs(p2 - p1))))^2
}
for (r in c(4, 5, 6, 7, 12, 13))
  report(sprintf("Ratio %d:1  RR articles needed (p1=.44, p2=.96)", r), round(fleiss_n(.44, .96, r), 2))

power_exact <- function(p1, p2, n1, n2, test, alpha = .05) {
  g <- expand.grid(a = 0:n1, c = 0:n2)
  if (test == "fisher") {
    p <- phyper(g$a, g$a + g$c, n1 + n2 - g$a - g$c, n1)
  } else {
    pooled <- (g$a + g$c) / (n1 + n2)
    se <- sqrt(pooled * (1 - pooled) * (1 / n1 + 1 / n2))
    p <- ifelse(se > 0, pnorm((g$a / n1 - g$c / n2) / se), 1)
  }
  sum(dbinom(g$a, n1, p1) * dbinom(g$c, n2, p2) * (p <= alpha + 1e-12))
}
for (rates in list(c(.44, .96), c(.70, .86), c(7 / 10, 51 / 59)))
  report(sprintf("Exact power, 10 vs 59, p1=%.3f p2=%.3f  Fisher | z", rates[1], rates[2]),
         sprintf("%.3f | %.3f", power_exact(rates[1], rates[2], 10, 59, "fisher"),
                 power_exact(rates[1], rates[2], 10, 59, "z")))

cat("\nSession: ", R.version.string, "\n", sep = "")
