***************************************************************************************
***************************************************************************************
**************** Publication Bias and Model Uncertainty in Measuring the Effect of Class Size on Achievement ******************
***************************************************************************************
*************************************************************************************** 
* January 3, 2025 




***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
************************    (A)    WHOLE SAMPLE          ******************************
***************************************************************************************
***************************************************************************************
***************************************************************************************

clear
log using class.log, replace
import excel "class.xlsx", sheet("data") firstrow
ssc install winsor
set more off

***************************************************************************************
* Summary statistics and patterns in data 
***************************************************************************************

drop if effect_true==0

gen precision = 1/se_effect
winsor effect, generate(effect_w) p(0.01)
winsor se_effect, generate(se_effect_w) p(0.01)
winsor sample_size, generate(sample_size_w) p(0.01)
gen tstat_w = effect_w/se_effect_w
gen precision_w = 1/se_effect_w
gen inv_sample_size = 1/sqrt(sample_size)
gen inv_sample_size_w = 1/sqrt(sample_size_w)
gen inv_sample_size_w2 = 1/sample_size_w
gen sqrt_sample_size = sqrt(sample_size)
gen sqrt_sample_size_w = sqrt(sample_size_w)
gen variance = se_effect*se_effect
gen variance_w = se_effect_w*se_effect_w
gen se_top5_journal = se_effect_w * top5_journal
gen preferred_estimate = 0
replace preferred_estimate = 1 if estimate_category=="preferred"
gen discounted_estimate = 0
replace discounted_estimate = 1 if estimate_category=="discounted"
gen neutral_estimate = 0
replace neutral_estimate = 1 if estimate_category=="neutral"

xtile quantil = average_class_size, nq(5)
tabstat effect_w, stat(count mean sd p50 min max) by(quantil) 
tabstat average_class_size, stat(count mean sd p50 min max) by(quantil) 
tabstat effect_w [aweight=precision*precision], stat(count mean sd p50 min max) by(quantil)
tabstat average_class_size [aweight=precision*precision], stat(count mean sd p50 min max) by(quantil)

sum effect effect_w se_effect se_effect_w
sum effect effect_w se_effect se_effect_w [aweight=weight]
sum effect_w se_effect_w se_top5_journal test_in_math test_in_reading test_in_writing test_in_languages test_in_other_subjects class_kindergarten class_primary_school class_secondary_school class_size female_students male_students minority_students disadvantaged_students general_population_students crosssectional_data longitudinal_data data_year country_usa country_scandinavia country_other method_experiment method_rdd method_instrument method_fe method_ols number_of_variables control_students_gender control_students_age control_students_ethnicity control_household_income control_parental_education control_family_status control_peers_ability control_teachers_experience control_teachers_gender control_teachers_education control_school_size control_rural_population preferred_estimate discounted_estimate neutral_estimate top5_journal citations publication_year impact_factor 
sum effect_w se_effect_w se_top5_journal test_in_math test_in_reading test_in_writing test_in_languages test_in_other_subjects class_kindergarten class_primary_school class_secondary_school class_size female_students male_students minority_students disadvantaged_students general_population_students crosssectional_data longitudinal_data data_year country_usa country_scandinavia country_other method_experiment method_rdd method_instrument method_fe method_ols number_of_variables control_students_gender control_students_age control_students_ethnicity control_household_income control_parental_education control_family_status control_peers_ability control_teachers_experience control_teachers_gender control_teachers_education control_school_size control_rural_population preferred_estimate discounted_estimate neutral_estimate top5_journal citations publication_year impact_factor  [aweight=weight]

*full sample
mean effect_w 
mean effect_w if test_in_math==1
mean effect_w if test_in_reading==1
mean effect_w if test_in_writing==1
mean effect_w if test_in_languages==1
mean effect_w if test_in_other_subjects==1
mean effect_w if class_kindergarten==1
mean effect_w if class_primary_school==1
mean effect_w if class_secondary_school==1
mean effect_w if female_students==1
mean effect_w if male_students==1
mean effect_w if minority_students==1
mean effect_w if disadvantaged_students==1
mean effect_w if general_population_students==1
mean effect_w if longitudinal_data==1
mean effect_w if crosssectional_data==1
mean effect_w if country_usa==1
mean effect_w if country_scandinavia==1
mean effect_w if country_other==1
mean effect_w if method_experiment==1
mean effect_w if method_rdd==1
mean effect_w if method_instrument==1
mean effect_w if method_fe==1
mean effect_w if method_experiment==1 | method_instrument==1 | method_rdd==1 | method_fe==1
mean effect_w if method_ols==1
mean effect_w if top5_journal==1
mean effect_w if top5_journal==0
mean effect_w if estimate_category=="preferred"
mean effect_w if estimate_category=="neutral"
mean effect_w if estimate_category=="discounted"

*full sample weighted
mean effect_w [aweight=weight] 
mean effect_w [aweight=weight] if test_in_math==1
mean effect_w [aweight=weight] if test_in_reading==1
mean effect_w [aweight=weight] if test_in_writing==1
mean effect_w [aweight=weight] if test_in_languages==1
mean effect_w [aweight=weight] if test_in_other_subjects==1
mean effect_w [aweight=weight] if class_kindergarten==1
mean effect_w [aweight=weight] if class_primary_school==1
mean effect_w [aweight=weight] if class_secondary_school==1
mean effect_w [aweight=weight] if female_students==1
mean effect_w [aweight=weight] if male_students==1
mean effect_w [aweight=weight] if minority_students==1
mean effect_w [aweight=weight] if disadvantaged_students==1
mean effect_w [aweight=weight] if general_population_students==1
mean effect_w [aweight=weight] if longitudinal_data==1
mean effect_w [aweight=weight] if crosssectional_data==1
mean effect_w [aweight=weight] if country_usa==1
mean effect_w [aweight=weight] if country_scandinavia==1
mean effect_w [aweight=weight] if country_other==1
mean effect_w [aweight=weight] if method_experiment==1
mean effect_w [aweight=weight] if method_rdd==1
mean effect_w [aweight=weight] if method_instrument==1
mean effect_w [aweight=weight] if method_fe==1
mean effect_w [aweight=weight] if method_experiment==1 | method_instrument==1 | method_rdd==1 | method_fe==1
mean effect_w [aweight=weight] if method_ols==1
mean effect_w [aweight=weight] if top5_journal==1
mean effect_w [aweight=weight] if top5_journal==0
mean effect_w [aweight=weight] if estimate_category=="preferred"
mean effect_w [aweight=weight] if estimate_category=="neutral"
mean effect_w [aweight=weight] if estimate_category=="discounted"

*preferred sample
mean effect_w if estimate_category=="preferred"
mean effect_w if test_in_math==1 & estimate_category=="preferred"
mean effect_w if test_in_reading==1 & estimate_category=="preferred"
mean effect_w if test_in_writing==1 & estimate_category=="preferred"
mean effect_w if test_in_languages==1 & estimate_category=="preferred"
mean effect_w if test_in_other_subjects==1 & estimate_category=="preferred"
mean effect_w if class_kindergarten==1 & estimate_category=="preferred"
mean effect_w if class_primary_school==1 & estimate_category=="preferred"
mean effect_w if class_secondary_school==1 & estimate_category=="preferred"
mean effect_w if female_students==1 & estimate_category=="preferred"
mean effect_w if male_students==1 & estimate_category=="preferred"
mean effect_w if disadvantaged_students==1 & estimate_category=="preferred"
mean effect_w if general_population_students==1 & estimate_category=="preferred"
mean effect_w if longitudinal_data==1 & estimate_category=="preferred"
mean effect_w if crosssectional_data==1 & estimate_category=="preferred"
mean effect_w if country_usa==1 & estimate_category=="preferred"
mean effect_w if country_scandinavia==1 & estimate_category=="preferred"
mean effect_w if country_other==1 & estimate_category=="preferred"
mean effect_w if method_experiment==1 & estimate_category=="preferred"
mean effect_w if method_rdd==1 & estimate_category=="preferred"
mean effect_w if method_instrument==1 & estimate_category=="preferred"
mean effect_w if method_fe==1 & estimate_category=="preferred"
mean effect_w if (method_experiment==1 | method_instrument==1 | method_rdd==1 | method_fe==1) & estimate_category=="preferred"
mean effect_w if method_ols==1 & estimate_category=="preferred"
mean effect_w if top5_journal==1 & estimate_category=="preferred"
mean effect_w if top5_journal==0 & estimate_category=="preferred"

