*PUZZLE.DO  Sep 2010 for Stata version 11
*used for "How to Solve the Price Puzzle? A Meta-Analysis" 
*To run, you need file puzzla.dta and add-ons xtmrho (http://fmwww.bc.edu/repec/bocode/x/xtmrho.ado) and estout (http://fmwww.bc.edu/repec/bocode/e/estout.zip) 

clear
log using "puzzle.log", replace
use "puzzle.dta", clear
set more off
set scheme s2mono

*replace se=(up+low)/2       //alternative measure of standard error

replace res=100*res
replace se=100*se
************************************************************************************************************
g prec=1/se
g t=res/se
************************************************************************************************************
*FUNNEL PLOTS
************************************************************************************************************
g funcut=30
g funlow=-5
g funupp=5
scatter prec res if prec<funcut & (res<funupp & res>funlow)& horizon==3, t1title("3 months", box bexpand)  msize(*1)  msymbol(oh) saving(3,replace)
scatter prec res if prec<funcut & (res<funupp & res>funlow)& horizon==6, t1title("6 months", box bexpand)  msize(*1)  msymbol(oh) saving(6,replace)
scatter prec res if prec<funcut & (res<funupp & res>funlow)& horizon==12, t1title("12 months", box bexpand) msize(*1)  msymbol(oh) saving(12,replace)
scatter prec res if prec<funcut & (res<funupp & res>funlow)& horizon==18, t1title("18 months", box bexpand) msize(*1)  msymbol(oh) saving(18,replace)
scatter prec res if prec<funcut & (res<funupp & res>funlow)& horizon==36,  t1title("36 months", box bexpand) msize(*1)  msymbol(oh) saving(36,replace)
scatter prec res if prec<funcut & (res<funupp & res>funlow)& horizon~=88 & horizon~=99 , t1title("All horizons", box bexpand) msize(*0.75) msymbol(oh) saving(all,replace)
graph combine all.gph 3.gph 6.gph 12.gph 18.gph 36.gph , row(2) ycommon xcommon imargin(0 0 0 0) saving(funnel, replace)

************************************************************************************************************
*FAT-PET tests
************************************************************************************************************
eststo: reg t prec if horizon==3, vce(cluster idstudy)
eststo: reg t prec if horizon==6, vce(cluster idstudy)
eststo: reg t prec if horizon==12, vce(cluster idstudy)
eststo: reg t prec if horizon==18, vce(cluster idstudy)
eststo: reg t prec if horizon==36, vce(cluster idstudy)
esttab using biasOLS.tex, se booktabs replace compress title(Test of publication bias and true effect, OLS\label{tab:all}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("3 Months" "6 Months" "12 Months" "18 months" "36 Months") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) b(3) se(3) label nonumber nogaps scalars(chi2_c) width(1\hsize)
eststo clear

eststo: xtmixed t prec if horizon==3 || idstudy:
xtmrho
eststo: xtmixed t prec if horizon==6 || idstudy:
xtmrho
eststo: xtmixed t prec if horizon==12 || idstudy:
xtmrho
eststo: xtmixed t prec if horizon==18 || idstudy:
xtmrho
eststo: xtmixed t prec if horizon==36 || idstudy:
xtmrho
esttab using biasME.tex, se booktabs replace compress title(Test of publication bias and true effect, Mixed-effects multilevel\label{tab:all}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("3 Months" "6 Months" "12 Months" "18 months" "36 Months") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) b(3) se(3) label nonumber nogaps scalars(chi2_c) width(1\hsize)
eststo clear

*************************************************************************************************************
*Definitions of variables for meta-regression
*************************************************************************************************************
gen monthly=0
replace monthly=1 if freq==12
gen avgyear=((syear+eyear)/2)-2000
gen timespan=(eyear-syear)     
gen lagsf=lags/freq
gen studyage=2010-yearpub+0.5
gen cits=citations/studyage
gen lncits=ln(1+cits)
replace yearpub=yearpub-2000           
gen policy=0
replace policy=1 if ministry==1 | imf_bis_oecd==1 
gen lnend_variab=ln(end_variab)
gen lnobs=ln(nobs)

replace vol=sqrt(vol) // standard deviation
replace gdppc=ln(gdppc) //log gdp level

replace findev=findev/100
replace open=open/100

local allvariables growth gdppc inf vol findev open indep gdpdeflator monthly interp timespan df lnobs avgyear lagsf lag_sel com single money foreign trend seasonal tot_variab lnend_variab ea_ip ea_gap ea_oth bvar favar svar sign lncits ci_boot ci_mc if_isi if_repec native cb onlycb policy academia yearpub  //list of variables

foreach x of varlist `allvariables' {
				gen `x'_se = `x' /se
}

