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

import hashlib
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
        if refs_are_numbered and re.fullmatch(r"[\d,\s\u2013\u2014-]+", body):
            # "4-6" cites three references, so it links three times: the range's own
            # endpoints and everything between, each to its entry.
            parts = []
            for tok in re.split(r"(,\s*)", body):
                t = tok.strip()
                m_range = re.fullmatch(r"(\d+)\s*[\u2013\u2014-]\s*(\d+)", t)
                if re.fullmatch(r"\d+", t):
                    parts.append('<a href="#ref-%s">%s</a>' % (t, t))
                elif m_range:
                    lo, hi = int(m_range.group(1)), int(m_range.group(2))
                    if 0 < hi - lo <= 40:
                        inner = "".join('<a href="#ref-%d">%d</a>%s'
                                        % (n, n, "" if n == hi else
                                           ("&#8211;" if n == lo else ""))
                                        for n in range(lo, hi + 1)
                                        if n in (lo, hi))
                        parts.append(inner)
                    else:
                        parts.append(html.escape(tok))
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
    # A DOI is a link whether or not the paper printed it as one, and the reference lists
    # carry theirs three ways: after a "doi:" label, bare, and as an https://doi.org/ URL
    # glued to the preceding word so the bare-URL rule above could not see it. All three
    # resolve identically. The closing character class keeps the link from swallowing the
    # sentence's full stop, which would send the reader to a DOI that does not exist.
    def _doi(m):
        prefix, doi = m.group(1) or "", m.group(2)
        if prefix.lower().startswith("http"):
            return park('<a href="https://doi.org/%s">%s%s</a>' % (doi, prefix, doi))
        return prefix + park('<a href="https://doi.org/%s">%s</a>' % (doi, doi))

    text = re.sub(r"(doi:\s*|https?://(?:dx\.)?doi\.org/)?"
                  r"(10\.\d{4,9}/[^\s<>\"]*[^\s<>\".,;:)\]])", _doi, text, flags=re.I)
    text = re.sub(r"`([^`]+)`", lambda m: "<code>%s</code>" % m.group(1), text)
    # Emphasis markers must hug their text: "*word*" is emphasis, "***, **, and *" is a
    # significance legend. Without the rule a table note came out as interleaved empty tags,
    # which is why transcribers started wrapping the legend in mathematics to protect it.
    _emph = r"(?=[^*]*[A-Za-z0-9])(\S(?:[^*]*\S)?)"
    text = re.sub(r"\*\*" + _emph + r"\*\*", lambda m: "<b>%s</b>" % m.group(1), text)
    text = re.sub(r"(?<!\*)\*" + _emph + r"\*(?!\*)", lambda m: "<i>%s</i>" % m.group(1), text)
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
        self._matched_refs = 0
        self.toc = []
        self.refs_numbered = False
        self.in_frontmatter = False
        self._ref_seq = 0
        # Every id emitted on the page, so a repeated one gets a suffix instead of a twin.
        # Papers print an endnote block per PDF page, so both the section anchor and the
        # note numbers repeat within one document.
        self._anchors = {}
        # Endnote <li> collected from every "## ENDNOTES" block, emitted once at the end.
        self._endnotes = []
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
            elif mode == "references":
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
                self.w('<h3 id="%s">%s</h3>'
                       % (anchor, inline(heading_label(head), self.refs_numbered)))
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
                if anchor in self._anchors:
                    self._anchors[anchor] += 1
                    anchor = "%s-%d" % (anchor, self._anchors[anchor])
                else:
                    self._anchors[anchor] = 1
                self.w('<h2 id="%s">%s</h2>'
                       % (anchor, inline(heading_label(head), self.refs_numbered)))
                self.toc.append((2, anchor, head))
                if upper.startswith("REFERENCES"):
                    # Filled in at the end of the render, once it is known whether any
                    # reference on this page actually got a matched link to explain.
                    self.w(REF_NOTE_SLOT)
                    self.w('<ol class="references%s">'
                           % ("" if self.refs_numbered else " unnumbered"))
                    mode = "references"
                elif upper.startswith("ENDNOTE"):
                    # Buffered, not emitted: see _endnotes.
                    self.out.pop()           # the <h2> just written
                    self.toc.pop()
                    self._anchors[anchor] -= 1
                    if not self._anchors[anchor]:
                        del self._anchors[anchor]
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
                    rendered = inline(body, self.refs_numbered)
                    if mode == "references":
                        # The matched DOI first: it is a link cites_on_site can then read,
                        # so a reference to a paper published here reaches it either way.
                        link = matched_doi_link(rendered)
                        self._matched_refs += bool(link)
                        rendered += link
                        rendered += cites_on_site(rendered, self.project)
                    lid = "%s%s" % (idprefix, key)
                    if lid in self._anchors:
                        self._anchors[lid] += 1
                        lid = "%s-%d" % (lid, self._anchors[lid])
                    else:
                        self._anchors[lid] = 1
                    item = '<li id="%s"%s>%s</li>' % (lid, style, rendered)
                    if mode == "endnotes":
                        self._endnotes.append(item)
                    else:
                        self.w(item)
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
                    rendered = inline(body, self.refs_numbered)
                    link = matched_doi_link(rendered)
                    self._matched_refs += bool(link)
                    rendered += link
                    self.w("<li>%s</li>" % (rendered + cites_on_site(rendered, self.project)))
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
                # A blank line between two rows is not the end of the table. Some transcripts
                # space their rows out, and reading a blank line as a boundary turned one of
                # beauty's tables into fifty-one tables of a single row each -- which a screen
                # reader announces as fifty-one tables, and which is not what the paper prints.
                # A table ends at the first line that is neither blank nor a row; the caption
                # of the next table is such a line, so two tables still cannot merge.
                while i < len(lines):
                    if lines[i].strip().startswith("|"):
                        rows.append(lines[i].strip())
                        i += 1
                        continue
                    if lines[i].strip():
                        break
                    j = i
                    while j < len(lines) and not lines[j].strip():
                        j += 1
                    if j < len(lines) and lines[j].strip().startswith("|"):
                        i = j
                        continue
                    break
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
        if self._endnotes:
            # One section, at the end, in the order the notes were met. The transcripts carry
            # a block per PDF page; inline they cut the running text, sometimes mid-word.
            self.w('<h2 id="sec-endnotes">ENDNOTES</h2>')
            self.toc.append((2, "sec-endnotes", "ENDNOTES"))
            self.w('<ol class="endnotes">')
            for item in self._endnotes:
                self.w(item)
            self.w("</ol>")
        page = rejoin_hyphens("\n".join(self.out))
        if self._matched_refs:
            return page.replace(REF_NOTE_SLOT, REF_NOTE)
        # With its newline: an unfilled slot must leave no trace, not a blank line.
        return page.replace(REF_NOTE_SLOT + "\n", "").replace(REF_NOTE_SLOT, "")

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
            if not os.path.exists(os.path.join(page_dir(self.project, self.meta), src)):
                raise SystemExit("%s: figure %s has no artwork at %s%s"
                                 % (self.project, num, page_href(self.project, self.meta), src))
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