*preferred sample weighted
mean effect_w [aweight=weight] if estimate_category=="preferred"
mean effect_w [aweight=weight] if test_in_math==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if test_in_reading==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if test_in_writing==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if test_in_languages==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if test_in_other_subjects==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if class_kindergarten==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if class_primary_school==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if class_secondary_school==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if female_students==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if male_students==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if disadvantaged_students==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if general_population_students==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if longitudinal_data==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if crosssectional_data==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if country_usa==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if country_scandinavia==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if country_other==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if method_experiment==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if method_rdd==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if method_instrument==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if method_fe==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if (method_experiment==1 | method_instrument==1 | method_rdd==1 | method_fe==1) & estimate_category=="preferred"
mean effect_w [aweight=weight] if method_ols==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if top5_journal==1 & estimate_category=="preferred"
mean effect_w [aweight=weight] if top5_journal==0 & estimate_category=="preferred"

*histograms of the effects and class size
sum effect_w, detail
histogram effect if effect > -10 & effect< 10, bin(40) fcolor(gs14) lstyle(thin) frequency xtitle("Effect of class size on student achievement", size(medsmall)) xline(0, lcolor(black)) xline(-.2546564, lcolor(red))  ylabel( ,glcolor(gray%10)) bgcolor(white) graphregion(color(white)) saving(histogram_effect, replace)
histogram average_class_size, bin(50) fcolor(gs14) lstyle(thin) frequency xtitle("Average number of students in one class", size(medsmall)) xline(0, lcolor(black)) xline(25.8, lcolor(red)) xlabel(10 20 30 40 50, ) xlabel(26, add custom labcolor(red)) xvarformat(%4.0f) ylabel( ,glcolor(gray%10)) bgcolor(white) graphregion(color(white)) saving(histogram_class, replace)
histogram t_stat if 10>t_stat & t_stat>-10, bin(60) fcolor(gs14) lstyle(thin) frequency  xtitle("t-statistics of the effect estimates") xlabel(-10 -5 -1.96 0 1.96 5 10) xline(-1.96 1.96 , lcolor(red))  xline(0, lcolor(black)) ylabel( ,glcolor(white)) graphregion(color(white)) saving(caliper, replace)

*scatter plot of the effect on class size
bysort idstudy: egen SD_w_med = median(effect_w)
bysort idstudy: egen SD_data_year_med = median(mid_year)
bysort idstudy: egen SD_class = median(average_class_size)
generate SG_w_med2=SD_w_med
graph twoway (scatter SG_w_med2 SD_class if SG_w_med2 > -10 & SG_w_med2 < 10, msize(*1) msymbol(Oh) ylabel( ,glcolor(ltbluishgray)) graphregion(color(white))) (lfit SG_w_med2 SD_class, lcolor(black)),  xtitle("Average class size") ytitle("Median effect of class size on student achievement", size(medsmall)) legend(off) saving(class_size, replace)

*pattern 1: data preferrence, pattern 2: subject-based testing, pattern 3: student sample, pattern 4: methods
twoway(hist effect if estimate_category=="neutral" & effect > -10 & effect< 10, bin(40) freq fcolor(gs12) lcolor(gs12) fcolor(white) lcolor(black%80)  legend(label(1 "Neutral estimates")) bgcolor(white) graphregion(color(white))) (hist effect if estimate_category=="discounted" & effect > -10 & effect< 10, bin(50) freq fcolor(gs5) lcolor(gs2) legend(label(2 "Discounted estimates"))xline(0, lcolor(ltblue))) (hist effect_w if estimate_category=="preferred" & effect > -10 & effect< 10, bin(50) freq fcolor(gs12) lcolor(gs8) color(navy%30) legend(label(3 "Preferred estimates")) bgcolor(white) graphregion(color(white))), legend(ring(0) region(fcolor(none)) position(10) bmargin(medium) rows(3) region(lstyle(none)) style(none) size(*0.9) symxsize(*0.5))  xtitle("Effect of class size on student achievement")  scale(1.2) saving(pattern1, replace)
twoway(kdensity effect if test_in_math==1 & effect>-10 & effect<10, lcolor(ltblue) lpattern(solid) legend(label(1 "Math")) xline(0, lcolor(ltblue))) (kdensity effect if test_in_reading==1 & effect>-10 & effect<10, lcolor(black) lpattern(dash) legend(label(2 "Reading")))(kdensity effect if test_in_writing==1 & effect>-10 & effect<10, lcolor(black) lpattern(solid) legend(label(3 "Writing")))(kdensity effect if test_in_languages==1 & effect>-10 & effect<10, lcolor(black) lpattern(tight_dot) legend(label(4 "Languages")))(kdensity effect if test_in_other_subjects==1 & effect>-3 & effect<3, lcolor(gray) lpattern(solid) legend(label(5 "Other subjects"))), bgcolor(white) graphregion(color(white)) legend(ring(0) position(10) style(none) bmargin(medium) rows(5) size(*0.9) symxsize(*0.55) region(lstyle(none))) xtitle("Effect of class size on student achievement") ytitle("Kernel density (effect)") scale(1.2) saving(pattern2, replace)
twoway(kdensity effect if general_population_students==1 & effect>-5 & effect<5, lcolor(ltblue) lpattern(solid) legend(label(1 "General population")) xline(0, lcolor(ltblue))) (kdensity effect if disadvantaged_students==1 & effect>-5 & effect<5, lcolor(black) lpattern(tight_dot) legend(label(2 "Disadvantaged")))(kdensity effect if female_students==1 & effect>-5 & effect<5, lcolor (black) lpattern(solid) legend(label(3 "Female"))) (kdensity effect if male_students==1 & effect>-5 & effect<5, lcolor (gs10) lpattern(solid) legend(label(4 "Male"))), bgcolor(white) graphregion(color(white)) legend(ring(0) position(10) style(none) bmargin(medium) rows(4) size(*0.9) symxsize(*0.55) region(lstyle(none))) xtitle("Effect of class size on student achievement") ytitle("Kernel density (effect)") scale(1.2) saving(pattern3, replace)
twoway(kdensity effect if method_experiment==1 & effect>-10 & effect<10, lcolor(ltblue) lpattern(solid) legend(label(1 "STAR experiment"))xline(0, lcolor(ltblue)))(kdensity effect if method_rdd==1 & effect>-10 & effect<10, lcolor(black) lpattern(tight_dot) legend(label(2 "Regression discontinuity")))(kdensity effect if method_instrument==1 & effect >-10 & effect<10, lcolor(black) lpattern(dash) legend(label(3 "Instrumental variable")))(kdensity effect if method_fe==1 & effect>-10 & effect<10, lcolor(gray) lpattern(solid) legend(label(4 "Fixed effects")))(kdensity effect if method_ols==1 & effect>-10 & effect<10, lcolor (black) lpattern(solid) legend(label(5 "OLS"))), bgcolor(white) graphregion(color(white)) legend(ring(0) position(10) style(none) bmargin(medium) rows(5) size(*0.9) symxsize(*0.55) region(lstyle(none))) xtitle("Effect of class size on student achievement") ytitle("Kernel density (effect)") scale(1.2) saving(pattern4, replace)

*graphs: effect size by studies and counties, class size by countries
graph hbox effect if effect > -10 & effect< 10, over(study, sort(data_year)) xsize(6) ysize(9) scale(0.65) yline(0, lcolor (ltblue)) box(1,lcolor(black) fcolor(gs6*.5)) marker(1,msymbol(circle_hollow)  mcolor(gs5)) ytitle("Effect of class size on student achievement", size(medsmall)) ylabel(, grid glcolor(black) glpattern(dot)) bgcolor(white) graphregion(color(white)) scheme(white_tableau) saving(studies, replace) 
graph hbox effect if effect > -10 & effect< 10, over(country, label(grid glcolor(gs12%30))) xsize(5) ysize(7) scale(0.7) yline(0, lcolor (ltblue))  box(1,lcolor(black) fcolor(gs6*.5)) marker(1,msymbol(circle_hollow)  mcolor(gs5)) ytitle("Effect of class size on student achievement", size(medium)) ylabel(,grid glcolor(black) glpattern(dot)) bgcolor(white) scheme(white_tableau) graphregion(color(white)) saving(countries, replace) 
graph hbox average_class_size if effect > -10 & effect < 10, over(country, label(grid glcolor(gs12%30))) xsize(5) ysize(7) scale(0.7) yline(24.2, lcolor (red))  box(1,lcolor(black) fcolor(gs6*.5)) marker(1,msymbol(circle_hollow)  mcolor(gs5)) ytitle("Mean class size", size(medium)) ylabel(,grid glcolor(black) glpattern(dot)) bgcolor(white) graphregion(color(white)) scheme(white_tableau) saving(classes, replace) 

