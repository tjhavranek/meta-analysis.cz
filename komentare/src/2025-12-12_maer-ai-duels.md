---
category: "english"
media: "text"
outlet: "MAER-Net"
url: "https://www.maer-net.org/post/ai_duel"
date: "2025-12-12"
headline: "Stress-Testing Meta-Research with AI Duels"
byline: "Zuzana Irsova, Tomáš Havránek"
word_count: "316"
---

# Stress-Testing Meta-Research with AI Duels

Many of us now use large language models for meta-analysis tasks like coding, short summaries, or quick checks. Where they become genuinely valuable for research, though, is not in producing a single clean answer. It is in creating **structured disagreement**: two models pushing on each other’s reasoning, with a researcher steering the process.

That is the idea behind the [**Research Audit Protocol (v1.7)**](https://github.com/tjhavranek/research-audit-duel-protocol). It is a structured, human-in-the-loop workflow that coordinates ChatGPT and Gemini in a deliberate “duel.” The goal is not AI approval. The goal is to generate the kinds of counterexamples, boundary conditions, and missing assumptions that a single model (and often a single human pass) would not surface. (Of course, advanced users can substitute Claude for the auditor role, or run the same workflow via an API-based multi-agent setup.)

**Why duels work** A normal chat is optimized for flow. A duel is optimized for scrutiny:

- **Anchor (ChatGPT):** Start with a full, file-grounded assessment before seeing any critique.
- **Duel (Gemini):** Probe hard for identification problems, hidden assumptions, and failure modes—and force specificity.
- **Synthesis (You + ChatGPT):** Map the disagreement (or convergence) and record what changed and why, so the final view is auditable.

**A MAER-Net Case Study: **[**WAIVE vs. MAIVE**](https://github.com/tjhavranek/research-audit-duel-protocol/tree/main/examples) As a proof of concept for meta-method work, we applied the protocol to an audit of the proposed **WAIVE** idea against the **MAIVE** framework. The duel did not just restate the two approaches. It forced us to pin down the key tension that matters for applied meta-analysis: when does downweighting “suspiciously precise” results reduce spurious precision, and when might it also penalize genuinely informative studies?

In other words, it pushed us to state the boundary conditions clearly—the kind of slow thinking that improves methods before they hit peer review.

**Resources**

- **Protocol (v1.7):** [GitHub Repository](https://github.com/tjhavranek/research-audit-duel-protocol)
- **Worked Example (WAIVE/MAIVE):** [Examples Folder](https://github.com/tjhavranek/research-audit-duel-protocol/tree/main/examples)
- **Permanent DOI:** [Zenodo](https://doi.org/10.5281/zenodo.17898869)
- **MAIVE Code:** [CRAN](https://cran.r-project.org/package=MAIVE) | [EasyMeta.org](https://easymeta.org/)
