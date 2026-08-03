"""Resolve WORK and SITE without hardcoding anyone's home directory.

Two layouts are supported, because the pipeline is published inside the site it builds:

  development :  web_meta/data_layer/   +  web_meta/site/
  published   :  site/data_layer/       (SITE is the parent)

Override either with the SEO_SITE_DIR / DATA_LAYER_DIR environment variables.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))

def _resolve():
    work = os.environ.get("DATA_LAYER_DIR", HERE)
    site = os.environ.get("SEO_SITE_DIR")
    if site:
        return work, site
    sibling = os.path.join(os.path.dirname(work), "site")      # development layout
    if os.path.isdir(sibling):
        return work, sibling
    parent = os.path.dirname(work)                              # published layout
    if os.path.isdir(os.path.join(parent, "api")) or os.path.isdir(os.path.join(parent, "data")):
        return work, parent
    raise SystemExit(
        "Cannot locate the site directory. Expected either a 'site' folder beside "
        f"{work}, or api/ and data/ in its parent. Set SEO_SITE_DIR to point at it.")

WORK, SITE = _resolve()
