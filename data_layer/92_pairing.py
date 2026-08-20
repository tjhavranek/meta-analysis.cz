"""How DECISIVE was each literature's effect/standard-error pairing?

Round-trip (90_) proves the values are real: they occur in the published file. It cannot
prove they are the RIGHT values. Read the wrong two columns and the pairs still occur in
the source, so the strongest check passes while the table means something else entirely.
That is the live risk for the 19 literatures whose mapping rests on arithmetic alone.

This re-derives the pairing from scratch and asks a harder question than "does it work?":

    was the chosen pair the UNIQUE pair that works, and by how much did it win?

For every literature it finds the columns that look like a reported t-statistic, then tests
EVERY ordered pair of numeric columns (A, B) for how often A/B reproduces one. The chosen
pair should rank first. What matters is the MARGIN over the runner-up: a pair that wins
0.99 to 0.12 is settled, a pair that wins 0.99 to 0.98 is a coin-flip between two columns
that happen to be near-collinear, and one that cannot be tested at all is an assumption.

Output is a triage list, not a pass/fail: it says which of the provisional literatures a
human should look at first. Exit 1 only if a chosen pairing is actually BEATEN.
"""
import os, sys, io, json, zipfile, re, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE
import numpy as np, pandas as pd

OUT = os.path.join(WORK, "out")
if not os.path.isdir(OUT):
    OUT = SITE
H = pd.read_parquet(os.path.join(OUT, "data", "v1", "estimates_harmonised.parquet"))
PRIM = json.load(open(os.path.join(WORK, "primaries.json"), encoding="utf-8"))
OVR = json.load(open(os.path.join(WORK, "overrides.json"), encoding="utf-8"))
REP = json.load(open(os.path.join(WORK, "harmonised_report.json"), encoding="utf-8"))
API = json.load(open(os.path.join(OUT, "api", "v1", "datasets.json"), encoding="utf-8"))
STATUS = {d["id"]: d.get("audit_status", "?") for d in API["datasets"]}

TPAT = re.compile(r"^\s*(t[\s_.-]*stat|t[\s_.-]*val|tstat|tval|t|abs[\s_.-]*t|t[\s_.-]*ratio)\s*$", re.I)
TOL = 0.01      # a t is "reproduced" within 1% relative
HIT = 0.90      # a pair "works" if it reproduces a reported t for 90% of usable rows


def read_source(proj):
    rec = PRIM[proj]
    folder = os.path.join(SITE, proj)
    if rec["source"] == "loose":
        src, name = os.path.join(folder, rec["member"]), rec["member"]
    else:
        z = zipfile.ZipFile(os.path.join(folder, rec["archive"]))
        src, name = io.BytesIO(z.read(rec["member"])), rec["member"]
    ext = os.path.splitext(name)[1].lower()
    if ext == ".dta":
        return pd.read_stata(src, convert_categoricals=False)
    if ext == ".csv":
        return pd.read_csv(src, low_memory=False)
    # primaries.json ALREADY records which sheet the inventory chose, and it was ignored
    # here. Falling back to the first sheet works only because every workbook until
    # finance_growth happened to put its data first; that one opens with a 12x2 'Contents'
    # cover sheet, so this read 12 rows, found no t-statistic, and reported the pairing as
    # untestable -- on the single literature whose audit status rests on that very test.
    sheet = ((OVR.get(proj) or {}).get("sheet")
             or REP["projects"][proj].get("sheet")
             or (PRIM.get(proj) or {}).get("sheet"))
    xl = pd.ExcelFile(src)
    if sheet and sheet in xl.sheet_names:
        return xl.parse(sheet)
    # No recorded sheet: take the widest one with data, as 90_roundtrip.py does, rather
    # than the first one, which may be a cover page.
    best = None
    for sh in xl.sheet_names:
        try: d = xl.parse(sh)
        except Exception: continue
        if best is None or d.shape[1] * max(len(d), 1) > best.shape[1] * max(len(best), 1):
            best = d
    return best if best is not None else xl.parse(xl.sheet_names[0])


def numeric(df):
    """Columns usable as a number, wide to float64, with enough data to judge."""
    cols = {}
    for c in df.columns:
        v = pd.to_numeric(df[c], errors="coerce").astype("float64")
        if v.notna().sum() >= max(10, 0.3 * len(df)):
            cols[str(c)] = v.values
    return cols


def looks_like_t(v):
    """A reported t-statistic, not a panel dimension or a counter.

    `^t$` also matches the T that sits beside N in a panel dataset -- the time dimension.
    That false positive made three literatures look as though their pairing failed, when
    what failed was the assumption that the column held a t at all. A real t-statistic is
    continuous and usually straddles zero; a T or an N is a small non-negative integer.
    """
    v = v[np.isfinite(v)]
    if v.size < 20 or np.unique(v).size < 20:
        return False
    frac = np.mean(np.abs(v - np.round(v)) > 1e-9)     # genuinely non-integer
    return bool(frac > 0.5 and np.max(np.abs(v)) > 1.0)


def usable_denominator(v):
    """A standard error, not a dummy. Dividing a t column by a 0/1 flag returns the t
    column, which scores a perfect 1.00 and means nothing."""
    u = np.unique(v[np.isfinite(v)])
    return u.size >= 10 and np.all(u[u != 0] != 0)


