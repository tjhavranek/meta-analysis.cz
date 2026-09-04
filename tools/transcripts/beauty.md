## FRONTMATTER

Zuzana Irsova^{a,b,†}, Tomas Havranek^{a,b,c,†}, Kseniya Bortnikova^{a}, and František Bartoš^{d}

^{a} Charles University, Prague

^{b} Meta-Research Innovation Center, Stanford

^{c} Centre for Economic Policy Research, London

^{d} University of Amsterdam

December 1, 2025

^{*} Corresponding author: Zuzana Irsova, irsova.com. Contact email: zuzana.irsova@fsv.cuni.cz. ^{†} These authors contributed equally to this work. Data, code, and additional materials are available in an online appendix at meta-analysis.cz/beauty.

## ABSTRACT

Common wisdom suggests that beauty helps in the labor market. We show that two factors combine to explain away most of the mean beauty premium reported in the literature.
First, correcting for publication bias reduces the premium by at least a third. Second, controlling for cognitive ability renders the premium small (mean = 1.1%; 95% CrI = −0.8%, 3.0%) for all occupations except sex workers, where appearance is a direct input. The beauty premium is similar for earnings and productivity, a fact inconsistent with discrimination based on employer tastes for beauty. We find little evidence of attenuation bias that could offset publication and omitted-variable biases. To obtain these results we collect 1,159 estimates of the beauty premium in 67 studies and codify 35 aspects that reflect estimation context. We employ recently developed techniques to account for publication bias and model uncertainty.

## KEYWORDS: Beauty premium, productivity, meta-analysis, model uncertainty, publication bias

## 1 | Introduction

According to the authoritative 2011 survey by Hamermesh (1) , people in the top third of looks earn about 5% more compared with average-looking people. We find a remarkably similar mean figure across 1,159 estimates reported in 67 studies published by 2024: moving up along the distribution of beauty by one standard deviation, from the 50th to the 84th percentile, is on average associated with an increase in earnings by 4.3% (5.2% if we give each study, not each estimate, the same weight). But as Figure 1 shows, individual studies have yielded increasingly divergent results, from −5% to 30%. What explains the dispersion in results? Does the robust mean association imply that employers discriminate based on their taste for employees’ beauty? The answers have consequences for anti-discriminatory legislation and compensations after accidents damaging looks. In his superb narrative survey Hamermesh (1) could not make strong conclusions on these questions. After more than a decade, enough studies have been published to allow us to examine both questions formally using meta-analysis, the quantitative method of research synthesis.

FIGURE 1. Reported beauty premiums across studies and countries
Notes: In Panel (a), the horizontal axis shows the median year of data used in each study, and the vertical axis shows the median estimate of the beauty premium reported in that study. All estimates are recalculated to represent the percent increase in earnings or productivity associated with a one-standard-deviation increase in beauty. The mean reported effect, denoted by a solid horizontal line, indicates a 4.3% increase in earnings or productivity associated with an increase in beauty from the 50th to the 84th percentile. The size of each circle reflects the square root of the median number of observations in the corresponding study. In Panel (b), the figure presents a box plot of the estimated beauty premiums for different countries. Countries are ordered from top to bottom by GDP per capita, in ascending order. The length of each box represents the interquartile range (P25–P75), and the dividing line inside the box indicates the median. The whiskers represent the highest and lowest data points within 1.5 times the interquartile range. The mean reported effect is denoted by a solid vertical line. For ease of exposition, extreme outliers are excluded from the figure but included in all statistical tests.

Our main finding is that the observed association between beauty and earnings does not imply that beauty itself affects outcomes in the labor market. The mean premium reported in the literature is exaggerated by publication bias. Conservative corrections for publication bias reduce the mean premium from about 5% to about 3%, while other techniques suggest a more aggressive reduction. Controlling for cognitive ability in the primary study or using difference-in-differences makes the remaining premium small (mean = 1.1%; 95% CrI = −0.8%, 3.0%), with the exception of sex workers. These findings suggest that beauty is not important in the labor market per se but via its correlation with other characteristics. We corroborate this conclusion by showing that the effect of beauty is similar for earnings and (imperfect) measures of productivity, such as sales, research output, and study outcomes. If the beauty premium reported in the literature was due to taste-based discrimination by employers, we would expect a larger correlation of beauty with earnings than with productivity. Finally, we control for several characteristics reflecting the potential extent of measurement error. We fail to find evidence of substantial attenuation bias (measurement error bias in the downward direction). Two existing studies are especially relevant for our analysis. First, Nault et al. (2) provide an excellent summary of previous meta-analyses related to the effect of beauty on various outcomes and personal characteristics. The meta-analyses, in line with our results and those of Hamermesh (1) , suggest a robust positive correlation between beauty and success. Nevertheless, the previous meta-analyses mostly focus on laboratory experiments with indirect external validity for the labor market and do not report economic effects (such as the percent increase in earnings following a one-standard-deviation increase in beauty) but standardized coefficients (such as correlation or Cohen’s d), which complicates interpretation. Moreover, the meta-analyses neither correct the literature for publication bias nor try to systematically tackle model uncertainty. Nault et al. (2) conclude their survey of meta-analyses by observing that, aside from earnings, beauty is also correlated with other characteristics of employees, indicating that the literature is more consistent with statistical than taste-based discrimination.

A second study intimately related to ours is Stinebrickner et al. (3) . Using unique data with detailed information on job tasks, the authors show that the beauty premium exists only in occupations where interpersonal interaction is important. Taken together, the results of Stinebrickner et al. (3) , Nault et al. (2) , and our study present independent evidence against employer taste-based discrimination in relation to beauty. Our main contribution on top of these and other studies is threefold. First, we present the meta-analysis of the economics literature on the beauty premium. Second, we use recently developed techniques to correct the literature for publication bias. Third, using methods that address model uncertainty we trace the differences in results to differences in estimation context. Doing so allows us to gauge the effect of omitted variables, measurement error, and other identification issues.

Publication bias describes a situation when reported results represent a systematically different subset of all results obtained by researchers. Ioannidis et al. (4) and Bartoš et al. (5) show that the problem is ubiquitous in economics and that the typical estimate is exaggerated twofold due to the bias. Other high-quality recent papers document the extent of the problem (6–15) . The baseline bias-correction method that we use is Robust Bayesian Meta-Analysis (RoBMA), which is a weighted average of various existing bias-correction methods with weights proportional to model fit and parsimony (16–19) .

Most meta-analysis techniques correct for publication bias by exploiting the property of standard regression analysis: estimates should be independent of their standard errors. If a correlation exists, it is attributable to publication bias: large standard errors, given by noise in data or methods, must be compensated by large point estimates to produce statistical significance. It follows that more precise estimates are less likely to be biased. This is, however, a strong assumption, and a variety of mechanisms can produce a correlation between estimates and standard errors even in the absence of publication bias. For example, Keane and Neal (20) show that, with instrumental variables, the correlation arises naturally. Method choices may affect both estimates and standard errors systematically. Precision can be p-hacked (changed by changing specification in order to achieve statistical significance), which introduces reverse causality. To address these problems we use the novel Meta-Analysis Instrumental Variable Estimator (MAIVE) (21) , which accounts for potential spurious precision and various forms of p-hacking. We also employ the p-hacking correction by Mathur (22) .

Our other major contribution is a detailed examination of the link between estimation context and the beauty premiums reported in the literature. Because randomized controlled trials on the effect of beauty on earnings are infeasible, and convincing instruments are hard to come by (23) , the bulk of the literature relies on ordinary least squares and tries to control for observable characteristics that might be correlated with earnings or beauty. A few studies, such as Mehic et al. (24) , exploit the shift to online learning during the Covid-19 pandemic and employ the difference-in-differences method. We collect 35 variables that reflect the context in which the premiums are obtained: measurement of beauty (e.g. photo-rated vs. interviewer-rated), measurement of success (earnings or different proxies for productivity), occupation characteristics (e.g. interpersonal intensity, output measurability), method choice (e.g. control for cognitive skills or social skills), and publication characteristics (e.g. publication status and journal impact factor).

Due to the large number of factors plausibly capturing estimation context and leading to different results, we face substantial model uncertainty: it is unclear ex ante which variables should be included in the final model. The natural response to model uncertainty is Bayesian model averaging (BMA). (25–28) BMA runs many regressions with different combinations of controls and then makes a weighted average over them with weights proportional to data fit and parsimony. To account for potential collinearity we use the dilution prior (29) . Our results suggest that only three variables robustly and systematically explain the differences in the reported beauty premiums: 1) the standard error (a proxy for publication bias), 2) a dummy for sex workers, and 3) control for cognitive skills. Conditional on correcting for publication bias, controlling for cognitive skills (or using difference-in-differences), and focusing on other occupations than sex workers, the mean beauty premium is only about 1% and not statistically different from zero. This contrasts the frequently cited conclusion by Hamermesh’s careful narrative survey that “beauty pays” in the labor market (1) .

An important issue in the literature on the beauty premium is attenuation bias (23,30,31) . While Hamermesh (1) shows that, across cultures, there is surprising agreement on what it means to be beautiful, some measurement error is inevitable. If the measurement error is classical, techniques such as ordinary least squares will yield beauty premiums that are biased towards zero. Two general strategies to combat the problem have been suggested in the literature. First, instrumental variables: for example, Hamermesh et al. (32) instrument children’s looks by their mother’s, and Gu and Ji (33) use the looks of other blood relatives. While these instruments can also help with other endogeneity issues, we believe that they are most likely to be useful in attenuating attenuation bias. Second, some studies try to limit measurement error by employing a large number of raters or by using software rating. We find no evidence consistent with substantial attenuation bias: IV estimates tend to be similar to OLS estimates and it does not seem to matter systematically how many raters the study uses or whether it employs software rating.

## 2 | Results

### 2.1 | Conceptual Background

Physical attractiveness has long been reported to shape how individuals are perceived and rewarded, from education to criminal justice to labor markets. In employment settings, those judged to be more attractive tend to earn higher wages, receive better evaluations, and have more favorable hiring prospects than others (34,35) . But even putting aside potential omitted variables and publication bias, the reported size and nature of this “beauty premium” vary, sometimes substantially, across jobs, industries, and social groups, as Figure 2 illustrates for our metaanalysis data. An emerging interdisciplinary literature points to a wide range of mechanisms linking appearance to labor market outcomes, from early-life reinforcement to institutional bias to cultural valuation.

FIGURE 2. Selected patterns in the literature
Notes: Estimates of beauty premiums are recomputed to represent the percent increase in earnings or productivity associated with a one-standard-deviation increase in beauty. The mean estimate is denoted by a solid vertical line. Numerical summary statistics are available in Table S2.

Economic models typically distinguish between taste-based discrimination, in which decisionmakers simply prefer attractive individuals, and statistical discrimination, where appearance is treated as a signal of unobserved productivity (34) . Both frameworks help explain empirical patterns reported in the literature, but they bracket important psychological and sociological dimensions that shape how attractiveness is perceived and rewarded.

Psychological research emphasizes perceptual bias, especially the halo effect: the tendency to attribute intelligence, competence, and warmth to attractive individuals (36–39) . These assumptions can influence treatment in school, hiring, and evaluation, even in the absence of actual performance differences. For example, Zebrowitz et al. (40) report that facial cues linked to attractiveness systematically affect perceived intelligence, independent of measured ability. Such effects are especially pronounced when evaluations are subjective or involve limited information. From a sociological perspective, attractiveness may function as a form of capital. Bourdieu’s (41) concept of social capital captures how beauty can facilitate access to influential networks or resources. Hakim (42,43) introduces erotic capital as a distinct asset, comprising physical appearance, charisma, and self-presentation, that is convertible into social or economic advantage, particularly in settings where personal impression matters. These frameworks suggest that beauty is not merely a source of bias but a structured advantage that interacts with institutional norms.

Attractiveness could also shape outcomes through developmental feedback over the life course. Attractive children achieve slightly higher test scores and attain more schooling. These early advantages may reflect social feedback mechanisms, although the precise channels remain debated (32) . The differences could accumulate over time, influencing both cognitive and noncognitive development. In longitudinal data, more attractive adolescents tend to complete more education and earn higher wages as adults (31) . These effects may reflect subtle but persistent differences in how individuals are treated, rather than differences in underlying ability.

Some evolutionary psychologists have proposed a biological correlation between beauty and intelligence, potentially driven by assortative mating or shared heritable factors (44–46) . This relationship is theoretically attributed to assortative mating or shared heritable factors, mechanisms well-documented in other domains (47,48) . The idea is that intelligent individuals are more likely to partner with attractive ones, producing offspring with both traits. While logically possible, the evidence is limited. A large genetically informed study by Mitchem et al. (49) finds no meaningful phenotypic or genetic correlation between attractiveness and general intelligence. These theories remain conceptually relevant but empirically as yet unsubstantiated.

The beauty premium also seems to vary systematically across job characteristics. It tends to be reported the strongest in interpersonal or client-facing roles, such as sales, education, or hospitality, where physical appearance might plausibly influence persuasion, rapport, or customer satisfaction (3,50) . In contrast, it is often reported negligible in solitary or technical roles where output is measurable and appearance plays no obvious role. Two features appear particularly important: the degree of interpersonal interaction required, and the subjectivity of performance evaluation. In contexts where judgments are discretionary or socially mediated, attractiveness tends to matter more.

Finally, the rewards to beauty can be shaped by culture and identity. In societies that devote more economic resources to appearance (for example, higher per-capita spending on grooming and cosmetics) beauty may carry greater economic value. But standards of attractiveness are not universally applied. Romi (51) argues that the beauty premium is conditioned by gender, race, and age, with norms often enforced unevenly across social groups. In some contexts, attractiveness may buffer against stigma; in others, it may reinforce exclusion.

Despite extensive theorizing, empirical estimates of the beauty premium remain inconsistent, with reported effects ranging from negligible to large even within individual contexts and for individual countries, as Figure 1 and Figure 2 demonstrate. We conduct a comprehensive meta-analysis to reconcile these discrepancies by identifying systematic patterns in the evidence and correcting for publication bias. This approach allows us to assess when beauty appears to matter, to what extent the premium reflects differences in measured ability, and how far contextual factors account for the wide dispersion of findings.

### 2.2 | Publication Bias

Publication bias, broadly defined, is the difference between the mean reported result and the mean result originally obtained by researchers. The meta-analysis literature sometimes distinguishes between narrowly defined publication bias and p-hacking (52) . When the distinction is made, publication bias denotes the decision to report an estimate or hide it in a file drawer. P-hacking then denotes the process by which researchers adjust their model to make their estimates more publishable—for example, more statistically significant. Given that under extreme p-hacking no limits exist for the resulting estimates, no model can convincingly account for p-hacking. Most meta-analysis techniques were developed with narrowly defined publication bias in mind. Some of them, though, also address many plausible forms of p-hacking. We use the term publication bias in its more general meaning, separating it from p-hacking only when necessary.

FIGURE 3. Visual diagnostics of publication bias and p-hacking
Notes: In Panel (a), the figure depicts a histogram of the estimated beauty premiums. All estimates are recomputed to represent the percent increase in earnings or productivity associated with a one-standard-deviation increase in beauty. The mean reported effect, denoted by a solid horizontal line, indicates a 4.3% increase in earnings or productivity associated with an increase in beauty from the 50th to the 84th percentile. In Panel (b), the figure shows the corresponding funnel plot. In the absence of publication bias, the most precise estimates should cluster around the mean estimate, denoted by the solid vertical line, while less precise estimates should be symmetrically dispersed around the mean. The figure indicates that small or negative imprecise estimates are less likely to be reported than similarly imprecise but large and positive ones. In Panel (c), the figure displays the histogram of $z$-statistics for the reported beauty effects. The vertical lines represent the value of 0 (sign change), the critical value of 1.96 (5% significance), and the critical value of 2.58 (1% significance). Bins just below and above these thresholds are highlighted, with the zero threshold being most relevant. The corresponding caliper tests are reported in Table S5. The black line shows the estimated kernel density. In Panel (d), the figure compares the model fit of an unadjusted random-effects meta-analysis model (black) with a publication-bias-adjusted robust Bayesian meta-analysis (RoBMA, blue) using a meta-analytic $z$-curve plot^{64}. The histogram of observed $z$-statistics shows two discontinuities: one at $z = 0$ (reflecting suppression of negative results) and another at $z = 1.65$ (reflecting suppression of non-significant results, $\alpha = 0.10$), highlighted by red dashed lines. The posterior predictive distribution from the conventional random-effects model underestimates significant positive estimates and overestimates non-significant ones, indicating poor fit. In contrast, the robust Bayesian model closely tracks the observed discontinuities, providing a substantially better, though not perfect, description of the data. This visualization is consistent with strong evidence of publication bias and demonstrates the importance of correcting for it. The expected discovery rate (EDR) is estimated at 0.31, 95% CI [0.29, 0.33], compared with the observed discovery rate (ODR) of 0.47, 95% CI [0.44, 0.50], quantifying the degree of publication bias. The estimated number of missing estimates is N_{missing} = 1,242, 95% CI [821, 1,751], and the false discovery risk is inflated to 0.12, 95% CI [0.11, 0.13], further underscoring the consequences of publication bias in this literature. Extreme outliers are excluded from the figure for clarity but are included in all statistical tests.

Figure 3 shows visual diagnostics of publication bias. In panel (a) we report the distribution of the estimates. An asymmetrical histogram may signal publication bias, perhaps against negative estimates of the beauty premium, but can also be consistent with heterogeneity and no bias. We observe asymmetry towards large positive estimates. A more informative diagnostic of publication bias is the so-called funnel plot (53,54) , shown here in panel (b). It is a scatter plot of estimated beauty effects on the horizontal axis against their precision (1/SE) on the vertical axis. The most precise estimates at the top of the figure are close to each other, while less precise estimates at the bottom are more widely dispersed.

Crucially, imprecise estimates larger than the mean should be just as common as imprecise estimates smaller than the mean. A symmetrical inverted funnel shape should follow, and symmetry in the absence of publication bias is the key feature of the funnel plot. Panel (b) in Figure 3 suggests that, for the literature on the beauty effect, the funnel plot is not symmetrical. Large imprecise estimates are much more common than small, and especially negative, imprecise estimates. (It is also apparent that the funnel for sex workers is completely different from the rest of the data, which is why in the Supplementary Information we conduct the analysis separately for the subsample of sex workers and other occupations.) In other words, estimates are positively correlated with their standard errors. Because the correlation arises if researchers prefer positive or statistically significant estimates, it is synonymous with publication bias in most of the meta-analysis literature.

Panel (c) in Figure 3 illustrates the importance of the psychologically important thresholds for the z-statistic. Estimates that are just negative and much less likely to be reported than estimates that are just positive, a finding corroborated by Table S5 in the Supplementary Information. Panel (d) shows how our baseline model, Robust Bayesian Meta-Analysis (RoBMA), is able to fit the distribution of reported z-statistics. The fit is not perfect, but unlike random effects it correctly captures the jumps at zero and significance thresholds.

RoBMA is a weighted average of several bias-correction techniques (both selection models and techniques based on the funnel plot), with weights proportional to data fit and model parsimony (16–19) . Details are available in the Methods section. We use two versions of RoBMA: the simple one that treats each estimate as the unit of analysis, and the three-level one that treats each study as the unit and accounts for within-study correlation among estimates. RoBMA has two main advantages. First, it reduces possible p-hacking at the meta-analysis level, because meta-analysts do not choose the individual correction model (out of the great number available) but use a well-established mechanism that assigns weights to each individual model. Second, it is computationally feasible even for small samples, which is especially important in our case because for many contexts we have limited sample sizes. This is also the reason why we report simple RoBMA along with three-level RoBMA: the former is stable even with a small number of studies.

The main results for the overall sample are reported in Table 1. After correcting for publication bias, simple RoBMA suggests a mean beauty premium of 0.2, while three-level RoBMA yields 3.1. Because some databases are used repeatedly in different studies and some studies use several databases, additionally we report three-level RoBMA where database, not study, is the main unit of analysis. Doing so yields a mean beauty premium of 2.9. Running separately a selection model (55) and a funnel-based model (PET-PEESE) (56) , which are constituent models of simple RoBMA, yields results close to those of simple RoBMA. Nevertheless, all these models share a common assumption: estimates in the literature are not actively p-hacked. For this reason we also report the results of two models that explicitly allow for p-hacking: MAIVE (Meta-Analysis Instrumental Variable Estimator) (21) and RTMA (Right-Truncated Meta-Analysis) (22) . These models yield mean corrected estimates of 3.1 and 2.3, respectively. We conclude that the mean beauty premium conservatively corrected for publication bias is around 3, down from about 5 prior to the correction.

Part 2 of Table 1 shows that excluding sex workers further reduces the corrected premium, and that focusing on standardized effects (instead of percent increase in earnings or productivity) yields very small premiums. Table 2 shows the corrected mean premiums for individual contexts. Due to small samples in some subgroups, three-level RoBMA often fails to track heterogeneity and yields results close to the overall mean. Simple RoBMA shows more variation in results, but reports small beauty premiums for all contexts except scientific research and sex industry. An important result concerns cognitive and non-cognitive skill controls. When only non-cognitive skill control is used, the beauty premium remains substantial. When cognitive control is used individually or jointly with non-cognitive, the mean beauty premium is small. This suggests that control for cognitive skills reduces the beauty premium independently of control for noncognitive skills. Finally, we observe that the bias-corrected beauty premium is similar for earnings and productivity measures.

### 2.3 | Heterogeneity

This section has two goals. First, we examine whether our findings regarding publication bias are robust to the inclusion of controls reflecting study design. The approach is complementary to that of the MAIVE method employed in the previous section: MAIVE accounts for unobserved heterogeneity that may bias meta-analysis models; now we explicitly control for observable data and method choices, including those traditionally linked to “risk of bias” in meta-analysis. The approach of the current section will dominate MAIVE if sample size is correlated with method choices that influence both the reported estimates and their standard errors. Second, we examine why, on top of differences in the propensity for publication bias, the estimates reported in the literature vary so much, extending the subgroup analysis of the previous section. The variables reflecting study context, as well as the Bayesian model averaging approach (BMA) used to link this context to reported beauty premiums, are described in the Methods section.

FIGURE 4. Model inclusion across the posterior model space in Bayesian model averaging
Notes: On the vertical axis, covariates are ranked by their posterior inclusion probabilities, from the highest at the top to the lowest at the bottom. Variables near the top are therefore most strongly associated with variation in the reported beauty premiums. The horizontal axis shows the cumulative posterior model probability, with models on the left having the highest posterior probability. Blue (darker in grayscale) indicates a positive estimated association for the corresponding covariate; red (lighter in grayscale) indicates a negative association; white indicates that the covariate is not included in the model. Numerical results are reported in Table 3. DID = difference-in-differences. OLS = ordinary least squares. IV = instrumental variables. All variables are described in Table S10. Technical details and diagnostics of the BMA exercise are provided in Table S11 and Figure S3.

Figure 4 presents a graphical summary of Bayesian model averaging results. On the vertical axis the explanatory variables are ranked according to their posterior inclusion probabilities from the highest at the top to the lowest at the bottom. In other words, the variables shown at the top are the ones most useful in explaining differences in the reported beauty effects. The horizontal axis shows the values of the cumulative posterior model probability, the model weight used in BMA. The models on the left display the best combination of data fit and parsimony. Blue color (darker in grayscale) means that the estimated parameter of the corresponding explanatory variable is positive. Red color (lighter in grayscale) means the estimated parameter is negative. No color means the corresponding explanatory variable is excluded. The figure shows that only 4 variables out of the 35 that we consider are robustly associated with the reported beauty effects: standard error (proxy for publication bias), cognitive skill control, a dummy variable for sex workers, and the impact factor of the journal in which the study was published.

Table 3 shows the numerical results of Bayesian model averaging and a simple stepwise regression provided as a frequentist robustness check. The posterior mean in BMA denotes the partial derivative of the reported beauty premium with respect to the corresponding study characteristic. For example, including a control for cognitive skills typically reduces the beauty premium by 2.3 percentage points compared to the case in which cognitive skills are ignored in primary studies. The corresponding variable also has a high posterior inclusion probability, almost 100%. The same is true for the standard error: even when we explicitly control for heterogeneity we obtain strong evidence for publication bias. We also find that, unsurprisingly, sex workers enjoy substantially larger beauty premiums (by about 5 percentage points) than other occupations. The BMA results also suggest that studies published in more prestigious journals (as measured by the impact factor) tend to publish larger beauty premiums. Nevertheless, the latter finding does not survive the frequentist check reported in the right-hand part of Table 3. In contrast, the stepwise regression shows statistical significance for the variable related to difference-in-differences, for which BMA finds a large coefficient estimate (−2.5) but an inclusion probability slightly below 50%.

The analysis of heterogeneity yields three key takeaways. First, the finding of publication bias is robust to explicit control for observables. Second, most aspects related to estimation context are not systematically associated with the reported beauty effects. We find no consistent evidence that variables potentially associated with the extent of attenuation bias (algorithmic beauty rating, number of raters, IV estimation) affect the results systematically. Similarly, it does not seem to matter systematically whether researchers consider the effect of beauty on earnings or on proxies for productivity, whether interpersonal intensity and output measurability in the given context is high or low, and whether the researchers is conducted in different countries (proxied by beauty spending and culture). Third, much of the remaining beauty premium beyond publication bias for occupations other than sex workers is due to a correlation between beauty and cognitive ability.

