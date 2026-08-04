# FABLE_FINDINGS — independent audit of estimates_harmonised (0.9.0-beta)

All numbers below were computed from the shipped parquet
(`data/v1/estimates_harmonised.parquet`, 54,076 x 41) and the per-dataset
parquets; scripts run in this directory.

## Defects found

### D1 (critical). price_puzzle is duplicated exactly 7-fold: 6,360 spurious rows, 11.8% of the pooled table
The source `puzzle.xls` is ALREADY LONG: 217 underlying estimates x 7 rows
(source `horizon` in {3,6,12,18,36,88,99}), with the wide `M{h}R`/`SE{h}`
columns CONSTANT within each (idstudy, idest) — verified:
`groupby(['idstudy','idest'])['M3R'].nunique() <= 1` on all 217 groups, 7 rows
per group. The pipeline's reshape was applied to all 1,519 long rows instead of
the 217 deduplicated wide rows, so every harmonised (study_id, effect, se,
horizon) tuple appears **exactly 7 times**: 7,420 rows, 1,060 unique tuples,
`groupby(...).size()` == 7 for all 1,060. Correct table: 1,060 rows; shipped:
7,420; spurious: 6,360 = 11.76% of the entire pooled table, which also makes
price_puzzle its largest "literature".
Consequences, computed: WLS PET on price_puzzle gives identical point estimates
(intercept 1.426e-4, slope -0.478) but the intercept t-statistic inflates from
2.69 (dedup) to 7.13 (shipped) — sqrt(7) exactly. Any count-sensitive estimator
(selection models, p-curve, AIC/likelihood comparisons, "N estimates" claims)
is wrong by 7x. The catalogue's own entry contains the smoking gun it never
cross-checked: description says "1,000 VAR estimates" while
`n_estimates_in_literature` = 7,420 (the dedup count 1,060 matches the paper).
The headline counts 54,076 and 61,294 are both inflated by 6,360.
Why every existing check passed: t-reproduction, roundtrip-to-source,
distribution and median-|t| checks are all invariant to row duplication
(dedup medians by horizon are identical to shipped: 0.83/0.83/0.78/0.75/0.91).

### D2. data_midyear holds a transformed regressor, not a year, in 4 literatures (4,004 rows)
`data_midyear` ranges 0.00–3.40 (alphas, beauty, students) and 3.43–4.38
(skill) — log/standardised values, filled on 100% of those rows, e.g. alphas
"Eling & Faust (2010)" data_midyear = 2.603. This is the same disease as the
KNOWN pub_year issue but in a **different column**, and the known list covers
only pub_year. 4,004 rows of nonsense years; any user computing "data vintage"
effects across literatures ingests them silently (global min of the column is
0.0, which at least is discoverable; 3.43–4.38 in skill is not obviously wrong
if the user filters > 0).

### D3. `citations` (and likely `impact_factor`) mix incompatible scales across literatures
`citations` max by literature: alphas 4.15, beauty 4.06, class 6.15,
competition 4.16, discrate 4.53, incentives 5.11, skill 5.76, students 5.33 —
log-scaled — vs raw counts elsewhere (size max 15,600; habits 3,710). students
has **26 negative citation values** (min -2.70), i.e. standardised, not even
plain log. Any cross-literature regression on `citations` is meaningless, and
nothing in the schema or notes says the scale varies. `impact_factor` shows the
same signature (esg max 0.123, water 0.875, remittances 0.689 vs inflation
14.9, alphas 18.2) — probably RePEc recursive IF vs JCR IF vs normalised; I
could not fully adjudicate which definition each literature uses (flagged as
uncertainty below).

### D4. The trust/size overlap numbers in overrides.json are internally inconsistent and not reproducible
The `trust` note states: "1,269 of trust's 1,613 usable (effect, se) pairs
(83.5%) already appear in the pooled size rows, leaving 251 estimates unique to
trust." Those three numbers are mutually inconsistent: 1,269/1,613 = 78.7% (not
83.5%), and 1,613 - 1,269 = 344 (not 251). Recomputed from the shipped files:
multiset overlap of trust's 1,613 usable pairs with the 1,631 pooled size rows
is **1,329 (82.4%), leaving 284 unique to trust**. (The `verified_by`
set-based numbers — 1,256 shared, 259 only-trust, 276 only-size — DO reproduce
exactly; it is the later "measured rather than asserted" note whose arithmetic
is wrong.)

