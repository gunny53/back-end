## Response-construction + JSON-serialisation baseline benchmark
## Phase A — proxy for hello-endpoint and JSON-endpoint throughput

import times, json, strutils

# ──────────────────────────────────────────────────────────────
# Simulate the allocations that happen on every response:
#   1. Build a JSON payload (hello-world tier and object tier)
#   2. Serialise to string
#   3. Build standard response headers string
#   4. Concatenate status line + headers + body (HTTP/1.1 wire format)
# ──────────────────────────────────────────────────────────────

const helloBody  = """{"message":"Hello, World!"}"""
const jsonObject = """{"id":1,"name":"Alice","email":"alice@example.com","active":true}"""
const dateHeader = "Tue, 01 Jan 2026 00:00:00 GMT"

const iterations = 100_000

# ── Hello-string construction ─────────────────────────────────
let helloStart = cpuTime()
for _ in 0 ..< iterations:
  let headers =
    "HTTP/1.1 200 OK\r\n" &
    "Content-Type: application/json\r\n" &
    "Content-Length: " & $helloBody.len & "\r\n" &
    "Date: " & dateHeader & "\r\n" &
    "Connection: keep-alive\r\n" &
    "X-Powered-By: NimHTTP\r\n\r\n"
  discard headers & helloBody
let helloDurationMs = (cpuTime() - helloStart) * 1_000

stdout.writeLine "bench_hello_iterations=" & $iterations
stdout.writeLine "bench_hello_duration_ms=" & $helloDurationMs

# ── JSON object parse + serialise round-trip ─────────────────
let jsonStart = cpuTime()
for _ in 0 ..< iterations:
  let node = parseJson(jsonObject)
  discard $node
let jsonDurationMs = (cpuTime() - jsonStart) * 1_000

stdout.writeLine "bench_json_iterations=" & $iterations
stdout.writeLine "bench_json_duration_ms=" & $jsonDurationMs

# ── %* JSON node construction (typical handler pattern) ──────
let buildStart = cpuTime()
for i in 0 ..< iterations:
  let node = %*{"id": i, "name": "user" & $i, "active": true}
  discard $node
let buildDurationMs = (cpuTime() - buildStart) * 1_000

stdout.writeLine "bench_json_build_iterations=" & $iterations
stdout.writeLine "bench_json_build_duration_ms=" & $buildDurationMs