*************************************************************************************************************
*Meta-analysis by countries
*************************************************************************************************************
*metan res se if horizon==3, by(country) random nograph
*drop_*
*metan res se if horizon==6, by(country) random nograph
*drop_*
*metan res se if horizon==12, by(country) random nograph
*drop_*
*metan res se if horizon==18, by(country) random nograph
*drop_*
*metan res se if horizon==36, by(country) random nograph
*drop_*
*************************************************************************************************************
*Labels
*************************************************************************************************************
label variable growth_se "GDP growth"
label variable gdppc_se "GDP per capita"
label variable inf_se "Inflation"
label variable vol_se "Inflation volatility"
label variable findev_se "Financial dev."
label variable open_se "Openness"
label variable indep_se "CB Independence"
label variable gdpdeflator_se "GDP deflator"
label variable monthly_se "Monthly"
label variable interp_se "Interpolated"
label variable timespan_se "Time span"
label variable lnobs_se "Observations"
*label variable nobs_se "Observations"
label variable avgyear_se "Average year"
label variable lagsf_se "Lags"
label variable lag_sel_se "Lag selection"
label variable com_se "Commodity"
label variable single_se "Single"
label variable money_se "Money"
label variable foreign_se "Foreign"
label variable trend_se "Time trend"
label variable seasonal_se "Seasonal"
label variable tot_variab_se "Total variables"
label variable lnend_variab_se "Variables"
label variable ea_ip_se "Industrial prod."
label variable ea_gap_se "Output gap"
label variable ea_oth_se "Other"
label variable bvar_se "BVAR"
label variable favar_se "FAVAR"
label variable svar_se "SVAR"
label variable sign_se "Sign restrictions"
label variable ci_boot "Bootstrap"
label variable ci_mc "Monte Carlo"
label variable lncits_se "Study citations"
label variable if_repec_se "Impact Repec"
label variable if_isi_se "Impact ISI"
label variable cb_se "Central banker" 
label variable academia_se "Acedemia"
label variable native_se "Native"
label variable policy_se "Policymaker"
label variable yearpub_se "Publication year"

