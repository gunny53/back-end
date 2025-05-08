import tables, macros

type SingletonObj* = ref object of RootObj

# Singleton controllerRegistry toàn cục
var singletonRegistry* {.threadvar.}: TableRef[string, SingletonObj]
singletonRegistry = newTable[string, SingletonObj]()

macro singleton*(classT, body: untyped): untyped =
  result        = newStmtList()
  let class     = if classT.kind == nnkInfix: classT[1] else: classT
  let baseClass = if classT.len < 2: ident("SingletonObj") else: classT[2]
  let classDef  = quote do:
    type `class`*               = ref object of `baseClass`
  echo treeRepr classT
  
  for stmt in body:
    echo stmt.kind
    echo "vc"
    if stmt.kind == nnkAsgn:
      let fields = stmt
      echo treeRepr fields
      classDef.insert(1, quote("@") do: @fields)
      
  dumpTree classDef
  result.add quote("@") do:
    @classDef
    @body
  result.add quote do:
    singletonRegistry[$`class`] = new(`class`)