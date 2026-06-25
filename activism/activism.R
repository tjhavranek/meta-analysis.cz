###
# Value creation by shareholder activism: A meta-analysis
# Authors: Josef Bajzik - the original code was developed by Simona Malovana and is available for download here: https://simonamalovana.org/research-papers
####

## WORKSAPCE
# ==============================
# remove the list of variables from previous session:
rm(list = ls())

# set library
#.libPaths("N:/R_LIBRARY") # ZR directory
#.libPaths("C:/Users/cnb/Desktop/Skola/Shareholder_activism/R/R_Library_4.2")
.libPaths("C:/Users/cnb/Desktop/Skola/Shareholder_activism/R/R_Library")

# load required packages
#install.packages(c("tidytext", "tidyselect", "tidygraph", "zip", "DescTools", "xtable",
#                "openxlsx", "miceadds", "vrtest", "plm", "ggplot2", "labeling", "BMS", "foreign",
#                 "meta", "PEIP", "stargazer","DescTools", "TAM", "Rmisc", "gtools", "estimatr",
#                 "ggcorrplot", "modi", "RStata", "diagis", "bayesm", "data.table", "lmtest",
#                 "fanplot", "foreign", "MASS", "purrr", "dendextend", "stringr", "phonTools",
#                 "Hmisc", "reshape2", "stargazer", "cowplot", "corrplot", "dplyr", "cluster",
#                 "viridis", "gtable", "gridExtra", "grid", "lattice", "sjPlot", "fpc", "scales",
#                 "devtools", "moments", "LowRankQP", "multcomp",
#                 "lfe","fwildclusterboot","plyr","corrplot","e1071",
#                 "RColorBrewer",'devtools','BMS','openxlsx'.'reshape','reldist'))
libs <- c("tidyverse", "tidytext", "tidyselect", "tidygraph", "zip", "DescTools", "xtable",
          "openxlsx", "miceadds", "vrtest", "plm", "ggplot2", "labeling", "BMS", "foreign",
          "meta", "PEIP", "stargazer","DescTools", "TAM", "Rmisc", "gtools", "estimatr",
          "ggcorrplot", "modi", "RStata", "diagis", "bayesm", "data.table", "lmtest",
          "fanplot", "foreign", "MASS", "purrr", "dendextend", "stringr", "phonTools",
          "Hmisc", "reshape2", "stargazer", "cowplot", "corrplot", "dplyr", "cluster",
          "viridis", "gtable", "gridExtra", "grid", "lattice", "sjPlot", "fpc", "scales",
          "devtools", "moments", "LowRankQP", "multcomp",
          "lfe","fwildclusterboot","plyr","corrplot","e1071",
          "RColorBrewer",'devtools','BMS','openxlsx','reshape','reldist')
lapply(libs, require, character.only = T)

# set WDs
currentDir <- dirname(rstudioapi::getSourceEditorContext()$path)
currentDir_data <- "C:/Users/cnb/Desktop/Skola/Shareholder_activism/R"

currentDir_output <- paste(currentDir, "/output", sep="")
currentDir_output_BMA <- paste(currentDir, "/output/BMA", sep="")
currentDir_charts <- paste(currentDir, "/charts", sep="")
currentDir_charts_funnel <- paste(currentDir_charts, "/funnel", sep="")
currentDir_charts_bma <- paste(currentDir, "/charts/bma", sep="")
currentDir_charts_pubbias <- paste(currentDir, "/charts/pubbias", sep="")
currentDir_charts_density <- paste(currentDir, "/charts/density", sep="")
currentDir_fcn <- paste(currentDir, "/functions", sep="")
currentDir_ws <- paste(currentDir, "/workspace", sep="")

# load functions
setwd(currentDir_fcn)
source("calculateSE_JB.R")
source("kinked2.R")
source("pubbias_selection.R")
source("publication_bias3.R")
source("stem_method.R")

pubbias_selection( paste(currentDir_fcn, "/pubbias_ak", sep=""))

saveToPDF <- function(...) {
  d = dev.copy(pdf,...)
  dev.off(d)
}

saveToPNG <- function(...) {
  d = dev.copy(png,...)
  dev.off(d)
}
# ==============================

## LOAD DATA
# ==============================
library(openxlsx)
setwd(currentDir_data)
data <- read.xlsx("data_v14.xlsx", startRow=2) 
#View(data)
# ==============================

## PRELIMINARIES
# ==============================

# DELETE COLUMN THAT ARE NOT NEEDED
data[, "Delete" == names(data)] <- NULL

###Data preparation
data$Estimate <- NULL
data$se <- NULL

## create indicator variables for summary statistics
data$publid <- paste(data$Title, data$Authors, data$PubYear, data$Journal)
data$rowid <- paste(data$Title, data$Authors, data$PubYear, 
                    data$Elasticity, data$se, data$tstats, data$pvalue)

## CALCULATE SE FROM P-VALUE
# zero p-value 
data$pvalue[which(data$pvalue==0)] <- 0.0004 
data$pvalue[which(data$pvalue==1)] <- 0.9999 

data$elasticity <- data$Estim_adj
data$se_estim <- NA

# Calculate se from p-value
elasticity <- as.numeric(data$elasticity[which(is.na(data$Se_adj)==T & is.na(data$pvalue)==F)])
value <- as.numeric(data$pvalue[which(is.na(data$Se_adj)==T & is.na(data$pvalue)==F)]) 
obs <- as.numeric(data$TotalObs[which(is.na(data$Se_adj)==T & is.na(data$pvalue)==F)])
data$se_estim[which(is.na(data$Se_adj)==T & is.na(data$pvalue)==F)] <- 
  calculateSE(value, elasticity, type="pvalue", obs)

# combine and adjust se to get final value for analysis
data$se_all <- data$Se_adj
data$se_all[which(is.na(data$Se_adj)==T)] <- data$se_estim[which(is.na(data$Se_adj)==T)]
#View(data)

## WINSORIZATION

# store nonwinsorized data
data_nonwins <- data
data$elasticity_adj <- data$elasticity
data$se_adj <- data$se_all

# winsorize (1% from each side for both - se and elasticity)
#install.packages("DescTools")
library("DescTools")
data[, "elasticity_adjw"] <- Winsorize(data[, "elasticity_adj"], probs = c(0.01, 0.99), na.rm=T)
data[, "se_adjw"] <- Winsorize(data[, "se_adj"], probs = c(0.01, 0.99), na.rm=T) 

## CALCULATE WEIGHTS - w2 = precision
# weight 1: the inverse of the number of estimates reported per study
data$w1 <- NA
for (k in unique(data$ArticleNo)){
  estimpos <- which(data$ArticleNo==k)
  data$w1[estimpos] <- 1/length(estimpos)
}

# weight 2: the inverse of the standard error
data$w2 <- 1/data$se_adjw
# ==============================

## GROUPS of VARIABLES
# ==============================
data$EventWindow <- NA
data$EventWindow[which(data$"0_0"==1)] <- "The_Day"
data$EventWindow[which(data$"-1_0"==1)] <- "Surrounding"
data$EventWindow[which(data$"0_1"==1)] <- "Surrounding"
data$EventWindow[which(data$"-1_1"==1)] <- "Surrounding"
data$EventWindow[which(data$"-3_3"==1)] <- "One_Week"
data$EventWindow[which(data$"-5_5"==1)] <- "Two_Weeks"
data$EventWindow[which(data$"-10_10"==1)] <- "Two_Weeks"
data$EventWindow[which(data$"-20_20"==1)] <- "One_Month"
data$EventWindow[which(data$"-3_0"==1)] <- "Surrounding"
data$EventWindow[which(data$"0_3"==1)] <- "Surrounding"
data$EventWindow[which(data$"-5_0"==1)] <- "One_Week"
data$EventWindow[which(data$"0_5"==1)] <- "One_Week"
data$EventWindow[which(data$"-10_0"==1)] <- "Two_Weeks"
data$EventWindow[which(data$"0_10"==1)] <- "Two_Weeks"
data$EventWindow[which(data$"-20_0"==1)] <- "One_Month"
data$EventWindow[which(data$"0_20"==1)] <- "One_Month"
table(data$EventWindow)
data$EventWindow <- as.factor(data$EventWindow)
data$EventWindow <- factor(data$EventWindow, levels=c("The_Day","Surrounding","One_Week",
                                                      "Two_Weeks","One_Month"))

#Summary for event window_v2
EventWindow2 <- data.frame(table(data$EventWindow),round(data.frame(aggregate(data[, c("elasticity_adjw")], list(data$EventWindow), mean))[,2],3),
                           round(data.frame(aggregate(data[, c("elasticity_adjw")], list(data$EventWindow), sd))[,2],3))
stargazer(EventWindow2, summary=F)  

