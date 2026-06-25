***************************************************************************************
***************************************************************************************
* Exxamining publication bias in the alpha estimate of hedge funds literature
***************************************************************************************
***************************************************************************************
* January 15, 2023

log using hedge.log, replace
import excel hedge_bias.xlsx, sheet("data") firstrow
set more off
set graphics off
xtset study_id

***************************************************************************************
* Data preparation
***************************************************************************************

gen instrument = 1/sqrt(sample_size)
winsor2 alpha, suffix(_w) cuts(1 99)
winsor2 se, suffix(_w) cuts(1 99)
gen tstat_w = alpha_w/se_w 
gen precision_w = 1/se_w
gen method_noniv = 0
replace method_noniv = 1 if method_iv==0
gen bias_treated = 0
replace bias_treated = 1 if (survivorship_treated==1 | backfilling_treated==1)
gen bias_not_treated = 0
replace bias_not_treated = 1 if survivorship_treated==0 & backfilling_treated==0
gen se_method_iv = se_w * method_iv

egen sd_se_w = sd(se_w), by(study_id)
gen alpha_w_sd = alpha_w/sd_se_w
gen se_w_sd = se_w/sd_se_w
egen se_medw = median(se_w), by(study_id)
gen alpha_w_semed = alpha_w/se_medw
gen se_w_semed = se_w/se_medw

***************************************************************************************
* Summary statistics
***************************************************************************************

sum alpha tstat se, detail
sum alpha alpha_w se se_w tstat tstat_w, detail

gen top5studies = top5*weight
graph bar (sum) top5studies, over(year_publication) bar(1, color(gs10)) graphregion(color(ltbluishgray))  b1title("Publication year")  l1title("Number of studies") saving(histogram_studies, replace)
histogram tstat if tstat<15, bin(50) fcolor(gs14) lstyle(thin) frequency xtitle("t-statistics of the alpha estimate")  xline(0, lcolor(gs8) lpattern(dash)) xline(-1.96 1.96, lcolor(red)) xlabel(-5 -1.96 0 1.96 5) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram_tstat, replace)

graph hbox alpha if alpha<3 & alpha>-3, over(study,label(grid) sort(year_data)) xsize(2.6) ysize(4) scale(0.55)  yline(0, lcolor(gs8) lpattern(dash)) yline(0.36, lcolor (red))  box(1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow)  mcolor(gs12)) ytitle("Estimate of the alpha") ylabel(, nogrid) saving(studies, replace) 
graph hbox alpha if alpha<3 & alpha>-3, over(country,label(grid)) xsize(6) ysize(3.5) scale(1) yline(0.36, lcolor (red)) yline(0, lcolor(gs8) lpattern(dash)) box(1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow)  mcolor(gs12)) ytitle("Estimate of the alpha") ylabel(, nogrid)  saving(countries, replace) 

***************************************************************************************
* PUBLICATION BIAS - Funnel plot (Egger et al., 1997)
***************************************************************************************

*whole sample
twoway scatter precision alpha if alpha<3 & alpha>-3, yscale(log) ylab(1  10  80  200,grid) xlab(,g) ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of the alpha") xline(0, lcolor(gs8) lpattern(dash)) xline(0.3623496, lpattern(solid) lcolor (red)) xlabel(0.36 ,add custom labcolor(red)) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel, replace)
histogram alpha if alpha>-3 & alpha<3, bin(70) fcolor(gs14) lstyle(thin) frequency xtitle("Estimate of the alpha") xline(0.3623496, lcolor(red)) xline(0, lcolor(gs8) lpattern(dash)) xlabel(-2 -1 0 0.36 1 2) xlabel(0.36 ,add custom labcolor(red)) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram, replace)

