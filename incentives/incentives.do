/********************************************************************
  
  Title: Replication Script for "Financial Incentives and Performance: 
  A Meta-Analysis of Experiments in Economics"
  Authors: Cala, Havranek, Irsova, Matousek, Luskova, Novak
  Version: 1.3

  Description:
  This script replicates all analyses in the paper 
  "Financial Incentives and Performance: 
  A Meta-Analysis of Experiments in Economics".
  Data and code are available at: https://meta-analysis.cz/incentives/

  System requirements:
  - Stata 17 or later
  - R 4.0 or later (for supplementary analyses)
  - No non-standard hardware required

  Installation:
  - Download the dataset "incentives_data.xlsx" from https://meta-analysis.cz/incentives/
  - Place all files in the same working directory
  - Typical runtime: <2 minutes on a standard laptop

  Demo:
  - Run this file in Stata to load and analyze the Excel dataset
  - The script performs meta-regressions, computes effect-size distributions,
    and estimates heterogeneity and publication bias
  - For specific sections (e.g. BMA),
    follow the comments to temporarily switch to R
  - After running the corresponding R code (included inline or referenced),
    return to Stata to continue

  Instructions for your own data:
  - Replace "incentives_data.xlsx" with your own dataset structured identically
  - Adjust variable names if necessary
  - Ensure your data is accessible both in Stata and R if using R-based methods

  Reproducibility:
  - This Stata script reproduces all quantitative 
    results in the manuscript, including effect-size distributions,
    heterogeneity estimation, and publication bias corrections

  Dependencies:
  - No additional Stata packages required
  - R packages: BMS, corrplot

********************************************************************/
* May 30, 2025
log using incentives.log, replace
import excel incentives_data.xlsx, sheet("data") firstrow
set more off
xtset study_id

***************************************************************************************
* Data preparation
***************************************************************************************
* include only top journals without working papers

drop if include == 2 
drop if bma == 0

winsor2 pcc, suffix(_w) cuts(1 99)
winsor2 se_pcc, suffix(_w) cuts(1 99)
winsor2 n_obs, suffix(_w) cuts(1 99)
gen precision = 1/se_pcc
gen precision_w = 1/se_pcc_w
gen tstat_w = t_adjusted
gen effect_negative=0
gen inv_sample_size = 1/sqrt(observations)
replace effect_negative=1 if effect_positive==0
gen developing_country=0
replace developing_country=1 if developed_country==0
gen other_method2=0
replace other_method2=1 if (mean_method==1 | other_method==1)
gen se_control = se_pcc_w * control_zero

***************************************************************************************
* Summary statistics
***************************************************************************************

sum pcc_w se_pcc_w, detail
sum pcc_w se_pcc_w preferred effect_gpa effect_charity effect_game effect_work effect_positive effect_negative task_app task_napp task_cog task_man perf_quan perf_qual reward_scaled framing_pos framing_neg all_paid reward_own reward_else control_zero control_nonzero mot_alt mot_rec mot_fai mot_mon location_lab location_field crowding_out subject_st subject_emp subject_mix male mid_age data_avgyear developed_country developing_country ols_method logit_method probit_method tobit_method fe_method re_method did_method other_method2 data_cross data_panel impact_factor citations
correlate pcc_w se_pcc_w preferred effect_gpa effect_charity effect_game effect_work effect_positive effect_negative task_app task_napp task_cog task_man perf_quan perf_qual reward_scaled framing_pos framing_neg all_paid reward_own reward_else control_zero  control_nonzero mot_alt mot_rec mot_fai mot_mon location_lab location_field crowding_out subject_st subject_emp subject_mix male mid_age data_avgyear developed_country developing_country ols_method logit_method probit_method tobit_method fe_method re_method did_method other_method2 data_cross data_panel impact_factor citations if bma==1
sum pcc_w se_pcc_w preferred effect_gpa effect_charity effect_game effect_work effect_positive effect_negative task_app task_napp task_cog task_man perf_quan perf_qual reward_scaled framing_pos framing_neg all_paid reward_own reward_else control_zero control_nonzero mot_alt mot_rec mot_fai mot_mon location_lab location_field crowding_out subject_st subject_emp subject_mix male mid_age data_avgyear developed_country developing_country ols_method logit_method probit_method tobit_method fe_method re_method did_method other_method2 data_cross data_panel impact_factor citations if bma==1

mean pcc_w 
mean pcc_w if preferred==1
mean pcc_w if preferred==0
mean pcc_w if effect_gpa==1
mean pcc_w if effect_charity==1
mean pcc_w if effect_game==1 
mean pcc_w if effect_work==1 
mean pcc_w if effect_positive==1 
mean pcc_w if effect_positive==0
mean pcc_w if task_app==1 
mean pcc_w if task_napp==1  
mean pcc_w if task_cog==1  
mean pcc_w if task_man==1
mean pcc_w if perf_quan==1  
mean pcc_w if perf_qual==1  
mean pcc_w if reward_scaled>=0.5
mean pcc_w if reward_scaled<0.5
mean pcc_w if framing_pos==1  
mean pcc_w if framing_neg==1  
mean pcc_w if all_paid==1  
mean pcc_w if reward_own==1  
mean pcc_w if reward_else==1  
mean pcc_w if control_zero==1  
mean pcc_w if control_nonzero==1 
mean pcc_w if mot_alt==1  
mean pcc_w if mot_rec==1  
mean pcc_w if mot_fai==1  
mean pcc_w if mot_mon==1   
mean pcc_w if location_lab==1  
mean pcc_w if location_field==1  
mean pcc_w if crowding_out==1  
mean pcc_w if subject_st==1  
mean pcc_w if subject_emp==1  
mean pcc_w if subject_mix==1  
mean pcc_w if male>0.5
mean pcc_w if male==0.5   
mean pcc_w if male<0.5  
mean pcc_w if developed_country==1  
mean pcc_w if developed_country==0
mean pcc_w if ols_method==1  
mean pcc_w if logit_method==1  
mean pcc_w if probit_method==1  
mean pcc_w if tobit_method==1  
mean pcc_w if fe_method==1  
mean pcc_w if re_method==1  
mean pcc_w if did_method==1  
mean pcc_w if (other_method==1|mean_method==1)
mean pcc_w if data_cross==1  
mean pcc_w if data_panel==1  
mean pcc_w [aweight=weight]
mean pcc_w [aweight=weight] if preferred==1
mean pcc_w [aweight=weight] if preferred==0
mean pcc_w [aweight=weight] if effect_gpa==1
mean pcc_w [aweight=weight] if effect_charity==1
mean pcc_w [aweight=weight] if effect_game==1 
mean pcc_w [aweight=weight] if effect_work==1 
mean pcc_w [aweight=weight] if effect_positive==1 
mean pcc_w [aweight=weight] if effect_positive==0
mean pcc_w [aweight=weight] if task_app==1 
mean pcc_w [aweight=weight] if task_napp==1  
mean pcc_w [aweight=weight] if task_cog==1  
mean pcc_w [aweight=weight] if task_man==1
mean pcc_w [aweight=weight] if perf_quan==1  
mean pcc_w [aweight=weight] if perf_qual==1    
mean pcc_w [aweight=weight] if reward_scaled>=0.5
mean pcc_w [aweight=weight] if reward_scaled<0.5
mean pcc_w [aweight=weight] if framing_pos==1  
mean pcc_w [aweight=weight] if framing_neg==1  
mean pcc_w [aweight=weight] if all_paid==1  
mean pcc_w [aweight=weight] if reward_own==1  
mean pcc_w [aweight=weight] if reward_else==1  
mean pcc_w [aweight=weight] if control_zero==1  
mean pcc_w [aweight=weight] if control_nonzero==1  
mean pcc_w [aweight=weight] if mot_alt==1  
mean pcc_w [aweight=weight] if mot_rec==1  
mean pcc_w [aweight=weight] if mot_fai==1  
mean pcc_w [aweight=weight] if mot_mon==1  
mean pcc_w [aweight=weight] if location_lab==1  
mean pcc_w [aweight=weight] if location_field==1  
mean pcc_w [aweight=weight] if crowding_out==1  
mean pcc_w [aweight=weight] if subject_st==1  
mean pcc_w [aweight=weight] if subject_emp==1  
mean pcc_w [aweight=weight] if subject_mix==1  
mean pcc_w [aweight=weight] if male>0.5
mean pcc_w [aweight=weight] if male==0.5   
mean pcc_w [aweight=weight] if male<0.5  
mean pcc_w [aweight=weight] if developed_country==1  
mean pcc_w [aweight=weight] if developed_country==0
mean pcc_w [aweight=weight] if ols_method==1  
mean pcc_w [aweight=weight] if logit_method==1  
mean pcc_w [aweight=weight] if probit_method==1  
mean pcc_w [aweight=weight] if tobit_method==1  
mean pcc_w [aweight=weight] if fe_method==1  
mean pcc_w [aweight=weight] if re_method==1  
mean pcc_w [aweight=weight] if did_method==1  
mean pcc_w [aweight=weight] if (other_method==1|mean_method==1)
mean pcc_w [aweight=weight] if data_cross==1  
mean pcc_w [aweight=weight] if data_panel==1  

histogram pcc if pcc>-0.4 & pcc<0.6, bin(60) fcolor(gs14) lstyle(thin) frequency xtitle("Partial correlation coefficient") xline(0.051, lcolor(red)) xline(0, lcolor(bluishgray)) xlabel(-0.4 -0.2 0 0.051 0.2 0.4 0.6) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram, replace)
histogram pcc if pcc>-0.4 & pcc<0.6 & preferred==1, bin(60) fcolor(gs14) lstyle(thin) frequency xtitle("Partial correlation coefficient") xline(0.069, lcolor(red)) xline(0, lcolor(bluishgray)) xlabel(-0.4 -0.2 0 0.069 0.2 0.4 0.6) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram_pref, replace)

