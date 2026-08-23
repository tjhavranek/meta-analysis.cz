# Regenerates the invisible SEO/AI-indexing layer of meta-analysis.cz.
# Run from anywhere: python tools/generate_seo.py  (site root = parent of tools/)
#
# What it does, per project page (any folder with index.html): injects, inside
# <!-- seo-meta:start/end --> sentinels (idempotent), a canonical link, meta
# description (if missing), Google Scholar Highwire citation_* tags, Open Graph
# tags, and one JSON-LD block (ScholarlyArticle + Dataset). Regenerates
# robots.txt, sitemap.xml, llms.txt, llms-full.txt.
#
# Metadata comes from tools/papers.json (reviewed, authoritative). A folder NOT
# in papers.json is still covered mechanically (parsed from its HTML: title,
# abstract, menu links, figure) and included in sitemap/llms.txt, but gets no
# Highwire tags until papers.json is enriched — the script then exits 1 so CI
# turns red and the owner knows to ask their AI assistant to add the entry.
import json, os, re, sys, datetime, hashlib, html, subprocess, urllib.parse

HERE = os.path.dirname(os.path.abspath(__file__))
SITE = os.environ.get("SEO_SITE_DIR", os.path.dirname(HERE))
META = os.path.join(HERE, "papers.json")
BASE = "https://meta-analysis.cz"
TODAY = datetime.date.today().isoformat()
WARNINGS = []
NOTES = []   # informational only -- never fail the build

# Sections that build their own metadata layer and must NOT be injected into.
# /komentare/ (published commentary, columns, interviews) and /notes/ are generated
# by their own scripts, which already emit canonical, OG, per-item JSON-LD and a
# feed. Injecting the paper-oriented ScholarlyArticle block here would duplicate
# every one of those tags and fail verify_seo. Their pages are still listed in
# sitemap.xml below.
import sys as _sys, os as _os
_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from _seo_shared import SELF_MANAGED   # one definition, shared with verify_seo.py

# The catalogue node every Dataset points at, built once.
# The catalogue, keyed by project id. Used for variableMeasured on each paper's Dataset node:
# core_columns names the columns whose meaning has actually been verified, which is the honest
# thing to advertise. Absent catalogue => no variableMeasured, never a wrong one.
def _catalog_doi():
    """The Zenodo concept DOI of the collection, read rather than typed."""
    try:
        import json as _j
        _p = os.path.join(SITE, "api", "v1", "datasets.json")
        return (_j.load(open(_p, encoding="utf-8")) or {}).get("concept_doi_url") or ""
    except Exception:
        return ""


_CATALOG = None


def _catalog_node():
    global _CATALOG
    if _CATALOG is None:
        _CATALOG = {"@type": "DataCatalog", "name": "meta-analysis.cz",
                    "url": BASE + "/datasets/"}
        _doi = _catalog_doi()
        if _doi:
            _CATALOG["sameAs"] = _doi
    return _CATALOG


def _load_datasets():
    try:
        import json as _j
        _p = os.path.join(SITE, "api", "v1", "datasets.json")
        return {d["id"]: d for d in _j.load(open(_p, encoding="utf-8"))["datasets"]}
    except Exception:
        return {}
_DATASETS = _load_datasets()
# (was declared here AND in verify_seo.py with different contents; see _seo_shared.py)

# /datasets/ is the human landing page for the data layer. It is NOT a paper, so it
# must not receive Highwire citation_* tags — hence SELF_MANAGED above. It does get a
# schema.org DataCatalog block, injected below, which is what Google Dataset Search
# reads to discover the individual datasets. The page itself is hand-built; only the
# block between the sentinels is generated. Safe if the page does not exist yet.
DATA_API = "/api/v1/datasets.json"

FMT = {
    ".pdf": "application/pdf", ".dta": "application/x-stata-dta",
    ".xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ".xls": "application/vnd.ms-excel", ".csv": "text/csv",
    ".zip": "application/zip", ".do": "text/plain", ".r": "text/plain",
    ".txt": "text/plain", ".png": "image/png",
    ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ".doc": "application/msword",
}
DATA_EXT = {".dta", ".xlsx", ".xls", ".csv"}
CODE_EXT = {".do", ".r", ".zip"}
DATAISH = re.compile(r"data|code|replication|studies|calibration|classification|excluded", re.I)

def absurl(proj, href):
    href = href.strip()
    if href.startswith(("http://", "https://")):
        return href
    path = href if href.startswith("/") else f"/{proj}/{href}"
    return BASE + urllib.parse.quote(path)

def jdump(obj):
    return json.dumps(obj, ensure_ascii=False, indent=1).replace("</", "<\\/")

# verified ORCID iDs for frequent authors (exact-name map; confirmed via
# pub.orcid.org). Only these two are asserted — never inferred for others.
AUTHOR_IDS = {
    "tomas havranek": "https://orcid.org/0000-0002-3158-2539",
    "zuzana irsova": "https://orcid.org/0000-0002-0753-8124",
    "zuzana havrankova": "https://orcid.org/0000-0002-0753-8124",
}

def person(name):
    p = {"@type": "Person", "name": name}
    key = re.sub(r"[^a-z ]", "", (name or "").lower()).strip()
    if key in AUTHOR_IDS:
        p["sameAs"] = AUTHOR_IDS[key]
    return p

# volume/issue/first-last-page from a citation line. Ordered most→least
# specific; tolerant of "pp.", ":", "," separators and en/em dashes.
REF_VIP = [
    re.compile(r"(?P<vol>\d+)\s*\(\s*(?P<iss>[\dA-Za-z\-]+)\s*\)\s*[:,]?\s*(?:pp?\.?\s*)?(?P<fp>\d+)\s*[-–—]\s*(?P<lp>\d+)"),
    re.compile(r"(?P<vol>\d+)\s*\(\s*(?P<iss>[\dA-Za-z\-]+)\s*\)\s*[:,]?\s*(?:pp?\.?\s*)?(?P<fp>\d+)"),
    re.compile(r"(?<![.\d])(?P<vol>\d{1,3})\s*[:,]\s*(?:pp?\.?\s*)?(?P<fp>\d+)\s*[-–—]\s*(?P<lp>\d+)"),
    re.compile(r"(?<![.\d])(?P<vol>\d{1,3}),\s*(?P<fp>\d{4,7})\b"),  # article-number journals
]

def parse_ref(ref):
    if not ref:
        return {}
    for rx in REF_VIP:
        m = rx.search(ref)
        if m:
            return {k: v for k, v in m.groupdict().items() if v}
    return {}

def extract_doi(url):
    m = re.search(r"doi\.org/(10\.\S+?)/?$", url or "")
    return m.group(1) if m else None

