import tables, macros

type BaseSingleton* = ref object of RootObj

# Singleton CONTAINER toàn cục
let singletonCONTAINER*: TableRef[string, BaseSingleton] = newTable[string, BaseSingleton]()

macro Injectable*(body: untyped): untyped =
  result = newStmtList()
  if body.kind == nnkIdent:
    let bodyType = $body
    result.add quote do:
      let inst = new(`body`)
      singletonCONTAINER["singleton_" & `bodyType`] = inst
  else: discard

template inject*(): BaseSingleton {.pragma.}

template singleton*() {.pragma.}
template transient*() {.pragma.}