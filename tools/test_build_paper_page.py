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
    check("a continued panel keeps its number",
          body.count("<table>") == 2 and "<b>Table 2.</b>" in body)
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
    check("a section heading keeps its printed pipe",
          "<h2 id=\"sec-3\">3 | METHOD</h2>" in body, body[:200])
    check("a subsection anchor keeps the number's structure",
          'id="sec-3-2"' in body)
    check("headings are collected for the contents list",
          [t[1] for t in b.toc] == ["sec-3", "sec-3-2"])


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
