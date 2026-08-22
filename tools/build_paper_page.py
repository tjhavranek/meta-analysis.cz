#!/usr/bin/env python3
"""Build a full-text article page from a transcript.

    python3 tools/build_paper_page.py <project> [<project> ...]
    python3 tools/build_paper_page.py --all

Reads tools/transcripts/<project>.md and the project's entry in tools/papers.json,
writes <project>/paper/index.html.

The transcript carries only what the paper says. Everything else -- the site shell, the
menu, the footer, the JSON-LD, the citation meta tags -- comes from papers.json, so fifty
pages cannot drift from each other and a fix to the shell is a fix everywhere.

TRANSCRIPT DIALECT
------------------
Block level, one construct per line unless noted:

    # anything                 ignored (the paper title, for a human reading the transcript)
    ## ABSTRACT                the abstract block; paragraphs until the next heading
    ## KEYWORDS: a, b, c       keyword line, rendered under the abstract
    ## FRONTMATTER             authors/affiliations block; paragraphs until the next heading
    ## 1 | INTRODUCTION        section heading (h2). Anchored as #sec-1
    ### 3.2 | Sub-heading      subsection (h3), anchored #sec-3-2
    #### Run-in heading        run-in heading (h4)
    ## REFERENCES              numbered reference list; entries are "1. ..." lines
    ## ENDNOTES                endnote list; entries are "i. ..." or "1. ..." lines

    $$ \\alpha_1 = ... $$ (7)  display equation, optional printed number in trailing parens
    $\\beta_1$                 inline mathematics, anywhere in a paragraph

    TABLE 1. Caption text      table caption; the pipe table on the following lines is the table
    TABLE 1 (continued). Cap   a second panel of the same printed table
    | a | b |                  markdown pipe table (the --- separator row is required)
    Note: ...                  the paragraph on the line directly after a table (no blank
                               line between them) is that table's note, whatever it starts
                               with. Do not add a "Note:" label the paper does not print.

    FIGURE 2. Caption text     figure caption; expects figures/fig2.png beside the page
    FIGURE 2 (no artwork). C   figure whose artwork is not reproduced; caption only

Inline: **bold**, *italic*, `code`, [text](url), ^{4} for a citation marker (linked to the
reference list when the paper numbers its references), _{i} for a subscript, and --- for an
em dash. Literal text is escaped; nothing in a transcript can inject markup.
"""

import html
import json
import os
import re
import sys

from latex2mathml.converter import convert as tex_to_mathml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANSCRIPTS = os.path.join(ROOT, "tools", "transcripts")

# ---------------------------------------------------------------- inline markup

_PLACEHOLDER = "\x00{}\x00"


def _mathml(tex, display=False):
    """LaTeX to MathML. A formula we cannot convert is shown as its own source, which is
    wrong-looking enough to be caught in review and still readable to a person."""
    try:
        out = tex_to_mathml(tex.strip())
    except Exception:
        return '<code class="tex-fallback">%s</code>' % html.escape(tex.strip())
    out = out.replace("\n", "")
    if display:
        out = out.replace('display="inline"', 'display="block"', 1)
    else:
        out = out.replace("<math ", '<math class="inl" ', 1)
    return out


