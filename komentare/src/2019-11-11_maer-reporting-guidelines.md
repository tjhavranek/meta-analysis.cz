---
category: "english"
media: "text"
outlet: "MAER-Net"
url: "https://www.maer-net.org/post/revision-of-reporting-guidelines"
date: "2019-11-11"
headline: "Revision of Reporting Guidelines"
byline: "Tomáš Havránek"
word_count: "781"
---

# Revision of Reporting Guidelines

Dear fellow meta-analysts:

It has been 7 years since we drafted the current [reporting guidelines](https://onlinelibrary.wiley.com/doi/full/10.1111/joes.12008). I believe the time is ripe for updating them – and based on our debate at the MAER-Net Open Forum in Greenwich, I think at least some of you share that belief. Let me kick off a discussion on the shape of the possible revision.

The intention is not to create a list of rules and then cast them in stone. Rather, the guidelines should, apart from defining the minimum standard for conducting a meta-analysis in economics (well covered by the current guidelines), offer a set of practical recommendations. These recommendations may change again in a couple of year as our tools evolve.

My motivation for proposing the update is that since I started to serve as an associate editor at the Journal of Economic Surveys, I’ve handled quite a few meta-analyses with basic econometric and interpretation errors, studies that do not enhance the reputation of meta-analysis in economics. I find myself providing similar feedback all over again (and the same, I assume, goes for Tom and Chris at the JoES and many of you who write referee reports), so I believe a concrete set of recommendations published in the JoES will help.

Below I offer 12 subjective recommendations that I miss in the current guidelines. You may disagree about some points or may want to add others. We will prepare the revision of the guidelines (if any) based on the discussion that will follow. Thank you for contributing!

- **Weights**. If the meta-analyst doesn't use inverse-variance weights, she or he should explain why. The requirement is in line with the recent [review paper on meta-analysis in Nature](https://www.nature.com/articles/nature25753?sf184289833=1): *“Meta-analyses that are not weighted by inverse variances are common and often poorly justified.”*
- **Outliers**. The meta-analyst is encouraged to specify how outliers, both in the estimated effects and standard errors, are treated: whether all observations are included, or which rule was used to omit outlying observations (for example, Hadi or winsorizing and the respective thresholds).
- **Reconstructed standard errors.** If standard errors are not directly reported in some primary studies, the meta-analyst should state how the standard errors were obtained (for example, using the delta method with the assumption of zero covariance). A robustness check is encouraged that excludes observations with reconstructed standard errors.
- **Study-level dummies**. When using meta-regression analysis to investigate the extent of publication bias, the meta-analyst is encouraged to include a robustness check with study-level dummies (fixed effects in the econometric sense) and thus control for unobserved characteristics of individual studies. Note that such specification only captures within-study bias (p-hacking).
- **Random effects**. Study-level random effects in economics meta-analyses can be correlated with publication bias or other aspects of studies. The meta-analyst should exercise caution when adding random effects to multiple MRA, because doing so likely violates the exogeneity condition.
- **Clustering or bootstrapping**. Standard errors in meta-regression analysis should be clustered or bootstrapped. [Bootstrapping ](https://ideas.repec.org/c/boc/bocode/s458121.html)is the only viable option when the number of studies is small.
- **General-to-specific**. Instead of sequential t-tests, in multiple MRA it is recommended to use the more holistic general-to-specific approach due to [Hendry and colleagues](https://ideas.repec.org/p/fip/fedgif/838.html). Alternatively, the meta-analyst may want to employ Bayesian or frequentist model averaging to address [model uncertainty](https://www.maer-net.org/post/model-averaging).
- **Sensitivity of model averaging**. If the meta-analyst uses Bayesian or frequentist model averaging, she or he should report robustness checks that show how the results depend on the selected priors (in the Bayesian case) or the selected weights (Mallows or other; in the frequentist case). The procedure employed to simplify model space (Markov Chain Monte Carlo or orthogonalization) should be mentioned.
- **Collinearity**. The meta-analyst is encouraged to report collinearity statistics for multiple MRA, for example the correlation matrix or variance-inflation factors. Note that collinearity increases when inverse-variance weights are used.
- **Robustness checks**. The meta-analyst should report robustness checks to the baseline test of publication bias and the underlying effect. Note that different estimators have different performance in different environments (as shown by [Carter et al.](https://journals.sagepub.com/doi/abs/10.1177/2515245919847196?journalCode=ampa)). Choose several robustness checks, for example: [PET-PEESE](https://onlinelibrary.wiley.com/doi/abs/10.1002/jrsm.1095), [WAAP](https://onlinelibrary.wiley.com/doi/abs/10.1111/ecoj.12461), [Bom & Rachinger](https://onlinelibrary.wiley.com/doi/abs/10.1002/jrsm.1352), [Furukawa](https://economics.mit.edu/files/12424), [Hedges ](https://projecteuclid.org/euclid.ss/1177011364)(and variants thereof), [Andrews & Kasy](https://www.aeaweb.org/articles?id=10.1257/aer.20180310), [p-curve](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2377290), [p-uniform](https://osf.io/preprints/metaarxiv/zqjr9/).
- **Data**. The meta-analyst is encouraged to provide the data to the editor and referees so that they can check their structure. This can be done either through the journal's submission system or (preferably) publicly through the author's website.
- **Economic significance**. The meta-analyst should discuss the economic significance of results. For example, publication bias or the underlying effect can be significant statistically, but not material in practice. If partial correlation coefficients are used, [Doucouliagos's guidelines](https://ideas.repec.org/p/dkn/econwp/eco_2011_5.html) for the practical strength of the effect should be consulted.
