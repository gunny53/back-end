# Example Service Usage

This document demonstrates how to use the enhanced features of the NimHTTP framework.

## Configuration Example

```nim
import nim_http/core/config

# Get configuration
let config = getConfig()

# Get values with defaults
let dbHost = config.get("DB_HOST", "localhost")
let dbPort = config.getInt("DB_PORT", 5432)
let debugMode = config.getBool("DEBUG_MODE", false)

# Check if key exists
if config.has("JWT_SECRET"):
  let secret = config.get("JWT_SECRET")
```

## Middleware Usage

```nim
import nim_http/core/middleware

# Custom middleware
proc authMiddleware(req: Request, next: NextFunction): Future[void] {.async.} =
  if not req.headers.hasKey("Authorization"):
    await req.respond(Http401, "Unauthorized")
    return
  
  # Validate token
  await next()

# Apply middleware
let consumer = getMiddlewareConsumer()
consumer.apply(authMiddleware)
consumer.apply(loggerMiddleware)

# Apply to specific routes
consumer.apply(authMiddleware, @["/api/secure", "/api/admin"])
```

## Interceptor Usage

```nim
import nim_http/core/interceptor

# Custom response transformation
type MyTransformInterceptor = ref object of Interceptor

method intercept(
  self: MyTransformInterceptor,
  context: ExecutionContext,
  next: CallHandler
): Future[Response] {.async, gcsafe.} =
  var response = await next.handle()
  
  # Add custom headers
  response.headers["X-Custom-Header"] = "MyValue"
  
  # Transform response body
  if response.body.startsWith("{"):
    let json = parseJson(response.body)
    json["timestamp"] = %unixTimestamp()
    response.body = $json
  
  return response

# Register interceptor
registerInterceptor(MyTransformInterceptor())
```

## Dependency Injection Usage

```nim
import nim_http/core/di

# Define a service
class UserService*() of SingletonObj:
  proc getUser*(self: UserService, id: int): string =
    return "User " & $id

# Register with custom scope
register(UserService, Singleton, proc(): SingletonObj = new UserService())

# Inject in controller
let userService = inject(UserService)
let user = userService.getUser(1)
```

## Helper Utilities Usage

```nim
import nim_http/core/helpers

# String utilities
let slug = slugify("Hello World 123")  # "hello-world-123"
let truncated = truncate("Long text here", 10)  # "Long te..."
let camel = camelCase("user_name")  # "userName"
let pascal = pascalCase("user-name")  # "UserName"
let snake = snakeCase("userName")  # "user_name"

# Validation
if isEmail("user@example.com"):
  echo "Valid email"

if isURL("https://example.com"):
  echo "Valid URL"

# JSON utilities
let json = parseJson("""{"name": "John", "age": 30}""")
let name = json.getString("name", "Unknown")
let age = json.getInt("age", 0)

# Random utilities
let randomStr = randomString(16)  # Random 16-char string
let randomNum = randomInt(1, 100)  # Random number between 1-100
let uuid = generateUUID()  # UUID-like string

# Time utilities
let timestamp = unixTimestamp()
let timestampMs = unixTimestampMs()
let formatted = formatTimeISO(now())

# Performance measurement
benchmark "slow operation":
  # Some slow code
  for i in 0..1000000:
    discard

let (result, duration) = measureTime proc(): int =
  var sum = 0
  for i in 0..1000:
    sum += i
  return sum

echo "Result: ", result, ", took ", duration, "ms"
```

## Complete Controller Example

