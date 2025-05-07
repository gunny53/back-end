import tables, macros

type BaseSingleton* = ref object of RootObj

# Singleton controllerRegistry toàn cục
var singletonRegistry* {.threadvar.}: TableRef[string, BaseSingleton]
singletonRegistry = newTable[string, BaseSingleton]()

macro Injectable*(body: untyped): untyped =
  result = newStmtList()
  if body.kind == nnkIdent:
    let bodyType = $body
    result.add quote do: singletonRegistry[`bodyType`] = new(`body`)
  else: discard