histogram t_adjusted if t_adjusted<15 & t_adjusted>-15, bin(38) fcolor(gs14) lstyle(thin) frequency xtitle("Reported t-statistics") xline(-1.96 0 1.96, lcolor(red)) xlabel(-5 -1.96 0 1.96 5 10 15) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(caliper, replace)

twoway(hist pcc if ols_method==1 & pcc>-0.4 & pcc<0.6, bin(70) freq fcolor(navy) lcolor(navy) legend(label(1 "Method: OLS")))  (hist pcc if pcc>-0.4 & pcc<0.6 & (probit_method==1 | logit_method==1), bin(60) gap(20) freq lcolor(gs12) fcolor(gs12) legend(label(2 "Method: probit & logit"))), xlabel(-0.4 -0.2 0 0.2 0.4 0.6) legend(ring(0) position(2) bmargin(medium) rows(2) region(lstyle(none))) xtitle("Partial correlation coefficient") xline(0, lcolor(bluishgray)) saving(pattern1, replace)
twoway(hist pcc if pcc>-0.4 & pcc<0.6 & control_zero==1, bin(55) gap(2) freq fcolor(navy) lcolor(navy) legend(label(1 "Control: no incentive"))) (hist pcc if control_nonzero==1 & pcc>-0.4 & pcc<0.6, bin(60) gap(10) freq fcolor(gs12) lcolor(gs12) legend(label(2 "Baseline: some incentive"))), legend(ring(0) position(2) bmargin(medium) rows(2) region(lstyle(none))) xtitle("Partial correlation coefficient") xlabel(-0.4 -0.2 0 0.2 0.4 0.6) xline(0, lcolor(bluishgray)) saving(pattern2, replace)
twoway(hist pcc if developed_country==1 & pcc>-0.4 & pcc<0.6, bin(60) freq fcolor(navy) lcolor(navy) legend(label(1 "Developed country")))(hist pcc if developed_country==0 & pcc>-0.4 & pcc<0.6, bin(60) gap(10) freq fcolor(gs12) lcolor(gs12) legend(label(2 "Developing country"))) , legend(ring(0) position(2) bmargin(medium) rows(2) region(lstyle(none))) xtitle("Partial correlation coefficient") xlabel(-0.4 -0.2 0 0.2 0.4 0.6) xline(0, lcolor(bluishgray)) saving(pattern3, replace)
twoway(hist pcc if location_field==1 & pcc>-0.4 & pcc<0.6, bin(60) gap(10) freq fcolor(gs12) lcolor(gs12) legend(label(1 "Field experiment")))(hist pcc if crowding_out==1 & pcc>-0.4 & pcc<0.6, bin(60) gap(10) freq fcolor(cranberry) lcolor(cranberry) legend(label(2 "Crowding-out theory")))(hist pcc if location_lab==1 & pcc>-0.4 & pcc<0.6, bin(60) freq fcolor(navy) lcolor(navy) legend(label(3 "Laboratory experiment"))) , legend(ring(0) position(2) bmargin(medium) rows(3) region(lstyle(none))) xtitle("Partial correlation coefficient") xlabel(-0.4 -0.2 0 0.2 0.4 0.6) xline(0, lcolor(bluishgray)) saving(pattern4, replace)
twoway(hist pcc if subject_st==1 & pcc>-0.4 & pcc<0.6, bin(60) gap(10) freq fcolor(gs12) lcolor(gs12) legend(label(1 "Subjects: students")))(hist pcc if subject_mix==1 & pcc>-0.4 & pcc<0.6, bin(60) freq fcolor(navy) lcolor(navy) legend(label(2 "Subjects: general population")))(hist pcc if subject_emp==1 & pcc>-0.4 & pcc<0.6, bin(60) gap(10) freq fcolor(cranberry) lcolor(cranberry) legend(label(3 "Subject: employees"))) , legend(ring(0) position(2) bmargin(medium) rows(3) region(lstyle(none))) xtitle("Partial correlation coefficient") xlabel(-0.4 -0.2 0 0.2 0.4 0.6) xline(0, lcolor(bluishgray)) saving(pattern5, replace)
twoway(hist pcc if framing_pos==1 & pcc>-0.4 & pcc<0.6, bin(65) freq fcolor(navy) lcolor(navy) legend(label(1 "Positive framing"))) (hist pcc if framing_neg==1 & pcc>-0.4 & pcc<0.6, bin(40) freq fcolor(cranberry) lcolor(cranberry) legend(label(2 "Negative framing"))), legend(ring(0) position(2) bmargin(medium) rows(2) region(lstyle(none))) xtitle("Partial correlation coefficient") xlabel(-0.4 -0.2 0 0.2 0.4 0.6) xline(0, lcolor(bluishgray)) saving(pattern6, replace)
twoway(kdensity pcc if mot_alt==1 & pcc>-0.4 & pcc<0.6, legend(label(1 "Motivation: altruism")))(kdensity pcc if mot_rec==1 & pcc>-0.4 & pcc<0.6, legend(label(2 "Motivation: reciprocity")))(kdensity pcc if mot_fai==1 & pcc>-0.4 & pcc<0.6, legend(label(3 "Motivation: fairness")))(kdensity pcc if mot_mon==1 & pcc>-0.4 & pcc<0.6, legend(label(4 "Motivation: money"))), legend(ring(0) position(2) bmargin(medium) rows(4) region(lstyle(none))) xtitle("Partial correlation coefficient") ytitle("Kernel density (PCC)") xlabel(-0.4 -0.2 0 0.2 0.4 0.6) xline(0, lcolor(bluishgray)) saving(pattern7, replace)
twoway(kdensity pcc if effect_gpa==1 & pcc>-0.4 & pcc<0.6, legend(label(1 "Effect: grades")))(kdensity pcc if effect_charity==1 & pcc>-0.4 & pcc<0.6, legend(label(2 "Effect: charity")))(kdensity pcc if effect_game==1 & pcc>-0.4 & pcc<0.6, legend(label(3 "Effect: game")))(kdensity pcc if effect_work==1 & pcc>-0.4 & pcc<0.6, legend(label(4 "Effect: work"))), legend(ring(0) position(2) bmargin(medium) rows(4) region(lstyle(none))) xtitle("Partial correlation coefficient") ytitle("Kernel density (PCC)") xlabel(-0.4 -0.2 0 0.2 0.4 0.6) xline(0, lcolor(bluishgray)) saving(pattern8, replace)
 
bysort study_id: egen pcc_med = median(pcc_w)
bysort study_id: egen midyear_med = median(data_year)
graph twoway (scatter pcc_med midyear_med, msize(*1) msymbol(Oh) yline(1, lpattern(dott)) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray))) (lfit pcc_w midyear_med, lcolor(bluishgray) lpattern(dash)), xtitle("Median year of data used by a study") ytitle("Median partial correlation coefficient") legend(off) saving(trend, replace)

graph hbox pcc if pcc>-0.4 & pcc<0.6, over(study,label(grid) sort(midyear_med)) xsize(2.6) ysize(4) scale(0.55) yline(0, lcolor (bluishgray)) box(1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow) mcolor(gs12)) ytitle("Partial correlation coefficient") ylabel(, nogrid) saving(studies, replace) 
graph hbox pcc if pcc>-0.4 & pcc<0.6, over(country,label(grid)) xsize(6) ysize(5) scale(0.8) yline(0, lcolor (bluishgray)) box( 1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow) mcolor(gs12)) ytitle("Partial correlation coefficient") ylabel(, nogrid) saving(countries, replace) 

***************************************************************************************
* PUBLICATION BIAS - Funnel plot (Egger et al., 1997)
***************************************************************************************

sum pcc precision_pcc
*twoway scatter  precision_pcc pcc if pcc>-0.4 & pcc<0.6, ytitle("Precision of the partial correlation coefficient (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Partial correlation coefficient") xline(0, lpattern(solid) lcolor (bluishgray)) xlabel(0 , add) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel, replace)
twoway scatter  precision_pcc pcc if precision_pcc<600 & pcc>-0.4 & pcc<0.6, ytitle("Precision of the partial correlation coefficient (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Partial correlation coefficient") xline(0, lpattern(solid) lcolor (bluishgray)) xlabel(0 , add) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel, replace)
twoway scatter  precision_pcc pcc if precision_pcc<600 & pcc>-0.4 & pcc<0.6 & preferred==1, ytitle("Precision of the partial correlation coefficient (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Partial correlation coefficient") xline(0, lpattern(solid) lcolor (bluishgray)) xlabel(0 , add) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel_pref, replace)

***************************************************************************************
* PUBLICATION BIAS - FAT-PET (Stanley, 2005) for WLS, FE, BE, and IV
***************************************************************************************

xtset study_id

eststo: ivreg2 pcc_w se_pcc_w, cluster(study_id)
  boottest se_pcc_w, nograph
  boottest _cons, nograph 
eststo: xtreg pcc_w se_pcc_w, fe vce(cluster study_id)
  boottest se_pcc_w, nograph
eststo: xtreg pcc_w se_pcc_w, be
eststo: ivreg2 pcc_w se_pcc_w [pweight=weight], cluster (study_id)
  boottest se_pcc_w, nograph
  boottest _cons, nograph
eststo: ivreg2 tstat_w precision_w, cluster (study_id)
  boottest precision_w, nograph
  boottest _cons, nograph
esttab using tab_pcc.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "BE" "Study" "Precision") label
eststo clear

eststo: ivreg2 pcc_w se_pcc_w if preferred==1, cluster(study_id)
  boottest se_pcc_w, nograph
  boottest _cons, nograph 
