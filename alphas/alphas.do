***************************************************************************************
***************************************************************************************
* Hedge Funds 
***************************************************************************************
***************************************************************************************
* January 15, 2024

log using hedge_het.log, replace
import excel hedge_het.xlsx, sheet("data") firstrow
set more off
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

gen both_biases_treated = 0
replace both_biases_treated = 1 if (survivorship_treated==1 & backfilling_treated==1)
gen survivorship_only = 0
replace survivorship_only = 1 if (survivorship_treated==1 & backfilling_treated==0)
gen backfilling_only = 0
replace backfilling_only = 1 if (survivorship_treated==0 & backfilling_treated==1)

collin se_w se_method_iv depvar_individual_funds depvar_equalw_funds depvar_net_returns data_cross_section data_midyear database_default database_cst database_cisdm database_handcollect number_of_databases market_developed market_bull market_bear strategy_all strategy_equity strategy_events strategy_relative_value strategy_global strategy_fund_of_funds strategy_multi method_iv model_1factor model_3factor model_4factor model_7factor model_uncertainty model_asset_based survivorship_treated backfilling_treated publication_year citations impact_factor

***************************************************************************************
* Summary statistics
***************************************************************************************

sum alpha tstat se , detail
sum alpha_w se_w se_method_iv depvar_individual_funds depvar_equalw_funds depvar_valuew_funds depvar_net_returns depvar_gross_returns data_cross_section data_longitudal data_midyear database_default database_cst database_cisdm database_handcollect database_other number_of_databases market_developed market_world market_bull market_bear strategy_all strategy_equity strategy_events strategy_relative_value strategy_global strategy_fund_of_funds strategy_multi strategy_other method_iv method_noniv model_1factor model_3factor model_4factor model_7factor model_uncertainty model_asset_based model_other survivorship_treated backfilling_treated bias_treated bias_not_treated publication_year citations impact_factor
sum alpha_w se_w se_method_iv depvar_individual_funds depvar_equalw_funds depvar_valuew_funds depvar_net_returns depvar_gross_returns data_cross_section data_longitudal data_midyear database_default database_cst database_cisdm database_handcollect database_other number_of_databases market_developed market_world market_bull market_bear strategy_all strategy_equity strategy_events strategy_relative_value strategy_global strategy_fund_of_funds strategy_multi strategy_other method_iv method_noniv model_1factor model_3factor model_4factor model_7factor model_uncertainty model_asset_based model_other survivorship_treated backfilling_treated bias_treated bias_not_treated publication_year citations impact_factor [aweight=weight]
correlate se_w se_method_iv depvar_individual_funds depvar_equalw_funds depvar_net_returns data_cross_section data_midyear database_default database_cst database_cisdm database_handcollect number_of_databases market_developed market_bull market_bear strategy_all strategy_equity strategy_events strategy_relative_value strategy_global strategy_fund_of_funds strategy_multi method_iv model_1factor model_3factor model_4factor model_7factor model_uncertainty model_asset_based survivorship_treated backfilling_treated publication_year citations impact_factor
collin se_w se_method_iv depvar_individual_funds depvar_equalw_funds depvar_net_returns data_cross_section data_midyear database_default database_cst database_cisdm database_handcollect number_of_databases market_developed market_bull market_bear strategy_all strategy_equity strategy_events strategy_relative_value strategy_global strategy_fund_of_funds strategy_multi method_iv model_1factor model_3factor model_4factor model_7factor model_uncertainty model_asset_based survivorship_treated backfilling_treated publication_year citations impact_factor

histogram se if se<100
histogram alpha if alpha>-3 & alpha<3, bin(70) fcolor(gs14) lstyle(thin) frequency xtitle("Estimate of the alpha") xline(0.3623496, lcolor(red)) xlabel(-2 -1 0 0.37 1 2) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray)) saving(histogram, replace)

