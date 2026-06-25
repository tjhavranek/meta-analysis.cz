***************************************************************************************
***************************************************************************************
*********     How Puzzling Is the Forward Premium Puzzle? A Meta-Analysis      ********
***************************************************************************************
***************************************************************************************
* January 27, 2021

log using forward_win.log, replace
use "forward.dta", clear
xtset studyid
set more off

sum beta se

***************************************************************************************
***************************************************************************************
************************      WINSORIZING DATA     ************************************
***************************************************************************************
***************************************************************************************

winsor2 beta se, cuts(5 95) replace
gen tstat = beta/se
gen double inv_se = 1/se
gen double root=sqrt(sample_size_full)
gen double inv_root=1/root

bysort studyid: egen double nobs=count(beta) if lnspot==0
gen double inv_nobs=1/nobs if lnspot==0
drop nobs

bysort studyid: egen double nobs_lev=count(beta) if lnspot==1
gen double inv_nobs_lev=1/nobs_lev if lnspot==1
drop nobs_lev

***************************************************************************************
* Summary statistics
***************************************************************************************
sum beta se, detail
sum beta se if lnspot==0, detail
sum beta se if lnspot==1, detail

sum beta se advanced_currencies emerging_currencies german_mark french_franc british_pound italian_lira japanese_yen swiss_franc euro mixed_currencies european_currencies other_country_currencies asianmixed_country_currencies british_pound_base euro_base german_mark_base other_base shorter_horizon onemonth_horizon onemonth_oneyear_horizon oneyear_horizon longer_horizon daily_frequency weekly_frequency monthly_frequency other_frequency time_difference number_of_currencies sample_size overlapping_problem ols_method fixed_effects_method sur_method regime_switching_model other_technique controls spot_rate_percentage large_differential small_differential large_positive_premium low_negative_premium overvalued_currency undervalued_currency datastream_source bank_data_source dataresources_source other_source impact_factor citations firstdraft_year gdp exchange_rate_regime if lnspot==0
sum beta se advanced_currencies emerging_currencies german_mark french_franc british_pound italian_lira japanese_yen swiss_franc euro mixed_currencies european_currencies other_country_currencies asianmixed_country_currencies british_pound_base euro_base german_mark_base other_base shorter_horizon onemonth_horizon onemonth_oneyear_horizon oneyear_horizon longer_horizon daily_frequency weekly_frequency monthly_frequency other_frequency time_difference number_of_currencies sample_size overlapping_problem ols_method fixed_effects_method sur_method regime_switching_model other_technique controls spot_rate_percentage large_differential small_differential large_positive_premium low_negative_premium overvalued_currency undervalued_currency datastream_source bank_data_source dataresources_source other_source impact_factor citations firstdraft_year gdp exchange_rate_regime if lnspot==0 [aweight=inv_nobs]

mean beta if advanced_currencies ==1 & lnspot==0
mean beta if emerging_currencies ==1 & lnspot==0
mean beta if euro==1 & lnspot==0
mean beta if german_mark ==1 & lnspot==0
mean beta if british_pound==1 & lnspot==0
mean beta if french_franc ==1 & lnspot==0
mean beta if italian_lira ==1 & lnspot==0
mean beta if swiss_franc==1 & lnspot==0
mean beta if japanese_yen ==1 & lnspot==0
mean beta if european_currencies ==1 & lnspot==0
mean beta if asian_currencies ==1 & lnspot==0
mean beta if other_country_currencies ==1 & lnspot==0
mean beta if lnspot==0

mean beta [aweight=inv_nobs] if advanced_currencies ==1 & lnspot==0
mean beta [aweight=inv_nobs] if emerging_currencies ==1 & lnspot==0
mean beta [aweight=inv_nobs] if euro==1 & lnspot==0
mean beta [aweight=inv_nobs] if german_mark ==1 & lnspot==0
mean beta [aweight=inv_nobs] if british_pound==1 & lnspot==0
mean beta [aweight=inv_nobs] if french_franc ==1 & lnspot==0
mean beta [aweight=inv_nobs] if italian_lira ==1 & lnspot==0
mean beta [aweight=inv_nobs] if swiss_franc==1 & lnspot==0
mean beta [aweight=inv_nobs] if japanese_yen ==1 & lnspot==0
mean beta [aweight=inv_nobs] if european_currencies ==1 & lnspot==0
mean beta [aweight=inv_nobs] if asian_currencies ==1 & lnspot==0
mean beta [aweight=inv_nobs] if other_country_currencies ==1 & lnspot==0
mean beta [aweight=inv_nobs] if lnspot==0

* time trend
bysort studyid: egen beta_med = median(beta)
bysort studyid: egen inv_se_med = median(inv_se)
graph twoway (lfitci beta_med fd_year if lnspot==0)(scatter beta_med fd_year if lnspot==0, mcolor(navy) msize(*1.5) ytitle("Median estimate per study") xtitle("Year of publication") graphregion(color(white)) legend(off) msymbol(Oh)), saving(trend, replace) 

* studies
graph hbox beta if beta>-10 & beta<10, over(author, label(grid)) xsize(5) ysize(6) scale(0.4) yline(0, lcolor(black))  box(1, lcolor(black) fcolor(gs12)) marker(1, msymbol(circle_hollow) mcolor(gs1)) ytitle("Estimate of beta (slope coefficient from a regression of spots on forwards)") ylabel(, nogrid) graphregion(color(white)) saving(studies, replace) 
graph hbox beta if beta>-10 & beta<10 & lnspot==0, over(author, label(grid)) xsize(5) ysize(6) scale(0.4) yline(-.6021251, lcolor(black))  box(1, lcolor(black) fcolor(gs1)) marker(1, msymbol(circle_hollow) mcolor(gs12)) ytitle("Estimate of beta (differences)") ylabel(, nogrid) graphregion(color(white)) saving(studies_difference, replace) 
graph hbox beta if beta>-10 & beta<10 & lnspot==1, over(author, label(grid)) xsize(5) ysize(6) scale(0.4) yline(.8376464, lcolor(black))  box(1, lcolor(black) fcolor(gs1)) marker(1, msymbol(circle_hollow) mcolor(gs12)) ytitle("Estimate of beta (levels)") ylabel(, nogrid) graphregion(color(white)) saving(studies_level, replace) 

* countries
graph hbox beta if beta>-10 & beta<10 & country!="developed countries" & country!="emerging countries" & country!="world" & country!="United States", over(country, label(grid)) xsize(5) ysize(6) scale(0.4) yline(0, lcolor(black))  box(1, lcolor(black) fcolor(gs12)) marker(1, msymbol(circle_hollow) mcolor(gs1)) ytitle("Estimate of beta (slope coefficient from a regression of spots on forwards)") ylabel(, nogrid) graphregion(color(white)) saving(countries, replace) 
graph hbox beta if beta>-10 & beta<10 & country!="developed countries" & country!="emerging countries" & country!="world" & country!="United States" & lnspot==0, over(country, label(grid)) xsize(5) ysize(6) scale(0.4) yline(-.6021251, lcolor(black))  box(1, lcolor(black) fcolor(gs1)) marker(1, msymbol(circle_hollow) mcolor(gs12)) ytitle("Estimate of beta (differences)") ylabel(, nogrid) graphregion(color(white)) saving(countries_difference, replace) 
graph hbox beta if beta>-10 & beta<10 & country!="developed countries" & country!="emerging countries" & country!="world" & country!="United States" & lnspot==1, over(country, label(grid)) xsize(5) ysize(6) scale(0.4) yline(.8376464, lcolor(black))  box(1, lcolor(black) fcolor(gs1)) marker(1, msymbol(circle_hollow) mcolor(gs12)) ytitle("Estimate of beta (levels)") ylabel(, nogrid) graphregion(color(white)) saving(countries_level, replace) 

* histograms
hist beta if beta<3 & beta>-5, xline(-.3436539, lpattern(dott) lcolor (black)) xtitle("Estimate of beta") graphregion(color(white)) saving(histogram, replace) 
hist beta if beta<3 & beta>-5 & lnspot==0, xline(-.6021251, lpattern(dott) lcolor (black)) xline(-.266 , lpattern(dash) lcolor (black)) xtitle("Estimate of beta (differences)") graphregion(color(white)) saving(histogram_difference, replace) 
hist beta if beta<3 & beta>-5 & lnspot==1, bin(50) xline(.8376464, lpattern(dott) lcolor (black)) xline(.982, lpattern(dash) lcolor (black)) xtitle("Estimate of beta (levels)") graphregion(color(white)) saving(histogram_level, replace) 

***************************************************************************************
* PUBLICATION BIAS - Funnel plot (Egger et al., 1997)
***************************************************************************************

