# LTS Policy

## Support tracks

- **Active support**: the latest minor release. Receives new features, fixes, and documentation updates.
- **Maintenance support**: the immediately previous minor release, limited to critical bug fixes and security patches.
- **End of support**: any release older than the maintenance line.

## LTS designation

- A release may be designated LTS at the time it is cut.
- LTS releases receive security and critical stability fixes for 12 months after publication.
- The active LTS line must be listed in `docs/COMPATIBILITY_MATRIX.md`.

## Deprecation and migration

- Deprecated APIs remain available for at least two minor releases unless a security issue requires faster removal.
- Every removal must reference `docs/MIGRATION_GUIDE.md` and the deprecation map in `docs/API_INVENTORY.md`.
- Starter template removals or CLI flag removals follow the same two-minor deprecation window.
