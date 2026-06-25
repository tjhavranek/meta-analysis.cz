***************************************************************************************
***************************************************************************************
********** Publication and Attenuation Bias in Measuring Skill Substitution ***********
***************************************************************************************
***************************************************************************************
* December 21, 2021
log using skill.log, replace
import excel skill.xlsx, sheet("data") firstrow
*use "skill.dta"
set more off
xtset idstudy
***************************************************************************************
* Data preparation
***************************************************************************************

gen coefficient = -1/elasticity
gen se_coefficient = se/(elasticity^2)
gen precision_coefficient = 1/se_coefficient

gen elasticity_new = .
replace elasticity_new = elasticity if inverted_estimate==0
drop elasticity
rename elasticity_new elasticity
gen se_new = .
replace se_new = se if inverted_estimate==0
drop se
rename se_new se

gen coefficient_new = .
replace coefficient_new = coefficient if inverted_estimate==1
drop coefficient
rename coefficient_new coefficient
gen se_coefficient_new = .
replace se_coefficient_new = se_coefficient if inverted_estimate==1
drop se_coefficient
rename se_coefficient_new se_coefficient

winsor2 elasticity, suffix(_w) cuts(1 99)
winsor2 se, suffix(_w) cuts(1 99)
winsor2 coefficient, suffix(_w) cuts(1 99) 
winsor2 se_coefficient, suffix(_w) cuts(1 99) 

gen tstat_w = elasticity_w/se_w
gen tstat_coefficient_w = coefficient_w/se_coefficient_w
gen precision_w = 1/se_w
gen precision_coefficient_w = 1/se_coefficient_w

gen onelevel_ces_function2 = 0
replace onelevel_ces_function2 = 1 if (multilevel_ces_function==0|other_function==1)
gen se_iv_method2 = se_coefficient_w*iv_method2
gen se_developing_country = se_coefficient_w*developing_country

***************************************************************************************
* Summary statistics
***************************************************************************************

sum elasticity elasticity_w se se_w if inverted_estimate==0 & se_w!=., detail
sum coefficient coefficient_w se_coefficient se_coefficient_w if inverted_estimate==1, detail

sum coefficient_w se_coefficient_w se_iv_method2 se_developing_country higher_frequency annual_frequency lower_frequency micro_data sectoral_data aggregated_data cross_section data_midyear united_states developing_country manufacturing_sector region_estimate country_estimate onelevel_ces_function2 multilevel_ces_function time_control location_control macro_control age_control capital_control dynamic_model unit_fixed_effects time_fixed_effects ols_method2 iv_method2 natural_experiment impact_factor citations published_study if inverted_estimate==1 & se_coefficient_w!=. 
sum coefficient_w se_coefficient_w se_iv_method2 se_developing_country higher_frequency annual_frequency lower_frequency micro_data sectoral_data aggregated_data cross_section data_midyear united_states developing_country manufacturing_sector region_estimate country_estimate onelevel_ces_function2 multilevel_ces_function time_control location_control macro_control age_control capital_control dynamic_model unit_fixed_effects time_fixed_effects ols_method2 iv_method2 natural_experiment impact_factor citations published_study [aweight=weight] if inverted_estimate==1 & se_coefficient_w!=. 
correlate se_coefficient_w se_iv_method2 se_developing_country higher_frequency annual_frequency lower_frequency micro_data sectoral_data aggregated_data cross_section data_midyear united_states developing_country manufacturing_sector region_estimate country_estimate onelevel_ces_function2 multilevel_ces_function time_control location_control macro_control capital_control dynamic_model unit_fixed_effects time_fixed_effects ols_method2 iv_method2 natural_experiment impact_factor citations published_study if inverted_estimate==1 & se_coefficient_w!=. 
collin se_coefficient_w se_iv_method2 se_developing_country higher_frequency lower_frequency micro_data sectoral_data cross_section data_midyear united_states developing_country manufacturing_sector country_estimate multilevel_ces_function time_control location_control macro_control age_control capital_control dynamic_model unit_fixed_effects time_fixed_effects iv_method2 natural_experiment impact_factor citations published_study if inverted_estimate==1  & se_coefficient_w!=. 

mean elasticity_w if inverted_estimate==0
mean coefficient_w if inverted_estimate==1
mean coefficient_w if higher_frequency==1 & inverted_estimate==1
mean coefficient_w if annual_frequency==1 & inverted_estimate==1
mean coefficient_w if lower_frequency==1 & inverted_estimate==1
mean coefficient_w if micro_data==1 & inverted_estimate==1
mean coefficient_w if sectoral_data==1 & inverted_estimate==1
mean coefficient_w if aggregated_data==1 & inverted_estimate==1
mean coefficient_w if cross_section==1 & inverted_estimate==1
mean coefficient_w if cross_section==0 & inverted_estimate==1
mean coefficient_w if united_states==1 & inverted_estimate==1
mean coefficient_w if united_states==0 & inverted_estimate==1
mean coefficient_w if developed_country==1 & inverted_estimate==1
mean coefficient_w if developing_country==1 & inverted_estimate==1
mean coefficient_w if manufacturing_sector==1 & inverted_estimate==1
mean coefficient_w if manufacturing_sector==0 & inverted_estimate==1
mean coefficient_w if region_estimate==1 & inverted_estimate==1
mean coefficient_w if country_estimate==1 & inverted_estimate==1
mean coefficient_w if onelevel_ces_function2==1 & inverted_estimate==1
mean coefficient_w if multilevel_ces_function==1 & inverted_estimate==1
mean coefficient_w if dynamic_model==1 & inverted_estimate==1
mean coefficient_w if unit_fixed_effects==1 & inverted_estimate==1
mean coefficient_w if time_fixed_effects==1 & inverted_estimate==1
mean coefficient_w if ols_method2==1 & inverted_estimate==1 
mean coefficient_w if iv_method2==1 & inverted_estimate==1
mean coefficient_w if natural_experiment==1 & inverted_estimate==1
mean coefficient_w if published_study==0 & inverted_estimate==1
mean coefficient_w if published_study==1 & inverted_estimate==1
mean coefficient_w if top_journal==1 & inverted_estimate==1