### D5. house_prices standard error is constructed but flagged `se_is_derived = False`
`se_col` = "mean:SE_l+SE_u" (average of two CI-implied SEs), yet
`se_is_derived` is False on all 1,555 rows. activism/gasoline/reforms are
flagged True; house_prices is the one constructed SE the flag misses. The
already-verified claim "every (effect, se) pair occurs verbatim in its original
source file" cannot be literally true for these rows either.

### D6. units.json is missing the `spillovers` entry entirely
The pooled table carries effect_units "elasticity" for spillovers (from
overrides.json), but units.json — the file the site presents as the semantic
layer — has no `spillovers` key at all, hence no direction_note for a 2,421-row
literature whose values span -136..52.3.

### D7. `pcc` column filling is inconsistent with declared units
reforms' effect IS a partial correlation (units say so; it is computed via
pcc_from_t) yet its `pcc`/`se_pcc` columns are 100% null, while the other six
pcc literatures have pcc == effect on every row (verified to 1e-9). Meanwhile
dst (units "percent") fills pcc on 88% of rows. A user selecting
`pcc.notna()` to build a comparable-units subsample silently loses reforms'
245 rows and gains dst's.

### D8. Heavy exact-duplicate (effect,se) mass inside other literatures, unflagged
Share of rows belonging to duplicated (effect,se) pairs: scc 89.4% (602 rows,
only 273 unique pairs), dst 50.5%, frisch 40.8%, inflation 39.6%, migrant
20.1%. These duplicates exist in the sources (rounding of reported values +
winsorised bounds in inflation: 45 rows at -3.85, 42 at 6.0, disclosed), so
they are not pipeline errors like D1 — but nothing marks them, and estimators
that treat rows as distinct draws (p-curve, selection models, permutation
tests) inherit them. Also note row-level tracing via (source_file, effect, se)
is NOT unique for these rows, which weakens the traceability claim (see A3).

### D9 (minor). n_obs oddities beyond the disclosed gasoline case
n_obs == 1 also occurs in migrant (1 row) and remittances (1 row), not only
gasoline's disclosed 90. Non-integer n_obs in six literatures (size 102 rows,
e.g. 37.4167; discrate 24; alphas 15; sigma 14; forward 10; electricity 1) —
plausibly averages of per-month/per-portfolio counts, but undocumented, and
there is no provenance column saying which source column n_obs came from.

## Claims that are asserted, not demonstrated

- **A1.** Catalogue note: "price_puzzle reshapes wide impulse-response columns
  into one row per horizon." False as shipped — seven rows per horizon (D1).
- **A2.** armington's note orders the user to "not pool [short- and long-run]
  without" the srun flag, and electricity's direction_note says to condition on
  run-length flags — but the pooled table carries NEITHER flag and `horizon` is
  null for both literatures. Computed severity: armington mixes 556 short-run
  (mean 0.88) with 2,968 long-run (mean 1.65) indistinguishably; electricity's
  3,324 rows are 49.5% short-run / 28.7% intermediate / 21.8% long-run. The
  instruction is not executable on the object it ships with.
- **A3.** "source_file, effect_col and se_col identify the origin of every
  value, so any row can be traced." Only effect/se have provenance columns;
  n_obs, pub_year, and all 18 moderators have none (D2/D3 are direct
  casualties), and for the 89% duplicated scc rows the (effect,se) match does
  not identify a unique source row.
- **A4.** 19 of 44 catalogue entries carry audit_status
  "arithmetic_pairing_only" (19 domain_reviewed, 1 code_traced). The pairing
  check proves the effect/se pairing, not the semantic fields — for those 19,
  effect_units and descriptions rest on assertion. To the catalogue's credit
  the status is disclosed; the weakness is that units.json semantics have no
  check of any kind (see G3).
- **A5.** direction_note is null for 20 in-table literatures. Some are fine
  (pcc conventions), but risk spans -810..2,100 "relative risk aversion" with
  no note, and remittances' "regression coefficient" spans -11..191 across five
  coded dependent variables (known, staged as pending_1_0_0).
- **A6.** Unit strings that nothing can verify: codebooks carry no variable
  labels or descriptions (checked size.json — stats only), so units.json is a
  single point of failure for e.g. size's "percent" (a size-return slope — per
  what unit of size is not stated anywhere machine-readable), esg's "points per
  percentage point of board diversity", inflation's "percentage points". I
  could not falsify these; I also could not confirm them from shipped
  artifacts. Sign-convention claims I COULD test all passed: dst median -0.40
  (claimed -0.40), size 76.1% negative (claimed 76%), gasoline_price 99.5%
  negative, water positive (median 0.157), electricity 91.5% negative,
  incentives mean 0.05118 (claimed 0.05118), eis mean 0.49 under |x|<10
  (claimed 0.49), discrate ln(nobs)==sample_size (exact), fdi truly has no
  SE-like column.
