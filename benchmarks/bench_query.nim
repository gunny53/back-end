## Query-string parse baseline benchmark
## Phase B — hot-path baseline for URL query-string parsing

import times
import nim_http/http/query

# ──────────────────────────────────────────────────────────────
# Representative query strings covering common cases:
#   1. Simple    — a few static key=value pairs
#   2. Encoded   — percent-encoded values (common in search/filter APIs)
#   3. Long      — many params (pagination + filter + sort)
#   4. Minimal   — single param (health-check / flag)
# ──────────────────────────────────────────────────────────────
const queryStrings = [
  "page=1&limit=10",
  "q=hello%20world&lang=en&safe=on",
  "page=2&limit=25&sort=createdAt&order=desc&filter=active&include=tags",
  "format=json",
  "",
]

const urlSamples = [
  "/api/users?page=1&limit=10",
  "/search?q=hello%20world&lang=en",
  "/api/items?page=2&limit=25&sort=price&order=asc",
  "/health?format=json",
  "/api/root",
]

const iterations = 50_000

# ── parseQueryString benchmark ──────────────────────────────
let parseStart = cpuTime()
for _ in 0 ..< iterations:
  for qs in queryStrings:
    discard parseQueryString(qs)
let parseDurationMs = (cpuTime() - parseStart) * 1_000

stdout.writeLine "bench_query_parse_samples=" & $queryStrings.len
stdout.writeLine "bench_query_parse_iterations=" & $(iterations * queryStrings.len)
stdout.writeLine "bench_query_parse_duration_ms=" & $parseDurationMs

# ── queryFromUrl benchmark ───────────────────────────────────
let urlStart = cpuTime()
for _ in 0 ..< iterations:
  for url in urlSamples:
    discard queryFromUrl(url)
let urlDurationMs = (cpuTime() - urlStart) * 1_000

stdout.writeLine "bench_query_from_url_samples=" & $urlSamples.len
stdout.writeLine "bench_query_from_url_iterations=" & $(iterations * urlSamples.len)
stdout.writeLine "bench_query_from_url_duration_ms=" & $urlDurationMs
