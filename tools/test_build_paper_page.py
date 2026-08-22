#!/usr/bin/env python3
"""Regression tests for the transcript dialect.

    python3 tools/test_build_paper_page.py

Fifty pages are built by one script, and the script is edited while papers are being
converted -- the reference-list handling, the citation markers and the caption parsing
were all changed mid-run, each time for a good reason. This pins the behaviour those
changes have to preserve, so a fix for one paper cannot quietly break the other forty-nine.

Each case states the input in the dialect and asserts what must come out of it.
"""

import re
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0])

from build_paper_page import Builder, inline           # noqa: E402

FAILED = []


def check(name, condition, detail=""):
    if condition:
        print("  ok   %s" % name)
    else:
        print("  FAIL %s%s" % (name, (" -- " + detail) if detail else ""))
        FAILED.append(name)


def build(src, project="test"):
    b = Builder(project, {"title": "T"})
    return b.build(src), b


def test_numbered_references():
    body, _ = build("""## 1 | INTRO

As shown before.^{4}

## REFERENCES

1. First, A. A title. 2020.
4. Fourth, D. Another. 2021.
""")
    check("a numbered citation links to its reference",
          '<a href="#ref-4">4</a>' in body, body[:200])
    check("a reference keeps its printed number",
          'id="ref-4"' in body and "counter-reset:rf 3" in body)
    check("a numbered list is not marked unnumbered",
          '<ol class="references">' in body)


def test_author_year_references():
    body, _ = build("""## 1 | INTRO

As shown before.^{1}

## ENDNOTES

1. A note.

## REFERENCES

Abdel-khalek, G., 1988. Income and price elasticities. Energy Econ. 10 (1), 47-58.

Abreu, M., de Groot, H., 2005. A meta-analysis of convergence. J. Econ. Surv. 19, 389-420.
""")
    check("author-year entries are list items, not paragraphs",
          body.count("<li>") >= 2 and "<p>Abdel-khalek" not in body)
    check("an author-year list is marked unnumbered",
          'class="references unnumbered"' in body)
    check("with author-year references a bare marker is an endnote",
          '<a href="#note-1">1</a>' in body and 'href="#ref-1"' not in body)


def test_endnotes_printed_after_the_references():
    # Several papers close with references and then endnotes. A numbered endnote below the
    # REFERENCES heading is not a numbered reference, and reading it as one sent every
    # marker in the body to a #ref- anchor that was never emitted.
    body, _ = build("""## 1 | INTRO

As noted.^{1}

## REFERENCES

Aitken, B., Harrison, A., 1999. Do domestic firms benefit? Am. Econ. Rev. 89, 605-618.

## ENDNOTES

1. See Smeets (2008) for a survey.
""")
    check("an endnote below the references is not a reference number",
          'href="#ref-1"' not in body, body[:300])
    check("the marker links to the endnote instead",
          '<a href="#note-1">1</a>' in body and 'id="note-1"' in body)


def test_affiliation_markers_do_not_link():
    body, _ = build("""## FRONTMATTER

A. One^{a,b}, B. Two^{c}

## 1 | INTRO

Text.^{2}

## REFERENCES

1. One, A. 2020.
2. Two, B. 2021.
""")
    front = body[body.index('class="frontmatter"'):body.index("</div>")]
    check("an affiliation marker is not a citation link",
          "href=" not in front, front)
    check("a citation in the body still links",
          '<a href="#ref-2">2</a>' in body)


def test_emphasis_is_not_paired_across_markers():
    out = inline("Significant at 1%^{***}, 5%^{**}, and 10%^{*}.")
    check("asterisk markers do not pair as emphasis",
          "<i>" not in out and "<b>" not in out, out)


def test_significance_legend_is_not_emphasis():
    # "***, **, and *" is what a table note calls its significance stars. Read as emphasis
    # it becomes three interleaved empty tags, which is what the scc tables showed.
    out = inline("***, **, and * denote significance at the 1%, 5%, and 10% levels.")
    check("a significance legend stays literal",
          "<b>" not in out and "<i>" not in out and "***" in out, out)
    check("real emphasis still works",
          inline("a *word* and **another**") == "a <i>word</i> and <b>another</b>",
          inline("a *word* and **another**"))


def test_tables():
    body, _ = build("""## 1 | RESULTS

TABLE 1. A caption.
| Design | Bias |
|---|---|
| 0.7071 | 0.0455 |
Note: the note.

TABLE 2 (continued). Second panel.
| Design | Bias |
|---|---|
| 0.3162 | -0.0004 |
""")
    check("a caption is attached to its table",
          "<caption><b>Table 1.</b> A caption." in body)
    check("a continued panel keeps its number and says it is continued",
          body.count("<table") == 2 and "<b>Table 2 (continued).</b>" in body
          and '<table class="continued">' in body, body[-400:])
    check("a note after a table is a table note",
          '<p class="table-note">Note: the note.</p>' in body)
    check("numeric cells are marked numeric",
          '<td class="num">0.0455</td>' in body)