# Event type
data$EventType <- NA
data$EventType[which(data$First==1)] <- "First_announcement"
data$EventType[which(data$Press==1)] <- "Press_announcement"
data$EventType[which(data$Mail==1)] <- "Mailing_date"
data$EventType[which(data$Meeting==1)] <- "Meeting_date"
data$EventType[which(data$Filing==1)] <- "Filing"
data$EventType[which(data$Decision==1)] <- "Decision_date"
data$EventType[which(data$FocusList==1)] <- "Press_announcement"
data$EventType[which(data$LetterDay==1)] <- "Mailing_date"
data$EventType[which(data$ThresholdReach==1)] <- "Filing"
table(data$EventType)
data$EventType <- as.factor(data$EventType)
data$EventType <- factor(data$EventType, levels=c("First_announcement","Press_announcement","Mailing_date",
                                                  "Meeting_date","Filing","Decision_date"))

# Objective
data$Objective <- NA
data$Objective[which(data$ObjectiveAll==1)] <- "Objective_general" 
data$Objective[which(data$Performance==1)] <- "Performance_governance"
data$Objective[which(data$PerfGov==1)] <- "Performance_governance"
data$Objective[which(data$GovAll==1)] <- "Governance_general"
data$Objective[which(data$GovBoard==1)] <- "Governance_board_seats"
data$Objective[which(data$GovDefense==1)] <- "Governance_other" 
data$Objective[which(data$GovMoney==1)] <- "Governance_other"
data$Objective[which(data$GovVoting==1)] <- "Governance_other" 
data$Objective[which(data$GovOther==1)] <- "Governance_other"
data$Objective[which(data$CapStr==1)] <- "Other_objective" #ud2lat CapStr, BusSt and Other objectives
data$Objective[which(data$BusSt==1)] <- "Other_objective" 
data$Objective[which(data$Sale==1)] <- "Sale"
data$Objective[which(data$ObjOther==1)] <- "Other_objective"
table(data$Objective)
data$Objective <- as.factor(data$Objective)
data$Objective <- factor(data$Objective, levels=c("Objective_general","Performance_governance",
                                                  "Governance_general","Governance_board_seats","Governance_other",
                                                  "Sale","Other_objective"))

# Outcomes
data$Outcome <- NA
data$Outcome[which(data$Success==1)] <- "Successful"
data$Outcome[which(data$Unsuccess==1)] <- "Unsuccessful"
data$Outcome[which(data$OutcomeNA==1)] <- "Not_defined"
table(data$Outcome)
data$Outcome <- as.factor(data$Outcome)
data$Outcome <- factor(data$Outcome, levels=c("Successful","Unsuccessful","Not_defined"))

# DVestim
data$DVestim <- NA
data$DVestim[which(data$MarketM==1)] <- "Market_model"
data$DVestim[which(data$MarketAdj==1)] <- "Market_adjusted"
data$DVestim[which(data$FF==1)] <- "Other_Model" 
data$DVestim[which(data$BHAR==1)] <- "Other_Model" 
data$DVestim[which(data$Equation==1)] <- "Other_Model" 
table(data$DVestim)
data$DVestim <- as.factor(data$DVestim)
data$DVestim <- factor(data$DVestim, levels=c("Market_model","Market_adjusted",
                                              "Other_Model"))

# Sponsor
data$Sponsor <- NA
data$Sponsor[which(data$HF==1)] <- "Hedge_fund"
data$Sponsor[which(data$Calpers==1)] <- "Calpers"
data$Sponsor[which(data$Institution==1)] <- "Institutional"
data$Sponsor[which(data$InstCoal==1)] <- "Institutional"
data$Sponsor[which(data$Individual==1)] <- "Individual"
data$Sponsor[which(data$IndivCoal==1)] <- "Individual"
data$Sponsor[which(data$ActivistAll==1)] <- "Sponsor_na"
table(data$Sponsor)
data$Sponsor <- as.factor(data$Sponsor)
data$Sponsor <- factor(data$Sponsor, levels=c("Hedge_fund","Calpers","Institutional",
                                              "Individual","Sponsor_na"))

# Activism type
data$ActivismType <- NA
data$ActivismType[which(data$ActivismAll==1)] <- "All_types"
data$ActivismType[which(data$Proposal==1)] <- "Shareholder_proposal"
data$ActivismType[which(data$Negotiation==1)] <- "Direct_negotiation"
data$ActivismType[which(data$Proxy==1)] <- "Proxy_fight"
data$ActivismType[which(data$Prop_NegProxy==1)] <- "All_types"
data$ActivismType[which(data$PropNegProxy==1)] <- "All_types"
data$ActivismType[which(data$Litigation==1)] <- "Other_activism" #do other type
data$ActivismType[which(data$ActivismOther==1)] <- "Other_activism"
table(data$ActivismType)
data$ActivismType <- as.factor(data$ActivismType)
data$ActivismType <- factor(data$ActivismType, levels=c("All_types","Shareholder_proposal","Direct_negotiation", "Proxy_fight",
                                                        "Other_activism"))

# Country
data$Country <- NA
data$Country[which(data$US==1)] <- "US" 
data$Country[which(data$Germany==1)] <- "Europe" 
data$Country[which(data$Europe==1)] <- "Europe"
data$Country[which(data$Asia==1)] <- "Asia"
table(data$Country)
data$Country <- as.factor(data$Country)
data$Country <- factor(data$Country, levels=c("US","Europe","Asia"))
# ==============================

# LIST OF PUBLICATIONS 
# ==============================
# including number of observations
data$publid2 <- paste(data$Authors, " (", data$PubYear, ")", sep="")
articles <- data.frame(table(data$publid2),round(data.frame(aggregate(data[, c("elasticity_adjw")], list(data$publid2), mean))[,2],3),
                       round(data.frame(aggregate(data[, c("elasticity_adjw")], list(data$publid2), sd))[,2],3))
setwd(currentDir_output)
stargazer(articles, summary=F,rownames = F,type="text", out=paste("summary_articles.tex",sep = ""))
# ==============================

## FIGURES
# ==============================

##Basic histograms
ActivismRet_hist <- hist(data$elasticity, 
                         main="Distribution of Value Creation", 
                         xlab="Value Created by Shareholder Activism", 
                         border="red", 
                         col="red",
                         xlim=c(-20,20),ylim=c(0,200),
                         breaks=500) 
#Save histogram
setwd(currentDir_charts_funnel)
dev.copy2pdf(file=paste("ActivismRet_hist2",".pdf",sep = ""), out.type="cairo", width=7, height=3.5) 

SE_hist <- hist(data$se_all, 
                main="Histogram of Standard Errors", 
                xlab="Standarrd Errors", 
                border="blue", 
                col="green",
                xlim=c(0,20), ylim=c(0,800),
                breaks=500) 
#Save histogram
setwd(currentDir_charts_funnel)
dev.copy2pdf(file=paste("SE_hist",".pdf",sep = ""), out.type="cairo", width=3.5, height=5) 

data$tstats <- data$elasticity/data$se_all
tstats_hist <- hist(data$tstats, 
                main="Distribution of T-Statistics", 
                xlab="T-Statistic", 
                border="black", 
                col="blue",
                xlim=c(-15,15), ylim=c(0,100),
                breaks=1000)
                abline(v=1.645,col="grey",lty=2,lwd=2)
                abline(v=-1.645,col="grey",lty=2,lwd=2)
                #abline(v=1.96,col="grey",lty=2,lwd=2)
                #abline(v=2.58,col="grey",lty=2,lwd=2) 
#Save histogram
setwd(currentDir_charts_funnel)
dev.copy2pdf(file=paste("tstats_hist2",".pdf",sep = ""), out.type="cairo", width=7, height=3.5) 


# Histogram based on Sponsor type
fg_hist_Sponsor <- data %>%
  ggplot() +
  geom_histogram(aes(x = elasticity_adj, fill = Sponsor), position = "identity", alpha = 0.4, bins = 50) +
  theme_minimal() +
  xlim(-15, 15) +
  xlab("Estimate of Beta") + ylab("Frequency") +
  theme(axis.text = element_text(size = 12),
        text = element_text(size = 12),
        legend.text = element_text(size = 12),
        legend.title = element_blank(), legend.position="bottom") +
  scale_fill_viridis_d(alpha = 1, begin =0, end = 1, direction = 1, option = "D", aesthetics = "fill")  +
  geom_vline(xintercept = median(data$elasticity_adj[which(data$Sponsor=="Hedge_fund")]), 
             color = viridis(5)[1], size = 1)  + 
  geom_vline(xintercept = median(data$elasticity_adj[which(data$Sponsor=="Calpers")]), 
             color = viridis(5)[2], size = 1)  + 
  geom_vline(xintercept = median(data$elasticity_adj[which(data$Sponsor=="Institutional")]), 
             color = viridis(5)[3], size = 1) +
  geom_vline(xintercept = median(data$elasticity_adj[which(data$Sponsor=="Individual")]), 
             color = viridis(5)[4], size = 1)  + 
  geom_vline(xintercept = median(data$elasticity_adj[which(data$Sponsor=="Activist_na")]), 
             color = viridis(5)[5], size = 1)
