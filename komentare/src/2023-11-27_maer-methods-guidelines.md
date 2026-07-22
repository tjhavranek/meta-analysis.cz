---
category: "english"
media: "text"
outlet: "MAER-Net"
url: "https://www.maer-net.org/post/methods-guidelines-for-meta-analysis"
date: "2023-11-27"
headline: "Methods Guidelines for Meta-Analysis"
byline: "Zuzana Irsova"
word_count: "916"
---

# Methods Guidelines for Meta-Analysis

As discussed at the Palma colloquium, together with Tom, Chris, and Tomas we prepared a brief practical guide on how to do modern meta-analysis – especially in social sciences but hopefully useful to aspiring meta-analysts in any field. The paper has just been published by the *Journal of Economic Surveys* and is available [here](https://onlinelibrary.wiley.com/doi/full/10.1111/joes.12595). The purpose of this column is to provide context to the guidelines from my own personal perspective.

Following these guidelines is not obligatory for publication in *JoES* or elsewhere. Nevertheless, we believe there is value in summarizing in one place the comments that we often provide, as editors or referees, on meta-analysis manuscripts in economics, management, psychology, education, environmental sciences, and medical research. We try to be as specific as possible, but the tone of the guidelines is tempered by referees' comments and interactions among the four co-authors. The paper is mostly intended for researchers new to meta-analysis. In this role, the methods guidelines complement the [reporting guidelines](https://onlinelibrary.wiley.com/doi/full/10.1111/joes.12363) published in 2020.

We provide a step-by-step guide on how to do a meta-analysis from scratch. We cover the following issues: topic selection, literature search, data collection, correction for publication bias and p-hacking, heterogeneity, implied (best practice) estimate, and use of artificial intelligence. The guidelines draw, first, on the vast experience of Tom and Chris with both methods and applications, and second, on the data and codes for dozens of meta-analyses available at [meta-analysis.cz](http://meta-analysis.cz/). Each discussed step and method characteristic is accompanied by a practical example.

The guidelines are brief and non-technical, so please read them if you are interested in the content. Here I highlight seven issues that I personally find particularly important:

**Topic**. If possible, choose a topic that you or your co-authors understand well from your own primary research. It's often risky to write a meta-analysis on a topic you are not intimate with, even if you have a lot of previous experience with meta-analysis. Seek co-authors who have written primary studies in this field.

**Comparability**. Make sure it makes sense to quantitatively compare the estimates reported in different studies. While some systematic heterogeneity is inevitable and can be explored in meta-analysis (indeed, it can be the main reason why to do the meta-analysis in the first place), one should not mix estimates that cover scientifically different concepts. If you are unsure, divide the dataset and conduct separate meta-analyses.

**Quality**. Do not exclude any primary studies ex ante. If you can include a paper, include it. You can always show what happens when you give more weight to "good" studies or if you remove the "bad" studies entirely. Importantly, doing so forces you to specify carefully what it is exactly that makes bad studies bad. Any such differentiation of "good" and "bad" need to be determined by an explicitly coded variable (e.g., quasi-experimental or observational) or some objective measure (e.g., retrospective power). If "bad" studies yield results similar to those of "good" studies, that's also a useful finding as it makes your main findings more robust.

**Multiple estimates per study**. Collect all available estimates and use clustering/bootstrapping. Beware [sample overlap](https://onlinelibrary.wiley.com/doi/abs/10.1002/jrsm.1441). You can base a robustness check on the estimates that researchers prefer. You can also introduce a robustness check that focuses on one (random or median) estimate per study.

**Correction techniques**. Always correct for potential publication bias or p-hacking. Use at least one model based on the funnel plot (such as PET-PEESE) and one selection model (such as 3PSM). Both families of correction techniques have quite different assumptions. Recently, Bartoš et al. (2023) have offered a model average across both families of publication selection bias corrections and models without any selection bias. Bartoš et al. offer easy to use software, JASP: ([https://fbartos.github.io/RoBMA/](https://fbartos.github.io/RoBMA/)) to calculate RoBMA-PSMA. Also, there are a number of video and [published tutorials](https://journals.sagepub.com/doi/full/10.1177/25152459221109259) that provide step-by-step guidance. Additionally, you can also use our new [MAIVE technique](http://meta-analysis.cz/maive/), which allows for spurious precision.

**Bayesian approaches**. You don't have to be a convinced Bayesian to recognize the advantages of Bayesian model averaging techniques, both when it comes to [correcting for publication bias](https://fbartos.github.io/RoBMA/) (as described above) and explaining [heterogeneity](https://www.maer-net.org/post/model-averaging). When using Bayesian model averaging to explain heterogeneity, it is useful to add a dilution prior to address collinearity.

**Implied estimates**. Report implied (best-practice) meta-analysis means for different contexts (for example, different demographic characteristics) conditional on correction for publication bias and potential misspecifications in primary studies.

We hope you will find the guidelines useful. Sometimes they might sound too demanding: do not despair if you cannot accommodate all of these issues. You can find good reasons to disagree with us for specific applications. A well-executed meta-analysis, even if it does not follow all of our recommendations, is immensely helpful to the scientific community and likely to attract a healthy number of citations. Doing a meta-analysis is worth the effort!

The guidelines provide many specific examples, but if I were to choose one general example from the meta-analyses that I co-authored, it would be the [one on skill substitution](https://direct.mit.edu/rest/article/doi/10.1162/rest_a_01227/112420/Publication-and-Attenuation-Biases-in-Measuring) forthcoming in the *Review of Economics and Statistics* and available open-access. The paper incorporates almost all the principles discussed here and in the guidelines.

To be clear, we do not claim that our guidelines must always be followed nor are they the definitive steps in conducting a rigorous meta-analysis in economics or the social sciences. It is impossible to provide a definitive guide on methodology: methods change rapidly, and opinions on best practices sometimes differ even among the co-authors of our guidelines paper. It's OK, and on some issues expected, if you disagree with us.
