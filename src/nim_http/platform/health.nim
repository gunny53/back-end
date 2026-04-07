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

var readinessChecks = initTable[string, ReadinessCheck]()

proc currentProbeTimestamp(): string =
  now().utc.format("yyyy-MM-dd'T'HH:mm:ss'Z'")

proc clearReadinessChecks*() =
  readinessChecks.clear()

proc registerReadinessCheck*(
  name: string,
  check: proc(): bool {.gcsafe.}
) =
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
  var checks: seq[HealthCheckStatus] = @[]
  var isReady = true

  for _, readinessEntry in readinessChecks:
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