bysort study_id: egen alpha_med = median(alpha)
bysort study_id: egen midyear_med = median(year_data)
graph twoway (scatter alpha_med midyear_med if alpha_med<3 & alpha_med>-3, msize(*1) msymbol(Oh) ylabel( ,glcolor(ltbluishgray)) graphregion(color(ltbluishgray))) (lfit alpha_med midyear_med, lcolor(black) lpattern(dash)),  xtitle("Median year of data used by a study") ytitle("Median estimate of the alpha") legend(off) saving(trend, replace)

sum alpha alpha_w se se_w tstat tstat_w, detail

mean alpha_w
mean alpha_w if depvar_individual_funds==1
mean alpha_w if depvar_equalw_funds==1
mean alpha_w if depvar_valuew_funds==1
mean alpha_w if depvar_net_returns==1
mean alpha_w if depvar_gross_returns==1
mean alpha_w if data_cross_section==1
mean alpha_w if data_longitudal==1
mean alpha_w if database_default==1
mean alpha_w if database_cst==1
mean alpha_w if database_cisdm==1
mean alpha_w if database_handcollect==1
mean alpha_w if database_other==1
mean alpha_w if market_developed==1
mean alpha_w if market_world==1
mean alpha_w if market_bull==1
mean alpha_w if market_bear==1
mean alpha_w if strategy_all==1
mean alpha_w if strategy_equity==1
mean alpha_w if strategy_events==1
mean alpha_w if strategy_relative_value==1
mean alpha_w if strategy_global==1
mean alpha_w if strategy_fund_of_funds==1
mean alpha_w if strategy_multi==1
mean alpha_w if strategy_other==1
mean alpha_w if method_iv==1
mean alpha_w if method_iv==0
mean alpha_w if model_1factor==1
mean alpha_w if model_3factor==1
mean alpha_w if model_4factor==1
mean alpha_w if model_7factor==1
mean alpha_w if model_uncertainty==1
mean alpha_w if model_asset_based==1
mean alpha_w if model_other==1
mean alpha_w if survivorship_treated==1
mean alpha_w if backfilling_treated==1
mean alpha_w if backfilling_treated==0 & survivorship_treated==0
mean alpha_w if (survivorship_treated==1 | backfilling_treated==1)

mean alpha_w [aweight=weight]
mean alpha_w [aweight=weight] if depvar_individual_funds==1
mean alpha_w [aweight=weight] if depvar_equalw_funds==1
mean alpha_w [aweight=weight] if depvar_valuew_funds==1
mean alpha_w [aweight=weight] if depvar_net_returns==1
mean alpha_w [aweight=weight] if depvar_gross_returns==1
mean alpha_w [aweight=weight] if data_cross_section==1
mean alpha_w [aweight=weight] if data_longitudal==1
mean alpha_w [aweight=weight] if database_default==1
mean alpha_w [aweight=weight] if database_cst==1
mean alpha_w [aweight=weight] if database_cisdm==1
mean alpha_w [aweight=weight] if database_handcollect==1
mean alpha_w [aweight=weight] if database_other==1
mean alpha_w [aweight=weight] if market_developed==1
mean alpha_w [aweight=weight] if market_world==1
mean alpha_w [aweight=weight] if market_bull==1
mean alpha_w [aweight=weight] if market_bear==1
mean alpha_w [aweight=weight] if strategy_all==1
mean alpha_w [aweight=weight] if strategy_equity==1
mean alpha_w [aweight=weight] if strategy_events==1
mean alpha_w [aweight=weight] if strategy_relative_value==1
mean alpha_w [aweight=weight] if strategy_global==1
mean alpha_w [aweight=weight] if strategy_fund_of_funds==1
mean alpha_w [aweight=weight] if strategy_multi==1
mean alpha_w [aweight=weight] if strategy_other==1
mean alpha_w [aweight=weight] if method_iv==1
mean alpha_w [aweight=weight] if method_iv==0
mean alpha_w [aweight=weight] if method_other==1
mean alpha_w [aweight=weight] if model_1factor==1
mean alpha_w [aweight=weight] if model_3factor==1
mean alpha_w [aweight=weight] if model_4factor==1
mean alpha_w [aweight=weight] if model_7factor==1
mean alpha_w [aweight=weight] if model_uncertainty==1
mean alpha_w [aweight=weight] if model_asset_based==1
mean alpha_w [aweight=weight] if model_other==1
mean alpha_w [aweight=weight] if survivorship_treated==1
mean alpha_w [aweight=weight] if backfilling_treated==1
mean alpha_w [aweight=weight] if backfilling_treated==0 & survivorship_treated==0
mean alpha_w [aweight=weight] if (survivorship_treated==1 | backfilling_treated==1)


