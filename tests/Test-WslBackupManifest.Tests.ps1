BeforeAll {
    $scriptUnderTest = Join-Path $PSScriptRoot '..\scripts\Test-WslBackupManifest.ps1'
}

Describe 'Test-WslBackupManifest' {
    BeforeEach {
        $testDirectory = Join-Path $TestDrive 'manifest-validation'

        if (Test-Path -LiteralPath $testDirectory) {
            Remove-Item -LiteralPath $testDirectory -Recurse -Force -ErrorAction Stop
        }

        New-Item -ItemType Directory -Path $testDirectory -ErrorAction Stop | Out-Null

        $archivePath = Join-Path $testDirectory 'Ubuntu-snapshot-example.7z'
        Set-Content -LiteralPath $archivePath -Value 'synthetic archive bytes' -NoNewline
        $archiveInfo = Get-Item -LiteralPath $archivePath
        $archiveHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash

        $manifestPath = Join-Path $testDirectory 'manifest.json'
        $manifest = [ordered]@{
            SchemaVersion = 1
            Distro = 'Ubuntu'
            RetainedArchive = $archivePath
            Bytes = $archiveInfo.Length
            SHA256 = $archiveHash
            CreatedUtc = '2026-01-01T00:00:00Z'
            Limitation = 'Synthetic fixture. No operational recovery claim.'
        }

        $manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    }

    It 'reports archive presence and matching size without recomputing the hash' {
        $output = & $scriptUnderTest -ManifestPath $manifestPath | Out-String

        $output | Should -Match 'ManifestReadable\s*:\s*True'
        $output | Should -Match 'ArchiveExists\s*:\s*True'
        $output | Should -Match 'SizeMatches\s*:\s*True'
        $output | Should -Match 'HashRecomputed\s*:\s*False'
        $output | Should -Match 'MutationPerformed\s*:\s*False'
    }

    It 'recomputes and matches the archive SHA256 when requested' {
        $output = & $scriptUnderTest -ManifestPath $manifestPath -RecomputeArchiveHash | Out-String

        $output | Should -Match 'HashRecomputed\s*:\s*True'
        $output | Should -Match 'HashMatches\s*:\s*True'
        $output | Should -Match 'MutationPerformed\s*:\s*False'
    }

    It 'reports a size mismatch when manifest bytes differ from the archive' {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        $manifest.Bytes = [int64]$manifest.Bytes + 1
        $manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding UTF8

        $output = & $scriptUnderTest -ManifestPath $manifestPath | Out-String

        $output | Should -Match 'ArchiveExists\s*:\s*True'
        $output | Should -Match 'SizeMatches\s*:\s*False'
    }

    It 'reports a hash mismatch when the recorded SHA256 is incorrect' {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        $manifest.SHA256 = 'A' * 64
        $manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding UTF8

        $output = & $scriptUnderTest -ManifestPath $manifestPath -RecomputeArchiveHash | Out-String

        $output | Should -Match 'HashRecomputed\s*:\s*True'
        $output | Should -Match 'HashMatches\s*:\s*False'
    }

    It 'throws when a required manifest property is missing' {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        $manifest.PSObject.Properties.Remove('SHA256')
        $manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding UTF8

        { & $scriptUnderTest -ManifestPath $manifestPath } |
            Should -Throw '*missing required properties: SHA256*'
    }

    It 'throws when the manifest file does not exist' {
        $missingManifest = Join-Path $testDirectory 'missing.json'

        { & $scriptUnderTest -ManifestPath $missingManifest } |
            Should -Throw '*Manifest does not exist*'
    }

    It 'does not modify the archive or manifest' {
        $archiveHashBefore = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
        $manifestHashBefore = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash

        & $scriptUnderTest -ManifestPath $manifestPath -RecomputeArchiveHash | Out-Null

        $archiveHashAfter = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
        $manifestHashAfter = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash

        $archiveHashAfter | Should -Be $archiveHashBefore
        $manifestHashAfter | Should -Be $manifestHashBefore
    }
}
