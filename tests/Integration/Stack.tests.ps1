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

Describe 'Stack' -Tag 'Integration' {
    # Intentionally excluded cmdlets: none.
    # Only assets that are not already in a stack are picked. Pre-existing stacks are never modified or removed.
    # Tests that cannot find enough unstacked assets are skipped rather than touching existing stacks.

    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $script:Candidates = @(
            'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'
            'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
            'bdc6d2c8-6168-4a88-a51f-6da11bf8f506'
            '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        )
        $script:CreatedStackIds = [System.Collections.Generic.List[string]]::new()
        $script:GetFreeAssets = {
            $Stacked = @((Get-IMStack).assets.id)
            @($script:Candidates | Where-Object { $_ -notin $Stacked })
        }
        $script:NewTestStack = {
            param([string[]]$AssetIds)
            $Stack = New-IMStack -AssetIds $AssetIds
            $script:CreatedStackIds.Add($Stack.id)
            $Stack
        }
    }

    AfterAll {
        foreach ($Id in $script:CreatedStackIds)
        {
            try
            {
                Remove-IMStack -Id $Id -Force -Confirm:$false
            }
            catch
            {
                $null = $_
            }
        }
    }

    Context 'New-IMStack' -Tag 'New-IMStack' {
        It 'Creates a stack from two unstacked assets and returns StackResponseDto' {
            $Free = & $script:GetFreeAssets
            if ($Free.Count -lt 2) { Set-ItResult -Skipped -Because 'Fewer than 2 unstacked candidate assets'; return }
            $Stack = & $script:NewTestStack -AssetIds $Free[0], $Free[1]
            $Stack.GetType().Name | Should -Be 'StackResponseDto'
            $Stack.id | Should -Not -BeNullOrEmpty
            $Stack.assets | Should -HaveCount 2
        }

        It 'Uses the first asset as the primary asset' {
            $Free = & $script:GetFreeAssets
            if ($Free.Count -lt 2) { Set-ItResult -Skipped -Because 'Fewer than 2 unstacked candidate assets'; return }
            $Stack = & $script:NewTestStack -AssetIds $Free[0], $Free[1]
            $Stack.primaryAssetId | Should -Be $Free[0]
        }

        It 'Includes every requested asset in the stack' {
            $Free = & $script:GetFreeAssets
            if ($Free.Count -lt 3) { Set-ItResult -Skipped -Because 'Fewer than 3 unstacked candidate assets'; return }
            $Stack = & $script:NewTestStack -AssetIds $Free[0], $Free[1], $Free[2]
            $Stack.assets.id | Should -Contain $Free[1]
            $Stack.assets.id | Should -Contain $Free[2]
            $Stack.assets | Should -HaveCount 3
        }

        It 'Throws for a malformed asset ID' {
            { New-IMStack -AssetIds 'not-a-guid', 'also-not-a-guid' } | Should -Throw
        }
    }

    Context 'Get-IMStack' -Tag 'Get-IMStack' {
        BeforeAll {
            $script:Free = & $script:GetFreeAssets
            if ($script:Free.Count -ge 2)
            {
                $script:Stack = & $script:NewTestStack -AssetIds $script:Free[0], $script:Free[1]
            }
        }

        It 'Lists stacks including the test stack' {
            if (-not $script:Stack) { Set-ItResult -Skipped -Because 'No test stack could be created'; return }
            $Result = @(Get-IMStack)
            $Result.id | Should -Contain $script:Stack.id
        }

        It 'Returns StackResponseDto for a stack ID' {
            if (-not $script:Stack) { Set-ItResult -Skipped -Because 'No test stack could be created'; return }
            $Result = Get-IMStack -Id $script:Stack.id
            $Result.GetType().Name | Should -Be 'StackResponseDto'
            $Result.id | Should -Be $script:Stack.id
            $Result.assets | Should -HaveCount 2
        }

        It 'Accepts a stack ID string from the pipeline' {
            if (-not $script:Stack) { Set-ItResult -Skipped -Because 'No test stack could be created'; return }
            $Result = $script:Stack.id | Get-IMStack
            $Result.id | Should -Be $script:Stack.id
        }

        It 'Accepts objects with an id property from the pipeline' {
            if (-not $script:Stack) { Set-ItResult -Skipped -Because 'No test stack could be created'; return }
            $Result = [pscustomobject]@{ id = $script:Stack.id } | Get-IMStack
            $Result.id | Should -Be $script:Stack.id
        }

        It 'Filters stacks by primary asset ID' {
            if (-not $script:Stack) { Set-ItResult -Skipped -Because 'No test stack could be created'; return }
            $Result = @(Get-IMStack -PrimaryAssetId $script:Free[0])
            $Result.id | Should -Contain $script:Stack.id
        }

        It 'Does not return the stack for a non-primary asset filter' {
            if (-not $script:Stack) { Set-ItResult -Skipped -Because 'No test stack could be created'; return }
            $Result = @(Get-IMStack -PrimaryAssetId $script:Free[1])
            $Result.id | Should -Not -Contain $script:Stack.id
        }

        It 'Throws for a malformed stack ID' {
            { Get-IMStack -Id 'not-a-guid' } | Should -Throw
        }
    }

    Context 'Set-IMStack' -Tag 'Set-IMStack' {
        It 'Changes the primary asset of a stack' {
            $Free = & $script:GetFreeAssets
            if ($Free.Count -lt 2) { Set-ItResult -Skipped -Because 'Fewer than 2 unstacked candidate assets'; return }
            $Stack = & $script:NewTestStack -AssetIds $Free[0], $Free[1]
            Set-IMStack -Id $Stack.id -PrimaryAssetId $Free[1]
            (Get-IMStack -Id $Stack.id).primaryAssetId | Should -Be $Free[1]
        }

        It 'Accepts a stack from the pipeline' {
            $Free = & $script:GetFreeAssets
            if ($Free.Count -lt 2) { Set-ItResult -Skipped -Because 'Fewer than 2 unstacked candidate assets'; return }
            $Stack = & $script:NewTestStack -AssetIds $Free[0], $Free[1]
            $Stack | Set-IMStack -PrimaryAssetId $Free[1]
            (Get-IMStack -Id $Stack.id).primaryAssetId | Should -Be $Free[1]
        }

        It 'Throws for a malformed primary asset ID' {
            { Set-IMStack -Id 'not-a-guid' -PrimaryAssetId 'not-a-guid' } | Should -Throw
        }
    }

    Context 'Remove-IMStackAsset' -Tag 'Remove-IMStackAsset' {
        It 'Removes one asset from a three-asset stack' {
            $Free = & $script:GetFreeAssets
            if ($Free.Count -lt 3) { Set-ItResult -Skipped -Because 'Fewer than 3 unstacked candidate assets'; return }
            $Stack = & $script:NewTestStack -AssetIds $Free[0], $Free[1], $Free[2]
            Remove-IMStackAsset -StackId $Stack.id -AssetId $Free[2] -Force
            $Result = Get-IMStack -Id $Stack.id
            $Result.assets | Should -HaveCount 2
            $Result.assets.id | Should -Not -Contain $Free[2]
        }

        It 'Accepts stack and asset IDs from a pipeline object' {
            $Free = & $script:GetFreeAssets
            if ($Free.Count -lt 3) { Set-ItResult -Skipped -Because 'Fewer than 3 unstacked candidate assets'; return }
            $Stack = & $script:NewTestStack -AssetIds $Free[0], $Free[1], $Free[2]
            [pscustomobject]@{ StackId = $Stack.id; AssetId = $Free[2] } | Remove-IMStackAsset -Force
            (Get-IMStack -Id $Stack.id).assets.id | Should -Not -Contain $Free[2]
        }

        It 'Does not remove the asset with -WhatIf' {
            $Free = & $script:GetFreeAssets
            if ($Free.Count -lt 3) { Set-ItResult -Skipped -Because 'Fewer than 3 unstacked candidate assets'; return }
            $Stack = & $script:NewTestStack -AssetIds $Free[0], $Free[1], $Free[2]
            Remove-IMStackAsset -StackId $Stack.id -AssetId $Free[2] -Force -WhatIf
            (Get-IMStack -Id $Stack.id).assets.id | Should -Contain $Free[2]
        }

        It 'Throws for a malformed stack ID' {
            { Remove-IMStackAsset -StackId 'not-a-guid' -AssetId 'not-a-guid' -Force } | Should -Throw
        }
    }

    Context 'Remove-IMStack' -Tag 'Remove-IMStack' {
        It 'Removes a stack by ID' {
            $Free = & $script:GetFreeAssets
            if ($Free.Count -lt 2) { Set-ItResult -Skipped -Because 'Fewer than 2 unstacked candidate assets'; return }
            $Stack = & $script:NewTestStack -AssetIds $Free[0], $Free[1]
            try
            {
                Remove-IMStack -Id $Stack.id -Force -Confirm:$false
                (Get-IMStack).id | Should -Not -Contain $Stack.id
            }
            finally
            {
                $script:CreatedStackIds.Remove($Stack.id) | Out-Null
            }
        }

        It 'Removes a stack from a pipeline object' {
            $Free = & $script:GetFreeAssets
            if ($Free.Count -lt 2) { Set-ItResult -Skipped -Because 'Fewer than 2 unstacked candidate assets'; return }
            $Stack = & $script:NewTestStack -AssetIds $Free[0], $Free[1]
            try
            {
                $Stack | Remove-IMStack -Force -Confirm:$false
                (Get-IMStack).id | Should -Not -Contain $Stack.id
            }
            finally
            {
                $script:CreatedStackIds.Remove($Stack.id) | Out-Null
            }
        }

        It 'Removes multiple stacks in one call' {
            $Free = & $script:GetFreeAssets
            if ($Free.Count -lt 4) { Set-ItResult -Skipped -Because 'Fewer than 4 unstacked candidate assets'; return }
            $First = & $script:NewTestStack -AssetIds $Free[0], $Free[1]
            $Second = & $script:NewTestStack -AssetIds $Free[2], $Free[3]
            try
            {
                Remove-IMStack -Id $First.id, $Second.id -Force -Confirm:$false
                $Ids = (Get-IMStack).id
                $Ids | Should -Not -Contain $First.id
                $Ids | Should -Not -Contain $Second.id
            }
            finally
            {
                $script:CreatedStackIds.Remove($First.id) | Out-Null
                $script:CreatedStackIds.Remove($Second.id) | Out-Null
            }
        }

        It 'Does not remove the stack with -WhatIf' {
            $Free = & $script:GetFreeAssets
            if ($Free.Count -lt 2) { Set-ItResult -Skipped -Because 'Fewer than 2 unstacked candidate assets'; return }
            $Stack = & $script:NewTestStack -AssetIds $Free[0], $Free[1]
            Remove-IMStack -Id $Stack.id -Force -WhatIf
            (Get-IMStack).id | Should -Contain $Stack.id
        }

        It 'Throws for a malformed stack ID' {
            { Remove-IMStack -Id 'not-a-guid' -Force -Confirm:$false } | Should -Throw
        }
    }
}
