
*PUBLICATION BIAS IN MEASURING OF ANTRHORPOGENIC CLIMATE CHANGE
set more off
************************************************************************
*LABELING OF VARIABLES
************************************************************************
rename volcanicforcing volcan
rename lowerbound low
rename upperbound up
rename se_lowse_up se_lowup
rename publicationyear puby
rename solarirradianceforcing solar
rename ozonforcing ozon
rename icesheet ice
rename numberofmodelsineachensemble model
rename ratingofsource cit
rename dumm_mean mea
rename dumm_median medi
rename modelling mo
************************************************************************
*DEFINITION OF BASIC VARIABLES
************************************************************************
gen prec = 1/se_low
gen tstat = estimate/se_low
gen tstat1=estimate/se_up
gen inter = se_low*se_lowup
gen prec_up=1/se_up
gen seuplow = se_up/se_low
gen inter2 = se_up*seuplow
gen mea1=mea/se_low
gen mea2=mea/se_up
gen tmean = mean/se_low
gen tmedian = median/se_low
gen puby1=puby/se_low         
gen model1=model/se_low       
gen cit1=cit/se_low
gen SE=se_low^2
gen meainter=mea*se_low

*********************************************************************** 
*KERNEL DENSITY
***********************************************************************
kdensity estimate, normal 

***********************************************************************
*FUNNEL and other PLOTS
***********************************************************************
scatter prec estimate, msize(*1) msymbol(Oh)
scatter prec estimate if prec < 10, msize(*1) msymbol(Oh)
scatter prec_up estimate, msize(*1) msymbol(Oh)

hist estimate, xlabel(0(0.5)5) width(0.764) normal 
hist tstat, width(0.564) normal 

graph twoway (scatter tstat prec, msize(*1) msymbol(Oh)) (lfit tstat prec)
graph twoway (scatter se_low estimate, msize(*1) msymbol (Oh)) (lfit se_low estimate)
graph twoway (scatter estimate se_low, msize(*1) msymbol (Oh)) (lfit estimate se_low) 

***********************************************************************
*SUMMARY OF CLIMATE CHANGE VARIABLES
***********************************************************************
sum 
summarize estimate if se_low<1

***********************************************************************
*TEST OF ASYMETRY OF THE FUNNEL PLOT
***********************************************************************
*SPECIFICATION (1)*
***********************************************************************
reg estimate se_low mea
ovtest
*1* robustness check
reg estimate se_up mea 
test se_up mea

***********************************************************************
*STUDY-LEVEL CLUSTER (2)*
***********************************************************************
reg estimate se_low mea, vce (cluster idstudy)
reg estimate se_up mea, vce (cluster idstudy) 
reg estimate se_low se_lowup mea, vce (cluster idstudy)
reg estimate se_low inter mea, vce (cluster idstudy) 

*regression on subsets when median or mean
reg median se_low, vce (cluster idstudy) 
reg mean se_low, vce (cluster idstudy) 


***********************************************************************
*ASYMETRY OF ESTIMATE DISTRIBUTION - PUBLICATION BIAS (3+4)*
***********************************************************************
reg estimate se_low se_lowup mea // se_lowup identifies the asymetric distribution
reg estimate se_low inter mea

**********************************************************************
*SPECIFICATION (5)*
**********************************************************************
reg tstat prec mea1, vce (cluster idstudy) 
reg tstat1 prec_up mea2, vce (cluster idstudy) // robustness check
reg tmean prec, vce (cluster idstudy) 
ovtest
reg tmedian prec, vce (cluster idstudy) 
ovtest
*********************************************************************
*SPECIFICATION (6)*
*********************************************************************
xtset idstudy
xtreg tstat prec mea1, fe vce (cluster idstudy)
xtreg tstat1 prec_up mea2, fe vce (cluster idstudy),
xtreg tmean prec, fe vce (cluster idstudy)
xtreg tmedian prec, fe vce (cluster idstudy)

*********************************************************************
*SPECIFICATION (7)*
*********************************************************************
xtset idstudy
xtmixed tstat prec mea1|| idstudy: , nolog,
xtmixed tstat1 prec_up mea2|| idstudy: , nolog,
xtmixed tmean prec|| idstudy: , nolog,
xtmixed tmedian prec|| idstudy: , nolog,

