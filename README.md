# WSL Backup Guard

A safety-oriented PowerShell toolkit for evaluating encrypted WSL backup evidence without creating, deleting, decrypting, or restoring backups during routine health checks.

## Why this project exists

Backup status is often reduced to "a file exists." WSL Backup Guard uses a narrower and more auditable claim: a recent encrypted archive exists, a corresponding checksum record is structurally valid, and the check performed no backup mutation.

## Current scope

The first public slice provides:

- read-only discovery of encrypted `.7z` WSL backup archives;
- checksum-record format and filename validation;
- age-based freshness evaluation;
- machine-readable result objects and deterministic exit codes;
- a separate evidence validator for synthetic manifest files;
- Pester tests for healthy, due, malformed, and missing-evidence cases.

It does **not**:

- export a WSL distribution;
- accept or store an encryption password;
- recompute multi-gigabyte hashes during daily checks;
- copy files to a cloud provider;
- remove retention candidates;
- claim that a restore or project execution succeeded.

## Repository layout

```text
scripts/              PowerShell commands
examples/             Synthetic evidence only
tests/                Pester tests
docs/                 Architecture, validation model, and threat model
.github/workflows/     CI syntax and test gate
```

## Quick start

```powershell
./scripts/Test-WslBackupHealth.ps1 `
  -BackupDirectory C:\Backups\WSL `
  -DistroName Ubuntu `
  -DueAfterDays 7
```

Exit codes:

- `0`: a recent candidate and valid checksum record were found;
- `2`: evidence is missing, malformed, or older than the threshold;
- `1`: the check failed to execute safely.

## Validation language

A healthy result proves only the checks reported in the output. It does not prove archive readability, password availability, cloud synchronization, full restore capability, or application correctness. See [`docs/validation-model.md`](docs/validation-model.md).

## Security

Never commit real backup archives, checksums, manifests containing personal paths, credentials, private keys, customer data, or machine inventories. See [`SECURITY.md`](SECURITY.md) and [`docs/threat-model.md`](docs/threat-model.md).

## Status

Initial public scaffold. No release or production-readiness claim is made.

## License

MIT. See [`LICENSE`](LICENSE).

## Validated operating workflow

The read-only health evaluator is now part of a validated personal WSL backup workflow.

The operating model combines:

- encrypted-backup discovery;
- checksum-record validation;
- a configurable freshness threshold;
- deterministic exit codes;
- daily and current-user sign-in health checks;
- deliberate WSL shutdown before export;
- interactive AES archive encryption;
- encrypted archive testing;
- SHA-256 reconciliation;
- off-device byte and hash comparison;
- cloud-presence confirmation;
- manifest-based validation;
- retention only after all required gates pass.

The scheduled task runs the read-only health wrapper only. It does not stop WSL, create backups, handle passwords, copy archives, or delete retention candidates.

See docs/validated-personal-workflow.md.

This validation does not prove isolated restoration or post-restore project correctness.
