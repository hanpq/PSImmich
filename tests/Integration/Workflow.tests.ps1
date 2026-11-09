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

# No Workflow cmdlets are excluded. All create, update and remove operations target only workflows created by this run, identified by a unique name prefix, and are removed in AfterAll.
Describe 'Workflow' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY

        $script:RunId = [guid]::NewGuid().ToString('N').Substring(0, 8)
        $script:NamePrefix = "PSImmich-IT-$($script:RunId)"
        $script:CreatedIds = [System.Collections.Generic.List[string]]::new()

        function New-TestWorkflow
        {
            param(
                [string]$Suffix = 'base',
                [string]$Trigger = 'AssetCreate',
                [bool]$Enabled = $true,
                [bool]$Logging,
                [switch]$WithLogging
            )
            $Parameters = @{
                Name        = "$script:NamePrefix-$Suffix"
                Trigger     = $Trigger
                Description = "PSImmich integration test $Suffix"
                Enabled     = $Enabled
                Steps       = @()
            }
            if ($WithLogging)
            {
                $Parameters.Logging = $Logging
            }
            $Workflow = New-IMWorkflow @Parameters
            $script:CreatedIds.Add($Workflow.id)
            $Workflow
        }
    }

    AfterAll {
        foreach ($Id in $script:CreatedIds)
        {
            try
            {
                Remove-IMWorkflow -Id $Id -Confirm:$false
            }
            catch
            {
                # Already removed by the test itself
            }
        }
        Get-IMWorkflow |
            Where-Object { $_.name -like "$script:NamePrefix*" } |
            ForEach-Object {
                Remove-IMWorkflow -Id $_.id -Confirm:$false
            }
    }

    Context 'Get-IMWorkflow' -Tag 'Get-IMWorkflow' {
        It -Name 'Should list all workflows without error' {
            { $Result = Get-IMWorkflow } | Should -Not -Throw
        }

        It -Name 'Should return WorkflowResponseDto objects for the list' {
            New-TestWorkflow -Suffix 'list-type' | Out-Null
            $Result = Get-IMWorkflow
            $Result | Should -Not -BeNullOrEmpty
            foreach ($Item in $Result)
            {
                $Item.GetType().Name | Should -Be 'WorkflowResponseDto'
            }
        }

        It -Name 'Should get a specific workflow by ID' {
            $TestWorkflow = New-TestWorkflow -Suffix 'by-id'
            $Result = Get-IMWorkflow -Id $TestWorkflow.id
            $Result.id | Should -Be $TestWorkflow.id
            $Result.name | Should -Be $TestWorkflow.name
            $Result.GetType().Name | Should -Be 'WorkflowResponseDto'
        }

        It -Name 'Should support pipeline input with workflow ID' {
            $TestWorkflow = New-TestWorkflow -Suffix 'pipeline-id'
            $Result = $TestWorkflow.id | Get-IMWorkflow
            $Result.id | Should -Be $TestWorkflow.id
        }

        It -Name 'Should support pipeline input with a workflow object' {
            $TestWorkflow = New-TestWorkflow -Suffix 'pipeline-object'
            $Result = $TestWorkflow | Get-IMWorkflow
            $Result.id | Should -Be $TestWorkflow.id
        }

        It -Name 'Should return multiple workflows when piping several IDs' {
            $First = New-TestWorkflow -Suffix 'multi-1'
            $Second = New-TestWorkflow -Suffix 'multi-2'
            $Result = @($First.id, $Second.id | Get-IMWorkflow)
            $Result.id | Should -Contain $First.id
            $Result.id | Should -Contain $Second.id
        }

        It -Name 'Should filter the list by name' {
            $TestWorkflow = New-TestWorkflow -Suffix 'filter-name'
            $Result = Get-IMWorkflow -Name $TestWorkflow.name
            $Result.id | Should -Contain $TestWorkflow.id
        }

        It -Name 'Should filter the list by enabled state' {
            $Disabled = New-TestWorkflow -Suffix 'filter-disabled' -Enabled $false
            $Result = Get-IMWorkflow -Enabled $false
            $Result.id | Should -Contain $Disabled.id
            foreach ($Item in $Result)
            {
                $Item.enabled | Should -BeFalse
            }
        }

        It -Name 'Should filter the list by trigger' {
            $TestWorkflow = New-TestWorkflow -Suffix 'filter-trigger' -Trigger 'AssetTagged'
            $Result = Get-IMWorkflow -Trigger 'AssetTagged'
            $Result.id | Should -Contain $TestWorkflow.id
            foreach ($Item in $Result)
            {
                $Item.trigger | Should -Be 'AssetTagged'
            }
        }

        It -Name 'Should throw when getting a non-existent workflow' {
            { Get-IMWorkflow -Id 'ffffffff-ffff-ffff-ffff-ffffffffffff' } | Should -Throw
        }

        It -Name 'Should throw for an ID that is not a GUID' {
            { Get-IMWorkflow -Id 'not-a-guid' } | Should -Throw
        }

        It -Name 'Should throw for an invalid trigger filter' {
            { Get-IMWorkflow -Trigger 'NotATrigger' } | Should -Throw
        }

        It -Name 'Should throw when combining -Id with list filters' {
            { Get-IMWorkflow -Id 'ffffffff-ffff-ffff-ffff-ffffffffffff' -Name 'x' } | Should -Throw
        }
    }

    Context 'Get-IMWorkflow -Share' -Tag 'Get-IMWorkflow' {
        It -Name 'Should return the shareable representation of a workflow' {
            $TestWorkflow = New-TestWorkflow -Suffix 'share'
            { Get-IMWorkflow -Id $TestWorkflow.id -Share } | Should -Not -Throw
            $Result = Get-IMWorkflow -Id $TestWorkflow.id -Share
            $Result.GetType().Name | Should -Be 'WorkflowShareResponseDto'
        }
    }

    Context 'Get-IMWorkflowLog' -Tag 'Get-IMWorkflowLog' {
        BeforeAll {
            $script:LoggedWorkflow = New-TestWorkflow -Suffix 'log' -WithLogging -Logging $true
        }

        It -Name 'Should return run logs for a workflow without error' {
            { Get-IMWorkflowLog -Id $script:LoggedWorkflow.id } | Should -Not -Throw
        }

        It -Name 'Should return WorkflowLogEntryDto objects when log entries exist' {
            $Result = @(Get-IMWorkflowLog -Id $script:LoggedWorkflow.id)
            if ($Result.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'The test workflow has no run log entries yet'
                return
            }
            foreach ($Item in $Result)
            {
                $Item.GetType().Name | Should -Be 'WorkflowLogEntryDto'
            }
        }

        It -Name 'Should honour the Limit parameter' {
            $Result = @(Get-IMWorkflowLog -Id $script:LoggedWorkflow.id -Limit 1)
            $Result.Count | Should -BeLessOrEqual 1
        }

        It -Name 'Should support pipeline input with workflow ID' {
            { $script:LoggedWorkflow.id | Get-IMWorkflowLog } | Should -Not -Throw
        }

        It -Name 'Should accept each valid Result filter value' -ForEach @(
            @{ Result = 'completed' }
            @{ Result = 'halted' }
            @{ Result = 'error' }
        ) {
            { Get-IMWorkflowLog -Id $script:LoggedWorkflow.id -Result $Result } | Should -Not -Throw
        }

        It -Name 'Should throw for an invalid Result filter value' {
            { Get-IMWorkflowLog -Id $script:LoggedWorkflow.id -Result 'unknown' } | Should -Throw
        }

        It -Name 'Should throw for an ID that is not a GUID' {
            { Get-IMWorkflowLog -Id 'not-a-guid' } | Should -Throw
        }
    }

    Context 'Get-IMWorkflowTrigger' -Tag 'Get-IMWorkflowTrigger' {
        It -Name 'Should list workflow triggers without error' {
            { $Result = Get-IMWorkflowTrigger } | Should -Not -Throw
        }

        It -Name 'Should return WorkflowTriggerResponseDto objects' {
            $Result = Get-IMWorkflowTrigger
            $Result | Should -Not -BeNullOrEmpty
            foreach ($Item in $Result)
            {
                $Item.GetType().Name | Should -Be 'WorkflowTriggerResponseDto'
            }
        }

        It -Name 'Should include the AssetCreate trigger' {
            $Result = Get-IMWorkflowTrigger
            $Result.trigger | Should -Contain 'AssetCreate'
        }

        It -Name 'Should expose the types of each trigger as a collection' {
            $Result = Get-IMWorkflowTrigger
            foreach ($Item in $Result)
            {
                $Item.PSObject.Properties.Name | Should -Contain 'types'
            }
        }
    }

    Context 'New-IMWorkflow' -Tag 'New-IMWorkflow' {
        It -Name 'Should create a workflow with basic parameters' {
            $NewWorkflow = New-TestWorkflow -Suffix 'create-basic'
            $NewWorkflow.name | Should -Be "$script:NamePrefix-create-basic"
            $NewWorkflow.description | Should -Be 'PSImmich integration test create-basic'
            $NewWorkflow.trigger | Should -Be 'AssetCreate'
            $NewWorkflow.enabled | Should -BeTrue
            $NewWorkflow.id | Should -Not -BeNullOrEmpty
            $NewWorkflow.GetType().Name | Should -Be 'WorkflowResponseDto'

            $Retrieved = Get-IMWorkflow -Id $NewWorkflow.id
            $Retrieved.name | Should -Be $NewWorkflow.name
        }

        It -Name 'Should create a disabled workflow' {
            $NewWorkflow = New-TestWorkflow -Suffix 'create-disabled' -Enabled $false
            $NewWorkflow.enabled | Should -BeFalse
        }

        It -Name 'Should create a workflow with logging enabled' {
            $NewWorkflow = New-TestWorkflow -Suffix 'create-logging' -WithLogging -Logging $true
            $NewWorkflow.logging | Should -BeTrue
        }

        It -Name 'Should create a workflow with an empty steps collection' {
            $NewWorkflow = New-TestWorkflow -Suffix 'create-steps'
            $Retrieved = Get-IMWorkflow -Id $NewWorkflow.id
            $Retrieved.name | Should -Be $NewWorkflow.name
        }

        It -Name 'Should create a workflow without a description' {
            $Name = "$script:NamePrefix-create-nodesc"
            $NewWorkflow = New-IMWorkflow -Name $Name -Trigger 'AssetCreate' -Steps @()
            $script:CreatedIds.Add($NewWorkflow.id)
            $NewWorkflow.name | Should -Be $Name
        }

        It -Name 'Should create a workflow for the <Trigger> trigger' -ForEach @(
            @{ Trigger = 'AssetCreate' }
            @{ Trigger = 'AssetMetadataExtraction' }
            @{ Trigger = 'AssetTagged' }
        ) {
            $NewWorkflow = New-TestWorkflow -Suffix "create-$Trigger" -Trigger $Trigger
            $NewWorkflow.trigger | Should -Be $Trigger
        }

        It -Name 'Should throw for an invalid trigger' {
            { New-IMWorkflow -Name "$script:NamePrefix-invalid" -Trigger 'NotATrigger' -Steps @() } | Should -Throw
        }
    }

    Context 'Set-IMWorkflow' -Tag 'Set-IMWorkflow' {
        BeforeAll {
            $script:UpdateWorkflow = New-TestWorkflow -Suffix 'update-base'
        }

        It -Name 'Should update the workflow name' {
            $UpdatedName = "$script:NamePrefix-update-renamed"
            Set-IMWorkflow -Id $script:UpdateWorkflow.id -Name $UpdatedName -Confirm:$false
            $Result = Get-IMWorkflow -Id $script:UpdateWorkflow.id
            $Result.name | Should -Be $UpdatedName
            $script:UpdateWorkflow.name = $UpdatedName
        }

        It -Name 'Should update the workflow description' {
            $UpdatedDescription = 'Updated integration test workflow description'
            Set-IMWorkflow -Id $script:UpdateWorkflow.id -Description $UpdatedDescription -Confirm:$false
            $Result = Get-IMWorkflow -Id $script:UpdateWorkflow.id
            $Result.description | Should -Be $UpdatedDescription
        }

        It -Name 'Should toggle the workflow enabled state' {
            Set-IMWorkflow -Id $script:UpdateWorkflow.id -Enabled:$false -Confirm:$false
            (Get-IMWorkflow -Id $script:UpdateWorkflow.id).enabled | Should -BeFalse

            Set-IMWorkflow -Id $script:UpdateWorkflow.id -Enabled:$true -Confirm:$false
            (Get-IMWorkflow -Id $script:UpdateWorkflow.id).enabled | Should -BeTrue
        }

        It -Name 'Should update the logging setting' {
            Set-IMWorkflow -Id $script:UpdateWorkflow.id -Logging:$true -Confirm:$false
            (Get-IMWorkflow -Id $script:UpdateWorkflow.id).logging | Should -BeTrue
        }

        It -Name 'Should update the trigger' {
            Set-IMWorkflow -Id $script:UpdateWorkflow.id -Trigger 'AssetTagged' -Confirm:$false
            (Get-IMWorkflow -Id $script:UpdateWorkflow.id).trigger | Should -Be 'AssetTagged'

            Set-IMWorkflow -Id $script:UpdateWorkflow.id -Trigger 'AssetCreate' -Confirm:$false
            (Get-IMWorkflow -Id $script:UpdateWorkflow.id).trigger | Should -Be 'AssetCreate'
        }

        It -Name 'Should return a WorkflowResponseDto' {
            $Result = Set-IMWorkflow -Id $script:UpdateWorkflow.id -Description 'Return type check' -Confirm:$false
            $Result.GetType().Name | Should -Be 'WorkflowResponseDto'
        }

        It -Name 'Should support pipeline input with a workflow ID' {
            $UpdatedName = "$script:NamePrefix-update-pipeline-id"
            $script:UpdateWorkflow.id | Set-IMWorkflow -Name $UpdatedName -Confirm:$false
            (Get-IMWorkflow -Id $script:UpdateWorkflow.id).name | Should -Be $UpdatedName
        }

        It -Name 'Should support pipeline input with a workflow object' {
            $Target = New-TestWorkflow -Suffix 'update-pipeline-object'
            $UpdatedDescription = 'Updated via workflow object pipeline'
            $Target | Set-IMWorkflow -Description $UpdatedDescription -Confirm:$false
            (Get-IMWorkflow -Id $Target.id).description | Should -Be $UpdatedDescription
        }

        It -Name 'Should update multiple workflows in one call' {
            $First = New-TestWorkflow -Suffix 'update-multi-1'
            $Second = New-TestWorkflow -Suffix 'update-multi-2'
            Set-IMWorkflow -Id $First.id, $Second.id -Enabled:$false -Confirm:$false
            (Get-IMWorkflow -Id $First.id).enabled | Should -BeFalse
            (Get-IMWorkflow -Id $Second.id).enabled | Should -BeFalse
        }

        It -Name 'Should not change the workflow when -WhatIf is used' {
            $Before = (Get-IMWorkflow -Id $script:UpdateWorkflow.id).name
            Set-IMWorkflow -Id $script:UpdateWorkflow.id -Name "$script:NamePrefix-whatif" -WhatIf
            (Get-IMWorkflow -Id $script:UpdateWorkflow.id).name | Should -Be $Before
        }

        It -Name 'Should throw for an ID that is not a GUID' {
            { Set-IMWorkflow -Id 'not-a-guid' -Name 'x' -Confirm:$false } | Should -Throw
        }

        It -Name 'Should throw for an invalid trigger' {
            { Set-IMWorkflow -Id $script:UpdateWorkflow.id -Trigger 'NotATrigger' -Confirm:$false } | Should -Throw
        }
    }

    Context 'Remove-IMWorkflow' -Tag 'Remove-IMWorkflow' {
        It -Name 'Should remove a workflow by ID' {
            $TestWorkflow = New-TestWorkflow -Suffix 'remove-by-id'
            Remove-IMWorkflow -Id $TestWorkflow.id -Confirm:$false
            { Get-IMWorkflow -Id $TestWorkflow.id } | Should -Throw
        }

        It -Name 'Should support pipeline input with a workflow ID' {
            $TestWorkflow = New-TestWorkflow -Suffix 'remove-pipeline-id'
            $TestWorkflow.id | Remove-IMWorkflow -Confirm:$false
            { Get-IMWorkflow -Id $TestWorkflow.id } | Should -Throw
        }

        It -Name 'Should support pipeline input with a workflow object' {
            $TestWorkflow = New-TestWorkflow -Suffix 'remove-pipeline-object'
            $TestWorkflow | Remove-IMWorkflow -Confirm:$false
            { Get-IMWorkflow -Id $TestWorkflow.id } | Should -Throw
        }

        It -Name 'Should remove multiple workflows in one call' {
            $First = New-TestWorkflow -Suffix 'remove-multi-1'
            $Second = New-TestWorkflow -Suffix 'remove-multi-2'
            Remove-IMWorkflow -Id $First.id, $Second.id -Confirm:$false
            { Get-IMWorkflow -Id $First.id } | Should -Throw
            { Get-IMWorkflow -Id $Second.id } | Should -Throw
        }

        It -Name 'Should not remove the workflow when -WhatIf is used' {
            $TestWorkflow = New-TestWorkflow -Suffix 'remove-whatif'
            Remove-IMWorkflow -Id $TestWorkflow.id -WhatIf
            (Get-IMWorkflow -Id $TestWorkflow.id).id | Should -Be $TestWorkflow.id
        }

        It -Name 'Should throw for an ID that is not a GUID' {
            { Remove-IMWorkflow -Id 'not-a-guid' -Confirm:$false } | Should -Throw
        }
    }
}
