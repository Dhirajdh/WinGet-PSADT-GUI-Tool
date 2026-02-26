# Versioning Strategy

This project uses Semantic Versioning: `MAJOR.MINOR.PATCH`.

## Rules
- `MAJOR`: breaking behavior change, contract break, or significant compatibility shift.
- `MINOR`: new backward-compatible features.
- `PATCH`: backward-compatible bug fixes.

## Tagging
Use git tags like:
- `v1.0.0`
- `v1.1.0`
- `v1.1.1`

## Release Checklist
1. Update `CHANGELOG.md`.
2. Validate GUI smoke flows.
3. Validate package generation/upload non-regression.
4. Tag release and publish notes.
