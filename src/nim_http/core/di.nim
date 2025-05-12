import tables, macros

type SingletonObj* = ref object of RootObj

# Singleton controllerRegistry toàn cục
var singletonRegistry* {.threadvar.}: TableRef[string, SingletonObj]
singletonRegistry = newTable[string, SingletonObj]()

proc inject*[T: SingletonObj](t: typedesc[T]): T {.gcsafe.} = cast[T](singletonRegistry[$t])

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