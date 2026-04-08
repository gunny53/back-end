# NimHTTP API Inventory & Deprecation Map

> **Phase A deliverable.** This document is the authoritative record of every public symbol exported
> by NimHTTP, its stability tier, and any deprecation timeline. It is updated at the start of every
> new phase and reviewed before any PR that touches a public API surface.

---

## Stability tiers

| Tier | Meaning |
|------|---------|
| **stable** | Frozen. Breaking changes require an RFC, a deprecation notice in the preceding minor release, and a `MIGRATION_GUIDE.md` entry. |
| **experimental** | API may change between minor versions without prior notice. Not recommended for production consumers. |
| **deprecated** | Scheduled for removal. Replacement symbol is listed. Removal happens after the deprecation window (≥ 2 minor versions). |

---

## `nim_http/kernel/application` (re-exports `core/app`)

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `NimHttpApplicationSettings` | type | stable | Root configuration object |
| `NimHttpApplicationSettings.host` | field | stable | |
| `NimHttpApplicationSettings.port` | field | stable | |
| `NimHttpApplicationSettings.errorHandle` | field | stable | |
| `NimHttpApplicationSettings.middleware` | field | stable | |
| `NimHttpApplicationErrorHandle` | type | stable | |
| `NimHttpApplicationErrorHandle.catch` | method | stable | |
| `NimHttpApplication` | type | stable | |
| `NimHttpApplication.settings` | field | stable | |
| `NimHttpApplication.server` | field | experimental | Exposed for lifecycle management; may move behind an interface |
| `NimHttpApplication.start` | proc | stable | Blocks until server stops |
| `NimHttpApplication.stop` | proc | stable | Graceful shutdown |

---

## `nim_http/kernel/di` (re-exports `core/di`)

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `SingletonObj` | type | stable | Base type for all injectable services |
| `ProviderScope` | enum | stable | `Singleton \| Transient \| Request` |
| `ProviderMetadata` | type | experimental | Internal container metadata; subject to change in Phase B DI refactor |
| `DependencyContainer` | type | experimental | Internal container; use `inject`/`register` instead |
| `singletonRegistry` | var | deprecated | Use `register`/`inject`. Scheduled for removal in v0.4. |
| `dependencyContainer` | var | experimental | Internal; do not reference directly |
| `register[T]` | proc | stable | Register a provider with scope + factory |
| `inject[T]` | proc | stable | Resolve a provider by type |
| `class` (body variant) | macro | stable | Declare and auto-register a service class |
| `class` (no-body variant) | macro | stable | Declare a service class without methods |
| `singleton` | pragma | stable | Marks a type as singleton-scoped |

---

## `nim_http/kernel/module`

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `ProviderToken` | type | stable | |
| `ControllerToken` | type | stable | |
| `ModuleDescriptor` | type | stable | Ref object; treat as immutable after registration |
| `ModuleDescriptor.name` | field | stable | |
| `ModuleDescriptor.imports` | field | stable | Mutable only during graph assembly, before registration |
| `ModuleDescriptor.providers` | field | stable | |
| `ModuleDescriptor.exports` | field | stable | |
| `ModuleDescriptor.controllers` | field | stable | |
| `ModuleRegistry` | type | stable | |
| `newModuleDescriptor` | proc | stable | |
| `newModuleRegistry` | proc | stable | |
| `registerModule` | proc | stable | Validates and adds a descriptor to a registry |
| `validateGraph` (descriptor set) | proc | stable | Validates exact descriptor set |
| `validateGraph` (registry + roots) | proc | stable | Validates reachable subgraph from root modules |
| `validate` (single descriptor) | proc | stable | |
| `toProviderToken` | converter | stable | Allows `typedesc[T]` as provider token |
| `toControllerToken` | converter | stable | Allows `typedesc[T]` as controller token |

---

