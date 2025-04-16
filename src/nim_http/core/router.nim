import asynchttpserver, tables, macros, re, options, strutils
import controller

type
  RoutePattern = object
    raw*:        string
    regex*:      Regex
    paramNames*: seq[string]
  RouteWrapper* = object
    httpMethod*:        HttpMethod
    pattern*:           RoutePattern
    handler*:           proc (this: BaseController) {.gcsafe.}
    controllerFactory*: BaseController
  RouteRegister = object
    path: string
    c:    ControllerWrapper
  ControllerWrapper* = object
    clt*: BaseController
    fn*:  proc (this: BaseController) {.gcsafe.}

var routeTree* {.threadvar.}: seq[RouteWrapper]
routeTree = @[]

proc `/`*[T: BaseController](c: typedesc[T], fn: auto): ControllerWrapper =
  ControllerWrapper(
    clt: controllerRegistry[$c],
    fn: proc(this: BaseController) {.gcsafe.} =
      let ctrl = cast[T](this)
      fn(ctrl)
  )

proc `->`*(path: string, c: ControllerWrapper): RouteRegister =
  RouteRegister(path: path, c: c)  

proc parseRoutePattern(pattern: string): RoutePattern =
  var regexStr = "^"
  var paramNames: seq[string] = @[]
  let parts = pattern.strip(chars = {'/'}).split("/")  # Loại bỏ các dấu '/' đầu và cuối
  for part in parts:
    if part.startsWith(":"):
      regexStr.add("/([^/]+)")
      paramNames.add(part[1..^1])  # Lấy phần sau dấu ":" làm tên tham số
    else:
      regexStr.add("/" & part)
  regexStr.add("$")
  result = RoutePattern(raw: pattern, regex: re(regexStr), paramNames: paramNames)

# Đăng ký route
proc route*(
  httpMethod:     HttpMethod,
  path:           string,
  controllerType: ControllerWrapper
) =
  routeTree.add RouteWrapper(
    httpMethod:        httpMethod,
    pattern:           parseRoutePattern(path),
    handler:           controllerType.fn,
    controllerFactory: controllerType.clt
  )

proc resolveRoute*(path: string, method2: HttpMethod): Option[(RouteWrapper, Table[string, string])] =
  for route in routeTree:
    if route.httpMethod == method2:
      var matches: seq[string] = newSeq[string](route.pattern.paramNames.len + 1)
      if match(path, route.pattern.regex, matches):
        if matches.len == route.pattern.paramNames.len + 1:
          var params: Table[string, string] = initTable[string, string]()
          for i, name in route.pattern.paramNames:
            params[name] = matches[i]
          return some((route, params))
      else:
        return some((route, initTable[string, string]())) 
  return none((RouteWrapper, Table[string, string]))

# Shortcut
template Get* (rr: RouteRegister): untyped = route(HttpGet,  rr.path, rr.c)
template Post*(rr: RouteRegister): untyped = route(HttpPost, rr.path, rr.c)