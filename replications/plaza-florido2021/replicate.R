## replicate.R
## Replication of the whole-blood RNA-seq analysis in
##   Plaza-Florido A, Altmae S, Esteban FJ, Lof M, Radom-Aizik S, Ortega FB (2021).
##   Cardiorespiratory fitness in children with overweight/obesity: insights into the molecular mechanisms.
##   Scand J Med Sci Sports 31(11):2083-2091. doi:10.1111/sms.14028
##
## Data: the authors' deposit at https://osf.io/neuys/ (four files: raw counts, sample table, normalised matrix,
##   R script), named in section 2.5 of the article. On the first run the script downloads the four files into data/
##   and checks their MD5. Raw reads are at GEO GSE164873 and are not used here.
## Optional inputs in data/supporting/ (not distributed here; each comparison is skipped if its file is absent):
##   sms14028-sup-0001-tables1-s2.docx  Supporting Information of the article (Wiley), Supplementary Table 1
##   article_tables.txt, article_text.txt  article text and tables as plain text (author manuscript, PMC12530440)
##   figure2_genes.csv  the 33 gene labels of Figure 2 (columns gene, direction = up or down)
##
## Run from this folder:  Rscript replicate.R > output.txt 2>&1
## Needs R >= 4.2, limma, edgeR (DESeq2 is loaded by the authors' script but not used; it is skipped if absent).
## Seeds: 20261019 (the within-sex permutation of section C2a, P1) and 20261105 (all other permutations).
## Results do not depend on the number of cores (permutations are drawn before they are distributed).

args <- commandArgs(FALSE)
f <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(f)) setwd(dirname(normalizePath(f)))
suppressWarnings(suppressPackageStartupMessages({library(limma); library(edgeR); library(parallel)}))
options(width = 150, digits = 6, stringsAsFactors = FALSE)
SEED <- 20261105
## Permutation draws per scheme in section C2a (P6 always uses all 55 pairs). About 11 minutes with 6 cores at these values.
NDRAW <- c(P1 = 30, P2 = 200, P3 = 40, P4 = 200, P5 = 200)
options(timeout = 600)
T0 <- Sys.time()
NC <- suppressWarnings(as.integer(Sys.getenv("NCORES", "")))
if (is.na(NC)) NC <- max(1L, min(6L, detectCores() - 2L))
sec <- function(x) cat("\n\n==== ", x, " ====\n", sep = "")
say <- function(tag, label, ...) {
  a <- list(...); s <- ""
  for (k in seq_along(a)) {
    z <- if (is.character(a[[k]])) paste(trimws(a[[k]]), collapse = ", ") else paste(format(a[[k]], digits = 6, trim = TRUE), collapse = ", ")
    sep <- if (k == 1) " " else if (is.character(a[[k]]) || is.character(a[[k - 1]])) " " else ", "
    s <- paste0(s, sep, z)
  }
  cat("[", tag, "] ", label, if (length(a)) ":", s, "\n", sep = "")
}
ascii <- function(x) iconv(x, "UTF-8", "ASCII", sub = "?")

cat("R", as.character(getRversion()), "| limma", as.character(packageVersion("limma")),
    "| edgeR", as.character(packageVersion("edgeR")), "| cores", NC, "\n")
HAS_ADAPT <- "adaptive.span" %in% names(formals(voom))
say("setup", "voom has argument adaptive.span", HAS_ADAPT, "| its default", if (HAS_ADAPT) deparse(formals(voom)$adaptive.span) else "n/a (span 0.5 only)")

## ------------------------------------------------------------------------------------------------
sec("1. Deposited files")
osf <- data.frame(
  file = c("Fit_Unfit_BW_raw.txt.txt", "coldata.txt.txt", "voomQuantiles_normalized.txt.txt", "ScriptR_RNAseq_limma_FitUnfit.R"),
  url  = paste0("https://osf.io/download/", c("8rn5c", "smbk7", "76jwb", "wjb5v"), "/"),
  md5  = c("44e6b8c9e4d90fd5b17db60a9e9397bb", "f04f2bad555e8755f5b573da330da937", "799bcabd2750f32069e1a4a661a46ece", "00600f8c7e0e3a6569230d75c7805730"))
dir.create("data", showWarnings = FALSE)
for (k in seq_len(nrow(osf))) {
  p <- file.path("data", osf$file[k]); fresh <- !file.exists(p)
  if (fresh) {
    message("downloading ", osf$file[k], " from ", osf$url[k])
    ok <- tryCatch({ download.file(osf$url[k], p, mode = "wb", quiet = TRUE) == 0 }, error = function(e) FALSE, warning = function(w) FALSE)
    if (!isTRUE(ok) || !file.exists(p)) { unlink(p); stop("Download of ", osf$file[k], " failed. Get it from ", osf$url[k], " (project https://osf.io/neuys/) and save it in data/ under that name.", call. = FALSE) }
  }
  got <- unname(tools::md5sum(p))
  if (got != osf$md5[k]) {
    if (fresh) unlink(p)
    stop("MD5 of data/", osf$file[k], " is ", got, ", expected ", osf$md5[k], ". ", if (fresh) "The downloaded file was removed. " else "",
         "Download it again from ", osf$url[k], " and save it in data/ under that name.", call. = FALSE)
  }
}
dep_files <- osf$file
say("data", "four deposit files in data/, MD5 checked against the OSF checksums", "ok")
cnt <- read.table("data/Fit_Unfit_BW_raw.txt.txt", header = TRUE, row.names = 1, check.names = FALSE)
cd  <- read.table("data/coldata.txt.txt", header = TRUE, row.names = 1)
dep <- as.matrix(read.table("data/voomQuantiles_normalized.txt.txt", header = TRUE, row.names = 1, check.names = FALSE))
Y <- as.matrix(cnt); storage.mode(Y) <- "double"
n <- ncol(Y)
sym <- sub("_[0-9]+$", "", rownames(Y))
spike <- grepl("^RNA_SPIKE", sym)
det <- rowSums(Y > 0); tot <- rowSums(Y)
Fit <- factor(cd$Fit_Unfit_BW, levels = c("Fit_0", "Unfit_1"))
sex <- factor(cd$Sex_I, levels = c("male_0", "female_1"))
PHV <- cd$PHV_Moore_final_I
say("data", "count matrix rows (genes) x columns (libraries)", nrow(Y), ncol(Y))
say("data", "all cells non-negative integers", all(Y >= 0 & Y == round(Y)), "| NA cells", sum(is.na(Y)), "| identical library columns", sum(duplicated(t(Y))))
say("data", "sample names identical and in the same order: counts vs sample table, counts vs normalised matrix", identical(colnames(Y), rownames(cd)), identical(colnames(Y), colnames(dep)))
say("data", "duplicated row names", sum(duplicated(rownames(Y))), "| rows sharing a gene symbol with an earlier row", sum(duplicated(sym)))
cat("[data] fitness group x sex:\n"); print(table(Fit, sex))
say("data", "spike-in rows (RNA_SPIKE_)", sum(spike), "| of which detected in >= 1 sample", sum(spike & det > 0), "| all-zero rows", sum(tot == 0), "| rows detected in <= 5 samples (%)", round(100 * mean(det <= 5), 1))
say("data", "PHV offset mean (SD): fit", round(mean(PHV[Fit == "Fit_0"]), 2), round(sd(PHV[Fit == "Fit_0"]), 2), "| unfit", round(mean(PHV[Fit == "Unfit_1"]), 2), round(sd(PHV[Fit == "Unfit_1"]), 2), "| all", round(mean(PHV), 2), round(sd(PHV), 2), "| range", range(PHV))

