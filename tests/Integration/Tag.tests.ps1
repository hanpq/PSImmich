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
    # Asset tagging tests use uniquely uploaded disposable assets and test-created tags.

    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        . (Join-Path $PSScriptRoot 'Support\Wait-TestAssetTagState.ps1')
        $script:CreatedTagIds = [System.Collections.Generic.List[string]]::new()
        $script:CreatedAssetIds = [System.Collections.Generic.List[string]]::new()
        $script:TempAssetFiles = [System.Collections.Generic.List[string]]::new()
        $script:NewTestTag = {
            $Name = "PSImmich-IT-$($env:GITHUB_RUN_ID)-$(Get-Random)"
            $Tag = New-IMTag -Name $Name
            $script:CreatedTagIds.Add($Tag.id)
            $Tag
        }
        function New-TestTagAsset
        {
            $Path = Join-Path ([System.IO.Path]::GetTempPath()) "psimmich-tag-$([guid]::NewGuid().ToString('N')).png"
            $script:TempAssetFiles.Add($Path)
            $Image = [System.IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'Immich.png'))
            $Marker = [System.Text.Encoding]::ASCII.GetBytes("psimmich-tag:$([guid]::NewGuid().ToString('N'))")
            [System.IO.File]::WriteAllBytes($Path, [byte[]]($Image + $Marker))
            $File = Get-Item -LiteralPath $Path
            $FormData = @{
                deviceAssetId = $File.Name
                deviceId = 'PSImmich'
                fileCreatedAt = ([DateTimeOffset]$File.CreationTime).UtcDateTime.ToString('o')
                fileModifiedAt = ([DateTimeOffset]$File.LastWriteTime).UtcDateTime.ToString('o')
            }
            $Upload = & (Get-Module PSImmich) {
                param($File, $FormData)
                Invoke-ImmichApiUploadAsset -FileInfo $File -FormData $FormData
            } $File $FormData
            if ($Upload.status -ne 'created' -or [string]::IsNullOrWhiteSpace($Upload.id))
            {
                throw "Disposable asset upload did not create an asset (status: '$($Upload.status)', id: '$($Upload.id)')."
            }
            $script:CreatedAssetIds.Add($Upload.id)
            $Upload.id
        }
        function Assert-TestTagResult
        {
            param($Result, [string[]]$AssetIds)
            $Entries = @($Result)
            $Entries.Count | Should -Be $AssetIds.Count
            foreach ($AssetId in $AssetIds)
            {
                $Entry = @($Entries | Where-Object { $_.id -eq $AssetId })
                $Entry.Count | Should -Be 1
                $Entry[0].success | Should -BeTrue -Because "tag operation for asset '$AssetId' failed: $($Entry[0].error) $($Entry[0].errorMessage)"
            }
        }
    }

    AfterAll {
        $CleanupErrors = [System.Collections.Generic.List[string]]::new()
        foreach ($Id in $script:CreatedTagIds)
        {
            try
            {
                Remove-IMTag -id $Id -Confirm:$false -ErrorAction Stop
            }
            catch
            {
                $CleanupErrors.Add("Tag '$Id': $($_.Exception.Message)")
            }
        }
        foreach ($Id in $script:CreatedAssetIds)
        {
            try { Remove-IMAsset -Ids $Id -Force -Confirm:$false -ErrorAction Stop }
            catch { $CleanupErrors.Add("Asset '$Id': $($_.Exception.Message)") }
        }
        foreach ($Path in $script:TempAssetFiles)
        {
            try { Remove-Item -LiteralPath $Path -Force -ErrorAction Stop }
            catch { $CleanupErrors.Add("File '$Path': $($_.Exception.Message)") }
        }
        if ($CleanupErrors.Count -gt 0)
        {
            throw "Test cleanup failed: $($CleanupErrors -join '; ')"
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

        It 'Tags a disposable asset with a test-created tag' {
            $Tag = & $script:NewTestTag
            $AssetId = New-TestTagAsset
            $Result = Set-IMTag -Id $Tag.id -AddAssets $AssetId
            Assert-TestTagResult -Result $Result -AssetIds $AssetId
            Wait-TestAssetTagState -AssetId $AssetId -TagId $Tag.id -Present $true
        }

        It 'Tags multiple disposable assets with a test-created tag' {
            $Tag = & $script:NewTestTag
            $AssetIds = @(New-TestTagAsset; New-TestTagAsset)
            $Result = Set-IMTag -Id $Tag.id -AddAssets $AssetIds
            Assert-TestTagResult -Result $Result -AssetIds $AssetIds
            foreach ($AssetId in $AssetIds)
            {
                Wait-TestAssetTagState -AssetId $AssetId -TagId $Tag.id -Present $true
            }
        }

        It 'Removes a tag from an asset' {
            $Tag = & $script:NewTestTag
            $AssetId = New-TestTagAsset
            $Result = Set-IMTag -Id $Tag.id -AddAssets $AssetId
            Assert-TestTagResult -Result $Result -AssetIds $AssetId
            Wait-TestAssetTagState -AssetId $AssetId -TagId $Tag.id -Present $true
            $Result = Set-IMTag -Id $Tag.id -RemoveAssets $AssetId
            Assert-TestTagResult -Result $Result -AssetIds $AssetId
            Wait-TestAssetTagState -AssetId $AssetId -TagId $Tag.id -Present $false
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