*bias treatment
twoway scatter precision alpha if alpha<3 & alpha>-3 & (survivorship_treated==1 | backfilling_treated==1), yscale(log) ylab(1  10  80  200,grid) xlab(,g) ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of the alpha") xline(0, lcolor(gs8) lpattern(dash)) xline(0.3623496, lpattern(solid) lcolor (red)) xlabel(0.36 ,add custom labcolor(red)) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel_bias_treated, replace)
twoway scatter precision alpha if alpha<3 & alpha>-3 & (survivorship_treated==0 & backfilling_treated==0), yscale(log) ylab(1  10  80  200,grid) xlab(,g) ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of the alpha") xline(0, lcolor(gs8) lpattern(dash)) xline(0.3623496, lpattern(solid) lcolor (red)) xlabel(0.36 ,add custom labcolor(red)) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel_bias_nottreated, replace)
histogram alpha if alpha>-3 & alpha<3 & (survivorship_treated==1 | backfilling_treated==1), bin(70) fcolor(gs14) lstyle(thin) frequency xtitle("Estimate of the alpha") xline(0.3623496, lcolor(red)) xline(0, lcolor(gs8) lpattern(dash)) xlabel(-2 -1 0 0.36 1 2) xlabel(0.36 ,add custom labcolor(red)) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram_bias_treated, replace)
histogram alpha if alpha>-3 & alpha<3 & (survivorship_treated==0 & backfilling_treated==0), bin(70) fcolor(gs14) lstyle(thin) frequency xtitle("Estimate of the alpha") xline(0.3623496, lcolor(red)) xline(0, lcolor(gs8) lpattern(dash)) xlabel(-2 -1 0 0.36 1 2) xlabel(0.36 ,add custom labcolor(red)) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram_bias_nottreated, replace)

*methods
twoway scatter precision alpha if alpha<3 & alpha>-3 & method_iv==1, yscale(log) ylab(1  10  80  200,grid) xlab(,g) ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of the alpha") xline(0, lcolor(gs8) lpattern(dash)) xline(0.3623496, lpattern(solid) lcolor (red)) xlabel(0.36 ,add custom labcolor(red)) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel_method_iv, replace)
twoway scatter precision alpha if alpha<3 & alpha>-3 & method_iv==0, yscale(log) ylab(1  10  80  200,grid) xlab(,g) ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of the alpha") xline(0, lcolor(gs8) lpattern(dash)) xline(0.3623496, lpattern(solid) lcolor (red)) xlabel(0.36 ,add custom labcolor(red)) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel_method_noniv, replace)
histogram alpha if alpha>-3 & alpha<3 & method_iv==1, bin(50) fcolor(gs14) lstyle(thin) frequency xtitle("Estimate of the alpha") xline(0.3623496, lcolor(red)) xline(0, lcolor(gs8) lpattern(dash)) xlabel(-2 -1 0 0.36 1 2) xlabel(0.36 ,add custom labcolor(red)) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram_method_iv, replace)
histogram alpha if alpha>-3 & alpha<3 & method_iv==0, bin(70) fcolor(gs14) lstyle(thin) frequency xtitle("Estimate of the alpha") xline(0.3623496, lcolor(red)) xline(0, lcolor(gs8) lpattern(dash)) xlabel(-2 -1 0 0.36 1 2) xlabel(0.36 ,add custom labcolor(red)) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram_method_noniv, replace)

*models
twoway scatter precision alpha if alpha<3 & alpha>-3 & model_1factor==1, yscale(log) ylab(1  10  80  200,grid) xlab(,g) ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of the alpha") xline(0, lcolor(gs8) lpattern(dash)) xline(0.3623496, lpattern(solid) lcolor (red)) xlabel(0.36 ,add custom labcolor(red)) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel_model_1factor, replace)
twoway scatter precision alpha if alpha<3 & alpha>-3 & model_7factor==1, yscale(log) ylab(1  10  80  200,grid) xlab(,g) ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of the alpha") xline(0, lcolor(gs8) lpattern(dash)) xline(0.3623496, lpattern(solid) lcolor (red)) xlabel(0.36 ,add custom labcolor(red)) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel_model_7factor, replace)
histogram alpha if alpha>-3 & alpha<3 & model_1factor==1, bin(70) fcolor(gs14) lstyle(thin) frequency xtitle("Estimate of the alpha") xline(0.3623496, lcolor(red)) xline(0, lcolor(gs8) lpattern(dash)) xlabel(-2 -1 0 0.36 1 2) xlabel(0.36 ,add custom labcolor(red)) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram_model_1factor, replace)
histogram alpha if alpha>-3 & alpha<3 & model_7factor==1, bin(70) fcolor(gs14) lstyle(thin) frequency xtitle("Estimate of the alpha") xline(0.3623496, lcolor(red)) xline(0, lcolor(gs8) lpattern(dash)) xlabel(-2 -1 0 0.36 1 2) xlabel(0.36 ,add custom labcolor(red)) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram_model_7factor, replace)

