
/******************************************************************************************
   Applied Meta-Analysis in Economics: Stata Course Script
   -------------------------------------------------------------
   Example: "Beauty and Professional Success" 
            (Bortnikova, Havranek, Bartos, Irsova, Luskova)

   Version:        2.1 (Course Edition)
   Author:         Tomas Havranek
   Institution:    Charles University | CEPR | METRICS @ Stanford
   Date:           March 6, 2026
   License:        MIT License (https://opensource.org/licenses/MIT)

   ----------------------------------------------------------------------------------------
   Purpose:
   This Stata script demonstrates practical tools for applied meta-analysis using data from
   the paper "Beauty and Professional Success: A Meta-Analysis", currently under revision
   for *Nature Human Behaviour*.

   It is designed for instructional use in the University of Osaka meta-analysis workshop
   and includes step-by-step annotations, modular structure, and code best practices.
   
   ----------------------------------------------------------------------------------------
   Requirements (install beforehand):

   Software:
       - Stata 15 or later

   Data:
       - beauty.xlsx placed in the working directory

   Required Stata packages:
       (must be installed manually before the course begins)

       * ssc install winsor2       // For winsorizing variables
       * ssc install metan         // For forest plots and random/fixed effects models
       * ssc install ivreg2        // For instrumental variable regressions and diagnostics
       * ssc install weakiv        // For weak instrument diagnostics
       * ssc install collin        // For multicollinearity checks
       * net install boottest, ///
            from("https://raw.githubusercontent.com/droodman/boottest/main/")

   ----------------------------------------------------------------------------------------
   How to Use:
   Run this script section by section to explore key steps of meta-analysis:
       • Data preparation
       • Effect size analysis
       • Publication bias correction
       • Heterogeneity analysis

   Switch between slides and code as indicated during the workshop.

   ----------------------------------------------------------------------------------------
   Reproducibility:
   This script reproduces and updates selected Stata-based results from the paper. Matching 
   R code is available for Bayesian model averaging but is not required to run this file.

******************************************************************************************/

/******************************************************************************************
   SECTION 1: Load Dataset
   ----------------------------------------------------------------------------------------
   This section opens a log file and imports the meta-analysis dataset from Excel.
   Ensure "beauty.xlsx" is placed in your working directory before running this block.
******************************************************************************************/

* Force Stata to use version 15 behavior for compatibility and reproducibility
version 15

* Open log file to capture output
log using beauty.log, replace

* Import data from Excel (sheet "data")
import excel "beauty.xlsx", sheet("data") firstrow clear

* Update variable labels for clarity
label variable premium              "Estimated beauty effect (% premium)"
label variable se_premium          "Standard error of premium"
label variable nobs                "Sample size used for the original estimate"
label variable study               "Study name (authors and year)"
label variable beauty_penalty      "1 = penalty estimate, 0 = premium"
label variable published_study     "1 = published, 0 = unpublished"
label variable interrater_pairwise "Agreement among raters"
label variable high_quality        "Top 5 journal"
label variable impact_factor       "Impact factor of journal"
label variable citations           "Log number of citations"
label variable datyear             "Mean year of data used"

* Disable pagination in output
set more off

* Display the structure of the dataset
describe

* Check the first 10 observations
list study_id study premium se_premium nobs if _n <= 10

/******************************************************************************************
   SECTION 2: Compute Derived Variables
   ----------------------------------------------------------------------------------------
   This section creates variables that are functions of others: precision, t-stat, weight,
   and instruments for MAIVE. These are excluded from the raw Excel file for transparency.
******************************************************************************************/

* Compute precision and t-statistic
gen precision_premium = 1 / se_premium
gen tstat_premium     = premium / se_premium

* Compute number of estimates per study
bysort study_id: gen estimates_per_study = _N

* Compute inverse-frequency weight
gen weight = 1 / estimates_per_study

* Compute instruments for MAIVE (used later in the analysis)
gen instrument  = 1 / sqrt(nobs)
gen instrument2 = 1 / nobs

/******************************************************************************************
   SECTION 3: Outlier Handling with Winsorization
   ----------------------------------------------------------------------------------------
   This section reduces the influence of extreme effect size estimates by applying 
   1%–99% winsorization. We apply it to the effect size (premium) and standard error,
   and then visually and numerically compare the original and adjusted variables.

   Winsorization replaces the top and bottom 1% of values with the nearest remaining
   non-extreme values. It retains all observations but reduces the weight of outliers.
******************************************************************************************/

* Visual inspection: distribution of raw effect sizes
histogram premium, bin(40) color(gs14) ///
    title("Raw Distribution of Beauty Effects") ///
    xtitle("Beauty Premium (%)") ytitle("Frequency")

* Show top and bottom 5 raw premium values
sort premium
list study_id study premium se_premium if _n <= 5
list study_id study premium se_premium if _n >= _N - 4

* Apply 1%–99% winsorization to effect size, SE, and instrument
winsor2 premium,     suffix(_w) cuts(1 99)
winsor2 se_premium,  suffix(_w) cuts(1 99)
winsor2 instrument,  suffix(_w) cuts(1 99)
winsor2 instrument2, suffix(_w) cuts(1 99)

