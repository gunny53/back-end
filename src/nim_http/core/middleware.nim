## Middleware Module
## Provides middleware architecture for request/response processing

import asyncdispatch, asynchttpserver, tables, times

type
  NextFunction* = proc(): Future[void] {.gcsafe, closure.}
  
  MiddlewareFunction* = proc(
    req: Request,
    next: NextFunction
  ): Future[void] {.gcsafe, closure.}

  MiddlewareConsumer* = ref object
    middlewares: seq[MiddlewareFunction]
    routes: Table[string, seq[MiddlewareFunction]]

proc newMiddlewareConsumer*(): MiddlewareConsumer =
  ## Creates a new middleware consumer
  MiddlewareConsumer(
    middlewares: @[],
    routes: initTable[string, seq[MiddlewareFunction]]()
  )

proc apply*(consumer: MiddlewareConsumer, middleware: MiddlewareFunction) =
  ## Applies middleware to all routes
  consumer.middlewares.add(middleware)

proc apply*(consumer: MiddlewareConsumer, middleware: MiddlewareFunction, routes: seq[string]) =
  ## Applies middleware to specific routes
  for route in routes:
    if not consumer.routes.hasKey(route):
      consumer.routes[route] = @[]
    consumer.routes[route].add(middleware)

proc execute*(consumer: MiddlewareConsumer, req: Request): Future[void] {.async.} =
  ## Executes all middlewares for a request
  var index = 0
  let allMiddlewares = consumer.middlewares
  
  # Get route-specific middlewares
  var routeMiddlewares: seq[MiddlewareFunction] = @[]
  for route, mws in consumer.routes:
    if req.url.path.startsWith(route):
      routeMiddlewares.add(mws)
  
  let totalMiddlewares = allMiddlewares & routeMiddlewares
  
  proc next(): Future[void] {.async, gcsafe.} =
    if index < totalMiddlewares.len:
      let middleware = totalMiddlewares[index]
      index.inc()
      await middleware(req, next)
  
  await next()

# Built-in middleware implementations

proc loggerMiddleware*(req: Request, next: NextFunction): Future[void] {.async.} =
  ## Logs incoming requests with timestamp and duration
  let startTime = cpuTime()
  let timestamp = now().format("yyyy-MM-dd HH:mm:ss")
  
  echo "[", timestamp, "] ", req.reqMethod, " ", req.url.path
  
  await next()
  
  let duration = cpuTime() - startTime
  echo "[", timestamp, "] Completed in ", duration * 1000, "ms"

proc corsMiddleware*(
  allowOrigin: string = "*",
  allowMethods: string = "GET, POST, PUT, DELETE, OPTIONS, PATCH",
  allowHeaders: string = "Content-Type, Authorization",
  maxAge: int = 86400
): MiddlewareFunction =
  ## CORS middleware factory
  result = proc(req: Request, next: NextFunction): Future[void] {.async, gcsafe.} =
    # Add CORS headers to response
    req.headers["Access-Control-Allow-Origin"] = allowOrigin
    req.headers["Access-Control-Allow-Methods"] = allowMethods
    req.headers["Access-Control-Allow-Headers"] = allowHeaders
    req.headers["Access-Control-Max-Age"] = $maxAge
    
    # Handle preflight requests
    if req.reqMethod == HttpOptions:
      await req.respond(Http204, "", req.headers)
    else:
      await next()

proc rateLimitMiddleware*(
  maxRequests: int = 100,
  windowMs: int = 60000
): MiddlewareFunction =
  ## Rate limiting middleware factory
  var requestCounts = initTable[string, tuple[count: int, resetTime: Time]]()
  
  result = proc(req: Request, next: NextFunction): Future[void] {.async, gcsafe.} =
    let clientIp = req.headers.getOrDefault("X-Forwarded-For", req.hostname)
    let now = getTime()
    
    if requestCounts.hasKey(clientIp):
      var entry = requestCounts[clientIp]
      
      # Reset counter if window expired
      if (now - entry.resetTime).inMilliseconds > windowMs:
        entry.count = 0
        entry.resetTime = now
      
      entry.count.inc()
      requestCounts[clientIp] = entry
      
      if entry.count > maxRequests:
        await req.respond(Http429, "Too many requests", req.headers)
        return
    else:
      requestCounts[clientIp] = (count: 1, resetTime: now)
    
    await next()

proc bodyParserMiddleware*(maxBodySize: int = 10_000_000): MiddlewareFunction =
  ## JSON body parser middleware
  result = proc(req: Request, next: NextFunction): Future[void] {.async, gcsafe.} =
    # Body parsing is handled by the framework
    # This validates size limits
    if req.body.len > maxBodySize:
      await req.respond(Http413, "Request body too large", req.headers)
      return
    
    await next()

proc securityHeadersMiddleware*(): MiddlewareFunction =
  ## Adds common security headers
  result = proc(req: Request, next: NextFunction): Future[void] {.async, gcsafe.} =
    req.headers["X-Content-Type-Options"] = "nosniff"
    req.headers["X-Frame-Options"] = "DENY"
    req.headers["X-XSS-Protection"] = "1; mode=block"
    req.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    
    await next()

# Export global middleware consumer
var globalMiddlewareConsumer* {.threadvar.}: MiddlewareConsumer

proc initGlobalMiddleware*() =
  ## Initializes the global middleware consumer
  if globalMiddlewareConsumer.isNil:
    globalMiddlewareConsumer = newMiddlewareConsumer()

proc getMiddlewareConsumer*(): MiddlewareConsumer =
  ## Gets the global middleware consumer
  if globalMiddlewareConsumer.isNil:
    initGlobalMiddleware()
  return globalMiddlewareConsumer
