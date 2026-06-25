******************************************************************************
******************************************************************************
*DAYLIGHT SAVING TIME: A META-ANALYSIS
******************************************************************************
******************************************************************************
*Stata 14.1
*March 20, 2017
log using daylight.log, replace
import excel daylight.xlsx, sheet("STATA") firstrow
set more off
******************************************************************************
*DEFINITION OF VARIABLES
******************************************************************************
destring ESTIMATE, replace
destring SE, replace
destring TSTAT, replace
destring PRECISION, replace
destring PUBYEAR, replace
destring DSTYEAR, replace
destring PERIOD, replace
destring HOUR, replace
destring DAY, replace
destring MONTH, replace 
destring N, replace
replace PERIOD = 1 if missing(PERIOD)
g MIDYEAR = DSTYEAR + (PERIOD-1)/2
replace MIDYEAR = MIDYEAR - 1968
g PUBYEAR2 = PUBYEAR - 1970
g LNCITATIONS = log(CITATIONS + 1)
g COUNTRYCZ = 0
replace COUNTRYCZ = 1 if COUNTRY=="Czech Republic" 
g SQRTNOBS = sqrt(N) if REGRESSION==1
g INVSQRTNOBS = 1/sqrt(N) if REGRESSION==1
replace COUNTRYCZ = 0 if (COUNTRYCZ >= .)
egen IDCOUNTRY = group(COUNTRY)
egen IDCOUNTRYA = group(COUNTRYA)
******************************************************************************
label variable LABEL "Author and publication year"
label variable IDSTUDY "ID of a study"
label variable IDAUTHOR "ID of an author"
label variable IDCOUNTRY "ID of the country for which the DST effect is estimated"
label variable IDCOUNTRYA "ID of the home country of an author"
label variable COUNTRY "Country for which the DST effect is estimated"
label variable COUNTRYA "Home country of an author"
label variable COUNTRYCZ "Country for which the DST effect is estimated is the Czech republic"
label variable ESTIMATE "Estimate of the DST impact (in %)"
label variable SE "Standard error"
label variable TSTAT "t-statistic"
label variable PRECISION "Precision of the DST estimate (1/SE)"
label variable REGRESSION "= 1 if the study is based on regression analysis"
label variable SIMULATION "= 1 if the study is based on simulation"
label variable RESIDENT "= 1 if residential consumption is examined"
label variable LIGHT "= 1 if lightning electricity consumption is examined"
label variable USA "= 1 if US data are examined"
label variable EUROPE "= 1 if European countries are examined"
label variable PUBYEAR "Publication year of the study"
label variable PUBYEAR2 "Year the study was published (base: 1974)"
label variable DSTYEAR "First year of data examined in a study"
label variable PERIOD "Number of years examined in a study"
label variable MIDYEAR "Midpoint of the sample on which the DST effect is estimated (base: 1973)"
label variable HOUR "= 1 if data are examined on hourly basis or less (half an hour, minutes etc.)"
label variable DAY "= 1 if data are examined on daily basis"
label variable MONTH "= 1 if data are examined on mothly basis"
label variable DID "= 1 if difference-in-differences approach is employed"
label variable LOG "= 1 if log-level model is estimated"
label variable MAIN "= 1 if estimate is reported as main in primary study"
label variable JOURNAL "= 1 if the study is published in a peer-reviewed journal"
label variable IMPACT "Recursive discounted RePEc impact factor of the outlet (collected in April 2016)"
label variable CITATIONS "Total number of Google Scholar citations since the study appeared in Google Scholar (collected in April 2016)"
label variable LNCITATIONS "Logarithm of the total number of Google Scholar citations since the study appeared in Google Scholar (collected in April 2016)"
label variable N "Number of observations"
label variable SQRTNOBS "Number of study observations squared"
label variable INVSQRTNOBS "Inverse of the number of study observations squared"
label variable REFERENCE "Bibliographical records"
label variable WEIGHT "Inverse of the number of estimates reported per study"
label variable LATITUDE "Absolute value of the average latitude for a country"
label variable DAYLIGHT "Number of daylight hours of the longest day (from sunset to sunrise)"
label variable DAYLIGHTSQ "Number of daylight hours squared"
xtset IDSTUDY
******************************************************************************
*SUMMARY STATISTICS
******************************************************************************
mean ESTIMATE
mean ESTIMATE if USA==1
mean ESTIMATE if USA==0
mean ESTIMATE if EUROPE==1
mean ESTIMATE if EUROPE==0
mean ESTIMATE if REGRESSION==1
mean ESTIMATE if SIMULATION==1
mean ESTIMATE if REGRESSION==0 & SIMULATION==0
mean ESTIMATE if RESIDENT==1
mean ESTIMATE if RESIDENT==0
mean ESTIMATE if LIGHT==1
mean ESTIMATE if LIGHT==0
mean ESTIMATE if DID==1
mean ESTIMATE if DID==0
mean ESTIMATE if HOUR==1 
mean ESTIMATE if DAY==1 
mean ESTIMATE if MONTH==1 
mean ESTIMATE if JOURNAL==1
mean ESTIMATE if JOURNAL==0
mean ESTIMATE if MAIN==1
mean ESTIMATE [aweight=WEIGHT]
mean ESTIMATE [aweight=WEIGHT] if USA==1
mean ESTIMATE [aweight=WEIGHT] if USA==0
mean ESTIMATE [aweight=WEIGHT] if EUROPE==1
mean ESTIMATE [aweight=WEIGHT] if EUROPE==0
mean ESTIMATE [aweight=WEIGHT] if REGRESSION==1
mean ESTIMATE [aweight=WEIGHT] if SIMULATION==1
mean ESTIMATE [aweight=WEIGHT] if REGRESSION==0 & SIMULATION==0
mean ESTIMATE [aweight=WEIGHT] if RESIDENT==1
mean ESTIMATE [aweight=WEIGHT] if RESIDENT==0
mean ESTIMATE [aweight=WEIGHT] if LIGHT==1
mean ESTIMATE [aweight=WEIGHT] if LIGHT==0
mean ESTIMATE [aweight=WEIGHT] if DID==1
mean ESTIMATE [aweight=WEIGHT] if DID==0
mean ESTIMATE [aweight=WEIGHT] if HOUR==1 
mean ESTIMATE [aweight=WEIGHT] if DAY==1 
mean ESTIMATE [aweight=WEIGHT] if MONTH==1 
mean ESTIMATE [aweight=WEIGHT] if JOURNAL==1
mean ESTIMATE [aweight=WEIGHT] if JOURNAL==0
mean ESTIMATE [aweight=WEIGHT] if MAIN==1
******************************************************************************
sktest ESTIMATE
sum ESTIMATE, det
mean TSTAT 
sum SE
sum TSTAT, det
sum TSTAT if MAIN==1, det
*****************************************************************************
graph twoway (scatter ESTIMATE PUBYEAR, msize(*1) msymbol(Oh)) (lfit ESTIMATE PUBYEAR, lcolor(black)),  ytitle("Estimate of the DST impact (in %)") legend(off) saving(_trend, replace)
kdensity ESTIMATE, normopts(lpattern(dash) lcolor(black)) note("") legend(off) xtitle("Estimate of the DST impact (in %)", size(medsmall)) title("") xline(-0.3427427, lpattern(solid) lcolor (grey)) xline(-0.1206594, lpattern(dott) lcolor (black)) saving(_density, replace)
graph hbox ESTIMATE, over(LABEL) xsize(6) ysize(6) scale(0.5) yline(0, lpattern(shortdash) lcolor (black)) saving(_studies, replace)
graph hbox ESTIMATE if COUNTRYCZ==0, over(COUNTRY) xsize(3) ysize(3) scale(0.7) yline(0, lpattern(shortdash) lcolor (black)) saving(_countries, replace) 
******************************************************************************
*FUNNEL PLOT
******************************************************************************
graph twoway scatter PRECISION ESTIMATE if PRECISION<15 & ESTIMATE>-5, msize(*1) msymbol(Oh) xline(-.3344542, lpattern(dash) lcolor (black)) saving(_funnel, replace)
******************************************************************************
*PUBLICATION BIAS: FAT-PET
******************************************************************************
quietly tabulate IDSTUDY, gen(studyd)
local studies studyd*
foreach x of varlist `studies' {
				egen av`x' = mean(`x')
				scalar scav`x' = av`x' in 1
}
drop avstudyd*
quietly tabulate IDCOUNTRY, gen(countryd)
local countries countryd*
foreach x of varlist `countries' {
				egen av`x' = mean(`x')
				scalar scav`x' = av`x' in 1
}
drop avcountryd*
constraint 1 scavstudyd1*studyd1 + scavstudyd2*studyd2 + scavstudyd3*studyd3 + scavstudyd4*studyd4 + scavstudyd5*studyd5 + scavstudyd6*studyd6 + scavstudyd7*studyd7 + scavstudyd8*studyd8 + scavstudyd9*studyd9 + scavstudyd10*studyd10 + scavstudyd11*studyd11 + scavstudyd12*studyd12 + scavstudyd13*studyd13 + scavstudyd14*studyd14 + scavstudyd15*studyd15 + scavstudyd16*studyd16 + scavstudyd17*studyd17 + scavstudyd18*studyd18 + scavstudyd19*studyd19 + scavstudyd20*studyd20 + scavstudyd21*studyd21 + scavstudyd22*studyd22 + scavstudyd23*studyd23 + scavstudyd24*studyd24 + scavstudyd25*studyd25 + scavstudyd26*studyd26 + scavstudyd27*studyd27 + scavstudyd28*studyd28 + scavstudyd29*studyd29 + scavstudyd30*studyd30 + scavstudyd31*studyd31 + scavstudyd32*studyd32 + scavstudyd33*studyd33 + scavstudyd34*studyd34 + scavstudyd35*studyd35 + scavstudyd36*studyd36 + scavstudyd37*studyd37 + scavstudyd38*studyd38 + scavstudyd39*studyd39 + scavstudyd40*studyd40 + scavstudyd41*studyd41 + scavstudyd42*studyd42 + scavstudyd43*studyd43 + scavstudyd44*studyd44 = 0
constraint 2 scavcountryd1*countryd1 + scavcountryd2*countryd2 + scavcountryd3*countryd3 + scavcountryd4*countryd4 + scavcountryd5*countryd5 + scavcountryd6*countryd6 + scavcountryd7*countryd7 + scavcountryd8*countryd8 + scavcountryd10*countryd10 + scavcountryd11*countryd11 + scavcountryd12*countryd12 + scavcountryd13*countryd13 + scavcountryd14*countryd14 + scavcountryd15*countryd15 + scavcountryd16*countryd16 + scavcountryd17*countryd17 + scavcountryd18*countryd18 + scavcountryd19*countryd19 + scavcountryd20*countryd20 + scavcountryd21*countryd21 = 0