# ---------- fallback: deterministic parse of a template page ----------------
def fallback_parse(proj, raw):
    """Mechanical metadata for a page missing from papers.json."""
    def rx1(p, flags=re.I | re.S):
        m = re.search(p, raw, flags)
        return m.group(1).strip() if m else None
    title = html.unescape(rx1(r"<title>(.*?)</title>") or proj)
    # some pages wrap the abstract in a custom <abstract> tag rather than <p>;
    # prefer that, else fall back to the entry-div paragraphs
    abstract = ""
    am = re.search(r"<abstract>(.*?)</abstract>", raw, re.S | re.I)
    if am:
        abstract = re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", am.group(1)))).strip()
    else:
        entry = rx1(r'<div class="entry">(.*?)</div>')
        if entry:
            paras = []
            for ptxt in re.findall(r"<p>(.*?)</p>", entry, re.S):
                t = re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", ptxt))).strip()
                if not t or t.lower().startswith(("fig", "reference")):
                    continue
                if "Reference:" in ptxt or "<img" in ptxt:
                    continue
                paras.append(t)
            abstract = " ".join(paras).strip()
    # guard: a scrape that just echoes the title is not a real abstract
    if abstract and abstract.strip() == title.strip():
        abstract = ""
    menu = []
    menu_html = rx1(r'<div id="menu">(.*?)</div>')
    if menu_html:
        for href, label in re.findall(r'<a href="([^"]+)"[^>]*>(.*?)</a>', menu_html, re.S):
            menu.append({"href": href, "label": re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", "", label))).strip()})
    # Most pages link the paper PDF in the menu. A few link it only in the body
    # (/guidelines/ links the published JOES article there), which left the page
    # with no citation_pdf_url at all -- Google Scholar then has no full text to
    # index. Fall back to the first same-folder, non-supplement PDF in the body,
    # and only when the menu offers none.
    if not any(not l["href"].startswith(("http", "/")) and l["href"].lower().endswith(".pdf")
               and not SUPP.search(l["label"]) for l in menu):
        body = raw.replace(menu_html, "") if menu_html else raw
        for href, label in re.findall(r'<a href="([^"]+\.pdf)"[^>]*>(.*?)</a>', body, re.S):
            if href.startswith(("http", "/")):
                continue
            label = re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", "", label))).strip()
            if SUPP.search(label) or SUPP.search(href):
                continue
            if os.path.isfile(os.path.join(SITE, proj, href.split("?")[0])):
                menu.append({"href": href, "label": label})
                NOTES.append(f"{proj}: paper PDF {href} found in the page body, not the "
                             f"menu — used for citation_pdf_url")
                break
    ref = rx1(r"<b>\s*Reference\s*:\s*</b>(.*?)(?:<|$)")
    if ref:
        ref = re.sub(r"\s+", " ", html.unescape(ref)).strip()
    year = None
    if ref:
        ym = re.search(r"\((20\d\d)\)", ref)
        year = int(ym.group(1)) if ym else None
    fig = None
    fm = re.search(r'<img src="([^"]+\.(?:png|jpg))"', raw, re.I)
    if fm:
        fig = {"src": fm.group(1), "caption": title}
    # Prominent tool links that live in the page BODY rather than the resource menu.
    # The redesign promoted the MAIVE app from a menu button to a `.tool-link`
    # sentence, which silently dropped its URL out of llms-full.txt — the file that
    # exists for AI crawlers. The link is still on the page, so emit it from there.
    tools = []
    for tm in re.finditer(r'<b[^>]*class="[^"]*tool-link[^"]*"[^>]*>(.*?)</b>', raw, re.S | re.I):
        blk = tm.group(1)
        am = re.search(r'<a[^>]+href="(https?://[^"]+)"[^>]*>(.*?)</a>', blk, re.S | re.I)
        if not am:
            continue
        lbl = re.sub(r"<[^>]+>", "", am.group(2))
        lbl = re.sub(r"\s+", " ", html.unescape(lbl)).strip(" : ")
        # the visible text usually ends with the bare domain, which the URL then
        # repeats; drop it so the line reads as a label rather than a stutter
        host = re.sub(r"^www\.", "", urllib.parse.urlparse(am.group(1)).netloc)
        lbl = re.sub(r"[\s:,-]*" + re.escape(host) + r"/?\s*$", "", lbl, flags=re.I).strip(" :,-")
        if lbl and not any(t["href"] == am.group(1) for t in tools):
            tools.append({"href": am.group(1), "label": lbl})
    return {
        "project": proj, "title": title, "abstract": abstract or title,
        "reference_line": ref, "authors": None, "year": year, "journal": None,
        "doi_or_publisher_url": None, "menu_links": menu, "tool_links": tools, "figure": fig,
        "has_meta_description": '<meta name="description"' in raw,
        "meta_keywords": rx1(r'<meta name="keywords" content="([^"]*)"'),
        "one_line": (abstract or title)[:152] + ("..." if len(abstract or title) > 152 else ""),
        "_fallback": True,
    }

# ---------- builders ---------------------------------------------------------
def local_exists(proj, href):
    p = href.split("?")[0].split("#")[0].lstrip("/")
    path = os.path.join(SITE, p) if href.startswith("/") else os.path.join(SITE, proj, p)
    return os.path.isfile(path)

SUPP = re.compile(r"appendix|supplement|online|additional|results|studies|"
                  r"calibrat|classif|excluded|replication|do.?file|stata|"
                  r"matlab|dataset|figure|slides|presentation", re.I)
FILE_URL = re.compile(r"\.(zip|xlsx?|csv|dta|do|r|pdf|txt|tsv|json)$", re.I)
NOT_DATA = re.compile(r"scholar\.google|/scholar\?|/citations\?|/search\b", re.I)

def classify_links(m):
    """main paper PDF, other local PDFs, local data/code downloads,
    external DIRECT-FILE downloads, and external LANDING pages (-> sameAs)."""
    main_pdf, other_pdfs, dc_local, dc_ext_file, ext_landing = None, [], [], [], []
    for link in m["menu_links"]:
        href, label = link["href"], link["label"].strip()
        ext = os.path.splitext(href.split("?")[0].split("#")[0])[1].lower()
        if href.startswith(("http://", "https://")):
            if not DATAISH.search(label) or NOT_DATA.search(href):
                continue  # a Google Scholar search etc. is not dataset data
            if FILE_URL.search(href.split("?")[0]):
                dc_ext_file.append(link)          # direct downloadable file
            else:
                ext_landing.append(link)          # OSF/Zenodo landing page
            continue
        if not ext or href.startswith("/"):  # anchor, or cross-project abs link
            continue
        if not local_exists(m["project"], href):
            if href in (m.get("pending_files") or []):
                # intentionally absent (e.g. a manuscript awaiting co-author sign-off):
                # keep the visible link, keep it out of the metadata, do not fail the build
                NOTES.append(f"{m['project']}: {href} is pending (papers.json pending_files) — "
                             f"excluded from metadata until the file lands")
            else:
                WARNINGS.append(f"{m['project']}: menu links missing file {href} — "
                                f"excluded from metadata; add the file or fix the link")
            continue
        if ext == ".pdf":
            # main paper = first same-folder PDF that isn't a supplement
            if main_pdf is None and not SUPP.search(label):
                main_pdf = link
            else:
                other_pdfs.append(link)
        elif ext in DATA_EXT or ext in CODE_EXT:
            dc_local.append(link)
    return main_pdf, other_pdfs, dc_local, dc_ext_file, ext_landing

def build_jsonld(m):
    proj, page = m["project"], f"{BASE}/{m['project']}/"
    authors = [person(a) for a in (m["authors"] or [])]
    main_pdf, other_pdfs, dc_local, dc_ext_file, ext_landing = classify_links(m)
    vip = parse_ref(m["reference_line"])
    art = {"@type": "ScholarlyArticle", "@id": page + "#paper",
           "mainEntityOfPage": page, "url": page,
           "headline": m.get("citation_title") or m["title"],
           "name": m.get("citation_title") or m["title"],
           "abstract": m["abstract"], "inLanguage": "en",
           # The sibling Dataset node has carried a license since the CC BY decision, but this
           # one did not, so a crawler reading the PAPER saw no rights at all on 51 of 51 pages.
           # The whole point of the CC BY declaration is that a machine never has to wonder.
           #
           # CC BY 4.0 is the owner's decision for HIS material, and it is the right default.
           # It is not his to declare for a publisher's typeset OA copy hosted here under the
           # journal's own terms: conventional_wisdom.pdf is Wiley's version of record, marked
           # CC BY-NC-ND on its first page, with nine other copyright holders. So the default
           # stands and papers.json may override it per paper.
           # CC BY 4.0 by default. Crossref records publisher terms for most of these
           # articles -- Elsevier, Springer, Wiley and Sage proprietary or text-mining
           # licences, and CC BY-NC-ND on three -- but those describe the PUBLISHER'S copy.
           # The owner is an author and holds the rights to this content, and has stated
           # that it is CC BY. article_license in papers.json still overrides per paper.
           "license": m.get("article_license")
                      or "https://creativecommons.org/licenses/by/4.0/"}
    if authors:
        art["author"] = authors
    if m["year"]:
        art["datePublished"] = str(m["year"])
    if m["journal"]:
        part = {"@type": "Periodical", "name": m["journal"]}
        if vip.get("vol"):
            part = {"@type": "PublicationVolume", "volumeNumber": vip["vol"], "isPartOf": part}
        if vip.get("iss"):
            part = {"@type": "PublicationIssue", "issueNumber": vip["iss"], "isPartOf": part}
        art["isPartOf"] = part
        if vip.get("fp"):
            art["pageStart"] = vip["fp"]
        if vip.get("lp"):
            art["pageEnd"] = vip["lp"]
    if m["doi_or_publisher_url"]:
        art["sameAs"] = m["doi_or_publisher_url"]
        doi = extract_doi(m["doi_or_publisher_url"])
        if doi:
            art["identifier"] = {"@type": "PropertyValue", "propertyID": "DOI", "value": doi}
    if m.get("license"):
        art["license"] = m["license"]
    if m["meta_keywords"]:
        art["keywords"] = m["meta_keywords"]
    if m["figure"]:
        art["image"] = absurl(proj, m["figure"]["src"])
    if main_pdf:
        art["encoding"] = [{"@type": "MediaObject", "name": main_pdf["label"],
                            "contentUrl": absurl(proj, main_pdf["href"]),
                            "encodingFormat": "application/pdf"}]
    if other_pdfs:
        art["hasPart"] = [{"@type": "CreativeWork", "name": p["label"],
                            "url": absurl(proj, p["href"])} for p in other_pdfs]
    graph = [art]
    # ALSO NOT a bug, and the same shape as the pcc case below: /debate/, /learning/ and
    # /outliers/ show a DOI in visible text but emit no citation_doi. Those are Charles
    # University working papers with no journal DOI; the DOIs on the page are OSF
    # pre-registrations and Zenodo replication packages. Putting either in citation_doi would
    # tell Google Scholar the PAPER's DOI is a dataset's, corrupting the record rather than
    # completing it. No citation_doi until these papers actually have one. A checker that sees
    # a DOI on a page and assumes it belongs to the paper will keep re-raising this; it is wrong.
    #
    # NOT a bug that some pages emit a Dataset node yet are absent from the /datasets/
    # DataCatalog (pcc is the example): this node means "data and code for this study", which a
    # literature-search log satisfies, while the catalogue admits only estimate-level datasets
    # with a per-estimate standard error. Different scopes, both correct. Raised by the site
    # audit of 2026-08-04 and checked: pcc ships only search.xlsx, so it belongs here and not
    # in the catalogue.
    if dc_local or dc_ext_file or ext_landing:
        # distribution = actual downloadable files only; repository landing
        # pages (OSF/Zenodo) go to sameAs, not distribution
        dist = [{"@type": "DataDownload", "name": f["label"],
                 "contentUrl": absurl(proj, f["href"]),
                 "encodingFormat": FMT.get(os.path.splitext(f["href"].split("?")[0])[1].lower(),
                                            "application/octet-stream")}
                for f in dc_local + dc_ext_file]
        ds = {"@type": "Dataset", "@id": page + "#dataset",
              "name": f"Data and code for: {m['title']}",
              "description": ("Dataset and replication files for the study. " + m["abstract"])[:4900],
              "url": page, "isAccessibleForFree": True, "inLanguage": "en",
              # Owner's decision, 2026-08-03: everything on the site is CC BY 4.0, the research
              # data included, and he takes responsibility for the grant. This is the field
              # Google Dataset Search and AI crawlers read to decide whether the data may be
              # used, so it must say so plainly. usageInfo stays alongside for the full terms.
              "license": "https://creativecommons.org/licenses/by/4.0/",
              "usageInfo": BASE + "/LICENSE",
              "isAccessibleForFree": True,
              # Google Dataset Search recommends catalogue membership, and it is a plain fact
              # about this dataset: it is one entry in the collection. The DOI goes on the
              # CATALOGUE, which is what it identifies -- no individual dataset here has a DOI
              # of its own, and putting the collection's on each one would say otherwise.
              "includedInDataCatalog": _catalog_node(),
              "subjectOf": {"@id": page + "#paper"}}
        if dist:
            ds["distribution"] = dist
        if ext_landing:
            ds["sameAs"] = [l["href"] for l in ext_landing]
        if authors:
            ds["creator"] = authors
        # Google Dataset Search recommends variableMeasured, and it is the only field that
        # says what the file actually contains. Taken from the catalogue's verified
        # core_columns, so it names the columns whose meaning has been checked rather than
        # every column the file happens to have.
        # ONLY the keys that name a real column. core_columns also carries `evidence` and
        # `standard_error_note`, which are prose ABOUT the mapping -- emitting those put a
        # 190-character sentence in as a variable name, in the field Google Dataset Search
        # reads to learn what the file measures.
        _cc = (_DATASETS.get(proj) or {}).get("core_columns") or {}
        _COLS = ("effect", "standard_error")
        _vm = [{"@type": "PropertyValue", "name": _cc[k], "description": k.replace("_", " ")}
               for k in _COLS if _cc.get(k)]
        if _vm:
            ds["variableMeasured"] = _vm
        if m["reference_line"]:
            ds["citation"] = m["reference_line"]
        if m.get("dataset_doi"):
            ds["identifier"] = {"@type": "PropertyValue", "propertyID": "DOI",
                                "value": m["dataset_doi"]}
        if m.get("dataset_license"):
            ds["license"] = m["dataset_license"]
        if m["meta_keywords"]:
            ds["keywords"] = m["meta_keywords"]
        graph.append(ds)
    return {"@context": "https://schema.org", "@graph": graph}

def highwire_tags(m):
    # Scholar needs at least title + author + date; emit nothing on fallback pages
    if not (m["authors"] and m["year"]):
        return []
    esc = lambda s: html.escape(s, quote=True)
    # citation_title: the PAPER's actual title (papers.json override, e.g. when the page uses a
    # short display title) so Scholar indexes under the real title and merges with the journal
    # version; falls back to the page title when they coincide
    tags = [f'<meta name="citation_title" content="{esc(m.get("citation_title") or m["title"])}" />']
    for a in m["authors"]:
        tags.append(f'<meta name="citation_author" content="{esc(a)}" />')
    tags.append(f'<meta name="citation_publication_date" content="{m["year"]}" />')
    vip = parse_ref(m["reference_line"])
    if m["journal"]:
        tags.append(f'<meta name="citation_journal_title" content="{esc(m["journal"])}" />')
        for k, tag in (("vol", "citation_volume"), ("iss", "citation_issue"),
                       ("fp", "citation_firstpage"), ("lp", "citation_lastpage")):
            if vip.get(k):
                tags.append(f'<meta name="{tag}" content="{vip[k]}" />')
    elif m["reference_line"] and "Charles University" in m["reference_line"]:
        tags.append('<meta name="citation_technical_report_institution" content="Charles University, Prague" />')
    doi = extract_doi(m["doi_or_publisher_url"])
    if doi:
        tags.append(f'<meta name="citation_doi" content="{doi}" />')
    main_pdf = classify_links(m)[0]
    if main_pdf:
        tags.append(f'<meta name="citation_pdf_url" content="{absurl(m["project"], main_pdf["href"])}" />')
    return tags

def head_block(m):
    proj, page = m["project"], f"{BASE}/{m['project']}/"
    desc = html.escape(m["one_line"], quote=True)
    lines = [f'<link rel="canonical" href="{page}" />']
    if not m["has_meta_description"]:
        lines.append(f'<meta name="description" content="{desc}" />')
    lines += highwire_tags(m)
    lines += ['<meta property="og:site_name" content="meta-analysis.cz" />',
              '<meta property="og:type" content="article" />',
              f'<meta property="og:title" content="{html.escape(m["title"], quote=True)}" />',
              f'<meta property="og:description" content="{desc}" />',
              f'<meta property="og:url" content="{page}" />']
    if m["figure"]:
        lines.append(f'<meta property="og:image" content="{absurl(proj, m["figure"]["src"])}" />')
        cap = (m["figure"].get("caption") or m["title"])
        lines.append(f'<meta property="og:image:alt" content="{html.escape(cap, quote=True)}" />')
    # No og:image when the page has no real figure. It used to fall back to
    # images/img02.jpg, the 880x58 navigation-bar gradient: below the 200x200
    # minimum most platforms accept, so every share rendered a blue smear.
    # A text-only card is better than a misleading one.
    lines.append('<script type="application/ld+json">\n' + jdump(build_jsonld(m)) + "\n</script>")
    return "\n".join(lines) + "\n"

S_OPEN, S_CLOSE = "<!-- seo-meta:start -->", "<!-- seo-meta:end -->"

def inject(path, block):
    raw = open(path, "rb").read().decode("utf-8")
    no = raw.count(S_OPEN)
    nc = raw.count(S_CLOSE)
    if no != nc:
        WARNINGS.append(f"{path}: unbalanced seo-meta sentinels ({no} start / {nc} "
                        f"end) — fix by hand; page skipped to avoid double injection")
        return False
    if no:  # strip existing block(s); tolerate CRLF and repeated blocks
        raw = re.sub(re.escape(S_OPEN) + r".*?" + re.escape(S_CLOSE) + r"\r?\n?",
                     "", raw, flags=re.S)
    if raw.count("</head>") != 1:
        WARNINGS.append(f"{path}: no unique </head>, page skipped")
        return False
    # these pages are English (Czech sections are SELF_MANAGED and never injected);
    # declare it for screen readers, translation tools, and search engines
    if "name=\"viewport\"" not in raw:
        vp = '<meta name="viewport" content="width=device-width, initial-scale=1" />'
        raw = raw.replace("</head>", vp + chr(10) + "</head>", 1)
    mh = re.search("<html[^>]*>", raw)
    if mh and "lang=" not in mh.group(0):
        raw = raw[:mh.start()] + mh.group(0).replace("<html", chr(60) + 'html lang="en"', 1) + raw[mh.end():]
    out = raw.replace("</head>", f"{S_OPEN}\n{block}{S_CLOSE}\n</head>")
    open(path, "wb").write(out.encode("utf-8"))
    return True

def git_dates():
    dates = {}
    try:
        out = subprocess.run(["git", "-C", SITE, "log", "--format=%cs", "--name-only"],
                             capture_output=True, text=True, encoding="utf-8").stdout
        cur = None
        for line in out.splitlines():
            if re.fullmatch(r"\d{4}-\d{2}-\d{2}", line.strip()):
                cur = line.strip()
            elif line.strip() and cur and line.strip() not in dates:
                dates[line.strip()] = cur
        st = subprocess.run(["git", "-C", SITE, "status", "--porcelain"],
                            capture_output=True, text=True, encoding="utf-8").stdout
        for line in st.splitlines():
            p = line[3:].strip().strip('"')
            if p:
                dates[p] = TODAY
    except Exception as e:
        print("git dates unavailable:", e)
    return dates

def refresh_about_counts(api):
    """Keep /about/'s one hand-written pair of numbers honest.

    The About page is SELF_MANAGED, so the head injector never touches it, and its
    body sentence "pools 40 of the 44 published datasets" was maintained by hand --
    correct when written and silently wrong the day a 45th dataset lands. The
    numbers live in api/v1/datasets.json like every other count on the site, so
    read them from there and rewrite the sentence in place. Nothing else on the
    page is touched, and a mismatch is reported rather than fixed quietly.
    """
    path = os.path.join(SITE, "about", "index.html")
    if not os.path.exists(path):
        return
    counts = (api or {}).get("counts") or {}
    pooled = counts.get("literatures_in_harmonised_table")
    total = counts.get("datasets")
    if not (pooled and total):
        WARNINGS.append("about: datasets.json carries no counts to refresh the page with")
        return
    s = open(path, encoding="utf-8").read()
    pat = re.compile(r"pools (\d+) of the (\d+) published datasets")
    m = pat.search(s)
    if not m:
        WARNINGS.append(
            "about: the pooled-datasets sentence has been reworded, so its counts are "
            "no longer refreshed here -- update the pattern in refresh_about_counts()")
        return
    if (int(m.group(1)), int(m.group(2))) == (pooled, total):
        return
    NOTES.append(f"about: pooled-datasets count refreshed to {pooled} of {total} "
                 f"(page said {m.group(1)} of {m.group(2)})")
    open(path, "w", encoding="utf-8", newline="\n").write(
        pat.sub(f"pools {pooled} of the {total} published datasets", s, count=1))


# -- the full text, for llms-full.txt ---------------------------------------------------

_TRANSCRIPTS = os.path.join(SITE, "tools", "transcripts")

# Sections the entry above already states. Repeating them would have a machine read the
# title, the authors and the abstract twice per paper and disagree with itself on nothing.
_SKIP_SECTIONS = {"FRONTMATTER", "ABSTRACT"}


def _plain(md):
    """The transcript dialect as ordinary Markdown.

    The transcripts are already Markdown -- pipe tables, LaTeX between dollars, ^{n} for a
    citation marker -- so this only has to do three things: drop the sections the entry has
    already stated, undo the Wiley-style "3.2 | Title" heading rule, and push every heading
    two levels down so a paper's own sections nest under its ## entry instead of colliding
    with it."""
    out, skipping = [], False
    for line in md.split("\n"):
        m = re.match(r"^(#{2,6})\s+(.*)$", line)
        if m:
            level, head = m.group(1), m.group(2).strip()
            name = re.sub(r"\s*\|\s*", ". ", head).strip()
            skipping = name.split(":")[0].strip().upper() in _SKIP_SECTIONS
            if skipping:
                continue
            out.append("#" * min(6, len(level) + 2) + " " + name)
            continue
        if not skipping:
            out.append(line)
    return "\n".join(out).strip("\n")


def _from_page(rel):
    """The article text of a built page, for the two papers that have no transcript.

    /guidelines/guide/ and /maive/paper/ were written by hand before the toolchain existed,
    so the published HTML is the only copy of their text. Reading it back is not a second
    source that could disagree with the page -- it IS the page."""
    path = os.path.join(SITE, rel, "index.html")
    if not os.path.isfile(path):
        return None
    with open(path, encoding="utf-8") as fh:
        page = fh.read()
    m = re.search(r'<div class="entry">(.*?)</div>\s*</div>\s*</div>', page, re.S)
    body = m.group(1) if m else page
    body = re.sub(r"<(script|style|nav)\b.*?</\1>", " ", body, flags=re.S)
    # the contents list is navigation, not text, and it repeats every heading
    body = re.sub(r'<(ol|ul)[^>]*class="[^"]*toc[^"]*".*?</\1>', " ", body, flags=re.S)
    body = re.sub(r"<h([1-6])[^>]*>(.*?)</h\1>",
                  lambda mm: "\n\n" + "#" * min(6, int(mm.group(1)) + 2) + " "
                             + re.sub(r"<[^>]+>", "", mm.group(2)).strip() + "\n", body, flags=re.S)
    body = re.sub(r"</(p|li|tr|div|figure|table|blockquote)>", "\n", body)
    body = re.sub(r"<[^>]+>", " ", body)
    body = html.unescape(body)
    body = re.sub(r"[ \t]+", " ", body)
    body = re.sub(r"\n{3,}", "\n\n", body)
    body = "\n".join(l.strip() for l in body.split("\n"))
    return _drop_sections(body) or None


def _drop_sections(md):
    """Remove the sections the catalogue entry above already states.

    The transcript path skips FRONTMATTER and ABSTRACT before emitting; a page read back from
    HTML has to have the same thing done to it, or every hand-built paper prints its abstract
    twice -- once as the entry's Abstract line and once as the article's own first section."""
    out, skipping = [], False
    for line in md.split("\n"):
        m = re.match(r"^(#{2,6})\s+(.*)$", line)
        if m:
            skipping = m.group(2).strip().split(":")[0].strip().upper() in _SKIP_SECTIONS
            if skipping:
                continue
        if not skipping:
            out.append(line)
    return "\n".join(out).strip("\n")


# The two hand-built pages, and where their text actually lives.
_HAND_BUILT = {"guidelines": "guidelines/guide", "maive": "maive/paper"}


def full_text_of(project):
    path = os.path.join(_TRANSCRIPTS, f"{project}.md")
    if not os.path.isfile(path):
        rel = _HAND_BUILT.get(project)
        return _from_page(rel) if rel else None
    with open(path, encoding="utf-8") as fh:
        return _plain(fh.read())


def extra_documents():
    """Documents this site republishes that are not one of the papers.

    The practitioner's guide and the MAIVE supplement are the two things a reader most often
    wants the substance of, and neither has an entry in papers.json to hang off."""
    out = []
    reg = os.path.join(SITE, "tools", "documents.json")
    if os.path.isfile(reg):
        with open(reg, encoding="utf-8") as fh:
            for d in json.load(fh):
                body = full_text_of(d["project"])
                if not body:
                    continue
                head = [f"## {d['title']}", f"URL: {BASE}/{d['slug'].strip('/')}/"]
                if d.get("reference_line"):
                    head.append(f"Citation: {d['reference_line']}")
                if d.get("doi_or_publisher_url"):
                    head.append(f"Published version: {d['doi_or_publisher_url']}")
                out.append((head + [""], body))
    return out


def main():
    metas = {m["project"]: m for m in json.load(open(META, encoding="utf-8"))}
    # Every surname in `authors` must appear in that paper's `reference_line`. The two are
    # written by hand and read by different things -- `authors` feeds the JSON-LD and the
    # Highwire tags, `reference_line` feeds the visible citation and the how-to-cite block --
    # so a name can be right in one and wrong in the other for a long time without anyone
    # noticing. One was: a co-author's surname was misspelled in the citation line only.
    for proj, m in sorted(metas.items()):
        ref = m.get("reference_line") or ""
        if not ref:
            continue
        for full in (m.get("authors") or []):
            surname = full.split()[-1]
            if surname and surname not in ref:
                WARNINGS.append(
                    f"{proj}: '{surname}' is in authors but not in reference_line — "
                    f"one of the two is misspelled, and they are read by different things")
    # filesystem is the source of truth for WHICH pages exist
    projects = sorted(d for d in os.listdir(SITE)
                      if os.path.isfile(os.path.join(SITE, d, "index.html"))
                      and d not in SELF_MANAGED)
    merged = {}
    for proj in projects:
        raw = open(os.path.join(SITE, proj, "index.html"), "rb").read().decode("utf-8")
        # parse the page WITHOUT our own previous injection (else we'd mistake
        # our injected meta description for the page's own and then drop it),
        raw_clean = re.sub(re.escape(S_OPEN) + r".*?" + re.escape(S_CLOSE) + r"\r?\n?",
                           "", raw, flags=re.S)
        # and flag hand-written metadata that would collide with our block
        # (this is what happened on /debate before it was cleaned up)
        for fam, pat in (("citation_*", r'name="citation_'),
                         ("og:", r'property="og:'),
                         ("JSON-LD", r'application/ld\+json')):
            if re.search(pat, raw_clean):
                WARNINGS.append(f"{proj}: page contains hand-written {fam} metadata "
                                f"outside the seo-meta block — remove it or Scholar/"
                                f"crawlers will see conflicting duplicates")
        # the live page is the source of truth for mechanical facts
        base = fallback_parse(proj, raw_clean)
        if proj in metas:
            s = metas[proj]
            m = dict(base)   # title/abstract/menu/figure/keywords from CURRENT page
            for k in ("authors", "journal", "one_line", "doi_or_publisher_url",
                      "dataset_doi", "dataset_license", "license", "article_license",
                      "citation_title", "pending_files"):
                if s.get(k):
                    m[k] = s[k]
            if not m["abstract"] or len(m["abstract"]) < 80:
                m["abstract"] = s["abstract"]
            if not m["reference_line"]:
                m["reference_line"] = s["reference_line"]
            if base["year"] and s.get("year") and base["year"] != s["year"]:
                WARNINGS.append(f"{proj}: page year {base['year']} != papers.json "
                                f"{s['year']} — using page; review papers.json")
                m["year"] = base["year"]
            else:
                m["year"] = s.get("year") or base["year"]
            merged[proj] = m
        else:
            merged[proj] = base
            WARNINGS.append(f"{proj}: not in tools/papers.json — covered mechanically "
                            f"(no Scholar tags); ask your AI assistant to enrich papers.json")
    stale = sorted(set(metas) - set(projects))
    for s in stale:
        WARNINGS.append(f"papers.json entry '{s}' has no folder on disk (stale?)")

    ok = sum(inject(os.path.join(SITE, p, "index.html"), head_block(merged[p])) for p in projects)
    print(f"injected head block into {ok}/{len(projects)} project pages")

    items = [{"@type": "ListItem", "position": i + 1, "url": f"{BASE}/{p}/",
              "name": merged[p]["title"]} for i, p in enumerate(projects)]
    home_graph = {"@context": "https://schema.org", "@graph": [
        {"@type": "WebSite", "@id": BASE + "/#website", "url": BASE + "/",
         "name": "meta-analysis.cz",
         "alternateName": "Meta-Analysis in Economics and Social Sciences",
         "description": "Data, code, and papers for meta-analyses in economics and the social sciences, by Tomas Havranek and Zuzana Irsova of Charles University, Prague, and their co-authors.",
         # publisher stays singular: one person runs the domain. But 35 of the 52 papers
         # collected here are hers, and a graph that never names her leaves a search
         # engine or a model no way to connect this body of work to her at all. She is a
         # contributor to the site, which is what is true — not its publisher.
         # sameAs is an identity assertion between records, not a reading link, so the
         # language of the target is irrelevant. Wikidata is the anchor that matters:
         # it is language-neutral, it already carries his ORCID and Scopus id (which is
         # how these two items were confirmed to be the right people), and it is what
         # points on to the cs.wikipedia article, so linking that article too would be
         # redundant. The en.wikipedia "Tomáš Havránek" is a DIFFERENT PERSON, an ice
         # hockey player, and cs.wikipedia's undisambiguated title is a disambiguation
         # page listing three men — never link either.
         "publisher": {"@type": "Person", "@id": BASE + "/#th", "name": "Tomas Havranek",
                       "alternateName": ["Tomáš Havránek"],
                       # /about/ states the rank in prose and in its own Person node; the
                       # homepage node merges with it on @id, so it carries the same jobTitle.
                       "jobTitle": "Professor of Economics",
                       "affiliation": {"@type": "Organization", "name": "Charles University, Prague"},
                       "url": "https://www.tomashavranek.cz",
                       "sameAs": ["https://orcid.org/0000-0002-3158-2539",
                                  "https://www.wikidata.org/entity/Q41800151",
                                  "https://openalex.org/A5086665090"]},
         "contributor": [
             {"@id": BASE + "/#th"},
             {"@type": "Person", "@id": BASE + "/#zi", "name": "Zuzana Irsova",
              # every form this site prints her name in. /komentare/ alone uses the
              # accented double-barrelled form on 200-odd pages and the unaccented one
              # in the Posts titles; without them the graph offers no way to tell that
              # those are the same person as the "Zuzana Irsova" on the papers.
              "alternateName": ["Zuzana Iršová", "Zuzana Havránková",
                                "Zuzana Iršová Havránková", "Zuzana Irsova Havrankova"],
              "jobTitle": "Professor of Economics",
              "affiliation": {"@type": "Organization", "name": "Charles University, Prague"},
              "url": "https://www.irsova.com",
              "sameAs": ["https://orcid.org/0000-0002-0753-8124",
                         "https://www.wikidata.org/entity/Q41799025",
                         "https://openalex.org/A5072893157"]}]},
        # One creator on the list, not an author array repeated across 52 ListItems: the Person
        # nodes are already defined above, so a reference costs nothing and says the same thing.
        # (Site audit, 2026-08-04: the list carried only url and name per paper.)
        {"@type": "ItemList", "@id": BASE + "/#papers", "name": "Meta-analyses on this site",
         "creator": [{"@id": BASE + "/#th"}, {"@id": BASE + "/#zi"}],
         "numberOfItems": len(items), "itemListElement": items}]}
    home_block = "\n".join([
        f'<link rel="canonical" href="{BASE}/" />',
        '<meta property="og:site_name" content="meta-analysis.cz" />',
        '<meta property="og:type" content="website" />',
        '<meta property="og:title" content="Meta-Analysis in Economics and Social Sciences" />',
        '<meta property="og:description" content="Data and codes for papers on meta-analysis '
        'and research synthesis in economics and the social sciences, by Tomas Havranek, '
        'Zuzana Irsova of Charles University, Prague, and their co-authors" />',
        f'<meta property="og:url" content="{BASE}/" />',

        '<script type="application/ld+json">\n' + jdump(home_graph) + "\n</script>"]) + "\n"
    inject(os.path.join(SITE, "index.html"), home_block)

    # /datasets/ — the data layer's landing page. Hand-built and hand-designed; we
    # only inject the DataCatalog that makes its datasets discoverable. Each entry
    # points at the paper page's existing #dataset node rather than restating it, so
    # there is one description of each dataset, not two that can drift apart.
    dsets_index = os.path.join(SITE, "datasets", "index.html")
    if os.path.isfile(dsets_index):
        try:
            api = json.load(open(os.path.join(SITE, "api", "v1", "datasets.json"),
                                 encoding="utf-8"))
        except Exception as e:
            api = None
            WARNINGS.append(f"datasets/: cannot read api/v1/datasets.json ({e}) — "
                            f"DataCatalog not injected")
        if api:
            entries = [d for d in api["datasets"] if d.get("n_estimates")]
            catalog = {
                "@context": "https://schema.org", "@type": "DataCatalog",
                "@id": BASE + "/datasets/#catalog",
                "name": "meta-analysis.cz datasets",
                "description": (
                    f"{len(entries)} estimate-level datasets from meta-analyses in economics "
                    f"and the social sciences, {api['counts']['estimates_in_analysis_samples']:,} "
                    f"estimates in their analysis samples, "
                    f"each with the study characteristics hand-coded for the original paper."),
                "url": BASE + "/datasets/",
                # Connect the page to the archived deposit. Without this a machine cannot
                # tell that the DOI and this catalogue describe the same thing.
                **({"identifier": [
                        {"@type": "PropertyValue", "propertyID": "DOI", "value": api["concept_doi"],
                         "description": "Concept DOI - always resolves to the latest version"},
                        {"@type": "PropertyValue", "propertyID": "DOI", "value": api["doi"],
                         "description": "This version"}],
                    "sameAs": api["concept_doi_url"]} if api.get("concept_doi") else {}),
                # Correct HERE and only here: a DataCatalog describes the COMPILATION, which
                # is precisely what CC BY 4.0 covers. usageInfo carries the full scoping.
                "license": "https://creativecommons.org/licenses/by/4.0/",
                "usageInfo": BASE + "/LICENSE",
                "isAccessibleForFree": True,
                # `provider` used to point at BASE + "/#org", which the homepage graph never
                # defines - a dangling reference. Name the people the homepage does define.
                "creator": [{"@id": BASE + "/#th"}, {"@id": BASE + "/#zi"}],
                "dataset": [{"@id": f"{BASE}/{d['id']}/#dataset"} for d in entries],
                "distribution": [
                    {"@type": "DataDownload", "encodingFormat": "application/json",
                     "contentUrl": BASE + DATA_API,
                     "description": "Machine-readable index of every dataset"},
                    {"@type": "DataDownload", "encodingFormat": "text/csv",
                     "contentUrl": BASE + "/data/v1/estimates_harmonised.csv",
                     "description": "All literatures pooled into one estimate-level table"}]}
            # /datasets/ is in SELF_MANAGED only to suppress Highwire citation_* tags (it is
            # not a paper). Canonical and Open Graph got caught up in that by accident, and a
            # public front door with no canonical is weak in exactly the way this layer exists
            # to fix. Emit them here; still no citation_* tags.
            durl = BASE + "/datasets/"
            ddesc = (f"{len(entries)} estimate-level datasets from meta-analyses in economics and "
                     f"the social sciences, published as Parquet and CSV with column-level "
                     f"codebooks, plus a harmonised table pooling "
                     f"{api['counts'].get('literatures_in_harmonised_table', '')} literatures.")
            block = chr(10).join([
                f'<link rel="canonical" href="{durl}" />',
                f'<meta name="description" content="{html.escape(ddesc, quote=True)}" />',
                '<meta property="og:type" content="website" />',
                '<meta property="og:title" content="Datasets | meta-analysis.cz" />',
                f'<meta property="og:url" content="{durl}" />',
                f'<meta property="og:description" content="{html.escape(ddesc, quote=True)}" />',
                '<meta name="twitter:card" content="summary" />',
                '<script type="application/ld+json">'
                + json.dumps(catalog, ensure_ascii=False, separators=(",", ":"))
                + "</script>"])
            inject(dsets_index, block)
            print(f"datasets/: DataCatalog injected ({len(entries)} datasets)")
    print("injected homepage block")

    ai_bots = ["GPTBot", "OAI-SearchBot", "ClaudeBot", "Claude-SearchBot", "Claude-User",
               "CCBot", "Google-Extended", "Applebot-Extended", "PerplexityBot",
               "meta-externalagent", "Bytespider"]
    rb = ["# meta-analysis.cz — all crawlers welcome, including AI/LLM crawlers.",
          "User-agent: *", "Allow: /", ""]
    for b in ai_bots:
        rb += [f"User-agent: {b}", "Allow: /", ""]
    rb += [f"Sitemap: {BASE}/sitemap.xml", ""]
    open(os.path.join(SITE, "robots.txt"), "w", encoding="utf-8", newline="\n").write("\n".join(rb))

    gd = git_dates()
    lastmod = lambda rel: gd.get(rel.replace(os.sep, "/"), TODAY)
    urls = [(BASE + "/", lastmod("index.html"))]
    urls += [(f"{BASE}/{p}/", lastmod(f"{p}/index.html")) for p in projects]
    # Sub-pages of a project, one level down: /guidelines/guide/, /maive/paper/ and any
    # future full-text republication. `projects` is a ONE-LEVEL listing, and the recursive
    # walk below covers SELF_MANAGED sections only, so a page like this was enumerated by
    # nothing: absent from the sitemap and from llms.txt no matter how often the generator
    # ran, and invisible to verify_seo.py, which builds its page list the same way. A
    # full-text republication whose whole value is being findable was reachable only by
    # typing the URL.
    for p in projects:
        for sub in sorted(os.listdir(os.path.join(SITE, p))):
            sub_index = os.path.join(SITE, p, sub, "index.html")
            if not os.path.isfile(sub_index):
                continue
            with open(sub_index, encoding="utf-8") as _f:
                if 'name="robots" content="noindex' in _f.read(2000):
                    continue          # noindex pages do not belong in a sitemap
            urls.append((f"{BASE}/{p}/{sub}/", lastmod(f"{p}/{sub}/index.html")))
    pdf_rels = []
    for dp, dns, fns in os.walk(SITE):
        rel_dir = os.path.relpath(dp, SITE).replace(os.sep, "/")
        top = rel_dir.split("/")[0]
        if top in (".git", ".github", "conference", "tools"):
            dns[:] = []
            continue
        if not (rel_dir == "." or os.path.isfile(os.path.join(SITE, top, "index.html"))):
            continue
        for fn in sorted(fns):
            if fn.lower().endswith(".pdf"):
                rel = fn if rel_dir == "." else f"{rel_dir}/{fn}"
                pdf_rels.append(rel)
                urls.append((BASE + urllib.parse.quote("/" + rel), lastmod(rel)))
    # A legacy root-level PDF that is byte-identical to one inside a paper folder is the
    # same document under two URLs, and listing both splits the indexing and citation
    # signals between them. /inflation2.pdf is /conventional_wisdom/conventional_wisdom.pdf.
    # The file stays on disk so old inbound links keep resolving; only the sitemap entry
    # goes, so crawlers are pointed at the canonical path.
    by_hash = {}
    for rel in pdf_rels:
        try:
            h = hashlib.sha1(open(os.path.join(SITE, rel), "rb").read()).hexdigest()
        except OSError:
            continue
        by_hash.setdefault(h, []).append(rel)
    dropped = set()
    for h, rels in by_hash.items():
        if len(rels) < 2:
            continue
        # the canonical copy is the one that lives beside its paper page
        canon = sorted(rels, key=lambda r: ("/" not in r, r))[0]
        for r in rels:
            if r != canon and "/" not in r:
                dropped.add(BASE + urllib.parse.quote("/" + r))
                NOTES.append(f"sitemap: /{r} omitted, byte-identical to /{canon}; "
                             f"the file itself is kept so old links still resolve")
    if dropped:
        urls = [u for u in urls if u[0] not in dropped]
    # self-managed sections: list every page they generate, so the sitemap stays
    # the single authoritative index even though their metadata is written elsewhere
    for sec in sorted(SELF_MANAGED):
        sec_dir = os.path.join(SITE, sec)
        if not os.path.isfile(os.path.join(sec_dir, "index.html")):
            continue
        urls.append((f"{BASE}/{sec}/", lastmod(f"{sec}/index.html")))
        for dp, dns, fns in os.walk(sec_dir):
            dns[:] = [d for d in dns if d not in ("src", "__pycache__")]
            if dp == sec_dir or "index.html" not in fns:
                continue
            # A page that tells robots not to index it does not belong in the sitemap:
            # Search Console reports "submitted URL marked noindex" as an error.
            with open(os.path.join(dp, "index.html"), encoding="utf-8") as _f:
                if 'name="robots" content="noindex' in _f.read(2000):
                    continue
            rel = os.path.relpath(dp, SITE).replace(os.sep, "/")
            urls.append((f"{BASE}/{rel}/", lastmod(f"{rel}/index.html")))

    # The machine-readable artifacts. A sitemap is page-oriented by convention, which is why
    # these were never in it, but Google Dataset Search and several crawlers use sitemap
    # membership as a discovery signal -- and these are the highest-value URLs on the site.
    # The catalogue, the two dataset descriptors, the harmonised table in both formats, the
    # headline table and the two llms files were reachable only from prose that links them.
    for rel in ["api/v1/datasets.json", "api/v1/datapackage.json", "api/v1/croissant.json",
                "data/v1/estimates_harmonised.csv", "data/v1/estimates_harmonised.parquet",
                "estimates.csv", "llms.txt", "llms-full.txt"]:
        if os.path.isfile(os.path.join(SITE, rel)):
            urls.append((f"{BASE}/{rel}", lastmod(rel)))
    # One codebook per dataset: 45 URLs that document the columns of 45 files, and the only
    # place the per-dataset column semantics are published at all.
    cb_dir = os.path.join(SITE, "api", "v1", "codebooks")
    if os.path.isdir(cb_dir):
        for fn in sorted(os.listdir(cb_dir)):
            if fn.endswith(".json"):
                urls.append((f"{BASE}/api/v1/codebooks/{fn}", lastmod(f"api/v1/codebooks/{fn}")))

    sm = ['<?xml version="1.0" encoding="UTF-8"?>',
          '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
    sm += [f"  <url><loc>{loc}</loc><lastmod>{lm}</lastmod></url>" for loc, lm in urls]
    sm.append("</urlset>\n")
    open(os.path.join(SITE, "sitemap.xml"), "w", encoding="utf-8", newline="\n").write("\n".join(sm))
    print(f"sitemap: {len(urls)} URLs")

    # How many papers llms-full.txt actually carries the text of, counted rather than stated.
    _n_full = sum(1 for _p in projects if full_text_of(_p))
    lt = ["# meta-analysis.cz", "",
          "> Data, code, and papers for meta-analyses in economics and the social sciences, "
          "by Tomas Havranek and Zuzana Irsova of Charles University, Prague, and their co-authors. "
          "Each paper page links the full-text PDF "
          "and, for most papers, the dataset and estimation code.", "",
          "> Maintained by Tomas Havranek (in Czech Tomáš Havránek) and "
          "Zuzana Irsova (Zuzana Iršová, earlier work indexed as Zuzana Havránková) at the "
          "Institute of Economic Studies, Charles University, Prague. "
          f"Who they are: {BASE}/about/", "",
          "> **Licence: everything on this site is CC BY 4.0** "
           "(https://creativecommons.org/licenses/by/4.0/) — the papers, the datasets, their "
           "CSV and Parquet conversions, the pooled table, the codebooks, and this "
           "documentation. You may use, adapt and redistribute any of it, including "
           "commercially and including as training data for machine-learning models. The only "
           "condition is attribution: cite the source paper for a dataset, and the collection "
           "as DOI 10.5281/zenodo.21773678.", "", "## Papers", ""]
    # The link text is this site's plain-language name for the literature, which is also the
    # target page's <title>, so anchor and target agree. But this list sits under "## Papers"
    # in a file written to be ingested whole, and for 21 papers that name is not what the
    # journal printed -- with no citation anywhere else in the file to correct it. A model
    # trained on this would repeat an invented title back in a reference list, so where the two
    # differ the published one is stated outright.
    def _llms_line(p):
        m = merged[p]
        line = f"- [{m['title']}]({BASE}/{p}/): {m['one_line']}"
        pub = m.get("citation_title")
        if pub and pub != m["title"]:
            line += f' Published as "{pub}".'
        return line
    lt += [_llms_line(p) for p in projects]
    _api = {}
    try:
        _api = json.load(open(os.path.join(SITE, "api", "v1", "datasets.json"), encoding="utf-8"))
    except Exception:
        pass
    lt += ["", "## Data", ""]
    if _api.get("concept_doi"):
        # The version DOI is null between a version bump and its deposit. Interpolating it
        # unconditionally printed the literal string "None." into llms.txt -- the file whose whole
        # purpose is telling machines how to cite this -- so an answer engine was told the DOI of
        # version 1.0.0 was "None". Same class as doi.html keeping the previous release's value:
        # an absent value must produce no claim, not a claim with a placeholder in it.
        _ver = _api["harmonised_table"]["version"]
        _vd = (f" Version {_ver} specifically is DOI {_api['doi']}." if _api.get("doi")
               else f" Version {_ver} is the current release; cite the concept DOI and name the version.")
        lt += [f"- **Archived and citable**: {_api['concept_doi_url']} (DOI {_api['concept_doi']}) — "
               f"the concept DOI, which always resolves to the newest version.{_vd} "
               f"Cite the collection AND the individual paper whose data you use."]
    lt += [
           f"- [Dataset index / data API]({BASE}/api/v1/datasets.json): every dataset on this site "
           f"as machine-readable JSON — paper, DOI, row counts, file URLs, and which columns hold "
           f"the effect estimate and its standard error",
           f"- [Harmonised estimate-level table]({BASE}/data/v1/estimates_harmonised.csv): all "
           f"literatures pooled into one table, one row per harmonised observation (some "
           f"literatures contribute one row per impulse-response horizon), with effect, standard error, "
           f"t-statistic, sample size and shared study characteristics "
           # the maturity label is DERIVED; it read "; beta)" beside a link to the 1.0.0 file
           f"(also [Parquet]({BASE}/data/v1/estimates_harmonised.parquet); version "
           f"{_api['harmonised_table']['version']})",
           f"- [Per-dataset files]({BASE}/api/v1/datapackage.json): each dataset also published "
           f"individually as Parquet and CSV, with a column-level codebook giving every variable's "
           f"type, missingness and summary statistics — all URLs listed in datasets.json",
           f"- [API documentation]({BASE}/api/v1/README.md): endpoints, usage, licence, and what "
           f"is deliberately not in the harmonised table",
           "", "## Resources", "",
           f"- [Headline results for every paper]({BASE}/estimates.csv): one row per paper — the "
           f"parameter, the value the paper headlines, the sample it rests on, and the verbatim "
           f"sentence from the paper that each figure came from (CSV)",
           f"- [Every paper in full text]({BASE}/llms-full.txt): the whole corpus in one file -- "
           f"citation, links, abstract and the complete text of all {_n_full} papers, for LLM ingestion",
           f"- [Papers republished in full as HTML]({BASE}/papers/): the complete text of each "
           f"paper -- body, tables, figures, equations and references -- readable and quotable "
           f"without opening a PDF",
           f"- [About the site and who maintains it]({BASE}/about/): affiliations and ORCIDs",
           f"- [Sitemap]({BASE}/sitemap.xml): all pages and PDF full texts",
           f"- [Commentary and interviews]({BASE}/komentare/): op-eds, columns and interviews "
           f"(mostly Czech); machine index at {BASE}/komentare/llms.txt",
           f"- [Research notes]({BASE}/notes/): short notes on methods and papers",
           "- [EasyMeta](https://www.easymeta.org/): one-click meta-analysis web app (MAIVE, PET-PEESE, clustering)",
           "- [MAER-Net](https://www.maer-net.org/): Meta-Analysis of Economics Research Network",
           "", "## Optional", "",
           f"- [MAER-Net 2015 Prague Colloquium program]({BASE}/conference/MAER-Net2015_program.pdf): conference archive under /conference/", ""]
    open(os.path.join(SITE, "llms.txt"), "w", encoding="utf-8", newline="\n").write("\n".join(lt))

    lf = ["# meta-analysis.cz — full paper index", "",
          "Site: https://meta-analysis.cz/ — Data, code, and papers for meta-analyses in economics",
          "and the social sciences (Charles University, Prague). By Tomas Havranek",
          "(ORCID 0000-0002-3158-2539), Zuzana Irsova (ORCID 0000-0002-0753-8124), and coauthors.", "",
          "LICENCE: everything on this site is CC BY 4.0 "
          "(https://creativecommons.org/licenses/by/4.0/) - the papers, the datasets, their CSV and "
          "Parquet conversions, the pooled table, the codebooks, and this documentation. Free to use, "
          "adapt and redistribute, including commercially and including as training data for "
          "machine-learning models. The only condition is attribution: cite the source paper for a "
          "dataset, and the collection as DOI 10.5281/zenodo.21773678.", ""]
    for p in projects:
        m = merged[p]
        lf += [f"## {m['title']}", f"URL: {BASE}/{p}/"]
        if m["reference_line"]:
            lf.append(f"Citation: {m['reference_line']}")
        elif m["authors"]:
            lf.append(f"Authors: {', '.join(m['authors'])}")
        # One "Published version:" per entry. The page menu usually carries a link with that
        # same label, so emitting both put the key in twice -- once as the DOI and once as the
        # publisher's own URL -- and a flat key:value format read by a machine has no way to
        # tell which is meant. The DOI form wins; the menu's copy is dropped.
        emitted_labels = set()
        if m["doi_or_publisher_url"]:
            lf.append(f"Published version: {m['doi_or_publisher_url']}")
            emitted_labels.add("published version")
        lf += [f"{l['label']}: {absurl(p, l['href'])}" for l in m["menu_links"]
               if (l["href"].startswith(("http://", "https://"))
                   or local_exists(p, l["href"]))
               and l["label"].strip().lower() not in emitted_labels]
        # body tool links, not already listed in the menu
        seen_hrefs = {l["href"] for l in m["menu_links"]}
        lf += [f"{t['label']}: {t['href']}" for t in (m.get("tool_links") or [])
               if t["href"] not in seen_hrefs]
        # The full text, where this site carries one. It is the substantive document an LLM
        # crawler wants and it was reaching neither export -- sitemap.xml listed the nested
        # pages, llms.txt and llms-full.txt named only the parent landing page.
        _full = {"maive": "/maive/paper/", "guidelines": "/guidelines/guide/"}.get(
            p, f"/{p}/paper/")
        if os.path.isfile(os.path.join(SITE, _full.strip("/"), "index.html")):
            lf.append(f"Full text (HTML): {BASE}{_full}")
        lf += ["", f"Abstract: {m['abstract']}", ""]
        body = full_text_of(p)
        if body:
            lf += [body, ""]
    for doc, body in extra_documents():
        lf += doc + [body, ""]
    open(os.path.join(SITE, "llms-full.txt"), "w", encoding="utf-8", newline="\n").write("\n".join(lf))
    refresh_about_counts(_api)
    print("wrote robots.txt, sitemap.xml, llms.txt, llms-full.txt")

    if NOTES:
        print("\nNOTES (informational):")
        for n in NOTES:
            print("  - " + n)
    if WARNINGS:
        print("\nWARNINGS:")
        for w in WARNINGS:
            print("  ! " + w)
        sys.exit(1)

if __name__ == "__main__":
    main()
