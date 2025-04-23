import asynchttpserver, tables, macros, re, options, strutils, asyncdispatch
import controller, guard, exception

type
  # Lưu thông tin meta của route dưới dạng regex pattern
  RoutePattern = ref object
    raw*:        string
    regex*:      Regex
    paramSegments*: seq[string]

  # Lưu thông tin chi tiết của 1 route
  RouteDetail* = ref object
    httpMethod*: HttpMethod
    pattern*:    RoutePattern
    delegate*:   ControllerDelegate

  # Lưu thông tin của 1 route
  RouteItem = ref object
    path:     string
    delegate: ControllerDelegate

  # Lưu thông tin của controller
  ControllerDelegate = ref object
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
  let ctrlSym    = ctlClass
  let methodName = $handler
  result         = quote do:
    let hand =
      proc (this: BaseController): Future[void] {.gcsafe, closure.} =
        let ctrl = cast[`ctrlSym`](this)
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
    regexStr                = "^"
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