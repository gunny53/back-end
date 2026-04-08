## Middleware pipeline compile + resolve baseline benchmark
## Phase A — hot-path baseline for the pipeline planner

import times
import nim_http/pipeline/middleware

# ──────────────────────────────────────────────────────────────
# Build a representative consumer:
#   - 3 global middlewares (logger, security headers, body parser)
#   - 2 route-scoped middlewares
# ──────────────────────────────────────────────────────────────
proc makeConsumer(): MiddlewareConsumer =
  let consumer = newMiddlewareConsumer()

  consumer.apply(loggerMiddleware)
  consumer.apply(securityHeadersMiddleware())
  consumer.apply(bodyParserMiddleware(10_000_000))
  consumer.apply(corsMiddleware("*"), @["/api"])
  consumer.apply(rateLimitMiddleware(100, 60_000), @["/api"])
  consumer

const paths = [
  "/",
  "/health/live",
  "/health/ready",
  "/api/v1/users",
  "/api/v1/users/42",
  "/api/v1/users/42/posts/7",
  "/static/logo.png",
  "/metrics",
]

const compileIterations = 2_000
const resolveIterations = 10_000

# ── compilePipelinePlans benchmark ───────────────────────────
let compileStart = cpuTime()
for _ in 0 ..< compileIterations:
  let c = makeConsumer()
  c.compilePipelinePlans()
let compileDurationMs = (cpuTime() - compileStart) * 1_000

stdout.writeLine "bench_pipeline_compile_iterations=" & $compileIterations
stdout.writeLine "bench_pipeline_compile_duration_ms=" & $compileDurationMs

# ── resolvePlan (path cache) benchmark ───────────────────────
let consumer = makeConsumer()
consumer.compilePipelinePlans()

# Warm the LRU cache with all paths first
for p in paths:
  discard consumer.resolvePlan(p)

let resolveStart = cpuTime()
for _ in 0 ..< resolveIterations:
  for p in paths:
    discard consumer.resolvePlan(p)
let resolveDurationMs = (cpuTime() - resolveStart) * 1_000

stdout.writeLine "bench_pipeline_resolve_paths=" & $paths.len
stdout.writeLine "bench_pipeline_resolve_iterations=" & $(resolveIterations * paths.len)
stdout.writeLine "bench_pipeline_resolve_duration_ms=" & $resolveDurationMs
