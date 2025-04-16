import asynchttpserver, tables, macros, re, options, strutils
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

var routeTree* {.threadvar.}: seq[RouteDetail]
routeTree = @[]

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

proc parseRoutePattern(pattern: string): RoutePattern =
  var regexStr = "^"
  var paramNames: seq[string] = @[]
  let parts = pattern.strip(chars = {'/'}).split("/")
  for part in parts:
    if part.startsWith(":"):
      regexStr.add("/([^/]+)")
      let name = part[1..^1]
      assert name notin paramNames, "Parameter `" & name & "` already exists in route pattern."
      paramNames.add(name)
    else:
      regexStr.add("/" & part)
  regexStr.add("$")
  result = RoutePattern(raw: pattern, regex: re(regexStr), paramNames: paramNames)

proc register(
  httpMethod: HttpMethod,
  route:      RouteItem
) =
  let pattern = parseRoutePattern(route.path)
  routeTree.add RouteDetail(
    httpMethod: httpMethod,
    pattern:    pattern,
    delegate:   route.delegate
  )

proc matchRoute*(requet: Request): Option[RouteDetail] =
  for route in routeTree:
    if route.httpMethod == requet.reqMethod:
      var matches: seq[string] = newSeq[string](route.pattern.paramNames.len + 1)
      if match(requet.url.path, route.pattern.regex, matches):
        if matches.len == route.pattern.paramNames.len + 1:
          for i, name in route.pattern.paramNames:
            route.delegate.instance.params[name] = matches[i]
          return some(route)
        else:
          return some(route)
  return none(RouteDetail)

template Get* (route: RouteItem): untyped = register(HttpGet,  route)
template Post*(route: RouteItem): untyped = register(HttpPost, route)