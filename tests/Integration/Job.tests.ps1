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

# Read-only. Intentionally excluded: Clear-IMJob, Start-IMJob, Suspend-IMJob and Resume-IMJob, because they change the
# state of background job queues (including emptying trash) on the shared live server, which is not reset.
Describe 'Job' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $script:AllJobs = @(Get-IMJob)
    }

    Context 'Get-IMJob' -Tag 'Get-IMJob' {
        It -Name 'Should list all jobs without error' {
            { $Result = Get-IMJob } | Should -Not -Throw
        }

        It -Name 'Should return job queues that include thumbnailGeneration' {
            $script:AllJobs.name | Should -Contain 'thumbnailGeneration'
        }

        It -Name 'Should return QueueResponseDto objects' {
            if ($script:AllJobs.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No job queues are returned by the server'
                return
            }
            foreach ($Job in $script:AllJobs)
            {
                $Job.GetType().Name | Should -Be 'QueueResponseDto'
                $Job.PSObject.Properties.Name | Should -Contain 'name'
                $Job.PSObject.Properties.Name | Should -Contain 'isPaused'
                $Job.PSObject.Properties.Name | Should -Contain 'statistics'
            }
        }

        It -Name 'Should return a boolean isPaused flag for each queue' {
            if ($script:AllJobs.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No job queues are returned by the server'
                return
            }
            foreach ($Job in $script:AllJobs)
            {
                $Job.isPaused | Should -BeOfType [System.Boolean]
            }
        }

        It -Name 'Should return queue statistics with the expected counters' {
            if ($script:AllJobs.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No job queues are returned by the server'
                return
            }
            foreach ($Job in $script:AllJobs)
            {
                $Job.statistics.PSObject.Properties.Name | Should -Contain 'active'
                $Job.statistics.PSObject.Properties.Name | Should -Contain 'completed'
                $Job.statistics.PSObject.Properties.Name | Should -Contain 'delayed'
                $Job.statistics.PSObject.Properties.Name | Should -Contain 'failed'
                $Job.statistics.PSObject.Properties.Name | Should -Contain 'paused'
                $Job.statistics.PSObject.Properties.Name | Should -Contain 'waiting'
            }
        }

        It -Name 'Should return non-negative queue counters' {
            if ($script:AllJobs.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No job queues are returned by the server'
                return
            }
            foreach ($Job in $script:AllJobs)
            {
                $Job.statistics.active | Should -BeGreaterOrEqual 0
                $Job.statistics.waiting | Should -BeGreaterOrEqual 0
            }
        }

        It -Name 'Should return the same queues on a second call' {
            $Second = @(Get-IMJob)
            $Second.Count | Should -Be $script:AllJobs.Count
        }

        It -Name 'Should support pipeline input from Where-Object filtering' {
            { Get-IMJob | Where-Object { $_.name -eq 'thumbnailGeneration' } } | Should -Not -Throw
        }
    }
}
