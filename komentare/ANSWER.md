# Answer

## 1. SEO / retrieval

`/komentare/posts/#a` and `#b` are navigation targets inside **one retrieved resource**, not two retrievable pages. The URI standard says the fragment is separated before dereferencing and a same-document reference should not trigger another retrieval ([RFC 3986](https://www.rfc-editor.org/rfc/rfc3986.html#section-3.5)). Google is equally explicit: it generally does not support fragments as separate content URLs, ignores fragment identifiers when deciding whether it has already fetched a page, and rejects fragments as canonicals ([URL guidance](https://developers.google.com/search/docs/crawling-indexing/url-structure), [pagination guidance](https://developers.google.com/search/docs/specialty/ecommerce/pagination-and-incremental-page-loading), [canonical guidance](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls)).

Therefore 22 rows create 22 navigation links but only **one indexable destination**, `/komentare/posts/`. Google may display a fragment as a “jump to” section, but the indexed/ranked document remains the posts page. Descriptive internal-link text can help Google understand that page ([link guidance](https://developers.google.com/search/docs/crawling-indexing/links-crawlable)); there is no documented basis for treating 22 same-page links as 22 ranking assets. The hub itself could rank for its visible generated labels, while all post text is indexed and ranked together on the posts page—an inference from the one-document model.

## 2. Precedent

- [Manton Reece](https://www.manton.org/) mixes titleless micro-posts and titled essays in one chronological stream, but every micro-post’s timestamp opens a **unique `.html` permalink**.
- Academic Jason Heppler’s [full archive](https://jasonheppler.org/archive/) explicitly mixes “Essays, Posts, & Notes” in one date-sorted list; entries have titles and unique URLs.
- [Lars-Christian](https://lars-christian.com/writing/) keeps long “Posts” and short social-style “Notes” in separate archives and feeds.
- Pew both separates [Short Reads](https://www.pewresearch.org/short-reads/) as a format landing page and mixes them into [Publications](https://www.pewresearch.org/publications/); again, each item has a title and unique URL.

**Recommendation: Do not add 22 rows; add one prominent "LinkedIn posts (22)" link/card with a last-updated date above the formal-item index.**
