******************************************************************************
******************************************************************************
* PUBLICATION SELECTION IN THE FDI SPILLOVER LITERATURE
* 18 Feb 2011, Stata 11.1
******************************************************************************
log using "results.log", replace
use "data.dta", clear
set more off
******************************************************************************
* Publication bias is present according to the test used by Görg and Strobl (2001).
******************************************************************************
gen lnabst=ln(abs(t))
gen lnsqrtn=ln(sqrt(exp(lnnobs)))
eststo: reg lnabst lnsqrtn if back==1, vce(robust)
test lnsqrtn=1
eststo: reg lnabst lnsqrtn if forw==1, vce(robust)
test lnsqrtn=1
eststo: reg lnabst lnsqrtn if horiz==1, vce(robust)
test lnsqrtn=1
esttab using gorgbias.tex, se booktabs replace compress title(Test of publication bias\label{tab:gorgbias}) mtitles("Backward" "Forward" "Horizontal") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps scalars(chi2_c) width(1\hsize)
eststo clear
sum e se prec if back==1
sum e se prec if forw==1
sum e se prec if horiz==1
mean e if back==1
mean e if back==1 & pub==1
mean e if forw==1
mean e if horiz==1
******************************************************************************
* Funnel plots suggest pub bias only for published studies on backward spillovers.
******************************************************************************
scatter prec e if back==1 & abs(e)<9 & prec<40, saving(funnel_back, replace) msize(*.7) msymbol(Oh) t1title("Backward", box bexpand)
scatter prec e if forw==1 & abs(e)<9.5 & prec<40, saving(funnel_forw, replace) msize(*.7) msymbol(Oh) t1title("Forward", box bexpand)
scatter prec e if horiz==1 & abs(e)<2.5 & prec<100, saving(funnel_horiz, replace) msize(*.7) msymbol(Oh) t1title("Horizontal", box bexpand) r1title("All studies", box bexpand)
scatter prec e if back==1 & abs(e)<9 & prec<40 & pub==1, saving(funnel_back_top, replace) msize(*.7) msymbol(Oh) 
scatter prec e if forw==1 & abs(e)<9.5 & prec<40 & pub==1, saving(funnel_forw_top, replace) msize(*.7) msymbol(Oh) 
scatter prec e if horiz==1 & abs(e)<2.5 & prec<100 & pub==1, saving(funnel_horiz_top, replace) msize(*.7) msymbol(Oh)  r1title("Published studies", box bexpand)
gr combine funnel_back.gph funnel_forw.gph funnel_horiz.gph funnel_back_top.gph funnel_forw_top.gph funnel_horiz_top.gph, saving(funnel, replace) imargin(0 0 0 0)
******************************************************************************
* Cofirmed by FAT-PET. Only backward significant, around 0.12.
******************************************************************************
xtset idstudy
eststo: xtreg t prec if back==1, fe vce(robust)
eststo: xtreg t prec if back==1 & pub==1, fe vce(robust)
eststo: mmregress tb precb if last==1
esttab using back.tex, se booktabs replace compress title(Test of publication bias and true effect, all studies\label{tab:bias}) mgroups("Backward", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("All" "Published" "Robust") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear
eststo: xtreg t prec if forw==1 & prec<1000, fe vce(robust)
eststo: xtreg t prec if forw==1 & pub==1 & prec<1000, fe vce(robust)
eststo: mmregress tf precf if last==1
esttab using forw.tex, se booktabs replace compress title(Test of publication bias and true effect, all studies\label{tab:bias}) mgroups("Forward", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("All" "Published" "Robust") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear
eststo: xtreg t prec if horiz==1, fe vce(robust)
eststo: xtreg t prec if horiz==1 & pub==1, fe vce(robust)
eststo: mmregress th prech if last==1
esttab using horiz.tex, se booktabs replace compress title(Test of publication bias and true effect, all studies\label{tab:bias}) mgroups("Horizontal", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("All" "Published" "Robust") addnote("Meta-response variable: t-statistic") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nonumber nogaps width(1\hsize)
eststo clear
******************************************************************************
* PEESE: coefficients only slightly higher.
******************************************************************************
xtreg t prec se if back==1, fe vce(robust)
xtreg t prec se if forw==1 & prec<1000, fe vce(robust)
mmregress tb precb seb if last==1, noconstant
mmregress tf precf sef if last==1, noconstant
******************************************************************************
xtreg t prec if back==1, fe vce(robust)
predict indiv_fe, u
gen bias =  indiv_fe + _b[_cons]
drop indiv_fe
******************************************************************************
* File data2 is used. What drives publication bias?
******************************************************************************
use "data2.dta", clear
label variable pub "Published"
label variable repimp "Journal impact"
label variable lnciteaut "Author citations"
label variable lnnobs "No.\ of observations"
label variable native "Native co-author"
label variable affusa "US-based"
label variable affacad "Academia"
label variable pubdate "Publication date"
label variable focus "Focus"
label variable phd0 "PhD not completed"
label variable phd1 "PhD 1--5 years"
label variable phd2 "PhD 6--10 years"
label variable pubdate2 "Publication date$^2$"
estpost summarize bias pub repimp lnciteaut lnnobs native affusa affacad pubdate focus phd0 phd1 phd2
esttab using summary.tex, booktabs replace compress width(1\hsize) title(Summary statistics of regression variables\label{tab:summary}) cells("mean sd min max") nonumber nomtitle nogaps
correl pub repimp lnciteaut lnnobs native affusa affacad pubdate focus phd0 phd1 phd2
collin pub repimp lnciteaut lnnobs native affusa affacad pubdate focus phd0 phd1 phd2
eststo: mmregress bias pub repimp lnciteaut lnnobs native affusa affacad pubdate focus
predict biasp if e(sample)
corr bias biasp if e(sample)
drop biasp
eststo: mmregress bias pub repimp lnciteaut lnnobs native affusa affacad pubdate focus phd0 phd1 phd2
predict biasp if e(sample)
corr bias biasp if e(sample)
drop biasp
test phd0 phd1 phd2
eststo: mmregress bias pub repimp lnciteaut lnnobs affusa pubdate focus
predict biasp if e(sample)
corr bias biasp if e(sample)
drop biasp
esttab using deter.tex, se booktabs replace compress title(Determinants of Publication Bias\label{tab:deter}) addnote("Meta-response variable: bias") star(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.01) label nogaps width(1\hsize)
eststo clear
mmregress bias pub repimp lnciteaut lnnobs affusa pubdate focus
lincom _cons + 1*pub + 0*repimp + 6.66*lnciteaut + 3.76*lnnobs + 1*affusa + 2.79*pubdate + 1*focus
lincom _cons + 0*pub + 2.7*repimp + 0*lnciteaut + 13.7*lnnobs + 0*affusa + 10.5*pubdate + 0*focus
******************************************************************************
window manage close graph
log close
exit, clear
******************************************************************************
******************************************************************************