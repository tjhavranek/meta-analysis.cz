"""Build the index the site's own search runs on.

The search box on this site used to hand the visitor's query to Google, with
as_sitesearch=meta-analysis.cz -- a parameter Google stopped honouring years ago, so what
came back was the whole web. It was also on 91 of 374 pages: not on the papers index, not on
the datasets page, and not on any of the 55 full-text papers, which are the pages with
something to search.

This indexes every page on the site instead. It is a document-level inverted index: for each
word, the list of pages that contain it. That is enough to answer "which pages say
publication bias and Armington" instantly, in the reader's browser, without a request to
anyone. It is not enough to answer "where on the page", which is why headings are indexed
separately -- a hit in a heading links to that section rather than to the top of a 300KB
paper.

    python tools/build_search_index.py

Writes api/v1/search-index.json. Numbers are base-36 and document ids are delta-encoded,
which is the difference between a 900KB index and a 350KB one; the reader downloads it once,
compressed, and searches offline from then on.
"""
import collections
import html
import json
import os
import re
import sys
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_paper_page import ROOT  # noqa: E402

OUT = os.path.join(ROOT, "api", "v1", "search-index.json")
WORD = re.compile(r"[a-z][a-z0-9]{1,}")


def fold(text):
    """Strip accents before indexing, so Havranek finds Havranek.

    Half this site's authors have a diacritic in their name and nobody types them into a
    search box. Without this, "Havranek" indexes as "havr" and "nek" and matches neither
    what is on the page nor what the reader types."""
    return "".join(c for c in unicodedata.normalize("NFKD", text.lower())
                   if not unicodedata.combining(c))

# Words in more than this share of pages carry no information about which page you want: the
# site's own furniture ("meta", "analysis", "havranek") is on every page by construction.
TOO_COMMON = 0.55

# A word is prominent on a page if it is used at least this many times AND at this rate. One
# test without the other ranks by page length instead of by aboutness.
PROMINENT_COUNT = 4
PROMINENT_RATE = 0.0008

# Directories that are not pages a reader would want returned.
SKIP = ("api/", "data/", "tools/", "node_modules/")


def visible(page):
    """The text a reader sees: no scripts, no navigation, no footer."""
    page = re.sub(r"<(script|style)\b[^>]*>.*?</\1>", " ", page, flags=re.S | re.I)
    page = re.sub(r"<(nav|footer|header)\b[^>]*>.*?</\1>", " ", page, flags=re.S | re.I)
    page = re.sub(r'<div id="(?:menu|sidebar|header|footer)".*?</div>', " ", page, flags=re.S)
    return " ".join(html.unescape(re.sub(r"<[^>]+>", " ", page)).split())


def title_of(page, url):
    m = re.search(r"<title>(.*?)</title>", page, re.S | re.I)
    if m:
        t = " ".join(html.unescape(re.sub(r"<[^>]+>", " ", m.group(1))).split())
        return re.sub(r"\s*[|–-]\s*meta-analysis\.cz\s*$", "", t, flags=re.I) or url
    return url


def summary_of(page, text):
    """One or two sentences to show under the result. The page's own description if it has
    one -- it was written for this -- and the start of its text if not."""
    m = re.search(r'<meta name="description" content="([^"]*)"', page, re.I)
    if m and len(m.group(1)) > 40:
        return html.unescape(m.group(1))[:300]
    return text[:300]


def headings_of(page):
    """(anchor, heading) for every section that has an id, so a hit can land on it."""
    out = []
    for m in re.finditer(r'<h[2-3][^>]*\bid="([^"]+)"[^>]*>(.*?)</h[2-3]>', page, re.S | re.I):
        head = " ".join(html.unescape(re.sub(r"<[^>]+>", " ", m.group(2))).split())
        if head and len(head) < 120:
            out.append((m.group(1), head))
    return out[:60]


CANONICAL = re.compile(r'<link rel="canonical" href="https://meta-analysis\.cz(/[^"]*)"')


def canonical_of(page, url):
    """The URL the page says it is.

    Twenty pages here are the same note under a second address and say so in a canonical
    link. Returning both is returning one result twice, and the site has already answered
    which one it is -- this reads that answer rather than guessing at duplicates."""
    m = CANONICAL.search(page)
    if not m:
        return url
    return m.group(1).rstrip("/") + "/" if m.group(1) != "/" else "/"