def inline(text, refs_are_numbered=False, link_cites=True):
    """Escape the text, then apply the inline dialect. Math is converted first and parked
    behind placeholders so that markup characters inside a formula are never re-read."""
    parked = []

    def park(fragment):
        parked.append(fragment)
        return _PLACEHOLDER.format(len(parked) - 1)

    text = re.sub(r"\$([^$]+)\$", lambda m: park(_mathml(m.group(1))), text)
    text = html.escape(text, quote=False)

    # citation markers: ^{4} or ^{4,5} or ^{i}
    def cite(m):
        body = m.group(1)
        # In the author block a superscript is an affiliation key, never a citation: "c" and
        # "d" are also roman numerals, so linking them invents anchors that do not exist.
        if not link_cites:
            return "<sup>%s</sup>" % body
        if refs_are_numbered and re.fullmatch(r"[\d,\s–-]+", body):
            parts = []
            for tok in re.split(r"(,\s*)", body):
                if re.fullmatch(r"\d+", tok.strip()):
                    parts.append('<a href="#ref-%s">%s</a>' % (tok.strip(), tok.strip()))
                else:
                    parts.append(html.escape(tok))
            return '<sup class="cite">%s</sup>' % "".join(parts)
        if re.fullmatch(r"[ivxlcdm]+", body):
            return '<sup class="cite"><a href="#note-%s">%s</a></sup>' % (body, body)
        # References are author-year, so a bare number is an endnote marker, not a citation.
        if re.fullmatch(r"\d+", body):
            return '<sup class="cite"><a href="#note-%s">%s</a></sup>' % (body, body)
        return "<sup>%s</sup>" % body

    # Parked like mathematics: a superscript marker is often a run of asterisks, and left in
    # the stream the emphasis rules pair them across the markers ("***, **, and *" became
    # "<sup><i><b></sup>, <sup></b></sup>, and <sup></i></sup>").
    text = re.sub(r"\^\{([^}]*)\}", lambda m: park(cite(m)), text)
    text = re.sub(r"_\{([^}]*)\}", lambda m: "<sub>%s</sub>" % m.group(1), text)
    # Both link rules park their output. Otherwise the bare-URL rule reads the href the
    # markdown rule just wrote and links it again, nesting one anchor inside another.
    text = re.sub(r"\[([^\]]+)\]\((https?://[^)\s]+)\)",
                  lambda m: park('<a href="%s">%s</a>' % (m.group(2), m.group(1))), text)
    text = re.sub(r"(?<![\w/])(https?://[^\s<>)\]]+[\w/])",
                  lambda m: park('<a href="%s">%s</a>' % (m.group(1), m.group(1))), text)
    text = re.sub(r"`([^`]+)`", lambda m: "<code>%s</code>" % m.group(1), text)
    text = re.sub(r"\*\*([^*]+)\*\*", lambda m: "<b>%s</b>" % m.group(1), text)
    text = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", lambda m: "<i>%s</i>" % m.group(1), text)
    text = text.replace("---", "&#8212;")

    for i, fragment in enumerate(parked):
        text = text.replace(_PLACEHOLDER.format(i), fragment)
    return text


# ---------------------------------------------------------------- block parsing

RE_H2 = re.compile(r"^##\s+(?!#)(.*)$")
RE_H3 = re.compile(r"^###\s+(?!#)(.*)$")
RE_H4 = re.compile(r"^####\s+(.*)$")
RE_EQ = re.compile(r"^\$\$(.+?)\$\$\s*(?:\(([^)]+)\))?\s*$")
RE_TABLE_CAP = re.compile(
    r"^TABLE\s+([A-Za-z]?\.?\d+(?:\.\d+)?[A-Za-z]?)"
    r"(\s*\(\s*(?:continued|cont\.?)\s*\))?\s*\.\s*(.*)$", re.I)
# An appendix table is numbered "A.1" as often as "A1", and the dot between the letter and
# the number is not the full stop that ends the caption's number: without the optional dot
# here, "TABLE A.1. Caption" is not a caption at all and prints as a stray paragraph above
# an untitled table.
# "(continued)" is written either before or after the caption's full stop, depending on who
# transcribed it. Both mean the same thing: this is the second panel of a table too tall for
# one printed page, not a second table with the same number.
RE_CONT_LEAD = re.compile(r"^\(\s*(?:continued|cont\.?)\s*\)\s*", re.I)
RE_FIG_CAP = re.compile(
    r"^FIGURE\s+([A-Za-z]?\d+(?:\.\d+)?[A-Za-z]?)(\s*\(no artwork\))?\s*\.\s*(.*)$", re.I)
RE_LIST_ITEM = re.compile(r"^([0-9]+|[ivxlcdm]+)\.\s+(.*)$")


def slug(text):
    text = text.lower().replace(".", "-")
    text = re.sub(r"[^\w\s-]", "", text)
    return re.sub(r"[\s_]+", "-", text).strip("-")


