import asynchttpserver, asyncdispatch, strutils, httpclient, options
import apps/home/routes
import nim_http/core/[controller, router]

waitFor newAsyncHttpServer().serve(
  Port(8082),
  proc (request: Request) {.async.} =
    let routeOpt = matchRoute(request)
    if routeOpt.isSome:
      let route = routeOpt.get
      route.resolve(request)
    else:
      await request.respond(Http400, "not found")  
)