ivreg2 ESTIMATE SE, cluster (IDSTUDY IDCOUNTRY)
ivreg2 ESTIMATE SE [pweight=WEIGHT], cluster (IDSTUDY IDCOUNTRY)
xtmixed ESTIMATE SE || IDSTUDY: || IDCOUNTRY:
xtreg ESTIMATE SE, fe vce(cluster IDSTUDY)
ivreg2 ESTIMATE SE [pweight = 1/SE], cluster (IDSTUDY IDCOUNTRY)
cnsreg TSTAT PRECISION studyd*, constraint(1) vce(cluster IDSTUDY)
xtmixed ESTIMATE SE [pweight = 1/SE]|| IDSTUDY: || IDCOUNTRY:

eststo: ivreg2 TSTAT PRECISION, cluster (IDSTUDY IDCOUNTRY) 
eststo: xtreg TSTAT PRECISION, fe vce(cluster IDSTUDY) 
eststo: xtreg TSTAT PRECISION, be 
eststo: cnsreg TSTAT PRECISION countryd*, constraint(2) vce(cluster IDSTUDY)
eststo: xtmixed TSTAT PRECISION || IDSTUDY: || IDCOUNTRY:
eststo: xtivreg TSTAT (PRECISION = INVSQRTNOBS), fe vce(cluster IDSTUDY) 
esttab using _fatpet.tex, se booktabs replace compress title(FAT-PET test for DST estimates\label{tab:fatpet}) mtitles("OLS" "FE" "BE" "COUNTRY" "ME" "IV") addnote("Standard errors clustered at the study and country level.") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear
******************************************************************************
*HECKMAN CORRECTION
******************************************************************************
eststo: ivreg2 TSTAT PRECISION SE, cluster (IDSTUDY IDCOUNTRY) 
eststo: xtreg TSTAT PRECISION SE, fe vce(cluster IDSTUDY) 
eststo: xtmixed TSTAT PRECISION SE || IDSTUDY: || IDCOUNTRY:
esttab using _heckman.tex, se booktabs replace compress title(Heckman correction for DST estimates\label{tab:heckman}) mtitles("1" "2" "3") addnote("Standard errors clustered at the study and country level.") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear 
******************************************************************************
*GALBRAITH PLOT
******************************************************************************
g T=(ESTIMATE+0.2928212)/SE
g Tchisq = 1 
replace Tchisq = 0 if T>1.96 | T<-1.96
replace Tchisq = . if missing(T)
csgof Tchisq, expperc(5 95)
label variable T "t-statistic (if the DST true effect is -0.29%)"
twoway scatter T PRECISION, msize(*1.5) msymbol(Oh)
twoway scatter T PRECISION if LABEL!="Ahuja & SenGupta (2012)", msize(*1.5) msymbol(Oh) yline(-1.96, lpattern(dash) lcolor (black)) yline(1.96, lpattern(dash) lcolor (black)) saving(_galbraith, replace)
******************************************************************************
*HETEROGENEITY - BAYESIAN MODEL AVERAGING ////CODE for R///
******************************************************************************
*library(BMS)
**read data from excel (press ctrl-c)
*datadaylight=read.table("clipboard-512", sep="\t", header=TRUE)
******************************************************************************
**Starts estimation
*daylight = bms(datadaylight, burn=1000000, iter=2000000, g="UIP", mprior="uniform", nmodel=5000, mcmc="bd", user.int=FALSE)
*daylight2 = bms(datadaylight, burn=1000000, iter=2000000, g="BRIC", mprior="random", nmodel=5000, mcmc="bd", user.int=FALSE)
*daylight3 = bms(datadaylight, burn=1000000,iter=2000000, g="hyper=BRIC", mprior="random", nmodel=5000, mcmc="bd", user.int=FALSE)
******************************************************************************
**Diagnostics
*plot(daylight)
*summary(daylight)
*plot(daylight2)
*summary(daylight2)
******************************************************************************
**Results
*coef(daylight, order.by.pip = F, exact=T, include.constant=T)
*image(daylight, cex.axis=0.7, order.by.pip = T, yprop2pip=F)
*print(daylight$topmod[1]) *included variables in the best model
*coef(daylight2, order.by.pip = F, exact=T, include.constant=T)
*image(daylight2, cex.axis=0.7, order.by.pip = T, yprop2pip=F)
*print(daylight2$topmod[1]) *included variables in the best model
******************************************************************************
**Posterior density
*density(daylight, reg="SIMULATION")
*density(daylight, reg="DAYLIGHT")
*density(daylight, reg="DAY")
*density(daylight, reg="DID")
*density(daylight, reg="IMPACT")
******************************************************************************
*HETEROGENEITY - FREQUENTIST MODEL AVERAGING (MALLOWS) ////CODE for R///
******************************************************************************
**Loading libraries
*library(foreign)
*library(xtable)
*library(LowRankQP)
*datadaylight=read.table("clipboard-512", sep="\t", header=TRUE)
**deleting missing observations
*datadaylight <-na.omit(datadaylight)
*x.data <- datadaylight[,-1]
**adding constant
*const_<-c(1)
*x.data <-cbind(const_,x.data)
******************************************************************************
*x <- sapply(1:ncol(x.data),function(i){x.data[,i]/max(x.data[,i])})   
*scale.vector <- as.matrix(sapply(1:ncol(x.data),function(i){max(x.data[,i])}))        
*Y <- as.matrix(datadaylight[,1])
*output.colnames <- colnames(x.data)
*full.fit <- lm(Y~x-1)
*beta.full <- as.matrix(coef(full.fit))
*M <- k <- ncol(x)
*n <- nrow(x)
*beta <- matrix(0,k,M)
*e <- matrix(0,n,M)
*K_vector <- matrix(c(1:M))
*var.matrix <- matrix(0,k,M)
*bias.sq <- matrix(0,k,M) 
******************************************************************************            
**MMA estimator using orthogonalization 
*for(i in 1:M)
*{
*  X <- as.matrix(x[,1:i])
*  ortho <- eigen(t(X)%*%X)
*  Q <- ortho$vectors ; lambda <- ortho$values 
*  x.tilda <- X%*%Q%*%(diag(lambda^-0.5,i,i))
*  beta.star <- t(x.tilda)%*%Y
*  beta.hat <- Q%*%diag(lambda^-0.5,i,i)%*%beta.star
*  beta[1:i,i] <- beta.hat
*  e[,i] <- Y-x.tilda%*%as.matrix(beta.star)
*  bias.sq[,i] <- (beta[,i]-beta.full)^2
*  var.matrix.star <- diag(as.numeric(((t(e[,i])%*%e[,i])/(n-i))),i,i)
*  var.matrix.hat <- var.matrix.star%*%(Q%*%diag(lambda^-1,i,i)%*%t(Q))
*  var.matrix[1:i,i] <- diag(var.matrix.hat)
*  var.matrix[,i] <- var.matrix[,i]+ bias.sq[,i]
*} 
**End loop over i
******************************************************************************
*e_k <- e[,M]
*sigma_hat <- as.numeric((t(e_k)%*%e_k)/(n-M))
*G <- t(e)%*%e
*a <- ((sigma_hat)^2)*K_vector
*A <- matrix(1,1,M)
*b <- matrix(1,1,1)
*u <- matrix(1,M,1)
*optim <- LowRankQP(Vmat=G,dvec=a,Amat=A,bvec=b,uvec=u,method="LU",verbose=FALSE)
*weights <- as.matrix(optim$alpha)
*beta.scaled <- beta%*%weights
*final.beta <- beta.scaled/scale.vector
*std.scaled <- sqrt(var.matrix)%*%weights
*final.std <- std.scaled/scale.vector
*results.reduced <- as.matrix(cbind(final.beta,final.std))
*rownames(results.reduced) <- output.colnames; colnames(results.reduced) <- c("Coefficient", "Sd. Err")
*MMA.fls <- round(results.reduced,4)
*MMA.fls <- data.frame(MMA.fls)
*t <- as.data.frame(MMA.fls$Coefficient/MMA.fls$Sd..Err)
*MMA.fls$pv <-round( (1-apply(as.data.frame(apply(t,1,abs)), 1, pnorm))*2,3)
*MMA.fls$names <- rownames(MMA.fls)
*names <- c(colnames(datadaylight))
*names <- c(names,"const_")
*MMA.fls <- MMA.fls[match(names, MMA.fls$names),]
*MMA.fls$names <- NULL
*MMA.fls
******************************************************************************
*HETEROGENEITY
******************************************************************************
sum ESTIMATE SE MIDYEAR PERIOD MAIN HOUR DAY MONTH LATITUDE DAYLIGHT EUROPE USA REGRESSION SIMULATION DID LOG RESIDENT LIGHT PUBYEAR2 JOURNAL IMPACT LNCITATIONS
sum ESTIMATE SE MIDYEAR PERIOD MAIN HOUR DAY MONTH LATITUDE DAYLIGHT EUROPE USA REGRESSION SIMULATION DID LOG RESIDENT LIGHT PUBYEAR2 JOURNAL IMPACT LNCITATIONS [aweight=WEIGHT]
corr ESTIMATE MIDYEAR PERIOD MAIN DAY MONTH LATITUDE DAYLIGHT EUROPE USA REGRESSION SIMULATION DID LOG RESIDENT LIGHT PUBYEAR2 JOURNAL IMPACT LNCITATIONS
corr ESTIMATE PERIOD MAIN DAY DAYLIGHT REGRESSION SIMULATION DID RESIDENT PUBYEAR2 JOURNAL IMPACT LNCITATIONS if USA==1
* LOG=!=DID, PUBYEAR=!=MIDYEAR, IMPACT=!=MONTH, DAYLIGHT=!=LATITUDE=!EUROPE, REGRESSION? - VIF
******************************************************************************
ivreg2 ESTIMATE PERIOD MAIN DAY DAYLIGHT USA REGRESSION SIMULATION DID RESIDENT LIGHT PUBYEAR2 JOURNAL IMPACT LNCITATIONS, cluster (IDSTUDY IDCOUNTRY)
ivvif
ivreg2 ESTIMATE PERIOD MAIN DAY REGRESSION SIMULATION RESIDENT PUBYEAR2 IMPACT LNCITATIONS if USA==1, cluster (IDSTUDY)
ivreg2 ESTIMATE PERIOD MAIN DAY DAYLIGHT DAYLIGHTSQ USA REGRESSION SIMULATION DID RESIDENT LIGHT PUBYEAR2 JOURNAL IMPACT LNCITATIONS, cluster (IDSTUDY IDCOUNTRY)
ivvif
xtmixed ESTIMATE PERIOD MAIN DAY DAYLIGHT USA REGRESSION SIMULATION DID RESIDENT LIGHT PUBYEAR2 JOURNAL IMPACT LNCITATIONS || IDSTUDY: || IDCOUNTRY:
******************************************************************************
*BEST PRACTICE FOR COUNTRIES
******************************************************************************
ivreg2 ESTIMATE if COUNTRY=="Australia", cluster (IDSTUDY)
ivreg2 ESTIMATE if COUNTRY=="Austria", cluster (IDSTUDY)
ivreg2 ESTIMATE if COUNTRY=="Chile", cluster (IDSTUDY)
ivreg2 ESTIMATE if COUNTRY=="Czech Republic", cluster (IDSTUDY)
ivreg2 ESTIMATE if COUNTRY=="Denmark", cluster (IDSTUDY)
ivreg2 ESTIMATE if COUNTRY=="France", cluster (IDSTUDY)
ivreg2 ESTIMATE if COUNTRY=="Germany", cluster (IDSTUDY)
ivreg2 ESTIMATE if COUNTRY=="India", cluster (IDSTUDY)
sum ESTIMATE if COUNTRY=="Israel"
ivreg2 ESTIMATE if COUNTRY=="Italy", cluster (IDSTUDY)
sum ESTIMATE if COUNTRY=="Japan"
ivreg2 ESTIMATE if COUNTRY=="Jordan", cluster (IDSTUDY)
sum ESTIMATE if COUNTRY=="Kuwait"
sum ESTIMATE if COUNTRY=="Mexico"
ivreg2 ESTIMATE if COUNTRY=="Netherlands", cluster (IDSTUDY)
sum ESTIMATE if COUNTRY=="New Zealand"
ivreg2 ESTIMATE if COUNTRY=="Norway", cluster (IDSTUDY)
ivreg2 ESTIMATE if COUNTRY=="Sweden", cluster (IDSTUDY)
sum ESTIMATE if COUNTRY=="Turkey"
ivreg2 ESTIMATE if COUNTRY=="USA"
ivreg2 ESTIMATE if COUNTRY=="United Kingdom", cluster (IDSTUDY)
ivreg2 ESTIMATE if EUROPE==1, cluster (IDSTUDY IDCOUNTRY)
ivreg2 ESTIMATE, cluster (IDSTUDY)

ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="Australia", cluster (IDSTUDY)
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="Austria", cluster (IDSTUDY)
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="Chile", cluster (IDSTUDY)
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="Czech Republic", cluster (IDSTUDY)
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="Denmark", cluster (IDSTUDY)
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="France", cluster (IDSTUDY)
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="Germany", cluster (IDSTUDY)
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="India", cluster (IDSTUDY)
sum ESTIMATE [aweight=WEIGHT] if COUNTRY=="Israel"
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="Italy", cluster (IDSTUDY)
sum ESTIMATE [aweight=WEIGHT] if COUNTRY=="Japan"
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="Jordan", cluster (IDSTUDY)
sum ESTIMATE [aweight=WEIGHT] if COUNTRY=="Kuwait"
sum ESTIMATE [aweight=WEIGHT] if COUNTRY=="Mexico"
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="Netherlands", cluster (IDSTUDY)
sum ESTIMATE [aweight=WEIGHT] if COUNTRY=="New Zealand"
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="Norway", cluster (IDSTUDY)
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="Sweden", cluster (IDSTUDY)
sum ESTIMATE [aweight=WEIGHT] if COUNTRY=="Turkey"
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="USA"
ivreg2 ESTIMATE [aweight=WEIGHT] if COUNTRY=="United Kingdom", cluster (IDSTUDY)
ivreg2 ESTIMATE [aweight=WEIGHT] if EUROPE==1, cluster (IDSTUDY IDCOUNTRY)
ivreg2 ESTIMATE [aweight=WEIGHT], cluster (IDSTUDY)
***************************UNWEIGHTED
ivreg2 ESTIMATE PERIOD MAIN DAY DAYLIGHT USA REGRESSION SIMULATION DID RESIDENT LIGHT PUBYEAR2 JOURNAL IMPACT LNCITATIONS, cluster (IDSTUDY IDCOUNTRY)
sum IMPACT, det
sum LNCITATIONS, det
*Australia
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*13.83333333 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Austria
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*15.93333333 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Chile
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*14.8125 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Czech Republic
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*16.31666667 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Denmark
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*17.61666667 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*France
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*15.75 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Germany
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*16.53333333 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*India
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*13.33333333 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Israel
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*14.2 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Italy
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*15.33333333 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Japan
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*14.48333333 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Jordan
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*14.16666667 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Kuwait
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*14.01666667 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Mexico
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*13.55 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Netherlands
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*16.83333333 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*New Zealand
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*15.11666667 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Norway-----------------
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*19.76666667 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Sweden
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*19.75 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Turkey
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*14.9 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*United Kingdom
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*17.13333333 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*USA
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*14.76666667 + USA*1 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*Europe
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*16.13796933 + USA*0 + REGRESSION*0 + SIMULATION*0.1296296 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
*All countries
lincom _cons + PERIOD*9 + MAIN*1 + DAY*0 + DAYLIGHT*15.57093 + USA*0.2272728 + REGRESSION*0 + SIMULATION*0 + DID*1 + RESIDENT*0 + LIGHT*0 + PUBYEAR2*46 + JOURNAL*1 + IMPACT*0.501 + LNCITATIONS*4.70953
******************************************************************************
window manage close graph
log close
exit, clear
