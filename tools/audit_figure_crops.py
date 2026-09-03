#!/usr/bin/env python3
"""Screen every figure image for the two ways a page crop goes wrong.

Deliberately NOT a proposal to re-render figures from the LaTeX sources' original artwork.
That artwork is usually a DRAFT's: house_prices' source plots 31 studies where the
published paper has 37. Swapping it in would put different data under a published caption,
which is far worse than a slightly soft image. The published PDF is the only safe origin,
and every figure already comes from it.

What can still be wrong is the box that was cut out of the page:

  furniture   the crop reached above the artwork and took in the journal's running head, an
              author line, or a section heading. Found by ink profile: a band of ink at the
              very top, then a clear gutter, then the artwork. Four were fixed this way in
              /forward/, /students/ and /trust/.

  truncated   the crop stopped inside the artwork, so an axis, a label or a whole panel is
              missing. Found by asking whether ink runs into the bottom edge with no margin
              under it, the signature of /incentives/ figures 2 and 5 and /lags/ figure 1.

Both are reported as candidates. Look at the image before acting.

How noisy this is, measured, so nobody trusts it more than it deserves
---------------------------------------------------------------------
On the 455 images it flags about 105 for furniture and 21 for truncation, and MOST of both
are false. A multi-panel plot opens with its panel titles ("Euro Area GDP => Czech GDP"),
which is a band of ink over a gutter and reads exactly like a running head; /transmission/
alone contributes fifteen of those, all correct as they stand. Truncation fires whenever
the crop sits tight around the x-axis label, which is normal: /maive/ figure 1 is flagged
and is complete.

So this is a shortlist to look through, never a list to act on. The figures that really
were wrong -- /incentives/ 2 and 5 cut above their own axes, /lags/ 1 cut below -1.5,
/learning/ 8 missing a whole panel -- were caught by reading each caption against the PDF
and asking whether the picture shows what the caption claims. That is a semantic check and
an ink profile cannot stand in for it.
"""

import glob
import os
import sys

from PIL import Image


def profile(im, step=3):
    g = im.convert("L")
    w, h = g.size
    px = g.load()
    out = []
    for y in range(h):
        n = 0
        for x in range(0, w, step):
            if px[x, y] < 205:
                n += 1
        out.append(n / max(1.0, w / step))
    return out


def main(argv):
    only = argv[1] if len(argv) > 1 else None
    files = sorted(glob.glob(os.path.join("*", "paper", "figures", "*.png")) +
                   glob.glob(os.path.join("*", "supplement", "figures", "*.png")))
    furn = trunc = 0
    for f in files:
        proj = f.split(os.sep)[0]
        if only and proj != only:
            continue
        try:
            im = Image.open(f)
        except Exception:
            continue
        w, h = im.size
        if h < 80:
            continue
        ink = profile(im)
        top = int(h * 0.18)

        # furniture: ink, then a gutter of at least 2% of the height, inside the top 18%
        y = 0
        while y < top and ink[y] < 0.004:
            y += 1
        band_start = y
        while y < top and ink[y] >= 0.004:
            y += 1
        band_end = y
        gap = y
        while y < top and ink[y] < 0.004:
            y += 1
        if band_end > band_start and (y - gap) >= max(6, h * 0.02) and y < top:
            furn += 1
            print("  furniture  %-46s band rows %d-%d, gutter to %d (h=%d)"
                  % (f, band_start, band_end, y, h))

        # truncated: the last 1.5% of rows still carry ink, i.e. no bottom margin at all
        tail = max(3, int(h * 0.015))
        if min(ink[-tail:]) > 0.004:
            trunc += 1
            print("  truncated  %-46s ink reaches the bottom edge (h=%d)" % (f, h))
    print("\n%d with suspected page furniture, %d suspected truncation, of %d image(s)."
          % (furn, trunc, len(files)))
    print("Candidates only. Open the image before changing anything.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