eststo: xtreg pcc_w se_pcc_w  if preferred==1, fe vce(cluster study_id)
  boottest se_pcc_w, nograph
eststo: xtreg pcc_w se_pcc_w  if preferred==1, be
eststo: ivreg2 pcc_w se_pcc_w [pweight=weight_pref] if preferred==1, cluster (study_id)
  boottest se_pcc_w, nograph
  boottest _cons, nograph
eststo: ivreg2 tstat_w precision_w  if preferred==1, cluster (study_id)
  boottest precision_w, nograph
  boottest _cons, nograph
esttab using tab_pcc_pref.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "BE" "Study" "Precision") label
eststo clear

eststo: ivreg2 pcc se_pcc, cluster(study_id)
  boottest se_pcc, nograph
  boottest _cons, nograph 
eststo: xtreg pcc se_pcc, fe vce(cluster study_id)
  boottest se_pcc, nograph
eststo: xtreg pcc se_pcc, be
eststo: ivreg2 pcc se_pcc [pweight=weight], cluster (study_id)
  boottest se_pcc, nograph
  boottest _cons, nograph
eststo: ivreg2 t_adjusted precision, cluster (study_id)
  boottest precision, nograph
  boottest _cons, nograph
esttab using tab_pcc_unwinsorized.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "BE" "Study" "Precision") label
eststo clear

eststo: ivreg2 pcc_w (se_pcc_w = inv_sample_size), cluster (study_id) first		
			boottest se_pcc_w, nograph
			boottest _cons, nograph
			twostepweakiv 2sls pcc_w (se_pcc_w = inv_sample_size), cluster(study_id)
eststo: ivreg2 pcc (se_pcc = inv_sample_size), cluster (study_id) first		
			boottest se_pcc, nograph
			boottest _cons, nograph
			twostepweakiv 2sls pcc (se_pcc = inv_sample_size), cluster(study_id)
eststo: ivreg2 pcc_w (se_pcc_w = inv_sample_size) if preferred==1, cluster (study_id) first		
			boottest se_pcc_w, nograph
			boottest _cons, nograph
			twostepweakiv 2sls pcc_w (se_pcc_w = inv_sample_size) if preferred==1, cluster(study_id)
esttab using tab_pcc_exogeneity.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("PCC" "PCC unwinsorized" "PCC preferred") label
eststo clear

xtset study_id
eststo: ivreg2 pcc_w se_pcc_w, cluster(study_id)
  boottest se_pcc_w, nograph
  boottest _cons, nograph 
eststo: ivreg2 pcc_w se_pcc_w [pweight=weight], cluster (study_id)
  boottest se_pcc_w, nograph
  boottest _cons, nograph
eststo: xtreg pcc_w se_pcc_w, be
eststo: ivreg2 pcc_w se_pcc_w [pweight=weight_exp], cluster (study_id)
  boottest se_pcc_w, nograph
  boottest _cons, nograph 
xtset experiment_id
eststo: xtreg pcc_w se_pcc_w, be
esttab using tab_experiment.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "Study" "BE Study" "Experiment" "BE Experiment") label
eststo clear

xtset study_id
eststo: ivreg2 pcc_w se_pcc_w if preferred==1, cluster(study_id)
  boottest se_pcc_w, nograph
  boottest _cons, nograph 
eststo: ivreg2 pcc_w se_pcc_w [pweight=weight_pref] if preferred==1, cluster (study_id)
  boottest se_pcc_w, nograph
  boottest _cons, nograph
eststo: xtreg pcc_w se_pcc_w if preferred==1, be
eststo: ivreg2 pcc_w se_pcc_w [pweight=weight_exp_pref] if preferred==1, cluster (study_id)
  boottest se_pcc_w, nograph
  boottest _cons, nograph 
xtset experiment_id
eststo: xtreg pcc_w se_pcc_w if preferred==1, be
esttab using tab_experiment_pref.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "Study" "BE Study" "Experiment" "BE Experiment") label
eststo clear

***************************************************************************************
* PUBLICATION BIAS - TOP10 method (Stanley et al., 2010)
***************************************************************************************

summarize precision_w, detail
gen top10bound = r(p90)
summarize pcc_w precision_w if precision_w > top10bound

summarize precision, detail
gen top10bound_unw = r(p90)
summarize pcc precision if precision > top10bound_unw

summarize precision_w if preferred==1, detail
gen top10bound_pref = r(p90)
summarize pcc_w precision_w if precision_w > top10bound_pref & preferred==1

***************************************************************************************
* PUBLICATION BIAS - WAAP (Ioannidis et al., 2017) 
***************************************************************************************

summarize pcc_w [aweight=1/(se_pcc_w*se_pcc_w)]
gen waapbound = abs(r(mean))/2.8
reg tstat_w precision_w if se_pcc_w < waapbound, noconstant

summarize pcc [aweight=1/(se_pcc*se_pcc)]
gen waapbound_unwin = abs(r(mean))/2.8
reg t_adjusted precision if se_pcc_w < waapbound_unwin, noconstant

summarize pcc_w [aweight=1/(se_pcc_w*se_pcc_w)] if preferred==1
gen waapbound_pref = abs(r(mean))/2.8
reg tstat_w precision_w if se_pcc_w < waapbound_pref & preferred==1, noconstant

***************************************************************************************
* PUBLICATION BIAS - Caliper test (Gerber & Malhotra, 2008)
***************************************************************************************

* caliper for tstat below -1.96 (5%, 10%, 20%)
generate significant = 0
replace significant = 1 if tstat_w < -1.96
reg significant if tstat_w > -2.01 & tstat_w < -1.91
 lincom _cons - 0.5
reg significant if tstat_w > -2.06 & tstat_w < -1.86
 lincom _cons - 0.5
reg significant if tstat_w > -2.11 & tstat_w < -1.81
 lincom _cons - 0.5

*caliper for tstat above 1.96 (5%, 10%, 20%)
generate significant2 = 0
replace significant2 = 1 if tstat_w > 1.96
reg significant2 if tstat_w < 2.01 & tstat_w > 1.91 
 lincom _cons - 0.5
reg significant2 if tstat_w < 2.06 & tstat_w > 1.86
 lincom _cons - 0.5
reg significant2 if tstat_w < 2.11 & tstat_w > 1.81 
 lincom _cons - 0.5

*caliper for positive estimates
generate positive = 0
replace positive = 1 if tstat_w > 0 
reg positive if tstat_w > -0.05 & tstat_w < 0.05
 lincom _cons - 0.5
reg positive if tstat_w > -0.10 & tstat_w < 0.10
 lincom _cons - 0.5
reg positive if tstat_w > -0.15 & tstat_w < 0.15
 lincom _cons - 0.5

***************************************************************************************
* PUBLICATION BIAS - Endogenous kink (Bom & Rachinger, 2020)
*   code downloaded from https://sites.google.com/site/heikorachinger/codes 
***************************************************************************************

/*
drop if preferred==0

quietly{
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
*/

***************************************************************************************
* Publication bias - p-uniform* (van Aert & van Assen, 2020) - on median values 
***************************************************************************************

/* Code for Stata (creating the dataset)
*drop if preferred==0

bysort study_id: egen pcc_av = mean(pcc)
bysort study_id: egen se_av = mean(se_pcc)
bysort study_id: egen t_av = mean(t_adjusted)
gen variance_av = se_av*se_av

bysort study_id: egen pcc_avw = mean(pcc_w)
bysort study_id: egen se_avw = mean(se_pcc_w)
bysort study_id: egen t_avw = mean(tstat_w)
gen variance_avw = se_avw*se_avw

preserve
collapse (lastnm) pcc_av pcc_avw se_av se_avw variance_av variance_avw t_av t_avw (p50) nobs_av==n_obs, by(study_id)
save "puniform_pcc_av.dta", replace
*save "puniform_pcc_av_pref.dta", replace
restore
clear

***************************************************************************************

bysort study_id: egen pcc_med = median(pcc)
bysort study_id: egen se_med = median(se_pcc)
bysort study_id: egen t_med = median(t_adjusted)
gen variance_med = se_med*se_med

bysort study_id: egen pcc_medw = median(pcc_w)
bysort study_id: egen se_medw = median(se_pcc_w)
bysort study_id: egen t_medw = median(tstat_w)
gen variance_medw = se_medw*se_medw

preserve
collapse (lastnm) pcc_med pcc_medw se_med se_medw variance_med variance_medw t_med t_medw (p50) nobs_med=n_obs, by(study_id)
save "puniform_pcc.dta", replace
*save "puniform_pcc_pref.dta", replace
restore
clear
*/

/* Code for R (testing for publication bias)
library(puniform)
library(metafor)
library(dmetar)
library(haven)
library(tidyverse)
library(meta)

data <- read_dta("puniform_pcc.dta")
data <- read_dta("puniform_pcc_pref.dta")
data = read.table("clipboard-512", sep="\t", header=TRUE)

puni_star(yi = data$pcc_med, vi = data$variance_med, side="right", method="ML",alpha = 0.05)
#puni_star(yi = data$pcc_medw, vi = data$variance_medw, side="right", method="ML",alpha = 0.05)
puniform(yi = data$pcc_med, vi = data$variance_med, side="right", method="ML",alpha = 0.05)
#puniform(yi = data$pcc_medw, vi = data$variance_medw, side="right", method="ML",alpha = 0.05)
*/

***************************************************************************************
* PUBLICATION BIAS - Stem-based method in R (Furukawa, 2019) - on median values
***************************************************************************************

/*
source("stem_method.R") #github.com/Chishio318/stem-based_method
dataincentives = read.table("clipboard-512", sep="\t", header=TRUE)
stem_results = stem(dataincentives$pcc_med, dataincentives$se_med, param)
stem_results = stem(dataincentives$pcc_medw, dataincentives$se_medw, param)
stem_results[["estimates"]]
*/

