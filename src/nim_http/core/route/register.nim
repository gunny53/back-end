import delegate, asynchttpserver, detail, tables, strutils

type RouteRegister* = ref object
  path*:     string             # Đường dẫn của route
  delegate*: ControllerDelegate # Delegate cho route (controller + handler)

proc reg*(this: RouteRegister, httpMed: auto) =
  let met = parseEnum[HttpMethod]($httpMed)
  addRoute(this.path, met, this.delegate)