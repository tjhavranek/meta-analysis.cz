# Guidance for the Use of AI in the Meta-Analysis of Economics Research

## FRONTMATTER

Nikolai Cook^{1} | Frantisek Bartos^{2} | Pedro R. D. Bom^{3} | Sebastian Gechert^{4} | Klara Kantova^{5} | Jerome Geyer-Klingeberg^{6} | Tomas Havranek^{7} | Zuzana Irsova^{8} | Martina Luskova^{5} | Matej Opatrny^{5} | Franz Prante^{4} | Heiko J. Rachinger^{9} | T. D. Stanley^{10}

^{1}Wilfrid Laurier University, Waterloo, Canada

^{2}University of Amsterdam, Amsterdam, The Netherlands

^{3}University of Deusto, Bilbao, Spain

^{4}Chemnitz University of Technology, Chemnitz, Germany

^{5}Institute of Economic Studies, Faculty of Social Sciences, Charles University, Prague, Czech Republic

^{6}University of Augsburg, Augsburg, Germany

^{7}Institute of Economic Studies, Faculty of Social Sciences, Charles University, Prague, Czech Republic. Faculty of International Relations, Prague University of Economics and Business, Prague, Czech Republic. Meta-Research Innovation Center at Stanford (METRICS), Stanford University, Stanford, California, USA

^{8}Institute of Economic Studies, Faculty of Social Sciences, Charles University, Prague, Czech Republic. Anglo-American University, Prague, Czech Republic. Meta-Research Innovation Center at Stanford (METRICS), Stanford University, Stanford, California, USA

^{9}University of the Balearic Islands, Palma, Spain

^{10}Deakin University, Melbourne, Australia

**Correspondence:** Nikolai Cook (ncook@wlu.ca)

**Received:** 5 December 2025 | **Revised:** 16 January 2026 | **Accepted:** 4 March 2026

## ABSTRACT

Meta-analysis is widely accepted to be the most rigorous and objective approach to the synthesis, interpretation, and understanding of findings from specific areas of empirical economics research. With the advent of increasingly capable generative artificial intelligence and AI’s potential to transform the practice of meta-analysis, the Meta-Analysis of Economics Research Network (MAER-Net) has adopted this set of principles. These principles are meant to provide guidance to meta-researchers, as well as editors and reviewers, in the use of AI in meta-analysis of economics research. Future meta-analyses that employ AI are expected to embody these guiding principles and to follow the associated Reporting Guidelines for Meta-Analysis in Economics - Updated for AI (Cook et al. 2026).

## KEYWORDS: artificial intelligence, meta-analysis, meta-regression, research methods, reporting standards

## 1 | Introduction

Meta-analysis is the way that science takes stock of our vast research output. Meta-analysis is a statistical and systematic review of all relevant research. It produces the authoritative assessments required for evidence-based practice in medicine, social sciences, economics, and business (Stanley and Doucouliagos 2012).

Meta-analysis remains the conventional approach to authoritatively synthesizing the results of empirical economics research. Conventional in the sense that the sizable growth of conducting the meta-analysis of economics research has created a critical mass of meta-analyses published in economic scholarly journals. Three facts illustrate this. First, the number of published meta-analyses in economics has grown steadily over time. Figure 1 plots the number of published meta-analyses in economics from 1989–2024; we note that a quadratic curve fits the data quite well. Second, over 5000 new meta-analyses have been listed on RePEc since the last update of the Reporting Guidelines in 2020. Third, in addition to the *Journal of Economic Surveys*, other top economics journals are now publishing meta-analyses (which often gather hundreds of citations in a short period of time), including *Economic Journal* (Imai et al. 2021; Antinyan and Asatryan 2025), *Journal of Financial Economics* (Kaiser et al. 2022), *Journal of Economic Literature* (Brown et al. 2024), *Review of Economics and Statistics* (Havranek et al. 2024), *American Economic Journal: Applied Economics* (Jackson and Mackevicius 2024), *Journal of Labor Economics* (Opatrny et al. forthcoming), *Journal of Political Economy: Microeconomics* (Cala et al. forthcoming), *Journal of Political Economy* (Mullins 2025), and *American Economic Review: Insights* (Cohen and Ganong 2026).^{1}