twoway (scatter inv_se beta if beta<3 & beta>-5 & inv_se<100 & inv_se > 0.1 & lnspot==0, msize(*.9) msymbol(Oh) yscale(log) ylab(.1 1.5 10 50 100,grid) xlab(,g) legend(label(1 "Difference estimates"))) (scatter inv_se beta if beta<3 & beta>-5 & inv_se<100 & inv_se > 0.1 & lnspot==1, msize(*.9) msymbol(Oh) color(maroon) yscale(log) ylab(.1 1.5 10 50 100,grid) xlab(,g) legend(label(2 "Level estimates"))), legend(ring(0) position(11) bmargin(medium) rows(2) region(lstyle(none))) xtitle("Estimate of beta") ytitle("Precision of the estimate (1/SE)") graphregion(color(white)) saving(funnel, replace)
twoway scatter inv_se beta if beta<3 & beta>-5 & inv_se<100 & inv_se > 0.1 & lnspot==0, ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of beta (differences)") xline(-.6021251, lpattern(dott) lcolor (black)) xline(-.266 , lpattern(dash) lcolor (black)) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) yscale(log) ylab(.1 1.5 10 50 100,grid) xlab(,g) graphregion(color(white)) saving(funnel_difference, replace)
twoway scatter inv_se beta if beta<3 & beta>-5 & inv_se<100 & inv_se > 0.1 & lnspot==1, ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of beta (levels)") xline(.8376464, lpattern(dott) lcolor (black)) xline(.982, lpattern(dash) lcolor (black)) msymbol(smcircle_hollow) color(maroon) graphregion(color(ltbluishgray)) yscale(log) ylab(.1 1.5 10 50 100,grid) xlab(,g) graphregion(color(white)) saving(funnel_level, replace)

***************************************************************************************
* PUBLICATION BIAS - FAT-PET-PEESE (Stanley, 2005; Stanley & Doucouliagos, 2012) 
***************************************************************************************

*fat-pet (differences)
gen tstat_w = tstat*sqrt(inv_nobs)
gen inv_se_w = inv_se*sqrt(inv_nobs)
gen root_w = root*sqrt(inv_nobs)
gen inv_sqrt_nobs=sqrt(inv_nobs)
eststo: xtreg tstat inv_se if lnspot==0 [pweight=inv_nobs], fe
*note: fixed effects not weighted here, recalculate bootstrapped se´s
bootstrap _b, reps(100): xtreg tstat_w inv_se_w if lnspot==0, fe
eststo: bootstrap _b, reps(100): ivreg2 tstat_w inv_sqrt_nobs inv_se_w if lnspot==0, noconstant
eststo: bootstrap _b, reps(100): ivreg2 tstat_w inv_sqrt_nobs (inv_se_w=root_w) if lnspot==0, noconstant
esttab using fatpet_differences_win.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*peese (differences)
gen se_w = se*sqrt(inv_nobs)
gen inv_root_w = inv_root*sqrt(inv_nobs)
eststo: bootstrap _b, reps(100): reg tstat_w se_w inv_se_w if lnspot==0, noconstant
eststo: bootstrap _b, reps(100): ivreg2 tstat_w (inv_se_w se_w = inv_root_w root_w) if lnspot==0, noconstant 
esttab using peese_differences_win.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*fat-pet (levels)
gen tstat_w_lev = tstat*sqrt(inv_nobs_lev)
gen inv_se_w_lev = inv_se*sqrt(inv_nobs_lev)
gen root_w_lev = root*sqrt(inv_nobs_lev)
gen inv_sqrt_nobs_lev=sqrt(inv_nobs_lev)
eststo: xtreg tstat inv_se if lnspot==1 [pweight=inv_nobs_lev], fe
bootstrap _b, reps(100): xtreg tstat_w_lev inv_se_w_lev if lnspot==1, fe
*note: fixed effects not weighted here, recalculate bootstrapped se´s
eststo: bootstrap _b, reps(100): ivreg2 tstat_w_lev inv_sqrt_nobs_lev inv_se_w_lev if lnspot==1, noconstant
eststo: bootstrap _b, reps(100): ivreg2 tstat_w_lev inv_sqrt_nobs_lev (inv_se_w_lev=root_w_lev) if lnspot==1, noconstant
esttab using fatpet_levels_win.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*peese (levels)
gen se_w_lev = se*sqrt(inv_nobs_lev)
gen inv_root_w_lev = inv_root*sqrt(inv_nobs_lev)
eststo: bootstrap _b, reps(100): reg tstat_w_lev se_w_lev inv_se_w_lev if lnspot==1, noconstant
eststo: bootstrap _b, reps(100): ivreg2 tstat_w_lev (inv_se_w_lev se_w_lev = inv_root_w_lev root_w_lev) if lnspot==1, noconstant 
esttab using peese_levels_win.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

***************************************************************************************
* PUBLICATION BIAS - Stem-based method in R (Furukawa, 2019)
***************************************************************************************
/*
source("stem_method.R") #github.com/Chishio318/stem-based_method
dataforward = read.table("clipboard-512", sep="\t", header=TRUE)
stem_results = stem(dataforward$beta, dataforward$se, param)
stem_results[["estimates"]]
*/
***************************************************************************************
* PUBLICATION BIAS - TOP10 method (Stanley et al., 2010)
***************************************************************************************

summarize inv_se if lnspot==0, detail
gen top10bound = r(p90)
summarize beta inv_se if inv_se > top10bound & lnspot==0

summarize inv_se if lnspot==1, detail
gen top10bound_lev = r(p90)
summarize beta inv_se if inv_se > top10bound_lev & lnspot==1

***************************************************************************************
* PUBLICATION BIAS - WAAP (Ioannidis et al., 2017) 
***************************************************************************************

summarize beta [aweight=1/(se*se)] if lnspot==0
gen waapbound = abs(r(mean))/2.8
reg tstat inv_se if se < waapbound & lnspot==0, noconstant

summarize beta [aweight=1/(se*se)] if lnspot==1
gen waapbound_lev = abs(r(mean))/2.8
reg tstat inv_se if se < waapbound_lev & lnspot==1, noconstant 

***************************************************************************************
* PUBLICATION BIAS - Selection model (Andrews & Kasy, 2019) 
*      accessed at https://maxkasy.github.io/home/metastudy/
***************************************************************************************
/*
use the same winsorized beta and standard error as for the stem-based method
*/
***************************************************************************************
* PUBLICATION BIAS - Endogenous kink (Bom & Rachinger, 2020)
*      code downloaded from https://sites.google.com/site/heikorachinger/codes 
***************************************************************************************
* difference estimates
drop if lnspot==1 
export excel using "data_differences_win.xlsx", sheet("differences") replace first(var) 

quietly{
clear 
import excel "data_differences_win.xlsx", sheet("differences") firstrow
rename beta bs
rename se sebs
gen ones=1
sum
local M=r(N)
sum sebs
local sebs_min=r(min)
local sebs_max=r(max)
gen sebs2=sebs^2
gen wis=ones/sebs2
gen bs_sebs=bs/sebs
gen ones_sebs=ones/sebs
gen bswis=bs*wis
sum wis
local wis_sum=r(sum)

regress bs_sebs ones_sebs ones,noc
local pet=_b[ones_sebs]
local t1_linreg = (_b[ones_sebs]/_se[ones_sebs])
local b_lin=_b[ones_sebs]
local Q1_lin = e(rss)
di `t1_linreg'
local abs_t1_linreg = abs(`t1_linreg')
di `abs_t1_linreg'

regress bs_sebs ones_sebs sebs,noc
local peese=_b[ones_sebs]
local b_sq=_b[ones_sebs]
local Q1_sq = e(rss)
di `Q1_sq'

if `abs_t1_linreg' > invt(`M-2', 0.975) {
    local combreg=`b_sq'
	local Q1=`Q1_sq'
	}
else {
    local combreg=`b_lin'
	local Q1=`Q1_lin'
}

local sigh2hat=max(0,`M'*((`Q1'/(`M'-e(df_m)-1))-1)/`wis_sum') 
local sighhat=sqrt(`sigh2hat') 

if `combreg'>1.96*`sighhat' {
    local a1=(`combreg'-1.96*`sighhat')*(`combreg'+1.96*`sighhat')/(2*1.96*`combreg')
}
else {
	local a1=0
	}
	rename bs bs_original
	rename bs_sebs bs
	rename ones_sebs constant
	rename ones pub_bias
    noisily: display "EK regression: "
if `a1'>`sebs_min' & `a1'<`sebs_max' {
    gen sebs_a1=sebs-`a1' if sebs>`a1'
	replace sebs_a1=0 if sebs<=`a1'
	gen pubbias=sebs_a1/sebs
	noisily regress bs constant pubbias, noc
	local b0_ek=_b[constant]
	local b1_ek=_b[pubbias]
	local sd0_ek=_se[constant]
	local sd1_ek=_se[pubbias]
}
else if `a1'<`sebs_min' {
    noisily regress bs constant pub_bias, noc
	local b0_ek=_b[constant]
	local b1_ek=_b[pub_bias]
	local sd0_ek=_se[constant]
	local sd1_ek=_se[pub_bias]
}
else if `a1'>`sebs_max' {
    noisily regress bs constant, noc
	local b0_ek=_b[constant]
	local sd0_ek=_se[constant]	
}
noisily: display "EK's mean effect estimate (alpha1) and standard error:"
noisily: di `b0_ek' 
noisily: di `sd0_ek' 
noisily: display "EK's publication bias estimate (delta) and standard error:"
noisily: di `b1_ek' 
noisily: di `sd1_ek' 
}
rename bs beta
rename sebs se