#Save histogram
setwd(currentDir_charts_funnel)
print(fg_hist_Sponsor)
dev.copy2pdf(file=paste("fg_hist_Sponsor",".pdf",sep = ""), out.type="cairo", width=3.5, height=5) 

#Basic scatter plot
data_scatter <- data.frame(aggregate(data[, c("Midyear")], list(data$ArticleNo), mean),aggregate(data[, c("elasticity_adjw")], list(data$ArticleNo), mean))
#View(data_scatter)

fg_scatter <- 
  ggplot(data=data_scatter,aes(x = x, y = x.1))+ 
  geom_smooth(method = lm, se = T, fullrange = TRUE) + 
  geom_point(alpha = 0.6, size = 1) + 
  theme_minimal() +
  coord_cartesian(ylim=c(-5,10))  + 
  xlab("Midyear of Data") + ylab("Mean Value Creation per Study in %") + 
  theme(axis.text = element_text(size = 18), 
        text = element_text(size = 18), 
        legend.text = element_text(size = 18), 
        legend.title = element_blank(), 
        legend.position="bottom") + 
  guides(shape = guide_legend(override.aes = list(size = 5, alpha = 1),nrow=2, byrow=T),
         fill = guide_legend(override.aes = list(size = 5, alpha = 1),nrow=2, byrow=T),
         color = guide_legend(override.aes = list(size = 5, alpha = 1),nrow=2, byrow=T)) +
  scale_colour_viridis_d(option = "viridis") + 
  scale_fill_viridis_d(option = "viridis")

# Boxplot plain 
sub_bp <- data.frame(melt(data[,c("elasticity_adjw","publid2")], id="publid2"))

setwd(currentDir_charts_funnel)
fg_boxplot <- ggplot(sub_bp, aes(x = publid2, y = value)) + 
  geom_boxplot(lwd = 0.25, color = c(brewer.pal(11, "RdBu"))[11],fill=c(brewer.pal(11, "RdBu"))[9]) + 
  coord_flip() + 
  theme_minimal() + 
  geom_hline(yintercept = mean(data$elasticity_adjw), color=c(brewer.pal(11, "RdBu"))[2])+
  xlab("") + ylab("Estimate of Beta") +
  theme(axis.text = element_text(size = 12), 
        text = element_text(size = 12), 
        legend.text = element_text(size = 13), 
        legend.title = element_blank(), legend.position="bottom",
        legend.spacing.x = unit(0.5, 'cm')) 

# Boxplot based on Sponsor types
sub_bpAT <- data.frame(melt(data[,c("Sponsor","publid2")], id="publid2"))
sub_bp_all <- cbind(sub_bp, sub_bpAT$value)
colnames(sub_bp_all) <- c("publid2", "variable", "value", "valueAT")

sub_bp_all$valueATb <- NA
sub_bp_all$publid2_ATb <- NA
for (i in unique(sub_bp_all$publid2)){
  sub_bp_all$valueATb[which(sub_bp_all$publid2==i)] <- as.numeric(sub_bp_all$valueAT[which(sub_bp_all$publid2==i)])
  if(length(unique(sub_bp_all$valueATb[which(sub_bp_all$publid2==i)])) > 1){
    sub_bp_all$publid2_ATb[which(sub_bp_all$publid2==i)] <- paste(sub_bp_all$publid2[which(sub_bp_all$publid2==i)],
                                                                  chartr("123456", "ABCDEF", (sub_bp_all$valueATb[which(sub_bp_all$publid2==i)] - min(sub_bp_all$valueATb[which(sub_bp_all$publid2==i)]) + 1)))
  } else {
    sub_bp_all$publid2_ATb[which(sub_bp_all$publid2==i)] <- sub_bp_all$publid2[which(sub_bp_all$publid2==i)]
  }
}

sub_bp_all$publid2_ATb <- factor(sub_bp_all$publid2_ATb, levels = sort(unique(sub_bp_all$publid2_ATb), decreasing = F))
sub_bp_all$valueAT <- factor(sub_bp_all$valueAT, levels = c("Hedge_fund","Calpers","Institutional",
                                                            "Individual","Sponsor_na"))

fg_boxplot2 <- ggplot(sub_bp_all, aes(x = reorder(publid2, -data$Midyear), y = value, fill = valueAT)) + 
  geom_boxplot(lwd = 0.25) + 
  coord_flip() + 
  theme_minimal() + 
  geom_hline(yintercept = mean(data$elasticity_adjw), color=c(brewer.pal(11, "RdBu"))[2])+
  xlab("") + ylab("Value Creation in %") +
  theme(axis.text = element_text(size = 12), 
        text = element_text(size = 12), 
        legend.text = element_text(size = 15), 
        legend.title = element_blank(), legend.position="bottom",
        legend.spacing.x = unit(0.5, 'cm')) +
  scale_colour_viridis_d(option = "viridis") +
  scale_fill_viridis_d(option = "viridis") 

fg_boxplot3 <- ggplot(sub_bp_all, aes(x = reorder(publid2, -data$PubYear), y = value, fill = valueAT)) + 
  geom_boxplot(lwd = 0.25) + 
  coord_flip() + 
  theme_minimal() + 
  geom_hline(yintercept = mean(data$elasticity_adjw), color=c(brewer.pal(11, "RdBu"))[2])+
  xlab("") + ylab("Value Creation in %") +
  theme(axis.text = element_text(size = 12), 
        text = element_text(size = 12), 
        legend.text = element_text(size = 15), 
        legend.title = element_blank(), legend.position="bottom",
        legend.spacing.x = unit(0.5, 'cm')) +
  scale_colour_viridis_d(option = "viridis") +
  scale_fill_viridis_d(option = "viridis") 

#Save scatter plot and boxplots

setwd(currentDir_charts)

print(fg_scatter)
dev.copy2pdf(file=paste("funnel_scatter",".pdf",sep = ""), out.type="cairo", width=10, height=7) 

fg_boxplot
dev.copy2pdf(file=paste("boxplot_studies.pdf",sep = ""), out.type="cairo", width=11, height=15)

fg_boxplot2
dev.copy2pdf(file=paste("boxplot_studies_AT.pdf",sep = ""), out.type="cairo", width=11, height=15)

fg_boxplot3
dev.copy2pdf(file=paste("boxplot_studies_AT2.pdf",sep = ""), out.type="cairo", width=11, height=15)

# Funnel All estimates
ylab_names <- c("Precision (1/St. Error)","","")

fg_funnelAll <- 
  ggplot(data=data,aes(x = elasticity_adj, y = w2)) + 
  geom_point(alpha = 0.6, size = 0.5) + 
  theme_minimal() + 
  xlab("Value Creation in %") + ylab(ylab_names) + 
  xlim(-15, 15)+
  ylim(0, 15)+
  theme(axis.text = element_text(size = 15), 
        text = element_text(size = 15), 
        legend.text = element_text(size = 15), 
        legend.title = element_blank(), 
        legend.position="bottom") + 
  geom_vline(xintercept = median(data$elasticity_adjw), 
             color = viridis(1)[1], size = 0.5)  +
  guides(shape = guide_legend(override.aes = list(size = 5, alpha = 1),nrow=1, byrow=T),
         fill = guide_legend(override.aes = list(size = 5, alpha = 1),nrow=1, byrow=T),
         color = guide_legend(override.aes = list(size = 5, alpha = 1),nrow=1, byrow=T)) 

#
print(fg_funnelAll)
dev.copy2pdf(file=paste("funnel_All2",".pdf",sep = ""), out.type="cairo", width=7, height=5) 

#density plots
# Outcome
Outcome_dens <- data[which(data$Outcome == "Successful" | data$Outcome == "Not_defined"),]
Outcome_dens$Outcome <- as.factor(Outcome_dens$Outcome)
Outcome_dens$Outcome <- factor(Outcome_dens$Outcome, levels=c("Successful","Not_defined"))
table(Outcome_dens$Outcome) 
fg_groups <- c("Outcome")
fg_colors <- list(c(brewer.pal(11, "RdBu"))[c(2,10)]) 
fg_names <- list(c(Successful = "Successful", Not_defined = "Not_defined"))

# density plot 1
fg_dens_Outcome <- 
  ggplot() +
  geom_density(aes(x = Outcome_dens$elasticity_adjw, color = Outcome_dens[,fg_groups])) + #, linetype = "solid")) +
  theme_minimal() + 
  xlab("Value Creation in %") + ylab("Density") + 
  theme(axis.text = element_text(size = 15), 
        text = element_text(size = 15), 
        legend.text = element_text(size = 15), 
        legend.title = element_blank(), legend.position="bottom") + 
  xlim(-15, 15) +
  guides(fill = guide_legend(nrow = 1, byrow = T))

# for each group create and save density plot
setwd(currentDir_charts_density)
print(fg_dens_Outcome)
dev.copy2pdf(file=paste("density_",fg_groups,".pdf",sep = ""), out.type="cairo", width=5, height=5)

