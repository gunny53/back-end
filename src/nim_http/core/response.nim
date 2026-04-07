import asynchttpserver, tables, json, strutils, times

type Response* = ref object of RootObj
  body*:    RootObj
  request*: Request

proc detectContentType*(body: auto): (JsonNode, string) =
  if body.isNil:
    return (newJNull(), "application/json")
  if body is ref object:
    return (%body, "application/json")
  when body is string:
    if body.startsWith("<!DOCTYPE html>") or body.startsWith("<html"):
      return (%body, "text/html; charset=utf-8")
    else:
      return (%body, "text/plain; charset=utf-8")
  elif body is seq[byte]:
    return (%body, "application/octet-stream")
  elif body is JsonNode:
    return (body, "application/json")
  elif body is Table[string, auto] or body is seq[auto]: 
    return (%body, "application/json")
  else:
    return (%body, "application/octet-stream")

proc send*(this: Response, code: HttpCode, data: auto): void = 
  let (dataParse, ctt) = detectContentType(data)
  let headers = {
    "Content-Type":   ctt,
    "Date":           now().utc.format("ddd, dd MMM yyyy HH:mm:ss 'GMT'"),
    "Connection":    "keep-alive",
    "Cache-Control": "no-cache",
    "X-Powered-By":  "Nim http framework",
    "Server":        "Nim HTTP Server"
  }.newHttpHeaders()
  discard this.request.respond(code, $dataParse, headers)