The third point is best illustrated by computing the mean beauty premium conditional on correcting for publication bias and controlling for cognitive ability either via an explicit inclusion of the control or via difference-in-differences (Table 4). When we plug in the corresponding variables to the results of BMA, we obtain an implied beauty premium of 0.6% (95% CrI = −1.5, 2.6). For sex workers, the implied premium is 5.4% (95% CrI = 2.3, 10.5); for all other contexts the implied premium is close to zero (Part 2 of the table). Implied beauty premiums can also be computed using the RoBMA approach (Part 3 and 4), though this technique delivers more uncertain results for individual occupations including sex workers. Doing so for the three-level RoBMA yields a premium of 0.4% (95% CrI = 0.0, 2.2). All individual contexts examined in Part 4 are consistent with small beauty premiums. Because the occupations examined in the beauty literature are not representative of the entire economy, we use sampling weights to better approximate the US workforce. Doing so yields a mean beauty premium of 1.1% (95% CrI = −0.8, 3.0).

## 3 | Discussion

Across the literature, we find a sizable reported beauty premium (around 5%) that falls by one-third or more on average (to about 3%) after correcting for publication bias and becomes small (about 1% and not statistically different from zero) once cognitive ability is controlled. A natural interpretation is that attractiveness correlates with accumulated human capital, not with an independent market value of appearance. Developmental evidence provides results consistent with this view: attractive children could receive more encouragement from teachers and peers, attain slightly higher test scores, and complete more education^{32}. If beauty maps into schooling and measured ability through such early reinforcement, conditioning on those factors should largely absorb the premium, as we find.

This pattern does not align fully with standard models of statistical discrimination in settings where ability is observed. Under those models, appearance is a proxy for unobserved productivity, and a residual premium should persist even after ability is controlled. Instead, our results suggest that appearance proxies measured skill differences reported in primary studies, with little evidence of an additional payoff once information about ability is available. In other words, the beauty-wage correlation largely reflects differential skill accumulation rather than continuing reliance on appearance as a signal. Under this developmental framework, cognitive ability could act as a mediator rather than a confounder; thus, while we do not find strong evidence of substantial direct discrimination, beauty could remain economically significant as a driver of human capital acquisition that the labor market later rewards.

The aggregate evidence in our meta-analysis also limits the explanatory power of non-cognitive or purely perceptual channels. Control for soft-skill measures does not attenuate the premium. Laboratory and field studies both suggest that attractiveness can influence judgments in information-poor or subjective settings, especially in customer-facing or interpersonal tasks^{3,35,37,38}. In our meta-analysis, however, extensive subgroup and moderator exploration fails to uncover sizable systematic differences across occupations or industries (with the exception of sex work), likely reflecting both genuine concentration of returns in interpersonal contexts and the limited occupational granularity available in primary studies. Taken together with the collapse of the premium after conditioning on ability, this pattern is not what we would expect if non-cognitive traits or evaluator bias were the dominant drivers in typical wage settings, though minor effects may persist where performance is hard to measure. Focusing on measured ability instead of perceived ability does not change the results qualitatively.

Our results cannot be interpreted as supporting a strong genetic or biological link between beauty and intelligence. Twin-based evidence reports little to no phenotypic or genetic association between facial attractiveness and general intelligence in the available data^{49}. Earlier claims of a genetic relationship^{45,46} have so far not been corroborated by subsequent large-sample research. Overall, the weight of evidence points to educational and developmental mechanisms, with task-specific social returns in interpersonal jobs, and at most a small residual payoff to appearance per se once information about ability is available.

Our analysis has two main limitations. First, random errors in beauty measurement can bias the reported estimates, and meta-analysis, downwards. While we cannot fully correct for what almost certainly is an attenuation bias in the literature, we use three strategies to gauge the extent of the problem: comparison of OLS and IV estimates, comparison of human and software rating, and comparison based on the number of raters. More raters or software rating should plausibly diminish measurement error. Because the IV estimates in the literature are unlikely to help with omitted variables or reverse causality, under the assumption of a classical measurement error the difference between OLS and IV serves as a proxy for attenuation bias^{57}. We find no evidence that IV estimates differ systematically from OLS estimates, and it does not seem to matter how many raters are employed or whether software rating is used.

Second, for most primary studies we do not have crisp data on job tasks that would allow us to cleanly separate occupations where beauty is likely to be a genuinely productive factor. Stinebrickner et al.^{3} have such data and find no beauty effects for jobs where employees do not come into personal contact with customers. In a meta-analysis setting we can separate beauty premium estimates for occupations where looks are likely to be especially important (lawyers, politicians, etc.) from those where looks are unlikely to matter much (analysts, researchers, etc.). We put sex workers aside as a special category where beauty is a key productive characteristic. Our results show that sex workers enjoy beauty premiums clearly much larger than other occupations, but we fail to find systematic differences among the remaining categories.

## Data Availability

All data have been deposited in the meta-analysis.cz repository (meta-analysis.cz/beauty).

## Code Availability

All codes have been deposited in the meta-analysis.cz repository (meta-analysis.cz/beauty).

## Acknowledgments

We are grateful to Henrik Jordahl, Andrew Leigh, and Panu Poutvaara for kindly sharing additional statistics on top of their published datasets. We thank seminar and conference participants at Charles University, University of Canterbury, University of Augsburg, Victoria University of Wellington, and University of Piraeus for useful comments that helped us improve the paper. Z.I. and F.B. acknowledge support from the Czech Science Foundation (grant no. 23-05227M). T.H. and K.B. acknowledge support from the Czech Science Foundation (grant no. 24-11583S).

## Author Contributions Statement

Z.I. and T.H. proposed the research idea; Z.I. and K.B. collected data; Z.I. and F.B. coded the study; T.H. interpreted the results, with assistance from Z.I. and K.B.; T.H. wrote the main text, with assistance from Z.I. and F.B. Finally, T.H. wrote the Supplementary Information, with assistance from F.B.

## Competing Interests Statement

The authors declare no competing interests.

## 4 | Methods

### 4.1 | Data

We focus on studies conducted in field settings. Laboratory studies on the subject exist, most prominently the maze experiment by Mobius and Rosenblat^{35}, especially in the field of psychology, and have been covered by previous meta-analyses^{2}. We believe these two parts of the literature are best analyzed separately. While laboratory studies on this topic are very useful and informative, it is not always clear how their findings translate to real-world behavior in the labor market. Aside from external validity issues, a practical consideration is that most laboratory experiments do not report enough information that would allow us to convert their results to the percent increase in earnings or productivity associated with a one-standard-deviation increase in beauty.

Figure S1 in the Supplementary Information provides details on how we include individual empirical studies in the meta-analysis. We start with a Google Scholar search. We prefer Google Scholar to other databases because it goes through the full text of studies, not just the title, abstract, and keywords, as is the case for many other sources. After identifying potentially usable studies we also do “snowballing” by inspecting the studies frequently cited among the potentially usable ones. Snowballing reduces our dependence on Google Scholar. We use the following inclusion criteria: i) the study must report the effect of beauty on a continuous variable reflecting earnings or productivity; ii) the beauty measurement used in the study must focus on physiognomy (just the face); iii) the study must focus on the subject’s own earnings or productivity (e.g. not the income of the spouse, firm valuation, or college rank); iv) the study must report statistics that allow us to convert the reported estimate to the percent increase in earnings or productivity following a one-standard-deviation increase in beauty (e.g. studies reporting zero-order correlations or lacking the standard deviation of the beauty measure cannot be converted); v) the study must report standard errors or other statistics from which standard errors can be computed; and vi) the study must report primary results and focus on field (real-world) outcomes; we exclude laboratory experiments and surveys. Based on these criteria, we excluded 69 studies that reported related empirical estimates: 8 for lacking a continuous earnings or productivity variable, 7 for using a beauty measure not based on physiognomy, 12 for not focusing on the subject’s own earnings or productivity, 19 for not reporting convertible statistics (often just correlation coefficients), 9 for missing standard errors, and 14 because they were laboratory experiments or surveys. The literature search was terminated on February 16, 2024. The dataset, together with R and Stata codes and reasons for exclusion of the 69 above-mentioned individual studies, is available at meta-analysis.cz/beauty. The inclusion criteria leave 67 studies listed in Table S1 in the Supplementary Information; we call them primary studies, and together they provide 1,159 estimates of the beauty effect. Each study typically reports many estimates: for example using OLS vs. IV, men vs. women, results for different occupations, etc. In the analysis, and most prominently in subsection 2.3, we control for 35 characteristics that reflect the context in which the estimate was produced in the primary study. Figure S2 shows a box plot of the reported estimates. The studies in the figure are ranked by the age of the data they use from oldest to newest. There is no apparent trend in the findings. Most studies report at least some estimates that are close to the overall mean beauty premium, 4.3% (5.2% when each study, not each estimate, is treated as the unit of analysis). Many studies report much higher estimates, in several cases above 20%. In the analysis we winsorize these data at the 1% level to limit the influence of extreme outliers. Overall we observe substantial variance in results both within and across studies.

Figure 1 shows that the estimated coefficients are typically positive but not huge across countries, with the notable exception of Finland (though these are results from a single study on politicians). The figure does not suggest any systematic difference in the beauty premium across cultures or income levels. Panel (a) of Figure 3 shows the histogram of the reported beauty effects. Two facts stand out in the figure. First, the distribution is asymmetrical: while many large positive outliers appear in the literature, few estimates are substantially negative. Second, the mode of the distribution is dominated by estimates that are just positive. Both observations are consistent with publication bias, but they could also be consistent with systematic heterogeneity.

Table S2 and Figure 2 give a general overview of the heterogeneity in the literature, more fully explored in subsection 2.3. It does not seem to matter much how beauty is measured. Self-rated measures of beauty tend to be associated with smaller beauty effects, but only a few studies use self-rating. Beauty penalties (comparisons of below-average and average looks) seem to be slightly smaller than beauty premiums (above-average vs. average looks). While in the main analysis we pool both types of estimates together, as a robustness check we also conduct the analysis separately for premiums and penalties. For comparability, we always recompute all estimates to represent the percent increase in earnings or productivity associated with a one-standard-deviation increase in beauty.

Regarding the measure of success, the response variable in primary studies, the literature can be divided into two groups: studies focusing on earnings and studies focusing on (imperfect) measures of productivity. Productivity in this context can be measured as sales, research outcomes, study outcomes, electoral success, etc. On average, the mean beauty premium for earnings is identical to the mean premium for productivity: 4.3%, which is consistent with no or little taste-based discrimination by employers. Athletes and politicians seem to enjoy relatively large beauty premiums. Not surprisingly, the beauty premium is the largest for sex workers. Other data characteristics, such as gender and culture, interpersonal intensity, and output measurability, do not seem to be associated with substantial systematic differences in the results.

Studies of sex workers form a small and well-identified subset of our database: four studies (6% of the 67 field studies) contributing 55 effect-size estimates (about 5% of the 1,159 observations). These papers rely on four distinct datasets---U.S. and Canadian anonymous online escort reviews, the 2003 Ecuador HIV Survey, the 2001 Mexico Sex Worker Survey, and the Bangladesh BIDS/UNDP Survey---and all analyze transactional earnings in settings where client- or interviewer-rated attractiveness directly enters price determination.

Given their small number and distinctive institutional context, we treat these papers as a separate subsample (a fact that is also apparent from the funnel plot) and report their associations in dedicated robustness analyses, ensuring that the implied estimates for the general labor market are not influenced by this unique sector. Within this subsample, most reported associations fall in the range of 5–15% per one-standard-deviation increase in attractiveness. Following Hamermesh^{1}, who highlighted sex work as an informative boundary case of the beauty-earnings relationship, we view these studies as theoretically valuable for understanding contexts in which beauty mechanically enters prices, while not interpreting them as representative of typical labor-market processes.

Regarding estimation characteristics, two subsets of the literature stand out: estimates obtained using difference-in-differences and estimates obtained using OLS while controlling for cognitive ability. These two subsets tend to report beauty premiums much smaller than the rest of the literature. The finding, which as we will see will survive correction for publication bias and model uncertainty, suggests that the raw correlation between beauty and earnings is driven by a correlation between beauty and other productive characteristics. Nevertheless, Table S2 and Figure 2 also suggest that studies published in top journals typically report relatively large estimates. Next, we examine how these preliminary results are affected by an explicit treatment of publication bias and model uncertainty.

### 4.2 | Publication Bias

We estimate the total and subgroup mean beauty premiums corrected for publication bias using robust Bayesian meta-analysis (RoBMA)^{16–19}. RoBMA applies Bayesian model averaging to account for model uncertainty (i.e., the presence vs. absence of the effect, heterogeneity, publication bias, and moderation) and incorporates multiple publication bias adjustment techniques. It combines a set of six selection models (accounting for different forms of selection on statistical significance and direction of the effect) and PET-PEESE (to account for “small-study effects”). Bayesian model averaging allows RoBMA to place more weight on models that predict the data well, making it more robust to model misspecification and directly evaluate the evidence for the presence vs. absence of the effect, heterogeneity, and publication bias via Bayes factors.

As such, we can distinguish the absence of evidence from the evidence of absence, even though both correspond to non-significant $p$-values in a classical analysis. Since the meta-analysis is performed on regression coefficients (that is, non-standardized effect-size estimates), we matched the scale of the default prior distributions specified in Bartoš et al.^{17,18} to the unit-information prior scale described in Mulder and van Aert^{58}. This required rescaling the prior distribution by 25.8 for the beauty premium (i.e., $\mu \sim$ Normal(0, 25.8), $\tau \sim$ Inverse-Gamma(1, 3.87)) and by 0.095 for the standard error (i.e., $\mu \sim$ Normal(0, 0.095), $\tau \sim$ Inverse-Gamma(1, 0.014)).

All subgroup estimates were specified via a meta-regression with standardized mean contrast and a correspondingly scaled prior distribution (i.e., MVN(0, 6.45) and MVN(0, 0.024), respectively) and computed via estimated marginal means. The subgroup estimates adjusted for sex workers and for non-quasi-experimental studies or studies not controlling for cognitive skill were obtained by extending the models with the appropriate terms specified via dummy contrasts, again using a correspondingly scaled prior distribution (as in the subgroup analyses). The prostitutes adjustment was not used in the non-prostitutes subgroup analysis, and the quasi-experimental or cognitive-skill-control adjustment was not used in the cognitive-control sub-analyses. The three-level version of the specified models followed the description in Bartoš et al.^{19}. Occupations that fully overlap with industries (e.g., all estimates in the subgroup “Legal services” correspond to lawyers) are omitted from the Occupation group reported in Table 2. Each *subgroup model* uses only estimates for that dimension (e.g., industry-specific effects) and includes dummies for the *categories*. If RoBMA detects little systematic heterogeneity, category means may look similar. These subgroup means need not average to the overall mean, which is based on all effects, including non-subgrouped estimates. RoBMA averages over models with and without a true association. When some probability is assigned to the null, the posterior is pulled toward zero and the 95% credible interval may start or end exactly at zero. This is expected behavior of spike-and-slab model averaging. Definitions of the subgroups are provided in Table S18 in the Supplementary Information. More details on the RoBMA exercise are available in Table S16.

The models included in RoBMA correct for publication bias, but not for p-hacking. For p-hacking correction, we use the Right-Truncated Meta-Analysis (RTMA) approach^{22}. RTMA corrects for p-hacking by explicitly modeling the selective reporting of only the most extreme or statistically significant estimates. RTMA assumes that the observed effect sizes arise from an underlying normal (or random-effects) distribution that has been *right-truncated* at an unknown threshold induced by researcher behavior (e.g., repeated testing, flexible specifications, or selective reporting of large $t$-statistics). In a Bayesian framework, the truncation point, the mean effect, and the between-study heterogeneity are estimated jointly via the truncated likelihood, allowing the posterior to adjust for the fact that small or non-significant estimates are systematically underrepresented. This yields bias-corrected posterior summaries that account for the distributional distortions characteristic of p-hacking.

To ensure our results are not driven by the functional form of the dependent variable, particularly given the heterogeneity of productivity measures (e.g., citations, votes, tips) which may not always offer an intuitive percentage interpretation, we implement a robustness check using standardized effect sizes. In this specification, we convert all estimates to represent the standard deviation change in earnings or productivity associated with a one-standard-deviation increase in beauty. This normalization renders all outcomes strictly comparable on a dimensionless scale. We find that using standardized effects yields a negligible beauty premium after correction for publication bias (last two specifications of Part 2 in Table 1). More details on related robustness checks (standardized outcome and objectively measured ability) are available in Table S7.

Specifications in Panel A of Table S6 in the Supplementary Information present statistical tests of funnel plot asymmetry^{59,60}. In the first column we show a simple OLS regression and find a substantial correlation between estimates and standard errors. The intercept in the regression can be interpreted as the estimated beauty premium conditional on maximum precision (and therefore no publication bias), the top of the funnel, and thus the mean estimate corrected for publication bias^{61}. We obtain a value of 2.9, which is 1/3 smaller than the uncorrected mean of 4.3. The corrected mean increases when we include study-level fixed effects (3.5). The fixed-effects estimator only captures decisions within studies, and can be thus interpreted as capturing p-hacking rather than strictly publication bias^{22}. Publication bias, narrowly defined, is captured by the between-effects estimator, which corresponds to selection across studies. The between-effects estimate for the corrected beauty premium is 2.2. Therefore it seems that in this literature publication bias can be more important than p-hacking. Note that techniques based on the funnel plot, unlike most other methods reported later in Panel B, are robust to p-hacking on the reported point estimates: even if estimates are artificially large to offset large standard errors, funnel-based techniques are virtually unaffected because they focus on the most precise estimates.

But, in contrast to the common meta-analysis assumption employed in the above-mentioned funnel asymmetry tests, in the literature on the beauty effect some of the correlation between estimates and standard errors can plausibly be unrelated to publication bias. First, Keane and Neal^{20} show that for IV estimates the correlation arises by construction. Second, some method choices can influence both estimates and standard errors. For example, compared to OLS, IV estimates can bring larger point estimates (because they address attenuation bias) but also larger standard errors (because IV estimation tends to be generally less precise). Third, if researchers p-hack standard errors (e.g. by changes in clustering), the correlation resulting from this form of p-hacking is not associated with any bias in the mean reported estimate, and funnel asymmetry tests introduce a downward bias that did not exist before.

In other words, we face a classical endogeneity problem in our meta-analysis specifications. Irsova et al.^{21} present a simple solution: the meta-analysis instrumental variable estimator (MAIVE). MAIVE uses inverse sample size used in the primary study as an instrument for the reported squared standard error. Sample size is a strong instrument by virtue of the definition of the standard error, which is a function of the sample size. While it does not completely eliminate the endogeneity problem, it alleviates it substantially: researchers find it more difficult to artificially increase sample size than to artificially decrease the standard error; the problem identified by Keane and Neal^{20} does not apply to sample size; and the choice of methods (such as IV vs. OLS) is often unrelated to sample size. The fourth column in Table S6 reports the results of MAIVE. The Anderson-Rubin confidence intervals recommended by Andrews and Kasy^{62} and Keane and Neal^{20} suggest marginal statistical insignificance of publication bias at the 5% level. This leads to a correction in the mean beauty premium to 3.1.

The last column of Panel A shows a specification weighted by the inverse of the number of estimates reported per study: in other words, each study now has the same weight. The corrected mean beauty premium is similar to the one previously reported for study-level fixed effects. In Panel B we show models weighted by reported inverse variance, which is common in meta-analysis but which we avoided in Panel A due to the apparent endogeneity of the standard error in this literature. The first specification is the funnel-asymmetry test similar to those in Panel A but weighted by inverse variance. The remaining models present recently developed nonlinear techniques for publication bias correction. While they relax the assumption that publication bias is a linear function of the standard error, they do not allow for any p-hacking (with the exception of RTMA): put differently, these techniques assume that each reported estimate is individually unbiased. All techniques in Panel B except for RTMA yield very small, indeed almost zero corrected beauty premiums, and by comparing the first column in Panel A with the first column in Panel B it seems that the reason for the difference is inverse variance weighting, an inherent part of the nonlinear models in Panel B. Robustness checks reported in Table S8 and Table S9 show that excluding estimates for sex workers or beauty penalties does not change the results qualitatively.

Another piece of evidence indicates that inverse variance weights can be problematic in the beauty premium literature. Table S4, reported in the Supplementary Information, shows that, based on the Andrews and Kasy^{55} model, estimates and standard errors are correlated even after correction for publication bias. While the result may indicate that any of the assumptions of the Andrews and Kasy^{55} model are not met, the assumption of no relation between estimates and standard errors in the absence of publication bias is by far the most important assumption^{63}. For this reason we prefer the results reported in Panel A of Table S8 to the precision-weighted specifications reported in Panel B. To be on the safe side, for the representative estimate we choose the median value reported in Panel A: 2.9 corresponding to the simple OLS (which is also very close to the baseline three-level RoBMA estimate interpreted in the main text). This correction for publication bias is conservative given all the estimates in Panel B. The advantage of the simple OLS correction is that it can be easily incorporated into the analysis of heterogeneity and model uncertainty in the heterogeneity section.

Figure 3 gives intuition on the sources of publication bias. In Panel (a), the figure depicts a histogram of the estimated beauty premiums. All estimates are recomputed to represent the percent increase in earnings or productivity associated with a one-standard-deviation increase in beauty. The mean reported effect, denoted by a solid horizontal line, indicates a 4.3% increase in earnings or productivity associated with an increase in beauty from the 50th to the 84th percentile. In Panel (b), the figure shows the corresponding funnel plot. In the absence of publication bias, the most precise estimates should cluster around the mean estimate, denoted by the solid vertical line, while less precise estimates should be symmetrically dispersed around the mean. The figure indicates that small or negative imprecise estimates are less likely to be reported than similarly imprecise but large and positive ones. In Panel (c), the figure displays the histogram of $z$-statistics for the reported beauty effects. The vertical lines represent the value of 0 (sign change), the critical value of 1.96 (5% significance), and the critical value of 2.58 (1% significance). Bins just below and above these thresholds are highlighted, with the zero threshold being most relevant. The black line shows the estimated kernel density. In all three cases, estimates just above the threshold are more common in the literature, which is again consistent with publication bias. But the jumps at 1.96 and 2.58 are relatively small compared to the jump at zero: estimates that are just positive are much more likely to be reported than estimates that are just negative. Caliper tests presented in Table S5 in the Supplementary Information corroborate these observations and suggest that publication bias is mainly driven by the preference for positive estimates, while the preference for statistically significant estimates plays a relatively less important part. In Panel (d), the figure compares the model fit of an unadjusted random-effects meta-analysis model (black) with a publication-bias-adjusted robust Bayesian meta-analysis (RoBMA, blue) using a meta-analytic $z$-curve plot^{64}. The histogram of observed $z$-statistics shows two discontinuities: one at $z = 0$ (reflecting suppression of negative results) and another at $z = 1.65$ (reflecting suppression of non-significant results, $\alpha = 0.10$), highlighted by red dashed lines. The posterior predictive distribution from the conventional random-effects model underestimates significant positive estimates and overestimates non-significant ones, indicating poor fit. In contrast, the robust Bayesian model closely tracks the observed discontinuities, providing a substantially better, though not perfect, description of the data. This visualization is consistent with strong evidence of publication bias and demonstrates the importance of correcting for it. The expected discovery rate (EDR) is estimated at 0.31, 95% CI [0.29, 0.33], compared with the observed discovery rate (ODR) of 0.47, 95% CI [0.44, 0.50], quantifying the degree of publication bias. The estimated number of missing estimates is N_{missing} = 1,242, 95% CI [821, 1,751], and the false discovery risk is inflated to 0.12, 95% CI [0.11, 0.13], further underscoring the consequences of publication bias in this literature.

### 4.3 | Heterogeneity

The variables reflecting estimation context and used in Bayesian model averaging are defined and summarized in Table S10 in the Supplementary Information. For ease of exposition we divide them into five groups: measurement of beauty, measurement of success, data characteristics, estimation technique, and publication characteristics. The table shows stylized facts regarding the literature. For example, only a few studies use self-rating or computer algorithms to generate beauty ratings; most studies rely on interviewers (45% of the estimates) or humans evaluating photos (42%). Only about 18% of the studies focus explicitly on beauty penalty as opposed to beauty premium. Most studies (59%) focus on earnings, while the rest rely on various, though often imperfect, proxies for productivity. Quasi-experimental estimation techniques are quite rare in the literature because of the paucity of convincing instruments and natural experiments---with the exception of the switch to online learning during the Covid-19 pandemic, which allows for difference-in-differences estimation. A substantial number of studies (38%) find a way to control for a proxy for cognitive ability, such as IQ. Almost all studies in our sample are published in peer-reviewed journals (89%).

To capture cross-national cultural variation in the valuation of appearance, we employ the share of household consumption allocated to personal care (OECD/Eurostat) rather than subjective survey indices. This “revealed preference” measure avoids the cultural response biases inherent in self-reported values (e.g., World Values Survey) and provides an objective economic proxy for the societal salience of beauty. To rigorously test mechanism-based heterogeneity, we replaced subjective proxies for appearance requirements with objective, task-based metrics derived from O*NET data. By explicitly modeling Interpersonal Intensity and Output Measurability, we can distinguish whether the beauty premium is driven by customer interaction demands (taste-based discrimination) or by information asymmetry in roles where individual output is harder to verify.

