# Reporting Guidelines for Meta-Analysis in Economics---Updated for AI

## FRONTMATTER

Nikolai Cook^{1} | Frantisek Bartos^{2} | Pedro R. D. Bom^{3} | Sebastian Gechert^{4} | Klara Kantova^{5} | Jerome Geyer-Klingeberg^{6} | Tomas Havranek^{5,7,8} | Zuzana Irsova^{5,9,8} | Martina Luskova^{5} | Matej Opatrny^{5} | Franz Prante^{4} | Heiko J. Rachinger^{10} | T. D. Stanley^{11}

^{1}Wilfrid Laurier University, Waterloo, Ontario, Canada

^{2}University of Amsterdam, Amsterdam, The Netherlands

^{3}University of Deusto, Bilbao, Spain

^{4}Chemnitz University of Technology, Chemnitz, Germany

^{5}Institute of Economic Studies, Faculty of Social Sciences, Charles University, Prague, Czech Republic

^{6}University of Augsburg, Augsburg, Germany

^{7}Faculty of International Relations, Prague University of Economics and Business, Prague, Czech Republic

^{8}Meta-Research Innovation Center at Stanford (METRICS), Stanford University, Stanford, California, USA

^{9}Anglo-American University, Prague, Czech Republic

^{10}University of the Balearic Islands, Palma, Spain

^{11}Deakin University, Melbourne, Australia

**Correspondence:** Nikolai Cook (ncook@wlu.ca)

**Received:** 10 December 2025 | **Revised:** 2 March 2026 | **Accepted:** 14 April 2026

## ABSTRACT

Meta-analysis is how science takes stock of its vast research output. The advent of increasingly capable artificial intelligence (AI) promises an unprecedented ability to identify and synthesize relevant research and its findings. In this document, the meta-analysis of economics research network (MAER-Net) updates existing Reporting Guidelines to be consistent with community-driven best practices for the responsible use and disclosure of AI-assistance in meta-analysis research. This update is meant to further improve the transparency, replicability, and quality of meta-analyses by building upon the 2020 and 2013 Reporting Guidelines published by this Journal. Cook et al. (2026) describe the guiding principles behind the update. Future meta-analyses, whether or not they use AI, are expected to follow these updated guidelines or to be prepared to give reasons if they deviate from them.

## KEYWORDS: artificial intelligence, meta-analysis, meta-regression, research methods, reporting standards

## 1 | Introduction

Twelve years ago, *Journal of Economic Surveys* published the first Reporting Guidelines for Meta-Analysis in Economics (Stanley et al. 2013). Seven years later, the Reporting Guidelines were updated in Havranek et al. (2020), following numerous methodological advances in the field of meta-analysis (Stanley and Doucouliagos 2015;2017; Ioannidis et al. 2017; Andrews and Kasy 2019; Van Aert et al. 2019; Bom and Rachinger 2019; Furukawa 2019) and the impressive attention garnered by many meta-analyses in economics; examples with more than 1000 citations include Stanley (2001); Gorg and Strobl (2001); Woodward and Wui (2001); Weichselbaumer and Winter-Ebmer (2005), and Doucouliagos and Ulubaşoğlu (2008).^{1}

In the five years since that update, there have been further methodological advancements in meta-analysis (examples include the Meta-Analysis Instrumental Variable Estimator and the broader easymeta.org tool (Irsova et al. 2025), the Proportion of Statistically Significant Test (Stanley et al. 2021), and a robust Bayesian model averaging approach to publication bias (Bartos et al. 2023)), while a practitioner’s guide for meta-analysis of social science research (Irsova et al. 2024), and more influential meta-analyses have been published (Cazachevici et al. 2020; Xue et al. 2020; Imai et al. 2021; Taye et al. 2021; Brown et al. 2024; Havranek et al. 2024; Jackson and Mackevicius 2024; Antinyan and Asatryan 2025; Cala et al. 2026; Opatrny et al. 2026; Cohen and Ganong 2026).

