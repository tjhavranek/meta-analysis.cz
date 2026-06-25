************************************************************************************
* MONETARY POLICY AND HOUSE PRICES

* The code reproduces the results of the following paper: 
* Dominika Ehrenbergerova, Josef Bajzik, Tomas Havranek (2022), "When Does Monetary Policy Sway House Prices? A Meta-Analysis." Charles University, Prague.
* http://meta-analysis.cz/house_prices/
* The code contains parts to be run in R and Matlab!
* Date: 31/05/2022
* Corresponding author: Dominika Ehrenbergerova, dominika.ehrenbergerova@cnb.cz.
************************************************************************************


************************************************************************************
* STATA MODULES
************************************************************************************
/*
ssc install winsor2, replace
ssc install ivreg2, replace
ssc install estout, replace
ssc install ranktest, replace
ssc install boottest, replace
*/

************************************************************************************
* FOLDERS
************************************************************************************
* Set your folders depending on where you store the data and where you want to put export output

global dir_hp "C:\Users\Dominika\Dropbox\house_prices"
global dir_reg "$dir_hp\reg_output"
global dir_graphs "$dir_hp\graphs"


cd "O:\Dokoncene projekty\2020\WP 14-2020_meta_HP\04_estimation\IMF"


************************************************************************************
* UPLOAD DATA + DATA ADJUSTMENTS
************************************************************************************

use "$dir_hp\house_prices.dta", clear

*Multiply by 10 get values in %
replace est=100*est
gen se_avg = (SE_l + SE_u)/2
replace se_avg =100*se_avg
gen prec_avg = 1/se_avg
gen t_avg = est/se_avg
rename se_avg SE
rename t_avg t
rename prec_avg prec


*Means and medians
replace horizon = 24 if horizon > 16 & horizon!=.

bysort horizon: egen estmean = mean(est)
bysort horizon: egen estmed = median(est)
bysort horizon: egen semean = mean(SE)
bysort horizon: egen semed = median(SE)

gen lbmean = estmean - semean
gen ubmean = estmean + semean
gen lbmed = estmed - semed
gen ubmed = estmed + semed

bysort idstudy horizon: egen precmed = median(prec)
bysort idstudy horizon: egen tmed = median(t)

bysort idstudy horizon: egen perstudy = count(est)
gen  invperstudy = 1/perstudy

*Horizon dummies
gen dummy1=0
replace dummy1=1 if horizon==1 & est!=.
gen dummy2=0
replace dummy2=1 if horizon==2 & est!=.
gen dummy4=0
replace dummy4=1 if horizon==4 & est!=.
gen dummy8=0
replace dummy8=1 if horizon==8 & est!=.
gen dummy12=0
replace dummy12=1 if horizon==12 & est!=.
gen dummy16=0
replace dummy16=1 if horizon==16 & est!=.
gen dummy24=0
replace dummy24=1 if horizon==24 & est!=.

*Variables in logs
replace midyear=ln(midyear-1975+1)
replace pubyear=ln(pubyear-2001+1)
replace start =ln(start-1947+1)
replace end=ln(end-1982+1)
replace nobs=ln(nobs)
replace length_y = ln(length_y)
replace cross_units = ln(cross_units)
replace time_units = ln(time_units)
replace no_vars = ln(no_vars)
replace citations = ln(citations +1)

*Transformation of external vars
gen nonrec = srlr_restr+ nonrecursive
gen ext_boom_ratio = ext_boom/length_y  
replace ext_income=ln(ext_income) 
replace ext_dwell = ln(ext_dwell) 
replace ext_maturity = ln(ext_maturity)


************************************************************************************************************
*KEEP IF INLEVELS==1 ! - robustness check with the growth levels from appendix is towards the end of the code
************************************************************************************************************
keep if inlevels==1

************************************************************************************************************
*SUMMARY STATISTICS
************************************************************************************************************

tabstat est , by(horizon)


************************************************************************************************************
* MEAN IRF (FIGURE 1)
************************************************************************************************************
twoway (line estmean horizon, sort) (line lbmean horizon, sort lpattern(dash) lcolor(navy) ) (line ubmean horizon, sort lpattern(dash) lcolor(navy) ), xtitle("Quarters after a 1pp increase in the interest rate") ytitle("Mean response of house prices (%)") graphregion(color(white)) legend(order(1 "Mean response" 2 "+-1SE") ) 
graph export "$dir_graphs\mean_irf.pdf", replace


************************************************************************************************************
* HISTOGRAMS (FIGURE 2)
************************************************************************************************************
hist est if est>=-5  & est<=2, width(0.2) xscale(range(-5 2)) xlabel(-5(1)2)   frequency bcolor(edkbg) t1title("All horizons", box bexpand) xline(0, lcolor(black)) xtitle("") ytitle("") graphregion(color(white)) saving(allhist,replace)
hist est if est>-5  & est<=2 & horizon == 1, width(0.2) xscale(range(-5 2)) xlabel(-5(1)2)    frequency bcolor(edkbg) t1title("1 quarter", box bexpand) xline(0, lcolor(black)) xtitle("") ytitle("") graphregion(color(white)) saving(1hist,replace)
hist est if est>-5  & est<=2 & horizon == 2, width(0.2) xscale(range(-5 2)) xlabel(-5(1)2)     frequency bcolor(edkbg) t1title("2 quarters", box bexpand) xline(0, lcolor(black)) xtitle("") ytitle("") graphregion(color(white)) saving(2hist,replace)
hist est if est>-5  & est<=2 & horizon == 4, width(0.2) xscale(range(-5 2)) xlabel(-5(1)2)    frequency bcolor(edkbg) t1title("4 quarters", box bexpand) xline(0, lcolor(black)) xtitle("") ytitle("") graphregion(color(white)) saving(4hist,replace)
hist est if est>-5  & est<=2 & horizon == 8, width(0.2) xscale(range(-5 2)) xlabel(-5(1)2)     frequency bcolor(edkbg) t1title("8 quarters", box bexpand) xline(0, lcolor(black))  xtitle("") ytitle("") graphregion(color(white)) saving(8hist,replace)
hist est if est>-5  & est<=2 & horizon == 12, width(0.2) xscale(range(-5 2)) xlabel(-5(1)2)    frequency bcolor(edkbg) t1title("12 quarters", box bexpand) xline(0, lcolor(black)) xtitle("") ytitle("") graphregion(color(white)) saving(12hist,replace)
graph combine allhist.gph 1hist.gph 2hist.gph 4hist.gph 8hist.gph 12hist.gph , row(2)    imargin(0 0 0 0) l1("Frequency", size(small)) b1("Estimate of the response of house prices (%)", size(small))  graphregion(color(white)) saving(hist, replace)
graph export "$dir_graphs\hist.pdf", replace


************************************************************************************************************
* FUNNEL PLOTS (FIGURE 3)
************************************************************************************************************
g funcut=30
g funlow=-5
g funupp=5

