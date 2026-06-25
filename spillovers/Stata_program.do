******************************************************************************
******************************************************************************
******************************************************************************
*WHICH FOREIGNERS ARE WORTH WOOING?
*A META-ANALYSIS OF VERTICAL SPILLOVERS FROM FDI
******************************************************************************
log using "C:\Research\Papers\Meta-analysis\Stata\results.log", replace
use "C:\Research\Papers\Meta-analysis\Stata\data.dta", clear
set more off
******************************************************************************
*DEFINITION OF BASIC VARIABLES
******************************************************************************
drop if aux==1
drop aux
gen back= ((horiz==0 & forw==0) | (horiz==0 & local==1))
gen prec=1/se
gen top= (idstudy==5| idstudy==6| idstudy==7| idstudy==16| idstudy==17| idstudy==22| idstudy==23) // Top journals
gen top2= (idstudy==5| idstudy==6| idstudy==7| idstudy==16| idstudy==17| idstudy==22| idstudy==23 | idstudy==2) // +World Economy
gen top3= (idstudy==16| idstudy==5| idstudy==39| idstudy==12| idstudy==17| idstudy==63| idstudy==22) // 7 top cited in RePEc
gen top4= (idstudy==16| idstudy==5| idstudy==39| idstudy==12| idstudy==17| idstudy==63| idstudy==22 | idstudy==43) // +8th top cited in RePEc
gen tb=eb/seb
gen precb=1/seb
gen tf=ef/sef
gen precf=1/sef
gen th=eh/seh
gen prech=1/seh
******************************************************************************
*OUTLIERS
******************************************************************************
hadimvo e prec if back==1, gen(oddb) p(.001)
hadimvo e prec if forw==1, gen(oddf) p(.001)
hadimvo e prec if horiz==1, gen(oddh) p(.001)
gen odd= (oddb==1 | oddf==1 | oddh==1)
drop oddb oddf oddh
ttest repimp, by(odd)
ttest jcrimp, by(odd)
ttest eigen, by(odd)
ttest sjrimp, by(odd)
******************************************************************************
*FUNNEL PLOTS
******************************************************************************
scatter prec e if back==1 & odd==0, saving(funnel_back, replace) msize(*.5) msymbol(Oh)
scatter prec e if forw==1 & odd==0, saving(funnel_forw, replace) msize(*.5) msymbol(Oh)
scatter prec e if horiz==1 & odd==0, saving(funnel_horiz, replace) msize(*.5) msymbol(Oh) r1title("All studies", box bexpand)
scatter prec e if back==1 & odd==0 & top==1, saving(funnel_back_top, replace) msize(*.7) msymbol(Oh) t1title("Backward", box bexpand)
scatter prec e if forw==1 & odd==0 & top==1, saving(funnel_forw_top, replace) msize(*.7) msymbol(Oh) t1title("Forward", box bexpand)
scatter prec e if horiz==1 & odd==0 & top==1, saving(funnel_horiz_top, replace) msize(*.7) msymbol(Oh) t1title("Horizontal", box bexpand) r1title("Top journals", box bexpand)
gr combine funnel_back_top.gph funnel_forw_top.gph funnel_horiz_top.gph funnel_back.gph funnel_forw.gph funnel_horiz.gph, saving(funnel, replace) imargin(0 0 0 0)
graph hbox e if back==1 & country=="China", over(study) saving(box, replace) nooutside
******************************************************************************
*SUMMARY OF SPILLOVER VARIABLES
******************************************************************************
summarize e if back==1 & odd==0
summarize e if forw==1 & odd==0
summarize e if horiz==1 & odd==0
mean e if back==1 & odd==0
mean e if forw==1 & odd==0
mean e if horiz==1 & odd==0
mean e if back==1
mean e if forw==1
mean e if horiz==1
mean e if back==1 & odd==0 & top==1
mean e if forw==1 & odd==0 & top==1
mean e if horiz==1 & odd==0 & top==1
bysort pub: summarize e if back==1 & odd==0
bysort pub: summarize e if forw==1 & odd==0
bysort pub: summarize e if horiz==1 & odd==0
******************************************************************************
*TOP JOURNALS, FAT-PET, BACKWARD SPILLOVERS
******************************************************************************
eststo: xtmixed t prec || idstudy: if back==1 & odd==0 & top==1
eststo: reg t prec if back==1 & odd==0 & top==1, vce(cluster idstudy)
xtmixed t prec || idauthor: || idstudy: if back==1 & odd==0 & top==1
xtmixed t prec || idauthor: if back==1 & odd==0 & top==1
xtmixed t prec || idcountry: if back==1 & odd==0 & top==1
xtmixed t prec || idstudy: if back==1 & odd==0 & top2==1
xtmixed t prec || idstudy: if back==1 & odd==0 & top3==1
xtmixed t prec || idstudy: if back==1 & odd==0 & top4==1
******************************************************************************
*TOP JOURNALS, FAT-PET, FORWARD SPILLOVERS
******************************************************************************
eststo: xtmixed t prec || idstudy: if forw==1 & odd==0 & top==1
eststo: reg t prec if forw==1 & odd==0 & top==1, vce(cluster idstudy)
xtmixed t prec || idauthor: || idstudy: if forw==1 & odd==0 & top==1
xtmixed t prec || idauthor: if forw==1 & odd==0 & top==1
xtmixed t prec || idcountry: if forw==1 & odd==0 & top==1
xtmixed t prec || idstudy: if forw==1 & odd==0 & top2==1
xtmixed t prec || idstudy: if forw==1 & odd==0 & top3==1
xtmixed t prec || idstudy: if forw==1 & odd==0 & top4==1
******************************************************************************
*TOP JOURNALS, FAT-PET, HORIZONTAL SPILLOVERS
******************************************************************************
eststo: xtmixed t prec || idstudy: if horiz==1 & odd==0 & top==1
eststo: reg t prec if horiz==1 & odd==0 & top==1, vce(cluster idstudy)
xtmixed t prec || idauthor: || idstudy: if horiz==1 & odd==0 & top==1
xtmixed t prec || idauthor: if horiz==1 & odd==0 & top==1
xtmixed t prec || idcountry: if horiz==1 & odd==0 & top==1
xtmixed t prec || idstudy: if horiz==1 & odd==0 & top2==1
xtmixed t prec || idstudy: if horiz==1 & odd==0 & top3==1
xtmixed t prec || idstudy: if horiz==1 & odd==0 & top4==1
esttab using tables\topbias.tex, se booktabs replace compress title(Test of publication bias and true effect, top journals\label{tab:topbias}) mgroups("Backward" "Forward" "Horizontal", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("RE" "Cluster" "RE" "Cluster" "RE" "Cluster") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps scalars(chi2_c) width(1\hsize)
eststo clear
******************************************************************************
*ALL STUDIES, FAT-PET, BACKWARD SPILLOVERS
******************************************************************************
eststo: xtmixed t prec || idstudy: if back==1 & odd==0
eststo: xtmixed t prec || idstudy: if back==1 & odd==0 & pub==1
xtmixed t prec || idstudy: if back==1
eststo: xtmixed t prec || idstudy: if back==1 & odd==0 & local==0 & cs==0 & aggr==0 & comb==0 & more==0 & lin==0 & loglog==0
metan e se if back==1, by(idstudy) random nograph
eststo: mmregress tb precb if last==1
xtmixed t prec || idauthor: || idstudy: if back==1 & odd==0
xtmixed t prec || idauthor: if back==1 & odd==0
xtmixed t prec || idcountry: || idauthor: || idstudy: if back==1 & odd==0
xtmixed t prec || idcountry: if back==1 & odd==0
esttab using tables\allback.tex, se booktabs replace compress title(Test of publication bias and true effect, all studies\label{tab:all}) mgroups("Backward", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("All" "Published" "Homogeneous" "Robust") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps scalars(chi2_c) width(1\hsize)
eststo clear
******************************************************************************
*ALL STUDIES, FAT-PET, FORWARD SPILLOVERS
******************************************************************************
eststo: xtmixed t prec || idstudy: if forw==1 & odd==0
eststo: xtmixed t prec || idstudy: if forw==1 & odd==0 & pub==1
xtmixed t prec || idstudy: if forw==1
eststo: xtmixed t prec || idstudy: if forw==1 & odd==0 & local==0 & cs==0 & aggr==0 & comb==0 & more==0 & lin==0 & loglog==0
metan e se if forw==1, by(idstudy) random nograph
eststo: mmregress tf precf if last==1
xtmixed t prec || idauthor: || idstudy: if forw==1 & odd==0
xtmixed t prec || idauthor: if forw==1 & odd==0
xtmixed t prec || idcountry: || idauthor: || idstudy: if forw==1 & odd==0
xtmixed t prec || idcountry: if back==1 & odd==0
esttab using tables\allforw.tex, se booktabs replace compress title(Test of publication bias and true effect, all studies\label{tab:all}) mgroups("Backward", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("All" "Published" "Homogeneous" "Robust") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps scalars(chi2_c) width(1\hsize)
eststo clear
******************************************************************************
*ALL STUDIES, FAT-PET, HORIZONTAL SPILLOVERS
******************************************************************************
eststo: xtmixed t prec || idstudy: if horiz==1 & odd==0
eststo: xtmixed t prec || idstudy: if horiz==1 & odd==0 & pub==1
xtmixed t prec || idstudy: if horiz==1
eststo: xtmixed t prec || idstudy: if horiz==1 & odd==0 & local==0 & cs==0 & aggr==0 & comb==0 & more==0 & lin==0 & loglog==0
metan e se if horiz==1, by(idstudy) random nograph
eststo: mmregress th prech if last==1
xtmixed t prec || idauthor: || idstudy: if horiz==1 & odd==0
xtmixed t prec || idauthor: if horiz==1 & odd==0
xtmixed t prec || idcountry: || idauthor: || idstudy: if horiz==1 & odd==0
xtmixed t prec || idcountry: if horiz==1 & odd==0
esttab using tables\allhoriz.tex, se booktabs replace compress title(Test of publication bias and true effect, all studies\label{tab:all}) mgroups("Backward", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("All" "Published" "Homogeneous" "Robust") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps scalars(chi2_c) width(1\hsize)
eststo clear
******************************************************************************
*RANDOM-EFFECTS META-ANALYSIS BY COUNTRIES
******************************************************************************
metan e se if back==1, by(country) random nograph
metan e se if forw==1, by(country) random nograph
metan e se if horiz==1, by(country) random nograph
drop _*
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
gen onestep=output==1|lp==1
drop output lp
drop  table orige origse mean1 mean2 start end nat realpart forpart nace io check comment
replace findev=findev/100
replace open=open/100
local allvariables cs aggr lnfirms tspan avgyear amad serv onestep gmm op ols pols rand yearfe sectfe translog nloglin diff bothbf bothvh empl asset allfirm green ma ac scomp cycl local lag more comb lndist lngap open findev gp95 repimp lnschcit pub native lnciteaut affusa pubdate
foreach x of varlist `allvariables' {
				gen `x'_se = `x' / se
}
******************************************************************************
*LABELS OF VARIABLES
******************************************************************************
label variable lndist "Distance"
label variable lngap	 "Technology gap"
label variable open	 "Openness"
label variable findev	 "Financial dev."
label variable gp95	 "Patent rights"
label variable green	 "Fully owned"
label variable ma	 "Joint ventures"
label variable serv	 "Services"
label variable prec	 "1/SE"
label variable cs	 "Cross-sectional"
label variable aggr	 "Aggregated"
label variable tspan	 "Time span"
label variable lnfirms	 "Firms"
label variable avgyear	 "Average year"
label variable amad	 "Amadeus"
label variable bothbf	 "Forward"
label variable bothvh	 "Horizontal"
label variable empl	 "Employment"
label variable asset	 "Equity"
label variable allfirm	 "All firms"
label variable ac	 "Absorption"
label variable scomp	 "Competition"
label variable cycl	 "Cyclicality"
label variable local	 "Regional"
label variable lag	 "Lagged"
label variable more	 "More"
label variable comb	 "Combination"
label variable onestep	 "One step"
label variable op	 "Olley-Pakes"
label variable ols	 "OLS"
label variable gmm	 "GMM"
label variable rand	 "Random"
label variable pols	 "Pooled OLS"
label variable yearfe	 "Year fixed"
label variable sectfe	 "Sector fixed"
label variable diff	 "Differences"
label variable translog	 "Translog"
label variable nloglin	 "Log-log"
label variable pub	 "Published"
label variable repimp	 "Impact"
label variable lnschcit	 "Study citations"
label variable native	 "Native"
label variable lnciteaut	 "Author citations"
label variable affusa	 "US-based"
label variable pubdate	 "Publication date"
label variable lndist_se "Distance"
label variable lngap_se	 "Technology gap"
label variable open_se	 "Openness"
label variable findev_se	 "Financial dev."
label variable gp95_se	 "Patent rights"
label variable green_se	 "Fully owned"
label variable ma_se	 "Joint ventures"
label variable serv_se	 "Services"
label variable cs_se	 "Cross-sectional"
label variable aggr_se	 "Aggregated"
label variable tspan_se	 "Time span"
label variable lnfirms_se	 "Firms"
label variable avgyear_se	 "Average year"
label variable amad_se	 "Amadeus"
label variable bothbf_se	 "Forward"
label variable bothvh_se	 "Horizontal"
label variable empl_se	 "Employment"
label variable asset_se	 "Equity"
label variable allfirm_se	 "All firms"
label variable ac_se	 "Absorption"
label variable scomp_se	 "Competition"
label variable cycl_se	 "Cyclicality"
label variable local_se	 "Regional"
label variable lag_se	 "Lagged"
label variable more_se	 "More"
label variable comb_se	 "Combination"
label variable onestep_se	 "One step"
label variable op_se	 "Olley-Pakes"
label variable ols_se	 "OLS"
label variable gmm_se	 "GMM"
label variable rand_se	 "Random"
label variable pols_se	 "Pooled OLS"
label variable yearfe_se	 "Year fixed"
label variable sectfe_se	 "Sector fixed"
label variable diff_se	 "Differences"
label variable translog_se	 "Translog"
label variable nloglin_se	 "Log-log"
label variable pub_se	 "Published"
label variable repimp_se	 "Impact"
label variable lnschcit_se	 "Study citations"
label variable native_se	 "Native"
label variable lnciteaut_se	 "Author citations"
label variable affusa_se	 "US-based"
label variable pubdate_se	 "Publication date"
******************************************************************************
******************************************************************************
*MULTIVARIATE MRA, BACKWARD SPILLOVERS
******************************************************************************
*SUMMARY STATISTICS
******************************************************************************
estpost summarize t prec `allvariables' if back==1 & odd==0
esttab using tables\summary.tex, booktabs replace compress width(1\hsize) title(Summary statistics of regression variables\label{tab:summary}) cells("mean sd min max") nonumber nomtitle nogaps
eststo clear
collin prec `allvariables' if back==1 & odd==0
correl prec `allvariables' if back==1 & odd==0
******************************************************************************
*GENERAL MODEL
******************************************************************************
xtmixed t prec lndist_se lngap_se open_se findev_se gp95_se serv_se green_se ma_se aggr_se avgyear_se amad_se onestep_se op_se ols_se pols_se sectfe_se diff_se empl_se scomp_se cycl_se lnschcit_se pub_se native_se lnciteaut_se pubdate_se lag_se nloglin_se bothvh_se lnfirms_se ac_se allfirm_se bothbf_se repimp_se rand_se translog_se more_se cs_se yearfe_se local_se tspan_se gmm_se asset_se comb_se affusa_se || idstudy: if back==1 & odd==0
test lag_se nloglin_se bothvh_se lnfirms_se ac_se allfirm_se bothbf_se repimp_se rand_se translog_se more_se cs_se yearfe_se local_se tspan_se gmm_se asset_se comb_se affusa_se
test gp95_se ma_se lag_se nloglin_se bothvh_se lnfirms_se ac_se allfirm_se bothbf_se repimp_se rand_se translog_se more_se cs_se yearfe_se local_se tspan_se gmm_se asset_se comb_se affusa_se
local controls_se aggr_se avgyear_se amad_se empl_se scomp_se cycl_se onestep_se op_se ols_se pols_se sectfe_se diff_se  pub_se lnschcit_se native_se lnciteaut_se pubdate_se
******************************************************************************
*FULL STRUCTURAL MODEL AND ROBUSTNESS CHECKS
******************************************************************************
eststo: xtmixed t prec lndist_se lngap_se open_se findev_se gp95_se green_se ma_se serv_se `controls_se' || idstudy: if back==1 & odd==0
eststo: xtmixed t prec lndist_se open_se gp95_se serv_se ma_se `controls_se' || idstudy: if back==1 & odd==0
eststo: xtmixed t prec lngap_se findev_se serv_se green_se ma_se `controls_se' || idstudy: if back==1 & odd==0
******************************************************************************
*SPECIFIC MODEL AND ROBUSTNESS CHECKS
******************************************************************************
eststo: xtmixed t prec lndist_se lngap_se open_se findev_se serv_se green_se `controls_se' || idstudy: if back==1 & odd==0
eststo: reg t prec lndist_se lngap_se open_se findev_se serv_se green_se `controls_se' if back==1 & odd==0, vce(cluster idstudy)
xtmixed t prec lndist_se lngap_se open_se findev_se serv_se green_se `controls_se' || idstudy: if back==1
xtmixed t prec lndist_se lngap_se open_se findev_se serv_se green_se `controls_se' || idauthor: || idstudy: if back==1 & odd==0
xtmixed t prec lndist_se lngap_se open_se findev_se serv_se green_se `controls_se' || idauthor: if back==1 & odd==0
xtmixed t prec lndist_se lngap_se open_se findev_se serv_se green_se `controls_se' || idcountry: || idauthor: || idstudy: if back==1 & odd==0
xtmixed t prec lndist_se lngap_se open_se findev_se serv_se green_se `controls_se' || idcountry: if back==1 & odd==0
reg t prec lndist_se lngap_se open_se findev_se serv_se green_se `controls_se' if back==1 & odd==0, vce(cluster idauthor)
reg t prec lndist_se lngap_se open_se findev_se serv_se green_se `controls_se' if back==1 & odd==0, vce(cluster idcountry)
esttab using tables\multi.tex, se booktabs replace compress title(Multivariate meta-regression\label{tab:multi}) mtitles("All" "Distance" "Technology gap" "Specific" "Cluster") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps scalars(chi2_c) width(1\hsize)
eststo clear
******************************************************************************
*COUNTRY-LEVEL VARIABLES INCLUDED ONE BY ONE
******************************************************************************
xtmixed t prec lndist_se serv_se green_se ma_se `controls_se' || idstudy: if back==1 & odd==0
xtmixed t prec lngap_se serv_se green_se ma_se `controls_se' || idstudy: if back==1 & odd==0
xtmixed t prec open_se serv_se green_se ma_se `controls_se' || idstudy: if back==1 & odd==0
xtmixed t prec findev_se serv_se green_se ma_se `controls_se' || idstudy: if back==1 & odd==0
xtmixed t prec gp95_se serv_se green_se ma_se `controls_se' || idstudy: if back==1 & odd==0
******************************************************************************
*BEST PRACTICE
******************************************************************************
xtmixed t prec lndist_se lngap_se open_se findev_se serv_se green_se `controls_se' || idstudy: if back==1 & odd==0
lincom prec + 7.769428*lndist_se + 9.816206*lngap_se + 0.7039733*open_se + 0.6143713*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 3.5*avgyear_se + 0.2227307*amad_se + 0.1868802*op_se + sectfe_se + diff_se + 0.1418764*empl_se + scomp_se + cycl_se + 4.525519*lnschcit_se + pub_se + native_se + 6.660575*lnciteaut_se + 7.844069*pubdate_se
bysort top: summarize aggr scomp cycl onestep ols pols sectfe diff
******************************************************************************
*AVERAGE QUALITY
******************************************************************************
lincom prec + 7.769428*lndist_se + 9.816206*lngap_se + 0.7039733*open_se + 0.6143713*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 3.5*avgyear_se + 0.2227307*amad_se + 0.1868802*op_se + sectfe_se + diff_se + 0.1418764*empl_se + scomp_se + cycl_se + 1.164344*lnschcit_se + 0.2883295*pub_se + 0.7116705*native_se + 3.075774*lnciteaut_se + 7.844069*pubdate_se
******************************************************************************
*AVERAGE QUALITY AND DATA
******************************************************************************
lincom prec + 7.769428*lndist_se + 9.816206*lngap_se + 0.7039733*open_se + 0.6143713*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 0.0327994*aggr_se + -0.9586321*avgyear_se + 0.2227307*amad_se + 0.1868802*op_se + sectfe_se + diff_se + 0.1418764*empl_se + scomp_se + cycl_se + 1.164344*lnschcit_se + 0.2883295*pub_se + 0.7116705*native_se + 3.075774*lnciteaut_se + 7.844069*pubdate_se
******************************************************************************
*AVERAGE QUALITY, DATA, AND METHODS
******************************************************************************
lincom prec + 7.769428*lndist_se + 9.816206*lngap_se + 0.7039733*open_se + 0.6143713*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 0.0327994*aggr_se - 0.9586321*avgyear_se + 0.2227307*amad_se + 0.4294432*onestep_se + 0.1868802*op_se + 0.1067887*ols_se +0.157132*pols_se +0.4942792*sectfe_se +0.4561404*diff_se + 0.1418764*empl_se +0.2723112*scomp_se +0.0747521*cycl_se + 1.164344*lnschcit_se +0.2883295*pub_se +0.7116705*native_se + 3.075774*lnciteaut_se + 7.844069*pubdate_se
******************************************************************************
*WORST PRACTICE
******************************************************************************
lincom prec + 7.769428*lndist_se + 9.816206*lngap_se + 0.7039733*open_se + 0.6143713*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 0.0327994*aggr_se - 14*avgyear_se + 0.2227307*amad_se + 0*onestep_se + 0*op_se + 1*ols_se +pols_se +0*sectfe_se +0*diff_se + 0.1418764*empl_se +0*scomp_se +0*cycl_se + 0*lnschcit_se +0*pub_se +0*native_se + 0*lnciteaut_se + 7.844069*pubdate_se
******************************************************************************
*BEST PRACTICE, WITH OUTLIERS
******************************************************************************
xtmixed t prec lndist_se lngap_se open_se findev_se gp95_se serv_se green_se ma_se aggr_se avgyear_se amad_se onestep_se op_se ols_se pols_se sectfe_se diff_se empl_se scomp_se cycl_se lnschcit_se pub_se native_se lnciteaut_se pubdate_se lag_se nloglin_se bothvh_se lnfirms_se ac_se allfirm_se bothbf_se repimp_se rand_se translog_se more_se cs_se yearfe_se local_se tspan_se gmm_se asset_se comb_se affusa_se || idstudy: if back==1
test bothvh_se cs_se ac_se rand_se bothbf_se green_se pub_se gp95_se yearfe_se comb_se repimp_se allfirm_se translog_se diff_se affusa_se sectfe_se gmm_se nloglin_se asset_se lag_se local_se lnfirms_se ma_se findev_se
xtmixed t prec lndist_se lngap_se open_se serv_se aggr_se avgyear_se amad_se onestep_se op_se ols_se pols_se empl_se scomp_se cycl_se lnschcit_se native_se lnciteaut_se pubdate_se more_se tspan_se || idstudy: if back==1
lincom prec + 7.792039*lndist_se + 9.809881*lngap_se + 0.6962812*open_se + 0.042796*serv_se + 3.5*avgyear_se + 0.2296719*amad_se +0.1997147*op_se + 0.1426534*empl_se + scomp_se + cycl_se + 4.525519*lnschcit_se + native_se + 6.660575*lnciteaut_se + 7.843353*pubdate_se + 16*tspan_se
******************************************************************************
*BEST PRACTICE, CLUSTERED OLS
******************************************************************************
reg t prec lndist_se lngap_se open_se findev_se gp95_se serv_se green_se ma_se aggr_se avgyear_se amad_se onestep_se op_se ols_se pols_se sectfe_se diff_se empl_se scomp_se cycl_se lnschcit_se pub_se native_se lnciteaut_se pubdate_se lag_se nloglin_se bothvh_se lnfirms_se ac_se allfirm_se bothbf_se repimp_se rand_se translog_se more_se cs_se yearfe_se local_se tspan_se gmm_se asset_se comb_se affusa_se if back==1 & odd==0, vce(cluster idstudy)
test ac_se ma_se bothvh_se more_se nloglin_se gmm_se lnfirms_se repimp_se affusa_se translog_se local_se pubdate_se lag_se findev_se lnschcit_se allfirm_se yearfe_se comb_se
reg t prec lndist_se lngap_se open_se gp95_se serv_se green_se aggr_se avgyear_se amad_se onestep_se op_se ols_se pols_se sectfe_se diff_se empl_se scomp_se cycl_se pub_se native_se lnciteaut_se bothbf_se cs_se tspan_se asset_se rand_se if back==1 & odd==0, vce(cluster idstudy)
lincom prec + 7.769428*lndist_se + 9.816206*lngap_se +0.7039733*open_se + 2.992687*gp95_se + 0.0457666*serv_se + 0.0686499*green_se + 3.5*avgyear_se + 0.2227307*amad_se + 0.1868802*op_se + sectfe_se + diff_se + 0.1418764*empl_se + scomp_se + cycl_se + native_se + 6.660575*lnciteaut_se + bothbf_se + 16*tspan_se + 0.0602593*asset_se
******************************************************************************
******************************************************************************
*MULTIVARIATE MRA, FORWARD SPILLOVERS
******************************************************************************
collin prec `allvariables' if forw==1 & odd==0
xtmixed t prec lndist_se lngap_se open_se findev_se gp95_se serv_se green_se ma_se aggr_se avgyear_se amad_se onestep_se op_se ols_se pols_se sectfe_se diff_se empl_se scomp_se cycl_se lnschcit_se pub_se native_se lnciteaut_se pubdate_se lag_se nloglin_se bothvh_se lnfirms_se ac_se allfirm_se bothbf_se repimp_se rand_se translog_se more_se cs_se yearfe_se local_se tspan_se gmm_se asset_se comb_se affusa_se || idstudy: if forw==1 & odd==0
test lag_se ac_se bothbf_se lndist_se amad_se asset_se pub_se ols_se open_se lnfirms_se lngap_se translog_se onestep_se green_se allfirm_se affusa_se bothvh_se gp95_se yearfe_se findev_se
xtmixed t prec serv_se ma_se aggr_se avgyear_se op_se pols_se sectfe_se diff_se empl_se scomp_se cycl_se lnschcit_se native_se lnciteaut_se pubdate_se nloglin_se repimp_se rand_se more_se cs_se local_se tspan_se gmm_se comb_se || idstudy: if forw==1 & odd==0
lincom prec + 0.0543689*serv_se + 0.0349515*ma_se + 3.5*avgyear_se + sectfe_se + diff_se + 0.1592233*empl_se + scomp_se + cycl_se + 4.52519*lnschcit_se + native_se + 6.660575*lnciteaut_se + 7.861732*pubdate_se + 2.704*repimp_se + 16*tspan_se
xtmixed t prec serv_se ma_se aggr_se avgyear_se op_se pols_se sectfe_se diff_se empl_se scomp_se cycl_se lnschcit_se native_se lnciteaut_se pubdate_se nloglin_se repimp_se rand_se more_se cs_se local_se tspan_se gmm_se comb_se || idstudy: if forw==1
lincom prec + 0.0543689*serv_se + 0.0349515*ma_se + 3.5*avgyear_se + sectfe_se + diff_se + 0.1592233*empl_se + scomp_se + cycl_se + 4.52519*lnschcit_se + native_se + 6.660575*lnciteaut_se + 7.861732*pubdate_se + 2.704*repimp_se + 16*tspan_se
reg t prec serv_se ma_se aggr_se avgyear_se op_se pols_se sectfe_se diff_se empl_se scomp_se cycl_se lnschcit_se native_se lnciteaut_se pubdate_se nloglin_se repimp_se rand_se more_se cs_se local_se tspan_se gmm_se comb_se if forw==1 & odd==0, vce(cluster idstudy)
lincom prec + 0.0543689*serv_se + 0.0349515*ma_se + 3.5*avgyear_se + sectfe_se + diff_se + 0.1592233*empl_se + scomp_se + cycl_se + 4.52519*lnschcit_se + native_se + 6.660575*lnciteaut_se + 7.861732*pubdate_se + 2.704*repimp_se + 16*tspan_se
xtmixed t prec serv_se ma_se aggr_se avgyear_se op_se pols_se sectfe_se diff_se empl_se scomp_se cycl_se lnschcit_se native_se lnciteaut_se pubdate_se nloglin_se repimp_se rand_se more_se cs_se local_se tspan_se gmm_se comb_se || idauthor: || idstudy: if forw==1 & odd==0
xtmixed t prec serv_se ma_se aggr_se avgyear_se op_se pols_se sectfe_se diff_se empl_se scomp_se cycl_se lnschcit_se native_se lnciteaut_se pubdate_se nloglin_se repimp_se rand_se more_se cs_se local_se tspan_se gmm_se comb_se || idauthor: if forw==1 & odd==0
******************************************************************************
******************************************************************************
*EXAMPLES OF SPILLOVERS
******************************************************************************
*MEXICO
******************************************************************************
xtmixed t prec lndist_se lngap_se open_se findev_se serv_se green_se `controls_se' || idstudy: if back==1 & odd==0
lincom prec + 7.392475092*lndist_se + 10.24356581*lngap_se + 0.6309406281*open_se + 0.2038370454*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 3.5*avgyear_se + 0.2227307*amad_se + 0.1868802*op_se + sectfe_se + diff_se + 0.1418764*empl_se + scomp_se + cycl_se + 4.525519*lnschcit_se + pub_se + native_se + 6.660575*lnciteaut_se + 7.844069*pubdate_se //MEXUSA
lincom prec + 9.155577909*lndist_se + 9.728055227*lngap_se + 0.6309406281*open_se + 0.2038370454*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 3.5*avgyear_se + 0.2227307*amad_se + 0.1868802*op_se + sectfe_se + diff_se + 0.1418764*empl_se + scomp_se + cycl_se + 4.525519*lnschcit_se + pub_se + native_se + 6.660575*lnciteaut_se + 7.844069*pubdate_se //MEXDEU
lincom prec + 9.364765586*lndist_se + 8.405177605*lngap_se + 0.6309406281*open_se + 0.2038370454*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 3.5*avgyear_se + 0.2227307*amad_se + 0.1868802*op_se + sectfe_se + diff_se + 0.1418764*empl_se + scomp_se + cycl_se + 4.525519*lnschcit_se + pub_se + native_se + 6.660575*lnciteaut_se + 7.844069*pubdate_se //MEXKOR
******************************************************************************
*CHINA
******************************************************************************
lincom prec + 9.314682369*lndist_se + 10.40020475*lngap_se + 0.379668961*open_se + 1.114757986*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 3.5*avgyear_se + 0.2227307*amad_se + 0.1868802*op_se + sectfe_se + diff_se + 0.1418764*empl_se + scomp_se + cycl_se + 4.525519*lnschcit_se + pub_se + native_se + 6.660575*lnciteaut_se + 7.844069*pubdate_se //CHNUSA
lincom prec + 8.987596741*lndist_se + 9.977995914*lngap_se + 0.379668961*open_se + 1.114757986*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 3.5*avgyear_se + 0.2227307*amad_se + 0.1868802*op_se + sectfe_se + diff_se + 0.1418764*empl_se + scomp_se + cycl_se + 4.525519*lnschcit_se + pub_se + native_se + 6.660575*lnciteaut_se + 7.844069*pubdate_se //CHNDEU
lincom prec + 6.907007199*lndist_se + 9.130794336*lngap_se + 0.379668961*open_se + 1.114757986*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 3.5*avgyear_se + 0.2227307*amad_se + 0.1868802*op_se + sectfe_se + diff_se + 0.1418764*empl_se + scomp_se + cycl_se + 4.525519*lnschcit_se + pub_se + native_se + 6.660575*lnciteaut_se + 7.844069*pubdate_se //CHNKOR
******************************************************************************
*ROMANIA
******************************************************************************
lincom prec + 9.074023504*lndist_se + 10.37761632*lngap_se + 0.608683929*open_se + 0.080681811*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 3.5*avgyear_se + 0.2227307*amad_se + 0.1868802*op_se + sectfe_se + diff_se + 0.1418764*empl_se + scomp_se + cycl_se + 4.525519*lnschcit_se + pub_se + native_se + 6.660575*lnciteaut_se + 7.844069*pubdate_se //ROMUSA
lincom prec + 7.170497164*lndist_se + 9.943333542*lngap_se + 0.608683929*open_se + 0.080681811*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 3.5*avgyear_se + 0.2227307*amad_se + 0.1868802*op_se + sectfe_se + diff_se + 0.1418764*empl_se + scomp_se + cycl_se + 4.525519*lnschcit_se + pub_se + native_se + 6.660575*lnciteaut_se + 7.844069*pubdate_se //ROMDEU
lincom prec + 8.988196071*lndist_se + 9.047971763*lngap_se + 0.608683929*open_se + 0.080681811*findev_se + 0.0457666*serv_se + 0.0686499*green_se + 3.5*avgyear_se + 0.2227307*amad_se + 0.1868802*op_se + sectfe_se + diff_se + 0.1418764*empl_se + scomp_se + cycl_se + 4.525519*lnschcit_se + pub_se + native_se + 6.660575*lnciteaut_se + 7.844069*pubdate_se //ROMKOR
******************************************************************************
******************************************************************************
window manage close graph
log close
exit, clear
******************************************************************************
******************************************************************************
******************************************************************************