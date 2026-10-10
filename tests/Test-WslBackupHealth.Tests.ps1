BeforeAll {
    $scriptUnderTest = Join-Path $PSScriptRoot '..\scripts\Test-WslBackupHealth.ps1'
}

Describe 'Test-WslBackupHealth' {
    BeforeEach {
        $testDirectory = Join-Path $TestDrive 'backups'
        if (Test-Path -LiteralPath $testDirectory) {
            Remove-Item -LiteralPath $testDirectory -Recurse -Force -ErrorAction Stop
        }
        New-Item -ItemType Directory -Path $testDirectory -ErrorAction Stop | Out-Null
    }

    It 'returns structured healthy evidence for a recent archive and matching checksum record' {
        $archive = Join-Path $testDirectory 'Ubuntu-snapshot-example.7z'
        Set-Content -LiteralPath $archive -Value 'synthetic archive bytes'
        $hash = 'A' * 64
        "$hash  $([IO.Path]::GetFileName($archive))" |
            Set-Content -LiteralPath "$archive.sha256"

        $result = & $scriptUnderTest -BackupDirectory $testDirectory -DueAfterDays 7
        $exitCode = $LASTEXITCODE

        $exitCode | Should -Be 0
        $result | Should -BeOfType [pscustomobject]
        $result.Due | Should -BeFalse
        $result.ChecksumRecordValid | Should -BeTrue
        $result.IntegrityRechecked | Should -BeFalse
        $result.MutationPerformed | Should -BeFalse
    }

    It 'returns due evidence when no archive exists' {
        $result = & $scriptUnderTest -BackupDirectory $testDirectory -DueAfterDays 7
        $exitCode = $LASTEXITCODE

        $exitCode | Should -Be 2
        $result.Due | Should -BeTrue
        $result.LatestCandidate | Should -BeNullOrEmpty
        $result.ChecksumRecordValid | Should -BeFalse
    }

    It 'returns due evidence when the checksum record names a different archive' {
        $archive = Join-Path $testDirectory 'Ubuntu-snapshot-example.7z'
        Set-Content -LiteralPath $archive -Value 'synthetic archive bytes'
        $hash = 'A' * 64
        "$hash  different.7z" | Set-Content -LiteralPath "$archive.sha256"

        $result = & $scriptUnderTest -BackupDirectory $testDirectory -DueAfterDays 7
        $exitCode = $LASTEXITCODE

        $exitCode | Should -Be 2
        $result.Due | Should -BeTrue
        $result.ChecksumRecordValid | Should -BeFalse
    }

    It 'does not create additional files' {
        $archive = Join-Path $testDirectory 'Ubuntu-snapshot-example.7z'
        Set-Content -LiteralPath $archive -Value 'synthetic archive bytes'
        $hash = 'A' * 64
        "$hash  $([IO.Path]::GetFileName($archive))" |
            Set-Content -LiteralPath "$archive.sha256"

        $before = @(Get-ChildItem -LiteralPath $testDirectory -File).Count
        $result = & $scriptUnderTest -BackupDirectory $testDirectory
        $exitCode = $LASTEXITCODE
        $after = @(Get-ChildItem -LiteralPath $testDirectory -File).Count

        $exitCode | Should -Be 0
        $result.MutationPerformed | Should -BeFalse
        $after | Should -Be $before
    }
}
