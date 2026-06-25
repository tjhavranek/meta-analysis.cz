
******************************************************************************
******************************************************************************
*FIRM SIZE AND STOCK RETURNS: A META-ANALYSIS
******************************************************************************
******************************************************************************
*May 11, 2017
log using size.log, replace
use size.dta, clear
set more off
******************************************************************************
*SUMMARY STATISTICS
******************************************************************************
gen prec = 1/se
gen invsqrtobs = 1/sqrt(obs)
estpost sum size tstat se prec invsqrtobs startyear endyear obs pubyear, detail 
esttab using sum.rtf, cells("mean(fmt(3)) p50(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") nomtitle nonumber replace

***
preserve
drop if missing(startyear)|startyear==0|missing(endyear)|endyear==0
keep if endyear<1981
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(Year less than 1981) nomtitle nonumber append
restore
***

***
preserve
drop if missing(startyear)|startyear==0|missing(endyear)|endyear==0
keep if startyear>=1982
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(Year after 1981) nomtitle nonumber append
restore
***

***
preserve
drop if missing(startyear)|startyear==0|missing(endyear)|endyear==0
keep if startyear>=1982 & endyear<=2000
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(Year between 1981 and 2000) nomtitle nonumber append
restore
***

***
preserve
drop if missing(startyear)|startyear==0|missing(endyear)|endyear==0
keep if startyear>=2000
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(Year after than 2000) nomtitle nonumber append
restore
***

***
preserve
keep if geo=="US"|geo=="AM"
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(Geo North America) nomtitle nonumber append
restore
***

***
preserve
keep if geo=="WE"|geo=="EE"
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(Geo Europe) nomtitle nonumber append
restore
***

***
preserve
keep if geo=="ASIA"|geo=="EMER"|geo=="SAM"|geo=="OTHER"
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(Geo Other) nomtitle nonumber append
restore
***

***
preserve
keep if stockex=="NYSE" & geo=="US"
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(Geo US, stockex NYSE only) nomtitle nonumber append
restore
***

***
preserve
keep if stockex!="NYSE" & geo=="US"
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(Geo US, stockex any) nomtitle nonumber append
restore
***

***
preserve
keep if jan==1
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(January only) nomtitle nonumber append
restore
***

***
preserve
keep if febdec==1|feb==1|mar==1|apr==1|may==1|jun==1|jul==1|aug==1|sep==1|oct==1|nov==1|dec==1|non_janjul==1
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(Not January) nomtitle nonumber append
restore
***

***
preserve
keep if OLS==1
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(OLS) nomtitle nonumber append
restore
***

***
preserve
drop if OLS==1
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(Not OLS) nomtitle nonumber append
restore
***

***
preserve
keep if indstock==1
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(Individual stock returns) nomtitle nonumber append
restore
***

***
preserve
keep if portfolio==1
estpost sum size  
esttab using sum.rtf, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") title(Portfolio returns) nomtitle nonumber append
restore
***

