<p class="byline">First published on <a href="https://www.maer-net.org/post/rebuilding-meta-analysis-cz-what-is-on-it-now" rel="external">MAER-Net</a>, 2 September 2026. Archived with the rest of our writing at <a href="https://meta-analysis.cz/komentare/maer-rebuilding-meta-analysis-cz/">/komentare/maer-rebuilding-meta-analysis-cz/</a>.</p>

This summer our website [meta-analysis.cz](https://meta-analysis.cz/) was hacked (thank you, AI!). It was our own fault. We hadn't changed the site in any serious way since 2015 and were still uploading files by FTP, one paper at a time. There was no central backup.

Rebuilding it by hand would have taken months. Instead we reconstructed it with Claude Code and Codex (thank you, AI!), working from old copies on the Wayback Machine and whatever we could still find on our hard drives. That took a few days. Cleaning up afterwards took a few weeks, and that's what this post is about, because the site we ended up with is quite different from the one we lost. Some of it may be useful to MAER-Net members.

**The papers are readable as web pages.** All 71 papers on the site are now there [in full as HTML](https://meta-analysis.cz/papers/), with the tables and 412 of the figures. A PDF is awkward on a phone and useless in a search box, and a language model reading one has to guess at column boundaries (it often gets a two-column layout wrong). Converting them was more work than we expected. AI agents pull text out of a PDF well, but they will also drop a clause at a page break, or hand you a table with two columns interleaved. So every page is gated against its PDF before it can go live: nothing on the page that isn't in the paper, every table and figure the paper prints present on the page, and an alarm when too much of the paper's vocabulary goes missing. Where the artwork wouldn't lift cleanly off the page, the caption stands alone and the picture stays in the PDF.

**The data are in one place, and in more than one format.** There are [46 datasets](https://meta-analysis.cz/datasets/), each as CSV and Parquet, with a codebook for every one. On top of those we built a pooled table: 49,845 estimate-level rows from 42 of our meta-analyses on a single grid. The effect, the standard error, the t-statistic and the precision sit in the same columns under the same names, and the sample size is there wherever the original paper reported one (it's missing entirely for seven of the 42, which matters if you plan to run MAIVE across all of them). It's convenient when you want to test a method against many literatures at once. The pooled table, the dataset index and the codebooks are also archived on Zenodo under a versioned DOI, so a replication package can cite version 1.2.0 and get exactly those files. The per-paper datasets stay on the site.

**The site is built to be read by machines as well as people.** There's an llms.txt giving the structure and an llms-full.txt carrying the whole corpus as plain text, a JSON API for the papers and the search index, and Croissant and Data Package descriptors for the data. None of this is exotic. It just means you can point an assistant at the site and get a real answer instead of a summary of the front page.

That last part has a payoff we didn't anticipate. If you want to run MAIVE, our estimator that corrects for p-hacking as well as publication bias, you no longer need to install anything or read a vignette first. You can say to your AI assistant:

> Run MAIVE on this dataset, following the protocol at meta-analysis.cz

and it will find [the how-to page](https://meta-analysis.cz/maive/how-to/) and follow it. If you'd rather click than prompt, the same methods are at [EasyMeta.org](https://www.easymeta.org/), together with PET-PEESE and the endogenous kink model.

The homepage now also states the three principles we'd defend as today's defaults, with a link to the method behind each. Correct for publication bias (RoBMA, by Bartos, Maier and Wagenmakers). Correct for p-hacking (MAIVE, by Irsova et al., and Mathur's RTMA). Cluster by study (CR2 standard errors, by Pustejovsky and Tipton).

Thanks to Zuzana Irsova for most of the decisions about what the site should contain, and to everyone who sent corrections after the first version went up.

If you find something broken, a number that doesn't match the paper it came from, or a figure cropped wrongly, please tell us. Readers have already caught several such things. Anything else we could improve?
