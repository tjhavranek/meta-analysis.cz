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
import json, os, re, sys, datetime, html, subprocess, urllib.parse

HERE = os.path.dirname(os.path.abspath(__file__))
SITE = os.environ.get("SEO_SITE_DIR", os.path.dirname(HERE))
META = os.path.join(HERE, "papers.json")
BASE = "https://meta-analysis.cz"
TODAY = datetime.date.today().isoformat()
WARNINGS = []
NOTES = []   # informational only -- never fail the build

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
    return {
        "project": proj, "title": title, "abstract": abstract or title,
        "reference_line": ref, "authors": None, "year": year, "journal": None,
        "doi_or_publisher_url": None, "menu_links": menu, "figure": fig,
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
           "abstract": m["abstract"], "inLanguage": "en"}
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
              "subjectOf": {"@id": page + "#paper"}}
        if dist:
            ds["distribution"] = dist
        if ext_landing:
            ds["sameAs"] = [l["href"] for l in ext_landing]
        if authors:
            ds["creator"] = authors
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
    else:
        lines.append(f'<meta property="og:image" content="{BASE}/images/img02.jpg" />')
        lines.append('<meta property="og:image:alt" content="meta-analysis.cz" />')
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

def main():
    metas = {m["project"]: m for m in json.load(open(META, encoding="utf-8"))}
    # filesystem is the source of truth for WHICH pages exist
    projects = sorted(d for d in os.listdir(SITE)
                      if os.path.isfile(os.path.join(SITE, d, "index.html")))
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
                      "dataset_doi", "dataset_license", "license", "citation_title",
                      "pending_files"):
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
         "description": "Data, code, and papers for meta-analyses in economics and the social sciences, by researchers at Charles University, Prague.",
         "publisher": {"@type": "Person", "name": "Tomas Havranek",
                        "affiliation": {"@type": "Organization", "name": "Charles University, Prague"},
                        "url": "https://www.tomashavranek.cz"}},
        {"@type": "ItemList", "@id": BASE + "/#papers", "name": "Meta-analyses on this site",
         "numberOfItems": len(items), "itemListElement": items}]}
    home_block = "\n".join([
        f'<link rel="canonical" href="{BASE}/" />',
        '<meta property="og:site_name" content="meta-analysis.cz" />',
        '<meta property="og:type" content="website" />',
        '<meta property="og:title" content="Meta-Analysis in Economics and Social Sciences" />',
        '<meta property="og:description" content="Data and codes for papers on meta-analysis and research synthesis in economics and the social sciences" />',
        f'<meta property="og:url" content="{BASE}/" />',
        f'<meta property="og:image" content="{BASE}/images/img02.jpg" />',
        '<meta property="og:image:alt" content="meta-analysis.cz" />',
        '<script type="application/ld+json">\n' + jdump(home_graph) + "\n</script>"]) + "\n"
    inject(os.path.join(SITE, "index.html"), home_block)
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
                urls.append((BASE + urllib.parse.quote("/" + rel), lastmod(rel)))
    sm = ['<?xml version="1.0" encoding="UTF-8"?>',
          '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
    sm += [f"  <url><loc>{loc}</loc><lastmod>{lm}</lastmod></url>" for loc, lm in urls]
    sm.append("</urlset>\n")
    open(os.path.join(SITE, "sitemap.xml"), "w", encoding="utf-8", newline="\n").write("\n".join(sm))
    print(f"sitemap: {len(urls)} URLs")

    lt = ["# meta-analysis.cz", "",
          "> Data, code, and papers for meta-analyses in economics and the social sciences, "
          "by researchers at Charles University, Prague. Each paper page links the full-text PDF "
          "and, for most papers, the dataset and estimation code.", "", "## Papers", ""]
    lt += [f"- [{merged[p]['title']}]({BASE}/{p}/): {merged[p]['one_line']}" for p in projects]
    lt += ["", "## Resources", "",
           f"- [Full paper index with abstracts and file links]({BASE}/llms-full.txt): one entry per paper, for LLM ingestion",
           f"- [Sitemap]({BASE}/sitemap.xml): all pages and PDF full texts",
           "- [EasyMeta](https://www.easymeta.org/): one-click meta-analysis web app (MAIVE, PET-PEESE, clustering)",
           "- [MAER-Net](https://www.maer-net.org/): Meta-Analysis of Economics Research Network",
           "", "## Optional", "",
           f"- [MAER-Net 2015 Prague Colloquium program]({BASE}/conference/MAER-Net2015_program.pdf): conference archive under /conference/", ""]
    open(os.path.join(SITE, "llms.txt"), "w", encoding="utf-8", newline="\n").write("\n".join(lt))

    lf = ["# meta-analysis.cz — full paper index", "",
          "Site: https://meta-analysis.cz/ — Data, code, and papers for meta-analyses in economics",
          "and the social sciences (Charles University, Prague). Maintained by Tomas Havranek and coauthors.", ""]
    for p in projects:
        m = merged[p]
        lf += [f"## {m['title']}", f"URL: {BASE}/{p}/"]
        if m["reference_line"]:
            lf.append(f"Citation: {m['reference_line']}")
        elif m["authors"]:
            lf.append(f"Authors: {', '.join(m['authors'])}")
        if m["doi_or_publisher_url"]:
            lf.append(f"Published version: {m['doi_or_publisher_url']}")
        lf += [f"{l['label']}: {absurl(p, l['href'])}" for l in m["menu_links"]
               if l["href"].startswith(("http://", "https://")) or local_exists(p, l["href"])]
        lf += ["", f"Abstract: {m['abstract']}", ""]
    open(os.path.join(SITE, "llms-full.txt"), "w", encoding="utf-8", newline="\n").write("\n".join(lf))
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
