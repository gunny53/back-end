import unittest

import nim_http/kernel/module

suite "module graph":
  test "accepts a valid module graph":
    let leaf = newModuleDescriptor(
      name = "LeafModule",
      providers = ["LeafService"],
      exports = ["LeafService"]
    )
    let root = newModuleDescriptor(
      name = "RootModule",
      imports = ["LeafModule"]
    )

    check validateGraph([root, leaf]) == 2

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

    expect(ValueError):
      validateGraph([first, second])