*************************************************************************************************************
*Summary statistics
*************************************************************************************************************
estpost summarize t prec `allvariables' if horizon==3 | horizon==6 | horizon==12 |horizon==18 |horizon==36 & t~=.
esttab using summary.tex, booktabs replace compress width(1\hsize) title(Summary statistics of regression variables\label{tab:summary}) cells("mean sd min max") nonumber nomtitle nogaps
eststo clear
collin prec `allvariables' 
correl prec `allvariables' 

*************************************************************************************************************
*General model
*************************************************************************************************************
eststo: reg t prec gdppc_se growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se lagsf_se com_se single_se money_se foreign_se trend_se seasonal_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se lncits_se if_repec_se cb_se policy_se native_se yearpub_se if horizon==3, vce(cluster idstudy) 
test gdppc_se lagsf_se trend_se seasonal_se money_se lncits_se if_repec_se native_se yearpub_se
eststo: reg t prec gdppc_se growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se lagsf_se com_se single_se money_se foreign_se trend_se seasonal_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se lncits_se if_repec_se cb_se policy_se native_se yearpub_se if horizon==6, vce(cluster idstudy) 
test gdppc_se lagsf_se trend_se seasonal_se money_se lncits_se if_repec_se native_se yearpub_se
eststo: reg t prec gdppc_se growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se lagsf_se com_se single_se money_se foreign_se trend_se seasonal_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se lncits_se if_repec_se cb_se policy_se native_se yearpub_se if horizon==12, vce(cluster idstudy) 
test gdppc_se lagsf_se trend_se seasonal_se money_se lncits_se if_repec_se native_se yearpub_se
eststo: reg t prec gdppc_se growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se lagsf_se com_se single_se money_se foreign_se trend_se seasonal_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se lncits_se if_repec_se cb_se policy_se native_se yearpub_se if horizon==18, vce(cluster idstudy) 
test gdppc_se lagsf_se trend_se seasonal_se money_se lncits_se if_repec_se native_se yearpub_se
eststo: reg t prec gdppc_se growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se lagsf_se com_se single_se money_se foreign_se trend_se seasonal_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se lncits_se if_repec_se cb_se policy_se native_se yearpub_se if horizon==36, vce(cluster idstudy) 
test gdppc_se lagsf_se trend_se seasonal_se money_se lncits_se if_repec_se native_se yearpub_se
esttab using generalOLS.tex, se booktabs replace compress title(MRA, OLS\label{tab:all}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("3 Months" "6 Months" "12 Months" "18 months" "36 Months") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear

eststo: xtmixed t prec gdppc_se growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se lagsf_se com_se single_se money_se foreign_se trend_se seasonal_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se lncits_se if_repec_se cb_se policy_se native_se yearpub_se if horizon==3 ||idstudy:
test gdppc_se lagsf_se trend_se seasonal_se money_se lncits_se if_repec_se native_se yearpub_se
eststo: xtmixed t prec gdppc_se growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se lagsf_se com_se single_se money_se foreign_se trend_se seasonal_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se lncits_se if_repec_se cb_se policy_se native_se yearpub_se if horizon==6 ||idstudy: 
test gdppc_se lagsf_se trend_se seasonal_se money_se lncits_se if_repec_se native_se yearpub_se
eststo: xtmixed t prec gdppc_se growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se lagsf_se com_se single_se money_se foreign_se trend_se seasonal_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se lncits_se if_repec_se cb_se policy_se native_se yearpub_se if horizon==12 ||idstudy: 
test gdppc_se lagsf_se trend_se seasonal_se money_se lncits_se if_repec_se native_se yearpub_se
eststo: xtmixed t prec gdppc_se growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se lagsf_se com_se single_se money_se foreign_se trend_se seasonal_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se lncits_se if_repec_se cb_se policy_se native_se yearpub_se if horizon==18 ||idstudy:
test gdppc_se lagsf_se trend_se seasonal_se money_se lncits_se if_repec_se native_se yearpub_se
eststo: xtmixed t prec gdppc_se growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se lagsf_se com_se single_se money_se foreign_se trend_se seasonal_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se lncits_se if_repec_se cb_se policy_se native_se yearpub_se if horizon==36 ||idstudy:
test gdppc_se lagsf_se trend_se seasonal_se money_se lncits_se if_repec_se native_se yearpub_se
esttab using generalME.tex, se booktabs replace compress title(MRA, Mixed Effects\label{tab:all}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("3 Months" "6 Months" "12 Months" "18 months" "36 Months") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear

*************************************************************************************************************
*Specific model
*************************************************************************************************************
eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==3, vce(cluster idstudy)
predict res1 if horizon==3,resid
eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==6, vce(cluster idstudy)
predict res2 if horizon==6,resid
eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==12, vce(cluster idstudy)
predict res3 if horizon==12,resid
eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==18, vce(cluster idstudy)
predict res4 if horizon==18,resid
eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==36, vce(cluster idstudy)
predict res5 if horizon==36,resid
esttab using specificOLS.tex, se booktabs replace compress title(MRA, OLS\label{tab:all}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("3 Months" "6 Months" "12 Months" "18 months" "36 Months") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) b(3) se(3) label nonumber nogaps width(1\hsize)
eststo clear

eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==3  || idstudy: 
xtmrho
estimates store m1
predict res6 if horizon==3, resid
predict res6_std if horizon==3, rstandard
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==6  || idstudy: 
xtmrho
estimates store m2
predict res7 if horizon==6, resid
predict res7_std if horizon==6, rstandard
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==12 || idstudy: 
xtmrho
estimates store m3
predict res8 if horizon==12, resid
predict res8_std if horizon==12, rstandard
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==18 || idstudy: 
xtmrho
estimates store m4
predict res9 if horizon==18, resid
predict res9_std if horizon==18, rstandard
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==36 || idstudy: 
xtmrho
estimates store m5
predict res10 if horizon==36, resid
predict res10_std if horizon==36, rstandard
esttab using specificME.tex, se booktabs replace compress title(MRA, OLS\label{tab:all}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("3 Months" "6 Months" "12 Months" "18 months" "36 Months") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) b(3) se(3) label nonumber nogaps width(1\hsize)
eststo clear

swilk res1-res10  //normality test - Shapiro-Wilk
sktest res1-res10 //normality test - Skewness and kurtosis

qnorm res6_std
qnorm res7_std
qnorm res8_std
qnorm res9_std
qnorm res10_std

drop res1-res10_std

*************************************************************************************************************
*Best Practice
*************************************************************************************************************
quietly xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==3 || idstudy: 
lincom prec + 2.668301*growth_se + 7.748488*inf_se + 6.233974*vol_se + .8368237*findev_se + .4598406*open_se + .7735787*indep_se + 6.298949*lnobs_se + 4*avgyear_se + 0*gdpdeflator_se +  1*single_se + 1*com_se + 1*foreign_se + 4.875197*lnend_variab_se + 0*ea_ip_se + 1*ea_gap_se + 0*ea_oth_se + 1*bvar_se + 0*favar_se + 1*svar_se + 0*sign_se + .4510718*cb_se + .054986*policy_se //3 months
quietly xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==6 || idstudy: 
lincom prec + 2.668301*growth_se + 7.748488*inf_se + 6.233974*vol_se + .8368237*findev_se + .4598406*open_se + .7735787*indep_se + 6.298949*lnobs_se + 4*avgyear_se + 0*gdpdeflator_se +  1*single_se + 1*com_se + 1*foreign_se + 4.875197*lnend_variab_se + 0*ea_ip_se + 1*ea_gap_se + 0*ea_oth_se + 1*bvar_se + 0*favar_se + 1*svar_se + 0*sign_se + .4510718*cb_se + .054986*policy_se //6 months
quietly xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==12 || idstudy: 
lincom prec + 2.668301*growth_se + 7.748488*inf_se + 6.233974*vol_se + .8368237*findev_se + .4598406*open_se + .7735787*indep_se + 6.298949*lnobs_se +4*avgyear_se + 0*gdpdeflator_se +  1*single_se + 1*com_se + 1*foreign_se + 4.875197*lnend_variab_se + 0*ea_ip_se + 1*ea_gap_se + 0*ea_oth_se + 1*bvar_se + 0*favar_se + 1*svar_se + 0*sign_se + .4510718*cb_se + .054986*policy_se //12 months
quietly xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==18 || idstudy:
lincom prec + 2.668301*growth_se + 7.748488*inf_se + 6.233974*vol_se + .8368237*findev_se + .4598406*open_se + .7735787*indep_se + 6.298949*lnobs_se +4*avgyear_se + 0*gdpdeflator_se +  1*single_se + 1*com_se + 1*foreign_se + 4.875197*lnend_variab_se + 0*ea_ip_se + 1*ea_gap_se + 0*ea_oth_se + 1*bvar_se + 0*favar_se + 1*svar_se + 0*sign_se + .4510718*cb_se + .054986*policy_se //18 months
quietly xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==36 || idstudy: 
lincom prec + 2.668301*growth_se + 7.748488*inf_se + 6.233974*vol_se + .8368237*findev_se + .4598406*open_se + .7735787*indep_se + 6.298949*lnobs_se +4*avgyear_se + 0*gdpdeflator_se +  1*single_se + 1*com_se + 1*foreign_se + 4.875197*lnend_variab_se + 0*ea_ip_se + 1*ea_gap_se + 0*ea_oth_se + 1*bvar_se + 0*favar_se + 1*svar_se + 0*sign_se + .4510718*cb_se + .054986*policy_se //36 months

quietly reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==3, vce(cluster idstudy) 
lincom prec + 2.668301*growth_se + 7.748488*inf_se + 6.233974*vol_se + .8368237*findev_se + .4598406*open_se + .7735787*indep_se + 6.298949*lnobs_se + 4*avgyear_se + 0*gdpdeflator_se +  1*single_se + 1*com_se + 1*foreign_se + 4.875197*lnend_variab_se + 0*ea_ip_se + 1*ea_gap_se + 0*ea_oth_se + 1*bvar_se + 0*favar_se + 1*svar_se + 0*sign_se + .4510718*cb_se + .054986*policy_se //3 months
quietly reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==6, vce(cluster idstudy)
lincom prec + 2.668301*growth_se + 7.748488*inf_se + 6.233974*vol_se + .8368237*findev_se + .4598406*open_se + .7735787*indep_se + 6.298949*lnobs_se + 4*avgyear_se +0*gdpdeflator_se +   1*single_se + 1*com_se + 1*foreign_se + 4.875197*lnend_variab_se + 0*ea_ip_se + 1*ea_gap_se + 0*ea_oth_se + 1*bvar_se + 0*favar_se + 1*svar_se + 0*sign_se + .4510718*cb_se + .054986*policy_se //6 months
quietly reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==12, vce(cluster idstudy)
lincom prec + 2.668301*growth_se + 7.748488*inf_se + 6.233974*vol_se + .8368237*findev_se + .4598406*open_se + .7735787*indep_se + 6.298949*lnobs_se +4*avgyear_se +0*gdpdeflator_se +   1*single_se + 1*com_se + 1*foreign_se + 4.875197*lnend_variab_se + 0*ea_ip_se + 1*ea_gap_se + 0*ea_oth_se + 1*bvar_se + 0*favar_se + 1*svar_se + 0*sign_se + .4510718*cb_se + .054986*policy_se //12 months
quietly reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==18, vce(cluster idstudy)
lincom prec + 2.668301*growth_se + 7.748488*inf_se + 6.233974*vol_se + .8368237*findev_se + .4598406*open_se + .7735787*indep_se + 6.298949*lnobs_se +4*avgyear_se +0*gdpdeflator_se +   1*single_se + 1*com_se + 1*foreign_se + 4.875197*lnend_variab_se + 0*ea_ip_se + 1*ea_gap_se + 0*ea_oth_se + 1*bvar_se + 0*favar_se + 1*svar_se + 0*sign_se + .4510718*cb_se + .054986*policy_se //18 months
quietly reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==36, vce(cluster idstudy)
lincom prec + 2.668301*growth_se + 7.748488*inf_se + 6.233974*vol_se + .8368237*findev_se + .4598406*open_se + .7735787*indep_se + 6.298949*lnobs_se +4*avgyear_se +0*gdpdeflator_se +   1*single_se + 1*com_se + 1*foreign_se + 4.875197*lnend_variab_se + 0*ea_ip_se + 1*ea_gap_se + 0*ea_oth_se + 1*bvar_se + 0*favar_se + 1*svar_se + 0*sign_se + .4510718*cb_se + .054986*policy_se //36 months

*************************************************************************************************************
*Robustness checks and LR tests
*************************************************************************************************************
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==3  || idcountry: ||idauthor:  ||idstudy:  
xtmrho
estimates store m1a
lrtest m1 m1a

eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==6  || idcountry: ||idauthor:  ||idstudy: 
xtmrho
estimates store m2a
lrtest m2 m2a

quietly: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==12 ||idstudy: , mle
estimates store m3mle

eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==12  || idcountry: ||idauthor:  ||idstudy: , mle //restricted maximum likelihood did not converge, therefore maximum likelihood used
xtmrho
estimates store m3a
lrtest m3mle m3a

eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==18   || idcountry: ||idauthor:  ||idstudy: 
xtmrho
estimates store m4a
lrtest m4 m4a

eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==36  || idcountry: ||idauthor:  ||idstudy: 
xtmrho
estimates store m5a
lrtest m5 m5a

esttab using check1.tex, se booktabs replace compress title(Country - Author - Study\label{tab:c1}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("3 Months" "6 Months" "12 Months" "18 months" "36 Months") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) b(3) se(3) label nonumber nogaps width(1\hsize)
eststo clear

eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==3  || idcountry: ||idstudy:  
xtmrho
estimates store m1b
lrtest m1 m1b

eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==6  || idcountry: ||idstudy:  
xtmrho
estimates store m2b
lrtest m2 m2b

eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==12  || idcountry: ||idstudy: , mle //restricted maximum likelihood did not converge, therefore maximum likelihood used
xtmrho
estimates store m3b
lrtest m3mle m3b

eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==18   || idcountry: ||idstudy: 
xtmrho
estimates store m4b
lrtest m4 m4b

eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==36  || idcountry: ||idstudy: 
xtmrho
estimates store m5b
lrtest m5 m5b
esttab using check2.tex, se booktabs replace compress title(Country - Study\label{tab:c1}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("3 Months" "6 Months" "12 Months" "18 months" "36 Months") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) b(3) se(3) label nonumber nogaps width(1\hsize)
eststo clear

eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==3   ||idauthor: ||idstudy: 
xtmrho
estimates store m1c
lrtest m1 m1c
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==6  ||idauthor: ||idstudy:  
xtmrho
estimates store m2c
lrtest m2 m2c
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==12  ||idauthor: ||idstudy: 
xtmrho
estimates store m3c
lrtest m3 m3c
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==18   ||idauthor: ||idstudy:
xtmrho
estimates store m4c
lrtest m4 m4c
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==36  ||idauthor: ||idstudy: 
xtmrho
estimates store m5c
lrtest m5 m5c
esttab using check3.tex, se booktabs replace compress title(Author - Study\label{tab:c2}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("3 Months" "6 Months" "12 Months" "18 months" "36 Months") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) b(3) se(3) label nonumber nogaps width(1\hsize)
eststo clear

eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==3   ||idcountry:
xtmrho
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==6  ||idcountry: 
xtmrho
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==12  ||idcountry: 
xtmrho
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==18   ||idcountry:
xtmrho
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==36  ||idcountry:
xtmrho
esttab using check4.tex, se booktabs replace compress title(Country\label{tab:c3}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("3 Months" "6 Months" "12 Months" "18 months" "36 Months") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) b(3) se(3) label nonumber nogaps width(1\hsize)
eststo clear

eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==3   ||idauthor:
xtmrho
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==6  ||idauthor: 
xtmrho
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==12  ||idauthor:
xtmrho
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==18   ||idauthor:
xtmrho
eststo: xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==36  ||idauthor:
xtmrho
esttab using check5.tex, se booktabs replace compress title(Author\label{tab:c4}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("3 Months" "6 Months" "12 Months" "18 months" "36 Months") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) b(3) se(3) label nonumber nogaps width(1\hsize)
eststo clear

eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se  single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==3, vce(cluster idcountry)
eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se  single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==6, vce(cluster idcountry)
eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se  single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==12, vce(cluster idcountry)
eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se  single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==18, vce(cluster idcountry)
eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==36, vce(cluster idcountry)
esttab using check6.tex, se booktabs replace compress title(OLS country clustered\label{tab:c5}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("3 Months" "6 Months" "12 Months" "18 months" "36 Months") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label b(3) se(3) nonumber nogaps width(1\hsize)
eststo clear

eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se  single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==3, vce(cluster idauthor)
eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se  single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==6, vce(cluster idauthor)
eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se  single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==12, vce(cluster idauthor)
eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se  single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==18, vce(cluster idauthor)
eststo: reg t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==36, vce(cluster idauthor)
esttab using check7.tex, se booktabs replace compress title(OLS author clustered\label{tab:c6}) mgroups("Horizon", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("3 Months" "6 Months" "12 Months" "18 months" "36 Months") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label b(3) se(3) nonumber nogaps width(1\hsize)
eststo clear

*************************************************************************************************************
*Random sample method
*************************************************************************************************************
set seed 1234

/*forvalues i= 1(1)1000 {
preserve
sample 80, by(horizon) //changing sample of 80% of the total sample

quietly xtmixed t prec if horizon==3 || idstudy:
quietly parmest,format(estimate p) list(,) saving("D:\work\meta\stata\randomsample\MR3FAT`i'",replace)
quietly xtmixed t prec if horizon==6 || idstudy:
quietly parmest,format(estimate p) list(,) saving("D:\work\meta\stata\randomsample\MR6FAT`i'",replace)
quietly xtmixed t prec if horizon==12 || idstudy:
quietly parmest,format(estimate p) list(,) saving("D:\work\meta\stata\randomsample\MR12FAT`i'",replace)
quietly xtmixed t prec if horizon==18 || idstudy:
quietly parmest,format(estimate p) list(,) saving("D:\work\meta\stata\randomsample\MR18FAT`i'",replace)
quietly xtmixed t prec if horizon==36 || idstudy:
quietly parmest,format(estimate p) list(,) saving("D:\work\meta\stata\randomsample\MR36FAT`i'",replace)
restore
}