```nim
import ../../nim_http/core/controller
import ../../nim_http/core/helpers
import ../../libs/auth/auth_guard
import asyncdispatch
import json

type 
  CreateUserDto = ref object
    username*: string
    email*: string
    age*: int
  
  UserResponseDto = ref object
    id*: string
    username*: string
    email*: string
    age*: int
    createdAt*: int64

Controller UsersController("api/v1/users"):

  [GET("")]
  [UseGuard(AuthGuard)]
  proc list(
    page {.query.}: int = 1,
    limit {.query.}: int = 10
  ) =
    # Validate pagination
    let safePage = if page < 1: 1 else: page
    let safeLimit = if limit < 1 or limit > 100: 10 else: limit
    
    # Build response
    let response = %*{
      "data": [],
      "page": safePage,
      "limit": safeLimit,
      "total": 0
    }
    
    Http200 response

  [GET(":id")]
  [UseGuard(AuthGuard)]
  proc getById(id {.param.}: int) =
    # Generate UUID for user
    let userId = generateUUID()
    
    let user = UserResponseDto(
      id: userId,
      username: "user" & $id,
      email: "user" & $id & "@example.com",
      age: randomInt(18, 65),
      createdAt: unixTimestamp()
    )
    
    Http200 user

  [POST("")]
  [UseGuard(AuthGuard)]
  proc create(user {.body.}: CreateUserDto) =
    # Validate email
    if not isEmail(user.email):
      Http400 %*{"error": "Invalid email format"}
      return
    
    # Validate username
    if not isAlphanumeric(user.username):
      Http400 %*{"error": "Username must be alphanumeric"}
      return
    
    # Create user response
    let newUser = UserResponseDto(
      id: generateUUID(),
      username: user.username,
      email: user.email,
      age: user.age,
      createdAt: unixTimestamp()
    )
    
    Http201 newUser

  [PUT(":id")]
  [UseGuard(AuthGuard)]
  proc update(
    id {.param.}: int,
    user {.body.}: CreateUserDto
  ) =
    # Validate
    if not isEmail(user.email):
      Http400 %*{"error": "Invalid email format"}
      return
    
    let updated = UserResponseDto(
      id: "existing-uuid",
      username: user.username,
      email: user.email,
      age: user.age,
      createdAt: unixTimestamp()
    )
    
    Http200 updated

  [DELETE(":id")]
  [UseGuard(AuthGuard)]
  proc delete(id {.param.}: int) =
    Http204()

  [GET("search")]
  proc search(q {.query.}: string = "") =
    let slug = slugify(q)
    let response = %*{
      "query": q,
      "slug": slug,
      "results": []
    }
    Http200 response
```

## Environment Configuration Example

Create a `.env` file:

```bash
# Application
APP_NAME=My NimHTTP App
APP_ENV=development

# Server
SERVER_HOST=0.0.0.0
SERVER_PORT=3000
SERVER_TIMEOUT=30000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp
DB_USER=postgres
DB_PASSWORD=secret

# Security
JWT_SECRET=your-super-secret-key-here
JWT_EXPIRATION=86400

# Features
CACHE_ENABLED=true
CACHE_TTL=300
RATE_LIMIT_ENABLED=true
RATE_LIMIT_MAX=100
RATE_LIMIT_WINDOW_MS=60000

# CORS
CORS_ENABLED=true
CORS_ORIGIN=http://localhost:3000
CORS_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_HEADERS=Content-Type,Authorization

# Logging
LOGGING_ENABLED=true
LOG_LEVEL=debug
```

## Application Bootstrap Example

```nim
import nim_http/core/app
import nim_http/core/config
import nim_http/core/middleware
import nim_http/core/interceptor
import libs/error/handle
import apps/users/main  # Import your controllers

# Get configuration
let config = getConfig()

# Setup application
let settings = NimHttpApplicationSettings()
settings.host = config.get("SERVER_HOST", "0.0.0.0")
settings.port = config.getInt("SERVER_PORT", 8888)
settings.errorHandle = HttpErrorHandle()

# Configure middleware
let middleware = getMiddlewareConsumer()
middleware.apply(loggerMiddleware)
middleware.apply(securityHeadersMiddleware())

if config.getBool("CORS_ENABLED", true):
  middleware.apply(corsMiddleware(
    config.get("CORS_ORIGIN", "*"),
    config.get("CORS_METHODS", "GET,POST,PUT,DELETE"),
    config.get("CORS_HEADERS", "Content-Type,Authorization")
  ))

if config.getBool("RATE_LIMIT_ENABLED", true):
  middleware.apply(rateLimitMiddleware(
    config.getInt("RATE_LIMIT_MAX", 100),
    config.getInt("RATE_LIMIT_WINDOW_MS", 60000)
  ))

# Configure interceptors
if config.getBool("LOGGING_ENABLED", true):
  registerInterceptor(LoggingInterceptor(verbose: true))

if config.getBool("CACHE_ENABLED", false):
  registerInterceptor(newCacheInterceptor(config.getInt("CACHE_TTL", 60)))

# Start application
echo "🚀 Starting ", config.get("APP_NAME", "NimHTTP App")
echo "📦 Environment: ", config.get("APP_ENV", "production")
NimHttpApplication(settings: settings).start()
```
