<p class="byline">First published on <a href="https://www.linkedin.com/feed/update/urn%3Ali%3Ashare%3A7500512259765448705" rel="external">LinkedIn</a>, 1 September 2026. Archived with the rest of our writing at <a href="https://meta-analysis.cz/komentare/posts/2026-09-01-rebuilding-meta-analysis-cz/">/komentare/posts/2026-09-01-rebuilding-meta-analysis-cz/</a>.</p>

A few weeks ago, our research website meta-analysis.cz was hacked (thank you, AI!).

It was our fault: we hadn't changed the site in a major way since 2015 and had little security. Prior to the hack, we were still uploading files by FTP for individual papers. We had no central backup.

Fortunately, Claude Code and Codex (thank you, AI!) proved very effective at reconstructing the site from old copies on the Wayback Machine and scattered files on our hard drives.

In the end, the hack was a blessing in disguise. Now we have the website on GitHub, the datasets are archived on Zenodo with a DOI, and we can edit everything much more easily. This also made it much easier for us to integrate meta-analysis.cz with EasyMeta.org, which is a web-based tool for meta-analysis (including correction for p-hacking).

It also turns out that AI agents are very good at converting PDFs into clean HTML, so now we provide an HTML version of all our papers, plus of course complete data and code, and more.

So, for example, if you want to run MAIVE (a meta-analysis technique that corrects for p-hacking), you can just ask your AI assistant: "Run MAIVE on this dataset, following the protocol at meta-analysis.cz"

Anything broken, or anything we could improve?

The entire dataset, 50 thousand estimates from 42 literatures, is available here: [https://meta-analysis.cz/datasets/](https://meta-analysis.cz/datasets/)

All results are summarized here: [https://meta-analysis.cz/results/](https://meta-analysis.cz/results/)

And finally integration with EasyMeta.org: [https://meta-analysis.cz/maive/how-to/](https://meta-analysis.cz/maive/how-to/)
