***************************************************************************************
***************************************************************************************
********** Immigrant and Native Labor ***********
***************************************************************************************
***************************************************************************************
cd "/Users/klarakantova/Documents/1_Škola/PhD/3_The Elasticity of Substitution between Native and Immigrant Labor_A Meta-Analysis/1_Pub Bias, BPE"
log using immi.log, replace
import excel "/Users/klarakantova/Documents/1_Škola/PhD/3_The Elasticity of Substitution between Native and Immigrant Labor_A Meta-Analysis/1_Pub Bias, BPE/Data.xlsx", sheet("Sheet1") firstrow
set more off
xtset idstudy

***************************************************************************************
* Data Stats & graphs
***************************************************************************************

graph hbox elasticity, over(author,label(grid) sort(pub_year)) xsize(2.6) ysize(4) scale(0.55) yline(-0.0749777, lcolor (red))  box(1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow)  mcolor(gs12)) ytitle("Estimate of the negative of the inverse elasticity") ylabel(, nogrid) graphregion(color(ltbluishgray)) saving(studies, replace) 

graph hbox elasticity if idcountry != 1, over(country, label(grid)) xsize(6) ysize(5) scale(0.8) yline(-0.0749777, lcolor (red))  box( 1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow)  mcolor(gs12)) ytitle("Estimate of the negative of the inverse elasticity") ylabel(, nogrid) graphregion(color(ltbluishgray)) saving(countries_womix, replace)

*trend
bysort idstudy: egen elasticity_med = median(elasticity)
bysort idstudy: egen midyear_med = median(midyear)

graph twoway (scatter elasticity_med midyear_med, msize(*1) msymbol(Oh) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray))) (lfit elasticity_med midyear_med, lcolor(black) lpattern(dash)),  xtitle("Median year of data used by a study") ytitle("Median estimate of the elasticity of substitution") legend(off) saving(trend, replace)

mean elasticity
mean elasticity if high_cell == 1
mean elasticity if high_cell == 0
mean elasticity if annual_freq == 1
mean elasticity if annual_freq == 0
mean elasticity if all_workers == 1
mean elasticity if all_workers == 0
mean elasticity if high_exp == 1
mean elasticity if low_exp == 1
mean elasticity if high_educ == 1
mean elasticity if low_educ == 1
mean elasticity if EN == 1
mean elasticity if EN == 0
mean elasticity if biling == 1
mean elasticity if biling == 0
mean elasticity if top5_lang == 1
mean elasticity if top6_lang == 1
mean elasticity if male == 1
mean elasticity if female == 1
mean elasticity if both == 1
mean elasticity if farmers == 1
mean elasticity if farmers == 0
mean elasticity if north_america == 1
mean elasticity if north_america == 0
mean elasticity if DV_logmeanwage == 1
mean elasticity if DV_logmeanwage == 0
mean elasticity if national == 1
mean elasticity if national == 0
mean elasticity if ols_method2 == 1
mean elasticity if ols_method2 == 0
mean elasticity if experiment == 1
mean elasticity if experiment == 0
mean elasticity if time_FE == 1
mean elasticity if time_FE == 0
mean elasticity if person_FE == 1
mean elasticity if person_FE == 0
mean elasticity if skill_FE == 1
mean elasticity if skill_FE == 0
mean elasticity if published == 1
mean elasticity if published == 0
mean elasticity if topfive == 1
mean elasticity if topfive == 0
mean elasticity if toptwenty == 1
mean elasticity if toptwenty == 0
mean elasticity if unpublished_old == 1
mean elasticity if unpublished_old == 0

