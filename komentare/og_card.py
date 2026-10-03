"""A typographic card for link previews: the title on the site's paper colour, no photographs.

    python komentare/og_card.py <out.png> "<title>" "<byline and date>"

1200x675 (16:9, what Discover and most link previews crop to), in the colours of style.css and
in Palatino, the face its serif stack falls back to on Windows. First used for the gymnasium
article (3 Oct 2026).
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 675
BG, TEXT, MUTED, RULE, ACCENT = "#fbfaf8", "#1b1a18", "#6a6660", "#d8d3cb", "#8c2f27"
FONTS = Path("C:/Windows/Fonts")


def font(name, size):
    return ImageFont.truetype(str(FONTS / name), size)


def wrap(draw, text, f, width):
    # one-letter words stay with the next word, as in Czech typesetting
    words = text.replace(" v ", " v\u00a0").replace(" a ", " a\u00a0").split(" ")
    lines, cur = [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        if draw.textlength(trial.replace("\u00a0", " "), font=f) <= width:
            cur = trial
        else:
            lines.append(cur)
            cur = w
    lines.append(cur)
    return [l.replace("\u00a0", " ") for l in lines]


def card(out, title, byline):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 14, H], fill=ACCENT)
    d.text((90, 70), "Komentáře · meta-analysis.cz", font=font("pala.ttf", 30), fill=MUTED)
    size = 68
    while True:
        f = font("palab.ttf", size)
        lines = wrap(d, title, f, W - 180)
        if len(lines) <= 4 or size <= 44:
            break
        size -= 4
    y = 160
    for line in lines:
        d.text((90, y), line, font=f, fill=TEXT)
        y += int(size * 1.22)
    d.line([90, H - 130, W - 90, H - 130], fill=RULE, width=2)
    d.text((90, H - 105), byline, font=font("pala.ttf", 32), fill=MUTED)
    img.save(out, optimize=True)


if __name__ == "__main__":
    card(sys.argv[1], sys.argv[2], sys.argv[3])
    print("wrote", sys.argv[1])
