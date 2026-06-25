* generating partial correlations and their std errors
gen PCC_L=TSTAT_L/sqrt(TSTAT_L^2+DF)
gen PCC_S=TSTAT_S/sqrt(TSTAT_S^2+DF)
gen SE_PCC_L=sqrt((1-PCC_L*PCC_L)/DF)
gen SE_PCC_S=sqrt((1-PCC_S*PCC_S)/DF)
gen SE1_PCC_L = 1/SE_PCC_L
gen SE1_PCC_S = 1/SE_PCC_S

*outliers?
dotplot TSTAT_L
dotplot TSTAT_S
dotplot PCC_L
dotplot PCC_S
dotplot SE1_PCC_L
gen odd =0
replace odd=1 in 195
replace odd=1 in 205
replace odd=1 in 283
drop if odd==1 (3 observations deleted) 


*generate weighting variables
gen Inverse=1/No_Eq
gen Prec_L=1/SE_PCC_L
gen Prec_S=1/SE_PCC_S

*generate instrumental variable
gen Instrum=1/sqrt(DF)

* estimating the average reform effect
mean PCC_L 
mean PCC_S 
metan PCC_L SE_PCC_L , nograph fixed
metan PCC_S SE_PCC_S, nograph fixed
metan PCC_L SE_PCC_L, nograph random
metan PCC_S SE_PCC_S, nograph random