mean elasticity_w [aweight=weight] if inverted_estimate==0
mean coefficient_w [aweight=weight] if inverted_estimate==1
mean coefficient_w [aweight=weight] if higher_frequency==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if annual_frequency==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if lower_frequency==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if micro_data==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if sectoral_data==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if aggregated_data==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if cross_section==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if cross_section==0 & inverted_estimate==1
mean coefficient_w [aweight=weight] if united_states==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if united_states==0 & inverted_estimate==1
mean coefficient_w [aweight=weight] if developed_country==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if developing_country==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if manufacturing_sector==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if manufacturing_sector==0 & inverted_estimate==1
mean coefficient_w [aweight=weight] if region_estimate==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if country_estimate==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if onelevel_ces_function2==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if multilevel_ces_function==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if dynamic_model==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if unit_fixed_effects==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if time_fixed_effects==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if ols_method2==1 & inverted_estimate==1 
mean coefficient_w [aweight=weight] if iv_method2==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if natural_experiment==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if published_study==0 & inverted_estimate==1
mean coefficient_w [aweight=weight] if published_study==1 & inverted_estimate==1
mean coefficient_w [aweight=weight] if top_journal==1 & inverted_estimate==1

histogram elasticity if elasticity >-2 & elasticity<8 & inverted_estimate==0, bin(60) fcolor(gs14) lstyle(thin) frequency xtitle("Direct estimate of the elasticity") xline(1 2, lcolor(red)) xlabel(-2 0 1 2 5 8) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram_direct, replace)
histogram coefficient if coefficient >-3 & coefficient<1 & inverted_estimate==1, bin(50) fcolor(gs14) lstyle(thin) frequency xtitle("Estimate of the negative of inverse elasticity") xline(-1 -0.5, lcolor(red)) xlabel(-3 -2 -1 -0.5 0 1) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram, replace)

twoway(hist coefficient if ols_method2==1 & coefficient >-4 & coefficient<1, bin(60) freq fcolor(navy) lcolor(navy) legend(label(1 "OLS method"))) (hist coefficient if iv_method2==1 & coefficient >-4 & coefficient<1, bin(60) freq fcolor(cranberry) lcolor(cranberry) legend(label(2 "IV method"))) (hist coefficient if natural_experiment==1 & coefficient >-4 & coefficient<1, bin(60) gap(20) freq  lcolor(gs12) fcolor(gs12) legend(label(3 "Natural experiment"))), legend(ring(0) position(10) bmargin(medium) rows(3) region(lstyle(none))) xtitle("Estimate of the negative of the inverse elasticity")  saving(pattern1, replace)
twoway(hist coefficient if developed_country==1 & coefficient >-4 & coefficient<1, bin(60) freq fcolor(navy) lcolor(navy) legend(label(1 "Developed country")))(hist coefficient if developing_country==1 & coefficient >-4 & coefficient<1, bin(60) gap(10) freq fcolor(gs12) lcolor(gs12) legend(label(2 "Developing country"))) , legend(ring(0) position(10) bmargin(medium) rows(2) region(lstyle(none))) xtitle("Estimate of the negative of the inverse elasticity")  saving(pattern2, replace)
twoway(hist coefficient if country_estimate==1 & coefficient >-4 & coefficient<1, bin(60) freq fcolor(navy) lcolor(navy) legend(label(1 "Country estimate"))) (hist coefficient if region_estimate==1 & coefficient >-4 & coefficient<1, bin(40) gap(10) freq fcolor(gs12) lcolor(gs12) legend(label(2 "Regional estimate"))), legend(ring(0) position(10) bmargin(medium) rows(2) region(lstyle(none))) xtitle("Estimate of the negative of the inverse elasticity")  saving(pattern3, replace)
twoway(hist coefficient if multilevel_ces==1 & coefficient >-4 & coefficient<1, bin(60) freq fcolor(navy) lcolor(navy) legend(label(1 "Multi-level CES"))) (hist coefficient if onelevel_ces_function==1 & coefficient >-4 & coefficient<1, bin(60) gap(10) freq  lcolor(gs12) fcolor(gs12) legend(label(2 "One-level CES"))), legend(ring(0) position(10) bmargin(medium) rows(3) region(lstyle(none)))  xtitle("Estimate of the negative of the inverse elasticity")  saving(pattern4, replace)

replace elasticity = -1/coefficient if inverted_estimate==1
bysort idstudy: egen elasticity_med = median(elasticity)
bysort idstudy: egen midyear_med = median(midyear)
generate elasticity_med_w=elasticity_med
graph twoway (scatter elasticity_med_w midyear_med if elasticity_med_w<7 & elasticity_med_w>0, msize(*1) msymbol(Oh) yline(1, lpattern(dott)) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray))) (lfit elasticity_med_w midyear_med, lcolor(black) lpattern(dash)),  xtitle("Median year of data used by a study") ytitle("Median estimate of the elasticity of substitution") legend(off) saving(trend, replace)

