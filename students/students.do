***************************************************************************************
***************************************************************************************
****** The Impact of Student Employment on Educational Outcomes: A Meta-Analysis ******
***************************************************************************************
***************************************************************************************
* Feb 15, 2024
log using students.log, replace
import excel students.xlsx, sheet("data") firstrow
set more off

***************************************************************************************
* Summary statistics and patterns in data
***************************************************************************************
drop if idstudy>69
drop if missing(pcc)
drop if missing(se_pcc)
winsor pcc, generate(pcc_w) p(0.01)
winsor se_pcc, generate(se_pcc_w) p(0.01)
winsor sample_size_full, generate(sample_size_full_w) p(0.01)
gen tstat_w = pcc_w/se_pcc_w
gen precision_w = 1/se_pcc_w
gen precision = 1/se_pcc
*number of estimates per study
bysort idstudy: egen nest = count(pcc_w)
gen inv_nest = 1/nest
*number of observations used to estimate pcc
gen double nobs = sqrt(sample_size_full_w)
gen inv_nobs = 1/nobs
gen no_endogeneity_control = 0
replace no_endogeneity_control = 1 if endogeneity_control==0
gen se_no_endogeneity_control = se_pcc_w * no_endogeneity_control
gen se_endogeneity_control = se_pcc_w * endogeneity_control
generate countries_excl_usge = 1
replace countries_excl_usge = 0 if usa==1 | germany==1
gen other_method = 0
replace other_method = 1 if  panel_method==1 | dynamic_model==1
univar pcc pcc_w se_pcc se_pcc_w

sum pcc_w, detail
sum pcc_w [aweight=inv_nest], detail

***************************************************************************************
* PUBLICATION BIAS - testing larger sample
***************************************************************************************
xtset idstudy

*FULL SAMPLE on 876 obs
*basic linear tests (ols, instrument, study-weighted, precision-weighted)
eststo: ivreg2 pcc_w se_pcc_w, cluster(idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph 
eststo: ivreg2 pcc (se_pcc_w = inv_nobs), cluster (idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph
eststo: ivreg2 pcc_w se_pcc_w [pweight=inv_nobs], cluster (idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph
eststo: ivreg2 pcc_w se_pcc_w [pweight=precision_w], cluster (idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph
esttab using table_bias1_new_sample.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
*within and between-study variation (be, fe, re) 
eststo: xtreg pcc_w se_pcc_w, be
eststo: xtreg pcc_w se_pcc_w, fe vce(cluster idstudy)
eststo: xtreg pcc_w se_pcc_w, re
esttab using table_bias2_new_sample.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

summarize precision_w, detail
gen top10bound = r(p90)
summarize pcc_w precision_w if precision_w > top10bound

summarize pcc_w [aweight=precision_w*precision_w]
gen waapbound = abs(r(mean))/2.8
reg tstat precision_w if se_pcc < waapbound, noconstant

***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
clear
import excel students.xlsx, sheet("data") firstrow
set more off
***************************************************************************************
* Summary statistics and patterns in data
***************************************************************************************
drop if idstudy>69
drop if missing(pcc)
drop if missing(se_pcc)
winsor pcc, generate(pcc_w) p(0.01)
winsor se_pcc, generate(se_pcc_w) p(0.01)
winsor sample_size_full, generate(sample_size_full_w) p(0.01)
gen tstat_w = pcc_w/se_pcc_w
gen precision_w = 1/se_pcc_w
gen precision = 1/se_pcc
gen citations_med = exp(citations)
*number of estimates per study
bysort idstudy: egen nest = count(pcc_w)
gen inv_nest = 1/nest
*number of observations used to estimate pcc
gen double nobs = sqrt(sample_size_full_w)
gen inv_nobs = 1/nobs
gen no_endogeneity_control = 0
replace no_endogeneity_control = 1 if endogeneity_control==0
gen se_no_endogeneity_control = se_pcc_w * no_endogeneity_control
gen se_endogeneity_control = se_pcc_w * endogeneity_control
generate countries_excl_usge = 1
replace countries_excl_usge = 0 if usa==1 | germany==1
gen other_method = 0
replace other_method = 1 if  panel_method==1 | dynamic_model==1
univar pcc pcc_w se_pcc se_pcc_w

sum pcc_w, detail
sum pcc_w [aweight=inv_nest], detail
sum pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy employment_categorical education_choice education_attainment education_test selfreported_education longitudinal_data crosssectional_data data_year sample_size male_students female_students mixed_gender_students caucasian_students minority_students parttime_students secondary_education tertiary_education low_intensity_employment medium_intensity_employment high_intensity_employment oncampus_employment usa germany europe countries_excl_usge endogeneity_control ols_method matching_method did_method iv_method other_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control publication_year impact_factor citations published_study 
sum pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy employment_categorical education_choice education_attainment education_test selfreported_education longitudinal_data crosssectional_data data_year sample_size male_students female_students mixed_gender_students caucasian_students minority_students parttime_students secondary_education tertiary_education low_intensity_employment medium_intensity_employment high_intensity_employment oncampus_employment usa germany europe countries_excl_usge endogeneity_control ols_method matching_method did_method iv_method other_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control publication_year impact_factor citations published_study [aweight=inv_nest]

mean pcc_w
mean pcc_w if education_choice==1
mean pcc_w if education_attainment==1
mean pcc_w if education_test==1
mean pcc_w if employment_continuous==1
mean pcc_w if employment_dummy==1
mean pcc_w if employment_categorical==1
mean pcc_w if selfreported_education==1
mean pcc_w if longitudinal_data==1
mean pcc_w if crosssectional_data==1
mean pcc_w if male_students==1
mean pcc_w if female_students==1
mean pcc_w if mixed_gender_students==1
mean pcc_w if caucasian_students==1
mean pcc_w if minority_students==1
mean pcc_w if parttime_students==1
mean pcc_w if secondary_education==1
mean pcc_w if tertiary_education==1
mean pcc_w if low_intensity_employment==1
mean pcc_w if medium_intensity_employment==1
mean pcc_w if high_intensity_employment==1
mean pcc_w if oncampus_employment==1
mean pcc_w if usa==1 
mean pcc_w if germany==1 
mean pcc_w if countries_excl_usge==1
mean pcc_w if endogeneity_control==1
mean pcc_w if endogeneity_control==0
mean pcc_w if ols_method==1
mean pcc_w if matching_method==1
mean pcc_w if did_method==1
mean pcc_w if iv_method==1
mean pcc_w if other_method==1
mean pcc_w if published==0
mean pcc_w if published==1
mean pcc_w if pub_year>1978 & pub_year<1991
mean pcc_w if pub_year>=1991 & pub_year<2001
mean pcc_w if pub_year>=2001 & pub_year<2011
mean pcc_w if pub_year>=2011

mean pcc_w [aweight=inv_nest]
mean pcc_w [aweight=inv_nest] if education_choice==1
mean pcc_w [aweight=inv_nest] if education_attainment==1
mean pcc_w [aweight=inv_nest] if education_test==1
mean pcc_w [aweight=inv_nest] if employment_continuous==1
mean pcc_w [aweight=inv_nest] if employment_dummy==1
mean pcc_w [aweight=inv_nest] if employment_categorical==1
mean pcc_w [aweight=inv_nest] if selfreported_education==1
mean pcc_w [aweight=inv_nest] if longitudinal_data==1
mean pcc_w [aweight=inv_nest] if crosssectional_data==1
mean pcc_w [aweight=inv_nest] if male_students==1
mean pcc_w [aweight=inv_nest] if female_students==1
mean pcc_w [aweight=inv_nest] if mixed_gender_students==1
mean pcc_w [aweight=inv_nest] if caucasian_students==1
mean pcc_w [aweight=inv_nest] if minority_students==1
mean pcc_w [aweight=inv_nest] if parttime_students==1
mean pcc_w [aweight=inv_nest] if secondary_education==1
mean pcc_w [aweight=inv_nest] if tertiary_education==1
mean pcc_w [aweight=inv_nest] if low_intensity_employment==1
mean pcc_w [aweight=inv_nest] if medium_intensity_employment==1
mean pcc_w [aweight=inv_nest] if high_intensity_employment==1
mean pcc_w [aweight=inv_nest] if oncampus_employment==1
mean pcc_w [aweight=inv_nest] if usa==1 
mean pcc_w [aweight=inv_nest] if germany==1
mean pcc_w [aweight=inv_nest] if countries_excl_usge==1
mean pcc_w [aweight=inv_nest] if endogeneity_control==1
mean pcc_w [aweight=inv_nest] if endogeneity_control==0
mean pcc_w [aweight=inv_nest] if ols_method==1
mean pcc_w [aweight=inv_nest] if matching_method==1
mean pcc_w [aweight=inv_nest] if did_method==1
mean pcc_w [aweight=inv_nest] if iv_method==1
mean pcc_w [aweight=inv_nest] if other_method==1
mean pcc_w [aweight=inv_nest] if published==0
mean pcc_w [aweight=inv_nest] if published==1
mean pcc_w [aweight=inv_nest] if pub_year>1978 & pub_year<1991
mean pcc_w [aweight=inv_nest] if pub_year>=1991 & pub_year<2001
mean pcc_w [aweight=inv_nest] if pub_year>=2001 & pub_year<2011
mean pcc_w [aweight=inv_nest] if pub_year>=2011

sum estimate if homogeneous_subsample==1, detail

histogram pcc_w if pcc_w >-0.25 & pcc_w<0.13, bin(50) fcolor(gs14) lstyle(thin) frequency xtitle("Estimated effect of student employment on educational outcomes" "(partial correlation coefficient)") xline(-0.02, lcolor(black)) xline(-0.02, lcolor(red)) xlabel(-.2 -.1 0 .1) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram, replace)
bysort idstudy: egen pcc_w_med = median(pcc_w)
bysort idstudy: egen mid_year_med = median(mid_year)
generate pcc_w_med2=pcc_w_med
graph twoway (scatter pcc_w_med2 mid_year_med if pcc_w_med2>-0.5, msize(*1) msymbol(Oh) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray))) (lfit pcc_w_med2 mid_year_med, lcolor(black)),  xtitle("Median year of data") ytitle("Median PCC of the effect") legend(off) saving(trend, replace)
graph twoway (scatter citations_med pcc_w_med2 if pcc_w_med2>-0.5 & citations_med<50, msize(*1) msymbol(Oh) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray))) (lfit citations_med pcc_w_med2, lcolor(black)),  xtitle("Median estimated effect of student employment on educational outcomes" "(partial correlation coefficient)") ytitle("Citations per year") legend(off) saving(trend, replace)


