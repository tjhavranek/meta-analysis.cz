# Notes for meta-analysis theses

Tomas Havranek and Zuzana Irsova

Version: 1 October 2026, cleaned from the 31 May 2026 cookbook

These are our own informal, subjective notes for students writing a meta-analysis thesis with us, at bachelor's, master's or PhD level. They are a menu of methods and a set of principles, not a checklist every thesis must complete. We expect less from a bachelor's or master's thesis than from a journal paper, so do not despair if you cannot do everything here. Where these notes differ from the published guidelines, discuss the choice with your supervisor. Many of our students have published a shorter version of their thesis in a journal.

## What a reviewer should check in a meta-analysis thesis

Judge these at the level of the thesis. The core items are the search, comparability, standard errors, bias correction and clustering. The wild bootstrap, alternative priors and alternative weights are robustness checks. A missing core item matters more than a missing robustness check, a reasoned departure is fine, and following the practitioner's guide where these notes differ is not a defect.

- Search: a documented query (Google Scholar by default), about 500 hits screened, snowballing, explicit inclusion criteria, published versions used, any restriction stated, a PRISMA diagram. If a meta-analysis of the topic exists, the thesis says what it adds.
- Size: as a rule of thumb at least 10 studies and 50 estimates (20 studies and 100 estimates for a journal), with all estimates from each study. A solid thesis has around 40 studies and 600 estimates or more.
- Comparability: one clearly defined effect, comparable in size and not only in sign, with conversions documented. Partial correlations only as a last resort, with a robustness check on a comparable subset.
- Standard errors: how each was obtained is explained, approximations are listed in an appendix, all are positive, each t-statistic has the sign of its estimate, and sample sizes were collected.
- Cleaning: outliers checked against the studies, any winsorizing small, stated and not driving the results.
- Publication bias and p-hacking: a funnel plot plus RoBMA, MAIVE (with the first-stage F, and the Anderson-Rubin interval if F is below 10) and RTMA, with the corrected mean interpreted even when tests find little bias. A funnel asymmetry test alone is not enough.
- Dependence: standard errors clustered by study (CR2, plus the wild bootstrap with few studies), and a check that studies with many estimates do not drive the results.
- Heterogeneity: moderators motivated by theory and defined in a table with means, no near-constant dummies, and Bayesian model averaging that handles collinearity, includes the standard error, and is robust to priors and weights.
- Best practice: an explicit definition and an implied effect corrected for bias and misspecification, compared with the simple mean in economic units.
- Writing: an introduction arguing why the meta-analysis is needed, figures and tables telling one story, readable variable labels.
- Transparency: the studies, data and code are available.

## Reading and tools

