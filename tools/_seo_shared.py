"""One definition of which sections build their own metadata, shared by the generator and the
verifier.

It used to be declared twice, and the two drifted: generate_seo.py listed
{komentare, notes, datasets} while verify_seo.py listed {komentare, notes}. So the generator
deliberately skipped injecting into /datasets/ and the verifier then reported the absence of
that injection as a fault -- the open "/datasets/: canonical count != 1" disagreement. A second
instance was about to appear with /results/.

Two lists that must agree are a defect waiting to happen. There is now one list.

A section belongs here when it builds its own <head>: title, description, canonical, and its own
JSON-LD. Those pages are still in sitemap.xml, still checked for stale inlined fragments, and
still validated by their own build script -- what is skipped is only the injection check, which
does not apply to a page nothing injects into.
"""

SELF_MANAGED = {
    "komentare",   # Czech commentary section, builds its own head
    "notes",       # research notes, built by notes/build_notes.py
    "datasets",    # built by redesign/build_datasets_page.py; a DataCatalog, not an article,
                   # so it must not receive Highwire citation_* tags
    "about",       # hand-authored identity page; builds its own head and is not a paper.
                   # Without this the injector treats it as a 55th paper, emits
                   # ScholarlyArticle, and fails for absence from papers.json.
    "results",     # built by redesign/build_results_page.py; an ItemList of Question nodes.
                   # Deliberately not FAQPage: these are research findings, not frequently
                   # asked questions, and claiming that type would be a misdeclaration.
    "maive/how-to",  # built by tools/build_maive_howto.py; a how-to whose numbers come from
                   # a live API run and are recorded in api/v1/maive-howto.json. Not a paper:
                   # Highwire citation_* tags on it would be fabricated.
    "search",      # built by tools/build_search_page.py; a tool, not a document. It has no
                   # author, no year and no abstract, so Highwire citation_* tags would be
                   # fabricated. It is still in the sitemap -- it is a real page a reader
                   # may want -- but it is a tool, not a document, and is described as one.
    "publications",  # built by tools/build_publications_page.py; a bibliography of other
                   # people's articles as much as of this site's. It has no author, year or
                   # abstract of its own, so Highwire citation_* tags on it would be
                   # fabricated, and the injector would emit ScholarlyArticle for a list.
    "papers",      # built by tools/build_fulltext_page.py; an index of the full-text
                   # editions, so a CollectionPage rather than a 55th paper. Without this
                   # the injector emits ScholarlyArticle and Highwire tags for a list.
}
