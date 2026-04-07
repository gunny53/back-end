import unittest

import nim_http/kernel/module

suite "module graph":
  test "accepts a valid module graph":
    var validated = false
    let leaf = newModuleDescriptor(
      name = "LeafModule",
      providers = ["LeafService"],
      exports = ["LeafService"]
    )
    let root = newModuleDescriptor(
      name = "RootModule",
      imports = ["LeafModule"]
    )

    validateGraph([root, leaf])
    validated = true
    check validated

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