- The practitioner's guide: Irsova, Doucouliagos, Havranek and Stanley (2024), Journal of Economic Surveys ([guide page with free PDF](https://meta-analysis.cz/guidelines/), [published version](https://onlinelibrary.wiley.com/doi/full/10.1111/joes.12595), [blog summary](https://www.maer-net.org/post/methods-guidelines-for-meta-analysis)). Written for experienced researchers, it asks more than we expect from a thesis.
- Reporting guidelines: [Havranek et al. (2020)](https://onlinelibrary.wiley.com/doi/full/10.1111/joes.12363), updated for AI by Cook et al. (2026) ([reporting guidelines](https://onlinelibrary.wiley.com/doi/10.1111/joes.70116), [guidance on the use of AI](https://onlinelibrary.wiley.com/doi/10.1111/joes.70105)). See also [AI tools for meta-analysis](https://www.maer-net.org/post/ai-tools-for-meta-analysis).
- The three principles as of 2026, from [meta-analysis.cz](https://meta-analysis.cz/): correct for publication bias ([RoBMA](https://fbartos.github.io/RoBMA/)), correct for p-hacking ([MAIVE](https://meta-analysis.cz/maive/) and Mathur's [RTMA](https://onlinelibrary.wiley.com/doi/10.1002/jrsm.1701)), cluster by study ([CR2 standard errors](https://doi.org/10.1080/07350015.2016.1247004)).
- [EasyMeta](https://www.easymeta.org) runs MAIVE, RTMA and standard models in the browser. [How to run MAIVE](https://meta-analysis.cz/maive/how-to/) works through a real dataset.
- [Teaching materials](https://meta-analysis.cz/teaching/): slides, Stata and R code, data and recordings where available. Useful, not obligatory.
- Worked examples with data and code: [skill substitution](https://meta-analysis.cz/skill/) (the best template so far), [capital-labor substitution](https://meta-analysis.cz/sigma/), and [student employment](https://meta-analysis.cz/students/), easy to replicate as practice. They predate the 2026 principles, so take the bias corrections from these notes.
- For depth: the textbooks by Stanley and Doucouliagos (Meta-Regression Analysis in Economics and Business) and Borenstein et al. (Introduction to Meta-Analysis), Harrer's free [Doing Meta-Analysis in R](https://bookdown.org/MathiasHarrer/Doing_Meta_Analysis_in_R/), and the [MAER-Net blog](https://www.maer-net.org/blog).
- To stress-test a draft with AI: [mad-research](https://github.com/tjhavranek/mad-research) (written by one of us). Declare any AI use in the thesis.

## Finding the literature

Understand the literature before collecting anything. Read the most prominent studies of your effect (top journals, the most cited) and a narrative survey if one exists. From them and their references, list about 10 studies (fewer in a small literature) that you must include.

Then design one main Google Scholar query from combinations of the keywords used in the papers. It works when many of your must-include studies are among the top hits ([an example](https://meta-analysis.cz/eis/Scholar_search.htm)). Google Scholar searches full texts and covers working papers as well as journals, and one query is easy to replicate. If one query is not enough, list all of them in an appendix. A second database, such as EconLit, is optional.

Read the abstracts of the first 500 hits and download every study that might contain estimates, perhaps 200. Then:

- Drop studies that do not estimate your effect, and those without standard errors unless you have few studies (on bootstrapping standard errors, see [this paper](https://www.sciencedirect.com/science/article/pii/S0140988315002327) and [this one](https://meta-analysis.cz/discrate/)).
- Check whether each working paper has been published, and use only the published version.
- Repeat the query for the last three years.
- Snowball through the references of included studies from the last three years (thoroughly: rank all their references by frequency in Scopus and check the 30 most cited). Also check the studies in earlier meta-analyses.
- Keep notes for a PRISMA diagram in an appendix ([an example](https://meta-analysis.cz/risk/)).

Get papers through the university's [electronic resources](https://ezdroje.cuni.cz/index.php?lang=en).

One person can rarely collect data from more than about 100 studies, or 50 when time is short. By default, include unpublished studies and do not drop studies for perceived low quality. If the literature is too large, agree a restriction with your supervisor, for example to refereed journals ([a justification](https://ideas.repec.org/a/mcb/jmoncb/v45y2013i1p37-70.html)), and state it. The practitioner's guide advises against excluding studies by outlet, so this is a fallback.

## How many studies and estimates

- Bare minimum, as a rule of thumb: 10 studies and 50 estimates. The practitioner's guide puts the floor for modern meta-regression at 30 estimates from 10 studies.
- Minimum if you want to publish: 20 studies and 100 estimates. With only about 20 studies, though, there is little between-study variation to explain, so the heterogeneity part will be thin.
- A solid thesis, well above the minimum: around 40 studies and 600 estimates.
- The median bachelor's or master's thesis meta-analysis: around 60 studies and 1,000 estimates. The larger the dataset, the more convincing the results.

Collect all estimates each study reports, not just one.

## What to collect

For every estimate, collect the effect (typically an elasticity), its standard error or what lets you compute it, the number of observations, the degrees of freedom if you may need partial correlations, a study identifier, and the variables describing how studies differ. The number of observations is the total sample size, not degrees of freedom. MAIVE needs it, so never guess it or back it out of the standard error. See an [example dataset](https://meta-analysis.cz/spillovers/data.xls).

Understand what each effect means (continuous regressor or dummy, levels or logs), and note what each study reports before choosing the effect. This [handout](https://web.mit.edu/14.771/www/emp_handout.pdf) summarizes the main empirical approaches in economics.

Habits that help:

- Record the method in one text column ("OLS", "IV") instead of dummies, and likewise countries. Decide on dummies later.
- Mark the authors' preferred estimates.
- Keep a notes file of arguments you meet (treatment of endogeneity, short versus long run, known biases), sorted by topic.
- Collect about five papers a day, not everything at once.
- Record every recomputation for an appendix, and re-check random parts of the dataset.
- Collect publication characteristics last, all on one day.

## Getting standard errors

A standard error is always positive, and a negative coefficient goes with a negative t-statistic. If a paper shows otherwise, it may report absolute t-statistics, miss a minus sign, or mislabel t-statistics. Check, ask the authors if needed, and never code in absolute values.

- t-statistic only: SE = estimate / t.
- Standard deviation instead: SE = SD / sqrt(n), with n the number of observations, when the SD describes the sample behind a mean effect. If the SD is that of the estimate itself (for example a posterior or bootstrap SD), it is already the standard error. If unsure, ask your supervisor.
- 95% confidence interval: SE = (upper - lower) / (2 × 1.96). For -0.12 to 0.23, SE = 0.35 / 3.92 = 0.089.
- p-value only: in Excel, t = TINV(p, df) for a two-sided p (T.INV.2T in newer versions, and double a one-sided p first), with df the degrees of freedom (observations minus regressors, which in large samples is close to the number of observations). Then SE = |estimate| / t. TINV(0.01569, 352) = 2.43.
- Stars only: ask the authors if you can. Otherwise approximate the t-statistic: an estimate significant at 10% but not at 5% has a t between 1.645 and 1.96, and one significant at 5% but not at 1% has a t between 1.96 and 2.575. An estimate significant at 1% can have any t above 2.575, so exclude such estimates or use other information. Keep approximations rare, since many add systematic error.
- Zero p-value or standard error: ask the authors, approximate (say p = 0.0002 for 0.000), or drop. With only a few such estimates, we lean toward inclusion. Approximate them only after collection, since they may turn out to be outliers.
- No precision at all: usable for simple averages and motivation, not for the bias or heterogeneity analysis, since both need the standard error.

Transformations. If you rescale an estimate by a constant, rescale its standard error the same way: 0.03 (SE 0.01) per inch becomes 0.03/2.54 = 0.012 (SE 0.0039) per centimeter. For a nonlinear function (elasticity = 1/B) or a combination of estimates (B1/B2), use the delta method:

```r
library(msm)                         # install.packages("msm")
deltamethod(~ 1/x1, 0.5, 0.2^2)      # estimate 0.5, SE 0.2, effect 1/x1
cov <- diag(c(se1^2, se2^2), 2, 2)   # covariances set to zero
deltamethod(~ x1/x2, c(b1, b2), cov)
```

If a transformation distorts the link between an estimate and its standard error, run the bias analysis on the original coefficient. The expected value of 1/B rises with SE(B) even without selection (assuming B is bounded away from zero), so bias tests on 1/B find a pattern the transformation created. Transform only to interpret the final result.

Interactions. For wage = a × education + b × education × female, the effect for women is a + b, with SE = sqrt(SE(a)^2 + SE(b)^2) when the covariance is set to zero. If the covariance is reported, add 2 × cov inside the root, and if a correlation r between the two estimates is reported, add 2 × r × SE(a) × SE(b). Neither usually is, so say you approximated.

Squared terms. For wage = B1 × education + B2 × education^2, the effect at the sample mean is B1 + 2 × B2 × mean, with SE = sqrt(SE(B1)^2 + 4 × mean^2 × SE(B2)^2), covariance again zero. B1 and B2 are usually strongly correlated, so this approximation is rougher than for interactions. Say you approximated.

## Comparable effects and partial correlations

Effects must be comparable in size, not only in sign. In order of preference:

1. The same economic effect in all studies, usually an elasticity.
2. A computed common metric, such as the effect of a one-standard-deviation change in the regressor, when studies report summary statistics. Or keep only subsamples with the same interpretation.
3. Partial correlations, as a last resort when definitions cannot be translated. PCC = t / sqrt(t^2 + df) and SE(PCC) = sqrt((1 - PCC^2) / df). For their size, see [Doucouliagos's guidelines](https://ideas.repec.org/p/dkn/econwp/eco_2011_5.html), and for an application, [meta-analysis.cz/remittances](https://meta-analysis.cz/remittances/).

With partial correlations, always add a robustness check on the largest subset with a comparable economic effect, even a small one. The practitioner's guide warns that partial correlations are related to their standard errors by construction, which matters for funnel-based tests. For odds ratios and risk ratios, see [Daniel Bartusek's thesis](https://dspace.cuni.cz/handle/20.500.11956/126499).

If some groups do not belong together, typically short-run and long-run estimates, analyze their publication bias separately, but design the data so that all estimates can be pooled in the heterogeneity analysis.

## Moderator variables

Once the list of studies is final, read many of them before deciding what to code. This is the most creative and often the hardest part. No perfect list exists. Start with differences that theory says should shift the estimate: if aggregation biases estimates upward, code a dummy for aggregated data. Then add controls that theory does not pin down, such as the average year of the data, the number of years and of cross-sectional units, citations, publication in a peer-reviewed journal and the impact factor. Borrow ideas from earlier meta-analyses and the datasets on [meta-analysis.cz](https://meta-analysis.cz/).

As a rule of thumb, a full-fledged meta-analysis needs at least 15 variables (the practitioner's guide says at least 10 and, for parsimony, fewer than 30). Group them for the reader:

- Effect definition: how the variables are defined, short or long run, preferred estimate.
- Data: cross-section, panel or time series, size, time span, average year, aggregation, source.
- Estimation: method, treatment of endogeneity, key controls.
- Publication: RePEc impact factor ([journals](https://ideas.repec.org/top/top.journals.rdiscount.html), [working papers](https://ideas.repec.org/top/top.wpseries.rdiscount.html)), log of Google Scholar citations per year, a peer-reviewed dummy, publication year minus the earliest in the sample.

Country-level variables can test what primary studies could not ([an example](https://ideas.repec.org/a/eee/inecon/v96y2015i1p100-118.html)).

## Cleaning, outliers and winsorizing

Spend several days on cleaning. Negative or zero standard errors point to a typo or rounding, in the paper or in your data. Inspect the histogram and summary statistics of every variable and the funnel plot (estimates on the horizontal axis, precision 1/SE on the vertical). Points far outside the funnel may be misplaced decimals. Re-read the study and show your supervisor anything odd.

Drop or merge dummies with a mean below 0.03 or above 0.97. Variance inflation factors should ideally stay below 10, though that is not always possible. Keep a variable that theory makes important even if it breaks these rules.

We prefer winsorizing the estimates and standard errors to dropping observations. Start at 1% on each side and go higher only if needed, typically to 2.5% and never beyond 5%. The right level removes meaningless outliers, and results change little when you raise it. If you do not need winsorizing, skip it. In Stata, use winsor2. Report results with other levels or none. On how much outlier handling matters, see [meta-analysis.cz/outliers](https://meta-analysis.cz/outliers/).

## Publication bias and p-hacking

Publication bias means some estimates are more likely to be reported, usually significant ones or those that fit theory. P-hacking means trying specifications until significance appears. The two look alike in the data, so meta-analysts call both publication selection bias. It need not mean cheating, and it affects unpublished studies too. If researchers discard negative elasticities of intertemporal substitution while nothing caps large positive ones, the literature is biased upward.

The current core:

- Always show a funnel plot. It motivates the analysis, though judging asymmetry by eye is subjective.
- [RoBMA](https://fbartos.github.io/RoBMA/) corrects for publication bias. It averages selection models and funnel-based methods such as PET-PEESE, weighting each by fit. It is an R package, and JASP runs it from menus.
- [MAIVE](https://meta-analysis.cz/maive/) corrects for p-hacking as well as publication bias. It instruments the reported standard error with a function of the sample size. The standard error is itself estimated, precision can be reported selectively, and method choices move both the estimate and its standard error, so treating it as exogenous is risky. The [how-to page](https://meta-analysis.cz/maive/how-to/) recommends PET-PEESE, equal weights, a log first stage and CR2 errors clustered by study. Report the first-stage F. If it is below 10, report the Anderson-Rubin interval instead of the point estimate and cross-check with RTMA. With data clustered by study, treat that interval as indicative, because it is not cluster-robust. MAIVE is on CRAN and runs in [EasyMeta](https://www.easymeta.org).
- [RTMA](https://onlinelibrary.wiley.com/doi/10.1002/jrsm.1701), by Maya Mathur, corrects for p-hacking under different assumptions. EasyMeta runs it.

Report the corrected mean next to the simple mean, in economic terms, even when tests find little bias.

Older methods are optional robustness checks, and you need few or none: the funnel asymmetry test (FAT-PET) with study fixed effects, between effects or weights (weighting by X means multiplying all variables by the square root of X, [see here](https://www.stata.com/support/faqs/statistics/analytical-weights-with-linear-regression/)), the [Andrews and Kasy](https://www.aeaweb.org/articles?id=10.1257/aer.20180310&&from=f) selection model ([web app](https://maxkasy.github.io/home/metastudy/)), [p-uniform*](https://osf.io/preprints/metaarxiv/zqjr9/), the endogenous kink of [Bom and Rachinger](https://onlinelibrary.wiley.com/doi/abs/10.1002/jrsm.1352) ([Stata code](https://www.dropbox.com/s/8j4rpm8ruz7dwqx/EK_stata.do?dl=0)), WAAP of [Ioannidis et al.](https://onlinelibrary.wiley.com/doi/full/10.1111/ecoj.12461), and [Furukawa's](https://github.com/Chishio318/stem-based_method) stem-based method. Code for several is at [meta-analysis.cz/sigma](https://meta-analysis.cz/sigma/). Caliper tests and the old three-table layout are optional too.

## Clustering and dependence

Estimates from one study are not independent, so cluster standard errors by study in every regression, using CR2. With few studies (fewer than 40, the threshold in the practitioner's guide), add wild bootstrap intervals ([an introduction](https://www.stata.com/meeting/canada18/slides/canada18_Webb.pdf)). If author teams or datasets repeat, consider clustering by author, or two-way by study and country or dataset ([an example](https://ideas.repec.org/a/pal/imfecr/v65y2017i2d10.1057_s41308-016-0001-5.html)). Clustering does not fully solve sample overlap.

So that studies with many estimates do not dominate, add a robustness check weighting each estimate by the inverse of the number of estimates per study. We prefer this to a multilevel model, whose study random effects may correlate with study-level regressors. Study fixed effects rely on within-study variation and may not work well when many studies report one or two estimates, so complement them with between effects.

## Heterogeneity and model averaging

No theory tells you which of your many variables matter. Dropping insignificant ones one by one (general-to-specific) is not statistically valid as the main method. Bayesian model averaging (BMA) estimates models with many subsets of the variables, weights them by fit adjusted for size, and reports a posterior mean and inclusion probability for each variable. Keep the standard error among the regressors. It allows a model-based adjustment for publication bias, and estimates without a standard error cannot enter this analysis.

Our baseline priors are the unit information g-prior (worth one observation), the uniform model prior and the dilution prior. The dilution prior multiplies each model's weight by the determinant of the correlation matrix of its variables, so collinear models count for little. In an appendix, try other g-priors (BRIC, hyper-g) and the random model prior, which weights model sizes equally. In our experience the g-prior matters little. Code: [dilutBMS](https://gitlab.com/matmo/dilutbms2), [R code for the dilution prior](https://www.dropbox.com/s/p9yc0jfpfund6of/code_dillution.txt?dl=0), [example Stata code](https://meta-analysis.cz/students/students.do). On the dilution prior: [George (2010)](https://projecteuclid.org/euclid.imsc/1288099018), [this paper](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=933989), [this one](https://onlinelibrary.wiley.com/doi/abs/10.1002/jae.2365). MAER-Net has an overview of [model averaging](https://www.maer-net.org/post/model-averaging). Frequentist model averaging is a good robustness check, but it does not address collinearity, so check variance inflation factors there.

Weights. We prefer a baseline that is unweighted or weighted by the inverse of the number of estimates per study ([why](https://ideas.repec.org/a/bla/jecsur/v30y2016i5p944-981.html)). Precision weights vary within studies, so they create artificial variation in study-level variables such as citations, and they worsen collinearity. The practitioner's guide starts from inverse-variance weights instead. Show the alternative as a robustness check, agree the baseline with your supervisor, and put variants in an appendix.

## A best-practice estimate

The bottom line is the effect the literature implies once corrected for publication bias and misspecification. Choose values for the variables that describe best-practice data and methods, plug them into the BMA results, and set the standard error to zero. That is an extrapolation which approximately removes publication bias under the model's assumptions, not a guarantee. Give two versions: your own best practice, and one that takes a prominent, meticulous study as the benchmark (what would the mean be if every study used its data and methods?). See [meta-analysis.cz/skill](https://meta-analysis.cz/skill/).

## Writing and structure

The usual order is publication bias, heterogeneity, then best practice. Prepare figures and tables first so that they tell one story, such as "publication bias matters more than method choices." Write the results first. Write the conclusion, introduction and abstract last, and revise those three most.

The introduction must argue why the study is needed. A histogram of estimates, a plot showing they do not converge over time, or a demonstration of what is at stake when the parameter changes can help (see the [habit formation meta-analysis](https://meta-analysis.cz/habits/)). Consider citing (none is required) [Methods Matter](http://ftp.iza.org/dp11796.pdf), [The Power of Bias](https://onlinelibrary.wiley.com/doi/full/10.1111/ecoj.12461), [Andrews and Kasy](https://www.aeaweb.org/articles?id=10.1257/aer.20180310&&from=f), [Star Wars](https://www.aeaweb.org/articles?id=10.1257/app.20150044), [credibility in economics](https://www.aeaweb.org/articles?id=10.1257/jel.20171350), [editorial statements](https://academic.oup.com/ej/article-abstract/130/629/1226/5716665), [present bias](https://ideas.repec.org/p/rco/dpaper/168.html), and replicability studies ([1](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0225826), [2](https://www.nature.com/articles/s41562-018-0399-z), [3](https://science.sciencemag.org/content/351/6280/1433)).

Show a box plot of estimates by study, sorted by year of data. Define every variable in a table with its summary statistics, and use readable labels ("Institution control", not "INSTC"). Put the PRISMA diagram and data adjustments in appendices.

Read about writing first: The Elements of Style, Economical Writing, How to Write a Lot, John Cochrane's [writing tips](https://www.johnhcochrane.com/research-all/writing-tips-for-phd-studentsnbsp), "How to Write Applied Papers in Economics," and, for the ambitious, Williams's Style: Lessons in Clarity and Grace. Steven Pinker's [lecture](https://www.youtube.com/watch?v=OV5J6BfToSw) sums it up: write simply and know your audience. For well-written theses by earlier students, see [this one](https://dspace.cuni.cz/handle/20.500.11956/124595) and [this one](https://dspace.cuni.cz/handle/20.500.11956/94855). We recommend English and LaTeX, with the [IES template](https://is.cuni.cz/studium/predmety/index.php?do=download&did=245904&kod=JEM213).

## Answers to common criticisms

Each paragraph quotes a common criticism of meta-analysis and then answers it.

"Meta-analysis mixes apples and oranges." Meta-analysis in economics examines heterogeneous estimates. Control for differences in design, report subsamples, keep the topic narrow, and use a common metric.

"Low-quality studies should be excluded." Not necessarily. Any line between good and bad studies is arbitrary, so err on the side of inclusion, control for impact factor and citations, and let best practice weight the better methods.

"Some studies are missing." That is fine unless their results differ systematically. Publish the query and data.

"Preferred estimates deserve more weight." Many studies do not say which they prefer. Code it where they do, and show the preferred subsample as a robustness check.

"Estimates are not independent, and studies with many estimates dominate." Cluster by study, and weight by the inverse of the number of estimates per study as a robustness check.

"Precision weights are wrong because some methods understate standard errors." MAIVE instruments the standard error with sample size, and we prefer a baseline heterogeneity analysis without precision weights.

"Coding mistakes are inevitable." As in any dataset. Double-check random parts, and errors that are not systematic should not bias the results.

"Some sources of heterogeneity are omitted." A line must be drawn somewhere: in the 140 meta-analyses reviewed by Nelson and Kennedy (2009), the median uses 12 explanatory variables.

"Meta-analysis disagrees with large studies." In economics methods differ, and meta-analysis measures the effect of each method choice, which no single study can.
