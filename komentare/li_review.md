# LinkedIn posts — cleaned, for review

24 posts kept. Dates derived from LinkedIn's RELATIVE timestamps, so most are month-precision only.


==============================================================================
## post 2  |  2026-07-17 (day)  |  age=5d  |  182 words  |  EN

Does multi-agent debate improve AI feedback on research papers? Not in our experiment.

We just posted a pre-registered study in which authors ranked three AI reports on their own paper. The reports were blinded and came from three setups: a single prompt and two multi-agent tools. We expected the multi-agent tools to win.

We find:
1) Multi-agent debate does not help here. The single prompt beat both multi-agent tools, even though one of them spent about 30x the tokens.
2) If an independent AI model ranked the reports in the authors' place, it would put the most expensive multi-agent tool first.
3) Authors who recalled their real journal referee feedback usually ranked it above all the AI reports. In contrast, the AI judges almost always ranked the human feedback last.I was also surprised by how little the author and AI rankings agree (correlation 0.14). Authors seem to have actually read the AI reports (!) and thought about them, not just used a chatbot to rank them.

Thanks to all 47 authors who participated!

Paper: https://lnkd.in/d7YsNxWc

Both multi-agent tools are open source:https://lnkd.in/dtGSi8zP

https://lnkd.in/dk5NQpcE

==============================================================================
## post 3  |  2026-07-08 (day)  |  age=2w  |  71 words  |  EN

This week I have been at Stanford, spending my days working and my evenings at Nitoboxing in Palo Alto. Honestly, it was exactly what I needed!

Research is intense, travel tiring, and sometimes the best way to get your head straight is not another coffee, but gloves and sweat.

Huge thanks to Mark and the whole team for the warm welcome, great energy, and for helping me reset after long days.

==============================================================================
## post 4  |  2026-07-08 (day)  |  age=2w  |  57 words  |  EN

Proud to be affiliated with Stanford METRICS. Few groups have done more for reproducibility and research integrity than John Ioannidis and his team, and it's a pleasure to meet in person some of the postdocs behind so much of the work: Alejandro Sandoval Lentisco, Quentin Loisel, and Sarah Tanveer.

Happy Fourth of July, and happy 250th, America!!

==============================================================================
## post 5  |  2026-06-24 (day)  |  age=4w  |  150 words  |  EN

If you plan to work on your ERC proposal this summer, the following tool might help you:https://lnkd.in/gAN6S747

It checks your draft at various stages against the official ERC evaluation criteria and rules, flags the routine weak spots, gives you tips, etc. The idea is to clear the easy problems before you ask humans, not to replace them.

Just read the privacy note first: use a paid model with training turned off, or don't paste anything sensitive.

We built this with Tomas Havranek, who was on the ERC Advanced economics panel in 2020 and is involved in the expert group supporting ERC applicants in Czechia.

