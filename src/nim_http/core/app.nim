import asynchttpserver, asyncdispatch, strutils, logging
import route
import exception

addHandler(newConsoleLogger())

type NimHttpApplicationErrorHandle* = ref object of RootObj
  exception*: HttpException

method catch*(this: NimHttpApplicationErrorHandle, req: Request): Future[void] {.base, async, gcsafe.} =
  this.exception.catch(req)

type NimHttpApplicationSettings* = ref object of RootObj
  host*:        string = "localhost"
  useHttps:     bool   = false
  basePath:     string = ""
  port*:        int    = 8800
  errorHandle*: NimHttpApplicationErrorHandle

func getHostUrl(this: NimHttpApplicationSettings): string = "http://" & this.host & ":" & $this.port

type NimHttpApplication* = ref object of RootObj
  settings*: NimHttpApplicationSettings

proc start*(this: NimHttpApplication) =
  info """███╗   ██╗██╗███╗   ███╗ █████╗ ███████╗██╗  ██╗"""
  info """████╗  ██║██║████╗ ████║██╔══██╗██╔════╝██║  ██║"""
  info """██╔██╗ ██║██║██╔████╔██║███████║███████╗███████║"""
  info """██║╚██╗██║██║██║╚██╔╝██║██╔══██║╚════██║██╔══██║"""
  info """██║ ╚████║██║██║ ╚═╝ ██║██║  ██║███████║██║  ██║"""
  info """╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"""
  info "Starting server"
  info "Application is running on " & this.settings.getHostUrl
  waitFor newAsyncHttpServer().serve(
    port     = Port(this.settings.port),
    address  = this.settings.host,
    callback = proc (request: Request) {.async, gcsafe.} =
    debug "Incoming request -> route path " & request.url.path
    try:
      await request.process
    except HttpException as e:
      if this.settings.errorHandle.isNil:
        this.settings.errorHandle = NimHttpApplicationErrorHandle(exception: e)
      else: this.settings.errorHandle.exception = e
      await this.settings.errorHandle.catch(request)
  )