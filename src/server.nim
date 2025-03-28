import asynchttpserver, asyncdispatch, packages/common/decorators/core/controller, tables, nester

waitFor newAsyncHttpServer().serve(
  Port(8082),
  proc (req: Request) {.async.} =
    let routeKey = (req.url.path, req.reqMethod)  # Lấy cả đường dẫn + phương thức
    if routes.hasKey(routeKey): await routes[routeKey](req)  # Gọi handler tương ứng
    else: await req.respond(Http404, "Not Found")
)