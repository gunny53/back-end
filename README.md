# NimHTTP Framework

A high-performance, async web framework for Nim inspired by NestJS and Spring Boot.

## Features

- 🚀 **High Performance**: Built on Nim's async/await with zero-cost abstractions
- 🎯 **Decorator-Based Routing**: Clean, intuitive API similar to NestJS
- 💉 **Dependency Injection**: Powerful DI container with singleton support
- 🛡️ **Guards & Middleware**: Flexible authentication and authorization
- 🔧 **Type-Safe**: Leverages Nim's static typing for compile-time safety
- 📦 **Modular Architecture**: Organized project structure following best practices

## Quick Start

### Prerequisites

- Nim >= 2.2.2
- nimble (Nim package manager)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd back-end

# Build the project
nim c --define:release --threads:on src/main.nim

# Run the application
./src/main
```

### Using Docker

```bash
# Build and run with Docker Compose
docker-compose up --build

# Or build Docker image manually
docker build -t nimhttp .
docker run -p 8888:8888 nimhttp
```

## Project Structure

```
src/
├── main.nim                 # Application entry point
├── apps/                    # Application modules
│   └── home/               # Home module example
│       ├── main.nim        # Home controller
│       └── services/       # Home services
├── libs/                    # Shared libraries
│   ├── auth/               # Authentication library
│   └── error/              # Error handling library
└── nim_http/                # Core framework
    └── core/               # Core framework components
        ├── app.nim         # Application bootstrap
        ├── controller.nim  # Controller decorator
        ├── di.nim          # Dependency injection
        ├── guard.nim       # Guard base class
        ├── exception.nim   # Exception hierarchy
        ├── route/          # Routing system
        └── controller/     # Controller utilities
```

## Creating a Controller

```nim
import ../../nim_http/core/controller
import asyncdispatch

type UserDto = ref object
  username: string
  email: string

Controller UsersController("api/v1/users"):

  [GET("")]
  proc list() =
    Http200 "List of users"

  [GET(":id")]
  proc getById(id {.param.}: int) =
    Http200 "User with ID: " & $id

  [POST("")]
  proc create(user {.body.}: UserDto) =
    Http201 user

  [PUT(":id")]
  proc update(
    id {.param.}: int,
    user {.body.}: UserDto
  ) =
    Http200 user
```

## Guards & Authentication

```nim
import asynchttpserver
import ../../nim_http/core/[guard, exception, di]

class AuthGuard*() of Guard:

  method canActivate(self: AuthGuard, req: Request): bool =
    if not req.headers.hasKey("Authorization"):
      raise UNAUTHORIZED("Authentication required")
    
    let token = req.headers["Authorization"]
    # Validate token logic here
    return true

# Use in controller
Controller SecureController("api/secure"):
  
  [GET("data")]
  [UseGuard(AuthGuard)]
  proc getData() =
    Http200 "Protected data"
```

## Exception Handling

The framework provides a comprehensive exception hierarchy:

```nim
# Built-in exceptions
raise BAD_REQUEST("Invalid input")
raise UNAUTHORIZED("Not authorized")
raise FORBIDDEN("Access denied")
raise NOT_FOUND("Resource not found")
raise INTERNAL_SERVER_ERROR("Server error")

# Custom error handler
type CustomErrorHandle* = ref object of NimHttpApplicationErrorHandle

method catch*(e: CustomErrorHandle, req: Request): Future[void] {.async.} =
  # Custom error handling logic
  await req.respond(e.exception.statusCode, errorMessage, headers)
```

## Configuration

Create a custom application settings:

```nim
import nim_http/core/app
import libs/error/handle

let settings = NimHttpApplicationSettings()
settings.host = "0.0.0.0"
settings.port = 8888
settings.errorHandle = CustomErrorHandle()

NimHttpApplication(settings: settings).start()
```

## API Examples

### Query Parameters

```nim
[GET("search")]
proc search(
  q {.query.}: string,
  page {.query.}: int = 1,
  limit {.query.}: int = 10
) =
  Http200 "Search results for: " & q
```

### Request Body

```nim
[POST("users")]
proc createUser(user {.body.}: UserDto) =
  # user object is automatically parsed from request body
  Http201 user
```

### URL Parameters

```nim
[GET("users/:id/posts/:postId")]
proc getUserPost(
  id {.param.}: int,
  postId {.param.}: int
) =
  Http200 "User " & $id & " post " & $postId
```

## Performance Tips

1. **Use release mode**: `nim c --define:release --threads:on`
2. **Enable multithreading**: The framework supports concurrent request handling
3. **Connection pooling**: Reuse database connections across requests
4. **Caching**: Implement caching strategies for frequently accessed data

## Development

### Running in Development Mode

```bash
# Compile with debug info
nim c --threads:on src/main.nim

# Run with hot reload (requires additional tools)
nim c -r --threads:on src/main.nim
```

### Testing

```bash
# Run tests
nim c -r tests/test_all.nim
```

## Architecture

The framework follows a layered architecture:

1. **Application Layer**: Controllers handle HTTP requests
2. **Service Layer**: Business logic and data processing
3. **Guard Layer**: Authentication and authorization
4. **Exception Layer**: Error handling and responses
5. **Routing Layer**: Request dispatching and parameter binding

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License

## Credits

Inspired by NestJS and Spring Boot frameworks, built with the power of Nim.
