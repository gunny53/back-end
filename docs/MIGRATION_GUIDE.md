# Migration Guide

## Import migration

Move application code from `nim_http/core/*` to the Phase A public surface:

- `nim_http/core/app` -> `nim_http/kernel/application`
- `nim_http/core/di` -> `nim_http/kernel/di`
- `nim_http/core/controller` -> `nim_http/http/controller`
- `nim_http/core/request` -> `nim_http/http/request`
- `nim_http/core/response` -> `nim_http/http/response`
- `nim_http/core/route` -> `nim_http/http/routing`
- `nim_http/core/middleware` -> `nim_http/pipeline/middleware`
- `nim_http/core/guard` -> `nim_http/pipeline/guard`
- `nim_http/core/interceptor` -> `nim_http/pipeline/interceptor`
- `nim_http/core/config` -> `nim_http/platform/config`
- `nim_http/core/exception` -> `nim_http/platform/exception`

## Module-system adoption

1. Register feature modules through `ModuleRegistry`.
2. Validate from `ApplicationModule` before bootstrapping runtime services.
3. Export only providers that are explicitly declared by the module.

## Health-probe adoption

- Keep `/health/live` and `/health/ready` unguarded.
- Register readiness checks during bootstrap.
- Freeze readiness checks before the server starts serving requests.

## Tooling adoption

- Use `nimhttp new` for new projects.
- Use `nimhttp generate module <name>` for feature modules.
- Use `nimhttp generate resource <name>` for CRUD-style resource scaffolding.