graph hbox coefficient if coefficient >-3 & coefficient<1 & inverted_estimate==1, over(author,label(grid) sort(midyear_med)) xsize(2.6) ysize(4) scale(0.55) yline(-1, lcolor (red))  box(1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow)  mcolor(gs12)) ytitle("Estimate of the negative of the inverse elasticity") ylabel(, nogrid) saving(studies, replace) 
graph hbox coefficient if coefficient >-3 & coefficient<1 & inverted_estimate==1 & (idcountry!=6 & idcountry!=7 & idcountry!=15 & idcountry!=20 & idcountry!=21 & idcountry!=23 & idcountry!=28), over(country,label(grid)) xsize(6) ysize(5) scale(0.8) yline(-1, lcolor (red))  box( 1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow)  mcolor(gs12)) ytitle("Estimate of the negative of the inverse elasticity") ylabel(, nogrid) saving(countries, replace) 

***************************************************************************************
* PUBLICATION BIAS - Funnel plot (Egger et al., 1997)
***************************************************************************************

*Direct estimates
twoway scatter precision elasticity if elasticity>-10 & elasticity<10 & inverted_estimate==0, ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of the elasticity") xline(0, lpattern(solid) lcolor (black))  xlabel(0 , add) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel_direct, replace)
*Inverse estimates
twoway scatter precision_coefficient coefficient if  coefficient<20 & coefficient>-4 & inverted_estimate==1, ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of the negative of the inverse elasticity") xline(0, lpattern(solid) lcolor (black)) xlabel(0 , add) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel, replace)

***************************************************************************************
* PUBLICATION BIAS - FAT-PET (Stanley, 2005) for WLS, FE, BE, and IV
***************************************************************************************

xtset idstudy

*Direct estimates: All
sum elasticity_w if inverted_estimate==0 & se_w!=.
eststo: ivreg2 tstat_w precision_w if inverted_estimate==0, cluster(idstudy)
		boottest precision_w, nograph
		boottest _cons, nograph 
eststo: xtreg tstat_w precision_w if inverted_estimate==0, fe vce(cluster idstudy)
		boottest precision_w, nograph gridmin(-100) gridmax(+100)
eststo: xtreg tstat_w precision_w if inverted_estimate==0, be 
eststo: ivreg2 tstat_w (precision_w=instrument_se) if inverted_estimate==0, cluster(idstudy) first
		boottest precision_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls tstat_w (precision_w=instrument_se) if inverted_estimate==0, cluster(idstudy)
esttab using tab01_direct.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*Inverse estimates: All
sum coefficient_w if inverted_estimate==1 & se_coefficient_w!=.
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if inverted_estimate==1, cluster(idstudy)
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
eststo: xtreg tstat_coefficient_w precision_coefficient_w if inverted_estimate==1, fe vce(cluster idstudy)
		boottest precision_coefficient_w, nograph gridmin(-100) gridmax(+100)
eststo: xtreg tstat_coefficient_w precision_coefficient_w if inverted_estimate==1, be 
eststo: ivreg2 tstat_coefficient_w (precision_coefficient_w=instrument_sec) if inverted_estimate==1, cluster(idstudy) 
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls tstat_coefficient_w (precision_coefficient_w=instrument_sec) if inverted_estimate==1, cluster(idstudy)
esttab using tab02_inverse.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
 
*Inverse estimates: Ordinary least squares
sum coefficient_w if ols_method2==1 & inverted_estimate==1 & se_coefficient_w!=.
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if ols_method2==1 & inverted_estimate==1, cluster(idstudy)
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph  
eststo: xtreg tstat_coefficient_w precision_coefficient_w if ols_method2==1 & inverted_estimate==1, fe vce(cluster idstudy)
		boottest precision_coefficient_w, nograph gridmin(-100) gridmax(+100)
eststo: xtreg tstat_coefficient_w precision_coefficient_w if ols_method2==1 & inverted_estimate==1, be 
eststo: ivreg2 tstat_coefficient_w (precision_coefficient_w=instrument_sec) if ols_method2==1 & inverted_estimate==1, cluster(idstudy) robust first
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls tstat_coefficient_w (precision_coefficient_w=instrument_sec) if ols_method2==1 & inverted_estimate==1, cluster(idstudy)
esttab using tab03_invOLS.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*Inverse estimates: Instrumental variables
sum coefficient_w if iv_method2==1 & inverted_estimate==1 & se_coefficient_w!=.
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if iv_method2==1 & inverted_estimate==1, cluster(idstudy)
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph  
eststo: xtreg tstat_coefficient_w precision_coefficient_w if iv_method2==1 & inverted_estimate==1, fe vce(cluster idstudy)
		boottest precision_coefficient_w, nograph gridmin(-100) gridmax(+100)
eststo: xtreg tstat_coefficient_w precision_coefficient_w if iv_method2==1 & inverted_estimate==1, be 
eststo: ivreg2 tstat_coefficient_w (precision_coefficient_w=instrument_sec) if iv_method2==1 & inverted_estimate==1, cluster(idstudy) robust first
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls tstat_coefficient_w (precision_coefficient_w=instrument_sec) if iv_method2==1 & inverted_estimate==1, cluster(idstudy)
esttab using tab04_invIV.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*Inverse estimates: Natural experiments
sum coefficient_w if natural_experiment==1 & inverted_estimate==1 & se_coefficient_w!=.
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if natural_experiment==1 & inverted_estimate==1, cluster(idstudy)
		boottest precision_coefficient_w, nograph weight(webb)
		boottest _cons, nograph
eststo: xtreg tstat_coefficient_w precision_coefficient_w if natural_experiment==1 & inverted_estimate==1, fe vce(cluster idstudy)
		boottest precision_coefficient_w, nograph gridmin(-100) gridmax(+100)