***************************************************************************************
* PUBLICATION BIAS - Funnel plot (Egger et al., 1997) 
***************************************************************************************

sum effect_w, detail
twoway scatter precision effect if effect>-10 & effect<10 & precision<80, yscale(log) ylab(0.1  0.5  10 100,grid) xlab(,g)  ytitle("Precision of the effect (1/SE)") ylabel( ,glcolor(black) glpattern(dot)) xtitle("Effect of class size on student achievement") xline(0, lpattern(solid) lcolor (ltblue)) xline(-0.2546564, lpattern(dott) lcolor (red)) msymbol(smcircle_hollow) bgcolor(white) graphregion(color(white) lwidth(large)) saving(funnel, replace)

***************************************************************************************
* PUBLICATION BIAS - FAT-PET (Stanley, 2005)
***************************************************************************************

xtset idstudy
*whole sample
eststo: ivreg2 effect_w se_effect_w, cluster(idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph 
eststo: xtreg effect_w se_effect_w, fe vce(cluster idstudy)
eststo: ivreg2 effect_w (se_effect_w = sqrt_sample_size_w), cluster (idstudy) first		
			boottest se_effect_w, nograph
			boottest _cons, nograph
			twostepweakiv 2sls effect_w (se_effect_w = sqrt_sample_size_w), cluster(idstudy)
eststo: ivreg2 effect_w se_effect_w [pweight=weight], cluster (idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
eststo: ivreg2 effect_w se_effect_w [pweight=precision_w], cluster (idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
esttab using table_bias.tex, float se booktabs replace compress title(Tests suggest small publication bias overall\label{tab:fatpett}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "IV" "Study" "Precision") label
eststo clear

*experiments
eststo: ivreg2 effect_w se_effect_w if method_experiment==1
			boottest se_effect_w, nograph
			boottest _cons, nograph 
eststo: xtreg effect_w se_effect_w if method_experiment==1, fe
eststo: ivreg2 effect_w (se_effect_w = sqrt_sample_size_w) if method_experiment==1, first
			twostepweakiv 2sls effect_w (se_effect_w = sqrt_sample_size_w) if method_experiment==1
			bootstrap, reps(500): ivreg2 effect_w (se_effect_w = sqrt_sample_size_w) if method_experiment==1, first			
eststo: ivreg2 effect_w se_effect_w [pweight=weight] if method_experiment==1
			boottest se_effect_w, nograph
			boottest _cons, nograph
eststo: ivreg2 effect_w se_effect_w if method_experiment==1 [pweight=precision_w]
			boottest se_effect_w, nograph
			boottest _cons, nograph
esttab using table_bias_exp.tex, float se booktabs replace compress title(Tests suggest small publication bias overall\label{tab:fatpett}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "IV" "Study" "Precision") label
eststo clear


*regression discontinuity
eststo: ivreg2 effect_w se_effect_w if method_rdd==1, cluster(idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph 
eststo: xtreg effect_w se_effect_w if method_rdd==1, fe vce(cluster idstudy)
eststo: ivreg2 effect_w (se_effect_w = sqrt_sample_size_w) if method_rdd==1, cluster (idstudy) first
			boottest se_effect_w, nograph
			boottest _cons, nograph
			twostepweakiv 2sls effect_w (variance_w = inv_sample_size_w2) if method_rdd==1, cluster (idstudy)
eststo: ivreg2 effect_w se_effect_w [pweight=weight] if method_rdd==1, cluster (idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
eststo: ivreg2 effect_w se_effect_w if method_rdd==1 [pweight=precision_w], cluster (idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
esttab using table_bias_rdd.tex, float se booktabs replace compress title(Tests suggest small publication bias overall\label{tab:fatpett}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "IV" "Study" "Precision") label
eststo clear


*instrumental methods
eststo: ivreg2 effect_w se_effect_w if method_instrument==1, cluster(idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph 
eststo: xtreg effect_w se_effect_w if method_instrument==1, fe vce(cluster idstudy)
eststo: ivreg2 effect_w (se_effect_w = sqrt_sample_size_w) if method_instrument==1, cluster (idstudy) first
			twostepweakiv 2sls effect_w (se_effect_w = sqrt_sample_size_w) if method_instrument==1, cluster(idstudy)
			bootstrap, reps(500): ivreg2 effect_w (se_effect_w = sqrt_sample_size_w) if method_instrument==1, first
eststo: ivreg2 effect_w se_effect_w [pweight=weight] if method_instrument==1, cluster (idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
eststo: ivreg2 effect_w se_effect_w if method_instrument==1 [pweight=precision_w], cluster (idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
esttab using table_bias_iv.tex, float se booktabs replace compress title(Tests suggest small publication bias overall\label{tab:fatpett}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "IV" "Study" "Precision") label
eststo clear


*fixed effects
eststo: ivreg2 effect_w se_effect_w if method_fe==1, cluster(idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph 
eststo: xtreg effect_w se_effect_w if method_fe==1, fe vce(cluster idstudy)
eststo: ivreg2 effect_w (se_effect_w = sqrt_sample_size_w) if method_fe==1, cluster (idstudy) first
			twostepweakiv 2sls effect_w (se_effect_w = sqrt_sample_size_w) if method_fe==1, cluster(idstudy)
			bootstrap, reps(500): ivreg2 effect_w (se_effect_w = sqrt_sample_size_w) if method_fe==1, cluster(idstudy) first
eststo: ivreg2 effect_w se_effect_w [pweight=weight] if method_fe==1, cluster (idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
eststo: ivreg2 effect_w se_effect_w if method_fe==1 [pweight=precision_w], cluster (idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
esttab using table_bias_fe.tex, float se booktabs replace compress title(Tests suggest small publication bias overall\label{tab:fatpett}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "IV" "Study" "Precision") label
eststo clear


*ordinary least squares
eststo: ivreg2 effect_w se_effect_w if method_ols==1, cluster(idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph 
eststo: xtreg effect_w se_effect_w if method_ols==1, fe vce(cluster idstudy)
eststo: ivreg2 effect_w (se_effect_w = sqrt_sample_size_w) if method_ols==1, cluster (idstudy) first
			boottest se_effect_w, nograph
			boottest _cons, nograph
			twostepweakiv 2sls effect_w (se_effect_w = sqrt_sample_size_w) if method_ols==1, cluster(idstudy)
eststo: ivreg2 effect_w se_effect_w [pweight=weight] if method_ols==1, cluster (idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
eststo: ivreg2 effect_w se_effect_w if method_ols==1 [pweight=precision_w], cluster (idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
esttab using table_bias_ols.tex, float se booktabs replace compress title(Tests suggest small publication bias overall\label{tab:fatpett}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "IV" "Study" "Precision") label
eststo clear

/*
*generate effect in 1 SD of class size
gen effectsd = effect/sd_class_size
gen se_effectsd = se_effect/sd_class_size
winsor effectsd, generate(effectsd_w) p(0.01)
winsor se_effectsd, generate(se_effectsd_w) p(0.01)
sum effectsd effectsd_w se_effectsd se_effectsd_w
xtset idstudy

*effect measured in common metrics
eststo: ivreg2 effectsd_w se_effectsd_w, cluster(idstudy)
			boottest se_effectsd_w, nograph
			boottest _cons, nograph 
eststo: xtreg effectsd_w se_effectsd_w, fe vce(cluster idstudy)
eststo: ivreg2 effectsd_w (se_effectsd_w = sqrt_sample_size_w), cluster (idstudy) first
			boottest se_effectsd_w, nograph
			boottest _cons, nograph
			twostepweakiv 2sls effectsd_w (se_effectsd_w = sqrt_sample_size_w), cluster(idstudy)
eststo: ivreg2 effectsd_w se_effectsd_w [pweight=weight], cluster (idstudy)
			boottest se_effectsd_w, nograph
			boottest _cons, nograph
*ivreg2 tstat_w precision_w, cluster (idstudy)
eststo: ivreg2 effectsd_w se_effectsd_w [pweight=precision_w], cluster (idstudy)
			boottest se_effectsd_w, nograph
			boottest _cons, nograph
esttab using table_bias_sd.tex, float se booktabs replace compress title(Tests suggest small publication bias overall\label{tab:fatpett}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "IV" "Study" "Precision") label
eststo clear

gen precisionsd_w=1/se_effectsd_w
gen tstatsd_w=effectsd_w/se_effectsd_w
summarize effectsd_w [aweight=precisionsd_w*precisionsd_w]
gen waapboundsd = abs(r(mean))/2.8
reg tstatsd_w precisionsd_w if se_effectsd_w  < waapbound, noconstant

quietly{
*clear 
rename effectsd_w bs
rename se_effectsd_w sebs
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
*/

***************************************************************************************
* PUBLICATION BIAS - WAAP (Ioannidis et al., 2017) 
***************************************************************************************

summarize effect_w [aweight=precision_w*precision_w]
gen waapbound = abs(r(mean))/2.8
reg tstat_w precision_w if se_effect_w  < waapbound, noconstant

summarize effect_w [aweight=precision_w*precision_w] if method_experiment==1
gen waapbound_experiment = abs(r(mean))/2.8
reg tstat_w precision_w if se_effect_w  < waapbound_experiment & method_experiment==1, noconstant

summarize effect_w [aweight=precision_w*precision_w] if method_rdd==1
gen waapbound_rdd = abs(r(mean))/2.8
reg tstat_w precision_w if se_effect  < waapbound_rdd & method_rdd==1, noconstant

summarize effect_w [aweight=precision*precision] if method_instrument==1
gen waapbound_iv = abs(r(mean))/2.8
reg tstat_w precision_w if se_effect  < waapbound_iv & method_instrument==1, noconstant

summarize effect_w [aweight=precision_w*precision_w] if method_fe==1
gen waapbound_did_fe = abs(r(mean))/2.8
reg tstat_w precision_w if se_effect_w  < waapbound_did_fe & method_fe==1, noconstant

summarize effect_w [aweight=precision_w*precision_w] if method_ols==1
gen waapbound_ols = abs(r(mean))/2.8
reg tstat_w precision_w if se_effect_w  < waapbound_ols & method_ols==1, noconstant

***************************************************************************************
* PUBLICATION BIAS - Endogenous kink (Bom & Rachinger, 2020)
*      code downloaded from https://sites.google.com/site/heikorachinger/codes 
***************************************************************************************
*drop if method_experiment==0
*drop if method_rdd==0
*drop if method_instrument==0
*drop if method_fe==0
*drop if method_ols==0

quietly{
*clear 
rename effect_w bs
rename se_effect_w sebs
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

rename  bs effect_w
rename  sebs se_effect_w

***************************************************************************************
* Publication bias - p-uniform* (van Aert & van Assen, 2020) - on median values - code for Stata & R
***************************************************************************************
*drop if method_experiment==0
*drop if method_rdd==0
*drop if method_instrument==0
*drop if method_fe==0
*drop if method_ols==0

bysort idstudy: egen effect_med = median(effect)
bysort idstudy: egen se_med = median(se_effect)
bysort idstudy: egen t_med = median(t_stat)
bysort idstudy: egen data_year_med = median(data_year)
gen variance_med = se_med*se_med

bysort idstudy: egen effect_medw = median(effect_w)
bysort idstudy: egen se_medw = median(se_effect_w)
bysort idstudy: egen t_medw = median(tstat_w)
gen variance_medw = se_medw*se_medw

preserve
collapse (lastnm) effect_med effect_medw se_med se_medw variance_med variance_medw t_med t_medw data_year_med (p50) nobs_med=sample_size_w, by(idstudy)
save "puniform.dta", replace
restore
clear

*save "puniform.dta", replace
*save "puniform_experiment.dta", replace
*save "puniform_rdd.dta", replace
*save "puniform_instrument.dta", replace
*save "puniform_fe.dta", replace
*save "puniform_ols.dta", replace

*keep effect effect_w se_effect se_effect_w variance variance_w
*save "puniform2_top5.dta", replace

/* on median values
library(puniform)
library(metafor)
library(dmetar)
library(haven)
library(tidyverse)
library(meta)

data <- read_dta("puniform.dta")
data <- read_dta("puniform_experiment.dta")
data <- read_dta("puniform_instrument.dta")
data <- read_dta("puniform_rdd.dta")
data <- read_dta("puniform_didfe.dta")
data <- read_dta("puniform_ols.dta")


data = read.table("clipboard-512", sep="\t", header=TRUE)
puni_star(yi = data$effect_w, vi = data$variance_w, side="left", method="ML",alpha = 0.05)
puni_star(yi = data$effect_medw, vi = data$variance_medw, side="left", method="ML",alpha = 0.05)
puni_star(yi = data$effectsd_medw, vi = data$variancesd_medw, side="left", method="ML",alpha = 0.05)
puni_star(yi = data$pcc_medw, vi = data$variance_medw, side="left", method="ML",alpha = 0.05)
puniform(yi = data$effect_medw, vi = data$variance_medw, side="left", method="ML",alpha = 0.05)
*/

/*
bysort idstudy: egen effectsd_med = median(effectsd)
bysort idstudy: egen sesd_med = median(se_effectsd)
gen variancesd_med = sesd_med*sesd_med

bysort idstudy: egen effectsd_medw = median(effectsd_w)
bysort idstudy: egen sesd_medw = median(se_effectsd_w)
gen variancesd_medw = sesd_medw*sesd_medw

preserve
collapse (lastnm) effectsd_med effectsd_medw sesd_med sesd_medw variancesd_med variancesd_medw  (p50) nobs_med=sample_size_w, by(idstudy)
save "puniform_sd.dta", replace
restore
*/


***************************************************************************************
* PUBLICATION BIAS - Stem-based method in R (Furukawa, 2019) - on median values
***************************************************************************************

/*
source("stem_method.R") #github.com/Chishio318/stem-based_method
dataclass = read.table("clipboard-512", sep="\t", header=TRUE)
stem_results = stem(dataclass$effect_medw, dataclass$se_medw, param)
stem_results[["estimates"]]
*/

***************************************************************************************
* Publication bias - p-hacking (Elliott et al., 2022) - data preparation
***************************************************************************************

import excel class.xlsx, sheet("data") firstrow
drop if effect_true==0
set more off
*drop if method_experiment==0
*drop if method_instrument==0
*drop if method_rdd==0
*drop if method_fe==0
*drop if method_ols==0

gen t_abs = abs(t_stat)
gen ptop = 2*(1 - normal(t_abs))
drop if se_effect==.
drop if ptop > 1
gen id = idstudy

export delimited using "class.csv", replace
*export delimited using "class_experiment.csv", replace
*export delimited using "class_instrument.csv", replace
*export delimited using "class_rdd.csv", replace
*export delimited using "class_fe.csv", replace
*export delimited using "class_ols.csv", replace
clear

/*
*https://github.com/skranz/phack?tab=readme-ov-file
options(repos = c(
  skranz = 'https://skranz.r-universe.dev',
  CRAN = 'https://cloud.r-project.org'))
install.packages('phack')
library(phack)

dat = read.table("clipboard-512", sep="\t", header=TRUE)
phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.15, J=5)
phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.15, J=10)
phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.15, J=15)
phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.15, J=20)

phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.15, J=5, K=2, use_bound=TRUE)
phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.15, J=10, K=2, use_bound=TRUE)
phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.15, J=15, K=2, use_bound=TRUE)
phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.15, J=20, K=2, use_bound=TRUE)
*/


***************************************************************************************
* PCC
***************************************************************************************

/*
clear
log using class.log, replace
import excel "class.xlsx", sheet("data") firstrow
ssc install winsor
set more off


xtset idstudy

winsor pcc, generate(pcc_w) p(0.01)
winsor se_pcc, generate(se_pcc_w) p(0.01)
drop if se_pcc==0
*drop if sample_size==.
gen precision_pcc = 1/se_pcc
winsor sample_size, generate(ss_w) p(0.01)
gen inv_sample_size_w = 1/sqrt(ss_w)
gen tstat_w = pcc_w/se_pcc 


* linear methods
eststo: ivreg2 pcc_w se_pcc_w, cluster(idstudy)
			boottest se_pcc_w, nograph
			boottest _cons, nograph 
eststo: xtreg pcc_w se_pcc_w, fe vce(cluster idstudy)
eststo: ivreg2 pcc_w (se_pcc_w = inv_sample_size), cluster (idstudy) first
			twostepweakiv 2sls pcc_w (se_pcc_w = inv_sample_size_w), cluster(idstudy)
			bootstrap, reps(500): ivreg2 pcc_w (se_pcc_w = inv_sample_size_w), first 
eststo: ivreg2 pcc_w se_pcc_w [pweight=weight_pcc], cluster (idstudy)
			boottest se_pcc_w, nograph
			boottest _cons, nograph
eststo: ivreg2 pcc_w se_pcc_w [pweight=1/(se_pcc_w*se_pcc_w)], cluster (idstudy)
			boottest se_pcc_w, nograph
			boottest _cons, nograph
esttab using table_bias_pcc.tex, float se booktabs replace compress title(Tests suggest small publication bias overall\label{tab:fatpett}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "IV" "Study" "Precision") label
eststo clear

* waap
summarize pcc_w [aweight=precision_pcc*precision_pcc]
gen waapboundpcc = abs(r(mean))/2.8
reg tstat_w precision_pcc if se_pcc_w  < waapboundpcc, noconstant

* p-uniform*
bysort idstudy: egen pcc_medw = median(pcc_w)
bysort idstudy: egen se_pcc_medw = median(se_pcc_w)
bysort idstudy: egen t_pcc_medw = median(tstat_w)
gen variance_medw = se_pcc_medw*se_pcc_medw

bysort idstudy: egen pcc_med = median(pcc)
bysort idstudy: egen se_pcc_med = median(se_pcc)
bysort idstudy: egen t_pcc_med = median(t_stat)
gen variance_med = se_pcc_med*se_pcc_med

preserve
collapse (lastnm) pcc_medw pcc_med se_pcc_medw se_pcc_med variance_medw variance_med t_pcc_med t_pcc_medw (p50) nobs_med=ss_w, by(idstudy)
save "puniform_pcc.dta", replace
restore

* kinked meta
drop if se_pcc_w==0
quietly{
*clear 
rename pcc_w bs
rename se_pcc_w sebs
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

rename  bs pcc_w
rename  sebs se_pcc_w

drop inv_sample_size ss_w tstat_w variance_medw
log close
*/

***************************************************************************************
***************************************************************************************
***************************************************************************************
********************     (B)     PREFERRED ESTIMATES          *************************
***************************************************************************************
***************************************************************************************
***************************************************************************************

clear
*log using class.log, replace
import excel "class.xlsx", sheet("data") firstrow
ssc install winsor
set more off

***************************************************************************************
* Summary statistics and patterns in data (whole sample)
***************************************************************************************

drop if effect_true==0
drop if estimate_category=="neutral"
drop if estimate_category=="discounted"

gen precision = 1/se_effect
winsor effect, generate(effect_w) p(0.01)
winsor se_effect, generate(se_effect_w) p(0.01)
winsor sample_size, generate(sample_size_w) p(0.01)
gen tstat_w = effect_w/se_effect_w
gen precision_w = 1/se_effect_w
gen inv_sample_size = 1/sqrt(sample_size)
gen inv_sample_size_w = 1/sqrt(sample_size_w)
gen inv_sample_size_w2 = 1/sample_size_w
gen sqrt_sample_size = sqrt(sample_size)
gen sqrt_sample_size_w = sqrt(sample_size_w)
gen variance = se_effect*se_effect
gen variance_w = se_effect_w*se_effect_w
gen se_top5_journal = se_effect_w * top5_journal
gen se_impact_factor = se_effect_w * impact_factor

xtile quantil = average_class_size, nq(5)
tabstat effect_w, stat(count mean sd p50 min max) by(quantil) 

/*generate effect in 1 SD of class size
gen effectsd = effect/sd_class_size
gen se_effectsd = se_effect/sd_class_size
winsor effectsd, generate(effectsd_w) p(0.01)
winsor se_effectsd, generate(se_effectsd_w) p(0.01)
sum effectsd effectsd_w se_effectsd se_effectsd_w
*/

sum effect effect_w se_effect se_effect_w
sum effect effect_w se_effect se_effect_w [aweight=weight]
sum effect_w se_effect_w se_top5_journal top5_journal test_in_math test_in_reading test_in_writing test_in_languages test_in_other_subjects class_kindergarten class_primary_school class_secondary_school class_size female_students male_students minority_students disadvantaged_students general_population_students crosssectional_data longitudinal_data data_year country_usa country_scandinavia country_other method_experiment method_rdd method_instrument method_fe method_ols number_of_variables control_students_gender control_students_age control_students_ethnicity control_household_income control_parental_education control_family_status control_peers_ability control_teachers_experience control_teachers_gender control_teachers_education control_school_size control_rural_population citations publication_year impact_factor 
sum effect_w se_effect_w se_top5_journal top5_journal test_in_math test_in_reading test_in_writing test_in_languages test_in_other_subjects class_kindergarten class_primary_school class_secondary_school class_size female_students male_students minority_students disadvantaged_students general_population_students crosssectional_data longitudinal_data data_year country_usa country_scandinavia country_other method_experiment method_rdd method_instrument method_fe method_ols number_of_variables control_students_gender control_students_age control_students_ethnicity control_household_income control_parental_education control_family_status control_peers_ability control_teachers_experience control_teachers_gender control_teachers_education control_school_size control_rural_population citations publication_year impact_factor  [aweight=weight]

*histograms of the effects and class size
sum effect_w, detail
histogram effect if effect > -10 & effect< 10, bin(40) fcolor(gs14) lstyle(thin) frequency xtitle("Effect of class size on student achievement", size(medsmall)) xline(0, lcolor(black)) xline(-0.3632608, lcolor(red))  ylabel( ,glcolor(gray%10)) bgcolor(white) graphregion(color(white)) saving(histogram_effect_pref, replace)
histogram average_class_size, bin(50) fcolor(gs14) lstyle(thin) frequency xtitle("Average number of students in one class", size(medsmall)) xline(0, lcolor(black)) xline(23.9, lcolor(red)) xlabel(10 30 50, ) xlabel(23.9, add custom labcolor(red)) xvarformat(%4.0f) ylabel( ,glcolor(gray%10)) bgcolor(white) graphregion(color(white)) saving(histogram_class_pref, replace)
histogram t_stat if 10>t_stat & t_stat>-10, bin(60) fcolor(gs14) lstyle(thin) frequency  xtitle("t-statistics of the effect estimates") xlabel(-10 -5 -1.96 0 1.96 5 10) xline(-1.96 1.96 , lcolor(red))  xline(0, lcolor(black)) ylabel( ,glcolor(white)) graphregion(color(white)) saving(caliper_pref, replace)

*graphs: effect size by studies and counties, class size by countries
graph hbox effect if effect > -10 & effect< 10, over(study, sort(data_year)) xsize(6) ysize(9) scale(0.65) yline(0, lcolor (ltblue)) box(1,lcolor(black) fcolor(gs6*.5)) marker(1,msymbol(circle_hollow)  mcolor(gs5)) ytitle("Effect of class size on student achievement", size(medsmall)) ylabel(, grid glcolor(black) glpattern(dot)) bgcolor(white) graphregion(color(white)) scheme(white_tableau) saving(studies_pref, replace) 
graph hbox effect if effect > -10 & effect< 10, over(country, label(grid glcolor(gs12%30))) xsize(5) ysize(7) scale(0.7) yline(0, lcolor (ltblue))  box(1,lcolor(black) fcolor(gs6*.5)) marker(1,msymbol(circle_hollow)  mcolor(gs5)) ytitle("Effect of class size on student achievement", size(medium)) ylabel(,grid glcolor(black) glpattern(dot)) bgcolor(white) scheme(white_tableau) graphregion(color(white)) saving(countries_pref, replace) 
graph hbox average_class_size if effect > -10 & effect< 10, over(country, label(grid glcolor(gs12%30))) xsize(5) ysize(7) scale(0.7) yline(24.2, lcolor (red))  box(1,lcolor(black) fcolor(gs6*.5)) marker(1,msymbol(circle_hollow)  mcolor(gs5)) ytitle("Mean class size", size(medium)) ylabel(,grid glcolor(black) glpattern(dot)) bgcolor(white) graphregion(color(white)) scheme(white_tableau) saving(classes_pref, replace) 

***************************************************************************************
* PUBLICATION BIAS - Funnel plot (Egger et al., 1997) 
***************************************************************************************

sum effect_w, detail
twoway scatter precision effect if effect>-10 & effect<10 & precision<80, yscale(log) ylab(0.1  0.5  10 100,grid) xlab(,g)  ytitle("Precision of the effect (1/SE)") ylabel( ,glcolor(black) glpattern(dot)) xtitle("Effect of class size on student achievement") xline(0, lpattern(solid) lcolor (ltblue)) xline(-0.6519134, lpattern(dott) lcolor (red)) msymbol(smcircle_hollow) bgcolor(white) graphregion(color(white) lwidth(large)) saving(funnel_pref, replace)

***************************************************************************************
* PUBLICATION BIAS - FAT-PET (Stanley, 2005)
***************************************************************************************

xtset idstudy

*whole sample
eststo: ivreg2 effect_w se_effect_w, cluster(idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph 
eststo: xtreg effect_w se_effect_w, fe vce(cluster idstudy)
eststo: ivreg2 effect_w (se_effect_w = sqrt_sample_size_w), cluster (idstudy) first
			boottest se_effect_w, nograph
			boottest _cons, nograph
			twostepweakiv 2sls effect_w (se_effect_w = sqrt_sample_size_w), cluster(idstudy)
eststo: ivreg2 effect_w se_effect_w [pweight=weight], cluster (idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
eststo: ivreg2 effect_w se_effect_w [pweight=precision_w], cluster (idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
esttab using table_bias_pref.tex, float se booktabs replace compress title(Tests suggest small publication bias overall\label{tab:fatpett}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "IV" "Study" "Precision") label
eststo clear

*impact factor
eststo: ivreg2 effect_w se_effect_w se_impact_factor impact_factor, cluster(idstudy)
eststo: ivreg2 effect_w se_effect_w se_impact_factor impact_factor [pweight=weight], cluster (idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
eststo: ivreg2 effect_w se_effect_w se_impact_factor impact_factor [pweight=precision_w], cluster(idstudy)
			boottest se_effect_w, nograph
			boottest _cons, nograph
esttab using table_bias_pref_se_impact.tex, float se booktabs replace compress title(Tests suggest small publication bias overall\label{tab:fatpett}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "Study" "Precision") label
eststo clear

***************************************************************************************
* PUBLICATION BIAS - WAAP (Ioannidis et al., 2017) 
***************************************************************************************

summarize effect_w [aweight=precision_w*precision_w]
gen waapbound = abs(r(mean))/2.8
reg tstat_w precision_w if se_effect_w  < waapbound, noconstant


***************************************************************************************
* PUBLICATION BIAS - Stem-based method in R (Furukawa, 2019) - on median values
***************************************************************************************

/*
source("stem_method.R") #github.com/Chishio318/stem-based_method
dataclass = read.table("clipboard-512", sep="\t", header=TRUE)
stem_results = stem(dataclass$effect_medw, dataclass$se_medw, param)
stem_results[["estimates"]]
*/

***************************************************************************************
* FOREST PLOT - on median values
***************************************************************************************

/*
# forest plot based on preffered estimates
install.packages(c("robumeta","metafor","dplyr","data.table","forestplot"))
library(forestplot)
library(dplyr)
library(robumeta)
library(metafor)
library(data.table)

data = read.table("clipboard-512", sep="\t", header=TRUE)
res <- rma(yi=effect_medw, vi=variance_medw, data=data) 
confint(res) 
forest(res, slab=paste(data$study), order = data_year_med, xlim=c(-30, 30), digits=c(2,1))
forest(res, slab=paste(data$study), order = data_year_med, ilab=cbind(weights), ilab.xpos=c(20),  xlim=c(-30, 30), digits=c(2,1), cex=0.7)
forest(res, slab=paste(data$study), order = data_year_med, showweights=TRUE,  xlim=c(-30, 30), digits=c(1,1), cex=0.7)
*/

***************************************************************************************
* PUBLICATION BIAS - Hedges model (Andrews & Kasy 2019, Kranz & Putz 2021)
***************************************************************************************

/*
options(repos = c(skranz = 'https://skranz.r-universe.dev',
CRAN = 'https://cloud.r-project.org'))
install.packages('MetaStudies')
library(MetaStudies)

dataclass = read.table("clipboard-512", sep="\t", header=TRUE)

colnames(dataclass) = c("X","sigma")
ms = metastudies_estimation(X=dataclass$X,sigma=dataclass$sigma,model = "t",cutoffs = c(1.96),symmetric = TRUE)
ms$est_tab
metastudy_X_sigma_cors(ms)
resl=bootstrap_specification_tests(dataclass$X, dataclass$sigma, B = 500)
estimates_plot(ms)
resl
*/


***************************************************************************************
* PUBLICATION BIAS - Endogenous kink (Bom & Rachinger, 2020)
*      code downloaded from https://sites.google.com/site/heikorachinger/codes 
***************************************************************************************

quietly{
*clear 
rename effect_w bs
rename se_effect_w sebs
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

rename  bs effect_w
rename  sebs se_effect_w


***************************************************************************************
* Publication bias - p-uniform* (van Aert & van Assen, 2020) - on median values - code for Stata & R
***************************************************************************************

bysort idstudy: egen effect_med = median(effect)
bysort idstudy: egen se_med = median(se_effect)
bysort idstudy: egen t_med = median(t_stat)
bysort idstudy: egen data_year_med = median(data_year)

gen variance_med = se_med*se_med

bysort idstudy: egen effect_medw = median(effect_w)
bysort idstudy: egen se_medw = median(se_effect_w)
bysort idstudy: egen t_medw = median(tstat_w)
gen variance_medw = se_medw*se_medw

preserve
collapse (lastnm) effect_med effect_medw se_med se_medw variance_med variance_medw t_med t_medw data_year_med (p50) nobs_med=sample_size_w, by(idstudy)
save "puniform_pref.dta", replace
restore
clear

*save "puniform.dta", replace
*keep effect effect_w se_effect se_effect_w variance variance_w


/* on median values
library(puniform)
library(metafor)
library(dmetar)
library(haven)
library(tidyverse)
library(meta)

data <- read_dta("puniform.dta")

data = read.table("clipboard-512", sep="\t", header=TRUE)
puni_star(yi = data$effect_medw, vi = data$variance_medw, side="left", method="ML",alpha = 0.05)
puniform(yi = data$effect_medw, vi = data$variance_medw, side="left", method="ML",alpha = 0.05)
puni_star(yi = data$effectsd_medw, vi = data$variancesd_medw, side="left", method="ML",alpha = 0.05)
puni_star(yi = data$pcc_medw, vi = data$variance_medw, side="left", method="ML",alpha = 0.05)
*/


***************************************************************************************
* PUBLICATION BIAS - Stem-based method in R (Furukawa, 2019) - on median values
***************************************************************************************

/*
source("stem_method.R") #github.com/Chishio318/stem-based_method
dataclass = read.table("clipboard-512", sep="\t", header=TRUE)
stem_results = stem(dataclass$effect_medw, dataclass$se_medw, param)
stem_results[["estimates"]]
*/


***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
*  (C) HETEROGENEITY - Data preparation
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************

clear
import excel "class.xlsx", sheet("data") firstrow
ssc install winsor
set more off

drop if effect_true==0
gen precision = 1/se_effect
winsor effect, generate(effect_w) p(0.01)
winsor se_effect, generate(se_effect_w) p(0.01)
gen se_top5_journal = se_effect_w * top5_journal
gen preferred_estimate = 0
replace preferred_estimate = 1 if estimate_category=="preferred"
gen discounted_estimate = 0
replace discounted_estimate = 1 if estimate_category=="discounted"
gen neutral_estimate = 0
replace neutral_estimate = 1 if estimate_category=="neutral"

sum effect_w se_effect_w se_top5_journal test_in_math test_in_reading test_in_writing test_in_languages test_in_other_subjects class_kindergarten class_primary_school class_secondary_school class_size female_students minority_students disadvantaged_students general_population_students longitudinal_data crosssectional_data data_year country_usa country_scandinavia country_other method_experiment method_instrument method_rdd method_fe method_ols number_of_variables control_students_gender	control_students_age control_students_ethnicity control_household_income control_parental_education control_family_status control_peers_ability control_teachers_experience control_teachers_gender control_teachers_education control_school_size control_rural_population preferred_estimate discounted_estimate top5_journal citations publication_year impact_factor 
*full
collin effect_w se_effect_w se_top5_journal test_in_math test_in_reading test_in_writing test_in_languages class_kindergarten class_primary_school class_size female_students minority_students disadvantaged_students general_population_students crosssectional_data data_year country_usa country_scandinavia method_experiment method_instrument method_rdd method_fe number_of_variables control_students_gender control_students_age control_students_ethnicity control_household_income control_parental_education control_family_status control_peers_ability control_teachers_experience control_teachers_gender control_teachers_education control_school_size control_rural_population preferred_estimate discounted_estimate citations publication_year impact_factor top5_journal
collin effect_w se_effect_w se_top5_journal test_in_math test_in_reading test_in_writing test_in_languages class_kindergarten class_primary_school class_size female_students minority_students disadvantaged_students general_population_students crosssectional_data country_usa country_scandinavia method_experiment method_instrument method_rdd method_fe number_of_variables control_students_gender control_students_age control_students_ethnicity control_household_income control_parental_education control_family_status control_peers_ability control_teachers_experience control_teachers_gender control_teachers_education control_school_size control_rural_population preferred_estimate discounted_estimate citations publication_year impact_factor top5_journal
correlate effect_w se_effect_w se_top5_journal test_in_math test_in_reading test_in_writing test_in_languages class_kindergarten class_primary_school class_size female_students minority_students disadvantaged_students general_population_students crosssectional_data data_year country_usa country_scandinavia method_experiment method_instrument method_rdd method_fe number_of_variables control_students_gender control_students_age control_students_ethnicity control_household_income control_parental_education control_family_status control_peers_ability control_teachers_experience control_teachers_gender control_teachers_education control_school_size control_rural_population preferred_estimate discounted_estimate  citations publication_year impact_factor top5_journal

keep effect_w se_effect_w se_top5_journal test_in_math test_in_reading test_in_writing test_in_languages test_in_other_subjects class_kindergarten class_primary_school class_secondary_school class_size female_students minority_students disadvantaged_students general_population_students longitudinal_data crosssectional_data data_year country_usa country_scandinavia country_other method_experiment method_instrument method_rdd method_fe method_ols number_of_variables control_students_gender	control_students_age control_students_ethnicity control_household_income control_parental_education control_family_status control_peers_ability control_teachers_experience control_teachers_gender control_teachers_education control_school_size control_rural_population preferred_estimate discounted_estimate top5_journal citations publication_year impact_factor 
order effect_w se_effect_w se_top5_journal test_in_math test_in_reading test_in_writing test_in_languages test_in_other_subjects class_kindergarten class_primary_school class_secondary_school class_size female_students minority_students disadvantaged_students general_population_students longitudinal_data crosssectional_data data_year country_usa country_scandinavia country_other method_experiment method_instrument method_rdd method_fe method_ols number_of_variables control_students_gender	control_students_age control_students_ethnicity control_household_income control_parental_education control_family_status control_peers_ability control_teachers_experience control_teachers_gender control_teachers_education control_school_size control_rural_population preferred_estimate discounted_estimate top5_journal citations publication_year impact_factor 
export excel using "data_4R.xlsx", sheet("data") firstrow(variables) replace
clear

**************************************************************************************
***************************************************************************************
* HETEROGENEITY - BAYEASIAN MODEL AVERAGING ////CODE for R////
***************************************************************************************
***************************************************************************************
/*
rm(list=ls())

library("data.table")
library("BMS")
library("openxlsx")
library("RStata")
library("stargazer")
library("readstata13")
library("foreign")
library("ggplot2")
library("reshape2")
library("corrplot")
library("installr")
library("xtable")
library("LowRankQP")

    *ctrl+C from data_4R.xlsx
dataclass = read.table("clipboard-512", sep="\t", header=TRUE)
colnames(dataclass)	<- c("Effect","Standard error (SE)","SE * Top journal", "Math", "Reading", "Writing", "Languages", "Other subjects", "Kindergarten class", "Primary school", "Secondary school", "Class size", "Female students", "Minority students", "Disadvantaged students", "General population", "Longitudinal data", "Cross-sectional data", "Data year", "USA", "Scandinavian countries","Other countries", "STAR experiment", "Instrumental variable", "Regression discontinuity", "Fixed effects", "OLS", "Number of variables", "Control: student's gender", "Control: student's age", "Control: student's ethnicity", "Control: household income", "Control: parental education", "Control: family status", "Control: peers' ability", "Control: teacher's experience", "Control: teacher's gender", "Control: teacher's education", "Control: school size", "Control: rural population", "Preferred estimate", "Discounted estimate", "Top journal", "Citations", "Publication year", "Impact factor")

data_orig	<- c("Effect", "Standard error (SE)", "SE * Top journal", "Math", "Reading", "Writing", "Languages", "Kindergarten class", "Primary school", "Class size", "Female students", "Minority students", "Disadvantaged students","Advantaged students",  "General population", "Cross-sectional data", "Data year", "USA", "Scandinavian countries", "STAR experiment", "Regression discontinuity", "Instrumental variable", "Fixed effects", "Number of variables", "Control: student's gender", "Control: student's age", "Control: student's ethnicity", "Control: household income", "Control: parental education", "Control: family status", "Control: peers' ability", "Control: teacher's experience", "Control: teacher's gender", "Control: teacher's education", "Control: school size", "Control: rural population", "Preferred estimate", "Discounted estimate", "Top journal", "Citations", "Publication year", "Impact factor")
data_1 		<- c("Effect", "Standard error (SE)", "SE * Top journal", "Math", "Reading", "Writing", "Languages", "Kindergarten class", "Primary school", "Class size", "Female students", "Minority students", "Disadvantaged students", "General population", "Cross-sectional data", "USA", "Scandinavian countries", "STAR experiment", "Regression discontinuity", "Instrumental variable", "Fixed effects", "Number of variables", "Control: student's gender", "Control: student's age", "Control: student's ethnicity", "Control: household income", "Control: parental education", "Control: family status", "Control: peers' ability", "Control: teacher's experience", "Control: teacher's gender", "Control: teacher's education", "Control: school size", "Control: rural population", "Preferred estimate", "Discounted estimate", "Top journal", "Citations", "Publication year")

data_df		<- dataclass[data_1]


class1 = bms(data_df, burn=1e5,iter=3e5, g="UIP", mprior="dilut", nmodel=50000, mcmc="bd", user.int=FALSE)
coef(class1, order.by.pip = F, exact=T, include.constant=T)
pdf("bma_dilut.pdf")
image(class1, cex=0.7, xlab="", main="")
dev.off()
summary(class1)
pdf("bma_dilut_pmp.pdf")
plot(class1)
dev.off()
print(class1$topmod[1])

class2 = bms(data_df, burn=1e5,iter=3e5, g="BRIC", mprior="random", nmodel=50000, mcmc="bd", user.int=FALSE)
coef(class2, order.by.pip = F, exact=T, include.constant=T)
pdf("bma_bric.pdf")
image(class2, cex=0.7, xlab="", main="")
dev.off()
summary(class2)
pdf("bma_bric_pmp.pdf")
plot(class2)
dev.off()
print(class2$topmod[1])

par(mfrow=c(4,2))
density(class1, reg="SE * Top journal")
density(class1, reg="Primary school")
density(class1, reg="Class size")
density(class1, reg="STAR experiment")
density(class1, reg="Control: household income")
density(class1, reg="Control: peers' ability")
density(class1, reg="Cross-sectional data")
density(class1, reg="Control: parental education")

*drop <- c("data_year") 

library(corrplot)
dataclass = read.table("clipboard-512", sep="\t", header=TRUE)
col<- colorRampPalette(c("red", "white", "blue"))
M <- cor(dataclass)
corrplot.mixed(M, lower = "number", upper = "circle", lower.col=col(200), upper.col=col(200), tl.pos = c("lt"), diag = c("u"), tl.col="black", tl.srt=45, tl.cex=0.85, number.cex = 0.5, cl.cex=0.8, cl.ratio=0.1)
*/

***************************************************************************************
***************************************************************************************
* HETEROGENEITY - FREQUENTIST MODEL AVERAGING (MALLOWS) ////CODE for R////
***************************************************************************************
***************************************************************************************

/*
library(foreign)
library(xtable)
library(readxl)
library(LowRankQP)

*dataclass=read.table("clipboard-512", sep="\t", header=TRUE)

dataclass <- data_df
dataclass <-na.omit(dataclass)
x.data <- dataclass[,-1]
const_<-c(1)
x.data <-cbind(const_,x.data)

x <- sapply(1:ncol(x.data),function(i){x.data[,i]/max(x.data[,i])})   
scale.vector <- as.matrix(sapply(1:ncol(x.data),function(i){max(x.data[,i])}))        
Y <- as.matrix(dataclass[,1])
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
names <- c(colnames(dataclass))
names <- c(names,"const_")
MMA.fls <- MMA.fls[match(names, MMA.fls$names),]
MMA.fls$names <- NULL
MMA.fls

library(xtable)
xtable(MMA.fls,digits=c(0,3,3,3))
separator   = ";"
write.table(MMA.fls,"fma.csv",sep=separator, append = FALSE)
*/

***************************************************************************************
***************************************************************************************
* BEST-PRACTICE (SE calculation to BMA estimate)
***************************************************************************************
***************************************************************************************

clear
import excel "class.xlsx", sheet("data") firstrow
ssc install winsor
set more off

drop if effect_true==0
gen precision = 1/se_effect
winsor effect, generate(effect_w) p(0.01)
winsor se_effect, generate(se_effect_w) p(0.01)
gen se_top5_journal = se_effect_w * top5_journal
gen preferred_estimate = 0
replace preferred_estimate = 1 if estimate_category=="preferred"
gen discounted_estimate = 0
replace discounted_estimate = 1 if estimate_category=="discounted"
gen neutral_estimate = 0
replace neutral_estimate = 1 if estimate_category=="neutral"

ivreg2 effect_w se_top5_journal class_primary_school class_size crosssectional_data method_experiment method_instrument control_household_income control_parental_education control_peers_ability preferred_estimate publication_year, cluster(idstudy)

summarize number_of_variables, detail
summarize impact_factor, detail
summarize citations, detail


set more off
local variables effect_w se_effect_w se_top5_journal test_in_math test_in_reading test_in_writing test_in_languages class_kindergarten class_primary_school class_size female_students minority_students disadvantaged_students general_population_students crosssectional_data country_usa country_scandinavia method_experiment method_instrument method_rdd method_fe number_of_variables control_students_gender control_students_age control_students_ethnicity control_household_income control_parental_education control_family_status control_peers_ability control_teachers_experience control_teachers_gender control_teachers_education control_school_size control_rural_population preferred_estimate discounted_estimate top5_journal citations publication_year 
foreach x of varlist `variables' {
sum  `x' 
local m`x' =r(mean)  
local min`x' =r(min)
local max`x' =r(max)
}

ivreg2 effect_w se_effect_w se_top5_journal test_in_math test_in_reading test_in_writing test_in_languages class_kindergarten class_primary_school class_size female_students minority_students disadvantaged_students general_population_students crosssectional_data country_usa country_scandinavia method_experiment method_instrument method_rdd method_fe number_of_variables control_students_gender control_students_age control_students_ethnicity control_household_income control_parental_education control_family_status control_peers_ability control_teachers_experience control_teachers_gender control_teachers_education control_school_size control_rural_population preferred_estimate discounted_estimate top5_journal citations publication_year

*Overall
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Method: Field experiment
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*1+method_rdd*0+method_instrument*0+method_fe*0+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Method: RDD
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*0+method_rdd*1+method_instrument*0+method_fe*0+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Method: IV
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*0+method_rdd*0+method_instrument*1+method_fe*0+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Method: FE
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*0+method_rdd*0+method_instrument*0+method_fe*1+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Method: OLS
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*0+method_rdd*0+method_instrument*0+method_fe*0+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Kindergarten class
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*1+class_primary_school*0+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Primary school
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*0+class_primary_school*1+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Secondary school
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*0+class_primary_school*0+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Disadvantaged students
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*1+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Country: United States
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*1+country_scandinavia*0+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Country: Scandinavian
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*0+country_scandinavia*1+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Country: other
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*0+country_scandinavia*0+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Test in math
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*1+test_in_reading*0+test_in_writing*0+test_in_languages*0+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Test in reading
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*0+test_in_reading*1+test_in_writing*0+test_in_languages*0+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Test in writing
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*0+test_in_reading*0+test_in_writing*1+test_in_languages*0+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Test in languages
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*0+test_in_reading*0+test_in_writing*0+test_in_languages*1+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Test in other subject
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*0+test_in_reading*0+test_in_writing*0+test_in_languages*0+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*`mclass_size'+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Class size = 15
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*1.220829921+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Class size = 20
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*2.12704052+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Class size = 25
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*2.59450816+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Class size = 30
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*2.911807039+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1
*Class size = 35
lincom _cons+se_effect_w*0+se_top5_journal*0+test_in_math*`mtest_in_math'+test_in_reading*`mtest_in_reading'+test_in_writing*`mtest_in_writing'+test_in_languages*`mtest_in_languages'+class_kindergarten*`mclass_kindergarten'+class_primary_school*`mclass_primary_school'+class_size*3.152308581+female_students*`mfemale_students'+minority_students*`mminority_students'+disadvantaged_students*`mdisadvantaged_students'+general_population_students*`mgeneral_population_students'+crosssectional_data*0+country_usa*`mcountry_usa'+country_scandinavia*`mcountry_scandinavia'+method_experiment*`mmethod_experiment'+method_rdd*`mmethod_rdd'+method_instrument*`mmethod_instrument'+method_fe*`mmethod_fe'+number_of_variables*`maxnumber_of_variables'+control_students_gender*1+control_students_age*1+control_students_ethnicity*1+control_household_income*1+control_parental_education*1+control_family_status*1+control_peers_ability*1+control_teachers_experience*1+control_teachers_gender*1+control_teachers_education*1+control_school_size*1+control_rural_population*1+preferred_estimate*1+discounted_estimate*0+citations*`maxcitations'+publication_year*`mpublication_year'+top5_journal*1

clear
log close



* MEDIANS ON WHOLE SAMPLE
use "puniform.dta", clear
gen precision_medw = 1/se_medw
gen sqrt_nobs_med = sqrt(nobs_med)
mean effect_medw
twoway scatter precision_medw effect_medw, yscale(log) ylab(0.5  10 100,grid) xlab(,g)  ytitle("Precision of the effect (1/SE)") ylabel( ,glcolor(black) glpattern(dot)) xtitle("Effect of class size on student achievement") xline(0, lpattern(solid) lcolor (ltblue)) xline(-.7416299, lpattern(dott) lcolor (red)) msymbol(smcircle_hollow) bgcolor(white) graphregion(color(white) lwidth(large)) saving(funnel_all_med, replace)

eststo: ivreg2 effect_medw se_medw, robust 
eststo: ivreg2 effect_medw (se_medw = sqrt_nobs_med), robust first		
			twostepweakiv 2sls effect_medw (se_medw = sqrt_nobs_med), robust
eststo: ivreg2 effect_medw se_medw [pweight=precision_med], robust
esttab using table_bias_med.tex, float se booktabs replace compress title(Tests suggest small publication bias overall\label{tab:fatpett}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "IV" "Precision") label
eststo clear
clear


* MEDIANS ON PREFFERED SAMPLE
use "puniform_pref.dta", clear
gen precision_medw = 1/se_medw
gen sqrt_nobs_med = sqrt(nobs_med)
mean effect_medw
twoway scatter precision_medw effect_medw, yscale(log) ylab(0.5  10 100,grid) xlab(,g)  ytitle("Precision of the effect (1/SE)") ylabel( ,glcolor(black) glpattern(dot)) xtitle("Effect of class size on student achievement") xline(0, lpattern(solid) lcolor (ltblue)) xline( -.9315717, lpattern(dott) lcolor (red)) msymbol(smcircle_hollow) bgcolor(white) graphregion(color(white) lwidth(large)) saving(funnel_pref_med, replace)

eststo: ivreg2 effect_medw se_medw, robust
eststo: ivreg2 effect_medw (se_medw = sqrt_nobs_med), robust first		
			twostepweakiv 2sls effect_medw (se_medw = sqrt_nobs_med), robust
eststo: ivreg2 effect_medw se_medw [pweight=precision_med], robust
esttab using table_bias_pref_med.tex, float se booktabs replace compress title(Tests suggest small publication bias overall\label{tab:fatpett}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "IV" "Precision") label
eststo clear

summarize effect_medw [aweight=precision_medw*precision_medw]
gen waapbound_med = abs(r(mean))/2.8
reg t_medw precision_medw if se_medw  < waapbound_med, noconstant


quietly{
*clear 
rename effect_medw bs
rename se_medw sebs
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

rename  bs effect_medw
rename  sebs se_medw

