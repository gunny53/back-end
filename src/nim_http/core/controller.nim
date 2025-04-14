import macros, asyncdispatch, asynchttpserver, macrocache, tables, sequtils, di, strutils

type BaseController* = ref object of RootObj
  request*: Request
  
var controllerRegistry* {.threadvar.}: Table[string, BaseController]
controllerRegistry = initTable[string, BaseController]()

proc send(this: BaseController, code: HttpCode, data: string) = discard this.request.respond(code, data)

template Ok*        (content): untyped = this.send(Http200, "{\"message\": \"" & content & "\"}")
template BadRequest*(content): untyped = this.send(Http400, "{\"message\": \"" & content & "\"}")

proc next*(this: auto, handler: auto): Future[void] =
  return handler(this)

template next*(handler: untyped, typo: typedesc): Future[void] =
  when declared(this):
    this.next(proc (this: BaseController): Future[void] {.gcsafe, closure.} = handler(cast[typo](this)))
  else:
    {.error: "next() must be used inside a method with 'self' or 'this'.".}

proc BindRequest*(this: BaseController, req: Request): BaseController =
  this.request = req
  return this

macro injector(inst: typed): untyped =
  let
    typ     = inst.getTypeInst
    typImpl = typ.getImpl
  result = newStmtList()
  for idef in typImpl[2]:
    for node in idef[2]:
      if node.kind == nnkIdentDefs:
        for fields in node:
          if fields.kind == nnkPragmaExpr:
            for field in fields:
              for pragma in field:
                if pragma.eqident"inject":
                  let fieldNameStr = ($fields[0]).strip(chars = {'*'})
                  let fieldName = ident(fieldNameStr)
                  let fieldTypeStr = $node[1]
                  let fieldType = ident(fieldTypeStr)
                  echo fieldType.kind
                  echo treeRepr node[1]
                  result.add quote do:
                    let rawService = singletonContainer["singleton_" & `fieldTypeStr`]
                    assert rawService != nil
                    let service = cast[`fieldType`](rawService)
                    `inst`.`fieldName` = service
    
macro Controller*(class: typed, basePath: static[string], body: untyped): untyped =
  let outBody:    NimNode = newStmtList()
  let classIdent: NimNode = ident($class)
  for stmt in body:
    if stmt.kind == nnkProcDef:
      let procName:   NimNode = stmt[0]
      let params:     NimNode = stmt[3]
      let returnType: NimNode = stmt[4]
      let bodyStmt:   NimNode = stmt[6]
      
      let thisDefined = anyIt(params[1..^1], it[1].kind != nnkEmpty and $it[1] == "BaseController")
      # Nếu chưa có param nào (chỉ có return type), thì chèn this vào
      if not thisDefined:
        let thisParam: NimNode = newIdentDefs(ident("this"), class)
        let newParams: NimNode = nnkFormalParams.newTree()
        newParams.add(returnType)
        newParams.add(thisParam)
        for i in 2..<params.len:
          newParams.add(params[i])

        let newProc: NimNode = nnkProcDef.newTree(
          procName,
          stmt[1],  # Optional generics
          stmt[2],  # Optional pragma
          newParams,
          returnType,
          stmt[5],  # Optional exceptions
          bodyStmt
        )
        outBody.add(newProc)
      else:
        outBody.add(stmt)
    else:
      outBody.add(stmt)
  let classNameStr: string = $class
  let register: NimNode    = quote do:
    let inst      = new `classIdent`
    controllerRegistry[`classNameStr`] = cast[BaseController](inst)
    injector(inst)

  result = newStmtList()
  result.add(outBody)
  result.add(register)