You might also check our related tools: mad-research (https://lnkd.in/dtGSi8zP), which stress-tests your paper or proposal with a Claude/Codex debate, and paper-workshop (https://lnkd.in/dk5NQpcE), which simulates an expert workshop on your stuff.

If you have any comments or feedback, we'll be happy to incorporate them into the tools.

==============================================================================
## post 6  |  2026-06-01 (month)  |  age=1mo  |  110 words  |  EN

Imagine a panel of the world's leading experts, assembled for your research paper, arguing it out from rival schools and then revising it themselves.

Well, that's not possible. But we built an approximation with Claude Code, and it now uses the full power of Anthropic's Mythos-class model, Claude Fable 5.

Below is the skill, open and free. You give it your paper, ideally with the data and draft code. You get a stress test of your paper + a revision in track changes + a replication package. We ran it end to end on colleagues' papers and our own paper accepted at JPE Micro, Stata and R re-runs included. Enjoy:https://lnkd.in/dk5NQpcE

==============================================================================
## post 7  |  2026-06-01 (month)  |  age=1mo  |  144 words  |  CZ

Nesehnali jste už lístky na Smetanova Litomyšl, ale přesto chcete zakusit genius loci perly východních Čech? Snadná pomoc!

Děti připravily festivalové vydání své závodní hry z Litomyšle:https://lnkd.in/gvEF-zD7

Závodíte v litomyšlských ulicích s dalším hráčem na počítači, nebo na mobilu s botem. Můžete střílet, sbírat lepší zbraně, ničit budovy (např. školu).

Pozor na bomby a zombie Bedřichy!

Hru postavily děti samy v zimě s Claude Code za několik hodin (ač pak trvaly na mnoha hodinách testování 😉). Jasně, vypadá jako z 80. let. Ale je to jen malá ukázka toho, co současné agentní AI systémy dokážou, a není to zdaleka jen o kódování.

Pokud jste Claude Code nebo Codex ještě nezkoušeli, určitě stojí za to nainstalovat, ať už se živíte čímkoli. Nejtěžší je překonat počáteční strach. Ono je to nakonec jednoduché.

Detaily hry tady:https://lnkd.in/gVmACuyi Play Remaining time 0:01 1x Playback speed Unmute Turn fullscreen on

==============================================================================
## post 8  |  2026-06-01 (month)  |  age=1mo  |  101 words  |  EN

Do you know that Claude Code can use Codex to stress test its work?I had both installed and used them interchangeably: for some tasks, one seems to be better, and vice versa. Also, sometimes I hit usage limit in one, so I continue in the other.

This can be automated easily: work from Claude Code and call Codex when needed. Here is the Claude skill, applied to stress-testing research:https://lnkd.in/dtGSi8zP

This builds on our previous manual protocols for using different AI models to test research ideas or papers:https://lnkd.in/dRwKz63g

Does the skill work for you? What should we change? Should we add Gemini?

==============================================================================
## post 9  |  2026-05-01 (month)  |  age=2mo  |  212 words  |  CZ

Reporting Guidelines for Meta-Analysis in Economics, updated for AI, just published in the Journal of Economic Surveys:https://lnkd.in/d_BciGAd

Two practical points I would emphasize (my personal opinion), beyond the reporting checklist itself:1️⃣ If you use AI for searching, screening, or coding, don't rely on a single model. Use meta-analysis thinking: each model is trained differently and on different data (think Claude vs. Grok). Even if one model strictly dominates, there will be useful information in the others, and you need to stress-test your favorite model brutally regardless. We have developed a simple Research Audit Protocol based on Multi-Agent Debate (MAD) for exactly this:https://lnkd.in/d63DFbPz

2️⃣ These guidelines intentionally do not recommend any particular methodology. We do so in our 2024 method guidelines (https://lnkd.in/dPcDR7Gr). Brief update: I think the baseline meta-analysis technique is now Robust Bayesian Meta-Analysis (RoBMA) by František Bartoš, Maximilian Maier, and Eric-Jan Wagenmakers -
- a principled way to average over various bias-correction methods. But these methods don't address p-hacking, so RoBMA should be complemented with MAIVE (easy to apply via https://easymeta.org) and RTMA (Maya Mathur).

The updated reporting guidelines were led by Nikolai Cook and co-authored with František Bartoš, Pedro Bom, Sebastian Gechert, Klára Kantová, Jerome Geyer-Klingeberg, Dr.-Ing., Tomas Havranek, Martina Lušková, Matej Opatrny, Franz Prante, Heiko Rachinger, and Tom Stanley.

==============================================================================
## post 10  |  2026-05-01 (month)  |  age=None  |  233 words  |  CZ
<!-- date: no timestamp; boxed between the 2mo and 3mo posts -->

Will our results change if we redo the meta-analysis from scratch?

We just pre-registered a big revision of our meta-analysis on beauty and professional success:https://lnkd.in/dBSAB5N2

The current paper follows standards commonly used in economics meta-analysis. For the revision we decided to do the search and data collection differently, following multidisciplinary systematic-review practice: a librarian-designed multi-database search, dual screening, coding reliability checks, PRISMA documentation, and a full audit trail.A nice side effect is that this becomes a natural experiment on our own work. Honestly, I'm curious how much it will move the results.

The amazing Martina Lušková joined the team to help lead study selection and coding, and we are working with a librarian at the University of Amsterdam on the search strategy.

In the current version we find that the effect of beauty on earnings is smaller than commonly thought once you correct for publication bias and p-hacking, and smaller still when more weight is given to studies that control for cognitive ability. The one clear exception is sex workers. For politicians, the beauty premium mostly goes away after correction.

To make the comparison fully transparent, we also uploaded the current paper, data, and code to the registration.

We should do much more pre-registration in observational research. It doesn't fully prevent p-hacking, but it helps a lot and the cost is low.

Co-authored with Tomas Havranek, František Bartoš, Xenia Bortnikova, and Martina Lušková

==============================================================================
## post 11  |  2026-04-01 (month)  |  age=3mo  |  161 words  |  EN

Not an easy task, but in a new note just out in the Journal of Economic Surveys we try to set a basic floor on the use of AI in meta-analysis.https://lnkd.in/dZNGRfJb

Short version:
🔹 Human leadership. Humans direct the search, coding, and analysis, and record where they override the AI.
🔹 Human accountability. AI cannot be a co-author. If your name is on the paper, the errors are yours.
🔹 Human auditing. AI can serve as one of the coders, as long as humans audit at least 10% of screening records and 10% of coded studies (or 100 and 20, whichever is larger), and report a measure of agreement.
🔹 Human disclosure. Anything that shapes search, screening, coding, analysis, or conclusions should be disclosed, with prompts and model versions saved.

The effort was led by the amazing Nikolai Cook. It will be periodically updated at maer-net.org.

For the full discussion of how we agreed on these guidelines (scroll down to comments):https://lnkd.in/dME6se-W

==============================================================================
## post 12  |  2026-04-01 (month)  |  age=3mo  |  58 words  |  EN  |  RESHARE-TRIMMED

It was fun to be (a very small) part of the amazing team led by Abel Brodeur. The numbers look great, but note that we replicate papers in journals that have mandatory data and code sharing. So: share your data and code! And while you're at it, pre-register your papers and upload pre-analysis plans. This is the way!

==============================================================================
## post 13  |  2026-04-01 (month)  |  age=3mo  |  123 words  |  EN

Top 7 non-fiction books I recommend.

📚Not an endorsement of everything in these books, but I learned a great deal about economics, history, and politics.1️⃣ Bourgeois Equality (McCloskey): How the West got rich.2️⃣ In the Garden of Beasts (Larson): An American family in 1930s Berlin, watching a society die.3️⃣ Recession (Tyler Goodspeed): Why economies shrink. Excellent new book.4️⃣ Cicero (Everitt): The life of arguably the greatest statesman the West ever produced.5️⃣ Red Dawn Over China (Dikötter): How China became communist.6️⃣ The Lives of the Caesars (Suetonius): The most readable classical text I know. Reads like a novel.7️⃣ The Fiscal Theory of the Price Level (John H. Cochrane): A bold, rigorous book on modern macroeconomics.

What's the best non-fiction book you've read this year?

==============================================================================
## post 14  |  2026-03-01 (month)  |  age=4mo  |  126 words  |  EN

Two AI models dueling worked. Four models debating works better.

We updated our research audit protocol. The new version (MAD v2.
0) uses ChatGPT, Claude, Gemini, and Grok in structured adversarial rounds:1️⃣ Independent critique — no model sees the others, every claim grounded in the document.2️⃣ Cross-examination — each model attacks the weakest peer arguments.3️⃣ Final arbiter synthesizes what survived.

No code needed. Copy-paste prompts. Free model versions work (just register for each model).

Advanced users: the entire workflow can be automated via the models' APIs using frameworks like AutoGen, LangGraph, or CrewAI.

Use it for high-stakes documents: stress-testing your papers, grant proposals, referee reports.

Protocol (GitHub): 👉 https://lnkd.in/dRwKz63g GitHub
- tjhavranek/research-audit-duel-protocol: Human-in-the-loop adversarial workflows for high-stakes research audit: from ChatGPT-Gemini duels to 4-model MAD. github.com

==============================================================================
## post 15  |  2026-03-01 (month)  |  age=4mo  |  92 words  |  CZ

Doporučuji všem rodičům včas testovat děti na cukrovku. Nám to bohužel vyšlo jednou pozitivní, ale díky tomu testu + moderní medicíně můžete nástup nemoci oddálit o několik let.

Včasný test = šance na roky navíc bez inzulinu.

Díky Barbora Berka a Natálie Chrástecká za skvělý přístup v Motole.

Díky Jan Hrušovský za hezký rozhovor s mým manželem, který poprvé na kameru mluvil o něčem jiném než o ekonomii (což je většinou velmi ... poutavé 😉 ).https://lnkd.in/duWtcSbA Když screening odhalí cukrovku u dítěte: Nemá smysl se vztekat, říká tatínek malého diabetika youtube.com 18

==============================================================================
## post 16  |  2026-03-01 (month)  |  age=4mo  |  223 words  |  CZ

Meta-analyses should try to correct not just for publication bias, but also for p-hacking.

Some estimates are more likely to be reported than others, so every good summary of research should correct for this publication bias. In case you're wondering — yes, this can be done, there are dozens of methods and decades of research on this. There is even a great way to put these different correction techniques together: see RoBMA by František Bartoš and colleagues.

The problem is that these techniques assume that the reported estimates are individually unbiased. This is a strong assumption, as researchers can tweak models (consciously or unconsciously) to get more "sensible" results. This is called p-hacking. Most of us do it.

In our recent Nature Communications paper we show that under some forms of p-hacking, classical models correcting for publication bias can actually be more biased than a simple average of published estimates.

As far as I know, there are only two meta-analysis corrections for (some forms of) p-hacking: our MAIVE (from the Nature Comms paper) and RTMA by Maya Mathur. If you know of more, please let me know in the comments!

If you want to see MAIVE and RTMA applied, take a look at our meta-analysis of the beauty premium. Spoiler: apart from the sex industry, beauty doesn't matter much in the labor market.

==============================================================================
## post 17  |  2026-02-01 (month)  |  age=5mo  |  22 words  |  CZ  |  RESHARE-TRIMMED

Congratulations to Martin! I am very sorry I couldn't be there. I love my hometown Rožňava. Central European Labour Studies Institute (CELSI)

==============================================================================
## post 19  |  2026-02-01 (month)  |  age=5mo  |  108 words  |  EN

A small experiment at home: our kids (8-1
2) were sick and bored, so we introduced them to Claude Code.

Two hours later, they had a working browser racing game set in our hometown. They did almost everything themselves; we helped with publishing it on GitHub.

The graphics are… charmingly 1980s. But it runs smoothly and it’s fun.

Takeaway for me: if you’re a researcher, it’s worth setting aside an hour to play with these tools -
- you might be surprised what you can do now.(Link to the game in the first comment!)hashtag#ResearchTools hashtag#ClaudeCode hashtag#Litomysl Play Remaining time 0:14 1x Playback speed Unmute Turn fullscreen on 60

==============================================================================
## post 20  |  2026-02-01 (month)  |  age=5mo  |  141 words  |  EN

A browser-based tool for correcting publication bias and p-hacking.

We built EasyMeta.org to make bias-corrected meta-analysis easier to run. Upload your dataset and benchmark your conclusions against modern corrections -
- directly in your browser.

Why: Selective reporting can distort what enters the literature and how results are reported, but applying corrections often requires specialized software or a complex workflow.

What it offers:
• Bias corrections: MAIVE (our Nature Communications method) plus benchmarks like PET-PEESE.
• Robust inference: options for clustering and different data structures.
• Minimal setup: free, open, no installation, no coding.
• Reproducibility: export R code for the results you generate.

Swipe through the four slides to see the workflow.

Try it with your own data: 👉 easymeta.org (https://www.easymeta.org/)With Pedro Bom, Tomas Havranek, Heiko Rachinger, and Petr Čalahashtag#MetaAnalysis hashtag#OpenScience hashtag#ResearchMethods hashtag#Econometrics hashtag#Statistics Your document has finished loading 41

==============================================================================
## post 22  |  2025-12-31 (day)  |  age=None  |  136 words  |  CZ
<!-- date: says "v dnešních HN"; that op-ed is archived at this date -->

Jak vytěžit z AI maximum?

Nechte modely bojovat mezi sebou. 🧠

🤖V dnešních Hospodářské noviny ukazujeme jednoduchý, ale účinný postup, jak pracovat efektivněji s umělou inteligencí.

Místo jedné odpovědi: duel AI modelů.

ChatGPT vs. Gemini (nebo jiná kombinace).
🔹 Jeden model dostane roli kreativního vizionáře, který nápad rozvíjí.
🔹 Druhý je ďáblův advokát
– systematicky hledá faktické i logické chyby.
🔹 Modely si navzájem napadají výstupy a opravují se.

Výsledek?

👉 Méně halucinací.

👉 Tvrdší „stress test“ nápadů.

👉 Kvalitnější výstup než od jednoho modelu.

Nemáte předplatné ChatGPT?

Žádný problém. Duel zvládnete i manuálně
– stačí otevřít vedle sebe dva zdarma dostupné AI modely, dát jim stejná data a protichůdné role a jejich odpovědi mezi sebou křížit. Po několika kolech už dává smysl výstupy číst.🔗 Odemčený článek v HN:https://lnkd.in/dBbUetrP

🔗 Duelový protokol (prompt + návod):https://lnkd.in/dRwKz63g 34

==============================================================================
## post 23  |  2026-01-01 (month)  |  age=6mo  |  41 words  |  EN  |  RESHARE-TRIMMED

I still love Slovakia and Gemer. When our kids were born, one of the first things my husband did was go to the Slovak embassy in Prague and arrange Slovak citizenship for them. I hope I’m wrong in this interview. Startitup

==============================================================================
## post 24  |  2025-12-01 (month)  |  age=7mo  |  165 words  |  EN

For deep analytical work, I don’t use one AI model. I make them duel.

For thinking-intensive tasks (research, strategy, due diligence) a single AI model often converges too fast. It sounds convincing but skips edge cases and hidden assumptions.

So Tomas Havranek and I formalized a workflow to create structured disagreement:
🔹 Anchor (ChatGPT): Writes a first-pass assessment grounded in the files.
🔹 Audit (Gemini): Actively tries to break it (logic gaps, counterexamples, failure modes). ChatGPT defends. The duel iterates.
🔹 Synthesis (You): You analyze the conflict to see what survives.

The output is not “AI approval.” It is a clearer map of risks, boundary conditions, and what you must verify.

Advanced users: You can swap the auditor for Claude or automate this via API (MAD).

For everyone else: no code needed. You can copy-paste the protocol and try it via ChatGPT Agent.

Protocol (GitHub): 👉 https://lnkd.in/dRwKz63g Research example: 👉 https://lnkd.in/dw98RKuW

hashtag#AI hashtag#DecisionMaking hashtag#CriticalThinking hashtag#Productivity hashtag#Research The Adversarial Advantage: AI Duels for Meta-Analysis maer-net.org 69

==============================================================================
## post 26  |  2025-12-01 (month)  |  age=7mo  |  136 words  |  EN

🔎 MAIVE is now on CRAN: Better tools for trustworthy meta-analysisMeta-analysis is one of the key pillars of evidence-based research. It combines results from many studies to give us a clearer, more reliable answer.

But in observational research, studies can sometimes appear too precise --not because the evidence is strong, but because of method choices, selective reporting, or p-hacking. This can distort the final meta-analytic conclusion.MAIVE helps address this.

You can now install MAIVE directly in R:install.packages("MAIVE")Or try it instantly in your browser (no coding needed): 🖥
️ https://www.easymeta.orgMore details: 📦 CRAN package: https://lnkd.in/dQ7XjiAq 📄 Nature Communications article: https://lnkd.in/eFfrP6H2 📰 Blog overview: https://lnkd.in/ejkgbU6X

A big thank-you to Petr Čala, who built the MAIVE web app and prepared the CRAN release. His work makes high-quality meta-analysis methods accessible.hashtag#metaanalysis hashtag#OpenScience hashtag#researchmethods hashtag#RStats Spurious Precision in Meta-Analysis communities.springernature.com 34

==============================================================================
## post 27  |  2025-11-01 (month)  |  age=8mo  |  89 words  |  EN

🔎 New in Nature Communications: “Spurious precision in meta-analysis of observational research.”

Sometimes studies appear too precise because their reported uncertainty reflects method choices rather than real evidence strength. This can mislead meta-analyses.

We introduce MAIVE, a simple way to detect and correct such bias, including publication bias and p-hacking.🖥
️ Try it in your browser (free, no coding): https://www.easymeta.org 📄 Paper: https://lnkd.in/eFfrP6H2 📰 Blog: https://lnkd.in/ejkgbU6X

— Kudos to my great co-authors Pedro Bom, Tomas Havranek, and Heiko Rachinger hashtag#metaanalysis hashtag#researchmethods hashtag#OpenScience hashtag#NatureCommunications Spurious Precision in Meta-Analysis communities.springernature.com 38

==============================================================================
## post 30  |  2023-07-01 (month)  |  age=3yr  |  61 words  |  CZ

Přátelé,každoročně věnuje skupina českých lékařů měsíce svého života budování nemocnice a pomoci nemocným v keňském Itibu. Možná je znáte z filmu Daleko za sluncem. Některé dobrovolníky osobně znám; zrovna se snaží o sbírku na přístroj, který by zlepšil či zachránil život mnohým. Sbírka měsíce stagnuje, cíl je daleko. Prosím pomozte jim pomáhat nahttps://lnkd.in/eR_cCtDx

Jako každá legit donation i tahle je tax-deductible.