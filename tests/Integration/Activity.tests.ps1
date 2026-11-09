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

Describe 'Activity' -Tag 'Integration' {
    # Intentionally excluded cmdlets: none.
    # Activity is covered against albums created by these tests. Pre-existing albums are never commented on or deleted.

    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $script:AssetA = 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
        $script:AssetB = '025665c6-d874-46a2-bbc6-37250ddcb2eb'
        $script:CreatedAlbumIds = [System.Collections.Generic.List[string]]::new()
        $script:NewTestAlbum = {
            $Name = "PSImmich-IT-$($env:GITHUB_RUN_ID)-$(Get-Random)"
            $Album = New-IMAlbum -AlbumName $Name -AssetIds @($script:AssetA, $script:AssetB)
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
                $null = $_
            }
        }
    }

    Context 'Add-IMActivity' -Tag 'Add-IMActivity' {
        BeforeAll {
            $script:Album = & $script:NewTestAlbum
        }

        It 'Adds a comment to an album and returns ActivityResponseDto' {
            $Result = Add-IMActivity -AlbumId $script:Album.id -Comment 'Album comment test'
            $Result.GetType().Name | Should -Be 'ActivityResponseDto'
            $Result.comment | Should -Be 'Album comment test'
            $Result.type | Should -Be 'comment'
            $Result.assetId | Should -BeNullOrEmpty
        }

        It 'Adds a like to an album' {
            $Result = Add-IMActivity -AlbumId $script:Album.id -Type like
            $Result.type | Should -Be 'like'
        }

        It 'Adds a comment to an asset within the album' {
            $Result = Add-IMActivity -AlbumId $script:Album.id -AssetId $script:AssetA -Comment 'Asset comment test'
            $Result.assetId | Should -Be $script:AssetA
            $Result.comment | Should -Be 'Asset comment test'
        }

        It 'Adds a like to an asset within the album' {
            $Result = Add-IMActivity -AlbumId $script:Album.id -AssetId $script:AssetB -Type like
            $Result.assetId | Should -Be $script:AssetB
            $Result.type | Should -Be 'like'
        }

        It 'Accepts album IDs from the pipeline' {
            $Result = $script:Album.id | Add-IMActivity -Comment 'Piped comment test'
            $Result.comment | Should -Be 'Piped comment test'
        }

        It 'Accepts album objects from the pipeline' {
            $Result = $script:Album | Add-IMActivity -Comment 'Piped album object test'
            $Result.comment | Should -Be 'Piped album object test'
        }

        It 'Throws for an invalid type' {
            { Add-IMActivity -AlbumId $script:Album.id -Type 'share' } | Should -Throw
        }

        It 'Throws for a malformed album ID' {
            { Add-IMActivity -AlbumId 'not-a-guid' -Comment 'x' } | Should -Throw
        }
    }

    Context 'Get-IMActivity' -Tag 'Get-IMActivity' {
        BeforeAll {
            $script:Album = & $script:NewTestAlbum
            $script:AlbumComment = Add-IMActivity -AlbumId $script:Album.id -Comment 'Get album comment'
            $script:AlbumLike = Add-IMActivity -AlbumId $script:Album.id -Type like
            $script:AssetComment = Add-IMActivity -AlbumId $script:Album.id -AssetId $script:AssetA -Comment 'Get asset comment'
        }

        It 'Lists all activity for an album' {
            $Result = @(Get-IMActivity -AlbumId $script:Album.id)
            $Result.id | Should -Contain $script:AlbumComment.id
            $Result.id | Should -Contain $script:AlbumLike.id
            $Result.id | Should -Contain $script:AssetComment.id
        }

        It 'Returns ActivityResponseDto objects' {
            $Result = @(Get-IMActivity -AlbumId $script:Album.id)[0]
            $Result.GetType().Name | Should -Be 'ActivityResponseDto'
        }

        It 'Filters to comments only' {
            $Result = @(Get-IMActivity -AlbumId $script:Album.id -Type comment)
            $Result | Should -Not -BeNullOrEmpty
            $Result.type | Should -Not -Contain 'like'
        }

        It 'Filters to likes only' {
            $Result = @(Get-IMActivity -AlbumId $script:Album.id -Type like)
            $Result | Should -Not -BeNullOrEmpty
            $Result.type | Should -Not -Contain 'comment'
        }

        It 'Filters to album-level activity' {
            $Result = @(Get-IMActivity -AlbumId $script:Album.id -Level album)
            $Result.id | Should -Contain $script:AlbumComment.id
            $Result.id | Should -Not -Contain $script:AssetComment.id
        }

        It 'Filters to asset-level activity for an asset' {
            $Result = @(Get-IMActivity -AlbumId $script:Album.id -AssetId $script:AssetA -Level asset)
            $Result.id | Should -Contain $script:AssetComment.id
            $Result.id | Should -Not -Contain $script:AlbumComment.id
        }

        It 'Filters by user ID' {
            $UserId = $script:AlbumComment.user.id
            $Result = @(Get-IMActivity -AlbumId $script:Album.id -UserId $UserId)
            $Result | Should -Not -BeNullOrEmpty
            $Result.user.id | Should -Not -Contain $null
            @($Result.user.id | Select-Object -Unique) | Should -Be $UserId
        }

        It 'Throws for an unknown user ID' {
            { Get-IMActivity -AlbumId $script:Album.id -UserId '00000000-0000-0000-0000-000000000000' } | Should -Throw
        }

        It 'Returns nothing for an asset not commented on' {
            $Result = Get-IMActivity -AlbumId $script:Album.id -AssetId $script:AssetB -Level asset -Type comment
            $Result | Should -BeNullOrEmpty
        }

        It 'Accepts album objects from the pipeline' {
            $Result = @($script:Album | Get-IMActivity)
            $Result.id | Should -Contain $script:AlbumComment.id
        }

        It 'Throws for an invalid level' {
            { Get-IMActivity -AlbumId $script:Album.id -Level group } | Should -Throw
        }

        It 'Throws for an invalid type' {
            { Get-IMActivity -AlbumId $script:Album.id -Type share } | Should -Throw
        }

        It 'Throws for a malformed album ID' {
            { Get-IMActivity -AlbumId 'not-a-guid' } | Should -Throw
        }
    }

    Context 'Get-IMActivityStatistic' -Tag 'Get-IMActivityStatistic' {
        BeforeAll {
            $script:Album = & $script:NewTestAlbum
        }

        It 'Returns ActivityStatisticsResponseDto with numeric counts for an album' {
            $Result = Get-IMActivityStatistic -AlbumId $script:Album.id
            $Result.GetType().Name | Should -Be 'ActivityStatisticsResponseDto'
            $Result.comments | Should -BeOfType ([long])
            $Result.likes | Should -BeOfType ([long])
        }

        It 'Counts comments added to the album' {
            $Before = (Get-IMActivityStatistic -AlbumId $script:Album.id).comments
            Add-IMActivity -AlbumId $script:Album.id -Comment 'Stat comment'
            (Get-IMActivityStatistic -AlbumId $script:Album.id).comments | Should -Be ($Before + 1)
        }

        It 'Counts likes added to the album' {
            $Before = (Get-IMActivityStatistic -AlbumId $script:Album.id).likes
            Add-IMActivity -AlbumId $script:Album.id -Type like
            (Get-IMActivityStatistic -AlbumId $script:Album.id).likes | Should -Be ($Before + 1)
        }

        It 'Counts comments for a single asset' {
            $Before = (Get-IMActivityStatistic -AlbumId $script:Album.id -AssetId $script:AssetB).comments
            Add-IMActivity -AlbumId $script:Album.id -AssetId $script:AssetB -Comment 'Asset stat comment'
            (Get-IMActivityStatistic -AlbumId $script:Album.id -AssetId $script:AssetB).comments | Should -Be ($Before + 1)
        }

        It 'Accepts album objects from the pipeline' {
            $Result = $script:Album | Get-IMActivityStatistic
            $Result.GetType().Name | Should -Be 'ActivityStatisticsResponseDto'
        }

        It 'Throws for a malformed album ID' {
            { Get-IMActivityStatistic -AlbumId 'not-a-guid' } | Should -Throw
        }
    }

    Context 'Remove-IMActivity' -Tag 'Remove-IMActivity' {
        BeforeAll {
            $script:Album = & $script:NewTestAlbum
        }

        It 'Removes a comment by ID' {
            $Activity = Add-IMActivity -AlbumId $script:Album.id -Comment 'To remove'
            Remove-IMActivity -Id $Activity.id -Confirm:$false
            Get-IMActivity -AlbumId $script:Album.id | Where-Object { $_.id -eq $Activity.id } | Should -BeNullOrEmpty
        }

        It 'Removes a like from a pipeline object' {
            $Activity = Add-IMActivity -AlbumId $script:Album.id -Type like
            $Activity | Remove-IMActivity -Confirm:$false
            Get-IMActivity -AlbumId $script:Album.id | Where-Object { $_.id -eq $Activity.id } | Should -BeNullOrEmpty
        }

        It 'Does not remove the activity with -WhatIf' {
            $Activity = Add-IMActivity -AlbumId $script:Album.id -Comment 'WhatIf keep'
            Remove-IMActivity -Id $Activity.id -WhatIf
            Get-IMActivity -AlbumId $script:Album.id | Where-Object { $_.id -eq $Activity.id } | Should -Not -BeNullOrEmpty
        }

        It 'Throws for a malformed activity ID' {
            { Remove-IMActivity -Id 'not-a-guid' -Confirm:$false } | Should -Throw
        }
    }
}
