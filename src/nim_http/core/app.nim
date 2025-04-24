import asynchttpserver, asyncdispatch, strutils
import controller
import exception

type NimHttpApplicationErrorHandle* = ref object of RootObj
  exception*: HttpException

method catch*(this: NimHttpApplicationErrorHandle, req: Request): Future[void] {.base, async, gcsafe.} =
  this.exception.catch(req)

type NimHttpApplicationSettings* = ref object of RootObj
  host*:        string = "localhost"
  useHttps:     bool   = false
  prefixPath:   string = ""
  port*:        int    = 8800
  errorHandle*: NimHttpApplicationErrorHandle

type NimHttpApplication* = ref object of RootObj
  settings*: NimHttpApplicationSettings

proc listen*(this: NimHttpApplication) =
  waitFor newAsyncHttpServer().serve(
    port     = Port(this.settings.port),
    address  = this.settings.host,
    callback = proc (request: Request) {.async.} = 
    try:
      await request.process
    except HttpException as e:
      if this.settings.errorHandle.isNil:
        this.settings.errorHandle = NimHttpApplicationErrorHandle(exception: e)
      else: this.settings.errorHandle.exception = e
      await this.settings.errorHandle.catch(request)
  )