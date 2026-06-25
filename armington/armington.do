******************************************************************************
******************************************************************************
* A Meta-Analysis of the Estimates of the Armington Elasticity
******************************************************************************
******************************************************************************
* August 7, 2020
log using armington.log, replace
import excel data.xlsx, sheet("data") firstrow
set more off
******************************************************************************
* Summary statistics
******************************************************************************
gen invnobs = 1/nobs
gen invnobs_long = 1/nobs_long
gen invnobs_short = 1/nobs_short
winsor armel, gen(armel_w1) p(0.01)
winsor armel, gen(armel_w5) p(0.05)

sum armel armel_w1 armel_w armel_w5

sum armel armel_w se se_w
summarize armel_w se_w se_lrun srun lrun sicdata sicres mon quart annu pan ts cross length ltotal lmidyear prim sec ter deving deved lmsize armx darmx army ecmyx asp othmod ols corc tsls gmm othest imcon seas impact lcit pblshd tariff ntb volatility pride internet
summarize armel_w se_w se_lrun srun lrun sicdata sicres mon quart annu pan ts cross length ltotal lmidyear prim sec ter deving deved lmsize armx darmx army ecmyx asp othmod ols corc tsls gmm othest imcon seas impact lcit pblshd tariff ntb volatility pride internet [aweight=invnobs]

summarize armel_w se_w sicdata sicres mon quart annu pan ts cross length ltotal lmidyear prim sec ter deving deved lmsize armx darmx army ecmyx asp othmod ols corc tsls gmm othest imcon seas impact lcit pblshd tariff ntb volatility pride internet if srun==0
summarize armel_w se_w sicdata sicres mon quart annu pan ts cross length ltotal lmidyear prim sec ter deving deved lmsize armx darmx army ecmyx asp othmod ols corc tsls gmm othest imcon seas impact lcit pblshd tariff ntb volatility pride internet if srun==0 [aweight=invnobs_long]
 
mean armel_w
mean armel_w if srun==1
mean armel_w if srun==0
mean armel_w if deving==1
mean armel_w if deved==1
mean armel_w if prim==1
mean armel_w if prim==0
mean armel_w if sec==1
mean armel_w if ter==1
mean armel_w if pblshd==1
mean armel_w if pblshd==0
mean armel_w if mon==1
mean armel_w if quart==1
mean armel_w if annu==1
mean armel_w [aweight=invnobs]
mean armel_w [aweight=invnobs_short] if srun==1
mean armel_w [aweight=invnobs_long] if srun==0
mean armel_w [aweight=invnobs] if deving==1
mean armel_w [aweight=invnobs] if deved==1
mean armel_w [aweight=invnobs] if prim==1
mean armel_w [aweight=invnobs] if prim==0
mean armel_w [aweight=invnobs] if sec==1
mean armel_w [aweight=invnobs] if ter==1
mean armel_w [aweight=invnobs] if pblshd==1
mean armel_w [aweight=invnobs] if pblshd==0
mean armel_w [aweight=invnobs] if mon==1
mean armel_w [aweight=invnobs] if quart==1
mean armel_w [aweight=invnobs] if annu==1
mean armel_w if ag==1
mean armel_w if min==1
mean armel_w if man==1
mean armel_w if util==1
mean armel_w if cons==1
mean armel_w if trad==1
mean armel_w if trans==1
mean armel_w if fin==1
mean armel_w if serv==1
mean armel_w [aweight=invnobs] if ag==1
mean armel_w [aweight=invnobs] if min==1
mean armel_w [aweight=invnobs] if man==1
mean armel_w [aweight=invnobs] if util==1
mean armel_w [aweight=invnobs] if cons==1
mean armel_w [aweight=invnobs] if trad==1
mean armel_w [aweight=invnobs] if trans==1
mean armel_w [aweight=invnobs] if fin==1
mean armel_w [aweight=invnobs] if serv==1