## `nim_http/http/controller` (re-exports `core/controller`)

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `BaseController` | type | stable | |
| `BaseController.request` | field | stable | |
| `BaseController.params` | field | stable | |
| `BaseController.guards` | field | stable | |
| `processRequest` | func | stable | |
| `invoke` | proc | stable | |
| `addGuard[T]` | func | stable | |
| `getGuards` | func | stable | |
| `Http200` | template | stable | |
| `Http201` | template | stable | |
| `Http204` | template | stable | |
| `Http400` | template | stable | |
| `Http403` | template | stable | |
| `Http404` | template | stable | |
| `controllerRegistry` | let | stable | Global registry; populated by `class` macro |
| `ControllerDelegate` | type | stable | |
| `ControllerDelegate.instance` | field | stable | |
| `ControllerDelegate.handler` | field | stable | |
| `ControllerDelegate.guards` | field | stable | |
| `collect[T]` | macro | stable | Build a `ControllerDelegate` from controller type + handler |

---

## `nim_http/http/request` (re-exports `core/request`)

Delegates entirely to `asynchttpserver.Request`. No NimHTTP-specific symbols at this layer.

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `Request` | re-export | stable | Standard library `asynchttpserver.Request` |

---

## `nim_http/http/response` (re-exports `core/response`)

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `Response` | type | stable | |
| `detectContentType` | proc | experimental | Heuristic; behavior may be refined |
| `send` | proc | stable | Primary response emission API |

---

## `nim_http/http/routing` (re-exports `core/route`)

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `RoutePattern` | type | stable | |
| `RoutePattern.raw` | field | stable | |
| `RoutePattern.paramSegments` | field | stable | |
| `parseRoutePattern` | func | stable | |
| `RouteRegister` | type | stable | |
| `RouteRegister.path` | field | stable | |
| `RouteRegister.delegate` | field | stable | |
| `reg` | proc | stable | Register a route against an HTTP method |
| `RouteDetail` | type | stable | |
| `RouteNode` | type | experimental | Internal trie node; not part of public contract |
| `routeRoot` | var | experimental | Internal thread-local trie root; do not access directly |
| `addRoute` | proc | stable | Low-level route registration |
| `process` | proc | stable | Core request dispatch — called by the application loop |

---

## `nim_http/pipeline/middleware` (re-exports `core/middleware`)

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `NextFunction` | type | stable | |
| `MiddlewareFunction` | type | stable | |
| `PipelinePlan` | type | stable | |
| `MiddlewareConsumer` | type | stable | |
| `newMiddlewareConsumer` | proc | stable | |
| `apply` (global) | proc | stable | Apply middleware to all routes |
| `apply` (route-scoped) | proc | stable | Apply middleware to specific path prefixes |
| `compilePipelinePlans` | proc | stable | Must be called once at startup |
| `resolvePlan` | proc | stable | Returns compiled middleware chain for a path; benchmark entry point |
| `execute` | proc | stable | |
| `loggerMiddleware` | proc | stable | Built-in; logs method, path, duration |
| `corsMiddleware` | proc | stable | Factory; returns `MiddlewareFunction` |
| `rateLimitMiddleware` | proc | stable | Factory; in-memory per-IP counter |
| `bodyParserMiddleware` | proc | stable | Factory; enforces `maxBodySize` |
| `securityHeadersMiddleware` | proc | stable | Factory; sets OWASP headers |
| `globalMiddlewareConsumer` | var | experimental | Thread-local global consumer |
| `initGlobalMiddleware` | proc | experimental | |
| `getMiddlewareConsumer` | proc | stable | Returns global `MiddlewareConsumer`, init if nil |

---

## `nim_http/pipeline/guard` (re-exports `core/guard`)

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `Guard` | type | stable | |
| `canActivate` | method | stable | Override to implement authorization |

---

## `nim_http/pipeline/interceptor` (re-exports `core/interceptor`)

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `ExecutionContext` | type | stable | |
| `ExecutionContext.request` | field | stable | |
| `ExecutionContext.handler` | field | stable | |
| `ExecutionContext.startTime` | field | stable | |
| `ExecutionContext.metadata` | field | experimental | Type may change from `JsonNode` to a typed map |
| `CallHandler` | type | stable | |
| `Interceptor` | type | stable | |
| `Interceptor.intercept` | method | stable | |
| `LoggingInterceptor` | type | stable | |
| `applyInterceptors` | proc | stable | |
| `registerInterceptor` | proc | stable | |