forvalues i= 1(1)1000 {
preserve
sample 80, by(horizon) //changing sample of 80% of the total sample
quietly xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==3  || idstudy: 
quietly parmest,format(estimate p) list(,) saving("D:\work\meta\stata\randomsample\MRA\MR3MRA`i'",replace)
quietly xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==6  || idstudy: 
quietly parmest,format(estimate p) list(,) saving("D:\work\meta\stata\randomsample\MRA\MR6MRA`i'",replace)
quietly xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==12 || idstudy: 
quietly parmest,format(estimate p) list(,) saving("D:\work\meta\stata\randomsample\MRA\MR12MRA`i'",replace)
quietly xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==18 || idstudy: 
quietly parmest,format(estimate p) list(,) saving("D:\work\meta\stata\randomsample\MRA\MR18MRA`i'",replace)
quietly xtmixed t prec growth_se inf_se vol_se findev_se open_se indep_se lnobs_se avgyear_se gdpdeflator_se single_se com_se foreign_se lnend_variab_se ea_ip_se ea_gap_se ea_oth_se bvar_se favar_se svar_se sign_se cb_se policy_se if horizon==36 || idstudy: 
quietly parmest,format(estimate p) list(,) saving("D:\work\meta\stata\randomsample\MRA\MR36MRA`i'",replace)
restore
}
*/

window manage close graph
log close
exit, clear
