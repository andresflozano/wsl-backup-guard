# WSL Backup Guard: Validated Personal Backup Workflow

## Status

Validated as a personal operational workflow with a deliberately limited automation boundary.

The public repository provides read-only backup health evaluation and evidence validation. Backup creation, password handling, encryption, cloud-copy verification, retention, and restore rehearsal remain guided operator activities.

## Problem

A backup should not be considered healthy merely because a file exists.

The workflow needs to distinguish:

- a recent encrypted backup candidate;
- a structurally valid checksum record;
- a backup that is due under a configured freshness rule;
- archive integrity and password validation;
- off-device copy equivalence;
- web-visible synchronization;
- restore rehearsal;
- application validation after restoration.

Each check supports a narrow claim. No single check proves complete recoverability.

## Validated operating model

```text
Daily and sign-in health check
→ evaluate newest encrypted candidate and checksum metadata
→ Healthy: record evidence and stop
→ Due: notify the operator
→ operator saves work and stops workloads
→ operator stops the WSL distribution
→ create TAR export and export evidence
→ encrypt with AES from the command line, entering the password at an interactive prompt
→ test encrypted archive interactively
→ create and reconcile SHA-256
→ copy encrypted archive and checksum off-device
→ compare byte count and SHA-256
→ confirm cloud web presence
→ verify the cloud copy by releasing local content and hashing the rehydrated file
→ create and hash a validation manifest
→ apply retention only after every required gate passes
```

## Automation boundary

### Automated

- encrypted backup discovery;
- checksum-record presence and structural validation;
- age-based freshness evaluation;
- deterministic exit codes;
- human-readable and JSON health evidence;
- daily Task Scheduler trigger;
- user sign-in trigger;
- missed-schedule recovery through `StartWhenAvailable`;
- overlapping-run prevention.

### Deliberately manual

- saving open work;
- stopping application and container workloads;
- terminating the WSL distribution;
- starting the export;
- entering the archive password;
- encrypted archive testing;
- off-device copy review;
- cloud web-presence confirmation;
- cloud-copy rehydration verification;
- retention deletion;
- restore rehearsal.

The manual boundary prevents routine health automation from silently becoming a destructive or credential-handling workflow.

## Command-line encryption and cloud verification

Encryption, archive testing, and cloud verification run from Windows PowerShell. No GUI step is required, and the password is never placed in a command, script, log, or task configuration.

### Encrypt and test

`7z.exe` with `-p` and no value prompts for the password without echoing it. `-mhe=on` encrypts archive headers, so file names are hidden.

```powershell
& {
    $ErrorActionPreference = "Stop"

    $SevenZip = "C:\Program Files\7-Zip\7z.exe"
    $BackupRoot = Join-Path $env:USERPROFILE "WSL-Backups"
    $Stem = "SNAPSHOT_STEM"
    $ExpectedTarHash = "TAR_SHA256_FROM_EXPORT"

    $Tar = Join-Path $BackupRoot "$Stem.tar"
    $Archive = Join-Path $BackupRoot "$Stem.7z"

    if (Test-Path -LiteralPath $Archive) { throw "Archive already exists: $Archive" }

    $TarHash = (Get-FileHash -LiteralPath $Tar -Algorithm SHA256).Hash
    if ($TarHash -ne $ExpectedTarHash) { throw "TAR hash differs from the export result. Stop." }

    & $SevenZip a -t7z -mx=3 -mhe=on -p $Archive $Tar
    if ($LASTEXITCODE -ne 0) { throw "Archive creation failed. Stop." }

    & $SevenZip t $Archive
    if ($LASTEXITCODE -ne 0) { throw "Archive test failed. Stop." }
}
```

Replace `SNAPSHOT_STEM` and `TAR_SHA256_FROM_EXPORT` with values from the export output before running.

### Verify the cloud copy

After the synchronized copy finishes uploading, release its local content and hash it. Reading a released file forces the OneDrive client to download it from the cloud, so a matching hash shows the cloud holds a matching copy.

Preconditions:

- the original archive still exists outside the synchronized folder;
- the OneDrive client reports the folder as up to date.

```powershell
& {
    $ErrorActionPreference = "Stop"

    $Stem = "SNAPSHOT_STEM"
    $ExpectedHash = "ARCHIVE_SHA256"
    $ExpectedBytes = 0   # replace with the archive size in bytes
    $Cloud = Join-Path $env:OneDriveConsumer "Backups\WSL\$Stem.7z"

    if ($ExpectedBytes -le 0) { throw "Set ExpectedBytes before running." }

    attrib.exe +U -P "$Cloud"

    $RecallFlag = 0x400000
    $Released = $false
    for ($i = 0; $i -lt 30; $i++) {
        $Item = Get-Item -LiteralPath $Cloud
        if (([int]$Item.Attributes) -band $RecallFlag) {
            $Released = $true
            break
        }
        Start-Sleep -Seconds 2
    }
    if (-not $Released) { throw "Local content was not released. Nothing verified." }

    $Hash = (Get-FileHash -LiteralPath $Cloud -Algorithm SHA256).Hash
    $Bytes = (Get-Item -LiteralPath $Cloud).Length

    [pscustomobject]@{
        CloudUploadVerified = ($Bytes -eq $ExpectedBytes -and $Hash -eq $ExpectedHash)
    } | Format-List
}
```

### Observed behavior