scatter prec est if prec<funcut  & (est<funupp & est>funlow)& (horizon==1 | horizon == 0), t1title("1 quarter", box bexpand) xtitle("") ytitle("") msize(*1)  msymbol(oh) graphregion(color(white)) saving(1,replace)
scatter prec est if prec<funcut  & (est<funupp & est>funlow)& horizon==2, t1title("2 quarters", box bexpand) xtitle("") ytitle("") msize(*1)  msymbol(oh) graphregion(color(white)) saving(2,replace)
scatter prec est if prec<funcut  & (est<funupp & est>funlow)& horizon==4, t1title("4 quarters", box bexpand) xtitle("") ytitle("") msize(*1)  msymbol(oh) graphregion(color(white)) saving(4,replace)
scatter prec est if prec<funcut  & (est<funupp & est>funlow)& horizon==8, t1title("8 quarters", box bexpand) xtitle("") ytitle("") msize(*1)  msymbol(oh) graphregion(color(white)) saving(8,replace)
scatter prec est if prec<funcut  & (est<funupp & est>funlow)& horizon==12,  t1title("12 quarters", box bexpand) xtitle("") ytitle("") msize(*1)  msymbol(oh) graphregion(color(white)) saving(12,replace)
scatter prec est if prec<funcut  & (est<funupp & est>funlow)& horizon==16,  t1title("16 quarters", box bexpand) xtitle("") ytitle("")  msize(*1)  msymbol(oh) graphregion(color(white)) saving(16,replace)
scatter prec est if prec<funcut  & (est<funupp & est>funlow), t1title("All horizons", box bexpand) xtitle("") ytitle("") msize(*0.75) msymbol(oh) graphregion(color(white)) saving(all,replace)
graph combine all.gph 1.gph 2.gph 4.gph 8.gph 12.gph , row(2) ycommon xcommon imargin(0 0 0 0) l1("Precision of the estimate (1/SE)", size(small)) b1("Estimate of the response of house prices (%)", size(small)) graphregion(color(white)) saving(funnel, replace)
graph export "$dir_graphs/funnels.pdf", replace


************************************************************************************************************
* PUBLICATION BIAS LINEAR TESTS (TABLE 1)
************************************************************************************************************
xtset idstudy

eststo: ivreg2 est SE  if horizon==1, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE if t>-50 & horizon==2, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE if t>-50 & horizon==4, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE if t>-50 & horizon==8, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE if t>-50 & horizon==12, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE if t>-50 & horizon==16, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
esttab using "$dir_reg\bias.tex", se booktabs replace compress title(Test of publication bias and true effect, OLS\label{tab:all}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("All horizons" "1 Quarter" "2 Quarters" "4 Quarters" "8 Quarters" "12 Quarters" "16 Quarters" ) addnote("Meta-response variable: Estimate") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) b(3) se(3) label nonumber nogaps scalars(chi2_c) width(1\hsize)
eststo clear

* Weighted OLS
eststo: ivreg2 est SE [pweight=prec] if t>-50 & horizon==1, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE [pweight=prec] if t>-50 & horizon==2, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE [pweight=prec] if t>-50 & horizon==4, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE [pweight=prec] if t>-50 & horizon==8, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE [pweight=prec] if t>-50 & horizon==12, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE [pweight=prec] if t>-50 & horizon==16, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
esttab using "$dir_reg\bias_pweightprec.tex", se booktabs replace compress title(Test of publication bias and true effect, OLS\label{tab:all}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("All horizons" "1 Quarter" "2 Quarters" "4 Quarters" "8 Quarters" "12 Quarters" "16 Quarters" ) addnote("Meta-response variable: Estimate") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) b(3) se(3) label nonumber nogaps scalars(chi2_c) width(1\hsize)
eststo clear


********************************************************************************************
* PUBLICATION BIAS - ANDREWS AND KASY (2019) (TABLE 1)
********************************************************************************************

* Export the data, then use Matlab code (Matlab replication files, 2019 version) available here:
* https://scholar.harvard.edu/iandrews/publications/identification-and-correction-publication-bias
* Open AllApplications.m mfile
* Copy their application == 13:
* Parameter setting in Matlab:
/*
vcutoff = 1.645; %(2nd version: vcutoff = 1;)
cutoffs=[-1.645 0 1.645]';   %(2nd version: cutoffs=[-1 0 1]';)
%Use a step function which may by asymmetric around zero
symmetric=0;
symmetric_p=0;
%starting values for optimization
asymmetric_likelihood_spec=2; %Use a t model for latent distribution of true effects
Psihat0=[0,1,1,1,1,1]; 
*/

egen id = group(idstudy)
export delimited est SE id using "$dir_reg\hor1.csv" if est!=. & horizon==1, novarnames nolabel replace
export delimited est SE id using "$dir_reg\hor2.csv" if est!=. & horizon==2, novarnames nolabel replace
export delimited est SE id using "$dir_reg\hor4.csv" if est!=. & horizon==4, novarnames nolabel replace
export delimited est SE id using "$dir_reg\hor8.csv" if est!=. & horizon==8, novarnames nolabel replace
export delimited est SE id using "$dir_reg\hor12.csv" if est!=. & horizon==12, novarnames nolabel replace
export delimited est SE id using "$dir_reg\hor16.csv" if est!=. & horizon==16, novarnames nolabel replace
drop id


********************************************************************************************
* PUBLICATION BIAS - FURUKAWA (2019) (TABLE 1)
********************************************************************************************
* Run in R 
* See the end of this code


********************************************************************************************
* PUBLICATION BIAS - P-UNIFORM* - VAN AERT and VAN ASSEN (2021) (TABLE 1)
********************************************************************************************
* Run in R 
* See the end of this code


*************************************************************************************************************
* HETEROGENEITY
*************************************************************************************************************
*************************************************************************************************************
* COUNTRY-SPECIFIC IRFs (FIGURE 5)
*************************************************************************************************************