* level estimates
use "forward.dta", clear
xtset studyid
set more off

sum beta se
winsor2 beta se, cuts(5 95) replace
sum beta se

bysort studyid: egen double nobs_lev=count(beta) if lnspot==1
gen double inv_nobs_lev=1/nobs_lev if lnspot==1
drop nobs_lev

drop if lnspot==0
export excel "data_levels_win.xlsx", sheet("levels") replace first(var)

quietly{
clear 
import excel "data_levels_win.xlsx", sheet("levels") firstrow
rename beta bs
rename se sebs
gen ones=1
sum
local M=r(N)
sum sebs
local sebs_min=r(min)
local sebs_max=r(max)
gen sebs2=sebs^2
gen wis=ones/sebs2
gen bs_sebs=bs/sebs
gen ones_sebs=ones/sebs
gen bswis=bs*wis
sum wis
local wis_sum=r(sum)

regress bs_sebs ones_sebs ones,noc
local pet=_b[ones_sebs]
local t1_linreg = (_b[ones_sebs]/_se[ones_sebs])
local b_lin=_b[ones_sebs]
local Q1_lin = e(rss)
di `t1_linreg'
local abs_t1_linreg = abs(`t1_linreg')
di `abs_t1_linreg'

regress bs_sebs ones_sebs sebs,noc
local peese=_b[ones_sebs]
local b_sq=_b[ones_sebs]
local Q1_sq = e(rss)
di `Q1_sq'

if `abs_t1_linreg' > invt(`M-2', 0.975) {
    local combreg=`b_sq'
	local Q1=`Q1_sq'
	}
else {
    local combreg=`b_lin'
	local Q1=`Q1_lin'
}

local sigh2hat=max(0,`M'*((`Q1'/(`M'-e(df_m)-1))-1)/`wis_sum') 
local sighhat=sqrt(`sigh2hat') 

if `combreg'>1.96*`sighhat' {
    local a1=(`combreg'-1.96*`sighhat')*(`combreg'+1.96*`sighhat')/(2*1.96*`combreg')
}
else {
	local a1=0
	}
	rename bs bs_original
	rename bs_sebs bs
	rename ones_sebs constant
	rename ones pub_bias
    noisily: display "EK regression: "
if `a1'>`sebs_min' & `a1'<`sebs_max' {
    gen sebs_a1=sebs-`a1' if sebs>`a1'
	replace sebs_a1=0 if sebs<=`a1'
	gen pubbias=sebs_a1/sebs
	noisily regress bs constant pubbias, noc
	local b0_ek=_b[constant]
	local b1_ek=_b[pubbias]
	local sd0_ek=_se[constant]
	local sd1_ek=_se[pubbias]
}
else if `a1'<`sebs_min' {
    noisily regress bs constant pub_bias, noc
	local b0_ek=_b[constant]
	local b1_ek=_b[pub_bias]
	local sd0_ek=_se[constant]
	local sd1_ek=_se[pub_bias]
}
else if `a1'>`sebs_max' {
    noisily regress bs constant, noc
	local b0_ek=_b[constant]
	local sd0_ek=_se[constant]	
}
noisily: display "EK's mean effect estimate (alpha1) and standard error:"
noisily: di `b0_ek' 
noisily: di `sd0_ek' 
noisily: display "EK's publication bias estimate (delta) and standard error:"
noisily: di `b1_ek' 
noisily: di `sd1_ek' 
}
rename bs beta
rename sebs se
clear

********************************************************************************
* Publication bias - p-uniform* (van Aert & van Assen, 2020) - code for Stata & R
********************************************************************************

/* on median values
library(puniform)
library(metafor)
library(dmetar)
library(haven)
library(tidyverse)
library(meta)

data <- read_dta("puniform.dta")
puni_star(yi = data$beta_med, vi = data$variance_med, side="left", method="P",alpha = 0.05, control=list( max.iter=1000,tol=0.1,reps=10000, int=c(0,2), verbose=TRUE))
*/

***************************************************************************************
* REVISION---robustness check using interest rate differrential data
***************************************************************************************
use "forward_ird.dta", clear
xtset studyid
set more off

sum beta se
winsor2 beta se, cuts(5 95) replace
gen double root=sqrt(sample_size)
gen inv_se = 1/se
gen inv_root=1/root
gen tstat_w = tstat*sqrt(inv_nobs)
gen inv_se_w = inv_se*sqrt(inv_nobs)
gen root_w = root*sqrt(inv_nobs)
gen inv_sqrt_nobs=sqrt(inv_nobs)

*fat-pet
eststo: bootstrap _b, reps(50): xtreg tstat inv_se, fe
eststo: bootstrap _b, reps(50): ivreg2 tstat inv_se 
eststo: bootstrap _b, reps(50): ivreg2 tstat (inv_se=root)
esttab using fatpet_ird.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*peese
eststo: bootstrap _b, reps(100): reg tstat se inv_se, noconstant
eststo: bootstrap _b, reps(100): ivreg2 tstat (inv_se se = inv_root root), noconstant 
esttab using peese_ird.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*waap
summarize beta [aweight=1/(se*se)] 
gen waapbound = abs(r(mean))/2.8
reg tstat inv_se if se < waapbound, noconstant

*kinked-meta
quietly{
clear 
use "forward_ird.dta", clear
rename beta bs
rename se sebs
gen ones=1
sum
local M=r(N)
sum sebs
local sebs_min=r(min)
local sebs_max=r(max)
gen sebs2=sebs^2
gen wis=ones/sebs2
gen bs_sebs=bs/sebs
gen ones_sebs=ones/sebs
gen bswis=bs*wis
sum wis
local wis_sum=r(sum)

regress bs_sebs ones_sebs ones,noc
local pet=_b[ones_sebs]
local t1_linreg = (_b[ones_sebs]/_se[ones_sebs])
local b_lin=_b[ones_sebs]
local Q1_lin = e(rss)
di `t1_linreg'
local abs_t1_linreg = abs(`t1_linreg')
di `abs_t1_linreg'

regress bs_sebs ones_sebs sebs,noc
local peese=_b[ones_sebs]
local b_sq=_b[ones_sebs]
local Q1_sq = e(rss)
di `Q1_sq'

if `abs_t1_linreg' > invt(`M-2', 0.975) {
    local combreg=`b_sq'
	local Q1=`Q1_sq'
	}
else {
    local combreg=`b_lin'
	local Q1=`Q1_lin'
}

local sigh2hat=max(0,`M'*((`Q1'/(`M'-e(df_m)-1))-1)/`wis_sum') 
local sighhat=sqrt(`sigh2hat') 

if `combreg'>1.96*`sighhat' {
    local a1=(`combreg'-1.96*`sighhat')*(`combreg'+1.96*`sighhat')/(2*1.96*`combreg')
}
else {
	local a1=0
	}
	rename bs bs_original
	rename bs_sebs bs
	rename ones_sebs constant
	rename ones pub_bias
    noisily: display "EK regression: "
if `a1'>`sebs_min' & `a1'<`sebs_max' {
    gen sebs_a1=sebs-`a1' if sebs>`a1'
	replace sebs_a1=0 if sebs<=`a1'
	gen pubbias=sebs_a1/sebs
	noisily regress bs constant pubbias, noc
	local b0_ek=_b[constant]
	local b1_ek=_b[pubbias]
	local sd0_ek=_se[constant]
	local sd1_ek=_se[pubbias]
}
else if `a1'<`sebs_min' {
    noisily regress bs constant pub_bias, noc
	local b0_ek=_b[constant]
	local b1_ek=_b[pub_bias]
	local sd0_ek=_se[constant]
	local sd1_ek=_se[pub_bias]
}
else if `a1'>`sebs_max' {
    noisily regress bs constant, noc
	local b0_ek=_b[constant]
	local sd0_ek=_se[constant]	
}
noisily: display "EK's mean effect estimate (alpha1) and standard error:"
noisily: di `b0_ek' 
noisily: di `sd0_ek' 
noisily: display "EK's publication bias estimate (delta) and standard error:"
noisily: di `b1_ek' 
noisily: di `sd1_ek' 
}
rename bs beta
rename sebs se
clear 

***************************************************************************************
* REVISION - Funnel plot (Egger et al., 1997), full sample
***************************************************************************************

use "forward.dta", clear
xtset studyid
set more off

sum beta se,detail
sum beta se if lnspot==0, detail
sum beta se if lnspot==1, detail

gen inv_se = 1/se

hist beta, xline(-.2964172, lpattern(dott) lcolor (black)) xtitle("Estimate of beta (all estimates)") graphregion(color(white)) saving(histogram_unwin, replace) 
hist beta if beta<10 & beta>-10 & lnspot==0, xline(-.5455296, lpattern(dott) lcolor (black)) xtitle("Estimate of beta (differences)") graphregion(color(white)) saving(histogram_difference_unwin, replace) 
hist beta if beta<6 & beta>-4 & lnspot==1, bin(50) xline(.84211, lpattern(dott) lcolor (black)) xtitle("Estimate of beta (levels)") graphregion(color(white)) saving(histogram_level_unwin, replace) 