At the same time, the rapidly improving capabilities of artificial intelligence (AI), and in particular large language models (LLMs), now promise to revolutionize meta-analysis by replacing relatively scarce and highly-skilled labor with relatively inexpensive computing capital.^{2} Meta-analysis tasks that could take multiple human researchers weeks to complete can now be completed by an AI in minutes.^{3} This promise, however, must be embraced with great caution. Concerns include: AI-hallucinated or fabricated data (Emsley 2023), AI-generated primary studies (Elali and Rachid 2023), non-replicability (Ghahramani 2015; Brown et al. 2020), and non-transparency due to undisclosed AI use. For example, if undisclosed and unverified, a LLM might systematically exclude studies based on unknown criteria, potentially introducing selection bias in the resulting meta-analytic estimates. These guidelines are meant to help avoid careless applications of AI, which threaten the validity and quality of meta-analysis in economics research.

The meta-analysis in economics research network (MAER-Net) community has developed this update to the reporting guidelines in order to set the expectations of its members and the broader scientific community for the responsible use and disclosure of AI-assistance for meta-analysis in economics. We consider these guidelines to be particularly timely and have benefited from the experience of other organizations, including: healthcare (Hernandez-Boussard et al. 2020; Sounderajah et al. 2025; Flemyng et al. 2025), clinical trials (Ibrahim et al. 2021), medical meta-analyses (Cacciamani et al. 2023), and education (Allison 2026). Jobin et al. (2019) survey 84 AI-use guidelines published by organizations and found common principles among them, in ranked order: transparency, justice and fairness, non-maleficence, responsibility, and privacy. Hagendorff (2020)’s survey of 24 AI-ethics guidelines finds that the principles of accountability, privacy, or fairness appeared in about 80% of guidelines sampled.

This update to the Reporting Guidelines, informed by engaged discussion of professional members, embraces these principles, addresses the idiosyncrasies of implementing AI in the meta-analysis of economics, and provides specific, yet tool-agnostic, recommendations that should remain relevant for some time.

We have adopted a set of principles and recommendations that informed the development of this update for AI in Cook et al. (2026) which contains a more complete discussion of the guiding principles. We recommend that human authors of meta-analysis in economics research be accountable for their research findings, audit a notable proportion of the output of the AI, and disclose their use of AI.

MAER-Net recommends that all meta-analyses and meta-regression analyses in economics comply with the following reporting protocols.

## 2 | Reporting Guidelines for Meta-Analyses in Economics

Research papers that conduct meta-analysis in economics should include the points detailed below. If AI is used, the date, tool, version, interface, settings, and preferably the prompts (or representative prompts) should be disclosed for each stage and application.^{4} The absence of a specific AI guideline below does not preclude researchers from proactively disclosing AI use.

### 2.1 | Research Questions and Effect Size

- A clear statement of the specific economic theories, hypotheses, or effects studied.

- A precise definition of how effects are measured (the “effect size”) and their standard errors or other proxies for precision, accompanied by any relevant formulas if transformations are made.

- An explicit description about how measured effects are comparable, including any methods or formulas used to standardize or convert them to a common metric.

- *If AI assisted in formulating the research question or hypothesis, this should be disclosed.*

### 2.2 | Searching, Screening, and Coding of Primary Studies

- A full report of how the research literature was searched. This report should include:

  - the exact databases or other sources used;

  - the precise combination of keywords employed; and

  - the date that the search was completed.

  - *If AI was used during any part of the literature search, compilation, or coding, this should be disclosed.*

  - *Where AI-assisted discovery tools were used, their exportable search logs should be shared in replication materials.*

- A full disclosure of the rules for study (or effect size) inclusion/exclusion. This should be accompanied by a PRISMA flow diagram. *If an AI is used for screening, the human should audit a reasonable number or proportion of inclusions/exclusions and report the false-negative rate, with a default for “reasonable” as 10 percent or 100 records, whichever is larger. Particularly well-performing AI may require less auditing. In such cases, authors should briefly justify the reduced audit by reporting human-AI agreement (the ratio of human-AI matches to records reviewed) so that readers can judge whether the lower level of human verification is warranted.* Audits can be strengthened by independent second-pass review, including adversarial, dual-model workflows under human supervision (Irsova and Havranek 2026).

- A statement addressing who searched, read, and coded the research literature. Two or more reviewers should code the relevant research and disclose a measure of their agreement. *An AI may be used as a substitute for one or both of the reviewers, however, this must be disclosed. A human should code a reasonable amount or proportion (10 percent or 20 studies by default, particularly well-performing AI may require less auditing) and any discrepancies between an AI and human reviewer should be disclosed, along with a statistical reliability metric such as Cohen’s $\kappa$.*