* Recompute precision using winsorized SE
gen precision_premium_w = 1 / se_premium_w

* Visual inspection: winsorized effect size
histogram premium_w, bin(40) color(emerald) ///
    title("Winsorized Distribution (1%–99%)") ///
    xtitle("Beauty Premium (%)") ytitle("Frequency")

* Numeric comparison: before and after winsorization
sum premium premium_w, detail

* Scatter plot: original vs. winsorized effect sizes
twoway (scatter premium_w premium, mcolor(navy) msymbol(circle)), ///
    yline(0, lcolor(gs12)) xline(0, lcolor(gs12)) ///
    title("Winsorized vs. Raw Beauty Effects") ///
    xtitle("Original Premium") ytitle("Winsorized Premium")

/******************************************************************************************
   SECTION 4: Conventional Tools for Meta-Analysis
   ----------------------------------------------------------------------------------------
   This section introduces conventional methods for summarizing and analyzing effect sizes,
   including fixed and random effects models, visual summaries, and distribution diagnostics.
******************************************************************************************/

* Descriptive statistics
mean premium_w
centile premium_w, centile(50)

* Install metan if not already installed
cap which metan
if _rc {
    di "Installing user-written command: metan"
    ssc install metan, replace
}

* Run fixed-effects meta-analysis
metan premium_w se_premium_w, fixed

* Temporarily collapse to one estimate per study
preserve
collapse (median) premium_w se_premium_w, by(study_id study)

* Run fixed-effects meta-analysis on collapsed data
metan premium_w se_premium_w, fixed ///
    label(namevar=study) ///
    effect(Mean) ///
    forestplot(xlabel(-20(10)40) ///
               title("Fixed-Effects Meta-Analysis of Beauty Effect"))

* Restore original multi-estimate dataset
restore

* Unrestricted Weighted Least Squares (UWLS)
* Same point estimate as fixed effects, but different SE formula
reg premium_w [aweight=1/(se_premium_w^2)]

* Clustered UWLS: adjusts standard errors for multiple estimates per study
reg premium_w [aweight=1/(se_premium_w^2)], cluster(study_id)

* Clustered UWLS with adjusted weights: inverse-variance × inverse-frequency
gen cluster_weight = (1 / (se_premium_w^2)) * (1 / estimates_per_study)
reg premium_w [aweight=cluster_weight], cluster(study_id)

* Random-effects meta-analysis (collapsed to one estimate per study)
preserve
collapse (median) premium_w se_premium_w, by(study_id study)

metan premium_w se_premium_w, random ///
    label(namevar=study) ///
    effect(Mean) ///
    forestplot(xlabel(-20(10)40) ///
               title("Random-Effects Meta-Analysis of Beauty Effect"))

restore

* Box plot by study
graph hbox premium_w, ///
    over(study, label(angle(45) labsize(small) grid) sort(datyear)) ///
    box(1, lcolor(black) fcolor(none)) ///
    marker(1, msymbol(circle_hollow) mcolor(gs12)) ///
    medline(lcolor(gs9)) ///
    yline(0, lcolor(gs12) lpattern(shortdash)) ///
    yline(4.3, lcolor(red)) ///
    ylabel(, glcolor(ltbluishgray)) ///
    ytitle("Estimate of the beauty effect (winsorized)") ///
    title("Box Plot of Winsorized Beauty Effects by Study", size(medsmall)) ///
    graphregion(color(ltbluishgray)) ///
    xsize(3) ysize(5) scale(0.7) 

* Box plot by country
graph hbox premium_w, ///
    over(country, label(angle(45) labsize(small) grid)) ///
    box(1, lcolor(black) fcolor(none)) ///
    marker(1, msymbol(circle_hollow) mcolor(gs12)) ///
    medline(lcolor(gs9)) ///
    yline(0, lcolor(gs12) lpattern(shortdash)) ///
    yline(4.3, lcolor(red)) ///
    ylabel(, glcolor(ltbluishgray)) ///
    ytitle("Estimate of the beauty effect (winsorized)") ///
    title("Box Plot of Winsorized Beauty Effects by Country", size(medsmall)) ///
    graphregion(color(ltbluishgray)) ///
    xsize(6) ysize(4) scale(0.8) 

* Density by rating method
twoway ///
(kdensity premium if interviewer_rated_beauty==1 & premium > -20 & premium < 40, ///
    legend(label(1 "Interviewer-rated beauty")) lcolor(cranberry) ///
    xline(0, lcolor(gs12) lpattern(shortdash)) ///
    xline(4.3, lcolor(red) lpattern(dott))) ///
(kdensity premium if photo_rated_beauty==1 & premium > -20 & premium < 40, ///
    legend(label(2 "Photo-rated beauty")) lcolor(black) lpattern(longdash)) ///
(kdensity premium if software_rated_beauty==1 & premium > -20 & premium < 40, ///
    legend(label(3 "Software-rated beauty")) lcolor(gs10)) ///
