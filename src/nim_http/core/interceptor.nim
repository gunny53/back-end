## Interceptor Module
## Provides interceptor architecture for cross-cutting concerns
## Inspired by NestJS interceptors

import asyncdispatch, asynchttpserver, times, json, tables, di, response

type
  ExecutionContext* = ref object
    request*: Request
    handler*: string
    startTime*: float
    metadata*: JsonNode

  CallHandler* = ref object
    handle*: proc(): Future[Response] {.gcsafe, closure.}

  Interceptor* = ref object of SingletonObj
    ## Base interceptor class

method intercept*(
  self: Interceptor,
  context: ExecutionContext,
  next: CallHandler
): Future[Response] {.base, async, gcsafe.} =
  ## Base intercept method - override in subclasses
  if not next.handle.isNil:
    result = await next.handle()

# Legacy method for backward compatibility
method intercept*(this: Interceptor, ctx: Request, next: proc(): Future[Response]): Future[Response] {.base, gcsafe.} = 
  ## Legacy interceptor method for backward compatibility
  ## This method should be overridden in subclasses
  ## Returns an empty response to maintain API compatibility
  let emptyResponse = Response(statusCode: Http200, body: "")
  return newFuture[Response]("legacy_intercept")

# Built-in Interceptors

type
  LoggingInterceptor* = ref object of Interceptor
    verbose*: bool

method intercept*(
  self: LoggingInterceptor,
  context: ExecutionContext,
  next: CallHandler
): Future[Response] {.async, gcsafe.} =
  let startTime = cpuTime()
  let timestamp = now().format("yyyy-MM-dd HH:mm:ss")
  
  if self.verbose:
    echo "[INTERCEPTOR][", timestamp, "] Before: ", context.handler
  
  if not next.handle.isNil:
    result = await next.handle()
  
  let duration = (cpuTime() - startTime) * 1000
  if self.verbose:
    echo "[INTERCEPTOR][", timestamp, "] After: ", context.handler, " (", duration, "ms)"

type
  CacheInterceptor* = ref object of Interceptor
    ttl*: int  # Time to live in seconds
    cache*: TableRef[string, tuple[data: string, expiry: Time]]

proc newCacheInterceptor*(ttl: int = 60): CacheInterceptor =
  ## Creates a new cache interceptor with specified TTL
  result = CacheInterceptor(
    ttl: ttl,
    cache: newTable[string, tuple[data: string, expiry: Time]]()
  )

method intercept*(
  self: CacheInterceptor,
  context: ExecutionContext,
  next: CallHandler
): Future[Response] {.async, gcsafe.} =
  let cacheKey = context.request.url.path
  let now = getTime()
  
  # Check cache
  if self.cache.hasKey(cacheKey):
    let cached = self.cache[cacheKey]
    if now < cached.expiry:
      # Serve from cache
      result = Response(statusCode: Http200, body: cached.data)
      return
  
  # Execute handler and cache result
  if not next.handle.isNil:
    result = await next.handle()
    
    # Cache the response
    let expiry = now + initDuration(seconds = self.ttl)
    self.cache[cacheKey] = (data: result.body, expiry: expiry)

type
  TransformInterceptor* = ref object of Interceptor
    transform*: proc(data: JsonNode): JsonNode {.gcsafe.}

method intercept*(
  self: TransformInterceptor,
  context: ExecutionContext,
  next: CallHandler
): Future[Response] {.async, gcsafe.} =
  ## Transforms response data before sending to client
  if not next.handle.isNil:
    result = await next.handle()
    
    # Transform response if it's JSON
    try:
      if not self.transform.isNil:
        let jsonData = parseJson(result.body)
        let transformed = self.transform(jsonData)
        result.body = $transformed
    except JsonParsingError:
      # Not JSON, return as-is
      discard

type
  TimeoutInterceptor* = ref object of Interceptor
    timeoutMs*: int

method intercept*(
  self: TimeoutInterceptor,
  context: ExecutionContext,
  next: CallHandler
): Future[Response] {.async, gcsafe.} =
  ## Enforces timeout on request handling
  let timeoutFuture = sleepAsync(self.timeoutMs)
  let handlerFuture = if not next.handle.isNil: next.handle() else: newFuture[Response]()
  
  # Race between timeout and handler
  let completed = await handlerFuture or timeoutFuture
  
  if completed == timeoutFuture:
    # Timeout occurred
    result = Response(statusCode: Http408, body: "Request timeout")
  else:
    result = handlerFuture.read()

type
  ErrorMappingInterceptor* = ref object of Interceptor
    errorMap*: TableRef[string, HttpCode]

method intercept*(
  self: ErrorMappingInterceptor,
  context: ExecutionContext,
  next: CallHandler
): Future[Response] {.async, gcsafe.} =
  ## Maps errors to appropriate HTTP status codes
  try:
    if not next.handle.isNil:
      result = await next.handle()
  except CatchableError as e:
    let errorType = $e.name
    let statusCode = if self.errorMap.hasKey(errorType):
      self.errorMap[errorType]
    else:
      Http500
    
    let errorResponse = %*{
      "error": errorType,
      "message": e.msg,
      "timestamp": now().format("yyyy-MM-dd'T'HH:mm:ss'Z'")
    }
    result = Response(statusCode: statusCode, body: $errorResponse)

# Global interceptor registry
type
  InterceptorRegistry* = ref object
    interceptors*: seq[Interceptor]

var globalInterceptors* {.threadvar.}: InterceptorRegistry

proc initInterceptors*() =
  if globalInterceptors.isNil:
    globalInterceptors = InterceptorRegistry(interceptors: @[])

proc registerInterceptor*(interceptor: Interceptor) =
  initInterceptors()
  globalInterceptors.interceptors.add(interceptor)

proc applyInterceptors*(
  context: ExecutionContext,
  handler: proc(): Future[Response] {.gcsafe, closure.}
): Future[Response] {.async.} =
  ## Applies all registered interceptors to a request
  initInterceptors()
  
  var currentHandler = CallHandler(handle: handler)
  
  # Apply interceptors in reverse order to create proper chain
  # Reverse order ensures the first registered interceptor wraps all others,
  # creating a nested call structure where each interceptor can execute
  # before and after the next one in the chain
  for i in countdown(globalInterceptors.interceptors.len - 1, 0):
    let interceptor = globalInterceptors.interceptors[i]
    let nextHandler = currentHandler
    
    currentHandler = CallHandler(
      handle: proc(): Future[Response] {.async, gcsafe, closure.} =
        result = await interceptor.intercept(context, nextHandler)
    )
  
  # Execute the chain
  if not currentHandler.handle.isNil:
    result = await currentHandler.handle()