******************************************************************************
*PUBLICATION BIAS
******************************************************************************
*rename obs obs_old
*rename firms obs 
*drop if obs==0
*drop if size_other == 1
gen lnobs=ln(obs)
gen se_impact=se*impact
label var se_impact "SE*Impact"
gen se_pubyear=se*pubyear
label var se_pubyear "SE*Pub. Year"
label var se "SE"
gen invsqrtobs_impact=se*impact
gen invsqrtobs_pubyear=se*pubyear
quietly sum size, detail
local m = r(mean)
local median = r(p50)
scatter prec size if prec<110 & size<1.2 & size>-1.2, msize(*.6) msymbol(Oh) xline(`m', lp(solid) lcolor(gs0)) xline(`median', lp(dash) lcolor(gs0)) xtitle("Estimate of the size effect") ytitle("Precision of the estimate (1/SE)") saving(funnel, replace)
winsor2 size se prec tstat invsqrtobs, replace cuts (2.5 97.5)
******************************************************************************
sum size
bysort idstudy: egen emed = median(size)
bysort idstudy: egen precmed = median(prec)
bysort idstudy: egen semed = median(se)
bysort idstudy: egen tmed = median(tstat)
bysort idstudy: egen perstudy = count(size)
gen invperstudy = 1/perstudy
bysort idstudy: egen idmax = max(id)
gen last=0
replace last = 1 if idmax==id
xtset idstudy
******************************************************************************
quietly eststo: ivreg2 size se, cluster (idstudy geo)
quietly eststo: xtreg size se, fe vce(cluster idstudy)
quietly eststo: xtreg size se, be
quietly eststo: ivreg2 size se [pweight=prec], cluster (idstudy geo)
quietly eststo: ivreg2 size se [pweight=invperstudy], cluster (idstudy geo)
reg se invsqrtobs
*quietly eststo: ivreg2 size (se=invsqrtobs), cluster(idstudy country_region)
quietly eststo: xtivreg size (se=invsqrtobs), fe
esttab using reg.rtf, se star(* 0.10 ** 0.05 *** 0.01) mtitles("OLS" "FE" "BE" "Precision" "Study" "IV" "IV-FE") replace label nogap onecell
esttab, se star(* 0.10 ** 0.05 *** 0.01) mtitles("OLS" "FE" "BE" "Precision" "Study" "IV" "IV-FE") replace label nogap onecell
eststo clear
******************************************************************************
*INTERACTION COEFFICIENT (IMPACT FACTOR AND YEAR OF PUBLICATION)
******************************************************************************
quietly eststo: ivreg2 size se se_impact, cluster (idstudy geo)
quietly eststo: ivreg2 size se se_pubyear, cluster (idstudy geo)
quietly eststo: ivreg2 size se se_impact se_pubyear, cluster (idstudy geo)
esttab using reg_interactions.rtf, se star(* 0.10 ** 0.05 *** 0.01) mtitles("OLS" "OLS" "OLS") replace label nogap onecell
eststo clear

quietly eststo: xtreg size se se_impact, fe vce(cluster idstudy)
quietly eststo: xtreg size se se_pubyear, fe vce(cluster idstudy)
quietly eststo: xtreg size se se_impact se_pubyear, fe vce(cluster idstudy)
esttab using reg_interactions.rtf, se star(* 0.10 ** 0.05 *** 0.01) mtitles("FE" "FE" "FE") append label nogap onecell
eststo clear

quietly eststo: xtreg size se se_impact, be
quietly eststo: xtreg size se se_pubyear, be
quietly eststo: xtreg size se se_impact se_pubyear, be
esttab using reg_interactions.rtf, se star(* 0.10 ** 0.05 *** 0.01) mtitles("BE" "BE" "BE") append label nogap onecell
eststo clear

quietly eststo: ivreg2 size se se_impact [pweight=prec], cluster (idstudy geo)
quietly eststo: ivreg2 size se se_pubyear [pweight=prec], cluster (idstudy geo)
quietly eststo: ivreg2 size se se_impact se_pubyear [pweight=prec], cluster (idstudy geo)
esttab using reg_interactions.rtf, se star(* 0.10 ** 0.05 *** 0.01) mtitles("WLS - Precision" "WLS - Precision" "WLS - Precision") append label nogap onecell
eststo clear

quietly eststo: ivreg2 size se se_impact [pweight=invperstudy], cluster (idstudy geo)
quietly eststo: ivreg2 size se se_pubyear [pweight=invperstudy], cluster (idstudy geo)
quietly eststo: ivreg2 size se se_impact se_pubyear [pweight=invperstudy], cluster (idstudy geo)
esttab using reg_interactions.rtf, se star(* 0.10 ** 0.05 *** 0.01) mtitles("WLS - Invperstudy" "WLS - Invperstudy" "WLS - Invperstudy") append label nogap onecell
eststo clear

quietly eststo: xtivreg size (se=invsqrtobs) invsqrtobs_impact, fe
quietly eststo: xtivreg size (se=invsqrtobs) invsqrtobs_pubyear, fe 
quietly eststo: xtivreg size (se=invsqrtobs) invsqrtobs_impact invsqrtobs_pubyear, fe 
esttab using reg_interactions.rtf, se star(* 0.10 ** 0.05 *** 0.01) mtitles("OLS" "OLS" "OLS" "FE" "FE" "FE") append label nogap onecell
eststo clear

*esttab, se star(* 0.10 ** 0.05 *** 0.01) mtitles("OLS" "OLS" "OLS" "FE" "FE" "FE") replace label nogap onecell
******************************************************************************
*FOR SIZE RISK PREMIUM
******************************************************************************
preserve
keep if monthly == 1
keep if geo == "US"
estpost sum size 
quietly eststo: ivreg2 size se, cluster (idstudy)
esttab, se star(* 0.10 ** 0.05 *** 0.01) mtitles("OLS") replace label nogap onecell
eststo clear
restore
******************************************************************************
*HEDGES' TEST FOR PUBLICATION BIAS
******************************************************************************
set more off
global t1=invnormal(1-.5*.01)
global t2=invnormal(1-.5*.05)
global t3=invnormal(1-.5*.10)
dis %8.3f $t1 %8.3f $t2 %8.3f $t3

gen group=1
replace group=2 if tstat<$t1
replace group=3 if tstat<$t2
replace group=4 if tstat<$t3

program hedges1
         version 13.0
         args todo b lnf
         tempvar theta1 sigma l eta
         mleval `theta1' = `b', eq(1)
         mleval `sigma'=`b', eq(2)

         gen double `eta'=sqrt(se*se+`sigma'*`sigma')

         quietly gen double `l' = -ln(`eta')-.5*(($ML_y1-`theta1')/`eta')^2
         mlsum `lnf' = `l'
