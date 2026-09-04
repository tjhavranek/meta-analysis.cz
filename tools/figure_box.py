#!/usr/bin/env python3
"""Work out the crop box for a figure from the page's own geometry.

    python3 tools/figure_box.py <project> [<fig> ...] [--page N] [--pdf F] [--json]

Prints a line per figure ready to hand to extract_figure.py.

Why this exists. Thirty figures on this site were cut wrong, and every one of them
was cut by eye off a rendered preview. The failures were all the same two shapes:

  * the box was placed against the visible MASS of the plot, so a sparse right tail
    fell outside it -- a ".1" tick and the estimates beyond it, two histogram bars,
    the last two months of every forecast series, a whole stacked panel;
  * the box was placed against the text BLOCK, so it swallowed the running head above
    and the paper's own Notes paragraph below -- which the transcript then printed a
    second time as the caption.

Both are invisible afterwards. The crop is trimmed back to its own ink, so the result
looks deliberate whichever way it went wrong, and no gate on the site opens an image.

So the box is not guessed here. The page says where its artwork is: an embedded image
has a rect, and a vector plot is a heap of drawing operations. Take those, keep the
ones next to the caption, and grow the box to include the text that belongs to the
artwork -- tick labels, axis titles, legend entries, panel titles, sub-captions -- while
refusing the text that does not: the caption, the notes, the running head, the folio,
and any paragraph of prose.

Then the edges are put in white gaps, so a rounding error costs whitespace instead of
a glyph.

The result is a PROPOSAL, and it has to be looked at. Run against the 71 figures of eight
papers whose figures had just been checked one by one, it disagreed with sixteen of them --
every disagreement a case where the stored figure was right and this was wrong, mostly on
pages laid out in ways the rules above do not cover. So it is not a screen and must not be
made into one: a gate that calls one figure in five wrong would cost more than the thirty
it would have caught, by inviting a later session to recut figures that are already
correct. Generate a box with it, cut the figure, and look at the two side by side.
"""

import io
import json
import os
import re
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import fitz

DPI = 150
THRESHOLD = 232
HAIRLINE = 3.0        # a drawing thinner than this in both directions is a rule, not artwork
NEAR = 26.0           # points: how far a label may sit from the artwork and still belong
PROSE_LINES = 2       # a block this tall, with PROSE_WORDS words, is prose
PROSE_WORDS = 15
GAP = 0.004           # keep this much page away from whatever bounds the figure
MARGIN = 0.075        # a lone line this far out is a running head or a folio

CAP_LINE = re.compile(r"^(?:FIGURE|Figure|FIG\.|Fig\.)\s*([A-Za-z]?[\d.]*[A-Za-z]?\d*)\s*(?:[.:]|$)")


def cap_match(text):
    """The figure number this line captions, or None.

    Wiley letter-spaces its captions -- the text layer gives "F I G U R E 3", not
    "FIGURE 3" -- so the spacing inside the word is collapsed before matching. Only
    runs of single letters are joined, or "Fig. 1 2" would become "Fig. 12".
    """
    t = re.sub(r"(?:[A-Za-z]\s){2,}[A-Za-z]",
               lambda m: m.group(0).replace(" ", ""), text.strip())
    m = CAP_LINE.match(t)
    return m.group(1).rstrip(".") if m else None


def same_figure(found, want):
    """Whether the PDF's label names the figure the transcript calls `want`.

    A paper can print "Figure C.2" for what the transcript numbers C2, so the dots are
    not significant; the comparison is on letters and digits alone.
    """
    norm = lambda x: re.sub(r"[^A-Za-z0-9]", "", x or "").upper()
    return norm(found) == norm(want)
NOTE_LINE = re.compile(r"^(Notes?|Source)\s*[:.]", re.I)
TAB_LINE = re.compile(r"^(?:TABLE|Table|TAB\.|Tab\.)\s*[A-Za-z]?[\d.]*[A-Za-z]?\d*\s*(?:[.:]|$)")