**********************************************************************
*ROBUSTNESS CHECK AND LR TEST*
**********************************************************************
xtmixed tstat prec mea1 || idstudy: , nolog,

xtmixed tstat prec  || idstudy: ||mea:, nolog,
quietly xtmixed tstat prec mea1 || idstudy: , nolog,

**********************************************************************
*STEPWISE REGRESSION
**********************************************************************
stepwise, pr(0.15) pe (0.1)lockterm1: regress tstat (prec mea1) mea puby1 asa solar cloud ozon volcan ice model1 cit1 mo, vce (cluster idstudy)
stepwise, pr(0.1) pe (0.05)lockterm1: regress tstat (prec mea1) mea puby1 asa solar cloud ozon volcan ice model1 cit1 mo, vce (cluster idstudy)

ovtest
stepwise, pr(0.15) pe (0.1) forward lockterm1: regress tstat (prec mea1) mea puby1 asa solar cloud ozon volcan ice model1 cit1 mo, vce (cluster idstudy)
stepwise, pr(0.1) pe (0.05) forward lockterm1: regress tstat (prec mea1) mea puby1 asa solar cloud ozon volcan ice model1 cit1 mo, vce (cluster idstudy)
stepwise, pr(0.2) pe (0.15) forward lockterm1: regress tstat (prec mea) puby1 asa solar cloud ozon volcan ice model1 cit1 mo, vce (cluster idstudy)

xtreg tstat (prec mea1) mea puby1 asa solar cloud ozon volcan ice model1 cit1 mo, fe  vce (cluster idstudy)
***********************************************************************
stepwise, pr(0.1) pe (0.05)lockterm1: regress tstat prec mea1 mea puby1 asa solar ozon ice model1 cit1 mo, vce (cluster idstudy)
stepwise, pr(0.1) pe (0.05) forward lockterm1: regress tstat prec mea1 mea puby1 asa solar ozon ice model1 cit1 mo, vce (cluster idstudy)

xtreg prec mea mea1 solar, fe vce(cluster idstudy)
reg prec mea mea1 solar,  vce(cluster idstudy)

**********************************************************************
*SPECIFICATION (8)*
**********************************************************************
reg tstat prec mea1 ice, vce (cluster idstudy)
xtmixed tstat prec mea1 ice|| idstudy: , nolog,
xtreg tstat prec mea1 ice, fe vce (cluster idstudy)
*********************************************************************
*CORECTING FOR PUBLICATION BIAS (9)*
*********************************************************************
xtmixed tstat prec mea1 se_low || idstudy: , nolog,
xtmixed tmean prec se_low || idstudy: , nolog,
xtmixed tmedian prec se_low || idstudy: , nolog,

xtreg tstat prec mea1 se_low, fe vce(cluster idstudy)
reg tstat prec mea1 se_low, vce (cluster idstudy)


reg tmean prec se_low, vce (cluster idstudy)
reg tmedian prec se_low, vce (cluster idstudy)

*********************************************************************
*ROBUSTNESS CHECK OF THE METHOD*
*********************************************************************
xtmixed estimate 
reg estimate
*********************************************************************
*CHECK FOR DIFFERENCES IN MEAN*
*********************************************************************
reg estimate se_low meainter 
reg estimate se_low meainter, vce (cluster idstudy)
xtmixed estimate se_low meainter
xtreg estimate se_low meainter, fe vce (cluster idstudy)


reg tstat prec mea, vce (cluster idstudy) 
xtmixed tstat prec mea|| idstudy: , nolog,
xtreg tstat prec mea, fe vce (cluster idstudy)
**********************************************************************
reg estimate se_low  
reg estimate se_low, vce (cluster idstudy)
xtmixed estimate se_low
xtreg estimate se_low, fe vce (cluster idstudy)

reg tstat prec, vce (cluster idstudy) 
xtmixed tstat prec || idstudy: , nolog,
xtreg tstat prec, fe vce (cluster idstudy)


exit, clear

