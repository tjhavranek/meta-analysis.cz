#!/usr/bin/env python3
"""Compare each republished page against the paper's own LaTeX source, mechanically.

Why this exists
---------------
A PDF text layer is a lossy record of a paper. Maths comes out as prose, italics vanish,
footnotes land in the body. Reading 66 papers against 66 PDFs by hand is what the corpus
audits have been doing, and it is expensive and misses things: three separate hand passes
each found some cut sentences and none found all of them.

The LaTeX source says exactly what the author wrote: every displayed equation, every
emphasised term, every footnote, verbatim. Where a source exists, it turns "does this page
look right?" into a countable question.

The one thing this tool must never do
-------------------------------------
Treat the LaTeX as the truth. A source on disk is very often an EARLIER draft than the
published article the site transcribes: the matcher finds files marked REVISION_old, or
dated years before the article appeared. Wording, numbers and section order legitimately
differ, and where they differ the PUBLISHED PDF is right and the .tex is wrong.

So nothing here reports a textual difference. It reports STRUCTURAL DEFICITS -- the source
displays nine equations and the page renders four -- which are the cases where the page is
poorer than the paper whichever draft you compare against. Every hit still has to be
confirmed against the PDF before anything is changed. The tool ranks candidates; it does
not decide.

Manifest
--------
The sources live outside this repository, scattered across the owner's drive, so the
project-to-file map is a local artefact and is not committed. Point at one with:

    python tools/audit_tex_fidelity.py --manifest <path-to-json>

where the JSON is {"project": "C:/path/to/paper.tex", ...}. Build one with
tools/find_tex_sources.py.
"""

import argparse
import glob
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Displayed maths in LaTeX. starred and unstarred, plus the plain bracket forms.
DISPLAY_ENV = re.compile(
    r"\\begin\{(equation|align|eqnarray|gather|multline|displaymath|flalign)\*?\}")
BRACKET_DISPLAY = re.compile(r"(?<!\\)\\\[")
DOLLAR_DISPLAY = re.compile(r"(?<!\$)\$\$(?!\$)")

# A \footnote{...} with balanced braces is not a regular language; find the opening and
# walk the braces.
FOOTNOTE_OPEN = re.compile(r"\\footnote\s*\{")
EMPH_OPEN = re.compile(r"\\(?:emph|textit)\s*\{")

COMMENT = re.compile(r"(?m)(?<!\\)%.*$")


def strip_comments(s):
    return COMMENT.sub("", s)


def balanced(s, start):
    """Text inside the braces whose opening brace is at s[start-1]."""
    depth, i, n = 1, start, len(s)
    while i < n and depth:
        c = s[i]
        if c == "\\":
            i += 2
            continue
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
        i += 1
    return s[start:i - 1] if depth == 0 else ""


def detex(s):
    s = re.sub(r"\\(?:emph|textit|textbf|texttt|textsc)\s*\{", "{", s)
    s = re.sub(r"\\[a-zA-Z@]+\s*", " ", s)
    s = re.sub(r"[{}$&~^_%#\\]", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def tex_facts(path):
    try:
        s = strip_comments(io.open(path, encoding="utf-8", errors="replace").read())
    except OSError:
        return None
    # only the body: a preamble can define macros that look like maths
    m = re.search(r"\\begin\{document\}", s)
    body = s[m.end():] if m else s
    n_display = (len(DISPLAY_ENV.findall(body)) + len(BRACKET_DISPLAY.findall(body))
                 + len(DOLLAR_DISPLAY.findall(body)) // 2)
    notes = []
    for m in FOOTNOTE_OPEN.finditer(body):
        t = detex(balanced(body, m.end()))
        if len(t) > 25:
            notes.append(t)
    emph = []
    for m in EMPH_OPEN.finditer(body):
        t = detex(balanced(body, m.end()))
        if 2 < len(t) < 60:
            emph.append(t)
    return {"display": n_display, "footnotes": notes, "emph": emph,
            "words": len(detex(body).split())}


TAG = re.compile(r"<[^>]+>")


def page_facts(project):
    p = os.path.join(ROOT, project, "paper", "index.html")
    if not os.path.isfile(p):
        return None
    s = io.open(p, encoding="utf-8", errors="replace").read()
    n_display = len(re.findall(r'class="eqn"', s))
    n_inline = len(re.findall(r"<math[^>]*class=\"inl\"", s))
    n_notes = len(re.findall(r'<ol class="endnotes">', s))
    notes_block = ""
    m = re.search(r'(?s)<ol class="endnotes">(.*?)</ol>', s)
    if m:
        notes_block = m.group(1)
    body = re.sub(r"(?s)<(script|style).*?</\1>", " ", s)
    import html as H
    text = H.unescape(TAG.sub(" ", body))
    text = re.sub(r"\s+", " ", text)
    return {"display": n_display, "inline": n_inline, "note_lists": n_notes,
            "notes_text": re.sub(r"\s+", " ", H.unescape(TAG.sub(" ", notes_block))),
            "text": text}


def norm(t):
    return re.sub(r"[^a-z0-9 ]", " ", t.lower()).split()


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--project", help="check only this project")
    args = ap.parse_args(argv)

    man = json.load(io.open(args.manifest, encoding="utf-8"))
    rows = []
    for project in sorted(man):
        if args.project and project != args.project:
            continue
        tf = tex_facts(man[project])
        pf = page_facts(project)
        if not tf or not pf:
            continue
        # equations the page does not render
        eq_deficit = tf["display"] - pf["display"]
        # footnotes whose opening words appear nowhere on the page
        missing_notes = []
        hay = " ".join(norm(pf["text"]))
        for t in tf["footnotes"]:
            w = norm(t)
            if len(w) < 6:
                continue
            probe = " ".join(w[:6])
            if probe not in hay:
                missing_notes.append(t)
        rows.append({
            "project": project,
            "tex_display": tf["display"], "page_display": pf["display"],
            "eq_deficit": eq_deficit,
            "page_inline": pf["inline"],
            "tex_notes": len(tf["footnotes"]), "missing_notes": len(missing_notes),
            "missing_note_samples": [t[:110] for t in missing_notes[:3]],
            "tex": man[project],
        })

    rows.sort(key=lambda r: (-max(r["eq_deficit"], 0), -r["missing_notes"], r["project"]))
    print("%-16s %5s %5s %6s %6s %6s %6s" %
          ("project", "texEq", "pgEq", "defic", "pgInl", "texFn", "missFn"))
    print("-" * 60)
    flagged = 0
    for r in rows:
        mark = ""
        if r["eq_deficit"] > 0:
            mark += "  <== %d equation(s) not rendered" % r["eq_deficit"]
        if r["missing_notes"]:
            mark += "  <== %d footnote(s) absent" % r["missing_notes"]
        if mark:
            flagged += 1
        print("%-16s %5d %5d %6d %6d %6d %6d%s" %
              (r["project"], r["tex_display"], r["page_display"], r["eq_deficit"],
               r["page_inline"], r["tex_notes"], r["missing_notes"], mark))
    print("\n%d project(s) compared, %d flagged." % (len(rows), flagged))
    print("Every hit is a CANDIDATE: the .tex may be an older draft. Confirm against the "
          "published PDF before changing anything.")
    for r in rows:
        if r["missing_note_samples"]:
            print("\n%s -- footnote text not found on the page:" % r["project"])
            for t in r["missing_note_samples"]:
                print("   ... %s" % t)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
