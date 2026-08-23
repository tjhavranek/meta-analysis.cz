"""Build /search/ -- the page the site's search box now points at.

It points at this page instead of Google because Google was never actually searching this
site: the form carried as_sitesearch=meta-analysis.cz, which Google stopped honouring, so a
reader looking for "Armington elasticity" got the web's opinion of it rather than the paper
published here. It also sent every query to a third party, and could not see a page until
Google had crawled it.

The page loads api/v1/search-index.json once and answers every query after that in the
browser: no request per keystroke, nothing sent anywhere, and a page published a minute ago
is findable a minute ago.

    python tools/build_search_page.py
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_paper_page import ROOT  # noqa: E402

OUT = os.path.join(ROOT, "search", "index.html")


def homepage_footer():
    """The footer is one text with 148 copies, and verify_seo fails if they diverge. Reading
    it rather than writing it is how this page stays the 149th and not the exception."""
    page = open(os.path.join(ROOT, "index.html"), encoding="utf-8").read()
    m = re.search(r"<footer.*?</footer>", page, re.S)
    if not m:
        raise SystemExit("no footer on the homepage to copy")
    return m.group(0)


SCRIPT = r"""
(function () {
  var INDEX = "/api/v1/search-index.json";
  var idx = null, pending = null;
  var form = document.getElementById("searchform");
  var box = document.getElementById("q");
  var out = document.getElementById("results");
  var status = document.getElementById("searchstatus");

  function fold(s) {
    return s.normalize("NFKD").replace(/[̀-ͯ]/g, "").toLowerCase();
  }
  function terms(q) { return fold(q).match(/[a-z][a-z0-9]+/g) || []; }

  // Document ids are stored as base-36 gaps: "1f.2.9" is 51, 53, 62.
  function ids(s) {
    var parts = s.split("."), out = new Array(parts.length), at = 0;
    for (var i = 0; i < parts.length; i++) { at += parseInt(parts[i], 36); out[i] = at; }
    return out;
  }

  function load() {
    if (pending) return pending;
    status.textContent = "Loading the index…";
    pending = fetch(INDEX).then(function (r) {
      if (!r.ok) throw new Error(r.status);
      return r.json();
    }).then(function (j) {
      idx = j;
      idx.words = Object.keys(j.b).sort();
      return j;
    });
    return pending;
  }

  // The last word is what the reader is still typing, so it matches as a prefix: "armin"
  // finds Armington before the "gton" arrives. Earlier words are already finished words.
  function postings(term, asPrefix) {
    var hits = Object.create(null);
    function add(word, weight) {
      if (idx.b[word]) ids(idx.b[word]).forEach(function (d) {
        hits[d] = Math.max(hits[d] || 0, weight);
      });
      // Prominent on the page, not merely present: the difference between a paper about
      // the Armington elasticity and a paper that cites one.
      if (idx.s[word]) ids(idx.s[word]).forEach(function (d) {
        hits[d] = Math.max(hits[d] || 0, weight * 2.4);
      });
      if (idx.h[word]) ids(idx.h[word]).forEach(function (d) {
        hits[d] = Math.max(hits[d] || 0, weight * 4);
      });
    }
    if (idx.b[term] || idx.h[term]) add(term, 1);
    if (asPrefix && term.length >= 2) {
      var w = idx.words, lo = 0, hi = w.length;
      while (lo < hi) { var mid = (lo + hi) >> 1; if (w[mid] < term) lo = mid + 1; else hi = mid; }
      for (var i = lo; i < w.length && w[i].indexOf(term) === 0 && i - lo < 400; i++) {
        // A prefix hit is weaker than the word itself, and weaker the more it added.
        add(w[i], w[i] === term ? 1 : 0.55);
      }
    }
    var df = Object.keys(hits).length;
    return { hits: hits, idf: df ? Math.log(idx.n / df) : 0, df: df };
  }

  function search(q) {
    var want = terms(q);
    if (!want.length) return { rows: [], want: want, allCommon: false };
    var scores = null, allCommon = true;
    for (var i = 0; i < want.length; i++) {
      if (idx.common.indexOf(want[i]) < 0) allCommon = false;
      var p = postings(want[i], i === want.length - 1);
      var next = Object.create(null), any = false;
      for (var d in p.hits) {
        if (scores === null || d in scores) {
          next[d] = (scores === null ? 0 : scores[d]) + p.hits[d] * p.idf;
          any = true;
        }
      }
      // A word nobody has is not a reason to return nothing when it is the one still being
      // typed; every finished word has to be somewhere.
      if (!any && !(i === want.length - 1 && p.df === 0)) return { rows: [], want: want, allCommon: allCommon };
      if (any) scores = next;
    }
    if (scores === null) return { rows: [], want: want, allCommon: allCommon };
    var rows = Object.keys(scores).map(function (d) {
      return { doc: idx.docs[d], score: scores[d] };
    });
    rows.sort(function (a, b) { return b.score - a.score || a.doc.t.localeCompare(b.doc.t); });
    return { rows: rows, want: want, allCommon: allCommon };
  }

  function mark(text, want) {
    var esc = document.createElement("div");
    esc.textContent = text;
    var s = esc.innerHTML;
    want.forEach(function (w) {
      if (w.length < 2) return;
      s = s.replace(new RegExp("(" + w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + ")", "gi"),
                    "<mark>$1</mark>");
    });
    return s;
  }

  var KIND = { paper: "full text", note: "research note", data: "data", page: "" };

  function section(doc, want) {
    for (var i = 0; i < (doc.h || []).length; i++) {
      var head = fold(doc.h[i][1]);
      for (var j = 0; j < want.length; j++) {
        if (head.indexOf(want[j]) >= 0) return doc.h[i];
      }
    }
    return null;
  }

  function render(q) {
    var r = search(q);
    out.innerHTML = "";
    if (!terms(q).length) { status.textContent = ""; return; }
    if (!r.rows.length) {
      status.textContent = r.allCommon
        ? "Every page here says that. Try a word that narrows it down."
        : "Nothing on this site matches " + q + ".";
      return;
    }
    status.textContent = r.rows.length + (r.rows.length === 1 ? " page" : " pages");
    var frag = document.createDocumentFragment();
    r.rows.slice(0, 60).forEach(function (row) {
      var doc = row.doc, li = document.createElement("li");
      var sec = section(doc, r.want);
      var href = doc.u + (sec ? "#" + sec[0] : "");
      li.innerHTML = '<a href="' + href + '"><b>' + mark(doc.t, r.want) + "</b></a>"
        + (KIND[doc.k] ? ' <span class="kind">' + KIND[doc.k] + "</span>" : "")
        + (sec ? '<br /><span class="in">in ' + mark(sec[1], r.want) + "</span>" : "")
        + '<br /><span class="sum">' + mark(doc.s, r.want) + "</span>";
      frag.appendChild(li);
    });
    out.appendChild(frag);
    if (r.rows.length > 60) {
      var more = document.createElement("li");
      more.className = "more";
      more.textContent = "and " + (r.rows.length - 60) + " more, less closely matched";
      out.appendChild(more);
    }
  }

  var timer = null;
  function queue() {
    clearTimeout(timer);
    timer = setTimeout(function () {
      var q = box.value;
      load().then(function () { render(q); }).catch(function () {
        status.textContent = "The index did not load. Reload the page to try again.";
      });
      var url = q ? "?q=" + encodeURIComponent(q) : location.pathname;
      history.replaceState(null, "", url);
    }, 120);
  }

  form.addEventListener("submit", function (e) { e.preventDefault(); queue(); });
  box.addEventListener("input", queue);

  var initial = new URLSearchParams(location.search).get("q");
  if (initial) { box.value = initial; queue(); }
  box.focus();
})();
"""

PAGE = """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" \
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Search</title>
<meta name="description" content="Search every page on meta-analysis.cz \
&#8212; 54 papers in full, the research notes, the datasets and the guidelines. \
The search runs in your browser; nothing is sent anywhere." />
<link rel="canonical" href="https://meta-analysis.cz/search/" />
<link href="/style.css" rel="stylesheet" type="text/css" />
<link href="/paper.css" rel="stylesheet" type="text/css" />
</head>
<body>
<div id="wrapper">
<!-- start header -->
<div id="logo">
\t<a class="masthead-home" href="/">meta-analysis.cz</a>
\t<p class="site-name"><a href="/search/">Search</a></p>
\t<h2> <span class="mk">&raquo;</span>&nbsp;&nbsp;&nbsp; every page, in your browser</h2>
</div>
<div id="header">
\t<div id="menu">
\t\t<ul>
\t\t\t<li class="current_page_item"><a href="/search/">Search</a></li>
\t\t\t<li><a href="/">All meta-analyses</a></li>
\t\t\t<li><a href="/papers/">Papers in full</a></li>
\t\t\t<li><a href="/results/">Results</a></li>
\t\t\t<li><a href="/datasets/">Datasets</a></li>
\t\t</ul>
\t</div>
</div>
<!-- end header -->
<!-- start page -->
<div id="page" class="single">
\t<div id="content">
\t\t<div class="post">
\t\t\t<div class="entry">