histogram armel_w, bin(20) frequency xtitle("Estimate of the Armington elasticity") saving(histogram, replace)
bysort idstudy: egen armel_med = median(armel)
bysort idstudy: egen midyear_med = median(midyear)
generate armel_med_w=armel_med
replace armel_med_w=8 if armel_med_w>13
graph twoway (scatter armel_med_w midyear_med, msize(*1) msymbol(Oh)) (lfit armel_med_w midyear_med, lcolor(black)),  xtitle("Median year of data") ytitle("Median estimate of the Armington elasticity") legend(off) saving(trend, replace)
graph hbox armel if armel>-10 & armel<20, over(author,label(grid)) ysize(7) xsize(7) scale(0.5) yline(1, lcolor(gs12)) box( 1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow)  mcolor(gs12)) ytitle("Estimate of the Armington elasticity") ylabel(, nogrid) saving(studies, replace)
graph hbox armel if armel>-10 & armel<20 & country != "EU14" & country != "EU15" &country != "EU10" &country != "EU25" &country != "Americas" &country != "OECD", over(country,label(grid)) ysize(7) xsize(7) scale(0.5) yline(1, lcolor(gs12)) box( 1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow) mcolor(gs12)) ytitle("Estimate of the Armington elasticity") ylabel(, nogrid) saving(countries, replace)
******************************************************************************
* Funnel plot
******************************************************************************
twoway scatter invse armel if invse<500 & armel>-15 & armel<15, ytitle("Precision of the estimate (1/SE)") xtitle("Estimate of the Armington elasticity") xline(1.63, lpattern(dott) lcolor (black)) saving(funnel, replace)
graph twoway (scatter invse armel if srun==0, msize(*1) msymbol(Oh) mcolor(black)) (scatter invse armel if srun==1, msize(*1) msymbol(Oh)) if invse<500 & armel>-15 & armel<15, ytitle("Precision of the estimate (1/SE)") xtitle("Estimate of the Armington elasticity") xline(1.63, lpattern(dott) lcolor (black)) saving(funnel_both, replace)
******************************************************************************
******************************************************************************
* PUBLICATION BIAS - FAT-PET
******************************************************************************
******************************************************************************
xtset idstudy
eststo: ivreg2 armel_w se_w, cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w if srun==1, robust
eststo: ivreg2 armel_w se_w if srun==0, cluster(idstudy idcountry)
esttab using table_bias_ols.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
eststo: xtreg armel_w se_w, fe cluster(idstudy)
eststo: xtreg armel_w se_w if srun==1, fe vce(robust)
eststo: xtreg armel_w se_w if srun==0, fe cluster(idstudy)
esttab using table_bias_fe.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
eststo: ivreg2 armel_w se_w [pweight=invnobs], cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w if srun==1 [pweight=invnobs_short], robust
eststo: ivreg2 armel_w se_w if srun==0 [pweight=invnobs_long], cluster(idstudy idcountry)
esttab using table_bias_nobs.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
eststo: ivreg2 tstats_w invse_w, cluster(idstudy)
eststo: ivreg2 tstats_w invse_w if srun==1, cluster(idstudy)
eststo: ivreg2 tstats_w invse_w if srun==0, cluster(idstudy)
esttab using table_bias_se.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*REVISION******************REVISION******************REVISION
gen se_impact = se_w*impact 
gen se_lcit = se_w*lcit 
gen se_pblshd = se_w*pblshd 
gen se_disaggreg = se_w*sicdata
eststo: ivreg2 armel_w se_w impact se_impact if srun==0, cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w lcit se_lcit if srun==0, cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w pblshd se_pblshd if srun==0, cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w impact lcit pblshd se_impact se_lcit se_pblshd if srun==0, cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w sicdata se_disaggreg if srun==0, cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w impact lcit pblshd sicdata se_impact se_lcit se_pblshd se_disaggreg if srun==0, cluster(idstudy idcountry)
esttab using table_bias_quality.tex, se booktabs replace compress title(FAT-PET for publication characteristics and dissaggregation\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

gen inferior_1 = 1
replace inferior_1 = 0 if preffered==1 & quality==1
gen inferior_2 = 1
replace inferior_2 = 0 if preffered==1 & peer_review==1
gen inferior_3 = 1
replace inferior_3 = 0 if (preffered==1 | indifferent==1) & quality==1
gen inferior_4 = 1
replace inferior_4 = 0 if (preffered==1 | indifferent==1) & peer_review==1

summarize inferior_1 inferior_2 inferior_3 inferior_4 if srun==0
summarize preffered indifferent quality peer_review if srun==0
summarize inferior_4 if srun==0 & mon==1
summarize inferior_4 if srun==0 & quart==1
summarize inferior_4 if srun==0 & annu==1
summarize inferior_4 if srun==0 & pan==1
summarize inferior_4 if srun==0 & ts==1
summarize inferior_4 if srun==0 & cross==1
summarize inferior_4 if srun==0 & asp==1
summarize inferior_4 if srun==0 & armx==1
summarize inferior_4 if srun==0 & army==1
summarize inferior_4 if srun==0 & ols==1
summarize inferior_4 if srun==0 & gmm==1
summarize inferior_4 if srun==0 & prim==1
summarize inferior_4 if srun==0 & sec==1

ivreg2 armel_w se_w inferior_2 if srun==0 & mon==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_4 if srun==0 & mon==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_2 if srun==0 & quart==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_3 if srun==0 & quart==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_4 if srun==0 & quart==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_1 if srun==0 & annu==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_2 if srun==0 & annu==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_3 if srun==0 & annu==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_4 if srun==0 & annu==1 [pweight=invnobs_long], cluster(idstudy idcountry)

ivreg2 armel_w se_w inferior_3 if srun==0 & cross==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_4 if srun==0 & cross==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_1 if srun==0 & ts==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_2 if srun==0 & ts==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_3 if srun==0 & ts==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_4 if srun==0 & ts==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_1 if srun==0 & pan==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_2 if srun==0 & pan==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_3 if srun==0 & pan==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_4 if srun==0 & pan==1 [pweight=invnobs_long], cluster(idstudy idcountry)

ivreg2 armel_w se_w inferior_1 if srun==0 & asp==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_2 if srun==0 & asp==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_3 if srun==0 & asp==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_4 if srun==0 & asp==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_1 if srun==0 & armx==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_2 if srun==0 & armx==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_3 if srun==0 & armx==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_4 if srun==0 & armx==1 [pweight=invnobs_long], cluster(idstudy idcountry)

ivreg2 armel_w se_w inferior_1 if srun==0 & ols==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_2 if srun==0 & ols==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_3 if srun==0 & ols==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_4 if srun==0 & ols==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_2 if srun==0 & (gmm==1 | tsls==1) [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_4 if srun==0 & (gmm==1 | tsls==1) [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_2 if srun==0 & army==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_4 if srun==0 & army==1 [pweight=invnobs_long], cluster(idstudy idcountry)

ivreg2 armel_w se_w inferior_1 if srun==0 & prim==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_2 if srun==0 & prim==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_3 if srun==0 & prim==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_4 if srun==0 & prim==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_1 if srun==0 & sec==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_2 if srun==0 & sec==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_3 if srun==0 & sec==1 [pweight=invnobs_long], cluster(idstudy idcountry)
ivreg2 armel_w se_w inferior_4 if srun==0 & sec==1 [pweight=invnobs_long], cluster(idstudy idcountry)


eststo: ivreg2 armel_w se_w inferior_1 if srun==0 [pweight=invnobs_long], cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w inferior_2 if srun==0 [pweight=invnobs_long], cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w inferior_3 if srun==0 [pweight=invnobs_long], cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w inferior_4 if srun==0 [pweight=invnobs_long], cluster(idstudy idcountry)
esttab using table_bpractice_panelA.tex, se booktabs replace compress title(Quality 1-4\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
eststo: ivreg2 armel_w se_w inferior_1 if srun==0 & annu==1 [pweight=invnobs_long], cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w inferior_4 if srun==0 & quart==1 [pweight=invnobs_long], cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w inferior_2 if srun==0 & mon==1 [pweight=invnobs_long], cluster(idstudy idcountry)
esttab using table_bpractice_panelB.tex, se booktabs replace compress title(Annual, Quarterly, Monthly\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
eststo: ivreg2 armel_w se_w inferior_1 if srun==0 & pan==1 [pweight=invnobs_long], cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w inferior_1 if srun==0 & ts==1 [pweight=invnobs_long], cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w inferior_3 if srun==0 & cross==1 [pweight=invnobs_long], cluster(idstudy idcountry)
esttab using table_bpractice_panelC.tex, se booktabs replace compress title(Panel, Time-series, Cross-section\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
eststo: ivreg2 armel_w se_w inferior_2 if srun==0 & asp==1 [pweight=invnobs_long], cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w inferior_2 if srun==0 & army==1 [pweight=invnobs_long], cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w inferior_2 if srun==0 & armx==1 [pweight=invnobs_long], cluster(idstudy idcountry)
esttab using table_bpractice_panelD.tex, se booktabs replace compress title(Non-linear, Partialadj, Static\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
eststo: ivreg2 armel_w se_w inferior_2 if srun==0 & (gmm==1 | tsls==1) [pweight=invnobs_long], cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w inferior_2 if srun==0 & ols==1 [pweight=invnobs_long], cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w inferior_2 if srun==0 & prim==1 [pweight=invnobs_long], cluster(idstudy idcountry)
eststo: ivreg2 armel_w se_w inferior_1 if srun==0 & sec==1 [pweight=invnobs_long], cluster(idstudy idcountry)
esttab using table_bpractice_panelE.tex, se booktabs replace compress title(GMM\&TSLS, OLS, Primary, Secondary sector\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


******************************************************************************
******************************************************************************
* PUBLICATION BIAS - FAT-PET (hierarchical) in R
******************************************************************************
******************************************************************************
*library(bayesm)
*dataarmington = read.table("clipboard-512", sep="\t", header=TRUE)
*str(dataarmington)
*study <- levels(dataarmington$author)
*nreg <- length(study); nreg
*regdata <- NULL
*for (i in 1:nreg) {
*filter <- dataarmington$author==study[i] 
*y <- dataarmington$armel_w[filter]
*X <- cbind(1,
*dataarmington$se_w[filter])
*regdata[[i]] <- list(y=y, X=X) 
*}
*Data <- list(regdata=regdata) 
*Mcmc <- list(R=6000)
* out <- bayesm::rhierLinearModel( 
*         Data=Data, 
*         Mcmc=Mcmc)
*cat("Summary of Delta Draws", fill=TRUE)
*summary(out$Deltadraw)
******************************************************************************
******************************************************************************
* PUBLICATION BIAS - Stem-based method in R (Furukawa, 2019)
******************************************************************************
******************************************************************************
*source("stem_method.R") #github.com/Chishio318/stem-based_method
*dataarmington = read.table("clipboard-512", sep="\t", header=TRUE)
*stem_results = stem(dataarmington$armel, dataarmington$se, param)
*view(stem_results$estimates)
******************************************************************************
******************************************************************************
* PUBLICATION BIAS - TOP10 method (Stanley et al., 2010)
******************************************************************************
******************************************************************************
summarize invse, detail
gen top10bound = r(p90)
summarize armel invse if invse > top10bound
summarize armel invse if invse > top10bound & srun==1
summarize armel invse if invse > top10bound & srun==0
******************************************************************************
******************************************************************************
* PUBLICATION BIAS - WAAP (Ioannidis et al., 2017) 
******************************************************************************
******************************************************************************
summarize armel [aweight=1/(se*se)]
gen waapbound = abs(r(mean))/2.8
summarize armel if se < waapbound
summarize armel if se < waapbound & srun==1
summarize armel if se < waapbound & srun==0
******************************************************************************
******************************************************************************
* HETEROGENEITY - OLS
******************************************************************************
******************************************************************************
*ivreg2 armel_w se_lrun lrun sicdata sicres mon annu ts cross length ltotal lmidyear sec ter deved lmsize tariff ntb volatility pride internet armx darmx army  asp ols corc tsls gmm imcon seas impact lcit pblshd, cluster(idstudy idcountry)
*long-run
ivreg2 armel_w se_w sicdata sicres mon annu ts cross length ltotal lmidyear sec ter deved lmsize tariff ntb volatility pride internet armx darmx army  asp ols corc tsls gmm imcon seas impact lcit pblshd if lrun==1, cluster(idstudy idcountry)
ivreg2 armel_w se_w sicdata sicres mon annu ts cross length ltotal lmsize tariff volatility tsls imcon seas lcit pblshd if lrun==1, cluster(idstudy idcountry)
******************************************************************************
******************************************************************************
* HETEROGENEITY - BAYEASIAN MODEL AVERAGING ////CODE for R////
******************************************************************************
******************************************************************************
*library(BMS)
*    *ctrl+C from armington.xlsx, sheet("data.r")
*dataarmington = read.table("clipboard-512", sep="\t", header=TRUE)
*armington = bms(dataarmington, burn=1e5,iter=3e5, g="UIP", mprior="uniform", nmodel=50000, mcmc="bd", user.int=FALSE)
*armington1 = bms(dataarmington, burn=1e5,iter=3e5, g="UIP", mprior="dilut", nmodel=50000, mcmc="bd", user.int=FALSE)
*armington2 = bms(dataarmington, burn=1e5,iter=3e5, g="BRIC", mprior="dilut", nmodel=50000, mcmc="bd", user.int=FALSE)
*armington3 = bms(dataarmington, burn=1e5,iter=3e5, g="UIP", mprior="dilut", nmodel=50000, mcmc="tess", user.int=FALSE)
*coef(armington, order.by.pip = F, exact=T, include.constant=T)
*image(armington, yprop2pip=FALSE, order.by.pip=TRUE, do.par=TRUE, do.grid=TRUE, do.axis=TRUE, cex.axis = 0.7)
*summary(armington)
*plot(armington)
*print(armington$topmod[1])
******************************************************************************
******************************************************************************
* HETEROGENEITY - FREQUENTIST MODEL AVERAGING (MALLOWS) ////CODE for R////
******************************************************************************
******************************************************************************
**Loading libraries
*library(foreign)
*library(xtable)
*library(LowRankQP)
*datadaylight=read.table("clipboard-512", sep="\t", header=TRUE)
**deleting missing observations
*datadaylight <-na.omit(datadaylight)
*x.data <- datadaylight[,-1]
**adding constant
*const_<-c(1)
*x.data <-cbind(const_,x.data)
******************************************************************************
*x <- sapply(1:ncol(x.data),function(i){x.data[,i]/max(x.data[,i])})   
*scale.vector <- as.matrix(sapply(1:ncol(x.data),function(i){max(x.data[,i])}))        
*Y <- as.matrix(datadaylight[,1])
*output.colnames <- colnames(x.data)
*full.fit <- lm(Y~x-1)
*beta.full <- as.matrix(coef(full.fit))
*M <- k <- ncol(x)
*n <- nrow(x)
*beta <- matrix(0,k,M)
*e <- matrix(0,n,M)
*K_vector <- matrix(c(1:M))
*var.matrix <- matrix(0,k,M)
*bias.sq <- matrix(0,k,M) 
******************************************************************************            
**MMA estimator using orthogonalization 
*for(i in 1:M)
*{
*  X <- as.matrix(x[,1:i])
*  ortho <- eigen(t(X)%*%X)
*  Q <- ortho$vectors ; lambda <- ortho$values 
*  x.tilda <- X%*%Q%*%(diag(lambda^-0.5,i,i))
*  beta.star <- t(x.tilda)%*%Y
*  beta.hat <- Q%*%diag(lambda^-0.5,i,i)%*%beta.star
*  beta[1:i,i] <- beta.hat
*  e[,i] <- Y-x.tilda%*%as.matrix(beta.star)
*  bias.sq[,i] <- (beta[,i]-beta.full)^2
*  var.matrix.star <- diag(as.numeric(((t(e[,i])%*%e[,i])/(n-i))),i,i)
*  var.matrix.hat <- var.matrix.star%*%(Q%*%diag(lambda^-1,i,i)%*%t(Q))
*  var.matrix[1:i,i] <- diag(var.matrix.hat)
*  var.matrix[,i] <- var.matrix[,i]+ bias.sq[,i]
*} 
**End loop over i
******************************************************************************
*e_k <- e[,M]
*sigma_hat <- as.numeric((t(e_k)%*%e_k)/(n-M))
*G <- t(e)%*%e
*a <- ((sigma_hat)^2)*K_vector
*A <- matrix(1,1,M)
*b <- matrix(1,1,1)
*u <- matrix(1,M,1)
*optim <- LowRankQP(Vmat=G,dvec=a,Amat=A,bvec=b,uvec=u,method="LU",verbose=FALSE)
*weights <- as.matrix(optim$alpha)
*beta.scaled <- beta%*%weights
*final.beta <- beta.scaled/scale.vector
*std.scaled <- sqrt(var.matrix)%*%weights
*final.std <- std.scaled/scale.vector
*results.reduced <- as.matrix(cbind(final.beta,final.std))
*rownames(results.reduced) <- output.colnames; colnames(results.reduced) <- c("Coefficient", "Sd. Err")
*MMA.fls <- round(results.reduced,4)
*MMA.fls <- data.frame(MMA.fls)
*t <- as.data.frame(MMA.fls$Coefficient/MMA.fls$Sd..Err)
*MMA.fls$pv <-round( (1-apply(as.data.frame(apply(t,1,abs)), 1, pnorm))*2,3)
*MMA.fls$names <- rownames(MMA.fls)
*names <- c(colnames(datadaylight))
*names <- c(names,"const_")
*MMA.fls <- MMA.fls[match(names, MMA.fls$names),]
*MMA.fls$names <- NULL
*MMA.fls
******************************************************************************
******************************************************************************
* BEST-PRACTICE (SE calculation to BMA estimate)
******************************************************************************
******************************************************************************
summarize ltotal, detail
summarize length, detail
summarize impact, detail
summarize lcit, detail 
ivreg2 armel_w se_w sicdata sicres mon annu ts cross length ltotal lmidyear sec ter deved lmsize tariff ntb volatility pride internet armx darmx army  asp ols corc tsls gmm imcon seas impact lcit pblshd if srun==0, cluster(idstudy idcountry)
***********************
*** Feenstra (2018) ***
***********************
*World at means
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*0.8153639+lmsize*6.280964+tariff*6.869137+ntb*0.9405251+volatility*0.6384191+pride*0.4904672+internet*3.438876+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Euro area
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*9.078442+tariff*3.27+ntb*1.082473684+volatility*0.920610394+pride*0.342642418+internet*32.49205743+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Australia
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*5.098707+tariff*1.91+ntb*1.22+volatility*1.516772259+pride*0.6835115+internet*27.84277929+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Austria
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*5.640992+tariff*1.84+ntb*1.215+volatility*0.333441163+pride*0.2+internet*27.32468303+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Belgium
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*5.846625+tariff*1.84+ntb*1.4+volatility*0.333441163+pride*0.284+internet*35.75312806+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Brazil
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*0+lmsize*6.326818+tariff*7.79+ntb*2.3228+volatility*0.451791945+pride*0.499238707+internet*11.73692977+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Bulgaria
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*3.193209+tariff*1.84+ntb*1.365+volatility*0.33679998+pride*0.426917511+internet*20.50483617+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Colombia
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*0+lmsize*4.017878+tariff*4.21+ntb*2.47+volatility*0.707768155+pride*0.854951714+internet*10.52185379+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Cyprus 
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*2.822033+tariff*1.84+ntb*1.01+volatility*0.333808456+pride*0.513658537+internet*28.55262541+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Czech Republic
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*4.701811+tariff*1.84+ntb*1.215+volatility*2.691953128+pride*0.281506519+internet*28.25692931+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Denmark
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*5.475163+tariff*1.84+ntb*0.745+volatility*0.340246268+pride*0.549+internet*41.34524288+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Estonia
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*2.481693+tariff*1.84+ntb*0.795+volatility*0.333441163+pride*0.19146437+internet*28.14172771+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Finland
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*5.221525+tariff*1.84+ntb*0.625+volatility*0.333441163+pride*0.468375499+internet*32.20862913+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*France
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*6.558928+tariff*1.84+ntb*1.445+volatility*0.333441163+pride*0.27972028+internet*40.45605529+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Germany
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*5.459586+tariff*1.84+ntb*1.05+volatility*0.333441163+pride*0.193285528+internet*36.29027045+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Greece
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*5.402468+tariff*1.84+ntb*1.135+volatility*0.333441163+pride*0.27026594+internet*28.01729043+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Hungary
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*4.553324+tariff*1.84+ntb*0.845+volatility*1.32232485+pride*0.540531881+internet*26.29622855+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Ireland
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*5.194445+tariff*1.84+ntb*1.121+volatility*0.333441163+pride*0.246954077+internet*26.86011087+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Italy
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*6.086864+tariff*1.84+ntb*1.145+volatility*0.333441163+pride*0.414031621+internet*24.13749394+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Japan
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*8.393448+tariff*2.29+ntb*1.0213+volatility*2.821162781+pride*0.245410037+internet*29.48508263+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Latvia
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*2.646352+tariff*1.84+ntb*0.801+volatility*0.331329992+pride*0.173333333+internet*25.0480501+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Lesotho
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*0+lmsize*0.6205765+tariff*2.43+ntb*2.045+volatility*1.332526529+pride*0.669687401+internet*0.069997693+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Lithuania
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*3.077773+tariff*1.84+ntb*0.8+volatility*0.331976027+pride*0.176412289+internet*27.07308213+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Luxembourg
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*3.491251+tariff*1.84+ntb*1.42+volatility*0.333441163+pride*0.284+internet*33.57803838+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Malta
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*1.907466+tariff*1.84+ntb*0.97+volatility*0.333808456+pride*0.414031621+internet*35.61270766+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Netherlands
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*6.41867+tariff*1.84+ntb*0.975+volatility*0.333441163+pride*0.222222222+internet*40.56400966+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Poland
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*5.46642+tariff*1.84+ntb*1.025+volatility*1.131981247+pride*0.646290362+internet*18.89077029+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Portugal
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*3.514853+tariff*1.84+ntb*0.925+volatility*0.333441163+pride*0.602+internet*27.29185512+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Romania
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*4.234722+tariff*1.84+ntb*1.495+volatility*0.792999761+pride*0.413678619+internet*20.10935808+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Russia
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*0+lmsize*5.56337+tariff*5.37+ntb*2.5945+volatility*0.899271624+pride*0.314506679+internet*17.35553063+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Slovakia
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*3.6797+tariff*1.84+ntb*1.505+volatility*0.333441163+pride*0.384368994+internet*21.92620767+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Slovenia
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*3.500168+tariff*1.84+ntb*0.83+volatility*0.333441163+pride*0.535175072+internet*26.84000975+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*South Africa
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*0+lmsize*4.79371+tariff*3.87+ntb*2.08+volatility*1.301336064+pride*0.671154534+internet*3.128577964+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Spain
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*6.89851+tariff*1.84+ntb*1.4+volatility*0.333441163+pride*0.556575408+internet*27.95455346+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Sweden
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*5.878928+tariff*1.84+ntb*0.735+volatility*0.598974387+pride*0.379194631+internet*33.8660405+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Thailand
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*0+lmsize*3.538696+tariff*3.53+ntb*0.76+volatility*0.708861744+pride*0.835771763+internet*7.951266686+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*UK
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*6.166593+tariff*1.84+ntb*1.05+volatility*1.257316008+pride*0.246954077+internet*36.49857667+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*USA
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*1+lmsize*7.959791+tariff*1.69+ntb*1.289+volatility*0+pride*0.685657464+internet*30.7850862+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
*Uruguay
lincom _cons + se_w*0+sicdata*8+sicres*4+mon*0+annu*1+ts*0+cross*0+length*16+ltotal*5.133481273+lmidyear*31.5+sec*1+ter*0+deved*0+lmsize*3.191114+tariff*4.68+ntb*1.44+volatility*0.994809431+pride*0.651333333+internet*24.57229702+armx*0+darmx*0+army*0+asp*1+ols*0+corc*0+tsls*0+gmm*1+imcon*0+seas*0+impact*1.457+lcit*3.799227+pblshd*1
***********************
* Imbs & Mejan (2015) *
***********************
*World at means
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*0.8153639+lmsize*6.280964+tariff*6.869137+ntb*0.9405251+volatility*0.6384191+pride*0.4904672+internet*3.438876+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Euro area
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*9.078442+tariff*3.27+ntb*1.082473684+volatility*0.920610394+pride*0.342642418+internet*32.49205743+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Australia
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*5.098707+tariff*1.91+ntb*1.22+volatility*1.516772259+pride*0.6835115+internet*27.84277929+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Austria
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*5.640992+tariff*1.84+ntb*1.215+volatility*0.333441163+pride*0.2+internet*27.32468303+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Belgium
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*5.846625+tariff*1.84+ntb*1.4+volatility*0.333441163+pride*0.284+internet*35.75312806+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Brazil
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*0+lmsize*6.326818+tariff*7.79+ntb*2.3228+volatility*0.451791945+pride*0.499238707+internet*11.73692977+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Bulgaria
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*3.193209+tariff*1.84+ntb*1.365+volatility*0.33679998+pride*0.426917511+internet*20.50483617+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Colombia
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*0+lmsize*4.017878+tariff*4.21+ntb*2.47+volatility*0.707768155+pride*0.854951714+internet*10.52185379+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Cyprus 
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*2.822033+tariff*1.84+ntb*1.01+volatility*0.333808456+pride*0.513658537+internet*28.55262541+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Czech Republic
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*4.701811+tariff*1.84+ntb*1.215+volatility*2.691953128+pride*0.281506519+internet*28.25692931+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Denmark
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*5.475163+tariff*1.84+ntb*0.745+volatility*0.340246268+pride*0.549+internet*41.34524288+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Estonia
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*2.481693+tariff*1.84+ntb*0.795+volatility*0.333441163+pride*0.19146437+internet*28.14172771+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Finland
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*5.221525+tariff*1.84+ntb*0.625+volatility*0.333441163+pride*0.468375499+internet*32.20862913+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*France
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*6.558928+tariff*1.84+ntb*1.445+volatility*0.333441163+pride*0.27972028+internet*40.45605529+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Germany
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*5.459586+tariff*1.84+ntb*1.05+volatility*0.333441163+pride*0.193285528+internet*36.29027045+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Greece
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*5.402468+tariff*1.84+ntb*1.135+volatility*0.333441163+pride*0.27026594+internet*28.01729043+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Hungary
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*4.553324+tariff*1.84+ntb*0.845+volatility*1.32232485+pride*0.540531881+internet*26.29622855+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Ireland
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*5.194445+tariff*1.84+ntb*1.121+volatility*0.333441163+pride*0.246954077+internet*26.86011087+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Italy
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*6.086864+tariff*1.84+ntb*1.145+volatility*0.333441163+pride*0.414031621+internet*24.13749394+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Japan
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*8.393448+tariff*2.29+ntb*1.0213+volatility*2.821162781+pride*0.245410037+internet*29.48508263+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Latvia
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*2.646352+tariff*1.84+ntb*0.801+volatility*0.331329992+pride*0.173333333+internet*25.0480501+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Lesotho
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*0+lmsize*0.6205765+tariff*2.43+ntb*2.045+volatility*1.332526529+pride*0.669687401+internet*0.069997693+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Lithuania
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*3.077773+tariff*1.84+ntb*0.8+volatility*0.331976027+pride*0.176412289+internet*27.07308213+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Luxembourg
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*3.491251+tariff*1.84+ntb*1.42+volatility*0.333441163+pride*0.284+internet*33.57803838+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Malta
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*1.907466+tariff*1.84+ntb*0.97+volatility*0.333808456+pride*0.414031621+internet*35.61270766+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Netherlands
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*6.41867+tariff*1.84+ntb*0.975+volatility*0.333441163+pride*0.222222222+internet*40.56400966+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Poland
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*5.46642+tariff*1.84+ntb*1.025+volatility*1.131981247+pride*0.646290362+internet*18.89077029+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Portugal
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*3.514853+tariff*1.84+ntb*0.925+volatility*0.333441163+pride*0.602+internet*27.29185512+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Romania
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*4.234722+tariff*1.84+ntb*1.495+volatility*0.792999761+pride*0.413678619+internet*20.10935808+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Russia
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*0+lmsize*5.56337+tariff*5.37+ntb*2.5945+volatility*0.899271624+pride*0.314506679+internet*17.35553063+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Slovakia
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*3.6797+tariff*1.84+ntb*1.505+volatility*0.333441163+pride*0.384368994+internet*21.92620767+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Slovenia
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*3.500168+tariff*1.84+ntb*0.83+volatility*0.333441163+pride*0.535175072+internet*26.84000975+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*South Africa
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*0+lmsize*4.79371+tariff*3.87+ntb*2.08+volatility*1.301336064+pride*0.671154534+internet*3.128577964+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Spain
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*6.89851+tariff*1.84+ntb*1.4+volatility*0.333441163+pride*0.556575408+internet*27.95455346+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Sweden
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*5.878928+tariff*1.84+ntb*0.735+volatility*0.598974387+pride*0.379194631+internet*33.8660405+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Thailand
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*0+lmsize*3.538696+tariff*3.53+ntb*0.76+volatility*0.708861744+pride*0.835771763+internet*7.951266686+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*UK
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*6.166593+tariff*1.84+ntb*1.05+volatility*1.257316008+pride*0.246954077+internet*36.49857667+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*USA
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*1+lmsize*7.959791+tariff*1.69+ntb*1.289+volatility*0+pride*0.685657464+internet*30.7850862+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
*Uruguay
lincom _cons + se_w*0+sicdata*7+sicres*1+mon*0+annu*1+ts*0+cross*0+length*9+ltotal*6.222576+lmidyear*31.5+sec*0+ter*0+deved*0+lmsize*3.191114+tariff*4.68+ntb*1.44+volatility*0.994809431+pride*0.651333333+internet*24.57229702+armx*0+darmx*0+army*0+asp*1+ols*1+corc*0+tsls*0+gmm*0+imcon*0+seas*0+impact*2.881+lcit*3.341094+pblshd*1