- A complete list of the information coded for each study or estimate. At a minimum, we recommend that reviewers conducting a meta-analysis code:

  - the estimated effect size;

  - its standard error, when feasible, and the degrees of freedom (or sample size);

  - *dummy (i.e., 0/1) variable that the estimate was reviewed by a human.*

- Reviewers conducting a meta-regression analysis also need to code:

  - variables that distinguish which type of econometric model, methods, and techniques were employed;

  - dummy (i.e., 0/1) variables for the omission of theoretically relevant variables in the research study investigated;

  - empirical setting (e.g., region, market, and industry);

  - data types (panel, cross-sectional, time series,...);

  - alternative ways that effects were measured and reported before being converted to a common effect size;

  - year of the data used and/or publication year;

  - type of publication (journal, working paper, book chapter, etc.);

  - the primary study, publication, and/or dataset from which an observation is drawn; and

- The rule or method used to identify outliers, leverage, or influence points when omitted.

### 2.3 | Meta-Analyses and Meta-Regression

- A table displaying definitions of all the coded variables along with their descriptive statistics (means and standard deviations) *and, if applicable, proportion coded by AI.*

- A fully reported meta-regression analysis, along with the exact strategy used to simplify it (e.g., Bayesian or frequentist model averaging, general-to-specific, etc.).

- An investigation of publication, selection, and misspecification biases unless these biases can reasonably be expected to be absent. When suspected, these should be controlled for in subsequent meta-regression models.

- Methods to accommodate heteroscedasticity (e.g., inverse-variance weights) and dependence across estimates, such as within-study dependence (e.g., clustered or bootstrapped standard errors and panel or multilevel meta-regression models).

### 2.4 | Further Reporting and Interpretation

- Graph(s) of the effect sizes, such as funnel graphs, forest plots, or other statistical displays of data. *If produced by AI without the researcher, this is disclosed in the figure’s caption: “Figure produced by AI.” ‘Produced by AI’ refers to outputs generated end-to-end by AI without human validation or the re-running of the analyses.*

- Robustness checks for meta-regression models and publication bias methods. *Where AI contributed to any graphical or statistical outputs, authors should note whether the AI performed only formatting or visualization tasks, or whether it influenced analytic choices (such as bandwidths, model specifications, or weighting schemes). This distinction helps readers assess whether AI played a role in shaping the underlying evidence or only its presentation.*

- A discussion of the economic (or practical) significance of the main findings.

- “Best practice” estimate(s) and sensible variations from them.

- *Where AI tools are used, replication materials should specify the AI model and version, dates of use, and any prompts, templates, or settings that materially influenced screening, coding, or analysis, enabling others to approximate the original AI-assisted workflow.*

- A statement about sharing the data or link to its public posting along with the codes of the core analyses*, and, if applicable, sufficient details for a researcher to apply AI tools to replicate the meta-analysis results.*

## 3 | Discussion

Not all meta-analyses in economics will nicely fit into the above list of recommended guidelines. For example, meta-analyses of economic experiments may not be able to conduct meta-regression due to the limited numbers of experiments or to code all of the moderator variables listed above. Again, exceptions to these guidelines may be acceptable when accompanied by a suitable rationale.

A further qualification made by both the 2013 and 2020 MAER-Net reporting guidelines remains especially relevant to this update.

With one exception, MAER-Net has come to a clear consensus about these reporting guidelines. The requirement to have two reviewers code all the relevant research has received the most comment and discussion. As economists, we all are acutely aware of the tradeoff between the improved quality that the second coder will likely add (through catching mistakes and resolving ambiguities) and the increased cost (in weeks of highly skilled professional labor). We understand that the highest standards of scientific rigor demand at least two highly knowledgeable researchers code the relevant research base. Nonetheless, MAER-Net does not wish to prohibit Ph.D. students and researchers at resource-challenged institutions from employing this important tool to understand their areas of research. To finesse these opposing concerns, the above statement is sufficiently broad to encompass a second reviewer randomly checking a substantial proportion of the research literature if their coding protocol is stated explicitly and justified.^{5}

Similarly, MAER-Net does not wish to prohibit anyone from applying AI in their meta-analyses. When using AI to code the relevant research, we as economists recognize the tradeoff between cost and quality that may change over time as AI-tools develop. The above statement that exceptions to these guidelines are acceptable when accompanied by a suitable rationale is considered sufficiently broad to allow the community’s best practices to evolve over time.^{6}

