# Replace the headline-results block in site/index.html with the freshly built
# fragment. Written as a checked tool because hand-editing this block broke the
# homepage twice: a naive regex stopped at the FIRST </div> (the .entry close),
# so #content closed early and the sidebar escaped the page box.
#
# Guarantees, all asserted before anything is written:
#   1. the replaced region is located by DIV DEPTH COUNTING, not by regex
#   2. <div> and </div> counts stay equal
#   3. the block still sits INSIDE #content (depth from #content stays > 0)
#   4. #content still closes before #sidebar opens
import io, os, re, sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IDX = os.path.join(BASE, "site", "index.html")
FRAG = os.path.join(BASE, "tools_seo", "estimates_draft.html")

HEAD_RE = re.compile(r'<h2 class="title"[^>]*>Headline (?:estimates|results) from these papers</h2>')
TAG_RE = re.compile(r"</?div\b", re.I)


def find_block(s):
    """Return (start, end) of the <div class="post..."> ... </div> holding the heading."""
    m = HEAD_RE.search(s)
    if not m:
        return None
    start = s.rindex('<div class="post', 0, m.start())
    depth, i = 0, start
    for t in TAG_RE.finditer(s, start):
        depth += 1 if t.group(0).lower() == "<div" else -1
        if depth == 0:
            return start, s.index(">", t.end()) + 1
    raise SystemExit("unbalanced divs around the estimates block")


def depth_at(s, pos, frm=0):
    seg = s[frm:pos]
    return seg.count("<div") - seg.count("</div>")


def main():
    s = io.open(IDX, encoding="utf-8", newline="").read()
    frag = io.open(FRAG, encoding="utf-8", newline="").read().strip()
    block = '\t\t<div class="post estimates">\n' + \
            "\n".join("\t\t" + ln if ln.strip() else ln for ln in frag.split("\n")) + \
            "\n\t\t</div>\n"

    span = find_block(s)
    if span:
        new = s[:span[0] - 2] + block + s[span[1] + 1:]   # -2/+1 eats the leading tabs / trailing NL
    else:                                                  # first insertion: before #content's close
        ic = s.index('id="content"')
        depth, close = 0, None
        for t in TAG_RE.finditer(s, ic):
            depth += 1 if t.group(0).lower() == "<div" else -1
            if depth == 0:
                close = t.start()
                break
        if close is None:
            raise SystemExit("could not locate the close of #content")
        new = s[:close] + block + s[close:]

    # --- assertions (fail closed) -------------------------------------------
    o, c = new.count("<div"), new.count("</div>")
    assert o == c, f"div imbalance after injection: {o} open / {c} close"
    h = HEAD_RE.search(new)
    assert h, "heading vanished"
    ic = new.index('id="content"')
    assert depth_at(new, h.start(), ic) > 0, "block is NOT inside #content"
    isb = new.index('id="sidebar"')
    assert depth_at(new, isb, ic) <= 0, "#content does not close before #sidebar"
    assert new.index('id="content"') < h.start() < isb, "block landed after the sidebar"

    if new != s:
        io.open(IDX, "w", encoding="utf-8", newline="").write(new)
        print(f"injected: {len(block)} chars, divs balanced ({o}), inside #content, sidebar intact")
    else:
        print("no change")


if __name__ == "__main__":
    main()
