import controller, asynchttpserver, tables, sequtils, macros, macrocache, asyncdispatch

type
  HandlerFn*    = proc (this: BaseController): Future[system.void] {.gcsafe.}
  RouteHandler* = object
    ctlInst*:   BaseController
    handlerFn*: HandlerFn
  Route* = object
    path*:       string 
    httpMethod*: HttpMethod
    handler*:    RouteHandler

var routerTable* {.threadvar.}: Table[string, Route]
routerTable = initTable[string, Route]()

macro RegRoute(path: static[string], httpMethod: HttpMethod, body: untyped): untyped =
  let outBody:    NimNode = newStmtList()
  let stmt = body[0]
  if stmt.kind == nnkProcDef:
    let procName:   NimNode = stmt[0]
    let params:     NimNode = stmt[3]
    let returnType: NimNode = stmt[4]
    let bodyStmt:   NimNode = stmt[6]
    
    # Kiểm tra xem có cần chèn `this` vào params không
    let thisDefined = anyIt(params[1..^1], it[1].kind != nnkEmpty and $it[1] == "BaseController")
    
    if not thisDefined:
      let thisParam: NimNode = newIdentDefs(ident("this"), getTypeInst(BaseController))
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

  # Tạo key cho route
  let key = $httpMethod & " " & path
  
  # Đảm bảo handlerFn là thủ tục đúng kiểu
  result = newStmtList()
  result.add(quote do:
    routerTable[`key`] = Route(
      path: `path`,
      httpMethod: `httpMethod`,
      handler: RouteHandler(
        ctlInst: BaseController(),
        handlerFn: proc (this: BaseController): Future[system.void] {.closure.} =
          `stmt[0]`
      )
    )
  )
  echo treeRepr outBody
  result.add(outBody)

macro Get*    (path: static[string], body: untyped): untyped = quote do: RegRoute(`path`, HttpGet,     `body`)
macro Post*   (path: static[string], body: untyped): untyped = quote do: RegRoute(`path`, HttpPost,    `body`)
macro Put*    (path: static[string], body: untyped): untyped = quote do: RegRoute(`path`, HttpPut,     `body`)
macro Delete* (path: static[string], body: untyped): untyped = quote do: RegRoute(`path`, HttpDelete,  `body`)
macro Patch*  (path: static[string], body: untyped): untyped = quote do: RegRoute(`path`, HttpPatch,   `body`)
macro Options*(path: static[string], body: untyped): untyped = quote do: RegRoute(`path`, HttpOptions, `body`)
