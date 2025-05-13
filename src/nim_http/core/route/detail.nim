import asynchttpserver, pattern, delegate, asyncdispatch, tables, ../controller/base, ../guard, re, ../exception

# Lưu thông tin chi tiết của 1 route
type RouteDetail* = ref object
  httpMethod*: HttpMethod            # Phương thức HTTP (GET, POST, etc.)
  pattern*:    RoutePattern          # Pattern của route
  delegate*:   ControllerDelegate # Hàm handler xử lý request cho route

# Lưu trữ các route trong bộ nhớ
var routeTree* {.threadvar.}: TableRef[string, RouteDetail]
routeTree = newTable[string, RouteDetail]()

# Hàm xử lý request, kiểm tra các guards, middleware, interceptors trước khi thực thi nghiệp vụ ở controller
proc resolve*(this: RouteDetail, request: Request): Future[void] =
  if this.delegate.guards.len > 0:
    for guard in this.delegate.guards:
      discard guard.canActivate(request)
  this.delegate.instance.processRequest(request).invoke(this.delegate.handler)

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