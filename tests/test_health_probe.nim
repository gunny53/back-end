import unittest, strutils

import nim_http/platform/health

suite "health probes":
  setup:
    clearReadinessChecks()

  test "liveness probe reports alive status":
    let probe = livenessProbe("TestService")

    check probe.status == "alive"
    check probe.probe == "liveness"
    check probe.service == "TestService"
    check probe.checks.len == 0
    check probe.timestamp.contains("T")

  test "readiness probe aggregates registered checks":
    registerReadinessCheck("module_graph", proc(): bool {.gcsafe.} = true)
    registerReadinessCheck("configuration", proc(): bool {.gcsafe.} = false)

    let probe = readinessProbe("TestService")

    check probe.status == "not_ready"
    check probe.probe == "readiness"
    check probe.service == "TestService"
    check probe.checks.len == 2
    check probe.timestamp.contains("T")

  test "duplicate readiness check names are updated in place":
    registerReadinessCheck("module_graph", proc(): bool {.gcsafe.} = false)
    registerReadinessCheck("module_graph", proc(): bool {.gcsafe.} = true)

    let probe = readinessProbe("TestService")

    check probe.status == "ready"
    check probe.checks.len == 1
    check probe.checks[0].name == "module_graph"
    check probe.checks[0].status == "ready"