(kdensity premium if self_rated_beauty==1 & premium > -20 & premium < 40, ///
    legend(label(4 "Self-rated beauty")) lcolor(gs5) lpattern(shortdash)), ///
xlabel(-20 0 4.3 20 40, glcolor(ltbluishgray)) ///
legend(ring(0) position(2) bmargin(medium) rows(4) region(lstyle(none))) ///
xtitle("Estimate of the beauty effect") ///
ytitle("Kernel density (beauty effect)") 

* Density by outcome type
twoway ///
(kdensity premium if salary==1 & premium > -20 & premium < 40, ///
    legend(label(1 "Salary")) lcolor(navy) ///
    xline(0, lcolor(gs12) lpattern(shortdash)) ///
    xline(4.3, lcolor(red) lpattern(dott))) ///
(kdensity premium if study_outcomes==1 & premium > -20 & premium < 40, ///
    legend(label(2 "Study outcomes")) lcolor(black) lpattern(shortdash)) ///
(kdensity premium if teaching_research_outcomes==1 & premium > -20 & premium < 40, ///
    legend(label(3 "Teaching/research")) lcolor(gs10)) ///
(kdensity premium if athletic_success==1 & premium > -20 & premium < 40, ///
    legend(label(4 "Athletic success")) lcolor(gs5) lpattern(dott)) ///
(kdensity premium if electoral_success==1 & premium > -20 & premium < 40, ///
    legend(label(5 "Electoral success")) lcolor(cranberry) lpattern(solid)) ///
(kdensity premium if other_outcomes==1 & premium > -20 & premium < 40, ///
    legend(label(6 "Other outcomes")) lcolor(gs12) lpattern(dash)), ///
xlabel(-20 0 4.3 20 40, glcolor(ltbluishgray)) ///
legend(ring(0) position(2) bmargin(medium) rows(6) region(lstyle(none))) ///
xtitle("Estimate of the beauty effect") ///
ytitle("Kernel density (beauty effect)") 

* Density by method
twoway ///
(kdensity premium if ols_method==1 & premium > -20 & premium < 40, ///
    legend(label(1 "OLS method")) lcolor(navy) ///
    xline(0, lcolor(gs12) lpattern(shortdash)) ///
    xline(4.3, lcolor(red) lpattern(dott))) ///
(kdensity premium if iv_method==1 & premium > -20 & premium < 40, ///
    legend(label(2 "IV method")) lcolor(black) lpattern(shortdash)) ///
(kdensity premium if quasi_experimental_method==1 & premium > -20 & premium < 40, ///
    legend(label(3 "Quasi-experimental method")) lcolor(gs10)) ///
(kdensity premium if other_method==1 & premium > -20 & premium < 40, ///
    legend(label(4 "Other method")) lcolor(gs5) lpattern(dott)), ///
xlabel(-20 0 4.3 20 40, glcolor(ltbluishgray)) ///
legend(ring(0) position(2) bmargin(medium) rows(4) region(lstyle(none))) ///
xtitle("Estimate of the beauty effect") ///
ytitle("Kernel density (beauty effect)") 

* Density by occupation type
twoway ///
(kdensity premium if prostitutes==1 & premium > -20 & premium < 40, ///
    legend(label(1 "Prostitutes")) lcolor(cranberry) ///
    xline(0, lcolor(gs12) lpattern(shortdash)) ///
    xline(4.3, lcolor(red) lpattern(dott))) ///
(kdensity premium if other_dressy_occupations==1 & premium > -20 & premium < 40, ///
    legend(label(2 "Other dressy occupations")) lcolor(black) lpattern(shortdash)) ///
(kdensity premium if non_dressy_occupation==1 & premium > -20 & premium < 40, ///
    legend(label(3 "Non-dressy occupations")) lcolor(gs10)), ///
xlabel(-20 0 4.3 20 40, glcolor(ltbluishgray)) ///
legend(ring(0) position(2) bmargin(medium) rows(3) region(lstyle(none))) ///
xtitle("Estimate of the beauty effect") ///
ytitle("Kernel density (beauty effect)") 

/******************************************************************************************
   SECTION 5: Publication Bias and Correction Methods
   ----------------------------------------------------------------------------------------
   This section investigates potential publication bias in the meta-analysis dataset.

   Publication bias arises when studies with statistically insignificant or undesirable
   results are less likely to be published, skewing the overall evidence. We begin by 
   visualizing the distribution of effect sizes and study precision using a funnel plot.

   In subsequent blocks, we will introduce several econometric tools that attempt to 
   detect and correct for publication bias—some based on precision-effect regressions, 
   others on power thresholds, selection models, or instrumented approaches.
******************************************************************************************/
gen se_premium_w2 = se_premium_w*se_premium_w

* Funnel plot:  beauty effect vs. precision
twoway scatter precision_premium premium if precision_premium < 10 & premium > -20 & premium < 40, ///
    xlab(-20 0 4.3 20 40, nogrid labcolor(black)) ///
    xline(0, lcolor(gs12) lpattern(shortdash)) ///
    xline(4.3, lpattern(dott) lcolor(red)) ///
    xtitle("Estimate of the beauty premium") ///
    ylabel(, glcolor(ltbluishgray)) ///
    ytitle("Precision of the estimate (1/SE)") ///
    msymbol(smcircle_hollow) ///
    graphregion(color(ltbluishgray))

	* Install boottest if needed
