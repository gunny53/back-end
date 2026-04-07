# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2025-12-26

### Added
- **Configuration Management Module** (`src/nim_http/core/config.nim`)
  - Environment variable support
  - `.env` file loading
  - Type-safe getters: `getInt()`, `getBool()`, `getFloat()`
  - Default value fallbacks
  - Global configuration service

- **Middleware Architecture** (`src/nim_http/core/middleware.nim`)
  - Middleware consumer for request/response processing
  - Next function pattern for middleware chaining
  - Built-in middleware:
    - Logger middleware with timestamps
    - CORS middleware with configurable origins
    - Rate limiting middleware (100 req/min default)
    - Security headers middleware (XSS, clickjacking protection)
    - Body parser middleware with size limits
    - Compression middleware (placeholder)

- **Enhanced Interceptor System** (`src/nim_http/core/interceptor.nim`)
  - Execution context with request metadata
  - Call handler chain pattern
  - Built-in interceptors:
    - Logging interceptor with performance timing
    - Cache interceptor with TTL support
    - Transform interceptor for response modification
    - Timeout interceptor (408 on timeout)
    - Error mapping interceptor
  - Global interceptor registry

- **Helper Utilities Module** (`src/nim_http/core/helpers.nim`)
  - String utilities: slugify, truncate, case conversion (camelCase, PascalCase, snake_case)
  - Hash & crypto: MD5, Base64 encoding/decoding
  - JSON utilities: safe parsing, type-safe getters
  - Time utilities: Unix timestamps, ISO8601 formatting
  - Collection utilities: distinct, groupBy, chunk
  - Validation: isEmail, isURL, isNumeric, isAlphanumeric
  - Random: randomString, randomInt, generateUUID
  - Performance: benchmark template, measureTime

- **Documentation**
  - Comprehensive README.md with quick start guide
  - EXAMPLES.md with real-world usage patterns
  - .env.example with configuration options
  - Inline code documentation

### Changed
- **Enhanced Dependency Injection** (`src/nim_http/core/di.nim`)
  - Added provider scopes (Singleton, Transient, Request)
  - Implemented circular dependency detection
  - Factory function support for lazy initialization
  - Maintained backward compatibility

- **Application Lifecycle** (`src/nim_http/core/app.nim`)
  - Integrated middleware pipeline
  - Enhanced error handling with try-catch blocks
  - Server instance stored for lifecycle management
  - Added `stop()` method for graceful shutdown
  - Configuration-based logging

- **Main Application** (`src/main.nim`)
  - Application reference stored for lifecycle management
  - Signal handlers for graceful shutdown (SIGINT, SIGTERM)
  - Configuration-driven setup
  - Middleware and interceptor registration

- **.gitignore**
  - Added environment files (.env, .env.local)
  - Added build artifacts (nim_http, main)
  - Added common IDE and OS files
  - Added log and coverage directories

### Fixed
- Interceptor legacy method now returns proper Future instead of discard
- Added detailed comments explaining interceptor chain ordering
- Application server instance properly managed for reuse
- Error responses now properly formatted as JSON

### Security
- Added security headers middleware (X-Content-Type-Options, X-Frame-Options, etc.)
- Rate limiting to prevent API abuse
- CORS protection with configurable origins
- Request body size limits
- Passed CodeQL security scan with no vulnerabilities

## [0.1.0] - Previous Version

### Initial Implementation
- Basic controller decorator syntax
- Route pattern matching
- Guard-based authentication
- Exception hierarchy
- Dependency injection basics
- Request/response handling

---

## Migration Guide

### From 0.1.0 to Current

#### Configuration
**Before:**
```nim
let settings = NimHttpApplicationSettings()
settings.host = "127.0.0.1"
settings.port = 8888
```

**After:**
```nim
import nim_http/core/config

let config = getConfig()
let settings = NimHttpApplicationSettings()
settings.host = config.get("SERVER_HOST", "127.0.0.1")
settings.port = config.getInt("SERVER_PORT", 8888)
```

#### Middleware
**New Feature:**
```nim
import nim_http/core/middleware

let middleware = getMiddlewareConsumer()
middleware.apply(loggerMiddleware)
middleware.apply(corsMiddleware("*", "GET,POST,PUT,DELETE"))
```

#### Lifecycle Management
**Before:**
```nim
NimHttpApplication(settings: settings).start()
```

**After:**
```nim
let app = NimHttpApplication(settings: settings)

when defined(posix):
  proc handleShutdown() {.noconv.} =
    app.stop()
    quit(0)
  setControlCHook(handleShutdown)

app.start()
```

## Performance Improvements

- **Middleware Pipeline**: Request processing through efficient middleware chain
- **Rate Limiting**: Prevents server overload with configurable limits
- **Caching**: Interceptor-based caching with TTL support
- **Error Handling**: Efficient exception catching without performance overhead

## Breaking Changes

None - all changes are backward compatible with the previous version.

## Known Issues

- Compression middleware is a placeholder and needs implementation
- Request-scoped providers not yet fully implemented
- Advanced caching strategies need integration with route processing

## Contributors

- Hoang Tat Hieu (@hieuht-htv)
- GitHub Copilot

---

For more details, see:
- [README.md](README.md) for project overview
- [EXAMPLES.md](EXAMPLES.md) for usage examples
- [.env.example](.env.example) for configuration options
