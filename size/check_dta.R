d <- haven::read_dta("C:/Users/thavr/Dropbox/Study/Other/Agents/Joint/web_meta/site/size/size.dta")
cat("nrow:", nrow(d), "ncol:", ncol(d), "\n")
cat(paste(names(d), collapse=", "), "\n")