*publications
twoway scatter precision alpha if alpha<3 & alpha>-3 & top5==1, yscale(log) ylab(1  10  80  200,grid) xlab(,g) ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of the alpha") xline(0, lcolor(gs8) lpattern(dash)) xline(0.3623496, lpattern(solid) lcolor (red)) xlabel(0.36 ,add custom labcolor(red)) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel_top5, replace)
twoway scatter precision alpha if alpha<3 & alpha>-3 & top3==1, yscale(log) ylab(1  10  80  200,grid) xlab(,g) ytitle("Precision of the estimate (1/SE)") ylabel( ,glcolor(ltbluishgray)) xtitle("Estimate of the alpha") xline(0, lcolor(gs8) lpattern(dash)) xline(0.3623496, lpattern(solid) lcolor (red)) xlabel(0.36 ,add custom labcolor(red)) msymbol(smcircle_hollow) graphregion(color(ltbluishgray)) saving(funnel_top3, replace)
histogram alpha if alpha>-3 & alpha<3 & top5==1, bin(70) fcolor(gs14) lstyle(thin) frequency xtitle("Estimate of the alpha") xline(0.3623496, lcolor(red)) xline(0, lcolor(gs8) lpattern(dash)) xlabel(-2 -1 0 0.36 1 2) xlabel(0.36 ,add custom labcolor(red)) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram_top5, replace)
histogram alpha if alpha>-3 & alpha<3 & top3==1, bin(70) fcolor(gs14) lstyle(thin) frequency xtitle("Estimate of the alpha") xline(0.3623496, lcolor(red)) xline(0, lcolor(gs8) lpattern(dash)) xlabel(-2 -1 0 0.36 1 2) xlabel(0.36 ,add custom labcolor(red)) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram_top3, replace)

***************************************************************************************
* PUBLICATION BIAS - FAT-PET (Stanley, 2005) for OLS, FE, BE, IV, WLS, wNobs
***************************************************************************************

xtset study_id

*whole sample (baseline)					
eststo: ivreg2 alpha_w se_w, cluster(study_id)
		boottest se_w, nograph
		boottest _cons, nograph
eststo: xtreg alpha_w se_w, fe vce(cluster study_id)
xtreg alpha_w_sd se_w_sd, fe vce(cluster study_id)
xtreg alpha_w_semed se_w_semed, fe vce(cluster study_id)
eststo: xtreg alpha_w se_w, be 
eststo: ivreg2 alpha_w (se_w=instrument), cluster(study_id) first
		boottest se_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls alpha_w (se_w=instrument), cluster(study_id)
eststo: ivreg2 tstat_w precision_w, cluster(study_id)
		boottest precision_w, nograph
		boottest _cons, nograph
eststo: ivreg2 alpha_w se_w [pweight=weight], cluster(study_id)
		boottest se_w, nograph
		boottest _cons, nograph
