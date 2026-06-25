******************************************************************************
******************************************************************************
*SELECTIVE REPORTING AND THE SOCIAL COST OF CARBON
******************************************************************************
******************************************************************************
*Stata 13.1
*August 1, 2014 
*Data and paper available at http://meta-analysis.cz/scc
log using scc.log, replace
use scc.dta, clear
set more off
******************************************************************************
*DEFINITION OF VARIABLES
******************************************************************************
gen lnscc = ln(scc + 13)
gen preclow = 1/stdlow
gen precup = 1/stdup
gen lnstdlow = ln(stdlow)
gen lnstdup = ln(stdup)
gen lnpreclow = 1/lnstdlow
gen lnprecup = 1/lnstdlow
gen invperstudy = 1/perstudy
replace pubyear = pubyear - 1982
gen lncits = ln(citations + 1)
gen stdreviewed = stdlow*reviewed
gen stdlncits = stdlow*lncits
gen stdsjr = stdlow*sjr
drop citations
drop dollaryear emissionyear tolweight iie cdr rra growth ies ///
climatesens hope nordhaus tol perstudy
label variable scc "SCC"
label variable stdlow "Standard error"
label variable stdup "Upper SE"
label variable reviewed "Reviewed"
label variable pubyear "Publication year"
label variable sccmean "Mean estimate"
label variable sccmed "Median estimate"
label variable mmi "Marginal costs"
label variable dim "Dynamic impacts"
label variable sce "Scenarios"
label variable fund "FUND"
label variable dicerice "DICE or RICE"
label variable page "PAGE"
label variable prtp "PRTP"
label variable eweight "Equity weights"
label variable pigou "Pigouvian tax"
label variable lncits "Citations"
label variable sjr "Journal rank"
******************************************************************************
*SUMMARY STATISTICS AND PLOTS
******************************************************************************
sort dataset
by dataset: sum scc, detail
by dataset: sum scc [aweight=lncits], detail
by dataset: sum scc stdlow stdup reviewed pubyear sccmean ///  
sccmed mmi dim sce fund dicerice page prtp eweight pigou lncits sjr
kdensity lnscc if dataset==0
kdensity lnscc if dataset==1
kdensity lnscc if dataset==2
sktest lnscc if dataset==0
scatter preclow scc if dataset==1 & scc<180 & preclow<0.5
scatter preclow scc if dataset==2 & scc<500 & preclow <0.5
graph hbox lnscc if dataset==0, over(label) xsize(6.3) ysize(8) scale(0.4) ///
saving(box, replace)
******************************************************************************
*HETEROGENEITY
******************************************************************************
eststo: reg scc reviewed pubyear sccmean sccmed mmi dim sce fund dicerice ///
page eweight pigou lncits sjr if dataset==0, cluster(idstudy)
eststo: reg scc reviewed pubyear sccmean sccmed mmi dim sce fund dicerice ///
page eweight prtp pigou lncits sjr if dataset==0, cluster(idstudy)
eststo: reg lnscc reviewed pubyear sccmean sccmed mmi dim sce fund dicerice ///
page eweight pigou lncits sjr if dataset==0, cluster(idstudy)
eststo: reg lnscc reviewed pubyear sccmean sccmed mmi dim sce fund dicerice ///
page eweight prtp pigou lncits sjr if dataset==0, cluster(idstudy)
esttab using 0.tex, se booktabs replace compress title(Explaining the /// 
heterogeneity in the SCC estimates\label{tab:0}) mgroups("SCC" "log SCC", /// 
pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span /// 
erepeat(\cmidrule(lr){@span})) mtitles("All estimates" "PRTP"  /// 
"All estimates" "PRTP") addnote("Meta-response variable: t-statistic") ///
star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps ///
width(1\hsize)
eststo clear
******************************************************************************
*FUNNEL ASYMMETRY TESTS
******************************************************************************
eststo: reg scc stdlow if dataset==1, cluster(idstudy)
xtset idstudy
eststo: xtreg scc stdlow if dataset==1, fe cluster(idstudy)
eststo: reg scc stdlow [pweight=preclow] if dataset==1, cluster(idstudy)
eststo: reg scc stdlow [pweight=invperstudy] if dataset==1, cluster(idstudy)
eststo: xtmixed scc stdlow || idstudy: if dataset==1
esttab using 1a.tex, se booktabs replace compress title(Funnel asymmetry /// 
test estimates\label{tab:1}) mtitles("OLS" "FE" "Precision" "Study" "ME") /// 
addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} ///
0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear
******************************************************************************
eststo: reg scc stdlow stdup if dataset==1, cluster(idstudy)
eststo: xtreg scc stdlow stdup if dataset==1, fe cluster(idstudy)
eststo: reg scc stdlow stdup [pweight=preclow] if dataset==1, cluster(idstudy)
eststo: reg scc stdlow stdup [pweight=invperstudy] if dataset==1, ///
cluster(idstudy)
eststo: xtmixed scc stdlow stdup || idstudy: if dataset==1
esttab using 1b.tex, se booktabs replace compress title(Funnel asymmetry /// 
test estimates\label{tab:1}) mtitles("OLS" "FE" "Precision" "Study" "ME") /// 
addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} ///
0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear
******************************************************************************
*STUDY-LEVEL MEANS
******************************************************************************
eststo: reg scc stdlow if dataset==2, vce(robust)
eststo: reg scc stdlow [pweight=preclow] if dataset==2, vce(robust)
eststo: reg scc stdlow stdup if dataset==2, vce(robust)
eststo: reg scc stdlow stdup [pweight=preclow] if dataset==2, vce(robust)
esttab using 2.tex, se booktabs replace compress title(Funnel asymmetry /// 
tests, median estimates reported in studies\label{tab:2}) ///
mtitles("OLS" "Precision" "OLS" "Precision") /// 
addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} ///
0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear
******************************************************************************
*INTRODUCING CONTROLS
******************************************************************************
eststo: reg scc stdlow reviewed pubyear sccmean sccmed mmi dim sce fund ///
dicerice page eweight pigou lncits sjr if dataset==1, cluster(idstudy)
eststo: reg scc stdlow reviewed pubyear sccmean sccmed mmi dim sce fund /// 
dicerice page eweight prtp pigou lncits sjr if dataset==1, cluster(idstudy)
eststo: reg scc stdlow reviewed pubyear sccmean sccmed mmi dim sce fund ///
dicerice page eweight pigou lncits sjr if dataset==1 [pweight=preclow], /// 
cluster(idstudy)
eststo: reg scc stdlow reviewed pubyear sccmean sccmed mmi dim sce fund ///
dicerice page eweight pigou lncits sjr if dataset==1 ///
[pweight=invperstudy], cluster(idstudy)
eststo: xtmixed scc stdlow reviewed pubyear sccmean sccmed mmi dim sce fund ///
dicerice page eweight pigou lncits sjr || idstudy: if dataset==1
esttab using 12.tex, se booktabs replace compress title(Introducing ///
controls for heterogeneity\label{tab:2}) ///
mtitles("OLS" "PRTP" "Precision" "Study" "ME") ///
addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} ///
0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear
******************************************************************************
eststo: reg scc stdlow reviewed pubyear sccmean sccmed mmi dim sce fund ///
dicerice page eweight pigou lncits sjr if dataset==2, vce(robust)
eststo: reg scc stdlow reviewed pubyear sccmean sccmed mmi dim sce fund ///
dicerice page eweight pigou lncits sjr [pweight=preclow] if dataset==2, ///
vce(robust)
eststo: reg scc stdlow reviewed pubyear sccmean sccmed mmi dim sce fund ///
dicerice page eweight prtp pigou lncits sjr if dataset==2, vce(robust)
eststo: reg scc stdlow reviewed pubyear sccmean sccmed mmi dim sce fund ///
dicerice page eweight prtp pigou lncits sjr [pweight=preclow] ///
 if dataset==2, vce(robust)