eststo: xtreg tstat_coefficient_w precision_coefficient_w if natural_experiment==1 & inverted_estimate==1, be 
eststo: ivreg2 tstat_coefficient_w (precision_coefficient_w=instrument_sec) if natural_experiment==1 & inverted_estimate==1, cluster(idstudy) robust first
		boottest precision_coefficient_w, nograph gridmin(-100) gridmax(+100)
		boottest _cons, nograph 
		twostepweakiv 2sls tstat_coefficient_w (precision_coefficient_w=instrument_sec) if natural_experiment==1 & inverted_estimate==1, cluster(idstudy)
esttab using tab05_invNEXP.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*Inverse estimates: Developed world
sum coefficient_w if developed_country==1 & inverted_estimate==0 & se_coefficient_w!=.
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if developed_country==1 & inverted_estimate==1, cluster(idstudy)
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
eststo: xtreg tstat_coefficient_w precision_coefficient_w if developed_country==1 & inverted_estimate==1, fe vce(cluster idstudy)
		boottest precision_coefficient_w, nograph gridmin(-100) gridmax(+100)
eststo: xtreg tstat_coefficient_w precision_coefficient_w if developed_country==1 & inverted_estimate==1, be 
eststo: ivreg2 tstat_coefficient_w (precision_coefficient_w=instrument_sec) if developed_country==1 & inverted_estimate==1, cluster(idstudy) robust first
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls tstat_coefficient_w (precision_coefficient_w=instrument_sec) if developed_country==1 & inverted_estimate==1, cluster(idstudy)
esttab using tab08a_invDEVED.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*Inverse estimates: Developing world
sum coefficient_w if developing_country==1 & inverted_estimate==1 & se_coefficient_w!=.
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if developing_country==1 & inverted_estimate==1, cluster(idstudy)
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
eststo: xtreg tstat_coefficient_w precision_coefficient_w if developing_country==1 & inverted_estimate==1, fe vce(cluster idstudy)
		boottest precision_coefficient_w, nograph gridmin(-100) gridmax(+100)
eststo: xtreg tstat_coefficient_w precision_coefficient_w if developing_country==1 & inverted_estimate==1, be 
eststo: ivreg2 tstat_coefficient_w (precision_coefficient_w=instrument_sec) if developing_country==1 & inverted_estimate==1, cluster(idstudy) robust first
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls tstat_coefficient_w (precision_coefficient_w=instrument_sec) if developing_country==1 & inverted_estimate==1, cluster(idstudy)
esttab using tab08b_invDEVING.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*Inverse estimates: Aggregate (country) estimate
sum coefficient_w if country_estimate==1 & inverted_estimate==1 & se_coefficient_w!=.
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if country_estimate==1 & inverted_estimate==1, cluster(idstudy)
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
eststo: xtreg tstat_coefficient_w precision_coefficient_w if country_estimate==1 & inverted_estimate==1, fe vce(cluster idstudy)
		boottest precision_coefficient_w, nograph gridmin(-100) gridmax(+100)
eststo: xtreg tstat_coefficient_w precision_coefficient_w if country_estimate==1 & inverted_estimate==1, be 
eststo: ivreg2 tstat_coefficient_w (precision_coefficient_w=instrument_sec) if country_estimate==1 & inverted_estimate==1, cluster(idstudy) robust first
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls tstat_coefficient_w (precision_coefficient_w=instrument_sec) if country_estimate==1 & inverted_estimate==1, cluster(idstudy)
esttab using tab09_invCOUNTRY.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*Inverse estimates: Less-aggregate (region & city) estimate
sum coefficient_w if region_estimate==1 & inverted_estimate==1 & se_coefficient_w!=.
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if region_estimate==1 & inverted_estimate==1, cluster(idstudy)
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
eststo: xtreg tstat_coefficient_w precision_coefficient_w if region_estimate==1 & inverted_estimate==1, fe vce(cluster idstudy)
		boottest precision_coefficient_w, nograph gridmin(-100) gridmax(+100)
eststo: xtreg tstat_coefficient_w precision_coefficient_w if region_estimate==1 & inverted_estimate==1, be 
eststo: ivreg2 tstat_coefficient_w (precision_coefficient_w=instrument_sec) if region_estimate==1 & inverted_estimate==1, cluster(idstudy) robust first
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls tstat_coefficient_w (precision_coefficient_w=instrument_sec) if region_estimate==1 & inverted_estimate==1, cluster(idstudy)
esttab using tab10_invREGION.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*Inverse estimates: One-level CES
sum coefficient_w if onelevel_ces_function==1 & inverted_estimate==1 & se_coefficient_w!=.
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if onelevel_ces_function==1 & inverted_estimate==1, cluster(idstudy)
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
eststo: xtreg tstat_coefficient_w precision_coefficient_w if onelevel_ces_function==1 & inverted_estimate==1, fe vce(cluster idstudy)
		boottest precision_coefficient_w, nograph gridmin(-100) gridmax(+100)
eststo: xtreg tstat_coefficient_w precision_coefficient_w if onelevel_ces_function==1 & inverted_estimate==1, be 
eststo: ivreg2 tstat_coefficient_w (precision_coefficient_w=instrument_sec) if onelevel_ces_function==1 & inverted_estimate==1, cluster(idstudy) robust first
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls tstat_coefficient_w (precision_coefficient_w=instrument_sec) if onelevel_ces_function==1 & inverted_estimate==1, cluster(idstudy)
esttab using tab11_inv1CES.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*Inverse estimates: Multilevel CES
sum coefficient_w if multilevel_ces==1 & inverted_estimate==1 & se_coefficient_w!=.
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if multilevel_ces==1 & inverted_estimate==1, cluster(idstudy)
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
eststo: xtreg tstat_coefficient_w precision_coefficient_w if multilevel_ces==1 & inverted_estimate==1, fe vce(cluster idstudy)
		boottest precision_coefficient_w, nograph gridmin(-100) gridmax(+100)
