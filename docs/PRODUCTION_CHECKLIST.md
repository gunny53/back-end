# Production Checklist

## Runtime

- [ ] Validate the module graph before boot.
- [ ] Call `resolveAll()` after registering all providers for eager singleton cache warmup.
- [ ] Enable health probes and confirm `/health/live` and `/health/ready` are reachable.
- [ ] Configure host, port, body limits, CORS, and rate limits from environment.
- [ ] Attach middleware to `settings.middleware` before creating `NimHttpApplication`.

## Observability (Phase C)

- [ ] Initialise `getMetrics()` at startup; expose `/metrics` returning `exportPrometheus()`.
- [ ] Use `extractTraceContext(req)` in middleware to obtain a `TraceContext` per request.
- [ ] Propagate `toTraceParent()` to downstream HTTP calls via `injectTraceHeaders`.
- [ ] Set structured log fields from `TraceContext.traceId` and `correlationId`.

## Security

- [ ] Keep security headers enabled.
- [ ] Replace starter credentials and secrets from `.env`.
- [ ] Review authentication guards before exposing protected routes.

## Delivery

- [ ] Run `nimble test`.
- [ ] Run `nimhttp bench` or `nim c -r benchmarks/bench.nim`.
- [ ] Publish migration notes for any breaking surface changes in `docs/MIGRATION_GUIDE.md`.
- [ ] Update `CHANGELOG.md` and compatibility docs before release.
