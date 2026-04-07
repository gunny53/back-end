# Quick Reference Guide

A quick reference for common tasks in the NimHTTP framework.

## Table of Contents
- [Configuration](#configuration)
- [Middleware](#middleware)
- [Interceptors](#interceptors)
- [Controllers](#controllers)
- [Guards](#guards)
- [Error Handling](#error-handling)
- [Utilities](#utilities)

## Configuration

### Get Configuration
```nim
import nim_http/core/config

let config = getConfig()
```

### Get Values
```nim
# String with default
let host = config.get("SERVER_HOST", "localhost")

# Integer
let port = config.getInt("SERVER_PORT", 8888)

# Boolean
let debug = config.getBool("DEBUG_MODE", false)

# Float
let timeout = config.getFloat("TIMEOUT", 30.0)

# Check existence
if config.has("JWT_SECRET"):
  let secret = config.get("JWT_SECRET")
```

### Set Values
```nim
config.set("CUSTOM_KEY", "value")
```

## Middleware

### Apply Global Middleware
```nim
import nim_http/core/middleware

let middleware = getMiddlewareConsumer()

# Logger
middleware.apply(loggerMiddleware)

# CORS
middleware.apply(corsMiddleware("*", "GET,POST,PUT,DELETE"))

# Rate Limiting
middleware.apply(rateLimitMiddleware(100, 60000))  # 100 req/min

# Security Headers
middleware.apply(securityHeadersMiddleware())
```

### Apply Route-Specific Middleware
```nim
middleware.apply(authMiddleware, @["/api/secure", "/api/admin"])
```

### Custom Middleware
```nim
proc myMiddleware(req: Request, next: NextFunction): Future[void] {.async.} =
  # Before request
  echo "Before: ", req.url.path
  
  # Process request
  await next()
  
  # After request
  echo "After: ", req.url.path

middleware.apply(myMiddleware)
```

## Interceptors

### Register Interceptors
```nim
import nim_http/core/interceptor

# Logging
registerInterceptor(LoggingInterceptor(verbose: true))

# Caching
registerInterceptor(newCacheInterceptor(ttl = 60))
```

### Custom Interceptor
```nim
type MyInterceptor = ref object of Interceptor

method intercept(
  self: MyInterceptor,
  context: ExecutionContext,
  next: CallHandler
): Future[Response] {.async, gcsafe.} =
  # Before
  let start = cpuTime()
  
  # Execute
  result = await next.handle()
  
  # After
  let duration = cpuTime() - start
  echo "Took ", duration, "s"

registerInterceptor(MyInterceptor())
```

## Controllers

### Basic Controller
```nim
import ../../nim_http/core/controller

Controller MyController("api/v1"):
  
  [GET("")]
  proc list() =
    Http200 "List"
  
  [GET(":id")]
  proc getById(id {.param.}: int) =
    Http200 "ID: " & $id
  
  [POST("")]
  proc create(data {.body.}: MyDto) =
    Http201 data
```

### With Query Parameters
```nim
[GET("search")]
proc search(
  q {.query.}: string = "",
  page {.query.}: int = 1,
  limit {.query.}: int = 10
) =
  Http200 %*{"query": q, "page": page, "limit": limit}
```

### With Guards
```nim
[GET("protected")]
[UseGuard(AuthGuard)]
proc protected() =
  Http200 "Protected data"
```

### Response Types
```nim
Http200 "OK"                    # 200 with text
Http201 myObject                # 201 with JSON
Http204()                       # 204 no content
Http400 "Bad request"           # 400 with message
Http403 "Forbidden"             # 403
Http404 "Not found"             # 404
```

## Guards

### Create Guard
```nim
import asynchttpserver
import ../../nim_http/core/[guard, exception, di]

class MyGuard*() of Guard:
  
  method canActivate(self: MyGuard, req: Request): bool =
    if not req.headers.hasKey("Authorization"):
      raise UNAUTHORIZED("Auth required")
    
    # Validate logic here
    return true
```

### Use Guard
```nim
Controller SecureController("api/secure"):
  
  [GET("data")]
  [UseGuard(MyGuard)]
  proc getData() =
    Http200 "Protected data"
```

## Error Handling

### Throw Errors
```nim
# Built-in exceptions
raise BAD_REQUEST("Invalid input")
raise UNAUTHORIZED("Not authorized")
raise FORBIDDEN("Access denied")
raise NOT_FOUND("Resource not found")
raise INTERNAL_SERVER_ERROR("Server error")
```

### Custom Error Handler
```nim
import nim_http/core/[app, exception]

type MyErrorHandle = ref object of NimHttpApplicationErrorHandle

method catch(e: MyErrorHandle, req: Request): Future[void] {.async.} =
  let response = %*{
    "error": e.exception.message,
    "code": e.exception.statusCode.int,
    "timestamp": unixTimestamp()
  }
  await req.respond(e.exception.statusCode, $response)

# Use in app
settings.errorHandle = MyErrorHandle()
```

## Utilities

### String Operations
```nim
import nim_http/core/helpers

slugify("Hello World")          # "hello-world"
truncate("Long text", 10)       # "Long te..."
camelCase("user_name")          # "userName"
pascalCase("user-name")         # "UserName"
snakeCase("userName")           # "user_name"
```

### Validation
```nim
isEmail("user@example.com")     # true
isURL("https://example.com")    # true
isNumeric("12345")              # true
isAlphanumeric("abc123")        # true
```

### JSON Operations
```nim
let json = safeParseJson("""{"name":"John"}""")
let name = json.getString("name", "Unknown")
let age = json.getInt("age", 0)
let active = json.getBool("active", false)
```

### Time Operations
```nim
let ts = unixTimestamp()        # Unix timestamp (seconds)
let tsMs = unixTimestampMs()    # Unix timestamp (milliseconds)
let iso = formatTimeISO(now())  # ISO8601 format
```

### Random Operations
```nim
let str = randomString(16)      # Random 16-char string
let num = randomInt(1, 100)     # Random 1-100
let uuid = generateUUID()       # UUID-like string
```

### Hash Operations
```nim
let hash = hashMD5("password")
let encoded = base64Encode("text")
let decoded = base64Decode(encoded)
```

### Performance
```nim
# Benchmark
benchmark "operation":
  # Your code here
  discard

# Measure
let (result, duration) = measureTime proc(): int =
  return 42
echo "Took ", duration, "ms"
```

### Collections
```nim
let unique = distinct(@[1, 2, 2, 3])  # [1, 2, 3]
let chunks = chunk(@[1, 2, 3, 4], 2)  # [[1, 2], [3, 4]]
```

## Application Setup

### Basic Setup
```nim
import nim_http/core/[app, config]

let config = getConfig()
let settings = NimHttpApplicationSettings()
settings.host = config.get("SERVER_HOST", "0.0.0.0")
settings.port = config.getInt("SERVER_PORT", 8888)

let app = NimHttpApplication(settings: settings)
app.start()
```

### With Middleware
```nim
import nim_http/core/middleware

let middleware = getMiddlewareConsumer()
middleware.apply(loggerMiddleware)
middleware.apply(corsMiddleware())
settings.middleware = middleware
```

### With Graceful Shutdown
```nim
let app = NimHttpApplication(settings: settings)

when defined(posix):
  proc handleShutdown() {.noconv.} =
    app.stop()
    quit(0)
  setControlCHook(handleShutdown)

app.start()
```

## Environment Variables

### .env File
```bash
# Server
SERVER_HOST=0.0.0.0
SERVER_PORT=8888

# Features
CACHE_ENABLED=true
RATE_LIMIT_ENABLED=true
LOGGING_ENABLED=true

# CORS
CORS_ORIGIN=*
CORS_METHODS=GET,POST,PUT,DELETE
```

### Access in Code
```nim
let config = getConfig()
let cacheEnabled = config.getBool("CACHE_ENABLED", false)
```

## Common Patterns

### Service Pattern
```nim
import nim_http/core/di

class UserService*() of SingletonObj:
  proc getUser*(self: UserService, id: int): string =
    return "User " & $id

# Inject
let userService = inject(UserService)
```

### DTO Pattern
```nim
type
  CreateUserDto = ref object
    username*: string
    email*: string
  
  UserResponseDto = ref object
    id*: string
    username*: string
    email*: string
```

### Repository Pattern
```nim
class UserRepository*() of SingletonObj:
  proc findById*(self: UserRepository, id: int): User =
    # Database logic here
    discard
  
  proc save*(self: UserRepository, user: User): void =
    # Save logic here
    discard
```

## Tips & Best Practices

1. **Always use configuration** for environment-specific values
2. **Apply middleware in order**: Logger → Security → CORS → Rate Limit → Body Parser
3. **Use guards** for authentication/authorization
4. **Use interceptors** for cross-cutting concerns (logging, caching)
5. **Validate input** in controllers
6. **Use DTOs** for type safety
7. **Handle errors** with appropriate HTTP codes
8. **Document** your APIs
9. **Test** middleware and interceptors
10. **Monitor** performance with logging interceptor

## Common Issues

### Port Already in Use
```nim
# Change port in .env or config
SERVER_PORT=3000
```

### CORS Issues
```nim
# Enable CORS middleware
middleware.apply(corsMiddleware("*", "GET,POST,PUT,DELETE"))
```

### Rate Limit Too Strict
```nim
# Adjust limits
middleware.apply(rateLimitMiddleware(1000, 60000))  # 1000 req/min
```

### Large Request Body
```nim
# Increase limit
middleware.apply(bodyParserMiddleware(50_000_000))  # 50MB
```

## Resources

- **README.md**: Project overview and quick start
- **EXAMPLES.md**: Detailed usage examples
- **CHANGELOG.md**: Version history and migration guide
- **IMPLEMENTATION_SUMMARY.md**: Technical details

---

For more detailed examples, see [EXAMPLES.md](EXAMPLES.md)
