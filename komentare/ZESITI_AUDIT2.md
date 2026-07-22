# ZESITI audit 2

| post date | severity | quoted text | what is wrong | suggested fix | confidence |
|---|---|---|---|---|---|
| n/a (row accounting) | low | “No CSV row has empty `ShareCommentary`.” | The requested “one empty repost” exclusion cannot be confirmed: all 26 commentary fields are nonempty after decoding. The four absent rows are 2026-02-12 (“Congratulations to Martin!”), 2024-09-02 (the ten-word “Proč se všichni ptají…” reaction), 2023-04-12, and 2022-07-20; the last three are before the 2025-10-26 cutoff. No other row is missing. | Correct the accounting rationale or supply the supposed empty source row. No change to the 22-post set is needed under the stated cutoff. | high |

## Coverage

22/22 posts were compared in full against decoded `li_shares.csv`; none were skipped. No word or paragraph-break differences were found. Dates and URLs, timestamp-attributed comment URLs, all 16 image references/dimensions/alts, all 22 rendered texts/original links/unique anchors, href punctuation, languages, and reshare metadata passed the requested checks.
