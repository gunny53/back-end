import macros, asyncdispatch, asynchttpserver, macrocache, tables, sequtils, di, strutils, utils, uri, json, options
import guard, re, exception, route
import controller/base as base
export base

# Định nghĩa các pragma cho param (các loại tham số trong controller)
type ParamPragma = enum
  body, query, param

# Bảng lưu các inst controller theo tên
let CONTAINER: TableRef[string, BaseController] = newTable[string, BaseController]()

# Lưu trữ các route trong bộ nhớ
var routeTree {.threadvar.}: TableRef[string, RouteDetail[BaseController]]
routeTree = newTable[string, RouteDetail[BaseController]]()

# Lưu thông tin function handler cho request, bao gồm controller instance, guards, handler function
macro collect[T: BaseController](ctlClass: typedesc[T], handler: untyped): ControllerDelegate[T] =
  let className  = $ctlClass 
  let methodName = $handler
  result         = quote do:
    # Ép kiểu về kiểu gốc
    let hand = proc (this: `ctlClass`): Future[void] {.gcsafe, closure.} =
      let ctrl = cast[`ctlClass`](this)
      `handler`(ctrl)
    # Phát hiện các guards và lưu vào bộ nhớ quản lý guards của instance controller
    let guards = if CONTAINER[`className`].guards.hasKey(`methodName`): CONTAINER[`className`].guards[`methodName`] else: @[]
    ControllerDelegate[`ctlClass`](
      instance: cast[`ctlClass`](CONTAINER[`className`]),
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
proc register[T: BaseController](httpMethod: HttpMethod, route: RouteRegister) =
  let (pattern, key) = parseRoutePattern(route.path)
  routeTree[key]     = cast[RouteDetail[BaseController]](RouteDetail[T](
    httpMethod: httpMethod,
    pattern:    pattern,
    delegate:   route.delegate
  ))

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
      except Exception as e: raise BAD_REQUEST(e.msg)
    )

proc registerGuard(className: string, procName: string, guardType: typedesc[Guard]) =
  let guardInst = new guardType
  if not CONTAINER[className].guards.hasKey(procName):
    CONTAINER[className].guards[procName] = @[]
  CONTAINER[className].guards[procName].add(cast[Guard](guardInst))

proc registerRoute(httpMethod: string, path: string, class: NimNode, procName: string): NimNode =
  let procNameStriped = ident(procName)
  result = (
    case httpMethod
    of "HttpGet":    
      quote do: 
        let v = collect[`class`](`class`, `procNameStriped`)
        register[`class`](HttpGet,    (RouteRegister[`class`](path: `path`, delegate: v)))
    of "HttpPost":   
      quote do: register[`class`](HttpPost,   (RouteRegister[`class`](path: `path`, delegate: collect[`class`](`class`, `procNameStriped`))))
    of "HttpPut":    
      quote do: register[`class`](HttpPut,    (RouteRegister[`class`](path: `path`, delegate: collect[`class`](`class`, `procNameStriped`))))
    of "HttpDelete": 
      quote do: register[`class`](HttpDelete, (RouteRegister[`class`](path: `path`, delegate: collect[`class`](`class`, `procNameStriped`))))
    else: newEmptyNode()
  )

# Định nghĩa Controller
macro Controller*(classT, body: untyped): untyped =
  result          = newStmtList()
  let class       = if classT.kind == nnkCall: ident($classT[0]) else: ident($classT)
  let routePrefix = if classT.kind == nnkCall: $classT[1]        else: ""
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
  # Khởi tạo controller instance, đăng ký vào container
  let analyzeBody: NimNode = quote do:
    let inst = new `classIdent`
    CONTAINER[`classNameStr`] = cast[BaseController](inst)  
  var pendingAttrs: seq[NimNode] = @[]
  const httpMethodsAttr = @["HttpGet", "HttpPost", "HttpPut", "HttpDelete"]
  const useGuardAttr    = @["UseGuard"]
  for stmt in body:
    if stmt.kind == nnkBracket:
      let attr = if stmt[0].kind == nnkCall: stmt[0][0] else: stmt[0]
      if ($attr notin httpMethodsAttr) and ($attr notin useGuardAttr):
        error "[ERROR] Attribute " & $attr & " invalid, " & (httpMethodsAttr & useGuardAttr).join(", ")
      pendingAttrs.add(stmt)
    elif stmt.kind == nnkProcDef:
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
                newParams.add(newIdentDefs(ident($param[0]), ident($param[1]), newLit(0)))
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
      if pendingAttrs.len > 0:
        let procNameStr       = ($procName).strip(chars = {'*'})
        for attr in pendingAttrs:
          if attr[0].kind == nnkCall:
            let identKey = attr[0][0]
            let identVal = attr[0][1]
            if $identKey in httpMethodsAttr:
              let rawPath      = if identVal.kind == nnkStrLit: $identVal else: "/"
              let splatOrEmpty = if routePrefix.endsWith("/") or rawPath.startsWith("/"): "" else: "/"
              let path         = routePrefix & splatOrEmpty & rawPath
              let roStmt = registerRoute($identKey, path, class, procNameStr)
              outbody.add(roStmt)
            elif $identKey in useGuardAttr:
              if identVal.kind == nnkIdent:
                analyzeBody.add quote do:
                  registerGuard(`classNameStr`, `procNameStr`, `identVal`)
          elif attr[0].kind == nnkIdent:
            let identKey = attr[0]
            if $identKey in httpMethodsAttr:
              let roStmt = registerRoute($identKey, routePrefix, class, procNameStr)
              outBody.add(roStmt)
        pendingAttrs.setLen(0)  
  
  result.add(metaProcSecion)  # Cài đặt các hàm bổ trợ cần thiết
  result.add(analyzeBody)     # Cài đặt init controller và đăng ký các guard
  result.add(outBody)         # Cài đặt thân hàm đã chèn các tham số cần thiết và đăng ký các route

# Param pragma
template `$ParamPragma.param`*  (key: string = "") {.pragma.}
template `$ParamPragma.query`*  (key: string = "") {.pragma.}
template `$ParamPragma.body`*() {.pragma.}