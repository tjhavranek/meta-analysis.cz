"""Match references that print no link to a DOI, and refuse anything not triply confirmed.

Most of the reference lists on this site were typeset before DOIs were routine, so a reader
who wants the cited paper has to retype its title into a search box. The links below close
that, but a wrong link is worse than no link: it sends the reader to a different paper while
looking exactly as authoritative as a right one. So the bar is deliberately high, and a
reference that cannot clear it keeps no link at all.

    CHECK 1  the strict rule, on the best of three candidates: at least 70% of the record's
             title words present in the reference, the record's year present, and one author
             surname present. All three, not two of three.
    CHECK 2  unambiguity: the runner-up must not also satisfy the strict rule at a comparable
             relevance score. Two equally plausible records mean we do not know which one the
             reference is, and guessing between them is exactly the failure to avoid.
    CHECK 3  independent re-verification: fetch the accepted DOI on its own endpoint -- a
             fresh response from a different query -- and re-run the whole agreement test
             against the record that comes back. A search hit is not a confirmation.

The output is keyed on the reference's visible text, so the same reference cited by six
papers is matched once, and re-transcribing a reference list drops its stale links rather
than sliding them onto the wrong entries. It is a side file and not part of any transcript:
a transcript is checked word for word against its PDF, and a DOI the paper never printed
would be text the paper does not contain. See build_paper_page.reference_dois().

    python tools/match_reference_dois.py            # resumable; re-run to continue
    python tools/match_reference_dois.py --report   # what was accepted, and why the rest was not
"""
import hashlib
import html
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_paper_page import (ROOT, documents, page_dir, reference_key,  # noqa: E402
                              strip_our_links)

UA = "meta-analysis-cz-reference-linker/1.0 (mailto:t.havranek@gmail.com)"
OUT = os.path.join(ROOT, "tools", "reference_dois.json")
STATE = os.path.join(ROOT, "tools", "reference_dois_state.json")


def unlinked_references():
    """Every reference on the site that carries no link of its own, deduplicated."""
    catalogue = {p["project"]: p
                 for p in json.load(open(os.path.join(ROOT, "tools", "papers.json"),
                                         encoding="utf-8"))}
    catalogue.update(documents())
    seen, out = set(), []
    for project, meta in sorted(catalogue.items()):
        path = os.path.join(page_dir(project, meta), "index.html")
        if not os.path.exists(path):
            continue
        page = open(path, encoding="utf-8").read()
        m = re.search(r'<(ol|ul) class="references[^"]*">(.*?)</\1>', page, re.S)
        if not m:
            continue
        for item in re.findall(r"<li[^>]*>(.*?)</li>", m.group(2), re.S):
            # The links this mechanism adds are stripped before asking whether the reference
            # has one. Without this the extraction is not reproducible: the first build
            # attaches a link, the next run no longer sees the reference, and the key it was
            # matched under can never be re-derived from the built tree.
            item = strip_our_links(item)
            if "<a " in item:
                continue
            text = " ".join(html.unescape(re.sub(r"<[^>]+>", "", item)).split())
            # A one-line "Ibid." or a stray fragment carries nothing to match on.
            if len(text) < 40:
                continue
            key = reference_key(item)
            if key in seen:
                continue
            seen.add(key)
            out.append({"project": project, "key": key, "text": text})
    return out


def fetch(url):
    for attempt in range(3):
        r = subprocess.run(["curl", "-sS", "--max-time", "30", "-A", UA, url],
                           capture_output=True, text=True)
        if r.returncode == 0 and r.stdout.strip().startswith("{"):
            try:
                return json.loads(r.stdout)
            except ValueError:
                pass
        time.sleep(2 + attempt * 3)
    return None


def words(s):
    return set(re.sub(r"[^a-z0-9 ]", " ", (s or "").lower()).split())


def _year_of(node):
    try:
        return str((node or {}).get("date-parts", [[None]])[0][0] or "")
    except (IndexError, TypeError):
        return ""


def publication_years(record):
    """Every year the record itself says it was published.

    Crossref's `issued` is the earliest date it holds, which for a journal article is
    usually the online-first date -- while the reference cites the year it appeared in
    print. Testing `issued` alone refused 145 references whose year the record does state,
    one field over: Becht, Franks, Mayer and Rossi is issued 2008 and published-print 2009,
    and the reference says 2009 because that is when it was published.

    This does not loosen the test. Every year here is one the record asserts about itself,
    and it still has to appear in the reference exactly."""
    years = {_year_of(record.get(f))
             for f in ("issued", "published", "published-print", "published-online")}
    years.add(_year_of((record.get("journal-issue") or {}).get("published-print")))
    return {y for y in years if y}