twoway(hist pcc_w if longitudinal_data==1 & pcc_w>-0.25 & pcc_w<0.13, bin(50) freq fcolor(navy) lcolor(navy) legend(label(1 "Time series or panel"))) (hist pcc_w if crosssectional_data==1 & pcc_w>-0.25 & pcc_w<0.13, bin(50) freq fcolor(orange_red) lcolor(orange_red) legend(label(2 "Cross-sectional data"))), legend(ring(0) position(11) bmargin(medium) rows(2) region(lstyle(none))) xtitle("Estimated effect of student employment on educational outcomes" "(partial correlation coefficient)")  saving(pattern1, replace)
twoway(hist pcc_w if education_test==1 & pcc_w>-0.25 & pcc_w<0.13, bin(50) freq fcolor(gs13) lcolor(gs13) legend(label(1 "Educational outcome: test scores"))) (hist pcc_w if education_choice==1 & pcc_w>-0.25 & pcc_w<0.13, bin(50) freq fcolor(navy) lcolor(navy) legend(label(2 "Educational outcome: choices")))(hist pcc_w if education_attainment==1 & pcc_w>-0.25 & pcc_w<0.13, bin(50) freq fcolor(orange_red) lcolor(orange_red) legend(label(3 "Educational outcome: attainment"))), legend(ring(0) position(11) bmargin(medium) rows(3) region(lstyle(none))) xtitle("Estimated effect of student employment on educational outcomes" "(partial correlation coefficient)")  saving(pattern2, replace)
twoway(hist pcc_w if high_intensity_employment==1 & pcc_w>-0.25 & pcc_w<0.13, bin(40) freq fcolor(orange_red) lcolor(orange_red) legend(label(1 "High-intensity employment"))) (hist pcc_w if low_intensity_employment==1 & pcc_w>-0.25 & pcc_w<0.13, bin(40) freq fcolor(gs13) lcolor(gs13) legend(label(2 "Low-intensity employment"))) , legend(ring(0) position(11) bmargin(medium) rows(2) region(lstyle(none))) xtitle("Estimated effect of student employment on educational outcomes" "(partial correlation coefficient)")  saving(pattern3, replace)
twoway(hist pcc_w if secondary_education==1 & pcc_w>-0.25 & pcc_w<0.13, bin(50) freq fcolor(navy) lcolor(navy) legend(label(1 "Secondary education"))) (hist pcc_w if tertiary_education==1 & pcc_w>-0.25 & pcc_w<0.13, bin(50) freq fcolor(orange_red) lcolor(orange_red) legend(label(2 "Tertiary education"))), legend(ring(0) position(11) bmargin(medium) rows(2) region(lstyle(none))) xtitle("Estimated effect of student employment on educational outcomes" "(partial correlation coefficient)")  saving(pattern4, replace)
twoway(hist pcc_w if endogeneity_control==0 & pcc_w>-0.25 & pcc_w<0.13, bin(50) freq fcolor(orange_red) lcolor(orange_red) legend(label(1 "No endogeneity control"))) (hist pcc_w if endogeneity_control==1 & pcc_w>-0.25 & pcc_w<0.13, bin(50) freq fcolor(navy) lcolor(navy) legend(label(2 "Endogeneity control"))), legend(ring(0) position(11) bmargin(medium) rows(2) region(lstyle(none))) xtitle("Estimated effect of student employment on educational outcomes" "(partial correlation coefficient)")  saving(pattern5, replace)
twoway(hist pcc_w if usa==1 & pcc_w>-0.25 & pcc_w<0.13, bin(50) freq fcolor(gs13) lcolor(gs13) legend(label(1 "United States"))) (hist pcc_w if countries_excl_usge==1 & pcc_w>-0.25 & pcc_w<0.13, bin(50) freq fcolor(navy) lcolor(navy) legend(label(2 "Other countries")))  (hist pcc_w if germany==1 & pcc_w>-0.25 & pcc_w<0.13, bin(50) freq fcolor(orange_red) lcolor(orange_red) legend(label(3 "Germany"))), legend(ring(0) position(11) bmargin(medium) rows(3) region(lstyle(none))) xtitle("Estimated effect of student employment on educational outcomes" "(partial correlation coefficient)")  saving(pattern6, replace)
graph hbox pcc_w if pcc_w>-0.3 & pcc_w<0.13, over(study, label(grid)) xsize(3) ysize(4) scale(0.5) yline(0, lcolor (red))  box(1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow)  mcolor(gs13)) ytitle("Estimated effect of student employment on educational outcomes" "(partial correlation coefficient)") ylabel(, nogrid) saving(studies, replace) 
graph hbox pcc_w if pcc_w>-0.3 & pcc_w<0.13, over(study, label(grid) sort(mid_year_med))  xsize(3) ysize(4) scale(0.5) yline(0, lcolor (red))  box(1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow)  mcolor(gs12)) ytitle("Estimated effect of student employment on educational outcomes" "(partial correlation coefficient)") ylabel(, nogrid) saving(studies_bydatayear, replace) 
graph hbox pcc_w if pcc_w>-0.25 & pcc_w<0.13, over(country, label(grid)) xsize(3) ysize(2) scale(1.05) yline(0, lcolor (red))  box(1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow)  mcolor(gs12)) ytitle("Estimated effect of student employment on educational outcomes" "(partial correlation coefficient)") ylabel(, nogrid) saving(countries, replace) 
egen mean = mean(pcc_w), by(idstudy)
graph hbox pcc_w if pcc_w>-0.3 & pcc_w<0.13, over(no_endogeneity_control)  over(study, label(grid) sort(mean)) xsize(3) ysize(4) scale(0.5) yline(0, lcolor (red)) asyvars  box(1,lcolor(black) fcolor(red)) box(2,lcolor(black) fcolor(gs12)) marker(1,msymbol(circle_hollow)  mcolor(cranberry)) marker(2,msymbol(circle_hollow)  mcolor(gs12)) ytitle("Estimated effect of student employment on educational outcomes" "(partial correlation coefficient)") ylabel(, nogrid)  saving(studies_endo, replace)
graph hbox pcc_w if pcc_w>-0.3 & pcc_w<0.13, over(tertiary_education)  over(study, label(grid) sort(mean)) xsize(3) ysize(4) scale(0.5) yline(0, lcolor (red)) asyvars  box(1,lcolor(black) fcolor(navy)) box(2,lcolor(black) fcolor(gs12)) marker(1,msymbol(circle_hollow)  mcolor(navy)) marker(2,msymbol(circle_hollow)  mcolor(gs12)) ytitle("Estimated effect of student employment on educational outcomes" "(partial correlation coefficient)") ylabel(, nogrid)  saving(studies_educ, replace)
*Hwang (2013)
sum pcc if endogeneity_control==1 & idstudy==28, detail
*Paul (1982)
sum pcc if endogeneity_control==1 & idstudy==45, detail
sum pcc if no_endogeneity_control==1 & idstudy==45, detail
*Rochford et al. (2009)
sum pcc if no_endogeneity_control==1 & idstudy==47, detail
*Salamonson & Andrew (2006)
sum pcc if no_endogeneity_control==1 & idstudy==50, detail
*Hwang (2013)
sum pcc if tertiary_education==1 & idstudy==28, detail
*Paul (1982)
sum pcc if tertiary_education==1 & idstudy==45, detail
*Rochford et al. (2009)
sum pcc if tertiary_education==1 & idstudy==47, detail
*Salamonson & Andrew (2006)
sum pcc if tertiary_education==1 & idstudy==50, detail

