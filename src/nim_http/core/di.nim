import tables, macros, asyncdispatch

type BaseSingleton* = ref object of RootObj

# Singleton Container toàn cục
var singletonContainer* {.threadvar.}: Table[string, BaseSingleton]
singletonContainer = initTable[string, BaseSingleton]()

macro RegisterSingletons*(body: untyped): untyped =
  result = newStmtList()
  if body.kind == nnkIdent:
    let bodyType = $body
    result.add quote do:
      let inst = new(`body`)
      singletonContainer["singleton_" & `bodyType`] = new(`body`)
  else: discard

template inject*(): BaseSingleton {.pragma.}
template inject2*(): auto {.pragma.}
macro Get*(path: static[string], body: untyped): untyped =
  result