bysort horizon idcountry: egen estmean2 = mean(est)
bysort horizon idcountry: egen semean2 = mean(SE)
gen lbmean2  = estmean2 - semean2
gen ubmean2  = estmean2 + semean2
twoway (line estmean2 horizon if idcountry==45, sort xtitle("") legend(off) t1title("United States", box bexpand))  (line lbmean2 horizon if idcountry==45, sort lcolor(navy) lpattern(dash)) (line ubmean2 horizon if idcountry==45, sort lcolor(navy) lpattern(dash)), graphregion(color(white)) saving(USirf,replace)
twoway (line estmean2 horizon if idcountry==36, sort xtitle("") legend(off) t1title("Italy", box bexpand))          (line lbmean2 horizon if idcountry==36, sort lcolor(navy) lpattern(dash)) (line ubmean2 horizon if idcountry==36, sort lcolor(navy) lpattern(dash)), graphregion(color(white)) saving(ITirf,replace)
twoway (line estmean2 horizon if idcountry==44, sort xtitle("") legend(off) t1title("United Kingdom", box bexpand)) (line lbmean2 horizon if idcountry==44, sort lcolor(navy) lpattern(dash)) (line ubmean2 horizon if idcountry==44, sort lcolor(navy) lpattern(dash)), graphregion(color(white)) saving(UKirf,replace)
twoway (line estmean2 horizon if idcountry==43, sort xtitle("") legend(off) t1title("Switzerland", box bexpand))    (line lbmean2 horizon if idcountry==43, sort lcolor(navy) lpattern(dash)) (line ubmean2 horizon if idcountry==43, sort lcolor(navy) lpattern(dash)), graphregion(color(white)) saving(CHirf,replace)
twoway (line estmean2 horizon if idcountry==30, sort xtitle("") legend(off) t1title("Finland", box bexpand))        (line lbmean2 horizon if idcountry==30, sort lcolor(navy) lpattern(dash)) (line ubmean2 horizon if idcountry==30, sort lcolor(navy) lpattern(dash)), graphregion(color(white)) saving(FIirf,replace)
twoway (line estmean2 horizon if idcountry==42, sort xtitle("") legend(off) t1title("Sweden", box bexpand))         (line lbmean2 horizon if idcountry==42, sort lcolor(navy) lpattern(dash)) (line ubmean2 horizon if idcountry==42, sort lcolor(navy) lpattern(dash)), graphregion(color(white)) saving(SEirf,replace)
twoway (line estmean2 horizon if idcountry==31, sort xtitle("") legend(off) t1title("France", box bexpand))         (line lbmean2 horizon if idcountry==31, sort lcolor(navy) lpattern(dash)) (line ubmean2 horizon if idcountry==31, sort lcolor(navy) lpattern(dash)), graphregion(color(white)) saving(FRirf,replace)
twoway (line estmean2 horizon if idcountry==32, sort xtitle("") legend(off) t1title("Germany", box bexpand))        (line lbmean2 horizon if idcountry==32, sort lcolor(navy) lpattern(dash)) (line ubmean2 horizon if idcountry==32, sort lcolor(navy) lpattern(dash)), graphregion(color(white)) saving(DEirf,replace)
graph combine USirf.gph ITirf.gph UKirf.gph CHirf.gph FIirf.gph SEirf.gph FRirf.gph DEirf.gph, row(2)  xcommon l1("Mean response of house prices (%)", size(small)) b1("Quarters after a 1pp increase in the interest rate", size(small)) imargin(0 0 0 0) graphregion(color(white)) saving(countryirf, replace)
graph export "$dir_graphs/country_response.pdf", replace


*************************************************************************************************************
* SUMMARY STATISTICS (TABLE C1)
*************************************************************************************************************

sum est SE monthly	panel length_y	 midyear ///
gdp_defl foreign_ir	credit	 consump res_invest	ms	exchan	lrir real_hp lags_q	time_trend	///
BVAR sign_restr_hp sign_restr_other nonrec ///
citations	impact	journalyn	///
ext_crisis1	ext_ir_level ext_ir_long ext_spread	ext_floating ext_tourism_yoy ext_income	ext_creditgdp ext_populgr ext_pti_std ext_hp_long ext_permits ext_maturity	ext_ownership ext_boom


*************************************************************************************************************
* BMA nad FMA (FIGURES 6, 7, C1, Tables 2, C2)
*************************************************************************************************************
* Export, then run in R

* BMA BASELINE - 4Q
preserve
order est SE  monthly    panel length_y  midyear gdp_defl foreign_ir  credit  consump res_invest ms exchan lrir real_hp lags_q time_trend  BVAR     sign_restr_hp sign_restr_other   citations  impact journalyn ext_crisis1 ext_ir_level ext_ir_long  ext_spread ext_floating    ext_tourism_yoy ext_income ext_infl ext_creditgdp ext_populgr  ext_pti_std    ext_hp_long    ext_permits ext_maturity ext_ownership  ext_boom  nonrec
keep if horizon==4 
keep est SE  monthly    panel length_y  midyear gdp_defl foreign_ir  credit  consump res_invest ms exchan lrir real_hp lags_q time_trend  BVAR     sign_restr_hp sign_restr_other   citations  impact journalyn ext_crisis1 ext_ir_level ext_ir_long  ext_spread ext_floating    ext_tourism_yoy ext_income ext_infl ext_creditgdp ext_populgr  ext_pti_std    ext_hp_long    ext_permits ext_maturity ext_ownership  ext_boom  nonrec
saveold  "${dir_reg}\bma_hor4_final.dta", version(12) replace
restore


* BMA - ALL horizons
preserve
order est SE  monthly    panel length_y  midyear gdp_defl foreign_ir  credit  consump res_invest ms exchan lrir real_hp lags_q time_trend  BVAR     sign_restr_hp sign_restr_other   citations  impact journalyn ext_crisis1 ext_ir_level ext_ir_long  ext_spread ext_floating    ext_tourism_yoy ext_income ext_infl ext_creditgdp ext_populgr  ext_pti_std    ext_hp_long    ext_permits ext_maturity ext_ownership  ext_boom  nonrec
keep est SE  monthly    panel length_y  midyear gdp_defl foreign_ir  credit  consump res_invest ms exchan lrir real_hp lags_q time_trend  BVAR     sign_restr_hp sign_restr_other   citations  impact journalyn ext_crisis1 ext_ir_level ext_ir_long  ext_spread ext_floating    ext_tourism_yoy ext_income ext_infl ext_creditgdp ext_populgr  ext_pti_std    ext_hp_long    ext_permits ext_maturity ext_ownership  ext_boom  nonrec dummy2 dummy4 dummy8 dummy12 dummy16 dummy24
saveold  "${dir_reg}\bma_all_final.dta", version(12) replace
restore


