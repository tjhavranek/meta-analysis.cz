#!/usr/bin/env python3
"""Recompute the publication-bias counts the documentation publishes.

    python3 data_layer/98_fat_claim.py

api/v1/README.md tells a reader that, on 1st-99th percentile winsorised data with standard
errors clustered by study, the FAT intercept lies beyond +/-1.96 in 24 of the 41 pooled
literatures, and that FAT-PET reproduces three named published conclusions. Those numbers
were computed by hand. A hand-computed number in published prose is one dataset revision
away from being quietly wrong, and a reader has no way to check it.

This recomputes them from the shipped table and fails if the file stops saying what the
data says. It reads api/v1/README.md rather than hard-coding the claim, so correcting the
prose and correcting the check cannot drift apart.
"""

import os
import re
import sys

import numpy as np
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TABLE = os.path.join(ROOT, "data", "v1", "estimates_harmonised.parquet")
README = os.path.join(ROOT, "data_layer", "api_readme.md")


def cluster_ols(y, X, groups):
    """OLS with the Stata-style cluster-robust covariance (CR1)."""
    X = np.asarray(X, float)
    y = np.asarray(y, float)
    n, k = X.shape
    xtx_inv = np.linalg.inv(X.T @ X)
    beta = xtx_inv @ X.T @ y
    resid = y - X @ beta
    meat = np.zeros((k, k))
    uniq = pd.unique(groups)
    for g in uniq:
        idx = np.where(groups == g)[0]
        s = X[idx].T @ resid[idx]
        meat += np.outer(s, s)
    G = len(uniq)
    V = xtx_inv @ meat @ xtx_inv * (G / max(G - 1, 1)) * ((n - 1) / (n - k))
    return beta, np.sqrt(np.diag(V))


def winsorise(frame, cols=("effect", "se"), lo=0.01, hi=0.99):
    out = frame.copy()
    for c in cols:
        a, b = out[c].quantile([lo, hi])
        out[c] = out[c].clip(a, b)
    return out


def fat_pet(frame):
    """FAT-PET in its precision-weighted form: t = FAT + PET * (1/SE)."""
    t = (frame.effect / frame.se).values
    X = np.column_stack([np.ones(len(frame)), (1.0 / frame.se).values])
    beta, se = cluster_ols(t, X, frame.study_id.values)
    return {"fat": beta[0], "fat_t": beta[0] / se[0] if se[0] else np.nan,
            "pet": beta[1], "pet_t": beta[1] / se[1] if se[1] else np.nan}


def main():
    df = pd.read_parquet(TABLE)
    df = df[df.se > 0].dropna(subset=["effect", "se", "study_id"])

    beyond, iid_beyond, pets = 0, 0, {}
    for name, block in df.groupby("dataset", observed=True):
        if len(block) < 3 or block.study_id.nunique() < 2:
            continue
        w = winsorise(block)
        r = fat_pet(w)
        pets[name] = r["pet"]
        if abs(r["fat_t"]) > 1.96:
            beyond += 1
        # the same specification with independent errors, for the contrast the commit noted
        t = (w.effect / w.se).values
        X = np.column_stack([np.ones(len(w)), (1.0 / w.se).values])
        b = np.linalg.lstsq(X, t, rcond=None)[0]
        resid = t - X @ b
        s2 = resid @ resid / (len(w) - 2)
        se_iid = np.sqrt(np.diag(s2 * np.linalg.inv(X.T @ X)))
        if abs(b[0] / se_iid[0]) > 1.96:
            iid_beyond += 1

    total = len(pets)
    text = open(README, encoding="utf-8").read()
    m = re.search(r"beyond ±?1\.96 in (\d+) of the (\d+)\s*\n?\s*literatures", text)
    if not m:
        print("could not find the claim in api/v1/README.md")
        return 1
    said_beyond, said_total = int(m.group(1)), int(m.group(2))

    print("clustered by study, |FAT t| > 1.96 in %d of %d literatures  (README says %d of %d)"
          % (beyond, total, said_beyond, said_total))
    print("the same specification with independent errors: %d of %d" % (iid_beyond, total))
    for name, target, tol in (("education", 0.02, 0.02),
                              ("excess_sensitivity", 0.01, 0.02),
                              ("forward", 0.92, 0.05)):
        got = pets.get(name)
        ok = got is not None and abs(got - target) <= tol
        print("  PET %-20s %8.4f  README says about %.2f   %s"
              % (name, got if got is not None else float("nan"), target,
                 "ok" if ok else "MISMATCH"))
        if not ok:
            return 1

    if (beyond, total) != (said_beyond, said_total):
        print("\nREADME and data disagree: fix one of them")
        return 1
    print("\nthe documentation says what the data says")
    return 0


if __name__ == "__main__":
    sys.exit(main())
