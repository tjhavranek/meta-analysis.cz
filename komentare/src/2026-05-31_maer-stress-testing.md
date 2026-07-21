---
category: "english"
media: "text"
outlet: "MAER-Net"
url: "https://www.maer-net.org/post/stress-testing-research-with-ai-now-super-easy-and-fully-automated"
date: "2026-05-31"
headline: "Stress-testing research with AI, now super easy and fully automated"
byline: "Tomáš Havránek"
word_count: "182"
---

# Stress-testing research with AI, now super easy and fully automated

Last December we shared a protocol for stress-testing (meta-)research by making AI models argue and keeping what survives. But running it by hand (opening several models, copying outputs back and forth) is a chore and our original automation via a GPT agent was not reliable.

So we automated the protocol using Claude Code. After a one-time setup it is a single sentence: you describe the task, and the skill (built with Zuzana Irsova) has Claude call OpenAI's Codex, runs the critique and synthesis rounds, and gives you a memo with the full trail of the debate.

We built it with meta-analysis in mind, but it works on any paper, proposal, or task. More generally, it is a simple way to have one AI check another's work. A worked example (WAIVE vs. MAIVE) is included so you can see what it produces.

The manual protocol (including a four-model version with Gemini and Grok in addition to Claude and GPT) is still here if you prefer copy-paste:

https://github.com/tjhavranek/research-audit-duel-protocol

Try it on something you are working on and tell us how we could improve it!
