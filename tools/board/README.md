# How the homepage board and the /datasets/ figure are made

These are the exact sources that produced what is on the site. They are copied here by
`publish_board_sources.py`, which every generator calls as its last step, so a file in
this directory is always the version that built the current page.

    build_answer_board.py     the 53 homepage tiles, and folds the 53 result sentences
                              into the collapsed <details> beneath them
    answer_board.json         the only curated text on a tile: a short form of each
                              paper's published headline, produced by deletion. The
                              build refuses to run if a value carries a number that its
                              headline in estimates.csv does not.
    results_questions.json    the question on each tile and on /results/
    build_zstat_figure.py     the |t| distribution and the 1.96 caliper on /datasets/,
                              plus data/v1/t_distribution.csv
    build_estimates.py        estimates.csv and the homepage result sentences
    headline_estimates.json   one quote-grounded record per paper behind those sentences

Everything is derived from `estimates.csv` and `data/v1/estimates_harmonised.csv`, both
published here under CC BY. Nothing on a tile or in a caption is a claim that is not
also in one of those files.
