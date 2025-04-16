import asynchttpserver, asyncdispatch, strutils, tables
import apps/home/main
import nim_http/core/[controller, router]

waitFor newAsyncHttpServer().serve(
  Port(8082),
  proc (req: Request) {.async.} =
    if routeTree.hasKey(req.url.path):
      let conf = routeTree[req.url.path]
      conf.controllerFactory.BindRequest(req).next(conf.handler, typeof conf.controllerFactory)
    else:
      await req.respond(Http400, "not found")  
)