After excluding baseline categories, we are left with 35 explanatory variables. All of them can potentially affect the reported estimates of beauty effects, but probably only few will prove systematically important in practice. We thus face substantial model uncertainty: including all the variables into one regression would result in exceedingly imprecise estimates even for the most important variables. As Steel^{28} notes, the natural response to model uncertainty is Bayesian model averaging (BMA). BMA exploits the Markov chain Monte Carlo algorithm^{65} which allows us to avoid estimating all the $2^{35}$ potential models and to concentrate on the most important portion of the model mass. For our baseline estimation we choose the unit information prior recommended by Eicher et al.^{27}, which gives the prior that each coefficient is zero the same weight as one data point. Additionally we use the dilution model prior developed by George^{29}, which discounts models with substantial collinearity. In effect, BMA weights individual models by measures related to model fit and parsimony. For each variable the sum of the weights of the models in which the variable is included is denoted by posterior inclusion probability (PIP). Variables with a high PIP are effective in explaining the differences in the beauty effects reported in the literature.

Table 4 reports implied beauty premiums for the full sample and key subgroups, conditional on three main adjustments: (i) correction for publication bias, (ii) inclusion of cognitive-ability controls or use of difference-in-differences estimation, and (iii) exclusion of occupations involving sex work. The last adjustment is not applied to the prostitutes subgroup. In addition, implied beauty premiums based on Bayesian model averaging (BMA; Parts 1-2) are calculated as fitted values in which beauty is either software-rated or assessed by the maximum number of raters. Other study characteristics (output measurability, data year, and number of citations) are set to their maximum observed values in the sample to represent a relevant and recent research context. These additional adjustments do not qualitatively affect the implied point estimate but widen the credible intervals, as they incorporate the uncertainty associated with multiple model and variable choices used to compute the fitted values. Due to collinearity issues, not all subgroups can be included in BMA. Results in Parts 3-4 are fitted values from Robust Bayesian meta-analysis (RoBMA). Further details on RoBMA specifications are provided in Table S3 in the Supplmentary Information. RoBMA (3lvl) accounts for within-study dependence, and RoBMA (3lvl, database) accounts for within-database dependence. The overall RoBMA estimate is based on all reported beauty premiums, including those not tied to any specific occupation. In contrast, the subgroup RoBMA models use only the subset of estimates that identify particular occupations. Because many studies report general (non-occupation-specific) effects, the subgroup analyses rely on different data and models, so their results do not average to the overall mean. The occupation-weighted estimate combines RoBMA-based subgroup results using employment shares from the U.S. Bureau of Labor Statistics’ May 2023 Occupational Employment and Wage Statistics, approximating a representative beauty premium for the U.S. labor market. We estimated the economy-wide distribution using a mixture of split-normal distributions weighted by occupational shares. To ensure internal consistency, the location parameters of the split-normal distributions were adjusted such that the expected value of each subgroup’s simulation matched the reported meta-analytic mean exactly, while preserving the reported asymmetry of the credible intervals. The BMA intervals are approximated using uncertainty estimated in the frequentist model to allow for study-level clustering; three-level RoBMA accounts for within-study correlation automatically. RoBMA averages over models with and without a true association. When some probability is assigned to the null, the posterior is pulled toward zero and the 95% credible interval may start or end exactly at zero. This is expected behavior of spike-and-slab model averaging. Definitions of subgroups are available in Table S18.

In the Supplementary Information we report robustness checks that employ different priors for BMA (Table S12) and that use a subsample of reported estimates without beauty penalties (Table S14). We also present another version of the frequentist check: instead of the stepwise regression, in Table S12 we run OLS that only includes variables with a posterior inclusion probability above 0.5. Our main results are not affected by these changes. The only plausible scenario that could produce a non-negligible beauty premium beyond publication bias and after controlling for cognitive ability is one in which we put great weight on results published in journals with a high impact factor---perhaps as a proxy for unobserved aspects of study quality. The impact factor variable, however, is statistically insignificant at the 5% level in all the frequentist models we run (and which are clustered at the study level), implying a lack of robust evidence for a strong association with the reported beauty premiums.

## 5 | Tables and Figures

TABLE 1. Mean beauty premium after correction for publication bias

| **Part 1. Full sample** | | RoBMA | RoBMA (3lvl) | RoBMA (3lvl, database) |

| --- | --- | --- | --- | --- |

| Bias-corrected mean (%) | | 0.21 | 3.13 | 2.88 |

| 95% interval | | [0.00, 1.27] | [2.05, 4.25] | [1.70, 4.03] |

| Clusters | | – | 67 | 63 |

| Estimates | | 1,159 | 1,159 | 1,159 |

| | Selection model | PET–PEESE | MAIVE | RTMA |

| Bias-corrected mean (%) | 0.49 | 0.34 | 3.05 | 2.27 |

| 95% interval | [-0.31, 1.30] | [-0.20, 0.89] | [0.73, 5.00] | [1.69, 2.99] |

| Clusters | 67 | 67 | 67 | – |

| Estimates | 1,159 | 1,159 | 1,159 | 1,159 |

| **Part 2. Robustness** | Excluding prostitutes | | Standardized outcome | |

| | RoBMA | RoBMA (3lvl) | RoBMA | RoBMA (3lvl) |

| Bias-corrected mean (% or std.) | 0.06 | 2.73 | 0.02 | 0.05 |

| 95% interval | [0.00, 0.85] | [1.69, 3.77] | [0.00, 0.04] | [0.03, 0.07] |

| Clusters | – | 63 | – | 62 |

| Estimates | 1,104 | 1,104 | 1,000 | 1,000 |
Notes: Part 1 reports the results of bias-correction estimators applied to the full sample. RoBMA refers to the standard Robust Bayesian Meta-Analysis framework, while RoBMA (3lvl) denotes its three-level extension that explicitly accounts for dependence among multiple estimates reported within the same study or database^{16–19}. MAIVE = Meta-Analysis Instrumental Variable Estimator^{21}; RTMA = Right-Truncated Meta-Analysis^{22}; selection model^{55}; and PET–PEESE = Precision-Effect Test and Precision-Effect Estimate with Standard Error^{56}. Note that PET–PEESE and selection-model approaches are included within RoBMA, whereas MAIVE and RTMA are not. Unlike the methods incorporated in RoBMA, MAIVE and RTMA are designed to accommodate various forms of *p*-hacking in the literature. Our preferred specifications are the three-level RoBMA, which accounts for dependence within databases as a robust weighted average of bias-correction models, and MAIVE together with RTMA, which are intended to address potential *p*-hacking. Part 2 reports RoBMA and RoBMA (3lvl) results for two robustness checks: one excluding prostitutes and the other using, instead of the percent increase in earnings or productivity associated with a one-standard-deviation increase in beauty, standardized effect sizes (a one-standard-deviation increase in earnings or productivity associated with a one-standard-deviation increase in beauty). The number of clusters denotes the number of studies or databases used when estimating multilevel models. The table reports the posterior model-averaged mean effect size for RoBMA, the mode for RTMA, and the mean for all other estimators. Brackets report 95% credible intervals for Bayesian estimators, 95% Anderson–Rubin confidence intervals for MAIVE, and 95% cluster-robust confidence intervals for all other estimators. RoBMA averages over models with and without a true association. When some probability is assigned to the null, the posterior is pulled toward zero and the 95% credible interval may start or end exactly at zero. This is expected behavior of spike-and-slab model averaging. More details on the RoBMA exercise are available in Table S16. More details on robustness checks (standardized outcome and objectively measured ability) are available in Table S7. More details on other approaches are available in Table S6.

TABLE 2. Bias-corrected beauty premiums by subgroup

| | Est. | Stud. | RoBMA Mean | RoBMA 95% cred. int. | | RoBMA 3lvl Mean | RoBMA 3lvl 95% cred. int. | |

| --- | --- | --- | --- | --- | --- | --- | --- | --- |

| *Industry* | | | | | | | | |

| Customer services | 57 | 7 | 0.38 | -0.59 | 1.34 | 4.05 | 0.00 | 6.91 |

| Financial services | 34 | 6 | 1.00 | -0.31 | 2.32 | 4.40 | 0.00 | 7.08 |

| Legal services | 31 | 1 | 1.32 | 0.16 | 2.48 | 4.21 | 0.00 | 7.28 |

| Political office | 37 | 4 | 2.52 | 1.47 | 3.64 | 4.36 | 0.00 | 7.17 |

| Professional sports | 56 | 5 | 1.78 | 0.45 | 3.19 | 4.77 | 0.00 | 9.89 |

| Scientific research | 42 | 3 | 8.12 | 6.45 | 9.74 | 4.15 | 0.00 | 6.97 |

| Sex industry | 55 | 4 | 7.00 | 5.90 | 8.06 | 4.75 | 0.00 | 9.92 |

| *Occupation* | | | | | | | | |

| General population | 435 | 23 | 1.54 | 0.92 | 2.13 | 3.64 | 2.33 | 5.23 |

| Executives | 56 | 10 | 3.61 | 2.06 | 5.14 | 3.52 | 2.10 | 5.32 |

| Salespeople | 32 | 5 | -1.27 | -2.77 | 0.26 | 3.15 | 0.75 | 4.72 |

| Students | 233 | 9 | -1.52 | -2.30 | -0.75 | 2.32 | -1.60 | 4.46 |

| Teachers | 109 | 8 | 1.50 | 0.54 | 2.42 | 2.56 | -1.06 | 4.46 |

| *Gender* | | | | | | | | |

| Female | 447 | 48 | 0.79 | 0.00 | 1.79 | 3.33 | 2.08 | 4.60 |

| Male | 375 | 44 | 0.79 | 0.00 | 1.79 | 3.61 | 2.35 | 4.88 |

| *Degree of customer contact* | | | | | | | | |

| No customer contact | 318 | 23 | -1.13 | -1.68 | -0.23 | 0.89 | -0.62 | 2.70 |

| Some customer contact | 401 | 19 | 0.17 | -0.33 | 0.86 | 3.95 | 2.46 | 5.51 |

| Direct customer contact | 440 | 32 | 1.09 | 0.59 | 1.76 | 4.19 | 2.85 | 5.49 |

| *Measurability of output* | | | | | | | | |

| Low output measurability | 135 | 6 | 0.19 | 0.00 | 1.27 | 3.15 | 2.06 | 4.27 |

| Mid output measurability | 274 | 16 | 0.19 | 0.00 | 1.27 | 3.15 | 2.07 | 4.26 |

| High output measurability | 750 | 51 | 0.19 | 0.00 | 1.27 | 3.15 | 2.07 | 4.25 |

| *Intensity of interpersonal interaction* | | | | | | | | |

| Low interpersonal intensity | 180 | 17 | 1.59 | 0.00 | 3.27 | 3.14 | 2.03 | 4.23 |

| Mid interpersonal intensity | 519 | 30 | 0.17 | -0.95 | 1.07 | 3.16 | 2.08 | 4.24 |

| High interpersonal intensity | 460 | 33 | 0.83 | 0.00 | 1.91 | 3.16 | 2.08 | 4.24 |

| *Cognitive and non-cognitive skill controls* | | | | | | | | |

| No skill control | 617 | 48 | 1.64 | 0.75 | 2.45 | 3.53 | 2.37 | 4.67 |

| Cognitive skill control only | 298 | 16 | -1.66 | -2.77 | -0.62 | 2.03 | 0.42 | 3.82 |

| Non-cognitive skill control only | 97 | 10 | 3.26 | 1.66 | 4.74 | 4.11 | 2.42 | 5.87 |

| Both skill controls | 147 | 15 | -0.26 | -1.60 | 1.00 | 2.03 | 0.36 | 3.85 |

| *Objectively measured cognitive skill control* | | | | | | | | |

| Objective cognitive skill control only | 256 | 12 | -0.05 | -0.78 | 1.02 | 0.73 | 0.00 | 2.45 |

| Objective cog. and non-cog. control | 127 | 10 | 0.62 | 0.00 | 2.02 | 0.73 | 0.00 | 2.48 |

| Objective cog. control or DID | 395 | 21 | 0.05 | 0.00 | 0.86 | 0.49 | 0.00 | 2.10 |

| *Output type* | | | | | | | | |

| Earnings | 688 | 43 | 0.24 | 0.00 | 1.30 | 3.29 | 2.11 | 4.50 |

| Productivity | 471 | 29 | 0.14 | -0.49 | 1.24 | 2.92 | 1.53 | 4.14 |
Notes: The table reports mean beauty premiums across subgroups after correcting for publication bias. All estimates are recalculated to represent the percent increase in earnings or productivity associated with a one-standard-deviation increase in beauty. Occupations that fully overlap with industries (e.g., all estimates in the subgroup "Legal services" correspond to lawyers) are omitted from the Occupation group. RoBMA denotes the Robust Bayesian Meta-Analysis model (a weighted average of bias-correction approaches), while the specification on the right-hand side applies the three-level RoBMA (RoBMA 3lvl), which explicitly accounts for the dependence among multiple effect-size estimates reported within the same study^{16–19}. Each *subgroup model* uses only estimates for that dimension (e.g., industry-specific effects) and includes dummies for the *categories*. If RoBMA detects little systematic heterogeneity, category means may look similar. These subgroup means need not average to the overall mean, which is based on all effects, including non-subgrouped estimates. DID = difference-in-differences. *Est.* indicates the number of estimates included in the analysis, and *Stud.* denotes the number of studies used in the multilevel specification. *Mean* reports the posterior model-averaged mean estimate for each subgroup, and the associated 95% credible interval reflects the posterior uncertainty surrounding this estimate. RoBMA averages over models with and without a true association. When some probability is assigned to the null, the posterior is pulled toward zero and the 95% credible interval may start or end exactly at zero. This is expected behavior of spike-and-slab model averaging. Definitions of the subgroups are provided in Table S18. More details on the RoBMA exercise are available in Table S16.

TABLE 3. Contextual characteristics associated with variation in reported beauty premiums

| Response variable: Beauty premium (%) | Bayesian model averaging (baseline model) | | | Stepwise regression (frequentist check) | | |

| --- | --- | --- | --- | --- | --- | --- |

| | P. mean | P. SD | PIP | Mean | SE | p-value |

| Constant | 2.140 | NA | 1.000 | 3.582 | 0.562 | 0.001 |

| Standard error | 0.430 | 0.043 | 1.000 | 0.426 | 0.112 | 0.001 |

| *Measurement of beauty* | | | | | | |

| Interviewer-rated beauty | -0.035 | 0.206 | 0.037 | | | |

| Photo-rated beauty | 0.490 | 0.714 | 0.352 | | | |

| Software-rated beauty | 0.006 | 0.121 | 0.011 | | | |

| Dummy beauty | -0.569 | 0.692 | 0.444 | | | |

| Beauty penalty | -0.007 | 0.091 | 0.012 | | | |

| Number of raters | 0.043 | 0.129 | 0.114 | | | |

| *Measurement of success* | | | | | | |

| Earnings | 0.003 | 0.064 | 0.008 | | | |

| Study outcomes | -0.006 | 0.095 | 0.010 | | | |

| Teaching & research outcomes | 0.564 | 1.007 | 0.269 | | | |

| Athletic success | -0.004 | 0.105 | 0.006 | | | |

| Electoral success | 0.584 | 1.272 | 0.201 | | | |

| *Data characteristics* | | | | | | |

| Male subjects | -0.004 | 0.058 | 0.009 | | | |

| Female subjects | -0.005 | 0.062 | 0.010 | | | |

| Subjects' age | -0.048 | 0.262 | 0.042 | | | |

| High-skilled workers | -0.001 | 0.077 | 0.009 | | | |

| Prostitutes | 4.918 | 1.071 | 0.999 | 4.386 | 1.199 | 0.001 |

| Interpersonal intensity | 0.000 | 0.070 | 0.006 | | | |

| Output measurability | 0.880 | 1.876 | 0.204 | | | |

| Beauty spending | 0.000 | 0.010 | 0.007 | | | |

| Western culture | 0.000 | 0.036 | 0.005 | | | |

| Panel data | -0.938 | 1.014 | 0.507 | | | |

| Data year | 0.262 | 0.461 | 0.274 | | | |

| *Estimation technique* | | | | | | |

| OLS method | -0.006 | 0.082 | 0.011 | | | |

| IV method | -0.001 | 0.056 | 0.005 | | | |

| DID method | -2.406 | 2.875 | 0.456 | -5.078 | 2.061 | 0.016 |

| Age control | 0.011 | 0.119 | 0.014 | | | |

| Education control | -0.017 | 0.123 | 0.025 | | | |

| Ethnicity control | -0.010 | 0.092 | 0.016 | | | |

| Cognitive skill control | -2.265 | 0.444 | 1.000 | -2.750 | 0.691 | 0.001 |

| Non-cognitive skill control | 0.116 | 0.378 | 0.103 | | | |

| Physicality control | 0.000 | 0.032 | 0.005 | | | |

| *Publication characteristics* | | | | | | |

| Published study | -0.234 | 0.653 | 0.133 | | | |

| Impact factor | 0.262 | 0.116 | 0.914 | | | |

| Citations | -0.002 | 0.031 | 0.009 | | | |

| Studies | 67 | | | 67 | | |

| Estimates | 1,159 | | | 1,159 | | |
Notes: The posterior mean in BMA represents the partial derivative of the reported beauty premium with respect to the corresponding study characteristic. P. mean = posterior mean, P. SD = posterior standard deviation, PIP = posterior inclusion probability, SE = standard error. BMA employs the unit-information prior recommended by Eicher et al.^{27} and the dilution prior proposed by George^{29}, which reduces the influence of collinearity among covariates. The frequentist check uses a 5% significance threshold and standard errors clustered at the study level. Covariate definitions are provided in Table S10. Technical details and diagnostics of the BMA exercise are reported in Table S11 and Figure S3.

TABLE 4. Implied beauty premiums after bias correction and full adjustment

| **Part 1. Bayesian model averaging, overall** | Mean (%) | 95% cred. int. | |

| --- | --- | --- | --- |

| Full sample | 0.56 | -1.48 | 2.60 |

| Full sample (stepwise) | -0.33 | -2.37 | 1.71 |

| **Part 2. Bayesian model averaging, subgroups** | Mean (%) | 95% cred. int. | |

| Athletes | 0.47 | -3.23 | 4.17 |

| Politicians | 1.06 | -8.41 | 10.52 |

| Prostitutes | 5.39 | 2.28 | 8.50 |

| Students | 0.47 | -1.78 | 2.71 |

| Teachers & Scientists | 1.03 | -2.13 | 4.20 |

| Male subjects | 0.56 | -1.58 | 2.69 |

| Female subjects | 0.56 | -1.80 | 2.91 |

| Earnings | 0.47 | -1.67 | 2.62 |

| Low interpersonal intensity | 0.56 | -2.67 | 3.78 |

| Mid interpersonal intensity | 0.56 | -1.77 | 2.89 |

| High interpersonal intensity | 0.56 | -1.57 | 2.68 |

| Low output measurability | 0.00 | -2.52 | 2.53 |

| Mid output measurability | 0.20 | -1.85 | 2.26 |

| High output measurability | 0.37 | -1.67 | 2.40 |

| **Part 3. Robust Bayesian meta-analysis, overall** | Mean | 95% cred. int. | |

| Full sample (% units) | -0.19 | -1.28 | 0.00 |

| Full sample (3lvl, % units) | 0.39 | 0.00 | 2.16 |

| Full sample (3lvl, database, % units) | 0.01 | 0.00 | 0.02 |

| Excluding prostitutes (% units) | -0.17 | -1.26 | 0.00 |

| Excluding prostitutes (3lvl, % units) | 0.44 | 0.00 | 2.33 |

| Standardized effect (SD units) | 0.00 | -0.01 | 0.00 |

| Standardized effect (3lvl, SD units) | 0.02 | 0.00 | 0.05 |

| **Part 4. Robust Bayesian meta-analysis (3lvl), subgroups** | Mean (%) | 95% cred. int. | |

| Athletes | 1.53 | 0.00 | 5.80 |

| Executives | 1.29 | 0.00 | 3.77 |

| Lawyers | 0.73 | -4.86 | 3.47 |

| Politicians | 1.30 | 0.00 | 4.75 |

| Salespeople | 0.97 | -0.62 | 2.83 |

| Scientists | 1.58 | -0.35 | 7.29 |

| Prostitutes | 1.42 | -4.05 | 10.20 |

| Students | 0.81 | -1.05 | 2.69 |

| Teachers | 0.58 | -2.78 | 2.69 |

| Male subjects | 1.58 | 0.00 | 3.36 |

| Female subjects | 1.25 | -0.44 | 2.98 |

| Earnings | 0.43 | 0.00 | 2.19 |

| Low interpersonal intensity | 0.31 | 0.00 | 2.10 |

| Mid interpersonal intensity | 0.32 | 0.00 | 2.11 |

| High interpersonal intensity | 0.33 | 0.00 | 2.12 |

| Low output measurability | 0.53 | 0.00 | 2.28 |

| Mid output measurability | 0.53 | 0.00 | 2.29 |

| High output measurability | 0.53 | 0.00 | 2.28 |

| Occupation-weighted estimate | 1.11 | -0.75 | 3.00 |
Notes: The table reports implied beauty premiums for the full sample and key subgroups, conditional on three main adjustments: (i) correction for publication bias, (ii) inclusion of cognitive-ability controls or use of difference-in-differences estimation, and (iii) exclusion of occupations involving sex work. The last adjustment is not applied to the prostitutes subgroup. In addition, implied beauty premiums based on Bayesian model averaging (BMA; Parts 1-2) are calculated as fitted values in which beauty is either software-rated or assessed by the maximum number of raters. Other study characteristics (output measurability, data year, journal impact factor, and number of citations) are set to their maximum observed values in the sample to represent a relevant and recent research context. Due to collinearity issues, not all subgroups can be included in BMA. Results in Parts 3-4 are fitted values from Robust Bayesian meta-analysis (RoBMA). Further details on RoBMA specifications are provided in Table S3. RoBMA (3lvl) accounts for within-study dependence, and RoBMA (3lvl, database) additionally accounts for within-database dependence. The overall RoBMA estimate is based on all reported beauty premiums, including those not tied to any specific occupation. In contrast, the subgroup RoBMA models use only the subset of estimates that identify particular occupations. Because many studies report general (non-occupation-specific) effects, the subgroup analyses rely on different data and models, so their results do not average to the overall mean. The occupation-weighted estimate combines RoBMA-based subgroup results using employment shares from the U.S. Bureau of Labor Statistics' May 2023 Occupational Employment and Wage Statistics, approximating a representative beauty premium for the U.S. labor market. The BMA intervals are approximated using uncertainty estimated in the frequentist model to allow for study-level clustering; three-level RoBMA accounts for within-study correlation automatically. RoBMA averages over models with and without a true association. When some probability is assigned to the null, the posterior is pulled toward zero and the 95% credible interval may start or end exactly at zero. This is expected behavior of spike-and-slab model averaging. Definitions of subgroups are available in Table S18.

## REFERENCES

1. Hamermesh, D. S. *Beauty Pays: Why Attractive People Are More Successful* (Princeton University Press, 2011).

2. Nault, K. A., Pitesa, M. & Thau, S. The Attractiveness Advantage At Work: A Cross-Disciplinary Integrative Review. *Academy of Management Annals* **14**, 1103–1139 (2020).

3. Stinebrickner, R., Stinebrickner, T. & Sullivan, P. Beauty, Job Tasks, and Wages: A New Conclusion about Employer Taste-Based Discrimination. *The Review of Economics and Statistics* **101**, 602–615 (2019).

4. Ioannidis, J. P., Stanley, T. D. & Doucouliagos, H. The Power of Bias in Economics Research. *Economic Journal* **127**, F236–F265 (2017).

5. Bartos, F. *et al.* Footprint of publication selection bias on meta-analyses in medicine, environmental sciences, psychology, and economics. *Research Synthesis Methods* **15**, 500–511 (2024).

6. Blanco-Perez, C. & Brodeur, A. Publication Bias and Editorial Statement on Negative Findings. *Economic Journal* **130**, 1226–1247 (2020).

7. Brown, A. L., Imai, T., Vieider, F. & Camerer, C. Meta-Analysis of Empirical Estimates of Loss-Aversion. *Journal of Economic Literature* **62**, 485–516 (2024).

8. Card, D., Kluve, J. & Weber, A. What Works? A Meta Analysis of Recent Active Labor Market Program Evaluations. *Journal of the European Economic Association* **16**, 894–931 (2018).

9. DellaVigna, S. & Linos, E. RCTs to Scale: Comprehensive Evidence From Two Nudge Units. *Econometrica* **90**, 81–116 (2022).

10. Elliott, G., Kudrin, N. & Wuthrich, K. Detecting p-hacking. *Econometrica* **90**, 887–906 (2022).

11. Imai, T., Rutter, T. A. & Camerer, C. F. Meta-Analysis of Present-Bias Estimation Using Convex Time Budgets. *Economic Journal* **131**, 1788–1814 (2021).

12. Neisser, C. The Elasticity of Taxable Income: A Meta-Regression Analysis. *Economic Journal* **131**, 3365–3391 (2021).

13. Stanley, T. D., Doucouliagos, H., Ioannidis, J. P. A. & Carter, E. C. Detecting publication selection bias through excess statistical significance. *Research Synthesis Methods* **12**, 776–795 (2021).

14. Vivalt, E. Specification Searching and Significance Inflation Across Time, Methods and Disciplines. *Oxford Bulletin of Economics and Statistics* **81**, 797–816 (2019).

15. Xue, X., Reed, W. R. & Menclova, A. Social capital and health: a meta-analysis. *Journal of Health Economics* **72**, 102317 (2020).

16. Maier, M., Bartos, F. & Wagenmakers, E.-J. Robust Bayesian meta-analysis: Addressing publication bias with model-averaging. *Psychological Methods* **28**, 107–122 (2023).

17. Bartos, F., Maier, M., Wagenmakers, E.-J., Doucouliagos, H. & Stanley, T. D. Robust Bayesian meta-analysis: Model-averaging across complementary publication bias adjustment methods. *Research Synthesis Methods* **14**, 99–116 (2023).

