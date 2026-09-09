"""Assert every derived number in harmonised_field_descriptions.json against the built table.

Why this exists. That file is hand-written analytical prose with measured numbers embedded in
it: coverage counts, percentages, literature counts, ranges, the size of a trap. Prose cannot be
generated, so the numbers were typed beside something that regenerates, and they went four
releases stale without a single gate noticing. Every "Present on N rows (P%)" line in it was
measured against the 49,669-row table of 1.1.1 and survived 1.2.0, 1.2.1, 1.3.0 and 2.0.0
untouched. Two had become false in substance rather than merely out of date: effect and se
claimed to be present on every row, after 218 class rows were admitted on the alternative scale
alone.

So the numbers stay in the prose, where a reader needs them, and this asserts them. A claim is a
regex that locates the number plus a function that recomputes it from the published table. If
they disagree the build fails and prints both, which is the point: the next release cannot
quietly invalidate a sentence in the dictionary that feeds api/v1/datapackage.json.

    python data_layer/99_fielddict.py            # report
    python data_layer/99_fielddict.py --check    # exit 1 on any drift

Adding a claim is one entry in CHECKS. A number NOT covered here is not guarded, so the report
prints how many are asserted; keep that honest rather than impressive.
"""
import json, os, re, sys
import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
SITE = os.path.dirname(HERE)
FD = os.path.join(HERE, "harmonised_field_descriptions.json")
TAB = os.path.join(SITE, "data", "v1", "estimates_harmonised.parquet")

d = pd.read_parquet(TAB)
N = len(d)
NLIT = d["dataset"].nunique()


def f(n):
    return "{:,}".format(int(n))


def pct(n, tot=None):
    return "{:.1f}".format(round(100.0 * n / (tot if tot else N), 1))


def cov(col):
    return int(d[col].notna().sum())


def lits(col):
    return int(d.loc[d[col].notna(), "dataset"].nunique())


def sub(ds):
    return d[d["dataset"] == ds]


def _pairs():
    return d.groupby(["dataset", "study_id"]).ngroups


def _shared_sid():
    g = d.groupby("study_id")["dataset"].nunique()
    return int((g > 1).sum())


def _sid1():
    s = d[d["study_id"] == 1]
    return int(s["dataset"].nunique()), len(s)


def _collapsed():
    return int(round(100.0 * (1 - d["study_id"].nunique() / float(_pairs()))))


def _shared_labels():
    g = d.loc[d["study_label"].notna()].groupby("study_label")["dataset"].nunique()
    return int((g > 1).sum())


def _derived_true():
    return int((d["se_is_derived"] == True).sum())  # noqa: E712  bool column, not truthiness