/*  Beginning of the R Code for BMA and FMA

rm(list=ls())

# loading library #################

# In case one has never used BMS package, it needs to be manually installed to the library from https://cran.r-project.org/src/contrib/Archive/BMS/  
library(BMS)  
library(foreign)

# set directory   #################
setwd("C:/Users/cnb/Dropbox/house_prices/IMFER rev")

# loading data   #################

data_nw_hor4        = read.dta("bma_hor4_final.dta")
data_nw_all         = read.dta("bma_all_final.dta")

colnames(data_nw_hor4)  <- c("Estimate", "St. Error","Monthly","Panel","Length","Midpoint","GDP Defl.","Foreign IR","Credit","Consumption","Resid. Invest.", "Money Supply","Exch. rate","Long-run IR","Real HP","Lags","Time trend","BVAR", "Sign restr. HP", "Sign restr. other","Citations","Impact","Journal","Country-level: Crisis","Country-level: IR","Country-level: Prolonged low IR","Country-level: Spread","Country-level: Floating", "Country-level: Tourism yoy","Country-level: Income", "Country-level: Inflation", "Country-level: Credit-to-GDP", "Country-level: Popul. Growth", "Country-level: PTI", "Country-level: Prolonged High HP","Country-level: Permits", "Country-level: Maturity", "Country-level: Ownership", "Country-level: Econ. Boom","Nonrecursive")
colnames(data_nw_all)   <- c("Estimate", "St. Error","Monthly","Panel","Length","Midpoint","GDP Defl.","Foreign IR","Credit","Consumption","Resid. Invest.", "Money Supply","Exch. rate","Long-run IR","Real HP","Lags","Time trend","BVAR", "Sign restr. HP", "Sign restr. other","Citations","Impact","Journal","Country-level: Crisis","Country-level: IR","Country-level: Prolonged low IR","Country-level: Spread","Country-level: Floating", "Country-level: Tourism yoy","Country-level: Income", "Country-level: Inflation", "Country-level: Credit-to-GDP", "Country-level: Popul. Growth", "Country-level: PTI", "Country-level: Prolonged High HP","Country-level: Permits", "Country-level: Maturity", "Country-level: Ownership", "Country-level: Econ. Boom","Nonrecursive", "Dummy 2Q", "Dummy 4Q","Dummy 8Q","Dummy 12Q","Dummy 16Q","Dummy 24Q")

data_nw_hor4 <- data_nw_hor4[complete.cases(data_nw_hor4), ]
data_nw_all  <- data_nw_all[complete.cases(data_nw_all), ]


#Estimation #################################
# Parameters for in-sample estimation #

#burn_       = 0.5e8
#iter_       = 1e8
burn_       = 1e6
iter_       = 3e6
gprior      = "UIP"
modelprior  = "uniform"
order_PIP   = F
separator   = ","


devtools::install_git("https://gitlab.com/matmosr/dilutbms2")
library(dilutBMS2)

# Baseline (Figure 6 and Table 2) ##################
BMA_nw_hor4_dil  = dilutBMS2::bms(data_nw_hor4, burn=burn_,iter=iter_, g=gprior, mprior="dilut", nmodel=10000, mcmc="bd", user.int=FALSE)
BMA_nw_hor4_res_dil<-coef(BMA_nw_hor4_dil,std.coefs=F, order.by.pip = order_PIP, exact=T,include.constant = T)
write.table(BMA_nw_hor4_res_dil,"BMA_baseline_dilut.csv",sep=separator)
par(mar = c(2, 0.1, 2, 2))
image(BMA_nw_hor4_dil, cex=0.7, xlab="", main="")
summary(BMA_nw_hor4_dil)
plot(BMA_nw_hor4_dil)



#Prior sensitivity (Figure 7) ##################

#BMA_nw_hor4_2  = bms(data_nw_hor4, burn=burn_,iter=iter_, g="UIP", mprior="uniform", nmodel=5000, mcmc="bd", user.int=FALSE)
BMA_nw_hor4_3  = bms(data_nw_hor4, burn=burn_,iter=iter_, g="HQ", mprior="random", nmodel=5000, mcmc="bd", user.int=FALSE)
par(mfrow = c(1, 1))
par(mar = c(4, 2.5, 2, 2))
plotComp("UIP and Dilution"=BMA_nw_hor4_dil,"UIP and Uniform"=BMA_nw_hor4,"HQ and Random"=BMA_nw_hor4_3,  add.grid=F,cex.xaxis=0.7)
plotComp("UIP and Uniform"=BMA_nw_hor4,"HQ and Random"=BMA_nw_hor4_3,  add.grid=F,cex.xaxis=0.7)




# Appendix ####################
# With all horizons at once (Figure C1)

BMA_nw_all_dil  = dilutBMS2::bms(data_nw_all, burn=burn_,iter=iter_, g=gprior, mprior="dilut", nmodel=10000, mcmc="bd", user.int=FALSE)
BMA_nw_all_res_dil<-coef(BMA_nw_all_dil,std.coefs=F, order.by.pip = order_PIP, exact=T,include.constant = T)
write.table(BMA_nw_all_res_dil,"BMA_allhor_dilut.csv",sep=separator)
image(BMA_nw_all_dil, cex=0.7, xlab="", main="")
summary(BMA_nw_all_dil)
plot(BMA_nw_all_dil)


# With interaction variable (Figure C2)

data_nw_hor4$interaction <-data_nw_hor4$`Country-level: Prolonged High HP`* data_nw_hor4$`Country-level: Crisis`
colnames(data_nw_hor4)  <- c("Estimate", "St. Error","Monthly","Panel","Length","Midpoint","GDP Defl.","Foreign IR","Credit","Consumption","Resid. Invest.", "Money Supply","Exch. rate","Long-run IR","Real HP","Lags","Time trend","BVAR", "Sign restr. HP", "Sign restr. other","Citations","Impact","Journal","Country-level: Crisis","Country-level: IR","Country-level: Prolonged low IR","Country-level: Spread","Country-level: Floating", "Country-level: Tourism yoy","Country-level: Income", "Country-level: Inflation", "Country-level: Credit-to-GDP", "Country-level: Popul. Growth", "Country-level: PTI", "Country-level: Prolonged High HP","Country-level: Permits", "Country-level: Maturity", "Country-level: Ownership", "Country-level: Econ. Boom","Nonrecursive","Crisis_ProlongedHP Inter.")

BMA_nw_hor4_inter  = dilutBMS2::bms(data_nw_hor4, burn=burn_,iter=iter_, g=gprior, mprior="dilut", nmodel=10000, mcmc="bd", user.int=FALSE)
BMA_nw_hor4_res_inter<-coef(BMA_nw_hor4_inter,std.coefs=F, order.by.pip = order_PIP, exact=T,include.constant = T)
write.table(BMA_nw_hor4_res_inter,"BMA_baseline_inter.csv",sep=separator)
par(mar = c(2, 0.1, 2, 2))
image(BMA_nw_hor4_inter, cex=0.7, xlab="", main="")
summary(BMA_nw_hor4_inter)
plot(BMA_nw_hor4_inter)




#  FMA (Table C2)  ########################################

# Mallows Model Averaging Program 

# Loading libraries
library(foreign)
library(xtable)
library(LowRankQP)

rm(list=ls())

mydata <- read.dta("bma_hor4_final.dta", convert.dates=TRUE, convert.factors=TRUE, 
                   missing.type=TRUE, convert.underscore=TRUE, warn.missing.labels=TRUE)

colnames(data_nw_hor4)  <- c("Estimate", "St. Error","Monthly","Panel","Length","Midpoint","GDP Defl.","Foreign IR","Credit","Consumption","Resid. Invest.", "Money Supply","Exch. rate","Long-run IR","Real HP","Lags","Time trend","BVAR", "Sign restr. HP", "Sign restr. other","Citations","Impact","Journal","Country-level: Crisis","Country-level: IR","Country-level: Prolonged low IR","Country-level: Spread","Country-level: Floating", "Country-level: Tourism yoy","Country-level: Income", "Country-level: Inflation", "Country-level: Credit-to-GDP", "Country-level: Popul. Growth", "Country-level: PTI", "Country-level: Prolonged High HP","Country-level: Permits", "Country-level: Maturity", "Country-level: Ownership", "Country-level: Econ. Boom","Nonrecursive")


#deleting missing observations
mydata <-na.omit(mydata)
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


MMA.fls <- data.frame(MMA.fls)
t <- as.data.frame(MMA.fls$Coefficient/MMA.fls$Sd..Err)
MMA.fls$pv <-round( (1-apply(as.data.frame(apply(t,1,abs)), 1, pnorm))*2,3)
MMA.fls$names <- rownames(MMA.fls)
names <- c(colnames(mydata))
names <- c(names,"const_")
MMA.fls <- MMA.fls[match(names, MMA.fls$names),]
MMA.fls$names <- NULL
MMA.fls


library(xtable)
xtable(MMA.fls,digits=c(0,3,3,3))

separator   = ";"
write.table(MMA.fls,"FMA.csv",sep=separator)


*/ // The end of code for BMA and FMA in R 