X3 <- model.matrix(~ +Fit + sex + PHV + Fit * sex * PHV)       # design of script line 31
Xa <- model.matrix(~ Fit + sex + PHV)                           # additive design described in the Methods
LAST <- ncol(X3)

vm <- function(y, X, hist = FALSE, quant = TRUE) {
  nm <- if (quant) "quantile" else "none"
  if (HAS_ADAPT && hist) voom(y, X, normalize.method = nm, span = 0.5, adaptive.span = FALSE) else voom(y, X, normalize.method = nm)
}
pipe <- function(y, X, coef = ncol(X), hist = FALSE, tmm = FALSE, quant = TRUE, robust = FALSE, trend = FALSE) {
  obj <- if (isTRUE(tmm)) calcNormFactors(DGEList(y)) else y
  v <- vm(obj, X, hist, quant)
  e <- eBayes(lmFit(v, X), robust = robust, trend = trend)
  tt <- topTable(e, coef = coef, number = Inf, sort.by = "none")
  list(sym = sub("_[0-9]+$", "", rownames(tt)), lfc = tt$logFC, p = tt$P.Value, adj = tt$adj.P.Val, sigma = e$sigma, v = v, e = e)
}
nhit <- function(r) sum(r$adj < 0.05)
nsplit <- function(r) paste0(sum(r$adj < 0.05 & r$lfc < 0), " neg / ", sum(r$adj < 0.05 & r$lfc > 0), " pos")

## ------------------------------------------------------------------------------------------------
sec("2. The authors' script, run as deposited")
## Two edits are needed to run the script: the input names (it reads Fit_Unfit_BW.txt and coldata.txt) and, when
## DESeq2 is not installed, the unused library(DESeq2) line. For the "span 0.5" run the voom call is made explicit.
run_authors <- function(hist) {
  src <- readLines("data/ScriptR_RNAseq_limma_FitUnfit.R", warn = FALSE)
  if (!requireNamespace("DESeq2", quietly = TRUE)) src <- src[!grepl("^library[(]DESeq2[)]", src)]
  src <- sub('"Fit_Unfit_BW.txt"', '"Fit_Unfit_BW_raw.txt.txt"', src, fixed = TRUE)
  src <- sub('"coldata.txt"', '"coldata.txt.txt"', src, fixed = TRUE)
  if (hist) {
    old <- 'vQuant <- voom(data.matrix, design, normalize="quantile")'
    stopifnot(any(grepl(old, src, fixed = TRUE)))
    src <- sub(old, 'vQuant <- voom(data.matrix, design, normalize="quantile", span=0.5, adaptive.span=FALSE)', src, fixed = TRUE)
  }
  wd <- tempfile("authors_"); dir.create(wd)
  file.copy(file.path("data", c("Fit_Unfit_BW_raw.txt.txt", "coldata.txt.txt")), wd)
  writeLines(src, file.path(wd, "script_patched.R"))
  owd <- setwd(wd); on.exit(setwd(owd), add = TRUE)
  env <- new.env()
  suppressMessages(source("script_patched.R", local = env))
  for (a in c("file", "coldata")) if (a %in% search()) detach(a, character.only = TRUE)
  list(topQ = env$topQ, vQ = env$vQuant)
}
cur <- pipe(Y, X3); his <- pipe(Y, X3, hist = TRUE)
for (h in c(FALSE, TRUE)) {
  au <- run_authors(h); tq <- au$topQ[rownames(Y), ]
  r <- if (h) his else cur
  say("A2", paste0("script, ", if (h) "voom span 0.5 fixed (pre-3.66 default)" else "current limma default", ": sum(adj.P.Val < 0.05)"), sum(au$topQ$adj.P.Val < 0.05),
      "| coefficient < 0:", sum(au$topQ$adj.P.Val < 0.05 & au$topQ$logFC < 0), "| > 0:", sum(au$topQ$adj.P.Val < 0.05 & au$topQ$logFC > 0),
      "| nominal p < 0.05:", sum(au$topQ$P.Value < 0.05))
  say("A2", "  max |script - own pipeline|: logFC, adj.P.Val", format(max(abs(tq$logFC - r$lfc)), digits = 3), format(max(abs(tq$adj.P.Val - r$adj)), digits = 3))
  say("A2", "  max |voom E from script - deposited normalised matrix|", format(max(abs(au$vQ$E - dep)), digits = 3))
}
say("A2", "script mentions calcNormFactors / TMM", any(grepl("calcNormFactors|TMM", readLines("data/ScriptR_RNAseq_limma_FitUnfit.R", warn = FALSE))))
nw <- tryCatch(readLines(system.file("NEWS.Rd", package = "limma"), warn = FALSE), error = function(e) character())
vv <- grep("section[{]version", nw)
for (k in grep("adaptive.span. in voom", nw)) say("A2", "limma NEWS", trimws(sub("[\\]section[{]version ([0-9.]+).*", "\\1", nw[max(vv[vv <= k])])), trimws(substr(nw[k], 1, 110)))