hist beta if beta<5 & beta>-5, xline(-.343654, lpattern(dott) lcolor (black)) xtitle("Estimate of beta") graphregion(color(white)) saving(histogram, replace) 
hist beta if beta<5 & beta>-5 & lnspot==0, xline(-.6021251, lpattern(dott) lcolor (black)) xtitle("Estimate of beta (differences)") graphregion(color(white)) saving(histogram_difference, replace) 
hist beta if beta<5 & beta>-5 & lnspot==1, bin(50) xline(.8376464, lpattern(dott) lcolor (black)) xtitle("Estimate of beta (levels)") graphregion(color(white)) saving(histogram_level, replace) 

***************************************************************************************
* Heterogeneity - Data generation for R and Frequentist check (OLS)
***************************************************************************************

* generate data for R
use "forward.dta", clear
xtset studyid
set more off

sum beta se
winsor2 beta se, cuts(5 95) replace
sum beta se
gen tstat = beta/se
gen double inv_se = 1/se

bysort studyid: egen double nobs=count(beta) if lnspot==0
gen double inv_sqrt_nobs=1/sqrt(nobs) if lnspot==0
drop nobs

bysort studyid: egen double nobs_lev=count(beta) if lnspot==1
gen double inv_nobs_lev=1/nobs_lev if lnspot==1
drop nobs_lev

drop mixed_currencies asian_currencies mixed_country_currencies asianmixed_country_currencies other_base longer_horizon other_frequency sample_size_full sample_size other_technique survey_source other_source reference
export excel "data_all_win.xlsx", sheet("data") replace first(var)

local variables beta se advanced_currencies emerging_currencies german_mark french_franc british_pound italian_lira japanese_yen swiss_franc euro european_currencies other_country_currencies british_pound_base euro_base german_mark_base shorter_horizon onemonth_horizon onemonth_oneyear_horizon oneyear_horizon daily_frequency weekly_frequency monthly_frequency time_difference number_of_currencies overlapping_problem ols_method fixed_effects_method sur_method regime_switching_model controls spot_rate_percentage large_differential small_differential large_positive_premium low_negative_premium overvalued_currency undervalued_currency datastream_source bank_data_source dataresources_source impact_factor citations firstdraft_year
foreach x of varlist `variables' {
gen double w_`x'=`x'*inv_sqrt_nobs
replace `x' = w_`x'
drop w_`x'
}
reg beta se inv_sqrt_nobs advanced_currencies emerging_currencies german_mark french_franc british_pound italian_lira japanese_yen swiss_franc euro european_currencies other_country_currencies british_pound_base euro_base german_mark_base shorter_horizon onemonth_horizon onemonth_oneyear_horizon oneyear_horizon daily_frequency weekly_frequency monthly_frequency time_difference number_of_currencies overlapping_problem ols_method fixed_effects_method sur_method regime_switching_model controls spot_rate_percentage large_differential small_differential large_positive_premium low_negative_premium overvalued_currency undervalued_currency datastream_source bank_data_source dataresources_source impact_factor citations firstdraft_year if lnspot==0, noconstant

***************************************************************************************
* Heterogeneity - Bayesian Model Averaging in R
***************************************************************************************

/*
library("BMS")

dataforward = read.table("clipboard-512", sep="\t", header=TRUE)

bma_dilut = bms(dataforward, burn=1e6, iter=5e6, g="UIP", mprior="dilut", nmodel=5000, mcmc="bd", user.int=FALSE)
bma_bric = bms(dataforward, burn=1e6, iter=5e6, g="BRIC", mprior="random", nmodel=5000, mcmc="bd", user.int=FALSE)
bma_hyper = bms(dataforward, burn=1e6,iter=5e6, g="hyper=BRIC", mprior="random", nmodel=5000, mcmc="bd", user.int=FALSE)

coef(bma_dilut, order.by.pip = F, exact=T, include.constant=T)
image(bma_dilut, cex.axis=0.7, order.by.pip = T, yprop2pip=F)
summary(bma_dilut)
plot(bma_dilut)
print(bma_dilut$topmod[1])

plotComp("UIP and Dilution"=bma_dilut,"BRIC and Random"=bma_bric,"HQ and Random"=bma_hyper,  add.grid=F,cex.xaxis=0.7)
*/

***************************************************************************************
* Heterogeneity - Frequentist Model Averaging in R
***************************************************************************************

/*
library(foreign)
library(xtable)
library(LowRankQP)
dataforwardfma=read.table("clipboard-512", sep="\t", header=TRUE)
dataforwardfma <-na.omit(dataforwardfma)
x.data <- dataforward[,-1]
const_<-c(1)
x.data <-cbind(const_,x.data)

x <- sapply(1:ncol(x.data),function(i){x.data[,i]/max(x.data[,i])})   
scale.vector <- as.matrix(sapply(1:ncol(x.data),function(i){max(x.data[,i])}))        
Y <- as.matrix(dataforward[,1])
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
} 

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
MMA.fls <- round(results.reduced,4)
MMA.fls <- data.frame(MMA.fls)
t <- as.data.frame(MMA.fls$Coefficient/MMA.fls$Sd..Err)
MMA.fls$pv <-round( (1-apply(as.data.frame(apply(t,1,abs)), 1, pnorm))*2,3)
MMA.fls$names <- rownames(MMA.fls)
names <- c(colnames(dataforward))
names <- c(names,"const_")
MMA.fls <- MMA.fls[match(names, MMA.fls$names),]
MMA.fls$names <- NULL
MMA.fls
*/

***************************************************************************************
* Heterogeneity - Best practice
***************************************************************************************
drop if lnspot==1
local variables se spot_rate_percentage advanced_currencies emerging_currencies german_mark french_franc british_pound italian_lira japanese_yen swiss_franc euro european_currencies other_country_currencies british_pound_base euro_base german_mark_base shorter_horizon onemonth_horizon onemonth_oneyear_horizon oneyear_horizon daily_frequency weekly_frequency monthly_frequency time_difference number_of_currencies overlapping_problem controls ols_method fixed_effects_method regime_switching_model sur_method large_positive_premium low_negative_premium overvalued_currency undervalued_currency large_differential small_differential datastream_source bank_data_source dataresources_source impact_factor citations firstdraft_year
foreach x of varlist `variables' {
sum  `x' 
local m`x' = r(mean)
local min`x' =r(min)
local max`x' =r(max)
}
xtset studyid

