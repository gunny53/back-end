import sets, tables

type
  ModuleDescriptor* = object
    name*: string
    imports*: seq[string]
    providers*: seq[string]
    exports*: seq[string]
    controllers*: seq[string]

  ModuleGraphState = object
    modules: Table[string, ModuleDescriptor]
    visited: HashSet[string]
    active: HashSet[string]

  ModuleRegistry* = object
    descriptors: Table[string, ModuleDescriptor]

proc newModuleDescriptor*(
  name: string,
  imports: openArray[string] = [],
  providers: openArray[string] = [],
  exports: openArray[string] = [],
  controllers: openArray[string] = []
): ModuleDescriptor =
  ModuleDescriptor(
    name: name,
    imports: @imports,
    providers: @providers,
    exports: @exports,
    controllers: @controllers
  )

proc validate*(descriptor: ModuleDescriptor) =
  if descriptor.name.len == 0:
    raise newException(ValueError, "Module name cannot be empty")

  var providerSet = initHashSet[string]()
  for provider in descriptor.providers:
    if provider.len == 0:
      raise newException(ValueError, "Provider name cannot be empty in module " & descriptor.name)
    providerSet.incl(provider)

  for controller in descriptor.controllers:
    if controller.len == 0:
      raise newException(ValueError, "Controller name cannot be empty in module " & descriptor.name)

  for exportedProvider in descriptor.exports:
    if exportedProvider.len == 0:
      raise newException(ValueError, "Exported provider name cannot be empty in module " & descriptor.name)
    if exportedProvider notin providerSet:
      raise newException(
        ValueError,
        "Exported provider '" & exportedProvider & "' must also be declared in providers for module " & descriptor.name
      )

proc newModuleRegistry*(): ModuleRegistry =
  ModuleRegistry(
    descriptors: initTable[string, ModuleDescriptor]()
  )

proc registerModule*(registry: var ModuleRegistry, descriptor: ModuleDescriptor) =
  descriptor.validate()
  if registry.descriptors.hasKey(descriptor.name):
    raise newException(ValueError, "Duplicate module descriptor: " & descriptor.name)
  registry.descriptors[descriptor.name] = descriptor

proc visitModule(state: var ModuleGraphState, moduleName: string) =
  if moduleName in state.active:
    raise newException(ValueError, "Circular module dependency detected at " & moduleName)
  if moduleName in state.visited:
    return

  state.active.incl(moduleName)
  for importedModule in state.modules[moduleName].imports:
    visitModule(state, importedModule)
  state.active.excl(moduleName)
  state.visited.incl(moduleName)

proc newModuleGraphState(): ModuleGraphState =
  ModuleGraphState(
    modules: initTable[string, ModuleDescriptor](),
    visited: initHashSet[string](),
    active: initHashSet[string]()
  )

proc validateState(state: var ModuleGraphState): int =
  for _, descriptor in state.modules:
    descriptor.validate()

  for _, descriptor in state.modules:
    for importedModule in descriptor.imports:
      if importedModule.len == 0:
        raise newException(ValueError, "Imported module name cannot be empty in module " & descriptor.name)
      if importedModule == descriptor.name:
        raise newException(ValueError, "Module " & descriptor.name & " cannot import itself")
      if not state.modules.hasKey(importedModule):
        raise newException(
          ValueError,
          "Module " & descriptor.name & " imports unknown module " & importedModule
        )

  for _, descriptor in state.modules:
    visitModule(state, descriptor.name)
  result = state.modules.len

proc collectRegisteredModule(
  state: var ModuleGraphState,
  registry: ModuleRegistry,
  moduleName: string
) =
  if moduleName.len == 0:
    raise newException(ValueError, "Root module name cannot be empty")
  if state.modules.hasKey(moduleName):
    return
  if not registry.descriptors.hasKey(moduleName):
    raise newException(ValueError, "Unknown registered module " & moduleName)

  let descriptor = registry.descriptors[moduleName]
  state.modules[moduleName] = descriptor
  for importedModule in descriptor.imports:
    collectRegisteredModule(state, registry, importedModule)

proc validateGraph*(descriptors: openArray[ModuleDescriptor]): int =
  var state = newModuleGraphState()
  for descriptor in descriptors:
    descriptor.validate()
    if state.modules.hasKey(descriptor.name):
      raise newException(ValueError, "Duplicate module descriptor: " & descriptor.name)
    state.modules[descriptor.name] = descriptor
  result = validateState(state)

proc validateGraph*(registry: ModuleRegistry, rootModules: openArray[string]): int =
  var state = newModuleGraphState()
  for rootModule in rootModules:
    collectRegisteredModule(state, registry, rootModule)
  result = validateState(state)