esttab using tab_pbias.tex, se booktabs replace compress title(FAT-PET whole sample \label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


*Biases are treated (at least one)
egen count_noBias = count(alpha) if (survivorship_treated==1 | backfilling_treated==1), by(study_id)
gen weight_noBias = 1/count_noBias					
eststo: ivreg2 alpha_w se_w if (survivorship_treated==1 | backfilling_treated==1), cluster(study_id) 
		boottest se_w, nograph
		boottest _cons, nograph
eststo: xtreg alpha_w se_w if (survivorship_treated==1 | backfilling_treated==1), fe vce(cluster study_id)
xtreg alpha_w_sd se_w_sd if (survivorship_treated==1 | backfilling_treated==1), fe vce(cluster study_id)
xtreg alpha_w_semed se_w_semed if (survivorship_treated==1 | backfilling_treated==1), fe vce(cluster study_id)
eststo: xtreg alpha_w se_w if (survivorship_treated==1 | backfilling_treated==1), be 
eststo: ivreg2 alpha_w (se_w=instrument) if (survivorship_treated==1 | backfilling_treated==1), cluster(study_id) first
		boottest se_w, nograph 
		boottest _cons, nograph 
		twostepweakiv 2sls alpha_w (se_w=instrument) if (survivorship_treated==1 | backfilling_treated==1), cluster(study_id)
eststo: ivreg2 tstat_w precision_w if (survivorship_treated==1 | backfilling_treated==1), cluster(study_id)
		boottest precision_w, nograph
		boottest _cons, nograph
eststo: ivreg2 alpha_w se_w [pweight=weight_noBias] if (survivorship_treated==1 | backfilling_treated==1), cluster(study_id)
		boottest se_w, nograph
		boottest _cons, nograph
esttab using tab_pbias_noBias.tex, se booktabs replace compress title(FAT-PET biases are treated \label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*Biases are not treated (none is)
egen count_Bias = count(alpha) if survivorship_treated==0 & backfilling_treated==0, by(study_id)
gen weight_Bias = 1/count_Bias					
eststo: ivreg2 alpha_w se_w if survivorship_treated==0 & backfilling_treated==0, cluster(study_id) 
		boottest se_w, nograph
		boottest _cons, nograph
eststo: xtreg alpha_w se_w if survivorship_treated==0 & backfilling_treated==0, fe vce(cluster study_id)
xtreg alpha_w_sd se_w_sd if survivorship_treated==0 & backfilling_treated==0, fe vce(cluster study_id)
xtreg alpha_w_semed se_w_semed if survivorship_treated==0 & backfilling_treated==0, fe vce(cluster study_id)
eststo: xtreg alpha_w se_w if survivorship_treated==0 & backfilling_treated==0, be 
eststo: ivreg2 alpha_w (se_w=instrument) if survivorship_treated==0 & backfilling_treated==0, cluster(study_id) first
		boottest se_w, nograph 
		boottest _cons, nograph 
		twostepweakiv 2sls alpha_w (se_w=instrument) if survivorship_treated==0 & backfilling_treated==0, cluster(study_id)
eststo: ivreg2 tstat_w precision_w if survivorship_treated==0 & backfilling_treated==0, cluster(study_id)
		boottest precision_w, nograph
		boottest _cons, nograph
eststo: ivreg2 alpha_w se_w [pweight=weight_Bias] if survivorship_treated==0 & backfilling_treated==0, cluster(study_id)
		boottest se_w, nograph
		boottest _cons, nograph
esttab using tab_pbias_Bias.tex, se booktabs replace compress title(FAT-PET biases are NOT treated \label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*Method IV
egen count_iv = count(alpha) if method_iv==1, by(study_id)
gen weight_iv = 1/count_iv					
eststo: ivreg2 alpha_w se_w if method_iv==1, cluster(study_id) 
		boottest se_w, nograph
		boottest _cons, nograph
eststo: xtreg alpha_w se_w if method_iv==1, fe vce(cluster study_id)
xtreg alpha_w_sd se_w_sd if method_iv==1, fe vce(cluster study_id)
xtreg alpha_w_semed se_w_semed if method_iv==1, fe vce(cluster study_id)
eststo: xtreg alpha_w se_w if method_iv==1, be 
eststo: ivreg2 alpha_w (se_w=instrument) if method_iv==1, cluster(study_id) first
		boottest se_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls alpha_w (se_w=instrument) if method_iv==1, cluster(study_id)
eststo: ivreg2 tstat_w precision_w if method_iv==1, cluster(study_id)
		boottest precision_w, nograph
		boottest _cons, nograph
eststo: ivreg2 alpha_w se_w [pweight=weight_iv] if method_iv==1, cluster(study_id)
		boottest se_w, nograph
		boottest _cons, nograph
esttab using tab_pbias_iv.tex, se booktabs replace compress title(FAT-PET method IV \label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*Method not IV
egen count_niv = count(alpha) if method_iv==0, by(study_id)
gen weight_niv = 1/count_niv					
eststo: ivreg2 alpha_w se_w if method_iv==0, cluster(study_id) 
		boottest se_w, nograph
		boottest _cons, nograph
eststo: xtreg alpha_w se_w if method_iv==0, fe vce(cluster study_id)
xtreg alpha_w_sd se_w_sd if method_iv==0, fe vce(cluster study_id)
xtreg alpha_w_semed se_w_semed if method_iv==0, fe vce(cluster study_id)
eststo: xtreg alpha_w se_w if method_iv==0, be 
eststo: ivreg2 alpha_w (se_w=instrument) if method_iv==0, cluster(study_id) first
		boottest se_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls alpha_w (se_w=instrument) if method_iv==0, cluster(study_id)
eststo: ivreg2 tstat_w precision_w if method_iv==0, cluster(study_id)
		boottest precision_w, nograph
		boottest _cons, nograph
eststo: ivreg2 alpha_w se_w [pweight=weight_niv] if method_iv==0, cluster(study_id)
		boottest se_w, nograph
		boottest _cons, nograph
esttab using tab_pbias_niv.tex, se booktabs replace compress title(FAT-PET method not IV \label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear

*Model 1-factor
egen count_M1f = count(alpha) if model_1factor==1, by(study_id)
gen weight_M1f = 1/count_M1f					
eststo: ivreg2 alpha_w se_w if model_1factor==1, cluster(study_id) 
		boottest se_w, nograph
		boottest _cons, nograph
eststo: xtreg alpha_w se_w if model_1factor==1, fe vce(cluster study_id)
xtreg alpha_w_sd se_w_sd if model_1factor==1, fe vce(cluster study_id)
xtreg alpha_w_semed se_w_semed if model_1factor==1, fe vce(cluster study_id)
eststo: xtreg alpha_w se_w if model_1factor==1, be 
eststo: ivreg2 alpha_w (se_w=instrument) if model_1factor==1, cluster(study_id) first
		boottest se_w, nograph 
		boottest _cons, nograph 
		twostepweakiv 2sls alpha_w (se_w=instrument) if model_1factor==1, cluster(study_id)
eststo: ivreg2 tstat_w precision_w if model_1factor==1, cluster(study_id)
		boottest precision_w, nograph
		boottest _cons, nograph
eststo: ivreg2 alpha_w se_w [pweight=weight_M1f] if model_1factor==1, cluster(study_id)
		boottest se_w, nograph
		boottest _cons, nograph
esttab using tab_pbias_M1f.tex, se booktabs replace compress title(FAT-PET model 1-factor \label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


*Model 7-factor
egen count_M7f = count(alpha) if model_7factor==1, by(study_id)
gen weight_M7f = 1/count_M7f					
eststo: ivreg2 alpha_w se_w if model_7factor==1, cluster(study_id) 
		boottest se_w, nograph
		boottest _cons, nograph
eststo: xtreg alpha_w se_w if model_7factor==1, fe vce(cluster study_id)
xtreg alpha_w_sd se_w_sd if model_7factor==1, fe vce(cluster study_id)
xtreg alpha_w_semed se_w_semed if model_7factor==1, fe vce(cluster study_id)
eststo: xtreg alpha_w se_w if model_7factor==1, be 
eststo: ivreg2 alpha_w (se_w=instrument) if model_7factor==1, cluster(study_id) first
		boottest se_w, nograph 
		boottest _cons, nograph 
		twostepweakiv 2sls alpha_w (se_w=instrument) if model_7factor==1, cluster(study_id)
eststo: ivreg2 tstat_w precision_w if model_7factor==1, cluster(study_id)
		boottest precision_w, nograph
		boottest _cons, nograph
eststo: ivreg2 alpha_w se_w [pweight=weight_M7f] if model_7factor==1, cluster(study_id)
		boottest se_w, nograph
		boottest _cons, nograph
esttab using tab_pbias_M7f.tex, se booktabs replace compress title(FAT-PET model 7-factor \label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


*Model top5
egen count_top5 = count(alpha) if top5==1, by(study_id)
gen weight_top5 = 1/count_top5					
eststo: ivreg2 alpha_w se_w if top5==1, cluster(study_id) 
		boottest se_w, nograph
		boottest _cons, nograph
eststo: xtreg alpha_w se_w if top5==1, fe vce(cluster study_id)
xtreg alpha_w_sd se_w_sd if top5==1, fe vce(cluster study_id)
xtreg alpha_w_semed se_w_semed if top5==1, fe vce(cluster study_id)
eststo: xtreg alpha_w se_w if top5==1, be 
eststo: ivreg2 alpha_w (se_w=instrument) if top5==1, cluster(study_id) first
		boottest se_w, nograph 
		boottest _cons, nograph 
		twostepweakiv 2sls alpha_w (se_w=instrument) if top5==1, cluster(study_id)
eststo: ivreg2 tstat_w precision_w if top5==1, cluster(study_id)
		boottest precision_w, nograph
		boottest _cons, nograph
eststo: ivreg2 alpha_w se_w [pweight=weight_top5] if top5==1, cluster(study_id)
		boottest se_w, nograph
		boottest _cons, nograph
esttab using tab_pbias_top5.tex, se booktabs replace compress title(FAT-PET model top5 \label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


*Model top3
egen count_top3 = count(alpha) if top3==1, by(study_id)
gen weight_top3 = 1/count_top3					
eststo: ivreg2 alpha_w se_w if top3==1, cluster(study_id) 
		boottest se_w, nograph
		boottest _cons, nograph
eststo: xtreg alpha_w se_w if top3==1, fe vce(cluster study_id)
xtreg alpha_w_sd se_w_sd if top3==1, fe vce(cluster study_id)
xtreg alpha_w_semed se_w_semed if top3==1, fe vce(cluster study_id)
eststo: xtreg alpha_w se_w if top3==1, be 
eststo: ivreg2 alpha_w (se_w=instrument) if top3==1, cluster(study_id) first
		boottest se_w, nograph 
		boottest _cons, nograph 
		twostepweakiv 2sls alpha_w (se_w=instrument) if top3==1, cluster(study_id)
eststo: ivreg2 tstat_w precision_w if top3==1, cluster(study_id)
		boottest precision_w, nograph
		boottest _cons, nograph
eststo: ivreg2 alpha_w se_w [pweight=weight_top3] if top3==1, cluster(study_id)
		boottest se_w, nograph
		boottest _cons, nograph
esttab using tab_pbias_top3.tex, se booktabs replace compress title(FAT-PET model top3 \label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


*whole sample (author-team dependencies)
xtset study_id	
eststo: ivreg2 alpha_w se_w, cluster(team_id)
		boottest se_w, nograph
		boottest _cons, nograph
eststo: xtreg alpha_w se_w, fe vce(cluster team_id)
xtreg alpha_w_sd se_w_sd, fe vce(cluster team_id)
xtreg alpha_w_semed se_w_semed, fe vce(cluster team_id)
eststo: xtreg alpha_w se_w, be 
eststo: ivreg2 alpha_w (se_w=instrument), cluster(team_id) first
		boottest se_w, nograph
		boottest _cons, nograph 
		twostepweakiv 2sls alpha_w (se_w=instrument), cluster(team_id)
eststo: ivreg2 tstat_w precision_w, cluster(team_id)
		boottest precision_w, nograph
		boottest _cons, nograph
eststo: ivreg2 alpha_w se_w [pweight=weight], cluster(team_id)
		boottest se_w, nograph
		boottest _cons, nograph
esttab using tab_pbias_teams.tex, se booktabs replace compress title(FAT-PET whole sample \label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear


***************************************************************************************
* PUBLICATION BIAS - Stem-based method in R (Furukawa, 2019)
***************************************************************************************
/*
source("stem_method.R") #github.com/Chishio318/stem-based_method
datahedge = read.table("clipboard-512", sep="\t", header=TRUE)
stem_results = stem(datahedge$alpha, datahedge$se, param)
stem_results[["estimates"]]
*/
***************************************************************************************
* PUBLICATION BIAS - TOP10 method (Stanley et al., 2010)
***************************************************************************************

summarize precision, detail
gen top10bound = r(p90)
summarize alpha if precision > top10bound

*bias
summarize precision if (survivorship_treated==1 | backfilling_treated==1), detail
gen top10bound_nobias = r(p90)
summarize alpha if precision > top10bound_nobias & (survivorship_treated==1 | backfilling_treated==1)

summarize precision if backfilling_treated==0 & survivorship_treated==0, detail
gen top10bound_bias = r(p90)
summarize alpha if precision > top10bound_bias & backfilling_treated==0 & survivorship_treated==0

*methods
summarize precision if method_iv==1, detail
gen top10bound_iv = r(p90)
summarize alpha if precision > top10bound_iv & method_iv==1

summarize precision if method_iv==0, detail
gen top10bound_niv = r(p90)
summarize alpha if precision > top10bound_niv & method_iv==0

*models
summarize precision if model_1factor==1, detail
gen top10bound_M1f = r(p90)
summarize alpha if precision > top10bound_M1f & model_1factor==1

summarize precision if model_7factor==1, detail
gen top10bound_M7f = r(p90)
summarize alpha if precision > top10bound_M7f & model_7factor==1

*publications
summarize precision if top5==1, detail
gen top10bound_top5 = r(p90)
summarize alpha if precision > top10bound_top5 & top5==1

summarize precision if top3==1, detail
gen top10bound_top3 = r(p90)
summarize alpha if precision > top10bound_top3 & top3==1


***************************************************************************************
* PUBLICATION BIAS - WAAP (Ioannidis et al., 2017) 
***************************************************************************************

summarize alpha [aweight=1/(se*se)] 
gen waapbound = abs(r(mean))/2.8
reg tstat precision if se < waapbound, noconstant

*biases
summarize alpha [aweight=1/(se*se)] if (survivorship_treated==1 | backfilling_treated==1)
gen waapbound_nobias = abs(r(mean))/2.8
reg tstat precision if se < waapbound_nobias & (survivorship_treated==1 | backfilling_treated==1), noconstant

summarize alpha [aweight=1/(se*se)] if backfilling_treated==0 & survivorship_treated==0
gen waapbound_bias = abs(r(mean))/2.8
reg tstat precision if se < waapbound_bias & backfilling_treated==0 & survivorship_treated==0, noconstant

*methods
summarize alpha [aweight=1/(se*se)] if method_iv==1
gen waapbound_iv = abs(r(mean))/2.8
reg tstat precision if se < waapbound_iv & method_iv==1, noconstant

summarize alpha [aweight=1/(se*se)] if method_iv==0
gen waapbound_niv = abs(r(mean))/2.8
reg tstat precision if se < waapbound_niv & method_iv==0, noconstant

*models
summarize alpha [aweight=1/(se*se)] if model_1factor==1
gen waapbound_M1f = abs(r(mean))/2.8
reg tstat precision if se < waapbound_M1f & model_1factor==1, noconstant

summarize alpha [aweight=1/(se*se)] if model_7factor==1
gen waapbound_M7f = abs(r(mean))/2.8
reg tstat precision if se < waapbound_M7f & model_7factor==1, noconstant

*models
summarize alpha [aweight=1/(se*se)] if top5==1
gen waapbound_top5 = abs(r(mean))/2.8
reg tstat precision if se < waapbound_top5 & top5==1, noconstant

summarize alpha [aweight=1/(se*se)] if top3==1
gen waapbound_top3 = abs(r(mean))/2.8
reg tstat precision if se < waapbound_top3 & top3==1, noconstant

***************************************************************************************
* PUBLICATION BIAS - Endogenous kink (Bom & Rachinger, 2020)
*      code downloaded from https://sites.google.com/site/heikorachinger/codes 
***************************************************************************************
*drop if method_iv==0
*drop if method_iv==1
*drop if model_1factor==0
*drop if model_7factor==0
*drop if backfilling_treated==0 & survivorship_treated==0
*drop if (survivorship_treated==1 | backfilling_treated==1)
*drop if top5==0
*drop if top3==0

quietly{
rename alpha bs
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

rename  bs alpha
rename  sebs se
***************************************************************************************
* Publication bias - p-uniform* (van Aert & van Assen, 2020) - code for Stata & R
***************************************************************************************
*drop if backfilling_treated==0 & survivorship_treated==0
*drop if (survivorship_treated==1 | backfilling_treated==1)
*drop if method_iv==0
*drop if method_iv==1
*drop if model_1factor==0
*drop if model_7factor==0
*drop if top5==0
*drop if top3==0

bysort study_id: egen alpha_med = median(alpha)
bysort study_id: egen se_med = median(se)
bysort study_id: egen t_med = median(tstat)
gen variance_med = se_med*se_med

bysort study_id: egen alpha_medw = median(alpha_w)
*bysort study_id: egen se_medw = median(se_w)
bysort study_id: egen t_medw = median(tstat_w)
gen variance_medw = se_medw*se_medw

preserve
collapse (lastnm) alpha_med alpha_medw variance_med variance_medw t_med t_medw (p50) nobs_med=sample_size, by(study_id)
save "puniform.dta", replace
restore

*save "puniform_nobias.dta", replace
*save "puniform_bias.dta", replace
*save "puniform_IV.dta", replace
*save "puniform_nIV.dta", replace
*save "puniform_M1f.dta", replace
*save "puniform_M7f.dta", replace
*save "puniform_top5.dta", replace
*save "puniform_top3.dta", replace

/* on median values
library(puniform)
library(metafor)
library(dmetar)
library(haven)
library(tidyverse)
library(meta)

data <- read_dta("puniform.dta")
data <- read_dta("puniform_nobias.dta")
data <- read_dta("puniform_bias.dta")
data <- read_dta("puniform_IV.dta")
data <- read_dta("puniform_nIV.dta")
data <- read_dta("puniform_M1f.dta")
data <- read_dta("puniform_M7f.dta")
data <- read_dta("puniform_top5.dta")
data <- read_dta("puniform_top3.dta")


puni_star(yi = data$alpha_med, vi = data$variance_med, side="right", method="ML",alpha = 0.05, control=list( max.iter=1000,tol=0.1,reps=10000, int=c(0,2), verbose=TRUE))
puni_star(yi = data$alpha_med, vi = data$variance_med, side="right", method="P",alpha = 0.05, control=list( max.iter=1000,tol=0.1,reps=10000, int=c(0,2), verbose=TRUE))
*/
clear
***************************************************************************************
* Publication bias - p-hacking (Elliott et al., 2022) - data preparation
***************************************************************************************
import excel hedge_bias.xlsx, sheet("data") firstrow
set more off

*drop if backfilling_treated==0 & survivorship_treated==0
*drop if (survivorship_treated==1 | backfilling_treated==1)
*drop if method_iv==0
*drop if method_iv==1
*drop if model_1factor==0
*drop if model_7factor==0
*drop if top5==0
*drop if top3==0

gen t_abs = abs(tstat)
gen ptop = 2*(1 - normal(t_abs))
drop if se==.
drop if ptop > 1
gen id = study_id

export delimited using "hedge.csv", replace
*export delimited using "hedge_nobias.csv", replace
*export delimited using "hedge_bias.csv", replace
*export delimited using "hedge_IV.csv", replace
*export delimited using "hedge_nIV.csv", replace
*export delimited using "hedge_M1f.csv", replace
*export delimited using "hedge_M7f.csv", replace
*export delimited using "hedge_top5.csv", replace
*export delimited using "hedge_top3.csv", replace
clear
