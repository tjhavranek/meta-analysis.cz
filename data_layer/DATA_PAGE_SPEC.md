# Content spec: the `/datasets/` landing page

For the redesign session. This is **content and constraints only** — layout, type and
visual treatment are yours. Nothing here dictates markup beyond the three hard
constraints in the last section.

## What it is

The human front door to the data layer. Someone lands here from a search result, a
citation, or a colleague's link, and needs to answer one question quickly: *is there
data here I can use, and how do I get it?*

The audience is a researcher or a graduate student, not a visitor browsing papers.
They arrive already wanting data. The page should not sell them on meta-analysis.

## Where it lives

`site/datasets/index.html` — note **`datasets`**, not `data`.

`/data/` and `/api/` are file trees with no `index.html` on purpose; the SEO generator
treats any folder containing one as a paper, and the build gate asserts they stay
empty of one. `/datasets/` is the page; `/data/` is what it points at.

I have already added `datasets` to `SELF_MANAGED` in `generate_seo.py`, so the page
will **not** be given Highwire `citation_*` tags (it is not a paper) but **will** appear
in `sitemap.xml`. It will also receive an injected `DataCatalog` JSON-LD block listing
all 44 datasets — tested and working. You do not need to write any JSON-LD.

## The numbers — DO NOT QUOTE THESE, READ THE FRAGMENTS

These move whenever the data is rebuilt, and they already have once.
Read every one from `site/api/v1/fragments/` at build time.
They are listed here only so a reader knows the rough scale. **Do not hard-code any of them.**

- **44** datasets published
- **65,349** estimates across them
- **39** literatures in the harmonised table, **54,087** estimates, **41** columns
- Every dataset ships as **Parquet and CSV**, with a column-level codebook
- Licence: **CC BY 4.0 on the compilation only** — see the licence section below

## What the page must convey

**1. The offer, in one sentence near the top.** Every meta-analysis on this site
publishes its estimate-level data, and all of it is now downloadable in one place, in
standard formats, with an open licence.

**2. The single most useful thing, made prominent.** One file containing every
literature: `/data/v1/estimates_harmonised.csv` (and `.parquet`). One row per estimate,
with the effect, its standard error, the sample size, and the study characteristics
that recur across literatures. This is the link most visitors want; it should be the
easiest thing to find on the page.

**3. A copyable two-line example.** Something a reader can paste and have working data
in ten seconds. Both languages matter — R is the larger share of this audience.

    df <- read.csv("https://meta-analysis.cz/data/v1/estimates_harmonised.csv")

    df = pd.read_parquet("https://meta-analysis.cz/data/v1/estimates_harmonised.parquet")

**4. The per-dataset route.** A reader who wants one literature, with all of its
hand-coded moderators rather than the shared subset, goes to that paper's own page or
to `/data/v1/<id>/`. A table or list of the 44 datasets belongs here — name, number of
estimates, link — and it can be generated from `api/v1/datasets.json` rather than
hand-maintained. Tell me if you want that as a build step and I will write it.

**5. That it is machine-readable.** A short pointer to `api/v1/datasets.json` and
`api/v1/README.md`. One line is enough; the people who need it will follow it.

**6. Licence and citation, unmissable but not loud.** Use the wording in
`DATA_PAGE_COPY.md` verbatim. It is scoped to match `/LICENSE` exactly: CC BY 4.0 covers
the compilation, NOT the underlying datasets, their format conversions, or the papers'
replication code. **Cite the individual paper when you use its dataset** — that clause is
the whole basis on which this is released and must not be buried. Do not paraphrase the
licence; two external reviewers flagged an earlier, looser wording as overreach.

**7. That the harmonised table is a beta.** Version `0.9.0-beta`. Frame it as
provisional and traceable rather than unreliable: it is generated from the published
files, every row records the file and columns it came from, so anything can be checked
against the source. Avoid language suggesting nobody has looked at it.

**8. One honest caveat.** Effects are not comparable across literatures in raw units —
an elasticity, a partial correlation and a dollar value per tonne all sit in the same
`effect` column, and `effect_units` says which is which. A reader who pools them naively
gets nonsense, so this belongs on the page, not only in the README.

## Tone

Same register as the rest of the site: plain, factual, no marketing. This is a research
resource being made available, not a product launch. Resist superlatives — "the largest
collection of…" invites a challenge nobody needs.

## Links the page must contain

| Target | Why |
|---|---|
| `/data/v1/estimates_harmonised.csv` and `.parquet` | the main offer |
| `/api/v1/datasets.json` | the index |
| `/api/v1/README.md` | full documentation |
| `/LICENSE` | terms |
| the homepage catalogue | for the papers themselves |

## Three hard constraints

1. **No `index.html` under `/data/` or `/api/`.** The build gate fails if one appears.
2. **Do not restate per-dataset facts in hand-written markup.** Counts, DOIs and file
   URLs live in `api/v1/datasets.json` and change when the data is rebuilt. Anything
   duplicated by hand will drift. If you want them on the page, generate them.
3. **Leave the injected JSON-LD sentinels alone**, as on every other page.

## What I will do when the page exists

Add it to `llms.txt` under the `## Data` block, confirm the `DataCatalog` injects
cleanly against the real page, and re-run `verify_seo.py` and your `regression.py`.
Ping me and I will handle the generator side in one pass.