18. Bartos, F., Maier, M., Stanley, T. D. & Wagenmakers, E.-J. Robust Bayesian meta-regression: Model-averaged moderation analysis in the presence of publication bias. *Psychological Methods* **forthcoming** (2025).

19. Bartos, F., Maier, M. & Wagenmakers, E.-J. Robust Bayesian multilevel meta-analysis: Adjusting for publication bias in the presence of dependent effect sizes. Preprint, PsyArXiv, PsyArXiv.org (2025).

20. Keane, M. & Neal, T. Instrument strength in IV estimation and inference: A guide to theory and practice. *Journal of Econometrics* **235**, 1625–1653 (2023).

21. Irsova, Z., Bom, P. R. D., Havranek, T. & Rachinger, H. Spurious Precision in Meta-Analysis of Observational Research. *Nature Communications* **16**, 8454 (2025).

22. Mathur, M. B. P-hacking in meta-analyses: A formalization and new meta-analytic methods. *Research Synthesis Methods* **15**, 483–499 (2024).

23. Hamermesh, D. & Abrevaya, J. Beauty is the promise of happiness? *European Economic Review* **64**, 351–368 (2013).

24. Mehic, A. Student beauty and grades under in-person and remote teaching. *Economics Letters* **219**, 110782 (2022).

25. Fernandez, C., Ley, E. & Steel, M. F. J. Benchmark priors for Bayesian Model Averaging. *Journal of Econometrics* **100**, 381–427 (2001).

26. Ley, E. & Steel, M. F. On the Effect of Prior Assumptions in Bayesian Model Averaging with Applications to Growth Regression. *Journal of Applied Econometrics* **24**, 651–674 (2009).

27. Eicher, T. S., Papageorgiou, C. & Raftery, A. E. Default priors and predictive performance in Bayesian model averaging, with application to growth determinants. *Journal of Applied Econometrics* **26**, 30–55 (2011).

28. Steel, M. F. J. Model Averaging and its Use in Economics. *Journal of Economic Literature* **58**, 644–719 (2020).

29. George, E. I. Dilution priors: Compensating for model space redundancy. In *IMS Collections Borrowing Strength: Theory Powering Applications – A Festschrift for Lawrence D. Brown*, vol. 6, 158–165 (Institute of Mathematical Statistics, 2010).

30. Harper, B. Beauty, Stature and the Labour Market: A British Cohort Study. *Oxford Bulletin of Economics and Statistics* **62**, 771–800 (2000).

31. Scholz, J. K. & Sicinski, K. Facial Attractiveness and Lifetime Earnings: Evidence from a Cohort Study. *The Review of Economics and Statistics* **97**, 14–28 (2015).

32. Hamermesh, D., Gordon, R. & Crosnoe, R. O Youth and Beauty: Children's Looks and Children's Cognitive Development. *Journal of Economic Behavior & Organization* **212**, 275–289 (2023).

33. Gu, T. & Ji, Y. Beauty premium in China's labor market: Is discrimination the main reason? *China Economic Review* **57**, 101335 (2019).

34. Hamermesh, D. S. & Biddle, J. E. Beauty and the Labor Market. *American Economic Review* **84**, 1174–1194 (1994).

35. Mobius, M. M. & Rosenblat, T. S. Why Beauty Matters. *American Economic Review* **96**, 222–235 (2006).

36. Thorndike, E. L. A constant error in psychological ratings. *Journal of Applied Psychology* **4**, 25–29 (1920).

37. Eagly, A. H., Ashmore, R. D., Makhijani, M. G. & Longo, L. C. What is beautiful is good, but. . . : A meta-analytic review of research on the physical attractiveness stereotype. *Psychological Bulletin* **110**, 109–128 (1991).

38. Langlois, J. H. *et al.* Maxims or myths of beauty? A meta-analytic and theoretical review. *Psychological Bulletin* **126**, 390–423 (2000).

39. Zebrowitz, L. A. *Reading Faces: Window to the Soul?* (Westview Press, Boulder, CO, 1997).

40. Zebrowitz, L. A., Hall, J. A., Murphy, N. A. & Rhodes, G. Looking smart and looking good: Facial cues to intelligence and their origins. *Personality and Social Psychology Bulletin* **28**, 238–249 (2002).

41. Bourdieu, P. The forms of capital. In Richardson, J. G. (ed.) *Handbook of Theory and Research for the Sociology of Education*, 241–258 (Greenwood, New York, 1986).

42. Hakim, C. Erotic capital. *European Sociological Review* **26**, 499–518 (2010).

43. Hakim, C. Beauty, intelligence and height: the black holes of sociology. *Sociologica* **7**, 1–40 (2013).

44. Buss, D. M. Sex differences in human mate preferences: Evolutionary hypotheses tested in 37 cultures. *Behavioral and Brain Sciences* **12**, 1–14 (1989).

45. Kanazawa, S. & Kovar, J. L. Why beautiful people are more intelligent. *Intelligence* **32**, 227–243 (2004).

46. Kanazawa, S. Intelligence and physical attractiveness. *Intelligence* **39**, 7–14 (2011).

47. Mathews, C. A. & Reus, V. I. Assortative mating in the affective disorders: A systematic review and meta-analysis. *Comprehensive Psychiatry* **42**, 257–262 (2001).

48. Plomin, R. & von Stumm, S. The new genetics of intelligence. *Nature Reviews Genetics* **19**, 148–159 (2018).

49. Mitchem, D. G. *et al.* No relationship between intelligence and facial attractiveness in a large, genetically informative sample. *Evolution and Human Behavior* **36**, 240–247 (2015).

50. Deryugina, T. & Shurchkov, O. Does Beauty Matter In Undergraduate Education? *Economic Inquiry* **53**, 940–961 (2015).

51. Romi, T. Beauty effect on economy: A truth hidden in our subconscious. SSRN Working Paper 5032346 (2024).

52. Brodeur, A., Carrell, S., Figlio, D. & Lusher, L. Unpacking p-hacking and publication bias. *American Economic Review* **113**, 2974–3002 (2023).

53. Duval, S. & Tweedie, R. Trim and fill: A simple funnel-plot–based method of testing and adjusting for publication bias in meta-analysis. *Biometrics* **56**, 455–463 (2000).

54. Stanley, T. & Doucouliagos, H. Picture This: A Simple Graph That Reveals Much Ado About Research. *Journal of Economic Surveys* **24**, 170–191 (2010).

55. Andrews, I. & Kasy, M. Identification of and correction for publication bias. *American Economic Review* **109**, 2766–2794 (2019).

56. Stanley, T. D. & Doucouliagos, H. Meta-regression approximations to reduce publication selection bias. *Research Synthesis Methods* **5**, 60–78 (2014).

57. Havranek, T., Irsova, Z., Laslopova, L. & Zeynalova, O. Publication and Attenuation Biases in Measuring Skill Substitution. *The Review of Economics and Statistics* **106**, 1187–1200 (2024).

58. Mulder, J. & van Aert, R. C. M. Bayes factor hypothesis testing in meta-analyses: Practical advantages and methodological considerations (2025). Research Synthesis Methods, forthcoming.

59. Card, D. & Krueger, A. B. Time-series minimum-wage studies: A meta-analysis. *American Economic Review* **85**, 238–243 (1995).

60. Egger, M., Smith, G. D., Schneider, M. & Minder, C. Bias in meta-analysis detected by a simple, graphical test. *BMJ* **315**, 629–634 (1997).

61. Stanley, T. D. Meta-Regression Methods for Detecting and Estimating Empirical Effects in the Presence of Publication Selection. *Oxford Bulletin of Economics and Statistics* **70**, 103–127 (2008).

62. Andrews, I., Stock, J. H. & Sun, L. Weak Instruments in Instrumental Variables Regression: Theory and Practice. *Annual Review of Economics* **11**, 727–753 (2019).

63. Kranz, S. & Putz, P. Methods Matter: p-Hacking and Publication Bias in Causal Analysis in Economics: Comment. *American Economic Review* **112**, 3124–3136 (2022).

64. Bartos, F. & Schimmack, U. Z-curve plot: A visual diagnostic for publication bias in meta-analysis. Preprint arXiv:2509.07171, arXiv, arXiv.org (2025).

65. Feldkircher, M. & Zeugner, S. Benchmark priors revisited: On adaptive shrinkage and the supermodel effect in Bayesian Model Averaging. IMF Working Papers 09/202/2009, International Monetary Fund, USA: Washington DC (2009).

66. Havranek, T. *et al.* Reporting Guidelines for Meta-Analysis in Economics. *Journal of Economic Surveys* **34**, 469–475 (2020).

67. Ahmed, S., Ranta, M., Vahamaa, E. & Vahamaa, S. Facial attractiveness and CEO compensation: Evidence from the banking industry. *Journal of Economics and Business* **123**, 106095 (2023).

68. Liu, X. Three Essays on Labor Economics. Physical Attractiveness and Earnings: Evidence from a Longitudinal Survey. Dissertation chapter 1, Department of Economics, The University of Arizona, pp. 16–51, Arizona: Tucson (2015).

69. Ahn, S. C. & Lee, Y. H. Beauty And Productivity: The Case Of The Ladies Professional Golf Association. *Contemporary Economic Policy* **32**, 155–168 (2014).

70. Halford, J. & Hsu, H.-C. CEO attractiveness and firm value. *The Financial Review* **55**, 529–556 (2020).

71. Liu, Y., Lu, H. & Veenstra, K. Beauty and Accounting Academic Career. *Journal of Accounting, Auditing & Finance* **39**, 1121–1138 (2024).

72. Anyzova, P. & Mateju, P. Beauty still matters: The role of attractiveness in labour market outcomes. *International Sociology* **33**, 269–291 (2018).

73. Malik, N., Singh, P. & Srinivasan, K. When Does Beauty Pay? A Large-Scale Image Based Appearance Analysis on Career Transitions. *Information Systems Research* **35**, 1507–2085 (2024).

74. Arunachalam, R. & Shah, M. The Prostitute's Allure: The Return to Beauty in Commercial Sex Work. *The B.E. Journal of Economic Analysis & Policy* **12**, 1–27 (2012).

75. Hamermesh, D. S. & Parker, A. Beauty in the classroom: Instructors' pulchritude and putative pedagogical productivity. *Economics of Education Review* **24**, 369–376 (2005).

76. Bakkenbull, L.-B. & Kiefer, S. Are Attractive Female Tennis Players More Successful? An Empirical Analysis. *Kyklos* **68**, 443–458 (2015).

77. Hamermesh, D. S. & Leigh, A. K. "Beauty too rich for use": Billionaires' assets and attractiveness. *Labour Economics* **76**, 102153 (2022).

78. Mocan, N. & Tekin, E. Ugly Criminals. *The Review of Economics and Statistics* **92**, 15–30 (2010).

79. Bakkenbull, L.-B. The Impact of Attractiveness on Athletic Performance of Tennis Players. *International Journal of Social Science Studies* **5**, 12–20 (2017).

80. Hamermesh, D. S., Meng, X. & Zhang, J. Dress for success–does primping pay? *Labour Economics* **9**, 361–373 (2002).

81. Monk, E., Esposito, M. & Lee, H. Beholding Inequality: Race, Gender, and Returns to Physical Attractiveness in the United States. *American Journal of Sociology* **127**, 194–241 (2021).

82. Berggren, N., Jordahl, H. & Poutvaara, P. The looks of a winner: Beauty and electoral success. *Journal of Public Economics* **94**, 8–15 (2010).

83. Oreffice, S. & Quintana-Domeque, C. Beauty, body size and wages: Evidence from a unique data set. *Economics & Human Biology* **22**, 24–34 (2016).

84. Berri, D. J., Simmons, R., Van Gilder, J. & O'Neill, L. What does it mean to find the face of the franchise? Physical attractiveness and the evaluation of athletic performance. *Economics Letters* **111**, 200–202 (2011).

85. Parrett, M. Beauty and the feast: Examining the effect of beauty on earnings using restaurant tipping data. *Journal of Economic Psychology* **49**, 34–46 (2015).

86. Bi, W., Chan, H. & Torgler, B. "Beauty" premium for social scientists but "unattractiveness" premium for natural scientists in the public speaking market. *Humanities and Social Sciences Communications* **7**, 1–9 (2020).

87. Hernandez-Julian, R. & Peters, C. Student Appearance and Academic Performance. *Journal of Human Capital* **11**, 247–262 (2017).

88. Peng, L., Wang, X. & Ying, S. The heterogeneity of beauty premium in China: Evidence from CFPS. *Economic Modelling* **90**, 386–396 (2020).

89. Biddle, J. E. & Hamermesh, D. S. Beauty, Productivity, and Discrimination: Lawyers' Looks and Lucre. *Journal of Labor Economics* **16**, 172–201 (1998).

90. Hitsch, G., Hortacsu, A. & Ariely, D. What makes you click? Mate preferences in online dating. *Quantitative Marketing and Economics* **8**, 393–427 (2010).

91. Pfeifer, C. Physical attractiveness, employment and earnings. *Applied Economics Letters* **19**, 505–510 (2012).

92. Borland, J. & Leigh, A. Unpacking the Beauty Premium: What Channels Does It Operate Through, and Has It Changed Over Time? *The Economic Record* **90**, 17–32 (2014).

93. Islam, A. & Smyth, R. The Economic Returns to Good Looks and Risky Sex in the Bangladesh Commercial Sex Market. *The B.E. Journal of Economic Analysis & Policy* **12**, 1–25 (2012).

94. Ponzo, M. & Scoppa, V. Professors' Beauty, Ability, and Teaching Evaluations in Italy. *The B.E. Journal of Economic Analysis & Policy* **13**, 811–835 (2013).

95. Cipriani, G. P. & Zago, A. Productivity or Discrimination? Beauty and the Exams. *Oxford Bulletin of Economics and Statistics* **73**, 428–447 (2011).

96. Jobu Babin, J., Hussey, A., Nikolsko-Rzhevskyy, A. & Taylor, D. A. Beauty Premiums Among Academics. *Economics of Education Review* **78**, 102019 (2020).

97. Ravina, E. Love & Loans: The Effect of Beauty and Personal Characteristics in Credit Markets. working paper, (previous versions of the working paper from 2008, New York University), Northwestern University, United States (2019).

98. Clark, C. & Walker, D. Does adolescent attractiveness matter? Academic performance, college attendance, and criminal & delinquent behavior. *Southern Business and Economic Journal* **32**, 57–78 (2009).

99. Kanazawa, S. & Still, M. Is There Really a Beauty Premium or an Ugliness Penalty on Earnings? *Journal of Business and Psychology* **33**, 249–262 (2018).

100. Ross, J. & Ferris, K. R. Interpersonal Attraction and Organizational Outcomes: A Field Examination. *Administrative Science Quarterly* **26**, 617–632 (1981).

101. Cook, D. O. & Mobbs, S. CEO Selection and Executive Appearance. *Journal of Financial and Quantitative Analysis* **58**, 1582–1611 (2023).

102. King, A. & Leigh, A. Beautiful Politicians. *Kyklos* **62**, 579–593 (2009).

103. Sachsida, A., Dornelles, A. C. & Mesquita, C. W. Beauty and the Labor Market – Study one Specific Occupation. Working paper, Mestrado em Economia de Empresas, Catholic University of Brasília, Brazil: Brasilia (2003).

104. Klein, M. & Rosar, U. Physische Attraktivitat und Wahlerfolg: Eine Empirische Analyse am Beispiel der Wahlkreiskandidaten bei der Bundestagswahl 2002. *Politische Vierteljahresheft* **46**, 266–290 (2005).

105. Salter, S. P., Mixon, F. G. & King, E. W. Broker beauty and boon: a study of physical attractiveness and its effect on real estate brokers' income and productivity. *Applied Financial Economics* **22**, 811–825 (2012).

106. Dietl, H., Ozdemir, A. & Rendall, A. The role of facial attractiveness in tennis TV-viewership. *Sport Management Review* **23**, 521–535 (2020).

107. Kraft, P. The role of beauty in the labor market: The signaling effect of beauty. Dissertation chapter 2, Center for Economic Research and Graduate Education–Economics Institute (CERGE-EI), Czech Republic: Prague (2012a).

108. Schnusenberg, O. & Froehlich, C. Hot and easy in Florida: The case of economics professors. *Research in Higher Education Journal* **10**, 10628 (2011).

109. Dilmaghani, M. Beauty perks: Physical appearance, earnings, and fringe benefits. *Economics and Human Biology* **38**, 100889 (2020).

110. Kraft, P. The role of beauty in the labor market: Attractive compensation, or compensation for being attractive? Evidence from German CEOs. Dissertation chapter 3, Center for Economic Research and Graduate Education–Economics Institute (CERGE-EI), Prague, Czech Republic (2012b).

111. Dossinger, K., Wanberg, C., Choi, Y. & Leslie, L. The beauty premium: The role of organizational sponsorship in the relationship between physical attractiveness and early career salaries. *Journal of Vocational Behavior* **112**, 109–121 (2019).

112. Lahdevuori, S. *CEO appearance, compensation, and firm performance - Evidence from Sweden.* Master thesis, School of Business, Aalto University, Finland: Espoo (2013).

113. Sen, A., Voia, M. & Woolley, F. Hot or Not: How appearance affects earnings and productivity in academia. Carleton Economic Papers 10-07, Carleton University, Canada: Ottawa (2010).

114. Edlund, L., Engelberg, J. & Parsons, C. The wages of sin. Discussion paper 0809-16, Department of Economics, Columbia University, USA: New York (2009).

115. Lee, S. & Ryu, K. Plastic Surgery: Investment in Human Capital or Consumption? *Journal of Human Capital* **6**, 224–250 (2012).

116. Fidrmuc, J. & Paphawasit, B. Beautiful minds: Physical attractiveness and research productivity in economics. Conference paper, IZA Institute of Labor Economics, Russia: Moscow (2018).

117. Leigh, A. & Susilo, T. Is voting skin-deep? Estimating the effect of candidate ballot photographs on election outcomes. *Journal of Economic Psychology* **30**, 61–70 (2009).

118. Tao, H.-L. Attractive Physical Appearance vs. Good Academic Characteristics: Which Generates More Earnings? *Kyklos* **61**, 114–133 (2008).

119. Fletcher, J. M. Beauty vs. brains: Early labor market outcomes of high school graduates. *Economics Letters* **105**, 321–325 (2009).

120. Li, C., Lin, A.-P., Lu, H. & Veenstra, K. J. Gender and beauty in the financial analyst profession: Evidence from the United States and China. *Review of Accounting Studies* **25**, 1230–1262 (2020).

121. Walcutt, B., Patterson, L. & Seo, S. Beauty Premium and Grade Point Average: A Study of Business Students at a Korean University. *Business Studies Journal* **3**, 51–68 (2011).

122. French, M. T., Robins, P. K., Homer, J. F. & Tapsell, L. M. Effects of physical attractiveness, personality, and grooming on academic performance in high school. *Labour Economics* **16**, 373–382 (2009).

123. Li, M., Triana, M., Byun, S. & Chapa, O. Pay for beauty? A contingent perspective of CEO facial attractiveness on CEO compensation. *Human Resource Management* **60**, 843–862 (2021).

124. Wolbring, T. & Riordan, P. How beauty works. Theoretical mechanisms and two empirical applications on students' evaluation of teaching. *Social Science Research* **57**, 253–272 (2016).

125. Gertler, P., Shah, M. & Bertozzi, S. M. Risky Business: The Market for Unprotected Commercial Sex. *Journal of Political Economy* **113**, 518–550 (2005).

126. Gerber, A. & Malhotra, N. Do Statistical Reporting Standards Affect What Is Published? Publication Bias in Two Leading Political Science Journals. *Quarterly Journal of Political Science* **3**, 313–326 (2008).

127. Bom, P. R. D. & Rachinger, H. A kinked meta-regression model for publication bias correction. *Research Synthesis Methods* **10**, 497–514 (2019).

128. Furukawa, C. Publication bias under aggregation frictions: Theory, evidence, and a new correction method. Working paper, Massachusetts Institute of Technology, USA: Cambridge, MA (2020).

129. Roodman, D., MacKinnon, J. G., Nielsen, M. O. & Webb, M. D. Fast and wild: Bootstrap inference in Stata using boottest. Queen's Economics Department Working Paper 1406, Department of Economics, Queen's University, Canada: Kingston (2018).

## Supplementary Information (for Online Publication)

FIGURE S1. PRISMA flow diagram.
Notes: Preferred reporting items for systematic reviews and meta-analyses (PRISMA) is an evidence-based set of items for reporting in systematic reviews and meta-analyses. More details on PRISMA and reporting standards in the context of economics meta-analyses are provided by Havranek et al.^{66}. Snowballing: we download the references of the potentially eligible studies identified in step "Screening" and inspect the 100 studies most commonly cited among the 185 studies. If, based on the abstract, these commonly cited studies show any promise of containing empirical estimates of the beauty effect, we add them to the set of potentially eligible studies. Snowballing yields 31 additional studies. Criteria for inclusion: i) the study must report the effect of beauty on a continuous variable reflecting earnings or productivity; ii) the beauty measurement used in the study must focus on physiognomy (just the face); iii) the study must focus on the subject's own earnings or productivity (e.g. not the income of the spouse, firm valuation, or college rank); iv) the study must report statistics that allow us to convert the reported estimate to the percent increase in earnings or productivity following a one-standard-deviation increase in beauty (e.g. studies reporting zero-order correlations or lacking the standard deviation of the beauty measure cannot be converted); v) the study must report standard errors or other statistics from which standard errors can be computed; and vi) the study must not be a laboratory experiment or a survey. Based on these criteria, we excluded 69 studies: 8 for lacking a continuous earnings or productivity variable, 7 for using a beauty measure not based on physiognomy, 12 for not focusing on the subject's own earnings or productivity, 19 for not reporting convertible statistics (often just correlation coefficients), 9 for missing standard errors, and 14 because they were laboratory experiments or surveys. The literature search was terminated on February 16, 2024. The dataset, together with R and Stata codes and reasons for exclusion of the 69 above-mentioned individual studies, is available at meta-analysis.cz/beauty.

TABLE S1. The 67 studies included in the meta-analysis

|  |  |  |

| --- | --- | --- |

| Ahmed et al.^{67} | Gu & Ji^{33} | Liu^{68} |

| Ahn & Lee^{69} | Halford & Hsu^{70} | Liu et al.^{71} |

| Anyzova & Mateju^{72} | Hamermesh & Biddle^{34} | Malik et al.^{73} |

| Arunachalam & Shah^{74} | Hamermesh & Parker^{75} | Mehic^{24} |

| Bakkenbull & Kiefer^{76} | Hamermesh & Leigh^{77} | Mocan & Tekin^{78} |

| Bakkenbull^{79} | Hamermesh et al.^{80} | Monk et al.^{81} |

| Berggren et al.^{82} | Hamermesh & Crosnoe^{32} | Oreffice & Quintana-Domeque^{83} |

| Berri et al.^{84} | Harper^{30} | Parrett^{85} |

| Bi et al.^{86} | Hernandez-Julian & Peters^{87} | Peng et al.^{88} |

| Biddle & Hamermesh^{89} | Hitsch et al.^{90} | Pfeifer^{91} |

| Borland & Leigh^{92} | Islam & Smyth^{93} | Ponzo & Scoppa^{94} |

| Cipriani & Zago^{95} | Jobu Babin et al.^{96} | Ravina^{97} |

| Clark & Walker^{98} | Kanazawa & Still^{99} | Ross & Ferris^{100} |

| Cook & Mobbs^{101} | King & Leigh^{102} | Sachsida et al.^{103} |

| Deryugina & Shurchkov^{50} | Klein & Rosar^{104} | Salter et al.^{105} |

| Dietl et al.^{106} | Kraft^{107} | Schnusenberg & Froehlich^{108} |

| Dilmaghani^{109} | Kraft^{110} | Scholz & Sicinski^{31} |

| Dossinger et al.^{111} | Lahdevuori^{112} | Sen et al.^{113} |

| Edlund et al.^{114} | Lee & Ryu^{115} | Stinebrickner et al.^{3} |

| Fidrmuc & Paphawasit^{116} | Leigh & Susilo^{117} | Tao^{118} |

| Fletcher^{119} | Li et al.^{120} | Walcutt et al.^{121} |

| French et al.^{122} | Li et al.^{123} | Wolbring & Riordan^{124} |

| Gertler et al.^{125} |  |  |
Notes: Details on the literature search and criteria for inclusion are available in Figure S1. The last study was added on February 16, 2024.

FIGURE S2. Estimates vary both within and across studies.
Notes: The figure shows a box plot of the estimated beauty effects. Studies are sorted by data age from oldest to newest. All estimates are recomputed to represent the percent increase in earnings or productivity associated with a one-standard-deviation increase in beauty. The length of each box represents the interquartile range (P25–P75), and the dividing line inside the box represents the median. The whiskers represent the highest and lowest data points within 1.5 times the range between the upper and lower quartiles. The mean overall reported effect is denoted as a solid vertical line. For ease of exposition, extreme outliers are excluded from the figure but included in all statistical tests.

TABLE S2. Beauty premiums reported in different contexts

|  | Est. | Stud. | Unweighted Mean | Unweighted 95% conf. int. |  | Weighted Mean | Weighted 95% conf. int. |  |

| --- | --- | --- | --- | --- | --- | --- | --- | --- |

| *Measurement of beauty* |  |  |  |  |  |  |  |  |

| Interviewer-rated beauty | 526 | 24 | 4.33 | 3.80 | 4.86 | 5.87 | 5.31 | 6.42 |

