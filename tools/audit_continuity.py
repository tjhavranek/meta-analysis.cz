#!/usr/bin/env python3
"""Find sentences the conversion cut in half.

    python3 tools/audit_continuity.py [<project> ...] [--all] [--verbose]

A typeset paragraph does not end mid-clause. When one does in a transcript, it is almost
always the page break showing through: the PDF put a footnote, a float or a column break
between two halves of one sentence, and the extraction promoted that gap to a paragraph
boundary. The reader then meets a paragraph that stops on "the" and a next one that starts
on "DST policy lowers".

The first version of this screen asked whether the paragraph ended lower-case and the next
began lower-case. That found six of them and missed fourteen, because the continuing half
frequently begins with something capitalised for reasons of its own -- a proper noun, an
acronym, a citation year, a number, the start of a new sentence that still belongs to the
same paragraph:

    ... Importantly, the   ->  DST policy lowers the peak ...
    ... over the period 2013-  ->  2016, which are available ...
    ... estimate Equation (1). A  ->  few cross-section studies ...

So the question is asked of the FIRST half only, and it is the question the typesetter
would ask: does this paragraph end where a paragraph can end? A paragraph may end on
terminal punctuation, on a closing quotation or bracket after it, on a footnote marker, on
an abbreviation that ends a sentence. It may not end on "the", on a comma, on an open
bracket, on a hyphen, on "&".

That rule fires on legitimate constructions too, and those are excluded by what they are
rather than by how they end: an author-affiliation block whose lines are addresses, a
KEYWORDS line, the stem of a list or a quotation, the line introducing a display equation,
a table note, a reference or endnote entry. What survives is checked against the source
PDF by hand -- this screen names candidates, it does not edit anything.

Exit status is 1 if any unreviewed candidate remains, so CI can hold the line once the
corpus is clean. tools/continuity_reviewed.json records the ones looked at and kept, each
with the reason, in the same spirit as tools/figures_reviewed.json.
"""

import hashlib
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANSCRIPTS = os.path.join(ROOT, "tools", "transcripts")
REVIEWED = os.path.join(ROOT, "tools", "continuity_reviewed.json")

# Blocks that are not running prose, recognised by their first characters.
RE_HEADING = re.compile(r"^#")
RE_TABLE_ROW = re.compile(r"^\|")
# An exhibit's note is not running prose. It routinely ends without a full stop -- "...but
# included in all statistical tests" -- because that is how the journal sets it, and it is
# followed by the next body paragraph, which is exactly the shape of a cut sentence. Once
# figure notes moved out of the caption line and onto their own line, where the fidelity
# checker can see them, eleven of these appeared at once. They are notes, not fragments.
RE_NOTE_LINE = re.compile(r"^[*_]{0,2}(Notes?|Source)[*_]{0,2}:\s")
# Captions are shouted in the dialect -- "TABLE 2." and "FIGURE 4." -- and the shouting is
# what tells them apart from a sentence that merely opens "Table 2 provides ...". Matching
# case-insensitively read one of /dst_slovakia/'s cut sentences as a caption and hid it.
# Exhibit numbers are not always digits: /remittances/ numbers its appendix funnel
# plot "E" after the appendix that holds it, and appendix figures run A.1, S13,
# I.4.1. A digits-only pattern read those caption lines as prose.
RE_CAPTION = re.compile(r"^(TABLE|FIGURE|ALT)\s+[A-Za-z]*[\d.]*[A-Za-z]?\d*\s*(\(continued\)|\(no artwork\))?\s*[.:]")
RE_LIST = re.compile(r"^\s*-\s")
RE_DISPLAY_MATH = re.compile(r"^\s*\$\$")
# A paragraph made of nothing but code spans is a displayed block, not running prose --
# /inflation/ shows its Scopus query on two such lines, and the sentence that introduces it
# ends on "The broad keyword query" for the same reason an equation's lead-in ends on a
# colon. Pairing across one would report four cuts that are not cuts.
RE_CODE_ONLY = re.compile(r"^(\s|\*)*(`[^`]*`(\s|\*)*)+$")
RE_ENTRY = re.compile(r"^([0-9]+|[ivxlc]+)\.\s")

# A paragraph may end on any of these.
#   .  !  ?  :  ;   -- terminal punctuation, colons and semicolons included because a
#                      transcript paragraph that ends on one is introducing a display block
#   "  '  )  ]  }   -- a closing mark after it
#   ^{4}            -- a footnote marker after it
#   *  _  `         -- emphasis closing after it
RE_TERMINAL = re.compile(
    r"""[.!?:;…]           # the punctuation itself
        (?: \^\{[^}]*\}         # a footnote/citation marker
          | ["'’”)\]} *_`]   # a closing mark or emphasis
        )*
        \s*$""", re.X)

