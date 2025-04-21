import asynchttpserver, tables, macros, re, options, strutils, asyncdispatch
import controller, guard

type
  RoutePattern = object
    raw*:        string
    regex*:      Regex
    paramNames*: seq[string]

  RouteDetail* = object
    httpMethod*: HttpMethod
    pattern*:    RoutePattern
    delegate*:   ControllerDelegate

  RouteItem = object
    path:     string
    delegate: ControllerDelegate

  ControllerDelegate = object
    instance*: BaseController
    handler*:  proc (this: BaseController): Future[void] {.gcsafe.}
    guards*:   seq[Guard]

var routeTree* {.threadvar.}: Table[string, RouteDetail]
routeTree = initTable[string, RouteDetail]()

type
  GuardFailedError* = object of CatchableError

# Hàm xử lý request, kiểm tra các guards, middleware, interceptors trước khi thực thi nghiệp vụ ở controller
proc resolve*(this: RouteDetail, request: Request): Future[void] {.async.} =
  if this.delegate.guards.len > 0:
    for guard in this.delegate.guards:
      if not guard.canActivate(request):
        raise newException(GuardFailedError, "Guard check failed: ")
  this.delegate.instance.processRequest(request).invoke(this.delegate.handler)

macro `/`*[T: BaseController](c: typedesc[T], handler: untyped): ControllerDelegate =
  let ctrlSym    = c
  let methodName = $handler
  echo methodName
  result = quote do:
    echo `handler`.repr
    let hand =
      proc (this: BaseController): Future[void] {.gcsafe.} =
        let ctrl = cast[`ctrlSym`](this)
        `handler`(ctrl)
    let guards = (
      if controllerRegistry[$`c`].guards.hasKey(`methodName` & "*"):
        controllerRegistry[$`c`].guards[`methodName` & "*"]
       else: @[] 
    )
    ControllerDelegate(
      instance: controllerRegistry[$`c`],
      handler:  hand,
      guards:   guards
    )

proc `->`*(path: string, delegate: ControllerDelegate): RouteItem =
  RouteItem(path: path, delegate: delegate)  

proc parseToRegex(path: string): (seq[string], string) =
  var 
    regexStr                = "^"
    paramNames: seq[string] = @[]
  let parts = path.strip(chars = {'/'}).split("/")
  for part in parts:
    if part.startsWith(":"):
      regexStr.add("/([^/]+)")
      let name = part[1..^1]
      assert name notin paramNames, "Parameter `" & name & "` already exists in route pattern."
      paramNames.add(name)
    else:
      regexStr.add("/" & part)
  regexStr.add("$")
  result = (paramNames, regexStr)

proc parseRoutePattern(pattern: string): (RoutePattern, string) =
  let (paramNames, regexStr) = parseToRegex(pattern)
  result = (RoutePattern(raw: pattern, regex: re(regexStr), paramNames: paramNames), regexStr)

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

proc process*(request: Request): Future[void] {.async.} =
  let (paramNames, key) = parseToRegex(request.url.path)
  if routeTree.hasKey(key):
    let route = routeTree[key]
    if route.httpMethod == request.reqMethod:
      var matches: seq[string] = newSeq[string](paramNames.len + 1)
      if match(request.url.path, route.pattern.regex, matches):
        if matches.len == paramNames.len + 1:
          for i, name in paramNames:
            route.delegate.instance.params[name] = matches[i]
          try:
            await route.resolve(request)
          except GuardFailedError as e:
            await request.respond(Http401, e.msg)
        else:
          await request.respond(Http400, $Http400)
    else:
      await request.respond(Http405, $Http405)
  await request.respond(Http400, $Http400)

template Get*    (route: RouteItem): untyped = register(HttpGet,     route)
template Post*   (route: RouteItem): untyped = register(HttpPost,    route)
template Put*    (route: RouteItem): untyped = register(HttpPut,     route)
template Patch*  (route: RouteItem): untyped = register(HttpPatch,   route)
template Options*(route: RouteItem): untyped = register(HttpOptions, route)
template Delete* (route: RouteItem): untyped = register(HttpDelete,  route)