## hand-coded voom as in limma before 3.60 (no adaptive span), against voom(span = 0.5, adaptive.span = FALSE)
voom_old <- function(y, X, span = 0.5) {
  lib <- colSums(y); E <- normalizeBetweenArrays(t(log2(t(y + 0.5) / (lib + 1) * 1e6)), method = "quantile")
  fit <- lmFit(E, X)
  sx <- fit$Amean + mean(log2(lib + 1)) - log2(1e6); sy <- sqrt(fit$sigma)
  az <- rowSums(y) == 0                                       # all-zero rows are left out of the trend
  f <- approxfun(lowess(sx[!az], sy[!az], f = span), rule = 2, ties = list("ordered", mean))
  fc <- 1e-6 * t(t(2^(fit$coefficients %*% t(fit$design))) * (lib + 1))
  w <- 1 / f(log2(fc))^4; dim(w) <- dim(fc)
  list(E = E, weights = w)
}
vo <- voom_old(Y, X3)
say("A2", "hand-coded pre-3.60 voom vs voom(span=0.5, adaptive.span=FALSE): max |E diff|, max |weight diff|", format(max(abs(vo$E - his$v$E)), digits = 3), format(max(abs(vo$weights - his$v$weights)), digits = 3))
sp_cur <- tryCatch(voom(Y, X3, normalize.method = "quantile", save.plot = TRUE)$span, error = function(e) NULL)
say("A2", "span chosen by the current default (adaptive)", if (is.null(sp_cur)) "n/a" else round(sp_cur, 4))

## ------------------------------------------------------------------------------------------------
## Optional inputs from the article (data/supporting/). Each comparison runs only if its file is present.
SUPD <- "data/supporting"
f_s1 <- file.path(SUPD, "sms14028-sup-0001-tables1-s2.docx"); f_tab <- file.path(SUPD, "article_tables.txt")
f_txt <- file.path(SUPD, "article_text.txt"); f_fig <- file.path(SUPD, "figure2_genes.csv")
HAS_S1 <- file.exists(f_s1); HAS_TAB <- file.exists(f_tab); HAS_TXT <- file.exists(f_txt); HAS_FIG <- file.exists(f_fig)
skip <- function(what, file, how) cat("[skipped] ", what, ": data/supporting/", file, " not found (", how, ")\n", sep = "")
S1 <- ent <- art <- tabs <- NULL; fig2_up <- fig2_dn <- character()
if (HAS_S1) {                                              # Supplementary Table 1 is the first table of the docx
  zd <- tempfile("docx_"); dir.create(zd); unzip(f_s1, files = "word/document.xml", exdir = zd)
  x <- paste(readLines(file.path(zd, "word/document.xml"), encoding = "UTF-8", warn = FALSE), collapse = "")
  x <- substr(x, regexpr("<w:tbl>", x, fixed = TRUE), regexpr("</w:tbl>", x, fixed = TRUE))
  rows <- strsplit(x, "</w:tr>", fixed = TRUE)[[1]]; rows <- rows[grepl("<w:tc>", rows, fixed = TRUE)]
  cells <- lapply(rows, function(r) {
    cc <- strsplit(r, "</w:tc>", fixed = TRUE)[[1]]; cc <- cc[grepl("<w:tc>", cc, fixed = TRUE)]
    vapply(cc, function(z) paste(sub("^<w:t[^>]*>", "", regmatches(z, gregexpr("<w:t( [^>]*)?>[^<]*", z))[[1]]), collapse = ""), "")
  })
  S1 <- data.frame(gene = trimws(vapply(cells[-1], `[`, "", 1)), log2FC = as.numeric(vapply(cells[-1], `[`, "", 2)), FDR = as.numeric(vapply(cells[-1], `[`, "", 3)))
} else skip("comparison with Supplementary Table 1", basename(f_s1), "Supporting Information of the article on Wiley, https://doi.org/10.1111/sms.14028")
if (HAS_TAB) {                                             # gene symbols and arrows of Tables 2-3
  tabs <- enc2utf8(readLines(f_tab, encoding = "UTF-8", warn = FALSE))
  seg <- tabs[grep("^Table 2[.]", tabs):grep("^Bold genes", tabs)]
  seg <- seg[grepl("[\u2191\u2193]", seg)]
  ent <- do.call(rbind, lapply(seg, function(ln) {
    pt <- strsplit(ln, " | ", fixed = TRUE)[[1]]
    g <- regmatches(pt[2], gregexpr("[^\u2191\u2193 |]+[\u2191\u2193]", pt[2]))[[1]]
    data.frame(row_label = trimws(pt[1]), gene = sub("[\u2191\u2193]$", "", g), arrow = ifelse(grepl("\u2191$", g), "up", "down"))
  }))
} else skip("Tables 2-3 and Table 1 comparisons", basename(f_tab), "text of the article's tables, see README")
if (HAS_TXT) art <- enc2utf8(paste(readLines(f_txt, encoding = "UTF-8", warn = FALSE), collapse = " ")) else skip("text searches (C5-C8)", basename(f_txt), "text of the article, see README")
if (HAS_FIG) { fg <- read.csv(f_fig); fig2_up <- fg$gene[fg$direction == "up"]; fig2_dn <- fg$gene[fg$direction == "down"] } else skip("comparison with the Figure 2 labels", basename(f_fig), "gene labels read from Figure 2 of the article, see README")
HAS_ENT <- HAS_TAB

## ------------------------------------------------------------------------------------------------
sec("3. Printed numbers against specifications")
cat("Printed (author manuscript): 256 genes, 145 up and 111 down in fit, log2FC -5.83 to 6.55, 33 top genes in Figure 2 (22 up, 11 down),\n",
    "108 arrow entries for 57 genes in Tables 2-3; Supplementary Table 1 lists 256 genes. Coefficient < 0 is printed as 'up in fit'.\n", sep = "")
