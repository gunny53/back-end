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

  ModuleRegistry = ref object
    descriptors: Table[string, ModuleDescriptor]

var globalModuleRegistry: ModuleRegistry

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

proc initModuleRegistry() =
  if globalModuleRegistry.isNil:
    globalModuleRegistry = ModuleRegistry(
      descriptors: initTable[string, ModuleDescriptor]()
    )

proc registerModule*(descriptor: ModuleDescriptor) =
  initModuleRegistry()
  descriptor.validate()
  if globalModuleRegistry.descriptors.hasKey(descriptor.name):
    raise newException(ValueError, "Duplicate module descriptor: " & descriptor.name)
  globalModuleRegistry.descriptors[descriptor.name] = descriptor

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

proc validateState(state: var ModuleGraphState) =
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

proc collectRegisteredModule(state: var ModuleGraphState, moduleName: string) =
  initModuleRegistry()
  if moduleName.len == 0:
    raise newException(ValueError, "Root module name cannot be empty")
  if state.modules.hasKey(moduleName):
    return
  if not globalModuleRegistry.descriptors.hasKey(moduleName):
    raise newException(ValueError, "Unknown registered module " & moduleName)

  let descriptor = globalModuleRegistry.descriptors[moduleName]
  state.modules[moduleName] = descriptor
  for importedModule in descriptor.imports:
    collectRegisteredModule(state, importedModule)

proc validateGraph*(descriptors: openArray[ModuleDescriptor]) =
  var state = newModuleGraphState()
  for descriptor in descriptors:
    descriptor.validate()
    if state.modules.hasKey(descriptor.name):
      raise newException(ValueError, "Duplicate module descriptor: " & descriptor.name)
    state.modules[descriptor.name] = descriptor
  validateState(state)

proc validateGraph*(rootModules: openArray[string]) =
  var state = newModuleGraphState()
  for rootModule in rootModules:
    collectRegisteredModule(state, rootModule)
  validateState(state)
