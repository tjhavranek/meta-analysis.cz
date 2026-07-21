---
category: "english"
media: "text"
outlet: "MAER-Net"
url: "https://www.maer-net.org/post/ai-tools-for-meta-analysis"
date: "2025-07-30"
headline: "AI Tools for Meta-Analysis"
byline: "Tomáš Havránek"
word_count: "1033"
---

# AI Tools for Meta-Analysis

SearchAI Tools for Meta-AnalysisTomas HavranekJul 30, 20254 min readUpdated: Aug 19, 2025

I believe we’ve finally reached the point where AI tools can genuinely save a lot of time in meta-analysis during literature search and data collection. Below is a summary of what works well as of late July 2025. My experience is mostly with ChatGPT, so I’d be interested to hear what has worked for others. There must be better ways of doing this.

Start with deep research. The deep research function in ChatGPT helps you explore the literature before you begin the actual meta-analysis. It improves your understanding of the topic and also improves how useful ChatGPT replies become in later stages.

Refine search strategy using o3. Upload a few key papers and ask the o3 reasoning model to help you create a good Google Scholar query, also based on the deep research results. Go back and forth with it until the first page of results gives you mostly relevant studies.

Use ChatGPT Agent to scan results. The Agent can go through the first few hundred hits on Google Scholar and look at the abstracts. Ask it to flag papers that have at least a small chance of including the type of estimates you want. Example prompt: You are an expert in meta-analysis. For each abstract and based on all information you can find about the paper, say whether the paper reports, with more than 20 percent probability, quantitative estimates on the effect of beauty on labor market outcomes. Justify briefly.

Download flagged papers and filter again. The Agent can download some PDFs but usually not those behind paywalls, so you’ll have to do that part. Upload them to ChatGPT in batches of five. Ask whether the papers include effect size estimates and where in the paper they are located (table numbers or page references). Example prompt: For each of these papers, does it contain new empirical estimates of the effect of beauty on wages that I can use in a meta-analysis? Point to specific tables or pages.

Cross-check with other tools. Use ASReview or Semantic Scholar to double-check or supplement your results. ASReview is good if you want to train an active learning model on what counts as relevant in your case.

Use snowballing to expand the dataset. Ask the Agent to identify studies that are closely connected to those already in your list. For example, you can request the 100 most frequently cited papers by the studies in your dataset, or the 100 most recent papers that cite at least five of them. (The latter helps surface newer work that may be underrepresented in standard Google Scholar results due to low citation counts.) Then return to step 4 and screen these new candidates for relevance.

Upload papers and identify coding dimensions. Upload your included papers in small batches. Ask ChatGPT to identify the main ways in which the studies differ, both in terms of methodology and data. These differences typically become your coding dimensions (e.g. IV vs. RDD vs. DID, different professions examined, different time periods).

Use o3 to review the coding structure. Before you finalize the structure of your dataset, ask the o3 reasoning model to help you think through whether the coding dimensions you’ve selected make sense. Adjust if needed. Then fix the structure yourself. Keep all related chats in one project folder in ChatGPT.

Train the Agent on a few coded papers. Code five papers manually. Upload the PDFs and your data entries for three of them. Then ask ChatGPT Agent to extract the same information from the other two using GPT-4.1. Iterate your prompt until it works well, then continue in batches. Example prompt: Here are three PDFs and the corresponding rows from my Excel sheet. Learn the structure. These data are collected well and I want you to collect data from other papers. I will now send two new PDFs. Extract estimates of the beauty premium and the corresponding standard error. Collect information on the estimation method used, the definition of the beauty variable, definition of the earnings variable.

Use NotebookLM as a separate check. Upload the same batch to NotebookLM. Let it try the same extraction task independently. Compare the two outputs. Manually resolve discrepancies and randomly spot-check the rest.

As of July 2025, you still need competent humans to collect data for meta-analysis. All of the above should be complemented with your usual expertise. You have to check carefully what the AI returns. There’s still a risk of hallucinations, although with good prompting the risk is quite small. But where you needed four co-authors a year ago, now you probably need just two. And they can focus on more intellectually demanding tasks.

Let me know if you’ve found better ways to do this. I’m especially curious about tools outside the OpenAI ecosystem. Some colleagues report success with Claude, which seems strong in reasoning, but I haven’t tested it systematically yet.

Update (July 31, 2025): Several MAER-Net colleagues wrote to me about a promising new platform called otto-SR. It offers an end-to-end AI pipeline for systematic reviews, using tools like GPT-4.1 and o3 for screening and data extraction: essentially a polished, integrated version of the workflow I described above. It’s currently in preview only and not publicly available. While the early results sound more than impressive, otto-SR has been designed and benchmarked mainly for Cochrane-style reviews, which differ quite a bit from meta-analyses in economics. Still, it’s worth watching closely.

Update (August 19, 2025): ChatGPT now runs on GPT‑5. In the UI you pick Auto, Fast, or Thinking; I use GPT‑5 Thinking for screening and PDF extraction because it reasons longer and stays more consistent. Agent mode also feels steadier, but careful human checks are still essential. (If you work via API, OpenAI still documents separate “reasoning” models like o3, but that label isn’t shown in the ChatGPT menu.)

The Impact of the Journal of Economics Surveys has Notably Increased! Thanks to the support of MAER-Net members and their outstanding research, the Journal of Economics Surveys’ impact factor is now

Introduction to the MAER-Net Blog Content overview How to create a new account for the MAER-Net Blog. Access your profile . Subscribe to...