_CANONICAL_PERSON = {
    "tomas havranek": ("https://meta-analysis.cz/#th", "https://orcid.org/0000-0002-3158-2539"),
    "t havranek": ("https://meta-analysis.cz/#th", "https://orcid.org/0000-0002-3158-2539"),
    "zuzana irsova": ("https://meta-analysis.cz/#zi", "https://orcid.org/0000-0002-0753-8124"),
    "zuzana havrankova": ("https://meta-analysis.cz/#zi", "https://orcid.org/0000-0002-0753-8124"),
    "zuzana irsova havrankova": ("https://meta-analysis.cz/#zi", "https://orcid.org/0000-0002-0753-8124"),
}


def _person_node(name):
    """Same mapping as generate_seo.person(): the two owners point at the canonical
    entities, every other co-author stays a bare named Person."""
    key = re.sub(r"[^a-z ]", "", (name or "").lower()).strip()
    hit = _CANONICAL_PERSON.get(key)
    if hit:
        return {"@type": "Person", "@id": hit[0], "name": name, "sameAs": hit[1]}
    return {"@type": "Person", "name": name}


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

    here = page_href(project, meta)
    home = meta.get("parent") or "/%s/" % project

    ld = {
        "@context": "https://schema.org",
        "@graph": [{
            "@type": "ScholarlyArticle",
            "@id": "https://meta-analysis.cz%s#article" % here,
            "mainEntityOfPage": "https://meta-analysis.cz%s" % here,
            "url": "https://meta-analysis.cz%s" % here,
            "headline": title,
            "name": title,
            "inLanguage": "en",
            "license": "https://creativecommons.org/licenses/by/4.0/",
            "isAccessibleForFree": True,
            "author": [_person_node(a) for a in authors],
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

    pdf = pdf_href(project, meta)
    if pdf:
        cite_meta.append('<meta name="citation_pdf_url" content="https://meta-analysis.cz%s" />'
                         % pdf)

    desc = ("The full text of %s" % (ref.rstrip(". ") or title))[:300]

    toc_html = ""
    if len([t for t in toc if t[0] == 2]) >= 4:
        # A sublist belongs INSIDE the item it hangs off, not beside it. Emitting it as a
        # sibling of the <li> is invalid, and every paper with subsections had it.
        items = []
        depth = 2
        open_li = False
        for level, anchor, head in toc:
            entry = heading_label(head)
            link = '<a href="#%s">%s</a>' % (anchor, html.escape(entry))
            if level == 3:
                if depth == 2:
                    items.append("<ol>")          # opens inside the still-unclosed <li>
                else:
                    items.append("</li>")
                items.append("<li>" + link)
            else:
                if depth == 3:
                    items.append("</li></ol>")
                if open_li:
                    items.append("</li>")
                items.append("<li>" + link)
                open_li = True
            depth = level
        if depth == 3:
            items.append("</li></ol>")
        if open_li:
            items.append("</li>")
        toc_html = ('<nav class="toc" aria-label="Contents"><h2>Contents</h2><ol>%s</ol></nav>'
                    % "".join(items))

    attribution = ["<div class=\"attribution\">"]
    attr_p = []
    if ref:
        attr_p.append(inline(ref))
    # Some reference lines already end with the DOI, and appending it again printed the
    # same URL twice in a row.
    if doi and doi.rstrip("/").replace("https://", "") not in (ref or ""):
        attr_p.append('<a href="%s">%s</a>.' % (esc_attr(doi), html.escape(doi)))
    attribution.append("<p>%s</p>" % " ".join(attr_p))
    parent_label = meta.get("parent_label")
    links = []
    if pdf:
        links.append('<a href="%s">%s (PDF)</a>' % (pdf, "Supplement" if parent_label else "Paper"))
    if doi:
        links.append('<a href="%s">Version of record</a>' % esc_attr(doi))
    links.append('<a href="%s">%s</a>' % (home, "The paper" if parent_label else "Data and code"))
    attribution.append('<p class="attr-links">%s</p>' % " &nbsp;&middot;&nbsp; ".join(links))
    attribution.append("</div>")

    menu = ['<li class="current_page_item"><a href="%s">Full text</a></li>' % here]
    if pdf:
        menu.append('<li><a href="%s">%s (PDF)</a></li>'
                    % (pdf, "Supplement" if parent_label else "Paper"))
    if doi:
        menu.append('<li><a href="%s">Version of record</a></li>' % esc_attr(doi))
    menu.append('<li><a href="%s">%s</a></li>'
                % (home, "The paper" if parent_label else "Data and code"))
    # A reader who has just finished one full text is the likeliest reader of another, and
    # from here the only way to the list of them was the home page.
    menu.append('<li><a href="/papers/">Papers in full</a></li>')
    menu.append('<li><a href="/">All meta-analyses</a></li>')
    # These pages carry no sidebar, so the search box that is on the rest of the site is not
    # on the 55 pages with the most text to search. A menu entry is the way in from here.
    menu.append('<li><a href="/search/">Search</a></li>')

    return """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>{title} (full text)</title>
<meta name="description" content="{desc}" />
<link href="/style.css" rel="stylesheet" type="text/css" />
<link href="/paper.css" rel="stylesheet" type="text/css" />
<link rel="canonical" href="https://meta-analysis.cz{here}" />
{cite_meta}
<meta property="og:site_name" content="meta-analysis.cz" />
<meta property="og:type" content="article" />
<meta property="og:title" content="{title} (full text)" />
<meta property="og:description" content="{desc}" />
<meta property="og:url" content="https://meta-analysis.cz{here}" />
<script type="application/ld+json">
{ld}
</script>
</head>
<body>
<div id="wrapper">
<!-- start header -->
<div id="logo">
\t<a class="masthead-home" href="/">meta-analysis.cz</a>
\t<p class="site-name"><a href="{home}">{short}</a></p>
\t<h2> <span class="mk">&raquo;</span>&nbsp;&nbsp;&nbsp; {strapline}</h2>
</div>
<div id="header">
\t<div id="menu">
\t\t<ul>
\t\t\t{menu}
\t\t</ul>
\t</div>
</div>
<!-- end header -->
</div>
<!-- start page -->
<div id="page">
\t<div id="content">
\t\t<div class="post">
\t\t\t<div class="entry">

<h1 class="paper-title">{h1}</h1>
{byline}

{attribution}

{toc}

{body}

\t\t\t</div>
\t\t</div>
\t</div>
</div>
<!-- end page -->
{footer}
</body>
</html>
""".format(
        title=html.escape(title),
        short=html.escape((parent_label or label) if len(parent_label or label) <= 60
                          else (parent_label or label).split(":")[0]),
        home=home,
        strapline="the supplement in full" if parent_label else "the full text",
        desc=esc_attr(desc),
        project=project,
        here=here,
        cite_meta="\n".join(cite_meta),
        ld=json.dumps(ld, indent=1, ensure_ascii=False),
        menu="\n\t\t\t".join(menu),
        attribution="\n".join(attribution),
        h1=html.escape(title),
        byline=('<p class="byline">%s</p>' % html.escape(
            ", ".join(authors[:-1]) + (" and " if len(authors) > 1 else "") + authors[-1])
            if authors else ""),
        toc=toc_html,
        body=body,
        footer=load_footer(),
    )


RE_QUOTED_TITLE = re.compile(r"[\u201c\"]([^\u201d\"]{10,300})[\u201d\"]")


PIPE_STYLE = False        # does this journal print "3.2 | Heading"? set per paper in main()


def heading_label(head):
    """A section heading as the paper prints it.

    The dialect writes "3.2 | Reducing bias" because Wiley sets its headings that way, with
    a rule between the number and the title. Most journals do not, and transcribers followed
    the dialect's example regardless, so the pipe leaked onto pages whose papers never print
    one. Whether to keep it is decided per paper by looking at the PDF, not by taste."""
    if PIPE_STYLE:
        return head.strip()
    return re.sub(r"\s*\|\s*", ". ", head).strip()


def prints_pipe_headings(project, meta):
    """True when the paper's own text layer sets numbered headings with a vertical rule."""
    import subprocess
    pdf = pdf_path(project, meta)
    if not pdf:
        return False
    try:
        text = subprocess.run(["pdftotext", "-f", "1", "-l", "12", pdf, "-"],
                              capture_output=True, text=True, check=True).stdout
    except Exception:
        return False
    return len(re.findall(r"^\s*\d+(?:\.\d+)?\s*\|\s*[A-Z]", text, re.M)) >= 2


def article_title(meta):
    """The title the article was published under, not the label this site files it by.

    papers.json's "title" is the site's own name for a literature -- "A Meta-Analysis of the
    Price Elasticity of Gasoline Demand" -- which is how the catalogue should list it and is
    not what the journal printed. Twenty-one of the fifty-five differ. Putting the site label
    in citation_title tells Google Scholar the paper has a title it does not have, so the
    published title is taken from the quoted title in the reference line.

    A document registered in documents.json is the exception: a supplement is cited by the
    article it belongs to, so its reference line quotes that article's title and not its
    own. There the registry's own title is the published one."""
    if meta.get("parent"):
        return meta.get("title") or meta.get("project", "")
    m = RE_QUOTED_TITLE.search(meta.get("reference_line") or "")
    if m:
        return m.group(1).strip().rstrip(",.").strip()
    return meta.get("title") or meta.get("project", "")


def documents():
    """Documents this site republishes that are not one of the papers.

    A supplement is not a paper: it has no entry in papers.json, no place in the site's
    catalogue and no headline result, but it is a document worth reading in HTML. Keeping
    it in its own small registry means the paper list stays what it says it is."""
    path = os.path.join(ROOT, "tools", "documents.json")
    if not os.path.exists(path):
        return {}
    return {d["project"]: d for d in json.load(open(path))}


def paper_pdf(project, meta):
    """The paper's PDF, named relative to <project>/.

    A registered document lives beside the paper it belongs to rather than in a directory
    of its own -- maive/supplement.pdf, not maive_supplement/supplement.pdf -- so its path
    is given from the site root and pdf_path() is what resolves either kind."""
    doc = documents().get(project)
    if doc:
        return doc["pdf"]
    # A paper filed under another project's landing (papers.json "parent") has no folder of
    # its own, so its entry names the PDF from the site root, like a registered document.
    if meta.get("parent") and meta.get("pdf"):
        return meta["pdf"]
    for m in meta.get("menu_links") or []:
        href = (m.get("href") or "")
        if href.endswith(".pdf") and not href.startswith("http") and "appendix" not in href.lower():
            if os.path.exists(os.path.join(ROOT, project, href)):
                return href
    for cand in ("%s2.pdf" % project, "%s.pdf" % project):
        if os.path.exists(os.path.join(ROOT, project, cand)):
            return cand
    return None


def pdf_path(project, meta):
    """Where that PDF actually is on disk.

    Papers keep theirs inside their own directory; documents registered in documents.json
    give a path from the site root, because a supplement sits next to its paper."""
    rel = paper_pdf(project, meta)
    if not rel:
        return None
    if project in documents() or meta.get("parent"):
        return os.path.join(ROOT, rel)
    return os.path.join(ROOT, project, rel)


# The two papers whose full text was written by hand before the toolchain existed, and does
# not live at the address the convention would put it. Declared once, here, because every
# tool that looks for a paper's page needs the same answer: tools/check_paper_pages.py had
# its own idea and so checked neither of them, which is how /maive/paper/ pointed at a
# deleted figure without anything noticing.
HAND_BUILT = {"maive": "maive/paper", "guidelines": "guidelines/guide",
              "reporting": "guidelines/reporting"}


def page_href(project, meta):
    """Where this page lives on the site.

    A paper's full text sits at /<project>/paper/. A registered document gives its own
    slug, because a supplement belongs beside the paper it supplements rather than in a
    directory of its own."""
    return "/%s/" % (meta.get("slug") or HAND_BUILT.get(project)
                     or "%s/paper" % project).strip("/")


def page_dir(project, meta):
    return os.path.join(ROOT, page_href(project, meta).strip("/"))


def pdf_href(project, meta):
    rel = meta.get("_pdf") or paper_pdf(project, meta)
    if not rel:
        return None
    if project in documents() or meta.get("parent"):
        return "/%s" % rel
    return "/%s/%s" % (project, rel)


_DOI_INDEX = None


def doi_index():
    """Every paper this site carries in full, keyed by its own DOI.

    A registered document shares the DOI of the paper it belongs to -- the MAIVE supplement
    carries the MAIVE article's -- so the paper wins the key. The DOI identifies the article,
    and a reference citing it is citing the article, not the supplement."""
    global _DOI_INDEX
    if _DOI_INDEX is None:
        idx = {}
        papers = json.load(open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))
        # documents first, papers second, so a paper overwrites a document on a shared DOI
        for meta in list(documents().values()) + papers:
            m = re.search(r"10\.\d{4,9}/\S+", meta.get("doi_or_publisher_url") or "")
            if m:
                idx[m.group(0).rstrip("/").lower()] = meta["project"]
        _DOI_INDEX = idx
    return _DOI_INDEX


def cites_on_site(rendered, project):
    """If a reference names another paper published here, link it to that paper.

    Exact DOI only. Matching references by title would be a guess dressed as a fact, and the
    edges this can prove are the ones worth drawing: 63 of them across the corpus."""
    for doi in re.findall(r'href="https://doi\.org/([^"]+)"', rendered):
        target = doi_index().get(doi.rstrip("/").lower())
        if target and target != project:
            meta = dict(documents().get(target) or {})
            if not meta:
                for p in json.load(open(os.path.join(ROOT, "tools", "papers.json"),
                                        encoding="utf-8")):
                    if p["project"] == target:
                        meta = p
                        break
            if not meta:
                continue
            href = page_href(target, meta)
            if os.path.exists(os.path.join(ROOT, href.strip("/"), "index.html")):
                return (' <a class="on-site" href="%s">Full text on this site</a>' % href)
    return ""


RE_HYPHEN_SPLIT = re.compile(r'([A-Za-z]{2,})-</p>\n<p>([a-z]{2,})')


def rejoin_hyphens(page):
    """A word broken by a PDF page break arrives as two paragraphs, "under-" then
    "perform". Join them, and let the document decide the hyphen: if the closed form occurs
    elsewhere in this paper it was a line break ("underperform"), and if the hyphenated form
    occurs it was a compound ("fixed-effects"). Anything the paper does not settle is left
    exactly as transcribed."""
    text = re.sub(r"<[^>]+>", " ", page).lower()

    def decide(m):
        a, b = m.group(1), m.group(2)
        closed, hyphen = (a + b).lower(), (a + "-" + b).lower()
        n_closed = len(re.findall(r"\b%s" % re.escape(closed), text))
        n_hyphen = len(re.findall(r"\b%s" % re.escape(hyphen), text))
        if n_closed and not n_hyphen:
            return a + b
        if n_hyphen and not n_closed:
            return a + "-" + b
        return m.group(0)

    return RE_HYPHEN_SPLIT.sub(decide, page)


REF_NOTE_SLOT = "<!--reference-note-->"
REF_NOTE = ('<p class="ref-note">Some entries below were printed without a link. Where a '
            'Crossref record matches one and no other record plausibly could, its DOI is '
            'shown; ambiguous references are left as they were printed.</p>')

_REF_DOIS = None


def reference_dois():
    """DOIs matched to references that were printed without one.

    This lives in a side file and NOT in the transcripts, on purpose. A transcript is
    checked word by word against its PDF; writing a DOI into one would be writing text the
    paper does not contain, and the fidelity gate would be right to fail it. The link is a
    rendering of the reference, not part of it, so it is attached at render time."""
    global _REF_DOIS
    if _REF_DOIS is None:
        path = os.path.join(ROOT, "tools", "reference_dois.json")
        try:
            with open(path, encoding="utf-8") as fh:
                _REF_DOIS = json.load(fh).get("entries", {})
        except FileNotFoundError:
            _REF_DOIS = {}
    return _REF_DOIS


def reference_key(rendered):
    """The identity of a reference is its visible text, and nothing else.

    Keying on the text rather than on (paper, position) means the same reference cited by
    six papers is matched once, and that renumbering or re-transcribing a reference list
    drops the stale links instead of moving them onto the wrong entries."""
    # Tags are removed, not replaced by a space: the matcher keys on exactly this string,
    # and the two must derive it the same way or every key misses by a space.
    text = html.unescape(re.sub(r"<[^>]+>", "", rendered))
    return hashlib.sha1(" ".join(text.split()).encode("utf-8")).hexdigest()[:16]


OUR_LINK = re.compile(r'\s*<a class="(?:ref-doi|on-site)"[^>]*>.*?</a>', re.S)


def strip_our_links(fragment):
    """Remove the links this builder appends, so re-reading a built page sees the reference
    as it was printed. Everything that keys on a reference's text depends on this."""
    return OUR_LINK.sub("", fragment)


def matched_doi_link(rendered):
    """Attach the matched DOI, if this reference has one and prints no link of its own."""
    if "<a " in rendered:
        return ""
    hit = reference_dois().get(reference_key(rendered))
    if not hit:
        return ""
    # No rel="nofollow": the DOI links this site already prints in running text carry none,
    # and a citation is the one kind of outbound link that is meant to be followed.
    return (' <a class="ref-doi" href="https://doi.org/%s">%s</a>'
            % (html.escape(hit["doi"], quote=True), html.escape(hit["doi"])))


def attach_reference_links(path):
    """Attach matched DOIs to a page this builder did not render.

    Two pages here are written by hand rather than generated from a transcript, and their
    reference lists are as unlinked as any other -- 158 entries between them. Rewriting the
    list items in place gives them the same links on the same evidence. Our own links are
    stripped first, so a re-run replaces them rather than stacking a second copy."""
    src = open(path, encoding="utf-8").read()
    m = re.search(r'<(ol|ul) class="references[^"]*">(.*?)</\1>', src, re.S)
    if not m:
        return 0
    added = [0]

    def one(mo):
        open_tag, body = mo.group(1), strip_our_links(mo.group(2))
        link = matched_doi_link(body)
        added[0] += bool(link)
        return "%s%s%s</li>" % (open_tag, body, link)

    rewritten = re.sub(r"(<li[^>]*>)(.*?)</li>", one, m.group(2), flags=re.S)
    listing = m.group(0).replace(m.group(2), rewritten, 1)
    src = src[:m.start()] + listing + src[m.end():]
    # With its newline, or a re-run leaves a blank line behind and the page never settles.
    src = src.replace(REF_NOTE + "\n", "").replace(REF_NOTE, "")
    if added[0]:
        src = src.replace(listing, REF_NOTE + "\n" + listing, 1)
    open(path, "w", encoding="utf-8").write(src)
    return added[0]


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
    papers.update(documents())
    if not argv or argv[0] == "--all":
        projects = sorted(p[:-3] for p in os.listdir(TRANSCRIPTS)
                          if p.endswith(".md") and not p.endswith(".draft.md"))
    else:
        projects = argv
    if not argv or argv[0] == "--all":
        for project, rel in sorted(HAND_BUILT.items()):
            path = os.path.join(ROOT, rel, "index.html")
            if os.path.exists(path):
                print("%-22s %6d reference link(s) attached (hand-built page)"
                      % (project, attach_reference_links(path)))

    for project in projects:
        src_path = os.path.join(TRANSCRIPTS, "%s.md" % project)
        if not os.path.exists(src_path):
            raise SystemExit("no transcript at %s" % src_path)
        meta = dict(papers[project])
        meta["_pdf"] = paper_pdf(project, meta)
        globals()["PIPE_STYLE"] = prints_pipe_headings(project, meta)
        builder = Builder(project, meta)
        body = builder.build(open(src_path).read())
        if builder.abstract:
            # papers.json's abstract is the site's summary of the literature; the page shows
            # the paper's own. The metadata should say what the page says.
            meta["abstract"] = " ".join(builder.abstract)
        page = build_page(project, meta, body, builder.toc)
        outdir = page_dir(project, meta)
        os.makedirs(outdir, exist_ok=True)
        with open(os.path.join(outdir, "index.html"), "w") as fh:
            fh.write(page)
        # A document hangs off the page of the paper it belongs to, which may be hand-built;
        # only a project page gets the link written into it here.
        linked = project not in documents() and link_from_project_page(project)
        print("%-22s %6d bytes  %2d sections  %s%s" % (
            project, len(page), len(builder.toc),
            "figures " if "<figure>" in page else "",
            "linked" if linked else ""))


if __name__ == "__main__":
    main(sys.argv[1:])
