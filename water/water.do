******************************************************************************
*            INCOME ELASTICITY OF WATER DEMAND: A META-ANALYSIS              *
******************************************************************************
*Stata 14.1
*Sept 16, 2016
log using water.log, replace
import excel water.xlsx, sheet("dataset") firstrow
set more off
destring, replace dpcomma
#ssc install winsor
#ssc install estout
xtset studyid
******************************************************************************
* Definition of variables
******************************************************************************
gen inv_no_est = 1/numberofestimates
gen inv_no_est2 = 1/sqrt(numberofestimates)
gen inv_se = 1/standarderror
gen inv_se2 = 1/sqrt(standarderror)
bysort studyid: egen med_se = median(standarderror)
gen inv_med_se = 1/med_se
bysort studyid: egen med_se2 = median(standarderror*standarderror)
gen inv_med_se2 = 1/med_se2
replace publicationyear = publicationyear - 1972
gen publicationyear1 = publicationyear + 1972
replace midyear = midyear - 1956
gen standarderrorovb = standarderror*ovb
******************************************************************************
* Summary statistics
******************************************************************************
correlate incomeelasticity standarderror standarderrorovb householdsize populationdensity temperature rainfall evaporation differencevariable lagged discretecontinuous marginal otherprice midyear householddata longrun annual monthly daily timeseries crosssection ovb paneltechnique otherestimator flat increasing decreasing europe otherlocation developed publicationyear citations impact published
sum incomeelasticity, detail
local m = r(mean)
local med = r(p50)
histogram incomeelasticity, bin(40) frequency xline(`m', lp(solid) lcolor(gs0)) xline(`med', lp(dash) lcolor(gs0)) 
graph twoway (scatter incomeelasticity publicationyear1, msize(*1) msymbol(Oh)) (lfit incomeelasticity publicationyear1, lcolor(black)),  ytitle("Estimate of the income elasticity of water demand") legend(off) saving(trend, replace)
******************************************************************************
sum incomeelasticity if longrun==0, detail
sum incomeelasticity if longrun==1, detail
sum incomeelasticity if us==1, detail
sum incomeelasticity if eur==1, detail
sum incomeelasticity if otherlocation==1, detail
sum incomeelasticity if householddata==1, detail
sum incomeelasticity if aggregatedata==1, detail
sum incomeelasticity if published==0, detail
sum incomeelasticity if published==1, detail
sum incomeelasticity if developed==0, detail
sum incomeelasticity if developed==1, detail
sum incomeelasticity if ovb==1, detail
sum incomeelasticity if ovb==0, detail
sum incomeelasticity if iv==1, detail
sum incomeelasticity if paneltechnique==1, detail
sum incomeelasticity if otherestimator==1, detail
sum incomeelasticity [aweight=inv_no_est], detail
sum incomeelasticity if longrun==0 [aweight=inv_no_est], detail
sum incomeelasticity if longrun==1 [aweight=inv_no_est], detail
sum incomeelasticity if us==1 [aweight=inv_no_est], detail
sum incomeelasticity if eur==1 [aweight=inv_no_est], detail
sum incomeelasticity if otherlocation==1 [aweight=inv_no_est], detail
sum incomeelasticity if householddata==1 [aweight=inv_no_est], detail
sum incomeelasticity if aggregatedata==1 [aweight=inv_no_est], detail
sum incomeelasticity if published==0 [aweight=inv_no_est], detail
sum incomeelasticity if published==1 [aweight=inv_no_est], detail
sum incomeelasticity if developed==0 [aweight=inv_no_est], detail
sum incomeelasticity if developed==1 [aweight=inv_no_est], detail
sum incomeelasticity if ovb==1 [aweight=inv_no_est], detail
sum incomeelasticity if ovb==0 [aweight=inv_no_est], detail
sum incomeelasticity if iv==1 [aweight=inv_no_est], detail
sum incomeelasticity if paneltechnique==1 [aweight=inv_no_est], detail
sum incomeelasticity if otherestimator==1 [aweight=inv_no_est], detail
sum incomeelasticity standarderror standarderrorovb householdsize populationdensity temperature rainfall evaporation differencevariable lagged discretecontinuous marginal otherprice midyear longrun householddata daily monthly annual crosssection timeseries ovb paneltechnique otherestimator flat increasing decreasing europe otherlocation developed publicationyear citations impact published
sum incomeelasticity standarderror standarderrorovb householdsize populationdensity temperature rainfall evaporation differencevariable lagged discretecontinuous marginal otherprice midyear longrun householddata daily monthly annual crosssection timeseries ovb paneltechnique otherestimator flat increasing decreasing europe otherlocation developed publicationyear citations impact published [aweight=inv_no_est]
sum incomeelasticity standarderror standarderrorovb householdsize populationdensity temperature rainfall evaporation differencevariable lagged discretecontinuous marginal otherprice midyear longrun householddata daily monthly annual crosssection timeseries ovb paneltechnique otherestimator flat increasing decreasing europe otherlocation developed publicationyear citations impact published [aweight=inv_se]
sum incomeelasticity standarderror standarderrorovb householdsize populationdensity temperature rainfall evaporation differencevariable lagged discretecontinuous marginal otherprice midyear longrun householddata daily monthly annual crosssection timeseries ovb paneltechnique otherestimator flat increasing decreasing europe otherlocation developed publicationyear citations impact published [aweight=inv_no_est2]
sum incomeelasticity standarderror standarderrorovb householdsize populationdensity temperature rainfall evaporation differencevariable lagged discretecontinuous marginal otherprice midyear longrun householddata daily monthly annual crosssection timeseries ovb paneltechnique otherestimator flat increasing decreasing europe otherlocation developed publicationyear citations impact published [aweight=inv_se2]
******************************************************************************
graph hbox incomeelasticity if incomeelasticity<=1.2, over(label) xsize(6) ysize(6) scale(0.5) yline(0, lpattern(shortdash) lcolor (black)) saving(studies, replace)
******************************************************************************
* Funnel plot and Galbraith plot
******************************************************************************
scatter inv_se incomeelasticity if inv_se<200, msize(*1) msymbol(Oh)  xline(`m', lp(solid) lcolor(gs0)) xline(`med', lp(dash) lcolor(gs0)) xtitle("Estimate of the income elasticity of water demand") ytitle("Precision of the estimate (1/SE)") saving(funnel, replace)
## We assume that the true effect is 0.178
gen galb = (incomeelasticity - 0.178)/standarderror
scatter galb inv_se if inv_se<200 & galb < 25 & galb > -25, msize(*1) msymbol(Oh)  yline(1.96, lp(dash) lcolor(gs0)) yline(-1.96, lp(dash) lcolor(gs0)) xtitle("Precision of the estimate (1/SE)") ytitle("Standardized t-stat (if the true effect is 0.178)") saving(galbraith, replace)
count if galb < 1.96 & galb > -1.96
******************************************************************************
* FAT-PET
******************************************************************************
xtset studyid
eststo: ivreg2 incomeelasticity standarderror, cluster(studyid)
eststo: xtreg incomeelasticity standarderror, fe cluster(studyid)
eststo: ivreg2 incomeelasticity standarderror [pweight=inv_no_est], cluster(studyid)
eststo: xtreg incomeelasticity standarderror [pweight=inv_no_est], fe cluster(studyid)
eststo: ivreg2 incomeelasticity standarderror [pweight=inv_se], cluster(studyid)
eststo: xtreg incomeelasticity standarderror [pweight=inv_med_se], fe cluster(studyid)
esttab using fatpet_all.tex, se booktabs replace compress title(FAT-PET all\label{tab:fatpet}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
* OVB sample
eststo: ivreg2 incomeelasticity standarderror if ovb == 1, cluster(studyid)
eststo: xtreg incomeelasticity standarderror if ovb == 1, fe cluster(studyid)
eststo: ivreg2 incomeelasticity standarderror [pweight=inv_no_est] if ovb == 1, cluster(studyid)
eststo: xtreg incomeelasticity standarderror [pweight=inv_no_est] if ovb == 1, fe cluster(studyid)
eststo: ivreg2 incomeelasticity standarderror [pweight=inv_se] if ovb == 1, cluster(studyid)
eststo: xtreg incomeelasticity standarderror [pweight=inv_med_se] if ovb == 1, fe cluster(studyid)
esttab using fatpet_ovb.tex, se booktabs replace compress title(FAT-PET OVB\label{tab:fatpetovb}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
* non-OVB sample
eststo: ivreg2 incomeelasticity standarderror if ovb == 0, cluster(studyid)
eststo: xtreg incomeelasticity standarderror if ovb == 0, fe cluster(studyid)
eststo: ivreg2 incomeelasticity standarderror [pweight=inv_no_est] if ovb == 0, cluster(studyid)
eststo: xtreg incomeelasticity standarderror [pweight=inv_no_est] if ovb == 0, fe cluster(studyid)
eststo: ivreg2 incomeelasticity standarderror [pweight=inv_se] if ovb == 0, cluster(studyid)
eststo: xtreg incomeelasticity standarderror [pweight=inv_med_se] if ovb == 0, fe cluster(studyid)
esttab using fatpet_nonovb.tex, se booktabs replace compress title(FAT-PET non-OVB\label{tab:fatpetnonovb}) star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01)
eststo clear
******************************************************************************
* Code for R
****************************************************************************** 
#library(BMS)
#    *ctrl+C from water.xlsx, sheet("bma")
#datawater = read.table("clipboard-512", sep="\t", header=TRUE)
#water = bms(datawater, burn=1e5,iter=3e5, g="UIP", mprior="uniform", nmodel=50000, mcmc="bd", user.int=FALSE)
#water2 = bms(datawater, burn=1e5,iter=3e5, g="BRIC", mprior="random", nmodel=50000, mcmc="bd", user.int=FALSE)
#water3 = bms(datawater, burn=1e5,iter=3e5, g="hyper=BRIC", mprior="random", nmodel=50000, mcmc="bd", user.int=FALSE)
#coef(water, order.by.pip = F, exact=T, include.constant=T)
#image(water, yprop2pip=FALSE, order.by.pip=TRUE, do.par=TRUE, do.grid=TRUE, do.axis=TRUE, cex.axis = 0.7)
#summary(water)
#plot(water)
#print(water$topmod[1])
******************************************************************************
* Best practice
****************************************************************************** 
ivreg2 incomeelasticity standarderror standarderrorovb householdsize populationdensity temperature rainfall evaporation differencevariable lagged discretecontinuous marginal otherprice  longrun householddata daily monthly annual crosssection timeseries ovb paneltechnique otherestimator flat increasing decreasing europe otherlocation developed publicationyear citations impact published, cluster(studyid)
lincom _cons + standarderror*0 + standarderrorovb*0  +  householdsize*1  + populationdensity*1 + temperature*1  + rainfall*1  + evaporation*1  + differencevariable*0  + lagged*0.085 + discretecontinuous*0.107  + marginal*0  + otherprice*0  +  longrun*0.296  + householddata*1  + daily*1  + monthly*0  + annual*0  + crosssection*0  + timeseries*0  + ovb*0  + paneltechnique*1  + otherestimator*1  + flat*0.078  + increasing*0.485  + decreasing*0.023  + europe*0.166  + otherlocation*0.391  + developed*0.655  + publicationyear*43  + citations*27.333  + impact*0.875  + published*1  
local rhsvars incomeelasticity standarderror standarderrorovb householdsize populationdensity temperature rainfall evaporation differencevariable lagged discretecontinuous marginal otherprice  longrun householddata daily monthly annual crosssection timeseries ovb paneltechnique otherestimator flat increasing decreasing europe otherlocation developed publicationyear citations impact published
foreach x of varlist `rhsvars' {
				gen `x'_nobs = `x' / sqrt(numberofestimates)
}
foreach x of varlist `rhsvars' {
				egen aver`x'_nobs = mean(`x'_nobs)
				scalar scav`x'_nobs = aver`x'_nobs in 1
}
drop aver*
foreach x of varlist `rhsvars' {
				egen max`x'_nobs = max(`x'_nobs)
				scalar scmax`x'_nobs = max`x'_nobs in 1
}
drop max*
foreach x of varlist `rhsvars' {
				egen min`x'_nobs = min(`x'_nobs)
				scalar scmin`x'_nobs = min`x'_nobs in 1
}
drop min*
ivreg2 incomeelasticity_nobs standarderror_nobs standarderrorovb_nobs householdsize_nobs populationdensity_nobs temperature_nobs rainfall_nobs evaporation_nobs differencevariable_nobs lagged_nobs discretecontinuous_nobs marginal_nobs otherprice_nobs longrun_nobs householddata_nobs daily_nobs monthly_nobs annual_nobs crosssection_nobs timeseries_nobs ovb_nobs paneltechnique_nobs otherestimator_nobs flat_nobs increasing_nobs decreasing_nobs europe_nobs otherlocation_nobs developed_nobs publicationyear_nobs citations_nobs impact_nobs published_nobs, cluster(studyid)
lincom _cons + standarderror_nobs*0 + standarderrorovb_nobs*0 + householdsize_nobs*scmaxhouseholdsize_nobs  + populationdensity_nobs*scmaxpopulationdensity_nobs + temperature_nobs*scmaxtemperature_nobs  + rainfall_nobs*scmaxrainfall_nobs  + evaporation_nobs*scmaxevaporation_nobs  + differencevariable_nobs*scmindifferencevariable_nobs  + lagged_nobs*scavlagged_nobs + discretecontinuous_nobs*scavdiscretecontinuous_nobs  + marginal_nobs*scminmarginal_nobs  + otherprice_nobs*scminotherprice_nobs  +  longrun_nobs*scavlongrun_nobs  + householddata_nobs*scmaxhouseholddata_nobs  + daily_nobs*scmaxdaily_nobs  + monthly_nobs*scminmonthly_nobs  + annual_nobs*scminannual_nobs  + crosssection_nobs*scmincrosssection_nobs  + timeseries_nobs*scmintimeseries_nobs  + ovb_nobs*scminovb_nobs  + paneltechnique_nobs*scmaxpaneltechnique_nobs  + otherestimator_nobs*scmaxotherestimator_nobs  + flat_nobs*scavflat_nobs  + increasing_nobs*scavincreasing_nobs  + decreasing_nobs*scavdecreasing_nobs  + europe_nobs*scaveurope_nobs  + otherlocation_nobs*scavotherlocation_nobs  + developed_nobs*scavdeveloped_nobs  + publicationyear_nobs*scmaxpublicationyear_nobs  + citations_nobs*scmaxcitations_nobs  + impact_nobs*scmaximpact_nobs + published_nobs*scmaxpublished_nobs  

