import os, unittest

import nim_http/tooling/scaffold

proc removeDirIfExists(path: string) =
  if dirExists(path):
    removeDir(path)

suite "phase d scaffolding":
  test "camel case helper normalizes identifier names":
    check toCamelCase("user profile") == "userProfile"
    check toCamelCase("UserProfile") == "userProfile"
    check toCamelCase("user_profile") == "userProfile"

  test "rest starter creates expected files":
    let baseDir = getCurrentDir() / ".tmp-rest-starter"
    removeDirIfExists(baseDir)
    try:
      createStarterProject("rest-api", baseDir)

      check fileExists(baseDir / "src/main.nim")
      check fileExists(baseDir / "src/apps/home/main.nim")
      check fileExists(baseDir / "src/apps/health/main.nim")
      check fileExists(baseDir / "benchmarks/bench.nim")
      check fileExists(baseDir / "tmp_rest_starter.nimble")
    finally:
      removeDirIfExists(baseDir)

  test "resource generator creates module and service files":
    let baseDir = getCurrentDir() / ".tmp-resource-starter"
    removeDirIfExists(baseDir)
    try:
      createDir(baseDir)
      generateResource("User Profile", baseDir)

      check fileExists(baseDir / "src/apps/user_profile/main.nim")
      check fileExists(baseDir / "src/apps/user_profile/module.nim")
      check fileExists(baseDir / "src/apps/user_profile/services/service.nim")
      check fileExists(baseDir / "src/apps/user_profile/services/provider.nim")
    finally:
      removeDirIfExists(baseDir)

  test "modular monolith starter is supported":
    let baseDir = getCurrentDir() / ".tmp-modular-monolith-starter"
    removeDirIfExists(baseDir)
    try:
      createStarterProject("modular-monolith", baseDir)

      check fileExists(baseDir / "src/main.nim")
      check fileExists(baseDir / "src/apps/home/main.nim")
      check fileExists(baseDir / "src/apps/health/main.nim")
      check fileExists(baseDir / "tmp_modular_monolith_starter.nimble")
    finally:
      removeDirIfExists(baseDir)

  test "release preparation stages required docs":
    let baseDir = getCurrentDir() / ".tmp-release-bundle"
    removeDirIfExists(baseDir)
    try:
      createDir(baseDir)
      createDir(baseDir / "docs")
      createDir(baseDir / ".github")
      createDir(baseDir / ".github" / "workflows")

      writeFile(baseDir / "README.md", "# Demo\n")
      writeFile(baseDir / "CHANGELOG.md", "# Changelog\n")
      writeFile(baseDir / "nim_http.nimble", "version = \"0.1.0\"\n")
      writeFile(baseDir / "docs" / "API_INVENTORY.md", "# API\n")
      writeFile(baseDir / "docs" / "COMPATIBILITY_POLICY.md", "# Policy\n")
      writeFile(baseDir / "docs" / "COMPATIBILITY_MATRIX.md", "# Matrix\n")
      writeFile(baseDir / "docs" / "LTS_POLICY.md", "# LTS\n")
      writeFile(baseDir / "docs" / "MIGRATION_GUIDE.md", "# Migration\n")
      writeFile(baseDir / ".github" / "workflows" / "release.yml", "name: Release\n")

      let bundleDir = prepareReleaseArtifacts("0.3.0", baseDir)
      check dirExists(bundleDir)
      check fileExists(bundleDir / "release_manifest.txt")
      check fileExists(bundleDir / "README.md")
      check fileExists(bundleDir / "docs" / "COMPATIBILITY_MATRIX.md")
      check fileExists(bundleDir / ".github" / "workflows" / "release.yml")
    finally:
      removeDirIfExists(baseDir)

  test "release preparation accepts optional v prefix":
    let baseDir = getCurrentDir() / ".tmp-release-bundle-vprefix"
    removeDirIfExists(baseDir)
    try:
      createDir(baseDir)
      createDir(baseDir / "docs")
      createDir(baseDir / ".github")
      createDir(baseDir / ".github" / "workflows")

      writeFile(baseDir / "README.md", "# Demo\n")
      writeFile(baseDir / "CHANGELOG.md", "# Changelog\n")
      writeFile(baseDir / "nim_http.nimble", "version = \"0.1.0\"\n")
      writeFile(baseDir / "docs" / "API_INVENTORY.md", "# API\n")
      writeFile(baseDir / "docs" / "COMPATIBILITY_POLICY.md", "# Policy\n")
      writeFile(baseDir / "docs" / "COMPATIBILITY_MATRIX.md", "# Matrix\n")
      writeFile(baseDir / "docs" / "LTS_POLICY.md", "# LTS\n")
      writeFile(baseDir / "docs" / "MIGRATION_GUIDE.md", "# Migration\n")
      writeFile(baseDir / ".github" / "workflows" / "release.yml", "name: Release\n")

      let bundleDir = prepareReleaseArtifacts("v0.3.0", baseDir)
      check dirExists(bundleDir)
      check fileExists(bundleDir / "release_manifest.txt")
      check dirExists(baseDir / "dist" / "release-0.3.0")
    finally:
      removeDirIfExists(baseDir)

  test "release preparation rejects non semver versions":
    expect(ValueError):
      discard prepareReleaseArtifacts("v0.3", getCurrentDir())

  test "release preparation rejects invalid semver variants":
    expect(ValueError):
      discard prepareReleaseArtifacts("01.2.3", getCurrentDir())
    expect(ValueError):
      discard prepareReleaseArtifacts("1.2.x", getCurrentDir())
    expect(ValueError):
      discard prepareReleaseArtifacts("1.2.3.4", getCurrentDir())
