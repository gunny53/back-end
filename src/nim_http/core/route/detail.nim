import asynchttpserver, pattern, delegate, asyncdispatch, tables, ../controller/base, ../guard, ../exception, strutils

type RouteDetail* = ref object
  httpMethod*: HttpMethod            # Phương thức HTTP (GET, POST, etc.)
  pattern*:    RoutePattern          # Pattern của route
  delegate*:   ControllerDelegate    # Hàm handler xử lý request cho route

type RouteNode = ref object
  children*:   TableRef[string, RouteNode]        # Các node con cho exact match segments
  paramChild*: RouteNode                          # Node cho dynamic params (:id)
  methods*:    TableRef[HttpMethod, RouteDetail]  # Routes cho từng HTTP method tại node này

var routeRoot* {.threadvar.}: RouteNode
routeRoot = RouteNode(children: newTable[string, RouteNode](), methods: newTable[HttpMethod, RouteDetail]())

proc addRoute*(path: string, met: HttpMethod, delegate: ControllerDelegate) =
  let pattern  = parseRoutePattern(path)
  var current  = routeRoot
  let segments = path.strip(chars = {'/'}).split("/")
  for seg in segments:
    if seg.startsWith(":"):
      if current.paramChild.isNil:
        current.paramChild = RouteNode(children: newTable[string, RouteNode](), methods: newTable[HttpMethod, RouteDetail]())
      current = current.paramChild
    else:
      if not current.children.hasKey(seg):
        current.children[seg] = RouteNode(children: newTable[string, RouteNode](), methods: newTable[HttpMethod, RouteDetail]())
      current = current.children[seg]
  current.methods[met] = RouteDetail(httpMethod: met, pattern: pattern, delegate: delegate)

proc resolve*(this: RouteDetail, request: Request): Future[void] {.async, gcsafe.} =
  if this.delegate.guards.len > 0:
    for guard in this.delegate.guards:
      if not guard.canActivate(request):
        raise FORBIDDEN("Guard failed")
  await this.delegate.instance.processRequest(request).invoke(this.delegate.handler)

proc process*(request: Request): Future[void] {.async, gcsafe.} =
  let segments = request.url.path.strip(chars = {'/'}).split("/")
  var current = routeRoot
  var params = newTable[string, string]()
  var paramValues: seq[string] = @[]
  for seg in segments:
    if current.children.hasKey(seg):
      current = current.children[seg]
    elif not current.paramChild.isNil:
      current = current.paramChild
      paramValues.add(seg)
    else:
      raise NOT_FOUND("No route found for path: " & request.url.path)
  if current.methods.hasKey(request.reqMethod):
    let route = current.methods[request.reqMethod]
    for idx, name in route.pattern.paramSegments:
      if idx < paramValues.len:
        params[name] = paramValues[idx]
    route.delegate.instance.params = params
    await route.resolve(request)
  else:
    raise METHOD_NOT_ALLOWED("Method " & $request.reqMethod & " not allowed for path: " & request.url.path)
