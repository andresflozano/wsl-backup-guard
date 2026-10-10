# Roadmap

This roadmap records maturity gates, not delivery promises. Each stage begins only after the prior stage is validated on protected `main`.

## Current maturity

- Public repository with protected `main`
- Read-only health and manifest evidence checks
- Synthetic fixtures only
- Local, pull-request, and post-merge Pester validation
- No backup creation, password handling, retention deletion, cloud mutation, or restore automation

## Stage 1: Structured output contract

**Goal:** Return stable PowerShell objects from reusable scripts and leave formatting to callers.

**Exit criteria:**

- No `Format-List` inside reusable scripts
- Existing result properties remain available
- Tests assert object properties rather than formatted text
- Exit-code behavior is preserved where applicable
- Local, pull-request, and post-merge CI pass

## Stage 2: Checksum-record reconciliation

**Entry gate:** Stage 1 is merged and stable.

**Goal:** Reconcile an explicit archive, checksum record, and manifest hash without mutating source evidence.

**Exit criteria:**

- Checksum-file presence and syntax are validated
- Recorded filename is compared with the selected archive
- Hash calculation remains opt-in
- Manifest, checksum-record, and calculated hashes can be compared explicitly
- Malformed, mismatched, and missing-evidence cases have synthetic tests
- Limitations state that matching hashes do not prove password availability or recoverability

## Stage 3: Restore-rehearsal design

**Entry gate:** Read-only evidence contracts are stable.

**Goal:** Document a safe isolated restore procedure without automating state-changing restore operations.

**Exit criteria:**

- Prerequisites, target isolation, collision checks, evidence capture, cleanup, and rollback are documented
- Production distribution names and locations are protected by explicit stop conditions
- Synthetic examples only
- No automatic unregister, deletion, or destructive cleanup
- Sampling limitations are explicit

## Stage 4: Release readiness

**Entry gate:** Stages 1 through 3 are complete and documentation matches observed behavior.

**Goal:** Decide whether the project is mature enough for `v0.1.0`.

**Exit criteria:**

- Public interface and supported behavior are documented
- README examples are executed and validated
- `CHANGELOG.md` accurately records user-visible changes
- Security and confidentiality review returns no blocked material
- Local, pull-request, and post-merge CI pass
- No known CI warnings
- Release notes make no production-readiness or operational-recovery claims beyond evidence

## Deferred by design

- Unattended password handling
- Automatic backup deletion
- Automatic WSL unregister or restore cleanup
- Claims that sampled restoration proves every project, credential, or dependency works
