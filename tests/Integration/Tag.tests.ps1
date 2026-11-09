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

Describe 'Tag' -Tag 'Integration' {
    # Intentionally excluded cmdlets: none.
    # Tags are only created by these tests. Pre-existing tags (including any named 'TestTag') are never modified or deleted.
    # Pre-existing assets are only tagged with test-created tags, and those tags are removed in finally blocks.

    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $script:AssetA = 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'
        $script:AssetB = 'bdc6d2c8-6168-4a88-a51f-6da11bf8f506'
        $script:CreatedTagIds = [System.Collections.Generic.List[string]]::new()
        $script:NewTestTag = {
            $Name = "PSImmich-IT-$($env:GITHUB_RUN_ID)-$(Get-Random)"
            $Tag = New-IMTag -Name $Name
            $script:CreatedTagIds.Add($Tag.id)
            $Tag
        }
    }

    AfterAll {
        foreach ($Id in $script:CreatedTagIds)
        {
            try
            {
                Remove-IMTag -id $Id -Confirm:$false
            }
            catch
            {
                $null = $_
            }
        }
    }

    Context 'New-IMTag' -Tag 'New-IMTag' {
        It 'Creates a tag and returns the created tag object' {
            $Name = "PSImmich-IT-$($env:GITHUB_RUN_ID)-$(Get-Random)"
            $Tag = New-IMTag -Name $Name
            $script:CreatedTagIds.Add($Tag.id)
            $Tag.GetType().Name | Should -Be 'PSCustomObject'
            $Tag.name | Should -Be $Name
            $Tag.id | Should -Match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        }

        It 'Creates a tag that appears in Get-IMTag' {
            $Tag = & $script:NewTestTag
            (Get-IMTag).id | Should -Contain $Tag.id
        }

        It 'Creates a tag whose name is retained exactly' {
            $Name = "PSImmich-IT-Case-$($env:GITHUB_RUN_ID)-$(Get-Random)"
            $Tag = New-IMTag -Name $Name
            $script:CreatedTagIds.Add($Tag.id)
            (Get-IMTag -id $Tag.id).name | Should -BeExactly $Name
        }
    }

    Context 'Get-IMTag' -Tag 'Get-IMTag' {
        BeforeAll {
            $script:Tag = & $script:NewTestTag
        }

        It 'Lists tags including the test tag' {
            $Result = @(Get-IMTag)
            $Result.id | Should -Contain $script:Tag.id
        }

        It 'Returns TagResponseDto for a tag ID' {
            $Result = Get-IMTag -id $script:Tag.id
            $Result.GetType().Name | Should -Be 'PSCustomObject'
            $Result.id | Should -Be $script:Tag.id
            $Result.name | Should -Be $script:Tag.name
        }

        It 'Returns a color property for a tag once a color is set' {
            Set-IMTag -Id $script:Tag.id -Color '#0000FF'
            $Result = Get-IMTag -id $script:Tag.id
            $Result.PSObject.Properties.Name | Should -Contain 'color'
            $Result.color | Should -Match '0000FF'
        }

        It 'Accepts a tag ID string from the pipeline' {
            $Result = $script:Tag.id | Get-IMTag
            $Result.id | Should -Be $script:Tag.id
        }

        It 'Accepts objects with an id property from the pipeline' {
            $Result = [pscustomobject]@{ id = $script:Tag.id } | Get-IMTag
            $Result.name | Should -Be $script:Tag.name
        }

        It 'Returns multiple tags for several IDs' {
            $Second = & $script:NewTestTag
            $Result = @(Get-IMTag -id $script:Tag.id, $Second.id)
            $Result | Should -HaveCount 2
            $Result.id | Should -Contain $Second.id
        }

        It 'Throws for an unknown tag ID' {
            { Get-IMTag -id '00000000-0000-0000-0000-000000000000' } | Should -Throw
        }

        It 'Throws for a malformed tag ID' {
            { Get-IMTag -id 'not-a-guid' } | Should -Throw
        }
    }

    Context 'Set-IMTag' -Tag 'Set-IMTag' {
        It 'Updates the color of a tag by ID' {
            $Tag = & $script:NewTestTag
            Set-IMTag -Id $Tag.id -Color '#0000FF'
            (Get-IMTag -id $Tag.id).color | Should -Match '0000FF'
        }

        It 'Updates the color of a tag from the pipeline' {
            $Tag = & $script:NewTestTag
            $Tag | Set-IMTag -Color '#FF0000'
            (Get-IMTag -id $Tag.id).color | Should -Match 'FF0000'
        }

        It 'Updates the color of a tag selected by name' {
            $Tag = & $script:NewTestTag
            Set-IMTag -tagName $Tag.name -Color '#00FF00'
            (Get-IMTag -id $Tag.id).color | Should -Match '00FF00'
        }

        It 'Throws when the tag name does not exist' {
            { Set-IMTag -tagName "PSImmich-IT-missing-$(Get-Random)" -Color '#0000FF' } | Should -Throw
        }

        It 'Tags an asset with a test-created tag and removes it in finally' {
            $Tag = & $script:NewTestTag
            try
            {
                Set-IMTag -Id $Tag.id -AddAssets $script:AssetA
                $Asset = Get-IMAsset -id $script:AssetA
                $Asset.tags.id | Should -Contain $Tag.id
            }
            finally
            {
                Set-IMTag -Id $Tag.id -RemoveAssets $script:AssetA
            }
        }

        It 'Tags multiple assets with a test-created tag and removes them in finally' {
            $Tag = & $script:NewTestTag
            try
            {
                Set-IMTag -Id $Tag.id -AddAssets $script:AssetA, $script:AssetB
                $Assets = @(foreach ($AssetId in $script:AssetA, $script:AssetB) { Get-IMAsset -id $AssetId })
                $Assets | Should -HaveCount 2
                foreach ($Asset in $Assets)
                {
                    $Asset.tags.id | Should -Contain $Tag.id
                }
            }
            finally
            {
                Set-IMTag -Id $Tag.id -RemoveAssets $script:AssetA, $script:AssetB
            }
        }

        It 'Removes a tag from an asset' {
            $Tag = & $script:NewTestTag
            try
            {
                Set-IMTag -Id $Tag.id -AddAssets $script:AssetA
                Set-IMTag -Id $Tag.id -RemoveAssets $script:AssetA
                $Asset = Get-IMAsset -id $script:AssetA
                $Asset.tags.id | Should -Not -Contain $Tag.id
            }
            finally
            {
                Set-IMTag -Id $Tag.id -RemoveAssets $script:AssetA
            }
        }

        It 'Does not change the color with -WhatIf' {
            $Tag = & $script:NewTestTag
            Set-IMTag -Id $Tag.id -Color '#800080'
            Set-IMTag -Id $Tag.id -Color '#FFA500' -WhatIf
            (Get-IMTag -id $Tag.id).color | Should -Match '800080'
        }

        It 'Throws for a malformed tag ID' {
            { Set-IMTag -Id 'not-a-guid' -Color '#0000FF' } | Should -Throw
        }
    }

    Context 'Remove-IMTag' -Tag 'Remove-IMTag' {
        It 'Removes a tag by ID' {
            $Tag = & $script:NewTestTag
            Remove-IMTag -id $Tag.id -Confirm:$false
            { Get-IMTag -id $Tag.id } | Should -Throw
            $script:CreatedTagIds.Remove($Tag.id) | Out-Null
        }

        It 'Removes a tag from a pipeline object' {
            $Tag = & $script:NewTestTag
            $Tag | Remove-IMTag -Confirm:$false
            { Get-IMTag -id $Tag.id } | Should -Throw
            $script:CreatedTagIds.Remove($Tag.id) | Out-Null
        }

        It 'Removes multiple tags in one call' {
            $First = & $script:NewTestTag
            $Second = & $script:NewTestTag
            Remove-IMTag -id $First.id, $Second.id -Confirm:$false
            { Get-IMTag -id $First.id } | Should -Throw
            { Get-IMTag -id $Second.id } | Should -Throw
            $script:CreatedTagIds.Remove($First.id) | Out-Null
            $script:CreatedTagIds.Remove($Second.id) | Out-Null
        }

        It 'Does not remove the tag with -WhatIf' {
            $Tag = & $script:NewTestTag
            Remove-IMTag -id $Tag.id -WhatIf
            (Get-IMTag -id $Tag.id).id | Should -Be $Tag.id
        }

        It 'Throws for a malformed tag ID' {
            { Remove-IMTag -id 'not-a-guid' -Confirm:$false } | Should -Throw
        }
    }
}
