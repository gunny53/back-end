import asynchttpserver, asyncdispatch, strutils, logging, tables
import route
import exception
import middleware
import interceptor
import config

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
  middleware*:  MiddlewareConsumer

func getHostUrl(this: NimHttpApplicationSettings): string = "http://" & this.host & ":" & $this.port

type NimHttpApplication* = ref object of RootObj
  settings*: NimHttpApplicationSettings

proc processRequestWithMiddleware(
  app: NimHttpApplication,
  req: Request
): Future[void] {.async.} =
  ## Processes request through middleware pipeline then routing
  var processed = false
  
  # Create middleware consumer if not exists
  if app.settings.middleware.isNil:
    app.settings.middleware = newMiddlewareConsumer()
  
  # Execute middleware chain
  try:
    await app.settings.middleware.execute(req)
    
    # After middleware, process the route
    debug "Processing route: " & req.url.path
    await req.process
    processed = true
    
  except HttpException as e:
    # Handle HTTP exceptions
    if app.settings.errorHandle.isNil:
      app.settings.errorHandle = NimHttpApplicationErrorHandle(exception: e)
    else:
      app.settings.errorHandle.exception = e
    await app.settings.errorHandle.catch(req)
    processed = true
    
  except CatchableError as e:
    # Handle other errors
    error "Unhandled error: " & e.msg
    let httpEx = INTERNAL_SERVER_ERROR(e.msg)
    if app.settings.errorHandle.isNil:
      app.settings.errorHandle = NimHttpApplicationErrorHandle(exception: httpEx)
    else:
      app.settings.errorHandle.exception = httpEx
    await app.settings.errorHandle.catch(req)
    processed = true

proc start*(this: NimHttpApplication) =
  info """███╗   ██╗██╗███╗   ███╗ █████╗ ███████╗██╗  ██╗"""
  info """████╗  ██║██║████╗ ████║██╔══██╗██╔════╝██║  ██║"""
  info """██╔██╗ ██║██║██╔████╔██║███████║███████╗███████║"""
  info """██║╚██╗██║██║██║╚██╔╝██║██╔══██║╚════██║██╔══██║"""
  info """██║ ╚████║██║██║ ╚═╝ ██║██║  ██║███████║██║  ██║"""
  info """╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"""
  info "Starting server"
  info "Application is running on " & this.settings.getHostUrl
  
  # Get configuration
  let config = getConfig()
  let envName = config.get("APP_ENV", "production")
  info "Environment: " & envName
  
  # Initialize middleware if not provided
  if this.settings.middleware.isNil:
    this.settings.middleware = getMiddlewareConsumer()
  
  waitFor newAsyncHttpServer().serve(
    port     = Port(this.settings.port),
    address  = this.settings.host,
    callback = proc (request: Request) {.async.} =
      debug "Incoming request -> " & request.reqMethod & " " & request.url.path
      await this.processRequestWithMiddleware(request)
  )
