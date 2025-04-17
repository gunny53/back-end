import asynchttpserver, tables, macros, re, options, strutils, asyncdispatch
import controller

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
    handler*:  proc (this: BaseController) {.gcsafe.}

var routeTree* {.threadvar.}: Table[string, RouteDetail]
routeTree = initTable[string, RouteDetail]()

proc resolve*(this: RouteDetail, request: Request) =
  this.delegate.instance.processRequest(request).next(this.delegate.handler)

proc `/`*[T: BaseController](c: typedesc[T], handler: auto): ControllerDelegate =
  ControllerDelegate(
    instance: controllerRegistry[$c],
    handler:  proc(this: BaseController) {.gcsafe.} =
      let ctrl = cast[T](this)
      handler(ctrl)
  )

proc `->`*(path: string, delegate: ControllerDelegate): RouteItem =
  RouteItem(path: path, delegate: delegate)  

proc parseToRegex(path: string): (seq[string], string) =
  var regexStr = "^"
  var paramNames: seq[string] = @[]
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
          route.resolve(request)
        else:
          await request.respond(Http400, "not found") 
  await request.respond(Http400, "not found") 

template Get*     (route: RouteItem): untyped = register(HttpGet,     route)
template Post*    (route: RouteItem): untyped = register(HttpPost,    route)
template Put*     (route: RouteItem): untyped = register(HttpPut,     route)
template Patch*   (route: RouteItem): untyped = register(HttpPatch,   route)
template Options* (route: RouteItem): untyped = register(HttpOptions, route)
template Delete*  (route: RouteItem): untyped = register(HttpDelete,  route)