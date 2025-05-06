import tables, macros

type BaseSingleton* = ref object of RootObj

# Singleton CONTAINER toàn cục
var singletonCONTAINER* {.threadvar.}: TableRef[string, BaseSingleton]
singletonCONTAINER = newTable[string, BaseSingleton]()

macro Injectable*(body: untyped): untyped =
  result = newStmtList()
  if body.kind == nnkIdent:
    let bodyType = $body
    result.add quote do: singletonCONTAINER[`bodyType`] = new(`body`)
  else: discard

# template inject*(): BaseSingleton {.pragma.}

template singleton*() {.pragma.}
template transient*() {.pragma.}