*funnel plot
quietly sum PCC_L if odd!=1, detail
local m = r(mean)
local median = r(p50)
scatter Prec_L PCC_L, msize(*.6) msymbol(Oh) xline(`m', lp(solid) lcolor(gs0)) xline(`median', lp(dash) lcolor(gs0)) xtitle("Estimate of the size effect, PPC_L") ytitle("Precision of the estimate (1/SE_PPC_L)") saving(funnel, replace)

quietly sum PCC_S, detail
local m = r(mean)
local median = r(p50)
scatter Prec_S PCC_S, msize(*.6) msymbol(Oh) xline(`m', lp(solid) lcolor(gs0)) xline(`median', lp(dash) lcolor(gs0)) xtitle("Estimate of the size effect, PPC_S") ytitle("Precision of the estimate (1/SE_PPC_S)") saving(funnel, replace)

*publication bias
quietly eststo: reg TSTAT_L SE1_PCC_L, cluster (IDStudy)
quietly eststo: rreg TSTAT_L SE1_PCC_L 
quietly eststo: xtreg TSTAT_L SE1_PCC_L, fe vce(cluster IDStudy)
quietly eststo: xtmixed TSTAT_L SE1_PCC_L  || IDStudy: 
quietly eststo: ivreg TSTAT_L (SE1_PCC_L=Instrum) , cluster(IDStudy)
quietly eststo: reg PCC_L SE_PCC_L  [pweight=Inverse] , cluster (IDStudy)
estout, cells(b(star fmt(3)) se(par fmt(2)))
eststo clear 

quietly eststo: reg TSTAT_S SE1_PCC_S, cluster (IDStudy)
quietly eststo: rreg TSTAT_S SE1_PCC_S 
quietly eststo: xtmixed TSTAT_S SE1_PCC_S || IDStudy: 
quietly eststo: ivreg TSTAT_S (SE1_PCC_S=Instrum) , cluster(IDStudy)
quietly eststo: reg PCC_S SE_PCC_S  [pweight=Inverse] , cluster (IDStudy)
estout, cells(b(star fmt(3)) se(par fmt(2)))
eststo clear 

*RC for equations that apply growth to GDP
quietly eststo: reg TSTAT_L SE1_PCC_L if Growth==1, cluster (IDStudy)
quietly eststo: rreg TSTAT_L SE1_PCC_L if Growth==1
quietly eststo: xtreg TSTAT_L SE1_PCC_L if Growth==1, fe vce(cluster IDStudy)
quietly eststo: xtmixed TSTAT_L SE1_PCC_L if Growth==1 || IDStudy: 
quietly eststo: ivreg TSTAT_L (SE1_PCC_L=Instrum) if Growth==1, cluster(IDStudy)
quietly eststo: reg PCC_L SE_PCC_L  [pweight=Inverse] if Growth==1 , cluster (IDStudy)
estout, cells(b(star fmt(3)) se(par fmt(2)))
eststo clear 

quietly eststo: reg TSTAT_S SE1_PCC_S if Growth==1, cluster (IDStudy)
quietly eststo: rreg TSTAT_S SE1_PCC_S if Growth==1
quietly eststo: xtmixed TSTAT_S SE1_PCC_S if Growth==1|| IDStudy: 
quietly eststo: ivreg TSTAT_S (SE1_PCC_S=Instrum) if Growth==1, cluster(IDStudy)
quietly eststo: reg PCC_S SE_PCC_S  [pweight=Inverse] if Growth==1, cluster (IDStudy)
estout, cells(b(star fmt(3)) se(par fmt(2)))
eststo clear 

*Robustness check
*Top10
summarize Prec_L, detail
local top10bound = r(p90)
summarize PCC_L if Prec_L > `top10bound'
*WAAP
reg TSTAT_L SE1_PCC_L if TSTAT_L > 2.8, cluster (IDStudy)
*A&K
*https://maxkasy.github.io/home/metastudy/
*Stem
*in R: https://github.com/Chishio318/stem-based_method

*explanatory variables (preparation)
gen NomGDP=1
replace NomGDP=0 if RealGDP==1
gen TSpan = End - Start
gen LN_TSpan = log(TSpan+1)
gen LN_Sample = log(Sample+1)
gen LN_Variables = log(Variables+1)
gen LN_Countries = log(N+1)
gen LN_Time = log(T+1)
gen LN_Citat = log(Citat+1)
gen LN_Length = log(Length+1)
*gen LN_RY = log(RY+1)

sum TSTAT_L PCC_L SE1_PCC_L PerCap NomGDP Growth Log_trans Rem Rempc RemofGDP Growth_Rem AID FDI OPEN FD INS IT Panel TS Cross LN_Countries LN_TSpan LN_Length LN_Variables Homogen Endogen LN_Citat IF EUR EAP SA LAC MENA SSA LI LMI UMI if PCC_L!=.
* drop: 
sum TSTAT_L PCC_L SE1_PCC_L PerCap RealGDP Growth Log_trans Rem Rempc RemofGDP Growth_Rem Log_Rem AID FDI OPEN FD INS IT Panel TS Cross LN_Countries LN_TSpan LN_Length LN_Variables Homogen Endogen LN_Citat IF EUR EAP SA LAC MENA SSA LI LMI UMI if PCC_S!=.
* drop: 

* dividing by standard errors
local longvar PerCap NomGDP Growth Log_trans Rem Rempc RemofGDP Growth_Rem Log_Rem AID FDI OPEN FD INS IT Panel TS Cross LN_Countries LN_TSpan LN_Length LN_Variables Homogen Endogen LN_Citat IF EUR EAP SA LAC MENA SSA LI LMI UMI
foreach x of varlist `longvar' {
				gen `x'_se_L = `x' / SE_PCC_L
}

local shortvar PerCap RealGDP Growth Log_trans Rem Rempc RemofGDP Growth_Rem Log_Rem AID FDI OPEN FD INS IT Panel TS Cross LN_Countries LN_TSpan LN_Length LN_Variables Homogen Endogen LN_Citat IF EUR EAP SA LAC MENA SSA LI LMI UMI
foreach x of varlist `shortvar' {
				gen `x'_se_S = `x' / SE_PCC_S
}