cap which boottest
if _rc {
    di "Installing user-written command: boottest"
    net install boottest, from("https://raw.githubusercontent.com/droodman/boottest/main/")
}

* Run nonweighted FAT-PET regression with clustered standard errors
ivreg2 premium_w se_premium_w, cluster(study_id)

* Bootstrap important for most meta-analyses
* FAT: Test for funnel asymmetry (significance of SE coefficient)
boottest se_premium_w, nograph

* PET: Test whether effect remains when SE → 0 (constant term)
boottest _cons, nograph
	
* Run FAT-PET regression with study fixed effects and clustered SEs	
xtset study_id
xtreg premium_w se_premium_w, fe vce(cluster study_id)
	
* Between effects
xtreg premium_w se_premium_w, be

* Run FAT-PET with equal weight for each study
ivreg2 premium_w se_premium_w [aweight=(1 / estimates_per_study)], cluster(study_id)

* Run FAT-PET with inverse variance weight
ivreg2 premium_w se_premium_w [aweight=1/(se_premium_w^2)], cluster(study_id)
	
* Run PET-PEESE (simplest nonlinear model)
ivreg2 premium_w se_premium_w2 [aweight=1/(se_premium_w^2)], cluster(study_id)

/******************************************************************************************
   WAAP (Ioannidis et al., 2017)
   ----------------------------------------------------------------------------------------
   This approach focuses on studies with adequate statistical power to reduce publication bias.

   Procedure:
     1. Compute the WAAP cutoff: abs(mean effect) / 2.8
     2. Include only estimates with SE < cutoff (i.e., ≥80% power)
     3. Estimate the effect via regression of t-stat on precision, no constant

   Notes:
     • Equivalent to inverse-variance weighted regression on high-power subset.
     • r(mean) is pulled from weighted mean using inverse-variance weights.
******************************************************************************************/

* Step 1: Compute weighted mean of premium_w using inverse-variance weights
summarize premium_w [aweight=1/(se_premium_w^2)]

* Step 2: Compute WAAP power cutoff
gen waapbound_premium = abs(r(mean)) / 2.8

* Step 3: Run no-constant regression of t-stat on precision (subset with SE < cutoff)
reg tstat_premium precision_premium_w if se_premium_w < waapbound_premium, noconstant cluster(study_id)

*----------------------------------------------------------------------
*  Endogenous–Kink meta-estimator (Bom & Rachinger, 2020, RSM)
*  Assumes variables:
*       premium_w       – point estimates
*       se_premium_w    – standard errors
*
*  Nothing permanent is written to the data – all work inside PRESERVE.
*----------------------------------------------------------------------

preserve          // keep original data untouched
***********************************************************************
* --------- 0. OPTIONAL RESTRICTIONS  -------------------------------
* uncomment *one* of these if you want to run EK on a subsample
*---------------------------------------------------------------------
 // drop if prostitutes      == 1        // keep only non-prostitute jobs
 // drop if beauty_penalty   == 1        // keep only “premium” estimates
***********************************************************************

* --------- 1. PREPARE ------------------------------------------------
quietly {
    rename  premium_w        bs
    rename  se_premium_w     sebs

    gen     ones  = 1
    gen     sebs2 = sebs^2
    gen     wis   = 1/sebs2          // sampling weights 1/SE²
    gen     bs_sebs     =  bs / sebs
    gen     invse       = 1 / sebs

    * basic sample info
    summ sebs
    local se_min = r(min)
    local se_max = r(max)
    summ wis
    local Wsum   = r(sum)
    count
    local N      = r(N)
}

* --------- 2. PET and PEESE -----------------------------------------
quietly regress bs_sebs invse, noc      // PET
local b_PET  = _b[invse]
local t_PET  = _b[invse] / _se[invse]
local RSS_PET = e(rss)

quietly regress bs_sebs invse sebs, noc // PEESE
local b_PEESE = _b[invse]
local RSS_PEE = e(rss)