# (field, regex with one capture group per asserted number, function returning those numbers
#  already formatted the way the prose writes them)
CHECKS = [
    ("dataset", r"(\d+) slugs are not", lambda: (str(NLIT),)),
    ("dataset", r"only the ([\d,]+) estimates", lambda: (f(len(sub("trust"))),)),
    ("dataset", r"forward ([\d,]+) down to climate (\d+)",
     lambda: (f(len(sub("forward"))), f(len(sub("climate"))))),

    ("study_id", r"There are ([\d,]+) distinct values but ([\d,]+) real",
     lambda: (f(d["study_id"].nunique()), f(_pairs()))),
    ("study_id", r"and (\d+) of the [\d,]+ values occur in more than one",
     lambda: (f(_shared_sid()),)),
    ("study_id", r"study_id 1 alone spans (\d+) datasets and (\d+) rows",
     lambda: tuple(f(x) for x in _sid1())),
    ("study_id", r"collapses (\d+)% of clusters", lambda: (str(_collapsed()),)),

    ("study_label", r"Null on ([\d.]+)% of rows",
     lambda: (pct(N - cov("study_label")),)),
    ("study_label", r"and (\d+) label strings appear in more than one dataset",
     lambda: (f(_shared_labels()),)),

    ("effect", r"Present on ([\d,]+) of the ([\d,]+) rows",
     lambda: (f(cov("effect")), f(N))),

    ("se", r"on ([\d,]+) rows and reconstructed on ([\d,]+) \(([\d.]+)%\)",
     lambda: (f(cov("se") - _derived_true()), f(_derived_true()), pct(_derived_true()))),

    ("se_is_derived", r"True on ([\d,]+) rows \(([\d.]+)%\)",
     lambda: (f(_derived_true()), pct(_derived_true()))),

    ("pub_year",
     r"Populated on ([\d,]+) of ([\d,]+) rows \(([\d.]+)%\) from (\d+) of the 42 literatures, "
     r"spanning (\d+)",
     lambda: (f(cov("pub_year")), f(N), pct(cov("pub_year")), str(lits("pub_year")),
              str(int(d["pub_year"].min())))),

    ("citations", r"Present on ([\d,]+) rows \(([\d.]+)%\) from (\d+) literatures",
     lambda: (f(cov("citations")), pct(cov("citations")), str(lits("citations")))),

    ("impact_factor", r"Present on ([\d,]+) rows \(([\d.]+)%\) from (\d+) literatures",
     lambda: (f(cov("impact_factor")), pct(cov("impact_factor")),
              str(lits("impact_factor")))),
    ("impact_factor", r"([\d,]+) values are exactly 0",
     lambda: (f((d["impact_factor"] == 0).sum()),)),

    ("published", r"Present on ([\d,]+) rows \(([\d.]+)%\) from just (\d+) of the 42",
     lambda: (f(cov("published")), pct(cov("published")), str(lits("published")))),
    ("published", r"activism \(([\d,]+) rows\) and size \(([\d,]+) rows\)",
     lambda: (f(sub("activism")["published"].notna().sum()),
              f(sub("size")["published"].notna().sum()))),

    ("top_journal", r"Present on ([\d,]+) rows \(([\d.]+)%\) from only (\d+) literatures",
     lambda: (f(cov("top_journal")), pct(cov("top_journal")), str(lits("top_journal")))),

    ("country",
     r"Present on ([\d,]+) rows \(([\d.]+)%\) from (\d+) literatures as (\d+) distinct strings",
     lambda: (f(cov("country")), pct(cov("country")), str(lits("country")),
              str(d["country"].nunique()))),

    ("country_id",
     r"Present on ([\d,]+) rows \(([\d.]+)%\) from (\d+) literatures, running (\d+) to (\d+)",
     lambda: (f(cov("country_id")), pct(cov("country_id")), str(lits("country_id")),
              str(int(d["country_id"].min())), str(int(d["country_id"].max())))),

    ("is_usa",
     r"Present on ([\d,]+) rows \(([\d.]+)%\) from (\d+) literatures, of which ([\d,]+) are 1s",
     lambda: (f(cov("is_usa")), pct(cov("is_usa")), str(lits("is_usa")),
              f((d["is_usa"] == 1).sum()))),

    ("data_start", r"Present on ([\d,]+) rows \(([\d.]+)%\) from (\d+) literatures",
     lambda: (f(cov("data_start")), pct(cov("data_start")), str(lits("data_start")))),

    ("data_midyear", r"Present on ([\d,]+) rows \(([\d.]+)%\)",
     lambda: (f(cov("data_midyear")), pct(cov("data_midyear")))),

    ("n_obs", r"the ([\d.]+)% headline", lambda: (pct(cov("n_obs")),)),

    ("t_stat", r"exact on all ([\d,]+) rows", lambda: (f(cov("t_stat")),)),

    ("horizon",
     r"house_prices \(([\d,]+) rows\) and price_puzzle \(([\d,]+)\), and null for the other (\d+)",
     lambda: (f(sub("house_prices")["horizon"].notna().sum()),
              f(sub("price_puzzle")["horizon"].notna().sum()),
              str(NLIT - lits("horizon")))),

    ("is_panel", r"Only (\d+) of 42 literatures populate it \(([\d,]+) rows, ([\d.]+)%",
     lambda: (str(lits("is_panel")), f(cov("is_panel")), pct(cov("is_panel")))),
    ("is_cross_section",
     r"Populated for (\d+) of 42 literatures \(([\d,]+) rows, ([\d.]+)%",
     lambda: (str(lits("is_cross_section")), f(cov("is_cross_section")),
              pct(cov("is_cross_section")))),
    ("is_time_series",
     r"only (\d+) of 42 literatures carry it \(([\d,]+) rows, ([\d.]+)%",
     lambda: (str(lits("is_time_series")), f(cov("is_time_series")),
              pct(cov("is_time_series")))),

    ("freq_annual", r"Filled for (\d+) of 42 literatures \(([\d,]+) rows, ([\d.]+)%",
     lambda: (str(lits("freq_annual")), f(cov("freq_annual")), pct(cov("freq_annual")))),
    ("freq_quarterly", r"Present in (\d+) of 42 literatures \(([\d,]+) rows, ([\d.]+)%",
     lambda: (str(lits("freq_quarterly")), f(cov("freq_quarterly")),
              pct(cov("freq_quarterly")))),
    ("freq_monthly", r"(\d+) of 42 literatures, ([\d,]+) rows \(([\d.]+)%",
     lambda: (str(lits("freq_monthly")), f(cov("freq_monthly")), pct(cov("freq_monthly")))),
    ("freq_monthly",
     r"([\d,]+) rows have freq_monthly, ([\d,]+) have freq_annual, and only ([\d,]+) have all three",
     lambda: (f(cov("freq_monthly")), f(cov("freq_annual")),
              f((d["freq_monthly"].notna() & d["freq_annual"].notna()
                 & d["freq_quarterly"].notna()).sum()))),

    ("method_ols", r"filled for (\d+) of 42 literatures \(([\d,]+) rows, ([\d.]+)%",
     lambda: (str(lits("method_ols")), f(cov("method_ols")), pct(cov("method_ols")))),
    ("method_iv", r"Filled for (\d+) of 42 literatures \(([\d,]+) rows, ([\d.]+)%",
     lambda: (str(lits("method_iv")), f(cov("method_iv")), pct(cov("method_iv")))),
    ("method_gmm", r"filled for (\d+) of 42 literatures, ([\d,]+) rows \(([\d.]+)%",
     lambda: (str(lits("method_gmm")), f(cov("method_gmm")), pct(cov("method_gmm")))),
    ("method_ml", r"Filled for (\d+) of 42 literatures, ([\d,]+) rows \(([\d.]+)%",
     lambda: (str(lits("method_ml")), f(cov("method_ml")), pct(cov("method_ml")))),
    ("method_fe", r"(\d+) of 42 literatures, ([\d,]+) rows \(([\d.]+)%",
     lambda: (str(lits("method_fe")), f(cov("method_fe")), pct(cov("method_fe")))),

    ("is_europe",
     r"([\d,]+) rows \(([\d.]+)%\) from (\d+) literatures, and only ([\d,]+) of those are 1s",
     lambda: (f(cov("is_europe")), pct(cov("is_europe")), str(lits("is_europe")),
              f((d["is_europe"] == 1).sum()))),
    ("is_europe", r"but no is_europe \(([\d,]+) rows\)",
     lambda: (f((d["is_usa"].notna() & d["is_europe"].isna()).sum()),)),
]


def run(check=False):
    fd = json.load(open(FD, encoding="utf-8"))
    stale, checked, unmatched = [], 0, []
    for field, pat, fn in CHECKS:
        txt = fd.get(field)
        if not isinstance(txt, str):
            unmatched.append("%s: no such field in the dictionary" % field)
            continue
        m = re.search(pat, txt)
        if not m:
            unmatched.append("%s: claim pattern found nothing -- %s" % (field, pat))
            continue
        want, got = tuple(fn()), m.groups()
        checked += len(want)
        if got != want:
            stale.append((field, got, want, m.group(0)))
    for line in unmatched:
        print("  UNMATCHED  %s" % line)
    for field, got, want, ctx in stale:
        print("  STALE      %-14s prose says %s, the table says %s" % (field, got, want))
        print("             ...%s..." % ctx[:104])
    print("field dictionary: %d numbers asserted over %d claims, %d stale, %d unmatched"
          % (checked, len(CHECKS), len(stale), len(unmatched)))
    if check and (stale or unmatched):
        print("FAIL: the field dictionary disagrees with the built table.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(run("--check" in sys.argv))