graph hbox alpha if alpha<3 & alpha>-3, over(study,label(grid) sort(year_data)) xsize(2.6) ysize(4) scale(0.55) yline(0.36, lcolor (red))  box(1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow)  mcolor(gs12)) ytitle("Estimate of the alpha") ylabel(, nogrid) saving(studies, replace) 
graph hbox alpha if alpha<3 & alpha>-3, over(country,label(grid)) xsize(6) ysize(3.5) scale(1) yline(0.36, lcolor (red))  box(1,lcolor(black) fcolor(none)) marker(1,msymbol(circle_hollow)  mcolor(gs12)) ytitle("Estimate of the alpha") ylabel(, nogrid) saving(countries, replace) 

twoway(hist alpha if method_iv==0 & alpha>-3 & alpha<3, bin(60) freq fcolor(navy) lcolor(navy) legend(label(1 "Non-IV method"))) (hist alpha if method_iv==1 & alpha >-3 & alpha<3, bin(20) gap(20) freq  lcolor(gs12) fcolor(gs12) legend(label(2 "Instrumental variables (IV)"))) , legend(ring(0) position(2) bmargin(small) rows(10) region(lstyle(none))) xtitle("Estimate of the alpha")  saving(pattern1, replace)
twoway(hist alpha if market_world==1 & alpha>-3 & alpha<3, bin(60) freq fcolor(navy) lcolor(navy) legend(label(1 "World market")))(hist alpha if market_developed==1 & alpha>-3 & alpha<3, bin(60) freq fcolor(gs12) lcolor(gs12) legend(label(2 "Developed market"))) , legend(ring(0) position(2) bmargin(medium) rows(3) region(lstyle(none))) xtitle("Estimate of the alpha")  saving(pattern2, replace)
twoway(hist alpha if depvar_equalw_funds==1 & alpha>-3 & alpha<3, bin(60) freq fcolor(gs12) lcolor(gs12) legend(label(1 "Equal-weighted funds")))(hist alpha if depvar_valuew_funds==1 & alpha>-3 & alpha<3, bin(60) gap(10) freq fcolor(cranberry) lcolor(cranberry) legend(label(2 "Value-weighted funds"))) (hist alpha if depvar_individual_funds==1 & alpha>-3 & alpha<3, bin(60) freq fcolor(navy) lcolor(navy) legend(label(3 "Individual funds"))), legend(ring(0) position(2) bmargin(medium) rows(3) region(lstyle(none))) xtitle("Estimate of the alpha")   saving(pattern3, replace)
twoway(hist alpha if bias_treated==1 & alpha>-3 & alpha<3, bin(60) freq fcolor(navy) lcolor(navy) legend(label(1 "Biases treated")))(hist alpha if bias_treated==0 & alpha>-3 & alpha<3, bin(60) gap(10) freq fcolor(gs12) lcolor(gs12) legend(label(2 "Biases untreated"))), legend(ring(0) position(2) bmargin(medium) rows(3) region(lstyle(none))) xtitle("Estimate of the alpha")   saving(pattern4, replace)
twoway(kdensity alpha if model_1factor==1 & alpha<3 & alpha>-3, legend(label(1 "1-factor model")))(kdensity alpha if model_3factor==1& alpha<3 & alpha>-3, legend(label(2 "3-factor model")))(kdensity alpha if model_4factor==1& alpha<3 & alpha>-3, legend(label(3 "4-factor model")))(kdensity alpha if model_7factor==1& alpha<3 & alpha>-3, legend(label(4 "7-factor model")))(kdensity alpha if model_uncertainty==1& alpha<3 & alpha>-3, legend(label(5 "modelling uncertainty")))(kdensity alpha if model_asset_based==1 & alpha<3 & alpha>-3, legend(label(6 "asset-based model")))(kdensity alpha if model_other==1 & alpha<3 & alpha>-3, legend(label(7 "other model"))) , legend(ring(0) position(2) bmargin(medium) rows(7) region(lstyle(none))) xtitle("Estimate of the alpha") ytitle("Kernel density (alpha)") saving(pattern5, replace)
twoway(kdensity alpha if strategy_all==1 & alpha<3 & alpha>-3, legend(label(1 "all funds")))(kdensity alpha if strategy_equity==1& alpha<3 & alpha>-3, legend(label(2 "equity hedge")))(kdensity alpha if strategy_events==1& alpha<3 & alpha>-3, legend(label(3 "events strategy")))(kdensity alpha if strategy_relative_value==1& alpha<3 & alpha>-3, legend(label(4 "relative value strategy")))(kdensity alpha if strategy_global==1& alpha<3 & alpha>-3, legend(label(5 "global funds")))(kdensity alpha if strategy_fund_of_funds==1 & alpha<3 & alpha>-3, legend(label(6 "fund of funds")))(kdensity alpha if strategy_multi==1 & alpha<3 & alpha>-3, legend(label(7 "multi-strategy"))) (kdensity alpha if strategy_other==1 & alpha<3 & alpha>-3, legend(label(8 "other strategy"))), legend(ring(0) position(2) bmargin(medium) rows(8) region(lstyle(none))) xtitle("Estimate of the alpha") ytitle("Kernel density (alpha)") saving(pattern6, replace)

