#!/usr/bin/env python3
"""Extract a figure by asking the PDF where it draws, not by guessing around the caption.

    python3 tools/figure_from_drawings.py <project> [<fig> ...] [--apply] [--dpi 200]

Why a third extractor. tools/locate_figures.py anchors on the caption and walks UP, which
assumes the caption sits under the artwork. tools/scan_figures.py segments the rendered page
into blocks of ink and asks tools/audit_figures.py whether each is a plot, which assumes a
plot has long strokes. Between them they leave 128 captioned figures on this site with no
artwork under them, and /electricity/'s Figure 1 shows why: its caption is ABOVE the plot,
and the plot is several thousand scatter dots with not one long stroke in it. Both tools
look straight past it.

A PDF, though, already says exactly where it drew. page.get_drawings() returns a rectangle
per drawing operation, so the artwork is simply where those rectangles are dense, whatever
shape the ink takes and wherever the caption sits. This finds the band of the page the
drawing occupies, grows it to take in the axis labels and legend that belong to it, stops
before the caption and the notes, and renders that.

Without --apply it reports what it would do and writes nothing.
"""

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import fitz                                                    # noqa: E402

from build_paper_page import (documents, page_dir,             # noqa: E402
                              transcript_pdf_paths)

PAPERS = {p["project"]: p for p in
          json.load(open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
PAPERS.update(documents())

GAP = 26.0        # points of blank between two drawing bands before they are separate
PAD = 4.0         # breathing room around the final crop
MIN_H = 40.0      # a band shorter than this is a rule, not a figure
MIN_FRAC = 0.06   # ...and one covering less than this share of the page height likewise


def caption_rects(page):
    """Where each figure caption sits, as {number: rect}.

    The dict extraction is the expensive call in this file, and most pages of most papers
    have no caption on them at all. One paper here is several hundred pages of impulse
    responses; walking all of them properly took the whole sweep past forty minutes. A plain
    text fetch is far cheaper and settles it for the great majority of pages.
    """
    flat = page.get_text()
    if not flat or not re.search(r"(?:F\s*I\s*G\s*U\s*R\s*E|Figure|Fig\.)\s*[A-Z]?\s*\.?\s*\d",
                                 flat, re.I):
        return {}
    out = {}
    for b in page.get_text("dict")["blocks"]:
        for line in b.get("lines", []):
            txt = "".join(s["text"] for s in line.get("spans", []))
            # Wiley letter-spaces its caption label -- "F I G U R E 3" -- and numbers its
            # appendix figures "A . 1". Eight of this site's figures sat unextracted behind
            # that alone, on a paper whose PDF holds nine thousand drawing operations.
            norm = re.sub(r"\bF\s*I\s*G\s*U\s*R\s*E\b", "FIGURE", txt, flags=re.I)
            m = re.match(r"\s*(?:FIGURE|Fig\.)\s*((?:[A-Z]\s*\.?\s*)?\d{1,2}(?:\s*\.\s*\d{1,2})?"
                         r"[A-Za-z]?)\s*[.:]?\s*(\S.*)?", norm, re.I)
            if not m:
                continue
            title = (m.group(2) or "").strip()
            # Wiley also sets the label on a line of its own and the title on the next, so
            # a bare "F I G U R E 1" is a caption too. A cross-reference in running prose
            # never stands alone on a short line, which is what separates the two; and a
            # false match still has to find a drawing band beside it to become a job.
            if not title and len(norm.strip()) > 22:
                continue
            label = re.sub(r"[\s.]", "", m.group(1))
            # Take the whole caption BLOCK, not just the line the label is on. A caption
            # that wraps leaves its tail outside the barrier, and /electricity/'s Figure 2
            # came out with the words "experimental benchmark" stranded above the plot.
            rect = fitz.Rect(line["bbox"])
            for other in b.get("lines", []):
                orect = fitz.Rect(other["bbox"])
                if orect.y0 >= rect.y0 - 1:
                    rect |= orect
            out.setdefault(label, rect)
    return out


def column_width(page):
    """The width of a line of body text on this page, not the width of the page.

    Every prose test here compared a line against the PAGE width, which is right for a
    single-column paper and wrong for the two-column ones. On students and substitution a
    full column line is 0.42 of the page, under every threshold, so a whole column of body
    text counted as neither prose nor a barrier and was cropped into the figure.
    """
    widths = []
    for b in page.get_text("dict")["blocks"]:
        for line in b.get("lines", []):
            t = "".join(s["text"] for s in line["spans"]).strip()
            if len(t) > 40:
                widths.append(fitz.Rect(line["bbox"]).width)
    if not widths:
        return page.rect.width
    widths.sort()
    return widths[int(0.9 * (len(widths) - 1))]


def dominant_column(rects, gutter=25.0, ratio=5.0):
    """Keep the x-cluster that holds nearly all the drawing, if there is one.

    Returns the rects unchanged unless a single cluster holds `ratio` times more marks than
    everything else together, which is the case that matters: one stray rule in the next
    column against a whole chart.
    """
    if len(rects) < 6:
        return rects
    order = sorted(rects, key=lambda r: r.x0)
    groups, cur, edge = [], [order[0]], order[0].x1
    for r in order[1:]:
        if r.x0 - edge > gutter:
            groups.append(cur)
            cur, edge = [r], r.x1
        else:
            cur.append(r)
            edge = max(edge, r.x1)
    groups.append(cur)
    if len(groups) < 2:
        return rects
    groups.sort(key=len, reverse=True)
    rest = sum(len(g) for g in groups[1:])
    return groups[0] if rest and len(groups[0]) >= ratio * rest else rects


def has_curve(drawings):
    """True if anything here is drawn as a many-segment path, i.e. a plotted line.

    A table is straight rules and nothing else. A chart of a flat series is ALSO mostly
    straight lines with few marks, which made substitution's convergence panels read as
    tables and cost them their captions. What separates them is that the chart contains a
    path with many segments in it; a rule has one or two.
    """
    for d in drawings or ():
        if d is None:
            # a raster's rectangle has no drawing record; an embedded image is artwork
            return True
        if len(d.get("items") or ()) > 12:
            return True
        for it in (d.get("items") or ()):
            if it and it[0] == "c":          # a bezier: no table draws one
                return True
    return False


def table_like(rects, rect):
    """Whether a band of drawing is a table's rules rather than artwork.

    A table is drawn as a few long horizontal lines and nothing else. A chart has axes too,
    but it also has the marks that carry the data: bars, points, curves. Counting what is
    NOT a rule separates them. This matters because a caption takes the nearest band, and on
    lags page 26 the caption sits between Table 9 and Figure 6 with the table 32 points away
    and the plot 38, so /lags/ published its Table 9 as "Figure 6".
    """
    if not rects:
        return False
    def is_rule(r):
        # A rule is a line: thin in one direction, whatever its length. Requiring it to
        # span a quarter of the band missed lags' column rules, which are one cell tall
        # (15 points) inside a 120-point table, so the table went on reading as a plot.
        return r.height <= 2.5 or r.width <= 2.5

    rules = sum(1 for r in rects if is_rule(r))
    marks = len(rects) - rules
    # A chart has axes too, but its data marks far outnumber its rules; a table is nearly
    # all rules, with at most a box per row.
    return rules >= 3 and marks <= rules


def drawing_bands(page, bar_rows=None):
    """Contiguous vertical bands where the page draws, widest x-extent of each."""
    # Anything living entirely in the page's top or bottom margin is furniture: a rule under
    # a running head, a folio, or -- on the Wiley papers -- the journal's masthead logo,
    # which is a raster and so counted as artwork and dragged the whole masthead into
    # /hedge/'s PRISMA diagram.
    head_y = page.rect.y0 + page.rect.height * 0.075
    foot_y = page.rect.y1 - page.rect.height * 0.055

    def furniture(r):
        return r.y1 <= head_y or r.y0 >= foot_y

    parea = (page.rect.width * page.rect.height) or 1.0
    owner = {}
    rects = []
    for d in page.get_drawings():
        r = d["rect"]
        # NOT r.is_empty: a vertical line has zero width and PyMuPDF calls that empty, so
        # this was throwing away every vertical rule on every page -- a table's column
        # separators and a chart's y-axis alike. Only a point or an infinite box is useless.
        if r.is_infinite or (r.width <= 0 and r.height <= 0) or furniture(r):
            continue
        # A single filled rectangle covering a quarter of the page is a background panel,
        # not artwork. /class/'s Figure 5 sits on one covering 41% of the page, and taking
        # it for the drawing made the band swallow the figure's notes and the paragraph
        # after them. Real artwork of that size is built from many marks, not one fill.
        if d.get("type") == "f" and (r.width * r.height) / parea > 0.25:
            continue
        rects.append(r)
        owner[id(r)] = d
    for img in page.get_images(full=True):
        try:
            for r in page.get_image_rects(img[0]):
                if not furniture(r):
                    rects.append(r)
        except Exception:
            pass
    if not rects:
        return []
    rects.sort(key=lambda r: r.y0)
    # Carry the running bottom edge rather than recomputing max() over the open band on
    # every rectangle: a scatter plot is several thousand drawing operations on one page,
    # and the quadratic form took minutes per paper.
    bands, cur, bottom = [], [rects[0]], rects[0].y1
    for r in rects[1:]:
        if r.y0 - bottom > GAP:
            bands.append(cur)
            cur, bottom = [r], r.y1
        else:
            cur.append(r)
            bottom = max(bottom, r.y1)
    bands.append(cur)
    boxes = []
    for b in bands:
        # Narrow the band to the dominant column of ink. A band is grouped by rows only, so
        # on a two-column page a single stray drawing in the other column -- the rule of a
        # displayed equation, in students' case -- stretches it across the page and the
        # crop then takes the neighbouring text with it. Where one x-cluster holds nearly
        # all the marks, that cluster is the artwork.
        b = dominant_column(b)
        rect = fitz.Rect(min(r.x0 for r in b), min(r.y0 for r in b),
                         max(r.x1 for r in b), max(r.y1 for r in b))
        boxes.append([rect, len(b), list(b)])

    # A flow diagram is boxes joined by arrows, and the blank between two of its rows can
    # be wider than the gap that separates two different objects. /inflation/'s PRISMA
    # chart split into three and published clipped at the first arrow. What actually ends
    # a figure is running prose, not white space, so merge neighbours unless a full-measure
    # line of text sits between them.
    # Barriers: a caption belonging to ANY figure, and any line of running prose. The
    # caption barrier is the load-bearing one. Without it /students/'s Figure 2 merged
    # straight through its own caption and notes and swallowed Figure 3 as well, which is
    # a worse failure than the clipping this merge exists to fix.
    colw = column_width(page)
    prose_rows = list(bar_rows or [])
    for b in page.get_text("dict")["blocks"]:
        for line in b.get("lines", []):
            t = "".join(s["text"] for s in line["spans"]).strip()
            lr = fitz.Rect(line["bbox"])
            if len(t) > 60 and lr.width > 0.80 * colw:
                prose_rows.append((lr.y0, lr.y1))
            elif re.match(r"^(?:FIGURE|Figure|Fig\.|F\s*I\s*G\s*U\s*R\s*E|TABLE|Table)\b", t):
                prose_rows.append((lr.y0, lr.y1))

    merged = []
    for rect, n, tbl in boxes:
        if merged:
            prev, pn, ptbl = merged[-1]
            blocked = any(prev.y1 - 2 < y1 and y0 < rect.y0 + 2 for y0, y1 in prose_rows)
            overlap = min(prev.x1, rect.x1) - max(prev.x0, rect.x0)
            if (not blocked and rect.y0 - prev.y1 < 90
                    and overlap > 0.3 * min(prev.width, rect.width)):
                merged[-1] = [fitz.Rect(prev) | rect, pn + n, ptbl + tbl]
                continue
        merged.append([rect, n, tbl])
    out = []
    for rect, n, tbl in merged:
        if rect.height >= MIN_H and rect.height / page.rect.height >= MIN_FRAC:
            # Judge table-or-artwork on the WHOLE merged band. Deciding per fragment and
            # combining with "and" meant one small non-table piece cleared the flag, which
            # is how lags' Table 9 kept winning its caption.
            drawings = [owner.get(id(r)) for r in tbl]
            out.append((rect, n,
                        table_like(tbl, rect) and not has_curve(drawings)))
    return out


def grow_to_labels(page, rect, caption):
    """Take in the tick labels, axis titles and legend that sit with the artwork.

    They are text, so the band of drawing alone clips them. Any text line that overlaps the
    artwork horizontally and sits within a short reach of it belongs to it -- except the
    caption itself and anything at or beyond the caption, which is where the figure ends.
    """
    grown = fitz.Rect(rect)
    colw = column_width(page)
    # Blocks of running prose, so the side-growth below can refuse them. On a two-column
    # page the neighbouring column sits within reach of the artwork and satisfies every
    # test for an axis label, which is how students' figures came out with a whole column
    # of body text printed beside the chart.
    prose_blocks = []
    for _b in page.get_text("dict")["blocks"]:
        _lines = _b.get("lines", [])
        if any(len("".join(sp["text"] for sp in ln["spans"]).strip()) > 60
               and fitz.Rect(ln["bbox"]).width > 0.80 * colw for ln in _lines):
            prose_blocks.append(fitz.Rect(_b["bbox"]))
    # Where the notes under (or over) the artwork begin. Only the FIRST line of that block
    # says "Notes:"; its continuation lines are ordinary short prose and were being taken
    # for axis labels, so the crop kept two lines of the note and sliced the third. Treat
    # the whole block as out of bounds by refusing to grow past where it starts.
    stop_below, stop_above = page.rect.y1, page.rect.y0
    for b in page.get_text("dict")["blocks"]:
        for line in b.get("lines", []):
            t = "".join(s["text"] for s in line["spans"]).strip()
            if not re.match(r"^(Notes?|Sources?)\s*[:.]", t):
                continue
            lr = fitz.Rect(line["bbox"])
            if lr.y0 >= rect.y1:
                stop_below = min(stop_below, lr.y0)
            elif lr.y1 <= rect.y0:
                stop_above = max(stop_above, lr.y1)

    for b in page.get_text("dict")["blocks"]:
        for line in b.get("lines", []):
            lr = fitz.Rect(line["bbox"])
            if caption and lr.intersects(caption):
                continue
            # never cross the caption line
            if caption:
                if caption.y0 >= rect.y1 and lr.y0 >= caption.y0:
                    continue
                if caption.y1 <= rect.y0 and lr.y1 <= caption.y1:
                    continue
            # A running head and a page number sit in the page's own margins and belong to
            # no figure. Four of /price_puzzle/'s plots came out with the authors' names
            # across the top because the artwork starts within a few points of the header.
            if lr.y1 < page.rect.height * 0.075 or lr.y0 > page.rect.height * 0.945:
                continue
            if lr.y0 >= stop_below or lr.y1 <= stop_above:
                continue
            # The y-axis labels form a narrow column beside the plot, so they share almost
            # none of its width and the overlap test alone throws them away -- which is how
            # /guai/ and /risk/ lost their axis and became unreadable. Take a line that sits
            # immediately to either side and spans the artwork vertically.
            beside = (abs(rect.x0 - lr.x1) < 34 or abs(lr.x0 - rect.x1) < 34) and \
                     lr.y1 > rect.y0 - 6 and lr.y0 < rect.y1 + 6
            if beside and any(pb.intersects(lr) for pb in prose_blocks):
                beside = False        # that is the next column, not this figure's scale
            overlap = min(lr.x1, rect.x1) - max(lr.x0, rect.x0)
            if overlap <= 0.35 * min(lr.width, rect.width) and not beside:
                continue
            # Reach is measured from the DRAWING, always. Measuring it from the box as it
            # grew made every absorbed label extend the reach to the next line, and the
            # crop walked down the page one line at a time through the notes and into the
            # body text.
            near = (0 <= lr.y0 - rect.y1 < 22) or (0 <= rect.y0 - lr.y1 < 22) \
                or rect.intersects(lr)
            # `near` asks whether the line sits just above or below the artwork. A y-axis
            # label sits BESIDE it and satisfies neither, so it was being dropped after
            # passing the width test -- the reason /guai/ kept its plot and lost its scale.
            if not (near or beside):
                continue
            text = "".join(s["text"] for s in line["spans"]).strip()
            # Test against the DRAWING band, not the box as it grows. Testing the growing
            # box let each absorbed label pull the edge outward until the notes paragraph
            # and then the body text below it counted as "inside", and three of /alphas/'s
            # figures came out as page crops with two paragraphs of prose in them.
            inside = rect.intersects(lr)
            # Text sitting ON the artwork is part of it: a legend, a panel letter, a
            # value printed against a bar. Text OUTSIDE it is only a label if it is
            # short -- an axis title, a tick row. The notes under a figure are prose,
            # and baking them into the picture buries them in a PNG where no reader can
            # select them and no text pipeline can read them, while the page already
            # prints the same words as a caption underneath.
            if not inside:
                if re.match(r"^(Notes?|Source|Sources)\s*[:.]", text):
                    continue
                if len(text) > 80:
                    continue
            grown |= lr
    # Hard stop at the notes block. Excluding the notes LINE was not enough: the padding
    # added afterwards reached a few points back into it and sliced the tops off its
    # letters, so a dozen figures came out with a half-height line of "Notes: The figure
    # depicts..." along the bottom, which reads as a broken image.
    if stop_below < page.rect.y1:
        grown.y1 = min(grown.y1, stop_below - PAD - 2)
    if stop_above > page.rect.y0:
        grown.y0 = max(grown.y0, stop_above + PAD + 2)
    return grown


def find(project, wanted=None):
    meta = PAPERS[project]
    pdfs = transcript_pdf_paths(project, meta)
    jobs = []
    for pdf in pdfs:
        doc = fitz.open(pdf)
        try:
            for pno in range(doc.page_count):
                page = doc.load_page(pno)
                caps = caption_rects(page)
                if not caps:
                    continue
                bands = drawing_bands(page, [(r.y0, r.y1) for r in caps.values()])
                if not bands:
                    continue
                # Assign captions to bands ONE TO ONE while there are bands to go round.
                # Taking each caption's nearest band independently let two captions claim
                # the same drawing: on /education/'s page the box plot is 37 points from
                # its caption and the four-panel grid below is 36, so Figure A2 was given
                # A3's grid and A3's own band went unused. A caption sits beside its own
                # figure, so competing claims are settled by which one is closer.
                claimed = (assign_by_convention(caps, bands, wanted)
                           or assign(caps, bands, wanted))

                for num, crect in caps.items():
                    if wanted and num not in wanted:
                        continue
                    # the band whose edge is nearest the caption, above or below
                    best, bestd = None, 1e9
                    if num in claimed:
                        rect, n, _t = bands[claimed[num]]
                        # _dist already treats a caption that overlaps the band vertically
                        # as distance zero, which is the sideways-figure case; recomputing
                        # it here with a 2-D intersection lost esg's A1 and learning's A1.
                        best, bestd = (rect, n), _dist(rect, crect)
                    for rect, n, _t in ([] if best else bands):
                        # Vertical distance only. A caption is always beside its artwork
                        # horizontally, and asking for a 2-D intersection missed captions
                        # that sit level with a plot but outside its x-range -- which is
                        # why /learning/'s A1 and /esg/'s A1 found nothing while both a
                        # caption and a band sat on the page.
                        if rect.y0 - 2 <= crect.y0 <= rect.y1 + 2 or \
                                rect.y0 - 2 <= crect.y1 <= rect.y1 + 2:
                            d = 0
                        else:
                            d = min(abs(rect.y0 - crect.y1), abs(crect.y0 - rect.y1))
                        if d < bestd:
                            best, bestd = (rect, n), d
                    if not best or bestd > 230:
                        continue
                    rect = grow_to_labels(page, best[0], crect)
                    rect = fitz.Rect(max(page.rect.x0, rect.x0 - PAD),
                                     max(page.rect.y0, rect.y0 - PAD),
                                     min(page.rect.x1, rect.x1 + PAD),
                                     min(page.rect.y1, rect.y1 + PAD))
                    # Stop cleanly at any caption on the page, its own included. The pad
                    # above was reaching into the caption line and slicing the tops off its
                    # letters, which looks like a broken image rather than a tight crop.
                    # A caption is never part of the artwork, so the crop stops at it even
                    # where the drawing band runs on past it -- which happens whenever a
                    # background panel or an axis rule is drawn the full height of the
                    # float. Requiring the caption to sit clear of the band, as this once
                    # did, let it through on /risk/'s Figures 3 and 4, /bma/'s B1 and
                    # /migrant/'s A2, each of which shipped with a strip of its own caption
                    # baked into the picture.
                    mid = 0.5 * (best[0].y0 + best[0].y1)
                    for cr in caps.values():
                        if caption_rotation(page, cr) not in (0, None):
                            continue          # a sideways caption sits beside the artwork
                        if cr.x1 < rect.x0 or cr.x0 > rect.x1:
                            continue          # a caption in the other column
                        if cr.y1 <= mid:
                            edge = cr.y1 + 2
                            if edge < rect.y1 - 40:
                                rect.y0 = max(rect.y0, edge)
                        elif cr.y0 >= mid:
                            edge = cr.y0 - 2
                            if edge > rect.y0 + 40:
                                rect.y1 = min(rect.y1, edge)
                    rect = clear_of_text(page, rect, best[0])
                    jobs.append(dict(project=project, fig=num, pdf=pdf, page=pno,
                                     rect=[round(v, 1) for v in rect],
                                     ops=best[1], gap=round(bestd, 1),
                                     caption_x=round(crect.x0, 1),
                                     caption_y=round(crect.y0, 1),
                                     frac=round(rect.height / page.rect.height, 3)))
        finally:
            doc.close()
    # one job per figure number: the closest band wins
    best = {}
    for j in jobs:
        if j["fig"] not in best or j["gap"] < best[j["fig"]]["gap"]:
            best[j["fig"]] = j
    return split_shared_bands(list(best.values()))


def _dist(rect, crect):
    if rect.y0 - 2 <= crect.y0 <= rect.y1 + 2 or rect.y0 - 2 <= crect.y1 <= rect.y1 + 2:
        return 0.0
    return min(abs(rect.y0 - crect.y1), abs(crect.y0 - rect.y1))


def assign_by_convention(caps, bands, wanted):
    """Assign captions to bands using the page's own caption convention.

    A page is consistent about where it puts captions: /migrant/'s appendix sets them under
    each figure, /electricity/ sets them over. Deciding per caption instead produced two
    wrong answers at once -- /education/'s Figure A2 took the grid below it rather than the
    box plot above, because the grid was one point nearer.

    So score the whole page both ways and keep the better. Several captions may then land on
    one band, which on /migrant/'s 2x2 pages is exactly right: the band is a ROW of two
    figures, and split_shared_bands cuts it into columns by caption x.
    """
    # Score EVERY caption on the page, not just the ones asked for. The competition for a
    # band is between all of them, so filtering first changes the answer: asking for
    # education's A2 alone gave it A3's grid, while asking for A2 and A3 together gave the
    # right one -- and rerunning a single figure is exactly how a fix gets applied.
    names = list(caps)
    if not names or not bands:
        return {}

    def score(below):
        # below=True: the caption sits under its figure, so look for a band ABOVE it
        out, total = {}, 0.0
        for n in names:
            c = caps[n]
            cands = []
            for bi, (r, _, _t) in enumerate(bands):
                # A sideways figure has a sideways caption, whose box then sits INSIDE the
                # drawing's band rather than above or below it. /esg/'s A1 and /learning/'s
                # A1 are both like that, and requiring a side lost them entirely.
                # A table's rules are drawings too, and on lags page 26 the table is
                # nearer the caption than the plot. A Figure caption should not own one
                # unless there is nothing else on the page.
                penalty = 400.0 if bands[bi][2] else 0.0
                if r.y0 <= c.y0 and c.y1 <= r.y1:
                    cands.append((penalty, bi))
                    continue
                d = (c.y0 - r.y1) if below else (r.y0 - c.y1)
                if d >= -2:
                    cands.append((max(d, 0.0) + penalty, bi))
            if not cands:
                return None, 1e18
            d, bi = min(cands)
            if d > 230 + (400.0 if bands[bi][2] else 0.0):
                return None, 1e18
            out[n], total = bi, total + d
        return out, total

    a, sa = score(True)
    b, sb = score(False)
    if a is None and b is None:
        return {}
    return a if (b is None or sa <= sb) else b


def assign(caps, bands, wanted):
    """Match captions to bands one-to-one, minimising total distance.

    Taking the nearest band per caption independently is not enough, and choosing greedily
    in distance order is not either: on /education/'s page Figure A2's caption is 36 points
    from A3's grid and 37 from its own box plot, so the greedy pass spends the grid on A2
    and leaves A3 with a band 451 points away, which is no assignment at all. Costing the
    whole arrangement picks 37 + 38 over 36 + 451.

    Pages here have a handful of figures, so the arrangements can simply be enumerated.
    Above that it falls back to nearest-first, which is what it always did.
    """
    import itertools
    names = list(caps)
    if not names or not bands:
        return {}
    cost = {(n, bi): _dist(bands[bi][0], caps[n]) + (400.0 if bands[bi][2] else 0.0)
        for n in names
            for bi in range(len(bands))}
    k = min(len(names), len(bands))
    if len(names) <= 6 and len(bands) <= 6:
        best, bestsum = None, None
        for combo in itertools.permutations(range(len(bands)), k):
            for pick in itertools.combinations(range(len(names)), k):
                tot = sum(cost[(names[pick[i]], combo[i])] for i in range(k))
                if bestsum is None or tot < bestsum:
                    bestsum = tot
                    best = {names[pick[i]]: combo[i] for i in range(k)}
        return {n: bi for n, bi in (best or {}).items() if cost[(n, bi)] <= 230}
    out, used = {}, set()
    for dist, n, bi in sorted((cost[(n, bi)], n, bi) for n in names
                              for bi in range(len(bands))):
        if n in out or bi in used or dist > 230:
            continue
        out[n], _ = bi, used.add(bi)
    return out


def split_shared_bands(jobs):
    """Give each figure its own half when two captions picked the same drawing.

    A paper that prints two figures side by side, or one above the other, puts both
    captions beside a single block of drawing, and the nearest-band rule then hands both
    of them the same crop. Twelve figures on this site were published that way: migrant's
    B1 and B2 were one image showing both, and so on through B15/B16.

    Which way to cut is in the captions themselves. Side-by-side captions differ in x, so
    the figures are columns; stacked captions differ in y, so they are rows. Order the
    captions along that axis and give each an equal share, because a figure and its own
    caption line up on it.
    """
    by_band = {}
    for j in jobs:
        key = (j["pdf"], j["page"], tuple(round(v) for v in j["rect"]))
        by_band.setdefault(key, []).append(j)
    for key, group in by_band.items():
        if len(group) < 2:
            continue
        x0, y0, x1, y1 = key[2]
        cx = [j["caption_x"] for j in group]
        cy = [j["caption_y"] for j in group]
        horizontal = (max(cx) - min(cx)) >= (max(cy) - min(cy))
        group.sort(key=lambda j: j["caption_x"] if horizontal else j["caption_y"])
        n = len(group)
        for i, j in enumerate(group):
            if horizontal:
                w = (x1 - x0) / n
                j["rect"] = [x0 + i * w, y0, x0 + (i + 1) * w, y1]
            else:
                h = (y1 - y0) / n
                j["rect"] = [x0, y0 + i * h, x1, y0 + (i + 1) * h]
            j["shared"] = n
    return [j for k in sorted({j["fig"] for j in jobs})
            for j in jobs if j["fig"] == k]


def crop_baked_notes(path):
    """Cut a notes column off a figure whose text is baked into the image.

    /armington/'s Figure 4 is a single raster: a landscape heatmap laid sideways on the
    page with its own notes paragraph printed down the side, all inside the image. There is
    no text layer to exclude and no transform to read, so the page-level rules cannot see
    any of it. What the pixels do show is structure: the plot is in colour, and to its right
    sit the axis values, a blank stripe, and then a block of black text.

    So cut at the SECOND blank stripe past the colour -- keeping the axis values, dropping
    the notes -- and only when a stripe is actually there. Returns True if it cropped.
    """
    from PIL import Image
    import numpy as np
    im = Image.open(path).convert("RGB")
    a = np.asarray(im)
    ink = (a.min(axis=2) < 170).mean(axis=0)
    sat = np.asarray(im.convert("HSV"))[:, :, 1]
    colour = (sat > 60).mean(axis=0)
    xs = np.flatnonzero(colour > 0.02)
    if not len(xs) or xs.max() > im.width * 0.92:
        return False                       # no distinct colour region, or it fills the frame
    stripes, run = [], None
    for x in range(int(xs.max()), im.width):
        if ink[x] < 0.004:
            run = (run[0], x) if run else (x, x)
        elif run:
            if run[1] - run[0] >= 6:
                stripes.append(run)
            run = None
    if len(stripes) < 2:
        return False                       # nothing but the plot out there
    cut = stripes[1][1]
    if cut > im.width * 0.95:
        return False                       # the "notes" are the frame edge, not a block
    im.crop((0, 0, cut, im.height)).save(path)
    return True


# A bitmap can be saved on its side and then placed in an upright float. The page says
# upright, the placement matrix says upright, and the picture is still sideways, because it
# was sideways before it ever reached the PDF. Nothing in the file records that, so the one
# figure in this corpus where it happens is written down here, confirmed by eye. It replaces
# a pixel test that tried to infer it -- which axis of the image flips between ink and blank
# more often -- and that test put six upright figures on their sides before it was removed:
# a box plot with study names set vertically looks, to it, exactly like a rotated page.
SIDEWAYS_BITMAP = {("armington", "4"): 90}


def raster_rotation(page, rect):
    """How the biggest image inside the crop is placed, or None if the crop has no image.

    A placed image carries the matrix that puts it on the page, and a quarter turn shows up
    there exactly: the diagonal terms go to zero and the off-diagonal ones do the work. This
    is a fact recorded in the file, not an inference.
    """
    r = fitz.Rect(*rect)
    best, area = None, 0.0
    for im in page.get_image_info():
        hit = fitz.Rect(im["bbox"]) & r
        if not hit.is_empty and hit.get_area() > area:
            best, area = im, hit.get_area()
    if best is None or area < 0.5 * (r.get_area() or 1):
        return None
    a, b, c, d = best["transform"][:4]
    if abs(a) > abs(b) and abs(d) > abs(c):
        return 0
    return 90 if b < 0 else 270


def caption_rotation(page, crect):
    """Which way the figure's own caption runs, or None if there is no caption to read.

    The caption belongs to the float, so a figure printed sideways carries its caption
    sideways with it. That makes the caption the plainest statement of the float's
    orientation the page has, and unlike the artwork it is always real text.
    """
    if crect is None:
        return None
    votes = {}
    for b in page.get_text("dict")["blocks"]:
        for line in b.get("lines", []):
            if not fitz.Rect(crect).intersects(fitz.Rect(line["bbox"])):
                continue
            dx, dy = line.get("dir", (1, 0))
            n = len("".join(s["text"] for s in line["spans"]).strip())
            key = 0 if abs(dx) > 0.7 else (90 if dy < -0.7 else 270)
            votes[key] = votes.get(key, 0) + n
    return max(votes, key=votes.get) if votes else None


def clear_of_text(page, rect, band):
    """Pull the crop's edges back off any running head or line of body prose.

    The padding and the label growth both work outwards from the artwork, and where a plot
    begins a few points under the running head or the previous paragraph they reach into it
    and slice its letters in half. A crop with the top half of "BANK COMPETITION AND
    FINANCIAL STABILITY" along its top edge reads as a broken image.

    Only the padding is given up: the edges never move inside the drawing itself, so a
    figure genuinely butted against the text keeps its artwork and its defect, and the
    reviewer sees it rather than a silently cropped plot.
    """
    head_y = page.rect.y0 + page.rect.height * 0.11
    foot_y = page.rect.y1 - page.rect.height * 0.07
    colw = column_width(page)
    out = fitz.Rect(rect)
    for b in page.get_text("dict")["blocks"]:
        # A paragraph's LAST line is short, and judging lines one at a time let those
        # through: competition's Figure A2 kept "Fernandez et al. (2001)." across its top,
        # the tail of the paragraph above it. If any line of a block is full-measure prose,
        # every line of that block is prose.
        block_is_prose = any(
            len("".join(s["text"] for s in ln["spans"]).strip()) > 60
            and fitz.Rect(ln["bbox"]).width > 0.80 * colw
            for ln in b.get("lines", []))
        for line in b.get("lines", []):
            t = "".join(s["text"] for s in line["spans"]).strip()
            if not t:
                continue
            lr = fitz.Rect(line["bbox"])
            running = lr.y1 <= head_y or lr.y0 >= foot_y
            prose = block_is_prose
            notes = bool(re.match(r"^(Notes?|Sources?)\s*[:.]", t))
            if not (running or prose or notes):
                continue
            if not out.intersects(lr):
                continue
            if lr.y1 <= band.y0 and out.y0 < lr.y1:          # sits above the artwork
                out.y0 = min(lr.y1 + 2, band.y0)
            elif lr.y0 >= band.y1 and out.y1 > lr.y0:        # sits below it
                out.y1 = max(lr.y0 - 2, band.y1)
            elif prose and lr.x1 <= band.x0 and out.x0 < lr.x1:   # the column to its left
                out.x0 = min(lr.x1 + 2, band.x0)
            elif prose and lr.x0 >= band.x1 and out.x1 > lr.x0:   # or to its right
                out.x1 = max(lr.x0 - 2, band.x1)
    return out


def text_rotation(page, rect):
    """0, 90 or 270: how far the text inside this crop is turned from upright.

    A landscape figure on a portrait page is printed on its side, and a crop of it comes out
    sideways -- /learning/'s A1 is two histograms lying on their backs. PyMuPDF reports a
    writing direction per line, so the figure's own labels say which way is up.
    """
    votes = {}
    r = fitz.Rect(*rect)
    for b in page.get_text("dict")["blocks"]:
        for line in b.get("lines", []):
            if not r.intersects(fitz.Rect(line["bbox"])):
                continue
            dx, dy = line.get("dir", (1, 0))
            n = len("".join(s["text"] for s in line["spans"]).strip())
            if abs(dx) > 0.7:
                votes["up"] = votes.get("up", 0) + n
            elif dy < -0.7:
                votes[90] = votes.get(90, 0) + n
            elif dy > 0.7:
                votes[270] = votes.get(270, 0) + n
    if not votes:
        # None, not 0: the page has no text here to judge by, which is a different answer
        # from "the text here is upright" and the only case where the pixel test should get
        # a say. Returning 0 for both let the pixel test overrule perfectly upright figures
        # -- it turned /risk/'s Figure 2 on its side, and five others with it.
        return None
    best = max(votes, key=votes.get)
    # only turn it when the sideways text clearly dominates
    if best == "up" or votes[best] < 2 * votes.get("up", 0):
        return 0
    return best


def render(job, dpi=200):
    doc = fitz.open(job["pdf"])
    try:
        page = doc.load_page(job["page"])
        pix = page.get_pixmap(clip=fitz.Rect(*job["rect"]), dpi=dpi)
        out = os.path.join(page_dir(job["project"], PAPERS[job["project"]]), "figures")
        os.makedirs(out, exist_ok=True)
        path = os.path.join(out, "fig%s.png" % job["fig"])
        pix.save(path)
        # Order matters: read the rotation BEFORE cutting anything off. On a raster figure
        # the sideways notes column carries most of the evidence for which way is up, so
        # cropping it first leaves nothing to judge by.
        #
        # Everything consulted here is recorded in the PDF. An earlier version fell back to
        # a pixel test -- which axis of the image flips between ink and blank more often --
        # and it was wrong far more often than it was right: it turned /risk/'s Figure 2,
        # /education/'s A1 and four others onto their sides, because a box plot with study
        # names set vertically looks, to that test, exactly like a page printed sideways.
        # In order of how directly each one answers the question. The figure's own labels
        # settle it whenever they are real text; a figure drawn entirely in vector strokes
        # has none, and then the file still records how its bitmap was placed and which way
        # its caption runs, both of which turn with the float.
        angle = SIDEWAYS_BITMAP.get((job["project"], job["fig"]))
        if angle is None:
            angle = text_rotation(page, job["rect"])
        if angle is None:
            angle = raster_rotation(page, job["rect"])
        if angle is None:
            angle = caption_rotation(page, caption_rects(page).get(job["fig"]))
        angle = angle or 0
        crop_baked_notes(path)
        if angle:
            from PIL import Image as _I
            im = _I.open(path)
            im.rotate(-90 if angle == 90 else 90, expand=True).save(path)
            return path, im.height, im.width
        return path, pix.width, pix.height
    finally:
        doc.close()


def main(argv):
    apply = "--apply" in argv
    argv = [a for a in argv if a != "--apply"]
    dpi = 200
    if "--dpi" in argv:
        i = argv.index("--dpi")
        dpi = int(argv[i + 1]); argv = argv[:i] + argv[i + 2:]
    if not argv:
        raise SystemExit("usage: figure_from_drawings.py <project> [<fig> ...] [--apply]")
    project, wanted = argv[0], set(argv[1:]) or None
    jobs = find(project, wanted)
    if not jobs:
        print("%-20s no figure found" % project)
        return 0
    for j in jobs:
        line = ("%-16s fig%-4s page %-3d ops %-5d gap %-6.1f height %.2f of page"
                % (j["project"], j["fig"], j["page"] + 1, j["ops"], j["gap"], j["frac"]))
        if apply:
            p, w, h = render(j, dpi)
            line += "   -> %s %dx%d" % (os.path.basename(p), w, h)
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