eststo: xtreg tstat_coefficient_w precision_coefficient_w if multilevel_ces==1 & inverted_estimate==1, be 
eststo: ivreg2 tstat_coefficient_w (precision_coefficient_w=instrument_sec) if multilevel_ces==1 & inverted_estimate==1, cluster(idstudy) robust first
		boottest precision_coefficient_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls tstat_coefficient_w (precision_coefficient_w=instrument_sec) if multilevel_ces==1 & inverted_estimate==1, cluster(idstudy)
esttab using tab12_invMCES.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

***************************************************************************************
* PUBLICATION BIAS - WAAP (Ioannidis et al., 2017) 
***************************************************************************************

*Direct estimates
summarize elasticity [aweight=1/(se*se)] if inverted_estimate==0 
gen waapbound_e = abs(r(mean))/2.8
reg tstat precision if se < waapbound_e & inverted_estimate==0, noconstant

*Inverse estimates
summarize coefficient [aweight=1/(se_coefficient*se_coefficient)] if inverted_estimate==1 
gen waapbound_c = abs(r(mean))/2.8
reg tstat_coefficient precision_coefficient if se_coefficient < waapbound_c & inverted_estimate==1, noconstant

*Inverse estimates: Ordinary least squares
summarize coefficient [aweight=1/(se_coefficient*se_coefficient)] if ols_method2==1 & inverted_estimate==1 
gen waapbound_ols = abs(r(mean))/2.8
reg tstat_coefficient precision_coefficient if se_coefficient < waapbound_ols & ols_method2==1 & inverted_estimate==1, noconstant

*Inverse estimates: Instrumental variables
summarize coefficient [aweight=1/(se_coefficient*se_coefficient)] if iv_method2==1 & inverted_estimate==1 
gen waapbound_iv = abs(r(mean))/2.8
reg tstat_coefficient precision_coefficient if se_coefficient < waapbound_iv & iv_method2==1 & inverted_estimate==1, noconstant

*Inverse estimates: Natural experiments
summarize coefficient [aweight=1/(se_coefficient*se_coefficient)] if natural_experiment==1 & inverted_estimate==1 
gen waapbound_nexp = abs(r(mean))/2.8
summarize coefficient if se_coefficient < waapbound_nexp & natural_experiment==1 & inverted_estimate==1

*Inverse estimates: Developed world
summarize coefficient [aweight=1/(se_coefficient*se_coefficient)] if developed_country==1 & inverted_estimate==1 
gen waapbound_ded = abs(r(mean))/2.8
reg tstat_coefficient precision_coefficient if se_coefficient < waapbound_ded & developed_country==1 & inverted_estimate==1, noconstant

*Inverse estimates: Developing world
summarize coefficient [aweight=1/(se_coefficient*se_coefficient)] if developing_country==1 & inverted_estimate==1 
gen waapbound_ding = abs(r(mean))/2.8
reg tstat_coefficient precision_coefficient if se_coefficient < waapbound_ding & developing_country==1 & inverted_estimate==1, noconstant

*Inverse estimates: Aggregate (country) estimate
summarize coefficient [aweight=1/(se_coefficient*se_coefficient)] if country_estimate==1 & inverted_estimate==1 
gen waapbound_country = abs(r(mean))/2.8
reg tstat_coefficient precision_coefficient if se_coefficient < waapbound_country & country_estimate==1 & inverted_estimate==1, noconstant

*Inverse estimates: Less-aggregate (region & city) estimate
summarize coefficient [aweight=1/(se_coefficient*se_coefficient)] if region_estimate==1 & inverted_estimate==1 
gen waapbound_region = abs(r(mean))/2.8
reg tstat_coefficient precision_coefficient if se_coefficient < waapbound_region & region_estimate==1 & inverted_estimate==1, noconstant

*Inverse estimates: One-level CES
summarize coefficient [aweight=1/(se_coefficient*se_coefficient)] if onelevel_ces_function==1 & inverted_estimate==1 
gen waapbound_1ces = abs(r(mean))/2.8
reg tstat_coefficient precision_coefficient if se_coefficient < waapbound_1ces & onelevel_ces_function==1 & inverted_estimate==1, noconstant

*Inverse estimates: Multilevel CES
summarize coefficient [aweight=1/(se_coefficient*se_coefficient)] if inverted_estimate==1 
gen waapbound_mces = abs(r(mean))/2.8
reg tstat_coefficient precision_coefficient if se_coefficient < waapbound_mces & inverted_estimate==1, noconstant

***************************************************************************************
* PUBLICATION BIAS - Caliper test (Gerber & Malhotra, 2008)
***************************************************************************************

histogram tstat_w if 20>tstat_w & tstat_w>-6 & inverted_estimate==0, bin(40) fcolor(gs14) lstyle(thin) frequency normal xtitle("t-statistics of the elasticity estimates") xlabel(-5 0 1.96 5 10 15 20) xline(0 1.96 , lcolor(red)) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(caliper_direct, replace)
histogram tstat_coefficient_w if -20<tstat_coefficient_w & tstat_coefficient_w<6 & inverted_estimate==1, bin(40) fcolor(gs14) lstyle(thin) frequency normal xtitle("t-statistics of the inverse of elasticity estimates") xlabel(5 0 -1.96 -5 -10 -15 -20) xline(0 -1.96 , lcolor(red)) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(caliper, replace)

