import macros, asynchttpserver, asyncdispatch, tables, jsony, options
import ../../../router/route_resolver

proc        Ok*(req: Request, content: auto): Future[void] {.async.} = await req.send(Http200, content)
proc   Created*(req: Request, content: auto): Future[void] {.async.} = await req.send(Http201, content)
proc NoContent*(req: Request, content: auto = nil): Future[void] {.async.} = await req.send(HTTP204, nil)

proc Redirect*(req: Request, location: string): Future[void] {.async.} =
  let headers = newHttpHeaders()
  headers["Location"] = location
  await req.respond(Http302, "", headers)

proc RedirectPermanent*(req: Request, location: string): Future[void] {.async.} =
  let headers = newHttpHeaders()
  headers["Location"] = location
  await req.respond(Http301, "", headers)

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

macro    GET*(route: static[string], body: untyped): untyped = quote do: regRoute(`route`, HttpMethod.HttpGet,    `body`)
macro   POST*(route: static[string], body: untyped): untyped = quote do: regRoute(`route`, HttpMethod.HttpPost,   `body`)
macro    PUT*(route: static[string], body: untyped): untyped = quote do: regRoute(`route`, HttpMethod.HttpPut,    `body`)
macro DELETE*(route: static[string], body: untyped): untyped = quote do: regRoute(`route`, HttpMethod.HttpDelete, `body`)