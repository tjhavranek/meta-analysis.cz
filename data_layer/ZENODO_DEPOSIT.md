# Zenodo deposit — what to upload, and what must never be uploaded

> **STATUS: 1.3.0 BUILT, AWAITING UPLOAD.** The DOI below is reserved on the draft.
> Version 1.2.1 is published and live.
> The 46 files in `codebooks/` now each carry a `license` key
> (`https://creativecommons.org/licenses/by/4.0/`), added 2026-09-04 so that a client
> reading a codebook on its own is told the rights over what it describes. Every other
> machine-readable record from this pipeline already declared it. No data value, row count
> or column changed, and 1.2.0 remains correct for everything it asserts about the data.
> Whether that warrants a 1.2.1 is the owner's call: until one is cut, the deposit is
> byte-identical to 1.2.0 and the site's codebooks carry one extra key.
> Concept DOI (cite this): **https://doi.org/10.5281/zenodo.21773678**
> Version 0.9.0-beta: **https://doi.org/10.5281/zenodo.21773679**
> Version 1.0.0: **https://doi.org/10.5281/zenodo.21789702**
> Version 1.1.1: **https://doi.org/10.5281/zenodo.22050272** — deposited 2026-08-21.
> Version 1.2.1: **https://doi.org/10.5281/zenodo.22520929** — published 2026-09-06.
> Version 1.3.0: **https://doi.org/10.5281/zenodo.22529684** — reserved 2026-09-06.
>
> 1.3.0 adds the intensive margin to `frisch`, which had published only the
> extensive one: 1,471 rows over 57 studies, distinguished by `margin` in the
> per-dataset file and by `source_file` in the pooled table. It also corrects
> five metadata records an external review found wrong.
>
> 1.2.1 is a correction release. `frisch` was reading a 723-row draft file matching neither
> sample its paper reports; it now publishes the extensive margin, 762 rows from 38 studies,
> pinned to `data_extensive.xlsx`. `activism` was shipping a second header row as an estimate
> (1,974 to 1,973). `lags` named the VAR lag order as its outcome instead of `mon_bot`.
> `spillovers` and `bma` are relabelled semi-elasticities, `skill`s direction note is corrected
> with the old text kept in `direction_note_correction`, `finance_growth` and `inflation` gain
> the publication year their sources always held, and 23 withheld dataset notes now reach the
> index. Totals: 66,897 source rows, 55,471 estimates, 49,866 harmonised rows, 42 literatures.
>
> Version 1.2.0: **https://doi.org/10.5281/zenodo.22212666** — deposited 2026-08-31, built
> from commit `a15b1dc9c4f3de9bc35890a0c68645e88ed466d2`.
>
> 1.2.0 corrects `n_obs` on 4,614 rows (armington and migrant were publishing the number of
> ESTIMATES a study reports as its sample size, which silently corrupts MAIVE's first stage)
> and adds `cbequity`, 176 partial correlations from 9 studies, as the 46th dataset and 42nd
> pooled literature.
>
> **What the 1.2.0 release taught, for whoever does the next one.** Reserve the DOI on the
> draft BEFORE building the bundle. `CITATION.cff` ships inside the zip, so its `doi:` and
> `version:` have to be right at build time; nothing can be corrected afterwards. The
> bundle builder enforces this and refuses to write the zip until `datasets.json` carries a
> version DOI and `CITATION.cff` states the release's version and counts, which is what you
> want. Two files are hand-written and nothing regenerates them:
> `data_layer/citation.cff` and `data_layer/zenodo.json`. Four places carry the DOI:
> those two, `DATA_DOI` in `07_api.py`, and the `DEPOSITS` map in `91_distribution.py`.
> Miss the last and the distribution check silently stops comparing.
> Run `data_layer/rebuild.py` in FULL, not `--data`: the site builders write
> `datasets/index.html` and `llms.txt`, and those carry the deposit sentence too.
>
> Zenodo strips punctuation from uploaded filenames: the archives are stored as
> `ZENODOUPLOADmetaanalysisczv1.2.0.zip`, not the hyphenated name they were uploaded under,
> and a published file cannot be renamed. Never construct that URL; ask the record.
> The steps below describe how it was made and how to make the next version.

> **READ THIS BEFORE FOLLOWING THE STEPS.** Every count and folder name below describes
> **0.9.0-beta** and is now two releases out of date. The procedure is still right; the
> numbers are not. `12_zenodo_bundle.py` names the folder after the version in
> `datasets.json`, so it will be `meta-analysis-cz-harmonised-v{current}` and **not** the
> `v0.9.0-beta` named below. Take the file list, the row counts and the file sizes from the
> freshly built folder's own `SHA256SUMS.txt`, and the dataset, row and literature counts
> from `api/v1/datasets.json`, never from this page. Numbers written by hand here have gone
> stale at every release so far, which is why they are no longer worth correcting in place.

**Do NOT enable the GitHub↔Zenodo integration for `tjhavranek/meta-analysis.cz`.**
It deposits the whole repository tarball and cannot take a subset. That would place
**173 author-copy PDFs** and **23 third-party replication packages** into one record
weighing 438 MB, permanently, when the deposit is meant to be the harmonised data and its
documentation. A DOI freezes whatever is wrong at mint time.

The reason is scope and size, not licensing: the owner decided on 2026-08-03 that everything
on the site is CC BY 4.0, and `LICENSE` now says so. An earlier version of this file cited
`LICENSE` section 2e, which conceded PDF copyright to the journals; that section no longer
exists and the rationale it carried is superseded.

Upload manually instead. It takes about five minutes.

---

## What to upload

The folder `meta-analysis-cz-harmonised-v0.9.0-beta/` — **50 files, 14.9 MB**. Rebuild it any
time with `python data_layer/12_zenodo_bundle.py`.

| File | What |
|---|---|
| `estimates_harmonised.csv` / `.parquet` | 54,076 rows, 39 literatures, 41 columns |
| `datasets.json` | the index: paper, DOI, units, audit status, rights status per dataset |
| `codebooks/*.json` | 44 column-level codebooks |
| `README.md` | documentation, caveats, what is deliberately excluded |
| `LICENSE` | CC BY 4.0, covering every file in the deposit |
| `CITATION.cff` | citation metadata |
| `SHA256SUMS.txt` | checksums for every file |

## What is deliberately NOT in it, and why

- **The 44 per-dataset mirrors (54 MB)**, the **173 paper PDFs** and the **23 replication
  packages**. All of these are CC BY 4.0 like everything else on the site; they are left out
  of the deposit purely to keep it small and citable, not for any rights reason. They stay
  served from the site.

## Licence

Everything on the site, and therefore everything in this bundle, is CC BY 4.0. The owner
decided that on 2026-08-03 and takes responsibility for the grant; the purpose is that an
automated user never has to work out whether a file is usable. Do not reintroduce narrower
scoping into the deposit metadata.

## Steps

1. Sign in at https://zenodo.org (ORCID login works: 0000-0002-3158-2539).
2. **Open the existing record** under the concept DOI `10.5281/zenodo.21773678` and click the
   green **New version** button. **Not "New upload".** The concept DOI already exists, and
   0.9.0-beta and 1.0.0 already sit under it. "New upload" starts a *separate* record with its
   own new concept DOI, which would split the lineage in two and cannot be undone once
   published. This is the single most expensive wrong click on this page.
3. Run `python data_layer/12_zenodo_bundle.py`. It builds the folder **and** the single
   archive `ZENODO-UPLOAD-meta-analysis-cz-v{version}.zip`, and prints the path and its
   sha256. **Upload that one zip. Do not drag in loose files.** Every published version so
   far holds exactly one file with exactly that name, and `91_distribution.py` fetches it by
   that URL to byte-compare the live table against the deposit. Loose files, or a different
   name, break that check. Treat the release files as immutable: Zenodo does allow limited file
   corrections for a short window after publishing, and a constrained support process after that,
   but a deposit is not a thing to plan on editing.
4. **Do not click "Import files".** A new-version draft is a new record and starts empty;
   Zenodo only brings the previous version's files across if you explicitly ask it to. Whatever
   the interface does on the day, the invariant is what matters: **before publishing, check the
   draft contains exactly one file, the zip from step 3.** If a previous version's archive is
   there for any reason, remove it, or this release ships the last release's data beside its own.
5. Fill the metadata from `data_layer/zenodo.json` — title, authors with ORCIDs, description,
   keywords. Set **Licence: Creative Commons Attribution 4.0 International**.
6. Under *Related identifiers*, add `https://meta-analysis.cz` as **is derived from**, and
   ideally each paper's DOI as **is supplement to** so credit flows to the original papers
   rather than collapsing into the collection citation.
7. Preview, and read the preview against the bundle you actually built: version, counts,
   file list, licence.
8. Publish, and record the newly minted **version** DOI. The concept DOI does not change.
9. Propagate the version DOI to every canonical source that carries one. Regenerating is not
   enough, because three of them are hand-written: `07_api.py` (`DATA_DOI`),
   `data_layer/zenodo.json`, `data_layer/citation.cff`, `data_layer/api_readme.md`, the
   Croissant `dateModified`, and the `DEPOSITS` map in `91_distribution.py`. Then rebuild and
   check `datasets.json`, root `.zenodo.json`, root `CITATION.cff`, `llms.txt` and the
   `/datasets/` fragments all agree.

## Afterwards

Zenodo versions cleanly: a later release becomes a new version under a stable **concept
DOI** that always resolves to the newest. Cite the concept DOI in prose and the version DOI
in a replication package.

Once the DOI exists, connect it at https://profiles.datacite.org (sign in with ORCID) so it
flows into ORCID automatically — that item is already on the deferred list in `PROGRESS.md`.

