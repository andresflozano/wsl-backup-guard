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

    It 'returns structured archive evidence without recomputing the hash' {
        $result = & $scriptUnderTest -ManifestPath $manifestPath

        $result | Should -BeOfType [pscustomobject]
        $result.ManifestReadable | Should -BeTrue
        $result.ArchiveExists | Should -BeTrue
        $result.SizeMatches | Should -BeTrue
        $result.HashRecomputed | Should -BeFalse
        $result.HashMatches | Should -BeNullOrEmpty
        $result.MutationPerformed | Should -BeFalse
    }

    It 'recomputes and matches the archive SHA256 when requested' {
        $result = & $scriptUnderTest -ManifestPath $manifestPath -RecomputeArchiveHash

        $result.HashRecomputed | Should -BeTrue
        $result.HashMatches | Should -BeTrue
        $result.CalculatedSHA256 | Should -Be $archiveHash
        $result.MutationPerformed | Should -BeFalse
    }

    It 'reports a size mismatch when manifest bytes differ from the archive' {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        $manifest.Bytes = [int64]$manifest.Bytes + 1
        $manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding UTF8

        $result = & $scriptUnderTest -ManifestPath $manifestPath

        $result.ArchiveExists | Should -BeTrue
        $result.SizeMatches | Should -BeFalse
    }

    It 'reports a hash mismatch when the recorded SHA256 is incorrect' {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        $manifest.SHA256 = 'A' * 64
        $manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding UTF8

        $result = & $scriptUnderTest -ManifestPath $manifestPath -RecomputeArchiveHash

        $result.HashRecomputed | Should -BeTrue
        $result.HashMatches | Should -BeFalse
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

        (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash |
            Should -Be $archiveHashBefore
        (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash |
            Should -Be $manifestHashBefore
    }
}