*Inverse estimates, caliper for tstat below -1.96
generate significant = 0
replace significant = 1 if tstat_coefficient_w > -1.96
reg significant if tstat_coefficient_w > -2.21 & tstat_coefficient_w < -1.71 & inverted_estimate==1
 lincom _cons - 0.5
reg significant if tstat_coefficient_w > -2.26 & tstat_coefficient_w < -1.66 & inverted_estimate==1
 lincom _cons - 0.5
reg significant if tstat_coefficient_w > -2.31 & tstat_coefficient_w < -1.61 & inverted_estimate==1
 lincom _cons - 0.5
reg significant if tstat_coefficient_w > -2.36 & tstat_coefficient_w < -1.56 & inverted_estimate==1
 lincom _cons - 0.5

*Inverse estimates, caliper for tstat above 1.96 for inverse sigma around -1
gen tstat_coefficient_1 = (coefficient_w + 1)/se_coefficient_w
sum tstat_coefficient_1 if inverted_estimate==1
gen unity = 0
replace unity = 1 if tstat_coefficient_1 < 1.96 // smaller than 1.96 to get interpretation of the coeff as the share of estimates "above" caliper minus 0.5
reg unity if tstat_coefficient_1 < 2.21 & tstat_coefficient_1 > 1.71 & inverted_estimate==1
 lincom _cons - 0.5
reg unity if tstat_coefficient_1 < 2.26 & tstat_coefficient_1 > 1.66 & inverted_estimate==1
 lincom _cons - 0.5
reg unity if tstat_coefficient_1 < 2.31 & tstat_coefficient_1 > 1.61 & inverted_estimate==1
 lincom _cons - 0.5
reg unity if tstat_coefficient_1 < 2.36 & tstat_coefficient_1 > 1.56 & inverted_estimate==1
 lincom _cons - 0.5
 
 *Inverse estimates, caliper for inverse sigma below 0
generate zero_coeff = 0
replace zero_coeff = 1 if coefficient_w > 0
reg zero_coeff if coefficient_w > -0.075 & coefficient_w < 0.075 & inverted_estimate==1
 lincom _cons - 0.5
reg zero_coeff if coefficient_w > -0.10 & coefficient_w < 0.10 & inverted_estimate==1
 lincom _cons - 0.5
reg zero_coeff if coefficient_w > -0.125 & coefficient_w < 0.125 & inverted_estimate==1
 lincom _cons - 0.5
reg zero_coeff if coefficient_w > -0.15 & coefficient_w < 0.15 & inverted_estimate==1
 lincom _cons - 0.5
 
 *Inverse estimates, caliper for inverse sigma below -1
generate unity_coeff = 0
replace unity_coeff = 1 if coefficient_w > -1
reg unity_coeff if coefficient_w > -1.075 & coefficient_w < -0.925 & inverted_estimate==1
 lincom _cons - 0.5
reg unity_coeff if coefficient_w > -1.100 & coefficient_w < -0.900 & inverted_estimate==1
 lincom _cons - 0.5
reg unity_coeff if coefficient_w > -1.125 & coefficient_w < -0.875 & inverted_estimate==1
 lincom _cons - 0.5
reg unity_coeff if coefficient_w > -1.150 & coefficient_w < -0.850 & inverted_estimate==1
 lincom _cons - 0.5
 
***************************************************************************************
* PUBLICATION BIAS - Stem-based method in R (Furukawa, 2019)
***************************************************************************************

/*
source("stem_method.R") #github.com/Chishio318/stem-based_method
datalabor = read.table("clipboard-512", sep="\t", header=TRUE)
stem_results = stem(datalabor$coefficient, datalabor$se_coefficient, param)
stem_results[["estimates"]]
*/

***************************************************************************************
* PUBLICATION BIAS - Endogenous kink (Bom & Rachinger, 2020)
*      code downloaded from https://sites.google.com/site/heikorachinger/codes 
***************************************************************************************

*drop if inverted_estimate==1
*export excel using "skill_direct.xlsx", sheet("direct") replace first(var) 

drop if inverted_estimate==0
export excel using "skill_inverse.xlsx", sheet("inverse") replace first(var) 

*Direct estimates
*clear
*import excel skill_direct.xlsx, sheet("direct") firstrow
*quietly{
*rename elasticity bs
*rename se sebs
*gen ones=1
*sum
*local M=r(N)
*sum sebs
*local sebs_min=r(min)
*local sebs_max=r(max)
*gen sebs2=sebs^2
*gen wis=ones/sebs2
*gen bs_sebs=bs/sebs
*gen ones_sebs=ones/sebs
*gen bswis=bs*wis
*sum wis
*local wis_sum=r(sum)

*regress bs_sebs ones_sebs ones,noc
*local pet=_b[ones_sebs]
*local t1_linreg = (_b[ones_sebs]/_se[ones_sebs])
*local b_lin=_b[ones_sebs]
*local Q1_lin = e(rss)
*di `t1_linreg'
*local abs_t1_linreg = abs(`t1_linreg')
*di `abs_t1_linreg'

*regress bs_sebs ones_sebs sebs,noc
*local peese=_b[ones_sebs]
*local b_sq=_b[ones_sebs]
*local Q1_sq = e(rss)
*di `Q1_sq'

*if `abs_t1_linreg' > invt(`M-2', 0.975) {
*    local combreg=`b_sq'
*	local Q1=`Q1_sq'
*	}
*else {
*    local combreg=`b_lin'
*	local Q1=`Q1_lin'
*}

*local sigh2hat=max(0,`M'*((`Q1'/(`M'-e(df_m)-1))-1)/`wis_sum') 
*local sighhat=sqrt(`sigh2hat') 

