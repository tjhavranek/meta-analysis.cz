#!/usr/bin/env python3
"""
Build the /notes/ section of meta-analysis.cz.

Reads:   notes/notes.json      metadata for every note
         notes/src/<slug>.md   body of each note (small markdown subset)

Writes:  notes/<slug>/index.html   one page per note
         notes/index.html          the listing page
         notes/feed.xml            RSS 2.0, full text
         sitemap.xml               notes URLs refreshed in place, everything else untouched

No third-party dependencies. Run from anywhere:

    python notes/build_notes.py

Add a note in three steps: write notes/src/<slug>.md, add an entry to
notes/notes.json, re-run this script.
"""

import html
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

NOTES_DIR = Path(__file__).resolve().parent
ROOT = NOTES_DIR.parent
SITE = "https://meta-analysis.cz"
NOTES_URL = f"{SITE}/notes/"


# --------------------------------------------------------------------------
# a deliberately small markdown subset: headings, paragraphs, lists, links,
# bold, italic, inline code, blockquotes. enough for a research note, and
# small enough to stay dependency-free.
# --------------------------------------------------------------------------

def _inline(text):
    text = html.escape(text, quote=False)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<i>\1</i>", text)
    return text


def md_to_html(md):
    out, lines, i = [], md.replace("\r\n", "\n").split("\n"), 0
    while i < len(lines):
        line = lines[i].rstrip()

        if not line.strip():
            i += 1
            continue

        # raw html passthrough (figures, tables you want to hand-place)
        if line.lstrip().startswith("<"):
            block = []
            while i < len(lines) and lines[i].strip():
                block.append(lines[i])
                i += 1
            out.append("\n".join(block))
            continue

        m = re.match(r"^(#{2,4})\s+(.*)$", line)
        if m:
            lvl = len(m.group(1))
            out.append(f"<h{lvl}>{_inline(m.group(2))}</h{lvl}>")
            i += 1
            continue

        if line.lstrip().startswith(("- ", "* ")):
            items = []
            while i < len(lines) and lines[i].lstrip().startswith(("- ", "* ")):
                items.append(f"<li>{_inline(lines[i].lstrip()[2:].strip())}</li>")
                i += 1
            out.append("<ul>\n" + "\n".join(items) + "\n</ul>")
            continue

        if line.lstrip().startswith("> "):
            quote = []
            while i < len(lines) and lines[i].lstrip().startswith("> "):
                quote.append(lines[i].lstrip()[2:].strip())
                i += 1
            out.append(f"<blockquote><p>{_inline(' '.join(quote))}</p></blockquote>")
            continue

        para = []
        while i < len(lines) and lines[i].strip() and not lines[i].lstrip().startswith(("#", "- ", "* ", ">", "<")):
            para.append(lines[i].strip())
            i += 1
        out.append(f"<p>\n{_inline(' '.join(para))}\n</p>")

    return "\n\n".join(out)


# --------------------------------------------------------------------------
# templates, matching the existing site chrome (see /debate/index.html)
# --------------------------------------------------------------------------

def esc(s):
    return html.escape(s or "", quote=True)


def pretty_date(iso):
    return datetime.strptime(iso, "%Y-%m-%d").strftime("%d %B %Y").lstrip("0")


