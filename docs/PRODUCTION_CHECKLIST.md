# Production Checklist

## Runtime

- [ ] Validate the module graph before boot.
- [ ] Enable health probes and confirm `/health/live` and `/health/ready` are reachable.
- [ ] Configure host, port, body limits, CORS, and rate limits from environment.
- [ ] Attach middleware to `settings.middleware` before creating `NimHttpApplication`.

## Security

- [ ] Keep security headers enabled.
- [ ] Replace starter credentials and secrets from `.env`.
- [ ] Review authentication guards before exposing protected routes.

## Delivery

- [ ] Run `nimble test`.
- [ ] Run `nimhttp bench` or `nim c -r benchmarks/bench.nim`.
- [ ] Publish migration notes for any breaking surface changes.
- [ ] Update `CHANGELOG.md` and compatibility docs before release.