*if `combreg'>1.96*`sighhat' {
*    local a1=(`combreg'-1.96*`sighhat')*(`combreg'+1.96*`sighhat')/(2*1.96*`combreg')
*}
*else {
*	local a1=0
*	}
*	rename bs bs_original
*	rename bs_sebs bs
*	rename ones_sebs constant
*	rename ones pub_bias
*    noisily: display "EK regression: "
*if `a1'>`sebs_min' & `a1'<`sebs_max' {
*    gen sebs_a1=sebs-`a1' if sebs>`a1'
*	replace sebs_a1=0 if sebs<=`a1'
*	gen pubbias=sebs_a1/sebs
*	noisily regress bs constant pubbias, noc
*	local b0_ek=_b[constant]
*	local b1_ek=_b[pubbias]
*	local sd0_ek=_se[constant]
*	local sd1_ek=_se[pubbias]
*}
*else if `a1'<`sebs_min' {
*    noisily regress bs constant pub_bias, noc
*	local b0_ek=_b[constant]
*	local b1_ek=_b[pub_bias]
*	local sd0_ek=_se[constant]
*	local sd1_ek=_se[pub_bias]
*}
*else if `a1'>`sebs_max' {
*    noisily regress bs constant, noc
*	local b0_ek=_b[constant]
*	local sd0_ek=_se[constant]	
*}
*noisily: display "EK's mean effect estimate (alpha1) and standard error:"
*noisily: di `b0_ek' 
*noisily: di `sd0_ek' 
*noisily: display "EK's publication bias estimate (delta) and standard error:"
*noisily: di `b1_ek' 
*noisily: di `sd1_ek' 
*}

