import macros, asyncdispatch, asynchttpserver, macrocache, tables, sequtils, di, strutils
import guard, re, exception

type BaseController* = ref object of RootObj
  request*: Request
  params*:  TableRef[string, string]     = newTable[string, string]()
  guards*:  TableRef[string, seq[Guard]] = newTable[string, seq[Guard]]()

let controllerRegistry*: TableRef[string, BaseController] = newTable[string, BaseController]()

proc send(this: BaseController, code: HttpCode, data: string) = discard this.request.respond(code, data)

template Ok*        (content): untyped = this.send(Http200, "{\"message\": \"" & content & "\"}")
template BadRequest*(content): untyped = this.send(Http400, "{\"message\": \"" & content & "\"}")
template NoContent* ():        untyped = this.request.respond(Http204)
template Created*(content):    untyped = this.send(Http201, "{\"message\": \"" & content & "\"}")
template Forbidden*(content):  untyped = this.send(Http403, "{\"message\": \"" & content & "\"}")
template NotFound*(content):   untyped = this.send(Http404, "{\"message\": \"" & content & "\"}")

proc invoke*(this: BaseController, handler: auto) =
  let fn = proc (this: BaseController): Future[void] {.closure, async.} = await handler(this)
  discard fn(this)

proc processRequest*(this: BaseController, req: Request): BaseController =
  this.request = req
  return this


type
  # Lưu thông tin meta của route dưới dạng regex pattern
  RoutePattern* = ref object
    raw*:        string
    regex*:      Regex
    paramSegments*: seq[string]

  # Lưu thông tin chi tiết của 1 route
  RouteDetail* = ref object
    httpMethod*: HttpMethod
    pattern*:    RoutePattern
    delegate*:   ControllerDelegate

  # Lưu thông tin của 1 route
  RouteItem* = ref object
    path:     string
    delegate: ControllerDelegate

  # Lưu thông tin của controller
  ControllerDelegate* = ref object
    instance*: BaseController
    handler*:  proc (this: BaseController): Future[void] {.gcsafe, closure.}
    guards*:   seq[Guard]

var routeTree {.threadvar.}: TableRef[string, RouteDetail]
routeTree = newTable[string, RouteDetail]()

# Hàm xử lý request, kiểm tra các guards, middleware, interceptors trước khi thực thi nghiệp vụ ở controller
proc resolve*(this: RouteDetail, request: Request): Future[void] {.async.} =
  if this.delegate.guards.len > 0:
    for guard in this.delegate.guards:
      discard guard.canActivate(request)

  this.delegate.instance.processRequest(request).invoke(this.delegate.handler)

# Lưu thông tin function handler cho request, bao gồm controller instance, guards, handler function
macro `/`*[T: BaseController](ctlClass: typedesc[T], handler: untyped): ControllerDelegate =
  let methodName = $handler
  result         = quote do:
    let hand =
      proc (this: BaseController): Future[void] {.gcsafe, closure.} =
        let ctrl = cast[`ctlClass`](this)
        `handler`(ctrl)
    let guards = (
      if controllerRegistry[$`ctlClass`].guards.hasKey(`methodName` & "*"):
         controllerRegistry[$`ctlClass`].guards[`methodName` & "*"]
      else: @[] 
    )
    ControllerDelegate(
      instance: controllerRegistry[$`ctlClass`],
      handler:  hand,
      guards:   guards
    )

# Lưu thông tin của url path sẽ mapping với Controller xử lý nghiệp vụ
proc `->`*(path: string, delegate: ControllerDelegate): RouteItem =
  RouteItem(path: path, delegate: delegate)  

# Hàm hỗ trợ chuyển đổi url path string sang regex
proc parseToRegex(path: string): (seq[string], string) =
  var 
    regexStr                   = "^"
    paramSegments: seq[string] = @[]
  let parts = path.strip(chars = {'/'}).split("/")
  for part in parts:
    if part.startsWith(":"):
      regexStr.add("/([^/]+)")
      let name = part[1..^1]
      paramSegments.add(name)
    else:
      regexStr.add("/" & part)
  regexStr.add("$")
  return (paramSegments, regexStr)

# Hàm lưu thông tin của url (đã chuyển đổi sang regex pattern), bao gồm params binds
proc parseRoutePattern(pattern: string): (RoutePattern, string) =
  let (paramSegments, regexStr) = parseToRegex(pattern)
  result = (RoutePattern(raw: pattern, regex: re(regexStr), paramSegments: paramSegments), regexStr)

