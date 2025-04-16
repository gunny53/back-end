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

# Syntax sugar: HomeController / index
proc `/`*[T: BaseController](c: typedesc[T], fn: auto): ControllerWrapper =
  ControllerWrapper(
    clt: controllerRegistry[$c],
    fn: proc(this: BaseController) {.gcsafe.} =
      let ctrl = cast[T](this)
      fn(ctrl)
  )

# Syntax sugar: "/path" -> HomeController / index
proc `->`*(path: string, c: ControllerWrapper): RouteRegister =
  RouteRegister(path: path, c: c)  

# Parse "/user/:id" => regex "/user/([^/]+)" và lưu lại paramNames
proc parseRoutePattern(pattern: string): RoutePattern =
  var regexStr = "^"
  var paramNames: seq[string] = @[]
  let parts = pattern.strip(chars = {'/'}).split("/")  # Loại bỏ các dấu '/' đầu và cuối
  for part in parts:
    if part.startsWith(":"):
      regexStr.add("/([^/]+)")
      assert part[1..^1] notin paramNames, "Parameter `" & part[1..^1] & "` already exists in route pattern."
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
  let r = parseRoutePattern(path)
  routeTree.add RouteWrapper(
    httpMethod:        httpMethod,
    pattern:           r,
    handler:           controllerType.fn,
    controllerFactory: controllerType.clt
  )

# Match route và trích xuất params
proc matchRoute*(path: string, method2: HttpMethod): Option[(RouteWrapper, Table[string, string])] =
  for route in routeTree:
    if route.httpMethod == method2:
      var matches: seq[string] = newSeq[string](route.pattern.paramNames.len + 1)
      if match(path, route.pattern.regex, matches):
        # match luôn push full match ở index 0
        if matches.len == route.pattern.paramNames.len + 1:
          var params: Table[string, string] = initTable[string, string]()
          for i, name in route.pattern.paramNames:
            params[name] = matches[i + 1]
          return some((route, params))
        else:
          return some((route, route.controllerFactory.params))
  return none((RouteWrapper, Table[string, string]))


# Shortcut
template Get* (rr: RouteRegister): untyped = route(HttpGet,  rr.path, rr.c)
template Post*(rr: RouteRegister): untyped = route(HttpPost, rr.path, rr.c)