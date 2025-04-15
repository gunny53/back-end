import asynchttpserver, asyncdispatch, strutils, tables
import apps/home/main
import nim_http/core/controller

waitFor newAsyncHttpServer().serve(
  Port(8082),
  proc (req: Request) {.async.} =
    controllerRegistry["HomeController"].BindRequest(req).next(index, HomeController)
)