FIGURE 1 (no artwork). Meta-analysis in economics over time. *Notes:* The growth of published meta-analyses in economics over 35 years. Produced by searching EconLit for journal articles with “Meta-analysis” or “Meta-regression” in either the title or abstract. Inspired by Figure 1 of Stanley and Doucouliagos (2012).

The advent of artificial intelligence (AI), and in particular, the introduction of large language models (LLMs) has introduced both very real opportunities and challenges for meta-analyses (Feng et al. 2022; Li et al. 2025; Bernard et al. 2025). For our purposes, AI refers to computational systems that employ non-deterministic, adaptive, or probabilistic algorithms-such as machine-learning classifiers, LLMs, or generative agents-to perform tasks that would ordinarily require human-like interpretation, classification, or judgment. This excludes deterministic, rule-based automation (e.g., standard R/Python scripts or simple text-matching algorithms) that operates without iterative learning or adaptation based on input data. Tasks that formerly required months of manual effort by a team of researchers can now be completed by a single AI-assisted human researcher in seconds. This promise of greatly increased research productivity should be tempered with the rigor and quality expectations of the best scholarly research. Meta-analyses should be, among other things, reproducible, transparent, and informed by the research they are synthesizing. Perhaps most important, the meta-researcher must continue to be held accountable for their research.

What, then, is the role of AI in meta-analysis? Should AI help tackle the vast research output and make authoritative assessments for evidence-based practice in the social sciences, economics, and business? Yes, as long as the human authors remain in the lead and are held responsible. That is, human authors are aware of the AI’s decisions, have examined and corrected an appropriate number of the AI’s decisions, and are ultimately responsible for what AI has produced under their direction. In addition, all research papers must fully disclose any and all assistance from AI.

This document provides a set of principles, which are meant to guide meta-researchers who use AI. They do not make specific recommendations or prohibit the use of any particular tool or AI in general. These guiding principles^{2} are also the framework through which the Reporting Guidelines for Meta-Analysis in Economics (Stanley et al. 2013; Havranek et al. 2020) are updated for AI in Cook et al. (2026).

## 2 | Guiding Principles

The following guiding principles should be considered when using AI in the meta-analysis of economics research. We believe these principles to be valid now and for the foreseeable future. Although not set in stone, we believe that they establish viable expectations for the appropriate use of AI by the research community. Meta-analysis in economics should disclose and discuss any violations of the principles.

In recognition that the landscape of AI technology is rapidly changing (and affecting change to research workflows more rapidly than we have seen before), these guiding principles are *not requirements*, but rather recommendations. Should it become obvious in the future that one of these guiding principles is clearly outdated, authors are free to adjust accordingly, and an update will be posted.

### 2.1 | Human Leadership

Human researchers should be in charge of meta-analysis in all of its stages. The assistance of AI is not expected to be insubstantial. Indeed, the community recognizes the very real possibility that general and/or dedicated AI tools can and will have superior performance to humans in some stages of the meta-analysis process. After all, we recognize that humans are fallible. Human fallibility is a reason our seminal guidelines recommended that “two or more (human) reviewers should code the relevant research and disclose a measure of their agreement.” Whenever AI-generated suggestions diverge from the researchers’ own judgment---such as recommending exclusion of a study, altering a coding decision, or proposing a different model specification---authors should briefly record the disagreement and the rationale for the final human decision. This preserves a transparent audit trail of situations in which AI did not simply automate an existing human choice. However, even with the assistance of AI, human understanding of the underlying research that is being meta-analyzed remains essential. While an AI makes thousands of decisions, human researchers direct the identification, screening, and inclusion of studies, as well as the coding of information, analysis, and reporting. Researchers are ultimately responsible for these decisions.

### 2.2 | Human Accountability

