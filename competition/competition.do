*Stata 13.1
*November 1, 2014 
*Data and paper available at http://meta-analysis.cz/competition
log using competition.log, replace
use competition.dta, clear
set more off

gen double invSEPCC = 1/SEPCC
gen double lnobs = ln(Samplesize)
gen double root=sqrt(Samplesize)
gen double invlnobs=1/lnobs
gen double invroot=1/root
bysort IDStudy: egen PCCmed = median(PCC)
bysort IDStudy: egen invSEPCCmed = median(invSEPCC)
bysort IDStudy: egen SEPCCmed = median(SEPCC)
bysort IDStudy: egen tmed = median(t)

*Summary statistics and plots:
graph twoway (scatter PCCmed firstpub, msize(*1.5) msymbol(Oh)) (lfit PCCmed firstpub)
mean PCC
mean PCCmed
mean PCC if reviewed_journal==1
hist PCC

ivreg2 PCC, cluster (IDStudy)
ivreg2 PCC if developed==1, cluster (IDStudy)
ivreg2 PCC if undeveloped==1, cluster (IDStudy)
ivreg2 PCC [pweight=investperst], cluster (IDStudy)
ivreg2 PCC if developed==1 [pweight=investperst], cluster (IDStudy)
ivreg2 PCC if undeveloped==1 [pweight=investperst], cluster (IDStudy)

*Funnel plots:
scatter invSEPCC PCC, msize(*.9) msymbol(Oh)
scatter invSEPCCmed PCCmed, msize(*.9) msymbol(Oh)

*Funnel asymmetry tests:

eststo: xtreg PCC SEPCC, fe vce(cluster IDStudy)
eststo: xtreg PCC SEPCC if reviewed_journal==1, fe vce(cluster IDStudy)
eststo: xtivreg2 PCC (SEPCC=lnobs), fe cluster(IDStudy)
eststo: xtivreg2 PCC (SEPCC=lnobs) if reviewed_journal==1, fe cluster(IDStudy)
gen double root=sqrt(Samplesize)
eststo: xtivreg2 PCC (SEPCC=root), fe cluster(IDStudy)
eststo: xtivreg2 PCC (SEPCC=root) if reviewed_journal==1, fe cluster(IDStudy)
eststo: xtivreg PCC (SEPCC=lnobs), fe
eststo: xtivreg PCC (SEPCC=lnobs) if reviewed_journal==1, fe
eststo: xtivreg PCC (SEPCC=root), fe
eststo: xtivreg PCC (SEPCC=root) if reviewed_journal==1, fe
eststo: xtreg PCC SEPCC [pweight=investperst], fe vce(cluster IDStudy)
eststo: xtreg PCC SEPCC [pweight=investperst] if reviewed_journal==1, fe vce(cluster IDStudy)
eststo: xtreg t invSEPCC, fe vce(cluster IDStudy)
eststo: xtreg t invSEPCC if reviewed_journal==1, fe vce(cluster IDStudy)
eststo: xtivreg t (invSEPCC=invlnobs), fe
eststo: xtivreg t (invSEPCC=invlnobs) if reviewed_journal==1, fe
eststo: xtivreg t (invSEPCC=invroot), fe
eststo: xtivreg t (invSEPCC=invroot) if reviewed_journal==1, fe
eststo: xtreg t invSEPCC [pweight=investperst], fe vce(cluster IDStudy)
eststo: xtreg t invSEPCC [pweight=investperst] if reviewed_journal==1, fe vce(cluster IDStudy)

*Box plot:

label define stu 1 "Agoraki et al. (2011)"
label define stu 2 "Anginer et al. (2014)", add
.
.
.
label values IDStudy stu
graph hbox PCC, over(IDStudy)

*Best practice:

sum SEPCC dummies Hstatistic developed undeveloped Logit Samplesize citations firstpub quadratic Boone IFrecursive regulation OLS reviewed_journal [aweight=investperst]

ivreg2 PCC SEPCC dummies Hstatistic developed undeveloped Logit Samplesize citations firstpub quadratic Boone IFrecursive regulation OLS reviewed_journal [pweight=investperst], cluster (IDStudy)

*Weighted:

lincom  _cons + SEPCC*0 + Samplesize*11.3 + IFrecursive*0.744 + citations*4.164078 +firstpub*6.677419 + reviewed_journal*1 + dummies*0 +  Hstatistic*0 + developed*0.3663594 + undeveloped*0.375576 + Logit*0 +regulation*1 + quadratic*0 + Boone*1 +OLS*0

lincom  _cons + SEPCC*0 + Samplesize*11.3 + IFrecursive*0.744 + citations*4.164078 +firstpub*6.677419 + reviewed_journal*1  + dummies*0 +  Hstatistic*0 + developed*1+ Logit*0 +regulation*1 + quadratic*0 + Boone*1 +OLS*0

