---
category: "english"
media: "text"
lang: "en"
outlet: "the 47 authors who took part in the experiment"
url: "https://meta-analysis.cz/debate"
url_label: "Project page and paper"
date: "2026-07-16"
headline: "Results of the AI report ranking experiment"
byline: "Tomáš Havránek, Zuzana Iršová Havránková"
genre: "correspondence"
word_count: "265"
context: "Rozesláno skrytou kopií autorům 44 meta-analýz, kteří v experimentu seřadili tři anonymizované AI posudky na svou vlastní práci; seznam příjemců zde neuvádíme."
body_note: "Dopis účastníkům experimentu, nikoli publikovaný text — proto je uveden jako korespondence. Shrnuje výsledky studie „Does Multi-Agent Debate Improve AI Feedback on Research Papers?“ v den, kdy vyšel preprint. Vše, na co odkazuje, je veřejné: preprint, CEPR Discussion Paper 21752, předregistrace na OSF, replikační balíček na Zenodu i oba nástroje na GitHubu. Text je otištěn beze změn."
---

# Results of the AI report ranking experiment

Dear colleague,

Thank you again for reading the AI reports on your paper and ranking them. Our experiment exists only because 47 authors were willing to do it! The paper is now out.

What we found:

- A report produced by a single prompt using one frontier model beat both elaborate multi-agent tools, even though one of the tools spent about 30 times the tokens. In our experiment, multi-agent debate did not help.
- Had an external AI model ranked the reports in your place, the most elaborate tool would have come first.
- Authors who recalled their real journal referee report usually ranked it above all the AI reports. In contrast, the AI judges almost always ranked that same human report last.
- Author rankings and the external AI model's rankings agree only weakly (correlation 0.14). Several of you told us the ranking took a lot of time, and we are grateful!

The two multi-agent tools from the experiment are open source: [mad-research](https://github.com/tjhavranek/mad-research) runs a cross-model adversarial audit, and [paper-workshop](https://github.com/tjhavranek/paper-workshop) runs a Claude-only expert workshop. They didn't beat a single prompt in our experiment, but both still produce detailed comments that can be useful as you revise your paper.

Links:

- Paper and project page: [meta-analysis.cz/debate](https://meta-analysis.cz/debate)
- CEPR Discussion Paper 21752: [cepr.org/publications/dp21752](https://cepr.org/publications/dp21752)
- mad-research: [github.com/tjhavranek/mad-research](https://github.com/tjhavranek/mad-research)
- paper-workshop: [github.com/tjhavranek/paper-workshop](https://github.com/tjhavranek/paper-workshop)
- Pre-registration (OSF): [https://doi.org/10.17605/OSF.IO/E6XGW](https://doi.org/10.17605/OSF.IO/E6XGW)
- Online supplement (OSF): [osf.io/7nfyb](https://osf.io/7nfyb)
- Replication package (Zenodo): [https://doi.org/10.5281/zenodo.21273528](https://doi.org/10.5281/zenodo.21273528)

*Havranek, T and Z Irsova (2026), "Does Multi-Agent Debate Improve AI Feedback on Research Papers?", CEPR Discussion Paper No. 21752. CEPR Press, Paris & London.*

Stay well,

Tomas Havranek and Zuzana Irsova