***Subjective best practice
ivreg2 beta se spot_rate_percentage advanced_currencies emerging_currencies german_mark french_franc british_pound italian_lira japanese_yen swiss_franc euro european_currencies other_country_currencies british_pound_base euro_base german_mark_base shorter_horizon onemonth_horizon onemonth_oneyear_horizon oneyear_horizon daily_frequency weekly_frequency monthly_frequency time_difference number_of_currencies  overlapping_problem controls ols_method fixed_effects_method regime_switching_model sur_method large_positive_premium low_negative_premium overvalued_currency undervalued_currency large_differential small_differential datastream_source bank_data_source dataresources_source impact_factor citations firstdraft_year 
lincom _cons+ spot_rate_percentage*`mspot_rate_percentage'+ advanced_currencies*`maxadvanced_currencies'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*`minshorter_horizon'+ onemonth_horizon*`monemonth_horizon'+ onemonth_oneyear_horizon*`maxonemonth_oneyear_horizon'+ oneyear_horizon*`maxoneyear_horizon'+ daily_frequency*`mdaily_frequency'+ weekly_frequency*`mweekly_frequency'+ monthly_frequency*`mmonthly_frequency'+ time_difference*`maxtime_difference'+ number_of_currencies*`mnumber_of_currencies'+ overlapping_problem*`minoverlapping_problem'+ controls*`mcontrols'+ ols_method*`minols_method'+ fixed_effects_method*`mfixed_effects_method'+ regime_switching_model*`maxregime_switching_model'+ sur_method*`maxsur_method'+ large_positive_premium*`mlarge_positive_premium'+ low_negative_premium*`mlow_negative_premium'+ overvalued_currency*`movervalued_currency'+ undervalued_currency*`mundervalued_currency'+ large_differential*`mlarge_differential'+ small_differential*`msmall_differential'+ datastream_source*`mdatastream_source'+ bank_data_source*`mbank_data_source'+ dataresources_source*`mdataresources_source'+ impact_factor*`maximpact_factor'+ citations*`maxcitations'+ firstdraft_year*`maxfirstdraft_year'
lincom _cons+ spot_rate_percentage*`mspot_rate_percentage'+ emerging_currencies*`maxemerging_currencies'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*`minshorter_horizon'+ onemonth_horizon*`monemonth_horizon'+ onemonth_oneyear_horizon*`maxonemonth_oneyear_horizon'+ oneyear_horizon*`maxoneyear_horizon'+ daily_frequency*`mdaily_frequency'+ weekly_frequency*`mweekly_frequency'+ monthly_frequency*`mmonthly_frequency'+ time_difference*`maxtime_difference'+ number_of_currencies*`mnumber_of_currencies'+ overlapping_problem*`minoverlapping_problem'+ controls*`mcontrols'+ ols_method*`minols_method'+ fixed_effects_method*`mfixed_effects_method'+ regime_switching_model*`maxregime_switching_model'+ sur_method*`maxsur_method'+ large_positive_premium*`mlarge_positive_premium'+ low_negative_premium*`mlow_negative_premium'+ overvalued_currency*`movervalued_currency'+ undervalued_currency*`mundervalued_currency'+ large_differential*`mlarge_differential'+ small_differential*`msmall_differential'+ datastream_source*`mdatastream_source'+ bank_data_source*`mbank_data_source'+ dataresources_source*`mdataresources_source'+ impact_factor*`maximpact_factor'+ citations*`maxcitations'+ firstdraft_year*`maxfirstdraft_year'
lincom _cons+ spot_rate_percentage*`mspot_rate_percentage'+ euro*`maxeuro'+ british_pound_base*`mbritish_pound_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*`minshorter_horizon'+ onemonth_horizon*`monemonth_horizon'+ onemonth_oneyear_horizon*`maxonemonth_oneyear_horizon'+ oneyear_horizon*`maxoneyear_horizon'+ daily_frequency*`mdaily_frequency'+ weekly_frequency*`mweekly_frequency'+ monthly_frequency*`mmonthly_frequency'+ time_difference*`maxtime_difference'+ number_of_currencies*`mnumber_of_currencies'+ overlapping_problem*`minoverlapping_problem'+ controls*`mcontrols'+ ols_method*`minols_method'+ fixed_effects_method*`mfixed_effects_method'+ regime_switching_model*`maxregime_switching_model'+ sur_method*`maxsur_method'+ large_positive_premium*`mlarge_positive_premium'+ low_negative_premium*`mlow_negative_premium'+ overvalued_currency*`movervalued_currency'+ undervalued_currency*`mundervalued_currency'+ large_differential*`mlarge_differential'+ small_differential*`msmall_differential'+ datastream_source*`mdatastream_source'+ bank_data_source*`mbank_data_source'+ dataresources_source*`mdataresources_source'+ impact_factor*`maximpact_factor'+ citations*`maxcitations'+ firstdraft_year*`maxfirstdraft_year'
lincom _cons+ spot_rate_percentage*`mspot_rate_percentage'+ german_mark*`maxgerman_mark'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ shorter_horizon*`minshorter_horizon'+ onemonth_horizon*`monemonth_horizon'+ onemonth_oneyear_horizon*`maxonemonth_oneyear_horizon'+ oneyear_horizon*`maxoneyear_horizon'+ daily_frequency*`mdaily_frequency'+ weekly_frequency*`mweekly_frequency'+ monthly_frequency*`mmonthly_frequency'+ time_difference*`maxtime_difference'+ number_of_currencies*`mnumber_of_currencies'+ overlapping_problem*`minoverlapping_problem'+ controls*`mcontrols'+ ols_method*`minols_method'+ fixed_effects_method*`mfixed_effects_method'+ regime_switching_model*`maxregime_switching_model'+ sur_method*`maxsur_method'+ large_positive_premium*`mlarge_positive_premium'+ low_negative_premium*`mlow_negative_premium'+ overvalued_currency*`movervalued_currency'+ undervalued_currency*`mundervalued_currency'+ large_differential*`mlarge_differential'+ small_differential*`msmall_differential'+ datastream_source*`mdatastream_source'+ bank_data_source*`mbank_data_source'+ dataresources_source*`mdataresources_source'+ impact_factor*`maximpact_factor'+ citations*`maxcitations'+ firstdraft_year*`maxfirstdraft_year'
lincom _cons+ spot_rate_percentage*`mspot_rate_percentage'+ french_franc*`maxfrench_franc'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*`minshorter_horizon'+ onemonth_horizon*`monemonth_horizon'+ onemonth_oneyear_horizon*`maxonemonth_oneyear_horizon'+ oneyear_horizon*`maxoneyear_horizon'+ daily_frequency*`mdaily_frequency'+ weekly_frequency*`mweekly_frequency'+ monthly_frequency*`mmonthly_frequency'+ time_difference*`maxtime_difference'+ number_of_currencies*`mnumber_of_currencies'+ overlapping_problem*`minoverlapping_problem'+ controls*`mcontrols'+ ols_method*`minols_method'+ fixed_effects_method*`mfixed_effects_method'+ regime_switching_model*`maxregime_switching_model'+ sur_method*`maxsur_method'+ large_positive_premium*`mlarge_positive_premium'+ low_negative_premium*`mlow_negative_premium'+ overvalued_currency*`movervalued_currency'+ undervalued_currency*`mundervalued_currency'+ large_differential*`mlarge_differential'+ small_differential*`msmall_differential'+ datastream_source*`mdatastream_source'+ bank_data_source*`mbank_data_source'+ dataresources_source*`mdataresources_source'+ impact_factor*`maximpact_factor'+ citations*`maxcitations'+ firstdraft_year*`maxfirstdraft_year'
lincom _cons+ spot_rate_percentage*`mspot_rate_percentage'+ british_pound*`maxbritish_pound'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*`minshorter_horizon'+ onemonth_horizon*`monemonth_horizon'+ onemonth_oneyear_horizon*`maxonemonth_oneyear_horizon'+ oneyear_horizon*`maxoneyear_horizon'+ daily_frequency*`mdaily_frequency'+ weekly_frequency*`mweekly_frequency'+ monthly_frequency*`mmonthly_frequency'+ time_difference*`maxtime_difference'+ number_of_currencies*`mnumber_of_currencies'+ overlapping_problem*`minoverlapping_problem'+ controls*`mcontrols'+ ols_method*`minols_method'+ fixed_effects_method*`mfixed_effects_method'+ regime_switching_model*`maxregime_switching_model'+ sur_method*`maxsur_method'+ large_positive_premium*`mlarge_positive_premium'+ low_negative_premium*`mlow_negative_premium'+ overvalued_currency*`movervalued_currency'+ undervalued_currency*`mundervalued_currency'+ large_differential*`mlarge_differential'+ small_differential*`msmall_differential'+ datastream_source*`mdatastream_source'+ bank_data_source*`mbank_data_source'+ dataresources_source*`mdataresources_source'+ impact_factor*`maximpact_factor'+ citations*`maxcitations'+ firstdraft_year*`maxfirstdraft_year'
lincom _cons+ spot_rate_percentage*`mspot_rate_percentage'+ italian_lira*`maxitalian_lira'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*`minshorter_horizon'+ onemonth_horizon*`monemonth_horizon'+ onemonth_oneyear_horizon*`maxonemonth_oneyear_horizon'+ oneyear_horizon*`maxoneyear_horizon'+ daily_frequency*`mdaily_frequency'+ weekly_frequency*`mweekly_frequency'+ monthly_frequency*`mmonthly_frequency'+ time_difference*`maxtime_difference'+ number_of_currencies*`mnumber_of_currencies'+ overlapping_problem*`minoverlapping_problem'+ controls*`mcontrols'+ ols_method*`minols_method'+ fixed_effects_method*`mfixed_effects_method'+ regime_switching_model*`maxregime_switching_model'+ sur_method*`maxsur_method'+ large_positive_premium*`mlarge_positive_premium'+ low_negative_premium*`mlow_negative_premium'+ overvalued_currency*`movervalued_currency'+ undervalued_currency*`mundervalued_currency'+ large_differential*`mlarge_differential'+ small_differential*`msmall_differential'+ datastream_source*`mdatastream_source'+ bank_data_source*`mbank_data_source'+ dataresources_source*`mdataresources_source'+ impact_factor*`maximpact_factor'+ citations*`maxcitations'+ firstdraft_year*`maxfirstdraft_year'
lincom _cons+ spot_rate_percentage*`mspot_rate_percentage'+ japanese_yen*`maxjapanese_yen'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*`minshorter_horizon'+ onemonth_horizon*`monemonth_horizon'+ onemonth_oneyear_horizon*`maxonemonth_oneyear_horizon'+ oneyear_horizon*`maxoneyear_horizon'+ daily_frequency*`mdaily_frequency'+ weekly_frequency*`mweekly_frequency'+ monthly_frequency*`mmonthly_frequency'+ time_difference*`maxtime_difference'+ number_of_currencies*`mnumber_of_currencies'+ overlapping_problem*`minoverlapping_problem'+ controls*`mcontrols'+ ols_method*`minols_method'+ fixed_effects_method*`mfixed_effects_method'+ regime_switching_model*`maxregime_switching_model'+ sur_method*`maxsur_method'+ large_positive_premium*`mlarge_positive_premium'+ low_negative_premium*`mlow_negative_premium'+ overvalued_currency*`movervalued_currency'+ undervalued_currency*`mundervalued_currency'+ large_differential*`mlarge_differential'+ small_differential*`msmall_differential'+ datastream_source*`mdatastream_source'+ bank_data_source*`mbank_data_source'+ dataresources_source*`mdataresources_source'+ impact_factor*`maximpact_factor'+ citations*`maxcitations'+ firstdraft_year*`maxfirstdraft_year'
lincom _cons+ spot_rate_percentage*`mspot_rate_percentage'+ swiss_franc*`maxswiss_franc'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*`minshorter_horizon'+ onemonth_horizon*`monemonth_horizon'+ onemonth_oneyear_horizon*`maxonemonth_oneyear_horizon'+ oneyear_horizon*`maxoneyear_horizon'+ daily_frequency*`mdaily_frequency'+ weekly_frequency*`mweekly_frequency'+ monthly_frequency*`mmonthly_frequency'+ time_difference*`maxtime_difference'+ number_of_currencies*`mnumber_of_currencies'+ overlapping_problem*`minoverlapping_problem'+ controls*`mcontrols'+ ols_method*`minols_method'+ fixed_effects_method*`mfixed_effects_method'+ regime_switching_model*`maxregime_switching_model'+ sur_method*`maxsur_method'+ large_positive_premium*`mlarge_positive_premium'+ low_negative_premium*`mlow_negative_premium'+ overvalued_currency*`movervalued_currency'+ undervalued_currency*`mundervalued_currency'+ large_differential*`mlarge_differential'+ small_differential*`msmall_differential'+ datastream_source*`mdatastream_source'+ bank_data_source*`mbank_data_source'+ dataresources_source*`mdataresources_source'+ impact_factor*`maximpact_factor'+ citations*`maxcitations'+ firstdraft_year*`maxfirstdraft_year'
lincom _cons+ spot_rate_percentage*`mspot_rate_percentage'+ european_currencies*`maxeuropean_currencies'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*`minshorter_horizon'+ onemonth_horizon*`monemonth_horizon'+ onemonth_oneyear_horizon*`maxonemonth_oneyear_horizon'+ oneyear_horizon*`maxoneyear_horizon'+ daily_frequency*`mdaily_frequency'+ weekly_frequency*`mweekly_frequency'+ monthly_frequency*`mmonthly_frequency'+ time_difference*`maxtime_difference'+ number_of_currencies*`mnumber_of_currencies'+ overlapping_problem*`minoverlapping_problem'+ controls*`mcontrols'+ ols_method*`minols_method'+ fixed_effects_method*`mfixed_effects_method'+ regime_switching_model*`maxregime_switching_model'+ sur_method*`maxsur_method'+ large_positive_premium*`mlarge_positive_premium'+ low_negative_premium*`mlow_negative_premium'+ overvalued_currency*`movervalued_currency'+ undervalued_currency*`mundervalued_currency'+ large_differential*`mlarge_differential'+ small_differential*`msmall_differential'+ datastream_source*`mdatastream_source'+ bank_data_source*`mbank_data_source'+ dataresources_source*`mdataresources_source'+ impact_factor*`maximpact_factor'+ citations*`maxcitations'+ firstdraft_year*`maxfirstdraft_year'
lincom _cons+ spot_rate_percentage*`mspot_rate_percentage'+ other_country_currencies*`maxother_country_currencies'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*`minshorter_horizon'+ onemonth_horizon*`monemonth_horizon'+ onemonth_oneyear_horizon*`maxonemonth_oneyear_horizon'+ oneyear_horizon*`maxoneyear_horizon'+ daily_frequency*`mdaily_frequency'+ weekly_frequency*`mweekly_frequency'+ monthly_frequency*`mmonthly_frequency'+ time_difference*`maxtime_difference'+ number_of_currencies*`mnumber_of_currencies'+ overlapping_problem*`minoverlapping_problem'+ controls*`mcontrols'+ ols_method*`minols_method'+ fixed_effects_method*`mfixed_effects_method'+ regime_switching_model*`maxregime_switching_model'+ sur_method*`maxsur_method'+ large_positive_premium*`mlarge_positive_premium'+ low_negative_premium*`mlow_negative_premium'+ overvalued_currency*`movervalued_currency'+ undervalued_currency*`mundervalued_currency'+ large_differential*`mlarge_differential'+ small_differential*`msmall_differential'+ datastream_source*`mdatastream_source'+ bank_data_source*`mbank_data_source'+ dataresources_source*`mdataresources_source'+ impact_factor*`maximpact_factor'+ citations*`maxcitations'+ firstdraft_year*`maxfirstdraft_year'

