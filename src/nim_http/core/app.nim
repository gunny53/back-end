import asynchttpserver, asyncdispatch, strutils
import router
import exception

proc defaultErrorHandler*(req: Request, err: ref Exception): Future[void] {.async.} =
  var code = Http500
  var msg  = ""
  if err of HttpException:
    let httpErr = cast[HttpException](err)
    code = httpErr.statusCode
    msg  = httpErr.message
  await req.respond(code, $msg, "application/json")

type NimHttpApplicationSettings* = ref object of RootObj
  host*:      string = "localhost"
  useHttps:   bool   = false
  prefixPath: string = ""
  port*:      int    = 8800
  error*:     ErrorHandler = defaultErrorHandler

type NimHttpApplication* = ref object of RootObj
  settings*: NimHttpApplicationSettings

proc listen*(this: NimHttpApplication) =
  waitFor newAsyncHttpServer().serve(
    port     = Port(this.settings.port),
    address  = this.settings.host,
    callback = proc (request: Request) {.async.} = await request.process
  )