mean elasticity [aweight=weight]
mean elasticity [aweight=weight] if high_cell == 1
mean elasticity [aweight=weight] if high_cell == 0
mean elasticity [aweight=weight] if annual_freq == 1
mean elasticity [aweight=weight] if annual_freq == 0
mean elasticity [aweight=weight] if all_workers == 1
mean elasticity [aweight=weight] if all_workers == 0
mean elasticity [aweight=weight] if high_exp == 1
mean elasticity [aweight=weight] if low_exp == 1
mean elasticity [aweight=weight] if high_educ == 1
mean elasticity [aweight=weight] if low_educ == 1
mean elasticity [aweight=weight] if EN == 1
mean elasticity [aweight=weight] if EN == 0
mean elasticity [aweight=weight] if biling == 1
mean elasticity [aweight=weight] if biling == 0
mean elasticity [aweight=weight] if top5_lang == 1
mean elasticity [aweight=weight] if top6_lang == 1
mean elasticity [aweight=weight] if male == 1
mean elasticity [aweight=weight] if female == 1
mean elasticity [aweight=weight] if both == 1
mean elasticity [aweight=weight] if farmers == 1
mean elasticity [aweight=weight] if farmers == 0
mean elasticity [aweight=weight] if north_america == 1
mean elasticity [aweight=weight] if north_america == 0
mean elasticity [aweight=weight] if DV_logmeanwage == 1
mean elasticity [aweight=weight] if DV_logmeanwage == 0
mean elasticity [aweight=weight] if national == 1
mean elasticity [aweight=weight] if national == 0
mean elasticity [aweight=weight] if ols_method2 == 1
mean elasticity [aweight=weight] if ols_method2 == 0
mean elasticity [aweight=weight] if experiment == 1
mean elasticity [aweight=weight] if experiment == 0
mean elasticity [aweight=weight] if time_FE == 1
mean elasticity [aweight=weight] if time_FE == 0
mean elasticity [aweight=weight] if person_FE == 1
mean elasticity [aweight=weight] if person_FE == 0
mean elasticity [aweight=weight] if skill_FE == 1
mean elasticity [aweight=weight] if skill_FE == 0
mean elasticity [aweight=weight] if published == 1
mean elasticity [aweight=weight] if published == 0
mean elasticity [aweight=weight] if topfive == 1
mean elasticity [aweight=weight] if topfive == 0
mean elasticity [aweight=weight] if toptwenty == 1
mean elasticity [aweight=weight] if toptwenty == 0
mean elasticity [aweight=weight] if unpublished_old == 1
mean elasticity [aweight=weight] if unpublished_old == 0


*1	Australia, Britain, Canada, US - few obs
*2	Canada - OK
*3	Colombia - few obs
*4	France - OK
*5	Germany - OK
*6	Italy - warnings (estimated covariance matrix of moment conditions not of full rank)
*7	Norway - few obs
*8	Switzerland - warnings (estimated covariance matrix of moment conditions not of full rank)
*9	UK - few obs
*10	US - OK

mean elasticity if idcountry == 1
mean elasticity [aweight=weight] if idcountry == 1
mean elasticity if idcountry == 2
mean elasticity [aweight=weight] if idcountry == 2
mean elasticity if idcountry == 3
mean elasticity [aweight=weight] if idcountry == 3
mean elasticity if idcountry == 4
mean elasticity [aweight=weight] if idcountry == 4
mean elasticity if idcountry == 5
mean elasticity [aweight=weight] if idcountry == 5
mean elasticity if idcountry == 6
mean elasticity [aweight=weight] if idcountry == 6
mean elasticity if idcountry == 7
mean elasticity [aweight=weight] if idcountry == 7
mean elasticity if idcountry == 8
mean elasticity [aweight=weight] if idcountry == 8
mean elasticity if idcountry == 9
mean elasticity [aweight=weight] if idcountry == 9
mean elasticity if idcountry == 10
mean elasticity [aweight=weight] if idcountry == 10
mean elasticity if idcountry == 10 & farmers == 0
mean elasticity [aweight=weight] if idcountry == 10 & farmers == 0

****************
**FUNNEL
****************
twoway scatter invse elasticity if elasticity > -0.5, ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of the negative of the inverse elasticity") xline(0 -0.0749777, lpattern(dash) lcolor (black)) xlabel(0 -.075, add) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel, replace)

log close

log using pubbias.log, replace
***************************************************************************************
* PUBLICATION BIAS - FAT-PET (Stanley, 2005) for 0LS, FE, BE, and WLS
***************************************************************************************