*heterogeneity
quietly eststo: reg TSTAT_L SE1_PCC_L PerCap_se_L RealGDP_se_L Growth_se_L Log_trans_se_L Rem_se_L Rempc_se_L Growth_Rem_se_L Log_Rem_se_L AID_se_L FDI_se_L OPEN_se_L FD_se_L INS_se_L IT_se_L TS_se_L Cross_se_L LN_Countries_se_L LN_TSpan_se_L LN_Length_se_L LN_Variables_se_L Homogen_se_L Endogen_se_L LN_Citat_se_L IF_se_L EUR_se_L EAP_se_L SA_se_L LAC_se_L MENA_se_L SSA_se_L LI_se, cluster (IDStudy)
quietly eststo: rreg TSTAT_L SE1_PCC_L PerCap_se_L RealGDP_se_L Growth_se_L Log_trans_se_L Rem_se_L Rempc_se_L Growth_Rem_se_L Log_Rem_se_L AID_se_L FDI_se_L OPEN_se_L FD_se_L INS_se_L IT_se_L TS_se_L Cross_se_L LN_Countries_se_L LN_TSpan_se_L LN_Length_se_L LN_Variables_se_L Homogen_se_L Endogen_se_L LN_Citat_se_L IF_se_L EUR_se_L EAP_se_L SA_se_L LAC_se_L MENA_se_L SSA_se_L LI_se 
quietly eststo: xtreg TSTAT_L SE1_PCC_L PerCap_se_L RealGDP_se_L Growth_se_L Log_trans_se_L Rem_se_L Rempc_se_L Growth_Rem_se_L Log_Rem_se_L AID_se_L FDI_se_L OPEN_se_L FD_se_L INS_se_L IT_se_L TS_se_L Cross_se_L LN_Countries_se_L LN_TSpan_se_L LN_Length_se_L LN_Variables_se_L Homogen_se_L Endogen_se_L LN_Citat_se_L IF_se_L EUR_se_L EAP_se_L SA_se_L LAC_se_L MENA_se_L SSA_se_L LI_se , fe vce(cluster IDStudy)
quietly eststo: xtmixed TSTAT_L SE1_PCC_L PerCap_se_L RealGDP_se_L Growth_se_L Log_trans_se_L Rem_se_L Rempc_se_L Growth_Rem_se_L Log_Rem_se_L AID_se_L FDI_se_L OPEN_se_L FD_se_L INS_se_L IT_se_L TS_se_L Cross_se_L LN_Countries_se_L LN_TSpan_se_L LN_Length_se_L LN_Variables_se_L Homogen_se_L Endogen_se_L LN_Citat_se_L IF_se_L EUR_se_L EAP_se_L SA_se_L LAC_se_L MENA_se_L SSA_se_L LI_se  || IDStudy: 
quietly eststo: ivreg TSTAT_L PerCap_se_L RealGDP_se_L Growth_se_L Log_trans_se_L Rem_se_L Rempc_se_L Growth_Rem_se_L Log_Rem_se_L AID_se_L FDI_se_L OPEN_se_L FD_se_L INS_se_L IT_se_L TS_se_L Cross_se_L LN_Countries_se_L LN_TSpan_se_L LN_Length_se_L LN_Variables_se_L Homogen_se_L Endogen_se_L LN_Citat_se_L IF_se_L EUR_se_L EAP_se_L SA_se_L LAC_se_L MENA_se_L SSA_se_L LI_se  (SE1_PCC_L=Instrum) , cluster(IDStudy)
quietly eststo: reg PCC_L SE_PCC_L PerCap RealGDP Growth Log_trans Rem Rempc Growth_Rem Log_Rem AID FDI OPEN FD INS IT TS Cross LN_Countries LN_TSpan LN_Length LN_Variables Homogen Endogen LN_Citat IF EUR EAP SA LAC MENA SSA LI [pweight=Inverse] , cluster (IDStudy)
estout, cells(b(star fmt(3)) se(par fmt(2)))
eststo clear

