## RED metrics (Requests, Errors, Duration) with Prometheus text-format export.
## Phase C deliverable — production observability without external dependencies.
##
## Design:
## * One ``MetricsRegistry`` owns all counters and histogram buckets.
## * ``recordRequest`` updates counters in O(log n) table lookup + O(B) bucket
##   scan where B = number of histogram bounds (11 by default).
## * ``exportPrometheus`` produces a valid Prometheus text format 0.0.4 document
##   that can be scraped by any compatible server or push gateway.
## * A process-global registry is available via ``getMetrics()`` / ``recordRequest``.

import tables, strutils, sequtils, algorithm

type
  HistogramBuckets* = seq[float]
  ## Sorted upper-bound values in milliseconds for the duration histogram.

  MetricEntry = object
    requestCount:    int
    errorCount:      int
    durationSum:     float        ## cumulative duration in milliseconds
    durationBuckets: seq[int]     ## cumulative count per histogram bucket bound

  MetricsRegistry* = ref object
    buckets*:      HistogramBuckets
    entries:       Table[string, MetricEntry]
    totalRequests: int
    totalErrors:   int
    totalDuration: float          ## milliseconds

const DefaultBuckets*: HistogramBuckets =
  @[1.0, 5.0, 10.0, 25.0, 50.0, 100.0, 250.0, 500.0, 1_000.0, 2_500.0, 5_000.0]
  ## Default histogram upper bounds match common web-service SLA tiers (ms).

proc newMetricsRegistry*(
  buckets: HistogramBuckets = DefaultBuckets
): MetricsRegistry =
  ## Creates a new, empty metrics registry with the given histogram bucket bounds.
  MetricsRegistry(
    buckets:      buckets,
    entries:      initTable[string, MetricEntry](),
    totalRequests: 0,
    totalErrors:   0,
    totalDuration: 0.0
  )

var globalMetrics* {.threadvar.}: MetricsRegistry
## Process-global metrics registry.
##
## **Multi-thread note:** ``{.threadvar.}`` means each OS thread maintains its
## own independent copy of this registry.  In multi-threaded deployments
## (e.g. with ``--threads:on``) the counters are per-thread and must be
## aggregated at scrape time.  For a single-threaded async server (the default
## NimHTTP deployment model) this is not a limitation.  If you need a truly
## shared registry across threads, create a ``MetricsRegistry`` explicitly and
## protect it with a lock.

proc initGlobalMetrics*() =
  ## Initialises the process-global metrics registry if it has not been
  ## initialised yet.  Safe to call multiple times.
  if globalMetrics.isNil:
    globalMetrics = newMetricsRegistry()

proc getMetrics*(): MetricsRegistry =
  ## Returns the process-global metrics registry, initialising it on first use.
  if globalMetrics.isNil:
    initGlobalMetrics()
  globalMetrics

proc resetMetrics*(registry: MetricsRegistry) =
  ## Resets all counters to zero.  Intended for use in tests; do not call in
  ## production unless you deliberately want to discard accumulated data.
  registry.entries.clear()
  registry.totalRequests = 0
  registry.totalErrors   = 0
  registry.totalDuration = 0.0

proc entryKey(httpMethod, path: string, statusCode: int): string {.inline.} =
  httpMethod & "|" & path & "|" & $statusCode

proc recordRequest*(
  registry: MetricsRegistry,
  httpMethod: string,
  path: string,
  statusCode: int,
  durationMs: float
) =
  ## Records a single completed request into ``registry``.
  ##
  ## * ``httpMethod`` — uppercase HTTP verb, e.g. ``"GET"``.
  ## * ``path``       — matched route pattern, e.g. ``"/api/users/:id"``.
  ## * ``statusCode`` — HTTP response status, e.g. ``200``.
  ## * ``durationMs`` — wall-clock time from first byte received to last byte
  ##                    sent, in milliseconds.
  let key = entryKey(httpMethod, path, statusCode)

  if not registry.entries.hasKey(key):
    registry.entries[key] = MetricEntry(
      requestCount:    0,
      errorCount:      0,
      durationSum:     0.0,
      durationBuckets: newSeq[int](registry.buckets.len)
    )

  var entry = registry.entries[key]
  entry.requestCount += 1
  if statusCode >= 500:
    entry.errorCount += 1
  entry.durationSum += durationMs

  # Buckets are sorted ascending.  Find the first qualifying bound and
  # increment all buckets from that index onward — no further condition
  # checks needed because every larger bound also qualifies.
  var firstMatch = registry.buckets.len   # default: falls in +Inf only
  for idx, bound in registry.buckets:
    if durationMs <= bound:
      firstMatch = idx
      break
  for idx in firstMatch ..< registry.buckets.len:
    entry.durationBuckets[idx] += 1

  registry.entries[key] = entry

  registry.totalRequests += 1
  if statusCode >= 500:
    registry.totalErrors += 1
  registry.totalDuration += durationMs

