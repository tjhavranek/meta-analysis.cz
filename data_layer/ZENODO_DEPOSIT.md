# Zenodo deposit — what to upload, and what must never be uploaded

> **STATUS: PUBLISHED.** This deposit exists.
> Concept DOI (cite this): **https://doi.org/10.5281/zenodo.21773678**
> Version 0.9.0-beta: **https://doi.org/10.5281/zenodo.21773679**
> Version 1.0.0: **https://doi.org/10.5281/zenodo.21789702**
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
| `LICENSE` | the scoping |
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
3. Build the bundle with `python data_layer/12_zenodo_bundle.py` and drag in the **contents**
   of the folder it prints. It names that folder after the version in `datasets.json`, so take
   the name from the script's output rather than from this page.
4. Fill the metadata from `data_layer/zenodo.json` — title, authors with ORCIDs, description,
   keywords. Set **Licence: Creative Commons Attribution 4.0 International**.
5. Under *Related identifiers*, add `https://meta-analysis.cz` as **is derived from**, and
   ideally each paper's DOI as **is supplement to** so credit flows to the original papers
   rather than collapsing into the collection citation.
6. Preview, and read the preview against the bundle you actually built: version, counts,
   file list, licence.
7. Publish, and record the newly minted **version** DOI. The concept DOI does not change.
8. Propagate the version DOI to every canonical source that carries one. Regenerating is not
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