***Frankel & Poonawala (2010)
ivreg2 beta se inv_sqrt_nobs spot_rate_percentage advanced_currencies emerging_currencies german_mark french_franc british_pound italian_lira japanese_yen swiss_franc euro european_currencies other_country_currencies british_pound_base euro_base german_mark_base shorter_horizon onemonth_horizon onemonth_oneyear_horizon oneyear_horizon daily_frequency weekly_frequency monthly_frequency time_difference number_of_currencies  overlapping_problem controls ols_method fixed_effects_method regime_switching_model sur_method large_positive_premium low_negative_premium overvalued_currency undervalued_currency large_differential small_differential datastream_source bank_data_source dataresources_source impact_factor citations firstdraft_year
lincom _cons+ spot_rate_percentage*0+ advanced_currencies*`maxadvanced_currencies'+british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.125+ onemonth_oneyear_horizon*0+ oneyear_horizon*0+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.125+ time_difference*0+ number_of_currencies*0.027+ overlapping_problem*0+ controls*0+ ols_method*0.076+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0.049+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.072+ citations*3.882+ firstdraft_year*10.253
lincom _cons+ spot_rate_percentage*0+ emerging_currencies*`maxemerging_currencies'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.125+ onemonth_oneyear_horizon*0+ oneyear_horizon*0+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.125+ time_difference*0+ number_of_currencies*0.027+ overlapping_problem*0+ controls*0+ ols_method*0.076+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0.049+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.072+ citations*3.882+ firstdraft_year*10.253
lincom _cons+ spot_rate_percentage*0+ euro*`maxeuro'+ british_pound_base*`mbritish_pound_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.125+ onemonth_oneyear_horizon*0+ oneyear_horizon*0+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.125+ time_difference*0+ number_of_currencies*0.027+ overlapping_problem*0+ controls*0+ ols_method*0.076+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0.049+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.072+ citations*3.882+ firstdraft_year*10.253
lincom _cons+ spot_rate_percentage*0+ german_mark*`maxgerman_mark'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ shorter_horizon*0+ onemonth_horizon*0.125+ onemonth_oneyear_horizon*0+ oneyear_horizon*0+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.125+ time_difference*0+ number_of_currencies*0.027+ overlapping_problem*0+ controls*0+ ols_method*0.076+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0.049+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.072+ citations*3.882+ firstdraft_year*10.253
lincom _cons+ spot_rate_percentage*0+ french_franc*`maxfrench_franc'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.125+ onemonth_oneyear_horizon*0+ oneyear_horizon*0+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.125+ time_difference*0+ number_of_currencies*0.027+ overlapping_problem*0+ controls*0+ ols_method*0.076+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0.049+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.072+ citations*3.882+ firstdraft_year*10.253
lincom _cons+ spot_rate_percentage*0+ british_pound*`maxbritish_pound'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.125+ onemonth_oneyear_horizon*0+ oneyear_horizon*0+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.125+ time_difference*0+ number_of_currencies*0.027+ overlapping_problem*0+ controls*0+ ols_method*0.076+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0.049+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.072+ citations*3.882+ firstdraft_year*10.253
lincom _cons+ spot_rate_percentage*0+ italian_lira*`maxitalian_lira'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.125+ onemonth_oneyear_horizon*0+ oneyear_horizon*0+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.125+ time_difference*0+ number_of_currencies*0.027+ overlapping_problem*0+ controls*0+ ols_method*0.076+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0.049+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.072+ citations*3.882+ firstdraft_year*10.253
lincom _cons+ spot_rate_percentage*0+ japanese_yen*`maxjapanese_yen'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.125+ onemonth_oneyear_horizon*0+ oneyear_horizon*0+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.125+ time_difference*0+ number_of_currencies*0.027+ overlapping_problem*0+ controls*0+ ols_method*0.076+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0.049+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.072+ citations*3.882+ firstdraft_year*10.253
lincom _cons+ spot_rate_percentage*0+ swiss_franc*`maxswiss_franc'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.125+ onemonth_oneyear_horizon*0+ oneyear_horizon*0+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.125+ time_difference*0+ number_of_currencies*0.027+ overlapping_problem*0+ controls*0+ ols_method*0.076+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0.049+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.072+ citations*3.882+ firstdraft_year*10.253
lincom _cons+ spot_rate_percentage*0+ european_currencies*`maxeuropean_currencies'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.125+ onemonth_oneyear_horizon*0+ oneyear_horizon*0+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.125+ time_difference*0+ number_of_currencies*0.027+ overlapping_problem*0+ controls*0+ ols_method*0.076+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0.049+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.072+ citations*3.882+ firstdraft_year*10.253
lincom _cons+ spot_rate_percentage*0+ other_country_currencies*`maxother_country_currencies'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.125+ onemonth_oneyear_horizon*0+ oneyear_horizon*0+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.125+ time_difference*0+ number_of_currencies*0.027+ overlapping_problem*0+ controls*0+ ols_method*0.076+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0.049+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.072+ citations*3.882+ firstdraft_year*10.253