These guidelines are not meant to express the last words about how best to conduct meta-analysis in economics. Rather, we support all efforts to raise the quality, transparency, and replicability of meta-analysis. There is further useful guidance for what is best practice in applying meta-analysis in economics in Nelson and Kennedy (2009), Stanley and Doucouliagos (2012), and most recently in Irsova et al. (2024). This AI-update to the Reporting Guidelines represents a floor for scientific rigor, replicability, and quality that we hope will be surpassed by most meta-analyses (Stanley et al. 2013; Havranek et al. 2020).

Finally, researchers remain responsible for the ethical use of AI and for protecting fairness, privacy, and scholarly integrity.

## ACKNOWLEDGMENTS

We thank the participants of MAER-Net’s University of Ottawa Colloquium, October 16-18, 2025 and everyone who contributed to the development and implementation of these guidelines. Havranek and Irsova acknowledge support from the Czech Science Foundation (grant no. 24-11583S). Bom and Rachinger acknowledge support under grant PID2023-152916NB-I00 financed by MCIN/AEI/10.13039/501100011033.

## ENDNOTES

1. The 2020 guidelines also introduced a recommendation of including a PRISMA diagram, which itself, has evolved over time. The evolution from the PRISMA 2009 (Liberati et al. 2009) to the PRISMA 2020 Statement (Page et al. 2021) followed ‘advances in methods of identifying, selecting, appraising, and synthesizing studies’ (along with evidence that uptake and reporting was not optimal in most meta-analysis studies examined by Page and Moher (2017)) and is updated for AI-use for healthcare meta-analysis in Cacciamani et al. (2023).

2. The topic of AI’s transformative power has not been neglected in economics research, including in *Journal of Economic Surveys*, Lu and Zhou (2021) provide a systematic review of how AI is incorporated into macroeconomics models, answering whether AI will have similar impacts on the economy as previous technologies, and what the empirical evidence of that impact is. They conclude, most importantly for us here, that AI is different.

3. For illustration and practical guidance toward implementing the great promise in the role of AI in economics research, Korinek (2023) (a living document which is regularly updated like these Reporting Guidelines) discusses use cases of generative AI in the economics research process from ideation to analysis and writing; and further provides both general instructions and specific examples on how to reap the potential productivity gains of AI to automate micro-tasks.

4. For the purpose of these Guidelines and the GUAI-MAER, AI refers to computational systems that employ non-deterministic, adaptive, or probabilistic algorithms-such as machine-learning classifiers, large-language models, or generative agents-to perform tasks that would ordinarily require human-like interpretation, classification, or judgment. This excludes deterministic, rule-based automation (e.g., standard R/Python scripts or simple text-matching algorithms) that operates without iterative learning or adaptation based on input data.

5. For this AI update, ‘substantial’ refers to no less than 10 percent, or 100 records, whichever is larger.

6. The guidelines are additionally not intended to contradict currently evolving publisher requirements of AI-disclosure.

## REFERENCES

Allison, J. 2026. “RAISE the Standard: A Framework for Transparent Reporting of Artificial Intelligence Studies in Education.” *Journal of Educational Computing Research* 64, no. 1: 3–15.

Andrews, I., and M. Kasy. 2019. “Identification of and Correction for Publication Bias.” *American Economic Review* 109: 2766–2794.

Antinyan, A., and Z. Asatryan. 2025. “Nudging for Tax Compliance: A Meta-Analysis.” *Economic Journal* 135: 1033–1068.

Bartos, F., M. Maier, E.-J. Wagenmakers, H. Doucouliagos, and T. Stanley. 2023. “Robust Bayesian Meta-Analysis: Model-Averaging Across Complementary Publication Bias Adjustment Methods.” *Research Synthesis Methods* 14: 99–116.

Bom, P. R., and H. Rachinger. 2019. “A Kinked Meta-Regression Model for Publication Bias Correction.” *Research Synthesis Methods* 10: 497–514.

Brown, A. L., T. Imai, F. M. Vieider, and C. F. Camerer. 2024. “Meta-Analysis of Empirical Estimates of Loss Aversion.” *Journal of Economic Literature* 62: 485–516.

Brown, T., B. Mann, N. Ryder, et al. 2020. “Language Models are Few-Shot Learners.” *Advances in Neural Information Processing Systems* 33: 1877–1901.

