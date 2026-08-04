"""Read every paper's OWN replication code and check it names the columns we chose.

This is the blind audit done mechanically. Six agents spent ~80k tokens each doing by hand
what is really a text-extraction job: find the paper's headline meta-analysis regression,
read off the two variables it regresses, and compare them with the pair we ship. One script
covers all 39 literatures for a fraction of one agent.

The pattern that made this worth automating: a meta-analysis regression is almost always
    <cmd> <effect> <se> [, options]
in Stata -- ivreg2/regress/xtreg for FAT-PET, metan/metareg for the pooled estimate. So the
first two tokens after the command ARE the effect/SE pair the paper analyses.

The one complication, found in every literature audited so far, is winsorising: papers run on
`armel_w`/`se_w` or `sigma_win5`/`se_win5`, built in code from the raw columns. So a match on
the stem counts as a match, and is reported distinctly -- it is the normal case, not an error.

Verdicts:
  MATCH        the code regresses exactly our pair
  WINSORISED   the code regresses a winsorised/transformed copy of our pair (stem matches)
  UNRELATED    the code's headline pair shares no stem with ours -- LOOK AT THIS
  NO CODE      no replication code shipped; nothing to check here
"""
import os, sys, io, re, json, zipfile, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _paths import WORK, SITE
import pandas as pd

OUT = os.path.join(WORK, "out")
if not os.path.isdir(OUT):
    OUT = SITE
H = pd.read_parquet(os.path.join(OUT, "data", "v1", "estimates_harmonised.parquet"))
API = json.load(open(os.path.join(OUT, "api", "v1", "datasets.json"), encoding="utf-8"))
STATUS = {d["id"]: d.get("audit_status", "?") for d in API["datasets"]}

CODE_EXT = (".do", ".r", ".py", ".ado")
# Stata commands whose first two arguments are the effect and its standard error.
CMD = re.compile(
    r"^\s*(?:eststo\s*:\s*|quietly\s+|qui\s+|noisily\s+|capture\s+)*"
    r"(ivreg2|regress|reg|areg|xtreg|vwls|metan|metareg|wls0|rreg|meta\s+set)\s+"
    r"([A-Za-z_][A-Za-z0-9_]*)\s+([A-Za-z_][A-Za-z0-9_]*)", re.I)
# R equivalents. Some packages ship R rather than Stata (migrant), and a Stata-only pattern
# reports "no regression found" for them, which reads as missing code rather than as a gap in
# this script. metafor's rma() names the pair through arguments, not position.
R_CMD = [
    re.compile(r"\brma(?:\.uni|\.mv)?\s*\(\s*yi\s*=\s*([A-Za-z_.][\w.]*)[^)]*?\bsei\s*=\s*([A-Za-z_.][\w.]*)", re.I),
    re.compile(r"\brma(?:\.uni|\.mv)?\s*\(\s*([A-Za-z_.][\w.]*)\s*,\s*sei\s*=\s*([A-Za-z_.][\w.]*)", re.I),
    re.compile(r"\b(?:lm|glm|ivreg|felm|lm_robust|rlm)\s*\(\s*([A-Za-z_.][\w.]*)\s*~\s*([A-Za-z_.][\w.]*)", re.I),
    re.compile(r"\bmetagen\s*\(\s*(?:TE\s*=\s*)?([A-Za-z_.][\w.]*)\s*,\s*(?:seTE\s*=\s*)?([A-Za-z_.][\w.]*)", re.I),
]
# suffixes papers append when they transform a column in code
SUF = re.compile(r"(_w|_win\d*|_wins?|_w\d+|_trim\d*|_sd|_alt|_c)$", re.I)


def stem(v):
    s = str(v).lower()
    for _ in range(3):
        s2 = SUF.sub("", s)
        if s2 == s:
            break
        s = s2
    return s


def code_texts(proj):
    """Every replication script for this literature, loose or zipped."""
    out, folder = [], os.path.join(SITE, proj)
    if not os.path.isdir(folder):
        return out
    for f in sorted(os.listdir(folder)):
        full = os.path.join(folder, f)
        if f.lower().endswith(CODE_EXT):
            try:
                out.append((f, open(full, "rb").read().decode("utf-8", "replace")))
            except Exception:
                pass
        elif f.lower().endswith(".zip"):
            try:
                z = zipfile.ZipFile(full)
                for m in z.namelist():
                    if m.lower().endswith(CODE_EXT) and not m.endswith("/"):
                        try:
                            out.append((f"{f}:{m}", z.read(m).decode("utf-8", "replace")))
                        except Exception:
                            pass
            except Exception:
                pass
    return out


def headline_pairs(texts):
    """(effect, se, where) for every meta-analysis regression found, in file order."""
    hits = []
    for name, txt in texts:
        for ln, line in enumerate(txt.splitlines(), 1):
            line = line.split("//")[0].split("*", 1)[0] if line.lstrip().startswith("*") else line.split("//")[0]
            line = re.sub(r"\[[^\]]*\]", " ", line)      # drop [pweight=...]
            line = re.split(r"\s+if\s+|,", line)[0]      # drop `if` conditions and options
            m = CMD.match(line)
            if m:
                hits.append((m.group(2), m.group(3), f"{name}:{ln}"))
                continue
            if name.lower().endswith((".r", ".rmd")) or ".r:" in name.lower():
                for rx in R_CMD:
                    rm = rx.search(line)
                    if rm:
                        hits.append((rm.group(1), rm.group(2), f"{name}:{ln}"))
                        break
    return hits