*Inverse estimates
clear
import excel skill_inverse.xlsx, sheet("inverse") firstrow
quietly{
rename coefficient bs
rename se_coefficient sebs
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

*Inverse estimates: Ordinary least squares
clear
import excel skill_inverse.xlsx, sheet("inverse") firstrow
drop if ols_method2==0
quietly{
rename coefficient bs
rename se_coefficient sebs
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

*Inverse estimates: Instrumental variables
clear
import excel skill_inverse.xlsx, sheet("inverse") firstrow
drop if  iv_method2==0
quietly{
rename coefficient bs
rename se_coefficient sebs
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

*Inverse estimates: Natural experiments
clear
import excel skill_inverse.xlsx, sheet("inverse") firstrow
drop if  natural_experiment==0
quietly{
rename coefficient bs
rename se_coefficient sebs
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

*Inverse estimates: United States
clear
import excel skill_inverse.xlsx, sheet("inverse") firstrow
drop if  united_states==0
quietly{
rename coefficient bs
rename se_coefficient sebs
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

*Inverse estimates: Europe
clear
import excel skill_inverse.xlsx, sheet("inverse") firstrow
drop if  europe==0
quietly{
rename coefficient bs
rename se_coefficient sebs
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

*Inverse estimates: Developed world
clear
import excel skill_inverse.xlsx, sheet("inverse") firstrow
drop if developed_country==0
quietly{
rename coefficient bs
rename se_coefficient sebs
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

*Inverse estimates: Developing world
clear
import excel skill_inverse.xlsx, sheet("inverse") firstrow
drop if developing_country==0
quietly{
rename coefficient bs
rename se_coefficient sebs
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

*Inverse estimates: Aggregate (country) estimate
clear
import excel skill_inverse.xlsx, sheet("inverse") firstrow
drop if country_estimate==0
quietly{
rename coefficient bs
rename se_coefficient sebs
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

*Inverse estimates: Less-aggregate estimate
clear
import excel skill_inverse.xlsx, sheet("inverse") firstrow
drop if region_estimate==0
quietly{
rename coefficient bs
rename se_coefficient sebs
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

*Inverse estimates: One-level CES
clear
import excel skill_inverse.xlsx, sheet("inverse") firstrow
drop if onelevel_ces_function==0
quietly{
rename coefficient bs
rename se_coefficient sebs
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

*Inverse estimates: Multi-level CES
clear
import excel skill_inverse.xlsx, sheet("inverse") firstrow
drop if multilevel_ces==0
quietly{
rename coefficient bs
rename se_coefficient sebs
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

***************************************************************************************
* HETEROGENEITY - Data preparation
***************************************************************************************

* generate data for R
clear
import excel skill_inverse.xlsx, sheet("inverse") firstrow
drop if se_coefficient_w==.

local variables coefficient_w se_iv_method2 se_developing_country higher_frequency lower_frequency micro_data sectoral_data cross_section united_states developing_country manufacturing_sector multilevel_ces_function time_control location_control macro_control age_control capital_control dynamic_model unit_fixed_effects time_fixed_effects iv_method2 natural_experiment impact_factor citations
foreach x of varlist `variables' {
gen double w_`x'=`x'*precision_coefficient_w
replace `x' = w_`x'
drop w_`x'
}

keep idstudy coefficient_w precision_coefficient_w se_iv_method2 se_developing_country higher_frequency lower_frequency micro_data sectoral_data cross_section united_states developing_country manufacturing_sector multilevel_ces_function time_control location_control macro_control age_control capital_control dynamic_model unit_fixed_effects time_fixed_effects iv_method2 natural_experiment impact_factor citations 
order idstudy coefficient_w precision_coefficient_w se_iv_method2 se_developing_country higher_frequency lower_frequency micro_data sectoral_data cross_section united_states developing_country manufacturing_sector multilevel_ces_function time_control location_control macro_control age_control capital_control dynamic_model unit_fixed_effects time_fixed_effects iv_method2 natural_experiment impact_factor citations 
export excel "skill_4R_w.xlsx", sheet("data") replace first(var)

correlate precision_coefficient_w se_iv_method2 se_developing_country higher_frequency lower_frequency micro_data sectoral_data cross_section united_states developing_country manufacturing_sector multilevel_ces_function time_control location_control macro_control age_control capital_control dynamic_model unit_fixed_effects time_fixed_effects iv_method2 natural_experiment impact_factor citations 
collin precision_coefficient_w se_iv_method2 se_developing_country higher_frequency lower_frequency micro_data sectoral_data cross_section united_states developing_country manufacturing_sector multilevel_ces_function time_control location_control macro_control age_control capital_control dynamic_model unit_fixed_effects time_fixed_effects iv_method2 natural_experiment impact_factor citations 

***************************************************************************************
* HETEROGENEITY - Robustness check
***************************************************************************************

ivreg2 coefficient_w precision_coefficient_w se_iv_method2 se_developing_country lower_frequency micro_data sectoral_data united_states developing_country multilevel_ces_function location_control macro_control capital_control unit_fixed_effects iv_method2 natural_experiment impact_factor, cluster(idstudy)

***************************************************************************************
* HETEROGENEITY - Testing the most precise estimates (pval < 0.005)
***************************************************************************************
clear 
import excel skill_inverse.xlsx, sheet("inverse") firstrow
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if inverted_estimate==1 & tstat_coefficient_w<-2.80, cluster(idstudy)
		boottest _cons, nograph 
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if inverted_estimate==1 & tstat_coefficient_w<-2.80 & ols_method2==1, cluster(idstudy)
		boottest _cons, nograph 
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if inverted_estimate==1 & tstat_coefficient_w<-2.80 & iv_method2==1, cluster(idstudy)
		boottest _cons, nograph 
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if inverted_estimate==1 & tstat_coefficient_w<-2.80 & natural_experiment==1, cluster(idstudy)
		boottest _cons, nograph 
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if inverted_estimate==1 & tstat_coefficient_w<-2.80 & developed_country==1, cluster(idstudy)
		boottest _cons, nograph 
esttab using tab00_pval005_1.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if inverted_estimate==1 & tstat_coefficient_w<-2.80 & developing_country==1, cluster(idstudy)
		boottest _cons, nograph
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if inverted_estimate==1 & tstat_coefficient_w<-2.80 & country_estimate==1, cluster(idstudy)
		boottest _cons, nograph 		
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if inverted_estimate==1 & tstat_coefficient_w<-2.80 & region_estimate==1, cluster(idstudy)
		boottest _cons, nograph 
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if inverted_estimate==1 & tstat_coefficient_w<-2.80 & onelevel_ces_function==1, cluster(idstudy)
		boottest _cons, nograph 
eststo: ivreg2 tstat_coefficient_w precision_coefficient_w if inverted_estimate==1 & tstat_coefficient_w<-2.80 & multilevel_ces_function==1, cluster(idstudy)
		boottest _cons, nograph 
esttab using tab00_pval005_2.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

***************************************************************************************
* HETEROGENEITY - Bayesian model averaging ////CODE for R////
***************************************************************************************

/*
library(BMS)
    *ctrl+C from labor.xlsx, sheet("data.r")
datalabor = read.table("clipboard-512", sep="\t", header=TRUE)
labor = bms(datalabor, burn=1e5,iter=3e5, g="UIP", mprior="uniform", nmodel=50000, mcmc="bd", user.int=FALSE)
labor1 = bms(datalabor, burn=1e5,iter=3e5, g="UIP", mprior="dilut", nmodel=50000, mcmc="bd", user.int=FALSE)
labor2 = bms(datalabor, burn=1e5,iter=3e5, g="BRIC", mprior="random", nmodel=50000, mcmc="bd", user.int=FALSE)
labor3 = bms(datalabor, burn=1e5,iter=3e5, g="hyper=BRIC", mprior="random", nmodel=50000, mcmc="bd", user.int=FALSE)
coef(labor, order.by.pip = F, exact=T, include.constant=T)
image(labor, yprop2pip=FALSE, order.by.pip=TRUE, do.par=TRUE, do.grid=TRUE, do.axis=TRUE, cex.axis = 0.7)
summary(labor)
plot(labor)
print(labor$topmod[1])

library(corrplot)
datalabor = read.table("clipboard-512", sep="\t", header=TRUE)
col<- colorRampPalette(c("red", "white", "blue"))
M <- cor(datalabor)
corrplot.mixed(M, lower = "number", upper = "circle", lower.col=col(200), upper.col=col(200), tl.pos = c("lt"), diag = c("u"), tl.col="black", tl.srt=45, tl.cex=0.85, number.cex = 0.5, cl.cex=0.8, cl.ratio=0.1)
*/

***************************************************************************************
* HETEROGENEITY - Frequentist model averaging (Mallows) ////CODE for R////
***************************************************************************************

/*
library(foreign)
library(xtable)
library(LowRankQP)
datalabor=read.table("clipboard-512", sep="\t", header=TRUE)
datalabor <-na.omit(datalabor)
x.data <- datalabor[,-1]
const_<-c(1)
x.data <-cbind(const_,x.data)

x <- sapply(1:ncol(x.data),function(i){x.data[,i]/max(x.data[,i])})   
scale.vector <- as.matrix(sapply(1:ncol(x.data),function(i){max(x.data[,i])}))        
Y <- as.matrix(datalabor[,1])
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
names <- c(colnames(datalabor))
names <- c(names,"const_")
MMA.fls <- MMA.fls[match(names, MMA.fls$names),]
MMA.fls$names <- NULL
MMA.fls
*/

clear