def kind_of(url):
    if url.endswith(("/paper/", "/supplement/", "/guide/")):
        return "paper"
    if url.startswith("/notes/"):
        return "note"
    if url.startswith("/datasets") or url.startswith("/results"):
        return "data"
    return "page"


def b36(n):
    if n == 0:
        return "0"
    digits = "0123456789abcdefghijklmnopqrstuvwxyz"
    out = ""
    while n:
        n, r = divmod(n, 36)
        out = digits[r] + out
    return out


def encode(ids):
    """Sorted document ids as base-36 gaps: the gaps are small even when the ids are not."""
    out, prev = [], 0
    for i in sorted(ids):
        out.append(b36(i - prev))
        prev = i
    return ".".join(out)


def main():
    pages = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        if "index.html" not in filenames:
            continue
        rel = os.path.relpath(dirpath, ROOT).replace(os.sep, "/")
        url = "/" if rel == "." else "/%s/" % rel
        if any(url.startswith("/" + s) for s in SKIP):
            continue
        pages.append((url, os.path.join(dirpath, "index.html")))
    pages.sort()

    docs, aliases = [], 0
    body, titles = collections.defaultdict(set), collections.defaultdict(set)
    strong = collections.defaultdict(set)
    for i, (url, path) in enumerate(pages):
        page = open(path, encoding="utf-8").read()
        text = visible(page)
        if len(text) < 120:
            continue
        if canonical_of(page, url) != url:
            aliases += 1
            continue
        title = title_of(page, url)
        heads = headings_of(page)
        docs.append({"u": url, "t": title, "k": kind_of(url),
                     "s": summary_of(page, text),
                     "h": [[a, h] for a, h in heads]})
        d = len(docs) - 1
        words = WORD.findall(fold(text))
        counts = collections.Counter(words)
        for w, c in counts.items():
            body[w].add(d)
            # A page that says "Armington" forty times is about the Armington elasticity; a
            # page that says it once mentions it. Without this every one of the 140 pages
            # containing "publication bias" scores the same and the order is arbitrary. Both
            # tests matter: the count alone promotes any long page, the rate alone promotes
            # any short one.
            if c >= PROMINENT_COUNT and c / len(words) >= PROMINENT_RATE:
                strong[w].add(d)
        for w in set(WORD.findall(fold(title + " " + " ".join(h for _, h in heads)))):
            titles[w].add(d)

    n = len(docs)
    cap = int(n * TOO_COMMON)
    postings = {w: encode(ids) for w, ids in body.items() if len(ids) <= cap}
    strong_postings = {w: encode(ids) for w, ids in strong.items()
                       if w in postings and ids}
    head_postings = {w: encode(ids) for w, ids in titles.items() if len(ids) <= cap}
    dropped = sorted((w for w, ids in body.items() if len(ids) > cap),
                     key=lambda w: -len(body[w]))

    payload = json.dumps({
            "what": "The index meta-analysis.cz searches itself with.",
            "how": "tools/build_search_index.py. Document-level inverted index; document ids "
                   "are base-36 gaps. b = words in the page, h = words in its title or a "
                   "heading, s = pages the word is prominent on rather than merely present. "
                   "Words on more than %d%% of pages are omitted as uninformative."
                   % int(TOO_COMMON * 100),
            "n": n,
            "common": dropped,
            "docs": docs,
            "b": postings,
            "h": head_postings,
            "s": strong_postings,
    }, separators=(",", ":"), ensure_ascii=False, sort_keys=True)

    # An index built from yesterday's pages is worse than no index: it returns pages that
    # have moved on and misses the ones added since. --check is how a build fails on that
    # instead of shipping it.
    if "--check" in sys.argv:
        current = open(OUT, encoding="utf-8").read() if os.path.exists(OUT) else ""
        if current != payload:
            print("the search index does not match the pages it indexes; "
                  "run: python tools/build_search_index.py")
            return 1
        print("search index: matches the pages it indexes (%d pages)" % n)
        return 0

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, "w", encoding="utf-8").write(payload)
    size = os.path.getsize(OUT)
    print("%d pages (%d aliases of another page skipped), %d words indexed (%d omitted as too common: %s)"
          % (n, aliases, len(postings), len(dropped), ", ".join(dropped[:6])))
    print("api/v1/search-index.json: %.0f KB" % (size / 1024))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
