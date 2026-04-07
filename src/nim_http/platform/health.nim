## Health probe utilities for liveness and readiness endpoints.
## Readiness checks are registered during application bootstrap, then frozen
## before the HTTP server begins serving requests, so probe reads observe a
## stable snapshot instead of mutating shared state at runtime.

import sequtils, tables, times

type
  HealthCheckStatus* = ref object
    name*: string
    status*: string

  HealthProbe* = ref object
    status*: string
    probe*: string
    service*: string
    timestamp*: string
    checks*: seq[HealthCheckStatus]

  ReadinessCheck = object
    name: string
    check: proc(): bool {.gcsafe.}

var readinessChecks = initTable[string, ReadinessCheck]()
var frozenReadinessChecks: seq[ReadinessCheck] = @[]
var readinessChecksFrozen = false

proc currentProbeTimestamp(): string =
  ## Emit an ISO-like UTC timestamp using literal `T` and `Z` separators.
  now().utc.format("yyyy-MM-dd'T'HH:mm:ss'Z'")

proc clearReadinessChecks*() =
  readinessChecks.clear()
  frozenReadinessChecks.setLen(0)
  readinessChecksFrozen = false

proc registerReadinessCheck*(
  name: string,
  check: proc(): bool {.gcsafe.}
) =
  ## Registers or replaces a readiness check by name.
  ## Intended to be called during application bootstrap before the server starts.
  if readinessChecksFrozen:
    raise newException(ValueError, "Readiness checks are frozen after bootstrap")
  if name.len == 0:
    raise newException(ValueError, "Readiness check name cannot be empty")
  if check.isNil:
    raise newException(ValueError, "Readiness check handler cannot be nil")

  readinessChecks[name] = ReadinessCheck(name: name, check: check)

proc freezeReadinessChecks*() =
  ## Freezes the readiness registry after bootstrap to avoid runtime mutation.
  if readinessChecksFrozen:
    return

  frozenReadinessChecks = @[]
  for _, readinessEntry in readinessChecks:
    frozenReadinessChecks.add(readinessEntry)
  readinessChecksFrozen = true

proc livenessProbe*(service: string = "NimHTTP Framework"): HealthProbe =
  HealthProbe(
    status: "alive",
    probe: "liveness",
    service: service,
    timestamp: currentProbeTimestamp(),
    checks: @[]
  )

proc readinessProbe*(service: string = "NimHTTP Framework"): HealthProbe =
  ## Builds the current readiness report from registered checks.
  ## When no explicit checks are registered, the probe returns a synthetic
  ## `startup=ready` check so orchestration endpoints still have a stable payload.
  ## This fallback only means "no custom readiness checks were configured".
  var checks: seq[HealthCheckStatus] = @[]
  var isReady = true

  let activeChecks =
    if readinessChecksFrozen:
      frozenReadinessChecks
    else:
      toSeq(readinessChecks.values)

  for readinessEntry in activeChecks:
    let passed =
      try:
        readinessEntry.check()
      except CatchableError:
        false

    if not passed:
      isReady = false

    checks.add(HealthCheckStatus(
      name: readinessEntry.name,
      status: if passed: "ready" else: "not_ready"
    ))

  if checks.len == 0:
    checks.add(HealthCheckStatus(
      name: "startup",
      status: "ready"
    ))

  HealthProbe(
    status: if isReady: "ready" else: "not_ready",
    probe: "readiness",
    service: service,
    timestamp: currentProbeTimestamp(),
    checks: checks
  )