# Đăng ký route
proc register(
  httpMethod: HttpMethod,
  route:      RouteItem
) =
  let (pattern, key) = parseRoutePattern(route.path)
  echo key
  routeTree[key] = RouteDetail(
    httpMethod: httpMethod,
    pattern:    pattern,
    delegate:   route.delegate
  )

# Hàm xử lý request tại tầng router
proc process*(request: Request): Future[void] =
  for _, route in routeTree.pairs:
    if match(request.url.path, route.pattern.regex):
      if route.httpMethod == request.reqMethod:
        var matches = newSeq[string](route.pattern.paramSegments.len + 1)
        if match(request.url.path, route.pattern.regex, matches):
          for i, name in route.pattern.paramSegments:
            route.delegate.instance.params[name] = matches[i]
          return route.resolve(request)
      else: raise METHOD_NOT_ALLOWED()
  raise NOT_FOUND()

template Get*     (route: RouteItem): untyped = register(HttpGet,     route)
template Post*    (route: RouteItem): untyped = register(HttpPost,    route)
template Put*     (route: RouteItem): untyped = register(HttpPut,     route)
template Patch*   (route: RouteItem): untyped = register(HttpPatch,   route)
template Options* (route: RouteItem): untyped = register(HttpOptions, route)
template Delete*  (route: RouteItem): untyped = register(HttpDelete,  route)
template Trace*   (route: RouteItem): untyped = register(HttpTrace,   route)
template Connect* (route: RouteItem): untyped = register(HttpConnect, route)


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
  let guardsTb:   TableRef[string, seq[NimNode]] = newTable[string, seq[NimNode]]()
  let classNameStr: string = $class
  for stmt in body:
    var pragmas: NimNode  = newEmptyNode()
    if stmt.kind == nnkProcDef:
      let procName    = stmt[0]  # Tên hàm
      let generic     = stmt[1]  # Generic params (nếu có)
      let patterns    = stmt[2]  # Pattern params (rarely used)
      let params      = stmt[3]  # Đã patch "this"
      pragmas         = stmt[4]  # Giữ pragmas gốc
      let annotations = stmt[5]  # Annotations
      let procBody    = stmt[6]  # Thân hàm

      for pragma in pragmas:
        if pragma.kind == nnkCall:
          if pragma[0].eqIdent("useGuards"):
            if pragma[1].kind == nnkIdent:
              guardsTb[$procName] = @[pragma[1]]
            else:  
              for brk in pragma[1]:
                let guardIdent = brk
                if not guardsTb.hasKey($procName):
                  guardsTb[$procName] = newSeq[NimNode](pragma[1].len).filterIt(it.len > 0)
                if guardIdent != nil:  
                  guardsTb[$procName].add(brk)
      
      let thisDefined = anyIt(params[1..^1], it[1].kind != nnkEmpty and $it[1] == $BaseController)
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

  let register1: NimNode    = quote do:
    let inst = new `classIdent`
    controllerRegistry[`classNameStr`] = cast[BaseController](inst)
    injector(inst)
  result = newStmtList()
  result.add(outBody)
  result.add(register1)
  for k, guards in guardsTb:
    for guard in guards:
      result.add quote do:
        let guardInst = new `guard`
        if not controllerRegistry[`classNameStr`].guards.hasKey(`k`):
          controllerRegistry[`classNameStr`].guards[`k`] = @[]
        controllerRegistry[`classNameStr`].guards[`k`].add(cast[Guard](guardInst))
  let routeBody:  NimNode = newStmtList()
  for stmt in outBody:
    if stmt.kind == nnkProcDef:
      let procName = stmt[0]  # Tên hàm
      let pragmas  = stmt[4]  # Giữ pragmas gốc
      for pragma in pragmas:
        if pragma.kind == nnkIdent:
          discard # cần triển khai kiểm tra nếu chỉ khai báo là .get. thì mặc định sẽ hiểu path là "/"
        if pragma.kind == nnkCall:
          if pragma[0].eqIdent("get"):
            let procNameStriped = ident(($procName).strip(chars = {'*'}))
            let path = $pragma[1]
            routeBody.add quote do:
              var z: ControllerDelegate =  `class` / `procNameStriped`
              let r2: RouteItem = `path` -> z
              Get(r2)
  result.add(routeBody)

template get*    (path: string = "/") {.pragma.}
template post*   (path: string = "/") {.pragma.}
template put*    (path: string = "/") {.pragma.}
template patch*  (path: string = "/") {.pragma.}
template delete* (path: string = "/") {.pragma.}
template trace*  (path: string = "/") {.pragma.}
template connect*(path: string = "/") {.pragma.}
template options*(path: string = "/") {.pragma.}
template head*   (path: string = "/") {.pragma.}