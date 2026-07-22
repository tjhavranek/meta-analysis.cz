---
category: "english"
media: "text"
outlet: "MAER-Net"
url: "https://www.maer-net.org/post/model-averaging"
date: "2019-02-27"
headline: "Why Model Averaging Is Useful in Meta-Analysis"
byline: "Tomáš Havránek"
word_count: "1367"
---

# Why Model Averaging Is Useful in Meta-Analysis

If you’ve ever run a regression with more than a handful of variables, you know the problem. It’s called **model uncertainty**: which variables should go into the baseline? One solution is to simply put all in one model, but doing so attenuates precision. Another approach is to get rid of the variables that are more difficult to interpret, but that’s not kosher either:

> It is important to realize that this uncertainty is an inherent part of economic modelling, whether we acknowledge it or not. Putting on blinkers and narrowly focusing on a limited set of possible models implies that we may fail to capture important aspects of economic reality. ([Steel, 2019](https://warwick.ac.uk/fac/sci/statistics/staff/academic-research/steel/steel_homepage/techrep/modelaveraging_jel_final.pdf))

A formal response to model uncertainty is **model averaging**. The idea is to run regression models with different combinations of variables, and then give these models weights based on how they fit the data and how parsimonious, and possibly well-specified, they are. I’ll write from an economist’s perspective (model averaging has its [roots ](https://link.springer.com/article/10.1057/jors.1969.103) in economics), but I hope this post will appeal to anyone who uses regression analysis: social scientists, medical scientists, ecologists, biologists, meta-analysts.

## How it Works

Suppose we have 5 explanatory variables. To do model averaging, we first estimate 2^5 = 32 regressions. Then we assign each model a weight and compute a **weighted average** over the 32 regressions. The weight increases with data fit, but decreases with model complexity (given the same fit, a regression with 4 variables will get more weight than a regression with 5 variables). So, think of adjusted R-squared as an intuitive weight for model averaging. It’s not an optimal weight, but you get the idea.

Many methods of model averaging exist, and the technicalities may look intimidating. Luckily for us, the statistician Mark Steel has crafted a [**superb survey**](https://warwick.ac.uk/fac/sci/statistics/staff/academic-research/steel/steel_homepage/techrep/modelaveraging_jel_final.pdf)**,** which is now forthcoming in the Journal of Economic Literature. Mark’s paper has it all: it’s easily accessible to scientists from various fields, but also contains useful technical details. In this post I quote Mark’s paper liberally – I couldn’t put it better.

## Key for Meta-Analysis

Mark makes a strong case that model averaging should form an essential part of an empirical economist’s toolkit. If that holds for economics, it must hold double for **meta-regression **analysis (in any field), where model uncertainty [runs rampant](https://journals.sagepub.com/doi/10.1177/1740774508101279). In most meta-analysis contexts we can think of [dozens](http://meta-analysis.cz/excess_sensitivity/) of factors that may influence (or just be correlated with) the reported outcomes. Sometimes there’s the theory to guide us, but more often than not we are on our own.

Our traditional response to model uncertainty is **model selection**: let’s choose the best model, either via sequential t-tests or sophisticated [general-to-specific](https://onlinelibrary.wiley.com/doi/full/10.1002/jae.615) modelling. But with 20 variables (a common number in economics meta-analyses), we already have more than a million, 2^20, models to choose from – so we’re virtually guaranteed to choose the wrong one. One can’t possibly run thorough specification checks for a million models. In addition, as Mark explains:

> The most important common characteristic of model selection methods is that they choose a model and then conduct inference conditionally upon the assumption that this model actually generated the data. So these methods only deal with the uncertainty in a limited sense: they try to select the ‘best’ model, and their inference can only be relied upon if that model happens to be (a really good approximation to) the data generating process. In the much more likely case where the best model captures some aspects of reality, but there are other models that capture other aspects, model selection implies that our inference is almost always misleading, either in the sense of being systematically wrong or overly precise. ([Steel, 2019](https://warwick.ac.uk/fac/sci/statistics/staff/academic-research/steel/steel_homepage/techrep/modelaveraging_jel_final.pdf))

Sure, that’s not to say we should bury the theory for good and just go all in for data mining. We always have some idea about the **structure of the underlying model**. We know that certain variables must play a role – so we can pin these to all regressions and only use model averaging to work over the ‘control’ variables (for which we have no theory, but still don’t want to ignore them). Roman Horvath, Zuzana Irsova, Marek Rusnak, and myself use this strategy in our 2015 [Journal of International Economics](http://meta-analysis.cz/substitution/) paper, among other applications.

## But It’s All Bayesian, Right?

The most common model averaging technique is **Bayesian model averaging** (BMA). Model averaging arises naturally as a response to model uncertainty in the Bayesian setting, but I suspect that most of us BMA-users are not convinced Bayesians. We are Bayesian opportunists. True, frequentist methods of model averaging [do exist](https://arxiv.org/abs/1802.03511) (Mark discusses them thoroughly), but BMA is more flexible and easier to compute.

Why? With more than 30 variables, one would have to compute over a billion, 2^30, models. That would take you months, so you need to simplify the model space. Such simplification methods (and I won’t go to details here; read Mark’s paper if you’re interested) are readily available for BMA, but not for the frequentist alternatives – well, with some recent [exceptions](https://onlinelibrary.wiley.com/doi/abs/10.1002/jae.2288). Mark quotes a line by [Jonathan Wright](https://www.sciencedirect.com/science/article/pii/S0304407608001115), who is spot on:

> One does not have to be a subjectivist Bayesian to believe in the usefulness of BMA, or of Bayesian shrinkage techniques more generally. A frequentist econometrician can interpret these methods as pragmatic devices that may be useful for out-of-sample forecasting in the face of model and parameter uncertainty. ([Wright, 2008](https://www.sciencedirect.com/science/article/pii/S0304407608001115))

## Priors Matter

A disclaimer is in order. If you decide to use BMA, note that different priors will give you different results. The natural baseline is to use **agnostic priors**: for example, that all coefficients are zero and that the weight of this prior is the same as the weight of one observation of data (so, [pretty small](https://cran.r-project.org/web/packages/BMS/vignettes/bms.pdf)). You must also specify the prior on model space. Again, the natural starting point is a prior in which all models have the same probability. In any case, robustness checks are crucial, and doing frequentist together with Bayesian model averaging in the same paper often yields the ultimate robustness check.

Yes, [frequentist techniques](https://link.springer.com/article/10.1007/s11424-009-9198-y) do not require priors (not explicitly, anyway) – but you have to choose your assumptions concerning optimal weights. In my eyes, the challenge is essentially the same, but concealed. Mark stresses the importance of priors, but the same goes for assumptions in the frequentist setting:

> For BMA, it is important to understand that the weights (based on posterior model probabilities) are typically quite sensitive to the prior assumptions, in contrast to the usually much more robust results for the model parameters given a specific model. In addition, this sensitivity does not vanish as the sample size grows. Thus, a good understanding of the effect of (seemingly arbitrary) prior choices is critical. ([Steel, 2019](https://warwick.ac.uk/fac/sci/statistics/staff/academic-research/steel/steel_homepage/techrep/modelaveraging_jel_final.pdf))

## Model Averaging Is User-Friendly

How difficult is to do model averaging in **your next meta-analysis**? Not difficult at all. You can use the packages described by Mark or the R code from [our website](http://meta-analysis.cz/) (you don’t have to know R syntax to apply these estimators; the code is self-contained). We have three recent papers in which we use both Bayesian and frequentist model averaging and for which we provide data and code: one in the [European Economic Review](http://meta-analysis.cz/habits/) (as far as we know, the first application of frequentist model averaging in meta-analysis), another in the [Energy Journal](http://meta-analysis.cz/dst/), and the third in the [Oxford Bulletin of Economics and Statistics](http://meta-analysis.cz/education/).

## Anything Else?

Not related to model averaging, but important news for the meta-analysis community: the **American Economic Review** has accepted the first regular [paper](https://maxkasy.github.io/home/files/papers/PublicationBias.pdf) ever that focuses on meta-analysis and publication bias. Congratulations to Isaiah Andrews and Maximilian Kasy! They also have an [app](https://maxkasy.github.io/home/metastudy/) for their method, so now you can do meta-analysis using your iPhone (or Xiaomi Mi, if you prefer). Another [superb new technique](https://github.com/Chishio318/stem-based_method) was developed by **Chishio Furukawa** from the MIT. It’s a clever, intuitive non-parametric estimator that in my experience works great, and I recommend you give it a try. In our new paper conditionally accepted by the [Review of Economic Dynamics](http://meta-analysis.cz/excess_sensitivity/) we employ these two techniques along with more traditional ones (including the ingenious and already classical [WAAP](https://onlinelibrary.wiley.com/doi/full/10.1111/ecoj.12461) by John Ioannidis, Tom Stanley, and Chris Doucouliagos), and all point to the same direction.

By now it won’t surprise you that we do model averaging in that paper, too.