def rfc822(iso):
    d = datetime.strptime(iso, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    return d.strftime("%a, %d %b %Y %H:%M:%S +0000")


def sidebar(cfg, note=None):
    parts = ['<div id="sidebar">\n<ul>', """  <li id="search">
    <h2>Search</h2>
    <form method="get" action="https://www.google.com/search">
      <fieldset>
        <input type="text" id="s" name="q" value="" title="Search meta-analysis.cz" />
        <input type="hidden" name="as_sitesearch" value="meta-analysis.cz" />
        <input type="submit" id="x" value="Search" />
      </fieldset>
    </form>
  </li>"""]

    if note and note.get("links"):
        parts.append("<li>\n<h2>Materials</h2>\n<ul>")
        for l in note["links"]:
            parts.append(f'<li><a href="{esc(l["url"])}">{esc(l["label"])}</a></li>')
        parts.append("</ul>\n</li>")

    if note and note.get("syndicated"):
        parts.append("<li>\n<h2>Also posted on</h2>\n<ul>")
        for l in note["syndicated"]:
            parts.append(f'<li><a href="{esc(l["url"])}" rel="syndication">{esc(l["label"])}</a></li>')
        parts.append("</ul>\n</li>")

    parts.append("<li>\n<h2>Links</h2>\n<ul>")
    for l in cfg["sidebar_links"]:
        parts.append(f'<li><a href="{esc(l["url"])}">{esc(l["label"])}</a></li>')
    parts.append("</ul>\n</li>")
    parts.append("</ul>\n</div>")
    return "\n".join(parts)


PAGE = """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<title>{title}</title>
<meta name="keywords" content="{keywords}" />
<meta name="description" content="{summary}" />
<link href="/default.css" rel="stylesheet" type="text/css" />
<link rel="alternate" type="application/rss+xml" title="{feed_title}" href="{site}/notes/feed.xml" />

<!-- seo-meta:start -->
<link rel="canonical" href="{canonical}" />
{extra_meta}<meta property="og:site_name" content="meta-analysis.cz" />
<meta property="og:type" content="{og_type}" />
<meta property="og:title" content="{title}" />
<meta property="og:description" content="{summary}" />
<meta property="og:url" content="{canonical}" />
<script type="application/ld+json">
{jsonld}
</script>
<!-- seo-meta:end -->
</head>
<body>
<div id="wrapper">
<div id="logo">
	<h1><a href="{logo_href}">{logo}</a></h1>
	<h2> &raquo;&nbsp;&nbsp;&nbsp; {tagline}</h2>
</div>
<div id="header">
	<div id="menu">
		<ul>
			<li class="current_page_item"><a href="/notes/">Notes</a></li>
			<li><a href="/">Data &amp; code</a></li>
			<li><a href="/guidelines">Guidelines</a></li>
			<li><a href="{site}/notes/feed.xml">RSS</a></li>
		</ul>
	</div>
</div>
</div>
<div id="page">
	<div id="content">
		<div class="post">
			<h1 class="title">{heading}</h1>
{byline}
			<div class="entry">
{body}
			</div>
			<div class="meta">
				<p class="links"><a href="/notes/" class="more">All notes</a> &nbsp;&middot;&nbsp; <a href="/" class="more">More meta from Prague</a></p>
			</div>
		</div>
	</div>
{sidebar}
	<div style="clear: both;">&nbsp;</div>
</div>
</body>
</html>
"""


def build_note(cfg, note):
    slug = note["slug"]
    canonical = f"{SITE}/notes/{slug}/"
    body_md = (NOTES_DIR / "src" / f"{slug}.md").read_text(encoding="utf-8")
    body = md_to_html(body_md)

    authors = note.get("authors") or cfg["default_authors"]
    jsonld = {
        "@context": "https://schema.org",
        "@graph": [{
            "@type": "BlogPosting",
            "@id": canonical + "#note",
            "mainEntityOfPage": canonical,
            "url": canonical,
            "headline": note["title"],
            "name": note["title"],
            "abstract": note["summary"],
            "description": note["summary"],
            "inLanguage": "en",
            "datePublished": note["date"],
            "dateModified": note.get("updated", note["date"]),
            "keywords": ", ".join(note.get("keywords", [])),
            "author": [{"@type": "Person", "name": a["name"], "sameAs": a["orcid"]} for a in authors],
            "publisher": {"@type": "Organization", "name": "meta-analysis.cz", "url": SITE},
            "isPartOf": {"@type": "Blog", "@id": NOTES_URL + "#blog", "name": cfg["notes_title"]},
            "license": cfg["license_url"],
            "isAccessibleForFree": True,
        }]
    }
    if note.get("topics"):
        jsonld["@graph"][0]["about"] = [{"@type": "Thing", "name": t} for t in note["topics"]]
    if note.get("links"):
        jsonld["@graph"][0]["citation"] = [l["url"] for l in note["links"]]
    # the owned page is canonical; social copies are declared as syndicated duplicates
    if note.get("syndicated"):
        jsonld["@graph"][0]["sameAs"] = [l["url"] for l in note["syndicated"]]

    extra = (
        f'<meta name="author" content="{esc(authors[0]["name"])}" />\n'
        f'<meta property="article:published_time" content="{note["date"]}" />\n'
        f'<meta property="article:modified_time" content="{note.get("updated", note["date"])}" />\n'
    )

    byline = (
        f'\t\t\t<p class="byline">{pretty_date(note["date"])}'
        f' &nbsp;&middot;&nbsp; {esc(", ".join(a["name"] for a in authors))}'
        + (f' &nbsp;&middot;&nbsp; updated {pretty_date(note["updated"])}'
           if note.get("updated") and note["updated"] != note["date"] else "")
        + (f' &nbsp;&middot;&nbsp; {esc(" / ".join(note["topics"]))}'
           if note.get("topics") else "")
        + "</p>"
    )

    page = PAGE.format(
        title=esc(note["title"]), keywords=esc(", ".join(note.get("keywords", []))),
        summary=esc(note["summary"]), canonical=canonical, site=SITE,
        feed_title=esc(cfg["notes_title"]), extra_meta=extra, og_type="article",
        jsonld=json.dumps(jsonld, indent=1, ensure_ascii=False),
        logo=esc(cfg["notes_title"]), logo_href="/notes/", tagline=esc(cfg["notes_tagline"]),
        heading=esc(note["title"]), byline=byline, body=body, sidebar=sidebar(cfg, note),
    )
    out = NOTES_DIR / slug
    out.mkdir(exist_ok=True)
    (out / "index.html").write_text(page, encoding="utf-8")
    return canonical


def build_index(cfg, notes):
    rows = []
    for n in notes:
        rows.append(
            f'<h3><a href="/notes/{n["slug"]}/">{esc(n["title"])}</a></h3>\n'
            f'<p class="byline">{pretty_date(n["date"])}</p>\n'
            f'<p>{esc(n["summary"])}</p>\n'
            f'<p class="links"><a href="/notes/{n["slug"]}/" class="more">Read the note</a></p>\n<hr />'
        )
    jsonld = {
        "@context": "https://schema.org",
        "@graph": [{
            "@type": "Blog",
            "@id": NOTES_URL + "#blog",
            "url": NOTES_URL,
            "name": cfg["notes_title"],
            "description": cfg["notes_description"],
            "inLanguage": "en",
            "publisher": {"@type": "Organization", "name": "meta-analysis.cz", "url": SITE},
            "blogPost": [{
                "@type": "BlogPosting",
                "@id": f"{SITE}/notes/{n['slug']}/#note",
                "url": f"{SITE}/notes/{n['slug']}/",
                "headline": n["title"], "datePublished": n["date"], "abstract": n["summary"],
            } for n in notes],
        }]
    }
    page = PAGE.format(
        title=esc(cfg["notes_title"]), keywords=esc(", ".join(cfg["notes_keywords"])),
        summary=esc(cfg["notes_description"]), canonical=NOTES_URL, site=SITE,
        feed_title=esc(cfg["notes_title"]), extra_meta="", og_type="website",
        jsonld=json.dumps(jsonld, indent=1, ensure_ascii=False),
        logo=esc(cfg["notes_title"]), logo_href="/notes/", tagline=esc(cfg["notes_tagline"]),
        heading="Research notes",
        byline=f'\t\t\t<p class="byline">{cfg["notes_description"]}</p>',
        body="\n".join(rows) if rows else "<p>No notes yet.</p>", sidebar=sidebar(cfg),
    )
    (NOTES_DIR / "index.html").write_text(page, encoding="utf-8")


def build_feed(cfg, notes):
    items = []
    for n in notes:
        url = f"{SITE}/notes/{n['slug']}/"
        body = md_to_html((NOTES_DIR / "src" / f"{n['slug']}.md").read_text(encoding="utf-8"))
        items.append(f"""    <item>
      <title>{esc(n["title"])}</title>
      <link>{url}</link>
      <guid isPermaLink="true">{url}</guid>
      <pubDate>{rfc822(n["date"])}</pubDate>
      <description>{esc(n["summary"])}</description>
      <content:encoded><![CDATA[{body}]]></content:encoded>
    </item>""")
    feed = f"""<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <title>{esc(cfg["notes_title"])}</title>
    <link>{NOTES_URL}</link>
    <atom:link href="{SITE}/notes/feed.xml" rel="self" type="application/rss+xml" />
    <description>{esc(cfg["notes_description"])}</description>
    <language>en</language>
    <lastBuildDate>{rfc822(notes[0]["date"]) if notes else rfc822("2026-01-01")}</lastBuildDate>
{chr(10).join(items)}
  </channel>
</rss>
"""
    (NOTES_DIR / "feed.xml").write_text(feed, encoding="utf-8")


def update_sitemap(notes):
    """Refresh notes URLs in sitemap.xml, leaving every other entry untouched."""
    sm = ROOT / "sitemap.xml"
    text = sm.read_text(encoding="utf-8")
    text = re.sub(r"\s*<url><loc>https://meta-analysis\.cz/notes/[^<]*</loc>[^\n]*</url>", "", text)
    entries = [f'  <url><loc>{NOTES_URL}</loc><lastmod>{notes[0]["date"] if notes else ""}</lastmod></url>']
    for n in notes:
        entries.append(
            f'  <url><loc>{SITE}/notes/{n["slug"]}/</loc>'
            f'<lastmod>{n.get("updated", n["date"])}</lastmod></url>'
        )
    text = text.replace("</urlset>", "\n".join(entries) + "\n</urlset>")
    sm.write_text(text, encoding="utf-8")
    return len(entries)


def main():
    cfg = json.loads((NOTES_DIR / "notes.json").read_text(encoding="utf-8"))
    notes = sorted(cfg["notes"], key=lambda n: n["date"], reverse=True)

    missing = [n["slug"] for n in notes if not (NOTES_DIR / "src" / f"{n['slug']}.md").exists()]
    if missing:
        sys.exit(f"error: missing body files in notes/src/ for: {', '.join(missing)}")

    for n in notes:
        print("  note   ", build_note(cfg, n))
    build_index(cfg, notes)
    print("  index   ", NOTES_URL)
    build_feed(cfg, notes)
    print("  feed    ", f"{SITE}/notes/feed.xml")
    print(f"  sitemap  {update_sitemap(notes)} notes URLs refreshed")
    print(f"\n{len(notes)} note(s) built.")


if __name__ == "__main__":
    main()
