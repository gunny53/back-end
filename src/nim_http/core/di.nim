## Dependency Injection Module
## Enhanced DI container with lifecycle management, inspired by NestJS

import tables, macros, sequtils

type
  SingletonObj* = ref object of RootObj

  # Scope types for dependency lifecycle
  ProviderScope* = enum
    Singleton,    # Single instance shared across application
    Transient,    # New instance created each time
    Request       # Instance per request (future enhancement)

  ProviderMetadata* = object
    scope*: ProviderScope
    instance*: SingletonObj
    factory*: proc(): SingletonObj {.gcsafe.}

  DependencyContainer* = ref object
    providers: TableRef[string, ProviderMetadata]
    circularDeps: seq[string]  # Track for circular dependency detection

# Global singleton registry - thread-local storage
var singletonRegistry* {.threadvar.}: TableRef[string, SingletonObj]
var dependencyContainer* {.threadvar.}: DependencyContainer

# Initialize registry if not already done
proc initRegistry() =
  if singletonRegistry.isNil:
    singletonRegistry = newTable[string, SingletonObj]()
  if dependencyContainer.isNil:
    dependencyContainer = DependencyContainer(
      providers: newTable[string, ProviderMetadata](),
      circularDeps: @[]
    )

# Always initialize on module load
initRegistry()

proc register*[T: SingletonObj](
  t: typedesc[T],
  scope: ProviderScope = Singleton,
  factory: proc(): SingletonObj {.gcsafe.} = nil
) =
  ## Registers a provider with the DI container
  ## For Singleton and Transient scopes, a factory function is required
  initRegistry()
  let key = $t
  
  # Require factory for non-Request scopes to avoid unusable providers
  if scope != Request and factory.isNil:
    raise newException(ValueError, "Factory function required for " & $scope & " scope when registering " & key)
  
  var metadata = ProviderMetadata(scope: scope, factory: factory)
  
  # For singleton scope, create instance immediately
  if scope == Singleton and not factory.isNil:
    metadata.instance = factory()
  
  dependencyContainer.providers[key] = metadata

proc inject*[T: SingletonObj](t: typedesc[T]): T {.gcsafe.} =
  ## Injects a dependency from the DI container
  initRegistry()
  let key = $t
  
  # Check for circular dependencies
  if key in dependencyContainer.circularDeps:
    raise newException(ValueError, "Circular dependency detected for: " & key)
  
  # Try legacy registry first
  if singletonRegistry.hasKey(key):
    return cast[T](singletonRegistry[key])
  
  # Try new container system
  if dependencyContainer.providers.hasKey(key):
    let metadata = dependencyContainer.providers[key]
    
    case metadata.scope:
    of Singleton:
      if not metadata.instance.isNil:
        return cast[T](metadata.instance)
      elif not metadata.factory.isNil:
        # Create singleton instance
        dependencyContainer.circularDeps.add(key)
        let instance = metadata.factory()
        dependencyContainer.circularDeps = dependencyContainer.circularDeps.filterIt(it != key)
        
        # Cache the instance
        var updatedMetadata = metadata
        updatedMetadata.instance = instance
        dependencyContainer.providers[key] = updatedMetadata
        singletonRegistry[key] = instance
        
        return cast[T](instance)
    of Transient:
      if not metadata.factory.isNil:
        dependencyContainer.circularDeps.add(key)
        let instance = metadata.factory()
        dependencyContainer.circularDeps = dependencyContainer.circularDeps.filterIt(it != key)
        return cast[T](instance)
    of Request:
      # Request-scoped will be implemented with request context
      discard
  
  raise newException(ValueError, "Provider not found: " & key)

macro class*(declareClass: untyped, body: untyped): untyped =
  result        = newStmtList()
  let rawClass  = declareClass[1]
  let baseClass = declareClass[2]
  if rawClass.kind == nnkInfix:
    let isExported: bool    = rawClass[0].eqIdent("*")
    let classIdent: NimNode = if isExported: rawClass[1] else: rawClass[0]
    let classDef            = (
      if isExported:
        quote do: 
          type `classIdent`* = ref object of `baseClass` # TODO
      else:  quote do: 
        type `classIdent` = ref object of `baseClass` # TODO
    )
    let classFields        = if isExported: rawClass[2] else: rawClass[1]
    for fieldStmt in classFields:
      if fieldStmt.kind == nnkExprColonExpr:
        let isFieldExport = if fieldStmt[0].kind == nnkPrefix: fieldStmt[0][0].eqIdent("*") else: false
        let fieldName     = (
          if fieldStmt[0].kind == nnkPrefix:
            if isFieldExport: fieldStmt[0][1]
            else: fieldStmt[0][0]
          else: fieldStmt[0]
        )

        # Add fields to class
        let fieldType    = fieldStmt[1]
        let declareField = newIdentDefs(ident($fieldName), ident($fieldType))
        if isExported: declareField[0] = postfix(declareField[0], "*")
        let typeDef  = classDef[0]
        let objectTy = typeDef[2][0]
        if objectTy[2].kind == nnkEmpty:
          objectTy[2] = newNimNode(nnkRecList)
        let typeBody = objectTy[2]
        typeBody.add(declareField)

    result.add quote("@") do:
      @classDef
      @body
    result.add quote do:
      singletonRegistry[$`classIdent`] = new `classIdent`

macro class*(declareClass: untyped): untyped =
  result        = newStmtList()
  let rawClass  = declareClass[1]
  let baseClass = declareClass[2]
  if rawClass.kind == nnkInfix:
    let isExported: bool    = rawClass[0].eqIdent("*")
    let classIdent: NimNode = if isExported: rawClass[1] else: rawClass[0]
    let classDef            = (
      if isExported:
        quote do:
          type `classIdent`* = ref object of `baseClass`
      else:  quote do: 
        type `classIdent` = ref object of `baseClass`
    )
    let classFields        = if isExported: rawClass[2] else: rawClass[1]
    for fieldStmt in classFields:
      if fieldStmt.kind == nnkExprColonExpr:
        let isFieldExport = if fieldStmt[0].kind == nnkPrefix: fieldStmt[0][0].eqIdent("*") else: false
        let fieldName     = (
          if fieldStmt[0].kind == nnkPrefix:
            if isFieldExport: fieldStmt[0][1]
            else: fieldStmt[0][0]
          else: fieldStmt[0]
        )

        # Add fields to class
        let fieldType    = fieldStmt[1]
        let declareField = newIdentDefs(ident($fieldName), ident($fieldType))
        if isExported: declareField[0] = postfix(declareField[0], "*")
        let typeDef  = classDef[0]
        let objectTy = typeDef[2][0]
        if objectTy[2].kind == nnkEmpty:
          objectTy[2] = newNimNode(nnkRecList)
        let typeBody = objectTy[2]
        typeBody.add(declareField)

    result.add quote("@") do:
      @classDef
    result.add quote do:
      singletonRegistry[$`classIdent`] = new `classIdent`      
template singleton*() {.pragma.}