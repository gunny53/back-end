import macros, asynchttpserver, asyncdispatch, tables, jsony

type RouteHandler = proc (req: Request): Future[void] {.async, gcsafe.}

var routes* {.threadvar.}: Table[(string, HttpMethod), RouteHandler]
routes = initTable[(string, HttpMethod), RouteHandler]()

macro Controller*(name: static[string], body: untyped): untyped =
  result = quote do:
    block: `body`

proc json*(req: Request, code: HttpCode, content: auto, headers: HttpHeaders = nil): Future[void] {.async.} =
  await req.respond(
    code,
    when  content is string: content
    elif  content is SomeInteger or content is SomeFloat: $content
    elif  compiles(toJson(content)): toJson(content)
    else: toJson(content),
    headers
  )

macro handle(
  route:      static[string],
  httpMethod: static[HttpMethod],
  body:       untyped
): untyped =
  if body.kind == nnkStmtList and body.len > 0 and body[0].kind == nnkProcDef:
    let procDef  =    body[0]
    let procName = procDef[0]
    result = quote do: `procDef`; routes[(`route`, `httpMethod`)] = `procName`
  else: result = quote do:
    when not compiles(`body`(Request())): {.error: "Function error".}
    routes[(`route`, `httpMethod`)] = `body`

macro    Get*(route: static[string], body: untyped): untyped = quote do: handle(`route`, HttpMethod.HttpGet,    `body`)
macro   Post*(route: static[string], body: untyped): untyped = quote do: handle(`route`, HttpMethod.HttpPost,   `body`)
macro    Put*(route: static[string], body: untyped): untyped = quote do: handle(`route`, HttpMethod.HttpPut,    `body`)
macro Delete*(route: static[string], body: untyped): untyped = quote do: handle(`route`, HttpMethod.HttpDelete, `body`)