| Photo-rated beauty | 481 | 37 | 4.28 | 3.71 | 4.85 | 4.82 | 4.16 | 5.47 |

| Software-rated beauty | 104 | 8 | 5.49 | 4.15 | 6.83 | 7.43 | 6.04 | 8.82 |

| Self-rated beauty | 56 | 6 | 2.04 | 0.79 | 3.29 | 2.79 | 1.32 | 4.27 |

| Dummy beauty | 460 | 23 | 3.63 | 3.05 | 4.22 | 5.02 | 4.39 | 5.65 |

| Categorical beauty | 699 | 52 | 4.70 | 4.24 | 5.16 | 5.29 | 4.76 | 5.81 |

| Beauty premium | 954 | 67 | 4.48 | 4.07 | 4.89 | 5.45 | 5.00 | 5.91 |

| Beauty penalty | 205 | 16 | 3.33 | 2.56 | 4.10 | 3.10 | 2.38 | 3.82 |

| *Measurement of success* |  |  |  |  |  |  |  |  |

| Earnings | 688 | 43 | 4.33 | 3.92 | 4.75 | 6.15 | 5.65 | 6.66 |

| Non-earnings outcomes | 471 | 29 | 4.20 | 3.55 | 4.85 | 3.74 | 3.10 | 4.38 |

| Study outcomes | 189 | 9 | 3.19 | 1.98 | 4.41 | 3.78 | 2.54 | 5.02 |

| Teaching & research outcomes | 139 | 8 | 4.95 | 4.05 | 5.85 | 3.38 | 2.36 | 4.40 |

| Athletic success | 33 | 2 | 6.28 | 3.03 | 9.54 | 5.36 | 2.27 | 8.46 |

| Electoral success | 37 | 4 | 7.00 | 4.26 | 9.75 | 5.67 | 3.09 | 8.24 |

| Other outcomes | 73 | 6 | 2.98 | 2.24 | 3.73 | 2.19 | 1.42 | 2.95 |

| *Data characteristics* |  |  |  |  |  |  |  |  |

| Male subjects | 375 | 44 | 3.66 | 3.10 | 4.22 | 4.28 | 3.69 | 4.87 |

| Female subjects | 447 | 48 | 4.10 | 3.45 | 4.75 | 6.28 | 5.52 | 7.04 |

| Mixed gender | 337 | 36 | 5.21 | 4.57 | 5.85 | 4.86 | 4.18 | 5.54 |

| High-skilled workers | 335 | 27 | 4.30 | 3.78 | 4.81 | 4.00 | 3.42 | 4.58 |

| Western culture | 874 | 47 | 3.85 | 3.46 | 4.23 | 4.62 | 4.22 | 5.02 |

| Other cultures | 285 | 21 | 5.60 | 4.72 | 6.48 | 6.55 | 5.54 | 7.56 |

| Panel data | 998 | 55 | 3.86 | 3.47 | 4.25 | 4.82 | 4.38 | 5.25 |

| Cross-section | 161 | 13 | 6.87 | 5.90 | 7.83 | 6.87 | 5.87 | 7.88 |

| *Industry* |  |  |  |  |  |  |  |  |

| Customer services | 57 | 7 | 2.74 | 1.29 | 4.18 | 2.81 | 1.42 | 4.21 |

| Financial services | 34 | 6 | 4.58 | 2.51 | 6.65 | 4.18 | 1.99 | 6.37 |

| Legal services | 31 | 1 | 2.86 | 2.06 | 3.66 | 2.86 | 2.06 | 3.66 |

| Political office | 37 | 4 | 7.00 | 4.26 | 9.75 | 5.67 | 3.09 | 8.24 |

| Professional sports | 56 | 5 | 8.70 | 5.86 | 11.54 | 12.43 | 9.41 | 15.45 |

| Scientific research | 42 | 3 | 7.96 | 5.81 | 10.11 | 6.77 | 4.48 | 9.06 |

| Sex industry | 55 | 4 | 8.55 | 7.27 | 9.82 | 9.54 | 8.45 | 10.64 |

| *Occupation* |  |  |  |  |  |  |  |  |

| General population | 435 | 23 | 4.20 | 3.77 | 4.63 | 5.39 | 4.91 | 5.87 |

| Athletes | 56 | 5 | 8.70 | 5.86 | 11.54 | 12.43 | 9.41 | 15.45 |

| Executives | 56 | 10 | 5.98 | 4.52 | 7.43 | 6.46 | 4.94 | 7.98 |

| Lawyers | 31 | 1 | 2.86 | 2.06 | 3.66 | 2.86 | 2.06 | 3.66 |

| Politicians | 37 | 4 | 7.00 | 4.26 | 9.75 | 5.67 | 3.09 | 8.24 |

| Prostitutes | 55 | 4 | 8.55 | 7.27 | 9.82 | 9.54 | 8.45 | 10.64 |

| Salespeople | 32 | 5 | 2.11 | -0.21 | 4.44 | 2.55 | 0.44 | 4.67 |

| Scientists | 42 | 3 | 7.96 | 5.81 | 10.11 | 6.77 | 4.48 | 9.06 |

| Students | 233 | 9 | 2.54 | 1.55 | 3.53 | 3.07 | 2.01 | 4.14 |

| Teachers | 109 | 8 | 3.34 | 2.60 | 4.09 | 1.88 | 0.98 | 2.78 |

| *Degree of customer contact* |  |  |  |  |  |  |  |  |

| No customer contact | 318 | 23 | 3.64 | 2.79 | 4.49 | 4.14 | 3.34 | 4.94 |

| Some customer contact | 401 | 19 | 3.87 | 3.47 | 4.27 | 4.97 | 4.51 | 5.43 |

| Direct customer contact | 440 | 32 | 5.11 | 4.49 | 5.74 | 6.05 | 5.32 | 6.78 |

TABLE S2 (continued). Beauty premiums reported in different contexts

|  | Est. | Stud. | Unweighted Mean | Unweighted 95% conf. int. |  | Weighted Mean | Weighted 95% conf. int. |  |

| --- | --- | --- | --- | --- | --- | --- | --- | --- |

| *Measurability of output* |  |  |  |  |  |  |  |  |

| Low output measurability | 135 | 6 | 3.32 | 2.66 | 3.97 | 3.15 | 2.44 | 3.87 |

| Mid output measurability | 274 | 16 | 4.06 | 3.36 | 4.76 | 6.16 | 5.51 | 6.81 |

| High output measurability | 750 | 51 | 4.53 | 4.05 | 5.01 | 5.21 | 4.67 | 5.75 |

| *Intensity of interpersonal interaction* |  |  |  |  |  |  |  |  |

| Low interpersonal intensity | 180 | 17 | 5.11 | 3.92 | 6.29 | 6.16 | 4.99 | 7.32 |

| Mid interpersonal intensity | 519 | 30 | 3.96 | 3.46 | 4.45 | 4.64 | 4.00 | 5.29 |

| High interpersonal intensity | 460 | 33 | 4.31 | 3.76 | 4.87 | 5.29 | 4.74 | 5.84 |

| *Cognitive and non-cognitive skill controls* |  |  |  |  |  |  |  |  |

| No skill control | 617 | 48 | 4.99 | 4.52 | 5.45 | 6.02 | 5.47 | 6.58 |

| Cognitive skill control only | 298 | 16 | 2.44 | 1.67 | 3.21 | 2.45 | 1.66 | 3.24 |

| Non-cognitive skill control only | 97 | 10 | 6.70 | 5.38 | 8.03 | 5.37 | 4.13 | 6.62 |

| Both skill controls | 147 | 15 | 3.43 | 2.52 | 4.34 | 4.89 | 3.82 | 5.96 |

| *Objectively measured cognitive skill control* |  |  |  |  |  |  |  |  |

| Objective cognitive skill control only | 256 | 12 | 2.47 | 1.60 | 3.34 | 2.73 | 1.87 | 3.59 |

| Objective cog. and non-cog. control | 127 | 10 | 2.98 | 2.23 | 3.72 | 5.21 | 4.39 | 6.03 |

| Objective cog. control or DID method | 395 | 21 | 2.59 | 1.98 | 3.20 | 3.66 | 3.05 | 4.26 |

| *Estimation technique* |  |  |  |  |  |  |  |  |

| Ordinary least squares | 903 | 60 | 4.17 | 3.77 | 4.56 | 5.19 | 4.75 | 5.64 |

| Instrumental variables | 83 | 10 | 4.86 | 3.07 | 6.64 | 6.60 | 4.70 | 8.50 |

| Difference-in-differences | 12 | 2 | 1.24 | 0.63 | 1.84 | 1.13 | 0.55 | 1.71 |

| Other method | 161 | 13 | 4.84 | 3.78 | 5.90 | 4.91 | 3.82 | 6.00 |

| *Publication characteristics* |  |  |  |  |  |  |  |  |

| Published study | 1,027 | 58 | 4.19 | 3.80 | 4.57 | 5.23 | 4.79 | 5.67 |

| Unpublished study | 132 | 9 | 4.99 | 3.96 | 6.03 | 5.06 | 4.11 | 6.02 |

| All estimates | 1,159 | 67 | 4.28 | 3.92 | 4.64 | 5.21 | 4.81 | 5.61 |
Notes: The table reports summary statistics of the estimated beauty effect for subsets of the literature. All estimates are recomputed to represent the percent increase in earnings or productivity associated with a one-standard-deviation increase in beauty. Est. = estimates. Stud. = studies. In the left-hand panel (unweighted) simple means and the corresponding 95% confidence intervals are reported; each estimate is assigned the same weight. In the right-hand panel (weighted) estimates are weighted by the inverse of the number of estimates reported per study, thus giving each study the same weight. Details on the definition of subsamples are available in Table S10 and Table S18.

TABLE S3. Bias-corrected and fully adjusted beauty premiums by subgroup

|  | Obs. | Clust. | RoBMA Mean | RoBMA 95% cred. int. |  | RoBMA 3lvl Mean | RoBMA 3lvl 95% cred. int. |  |

| --- | --- | --- | --- | --- | --- | --- | --- | --- |

| *Industry* |  |  |  |  |  |  |  |  |

| Customer services | 57 | 7 | -1.97 | -3.96 | 1.32 | -0.45 | -4.06 | 1.04 |

| Financial services | 34 | 6 | -1.65 | -3.51 | 1.57 | 0.25 | -1.17 | 3.01 |

| Legal services | 31 | 1 | 1.15 | -0.18 | 2.22 | -0.03 | -3.82 | 3.36 |

| Political office | 37 | 4 | 0.11 | -1.60 | 2.84 | 0.01 | -4.58 | 3.62 |

| Professional sports | 56 | 5 | -1.03 | -4.10 | 2.37 | 0.76 | -0.22 | 6.65 |

| Scientific research | 42 | 3 | 5.73 | 3.33 | 11.0 | -0.26 | -4.31 | 1.83 |

| Sex industry | 55 | 4 | 1.16 | -6.60 | 7.62 | 0.44 | -3.08 | 6.08 |

| *Occupation* |  |  |  |  |  |  |  |  |

| General population | 435 | 23 | -0.36 | -1.53 | 0.05 | 1.31 | 0.00 | 3.44 |

| Executives | 56 | 10 | -0.16 | -1.53 | 2.35 | 1.29 | 0.00 | 3.77 |

| Salespeople | 32 | 5 | -0.68 | -3.86 | 0.00 | 0.97 | -0.62 | 2.83 |

| Students | 233 | 9 | -0.54 | -2.25 | 0.00 | 0.81 | -1.05 | 2.69 |

| Teachers | 109 | 8 | -0.35 | -1.53 | 0.31 | 0.58 | -2.78 | 2.69 |

| *Gender* |  |  |  |  |  |  |  |  |

| Female | 447 | 48 | -0.47 | -0.83 | 0.00 | 1.25 | -0.44 | 2.98 |

| Male | 375 | 44 | 0.46 | 0.00 | 0.81 | 1.58 | 0.00 | 3.36 |

| *Degree of customer contact* |  |  |  |  |  |  |  |  |

| No customer contact | 318 | 23 | -0.20 | -1.29 | 0.00 | -0.61 | -2.35 | 1.66 |

| Some customer contact | 401 | 19 | -0.19 | -1.29 | 0.00 | 0.86 | -0.31 | 3.19 |

| Direct customer contact | 440 | 32 | -0.19 | -1.29 | 0.00 | 1.25 | 0.00 | 3.50 |

| *Measurability of output/performance* |  |  |  |  |  |  |  |  |

| Low output measurability | 135 | 6 | -0.17 | -1.30 | 0.62 | 0.53 | 0.00 | 2.28 |

| Mid output measurability | 274 | 16 | -0.26 | -1.41 | 0.00 | 0.53 | 0.00 | 2.29 |

| High output measurability | 750 | 51 | -0.21 | -1.30 | 0.03 | 0.53 | 0.00 | 2.28 |

| *Intensity of interpersonal interaction* |  |  |  |  |  |  |  |  |

| Low interpersonal intensity | 180 | 17 | 0.01 | -1.22 | 1.17 | 0.31 | 0.00 | 2.10 |

| Mid interpersonal intensity | 519 | 30 | -0.25 | -1.24 | 0.00 | 0.32 | 0.00 | 2.11 |

| High interpersonal intensity | 460 | 33 | -0.22 | -1.23 | 0.00 | 0.33 | 0.00 | 2.12 |

| *Cognitive and non-cognitive skill controls* |  |  |  |  |  |  |  |  |

| No skill control | 617 | 48 | 1.24 | 0.61 | 2.09 | 3.16 | 1.98 | 4.33 |

| Cognitive skill control only | 298 | 16 | -1.70 | -2.48 | -0.64 | 1.63 | 0.13 | 3.36 |

| Non-cognitive skill control only | 97 | 10 | 2.43 | 1.26 | 4.00 | 3.61 | 1.93 | 5.44 |

| Both skill controls | 147 | 15 | -0.70 | -1.66 | 0.64 | 1.83 | 0.14 | 3.44 |

| *Objectively measured cognitive skill control* |  |  |  |  |  |  |  |  |

| Objective cognitive skill control only | 256 | 12 | 0.00 | -0.70 | 1.05 | 0.63 | 0.00 | 2.33 |

| Objective cog. and non-cog. control | 127 | 10 | 0.44 | 0.00 | 1.86 | 0.64 | 0.00 | 2.36 |

| Objective cog. control or DID method | 395 | 21 | 0.06 | 0.00 | 0.89 | 0.46 | 0.00 | 2.00 |

| *Output type* |  |  |  |  |  |  |  |  |

| Earnings | 471 | 29 | -0.22 | -1.31 | 0.00 | 0.38 | -0.37 | 2.18 |

| Non-earnings outcomes | 688 | 43 | -0.22 | -1.31 | 0.00 | 0.43 | 0.00 | 2.19 |
Notes: The table reports implied beauty premiums conditional on three adjustments: (i) correction for publication bias, (ii) inclusion of cognitive-ability controls or use of difference-in-differences estimation, and (iii) exclusion of occupations involving sex work. The second adjustment is not applied to "No skill control" and "Non-cognitive skill control only" subgroups. The third adjustment is not applied to the sex industry subgroup. Occupations that fully overlap with industries (e.g., all estimates in the subgroup "Legal services" correspond to lawyers) are omitted from the Occupation group. RoBMA denotes Robust Bayesian Meta-Analysis, while the specification on the right-hand side applies the three-level RoBMA (RoBMA 3lvl), which accounts for the dependence among multiple estimates reported within the same study^{16–19}. Each *subgroup model* uses only estimates for that dimension (e.g., industry-specific effects) and includes dummies for the *categories*. If RoBMA detects little systematic heterogeneity, category means may look similar. These subgroup means need not average to the overall mean, which is based on all effects, including non-subgrouped estimates. DID = difference-in-differences. *Est.* indicates the number of estimates included in the analysis, and *Stud.* denotes the number of studies used in the multilevel specification. *Mean* reports the posterior model-averaged mean estimate for each subgroup, and the associated 95% credible interval reflects the posterior uncertainty surrounding this estimate. Definitions of the subgroups are provided in Table S18. More details on the RoBMA exercise are available in Table S17.

TABLE S4. Specification test for the selection model

|  | All | Premium | Penalty | Prostitutes | No prostitutes |

| --- | --- | --- | --- | --- | --- |

| Correlation | 0.550 | 0.535 | 0.665 | -0.217 | 0.568 |

|  | [0.43, 0.613] | [0.402, 0.611] | [0.543, 0.725] | [-0.462, 0.043] | [0.448, 0.624] |

| Estimates | 1,159 | 954 | 205 | 55 | 1,104 |
Notes: Following Kranz and Putz^{63}, the table shows, for selected subsets of the literature, the correlation coefficient between the logarithm of the absolute value of the beauty effect and the logarithm of the corresponding standard error, weighted by the inverse publication probability estimated by the Andrews-Kasy^{55} model. If the assumptions of the model hold, the correlation is zero. Bootstrapped 95% confidence interval in parentheses.

TABLE S5. Caliper tests suggest selection for positive estimates

|  | t-statistic = 0 | t-statistic = 1.96 | t-statistic = 2.58 |

| --- | --- | --- | --- |

| Caliper 0.05 | 0.119 | 0.176^{**} | 0.133 |

|  | (0.109) | (0.078) | (0.089) |

|  | N = 21 | N = 37 | N = 30 |

| Caliper 0.1 | 0.196^{***} | 0.074 | 0.064 |

|  | (0.069) | (0.064) | (0.067) |

|  | N = 46 | N = 61 | N = 55 |

| Caliper 0.15 | 0.222^{***} | 0.054 | 0.059 |

|  | (0.062) | (0.055) | (0.061) |

|  | N = 54 | N = 83 | N = 68 |

| Caliper 0.2 | 0.205^{***} | 0.019 | 0.024 |

|  | (0.052) | (0.049) | (0.055) |

|  | N = 78 | N = 106 | N = 82 |

| Caliper 0.25 | 0.173^{***} | 0.04 | 0 |

|  | (0.048) | (0.043) | (0.05) |

|  | N = 98 | N = 137 | N = 102 |
Notes: The table reports results for caliper tests^{126}. The tests compare the relative frequency of estimates above and below an important threshold for the t-statistic; the rows show results for different caliper widths. A test statistic of 0.176, for example, means that 67.6% estimates are just above the threshold and 32.4% estimates are just below the threshold. N = number of estimates. Standard errors are reported in parentheses and clustered at the study level. ^{*} p < 0.10, ^{**} p < 0.05, ^{***} p < 0.01.

TABLE S6. Linear and nonlinear techniques detect publication bias

| **Part 1. Clustered at the study level** |  |  |  |  |  |

| --- | --- | --- | --- | --- | --- |

| **Panel A** | OLS | FE | BE | MAIVE | Weighted |

| Publication bias | 0.377^{***} | 0.208^{*} | 0.732^{***} | 0.447 | 0.656^{**} |

| (*standard error*) | (0.118) | (0.119) | (0.164) | (0.286) | (0.272) |

|  | [0.116, 0.634] |  |  | {-0.045, 1.030} | [-0.009, 1.268] |

| Effect beyond bias | 2.865^{***} | 3.497^{***} | 2.243^{**} | 3.052^{***} | 3.424^{***} |

| (*constant*) | (0.464) | (0.446) | (0.871) | (1.133) | (1.156) |

|  | [1.916, 3.781] |  |  | {0.726, 4.995} | [0.776, 6.339] |

| Observations | 1,159 | 1,159 | 1,159 | 1,159 | 1,159 |

| **Panel B** | Precision-weighted/Kink | WAAP | Stem | RTMA | Selection |

| Publication bias | 1.720^{***} |  |  |  | P = 0.142 |

|  | (0.224) |  |  |  | (0.038) |

|  | [1.225, 2.188] |  |  |  |  |

| Effect beyond bias | 0.343 | 0.323^{**} | 0.055 | 2.210^{***} | 0.493 |

|  | (0.272) | (0.147) | (1.276) | (0.010) | (0.410) |

|  | [-0.028, 1.741] |  |  |  |  |

| Observations | 1,159 | 1,159 | 1,159 | 1,159 | 1,159 |

| **Part 2. Clustered at the database level** |  |  |  |  |  |

| **Panel A** | OLS | FE | BE | MAIVE | Weighted |

| Publication bias | 0.377^{***} | 0.208^{*} | 0.732^{***} | 0.447 | 0.656^{**} |

| (*standard error*) | (0.132) | (0.120) | (0.262) | (0.337) | (0.308) |

|  | [0.107, 0.751] |  |  | {-0.413, 1.246} | [-0.084, 1.352] |

| Effect beyond bias | 2.865^{***} | 3.497^{***} | 2.243^{**} | 3.052^{***} | 3.424^{***} |

| (*constant*) | (0.466) | (0.453) | (0.932) | (1.226) | (1.223) |

|  | [1.859, 3.779] |  |  | {-0.625, 6.987} | [0.648, 6.505] |

| Observations | 1,159 | 1,159 | 1,159 | 1,159 | 1,159 |

| **Panel B** | Precision-weighted/Kink | WAAP | Stem | RTMA | Selection |

| Publication bias | 1.720^{***} |  |  |  | P = 0.142 |

|  | (0.237) |  |  |  | (0.039) |

|  | [1.227, 2.296] |  |  |  |  |

| Effect beyond bias | 0.343 | 0.323^{**} | 0.055 | 2.210^{***} | 0.493 |

|  | (0.276) | (0.147) | (1.276) | (0.010) | (0.425) |

|  | [-0.046, 1.592] |  |  |  |  |

| Observations | 1,159 | 1,159 | 1,159 | 1,159 | 1,159 |
Notes: Panel A reports the results of regression $\hat{b}_{ij} = b_0 + \beta \cdot SE(b_{ij}) + \epsilon_{ij}$, where $\hat{b}_{ij}$ denotes the *i*-th beauty effect estimated in the *j*-th study, and $SE(b_{ij})$ denotes its standard error. FE = study-level fixed effects, BE = study-level between effects, MAIVE = Meta-Analysis Instrumental Variable Estimator^{21} with log sample size used as an instrument for log variance. Weighted = the inverse of the number of estimates per study is used as the weight. In Panel B all models are weighted by inverse variance. The first specification reports a regression similar to those from the last column of Panel A but with inverse variance weights (results identical to the kinked model^{127}). WAAP = Weighted Average of the Adequately Powered estimates^{4}; Stem = stem-based model^{128}; RTMA = Right-Truncated Meta-Analysis^{22}; Selection = selection model^{55}. P denotes the probability that estimates insignificant at the 5% level are published relative to the probability that significant estimates are published (normalized at 1). Standard errors, clustered at the study level, are reported in parentheses (WAAP, Stem, and RTMA do not allow for clustering). 95% confidence intervals from wild bootstrap^{129} are reported in square brackets. For MAIVE, in curly brackets we show the Anderson-Rubin 95% confidence interval recommended by Keane and Neal^{20}. Separate results for the subsamples of prostitutes, other occupations, beauty premiums, and beauty penalties are available in Table S8 and Table S9. ^{*} p < 0.10, ^{**} p < 0.05, ^{***} p < 0.01

TABLE S7. Publication bias tests for standardized effects, objective cognitive control

| **Part 1. Standardized effects** |  |  |  |  |  |

| --- | --- | --- | --- | --- | --- |

| **Panel A** | OLS | FE | BE | MAIVE | Weighted |

| Publication bias | 0.0239 | 0.0833 | -0.0492 | 0.330^{**} | 0.246 |

| (*standard error*) | (0.0446) | (0.0704) | (0.127) | (0.149) | (0.231) |

|  | [-0.068, 0.139] |  |  | {0.030, 0.591} | [-0.332, 0.796] |

| Effect beyond bias | 0.0730^{***} | 0.0680^{***} | 0.0878^{***} | 0.0460^{**} | 0.0827^{***} |

| (*constant*) | (0.00979) | (0.00601) | (0.0162) | (0.0200) | (0.0145) |

|  | [0.053, 0.094] |  |  | {0.007, 0.086} | [0.053, 0.112] |

| Observations | 1,000 | 1,000 | 1,000 | 1,000 | 1,000 |

| **Panel B** | Precision-weighted | WAAP | Stem | RTMA | Selection |

| Publication bias | 2.112^{***} |  |  |  | P = 0.388 |

|  | (0.342) |  |  |  | (0.112) |

|  | [1.462, 2.777] |  |  |  |  |

| Effect beyond bias | -0.0002 | 0.0004^{***} | -0.0000003 | 0.0672^{***} | 0.019^{*} |

|  | (0.0002) | (0.0001) | (0.013) | (0.0003) | (0.010) |

|  | [-0.010, 0.006] |  |  |  |  |

| Observations | 1,000 | 1,000 | 1,000 | 1,000 | 1,000 |

| **Part 2. Objective cognition control or difference-in-differences** |  |  |  |  |  |

| **Panel A** | OLS | FE | BE | MAIVE | Weighted |

| Publication bias | 0.305 | 0.166 | 0.432^{**} | 1.663^{**} | 0.508^{***} |

| (*standard error*) | (0.198) | (0.166) | (0.202) | (0.828) | (0.189) |

|  | [-0.102, 0.894] |  |  | {0.134, 3.255} | [-0.150, 0.939] |

| Effect beyond bias | 1.282^{***} | 1.879^{**} | 1.399 | -2.773 | 3.689^{***} |

| (*constant*) | (0.435) | (0.714) | (1.147) | (2.645) | (0.913) |

|  | [0.2983, 2.223] |  |  | {-8.594, 2.974} | [1.272, 5.639] |

| Observations | 395 | 395 | 395 | 395 | 395 |

| **Panel B** | Precision-weighted/Kink | WAAP | Stem | RTMA | Selection |

