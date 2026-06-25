******************************************************************************
******************************************************************************
******************************************************************************
*WHAT DETERMINES FDI SPILLOVERS?
*EVIDENCE FROM A LARGE META-ANALYSIS
******************************************************************************
cd C:\Study\Papers\10_Spillover_Determinants\stata
log using "determinants.log", replace
use "determinants.dta", clear
set more off
******************************************************************************
*DEFINITION OF BASIC VARIABLES
******************************************************************************
drop if aux==1
drop aux
gen back= ((horiz==0 & forw==0) | (horiz==0 & local==1))
gen prec=1/se
gen top= (idstudy==5| idstudy==6| idstudy==7| idstudy==16| idstudy==17| idstudy==22| idstudy==23) // Top journals
gen tb=eb/seb
gen precb=1/seb
gen tf=ef/sef
gen precf=1/sef
gen th=eh/seh
gen prech=1/seh
******************************************************************************
drop if horiz!=1
******************************************************************************
*DEFINITIONS OF VARIABLES FOR MULTIPLE MRA
******************************************************************************
gen nloglin=lin==1|loglog==1
drop lin loglog
replace diff=diff==1|ldiff==1
drop ldiff
gen ac=tgap==1|rd==1
drop rd tgap
replace output=output==1|va==1
drop va
drop square auto food text balan
replace jcrcit=jcrcit/(2010.6-pubdate)
replace scocit=scocit/(2010.6-pubdate)
replace schcit=schcit/(2010.6-pubdate)
replace repcit=repcit/(2010.6-pubdate)
gen lnjcrcit=ln(1+jcrcit)
gen lnscocit=ln(1+scocit)
gen lnschcit=ln(1+schcit)
gen lnrepcit=ln(1+repcit)
gen lnciteaut=ln(1+citeaut)
drop jcrcit scocit schcit repcit citeaut
gen avgyear=(end+start)/2 - 2000
gen tspan=(end-start+1)
gen firms=nobs/tspan
replace firms=nobs if cs==1
gen lnfirms=ln(firms)
drop firms nobs
gen lndist=ln(dist)
gen lngap=ln(gap)
gen lngap2=lngap^2
drop dist gap
replace pubdate=pubdate-2000
replace human=human/100
replace fdiint=fdiint/100
gen onestep=output==1|lp==1
drop output lp
drop  table orige origse mean1 mean2 start end nat realpart forpart nace io check comment
replace findev=findev/100
replace open=open/100
******************************************************************************
******************************************************************************
*LABELS OF VARIABLES
******************************************************************************
label variable lndist "Distance"
label variable lngap	 "Technology gap"
label variable open	 "Trade openness"
label variable findev	 "Financial dev."
label variable gp95	 "Patent rights"
label variable green	 "Fully owned"
label variable serv	 "Service sectors"
label variable prec	 "1/SE"
label variable cs	 "Cross-sectional"
label variable aggr	 "Aggregated"
label variable tspan	 "Time span"
label variable lnfirms	 "No. of Firms"
label variable avgyear	 "Average year"
label variable amad	 "Amadeus"
label variable bothbf	 "Forward"
label variable bothvh	 "Horizontal"
label variable empl	 "Employment"
label variable asset	 "Equity"
label variable allfirm	 "All firms"
label variable ac	 "Absorption cap."
label variable scomp	 "Competition"
label variable cycl	 "Cyclicality"
label variable local	 "Regional"
label variable lag	 "Lagged"
label variable more	 "More estimates"
label variable comb	 "Combination"
label variable onestep	 "One step"
label variable op	 "Olley-Pakes"
label variable ols	 "OLS"
label variable gmm	 "GMM"
label variable rand	 "Random eff."
label variable pols	 "Pooled OLS"
label variable yearfe	 "Year fixed"
label variable sectfe	 "Sector fixed"
label variable diff	 "Differences"
label variable translog	 "Translog"
label variable nloglin	 "Log-log"
label variable pub	 "Published"
label variable repimp	 "Impact"
label variable lnschcit	 "Study citations"
label variable native	 "Native co-author"
label variable lnciteaut	 "Author citations"
label variable affusa	 "US-based"
label variable pubdate	 "Publication date"
label variable sim "Similarity"
label variable fdiint "FDI penetration"
label variable human "Human capital"
******************************************************************************
*SUMMARY
******************************************************************************
hadimvo e, gen(odd) p(0.05)
by odd, sort : summarize e
drop if abs(e)>10
local allvariables lngap open findev gp95 sim human fdiint lag avgyear allfirm green serv empl cs aggr lnfirms tspan  amad onestep gmm op ols pols rand yearfe sectfe translog nloglin diff bothbf asset ac scomp local more comb repimp lnschcit pub native lnciteaut affusa pubdate
foreach x of varlist `allvariables' {
				gen `x'_se = `x' / se
}
sum e `allvariables'
correl `allvariables'
collin `allvariables'
*kdensity e if abs(e)<1
******************************************************************************
*PUBLICATION BIAS (none found)
******************************************************************************
xtset idstudy
xtreg t prec, fe vce(cluster idstudy)
xi: xtreg t prec i.idcountry, fe vce(cluster idstudy)
scatter prec  e if prec<100 & abs(e)<5, saving(funnel, replace) msize(*.7) msymbol(Oh)
******************************************************************************
*HETEROGENEITY
******************************************************************************
graph hbox e if country=="China", over(study) saving(box, replace) nooutside
reg e lngap sim open findev gp95 human fdiint green serv cs aggr bothbf empl local lnschcit lnciteaut, vce(cluster idcountry)
******************************************************************************
*SIMPLE META-ANALYSIS
mean e  // -0.002
metan e se, fixed // 0.017
metan e se, random // -0.011


log close
******************************************************************************
******************************************************************************
******************************************************************************