# Cases already run to ground by hand. Kept here so a re-run reports RESOLVED rather than
# re-raising them: this script cannot follow a variable BUILT earlier in the script, and most
# apparent mismatches are exactly that. Delete an entry only if the underlying mapping changes.
RESOLVED = {
 "competition":  "same pair, different spacing: our column is literally named 'SE PCC', the code's is SEPCC",
 "eis":          "code runs the WLS form of FAT-PET (t on precision), algebraically the same test as eis on se",
 "price_puzzle": "code runs the WLS form (t on prec) on the long form; 90_roundtrip re-derives the wide->long reshape",
 "skill":        "code runs the WLS form on winsorised copies (tstat_coefficient_w on precision_coefficient_w)",
 "forward":      "code renames the pair before regressing (bs/constant), the endogenous-kink idiom",
 "reforms":      "code builds the partial correlation from lib and df; we run the identical pcc_from_t path",
 "house_prices": "house.do sets SE=(SE_l+SE_u)/2, which is exactly our se_mean_of; seraw covers 40 of 1785 rows",
 "frisch":       "code regresses se_comb = se, falling back to study_se; the paper imputes the rest by bootstrap, "
                 "which the published file does not carry, so se alone is the reproducible subset",
 "size":         "se_calc reproduces the file's own tstat on 100% of rows, se on 96.7%; we take the internally "
                 "consistent column even though the paper's regression names se",
 "activism":     "lm(Y~x-1) at activism.R:1121 is inside a generic BMA helper -- Y and x are that "
                 "function's local matrices, not the meta-regression. A false positive of the R patterns.",
 "electricity":  "electricity.R:907 defines fat_pet_battery <- function(effect, se, ...) and line 910 runs "
                 "lm(e ~ s) on its local copies, so the pair regressed IS effect/se. Confirms our mapping.",
 "remittances":  "REAL, staged in overrides.pending_1_0_0: code builds PCC from TSTAT_L and DF; we ship COEF_L/SE_L",
}

rows = []
for proj in sorted(H["dataset"].unique()):
    g = H[H["dataset"] == proj]
    eff, se = str(g["effect_col"].iloc[0]), str(g["se_col"].iloc[0])
    texts = code_texts(proj)
    if not texts:
        rows.append((proj, STATUS.get(proj, "?"), f"{eff}/{se}", "NO CODE", "", "")); continue
    hits = headline_pairs(texts)
    if not hits:
        rows.append((proj, STATUS.get(proj, "?"), f"{eff}/{se}", "NO REGRESSION", "",
                     f"{len(texts)} script(s), no recognised command")); continue

    exact = [h for h in hits if h[0].lower() == eff.lower() and h[1].lower() == se.lower()]
    winsy = [h for h in hits if stem(h[0]) == stem(eff) and stem(h[1]) == stem(se)]
    if exact:
        v, ev = "MATCH", exact[0][2]
    elif winsy:
        v, ev = "WINSORISED", f"{winsy[0][0]}/{winsy[0][1]} @ {winsy[0][2]}"
    else:
        # what DOES it regress? report the most common pair, that is the headline one
        from collections import Counter
        top = Counter((a, b) for a, b, _ in hits).most_common(1)[0]
        where = next(h[2] for h in hits if (h[0], h[1]) == top[0])
        v, ev = "UNRELATED", f"{top[0][0]}/{top[0][1]} x{top[1]} @ {where}"
        if proj in RESOLVED:
            v, ev = "RESOLVED", RESOLVED[proj]
    rows.append((proj, STATUS.get(proj, "?"), f"{eff}/{se}", v, ev, f"{len(hits)} regressions"))

print("%-16s %-22s %-26s %-11s %s" % ("literature", "audit_status", "ours", "verdict", "code says"))
for p, st, pair, v, ev, n in rows:
    print("%-16s %-22s %-26s %-11s %s" % (p, st, pair[:26], v, ev[:110]))

from collections import Counter
tally = Counter(r[3] for r in rows)
print("\n" + " | ".join(f"{k}: {v}" for k, v in tally.most_common()))
bad = [r for r in rows if r[3] == "UNRELATED"]
# A RESOLVED note that stops firing means the mapping moved under it. That is the failure
# mode of any hand-maintained exception list: it silently starts excusing something else.
stale = [k for k in RESOLVED if k not in {r[0] for r in rows if r[3] == "RESOLVED"}]
if stale:
    print(f"\nNOTE: {len(stale)} RESOLVED entr(ies) no longer fire - the mapping may have "
          f"changed, so re-check or delete: {', '.join(sorted(stale))}")
if bad:
    print(f"\n{len(bad)} to look at -- the code's headline pair shares no stem with ours:")
    for r in bad:
        print(f"  ? {r[0]:<16} ours={r[2]:<24} code={r[4]}")
print("\n(UNRELATED is a prompt to look, not a verdict: a paper may regress a transformed\n"
      " variable built earlier in the script, which this cannot follow.)")

# Machine-readable side-output, so the evidence can be recorded into overrides.json without
# being retyped. Transcribing a file:line by hand is how a citation quietly stops matching
# the thing it cites.
json.dump({r[0]: {"verdict": r[3], "evidence": r[4], "ours": r[2]} for r in rows},
          open(os.path.join(WORK, "codegrep_evidence.json"), "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
