import unittest
import strutils

import nim_http/kernel/module

suite "module graph":
  test "accepts a valid module graph":
    var registry = newModuleRegistry()
    let leaf = newModuleDescriptor(
      name = "LeafModule",
      providers = ["LeafService"],
      exports = ["LeafService"]
    )
    let root = newModuleDescriptor(
      name = "RootModule",
      imports = ["LeafModule"]
    )

    registry.registerModule(leaf)
    registry.registerModule(root)

    check validateGraph(registry, ["RootModule"]) == 2

  test "rejects exported providers that are not declared":
    let invalidModule = newModuleDescriptor(
      name = "InvalidModule",
      exports = ["MissingProvider"]
    )

    expect(ValueError):
      invalidModule.validate()

  test "rejects circular module imports":
    let first = newModuleDescriptor(
      name = "FirstModule",
      imports = ["SecondModule"]
    )
    let second = newModuleDescriptor(
      name = "SecondModule",
      imports = ["FirstModule"]
    )

    var errorMessage = ""
    try:
      discard validateGraph([first, second])
    except ValueError as exc:
      errorMessage = exc.msg

    check errorMessage.contains("Circular module dependency detected")
    check errorMessage.contains("FirstModule") or errorMessage.contains("SecondModule")
