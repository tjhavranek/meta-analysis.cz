<p class="byline">First published on <a href="https://www.linkedin.com/feed/update/urn%3Ali%3Ashare%3A7500512259765448705" rel="external">LinkedIn</a>, 1 September 2026. Archived with the rest of our writing at <a href="https://meta-analysis.cz/komentare/posts/2026-09-01-rebuilding-meta-analysis-cz/">/komentare/posts/2026-09-01-rebuilding-meta-analysis-cz/</a>.</p>

A few weeks ago, our research website meta-analysis.cz was hacked (thank you, AI!).

It was our fault: we hadn't changed the site in a major way since 2015 and had little security. Prior to the hack, we were still uploading files by FTP for individual papers. We had no central backup.

Fortunately, Claude Code and Codex (thank you, AI!) proved very effective at reconstructing the site from old copies on the Wayback Machine and scattered files on our hard drives.

In the end, the hack was a blessing in disguise. Now we have the website on GitHub, the datasets are archived on Zenodo with a DOI, and we can edit everything much more easily. This also made it much easier for us to integrate meta-analysis.cz with [EasyMeta.org](https://www.easymeta.org/), which is a web-based tool for meta-analysis (including correction for p-hacking).

It also turns out that AI agents are very good at converting PDFs into clean HTML, so now we provide an HTML version of all our papers, plus of course complete data and code, and more.

So, for example, if you want to run [MAIVE](/maive/) (a meta-analysis technique that corrects for p-hacking), you can just ask your AI assistant: "Run MAIVE on this dataset, following the protocol at meta-analysis.cz"

Anything broken, or anything we could improve?

<figure><img src="https://meta-analysis.cz/komentare/social-img/2026-09-01_p1_1.png" alt="The “One file, every literature” panel from meta-analysis.cz: 49,845 estimate-level rows from 42 literatures in one table. Two histograms of absolute t-statistics. The left panel spans 0 to 6, peaks at 1,671 in the lowest bin and declines steadily, with a blue line marking 1.96 and dashed lines at 1.645 and 2.576. The right panel magnifies a 0.5-wide caliper from 1.71 to 2.21 on its own scale, where the bins above 1.96 are highlighted in blue and the tallest holds 646 estimates." /></figure>