# A block quotation ends on its source, and the source is a parenthesis that follows the
# quotation's own full stop and closing italics: "... in smaller classes.* (New York State
# Senate, 2022)". The full stop before the bracket is what separates this from a sentence
# that merely happens to break after a citation -- "... as Haskel et al. (2007)" has none,
# and is one of the real cuts.
RE_ATTRIBUTION = re.compile(
    r"""[.!?…] ["'’”*_]* \s*
        \( [^()]{0,80} \)
        (?: \^\{[^}]*\} | [*_"'’”] )*
        \s*$""", re.X)

# Back matter, appendix listings and endnote entries end on a bare address or a markdown
# link. A URL has no full stop to end on, and adding one would be wrong.
RE_URL_END = re.compile(r"(https?://\S+|\]\(https?://[^)]+\))\s*$")

# An abbreviation is not the end of a sentence, so a paragraph that stops on one has been
# cut. Only abbreviations that genuinely cannot close a paragraph belong here: "etc.",
# "pp." and "No." all end paragraphs legitimately -- "a positive coefficient of +1.4 pp."
# is a whole sentence -- and listing them cost three false positives and found nothing.
RE_ABBREV_END = re.compile(r"\b(e\.g|i\.e|cf|vs|Fig|Tab|Eq|Sec)\.\s*$", re.I)

# The same list with "al." added, used to decide whether the full stop in front of a
# closing parenthesis really ended a quoted sentence.
RE_QUOTE_ABBREV = re.compile(r"\b(al|e\.g|i\.e|cf|vs|Fig|Tab|Eq|Sec)\.\s*$", re.I)


def blocks(path):
    """The transcript's blocks, as (kind, text, line number).

    kind is "prose" only for running text. Everything else is named so the caller can
    decide what a boundary between two of them means."""
    out = []
    section = None
    lines = open(path, encoding="utf-8").read().split("\n")
    i, prev_blank = 0, True
    while i < len(lines):
        raw = lines[i]
        s = raw.strip()
        if not s:
            prev_blank = True
            i += 1
            continue
        if RE_HEADING.match(s):
            head = s.lstrip("#").strip().upper()
            section = head.split("|")[0].strip().split(":")[0].strip()
            out.append(("heading", s, i + 1))
        elif RE_TABLE_ROW.match(s):
            out.append(("table", s, i + 1))
        elif RE_NOTE_LINE.match(s):
            out.append(("note", s, i + 1))
        elif RE_CAPTION.match(s):
            out.append(("caption", s, i + 1))
        elif RE_LIST.match(raw):
            out.append(("list", s, i + 1))
        elif RE_DISPLAY_MATH.match(s):
            out.append(("math", s, i + 1))
        elif RE_CODE_ONLY.match(s):
            out.append(("code", s, i + 1))
        elif section in ("REFERENCES", "ENDNOTES") and RE_ENTRY.match(s):
            out.append(("entry", s, i + 1))
        elif not prev_blank and out and out[-1][0] == "table":
            # The line straight after a pipe table is that table's note.
            out.append(("note", s, i + 1))
        elif section in ("FRONTMATTER", "KEYWORDS", "REFERENCES"):
            # A reference list runs to the next heading whatever its entries look like:
            # the unnumbered lists have no "1. " to match, and every entry ends on a page
            # range or a URL, so reading them as prose would flag the whole bibliography.
            out.append(("meta", s, i + 1))
        elif section == "ENDNOTES":
            # A "## ENDNOTES" block reaches only as far as its numbered entries. The
            # builder gathers those and emits them at the end of the page, so the running
            # text that follows is running text again -- and it is precisely there that
            # the cut sentences hide, because the footnote was planted between the two
            # halves. Reading the heading as owning everything until the next heading was
            # what made an earlier version of this screen miss /electricity/ and /elb/,
            # the two the outside audit had to find by hand.
            section = None
            out.append(("prose", s, i + 1))
        else:
            out.append(("prose", s, i + 1))
        prev_blank = False
        i += 1
    return out


