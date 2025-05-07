import asynchttpserver, pattern, delegate, asyncdispatch, ../controller/base

# Lưu thông tin chi tiết của 1 route
type RouteDetail*[T: BaseController] = ref object
  httpMethod*: HttpMethod            # Phương thức HTTP (GET, POST, etc.)
  pattern*:    RoutePattern          # Pattern của route
  delegate*:   ControllerDelegate[T] # Hàm handler xử lý request cho route

# Hàm xử lý request, kiểm tra các guards, middleware, interceptors trước khi thực thi nghiệp vụ ở controller
proc resolve*(this: RouteDetail, request: Request): Future[void] =
  if this.delegate.guards.len > 0:
    for guard in this.delegate.guards:
      discard guard.canActivate(request)
  this.delegate.instance.processRequest(request).invoke(this.delegate.handler)  