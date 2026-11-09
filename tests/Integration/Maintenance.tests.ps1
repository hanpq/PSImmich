BeforeDiscovery {
    $RootItem = Get-Item $PSScriptRoot
    while ($RootItem.GetDirectories().Name -notcontains 'source')
    {
        $RootItem = $RootItem.Parent
    }
    $ProjectPath = $RootItem.FullName
    $ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
            ($_.Directory.Name -eq 'source') -and
            $(try
                {
                    Test-ModuleManifest $_.FullName -ErrorAction Stop
                }
                catch
                {
                    $false
                })
        }
    ).BaseName

    Import-Module $ProjectName -Force
}

# Read-only. Intentionally excluded: Start-IMMaintenanceMode and Stop-IMMaintenanceMode (they put the shared server into
# or out of maintenance mode), Save-IMDatabaseBackup and Remove-IMDatabaseBackup (they create or delete backups on the
# shared server), and Save-IMIntegrityReport and Remove-IMIntegrityReport (they start or delete integrity checks).
Describe 'Maintenance' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $script:MaintenanceStatus = Get-IMMaintenanceStatus
        $script:DatabaseBackups = @(Get-IMDatabaseBackup)
    }

    Context 'Get-IMMaintenanceStatus' -Tag 'Get-IMMaintenanceStatus' {
        It -Name 'Should return the maintenance status' {
            $script:MaintenanceStatus | Should -Not -BeNullOrEmpty
            $script:MaintenanceStatus.GetType().Name | Should -Be 'MaintenanceStatusResponseDto'
        }

        It -Name 'Should expose the expected status properties' {
            $script:MaintenanceStatus.PSObject.Properties.Name | Should -Contain 'active'
            $script:MaintenanceStatus.PSObject.Properties.Name | Should -Contain 'action'
            $script:MaintenanceStatus.PSObject.Properties.Name | Should -Contain 'progress'
            $script:MaintenanceStatus.PSObject.Properties.Name | Should -Contain 'task'
            $script:MaintenanceStatus.PSObject.Properties.Name | Should -Contain 'error'
        }

        It -Name 'Should return a boolean active flag' {
            $script:MaintenanceStatus.active | Should -BeOfType [System.Boolean]
        }

        It -Name 'Should return a numeric progress value' {
            $script:MaintenanceStatus.progress | Should -BeOfType [System.Int64]
        }

        It -Name 'Should return the status again on a second call' {
            $Second = Get-IMMaintenanceStatus
            $Second.GetType().Name | Should -Be 'MaintenanceStatusResponseDto'
        }
    }

    Context 'Get-IMDatabaseBackup' -Tag 'Get-IMDatabaseBackup' {
        It -Name 'Should list database backups without error' {
            { $Result = Get-IMDatabaseBackup } | Should -Not -Throw
        }

        It -Name 'Should return DatabaseBackupDto objects with expected properties' {
            if ($script:DatabaseBackups.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No database backups exist on the server'
                return
            }
            foreach ($Backup in $script:DatabaseBackups)
            {
                $Backup.GetType().Name | Should -Be 'DatabaseBackupDto'
                $Backup.PSObject.Properties.Name | Should -Contain 'filename'
                $Backup.PSObject.Properties.Name | Should -Contain 'filesize'
                $Backup.PSObject.Properties.Name | Should -Contain 'timezone'
            }
        }

        It -Name 'Should return filenames as strings and sizes as 64-bit integers' {
            if ($script:DatabaseBackups.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No database backups exist on the server'
                return
            }
            foreach ($Backup in $script:DatabaseBackups)
            {
                $Backup.filename | Should -BeOfType [System.String]
                $Backup.filesize | Should -BeOfType [System.Int64]
            }
        }

        It -Name 'Should return backups sortable by file size through the pipeline' {
            if ($script:DatabaseBackups.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No database backups exist on the server'
                return
            }
            $Sorted = @(Get-IMDatabaseBackup | Sort-Object -Property filesize)
            $Sorted.Count | Should -Be $script:DatabaseBackups.Count
            for ($i = 1; $i -lt $Sorted.Count; $i++)
            {
                $Sorted[$i].filesize | Should -BeGreaterOrEqual $Sorted[$i - 1].filesize
            }
        }
    }

    Context 'Get-IMIntegrityReport' -Tag 'Get-IMIntegrityReport' {
        It -Name 'Should return an integrity report summary with -Summary' {
            $Result = Get-IMIntegrityReport -Summary
            $Result.GetType().Name | Should -Be 'IntegrityReportSummaryResponseDto'
            $Result.PSObject.Properties.Name | Should -Contain 'checksum_mismatch'
            $Result.PSObject.Properties.Name | Should -Contain 'missing_file'
            $Result.PSObject.Properties.Name | Should -Contain 'untracked_file'
        }

        It -Name 'Should return summary counts as 64-bit integers' {
            $Result = Get-IMIntegrityReport -Summary
            $Result.checksum_mismatch | Should -BeOfType [System.Int64]
            $Result.missing_file | Should -BeOfType [System.Int64]
            $Result.untracked_file | Should -BeOfType [System.Int64]
        }

        It -Name 'Should return a report for integrity type <_>' -ForEach @('untracked_file', 'missing_file', 'checksum_mismatch') {
            $Result = Get-IMIntegrityReport -Type $_
            $Result.GetType().Name | Should -Be 'IntegrityReportResponseDto'
            $Result.PSObject.Properties.Name | Should -Contain 'items'
            $Result.PSObject.Properties.Name | Should -Contain 'nextCursor'
        }

        It -Name 'Should limit the number of report items with -Limit' {
            $Result = Get-IMIntegrityReport -Type 'untracked_file' -Limit 1
            @($Result.items).Count | Should -BeLessOrEqual 1
        }

        It -Name 'Should continue a report with -Cursor when a next cursor exists' {
            $First = Get-IMIntegrityReport -Type 'untracked_file' -Limit 1
            if ([string]::IsNullOrEmpty($First.nextCursor))
            {
                Set-ItResult -Skipped -Because 'The integrity report has no further pages'
                return
            }
            $Second = Get-IMIntegrityReport -Type 'untracked_file' -Limit 1 -Cursor $First.nextCursor
            $Second.GetType().Name | Should -Be 'IntegrityReportResponseDto'
        }

        It -Name 'Should throw for an invalid integrity report type' {
            { Get-IMIntegrityReport -Type 'not_a_type' } | Should -Throw
        }

        It -Name 'Should throw when combining -Summary with -Limit' {
            { Get-IMIntegrityReport -Summary -Limit 1 } | Should -Throw
        }
    }
}
