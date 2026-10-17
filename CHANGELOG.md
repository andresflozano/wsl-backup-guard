# Changelog

All notable user-visible changes to this project will be documented in this file.

The project has not published a versioned release. Entries remain under `Unreleased` until release criteria are met.

## [Unreleased]

### Added

- Public maturity roadmap with explicit gates for checksum reconciliation, restore-rehearsal design, and release readiness.
- Documented a validated operator-guided WSL backup workflow.
- Added daily and current-user sign-in health-check scheduling guidance.
- Documented missed-schedule recovery through Windows Task Scheduler.
- Documented TAR, interactive encryption, SHA-256, off-device-copy, manifest, and retention gates.

### Validation

- Freshness transitioned deterministically from healthy to due at the configured threshold.
- A scheduled health task completed successfully and generated healthy evidence after a new validated backup reset freshness.
- The encrypted archive passed an interactive password test.
- Local and off-device archive byte counts and SHA-256 matched.
- The validation manifest matched between local and off-device copies.

### Limitations

- No isolated restore rehearsal was performed for this snapshot.
- No post-restore project execution was validated.
- Password handling, WSL termination, retention deletion, and cloud mutation remain deliberately manual.

### Changed

- Reusable PowerShell scripts return structured objects instead of applying `Format-List` internally.
- Manifest-validator tests assert object properties directly.

### Security

- Read-only and non-mutation boundaries remain unchanged.
- No password handling, backup deletion, cloud mutation, or restore automation was added.
