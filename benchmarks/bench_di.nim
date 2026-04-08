## DI container registration + injection baseline benchmark
## Phase A — hot-path baseline for the dependency injection layer

import times
import nim_http/kernel/di

# ──────────────────────────────────────────────────────────────
# Declare a hierarchy of singleton services with explicit
# factory functions, matching a typical application graph.
# ──────────────────────────────────────────────────────────────
type
  BenchConfigService    = ref object of SingletonObj
  BenchLoggerService    = ref object of SingletonObj
  BenchUserRepository   = ref object of SingletonObj
  BenchUserService      = ref object of SingletonObj
  BenchPostRepository   = ref object of SingletonObj
  BenchPostService      = ref object of SingletonObj

# Registration phase — happens once at startup
register(BenchConfigService, Singleton,
  proc(): SingletonObj {.gcsafe.} = BenchConfigService())
register(BenchLoggerService, Singleton,
  proc(): SingletonObj {.gcsafe.} = BenchLoggerService())
register(BenchUserRepository, Singleton,
  proc(): SingletonObj {.gcsafe.} = BenchUserRepository())
register(BenchUserService, Singleton,
  proc(): SingletonObj {.gcsafe.} = BenchUserService())
register(BenchPostRepository, Singleton,
  proc(): SingletonObj {.gcsafe.} = BenchPostRepository())
register(BenchPostService, Singleton,
  proc(): SingletonObj {.gcsafe.} = BenchPostService())

const iterations = 50_000

# ── inject benchmark (singleton cache — no factory call) ─────
let injectStart = cpuTime()
for _ in 0 ..< iterations:
  discard inject(BenchConfigService)
  discard inject(BenchLoggerService)
  discard inject(BenchUserRepository)
  discard inject(BenchUserService)
  discard inject(BenchPostRepository)
  discard inject(BenchPostService)
let injectDurationMs = (cpuTime() - injectStart) * 1_000

stdout.writeLine "bench_di_inject_services=6"
stdout.writeLine "bench_di_inject_iterations=" & $(iterations * 6)
stdout.writeLine "bench_di_inject_duration_ms=" & $injectDurationMs
