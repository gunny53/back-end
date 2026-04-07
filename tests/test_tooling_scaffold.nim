import os, unittest

import nim_http/tooling/scaffold

proc removeDirIfExists(path: string) =
  if dirExists(path):
    removeDir(path)

suite "phase d scaffolding":
  test "rest starter creates expected files":
    let baseDir = getCurrentDir() / ".tmp-rest-starter"
    removeDirIfExists(baseDir)

    createStarterProject("rest-api", baseDir)

    check fileExists(baseDir / "src/main.nim")
    check fileExists(baseDir / "src/apps/home/main.nim")
    check fileExists(baseDir / "src/apps/health/main.nim")
    check fileExists(baseDir / "benchmarks/bench.nim")
    check fileExists(baseDir / ("" & toSnakeCase("tmp-rest-starter") & ".nimble"))

    removeDirIfExists(baseDir)

  test "resource generator creates module and service files":
    let baseDir = getCurrentDir() / ".tmp-resource-starter"
    removeDirIfExists(baseDir)
    createDir(baseDir)

    generateResource("User Profile", baseDir)

    check fileExists(baseDir / "src/apps/user_profile/main.nim")
    check fileExists(baseDir / "src/apps/user_profile/module.nim")
    check fileExists(baseDir / "src/apps/user_profile/services/service.nim")
    check fileExists(baseDir / "src/apps/user_profile/services/provider.nim")

    removeDirIfExists(baseDir)