# Sponsor
Sponsor_dens <- data[which(data$Sponsor == "Hedge_fund" | data$Sponsor == "Calpers" | data$Sponsor == "Institutional"| data$Sponsor == "Individual"),]
Sponsor_dens$Sponsor <- as.factor(Sponsor_dens$Sponsor)
Sponsor_dens$Sponsor <- factor(Sponsor_dens$Sponsor, levels=c("Hedge_fund","Calpers","Institutional","Individual"))
fg_groups <- c("Sponsor")
fg_colors <- list(c(brewer.pal(11, "RdBu"))[c(2,4,8,10)])
fg_names <- list(c(Hedge_fund = "Hedge_fund", Calpers = "Calpers", Institutional = "Institutional",
                   Individual = "Individual")) 

fg_dens_Sponsor <- 
  ggplot() +
  geom_density(aes(x = Sponsor_dens$elasticity_adjw, color = Sponsor_dens[,fg_groups])) +
  theme_minimal() + 
  xlab("Value Creation in %") + ylab("Density") + 
  theme(axis.text = element_text(size = 15), 
        text = element_text(size = 15), 
        legend.text = element_text(size = 15), 
        legend.title = element_blank(), legend.position="bottom") + 
  xlim(-15, 15) +
  guides(fill = guide_legend(nrow = 2, byrow = T))

# for each group create and save density plot
setwd(currentDir_charts_density)
print(fg_dens_Sponsor)
dev.copy2pdf(file=paste("density_",fg_groups,".pdf",sep = ""), out.type="cairo", width=5, height=5) 

# Activism Type
ActivismType_dens <- data[which(data$ActivismType == "Shareholder_proposal" | data$ActivismType == "Proxy_fight"),]
ActivismType_dens$ActivismType <- as.factor(ActivismType_dens$ActivismType)
ActivismType_dens$ActivismType <- factor(ActivismType_dens$ActivismType, levels=c("Shareholder_proposal","Proxy_fight"))
fg_groups <- c("ActivismType")
fg_colors <- list(c(brewer.pal(11, "RdBu"))[c(2,10)])  
fg_names <- list(c(Shareholder_proposal = "Shareholder_proposal", Proxy_fight = "Proxy_fight")) 

fg_dens_ActivismType <- 
  ggplot() +
  geom_density(aes(x = ActivismType_dens$elasticity_adjw, color = ActivismType_dens[,fg_groups])) +
  theme_minimal() + 
  xlab("Value Creation in %") + ylab("Density") + 
  theme(axis.text = element_text(size = 15), 
        text = element_text(size = 15), 
        legend.text = element_text(size = 15), 
        legend.title = element_blank(), legend.position="bottom") + 
  xlim(-15, 15) +
  guides(fill = guide_legend(nrow = 1, byrow = T))

# for each group create and save density plot
setwd(currentDir_charts_density)
print(fg_dens_ActivismType)
dev.copy2pdf(file=paste("density_",fg_groups,".pdf",sep = ""), out.type="cairo", width=5, height=5) 

# Country
Country_dens <- data[which(data$Country == "US" | data$Country == "Europe" | data$Country == "Asia"),]
Country_dens$Country <- as.factor(Country_dens$Country)
Country_dens$Country <- factor(Country_dens$Country, levels=c("US","Europe","Asia"))
fg_groups <- c("Country")
fg_colors <- list(c(brewer.pal(11, "RdBu"))[c(2,4,10)])  
fg_names <- list(c(US = "US", Europe = "Europe", Asia = "Asia"))

fg_dens_Country <- 
  ggplot() +
  geom_density(aes(x = Country_dens$elasticity_adjw, color = Country_dens[,fg_groups])) +
  theme_minimal() + 
  xlab("Value Creation in %") + ylab("Density") + 
  theme(axis.text = element_text(size = 15), 
        text = element_text(size = 15), 
        legend.text = element_text(size = 15), 
        legend.title = element_blank(), legend.position="bottom") + 
  xlim(-15, 15) +
  guides(fill = guide_legend(nrow = 1, byrow = T))

# for each group create and save density plot
setwd(currentDir_charts_density)
print(fg_dens_Country) 
dev.copy2pdf(file=paste("density_",fg_groups,".pdf",sep = ""), out.type="cairo", width=5, height=5) 

# ==============================

## SUBSAMPLES
# ==============================
# estimate publication bias for different subsamples
subdata_EventWindow <- list()
subdata_EventWindow[[1]] <- data[which(data$EventWindow == "The_Day"),]
subdata_EventWindow[[2]] <- data[which(data$EventWindow == "Surrounding"),]
subdata_EventWindow[[3]] <- data[which(data$EventWindow == "One_Week"),]
subdata_EventWindow[[4]] <- data[which(data$EventWindow == "Two_Weeks"),]
subdata_EventWindow[[5]] <- data[which(data$EventWindow == "One_Month"),]

subdata_EventType <- list()
subdata_EventType[[1]] <- data[which(data$EventType == "First_announcement"),]
subdata_EventType[[2]] <- data[which(data$EventType == "Press_announcement"),]
subdata_EventType[[3]] <- data[which(data$EventType == "Mailing_date"),]
subdata_EventType[[4]] <- data[which(data$EventType == "Meeting_date"),]
subdata_EventType[[5]] <- data[which(data$EventType == "Filing"),]
subdata_EventType[[6]] <- data[which(data$EventType == "Decision_date"),]

subdata_Objective <- list()
subdata_Objective[[1]] <- data[which(data$Objective == "Objective_general"),]
subdata_Objective[[2]] <- data[which(data$Objective == "Performance_governance"),]
subdata_Objective[[3]] <- data[which(data$Objective == "Governance_general"),]
subdata_Objective[[4]] <- data[which(data$Objective == "Governance_board_seats"),]
subdata_Objective[[5]] <- data[which(data$Objective == "Governance_other"),]
subdata_Objective[[6]] <- data[which(data$Objective == "Sale"),]
subdata_Objective[[7]] <- data[which(data$Objective == "Other_objective"),]

subdata_Outcome <- list()
subdata_Outcome[[1]] <- data[which(data$Outcome == "Successful"),]
subdata_Outcome[[2]] <- data[which(data$Outcome == "Unsuccessful"),]
subdata_Outcome[[3]] <- data[which(data$Outcome == "Not_defined"),]

subdata_DVestim <- list()
subdata_DVestim[[1]] <- data[which(data$DVestim == "Market_model"),]
subdata_DVestim[[2]] <- data[which(data$DVestim == "Market_adjusted"),]
subdata_DVestim[[3]] <- data[which(data$DVestim == "Other_Model"),]

subdata_Sponsor <- list()
subdata_Sponsor[[1]] <-  data[which(data$Sponsor == "Hedge_fund"),]
subdata_Sponsor[[2]] <-  data[which(data$Sponsor == "Calpers"),]
subdata_Sponsor[[3]] <-  data[which(data$Sponsor == "Institutional"),]
subdata_Sponsor[[4]] <-  data[which(data$Sponsor == "Individual"),]
subdata_Sponsor[[5]] <-  data[which(data$Sponsor == "Sponsor_na"),]

subdata_ActivismType <- list()
subdata_ActivismType[[1]] <-  data[which(data$ActivismType == "All_types"),]
subdata_ActivismType[[2]] <-  data[which(data$ActivismType == "Shareholder_proposal"),]
subdata_ActivismType[[3]] <-  data[which(data$ActivismType == "Direct_negotiation"),]
subdata_ActivismType[[4]] <-  data[which(data$ActivismType == "Proxy_fight"),]
subdata_ActivismType[[5]] <-  data[which(data$ActivismType == "Other_activism"),]

subdata_Country <- list()
subdata_Country[[1]] <-  data[which(data$Country == "US"),]
subdata_Country[[2]] <-  data[which(data$Country == "Europe"),]
subdata_Country[[3]] <-  data[which(data$Country == "Asia"),]

#Overall summary

all_subgroups <- c(list(data),subdata_EventWindow,subdata_EventType,subdata_Objective,subdata_Outcome,
                   subdata_DVestim,subdata_Sponsor,subdata_ActivismType,subdata_Country)
all_subgroups_names <- c("All","The_Day","Surrounding","One_Week", "Two_Weeks", "One_Month",
                         "First_announcement","Press_announcement","Mailing_date","Meeting_date","Filing","Decision_date",
                         "Objective_general","Performance_governance","Governance_general","Governance_board_seats","Governance_other","Sale","Other_objective",
                         "Successful","Unsuccessful","Not_defined",
                         "Market_model","Market_adjusted","Other_Model",
                         "Hedge_fund","Calpers","Institutional","Individual","Sponsor_na",
                         "All_types","Shareholder_proposal","Direct_negotiation", "Proxy_fight","Other_activism",
                         "US","Europe","Asia")