*Robustness check - unweighted results
quietly eststo: reg PCC_L SE_PCC_L PerCap RealGDP Growth Log_trans Rem Rempc Growth_Rem Log_Rem AID FDI OPEN FD INS IT TS Cross LN_Countries LN_TSpan LN_Length LN_Variables Homogen Endogen LN_Citat IF EUR EAP SA LAC MENA SSA LI, cluster (IDStudy)
quietly eststo: rreg PCC_L SE_PCC_L PerCap RealGDP Growth Log_trans Rem Rempc Growth_Rem Log_Rem AID FDI OPEN FD INS IT TS Cross LN_Countries LN_TSpan LN_Length LN_Variables Homogen Endogen LN_Citat IF EUR EAP SA LAC MENA SSA LI
quietly eststo: xtreg PCC_L SE_PCC_L PerCap RealGDP Growth Log_trans Rem Rempc Growth_Rem Log_Rem AID FDI OPEN FD INS IT TS Cross LN_Countries LN_TSpan LN_Length LN_Variables Homogen Endogen LN_Citat IF EUR EAP SA LAC MENA SSA LI, fe vce(cluster IDStudy)
quietly eststo: xtmixed PCC_L SE_PCC_L PerCap RealGDP Growth Log_trans Rem Rempc Growth_Rem Log_Rem AID FDI OPEN FD INS IT TS Cross LN_Countries LN_TSpan LN_Length LN_Variables Homogen Endogen LN_Citat IF EUR EAP SA LAC MENA SSA LI || IDStudy: 
quietly eststo: ivreg PCC_L SE_PCC_L PerCap RealGDP Growth Log_trans Rem Rempc Growth_Rem Log_Rem AID FDI OPEN FD INS IT TS Cross LN_Countries LN_TSpan LN_Length LN_Variables Homogen Endogen LN_Citat IF EUR EAP SA LAC MENA SSA LI (SE_PCC_L=Instrum) , cluster(IDStudy)
estout, cells(b(star fmt(3)) se(par fmt(2)))
eststo clear 

*prapering for BMA in R, long-term only:
drop if PCC_L==.
bysort TSTAT_L: sum SE1_PCC_L PerCap_se_L NomGDP_se_L Growth_se_L Log_trans_se_L Rem_se_L Rempc_se_L Growth_Rem_se_L Log_Rem_se_L AID_se_L FDI_se_L OPEN_se_L FD_se_L INS_se_L IT_se_L TS_se_L Cross_se_L LN_Countries_se_L LN_TSpan_se_L LN_Length_se_L LN_Variables_se_L Homogen_se_L Endogen_se_L LN_Citat_se_L IF_se_L EUR_se_L EAP_se_L SA_se_L LAC_se_L MENA_se_L SSA_se_L LI_se

*exporting

export excel TSTAT_L  SE1_PCC_L  PerCap_se_L NomGDP_se_L Growth_se_L Log_trans_se_L Rem_se_L Rempc_se_L Growth_Rem_se_L AID_se_L FDI_se_L OPEN_se_L FD_se_L INS_se_L IT_se_L TS_se_L Cross_se_L LN_Countries_se_L LN_TSpan_se_L LN_Length_se_L LN_Variables_se_L Homogen_se_L Endogen_se_L LN_Citat_se_L IF_se_L EUR_se_L EAP_se_L SA_se_L LAC_se_L MENA_se_L SSA_se_L LI_se_L using "C:\Users\AdyC\Desktop\DataBMASE.xls", firstrow(variables) replace

*BMA in R
library(BMS)
dataremit=read.xls("Data longrun2.xls", perl="C:\\Perl64\\bin\\perl.exe")
remit=bms(dataremit, burn=1000000, iter=2000000, g="UIP", mprior="uniform", nmodel=5000, mcmc="bd", user.int=FALSE, logfile=TRUE)
image(remit, cex.axis=0.7, order.by.pip = T, yprop2pip=F)
print(remit$topmod[1])
coef(remit, order.by.pip = F, exact=T, include.constant=T)

*Heterogeneity. Frequentist check
eststo: reg TSTAT_L SE1_PCC_L NomGDP_se_L Growth_Rem_se_L AID_se_L FDI_se_L TS_se_L LN_Countries_se_L Endogen_se_L EAP_se_L SA_se_L MENA_se_L SSA_se_L, cluster (IDStudy)
estout, cells(b(star fmt(3)) se(par fmt(2)))
eststo clear 

