import asynchttpserver, asyncdispatch, strutils
import router
import exception

type NimHttpApplicationSettings* = ref object of RootObj
  host*:      string = "localhost"
  useHttps:   bool   = false
  prefixPath: string = ""
  port*:      int    = 8800
  error*:     HttpException

type NimHttpApplication* = ref object of RootObj
  settings*: NimHttpApplicationSettings

proc listen*(this: NimHttpApplication) =
  waitFor newAsyncHttpServer().serve(
    port     = Port(this.settings.port),
    address  = this.settings.host,
    callback = proc (request: Request) {.async.} = await request.process
  )