sumtab <- c()
for (i in 1:length(all_subgroups)){
  tobebind <- c(#cbind(c("Type", "Nobs",  "Studies", "", "Simple average", "5%", "95%",  "", "Weighted average",  "5%", "95%")
    #NA,
    all_subgroups_names[i],
    length(all_subgroups[[i]]$elasticity_adjw),
    length(unique(all_subgroups[[i]]$publid)),
    NA, # mezera medzi obyc summary a unweighted
    round(c(mean(all_subgroups[[i]]$elasticity_adjw), 
            quantile(all_subgroups[[i]]$elasticity_adjw, 0.05),
            quantile(all_subgroups[[i]]$elasticity_adjw, 0.95)), 2),
    NA, # mezera medzi unweighted a weighted
    round(c(weighted.mean(all_subgroups[[i]]$elasticity_adjw,all_subgroups[[i]]$w1),
            wtd.quantile(all_subgroups[[i]]$elasticity_adjw, weights=all_subgroups[[i]]$w1, probs=c(.05, .95),
                         type=c('quantile'), normwt=TRUE, na.rm=TRUE)), 2))
  sumtab <- rbind(sumtab,tobebind)
}

setwd(currentDir_output)
stargazer(sumtab, summary=F,rownames = F,type="text", out=paste("summary_EventType.tex",sep = "")) 
# ==============================

## PUBLICATION BIAS
# ==============================
# load workspace
currentDir <- dirname(rstudioapi::getSourceEditorContext()$path)
currentDir_ws <- paste(currentDir, "/workspace", sep="")
currentDir_fcn <- paste(currentDir, "/functions", sep="")
currentDir_charts <- paste(currentDir, "/charts", sep="")
currentDir_charts_bma <- paste(currentDir, "/charts/bma", sep="")

setwd(currentDir_fcn)
pubbias_selection( paste(currentDir_fcn, "/pubbias_ak", sep=""))
  
round_dig <- 3 # no. of digits to round estimates and se
iter_fp <- 100000 # no. of iterations for fat-pet model
se_clustered <- T
wild_boot <- T
elasticity_name <- "elasticity_adjw"
se_name <- "se_adjw"
study_indic <- "publid"
weight1 <- "w1"
weight2 <- "w2"
model0 <- formula(paste(elasticity_name, "~", se_name))
data$instrument <- 1/sqrt(data$TotalObs)
data$tstat_estim2 <- data$elasticity_adjw/data$se_adjw
estim_models2 <- c("simpleOLS", "re", "fe", "weightedOLS1","weightedOLS2" ) 
estim_models3 <- c("stem","kinked","top10", "selection") 

# Choose data
subdata_Pubbias <- list()
subdata_Pubbias[[1]] <-  data[which(data$Outcome == "Successful"),]
subdata_Pubbias[[2]] <-  data[which(data$Outcome == "Not_defined"),]
subdata_Pubbias[[3]] <-  data[which(data$Sponsor == "Hedge_fund"),]
subdata_Pubbias[[4]] <-  data[which(data$Sponsor == "Calpers"),]
subdata_Pubbias[[5]] <-  data[which(data$Sponsor == "Institutional"),]
subdata_Pubbias[[6]] <-  data[which(data$Sponsor == "Individual"),]
subdata_Pubbias[[7]] <-  data[which(data$ActivismType == "Shareholder_proposal"),]
subdata_Pubbias[[8]] <-  data[which(data$ActivismType == "Proxy_fight"),]
subdata_Pubbias[[9]] <-  data[which(data$Country == "US"),]
subdata_Pubbias[[10]] <-  data[which(data$Country == "Europe"),]
subdata_Pubbias[[11]] <-  data[which(data$Country == "Asia"),]


# actual estimation
# set the subsamples to be estimated
mylist <- c(list(data), subdata_Pubbias)

# set the names of columns
mycolnames <- c("", "All","Successful","Result_na","Hedge_fund","Calpers","Institutional",
                "Individual","Shareholder_proposal","Proxy_fight","US","Europe","Asia")

setwd(currentDir_fcn)
source("publication_bias3.R")

# install.packages("polycor")
library(polycor)

table_pb <- c()
sum_pb <- c()
for (i in 1:length(mylist)){
  # estimation
  subdata <- mylist[[i]]
  output <- publication_bias3(mylist[[i]], elasticity_name, se_name, model0,estim_models3, study_indic, iter_fp, weight1, weight2, round_dig, se_clustered, wild_boot)
  # other statistics to the table -- no. of observations, studies and average
  other_stats <- c(nrow(mylist[[i]]),length(unique(mylist[[i]]$publid)))
  if (i == 1){
    table_pb <- cbind(table_pb,output[[1]])
    sum_pb <- cbind(sum_pb,c("Nobs.","Studies"),other_stats)
  } else{
    table_pb <- cbind(table_pb,output[[1]][,2])
    sum_pb <- cbind(sum_pb,other_stats)
  }
  print(paste(mycolnames[i+1]," done.",sep=""))
}

# rename the colnames
colnames(table_pb) <- mycolnames
colnames(sum_pb) <- mycolnames
# bind the tables
table_pb_export <- rbind(table_pb,sum_pb)

# export the table+
setwd(currentDir_output)
stargazer(table_pb_export,type="html", out=paste("All_pubbias.doc",sep = ""))
stargazer(table_pb_export,type="text", out=paste("All_pubbias.tex",sep = ""))

#Pub bias IV
#install.packages("AER")
library(AER)

#Set the subdata manually one by one
subdata <- data 
subdata <- subdata_Pubbias[[1]] 
subdata <- subdata_Pubbias[[2]] 
subdata <- subdata_Pubbias[[3]] 
subdata <- subdata_Pubbias[[4]] 
subdata <- subdata_Pubbias[[5]] 
subdata <- subdata_Pubbias[[6]] 
subdata <- subdata_Pubbias[[7]] 
subdata <- subdata_Pubbias[[8]] 
subdata <- subdata_Pubbias[[9]] 
subdata <- subdata_Pubbias[[10]] 
subdata <- subdata_Pubbias[[11]] 

IV_reg1 <- ivreg(formula = elasticity_adjw ~ se_adjw | instrument, data = subdata)
summary(IV_reg1, vcov = vcovHC(IV_reg1, cluster = c(subdata$ArticleNo)), diagnostics = TRUE)

## B. PUBLICATION BIAS -- Caliper test
# around what threshold the test is performed
tstat_thrs <- c(1.96, 1.645)  # 1.645, 1.96
# what interval around the threshold is chosen 
calip_interval <- c(0.1, 0.2, 0.3) # 0.1, 0.2, 0.3

# i. all observations
calip_collect_res <- c()
for (i in tstat_thrs){
  for (j in calip_interval){
    # calculate the binomial parameter 
    over_calip <- length(which(abs(subdata$tstat_estim2/i) > 1 & abs(subdata$tstat_estim2/i) <= (1+j)))
    under_calip <- length(which(abs(subdata$tstat_estim2/i) < 1 & abs(subdata$tstat_estim2/i) >= (1-j)))
    calip_p <- over_calip / (over_calip + under_calip)
    # data for t-test
    subdata$tstat_calip <- 0
    subdata$tstat_calip[which(abs(subdata$tstat_estim2/i) >= 1)] <- 1 # over "tstat_thrs" threshold
    calip_test_data <- subdata$tstat_calip[which(abs(subdata$tstat_estim2/i) >= (1-j) &
                                                abs(subdata$tstat_estim2/i) <= (1+j))]
    # one-sided t-test at 95% CI (lower than 0.5, 0.4, ...)
    # confint(lm(calip_test_data ~ 1), level = 0.9)
    calip_test_res <- t.test(calip_test_data, mu = calip_p, alternative = "greater")
    # collect results
    calip_collect_res <- rbind(calip_collect_res,    
                               c(round(calip_p, 3), paste("(", round(calip_test_res$conf.int[1], 3), ")", sep="")))
  }
}
calip_collect_res_all <- calip_collect_res

# report
calip_collect_res <- cbind(sort(rep(tstat_thrs,3), decreasing=T),
                           rep(calip_interval, 2),
                           calip_collect_res_all) 
setwd(currentDir_output)
stargazer(calip_collect_res, summary=F,rownames = F,type="text", out=paste("summary_Caliper.tex",sep = "")) #podle m? tu nic nen?, ale ale d? se r??o zb?hnout

# ==============================

## BMA
# ==============================

#save the data
dataBMA <- data
data <- dataBMA

#Create new varianles
# dataset time dimension
data$yearsno <- sapply(1:nrow(data), function(x) length(data$dataend_y[x]:data$datastart_y[x])) 
data$pubyear_ln <- log(as.numeric(data$PubYear) - min(as.numeric(data$PubYear)) + 1) 
data$midyear_ln <- log(data$Midyear - min(data$Midyear) + 1)
data$yearsno_ln <- log(data$yearsno)
data$totobs_ln <- log(data$TotalObs)

#Save data frames
w1 <- as.data.frame(data$w1)
w2 <- as.data.frame(data$w2)
elasticity_adjw <- as.data.frame(data$elasticity_adjw )
se_adjw <- as.data.frame(data$se_adjw)