class Builder:
    def __init__(self, project, meta):
        self.project = project
        self.meta = meta
        self.out = []
        self.toc = []
        self.refs_numbered = False
        self.in_frontmatter = False
        self._ref_seq = 0
        self.abstract = []

    # -- emit helpers
    def w(self, s):
        self.out.append(s)

    def para(self, lines):
        if not lines:
            return
        text = " ".join(l.strip() for l in lines).strip()
        if text and getattr(self, "_collect_abstract", False):
            self.abstract.append(re.sub(r"[*`]", "", text))
        if text:
            # A superscript in the author block marks an affiliation, not a reference.
            self.w("<p>%s</p>" % inline(text, self.refs_numbered, not self.in_frontmatter))

    def build(self, src):
        # Only a "1." *inside the reference list* means the references are numbered. A paper
        # with author-year references and numbered endnotes has a "1." too, and reading it as
        # a reference number sends every endnote marker to a #ref- anchor that does not exist.
        # The list ends at the next heading: several papers print their endnotes after their
        # references, so "somewhere below the REFERENCES line" is not the same section.
        m_refs = re.search(r"^##\s+REFERENCES.*$", src, re.M)
        self.refs_numbered = False
        if m_refs:
            rest = src[m_refs.end():]
            m_next = re.search(r"^##\s+", rest, re.M)
            section = rest[:m_next.start()] if m_next else rest
            self.refs_numbered = bool(re.search(r"^1\.\s", section, re.M))
        lines = src.split("\n")
        i = 0
        buf = []
        mode = None          # None | 'abstract' | 'frontmatter' | 'references' | 'endnotes'
        pending_table = None  # (number, caption)
        pending_fig = None    # (number, caption, has_art)
        just_closed_table = False

        def flush():
            nonlocal buf
            self.para(buf)
            buf = []

        def close_mode():
            nonlocal mode
            if mode in ("abstract", "frontmatter"):
                self.w("</div>")
                self.in_frontmatter = False
                self._collect_abstract = False
            elif mode in ("references", "endnotes"):
                self.w("</ol>")
            mode = None

        while i < len(lines):
            line = lines[i]
            stripped = line.strip()

            if not stripped:
                flush()
                just_closed_table = False
                i += 1
                continue

            if stripped.startswith("#") and not stripped.startswith("####"):
                m2, m3 = RE_H2.match(stripped), RE_H3.match(stripped)
                if stripped.startswith("# ") and not m2 and not m3:
                    i += 1
                    continue

            m = RE_H4.match(stripped)
            if m:
                flush()
                self.w('<h4 class="runin">%s</h4>' % inline(m.group(1), self.refs_numbered))
                i += 1
                continue

            m = RE_H3.match(stripped)
            if m:
                flush()
                if mode in ("references", "endnotes"):
                    close_mode()
                head = m.group(1).strip()
                anchor = "sec-" + slug(head.split("|")[0].strip() or head)
                self.w('<h3 id="%s">%s</h3>' % (anchor, inline(head, self.refs_numbered)))
                self.toc.append((3, anchor, head))
                i += 1
                continue

            m = RE_H2.match(stripped)
            if m:
                flush()
                close_mode()
                head = m.group(1).strip()
                upper = head.upper()
                if upper.startswith("KEYWORDS:"):
                    self.w('<p class="keywords"><b>Keywords:</b> %s</p>'
                           % inline(head.split(":", 1)[1].strip(), self.refs_numbered))
                    i += 1
                    continue
                if upper == "FRONTMATTER":
                    self.w('<div class="frontmatter">')
                    mode = "frontmatter"
                    self.in_frontmatter = True
                    i += 1
                    continue
                if upper == "ABSTRACT":
                    self.w('<div class="abstract">')
                    self.w("<h2>Abstract</h2>")
                    mode = "abstract"
                    self._collect_abstract = True
                    i += 1
                    continue
                anchor = "sec-" + slug(head.split("|")[0].strip() or head)
                self.w('<h2 id="%s">%s</h2>' % (anchor, inline(head, self.refs_numbered)))
                self.toc.append((2, anchor, head))
                if upper.startswith("REFERENCES"):
                    self.w('<ol class="references%s">'
                           % ("" if self.refs_numbered else " unnumbered"))
                    mode = "references"
                elif upper.startswith("ENDNOTE"):
                    self.w('<ol class="endnotes">')
                    mode = "endnotes"
                i += 1
                continue

            if mode in ("references", "endnotes"):
                m = RE_LIST_ITEM.match(stripped)
                if m:
                    key, body = m.group(1), m.group(2)
                    j = i + 1
                    while j < len(lines) and lines[j].strip() and not RE_LIST_ITEM.match(lines[j].strip()) \
                            and not lines[j].strip().startswith("#"):
                        body += " " + lines[j].strip()
                        j += 1
                    idprefix = "ref-" if mode == "references" else "note-"
                    style = ""
                    if mode == "references" and key.isdigit():
                        # The CSS counter already produces 1, 2, 3 ... Only a list whose
                        # printed numbers skip needs to be told where it is, and writing the
                        # style on every item otherwise leaves a no-op on every line.
                        expected = self._ref_seq + 1
                        if int(key) != expected:
                            style = ' style="counter-reset:rf %d"' % (int(key) - 1)
                        self._ref_seq = int(key)
                    self.w('<li id="%s%s"%s>%s</li>'
                           % (idprefix, key, style, inline(body, self.refs_numbered)))
                    i = j
                    continue
                if mode == "references":
                    # An author-year reference list carries no numbers to key an id off; the
                    # entries are still list items, one per paragraph, not loose <p> in an <ol>.
                    body = stripped
                    j = i + 1
                    while j < len(lines) and lines[j].strip() and not lines[j].strip().startswith("#"):
                        body += " " + lines[j].strip()
                        j += 1
                    self.w("<li>%s</li>" % inline(body, self.refs_numbered))
                    i = j
                    continue

            m = RE_EQ.match(stripped)
            if m:
                flush()
                tex, num = m.group(1), m.group(2)
                self.w('<div class="eqn"><div class="eqbody">%s</div>%s</div>' % (
                    _mathml(tex, display=True),
                    '<div class="eqno">(%s)</div>' % html.escape(num) if num else ""))
                i += 1
                continue

            m = RE_TABLE_CAP.match(stripped)
            if m:
                flush()
                num, cont, cap = m.group(1), bool(m.group(2)), m.group(3)
                if RE_CONT_LEAD.match(cap):
                    cap = RE_CONT_LEAD.sub("", cap)
                    cont = True
                pending_table = (num, cap, cont)
                i += 1
                continue

            m = RE_FIG_CAP.match(stripped)
            if m:
                flush()
                pending_fig = (m.group(1), m.group(3), not m.group(2))
                self.emit_figure(*pending_fig)
                pending_fig = None
                i += 1
                continue

            if stripped.startswith("|"):
                flush()
                rows = []
                while i < len(lines) and lines[i].strip().startswith("|"):
                    rows.append(lines[i].strip())
                    i += 1
                self.emit_table(rows, pending_table)
                pending_table = None
                just_closed_table = True
                continue

            # A paragraph that follows a table with no blank line between them is that
            # table's note, whatever word it starts with. Requiring it to start with "Note"
            # made transcribers write a label the journal had not printed.
            if just_closed_table:
                j = i
                note = []
                while j < len(lines) and lines[j].strip():
                    note.append(lines[j].strip())
                    j += 1
                self.w('<p class="table-note">%s</p>' % inline(" ".join(note), self.refs_numbered))
                i = j
                just_closed_table = False
                continue

            buf.append(line)
            i += 1

        flush()
        close_mode()
        return "\n".join(self.out)

    def emit_table(self, rows, caption):
        cells = [[c.strip() for c in r.strip("|").split("|")] for r in rows]
        body = [r for r in cells if not all(re.fullmatch(r":?-{2,}:?", c or "-") for c in r)]
        if not body:
            return
        header, rest = body[0], body[1:]
        self.w('<div class="table-scroll">')
        cont = bool(caption and len(caption) > 2 and caption[2])
        self.w('<table%s>' % (' class="continued"' if cont else ""))
        if caption:
            num, cap = caption[0], caption[1]
            self.w("<caption><b>Table %s%s.</b> %s</caption>" % (
                html.escape(num), " (continued)" if cont else "",
                inline(cap, self.refs_numbered)))
        self.w("<thead><tr>%s</tr></thead>" % "".join(
            '<th scope="col">%s</th>' % inline(c, self.refs_numbered) for c in header))
        self.w("<tbody>")
        for r in rest:
            tds = []
            for k, c in enumerate(r):
                numeric = bool(re.fullmatch(r"[\s−–<>=.,%\d()+-]*", c)) and any(
                    ch.isdigit() for ch in c)
                if k == 0:
                    tds.append('<th scope="row">%s</th>' % inline(c, self.refs_numbered))
                else:
                    tds.append('<td%s>%s</td>' % (' class="num"' if numeric else "",
                                                  inline(c, self.refs_numbered)))
            self.w("<tr>%s</tr>" % "".join(tds))
        self.w("</tbody></table></div>")

    def emit_figure(self, num, caption, has_art):
        if has_art:
            src = "figures/fig%s.png" % num
            if not os.path.exists(os.path.join(ROOT, self.project, "paper", src)):
                raise SystemExit("%s: figure %s has no artwork at %s/paper/%s"
                                 % (self.project, num, self.project, src))
            self.w("<figure>")
            # The caption says what the figure shows; a placeholder alt says nothing to
            # anyone who cannot see it.
            alt = re.sub(r"[*`]|\$[^$]*\$", "", caption)
            alt = re.sub(r"\s+([.,;:])", r"\1", re.sub(r"\s+", " ", alt)).strip()
            alt = "Figure %s. %s" % (num, alt) if alt else "Figure %s" % num
            self.w('<img src="%s" alt="%s" />' % (src, html.escape(alt[:300], quote=True)))
            self.w("<figcaption><b>Figure %s.</b> %s</figcaption>" % (
                html.escape(num), inline(caption, self.refs_numbered)))
            self.w("</figure>")
        else:
            self.w('<div class="fig-inpdf"><p><b>Figure %s.</b> %s</p></div>' % (
                html.escape(num), inline(caption, self.refs_numbered)))


