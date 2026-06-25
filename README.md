# meta-analysis.cz — website

This repository **is** the website: plain static files (HTML, PDF, data, code,
figures), one folder per meta-analysis project. No build step, no server-side
code. It is served by **GitHub Pages** at the custom domain **meta-analysis.cz**.

## How it's published (one-time setup)

1. Create a GitHub repo and push this folder's contents to the default branch.
2. Repo **Settings → Pages**: Source = "Deploy from a branch", branch = `main`,
   folder = `/ (root)`. Save.
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