#Generally deleted
ls(data)
data[,c("ArticleNo","Authors","Equation","Title","PubYear","Journal","publid","rowid","publid2","Published",     
        "elasticity_adj","Estim_adj","tstats","zstats","pvalue","se_all","se_adj","elasticity","se_estim","elasticity_adjw","se_adjw","Se_adj",    
        "-1_+","-1_0","-1_1","-10_0","-10_10","-3_0","-3_3","-20_+","-20_0","-20_20","-5_0","-5_5","0_0","0_1","0_10","0_3","0_20","0_5",            
        "ActivismAll","ActivismOther","Litigation","Negotiation","Prop_NegProxy","PropNegProxy","Proposal","Proxy", 
        "ActivistAll","Calpers","HF","IndivCoal","Individual","InstCoal","Institution",             
        "Asia","Europe","Germany","US",                   
        "BHAR","FF","MarketAdj","MarketM",                  
        "BusSt","CapStr","GovAll","GovBoard","GovDefense","GovMoney","GovOther","GovVoting","ObjectiveAll","ObjOther","PerfGov","Performance","Sale",                  
        "Decision","Filing","First","FocusList","LetterDay","Mail","Meeting","Press","ThresholdReach",                     
        "EventStart","EventEnd","Multiplicator","w1","w2","Event_start__end_adj",      
        "datastart_y","dataend_y","datastart_mqh","dataend_mqh","Midyear","Length","TotalObs",    
        "One_Month","Mid","Mid_neg","Mid_pos","One_Week","Surrounding","Surrounding_2",  
        "OtherEst","ScandinavianOrigin","Positive","Positive.1","tstat_calip","tstat_estim2",
        "OutcomeNA","Success","Unsuccess",
        #"EventWindow3","EventWindow4","EventWindow5","EventWindow6",
        "Sure_int","Unsure_int","instrument")] <- NULL      #pozor, Jirka chtel nechat strong!!
              
#citations adjustment
data$citation_ln <- log((data$Citations)/(2022-data$FirstYear) + 1) #O?i?t?no o prvn? rok v Google Scholaru
data$Citations <- NULL
data$FirstYear <- NULL
ls(data)

data_before_dummy <- data
#data <- data_before_dummy 

#dummies from factors
data_dummy <- data.frame(data[ , ! colnames(data) %in% "EventWindow"],       # Create dummy data
                         model.matrix( ~ EventWindow - 1, data))
data_dummy <- data.frame(data_dummy[ , ! colnames(data_dummy) %in% "EventType"],       # Create dummy data
                         model.matrix( ~ EventType - 1, data_dummy))
data_dummy <- data.frame(data_dummy[ , ! colnames(data_dummy) %in% "Objective"],       # Create dummy data
                         model.matrix( ~ Objective - 1, data_dummy))
data_dummy <- data.frame(data_dummy[ , ! colnames(data_dummy) %in% "Outcome"],       # Create dummy data
                         model.matrix( ~ Outcome - 1, data_dummy))
data_dummy <- data.frame(data_dummy[ , ! colnames(data_dummy) %in% "DVestim"],       # Create dummy data
                         model.matrix( ~ DVestim - 1, data_dummy))
data_dummy <- data.frame(data_dummy[ , ! colnames(data_dummy) %in% "Sponsor"],       # Create dummy data
                         model.matrix( ~ Sponsor - 1, data_dummy))
data_dummy <- data.frame(data_dummy[ , ! colnames(data_dummy) %in% "ActivismType"],       # Create dummy data
                         model.matrix( ~ ActivismType - 1, data_dummy))
data_dummy <- data.frame(data_dummy[ , ! colnames(data_dummy) %in% "Country"],       # Create dummy data
                         model.matrix( ~ Country - 1, data_dummy))
#check the data
#View(data)
#View(data_dummy)
data <- data_dummy
ls(data)

###BMA data creation
data <- as.data.frame(cbind(elasticity_adjw[1:1973, 1, drop=FALSE], se_adjw[1:1973, 1, drop=FALSE],data[1:1973, 1:66, drop=FALSE]))

#Rename dummies
names(data) <- c("Estimate", "SE", "Strong", "EventLength"	,	"Equally"	,	"Value"	,
                 "Group"	,	"Daily"	,	"Monthly"	,
                 "RoA"	,	"Size"	,	"Dynamic"	,	"OLS"	,	"IV"	,
                 "PanelFE"	,	"Impact"	,	"EnglishOrigin"	,	"FrenchOrigin"	,
                 "GermanOrigin"	,	"AntidirectorRights"	,	"Threshold"	,
                 "RuleOfLaw"	,	"CapGDP"	,	"HHI"	,	"After_SA"	,
                 "YearsNo"	,	"Pubyear_ln"	,	"Midyear_ln"	,	"Yearsno_ln"	,
                 "Totobs_ln"	,	"Citation_ln"	,	
                 "The_Day"	,	"Surrounding"	, "One_Week"	,	"Two_Weeks"	,	"One_Month"	,	
                 "First_Announcement"	,	"Press_Announcement"	,	"Mailing_Date"	,	"Meeting_Date"	,
                 "Filing"	,	"Decision_Date"	,	"Objective_General"	,
                 "Performance_Governance"	,	"Governance_General"	,	"Governance_Board_Seats"	, "Governance_Other",
                 "Sale"	,	"Other_Objective"	,	"Successful"	,	"Unsuccessful"	,
                 "Result_na"	,	"Market_Model"	,	"Market_Adjusted"	,	"Other_Model"	,	"Hedge_Fund"	,	"Calpers"	,
                 "Institutional"	,	"Individual"	,	"Sponsor_na"	,	"All_types"	,
                 "Shareholder_Proposal"	,	"Direct_Negotiation"	,	"Proxy_Fight"	,
                 "Other_Activism"	,	"US"	,	"Europe"	,"Asia")

data$Other_Estim <- 0
data$Other_Estim[which(data$PanelFE==1)] <- 1
data$Other_Estim[which(data$IV==1)] <- 1
data$IV <- NULL
data$PanelFE <- NULL

#data overview
mean <- sapply(data, mean, na.rm=TRUE)
sd <- sapply(data, sd, na.rm=TRUE)
table_pb <- cbind(mean,sd)
colnames(table_pb) <- c("mean","sd") 
setwd(currentDir_output)
stargazer(table_pb, summary=F,rownames = F,type="text", out=paste("summary_Mean_SD.tex",sep = ""))

#Dummy variable trap
data$The_Day <- NULL
data$Press_Announcement <- NULL
data$Objective_General <- NULL
data$Result_na <- NULL
data$Market_Model <- NULL
data$Hedge_Fund  <- NULL 
data$Shareholder_Proposal <- NULL 
data$US <- NULL
data$GermanOrigin <- NULL
data$OLS <- NULL
data$Daily <- NULL

#Finalization of the data
bayes <- data

#Correlation
M <- cor(bayes) #nefunguje ti, nem?? v?ude ??sla..
#install.packages("corrplot")
library(corrplot)
corrplot(M, method = "circle")
M[lower.tri(M, diag=TRUE)]=NA
M<-as.data.frame(as.table(M))
M<-na.omit(M)
M2<-M[order(-abs(M$Freq)),]
head(M2)

#Delete due to high correlation
bayes$Yearsno_ln <- NULL
bayes$AntidirectorRights <- NULL
bayes$Pubyear_ln <- NULL

#variable cleaning - lack of observations
#bayes <-bayes2
bayes2 <- bayes
bayes$EventLength <-NULL
bayes$Totobs_ln <-NULL
bayes$RuleOfLaw <- NULL
bayes$Strong <- NULL
bayes$Group <- NULL 
bayes$EnglishOrigin <- NULL 
bayes$FrenchOrigin <- NULL 
bayes$Midyear_ln <- NULL
bayes$RoA <- NULL
bayes$Size <- NULL
bayes$Dynamic <- NULL
bayes$Threshold <- NULL

#final data export
#install.packages("writexl")
library("writexl")
setwd(currentDir_output_BMA)
write_xlsx(bayes,"bayesdata.xlsx")

## set parameters for baseline in-sample estimation 
burn_ <- 1e6 # number of burn-in draws for the MC3 sampler 
iter_ <- 3e6 # number of iteration draws for the MC3 sampler 
nmodel_ <- 10000 # the number of best models for which information is stored 
order_PIP <- F 
mcmc_ <- "bd" # The MC3 sampler mcmc="bd" corresponds to a birth/death MCMC algogrithm.
# BASELINE PRIORS
gprior <- "UIP" # the hyperparameter on Zellner's g-prior for the regression coefficients; g="UIP" corresponds to $g=N$, the number of observations (default)
modelprior <- "dilut" # a character denoting the model prior choice

## 5. estimate BMA and store results (charts and posterior probability tables)
setwd(currentDir_charts_bma)
# par(mar = c(bottom, left, top, right)) 
par(mar=c(3,0.1,0.5,0.5))
bma_dilut <- bms(bayes, burn = burn_, iter = iter_, 
                 g = gprior, mprior = modelprior, 
                 nmodel = nmodel_, mcmc = mcmc_, user.int = F)