# ---------------------------------------------------------------- page shell

FOOTER = None


def load_footer():
    """Take the footer from a page that already has it, so one footer exists on the site."""
    global FOOTER
    if FOOTER is None:
        src = open(os.path.join(ROOT, "maive", "paper", "index.html")).read()
        m = re.search(r"<footer class=\"site-foot\">.*?</footer>", src, re.S)
        FOOTER = m.group(0)
    return FOOTER


def esc_attr(s):
    return html.escape(s or "", quote=True)


def build_page(project, meta, body, toc):
    ref = meta.get("reference_line") or ""
    doi = meta.get("doi_or_publisher_url") or ""
    journal = meta.get("journal") or ""
    year = meta.get("year")
    authors = meta.get("authors") or []
    label = meta.get("title") or project        # how the site files it
    title = article_title(meta)                 # how the journal printed it
    abstract = (meta.get("abstract") or "").strip()

    ld = {
        "@context": "https://schema.org",
        "@graph": [{
            "@type": "ScholarlyArticle",
            "@id": "https://meta-analysis.cz/%s/paper/#article" % project,
            "mainEntityOfPage": "https://meta-analysis.cz/%s/paper/" % project,
            "url": "https://meta-analysis.cz/%s/paper/" % project,
            "headline": title,
            "name": title,
            "inLanguage": "en",
            "license": "https://creativecommons.org/licenses/by/4.0/",
            "isAccessibleForFree": True,
            "author": [{"@type": "Person", "name": a} for a in authors],
            "isPartOf": {"@id": "https://meta-analysis.cz/#website"},
        }]
    }
    art = ld["@graph"][0]
    if abstract:
        art["abstract"] = abstract
    if year:
        art["datePublished"] = str(year)
    if journal:
        art["isPartOf"] = {"@type": "Periodical", "name": journal}
    if doi.startswith("https://doi.org/"):
        art["sameAs"] = doi
        art["identifier"] = {"@type": "PropertyValue", "propertyID": "DOI",
                             "value": doi.replace("https://doi.org/", "")}

    cite_meta = ['<meta name="citation_title" content="%s" />' % esc_attr(title)]
    cite_meta += ['<meta name="citation_author" content="%s" />' % esc_attr(a) for a in authors]
    if year:
        cite_meta.append('<meta name="citation_publication_date" content="%s" />' % year)
    if journal:
        cite_meta.append('<meta name="citation_journal_title" content="%s" />' % esc_attr(journal))
    if doi.startswith("https://doi.org/"):
        cite_meta.append('<meta name="citation_doi" content="%s" />'
                         % esc_attr(doi.replace("https://doi.org/", "")))

    pdf = meta.get("_pdf")
    if pdf:
        cite_meta.append('<meta name="citation_pdf_url" content="https://meta-analysis.cz/%s/%s" />'
                         % (project, pdf))

    desc = ("The full text of %s" % (ref.rstrip(". ") or title))[:300]

    toc_html = ""
    if len([t for t in toc if t[0] == 2]) >= 4:
        items = []
        depth = 2
        for level, anchor, head in toc:
            label = re.sub(r"\s*\|\s*", ". ", head).strip()
            if level == 3 and depth == 2:
                items.append("<ol>")
            elif level == 2 and depth == 3:
                items.append("</ol>")
            depth = level
            items.append('<li><a href="#%s">%s</a></li>' % (anchor, html.escape(label)))
        if depth == 3:
            items.append("</ol>")
        toc_html = ('<nav class="toc" aria-label="Contents"><h2>Contents</h2><ol>%s</ol></nav>'
                    % "".join(items))

    attribution = ["<div class=\"attribution\">"]
    attr_p = []
    if ref:
        attr_p.append(inline(ref))
    if doi:
        attr_p.append('<a href="%s">%s</a>.' % (esc_attr(doi), html.escape(doi)))
    attribution.append("<p>%s</p>" % " ".join(attr_p))
    links = []
    if pdf:
        links.append('<a href="/%s/%s">Paper (PDF)</a>' % (project, pdf))
    if doi:
        links.append('<a href="%s">Version of record</a>' % esc_attr(doi))
    links.append('<a href="/%s/">Data and code</a>' % project)
    attribution.append('<p class="attr-links">%s</p>' % " &nbsp;&middot;&nbsp; ".join(links))
    attribution.append("</div>")

    menu = ['<li class="current_page_item"><a href="/%s/paper/">Full text</a></li>' % project]
    if pdf:
        menu.append('<li><a href="/%s/%s">Paper (PDF)</a></li>' % (project, pdf))
    if doi:
        menu.append('<li><a href="%s">Version of record</a></li>' % esc_attr(doi))
    menu.append('<li><a href="/%s/">Data and code</a></li>' % project)
    menu.append('<li><a href="/">All meta-analyses</a></li>')

    return """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>{title} (full text)</title>
<meta name="description" content="{desc}" />
<link href="/style.css" rel="stylesheet" type="text/css" />
<link href="/paper.css" rel="stylesheet" type="text/css" />
<link rel="canonical" href="https://meta-analysis.cz/{project}/paper/" />
{cite_meta}
<meta property="og:site_name" content="meta-analysis.cz" />
<meta property="og:type" content="article" />
<meta property="og:title" content="{title} (full text)" />
<meta property="og:description" content="{desc}" />
<meta property="og:url" content="https://meta-analysis.cz/{project}/paper/" />
<script type="application/ld+json">
{ld}
</script>
</head>
<body>
<div id="wrapper">
<!-- start header -->
<div id="logo">
\t<a class="masthead-home" href="/">meta-analysis.cz</a>
\t<p class="site-name"><a href="/{project}/">{short}</a></p>
\t<h2> <span class="mk">&raquo;</span>&nbsp;&nbsp;&nbsp; the full text</h2>
</div>
<div id="header">
\t<div id="menu">
\t\t<ul>
\t\t\t{menu}
\t\t</ul>
\t</div>
</div>
<!-- end header -->
<!-- start page -->
<div id="page">
\t<div id="content">
\t\t<div class="post">
\t\t\t<div class="entry">

{attribution}

{toc}

{body}

\t\t\t</div>
\t\t</div>
\t</div>
</div>
<!-- end page -->
{footer}
</div>
</body>
</html>
""".format(
        title=html.escape(title),
        short=html.escape(label if len(label) <= 60 else label.split(":")[0]),
        desc=esc_attr(desc),
        project=project,
        cite_meta="\n".join(cite_meta),
        ld=json.dumps(ld, indent=1, ensure_ascii=False),
        menu="\n\t\t\t".join(menu),
        attribution="\n".join(attribution),
        toc=toc_html,
        body=body,
        footer=load_footer(),
    )


