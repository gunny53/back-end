import macros, asynchttpserver, asyncdispatch, tables, jsony, options

type RouteHandler = proc (req: Request): Future[void] {.async, gcsafe.}

var routes* {.threadvar.}: Table[(string, HttpMethod), RouteHandler]
routes = initTable[(string, HttpMethod), RouteHandler]()

macro Controller*(name: static[string], body: untyped): untyped =
  result = quote do:
    block: `body`

proc        Ok*(req: Request, content: auto): Future[void] {.async.} = await req.send(Http200, content)
proc       Bad*(req: Request, content: auto): Future[void] {.async.} = await req.send(Http400, content)
proc Forbidden*(req: Request, content: auto): Future[void] {.async.} = await req.send(Http403, content)

proc send*(
  req:     Request,
  code:    HttpCode,
  content: auto,
  headers: HttpHeaders = newHttpHeaders(),
): Future[void] {.async.} =
  await req.respond(
    code,
    content.withHeaders(headers),
    headers
  )

proc withHeaders*(content: auto, headers: HttpHeaders): auto =
  when content is Option:
    if content.isNone:
      headers["Content-Type"] = "application/json"
      return "null"
    else:
      return content.get.withHeaders(headers)
  when content is string:
    headers["Content-Type"] = "text/html; charset=utf-8"
    content
  elif content is SomeInteger or content is SomeFloat:
    headers["Content-Type"] = "text/plain"
    $content
  elif content is bool:
    headers["Content-Type"] = "text/plain"
    if content: "true" else: "false"
  elif content is seq[byte]:
    headers["Content-Type"] = "application/octet-stream"
    content.toOpenArrayByte.toString
  elif content is seq or content is object or compiles(toJson(content)):
    headers["Content-Type"] = "application/json"
    toJson(content)
  else:
    headers["Content-Type"] = "application/json"
    toJson(content)

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

macro    GET*(route: static[string], body: untyped): untyped = quote do: handle(`route`, HttpMethod.HttpGet,    `body`)
macro   POST*(route: static[string], body: untyped): untyped = quote do: handle(`route`, HttpMethod.HttpPost,   `body`)
macro    PUT*(route: static[string], body: untyped): untyped = quote do: handle(`route`, HttpMethod.HttpPut,    `body`)
macro DELETE*(route: static[string], body: untyped): untyped = quote do: handle(`route`, HttpMethod.HttpDelete, `body`)