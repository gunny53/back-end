import asynchttpserver, tables, macros
import controller

type
  RouteWrapper* = object
    httpMethod*:        HttpMethod
    path*:              string
    handler*:           proc (this: BaseController) {.gcsafe.}
    controllerFactory*: BaseController
  RouteRegister = object
    path: string
    c:    ControllerWrapper
  ControllerWrapper* = object
    clt*: BaseController
    fn*:  proc (this: BaseController) {.gcsafe.}

var routeTree* {.threadvar.}: Table[string, RouteWrapper]
routeTree = initTable[string, RouteWrapper]()

proc `/`*[T: BaseController](c: typedesc[T], fn: auto): ControllerWrapper =
  ControllerWrapper(clt: controllerRegistry[$c], 
  fn: proc(this: BaseController) {.gcsafe.} = 
    let ctrl = cast[T](this)
    fn(ctrl)
  )

proc `->`*(path: string, c: ControllerWrapper): RouteRegister =
  RouteRegister(path: path, c: c)  

proc route*(
  httpMethod:     HttpMethod,
  path:           string,
  controllerType: ControllerWrapper
) = routeTree[path] = RouteWrapper(
    httpMethod:        httpMethod,
    path:              path,
    handler:           controllerType.fn,
    controllerFactory: controllerType.clt
  )

template Get*(rr: RouteRegister): untyped = route(HttpGet, rr.path, rr.c)