RE_QUOTED_TITLE = re.compile(r"[\u201c\"]([^\u201d\"]{10,300})[\u201d\"]")


def article_title(meta):
    """The title the article was published under, not the label this site files it by.

    papers.json's "title" is the site's own name for a literature -- "A Meta-Analysis of the
    Price Elasticity of Gasoline Demand" -- which is how the catalogue should list it and is
    not what the journal printed. Twenty-one of the fifty-four differ. Putting the site label
    in citation_title tells Google Scholar the paper has a title it does not have, so the
    published title is taken from the quoted title in the reference line."""
    m = RE_QUOTED_TITLE.search(meta.get("reference_line") or "")
    if m:
        return m.group(1).strip().rstrip(",.").strip()
    return meta.get("title") or meta.get("project", "")


def paper_pdf(project, meta):
    for m in meta.get("menu_links") or []:
        href = (m.get("href") or "")
        if href.endswith(".pdf") and not href.startswith("http") and "appendix" not in href.lower():
            if os.path.exists(os.path.join(ROOT, project, href)):
                return href
    for cand in ("%s2.pdf" % project, "%s.pdf" % project):
        if os.path.exists(os.path.join(ROOT, project, cand)):
            return cand
    return None


def link_from_project_page(project):
    """Put a "Read it in full" link in the project page's menu, once.

    A page nobody can reach from the paper's own page is a page nobody reads, and doing
    this by hand fifty times is fifty chances to forget one."""
    path = os.path.join(ROOT, project, "index.html")
    if not os.path.exists(path):
        return False
    src = open(path).read()
    href = "/%s/paper/" % project
    if href in src:
        return False
    m = re.search(r"(<div id=\"menu\">\s*<ul>\s*(?:<li[^>]*>.*?</li>\s*)?)", src, re.S)
    if not m:
        return False
    entry = '\n\t\t\t<li><a href="%s">Read it in full</a></li>\n\t\t\t' % href
    src = src[:m.end()].rstrip() + entry + src[m.end():].lstrip()
    with open(path, "w") as fh:
        fh.write(src)
    return True


