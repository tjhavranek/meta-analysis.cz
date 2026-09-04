#!/usr/bin/env python3
"""Lift one figure out of a paper's PDF and save it for the full-text page.

    python3 tools/extract_figure.py <project> <fig> <page> <x0> <y0> <x1> <y1>
                                    [--dpi 200] [--pdf <file>]

The four coordinates are fractions of the page, measured from the top left, so they can be
read off a rendered preview without knowing the page size: 0.08 0.55 0.95 0.90 means the
lower middle band of the page. The crop is then trimmed back to its own ink, which removes
the slack in a hand-read box and, more usefully, removes the caption line and the margin
strip if the box caught their edge.

Writes <project>/paper/figures/fig<fig>.png, colour-reduced because these are line plots:
a funnel plot in 64 colours is indistinguishable from the same plot in millions and is
twenty times smaller.
"""

import io
import os
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _poppler

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def render(pdf, page, dpi):
    """Rasterise one page, and notice when the rasteriser dropped glyphs.

    poppler substitutes nothing for a non-embedded base-14 font it has no display font
    for: it draws the glyph as blank and says so only on stderr. alphas page 64 plots one
    of its three series as ZapfDingbats circles, and a crop taken through pdftoppm on a
    machine without those substitutes lost the entire series -- 2,014 marker pixels became
    zero -- while the caption beneath it went on describing it. Nothing downstream could
    see that: the image is a valid picture of a plot, just of two series instead of three.

    So the stderr poppler already emits is read, and a page it could not fully draw is
    re-rendered with MuPDF, which carries its own base-14 substitutes. Normal pages keep
    the poppler path, so every crop recorded from it stays reproducible.
    """
    global LAST_RENDERER
    with tempfile.TemporaryDirectory() as tmp:
        stem = os.path.join(tmp, "p")
        r = subprocess.run([_poppler.tool("pdftoppm"), "-f", str(page), "-l", str(page),
                            "-r", str(dpi), "-png", pdf, stem],
                           check=True, capture_output=True)
        err = (r.stderr or b"").decode("utf-8", "replace")
        if "No display font" in err or "Couldn't find a font" in err:
            import fitz
            LAST_RENDERER = "mupdf"
            with fitz.open(pdf) as doc:
                px = doc.load_page(page - 1).get_pixmap(dpi=dpi)
                return Image.frombytes("RGB", (px.width, px.height), px.samples).copy()
        LAST_RENDERER = "poppler"
        name = [f for f in os.listdir(tmp) if f.endswith(".png")][0]
        return Image.open(os.path.join(tmp, name)).convert("RGB").copy()


# Which backend the last render() used. Recorded per figure, because the choice has already
# changed what a picture shows once: poppler drew alphas Figure 8's ZapfDingbats markers as
# nothing, and MuPDF drew them.
LAST_RENDERER = None


def quantize(im, colours):
    """The exact final step of an extraction, so a checker can reproduce it.

    The stored PNG is palettised; a freshly rendered crop is not. Comparing the two without
    this compares an RGB image with a 64-colour one and differs on almost every pixel, which
    is why the comparison has to go through the same call rather than around it.
    """
    return im.quantize(colours, method=Image.MEDIANCUT)


def trim(im, threshold=232, pad=8):
    a = np.asarray(im).min(axis=2)
    ink = a < threshold
    rows, cols = np.where(ink.any(axis=1))[0], np.where(ink.any(axis=0))[0]
    if not len(rows) or not len(cols):
        return im
    return im.crop((max(int(cols[0]) - pad, 0), max(int(rows[0]) - pad, 0),
                    min(int(cols[-1]) + pad + 1, im.width),
                    min(int(rows[-1]) + pad + 1, im.height)))