*Calculating the BMA adjustet PCC
reg TSTAT_L SE1_PCC_L PerCap_se_L NomGDP_se_L Growth_se_L Log_trans_se_L Rem_se_L Rempc_se_L Growth_Rem_se_L AID_se_L FDI_se_L OPEN_se_L FD_se_L INS_se_L IT_se_L TS_se_L Cross_se_L LN_Countries_se_L LN_TSpan_se_L LN_Length_se_L LN_Variables_se_L Homogen_se_L Endogen_se_L LN_Citat_se_L IF_se_L EUR_se_L EAP_se_L SA_se_L LAC_se_L MENA_se_L SSA_se_L LI_se, cluster (IDStudy)
*At mean values
lincom SE1_PCC_L*0+ PerCap_se_L*0.85 NomGDP_se_L*0.33 Growth_se_L*0.7 Log_trans_se_L*0.51 Rem_se_L*0.25 Rempc_se_L*0.04 Growth_Rem_se_L*0.08 AID_se_L*0.11 FDI_se_L*0.28 OPEN_se_L*0.66 FD_se_L*0.44 INS_se_L*0.27 IT_se_L0.*18 TS_se_L*0.2 Cross_se_L*0.04 LN_Countries_se_L*2.92 LN_TSpan_se_L*3.23 LN_Length_se_L*1.13 LN_Variables_se_L*1.94 Homogen_se_L*0.45 Endogen_se_L*0.52 LN_Citat_se_L*3.14 IF_se_L*.01 EUR_se_L*0.03 EAP_se_L*0.03 SA_se_L*0.14 LAC_se_L*0.06 MENA_se_L*0.07 SSA_se_L*0.1 LI_se*0.04
*Best model
lincom SE1_PCC_L*0+ PerCap_se_L*0.85+ NomGDP_se_L*0+ Growth_se_L*0.7+ Log_trans_se_L*0.51+ Rem_se_L*0.25+ Rempc_se_L*0.04+ Growth_Rem_se_L*1+ AID_se_L*1+ FDI_se_L*1+ OPEN_se_L*0.66+ FD_se_L*0.44+ INS_se_L*1+ IT_se_L*0.18+ TS_se_L*0+ Cross_se_L*0+ LN_Countries_se_L*5.05+ LN_TSpan_se_L*3.23+ LN_Length_se_L*1.13+ LN_Variables_se_L*1.94+ Homogen_se_L*0.45+ Endogen_se_L*1+ LN_Citat_se_L*3.14+ IF_se_L*.01+ EUR_se_L*0.03+ EAP_se_L*0.03+ SA_se_L*0.14+ LAC_se_L*0.06+ MENA_se_L*0.07+ SSA_se_L*0.1+ LI_se*0.04

ivreg2 TSTAT_L SE1_PCC_L PerCap_se_L NomGDP_se_L Growth_se_L Log_trans_se_L Rem_se_L Rempc_se_L Growth_Rem_se_L AID_se_L FDI_se_L OPEN_se_L FD_se_L INS_se_L IT_se_L TS_se_L Cross_se_L LN_Countries_se_L LN_TSpan_se_L LN_Length_se_L LN_Variables_se_L Homogen_se_L Endogen_se_L LN_Citat_se_L IF_se_L EUR_se_L EAP_se_L SA_se_L LAC_se_L MENA_se_L SSA_se_L LI_se, cluster (IDStudy)


*RC with wighting by number of equations per study
local longvar2 PCC_L SE_PCC_L PerCap NomGDP Growth Log_trans Rem Rempc RemofGDP Growth_Rem Log_Rem AID FDI OPEN FD INS IT Panel TS Cross LN_Countries LN_TSpan LN_Length LN_Variables Homogen Endogen LN_Citat IF EUR EAP SA LAC MENA SSA LI LMI UMI
foreach x of varlist `longvar2' {
				gen `x'_nreq = `x' / No_Eq
}