if (HAS_ENT) say("A3", "Tables 2-3 entries", nrow(ent), "| unique genes", length(unique(ent$gene)))
if (HAS_S1) say("A3", "Table S1 genes", nrow(S1))
if (HAS_FIG) say("A3", "Figure 2 labels up/down", length(fig2_up), length(fig2_dn))
score <- function(r, label, drop_spike = FALSE) {
  hit <- r$adj < 0.05; if (drop_spike) hit <- hit & !grepl("^RNA_SPIKE", r$sym)
  big <- which(hit & abs(r$lfc) >= 1.5); up <- r$sym[big][r$lfc[big] < 0]; dn <- r$sym[big][r$lfc[big] > 0]
  tab108 <- arrow108 <- S1_of_256 <- S1_dlfc <- S1_rel_fdr <- NA; fig2 <- NA; extra <- miss <- character()
  if (HAS_ENT) { i <- match(ent$gene, r$sym); sig <- r$adj[i] < 0.05; ar <- sign(r$lfc[i]) == ifelse(ent$arrow == "up", -1, 1); tab108 <- sum(sig); arrow108 <- sum(ar) }
  if (HAS_FIG) { extra <- setdiff(r$sym[big], c(fig2_up, fig2_dn)); miss <- setdiff(c(fig2_up, fig2_dn), c(up[up %in% fig2_up], dn[dn %in% fig2_dn])); fig2 <- length(extra) == 0 && length(miss) == 0 }
  if (HAS_S1) {
    s <- match(S1$gene, r$sym); ok <- !is.na(s) & hit[s]; S1_of_256 <- sum(ok)
    if (any(ok)) { S1_dlfc <- signif(max(abs(S1$log2FC[ok] + r$lfc[s[ok]])), 2); S1_rel_fdr <- signif(max(abs(S1$FDR[ok] / r$adj[s[ok]] - 1)), 2) }
  }
  data.frame(spec = label, hits = sum(hit), neg = sum(r$lfc[hit] < 0), pos = sum(r$lfc[hit] > 0),
    min = round(-max(r$lfc[hit]), 2), max = round(-min(r$lfc[hit]), 2), n15 = length(big), tab108 = tab108, arrow108 = arrow108,
    fig2 = fig2, spike = sum(hit & grepl("^RNA_SPIKE", r$sym)),
    S1_of_256 = S1_of_256, S1_dlfc = S1_dlfc, S1_rel_fdr = S1_rel_fdr,
    fig2_extra = paste(extra, collapse = ","), fig2_missing = paste(miss, collapse = ","))
}
tm <- pipe(Y, X3, tmm = TRUE); tmh <- pipe(Y, X3, hist = TRUE, tmm = TRUE); rb <- pipe(Y, X3, hist = TRUE, robust = TRUE)
sc <- rbind(score(cur, "A current default"), score(his, "B span 0.5 fixed"), score(his, "C = B minus spike row", TRUE),
            score(tm, "D current + TMM"), score(tmh, "E span 0.5 + TMM"), score(rb, "F span 0.5, robust eBayes"))
show <- sc[, 1:14]; print(show[, !vapply(show, function(z) all(is.na(z)), NA), drop = FALSE], row.names = FALSE)
if (HAS_FIG) { cat("\nFigure 2 set (|log2FC| >= 1.5 among hits) against the 33 labelled genes:\n"); print(sc[, c("spec", "fig2_extra", "fig2_missing")], row.names = FALSE) }
if (HAS_S1) cat("\nS1_of_256 = Table S1 genes that are hits in the specification; S1_dlfc = largest |S1 log2FC + coefficient|; S1_rel_fdr = largest relative gap between S1 FDR (3 digits) and adj.P.Val.\n")
his_sp <- which(his$adj < 0.05 & spike)
say("A3", "spike-in row among the span-0.5 hits", his$sym[his_sp], "| coefficient", round(his$lfc[his_sp], 2), "(positive = printed 'down in fit', so removing it leaves 145 / 111)")
if (HAS_S1) say("A3", "set of C equals the 256 genes of Table S1", setequal(his$sym[his$adj < 0.05 & !spike], S1$gene))
i <- match("TOX2", sym); say("A3", "TOX2 (Table 3, hypertension row) adj p: A, B, D, E", signif(c(cur$adj[i], his$adj[i], tm$adj[i], tmh$adj[i]), 3), "| reads", tot[i], "| samples", det[i])
if (HAS_ENT) say("A3", "table entries not significant: D", unique(ent$gene[tm$adj[match(ent$gene, sym)] >= 0.05]), "| E", unique(ent$gene[tmh$adj[match(ent$gene, sym)] >= 0.05]), "| F", unique(ent$gene[rb$adj[match(ent$gene, sym)] >= 0.05]))
say("A3", "max |voom E - deposited matrix|: A (no TMM), D (TMM)", format(max(abs(cur$v$E - dep)), digits = 3), format(max(abs(tm$v$E - dep)), digits = 3), "(quantile normalisation removes most of TMM from E)")
say("A3", "TMM factors, range", round(range(calcNormFactors(DGEList(Y))$samples$norm.factors), 3))
dir.create("results", showWarnings = FALSE)
hh <- which(his$adj < 0.05 & !spike)
write.csv(data.frame(gene = his$sym[hh], coef_3way = round(his$lfc[hh], 6), log2FC_printed_convention = round(-his$lfc[hh], 6), adj_p = signif(his$adj[hh], 4),
                     total_reads = tot[hh], samples_detected = det[hh])[order(his$adj[hh]), ], "results/reconstructed_256_genes.csv", row.names = FALSE)

cat("\nHit counts by variant of the shipped analysis (3-way coefficient):\n")
vr <- function(h) c(
  all_rows = nhit(pipe(Y, X3, hist = h)), spikes_removed_before_fit = nhit(pipe(Y[!spike, ], X3, hist = h)),
  zero_rows_removed = nhit(pipe(Y[tot > 0, ], X3, hist = h)), robust_eBayes = nhit(pipe(Y, X3, hist = h, robust = TRUE)),
  trend_eBayes = nhit(pipe(Y, X3, hist = h, trend = TRUE)), no_quantile = nhit(pipe(Y, X3, hist = h, quant = FALSE)), TMM = nhit(pipe(Y, X3, hist = h, tmm = TRUE)))
print(rbind(current_default = vr(FALSE), span_0.5_fixed = vr(TRUE)))