def test_math():
    body, _ = build("""## 1 | MODEL

Where $\\beta_1$ is the slope.

$$ r_p = \\frac{t}{\\sqrt{t^2 + \\mathrm{df}}} $$ (2)
""")
    check("inline mathematics becomes MathML",
          '<math class="inl"' in body)
    check("a display equation is block MathML with its number",
          'display="block"' in body and '<div class="eqno">(2)</div>' in body)
    check("no equation fell back to its source",
          "tex-fallback" not in body)


def test_headings_and_anchors():
    body, b = build("""## 3 | METHOD

Text.

### 3.2 | A subsection

More.
""")
    # The pipe is Wiley's rule between a heading's number and its title. Papers that do not
    # print one must not show it, and build_paper_page decides which is which by reading the
    # paper; with no paper in hand the test sees the default, which is to normalise it.
    check("a heading with no pipe-printing paper reads as a number and a title",
          "<h2 id=\"sec-3\">3. METHOD</h2>" in body, body[:200])
    check("a subsection anchor keeps the number's structure",
          'id="sec-3-2"' in body)
    check("headings are collected for the contents list",
          [t[1] for t in b.toc] == ["sec-3", "sec-3-2"])


def test_contents_list_nests_inside_its_item():
    # A sublist is part of the item it hangs off. Emitted as a sibling of the <li> it is
    # invalid HTML, which is what every paper with subsections had.
    from build_paper_page import build_page
    toc = [(2, "sec-1", "1 | One"), (3, "sec-1-1", "1.1 | Sub"), (2, "sec-2", "2 | Two"),
           (2, "sec-3", "3 | Three"), (2, "sec-4", "4 | Four")]
    page = build_page("test", {"title": "T", "authors": []}, "<p>body</p>", toc)
    nav = page[page.index('<nav class="toc"'):page.index("</nav>")]
    check("a sublist opens inside its parent item",
          "</a><ol>" in nav and "<li><ol>" not in nav, nav[:260])
    check("every list item is closed",
          nav.count("<li") == nav.count("</li>") and nav.count("<ol") == nav.count("</ol>"),
          "li %d/%d ol %d/%d" % (nav.count("<li"), nav.count("</li>"),
                                 nav.count("<ol"), nav.count("</ol>")))


def test_masthead_is_the_paper_not_the_last_heading():
    # The masthead names the paper. It was being overwritten by whatever heading the
    # contents list happened to end on -- "ENDNOTES", "REFERENCES", a supplement title.
    from build_paper_page import build_page
    toc = [(2, "sec-%d" % i, "%d | Section" % i) for i in range(1, 5)]
    toc.append((2, "sec-endnotes", "ENDNOTES"))
    page = build_page("test", {"title": "The Paper's Own Name", "authors": []},
                      "<p>body</p>", toc)
    masthead = page[page.index('class="site-name"'):page.index("</p>", page.index('class="site-name"'))]
    check("the masthead names the paper",
          "The Paper&#x27;s Own Name" in masthead or "The Paper's Own Name" in masthead,
          masthead)
    check("the masthead is not the last contents entry",
          "ENDNOTES" not in masthead, masthead)


def test_links_are_not_nested():
    # A transcript that writes a URL as its own link text matched both link rules, and the
    # second one rewrote the href the first had just written.
    out = inline("Available at [http://meta-analysis.cz/scc](http://meta-analysis.cz/scc).")
    check("a link is not wrapped in another link",
          out.count("<a ") == 1 and 'href="<a' not in out, out)
    check("a bare URL still becomes a link",
          '<a href="https://doi.org/10.1/x">' in inline("See https://doi.org/10.1/x for more."))


def test_nothing_is_injected():
    body, _ = build("""## 1 | INTRO

A <script>alert(1)</script> and an & ampersand.
""")
    check("markup in a transcript is escaped, not executed",
          "<script>" not in body and "&lt;script&gt;" in body and "&amp;" in body)


def main():
    for fn in sorted(
            (v for k, v in globals().items() if k.startswith("test_")),
            key=lambda f: f.__code__.co_firstlineno):
        print("%s:" % fn.__name__.replace("test_", "").replace("_", " "))
        fn()
    print()
    if FAILED:
        print("%d assertion(s) failed" % len(FAILED))
        return 1
    print("the dialect behaves as the fifty pages need it to")
    return 0


if __name__ == "__main__":
    sys.exit(main())
