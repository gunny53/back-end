# Compatibility Matrix

| NimHTTP version | Nim version | Public surface | Status |
|----------------|-------------|----------------|--------|
| 0.2.x | 2.2.2 | `nim_http/kernel/*`, `http/*`, `pipeline/*`, `platform/*`, `tooling/*` | Active |
| 0.3.x | 2.2.2 | Same as 0.2.x with Phase D CLI (`nimhttp`) | Planned |
| 1.0.x | TBD at GA cut | Frozen public surface after GA RFC | Target |

## Release expectations

- Every release must update this table when the supported Nim version or public surface changes.
- Breaking changes require a matching entry in `docs/MIGRATION_GUIDE.md` and a deprecation note in `docs/API_INVENTORY.md`.
- CLI flag or starter-template breaking changes must be recorded in `CHANGELOG.md`.