***************************************************************************************
* PUBLICATION BIAS - Andrews & Kasy (2019) and Kranz & Putz(2022) in R
***************************************************************************************

/*
# save csv in "pcc" "standard error" format to default folder (Libraries\Documents)
# https://github.com/skranz/MetaStudies#testing-the-independence-assumption-of-andrews-and-kasy-2019
# https://github.com/maxkasy/MetaStudiesApp

options(repos = c(skranz = 'https://skranz.r-universe.dev',
CRAN = 'https://cloud.r-project.org'))
install.packages('MetaStudies')
library(MetaStudies)

dataincentives = read.table("clipboard-512", sep="\t", header=FALSE)
dataincentives= read.csv("data.csv", header = FALSE)
colnames(dataincentives) = c("X","sigma")
# perform A&K test
ms = metastudies_estimation(X=dataincentives$X,sigma=dataincentives$sigma,model = "t",cutoffs = c(-1.96, 0, 1.96),symmetric = FALSE)
ms$est_tab
# for clustered standard errors use the app from https://maxkasy.github.io/home/code-and-apps/
# check the viability of the test
metastudy_X_sigma_cors(ms)
resl=bootstrap_specification_tests(dataincentives$X, dataincentives$sigma, B = 500)
estimates_plot(ms)
resl
*/

***************************************************************************************
* Publication bias - p-hacking (Elliott et al., 2022) - data preparation
***************************************************************************************

gen t_abs = abs(t_adjusted)
gen ptop = 2*(1 - normal(t_abs))
*drop if se_ppc==.
drop if ptop > 1
gen id = study_id

export delimited using "elliot_pcc.csv", replace
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
* HETEROGENEITY - Data preparation
***************************************************************************************

* generate data for R
/*
local variables pcc_w se_pcc_w preferred se_control effect_gpa effect_charity effect_game effect_work effect_positive task_app task_napp task_cog task_man perf_quan perf_qual reward_scaled framing_pos framing_neg all_paid reward_own reward_else control_zero mot_alt mot_rec mot_fai mot_mon location_lab location_field crowding_out subject_st subject_emp subject_mix male female mid_age data_avgyear developed_country ols_method logit_method probit_method tobit_method fe_method re_method did_method other_method2 data_cross data_panel impact_factor citations
foreach x of varlist `variables' {
gen double w_`x'=`x'*inv_sample_size
}
keep w_*
export excel "incentives_4R_nobs.xlsx", sheet("data") replace first(var)
*/

clear
import excel incentives_data.xlsx, sheet("data") firstrow
set more off
xtset study_id


drop if include == 2 
drop if bma == 0

winsor2 pcc, suffix(_w) cuts(1 99)
winsor2 se_pcc, suffix(_w) cuts(1 99)
winsor2 n_obs, suffix(_w) cuts(1 99)
gen precision = 1/se_pcc
gen precision_w = 1/se_pcc_w
gen tstat_w = t_adjusted
gen effect_negative=0
gen inv_sample_size = 1/sqrt(observations)
replace effect_negative=1 if effect_positive==0
gen developing_country=0
replace developing_country=1 if developed_country==0
gen other_method2=0
replace other_method2=1 if (mean_method==1 | other_method==1)
gen se_control = se_pcc_w * control_zero


correlate pcc_w se_pcc_w preferred se_control effect_gpa effect_charity effect_game effect_positive task_app perf_quan task_cog reward_scaled framing_pos all_paid reward_own control_zero mot_alt mot_rec mot_fai location_lab crowding_out subject_st subject_emp male mid_age data_avgyear developed_country ols_method logit_method probit_method tobit_method fe_method re_method did_method data_cross impact_factor citations
collin pcc_w se_pcc_w preferred se_control effect_gpa effect_charity effect_game effect_positive task_app perf_quan task_cog reward_scaled framing_pos all_paid reward_own control_zero mot_alt mot_rec mot_fai location_lab crowding_out subject_st subject_emp male mid_age data_avgyear developed_country ols_method logit_method probit_method tobit_method fe_method re_method did_method data_cross impact_factor citations

* condition number below 30
collin pcc_w se_pcc_w preferred effect_positive task_app perf_quan task_cog framing_pos control_zero mot_alt location_lab crowding_out male probit_method tobit_method fe_method re_method data_cross
ivreg2 pcc_w se_pcc_w preferred effect_positive task_app perf_quan task_cog framing_pos control_zero mot_alt location_lab crowding_out male probit_method tobit_method fe_method re_method data_cross, cluster(study_id)

keep study_id pcc_w se_pcc_w preferred se_control effect_gpa effect_charity effect_game effect_work effect_positive task_app task_napp task_cog task_man perf_quan perf_qual reward_scaled framing_pos framing_neg all_paid reward_own reward_else control_zero mot_alt mot_rec mot_fai mot_mon location_lab location_field crowding_out subject_st subject_emp subject_mix male female mid_age data_avgyear developed_country ols_method logit_method probit_method tobit_method fe_method re_method did_method other_method2 data_cross data_panel impact_factor citations
order study_id pcc_w se_pcc_w preferred se_control effect_gpa effect_charity effect_game effect_work effect_positive task_app task_napp perf_quan perf_qual task_cog task_man reward_scaled framing_pos framing_neg all_paid reward_own reward_else control_zero mot_alt mot_rec mot_fai mot_mon location_lab location_field crowding_out subject_st subject_emp subject_mix male female mid_age data_avgyear developed_country ols_method logit_method probit_method tobit_method fe_method re_method did_method other_method2 data_cross data_panel impact_factor citations
export excel "incentives_4R.xlsx", sheet("data") replace first(var)

***************************************************************************************
* HETEROGENEITY - Bayesian model averaging ////CODE for R////
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

# ctrl+C from incentives_4R.xlsx
incentives = read.table("clipboard-512", sep="\t", header=TRUE)
colnames(incentives)	<- c("Study ID","PCC", "Standard error", "Preferred estimate", "SE * Control", "Effect: grades", "Effect: charity", "Effect: game", "Effect: work", "Effect: positive", "Task: appealing", "Task: unappealing", "Task: cognitive", "Task: manual", "Performance: quantitative", "Performance: qualitative","Reward size",  "Positive framing", "Negative framing", "All subjects paid", "Individual reward", "Group reward", "Control: no incentive", "Motivation: altruism", "Motivation: reciprocity", "Motivation: fairness", "Motivation: money only", "Laboratory experiment", "Field experiment", "Crowding-out theory", "Subjects: students", "Subjects: employees", "Subjects: general", "Gender: males", "Gender: females", "Subjects' age", "Data year", "Developed country", "Method: OLS", "Method: logit", "Method: probit", "Method: tobit", "Method: fixed-effects", "Method: random-effects", "Method: DID", "Method: Other", "Cross-section","Panel", "Impact factor", "Citations")
data_orig	<- c("PCC", "Standard error", "Preferred estimate", "Effect: grades", "Effect: charity", "Effect: game", "Effect: work", "Effect: positive", "Task: appealing", "Task: unappealing", "Task: cognitive", "Task: manual", "Performance: quantitative", "Performance: qualitative","Reward size",  "Positive framing", "Negative framing", "All subjects paid", "Individual reward", "Group reward", "Control: no incentive", "Motivation: altruism", "Motivation: reciprocity", "Motivation: fairness", "Motivation: money only", "Laboratory experiment", "Field experiment", "Crowding-out theory", "Subjects: students", "Subjects: employees", "Subjects: general", "Gender: males", "Gender: females", "Subjects' age", "Data year", "Developed country", "Method: OLS", "Method: logit", "Method: probit", "Method: tobit", "Method: fixed-effects", "Method: random-effects", "Method: DID", "Method: Other", "Cross-section","Panel", "Impact factor", "Citations")
data_1	<- c("PCC", "Standard error", "Preferred estimate", "Effect: grades", "Effect: charity", "Effect: game", "Effect: positive", "Task: appealing", "Task: cognitive", "Performance: quantitative", "Reward size",  "Positive framing", "All subjects paid", "Individual reward","Control: no incentive", "Motivation: altruism", "Motivation: reciprocity", "Motivation: fairness", "Laboratory experiment", "Crowding-out theory", "Subjects: students", "Subjects: employees", "Gender: males", "Subjects' age", "Data year", "Developed country", "Method: OLS", "Method: logit", "Method: probit", "Method: tobit", "Method: fixed-effects", "Method: random-effects", "Method: DID", "Cross-section","Impact factor", "Citations")
data_df		<- incentives[data_1]

incentives1 = bms(data_df, burn=1e5,iter=3e5, g="UIP", mprior="dilut", nmodel=50000, mcmc="bd", user.int=FALSE)
coef(incentives1, order.by.pip = F, exact=T, include.constant=T)
# pdf("bma_dilut.pdf")
image(incentives1, yprop2pip=FALSE, order.by.pip=TRUE, do.par=TRUE, do.grid=TRUE, do.axis=TRUE, cex.axis = 0.7)
# image(incentives1, cex=0.7, xlab="", main="")
# dev.off()
summary(incentives1)
# pdf("bma_dilut_pmp.pdf")
plot(incentives1)
# dev.off()
print(incentives1$topmod[1])

incentives2 = bms(data_df, burn=1e5,iter=3e5, g="BRIC", mprior="random", nmodel=50000, mcmc="bd", user.int=FALSE)
coef(incentives2, order.by.pip = F, exact=T, include.constant=T)
# pdf("bma_bric.pdf")
image(incentives2, yprop2pip=FALSE, order.by.pip=TRUE, do.par=TRUE, do.grid=TRUE, do.axis=TRUE, cex.axis = 0.7)
# image(incentives2, cex=0.7, xlab="", main="")
# dev.off()
summary(incentives2)
# pdf("bma_bric_pmp.pdf")
plot(incentives2)
# dev.off()
print(incentives2$topmod[1])