## ------------------------------------------------------------------------------------------------
sec("C1. Tested coefficient and the additive model")
say("C1", "design columns", ncol(X3), "| rank", qr(X3)$rank, "| residual df", n - qr(X3)$rank)
say("C1", "tested column (script: coef = ncol(design))", colnames(X3)[LAST])
say("C1", "script lines using coef = ncol(design)", sum(grepl("coef *= *ncol[(]design[)]", readLines("data/ScriptR_RNAseq_limma_FitUnfit.R", warn = FALSE))))
g <- match("SCO2", sym)
cell <- interaction(Fit, sex)
slope <- sapply(levels(cell), function(k) { s <- cell == k; unname(coef(lm(cur$v$E[g, s] ~ PHV[s], weights = cur$v$weights[g, s]))[2]) })
d3 <- (slope["Unfit_1.female_1"] - slope["Unfit_1.male_0"]) - (slope["Fit_0.female_1"] - slope["Fit_0.male_0"])
say("C1", "SCO2: 3-way coefficient equals (unfit F - unfit M) - (fit F - fit M) PHV slopes", round(cur$lfc[g], 5), round(unname(d3), 5))
for (h in c(FALSE, TRUE)) {
  ad <- pipe(Y, Xa, coef = 2, hist = h)
  say("C1", paste0("additive model ~ Fit + sex + PHV, ", if (h) "span 0.5 fixed" else "current default"), "genes", nrow(Y), "| hits", nhit(ad), "| min adj p", round(min(ad$adj), 3),
      "| raw p < 0.05:", sum(ad$p < 0.05), paste0("(", round(100 * mean(ad$p < 0.05), 1), "%)"), "| -log10(min adj)", round(-log10(min(ad$adj)), 2))
  if (!h) ad_cur <- ad else ad_his <- ad
}
say("C1", "shipped coefficient: -log10(min adj p), current / span 0.5", round(-log10(min(cur$adj)), 2), round(-log10(min(his$adj)), 2))
if (HAS_ENT) {
  say("C1", "arrows of Tables 2-3 equal minus the sign of the 3-way coefficient (of 108), current / span 0.5",
      sum(sign(cur$lfc[match(ent$gene, sym)]) == ifelse(ent$arrow == "up", -1, 1)), sum(sign(his$lfc[match(ent$gene, sym)]) == ifelse(ent$arrow == "up", -1, 1)))
  say("C1", "table entries significant under the shipped coefficient (of 108), current / span 0.5", sum(cur$adj[match(ent$gene, sym)] < 0.05), sum(his$adj[match(ent$gene, sym)] < 0.05))
}
fm <- pipe(Y, X3, coef = 2, hist = TRUE)
say("C1", "Fit main effect of the full model (boys at PHV = 0): hits", nhit(fm), "| PHV = 0 outside observed range", !(0 >= min(PHV) & 0 <= max(PHV)))
if (HAS_ENT) {
  ug <- unique(ent$gene); im <- match(ug, sym); pd <- ifelse(ent$arrow[match(ug, ent$gene)] == "up", -1, 1)
  say("C1", "  unique table genes significant under it (of 57)", sum(fm$adj[im] < 0.05), "| of those with sign opposite to the arrow", sum(fm$adj[im] < 0.05 & sign(fm$lfc[im]) != pd))
}
hC <- his$adj < 0.05 & !spike; s6 <- hC & det >= 6
mf <- rowMeans(his$v$E[, Fit == "Fit_0"]) - rowMeans(his$v$E[, Fit == "Unfit_1"])
say("C1", "256-list genes detected in >= 6 samples", sum(s6), "| printed direction equals raw fit-minus-unfit (voom log-CPM) sign in", sum(-sign(his$lfc[s6]) == sign(mf[s6])),
    "| equals additive adjusted sign in", sum(-sign(his$lfc[s6]) == -sign(ad_his$lfc[s6])))
cand <- c("IL2RA", "SCO2", "GRB2", "MAL", "GNG10", "CREB3L3", "PPP2R5E"); ci <- match(cand, sym)
print(data.frame(gene = cand, printed = ifelse(his$lfc[ci] < 0, "up", "down"), coef_3way = round(his$lfc[ci], 2), adj_3way = round(his$adj[ci], 3),
                 additive_fit_minus_unfit = round(-ad_his$lfc[ci], 2), additive_p = round(ad_his$p[ci], 3), reads = tot[ci], samples = det[ci]), row.names = FALSE)

## ------------------------------------------------------------------------------------------------
sec("C2. Where the hits are; leverage; filtering")
H <- hat(X3, intercept = FALSE); uf <- Fit == "Unfit_1" & sex == "female_1"; fb <- Fit == "Fit_0" & sex == "male_0"
say("C2", "leverage of the 2 unfit girls", round(H[uf], 6), "| largest among the other 25", round(max(H[!uf]), 3))
a3 <- (solve(crossprod(X3)) %*% t(X3))[LAST, ]
say("C2", "share of squared weight on the 3-way coefficient: 3 fit boys, 2 unfit girls", round(sum(a3[fb]^2) / sum(a3^2), 2), round(sum(a3[uf]^2) / sum(a3^2), 2))
only_uf <- rowSums(Y[, !uf] > 0) == 0 & rowSums(Y[, uf] > 0) > 0
for (lb in c("current", "span 0.5")) {
  r <- if (lb == "current") cur else his; hit <- r$adj < 0.05
  one <- which(hit & det == 1); wh <- apply(Y[one, , drop = FALSE] > 0, 1, which)
  wc <- table(factor(ifelse(uf[wh], "unfit girls", ifelse(fb[wh], "fit boys", "other")), levels = c("unfit girls", "fit boys", "other")))
  say("C2", paste0(lb, ": hits"), sum(hit), "| detected in <= 5 samples", sum(det[hit] <= 5), "| median total reads", median(tot[hit]),
      "| reads only in the 2-child cell", sum(hit & only_uf), "| residual SD < 1e-6", sum(hit & r$sigma < 1e-6),
      "| single-sample hits (unfit girls, fit boys, other)", as.integer(wc))
}
say("C2", "rows with reads only in the 2-child cell", sum(only_uf), "| of those in one child", sum(only_uf & rowSums(Y[, uf] > 0) == 1))
keepA <- filterByExpr(DGEList(Y), design = Xa)
f3 <- pipe(Y[keepA, ], X3); f3h <- pipe(Y[keepA, ], X3, hist = TRUE); fa <- pipe(Y[keepA, ], Xa, coef = 2); fah <- pipe(Y[keepA, ], Xa, coef = 2, hist = TRUE)
say("C2", "filterByExpr (additive design) keeps", sum(keepA), "| shipped coef hits: current, span 0.5", nhit(f3), nhit(f3h), "| min adj", round(min(f3$adj), 3), round(min(f3h$adj), 3),
    "| additive hits", nhit(fa), nhit(fah), "| min adj", round(min(fa$adj), 3), round(min(fah$adj), 3))
d2 <- pipe(Y[det >= 2, ], X3, hist = TRUE); nz <- pipe(Y[tot > 0, ], X3, hist = TRUE)
say("C2", "span 0.5, detected in >= 2 samples: rows", sum(det >= 2), "hits", nhit(d2), "| zero rows removed: rows", sum(tot > 0), "hits", nhit(nz))
say("C2", "eBayes prior df / variance: all rows", round(his$e$df.prior, 2), round(his$e$s2.prior, 3), "| zero rows removed", round(nz$e$df.prior, 2), round(nz$e$s2.prior, 3))
vnq <- pipe(Y, X3, hist = TRUE, quant = FALSE)
say("C2", "span 0.5, no quantile normalisation: hits", nhit(vnq), "| distinct values in zero-count cells: with / without quantile", length(unique(round(his$v$E[Y == 0], 8))), length(unique(round(vnq$v$E[Y == 0], 8))))
say("C2", "spike-in rows with nominal p < 0.05 (of 76): shipped coef, additive (current)", sum(cur$p[spike] < 0.05), sum(ad_cur$p[spike] < 0.05), "| span 0.5", sum(his$p[spike] < 0.05), sum(ad_his$p[spike] < 0.05))
nmd <- c("CREB3L3", "PPP2R5E")
say("C2", "genes named in the Results' enrichment sentence: reads", tot[match(nmd, sym)], "| samples detected", det[match(nmd, sym)])

