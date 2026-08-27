"""The blessed build order, in one place, for CI and for a person at a terminal.

    python data_layer/rebuild.py            # rebuild everything, in order
    python data_layer/rebuild.py --check    # rebuild and FAIL if the tree drifts
    python data_layer/rebuild.py --data     # data layer only, skip the site builders

Why this exists. The order was written out by hand in three places -- the CI workflow,
data_layer/README.md, and whatever the person at the keyboard remembered -- and two of the
steps are order-sensitive in a way that fails SILENTLY:

  * build_datasets_page.py INLINES the figure fragment, so running it before
    build_zstat_figure.py republishes the PREVIOUS figure. On release day that left the page
    saying 49,689 in the figure title and caption while saying 49,669 three times around it,
    with every gate green, because each file was internally consistent.
  * generate_seo.py must run LAST, because build_datasets_page.py rewrites
    datasets/index.html without the seo-meta block.

A copy of an order is a copy that can go stale. This is the only copy now.
"""
import os, subprocess, sys, shutil, filecmp

HERE = os.path.dirname(os.path.abspath(__file__))
SITE = os.path.dirname(HERE)
OUT  = os.path.join(HERE, "out")

DATA = [("06_convert.py",   "convert the source archives"),
        ("08_harmonise.py", "build the pooled table"),
        ("07_api.py",       "build the index, datapackage and croissant"),
        ("10_fragments.py", "build the fragments, README, CFF and .zenodo.json")]

# Order matters. See the module docstring: figure BEFORE page, generate_seo LAST.
SITE_STEPS = [("notes/build_notes.py",              "notes"),
              ("tools/build_papers_api.py",         "the papers manifest (reads the built pages)"),
              ("tools/board/build_zstat_figure.py", "the t-statistic figure"),
              ("tools/board/build_datasets_page.py","the datasets page (inlines the figure)"),
              ("tools/generate_seo.py",             "SEO metadata (must be last)")]

# Built into out/ and compared against the published tree. t_distribution.csv is written by
# build_zstat_figure, not by 06-10, so it is not part of the data-layer comparison.
COMPARE = [("api/v1", "api/v1", None),
           ("data/v1", "data/v1", "t_distribution.csv"),
           ("CITATION.cff", "CITATION.cff", None),
           (".zenodo.json", ".zenodo.json", None),
           ("LICENSE", "LICENSE", None)]


def run(script, what):
    print(f"  -> {script}  ({what})", flush=True)
    r = subprocess.run([sys.executable, os.path.join(SITE, script)],
                       cwd=SITE, capture_output=True, text=True)
    if r.returncode:
        sys.stdout.write(r.stdout[-4000:]); sys.stderr.write(r.stderr[-4000:])
        sys.exit(f"FAILED: {script} exited {r.returncode}")


def differences():
    """Every published file that the rebuild did not reproduce."""
    out = []
    for src, dst, skip in COMPARE:
        s, d = os.path.join(OUT, src), os.path.join(SITE, dst)
        if os.path.isfile(s):
            if not (os.path.isfile(d) and filecmp.cmp(s, d, shallow=False)):
                out.append(dst)
            continue
        for root, _, files in os.walk(s):
            # sorted: os.walk yields directories in filesystem order, so an
            # unsorted descent makes this generator's output machine-dependent
            _.sort(); files.sort()
            for f in files:
                if skip and f == skip:
                    continue
                a = os.path.join(root, f)
                b = os.path.join(d, os.path.relpath(a, s))
                if not (os.path.isfile(b) and filecmp.cmp(a, b, shallow=False)):
                    out.append(os.path.relpath(b, SITE))
    return sorted(out)


def publish():
    """Copy the rebuild over the published tree. Nothing else moves files here."""
    n = 0
    for root, _, files in os.walk(OUT):
        # sorted: os.walk yields directories in filesystem order, so an
        # unsorted descent makes this generator's output machine-dependent
        _.sort(); files.sort()
        for f in files:
            a = os.path.join(root, f)
            b = os.path.join(SITE, os.path.relpath(a, OUT))
            if not (os.path.isfile(b) and filecmp.cmp(a, b, shallow=False)):
                os.makedirs(os.path.dirname(b), exist_ok=True)
                shutil.copy2(a, b); n += 1
    return n


check    = "--check" in sys.argv
data_only= "--data" in sys.argv

print("data layer:")
for s, w in DATA:
    run(os.path.join("data_layer", s), w)

drift = differences()
if check:
    # Scratch must go before anything tars the checkout: upload-pages-artifact uses path: .
    # and .gitignore does not apply to it, so out/ would ship 57 MB to the live site.
    shutil.rmtree(OUT, ignore_errors=True)
    if drift:
        print(f"\nDRIFT: {len(drift)} published file(s) do not follow from the inputs:")
        for f in drift[:20]:
            print("   " + f)
        sys.exit(1)
    print("\nno drift: every published data file follows from its canonical inputs")
else:
    moved = publish()
    print(f"published {moved} changed file(s)")
    shutil.rmtree(OUT, ignore_errors=True)

if not data_only:
    print("site:")
    for s, w in SITE_STEPS:
        run(s, w)

print("\nrebuild complete" + (" (check mode: nothing was published)" if check else ""))