par(mfrow=c(4,2))
density(incentives1, reg="Standard error")
density(incentives1, reg="Laboratory experiment")
density(incentives1, reg="Cross-section")
density(incentives1, reg="Task: cognitive")
density(incentives1, reg="Positive framing")
density(incentives1, reg="Gender: males")
density(incentives1, reg="Task: appealing")
density(incentives1, reg="Control: no incentive")

library(corrplot)
col<- colorRampPalette(c("red", "white", "blue"))
M <- cor(data_df)
corrplot.mixed(M, lower = "number", upper = "circle", lower.col=col(200), upper.col=col(200), tl.pos = c("lt"), diag = c("u"), tl.col="black", tl.srt=45, tl.cex=0.85, number.cex = 0.5, cl.cex=0.8, cl.ratio=0.1)
*/

***************************************************************************************
* HETEROGENEITY - Frequentist model averaging (Mallows) with cluster-robust SEs ////CODE for R////
***************************************************************************************

/*
# Required libraries
library(foreign)
library(xtable)
library(LowRankQP)

# Read data from clipboard (copy the data eg from Excel before running this line, with header)
dataincentives <- read.table("clipboard", sep = "\t", header = TRUE)
dataincentives <- na.omit(dataincentives)

# Read cluster IDs from clipboard (copy the column before running this line, no header)
cluster_id <- scan("clipboard")  # Or use: cluster_id <- dataincentives$study_id
# Prepare independent variables
x.data <- dataincentives[,-1]
const_ <- rep(1, nrow(dataincentives))
x.data <- cbind(const_, x.data)
x <- sapply(1:ncol(x.data), function(i) x.data[, i] / max(x.data[, i]))
scale.vector <- as.matrix(sapply(1:ncol(x.data), function(i) max(x.data[, i])))
Y <- as.matrix(dataincentives[, 1])
output.colnames <- colnames(x.data)
# Full model fit
full.fit <- lm(Y ~ x - 1)
beta.full <- as.matrix(coef(full.fit))
M <- k <- ncol(x)
n <- nrow(x)
beta <- matrix(0, k, M)
e <- matrix(0, n, M)
K_vector <- matrix(1:M)
var.matrix <- matrix(0, k, M)
bias.sq <- matrix(0, k, M)
# Cluster-robust vcov (fully safe version)
cluster_vcov <- function(X, e, cluster) {
  cluster <- as.factor(cluster)
  n <- nrow(X)
  k <- ncol(X)
  G <- length(unique(cluster))
  dfc <- G / (G - 1) * (n - 1) / (n - k)  # finite-sample correction
  u <- X * e  # n × k matrix
  cluster_levels <- levels(cluster)
  cluster_sum <- matrix(0, nrow = G, ncol = k)
  for (j in 1:G) {
    cl <- cluster_levels[j]
    cluster_sum[j, ] <- colSums(u[cluster == cl, , drop = FALSE])
  }
  meat <- t(cluster_sum) %*% cluster_sum  # k × k
  bread_inv <- solve(t(X) %*% X)          # k × k
  vcov_cl <- dfc * bread_inv %*% meat %*% bread_inv
  return(vcov_cl)
}
# Model averaging loop
for (i in 1:M) {
  X <- as.matrix(x[, 1:i])
  ortho <- eigen(t(X) %*% X)
  Q <- ortho$vectors
  lambda <- ortho$values
  x.tilda <- X %*% Q %*% diag(lambda^(-0.5), i, i)
  beta.star <- t(x.tilda) %*% Y
  beta.hat <- Q %*% diag(lambda^(-0.5), i, i) %*% beta.star
  beta[1:i, i] <- beta.hat
  e[, i] <- Y - x.tilda %*% beta.star
  bias.sq[, i] <- (beta[, i] - beta.full)^2
  # Clustered SEs
  e_i <- e[, i]
  cl_vcov <- cluster_vcov(X, e_i, cluster_id)
  var.matrix[1:i, i] <- diag(cl_vcov)
  var.matrix[1:i, i] <- var.matrix[1:i, i] + bias.sq[1:i, i]
}
# Model weights via QP
e_k <- e[, M]
sigma_hat <- as.numeric((t(e_k) %*% e_k) / (n - M))
G <- t(e) %*% e
a <- sigma_hat^2 * K_vector
A <- matrix(1, 1, M)
b <- matrix(1, 1, 1)
u <- matrix(1, M, 1)
optim <- LowRankQP(Vmat = G, dvec = a, Amat = A, bvec = b, uvec = u, method = "LU", verbose = FALSE)
weights <- as.matrix(optim$alpha)
# Final estimates
beta.scaled <- beta %*% weights
final.beta <- beta.scaled / scale.vector
std.scaled <- sqrt(var.matrix) %*% weights
final.std <- std.scaled / scale.vector
results.reduced <- cbind(final.beta, final.std)
rownames(results.reduced) <- output.colnames
colnames(results.reduced) <- c("Coefficient", "Sd. Err")
# P-values and formatting
MMA.fls <- round(results.reduced, 4)
MMA.fls <- data.frame(MMA.fls)
t <- MMA.fls$Coefficient / MMA.fls$Sd..Err
MMA.fls$pv <- round((1 - pnorm(abs(t))) * 2, 3)
MMA.fls$names <- rownames(MMA.fls)
# Ensure correct row order
names <- c(colnames(dataincentives), "const_")
MMA.fls <- MMA.fls[match(names, MMA.fls$names), ]
MMA.fls$names <- NULL
# Output results
MMA.fls
*/

***************************************************************************************
* HETEROGENEITY - Robustness check
***************************************************************************************

ivreg2 pcc_w se_pcc_w preferred effect_charity effect_game effect_positive task_app perf_quan task_cog framing_pos reward_own control_zero mot_alt location_lab crowding_out subject_st male ols_method did_method data_cross, cluster(study_id)
collin pcc_w se_pcc_w preferred effect_charity effect_game effect_positive task_app perf_quan task_cog framing_pos reward_own control_zero mot_alt location_lab crowding_out subject_st male ols_method did_method data_cross

***************************************************************************************
* BEST-PRACTICE (SE calculation to BMA estimate)
***************************************************************************************

*Overall
*ivreg2 pcc_w se_pcc_w effect_gpa effect_charity effect_game  effect_positive task_app perf_quan  task_cog  reward_scaled framing_pos all_paid reward_own  mot_alt mot_rec  mot_fai location_lab  crowding_out subject_st subject_emp male mid_age data_avgyear developed_country  ols_method logit_method probit_method tobit_method fe_method re_method did_method  data_cross impact_factor citations, cluster(study_id)
ivreg2 pcc_w se_pcc_w preferred effect_gpa effect_charity effect_game effect_positive task_app perf_quan task_cog reward_scaled framing_pos all_paid reward_own control_zero mot_alt mot_rec mot_fai location_lab crowding_out subject_st subject_emp male mid_age data_avgyear developed_country ols_method logit_method probit_method tobit_method fe_method re_method did_method data_cross impact_factor citations, cluster(study_id)
ridgereg pcc_w se_pcc_w preferred effect_gpa effect_charity effect_game effect_positive	task_app perf_quan task_cog reward_scaled framing_pos all_paid reward_own control_zero mot_alt mot_rec mot_fai location_lab crowding_out subject_st subject_emp male mid_age data_avgyear developed_country ols_method logit_method probit_method tobit_method fe_method re_method did_method data_cross impact_factor citations, ridge(1)
cvlasso pcc_w se_pcc_w preferred effect_gpa effect_charity effect_game effect_positive task_app perf_quan task_cog reward_scaled framing_pos all_paid reward_own control_zero mot_alt mot_rec mot_fai location_lab crowding_out subject_st subject_emp male mid_age data_avgyear developed_country ols_method logit_method probit_method tobit_method fe_method re_method did_method data_cross impact_factor citations, cluster(study_id) rlasso

lincom _cons+se_pcc*0+effect_gpa*0.33290816+effect_charity*0.28125+effect_game*0.27742347+effect_positive*0.86862245+ols_method*0.57079082+logit_method*0.04783163+probit_method*0.08992347+tobit_method*0.03061224+fe_method*0.03890306+re_method*0.02806122+diff_method*0.02742347+cross_control*0+data_avgyear*7+lab_control*0.23341837+crowding_out*0.48788265+journal_impact*5.48694611+study_citations*8.08425410+pos_framing_control*0.830995+reward_scaled*0.599097+all_paid*0.74107143+reward_own_control*1+perf_quan_control*0.70216837+task_cog_control*0.70535714+task_app*0.49170918+mot_alt*0.29081633+mot_rec*0.10267857+mot_fai*0.15114796+subject_st*0.61033163+subject_emp*0.07206633+gender_control*0.52817484+mid_age*2.93128481+developed_country*0.83545918

