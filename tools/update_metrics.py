"""Refresh the stated RePEc ranks and Google Scholar citations from site-metrics (11 Oct 2026).

The numbers come from the private repo tjhavranek/site-metrics, whose collector runs on the
owner's PC on the 15th of each month and calls this script in a dedicated clone. Three spots are
rendered between sentinels: the RePEc sentence on /about/ and the "cited more than N times"
sentences on /about/ and /impact/. The wording is fixed by the owner; only the numbers move.

  python tools/update_metrics.py <metrics.json>   validate, store, render, regenerate; non-zero = fail
  python tools/update_metrics.py --check          the rendered spots must match tools/site_metrics.json

Only the fields used here are stored (tools/site_metrics.json): the site serves every file in
the repo, and the full collector output stays private. A citation floor that would go DOWN, a
status other than ok/repec_unchanged, or a claim the wording cannot carry fails closed.
"""
import json
import math
import os
import re
import subprocess
import sys

SITE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORE = os.path.join(SITE, "tools", "site_metrics.json")
PAGES = {"repec": ["about/index.html"], "citations": ["about/index.html", "impact/index.html"]}
MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August",
          "September", "October", "November", "December"]
WORDS = ["first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth",
         "tenth"]


def ordinal(n):
    n = int(n)
    if 1 <= n <= 10:
        return WORDS[n - 1]
    suffix = "th" if 10 <= n % 100 <= 20 else {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
    return f"{n}{suffix}"


def fail(msg):
    print(f"update_metrics: FAIL: {msg}")
    sys.exit(1)


def trim(full):
    """The fields the wording needs, validated; anything missing or off fails closed."""
    if full.get("status") not in ("ok", "repec_unchanged"):
        fail(f"status is {full.get('status')!r}, not ok or repec_unchanged")
    try:
        t, z = full["people"]["tomas"], full["people"]["zuzana"]
        out = {
            "generated_at": full["generated_at"],
            "repec_release": t["repec"]["release"],
            "th_czech10": int(t["repec"]["ranks"]["czech10"]),
            "th_top_percent": float(t["repec"]["top_percent"]),
            "th_cohort_year": int(t["repec"]["cohort"]["year"]),
            "th_cohort_rank": int(t["repec"]["cohort"]["rank"]),
            "zi_women10": int(z["repec"]["ranks"]["women10"]),
            "zi_cohort_year": int(z["repec"]["cohort"]["year"]),
            "zi_cohort_rank": int(z["repec"]["cohort"]["rank"]),
            "zi_highest_woman_cz": bool(z["repec"]["highest_woman_cz"]["value"]),
            "th_scholar_citations": int(t["scholar"]["citations"]),
            "th_scholar_as_of": t["scholar"]["as_of"],
            "sources": {"scholar": t["scholar"]["source"]},
        }
    except (KeyError, TypeError, ValueError) as e:
        fail(f"missing or malformed field: {e}")
    if not re.fullmatch(r"\d{4}-(0[1-9]|1[0-2])", out["repec_release"]):
        fail(f"repec release {out['repec_release']!r} is not YYYY-MM")
    if (out["th_cohort_year"], out["zi_cohort_year"]) != (2013, 2015):
        fail("cohort years differ from the PhD years the page states (2013, 2015)")
    if not out["zi_highest_woman_cz"]:
        fail("Irsova is no longer the highest-ranked woman in the Czech Republic; the wording needs the owner")
    if not 0 < out["th_top_percent"] <= 100:
        fail("top percent out of range")
    return out


def render(m):
    y, mo = m["repec_release"].split("-")
    th_cz = ("first among economists in the Czech Republic" if m["th_czech10"] == 1
             else f"{ordinal(m['th_czech10'])} among economists in the Czech Republic")
    top = m["th_top_percent"]
    top = str(int(top)) if top == int(top) else f"{math.ceil(top * 10) / 10:g}"
    repec = (f'In the <a href="https://ideas.repec.org/top/">RePEc rankings</a> of '
             f'{MONTHS[int(mo) - 1]} {y}, Havranek is\n{th_cz}, in the top {top}% worldwide over '
             f'the last ten\nyears, and {ordinal(m["th_cohort_rank"])} in the world among economists '
             f'who took their PhD in {m["th_cohort_year"]}. Irsova is {ordinal(m["zi_women10"])} among\n'
             f'women economists worldwide, {ordinal(m["zi_cohort_rank"])} in the world among all '
             f'economists who took their PhD in {m["zi_cohort_year"]}, and the highest-ranked\n'
             f'woman economist in the Czech Republic.')
    floor = m["th_scholar_citations"] // 1000 * 1000
    return {"repec": repec, "citations": f"cited more than {floor:,} times"}, floor


SPOT = re.compile(r"(<!-- metrics:(\w+):start -->)(.*?)(<!-- metrics:\2:end -->)", re.S)


def spots(text):
    return {m.group(2): m.group(3) for m in SPOT.finditer(text)}


def read(rel):
    return open(os.path.join(SITE, rel), "rb").read().decode("utf-8")


def check():
    if not os.path.isfile(STORE):
        fail("tools/site_metrics.json is missing")
    want, _ = render(trim_stored(json.load(open(STORE, encoding="utf-8"))))
    bad = []
    for key, rels in PAGES.items():
        for rel in rels:
            got = spots(read(rel).replace("\r\n", "\n")).get(key)
            if got is None:
                bad.append(f"{rel}: no metrics:{key} sentinels")
            elif got != want[key]:
                bad.append(f"{rel}: metrics:{key} differs from tools/site_metrics.json")
    if bad:
        for b in bad:
            print("  " + b)
        fail("run tools/update_metrics.py with the current metrics.json")
    print("update_metrics: the stated ranks and citations match tools/site_metrics.json")


def trim_stored(m):
    # the stored file is already trimmed; re-validate it in the same terms
    if not m.get("zi_highest_woman_cz"):
        fail("stored metrics say Irsova is not the highest-ranked woman in the Czech Republic")
    return m


def apply(path):
    m = trim(json.load(open(path, encoding="utf-8")))
    want, floor = render(m)
    for rel in PAGES["citations"]:
        old = re.search(r"cited more than ([\d,]+) times", spots(read(rel)).get("citations", ""))
        if old and floor < int(old.group(1).replace(",", "")):
            fail(f"the citation floor would drop from {old.group(1)} to {floor:,} on {rel}")
    for rel in sorted({r for rels in PAGES.values() for r in rels}):
        raw = read(rel)
        crlf = "\r\n" in raw
        s = raw.replace("\r\n", "\n")
        found = spots(s)
        for key, rels in PAGES.items():
            if rel in rels and key not in found:
                fail(f"{rel}: no metrics:{key} sentinels")
        s = SPOT.sub(lambda mt: mt.group(1) + want[mt.group(2)] + mt.group(4)
                     if mt.group(2) in want else mt.group(0), s)
        if s != raw.replace("\r\n", "\n"):
            open(os.path.join(SITE, rel), "wb").write(
                (s.replace("\n", "\r\n") if crlf else s).encode("utf-8"))
            print("rendered", rel)
    new = json.dumps(m, indent=1, ensure_ascii=False) + "\n"
    if not os.path.isfile(STORE) or open(STORE, encoding="utf-8").read() != new:
        open(STORE, "w", encoding="utf-8", newline="\n").write(new)
    # the pages changed, so the derived files must follow (CI checks both)
    for tool in ("tools/generate_seo.py", "tools/build_search_index.py"):
        r = subprocess.run([sys.executable, os.path.join(SITE, tool)], cwd=SITE,
                           capture_output=True, text=True, encoding="utf-8", errors="replace")
        if r.returncode:
            print(r.stdout[-2000:], r.stderr[-2000:])
            fail(f"{tool} failed")
    print(f"update_metrics: RePEc {m['repec_release']}, Scholar {m['th_scholar_citations']:,} "
          f"-> more than {floor:,}; done")


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--check":
        check()
    elif len(sys.argv) == 2:
        apply(sys.argv[1])
    else:
        print(__doc__)
        sys.exit(2)
