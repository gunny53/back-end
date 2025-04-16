import asynchttpserver, tables
import controller

type RouteWrapper* = object
  httpMethod*:        HttpMethod
  path*:              string
  handler*:           proc (this: BaseController) {.gcsafe.}
  controllerFactory*: BaseController

var routeTree* {.threadvar.}: Table[string, RouteWrapper]
routeTree = initTable[string, RouteWrapper]()

proc route*[T: BaseController](httpMethod: HttpMethod, path: string, controllerType: typedesc[T], handler: proc(this: T) {.gcsafe.}) =
  routeTree[path] = RouteWrapper(
    httpMethod: httpMethod,
    path:       path,
    handler:    proc(this: BaseController) {.gcsafe.} =
      let ctrl = cast[T](this)
      handler(ctrl),
    controllerFactory: controllerRegistry[$controllerType]
  )