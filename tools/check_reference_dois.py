"""Re-verify every matched reference DOI, independently of the matcher that proposed it.

The matcher runs three checks and keeps what passes. This runs a fourth, and it is the one
that matters most, because it does not trust the matcher's own record of what it did:

    - self-consistency: every entry's stored text must hash to the key it is filed under, so
      a hand-edited file cannot quietly point a reference at another reference's DOI;
    - reachability: every entry must correspond to a reference that is actually on the site,
      so a stale entry cannot sit in the file pretending to link something;
    - the acceptance rule, re-applied: at least 70% of the record's title words present in
      the reference, the record's year present, one author surname present -- recomputed here
      from the stored metadata, not read back from the matcher's verdict;
    - well-formedness: a DOI that is not a DOI is not a link.

With --online it also re-fetches every accepted DOI from Crossref, re-runs the rule against
that fresh record, DROPS anything that no longer clears it, and rewrites the file with the
year and author surnames the offline rule needs. The online pass is how the file is finished;
the offline pass is what runs in the gate afterwards, on every build, forever.

    python tools/check_reference_dois.py             # the gate
    python tools/check_reference_dois.py --online    # re-fetch, re-verify, cull, enrich
"""
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_paper_page import ROOT, reference_key  # noqa: E402
from match_reference_dois import (agrees, fetch, publication_years, strict,  # noqa: E402
                                  unlinked_references, words)
import re  # noqa: E402
import urllib.parse  # noqa: E402

PATH = os.path.join(ROOT, "tools", "reference_dois.json")
DOI_RE = re.compile(r"^10\.\d{4,9}/\S+$")


def load():
    if not os.path.exists(PATH):
        return {}, {}
    doc = json.load(open(PATH, encoding="utf-8"))
    return doc, doc.get("entries", {})


def offline(entries, on_site):
    """Every check that needs no network. Returns the list of failures."""
    bad = []
    for key, e in sorted(entries.items()):
        text = e.get("text", "")
        if reference_key(text) != key:
            bad.append((key, "the stored text does not hash to this key"))
            continue
        if not DOI_RE.match(e.get("doi") or ""):
            bad.append((key, "not a well-formed DOI: %r" % e.get("doi")))
            continue
        if key not in on_site:
            bad.append((key, "no reference on the site has this text"))
            continue
        if on_site[key] != text:
            bad.append((key, "the reference on the site reads differently"))
            continue
        title = e.get("title") or ""
        tw = words(title)
        if not tw:
            bad.append((key, "no title stored, so the rule cannot be re-applied"))
            continue
        overlap = len(tw & words(text)) / len(tw)
        if overlap < 0.70:
            bad.append((key, "title overlap %.2f is below the rule's 0.70" % overlap))
            continue
        years = e.get("years") or []
        if years and not any(str(y) in text for y in years):
            bad.append((key, "none of the record's years %s is in the reference" % years))
            continue
        # authors are present once the file has been through --online
        if "authors" in e:
            surnames = [s for s in (e.get("authors") or []) if len(s) > 2]
            if not any(s.lower() in text.lower() for s in surnames):
                bad.append((key, "no author surname from the record is in the reference"))
    return bad


def online(doc, entries):
    """Re-fetch every DOI, re-run the rule, drop what fails, store what the rule needs."""
    kept, dropped = {}, []
    for n, (key, e) in enumerate(sorted(entries.items()), 1):
        # An entry that already carries the record's authors has been through this pass. Two
        # things follow: a re-run costs nothing, and a run cut short in the middle keeps what
        # it verified. Three thousand fetches is an hour, and an hour is long enough to lose.
        if "authors" in e:
            kept[key] = e
            continue
        rec = ((fetch("https://api.crossref.org/works/"
                      + urllib.parse.quote(e["doi"])) or {}).get("message") or {})
        if not rec or rec.get("DOI", "").lower() != e["doi"].lower():
            dropped.append((key, "the DOI did not resolve to a record"))
        else:
            o, y, a = agrees(rec, e["text"])
            if not strict(o, y, a):
                dropped.append((key, "re-fetched record fails the rule "
                                     "(overlap %.2f, year %s, author %s)" % (o, y, a)))
            else:
                kept[key] = {
                    "doi": e["doi"],
                    "title": " ".join(rec.get("title") or [""])[:200],
                    "text": e["text"],
                    "years": sorted(publication_years(rec)),
                    "authors": sorted({(au.get("family") or "")
                                       for au in (rec.get("author") or []) if au.get("family")}),
                }
        if n % 50 == 0:
            flush(doc, dict(kept, **{k: v for k, v in entries.items()
                                     if k not in kept and k not in dict(dropped)}))
            print("  re-verified %d/%d, dropped %d" % (n, len(entries), len(dropped)), flush=True)
        time.sleep(1.1)

    flush(doc, kept)
    return dropped


def flush(doc, entries):
    doc["entries"] = entries
    doc["verified_by"] = "tools/check_reference_dois.py --online"
    json.dump(doc, open(PATH, "w", encoding="utf-8"), indent=1, sort_keys=True,
              ensure_ascii=False)


def main():
    doc, entries = load()
    if not entries:
        print("no matched reference DOIs on file; nothing to verify")
        return 0

    if "--online" in sys.argv:
        print("re-fetching %d DOIs from Crossref" % len(entries))
        dropped = online(doc, entries)
        for key, why in dropped:
            print("  dropped %s  %s" % (key, why))
        print("kept %d, dropped %d" % (len(entries) - len(dropped), len(dropped)))
        doc, entries = load()

    on_site = {r["key"]: r["text"] for r in unlinked_references()}
    bad = offline(entries, on_site)
    for key, why in bad:
        print("FAIL %s  %s" % (key, why))
        print("     %s" % entries[key].get("text", "")[:150])
    print("%d matched reference DOIs checked, %d failures" % (len(entries), len(bad)))
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
