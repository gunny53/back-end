import delegate, asynchttpserver, detail, pattern, tables

# Lưu thông tin của 1 route
type RouteRegister* = ref object
  path*:     string             # Đường dẫn của route
  delegate*: ControllerDelegate # Delegate cho route (controller + handler)

# Đăng ký route
proc register*(httpMethod: HttpMethod, route: RouteRegister) =
  let (pattern, key) = parseRoutePattern(route.path)
  routeTree[key]     = RouteDetail(
    httpMethod: httpMethod,
    pattern:    pattern,
    delegate:   route.delegate
  )