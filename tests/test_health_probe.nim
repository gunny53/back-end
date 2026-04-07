import unittest, strutils

import nim_http/platform/health

proc isValidHealthProbeTimestamp(value: string): bool =
  if value.len != 20:
    return false
  if value[4] != '-' or value[7] != '-' or value[10] != 'T':
    return false
  if value[13] != ':' or value[16] != ':' or value[19] != 'Z':
    return false

  for index, ch in value:
    if index in [4, 7, 10, 13, 16, 19]:
      continue
    if not ch.isDigit():
      return false

  true

suite "health probes":
  setup:
    clearReadinessChecks()

  test "liveness probe reports alive status":
    let probe = livenessProbe("TestService")

    check probe.status == "alive"
    check probe.probe == "liveness"
    check probe.service == "TestService"
    check probe.checks.len == 0
    check isValidHealthProbeTimestamp(probe.timestamp)

  test "readiness probe aggregates registered checks":
    registerReadinessCheck("module_graph", proc(): bool {.gcsafe.} = true)
    registerReadinessCheck("configuration", proc(): bool {.gcsafe.} = false)

    let probe = readinessProbe("TestService")

    check probe.status == "not_ready"
    check probe.probe == "readiness"
    check probe.service == "TestService"
    check probe.checks.len == 2
    check isValidHealthProbeTimestamp(probe.timestamp)

  test "duplicate readiness check names are updated in place":
    registerReadinessCheck("module_graph", proc(): bool {.gcsafe.} = false)
    registerReadinessCheck("module_graph", proc(): bool {.gcsafe.} = true)

    let probe = readinessProbe("TestService")

    check probe.status == "ready"
    check probe.checks.len == 1
    check probe.checks[0].name == "module_graph"
    check probe.checks[0].status == "ready"

  test "readiness checks cannot be mutated after freeze":
    registerReadinessCheck("module_graph", proc(): bool {.gcsafe.} = true)
    freezeReadinessChecks()

    expect(ValueError):
      registerReadinessCheck("configuration", proc(): bool {.gcsafe.} = true)
