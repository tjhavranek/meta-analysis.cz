Probably not. We built two multi-agent debate tools, expected them to win, and they lost to a
single prompt. This note summarises what we did and what we found; the full paper, the
pre-registration, and the replication package are linked in the sidebar.

## The question

Feedback from large language models is now cheap enough that many researchers use it on their own
drafts. A natural conjecture is that spending more computation at inference time should produce
better feedback: let several agents argue, critique each other, and converge. We wanted to know
whether that conjecture survives contact with the people best placed to judge, namely the authors
of the papers being reviewed.

## What we did

We ran a pre-registered, identity-masked, within-paper experiment. For each of 44 meta-analyses in
economics, we generated three AI reports on that paper: one from a single pass by a frontier model,
and one from each of two multi-agent debate tools we had written ourselves,
[mad-research](https://github.com/tjhavranek/mad-research) and
[paper-workshop](https://github.com/tjhavranek/paper-workshop). All three were held to a common
length and template, so authors could not tell them apart by format. We then asked the authors to
rank the three reports by how useful each would be for improving their own paper. The study was
registered before any report was generated.

## What we found

Authors preferred the single pass. It beat *mad-research* by 0.66 rank points (95% CI 0.32 to 1.00)
and *paper-workshop* by 0.57 (0.16 to 0.95). This is despite *paper-workshop* spending roughly
thirty times the tokens: about 800,000 per paper against about 27,000 for the single pass.

Two further results struck us as more interesting than the headline.

First, authors who could recall the referee report they had received from a journal usually ranked
it above every AI report, and never ranked it last. When we asked AI judges to rank the same
material, they almost always put the human referee report last. Author and AI rankings agree only
weakly, with a correlation of 0.14.

Second, the choice of AI judge can reverse the finding. Gemini, the only judge whose model family
had written none of the reports, would have ranked *paper-workshop* first in the authors' place.
That is the opposite of what the authors themselves said. The warning here is narrow but sharp: an
AI judge is not a substitute for the author, and a judge drawn from the same family as one of the
systems under test is not a neutral instrument.

## What this does not show

We measured perceived usefulness, judged by authors, on finished papers. That is not the same as
measuring whether a report would improve a paper if acted on, and it is not the same as asking
whether AI should referee papers at all. Both are separate questions and we do not answer them
here. Our papers are meta-analyses in economics, so the result may not carry to other designs or
fields.

## Why we are publishing the negative result

We built these tools, we expected them to win, and we pre-registered the comparison before finding
out. Reporting the outcome either way was the point of registering it. Both tools remain open
source and are linked above; the finding is about test-time compute in this setting, not about
whether the tools are useful for anything.
