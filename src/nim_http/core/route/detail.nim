import asynchttpserver, pattern, delegate, asyncdispatch, tables, ../controller/base, ../guard, ../exception, strutils

type RouteDetail* = ref object
  httpMethod*: HttpMethod            # Phương thức HTTP (GET, POST, etc.)
  pattern*:    RoutePattern          # Pattern của route
  delegate*:   ControllerDelegate    # Hàm handler xử lý request cho route

type RouteMethodTable = TableRef[HttpMethod, RouteDetail]

type RouteNode = ref object
  children*:   TableRef[string, RouteNode]        # Các node con cho exact match segments
  paramChild*: RouteNode                          # Node cho dynamic params (:id)
  paramName*:  string                             # Tên tham số cho dynamic node
  methods*:    RouteMethodTable                   # Routes cho từng HTTP method tại node này

var routeRoot* {.threadvar.}: RouteNode
routeRoot = RouteNode(children: newTable[string, RouteNode](), methods: newTable[HttpMethod, RouteDetail]())
var exactRoutes* {.threadvar.}: TableRef[string, RouteMethodTable]
exactRoutes = newTable[string, RouteMethodTable]()

proc splitPathSegments(path: string): seq[string] =
  let trimmed = path.strip(chars = {'/'})
  if trimmed.len == 0:
    return @[]
  trimmed.split("/")

proc isStaticPath(path: string): bool =
  not path.contains(":")

proc addRoute*(path: string, met: HttpMethod, delegate: ControllerDelegate) =
  let pattern  = parseRoutePattern(path)
  let detail = RouteDetail(httpMethod: met, pattern: pattern, delegate: delegate)
  let normalizedPath = path.normalizePathEnd(leadingSep = true, trailingSep = false)

  if isStaticPath(normalizedPath):
    if not exactRoutes.hasKey(normalizedPath):
      exactRoutes[normalizedPath] = newTable[HttpMethod, RouteDetail]()
    exactRoutes[normalizedPath][met] = detail
    return

  var current  = routeRoot
  let segments = splitPathSegments(normalizedPath)
  for seg in segments:
    if seg.startsWith(":"):
      if current.paramChild.isNil:
        current.paramChild = RouteNode(
          children: newTable[string, RouteNode](),
          methods: newTable[HttpMethod, RouteDetail](),
          paramName: seg[1 .. ^1]
        )
      current = current.paramChild
    else:
      if not current.children.hasKey(seg):
        current.children[seg] = RouteNode(children: newTable[string, RouteNode](), methods: newTable[HttpMethod, RouteDetail]())
      current = current.children[seg]
  current.methods[met] = detail

proc resolve*(this: RouteDetail, request: Request): Future[void] {.async, gcsafe.} =
  if this.delegate.guards.len > 0:
    for guard in this.delegate.guards:
      if not guard.canActivate(request):
        raise FORBIDDEN("Guard failed")
  await this.delegate.instance.processRequest(request).invoke(this.delegate.handler)

proc process*(request: Request): Future[void] {.async, gcsafe.} =
  let normalizedPath = request.url.path.normalizePathEnd(leadingSep = true, trailingSep = false)

  if exactRoutes.hasKey(normalizedPath):
    let methodTable = exactRoutes[normalizedPath]
    if methodTable.hasKey(request.reqMethod):
      let route = methodTable[request.reqMethod]
      route.delegate.instance.params = newTable[string, string]()
      await route.resolve(request)
      return
    raise METHOD_NOT_ALLOWED("Method " & $request.reqMethod & " not allowed for path: " & request.url.path)

  let segments = splitPathSegments(normalizedPath)
  var current = routeRoot
  var params = newTable[string, string]()
  for seg in segments:
    if current.children.hasKey(seg):
      current = current.children[seg]
    elif not current.paramChild.isNil:
      if current.paramChild.paramName.len > 0:
        params[current.paramChild.paramName] = seg
      current = current.paramChild
    else:
      raise NOT_FOUND("No route found for path: " & request.url.path)
  if current.methods.hasKey(request.reqMethod):
    let route = current.methods[request.reqMethod]
    route.delegate.instance.params = params
    await route.resolve(request)
  else:
    raise METHOD_NOT_ALLOWED("Method " & $request.reqMethod & " not allowed for path: " & request.url.path)