* choose PET or PEESE as in Bom-Rachinger
if abs(`t_PET') > invt(`=`N'-2', .975) {     // significant PET
    local b_star = `b_PEESE'
    local RSS    = `RSS_PEE'
}
else {
    local b_star = `b_PET'
    local RSS    = `RSS_PET'
}

* --------- 3. BETWEEN-STUDY VARIANCE (DerSimonian-Laird) ------------
local sig2_u = max(0, `N' * ((`RSS'/(`N'-1-1)) - 1) / `Wsum')
local sig_u  = sqrt(`sig2_u')

* --------- 4. KINK POINT a₁ -----------------------------------------
if `b_star' > 1.96*`sig_u' {
    local a1 = ( (`b_star' - 1.96*`sig_u') *           /*
    */               (`b_star' + 1.96*`sig_u') ) /      /*
    */               ( 2 * 1.96 * `b_star' )
}
else    local a1 = 0

* --------- 5. SECOND-STAGE REGRESSION -------------------------------
rename bs           bs_orig      // stash original
rename bs_sebs      bs           // dependent var for EK
tempvar pubbias
gen     `pubbias' = .            // will be filled below

local CASE ""

if (`a1' > `se_min') & (`a1' < `se_max') {
    local CASE  "EK kink inside support: a1 = `=round(`a1', .0001)'"
    replace `pubbias' = cond(sebs>`a1', (sebs-`a1')/sebs, 0)
    regress bs  invse `pubbias', noc
    local delta  = _b[`pubbias']
    local se_d   = _se[`pubbias']
}
else if (`a1' <= `se_min') {
    local CASE  "EK collapses to FAT–PET (a1 below min(SE))"
    replace `pubbias' = 1
    regress bs  invse `pubbias', noc
    local delta  = _b[`pubbias']
    local se_d   = _se[`pubbias']
}
else {   // a1 ≥ se_max  ⇒ WLS on constant
    local CASE  "EK collapses to WLS constant (a1 > max(SE))"
    regress bs [aw=wis], noc
    local delta  = .
    local se_d   = .
}

* alpha1 estimate always in constant
local alpha1 = _b[invse]
local se_a1  = _se[invse]

* --------- 6. DISPLAY RESULTS ---------------------------------------
di as txt "------------------------------------------------------------"
di as txt "`CASE'"
di as res " Mean effect  (alpha1) = " %9.4f `alpha1'  ///
          "   SE = " %9.4f `se_a1'
if "`delta'" != "." {
    di as res " Pub-bias slope (delta) = " %9.4f `delta'  ///
              "   SE = " %9.4f `se_d'
}
di as txt "------------------------------------------------------------"

restore           // bring back original var names & data
*----------------------------------------------------------------------
	
/******************************************************************************************
   Subsample Analysis: Publication Bias Among Prostitutes
   ----------------------------------------------------------------------------------------
   This block replicates key publication bias diagnostics (FAT-PET regressions and variants)
   for the subset of estimates related to prostitution, where appearance is most salient.
******************************************************************************************/

* Restrict to subsample of prostitutes
preserve
keep if prostitutes == 1

* Re-run basic FAT-PET (unweighted, clustered)
ivreg2 premium_w se_premium_w, cluster(study_id)

* Bootstrap tests for significance
boottest se_premium_w, nograph      // FAT: bias test
boottest _cons, nograph             // PET: effect test

* Run FAT-PET with study fixed effects and clustered SEs
xtset study_id
xtreg premium_w se_premium_w, fe vce(cluster study_id)

* Run between-effects model
xtreg premium_w se_premium_w, be

restore
	
/******************************************************************************************
   Caliper Test
   ----------------------------------------------------------------------------------------
   This part evaluates potential p-hacking or selective reporting by checking for excess
   significance just above key t-statistic thresholds (0, 1.96, 2.58). A disproportionate
   share of results just above the threshold may indicate publication bias.
******************************************************************************************/

* Visual inspection: distribution of t-statistics with key cutoffs
twoway ///
    (histogram tstat_premium if tstat_premium > -5 & tstat_premium < 10, ///
        bin(90) fcolor(gs14) lstyle(thin)) ///
    (kdensity tstat_premium if tstat_premium > -5 & tstat_premium < 10, ///
        lcolor(navy)), ///
    xtitle("t-statistics of the estimate of the beauty effect") ///
    ytitle("Density") ///
    xline(0, lcolor(gs12) lpattern(shortdash)) ///
    xline(1.96 2.58, lcolor(red)) ///
    xlabel(-5 0 1.96 2.58 5 10) ///
    ylabel(, glcolor(ltbluishgray)) ///
    legend(off) ///
    graphregion(color(ltbluishgray))

******************************************************************************************
* CALIPER TEST AROUND ZERO
******************************************************************************************

gen significant = (tstat_premium > 0)

foreach c in 0.05 0.10 0.15 {
    local lower = -`c'
    local upper = `c'
    di as txt "Testing asymmetry in window [`lower', `upper'] around zero"
    reg significant if tstat_premium > `lower' & tstat_premium < `upper'
    lincom _cons - 0.5
    di "--------------------------------------------------"
}

******************************************************************************************
* CALIPER TEST AROUND 1.96 (5% significance threshold)
******************************************************************************************

replace significant = (tstat_premium > 1.96)

foreach c in 0.05 0.10 0.15 {
    local lower = 1.96 - `c'
    local upper = 1.96 + `c'
    di as txt "Testing asymmetry in window [`lower', `upper'] around 1.96"
    reg significant if tstat_premium > `lower' & tstat_premium < `upper'
    lincom _cons - 0.5
    di "--------------------------------------------------"
}

******************************************************************************************
* CALIPER TEST AROUND 2.58 (1% significance threshold)
******************************************************************************************

replace significant = (tstat_premium > 2.58)

foreach c in 0.05 0.10 0.15 {
    local lower = 2.58 - `c'
    local upper = 2.58 + `c'
    di as txt "Testing asymmetry in window [`lower', `upper'] around 2.58"
    reg significant if tstat_premium > `lower' & tstat_premium < `upper'
    lincom _cons - 0.5
    di "--------------------------------------------------"
}
	
/******************************************************************************************
   SECTION 6: P-Hacking – MAIVE Estimator and Weak Instrument Diagnostics
   ----------------------------------------------------------------------------------------
   This section introduces the MAIVE method (Instrumental Variable approach to address
   p-hacking) and evaluates instrument strength using the Anderson–Rubin (AR) confidence
   interval, which is robust to weak instruments.

   Key idea:
     - Under p-hacking, standard errors become endogenous (correlated with the residual).
     - MAIVE instruments the standard error with a variable assumed to be exogenous 
       (e.g., inverse square root of sample size).

   Interpretation:
     - The coefficient on the SE in the MAIVE regression identifies publication bias.
     - AR confidence intervals are recommended due to weak instruments.
******************************************************************************************/

* Step 1: Run MAIVE using ivreg2 (full diagnostics)
ivreg2 premium_w (se_premium_w = instrument_w), cluster(study_id) first

* Step 2: Install weakiv (if not already installed) to compute AR intervals
cap which weakiv
if _rc {
    di "Installing user-written command: weakiv"
    ssc install weakiv
}

* Step 3: Re-run MAIVE using ivregress (needed for weakiv to work)
ivregress 2sls premium_w (se_premium_w = instrument_w), vce(cluster study_id)

* Step 4: Compute Anderson–Rubin confidence interval
weakiv, ar

******************************************************************************************
* Note:
* The AR confidence interval reported above is robust to weak instruments and should be
* preferred when the first-stage F-statistic from Step 1 is small (e.g., below 10).
******************************************************************************************
	
/******************************************************************************************
   SECTION 7: Heterogeneity
   ----------------------------------------------------------------------------------------
   This section explores systematic differences in the reported beauty premia based on context,
   methodology, and sample characteristics. It is divided into three parts:
     (1) summary tables for key moderators,
     (2) subsample analyses of publication bias, and
     (3) multiple meta-regression.
******************************************************************************************/

/******************************************************************************************
   Part 7.1: Summary Tables by Contextual and Methodological Moderators
   ----------------------------------------------------------------------------------------
   We display means, medians, and observation counts for various subsamples based on:
   - Rating method
   - Outcome type
   - Estimation method (incl. cognitive skill control)
   - Occupation type
******************************************************************************************/

* Rating method
preserve
gen rating_method = .
replace rating_method = 1 if interviewer_rated_beauty == 1
replace rating_method = 2 if photo_rated_beauty == 1
replace rating_method = 3 if software_rated_beauty == 1
replace rating_method = 4 if self_rated_beauty == 1
label define rating_lbl 1 "Interviewer" 2 "Photo" 3 "Software" 4 "Self"
label values rating_method rating_lbl
forvalues i = 1/4 {
    quietly {
        su premium_w if rating_method == `i', meanonly
        local m = r(mean)
        count if rating_method == `i'
        local n = r(N)
        centile premium_w if rating_method == `i', centile(50)
        local med = r(c_1)
        local lbl : label rating_lbl `i'
    }
    di as res ///
    %15s "`lbl'" " |" ///
    %9.2f `m' " |" ///
    %8.2f `med' " |" ///
    %5.0f `n'
}
restore

* Outcome type
preserve
gen outcome_type = .
replace outcome_type = 1 if salary == 1
replace outcome_type = 2 if study_outcomes == 1
replace outcome_type = 3 if teaching_research_outcomes == 1
replace outcome_type = 4 if athletic_success == 1
replace outcome_type = 5 if electoral_success == 1
replace outcome_type = 6 if other_outcomes == 1
label define outcome_lbl 1 "Salary" 2 "Study" 3 "Teaching/Res." 4 "Athletics" 5 "Elections" 6 "Other"
label values outcome_type outcome_lbl
forvalues i = 1/6 {
    quietly {
        su premium_w if outcome_type == `i', meanonly
        local m = r(mean)
        count if outcome_type == `i'
        local n = r(N)
        centile premium_w if outcome_type == `i', centile(50)
        local med = r(c_1)
        local lbl : label outcome_lbl `i'
    }
    di as res ///
    %15s "`lbl'" " |" ///
    %9.2f `m' " |" ///
    %8.2f `med' " |" ///
    %5.0f `n'
}
restore

* Estimation method
preserve
gen method_type = .
replace method_type = 1 if ols_method == 1
replace method_type = 2 if iv_method == 1
replace method_type = 3 if quasi_experimental_method == 1
replace method_type = 4 if other_method == 1
replace method_type = 5 if cognitive_skill_control == 1
label define method_lbl ///
    1 "OLS" ///
    2 "IV" ///
    3 "DID" ///
    4 "Other" ///
    5 "Controls for cognitive"
label values method_type method_lbl
forvalues i = 1/5 {
    quietly {
        su premium_w if method_type == `i', meanonly
        local m = r(mean)
        count if method_type == `i'
        local n = r(N)
        centile premium_w if method_type == `i', centile(50)
        local med = r(c_1)
        local lbl : label method_lbl `i'
    }
    di as res ///
    %22s "`lbl'" " |" ///
    %9.2f `m' " |" ///
    %8.2f `med' " |" ///
    %5.0f `n'
}
restore

* Occupation type
preserve
gen occupation_type = .
replace occupation_type = 1 if prostitutes == 1
replace occupation_type = 2 if other_dressy_occupations == 1
replace occupation_type = 3 if non_dressy_occupation == 1
label define occupation_lbl 1 "Prostitutes" 2 "Dressy jobs" 3 "Non-dressy"
label values occupation_type occupation_lbl
forvalues i = 1/3 {
    quietly {
        su premium_w if occupation_type == `i', meanonly
        local m = r(mean)
        count if occupation_type == `i'
        local n = r(N)
        centile premium_w if occupation_type == `i', centile(50)
        local med = r(c_1)
        local lbl : label occupation_lbl `i'
    }
    di as res ///
    %15s "`lbl'" " |" ///
    %9.2f `m' " |" ///
    %8.2f `med' " |" ///
    %5.0f `n'
}
restore

/******************************************************************************************
   Part 7.2: Subsample Analysis of Publication Bias
   ----------------------------------------------------------------------------------------
   This section replicates FAT-PET regressions on restricted subsets to assess how bias may vary
   across different sample definitions.
******************************************************************************************/

/******************************************************************************************
   Subsample: Excluding Prostitutes
******************************************************************************************/

preserve
keep if prostitutes != 1

ivreg2 premium_w se_premium_w, cluster(study_id)
boottest se_premium_w, nograph      // FAT: bias test
boottest _cons, nograph             // PET: effect test

xtset study_id
xtreg premium_w se_premium_w, fe vce(cluster study_id)
xtreg premium_w se_premium_w, be

restore

/******************************************************************************************
   Subsample: Only Beauty Premia (Excludes Penalties)
******************************************************************************************/

preserve
keep if beauty_penalty == 0

ivreg2 premium_w se_premium_w, cluster(study_id)
boottest se_premium_w, nograph      // FAT: bias test
boottest _cons, nograph             // PET: effect test

xtset study_id
xtreg premium_w se_premium_w, fe vce(cluster study_id)
xtreg premium_w se_premium_w, be

restore

/******************************************************************************************
   Part 7.3: Multiple Meta-Regression (Explaining Heterogeneity)
   ----------------------------------------------------------------------------------------
   We first inspect simple correlations, check for multicollinearity, and then estimate three
   versions of MMR:
     - Full specification
     - Stepwise selection
     - Parsimonious model based on selection
******************************************************************************************/

correlate premium_w se_premium_w interviewer_rated_beauty photo_rated_beauty software_rated_beauty ///
    dummy_beauty beauty_penalty number_of_raters salary study_outcomes teaching_research_outcomes ///
    athletic_success electoral_success male_subjects female_subjects age_subject high_skilled_workers ///
    prostitutes other_dressy_occupations western_culture panel_data data_year ///
    ols_method iv_method quasi_experimental_method ///
    ageexp_control education_control ethnicity_control cognitive_skill_control ///
    noncognitive_skill_control physicality_control published_study impact_factor citations

cap which collin
if _rc {
    di "Installing user-written command: collin"
    ssc install collin
}
collin premium_w se_premium_w interviewer_rated_beauty photo_rated_beauty software_rated_beauty ///
    dummy_beauty beauty_penalty number_of_raters salary study_outcomes teaching_research_outcomes ///
    athletic_success electoral_success male_subjects female_subjects age_subject high_skilled_workers ///
    prostitutes other_dressy_occupations western_culture panel_data data_year ///
    ols_method iv_method quasi_experimental_method ///
    ageexp_control education_control ethnicity_control cognitive_skill_control ///
    noncognitive_skill_control physicality_control published_study impact_factor citations

ivreg2 premium_w se_premium_w interviewer_rated_beauty photo_rated_beauty software_rated_beauty ///
    dummy_beauty beauty_penalty number_of_raters salary study_outcomes teaching_research_outcomes ///
    athletic_success electoral_success male_subjects female_subjects age_subject high_skilled_workers ///
    prostitutes other_dressy_occupations western_culture panel_data data_year ///
    ols_method iv_method quasi_experimental_method ///
    ageexp_control education_control ethnicity_control cognitive_skill_control ///
    noncognitive_skill_control physicality_control published_study impact_factor citations, ///
    cluster(study_id)

stepwise, pr(0.05): regress premium_w se_premium_w interviewer_rated_beauty photo_rated_beauty software_rated_beauty ///
    dummy_beauty beauty_penalty number_of_raters salary study_outcomes teaching_research_outcomes ///
    athletic_success electoral_success male_subjects female_subjects age_subject high_skilled_workers ///
    prostitutes other_dressy_occupations western_culture panel_data data_year ///
    ols_method iv_method quasi_experimental_method ///
    ageexp_control education_control ethnicity_control cognitive_skill_control ///
    noncognitive_skill_control physicality_control published_study impact_factor citations, ///
    vce(cluster study_id)

/******************************************************************************************
   Section 8: Best Practice (Implied Estimate)
   ----------------------------------------------------------------------------------------
   This section derives implied beauty premia under different assumptions:
   (1) No correction,
   (2) Correction for publication bias only (SE → 0),
   (3) Correction for both publication bias and omitted variable bias (SE → 0, identification = 1),
   (4) Same as (3), conditional on prostitutes = 1,
   (5) Same as (3), conditional on prostitutes = 0.
******************************************************************************************/

* Define "identification" as either cognitive control or DID method
gen identification = (quasi_experimental_method == 1 | cognitive_skill_control == 1)

* Estimate benchmark regression model
ivreg2 premium_w se_premium_w prostitutes identification, cluster(study_id)

* ----------------------------------------------------------------------
* (1) No correction (fitted value at sample means of all regressors)
* ----------------------------------------------------------------------

sum se_premium_w
local se_m = r(mean)
sum prostitutes
local prost_m = r(mean)
sum identification
local id_m = r(mean)

lincom _b[_cons] ///
    + _b[se_premium_w] * `se_m' ///
    + _b[prostitutes] * `prost_m' ///
    + _b[identification] * `id_m'

* ----------------------------------------------------------------------
* (2) Publication bias corrected (SE → 0, others at sample means)
* ----------------------------------------------------------------------

lincom _b[_cons] ///
    + _b[se_premium_w] * 0 ///
    + _b[prostitutes] * `prost_m' ///
    + _b[identification] * `id_m'

* ----------------------------------------------------------------------
* (3) Publication bias + omitted variable bias corrected
*     SE → 0, identification = 1, prostitutes at sample mean
* ----------------------------------------------------------------------

lincom _b[_cons] ///
    + _b[se_premium_w] * 0 ///
    + _b[prostitutes] * `prost_m' ///
    + _b[identification] * 1

* ----------------------------------------------------------------------
* (4) Same as (3), but conditional on prostitutes = 1
* ----------------------------------------------------------------------

lincom _b[_cons] ///
    + _b[se_premium_w] * 0 ///
    + _b[prostitutes] * 1 ///
    + _b[identification] * 1

* ----------------------------------------------------------------------
* (5) Same as (3), but conditional on prostitutes = 0
* ----------------------------------------------------------------------

lincom _b[_cons] ///
    + _b[se_premium_w] * 0 ///
    + _b[prostitutes] * 0 ///
    + _b[identification] * 1
	
/******************************************************************************************
   Section 9: Export Dataset for Bayesian Model Averaging in R
   ----------------------------------------------------------------------------------------
   This section prepares a clean, analysis-ready dataset for use with the BMS package in R.
   The export is a CSV file with premium_w as the first column, all variables in correct order,
   and no study_id column.
******************************************************************************************/

* Keep only the relevant variables
keep premium_w se_premium_w interviewer_rated_beauty photo_rated_beauty software_rated_beauty ///
     dummy_beauty beauty_penalty number_of_raters salary study_outcomes teaching_research_outcomes ///
     athletic_success electoral_success male_subjects female_subjects age_subject high_skilled_workers ///
     prostitutes other_dressy_occupations western_culture panel_data data_year ///
     ols_method iv_method quasi_experimental_method ///
     ageexp_control education_control ethnicity_control cognitive_skill_control ///
     noncognitive_skill_control physicality_control published_study impact_factor citations

* Enforce exact column order (especially to ensure premium_w is first)
order premium_w se_premium_w interviewer_rated_beauty photo_rated_beauty software_rated_beauty ///
      dummy_beauty beauty_penalty number_of_raters salary study_outcomes teaching_research_outcomes ///
      athletic_success electoral_success male_subjects female_subjects age_subject high_skilled_workers ///
      prostitutes other_dressy_occupations western_culture panel_data data_year ///
      ols_method iv_method quasi_experimental_method ///
      ageexp_control education_control ethnicity_control cognitive_skill_control ///
      noncognitive_skill_control physicality_control published_study impact_factor citations

* Drop any missing values
drop if missing(premium_w, se_premium_w, interviewer_rated_beauty, photo_rated_beauty, software_rated_beauty, ///
    dummy_beauty, beauty_penalty, number_of_raters, salary, study_outcomes, teaching_research_outcomes, ///
    athletic_success, electoral_success, male_subjects, female_subjects, age_subject, high_skilled_workers, ///
    prostitutes, other_dressy_occupations, western_culture, panel_data, data_year, ols_method, iv_method, ///
    quasi_experimental_method, ageexp_control, education_control, ethnicity_control, cognitive_skill_control, ///
    noncognitive_skill_control, physicality_control, published_study, impact_factor, citations)

* Export as semicolon-delimited CSV (for read.csv2 in R)
export delimited using "beauty_bma.csv", replace delimiter(";")

* Close log and clear memory
log close
clear
