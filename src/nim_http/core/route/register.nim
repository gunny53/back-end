import delegate, asynchttpserver, detail, pattern, tables, strutils

# Lưu thông tin của 1 route
type RouteRegister* = ref object
  path*:     string             # Đường dẫn của route
  delegate*: ControllerDelegate # Delegate cho route (controller + handler)

# Đăng ký route
proc reg*(this: RouteRegister, httpMed: auto) =
  let (pattern, key) = parseRoutePattern(this.path)
  routeTree[key]     = RouteDetail(
    httpMethod: parseEnum[HttpMethod]($httpMed),
    pattern:    pattern,
    delegate:   this.delegate
  )