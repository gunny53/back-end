import sets, tables
import ./di
import ../http/controller

type
  ProviderToken* = object
    name*: string

  ControllerToken* = object
    name*: string

  ModuleDescriptor* = ref object
    ## Ref semantics let modules point at imported module descriptors directly,
    ## including cyclic graphs used in validation tests. Callers should treat
    ## registered descriptors as shared immutable graph nodes after wiring.
    ## The public `imports` field remains mutable only to support graph assembly
    ## and explicit cycle construction in tests before validation runs.
    ## Post-registration mutation is not an intended runtime API; validation
    ## assumes the descriptor graph is stable once registration is complete.
    name*: string
    imports*: seq[ModuleDescriptor]
    providers*: seq[ProviderToken]
    exports*: seq[ProviderToken]
    controllers*: seq[ControllerToken]

  ModuleGraphState = object
    modules: Table[string, ModuleDescriptor]
    visited: HashSet[string]
    active: HashSet[string]

  ModuleRegistry* = object
    descriptors: Table[string, ModuleDescriptor]

proc newModuleDescriptor*(
  name: string,
  imports: openArray[ModuleDescriptor] = [],
  providers: openArray[ProviderToken] = [],
  exports: openArray[ProviderToken] = [],
  controllers: openArray[ControllerToken] = []
): ModuleDescriptor =
  ModuleDescriptor(
    name: name,
    imports: @imports,
    providers: @providers,
    exports: @exports,
    controllers: @controllers
  )

converter toProviderToken*[T: SingletonObj](provider: typedesc[T]): ProviderToken =
  ProviderToken(name: $provider)

converter toControllerToken*[T: BaseController](controller: typedesc[T]): ControllerToken =
  ControllerToken(name: $controller)

proc validate*(descriptor: ModuleDescriptor) =
  if descriptor.isNil:
    raise newException(ValueError, "Cannot validate nil module descriptor")
  if descriptor.name.len == 0:
    raise newException(ValueError, "Module name cannot be empty")

  var providerSet = initHashSet[string]()
  for provider in descriptor.providers:
    if provider.name.len == 0:
      raise newException(ValueError, "Provider name cannot be empty in module " & descriptor.name)
    providerSet.incl(provider.name)

  for controller in descriptor.controllers:
    if controller.name.len == 0:
      raise newException(ValueError, "Controller name cannot be empty in module " & descriptor.name)

  for exportedProvider in descriptor.exports:
    if exportedProvider.name.len == 0:
      raise newException(ValueError, "Exported provider name cannot be empty in module " & descriptor.name)
    if exportedProvider.name notin providerSet:
      raise newException(
        ValueError,
        "Exported provider '" & exportedProvider.name & "' must also be declared in providers for module " & descriptor.name
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
  ## Performs a depth-first walk over the resolved module graph.
  ## `active` tracks the current recursion stack for cycle detection, while
  ## `visited` skips modules whose import subgraphs have already been validated.
  if not state.modules.hasKey(moduleName):
    raise newException(ValueError, "Unknown module in validation state " & moduleName)
  if moduleName in state.active:
    raise newException(ValueError, "Circular module dependency detected at " & moduleName)
  if moduleName in state.visited:
    return

  state.active.incl(moduleName)
  for importedModule in state.modules[moduleName].imports:
    visitModule(state, importedModule.name)
  state.active.excl(moduleName)
  state.visited.incl(moduleName)

proc newModuleGraphState(): ModuleGraphState =
  ModuleGraphState(
    modules: initTable[string, ModuleDescriptor](),
    visited: initHashSet[string](),
    active: initHashSet[string]()
  )

proc validateState(state: var ModuleGraphState): int =
  ## Validates the resolved module graph and returns the number of modules covered.
  ## This checks descriptor integrity, missing imports, self-imports, and cycles.
  for _, descriptor in state.modules:
    descriptor.validate()

  for _, descriptor in state.modules:
    for importedModule in descriptor.imports:
      if importedModule.isNil:
        raise newException(ValueError, "Module " & descriptor.name & " has a nil imported module reference")
      if importedModule.name.len == 0:
        raise newException(ValueError, "Imported module name cannot be empty in module " & descriptor.name)
      if importedModule.name == descriptor.name:
        raise newException(ValueError, "Module " & descriptor.name & " cannot import itself")
      if not state.modules.hasKey(importedModule.name):
        raise newException(
          ValueError,
          "Module " & descriptor.name & " imports unknown module " & importedModule.name
        )

  for _, descriptor in state.modules:
    visitModule(state, descriptor.name)
  result = state.modules.len

proc collectRegisteredModule(
  state: var ModuleGraphState,
  registry: ModuleRegistry,
  descriptor: ModuleDescriptor
) =
  ## Collects a root module and its transitive imports into the validation state.
  ## The traversal is depth-first and stops once a module has already been added.
  if descriptor.isNil:
    raise newException(ValueError, "Root module cannot be nil")
  if descriptor.name.len == 0:
    raise newException(ValueError, "Root module name cannot be empty")
  if state.modules.hasKey(descriptor.name):
    return
  if not registry.descriptors.hasKey(descriptor.name):
    raise newException(ValueError, "Unknown registered module " & descriptor.name)

  let registeredDescriptor = registry.descriptors[descriptor.name]
  state.modules[registeredDescriptor.name] = registeredDescriptor
  for importedModule in registeredDescriptor.imports:
    collectRegisteredModule(state, registry, importedModule)

proc validateGraph*(descriptors: openArray[ModuleDescriptor]): int =
  ## Validates the exact descriptor set passed by the caller and returns the count.
  var state = newModuleGraphState()
  for descriptor in descriptors:
    descriptor.validate()
    if state.modules.hasKey(descriptor.name):
      raise newException(ValueError, "Duplicate module descriptor: " & descriptor.name)
    state.modules[descriptor.name] = descriptor
  result = validateState(state)

proc validateGraph*(registry: ModuleRegistry, rootModules: openArray[ModuleDescriptor]): int =
  ## Validates the requested root modules and only the imports reachable from them.
  var state = newModuleGraphState()
  for rootModule in rootModules:
    collectRegisteredModule(state, registry, rootModule)
  result = validateState(state)
