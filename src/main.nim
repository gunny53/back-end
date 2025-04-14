import asynchttpserver, asyncdispatch, strutils, macros, macrocache, tables
import apps/home/main
import nim_http/core/[controller, di]

waitFor newAsyncHttpServer().serve(
  Port(8082),
  proc (req: Request) {.async.} =
    let this = controllerRegistry["HomeController"].BindRequest(req)
    next(
      index,
      HomeController
    )
)
