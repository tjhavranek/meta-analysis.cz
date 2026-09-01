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
            out.setdefault(label, fitz.Rect(line["bbox"]))
    return out


def drawing_bands(page, bar_rows=None):
    """Contiguous vertical bands where the page draws, widest x-extent of each."""
    rects = []
    for d in page.get_drawings():
        r = d["rect"]
        if r.is_empty or r.is_infinite:
            continue
        rects.append(r)
    for img in page.get_images(full=True):
        try:
            for r in page.get_image_rects(img[0]):
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
        boxes.append([fitz.Rect(min(r.x0 for r in b), min(r.y0 for r in b),
                                max(r.x1 for r in b), max(r.y1 for r in b)), len(b)])

    # A flow diagram is boxes joined by arrows, and the blank between two of its rows can
    # be wider than the gap that separates two different objects. /inflation/'s PRISMA
    # chart split into three and published clipped at the first arrow. What actually ends
    # a figure is running prose, not white space, so merge neighbours unless a full-measure
    # line of text sits between them.
    # Barriers: a caption belonging to ANY figure, and any line of running prose. The
    # caption barrier is the load-bearing one. Without it /students/'s Figure 2 merged
    # straight through its own caption and notes and swallowed Figure 3 as well, which is
    # a worse failure than the clipping this merge exists to fix.
    prose_rows = list(bar_rows or [])
    for b in page.get_text("dict")["blocks"]:
        for line in b.get("lines", []):
            t = "".join(s["text"] for s in line["spans"]).strip()
            lr = fitz.Rect(line["bbox"])
            if len(t) > 80 and lr.width > 0.45 * page.rect.width:
                prose_rows.append((lr.y0, lr.y1))
            elif re.match(r"^(?:FIGURE|Figure|Fig\.|F\s*I\s*G\s*U\s*R\s*E|TABLE|Table)\b", t):
                prose_rows.append((lr.y0, lr.y1))

    merged = []
    for rect, n in boxes:
        if merged:
            prev, pn = merged[-1]
            blocked = any(prev.y1 - 2 < y1 and y0 < rect.y0 + 2 for y0, y1 in prose_rows)
            overlap = min(prev.x1, rect.x1) - max(prev.x0, rect.x0)
            if (not blocked and rect.y0 - prev.y1 < 90
                    and overlap > 0.3 * min(prev.width, rect.width)):
                merged[-1] = [fitz.Rect(prev) | rect, pn + n]
                continue
        merged.append([rect, n])
    out = []
    for rect, n in merged:
        if rect.height >= MIN_H and rect.height / page.rect.height >= MIN_FRAC:
            out.append((rect, n))
    return out


def grow_to_labels(page, rect, caption):
    """Take in the tick labels, axis titles and legend that sit with the artwork.

    They are text, so the band of drawing alone clips them. Any text line that overlaps the
    artwork horizontally and sits within a short reach of it belongs to it -- except the
    caption itself and anything at or beyond the caption, which is where the figure ends.
    """
    grown = fitz.Rect(rect)
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
                for num, crect in caps.items():
                    if wanted and num not in wanted:
                        continue
                    # the band whose edge is nearest the caption, above or below
                    best, bestd = None, 1e9
                    for rect, n in bands:
                        d = min(abs(rect.y0 - crect.y1), abs(crect.y0 - rect.y1))
                        if rect.intersects(crect):
                            d = 0
                        if d < bestd:
                            best, bestd = (rect, n), d
                    if not best or bestd > 140:
                        continue
                    rect = grow_to_labels(page, best[0], crect)
                    rect = fitz.Rect(max(page.rect.x0, rect.x0 - PAD),
                                     max(page.rect.y0, rect.y0 - PAD),
                                     min(page.rect.x1, rect.x1 + PAD),
                                     min(page.rect.y1, rect.y1 + PAD))
                    # Stop cleanly at any caption on the page, its own included. The pad
                    # above was reaching into the caption line and slicing the tops off its
                    # letters, which looks like a broken image rather than a tight crop.
                    for cr in caps.values():
                        if cr.y1 <= best[0].y0 and rect.y0 < cr.y1:
                            rect.y0 = min(cr.y1 + 2, best[0].y0)
                        elif cr.y0 >= best[0].y1 and rect.y1 > cr.y0:
                            rect.y1 = max(cr.y0 - 2, best[0].y1)
                    jobs.append(dict(project=project, fig=num, pdf=pdf, page=pno,
                                     rect=[round(v, 1) for v in rect],
                                     ops=best[1], gap=round(bestd, 1),
                                     frac=round(rect.height / page.rect.height, 3)))
        finally:
            doc.close()
    # one job per figure number: the closest band wins
    best = {}
    for j in jobs:
        if j["fig"] not in best or j["gap"] < best[j["fig"]]["gap"]:
            best[j["fig"]] = j
    return [best[k] for k in sorted(best)]


def render(job, dpi=200):
    doc = fitz.open(job["pdf"])
    try:
        page = doc.load_page(job["page"])
        pix = page.get_pixmap(clip=fitz.Rect(*job["rect"]), dpi=dpi)
        out = os.path.join(page_dir(job["project"], PAPERS[job["project"]]), "figures")
        os.makedirs(out, exist_ok=True)
        path = os.path.join(out, "fig%s.png" % job["fig"])
        pix.save(path)
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
