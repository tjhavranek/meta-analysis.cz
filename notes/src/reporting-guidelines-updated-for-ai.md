<p class="byline">First published on <a href="https://www.linkedin.com/feed/update/urn%3Ali%3Ashare%3A7460202147213791232" rel="external">LinkedIn</a>, 13 May 2026. Archived with the rest of our writing at <a href="https://meta-analysis.cz/komentare/posts/2026-05-13-reporting-guidelines-updated-for-ai/">/komentare/posts/2026-05-13-reporting-guidelines-updated-for-ai/</a>.</p>

Reporting Guidelines for Meta-Analysis in Economics, updated for AI, just published in the Journal of Economic Surveys:
[https://onlinelibrary.wiley.com/doi/10.1111/joes.70116](https://onlinelibrary.wiley.com/doi/10.1111/joes.70116)

Two practical points I would emphasize (my personal opinion), beyond the reporting checklist itself:

1️⃣ If you use AI for searching, screening, or coding, don't rely on a single model. Use meta-analysis thinking: each model is trained differently and on different data (think Claude vs. Grok). Even if one model strictly dominates, there will be useful information in the others, and you need to stress-test your favorite model brutally regardless. We have developed a simple Research Audit Protocol based on Multi-Agent Debate (MAD) for exactly this:
[https://github.com/tjhavranek/research-audit-duel-protocol/](https://github.com/tjhavranek/research-audit-duel-protocol/)

2️⃣ These guidelines intentionally do not recommend any particular methodology. We do so in our 2024 method guidelines ([https://onlinelibrary.wiley.com/doi/full/10.1111/joes.12595](https://onlinelibrary.wiley.com/doi/full/10.1111/joes.12595)). Brief update: I think the baseline meta-analysis technique is now Robust Bayesian Meta-Analysis (RoBMA) by Frantisek Bartos, Maximilian Maier, and Eric-Jan Wagenmakers -- a principled way to average over various bias-correction methods. But these methods don't address p-hacking, so RoBMA should be complemented with MAIVE (easy to apply via [https://easymeta.org](https://easymeta.org)) and RTMA (Maya Mathur).

The updated reporting guidelines were led by Nikolai Cook and co-authored with Frantisek Bartos, Pedro Bom, Sebastian Gechert, Klara Kantova, Jerome Geyer-Klingeberg, Dr.-Ing., Tomas Havranek, Martina Luskova, Matej Opatrny, Franz Prante, Heiko Rachinger, and Tom Stanley.

<figure><img src="https://meta-analysis.cz/komentare/social-img/2026-05-13_p9_1.jpeg" alt="Journal of Economic Surveys article header, open access: Reporting Guidelines for Meta-Analysis in Economics, Updated for AI, by Nikolai Cook, Frantisek Bartos, Pedro R. D. Bom, Sebastian Gechert, Klara Kantova, Jerome Geyer-Klingeberg, Tomas Havranek, Zuzana Irsova, Martina Luskova and others. First published 12 May 2026." /></figure>