| Publication bias | 0.881^{***} |  |  |  | P = 0.512 |

|  | (0.215) |  |  |  | (0.119) |

|  | [0.386, 1.467] |  |  |  |  |

| Effect beyond bias | 0.100 | 0.089^{***} | 1.105 | 1.640^{***} | 0.903^{***} |

|  | (0.123) | (0.026) | (1.323) | (0.0133) | (0.257) |

|  | [-2.775, 1.996] |  |  |  |  |

| Observations | 395 | 395 | 395 | 395 | 395 |
Notes: Part 1 reports the beauty effect recomputed to represent a one-standard-deviation increase in earnings or productivity associated with a one-standard-deviation increase in beauty. Part 2 reports the beauty effect representing the percentage increase in earnings or productivity associated with a one-standard-deviation increase in beauty but is restricted to studies that control for objectively measured cognitive skills or use difference-in-differences. Panel A represents the results of the regression $\hat{b}_{ij} = b_0 + \beta \cdot SE(b_{ij}) + \epsilon_{ij}$, where $\hat{b}_{ij}$ denotes the *i*-th beauty effect estimated in the *j*-th study, and $SE(b_{ij})$ denotes its standard error. FE = study-level fixed effects, BE = study-level between effects, MAIVE = Meta-Analysis Instrumental Variable Estimator^{21}, with log sample size used as an instrument for log variance. Weighted = the inverse of the number of estimates per study is used as the weight. In Panel B, all models are weighted by inverse variance. The first specification reports a regression similar to those from the last column of Panel A but with inverse variance weights (results identical to the kinked model^{127}). WAAP = Weighted Average of Adequately Powered estimates^{4}; Stem = the stem-based model^{128}; RTMA = Right-Truncated Meta-Analysis^{22}; Selection = selection model^{55}. P denotes the probability that estimates insignificant at the 5% level are published relative to the probability that significant estimates are published (normalized at 1). Standard errors, clustered at the study level, are reported in parentheses. 95% confidence intervals from the wild bootstrap^{129} are reported in square brackets. For MAIVE, in curly brackets we show the Anderson-Rubin 95% confidence interval recommended by Keane and Neal^{20}. ^{*} p < 0.10, ^{**} p < 0.05, ^{***} p < 0.01

TABLE S8. Publication bias tests separately for beauty premiums and penalties

| **Part 1. Subsample of penalties** | | | | | |
|---|---|---|---|---|---|
| **Panel A** | OLS | FE | BE | MAIVE | Weighted |
| Publication bias | 0.165^{**} | -0.354 | 0.702^{***} | 0.029 | 0.354^{***} |
| (*standard error*) | (0.0678) | (0.235) | (0.168) | (0.833) | (0.131) |
|  | [0.021, 0.406] |  |  | {-1.557, 1.662} | [0.028, 1.395] |
| Effect beyond bias | 2.647^{***} | 4.801^{***} | 0.447 | 3.178 | 2.655^{**} |
| (*constant*) | (0.733) | (0.977) | (0.877) | (5.241) | (1.153) |
|  | [1.225, 4.378] |  |  | {-6.919, 12.824} | [0.038, 5.782] |
| Observations | 205 | 205 | 205 | 205 | 205 |
| **Panel B** | Precision-weighted/Kink | WAAP | Stem | RTMA | Selection |
| Publication bias | 1.097^{***} |  |  |  | P = 0.369 |
|  | (0.12) |  |  |  | (0.019) |
|  | [0.709, 1.489] |  |  |  |  |
| Effect beyond bias | 0.139 | 0.244^{***} | 0.245 | 2.270^{***} | 0.236^{***} |
|  | (0.097) | (0.021) | (0.323) | (0.016) | (0.067) |
|  | [-0.405, 1.425] |  |  |  |  |
| Observations | 205 | 205 | 205 | 205 | 205 |
| **Part 2. Sample without penalties** | | | | | |
| **Panel A** | OLS | FE | BE | MAIVE | Weighted |
| Publication bias | 0.437^{***} | 0.282^{*} | 0.745^{***} | 0.494^{*} | 0.666^{**} |
| (*standard error*) | (0.139) | (0.160) | (0.172) | (0.286) | (0.281) |
|  | [0.125, 0.745] |  |  | {-0.036, 1.080} | [-0.044, 1.295] |
| Effect beyond bias | 2.881^{***} | 3.448^{***} | 2.228^{**} | 3.097^{***} | 3.470^{***} |
| (*constant*) | (0.555) | (0.585) | (0.914) | (1.108) | (1.202) |
|  | [1.745, 4.058] |  |  | {0.778, 5.055} | [0.845, 6.305] |
| Observations | 954 | 954 | 954 | 954 | 954 |
| **Panel B** | Precision-weighted/Kink | WAAP | Stem | RTMA | Selection |
| Publication bias | 1.881^{***} |  |  |  | P = 0.300 |
|  | (0.143) |  |  |  | (0.037) |
|  | [1.351, 2.378] |  |  |  |  |
| Effect beyond bias | 0.346^{***} | 0.380^{*} | 0.013 | 3.340^{***} | 0.200 |
|  | (0.073) | (0.229) | (1.323) | (0.022) | (0.828) |
|  | [-0.051, 2.285] |  |  |  |  |
| Observations | 954 | 954 | 954 | 954 | 954 |
*Notes*: Part 1 only includes estimates that measure the effect of below-average looks (as always, recomputed to represent the percent increase in earnings or productivity associated with a one-standard-deviation increase in beauty). Part 2 only includes estimates that directly focus on above-average looks. Panel A reports the results of regression $\hat{b}_{ij} = b_0 + \beta \cdot SE(\hat{b}_{ij}) + \epsilon_{ij}$, where $\hat{b}_{ij}$ denotes the $i$-th beauty effect estimated in the $j$-th study, and $SE(\hat{b}_{ij})$ denotes its standard error. FE = study-level fixed effects, BE = study-level between effects, MAIVE = Meta-Analysis Instrumental Variable Estimator^{21} with log sample size used as an instrument for log variance. Weighted = the inverse of the number of estimates per study is used as the weight. In Panel B all models are weighted by inverse variance. The first specification reports a regression similar to those from the last column of Panel A but with inverse variance weights (results identical to the kinked model^{127}). WAAP = Weighted Average of the Adequately Powered estimates^{4}; Stem = stem-based model^{128}; RTMA = Right-Truncated Meta-Analysis^{22}; Selection = selection model^{55}. P denotes the probability that estimates insignificant at the 5% level are published relative to the probability that significant estimates are published (normalized at 1). Standard errors, clustered at the study level, are reported in parentheses. 95% confidence intervals from wild bootstrap^{129} are reported in square brackets. For MAIVE, in curly brackets we show the Anderson-Rubin 95% confidence interval recommended by Keane and Neal^{20}. ^{*} p < 0.10, ^{**} p < 0.05, ^{***} p < 0.01

TABLE S9. Publication bias tests separately for sex workers and other occupations

| **Part 1. Subsample of sex workers** | | | | | |
|---|---|---|---|---|---|
| **Panel A** | OLS | FE | BE | MAIVE | Weighted |
| Publication bias | 0.148 | 1.467 | -0.756 | -1.225^{***} | -0.468^{**} |
| (*standard error*) | (0.776) | (0.782) | (1.032) | (0.047) | (0.210) |
|  | [-2.956, 2.671] |  |  | {-1.308, -1.141} | [-3.545, 0.383] |
| Effect beyond bias | 8.136^{***} | 4.488 | 11.260^{*} | 11.407^{***} | 11.760^{***} |
| (*constant*) | (2.767) | (2.164) | (2.686) | (0.444) | (0.414) |
|  | [1.525, 15.17] |  |  | {10.727, 12.086} | [5.245, 13.97] |
| Observations | 55 | 55 | 55 | 55 | 55 |
| **Panel B** | Kink | WAAP | Stem | RTMA | Selection |
| Publication bias | -2.126 |  |  |  | P = 1.215 |
|  | (1.878) |  |  |  | (0.091) |
|  | [-4.326, -0.755] |  |  |  |  |
| Effect beyond bias | 12.214^{***} | 12.168^{***} | 11.205^{***} | 14.9^{***} | 8.490^{***} |
|  | (0.349) | (0.372) | (0.905) | (0.636) | (1.691) |
|  | [-22.49, 17.96] |  |  |  |  |
| Observations | 55 | 55 | 55 | 55 | 55 |
| **Part 2. Sample without sex workers** | | | | | |
| **Panel A** | OLS | FE | BE | MAIVE | Weighted |
| Publication bias | 0.391^{***} | 0.204^{*} | 0.800^{***} | 0.517^{*} | 0.718^{***} |
| (*standard error*) | (0.117) | (0.119) | (0.161) | (0.272) | (0.271) |
|  | [0.120, 0.642] |  |  | {0.003, 1.043} | [0.061, 1.331] |
| Effect beyond bias | 2.581^{***} | 3.289^{***} | 1.603^{*} | 1.048 | 2.617^{**} |
| (*constant*) | (0.447) | (0.453) | (0.875) | (1.627) | (1.061) |
|  | [1.660, 3.501] |  |  | {-2.102, 4.041} | [0.333, 5.113] |
| Observations | 1,104 | 1,104 | 1,104 | 1,104 | 1,104 |
| **Panel B** | Precision-weighted/Kink | WAAP | Stem | RTMA | Selection |
| Publication bias | 1.61^{***} |  |  |  | P = 0.307 |
|  | (0.071) |  |  |  | (0.039) |
|  | [1.184, 2.051] |  |  |  |  |
| Effect beyond bias | 0.152^{***} | 0.229^{***} | 0.008 | 2.390^{***} | 0.669^{***} |
|  | (0.038) | (0.07) | (0.798) | (0.013) | (0.231) |
|  | [-0.050, 0.963] |  |  |  |  |
| Observations | 1,104 | 1,104 | 1,104 | 1,104 | 1,104 |
*Notes*: Part 1 only includes estimates that measure the beauty effect among prostitutes. Panel A reports the results of regression $\hat{b}_{ij} = b_0 + \beta \cdot SE(\hat{b}_{ij}) + \epsilon_{ij}$, where $\hat{b}_{ij}$ denotes the $i$-th beauty effect estimated in the $j$-th study, and $SE(\hat{b}_{ij})$ denotes its standard error. FE = study-level fixed effects, BE = study-level between effects, MAIVE = Meta-Analysis Instrumental Variable Estimator^{21} with log sample size used as an instrument for log variance. Weighted = the inverse of the number of estimates per study is used as the weight. In Panel B all models are weighted by inverse variance. The first specification reports a regression similar to those from the last column of Panel A but with inverse variance weights. WAAP = Weighted Average of the Adequately Powered estimates^{4}; Stem = the stem-based model^{128}; Kink = kinked model^{127}; Selection = selection model^{55}. P denotes the probability that estimates insignificant at the 5% level are published relative to the probability that significant estimates are published (normalized at 1). Standard errors, clustered at the study level, are reported in parentheses. 95% confidence intervals from wild bootstrap^{129} are reported in square brackets. For MAIVE, in curly brackets we show the Anderson-Rubin 95% confidence interval recommended by Keane and Neal^{20}. ^{*} p < 0.10, ^{**} p < 0.05, ^{***} p < 0.01

TABLE S10. Description and summary statistics of BMA variables

| Variable | Description | Mean | SD | WM |
|---|---|---|---|---|
| Beauty effect | Reported estimate recomputed to represent the percent increase in earnings or productivity associated with a one-standard-deviation increase in beauty. | 4.28 | 6.28 | 5.21 |
| Standard error (SE) | Standard error of the estimate (the variable is important for gauging publication bias). | 3.75 | 4.27 | 4.05 |
| *Measurement of beauty* |  |  |  |  |
| Interviewer-rated beauty | =1 if a rater assesses the beauty of a subject in person. | 0.45 | 0.50 | 0.34 |
| Photo-rated beauty | =1 if a rater assesses the beauty of a subject based on a photo. | 0.42 | 0.49 | 0.53 |
| Software-rated beauty | =1 if a software tool (e.g., a symmetry assessment algorithm) assesses the beauty of a subject. | 0.09 | 0.29 | 0.10 |
| Self-rated beauty | =1 if subjects self-rate their beauty (reference category). | 0.05 | 0.21 | 0.06 |
| Dummy beauty | =1 if the beauty variable is a dummy (such as “attractive”) and compared to a baseline (mean). | 0.40 | 0.49 | 0.30 |
| Categorical beauty | =1 if the beauty variable included in the regression is defined on a scale, e.g. from 1 to 10 (reference category). | 0.60 | 0.49 | 0.70 |
| Beauty penalty | =1 if the original estimate concerns the effect of below-average looks (e.g. by focusing on a dummy variable “unattractive”). | 0.18 | 0.38 | 0.10 |
| Number of raters | Logarithm of the average number of raters per subject. When software rating is used, the variable is set to sample maximum. | 1.85 | 1.52 | 2.09 |
| *Measurement of success* |  |  |  |  |
| Earnings | =1 if the success measure concerns earnings. | 0.59 | 0.49 | 0.61 |
| Study outcomes | =1 if the success measure concerns performance at school. | 0.16 | 0.37 | 0.12 |
| Teaching & research outcomes | =1 if the success measure concerns academic performance (such as citations). | 0.12 | 0.33 | 0.12 |
| Athletic success | =1 if the success measure concerns athletic performance (such as points or TV viewership). | 0.03 | 0.17 | 0.02 |
| Electoral success | =1 if the success measure concerns electoral success (such as votes). | 0.03 | 0.18 | 0.06 |
| Other outcomes | =1 if the success measure concerns other issues related to performance, such as sales or analysts’ forecast error (reference category). | 0.06 | 0.24 | 0.07 |
| *Data characteristics* |  |  |  |  |
| Male subjects | =1 if the subjects are men. | 0.32 | 0.47 | 0.29 |
| Female subjects | =1 if the subjects are women. | 0.39 | 0.49 | 0.36 |
| Mix-gender subjects | =1 if the sample includes both men and women (reference category). | 0.29 | 0.45 | 0.35 |
| Subjects’ age | Logarithm of the average age of the subject. | 3.40 | 0.45 | 3.51 |
| High-skilled workers | =1 if the study focuses on college-educated workers. | 0.29 | 0.45 | 0.36 |
| Prostitutes | =1 if the study focuses on sex workers. | 0.05 | 0.21 | 0.06 |
| Interpersonal intensity | Index from 0 (low) to 1 (high) that measures how much job success relies on social contact and interaction with others (e.g., customers, clients, colleagues), constructed using data from the O*NET occupational database. | 0.62 | 0.23 | 0.63 |
Continued on next page

TABLE S10 (continued). Description and summary statistics of BMA variables

| Variable | Description | Mean | SD | WM |
| --- | --- | --- | --- | --- |
| Output measurability | Index from 0 (low) to 1 (high) that measures how objectively a measure of worker’s output used in a primary study can be quantified and attributed directly to that individual. It is constructed using data from the O*NET occupational database, adjusted based on the specific performance measure used in a study. | 0.69 | 0.16 | 0.73 |
| Beauty spendings | Share of annual household final consumption expenditure allocated to clothing and personal care, based on the databases of OECD, Eurostat, and national statistical offices complemented by UN and World Bank consumption data. | 7.23 | 1.82 | 6.87 |
| Western culture | =1 if the study focuses on people (both raters and subjects) from the West. | 0.75 | 0.43 | 0.69 |
| Panel data | =1 if panel data or pooled cross-sections are used in the study. | 0.86 | 0.35 | 0.81 |
| Cross-section | =1 if purely cross-sectional data are used in the study (reference category). | 0.14 | 0.35 | 0.19 |
| Data year | Logarithm of the average year of the data used to estimate the beauty normalized by the year of the oldest data in our sample. | 3.34 | 0.61 | 3.45 |
| *Estimation technique* |  |  |  |  |
| OLS method | =1 if the ordinary least squares method is used for estimation. | 0.78 | 0.42 | 0.79 |
| IV method | =1 if instrumental variable methods are used for estimation. | 0.07 | 0.26 | 0.07 |
| DID method | =1 if the difference-in-differences method is used for estimation. | 0.01 | 0.10 | 0.01 |
| Other method | =1 if other methods (maximum likelihood, quantile regression, ridge regression, tobit, propensity score matching) are used for estimation (reference category for estimation methods). | 0.14 | 0.35 | 0.13 |
| Age control | =1 if the study controls for subjects’ age or experience. | 0.88 | 0.33 | 0.81 |
| Education control | =1 if the study controls for subjects’ education. | 0.66 | 0.47 | 0.58 |
| Ethnicity control | =1 if the study controls for subjects’ ethnicity or race. | 0.55 | 0.50 | 0.42 |
| Cognitive skill control | =1 if the study controls for subjects’ cognitive skills (e.g. IQ). | 0.38 | 0.49 | 0.31 |
| Non-cognitive skill control | =1 if the study controls for subjects’ non-cognitive skills such as measures of communication skills, confidence, leadership skills, or another indicator (such as “Big Five” personality traits). | 0.21 | 0.41 | 0.22 |
| Physicality control | =1 if the study controls for subjects’ physicality using weight, height, or body mass index. | 0.27 | 0.44 | 0.25 |
| *Publication characteristics* |  |  |  |  |
| Publication year | The logarithm of the year when the study first appeared in Google Scholar normalized by the year of the earliest publication in our sample. | 2.83 | 0.74 | 2.90 |
| Published study | =1 if the study was published in a peer-reviewed journal. | 0.89 | 0.32 | 0.87 |
| Impact factor | Journal Citation Reports impact factor (Clarivate, 2023). | 2.88 | 2.82 | 2.65 |
| Citations | Logarithm of the number of per-year citations received since the study first appeared in Google Scholar. | 1.42 | 1.06 | 1.41 |
Notes: BMA = Bayesian model averaging. SD = standard deviation, WM = mean weighted by the inverse of the number of estimates reported per study. Details on the construction of interpersonal intensity and output measurability and the definitions of subsamples used in this paper are available in Table S18.

TABLE S11. Diagnostics of the baseline BMA estimation (UIP and dilution priors)

| Mean no. regressors | Draws | Burn-ins | Time | No. models visited |
| --- | --- | --- | --- | --- |
| 7.52 | $3 \cdot 10^{5}$ | $1 \cdot 10^{5}$ | 2.53 mins | 50,564 |
| *Modelspace* | *Visited* | *Topmodels* | *Corr PMP* | *No. obs.* |
| $3.4 \cdot 10^{10}$ | 0.02% | 100% | 0.9952 | 1,159 |
| *Model prior* | *g-prior* | *Shrinkage-stats* |  |  |
| Dilution / 17.5 | UIP | Av = 0.9991 |  |  |
Notes: We employ the combination of the unit information prior recommended by Eicher et al.^{27} and dilution prior suggested by George^{29}, which accounts for collinearity.

FIGURE S3. Model size and convergence of the baseline BMA estimation

FIGURE S4. Model inclusion in BMA (BRIC and random priors)
Notes: On the vertical axis the explanatory variables are ranked according to their posterior inclusion probabilities from the highest at the top to the lowest at the bottom. The horizontal axis shows the values of cumulative posterior model probability. Blue color (darker in grayscale) = the estimated parameter of a corresponding explanatory variable is positive. Red color (lighter in grayscale) = the estimated parameter of a corresponding explanatory variable is negative. No color = the corresponding explanatory variable is not included in the model. Numerical results are reported in Table S12. All variables are described in Table S10.

TABLE S12. Why reported beauty premiums vary (robustness checks)
| Response variable: Beauty premium | Bayesian model averaging (BRIC and random priors): P. mean | Bayesian model averaging (BRIC and random priors): P. SD | Bayesian model averaging (BRIC and random priors): PIP | Ordinary least squares (only for PIP > 0.5): Mean | Ordinary least squares (only for PIP > 0.5): SE | Ordinary least squares (only for PIP > 0.5): p-value |
| --- | --- | --- | --- | --- | --- | --- |
| Constant | 2.164 | NA | 1.000 | 4.326 | 1.728 | 0.012 |
| Standard error | 0.430 | 0.043 | 1.000 | 0.422 | 0.112 | 0.000 |
| *Measurement of beauty* |  |  |  |  |  |  |
| Interviewer-rated beauty | -0.035 | 0.206 | 0.037 |  |  |  |
| Photo-rated beauty | 0.492 | 0.715 | 0.353 |  |  |  |
| Software-rated beauty | 0.007 | 0.122 | 0.011 |  |  |  |
| Dummy beauty | -0.559 | 0.690 | 0.437 |  |  |  |
| Beauty penalty | -0.008 | 0.094 | 0.013 |  |  |  |
| Number of raters | 0.043 | 0.130 | 0.114 |  |  |  |
| *Measurement of success* |  |  |  |  |  |  |
| Earnings | 0.002 | 0.056 | 0.007 |  |  |  |
| Study outcomes | -0.006 | 0.091 | 0.009 |  |  |  |
| Teaching & research outcomes | 0.545 | 0.995 | 0.261 |  |  |  |
| Athletic success | -0.004 | 0.097 | 0.006 |  |  |  |
| Electoral success | 0.567 | 1.254 | 0.195 |  |  |  |
| *Data characteristics* |  |  |  |  |  |  |
| Male subjects | -0.004 | 0.056 | 0.009 |  |  |  |
| Female subjects | -0.004 | 0.060 | 0.010 |  |  |  |
| Subjects' age | -0.043 | 0.246 | 0.039 |  |  |  |
| High-skilled workers | 0.000 | 0.078 | 0.010 |  |  |  |
| Prostitutes | 4.910 | 1.076 | 0.999 | 4.170 | 1.652 | 0.012 |
| Interpersonal intensity | 0.000 | 0.065 | 0.005 |  |  |  |
| Output measurability | 0.852 | 1.851 | 0.198 |  |  |  |
| Beauty spendings | 0.000 | 0.010 | 0.006 |  |  |  |
| Western culture | -0.001 | 0.036 | 0.005 |  |  |  |
| Panel data | -0.944 | 1.016 | 0.508 | -1.795 | 1.739 | 0.302 |
| Data year | 0.256 | 0.458 | 0.268 |  |  |  |
| *Estimation technique* |  |  |  |  |  |  |
| OLS method | -0.005 | 0.077 | 0.010 |  |  |  |
| IV method | -0.001 | 0.058 | 0.005 |  |  |  |
| DID method | -2.367 | 2.869 | 0.448 |  |  |  |
| Age control | 0.011 | 0.117 | 0.014 |  |  |  |
| Education control | -0.016 | 0.120 | 0.024 |  |  |  |
| Ethnicity control | -0.010 | 0.094 | 0.017 |  |  |  |
| Cognitive skill control | -2.269 | 0.444 | 1.000 | -2.194 | 0.707 | 0.002 |
| Non-cognitive skill control | 0.113 | 0.374 | 0.100 |  |  |  |
| Physicality control | 0.000 | 0.032 | 0.005 |  |  |  |
| *Publication characteristics* |  |  |  |  |  |  |
| Published study | -0.224 | 0.640 | 0.128 |  |  |  |
| Impact factor | 0.260 | 0.117 | 0.908 | 0.194 | 0.185 | 0.293 |
| Citations | -0.002 | 0.030 | 0.008 |  |  |  |
| Studies | 67 |  |  | 67 |  |  |
| Observations | 1,159 |  |  | 1,159 |  |  |
Notes: The posterior mean in BMA denotes the partial derivative of the reported beauty premium with respect to the corresponding study characteristic. For example, including a control for cognitive skills typically reduces the beauty premium by 2.3 percentage points. P. mean = posterior mean, P. SD = posterior standard deviation, PIP = posterior inclusion probability, SE = standard error. BMA employs the BRIC g-prior^{25} and the beta-binomial model prior^{26}. The frequentist check only includes variables with PIP above 0.5; standard errors clustered at the study level. All variables are described in Table S10. Technical details and diagnostics of the BMA exercise are available in Table S13 and Figure S5.

TABLE S13. Diagnostics of the alternative BMA estimation (BRIC and random priors)
| *Mean no. regressors* | *Draws* | *Burn-ins* | *Time* | *No. models visited* |
| --- | --- | --- | --- | --- |
| 7.299 | $3 \cdot 10^5$ | $1 \cdot 10^5$ | 1.78 mins | 49,684 |
| *Modelspace* | *Visited* | *Topmodels* | *Corr PMP* | *No. obs.* |
| $3.4 \cdot 10^{10}$ | 0.01% | 100% | 0.9944 | 1,159 |
| *Model prior* | *g-prior* | *Shrinkage-stats* |  |  |
| Random / 17.5 | BRIC | Av = 0.9992 |  |  |
Notes: The specification uses the BRIC g-prior^{25} and the beta-binomial model prior^{26}.

FIGURE S5. Model size and convergence of the alternative BMA estimation (BRIC and random priors)

FIGURE S6. Model inclusion in BMA (beauty penalties excluded)
Notes: We exclude estimates that focus on the effect of below-average looks. On the vertical axis the explanatory variables are ranked according to their posterior inclusion probabilities from the highest at the top to the lowest at the bottom. The horizontal axis shows the values of cumulative posterior model probability. Blue color (darker in grayscale) = the estimated parameter of a corresponding explanatory variable is positive. Red color (lighter in grayscale) = the estimated parameter of a corresponding explanatory variable is negative. No color = the corresponding explanatory variable is not included in the model. Numerical results are reported in Table S14. All variables are described in Table S10.

TABLE S14. Why reported beauty premiums vary (penalties excluded)

