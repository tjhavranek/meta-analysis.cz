******************************************************************************
*              Natural Resource and Economic Growth: A Meta-Analysis         *
******************************************************************************

* Stata 12.0
* June 1, 2016 
log using natural_resource.log, replace
use natural_resource.dta, clear
set more off
******************************************************************************
* Definition of variables given label part in natural_resource.dta file
******************************************************************************
* Note: It was giving only 99% degree of freedom on Leite and Weidmann (2003) paper, we took upper limit 2.639, two side
*	    Some research present t-statistics – we estimated standard error based on t-statistics
*       As a natural resource measurmemnt - foresty (Botthole) and production value of natural resource(Boschini) did not take consider. 
******************************************************************************
* Calculate average mean value with intercation term
gen SXP= EFFECT_SIZE + BETA_INTERACTION*INSTITUTION_MEAN
gen SXP_SE= sqrt( EFFECT_SIZE_SE^2+ INTERACTION_SE^2* INSTITUTION_MEAN^2)
******************************************************************************
* CALCULATE PARTIAL CORRELATION COEFFICIENT
******************************************************************************
gen TSTAT=SXP/SXP_SE
gen PCC=TSTAT/sqrt(TSTAT^2+DF)
gen PCC_SE=PCC/TSTAT
******************************************************************************
* Generate weighting variables
******************************************************************************
gen prec=1/(PCC_SE^2)
* weighted with the inverse variance
gen invperst=1/NO_STUDY
******************************************************************************
* GENERATE INSTRUMENTAL VARIABLE
******************************************************************************
gen instrument=1/sqrt(DF)
******************************************************************************
* SET PANAL SET
******************************************************************************
xtset ID
******************************************************************************
* CALCULATE WEIGHTED VARIABLES
******************************************************************************
gen INVSE = 1/PCC_SE
gen SXPSE = TSTAT
gen NO_OBSSE = NO_OBS/PCC_SE
gen NO_EXPSE = NO_EXP/PCC_SE
gen DFSE = DF/PCC_SE
gen NO_COUNTRYSE = NO_COUNTRY/PCC_SE
gen NO_TIMESE = NO_TIME/PCC_SE
gen YEARSE = YEAR/PCC_SE
gen INDEXSE = INDEX/PCC_SE
gen GOOGLESE = GOOGLE/PCC_SE
gen REVIEWSE = REVIEW/PCC_SE
gen INSTITUTIONSE = INSTITUTION/PCC_SE
gen INTERACTIONSE = INTERACTION/PCC_SE
gen TOTSE = TOT/PCC_SE
gen OPENNESSE = OPENNES/PCC_SE
gen iGDPSE = iGDP/PCC_SE
gen INVESTMENTSE = INVESTMENT/PCC_SE
gen SCHOOLINGSE = SCHOOLING/PCC_SE
gen RES_ABUNDANCESE = RES_ABUNDANCE/PCC_SE
gen NATURALRSE = NATURALR/PCC_SE
gen POINTRSE = POINTR/PCC_SE
gen OILRSE = OILR/PCC_SE
gen GDPpcSE= GDP_pc/PCC_SE
gen GDPgrowthSE= GDP_growth/PCC_SE
gen GDPnrSE= GDP_nr/PCC_SE
gen CROSSSE= CROSS/PCC_SE
gen PANELSE= PANEL/PCC_SE
gen TIME_SERISSE = TIME_SERIES/PCC_SE
gen ENDOGENEITYSE = ENDOGENEITY/PCC_SE
gen OLSSE = OLS/PCC_SE
gen IVSE = IV/PCC_SE
gen REGIONSE = REGION/PCC_SE 
gen DUMMY60SE = DUMMY60/PCC_SE
gen DUMMY70SE = DUMMY70/PCC_SE
gen DUMMY80SE = DUMMY80/PCC_SE
gen DUMMY90SE = DUMMY90/PCC_SE
gen DUMMY00SE = DUMMY00/PCC_SE
******************************************************************************
gen LN_NO_OBS = log(NO_OBS+1)
gen LN_NO_EXP = log(NO_EXP+1)
gen LN_NO_COUNTRY = log(NO_COUNTRY+1)
gen LN_NO_TIME = log(NO_TIME+1)
gen LN_YEAR = log(YEAR+1)
gen LN_INDEX = log(INDEX+1)
gen LN_GOOGLE = log(GOOGLE+1)
******************************************************************************
gen LN_NO_OBSSE = LN_NO_OBS/PCC_SE
gen LN_NO_EXPSE = LN_NO_EXP/PCC_SE
gen LN_NO_COUNTRYSE = LN_NO_COUNTRY/PCC_SE
gen LN_NO_TIMESE = LN_NO_TIME/PCC_SE
gen LN_YEARSE = LN_YEAR/PCC_SE
gen LN_INDEXSE = LN_INDEX/PCC_SE
gen LN_GOOGLESE = LN_GOOGLE/PCC_SE
******************************************************************************
* SUMMARY STATISTICS - DATA DESCRIPTION
******************************************************************************
latabstat ID, s(mean sd min max) f(%5.2f)
latabstat OUTPUT, s(mean sd min max) f(%5.2f)

