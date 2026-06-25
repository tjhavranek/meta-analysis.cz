use "lags.dta", clear
set more off

*************************************************************************************************************
*Data cleaning
*************************************************************************************************************

keep if horizon==99
sum mon_peak mon_bot no_peak no_bot
drop if lags==.
tab study if  mon_bot==.       			 //Lists studies in which the response is never negative
gen nevernegative=(mon_bot==. | mon_bot==0) 			 //Dummy for studies in which the response is never negative
drop if nevernegative==1
*gen pp=(mon_peak~=.) 				     // Dummy for price puzzle, but it does include positive responses at long horizons
gen pricepuzzle=(mon_peak<mon_bot)       //Dummy==1, if there is positive response before negative one
replace mon_bot=60 if mon_bot>60 & mon_bot~=. //Censoring the outliers (8 observations affected)

gen se_avg=(up+low)/2 //generate average standard 
replace se_avg=100*se_avg
gen prec=1/se_avg

*************************************************************************************************************
*Definitions of variables for meta-regression
*************************************************************************************************************
gen monthly=0
replace monthly=1 if freq==12
gen avgyear=((syear+eyear)/2)-2000
gen timespan=(eyear-syear)     
gen lagsf=lags/freq
gen studyage=2010-yearpub+0.5
gen cits=citations/studyage
gen lncits=ln(1+cits)
replace yearpub=yearpub-2000           
gen policy=0
replace policy=1 if ministry==1 | imf_bis_oecd==1 
gen lnend_variab=ln(end_variab)
gen lnobs=ln(nobs)
replace vol=sqrt(vol) // standard deviation
replace gdppc=ln(gdppc) //log gdp level
replace findev=findev/100
replace open=open/100
replace inf=inf/100
replace se=100*se
*************************************************************************************************************
kdensity mon_bot
bysort no_bot: sum mon_bot

sum res, detail

sum mon_bot gdppc growth inf findev open indep monthly lnobs avgyear gdpdeflator single lagsf com money foreign trend seasonal lnend_variab ea_ip ea_gap ea_oth bvar favar svar sign no_bot pricepuzzle lncits if_repec cb policy native yearpub

collin gdppc growth inf findev open indep monthly lnobs avgyear gdpdeflator single lagsf com money foreign trend seasonal lnend_variab ea_ip ea_gap ea_oth bvar favar svar sign no_bot pricepuzzle lncits if_repec cb policy native yearpub

*************************************************************************************************************
*Preparation for BMA
*************************************************************************************************************
*keep mon_bot gdppc growth inf findev open indep monthly lnobs avgyear gdpdeflator single lagsf com money foreign trend seasonal lnend_variab ea_ip ea_gap ea_oth bvar favar svar sign no_bot pricepuzzle lncits if_repec cb policy native yearpub 
*order mon_bot gdppc growth inf findev open indep monthly lnobs avgyear gdpdeflator single lagsf com money foreign trend seasonal lnend_variab ea_ip ea_gap ea_oth bvar favar svar sign no_bot pricepuzzle lncits if_repec cb policy native yearpub
*saveold speed.dta

*************************************************************************************************************
*BMA -- switch to R
*************************************************************************************************************
//load library
library(BMS)

//read data from excel (press ctrl-c)
//data in the form: 1 column explained variable, other columns explanatory variables.
dataspeed=read.table("clipboard-512", sep="\t", header=TRUE)

//Starts estimation
speed = bms(dataspeed, burn=1000000, iter=2000000, g="UIP", mprior="uniform", nmodel=5000, mcmc="bd", user.int=FALSE)

//Diagnostics
plot(speed)
summary(speed)

//Results
coef(speed, order.by.pip = F, exact=T, include.constant=T)
image(speed[1:5000], cex.axis=0.7, order.by.pip = T, yprop2pip=F)
print(speed$topmod[1]) //included variables in the best model

//Posterior densitiy
density(speed, reg="gdppc")