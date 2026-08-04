<p class="byline">First published on <a href="https://www.linkedin.com/feed/update/urn%3Ali%3AugcPost%3A7483554931325542401" rel="external">LinkedIn</a>, 16 July 2026. Archived with the rest of our writing at <a href="https://meta-analysis.cz/komentare/posts/2026-07-16-does-multi-agent-debate-improve-ai-feedback/">/komentare/posts/2026-07-16-does-multi-agent-debate-improve-ai-feedback/</a>.</p>

Does multi-agent debate improve AI feedback on research papers?

Not in our experiment.

We just posted a pre-registered study in which authors ranked three AI reports on their own paper. The reports were blinded and came from three setups: a single prompt and two multi-agent tools. We expected the multi-agent tools to win.

We find:

1) Multi-agent debate does not help here. The single prompt beat both multi-agent tools, even though one of them spent about 30x the tokens.

2) If an independent AI model ranked the reports in the authors' place, it would put the most expensive multi-agent tool first.

3) Authors who recalled their real journal referee feedback usually ranked it above all the AI reports. In contrast, the AI judges almost always ranked the human feedback last.

I was also surprised by how little the author and AI rankings agree (correlation 0.14). Authors seem to have actually read the AI reports (!) and thought about them, not just used a chatbot to rank them.

Thanks to all 47 authors who participated!

Paper: [https://meta-analysis.cz/debate](https://meta-analysis.cz/debate)

Both multi-agent tools are open source:
[https://github.com/tjhavranek/mad-research](https://github.com/tjhavranek/mad-research)
[https://github.com/tjhavranek/paper-workshop](https://github.com/tjhavranek/paper-workshop)

<figure><img src="https://meta-analysis.cz/komentare/social-img/2026-07-16_p2_1.jpeg" alt="Title page of the working paper Does Multi-Agent Debate Improve AI Feedback on Research Papers? by Tomas Havranek and Zuzana Irsova, dated 16 July 2026." /></figure>

<figure><img src="https://meta-analysis.cz/komentare/social-img/2026-07-16_p2_2.jpeg" alt="Chart: author mean rank plotted against tokens per paper on a log scale. The single pass ranks best at roughly 25k tokens, while mad-research and paper-workshop rank worse despite spending about 200k and 800k tokens." /></figure>