class Page(object):
    def __init__(self, doc, pno):
        self.pg = doc.load_page(pno)
        self.rot = self.pg.rotation_matrix
        self.W, self.H = self.pg.rect.width, self.pg.rect.height
        self.blocks = []
        for b in self.pg.get_text("dict")["blocks"]:
            bl = b.get("lines", [])
            if not bl:
                continue
            r = fitz.Rect(b["bbox"]) * self.rot
            first = "".join(s["text"] for s in bl[0]["spans"]).strip()
            # Count WORDS, not tokens. A plot's axis prints "0 1 2 3 ... 18" as a two-line
            # block of nineteen tokens, and counting those as prose put a wall between the
            # two panels of a stacked figure, so the merge below refused and the upper
            # panel was dropped. A word has letters in it.
            words = sum(1 for l in bl
                        for t in ("".join(s["text"] for s in l["spans"])).split()
                        if len(re.sub(r"[^A-Za-z]", "", t)) >= 2)
            # A caption or a note opens its own paragraph. Testing every line instead
            # matches running prose that happens to wrap onto "Fig. 2. In the absence
            # of ..." and sends the whole calculation into the wrong column.
            kind = "text"
            if cap_match(first):
                kind = "caption"
            elif TAB_LINE.match(first):
                # A table's caption bounds a figure exactly as another figure's does.
                kind = "caption"
            elif NOTE_LINE.match(first):
                kind = "note"
            elif len(bl) >= PROSE_LINES and words >= PROSE_WORDS:
                kind = "prose"
            elif r.y1 / self.H < MARGIN or r.y0 / self.H > 1 - MARGIN:
                # A running head or a folio: one line, out in the margin. It has to bound
                # the box like a caption does, or the box walks up over it looking for
                # white -- which is how five frisch figures came to carry the running head.
                kind = "furniture"
            sizes = [s["size"] for l in bl for s in l["spans"]]
            self.blocks.append({"rect": r, "kind": kind, "first": first, "words": words,
                                "size": max(sizes) if sizes else 0.0,
                                "lines": [(fitz.Rect(l["bbox"]) * self.rot,
                                           max([s["size"] for s in l["spans"]] or [0.0]))
                                          for l in bl]})

    def art_rects(self):
        """Everything the page draws, minus the hairlines that rule tables.

        Also minus whatever is drawn wholly inside the margins. A publisher's masthead is
        vector art like any plot -- hedge's pages carry the Wiley logo as thirty little
        paths -- and it sits close enough to the figure below it to be clustered with it,
        which puts the journal's logo in the picture. Nothing that is entirely inside the
        running-head strip is part of a figure, however large the figure is.
        """
        out = []
        for im in self.pg.get_images(full=True):
            for r in self.pg.get_image_rects(im[0]):
                r = fitz.Rect(r) * self.rot
                if r.width > HAIRLINE and r.height > HAIRLINE:
                    out.append(r)
        for d in self.pg.get_drawings():
            r = fitz.Rect(d["rect"]) * self.rot
            if r.width > HAIRLINE and r.height > HAIRLINE:
                out.append(r)
        return [r for r in out
                if not (r.y1 / self.H < MARGIN or r.y0 / self.H > 1 - MARGIN)]

    def ink(self):
        px = self.pg.get_pixmap(dpi=DPI)
        a = np.frombuffer(px.samples, np.uint8).reshape(px.height, px.width, px.n)[:, :, :3]
        return a.min(axis=2) < THRESHOLD, px


