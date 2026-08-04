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
    "results",     # built by redesign/build_results_page.py; an ItemList of Question nodes.
                   # Deliberately not FAQPage: these are research findings, not frequently
                   # asked questions, and claiming that type would be a misdeclaration.
}