esttab using 21.tex, se booktabs replace compress title(Heterogeneity /// 
\label{tab:21}) mgroups("All estimates" "PRTP", /// 
pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span /// 
erepeat(\cmidrule(lr){@span})) mtitles("OLS" "Precision" "OLS"  /// 
"Precision") addnote("Meta-response variable: t-statistic") ///
star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps ///
width(1\hsize)
eststo clear
******************************************************************************
*WHAT DRIVES SELECTIVE REPORTING
******************************************************************************
eststo: reg scc stdlow stdreviewed stdlncits stdsjr if dataset==1 ///
, cluster(idstudy)
eststo: reg scc stdlow stdreviewed stdlncits stdsjr [pweight=preclow] ///
if dataset==1, cluster(idstudy)
eststo: xtmixed scc stdlow stdreviewed stdlncits stdsjr || idstudy: ///
if dataset==1
eststo: reg scc stdlow stdreviewed stdlncits stdsjr if dataset==2 ///
, vce(robust)
eststo: reg scc stdlow stdreviewed stdlncits stdsjr [pweight=preclow] /// 
if dataset==2, vce(robust)
esttab using 22.tex, se booktabs replace compress title(Mediating factors /// 
of selective reporting\label{tab:22}) mgroups("All estimates with  ///
uncertainty" "median estimates", /// 
pattern(1 0 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span /// 
erepeat(\cmidrule(lr){@span})) mtitles("OLS" "Precision" "ME"  /// 
"OLS" "Precision") addnote("Meta-response variable: t-statistic") ///
star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps ///
width(1\hsize)
eststo clear
******************************************************************************
window manage close graph
log close
exit, clear
******************************************************************************
******************************************************************************
