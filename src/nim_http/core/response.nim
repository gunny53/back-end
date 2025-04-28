import asynchttpserver, tables, json, strutils, times

type Response* = ref object of RootObj
  body*:    RootObj
  request*: Request

proc detectContentType*(body: auto): string =
  if body.isNil:
    return "application/json"
  if body is string:
    if body.startsWith("<!DOCTYPE html>") or body.startsWith("<html"):
      return "text/html; charset=utf-8"
    else:
      return "text/plain; charset=utf-8"
  elif body is seq[byte]:
    return "application/octet-stream"
  elif body is JsonNode:
    return "application/json"
  elif body is Table[string, auto] or body is seq[auto]: 
    return "application/json"
  else:
    return "application/octet-stream"

proc send*(this: Response, code: HttpCode, data: auto): void = 
  let headers = {
    "Content-Type":   detectContentType(data),
    "Date":           now().utc.format("ddd, dd MMM yyyy HH:mm:ss 'GMT'"),
    "Connection":    "keep-alive",
    "Cache-Control": "no-cache",
    "X-Powered-By":  "Nim",
    "Server":        "Nim HTTP Server"
  }.newHttpHeaders()
  discard this.request.respond(code, data, headers)