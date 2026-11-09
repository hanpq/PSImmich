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

# Intentionally excluded:
# - Get-IMSharedLink | Remove-IMSharedLink: would delete every pre-existing shared link on the shared server.
# - Get-IMSharedLink -Me: returns links of the current user only; the server-wide list is already covered by the list test.
Describe 'SharedLink' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $script:AssetId1 = '6d178c17-71f1-4231-a225-f4ffe55d24a5'
        $script:AssetId2 = '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        $script:AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
        $script:CreatedLinkIds = [System.Collections.Generic.List[string]]::new()
        $script:NewTestLink = {
            param(
                [string]$AssetId = $script:AssetId1,
                [string]$Description = "PSImmich-Test-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
            )
            $Link = New-IMSharedLink -AssetId $AssetId -Description $Description
            $script:CreatedLinkIds.Add($Link.id)
            $Link
        }
    }

    AfterAll {
        # Some tests remove their own link, so skip IDs that no longer exist.
        foreach ($Id in $script:CreatedLinkIds)
        {
            try
            {
                Get-IMSharedLink -Id $Id -ErrorAction Stop | Out-Null
            }
            catch
            {
                continue
            }
            Remove-IMSharedLink -id $Id
        }
    }

    Context 'New-IMSharedLink' -Tag 'New-IMSharedLink' {
        It 'Should create an individual shared link for an asset' {
            $Link = & $script:NewTestLink
            $Link.type | Should -Be 'INDIVIDUAL'
            $Link.assets.id | Should -Contain $script:AssetId1
        }
        It 'Should create an album shared link' {
            $Link = New-IMSharedLink -AlbumId $script:AlbumId -Description 'PSImmich-Test-Album'
            $script:CreatedLinkIds.Add($Link.id)
            $Link.type | Should -Be 'ALBUM'
            $Result = Get-IMSharedLink -Id $Link.id
            $Result.album.id | Should -Be $script:AlbumId
        }
        It 'Should apply description, download, metadata and expiry settings' {
            $Link = New-IMSharedLink -AssetId $script:AssetId1 -Description 'PSImmich-Test-Settings' -AllowDownload -ShowMetadata -ExpiresAt ((Get-Date).AddDays(3))
            $script:CreatedLinkIds.Add($Link.id)
            $Result = Get-IMSharedLink -Id $Link.id
            $Result.description | Should -Be 'PSImmich-Test-Settings'
            $Result.allowDownload | Should -BeTrue
            $Result.showMetadata | Should -BeTrue
            $Result.expiresAt | Should -Not -BeNullOrEmpty
        }
        It 'Should accept asset IDs from the pipeline' {
            $Link = $script:AssetId1 | New-IMSharedLink -Description 'PSImmich-Test-Piped'
            $script:CreatedLinkIds.Add($Link.id)
            $Link.type | Should -Be 'INDIVIDUAL'
        }
        It 'Should return a SharedLinkResponseDto object' {
            $Link = & $script:NewTestLink
            $Link.PSObject.TypeNames | Should -Contain 'SharedLinkResponseDto'
        }
        It 'Should throw for a non-existent asset ID' {
            { New-IMSharedLink -AssetId ([guid]::NewGuid().ToString()) } | Should -Throw
        }
        It 'Should throw for a non-existent album ID' {
            { New-IMSharedLink -AlbumId ([guid]::NewGuid().ToString()) } | Should -Throw
        }
    }

    Context 'Get-IMSharedLink' -Tag 'Get-IMSharedLink' {
        BeforeAll {
            $script:Link = & $script:NewTestLink
        }
        It 'Should list shared links including the test link' {
            $All = Get-IMSharedLink
            $All.id | Should -Contain $script:Link.id
        }
        It 'Should return a single shared link by ID' {
            $Result = Get-IMSharedLink -Id $script:Link.id
            $Result | Should -HaveCount 1
            $Result.id | Should -Be $script:Link.id
        }
        It 'Should accept shared link IDs from the pipeline' {
            $Result = $script:Link.id | Get-IMSharedLink
            $Result.id | Should -Be $script:Link.id
        }
        It 'Should filter shared links by album' {
            $AlbumLink = New-IMSharedLink -AlbumId $script:AlbumId -Description 'PSImmich-Test-AlbumFilter'
            $script:CreatedLinkIds.Add($AlbumLink.id)
            $Result = Get-IMSharedLink -AlbumId $script:AlbumId
            $Result.id | Should -Contain $AlbumLink.id
            $Result | Where-Object { $_.album.id -ne $script:AlbumId } | Should -BeNullOrEmpty
        }
        It 'Should return a SharedLinkResponseDto object' {
            $Result = Get-IMSharedLink -Id $script:Link.id
            $Result.PSObject.TypeNames | Should -Contain 'SharedLinkResponseDto'
        }
        It 'Should throw for a non-existent shared link ID' {
            { Get-IMSharedLink -Id ([guid]::NewGuid().ToString()) } | Should -Throw
        }
    }

    Context 'Set-IMSharedLink' -Tag 'Set-IMSharedLink' {
        BeforeEach {
            $script:Link = & $script:NewTestLink
        }
        It 'Should update the description' {
            Set-IMSharedLink -Id $script:Link.id -Description 'PSImmich-Test-Updated' | Out-Null
            (Get-IMSharedLink -Id $script:Link.id).description | Should -Be 'PSImmich-Test-Updated'
        }
        It 'Should disable downloads' {
            Set-IMSharedLink -Id $script:Link.id -AllowDownload:$false | Out-Null
            (Get-IMSharedLink -Id $script:Link.id).allowDownload | Should -BeFalse
        }
        It 'Should enable uploads' {
            Set-IMSharedLink -Id $script:Link.id -AllowUpload | Out-Null
            (Get-IMSharedLink -Id $script:Link.id).allowUpload | Should -BeTrue
        }
        It 'Should update metadata visibility' {
            Set-IMSharedLink -Id $script:Link.id -ShowMetadata | Out-Null
            (Get-IMSharedLink -Id $script:Link.id).showMetadata | Should -BeTrue
        }
        It 'Should update the expiry date' {
            $Expiry = (Get-Date).AddDays(5)
            Set-IMSharedLink -Id $script:Link.id -ExpiresAt $Expiry | Out-Null
            (Get-IMSharedLink -Id $script:Link.id).expiresAt | Should -Not -BeNullOrEmpty
        }
        It 'Should accept shared link IDs from the pipeline' {
            $script:Link | Set-IMSharedLink -Description 'PSImmich-Test-Piped' | Out-Null
            (Get-IMSharedLink -Id $script:Link.id).description | Should -Be 'PSImmich-Test-Piped'
        }
        It 'Should throw for a non-existent shared link ID' {
            { Set-IMSharedLink -Id ([guid]::NewGuid().ToString()) -Description 'PSImmich-Test-Missing' } | Should -Throw
        }
    }

    Context 'Add-IMSharedLinkAsset' -Tag 'Add-IMSharedLinkAsset' {
        BeforeEach {
            $script:Link = & $script:NewTestLink
        }
        It 'Should add an asset to the shared link' {
            Add-IMSharedLinkAsset -SharedLinkId $script:Link.id -Id $script:AssetId2 | Out-Null
            $Result = Get-IMSharedLink -Id $script:Link.id
            $Result.assets.id | Should -Contain $script:AssetId2
        }
        It 'Should accept asset IDs from the pipeline' {
            $script:AssetId2 | Add-IMSharedLinkAsset -SharedLinkId $script:Link.id | Out-Null
            $Result = Get-IMSharedLink -Id $script:Link.id
            $Result.assets.id | Should -Contain $script:AssetId2
        }
        It 'Should throw for a non-existent shared link ID' {
            { Add-IMSharedLinkAsset -SharedLinkId ([guid]::NewGuid().ToString()) -Id $script:AssetId2 } | Should -Throw
        }
    }

    Context 'Remove-IMSharedLinkAsset' -Tag 'Remove-IMSharedLinkAsset' {
        BeforeEach {
            $script:Link = & $script:NewTestLink
            Add-IMSharedLinkAsset -SharedLinkId $script:Link.id -Id $script:AssetId2 | Out-Null
        }
        It 'Should remove an asset from the test shared link' {
            Remove-IMSharedLinkAsset -SharedLinkId $script:Link.id -Id $script:AssetId2 | Out-Null
            $Result = Get-IMSharedLink -Id $script:Link.id
            $Result.assets.id | Should -Not -Contain $script:AssetId2
            $Result.assets.id | Should -Contain $script:AssetId1
        }
        It 'Should accept asset IDs from the pipeline' {
            $script:AssetId2 | Remove-IMSharedLinkAsset -SharedLinkId $script:Link.id | Out-Null
            $Result = Get-IMSharedLink -Id $script:Link.id
            $Result.assets.id | Should -Not -Contain $script:AssetId2
        }
        It 'Should throw for a non-existent shared link ID' {
            { Remove-IMSharedLinkAsset -SharedLinkId ([guid]::NewGuid().ToString()) -Id $script:AssetId2 } | Should -Throw
        }
    }

    Context 'Remove-IMSharedLink' -Tag 'Remove-IMSharedLink' {
        It 'Should remove a shared link by ID' {
            $Link = & $script:NewTestLink
            Remove-IMSharedLink -id $Link.id
            { Get-IMSharedLink -Id $Link.id } | Should -Throw
        }
        It 'Should remove a shared link from the pipeline' {
            $Link = & $script:NewTestLink
            $Link | Remove-IMSharedLink
            { Get-IMSharedLink -Id $Link.id } | Should -Throw
        }
        It 'Should throw for a non-existent shared link ID' {
            { Remove-IMSharedLink -id ([guid]::NewGuid().ToString()) } | Should -Throw
        }
    }
}
