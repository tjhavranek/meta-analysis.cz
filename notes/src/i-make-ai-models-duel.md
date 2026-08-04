<p class="byline">First published on <a href="https://www.linkedin.com/feed/update/urn%3Ali%3Ashare%3A7405164270306504704" rel="external">LinkedIn</a>, 12 December 2025. Archived with the rest of our writing at <a href="https://meta-analysis.cz/komentare/posts/2025-12-12-i-make-ai-models-duel/">/komentare/posts/2025-12-12-i-make-ai-models-duel/</a>.</p>

For deep analytical work, I don’t use one AI model. I make them duel.

For thinking-intensive tasks (research, strategy, due diligence) a single AI model often converges too fast. It sounds convincing but skips edge cases and hidden assumptions.

So Tomas Havranek and I formalized a workflow to create structured disagreement:

🔹 Anchor (ChatGPT): Writes a first-pass assessment grounded in the files. 🔹 Audit (Gemini): Actively tries to break it (logic gaps, counterexamples, failure modes). ChatGPT defends. The duel iterates. 🔹 Synthesis (You): You analyze the conflict to see what survives.

The output is not “AI approval.” It is a clearer map of risks, boundary conditions, and what you must verify.

Advanced users: You can swap the auditor for Claude or automate this via API (MAD).

For everyone else: no code needed. You can copy-paste the protocol and try it via ChatGPT Agent.

Protocol (GitHub): 👉 [https://github.com/tjhavranek/research-audit-duel-protocol](https://github.com/tjhavranek/research-audit-duel-protocol)
Research example: 👉 [https://www.maer-net.org/post/ai_duel](https://www.maer-net.org/post/ai_duel)