***Breedon et al. (2016)
ivreg2 beta se spot_rate_percentage advanced_currencies emerging_currencies german_mark french_franc british_pound italian_lira japanese_yen swiss_franc euro european_currencies other_country_currencies british_pound_base euro_base german_mark_base shorter_horizon onemonth_horizon onemonth_oneyear_horizon oneyear_horizon daily_frequency weekly_frequency monthly_frequency time_difference number_of_currencies  overlapping_problem controls ols_method fixed_effects_method regime_switching_model sur_method large_positive_premium low_negative_premium overvalued_currency undervalued_currency large_differential small_differential datastream_source bank_data_source dataresources_source impact_factor citations firstdraft_year
lincom _cons+ spot_rate_percentage*0+ advanced_currencies*`maxadvanced_currencies'+british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.042+ onemonth_horizon*0.083+ oneyear_horizon*0.042+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.167+ time_difference*0+ number_of_currencies*0+ number_of_currencies*0.027+ overlapping_problem*0.125+ controls*0+ ols_method*0.111+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.138+ citations*3.882+ firstdraft_year*7.937
lincom _cons+ spot_rate_percentage*0+ emerging_currencies*`maxemerging_currencies'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.042+ onemonth_horizon*0.083+ oneyear_horizon*0.042+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.167+ time_difference*0+ number_of_currencies*0+ overlapping_problem*0.125+ controls*0+ ols_method*0.111+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.138+ citations*3.882+ firstdraft_year*7.937
lincom _cons+ spot_rate_percentage*0+ euro*`maxeuro'+ british_pound_base*`mbritish_pound_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.042+ onemonth_horizon*0.083+ oneyear_horizon*0.042+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.167+ time_difference*0+ number_of_currencies*0+ overlapping_problem*0.125+ controls*0+ ols_method*0.111+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.138+ citations*0.141+ firstdraft_year*7.937
lincom _cons+ spot_rate_percentage*0+ german_mark*`maxgerman_mark'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ shorter_horizon*0+ onemonth_horizon*0.042+ onemonth_horizon*0.083+ oneyear_horizon*0.042+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.167+ time_difference*0+ number_of_currencies*0+ overlapping_problem*0.125+ controls*0+ ols_method*0.111+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.138+ citations*0.141+ firstdraft_year*7.937
lincom _cons+ spot_rate_percentage*0+ french_franc*`maxfrench_franc'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.042+ onemonth_horizon*0.083+ oneyear_horizon*0.042+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.167+ time_difference*0+ number_of_currencies*0+ overlapping_problem*0.125+ controls*0+ ols_method*0.111+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.138+ citations*0.141+ firstdraft_year*7.937
lincom _cons+ spot_rate_percentage*0+ british_pound*`maxbritish_pound'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.042+ onemonth_horizon*0.083+ oneyear_horizon*0.042+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.167+ time_difference*0+ number_of_currencies*0+ overlapping_problem*0.125+ controls*0+ ols_method*0.111+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.138+ citations*0.141+ firstdraft_year*7.937
lincom _cons+ spot_rate_percentage*0+ italian_lira*`maxitalian_lira'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.042+ onemonth_horizon*0.083+ oneyear_horizon*0.042+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.167+ time_difference*0+ number_of_currencies*0+ overlapping_problem*0.125+ controls*0+ ols_method*0.111+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.138+ citations*0.141+ firstdraft_year*7.937
lincom _cons+ spot_rate_percentage*0+ japanese_yen*`maxjapanese_yen'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.042+ onemonth_horizon*0.083+ oneyear_horizon*0.042+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.167+ time_difference*0+ number_of_currencies*0+ overlapping_problem*0.125+ controls*0+ ols_method*0.111+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.138+ citations*0.141+ firstdraft_year*7.937
lincom _cons+ spot_rate_percentage*0+ swiss_franc*`maxswiss_franc'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.042+ onemonth_horizon*0.083+ oneyear_horizon*0.042+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.167+ time_difference*0+ number_of_currencies*0+ overlapping_problem*0.125+ controls*0+ ols_method*0.111+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.138+ citations*0.141+ firstdraft_year*7.937
lincom _cons+ spot_rate_percentage*0+ european_currencies*`maxeuropean_currencies'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.042+ onemonth_horizon*0.083+ oneyear_horizon*0.042+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.167+ time_difference*0+ number_of_currencies*0+ overlapping_problem*0.125+ controls*0+ ols_method*0.111+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.138+ citations*0.141+ firstdraft_year*7.937
lincom _cons+ spot_rate_percentage*0+ other_country_currencies*`maxother_country_currencies'+ british_pound_base*`mbritish_pound_base'+ euro_base*`meuro_base'+ german_mark_base*`mgerman_mark_base'+ shorter_horizon*0+ onemonth_horizon*0.042+ onemonth_horizon*0.083+ oneyear_horizon*0.042+ daily_frequency*0+ weekly_frequency*0+ monthly_frequency*0.167+ time_difference*0+ number_of_currencies*0+ overlapping_problem*0.125+ controls*0+ ols_method*0.111+ fixed_effects_method*0+ regime_switching_model*0+ sur_method*0+ large_positive_premium*0+ low_negative_premium*0+ overvalued_currency*0+ undervalued_currency*0+ large_differential*0+ small_differential*0+ datastream_source*0+ bank_data_source*0+ dataresources_source*0+ impact_factor*0.138+ citations*0.141+ firstdraft_year*7.937

clear
log close

***************************************************************************************
***************************************************************************************
************************      TRIMMING (not WINSORIZING)     **************************
************************               REVISION              **************************
***************************************************************************************
***************************************************************************************

log using forward_trim.log, replace
use "forward.dta", clear
xtset studyid
set more off

bysort studyid: egen double nobs=count(beta)
gen double inv_nobs=1/nobs
drop nobs
sum beta se, detail
drop if beta < -6
drop if beta > 6

gen double inv_se = 1/se
gen inv_se_w = inv_se*sqrt(inv_nobs)
gen tstat = beta/se
gen tstat_w = tstat*sqrt(inv_nobs)
gen se_w = se*sqrt(inv_nobs)
gen double root=sqrt(sample_size_full)
gen root_w = root*sqrt(inv_nobs)
gen inv_sqrt_nobs=sqrt(inv_nobs)
gen inv_root = 1/root
gen inv_root_w = inv_root*sqrt(inv_nobs)
gen double lnobs = ln(sample_size_full)
gen double invlnobs=1/lnobs
gen double invroot=1/root

reg tstat_w inv_se_w if lnspot==0
dfbeta
sort _dfbeta_1 
list tstat_w inv_se_w  in 1/50 if lnspot==0
drop if lnspot==0 & _dfbeta_1 in 1/3

summarize beta se if lnspot==0, detail
hist beta if beta<10 & beta>-10, xtitle("Estimate of beta (trimmed)") graphregion(color(white)) saving(histogram_trim, replace) 

***************************************************************************************
* PUBLICATION BIAS - FAT-PET (Stanley, 2005)
***************************************************************************************

*fat-pet (differences)
eststo: xtreg tstat inv_se if lnspot==0 [pweight=inv_nobs], fe
bootstrap _b, reps(100): xtreg tstat_w inv_se_w if lnspot==0, fe
*note: fixed effects not weighted here, recalculate bootstrapped se´s
eststo: bootstrap _b, reps(100): ivreg2 tstat_w inv_sqrt_nobs inv_se_w if lnspot==0, noconstant
eststo: bootstrap _b, reps(100): ivreg2 tstat_w inv_sqrt_nobs (inv_se_w=root_w) if lnspot==0, noconstant
esttab using fatpet_differences_trim.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*peese (differences)
eststo: bootstrap _b, reps(100): reg tstat_w se_w inv_se_w if lnspot==0, noconstant
eststo: bootstrap _b, reps(100): ivreg2 tstat_w (inv_se_w se_w = inv_root_w root_w) if lnspot==0, noconstant 
esttab using peese_differences_trim.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*fat-pet (levels)
eststo: xtreg tstat inv_se if lnspot==1 [pweight=inv_nobs], fe
bootstrap _b, reps(100): xtreg tstat_w inv_se_w if lnspot==1, fe
*note: fixed effects not weighted here, recalculate bootstrapped se´s
eststo: bootstrap _b, reps(100): ivreg2 tstat_w inv_sqrt_nobs inv_se_w if lnspot==1, noconstant
eststo: bootstrap _b, reps(100): ivreg2 tstat_w inv_sqrt_nobs (inv_se_w=root_w) if lnspot==1, noconstant
esttab using fatpet_levels_trim.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*peese (levels)
eststo: bootstrap _b, reps(100): reg tstat_w se_w inv_se_w if lnspot==1, noconstant
eststo: bootstrap _b, reps(100): ivreg2 tstat_w (inv_se_w se_w = inv_root_w root_w) if lnspot==1, noconstant 
esttab using peese_levels_trim.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

***************************************************************************************
* PUBLICATION BIAS - Stem-based method in R (Furukawa, 2019)
***************************************************************************************
/*
source("stem_method.R") #github.com/Chishio318/stem-based_method
dataforward = read.table("clipboard-512", sep="\t", header=TRUE)
stem_results = stem(dataforward$beta, dataforward$se, param)
stem_results[["estimates"]]
*/
***************************************************************************************
* PUBLICATION BIAS - TOP10 method (Stanley et al., 2010)
***************************************************************************************