def cluster(rects, pad=NEAR):
    """Group rects that touch or nearly touch into single figures."""
    boxes = []
    for r in rects:
        grown = fitz.Rect(r.x0 - pad, r.y0 - pad, r.x1 + pad, r.y1 + pad)
        hit = [i for i, b in enumerate(boxes) if b.intersects(grown)]
        if not hit:
            boxes.append(fitz.Rect(r))
            continue
        merged = fitz.Rect(r)
        for i in sorted(hit, reverse=True):
            merged = merged | boxes.pop(i)
        boxes.append(merged)
    # merging can bring previously separate groups into contact; settle it
    changed = True
    while changed:
        changed = False
        for i in range(len(boxes)):
            for j in range(len(boxes) - 1, i, -1):
                gi = fitz.Rect(boxes[i].x0 - pad, boxes[i].y0 - pad,
                               boxes[i].x1 + pad, boxes[i].y1 + pad)
                if gi.intersects(boxes[j]):
                    boxes[i] = boxes[i] | boxes.pop(j)
                    changed = True
    return boxes


def box_for(p, num):
    """The crop box for one figure, or a string saying why there isn't one."""
    caps = [b for b in p.blocks if same_figure(cap_match(b["first"]), num)]
    if not caps:
        return "no caption block on this page"
    cap = caps[0]["rect"]
    cap_size = caps[0]["size"]

    # A page can print two figures side by side -- migrant does it on four appendix pages,
    # sixteen figures in eight pairs -- and they sit close enough that clustering joins
    # them into one. Each has its own caption underneath it, so the captions divide the
    # page: this figure owns the strip from the midpoint with its left neighbour to the
    # midpoint with its right one, and artwork outside that strip belongs to the other
    # figure.
    mid = lambda r: (r.x0 + r.x1) / 2.0
    siblings = [b["rect"] for b in p.blocks if b["kind"] == "caption"
                and b["rect"] is not cap
                and min(b["rect"].y1, cap.y1) - max(b["rect"].y0, cap.y0) > -6.0]
    left = max([mid(s) for s in siblings if mid(s) < mid(cap)] or [0.0])
    right = min([mid(s) for s in siblings if mid(s) > mid(cap)] or [p.W])
    strip = fitz.Rect((left + mid(cap)) / 2.0 if left else 0.0, 0.0,
                      (right + mid(cap)) / 2.0 if right < p.W else p.W, p.H)

    art = cluster([r for r in p.art_rects()
                   if min(r.x1, strip.x1) - max(r.x0, strip.x0) > 0.5 * r.width])
    if not art:
        return "the page draws nothing here"

    # The figure is the cluster nearest its caption, measured on the axis the caption
    # is offset along. A caption set vertically down the margin -- three of these pages
    # do that -- sits beside its figure, not under it, so distance must be plain
    # rectangle distance and not a vertical gap.
    def dist(b):
        dx = max(b.x0 - cap.x1, cap.x0 - b.x1, 0)
        dy = max(b.y0 - cap.y1, cap.y0 - b.y1, 0)
        return (dx * dx + dy * dy) ** 0.5
    # A caption can sit above its figure or below it, and the same paper can do both --
    # lags prints "Figure 6." above its artwork on one page and frisch prints "Fig. 4."
    # under a Notes block on another. Distance alone then picks the previous figure's
    # artwork, which is a different picture entirely. What separates them is what lies in
    # between: between a caption and its own figure there is nothing, while between a
    # caption and the figure before it there is that figure's notes.
    def clean_run(b):
        lo, hi = min(b.y1, cap.y0), max(b.y0, cap.y1)
        if hi <= lo:
            return True
        return not any(f["rect"].y0 < hi and f["rect"].y1 > lo
                       and f["rect"].x0 < min(b.x1, cap.x1) and f["rect"].x1 > max(b.x0, cap.x0)
                       for f in p.blocks if f["kind"] in ("caption", "note"))

    # A table is drawn too, and on a page where a table sits above a figure the table's
    # ruled box is the cluster nearest the caption. lags page 26 is exactly that -- Table 9,
    # its note, then Figure 6's caption, then the figure -- and taking the nearest cluster
    # cropped the table and called it Figure 6. What tells them apart is the text inside:
    # a table holds paragraphs, a figure holds labels.
    def holds_prose(b):
        return any(b.intersects(f["rect"]) for f in p.blocks if f["kind"] == "prose")

    art.sort(key=lambda b: (holds_prose(b), not clean_run(b), dist(b)))
    box = fitz.Rect(art[0])

    # A figure of stacked panels is several clusters, not one: the gap between the upper
    # panel's axis title and the lower panel's title is text, so the drawings themselves
    # sit 39pt apart and never merge. Taking the nearest cluster alone then keeps the
    # panel by the caption and silently drops the others -- exactly the education A4 and
    # competition 4 defects. So absorb any further cluster that overlaps this one
    # horizontally with no caption, note, prose or furniture lying between them: those
    # are what separate one figure from the next, and between two panels there are none.
    forbidden = [b["rect"] for b in p.blocks
                 if b["kind"] in ("caption", "note", "prose", "furniture")]

    def shrink(f, by=2.5):
        # A text box carries leading above and below its glyphs, so an axis title's box
        # can overlap the caption's box by a point while the ink is a clear line apart.
        # Testing against the raw rects refused to absorb the axis titles of a figure
        # whose caption sat immediately under them -- recreating the very defect this
        # tool exists to prevent. The edges are clamped to the true rects afterwards.
        return fitz.Rect(f.x0 + by, f.y0 + by, max(f.x1 - by, f.x0 + by),
                         max(f.y1 - by, f.y0 + by))

    def nothing_between(a, b):
        lo, hi = min(a.y1, b.y1), max(a.y0, b.y0)
        if hi <= lo:                                # they overlap vertically already
            return True
        return not any(f.y0 < hi and f.y1 > lo and f.x0 < min(a.x1, b.x1)
                       and f.x1 > max(a.x0, b.x0) for f in forbidden)

    changed = True
    while changed:
        changed = False
        for r in art[1:]:
            if box.contains(r):
                continue
            overlap = min(box.x1, r.x1) - max(box.x0, r.x0)
            if overlap <= 0.35 * min(box.width, r.width):
                continue
            if not nothing_between(box, r):
                continue
            cand = box | r
            if any(cand.intersects(f) for f in forbidden):
                continue
            box, changed = cand, True

    # Absorb the artwork's own labels, and nothing else. A tick label, an axis title, a
    # legend entry, a panel title and a sub-caption all sit within a few points of the
    # plot; the caption, the notes, the running head, the folio and any paragraph of
    # prose are excluded by kind whatever their distance.
    core = fitz.Rect(box)                       # artwork only, before labels are absorbed
    for _ in range(8):
        grown = False
        near = fitz.Rect(box.x0 - NEAR, box.y0 - NEAR, box.x1 + NEAR, box.y1 + NEAR)
        for b in p.blocks:
            if b["kind"] in ("caption", "note", "prose", "furniture"):
                continue
            for lr, lsize in b["lines"]:
                if not near.intersects(lr) or box.contains(lr):
                    continue
                if min(lr.x1, strip.x1) - max(lr.x0, strip.x0) <= 0.5 * lr.width:
                    continue          # belongs to the figure beside this one
                # A caption that wraps puts its second line between itself and the
                # artwork, as a block of its own -- "Transmission Lags", "impulse
                # responses)" -- short and centred, so it looks exactly like a panel
                # title, and absorbing it printed the caption inside the picture as well
                # as underneath it. An axis title sits in the same place and does belong.
                # The type size tells them apart: a wrapped caption is still set in the
                # caption's size, and no plot labels its axes in it.
                # Sideways too: a landscape figure on a portrait page gets its caption set
                # vertically down the margin beside the artwork, and its second line is
                # then a separate column between the caption and the plot. lags does this
                # on three pages, and "decrease in prices)" was being read as a label.
                between = ((cap.y1 <= lr.y0 and lr.y1 <= core.y0) or
                           (core.y1 <= lr.y0 and lr.y1 <= cap.y0) or
                           (cap.x1 <= lr.x0 and lr.x1 <= core.x0) or
                           (core.x1 <= lr.x0 and lr.x1 <= cap.x0))
                if between and abs(lsize - cap_size) < 0.4:
                    continue
                cand = box | lr
                if any(cand.intersects(shrink(f)) for f in forbidden):
                    continue          # growing here would swallow the caption or notes
                box, grown = cand, True
        for r in art[1:]:
            near2 = fitz.Rect(box.x0 - NEAR, box.y0 - NEAR, box.x1 + NEAR, box.y1 + NEAR)
            if near2.intersects(r) and not box.contains(r):
                cand = box | r
                if not any(cand.intersects(shrink(f)) for f in forbidden):
                    box, grown = cand, True
        if not grown:
            break

    # Put the edges in white. The box is exact; the crop is not, because it is applied to
    # a raster at whatever dpi, so give it somewhere harmless to land.
    ink, px = p.ink()
    def clear(frac, axis, step):
        """Walk outward from an edge until the row or column is empty."""
        n = px.height if axis == "y" else px.width
        i = int(frac * n)
        for _ in range(int(0.03 * n)):
            j = i + step
            if j < 0 or j >= n:
                return max(0.0, min(1.0, i / float(n)))
            line = ink[j, :] if axis == "y" else ink[:, j]
            if not line.any():
                return j / float(n)
            i = j
        return max(0.0, min(1.0, frac))

    y0 = clear(box.y0 / p.H, "y", -1) - GAP
    y1 = clear(box.y1 / p.H, "y", +1) + GAP
    x0 = clear(box.x0 / p.W, "x", -1) - GAP
    x1 = clear(box.x1 / p.W, "x", +1) + GAP
    # Never cross the caption, the notes or the running head.
    #
    # Two details decide whether this works. The comparison is against the ARTWORK, not
    # against the grown box: an axis title absorbed a moment ago can reach past the
    # caption's box top, and comparing to the grown box then finds nothing to clamp and
    # lets the caption into the picture. And the edge is put at the last blank line
    # before the block's INK, not at its box, because a text box carries leading above
    # its glyphs -- clamping to the box costs a point of the axis title's descenders.
    def edge_of(f, axis, first):
        """Where the block's own INK begins or ends, as a page fraction.

        Its box is not the answer: a text box carries leading above and below the glyphs,
        so clamping to the box costs the neighbouring axis title a point of its
        descenders, and on a page where the two boxes overlap by less than a point it
        costs the whole line."""
        n = px.height if axis == "y" else px.width
        m = px.width if axis == "y" else px.height
        lo = max(int((f.y0 / p.H if axis == "y" else f.x0 / p.W) * n), 0)
        hi = min(int((f.y1 / p.H if axis == "y" else f.x1 / p.W) * n) + 1, n)
        a = max(int((f.x0 / p.W if axis == "y" else f.y0 / p.H) * m), 0)
        b = min(int((f.x1 / p.W if axis == "y" else f.y1 / p.H) * m) + 1, m)
        rows = range(lo, hi) if first else range(hi - 1, lo - 1, -1)
        for i in rows:
            line = ink[i, a:b] if axis == "y" else ink[a:b, i]
            if line.any():
                return i / float(n)
        return (lo if first else hi) / float(n)

    def gap_at(lim, axis, step, stop):
        """The blank line next to a forbidden block, walking away from it.

        A fixed step back from the block's ink is either too small to be safe or big
        enough to shave the axis title beside it -- on one page the two are three
        hundredths of a point apart. The white line between them is the right place, and
        the walk stops at the artwork so it can never collapse the box."""
        n = px.height if axis == "y" else px.width
        i = int(lim * n)
        # Search only a hair: the white line, if there is one, is right here. Walking
        # further finds the gap ABOVE the axis title instead of the one below it, and
        # cuts the title off -- which is the defect, not the fix.
        for _ in range(max(int(0.006 * n), 2)):
            if (i / float(n) - stop) * step >= 0:
                break
            line = ink[i, :] if axis == "y" else ink[:, i]
            if not line.any():
                return i / float(n)
            i += step
        return lim - step * 0.0008

    # A running head or a folio bounds the box whatever the artwork does. Making this
    # conditional on the artwork starting below it is not enough: a plot's frame or a
    # publisher's sidebar rule can reach up past the running head, and then the condition
    # is false, the clamp never fires, and the paper's own header lands in the picture.
    for b in p.blocks:
        if b["kind"] != "furniture":
            continue
        f = b["rect"]
        if f.x1 < box.x0 or f.x0 > box.x1:
            continue
        if f.y1 / p.H < 0.5:
            y0 = max(y0, gap_at(edge_of(f, "y", False), "y", +1, min(core.y0 / p.H, 1.0)))
        else:
            y1 = min(y1, gap_at(edge_of(f, "y", True), "y", -1, max(core.y1 / p.H, 0.0)))

    for f in forbidden:
        if f.y1 <= core.y0:
            y0 = max(y0, gap_at(edge_of(f, "y", False), "y", +1, core.y0 / p.H))
        if f.y0 >= core.y1:
            y1 = min(y1, gap_at(edge_of(f, "y", True), "y", -1, core.y1 / p.H))
        if f.x1 <= core.x0:
            x0 = max(x0, gap_at(edge_of(f, "x", False), "x", +1, core.x0 / p.W))
        if f.x0 >= core.x1:
            x1 = min(x1, gap_at(edge_of(f, "x", True), "x", -1, core.x1 / p.W))
    return (round(max(x0, 0.0), 3), round(max(y0, 0.0), 3),
            round(min(x1, 1.0), 3), round(min(y1, 1.0), 3))


