import macros, asyncdispatch, asynchttpserver, macrocache, tables, sequtils, di, strutils

type BaseController* = ref object of RootObj
  request*: Request
  params*:  Table[string, string] = initTable[string, string]()

var controllerRegistry* {.threadvar.}: Table[string, BaseController]
controllerRegistry = initTable[string, BaseController]()

proc send(this: BaseController, code: HttpCode, data: string) = discard this.request.respond(code, data)

template Ok*        (content): untyped = this.send(Http200, "{\"message\": \"" & content & "\"}")
template BadRequest*(content): untyped = this.send(Http400, "{\"message\": \"" & content & "\"}")

proc invoke*(this: BaseController, handler: auto): BaseController =
  let fn = proc (this: BaseController): Future[void] {.gcsafe, closure, async.} = await handler(this)
  discard fn(this)
  return this

proc finallize*(this: BaseController) =
  this.request.reset()

proc processRequest*(this: BaseController, req: Request): BaseController =
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
                  let fieldName    = ident(fieldNameStr)
                  let fieldTypeStr = $node[1]
                  let fieldType    = ident(fieldTypeStr)
                  result.add quote do:
                    let rawService     = singletonContainer["singleton_" & `fieldTypeStr`]
                    let service        = cast[`fieldType`](rawService)
                    `inst`.`fieldName` = service

macro Controller*(class: typed, body: untyped): untyped =
  let outBody:    NimNode = newStmtList()
  let classIdent: NimNode = ident($class)
  for stmt in body:
    if stmt.kind == nnkProcDef:
      let procName    = stmt[0]  # Tên hàm
      let generic     = stmt[1]  # Generic params (nếu có)
      let patterns    = stmt[2]  # Pattern params (rarely used)
      let params      = stmt[3]  # Đã patch "this"
      let pragmas     = stmt[4]  # Giữ pragmas gốc
      let annotations = stmt[5]  # Annotations
      let procBody    = stmt[6]  # Thân hàm

      for pragma in pragmas:
        echo pragma.treeRepr

      let thisDefined = anyIt(params[1..^1], it[1].kind != nnkEmpty and $it[1] == "BaseController")
      # Nếu chưa có param nào (chỉ có return type), thì chèn this vào
      if not thisDefined:
        let thisParam = newIdentDefs(ident("this"), class)
        let newParams = nnkFormalParams.newTree(params[0], thisParam)
        for i in 2..<params[0].len:
          newParams.add(params[0][i])

        let newProc: NimNode = nnkProcDef.newTree(
          procName,     # Tên hàm
          generic,      # Generic params (nếu có)
          patterns,     # Pattern params (rarely used)
          newParams,    # Đã patch "this"
          pragmas,      # Giữ pragmas gốc
          annotations,  # Annotations
          procBody      # Thân hàm
        )
        outBody.add(newProc)
      else:
        outBody.add(stmt)
    else:
      outBody.add(stmt)
  let classNameStr: string = $class
  let register: NimNode    = quote do:
    let inst = new `classIdent`
    controllerRegistry[`classNameStr`] = cast[BaseController](inst)
    injector(inst)

  result = newStmtList()
  result.add(outBody)
  result.add(register)