Cacciamani, G. E., T. N. Chu, D. I. Sanford, et al. 2023. “PRISMA AI Reporting Guidelines for Systematic Reviews and Meta-Analyses on AI in Healthcare.” *Nature Medicine* 29: 14–15.

Cala, P., T. Havranek, Z. Irsova, M. Luskova, J. Matousek, and J. Novak. 2026. “Financial Incentives and Performance: A Meta-Analysis of Experiments in Economics.”*Journal of Political Economy: Microeconomics* Forthcoming.

Cazachevici, A., T. Havranek, and R. Horvath. 2020. “Remittances and Economic Growth: A Meta-Analysis.” *World Development* 134: 105021.

Cohen, J. P., and P. Ganong. 2026. “Disemployment Effects of Unemployment Insurance: A Meta-Analysis.” *American Economic Review: Insights* 8: 1–18.

Cook, N., F. Bartos, P. R. D. Bom, et al. 2026. “Guidance for the Use of AI in the Meta-Analysis of Economics Research.”*Journal of Economic Surveys* Forthcoming.

Doucouliagos, H., and M. A. Ulubaşoğlu. 2008. “Democracy and Economic Growth: A Meta-Analysis.” *American Journal of Political Science* 52: 61–83.

Elali, F. R., and L. N. Rachid. 2023. “AI-Generated Research Paper Fabrication and Plagiarism in the Scientific Community.” *Patterns* 4, no. 3: 100706.

Emsley, R. 2023. “ChatGPT: These are not Hallucinations–They’re Fabrications and Falsifications.” *Schizophrenia* 9: 52.

Flemyng, E., A. Noel-Storr, B. Macura, et al. 2025. “Position Statement on Artificial Intelligence (AI) Use in Evidence Synthesis Across Cochrane, the Campbell Collaboration, JBI and the Collaboration for Environmental Evidence 2025.” *Cochrane Database of Systematic Reviews* 21: e70074.

Furukawa, C. 2019. “Publication Bias Under Aggregation Frictions: Theory, Evidence, and A New Correction Method.” *SSRN Working Paper 3362053*.

Ghahramani, Z. 2015. “Probabilistic Machine Learning and Artificial Intelligence.” *Nature* 521: 452–459.

Gorg, H., and E. Strobl. 2001. “Multinational Companies and Productivity Spillovers: A Meta-Analysis.” *Economic Journal* 111: 723–739.

Hagendorff, T. 2020. “The Ethics of AI Ethics: An Evaluation of Guidelines.” *Minds and Machines* 30: 99–120.

Havranek, T., Z. Irsova, L. Laslopova, and O. Zeynalova. 2024. “Publication and Attenuation Biases in Measuring Skill Substitution.” *Review of Economics and Statistics* 106: 1187–1200.

Havranek, T., T. D. Stanley, H. Doucouliagos, et al. 2020. “Reporting Guidelines for Meta-Analysis in Economics.” *Journal of Economic Surveys* 34: 469–475.

Hernandez-Boussard, T., S. Bozkurt, J. P. Ioannidis, and N. H. Shah. 2020. “MINIMAR (MINimum Information for Medical AI Reporting): Developing Reporting Standards for Artificial Intelligence in Health Care.” *Journal of the American Medical Informatics Association* 27: 2011–2015.

Ibrahim, H., X. Liu, S. C. Rivera, et al. 2021. “Reporting Guidelines for Clinical Trials of Artificial Intelligence Interventions: The SPIRIT-AI and CONSORT-AI Guidelines.” *Trials* 22: 11.

Imai, T., T. A. Rutter, and C. F. Camerer. 2021. “Meta-Analysis of Present-Bias Estimation Using Convex Time Budgets.” *Economic Journal* 131: 1788–1814.

Ioannidis, J. P., T. D. Stanley, and H. Doucouliagos. 2017. “The Power of Bias in Economics Research.” *Economic Journal* 127, no. 605: F236–F265.

Irsova, Z., P. R. Bom, T. Havranek, and H. Rachinger. 2025. “Spurious Precision in Meta-Analysis of Observational Research.” *Nature Communications* 16: 8454.

Irsova, Z., H. Doucouliagos, T. Havranek, and T. D. Stanley. 2024. “Meta-Analysis of Social Science Research: A Practitioner’s Guide.” *Journal of Economic Surveys* 38: 1547–1566.

