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

Describe 'Album' -Tag 'Integration' {
    # Intentionally excluded cmdlets: none. Get-IMAlbumMapMarker -Key and -Slug are not covered because they need a shared link on the shared live server.

    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $script:SharedUserId = '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
        $script:AssetA = 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
        $script:AssetB = '025665c6-d874-46a2-bbc6-37250ddcb2eb'
        $script:AssetC = '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        $script:CreatedAlbumIds = [System.Collections.Generic.List[string]]::new()
        $script:NewTestAlbum = {
            param([hashtable]$Parameters = @{})
            $Name = "PSImmich-IT-$($env:GITHUB_RUN_ID)-$(Get-Random)"
            $Album = New-IMAlbum -AlbumName $Name @Parameters
            $script:CreatedAlbumIds.Add($Album.id)
            $Album
        }
    }

    AfterAll {
        foreach ($Id in $script:CreatedAlbumIds)
        {
            try
            {
                Remove-IMAlbum -AlbumId $Id -Confirm:$false
            }
            catch
            {
                # Album was already removed by the test that created it.
                $null = $_
            }
        }
    }

    Context 'Get-IMAlbumStatistic' -Tag 'Get-IMAlbumStatistic' {
        It 'Returns AlbumStatisticsResponseDto with numeric counts' {
            $Result = Get-IMAlbumStatistic
            $Result.GetType().Name | Should -Be 'AlbumStatisticsResponseDto'
            $Result.owned | Should -BeGreaterOrEqual 0
            $Result.shared | Should -BeGreaterOrEqual 0
            $Result.notShared | Should -BeGreaterOrEqual 0
        }

        It 'Owned count increases when an album is created' {
            $Before = (Get-IMAlbumStatistic).owned
            $null = & $script:NewTestAlbum
            (Get-IMAlbumStatistic).owned | Should -BeGreaterOrEqual ($Before + 1)
        }

        It 'Shared count increases when an album is shared' {
            $Album = & $script:NewTestAlbum
            $Before = (Get-IMAlbumStatistic).shared
            try
            {
                Add-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId
                (Get-IMAlbumStatistic).shared | Should -BeGreaterOrEqual ($Before + 1)
            }
            finally
            {
                Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
            }
        }
    }

    Context 'Get-IMAlbum' -Tag 'Get-IMAlbum' {
        BeforeAll {
            $script:Album = & $script:NewTestAlbum -Parameters @{ AssetIds = @($script:AssetA); Description = 'Get-IMAlbum test' }
        }

        It 'Lists albums including the test album' {
            $Result = Get-IMAlbum | Where-Object { $_.id -eq $script:Album.id }
            $Result | Should -HaveCount 1
        }

        It 'Returns AlbumResponseDto for an album ID' {
            $Result = Get-IMAlbum -AlbumId $script:Album.id
            $Result.GetType().Name | Should -Be 'AlbumResponseDto'
            $Result.id | Should -Be $script:Album.id
        }

        It 'Filters by exact name' {
            $Result = Get-IMAlbum -Name $script:Album.albumName
            $Result | Should -HaveCount 1
            $Result.id | Should -Be $script:Album.id
        }

        It 'Returns nothing for an exact name that does not exist' {
            $Result = Get-IMAlbum -Name "PSImmich-IT-missing-$(Get-Random)"
            $Result | Should -BeNullOrEmpty
        }

        It 'Filters by wildcard search string' {
            $Result = Get-IMAlbum -SearchString "$($script:Album.albumName)*"
            $Result.id | Should -Contain $script:Album.id
        }

        It 'Returns nothing for a search string that does not match' {
            $Result = Get-IMAlbum -SearchString "PSImmich-IT-nomatch-$(Get-Random)*"
            $Result | Should -BeNullOrEmpty
        }

        It 'Includes an unshared album and excludes a shared album when Shared is false' {
            $Album = & $script:NewTestAlbum
            try
            {
                Add-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId
                $Unshared = Get-IMAlbum -Shared:$false | Where-Object { $_.id -eq $script:Album.id }
                $Unshared | Should -HaveCount 1
                $Shared = Get-IMAlbum -Shared:$false | Where-Object { $_.id -eq $Album.id }
                $Shared | Should -BeNullOrEmpty
            }
            finally
            {
                Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
            }
        }

        It 'Includes a shared album when Shared is true' {
            $Album = & $script:NewTestAlbum
            try
            {
                Add-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId
                $Result = Get-IMAlbum -Shared:$true | Where-Object { $_.id -eq $Album.id }
                $Result | Should -HaveCount 1
            }
            finally
            {
                Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
            }
        }

        It 'Returns albums containing a given asset' {
            $Result = Get-IMAlbum -AssetId $script:AssetA
            $Result.id | Should -Contain $script:Album.id
        }

        It 'Does not return the album for an asset it does not contain' {
            $Result = Get-IMAlbum -AssetId $script:AssetC
            $Result.id | Should -Not -Contain $script:Album.id
        }

        It 'Omits assets by default' {
            $Result = Get-IMAlbum -AlbumId $script:Album.id
            $Result.assets | Should -BeNullOrEmpty
        }

        It 'Includes assets for an album ID with -IncludeAssets' {
            $Result = Get-IMAlbum -AlbumId $script:Album.id -IncludeAssets
            $Result.assets | Should -HaveCount 1
            $Result.assets.id | Should -Contain $script:AssetA
        }

        It 'Includes assets for list results with -IncludeAssets' {
            $Result = Get-IMAlbum -Name $script:Album.albumName -IncludeAssets
            $Result | Should -HaveCount 1
            $Result.assets.id | Should -Contain $script:AssetA
        }

        It 'Accepts an album ID string from the pipeline' {
            $Result = $script:Album.id | Get-IMAlbum | Where-Object { $_.id -eq $script:Album.id }
            $Result | Should -HaveCount 1
        }

        It 'Accepts an array of album ID strings from the pipeline' {
            $Result = @($script:Album.id, $script:Album.id) | Get-IMAlbum | Where-Object { $_.id -eq $script:Album.id }
            $Result | Should -HaveCount 2
        }

        It 'Accepts objects with an albumId property from the pipeline' {
            $Result = [pscustomobject]@{ albumId = $script:Album.id } | Get-IMAlbum
            $Result.id | Should -Be $script:Album.id
        }

        It 'Accepts objects with an id property from the pipeline' {
            $Result = [pscustomobject]@{ id = $script:Album.id } | Get-IMAlbum
            $Result.id | Should -Be $script:Album.id
        }

        It 'Throws for a malformed album ID' {
            { Get-IMAlbum -AlbumId 'not-a-guid' } | Should -Throw
        }

        It 'Throws for an unknown album ID' {
            { Get-IMAlbum -AlbumId '00000000-0000-0000-0000-000000000000' } | Should -Throw
        }
    }

    Context 'New-IMAlbum' -Tag 'New-IMAlbum' {
        It 'Creates an album with the given name and description' {
            $Name = "PSImmich-IT-$($env:GITHUB_RUN_ID)-$(Get-Random)"
            $Album = New-IMAlbum -AlbumName $Name -Description 'New-IMAlbum test'
            $script:CreatedAlbumIds.Add($Album.id)
            $Result = Get-IMAlbum -AlbumId $Album.id
            $Result.albumName | Should -Be $Name
            $Result.description | Should -Be 'New-IMAlbum test'
        }

        It 'Creates an empty album when no assets are given' {
            $Album = & $script:NewTestAlbum
            (Get-IMAlbum -AlbumId $Album.id).assetCount | Should -Be 0
        }

        It 'Adds a single initial asset' {
            $Album = & $script:NewTestAlbum -Parameters @{ AssetIds = @($script:AssetA) }
            $Result = Get-IMAlbum -AlbumId $Album.id -IncludeAssets
            $Result.assetCount | Should -Be 1
            $Result.assets | Should -HaveCount 1
        }

        It 'Adds multiple initial assets' {
            $Album = & $script:NewTestAlbum -Parameters @{ AssetIds = @($script:AssetA, $script:AssetB) }
            $Result = Get-IMAlbum -AlbumId $Album.id -IncludeAssets
            $Result.assets | Should -HaveCount 2
            $Result.assets.id | Should -Contain $script:AssetB
        }

        It 'Returns AlbumResponseDto' {
            $Album = & $script:NewTestAlbum
            $Album.GetType().Name | Should -Be 'AlbumResponseDto'
        }

        It 'Shares the album with users given in AlbumUsers' {
            $Album = & $script:NewTestAlbum -Parameters @{ AlbumUsers = @(@{ userId = $script:SharedUserId; role = 'editor' }) }
            try
            {
                $Result = Get-IMAlbum -AlbumId $Album.id
                $SharedUser = $Result.albumUsers | Where-Object { $_.user.id -eq $script:SharedUserId }
                $SharedUser.role | Should -Be 'editor'
            }
            finally
            {
                Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
            }
        }

        It 'Throws for a malformed asset ID' {
            { New-IMAlbum -AlbumName 'PSImmich-IT-invalid' -AssetIds 'not-a-guid' } | Should -Throw
        }
    }

    Context 'Set-IMAlbum' -Tag 'Set-IMAlbum' {
        It 'Adds assets to the album' {
            $Album = & $script:NewTestAlbum
            Set-IMAlbum -Id $Album.id -AddAssets $script:AssetB, $script:AssetC
            $Result = Get-IMAlbum -AlbumId $Album.id -IncludeAssets
            $Result.assets | Should -HaveCount 2
            $Result.assets.id | Should -Contain $script:AssetB
            $Result.assets.id | Should -Contain $script:AssetC
        }

        It 'Removes assets from the album' {
            $Album = & $script:NewTestAlbum -Parameters @{ AssetIds = @($script:AssetB, $script:AssetC) }
            Set-IMAlbum -Id $Album.id -RemoveAssets $script:AssetB, $script:AssetC
            $Result = Get-IMAlbum -AlbumId $Album.id -IncludeAssets
            $Result.assets | Should -BeNullOrEmpty
        }

        It 'Updates the description' {
            $Album = & $script:NewTestAlbum -Parameters @{ Description = 'before' }
            Set-IMAlbum -Id $Album.id -Description 'after'
            (Get-IMAlbum -AlbumId $Album.id).description | Should -Be 'after'
        }

        It 'Updates the album name' {
            $Album = & $script:NewTestAlbum
            $NewName = "PSImmich-IT-renamed-$(Get-Random)"
            Set-IMAlbum -Id $Album.id -AlbumName $NewName
            (Get-IMAlbum -AlbumId $Album.id).albumName | Should -Be $NewName
        }

        It 'Sets the album thumbnail to an asset in the album' {
            $Album = & $script:NewTestAlbum -Parameters @{ AssetIds = @($script:AssetA) }
            Set-IMAlbum -Id $Album.id -AlbumThumbnailAssetId $script:AssetA
            (Get-IMAlbum -AlbumId $Album.id).albumThumbnailAssetId | Should -Be $script:AssetA
        }

        It 'Disables and re-enables the activity feed' {
            $Album = & $script:NewTestAlbum
            Set-IMAlbum -Id $Album.id -IsActivityEnabled:$false
            (Get-IMAlbum -AlbumId $Album.id).isActivityEnabled | Should -BeFalse
            Set-IMAlbum -Id $Album.id -IsActivityEnabled:$true
            (Get-IMAlbum -AlbumId $Album.id).isActivityEnabled | Should -BeTrue
        }

        It 'Sets the asset sort order' {
            $Album = & $script:NewTestAlbum
            Set-IMAlbum -Id $Album.id -Order desc
            (Get-IMAlbum -AlbumId $Album.id).order | Should -Be 'desc'
            Set-IMAlbum -Id $Album.id -Order asc
            (Get-IMAlbum -AlbumId $Album.id).order | Should -Be 'asc'
        }

        It 'Updates multiple albums in one call' {
            $First = & $script:NewTestAlbum
            $Second = & $script:NewTestAlbum
            Set-IMAlbum -Id $First.id, $Second.id -Description 'multi'
            (Get-IMAlbum -AlbumId $First.id).description | Should -Be 'multi'
            (Get-IMAlbum -AlbumId $Second.id).description | Should -Be 'multi'
        }

        It 'Accepts album objects from the pipeline' {
            $Album = & $script:NewTestAlbum
            $Album | Set-IMAlbum -Description 'piped'
            (Get-IMAlbum -AlbumId $Album.id).description | Should -Be 'piped'
        }

        It 'Does not change the album with -WhatIf' {
            $Album = & $script:NewTestAlbum -Parameters @{ Description = 'original' }
            Set-IMAlbum -Id $Album.id -Description 'whatif' -WhatIf
            (Get-IMAlbum -AlbumId $Album.id).description | Should -Be 'original'
        }

        It 'Throws for a malformed album ID' {
            { Set-IMAlbum -Id 'not-a-guid' -Description 'x' } | Should -Throw
        }
    }

    Context 'Rename-IMAlbum' -Tag 'Rename-IMAlbum' {
        It 'Renames an album by ID' {
            $Album = & $script:NewTestAlbum
            $NewName = "PSImmich-IT-renamed-$(Get-Random)"
            Rename-IMAlbum -Id $Album.id -NewName $NewName
            (Get-IMAlbum -AlbumId $Album.id).albumName | Should -Be $NewName
        }

        It 'Renames an album from a pipeline object' {
            $Album = & $script:NewTestAlbum
            $NewName = "PSImmich-IT-piped-$(Get-Random)"
            $Album | Rename-IMAlbum -NewName $NewName
            (Get-IMAlbum -AlbumId $Album.id).albumName | Should -Be $NewName
        }

        It 'Does not rename the album with -WhatIf' {
            $Album = & $script:NewTestAlbum
            $OriginalName = $Album.albumName
            Rename-IMAlbum -Id $Album.id -NewName "PSImmich-IT-whatif-$(Get-Random)" -WhatIf
            (Get-IMAlbum -AlbumId $Album.id).albumName | Should -Be $OriginalName
        }

        It 'Throws for a malformed album ID' {
            { Rename-IMAlbum -Id 'not-a-guid' -NewName 'x' } | Should -Throw
        }
    }

    Context 'Add-IMAlbumUser' -Tag 'Add-IMAlbumUser' {
        It 'Adds a user as viewer by default' {
            $Album = & $script:NewTestAlbum
            try
            {
                Add-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId
                $SharedUser = (Get-IMAlbum -AlbumId $Album.id).albumUsers | Where-Object { $_.user.id -eq $script:SharedUserId }
                $SharedUser | Should -HaveCount 1
                $SharedUser.role | Should -Be 'viewer'
            }
            finally
            {
                Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
            }
        }

        It 'Adds a user with the editor role' {
            $Album = & $script:NewTestAlbum
            try
            {
                Add-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Role editor
                $SharedUser = (Get-IMAlbum -AlbumId $Album.id).albumUsers | Where-Object { $_.user.id -eq $script:SharedUserId }
                $SharedUser.role | Should -Be 'editor'
            }
            finally
            {
                Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
            }
        }

        It 'Adds a user ID from the pipeline' {
            $Album = & $script:NewTestAlbum
            try
            {
                $script:SharedUserId | Add-IMAlbumUser -AlbumId $Album.id -Role viewer
                (Get-IMAlbum -AlbumId $Album.id).albumUsers.user.id | Should -Contain $script:SharedUserId
            }
            finally
            {
                Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
            }
        }

        It 'Throws for an invalid role' {
            $Album = & $script:NewTestAlbum
            { Add-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Role owner } | Should -Throw
        }

        It 'Throws for a malformed user ID' {
            $Album = & $script:NewTestAlbum
            { Add-IMAlbumUser -AlbumId $Album.id -UserId 'not-a-guid' } | Should -Throw
        }
    }

    Context 'Set-IMAlbumUser' -Tag 'Set-IMAlbumUser' {
        It 'Changes a user role from viewer to editor' {
            $Album = & $script:NewTestAlbum
            try
            {
                Add-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Role viewer
                Set-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Role editor
                $SharedUser = (Get-IMAlbum -AlbumId $Album.id).albumUsers | Where-Object { $_.user.id -eq $script:SharedUserId }
                $SharedUser.role | Should -Be 'editor'
            }
            finally
            {
                Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
            }
        }

        It 'Changes a user role from editor to viewer' {
            $Album = & $script:NewTestAlbum
            try
            {
                Add-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Role editor
                Set-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Role viewer
                $SharedUser = (Get-IMAlbum -AlbumId $Album.id).albumUsers | Where-Object { $_.user.id -eq $script:SharedUserId }
                $SharedUser.role | Should -Be 'viewer'
            }
            finally
            {
                Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
            }
        }

        It 'Accepts a user ID from the pipeline' {
            $Album = & $script:NewTestAlbum
            try
            {
                Add-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Role viewer
                $script:SharedUserId | Set-IMAlbumUser -AlbumId $Album.id -Role editor
                $SharedUser = (Get-IMAlbum -AlbumId $Album.id).albumUsers | Where-Object { $_.user.id -eq $script:SharedUserId }
                $SharedUser.role | Should -Be 'editor'
            }
            finally
            {
                Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
            }
        }

        It 'Throws for an invalid role' {
            $Album = & $script:NewTestAlbum
            { Set-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Role owner } | Should -Throw
        }
    }

    Context 'Remove-IMAlbumUser' -Tag 'Remove-IMAlbumUser' {
        It 'Removes a user from the album' {
            $Album = & $script:NewTestAlbum
            try
            {
                Add-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId
                (Get-IMAlbum -AlbumId $Album.id).albumUsers.user.id | Should -Contain $script:SharedUserId
                Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
                (Get-IMAlbum -AlbumId $Album.id).albumUsers.user.id | Should -Not -Contain $script:SharedUserId
            }
            finally
            {
                if ((Get-IMAlbum -AlbumId $Album.id).albumUsers.user.id -contains $script:SharedUserId)
                {
                    Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
                }
            }
        }

        It 'Removes a user ID from the pipeline' {
            $Album = & $script:NewTestAlbum
            try
            {
                Add-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId
                $script:SharedUserId | Remove-IMAlbumUser -AlbumId $Album.id -Confirm:$false
                (Get-IMAlbum -AlbumId $Album.id).albumUsers.user.id | Should -Not -Contain $script:SharedUserId
            }
            finally
            {
                if ((Get-IMAlbum -AlbumId $Album.id).albumUsers.user.id -contains $script:SharedUserId)
                {
                    Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
                }
            }
        }

        It 'Does not remove the user with -WhatIf' {
            $Album = & $script:NewTestAlbum
            try
            {
                Add-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId
                Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -WhatIf
                (Get-IMAlbum -AlbumId $Album.id).albumUsers.user.id | Should -Contain $script:SharedUserId
            }
            finally
            {
                Remove-IMAlbumUser -AlbumId $Album.id -UserId $script:SharedUserId -Confirm:$false
            }
        }
    }

    Context 'Remove-IMAlbum' -Tag 'Remove-IMAlbum' {
        It 'Removes an album by ID' {
            $Album = & $script:NewTestAlbum
            Remove-IMAlbum -AlbumId $Album.id -Confirm:$false
            { Get-IMAlbum -AlbumId $Album.id } | Should -Throw
        }

        It 'Removes an album from a pipeline object' {
            $Album = & $script:NewTestAlbum
            $Album | Remove-IMAlbum -Confirm:$false
            { Get-IMAlbum -AlbumId $Album.id } | Should -Throw
        }

        It 'Removes multiple albums in one call' {
            $First = & $script:NewTestAlbum
            $Second = & $script:NewTestAlbum
            Remove-IMAlbum -AlbumId $First.id, $Second.id -Confirm:$false
            { Get-IMAlbum -AlbumId $First.id } | Should -Throw
            { Get-IMAlbum -AlbumId $Second.id } | Should -Throw
        }

        It 'Does not remove the album with -WhatIf' {
            $Album = & $script:NewTestAlbum
            Remove-IMAlbum -AlbumId $Album.id -WhatIf
            (Get-IMAlbum -AlbumId $Album.id).id | Should -Be $Album.id
        }

        It 'Throws for a malformed album ID' {
            { Remove-IMAlbum -AlbumId 'not-a-guid' -Confirm:$false } | Should -Throw
        }
    }

    Context 'Get-IMAlbumMapMarker' -Tag 'Get-IMAlbumMapMarker' {
        It 'Returns no markers for an album without assets' {
            $Album = & $script:NewTestAlbum
            Get-IMAlbumMapMarker -Id $Album.id | Should -BeNullOrEmpty
        }

        It 'Accepts an album from Get-IMAlbum through the pipeline' {
            $Album = & $script:NewTestAlbum
            $Result = Get-IMAlbum -AlbumId $Album.id | Get-IMAlbumMapMarker
            $Result | Should -BeNullOrEmpty
        }

        It 'Returns MapMarkerResponseDto objects with coordinates for album assets' {
            $Album = & $script:NewTestAlbum -Parameters @{ AssetIds = @($script:AssetA, $script:AssetB) }
            $Result = Get-IMAlbumMapMarker -Id $Album.id
            foreach ($Marker in $Result)
            {
                $Marker.GetType().Name | Should -Be 'MapMarkerResponseDto'
                $Marker.lat | Should -BeOfType ([double])
                $Marker.lon | Should -BeOfType ([double])
            }
        }

        It 'Throws for a malformed album ID' {
            { Get-IMAlbumMapMarker -Id 'not-a-guid' } | Should -Throw
        }
    }
}