<form id="searchform" class="sitesearch" method="get" action="/search/">
<label for="q">Search meta-analysis.cz</label>
<input type="search" id="q" name="q" value="" autocomplete="off"
 placeholder="publication bias, Armington, discount rate…" />
<button type="submit">Search</button>
</form>

<p id="searchstatus" class="searchstatus" role="status" aria-live="polite"></p>
<ul id="results" class="results"></ul>

<noscript>
<p>This search runs in your browser, so it needs JavaScript. Without it, the
<a href="/papers/">list of papers</a>, the <a href="/datasets/">datasets</a> and the
<a href="/sitemap.xml">sitemap</a> are the way around the site.</p>
</noscript>

<p class="searchnote">Every word on every page of this site is indexed, including all 54
papers in full. The index is downloaded once and searched in your browser: no query is sent
to this site or to anyone else, and a page published a minute ago is findable a minute ago.
It is a plain file &#8212; <a href="/api/v1/search-index.json">search-index.json</a> &#8212;
if you would rather search it yourself.</p>

\t\t\t</div>
\t\t</div>
\t</div>
</div>
<!-- end page -->
</div>
<script>%s</script>
%s
</body>
</html>
"""


def main():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    page = PAGE % (SCRIPT, homepage_footer())
    open(OUT, "w", encoding="utf-8").write(page)
    print("search/index.html: %d bytes" % len(page))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