| Response variable: Beauty premium | Bayesian model averaging (UIP and dilution priors) |  |  | Ordinary least squares (only for PIP > 0.5) |  |  |
| --- | --- | --- | --- | --- | --- | --- |
|  | P. mean | P. SD | PIP | Mean | SE | p-value |
| Constant | 2.079 | NA | 1.000 | 1.695 | 0.995 | 0.088 |
| Standard error | 0.497 | 0.046 | 1.000 | 0.502 | 0.135 | 0.000 |
| *Measurement of beauty* |  |  |  |  |  |  |
| Interviewer-rated beauty | -0.073 | 0.363 | 0.050 |  |  |  |
| Photo-rated beauty | 1.825 | 0.775 | 0.900 | 2.199 | 0.969 | 0.023 |
| Software-rated beauty | 0.132 | 0.643 | 0.055 |  |  |  |
| Dummy beauty | -0.019 | 0.143 | 0.025 |  |  |  |
| Number of raters | 0.018 | 0.092 | 0.049 |  |  |  |
| *Measurement of success* |  |  |  |  |  |  |
| Earnings | 0.225 | 0.729 | 0.119 |  |  |  |
| Study outcomes | -0.147 | 0.677 | 0.129 |  |  |  |
| Teaching & research outcomes | 0.514 | 1.122 | 0.219 |  |  |  |
| Athletic success | -0.014 | 0.209 | 0.011 |  |  |  |
| Electoral success | 0.399 | 1.213 | 0.121 |  |  |  |
| *Data characteristics* |  |  |  |  |  |  |
| Male subjects | -0.010 | 0.092 | 0.018 |  |  |  |
| Female subjects | -0.002 | 0.041 | 0.007 |  |  |  |
| Subjects’ age | -0.025 | 0.218 | 0.023 |  |  |  |
| High-skilled workers | -0.057 | 0.332 | 0.039 |  |  |  |
| Prostitutes | 6.361 | 0.976 | 1.000 | 6.521 | 1.871 | 0.000 |
| Interpersonal intensity | -0.017 | 0.173 | 0.015 |  |  |  |
| Output measurability | 0.188 | 0.891 | 0.055 |  |  |  |
| Beauty spendings | 0.000 | 0.011 | 0.007 |  |  |  |
| Western culture | -0.026 | 0.167 | 0.031 |  |  |  |
| Panel data | -0.261 | 0.621 | 0.174 |  |  |  |
| Data year | 0.039 | 0.185 | 0.054 |  |  |  |
| *Estimation technique* |  |  |  |  |  |  |
| OLS method | -0.011 | 0.131 | 0.015 |  |  |  |
| IV method | -0.010 | 0.131 | 0.012 |  |  |  |
| DID method | -4.863 | 2.851 | 0.805 | -6.361 | 2.472 | 0.010 |
| Age control | 0.064 | 0.313 | 0.051 |  |  |  |
| Education control | -0.265 | 0.527 | 0.233 |  |  |  |
| Ethnicity control | -0.006 | 0.079 | 0.013 |  |  |  |
| Cognitive skill control | -3.271 | 0.479 | 1.000 | -3.542 | 0.799 | 0.000 |
| Non-cognitive skill control | 0.062 | 0.277 | 0.060 |  |  |  |
| Physicality control | -0.005 | 0.071 | 0.012 |  |  |  |
| *Publication characteristics* |  |  |  |  |  |  |
| Published study | -0.447 | 0.879 | 0.238 |  |  |  |
| Impact factor | 0.375 | 0.095 | 0.997 | 0.347 | 0.193 | 0.072 |
| Citations | 0.000 | 0.022 | 0.007 |  |  |  |
| Studies | 67 |  |  | 67 |  |  |
| Observations | 954 |  |  | 954 |  |  |
Notes: We exclude estimates that focus on the effect of below-average looks. The posterior mean in BMA denotes the partial derivative of the reported beauty premium with respect to the corresponding study characteristic. For example, including a control for cognitive skills typically reduces the beauty premium by 3.3 percentage points. P. mean = posterior mean, P. SD = posterior standard deviation, PIP = posterior inclusion probability, SE = standard error. BMA employs the BRIC g-prior^{25} and the beta-binomial model prior^{26}. The frequentist check only includes variables with PIP above 0.5; standard errors clustered at the study level. All variables are described in Table S10. Technical details and diagnostics of the BMA exercise are available in Table S15 and Figure S7.

TABLE S15. Diagnostics of the BMA estimation (beauty penalties excluded)

| Mean no. regressors | Draws | Burn-ins | Time | No. models visited |
| --- | --- | --- | --- | --- |
| 8.0085 | $3 \cdot 10^5$ | $1 \cdot 10^5$ | 1.72 mins | 44,136 |
| *Modelspace* | *Visited* | *Topmodels* | *Corr PMP* | *No. obs.* |
| $1.7 \cdot 10^9$ | 0.03% | 100% | 0.9993 | 954 |
| *Model prior* | *g-prior* | *Shrinkage-stats* |  |  |
| Random / 17 | UIP | Av = 0.999 |  |  |
Notes: We employ the combination of the unit information prior recommended by Eicher et al.^{27} and dilution prior suggested by George^{29}, which accounts for collinearity.

FIGURE S7. Model size and convergence of the BMA estimation (beauty penalties excluded)

TABLE S16. Robust Bayesian meta-analysis (RoBMA), bias adjustment, full results

| Sample | Obs | Clust | Effect | lCrI | uCrI | τ_{Effect} | τ_{lCrI} | τ_{uCrI} | BF10 | BFhet | BFbias | BFmod |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| *Full sample (1,159 observations)* |  |  |  |  |  |  |  |  |  |  |  |  |
| Full sample | 1,159 | – | 0.21 | 0.00 | 1.27 | 4.23 | 3.88 | 4.55 | 0.32 | ∞ | ∞ | – |
| Full sample (3lvl, studies) | 1,159 | 67 | 3.13 | 2.05 | 4.25 | 4.53 | 3.87 | 5.35 | ∞ | ∞ | ∞ | – |
| Full sample (3lvl, database) | 1,159 | 63 | 2.88 | 1.70 | 4.03 | 4.78 | 4.11 | 5.62 | 19,999 | ∞ | ∞ | – |
| *Subsample excluding prostitutes* |  |  |  |  |  |  |  |  |  |  |  |  |
| No prostitutes | 1,104 | – | 0.06 | 0.00 | 0.85 | 3.87 | 3.57 | 4.16 | 0.10 | ∞ | ∞ | – |
| No prostitutes (3lvl) | 1,104 | 63 | 2.73 | 1.69 | 3.77 | 4.32 | 3.67 | 5.13 | ∞ | ∞ | ∞ | – |
| *Standardized effect size: change in outcome (SD units) per 1-SD increase in beauty* |  |  |  |  |  |  |  |  |  |  |  |  |
| Standardized effect | 1,000 | – | 0.02 | 0.00 | 0.04 | 0.08 | 0.07 | 0.09 | 16 | ∞ | ∞ | – |
| Standardized effect (3lvl) | 1,000 | 62 | 0.05 | 0.03 | 0.07 | 0.09 | 0.08 | 0.11 | ∞ | ∞ | ∞ | – |
| *Industry* |  |  |  |  |  |  |  |  |  |  |  |  |
| Industry | 312 | – | 3.16 | 2.54 | 3.79 | 2.61 | 2.17 | 3.10 | ∞ | ∞ | ∞ | ∞ |
| customer services | 57 | – | 0.38 | -0.59 | 1.34 | – | – | – | 0.05 | – | – | – |
| financial services | 34 | – | 1.00 | -0.31 | 2.32 | – | – | – | 0.15 | – | – | – |
| legal services | 31 | – | 1.32 | 0.16 | 2.48 | – | – | – | 0.53 | – | – | – |
| political office | 37 | – | 2.52 | 1.47 | 3.64 | – | – | – | ∞ | – | – | – |
| professional sports | 56 | – | 1.78 | 0.45 | 3.19 | – | – | – | 1.49 | – | – | – |
| scientific research | 42 | – | 8.12 | 6.45 | 9.74 | – | – | – | ∞ | – | – | – |
| sex industry | 55 | – | 7.00 | 5.90 | 8.06 | – | – | – | ∞ | – | – | – |
| Industry (3lvl) | 312 | 27 | 4.39 | 0.00 | 6.96 | 5.41 | 3.98 | 7.51 | 17 | ∞ | 1,834 | 0.11 |
| customer services | 57 | 7 | 4.05 | 0.00 | 6.91 | – | – | – | 1.50 | – | – | – |
| financial services | 34 | 6 | 4.40 | 0.00 | 7.08 | – | – | – | 73 | – | – | – |
| legal services | 31 | 1 | 4.21 | 0.00 | 7.28 | – | – | – | 3.83 | – | – | – |
| political office | 37 | 4 | 4.36 | 0.00 | 7.17 | – | – | – | 11 | – | – | – |
| professional sports | 56 | 5 | 4.77 | 0.00 | 9.89 | – | – | – | 90 | – | – | – |
| scientific research | 42 | 3 | 4.15 | 0.00 | 6.97 | – | – | – | 2.01 | – | – | – |
| sex industry | 55 | 4 | 4.75 | 0.00 | 9.92 | – | – | – | 46 | – | – | – |
| *Occupation* |  |  |  |  |  |  |  |  |  |  |  |  |
| Occupation | 1,086 | – | 2.59 | 2.01 | 3.14 | 3.20 | 2.93 | 3.50 | ∞ | ∞ | ∞ | ∞ |
| athletes | 56 | – | 2.11 | 0.46 | 3.74 | – | – | – | 1.33 | – | – | – |
| executives | 56 | – | 3.61 | 2.06 | 5.14 | – | – | – | ∞ | – | – | – |
| general pop. | 435 | – | 1.54 | 0.92 | 2.13 | – | – | – | ∞ | – | – | – |
| lawyers | 31 | – | 0.46 | -1.05 | 1.97 | – | – | – | 0.07 | – | – | – |
| politicians | 37 | – | 2.35 | 0.92 | 3.79 | – | – | – | 9.56 | – | – | – |
| salespeople | 32 | – | -1.27 | -2.77 | 0.26 | – | – | – | 0.24 | – | – | – |
| scientists | 42 | – | 9.31 | 7.51 | 11.09 | – | – | – | ∞ | – | – | – |
| prostitutes | 55 | – | 7.79 | 6.54 | 9.00 | – | – | – | ∞ | – | – | – |
| students | 233 | – | -1.52 | -2.30 | -0.75 | – | – | – | 72 | – | – | – |
| teachers | 109 | – | 1.50 | 0.54 | 2.42 | – | – | – | 3.76 | – | – | – |
| Occupation (3lvl) | 1,086 | 62 | 3.47 | 2.26 | 4.68 | 4.51 | 3.68 | 5.44 | ∞ | ∞ | ∞ | 0.43 |
| athletes | 56 | 5 | 4.27 | 2.25 | 9.17 | – | – | – | 132 | – | – | – |
| executives | 56 | 10 | 3.52 | 2.10 | 5.32 | – | – | – | 93 | – | – | – |
| general pop. | 435 | 23 | 3.64 | 2.33 | 5.23 | – | – | – | ∞ | – | – | – |
| lawyers | 31 | 1 | 2.87 | -3.20 | 6.26 | – | – | – | 1.09 | – | – | – |
| politicians | 37 | 4 | 3.66 | 1.75 | 6.70 | – | – | – | 7.42 | – | – | – |
| salespeople | 32 | 5 | 3.15 | 0.75 | 4.72 | – | – | – | 1.93 | – | – | – |
| scientists | 42 | 3 | 3.72 | 1.55 | 7.33 | – | – | – | 5.02 | – | – | – |
| prostitutes | 55 | 4 | 4.95 | 2.34 | 10.86 | – | – | – | ∞ | – | – | – |
| students | 233 | 9 | 2.32 | -1.60 | 4.46 | – | – | – | 0.24 | – | – | – |
| teachers | 109 | 8 | 2.56 | -1.06 | 4.46 | – | – | – | 0.36 | – | – | – |
| *Gender* |  |  |  |  |  |  |  |  |  |  |  |  |
| Gender of rated | 822 | – | 0.79 | 0.00 | 1.79 | 3.88 | 3.49 | 4.30 | 2.16 | ∞ | ∞ | 0.03 |
| female | 447 | – | 0.79 | 0.00 | 1.79 | – | – | – | 0.72 | – | – | – |
| male | 375 | – | 0.79 | 0.00 | 1.79 | – | – | – | 0.71 | – | – | – |
| Gender of rated (3lvl) | 822 | 53 | 3.47 | 2.27 | 4.68 | 4.41 | 3.66 | 5.38 | ∞ | ∞ | ∞ | 0.71 |
| female | 447 | 48 | 3.33 | 2.08 | 4.60 | – | – | – | ∞ | – | – | – |

TABLE S16 (continued). Robust Bayesian meta-analysis (RoBMA), bias adjustment, full results
| Sample | Obs | Clust | Effect | lCrI | uCrI | τ_{Effect} | τ_{lCrI} | τ_{uCrI} | BF10 | BFhet | BFbias | BFmod |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| male | 375 | 44 | 3.61 | 2.35 | 4.88 | – | – | – | ∞ | – | – | – |
| *Customer contact* | | | | | | | | | | | | |
| Facing customer | 1,159 | – | 0.04 | 0.00 | 0.74 | 4.17 | 3.89 | 4.45 | 0.07 | ∞ | ∞ | 320.54 |
| no customer contact | 318 | – | -1.13 | -1.68 | -0.23 | – | – | – | 0.75 | – | – | – |
| some customer contact | 401 | – | 0.17 | -0.33 | 0.86 | – | – | – | 0.02 | – | – | – |
| direct customer contact | 440 | – | 1.09 | 0.59 | 1.76 | – | – | – | 227 | – | – | – |
| Facing customer (3lvl) | 1,159 | 67 | 3.01 | 1.90 | 4.11 | 4.52 | 3.85 | 5.36 | ∞ | ∞ | ∞ | 48.91 |
| no customer contact | 318 | 23 | 0.89 | -0.62 | 2.70 | – | – | – | 0.11 | – | – | – |
| some customer contact | 401 | 19 | 3.95 | 2.46 | 5.51 | – | – | – | ∞ | – | – | – |
| direct customer contact | 440 | 32 | 4.19 | 2.85 | 5.49 | – | – | – | ∞ | – | – | – |
| *Measurability of output/performance* | | | | | | | | | | | | |
| Output measurability | 1,159 | – | 0.19 | 0.00 | 1.27 | 4.24 | 3.88 | 4.55 | 0.29 | ∞ | ∞ | 0.00 |
| low output measurability | 135 | – | 0.19 | 0.00 | 1.27 | – | – | – | 0.48 | – | – | – |
| mid output measurability | 274 | – | 0.19 | 0.00 | 1.27 | – | – | – | 0.44 | – | – | – |
| high output measurability | 750 | – | 0.19 | 0.00 | 1.27 | – | – | – | 0.45 | – | – | – |
| Output measurability dummy (3lvl) | 1,159 | 67 | 3.15 | 2.07 | 4.25 | 4.52 | 3.87 | 5.32 | ∞ | ∞ | ∞ | 0.01 |
| low output measurability | 135 | 6 | 3.15 | 2.06 | 4.27 | – | – | – | ∞ | – | – | – |
| mid output measurability | 274 | 16 | 3.15 | 2.07 | 4.26 | – | – | – | ∞ | – | – | – |
| high output measurability | 750 | 51 | 3.15 | 2.07 | 4.25 | – | – | – | ∞ | – | – | – |
| *Intensity of interpersonal interaction* | | | | | | | | | | | | |
| Interpersonal intensity | 1,159 | – | 0.86 | 0.00 | 1.89 | 4.12 | 3.77 | 4.51 | 2.12 | ∞ | ∞ | 2.10 |
| low interpersonal intensity | 180 | – | 1.59 | 0.00 | 3.27 | – | – | – | 2.67 | – | – | – |
| mid interpersonal intensity | 519 | – | 0.17 | -0.95 | 1.07 | – | – | – | 0.05 | – | – | – |
| high interpersonal intensity | 460 | – | 0.83 | 0.00 | 1.91 | – | – | – | 0.21 | – | – | – |
| Interpersonal intensity (3lvl) | 1,159 | 67 | 3.15 | 2.07 | 4.23 | 4.53 | 3.87 | 5.34 | ∞ | ∞ | ∞ | 0.02 |
| low interpersonal intensity | 180 | 17 | 3.14 | 2.03 | 4.23 | – | – | – | ∞ | – | – | – |
| mid interpersonal intensity | 519 | 30 | 3.16 | 2.08 | 4.24 | – | – | – | ∞ | – | – | – |
| high interpersonal intensity | 460 | 33 | 3.16 | 2.08 | 4.24 | – | – | – | ∞ | – | – | – |
| *Cognition sample 1: cognitive-skill control and non-cognitive-skill control* | | | | | | | | | | | | |
| Cognition sample 1 | 1,159 | – | 0.74 | 0.00 | 1.63 | 3.85 | 3.52 | 4.21 | 2.19 | ∞ | ∞ | ∞ |
| cognitive=0 & noncognitive=0 | 617 | – | 1.64 | 0.75 | 2.45 | – | – | – | ∞ | – | – | – |
| cognitive=0 & noncognitive=1 | 97 | – | 3.26 | 1.66 | 4.74 | – | – | – | ∞ | – | – | – |
| cognitive=1 & noncognitive=0 | 298 | – | -1.66 | -2.77 | -0.62 | – | – | – | 9.95 | – | – | – |
| cognitive=1 & noncognitive=1 | 147 | – | -0.26 | -1.60 | 1.00 | – | – | – | 0.06 | – | – | – |
| Cognition sample 1 (3lvl) | 1,159 | 67 | 2.92 | 1.85 | 4.02 | 4.41 | 3.75 | 5.22 | ∞ | ∞ | ∞ | 3.18 |
| cognitive=0 & noncognitive=0 | 617 | 48 | 3.53 | 2.37 | 4.67 | – | – | – | ∞ | – | – | – |
| cognitive=0 & noncognitive=1 | 97 | 10 | 4.11 | 2.42 | 5.87 | – | – | – | ∞ | – | – | – |
| cognitive=1 & noncognitive=0 | 298 | 16 | 2.03 | 0.42 | 3.82 | – | – | – | 1.32 | – | – | – |
| cognitive=1 & noncognitive=1 | 147 | 15 | 2.03 | 0.36 | 3.85 | – | – | – | 1.13 | – | – | – |
| *Cognition sample 2: objective cognitive measure and non-cognitive-skill control* | | | | | | | | | | | | |
| Cognition sample 2 | 383 | – | 0.28 | 0.00 | 1.39 | 2.33 | 1.92 | 2.75 | 0.43 | ∞ | 2,499 | 1.79 |
| objective=1 and noncognitive=0 | 256 | – | -0.05 | -0.78 | 1.02 | – | – | – | 0.13 | – | – | – |
| objective=1 and noncognitive=1 | 127 | – | 0.62 | 0.00 | 2.02 | – | – | – | 0.70 | – | – | – |
| Cognition sample 2 (3lvl) | 383 | 19 | 0.73 | 0.00 | 2.46 | 2.65 | 2.06 | 3.51 | 0.93 | ∞ | 682 | 0.05 |
| objective=1 and noncognitive=0 | 256 | 12 | 0.73 | 0.00 | 2.45 | – | – | – | 0.32 | – | – | – |
| objective=1 and noncognitive=1 | 127 | 10 | 0.73 | 0.00 | 2.48 | – | – | – | 0.33 | – | – | – |
| *Cognition sample 3: objective cognitive measure or quasi-experimental method* | | | | | | | | | | | | |
| objective=1 or quasi-exp=1 | 395 | – | 0.05 | 0.00 | 0.86 | 2.36 | 2.00 | 2.74 | 0.09 | ∞ | 33,332 | – |
| objective=1 or quasi-exp=1 (3lvl) | 395 | 21 | 0.49 | 0.00 | 2.10 | 2.56 | 2.01 | 3.31 | 0.58 | ∞ | 682 | – |
| *Earnings and productivity* | | | | | | | | | | | | |
| Earnings | 1,159 | – | 0.19 | 0.00 | 1.25 | 4.23 | 3.88 | 4.55 | 0.29 | ∞ | ∞ | 0.17 |
| earnings=0 | 471 | – | 0.14 | -0.49 | 1.24 | – | – | – | 0.14 | – | – | – |
| earnings=1 | 688 | – | 0.24 | 0.00 | 1.30 | – | – | – | 0.18 | – | – | – |
| Earnings (3lvl) | 1,159 | 67 | 3.10 | 2.03 | 4.18 | 4.50 | 3.84 | 5.33 | ∞ | ∞ | ∞ | 0.43 |
| earnings=0 | 471 | 29 | 2.92 | 1.53 | 4.14 | – | – | – | 170.00 | – | – | – |
| earnings=1 | 688 | 43 | 3.29 | 2.11 | 4.50 | – | – | – | ∞ | – | – | – |
*Notes*: This tables expands on the results described in Table 2. Obs denotes the number of estimates included in the analysis (or in the subgroup, when applicable). Clstr denotes the number of clusters (reported only when multi-level clustering is applied). Effect, lCrI, and uCrI refer to the model-averaged posterior mean effect size and its 95% credible interval. τ_{Effect}, τ_{lCrI}, and τ_{uCrI} refer to the model-averaged total heterogeneity and its 95% credible interval; these are reported only at the analysis level (not for subgroups). BF denotes the Bayes factor; as a rule of thumb, $BF > 10$ indicates strong evidence. BF10 tests for the presence of a non-zero effect; BFhet for the presence of heterogeneity; BFbias for publication bias; and BFmod for moderation (differences across subgroups). BFhet, BFbias, and BFmod are reported only at the overall analysis level. When BFmod < 1, subgroup-specific estimates are partially pooled toward the overall effect; when BFmod → 0, subgroup estimates coincide with the overall estimate. Bayes factors reported as ∞ reflect numerical upper limits and indicate very strong evidence ($BF > 10^5$). RoBMA averages over models with and without a true association. When some probability is assigned to the null, the posterior is pulled toward zero and the 95% credible interval may start or end exactly at zero. This is expected behavior of spike-and-slab model averaging.

