import tables, times

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

var readinessChecks = initTable[string, ReadinessCheck]() # Register during bootstrap before serving requests.

proc currentProbeTimestamp(): string =
  now().utc.format("yyyy-MM-dd'T'HH:mm:ss'Z'")

proc clearReadinessChecks*() =
  readinessChecks.clear()

proc registerReadinessCheck*(
  name: string,
  check: proc(): bool {.gcsafe.}
) =
  ## Registers or replaces a readiness check by name.
  ## Intended to be called during application bootstrap before the server starts.
  if name.len == 0:
    raise newException(ValueError, "Readiness check name cannot be empty")
  if check.isNil:
    raise newException(ValueError, "Readiness check handler cannot be nil")

  readinessChecks[name] = ReadinessCheck(name: name, check: check)

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
  var checks: seq[HealthCheckStatus] = @[]
  var isReady = true

  for checkName, readinessEntry in readinessChecks:
    let passed =
      try:
        readinessEntry.check()
      except CatchableError:
        false

    if not passed:
      isReady = false

    checks.add(HealthCheckStatus(
      name: checkName,
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
