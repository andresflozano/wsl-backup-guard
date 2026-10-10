# Architecture

## Components

### Health evaluator

`scripts/Test-WslBackupHealth.ps1` discovers encrypted backup candidates and evaluates lightweight evidence. It is intended for frequent execution.

### Evidence validator

`scripts/Test-WslBackupManifest.ps1` validates a synthetic or sanitized JSON manifest against the referenced archive metadata and checksum record. Hash recomputation is opt-in because large archives can make routine checks expensive.

### Restore rehearsal

Restore testing is deliberately outside the automated health path. It is a separate, state-changing procedure that should use an isolated distribution name and install location.

## Design rules

- Read-only checks must not silently become backup creation or retention actions.
- Missing evidence produces a non-healthy result, not an inferred success.
- Previous validated backups must not be deleted merely because a newer candidate exists.
- Passwords must not be accepted as plain command-line parameters.
- Every output field should correspond to an observed check.
