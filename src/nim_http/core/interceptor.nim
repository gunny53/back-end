## Interceptor Module
## Provides interceptor architecture for cross-cutting concerns
## Inspired by NestJS interceptors
## Note: Interceptors work with the existing controller pipeline

import asyncdispatch, asynchttpserver, times, json, tables, di

type
  ExecutionContext* = ref object
    request*: Request
    handler*: string
    startTime*: float
    metadata*: JsonNode

  CallHandler* = ref object
    handle*: proc(): Future[void] {.gcsafe, closure.}

  Interceptor* = ref object of SingletonObj
    ## Base interceptor class

method intercept*(
  self: Interceptor,
  context: ExecutionContext,
  next: CallHandler
): Future[void] {.base, async, gcsafe.} =
  ## Base intercept method - override in subclasses
  if not next.handle.isNil:
    await next.handle()

# Legacy method for backward compatibility - removed as not needed

# Built-in Interceptors

type
  LoggingInterceptor* = ref object of Interceptor
    verbose*: bool

method intercept*(
  self: LoggingInterceptor,
  context: ExecutionContext,
  next: CallHandler
): Future[void] {.async, gcsafe.} =
  let startTime = cpuTime()
  let timestamp = now().format("yyyy-MM-dd HH:mm:ss")
  
  if self.verbose:
    echo "[INTERCEPTOR][", timestamp, "] Before: ", context.handler
  
  if not next.handle.isNil:
    await next.handle()
  
  let duration = (cpuTime() - startTime) * 1000
  if self.verbose:
    echo "[INTERCEPTOR][", timestamp, "] After: ", context.handler, " (", duration, "ms)"

# Note: Cache, Transform, Timeout, and ErrorMapping interceptors would need
# access to response data which requires deeper integration with the controller pipeline.
# For now, we provide the logging interceptor which works with the existing architecture.

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
  handler: proc(): Future[void] {.gcsafe, closure.}
): Future[void] {.async.} =
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
      handle: proc(): Future[void] {.async, gcsafe, closure.} =
        await interceptor.intercept(context, nextHandler)
    )
  
  # Execute the chain
  if not currentHandler.handle.isNil:
    await currentHandler.handle()

# Simplified cache interceptor that works with existing architecture
type
  CacheInterceptor* = ref object of Interceptor
    ttl*: int

proc newCacheInterceptor*(ttl: int = 60): CacheInterceptor =
  ## Creates a new cache interceptor with specified TTL
  ## Note: Actual caching requires integration with response handling
  result = CacheInterceptor(ttl: ttl)

method intercept*(
  self: CacheInterceptor,
  context: ExecutionContext,
  next: CallHandler
): Future[void] {.async, gcsafe.} =
  ## Placeholder for cache interceptor
  ## Full implementation requires access to response data
  if not next.handle.isNil:
    await next.handle()
