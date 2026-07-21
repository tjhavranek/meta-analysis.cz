---
category: "english"
media: "text"
outlet: "MAER-Net"
url: "https://www.maer-net.org/post/new-challenges-for-meta-analysis-attenuation-bias-p-hacking-preferred-estimates"
date: "2025-07-07"
headline: "New Challenges for Meta-Analysis: Attenuation Bias, P-Hacking, Preferred Estimates"
byline: "Tomáš Havránek"
word_count: "456"
---

# New Challenges for Meta-Analysis: Attenuation Bias, P-Hacking, Preferred Estimates

My colleagues and I have recently published or revised three meta-analyses, each raising issues that may matter for how we do meta-analysis in economics. I’d be grateful for thoughts or feedback -- here, by e-mail, or in person at our colloquium in Ottawa.

1. Attenuation bias (Review of Economics and Statistics, 2024)

Attenuation bias, aka regression dilution, arises when explanatory variables are measured with (classical random) error, biasing regression coefficients toward zero. We show that attenuation bias can be quantitatively important in estimating the elasticity of substitution between skilled and unskilled labor, although publication bias is still the bigger problem. We’re now working on comparing the two biases more broadly across meta-analyses in economics. Is it possible that on average, the two wrongs make a right? On a technical note, we also argue it’s risky to meta-analyze inverted regression coefficients -- especially common when elasticities are estimated primarily in their inverse form. Working with these transformed estimates can violate key meta-analysis assumptions. We should meta-analyze the originally reported regression coefficients.

2. P-hacking (JPE Microeconomics, revised & resubmitted)

Publication bias and p-hacking are commonly treated as the same problem, and in many settings, this is defensible: both are often observationally equivalent and create a correlation between effect sizes and standard errors. But the distinction can matter for methods. Selection models don’t handle p-hacking, while meta-regression (such as PET-PEESE) is robust to some forms. In this paper on the effect of financial incentives on performance we apply MAIVE, a new extension of PET-PEESE forthcoming in Nature Communications robust to more p-hacking strategies that work on precision (such as clustering choices or changing controls) as well as omitted-variable bias in meta-regression. Our results, in the Nature C and JPE Micro papers, suggest a need for more attention to the mechanisms behind selective reporting and for broader adoption of estimators robust to p-hacking, not just MAIVE but also RTMA developed by Maya Mathur.

3. Preferred estimates (Journal of Labor Economics, forthcoming)

Most economics meta-analyses collect all reported estimates -- a good default. But some estimates are clearly marked by the original authors as less or more trustworthy. The entire point of some papers is that a particular estimation strategy is wrong. In our class size meta-analysis, we classified estimates as “preferred,” “neutral,” or “discounted” according to how study authors described them. Preferred estimates were systematically larger, and this could not be explained by method choices or publication bias (based on tests we didn’t include in the final version of the paper because they were not relevant for JOLE readership though the finding could be relevant for MAER-Net). Takeaway: It’s worth coding which results are preferred in primary studies, as these author judgments may capture information that’s otherwise hard to quantify.