TABLE S17. Robust Bayesian meta-analysis (RoBMA), full adjustment, full results
| Sample | Obs | Clust | Effect | lCrI | uCrI | τ_{Effect} | τ_{lCrI} | τ_{uCrI} | BF10 | BFhet | BFbias | BFmod |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| *Full sample (1,159 observations)* | | | | | | | | | | | | |
| Full sample | 1,159 | – | -0.19 | -1.28 | 0.00 | 3.41 | 3.15 | 3.69 | 0.29 | ∞ | ∞ | – |
| Full sample (3lvl, studies) | 1,159 | 67 | 0.39 | 0.00 | 2.16 | 4.18 | 3.57 | 4.95 | 0.00 | ∞ | ∞ | – |
| Full sample (3lvl, database) | 1,159 | 63 | 0.01 | 0.00 | 0.02 | 4.39 | 3.76 | 5.18 | 0.03 | ∞ | ∞ | – |
| *Subsample excluding prostitutes* | | | | | | | | | | | | |
| No prostitutes | 1,104 | – | -0.17 | -1.26 | 0.00 | 3.41 | 3.15 | 3.71 | 0.00 | ∞ | ∞ | – |
| No prostitutes (3lvl) | 1,104 | 63 | 0.44 | 0.00 | 2.33 | 4.23 | 3.61 | 5.00 | 0.44 | ∞ | ∞ | – |
| *Standardized effect size: change in outcome (SD units) per 1-SD increase in beauty* | | | | | | | | | | | | |
| Standardized effect | 1,000 | – | 0.00 | -0.01 | 0.00 | 0.07 | 0.06 | 0.08 | 0.10 | ∞ | ∞ | – |
| Standardized effect (3lvl) | 1,000 | 62 | 0.02 | 0.00 | 0.05 | 0.09 | 0.08 | 0.11 | 1.58 | ∞ | ∞ | – |
| *Industry* | | | | | | | | | | | | |
| Industry | 312 | – | 0.50 | 0.00 | 3.35 | 2.63 | 2.17 | 3.24 | 0.30 | ∞ | ∞ | ∞ |
| customer services | 57 | – | -1.97 | -3.96 | 1.32 | – | – | – | 0.48 | – | – | – |
| financial services | 34 | – | -1.65 | -3.51 | 1.57 | – | – | – | 0.43 | – | – | – |
| legal services | 31 | – | 1.15 | -0.18 | 2.22 | – | – | – | 0.18 | – | – | – |
| political office | 37 | – | 0.11 | -1.60 | 2.84 | – | – | – | 0.10 | – | – | – |
| professional sports | 56 | – | -1.03 | -4.10 | 2.37 | – | – | – | 0.23 | – | – | – |
| scientific research | 42 | – | 5.73 | 3.33 | 10.98 | – | – | – | ∞ | – | – | – |
| sex industry | 55 | – | 1.16 | -6.60 | 7.62 | – | – | – | 0.54 | – | – | – |
| Industry (3lvl) | 312 | 27 | 0.10 | 0.00 | 2.00 | 5.37 | 3.91 | 7.29 | 0.08 | ∞ | 33,332 | 0.25 |
| customer services | 57 | 7 | -0.45 | -4.06 | 1.04 | – | – | – | 0.35 | – | – | – |
| financial services | 34 | 6 | 0.25 | -1.17 | 3.01 | – | – | – | 0.16 | – | – | – |
| legal services | 31 | 1 | -0.03 | -3.82 | 3.36 | – | – | – | 0.16 | – | – | – |
| political office | 37 | 4 | 0.01 | -4.58 | 3.62 | – | – | – | 0.23 | – | – | – |
| professional sports | 56 | 5 | 0.76 | -0.22 | 6.65 | – | – | – | 0.35 | – | – | – |
| scientific research | 42 | 3 | -0.26 | -4.31 | 1.83 | – | – | – | 0.16 | – | – | – |
| sex industry | 55 | 4 | 0.44 | -3.08 | 6.08 | – | – | – | 0.34 | – | – | – |
| *Occupation* | | | | | | | | | | | | |
| Occupation | 1,086 | – | -0.33 | -1.53 | 0.00 | 3.42 | 3.02 | 3.75 | 0.57 | ∞ | ∞ | 0.11 |
| athletes | 56 | – | -0.39 | -1.61 | 0.09 | – | – | – | 0.31 | – | – | – |
| executives | 56 | – | -0.16 | -1.53 | 2.35 | – | – | – | 1.13 | – | – | – |
| general pop. | 435 | – | -0.36 | -1.53 | 0.05 | – | – | – | 0.13 | – | – | – |
| lawyers | 31 | – | -0.32 | -1.54 | 0.71 | – | – | – | 0.21 | – | – | – |
| politicians | 37 | – | -0.32 | -1.54 | 0.68 | – | – | – | 0.24 | – | – | – |
| salespeople | 32 | – | -0.68 | -3.86 | 0.00 | – | – | – | 1.45 | – | – | – |
| scientists | 42 | – | 0.38 | -1.53 | 7.84 | – | – | – | 1.44 | – | – | – |
| prostitutes | 55 | – | -0.52 | -3.86 | 0.00 | – | – | – | 0.85 | – | – | – |
| students | 233 | – | -0.54 | -2.25 | 0.00 | – | – | – | 1.46 | – | – | – |
| teachers | 109 | – | -0.35 | -1.53 | 0.31 | – | – | – | 0.14 | – | – | – |
| Occupation (3lvl) | 1,086 | 62 | 1.15 | 0.00 | 3.25 | 4.24 | 3.59 | 5.05 | 1.65 | ∞ | ∞ | 0.25 |
| athletes | 56 | 5 | 1.53 | 0.00 | 5.80 | – | – | – | 1.15 | – | – | – |
| executives | 56 | 10 | 1.29 | 0.00 | 3.77 | – | – | – | 1.44 | – | – | – |
| general pop. | 435 | 23 | 1.31 | 0.00 | 3.44 | – | – | – | 2.18 | – | – | – |
| lawyers | 31 | 1 | 0.73 | -4.86 | 3.47 | – | – | – | 0.57 | – | – | – |
| politicians | 37 | 4 | 1.30 | 0.00 | 4.75 | – | – | – | 0.77 | – | – | – |
| salespeople | 32 | 5 | 0.97 | -0.62 | 2.83 | – | – | – | 0.30 | – | – | – |
| scientists | 42 | 3 | 1.58 | -0.35 | 7.29 | – | – | – | 0.76 | – | – | – |
| prostitutes | 55 | 4 | 1.42 | -4.05 | 10.20 | – | – | – | 1.22 | – | – | – |
| students | 233 | 9 | 0.81 | -1.05 | 2.69 | – | – | – | 0.21 | – | – | – |
| teachers | 109 | 8 | 0.58 | -2.78 | 2.69 | – | – | – | 0.38 | – | – | – |
| *Gender* | | | | | | | | | | | | |
| Gender of rated | 822 | – | 0.00 | 0.00 | 0.00 | 2.90 | 2.63 | 3.19 | 0.02 | ∞ | ∞ | 9.32 |
| female | 447 | – | -0.47 | -0.83 | 0.00 | – | – | – | 2.44 | – | – | – |
| male | 375 | – | 0.46 | 0.00 | 0.81 | – | – | – | 1.34 | – | – | – |
| Gender of rated (3lvl) | 822 | 53 | 1.41 | 0.00 | 3.12 | 3.87 | 3.20 | 4.76 | 2.77 | ∞ | ∞ | 0.93 |
| female | 447 | 48 | 1.25 | -0.44 | 2.98 | – | – | – | 0.76 | – | – | – |
| male | 375 | 44 | 1.58 | 0.00 | 3.36 | – | – | – | 1.11 | – | – | – |
| *Customer contact* | | | | | | | | | | | | |
| Facing customer | 1,159 | – | -0.19 | -1.29 | 0.00 | 3.41 | 3.15 | 3.69 | 0.30 | ∞ | ∞ | 0.00 |
| no customer contact | 318 | – | -0.20 | -1.29 | 0.00 | – | – | – | 0.46 | – | – | – |
| some customer contact | 401 | – | -0.19 | -1.29 | 0.00 | – | – | – | 0.40 | – | – | – |
| direct customer contact | 440 | – | -0.19 | -1.29 | 0.00 | – | – | – | 0.44 | – | – | – |
| Facing customer (3lvl) | 1,159 | 67 | 0.50 | 0.00 | 2.38 | 4.27 | 3.63 | 5.09 | 0.50 | ∞ | ∞ | 2.41 |
| no customer contact | 318 | 23 | -0.61 | -2.35 | 1.66 | – | – | – | 0.16 | – | – | – |
| some customer contact | 401 | 19 | 0.86 | -0.31 | 3.19 | – | – | – | 0.10 | – | – | – |
| direct customer contact | 440 | 32 | 1.25 | 0.00 | 3.50 | – | – | – | 2.26 | – | – | – |
| *Measurability of output/performance* | | | | | | | | | | | | |
| Output measurability | 1,159 | – | -0.21 | -1.32 | 0.00 | 3.41 | 3.15 | 3.70 | 0.32 | ∞ | ∞ | 0.08 |
| low output measurability | 135 | – | -0.17 | -1.30 | 0.62 | – | – | – | 0.30 | – | – | – |
| mid output measurability | 274 | – | -0.26 | -1.41 | 0.00 | – | – | – | 0.65 | – | – | – |
| high output measurability | 750 | – | -0.21 | -1.30 | 0.03 | – | – | – | 0.05 | – | – | – |
| Output measurability dummy (3lvl) | 1,159 | 67 | 0.53 | 0.00 | 2.28 | 4.17 | 3.58 | 4.92 | 0.60 | ∞ | ∞ | 0.00 |
| low output measurability | 135 | 6 | 0.53 | 0.00 | 2.28 | – | – | – | 0.88 | – | – | – |
| mid output measurability | 274 | 16 | 0.53 | 0.00 | 2.29 | – | – | – | 0.53 | – | – | – |
| high output measurability | 750 | 51 | 0.53 | 0.00 | 2.28 | – | – | – | 0.68 | – | – | – |
| *Intensity of interpersonal interaction* | | | | | | | | | | | | |
| Interpersonal intensity | 1,159 | – | -0.15 | -1.23 | 0.00 | 3.41 | 3.16 | 3.69 | 0.22 | ∞ | ∞ | 0.22 |
| low interpersonal intensity | 180 | – | 0.01 | -1.22 | 1.17 | – | – | – | 0.56 | – | – | – |
| mid interpersonal intensity | 519 | – | -0.25 | -1.24 | 0.00 | – | – | – | 0.61 | – | – | – |
| high interpersonal intensity | 460 | – | -0.22 | -1.23 | 0.00 | – | – | – | 0.15 | – | – | – |
| Interpersonal intensity (3lvl) | 1,159 | 67 | 0.32 | 0.00 | 2.11 | 4.18 | 3.57 | 4.95 | 0.31 | ∞ | ∞ | 0.02 |
| low interpersonal intensity | 180 | 17 | 0.31 | 0.00 | 2.10 | – | – | – | 0.47 | – | – | – |
| mid interpersonal intensity | 519 | 30 | 0.32 | 0.00 | 2.11 | – | – | – | 0.20 | – | – | – |
| high interpersonal intensity | 460 | 33 | 0.33 | 0.00 | 2.12 | – | – | – | 0.52 | – | – | – |
| *Cognition sample 1: cognitive-skill control and non-cognitive-skill control* | | | | | | | | | | | | |
| Cognition sample 1 | 1,159 | – | 0.32 | 0.00 | 1.32 | 3.60 | 3.27 | 3.90 | 0.56 | ∞ | ∞ | ∞ |
| cognitive=0 & noncognitive=0 | 617 | – | 1.24 | 0.61 | 2.09 | – | – | – | ∞ | – | – | – |
| cognitive=0 & noncognitive=1 | 97 | – | 2.43 | 1.26 | 4.00 | – | – | – | ∞ | – | – | – |
| cognitive=1 & noncognitive=0 | 298 | – | -1.70 | -2.48 | -0.64 | – | – | – | 16 | – | – | – |
| cognitive=1 & noncognitive=1 | 147 | – | -0.70 | -1.66 | 0.64 | – | – | – | 0.10 | – | – | – |
| Cognition sample 1 (3lvl) | 1,159 | 67 | 2.56 | 1.51 | 3.66 | 4.19 | 3.57 | 4.97 | ∞ | ∞ | ∞ | 4.54 |
| cognitive=0 & noncognitive=0 | 617 | 48 | 3.16 | 1.98 | 4.33 | – | – | – | ∞ | – | – | – |
| cognitive=0 & noncognitive=1 | 97 | 10 | 3.61 | 1.93 | 5.44 | – | – | – | ∞ | – | – | – |
| cognitive=1 & noncognitive=0 | 298 | 16 | 1.63 | 0.13 | 3.36 | – | – | – | 0.46 | – | – | – |
| cognitive=1 & noncognitive=1 | 147 | 15 | 1.83 | 0.14 | 3.44 | – | – | – | 0.54 | – | – | – |
| *Cognition sample 2: objective cognitive measure and non-cognitive-skill control* | | | | | | | | | | | | |
| Cognition sample 2 | 383 | – | 0.22 | 0.00 | 1.32 | 2.35 | 1.94 | 2.76 | 0.33 | ∞ | 1,586 | 0.85 |
| objective=1 and noncognitive=0 | 256 | – | 0.00 | -0.70 | 1.05 | – | – | – | 0.12 | – | – | – |
| objective=1 and noncognitive=1 | 127 | – | 0.44 | 0.00 | 1.86 | – | – | – | 0.34 | – | – | – |
| Cognition sample 2 (3lvl) | 383 | 19 | 0.64 | 0.00 | 2.34 | 2.64 | 2.04 | 3.51 | 0.78 | ∞ | 339 | 0.05 |
| objective=1 and noncognitive=0 | 256 | 12 | 0.63 | 0.00 | 2.33 | – | – | – | 0.32 | – | – | – |
| objective=1 and noncognitive=1 | 127 | 10 | 0.64 | 0.00 | 2.36 | – | – | – | 0.31 | – | – | – |
| *Cognition sample 3: objective cognitive measure or quasi-experimental method* | | | | | | | | | | | | |
| objective=1 or quasi-exp=1 | 395 | – | 0.06 | 0.00 | 0.89 | 2.36 | 2.01 | 2.73 | 0.10 | ∞ | 2,856 | – |
| objective=1 or quasi-exp=1 (3lvl) | 395 | 21 | 0.46 | 0.00 | 2.00 | 2.54 | 1.99 | 3.30 | 0.56 | ∞ | 620 | – |
| *Earnings and productivity* | | | | | | | | | | | | |
| Earnings | 1,159 | – | -0.22 | -1.31 | 0.00 | 3.41 | 3.15 | 3.70 | 0.34 | ∞ | ∞ | 0.02 |
| earnings=0 | 471 | – | -0.22 | -1.31 | 0.00 | – | – | – | 0.15 | – | – | – |
| earnings=1 | 688 | – | -0.22 | -1.31 | 0.00 | – | – | – | 0.15 | – | – | – |
| Earnings (3lvl) | 1,159 | 67 | 0.40 | 0.00 | 2.18 | 4.17 | 3.57 | 4.93 | 0.41 | ∞ | ∞ | 0.08 |
| earnings=0 | 471 | 29 | 0.38 | -0.37 | 2.18 | – | – | – | 0.20 | – | – | – |

TABLE S17 (continued). Robust Bayesian meta-analysis (RoBMA), full adjustment, full results
| Sample | Obs | Clust | Effect | lCrI | uCrI | τ_{Effect} | τ_{lCrI} | τ_{uCrI} | BF10 | BFhet | BFbias | BFmod |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| earnings=1 | 688 | 43 | 0.43 | 0.00 | 2.19 | – | – | – | 0.21 | – | – | – |
*Notes*: This table expands on the results reported in Table S3. The table reports implied beauty premiums conditional on three adjustments: (i) correction for publication bias, (ii) inclusion of cognitive-ability controls or use of difference-in-differences estimation, and (iii) exclusion of occupations involving sex work. The second adjustment is not applied to “No skill control” and “Non-cognitive skill control only” subgroups. The third adjustment is not applied to the sex industry subgroup. These adjustments are implemented via meta-regression (dummy adjustments with estimated marginal means). Obs denotes the number of estimates included in the analysis (or in the subgroup, when applicable). Clstr denotes the number of clusters (reported only when multi-level clustering is applied). Effect, lCrI, and uCrI refer to the model-averaged posterior mean effect size and its 95% credible interval. τ_{Effect}, τ_{lCrI}, and τ_{uCrI} refer to the model-averaged total heterogeneity and its 95% credible interval; these are reported only at the analysis level (not for subgroups). BF denotes the Bayes factor; as a rule of thumb, $BF > 10$ indicates strong evidence. BF10 is the Bayes factor for the presence of a non-zero effect; BFhet for the presence of heterogeneity; BFbias for the presence of publication bias; and BFmod for moderation (differences across subgroups). BFhet, BFbias, and BFmod are reported only at the overall analysis level. When BFmod < 1 (evidence against subgroup differences), subgroup-specific estimates are partially pooled toward the overall mean effect; if BFmod → 0, subgroup estimates coincide with the overall estimate. Bayes factors reported as ∞ reflect numerical upper limits and indicate very strong evidence ($BF > 10^5$). RoBMA averages over models with and without a true association. When some probability is assigned to the null, the posterior is pulled toward zero and the 95% credible interval may start or end exactly at zero. This is expected behavior of spike-and-slab model averaging.

TABLE S18. Description of subsamples used in the meta-analysis
| Subsample | Description |
| --- | --- |
| *Subsample without prostitutes* | |
| No prostitutes | Excludes all observations based on sex workers or occupations associated with the sex industry (where appearance is arguably the core productivity characteristic), retaining all other estimates. |
| *Standardized effect size* | |
| Standardized effect | All effect sizes are expressed as the change in the outcome (measured in standard deviations) associated with a one-standard-deviation increase in rated beauty, ensuring comparability across studies using heterogeneous scales and measures. |
| *Industry* | |
| Customer services | Workers in restaurants, hotels, catering, and retail, inclusing sales and clerical workers. Represents jobs with frequent customer contact and moderate pay dispersion. |
| Financial services | Chief executive officers of large banks, financial consultants, equity analysts, and management consultants. Beauty ratings are based on professional portraits or conference photographs, with outcomes such as compensation, analyst ranking, or promotion. A highly competitive, high-status, and objectively measurable domain. |
| Legal services | Licensed lawyers across specializations (litigation, regulatory, and corporate law). Attractiveness ratings are derived from professional headshots. Captures an elite white-collar profession with low output measurability and strong emphasis on formal education. |
| Political office | Political candidates from federal, parliamentary, or municipal election. Beauty is rated from campaign photos; outcomes include vote share and electoral success. Reflects public-facing, high-visibility occupations. |
| Professional sports | Professional golfers, tennis players, and soccer players. Beauty is rated from official portraits; outcomes include prize money, rankings, or salaries. |
| Scientific research | Scientists from the natural and social sciences (economics, psychology, management, biology). Photos are taken from publication or institutional websites, with productivity or citations as outcomes. Represents low interpersonal intensity and high human-capital intensity. |
| Sex industry | Sex workers and escorts in Bangladesh, Ecuador, Mexico, and North America (urban markets). Beauty is rated by clients or reviewers, with price or revenue as outcomes. Reflects near-perfect beauty measurability and direct monetization of appearance. |
| *Occupation* | |
| Athletes | Male and female professional golfers, tennis players, and soccer players, rated from official photographs. Earnings, rankings, or salaries serve as performance outcomes. |
| Executives | CEOs of large firms, typically in banking and finance. Beauty is rated from corporate headshots or annual reports. Compensation, firm performance, or appointment probability are used as outcomes. Represents elite, non-customer-facing professions. |
| General pop. | Broad samples of working-age adults from population surveys (e.g., Czechia, Australia, U.S.). Beauty is rated from ID-style photos; outcomes include earnings, employment status, or self-reported productivity. Provides general-population benchmarks. |
| Lawyers | Licensed lawyers working across different legal fields. Beauty measured from professional portraits. Outcomes include income or partnership status. Represents a cognitively intensive, low-measurability profession. |
| Politicians | Male and female candidates in national and local elections. Beauty rated by independent coders; outcomes include votes, donations, or electoral success. Represents highly visible, competitive occupations with public evaluation. |

TABLE S18 (continued). Description of subsamples used in the meta-analysis
| Subsample | Description |
| --- | --- |
| Salespeople | Retail and service-sector employees. Beauty assessed by external coders or customers; outcomes are tips, sales, or wages. Captures jobs with direct interpersonal exposure and moderate measurability. |
| Scientists | Academic researchers from natural and social sciences, including economics. Beauty rated from institutional portraits; outcomes are citations or publication counts. Represents intellectually demanding but low-interaction occupations. |
| Prostitutes | Female sex workers and escorts. Beauty rated by clients or online reviewers; earnings and price per encounter are outcomes. Provides the most direct market valuation of physical attractiveness. |
| Students | University and high-school students. Beauty rated by peers or external coders; outcomes include grades, test scores, or experimental performance. |
| Teachers | University and school instructors. Beauty rated from class photos or course-evaluation materials; outcomes are student evaluations or teaching ratings. Captures publicly visible but moderately measurable occupations. |
| *Gender* | |
| Female | Estimates based on ratings of women. Majority of samples involve mixed-gender raters. |
| Male | Estimates based on ratings of men, typically drawn from male-dominated occupational settings such as executives or politicians. |
| *Customer contact* | |
| No customer contact | Subample where the occupation involves no direct client or customer interaction (e.g., analysts, executives in internal roles). The classification is based on occupational profiles from the O*NET occupational database. Details on how each observation is handled can be found in the online appendix at meta-analysis.cz/beauty |
| Some customer contact | Subample where the job requires partial or mediated client exposure (e.g., teachers, managers). The classification is based on occupational profiles from the O*NET occupational database. Details on how each observation is handled can be found in the online appendix at meta-analysis.cz/beauty |
| Direct customer contact | Subample where the interaction with clients is central to job performance (e.g., sales, service, and sex industry roles). The classification is based on occupational profiles from the O*NET occupational database. Details on how each observation is handled can be found in the online appendix at meta-analysis.cz/beauty |
| *Measurability of output* | |
| Low output measurability | Subsample where the output-measurability index is in the low range ($index \leq 0.4$). Output measurability is an index ranging from 0 (low) to 1 (high) that measures how objectively a measure of a worker’s output used in a primary study can be quantified and attributed directly to that individual. It is constructed using data from the O*NET occupational database, adjusted based on the specific performance measure used in a study. Low-output-measurability outcomes are mostly subjective, composite, or only loosely linked to true productivity. Typical examples include teaching evaluations and course ratings, composite indices of fringe benefits, career rank, qualitative performance reviews, and broadly aggregated wages not tied to specific tasks. The cutoff at 0.4 is used because the empirical distribution shows a natural break at this point, with all observations below or equal 0.4 belonging to a tightly clustered group of purely subjective or weakly attributable performance measures whereas values above 0.4 begin to incorporate at least some objectively recorded element (e.g., pay, grades, sales), even if still influenced by discretion or multiple inputs. Details on how each observation is handled can be found in the online appendix at meta-analysis.cz/beauty |

TABLE S18 (continued). Description of subsamples used in the meta-analysis
| Subsample | Description |
| --- | --- |
| Mid output measurability | Subsample where the output-measurability index lies in the middle range ($0.4 < index < 0.7$). Outcomes combine objective elements (such as recorded pay or grades) with evaluator discretion or multi-input processes, making them partly comparable across units while still influenced by non-performance factors. Examples include earnings with bonuses for general workers; salary or earnings (including bonuses) for executives, athletes, and lawyers; students’ GPA; earnings of scientists, administrators, or artists; loan applicants’ internal rate of return; and salespeople’s commission wages, revenue per sale, or time on market. The lower cutoff at 0.4 separates outcomes with no quantifiable individual component (purely subjective or composite measures) from those where at least some objective record exists, while the upper cutoff at 0.7 marks the point at which performance becomes predominantly objective and tied to clearly measurable, task-specific outputs. Details on how each observation is handled can be found in the online appendix at meta-analysis.cz/beauty |
| High output measurability | Subsample where the index is in the high range ($index \geq 0.7$). Outcomes are tightly and transparently tied to performance or market prices at a fine task or event level, allowing almost mechanical comparison across units. Examples include athletes’ scores and prize money; politicians’ vote shares or personal votes; scientists’ publications, citations, or h-index; sex workers’ prices and monthly income; restaurant servers’ tips; explicit earnings formulas; and executives’ performance-linked compensation. The cutoff at 0.7 thus corresponds to outcomes where the primary performance measure is almost entirely determined by a clearly defined, task-specific metric leaving minimal to no scope for evaluator discretion or institutional judgement. Details on how each observation is handled can be found in the online appendix at meta-analysis.cz/beauty |
| *Intensity of interpersonal interaction* | |
| Low interpersonal intensity | Subsample where the interpersonal-intensity index is low ($index \leq 0.4$). Interpersonal intensity is an index ranging 0 (low) to 1 (high) that measures how much job success relies on social contact and interaction with others (customers, clients, colleagues, etc.). It is constructed using data from the O*NET occupational database. Low interpersonal intensity classifies occupations with minimal direct human interaction, such as scientists, technicians, athletes, and non-customer-facing general-population jobs. These roles rely mostly on individual performance or analytical output rather than continuous communication. The cutoff at 0.4 reflects an empirical break in the index, capturing occupations where interpersonal contact is absent or purely incidental to task performance, whereas values above this level indicate that interaction begins to have at least some functional relevance for carrying out the job. Details on how each observation is handled can be found in the online appendix at meta-analysis.cz/beauty |
| Mid interpersonal intensity | Subsample where the interpersonal-intensity index is in the middle range ($0.4 < index < 0.7$). Encompasses occupations with regular but structured or mediated interaction, such as teachers, students, executives, politicians, and loan applicants. Either social contact is important but does not dominate every aspect of job performance or this is a mixed sample of different occupations with low and high interpersonal intensity. The lower cutoff at 0.4 reflects an empirical break separating occupations with absent or incidental contact, while the upper cutoff at 0.7 marks the point at which interaction becomes continuous, central, and difficult to separate from the core tasks of the job. Details on how each observation is handled can be found in the online appendix at meta-analysis.cz/beauty |

TABLE S18 (continued). Description of subsamples used in the meta-analysis
| Subsample | Description |
| --- | --- |
| High interpersonal intensity | Subsample where the interpersonal-intensity index is high ($index \geq 0.7$). Comprises occupations where communication and personal contact are central to performance, including sex workers, salespeople, restaurant servers, advertising professionals, or politicians. These jobs depend heavily on charisma, persuasion, and customer engagement. The cutoff at 0.7 reflects an empirical break in the index at which interpersonal contact becomes continuous and integral to task execution, distinguishing occupations where interaction dominates day-to-day performance from those where it remains regular but not essential for every task. Details on how each observation is handled can be found in the online appendix at meta-analysis.cz/beauty |
| *Cognition sample 1: cognitive-skill control and non-cognitive-skill control* | |
| cognitive=0 and non-cognitive=0 | Studies controlling for neither cognitive nor non-cognitive skills. |
| cognitive=0 and non-cognitive=1 | Studies controlling only controls for non-cognitive or personality traits (e.g., Big Five, motivation, self-efficacy). |
| cognitive=1 and non-cognitive=0 | Studies controlling only for cognitive ability (e.g., IQ, test scores, or grades). |
| cognitive=1 and non-cognitive=1 | Studies controlling for both cognitive and non-cognitive characteristics. |
| *Cognition sample 2: objective cognitive measure and non-cognitive-skill control* | |
| objective=1 and non-cognitive=0 | Studies including an objective cognitive ability measure (e.g., IQ, test scores, or grades; not self-assessments or external raters’ judgments) but no non-cognitive-skill controls. |
| objective=1 and non-cognitive=1 | Studies including both an objective cognitive ability measure and controls for non-cognitive or personality traits (e.g., Big Five, motivation, self-efficacy). |
| *Cognition sample 3: objective cognitive measure or quasi-experimental method* | |
| objective=1 or quasi-exp=1 | Subsample based on studies that either include an objective cognitive measure or rely on quasi-experimental identification strategies (e.g., random assignment, difference-in-differences, instrumental variables). |
| *Earnings and productivity* | |
| earnings=0 | The dependent variable is not earnings but another performance/productivity proxy (e.g., votes, citations, tips, sales). |
| earnings=1 | The dependent variable is earnings, wage, salary, or income, directly representing labor-market valuation of beauty. |
*Notes*: Descriptions of subsamples rely on study characteristics, occupational context, and indices based on $\text{O*NET}$ data (interpersonal intensity, output measurability). $\text{O*NET}$ is the U.S. Department of Labor’s comprehensive occupational database that provides standardized descriptions and quantitative ratings of job tasks, skills, activities, and work context for each occupation, linked to the official U.S. Standard Occupational Classification (SOC) system. Full coding rules and details for all observations are provided in the online appendix at meta-analysis.cz/beauty.