## ------------------------------------------------------------------------------------------------
sec("C2a. Permutations (voom refitted every time; counts of genes at BH < 0.05)")
cat("Observed: ", nhit(cur), " (current default), ", nhit(his), " (span 0.5). Schemes break real sex and maturity structure, so they approximate a null only.\n", sep = "")
fi <- as.character(Fit); sx <- as.character(sex)
pw <- function(v, s) { o <- v; for (k in unique(s)) { w <- which(s == k); o[w] <- v[w[sample.int(length(w))]] }; o }
mk <- function(ord = seq_len(n), f = fi, s = sx, p = PHV, hist = FALSE, add = FALSE, label = "")
  list(ord = ord, f = f, s = s, p = p, hist = hist, add = add, label = label)
tasks <- list()
set.seed(20261019)                                                        # P1: the audit's scheme, same seed and draw order
for (b in seq_len(NDRAW[["P1"]])) { idx <- seq_len(n); for (k in levels(sex)) { w <- which(sex == k); idx[w] <- w[sample.int(length(w))] }
  tasks[[length(tasks) + 1]] <- mk(ord = idx, add = TRUE, label = paste0("P1 within-sex expression, ", NDRAW[["P1"]], ", current")) }
set.seed(SEED)
for (b in seq_len(NDRAW[["P2"]])) tasks[[length(tasks) + 1]] <- mk(ord = sample.int(n), label = paste0("P2 all columns, ", NDRAW[["P2"]], ", current"))
for (b in seq_len(NDRAW[["P3"]])) { idx <- sample.int(n); tasks[[length(tasks) + 1]] <- mk(f = fi[idx], s = sx[idx], p = PHV[idx], label = paste0("P3 joint covariate rows, ", NDRAW[["P3"]], ", current")) }
for (b in seq_len(NDRAW[["P4"]])) { f2 <- pw(fi, sx); for (h in c(FALSE, TRUE)) tasks[[length(tasks) + 1]] <- mk(f = f2, hist = h, label = paste0("P4 within-sex Fit labels, ", NDRAW[["P4"]], ", ", if (h) "span 0.5" else "current")) }
for (b in seq_len(NDRAW[["P5"]])) { id2 <- pw(seq_len(n), sx); for (h in c(FALSE, TRUE)) tasks[[length(tasks) + 1]] <- mk(ord = id2, hist = h, label = paste0("P5 within-sex expression, ", NDRAW[["P5"]], ", ", if (h) "span 0.5" else "current")) }
girls <- which(sx == "female_1")
for (pr in combn(girls, 2, simplify = FALSE)) { f2 <- fi; f2[girls] <- "Fit_0"; f2[pr] <- "Unfit_1"
  tasks[[length(tasks) + 1]] <- mk(f = f2, hist = TRUE, label = "P6 all 55 choices of the unfit-girl pair, span 0.5") }
one <- function(j) {
  X <- model.matrix(~ f * s * p, data = list(f = factor(j$f, levels = c("Fit_0", "Unfit_1")), s = factor(j$s, levels = c("male_0", "female_1")), p = j$p))
  v <- vm(Y[, j$ord], X, j$hist)
  out <- c(hits = sum(p.adjust(eBayes(lmFit(v, X))$p.value[, ncol(X)], "BH") < 0.05), add = NA)
  if (j$add) { Xa2 <- model.matrix(~ f + s + p, data = list(f = factor(j$f, levels = c("Fit_0", "Unfit_1")), s = factor(j$s, levels = c("male_0", "female_1")), p = j$p))
    va <- vm(Y[, j$ord], Xa2, j$hist); out["add"] <- sum(p.adjust(eBayes(lmFit(va, Xa2))$p.value[, 2], "BH") < 0.05) }
  out
}
cat("permutation fits:", length(tasks), "\n")
tp <- Sys.time()
if (NC > 1) {
  cl <- makeCluster(NC); libp <- .libPaths()
  clusterExport(cl, c("libp", "Y", "vm", "HAS_ADAPT", "n"))
  invisible(clusterEvalQ(cl, {.libPaths(libp); suppressWarnings(suppressPackageStartupMessages(library(limma)))}))
  RES <- do.call(rbind, parLapplyLB(cl, tasks, one)); stopCluster(cl)
} else RES <- do.call(rbind, lapply(tasks, one))
say("C2a", "permutation wall time (minutes)", round(as.numeric(difftime(Sys.time(), tp, units = "mins")), 1))
lab <- vapply(tasks, function(j) j$label, "")
summ <- function(x, obs) sprintf("median %.1f, IQR %.0f-%.0f, range %.0f-%.0f | >= observed (%d): %d of %d, P %.3f", median(x), quantile(x, .25), quantile(x, .75), min(x), max(x), obs, sum(x >= obs), length(x), mean(x >= obs))
for (k in unique(lab)) {
  x <- RES[lab == k, "hits"]; obs <- if (grepl("span 0.5", k)) nhit(his) else nhit(cur)
  if (grepl("^P6", k)) cat("[C2a]", k, ": median", median(x), "range", min(x), "-", max(x), "| observed pair", obs, "rank", rank(-x, ties.method = "min")[which(sapply(combn(girls, 2, simplify = FALSE), function(p) setequal(p, which(uf))))], "of 55\n")
  else cat("[C2a] ", k, ": ", summ(x, obs), "\n", sep = "")
}
xa <- RES[grepl("^P1", lab), "add"]
say("C2a", "P1: additive model on the same 30 permuted data sets, runs with >= 1 hit", sum(xa > 0), paste0("of ", NDRAW[["P1"]], " | median"), median(xa))
say("C2a", "P1: median", median(RES[grepl("^P1", lab), "hits"]), paste0("| runs reaching the observed ", nhit(cur)), sum(RES[grepl("^P1", lab), "hits"] >= nhit(cur)))

## ------------------------------------------------------------------------------------------------
sec("C3. 273 against 256")
for (h in c(FALSE, TRUE)) { r <- if (h) his else cur
  hit <- r$adj < 0.05
  say("C3", if (h) "span 0.5 fixed" else "current default", "hits", sum(hit), "| coefficient < 0 / > 0", sum(hit & r$lfc < 0), sum(hit & r$lfc > 0), "| log2FC range (printed sign)", round(range(-r$lfc[hit]), 2),
      "| |log2FC| >= 1.5:", sum(hit & abs(r$lfc) >= 1.5), "| |log2FC| >= log2(1.5):", sum(hit & abs(r$lfc) >= log2(1.5))) }
