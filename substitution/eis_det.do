******************************************************************************
******************************************************************************
*WHY DO ESTIMATES OF THE ELASTICITY OF INTERTEMPORAL SUBSTITUTION VARY?
*A META-ANALYSIS
******************************************************************************
*Stata 12.0
*July 1, 2013
log using eis_det.log, replace
use eis_det.dta, clear
set more off
******************************************************************************
*DEFINITION OF VARIABLES
******************************************************************************
label variable eis "Estimate of the elasticity of intertemporal substitution (response variable)"
label variable marketpartic "The fraction of households participating in the domestic stock market"
label variable gdppc "Gross domestic product per capita at purchasing-power-adjusted 2005 dollars"
label variable eascredit "The ease of access to loans"
label variable finref "The IMF's financial reform index"
label variable realrate "The lending interest rate adjusted for inflation as measured by the GDP deflator"
label variable ruleoflaw "The extent to which agents have confidence in the rules of the society"
label variable trust "Perceptions of general trust in the society"
label variable impact "The recursive RePEc impact factor of the outlet"
label variable cits "The number of Google Scholar citations of the study "
label variable yearcits "The number of per-year citations of the study"
label variable pubyear "The year of publication of the study"
label variable micro "=1 if the coefficient comes from a micro-level estimation"
label variable panel "=1 if panel data are used"
label variable quasipan "=1 if quasipanel (synthetic cohort) data are used"
label variable seprisk "=1 if the estimation differentiates between EIS and the coefficient of relative risk aversion"
label variable sepdur "=1 if the model allows for nonseparability between durables and nondurables"
label variable seplab "=1 if the model allows for non-separabilities between consumption and labor supply"
label variable sepgov "=1 if the model allows for nonseparability between private and public consumption"
label variable inverse "=1 if the interest rate is the dependent variable in the estimation"
label variable secord "=1 if second-order approximation is used"
label variable exact "=1 if the exact Euler equation is estimated"
label variable yearfe "=1 if year dummies are included"
label variable totalc "=1 if total consumption is used in the estimation"
label variable food "=1 if food is used as a proxy for nondurables"
label variable tastes "The number of controls for taste shifters"
label variable ml "=1 if maximum likelihood methods are used for estimation"
label variable tsls "=1 if two-stage least squares are used for estimation"
label variable coint "=1 if cointegrating regression is used for estimation"
label variable ols "=1 if ordinary least squares are used for estimation"
label variable bayes "=1 if Bayesian methods are used for estimation"
label variable income "=1 if income is included in the specification"
label variable inflinst "=1 if lags of inflation are included among instruments"
label variable firstlag "=1 if the first lags of variables are included among instruments"
label variable stockhold "=1 if the estimate corresponds to the subsample of rich or strockholders"
label variable nonstock "=1 if the estimate is for non-stockholders or poor"
label variable habits "=1 if habits in consumption are assumed"
label variable irstock "=1 if the interest rate is measured as stock return"
label variable ircap "=1 if the interest rate is measured as the return on capital"
label variable country "The country for which the elasticity is estimated"
label variable annual "=1 if data frequency is annual"
label variable monthly "=1 if data frequency is monthly"
label variable start "The start of the data period"
label variable end "The end of the data period"
label variable startyear "The start year of the data period"
label variable endyear "The end year of the data period"
label variable avyear "The average year of the data period"
label variable years "The number of years of the data period used in the estimation"
label variable obs "The number of observations"
label variable csunits "The number of cross-sectional units used in the estimation (households, cohorts, countries)"
label variable periods "The number of time units used in the estimation"
label variable septrd "=1 if the model allows for nonseparability between tradables and nontradables"
label variable perstudy "The number of observations per study"
******************************************************************************
gen prec = 1/se
gen tstat = eis/se
gen lnobs=ln(obs)
gen lncsunits=ln(csunits)
gen lnpubyear=ln(pubyear)
gen lnyears = ln(years)
gen lnavyear = ln(avyear)
gen lnyearcits = ln(yearcits + 1)
gen lntastes = ln(tastes + 1)
gen noyearfe = 0
replace noyearfe = 1 if micro==1 & quasipan==0 & food==1 & yearfe==0
gen invperstudy = 1/perstudy
replace gdppc = ln(gdppc)
******************************************************************************
*SUMMARY STATISTICS AND PLOTS
******************************************************************************
sum eis if abs(eis)<10
mean eis [pw=invperstudy] if abs(eis)<10
mean eis [pw=invperstudy*impact] if abs(eis)<10
mean eis [pw=invperstudy*impact*lnyearcits] if abs(eis)<10
sum marketpartic gdppc eascredit finref realrate ruleoflaw trust micro stockhold lncsunits lnyears lnavyear annual monthly seprisk habits sepdur sepgov septrd quasipan inverse firstlag noyearfe income lntastes totalc food irstock ircap exact ml tsls ols lnpubyear lnyearcits top impact
corr gdppc eascredit realrate ruleoflaw micro stockhold lncsunits lnyears lnavyear annual monthly seprisk habits sepdur sepgov septrd quasipan inverse firstlag noyearfe income lntastes totalc food irstock ircap exact ml tsls ols lnpubyear lnyearcits top impact if abs(eis)<10
corr marketpartic gdppc eascredit realrate ruleoflaw micro stockhold lncsunits lnyears lnavyear annual monthly seprisk habits sepdur sepgov septrd quasipan inverse firstlag noyearfe income lntastes totalc food irstock ircap exact ml tsls ols lnpubyear lnyearcits top impact if abs(eis)<10
bysort idcountry: egen med = median(eis)
bysort idcountry: egen mean = mean(eis) if abs(eis)<10
bysort idcountry: egen semean = semean(eis) if abs(eis)<10
bysort idcountry: egen count = count(eis)
graph hbox eis if country=="Japan" & abs(eis)<10, over(study) saving(box, replace)
******************************************************************************
*DATA PREPARATION FOR BMA
******************************************************************************
order eis marketpartic gdppc finref eascredit realrate ruleoflaw trust seprisk habits sepdur sepgov septrd  lncsunits lnyears lnavyear micro annual monthly quasipan inverse stockhold firstlag noyearfe income lntastes totalc food irstock ircap exact ml tsls ols lnpubyear lnyearcits top impact
drop if abs(eis)>=10
saveold "eis_det_bma.dta"
******************************************************************************
*BMA, ALL COUNTRIES
******************************************************************************
*//Switch to R
*library(BMS)
*//Data
*//load data: the first column is the response variable, other columns explanatory variables.
*dataeis=read.table("clipboard-512", sep="\t", header=TRUE)
*//Estimation
*eis = bms(dataspeed, burn=1000000, iter=2000000, g="BRIC", mprior="random", nmodel=5000, mcmc="bd", user.int=FALSE, fixed.reg=c("gdppc","eascredit","realrate","ruleoflaw"))
*//Diagnostics
*plot(eis)
*summary(eis)
*//Results
*coef(eis, order.by.pip = F, exact=T, include.constant=T)
*image(eis[1:5000], cex.axis=0.7, order.by.pip = T, yprop2pip=F)
*density(speed, reg="gdppc")
*density(speed, reg="eascredit")
*density(speed, reg="realrate")
*density(speed, reg="ruleoflaw")
reg eis gdppc eascredit realrate ruleoflaw inverse top irstock totalc ols lnyears stockhold exact ircap monthly if abs(eis)<10, vce(cluster idcountry)
******************************************************************************
*BMA, CORE COUNTRIES
******************************************************************************
*//Switch to R
*library(BMS)
*//Data
*//load data: the first column is the response variable, other columns explanatory variables.
*dataeis=read.table("clipboard-512", sep="\t", header=TRUE)
*//Estimation
*eis = bms(dataspeed, burn=1000000, iter=2000000, g="BRIC", mprior="random", nmodel=5000, mcmc="bd", user.int=FALSE, fixed.reg=c("gdppc","eascredit","marketpartic","realrate","ruleoflaw"))
*//Diagnostics
*plot(eis)
*summary(eis)
*//Results
*coef(eis, order.by.pip = F, exact=T, include.constant=T)
*image(eis[1:5000], cex.axis=0.7, order.by.pip = T, yprop2pip=F)
*density(speed, reg="marketpartic")
reg eis marketpartic gdppc eascredit realrate ruleoflaw inverse top lnyears totalc irstock ols ircap lnyearcits stockhold sepdur monthly if abs(eis)<10, vce(cluster idcountry)
******************************************************************************
*BMA, NO FIXED VARIABLES
******************************************************************************
*//Switch to R
*library(BMS)
*//Data
*//load data: the first column is the response variable, other columns explanatory variables.
*dataeis=read.table("clipboard-512", sep="\t", header=TRUE)
*//Estimation
*eis = bms(dataspeed, burn=1000000, iter=2000000, g="BRIC", mprior="random", nmodel=5000, mcmc="bd", user.int=FALSE)
*//Diagnostics
*plot(eis)
*summary(eis)
*//Results
*coef(eis, order.by.pip = F, exact=T, include.constant=T)
*image(eis[1:5000], cex.axis=0.7, order.by.pip = T, yprop2pip=F)
reg eis inverse top totalc lnyears irstock ols marketpartic ircap stockhold exact if abs(eis)<10, vce(cluster idcountry)
******************************************************************************
*BMA, DIFFERENT PRIORS
******************************************************************************
*//Switch to R
*library(BMS)
*//Data
*//load data: the first column is the response variable, other columns explanatory variables.
*dataeis=read.table("clipboard-512", sep="\t", header=TRUE)
*//Estimation
*eis = bms(dataspeed, burn=1000000, iter=2000000, g="UIP", mprior="uniform", nmodel=5000, mcmc="bd", user.int=FALSE, fixed.reg=c("gdppc","eascredit","marketpartic","realrate","ruleoflaw"))
*//Diagnostics
*plot(eis)
*summary(eis)
*//Results
*coef(eis, order.by.pip = F, exact=T, include.constant=T)
*image(eis[1:5000], cex.axis=0.7, order.by.pip = T, yprop2pip=F)
reg eis marketpartic gdppc eascredit realrate ruleoflaw inverse top irstock totalc lnyears ols ircap stockhold lnyearcits sepdur monthly if abs(eis)<10, vce(cluster idcountry)
******************************************************************************
*BMA, ALTERNATIVE PROXIES
******************************************************************************
*//Switch to R
*library(BMS)
*//Data
*//load data: the first column is the response variable, other columns explanatory variables.
*dataeis=read.table("clipboard-512", sep="\t", header=TRUE)
*//Estimation
*eis = bms(dataspeed, burn=1000000, iter=2000000, g="BRIC", mprior="random", nmodel=5000, mcmc="bd", user.int=FALSE, fixed.reg=c("gdppc","finref","marketpartic","realrate","trust"))
*//Diagnostics
*plot(eis)
*summary(eis)
*//Results
*coef(eis, order.by.pip = F, exact=T, include.constant=T)
*image(eis[1:5000], cex.axis=0.7, order.by.pip = T, yprop2pip=F)
reg eis marketpartic gdppc finref realrate trust inverse top totalc lnyears ols irstock stockhold lnyearcits ircap sepdur if abs(eis)<10, vce(cluster idcountry)
******************************************************************************
window manage close graph
log close
exit, clear
******************************************************************************
******************************************************************************

