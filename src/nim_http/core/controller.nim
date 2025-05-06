import macros, asyncdispatch, asynchttpserver, macrocache, tables, sequtils, di, strutils, utils, uri, json
import guard, re, exception, response, sugar

# Định nghĩa kiểu của 1 controller cơ bản
# BaseController là lớp cơ sở cho các controller khác, chứa các thuộc tính và phương thức chung
type BaseController* = ref object of RootObj
  # Đối tượng Request đại diện cho HTTP request
  request*: Request
  # Bảng lưu trữ các tham số của request (path, params binds)
  params*:  TableRef[string, string]     = newTable[string, string]()
  # Bảng lưu trữ các guards cho từng phương thức
  guards*:  TableRef[string, seq[Guard]] = newTable[string, seq[Guard]]()
  isHtml: bool # TODO làm 1 response header content type để trả về kiểu tương ứng
  response: Response = Response()

# Định nghĩa các pragma cho param (các loại tham số trong controller)
type ParamPragma = enum
  body, query, param

# Bảng lưu các inst controller theo tên
let CONTAINER: TableRef[string, BaseController] = newTable[string, BaseController]()

# Hàm gửi response cho client, trả về status code và dữ liệu
proc send(this: BaseController, code: HttpCode, data: string): void = discard this.request.respond(code, data)

# Các template tương ứng với các status code thông dụng
template Http200*(content): untyped = this.response.send(Http200, content)
template Http400*(content): untyped = this.response.send(Http400, content)
template Http204*():        untyped = this.request.respond(Http204)
template Http201*(content): untyped = this.response.send(Http201, content)
template Http403*(content): untyped = this.response.send(Http403, content)
template Http404*(content): untyped = this.response.send(Http404, content)

# Hàm xử lý nghiệp vụ của controller khi đã vượt qua các tầng xác thực (guards)
proc invoke*(this: BaseController, handler: auto): Future[void] =
  let fn = proc (this: BaseController): Future[void] {.closure, async.} = handler(this)
  return fn(this)

# Hàm gắn request vào controller
proc processRequest*(this: BaseController, req: Request): BaseController =
  this.request          = req
  this.response.request = req
  return this

# Định nghĩa kiểu RoutePattern dùng để lưu trữ thông tin pattern của route
# Mỗi route có thể có tham số động (parameter) trong URL, đây là cách xử lý những tham số đó.
type
  # Lưu thông tin meta của route dưới dạng regex pattern
  RoutePattern* = ref object
    raw*:           string      # Đường dẫn gốc của route
    regex*:         Regex       # Biểu thức chính quy dùng để so khớp URL
    paramSegments*: seq[string] # Các tham số động trong đường dẫn

  # Lưu thông tin chi tiết của 1 route
  RouteDetail* = ref object
    httpMethod*: HttpMethod         # Phương thức HTTP (GET, POST, etc.)
    pattern*:    RoutePattern       # Pattern của route
    delegate*:   ControllerDelegate # Hàm handler xử lý request cho route

  # Lưu thông tin của 1 route
  RouteItem* = ref object
    path:     string             # Đường dẫn của route
    delegate: ControllerDelegate # Delegate cho route (controller + handler)

  # Lưu thông tin của controller
  ControllerDelegate* = ref object
    instance*: BaseController                                                # Instance của controller
    handler*:  proc (this: BaseController): Future[void] {.gcsafe, closure.} # Hàm xử lý request
    guards*:   seq[Guard]                                                    # Các guards áp dụng cho phương thức

# Lưu trữ các route trong bộ nhớ
var routeTree {.threadvar.}: TableRef[string, RouteDetail]
routeTree = newTable[string, RouteDetail]()

# Hàm xử lý request, kiểm tra các guards, middleware, interceptors trước khi thực thi nghiệp vụ ở controller
proc resolve*(this: RouteDetail, request: Request): Future[void] =
  if this.delegate.guards.len > 0:
    for guard in this.delegate.guards:
      discard guard.canActivate(request)
  this.delegate.instance.processRequest(request).invoke(this.delegate.handler)

# Lưu thông tin function handler cho request, bao gồm controller instance, guards, handler function
macro collect[T: BaseController](ctlClass: typedesc[T], handler: untyped): ControllerDelegate =
  let methodName = $handler
  result         = quote do:
    # Ép kiểu về kiểu gốc
    let hand = proc (this: BaseController): Future[void] {.gcsafe, closure.} =
      let ctrl = cast[`ctlClass`](this)
      `handler`(ctrl)
    # Phát hiện các guards và lưu vào bộ nhớ quản lý guards của instance controller
    let guards = (
      if CONTAINER[$`ctlClass`].guards.hasKey(`methodName`):
         CONTAINER[$`ctlClass`].guards[`methodName`]
      else: @[] 
    )
    ControllerDelegate(
      instance: CONTAINER[$`ctlClass`],
      handler:  hand,
      guards:   guards
    )

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
proc register(httpMethod: HttpMethod, route: RouteItem) =
  let (pattern, key) = parseRoutePattern(route.path)
  routeTree[key]     = RouteDetail(
    httpMethod: httpMethod,
    pattern:    pattern,
    delegate:   route.delegate
  )

