import asynchttpserver, asyncdispatch, strutils, tables, httpclient, re, options
import apps/home/routes
import nim_http/core/[controller, router]

waitFor newAsyncHttpServer().serve(
  Port(8082),
  proc (req: Request) {.async.} =
    let routeOpt = matchRoute(req.url.path, req.reqMethod)
    if routeOpt.isSome:
      let (route, params) = routeOpt.get()
      route.controllerFactory
      .BindRequest(req)
      .BindParams(params)
      .next(route.handler, typeof route.controllerFactory)
    else:
      await req.respond(Http400, "not found")  
)
