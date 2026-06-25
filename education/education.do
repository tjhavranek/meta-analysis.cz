******************************************************************************
*    Responsiveness of Demand for Higher Education to Changes in Tuition     *
******************************************************************************
* Stata 14.1
* Dec 12th, 2016 
log using education.log, replace
import excel education.xlsx, sheet("data") firstrow
xtset idstudy
set more off
******************************************************************************
* Summary statistics
******************************************************************************
correlate tstat pcc pcc_se shortrun usa ln_timespan ln_pub_year ln_google linear doublelog published unemployment income cross panel tseries ols fe endogeneity male female private public
correlate tstat pcc pcc_se shortrun usa ln_timespan ln_pub_year ln_google linear doublelog published unemployment income cross panel tseries ols fe endogeneity male female private public [aweight=invperst]
correlate tstat pcc pcc_se shortrun usa ln_timespan ln_pub_year ln_google linear doublelog published unemployment income cross panel tseries ols fe endogeneity male female private public [aweight=pcc_prec]
summarize tstat pcc pcc_se shortrun usa ln_timespan ln_pub_year ln_google linear doublelog published unemployment income cross panel tseries ols fe endogeneity male female private public
summarize tstat pcc pcc_se shortrun usa ln_timespan ln_pub_year ln_google linear doublelog published unemployment income cross panel tseries ols fe endogeneity male female private public [aweight=invperst]
summarize pcc, detail
local m = r(mean)
local med = r(p50)
histogram pcc, bin(20) frequency xline(`m', lp(solid) lcolor(gs0)) xline(`med', lp(dash) lcolor(gs0)) saving(_hist, replace)
summarize pcc if shortrun==1, detail
summarize pcc if shortrun==0, detail
summarize pcc if endogeneity==1, detail
summarize pcc if endogeneity==0, detail
summarize pcc if private==1, detail
summarize pcc if public==1, detail
summarize pcc if male==1, detail
summarize pcc if female==1, detail
summarize pcc if usa==1, detail
summarize pcc if usa==0, detail
summarize pcc if published==1, detail
summarize pcc if published==0, detail
summarize pcc [aweight=invperst], detail
summarize pcc [aweight=invperst] if shortrun==1, detail
summarize pcc [aweight=invperst] if shortrun==0, detail
summarize pcc [aweight=invperst] if endogeneity==1, detail
summarize pcc [aweight=invperst] if endogeneity==0, detail
summarize pcc [aweight=invperst] if private==1, detail
summarize pcc [aweight=invperst] if public==1, detail
summarize pcc [aweight=invperst] if male==1, detail
summarize pcc [aweight=invperst] if female==1, detail
summarize pcc [aweight=invperst] if usa==1, detail
summarize pcc [aweight=invperst] if usa==0, detail
summarize pcc [aweight=invperst] if published==1, detail
summarize pcc [aweight=invperst] if published==0, detail
graph hbox pcc, over(author) xsize(7) ysize(8) scale(0.6) yline(0, lpattern(shortdash) lcolor (black)) saving(_studies, replace)
graph hbox pcc, over(country) xsize(2.5) ysize(1) scale(1.5) yline(0, lpattern(shortdash) lcolor (black)) saving(_countries, replace)
graph twoway (scatter pcc pub_year, msize(*1) msymbol(Oh)) (lfit pcc pub_year, lcolor(black)),  xtitle("Publication year") ytitle("Partial correlation coefficient") legend(off) saving(_trend, replace)
******************************************************************************
* Funnel plot
******************************************************************************
twoway scatter pcc_prec pcc, ytitle("Precision of partial correlation coefficient (1/SE)") xtitle("Partial correlation coefficient") xline(-.170816, lpattern(solid) lcolor (black)) xline(0, lpattern(dash) lcolor (black)) saving(_funnel, replace)
graph twoway (scatter pcc_prec pcc if shortrun==0) (scatter pcc_prec pcc if shortrun==1), ytitle("Precision of partial correlation coefficient (1/SE)") xtitle("Partial correlation coefficient") xline(-.170816, lpattern(solid) lcolor (black)) xline(0, lpattern(dash) lcolor (black)) saving(_funnel2, replace)
******************************************************************************
* FAT-PET
******************************************************************************
eststo: ivreg2 pcc pcc_se, cluster(idstudy)
eststo: ivreg pcc (pcc_se=instrument), cluster(idstudy)
eststo: ivreg2 pcc instrument, cluster(idstudy)
eststo: xtreg pcc pcc_se, be
estout, cells(b(star fmt(3)) se(par fmt(2)))
esttab using tabfat1.tex, replace cells(b(star fmt(3)) se(par fmt(2))) star(* 0.10 ** 0.05 *** 0.01) r2
eststo clear 

eststo: ivreg2 pcc pcc_se [pweight=pcc_prec], cluster(idstudy)
eststo: ivreg pcc (pcc_se=instrument) [pweight=pcc_prec], cluster(idstudy)
eststo: ivreg2 pcc pcc_se [pweight=invperst], cluster(idstudy)
eststo: ivreg pcc (pcc_se=instrument) [pweight=invperst], cluster(idstudy)
estout, cells(b(star fmt(3)) se(par fmt(2)))
esttab using tabfat2.tex, replace cells(b(star fmt(3)) se(par fmt(2))) star(* 0.10 ** 0.05 *** 0.01) r2
eststo clear 
******************************************************************************
* HETEROGENEITY - BAYESIAN MODEL AVERAGING in R
******************************************************************************
*library(BMS)
*dataeducation=read.table("clipboard-512", sep="\t", header=TRUE)
*education = bms(dataeducation, burn=1000000, iter=2000000, g="UIP", mprior="uniform", nmodel=5000, mcmc="bd", user.int=FALSE)
*education2 = bms(dataeducation, burn=1000000, iter=2000000, g="BRIC", mprior="random", nmodel=5000, mcmc="bd", user.int=FALSE)
*plot(education)
*summary(education)
*coef(education, order.by.pip = F, exact=T, include.constant=T)
*image(education, cex.axis=0.7, order.by.pip = T, yprop2pip=F)
*print(education$topmod[1]) *included variables in the best model
*density(education, reg="private")
******************************************************************************
* HETEROGENEITY - MALLOWS FREQUENTIST MODEL AVERAGING in R
******************************************************************************
*library(foreign)
*library(xtable)
*library(LowRankQP)
*dataeducation=read.table("clipboard-512", sep="\t", header=TRUE)
*dataeducation <-na.omit(dataeducation)
*x.data <- dataeducation[,-1]
*const_<-c(1)
*x.data <-cbind(const_,x.data)
*x <- sapply(1:ncol(x.data),function(i){x.data[,i]/max(x.data[,i])})   
*scale.vector <- as.matrix(sapply(1:ncol(x.data),function(i){max(x.data[,i])}))        
*Y <- as.matrix(dataeducation[,1])
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
*# MMA Estimator using orthogonalization 
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
*} # End loop over i
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
*names <- c(colnames(dataeducation))
*names <- c(names,"const_")
*MMA.fls <- MMA.fls[match(names, MMA.fls$names),]
*MMA.fls$names <- NULL
*MMA.fls
******************************************************************************
* HETEROGENEITY: FREQUENTIST CHECK
******************************************************************************
correlate pcc pcc_se shortrun ln_pub_year ln_google linear doublelog published unemployment income cross  panel ols fe usa endogeneity male female private public
collin pcc_se shortrun ln_pub_year ln_google linear doublelog published unemployment income cross  panel ols usa endogeneity  male female private public
eststo: ivreg2 pcc pcc_se shortrun ols endogeneity linear doublelog unemployment income male female cross panel private public usa ln_pub_year ln_google published [pweight=invperst], cluster(idstudy idcountry)
eststo: ivreg2 pcc pcc_se ols income panel male private ln_google [pweight=invperst], cluster(idstudy idcountry)
eststo: ivreg2 pcc pcc_se shortrun ols  income panel male private usa ln_google [pweight=invperst], cluster(idstudy idcountry)
*eststo: ivreg2 pcc pcc_se shortrun ols income panel male private usa ln_google [pweight=invperst], cluster(idstudy idcountry)estout, cells(b(star fmt(3)) se(par fmt(2)))
esttab using tabhet.tex, replace cells(b(star fmt(3)) se(par fmt(2))) star(* 0.10 ** 0.05 *** 0.01) r2
eststo clear 
******************************************************************************
* BEST PRACTICE
******************************************************************************
local variables pcc pcc_se shortrun ols endogeneity linear doublelog unemployment income cross panel male female private public usa ln_pub_year ln_google published
foreach x of varlist `variables' {
				gen `x'_nobs = `x' * invperst
}
ivreg2 pcc_nobs pcc_se_nobs shortrun_nobs ols_nobs endogeneity_nobs linear_nobs doublelog_nobs unemployment_nobs income_nobs cross_nobs panel_nobs male_nobs female_nobs private_nobs public_nobs usa_nobs ln_pub_year_nobs ln_google_nobs published_nobs, cluster(idstudy idcountry)
sum ln_google_nobs, det
*All
lincom  pcc_se_nobs*0 + shortrun_nobs*0.480 + ols_nobs*0 + endogeneity_nobs*1 + linear_nobs*0 + doublelog_nobs*1 + unemployment_nobs*1 + income_nobs*1 + cross_nobs*0 + panel_nobs*1 + male_nobs*0.075 + female_nobs*0.051 + private_nobs*0.233 + public_nobs*0.454 + usa_nobs*0.839 + ln_pub_year_nobs*7.609 + ln_google_nobs*3.970 + published_nobs*1 
*Shortrun
lincom  pcc_se_nobs*0 + shortrun_nobs*1 + ols_nobs*0 + endogeneity_nobs*1 + linear_nobs*0 + doublelog_nobs*1 + unemployment_nobs*1 + income_nobs*1 + cross_nobs*0 + panel_nobs*1 + male_nobs*0.075 + female_nobs*0.051 + private_nobs*0.233 + public_nobs*0.454 + usa_nobs*0.839 + ln_pub_year_nobs*7.609 + ln_google_nobs*3.970 + published_nobs*1 
*Longrun
lincom  pcc_se_nobs*0 + shortrun_nobs*0 + ols_nobs*0 + endogeneity_nobs*1 + linear_nobs*0 + doublelog_nobs*1 + unemployment_nobs*1 + income_nobs*1 + cross_nobs*0 + panel_nobs*1 + male_nobs*0.075 + female_nobs*0.051 + private_nobs*0.233 + public_nobs*0.454 + usa_nobs*0.839 + ln_pub_year_nobs*7.609 + ln_google_nobs*3.970 + published_nobs*1 
*Private
lincom  pcc_se_nobs*0 + shortrun_nobs*0.480 + ols_nobs*0 + endogeneity_nobs*1 + linear_nobs*0 + doublelog_nobs*1 + unemployment_nobs*1 + income_nobs*1 + cross_nobs*0 + panel_nobs*1 + male_nobs*0.075 + female_nobs*0.051 + private_nobs*1 + public_nobs*0 + usa_nobs*0.839 + ln_pub_year_nobs*7.609 + ln_google_nobs*3.970 + published_nobs*1 
*Public
lincom  pcc_se_nobs*0 + shortrun_nobs*0.480 + ols_nobs*0 + endogeneity_nobs*1 + linear_nobs*0 + doublelog_nobs*1 + unemployment_nobs*1 + income_nobs*1 + cross_nobs*0 + panel_nobs*1 + male_nobs*0.075 + female_nobs*0.051 + private_nobs*0 + public_nobs*1 + usa_nobs*0.839 + ln_pub_year_nobs*7.609 + ln_google_nobs*3.970 + published_nobs*1 
*Male
lincom  pcc_se_nobs*0 + shortrun_nobs*0.480 + ols_nobs*0 + endogeneity_nobs*1 + linear_nobs*0 + doublelog_nobs*1 + unemployment_nobs*1 + income_nobs*1 + cross_nobs*0 + panel_nobs*1 + male_nobs*1 + female_nobs*0 + private_nobs*0.233 + public_nobs*0.454 + usa_nobs*0.839 + ln_pub_year_nobs*7.609 + ln_google_nobs*3.970 + published_nobs*1 
*Female
lincom  pcc_se_nobs*0 + shortrun_nobs*0.480 + ols_nobs*0 + endogeneity_nobs*1 + linear_nobs*0 + doublelog_nobs*1 + unemployment_nobs*1 + income_nobs*1 + cross_nobs*0 + panel_nobs*1 + male_nobs*0 + female_nobs*1 + private_nobs*0.233 + public_nobs*0.454 + usa_nobs*0.839 + ln_pub_year_nobs*7.609 + ln_google_nobs*3.970 + published_nobs*1 
window manage close graph
log close