say("C3", "span 0.5, spike row removed from the list", sum(hC), "| coefficient < 0 / > 0", sum(hC & his$lfc < 0), sum(hC & his$lfc > 0), "| range", round(range(-his$lfc[hC]), 2), "| |log2FC| >= 1.5:", sum(hC & abs(his$lfc) >= 1.5))
say("C3", "current + TMM", nhit(tm), nsplit(tm), "| range", round(range(-tm$lfc[tm$adj < 0.05]), 2))
say("C3", "genes shared: current vs current + TMM; span 0.5 minus spike vs current; vs current + TMM", sum(cur$adj < 0.05 & tm$adj < 0.05), sum(hC & cur$adj < 0.05), sum(hC & tm$adj < 0.05))
if (HAS_S1) {
  say("C3", "span 0.5 minus spike vs Table S1: genes in both, only here, only in S1", sum(sym[hC] %in% S1$gene), sum(!sym[hC] %in% S1$gene), sum(!S1$gene %in% sym[hC]))
  say("C3", "current + TMM vs Table S1: genes in both, only here, only in S1", sum(sym[tm$adj < 0.05] %in% S1$gene), sum(!sym[tm$adj < 0.05] %in% S1$gene), sum(!S1$gene %in% sym[tm$adj < 0.05]))
  say("C3", "current default vs Table S1: genes in both, only here, only in S1", sum(sym[cur$adj < 0.05] %in% S1$gene), sum(!sym[cur$adj < 0.05] %in% S1$gene), sum(!S1$gene %in% sym[cur$adj < 0.05]))
  say("C3", "distinct log2FC values among the 256 in Table S1", length(unique(S1$log2FC)), "| distinct FDR values", length(unique(S1$FDR)))
}

## ------------------------------------------------------------------------------------------------
sec("C4-C6. Table 1")
tt2 <- function(m1, s1, n1, m2, s2, n2, var.equal) {
  d <- m1 - m2
  if (var.equal) { sp <- sqrt(((n1 - 1) * s1^2 + (n2 - 1) * s2^2) / (n1 + n2 - 2)); se <- sp * sqrt(1 / n1 + 1 / n2); df <- n1 + n2 - 2
  } else { se <- sqrt(s1^2 / n1 + s2^2 / n2); df <- se^4 / ((s1^2 / n1)^2 / (n1 - 1) + (s2^2 / n2)^2 / (n2 - 1)) }
  2 * pt(-abs(d / se), df)
}
pf <- PHV[Fit == "Fit_0"]; pu <- PHV[Fit == "Unfit_1"]
say("C4", "printed: PHV offset fit -1.76 (0.80) n = 12, unfit -2.47 (0.96) n = 15, p = 0.50")
say("C4", "from printed statistics: Student, Welch", round(tt2(-1.76, .80, 12, -2.47, .96, 15, TRUE), 3), round(tt2(-1.76, .80, 12, -2.47, .96, 15, FALSE), 3))
say("C4", "from deposited per-child PHV: Student, Welch, Mann-Whitney", round(t.test(pf, pu, var.equal = TRUE)$p.value, 3), round(t.test(pf, pu)$p.value, 3), round(suppressWarnings(wilcox.test(pf, pu))$p.value, 3))
gr <- expand.grid(n1 = 10:12, dm1 = c(-.005, .005), ds1 = c(-.005, .005), dm2 = c(-.005, .005), ds2 = c(-.005, .005)); gr$n2 <- 25 - gr$n1
res <- t(apply(gr, 1, function(g) { m1 <- 1.79 + g[["dm1"]]; s1 <- .62 + g[["ds1"]]; m2 <- 2.25 + g[["dm2"]]; s2 <- 1.33 + g[["ds2"]]; n1 <- g[["n1"]]; n2 <- g[["n2"]]
  m <- (n1 * m1 + n2 * m2) / 25; ss <- (n1 - 1) * s1^2 + (n2 - 1) * s2^2 + n1 * (m1 - m)^2 + n2 * (m2 - m)^2
  c(m, sqrt(ss / 24), tt2(m1, s1, n1, m2, s2, n2, TRUE), tt2(m1, s1, n1, m2, s2, n2, FALSE)) }))
say("C5", "IL-6 (n = 25; group n 10-12 / 13-15; rounding corners): total mean", round(range(res[, 1]), 2), "| total SD", round(range(res[, 2]), 2), "| Student p", round(range(res[, 3]), 3), "| Welch p", round(range(res[, 4]), 3))
say("C5", "printed total 2.31 (SD 1.98), p 0.26; printed total mean above both group means (1.79, 2.25)", 2.31 > max(1.79, 2.25), "| printed SD inside implied range", 1.98 >= min(res[, 2]) && 1.98 <= max(res[, 2]))
if (HAS_TXT) {
  sent <- strsplit(art, "(?<=[.]) (?=[A-Z])", perl = TRUE)[[1]]
  il <- sent[grepl("IL-6", sent) & grepl("lower", sent)]
  say("C5", "sentences with IL-6 and 'lower' in the article text", length(il))
}
bm <- matrix(c(3L, 9L, 3L, 12L), 2)
say("C6", "printed: BMI group counts 3 of 12 fit, 3 of 15 unfit; p = 0.56")
say("C6", "Pearson, Yates, Fisher", round(suppressWarnings(chisq.test(bm, correct = FALSE))$p.value, 3), round(suppressWarnings(chisq.test(bm))$p.value, 3), round(fisher.test(bm)$p.value, 3))
if (HAS_TAB) say("C6", "Table 1 BMI-group row labels in the author manuscript", trimws(sub("[|].*", "", tabs[grepl("^(Overweight|Obesity) [|]", tabs)])), "(the audit describes one combined label in the journal version)")
if (HAS_TXT) say("C6", "Methods: 'EASE score < 0.05' present", grepl("EASE score < 0.05", art, fixed = TRUE), "| 'background' present", grepl("background", art, ignore.case = TRUE), "| any adjustment mentioned in the EASE sentences", any(grepl("Benjamini|adjust|FDR|Bonferroni", sent[grepl("EASE", sent)])))

