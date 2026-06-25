******************************************************************************
******************************************************************************
*THE BORDER EFFECT IN TRADE: A META-ANALYSIS
******************************************************************************
******************************************************************************
*Stata 12.0
*February 3, 2014 
log using border.log, replace
use border.dta, clear
set more off
******************************************************************************
*DEFINITION OF VARIABLES
******************************************************************************
gen prec = 1/se
replace avyear = avyear - 1899
gen lncsunits=ln(csunits)
gen lnyears = ln(years)
gen lnobs = ln(nobs)
replace firstpub = firstpub - 1995
gen lnyearcits = ln(yearcits + 1)
xtset idstudy
bysort idstudy: egen bmed = median(b)
bysort idstudy: egen precmed = median(prec)
bysort idstudy: egen semed = median(se)
bysort idstudy: egen tmed = median(tstat)
egen idcountry = group(border)
******************************************************************************
label variable b "Coefficient on the dummy variable 'within-country trade' estimated in a gravity equation."
label variable se "Estimated standard error of Home."
label variable avyear "Midpoint of the sample on which the gravity equation is estimated (base: 1899)."
label variable panel "= 1 if panel data are used in the gravity equation."
label variable disagg "= 1 if data are disaggregated at the sector level."
label variable lncsunits "Log of the number of observations per year included in the gravity equation."
label variable lnyears "Log of the number of years in the data."
label variable canada "=1 if the border effect is estimated for Canada."
label variable us "=1 if the border effect is estimated for the US."
label variable eu "=1 if the border effect is estimated for the EU."
label variable oecd "=1 if the border effect is estimated for OECD countries."
label variable emerg "=1 if the border effect is estimated for developing or transition countries."
label variable nointflow "=1 if within-country trade flows are not observed but estimated using production data."
label variable ddiff "=1 if within-country distance is measured differently from between-country distance."
label variable dactual "=1 if actual distance traveled by road or sea is used instead of the great-circle formula."
label variable totalt "=1 if total trade is used as the dependent variable and imports and exports are summed before taking logs."
label variable asym "=1 if the estimate measures the difficulty of cross-border flows in one direction."
label variable gdpendog "=1 if instruments are used to correct for the endogeneity of GDP."
label variable remote "=1 if remoteness terms are included."
label variable countryfe "=1 if destination and origin fixed effects are included."
label variable ratio "=1 if trade flows are normalized by trade with self."
label variable avw "=1 if the nonlinear estimation method developed by Anderson and van Wincoop is used."
label variable nores "=1 if gravity equation does not account for multilateral resistance terms."
label variable plusone "=1 if one is added to observations of zero trade flows."
label variable tobit "=1 if gravity equation is estimated by the Tobit model."
label variable ppml "=1 if gravity equation is estimated by the Pseudo Poisson Maxmimum Likelihood estimator."
label variable nozeros "=1 if observations of zero trade flows are omitted."
label variable adjacency "= 1 if gravity equation controls for adjacency."
label variable language "= 1 if gravity equation controls for shared language (when needed)."
label variable fta "= 1 if gravity equation controls for free trade agreements (when needed)."
label variable published "= 1 if the study is published in a peer-reviewed journal."
label variable impact "Recursive discounted RePEc impact factor of the outlet (collected in January 2014)."
label variable lnyearcits "Log of the mean number of Google Scholar citations received per year since the study appeared in Google Scholar (collected in January 2014)."
label variable firstpub "Year when the study first appeared in Google Scholar (base: 1995)."
******************************************************************************
*SUMMARY STATISTICS AND PLOTS
******************************************************************************
sum b se avyear panel disagg lncsunits lnyears canada us eu oecd emerg nointflow ddiff dactual totalt asym gdpendog remote countryfe ratio avw nores plusone tobit ppml nozeros adjacency language fta published impact lnyearcits firstpub
sum b se avyear panel disagg lncsunits lnyears canada us eu oecd emerg nointflow ddiff dactual totalt asym gdpendog remote countryfe ratio avw nores plusone tobit ppml nozeros adjacency language fta published impact lnyearcits firstpub [aweight=invperst]
corr b se avyear panel disagg lncsunits lnyears canada us eu oecd emerg nointflow ddiff dactual totalt asym gdpendog remote countryfe ratio avw nores plusone tobit ppml nozeros adjacency language fta published impact lnyearcits firstpub [aweight=invperst]
sum tstat, det
centile b, centile(1(1)99)
mean b
sum b if idstudy==1 | idstudy==17 | idstudy==18 | idstudy==19 | idstudy==25 | idstudy == 36 | idstudy==38 | idstudy==40 | idstudy==52 | idstudy ==54 | idstudy ==58, detail
mean b [aweight=invperst]
mean bmed if last==1
hist b
graph twoway (scatter bmed firstpub if last==1, msize(*1.5) msymbol(Oh)) (lfit bmed firstpub if last==1) saving(trend, replace)
graph hbox b, over(study) xsize(6.3) ysize(8) scale(0.4) saving(box, replace)
******************************************************************************
ivreg2 b if canada==1, cluster (idstudy idcountry2)
ivreg2 b if us==1, cluster (idstudy idcountry2)
ivreg2 b if eu==1, cluster (idstudy idcountry2)
ivreg2 b if oecd==1, cluster (idstudy idcountry2)
ivreg2 b if emerg==1, cluster (idstudy idcountry2)
ivreg2 b, cluster (idstudy idcountry2)
ivreg2 b if canada==1 [pweight=invperst], cluster (idstudy idcountry2)
ivreg2 b if us==1 [pweight=invperst], cluster (idstudy idcountry2)
ivreg2 b if eu==1 [pweight=invperst], cluster (idstudy idcountry2)
ivreg2 b if oecd==1 [pweight=invperst], cluster (idstudy idcountry2)
ivreg2 b if emerg==1 [pweight=invperst], cluster (idstudy idcountry2)
ivreg2 b [pweight=invperst], cluster (idstudy idcountry2)
sum b if canada==1, detail
sum b if us==1, detail
sum b if eu==1, detail
sum b if oecd==1, detail
sum b if emerg==1, detail
sum b, cluster detail
sum b if canada==1 [aweight=invperst], detail
sum b if us==1 [aweight=invperst], detail
sum b if eu==1 [aweight=invperst], detail
sum b if oecd==1 [aweight=invperst], detail
sum b if emerg==1 [aweight=invperst], detail
sum b [aweight=invperst], detail
******************************************************************************
scatter prec b, msize(*.9) msymbol(Oh) saving(funnel_all, replace)
scatter precmed bmed, msize(*.9) msymbol(Oh) saving(funnel_perstudy, replace)
******************************************************************************
*FUNNEL ASYMMETRY TESTS
******************************************************************************
eststo: ivreg2 b se, cluster (idstudy idcountry2)
eststo: ivreg2 b se if published==1, cluster(idstudy idcountry2)
eststo: xtreg b se, fe vce(cluster idstudy)
eststo: ivreg2 b (se=lncsunits), cluster(idstudy idcountry2)
esttab using fat1.tex, se booktabs replace compress title(Funnel asymmetry test\label{tab:fat}) mtitles("1" "2" "3" "4") addnote("Standard errors are clustered at the study level.") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear
eststo: ivreg2 b se [pweight=prec], cluster(idstudy idcountry2)
eststo: ivreg2 b se [pweight=invperst*prec], cluster(idstudy idcountry2)
eststo: ivreg2 b se [pweight=invperst*prec*impact], cluster(idstudy idcountry2)
eststo: ivreg2 b se [pweight=invperst*prec*impact*yearcits], cluster(idstudy idcountry2)
esttab using fat2.tex, se booktabs replace compress title(Funnel asymmetry test\label{tab:fat}) mtitles("1" "2" "3" "4") addnote("Standard errors are clustered at the study level.") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear
******************************************************************************
*HETEROGENEITY
******************************************************************************
ivreg2 b avyear panel disagg lncsunits lnyears canada us eu oecd emerg nointflow ddiff dactual totalt asym gdpendog remote countryfe ratio avw nores plusone tobit ppml nozeros adjacency language fta published impact lnyearcits firstpub [pweight=invperst], cluster(idstudy idcountry2)
test panel lncsunits totalt gdpendog remote plusone nozeros adjacency language impact lnyearcits
ivreg2 b avyear disagg lnyears canada us eu oecd emerg nointflow ddiff dactual asym countryfe ratio avw nores tobit ppml fta published firstpub [pweight=invperst], cluster(idstudy idcountry2)
lincom _cons + avyear*112 + disagg*1 + lnyears*3.295837 + canada*0.1774262 + us*0.0790656 + eu*0.2329925 + oecd*0.0641344 + emerg*0.0506688 + ddiff*0 + dactual*1 + asym*0 + ratio*0.1147541 + nores*0 + tobit*0 + ppml*1 + fta*1 + published*1 + firstpub*9.622951 + nointflow*0 + countryfe*0.3122863 + avw*0.0634116 
lincom _cons + avyear*112 + disagg*1 + lnyears*3.295837 + canada*1 + ddiff*0 + dactual*1 + asym*0 + ratio*0.1147541 + nores*0 + tobit*0 + ppml*1 + fta*1 + published*1 + firstpub*9.622951 + nointflow*0 + countryfe*0.3122863 + avw*0.0634116 
lincom _cons + avyear*112 + disagg*1 + lnyears*3.295837 + us*1 + ddiff*0 + dactual*1 + asym*0 + ratio*0.1147541 + nores*0 + tobit*0 + ppml*1 + fta*1 + published*1 + firstpub*9.622951 + nointflow*0 + countryfe*0.3122863 + avw*0.0634116 
lincom _cons + avyear*112 + disagg*1 + lnyears*3.295837 + eu*1 + ddiff*0 + dactual*1 + asym*0 + ratio*0.1147541 + nores*0 + tobit*0 + ppml*1 + fta*1 + published*1 + firstpub*9.622951 + nointflow*0 + countryfe*0.3122863 + avw*0.0634116 
lincom _cons + avyear*112 + disagg*1 + lnyears*3.295837 + oecd*1 + ddiff*0 + dactual*1 + asym*0 + ratio*0.1147541 + nores*0 + tobit*0 + ppml*1 + fta*1 + published*1 + firstpub*9.622951 + nointflow*0 + countryfe*0.3122863 + avw*0.0634116 
lincom _cons + avyear*112 + disagg*1 + lnyears*3.295837 + emerg*1 + ddiff*0 + dactual*1 + asym*0 + ratio*0.1147541 + nores*0 + tobit*0 + ppml*1 + fta*1 + published*1 + firstpub*9.622951 + nointflow*0 + countryfe*0.3122863 + avw*0.0634116
ivreg2 b avyear disagg lnyears canada us eu oecd emerg nointflow ddiff dactual asym countryfe ratio avw nores tobit ppml adjacency fta published firstpub [pweight=invperst], cluster(idstudy idcountry2)
lincom _cons + avyear*112 + disagg*1 + lnyears*3.295837 + canada*0.1774262 + us*0.0790656 + eu*0.2329925 + oecd*0.0641344 + emerg*0.0506688 + ddiff*0 + dactual*1 + asym*0 + ratio*0.1147541 + nores*0 + tobit*0 + ppml*1 + fta*1 + published*1 + firstpub*9.622951 + nointflow*0 + countryfe*0.3122863 + avw*0.0634116 + adjacency*1
lincom _cons + avyear*112 + disagg*1 + lnyears*3.295837 + canada*1 + ddiff*0 + dactual*1 + asym*0 + ratio*0.1147541 + nores*0 + tobit*0 + ppml*1 + fta*1 + published*1 + firstpub*9.622951 + nointflow*0 + countryfe*0.3122863 + avw*0.0634116  + adjacency*1
lincom _cons + avyear*112 + disagg*1 + lnyears*3.295837 + us*1 + ddiff*0 + dactual*1 + asym*0 + ratio*0.1147541 + nores*0 + tobit*0 + ppml*1 + fta*1 + published*1 + firstpub*9.622951 + nointflow*0 + countryfe*0.3122863 + avw*0.0634116 + adjacency*1
lincom _cons + avyear*112 + disagg*1 + lnyears*3.295837 + eu*1 + ddiff*0 + dactual*1 + asym*0 + ratio*0.1147541 + nores*0 + tobit*0 + ppml*1 + fta*1 + published*1 + firstpub*9.622951 + nointflow*0 + countryfe*0.3122863 + avw*0.0634116 + adjacency*1
lincom _cons + avyear*112 + disagg*1 + lnyears*3.295837 + oecd*1 + ddiff*0 + dactual*1 + asym*0 + ratio*0.1147541 + nores*0 + tobit*0 + ppml*1 + fta*1 + published*1 + firstpub*9.622951 + nointflow*0 + countryfe*0.3122863 + avw*0.0634116 + adjacency*1
lincom _cons + avyear*112 + disagg*1 + lnyears*3.295837 + emerg*1 + ddiff*0 + dactual*1 + asym*0 + ratio*0.1147541 + nores*0 + tobit*0 + ppml*1 + fta*1 + published*1 + firstpub*9.622951 + nointflow*0 + countryfe*0.3122863 + avw*0.0634116 + adjacency*1
ivreg2 b avyear panel disagg lncsunits canada us eu oecd emerg nointflow dactual nores plusone tobit ppml adjacency impact lnyearcits firstpub, cluster(idstudy idcountry2)
lincom _cons + avyear*112 + panel*1 + disagg*1 + lncsunits*11.77141 + canada*0.1675846+ us*0.0503541+ eu*0.2069237+ oecd*0.0771046+ emerg*0.0645161+ nointflow*0+ dactual*1+ nores*0+ plusone*0+ tobit*0+ ppml*1+ adjacency*1+ impact*4.153+ lnyearcits*5.563425+ firstpub*9.461054
lincom _cons + avyear*112 + panel*1 + disagg*1 + lncsunits*11.77141 + canada*1+ nointflow*0+ dactual*1+ nores*0+ plusone*0+ tobit*0+ ppml*1+ adjacency*1+ impact*4.153+ lnyearcits*5.563425+ firstpub*9.461054
lincom _cons + avyear*112 + panel*1 + disagg*1 + lncsunits*11.77141 + us*1+ nointflow*0+ dactual*1+ nores*0+ plusone*0+ tobit*0+ ppml*1+ adjacency*1+ impact*4.153+ lnyearcits*5.563425+ firstpub*9.461054
lincom _cons + avyear*112 + panel*1 + disagg*1 + lncsunits*11.77141 + eu*1+ nointflow*0+ dactual*1+ nores*0+ plusone*0+ tobit*0+ ppml*1+ adjacency*1+ impact*4.153+ lnyearcits*5.563425+ firstpub*9.461054
lincom _cons + avyear*112 + panel*1 + disagg*1 + lncsunits*11.77141 + oecd*1+ nointflow*0+ dactual*1+ nores*0+ plusone*0+ tobit*0+ ppml*1+ adjacency*1+ impact*4.153+ lnyearcits*5.563425+ firstpub*9.461054
lincom _cons + avyear*112 + panel*1 + disagg*1 + lncsunits*11.77141 + emerg*1+ nointflow*0+ dactual*1+ nores*0+ plusone*0+ tobit*0+ ppml*1+ adjacency*1+ impact*4.153+ lnyearcits*5.563425+ firstpub*9.461054
******************************************************************************
*BAYESIAN MODEL AVERAGING
******************************************************************************
*//Switch to R
*//load library
*library(BMS)
*//read data from excel (press ctrl-c)
*//data in the form: 1 column explained variable, other columns explanatory variables.
*databorder=read.table("clipboard-512", sep="\t", header=TRUE)
*//load unweighted data
*databorder3=read.table("clipboard-512", sep="\t", header=TRUE)
******************************************************************************
*//Starts estimation
*border = bms(databorder, burn=1000000, iter=2000000, g="UIP", mprior="uniform", nmodel=5000, mcmc="bd", user.int=FALSE)
*border2 = bms(databorder, burn=1000000, iter=2000000, g="BRIC", mprior="random", nmodel=5000, mcmc="bd", user.int=FALSE)
*border3 = bms(databorder3, burn=1000000, iter=2000000, g="UIP", mprior="uniform", nmodel=5000, mcmc="bd", user.int=FALSE)
******************************************************************************
*//Diagnostics
*plot(border)
*summary(border)
*plot(border2)
*summary(border2)
*plot(border3)
*summary(border3)
******************************************************************************
*//Results
*coef(border, order.by.pip = F, exact=T, include.constant=T)
*image(border, cex.axis=0.7, order.by.pip = T, yprop2pip=F)
*print(border$topmod[1]) //included variables in the best model
*coef(border2, order.by.pip = F, exact=T, include.constant=T)
*image(border2, cex.axis=0.7, order.by.pip = T, yprop2pip=F)
*print(border2$topmod[1]) //included variables in the best model
*coef(border3, order.by.pip = F, exact=T, include.constant=T)
*image(border3, cex.axis=0.7, order.by.pip = T, yprop2pip=F)
*print(border3$topmod[1]) //included variables in the best model
******************************************************************************
*//Posterior density
*density(border, reg="nores")
*density(border2, reg="nores")
*density(border3, reg="nores")
******************************************************************************
*REVISION
******************************************************************************
gen income2 = abs(1-income)
sum size tariff ntb findev volatility income2 pride internet ruleoflaw
corr size tariff ntb findev volatility income2 pride internet ruleoflaw
corr size tariff ntb findev volatility income2 pride internet ruleoflaw avyear disagg lnyears nointflow ddiff dactual asym countryfe ratio avw nores tobit ppml adjacency fta published firstpub
eststo: ivreg2 b size tariff ntb [pweight=invperst], cluster(idstudy idcountry2)
eststo: ivreg2 b size tariff ntb findev volatility income2 pride internet ruleoflaw [pweight=invperst], cluster(idstudy idcountry2)
eststo: ivreg2 b size tariff ntb findev volatility income2 pride internet ruleoflaw avyear disagg lnyears nointflow ddiff dactual asym countryfe ratio avw nores tobit ppml adjacency fta published firstpub [pweight=invperst], cluster(idstudy idcountry2)
esttab using country.tex, se booktabs replace wide title(Country heterogeneity\label{tab:country}) mtitles("1" "2" "3") addnote("Standard errors are clustered at the study level.") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear

window manage close graph
log close
exit, clear
******************************************************************************
******************************************************************************