proc recordRequest*(
  httpMethod: string,
  path: string,
  statusCode: int,
  durationMs: float
) =
  ## Convenience overload that records into the global metrics registry.
  getMetrics().recordRequest(httpMethod, path, statusCode, durationMs)

proc totalRequests*(registry: MetricsRegistry): int =
  ## Returns the total number of requests recorded in this registry.
  registry.totalRequests

proc totalErrors*(registry: MetricsRegistry): int =
  ## Returns the total number of 5xx responses recorded in this registry.
  registry.totalErrors

proc exportPrometheus*(registry: MetricsRegistry): string =
  ## Exports all metrics in Prometheus text format (exposition format v0.0.4).
  ## The returned string can be served directly as the body of a ``/metrics``
  ## endpoint with ``Content-Type: text/plain; version=0.0.4; charset=utf-8``.
  var lines: seq[string] = @[]

  # ── process-level totals ─────────────────────────────────────────────────
  lines.add("# HELP nimhttp_requests_total Total HTTP requests processed")
  lines.add("# TYPE nimhttp_requests_total counter")
  lines.add("nimhttp_requests_total " & $registry.totalRequests)

  lines.add("# HELP nimhttp_errors_total Total HTTP 5xx responses")
  lines.add("# TYPE nimhttp_errors_total counter")
  lines.add("nimhttp_errors_total " & $registry.totalErrors)

  lines.add("# HELP nimhttp_duration_seconds_sum Sum of all request durations in seconds")
  lines.add("# TYPE nimhttp_duration_seconds_sum counter")
  lines.add("nimhttp_duration_seconds_sum " & $(registry.totalDuration / 1_000.0))

  # ── per-route request counters ───────────────────────────────────────────
  lines.add("# HELP nimhttp_route_requests_total Requests per route, method, and status code")
  lines.add("# TYPE nimhttp_route_requests_total counter")

  var sortedKeys = toSeq(registry.entries.keys)
  sort(sortedKeys)

  for key in sortedKeys:
    let entry  = registry.entries[key]
    let parts  = key.split('|')
    if parts.len != 3: continue
    let label = "method=\"" & parts[0] & "\",path=\"" & parts[1] & "\",status=\"" & parts[2] & "\""
    lines.add("nimhttp_route_requests_total{" & label & "} " & $entry.requestCount)

  # ── per-route duration histogram ─────────────────────────────────────────
  lines.add("# HELP nimhttp_request_duration_ms_bucket Request duration histogram in milliseconds")
  lines.add("# TYPE nimhttp_request_duration_ms_bucket histogram")

  for key in sortedKeys:
    let entry = registry.entries[key]
    let parts = key.split('|')
    if parts.len != 3: continue
    let baseLabel = "method=\"" & parts[0] & "\",path=\"" & parts[1] & "\",status=\"" & parts[2] & "\""

    for idx, bound in registry.buckets:
      let label = baseLabel & ",le=\"" & $bound & "\""
      lines.add("nimhttp_request_duration_ms_bucket{" & label & "} " & $entry.durationBuckets[idx])

    # +Inf bucket equals the route's total request count
    lines.add("nimhttp_request_duration_ms_bucket{" & baseLabel & ",le=\"+Inf\"} " & $entry.requestCount)

  lines.join("\n") & "\n"

proc exportPrometheus*(): string =
  ## Convenience overload using the global metrics registry.
  getMetrics().exportPrometheus()
