#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ManifestPath,
    [switch]$RecomputeArchiveHash
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Manifest does not exist: $ManifestPath"
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$required = @('SchemaVersion','Distro','RetainedArchive','Bytes','SHA256','CreatedUtc','Limitation')
$missing = @($required | Where-Object { -not $manifest.PSObject.Properties[$_] })
if ($missing.Count -gt 0) {
    throw "Manifest is missing required properties: $($missing -join ', ')"
}

$archiveExists = Test-Path -LiteralPath $manifest.RetainedArchive -PathType Leaf
$sizeMatches = $false
$calculatedHash = $null
$hashMatches = $null

if ($archiveExists) {
    $archiveInfo = Get-Item -LiteralPath $manifest.RetainedArchive
    $sizeMatches = [int64]$manifest.Bytes -eq $archiveInfo.Length
    if ($RecomputeArchiveHash) {
        $calculatedHash = (Get-FileHash -LiteralPath $archiveInfo.FullName -Algorithm SHA256).Hash
        $hashMatches = $calculatedHash -eq $manifest.SHA256
    }
}

[pscustomobject]@{
    ManifestReadable = $true
    ArchiveExists = $archiveExists
    SizeMatches = $sizeMatches
    HashRecomputed = [bool]$RecomputeArchiveHash
    CalculatedSHA256 = $calculatedHash
    HashMatches = $hashMatches
    MutationPerformed = $false
    Limitation = if ($RecomputeArchiveHash) {
        'Archive presence, size, and SHA-256 were evaluated. Password and restore behavior were not tested.'
    } else {
        'Archive presence and size were evaluated. SHA-256, password, and restore behavior were not tested.'
    }
}