def ends_openly(text):
    """Does this paragraph stop somewhere a paragraph cannot stop?"""
    t = text.rstrip()
    if not t:
        return False
    if RE_ABBREV_END.search(t):
        return True
    if RE_URL_END.search(t):
        return False
    m = RE_ATTRIBUTION.search(t)
    if m and not RE_QUOTE_ABBREV.search(t[:m.start() + 1]):
        # "... in smaller classes.* (New York State Senate, 2022)" is a quotation and its
        # source. "... as Haskel et al. (2007)" is not: the full stop belongs to "al.", and
        # the sentence runs on into the next paragraph. Reading the second as an
        # attribution hid one of /spillovers_bias/'s four cut sentences.
        return False
    # A paragraph cannot end inside a bracket it never closed. This is what the semicolon
    # in "... evening activities (Wolff & Makino, 2012;" is doing: the punctuation looks
    # terminal, and it is separating two citations in a list that has not finished.
    # Mathematics brings its own brackets and does not balance them: a half-open interval
    # is written "[0, 1)" on purpose. Count only the prose brackets.
    prose = re.sub(r"\$[^$]*\$", "", t)
    if prose.count("(") > prose.count(")") or prose.count("[") > prose.count("]"):
        return True
    return not RE_TERMINAL.search(t)


def candidates(project):
    """Pairs of prose blocks where the first has no plausible ending.

    An ENDNOTES block between the two halves does not break the pair: that is the commonest
    shape of the fault, because the footnote sat in the page footer between them."""
    path = os.path.join(TRANSCRIPTS, project + ".md")
    bs = blocks(path)
    out = []
    for a in range(len(bs)):
        kind, text, line = bs[a]
        if kind != "prose" or not ends_openly(text):
            continue
        # Walk forward over an endnote block -- and only an endnote block -- to the next
        # piece of running text. Anything else in between means the paragraph really did
        # end there, whatever its last character was.
        b = a + 1
        while b < len(bs) and (bs[b][0] == "entry"
                               or (bs[b][0] == "heading"
                                   and bs[b][1].lstrip("#").strip().upper().startswith("ENDNOTE"))):
            b += 1
        if b < len(bs) and bs[b][0] == "prose":
            out.append((line, text, bs[b][2], bs[b][1], b > a + 1))
    return out


def key(project, text, ntext):
    """A name for one candidate that survives edits elsewhere in the transcript.

    Keying the reviewed list by line number would go stale every time a paragraph above it
    was joined -- which is exactly what this screen causes people to do -- and a stale key
    reads as a fresh unreviewed candidate. So the key is the boundary itself: the tail of
    the paragraph that ends and the head of the one that follows, stripped to letters and
    digits. Change either half and the entry needs looking at again, which is right."""
    raw = re.sub(r"[^0-9a-z]+", "", (text[-60:] + ntext[:60]).lower())
    return "%s:%s" % (project, hashlib.sha1(raw.encode()).hexdigest()[:10])


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    verbose = "--verbose" in sys.argv
    # <project>.draft.md is the raw output of tools/draft_transcript.py, kept beside the
    # finished transcript as working material. No page is built from one, so its unedited
    # PDF text layer is not a defect in anything the site serves.
    projects = args or sorted(f[:-3] for f in os.listdir(TRANSCRIPTS)
                              if f.endswith(".md") and not f.endswith(".draft.md"))
    reviewed = {}
    if os.path.exists(REVIEWED):
        reviewed = {k: v for k, v in json.load(open(REVIEWED, encoding="utf-8")).items()
                    if not k.startswith("_")}

    open_count, kept, seen = 0, 0, set()
    for p in projects:
        for line, text, nline, ntext, via_notes in candidates(p):
            k = key(p, text, ntext)
            seen.add(k)
            if k in reviewed:
                kept += 1
                if verbose:
                    print("  kept   %-24s %s" % (k, reviewed[k]))
                continue
            open_count += 1
            print("%-24s %s  line %d%s"
                  % (k, p, line, "  (across ENDNOTES)" if via_notes else ""))
            print("   ends: ...%s" % text[-70:])
            print("   next: %s..." % ntext[:70])

    # An entry whose boundary no longer exists is not harmless: it means the paragraph was
    # edited after being reviewed, and nobody has looked at what it says now. Say so.
    if not args:
        for k in sorted(set(reviewed) - seen):
            print("STALE %-22s no longer a candidate -- %s" % (k, reviewed[k][:90]))

    print("\n%d unreviewed, %d reviewed and kept, over %d transcripts"
          % (open_count, kept, len(projects)))
    return 1 if open_count else 0


if __name__ == "__main__":
    sys.exit(main())