Irsova, Z., and T. Havranek. 2026. Research Audit Protocols: Duel + MAD, v2.0. GitHub repository. https://doi.org/10.5281/zenodo.19105954.

Jackson, C. K., and C. L. Mackevicius. 2024. “What Impacts Can We Expect From School Spending Policy? Evidence From Evaluations in the United States.” *American Economic Journal: Applied Economics* 16: 412–446.

Jobin, A., M. Ienca, and E. Vayena. 2019. “The Global Landscape of AI Ethics Guidelines.” *Nature Machine Intelligence* 1: 389–399.

Korinek, A. 2023. “Generative AI for Economic Research: Use Cases and Implications for Economists.” *Journal of Economic Literature* 61: 1281–1317.

Liberati, A., D. G. Altman, J. Tetzlaff, et al. 2009. “The PRISMA Statement for Reporting Systematic Reviews and Meta-Analyses of Studies that Evaluate Healthcare Interventions: Explanation and Elaboration.”*BMJ* 339.

Lu, Y., and Y. Zhou. 2021. “A Review on the Economics of Artificial Intelligence.” *Journal of Economic Surveys* 35: 1045–1072.

Nelson, J. P., and P. E. Kennedy. 2009. “The Use (and Abuse) of Meta-Analysis in Environmental and Natural Resource Economics: An Assessment.” *Environmental and Resource Economics* 42: 345–377.

Opatrny, M., T. Havranek, Z. Irsova, and M. Scasny. 2026. “Publication Bias and Model Uncertainty in Measuring the Effect of Class Size on Achievement.”*Journal of Labor Economics* Forthcoming.

Page, M. J., J. E. McKenzie, P. M. Bossuyt, et al. 2021. “The PRISMA 2020 Statement: An Updated Guideline for Reporting Systematic Reviews.”*BMJ* 372.

Page, M. J., and D. Moher. 2017. “Evaluations of the Uptake and Impact of the Preferred Reporting Items for Systematic Reviews and Meta-Analyses (PRISMA) Statement and Extensions: A Scoping Review.” *Systematic Reviews* 6: 263.

Sounderajah, V., A. Guni, X. Liu, et al. 2025. “The STARD-AI Reporting Guideline for Diagnostic Accuracy Studies Using Artificial Intelligence.”*Nature Medicine* 1–7.

D Stanley, T. 2001. “Wheat From Chaff: Meta-Analysis as Quantitative Literature Review.” *Journal of Economic Perspectives* 15: 131–150.

Stanley, T. D., and H. Doucouliagos. 2012. *Meta-Regression Analysis in Economics and Business* Routledge.

Stanley, T. D., and H. Doucouliagos. 2015. “Neither Fixed Nor Random: Weighted Least Squares Meta-Analysis.” *Statistics in Medicine* 34: 2116–2127.

Stanley, T. D., and H. Doucouliagos. 2017. “Neither Fixed Nor Random: Weighted Least Squares Meta-Regression.” *Research Synthesis Methods* 8: 19–42.

Stanley, T. D., H. Doucouliagos, M. Giles, et al. 2013. “Meta-Analysis of Economics Research Reporting Guidelines.” *Journal of Economic Surveys* 27: 390–394.

Stanley, T. D., H. Doucouliagos, J. P. Ioannidis, and E. C. Carter. 2021. “Detecting Publication Selection Bias Through Excess Statistical Significance.” *Research Synthesis Methods* 12: 776–795.

Taye, F. A., M. V. Folkersen, C. M. Fleming, et al. 2021. “The Economic Values of Global Forest Ecosystem Services: A Meta-Analysis.” *Ecological Economics* 189: 107145.

Van Aert, R. C., J. M. Wicherts, and M. A. Van Assen. 2019. “Publication Bias Examined in Meta-Analyses From Psychology and Medicine: A Meta-Meta-Analysis.” *PloS One* 14: e0215052.

Weichselbaumer, D., and R. Winter-Ebmer. 2005. “A Meta-Analysis of the International Gender Wage Gap.” *Journal of Economic Surveys* 19: 479–511.

Woodward, R. T., and Y.-S. Wui. 2001. “The Economic Value of Wetland Services: A Meta-Analysis.” *Ecological Economics* 37: 257–270.

Xue, X., W. R. Reed, and A. Menclova. 2020. “Social Capital and Health: A Meta-Analysis.” *Journal of Health Economics* 72: 102317.