********************************************************************************************
*FREQUENTIST ESTIMATION -  OLS (TABLE C3)
********************************************************************************************

eststo: ivreg2   est  SE      panel length_y  midyear gdp_defl foreign_ir  credit  consump res_invest ms exchan lrir real_hp lags_q time_trend  BVAR    sign_restr_hp sign_restr_other  nonrec citations  impact journalyn ext_crisis1 ext_ir_level ext_ir_long  ext_spread ext_floating    ext_tourism_yoy  ext_infl ext_creditgdp ext_populgr            ext_maturity ext_ownership  ext_permits ext_pti_std ext_hp_long ext_boom  if horizon==1 , cluster (idstudy idcountry)

eststo: ivreg2   est  SE      panel length_y  midyear gdp_defl foreign_ir  credit  consump res_invest ms exchan lrir real_hp lags_q time_trend  BVAR    sign_restr_hp sign_restr_other  nonrec citations  impact journalyn ext_crisis1 ext_ir_level ext_ir_long  ext_spread ext_floating    ext_tourism_yoy  ext_infl ext_creditgdp ext_populgr            ext_maturity ext_ownership  ext_permits ext_pti_std ext_hp_long ext_boom if horizon==2 , cluster (idstudy idcountry)

eststo: ivreg2   est  SE      panel length_y  midyear gdp_defl foreign_ir  credit  consump res_invest ms exchan lrir real_hp lags_q time_trend  BVAR    sign_restr_hp sign_restr_other  nonrec citations  impact journalyn ext_crisis1 ext_ir_level ext_ir_long  ext_spread ext_floating    ext_tourism_yoy  ext_infl ext_creditgdp ext_populgr            ext_maturity ext_ownership  ext_permits ext_pti_std ext_hp_long ext_boom  if horizon==4 , cluster (idstudy idcountry) 

eststo: ivreg2   est  SE      panel length_y  midyear gdp_defl foreign_ir  credit  consump res_invest ms exchan lrir real_hp lags_q time_trend  BVAR    sign_restr_hp sign_restr_other  nonrec citations  impact journalyn ext_crisis1 ext_ir_level ext_ir_long  ext_spread ext_floating    ext_tourism_yoy  ext_infl ext_creditgdp ext_populgr            ext_maturity ext_ownership  ext_permits ext_pti_std ext_hp_long ext_boom  if horizon==8 , cluster (idstudy idcountry)  

eststo: ivreg2   est  SE      panel length_y  midyear gdp_defl foreign_ir  credit  consump res_invest ms exchan lrir real_hp lags_q time_trend  BVAR    sign_restr_hp sign_restr_other  nonrec citations  impact journalyn ext_crisis1 ext_ir_level ext_ir_long  ext_spread ext_floating    ext_tourism_yoy  ext_infl ext_creditgdp ext_populgr            ext_maturity ext_ownership  ext_permits ext_pti_std ext_hp_long ext_boom if horizon==12, cluster (idstudy idcountry)

eststo: ivreg2   est  SE      panel length_y  midyear gdp_defl foreign_ir  credit  consump res_invest ms exchan lrir real_hp lags_q time_trend  BVAR    sign_restr_hp sign_restr_other  nonrec citations  impact journalyn ext_crisis1 ext_ir_level ext_ir_long  ext_spread ext_floating    ext_tourism_yoy  ext_infl ext_creditgdp ext_populgr            ext_maturity ext_ownership  ext_permits ext_pti_std ext_hp_long ext_boom  if horizon==16, cluster (idstudy idcountry) 
 