def agrees(record, reference):
    """(title overlap, year present, author surname present) of a record against a reference."""
    title = " ".join(record.get("title") or [""])
    tw = words(title)
    if not tw:
        return (0.0, False, False)
    overlap = len(tw & words(reference)) / len(tw)
    surnames = {(a.get("family") or "").lower()
                for a in (record.get("author") or []) if a.get("family")}
    return (overlap,
            any(y in reference for y in publication_years(record)),
            any(len(s) > 2 and s in reference.lower() for s in surnames))


def strict(overlap, year_ok, author_ok):
    return overlap >= 0.70 and year_ok and author_ok


def match(reference, state):
    """Run the three checks against one reference. Returns the record to store."""
    rec = {"project": reference["project"], "text": reference["text"], "doi": None, "why": ""}
    query = urllib.parse.quote(reference["text"][:420])
    res = fetch("https://api.crossref.org/works?rows=3&query.bibliographic=" + query
                + "&select=DOI,title,author,score,issued,published,"
                  "published-print,published-online")
    items = ((res or {}).get("message") or {}).get("items") or []
    if not items:
        rec["why"] = "no candidate"
        return rec

    best = items[0]
    o1, y1, a1 = agrees(best, reference["text"])
    if not strict(o1, y1, a1):
        rec["why"] = "check 1 failed (overlap %.2f, year %s, author %s)" % (o1, y1, a1)
        return rec

    if len(items) > 1:
        o2, y2, a2 = agrees(items[1], reference["text"])
        if strict(o2, y2, a2) and items[1].get("score", 0) >= 0.90 * best.get("score", 0):
            rec["why"] = "check 2 failed (the runner-up is equally plausible)"
            return rec

    doi = best["DOI"]
    time.sleep(1.1)
    fresh = ((fetch("https://api.crossref.org/works/" + urllib.parse.quote(doi)) or {})
             .get("message") or {})
    if not fresh or fresh.get("DOI", "").lower() != doi.lower():
        rec["why"] = "check 3 failed (the record did not re-fetch)"
        return rec
    o3, y3, a3 = agrees(fresh, reference["text"])
    if not strict(o3, y3, a3):
        rec["why"] = "check 3 failed (overlap %.2f, year %s, author %s)" % (o3, y3, a3)
        return rec

    rec["doi"] = doi.lower()
    rec["why"] = "all three checks passed"
    rec["overlap"] = round(o3, 3)
    rec["title"] = " ".join(fresh.get("title") or [""])[:200]
    rec["years"] = sorted(publication_years(fresh))
    return rec


def write(state, references):
    """The accepted matches go to the side file; every verdict stays in the state file.

    Keeping the refusals is the point of keeping them: without them a re-run re-asks Crossref
    about four thousand references to rediscover the same two thousand no-candidates."""
    json.dump(state, open(STATE, "w", encoding="utf-8"), indent=0, sort_keys=True)
    entries = {k: {"doi": v["doi"], "title": v.get("title", ""), "text": v["text"],
                   "years": v.get("years", [])}
               for k, v in sorted(state.items()) if v.get("doi")}
    json.dump({
        "what": "DOIs matched to references that were printed without a link.",
        "how": "tools/match_reference_dois.py -- three independent checks; see its docstring.",
        "verified_by": "tools/check_reference_dois.py",
        "keyed_on": "sha1 of the reference's visible text, first 16 hex characters",
        "entries": entries,
    }, open(OUT, "w", encoding="utf-8"), indent=1, sort_keys=True, ensure_ascii=False)


def main():
    references = unlinked_references()
    state = json.load(open(STATE, encoding="utf-8")) if os.path.exists(STATE) else {}

    if "--report" in sys.argv:
        reasons = {}
        for v in state.values():
            reasons[v["why"].split("(")[0].strip()] = reasons.get(v["why"].split("(")[0].strip(), 0) + 1
        print("references without a link of their own: %d" % len(references))
        print("decided: %d" % len(state))
        for why, n in sorted(reasons.items(), key=lambda kv: -kv[1]):
            print("  %5d  %s" % (n, why))
        return 0

    for reference in references:
        if reference["key"] in state:
            continue
        state[reference["key"]] = match(reference, state)
        if len(state) % 25 == 0:
            write(state, references)
            print("%d/%d  matched=%d" % (len(state), len(references),
                                         sum(1 for v in state.values() if v["doi"])), flush=True)
        time.sleep(1.1)

    write(state, references)
    print("done: %d of %d references matched" % (sum(1 for v in state.values() if v["doi"]),
                                                 len(references)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