latabstat TSTAT, s(mean sd min max) f(%5.2f)
latabstat PCC, s(mean sd min max) f(%5.2f)
latabstat INVSE, s(mean sd min max) f(%5.2f)

latabstat SXP, s(mean sd min max) f(%5.2f)
latabstat SXP_SE, s(mean sd min max) f(%5.2f)
latabstat DF, s(mean  sd  min max) f(%5.2f)
latabstat NO_OBS, s(mean sd  min max) f(%5.2f)
latabstat NO_EXP, s(mean sd  min max) f(%5.2f)
latabstat NO_COUNTRY, s(mean sd  min max) f(%5.2f)
latabstat NO_TIME, s(mean sd  min max) f(%5.2f)

latabstat YEAR, s(mean  sd  min max) f(%5.2f)
latabstat INDEX, s(mean  sd  min max) f(%5.2f)
latabstat GOOGLE, s(mean  sd  min max) f(%5.2f)
latabstat REVIEW, s(mean  sd  min max) f(%5.2f)

latabstat INSTITUTION, s(mean  sd  min max) f(%5.2f)
latabstat INTERACTION, s(mean  sd  min max) f(%5.2f)

latabstat TOT, s(mean  sd  min max) f(%5.2f)
latabstat OPENNESS, s(mean sd  min max) f(%5.2f)
latabstat iGDP, s(mean  sd  min max) f(%5.2f)
latabstat INVESTMENT, s(mean  sd  min max) f(%5.2f)
latabstat SCHOOLING, s(mean  sd  min max) f(%5.2f)

latabstat GDP_pc, s(mean  sd  min max) f(%5.2f)
latabstat GDP_growth, s(mean  sd  min max) f(%5.2f)
latabstat GDP_nr, s(mean  sd  min max) f(%5.2f)

latabstat RES_ABUNDANCE, s(mean  sd  min max) f(%5.2f)
latabstat NATURALR, s(mean  sd  min max) f(%5.2f)
latabstat OILR, s(mean  sd  min max) f(%5.2f)

latabstat CROSS, s(mean  sd  min max) f(%5.2f)
latabstat PANEL, s(mean  sd  min max) f(%5.2f)
latabstat TIME_SERIES, s(mean  sd  min max) f(%5.2f)
latabstat REGION, s(mean  sd  min max) f(%5.2f)

latabstat ENDOGENEITY, s(mean  sd  min max) f(%5.2f)
latabstat OLS, s(mean  sd  min max) f(%5.2f)