esttab using "${dir_reg}\OLS_all_horizons.tex", se booktabs replace compress title(MRA, OLS\label{tab:all}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("All" "1 Quarter" "2 Quarters" "4 Quarters" "8 Quarters" "12 Quarters" "16 Quarters") addnote("Meta-response variable: Estimate") star(* 0.10 ** 0.05 *** 0.01) label nonumber nogaps width(1\hsize)
eststo clear



************************************************************************************
*CALIPER TEST (TABLE B1)
************************************************************************************

*CALIPER TEST with interval=0.1;  t=1
gen tcal = 0
replace tcal = 1  if  abs(t)>=1                  & t!=.
eststo: reg tcal  if  abs(t)>=0.9 & abs(t)<1.1   & t!=.  , level(90)
eststo: reg tcal  if  abs(t)>=0.9 & abs(t)<=1.1  & t!=. & horizon==1, level(90)
eststo: reg tcal  if  abs(t)>=0.9 & abs(t)<=1.1  & t!=. & horizon==2, level(90)
eststo: reg tcal  if  abs(t)>=0.9 & abs(t)<=1.1  & t!=. & horizon==4, level(90)
eststo: reg tcal  if  abs(t)>=0.9 & abs(t)<=1.1  & t!=. & horizon==8, level(90)
eststo: reg tcal  if  abs(t)>=0.9 & abs(t)<=1.1  & t!=. & horizon==12, level(90)
eststo: reg tcal  if  abs(t)>=0.9 & abs(t)<=1.1  & t!=. & horizon==16, level(90)
esttab  using caliper68_01.tex,  compress replace ci
eststo clear
 
*CALIPER TEST with interval=0.3;  t=1
eststo: reg tcal  if  abs(t)>=0.7 & abs(t)<1.3   & t!=. , level(90)
eststo: reg tcal  if  abs(t)>=0.7 & abs(t)<=1.3  & t!=. & horizon==1, level(90)
eststo: reg tcal  if  abs(t)>=0.7 & abs(t)<=1.3  & t!=. & horizon==2, level(90)
eststo: reg tcal  if  abs(t)>=0.7 & abs(t)<=1.3  & t!=. & horizon==4, level(90)
eststo: reg tcal  if  abs(t)>=0.7 & abs(t)<=1.3  & t!=. & horizon==8, level(90)
eststo: reg tcal  if  abs(t)>=0.7 & abs(t)<=1.3  & t!=. & horizon==12, level(90)
eststo: reg tcal  if  abs(t)>=0.7 & abs(t)<=1.3  & t!=. & horizon==16, level(90)
esttab  using caliper68_03.tex,  compress replace ci
eststo clear

*CALIPER TEST with interval=0.5;  t=1
eststo: reg tcal  if  abs(t)>=0.5 & abs(t)<1.5   & t!=. , level(90)
eststo: reg tcal  if  abs(t)>=0.5 & abs(t)<=1.5  & t!=. & horizon==1, level(90)
eststo: reg tcal  if  abs(t)>=0.5 & abs(t)<=1.5  & t!=. & horizon==2, level(90)
eststo: reg tcal  if  abs(t)>=0.5 & abs(t)<=1.5  & t!=. & horizon==4, level(90)
eststo: reg tcal  if  abs(t)>=0.5 & abs(t)<=1.5  & t!=. & horizon==8, level(90)
eststo: reg tcal  if  abs(t)>=0.5 & abs(t)<=1.5  & t!=. & horizon==12, level(90)
eststo: reg tcal  if  abs(t)>=0.5 & abs(t)<=1.5  & t!=. & horizon==16, level(90)
esttab  using caliper68_05.tex,  compress replace ci
eststo clear


**************************************************************************************
* PUBLICATION BIAS - FURUKAWA, P-UNIFORM*, P-CURVE, TESTS BY ELLIOT (2021)
**************************************************************************************
* Prepare data for p-curve

	rename nobs lnobs
	gen nobs=exp(lnobs)
	gen  pval = (2 * ttail(nobs, abs(t)))
	gen variance = SE*SE

	keep  idstudy est SE variance  nobs lnobs pval  t horizon
	drop if est==.
	rename est TE  //est is renamed TE to match the notation with the original puniform* code, SE = seTE
	rename SE seTE
	rename idstudy studlab
	save "$dir_reg\pcurve.dta", replace
	
* Prepare data for Furukawa, Elliot
	gen ptop1 = pval
	gen t_abs = abs(t)
	gen ttop = 2*(1 - normal(t_abs))
	sum ptop1 ttop
	replace ptop1 = ttop if ptop1==.
	drop if t==0 & missing(seTE)
	replace ptop1 = 0 if seTE==0 & ptop1==. & TE!=0    //zero changes, we do not have missing obs

	drop if ptop1 == .
	drop if ptop1 > 1
	egen id = group(studlab)
	
	levelsof horizon, local(levels) 
	foreach l of local levels {
	preserve
	keep if horizon == `l'
	export delimited using "$dir_reg\hp_clean_data_hor`l'.csv", replace
	restore
	export delimited using "$dir_reg\hp_clean_data.csv", replace
}


* HISTOGRAM OF P-VALUES (Figure B2)

	hist pval if pval<0.5 , width(0.02)  xline(0.01) xline(0.05) xline(0.1) frequency bcolor(edkbg) t1title("All horizons", box bexpand) xtitle("") ytitle("") graphregion(color(white))  saving(allpval,replace)
	hist pval if horizon==1 & pval<0.5, width(0.02)  xline(0.01) xline(0.05) xline(0.1) frequency bcolor(edkbg) t1title("1 quarter", box bexpand) xtitle("") ytitle("") graphregion(color(white))  saving(1pval,replace)
	hist pval if horizon==2 & pval<0.5, width(0.02)  xline(0.01) xline(0.05) xline(0.1) frequency bcolor(edkbg) t1title("2 quarters", box bexpand) xtitle("") ytitle("") graphregion(color(white))  saving(2pval,replace)
	hist pval if horizon==4 & pval<0.5, width(0.02)  xline(0.01) xline(0.05) xline(0.1) frequency bcolor(edkbg) t1title("4 quarters", box bexpand) xtitle("") ytitle("") graphregion(color(white))  saving(4pval,replace)
	hist pval if horizon==8 & pval<0.5, width(0.02)  xline(0.01) xline(0.05) xline(0.1) frequency bcolor(edkbg) t1title("8 quarters", box bexpand) xtitle("") ytitle("") graphregion(color(white))  saving(8pval,replace)
	hist pval if horizon==12 & pval<0.5, width(0.02)  xline(0.01) xline(0.05) xline(0.1) frequency bcolor(edkbg) t1title("12 quarters", box bexpand) xtitle("") ytitle("") graphregion(color(white))  saving(12pval,replace)
	hist pval if horizon==16 & pval<0.5, width(0.02)  xline(0.01) xline(0.05) xline(0.1) frequency bcolor(edkbg) t1title("16 quarters", box bexpand) xtitle("") ytitle("") graphregion(color(white))  saving(16pval,replace)
	graph combine allpval.gph 1pval.gph 2pval.gph 4pval.gph 8pval.gph 12pval.gph , row(2)  xcommon imargin(0 0 0 0) l1("Frequency", size(small)) b1("P-value", size(small)) graphregion(color(white))  saving(hist_pval, replace)
	graph export "$dir_graphs/hist_pval.pdf", replace

	
**************************************************************************************************
* Run in R Studio
* PUBLICATION BIAS - FURUKAWA (2021) (TABLE 1)
**************************************************************************************************

/*  Beginning of the R Code for Furukawa's Stem-based method

# Furukawa (2021)
# download R code (stem_method.R) to your directory from here: https://github.com/Chishio318/stem-based_method

setwd("C:/Users/Dominika/Dropbox/house_prices/04_estimation/reg_output")
source("stem_method.R") 
# est is renamed as TE to match the notation with original puniform code, SE = seTE

#hor1
data = read.csv("hp_clean_data_hor1.csv")
stem_results = stem(data$TE, data$seTE, param)
View(stem_results$estimates)

#hor2
data = read.csv("hp_clean_data_hor2.csv")
stem_results = stem(data$TE, data$seTE, param)
View(stem_results$estimates)

#hor4
data = read.csv("hp_clean_data_hor4.csv")
stem_results = stem(data$TE, data$seTE, param)
View(stem_results$estimates)

#hor8
data = read.csv("hp_clean_data_hor8.csv")
stem_results = stem(data$TE, data$seTE, param)
View(stem_results$estimates)

#hor12
data = read.csv("hp_clean_data_hor12.csv")
stem_results = stem(data$TE, data$seTE, param)
View(stem_results$estimates)

#hor16
data = read.csv("hp_clean_data_hor16.csv")
stem_results = stem(data$TE, data$seTE, param)
View(stem_results$estimates)

*/ // The end of the R Code for Furukawa's Stem-based method



******************************************************************************************************
* PUBLICATION BIAS - P-UNIFORM* and P-CURVE CODE IN R (TABLE 1, FIGURE B1) 
******************************************************************************************************

/*  Beginning of the R Code for P-uniform*

install.packages("puniform")
install.packages("tidyverse")
install.packages("meta")
install.packages("metafor")
install.packages("devtools")
devtools::install_github("MathiasHarrer/dmetar")

library(installr)
library(puniform)
library(metafor)
library(dmetar)
library(haven)
library(tidyverse)
library(meta)
library(questionr)
library(xlsx)

setwd("C:/Users/Dominika/Dropbox/house_prices/04_estimation/reg_output")

# P-UNIFORM* (TABLE 1 in the paper) ##########################

# t=1 (alpha=0.32),full,t+obs
data <- read_csv(file="hp_clean_data_hor1.csv")
unistar1<-puni_star(tobs = data$t, ni = data$nobs, alpha = 0.32, side = "left", method = "ML",
          control=list(stval.tau=0, max.iter=10000,tol=0.1,reps=10000,  verbose=TRUE))

data <- read_csv(file="hp_clean_data_hor2.csv")
unistar2<-puni_star(tobs = data$t, ni = data$nobs, alpha = 0.32, side = "left", method = "ML",
          control=list(stval.tau=0, max.iter=10000,tol=0.1,reps=10000,  verbose=TRUE))

data <- read_csv(file="hp_clean_data_hor4.csv")
unistar4<-puni_star(tobs = data$t, ni = data$nobs, alpha = 0.32, side = "left", method = "ML",
          control=list(stval.tau=0, max.iter=10000,tol=0.1,reps=10000,  verbose=TRUE))

data <- read_csv(file="hp_clean_data_hor8.csv")
unistar8<-puni_star(tobs = data$t, ni = data$nobs, alpha = 0.32, side = "left", method = "ML",
          control=list(stval.tau=0, max.iter=10000,tol=0.1,reps=10000,  verbose=TRUE))

data <- read_csv(file="hp_clean_data_hor12.csv")
unistar12<-puni_star(tobs = data$t, ni = data$nobs, alpha = 0.32, side = "left", method = "ML",
          control=list(stval.tau=0, max.iter=10000,tol=0.1,reps=10000, int=c(-1,1),  verbose=TRUE))

data <- read_csv(file="hp_clean_data_hor16.csv")
unistar16<-puni_star(tobs = data$t, ni = data$nobs, alpha = 0.32, side = "left", method = "ML",
          control=list(stval.tau=0, max.iter=10000,tol=0.1,reps=10000,  verbose=TRUE))

est <-c(unistar1$est,unistar2$est,unistar4$est,unistar8$est,unistar12$est,unistar16$est)
lb  <-c(unistar1$ci.lb,unistar2$ci.lb,unistar4$ci.lb,unistar8$ci.lb,unistar12$ci.lb,unistar16$ci.lb)
ub  <-c(unistar1$ci.ub,unistar2$ci.ub,unistar4$ci.ub,unistar8$ci.ub,unistar12$ci.ub,unistar16$ci.ub)
pval<-c(unistar1$pval.0,unistar2$pval.0,unistar4$pval.0,unistar8$pval.0,unistar12$pval.0,unistar16$pval.0)
results32<-cbind(est,lb,ub,pval)
View(results32)



# t=1.645 (alpha=0.1),full,t+obs
data <- read_csv(file="hp_clean_data_hor1.csv")
unistar1<-puni_star(tobs = data$t, ni = data$nobs, alpha = 0.1, side = "left", method = "ML",
                    control=list(stval.tau=0, max.iter=10000,tol=0.1,reps=10000,  verbose=TRUE))

data <- read_csv(file="hp_clean_data_hor2.csv")
unistar2<-puni_star(tobs = data$t, ni = data$nobs, alpha = 0.1, side = "left", method = "ML",
                    control=list(stval.tau=0, max.iter=10000,tol=0.1,reps=10000,  verbose=TRUE))

data <- read_csv(file="hp_clean_data_hor4.csv")
unistar4<-puni_star(tobs = data$t, ni = data$nobs, alpha = 0.1, side = "left", method = "ML",
                    control=list(stval.tau=0, max.iter=10000,tol=0.1,reps=10000, verbose=TRUE))

data <- read_csv(file="hp_clean_data_hor8.csv")
unistar8<-puni_star(tobs = data$t, ni = data$nobs, alpha = 0.1, side = "left", method = "ML",
                    control=list(stval.tau=0, max.iter=10000,tol=0.1,reps=10000, verbose=TRUE))

data <- read_csv(file="hp_clean_data_hor12.csv")
unistar12<-puni_star(tobs = data$t, ni = data$nobs, alpha = 0.1, side = "left", method = "ML",
                     control=list(stval.tau=0, max.iter=10000,tol=0.1,reps=10000,  verbose=TRUE))

data <- read_csv(file="hp_clean_data_hor16.csv")
unistar16<-puni_star(tobs = data$t, ni = data$nobs, alpha = 0.1, side = "left", method = "ML",
                     control=list(stval.tau=0, max.iter=10000,tol=0.1,reps=10000,  verbose=TRUE))

est<-c(unistar1$est,unistar2$est,unistar4$est,unistar8$est,unistar12$est,unistar16$est)
lb<-c(unistar1$ci.lb,unistar2$ci.lb,unistar4$ci.lb,unistar8$ci.lb,unistar12$ci.lb,unistar16$ci.lb)
ub<-c(unistar1$ci.ub,unistar2$ci.ub,unistar4$ci.ub,unistar8$ci.ub,unistar12$ci.ub,unistar16$ci.ub)
pval<-c(unistar1$pval.0,unistar2$pval.0,unistar4$pval.0,unistar8$pval.0,unistar12$pval.0,unistar16$pval.0)
results10<-cbind(est,lb,ub,pval)
View(results10)


write.xlsx(results10, file="puniform.xlsx", sheetName="results10", row.names=FALSE)
write.xlsx(results32, file="puniform.xlsx", sheetName="results32", append=TRUE, row.names=FALSE)



# P-CURVE  (Figure B1 in the paper) ##########################################

data <- read_dta("pcurve.dta")
View(data)

meta1 = metagen(TE,seTE, studlab=data$studlab, data=data,  level.ci = 0.9)
#pcurve(pcurve)
pcurve(meta1)
pcurve(data, effect.estimation = TRUE, N = data$nobs, dmin = -2, dmax = 0)

*/  //The end of code for P-uniform* in R



**************************************************************************************************
**************************************************************************************************
**************************************************************************************************
**************************************************************************************************
* PUBLICATION BIAS - WITH STUDIES IN HOUSE PRICE INFLATION RATES (Table B3)
**************************************************************************************************
* We need to start again with the full dataset

use "$dir_hp\house_prices.dta", clear

*Multiply by 10 get values in %
replace est=100*est
gen se_avg = (SE_l + SE_u)/2
replace se_avg =100*se_avg
gen prec_avg = 1/se_avg
gen t_avg = est/se_avg
rename se_avg SE
rename t_avg t
rename prec_avg prec


*Means and medians
replace horizon = 24 if horizon > 16 & horizon!=.

bysort horizon: egen estmean = mean(est)
bysort horizon: egen estmed = median(est)
bysort horizon: egen semean = mean(SE)
bysort horizon: egen semed = median(SE)

gen lbmean = estmean - semean
gen ubmean = estmean + semean
gen lbmed = estmed - semed
gen ubmed = estmed + semed

bysort idstudy horizon: egen precmed = median(prec)
bysort idstudy horizon: egen tmed = median(t)

bysort idstudy horizon: egen perstudy = count(est)
gen  invperstudy = 1/perstudy

*Horizon dummies
gen dummy1=0
replace dummy1=1 if horizon==1 & est!=.
gen dummy2=0
replace dummy2=1 if horizon==2 & est!=.
gen dummy4=0
replace dummy4=1 if horizon==4 & est!=.
gen dummy8=0
replace dummy8=1 if horizon==8 & est!=.
gen dummy12=0
replace dummy12=1 if horizon==12 & est!=.
gen dummy16=0
replace dummy16=1 if horizon==16 & est!=.
gen dummy24=0
replace dummy24=1 if horizon==24 & est!=.

*Variables in logs
replace midyear=ln(midyear-1975+1)
replace pubyear=ln(pubyear-2001+1)
replace start =ln(start-1947+1)
replace end=ln(end-1982+1)
replace nobs=ln(nobs)
replace length_y = ln(length_y)
replace cross_units = ln(cross_units)
replace time_units = ln(time_units)
replace no_vars = ln(no_vars)
replace citations = ln(citations +1)

*Transformation of external vars
gen nonrec = srlr_restr+ nonrecursive
gen ext_boom_ratio = ext_boom/length_y  
replace ext_income=ln(ext_income) 
replace ext_dwell = ln(ext_dwell) 
replace ext_maturity = ln(ext_maturity)


************************************************************************************************************
* PUBLICATION BIAS LINEAR TESTS (TABLE B3)
************************************************************************************************************
xtset idstudy

eststo: ivreg2 est SE  if horizon==1, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE if t>-50 & horizon==2, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE if t>-50 & horizon==4, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE if t>-50 & horizon==8, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE if t>-50 & horizon==12, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE if t>-50 & horizon==16, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
esttab using "$dir_reg\bias_growths.tex", se booktabs replace compress title(Test of publication bias and true effect, OLS\label{tab:all}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("All horizons" "1 Quarter" "2 Quarters" "4 Quarters" "8 Quarters" "12 Quarters" "16 Quarters" ) addnote("Meta-response variable: Estimate") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) b(3) se(3) label nonumber nogaps scalars(chi2_c) width(1\hsize)
eststo clear

* Weighted OLS
eststo: ivreg2 est SE [pweight=prec] if t>-50 & horizon==1 , cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE [pweight=prec] if t>-50 & horizon==2, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE [pweight=prec] if t>-50 & horizon==4, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE [pweight=prec] if t>-50 & horizon==8, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE [pweight=prec] if t>-50 & horizon==12 , cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
eststo: ivreg2 est SE [pweight=prec] if t>-50 & horizon==16, cluster (idstudy idcountry)
boottest SE, nograph
boottest _cons, nograph
esttab using "$dir_reg\bias_pweightprec_growths.tex", se booktabs replace compress title(Test of publication bias and true effect, OLS\label{tab:all}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("All horizons" "1 Quarter" "2 Quarters" "4 Quarters" "8 Quarters" "12 Quarters" "16 Quarters" ) addnote("Meta-response variable: Estimate") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) b(3) se(3) label nonumber nogaps scalars(chi2_c) width(1\hsize)
eststo clear


********************************************************************************************
* PUBLICATION BIAS - ANDREWS AND KASY (2019) (TABLE B3)
********************************************************************************************

* Export the data, then use Matlab code (Matlab replication files, 2019 version) available here:
* https://scholar.harvard.edu/iandrews/publications/identification-and-correction-publication-bias
* Open AllApplications.m mfile
* Copy their application == 13:
* Parameter setting in Matlab:
/*
vcutoff = 1.645; %(2nd version: vcutoff = 1;)
cutoffs=[-1.645 0 1.645]';   %(2nd version: cutoffs=[-1 0 1]';)
%Use a step function which may by asymmetric around zero
symmetric=0;
symmetric_p=0;
%starting values for optimization
asymmetric_likelihood_spec=2; %Use a t model for latent distribution of true effects
Psihat0=[0,1,1,1,1,1]; 
*/

egen id = group(idstudy)
export delimited est SE id using "$dir_reg\hor1_gr.csv" if est!=. & horizon==1, novarnames nolabel replace
export delimited est SE id using "$dir_reg\hor2_gr.csv" if est!=. & horizon==2, novarnames nolabel replace
export delimited est SE id using "$dir_reg\hor4_gr.csv" if est!=. & horizon==4, novarnames nolabel replace
export delimited est SE id using "$dir_reg\hor8_gr.csv" if est!=. & horizon==8, novarnames nolabel replace
export delimited est SE id using "$dir_reg\hor12_gr.csv" if est!=. & horizon==12, novarnames nolabel replace
export delimited est SE id using "$dir_reg\hor16_gr.csv" if est!=. & horizon==16, novarnames nolabel replace
drop id



**************************************************************************************
* PUBLICATION BIAS - FURUKAWA, P-UNIFORM*, P-CURVE, TESTS BY ELLIOT (2021)
**************************************************************************************
* Prepare data

	rename nobs lnobs
	gen nobs=exp(lnobs)
	gen  pval = (2 * ttail(nobs, abs(t)))
	gen variance = SE*SE

	keep  idstudy est SE variance  nobs lnobs pval  t horizon
	drop if est==.
	rename est TE  //est is renamed TE to match the notation with the original puniform* code, SE = seTE
	rename SE seTE
	rename idstudy studlab
	save "$dir_reg\pcurve_gr.dta", replace
	
	* Prepare for Elliot
	gen ptop1 = pval
	gen t_abs = abs(t)
	gen ttop = 2*(1 - normal(t_abs))
	sum ptop1 ttop
	replace ptop1 = ttop if ptop1==.
	drop if t==0 & missing(seTE)
	replace ptop1 = 0 if seTE==0 & ptop1==. & TE!=0    //zero changes, we do not have missing obs

	drop if ptop1 == .
	drop if ptop1 > 1
	egen id = group(studlab)
	
	levelsof horizon, local(levels) 
	foreach l of local levels {
	preserve
	keep if horizon == `l'
	export delimited using "$dir_reg\hp_clean_data_hor`l'_gr.csv", replace
	restore
	export delimited using "$dir_reg\hp_clean_data_gr.csv", replace
}

* Then, run the same code as for baseline Furukawa and p-uniform tests