image(bma_dilut, cex = 0.7, xlab = "", main = "")
dev.copy2pdf(file = "bma_dilut.pdf", out.type = "cairo", width = 8, height = 8)
#
gprior <- "UIP" # the hyperparameter on Zellner's g-prior for the regression coefficients; g="UIP" corresponds to $g=N$, the number of observations (default)
modelprior <- "uniform" # a character denoting the model prior choice
bma_uniform <- bms(bayes, burn = burn_, iter = iter_, 
                   g = gprior, mprior = modelprior, 
                   nmodel = nmodel_, mcmc = mcmc_, user.int = F)
image(bma_uniform, cex = 0.7, xlab = "", main = "")
dev.copy2pdf(file = "bma_uniform.pdf", out.type = "cairo", width = 8, height = 8)
# 
gprior <- "BRIC" 
modelprior <- "random" # a character denoting the model prior choice
bma_bric <- bms(bayes, burn = burn_, iter = iter_, 
                g = gprior, mprior = modelprior, 
                nmodel = nmodel_, mcmc = mcmc_, user.int = F)
image(bma_bric, cex = 0.7, xlab = "", main = "")
dev.copy2pdf(file = "bma_bric.pdf", out.type = "cairo", width = 8, height = 8)
# 
gprior <- "HQ" 
modelprior <- "random" # a character denoting the model prior choice
bma_hq <- bms(bayes, burn = burn_, iter = iter_, 
                g = gprior, mprior = modelprior, 
                nmodel = nmodel_, mcmc = mcmc_, user.int = F)
image(bma_hq, cex = 0.7, xlab = "", main = "")
dev.copy2pdf(file = "bma_hq.pdf", out.type = "cairo", width = 8, height = 8)

# adjust output tables
bma_dilut_full <- bma_dilut
bma_uniform_full <- bma_uniform
bma_bric_full <- bma_bric
bma_hq_full <- bma_hq
bma_dilut <- data.frame(coef(bma_dilut_full, exact=T, std.coefs=F, order.by.pip = F, include.constant=T)[ ,1:3])
bma_uniform <- data.frame(coef(bma_uniform_full, exact=T, std.coefs=F, order.by.pip = F, include.constant=T)[ ,1:3])
bma_bric <- data.frame(coef(bma_bric_full, exact=T, std.coefs=F, order.by.pip = F, include.constant=T)[ ,1:3])
bma_hq <- data.frame(coef(bma_hq_full, exact=T, std.coefs=F, order.by.pip = F, include.constant=T)[ ,1:3])

setwd(currentDir_output_BMA)
stargazer(bma_dilut, digits=3, summary=F,type="text", out=paste("bma_dilut.tex",sep = "")) # baseline BMA table
stargazer(bma_uniform, digits=3, summary=F,type="text", out=paste("bma_uniform.tex",sep = ""))  # robust BMA table
stargazer(bma_bric, digits=3, summary=F,type="text", out=paste("bma_bric.tex",sep = ""))  # robust BMA table
stargazer(bma_hq, digits=3, summary=F,type="text", out=paste("bma_hq.tex",sep = ""))  # robust BMA table

# estimate BMA for different prior combinations
gprior_all <- c("UIP", "UIP", "BRIC", "HQ") 
modelprior_all <- c("dilut", "uniform", "random", "random")

pip_act <- c()
pip_names <- c()

# set parameters for estimation 
burn_ <- 1e6
iter_ <- 3e6
nmodel_ <- 10000
order_PIP <- T 
mcmc_ <- "bd"

for (i in 1:length(gprior_all)){
  gprior <- gprior_all[i]
  modelprior <- modelprior_all[i]
  bma_est_sens <- bms(bayes, burn = burn_, iter = iter_, 
                      g = gprior, mprior = modelprior, 
                      nmodel = nmodel_, mcmc = mcmc_, user.int = F)
  pip_act <- cbind(pip_act,
                  coef(bma_est_sens, std.coefs = F, order.by.pip = order_PIP, exact = T, include.constant = T)[,1])
  # prior names
  pip_names <- c(pip_names,
                 paste(gprior, "and", modelprior))
}

pip_names
pip_names <- c("UIP and Dilution", "UIP and Uniform", 
               "BRIC and Random", "HQ and Random")
colnames(pip_act) <- pip_names

# generate plots and save them
currentDir <- dirname(rstudioapi::getSourceEditorContext()$path)
currentDir_charts_bma <- paste(currentDir, "/charts/bma", sep="")

setwd(currentDir_charts_bma)
# CA
pip_all <- pip_act
pip_all <- pip_all[order(-rowSums(pip_all)),]
pip_act2 <- melt(pip_act)
pip_act2$X1 <- as.factor(pip_act2$X1)
ggplot(pip_act2, aes(x = reorder(X1, -value), y = value, colour = X2), 
       alpha = 1, size = 1, shape = 19) + 
  geom_point() +
  theme_minimal() + 
  xlab("") + ylab("") + 
  geom_hline(yintercept = 0) + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
        text = element_text(size = 14), 
        legend.text = element_text(size = 11), 
        legend.title = element_blank(), 
        # legend.position = "bottom") +
        legend.position = c(0.85, 0.75)) +
  scale_colour_viridis_d(option = "viridis")
dev.copy2pdf(file="prior_sensitivity.pdf", out.type="cairo", width=9, height=4)
#par(mfrow=c(1,1))
#plotComp("UIP and Dilution"=bma_dilut, "UIP and Uniform"=bma_uniform,"BRIC and Random"=bma_bric, add.grid=F,cex.xaxis=0.7)

# ==============================

## FMA
# ==============================
# Mallows Model Averaging Program
# Loading libraries
library(foreign)
#install.packages("xtable")
library(xtable)
#install.packages("LowRankQP")
library(LowRankQP)

mydata <- bayes #shorter version of data
x.data <- mydata[,-1]
#adding constant
const_<-c(1)
x.data <-cbind(const_,x.data)

x <- sapply(1:ncol(x.data),function(i){x.data[,i]/max(x.data[,i])})   
scale.vector <- as.matrix(sapply(1:ncol(x.data),function(i){max(x.data[,i])}))        
Y <- as.matrix(mydata[,1])
output.colnames <- colnames(x.data)
full.fit <- lm(Y~x-1)
beta.full <- as.matrix(coef(full.fit))
M <- k <- ncol(x)
n <- nrow(x)
beta <- matrix(0,k,M)
e <- matrix(0,n,M)
K_vector <- matrix(c(1:M))
var.matrix <- matrix(0,k,M)
bias.sq <- matrix(0,k,M)             

# MMA Estimator using orthogonalization 
for(i in 1:M)
{
  X <- as.matrix(x[,1:i])
  ortho <- eigen(t(X)%*%X)
  Q <- ortho$vectors ; lambda <- ortho$values 
  x.tilda <- X%*%Q%*%(diag(lambda^-0.5,i,i))
  beta.star <- t(x.tilda)%*%Y
  beta.hat <- Q%*%diag(lambda^-0.5,i,i)%*%beta.star
  beta[1:i,i] <- beta.hat
  e[,i] <- Y-x.tilda%*%as.matrix(beta.star)
  bias.sq[,i] <- (beta[,i]-beta.full)^2
  var.matrix.star <- diag(as.numeric(((t(e[,i])%*%e[,i])/(n-i))),i,i)
  var.matrix.hat <- var.matrix.star%*%(Q%*%diag(lambda^-1,i,i)%*%t(Q))
  var.matrix[1:i,i] <- diag(var.matrix.hat)
  var.matrix[,i] <- var.matrix[,i]+ bias.sq[,i]
} # End loop over i

e_k <- e[,M]
sigma_hat <- as.numeric((t(e_k)%*%e_k)/(n-M))
G <- t(e)%*%e
a <- ((sigma_hat)^2)*K_vector
A <- matrix(1,1,M)
b <- matrix(1,1,1)
u <- matrix(1,M,1)
optim <- LowRankQP(Vmat=G,dvec=a,Amat=A,bvec=b,uvec=u,method="LU",verbose=FALSE)
weights <- as.matrix(optim$alpha)
beta.scaled <- beta%*%weights
final.beta <- beta.scaled/scale.vector
std.scaled <- sqrt(var.matrix)%*%weights
final.std <- std.scaled/scale.vector
results.reduced <- as.matrix(cbind(final.beta,final.std))
rownames(results.reduced) <- output.colnames; colnames(results.reduced) <- c("Coefficient", "Sd. Err")
#MMA.fls <- round(results.reduced,4)[-1,]
MMA.fls <- round(results.reduced,4)
list(MMA.fls)

separator   = ";"
setwd(currentDir_output_BMA)
write.table(MMA.fls,"FMA_results_bma.csv",sep=separator)

