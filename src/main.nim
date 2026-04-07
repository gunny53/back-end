import nim_http/kernel/application
import nim_http/platform/config
import nim_http/pipeline/middleware
import nim_http/pipeline/interceptor
import libs/error/handle
import apps/home/main

# Initialize configuration
let config = getConfig()

# Configure application settings
let settings = NimHttpApplicationSettings()
settings.host = config.get("SERVER_HOST", "127.0.0.1")
settings.port = config.getInt("SERVER_PORT", 8888)
settings.errorHandle = HttpErrorHandle()

# Setup middleware
let middlewareConsumer = getMiddlewareConsumer()

# Apply global middleware
middlewareConsumer.apply(loggerMiddleware)
middlewareConsumer.apply(securityHeadersMiddleware())

# CORS middleware
if config.getBool("CORS_ENABLED", true):
  let corsOrigin = config.get("CORS_ORIGIN", "*")
  let corsMethods = config.get("CORS_METHODS", "GET, POST, PUT, DELETE, OPTIONS, PATCH")
  let corsHeaders = config.get("CORS_HEADERS", "Content-Type, Authorization")
  middlewareConsumer.apply(corsMiddleware(corsOrigin, corsMethods, corsHeaders))

# Rate limiting middleware
if config.getBool("RATE_LIMIT_ENABLED", true):
  let maxRequests = config.getInt("RATE_LIMIT_MAX", 100)
  let windowMs = config.getInt("RATE_LIMIT_WINDOW_MS", 60000)
  middlewareConsumer.apply(rateLimitMiddleware(maxRequests, windowMs))

# Body parser middleware
let maxBodySize = config.getInt("MAX_BODY_SIZE", 10_000_000)
middlewareConsumer.apply(bodyParserMiddleware(maxBodySize))

# Attach configured middleware to application settings
settings.middleware = middlewareConsumer

# Setup interceptors
if config.getBool("LOGGING_ENABLED", true):
  let loggingInterceptor = LoggingInterceptor(verbose: true)
  registerInterceptor(loggingInterceptor)

# Cache interceptor
if config.getBool("CACHE_ENABLED", false):
  let cacheTtl = config.getInt("CACHE_TTL", 60)
  let cacheInterceptor = newCacheInterceptor(cacheTtl)
  registerInterceptor(cacheInterceptor)

# Start application
echo "Starting ", config.get("APP_NAME", "NimHTTP Framework")
echo "Environment: ", config.get("APP_ENV", "production")

# Create application instance with proper lifecycle management
let app = NimHttpApplication(settings: settings)

# Register signal handlers for graceful shutdown (Unix-like systems)
when defined(posix):
  import posix
  
  proc handleShutdown() {.noconv.} =
    echo "\nReceived shutdown signal, stopping server..."
    app.stop()
    quit(0)
  
  setControlCHook(handleShutdown)

# Start the application
app.start()