keep study_id alpha_w se_w se_method_iv depvar_individual_funds depvar_equalw_funds depvar_net_returns data_cross_section data_midyear database_default database_cst database_cisdm database_handcollect number_of_databases market_developed market_bull market_bear strategy_all strategy_equity strategy_events strategy_relative_value strategy_global strategy_fund_of_funds strategy_multi method_iv model_1factor model_3factor model_4factor model_7factor model_uncertainty model_asset_based survivorship_treated backfilling_treated publication_year citations impact_factor
order study_id alpha_w se_w se_method_iv depvar_individual_funds depvar_equalw_funds depvar_net_returns data_cross_section data_midyear database_default database_cst database_cisdm database_handcollect number_of_databases market_developed market_bull market_bear strategy_all strategy_equity strategy_events strategy_relative_value strategy_global strategy_fund_of_funds strategy_multi method_iv model_1factor model_3factor model_4factor model_7factor model_uncertainty model_asset_based survivorship_treated backfilling_treated publication_year citations impact_factor
export excel using "hedge_4R.xlsx", sheet("data") replace first(var) 

clear


***************************************************************************************
* HETEROGENEITY - Data preparation
***************************************************************************************

import excel hedge_4R.xlsx, sheet("data") firstrow

collin se_w se_method_iv depvar_individual_funds depvar_equalw_funds depvar_net_returns data_cross_section data_midyear database_default database_cst database_cisdm database_handcollect number_of_databases market_developed market_bull market_bear strategy_all strategy_equity strategy_events strategy_relative_value strategy_global strategy_fund_of_funds strategy_multi method_iv model_1factor model_3factor model_4factor model_7factor model_uncertainty model_asset_based survivorship_treated backfilling_treated publication_year citations impact_factor

***************************************************************************************
* HETEROGENEITY - Bayesian model averaging ////CODE for R////
***************************************************************************************

