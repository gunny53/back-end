## Request tracing — Phase C deliverable.
##
## Provides W3C TraceContext-compatible trace and span IDs plus correlation-ID
## propagation for structured logging and distributed tracing.
##
## **Security notice:** ``newTraceId`` and ``newSpanId`` derive IDs from the
## wall clock and are therefore **not cryptographically random**.  They are
## suitable for development and single-host observability, but must be replaced
## with a CSPRNG (e.g. via an OTel SDK) before use in security-sensitive
## contexts such as rate-limiting, CSRF protection, or session tracking.
##
## Design goals:
## * Framework-agnostic: the ``TraceContext`` value type carries IDs and can be
##   forwarded to any exporter (OTel Collector, Jaeger, Zipkin) without coupling
##   this module to a specific SDK.
## * Zero external dependencies: ID generation relies on stdlib ``times`` +
##   ``strutils``; W3C header parsing is a pure string operation.
## * Fast path: ``extractTraceContext`` performs at most two header lookups and
##   one string split — no allocation on the outbound response path.

import strutils, times, asynchttpserver

const
  TraceParentHeader*   = "traceparent"
  TraceStateHeader*    = "tracestate"
  CorrelationIdHeader* = "x-correlation-id"

  # Multipliers used when deriving time-based trace/span IDs from the wall
  # clock.  These are arbitrary odd integers chosen to spread nanosecond
  # values across the full 64-bit range via simple multiplication, reducing
  # clustering of IDs generated in rapid succession.  They are NOT
  # cryptographically random; replace with a CSPRNG when integrating a
  # production OTel SDK.
  SpanIdMultiplier  = 1_337'i64
  TraceIdMultiplier = 1_337_0003'i64

type
  TraceContext* = object
    ## Immutable-by-convention trace state for a single request.
    ## Fields must not be mutated after extraction; create a new child context
    ## with a fresh ``spanId`` when propagating to downstream calls.
    traceId*:      string  ## 32 lowercase hex chars (128-bit W3C trace-id)
    spanId*:       string  ## 16 lowercase hex chars (64-bit W3C parent-id)
    parentSpanId*: string  ## 16 hex chars of the upstream span, or empty for root
    sampled*:      bool    ## True when the upstream requested sampling
    correlationId*: string ## x-correlation-id or first 16 chars of traceId

proc newSpanId*(): string =
  ## Generates a 64-bit span ID as 16 lowercase hex characters from the
  ## current wall clock.  Sufficient for non-distributed single-host tracing;
  ## replace with cryptographically random bytes when integrating an OTel SDK.
  let t = getTime()
  toHex(t.toUnix() xor int64(t.nanosecond) * SpanIdMultiplier, 16).toLowerAscii()

proc newTraceId*(): string =
  ## Generates a 128-bit trace ID as 32 lowercase hex characters.
  let t = getTime()
  toHex(t.toUnix(), 16).toLowerAscii() &
  toHex(int64(t.nanosecond) * TraceIdMultiplier, 16).toLowerAscii()

proc toTraceParent*(ctx: TraceContext): string =
  ## Serialises the context to a W3C ``traceparent`` header value.
  ## Format: ``00-<traceId>-<spanId>-<flags>``
  "00-" & ctx.traceId & "-" & ctx.spanId & "-" & (if ctx.sampled: "01" else: "00")

proc extractTraceContext*(headers: HttpHeaders): TraceContext =
  ## Extracts or creates a ``TraceContext`` from incoming HTTP headers.
  ##
  ## When a valid W3C ``traceparent`` header is present the trace ID and
  ## upstream span ID are preserved; a new child span ID is minted.  When no
  ## header is found a root context is created with fresh IDs.
  let correlationId = headers.getOrDefault(CorrelationIdHeader, "")
  let tp            = headers.getOrDefault(TraceParentHeader, "")

  if tp.len > 0:
    let parts = tp.split('-')
    if parts.len >= 4 and parts[1].len == 32 and parts[2].len == 16:
      let sampled = parts[3] == "01"
      let cid     = if correlationId.len > 0: correlationId else: parts[1][0 .. 15]
      return TraceContext(
        traceId:      parts[1],
        spanId:       newSpanId(),
        parentSpanId: parts[2],
        sampled:      sampled,
        correlationId: cid
      )

  let traceId = newTraceId()
  let cid     = if correlationId.len > 0: correlationId else: traceId[0 .. 15]
  TraceContext(
    traceId:      traceId,
    spanId:       newSpanId(),
    parentSpanId: "",
    sampled:      true,
    correlationId: cid
  )

proc extractTraceContext*(req: Request): TraceContext =
  ## Convenience overload — extracts from the headers of an incoming Request.
  extractTraceContext(req.headers)

proc injectTraceHeaders*(ctx: TraceContext, headers: HttpHeaders) =
  ## Injects W3C trace-propagation headers into an outgoing ``HttpHeaders``
  ## map so that downstream services receive the same trace context.
  headers[TraceParentHeader]   = ctx.toTraceParent()
  if ctx.correlationId.len > 0:
    headers[CorrelationIdHeader] = ctx.correlationId