set more off
local variables pcc_w se_pcc_w preferred effect_gpa effect_charity effect_game effect_positive task_app perf_quan task_cog reward_scaled framing_pos all_paid reward_own control_zero mot_alt mot_rec mot_fai location_lab crowding_out subject_st subject_emp male mid_age data_avgyear developed_country ols_method logit_method probit_method tobit_method fe_method re_method did_method data_cross impact_factor citations
foreach x of varlist `variables' {
sum  `x' 
local m`x' =r(mean)  
local min`x' =r(min)
local max`x' =r(max)
}
ivreg2 pcc_w se_pcc_w preferred effect_gpa effect_charity effect_game effect_positive task_app perf_quan task_cog reward_scaled framing_pos all_paid reward_own control_zero mot_alt mot_rec mot_fai location_lab crowding_out subject_st subject_emp male mid_age data_avgyear developed_country ols_method logit_method probit_method tobit_method fe_method re_method did_method data_cross impact_factor citations, cluster(study_id)
*Overall
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Effect: grades
lincom _cons+se_pcc*0+preferred*1+effect_gpa*1+effect_charity*0+effect_game*0+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Effect: charity
lincom _cons+se_pcc*0+preferred*1+effect_gpa*0+effect_charity*1+effect_game*0+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Effect: game
lincom _cons+se_pcc*0+preferred*1+effect_gpa*0+effect_charity*0+effect_game*1+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Task: appealing
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*1+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Task: unappealing
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*0+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Task: cognitive
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*1+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Task: manual
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*0+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Performance: quantitative
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*1+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Performance: qualitative
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*0+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Positive framing
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*1+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Negative framing
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*0+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Laboratory experiment
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*1+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Field experiment
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*0+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Subjects: students
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*1+subject_emp*0+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Subjects: employees
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*0+subject_emp*1+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Subjects: mixed
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*`mreward_own'+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*0+subject_emp*1+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Individual reward
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*1+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Group reward
lincom _cons+se_pcc*0+preferred*1+effect_gpa*`meffect_gpa'+effect_charity*`meffect_charity'+effect_game*`meffect_game'+effect_positive*`meffect_positive'+task_app*`mtask_app'+perf_quan*`perf_quan'+task_cog*`mtask_cog'+reward_scaled*`mreward_scaled'+framing_pos*`mframing_pos'+all_paid*`mall_paid'+reward_own*0+control_zero*`mcontrol_zero'+mot_alt*`mmot_alt'+mot_rec*`mmot_rec'+mot_fai*`mmot_fai'+location_lab*`mlocation_lab'+crowding_out*`mcrowding_out'+subject_st*`msubject_st'+subject_emp*`msubject_emp'+male*`mmale'+mid_age*`mmid_age'+data_avgyear*`maxdata_avgyear'+developed_country*`mdeveloped_country'+ols_method*`mols_method'+logit_method*`mlogit_method'+probit_method*`mprobit_method'+tobit_method*`mtobit_method'+fe_method*`mfe_method'+re_method*`mre_method'+did_method*`mdid_method'+data_cross*`mdata_cross'+impact_factor*`maximpact_factor'+citations*`maxcitations'
*Takahashi et al. (2016)
lincom _cons+se_pcc*0+preferred*1+effect_gpa*0+effect_charity*0+effect_game*1+effect_positive*0+task_app*1+perf_quan*1+task_cog*1+reward_scaled*0.202+framing_pos*1+all_paid*0+reward_own*1+control_zero*1+mot_alt*0+mot_rec*0+mot_fai*0+location_lab*1+crowding_out*1+subject_st*1+subject_emp*0+male*0.5+mid_age*2.996+data_avgyear*7.607+developed_country*1+ols_method*0+logit_method*0+probit_method*0+tobit_method*1+fe_method*0+re_method*0+did_method*0+data_cross*1+impact_factor*1.926+citations*1.386
*Lazear (2000)
lincom _cons+se_pcc*0+preferred*1+effect_gpa*0+effect_charity*0+effect_game*0+effect_positive*1+task_app*0+perf_quan*1+task_cog*0+reward_scaled*0.600+framing_pos*1+all_paid*0+reward_own*1+control_zero*0+mot_alt*0+mot_rec*0+mot_fai*0+location_lab*0+crowding_out*1+subject_st*0+subject_emp*1+male*0.63+mid_age*3.332+data_avgyear*7.598+developed_country*1+ols_method*1+logit_method*0+probit_method*0+tobit_method*0+fe_method*0+re_method*0+did_method*0+data_cross*0+impact_factor*4.367+citations*5.106
*Angrist & Lavy (2009)
lincom _cons+se_pcc*0+preferred*1+effect_gpa*1+effect_charity*0+effect_game*0+effect_positive*1+task_app*0+perf_quan*0+task_cog*1+reward_scaled*1.168+framing_pos*1+all_paid*0+reward_own*1+control_zero*1+mot_alt*0+mot_rec*0+mot_fai*0+location_lab*0+crowding_out*0+subject_st*1+subject_emp*0+male*0.5+mid_age*2.862+data_avgyear*7.601+developed_country*1+ols_method*0.5+logit_method*0.5+probit_method*0+tobit_method*0+fe_method*0+re_method*0+did_method*0+data_cross*1+impact_factor*4.367+citations*3.660
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
* COHENS D DATASET
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************

clear
import excel incentives_data.xlsx, sheet("data") firstrow
set more off
xtset study_id
drop if include == 2

winsor2 cohens_d, suffix(_w) cuts(1 99)
winsor2 se_cohens_d, suffix(_w) cuts(1 99)
winsor2 n_obs, suffix(_w) cuts(1 99)
gen precision_cohens_d = 1/se_cohens_d
gen precision_cohens_d_w = 1/se_cohens_d_w
gen tstat_cohens_d = cohens_d/se_cohens_d
gen tstat_cohens_d_w = cohens_d_w/se_cohens_d_w
gen effect_negative=0
gen inv_sample_size = 1/sqrt(observations)
replace effect_negative=1 if effect_positive==0
gen developing_country=0
replace developing_country=1 if developed_country==0
gen other_method2=0
replace other_method2=1 if (mean_method==1 | other_method==1)


***************************************************************************************
* Summary statistics
***************************************************************************************
sum cohens_d_w se_cohens_d_w, detail

mean cohens_d_w 
mean cohens_d_w if preferred==1
mean cohens_d_w if bma==1
mean cohens_d_w [aweight=weight]
mean cohens_d_w [aweight=weight] if preferred==1
mean cohens_d_w [aweight=weight] if bma==1 
 
histogram cohens_d if cohens_d>-0.6 & cohens_d<1, bin(60) fcolor(gs14) lstyle(thin) frequency xtitle("Cohen's d") xline(0.090, lcolor(red)) xlabel(-0.6 -0.4 -0.2 0 0.090 0.2 0.4 0.6 0.8 1.0) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram_cd, replace)
bysort study_id: egen midyear_med = median(data_year)
graph hbox cohens_d if cohens_d>-0.6 & cohens_d<1, over(study,label(grid) sort(midyear_med)) xsize(2.6) ysize(5) scale(0.7) yline(0, lcolor (bluishgray)) box(1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow) mcolor(gs12)) ytitle("Cohen's d") ylabel(, nogrid) saving(studies_cd, replace) 

histogram t_adjusted if t_adjusted<20 & t_adjusted>-10, bin(50) fcolor(gs14) lstyle(thin) frequency xtitle("Reported t-statistics") xline(-1.96 0 1.96, lcolor(red)) xlabel(-10 -5 -1.96 0 1.96 5 10 15 20) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(caliper_cd, replace)

***************************************************************************************
* PUBLICATION BIAS - Funnel plot (Egger et al., 1997)
***************************************************************************************

sum cohens_d precision_cohens_d
twoway scatter  precision_cohens_d cohens_d if precision_cohens_d<400 & cohens_d>-0.6 & cohens_d<1, ytitle("Precision of the Cohen's d (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Cohen's d") xline(0, lpattern(solid) lcolor (bluishgray)) xlabel(0 , add) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel_cd, replace)

***************************************************************************************
* PUBLICATION BIAS - FAT-PET (Stanley, 2005) for WLS, FE, BE, and IV
***************************************************************************************

xtset study_id

eststo: ivreg2 cohens_d_w se_cohens_d_w, cluster(study_id)
  boottest se_cohens_d_w, nograph
  boottest _cons, nograph 
eststo: xtreg cohens_d_w se_cohens_d_w, fe vce(cluster study_id)
  boottest se_cohens_d_w, nograph
eststo: xtreg cohens_d_w se_cohens_d_w, be
eststo: ivreg2 cohens_d_w se_cohens_d_w [pweight=weight], cluster (study_id)
  boottest se_cohens_d_w, nograph
  boottest _cons, nograph
eststo: ivreg2 tstat_cohens_d_w precision_cohens_d_w, cluster (study_id)
  boottest precision_cohens_d_w, nograph
  boottest _cons, nograph
esttab using tab_cd.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "BE" "Study" "Precision") label
eststo clear

eststo: ivreg2 cohens_d se_cohens_d, cluster(study_id)
  boottest se_cohens_d, nograph
  boottest _cons, nograph 
eststo: xtreg cohens_d se_cohens_d, fe vce(cluster study_id)
  boottest se_cohens_d, nograph
eststo: xtreg cohens_d se_cohens_d, be
eststo: ivreg2 cohens_d se_cohens_d [pweight=weight], cluster (study_id)
  boottest se_cohens_d, nograph
  boottest _cons, nograph
eststo: ivreg2 tstat_cohens_d precision_cohens_d, cluster (study_id)
  boottest precision_cohens_d, nograph
  boottest _cons, nograph
esttab using tab_cd_unwinsorized.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "BE" "Study" "Precision") label
eststo clear

eststo: ivreg2 cohens_d_w se_cohens_d_w if preferred==1, cluster(study_id)
  boottest se_cohens_d_w, nograph
  boottest _cons, nograph 
eststo: xtreg cohens_d_w se_cohens_d_w if preferred==1, fe vce(cluster study_id)
  boottest se_cohens_d_w, nograph
eststo: xtreg cohens_d_w se_cohens_d_w if preferred==1, be
eststo: ivreg2 cohens_d_w se_cohens_d_w [pweight=weight_pref] if preferred==1, cluster (study_id)
  boottest se_cohens_d_w, nograph
  boottest _cons, nograph
eststo: ivreg2 tstat_cohens_d_w precision_cohens_d_w if preferred==1, cluster (study_id)
  boottest precision_cohens_d_w, nograph
  boottest _cons, nograph