/*
library(BMS)
    *ctrl+C from hedge.xlsx, sheet("data.r")
datahedge = read.table("clipboard-512", sep="\t", header=TRUE)
hedge0 = bms(datahedge, burn=1e5,iter=3e5, g="UIP", mprior="uniform", nmodel=50000, mcmc="bd", user.int=FALSE)
hedge1 = bms(datahedge, burn=1e5,iter=3e5, g="UIP", mprior="dilut", nmodel=50000, mcmc="bd", user.int=FALSE)
hedge2 = bms(datahedge, burn=1e5,iter=3e5, g="BRIC", mprior="random", nmodel=50000, mcmc="bd", user.int=FALSE)

coef(hedge0, order.by.pip = F, exact=T, include.constant=T)
image(hedge0, yprop2pip=FALSE, order.by.pip=TRUE, do.par=TRUE, do.grid=TRUE, do.axis=TRUE, cex.axis = 0.7)
summary(hedge0)
plot(hedge0)
print(hedge0$topmod[1])

coef(hedge1, order.by.pip = F, exact=T, include.constant=T)
image(hedge1, yprop2pip=FALSE, order.by.pip=TRUE, do.par=TRUE, do.grid=TRUE, do.axis=TRUE, cex.axis = 0.7)
summary(hedge1)
plot(hedge1)
print(hedge1$topmod[1])

coef(hedge2, order.by.pip = F, exact=T, include.constant=T)
image(hedge2, yprop2pip=FALSE, order.by.pip=TRUE, do.par=TRUE, do.grid=TRUE, do.axis=TRUE, cex.axis = 0.7)
summary(hedge2)
plot(hedge2)
print(hedge2$topmod[1])

plotComp("UIP and Uniform"=hedge0, "UIP and Dilution"=hedge1,"BRIC and Random"=hedge2,  add.grid=F,cex.xaxis=0.7)

library(corrplot)
datahedge = read.table("clipboard-512", sep="\t", header=TRUE)
col<- colorRampPalette(c("red", "white", "blue"))
M <- cor(datahedge)
corrplot.mixed(M, lower = "number", upper = "circle", lower.col=col(200), upper.col=col(200), tl.pos = c("lt"), diag = c("u"), tl.col="black", tl.srt=45, tl.cex=0.85, number.cex = 0.5, cl.cex=0.8, cl.ratio=0.1)
*/

***************************************************************************************
* HETEROGENEITY - Robustness check
***************************************************************************************

ivreg2 alpha_w se_w se_method_iv depvar_individual_funds depvar_equalw_funds depvar_net_returns data_cross_section data_midyear database_default database_cst database_cisdm database_handcollect number_of_databases market_developed market_bull market_bear strategy_all strategy_equity strategy_events strategy_relative_value strategy_global strategy_fund_of_funds strategy_multi method_iv model_1factor model_3factor model_4factor model_7factor model_uncertainty model_asset_based survivorship_treated backfilling_treated publication_year citations impact_factor, cluster(study_id)
ivreg2 alpha_w depvar_net_returns data_midyear database_cisdm number_of_databases market_bear strategy_fund_of_funds model_1factor backfilling_treated publication_year, cluster(study_id)

***************************************************************************************
* BEST-PRACTICE (SE calculation to BMA estimate)
***************************************************************************************

summarize number_of_databases data_midyear publication_year, detail
ivreg2 alpha_w se_w se_method_iv depvar_individual_funds depvar_equalw_funds depvar_net_returns data_cross_section data_midyear database_default database_cst database_cisdm database_handcollect number_of_databases market_developed market_bull market_bear strategy_all strategy_equity strategy_events strategy_relative_value strategy_global strategy_fund_of_funds strategy_multi method_iv model_1factor model_3factor model_4factor model_7factor model_uncertainty model_asset_based survivorship_treated backfilling_treated publication_year citations impact_factor, cluster(study_id)

