import unittest
import strutils

import nim_http/kernel/module
import nim_http/kernel/di

type
  LeafService = ref object of SingletonObj
  HiddenService = ref object of SingletonObj

suite "module graph":
  test "accepts a valid module graph":
    var registry = newModuleRegistry()
    let leaf = newModuleDescriptor(
      name = "LeafModule",
      providers = [LeafService],
      exports = [LeafService]
    )
    let root = newModuleDescriptor(
      name = "RootModule",
      imports = [leaf]
    )

    registry.registerModule(leaf)
    registry.registerModule(root)

    check validateGraph(registry, [root]) == 2

  test "rejects exported providers that are not declared":
    let invalidModule = newModuleDescriptor(
      name = "InvalidModule",
      # HiddenService is intentionally omitted from providers.
      exports = [HiddenService]
    )

    expect(ValueError):
      invalidModule.validate()

  test "rejects circular module imports":
    let second = newModuleDescriptor(
      name = "SecondModule",
      imports = []
    )
    let first = newModuleDescriptor(
      name = "FirstModule",
      imports = [second]
    )
    # Complete the cycle after construction because the descriptors reference each other.
    second.imports = @[first]

    var errorMessage = ""
    try:
      discard validateGraph([first, second])
    except ValueError as exc:
      errorMessage = exc.msg

    check errorMessage.contains("Circular module dependency detected")
    check errorMessage.contains("FirstModule") or errorMessage.contains("SecondModule")
