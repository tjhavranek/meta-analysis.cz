---
category: "english"
media: "text"
outlet: "Springer Nature Research Communities"
url: "https://communities.springernature.com/posts/spurious-precision-in-meta-analysis"
date: "2025-09-27"
headline: "Spurious Precision in Meta-Analysis"
byline: "Zuzana Irsova"
word_count: "913"
perex: "Meta-analyses give more weight to precise studies. But what if the reported precision is spurious? We introduce MAIVE, a new estimator that tackles this problem."
body_note: "Behind-the-paper post k článku v Nature Communications. Přepsáno doslovně včetně překlepu „ratonale“ v druhém odstavci."
---

# Spurious Precision in Meta-Analysis

When I began working on meta-analyses two decades ago, I assumed the standard tools, developed mainly with experiments in mind, were safe to apply to observational research. Meta-analysis sounds straightforward: gather comparable estimates from many studies, give more weight to the precise ones, apply rigorous bias-correction techniques, and arrive at reliable averages across different contexts.

After dozens of meta-analyses in the social sciences, we kept noticing something odd. Reported effects were often too strongly correlated with their standard errors. And the correlation persisted even after we applied bias corrections using selection models. That worried us. If the link between estimated effects and precision arises beyond standard publication bias, the ratonale of inverse-variance weighting, the backbone of meta-analysis, starts to crumble.

## Spurious precision

One mechanism that can cause this problem is *spurious precision*. In theory, standard errors should measure study uncertainty. They are given to the researcher, and meta-analysts can use them as one indicator of study reliability. That is the clean textbook story.

In practice, reported precision is rarely that clean. Researchers make many choices: which controls to include, how to cluster standard errors, how to treat outliers, which estimation method to use. Ignoring heteroskedasticity often leads to artificially low standard errors, and commonly used cluster-robust standard errors are downward biased in small- and medium-sized samples.

Standard errors may also be underestimated in experiments due to violations of randomization assumptions, finite sample issues, or model misspecifications. And because significant results are easier to publish, there are incentives to favor smaller standard errors. A small effect with an even smaller standard error often looks better than a large but insignificant one.

## When existing methods fail

The funnel plot below illustrates what happens with spurious precision. Each dot represents a study's estimate against its standard error. Ideally, the funnel narrows symmetrically toward the true effect. Standard corrections account for asymmetry from publication bias or p-hacking on the effect size. But when precision is p-hacked as well, some estimates appear both larger and more precise than they really are: the hollow dots become solid black ones.

*Figure: Spurious precision makes some studies look more precise than reality, distorting meta-analysis results.*

These overly precise estimates (e.g. those that omit an important control variable) receive too much weight in meta-analysis. That is how spurious precision creeps in and distorts the overall result. In such cases, all standard inverse-variance weighting methods begin to break down.

Publication bias has been studied for decades, and correction methods like PET-PEESE or selection models are widely used. The catch is that they still rely heavily on reported precision and assume that the most precise estimates are unbiased. But if precision itself is p-hacked, these corrections do not necessarily solve the problem.

Consider the funnel plot above. Standard inverse-variance-weighted averages are biased upward. Funnel-plot corrections fail because they assume any p-hacking targets effect sizes rather than standard errors. And selection models break down as well, since they rely on the assumption that individual reported estimates are unbiased, an assumption violated under p-hacking.

Indeed, in some of our simulations with moderate spurious precision, simple unweighted averages ended up less biased than sophisticated bias-correction estimators.

## The idea behind MAIVE

This led us to MAIVE, the **Meta-Analysis Instrumental Variable Estimator**. The idea is simple. Reported standard errors may be biased, but sample size is much harder to p-hack. It is strongly (if imperfectly) linked to true precision and, in much of empirical research, authors typically use the largest feasible sample from the start. You can easily change controls, clustering, or estimation techniques; you usually cannot easily increase *N*.

MAIVE uses sample size as an instrument for precision. We keep the familiar funnel-based framework but rebuild it on a more robust foundation: predicted precision based on *N*, not reported precision alone, with confidence intervals considering prediction uncertainty. In simulations, MAIVE substantially reduced the overall bias (publication and p-hacking) compared to existing estimators. And in datasets with replication benchmarks, MAIVE moved meta-analytic results closer to the replications.

## Making it easy to use

To make MAIVE easy to apply, we built a simple web tool: [spuriousprecision.com](https://spuriousprecision.com/). Upload your dataset, click a button, and MAIVE runs in seconds, correcting your meta-analysis for publication bias, p-hacking, and spurious precision. If you just want to see MAIVE in action, the site offers a [demo dataset](https://spuriousprecision.com/demo) you can run instantly.

The tool supports study-level clustering (CR1, CR2, wild bootstrap), allows for extreme heterogeneity and weak instruments, and enables fixed-intercept multilevel specifications that account for within-study dependence and between-study differences in methods and quality. No coding, no setup, no R or Stata needed.

In the web tool we also included existing funnel-based methods — **PET-PEESE** and the **Endogenous Kink** model. Users can compare approaches side by side. This fills a gap: there are web tools for producing forest plots and basic meta-analysis models, but none that let you run advanced funnel-based corrections straight from the browser.

## What we learned

The biggest takeaway was how damaging spurious precision can be. Publication bias is well known, but the meta-analysis bias working through distorted standard errors can be just as harmful. Because almost every meta-analytic method relies on inverse-variance weights, the problem is potentially widespread.

We do not claim MAIVE is a cure-all. But it is a practical safeguard against a form of bias that existing methods largely ignore. With the web tool at [spuriousprecision.com](https://spuriousprecision.com/) (also available at [easymeta.org](http://easymeta.org/)), we hope MAIVE becomes a useful part of the toolbox for meta-analysis, whether in medicine, psychology, economics, or beyond.
