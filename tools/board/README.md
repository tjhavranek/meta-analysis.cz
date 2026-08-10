# How the homepage board and the /datasets/ figure are made

These are the exact sources that produced what is on the site. They are copied here by
`publish_board_sources.py`, which every generator calls as its last step, so a file in
this directory is always the version that built the current page.

    build_answer_board.py     the 53 homepage tiles, and folds the 53 result sentences
                              into the collapsed <details> beneath them
    answer_board.json         the only curated text on a tile: a short form of each
                              paper's published headline -- usually by deletion, sometimes
                              a light paraphrase or verdict where the headline is prose.
                              The build refuses to run if a value carries a number that its
                              headline in estimates.csv does not, so a paraphrase can
                              rephrase but never introduce or alter a figure. A tile may
                              also carry its own `tail` where the lay equivalent lives in
                              the headline rather than the caveat column.
    results_questions.json    the question on each tile and on /results/
    build_zstat_figure.py     the |t| distribution and the 1.96 caliper on /datasets/,
                              plus data/v1/t_distribution.csv
    build_estimates.py        estimates.csv and the homepage result sentences
    headline_estimates.json   one quote-grounded record per paper behind those sentences

    inject_estimates.py       replaces the homepage results block; the only step that can
                              un-build it, which build_answer_board.py needs before it will
                              run again
    build_results_page.py     /results/
    build_datasets_page.py    /datasets/, which inlines the figure fragment

Everything is derived from `estimates.csv` and `data/v1/estimates_harmonised.csv`, both
published here under CC BY. Nothing on a tile or in a caption is a claim that is not
also in one of those files.

## These copies do not run in place

They are the exact sources that built the current pages, for reading and auditing. They
compute their paths from a working tree that has `site/` beside `tools_seo/` and
`redesign/`, so to actually re-run them, put them back:

    <work>/tools_seo/     build_answer_board.py, answer_board.json, build_zstat_figure.py,
                          build_estimates.py, headline_estimates.json, inject_estimates.py
    <work>/redesign/      results_questions.json, build_results_page.py,
                          build_datasets_page.py
    <work>/site/          this repository

`build_datasets_page.py` also expects the figure fragment at
`<work>/redesign/_fragments/zstat_figure.html`, which `build_zstat_figure.py` writes.