summarize inv_se if lnspot==0, detail
gen top10bound = r(p90)
summarize beta inv_se if inv_se > top10bound & lnspot==0

summarize inv_se if lnspot==1, detail
gen top10bound_lev = r(p90)
summarize beta inv_se if inv_se > top10bound_lev & lnspot==1

***************************************************************************************
* PUBLICATION BIAS - WAAP (Ioannidis et al., 2017) 
***************************************************************************************

summarize beta [aweight=1/(se*se)] if lnspot==0
gen waapbound = abs(r(mean))/2.8
reg tstat inv_se if se < waapbound & lnspot==0, noconstant

summarize beta [aweight=1/(se*se)] if lnspot==1
gen waapbound_lev = abs(r(mean))/2.8
reg tstat inv_se if se < waapbound_lev & lnspot==1, noconstant

***************************************************************************************
* PUBLICATION BIAS - Selection model (Andrews & Kasy, 2019) 
*      accessed at https://maxkasy.github.io/home/metastudy/
***************************************************************************************
/*
use the same winsorized beta and standard error as for the stem-based method
*/
***************************************************************************************
* PUBLICATION BIAS - Endogenous kink (Bom & Rachinger, 2020)
*      code downloaded from https://sites.google.com/site/heikorachinger/codes 
***************************************************************************************

* differences estimates
drop if lnspot==1 
export excel using "data_differences_trim.xlsx", sheet("differences") replace first(var) 
quietly{
clear 
import excel "data_differences_trim.xlsx", sheet("differences") firstrow
rename beta bs
rename se sebs
gen ones=1
sum
local M=r(N)
sum sebs
local sebs_min=r(min)
local sebs_max=r(max)
gen sebs2=sebs^2
gen wis=ones/sebs2
gen bs_sebs=bs/sebs
gen ones_sebs=ones/sebs
gen bswis=bs*wis
sum wis
local wis_sum=r(sum)

regress bs_sebs ones_sebs ones,noc
local pet=_b[ones_sebs]
local t1_linreg = (_b[ones_sebs]/_se[ones_sebs])
local b_lin=_b[ones_sebs]
local Q1_lin = e(rss)
di `t1_linreg'
local abs_t1_linreg = abs(`t1_linreg')
di `abs_t1_linreg'

regress bs_sebs ones_sebs sebs,noc
local peese=_b[ones_sebs]
local b_sq=_b[ones_sebs]
local Q1_sq = e(rss)
di `Q1_sq'

if `abs_t1_linreg' > invt(`M-2', 0.975) {
    local combreg=`b_sq'
	local Q1=`Q1_sq'
	}
else {
    local combreg=`b_lin'
	local Q1=`Q1_lin'
}

local sigh2hat=max(0,`M'*((`Q1'/(`M'-e(df_m)-1))-1)/`wis_sum') 
local sighhat=sqrt(`sigh2hat') 

if `combreg'>1.96*`sighhat' {
    local a1=(`combreg'-1.96*`sighhat')*(`combreg'+1.96*`sighhat')/(2*1.96*`combreg')
}
else {
	local a1=0
	}
	rename bs bs_original
	rename bs_sebs bs
	rename ones_sebs constant
	rename ones pub_bias
    noisily: display "EK regression: "
if `a1'>`sebs_min' & `a1'<`sebs_max' {
    gen sebs_a1=sebs-`a1' if sebs>`a1'
	replace sebs_a1=0 if sebs<=`a1'
	gen pubbias=sebs_a1/sebs
	noisily regress bs constant pubbias, noc
	local b0_ek=_b[constant]
	local b1_ek=_b[pubbias]
	local sd0_ek=_se[constant]
	local sd1_ek=_se[pubbias]
}
else if `a1'<`sebs_min' {
    noisily regress bs constant pub_bias, noc
	local b0_ek=_b[constant]
	local b1_ek=_b[pub_bias]
	local sd0_ek=_se[constant]
	local sd1_ek=_se[pub_bias]
}
else if `a1'>`sebs_max' {
    noisily regress bs constant, noc
	local b0_ek=_b[constant]
	local sd0_ek=_se[constant]	
}
noisily: display "EK's mean effect estimate (alpha1) and standard error:"
noisily: di `b0_ek' 
noisily: di `sd0_ek' 
noisily: display "EK's publication bias estimate (delta) and standard error:"
noisily: di `b1_ek' 
noisily: di `sd1_ek' 
}
rename bs beta
rename sebs se

* level estimates

use "forward.dta", clear
xtset studyid
set more off


bysort studyid: egen double nobs=count(beta)
gen double inv_nobs=1/nobs
drop nobs
sum beta se, detail
drop if beta < -6
drop if beta > 6

gen double inv_se = 1/se
gen inv_se_w = inv_se*sqrt(inv_nobs)
gen tstat = beta/se
gen tstat_w = tstat*sqrt(inv_nobs)
gen se_w = se*sqrt(inv_nobs)
gen double root=sqrt(sample_size_full)
gen root_w = root*sqrt(inv_nobs)
gen inv_sqrt_nobs=sqrt(inv_nobs)
gen inv_root = 1/root
gen inv_root_w = inv_root*sqrt(inv_nobs)
gen double lnobs = ln(sample_size_full)
gen double invlnobs=1/lnobs
gen double invroot=1/root

drop if lnspot==0
export excel "data_levels_trim.xlsx", sheet("levels") replace first(var)

quietly{
clear 
import excel "data_levels_trim.xlsx", sheet("levels") firstrow
rename beta bs
rename se sebs
gen ones=1
sum
local M=r(N)
sum sebs
local sebs_min=r(min)
local sebs_max=r(max)
gen sebs2=sebs^2
gen wis=ones/sebs2
gen bs_sebs=bs/sebs
gen ones_sebs=ones/sebs
gen bswis=bs*wis
sum wis
local wis_sum=r(sum)

regress bs_sebs ones_sebs ones,noc
local pet=_b[ones_sebs]
local t1_linreg = (_b[ones_sebs]/_se[ones_sebs])
local b_lin=_b[ones_sebs]
local Q1_lin = e(rss)
di `t1_linreg'
local abs_t1_linreg = abs(`t1_linreg')
di `abs_t1_linreg'

regress bs_sebs ones_sebs sebs,noc
local peese=_b[ones_sebs]
local b_sq=_b[ones_sebs]
local Q1_sq = e(rss)
di `Q1_sq'

if `abs_t1_linreg' > invt(`M-2', 0.975) {
    local combreg=`b_sq'
	local Q1=`Q1_sq'
	}
else {
    local combreg=`b_lin'
	local Q1=`Q1_lin'
}

local sigh2hat=max(0,`M'*((`Q1'/(`M'-e(df_m)-1))-1)/`wis_sum') 
local sighhat=sqrt(`sigh2hat') 

if `combreg'>1.96*`sighhat' {
    local a1=(`combreg'-1.96*`sighhat')*(`combreg'+1.96*`sighhat')/(2*1.96*`combreg')
}
else {
	local a1=0
	}
	rename bs bs_original
	rename bs_sebs bs
	rename ones_sebs constant
	rename ones pub_bias
    noisily: display "EK regression: "
if `a1'>`sebs_min' & `a1'<`sebs_max' {
    gen sebs_a1=sebs-`a1' if sebs>`a1'
	replace sebs_a1=0 if sebs<=`a1'
	gen pubbias=sebs_a1/sebs
	noisily regress bs constant pubbias, noc
	local b0_ek=_b[constant]
	local b1_ek=_b[pubbias]
	local sd0_ek=_se[constant]
	local sd1_ek=_se[pubbias]
}
else if `a1'<`sebs_min' {
    noisily regress bs constant pub_bias, noc
	local b0_ek=_b[constant]
	local b1_ek=_b[pub_bias]
	local sd0_ek=_se[constant]
	local sd1_ek=_se[pub_bias]
}
else if `a1'>`sebs_max' {
    noisily regress bs constant, noc
	local b0_ek=_b[constant]
	local sd0_ek=_se[constant]	
}
noisily: display "EK's mean effect estimate (alpha1) and standard error:"
noisily: di `b0_ek' 
noisily: di `sd0_ek' 
noisily: display "EK's publication bias estimate (delta) and standard error:"
noisily: di `b1_ek' 
noisily: di `sd1_ek' 
}
rename bs beta
rename sebs se
clear
********************************************************************************
* Publication bias - p-uniform* (van Aert & van Assen, 2019) - code for Stata & R
********************************************************************************

/*
library(puniform)
library(metafor)
library(dmetar)
library(haven)
library(tidyverse)
library(meta)

data <- read_dta("puniform.dta")
puni_star(yi = data$beta_med, vi = data$variance_med, side="left", method="P",alpha = 0.05, control=list( max.iter=1000,tol=0.1,reps=10000, int=c(0,2), verbose=TRUE))
*/

log close
clear
*************************************************************************************************
*************************************************************************************************
*************************************************************************************************
*************************************************************************************************
*************************************************************************************************