latabstat DUMMY60, s(mean  sd  min max) f(%5.2f)
latabstat DUMMY70, s(mean  sd  min max) f(%5.2f)
latabstat DUMMY80, s(mean  sd  min max) f(%5.2f)
latabstat DUMMY90, s(mean  sd  min max) f(%5.2f)
latabstat DUMMY00, s(mean  sd  min max) f(%5.2f)
******************************************************************************
* THE MEAN VALUES OF PCC
******************************************************************************
ci PCC
ci PCC [fweight = ID]
ci PCC [aweight = ID]
******************************************************************************
* PUBLICATION BIAS
******************************************************************************
twoway scatter INVSE PCC, ytitle(INVSEpcc) xtitle(PCC)
metafunnel PCC PCC_SE, xtitle(PPC) ytitle(The Standard Error of PCC) egger
******************************************************************************
* FUNNEL ASSYMETRY TESTS
******************************************************************************
* weighted with precision
eststo: reg PCC PCC_SE [pweight=prec], cluster (ID)
eststo: ivreg PCC (PCC_SE=instrument) [pweight=prec], cluster(ID)
eststo: xtreg TSTAT INVSE, fe vce(cluster ID)
eststo: xtmixed PCC PCC_SE || ID: [pweight=prec] 
estout, cells(b(star fmt(3)) se(par fmt(2)))
esttab using table3.tex, cells(b(star fmt(3)) se(par fmt(2))) star(* 0.10 ** 0.05 *** 0.01)
eststo clear 
* weight must be constant within ID in fixed effect model
* sampling weights were specified only at the first level in a multilevel model. If these weights are indicative of overall and not conditional inclusion probabilities, then results may be biased.
******************************************************************************
* unweighted
eststo: reg PCC PCC_SE, cluster(ID)
eststo: ivreg PCC (PCC_SE=instrument), cluster(ID)
eststo: xtreg PCC PCC_SE, fe vce(cluster ID)
eststo: xtmixed PCC PCC_SE || ID:
estout, cells(b(star fmt(3)) se(par fmt(2)))
esttab using table3b.tex, cells(b(star fmt(3)) se(par fmt(2))) star(* 0.10 ** 0.05 *** 0.01)
eststo clear 
******************************************************************************
* weighted with number of study
eststo: reg PCC PCC_SE [pweight=invperst], cluster (ID)
eststo: ivreg PCC (PCC_SE=instrument) [pweight=invperst], cluster(ID)
eststo: xtreg PCC PCC_SE [pweight=invperst], fe vce(cluster ID)
eststo: xtmixed PCC PCC_SE || ID: [pweight=invperst]
estout, cells(b(star fmt(3)) se(par fmt(2)))
esttab using table3c.tex, cells(b(star fmt(3)) se(par fmt(2))) star(* 0.10 ** 0.05 *** 0.01)
eststo clear 
* sampling weights were specified only at the first level in a multilevel model. If these weights are indicative of overall and not conditional inclusion probabilities, then results may be biased.
******************************************************************************
* HETEROGENEITY
******************************************************************************
* weighted with precision
eststo:   reg PCC PCC_SE LN_NO_EXP LN_NO_COUNTRY LN_NO_TIME LN_YEAR LN_INDEX LN_GOOGLE REVIEW INSTITUTION INTERACTION TOT OPENNESS iGDP  INVESTMENT SCHOOLING GDP_pc GDP_growth GDP_nr RES_ABUNDANCE NATURALR OILR CROSS PANEL REGION OLS ENDOGENEITY DUMMY60 DUMMY80 DUMMY90 DUMMY00 [pweight=prec]
eststo:   ivreg PCC LN_NO_EXP LN_NO_COUNTRY LN_NO_TIME LN_YEAR LN_INDEX LN_GOOGLE REVIEW INSTITUTION INTERACTION TOT OPENNESS iGDP  INVESTMENT SCHOOLING GDP_pc GDP_growth GDP_nr RES_ABUNDANCE NATURALR OILR CROSS PANEL REGION OLS ENDOGENEITY DUMMY60 DUMMY80 DUMMY90 DUMMY00 (PCC_SE=instrument) [pweight=prec]
eststo:   xtreg TSTAT INVSE LN_NO_EXPSE LN_NO_COUNTRYSE LN_NO_TIMESE YEARSE INDEXSE GOOGLESE REVIEWSE INSTITUTIONSE INTERACTIONSE TOTSE OPENNESSE iGDPSE SCHOOLINGSE INVESTMENTSE GDPpcSE GDPgrowthSE GDPnrSE RES_ABUNDANCESE NATURALRSE OILRSE CROSSSE PANELSE REGIONSE OLSSE ENDOGENEITYSE DUMMY60SE DUMMY80SE DUMMY90SE DUMMY00SE, fe vce(cluster ID)
eststo:   xtmixed PCC PCC_SE LN_NO_EXP LN_NO_COUNTRY LN_NO_TIME LN_YEAR LN_INDEX LN_GOOGLE REVIEW INSTITUTION INTERACTION TOT OPENNESS iGDP  INVESTMENT SCHOOLING GDP_pc GDP_growth GDP_nr RES_ABUNDANCE NATURALR OILR CROSS PANEL REGION OLS ENDOGENEITY DUMMY60 DUMMY80 DUMMY90 DUMMY00 || ID: [pweight=prec]
estout, cells(b(star fmt(3)) se(par fmt(2)))
esttab using table4.tex, cells(b(star fmt(3)) se(par fmt(2))) star(* 0.10 ** 0.05 *** 0.01)
eststo clear
* weight must be constant within ID in fixed effect model
* sampling weights were specified only at the first level in a multilevel model. If these weights are indicative of overall and not conditional inclusion probabilities, then results may be biased.
******************************************************************************
* unweighted
eststo:   reg PCC PCC_SE LN_NO_EXP LN_NO_COUNTRY LN_NO_TIME LN_YEAR LN_INDEX LN_GOOGLE REVIEW INSTITUTION INTERACTION TOT OPENNESS iGDP  INVESTMENT SCHOOLING GDP_pc GDP_growth GDP_nr RES_ABUNDANCE NATURALR OILR CROSS PANEL REGION OLS ENDOGENEITY DUMMY60 DUMMY80 DUMMY90 DUMMY00,
eststo:   ivreg PCC LN_NO_EXP LN_NO_COUNTRY LN_NO_TIME LN_YEAR LN_INDEX LN_GOOGLE REVIEW INSTITUTION INTERACTION TOT OPENNESS iGDP  INVESTMENT SCHOOLING GDP_pc GDP_growth GDP_nr RES_ABUNDANCE NATURALR OILR CROSS PANEL REGION OLS ENDOGENEITY DUMMY60 DUMMY80 DUMMY90 DUMMY00 (PCC_SE=instrument)
eststo:   xtreg PCC PCC_SE LN_NO_EXP LN_NO_COUNTRY LN_NO_TIME LN_YEAR LN_INDEX LN_GOOGLE REVIEW INSTITUTION INTERACTION TOT OPENNESS iGDP  INVESTMENT SCHOOLING GDP_pc GDP_growth GDP_nr RES_ABUNDANCE NATURALR OILR CROSS PANEL REGION OLS ENDOGENEITY DUMMY60 DUMMY80 DUMMY90 DUMMY00, fe vce(cluster ID)
eststo:   xtmixed PCC PCC_SE LN_NO_EXP LN_NO_COUNTRY LN_NO_TIME LN_YEAR LN_INDEX LN_GOOGLE REVIEW INSTITUTION INTERACTION TOT OPENNESS iGDP  INVESTMENT SCHOOLING GDP_pc GDP_growth GDP_nr RES_ABUNDANCE NATURALR OILR CROSS PANEL REGION OLS ENDOGENEITY DUMMY60 DUMMY80 DUMMY90 DUMMY00 || ID:
estout, cells(b(star fmt(3)) se(par fmt(2)))
esttab using table4b.tex, cells(b(star fmt(3)) se(par fmt(2))) star(* 0.10 ** 0.05 *** 0.01)
eststo clear
******************************************************************************
* weighted with the number of study
eststo:   reg PCC PCC_SE LN_NO_EXP LN_NO_COUNTRY LN_NO_TIME LN_YEAR LN_INDEX LN_GOOGLE REVIEW INSTITUTION INTERACTION TOT OPENNESS iGDP  INVESTMENT SCHOOLING GDP_pc GDP_growth GDP_nr RES_ABUNDANCE NATURALR OILR CROSS PANEL REGION OLS ENDOGENEITY DUMMY60 DUMMY80 DUMMY90 DUMMY00 [pweight=invperst]
eststo:   ivreg PCC LN_NO_EXP LN_NO_COUNTRY LN_NO_TIME LN_YEAR LN_INDEX LN_GOOGLE REVIEW INSTITUTION INTERACTION TOT OPENNESS iGDP  INVESTMENT SCHOOLING GDP_pc GDP_growth GDP_nr RES_ABUNDANCE NATURALR OILR CROSS PANEL REGION OLS ENDOGENEITY DUMMY60 DUMMY80 DUMMY90 DUMMY00 (PCC_SE=instrument) [pweight=invperst]
eststo:   xtreg PCC PCC_SE LN_NO_EXP LN_NO_COUNTRY LN_NO_TIME LN_YEAR LN_INDEX LN_GOOGLE REVIEW INSTITUTION INTERACTION TOT OPENNESS iGDP  INVESTMENT SCHOOLING GDP_pc GDP_growth GDP_nr RES_ABUNDANCE NATURALR OILR CROSS PANEL REGION OLS ENDOGENEITY DUMMY60 DUMMY80 DUMMY90 DUMMY00 [pweight=invperst], fe vce(cluster ID)
eststo:   xtmixed PCC PCC_SE LN_NO_EXP LN_NO_COUNTRY LN_NO_TIME LN_YEAR LN_INDEX LN_GOOGLE REVIEW INSTITUTION INTERACTION TOT OPENNESS iGDP  INVESTMENT SCHOOLING GDP_pc GDP_growth GDP_nr RES_ABUNDANCE NATURALR OILR CROSS PANEL REGION OLS ENDOGENEITY DUMMY60 DUMMY80 DUMMY90 DUMMY00 || ID: [pweight=invperst]
esttab using table4c.tex, cells(b(star fmt(3)) se(par fmt(2))) star(* 0.10 ** 0.05 *** 0.01)
eststo clear 
* sampling weights were specified only at the first level in a multilevel model. If these weights are indicative of overall and not conditional inclusion probabilities, then results may be biased.
******************************************************************************
window manage close graph
log close
exit, clear
******************************************************************************