eststo: ivreg2 elasticity se , cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph  
eststo: xtreg elasticity se, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: xtreg elasticity se, be
eststo: ivreg2 elasticity se [pweight=invse], cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight], cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

***********
**SUBSETS**
***********
* DATA CHARACTERISTICS

*high cells
eststo: ivreg2 elasticity se if high_cell == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: xtreg elasticity se if high_cell == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if high_cell == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if high_cell == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*low cells
eststo: ivreg2 elasticity se if high_cell == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if high_cell == 0, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if high_cell == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if high_cell == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*annual frequency
eststo: ivreg2 elasticity se if annual_freq == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if annual_freq == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if annual_freq == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if annual_freq == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*lower frequency
eststo: ivreg2 elasticity se if annual_freq == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if annual_freq == 0, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if annual_freq == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if annual_freq == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear


* STRUCTURAL VARIATION

*all workers
eststo: ivreg2 elasticity se if all_workers == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if all_workers == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if all_workers == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if all_workers == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*full time workers
eststo: ivreg2 elasticity se if all_workers == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if all_workers == 0, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if all_workers == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if all_workers == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*high exp
eststo: ivreg2 elasticity se if high_exp == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if high_exp == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if high_exp == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if high_exp == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*low exp
eststo: ivreg2 elasticity se if low_exp == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if low_exp == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if low_exp == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if low_exp == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear


*high educ
eststo: ivreg2 elasticity se if high_educ == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if high_educ == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if high_educ == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if high_educ == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*low educ
eststo: ivreg2 elasticity se if low_educ == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if low_educ == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if low_educ == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if low_educ == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*English
eststo: ivreg2 elasticity se if EN == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if EN == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if EN == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if EN == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*other languages
eststo: ivreg2 elasticity se if EN == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if EN == 0, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if EN == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if EN == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*biling
eststo: ivreg2 elasticity se if biling == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if biling == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if biling == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if biling == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*no biling
eststo: ivreg2 elasticity se if biling == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if biling == 0, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if biling == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if biling == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*top6lang
eststo: ivreg2 elasticity se if top6_lang == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if top6_lang == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if top6_lang == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if top6_lang == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*male
eststo: ivreg2 elasticity se if male == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if male == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if male == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if male == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*female
eststo: ivreg2 elasticity se if female == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if female == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if female == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if female == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*bothgenders
eststo: ivreg2 elasticity se if both == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if both == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if both == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if both == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*farmers
eststo: ivreg2 elasticity se if farmers == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if farmers == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if farmers == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if farmers == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*no farmers
eststo: ivreg2 elasticity se if farmers == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if farmers == 0, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if farmers == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if farmers == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*North America
eststo: ivreg2 elasticity se if north_america == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if north_america == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if north_america == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if north_america == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*other than NA
eststo: ivreg2 elasticity se if north_america == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if north_america == 0, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if north_america == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if north_america == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

* ESTIMATION CHARACTERISTICS

*DV_log mean wage
eststo: ivreg2 elasticity se if DV_logmeanwage == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if DV_logmeanwage == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if DV_logmeanwage == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if DV_logmeanwage == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*DV_meanlog wage
eststo: ivreg2 elasticity se if DV_logmeanwage == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if DV_logmeanwage == 0, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if DV_logmeanwage == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if DV_logmeanwage == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*annual wage
eststo: ivreg2 elasticity se if annual == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if annual == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if annual == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if annual == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*monthly wage
eststo: ivreg2 elasticity se if monthly == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if monthly == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if monthly == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if monthly == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*weekly wage
eststo: ivreg2 elasticity se if weekly == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if weekly == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if weekly == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if weekly == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*daily wage
eststo: ivreg2 elasticity se if daily == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if daily == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if daily == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if daily == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*hourly wage
eststo: ivreg2 elasticity se if hourly == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if hourly == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if hourly == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if hourly == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*national
eststo: ivreg2 elasticity se if national == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if national == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if national == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if national == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*regional
eststo: ivreg2 elasticity se if national == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if national == 0, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if national == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if national == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*OLS
eststo: ivreg2 elasticity se if ols_method2 == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if ols_method2 == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if ols_method2 == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if ols_method2 == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*IV
eststo: ivreg2 elasticity se if ols_method2 == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if ols_method2 == 0, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if ols_method2 == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if ols_method2 == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

* fixed effects

*person_FE
eststo: ivreg2 elasticity se if person_FE == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if person_FE == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if person_FE == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if person_FE == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*skill_FE
eststo: ivreg2 elasticity se if skill_FE == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if skill_FE == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if skill_FE == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if skill_FE == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*time_FE
eststo: ivreg2 elasticity se if time_FE == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if time_FE == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if time_FE == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if time_FE == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

* PUB. CHARACTERISTICS

*published
eststo: ivreg2 elasticity se if published == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if published == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if published == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if published == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*unpublished 
eststo: ivreg2 elasticity se if published == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if published == 0, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if published == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if published == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*unpublished OLD
eststo: ivreg2 elasticity se if unpublished_old == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if unpublished_old == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if unpublished_old == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if unpublished_old == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*top5 journal
eststo: ivreg2 elasticity se if topfive == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if topfive == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if topfive == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if topfive == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*top20 journal
eststo: ivreg2 elasticity se if toptwenty == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if toptwenty == 1, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if toptwenty == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if toptwenty == 1, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

log close

log using countries.log, replace

**COUNTRIES

*Mix (Australia, Britain, Canada, US)
*few obs

*Canada
eststo: ivreg2 elasticity se if idcountry == 2, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if idcountry == 2, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if idcountry == 2, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if idcountry == 2, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*Colombia - few obs, warnings: estimated covariance matrix of moment conditions not of full rank
eststo: ivreg2 elasticity se if idcountry == 3, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if idcountry == 3, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if idcountry == 3, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if idcountry == 3, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*France
eststo: ivreg2 elasticity se if idcountry == 4, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if idcountry == 4, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if idcountry == 4, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if idcountry == 4, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*Germany
eststo: ivreg2 elasticity se if idcountry == 5, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if idcountry == 5, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if idcountry == 5, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if idcountry == 5, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*Italy, warnings: estimated covariance matrix of moment conditions not of full rank
eststo: ivreg2 elasticity se if idcountry == 6, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if idcountry == 6, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if idcountry == 6, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if idcountry == 6, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear


*7	Norway - few obs, warnings: estimated covariance matrix of moment conditions not of full rank
eststo: ivreg2 elasticity se if idcountry == 7, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if idcountry == 7, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if idcountry == 7, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if idcountry == 7, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*8	Switzerland, warnings: estimated covariance matrix of moment conditions not of full rank
eststo: ivreg2 elasticity se if idcountry == 8, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if idcountry == 8, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if idcountry == 8, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if idcountry == 8, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*9	UK - few obs, warnings: estimated covariance matrix of moment conditions not of full rank
eststo: ivreg2 elasticity se if idcountry == 9, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if idcountry == 9, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if idcountry == 9, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if idcountry == 9, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*10	US
eststo: ivreg2 elasticity se if idcountry == 10, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if idcountry == 10, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if idcountry == 10, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if idcountry == 10, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear

*10	US without farmers
eststo: ivreg2 elasticity se if idcountry == 10 & farmers == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph 
eststo: xtreg elasticity se if idcountry == 10 & farmers == 0, fe vce(cluster idstudy)
		boottest se, nograph gridmin(-100) gridmax(+100)
eststo: ivreg2 elasticity se [pweight=invse] if idcountry == 10 & farmers == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo: ivreg2 elasticity se [pweight=weight] if idcountry == 10 & farmers == 0, cluster (idstudy)
		boottest se, nograph
		boottest _cons, nograph
eststo clear
log close

***************************************************************************************
* PUBLICATION BIAS - WAAP (Ioannidis et al., 2017) 
***************************************************************************************

summarize elasticity [aweight=1/(se*se)] 
gen waapbound_e = abs(r(mean))/2.8
reg tstat invse if se < waapbound_e , noconstant


***************************************************************************************
* PUBLICATION BIAS - Stem-based method in R (Furukawa, 2019)
***************************************************************************************

/*
source("stem_method.R") #github.com/Chishio318/stem-based_method
data <- read_excel('/Users/klarakantova/Documents/1_Škola/PhD/3_The Elasticity of Substitution between Native and Immigrant Labor_A Meta-Analysis/1_Pub Bias, BPE/Data.xlsx')
stem_results = stem(data$elasticity, data$se, param)
stem_results[["estimates"]]
*/

***************************************************************************************
* PUBLICATION BIAS - Endogenous kink (Bom & Rachinger, 2020)
*      code downloaded from https://sites.google.com/site/heikorachinger/codes 
***************************************************************************************

clear
cd "/Users/klarakantova/Documents/1_Škola/PhD/3_The Elasticity of Substitution between Native and Immigrant Labor_A Meta-Analysis/1_Pub Bias, BPE/EK"
import excel Data_EK.xlsx, firstrow
quietly{
*rename elasticity bs
*rename se sebs
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
* FATE-PET, weights - MAIVE (Irsova et al., 2024)
***************************************************************************************

/*
#WEIGHTS - does matter

#weight = 1
result1 <- maive(dat, method = 1, weight = 1, instrument = 0, studylevel = 0, AR = 0)
result2 <- maive(dat, method = 2, weight = 1, instrument = 0, studylevel = 0, AR = 0)
result3 <- maive(dat, method = 3, weight = 1, instrument = 0, studylevel = 0, AR = 0)
result4 <- maive(dat, method = 4, weight = 1, instrument = 0, studylevel = 0, AR = 0)

maive_results_w1 <- rbind(
  cbind(Model = "Method 1", extract_maive_results(result1)),
  cbind(Model = "Method 2", extract_maive_results(result2)),
  cbind(Model = "Method 3", extract_maive_results(result3)),
  cbind(Model = "Method 4", extract_maive_results(result4))
)
print(maive_results_w1)

#weight = 0
result12 <- maive(dat, method = 1, weight = 0, instrument = 0, studylevel = 0, AR = 0)
result22 <- maive(dat, method = 2, weight = 0, instrument = 0, studylevel = 0, AR = 0)
result32 <- maive(dat, method = 3, weight = 0, instrument = 0, studylevel = 0, AR = 0)
result42 <- maive(dat, method = 4, weight = 0, instrument = 0, studylevel = 0, AR = 0)

maive_results_w0 <- rbind(
  cbind(Model = "Method 1", extract_maive_results(result12)),
  cbind(Model = "Method 2", extract_maive_results(result22)),
  cbind(Model = "Method 3", extract_maive_results(result32)),
  cbind(Model = "Method 4", extract_maive_results(result42))
)
print(maive_results_w0)

#weight = 2
result13 <- maive(dat, method = 1, weight = 2, instrument = 0, studylevel = 0, AR = 0)
result23 <- maive(dat, method = 2, weight = 2, instrument = 0, studylevel = 0, AR = 0)
result33 <- maive(dat, method = 3, weight = 2, instrument = 0, studylevel = 0, AR = 0)
result43 <- maive(dat, method = 4, weight = 2, instrument = 0, studylevel = 0, AR = 0)

maive_results_w2 <- rbind(
  cbind(Model = "Method 1", extract_maive_results(result13)),
  cbind(Model = "Method 2", extract_maive_results(result23)),
  cbind(Model = "Method 3", extract_maive_results(result33)),
  cbind(Model = "Method 4", extract_maive_results(result43))
)
print(maive_results_w2)
*/


***************************************************************************************
************************************HETEROGENEITY**************************************
***************************************************************************************

**BMA

/*
library(readxl)

het <- read_excel("/Users/klarakantova/Documents/1_Škola/PhD/3_The Elasticity of Substitution between Native and Immigrant Labor_A Meta-Analysis/2_Heterogenity/Data_Het.xlsx")
setwd("/Users/klarakantova/Documents/1_Škola/PhD/3_The Elasticity of Substitution between Native and Immigrant Labor_A Meta-Analysis/2_Heterogenity")

correlation_matrix <- cor(het, use = "complete.obs")
print(correlation_matrix)
heatmap(correlation_matrix, main = "Correlation Heatmap")
corrplot(correlation_matrix, method = "color", type = "upper", 
         tl.col = "black", tl.cex = 0.8)
#write_xlsx(as.data.frame(correlation_matrix), "correlation_matrix.xlsx")


burn_       = 1e6
iter_       = 3e6
gprior      = "UIP"
modelprior  = "uniform"
order_PIP   = F
separator   = ","

het <- het[complete.cases(het), ]

het2 <- het %>% select(-high_cell, -top5_lang, -cells, - north_america, -unpublished_old, -both, -topten)

correlation_matrix2 <- cor(het2, use = "complete.obs")
write_xlsx(as.data.frame(correlation_matrix2), "correlation_matrix2.xlsx")

het3 <- het %>% select(-high_cell, -top5_lang, -cells, - north_america, -unpublished_old, -both, -topten, -farmers, -biling)

correlation_matrix3 <- cor(het3, use = "complete.obs")
write_xlsx(as.data.frame(correlation_matrix3), "correlation_matrix3.xlsx")

het4 <- het %>% select(-high_cell, -top5_lang, -cells, - north_america, -unpublished_old, -both, -topten, -farmers, -biling, -EN)

correlation_matrix4 <- cor(het4, use = "complete.obs")
write_xlsx(as.data.frame(correlation_matrix4), "correlation_matrix4.xlsx")

colnames(het4)  <- c("Elasticity", "SE", "log_No.of_cells","Annual_freq.data", "All_workers","High_lvl_exp.","Low_lvl_exp.","High_lvl_educ","Low_lvl_educ", "Top6_languages", "Male","Female","Immi_portion","DV_log_mean_wage","DV_annual", "DV_monthly","DV_weekly","DV_daily","DV_hourly","National_approach","OLS_estimate","Time_FE","Personal_FE","Skill_FE","Impact factor","log_Citations/year","Published_study","Top5_journal", "log_Publication_year")

BMA4  = bms(as.data.frame(lapply(het4,as.numeric)), burn=burn_,iter=iter_, g=gprior, mprior=modelprior, nmodel=10000, mcmc="bd", user.int=FALSE)
BMA_res4 <-coef(BMA4,std.coefs=F, order.by.pip = order_PIP, exact=T,include.constant = T)
write.table(BMA_res4,"BMA4.csv",sep=separator)
image(BMA4, cex=0.7, xlab="", main="")
summary(BMA4)
plot(BMA4)

topmodels.bma(BMA4)
coef(BMA4)

BMA4_random  = bms(as.data.frame(lapply(het4,as.numeric)), burn=burn_,iter=iter_, g=gprior, mprior="random", nmodel=10000, mcmc="bd", user.int=FALSE)
BMA4_random_res <-coef(BMA4_random,std.coefs=F, order.by.pip = order_PIP, exact=T,include.constant = T)
write.table(BMA4_random_res,"BMA4_random.csv",sep=separator)
image(BMA4_random, cex=0.7, xlab="", main="")
summary(BMA4_random)
plot(BMA4_random)

####baseline: gprior = UIP and modelprior = uniform
####robustness checks - different priors:

#1 gprior = BRIC and modelprior = uniform
BMA_BRIC_uniform  = bms(as.data.frame(lapply(het4,as.numeric)), burn=burn_,iter=iter_, g="BRIC", mprior=modelprior, nmodel=10000, mcmc="bd", user.int=FALSE)
BMA_BRIC_uniform_res <-coef(BMA_BRIC_uniform,std.coefs=F, order.by.pip = order_PIP, exact=T,include.constant = T)
write.table(BMA_BRIC_uniform_res,"BMA_BRIC_uniform.csv",sep=separator)
image(BMA_BRIC_uniform, cex=0.7, xlab="", main="") #600x700
summary(BMA_BRIC_uniform)
plot(BMA_BRIC_uniform) #600x600

#1 gprior = BRIC and modelprior = random  
BMA_BRIC_random  = bms(as.data.frame(lapply(het4,as.numeric)), burn=burn_,iter=iter_, g="BRIC", mprior="random", nmodel=10000, mcmc="bd", user.int=FALSE)
BMA_BRIC_random_res <-coef(BMA_BRIC_random,std.coefs=F, order.by.pip = order_PIP, exact=T,include.constant = T)
write.table(BMA_BRIC_random_res,"BMA_BRIC_random.csv",sep=separator)
image(BMA_BRIC_random, cex=0.7, xlab="", main="")
summary(BMA_BRIC_random)
plot(BMA_BRIC_random)

#2 gprior = EBL and modelprior = uniform
BMA_EBL_uniform  = bms(as.data.frame(lapply(het4,as.numeric)), burn=burn_,iter=iter_, g="EBL", mprior=modelprior, nmodel=10000, mcmc="bd", user.int=FALSE)
BMA_EBL_uniform_res <-coef(BMA_EBL_uniform,std.coefs=F, order.by.pip = order_PIP, exact=T,include.constant = T)
write.table(BMA_EBL_uniform_res,"BMA_EBL_uniform.csv",sep=separator)
image(BMA_EBL_uniform, cex=0.7, xlab="", main="")
summary(BMA_EBL_uniform)
plot(BMA_EBL_uniform)

#2 gprior = EBL and modelprior = random
BMA_EBL_random  = bms(as.data.frame(lapply(het4,as.numeric)), burn=burn_,iter=iter_, g="EBL", mprior="random", nmodel=10000, mcmc="bd", user.int=FALSE)
BMA_EBL_random_res <-coef(BMA_EBL_random,std.coefs=F, order.by.pip = order_PIP, exact=T,include.constant = T)
write.table(BMA_EBL_random_res,"BMA_EBL_random.csv",sep=separator)
image(BMA_EBL_random, cex=0.7, xlab="", main="")
summary(BMA_EBL_random)
plot(BMA_EBL_random)

#3 g = "hyper=3", mprior = "uniform"
BMA_hyper_uniform  = bms(as.data.frame(lapply(het4,as.numeric)), burn=burn_,iter=iter_, g="hyper=3", mprior=modelprior, nmodel=10000, mcmc="bd", user.int=FALSE)
BMA_hyper_uniform_res <-coef(BMA_hyper_uniform,std.coefs=F, order.by.pip = order_PIP, exact=T,include.constant = T)
write.table(BMA_hyper_uniform_res,"BMA_hyper_uniform.csv",sep=separator)
image(BMA_hyper_uniform, cex=0.7, xlab="", main="")
summary(BMA_hyper_uniform)
plot(BMA_hyper_uniform)

#3 g = "hyper=3", mprior = "random" 
BMA_hyper_random  = bms(as.data.frame(lapply(het4,as.numeric)), burn=burn_,iter=iter_, g="hyper=3", mprior="random", nmodel=10000, mcmc="bd", user.int=FALSE)
BMA_hyper_random_res <-coef(BMA_hyper_random,std.coefs=F, order.by.pip = order_PIP, exact=T,include.constant = T)
write.table(BMA_hyper_random_res,"BMA_hyper_random.csv",sep=separator)
image(BMA_hyper_random, cex=0.7, xlab="", main="")
summary(BMA_hyper_random)
plot(BMA_hyper_random)

*/

*FMA, using het4

/*
mydata <-na.omit(het4)
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

xtable(MMA.fls,digits=c(0,3,3,3))

separator   = ";"
write.table(MMA.fls,"FMA_results.csv",sep=separator)

*/
