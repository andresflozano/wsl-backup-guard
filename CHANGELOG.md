# Changelog

All notable user-visible changes to this project will be documented in this file.

The project has not published a versioned release. Entries remain under `Unreleased` until release criteria are met.

## [Unreleased]

### Added

- Public maturity roadmap with explicit gates for checksum reconciliation, restore-rehearsal design, and release readiness.

### Changed

- Reusable PowerShell scripts return structured objects instead of applying `Format-List` internally.
- Manifest-validator tests assert object properties directly.

### Security

- Read-only and non-mutation boundaries remain unchanged.
- No password handling, backup deletion, cloud mutation, or restore automation was added.