esttab using tab_cd_pref.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "BE" "Study" "Precision") label
eststo clear

eststo: ivreg2 cohens_d_w (se_cohens_d_w = inv_sample_size), cluster (study_id) first		
			boottest se_cohens_d_w, nograph
			boottest _cons, nograph
			twostepweakiv 2sls cohens_d_w (se_cohens_d_w = inv_sample_size), cluster(study_id)		
eststo: ivreg2 cohens_d (se_cohens_d = inv_sample_size), cluster (study_id) first		
			boottest se_cohens_d, nograph
			boottest _cons, nograph
			twostepweakiv 2sls cohens_d (se_cohens_d = inv_sample_size), cluster(study_id)	
eststo: ivreg2 cohens_d_w (se_cohens_d_w = inv_sample_size) if preferred==1, cluster (study_id) first		
			boottest se_cohens_d_w, nograph
			boottest _cons, nograph
			twostepweakiv 2sls cohens_d_w (se_cohens_d_w = inv_sample_size) if preferred==1, cluster(study_id)
esttab using tab_cd_exogeneity.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("CD" "CD unwinsorized" "CD preferred") label
eststo clear

xtset study_id
eststo: ivreg2 cohens_d_w se_cohens_d_w, cluster(study_id)
  boottest se_cohens_d_w, nograph
  boottest _cons, nograph 
eststo: ivreg2 cohens_d_w se_cohens_d_w [pweight=weight], cluster (study_id)
  boottest se_cohens_d_w, nograph
  boottest _cons, nograph
eststo: xtreg cohens_d_w se_cohens_d_w, be
eststo: ivreg2 cohens_d_w se_cohens_d_w [pweight=weight_exp], cluster (study_id)
  boottest se_cohens_d_w, nograph
  boottest _cons, nograph 
xtset experiment_id
eststo: xtreg cohens_d_w se_cohens_d_w, be
esttab using tab_cd_experiment.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "Study" "BE Study" "Experiment" "BE Experiment") label
eststo clear

xtset study_id
eststo: ivreg2 cohens_d_w se_cohens_d_w if preferred==1, cluster(study_id)
  boottest se_cohens_d_w, nograph
  boottest _cons, nograph 
eststo: ivreg2 cohens_d_w se_cohens_d_w [pweight=weight_pref] if preferred==1, cluster (study_id)
  boottest se_cohens_d_w, nograph
  boottest _cons, nograph
eststo: xtreg cohens_d_w se_cohens_d_w if preferred==1, be
eststo: ivreg2 cohens_d_w se_cohens_d_w [pweight=weight_exp] if preferred==1, cluster (study_id)
  boottest se_cohens_d_w, nograph
  boottest _cons, nograph 
xtset experiment_id
eststo: xtreg cohens_d_w se_cohens_d_w if preferred==1, be
esttab using tab_cd_experiment_pref.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "Study" "BE Study" "Experiment" "BE Experiment") label
eststo clear

***************************************************************************************
* PUBLICATION BIAS - TOP10 method (Stanley et al., 2010)
***************************************************************************************

summarize precision_cohens_d_w, detail
gen top10bound_cd = r(p90)
summarize cohens_d_w precision_cohens_d_w if precision_cohens_d_w > top10bound_cd

summarize precision_cohens_d, detail
gen top10bound_cd_unwin = r(p90)
summarize cohens_d precision_cohens_d if precision_cohens_d > top10bound_cd_unwin

summarize precision_cohens_d_w if preferred==1, detail
gen top10bound_cd_pref = r(p90)
summarize cohens_d_w precision_cohens_d_w if precision_cohens_d_w > top10bound_cd_pref & preferred==1

***************************************************************************************
* PUBLICATION BIAS - WAAP (Ioannidis et al., 2017) 
***************************************************************************************

summarize cohens_d_w [aweight=1/(se_cohens_d_w*se_cohens_d_w)]
gen waapbound_cd = abs(r(mean))/2.8
reg tstat_cohens_d_w precision_cohens_d_w if se_cohens_d_w < waapbound_cd, noconstant

summarize cohens_d [aweight=1/(se_cohens_d*se_cohens_d)]
gen waapbound_cd_unwin = abs(r(mean))/2.8
reg tstat_cohens_d precision_cohens_d if se_cohens_d < waapbound_cd_unwin, noconstant

summarize cohens_d_w [aweight=1/(se_cohens_d_w*se_cohens_d_w)] if preferred==1
gen waapbound_cd_pref = abs(r(mean))/2.8
reg tstat_cohens_d_w precision_cohens_d_w if se_cohens_d_w < waapbound_cd_pref & preferred==1, noconstant

***************************************************************************************
* PUBLICATION BIAS - Endogenous kink (Bom & Rachinger, 2020)
*   code downloaded from https://sites.google.com/site/heikorachinger/codes 
***************************************************************************************

/*
drop if preferred==0

quietly{
rename cohens_d_w bs
rename se_cohens_d_w sebs
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
rename  bs cohens_d_w 
rename  sebs se_cohens_d_w
*/

***************************************************************************************
* Publication bias - p-uniform* (van Aert & van Assen, 2020) - on median values 
***************************************************************************************

/* Code for Stata (creating the dataset)
*drop if preferred==0

bysort study_id: egen cd_med = median(cohens_d)
bysort study_id: egen se_med = median(se_cohens_d)
bysort study_id: egen t_med = median(tstat_cohens_d)
gen variance_med = se_med*se_med

bysort study_id: egen cd_medw = median(cohens_d_w)
bysort study_id: egen se_medw = median(se_cohens_d_w)
bysort study_id: egen t_medw = median(tstat_cohens_d_w)
gen variance_medw = se_medw*se_medw

preserve
collapse (lastnm) cd_med cd_medw se_med se_medw variance_med variance_medw t_med t_medw (p50) nobs_med=n_obs, by(study_id)
save "puniform_cd.dta", replace
*save "puniform_cd_pref.dta", replace
restore
clear
*/

/* Code for R (testing for publication bias)
library(puniform)
library(metafor)
library(dmetar)
library(haven)
library(tidyverse)
library(meta)

data <- read_dta("puniform_cd.dta")
data <- read_dta("puniform_cd_pref.dta")

puni_star(yi = data$cd_med, vi = data$variance_med, side="right", method="ML",alpha = 0.05)
#puni_star(yi = data$cd_medw, vi = data$variance_medw, side="right", method="ML",alpha = 0.05)
puniform(yi = data$cd_med, vi = data$variance_med, side="right", method="ML",alpha = 0.05)
#puniform(yi = data$cd_medw, vi = data$variance_medw, side="right", method="ML",alpha = 0.05)
*/

***************************************************************************************
* PUBLICATION BIAS - Stem-based method in R (Furukawa, 2019) - on median values
***************************************************************************************

/*
source("stem_method.R") #github.com/Chishio318/stem-based_method
dataincentives = read.table("clipboard-512", sep="\t", header=TRUE)
stem_results = stem(dataincentives$cd_medw, dataincentives$se_medw, param)
stem_results[["estimates"]]
*/

***************************************************************************************
* PUBLICATION BIAS - Andrews & Kasy (2019) and Kranz & Putz(2022) in R
***************************************************************************************

/*
# save csv in "effect" "standard error" format to default folder (Libraries\Documents)
# https://github.com/skranz/MetaStudies#testing-the-independence-assumption-of-andrews-and-kasy-2019
# https://github.com/maxkasy/MetaStudiesApp

options(repos = c(skranz = 'https://skranz.r-universe.dev',
CRAN = 'https://cloud.r-project.org'))
install.packages('MetaStudies')
library(MetaStudies)

dataincentives= read.csv("data.csv", header = FALSE)
colnames(dataincentives) = c("X","sigma")
# perform A&K test
ms = metastudies_estimation(X=dataincentives$X,sigma=dataincentives$sigma,model = "t",cutoffs = c(-1.96, 0, 1.96),symmetric = FALSE)
ms$est_tab
# for clustered standard errors use the app from https://maxkasy.github.io/home/code-and-apps/
# check the viability of the test
metastudy_X_sigma_cors(ms)
resl=bootstrap_specification_tests(dataincentives$X, dataincentives$sigma, B = 500)
estimates_plot(ms)
resl
*/


***************************************************************************************
* Publication bias - p-hacking (Elliott et al., 2022) - data preparation
***************************************************************************************
*drop if preferred==0

gen t_abs = abs(tstat_cohens_d)
gen ptop = 2*(1 - normal(t_abs))
*drop if se_ppc==.
drop if ptop > 1
gen id = study_id

export delimited using "elliot_cd.csv", replace
clear

