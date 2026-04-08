## Route-pattern parsing & segment-splitting baseline benchmark
## Phase A — hot-path baseline for router core

import times, strutils
import nim_http/http/routing

# ──────────────────────────────────────────────────────────────
# Fixture patterns covering the three common cases:
#   1. Static  — no dynamic segments
#   2. Param   — one or more :param segments
#   3. Nested  — deep hierarchy mixing static and param segments
# ──────────────────────────────────────────────────────────────
const patterns = [
  "/",
  "/health",
  "/health/live",
  "/api/v1/users",
  "/api/v1/users/:id",
  "/api/v1/users/:id/posts/:postId",
  "/api/v1/orgs/:orgId/teams/:teamId/members/:memberId",
]

const iterations = 5_000

# ── parseRoutePattern benchmark ──────────────────────────────
let parseStart = cpuTime()
for _ in 0 ..< iterations:
  for p in patterns:
    discard parseRoutePattern(p)
let parseDurationMs = (cpuTime() - parseStart) * 1_000

stdout.writeLine "bench_routing_parse_patterns=" & $patterns.len
stdout.writeLine "bench_routing_parse_iterations=" & $(iterations * patterns.len)
stdout.writeLine "bench_routing_parse_duration_ms=" & $parseDurationMs

# ── Segment-splitting microbenchmark ─────────────────────────
let splitStart = cpuTime()
for _ in 0 ..< iterations:
  for p in patterns:
    let trimmed = p.strip(chars = {'/'})
    if trimmed.len > 0:
      discard trimmed.split("/")
let splitDurationMs = (cpuTime() - splitStart) * 1_000

stdout.writeLine "bench_routing_split_iterations=" & $(iterations * patterns.len)
stdout.writeLine "bench_routing_split_duration_ms=" & $splitDurationMs
