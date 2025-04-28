import ../../nim_http/core/[exception, app]
import asyncdispatch, asynchttpserver, json

type HttpErrorHandle* = ref object of NimHttpApplicationErrorHandle

method catch*(e: HttpErrorHandle, req: Request): Future[void] {.async, gcsafe.} =
  if not req.headers.hasKey("Content-Type"):
    req.headers["Content-Type"] = "application/json"
  let mess = %*{"statusCode": e.exception.statusCode.int, "message": e.exception.message}
  if e.exception of NotFoundException:
    await req.respond(e.exception.statusCode, $mess, req.headers)
  else: await req.respond(e.exception.statusCode, $mess, req.headers)