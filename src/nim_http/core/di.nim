import tables, macros

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
      echo "singleton_" & `bodyType`
      singletonContainer["singleton_" & `bodyType`] = inst
  else: discard

template inject*(): BaseSingleton {.pragma.}
macro Get*(path: static[string], body: untyped): untyped =
  result