/*
*https://github.com/skranz/phack?tab=readme-ov-file
options(repos = c(
  skranz = 'https://skranz.r-universe.dev',
  CRAN = 'https://cloud.r-project.org'))
install.packages('phack')
library(phack)

dat = read.table("clipboard-512", sep="\t", header=TRUE)

phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.1, J=5)
phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.1, J=10)
phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.1, J=15)
phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.1, J=20)

phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.1, J=5, K=2, use_bound=TRUE)
phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.1, J=10, K=2, use_bound=TRUE)
phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.1, J=15, K=2, use_bound=TRUE)
phack_test_cox_shi(dat$ptop,dat$id, p_min=0.00001, p_max=0.1, J=20, K=2, use_bound=TRUE)

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
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
* WORKING PAPERS SUBSET
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************
* include only working papers without journals 

clear
import excel incentives_data.xlsx, sheet("data") firstrow
set more off
xtset study_id

drop if include == 1

winsor2 pcc, suffix(_w) cuts(1 99)
winsor2 se_pcc, suffix(_w) cuts(1 99)
winsor2 cohens_d, suffix(_w) cuts(1 99)
winsor2 se_cohens_d, suffix(_w) cuts(1 99)
winsor2 n_obs, suffix(_w) cuts(1 99)
gen precision_w = 1/se_pcc_w
gen tstat_w = t_adjusted
gen precision_cohens_d = 1/se_cohens_d
gen precision_cohens_d_w = 1/se_cohens_d_w
gen tstat_cohens_d_w = cohens_d_w/se_cohens_d_w
gen effect_negative=0
gen inv_sample_size = 1/sqrt(observations)
replace effect_negative=1 if effect_positive==0
gen developing_country=0
replace developing_country=1 if developed_country==0
gen other_method2=0
replace other_method2=1 if (mean_method==1 | other_method==1)


***************************************************************************************
* Summary statistics
***************************************************************************************

sum pcc_w se_pcc_w, detail
sum cohens_d_w se_cohens_d_w, detail
sum pcc_w se_pcc_w if preferred==1, detail
sum cohens_d_w se_cohens_d_w if preferred==1, detail

histogram pcc if pcc>-0.4 & pcc<0.6, bin(60) fcolor(gs14) lstyle(thin) frequency xtitle("Partial correlation coefficient") xline(0.052, lcolor(red)) xlabel(-0.4 -0.2 0 0.052 0.2 0.4 0.6) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram_wp, replace)
bysort study_id: egen pcc_med = median(pcc_w)
bysort study_id: egen midyear_med = median(data_year)
graph hbox pcc if pcc>-0.4 & pcc<0.6, over(study,label(grid) sort(midyear_med)) xsize(2.6) ysize(2) scale(0.8) yline(0, lcolor (bluishgray)) box(1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow) mcolor(gs12)) ytitle("Partial correlation coefficient") ylabel(, nogrid) saving(studies_wp, replace) 

histogram t_adjusted if t_adjusted<20 & t_adjusted>-10, bin(30) fcolor(gs14) lstyle(thin) frequency xtitle("Reported t-statistics") xline(-1.96 0 1.96, lcolor(red)) xlabel(-10 -5 -1.96 0 1.96 5 10 15 20) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(caliper_wp, replace)

***************************************************************************************
* PUBLICATION BIAS - Funnel plot (Egger et al., 1997)
***************************************************************************************

sum pcc precision_pcc
sum cohens_d precision_cohens_d

twoway scatter  precision_pcc pcc if precision_pcc<200 & pcc>-0.4 & pcc<0.6, ytitle("Precision of the partial correlation coefficient (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Partial correlation coefficient") xline(0, lpattern(solid) lcolor (bluishgray)) xlabel(0 , add) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel_wo, replace)

***************************************************************************************
* PUBLICATION BIAS - FAT-PET (Stanley, 2005) for WLS, FE, BE, and IV
***************************************************************************************

xtset study_id

eststo: ivreg2 pcc_w se_pcc_w
  boottest se_pcc_w, nograph
  boottest _cons, nograph 
eststo: xtreg pcc_w se_pcc_w, fe 
  boottest se_pcc_w, nograph
eststo: xtreg pcc_w se_pcc_w, be
eststo: ivreg2 pcc_w se_pcc_w [pweight=weight]
  boottest se_pcc_w, nograph
  boottest _cons, nograph
eststo: ivreg2 tstat_w precision_w
  boottest precision_w, nograph
  boottest _cons, nograph
esttab using tab_wp_pcc.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "BE" "Study" "Precision") label
eststo clear

eststo: ivreg2 pcc_w se_pcc_w if preferred==1
  boottest se_pcc_w, nograph
  boottest _cons, nograph 
eststo: xtreg pcc_w se_pcc_w  if preferred==1, fe 
  boottest se_pcc_w, nograph
eststo: xtreg pcc_w se_pcc_w if preferred==1, be
eststo: ivreg2 pcc_w se_pcc_w [pweight=weight_pref] if preferred==1
  boottest se_pcc_w, nograph
  boottest _cons, nograph
eststo: ivreg2 tstat_w precision_w  if preferred==1
  boottest precision_w, nograph
  boottest _cons, nograph
esttab using tab_wp_pcc_pref.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) width(\textwidth) nonumbers mtitles("OLS" "FE" "BE" "Study" "Precision") label
eststo clear

eststo: ivreg2 pcc_w (se_pcc_w = inv_sample_size), cluster (study_id) first		
			boottest se_pcc_w, nograph
			boottest _cons, nograph
			twostepweakiv 2sls pcc_w (se_pcc_w = inv_sample_size), cluster(study_id)
eststo: ivreg2 pcc_w (se_pcc_w = inv_sample_size) if preferred==1, cluster (study_id) first		
			boottest se_pcc_w, nograph
			boottest _cons, nograph
			twostepweakiv 2sls pcc_w (se_pcc_w = inv_sample_size) if preferred==1, cluster(study_id)
esttab using tab_wp_exogeneity.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

***************************************************************************************
* PUBLICATION BIAS - TOP10 method (Stanley et al., 2010)
***************************************************************************************

summarize precision_w, detail
gen top10bound_wp = r(p90)
summarize pcc_w precision_w if precision_w > top10bound_wp

summarize precision_w if preferred==1, detail
gen top10bound_wp_pref = r(p90)
summarize pcc_w precision_w if precision_w > top10bound_wp_pref & preferred==1

***************************************************************************************
* PUBLICATION BIAS - WAAP (Ioannidis et al., 2017) 
***************************************************************************************

/*
summarize pcc_w [aweight=1/(se_pcc_w*se_pcc_w)]
gen waapbound_wp = abs(r(mean))/2.8
reg tstat_w precision_w if se_pcc_w < waapbound_wp, noconstant

summarize pcc_w [aweight=1/(se_pcc_w*se_pcc_w)] if preferred==1
gen waapbound_wp_pref = abs(r(mean))/2.8
reg tstat_w precision_w if se_pcc_w < waapbound_wp_pref & preferred==1, noconstant
*/

***************************************************************************************
* PUBLICATION BIAS - Endogenous kink (Bom & Rachinger, 2020)
*   code downloaded from https://sites.google.com/site/heikorachinger/codes 
***************************************************************************************

/*
*drop if preferred==0

quietly{
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
*/

***************************************************************************************
* Publication bias - p-uniform* (van Aert & van Assen, 2020) - on median values 
***************************************************************************************

/* Code for Stata (creating the dataset)
*drop if preferred==0

bysort study_id: egen pcc_med = median(pcc)
bysort study_id: egen se_med = median(se_pcc)
bysort study_id: egen t_med = median(t_adjusted)
gen variance_med = se_med*se_med

bysort study_id: egen pcc_medw = median(pcc_w)
bysort study_id: egen se_medw = median(se_pcc_w)
bysort study_id: egen t_medw = median(tstat_w)
gen variance_medw = se_medw*se_medw

preserve
collapse (lastnm) pcc_med pcc_medw se_med se_medw variance_med variance_medw t_med t_medw (p50) nobs_med=n_obs, by(study_id)
save "puniform_wp.dta", replace
*save "puniform_wp_pref.dta", replace
restore
clear
*/

/* Code for R (testing for publication bias)
library(puniform)
library(metafor)
library(dmetar)
library(haven)
library(tidyverse)
library(meta)

data <- read_dta("puniform_wp.dta")
data <- read_dta("puniform_wp_pref.dta")

data = read.table("clipboard-512", sep="\t", header=TRUE)
data$variance_pcc_w <- data$se_pcc_w^2
data$variance_pcc <- data$se_pcc^2
puni_star(yi = data$pcc, vi = data$variance_pcc, side="right", method="ML",alpha = 0.05)
puniform(yi = data$pcc, vi = data$variance_pcc, side="right", method="ML",alpha = 0.05)


puni_star(yi = data$pcc_med, vi = data$variance_med, side="right", method="ML",alpha = 0.05)
#puni_star(yi = data$pcc_medw, vi = data$variance_medw, side="right", method="ML",alpha = 0.05)
puniform(yi = data$pcc_med, vi = data$variance_med, side="right", method="ML",alpha = 0.05)
#puniform(yi = data$pcc_medw, vi = data$variance_medw, side="right", method="ML",alpha = 0.05)
*/

***************************************************************************************
* PUBLICATION BIAS - Stem-based method in R (Furukawa, 2019) - on median values
***************************************************************************************

/*
source("stem_method.R") #github.com/Chishio318/stem-based_method
dataincentives = read.table("clipboard-512", sep="\t", header=TRUE)
stem_results = stem(dataincentives$pcc_medw, dataincentives$se_medw, param)
stem_results[["estimates"]]
*/

***************************************************************************************
* PUBLICATION BIAS - Andrews & Kasy (2019) and Kranz & Putz(2022) in R
***************************************************************************************

/*
# save csv in "effect" "standard error" format to default folder (Libraries\Documents)
# https://github.com/skranz/MetaStudies#testing-the-independence-assumption-of-andrews-and-kasy-2019
# https://github.com/maxkasy/MetaStudiesApp

options(repos = c(skranz = 'https://skranz.r-universe.dev',
CRAN = 'https://cloud.r-project.org'))
install.packages('MetaStudies')
library(MetaStudies)

dataincentives= read.csv("data.csv", header = FALSE)
colnames(dataincentives) = c("X","sigma")
# perform A&K test
ms = metastudies_estimation(X=dataincentives$X,sigma=dataincentives$sigma,model = "t",cutoffs = c(-1.96, 0, 1.96),symmetric = FALSE)
ms$est_tab
# for clustered standard errors use the app from https://maxkasy.github.io/home/code-and-apps/
# check the viability of the test
metastudy_X_sigma_cors(ms)
resl=bootstrap_specification_tests(dataincentives$X, dataincentives$sigma, B = 500)
estimates_plot(ms)
resl
*/

clear
