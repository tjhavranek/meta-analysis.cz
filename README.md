# meta-analysis.cz — website

This repository **is** the website: plain static files (HTML, PDF, data, code,
figures), one folder per meta-analysis project. No server-side code. It is served
by **GitHub Pages** at the custom domain **meta-analysis.cz**.

Two generated layers sit on top of the static files, both reproducible from this
repository:

- **the metadata layer** — `tools/generate_seo.py` injects canonical, Highwire,
  Open Graph and JSON-LD into each page between sentinels, and regenerates
  `sitemap.xml`, `robots.txt` and `llms*.txt`. `tools/verify_seo.py` is its gate.
- **the data layer** — `data_layer/` builds `/api/v1/` and `/data/v1/` from the
  papers' own published files. `data_layer/09_verify.py` is its gate. See
  `data_layer/README.md`.

Everything on the site is **CC BY 4.0**, including the datasets and the PDFs.
See `LICENSE`.

## How it's published (one-time setup)

1. Create a GitHub repo and push this folder's contents to the default branch.
2. Repo **Settings → Pages**: Source = "GitHub Actions". Every push to `main`
   runs `.github/workflows/seo.yml`, which regenerates the invisible
   metadata layer (see below), verifies it, and deploys the site. If a check
   fails, the previous site stays live.
3. The `CNAME` file (already here) sets the custom domain to `meta-analysis.cz`.
   In Settings → Pages, confirm the domain shows and **Enforce HTTPS** is ticked
   (the certificate can take ~15 min to an hour the first time).
4. DNS (the registrar/host side — Martin):
   - Apex `meta-analysis.cz` → four **A** records:
     `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`
     (and optionally the matching **AAAA** records for IPv6).
   - `www` → **CNAME** to `<github-username>.github.io`.
   - Make sure any **CAA** record allows `letsencrypt.org` (or has no CAA record).
   GitHub redirects `www` → apex automatically; the apex is canonical.

That's it. Every push to `main` redeploys automatically.

## Why GitHub Pages (and not the earlier Vercel attempt)

Each project page links its figure with a **relative** path, e.g.
`<img src="funnel.png">`. GitHub Pages serves a folder as a directory: a request
for `/learning` is 301-redirected to `/learning/`, so `funnel.png` correctly
resolves to `/learning/funnel.png` and **figures render**. The earlier Vercel
deploy did *not* add the trailing slash, so `funnel.png` resolved to the site
root and figures 404'd. `.nojekyll` (present) tells Pages to serve everything
as-is. Do **not** move files into Git LFS — Pages cannot serve LFS files.

## How to maintain it (the common cases)

- **Update a paper's PDF / data:** replace the file in its project folder
  (e.g. `risk/risk.pdf`), keeping the same filename, then commit & push.
- **Add a new project** `foo`:
  1. make a folder `foo/` with `foo/index.html` (copy an existing project's
     `index.html` as a template, adjust title/text/links),
  2. add its assets (`foo.pdf`, figures, `default.css`, data),
  3. add a row linking to `/foo` on the homepage `index.html`,
  4. commit & push.
- **Keep filenames URL-safe** (letters, digits, `-`, `_`, `.`). Avoid spaces,
  `%`, parentheses. Filenames are **case-sensitive** on the live site, so a link
  to `Funnel.png` will not find `funnel.png`.

## Machine-readable metadata (SEO / AI indexing)

The site carries an invisible metadata layer so search engines, Google Scholar,
Google Dataset Search, and AI/LLM crawlers can index everything:

- each paper page: canonical URL, Highwire `citation_*` tags (what Google
  Scholar reads, incl. `citation_pdf_url` to the full text), Open Graph tags,
  and JSON-LD (`ScholarlyArticle` + `Dataset` with data/code download links) —
  injected between `<!-- seo-meta:start/end -->` comments in `<head>`;
- site root: `robots.txt` (all crawlers incl. AI bots welcome), `sitemap.xml`
  (all pages + own paper/supplement PDFs), `llms.txt` and `llms-full.txt`
  (plain-text indexes with abstracts for LLM ingestion).

**This regenerates automatically on every push** (`tools/generate_seo.py`,
driven by the filesystem). Metadata (authors, year, journal) comes from
`tools/papers.json`. **Adding a new paper**: just push the new folder — it
gets baseline coverage immediately; the workflow then turns red as a reminder
to add the paper's entry to `tools/papers.json` (easiest: ask Claude/your AI
assistant — "add the new paper to papers.json"), after which the red goes away
and Scholar tags appear. Never edit inside the sentinel comments by hand.

**Owner TODO for maximum reach (one-time, outside this repo):**
1. Verify the domain in Google Search Console + Bing Webmaster Tools and
   submit `https://meta-analysis.cz/sitemap.xml`.
2. Backfill publisher DOIs for published papers into `tools/papers.json`
   (field `doi_or_publisher_url`) — enables `citation_doi` and richer JSON-LD.
3. ~~Zenodo deposit~~ **DONE** — the harmonised data layer is archived at
   concept DOI `10.5281/zenodo.21773678` (cite this; always resolves to the
   newest version). Build the deposit with `data_layer/12_zenodo_bundle.py`;
   never enable the GitHub↔Zenodo integration, which would archive the whole
   repository including journal PDFs. See `data_layer/ZENODO_DEPOSIT.md`.
   Still worth doing: make sure RePEc/IDEAS records link to these landing pages.

## After any deploy — quick check

    curl -I https://meta-analysis.cz/learning      # expect 301 -> /learning/
    curl -I https://meta-analysis.cz/learning/funnelplot.png   # expect 200 image/png

Open the homepage and click into 2–3 projects; confirm figures and PDF links
load.

## Provenance / backups

Reconstructed 2026-06 after the host was compromised, from the recovered server
files, cross-checked against an Internet-Archive rebuild and the author's local
source folders; every file integrity-checked (valid PDFs/images, no truncation,
no injected scripts). A second independent copy and the verification notes live
outside this repo (the owner's `web_meta` working folder).

## Known minor gap (not content)

The saved literature-search pages (`*/search.html`, `*/Scholar*.htm`) reference a
few third-party assets (Google Scholar / RePEc logos, analytics JS) that were
never archived. The pages still open and list the searches; only external logos
are absent. No research file is affected.
