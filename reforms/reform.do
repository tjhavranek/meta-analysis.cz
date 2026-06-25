*** open reform.dta
set more off
log using "reform.log", replace

* generating partial correlations and their std errors
gen pcor = lib/sqrt(lib*lib+df)
gen pcor_cum = lib_cum/sqrt(lib_cum*lib_cum+df)
gen se_pcor = sqrt((1-pcor*pcor)/df)
gen se_pcor_cum = sqrt((1-pcor_cum*pcor_cum)/df)
gen se1_pcor = 1/se_pcor
gen se1_pcor_cum = 1/se_pcor_cum

*strange observations (outliers ??)
list obs study lib if se1_pcor>15 & pcor>0.3 & lib<12
gen odd =1 if  se1_pcor>15 & pcor>0.3 & lib<12

* plotting funnel charts: sample size (DF) versus partial correlations
twoway scatter df pcor if rg!=0 & lib<12 & odd!=1
twoway scatter df pcor_cum if rg!=0 & lib_cum<7.5

* simple mean
mean pcor if rg!=0 & lib<12 & odd!=1
mean pcor_cum if rg!=0 & lib_cum<7.5
metan pcor se_pcor if rg!=0 & lib<12 & odd!=1, nograph fixed
metan pcor_cum se_pcor_cum if rg!=0 & lib_cum<7.5, nograph fixed
metan pcor se_pcor if rg!=0 & lib<12 & odd!=1, nograph random
metan pcor_cum se_pcor_cum if rg!=0 & lib_cum<7.5, nograph random

* FAT-PET
reg lib se1_pcor if rg!=0 & lib<12 & odd!=1
reg lib_cum se1_pcor_cum if rg!=0 & lib_cum<7.5
rreg lib se1_pcor if rg!=0 & lib<12 & odd!=1
rreg lib_cum se1_pcor_cum if rg!=0 & lib_cum<7.5
reg lib se1_pcor if rg!=0 & lib<12 & odd!=1, vce(cluster study)
reg lib_cum se1_pcor_cum if rg!=0 & lib_cum<7.5, vce(cluster study)

* explanatory variables (preparation)
gen tspan = end - start
replace start=start-1983
sum k authaff panel endo fixed start tspan wb ebrd comb other lii lie lip margeff av cli lagdep speed lags time ic ic12 nic stabil nstab infl inst ninst fact nfact fsu pubpr journal lgoog_pa if lib!=. & lib<12 & odd!=1 & rg!=0 
* drop: panel, wb, other, lii, cli, fsu
sum k authaff endo fixed start tspan ebrd comb lie lip margeff av lagdep speed lags time ic ic12 nic stabil nstab infl inst ninst fact nfact pubpr journal lgoog_pa if lib!=. & lib<12 & odd!=1 & rg!=0

sum k authaff panel endo fixed start tspan wb ebrd comb other lii lie lip margeff av cli lagdep speed lags time ic ic12 nic stabil nstab infl inst ninst fact nfact fsu pubpr journal lgoog_pa if lib_cum!=. & rg!=0 & lib_cum<7.5 
* drop: other, fsu, wb
sum k authaff panel endo fixed start tspan ebrd comb lii lie lip margeff av cli lagdep speed lags time ic ic12 nic stabil nstab infl inst ninst fact nfact pubpr journal lgoog_pa if lib_cum!=. & rg!=0 & lib_cum<7.5

* divide by standard errors
local shortvar k authaff endo fixed start tspan ebrd comb lie lip margeff av lagdep speed lags time ic ic12 nic stabil nstab infl inst ninst fact nfact pubpr journal lgoog_pa
foreach x of varlist `shortvar' {
				gen `x'_se = `x' / se_pcor
}

local longvar k authaff panel endo fixed start tspan ebrd comb lii lie lip margeff av cli lagdep speed lags time ic ic12 nic stabil nstab infl inst ninst fact nfact pubpr journal lgoog_pa
foreach x of varlist `longvar' {
				gen `x'_se_cum = `x' / se_pcor_cum
}

* Save separately datasets for short run and long run
drop if lib==. | lib>12 | odd==1 | rg==0
drop if lib_cum==. | rg==0 | lib_cum>7.5

*** open combined.dta
twoway scatter df pcor
twoway (scatter df pcor if long==0) (scatter df pcor if long==1)
bysort longt: sum prec k authaff panel endo fixed start tspan ebrd comb lii lie lip margeff av cli lagdep speed lags time ic ic12 nic stabil nstab infl inst ninst fact nfact pubpr journal lgoog_pa
