# GPT review of `claude/cluster-se-wording-ktm76t`

Baseline reviewed: `bc2c1b12a25082194da31e4ad04cb89bd042b49f`
Branch reviewed: `claude/cluster-se-wording-ktm76t` (28 commits ahead at review time)

## Verdict

**Do not merge the full-text batch yet.** The direction is very good, and several pieces are already strong, but there are two systemic correctness/gating defects and several systematic HTML defects that should be fixed once in the generator and then regenerated across the corpus.

The existing hand-built **Practitioner’s Guide** and **MAIVE** pages remain good; I found no substantive regression in either. The problems below are concentrated in the newly generated paper editions.

## P0 — fix before merge

### 1. `build_paper_page.py` overwrites the paper masthead with the last TOC heading

This is a real generator bug, not a paper-specific typo.

`build_page()` starts with the project/paper label, but the TOC loop reuses the same variable name `label`; the final template then uses that overwritten value as `short` in the masthead.

Observed outputs include:

- `incentives/paper/`: masthead = **ENDNOTES**
- `armington/paper/`: masthead = **REFERENCES**
- `beauty/paper/`: masthead = **Supplementary Information (for Online Publication)**
- `inflation/paper/`: masthead = **B.8. Forest plot by primary study (full sample)**

Fix the variable shadowing (`toc_label` or equivalent), regenerate all generated pages, and add a regression test asserting that the masthead is the intended project/paper label and is unaffected by TOC contents.

### 2. The advertised “nothing missing” verifier does not actually fail on missing prose

`tools/verify_transcript.py` says that a changed/dropped prose word can gate the build, but the exit logic fails only on **invented** prose. `lost` words are computed and reported but do not make the command fail; ordered differences also return success.

`tools/check_paper_pages.py` then uses only a very loose total-word ratio for omissions:

- fail below 45%
- note below 60%

That cannot support a site-wide claim that these are mechanically verified “full text” editions. A substantial omitted section can pass. Table/figure-number census does not solve prose completeness.

Please make material running-prose omissions a blocking failure. This needs care because PDF text layers also contain table/equation/figure/front-matter noise, so I would not simply fail on every raw `lost` token. A section-by-section or contiguous-prose check with explicit exclusions would be much stronger. At minimum, the current 45% threshold should not be treated as a completeness guarantee.

## P1 — systematic export problems

### 3. The transcript delimiter `|` is leaking into visible section headings

The TOC correctly turns `## 1 | Introduction` into `1. Introduction`, but the body renders the raw heading as `1 | Introduction`. This occurs across generated pages (`incentives`, `beauty`, `inflation`, `outliers`, etc.).

The current regression test explicitly requires the pipe to remain:

`a section heading keeps its printed pipe`

I think that test has the direction backwards. The pipe is structural transcript syntax, not publication text. Render the body heading using the same normalized form as the TOC (or store the exact source heading separately if needed), then invert the regression test.

### 4. Nested TOC lists are malformed HTML

Generated TOCs emit a nested `<ol>` as a sibling of the parent `<li>`, e.g. conceptually:

```html
<li>2. Results</li>
<ol>...</ol>
<li>3. Discussion</li>
```

The child `<ol>` should be inside the owning `<li>`. This is visible in `armington`, `beauty`, `outliers`, `inflation`, and likely any paper with subsections. Fix once in the TOC renderer and add a structural test.

### 5. `/papers/` promises “the figures as images”, but the system deliberately accepts caption-only figures

The hub says the 53 papers contain “the figures as images”. The generator/CSS, however, explicitly supports `fig-inpdf`, and the checker counts a figure caption as a present figure even when no `<img>` exists.

Concrete examples:

- `armington`: Figure 1 is caption-only; only Figures 2–3 have image files.
- `beauty`: Figure 1 is caption-only; Figure 2 has an image.
- `inflation`: Figures 1, 2, 3 and 5 are caption-only; Figure 4 has an image.

Either finish the figure extraction so the public promise is true (my preference for pages advertised as full HTML editions), or weaken the hub wording to say that artwork is reproduced where available and captions are retained otherwise. If keeping the stronger promise, make the page checker require an actual `<img>` for every figure number.

`tools/audit_figures.py` is a useful sanity check for obvious prose/sliver crops, but it does not by itself prove that a crop is the correct figure; keep a targeted visual check for the extracted artwork.

### 6. `beauty` still looks like a mechanical draft transcript, not a finished semantic HTML edition

The words I sampled against the source PDF are faithful, so this is not an invention problem. But the transcript was not finished after mechanical extraction:

- title, authors, affiliations, date, `Abstract`, abstract text and keywords appear as ordinary body `<p>` elements instead of structured front matter / abstract;
- many PDF display lines become separate paragraphs because blank lines survived between wrapped source lines;
- Figure 1 artwork is absent.

The source phrase “— Figure 1 around here —” really is in the PDF, so retaining it is defensible for strict fidelity; I am **not** flagging that phrase as invented. The problem is the unfinished paragraph/front-matter structure around it.

Please finish/reflow the Beauty transcript and regenerate before calling it a publication-quality HTML edition.

## P2 — worthwhile before publishing the corpus

### 7. Generated paper pages should have an article `<h1>`

The established MAIVE page has a proper article `<h1>` and byline. The generated pages generally jump from the site masthead to attribution/TOC/front matter without a visible article-title `<h1>`. This is weaker semantically and for accessibility/SEO, especially while the masthead bug exists. Add an `<h1>` for the paper title in the generated template.

### 8. Numeric citation ranges are not links

The inline parser links comma-separated numeric markers, but a range such as `^{4–6}` is emitted as plain `<sup class="cite">4–6</sup>`. Example: `outliers/paper/`. Thus “references as links” is not consistently true.

Expand/link numeric ranges (or otherwise make the range navigable) and add a regression test.

### 9. `/papers/` calls all 53 items “meta-analyses”

The list includes methodology/review/experiment papers such as MAIVE, the Practitioner’s Guide, and the multi-agent-debate paper. “53 papers on this site are republished here in full” is both cleaner and accurate.

## Good work that should stay

### FAT 24/41 claim is now reproducible

`data_layer/98_fat_claim.py` is exactly the kind of follow-up the previous audit wanted. It recomputes the 24/41 clustered FAT count (and the 36/41 iid diagnostic), checks the named PET examples, and is invoked by `data_layer/09_verify.py` as a blocking gate. Good fix.

### Existing Guide and MAIVE editions remain strong

I found no substantive scientific-text regression in either. Moving common article CSS into `paper.css` is sensible. MAIVE remains the strongest reference for what a finished full-text page should look like.

### The tooling direction is good

Keeping transcripts, a deterministic renderer, source-PDF checks, figure helpers, and regression tests in the repository is much better than hand-editing 50 pages independently. The main recommendation is to make the verification guarantees match what the tools actually enforce before relying on them at this scale.

## Suggested order

1. Fix masthead variable shadowing.
2. Fix completeness verification semantics.
3. Fix heading-pipe and TOC rendering.
4. Decide/enforce the figure-artwork policy.
5. Finish Beauty’s transcript semantics.
6. Add `<h1>` and citation-range handling.
7. Regenerate all generated pages, then rerun the corpus checks and a small visual/source-PDF spot audit.

After those changes I would re-audit the regenerated branch rather than review individual generated HTML files one by one, because the highest-value failures here are generator-level and will disappear corpus-wide when fixed correctly.