#write the table
MMA.fls <- data.frame(MMA.fls)
t <- as.data.frame(MMA.fls$Coefficient/MMA.fls$Sd..Err)
MMA.fls$pv <-round( (1-apply(as.data.frame(apply(t,1,abs)), 1, pnorm))*2,3)
MMA.fls$names <- rownames(MMA.fls)
names <- c(colnames(mydata))
names <- names[!names %in% c("habit.se")]
names <- c(names,"const_")
MMA.fls <- MMA.fls[match(names, MMA.fls$names),]
MMA.fls$names <- NULL
MMA.fls

library(xtable)
xtable(MMA.fls,digits=c(0,3,3,3))
setwd(currentDir_output_BMA)
MMA.fls<-MMA.fls[-1,]
stargazer(MMA.fls,digits=3,summary=F,type="text", out=paste("FMA_estim.tex",sep = ""))

#================================ 

## OLS
# ==============================
# rename constant
rownames(bma_dilut)[which(rownames(bma_dilut)=="(Intercept)")] <- "const_"

## 1. Frequentist check -- selected variables, simple OLS
var_sel_ols <- rownames(bma_dilut)[which(bma_dilut$PIP>0.5)]
var_sel_ols2 <- head(var_sel_ols, - 1)
x_ols0 <- bayes[,-1]
x_ols_sel <- as.matrix(x_ols0[, var_sel_ols2])

# OLS estimation
y_ols <- as.matrix(bayes$Estimate)
lm_ols <- lm_robust(y_ols ~ x_ols_sel, 
                    clusters = as.matrix(dataBMA$publid),
                    se_type = "stata")
coef_ols <- as.matrix(coef(summary(lm_ols)))[, c(1, 2, 4)]

# adjusted R2
adjr2_ols <- summary(lm_ols)$adj.r.squared
setwd(currentDir_output_BMA)
stargazer(coef_ols, digits=3, summary=F,type="text", out=paste("lm_OLS_clustered.tex",sep = "")) 
# ==============================

## IMPLIED ELASTICITY
# ==============================
library(multcomp)
# which quantile to use in weighting (linear combination)
qq <- 0.5
qq1 <- 0.1
qq2 <- 0.9

# save the list of variables into matrix
rownames(bma_dilut)[which(rownames(bma_dilut)=="(Intercept)")] <- "const_"
var_implied <- rownames(bma_dilut)
x_implied0 <- bayes[,-1]
const_ <- 1
x_implied0 <- cbind(x_implied0,const_)
y_implied <- as.matrix(bayes$Estimate)

Var_implied <- as.matrix(var_implied)
incl_A <- c(0, # SE
            0, # Equally
            1, # Value - in baseline
            0, # Monthly
            as.numeric(quantile(x_implied0[, "Impact"], prob=qq2)), # Impact - studies with high-impavt factor
            as.numeric(quantile(x_implied0[, "CapGDP"], prob=qq)), # CapGDP - sample mean
            as.numeric(quantile(x_implied0[, "HHI"], prob=qq)), # HHI - sample mean
            as.numeric(quantile(x_implied0[, "After_SA"], prob=qq)), # After_SA - universally no impact
            as.numeric(quantile(x_implied0[, "YearsNo"], prob=qq2)), # YearsNo - longer sample preffered
            as.numeric(quantile(x_implied0[, "Citation_ln"], prob=qq2)), # Citation_ln - highly cited studies
            1, # Surrounding - in baseline
            0, # One_Week
            0, # Two_Weeks
            0, # One_Month
            1, # First_Announcement - in baseline
            0, # Mailing_Date
            0, # Meeting_Date
            0, # Filing
            0, # Decision_Date
            0, # Performance_Governance - in baseline is general objective
            0, # Governance_General
            0, # Governance_Board_Seats
            0, # Governance_Other
            0, # Sale
            0, # Other_Objective
            0, # Successful
            0, # Unsuccessful
            0, # Market_Adjusted - in baseline is market model
            0, # Other_Model
            0, # Calpers - in baseline are hedge funds
            0, # Institutional
            0, # Individual
            1, # Sponsor_na - in baseline
            1, # All_types - in baseline
            0, # Direct_Negotiation
            0, # Proxy_Fight
            0, # Other_Activism
            as.numeric(quantile(x_implied0[, "Europe"], prob=qq)), # Europe - in baseline is average of countries
            as.numeric(quantile(x_implied0[, "Asia"], prob=qq)), # Asia
            0, # Other_Estim - in baseline is OLS
            1)# constant


#Baseline
incl_A

# Hedge fund, Calpers, Institutional, Individual
incl_B1 <- incl_A
incl_B1[which(Var_implied=="Sponsor_na")] <- 0 # Hedge fund
incl_B2 <- incl_A
incl_B2[which(Var_implied=="Calpers")] <- 1 # Calpers
incl_B2[which(Var_implied=="Sponsor_na")] <- 0
incl_B3 <- incl_A
incl_B3[which(Var_implied=="Institutional")] <- 1 # Institutional
incl_B3[which(Var_implied=="Sponsor_na")] <- 0
incl_B4 <- incl_A
incl_B4[which(Var_implied=="Individual")] <- 1 # Individual
incl_B4[which(Var_implied=="Sponsor_na")] <- 0

# Shareholder_proposal, Proxy_fight
incl_C1 <- incl_A
incl_C1[which(Var_implied=="All_Types")] <- 0 # Shareholder_proposal - same as baseline!
incl_C2 <- incl_A
incl_C2[which(Var_implied=="All_Types")] <- 0 # Proxy_fight
incl_C2[which(Var_implied=="Proxy_Fight")] <- 1 

# Successful, Result_na
incl_D1 <- incl_A
incl_D1[which(Var_implied=="Successful")] <- 1 # Successful
incl_D2 <- incl_A  # Result_na - same as baseline!

# US, Europe, Asia
incl_E1 <- incl_A
incl_E1[which(Var_implied=="Europe")] <- 0 # US
incl_E1[which(Var_implied=="Asia")] <- 0 
incl_E1[which(Var_implied=="CapGDP")] <- 129.2258289 #newest value for US in the sample
incl_E1[which(Var_implied=="HHI")] <- 0.056438856
incl_E1[which(Var_implied=="After_SA")] <- 1 #now is after SA
incl_E2 <- incl_A
incl_E2[which(Var_implied=="Europe")] <- 1 # Europe
incl_E2[which(Var_implied=="Asia")] <- 0 
incl_E2[which(Var_implied=="CapGDP")] <- 50.75544683
incl_E2[which(Var_implied=="HHI")] <- 0.074756851
incl_E2[which(Var_implied=="After_SA")] <- 0 #not applicable for Europe
incl_E3 <- incl_A
incl_E3[which(Var_implied=="Asia")] <- 1 # Asia
incl_E3[which(Var_implied=="Europe")] <- 0
incl_E3[which(Var_implied=="CapGDP")] <- 209.604096
incl_E3[which(Var_implied=="HHI")] <- 0.106507255
incl_E3[which(Var_implied=="After_SA")] <- 0  #not applicable for Asia

## save it into the list
incl_all <- list(incl_A,
                 incl_B1, incl_B2, incl_B3, incl_B4, incl_C1, incl_C2, incl_D1, incl_D2,
                 incl_E1, incl_E2, incl_E3)
incl_all_names <- c("Baseline",
                    "Hedge fund", "Calpers","Institutional","Individual",
                    "Shareholder_proposal", "Proxy_fight",
                    "Successful","Result_na", 
                    "US","Europe","Asia" )
colnames(Var_implied)['(Intercept)'] <- "Intercept"
var_sel_list <- list(Var_implied,
                     Var_implied,Var_implied,Var_implied,Var_implied,
                     Var_implied,Var_implied,
                     Var_implied,Var_implied,
                     Var_implied,Var_implied,Var_implied)

#### estimate
ie_table <- c()
for (i in 1:length(incl_all)){
  x_ols1 <- as.matrix(x_implied0[, var_sel_list[[i]]])
  lm_ie <- lm_robust(y_implied ~ x_ols1-1, #without constant - constant is in the list of variables
                     clusters = as.matrix(dataBMA$publid), 
                     se_type = "stata")
  myres <- c(as.numeric(round(coef(glht(lm_ie, linfct = t(incl_all[[i]]))),3)),
             #as.numeric(round(summary(glht(lm_ie, linfct = t(incl_all[[i]])))$test$pvalues,3)),
             as.numeric(round(coef(glht(lm_ie, linfct = t(incl_all[[i]]))) - summary(glht(lm_ie, linfct = t(incl_all[[i]])))$test$sigma*1.96,3)), 
             as.numeric(round(coef(glht(lm_ie, linfct = t(incl_all[[i]]))) + summary(glht(lm_ie, linfct = t(incl_all[[i]])))$test$sigma*1.96,3)))
  ie_table <- rbind(ie_table,myres)
}

ie_table <- cbind(NA,incl_all_names,ie_table)
# export
setwd(currentDir_output)
stargazer(ie_table, summary=F,rownames = F,type="text", out=paste("ie_table_simple.tex",sep = ""))

#================================ End of code =================================







