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

    It 'returns 0 for a recent archive with matching checksum filename evidence' {
        $archive = Join-Path $testDirectory 'Ubuntu-snapshot-example.7z'
        Set-Content -LiteralPath $archive -Value 'synthetic archive bytes'
        $hash = 'A' * 64
        "$hash  $([IO.Path]::GetFileName($archive))" |
            Set-Content -LiteralPath "$archive.sha256"

        & $scriptUnderTest -BackupDirectory $testDirectory -DueAfterDays 7

        $LASTEXITCODE | Should -Be 0
    }

    It 'returns 2 when no archive exists' {
        & $scriptUnderTest -BackupDirectory $testDirectory -DueAfterDays 7

        $LASTEXITCODE | Should -Be 2
    }

    It 'returns 2 when checksum evidence names a different archive' {
        $archive = Join-Path $testDirectory 'Ubuntu-snapshot-example.7z'
        Set-Content -LiteralPath $archive -Value 'synthetic archive bytes'
        $hash = 'A' * 64
        "$hash  different.7z" | Set-Content -LiteralPath "$archive.sha256"

        & $scriptUnderTest -BackupDirectory $testDirectory -DueAfterDays 7

        $LASTEXITCODE | Should -Be 2
    }

    It 'does not create additional files' {
        $archive = Join-Path $testDirectory 'Ubuntu-snapshot-example.7z'
        Set-Content -LiteralPath $archive -Value 'synthetic archive bytes'
        $hash = 'A' * 64
        "$hash  $([IO.Path]::GetFileName($archive))" |
            Set-Content -LiteralPath "$archive.sha256"

        $before = @(Get-ChildItem -LiteralPath $testDirectory -File).Count

        & $scriptUnderTest -BackupDirectory $testDirectory
        $exitCode = $LASTEXITCODE

        $after = @(Get-ChildItem -LiteralPath $testDirectory -File).Count

        $exitCode | Should -Be 0
        $after | Should -Be $before
    }
}