*All strategies (at the sample mean)
lincom _cons+se_w*0+se_method_iv*0+depvar_individual_funds*0.17+depvar_equalw_funds*0.493621197+depvar_net_returns*1+data_cross_section*0+data_midyear*3.238678452+database_default*0.526987242+database_cst*0.251226693+database_cisdm*0.17468106+database_handcollect*0+number_of_databases*1.366045142+market_developed*0.137389598+market_bull*0.038272816+market_bear*0.038272816+strategy_all*0.238469087+strategy_equity*0.224730128+strategy_events*0.110893032+strategy_relative_value*0.092247301+strategy_global*0.153091266+strategy_fund_of_funds*0.065750736+strategy_multi*0.039254171+method_iv*1+model_1factor*0+model_3factor*0+model_4factor*0+model_7factor*0+model_uncertainty*1+model_asset_based*0+survivorship_treated*1+backfilling_treated*1+publication_year*3.044522438+citations*4.150164632+impact_factor*18.151
*Strategy: all funds
lincom _cons+se_w*0+se_method_iv*0+depvar_individual_funds*0.171736997+depvar_equalw_funds*0.493621197+depvar_net_returns*1+data_cross_section*0+data_midyear*3.238678452+database_default*0.526987242+database_cst*0.251226693+database_cisdm*0.17468106+database_handcollect*0+number_of_databases*1.366045142+market_developed*0.137389598+market_bull*0.038272816+market_bear*0.038272816+strategy_all*1+strategy_equity*0+strategy_events*0+strategy_relative_value*0+strategy_global*0+strategy_fund_of_funds*0+strategy_multi*0+method_iv*1+model_1factor*0+model_3factor*0+model_4factor*0+model_7factor*0+model_uncertainty*1+model_asset_based*0+survivorship_treated*1+backfilling_treated*1+publication_year*3.044522438+citations*4.150164632+impact_factor*18.151
*Strategy: equity hedge
lincom _cons+se_w*0+se_method_iv*0+depvar_individual_funds*0.171736997+depvar_equalw_funds*0.493621197+depvar_net_returns*1+data_cross_section*0+data_midyear*3.238678452+database_default*0.526987242+database_cst*0.251226693+database_cisdm*0.17468106+database_handcollect*0+number_of_databases*1.366045142+market_developed*0.137389598+market_bull*0.038272816+market_bear*0.038272816+strategy_all*0+strategy_equity*1+strategy_events*0+strategy_relative_value*0+strategy_global*0+strategy_fund_of_funds*0+strategy_multi*0+method_iv*1+model_1factor*0+model_3factor*0+model_4factor*0+model_7factor*0+model_uncertainty*1+model_asset_based*0+survivorship_treated*1+backfilling_treated*1+publication_year*3.044522438+citations*4.150164632+impact_factor*18.151
*Strategy: event driven
lincom _cons+se_w*0+se_method_iv*0+depvar_individual_funds*0.171736997+depvar_equalw_funds*0.493621197+depvar_net_returns*1+data_cross_section*0+data_midyear*3.238678452+database_default*0.526987242+database_cst*0.251226693+database_cisdm*0.17468106+database_handcollect*0+number_of_databases*1.366045142+market_developed*0.137389598+market_bull*0.038272816+market_bear*0.038272816+strategy_all*0+strategy_equity*0+strategy_events*1+strategy_relative_value*0+strategy_global*0+strategy_fund_of_funds*0+strategy_multi*0+method_iv*1+model_1factor*0+model_3factor*0+model_4factor*0+model_7factor*0+model_uncertainty*1+model_asset_based*0+survivorship_treated*1+backfilling_treated*1+publication_year*3.044522438+citations*4.150164632+impact_factor*18.151
*Strategy: relative value
lincom _cons+se_w*0+se_method_iv*0+depvar_individual_funds*0.171736997+depvar_equalw_funds*0.493621197+depvar_net_returns*1+data_cross_section*0+data_midyear*3.238678452+database_default*0.526987242+database_cst*0.251226693+database_cisdm*0.17468106+database_handcollect*0+number_of_databases*1.366045142+market_developed*0.137389598+market_bull*0.038272816+market_bear*0.038272816+strategy_all*0+strategy_equity*0+strategy_events*0+strategy_relative_value*1+strategy_global*0+strategy_fund_of_funds*0+strategy_multi*0+method_iv*1+model_1factor*0+model_3factor*0+model_4factor*0+model_7factor*0+model_uncertainty*1+model_asset_based*0+survivorship_treated*1+backfilling_treated*1+publication_year*3.044522438+citations*4.150164632+impact_factor*18.151
*Strategy: global
lincom _cons+se_w*0+se_method_iv*0+depvar_individual_funds*0.171736997+depvar_equalw_funds*0.493621197+depvar_net_returns*1+data_cross_section*0+data_midyear*3.238678452+database_default*0.526987242+database_cst*0.251226693+database_cisdm*0.17468106+database_handcollect*0+number_of_databases*1.366045142+market_developed*0.137389598+market_bull*0.038272816+market_bear*0.038272816+strategy_all*0+strategy_equity*0+strategy_events*0+strategy_relative_value*0+strategy_global*1+strategy_fund_of_funds*0+strategy_multi*0+method_iv*1+model_1factor*0+model_3factor*0+model_4factor*0+model_7factor*0+model_uncertainty*1+model_asset_based*0+survivorship_treated*1+backfilling_treated*1+publication_year*3.044522438+citations*4.150164632+impact_factor*18.151
*Strategy: fund of funds
lincom _cons+se_w*0+se_method_iv*0+depvar_individual_funds*0.171736997+depvar_equalw_funds*0.493621197+depvar_net_returns*1+data_cross_section*0+data_midyear*3.238678452+database_default*0.526987242+database_cst*0.251226693+database_cisdm*0.17468106+database_handcollect*0+number_of_databases*1.366045142+market_developed*0.137389598+market_bull*0.038272816+market_bear*0.038272816+strategy_all*0+strategy_equity*0+strategy_events*0+strategy_relative_value*0+strategy_global*0+strategy_fund_of_funds*1+strategy_multi*0+method_iv*1+model_1factor*0+model_3factor*0+model_4factor*0+model_7factor*0+model_uncertainty*1+model_asset_based*0+survivorship_treated*1+backfilling_treated*1+publication_year*3.044522438+citations*4.150164632+impact_factor*18.151
*Strategy: multi
lincom _cons+se_w*0+se_method_iv*0+depvar_individual_funds*0.171736997+depvar_equalw_funds*0.493621197+depvar_net_returns*1+data_cross_section*0+data_midyear*3.238678452+database_default*0.526987242+database_cst*0.251226693+database_cisdm*0.17468106+database_handcollect*0+number_of_databases*1.366045142+market_developed*0.137389598+market_bull*0.038272816+market_bear*0.038272816+strategy_all*0+strategy_equity*0+strategy_events*0+strategy_relative_value*0+strategy_global*0+strategy_fund_of_funds*0+strategy_multi*1+method_iv*1+model_1factor*0+model_3factor*0+model_4factor*0+model_7factor*0+model_uncertainty*1+model_asset_based*0+survivorship_treated*1+backfilling_treated*1+publication_year*3.044522438+citations*4.150164632+impact_factor*18.151
*Strategy: other
lincom _cons+se_w*0+se_method_iv*0+depvar_individual_funds*0.171736997+depvar_equalw_funds*0.493621197+depvar_net_returns*1+data_cross_section*0+data_midyear*3.238678452+database_default*0.526987242+database_cst*0.251226693+database_cisdm*0.17468106+database_handcollect*0+number_of_databases*1.366045142+market_developed*0.137389598+market_bull*0.038272816+market_bear*0.038272816+strategy_all*0+strategy_equity*0+strategy_events*0+strategy_relative_value*0+strategy_global*0+strategy_fund_of_funds*0+strategy_multi*0+method_iv*1+model_1factor*0+model_3factor*0+model_4factor*0+model_7factor*0+model_uncertainty*1+model_asset_based*0+survivorship_treated*1+backfilling_treated*1+publication_year*3.044522438+citations*4.150164632+impact_factor*18.151

clear