## ------------------------------------------------------------------------------------------------
sec("C7. SCO2, SPDYC, IL2RA")
rk <- function(r, label, drop = FALSE) {
  hit <- r$adj < 0.05; if (drop) hit <- hit & !grepl("^RNA_SPIKE", r$sym)
  w <- which(hit); pr <- -r$lfc[w]; g <- r$sym[w]; a <- function(x) match(x, g)
  cat(sprintf("[C7] %-24s SPDYC %.2f | SCO2 %.2f | IL2RA %.2f | SCO2 rank among up (of %d hits) %d, by |log2FC| %d | IL2RA from bottom %d | genes above SCO2 on the up side: %s\n",
              label, pr[a("SPDYC")], pr[a("SCO2")], pr[a("IL2RA")], length(g), rank(-pr)[a("SCO2")], rank(-abs(pr))[a("SCO2")], rank(pr)[a("IL2RA")], paste(g[pr > pr[a("SCO2")]], collapse = ",")))
  cat(sprintf("[C7]   fold change >= 1.5 (|log2FC| >= log2 1.5): %d of %d | |log2FC| >= 1.5: %d\n", sum(abs(pr) >= log2(1.5)), length(g), sum(abs(pr) >= 1.5)))
}
rk(cur, "current default"); rk(his, "span 0.5, no spike", TRUE); rk(tm, "current + TMM")
w27 <- which(hC & det >= 27)
say("C7", "among the 256 genes detected in all 27 samples (n)", length(w27), "| highest", sym[w27][which.max(-his$lfc[w27])], round(max(-his$lfc[w27]), 2), "| lowest", sym[w27][which.min(-his$lfc[w27])], round(min(-his$lfc[w27]), 2))
say("C7", "reads / samples detected: SPDYC, SCO2, IL2RA", tot[match(c("SPDYC", "SCO2", "IL2RA"), sym)], det[match(c("SPDYC", "SCO2", "IL2RA"), sym)])
if (HAS_TAB && HAS_TXT) {
  cap2 <- tabs[grep("^33 top-genes", tabs)]; note3 <- tabs[grep("^Bold genes", tabs)]
  say("C7", "Figure 2 caption says 'fold change' / mentions log2", grepl("fold change", cap2), grepl("log2", cap2), "| Table 3 note mentions log2FC", grepl("log2FC", note3), "| Results mention log2FC ranged", grepl("log2FC ranged", art))
}
if (HAS_TXT) say("C7", "Discussion names SCO2 and IL2RA as highest and lowest", grepl("SCO2 and IL2RA genes that showed the highest and lowest", art, fixed = TRUE))

## ------------------------------------------------------------------------------------------------
sec("C8. Methods and what the analysis chose")
if (HAS_TXT) {
  cnts <- function(w) lengths(regmatches(art, gregexpr(w, art, ignore.case = TRUE)))
  terms <- c("voom", "interaction", "spike", "ERCC", "filter", "TMM", "edgeR", "calcNormFactors", "background", "limma version", "R version", "sessionInfo")
  cat("[C8] occurrences in the author manuscript text:", paste(terms, sapply(terms, cnts), collapse = " | "), "\n")
  cat("[C8] occurrences of 'version':", cnts("version"), "\n")
}
say("C8", "rows tested", nrow(Y), "| spike-in rows", sum(spike), "| all-zero rows", sum(tot == 0), "| rows after removing spike-ins and all-zero rows", sum(!spike & tot > 0))

## ------------------------------------------------------------------------------------------------
sec("C9-C10. The deposit")
sc <- readLines("data/ScriptR_RNAseq_limma_FitUnfit.R", warn = FALSE)
rd <- sub('.*read.table[(]"([^"]+)".*', "\\1", grep("read.table[(]", sc, value = TRUE)); wr <- sub('.*write.table[(][^"]*"([^"]+)".*', "\\1", grep("write.table[(]", sc, value = TRUE))
dp <- sort(dep_files)
say("C9", "script reads", rd, "| present in the deposit", file.exists(file.path("data", rd)))
say("C9", "script writes", wr, "| present in the deposit", file.exists(file.path("data", wr)))
say("C9", "deposit holds", dp)
say("C9", "library calls", trimws(grep("^library", sc, value = TRUE)), "| sessionInfo in script", any(grepl("sessionInfo", sc)), "| edgeR Depends", gsub("\n", " ", packageDescription("edgeR")$Depends))
say("C9", "script uses vQuant/voomQuantiles output equal to deposited normalised matrix (section 2): max diff", format(max(abs(cur$v$E - dep)), digits = 3))
say("C9", "STRTprep pipeline (conf.yaml, licence, pinned version)", "not part of the OSF deposit; not checked here")
say("C10", "files in the study deposit", length(dp), "| README / licence / codebook / dictionary file names", sum(grepl("readme|licen|codebook|dictionary", dp, ignore.case = TRUE)),
    "| phenotype or SPSS files (.sav .sps .csv .xls*)", sum(grepl("[.](sav|sps|csv|xlsx?)$", dp, ignore.case = TRUE)))
say("C10", "deposit contains: Table 1 data, cytokines, enrichment input/output, figure code, Table S1", "none of these (only the limma step and its inputs)")

## ------------------------------------------------------------------------------------------------
sec("C11. Sample codes (counts only, no code or per-child value printed)")
hdr <- scan("data/voomQuantiles_normalized.txt.txt", what = "", nlines = 1, quiet = TRUE)
codes <- rownames(cd)
say("C11", "distinct codes in the sample table", length(unique(codes)), "| same codes in the headers of the counts and the normalised matrix", setequal(colnames(Y), codes), setequal(hdr, codes),
    "| code occurrences across the three files", length(codes) + sum(colnames(Y) %in% codes) + sum(hdr %in% codes))
say("C11", "distinct numeric stems", length(unique(sub("^[A-Z]+([0-9]+).*", "\\1", codes))))
once <- function(...) { k <- paste(...); sum(!duplicated(k) & !duplicated(k, fromLast = TRUE)) }
say("C11", "children unique on: sex", once(sex), "| group", once(Fit), "| sex + group", once(sex, Fit), "| offset", once(PHV), "| sex + offset", once(sex, PHV), "| sex + group + offset", once(sex, Fit, PHV))
say("C11", "offset rounded to half years: unique on sex + group + offset", once(sex, Fit, round(PHV * 2) / 2), "| whole years", once(sex, Fit, round(PHV)), "| sex + whole-year offset", once(sex, round(PHV)))
PHVb <- round(PHV * 2) / 2; Xb <- model.matrix(~ Fit * sex * PHVb); Xab <- model.matrix(~ Fit + sex + PHVb)
rbn <- pipe(Y, Xb); rab <- pipe(Y, Xab, coef = 2)
say("C11", "half-year offset refit, current default: shipped coefficient hits", nhit(rbn), "| shared with the 273", sum(rbn$adj < 0.05 & cur$adj < 0.05), "| additive hits", nhit(rab))

## ------------------------------------------------------------------------------------------------
sec("Session")
cat("total run time (minutes):", round(as.numeric(difftime(Sys.time(), T0, units = "mins")), 1), "\n\n")
print(sessionInfo())