- **A7.** house_prices/price_puzzle both fill `horizon`, but in different time
  units: price_puzzle in months {3..36}, house_prices in the study's native
  periods (88.8% quarterly). Convertible via freq_monthly/freq_quarterly (both
  filled for house_prices), but the column itself is silently unit-mixed and no
  note says so.

## Gaps in the existing checks

- **G1.** Every existing check (t-reproduction, verbatim roundtrip,
  distribution battery, per-dataset vs pooled comparison) is invariant to row
  duplication. Nothing compares row cardinality against an external anchor —
  even the catalogue's own free-text estimate count ("1,000 VAR estimates" vs
  7,420 rows sat in the same JSON object). A cheap check: unique (study_id,
  effect, se, horizon) tuples / rows, per literature; anything far below 1
  needs a written justification.
- **G2.** No check that harmonised moderator columns are on commensurable
  scales across literatures. A per-column per-literature range gate (years in
  1900–2027; citations non-negative; dummies in {0,1}) would have caught D2 and
  D3 immediately — it is the exact check that caught pub_year, never
  generalised to the other 17 moderators.
- **G3.** units.json / direction_note have zero automated coverage, yet several
  notes make quantitative claims (dst median, size 76%, price_puzzle 0.002).
  Those claims are testable — I tested them by hand and they pass — but nothing
  runs them, so any future regeneration can silently break the semantic layer.
  Encode each direction_note claim as a fixture (expected median sign, expected
  % negative) and run it in 9x_verify.
- **G4.** verified_by numeric claims are not re-executed. The trust note (D4)
  drifted into self-contradiction with no alarm; same risk applies to every
  count quoted in overrides.json.
- **G5.** Completeness of units.json vs the shipped table is unchecked (D6:
  spillovers missing). One assert: set(units.json) >= set(df.dataset.unique()).
- **G6.** No flag-parity check between prose and schema: notes that instruct
  conditioning on a variable (srun, run-length) should fail the build if that
  variable is absent from the harmonised columns (A2).

## Priority order for what to fix

1. **D1** — dedup price_puzzle to 1,060 rows, regenerate the table and every
   count (54,076 -> 47,716; 61,294 analysis-sample count likewise), and fix the
   catalogue entry/description mismatch. Everything downstream (benchmark runs,
   Zenodo copy) is contaminated until then.
2. **D2 + D3** — null out or rescale data_midyear (4 literatures) and document
   or harmonise citations/impact_factor scales; these silently poison any
   cross-literature moderator use, which is the table's stated purpose.
3. **A2** — carry srun (armington) and run-length (electricity) into the pooled
   table (the `horizon` column or a new flag); until then the two literatures'
   funnels mix estimands with no way to separate them.
4. **G1 + G2** — add the cardinality and moderator-range gates to the check
   battery; they are one-liners and would have caught the two worst defects.
5. **D4, D5, D6, D7** — correct the trust note arithmetic (use 1,329/82.4%/284
   or re-derive), set house_prices se_is_derived=True, add spillovers to
   units.json, fill reforms' pcc/se_pcc.
6. **D8, D9, A3, A7** — documentation-level: duplicate-mass note per
   literature, n_obs provenance and the non-integer/==1 cases, horizon unit
   note.

## Explicit uncertainties

- impact_factor scale mixing (D3) is inferred from ranges; I could not
  determine which IF definition each literature uses. Reading each source
  file's IF column against JCR/RePEc values for 2–3 journals would settle it.
- I did not verify the migrant/skill "inverse elasticity" direction claims
  against the papers (no machine-readable statement exists to test them
  against); if either is wrong the sign trap is severe, and only a read of the
  two papers settles it.
- The 88/99 horizon rows in puzzle.xls (source long structure) were assumed to
  be the lags project's extra horizons, consistent with overrides' lags entry;
  I did not re-read puzzle.do to confirm which of the 7 long rows the paper
  itself treats as the estimation sample (irrelevant to D1, which is about the
  wide columns being constant within estimate).
- scc/dst duplicate mass (D8) was confirmed present in the harmonised table
  and is consistent with source rounding, but I did not row-match every
  duplicate back to the sources.