local rhsvars incomeelasticity standarderror standarderrorovb householdsize populationdensity temperature rainfall evaporation differencevariable lagged discretecontinuous marginal otherprice  longrun householddata daily monthly annual crosssection timeseries ovb paneltechnique otherestimator flat increasing decreasing europe otherlocation developed publicationyear citations impact published
foreach x of varlist `rhsvars' {
				gen `x'_se = `x' / sqrt(standarderror)
}

foreach x of varlist `rhsvars' {
				egen aver`x'_se = mean(`x'_se)
				scalar scav`x'_se = aver`x'_se in 1
}
drop aver*
foreach x of varlist `rhsvars' {
				egen max`x'_se = max(`x'_se)
				scalar scmax`x'_se = max`x'_se in 1
}
drop max*
foreach x of varlist `rhsvars' {
				egen min`x'_se = min(`x'_se)
				scalar scmin`x'_se = min`x'_se in 1
}
drop min*
ivreg2 incomeelasticity_se standarderror_se standarderrorovb_se inv_se2 householdsize_se populationdensity_se temperature_se rainfall_se evaporation_se differencevariable_se lagged_se discretecontinuous_se marginal_se otherprice_se longrun_se householddata_se daily_se monthly_se annual_se crosssection_se timeseries_se ovb_se paneltechnique_se otherestimator_se flat_se increasing_se decreasing_se europe_se otherlocation_se developed_se publicationyear_se citations_se impact_se published_se, cluster(studyid)
lincom _cons + standarderror_se*0 + standarderrorovb_se*0 +  inv_se2*0 + householdsize_se*scmaxhouseholdsize_se  + populationdensity_se*scmaxpopulationdensity_se + temperature_se*scmaxtemperature_se  + rainfall_se*scmaxrainfall_se  + evaporation_se*scmaxevaporation_se  + differencevariable_se*scmindifferencevariable_se  + lagged_se*scavlagged_se + discretecontinuous_se*scavdiscretecontinuous_se  + marginal_se*scminmarginal_se  + otherprice_se*scminotherprice_se  +  longrun_se*scavlongrun_se  + householddata_se*scmaxhouseholddata_se  + daily_se*scmaxdaily_se  + monthly_se*scminmonthly_se  + annual_se*scminannual_se  + crosssection_se*scmincrosssection_se  + timeseries_se*scmintimeseries_se  + ovb_se*scminovb_se  + paneltechnique_se*scmaxpaneltechnique_se  + otherestimator_se*scmaxotherestimator_se  + flat_se*scavflat_se  + increasing_se*scavincreasing_se  + decreasing_se*scavdecreasing_se  + europe_se*scaveurope_se  + otherlocation_se*scavotherlocation_se  + developed_se*scavdeveloped_se  + publicationyear_se*scmaxpublicationyear_se  + citations_se*scmaxcitations_se  + impact_se*scmaximpact_se + published_se*scmaxpublished_se  
******************************************************************************
* Frequentist check
****************************************************************************** 
ivreg2 incomeelasticity standarderror standarderrorovb ovb temperature differencevariable lagged otherprice daily increasing decreasing otherlocation citations impact published, cluster(studyid)
xtmixed incomeelasticity standarderror standarderrorovb ovb temperature differencevariable lagged otherprice daily increasing decreasing otherlocation citations impact published  || studyid:
ivreg2 incomeelasticity standarderror standarderrorovb ovb temperature differencevariable otherprice daily increasing decreasing otherlocation citations impact published, cluster(studyid)
xtmixed incomeelasticity standarderror standarderrorovb ovb temperature differencevariable otherprice daily increasing decreasing otherlocation citations impact published  || studyid:



