# Compatibility Policy

## Public API surface

The supported public import surface is the Phase A layout:

- `nim_http/kernel/*`
- `nim_http/http/*`
- `nim_http/pipeline/*`
- `nim_http/platform/*`

The older `nim_http/core/*` modules remain compatibility shims during the migration window but should not be used for new code.

## Deprecation window

- New features land on the public Phase A surface first.
- Deprecated APIs remain available for at least one minor release after a replacement is documented.
- Removals require a matching migration note in `docs/MIGRATION_GUIDE.md`.

## Compatibility promises

- Module names and exported runtime contracts on the public surface are the compatibility boundary.
- Health probe endpoints and module-graph validation behavior are considered production-facing features.
- Generated starter projects may evolve, but breaking CLI flag changes must be documented in the changelog.
- Supported runtime / surface combinations are tracked in `docs/COMPATIBILITY_MATRIX.md`.
- Long-term support expectations are defined in `docs/LTS_POLICY.md`.

## Migration expectations

- Prefer import rewrites over behavioral rewrites when moving from `core/*` to the façade modules.
- Keep backward-compatible shims until migration docs exist for the affected feature.
