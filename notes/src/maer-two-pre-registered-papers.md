<p class="byline">First published on <a href="https://www.maer-net.org/post/two-new-pre-registered-papers-outlier-decisions-in-meta-analysis-and-ai-feedback-on-meta" rel="external">MAER-Net</a>, 27 July 2026. Archived with the rest of our writing at <a href="https://meta-analysis.cz/komentare/maer-two-pre-registered-papers/">/komentare/maer-two-pre-registered-papers/</a>.</p>

My colleagues and I have two new pre-registered papers that may interest MAER-Net members.

### 1. Do decisions about outliers and influential effects matter?

([https://meta-analysis.cz/outliers](https://meta-analysis.cz/outliers), [https://arxiv.org/abs/2607.23174](https://arxiv.org/abs/2607.23174))

With Zuzana Irsova, Martina Luskova, and Tom Stanley, we recompute 358 behavioral science meta-analyses under five outlier treatments: do nothing, drop the most extreme estimate, remove studentized residuals above 3, winsorize at 5/95, and remove estimates with |DFBETAS| above 2/sqrt(k). Each runs under random effects and UWLS. All data, thresholds, and rules were registered before we saw any results.

The mean effect barely moves: the median absolute change in Cohen's d is at most 0.047. Interpretation moves more. In 11.5% of the meta-analyses at least one treatment changes statistical significance, and in 15.9% whether the effect reaches a smallest effect size of interest (|d| >= 0.20). Nearly all flips are in results already close to the boundary; strongly significant results essentially never change. Winsorizing changes the fewest conclusions, DFBETAS the most, and DFBETAS computed with UWLS flags the most influential estimates. Takeaway: pre-register the outlier rule and report results with and without it.

### 2. Does multi-agent debate improve AI feedback on research papers?

([https://meta-analysis.cz/debate](https://meta-analysis.cz/debate), [https://arxiv.org/abs/2607.14713](https://arxiv.org/abs/2607.14713))

Many of you took part in this experiment with Zuzana and me -- thank you! Authors of 44 economics meta-analyses ranked three blinded AI reports on their own paper: a single pass by a frontier model against two multi-agent debate tools we built and expected to win. The single pass won, by 0.66 rank points over mad-research and 0.57 over paper-workshop, although paper-workshop spends about thirty times the tokens. Authors who recalled their journal referee report usually placed it first and never last; the AI judges almost always put the same human report last. And an independent AI judge (Gemini) would have reversed the authors' verdict and picked the most expensive tool. Takeaway: an AI judge is not a substitute for the author, so be careful with LLM-as-a-judge designs.

Both tools are open source: [https://github.com/tjhavranek/mad-research](https://github.com/tjhavranek/mad-research) and [https://github.com/tjhavranek/paper-workshop](https://github.com/tjhavranek/paper-workshop)

Comments are welcome!!

<figure><img src="https://meta-analysis.cz/komentare/item-img/2026-07_outliers-table3.png" alt="Two-panel table. Panel A, statistical significance at two-sided p below 0.05, gives for random effects, UWLS and pooled each of four outlier treatments — drop-extreme, studentized residual above 3, winsorize 5/95, and DFBETAS above 2 over the square root of k — with the number of results turning significant, the number turning non-significant, and the combined percentage. Discordance runs from 2.23 percent for winsorizing under UWLS to 6.42 percent for DFBETAS under UWLS; at least one treatment changes significance in 7.7 percent of results, 55 of 715. Panel B repeats the layout for whether the effect reaches the smallest effect size of interest, absolute pooled d of at least 0.20: winsorizing changes the fewest, 1.68 to 1.96 percent, and DFBETAS the most, up to 7.54 percent; at least one treatment changes this in 10.3 percent of results, 74 of 715." /></figure>

<figure><img src="https://meta-analysis.cz/komentare/item-img/2026-07_debate-cost-vs-rank.png" alt="Scatter plot with error bars. Author mean rank, where 1 is most useful, runs down an inverted vertical axis; tokens per paper run along a logarithmic horizontal axis. The single pass is both best and cheapest, at a mean rank near 1.6 and roughly 25 thousand tokens, with an interval from about 1.4 to 1.8. mad-research sits near 2.25 at roughly 250 thousand tokens and paper-workshop near 2.15 at about 800 thousand tokens; the intervals of the two multi-agent tools overlap each other but not the single pass." /></figure>