---

## `nim_http/platform/config` (re-exports `core/config`)

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `ConfigurationError` | type | stable | |
| `ConfigService` | type | stable | |
| `newConfigService` | proc | stable | |
| `loadFromEnv` | proc | stable | |
| `loadFromFile` | proc | stable | |
| `get` (required) | proc | stable | Raises `ConfigurationError` if key absent |
| `get` (with default) | proc | stable | |
| `getInt` | proc | stable | |
| `getBool` | proc | stable | |
| `getFloat` | proc | stable | |
| `set` | proc | stable | |
| `has` | proc | stable | |
| `initGlobalConfig` | proc | stable | |
| `getConfig` | proc | stable | Returns global singleton |

---

## `nim_http/platform/exception` (re-exports `core/exception`)

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `HttpException` | type | stable | |
| `HttpException.statusCode` | field | stable | |
| `HttpException.message` | field | stable | |
| `HttpException.catch` | method | stable | |
| `BadRequestException` et al. | types | stable | One type per standard HTTP error code |
| `UNAUTHORIZED`, `BAD_REQUEST`, `CONFLICT`, `FORBIDDEN`, `GATEWAY_TIMEOUT`, `GONE`, `HTTP_VERSION_NOT_SUPPORTED`, `IM_A_TEAPOT`, `INTERNAL_SERVER_ERROR`, `METHOD_NOT_ALLOWED`, `MISDIRECTED`, `NOT_ACCEPTABLE`, `NOT_FOUND`, `NOT_IMPLEMENTED`, `PRECONDITION_FAILED`, `REQUEST_TIMEOUT`, `SERVICE_UNAVAILABLE`, `UNPROCESSABLE_ENTITY`, `UNSUPPORTED_MEDIA_TYPE` | funcs | stable | Constructor functions for each HTTP error |

---

## `nim_http/platform/health`

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `HealthCheckStatus` | type | stable | |
| `HealthCheckStatus.name` | field | stable | |
| `HealthCheckStatus.status` | field | stable | |
| `HealthProbe` | type | stable | |
| `HealthProbe.status` | field | stable | |
| `HealthProbe.probe` | field | stable | |
| `HealthProbe.service` | field | stable | |
| `HealthProbe.timestamp` | field | stable | |
| `HealthProbe.checks` | field | stable | |
| `registerReadinessCheck` | proc | stable | Must be called before `freezeReadinessChecks` |
| `freezeReadinessChecks` | proc | stable | Call once after bootstrap, before `app.start()` |
| `clearReadinessChecks` | proc | stable | Test helper; resets global state |
| `livenessProbe` | proc | stable | |
| `readinessProbe` | proc | stable | |

---

## `nim_http/tooling/scaffold`

| Symbol | Kind | Tier | Notes |
|--------|------|------|-------|
| `usageText` | const | experimental | |
| `toCamelCase` | proc | experimental | |
| `createStarterProject` | proc | experimental | |
| `generateResource` | proc | experimental | |
| `runCli` | proc | experimental | Entry point for the `nimhttp` binary |

---

## Deprecation Map

| Symbol | Deprecated since | Replacement | Planned removal |
|--------|-----------------|-------------|-----------------|
| `singletonRegistry` | v0.2 | `register[T]` + `inject[T]` | v0.4 |

No other symbols are currently deprecated. Additions to this table require an RFC approved before
the deprecation PR is merged.

---

## Change process

1. Open a GitHub issue tagged `api-change`.
2. Fill in `docs/RFC_TEMPLATE.md`.
3. Require approval from ≥ 1 maintainer before any public symbol addition, rename, or removal.
4. Add a row to the **Deprecation Map** if removing a previously stable symbol.
5. Update `docs/MIGRATION_GUIDE.md` for any breaking or behavioral change.
