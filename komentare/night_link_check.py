#!/usr/bin/env python3
"""Polite, resumable outbound-link audit for this static site."""

from __future__ import annotations

import argparse
import html.parser
import json
import re
import socket
import sys
import time
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urljoin, urldefrag, urlsplit, urlunsplit

import requests


ROOT = Path(__file__).resolve().parent
PROGRESS = ROOT / ".night-links-progress.json"
REPORT = ROOT / "NIGHT_LINKS.md"
SITE_HOSTS = {"meta-analysis.cz", "www.meta-analysis.cz"}
URL_RE = re.compile(r"https?://[^\s<>\"']+", re.IGNORECASE)
REDIRECT_CODES = {301, 302, 303, 307, 308}
MAX_REDIRECTS = 15
TIMEOUT = 45
HOST_DELAY = 2.05
CHECKER_UA = "meta-analysis.cz-link-audit/1.0 (+https://meta-analysis.cz/)"
BROWSER_UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/126.0.0.0 Safari/537.36"
)


class HrefParser(html.parser.HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.hrefs: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        for key, value in attrs:
            if key.lower() == "href" and value:
                self.hrefs.append(value.strip())


def clean_url(raw: str) -> str | None:
    raw = raw.strip().rstrip(".,;:!?)]}>")
    if not raw.lower().startswith(("http://", "https://")):
        return None
    raw, _fragment = urldefrag(raw)
    parts = urlsplit(raw)
    if not parts.hostname:
        return None
    host = parts.hostname.lower()
    port = parts.port
    netloc = host
    if port and not ((parts.scheme.lower() == "http" and port == 80) or (parts.scheme.lower() == "https" and port == 443)):
        netloc = f"{host}:{port}"
    if parts.username:
        auth = parts.username
        if parts.password:
            auth += f":{parts.password}"
        netloc = f"{auth}@{netloc}"
    return urlunsplit((parts.scheme.lower(), netloc, parts.path or "/", parts.query, ""))


def is_external(url: str) -> bool:
    host = (urlsplit(url).hostname or "").lower()
    return host not in SITE_HOSTS


def add_url(refs: dict[str, set[str]], raw: Any, source: str) -> None:
    if not isinstance(raw, str):
        return
    url = clean_url(raw)
    if url and is_external(url):
        refs[url].add(source)


def item_label(filename: str, item: Any, index: int) -> str:
    if isinstance(item, dict):
        ident = item.get("id") or item.get("datetime") or item.get("date") or f"item {index + 1}"
        title = item.get("title")
        if title:
            return f"{filename} item {ident} ({title})"
        return f"{filename} item {ident}"
    return f"{filename} item {index + 1}"


def collect_json_key_urls(obj: Any, source: str, refs: dict[str, set[str]]) -> None:
    if isinstance(obj, dict):
        for key, value in obj.items():
            if key in {"url", "original_url"}:
                add_url(refs, value, source)
            collect_json_key_urls(value, source, refs)
    elif isinstance(obj, list):
        for value in obj:
            collect_json_key_urls(value, source, refs)


def collect_embedded_urls(obj: Any, source: str, refs: dict[str, set[str]]) -> None:
    if isinstance(obj, str):
        for match in URL_RE.findall(obj):
            add_url(refs, match, source)
    elif isinstance(obj, dict):
        for value in obj.values():
            collect_embedded_urls(value, source, refs)
    elif isinstance(obj, list):
        for value in obj:
            collect_embedded_urls(value, source, refs)


def collect_links() -> dict[str, list[str]]:
    refs: dict[str, set[str]] = defaultdict(set)

    # The requested glob is */index.html, i.e. page indexes below the site root.
    for path in sorted(ROOT.glob("*/index.html")):
        parser = HrefParser()
        parser.feed(path.read_text(encoding="utf-8", errors="replace"))
        rel = path.relative_to(ROOT).as_posix()
        for href in parser.hrefs:
            if href.startswith("//"):
                href = "https:" + href
            add_url(refs, href, rel)

    index_data = json.loads((ROOT / "index.json").read_text(encoding="utf-8"))
    # Label item-level references precisely rather than attributing all of them to the file.
    for key, value in index_data.items():
        if key == "items" and isinstance(value, list):
            for i, item in enumerate(value):
                collect_json_key_urls(item, item_label("index.json", item, i), refs)
        else:
            collect_json_key_urls({key: value}, "index.json top level", refs)

    social_data = json.loads((ROOT / "social-posts.json").read_text(encoding="utf-8"))
    if isinstance(social_data, list):
        for i, item in enumerate(social_data):
            label = item_label("social-posts.json", item, i)
            collect_json_key_urls(item, label, refs)
            # Post bodies and comment-link arrays are rendered as outbound links on the site.
            collect_embedded_urls(item, label, refs)
    else:
        collect_json_key_urls(social_data, "social-posts.json", refs)
        collect_embedded_urls(social_data, "social-posts.json", refs)

    return {url: sorted(sources) for url, sources in sorted(refs.items())}


def load_progress() -> dict[str, Any]:
    if not PROGRESS.exists():
        return {"started_at": datetime.now(timezone.utc).isoformat(), "results": {}}
    return json.loads(PROGRESS.read_text(encoding="utf-8"))


def save_progress(progress: dict[str, Any]) -> None:
    temp = PROGRESS.with_suffix(".json.tmp")
    temp.write_text(json.dumps(progress, ensure_ascii=False, indent=2), encoding="utf-8")
    try:
        temp.replace(PROGRESS)
    except PermissionError:
        # Dropbox on Windows may briefly deny an atomic replace while indexing.
        PROGRESS.write_text(temp.read_text(encoding="utf-8"), encoding="utf-8")
        try:
            temp.unlink()
        except PermissionError:
            pass


class PoliteRequester:
    def __init__(self) -> None:
        self.last_request: dict[str, float] = {}
        self.session = requests.Session()

    def wait_for_host(self, url: str) -> None:
        host = (urlsplit(url).hostname or "").lower()
        last = self.last_request.get(host)
        if last is not None:
            remaining = HOST_DELAY - (time.monotonic() - last)
            if remaining > 0:
                time.sleep(remaining)
        self.last_request[host] = time.monotonic()

    def one_request(self, url: str, user_agent: str) -> requests.Response:
        self.wait_for_host(url)
        return self.session.get(
            url,
            headers={
                "User-Agent": user_agent,
                "Accept": "text/html,application/xhtml+xml,application/pdf;q=0.9,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.8,cs;q=0.6",
                "Connection": "close",
            },
            allow_redirects=False,
            timeout=TIMEOUT,
            stream=True,
        )

    def follow(self, start_url: str, user_agent: str) -> dict[str, Any]:
        current = start_url
        chain: list[dict[str, Any]] = []
        seen: set[str] = set()
        for _ in range(MAX_REDIRECTS + 1):
            if current in seen:
                return {"status": None, "error": "redirect loop", "final_url": current, "chain": chain}
            seen.add(current)
            response = self.one_request(current, user_agent)
            try:
                code = response.status_code
                location = response.headers.get("Location")
                chain.append({"url": current, "status": code, "location": location})
                if code in REDIRECT_CODES and location:
                    current = clean_url(urljoin(current, location)) or urljoin(current, location)
                    continue
                return {"status": code, "error": None, "final_url": current, "chain": chain}
            finally:
                response.close()
        return {"status": None, "error": "too many redirects", "final_url": current, "chain": chain}


def error_text(exc: BaseException) -> tuple[str, str]:
    if isinstance(exc, requests.exceptions.Timeout):
        return "timeout", "timeout"
    if isinstance(exc, requests.exceptions.SSLError):
        return "ssl", f"SSL error: {exc}"
    if isinstance(exc, requests.exceptions.ConnectionError):
        text = str(exc)
        lowered = text.lower()
        dns_markers = (
            "name or service not known",
            "nodename nor servname provided",
            "temporary failure in name resolution",
            "getaddrinfo failed",
            "failed to resolve",
        )
        if any(marker in lowered for marker in dns_markers):
            return "nxdomain", f"DNS failure: {text}"
        return "connection", f"connection error: {text}"
    if isinstance(exc, socket.gaierror):
        return "nxdomain", f"DNS failure: {exc}"
    return "other", f"{type(exc).__name__}: {exc}"


def check_url(requester: PoliteRequester, url: str) -> dict[str, Any]:
    attempts: list[dict[str, Any]] = []
    for attempt in range(2):
        if attempt:
            previous = attempts[-1]
            if previous.get("status") in {403, 429}:
                time.sleep(30)
            elif previous.get("error_kind") == "timeout":
                time.sleep(2)
            else:
                break
        ua = BROWSER_UA if attempt else CHECKER_UA
        try:
            result = requester.follow(url, ua)
            result["user_agent"] = "browser" if attempt else "checker"
            result["error_kind"] = None
        except BaseException as exc:  # Preserve an audit record for every network failure.
            kind, message = error_text(exc)
            result = {
                "status": None,
                "error": message,
                "error_kind": kind,
                "final_url": url,
                "chain": [],
                "user_agent": "browser" if attempt else "checker",
            }
        attempts.append(result)
        if not (result.get("status") in {403, 429} or result.get("error_kind") == "timeout"):
            break

    final = attempts[-1]
    code = final.get("status")
    kind = final.get("error_kind")
    if code in {404, 410} or kind == "nxdomain":
        verdict = "DEAD"
    elif code in {403, 429}:
        verdict = "BLOCKED"
    elif kind == "timeout":
        verdict = "UNKNOWN"
    elif code is not None and 200 <= code < 300:
        origin_path = urlsplit(url).path or "/"
        final_path = urlsplit(final.get("final_url") or url).path or "/"
        verdict = "REDIRECTED" if final.get("chain") and len(final["chain"]) > 1 and origin_path != final_path else "OK"
    else:
        verdict = "UNKNOWN"

    statuses = [str(hop["status"]) for hop in final.get("chain", [])]
    if code is not None:
        status_text = " → ".join(statuses) if statuses else str(code)
    else:
        status_text = final.get("error") or "unknown error"
    return {
        "status": status_text,
        "status_code": code,
        "error": final.get("error"),
        "error_kind": kind,
        "final_url": final.get("final_url") or url,
        "chain": final.get("chain", []),
        "attempts": attempts,
        "verdict": verdict,
        "checked_at": datetime.now(timezone.utc).isoformat(),
    }


def markdown_escape(value: str) -> str:
    return value.replace("|", "\\|").replace("\r", " ").replace("\n", " ")


def different_url(a: str, b: str) -> bool:
    return a != b


def write_report(refs: dict[str, list[str]], progress: dict[str, Any]) -> Counter[str]:
    results = progress["results"]
    counts: Counter[str] = Counter()
    rows: list[str] = []
    for url in sorted(refs):
        result = results.get(url)
        if not result:
            continue
        verdict = result["verdict"]
        counts[verdict] += 1
        final_url = result.get("final_url") or url
        shown_final = final_url if different_url(url, final_url) else "—"
        sources = "<br>".join(markdown_escape(s) for s in refs[url])
        rows.append(
            "| {url} | {status} | {final} | {sources} | {verdict} |".format(
                url=markdown_escape(url),
                status=markdown_escape(result.get("status") or "unknown"),
                final=markdown_escape(shown_final),
                sources=sources,
                verdict=verdict,
            )
        )

    lnkd_rows: list[str] = []
    for url in sorted(u for u in refs if (urlsplit(u).hostname or "").lower() == "lnkd.in"):
        result = results.get(url)
        if result:
            lnkd_rows.append(f"- {url} → {result.get('final_url') or 'unresolved'} ({result['verdict']}; {result['status']})")

    started = datetime.fromisoformat(progress["started_at"])
    ended_text = progress.get("completed_at") or datetime.now(timezone.utc).isoformat()
    ended = datetime.fromisoformat(ended_text)
    elapsed = max(0, int((ended - started).total_seconds()))
    hours, remainder = divmod(elapsed, 3600)
    minutes, seconds = divmod(remainder, 60)
    duration = f"{hours}h {minutes}m {seconds}s"
    hosts = {(urlsplit(url).hostname or "").lower() for url in refs}
    checked = len(results)
    total = len(refs)

    lines = [
        "# Night link audit",
        "",
        "| url | status | final url | referenced by | verdict |",
        "|---|---:|---|---|---|",
        *rows,
        "",
        "## lnkd.in resolutions",
        "",
        *(lnkd_rows or ["No `lnkd.in` links found."]),
        "",
        "## Coverage",
        "",
        f"Checked {checked} of {total} de-duplicated outbound links across {len(hosts)} hosts in {duration}.",
        "",
        "Verdicts: " + ", ".join(f"{name} {counts.get(name, 0)}" for name in ("DEAD", "REDIRECTED", "BLOCKED", "UNKNOWN", "OK")) + ".",
        "",
        "A redirect is classified as REDIRECTED only when the successful redirect chain changes the URL path. "
        "403/429 responses were retried after 30 seconds with a browser User-Agent. Timeouts were tried twice.",
        "",
    ]
    REPORT.write_text("\n".join(lines), encoding="utf-8")
    return counts


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inventory", action="store_true", help="collect links but do not request them")
    parser.add_argument("--fresh", action="store_true", help="discard a previous checkpoint")
    args = parser.parse_args()

    refs = collect_links()
    hosts = {(urlsplit(url).hostname or "").lower() for url in refs}
    if args.inventory:
        lnkd = sum((urlsplit(url).hostname or "").lower() == "lnkd.in" for url in refs)
        print(f"links={len(refs)} hosts={len(hosts)} lnkd.in={lnkd}")
        return 0

    if args.fresh and PROGRESS.exists():
        PROGRESS.unlink()
    progress = load_progress()
    progress["source_link_count"] = len(refs)
    progress["source_host_count"] = len(hosts)
    # Drop stale results only if their URL has disappeared from the current source set.
    progress["results"] = {url: result for url, result in progress.get("results", {}).items() if url in refs}
    save_progress(progress)

    requester = PoliteRequester()
    pending = [url for url in refs if url not in progress["results"]]
    total = len(refs)
    for number, url in enumerate(pending, start=len(progress["results"]) + 1):
        print(f"[{number}/{total}] {url}", file=sys.stderr, flush=True)
        result = check_url(requester, url)
        progress["results"][url] = result
        save_progress(progress)
        write_report(refs, progress)

    progress["completed_at"] = datetime.now(timezone.utc).isoformat()
    save_progress(progress)
    counts = write_report(refs, progress)
    print(" ".join(f"{name}={counts.get(name, 0)}" for name in ("DEAD", "REDIRECTED", "BLOCKED", "UNKNOWN", "OK")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
