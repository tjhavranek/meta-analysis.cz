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

fails = []
pages = ["index.html"] + sorted(
    f"{d}/index.html" for d in os.listdir(SITE)
    if os.path.isfile(os.path.join(SITE, d, "index.html")))

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
    if new.count('rel="canonical"') != 1:
        fails.append(f"{rel}: canonical count != 1")
    # duplicate metadata families confuse Google Scholar (the /debate incident)
    for tag in ('name="citation_title"', 'property="og:title"'):
        if new.count(tag) > 1:
            fails.append(f"{rel}: DUPLICATE {tag} ({new.count(tag)}x) - conflicting metadata blocks")
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

print(f"pages checked: {len(pages)}; JSON-LD blocks valid: {n_ld}; URLs resolved: {n_urls}")
if fails:
    print(f"\nFAILURES ({len(fails)}):")
    for f in fails[:60]:
        print("  " + f)
    sys.exit(1)
print("ALL CHECKS PASS — visible content identical, JSON-LD valid, all URLs resolve")