AI cannot be a co-author. AI cannot be accountable because it generates text predictions and lacks understanding of meaning, whether input or output (Floridi 2023). When a meta-analysis is published or made public, the authors, by attaching their names to the work, assume both implicitly and explicitly responsibility for its veracity. That is, while the authors may be grateful for the assistance of AI and other researchers, their names are attached to the research, and they are fully responsible for any errors. The AI, even if closely monitored by authors, cannot be held accountable for the veracity of its output, and most importantly, the use of AI does not diminish the accountability of the human authors (just as the employment of human research assistants does not diminish the accountability of the named authors). With this principle in mind, AI does not fit the definition of co-authorship to this community, a position that is widely consistent with nearly all publishers, including: [American Economic Association](https://www.aeaweb.org/journals/aer/editorial-policy), *[Nature](https://www.nature.com/nature-portfolio/editorial-policies/ai)*, and an even stricter (and living) policy at *[Science](https://www.science.org/content/blog-post/change-policy-use-generative-ai-and-large-language-models)*.

### 2.3 | Human Auditing

As human authors are ultimately responsible for the meta-analysis’ findings and recommendations, the inclusion of AI output must be checked. This is not without precedent - §2.2 of Havranek et al. (2020) states “A full report of how the research literature was searched. This report should include:... A statement addressing who searched, read, and coded the research literature. Two or more reviewers should code the relevant research and disclose a measure of their agreement.” The use of AI as one or both of the reviewers must be included in a statement of who searched, read, and coded the research literature. Accuracy and replicability are the reasons for having more than one reviewer code and disclosing a measure of their disagreement. For these reasons, we recommend that human researchers audit some, but not necessarily all, of AI’s decisions. That is, there should be a minimum standard for human verification, informed by the performance of the AI on the audit where poor performance on the part of the AI necessitates more manual auditing; current best practice in meta-analysis in economics suggests that human authors should manually audit a (simple or otherwise) random sample of ≥ 10% or 100 records (whichever is larger) for screening, and ≥ 10% or 20 studies for coding. From this initial audit, we recommend reporting a measure of the author and AI’s disagreement, including Cohen’s $\kappa$ or other measures of inter-rater reliability. For high-stakes or policy-sensitive meta-analyses (such as those concerning the minimum wage or the value of a statistical life), or when an AI tool is being used in a new context or task, it will often be appropriate to audit substantially more than this minimum, and to document how the chosen audit sample reflects the most consequential AI-assisted decisions.

In a related vein, the researcher has an obligation to understand what is being input to their literature search. At the moment of writing, scholarly research consists mostly of human-only or human-mostly primary research studies. We recognize that this may change and, indeed, has already (Liang et al. 2024; Kobak et al. 2024). We therefore believe that the meta-analyst should take care and make a best effort to assess the credibility of sources that have been included in their meta-analysis.

### 2.4 | Human Disclosure

Following the consensus across the publishing and research communities, we recommend the disclosure of any substantive AI use in meta-analysis. Although reasons for disclosure may vary over time, we believe that disclosure represents best practice and will continue to be best practice moving forward. However, we also recognize that disclosure should neither impede nor place an unreasonable burden on AI-assistance. For example, AI assistance need not be disclosed for trivial applications, such as checking grammar or sentence structure. By contrast, any AI use that shapes core elements of the review---such as search strategies, screening and inclusion decisions, coding rules, statistical analyses, or the formulation of conclusions---should always be treated as substantive and disclosed, even if each individual AI interaction appears minor.^{3} The guiding principle behind disclosure of AI-assistance is to provide the information to the reader, policy maker, and meta-meta-analyst should they need it in their evaluation of the substantive content and replicability of the meta-analysis.

Disclosure of AI use is dictated by the importance of the decision and degree of AI use. First, AI assistance should be disclosed for all research-critical decisions. For example, the inclusion and exclusion of primary studies is sufficiently important. If the researcher wishes to use AI for this stage, it should be disclosed. Second, AI assistance should be disclosed if any part of the research is conducted without the human leadership or verification. For example, if a funnel plot diagram is produced by AI without human validation, we recommend disclosure and a description of the degree to which AI was used. Altogether, AI disclosure should become standard and provide only a minimum of information, disclosing more than this minimum is to be encouraged.

The community also recognizes that prompt engineering can constitute intellectual contribution (in the same manner that cleaning and analysis code has been considered in the past) and thus need not be publicly released. Researchers who use AI-assistance should record their prompts and the AI responses and be willing and able to provide them to a journal’s data editor or reviewer.

Researchers should be able to provide sufficient information to make their AI use traceable and reproducible. When AI tools assist at any stage, authors are encouraged to save their prompts together with details of the interface (e.g., API, web application, or local environment) and the model version or release date.^{4} Where AI-assisted discovery tools are used, exported search logs or bibliographic outputs (e.g., BibTeX, CSV, or JSON files) should be saved alongside replication materials to be able to document what the AI retrieved at the time of the search. If AI-generated or AI-assisted primary studies are detected, these should be identified and coded to allow for their identification in replication.

## 3 | Discussion

This document must, by necessity, remain static; however, we will strive to update and revise this as the evolution of AI dictates, similarly to Korinek (2023). The MAER-Net community considers these principles as providing important guidance in the use of AI when conducting meta-analysis of economics research. The community looks toward the integration of AI-assistance in research with guarded optimism. AI may level the playing field for new meta-analysts, students, and those at resource-challenged institutions by substituting relatively affordable computing capital (Luitse and Denkena 2021) for relatively scarce and highly-skilled labor, allowing more and varied meta-analyses to be conducted. However, human researchers must understand the research they are meta-analyzing, and they remain responsible for what is published, as it may be used to inform decisions that may have real consequences for other humans (Ioannidis 2018).

Lastly, this document will be periodically updated as AI practices evolve at the [Meta-Analysis of Economics Research Network](https://www.maer-net.org/resources) website.

## ACKNOWLEDGMENTS

We thank the participants of MAER-Net’s University of Ottawa Colloquium, October 16-18, 2025 and everyone who contributed to the development and implementation of these guidelines. Havranek and Irsova acknowledge support from the Czech Science Foundation (grant no. 24-11583S). Bom and Rachinger acknowledge support under grant PID2023-152916NB-I00 financed by MCIN/AEI/10.13039/501100011033.

## ENDNOTES

1. Indeed, Gechert et al. (2025) document a strong upward trend in the average impact factors of economic journals where meta-analyses are published.

2. The community was actively engaged in the development of these principles, a public discussion can be viewed on the [MAER-Net blog](https://www.maer-net.org/post/developing-guidelines-for-the-use-of-ai-in-meta-analysis-of-economics-research-guai-maer-and).

3. In the spirit of transparency, those applications of AI that are not clearly trivial, such as having AI initially write the statistical analysis code, should be disclosed to fully inform the meta-analysis reader. However, this may change in the future as writing statistical analysis codes and other currently nontrivial tasks become widely considered trivial for AI.

4. As LLM outputs are non-deterministic, meaningful replication will require disclosure of the prompts, interface, and model version used.

## REFERENCES

Antinyan, A., and Z. Asatryan. 2025. “Nudging for Tax Compliance: A Meta-Analysis.” *Economic Journal* 135, no. 668: 1033–1068.

Bernard, N., Y. Sagawa Jr, N. Bier, T. Lihoreau, L. Pazart, and T. Tannou. 2025. “Using Artificial Intelligence for Systematic Review: The Example of Elicit.” *BMC Medical Research Methodology* 25, no. 1: 75.

Brown, A. L., T. Imai, F. M. Vieider, and C. F. Camerer. 2024. “Meta-Analysis of Empirical Estimates of Loss Aversion.” *Journal of Economic Literature* 62, no. 2: 485–516.

Cala, P., T. Havranek, Z. Irsova, J. Martina, J. Matousek, and J. Novak. (forthcoming). “Financial Incentives and Performance: A Meta-Analysis of Experiments in Economics.” *Journal of Political Economy: Microeconomics*.

Cohen, J. P., and P. Ganong. 2026. “Disemployment Effects of Unemployment Insurance: A Meta-Analysis.” *American Economic Review: Insights* 8, no. 1: 1–18.

Cook, N., F. Bartos, P. R. D. Bom, et al. 2026. “Reporting Guidelines for Meta-Analysis in Economics - Updated for AI.” Working paper. Laurier Centre for Economic Research and Policy Analysis.

Feng, Y., S. Liang, Y. Zhang, et al. 2022. “Automated Medical Literature Screening Using Artificial Intelligence: A Systematic Review and Meta-Analysis.” *Journal of the American Medical Informatics Association* 29, no. 8: 1425–1432.

Floridi, L. 2023. “AI as Agency Without Intelligence: On ChatGPT, Large Language Models, and Other Generative Models.” *Philosophy & technology* 36, no. 1: 15.

Gechert, S., B. Mey, M. Opatrny, et al. 2025. “Conventional Wisdom, Meta-Analysis, and Research Revision in Economics.” *Journal of Economic Surveys* 39, no. 3: 980–999.

Havranek, T., Z. Irsova, L. Laslopova, and O. Zeynalova. 2024. “Publication and Attenuation Biases in Measuring Skill Substitution.” *Review of Economics and Statistics* 106, no. 5: 1187–1200.

Havranek, T., T. D. Stanley, H. Doucouliagos, et al. 2020. “Reporting Guidelines for Meta-Analysis in Economics.” *Journal of Economic Surveys* 34, no. 3: 469–475.

Imai, T., T. A. Rutter, and C. F. Camerer. 2021. “Meta-Analysis of Present-Bias Estimation Using Convex Time Budgets.” *Economic Journal* 131, no. 636: 1788–1814.

Ioannidis, J. P. 2018. “Meta-Research: Why Research on Research Matters.” *PLoS Biology* 16, no. 3: e2005468.

Jackson, C. K., and C. L. Mackevicius. 2024. “What Impacts Can We Expect From School Spending Policy? Evidence From Evaluations in the United States.” *American Economic Journal: Applied Economics* 16, no. 1: 412–446.

Kaiser, T., A. Lusardi, L. Menkhoff, and C. Urban. 2022. “Financial Education Affects Financial Knowledge and Downstream Behaviors.” *Journal of Financial Economics* 145, no. 2: 255–272.

Kobak, D., R. González-Márquez, E.-Á. Horvát, and J. Lause. 2024. “Delving into ChatGPT Usage in Academic Writing Through Excess Vocabulary.” *arXiv preprint arXiv:2406.07016*.

Korinek, A. 2023. “Generative AI for Economic Research: Use Cases and Implications for Economists.” *Journal of Economic Literature* 61, no. 4: 1281–1317.

Li, L., A. Mathrani, and T. Susnjak. 2025. “Transforming Evidence Synthesis: A Systematic Review of the Evolution of Automated Meta-Analysis in the Age of AI.” *arXiv preprint arXiv:2504.20113*.

Liang, W., Y. Zhang, Z. Wu, et al. 2024. “Mapping the Increasing use of LLMs in Scientific Papers.” *arXiv preprint arXiv:2404.01268*.

Luitse, D., and W. Denkena. 2021. “The Great Transformer: Examining the Role of Large Language Models in the Political Economy of AI.” *Big Data & Society* 8, no. 2: 20539517211047734.

Mullins, J. 2025. “A Structural Meta-Analysis of Welfare Reform Experiments and their Impacts on Children.” *Journal of Political Economy* 134, no. 1: 435–477.

Opatrny, M., T. Havranek, Z. Havránková, and M. Scasny. Forthcoming. “Publication Bias and Model Uncertainty in Measuring the Effect of Class Size on Achievement.” Journal of Labor Economics.

Stanley, T. D., and H. Doucouliagos. 2012. *Meta-Regression Analysis in Economics and Business* Routledge.

Stanley, T. D., H. Doucouliagos, M. Giles, et al. 2013. “Meta-Analysis of Economics Research Reporting Guidelines.” *Journal of Economic Surveys* 27, no. 2: 390–394.