lincom  _cons + SEPCC*0 + Samplesize*11.3 + IFrecursive*0.744 + citations*4.164078 +firstpub*6.677419 + reviewed_journal*1  + dummies*0 +  Hstatistic*0 + undeveloped*1 + Logit*0 +regulation*1 + quadratic*0 + Boone*1 +OLS*0

sum SEPCC  dummies Hstatistic developed undeveloped FE Samplesize ownership Logit TSLS firstpub citations profitability IFrecursive

ivreg2 PCC SEPCC  dummies Hstatistic developed undeveloped FE Samplesize ownership Logit TSLS firstpub citations profitability IFrecursive, cluster (IDStudy)

*Unweighted:

lincom _cons+SEPCC*0+dummies*0+Hstatistic*0+developed*0.3663594+undeveloped*0.375576+TSLS*0.1488294+Logit*0+FE*0.229097+Samplesize*11.3+IFrecursive*0.744+citations*4.164078+firstpub*6.453177+ ownership*0.1655518+profitability*0.0434783

lincom _cons+SEPCC*0+dummies*0+Hstatistic*0+developed*1+TSLS*0.1488294+Logit*0+FE*0.229097+Samplesize*11.3+IFrecursive*0.744+citations*4.164078+firstpub*6.453177+ ownership*0.1655518+profitability*0.0434783

lincom _cons+SEPCC*0+dummies*0+Hstatistic*0+undeveloped*1+TSLS*0.1488294+Logit*0+FE*0.229097+Samplesize*11.3+IFrecursive*0.744+citations*4.164078+firstpub*6.453177+ ownership*0.1655518+profitability*0.0434783

*Weighted – pure competition estimates:

lincom  _cons + SEPCC*0 + Samplesize*11.3 + IFrecursive*0.661 + citations*3.563478 +firstpub*7.304348 + reviewed_journal*1 + dummies*0 +  Hstatistic*0 + developed*0.4347826 + undeveloped*0.3043478 + regulation*1 + quadratic*0 + Boone*1 +OLS*0

lincom  _cons + SEPCC*0 + Samplesize*11.3 + IFrecursive*0.661 + citations*3.563478 +firstpub*7.304348 + reviewed_journal*1  + dummies*0 +  Hstatistic*0 + developed*1+ regulation*1 + quadratic*0 + Boone*1 +OLS*0

lincom  _cons + SEPCC*0 + Samplesize*11.3 + IFrecursive*0.661 + citations*3.563478 +firstpub*7.304348 + reviewed_journal*1  + dummies*0 +  Hstatistic*0 + undeveloped*1 + regulation*1 + quadratic*0 + Boone*1 +OLS*0

*Unweighted – pure competition estimates:

lincom _cons+SEPCC*0+dummies*0+Hstatistic*0+developed*0.315942+undeveloped*0.2405797+TSLS*0.2521739+FE*0.1594203+Samplesize*11.3+IFrecursive*0.661+citations*3.563478+firstpub*7.97971+ ownership*0.226087+profitability*0.0231884

lincom _cons+SEPCC*0+dummies*0+Hstatistic*0+developed*1+TSLS*0.2521739+FE*0.1594203+Samplesize*11.3+IFrecursive*0.661+citations*3.563478+firstpub*7.97971+ ownership*0.226087+profitability*0.0231884

lincom _cons+SEPCC*0+dummies*0+Hstatistic*0+undeveloped*1+TSLS*0.2521739+FE*0.1594203+Samplesize*11.3+IFrecursive*0.661+citations*3.563478+firstpub*7.97971+ ownership*0.226087+profitability*0.0231884

*BMA: switch to R
Comp = bms(weighted, burn=1000 000, iter=2000 000, g="UIP", mprior="uniform", nmodel=5000, mcmc="bd", user.int=FALSE)
Comp2 = bms(weighted, burn=1000 000, iter=2000 000, g="BRIC", mprior="random", nmodel=5000, mcmc="bd", user.int=FALSE)
Comp3 = bms(unweighted, burn=1000 000, iter=2000 000, g="UIP", mprior="uniform", nmodel=5000, mcmc="bd", user.int=FALSE)

plot(Comp)
summary(Comp)
plot(Comp2)
summary(Comp2)
plot(Comp3)
summary(Comp3)

coef(Comp, order.by.pip = T, exact=T, include.constant=T)
image(Comp, cex.axis=0.7, order.by.pip = T, yprop2pip=F)
coef(Comp2, order.by.pip = T, exact=T, include.constant=T)
image(Comp2, cex.axis=0.7, order.by.pip = T, yprop2pip=F)
coef(Comp3, order.by.pip = T, exact=T, include.constant=T)
image(Comp3, cex.axis=0.7, order.by.pip = T, yprop2pip=F)









