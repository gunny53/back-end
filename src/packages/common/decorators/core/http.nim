import macros, asynchttpserver, asyncdispatch, tables, options
import ../../../router/route_resolver

type
  Param*       = distinct string
  Query*       = string
  Body*        = string
  Header*      = string

proc Ok*(content: auto): auto = 
  return proc (req: Request): Future[void] {.async, gcsafe.} =
    await req.send(Http200, content)

# proc Redirect*(req: Request, location: string): HandlerFn =
#   let headers = newHttpHeaders()
#   headers["Location"] = location
#   await req.respond(Http302, "", headers)

# proc RedirectPermanent*(req: Request, location: string): HandlerFn =
#   let headers = newHttpHeaders()
#   headers["Location"] = location
#   await req.respond(Http301, "", headers)

# proc       Bad*(req: Request, content: auto): HandlerFn = await req.send(Http400, content)
# proc Forbidden*(req: Request, content: auto): HandlerFn = await req.send(Http403, content)

proc Bad*(content: auto): proc (req: Request): Future[void] =
  return proc (req: Request): Future[void] {.async.} =
    await req.send(Http400, content)

proc Forbidden*(content: auto): proc (req: Request): Future[void] =
  return proc (req: Request): Future[void] {.async.} =
    await req.send(Http403, content)

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

macro    GET*(route: static[string], body: untyped): untyped = quote do: RouteMapping(`route`, HttpMethod.HttpGet,    `body`)
macro   POST*(route: static[string], body: untyped): untyped = quote do: RouteMapping(`route`, HttpMethod.HttpPost,   `body`)
macro    PUT*(route: static[string], body: untyped): untyped = quote do: RouteMapping(`route`, HttpMethod.HttpPut,    `body`)
macro DELETE*(route: static[string], body: untyped): untyped = quote do: RouteMapping(`route`, HttpMethod.HttpDelete, `body`)