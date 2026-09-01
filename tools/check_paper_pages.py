#!/usr/bin/env python3
"""Check every full-text page against the paper it reproduces.

    python3 tools/check_paper_pages.py [<project> ...]

Three things can go wrong in a conversion, and each is checkable without an opinion:

  * something was invented -- prose on the page that is not in the PDF;
  * something is missing -- a table or a figure the paper prints and the page does not,
    which the census of table and figure NUMBERS decides exactly; and, for prose, how much
    of the paper's distinctive vocabulary the transcript accounts for, which is a
    proportion and not a proof. It will catch a dropped section. It will not catch a
    dropped sentence, and nothing here claims it does;
  * something is broken -- a leftover placeholder, a citation pointing at a reference that
    is not there, a figure whose file was never written, an equation that failed to convert.

Exit status is 1 if any page fails, so this can gate a deploy.
"""

import html
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

from build_paper_page import (documents, page_dir, transcript_pdf_path,  # noqa: E402
                              transcript_pdf_paths)
from scout_paper import scout                               # noqa: E402
from verify_transcript import (multiset_check, multiset_check_strict,  # noqa: E402
                               pdf_counts,
                               pdf_prose, transcript_prose, words)

PAPERS = {p["project"]: p for p in json.load(open(os.path.join(ROOT, "tools", "papers.json")))}
PAPERS.update(documents())


def visible_text(page):
    body = page
    body = re.sub(r"<script.*?</script>", " ", body, flags=re.S)
    body = re.sub(r"<style.*?</style>", " ", body, flags=re.S)
    body = re.sub(r"<[^>]+>", " ", body)
    return html.unescape(body)


