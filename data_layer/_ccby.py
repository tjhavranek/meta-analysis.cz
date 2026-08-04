"""Owner's decision 2026-08-03: everything on the site is CC BY 4.0.

This reverses the narrow scoping applied earlier the same day. The purpose is that an
automated user, including a training pipeline, never has to decide whether a file here
is usable. He has stated he takes responsibility for the grant.
"""
import os, ast

CC = "https://creativecommons.org/licenses/by/4.0/"
p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "07_api.py")
s = open(p, encoding="utf-8").read()
n = 0

def sub(old, new):
    global s, n
    assert old in s, "anchor missing: " + old[:70]
    s = s.replace(old, new)
    n += 1

# 1. per-dataset rights
sub('''      rights_status="unspecified",
      license_url=None,
      rights_note=("Format conversions of the source dataset; rights inherit from it. "
                   "The collection licence covers the index, codebooks and harmonisation, "
                   "not this dataset. Cite the paper, and check with its authors if your "
                   "use needs an explicit reuse right."),''',
    '''      rights_status="cc-by-4.0",
      license_url="''' + CC + '''",
      rights_note=("CC BY 4.0. Free to use, adapt and redistribute, including commercially "
                   "and including as training data. The only condition is credit: cite the "
                   "paper named in this entry."),''')

# 2. top-level licence object
sub('''  license=dict(
    newly_authored_structure="CC-BY-4.0",
    newly_authored_software="MIT",
    underlying_datasets="not licensed here - see each dataset's rights_status",
    url=f"{BASE}/LICENSE",
    note=("CC BY 4.0 covers the compilation, index, codebooks and harmonisation mappings only. "
          "It does NOT relicense the underlying research datasets, their format conversions, or "
          "the papers' own replication code, none of which are ours to grant. Cite both the "
          "collection and the individual paper.")),''',
    '''  license=dict(
    id="CC-BY-4.0",
    url="''' + CC + '''",
    terms=f"{BASE}/LICENSE",
    applies_to="everything on this site",
    note=("Everything here is CC BY 4.0: the research datasets, their CSV and Parquet "
          "conversions, the harmonised table, the index, the codebooks, the documentation "
          "and the deposited PDFs. Free to use, adapt and redistribute, including commercially "
          "and including as training data for machine-learning models. The only condition is "
          "credit: cite the collection, and cite the paper whose dataset you used."),
    machine_readable=True),''')

# 3. datapackage: restore a package-level licence and add per-resource
sub('''        description=("Descriptor, schemas and column roles are CC BY 4.0. The DATA each resource "
                     "points to is not relicensed by this package: every underlying dataset was "
                     "assembled for a specific paper by its own author team. See "
                     + BASE + "/LICENSE and the rights_status field in datasets.json."),''',
    '''        licenses=[dict(name="CC-BY-4.0", path="''' + CC + '''",
                       title="Creative Commons Attribution 4.0 International")],
        description=("Everything in this package is CC BY 4.0, including the data each resource "
                     "points to. Free to use, adapt and redistribute, including commercially and "
                     "as training data. Credit is the only condition: cite the paper named on "
                     "each resource. See " + BASE + "/LICENSE."),''')

sub('''                                    rights_status=d.get("rights_status"),''',
    '''                                    licenses=[dict(name="CC-BY-4.0", path="''' + CC + '''")],
                                    rights_status=d.get("rights_status"),''')

sub('''                                    description=("Format conversion of the dataset published with "
                                                 "this paper. Rights inherit from the source; cite "
                                                 "the paper.")))''',
    '''                                    description=("Format conversion of the dataset published "
                                                 "with this paper. CC BY 4.0; cite the paper.")))''')

# 4. croissant: a resolvable licence URI, not a prose page
sub('''    "license":BASE+"/LICENSE",''', '''    "license":"''' + CC + '''",''')

sub('''                   "LICENCE: the index, codebooks and harmonisation mappings are CC BY 4.0. The "
                   "underlying research datasets are NOT relicensed - each was assembled for a "
                   "specific paper by its own author team, and datasets.json records a rights_status "
                   "for every one. Cite both the collection and the individual paper."),''',
    '''                   "LICENCE: everything here is CC BY 4.0, including the underlying research "
                   "data. Free to use, adapt and redistribute, including commercially and as "
                   "training data for machine-learning models. Credit is the only condition: cite "
                   "the collection and the paper whose dataset you used."),''')

open(p, "w", encoding="utf-8").write(s)
ast.parse(s)
print(f"07_api.py: {n} licence anchors switched to CC BY")