end

program hedges2
         version 13.0
         args todo b lnf
         tempvar theta1 sigma l lg lgg g1 g2 g3 g4 eta
         mleval `theta1' = `b', eq(1)
         mleval `sigma'=`b', eq(2)
         mleval `g2'=`b', eq(3)
         mleval `g3'=`b', eq(4)
         mleval `g4'=`b', eq(5)

         gen double `eta'=sqrt(se*se+`sigma'*`sigma')
         gen double `g1'=1
         quietly gen double `lg'=`g1' if group==1
         quietly replace `lg'=(1-`g2') if group==2
         quietly replace `lg'=(1-`g3') if group==3
         quietly replace `lg'=(1-`g4') if group==4
         quietly gen double `lgg'=`g1'*(1-normal(($t1*se-`theta1')/`eta'))
         quietly replace `lgg'=`lgg'+(1-`g2')*(normal(($t1*se-`theta1')/`eta')-normal(($t2*se-`theta1')/`eta'))
         quietly replace `lgg'=`lgg'+(1-`g3')*(normal(($t2*se-`theta1')/`eta')-normal(($t3*se-`theta1')/`eta'))
         quietly replace `lgg'=`lgg'+(1-`g4')*(normal(($t3*se-`theta1')/`eta'))
         quietly gen double `l' =-ln(`eta')-.5*(($ML_y1-`theta1')/`eta')^2+ln(`lg')-ln(`lgg')
         mlsum `lnf' = `l'
end

ml model d0 hedges1 (equation:size = ) (sigma:)
ml maximize
gen ll1=e(ll)
ml model d0 hedges2 (equation:size = ) (sigma:)(g2:)(g3:)(g4:)
ml maximize
gen ll2=e(ll)
gen lldiff12=2*abs(ll1-ll2)
display chi2tail(3, lldiff12)
display lldiff12
******************************************************************************