def main(argv):
    papers = {p["project"]: p for p in json.load(open(os.path.join(ROOT, "tools", "papers.json")))}
    if not argv or argv[0] == "--all":
        projects = sorted(p[:-3] for p in os.listdir(TRANSCRIPTS)
                          if p.endswith(".md") and not p.endswith(".draft.md"))
    else:
        projects = argv
    for project in projects:
        src_path = os.path.join(TRANSCRIPTS, "%s.md" % project)
        if not os.path.exists(src_path):
            raise SystemExit("no transcript at %s" % src_path)
        meta = dict(papers[project])
        meta["_pdf"] = paper_pdf(project, meta)
        builder = Builder(project, meta)
        body = builder.build(open(src_path).read())
        if builder.abstract:
            # papers.json's abstract is the site's summary of the literature; the page shows
            # the paper's own. The metadata should say what the page says.
            meta["abstract"] = " ".join(builder.abstract)
        page = build_page(project, meta, body, builder.toc)
        outdir = os.path.join(ROOT, project, "paper")
        os.makedirs(outdir, exist_ok=True)
        with open(os.path.join(outdir, "index.html"), "w") as fh:
            fh.write(page)
        linked = link_from_project_page(project)
        print("%-22s %6d bytes  %2d sections  %s%s" % (
            project, len(page), len(builder.toc),
            "figures " if "<figure>" in page else "",
            "linked" if linked else ""))


if __name__ == "__main__":
    main(sys.argv[1:])