def check(project):
    fails, notes = [], []
    page_path = os.path.join(page_dir(project, PAPERS[project]), "index.html")
    tr_path = os.path.join(ROOT, "tools", "transcripts", "%s.md" % project)
    if not os.path.exists(page_path):
        return ["no page at %s" % page_dir(project, PAPERS[project])], []
    page = open(page_path, encoding="utf-8").read()
    # /maive/paper/ and /guidelines/guide/ were built by hand before the toolchain existed and
    # have no transcript, so the fidelity and census checks below cannot run on them. That
    # used to mean NO check ran on them, which is how /maive/paper/ came to point at a figure
    # file that had been deleted and stayed that way: a broken image on the site's flagship
    # page, invisible to this gate because the gate returned before it looked. Everything that
    # only needs the PAGE -- missing figures, dead citation links, placeholders, the
    # attribution block, the JSON-LD -- runs on every page now.
    have_transcript = os.path.exists(tr_path)
    if not have_transcript:
        notes.append("hand-built page, no transcript: fidelity and census checks skipped")
    src = open(tr_path, encoding="utf-8").read() if have_transcript else None
    pdf = transcript_pdf_path(project, PAPERS[project])
    pdfs = transcript_pdf_paths(project, PAPERS[project])

    # -- nothing invented
    if have_transcript:
      a = pdf_counts(pdfs[0])
      for _extra in pdfs[1:]:
          more = pdf_counts(_extra)
          merged = a | more               # a word in either hosted PDF is not invented
          # Counter.__or__ returns a plain Counter, dropping the `joined` set pdf_counts
          # attaches -- so on the two papers that draw on more than one PDF, contagion and
          # dst_slovakia, the run-together discount silently stopped applying and the gate
          # was stricter there than anywhere else. Carry it across the union.
          merged.joined = getattr(a, "joined", set()) | getattr(more, "joined", set())
          a = merged
      b = words(transcript_prose(src))
      _lost, gained = multiset_check(a, b)
      invented = sum(c for w, c in gained.items() if re.search(r"[a-z]{3}", w))
      if invented > 6:
          fails.append("%d prose words on the page are not in the PDF (%s)"
                       % (invented, ", ".join(sorted(w for w in gained if re.search(r"[a-z]{3}", w))[:8])))
      elif invented:
          notes.append("%d word(s) not in the text layer: %s"
                       % (invented, ", ".join(sorted(w for w in gained if re.search(r"[a-z]{3}", w)))))

      # The shipped rule forgives by membership and never consumes a count, so one glued
      # token absolves every surplus copy of a word; it also treats a two-letter surplus as
      # glue, which is where meaning inversions hide (significant riding in on
      # insignificant). multiset_check_strict repairs both. It does NOT gate yet: it prints
      # the difference so the delta can be sized under CI's poppler before anything is
      # tightened, because a stricter rule that reds CI is not shippable. Flip the gate once
      # this line stops appearing.
      _l2, g2 = multiset_check_strict(a, b)
      strict = sum(c for w, c in g2.items() if re.search(r"[a-z]{3}", w))
      if strict > invented:
          _new = sorted(set(w for w in g2 if re.search(r"[a-z]{3}", w))
                        - set(w for w in gained if re.search(r"[a-z]{3}", w)))
          notes.append("strict fidelity (report-only, not gating): %d vs %d; newly flagged: %s"
                       % (strict, invented, ", ".join(_new[:10]) or "(count only)"))

      # -- how much of the paper's distinctive vocabulary the transcript accounts for.
      #    Total words are a poor measure: half the words in a paper are "the" and "of", and
      #    tables supply thousands of short tokens the prose comparison never sees. Long words
      #    are where a paper's content lives, and across the fifty-three converted papers the
      #    share of them the transcript is missing runs from 3% to 29%. A page that dropped a
      #    section would sit far outside that; a threshold at 45% flags it without crying wolf
      #    at the papers whose tables are simply large.
      long_pdf = sum(c for w, c in a.items() if len(w) >= 8)
      long_missing = sum(c for w, c in _lost.items() if len(w) >= 8)
      share = long_missing / max(1, long_pdf)
      if share > 0.45:
          fails.append("%.0f%% of the paper's long words are absent from the transcript -- "
                       "a section may be missing" % (100 * share))
      elif share > 0.33:
          notes.append("%.0f%% of the paper's long words are absent (tables and figures "
                       "account for most of it)" % (100 * share))

      # -- the tables and figures the paper has, the page has
      sc = scout(project, PAPERS)
      want_t = set(sc.get("tables", {}))
      want_f = set(sc.get("figures", {}))
      # A paper can number one figure twice. reproducibility's manuscript floats its extended
      # data as "Fig. 5" through "Fig. 14" while its own body text calls the same pictures
      # "Extended Data Figure 1" through "10", and a reader following a cross-reference needs
      # the label the text uses, not the one the float carries. The page therefore serves them
      # as ED1..ED10, and papers.json says which float number that is, so this census still
      # compares the paper's figures against the page's rather than being switched off.
      alias = (PAPERS[project].get("figure_labels") or {})
      want_f = {alias.get(n, n) for n in want_f}
      # A table too tall for one printed page is two panels sharing a number; the second is
      # marked continued and is not a duplicate.
      got_t = re.findall(r"<caption><b>Table ([A-Za-z0-9.]+)\.</b>", page)
      got_f = re.findall(r"<b>Figure ([A-Za-z0-9.]+)\.</b>", page)
      # Which numbers, not how many: a page carrying Table 2 twice and no Table 3 has the
      # right count and the wrong contents, and the count alone cannot tell them apart.
      for label, want, got in (("table", want_t, got_t), ("figure", want_f, got_f)):
          # A figure printed once with lettered panels -- "Figure 4. ... (A) ... (B) ..." --
          # reads out of the text layer as both "4" and "4A". The page carrying 4 has it.
          seen = set(got) | {n[:-1] for n in got if n[-1:].isalpha()}
          want = {n for n in want
                  if not (n[-1:].isalpha() and n[:-1] in seen)}
          missing = want - seen
          if missing:
              fails.append("the paper prints %s %s; the page does not"
                           % (label, ", ".join(sorted(missing))))
          dupes = {n for n in got if got.count(n) > 1}
          if dupes:
              fails.append("%s %s appears more than once on the page"
                           % (label.capitalize(), ", ".join(sorted(dupes))))

      # -- every table on the page is one the paper prints
      #    A table with no caption is a fragment, not a table. Blank lines between a table's
      #    rows used to end it, so one of beauty's tables became fifty-one tables of a single
      #    row and the page carried 397 where the paper prints 29. The counts are equal on
      #    every paper once the rows are read as one table, which makes the equality a fact
      #    about the conversion rather than a coincidence, and worth failing on.
      #    Not every table carries a numbered caption: size prints a 103-row list of studies
      #    under an appendix HEADING, which is a real table and not a fragment. What a fragment
      #    is, is short -- the bug produced tables of a single row -- so that is what is tested.
      fragments = [t for t in re.findall(r"<table.*?</table>", page, re.S)
                   if "<caption" not in t and t.count("<tr") < 3]
      if fragments:
          fails.append("%d table(s) have no caption and fewer than three rows -- a table's rows "
                       "have been split into separate tables" % len(fragments))

    # -- nothing broken
    if "<<" in page:
        fails.append("a placeholder marker survived into the page")
    if "tex-fallback" in page:
        fails.append("%d equation(s) failed to convert to MathML" % page.count("tex-fallback"))
    if re.search(r"\bTODO\b", visible_text(page)):
        fails.append("the word TODO is visible on the page")
    for m in re.finditer(r'<img src="(figures/[^"]+)"', page):
        f = os.path.join(page_dir(project, PAPERS[project]), m.group(1))
        if not os.path.exists(f):
            fails.append("missing figure file %s" % m.group(1))
        elif os.path.getsize(f) < 2000:
            notes.append("%s is only %d bytes -- check it is the artwork"
                         % (m.group(1), os.path.getsize(f)))
    targets = set(re.findall(r'id="(ref-[^"]+|note-[^"]+)"', page))
    broken = {h for h in re.findall(r'href="#(ref-[^"]+|note-[^"]+)"', page)} - targets
    if broken:
        fails.append("%d citation link(s) point at nothing: %s"
                     % (len(broken), ", ".join(sorted(broken)[:6])))
    # A DOI link that cannot resolve is broken in the same way a dead citation link is, and
    # it fails silently: the identifier reads correctly on screen while the anchor points at
    # a "DOI Not Found" page. A sweep of all 2,435 DOIs this site links found 19 dead, and
    # every one was malformed in a way visible without asking the network -- which is what
    # makes it checkable in a gate. Live resolution is not checked here; 2,435 network calls
    # do not belong in a build.
    for href in {html.unescape(h) for h in re.findall(r'href="https://doi\.org/([^"]+)"', page)}:
        why = None
        if href.count("(") != href.count(")"):
            why = "unbalanced brackets -- the link stops at the DOI's own bracket"
        elif re.match(r"10\.\d{4,9}/10\.\d{4,9}/", href):
            why = "a doubled prefix"
        elif "%5C" in href.upper() or "\\" in href:
            why = "an unresolved escape sequence"
        if why:
            fails.append("DOI link https://doi.org/%s has %s" % (href, why))
    if 'class="attribution"' not in page:
        fails.append("no attribution block")
    for blob in re.findall(r'<script type="application/ld\+json">(.*?)</script>', page, re.S):
        try:
            json.loads(blob)
        except Exception as exc:
            fails.append("JSON-LD does not parse: %s" % exc)
    if "permission" in visible_text(page).lower():
        notes.append("the word 'permission' appears in visible text")

    return fails, notes


def main(argv):
    if argv:
        projects = argv
    else:
        projects = sorted(p for p in PAPERS
                          if os.path.exists(os.path.join(page_dir(p, PAPERS[p]), "index.html")))
    bad = 0
    for project in projects:
        fails, notes = check(project)
        mark = "FAIL" if fails else "ok  "
        print("%s %-22s %s" % (mark, project,
                               "" if fails or notes else "clean"))
        for f in fails:
            print("       ! %s" % f)
        for n in notes:
            print("       - %s" % n)
        bad += bool(fails)
    print("\n%d page(s) checked, %d with failures" % (len(projects), bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