In one validated run on an unstable connection, three browser downloads of a multi-gigabyte archive stopped early and were saved under the expected file name. Size and hash comparison rejected all three. Rehydration through the OneDrive client then succeeded on the first attempt. This is a single observation, not a general comparison of download methods.

### Operator notes

- Run PowerShell blocks only at a `PS C:\...>` prompt. Pasting them into a Linux shell fails and runs nothing.
- Long terminal pastes can be corrupted. Prefer running saved scripts, and re-verify state instead of re-running a partially executed block.

## Health states

### Healthy

A recent encrypted candidate and acceptable checksum record were found within the configured freshness threshold.

This does not prove:

- encrypted archive readability;
- password availability;
- cloud synchronization;
- restoration;
- project execution after restoration.

### Due

The candidate is missing, malformed, or older than the configured threshold.

A due result authorizes a deliberate backup window. It does not authorize automatic WSL termination, deletion, or retention.

### Error

The check could not execute safely. Diagnose before creating or deleting backup artifacts.

## Exit-code contract

```text
0 = healthy under the configured evidence and freshness checks
2 = backup window due
1 = health evaluation failed to execute safely
```

## Scheduled health check

The validated personal configuration uses one Windows Task Scheduler task with:

- one daily trigger;
- one current-user sign-in trigger;
- `StartWhenAvailable` enabled;
- battery operation allowed;
- `IgnoreNew` for overlapping instances;
- a bounded execution time;
- interactive execution for visible due notifications;
- a read-only wrapper action only.

The scheduled task does not invoke backup mode.

## Backup evidence model

A completed encrypted snapshot records:

- export timestamp;
- distro name;
- TAR filename, bytes, and SHA-256;
- TAR-listing result;
- export exit code;
- encrypted archive filename, bytes, and SHA-256;
- encryption method;
- encrypted archive test result and exit code;
- checksum-record validation;
- off-device destination class;
- source-versus-destination byte comparison;
- source-versus-destination SHA-256 comparison;
- cloud web-presence observation;
- cloud rehydration verification result, bytes, and SHA-256;
- manifest SHA-256;
- restore-test status;
- project-validation status;
- explicit limitations.

## Retention gate

The unencrypted TAR may be removed only after all required controls pass:

- TAR listing passed;
- encrypted archive test passed;
- encrypted checksum matched;
- off-device archive bytes matched;
- off-device archive SHA-256 matched;
- checksum-file copy matched;
- cloud web presence was confirmed;
- the rehydrated cloud copy matched bytes and SHA-256;
- final validation manifest exists and is hash-matched.

The previous validated encrypted backup remains until a separate multi-version retention policy is approved.

## Validation performed

The end-to-end personal workflow was exercised through:

- freshness transition from healthy to due;
- deliberate WSL shutdown;
- full distro TAR export;
- TAR listing and SHA-256 generation;
- command-line AES-encrypted 7z creation with an interactive password prompt;
- password-based archive test;
- encrypted archive SHA-256 reconciliation;
- off-device file copy;
- source and destination byte-count comparison;
- source and destination SHA-256 comparison;
- web-presence confirmation;
- cloud-copy rehydration and SHA-256 verification;
- validation-manifest creation;
- manifest hash comparison;
- retention-gated TAR deletion;
- WSL restart;
- scheduled-task registration and manual execution;
- healthy-state evidence generation after the new backup reset freshness.

## Validation limitations

- No isolated restore rehearsal was performed for this snapshot.
- Project execution was not validated from a restored distro.
- External Windows targets referenced by WSL symbolic links are outside distro-export coverage.
- Cloud web visibility confirms presence only. Rehydration verification depends on the OneDrive client and on the original archive remaining available locally.
- Password recovery was not tested independently.
- Fully unattended encryption and retention are intentionally excluded.

## Public repository boundary

Safe public content:

- generic health-check scripts;
- deterministic exit-code contracts;
- synthetic evidence and fixtures;
- architecture and threat models;
- validation-language guidance;
- Pester tests;
- Task Scheduler setup examples using placeholders;
- sample manifests with fictional names and hashes.

Never publish:

- real backup archives;
- real archive or manifest hashes tied to a personal machine;
- personal OneDrive paths;
- usernames or machine names;
- passwords or password hints;
- real manifests containing personal paths;
- private project inventory;
- customer or employer data;
- credentials, keys, cloud configuration, or recovery codes.

## Recommended public roadmap

### Current public slice

- read-only encrypted candidate discovery;
- checksum-record validation;
- freshness evaluation;
- deterministic outputs and exit codes;
- synthetic manifest validation;
- tests for healthy, due, malformed, and missing evidence.

### Next safe public slice

- generic Scheduled Task registration helper;
- unregister/repair helper;
- synthetic task-export fixture;
- operator runbook for due-state response;
- validation-manifest JSON Schema;
- manifest validator with synthetic cases;
- documented restore-rehearsal contract without automatic destructive actions.

### Deferred

- automatic WSL termination;
- password automation;
- automatic retention deletion;
- cloud mutation;
- automatic restore;
- project-level recovery claims.

## Claim boundary

The validated workflow supports this claim:

> A safety-oriented process can detect when a WSL encrypted backup is due, guide a deliberate export and encryption workflow, reconcile local and off-device evidence, and prevent retention until the required validation gates pass.

It does not support this stronger claim:

> The backup is fully recoverable and all applications will run correctly after restoration.

That stronger claim requires an isolated restore rehearsal and post-restore project validation.
