import asynchttpserver, asyncdispatch, strutils, tables, macrocache
import apps/home/[main, routes]
import nim_http/core/[controller, router]

waitFor newAsyncHttpServer().serve(
  Port(8082),
  proc (req: Request) {.async.} =
    let routeTree = routes()
    for path, cfg in routeTree.pairs:
      echo "Route: ", path, " -> Method: ", $cfg.httpMethod
    controllerRegistry["HomeController"].BindRequest(req).next(index, HomeController)
)
