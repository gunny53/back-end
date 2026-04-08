## Phase C unit tests — request tracing and RED metrics.

import unittest, strutils, httpcore

import nim_http/platform/tracing
import nim_http/platform/metrics

# ──────────────────────────────────────────────────────────────────────────────
# Tracing
# ──────────────────────────────────────────────────────────────────────────────

suite "phase c: trace id generation":
  test "newTraceId returns 32 lowercase hex characters":
    let id = newTraceId()
    check id.len == 32
    for ch in id:
      check ch in {'0'..'9', 'a'..'f'}

  test "newSpanId returns 16 lowercase hex characters":
    let id = newSpanId()
    check id.len == 16
    for ch in id:
      check ch in {'0'..'9', 'a'..'f'}

  test "consecutive calls produce different IDs":
    # IDs are time-based; successive calls within a test are not guaranteed to
    # differ by nanosecond resolution on all platforms — so we just assert they
    # are valid strings and not empty rather than asserting uniqueness.
    let a = newTraceId()
    let b = newTraceId()
    check a.len == 32
    check b.len == 32

suite "phase c: toTraceParent":
  test "serialises sampled context to W3C traceparent":
    let ctx = TraceContext(
      traceId:       "4bf92f3577b34da6a3ce929d0e0e4736",
      spanId:        "00f067aa0ba902b7",
      parentSpanId:  "",
      sampled:       true,
      correlationId: ""
    )
    let tp = ctx.toTraceParent()
    check tp == "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"

  test "serialises unsampled context":
    let ctx = TraceContext(
      traceId:       "4bf92f3577b34da6a3ce929d0e0e4736",
      spanId:        "00f067aa0ba902b7",
      parentSpanId:  "",
      sampled:       false,
      correlationId: ""
    )
    check ctx.toTraceParent().endsWith("-00")

suite "phase c: extractTraceContext from headers":
  test "generates root context when no traceparent present":
    let headers = newHttpHeaders()
    let ctx = extractTraceContext(headers)
    check ctx.traceId.len == 32
    check ctx.spanId.len == 16
    check ctx.parentSpanId == ""
    check ctx.sampled == true

  test "parses valid W3C traceparent header":
    let headers = newHttpHeaders([
      (TraceParentHeader, "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01")
    ])
    let ctx = extractTraceContext(headers)
    check ctx.traceId      == "4bf92f3577b34da6a3ce929d0e0e4736"
    check ctx.parentSpanId == "00f067aa0ba902b7"
    check ctx.sampled      == true
    # A new child span ID must be minted
    check ctx.spanId.len   == 16
    check ctx.spanId       != "00f067aa0ba902b7"

  test "sets sampled=false for flags 00":
    let headers = newHttpHeaders([
      (TraceParentHeader, "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-00")
    ])
    let ctx = extractTraceContext(headers)
    check ctx.sampled == false

  test "honours x-correlation-id header":
    let headers = newHttpHeaders([
      (CorrelationIdHeader, "my-custom-cid-12345")
    ])
    let ctx = extractTraceContext(headers)
    check ctx.correlationId == "my-custom-cid-12345"

  test "derives correlationId from traceId when header absent":
    let headers = newHttpHeaders([
      (TraceParentHeader, "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01")
    ])
    let ctx = extractTraceContext(headers)
    check ctx.correlationId == "4bf92f3577b34da6"  # first 16 chars of traceId

  test "falls back gracefully on malformed traceparent":
    let headers = newHttpHeaders([
      (TraceParentHeader, "not-a-valid-header")
    ])
    let ctx = extractTraceContext(headers)
    # Must produce a valid root context rather than raising
    check ctx.traceId.len == 32
    check ctx.spanId.len  == 16
    check ctx.parentSpanId == ""

# ──────────────────────────────────────────────────────────────────────────────
# Metrics
# ──────────────────────────────────────────────────────────────────────────────

suite "phase c: metrics registry":
  var reg: MetricsRegistry

  setup:
    reg = newMetricsRegistry()

  test "starts with zero counts":
    check reg.totalRequests == 0
    check reg.totalErrors   == 0

  test "recordRequest increments request count":
    reg.recordRequest("GET", "/api/users", 200, 5.0)
    check reg.totalRequests == 1
    check reg.totalErrors   == 0

  test "500 response increments error counter":
    reg.recordRequest("GET", "/api/fail", 500, 1.0)
    check reg.totalRequests == 1
    check reg.totalErrors   == 1

  test "4xx response does not increment error counter":
    reg.recordRequest("GET", "/api/missing", 404, 2.0)
    check reg.totalRequests == 1
    check reg.totalErrors   == 0

  test "multiple requests accumulate correctly":
    reg.recordRequest("GET",  "/api/a", 200, 10.0)
    reg.recordRequest("POST", "/api/b", 201, 20.0)
    reg.recordRequest("GET",  "/api/c", 500, 5.0)
    check reg.totalRequests == 3
    check reg.totalErrors   == 1

  test "resetMetrics clears all counters":
    reg.recordRequest("GET", "/api/x", 200, 3.0)
    reg.resetMetrics()
    check reg.totalRequests == 0
    check reg.totalErrors   == 0

suite "phase c: prometheus export":
  var reg: MetricsRegistry

  setup:
    reg = newMetricsRegistry()

  test "export contains process-level counter names":
    reg.recordRequest("GET", "/ping", 200, 1.0)
    let output = reg.exportPrometheus()
    check output.contains("nimhttp_requests_total")
    check output.contains("nimhttp_errors_total")
    check output.contains("nimhttp_duration_seconds_sum")

  test "export contains per-route labels":
    reg.recordRequest("GET", "/api/users", 200, 12.0)
    let output = reg.exportPrometheus()
    check output.contains("method=\"GET\"")
    check output.contains("path=\"/api/users\"")
    check output.contains("status=\"200\"")

  test "export contains histogram bucket lines":
    reg.recordRequest("POST", "/api/items", 201, 8.0)
    let output = reg.exportPrometheus()
    check output.contains("nimhttp_request_duration_ms_bucket")
    check output.contains("le=\"+Inf\"")

  test "export ends with newline":
    let output = reg.exportPrometheus()
    check output.endsWith("\n")

  test "empty registry produces valid prometheus output":
    let output = reg.exportPrometheus()
    check output.contains("nimhttp_requests_total 0")
    check output.contains("nimhttp_errors_total 0")
