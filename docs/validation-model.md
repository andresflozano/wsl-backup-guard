# Validation Model

## Health check

**Type:** freshness and evidence-structure check.
**Scope:** encrypted archives matching the configured naming pattern in one directory.
**Expected:** non-empty archive, corresponding checksum file, valid checksum syntax, matching recorded filename, age below threshold.
**Observed:** reported by the command result.
**Interpretation:** a recent candidate with structurally valid checksum evidence exists.
**Limitation:** no archive hash, password, extraction, import, cloud, or application check is implied.

## Hash reconciliation

**Type:** record-to-file checksum comparison.
**Scope:** one explicit archive and checksum record.
**Expected:** calculated SHA-256 equals the recorded value.
**Limitation:** matching hashes do not prove the archive password is known or that WSL import succeeds.

## Restore rehearsal

**Type:** isolated operational recovery test.
**Scope:** one explicit archive restored under a separate distribution name and location.
**Expected:** archive test passes, import succeeds, and predetermined structural checks return expected results.
**Limitation:** sampled checks do not prove every file, credential, project, container, or external dependency works.