def transcript_figures(project):
    path = os.path.join(ROOT, "tools", "transcripts", project + ".md")
    if not os.path.isfile(path):
        return []
    return [m.group(1) for m in
            (re.match(r"^FIGURE\s+(\S+?)\.\s", l) for l in io.open(path, encoding="utf-8")) if m]


def caption_page(doc, num):
    for i in range(doc.page_count):
        for b in doc.load_page(i).get_text("dict")["blocks"]:
            bl = b.get("lines", [])
            if not bl:
                continue
            if same_figure(cap_match("".join(s["text"] for s in bl[0]["spans"])), num):
                return i
    return None


def main(argv):
    from build_paper_page import documents, transcript_pdf_path
    papers = {p["project"]: p for p in
              json.load(io.open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    papers.update(documents())

    page, pdf, label, as_json = None, None, None, False
    rest = []
    for i, a in enumerate(argv):
        if a.startswith("--page"):
            page = int(a.split("=", 1)[1] if "=" in a else argv[i + 1])
        elif a.startswith("--pdf"):
            pdf = a.split("=", 1)[1] if "=" in a else argv[i + 1]
        elif a.startswith("--label"):
            # What the PDF calls the figure, when that is not what the transcript calls
            # it. reproducibility numbers its extended-data figures ED1..ED10 while the
            # paper prints them as Fig. 5..Fig. 14, so nothing on the page says "ED8".
            label = a.split("=", 1)[1] if "=" in a else argv[i + 1]
        elif a == "--json":
            as_json = True
        elif not a.startswith("--") and not (i and argv[i - 1] in ("--page", "--pdf", "--label")):
            rest.append(a)
    project, figs = rest[0], rest[1:]
    doc = fitz.open(pdf or transcript_pdf_path(project, papers[project]))
    out = []
    for num in (figs or transcript_figures(project)):
        on_page = label or num
        pno = (page - 1) if page is not None else caption_page(doc, on_page)
        if pno is None:
            print("%-16s fig%-5s  caption page not found" % (project, num))
            continue
        got = box_for(Page(doc, pno), on_page)
        if isinstance(got, str):
            print("%-16s fig%-5s  p%-3d  %s" % (project, num, pno + 1, got))
            continue
        out.append({"project": project, "fig": num, "page": pno + 1, "box": list(got)})
        print("python tools/extract_figure.py %s %s %d %.3f %.3f %.3f %.3f --dpi 200"
              % (project, num, pno + 1, got[0], got[1], got[2], got[3]))
    doc.close()
    if as_json:
        print(json.dumps(out, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
