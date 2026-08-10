# Verify the SEO injection: (1) visible text of every page is UNCHANGED vs git HEAD,
# (2) every JSON-LD block parses and has required fields, (3) every contentUrl /
# sitemap / llms.txt URL maps to an existing local file, (4) exactly one canonical.
import json, os, re, subprocess, sys, urllib.parse
from html.parser import HTMLParser

SITE = os.environ.get("SEO_SITE_DIR", os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BASE = "https://meta-analysis.cz"

class TextExtract(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
        self.skip = 0
    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style"):
            self.skip += 1
    def handle_endtag(self, tag):
        if tag in ("script", "style") and self.skip:
            self.skip -= 1
    def handle_data(self, d):
        if not self.skip:
            self.parts.append(d)

def visible_text(html_src):
    p = TextExtract()
    p.feed(html_src)
    return re.sub(r"\s+", " ", "".join(p.parts)).strip()

def git_show(rel):
    out = subprocess.run(["git", "-C", SITE, "show", f"HEAD:{rel}"],
                         capture_output=True)
    return out.stdout.decode("utf-8", "replace") if out.returncode == 0 else None

def url_to_path(u):
    if not u.startswith(BASE):
        return None
    p = urllib.parse.unquote(u[len(BASE):]).lstrip("/")
    if p == "" or p.endswith("/"):
        p += "index.html"
    return os.path.join(SITE, p.replace("/", os.sep))

# Sections that build their own metadata layer. They are not injected into, so they
# legitimately carry canonical/OG/JSON-LD outside the sentinel block — checking them here would
# report the absence of an injection we deliberately skipped. They are still listed in
# sitemap.xml, still checked below for stale inlined fragments, and their own build script
# validates their markup.
#
# This set USED to be declared here as {"komentare", "notes"} while generate_seo.py declared
# {"komentare", "notes", "datasets"} — which is exactly why /datasets/ reported
# "canonical count != 1". One definition now, in _seo_shared.py.
import sys as _sys, os as _os
_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from _seo_shared import SELF_MANAGED

fails = []
pages = ["index.html"] + sorted(
    f"{d}/index.html" for d in os.listdir(SITE)
    if os.path.isfile(os.path.join(SITE, d, "index.html"))
    and d not in SELF_MANAGED)

n_ld = n_urls = 0
for rel in pages:
    path = os.path.join(SITE, rel.replace("/", os.sep))
    new = open(path, "rb").read().decode("utf-8")
    old = git_show(rel)
    if old is None:
        fails.append(f"{rel}: not in git HEAD?")
        continue
    if visible_text(old) != visible_text(new):
        fails.append(f"{rel}: VISIBLE TEXT CHANGED")
    # STRUCTURAL: today's incident - a stray </div> closed #content early and
    # dropped the sidebar out of the page box, while every other check passed.
    nopen, nclose = new.count('<div'), new.count('</div>')
    if nopen != nclose:
        fails.append(f"{rel}: unbalanced divs ({nopen} open / {nclose} close) - layout will break")
    if 'id="sidebar"' in new and 'id="content"' in new:
        i, j = new.index('id="content"'), new.index('id="sidebar"')
        seg = new[i:j]
        if seg.count('<div') - seg.count('</div>') < 0:
            fails.append(f"{rel}: #content closes before #sidebar - sidebar escapes the page box")
    if 'name="viewport"' not in new:
        fails.append(f"{rel}: no viewport meta - page will render zoomed out on phones")
    # A bare "<" in visible text (an abstract writing "n < 200") is invisible in a browser and
    # catastrophic for every text extractor: a regex tag-stripper swallows everything from that
    # bracket to the next ">". On /pcc/ that silently deleted the rest of the abstract from
    # every corpus built from the page. This site is written to be read by machines.
    _spans = [(m.start(), m.end()) for m in
              re.finditer(r"<script\b.*?</script>|<style\b.*?</style>|<!--.*?-->", new, re.S | re.I)]
    for m in re.finditer(r"<(?![/a-zA-Z!?])", new):
        if any(a <= m.start() < b for a, b in _spans):
            continue          # inside a script/style/comment it is not markup and not text
        ctx = " ".join(new[max(0, m.start() - 40):m.start() + 40].split())
        fails.append(f"{rel}: unescaped '<' in visible text - a tag-stripper will delete "
                     f"everything after it. Write &lt;. Context: ...{ctx}...")
    if not re.search(r'<html[^>]*lang=', new):
        fails.append(f"{rel}: <html> has no lang attribute")
    if new.count('rel="canonical"') != 1:
        fails.append(f"{rel}: canonical count != 1")
    # duplicate metadata families confuse Google Scholar (the /debate incident):
    # no single-instance metadata tag may appear more than once anywhere
    for tag in ('name="citation_title"', 'property="og:title"',
                'property="og:url"', 'name="citation_doi"',
                'name="citation_pdf_url"', 'rel="canonical"'):
        if new.count(tag) > 1:
            fails.append(f"{rel}: DUPLICATE {tag} ({new.count(tag)}x) - conflicting metadata")
    # every citation_*/og: tag must live INSIDE the sentinel block (no
    # hand-written metadata outside it, which is what collided on /debate)
    m_in = re.search(r'<!-- seo-meta:start -->(.*?)<!-- seo-meta:end -->', new, re.S)
    outside = new.replace(m_in.group(0), "") if m_in else new
    if re.search(r'name="citation_|property="og:|application/ld\+json', outside):
        fails.append(f"{rel}: metadata found OUTSIDE the seo-meta sentinel block "
                     f"(hand-written duplicate?) - move it inside or remove it")
    # COVERAGE: a page whose menu links a same-folder, non-supplement PDF must
    # expose citation_pdf_url (the bug that silently dropped 11 pages' full text)
    proj = rel.split("/")[0]
    if proj != "index.html":
        menu = re.search(r'<div id="menu">(.*?)</div>', new, re.S)
        if menu:
            supp = re.compile(r"appendix|supplement|online|additional|results|studies|"
                              r"calibrat|classif|excluded|replication|dataset|figure|slides", re.I)
            for href, lbl in re.findall(r'<a href="([^"]+\.pdf)"[^>]*>(.*?)</a>', menu.group(1), re.S):
                if href.startswith(("http", "/")):
                    continue
                lbl = re.sub(r"<[^>]+>", "", lbl)
                if supp.search(lbl):
                    continue
                if os.path.isfile(os.path.join(SITE, proj, href)) and 'citation_pdf_url' not in new:
                    fails.append(f"{rel}: has local paper PDF '{href}' but NO citation_pdf_url")
                break
    # the citation_pdf_url value must point to a real file (not just be present)
    for pu in re.findall(r'name="citation_pdf_url" content="([^"]+)"', new):
        lp = url_to_path(pu)
        n_urls += 1
        if lp and not os.path.isfile(lp):
            fails.append(f"{rel}: citation_pdf_url target missing on disk: {pu}")
    blocks = re.findall(r'<script type="application/ld\+json">(.*?)</script>', new, re.S)
    if len(blocks) != 1:
        fails.append(f"{rel}: expected 1 JSON-LD block, found {len(blocks)}")
        continue
    try:
        data = json.loads(blocks[0])
    except Exception as e:
        fails.append(f"{rel}: JSON-LD does not parse: {e}")
        continue
    n_ld += 1
    for node in data.get("@graph", []):
        t = node.get("@type")
        if t == "ScholarlyArticle" and not (node.get("headline") and node.get("abstract")):
            fails.append(f"{rel}: article missing headline/abstract")
        if t == "Dataset":
            if not (node.get("name") and node.get("description")):
                fails.append(f"{rel}: dataset missing name/description")
            for d in node.get("distribution", []):
                lp = url_to_path(d.get("contentUrl", ""))
                n_urls += 1
                if lp and not os.path.isfile(lp):
                    fails.append(f"{rel}: distribution missing file {d.get('contentUrl')}")
        for enc in (node.get("encoding") or []):
            lp = url_to_path(enc.get("contentUrl", ""))
            n_urls += 1
            if lp and not os.path.isfile(lp):
                fails.append(f"{rel}: encoding missing file {enc.get('contentUrl')}")

# sitemap URLs resolve
sm = open(os.path.join(SITE, "sitemap.xml"), encoding="utf-8").read()
for loc in re.findall(r"<loc>(.*?)</loc>", sm):
    lp = url_to_path(loc)
    n_urls += 1
    if lp and not os.path.isfile(lp):
        fails.append(f"sitemap: missing target {loc}")

# llms.txt / llms-full.txt internal URLs resolve
for fn in ("llms.txt", "llms-full.txt"):
    txt = open(os.path.join(SITE, fn), encoding="utf-8").read()
    for u in re.findall(r"https://meta-analysis\.cz[^\s\)\]]*", txt):
        lp = url_to_path(u.rstrip(".,"))
        n_urls += 1
        if lp and not os.path.isfile(lp):
            fails.append(f"{fn}: missing target {u}")

# /datasets/ inlines generated fragments at BUILD time, so it can fall out of date with
# them without any file changing: a stale page is a CLEAN file, invisible to git status and
# to the visible-text check above, which only compares against HEAD. This caught nothing
# when the page said 61,305 while the fragments said 61,294. One assertion closes it.
_dsets = os.path.join(SITE, "datasets", "index.html")
_frag = os.path.join(SITE, "api", "v1", "fragments")
if os.path.isfile(_dsets) and os.path.isdir(_frag):
    _page = open(_dsets, "rb").read().decode("utf-8", "replace")
    for _f in ("count_datasets", "count_estimates", "count_analysis",
               "count_harmonised_estimates", "count_harmonised_literatures",
               "harmonised_version"):
        _fp = os.path.join(_frag, _f + ".html")
        if not os.path.isfile(_fp):
            continue
        _v = open(_fp, encoding="utf-8").read().strip()
        if _v and _v not in _page:
            fails.append(f"datasets/index.html: STALE - fragment {_f} is '{_v}' but the page "
                         f"does not contain it. Rebuild the page from the fragments.")

# --- does any one-line summary publish the number the paper CORRECTS, as the finding? ---
# `one_line` is derived from the abstract's opening, and abstracts often lead with the raw mean
# before the corrected estimate. On `dst` that produced a summary saying daylight saving yields
# "slight electricity savings of about 0.34%" -- 0.34% is the simple average the paper exists to
# correct; its actual estimate is 0.01%, essentially zero. llms.txt carried it, so an answer
# engine was told the opposite of the paper's conclusion, and of this site's whole thesis.
# estimates.csv already records which figure is preferred, so make it the referee.
# SCOPE: this is a KEYWORD guard, not a semantic one -- it only fires on the word "against".
# Verified 2026-08-04 across all 52 rows: exactly four mention a comparator at all
# (excess_sensitivity, lags, dst, trust); the first three use "against" and are covered, and
# trust's is a causality caveat rather than a raw-versus-corrected comparison. So the gap is
# prospective: the first headline written as "compared with the raw mean" will pass silently.
# If you add such a row, widen this alternation rather than assuming the guard saw it.
_est = os.path.join(SITE, "estimates.csv")
_pap = os.path.join(SITE, "tools", "papers.json")
if os.path.isfile(_est) and os.path.isfile(_pap):
    import csv as _csv
    _one = {x.get("project"): (x.get("one_line") or "")
            for x in json.load(open(_pap, encoding="utf-8"))}
    _num = re.compile(r"-?\d+(?:\.\d+)?%")
    for _row in _csv.DictReader(open(_est, encoding="utf-8")):
        _proj, _head = (_row.get("project") or "").strip(), (_row.get("headline") or "")
        _ol = _one.get(_proj) or ""
        if not _ol or "against" not in _head:
            continue
        # "essentially zero, 0.01% savings, against a 0.34% simple average" ->
        # preferred = numbers before "against", comparator = numbers after it
        _pre, _post = _head.split("against", 1)
        _preferred = set(_num.findall(_pre))
        _comparator = set(_num.findall(_post))
        _in_ol = set(_num.findall(_ol))
        if _comparator & _in_ol and not (_preferred & _in_ol):
            fails.append(
                f"{_proj}: one_line quotes {sorted(_comparator & _in_ol)}, which estimates.csv "
                f"records as the comparator the paper CORRECTS, and omits the preferred figure "
                f"{sorted(_preferred)}. This is what the abstract-first heuristic gets wrong; "
                f"override one_line in papers.json.")

print(f"pages checked: {len(pages)}; JSON-LD blocks valid: {n_ld}; URLs resolved: {n_urls}")
if fails:
    print(f"\nFAILURES ({len(fails)}):")
    for f in fails[:60]:
        print("  " + f)
    sys.exit(1)
print("ALL CHECKS PASS — visible content identical, JSON-LD valid, all URLs resolve")