***************************************************************************************
* PUBLICATION BIAS - Funnel plot (Egger et al., 1997)
***************************************************************************************
quietly sum pcc, detail
local m = r(mean)
local median = r(p50)
twoway scatter precision pcc if pcc>-0.35, ytitle("Precision of the partial correlation coefficient (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimated effect of student employment on educational outcomes" "(partial correlation coefficient)") xline(`median', lpattern(dash) lcolor (black)) xline(`m', lpattern(dott) lcolor (black)) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel, replace)
***************************************************************************************
* PUBLICATION BIAS - FAT-PET (Stanley, 2005)
***************************************************************************************
xtset idstudy

*FULL SAMPLE
*basic linear tests (ols, instrument, study-weighted, precision-weighted)
eststo: ivreg2 pcc_w se_pcc_w, cluster(idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph 
eststo: ivreg2 pcc (se_pcc_w = inv_nobs), cluster (idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph
eststo: ivreg2 pcc_w se_pcc_w [pweight=inv_nobs], cluster (idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph
eststo: ivreg2 pcc_w se_pcc_w [pweight=precision_w], cluster (idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph
esttab using table_bias1.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
*within and between-study variation (be, fe, re) 
eststo: xtreg pcc_w se_pcc_w, be
eststo: xtreg pcc_w se_pcc_w, fe vce(cluster idstudy)
eststo: xtreg pcc_w se_pcc_w, re
esttab using table_bias2.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


*ENDOGENEITY CONTROL
*basic linear tests (ols, instrument, study-weighted, precision-weighted)
eststo: ivreg2 pcc_w se_pcc_w if endogeneity_control==1, cluster(idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph 
eststo: ivreg2 pcc (se_pcc_w = inv_nobs) if endogeneity_control==1, cluster (idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph
eststo: ivreg2 pcc_w se_pcc_w [pweight=inv_nobs] if endogeneity_control==1, cluster (idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph
eststo: ivreg2 pcc_w se_pcc_w [pweight=precision_w] if endogeneity_control==1, cluster (idstudy)
boottest se_pcc, nograph
boottest _cons, nograph
esttab using table_bias1_endo.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
*within and between-study variation (be, fe, re) 
eststo: xtreg pcc_w se_pcc_w if endogeneity_control==1, be
eststo: xtreg pcc_w se_pcc_w if endogeneity_control==1, fe vce(cluster idstudy)
boottest se_pcc_w, nograph
eststo: xtreg pcc_w se_pcc_w if endogeneity_control==1, re
esttab using table_bias2_endo.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


*NO ENDOGENEITY CONTROL
*basic linear tests (ols, instrument, study-weighted, precision-weighted)
eststo: ivreg2 pcc_w se_pcc_w if endogeneity_control==0, cluster(idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph 
eststo: ivreg2 pcc (se_pcc_w = inv_nobs) if endogeneity_control==0, cluster (idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph
eststo: ivreg2 pcc_w se_pcc_w [pweight=inv_nobs] if endogeneity_control==0, cluster (idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph
eststo: ivreg2 pcc_w se_pcc_w [pweight=precision_w] if endogeneity_control==0, cluster (idstudy)
boottest se_pcc, nograph
boottest _cons, nograph
esttab using table_bias1_noendo.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
*within and between-study variation (be, fe, re) 
eststo: xtreg pcc_w se_pcc_w if endogeneity_control==0, be
eststo: xtreg pcc_w se_pcc_w if endogeneity_control==0, fe vce(cluster idstudy)
eststo: xtreg pcc_w se_pcc_w if endogeneity_control==0, re
esttab using table_bias2_noendo.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


*COMMON METRICS (not PCCs)
*basic linear tests (ols, instrument, study-weighted, precision-weighted)
sum estimate se_estimate if homogeneous_subsample==1, detail
eststo: ivreg2 estimate se_estimate if homogeneous_subsample==1, cluster(idstudy)
boottest se_estimate, nograph
boottest _cons, nograph 
eststo: ivreg2 estimate (se_estimate = inv_nobs) if homogeneous_subsample==1
eststo: ivreg2 estimate se_estimate if homogeneous_subsample==1 [pweight=inv_nobs]
boottest se_estimate, nograph
boottest _cons, nograph
eststo: ivreg2 estimate se_estimate if homogeneous_subsample==1 [pweight=precision_w]
boottest se_estimate, nograph
boottest _cons, nograph
esttab using table_bias1_homog.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
*within and between-study variation (be, fe, re) 
eststo: xtreg estimate se_estimate if homogeneous_subsample==1, be
eststo: xtreg estimate se_estimate if homogeneous_subsample==1, fe
eststo: xtreg estimate se_estimate if homogeneous_subsample==1, re
esttab using table_bias2_homog.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


*COMMON METRICS (not PCCs) ENDOGENOUS
*basic linear tests (ols, instrument, study-weighted, precision-weighted)
sum estimate se_estimate if homogeneous_subsample==1 & endogeneity_control==1, detail
eststo: ivreg2 estimate se_estimate if homogeneous_subsample==1 & endogeneity_control==1, cluster(idstudy)
boottest se_estimate, nograph
boottest _cons, nograph 
eststo: ivreg2 estimate (se_estimate = inv_nobs) if homogeneous_subsample==1 & endogeneity_control==1
eststo: ivreg2 estimate se_estimate if homogeneous_subsample==1 & endogeneity_control==1 [pweight=inv_nobs]
boottest se_estimate, nograph
boottest _cons, nograph
eststo: ivreg2 estimate se_estimate if homogeneous_subsample==1 & endogeneity_control==1 [pweight=precision_w]
boottest se_estimate, nograph
boottest _cons, nograph
esttab using table_bias1_homog_endoctrl.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
*within and between-study variation (be, fe, re) 
eststo: xtreg estimate se_estimate if homogeneous_subsample==1 & endogeneity_control==1, be
eststo: xtreg estimate se_estimate if homogeneous_subsample==1 & endogeneity_control==1, fe
eststo: xtreg estimate se_estimate if homogeneous_subsample==1 & endogeneity_control==1, re
esttab using table_bias2_homog_endoctrl.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


*SAMPLE WITHOUT USA
*basic linear tests (ols, instrument, study-weighted, precision-weighted)
eststo: ivreg2 pcc_w se_pcc_w if usa==0, cluster(idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph 
eststo: ivreg2 pcc (se_pcc_w = inv_nobs) if usa==0, cluster (idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph
eststo: ivreg2 pcc_w se_pcc_w [pweight=inv_nobs] if usa==0, cluster (idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph
eststo: ivreg2 pcc_w se_pcc_w [pweight=precision_w] if usa==0, cluster (idstudy)
boottest se_pcc_w, nograph
boottest _cons, nograph
esttab using table_bias1_noUSA.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
*within and between-study variation (be, fe, re) 
eststo: xtreg pcc_w se_pcc_w if usa==0, be
eststo: xtreg pcc_w se_pcc_w if usa==0, fe vce(cluster idstudy)
eststo: xtreg pcc_w se_pcc_w if usa==0, re
esttab using table_bias2_noUSA.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


***************************************************************************************
* PUBLICATION BIAS - Stem-based method in R (Furukawa, 2019)
***************************************************************************************
/*
source("stem_method.R") #github.com/Chishio318/stem-based_method
datastudents = read.table("clipboard-512", sep="\t", header=TRUE)
stem_results = stem(datastudents$pcc_w, datastudents$se_pcc_w, param)
stem_results = stem(datastudents$estimate, datastudents$se_estimate, param)
stem_results[["estimates"]]
*/
***************************************************************************************
* PUBLICATION BIAS - WAAP (Ioannidis et al., 2017) 
***************************************************************************************
summarize pcc_w [aweight=precision_w*precision_w] 
gen waapbound = abs(r(mean))/2.8
reg tstat precision_w if se_pcc < waapbound, noconstant

*summarize pcc_w [aweight=precision_w*precision_w] if usa==0
*gen waapbound_nUSA = abs(r(mean))/2.8
*reg tstat precision_w if se_pcc < waapbound_nUSA & usa==0, noconstant

*summarize pcc_w [aweight=precision_w*precision_w] if endogeneity_control==0
*gen waapbound_nec = abs(r(mean))/2.8
*reg tstat precision_w if se_pcc < waapbound_nec & endogeneity_control==0, noconstant

*summarize pcc_w [aweight=precision_w*precision_w] if endogeneity_control==1
*gen waapbound_ec = abs(r(mean))/2.8
*reg tstat precision_w if se_pcc < waapbound_ec & endogeneity_control==1, noconstant

*drop if homogeneous_subsample==0
*gen precisione=1/se_estimate
*summarize estimate [aweight=precisione*precisione] 
*gen waapbound = abs(r(mean))/2.8
*reg tstat precisione if estimate < waapbound, noconstant

*drop if homogeneous_subsample==0|endogeneity_control==0
*gen precisione=1/se_estimate
*summarize estimate [aweight=precisione*precisione] 
*gen waapbound = abs(r(mean))/2.8
*reg tstat precisione if estimate < waapbound, noconstant

***************************************************************************************
* PUBLICATION BIAS - Endogenous kink (Bom & Rachinger, 2020)
*      code downloaded from https://sites.google.com/site/heikorachinger/codes 
***************************************************************************************
*drop if endogeneity_control==0
*drop if homogeneous_subsample==0 
*drop if usa==1

quietly{
*clear 
*import excel "data_differences_win.xlsx", sheet("differences") firstrow
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
winsor pcc, generate(pcc_w) p(0.01)
winsor se_pcc, generate(se_pcc_w) p(0.01)
sum pcc_w se_pcc_w


*drop if homogeneous_subsample==0
*drop if homogeneous_subsample==0|endogeneity_control==0
/* quietly{
rename estimate bs
rename se_estimate sebs
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

********************************************************************************
* Publication bias - p-uniform* (van Aert & van Assen, 2020) - code for Stata & R
********************************************************************************
*generate data for p-uniform*
*drop if endogeneity_control==0/1
*drop if homogeneous_subsample==0
*drop if homogeneous_subsample==0|endogeneity_control==0

bysort idstudy: egen pccmed = median(pcc)
bysort idstudy: egen pccmedw = median(pcc_w)
bysort idstudy: egen semed = median(se_pcc)
bysort idstudy: egen semedw = median(se_pcc_w)
bysort idstudy: egen tmed = median(tstat)
bysort idstudy: egen tmedw = median(tstat_w)
gen variancemed = semed*semed
gen variancemedw = semedw*semedw

preserve
collapse (lastnm) pcc_med=pccmed pcc_medw=pccmedw variance_med=variancemed variance_medw=variancemedw tstat_med=tmed tstat_medw=tmedw (p50) nobs_med=sample_size_full_w, by(idstudy)
save "puniform.dta", replace
restore


*******************************

*drop if homogeneous_subsample==0|endogeneity_control==0
*bysort idstudy: egen seestmed = median(se_estimate)
*bysort idstudy: egen estmed = median(estimate)
*bysort idstudy: egen tmed = median(tstat)
*gen varianceestmed = seestmed*seestmed

*preserve
*collapse (lastnm) se_estimate_med=seestmed estimate_med=estmed variance_est_med=varianceestmed tstat_med=tmed (p50) nobs_med=sample_size_full, by(idstudy)
*save "puniform.dta", replace
*restore

*******************************

*drop if homogeneous_subsample==0
*gen variance = se_estimate*se_estimate
*bysort idstudy: egen variancemed = median(variance)
*bysort idstudy: egen estimatemed = median(estimate)
*preserve
*collapse (lastnm) variancemed estimatemed (p50), by(idstudy)
*keep estimate variance
*save "puniform_elasticity.dta", replace
*restore

/* on median values
library(puniform)
library(metafor)
library(dmetar)
library(haven)
library(tidyverse)
library(meta)

data <- read_dta("puniform.dta")
puni_star(yi = data$pcc_med, vi = data$variance_med, side="left", method="P",alpha = 0.05, control=list(tol=0.1,reps=10000, int=c(0,2), verbose=TRUE))
puni_star(yi = data$estimate_med, vi = data$variance_est_med, side="left", method="P",alpha = 0.05, control=list(tol=0.1,reps=10000, int=c(0,2), verbose=TRUE))
*/
 
***************************************************************************************
 
***************************************************************************************
* HETEROGENEITY - Exporting data
***************************************************************************************

***************************************************************************************
export excel using "data_all.xlsx", sheet("unweighted") firstrow(variables) replace
clear

*all unweighted (full sample)
import excel data_all.xlsx, sheet("unweighted") firstrow
collin pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method panel_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study
correlate pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method panel_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study
keep pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method panel_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study
order pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method panel_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study
export excel using "data_full.xlsx", sheet("unweighted") firstrow(variables) replace
clear


*all weighted by sqrt(inv_nest) (full sample)
*import excel data_all.xlsx, sheet("unweighted") firstrow
*local data_nest "pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students secondary_education low_intensity_employment high_intensity_employment usa europe ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study" 
*foreach var of varlist `data_nest' {
*				replace `var' = `var' * sqrt(inv_nest)
*}
*collin pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study
*correlate pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study
*keep pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study
*order pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study
*export excel using "data_full_nest.xlsx", sheet("weighted_n") firstrow(variables) replace
*clear


*all weighted by sqrt(precision_w) (full sample)
*import excel data_all.xlsx, sheet("unweighted") firstrow
*local data_se "pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students secondary_education low_intensity_employment high_intensity_employment usa europe ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study" 
*foreach var of varlist `data_se' {
*				replace `var' = `var' * sqrt(precision_w)
*}
*collin pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study
*correlate pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study
*keep pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study
*order pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study
*export excel using "data_full_se.xlsx", sheet("weighted_se") firstrow(variables) replace
*clear

*import excel data_usa.xlsx, sheet("unweighted") firstrow 
***************************************************************************************
***************************************************************************************
* HETEROGENEITY - OLS
***************************************************************************************
***************************************************************************************
import excel data_all.xlsx, sheet("unweighted") firstrow
ivreg2 pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study, cluster(idstudy)
stepwise, pr(.05): regress pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study, cluster(idstudy)
ivreg2 pcc_w se_no_endogeneity_control employment_continuous education_choice longitudinal_data parttime_students low_intensity_employment high_intensity_employment usa germany ols_method ability_control motivation_control ethnicity_control, cluster(idstudy)
ivreg2 pcc_w se_no_endogeneity_control employment_continuous education_choice longitudinal_data low_intensity_employment high_intensity_employment germany ols_method ability_control motivation_control ethnicity_control, cluster(idstudy)

**************************************************************************************
***************************************************************************************
* HETEROGENEITY - BAYEASIAN MODEL AVERAGING ////CODE for R////
***************************************************************************************
***************************************************************************************
/*
library(BMS)
    *ctrl+C from students.xlsx, sheet("data.r")
datastudents = read.table("clipboard-512", sep="\t", header=TRUE)
students0 = bms(datastudents, burn=1e5,iter=3e5, g="UIP", mprior="uniform", nmodel=50000, mcmc="bd", user.int=FALSE)
students = bms(datastudents, burn=1e5,iter=3e5, g="UIP", mprior="dilut", nmodel=50000, mcmc="bd", user.int=FALSE)
students1 = bms(datastudents, burn=1e5,iter=3e5, g="BRIC", mprior="random", nmodel=50000, mcmc="bd", user.int=FALSE)
coef(students, order.by.pip = F, exact=T, include.constant=T)
image(students, yprop2pip=FALSE, order.by.pip=TRUE, do.par=TRUE, do.grid=TRUE, do.axis=TRUE, cex.axis = 0.7)
summary(students)
plot(students)
print(students$topmod[1])


par(mfrow=c(5,2))
density(students, reg="se_no_endogeneity_control")
density(students, reg="ols_method")
density(students, reg="germany")
density(students, reg="longitudinal_data")
density(students, reg="education_choice")
density(students, reg="employment_continuous")
density(students, reg="low_intensity_employment")
density(students, reg="high_intensity_employment")
density(students, reg="ability_control")
density(students, reg="ethnicity_control")

*drop <- c("data_year") 

library(corrplot)
datastudents = read.table("clipboard-512", sep="\t", header=TRUE)
col<- colorRampPalette(c("red", "white", "blue"))
M <- cor(datastudents)
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
library(LowRankQP)
datastudents=read.table("clipboard-512", sep="\t", header=TRUE)
datastudents <-na.omit(datastudents)
x.data <- datastudents[,-1]
const_<-c(1)
x.data <-cbind(const_,x.data)

x <- sapply(1:ncol(x.data),function(i){x.data[,i]/max(x.data[,i])})   
scale.vector <- as.matrix(sapply(1:ncol(x.data),function(i){max(x.data[,i])}))        
Y <- as.matrix(datastudents[,1])
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
names <- c(colnames(datastudents))
names <- c(names,"const_")
MMA.fls <- MMA.fls[match(names, MMA.fls$names),]
MMA.fls$names <- NULL
MMA.fls
*/
***************************************************************************************
***************************************************************************************
* BEST-PRACTICE (SE calculation to BMA estimate)
***************************************************************************************
***************************************************************************************
clear
import excel data_all.xlsx, sheet("unweighted") firstrow

summarize data_year, detail
summarize number_of_variables, detail
summarize impact_factor, detail
summarize citations, detail

local variables se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study
foreach x of varlist `variables' {
sum  `x' 
local m`x' = r(mean)
local min`x' =r(min)
local max`x' =r(max)
}

*Overall


ivreg2 pcc_w se_pcc_w se_no_endogeneity_control employment_continuous employment_dummy education_choice education_attainment selfreported_education longitudinal_data data_year male_students female_students caucasian_students minority_students parttime_students secondary_education low_intensity_employment high_intensity_employment usa germany ols_method matching_method did_method iv_method number_of_variables ability_control motivation_control parental_education_control age_control ethnicity_control impact_factor citations published_study, cluster(idstudy)
lincom _cons+se_pcc_w*0+se_no_endogeneity_control*0+employment_continuous*1+employment_dummy*0+education_choice*`meducation_choice'+education_attainment*`meducation_attainment'+selfreported_education*0+longitudinal_data*1+data_year*`maxdata_year'+male_students*`mmale_students'+female_students*`mfemale_students'+caucasian_students*`mcaucasian_students'+minority_students*`mminority_students'+parttime_students*`mparttime_students'+secondary_education*`msecondary_education'+low_intensity_employment*`mlow_intensity_employment'+high_intensity_employment*`mhigh_intensity_employment'+usa*`musa'+germany*`mgermany'+ols_method*0+matching_method*0+did_method*0+iv_method*1+number_of_variables*`maxnumber_of_variables'+ability_control*1+motivation_control*1+parental_education_control*1+age_control*1+ethnicity_control*1+impact_factor*`maximpact_factor'+citations*`maxcitations'+published_study*`maxpublished_study'
*United States
lincom _cons+se_pcc_w*0+se_no_endogeneity_control*0+employment_continuous*1+employment_dummy*0+education_choice*`meducation_choice'+education_attainment*`meducation_attainment'+selfreported_education*0+longitudinal_data*1+data_year*`maxdata_year'+male_students*`mmale_students'+female_students*`mfemale_students'+caucasian_students*`mcaucasian_students'+minority_students*`mminority_students'+parttime_students*`mparttime_students'+secondary_education*`msecondary_education'+low_intensity_employment*`mlow_intensity_employment'+high_intensity_employment*`mhigh_intensity_employment'+usa*1+germany*0+ols_method*0+matching_method*0+did_method*0+iv_method*1+number_of_variables*`maxnumber_of_variables'+ability_control*1+motivation_control*1+parental_education_control*1+age_control*1+ethnicity_control*1+impact_factor*`maximpact_factor'+citations*`maxcitations'+published_study*`maxpublished_study'
*Germany
lincom _cons+se_pcc_w*0+se_no_endogeneity_control*0+employment_continuous*1+employment_dummy*0+education_choice*`meducation_choice'+education_attainment*`meducation_attainment'+selfreported_education*0+longitudinal_data*1+data_year*`maxdata_year'+male_students*`mmale_students'+female_students*`mfemale_students'+caucasian_students*`mcaucasian_students'+minority_students*`mminority_students'+parttime_students*`mparttime_students'+secondary_education*`msecondary_education'+low_intensity_employment*`mlow_intensity_employment'+high_intensity_employment*`mhigh_intensity_employment'+usa*0+germany*1+ols_method*0+matching_method*0+did_method*0+iv_method*1+number_of_variables*`maxnumber_of_variables'+ability_control*1+motivation_control*1+parental_education_control*1+age_control*1+ethnicity_control*1+impact_factor*`maximpact_factor'+citations*`maxcitations'+published_study*`maxpublished_study'
*Other countries
lincom _cons+se_pcc_w*0+se_no_endogeneity_control*0+employment_continuous*1+employment_dummy*0+education_choice*`meducation_choice'+education_attainment*`meducation_attainment'+selfreported_education*0+longitudinal_data*1+data_year*`maxdata_year'+male_students*`mmale_students'+female_students*`mfemale_students'+caucasian_students*`mcaucasian_students'+minority_students*`mminority_students'+parttime_students*`mparttime_students'+secondary_education*`msecondary_education'+low_intensity_employment*`mlow_intensity_employment'+high_intensity_employment*`mhigh_intensity_employment'+usa*0+germany*0+ols_method*0+matching_method*0+did_method*0+iv_method*1+number_of_variables*`maxnumber_of_variables'+ability_control*1+motivation_control*1+parental_education_control*1+age_control*1+ethnicity_control*1+impact_factor*`maximpact_factor'+citations*`maxcitations'+published_study*`maxpublished_study'
*Male students
lincom _cons+se_pcc_w*0+se_no_endogeneity_control*0+employment_continuous*1+employment_dummy*0+education_choice*`meducation_choice'+education_attainment*`meducation_attainment'+selfreported_education*0+longitudinal_data*1+data_year*`maxdata_year'+male_students*1+female_students*0+caucasian_students*`mcaucasian_students'+minority_students*`mminority_students'+parttime_students*`mparttime_students'+secondary_education*`msecondary_education'+low_intensity_employment*`mlow_intensity_employment'+high_intensity_employment*`mhigh_intensity_employment'+usa*`musa'+germany*`mgermany'+ols_method*0+matching_method*0+did_method*0+iv_method*1+number_of_variables*`maxnumber_of_variables'+ability_control*1+motivation_control*1+parental_education_control*1+age_control*1+ethnicity_control*1+impact_factor*`maximpact_factor'+citations*`maxcitations'+published_study*`maxpublished_study'
*Female students
lincom _cons+se_pcc_w*0+se_no_endogeneity_control*0+employment_continuous*1+employment_dummy*0+education_choice*`meducation_choice'+education_attainment*`meducation_attainment'+selfreported_education*0+longitudinal_data*1+data_year*`maxdata_year'+male_students*0+female_students*1+caucasian_students*`mcaucasian_students'+minority_students*`mminority_students'+parttime_students*`mparttime_students'+secondary_education*`msecondary_education'+low_intensity_employment*`mlow_intensity_employment'+high_intensity_employment*`mhigh_intensity_employment'+usa*`musa'+germany*`mgermany'+ols_method*0+matching_method*0+did_method*0+iv_method*1+number_of_variables*`maxnumber_of_variables'+ability_control*1+motivation_control*1+parental_education_control*1+age_control*1+ethnicity_control*1+impact_factor*`maximpact_factor'+citations*`maxcitations'+published_study*`maxpublished_study'
*Part-time students
lincom _cons+se_pcc_w*0+se_no_endogeneity_control*0+employment_continuous*1+employment_dummy*0+education_choice*`meducation_choice'+education_attainment*`meducation_attainment'+selfreported_education*0+longitudinal_data*1+data_year*`maxdata_year'+male_students*`mmale_students'+female_students*`mfemale_students'+caucasian_students*`mcaucasian_students'+minority_students*`mminority_students'+parttime_students*1+secondary_education*`msecondary_education'+low_intensity_employment*`mlow_intensity_employment'+high_intensity_employment*`mhigh_intensity_employment'+usa*`musa'+germany*`mgermany'+ols_method*0+matching_method*0+did_method*0+iv_method*1+number_of_variables*`maxnumber_of_variables'+ability_control*1+motivation_control*1+parental_education_control*1+age_control*1+ethnicity_control*1+impact_factor*`maximpact_factor'+citations*`maxcitations'+published_study*`maxpublished_study'
*Low-intensity employmnet
lincom _cons+se_pcc_w*0+se_no_endogeneity_control*0+employment_continuous*1+employment_dummy*0+education_choice*`meducation_choice'+education_attainment*`meducation_attainment'+selfreported_education*0+longitudinal_data*1+data_year*`maxdata_year'+male_students*`mmale_students'+female_students*`mfemale_students'+caucasian_students*`mcaucasian_students'+minority_students*`mminority_students'+parttime_students*`mparttime_students'+secondary_education*`msecondary_education'+low_intensity_employment*1+high_intensity_employment*0+usa*`musa'+germany*`mgermany'+ols_method*0+matching_method*0+did_method*0+iv_method*1+number_of_variables*`maxnumber_of_variables'+ability_control*1+motivation_control*1+parental_education_control*1+age_control*1+ethnicity_control*1+impact_factor*`maximpact_factor'+citations*`maxcitations'+published_study*`maxpublished_study'
*High-intensity employmnet
lincom _cons+se_pcc_w*0+se_no_endogeneity_control*0+employment_continuous*1+employment_dummy*0+education_choice*`meducation_choice'+education_attainment*`meducation_attainment'+selfreported_education*0+longitudinal_data*1+data_year*`maxdata_year'+male_students*`mmale_students'+female_students*`mfemale_students'+caucasian_students*`mcaucasian_students'+minority_students*`mminority_students'+parttime_students*`mparttime_students'+secondary_education*`msecondary_education'+low_intensity_employment*0+high_intensity_employment*1+usa*`musa'+germany*`mgermany'+ols_method*0+matching_method*0+did_method*0+iv_method*1+number_of_variables*`maxnumber_of_variables'+ability_control*1+motivation_control*1+parental_education_control*1+age_control*1+ethnicity_control*1+impact_factor*`maximpact_factor'+citations*`maxcitations'+published_study*`maxpublished_study'
*Education outcome: choices
lincom _cons+se_pcc_w*0+se_no_endogeneity_control*0+employment_continuous*1+employment_dummy*0+education_choice*1+education_attainment*0+selfreported_education*0+longitudinal_data*1+data_year*`maxdata_year'+male_students*`mmale_students'+female_students*`mfemale_students'+caucasian_students*`mcaucasian_students'+minority_students*`mminority_students'+parttime_students*`mparttime_students'+secondary_education*`msecondary_education'+low_intensity_employment*`mlow_intensity_employment'+high_intensity_employment*`mhigh_intensity_employment'+usa*`musa'+germany*`mgermany'+ols_method*0+matching_method*0+did_method*0+iv_method*1+number_of_variables*`maxnumber_of_variables'+ability_control*1+motivation_control*1+parental_education_control*1+age_control*1+ethnicity_control*1+impact_factor*`maximpact_factor'+citations*`maxcitations'+published_study*`maxpublished_study'
*Education outcome: attainment
lincom _cons+se_pcc_w*0+se_no_endogeneity_control*0+employment_continuous*1+employment_dummy*0+education_choice*0+education_attainment*1+selfreported_education*0+longitudinal_data*1+data_year*`maxdata_year'+male_students*`mmale_students'+female_students*`mfemale_students'+caucasian_students*`mcaucasian_students'+minority_students*`mminority_students'+parttime_students*`mparttime_students'+secondary_education*`msecondary_education'+low_intensity_employment*`mlow_intensity_employment'+high_intensity_employment*`mhigh_intensity_employment'+usa*`musa'+germany*`mgermany'+ols_method*0+matching_method*0+did_method*0+iv_method*1+number_of_variables*`maxnumber_of_variables'+ability_control*1+motivation_control*1+parental_education_control*1+age_control*1+ethnicity_control*1+impact_factor*`maximpact_factor'+citations*`maxcitations'+published_study*`maxpublished_study'
*Education outcome: test scores
lincom _cons+se_pcc_w*0+se_no_endogeneity_control*0+employment_continuous*1+employment_dummy*0+education_choice*0+education_attainment*0+selfreported_education*0+longitudinal_data*1+data_year*`maxdata_year'+male_students*`mmale_students'+female_students*`mfemale_students'+caucasian_students*`mcaucasian_students'+minority_students*`mminority_students'+parttime_students*`mparttime_students'+secondary_education*`msecondary_education'+low_intensity_employment*`mlow_intensity_employment'+high_intensity_employment*`mhigh_intensity_employment'+usa*`musa'+germany*`mgermany'+ols_method*0+matching_method*0+did_method*0+iv_method*1+number_of_variables*`maxnumber_of_variables'+ability_control*1+motivation_control*1+parental_education_control*1+age_control*1+ethnicity_control*1+impact_factor*`maximpact_factor'+citations*`maxcitations'+published_study*`maxpublished_study'
*High-intensity employmnet + Education outcome: choices
lincom _cons+se_pcc_w*0+se_no_endogeneity_control*0+employment_continuous*1+employment_dummy*0+education_choice*1+education_attainment*0+selfreported_education*0+longitudinal_data*1+data_year*`maxdata_year'+male_students*`mmale_students'+female_students*`mfemale_students'+caucasian_students*`mcaucasian_students'+minority_students*`mminority_students'+parttime_students*`mparttime_students'+secondary_education*`msecondary_education'+low_intensity_employment*0+high_intensity_employment*1+usa*`musa'+germany*`mgermany'+ols_method*0+matching_method*0+did_method*0+iv_method*1+number_of_variables*`maxnumber_of_variables'+ability_control*1+motivation_control*1+parental_education_control*1+age_control*1+ethnicity_control*1+impact_factor*`maximpact_factor'+citations*`maxcitations'+published_study*`maxpublished_study'

clear


********************************************************************************
********************************************************************************
********************************    REVISION    ********************************
********************************************************************************
********************************************************************************

clear
import excel students.xlsx, sheet("data") firstrow
set more off

drop if education_choice==0|employment_continuous==0
drop if idstudy>69
*number of estimates per study
bysort idstudy: egen nest = count(estimate)
gen inv_nest = 1/nest
*number of observations used to estimate pcc
gen double nobs = sqrt(sample_size_full)
gen inv_nobs = 1/nobs
gen no_endogeneity_control = 0
replace no_endogeneity_control = 1 if endogeneity_control==0
gen precision = 1/se_estimate


*DROPOUT IF EMPLOYMENT = CONTINUOS
*basic linear tests (ols, instrument, study-weighted, precision-weighted)
sum estimate se_estimate, detail
eststo: ivreg2 estimate se_estimate, cluster(idstudy)
boottest se_estimate, nograph
boottest _cons, nograph 
eststo: ivreg2 estimate (se_estimate = inv_nobs)
eststo: ivreg2 estimate se_estimate [pweight=inv_nobs]
boottest se_estimate, nograph
boottest _cons, nograph
eststo: ivreg2 estimate se_estimate [pweight=precision]
boottest se_estimate, nograph
boottest _cons, nograph
esttab using table_bias1_dropout_contl.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
*within and between-study variation (be, fe, re) 
xtset idstudy
eststo: xtreg estimate se_estimate, be
eststo: xtreg estimate se_estimate, fe
eststo: xtreg estimate se_estimate, re
esttab using table_bias2_dropout_cont2.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


*DROPOUT IF EMPLOYMENT = CONTINUOS + ENDOGENEITY CONTROL = 1
*basic linear tests (ols, instrument, study-weighted, precision-weighted)
sum estimate se_estimate, detail
eststo: ivreg2 estimate se_estimate if endogeneity_control==1, cluster(idstudy)
boottest se_estimate, nograph
boottest _cons, nograph 
eststo: ivreg2 estimate (se_estimate = inv_nobs) if endogeneity_control==1
eststo: ivreg2 estimate se_estimate if endogeneity_control==1 [pweight=inv_nobs]
boottest se_estimate, nograph
boottest _cons, nograph
eststo: ivreg2 estimate se_estimate if endogeneity_control==1 [pweight=precision]
boottest se_estimate, nograph
boottest _cons, nograph
esttab using table_bias1_dropout_contlendo.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
*within and between-study variation (be, fe, re) 
xtset idstudy
eststo: xtreg estimate se_estimate if endogeneity_control==1, be
eststo: xtreg estimate se_estimate if endogeneity_control==1, fe
eststo: xtreg estimate se_estimate if endogeneity_control==1, re
esttab using table_bias2_dropout_cont2endo.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


*******************************************************
*******************************************************


clear
import excel students.xlsx, sheet("data") firstrow
set more off

drop if education_choice==0|employment_dummy==0
drop if idstudy>69
*number of estimates per study
bysort idstudy: egen nest = count(estimate)
gen inv_nest = 1/nest
*number of observations used to estimate pcc
gen double nobs = sqrt(sample_size_full)
gen inv_nobs = 1/nobs
gen no_endogeneity_control = 0
replace no_endogeneity_control = 1 if endogeneity_control==0
gen precision = 1/se_estimate


*DROPOUT IF EMPLOYMENT = DUMMY
*basic linear tests (ols, instrument, study-weighted, precision-weighted)
sum estimate se_estimate, detail
eststo: ivreg2 estimate se_estimate, cluster(idstudy)
boottest se_estimate, nograph
boottest _cons, nograph 
eststo: ivreg2 estimate (se_estimate = inv_nobs)
eststo: ivreg2 estimate se_estimate [pweight=inv_nobs]
boottest se_estimate, nograph
boottest _cons, nograph
eststo: ivreg2 estimate se_estimate [pweight=precision]
boottest se_estimate, nograph
boottest _cons, nograph
esttab using table_bias1_dropout_dummyl.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
*within and between-study variation (be, fe, re) 
xtset idstudy
eststo: xtreg estimate se_estimate, be
eststo: xtreg estimate se_estimate, fe
eststo: xtreg estimate se_estimate, re
esttab using table_bias2_dropout_dummy2.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


*DROPOUT IF EMPLOYMENT = DUMMY & ENDOGENEITY CONTROL = 1
*basic linear tests (ols, instrument, study-weighted, precision-weighted)
sum estimate se_estimate, detail
eststo: ivreg2 estimate se_estimate if endogeneity_control==1, cluster(idstudy)
boottest se_estimate, nograph
boottest _cons, nograph 
eststo: ivreg2 estimate (se_estimate = inv_nobs) if endogeneity_control==1
eststo: ivreg2 estimate se_estimate [pweight=inv_nobs] if endogeneity_control==1
boottest se_estimate, nograph
boottest _cons, nograph
eststo: ivreg2 estimate se_estimate [pweight=precision] if endogeneity_control==1
boottest se_estimate, nograph
boottest _cons, nograph
esttab using table_bias1_dropout_dummylendo.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
*within and between-study variation (be, fe, re) 
xtset idstudy
eststo: xtreg estimate se_estimate if endogeneity_control==1, be
eststo: xtreg estimate se_estimate if endogeneity_control==1, fe
eststo: xtreg estimate se_estimate if endogeneity_control==1, re
esttab using table_bias2_dropout_dummy2endo.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


log close


