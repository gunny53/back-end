import asynchttpserver, asyncdispatch, strutils, logging, tables, json
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
  server*: AsyncHttpServer  # Store server instance for lifecycle management

proc processRequestWithMiddleware(
  app: NimHttpApplication,
  req: Request
): Future[void] {.async.} =
  ## Processes request through middleware pipeline then routing with interceptors
  
  # Create middleware consumer if not exists
  if app.settings.middleware.isNil:
    app.settings.middleware = newMiddlewareConsumer()
  
  # Execute middleware chain
  try:
    await app.settings.middleware.execute(req)
    
    # After middleware, process the route with interceptors
    debug "Processing route: " & req.url.path
    
    # Create execution context for interceptors
    let context = ExecutionContext(
      request: req,
      handler: req.url.path,
      startTime: cpuTime(),
      metadata: newJNull()
    )
    
    # Apply interceptors around route processing
    await applyInterceptors(context, proc(): Future[void] {.async, gcsafe, closure.} =
      await req.process
    )
    
  except HttpException as e:
    # Handle HTTP exceptions
    if app.settings.errorHandle.isNil:
      app.settings.errorHandle = NimHttpApplicationErrorHandle(exception: e)
    else:
      app.settings.errorHandle.exception = e
    await app.settings.errorHandle.catch(req)
    
  except CatchableError as e:
    # Handle other errors
    error "Unhandled error: " & e.msg
    let httpEx = INTERNAL_SERVER_ERROR(e.msg)
    if app.settings.errorHandle.isNil:
      app.settings.errorHandle = NimHttpApplicationErrorHandle(exception: httpEx)
    else:
      app.settings.errorHandle.exception = httpEx
    await app.settings.errorHandle.catch(req)

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
  
  # Create and store server instance for lifecycle management
  this.server = newAsyncHttpServer()
  
  waitFor this.server.serve(
    port     = Port(this.settings.port),
    address  = this.settings.host,
    callback = proc (request: Request) {.async.} =
      debug "Incoming request -> " & request.reqMethod & " " & request.url.path
      await this.processRequestWithMiddleware(request)
  )

proc stop*(this: NimHttpApplication) =
  ## Gracefully stops the server
  if not this.server.isNil:
    info "Shutting down server..."
    this.server.close()
    info "Server stopped"
