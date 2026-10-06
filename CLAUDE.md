# Working on meta-analysis.cz

Rules for anyone changing this repository, people and AI agents alike. Each one comes from
a mistake that happened. Those marked **(CI)** are enforced by `.github/workflows/seo.yml`,
and `python tools/preflight.py` runs the same gates locally.

## Pushing

- Commit everything, then push. The pre-push hook is the one battery: it runs every gate CI
  runs (it stops if the workflow gains a gate it does not name), so do not also run
  `tools/preflight.py` before pushing; that repeated every gate (5 Oct 2026). A push that
  touches only `komentare/`, the pages of `/ai/`, `sitemap.xml` and `api/v1/search-index.json`
  skips the full-text and data gates locally, provided CI passed on the base (CI still runs
  them); `FULL=1 git push` forces everything. Use `tools/preflight.py` to
  check without pushing. Never push on `--fast`.
- The hook runs its read-only gates side by side, and the full-text gates keep what poppler
  reads from each PDF in a local cache outside the repo (`tools/_pdf_cache.py`; CI keeps none).
  `PAPER_CHECK_NO_CACHE=1` turns the cache off; delete its folder after reinstalling poppler.
- Never edit files while the pre-push hook is running. It checks the working tree, so an
  edit made during the hook is what it sees, and the push is blocked or goes out mixed.
- A push is not a deploy. Afterwards, confirm that the Actions run succeeded and that the
  live pages match the commit (`python tools/preflight.py --deployed`).
- Changed page text needs `tools/generate_seo.py` and `tools/build_search_index.py`. A
  changed headline question also needs `tools/build_papers_api.py`. **(CI)**

## Counts **(CI: tools/check_counts.py)**

- Counts written into prose must match `api/v1/papers.json` and `api/v1/datasets.json`:
  - papers in full;
  - datasets and pooled literatures;
  - estimates in analysis samples.
- When a release changes a count, search the whole site for the old number.
- A dated note or a talk keeps the count of its day. List such a phrase in `HISTORICAL`
  in the checker, and give the reason.

## Transcript notes in /komentare/ **(CI: komentare/build.py --check)**

- A note describes the text as it stands now, in this order:
  1. what the recording is, and what is left out;
  2. how the text was made;
  3. how the answers were edited;
  4. which obvious slips or numbers were corrected;
  5. any caveats;
  6. what the markers mean.
- Keep a note to at most 200 words. It carries no revision history: phrases like "Při
  revizi…" or "Opraveno bylo 62 přeslechů" belong in the commit message, not the note.
- A note may say that numbers, negations and hedges were kept as spoken. If a slip was
  corrected, the same sentence must name it as the exception ("se neměnily, jen …",
  "kromě …").
- After pulling, the build checks now ignore Windows line endings. If a check still fails,
  run `python komentare/build.py` once and commit what changes.

## Content decisions

- **Licence:** everything is CC BY 4.0, the papers, the data and the photographs alike. The licence
  is always CC BY 4.0: the footer and /LICENSE keep that wording, with no "unless stated otherwise"
  (owner, 3 Oct 2026). A third-party photo shown on a page is credited, with its own licence, on that
  page; one used only as a link preview (og:image) carries its credit in the image file's metadata
  and in the JSON-LD ImageObject, with no visible line (owner, 3 Oct 2026). Exception for trivial
  uses (owner, 6 Oct 2026): small third-party pictures such as poster thumbnails in the
  /komentare/video/ gallery need no visible credit line; a credit printed inside the image, or on the
  item page the card links to, is enough. The owner accepts the small licence risk in cases like
  these, so do not re-add a credit line there or raise it again. The site licence stays CC BY 4.0
  for everything.
- **Names:** in English text the names are spelled Havranek and Irsova.
- **Dashes:** new prose uses no em dashes or en dashes.
- **MAIVE:** describe it without hedging.
- **Tone:** present the authors' record confidently. "Cited by five Nobel laureates" stays,
  linked to the section that names them, `/impact/#academic-use`.
- **CEPR:** Zuzana Irsova is not a CEPR affiliate. She has a CEPR profile as an author.
- **Excluded articles:** six older articles are deliberately not on the site as full text.
  They are cited only on /publications/:
  - Politická ekonomie 2014;
  - Finance a úvěr 2010;
  - Prague Economic Papers 2009 and 2010;
  - TAE 2010;
  - TSR 2013.
- **Size:** warn before adding about 10 MB or more. Measure it with
  `python tools/check_site_size.py --worktree`.