# Hàm xử lý request tại tầng router
proc process*(request: Request): Future[void] {.async, gcsafe.} =
  for _, route in routeTree.pairs:
    if match(request.url.path, route.pattern.regex):
      if route.httpMethod == request.reqMethod:
        var matches = newSeq[string](route.pattern.paramSegments.len + 1)
        if match(request.url.path, route.pattern.regex, matches):
          for i, name in route.pattern.paramSegments:
            route.delegate.instance.params[name] = matches[i]
          await route.resolve(request)
      else: raise METHOD_NOT_ALLOWED()
  raise NOT_FOUND()

# Hàm parse bind param
proc parseParamStmt(identName: NimNode, identNameStr: string, identType: NimNode): NimNode =
  let identTypeStr = $identType
  let body         = newStmtList()
  case identTypeStr
  of $int, $int32, $int64:
    body.add quote do: parseInt(this.params[`identNameStr`])
  of $float, $float32, $float64:
    body.add quote do: parseFloat(this.params[`identNameStr`])
  of $bool:
    body.add quote do: parseBool(this.params[`identNameStr`])
  else: body.add quote do: this.params[`identNameStr`]
  result = quote do:
    let `identName` = (
      try:   `body`
      except: raise BAD_REQUEST()
    )
# Hàm parse query
proc parseQueryStmt(identName: NimNode, identNameStr: string, identType: NimNode, defaultVal: NimNode): NimNode =
  result = quote do:
    let `identName`: `identType` = this.request.url.query
      .split("&")
      .mapIt(it.split("=", maxsplit = 1))
      .filterIt(it.len == 2 and it[0] == `identNameStr`)
      .mapIt(decodeUrl(it[1]))
      .headOption()
      .flatMap(parseOrNone[`identType`]).getOrElse(`defaultVal`)
# Hàm parse raw body to Dto class
proc parseBodyStmt(identName: NimNode, identNameStr: string, identType: NimNode): NimNode =
  result = quote do:
    let `identName`: `identType` = (
      try:    to(parseJson(this.request.body), `identType`)
      except: raise BAD_REQUEST()
    )

proc registerGuard(className: string, procName: string, guardType: typedesc[Guard]) =
  let guardInst = new guardType
  if not CONTAINER[className].guards.hasKey(procName):
    CONTAINER[className].guards[procName] = @[]
  CONTAINER[className].guards[procName].add(cast[Guard](guardInst))

