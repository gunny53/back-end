import macros, asynchttpserver, asyncdispatch, tables, options

type RouteHandler* = proc (): proc (req: Request): Future[void] {.async, gcsafe.} {.async, gcsafe.}

type Router* = ref object
  routes*: Table[(string, HttpMethod), tuple[handler: RouteHandler, filePath: string]]
  
var router* {.threadvar.}: Router
router = Router(routes: initTable[(string, HttpMethod), tuple[handler: RouteHandler, filePath: string]]())

macro regRoute*(
  route:      static[string],
  httpMethod: static[HttpMethod],
  body:       untyped
): untyped =
  if body.kind == nnkStmtList and body.len > 0 and body[0].kind == nnkProcDef:
    let procDef  =    body[0]
    let procName = procDef[0]
    let filename = $lineInfo(procDef)
    result = quote do:
      `procDef`
      router.routes[(`route`, `httpMethod`)] = (RouteHandler `procName`, `filename`)
  else:
    result = quote do:
      when not compiles(body(Request())): {.error: "Function error".}
      router.routes[(route, httpMethod)] = (RouteHandler body,  $lineInfo(body))