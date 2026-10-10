#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BackupDirectory,
    [string]$DistroName = 'Ubuntu',
    [ValidateRange(1,365)][int]$DueAfterDays = 7,
    [string]$ArchivePattern = '*.7z'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$exitCode = 1

try {
    if (-not (Test-Path -LiteralPath $BackupDirectory -PathType Container)) {
        throw "Backup directory does not exist: $BackupDirectory"
    }

    $candidates = @(
        Get-ChildItem -LiteralPath $BackupDirectory -Filter $ArchivePattern -File |
            Where-Object { $_.Length -gt 0 } |
            Sort-Object LastWriteTimeUtc -Descending
    )

    $latest = $null
    $checksumPath = $null
    $recordedHash = $null
    $recordedFileName = $null
    $checksumRecordValid = $false
    $ageDays = $null

    if ($candidates.Count -gt 0) {
        $latest = $candidates[0]
        $ageDays = ([DateTime]::UtcNow - $latest.LastWriteTimeUtc).TotalDays
        $checksumPath = $latest.FullName + '.sha256'

        if (Test-Path -LiteralPath $checksumPath -PathType Leaf) {
            $checksumText = (Get-Content -LiteralPath $checksumPath -Raw).Trim()
            $match = [regex]::Match($checksumText, '^(?<hash>[A-Fa-f0-9]{64})\s+(?<file>\S+)$')
            if ($match.Success) {
                $recordedHash = $match.Groups['hash'].Value.ToUpperInvariant()
                $recordedFileName = $match.Groups['file'].Value
                $checksumRecordValid = $recordedFileName -eq $latest.Name
            }
        }
    }

    $due = (
        $null -eq $latest -or
        -not $checksumRecordValid -or
        $ageDays -ge $DueAfterDays
    )

    [pscustomobject]@{
        Mode = 'Check'
        DistroName = $DistroName
        BackupDirectory = $BackupDirectory
        LatestCandidate = if ($latest) { $latest.FullName } else { $null }
        CandidateBytes = if ($latest) { $latest.Length } else { $null }
        AgeDays = if ($null -ne $ageDays) { [Math]::Round($ageDays, 2) } else { $null }
        ChecksumPath = $checksumPath
        ChecksumRecordValid = $checksumRecordValid
        RecordedSHA256 = $recordedHash
        DueAfterDays = $DueAfterDays
        Due = $due
        IntegrityRechecked = $false
        MutationPerformed = $false
        Limitation = 'No archive hash, password, extraction, import, cloud-presence, or application validation was performed.'
    } | Format-List

    $exitCode = if ($due) { 2 } else { 0 }
}
catch {
    Write-Warning $_.Exception.Message
    $exitCode = 1
}

exit $exitCode