def score(a, b, t):
    """Fraction of rows where a/b reproduces t. Sign-blind: many files report |t|."""
    m = np.isfinite(a) & np.isfinite(b) & np.isfinite(t) & (np.abs(b) > 0) & (np.abs(t) > 1e-8)
    if m.sum() < 10:
        return 0.0, 0
    got = np.abs(a[m] / b[m])
    return float(np.mean(np.abs(got - np.abs(t[m])) <= TOL * np.abs(t[m]))), int(m.sum())


rows, beaten = [], []
for proj in sorted(H["dataset"].unique()):
    o = OVR.get(proj) or {}
    chosen_e = o.get("effect") or REP["projects"][proj].get("effect")
    chosen_s = o.get("se") or REP["projects"][proj].get("se")
    st = STATUS.get(proj, "?")

    # Only a plain two-column read is testable this way. Computed and reshaped effects
    # (reforms, activism, price_puzzle, house_prices) are covered by 90_roundtrip instead.
    if o.get("compute") or o.get("reshape_long") or o.get("se_mean_of") \
            or not isinstance(chosen_s, str) or chosen_s.startswith("derived:"):
        rows.append((proj, st, "n/a", None, None, "derived or reshaped - see 90_roundtrip"))
        continue
    try:
        df = read_source(proj)
        cols = numeric(df)
    except Exception as e:
        rows.append((proj, st, "err", None, None, str(e)[:40])); continue

    tcands = [c for c in cols if TPAT.match(c) and c not in (chosen_e, chosen_s)
              and looks_like_t(cols[c])]
    if not tcands:
        rows.append((proj, st, "NO t", None, None,
                     "no reported t-statistic - pairing cannot be tested arithmetically"))
        continue

    best = {}
    for tc in tcands:
        t = cols[tc]
        for a in cols:
            if a == tc:
                continue
            # a numerator that IS the t column (to rounding) reproduces it trivially
            if np.allclose(np.nan_to_num(cols[a]), np.nan_to_num(t), rtol=1e-6):
                continue
            for b in cols:
                if b in (a, tc) or not usable_denominator(cols[b]):
                    continue
                s, n = score(cols[a], cols[b], t)
                if s > best.get((a, b), (0, 0))[0]:
                    best[(a, b)] = (s, n)
    if not best:
        rows.append((proj, st, "NO t", None, None, "no testable pair")); continue

    ranked = sorted(best.items(), key=lambda kv: -kv[1][0])
    # If NOTHING in the file reproduces the candidate, the candidate is not a t-statistic
    # and the whole test is void here. Declaring a "winner" among pairs that all score ~0
    # would be reading noise -- that is what made `forward` look broken twice.
    if ranked[0][1][0] < HIT:
        rows.append((proj, st, "NO t", None, None,
                     f"candidate {'/'.join(tcands)} is reproduced by no pair "
                     f"(best {ranked[0][1][0]:.2f}) - not a t-statistic"))
        continue
    mine = best.get((chosen_e, chosen_s), (0.0, 0))[0]
    # A rival is only interesting if it uses a DIFFERENT effect or se column
    rival = next((f"{a}/{b}={s:.2f}" for (a, b), (s, _) in ranked
                  if (a, b) != (chosen_e, chosen_s) and s >= HIT), None)
    top = ranked[0][1][0]
    if top > mine + 1e-9 and ranked[0][0] != (chosen_e, chosen_s):
        beaten.append(f"{proj}: chose {chosen_e}/{chosen_s} ({mine:.2f}) but "
                      f"{ranked[0][0][0]}/{ranked[0][0][1]} scores {top:.2f}")
    rows.append((proj, st, f"{chosen_e}/{chosen_s}", mine, rival,
                 "unique" if not rival else "TIED with another pair"))

print("%-16s %-22s %-30s %6s  %s" % ("literature", "audit_status", "chosen pair", "score", "verdict"))
for p, st, pair, sc, rival, msg in rows:
    s = f"{sc:.2f}" if sc is not None else "  -"
    print("%-16s %-22s %-30s %6s  %s" % (p, st, pair[:30], s, msg if not rival else f"{msg} ({rival})"))

conf = [r for r in rows if r[3] is not None and r[3] >= HIT and not r[4]]
tied = [r for r in rows if r[4]]
untested = [r for r in rows if r[3] is None and r[2] in ("NO t", "n/a")]
prov_untested = [r for r in untested if r[1] == "arithmetic_pairing_only"]

print(f"\n{len(conf)} literatures: the chosen pair uniquely reproduces the reported t")
print(f"{len(tied)} literatures: another pair scores as well - near-collinear columns")
print(f"{len(untested)} literatures: not testable this way "
      f"({len(prov_untested)} of them provisional -> audit these first)")
if prov_untested:
    print("  priority for human review: " + ", ".join(r[0] for r in prov_untested))
if beaten:
    print(f"\n{len(beaten)} CHOSEN PAIRING BEATEN BY ANOTHER:")
    for b in beaten:
        print("  X " + b)
    sys.exit(1)
print("\nPAIRING PASS - no chosen pairing is beaten by an alternative")