def extract(project, fig, page, box, dpi=200, colours=64, pdf=None):
    import json
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    from build_paper_page import documents, page_dir, transcript_pdf_path
    papers = {p["project"]: p for p in json.load(open(os.path.join(ROOT, "tools", "papers.json"), encoding="utf-8"))}
    papers.update(documents())
    # The TRANSCRIPT's source, not the hosted PDF. Four pages host one edition while their
    # text follows another -- tourist and transmission host the published article and
    # reproduce the working paper -- and the two editions lay their figures out differently
    # and, for transmission, do not even contain the same ones. Cropping page 17 of the
    # published tourist for a figure the page took from page 17 of the working paper yields
    # a picture of something else, silently. This is the same trap transcript_pdf_path()
    # exists for in the fidelity check and in scout_paper.py, and it is closed the same way.
    pdf = pdf or transcript_pdf_path(project, papers[project])

    im = render(pdf, page, dpi)
    x0, y0, x1, y1 = box
    im = im.crop((int(x0 * im.width), int(y0 * im.height),
                  int(x1 * im.width), int(y1 * im.height)))
    im = trim(im)
    outdir = os.path.join(page_dir(project, papers[project]), "figures")
    os.makedirs(outdir, exist_ok=True)
    out = os.path.join(outdir, "fig%s.png" % fig)
    quantize(im, colours).save(out, optimize=True)
    record(project, fig, pdf, page, box, dpi, colours, out)
    print("%s fig%s: page %s -> %s (%dx%d, %d KB)"
          % (project, fig, page, os.path.relpath(out, ROOT), im.width, im.height,
             os.path.getsize(out) // 1024))
    return out


MANIFEST = os.path.join(ROOT, "tools", "figure_crops.json")


def record(project, fig, pdf, page, box, dpi, colours, out):
    """Write down which page and which box this image came from.

    Thirty figures on this site were cut wrong and every one of them was invisible
    afterwards, because the crop is trimmed back to its own ink and a box that stopped early
    yields a tidy picture of part of a figure. Nothing could tell the difference, because
    nothing knew where the picture was supposed to have come from: the coordinates lived in
    one shell command and were gone the moment it finished.

    With the box on record, check_figure_crops.py can re-cut the figure and compare, so a
    crop that drifts or a source PDF that is replaced stops being a thing only a person
    reading the page can notice. An entry is a claim about provenance, not about
    correctness -- a box that was wrong when it was used is still wrong here, which is why
    the checker reports coverage as well as drift.
    """
    import hashlib
    import json as _json
    try:
        man = _json.load(io.open(MANIFEST, encoding="utf-8"))
    except (IOError, OSError, ValueError):
        man = {}
    man.setdefault(project, {})[str(fig)] = {
        "pdf": os.path.relpath(pdf, ROOT).replace("\\", "/"),
        # The source's own hash and the backend that drew it. Both belong here because a
        # re-cut is only reproducible against the same bytes through the same renderer, and
        # the renderer has already changed what a figure shows once.
        "pdf_sha256": hashlib.sha256(io.open(pdf, "rb").read()).hexdigest(),
        "renderer": LAST_RENDERER,
        "page": int(page),
        "box": [round(float(v), 4) for v in box],
        "dpi": int(dpi),
        "colours": int(colours),
        "width": Image.open(out).width,
        "height": Image.open(out).height,
        "sha256": hashlib.sha256(io.open(out, "rb").read()).hexdigest(),
    }
    # Sorted and indented so a re-extraction produces a reviewable one-figure diff rather
    # than a reordered file.
    io.open(MANIFEST, "w", encoding="utf-8", newline="").write(
        _json.dumps(man, indent=1, sort_keys=True, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    argv = sys.argv[1:]
    dpi, pdf = 200, None
    for i, a in enumerate(argv):
        if a.startswith("--dpi"):
            dpi = int(a.split("=", 1)[1] if "=" in a else argv[i + 1])
        elif a.startswith("--pdf"):
            pdf = a.split("=", 1)[1] if "=" in a else argv[i + 1]
    skip = set()
    for i, a in enumerate(argv):
        if a.startswith("--"):
            skip.add(i)
            if "=" not in a:
                skip.add(i + 1)
    args = [a for i, a in enumerate(argv) if i not in skip]
    project, fig, page = args[0], args[1], int(args[2])
    box = tuple(float(v) for v in args[3:7])
    extract(project, fig, page, box, dpi=dpi, pdf=pdf)
