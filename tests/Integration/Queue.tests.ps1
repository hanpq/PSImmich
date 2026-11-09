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

# Read-only. Intentionally excluded: Clear-IMQueue and Set-IMQueue, because they clear jobs or change pause state of
# queues on the shared live server, which is not reset.
Describe 'Queue' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $script:AllQueues = @(Get-IMQueue)
    }

    Context 'Get-IMQueue' -Tag 'Get-IMQueue' {
        It -Name 'Should list all queues without error' {
            { $Result = Get-IMQueue } | Should -Not -Throw
        }

        It -Name 'Should return QueueResponseDto objects with name, isPaused and statistics' {
            if ($script:AllQueues.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No queues are returned by the server'
                return
            }
            foreach ($Queue in $script:AllQueues)
            {
                $Queue.GetType().Name | Should -Be 'QueueResponseDto'
                $Queue.PSObject.Properties.Name | Should -Contain 'name'
                $Queue.PSObject.Properties.Name | Should -Contain 'isPaused'
                $Queue.PSObject.Properties.Name | Should -Contain 'statistics'
                $Queue.isPaused | Should -BeOfType [System.Boolean]
            }
        }

        It -Name 'Should return a single queue by name <_>' -ForEach @('thumbnailGeneration', 'metadataExtraction') {
            $Result = @(Get-IMQueue -Name $_)
            $Result.Count | Should -Be 1
            $Result[0].name | Should -Be $_
        }

        It -Name 'Should return multiple queues when given several names' {
            $Result = @(Get-IMQueue -Name 'thumbnailGeneration', 'metadataExtraction')
            $Result.name | Should -Contain 'thumbnailGeneration'
            $Result.name | Should -Contain 'metadataExtraction'
        }

        It -Name 'Should accept queue names from the pipeline as strings' {
            $Result = @('thumbnailGeneration' | Get-IMQueue)
            $Result.name | Should -Be 'thumbnailGeneration'
        }

        It -Name 'Should accept queue objects from the pipeline' {
            if ($script:AllQueues.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No queues are returned by the server'
                return
            }
            $First = $script:AllQueues[0]
            $Result = @($First | Get-IMQueue)
            $Result.name | Should -Contain $First.name
        }

        It -Name 'Should return statistics with numeric counters' {
            $Result = Get-IMQueue -Name 'thumbnailGeneration'
            $Result.statistics.active | Should -BeOfType [System.Int64]
            $Result.statistics.waiting | Should -BeOfType [System.Int64]
        }

        It -Name 'Should throw for a queue name outside the allowed set' {
            { Get-IMQueue -Name 'notAQueue' } | Should -Throw
        }
    }

    Context 'Get-IMQueueJob' -Tag 'Get-IMQueueJob' {
        It -Name 'Should list jobs for the queue <_>' -ForEach @('thumbnailGeneration', 'metadataExtraction') {
            { $Result = Get-IMQueueJob -Name $_ } | Should -Not -Throw
        }

        It -Name 'Should return QueueJobResponseDto objects with expected properties' {
            $Result = @(Get-IMQueueJob -Name 'thumbnailGeneration')
            if ($Result.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'The thumbnailGeneration queue has no jobs'
                return
            }
            foreach ($Job in $Result)
            {
                $Job.GetType().Name | Should -Be 'QueueJobResponseDto'
                $Job.PSObject.Properties.Name | Should -Contain 'id'
                $Job.PSObject.Properties.Name | Should -Contain 'name'
                $Job.PSObject.Properties.Name | Should -Contain 'timestamp'
                $Job.PSObject.Properties.Name | Should -Contain 'data'
            }
        }

        It -Name 'Should filter jobs by status <_>' -ForEach @('waiting', 'active', 'completed', 'failed', 'delayed', 'paused') {
            { Get-IMQueueJob -Name 'thumbnailGeneration' -Status $_ } | Should -Not -Throw
        }

        It -Name 'Should filter jobs by multiple statuses' {
            { Get-IMQueueJob -Name 'thumbnailGeneration' -Status 'waiting', 'failed' } | Should -Not -Throw
        }

        It -Name 'Should throw for a queue name outside the allowed set' {
            { Get-IMQueueJob -Name 'notAQueue' } | Should -Throw
        }

        It -Name 'Should throw for a status outside the allowed set' {
            { Get-IMQueueJob -Name 'thumbnailGeneration' -Status 'notAStatus' } | Should -Throw
        }
    }
}