export excel PCC_L_nreq SE_PCC_L_nreq PerCap_nreq NomGDP_nreq Growth_nreq Log_trans_nreq Rem_nreq Rempc_nreq Growth_Rem_nreq AID_nreq FDI_nreq OPEN_nreq FD_nreq INS_nreq IT_nreq TS_nreq Cross_nreq LN_Countries_nreq  LN_TSpan_nreq  LN_Length_nreq  LN_Variables_nreq  Homogen_nreq  Endogen_nreq  LN_Citat_nreq  IF_nreq  EUR_nreq  EAP_nreq  SA_nreq  LAC_nreq  MENA_nreq  SSA_nreq  LI_nreq  using "C:\Users\AdyC\Desktop\DataBMANREQ.xls", firstrow(variables) replace

*other
gen Rem_se_L = Rem / SE_PCC_L
gen Growth_Rem_se_L = Growth_Rem / SE_PCC_L
gen Log_Rem_se_L = Log_Rem / SE_PCC_L
gen RemofGDP_se_L = RemofGDP / SE_PCC_L
gen NomGDP_nreq = NomGDP / No_Eq

*exporting - Unweighted
export excel PCC_L SE_PCC_L PerCap NomGDP  Growth  Log_trans  Rem  Rempc Growth_Rem   AID  FDI  OPEN  FD  INS  IT TS  Cross  LN_Countries  LN_TSpan LN_Length LN_Variables  Homogen  Endogen  LN_Citat  IF  EUR  EAP  SA  LAC  MENA  SSA  LI  using "C:\Users\AdyC\Desktop\DataBMAUW.xls", firstrow(variables) replace

reg PCC_L_nreq SE_PCC_L_nreq PerCap_nreq NomGDP_nreq  Growth_nreq  Log_trans_nreq  Rem_nreq  Rempc_nreq   Growth_Rem_nreq AID_nreq  FDI_nreq  OPEN_nreq  FD_nreq  INS_nreq  IT_nreq TS_nreq  Cross_nreq  LN_Countries_nreq  LN_TSpan_nreq  LN_Length_nreq  LN_Variables_nreq  Homogen_nreq  Endogen_nreq  LN_Citat_nreq  IF_nreq  EUR_nreq  EAP_nreq  SA_nreq  LAC_nreq  MENA_nreq  SSA_nreq  LI_nreq, cluster (IDStudy)

*Funnel plot on coeffcients, not PCC
gen Precision=1/SE_L
quietly sum COEF_L if (PerCap==1 & RealGDP==1 & Growth==1 & Log_trans==1 & RemofGDP==1), detail
local m = r(mean)
local median = r(p50)
scatter Precision COEF_L if(PerCap==1 & RealGDP==1 & Growth==1 & Log_trans==1 & RemofGDP==1), msize(*.6) msymbol(Oh) xline(`m', lp(solid) lcolor(gs0)) xline(`median', lp(dash) lcolor(gs0)) xtitle("Estimate of the size effect") ytitle("Precision of the estimate (log(1/SE)") saving(funnel, replace)

gen LogPrec=log(Precision+1)
quietly sum COEF_L if (PerCap==1 & RealGDP==1 & Growth==1 & RemofGDP==1), detail
local m = r(mean)
local median = r(p50)
scatter LogPrec COEF_L if(PerCap==1 & RealGDP==1 & Growth==1 & RemofGDP==1), msize(*.6) msymbol(Oh) xline(`m', lp(solid) lcolor(gs0)) xline(`median', lp(dash) lcolor(gs0)) xtitle("Estimate of the size effect") ytitle("Precision of the estimate (log(1/SE)") saving(funnel, replace)
winsor2 LogPrec COEF_L, replace cuts (2.5 97.5)

mean PCC_L if (PerCap==1 & RealGDP==1 & Growth==1 & RemofGDP==1)