# Định nghĩa Controller
macro Controller*(classT, body: untyped): untyped =
  result = newStmtList()
  let class = 
    if classT.kind == nnkBracketExpr: ident($classT[0])
    else:                             ident($classT)
  let classDef = quote do:
    type `class` = ref object of BaseController    
  result.add quote("@") do: @classDef
  let outBody:      NimNode = newStmtList()
  let classIdent:   NimNode = ident($class)
  let classNameStr: string  = $class
  let metaProcSecion        = newStmtList()
  # Định nghĩa các meta proc
  metaProcSecion.add quote do:
    proc inject[T: BaseSingleton](t: typedesc[T]): T {.gcsafe.} = cast[T](singletonCONTAINER[$t])
  for stmt in body:
    echo treeRepr stmt
    if stmt.kind == nnkProcDef:
      let procName         = stmt[0]  # Tên hàm
      let generic          = stmt[1]  # Generic params (nếu có)
      let patterns         = stmt[2]  # Pattern params (rarely used)
      let params           = stmt[3]  # Đã patch "this"
      let pragmas          = stmt[4]  # Giữ pragmas gốc
      let annotations      = stmt[5]  # Annotations
      let procBodyOriginal = stmt[6]  # Thân hàm
      let thisDefined      = anyIt(params[1..^1], it[1].kind != nnkEmpty and $it[1] == $BaseController)
      let procBodyNew      = newStmtList()
      # Nếu chưa có param nào (chỉ có return type), thì chèn this vào
      if not thisDefined:
        let thisParam = newIdentDefs(ident("this"), class)
        let newParams = nnkFormalParams.newTree(params[0], thisParam)
        for param in params:
          if param.kind != nnkEmpty:
            if param.kind == nnkIdentDefs:
              if param[0].kind == nnkPragmaExpr:
                let identName  = param[0][0]        # Tên biến
                let identType  = param[1]           # Kiểu biến
                let pragmaNode = param[0][1]
                # Bước 1: tạo khai báo biến không khởi tạo
                let defaultVal = case $identType:
                  of   $int, $int32, $int64, $float, $float32, $float64: newLit(0)
                  of   $string: newStrLitNode("")
                  else: newNilLit()
                # Bước 1.1: Khởi tạo default value cho các params của proc, tránh báo lỗi compile 
                let remakeParamWithDefaulValue = newIdentDefs(ident($identName), ident($identType), defaultVal)
                newParams.add(remakeParamWithDefaulValue)
                # Bước 2: Kiểm tra các prama của param và gán giá trị
                let identNameStr = $identName
                if pragmaNode.len > 0:
                  let pragmaNodeStr = $pragmaNode[0]
                  procBodyNew.add case pragmaNodeStr:
                  of $ParamPragma.param: parseParamStmt(identName, identNameStr, identType)
                  of $ParamPragma.query: parseQueryStmt(identName, identNameStr, identType, defaultVal)
                  of $ParamPragma.body:   parseBodyStmt(identName, identNameStr, identType)
                  else: newEmptyNode()
              else:
                let i = newIdentDefs(ident($param[0]), ident($param[1]), newLit(0))
                newParams.add(i)
        procBodyNew.add(procBodyOriginal)
        for i in 2..<params[0].len:
          newParams.add(params[0][i])
        let newProc: NimNode = nnkProcDef.newTree(
          procName,     # Tên hàm
          generic,      # Generic params (nếu có)
          patterns,     # Pattern params (rarely used)
          newParams,    # Đã patch "this"
          pragmas,      # Giữ pragmas gốc
          annotations,  # Annotations
          procBodyNew   # Thân hàm
        )
        outBody.add(newProc)
      else:
        outBody.add(stmt)
  # Khởi tạo controller instance, đăng ký vào container
  let init: NimNode = quote do:
    let inst = new `classIdent`
    CONTAINER[`classNameStr`] = cast[BaseController](inst)
  # Cài đặt init controller và đăng ký các route
  result.add(metaProcSecion)
  result.add(outBody)
  result.add(init)
  let lBody = newStmtList()
  for stmt in outBody:
    if stmt.kind == nnkProcDef:
      let procName        = stmt[0]  # Tên hàm
      let pragmas         = stmt[4]  # Giữ pragmas gốc
      let procNameStr     = ($procName).strip(chars = {'*'})
      let procNameStriped = ident(procNameStr)
      for pragma in pragmas:
        if pragma.kind == nnkIdent:
          let path = "/"
          if pragma.eqIdent("get"):
            lBody.add quote do: register(HttpGet, (RouteItem(path: `path`, delegate: collect(`class`, `procNameStriped`))))
        elif pragma.kind == nnkCall:
          let path = $pragma[1]
          if pragma[0].eqIdent("get"):
            lBody.add quote do: register(HttpGet, (RouteItem(path: `path`, delegate: collect(`class`, `procNameStriped`))))
          elif pragma[0].eqIdent("post"):
            lBody.add quote do: register(HttpPost, (RouteItem(path: `path`, delegate: collect(`class`, `procNameStriped`))))
          elif pragma[0].eqIdent("put"):
            lBody.add quote do: register(HttpPut, (RouteItem(path: `path`, delegate: collect(`class`, `procNameStriped`))))
          elif pragma[0].eqIdent("delete"):
            lBody.add quote do: register(HttpDelete, (RouteItem(path: `path`, delegate: collect(`class`, `procNameStriped`))))
      for pragma in pragmas:
        if pragma.kind == nnkIdent:
          discard # cần triển khai kiểm tra nếu chỉ khai báo là .get. thì mặc định sẽ hiểu path là "/"
        if pragma.kind == nnkCall:
          if pragma[0].eqIdent("useGuards"):
            if pragma[1].kind == nnkIdent:
              let ide = pragma[1]
              lBody.add quote do:
                registerGuard(`classNameStr`, `procNameStr`, `ide`)
            else:
              for brk in pragma[1]:
                lBody.add quote do:
                  registerGuard(`classNameStr`, `procNameStr`, `brk`)
  result.add(lBody)
  # echo treeRepr result
# Method pramga
template get*    (path: string = "/") {.pragma.}
template post*   (path: string = "/") {.pragma.}
template put*    (path: string = "/") {.pragma.}
template patch*  (path: string = "/") {.pragma.}
template delete* (path: string = "/") {.pragma.}
template trace*  (path: string = "/") {.pragma.}
template connect*(path: string = "/") {.pragma.}
template options*(path: string = "/") {.pragma.}
template head*   (path: string = "/") {.pragma.}

# Param pragma
template `$ParamPragma.param`*  (key: string = "") {.pragma.}
template `$ParamPragma.query`*  (key: string = "") {.pragma.}
template `$ParamPragma.body`*() {.pragma.}