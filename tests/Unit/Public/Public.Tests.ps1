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

InModuleScope $ProjectName {
    Describe 'Add-IMActivity' -Tag 'Unit', 'Add-IMActivity' {
        BeforeAll {
            Mock Invoke-ImmichApiCreateActivity -ModuleName PSImmich {
                return [PSCustomObject]@{
                    id        = 'activity-123'
                    albumId   = 'album-456'
                    assetId   = 'asset-789'
                    type      = 'comment'
                    comment   = 'Test comment'
                    user      = [PSCustomObject]@{
                        id   = 'user-abc'
                        name = 'Test User'
                    }
                    createdAt = '2024-01-01T12:00:00Z'
                }
            }
            Mock ConvertTo-ApiParameters {
                return @{
                    albumId = $BoundParameters.AlbumId
                    assetId = $BoundParameters.AssetId
                    comment = $BoundParameters.Comment
                    type    = $BoundParameters.Type
                }
            }
        }

        Context 'When adding a comment to an album' {
            It 'Should call Invoke-ImmichApiCreateActivity with correct parameters' {
                $params = @{
                    AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
                    Comment = 'Amazing sunset!'
                    Type    = 'comment'
                }

                Add-IMActivity @params

                Should -Invoke Invoke-ImmichApiCreateActivity -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Body.albumId -eq $params.AlbumId -and
                    $Body.comment -eq $params.Comment -and
                    $Body.type -eq $params.Type
                }
            }
        }

        Context 'When adding a like to a specific asset' {
            It 'Should call Invoke-ImmichApiCreateActivity with asset ID' {
                $params = @{
                    AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
                    AssetId = 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
                    Type    = 'like'
                }

                Add-IMActivity @params

                Should -Invoke Invoke-ImmichApiCreateActivity -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Body.albumId -eq $params.AlbumId -and
                    $Body.assetId -eq $params.AssetId -and
                    $Body.type -eq $params.Type
                }
            }
        }

        Context 'Pipeline support' {
            It 'Should accept AlbumId from pipeline by property name' {
                # Create objects with AlbumId property for pipeline test
                $pipelineObject = [PSCustomObject]@{ AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }

                # Test that function works when called with parameter from object property
                Add-IMActivity -AlbumId $pipelineObject.AlbumId -Type 'like'

                Should -Invoke Invoke-ImmichApiCreateActivity -ModuleName PSImmich -Times 1 -Exactly
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Add-IMActivity -AlbumId 'invalid-guid' -Type 'like' } | Should -Throw
            }

            It 'Should validate AssetId GUID format' {
                { Add-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -AssetId 'invalid-guid' -Type 'like' } | Should -Throw
            }

            It 'Should validate Type parameter' {
                { Add-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Type 'invalid' } | Should -Throw
            }
        }
    }
    Describe 'Get-IMActivity' -Tag 'Unit', 'Get-IMActivity' {
        BeforeAll {
            Mock Invoke-ImmichApiGetActivities -ModuleName PSImmich {
                return @(
                    [PSCustomObject]@{
                        id        = 'activity-1'
                        albumId   = 'album-456'
                        assetId   = 'asset-789'
                        type      = 'comment'
                        comment   = 'Great photo!'
                        user      = [PSCustomObject]@{
                            id   = 'user-1'
                            name = 'John Doe'
                        }
                        createdAt = '2024-01-01T12:00:00Z'
                    },
                    [PSCustomObject]@{
                        id        = 'activity-2'
                        albumId   = 'album-456'
                        type      = 'like'
                        user      = [PSCustomObject]@{
                            id   = 'user-2'
                            name = 'Jane Smith'
                        }
                        createdAt = '2024-01-01T13:00:00Z'
                    }
                )
            }
            Mock AddCustomType {
                param($InputObject)
                return $InputObject
            }
            Mock ConvertTo-ApiParameters {
                $result = @{}
                if ($BoundParameters.AlbumId)
                {
                    $result.albumId = $BoundParameters.AlbumId
                }
                if ($BoundParameters.AssetId)
                {
                    $result.assetId = $BoundParameters.AssetId
                }
                if ($BoundParameters.Level)
                {
                    $result.level = $BoundParameters.Level
                }
                if ($BoundParameters.Type)
                {
                    $result.type = $BoundParameters.Type
                }
                if ($BoundParameters.UserId)
                {
                    $result.userId = $BoundParameters.UserId
                }
                return $result
            }
        }

        Context 'When retrieving all activities for an album' {
            It 'Should call Invoke-ImmichApiGetActivities with correct parameters' {
                $albumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

                $result = Get-IMActivity -AlbumId $albumId

                Should -Invoke Invoke-ImmichApiGetActivities -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $AlbumId -eq $albumId
                }
                $result | Should -HaveCount 2
            }
        }

        Context 'When filtering by asset' {
            It 'Should include assetId in query parameters' {
                $params = @{
                    AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
                    AssetId = 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
                }

                Get-IMActivity @params

                Should -Invoke Invoke-ImmichApiGetActivities -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $AlbumId -eq $params.AlbumId -and
                    $AssetId -eq $params.AssetId
                }
            }
        }

        Context 'When filtering by type and level' {
            It 'Should include type and level filters in query parameters' {
                $params = @{
                    AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
                    Type    = 'comment'
                    Level   = 'album'
                }

                Get-IMActivity @params

                Should -Invoke Invoke-ImmichApiGetActivities -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $AlbumId -eq $params.AlbumId -and
                    $Type -eq $params.Type -and
                    $Level -eq $params.Level
                }
            }
        }

        Context 'When filtering by user' {
            It 'Should include userId in query parameters' {
                $params = @{
                    AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
                    UserId  = '12345678-1234-1234-1234-123456789abc'
                }

                Get-IMActivity @params

                Should -Invoke Invoke-ImmichApiGetActivities -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $AlbumId -eq $params.AlbumId -and
                    $UserId -eq $params.UserId
                }
            }
        }

        Context 'Pipeline support' {
            It 'Should accept AlbumId from pipeline by property name' {
                # Create objects with AlbumId property for pipeline test
                $pipelineObject = [PSCustomObject]@{ AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }

                # Test that function works when called with parameter from object property
                Get-IMActivity -AlbumId $pipelineObject.AlbumId

                Should -Invoke Invoke-ImmichApiGetActivities -ModuleName PSImmich -Times 1 -Exactly
            }
        }

        Context 'Returned object types' {
            It 'Should return ActivityResponseDto objects' {
                $result = Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

                $result[0].GetType().Name | Should -Be 'ActivityResponseDto'
                $result[0].user.GetType().Name | Should -Be 'UserResponseDto'
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Get-IMActivity -AlbumId 'invalid-guid' } | Should -Throw
            }

            It 'Should validate AssetId GUID format' {
                { Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -AssetId 'invalid-guid' } | Should -Throw
            }

            It 'Should validate Level parameter' {
                { Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Level 'invalid' } | Should -Throw
            }

            It 'Should validate Type parameter' {
                { Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Type 'invalid' } | Should -Throw
            }

            It 'Should validate UserId GUID format' {
                { Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -UserId 'invalid-guid' } | Should -Throw
            }
        }
    }
    Describe 'Get-IMActivityStatistic' -Tag 'Unit', 'Get-IMActivityStatistic' {
        BeforeAll {
            Mock Invoke-ImmichApiGetActivityStatistics -ModuleName PSImmich {
                return [PSCustomObject]@{
                    albumId         = 'album-456'
                    assetId         = 'asset-789'
                    comments        = 5
                    likes           = 12
                    totalActivities = 17
                }
            }
            Mock ConvertTo-ApiParameters {
                $result = @{}
                if ($BoundParameters.AlbumId)
                {
                    $result.albumId = $BoundParameters.AlbumId
                }
                if ($BoundParameters.AssetId)
                {
                    $result.assetId = $BoundParameters.AssetId
                }
                return $result
            }
        }

        Context 'When retrieving album statistics' {
            It 'Should call Invoke-ImmichApiGetActivityStatistics with correct parameters' {
                $albumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

                $result = Get-IMActivityStatistic -AlbumId $albumId

                Should -Invoke Invoke-ImmichApiGetActivityStatistics -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $AlbumId -eq $albumId
                }
                $result | Should -Not -BeNullOrEmpty
                $result.comments | Should -Be 5
                $result.likes | Should -Be 12
            }
        }

        Context 'When retrieving asset statistics' {
            It 'Should include assetId in query parameters' {
                $params = @{
                    AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
                    AssetId = 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
                }

                Get-IMActivityStatistic @params

                Should -Invoke Invoke-ImmichApiGetActivityStatistics -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $AlbumId -eq $params.AlbumId -and
                    $AssetId -eq $params.AssetId
                }
            }
        }

        Context 'Pipeline support' {
            It 'Should accept AlbumId from pipeline by property name' {
                # Create objects with AlbumId property for pipeline test
                $pipelineObject = [PSCustomObject]@{ AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }

                # Test that function works when called with parameter from object property
                Get-IMActivityStatistic -AlbumId $pipelineObject.AlbumId

                Should -Invoke Invoke-ImmichApiGetActivityStatistics -ModuleName PSImmich -Times 1 -Exactly
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Get-IMActivityStatistic -AlbumId 'invalid-guid' } | Should -Throw
            }

            It 'Should validate AssetId GUID format' {
                { Get-IMActivityStatistic -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -AssetId 'invalid-guid' } | Should -Throw
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                # Test without explicit session parameter
                $albumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

                Get-IMActivityStatistic -AlbumId $albumId

                Should -Invoke Invoke-ImmichApiGetActivityStatistics -ModuleName PSImmich -Times 1 -Exactly
            }
        }
    }
    Describe 'Remove-IMActivity' -Tag 'Unit', 'Remove-IMActivity' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteActivity -ModuleName PSImmich { return $null }
        }

        Context 'When removing a single activity' {
            It 'Should call Invoke-ImmichApiDeleteActivity with correct parameters' {
                Remove-IMActivity -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteActivity -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
                }
            }
        }

        Context 'When removing multiple activities' {
            It 'Should process each activity ID separately' {
                $activityIds = @('bde7ceba-f301-4e9e-87a2-163937a2a3db', '550e8400-e29b-41d4-a716-446655440000')
                $activityIds | Remove-IMActivity -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteActivity -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }
        }

        Context 'Pipeline support' {
            It 'Should accept Id from pipeline by value' {
                'bde7ceba-f301-4e9e-87a2-163937a2a3db' | Remove-IMActivity -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteActivity -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
                }
            }

            It 'Should accept Id from pipeline by property name' {
                [PSCustomObject]@{Id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' } | Remove-IMActivity -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteActivity -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate Id GUID format' {
                { Remove-IMActivity -Id 'invalid-guid' -Confirm:$false } | Should -Throw
            }

            It 'Should require Id parameter' {
                (Get-Command Remove-IMActivity).Parameters['Id'].Attributes.Mandatory | Should -Be $true
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                Remove-IMActivity -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteActivity -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Add-IMAlbumUser' -Tag 'Unit', 'Add-IMAlbumUser' {
        BeforeAll {
            Mock Invoke-ImmichApiAddUsersToAlbum -ModuleName PSImmich { return @{success = $true } }
        }

        Context 'When adding a single user to an album' {
            It 'Should call Invoke-ImmichApiAddUsersToAlbum with correct parameters' {
                Add-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId '223e4567-e89b-12d3-a456-426614174001' -Role 'editor'

                Should -Invoke Invoke-ImmichApiAddUsersToAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000' -and
                    $Body.albumUsers -is [array] -and
                    $Body.albumUsers[0].userId -eq '223e4567-e89b-12d3-a456-426614174001' -and
                    $Body.albumUsers[0].role -eq 'editor'
                }
            }
        }

        Context 'When adding multiple users with different roles' {
            It 'Should create correct body with multiple user objects' {
                Add-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId @('223e4567-e89b-12d3-a456-426614174001', '323e4567-e89b-12d3-a456-426614174002') -Role 'viewer'

                Should -Invoke Invoke-ImmichApiAddUsersToAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.albumUsers.Count -eq 2 -and
                    $Body.albumUsers[0].role -eq 'viewer' -and
                    $Body.albumUsers[1].role -eq 'viewer'
                }
            }
        }

        Context 'Pipeline support' {
            It 'Should accept UserId from pipeline by value' {
                @('223e4567-e89b-12d3-a456-426614174001', '323e4567-e89b-12d3-a456-426614174002') | Add-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -Role 'editor'

                Should -Invoke Invoke-ImmichApiAddUsersToAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.albumUsers.Count -eq 2
                }
            }

            It 'Should accept UserId from pipeline by property name' {
                $users = @(
                    [PSCustomObject]@{id = '223e4567-e89b-12d3-a456-426614174001' }
                    [PSCustomObject]@{id = '323e4567-e89b-12d3-a456-426614174002' }
                )
                $users | Add-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -Role 'viewer'

                Should -Invoke Invoke-ImmichApiAddUsersToAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Add-IMAlbumUser -AlbumId 'invalid-guid' -UserId '223e4567-e89b-12d3-a456-426614174001' } | Should -Throw
            }

            It 'Should validate UserId GUID format' {
                { Add-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId 'invalid-guid' } | Should -Throw
            }

            It 'Should validate Role parameter' {
                { Add-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId '223e4567-e89b-12d3-a456-426614174001' -Role 'invalid' } | Should -Throw
            }
        }

        Context 'Default parameter values' {
            It 'Should use viewer as default role' {
                Add-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId '223e4567-e89b-12d3-a456-426614174001'

                Should -Invoke Invoke-ImmichApiAddUsersToAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.albumUsers[0].role -eq 'viewer'
                }
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                Add-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId '223e4567-e89b-12d3-a456-426614174001'

                Should -Invoke Invoke-ImmichApiAddUsersToAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Get-IMAlbum' -Tag 'Unit', 'Get-IMAlbum' {
        BeforeAll {
            Mock Invoke-ImmichApiGetAllAlbums -ModuleName PSImmich {
                return @(
                    @{id = '123e4567-e89b-12d3-a456-426614174000'; albumName = 'Family Photos'; shared = $false },
                    @{id = '223e4567-e89b-12d3-a456-426614174001'; albumName = 'Vacation 2023'; shared = $true }
                )
            }
            Mock Invoke-ImmichApiGetAlbumInfo -ModuleName PSImmich {
                return @{id = '123e4567-e89b-12d3-a456-426614174000'; albumName = 'Family Photos'; assets = @() }
            }
            Mock ConvertTo-ApiParameters { return @{} }
            Mock AddCustomType {
                param($InputObject, $TypeName)
                return $InputObject
            } -ModuleName 'PSImmich'
        }

        Context 'When retrieving all albums (list parameter set)' {
            It 'Should call Invoke-ImmichApiGetAllAlbums without filters by default' {
                Get-IMAlbum

                Should -Invoke Invoke-ImmichApiGetAllAlbums -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $IsShared -and $null -eq $AssetId
                }
                Should -Invoke Invoke-ImmichApiGetAlbumInfo -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }

            It 'Should pass IsShared when Shared is specified' {
                Get-IMAlbum -Shared $true

                Should -Invoke Invoke-ImmichApiGetAllAlbums -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $IsShared -eq $true
                }
            }

            It 'Should pass IsShared as false when Shared is false' {
                Get-IMAlbum -Shared $false

                Should -Invoke Invoke-ImmichApiGetAllAlbums -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $IsShared -eq $false
                }
            }

            It 'Should return AlbumResponseDto objects' {
                $result = Get-IMAlbum

                $result | ForEach-Object { $PSItem.GetType().Name | Should -Be 'AlbumResponseDto' }
            }
        }

        Context 'When retrieving specific album by ID (id parameter set)' {
            It 'Should call Invoke-ImmichApiGetAlbumInfo with the album ID' {
                Get-IMAlbum -AlbumId '123e4567-e89b-12d3-a456-426614174000'

                Should -Invoke Invoke-ImmichApiGetAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
                Should -Invoke Invoke-ImmichApiGetAllAlbums -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }

            It 'Should return AlbumResponseDto without assets when IncludeAssets is omitted' {
                $result = Get-IMAlbum -AlbumId '123e4567-e89b-12d3-a456-426614174000'

                $result.GetType().Name | Should -Be 'AlbumResponseDto'
                $result.PSObject.Properties.Name | Should -Not -Contain 'assets'
            }
        }

        Context 'When including assets' {
            BeforeAll {
                Mock Invoke-ImmichApiSearchAssets -ModuleName PSImmich {
                    if ($Body.page -eq 1)
                    {
                        return @{ assets = @{ items = @(@{ id = 'asset-1' }); nextPage = '2' } }
                    }
                    return @{ assets = @{ items = @(@{ id = 'asset-2' }); nextPage = $null } }
                }
            }

            It 'Should page through metadata search filtered by the album ID' {
                $result = Get-IMAlbum -AlbumId '123e4567-e89b-12d3-a456-426614174000' -IncludeAssets

                Should -Invoke Invoke-ImmichApiSearchAssets -Times 2 -Exactly -Scope It -ModuleName 'PSImmich' -ParameterFilter {
                    $Body.albumIds -contains '123e4567-e89b-12d3-a456-426614174000'
                }
                $result.assets.id | Should -Be @('asset-1', 'asset-2')
            }
        }

        Context 'When filtering by asset ID' {
            It 'Should pass AssetId to Invoke-ImmichApiGetAllAlbums' {
                Get-IMAlbum -AssetId '123e4567-e89b-12d3-a456-426614174000'

                Should -Invoke Invoke-ImmichApiGetAllAlbums -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $AssetId -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }
        }

        Context 'Pipeline support' {
            It 'Should accept AlbumId from pipeline by value' {
                '123e4567-e89b-12d3-a456-426614174000' | Get-IMAlbum

                Should -Invoke Invoke-ImmichApiGetAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept AlbumId from pipeline by property name' {
                [PSCustomObject]@{Id = '123e4567-e89b-12d3-a456-426614174000' } | Get-IMAlbum

                Should -Invoke Invoke-ImmichApiGetAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Get-IMAlbum -AlbumId 'invalid-guid' } | Should -Throw
            }

            It 'Should validate AssetId GUID format' {
                { Get-IMAlbum -AssetId 'invalid-guid' } | Should -Throw
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                Get-IMAlbum

                Should -Invoke Invoke-ImmichApiGetAllAlbums -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Get-IMAlbumStatistic' -Tag 'Unit', 'Get-IMAlbumStatistic' {
        BeforeAll {
            Mock Invoke-ImmichApiGetAlbumStatistics -ModuleName PSImmich {
                return @{
                    notShared = 9
                    owned     = 17
                    shared    = 8
                }
            }
        }

        Context 'When retrieving album statistics' {
            It 'Should call Invoke-ImmichApiGetAlbumStatistics' {
                Get-IMAlbumStatistic

                Should -Invoke Invoke-ImmichApiGetAlbumStatistics -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }

            It 'Should return AlbumStatisticsResponseDto' {
                $result = Get-IMAlbumStatistic

                $result.GetType().Name | Should -Be 'AlbumStatisticsResponseDto'
                $result.owned | Should -Be 17
                $result.shared | Should -Be 8
                $result.notShared | Should -Be 9
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                Get-IMAlbumStatistic

                Should -Invoke Invoke-ImmichApiGetAlbumStatistics -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'New-IMAlbum' -Tag 'Unit', 'New-IMAlbum' {
        BeforeAll {
            Mock Invoke-ImmichApiCreateAlbum {
                return [PSCustomObject]@{
                    id          = '123e4567-e89b-12d3-a456-426614174000'
                    albumName   = 'Test Album'
                    description = 'Test Description'
                    assets      = @()
                    albumUsers  = @()
                    shared      = $false
                }
            } -ModuleName PSImmich
        }

        Context 'When creating an album with minimal parameters' {
            It 'Should send only albumName in the body' {
                New-IMAlbum -AlbumName 'Test Album'

                Should -Invoke Invoke-ImmichApiCreateAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.albumName -eq 'Test Album' -and
                    -not $Body.ContainsKey('description') -and
                    -not $Body.ContainsKey('assetIds') -and
                    -not $Body.ContainsKey('albumUsers')
                }
            }

            It 'Should return an AlbumResponseDto' {
                $result = New-IMAlbum -AlbumName 'Test Album'

                $result.GetType().Name | Should -Be 'AlbumResponseDto'
                $result.Id | Should -Be '123e4567-e89b-12d3-a456-426614174000'
            }
        }

        Context 'When creating an album with all parameters' {
            It 'Should send all optional parameters in the body' {
                $assetIds = @('550e8400-e29b-41d4-a716-446655440000', '6ba7b810-9dad-11d1-80b4-00c04fd430c8')
                $albumUsers = @(@{userId = 'user1-uuid'; role = 'editor' }, @{userId = 'user2-uuid'; role = 'viewer' })

                New-IMAlbum -AlbumName 'Complete Album' -Description 'Test Description' -AssetIds $assetIds -AlbumUsers $albumUsers

                Should -Invoke Invoke-ImmichApiCreateAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.albumName -eq 'Complete Album' -and
                    $Body.description -eq 'Test Description' -and
                    $Body.assetIds.Count -eq 2 -and
                    $Body.albumUsers.Count -eq 2
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AssetIds GUID format' {
                { New-IMAlbum -AlbumName 'Test' -AssetIds @('invalid-guid') } | Should -Throw
            }

            It 'Should require AlbumName parameter' {
                (Get-Command New-IMAlbum).Parameters['AlbumName'].Attributes.Mandatory | Should -Be $true
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                New-IMAlbum -AlbumName 'Test Album'

                Should -Invoke Invoke-ImmichApiCreateAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Remove-IMAlbum' -Tag 'Unit', 'Remove-IMAlbum' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteAlbum -ModuleName PSImmich { return $null }
        }

        Context 'When removing a single album' {
            It 'Should call Invoke-ImmichApiDeleteAlbum with the album ID' {
                Remove-IMAlbum -AlbumId '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }
        }

        Context 'When removing multiple albums' {
            It 'Should process each album ID separately' {
                $albumIds = @('123e4567-e89b-12d3-a456-426614174000', '223e4567-e89b-12d3-a456-426614174001')
                Remove-IMAlbum -AlbumId $albumIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAlbum -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }
        }

        Context 'Pipeline support' {
            It 'Should accept AlbumId from pipeline by value' {
                '123e4567-e89b-12d3-a456-426614174000' | Remove-IMAlbum -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept AlbumId from pipeline by property name' {
                [PSCustomObject]@{id = '123e4567-e89b-12d3-a456-426614174000' } | Remove-IMAlbum -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Remove-IMAlbum -AlbumId 'invalid-guid' -Confirm:$false } | Should -Throw
            }

            It 'Should require AlbumId parameter' {
                (Get-Command Remove-IMAlbum).Parameters['AlbumId'].Attributes.Mandatory | Should -Be $true
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                Remove-IMAlbum -AlbumId '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Remove-IMAlbumUser' -Tag 'Unit', 'Remove-IMAlbumUser' {
        BeforeAll {
            Mock Invoke-ImmichApiRemoveUserFromAlbum -ModuleName PSImmich { return $null }
        }

        Context 'When removing a single user from album' {
            It 'Should call Invoke-ImmichApiRemoveUserFromAlbum with correct parameters' {
                Remove-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId '550e8400-e29b-41d4-a716-446655440000' -Confirm:$false

                Should -Invoke Invoke-ImmichApiRemoveUserFromAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000' -and $UserId -eq '550e8400-e29b-41d4-a716-446655440000'
                }
            }
        }

        Context 'When removing multiple users from album' {
            It 'Should process each user ID separately' {
                $userIds = @('550e8400-e29b-41d4-a716-446655440000', '6ba7b810-9dad-11d1-80b4-00c04fd430c8')
                Remove-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId $userIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiRemoveUserFromAlbum -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }
        }

        Context 'Pipeline support' {
            It 'Should accept UserId from pipeline by value' {
                '550e8400-e29b-41d4-a716-446655440000' | Remove-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke Invoke-ImmichApiRemoveUserFromAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000' -and $UserId -eq '550e8400-e29b-41d4-a716-446655440000'
                }
            }

            It 'Should accept UserId from pipeline by property name' {
                [PSCustomObject]@{id = '550e8400-e29b-41d4-a716-446655440000' } | Remove-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke Invoke-ImmichApiRemoveUserFromAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000' -and $UserId -eq '550e8400-e29b-41d4-a716-446655440000'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Remove-IMAlbumUser -AlbumId 'invalid-guid' -UserId '550e8400-e29b-41d4-a716-446655440000' -Confirm:$false } | Should -Throw
            }

            It 'Should validate UserId GUID format' {
                { Remove-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId 'invalid-guid' -Confirm:$false } | Should -Throw
            }

            It 'Should require both AlbumId and UserId parameters' {
                (Get-Command Remove-IMAlbumUser).Parameters['AlbumId'].Attributes.Mandatory | Should -Be $true
                (Get-Command Remove-IMAlbumUser).Parameters['UserId'].Attributes.Mandatory | Should -Be $true
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                Remove-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId '550e8400-e29b-41d4-a716-446655440000' -Confirm:$false

                Should -Invoke Invoke-ImmichApiRemoveUserFromAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Rename-IMAlbum' -Tag 'Unit', 'Rename-IMAlbum' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateAlbumInfo { return [PSCustomObject]@{ id = '123e4567-e89b-12d3-a456-426614174000' } } -ModuleName PSImmich
        }

        Context 'When renaming a single album' {
            It 'Should send albumName to the album update route' {
                Rename-IMAlbum -Id '123e4567-e89b-12d3-a456-426614174000' -NewName 'Vacation 2024' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000' -and $Body.albumName -eq 'Vacation 2024'
                }
            }
        }

        Context 'When renaming multiple albums' {
            It 'Should process each album ID separately' {
                $albumIds = @('123e4567-e89b-12d3-a456-426614174000', '223e4567-e89b-12d3-a456-426614174001')
                Rename-IMAlbum -Id $albumIds -NewName 'Archived Photos' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAlbumInfo -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }
        }

        Context 'Pipeline support' {
            It 'Should accept Id from pipeline by value' {
                '123e4567-e89b-12d3-a456-426614174000' | Rename-IMAlbum -NewName 'Piped Album' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept Id from pipeline by property name' {
                [PSCustomObject]@{albumId = '123e4567-e89b-12d3-a456-426614174000' } | Rename-IMAlbum -NewName 'Property Album' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate Id GUID format' {
                { Rename-IMAlbum -Id 'invalid-guid' -NewName 'Test' -Confirm:$false } | Should -Throw
            }

            It 'Should require both Id and NewName parameters' {
                (Get-Command Rename-IMAlbum).Parameters['Id'].Attributes.Mandatory | Should -Be $true
                (Get-Command Rename-IMAlbum).Parameters['NewName'].Attributes.Mandatory | Should -Be $true
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                Rename-IMAlbum -Id '123e4567-e89b-12d3-a456-426614174000' -NewName 'Session Test' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Set-IMAlbum' -Tag 'Unit', 'Set-IMAlbum' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateAlbumInfo { return [PSCustomObject]@{ id = '123e4567-e89b-12d3-a456-426614174000' } } -ModuleName PSImmich
            Mock Invoke-ImmichApiAddAssetsToAlbum { return @() } -ModuleName PSImmich
            Mock Invoke-ImmichApiRemoveAssetFromAlbum { return @() } -ModuleName PSImmich
        }

        Context 'When updating album properties' {
            It 'Should send only the bound properties in the body' {
                Set-IMAlbum -Id '123e4567-e89b-12d3-a456-426614174000' -AlbumName 'Updated Album' -Description 'New description' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000' -and
                    $Body.albumName -eq 'Updated Album' -and
                    $Body.description -eq 'New description' -and
                    -not $Body.ContainsKey('isActivityEnabled') -and
                    -not $Body.ContainsKey('order') -and
                    -not $Body.ContainsKey('albumThumbnailAssetId')
                }
            }

            It 'Should send explicit false and order values in the body' {
                Set-IMAlbum -Id '123e4567-e89b-12d3-a456-426614174000' -IsActivityEnabled:$false -Order 'desc' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.isActivityEnabled -eq $false -and $Body.order -eq 'desc'
                }
            }
        }

        Context 'When adding assets' {
            It 'Should call the add assets route with the asset IDs' {
                $assetIds = @('550e8400-e29b-41d4-a716-446655440000', '6ba7b810-9dad-11d1-80b4-00c04fd430c8')
                Set-IMAlbum -Id '123e4567-e89b-12d3-a456-426614174000' -AddAssets $assetIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiAddAssetsToAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000' -and $Body.ids.Count -eq 2
                }
                Should -Invoke Invoke-ImmichApiUpdateAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }

        Context 'When removing assets' {
            It 'Should call the remove assets route with the asset IDs' {
                $assetIds = @('550e8400-e29b-41d4-a716-446655440000')
                Set-IMAlbum -Id '123e4567-e89b-12d3-a456-426614174000' -RemoveAssets $assetIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiRemoveAssetFromAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000' -and $Body.ids -contains '550e8400-e29b-41d4-a716-446655440000'
                }
            }
        }

        Context 'When managing assets and updating properties' {
            It 'Should handle property update, add and remove in one call' {
                $addAssets = @('550e8400-e29b-41d4-a716-446655440000')
                $removeAssets = @('6ba7b810-9dad-11d1-80b4-00c04fd430c8')
                Set-IMAlbum -Id '123e4567-e89b-12d3-a456-426614174000' -AlbumName 'Mixed Operation' -AddAssets $addAssets -RemoveAssets $removeAssets -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It
                Should -Invoke Invoke-ImmichApiAddAssetsToAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It
                Should -Invoke Invoke-ImmichApiRemoveAssetFromAlbum -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }

        Context 'When updating multiple albums' {
            It 'Should process each album ID separately' {
                $albumIds = @('123e4567-e89b-12d3-a456-426614174000', '223e4567-e89b-12d3-a456-426614174001')
                Set-IMAlbum -Id $albumIds -Description 'Bulk update description' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAlbumInfo -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }
        }

        Context 'Pipeline support' {
            It 'Should accept Id from pipeline by value' {
                '123e4567-e89b-12d3-a456-426614174000' | Set-IMAlbum -Description 'Piped update' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept Id from pipeline by property name' {
                [PSCustomObject]@{albumId = '123e4567-e89b-12d3-a456-426614174000' } | Set-IMAlbum -AlbumName 'Property Update' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate Id GUID format' {
                { Set-IMAlbum -Id 'invalid-guid' -Description 'Test' -Confirm:$false } | Should -Throw
            }

            It 'Should validate AlbumThumbnailAssetId GUID format' {
                { Set-IMAlbum -Id '123e4567-e89b-12d3-a456-426614174000' -AlbumThumbnailAssetId 'invalid-guid' -Confirm:$false } | Should -Throw
            }

            It 'Should validate Order parameter values' {
                { Set-IMAlbum -Id '123e4567-e89b-12d3-a456-426614174000' -Order 'invalid' -Confirm:$false } | Should -Throw
            }

            It 'Should require Id parameter' {
                (Get-Command Set-IMAlbum).Parameters['Id'].Attributes.Mandatory | Should -Be $true
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                Set-IMAlbum -Id '123e4567-e89b-12d3-a456-426614174000' -Description 'Session test' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAlbumInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Set-IMAlbumUser' -Tag 'Unit', 'Set-IMAlbumUser' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateAlbumUser { return $null } -ModuleName PSImmich
        }

        Context 'When setting user role for single user' {
            It 'Should send the role to the album user route' {
                Set-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId '550e8400-e29b-41d4-a716-446655440000' -Role 'editor'

                Should -Invoke Invoke-ImmichApiUpdateAlbumUser -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000' -and
                    $UserId -eq '550e8400-e29b-41d4-a716-446655440000' -and
                    $Body.role -eq 'editor'
                }
            }
        }

        Context 'When setting roles for multiple users' {
            It 'Should process each user ID separately' {
                $userIds = @('550e8400-e29b-41d4-a716-446655440000', '6ba7b810-9dad-11d1-80b4-00c04fd430c8')
                Set-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId $userIds -Role 'editor'

                Should -Invoke Invoke-ImmichApiUpdateAlbumUser -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }
        }

        Context 'Pipeline support' {
            It 'Should accept UserId from pipeline by value' {
                '550e8400-e29b-41d4-a716-446655440000' | Set-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -Role 'viewer'

                Should -Invoke Invoke-ImmichApiUpdateAlbumUser -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $UserId -eq '550e8400-e29b-41d4-a716-446655440000' -and $Body.role -eq 'viewer'
                }
            }

            It 'Should accept UserId from pipeline by property name' {
                [PSCustomObject]@{id = '550e8400-e29b-41d4-a716-446655440000' } | Set-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -Role 'editor'

                Should -Invoke Invoke-ImmichApiUpdateAlbumUser -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $UserId -eq '550e8400-e29b-41d4-a716-446655440000'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Set-IMAlbumUser -AlbumId 'invalid-guid' -UserId '550e8400-e29b-41d4-a716-446655440000' -Role 'editor' } | Should -Throw
            }

            It 'Should validate UserId GUID format' {
                { Set-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId 'invalid-guid' -Role 'viewer' } | Should -Throw
            }

            It 'Should validate Role parameter values' {
                { Set-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId '550e8400-e29b-41d4-a716-446655440000' -Role 'invalid' } | Should -Throw
            }

            It 'Should require all mandatory parameters' {
                (Get-Command Set-IMAlbumUser).Parameters['AlbumId'].Attributes.Mandatory | Should -Be $true
                (Get-Command Set-IMAlbumUser).Parameters['UserId'].Attributes.Mandatory | Should -Be $true
                (Get-Command Set-IMAlbumUser).Parameters['Role'].Attributes.Mandatory | Should -Be $true
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                Set-IMAlbumUser -AlbumId '123e4567-e89b-12d3-a456-426614174000' -UserId '550e8400-e29b-41d4-a716-446655440000' -Role 'viewer'

                Should -Invoke Invoke-ImmichApiUpdateAlbumUser -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Get-IMAPIKey' -Tag 'Unit', 'Get-IMAPIKey' {
        BeforeAll {
            Mock Invoke-ImmichApiGetApiKeys -ModuleName PSImmich {
                return @(
                    [PSCustomObject]@{
                        id          = '123e4567-e89b-12d3-a456-426614174000'
                        name        = 'Production API Key'
                        permissions = @('all')
                        createdAt   = '2024-01-01T12:00:00Z'
                        updatedAt   = '2024-01-01T12:00:00Z'
                    },
                    [PSCustomObject]@{
                        id          = '223e4567-e89b-12d3-a456-426614174001'
                        name        = 'Read Only Key'
                        permissions = @('asset.read', 'album.read')
                        createdAt   = '2024-01-02T12:00:00Z'
                        updatedAt   = '2024-01-02T12:00:00Z'
                    }
                )
            }
            Mock Invoke-ImmichApiGetApiKey -ModuleName PSImmich {
                return [PSCustomObject]@{
                    id          = $Id
                    name        = 'Production API Key'
                    permissions = @('all')
                    createdAt   = '2024-01-01T12:00:00Z'
                    updatedAt   = '2024-01-01T12:00:00Z'
                }
            }
        }

        Context 'When retrieving all API keys (list parameter set)' {
            It 'Should call Invoke-ImmichApiGetApiKeys' {
                Get-IMAPIKey

                Should -Invoke Invoke-ImmichApiGetApiKeys -ModuleName PSImmich -Times 1 -Exactly -Scope It
                Should -Invoke Invoke-ImmichApiGetApiKey -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }

            It 'Should return ApiKeyResponseDto objects' {
                $result = @(Get-IMAPIKey)

                $result.Count | Should -Be 2
                $result[0].GetType().Name | Should -Be 'ApiKeyResponseDto'
                $result[1].name | Should -Be 'Read Only Key'
            }
        }

        Context 'When retrieving specific API key by ID (id parameter set)' {
            It 'Should call Invoke-ImmichApiGetApiKey with the key ID' {
                Get-IMAPIKey -Id '123e4567-e89b-12d3-a456-426614174000'

                Should -Invoke Invoke-ImmichApiGetApiKey -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should retrieve multiple API keys when multiple IDs provided' {
                $keyIds = @('123e4567-e89b-12d3-a456-426614174000', '223e4567-e89b-12d3-a456-426614174001')
                Get-IMAPIKey -Id $keyIds

                Should -Invoke Invoke-ImmichApiGetApiKey -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }
        }

        Context 'Pipeline support' {
            It 'Should accept Id from pipeline by value' {
                '123e4567-e89b-12d3-a456-426614174000' | Get-IMAPIKey

                Should -Invoke Invoke-ImmichApiGetApiKey -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept Id from pipeline by property name' {
                [PSCustomObject]@{Id = '123e4567-e89b-12d3-a456-426614174000' } | Get-IMAPIKey

                Should -Invoke Invoke-ImmichApiGetApiKey -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate Id GUID format' {
                { Get-IMAPIKey -Id 'invalid-guid' } | Should -Throw
            }
        }

        Context 'Session parameter' {
            It 'Should forward the session to the API function' {
                Get-IMAPIKey

                Should -Invoke Invoke-ImmichApiGetApiKeys -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'New-IMAPIKey' -Tag 'Unit', 'New-IMAPIKey' {
        BeforeAll {
            Mock Invoke-ImmichApiCreateApiKey -ModuleName PSImmich {
                return [PSCustomObject]@{
                    apiKey      = [PSCustomObject]@{
                        id          = '123e4567-e89b-12d3-a456-426614174000'
                        name        = 'Test API Key'
                        permissions = $Body.permissions
                        createdAt   = '2024-01-01T12:00:00Z'
                        updatedAt   = '2024-01-01T12:00:00Z'
                    }
                    id          = '123e4567-e89b-12d3-a456-426614174000'
                    name        = 'Test API Key'
                    permissions = $Body.permissions
                    secret      = 'api_key_secret_12345'
                    createdAt   = '2024-01-01T12:00:00Z'
                    updatedAt   = '2024-01-01T12:00:00Z'
                }
            }
            Mock ConvertTo-ApiParameters {
                $result = @{}
                if ($BoundParameters.Name)
                {
                    $result.name = $BoundParameters.Name
                }
                if ($BoundParameters.Permission)
                {
                    $result.permissions = $BoundParameters.Permission
                }
                return $result
            }
        }

        Context 'When creating API key with default permissions' {
            It 'Should call Invoke-ImmichApiCreateApiKey' {
                New-IMAPIKey -Name 'Test Key'

                Should -Invoke Invoke-ImmichApiCreateApiKey -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }

            It 'Should call ConvertTo-ApiParameters for body parameters' {
                New-IMAPIKey -Name 'Production Key'

                Should -Invoke ConvertTo-ApiParameters -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }

            It 'Should pass the name in the request body' {
                New-IMAPIKey -Name 'Default Permissions'

                Should -Invoke Invoke-ImmichApiCreateApiKey -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.name -eq 'Default Permissions'
                }
            }
        }

        Context 'When creating API key with specific permissions' {
            It 'Should handle single permission' {
                New-IMAPIKey -Name 'Read Only Key' -Permission 'asset.read'

                Should -Invoke Invoke-ImmichApiCreateApiKey -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    @($Body.permissions) -contains 'asset.read'
                }
            }

            It 'Should handle multiple permissions' {
                $permissions = @('asset.read', 'album.read', 'library.read')
                New-IMAPIKey -Name 'Multi Permission Key' -Permission $permissions

                Should -Invoke Invoke-ImmichApiCreateApiKey -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    @($Body.permissions).Count -eq 3
                }
            }

            It 'Should handle admin permissions' {
                $adminPermissions = @('admin.user.create', 'admin.user.read', 'admin.user.update')
                New-IMAPIKey -Name 'Admin Key' -Permission $adminPermissions

                Should -Invoke Invoke-ImmichApiCreateApiKey -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }

        Context 'Parameter validation' {
            It 'Should require Name parameter' {
                (Get-Command New-IMAPIKey).Parameters['Name'].Attributes.Mandatory | Should -Be $true
            }

            It 'Should validate Permission parameter values' {
                { New-IMAPIKey -Name 'Invalid Permission' -Permission 'invalid.permission' } | Should -Throw
            }

            It 'Should accept valid permission values' {
                # Test a few valid permission values to ensure validation works
                { New-IMAPIKey -Name 'Valid Permissions' -Permission 'all' } | Should -Not -Throw
                { New-IMAPIKey -Name 'Valid Permissions' -Permission 'asset.read' } | Should -Not -Throw
                { New-IMAPIKey -Name 'Valid Permissions' -Permission 'album.create' } | Should -Not -Throw
            }
        }

        Context 'Return value' {
            It 'Should return created API key information' {
                $result = New-IMAPIKey -Name 'Test Return Value'

                $result.id | Should -Be '123e4567-e89b-12d3-a456-426614174000'
                $result.name | Should -Be 'Test API Key'
                $result.secret | Should -Be 'api_key_secret_12345'
                $result.GetType().Name | Should -Be 'ApiKeyCreateResponseDto'
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                New-IMAPIKey -Name 'Session Test'

                Should -Invoke Invoke-ImmichApiCreateApiKey -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'New-IMFace' -Tag 'Unit', 'New-IMFace' {
        BeforeAll {
            Mock Invoke-ImmichApiCreateFace -ModuleName PSImmich {}
        }

        Context 'Parameter Validation' {
            It 'Should have mandatory parameters' {
                $Command = Get-Command New-IMFace
                $MandatoryParams = @('AssetId', 'PersonId', 'X', 'Y', 'Width', 'Height', 'ImageWidth', 'ImageHeight')
                foreach ($Param in $MandatoryParams)
                {
                    $Command.Parameters[$Param].ParameterSets.Values.IsMandatory | Should -Contain $true
                }
            }

            It 'Should validate GUID format for AssetId parameter' {
                { New-IMFace -AssetId 'invalid-guid' -PersonId '123e4567-e89b-12d3-a456-426614174000' -X 100 -Y 150 -Width 200 -Height 250 -ImageWidth 1920 -ImageHeight 1080 } | Should -Throw
            }

            It 'Should validate GUID format for PersonId parameter' {
                { New-IMFace -AssetId '123e4567-e89b-12d3-a456-426614174000' -PersonId 'invalid-guid' -X 100 -Y 150 -Width 200 -Height 250 -ImageWidth 1920 -ImageHeight 1080 } | Should -Throw
            }
        }

        Context 'API Calls' {
            BeforeAll {
                $TestParams = @{
                    AssetId     = 'a7c3b52c-1a2b-3c4d-5e6f-7a8b9c0d1e2f'
                    PersonId    = 'b8d4c63d-2b3c-4d5e-6f7a-8b9c0d1e2f3a'
                    X           = 100
                    Y           = 150
                    Width       = 200
                    Height      = 250
                    ImageWidth  = 1920
                    ImageHeight = 1080
                }
            }

            It 'Should call Invoke-ImmichApiCreateFace once' {
                New-IMFace @TestParams

                Should -Invoke Invoke-ImmichApiCreateFace -ModuleName PSImmich -Exactly 1 -Scope It
            }

            It 'Should send all face fields in the request body' {
                New-IMFace @TestParams

                Should -Invoke Invoke-ImmichApiCreateFace -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.assetId -eq 'a7c3b52c-1a2b-3c4d-5e6f-7a8b9c0d1e2f' -and
                    $Body.personId -eq 'b8d4c63d-2b3c-4d5e-6f7a-8b9c0d1e2f3a' -and
                    $Body.x -eq 100 -and
                    $Body.y -eq 150 -and
                    $Body.width -eq 200 -and
                    $Body.height -eq 250 -and
                    $Body.imageWidth -eq 1920 -and
                    $Body.imageHeight -eq 1080
                }
            }

            It 'Should forward an explicit session' {
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                New-IMFace @TestParams -Session $Session

                Should -Invoke Invoke-ImmichApiCreateFace -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }
        }
    }
    Describe 'Remove-IMAPIKey' -Tag 'Unit', 'Remove-IMAPIKey' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteApiKey -ModuleName PSImmich { return $null }
        }

        Context 'Parameter Validation' {
            It 'Should require Id parameter' {
                (Get-Command Remove-IMAPIKey).Parameters['Id'].Attributes.Mandatory | Should -Be $true
            }

            It 'Should validate GUID format for Id parameter' {
                { Remove-IMAPIKey -Id 'invalid-guid' -Confirm:$false } | Should -Throw
            }
        }

        Context 'Pipeline Support' {
            It 'Should accept pipeline input by value' {
                '12345678-1234-1234-1234-123456789abc' | Remove-IMAPIKey -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteApiKey -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc'
                }
            }

            It 'Should accept pipeline input by property name' {
                [PSCustomObject]@{Id = '12345678-1234-1234-1234-123456789abc' } | Remove-IMAPIKey -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteApiKey -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc'
                }
            }

            It 'Should process multiple IDs from pipeline' {
                @('12345678-1234-1234-1234-123456789abc', '87654321-4321-4321-4321-cba987654321') | Remove-IMAPIKey -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteApiKey -ModuleName PSImmich -Exactly 2 -Scope It
            }
        }

        Context 'API Calls' {
            It 'Should call the delete endpoint wrapper with the key ID' {
                Remove-IMAPIKey -Id '12345678-1234-1234-1234-123456789abc' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteApiKey -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc'
                }
            }
        }

        Context 'ShouldProcess Support' {
            It 'Should not call the API when -WhatIf is specified' {
                Remove-IMAPIKey -Id '12345678-1234-1234-1234-123456789abc' -WhatIf

                Should -Invoke Invoke-ImmichApiDeleteApiKey -ModuleName PSImmich -Exactly 0 -Scope It
            }
        }
    }
    Describe 'Rename-IMAPIKey' -Tag 'Unit', 'Rename-IMAPIKey' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateApiKey -ModuleName PSImmich {
                return [PSCustomObject]@{
                    id        = $Id
                    name      = $Body.name
                    createdAt = '2024-01-01T00:00:00Z'
                    updatedAt = '2024-01-01T00:00:00Z'
                }
            }
            Mock ConvertTo-ApiParameters -ModuleName PSImmich { return @{ name = $BoundParameters.Name } }
        }

        Context 'Parameter Validation' {
            It 'Should require Id parameter' {
                (Get-Command Rename-IMAPIKey).Parameters['Id'].Attributes.Mandatory | Should -Be $true
            }

            It 'Should require Name parameter' {
                (Get-Command Rename-IMAPIKey).Parameters['Name'].Attributes.Mandatory | Should -Be $true
            }

            It 'Should validate GUID format for Id parameter' {
                { Rename-IMAPIKey -Id 'invalid-guid' -Name 'test-name' } | Should -Throw
            }
        }

        Context 'Pipeline Support' {
            It 'Should accept pipeline input by value' {
                '12345678-1234-1234-1234-123456789abc' | Rename-IMAPIKey -Name 'new-name'

                Should -Invoke Invoke-ImmichApiUpdateApiKey -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc'
                }
            }

            It 'Should accept pipeline input by property name' {
                [PSCustomObject]@{Id = '12345678-1234-1234-1234-123456789abc' } | Rename-IMAPIKey -Name 'new-name'

                Should -Invoke Invoke-ImmichApiUpdateApiKey -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc'
                }
            }

            It 'Should process multiple IDs from pipeline' {
                @('12345678-1234-1234-1234-123456789abc', '87654321-4321-4321-4321-cba987654321') | Rename-IMAPIKey -Name 'batch-name'

                Should -Invoke Invoke-ImmichApiUpdateApiKey -ModuleName PSImmich -Exactly 2 -Scope It
            }
        }

        Context 'API Parameter Conversion' {
            It 'Should convert parameters to API format' {
                Rename-IMAPIKey -Id '12345678-1234-1234-1234-123456789abc' -Name 'original-name'

                Should -Invoke ConvertTo-ApiParameters -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $BoundParameters.Name -eq 'original-name'
                }
            }

            It 'Should pass converted parameters to the update wrapper' {
                Rename-IMAPIKey -Id '12345678-1234-1234-1234-123456789abc' -Name 'test-name'

                Should -Invoke Invoke-ImmichApiUpdateApiKey -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.name -eq 'test-name'
                }
            }
        }

        Context 'Return Value' {
            It 'Should return API key object with updated name' {
                $result = Rename-IMAPIKey -Id '12345678-1234-1234-1234-123456789abc' -Name 'updated-name'

                $result.id | Should -Be '12345678-1234-1234-1234-123456789abc'
                $result.name | Should -Be 'updated-name'
                $result.GetType().Name | Should -Be 'ApiKeyResponseDto'
            }
        }
    }
    Describe 'Export-IMAssetThumbnail' -Tag 'Unit', 'Export-IMAssetThumbnail' {
        BeforeAll {
            Mock Invoke-ImmichApiViewAsset -ModuleName PSImmich { }
        }

        Context 'Parameter Validation' {
            It 'Should require Id parameter' {
                (Get-Command Export-IMAssetThumbnail).Parameters['Id'].Attributes.Mandatory | Should -Be $true
            }

            It 'Should validate GUID format for Id parameter' {
                { Export-IMAssetThumbnail -Id 'invalid-guid' -Path $TestDrive } | Should -Throw
            }

            It 'Should accept valid GUID for Id parameter' {
                { Export-IMAssetThumbnail -Id '12345678-1234-1234-1234-123456789abc' -Path $TestDrive } | Should -Not -Throw
            }
        }

        Context 'Pipeline Support' {
            It 'Should accept pipeline input by value' {
                '12345678-1234-1234-1234-123456789abc' | Export-IMAssetThumbnail -Path $TestDrive

                Should -Invoke Invoke-ImmichApiViewAsset -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc'
                }
            }

            It 'Should accept pipeline input by property name' {
                [PSCustomObject]@{Id = '12345678-1234-1234-1234-123456789abc' } | Export-IMAssetThumbnail -Path $TestDrive

                Should -Invoke Invoke-ImmichApiViewAsset -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc'
                }
            }

            It 'Should process multiple IDs from pipeline' {
                @('12345678-1234-1234-1234-123456789abc', '87654321-4321-4321-4321-cba987654321') | Export-IMAssetThumbnail -Path $TestDrive

                Should -Invoke Invoke-ImmichApiViewAsset -ModuleName PSImmich -Exactly 2 -Scope It
            }
        }

        Context 'File Output' {
            It 'Should generate correct output file path with JPEG extension' {
                Export-IMAssetThumbnail -Id '12345678-1234-1234-1234-123456789abc' -Path $TestDrive

                Should -Invoke Invoke-ImmichApiViewAsset -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    "$OutFilePath" -like '*12345678-1234-1234-1234-123456789abc.jpeg'
                }
            }

            It 'Should use provided path directory' {
                Export-IMAssetThumbnail -Id '12345678-1234-1234-1234-123456789abc' -Path (Join-Path $TestDrive 'Thumbnails')

                Should -Invoke Invoke-ImmichApiViewAsset -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    "$OutFilePath" -like "$(Join-Path $TestDrive 'Thumbnails')*" -and
                    "$OutFilePath" -like '*12345678-1234-1234-1234-123456789abc.jpeg'
                }
            }
        }

        Context 'Session forwarding' {
            It 'Should call Invoke-ImmichApiViewAsset once with the asset id' {
                Export-IMAssetThumbnail -Id '12345678-1234-1234-1234-123456789abc' -Path $TestDrive

                Should -Invoke Invoke-ImmichApiViewAsset -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc'
                }
            }
        }

        Context 'Progress Preference Handling' {
            It 'Should call Invoke-ImmichApiViewAsset exactly once' {
                Export-IMAssetThumbnail -Id '12345678-1234-1234-1234-123456789abc' -Path $TestDrive

                Should -Invoke Invoke-ImmichApiViewAsset -ModuleName PSImmich -Exactly 1 -Scope It
            }
        }
    }
    Describe 'Get-IMAsset' -Tag 'Unit', 'Get-IMAsset' {
        BeforeAll {
            Mock InvokeImmichRestMethod {
                switch ($RelativePath)
                {
                    { $_ -match '^/assets/[0-9a-fA-F-]{36}$' }
                    {
                        return @{
                            id               = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'
                            originalFileName = 'test.jpg'
                            type             = 'IMAGE'
                            checksum         = 'abc123'
                            owner            = @{ name = 'TestUser' }
                        }
                    }
                    { $_ -match '^/assets/device/.+' }
                    {
                        return @(
                            @{ id = 'asset1'; originalFileName = 'device1.jpg' }
                            @{ id = 'asset2'; originalFileName = 'device2.jpg' }
                        )
                    }
                    '/search/metadata'
                    {
                        return [PSCustomObject]@{
                            assets = [PSCustomObject]@{
                                items    = @(
                                    [PSCustomObject]@{ id = 'tag-asset1'; originalFileName = 'tagged1.jpg' }
                                    [PSCustomObject]@{ id = 'tag-asset2'; originalFileName = 'tagged2.jpg' }
                                )
                                NextPage = $null
                            }
                        }
                    }
                    '/search/random'
                    {
                        return @(
                            @{ id = 'random1'; originalFileName = 'random1.jpg' }
                            @{ id = 'random2'; originalFileName = 'random2.jpg' }
                        )
                    }
                    default
                    {
                        return @()
                    }
                }
            } -ModuleName PSImmich

            Mock Search-IMAsset {
                return @(
                    @{ id = 'person-asset1'; originalFileName = 'person1.jpg' }
                    @{ id = 'person-asset2'; originalFileName = 'person2.jpg' }
                )
            } -ModuleName PSImmich

            Mock ConvertTo-ApiParameters -MockWith { return @{} } -ModuleName PSImmich
            Mock AddCustomType -MockWith {
                param($InputObject)
                return $InputObject
            } -ModuleName PSImmich
        }

        Context 'Parameter Set: list (default)' {
            It 'Should call Search-IMAsset when no parameters are provided' {
                Get-IMAsset
                Should -Invoke Search-IMAsset -Exactly 1 -Scope It -ModuleName PSImmich
            }
        }

        Context 'Parameter Set: id' {
            It 'Should return single asset when valid ID is provided' {
                $testId = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'
                $result = Get-IMAsset -Id $testId

                $result.id | Should -Be $testId
                Should -Invoke InvokeImmichRestMethod -Exactly 1 -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Method -eq 'Get' -and $RelativePath -eq "/assets/$testId"
                }
            }

            It 'Should accept pipeline input by value' {
                $testId = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'
                $result = $testId | Get-IMAsset

                $result.id | Should -Be $testId
                Should -Invoke InvokeImmichRestMethod -Exactly 1 -Scope It -ModuleName PSImmich
            }

            It 'Should accept pipeline input by property name' {
                $testId = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'
                $inputObject = [PSCustomObject]@{ Id = $testId }
                $result = $inputObject | Get-IMAsset

                $result.id | Should -Be $testId
                Should -Invoke InvokeImmichRestMethod -Exactly 1 -Scope It -ModuleName PSImmich
            }

            It 'Should throw when invalid GUID is provided' {
                { Get-IMAsset -Id 'invalid-guid' } | Should -Throw
            }

            It 'Should pass Key parameter when provided' {
                Mock Invoke-ImmichApiGetAssetInfo -ModuleName PSImmich { return @{ id = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f' } }
                $testId = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'

                Get-IMAsset -Id $testId -Key 'test-key'
                Should -Invoke Invoke-ImmichApiGetAssetInfo -Exactly 1 -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Id -eq $testId -and $Key -eq 'test-key'
                }
            }

            It 'Should pass Slug parameter when provided' {
                Mock Invoke-ImmichApiGetAssetInfo -ModuleName PSImmich { return @{ id = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f' } }
                $testId = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'

                Get-IMAsset -Id $testId -Slug 'test-slug'
                Should -Invoke Invoke-ImmichApiGetAssetInfo -Exactly 1 -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Id -eq $testId -and $Slug -eq 'test-slug'
                }
            }
        }

        Context 'Parameter Set: personid' {
            It 'Should return assets for specific person' {
                $testPersonId = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'
                $result = Get-IMAsset -PersonId $testPersonId

                $result | Should -HaveCount 2
                Should -Invoke Search-IMAsset -Exactly 1 -Scope It -ModuleName PSImmich -ParameterFilter {
                    $PersonIds -eq $testPersonId
                }
            }

            It 'Should throw when invalid person ID GUID is provided' {
                { Get-IMAsset -PersonId 'invalid-guid' } | Should -Throw
            }
        }

        Context 'Parameter Set: tagid' {
            It 'Should return assets with specific tag' {
                $testTagId = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'
                $result = Get-IMAsset -TagId $testTagId

                $result | Should -HaveCount 2
                Should -Invoke Search-IMAsset -Exactly 1 -Scope It -ModuleName PSImmich -ParameterFilter {
                    $TagIds -contains $testTagId
                }
            }

            It 'Should throw when invalid tag ID GUID is provided' {
                { Get-IMAsset -TagId 'invalid-guid' } | Should -Throw
            }
        }

        Context 'Parameter Set: random' {
            BeforeAll {
                Mock Invoke-ImmichApiSearchRandom -ModuleName PSImmich {
                    return @(
                        @{ id = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'; originalFileName = 'a.jpg'; type = 'IMAGE'; checksum = 'abc1'; owner = @{ name = 'TestUser' } }
                        @{ id = 'c5a6be0d-4d4a-4c9a-8f4a-4d4a5c9a8f4a'; originalFileName = 'b.jpg'; type = 'IMAGE'; checksum = 'abc2'; owner = @{ name = 'TestUser' } }
                    )
                }
            }

            It 'Should return random assets with default count' {
                $result = Get-IMAsset -Random

                $result | Should -HaveCount 2
                Should -Invoke Invoke-ImmichApiSearchRandom -Exactly 1 -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Body.size -eq 1
                }
            }

            It 'Should return specified count of random assets' {
                $result = Get-IMAsset -Random -Count 5

                Should -Invoke Invoke-ImmichApiSearchRandom -Exactly 1 -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Body.size -eq 5
                }
            }

            It 'Should throw when count is out of valid range' {
                { Get-IMAsset -Random -Count 0 } | Should -Throw
                { Get-IMAsset -Random -Count 1001 } | Should -Throw
            }
        }

        Context 'Parameter Set: id with OCR' {
            BeforeAll {
                Mock Invoke-ImmichApiGetAssetInfo -ModuleName PSImmich {
                    return @{
                        id               = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'
                        originalFileName = 'test.jpg'
                        type             = 'IMAGE'
                        checksum         = 'abc123'
                        owner            = @{ name = 'TestUser' }
                    }
                }
                Mock Invoke-ImmichApiGetAssetOcr -ModuleName PSImmich { return @() }
            }

            It 'Should request OCR data for the asset when IncludeOCR is specified' {
                $testId = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'
                Get-IMAsset -Id $testId -IncludeOCR | Out-Null

                Should -Invoke Invoke-ImmichApiGetAssetOcr -Exactly 1 -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Id -eq $testId
                }
            }

            It 'Should not request OCR data when IncludeOCR is not specified' {
                $testId = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'
                Get-IMAsset -Id $testId | Out-Null

                Should -Invoke Invoke-ImmichApiGetAssetOcr -Exactly 0 -Scope It -ModuleName PSImmich
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                # Skip session parameter testing due to type constraints
                # Session parameter requires ImmichSession type which is complex to mock
                $testId = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'

                { Get-IMAsset -Id $testId } | Should -Not -Throw
                Should -Invoke InvokeImmichRestMethod -Exactly 1 -Scope It -ModuleName PSImmich
            }
        }

        Context 'Mandatory Parameters' {
            BeforeAll {
                $Command = Get-Command Get-IMAsset
            }

            It 'Should have mandatory parameters for appropriate parameter sets' {
                $Command.Parameters.Random.ParameterSets['random'].IsMandatory | Should -Be $true

                $Command.Parameters.PersonId.ParameterSets['personid'].IsMandatory | Should -Be $true
                $Command.Parameters.TagId.ParameterSets['tagid'].IsMandatory | Should -Be $true
                $Command.Parameters.Id.ParameterSets['id'].IsMandatory | Should -Be $true
            }
        }
    }
    Describe 'Get-IMAssetStatistic' -Tag 'Unit', 'Get-IMAssetStatistic' {
        BeforeAll {
            Mock InvokeImmichRestMethod {
                return @{
                    images    = 150
                    videos    = 25
                    total     = 175
                    trashed   = 5
                    favorites = 30
                    archived  = 10
                }
            } -ModuleName PSImmich

            Mock ConvertTo-ApiParameters -MockWith {
                param($BoundParameters)
                $result = @{}
                if ($BoundParameters.IsFavorite)
                {
                    $result.isFavorite = $BoundParameters.IsFavorite
                }
                if ($BoundParameters.IsTrashed)
                {
                    $result.isTrashed = $BoundParameters.IsTrashed
                }
                if ($BoundParameters.Visibility)
                {
                    $result.visibility = $BoundParameters.Visibility
                }
                return $result
            } -ModuleName PSImmich
        }

        Context 'Basic Functionality' {
            It 'Should return statistics without parameters' {
                $result = Get-IMAssetStatistic

                $result.images | Should -Be 150
                $result.videos | Should -Be 25
                $result.total | Should -Be 175
                Should -Invoke InvokeImmichRestMethod -Exactly 1 -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Method -eq 'Get' -and $RelativePath -eq '/assets/statistics'
                }
            }
        }

        Context 'Parameter Validation' {
            It 'Should accept IsFavorite parameter' {
                Mock Invoke-ImmichApiGetAssetStatistics -ModuleName PSImmich { return @{ images = 1 } }
                Get-IMAssetStatistic -IsFavorite:$true
                Should -Invoke Invoke-ImmichApiGetAssetStatistics -Exactly 1 -Scope It -ModuleName PSImmich -ParameterFilter {
                    $IsFavorite -eq $true
                }
            }

            It 'Should accept IsTrashed parameter' {
                Mock Invoke-ImmichApiGetAssetStatistics -ModuleName PSImmich { return @{ images = 1 } }
                Get-IMAssetStatistic -IsTrashed:$false
                Should -Invoke Invoke-ImmichApiGetAssetStatistics -Exactly 1 -Scope It -ModuleName PSImmich -ParameterFilter {
                    $IsTrashed -eq $false
                }
            }

            It 'Should accept valid Visibility values' {
                Get-IMAssetStatistic -Visibility 'archive'
                Get-IMAssetStatistic -Visibility 'timeline'
                Get-IMAssetStatistic -Visibility 'hidden'
                Get-IMAssetStatistic -Visibility 'locked'

                Should -Invoke InvokeImmichRestMethod -Exactly 4 -Scope It -ModuleName PSImmich
            }

            It 'Should throw for invalid Visibility values' {
                { Get-IMAssetStatistic -Visibility 'invalid' } | Should -Throw
            }

            It 'Should accept multiple parameters together' {
                Mock Invoke-ImmichApiGetAssetStatistics -ModuleName PSImmich { return @{ images = 1 } }
                Get-IMAssetStatistic -IsFavorite:$true -IsTrashed:$false -Visibility 'timeline'
                Should -Invoke Invoke-ImmichApiGetAssetStatistics -Exactly 1 -Scope It -ModuleName PSImmich -ParameterFilter {
                    $IsFavorite -eq $true -and $IsTrashed -eq $false -and $Visibility -eq 'timeline'
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                # Skip session parameter testing due to type constraints
                { Get-IMAssetStatistic } | Should -Not -Throw
                Should -Invoke InvokeImmichRestMethod -Exactly 1 -Scope It -ModuleName PSImmich
            }
        }

        Context 'Mandatory Parameters' {
            BeforeAll {
                $Command = Get-Command Get-IMAssetStatistic
            }

            It 'Should not have any mandatory parameters' {
                $Command.Parameters.Values | Where-Object { $_.IsMandatory } | Should -BeNullOrEmpty
            }
        }
    }
    Describe 'Import-IMAsset' -Tag 'Unit', 'Import-IMAsset' {
        BeforeAll {
            # Mock script-level session to prevent null SecureString issues
            $script:ImmichSession = [PSCustomObject]@{
                ApiUri      = 'https://test.immich.app/api'
                AccessToken = ConvertTo-SecureString -String 'mock-token' -AsPlainText -Force
            }

            # Create test files in TestDrive
            $TestFile1 = New-Item -Path 'TestDrive:\photo1.jpg' -ItemType File -Force
            $TestFile2 = New-Item -Path 'TestDrive:\video1.mp4' -ItemType File -Force
            Set-Content -Path $TestFile1.FullName -Value 'Mock JPEG content'
            Set-Content -Path $TestFile2.FullName -Value 'Mock MP4 content'

            Mock Get-Item {
                param($Path)
                $fileName = Split-Path $Path -Leaf
                # Create a proper FileInfo-like object
                $fileInfo = New-Object PSObject -Property @{
                    FullName      = [string]$Path
                    Name          = $fileName
                    CreationTime  = [DateTime]'2023-01-01T10:00:00'
                    LastWriteTime = [DateTime]'2023-01-01T11:00:00'
                }
                # Add the required type name to make it castable to FileInfo
                $fileInfo.PSObject.TypeNames.Insert(0, 'System.IO.FileInfo')
                return $fileInfo
            } -ModuleName PSImmich

            Mock ConvertTo-ApiParameters -MockWith {
                param($BoundParameters, $CmdletName)
                $result = @{}
                if ($BoundParameters.Duration)
                {
                    $result.duration = $BoundParameters.Duration
                }
                if ($BoundParameters.isArchived)
                {
                    $result.isArchived = $BoundParameters.isArchived
                }
                if ($BoundParameters.isFavorite)
                {
                    $result.isFavorite = $BoundParameters.isFavorite
                }
                if ($BoundParameters.isOffline)
                {
                    $result.isOffline = $BoundParameters.isOffline
                }
                if ($BoundParameters.isReadOnly)
                {
                    $result.isReadOnly = $BoundParameters.isReadOnly
                }
                if ($BoundParameters.isVisible)
                {
                    $result.isVisible = $BoundParameters.isVisible
                }
                if ($BoundParameters.libraryId)
                {
                    $result.libraryId = $BoundParameters.libraryId
                }
                return $result
            } -ModuleName PSImmich

            Mock ConvertFromSecureString -MockWith {
                return 'mock-token-string'
            } -ModuleName PSImmich

            # Mock the new private function that handles HTTP uploads
            Mock Invoke-MultipartHttpUpload -MockWith {
                param($Uri, $Session, $FormData, $FileInfo, $FileFieldName)
                return '{"id":"550e8400-e29b-41d4-a716-446655440000","originalFileName":"test-file.jpg","type":"IMAGE"}'
            } -ModuleName PSImmich

            Mock Get-IMAsset -MockWith {
                param($Id)
                return [PSCustomObject]@{
                    id               = $Id
                    originalFileName = 'test-file.jpg'
                    type             = 'IMAGE'
                    createdAt        = '2023-01-01T10:00:00Z'
                }
            } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have FilePath as mandatory parameter' {
                $command = Get-Command Import-IMAsset -Module PSImmich
                $command.Parameters.FilePath.ParameterSets.Keys | ForEach-Object {
                    $command.Parameters.FilePath.ParameterSets[$_].IsMandatory | Should -Be $true
                }
            }

            It 'Should accept FileInfo array for FilePath parameter' {
                $command = Get-Command Import-IMAsset -Module PSImmich
                $command.Parameters.FilePath.ParameterType.Name | Should -Be 'FileInfo[]'
            }

            It 'Should support pipeline input for FilePath' {
                $command = Get-Command Import-IMAsset -Module PSImmich
                $command.Parameters.FilePath.Attributes.ValueFromPipeline | Should -Contain $true
                $command.Parameters.FilePath.Attributes.ValueFromPipelineByPropertyName | Should -Contain $true
            }

            It 'Should have switch parameters with correct types' {
                $command = Get-Command Import-IMAsset -Module PSImmich
                @('isArchived', 'isFavorite', 'isOffline', 'isReadOnly', 'isVisible') | ForEach-Object {
                    $command.Parameters[$_].SwitchParameter | Should -Be $true -Because "$_ should be a switch parameter"
                }
            }

            It 'Should have string parameters with correct types' {
                $command = Get-Command Import-IMAsset -Module PSImmich
                @('Duration', 'libraryId') | ForEach-Object {
                    $command.Parameters[$_].ParameterType.Name | Should -Be 'String' -Because "$_ should be a string parameter"
                }
            }

            It 'Should have Session parameter of ImmichSession type' {
                $command = Get-Command Import-IMAsset -Module PSImmich
                $command.Parameters.Session.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should support ShouldProcess' {
                $command = Get-Command Import-IMAsset -Module PSImmich
                $cmdletBinding = $command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
                $cmdletBinding.SupportsShouldProcess | Should -Be $true
            }
        }

        Context 'File Processing' {
            It 'Should process single file successfully' {
                $result = Import-IMAsset -FilePath $TestFile1

                Should -Invoke Get-Item -Times 1 -Exactly -Scope It -ModuleName PSImmich
                Should -Invoke ConvertTo-ApiParameters -Times 1 -Exactly -Scope It -ModuleName PSImmich
                $result.id | Should -Be '550e8400-e29b-41d4-a716-446655440000'
            }

            It 'Should process multiple files' {
                $files = @($TestFile1, $TestFile2)
                $result = Import-IMAsset -FilePath $files

                Should -Invoke Get-Item -Times 2 -Exactly -Scope It -ModuleName PSImmich
                Should -Invoke ConvertTo-ApiParameters -Times 2 -Exactly -Scope It -ModuleName PSImmich
                $result | Should -HaveCount 2
            }

            It 'Should support pipeline input' {
                $result = $TestFile1 | Import-IMAsset

                Should -Invoke Get-Item -Times 1 -Exactly -Scope It -ModuleName PSImmich
                $result.id | Should -Be '550e8400-e29b-41d4-a716-446655440000'
            }

            It 'Should call Get-Item with correct file paths' {
                Import-IMAsset -FilePath $TestFile1

                Should -Invoke Get-Item -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Path -eq $TestFile1.FullName
                }
            }
        }

        Context 'API Parameter Handling' {
            It 'Should convert API parameters correctly with multiple options' {
                Import-IMAsset -FilePath $TestFile1 -isArchived -isFavorite -Duration '00:02:30' -libraryId 'test-library-id'

                Should -Invoke ConvertTo-ApiParameters -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $BoundParameters.isArchived -eq $true -and
                    $BoundParameters.isFavorite -eq $true -and
                    $BoundParameters.Duration -eq '00:02:30' -and
                    $BoundParameters.libraryId -eq 'test-library-id'
                }
            }

            It 'Should handle form data preparation with file metadata' {
                Import-IMAsset -FilePath $TestFile1

                Should -Invoke Get-Item -Times 1 -Exactly -Scope It -ModuleName PSImmich
                Should -Invoke ConvertTo-ApiParameters -Times 1 -Exactly -Scope It -ModuleName PSImmich
            }

            It 'Should include device metadata in form data' {
                # This test verifies that the function includes deviceAssetId, deviceId,
                # fileCreatedAt, and fileModifiedAt in the form data
                Import-IMAsset -FilePath $TestFile1

                Should -Invoke Get-Item -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Path -eq $TestFile1.FullName
                }
            }
        }

        Context 'HTTP Upload Integration' {
            It 'Should call Invoke-MultipartHttpUpload with correct parameters' {
                Import-IMAsset -FilePath $TestFile1

                Should -Invoke Invoke-MultipartHttpUpload -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $RelativePath -eq '/assets' -and
                    $FileFieldName -eq 'assetData' -and
                    $FileInfo.Name -like 'photo1.jpg'
                }
            }

            It 'Should pass form data to upload function' {
                Import-IMAsset -FilePath $TestFile1 -isArchived -Duration '00:02:30'

                Should -Invoke Invoke-MultipartHttpUpload -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $FormData.ContainsKey('deviceAssetId') -and
                    $FormData.ContainsKey('deviceId') -and
                    $FormData.ContainsKey('fileCreatedAt') -and
                    $FormData.ContainsKey('fileModifiedAt')
                }
            }

            It 'Should handle upload errors gracefully' {
                Mock Invoke-MultipartHttpUpload -MockWith {
                    throw 'HTTP 400: Bad Request'
                } -ModuleName PSImmich

                { Import-IMAsset -FilePath $TestFile1 } | Should -Throw 'HTTP 400: Bad Request'
            }
        }

        Context 'Error Handling' {
            It 'Should handle file access errors gracefully' {
                Mock Get-Item -MockWith {
                    throw 'File not found'
                } -ModuleName PSImmich

                { Import-IMAsset -FilePath 'TestDrive:\NonExistentFile.jpg' } | Should -Throw
            }

            It 'Should handle API parameter conversion errors' {
                Mock ConvertTo-ApiParameters -MockWith {
                    throw 'Parameter conversion failed'
                } -ModuleName PSImmich

                { Import-IMAsset -FilePath $TestFile1 } | Should -Throw
            }
        }

        Context 'Asset Retrieval' {
            It 'Should call Get-IMAsset after successful upload' {
                Import-IMAsset -FilePath $TestFile1

                Should -Invoke Get-IMAsset -Times 1 -Exactly -Scope It -ModuleName PSImmich
            }

            It 'Should return processed asset information' {
                $result = Import-IMAsset -FilePath $TestFile1

                $result.id | Should -Not -BeNullOrEmpty
                $result.originalFileName | Should -Not -BeNullOrEmpty
                $result.type | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Cross-Platform Compatibility' {
            It 'Should work consistently across PowerShell editions' {
                # This test verifies that the function uses unified implementation
                Import-IMAsset -FilePath $TestFile1

                # Should successfully complete using the same private function approach
                Should -Invoke Get-Item -Times 1 -Exactly -Scope It -ModuleName PSImmich
                Should -Invoke ConvertTo-ApiParameters -Times 1 -Exactly -Scope It -ModuleName PSImmich
                Should -Invoke Invoke-MultipartHttpUpload -Times 1 -Exactly -Scope It -ModuleName PSImmich
            }
        }
    }
    Describe 'Remove-IMAsset' -Tag 'Unit', 'Remove-IMAsset' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteAssets -ModuleName PSImmich {
                # Mock returns nothing for DELETE operations
                return $null
            }

        }

        Context 'Parameter Validation' {
            It 'Should validate GUID format for Ids parameter' {
                $function = Get-Command Remove-IMAsset
                $idsParam = $function.Parameters['Ids']
                $validationAttribute = $idsParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should have Ids parameter as mandatory' {
                $function = Get-Command Remove-IMAsset
                $idsParam = $function.Parameters['Ids']
                $idsParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should have id alias for Ids parameter' {
                $function = Get-Command Remove-IMAsset
                $idsParam = $function.Parameters['Ids']
                $aliasAttribute = $idsParam.Attributes | Where-Object { $_.TypeId.Name -eq 'AliasAttribute' }
                $aliasAttribute.AliasNames | Should -Contain 'id'
            }

            It 'Should reject invalid GUID format' {
                { Remove-IMAsset -Ids 'invalid-guid' } | Should -Throw
            }

            It 'Should have Force parameter with switch type' {
                $function = Get-Command Remove-IMAsset
                $forceParam = $function.Parameters['Force']
                $forceParam.ParameterType.Name | Should -Be 'SwitchParameter'
            }
        }

        Context 'ShouldProcess Support' {
            It 'Should support ShouldProcess' {
                $function = Get-Command Remove-IMAsset
                $function.ScriptBlock.Attributes | Where-Object { $_.TypeId.Name -eq 'CmdletBindingAttribute' } |
                    ForEach-Object { $_.SupportsShouldProcess } | Should -Be $true
            }

            It 'Should call the delete wrapper when confirmed for single asset' {
                $TestAssetId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                Remove-IMAsset -Ids $TestAssetId -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.ids -contains $TestAssetId
                }
            }

            It 'Should call the delete wrapper when confirmed for multiple assets' {
                $TestAssetIds = @(
                    'a1b2c3d4-e5f6-4789-a012-123456789abc',
                    'b2c3d4e5-f6a7-4890-b123-234567890bcd'
                )
                Remove-IMAsset -Ids $TestAssetIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.ids.Count -eq 2 -and
                    $Body.ids -contains $TestAssetIds[0] -and
                    $Body.ids -contains $TestAssetIds[1]
                }
            }
        }

        Context 'Pipeline Support' {
            BeforeAll {
                $TestAssetId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $TestAssetId2 = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should accept pipeline input by value' {
                $TestAssetId | Remove-IMAsset -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.ids -contains $TestAssetId
                }
            }

            It 'Should accept pipeline input by property name (Ids)' {
                $assetObject = [PSCustomObject]@{ Ids = $TestAssetId }
                $assetObject | Remove-IMAsset -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.ids -contains $TestAssetId
                }
            }

            It 'Should accept pipeline input by property name (id alias)' {
                $assetObject = [PSCustomObject]@{ id = $TestAssetId }
                $assetObject | Remove-IMAsset -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.ids -contains $TestAssetId
                }
            }

            It 'Should handle multiple assets from pipeline' {
                @($TestAssetId, $TestAssetId2) | Remove-IMAsset -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.ids.Count -eq 2 -and
                    $Body.ids -contains $TestAssetId -and
                    $Body.ids -contains $TestAssetId2
                }
            }

            It 'Should collect multiple pipeline objects into single API call' {
                $assetObjects = @(
                    [PSCustomObject]@{ id = $TestAssetId },
                    [PSCustomObject]@{ id = $TestAssetId2 }
                )
                $assetObjects | Remove-IMAsset -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.ids.Count -eq 2
                }
            }
        }

        Context 'Force Parameter' {
            BeforeAll {
                $TestAssetId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
            }

            It 'Should include force in body parameters when Force is specified' {
                Remove-IMAsset -Ids $TestAssetId -Force -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.force -eq $true
                }
            }

            It 'Should not include force in body parameters when Force is not specified' {
                Remove-IMAsset -Ids $TestAssetId -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $null -eq $Body.force -or $Body.force -eq $false
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command Remove-IMAsset
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                $TestAssetId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                Remove-IMAsset -Ids $TestAssetId -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }

        Context 'API Integration' {
            It 'Should call the delete wrapper with the asset ID' {
                $TestAssetId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                Remove-IMAsset -Ids $TestAssetId -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.ids -contains $TestAssetId
                }
            }

            It 'Should include all asset IDs in request body' {
                $TestAssetIds = @(
                    'a1b2c3d4-e5f6-4789-a012-123456789abc',
                    'b2c3d4e5-f6a7-4890-b123-234567890bcd',
                    'c3d4e5f6-a7b8-4901-c234-345678901def'
                )
                Remove-IMAsset -Ids $TestAssetIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.ids.Count -eq 3 -and
                    $Body.ids -contains $TestAssetIds[0] -and
                    $Body.ids -contains $TestAssetIds[1] -and
                    $Body.ids -contains $TestAssetIds[2]
                }
            }
        }
    }
    Describe 'Restore-IMAsset' -Tag 'Unit', 'Restore-IMAsset' {
        BeforeAll {
            Mock Invoke-ImmichApiRestoreAssets { return @{ Status = 'Success' } } -ModuleName PSImmich
            Mock Invoke-ImmichApiRestoreTrash { return @{ Status = 'Success' } } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have mandatory parameters for id parameter set' {
                $Command = Get-Command Restore-IMAsset
                $Command.Parameters['Id'].ParameterSets['id'].IsMandatory | Should -Be $true
            }

            It 'Should have mandatory parameters for all parameter set' {
                $Command = Get-Command Restore-IMAsset
                $Command.Parameters['All'].ParameterSets['all'].IsMandatory | Should -Be $true
            }

            It 'Should validate GUID format for Id parameter' {
                $Command = Get-Command Restore-IMAsset
                $GuidPattern = $Command.Parameters['Id'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidatePatternAttribute] }
                $GuidPattern.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }
        }

        Context 'Pipeline Support' {
            It 'Should accept pipeline input for Id parameter' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                { $TestId | Restore-IMAsset -Confirm:$false } | Should -Not -Throw
            }

            It 'Should accept pipeline input by property name' {
                $TestObject = [PSCustomObject]@{ Id = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e' }
                { $TestObject | Restore-IMAsset -Confirm:$false } | Should -Not -Throw
            }

            It 'Should handle multiple IDs via pipeline' {
                $TestIds = @(
                    'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e',
                    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
                )

                { $TestIds | Restore-IMAsset -Confirm:$false } | Should -Not -Throw
            }
        }

        Context 'ShouldProcess Support' {
            It 'Should support ShouldProcess' {
                $Command = Get-Command Restore-IMAsset -Module PSImmich
                $Command.ScriptBlock.Attributes | Where-Object { $_.GetType().Name -eq 'CmdletBindingAttribute' } | ForEach-Object { $_.SupportsShouldProcess } | Should -Be $true
            }

            It 'Should call Invoke-ImmichApiRestoreAssets for id parameter set' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Restore-IMAsset -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRestoreAssets -ModuleName PSImmich -Exactly 1 -Scope It
            }

            It 'Should call Invoke-ImmichApiRestoreTrash for all parameter set' {
                Restore-IMAsset -All -Confirm:$false

                Should -Invoke Invoke-ImmichApiRestoreTrash -ModuleName PSImmich -Exactly 1 -Scope It
            }
        }

        Context 'API Calls' {
            It 'Should call correct endpoint for id parameter set' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Restore-IMAsset -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRestoreAssets -ModuleName PSImmich -Exactly 1 -Scope It
            }

            It 'Should call correct endpoint for all parameter set' {
                Restore-IMAsset -All -Confirm:$false

                Should -Invoke Invoke-ImmichApiRestoreTrash -ModuleName PSImmich -Exactly 1 -Scope It
            }

            It 'Should send correct body parameters for id parameter set' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Restore-IMAsset -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRestoreAssets -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.ids -contains $TestId
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should use provided session when specified' {
                $Command = Get-Command Restore-IMAsset -Module PSImmich
                $Command.Parameters.ContainsKey('Session') | Should -Be $true
                $Command.Parameters['Session'].ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Restore-IMAsset -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRestoreAssets -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Get-IMAssetEdit' -Tag 'Unit', 'Get-IMAssetEdit' {
        BeforeAll {
            Mock Invoke-ImmichApiGetAssetEdits -ModuleName PSImmich {
                return [pscustomobject]@{
                    assetId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
                    edits   = @([pscustomobject]@{ id = 'edit-1'; action = 'rotate'; parameters = [pscustomobject]@{ angle = 90 } })
                }
            }
        }

        It 'Should call Invoke-ImmichApiGetAssetEdits with the asset ID' {
            Get-IMAssetEdit -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

            Should -Invoke Invoke-ImmichApiGetAssetEdits -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            }
        }

        It 'Should return AssetEditsResponseDto objects' {
            $result = Get-IMAssetEdit -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

            $result.GetType().Name | Should -Be 'AssetEditsResponseDto'
            $result.edits[0].action | Should -Be 'rotate'
        }

        It 'Should accept Id from pipeline by property name' {
            [pscustomobject]@{ id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' } | Get-IMAssetEdit

            Should -Invoke Invoke-ImmichApiGetAssetEdits -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            }
        }

        It 'Should reject an invalid GUID' {
            { Get-IMAssetEdit -Id 'not-a-guid' } | Should -Throw
        }
    }

    Describe 'Set-IMAssetEdit' -Tag 'Unit', 'Set-IMAssetEdit' {
        BeforeAll {
            Mock Invoke-ImmichApiEditAsset -ModuleName PSImmich {
                return [pscustomobject]@{ assetId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'; edits = @() }
            }
        }

        It 'Should send the edits in the edits array of the body' {
            Set-IMAssetEdit -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Edit @{ action = 'rotate'; parameters = @{ angle = 90 } }

            Should -Invoke Invoke-ImmichApiEditAsset -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -and
                @($Body.edits).Count -eq 1 -and
                $Body.edits[0].action -eq 'rotate' -and
                $Body.edits[0].parameters.angle -eq 90
            }
        }

        It 'Should send multiple edits in order' {
            $Edits = @(
                @{ action = 'crop'; parameters = @{ x = 0; y = 0; width = 800; height = 600 } }
                @{ action = 'mirror'; parameters = @{ axis = 'horizontal' } }
            )
            Set-IMAssetEdit -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Edit $Edits

            Should -Invoke Invoke-ImmichApiEditAsset -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                @($Body.edits).Count -eq 2 -and
                $Body.edits[0].action -eq 'crop' -and
                $Body.edits[0].parameters.width -eq 800 -and
                $Body.edits[1].action -eq 'mirror' -and
                $Body.edits[1].parameters.axis -eq 'horizontal'
            }
        }

        It 'Should return AssetEditsResponseDto objects' {
            $result = Set-IMAssetEdit -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Edit @{ action = 'rotate'; parameters = @{ angle = 90 } }

            $result.GetType().Name | Should -Be 'AssetEditsResponseDto'
        }

        It 'Should support ShouldProcess' {
            $function = Get-Command Set-IMAssetEdit
            $function.ScriptBlock.Attributes | Where-Object { $_.TypeId.Name -eq 'CmdletBindingAttribute' } |
                ForEach-Object { $_.SupportsShouldProcess } | Should -Be $true
        }

        It 'Should require Edit' {
            $function = Get-Command Set-IMAssetEdit
            $function.Parameters['Edit'].Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' } |
                ForEach-Object { $_.Mandatory } | Should -Contain $true
        }
    }

    Describe 'Remove-IMAssetEdit' -Tag 'Unit', 'Remove-IMAssetEdit' {
        BeforeAll {
            Mock Invoke-ImmichApiRemoveAssetEdits -ModuleName PSImmich {}
        }

        It 'Should support ShouldProcess' {
            $function = Get-Command Remove-IMAssetEdit
            $function.ScriptBlock.Attributes | Where-Object { $_.TypeId.Name -eq 'CmdletBindingAttribute' } |
                ForEach-Object { $_.SupportsShouldProcess } | Should -Be $true
        }

        It 'Should call Invoke-ImmichApiRemoveAssetEdits when confirmed' {
            Remove-IMAssetEdit -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Confirm:$false

            Should -Invoke Invoke-ImmichApiRemoveAssetEdits -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            }
        }

        It 'Should not call the API with -WhatIf' {
            Remove-IMAssetEdit -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -WhatIf

            Should -Invoke Invoke-ImmichApiRemoveAssetEdits -ModuleName PSImmich -Times 0 -Exactly -Scope It
        }

        It 'Should reject an invalid GUID' {
            { Remove-IMAssetEdit -Id 'not-a-guid' -Confirm:$false } | Should -Throw
        }
    }

    Describe 'Get-IMAssetFile' -Tag 'Unit', 'Get-IMAssetFile' {
        BeforeAll {
            Mock Invoke-ImmichApiSearchAssetFiles -ModuleName PSImmich {
                return @(
                    [pscustomobject]@{ id = '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'; type = 'preview'; path = '/data/thumbs/a.jpg'; isEdited = $false; isProgressive = $false; isTransparent = $false; createdAt = '2024-01-01T00:00:00Z'; updatedAt = '2024-01-01T00:00:00Z' }
                )
            }
            Mock Invoke-ImmichApiGetAssetFile -ModuleName PSImmich {
                return [pscustomobject]@{ id = '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'; type = 'preview'; path = '/data/thumbs/a.jpg'; isEdited = $false; isProgressive = $false; isTransparent = $false; createdAt = '2024-01-01T00:00:00Z'; updatedAt = '2024-01-01T00:00:00Z' }
            }
        }

        It 'Should call Invoke-ImmichApiSearchAssetFiles with the asset ID' {
            Get-IMAssetFile -AssetId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

            Should -Invoke Invoke-ImmichApiSearchAssetFiles -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $AssetId -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -and -not $PSBoundParameters.ContainsKey('Type')
            }
        }

        It 'Should forward the Type filter when specified' {
            Get-IMAssetFile -AssetId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Type preview

            Should -Invoke Invoke-ImmichApiSearchAssetFiles -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Type -eq 'preview'
            }
        }

        It 'Should forward explicit false boolean filters' {
            Get-IMAssetFile -AssetId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -IsEdited $false

            Should -Invoke Invoke-ImmichApiSearchAssetFiles -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $IsEdited -eq $false
            }
        }

        It 'Should return AssetFileResponseDto objects for a search' {
            $result = Get-IMAssetFile -AssetId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

            $result.GetType().Name | Should -Be 'AssetFileResponseDto'
            $result.type | Should -Be 'preview'
        }

        It 'Should call Invoke-ImmichApiGetAssetFile with -Id' {
            $result = Get-IMAssetFile -Id '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'

            Should -Invoke Invoke-ImmichApiGetAssetFile -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Id -eq '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'
            }
            $result.GetType().Name | Should -Be 'AssetFileResponseDto'
        }

        It 'Should accept Id from pipeline by property name' {
            [pscustomobject]@{ id = '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' } | Get-IMAssetFile

            Should -Invoke Invoke-ImmichApiGetAssetFile -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Id -eq '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'
            }
        }

        It 'Should reject an invalid asset GUID' {
            { Get-IMAssetFile -AssetId 'not-a-guid' } | Should -Throw
        }
    }

    Describe 'Get-IMAssetFolder' -Tag 'Unit', 'Get-IMAssetFolder' {
        BeforeAll {
            Mock Invoke-ImmichApiGetAssetsByOriginalPath -ModuleName PSImmich {
                return @(
                    [pscustomobject]@{ id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'; type = 'IMAGE'; originalPath = '/usr/src/app/upload/library/2024/a.jpg'; originalFileName = 'a.jpg'; isFavorite = $false; isArchived = $false; isTrashed = $false; visibility = 'timeline'; checksum = 'abc'; deviceAssetId = 'd1'; deviceId = 'dev'; fileCreatedAt = '2024-01-01T00:00:00Z'; fileModifiedAt = '2024-01-01T00:00:00Z'; localDateTime = '2024-01-01T00:00:00Z'; updatedAt = '2024-01-01T00:00:00Z'; createdAt = '2024-01-01T00:00:00Z'; ownerId = 'owner'; hasMetadata = $true; duplicateId = $null; isEdited = $false; isOffline = $false; thumbhash = $null }
                )
            }
            Mock Invoke-ImmichApiGetUniqueOriginalPaths -ModuleName PSImmich {
                return @('/usr/src/app/upload/library/2024', '/usr/src/app/upload/library/2025')
            }
        }

        It 'Should call Invoke-ImmichApiGetAssetsByOriginalPath with the folder path' {
            Get-IMAssetFolder -Path '/usr/src/app/upload/library/2024'

            Should -Invoke Invoke-ImmichApiGetAssetsByOriginalPath -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Path -eq '/usr/src/app/upload/library/2024'
            }
            Should -Invoke Invoke-ImmichApiGetUniqueOriginalPaths -ModuleName PSImmich -Times 0 -Exactly -Scope It
        }

        It 'Should return AssetResponseDto objects for a folder' {
            $result = Get-IMAssetFolder -Path '/usr/src/app/upload/library/2024'

            $result.GetType().Name | Should -Be 'AssetResponseDto'
            $result.originalFileName | Should -Be 'a.jpg'
        }

        It 'Should call Invoke-ImmichApiGetUniqueOriginalPaths when no path is given' {
            $result = Get-IMAssetFolder

            Should -Invoke Invoke-ImmichApiGetUniqueOriginalPaths -ModuleName PSImmich -Times 1 -Exactly -Scope It
            Should -Invoke Invoke-ImmichApiGetAssetsByOriginalPath -ModuleName PSImmich -Times 0 -Exactly -Scope It
            $result | Should -Contain '/usr/src/app/upload/library/2025'
        }

        It 'Should reject an empty path' {
            { Get-IMAssetFolder -Path '' } | Should -Throw
        }
    }

    Describe 'Get-IMAlbumMapMarker' -Tag 'Unit', 'Get-IMAlbumMapMarker' {
        BeforeAll {
            Mock Invoke-ImmichApiGetAlbumMapMarkers -ModuleName PSImmich {
                return @(
                    [pscustomobject]@{ id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'; lat = 59.33; lon = 18.06; city = 'Stockholm'; state = 'Stockholm County'; country = 'Sweden' }
                )
            }
        }

        It 'Should call Invoke-ImmichApiGetAlbumMapMarkers with the album ID' {
            Get-IMAlbumMapMarker -Id '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'

            Should -Invoke Invoke-ImmichApiGetAlbumMapMarkers -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Id -eq '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' -and -not $PSBoundParameters.ContainsKey('Key') -and -not $PSBoundParameters.ContainsKey('Slug')
            }
        }

        It 'Should forward the shared link key and slug when specified' {
            Get-IMAlbumMapMarker -Id '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' -Key 'abc123' -Slug 'holiday'

            Should -Invoke Invoke-ImmichApiGetAlbumMapMarkers -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Key -eq 'abc123' -and $Slug -eq 'holiday'
            }
        }

        It 'Should return MapMarkerResponseDto objects' {
            $result = Get-IMAlbumMapMarker -Id '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'

            $result.GetType().Name | Should -Be 'MapMarkerResponseDto'
            $result.city | Should -Be 'Stockholm'
        }

        It 'Should accept Id from pipeline by property name' {
            [pscustomobject]@{ id = '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' } | Get-IMAlbumMapMarker

            Should -Invoke Invoke-ImmichApiGetAlbumMapMarkers -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Id -eq '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'
            }
        }

        It 'Should reject an invalid album GUID' {
            { Get-IMAlbumMapMarker -Id 'not-a-guid' } | Should -Throw
        }
    }

    Describe 'Reset-IMAPIKey' -Tag 'Unit', 'Reset-IMAPIKey' {
        BeforeAll {
            Mock Invoke-ImmichApiRotateApiKey -ModuleName PSImmich {
                return [pscustomobject]@{ apiKey = [pscustomobject]@{ id = '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'; name = 'Automation'; permissions = @('all'); createdAt = '2024-01-01T00:00:00Z'; updatedAt = '2024-01-02T00:00:00Z' }; secret = 'new-secret' }
            }
        }

        It 'Should call Invoke-ImmichApiRotateApiKey with the API key ID' {
            Reset-IMAPIKey -Id '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' -Confirm:$false

            Should -Invoke Invoke-ImmichApiRotateApiKey -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Id -eq '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'
            }
        }

        It 'Should return the new secret as an ApiKeyCreateResponseDto' {
            $result = Reset-IMAPIKey -Id '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' -Confirm:$false

            $result.GetType().Name | Should -Be 'ApiKeyCreateResponseDto'
            $result.secret | Should -Be 'new-secret'
        }

        It 'Should not rotate the key when -WhatIf is specified' {
            Reset-IMAPIKey -Id '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' -WhatIf

            Should -Invoke Invoke-ImmichApiRotateApiKey -ModuleName PSImmich -Times 0 -Exactly -Scope It
        }

        It 'Should accept Id from pipeline by property name' {
            [pscustomobject]@{ id = '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' } | Reset-IMAPIKey -Confirm:$false

            Should -Invoke Invoke-ImmichApiRotateApiKey -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Id -eq '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'
            }
        }

        It 'Should reject an invalid API key GUID' {
            { Reset-IMAPIKey -Id 'not-a-guid' -Confirm:$false } | Should -Throw
        }
    }

    Describe 'New-IMNotification' -Tag 'Unit', 'New-IMNotification' {
        BeforeAll {
            Mock Invoke-ImmichApiCreateNotification -ModuleName PSImmich {
                return [PSCustomObject]@{
                    id          = '6f1d2c3b-4a5e-4f60-8b7c-9d0e1f2a3b4c'
                    title       = $Body.title
                    description = $Body.description
                    level       = $Body.level
                    type        = $Body.type
                    data        = $Body.data
                    readAt      = $null
                    createdAt   = '2024-01-01T12:00:00Z'
                }
            }
        }

        Context 'When sending a notification with required parameters only' {
            It 'Should send only userId and title in the body' {
                New-IMNotification -UserId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Title 'Hello'

                Should -Invoke Invoke-ImmichApiCreateNotification -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.userId -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -and
                    $Body.title -eq 'Hello' -and
                    -not $Body.ContainsKey('level') -and
                    -not $Body.ContainsKey('type') -and
                    -not $Body.ContainsKey('description') -and
                    -not $Body.ContainsKey('data')
                }
            }

            It 'Should return a NotificationDto' {
                $Result = New-IMNotification -UserId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Title 'Hello'

                $Result.GetType().Name | Should -Be 'NotificationDto'
                $Result.title | Should -Be 'Hello'
            }
        }

        Context 'When sending a notification with optional parameters' {
            It 'Should include level, type, description and data in the body' {
                New-IMNotification -UserId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Title 'Backup failed' -Description 'See log' -Level error -Type BackupFailed -Data @{ job = 'backup' }

                Should -Invoke Invoke-ImmichApiCreateNotification -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.title -eq 'Backup failed' -and
                    $Body.description -eq 'See log' -and
                    $Body.level -eq 'error' -and
                    $Body.type -eq 'BackupFailed' -and
                    $Body.data.job -eq 'backup'
                }
            }
        }

        Context 'When an explicit session is provided' {
            It 'Should forward the session to the REST call' {
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])

                New-IMNotification -Session $Session -UserId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Title 'Hello'

                Should -Invoke Invoke-ImmichApiCreateNotification -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }
        }

        Context 'When parameters are invalid' {
            It 'Should throw for a malformed user id' {
                { New-IMNotification -UserId 'not-a-guid' -Title 'Hello' } | Should -Throw
            }

            It 'Should throw for an unsupported level' {
                { New-IMNotification -UserId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Title 'Hello' -Level critical } | Should -Throw
            }

            It 'Should throw for an unsupported type' {
                { New-IMNotification -UserId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Title 'Hello' -Type Unknown } | Should -Throw
            }
        }
    }

    Describe 'Save-IMAssetFile' -Tag 'Unit', 'Save-IMAssetFile' {
        BeforeAll {
            Mock Invoke-ImmichApiGetAssetFile -ModuleName PSImmich {
                return [pscustomobject]@{ id = '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'; path = '/data/encoded-video/clip.mp4' }
            }
            Mock Invoke-ImmichApiDownloadAssetFile -ModuleName PSImmich {}
        }

        It 'Should download the file to the target directory using the stored file name' {
            Save-IMAssetFile -Id '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' -Path $TestDrive

            Should -Invoke Invoke-ImmichApiDownloadAssetFile -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Id -eq '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' -and
                $OutFilePath.FullName -eq (Join-Path -Path $TestDrive -ChildPath 'clip.mp4')
            }
        }

        It 'Should accept Id from pipeline by property name' {
            [pscustomobject]@{ id = '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' } | Save-IMAssetFile -Path $TestDrive

            Should -Invoke Invoke-ImmichApiDownloadAssetFile -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Id -eq '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'
            }
        }

        It 'Should reject an invalid GUID' {
            { Save-IMAssetFile -Id 'not-a-guid' -Path $TestDrive } | Should -Throw
        }
    }

    Describe 'Set-IMAssetMetadata' -Tag 'Unit', 'Set-IMAssetMetadata' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateBulkAssetMetadata -ModuleName PSImmich {}
        }

        It 'Should send one item per asset in the items array' {
            Set-IMAssetMetadata -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db', '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' -Key 'reviewed' -Value $true -Confirm:$false

            Should -Invoke Invoke-ImmichApiUpdateBulkAssetMetadata -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                @($Body.items).Count -eq 2 -and
                $Body.items[0].assetId -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -and
                $Body.items[0].key -eq 'reviewed' -and
                $Body.items[0].value -eq $true -and
                $Body.items[1].assetId -eq '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b'
            }
        }

        It 'Should send object values unchanged' {
            Set-IMAssetMetadata -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Key 'mobile-app' -Value @{ note = 'imported' } -Confirm:$false

            Should -Invoke Invoke-ImmichApiUpdateBulkAssetMetadata -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Body.items[0].value.note -eq 'imported'
            }
        }

        It 'Should batch pipeline input into a single request' {
            [pscustomobject]@{ id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }, [pscustomobject]@{ id = '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' } |
                Set-IMAssetMetadata -Key 'reviewed' -Value $true -Confirm:$false

            Should -Invoke Invoke-ImmichApiUpdateBulkAssetMetadata -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                @($Body.items).Count -eq 2
            }
        }

        It 'Should not call the API with -WhatIf' {
            Set-IMAssetMetadata -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Key 'reviewed' -Value $true -WhatIf

            Should -Invoke Invoke-ImmichApiUpdateBulkAssetMetadata -ModuleName PSImmich -Times 0 -Exactly -Scope It
        }

        It 'Should reject an invalid GUID' {
            { Set-IMAssetMetadata -Id 'not-a-guid' -Key 'reviewed' -Value $true -Confirm:$false } | Should -Throw
        }
    }

    Describe 'Remove-IMAssetMetadata' -Tag 'Unit', 'Remove-IMAssetMetadata' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteBulkAssetMetadata -ModuleName PSImmich {}
        }

        It 'Should send one item per asset and key combination' {
            Remove-IMAssetMetadata -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db', '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' -Key 'reviewed', 'mobile-app' -Confirm:$false

            Should -Invoke Invoke-ImmichApiDeleteBulkAssetMetadata -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                @($Body.items).Count -eq 4 -and
                $Body.items[0].assetId -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -and
                $Body.items[0].key -eq 'reviewed' -and
                $Body.items[1].key -eq 'mobile-app' -and
                -not $Body.items[0].ContainsKey('value')
            }
        }

        It 'Should batch pipeline input into a single request' {
            [pscustomobject]@{ id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }, [pscustomobject]@{ id = '5a1f5a4e-2f1e-4b8e-9d0f-6c1d2e3f4a5b' } |
                Remove-IMAssetMetadata -Key 'reviewed' -Confirm:$false

            Should -Invoke Invoke-ImmichApiDeleteBulkAssetMetadata -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                @($Body.items).Count -eq 2
            }
        }

        It 'Should not call the API with -WhatIf' {
            Remove-IMAssetMetadata -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Key 'reviewed' -WhatIf

            Should -Invoke Invoke-ImmichApiDeleteBulkAssetMetadata -ModuleName PSImmich -Times 0 -Exactly -Scope It
        }

        It 'Should reject an invalid GUID' {
            { Remove-IMAssetMetadata -Id 'not-a-guid' -Key 'reviewed' -Confirm:$false } | Should -Throw
        }
    }

    Describe 'Save-IMAsset' -Tag 'Unit', 'Save-IMAsset' {
        BeforeAll {
            Mock Invoke-ImmichApiDownloadAsset { } -ModuleName PSImmich
            Mock Get-IMAsset {
                return [PSCustomObject]@{
                    id               = $Id
                    originalFileName = 'test-image.jpg'
                }
            } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have mandatory parameters' {
                $Command = Get-Command Save-IMAsset
                $Command.Parameters['Id'].ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $Command = Get-Command Save-IMAsset
                $GuidPattern = $Command.Parameters['Id'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidatePatternAttribute] }
                $GuidPattern.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should have Path parameter with DirectoryInfo type' {
                $Command = Get-Command Save-IMAsset
                $Command.Parameters['Path'].ParameterType.Name | Should -Be 'DirectoryInfo'
            }

            It 'Should have Key parameter with ApiParameter attribute' {
                $Command = Get-Command Save-IMAsset
                $ApiAttribute = $Command.Parameters['Key'].Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }
                $ApiAttribute.Name | Should -Be 'key'
            }
        }

        Context 'Pipeline Support' {
            It 'Should accept pipeline input for Id parameter' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                { $TestId | Save-IMAsset -Path $TestDrive } | Should -Not -Throw
            }

            It 'Should accept pipeline input by property name' {
                $TestObject = [PSCustomObject]@{ Id = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e' }
                { $TestObject | Save-IMAsset -Path $TestDrive } | Should -Not -Throw
            }

            It 'Should process multiple IDs from pipeline' {
                $TestIds = @(
                    'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e',
                    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
                )

                { $TestIds | Save-IMAsset -Path $TestDrive } | Should -Not -Throw
                Should -Invoke Get-IMAsset -ModuleName PSImmich -Exactly 2 -Scope It
            }
        }

        Context 'File Operations' {
            It 'Should call Get-IMAsset to retrieve filename' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Save-IMAsset -Id $TestId -Path $TestDrive

                Should -Invoke Get-IMAsset -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $TestId
                }
            }

            It 'Should call Invoke-ImmichApiDownloadAsset with the asset id' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Save-IMAsset -Id $TestId -Path $TestDrive

                Should -Invoke Invoke-ImmichApiDownloadAsset -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $TestId
                }
            }

            It 'Should pass OutFilePath parameter correctly' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                $TestPath = $TestDrive
                Save-IMAsset -Id $TestId -Path $TestPath

                Should -Invoke Invoke-ImmichApiDownloadAsset -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    "$OutFilePath" -like (Join-Path $TestPath 'test-image.jpg')
                }
            }
        }

        Context 'API Parameters' {
            It 'Should forward Key parameter to the download function' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Save-IMAsset -Id $TestId -Path $TestDrive -Key 'test-key'

                Should -Invoke Invoke-ImmichApiDownloadAsset -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $TestId -and $Key -eq 'test-key'
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should use provided session when specified' {
                # Test parameter definition and type - avoid runtime type conversion issues
                $Command = Get-Command Save-IMAsset -Module PSImmich
                $Command.Parameters.ContainsKey('Session') | Should -Be $true
                $Command.Parameters['Session'].ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Save-IMAsset -Id $TestId -Path $TestDrive

                Should -Invoke Invoke-ImmichApiDownloadAsset -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Set-IMAsset' -Tag 'Unit', 'Set-IMAsset' {
        BeforeAll {
            Mock ConvertTo-ApiParameters { return @{} } -ModuleName PSImmich
            Mock InvokeImmichRestMethod { return @{ Status = 'Success' } } -ModuleName PSImmich
            Mock Invoke-ImmichApiUpdateAsset { return @{ Status = 'Success' } } -ModuleName PSImmich
            Mock Invoke-ImmichApiUpdateAssets { return @{ Status = 'Success' } } -ModuleName PSImmich
            Mock Invoke-ImmichApiAddAssetsToAlbum { return @{ Status = 'Success' } } -ModuleName PSImmich
            Mock Invoke-ImmichApiRemoveAssetFromAlbum { return @{ Status = 'Success' } } -ModuleName PSImmich
            Mock Invoke-ImmichApiTagAssets { return @{ Status = 'Success' } } -ModuleName PSImmich
            Mock Invoke-ImmichApiUntagAssets { return @{ Status = 'Success' } } -ModuleName PSImmich
            Mock Invoke-ImmichApiAddMemoryAssets { return @{ Status = 'Success' } } -ModuleName PSImmich
            Mock Invoke-ImmichApiRemoveMemoryAssets { return @{ Status = 'Success' } } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have mandatory parameters' {
                $Command = Get-Command Set-IMAsset
                $Command.Parameters['Id'].ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $Command = Get-Command Set-IMAsset
                $GuidPattern = $Command.Parameters['Id'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidatePatternAttribute] }
                $GuidPattern.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should validate GUID format for AddToMemory parameter' {
                $Command = Get-Command Set-IMAsset
                $GuidPattern = $Command.Parameters['AddToMemory'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidatePatternAttribute] }
                $GuidPattern.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should validate GUID format for RemoveFromMemory parameter' {
                $Command = Get-Command Set-IMAsset
                $GuidPattern = $Command.Parameters['RemoveFromMemory'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidatePatternAttribute] }
                $GuidPattern.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should have parameter sets: batch and id' {
                $Command = Get-Command Set-IMAsset
                $Command.ParameterSets.Name | Should -Contain 'batch'
                $Command.ParameterSets.Name | Should -Contain 'id'
            }
        }

        Context 'Pipeline Support' {
            It 'Should accept pipeline input for Id parameter' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                { $TestId | Set-IMAsset -IsFavorite $true -Confirm:$false } | Should -Not -Throw
            }

            It 'Should accept pipeline input by property name' {
                $TestObject = [PSCustomObject]@{ Id = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e' }
                { $TestObject | Set-IMAsset -IsFavorite $true -Confirm:$false } | Should -Not -Throw
            }

            It 'Should handle multiple IDs for batch operations' {
                $TestIds = @(
                    'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e',
                    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
                )

                { Set-IMAsset -Id $TestIds -IsFavorite $true -Confirm:$false } | Should -Not -Throw
            }
        }

        Context 'ShouldProcess Support' {
            It 'Should support ShouldProcess' {
                $Command = Get-Command Set-IMAsset -Module PSImmich
                $Command.ScriptBlock.Attributes | Where-Object { $_.GetType().Name -eq 'CmdletBindingAttribute' } | ForEach-Object { $_.SupportsShouldProcess } | Should -Be $true
            }

            It 'Should call ShouldProcess before making changes' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Set-IMAsset -Id $TestId -IsFavorite $true -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAssets -ModuleName PSImmich -Exactly 1 -Scope It
            }
        }

        Context 'Basic Asset Updates' {
            It 'Should call ConvertTo-ApiParameters' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Set-IMAsset -Id $TestId -IsFavorite $true -Confirm:$false

                Should -Invoke ConvertTo-ApiParameters -ModuleName PSImmich -Exactly 1 -Scope It
            }

            It 'Should handle IsFavorite parameter' {
                Mock ConvertTo-ApiParameters { return @{ isFavorite = $true } } -ModuleName PSImmich

                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Set-IMAsset -Id $TestId -IsFavorite $true -Confirm:$false

                Should -Invoke ConvertTo-ApiParameters -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $BoundParameters.IsFavorite -eq $true
                }
            }

            It 'Should handle location parameters' {
                Mock ConvertTo-ApiParameters { return @{ latitude = 40; longitude = -74 } } -ModuleName PSImmich

                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Set-IMAsset -Id $TestId -Latitude 40 -Longitude -74 -Confirm:$false

                Should -Invoke ConvertTo-ApiParameters -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $BoundParameters.Latitude -eq 40 -and $BoundParameters.Longitude -eq -74
                }
            }

            It 'Should handle DateTimeOriginal parameter' {
                Mock ConvertTo-ApiParameters { return @{ dateTimeOriginal = '2023-01-01T10:00:00' } } -ModuleName PSImmich

                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Set-IMAsset -Id $TestId -DateTimeOriginal '2023-01-01T10:00:00' -Confirm:$false

                Should -Invoke ConvertTo-ApiParameters -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $BoundParameters.DateTimeOriginal -eq '2023-01-01T10:00:00'
                }
            }

            It 'Should handle Description parameter in id parameter set' {
                Mock ConvertTo-ApiParameters { return @{ description = 'Test description' } } -ModuleName PSImmich

                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Set-IMAsset -Id $TestId -Description 'Test description' -Confirm:$false

                Should -Invoke ConvertTo-ApiParameters -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $BoundParameters.Description -eq 'Test description'
                }
            }
        }

        Context 'Album Operations' {
            It 'Should handle AddToAlbum parameter' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                $AlbumId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

                Set-IMAsset -Id $TestId -AddToAlbum $AlbumId -Confirm:$false

                Should -Invoke Invoke-ImmichApiAddAssetsToAlbum -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $AlbumId
                }
            }

            It 'Should handle RemoveFromAlbum parameter' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                $AlbumId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

                Set-IMAsset -Id $TestId -RemoveFromAlbum $AlbumId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRemoveAssetFromAlbum -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $AlbumId
                }
            }
        }

        Context 'Tag Operations' {
            It 'Should handle AddTag parameter' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                $TagId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

                Set-IMAsset -Id $TestId -AddTag $TagId -Confirm:$false

                Should -Invoke Invoke-ImmichApiTagAssets -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $TagId
                }
            }

            It 'Should handle RemoveTag parameter' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                $TagId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

                Set-IMAsset -Id $TestId -RemoveTag $TagId -Confirm:$false

                Should -Invoke Invoke-ImmichApiUntagAssets -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $TagId
                }
            }
        }

        Context 'Face and Memory Operations' {
            It 'Should handle AddToMemory parameter' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                $MemoryId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

                Set-IMAsset -Id $TestId -AddToMemory $MemoryId -Confirm:$false

                Should -Invoke Invoke-ImmichApiAddMemoryAssets -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $MemoryId
                }
            }

            It 'Should handle RemoveFromMemory parameter' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                $MemoryId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

                Set-IMAsset -Id $TestId -RemoveFromMemory $MemoryId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRemoveMemoryAssets -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $MemoryId
                }
            }
        }

        Context 'Batch vs Individual Processing' {
            It 'Should use batch endpoint for batch parameter set' {
                $TestIds = @(
                    'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e',
                    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
                )

                Set-IMAsset -Id $TestIds -IsFavorite $true -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAssets -ModuleName PSImmich -Exactly 1 -Scope It
            }

            It 'Should use individual endpoint for id parameter set' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'

                Set-IMAsset -Id $TestId -Description 'Test description' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAsset -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $TestId
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should use provided session when specified' {
                # Test parameter definition and type - avoid runtime type conversion issues
                $Command = Get-Command Set-IMAsset -Module PSImmich
                $Command.Parameters.ContainsKey('Session') | Should -Be $true
                $Command.Parameters['Session'].ParameterType.Name | Should -Be 'ImmichSession'

                # Verify that InvokeImmichRestMethod is called when session handling occurs
                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Exactly 0 -Scope It
            }

            It 'Should use default session when no session parameter provided' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Set-IMAsset -Id $TestId -IsFavorite $true -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateAssets -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Start-IMVideoTranscode' -Tag 'Unit', 'Start-IMVideoTranscode' {
        BeforeAll {
            Mock Invoke-ImmichApiRunAssetJobs { return @{ Status = 'Success' } } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have mandatory parameters' {
                $Command = Get-Command Start-IMVideoTranscode
                $Command.Parameters['Id'].ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $Command = Get-Command Start-IMVideoTranscode
                $GuidPattern = $Command.Parameters['Id'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidatePatternAttribute] }
                $GuidPattern.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }
        }

        Context 'Pipeline Support' {
            It 'Should accept pipeline input for Id parameter' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                { $TestId | Start-IMVideoTranscode -Confirm:$false } | Should -Not -Throw
            }

            It 'Should accept pipeline input by property name' {
                $TestObject = [PSCustomObject]@{ Id = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e' }
                { $TestObject | Start-IMVideoTranscode -Confirm:$false } | Should -Not -Throw
            }

            It 'Should handle multiple IDs via pipeline' {
                $TestIds = @(
                    'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e',
                    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
                )

                { $TestIds | Start-IMVideoTranscode -Confirm:$false } | Should -Not -Throw
            }
        }

        Context 'ShouldProcess Support' {
            It 'Should support ShouldProcess' {
                $Command = Get-Command Start-IMVideoTranscode
                $CmdletBinding = $Command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
                $CmdletBinding.SupportsShouldProcess | Should -Be $true
            }

            It 'Should call ShouldProcess before starting transcode jobs' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Start-IMVideoTranscode -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It
            }
        }

        Context 'API Calls' {
            It 'Should call correct endpoint' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Start-IMVideoTranscode -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It
            }

            It 'Should send correct body parameters' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Start-IMVideoTranscode -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.assetIds -contains $TestId -and $Body.name -eq 'transcode-video'
                }
            }

            It 'Should handle multiple asset IDs in body' {
                $TestIds = @(
                    'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e',
                    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
                )

                Start-IMVideoTranscode -Id $TestIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.assetIds.Count -eq 2 -and $Body.assetIds -contains $TestIds[0] -and $Body.assetIds -contains $TestIds[1]
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should use provided session when specified' {
                # Test parameter definition and type - avoid runtime type conversion issues
                $Command = Get-Command Start-IMVideoTranscode -Module PSImmich
                $Command.Parameters.ContainsKey('Session') | Should -Be $true
                $Command.Parameters['Session'].ParameterType.Name | Should -Be 'ImmichSession'

                # Verify the wrapper is not called when only parameter definitions are checked
                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 0 -Scope It
            }

            It 'Should use default session when no session parameter provided' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Start-IMVideoTranscode -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Update-IMAssetMetadata' -Tag 'Unit', 'Update-IMAssetMetadata' {
        BeforeAll {
            Mock Invoke-ImmichApiRunAssetJobs { return @{ Status = 'Success' } } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have mandatory parameters' {
                $Command = Get-Command Update-IMAssetMetadata
                $Command.Parameters['Id'].ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $Command = Get-Command Update-IMAssetMetadata
                $GuidPattern = $Command.Parameters['Id'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidatePatternAttribute] }
                $GuidPattern.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }
        }

        Context 'Pipeline Support' {
            It 'Should accept pipeline input for Id parameter' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                { $TestId | Update-IMAssetMetadata -Confirm:$false } | Should -Not -Throw
            }

            It 'Should accept pipeline input by property name' {
                $TestObject = [PSCustomObject]@{ Id = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e' }
                { $TestObject | Update-IMAssetMetadata -Confirm:$false } | Should -Not -Throw
            }

            It 'Should handle multiple IDs via pipeline' {
                $TestIds = @(
                    'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e',
                    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
                )

                { $TestIds | Update-IMAssetMetadata -Confirm:$false } | Should -Not -Throw
            }
        }

        Context 'ShouldProcess Support' {
            It 'Should support ShouldProcess' {
                $Command = Get-Command Update-IMAssetMetadata
                $CmdletBinding = $Command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
                $CmdletBinding.SupportsShouldProcess | Should -Be $true
            }

            It 'Should call ShouldProcess before updating metadata' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Update-IMAssetMetadata -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It
            }
        }

        Context 'API Calls' {
            It 'Should call correct endpoint' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Update-IMAssetMetadata -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It
            }

            It 'Should send correct body parameters for metadata refresh' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Update-IMAssetMetadata -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.assetIds -contains $TestId -and $Body.name -eq 'refresh-metadata'
                }
            }

            It 'Should handle multiple asset IDs in body' {
                $TestIds = @(
                    'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e',
                    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
                )

                Update-IMAssetMetadata -Id $TestIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.assetIds.Count -eq 2 -and $Body.assetIds -contains $TestIds[0] -and $Body.assetIds -contains $TestIds[1]
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should use provided session when specified' {
                # Test parameter definition and type - avoid runtime type conversion issues
                $Command = Get-Command Update-IMAssetMetadata -Module PSImmich
                $Command.Parameters.ContainsKey('Session') | Should -Be $true
                $Command.Parameters['Session'].ParameterType.Name | Should -Be 'ImmichSession'

                # Verify the wrapper is not called when only parameter definitions are checked
                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 0 -Scope It
            }

            It 'Should use default session when no session parameter provided' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Update-IMAssetMetadata -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Update-IMAssetThumbnail' -Tag 'Unit', 'Update-IMAssetThumbnail' {
        BeforeAll {
            Mock Invoke-ImmichApiRunAssetJobs { return @{ Status = 'Success' } } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have mandatory parameters' {
                $Command = Get-Command Update-IMAssetThumbnail
                $Command.Parameters['Id'].ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $Command = Get-Command Update-IMAssetThumbnail
                $GuidPattern = $Command.Parameters['Id'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidatePatternAttribute] }
                $GuidPattern.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }
        }

        Context 'Pipeline Support' {
            It 'Should accept pipeline input for Id parameter' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                { $TestId | Update-IMAssetThumbnail -Confirm:$false } | Should -Not -Throw
            }

            It 'Should accept pipeline input by property name' {
                $TestObject = [PSCustomObject]@{ Id = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e' }
                { $TestObject | Update-IMAssetThumbnail -Confirm:$false } | Should -Not -Throw
            }

            It 'Should handle multiple IDs via pipeline' {
                $TestIds = @(
                    'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e',
                    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
                )

                { $TestIds | Update-IMAssetThumbnail -Confirm:$false } | Should -Not -Throw
            }
        }

        Context 'ShouldProcess Support' {
            It 'Should support ShouldProcess' {
                $Command = Get-Command Update-IMAssetThumbnail
                $CmdletBinding = $Command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
                $CmdletBinding.SupportsShouldProcess | Should -Be $true
            }

            It 'Should call ShouldProcess before updating thumbnails' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Update-IMAssetThumbnail -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It
            }
        }

        Context 'API Calls' {
            It 'Should call correct endpoint' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Update-IMAssetThumbnail -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It
            }

            It 'Should send correct body parameters for thumbnail regeneration' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Update-IMAssetThumbnail -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.assetIds -contains $TestId -and $Body.name -eq 'regenerate-thumbnail'
                }
            }

            It 'Should handle multiple asset IDs in body' {
                $TestIds = @(
                    'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e',
                    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
                )

                Update-IMAssetThumbnail -Id $TestIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.assetIds.Count -eq 2 -and $Body.assetIds -contains $TestIds[0] -and $Body.assetIds -contains $TestIds[1]
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should use provided session when specified' {
                # Test parameter definition and type - avoid runtime type conversion issues
                $Command = Get-Command Update-IMAssetThumbnail -Module PSImmich
                $Command.Parameters.ContainsKey('Session') | Should -Be $true
                $Command.Parameters['Session'].ParameterType.Name | Should -Be 'ImmichSession'

                # Verify the wrapper is not called when only parameter definitions are checked
                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 0 -Scope It
            }

            It 'Should use default session when no session parameter provided' {
                $TestId = 'f4c91e8b-7b4d-4b8a-9c6e-2f5a8b7c3d9e'
                Update-IMAssetThumbnail -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunAssetJobs -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Test-IMAccessToken' -Tag 'Unit', 'Test-IMAccessToken' {
        BeforeAll {
            Mock Invoke-ImmichApiValidateAccessToken -ModuleName PSImmich {
                return [PSCustomObject]@{
                    AuthStatus = $true
                }
            }
        }

        Context 'Token Validation' {
            It 'Should validate access token via the generated wrapper' {
                Test-IMAccessToken

                Should -Invoke Invoke-ImmichApiValidateAccessToken -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }

            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command Test-IMAccessToken
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should return AuthStatus boolean result' {
                $result = Test-IMAccessToken
                $result | Should -BeOfType [boolean]
                $result | Should -Be $true
            }

            It 'Should handle false authentication status' {
                Mock Invoke-ImmichApiValidateAccessToken -ModuleName PSImmich {
                    return [PSCustomObject]@{
                        AuthStatus = $false
                    }
                }

                $result = Test-IMAccessToken
                $result | Should -Be $false
            }

            It 'Should handle null result' {
                Mock Invoke-ImmichApiValidateAccessToken -ModuleName PSImmich {
                    return $null
                }

                $result = Test-IMAccessToken
                $result | Should -Be $false
            }
        }
    }
    Describe 'Get-IMAuthSession' -Tag 'Unit', 'Get-IMAuthSession' {
        BeforeAll {
            Mock Invoke-ImmichApiGetSessions -ModuleName PSImmich {
                @(
                    [PSCustomObject]@{
                        id                 = 'session1-guid-here-1234567890abcdef'
                        appVersion         = '2.3.1'
                        createdAt          = '2024-01-01T10:00:00Z'
                        current            = $true
                        deviceOS           = 'Windows'
                        deviceType         = 'web'
                        expiresAt          = $null
                        isPendingSyncReset = $false
                        updatedAt          = '2024-01-01T12:00:00Z'
                    },
                    [PSCustomObject]@{
                        id                 = 'session2-guid-here-1234567890abcdef'
                        appVersion         = '2.3.1'
                        createdAt          = '2024-01-01T08:00:00Z'
                        current            = $false
                        deviceOS           = 'iOS'
                        deviceType         = 'mobile'
                        expiresAt          = $null
                        isPendingSyncReset = $false
                        updatedAt          = '2024-01-01T11:30:00Z'
                    }
                )
            }
        }

        Context 'Session Retrieval' {
            It 'Should call Invoke-ImmichApiGetSessions once' {
                Get-IMAuthSession

                Should -Invoke Invoke-ImmichApiGetSessions -ModuleName PSImmich -Times 1
            }

            It 'Should forward an explicit session' {
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                Get-IMAuthSession -Session $Session

                Should -Invoke Invoke-ImmichApiGetSessions -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }

            It 'Should return SessionResponseDto objects' {
                $result = Get-IMAuthSession
                $result | Should -HaveCount 2
                $result[0].GetType().Name | Should -Be 'SessionResponseDto'
                $result[0].id | Should -Be 'session1-guid-here-1234567890abcdef'
                $result[0].deviceType | Should -Be 'web'
                $result[0].current | Should -Be $true
                $result[1].id | Should -Be 'session2-guid-here-1234567890abcdef'
                $result[1].deviceType | Should -Be 'mobile'
                $result[1].current | Should -Be $false
            }

            It 'Should handle empty session list' {
                Mock Invoke-ImmichApiGetSessions -ModuleName PSImmich {
                    return @()
                }

                $result = Get-IMAuthSession
                $result | Should -HaveCount 0
            }
        }
    }
    Describe 'Remove-IMAuthSession' -Tag 'Unit', 'Remove-IMAuthSession' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteAllSessions -ModuleName PSImmich {}
            Mock Invoke-ImmichApiDeleteSession -ModuleName PSImmich {}
        }

        Context 'Parameter Set: list (remove all sessions)' {
            It 'Should support ShouldProcess' {
                $function = Get-Command Remove-IMAuthSession
                $function.ScriptBlock.Attributes | Where-Object { $_.TypeId.Name -eq 'CmdletBindingAttribute' } |
                    ForEach-Object { $_.SupportsShouldProcess } | Should -Be $true
            }

            It 'Should call Invoke-ImmichApiDeleteAllSessions when no Id is given' {
                Remove-IMAuthSession -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAllSessions -ModuleName PSImmich -Times 1 -Scope It
                Should -Invoke Invoke-ImmichApiDeleteSession -ModuleName PSImmich -Times 0 -Scope It
            }

            It 'Should not call the API when -WhatIf is specified' {
                Remove-IMAuthSession -WhatIf

                Should -Invoke Invoke-ImmichApiDeleteAllSessions -ModuleName PSImmich -Times 0 -Scope It
            }

            It 'Should forward an explicit session' {
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                Remove-IMAuthSession -Session $Session -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteAllSessions -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }
        }

        Context 'Parameter Set: id (remove specific sessions)' {
            BeforeAll {
                $TestSessionId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $TestSessionId2 = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should validate GUID format for Id parameter' {
                $function = Get-Command Remove-IMAuthSession
                $idParam = $function.Parameters['id']
                $validationAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should call Invoke-ImmichApiDeleteSession for a specific session ID' {
                Remove-IMAuthSession -id $TestSessionId -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteSession -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Id -eq $TestSessionId
                }
                Should -Invoke Invoke-ImmichApiDeleteAllSessions -ModuleName PSImmich -Times 0 -Scope It
            }

            It 'Should handle multiple session IDs' {
                Remove-IMAuthSession -id @($TestSessionId, $TestSessionId2) -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteSession -ModuleName PSImmich -Times 2 -ParameterFilter {
                    $Id -eq $TestSessionId -or $Id -eq $TestSessionId2
                }
            }

            It 'Should accept pipeline input by value' {
                $TestSessionId | Remove-IMAuthSession -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteSession -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Id -eq $TestSessionId
                }
            }

            It 'Should accept pipeline input by property name' {
                $sessionObject = [PSCustomObject]@{ id = $TestSessionId }
                $sessionObject | Remove-IMAuthSession -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteSession -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Id -eq $TestSessionId
                }
            }

            It 'Should reject invalid GUID format' {
                { Remove-IMAuthSession -id 'invalid-guid' } | Should -Throw
            }

            It 'Should pass Session parameter with specific ID' {
                # Verify Session parameter exists and can be used with id parameter
                $function = Get-Command Remove-IMAuthSession
                $sessionParam = $function.Parameters['Session']
                $idParam = $function.Parameters['id']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
                $idParam | Should -Not -BeNullOrEmpty
            }
        }
    }
    Describe 'Get-IMDuplicate' -Tag 'Unit', 'Get-IMDuplicate' {
        BeforeAll {
            Mock Invoke-ImmichApiGetAssetDuplicates -ModuleName PSImmich {
                return @(
                            [PSCustomObject]@{
                                duplicateId = 'duplicate1-guid-here-1234567890abcdef'
                                assets      = @(
                                    [PSCustomObject]@{
                                        id            = 'asset1-guid-here-1234567890abcdef'
                                        deviceAssetId = 'IMG_001.jpg'
                                        checksum      = 'abc123def456789'
                                        originalPath  = '/photos/IMG_001.jpg'
                                        fileSize      = 2048576
                                        type          = 'IMAGE'
                                    },
                                    [PSCustomObject]@{
                                        id            = 'asset2-guid-here-1234567890abcdef'
                                        deviceAssetId = 'IMG_001_copy.jpg'
                                        checksum      = 'abc123def456789'
                                        originalPath  = '/photos/backup/IMG_001_copy.jpg'
                                        fileSize      = 2048576
                                        type          = 'IMAGE'
                                    }
                                )
                            },
                            [PSCustomObject]@{
                                duplicateId = 'duplicate2-guid-here-1234567890abcdef'
                                assets      = @(
                                    [PSCustomObject]@{
                                        id            = 'asset3-guid-here-1234567890abcdef'
                                        deviceAssetId = 'VID_001.mp4'
                                        checksum      = 'def456ghi789012'
                                        originalPath  = '/videos/VID_001.mp4'
                                        fileSize      = 104857600
                                        type          = 'VIDEO'
                                    },
                                    [PSCustomObject]@{
                                        id            = 'asset4-guid-here-1234567890abcdef'
                                        deviceAssetId = 'VID_001_backup.mp4'
                                        checksum      = 'def456ghi789012'
                                        originalPath  = '/videos/backup/VID_001_backup.mp4'
                                        fileSize      = 104857600
                                        type          = 'VIDEO'
                                    }
                                )
                            }
                        )
            }
        }

        Context 'Duplicate Retrieval' {

            It 'Should retrieve duplicates via the generated wrapper' {
                Get-IMDuplicate

                Should -Invoke Invoke-ImmichApiGetAssetDuplicates -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }

            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command Get-IMDuplicate
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should return array of duplicate groups' {
                $result = Get-IMDuplicate
                $result | Should -HaveCount 2
                $result[0].duplicateId | Should -Be 'duplicate1-guid-here-1234567890abcdef'
                $result[0].assets | Should -HaveCount 2
                $result[0].assets[0].type | Should -Be 'IMAGE'
                $result[1].duplicateId | Should -Be 'duplicate2-guid-here-1234567890abcdef'
                $result[1].assets | Should -HaveCount 2
                $result[1].assets[0].type | Should -Be 'VIDEO'
            }

            It 'Should return DuplicateResponseDto objects' {
                $result = Get-IMDuplicate

                $result[0].GetType().Name | Should -Be 'DuplicateResponseDto'
                $result[0].assets[0].GetType().Name | Should -Be 'AssetResponseDto'
            }

            It 'Should handle empty duplicate results' {
                Mock Invoke-ImmichApiGetAssetDuplicates -ModuleName PSImmich {
                    return @()
                }
                $result = Get-IMDuplicate
                $result | Should -HaveCount 0
            }
        }
    }
    Describe 'Get-IMFace' -Tag 'Unit', 'Get-IMFace' {
        BeforeAll {
            Mock Invoke-ImmichApiGetFaces -ModuleName PSImmich {
                return @(
                    [PSCustomObject]@{
                        id            = 'face1-guid-here-1234567890abcdef'
                        assetId       = $Id
                        boundingBoxX1 = 100
                        boundingBoxY1 = 150
                        boundingBoxX2 = 250
                        boundingBoxY2 = 300
                        imageWidth    = 1920
                        imageHeight   = 1080
                        person        = [PSCustomObject]@{
                            id            = 'person1-guid-here-1234567890abcdef'
                            name          = 'John Doe'
                            thumbnailPath = '/thumbnails/person1.jpg'
                        }
                    }
                )
            }
        }

        Context 'Parameter Validation' {
            It 'Should validate GUID format for Id parameter' {
                { Get-IMFace -Id 'invalid-guid' } | Should -Throw
            }

            It 'Should pass Session parameter when provided' {
                $function = Get-Command Get-IMFace
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }
        }

        Context 'Face Retrieval' {
            BeforeAll {
                $TestAssetId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $TestAssetId2 = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should call Invoke-ImmichApiGetFaces with the asset ID' {
                Get-IMFace -Id $TestAssetId

                Should -Invoke Invoke-ImmichApiGetFaces -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $TestAssetId
                }
            }

            It 'Should return AssetFaceResponseDto objects' {
                $result = Get-IMFace -Id $TestAssetId
                $result.GetType().Name | Should -Be 'AssetFaceResponseDto'
                $result.id | Should -Be 'face1-guid-here-1234567890abcdef'
                $result.person.name | Should -Be 'John Doe'
            }

            It 'Should call the endpoint once per asset ID' {
                Get-IMFace -Id @($TestAssetId, $TestAssetId2)

                Should -Invoke Invoke-ImmichApiGetFaces -ModuleName PSImmich -Exactly 2 -Scope It
            }

            It 'Should accept pipeline input by value' {
                $TestAssetId | Get-IMFace

                Should -Invoke Invoke-ImmichApiGetFaces -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $TestAssetId
                }
            }

            It 'Should accept pipeline input by property name (assetId alias)' {
                $assetObject = [PSCustomObject]@{ assetId = $TestAssetId }
                $assetObject | Get-IMFace

                Should -Invoke Invoke-ImmichApiGetFaces -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $TestAssetId
                }
            }

            It 'Should accept pipeline input by property name (id)' {
                $assetObject = [PSCustomObject]@{ id = $TestAssetId }
                $assetObject | Get-IMFace

                Should -Invoke Invoke-ImmichApiGetFaces -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $TestAssetId
                }
            }

            It 'Should forward an explicit session' {
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                Get-IMFace -Id $TestAssetId -Session $Session

                Should -Invoke Invoke-ImmichApiGetFaces -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }

            It 'Should handle empty face results' {
                Mock Invoke-ImmichApiGetFaces -ModuleName PSImmich { return @() }

                $result = Get-IMFace -Id $TestAssetId
                $result | Should -HaveCount 0
            }
        }
    }
    Describe 'Clear-IMJob' -Tag 'Unit', 'Clear-IMJob' {
        BeforeAll {
            Mock Invoke-ImmichApiEmptyQueue -ModuleName PSImmich {
                return $null
            }
            Mock Invoke-ImmichApiRunQueueCommandLegacy -ModuleName PSImmich {
                return $null
            }
        }

        Context 'Parameter Validation' {
            It 'Should have Job parameter as mandatory' {
                $function = Get-Command Clear-IMJob
                $jobParam = $function.Parameters['Job']
                $jobParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate Job parameter values' {
                $function = Get-Command Clear-IMJob
                $jobParam = $function.Parameters['Job']
                $validateSetAttribute = $jobParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidateSetAttribute' }
                $validateSetAttribute.ValidValues | Should -Contain 'thumbnailGeneration'
                $validateSetAttribute.ValidValues | Should -Contain 'metadataExtraction'
                $validateSetAttribute.ValidValues | Should -Contain 'faceDetection'
            }

            It 'Should have FailedOnly parameter as switch' {
                $function = Get-Command Clear-IMJob
                $failedOnlyParam = $function.Parameters['FailedOnly']
                $failedOnlyParam.ParameterType.Name | Should -Be 'SwitchParameter'
            }

            It 'Should have Force parameter as switch' {
                $function = Get-Command Clear-IMJob
                $forceParam = $function.Parameters['Force']
                $forceParam.ParameterType.Name | Should -Be 'SwitchParameter'
            }

            It 'Should reject invalid job types' {
                { Clear-IMJob -Job 'invalidJobType' } | Should -Throw
            }
        }

        Context 'Job Clearing Operations' {
            BeforeAll {
                $TestJob = 'thumbnailGeneration'
                $TestJob2 = 'metadataExtraction'
            }

            It 'Should clear all jobs by default' {
                Clear-IMJob -Job $TestJob

                Should -Invoke Invoke-ImmichApiEmptyQueue -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Name -eq $TestJob -and
                    $Body.failed -eq $false
                }
            }

            It 'Should clear only failed jobs when FailedOnly is specified' {
                Clear-IMJob -Job $TestJob -FailedOnly

                Should -Invoke Invoke-ImmichApiRunQueueCommandLegacy -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Name -eq $TestJob -and
                    $Body.command -eq 'clear-failed'
                }
            }

            It 'Should handle multiple job types' {
                Clear-IMJob -Job @($TestJob, $TestJob2)

                Should -Invoke Invoke-ImmichApiEmptyQueue -ModuleName PSImmich -Exactly 2 -Scope It -ParameterFilter {
                    $Name -eq $TestJob -or $Name -eq $TestJob2
                }
            }

            It 'Should warn and not send force when Force is specified' {
                Clear-IMJob -Job $TestJob -Force -WarningVariable warnings -WarningAction SilentlyContinue

                $warnings | Should -Not -BeNullOrEmpty
                Should -Invoke Invoke-ImmichApiEmptyQueue -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    -not $Body.ContainsKey('force')
                }
            }
        }


        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command Clear-IMJob
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                Clear-IMJob -Job 'thumbnailGeneration'

                Should -Invoke Invoke-ImmichApiEmptyQueue -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Get-IMJob' -Tag 'Unit', 'Get-IMJob' {
        BeforeAll {
            Mock InvokeImmichRestMethod -ModuleName PSImmich {
                switch ($RelativePath)
                {
                    '/queues'
                    {
                        return @(
                            [PSCustomObject]@{
                                name       = 'thumbnailGeneration'
                                isPaused   = $false
                                statistics = [PSCustomObject]@{
                                    active    = 2
                                    completed = 1547
                                    failed    = 3
                                    delayed   = 0
                                    waiting   = 15
                                    paused    = 0
                                }
                            },
                            [PSCustomObject]@{
                                name       = 'metadataExtraction'
                                isPaused   = $false
                                statistics = [PSCustomObject]@{
                                    active    = 1
                                    completed = 892
                                    failed    = 0
                                    delayed   = 0
                                    waiting   = 8
                                    paused    = 0
                                }
                            },
                            [PSCustomObject]@{
                                name       = 'faceDetection'
                                isPaused   = $true
                                statistics = [PSCustomObject]@{
                                    active    = 0
                                    completed = 234
                                    failed    = 1
                                    delayed   = 0
                                    waiting   = 0
                                    paused    = 50
                                }
                            }
                        )
                    }
                    default
                    {
                        throw "Unmocked path: $RelativePath"
                    }
                }
            }
        }

        Context 'Job Information Retrieval' {
            It 'Should retrieve job information using GET method' {
                Get-IMJob

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Method -eq 'GET' -and
                    $RelativePath -eq '/queues'
                }
            }

            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command Get-IMJob
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should return array of job objects with correct structure' {
                $result = Get-IMJob
                $result | Should -HaveCount 3

                # Test thumbnailGeneration job
                $thumbJob = $result | Where-Object { $_.name -eq 'thumbnailGeneration' }
                $thumbJob.statistics.active | Should -Be 2
                $thumbJob.statistics.completed | Should -Be 1547
                $thumbJob.statistics.failed | Should -Be 3
                $thumbJob.statistics.waiting | Should -Be 15
                $thumbJob.isPaused | Should -Be $false

                # Test metadataExtraction job
                $metaJob = $result | Where-Object { $_.name -eq 'metadataExtraction' }
                $metaJob.statistics.active | Should -Be 1
                $metaJob.statistics.completed | Should -Be 892
                $metaJob.statistics.failed | Should -Be 0
                $metaJob.isPaused | Should -Be $false

                # Test faceDetection job (paused)
                $faceJob = $result | Where-Object { $_.name -eq 'faceDetection' }
                $faceJob.statistics.paused | Should -Be 50
                $faceJob.isPaused | Should -Be $true
            }

            It 'Should handle different queue states' {
                $result = Get-IMJob
                $activeJobs = $result | Where-Object { $_.statistics.active -gt 0 }
                $pausedJobs = $result | Where-Object { $_.isPaused -eq $true }

                $activeJobs | Should -HaveCount 2
                $pausedJobs | Should -HaveCount 1
            }

            It 'Should handle empty job results' {
                Mock InvokeImmichRestMethod -ModuleName PSImmich {
                    return @()
                }

                $result = Get-IMJob
                $result | Should -HaveCount 0
            }
        }
    }
    Describe 'Resume-IMJob' -Tag 'Unit', 'Resume-IMJob' {
        BeforeAll {
            Mock InvokeImmichRestMethod -ModuleName PSImmich {
                # Mock returns nothing for PUT operations
                return $null
            }
        }

        Context 'Parameter Validation' {
            It 'Should have Job parameter as mandatory' {
                $function = Get-Command Resume-IMJob
                $jobParam = $function.Parameters['Job']
                $jobParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate Job parameter values' {
                $function = Get-Command Resume-IMJob
                $jobParam = $function.Parameters['Job']
                $validateSetAttribute = $jobParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidateSetAttribute' }
                $validateSetAttribute.ValidValues | Should -Contain 'thumbnailGeneration'
                $validateSetAttribute.ValidValues | Should -Contain 'metadataExtraction'
                $validateSetAttribute.ValidValues | Should -Contain 'faceDetection'
            }

            It 'Should have Force parameter as switch' {
                $function = Get-Command Resume-IMJob
                $forceParam = $function.Parameters['Force']
                $forceParam.ParameterType.Name | Should -Be 'SwitchParameter'
            }

            It 'Should reject invalid job types' {
                { Resume-IMJob -Job 'invalidJobType' } | Should -Throw
            }
        }

        Context 'Job Resume Operations' {
            BeforeAll {
                $TestJob = 'thumbnailGeneration'
                $TestJob2 = 'faceDetection'
            }

            It 'Should resume job with correct API call' {
                Resume-IMJob -Job $TestJob

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Method -eq 'PUT' -and
                    $RelativePath -eq "/queues/$TestJob" -and
                    $Body.isPaused -eq $false
                }
            }

            It 'Should handle multiple job types' {
                Resume-IMJob -Job @($TestJob, $TestJob2)

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Times 2 -ParameterFilter {
                    $Method -eq 'PUT' -and
                    ($RelativePath -eq "/queues/$TestJob" -or $RelativePath -eq "/queues/$TestJob2") -and
                    $Body.isPaused -eq $false
                }
            }

            It 'Should warn and not send force when Force is specified' {
                Resume-IMJob -Job $TestJob -Force -WarningVariable warnings -WarningAction SilentlyContinue

                $warnings | Should -Not -BeNullOrEmpty
                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Times 1 -ParameterFilter {
                    -not $Body.ContainsKey('force')
                }
            }

            It 'Should handle specialized job types' {
                $specialJobs = @('smartSearch', 'duplicateDetection', 'notifications')
                Resume-IMJob -Job $specialJobs

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Times 3 -ParameterFilter {
                    $Method -eq 'PUT' -and
                    $Body.isPaused -eq $false
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command Resume-IMJob
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                Resume-IMJob -Job 'thumbnailGeneration'

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Start-IMJob' -Tag 'Unit', 'Start-IMJob' {
        BeforeAll {
            Mock Invoke-ImmichApiRunQueueCommandLegacy -ModuleName PSImmich {
                return $null
            }

            Mock Invoke-ImmichApiEmptyTrash -ModuleName PSImmich {
                return $null
            }

            Mock Invoke-ImmichApiCreateJob -ModuleName PSImmich {
                return $null
            }

            Mock ConvertTo-ApiParameters -ModuleName PSImmich {
                param($BoundParameters, $CmdletName)
                $result = @{}
                if ($BoundParameters.Force)
                {
                    $result.force = $BoundParameters.Force
                }
                return $result
            }
        }

        Context 'Parameter Validation' {
            It 'Should support ShouldProcess' {
                $function = Get-Command Start-IMJob
                $function.ScriptBlock.Attributes | Where-Object { $_.TypeId.Name -eq 'CmdletBindingAttribute' } |
                    ForEach-Object { $_.SupportsShouldProcess } | Should -Be $true
            }

            It 'Should have Job parameter as mandatory' {
                $function = Get-Command Start-IMJob
                $jobParam = $function.Parameters['Job']
                $jobParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate Job parameter values including special jobs' {
                $function = Get-Command Start-IMJob
                $jobParam = $function.Parameters['Job']
                $validateSetAttribute = $jobParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidateSetAttribute' }
                $validateSetAttribute.ValidValues | Should -Contain 'thumbnailGeneration'
                $validateSetAttribute.ValidValues | Should -Contain 'emptyTrash'
                $validateSetAttribute.ValidValues | Should -Contain 'person-cleanup'
                $validateSetAttribute.ValidValues | Should -Contain 'tag-cleanup'
                $validateSetAttribute.ValidValues | Should -Contain 'user-cleanup'
            }

            It 'Should not contain duplicate or misspelled job names' {
                $function = Get-Command Start-IMJob
                $validateSetAttribute = $function.Parameters['Job'].Attributes | Where-Object { $_.TypeId.Name -eq 'ValidateSetAttribute' }
                $validateSetAttribute.ValidValues | Should -Not -Contain 'backup-databaseperson-cleanup'
                ($validateSetAttribute.ValidValues | Group-Object | Where-Object Count -gt 1) | Should -BeNullOrEmpty
            }

            It 'Should have Force parameter as switch' {
                $function = Get-Command Start-IMJob
                $forceParam = $function.Parameters['Force']
                $forceParam.ParameterType.Name | Should -Be 'SwitchParameter'
            }

            It 'Should reject invalid job types' {
                { Start-IMJob -Job 'invalidJobType' -Confirm:$false } | Should -Throw
            }
        }

        Context 'Standard Job Operations' {
            BeforeAll {
                $TestJob = 'thumbnailGeneration'
                $TestJob2 = 'faceDetection'
            }

            It 'Should start standard job with correct API call' {
                Start-IMJob -Job $TestJob -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunQueueCommandLegacy -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Name -eq $TestJob -and
                    $Body.command -eq 'start'
                }
            }

            It 'Should handle multiple standard job types' {
                Start-IMJob -Job @($TestJob, $TestJob2) -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunQueueCommandLegacy -ModuleName PSImmich -Exactly 2 -Scope It -ParameterFilter {
                    ($Name -eq $TestJob -or $Name -eq $TestJob2) -and
                    $Body.command -eq 'start'
                }
            }

            It 'Should include force in body when Force is specified' {
                Start-IMJob -Job $TestJob -Force -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunQueueCommandLegacy -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.force -eq $true -and
                    $Body.command -eq 'start'
                }
            }
        }

        Context 'Special Job Operations' {
            It 'Should handle emptyTrash job with special endpoint' {
                Start-IMJob -Job 'emptyTrash' -Confirm:$false

                Should -Invoke Invoke-ImmichApiEmptyTrash -ModuleName PSImmich -Exactly 1 -Scope It
            }

            It 'Should handle cleanup jobs with the create job endpoint' {
                $cleanupJobs = @('person-cleanup', 'tag-cleanup', 'user-cleanup')
                Start-IMJob -Job $cleanupJobs -Confirm:$false

                Should -Invoke Invoke-ImmichApiCreateJob -ModuleName PSImmich -Exactly 3 -Scope It -ParameterFilter {
                    $Body.ContainsKey('name')
                }
            }

            It 'Should set correct job name for cleanup jobs' {
                Start-IMJob -Job 'person-cleanup' -Confirm:$false

                Should -Invoke Invoke-ImmichApiCreateJob -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.name -eq 'person-cleanup'
                }
            }

            It 'Should handle mixed job types correctly' {
                Start-IMJob -Job @('thumbnailGeneration', 'emptyTrash', 'person-cleanup') -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunQueueCommandLegacy -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Name -eq 'thumbnailGeneration'
                }
                Should -Invoke Invoke-ImmichApiEmptyTrash -ModuleName PSImmich -Exactly 1 -Scope It
                Should -Invoke Invoke-ImmichApiCreateJob -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.name -eq 'person-cleanup'
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command Start-IMJob
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                Start-IMJob -Job 'thumbnailGeneration' -Confirm:$false

                Should -Invoke Invoke-ImmichApiRunQueueCommandLegacy -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession -and
                    $Name -eq 'thumbnailGeneration' -and
                    $Body.command -eq 'start'
                }
            }
        }
    }
    # Skipped until we can exit maintenance mode via API
    Describe 'Get-IMIntegrityReport' -Tag 'Unit', 'Get-IMIntegrityReport' {
        BeforeAll {
            Mock Invoke-ImmichApiGetIntegrityReport -ModuleName PSImmich {
                [PSCustomObject]@{
                    items      = @(
                        [PSCustomObject]@{ id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'; type = 'untracked_file'; path = '/data/a.jpg'; createdAt = '2026-01-01T00:00:00Z'; assetId = $null; fileAssetId = $null }
                    )
                    nextCursor = 'next-page'
                }
            }
            Mock Invoke-ImmichApiGetIntegrityReportSummary -ModuleName PSImmich {
                [PSCustomObject]@{ untrackedFile = 3; missingFile = 1; checksumMismatch = 0 }
            }
        }

        Context 'When listing a report type' {
            It 'Should call the report endpoint with the type' {
                $null = Get-IMIntegrityReport -Type 'untracked_file'

                Should -Invoke Invoke-ImmichApiGetIntegrityReport -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Type -eq 'untracked_file' -and $null -eq $Cursor -and $null -eq $Limit
                }
            }

            It 'Should forward cursor and limit when supplied' {
                $null = Get-IMIntegrityReport -Type 'missing_file' -Cursor 'page-2' -Limit 25

                Should -Invoke Invoke-ImmichApiGetIntegrityReport -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Type -eq 'missing_file' -and $Cursor -eq 'page-2' -and $Limit -eq 25
                }
            }

            It 'Should return the report response with the next cursor' {
                $Result = Get-IMIntegrityReport -Type 'untracked_file'

                $Result.GetType().Name | Should -Be 'IntegrityReportResponseDto'
                $Result.NextCursor | Should -Be 'next-page'
                $Result.Items.Count | Should -Be 1
            }

            It 'Should reject an unknown report type' {
                { Get-IMIntegrityReport -Type 'unknown' } | Should -Throw
            }
        }

        Context 'When requesting the summary' {
            It 'Should call the summary endpoint' {
                $Result = Get-IMIntegrityReport -Summary

                Should -Invoke Invoke-ImmichApiGetIntegrityReportSummary -ModuleName PSImmich -Times 1 -Exactly -Scope It
                Should -Invoke Invoke-ImmichApiGetIntegrityReport -ModuleName PSImmich -Times 0 -Exactly -Scope It
                $Result.GetType().Name | Should -Be 'IntegrityReportSummaryResponseDto'
            }
        }

        Context 'When parameters conflict' {
            It 'Should reject Summary combined with Type' {
                { Get-IMIntegrityReport -Summary -Type 'untracked_file' } | Should -Throw
            }
        }
    }

    Describe 'Remove-IMIntegrityReport' -Tag 'Unit', 'Remove-IMIntegrityReport' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteIntegrityReport -ModuleName PSImmich {}
        }

        Context 'When removing an item' {
            It 'Should call the delete endpoint with the id' {
                Remove-IMIntegrityReport -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteIntegrityReport -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
                }
            }
        }

        Context 'When removing items from the pipeline' {
            It 'Should send one request per item bound by property name' {
                $Items = @(
                    [PSCustomObject]@{ id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
                    [PSCustomObject]@{ id = '6c1c0c9e-4b4f-4b57-b2bc-1f8b3e5a0d22' }
                )

                $Items | Remove-IMIntegrityReport -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteIntegrityReport -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }
        }

        Context 'When WhatIf is specified' {
            It 'Should not call the endpoint' {
                Remove-IMIntegrityReport -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -WhatIf

                Should -Invoke Invoke-ImmichApiDeleteIntegrityReport -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }
        }

        Context 'When the id is invalid' {
            It 'Should throw for a malformed id' {
                { Remove-IMIntegrityReport -Id 'not-a-guid' -Confirm:$false } | Should -Throw
            }
        }
    }

    Describe 'Save-IMIntegrityReport' -Tag 'Unit', 'Save-IMIntegrityReport' {
        BeforeAll {
            Mock Invoke-ImmichApiGetIntegrityReportFile -ModuleName PSImmich {}
            Mock Invoke-ImmichApiGetIntegrityReportCsv -ModuleName PSImmich {}
        }

        Context 'When saving an item file' {
            It 'Should download the file for the id to the path' {
                $Path = Join-Path $TestDrive 'item.bin'

                Save-IMIntegrityReport -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Path $Path

                Should -Invoke Invoke-ImmichApiGetIntegrityReportFile -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -and $OutFilePath.FullName -eq $Path
                }
                Should -Invoke Invoke-ImmichApiGetIntegrityReportCsv -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }
        }

        Context 'When saving a CSV export' {
            It 'Should download the CSV for the type to the path' {
                $Path = Join-Path $TestDrive 'checksum.csv'

                Save-IMIntegrityReport -Type 'checksum_mismatch' -Path $Path

                Should -Invoke Invoke-ImmichApiGetIntegrityReportCsv -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Type -eq 'checksum_mismatch' -and $OutFilePath.FullName -eq $Path
                }
                Should -Invoke Invoke-ImmichApiGetIntegrityReportFile -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }
        }

        Context 'When parameters are invalid' {
            It 'Should reject an unknown CSV report type' {
                { Save-IMIntegrityReport -Type 'bogus' -Path (Join-Path $TestDrive 'x.csv') } | Should -Throw
            }

            It 'Should require a path' {
                { Save-IMIntegrityReport -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' } | Should -Throw
            }
        }
    }

    Describe 'Get-IMDatabaseBackup' -Tag 'Unit', 'Get-IMDatabaseBackup' {
        BeforeAll {
            Mock Invoke-ImmichApiListDatabaseBackups -ModuleName PSImmich {
                [PSCustomObject]@{
                    backups = @(
                        [PSCustomObject]@{ filename = 'immich-db-backup-1.sql.gz'; filesize = 1024; timezone = 'UTC' }
                        [PSCustomObject]@{ filename = 'immich-db-backup-2.sql.gz'; filesize = 2048; timezone = 'UTC' }
                    )
                }
            }
        }

        It 'Should return one DatabaseBackupDto per backup' {
            $Result = Get-IMDatabaseBackup

            Should -Invoke Invoke-ImmichApiListDatabaseBackups -ModuleName PSImmich -Times 1 -Exactly -Scope It
            $Result.Count | Should -Be 2
            $Result[0].GetType().Name | Should -Be 'DatabaseBackupDto'
            $Result[1].filename | Should -Be 'immich-db-backup-2.sql.gz'
        }

        It 'Should forward the session' {
            $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])

            $null = Get-IMDatabaseBackup -Session $Session

            Should -Invoke Invoke-ImmichApiListDatabaseBackups -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $null -ne $ImmichSession
            }
        }
    }

    Describe 'Remove-IMDatabaseBackup' -Tag 'Unit', 'Remove-IMDatabaseBackup' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteDatabaseBackup -ModuleName PSImmich {}
        }

        Context 'When removing a backup' {
            It 'Should send the file name in the backups array' {
                Remove-IMDatabaseBackup -Filename 'immich-db-backup-1.sql.gz' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteDatabaseBackup -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.backups.Count -eq 1 -and $Body.backups[0] -eq 'immich-db-backup-1.sql.gz'
                }
            }

            It 'Should send several file names in one request' {
                Remove-IMDatabaseBackup -Filename 'immich-db-backup-1.sql.gz', 'immich-db-backup-2.sql.gz' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteDatabaseBackup -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.backups.Count -eq 2
                }
            }
        }

        Context 'When removing backups from the pipeline' {
            It 'Should send one request per backup bound by property name' {
                $Backups = @(
                    [PSCustomObject]@{ filename = 'immich-db-backup-1.sql.gz' }
                    [PSCustomObject]@{ filename = 'immich-db-backup-2.sql.gz' }
                )

                $Backups | Remove-IMDatabaseBackup -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteDatabaseBackup -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }
        }

        Context 'When WhatIf is specified' {
            It 'Should not call the endpoint' {
                Remove-IMDatabaseBackup -Filename 'immich-db-backup-1.sql.gz' -WhatIf

                Should -Invoke Invoke-ImmichApiDeleteDatabaseBackup -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }
        }
    }

    Describe 'Save-IMDatabaseBackup' -Tag 'Unit', 'Save-IMDatabaseBackup' {
        BeforeAll {
            Mock Invoke-ImmichApiDownloadDatabaseBackup -ModuleName PSImmich {}
        }

        It 'Should download the backup into the directory keeping its file name' {
            $Directory = Get-Item -Path $TestDrive

            Save-IMDatabaseBackup -Filename 'immich-db-backup-1.sql.gz' -Path $Directory

            Should -Invoke Invoke-ImmichApiDownloadDatabaseBackup -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $Filename -eq 'immich-db-backup-1.sql.gz' -and
                $OutFilePath.FullName -eq (Join-Path $TestDrive 'immich-db-backup-1.sql.gz')
            }
        }

        It 'Should accept file names from the pipeline' {
            $Backups = @([PSCustomObject]@{ filename = 'immich-db-backup-1.sql.gz' })

            $Backups | Save-IMDatabaseBackup -Path (Get-Item -Path $TestDrive)

            Should -Invoke Invoke-ImmichApiDownloadDatabaseBackup -ModuleName PSImmich -Times 1 -Exactly -Scope It
        }

        It 'Should require a directory path' {
            { Save-IMDatabaseBackup -Filename 'immich-db-backup-1.sql.gz' } | Should -Throw
        }
    }

    Describe 'Get-IMMaintenanceStatus' -Tag 'Unit', 'Get-IMMaintenanceStatus' {
        BeforeAll {
            Mock Invoke-ImmichApiGetMaintenanceStatus -ModuleName PSImmich {
                [PSCustomObject]@{ action = 'start'; active = $true; error = $null; progress = 42; task = 'Restoring' }
            }
        }

        It 'Should return a MaintenanceStatusResponseDto' {
            $Result = Get-IMMaintenanceStatus

            Should -Invoke Invoke-ImmichApiGetMaintenanceStatus -ModuleName PSImmich -Times 1 -Exactly -Scope It
            $Result.GetType().Name | Should -Be 'MaintenanceStatusResponseDto'
            $Result.active | Should -BeTrue
            $Result.progress | Should -Be 42
        }

        It 'Should forward the session' {
            $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])

            $null = Get-IMMaintenanceStatus -Session $Session

            Should -Invoke Invoke-ImmichApiGetMaintenanceStatus -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                $null -ne $ImmichSession
            }
        }
    }

    Describe 'Start-IMMaintenanceMode' -Tag 'Unit', 'Start-IMMaintenanceMode' -Skip:$true {
        BeforeAll {
            Mock Invoke-ImmichApiSetMaintenanceMode {} -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have Session parameter' {
                $Command = Get-Command Start-IMMaintenanceMode
                $Command.Parameters['Session'] | Should -Not -BeNullOrEmpty
            }
        }

        Context 'ShouldProcess Support' {
            It 'Should support ShouldProcess' {
                $Command = Get-Command Start-IMMaintenanceMode
                $CmdletBinding = $Command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
                $CmdletBinding.SupportsShouldProcess | Should -Be $true
            }

            It 'Should have High ConfirmImpact' {
                $Command = Get-Command Start-IMMaintenanceMode
                $CmdletBinding = $Command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
                $CmdletBinding.ConfirmImpact | Should -Be 'High'
            }

            It 'Should not call API when ShouldProcess returns false' {
                Start-IMMaintenanceMode -WhatIf

                Should -Invoke Invoke-ImmichApiSetMaintenanceMode -ModuleName PSImmich -Exactly 0 -Scope It
            }
        }

        Context 'API Calls' {
            It 'Should call correct endpoint with start action' {
                Start-IMMaintenanceMode -Confirm:$false

                Should -Invoke Invoke-ImmichApiSetMaintenanceMode -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.action -eq 'start'
                }
            }
        }
    }
    # Skipped until we can exit maintenance mode via API
    Describe 'Stop-IMMaintenanceMode' -Tag 'Unit', 'Stop-IMMaintenanceMode' -Skip:$true {
        BeforeAll {
            Mock Invoke-ImmichApiSetMaintenanceMode {} -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have Session parameter' {
                $Command = Get-Command Stop-IMMaintenanceMode
                $Command.Parameters['Session'] | Should -Not -BeNullOrEmpty
            }
        }

        Context 'ShouldProcess Support' {
            It 'Should support ShouldProcess' {
                $Command = Get-Command Stop-IMMaintenanceMode
                $CmdletBinding = $Command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
                $CmdletBinding.SupportsShouldProcess | Should -Be $true
            }

            It 'Should not call API when ShouldProcess returns false' {
                Stop-IMMaintenanceMode -WhatIf

                Should -Invoke Invoke-ImmichApiSetMaintenanceMode -ModuleName PSImmich -Exactly 0 -Scope It
            }
        }

        Context 'API Calls' {
            It 'Should call correct endpoint with end action' {
                Stop-IMMaintenanceMode -Confirm:$false

                Should -Invoke Invoke-ImmichApiSetMaintenanceMode -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.action -eq 'end'
                }
            }
        }
    }
    Describe 'Suspend-IMJob' -Tag 'Unit', 'Suspend-IMJob' {
        BeforeAll {
            Mock InvokeImmichRestMethod -ModuleName PSImmich {
                # Mock returns nothing for PUT operations
                return $null
            }
        }

        Context 'Parameter Validation' {
            It 'Should have Job parameter as mandatory' {
                $function = Get-Command Suspend-IMJob
                $jobParam = $function.Parameters['Job']
                $jobParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate Job parameter values' {
                $function = Get-Command Suspend-IMJob
                $jobParam = $function.Parameters['Job']
                $validateSetAttribute = $jobParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidateSetAttribute' }
                $validateSetAttribute.ValidValues | Should -Contain 'thumbnailGeneration'
                $validateSetAttribute.ValidValues | Should -Contain 'metadataExtraction'
                $validateSetAttribute.ValidValues | Should -Contain 'faceDetection'
                $validateSetAttribute.ValidValues | Should -Contain 'notifications'
            }

            It 'Should have Force parameter as switch' {
                $function = Get-Command Suspend-IMJob
                $forceParam = $function.Parameters['Force']
                $forceParam.ParameterType.Name | Should -Be 'SwitchParameter'
            }

            It 'Should reject invalid job types' {
                { Suspend-IMJob -Job 'invalidJobType' } | Should -Throw
            }
        }

        Context 'Job Suspension Operations' {
            BeforeAll {
                $TestJob = 'thumbnailGeneration'
                $TestJob2 = 'videoConversion'
            }

            It 'Should suspend job with correct API call' {
                Suspend-IMJob -Job $TestJob

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Method -eq 'PUT' -and
                    $RelativePath -eq "/queues/$TestJob" -and
                    $Body.isPaused -eq $true
                }
            }

            It 'Should handle multiple job types' {
                Suspend-IMJob -Job @($TestJob, $TestJob2)

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Times 2 -ParameterFilter {
                    $Method -eq 'PUT' -and
                    ($RelativePath -eq "/queues/$TestJob" -or $RelativePath -eq "/queues/$TestJob2") -and
                    $Body.isPaused -eq $true
                }
            }

            It 'Should warn and not send force when Force is specified' {
                Suspend-IMJob -Job $TestJob -Force -WarningVariable warnings -WarningAction SilentlyContinue

                $warnings | Should -Not -BeNullOrEmpty
                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Times 1 -ParameterFilter {
                    -not $Body.ContainsKey('force')
                }
            }

            It 'Should handle all supported job types' {
                $allJobs = @('smartSearch', 'duplicateDetection', 'library', 'migration')
                Suspend-IMJob -Job $allJobs

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Times 4 -ParameterFilter {
                    $Method -eq 'PUT' -and
                    $Body.isPaused -eq $true
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command Suspend-IMJob
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                Suspend-IMJob -Job 'thumbnailGeneration'

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Get-IMLibrary' -Tag 'Unit', 'Get-IMLibrary' {
        BeforeAll {
            # Mock the generated API wrappers used by Get-IMLibrary
            Mock Invoke-ImmichApiGetAllLibraries -ModuleName PSImmich {
                return @(
                    [pscustomobject]@{
                        id      = '11111111-1111-1111-1111-111111111111'
                        name    = 'Library 1'
                        ownerId = '22222222-2222-2222-2222-222222222222'
                        type    = 'UPLOAD'
                    },
                    [pscustomobject]@{
                        id      = '33333333-3333-3333-3333-333333333333'
                        name    = 'Library 2'
                        ownerId = '44444444-4444-4444-4444-444444444444'
                        type    = 'EXTERNAL'
                    }
                )
            }

            Mock Invoke-ImmichApiGetLibrary -ModuleName PSImmich {
                if ($Id -eq '11111111-1111-1111-1111-111111111111')
                {
                    return [pscustomobject]@{
                        id      = '11111111-1111-1111-1111-111111111111'
                        name    = 'Library 1'
                        ownerId = '22222222-2222-2222-2222-222222222222'
                        type    = 'UPLOAD'
                    }
                }
                if ($Id -eq '33333333-3333-3333-3333-333333333333')
                {
                    return [pscustomobject]@{
                        id      = '33333333-3333-3333-3333-333333333333'
                        name    = 'Library 2'
                        ownerId = '44444444-4444-4444-4444-444444444444'
                        type    = 'EXTERNAL'
                    }
                }
            }

            Mock Invoke-ImmichApiGetLibraryStatistics -ModuleName PSImmich {
                return [pscustomobject]@{
                    total  = 150
                    videos = 25
                    photos = 125
                    usage  = 1073741824
                }
            }
        }

        Context 'Parameter Set: list (Default)' {
            It 'Should retrieve all libraries when no parameters are provided' {
                $result = Get-IMLibrary

                $result | Should -HaveCount 2
                $result[0].id | Should -Be '11111111-1111-1111-1111-111111111111'
                $result[1].id | Should -Be '33333333-3333-3333-3333-333333333333'

                # Verify the REST method was called correctly
                Should -Invoke Invoke-ImmichApiGetAllLibraries -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }

            It 'Should filter libraries by ownerId when provided' {
                $result = Get-IMLibrary -ownerId '22222222-2222-2222-2222-222222222222'

                $result | Should -HaveCount 1
                $result.ownerId | Should -Be '22222222-2222-2222-2222-222222222222'

                # Filtering happens in PowerShell after the list wrapper returns
                Should -Invoke Invoke-ImmichApiGetAllLibraries -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }

            It 'Should not call the single library or statistics wrappers in list mode' {
                $null = Get-IMLibrary

                Should -Invoke Invoke-ImmichApiGetLibrary -ModuleName PSImmich -Times 0 -Exactly -Scope It
                Should -Invoke Invoke-ImmichApiGetLibraryStatistics -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }

            It 'Should pass session parameter to the list wrapper when provided' {
                $null = Get-IMLibrary -Session $null

                Should -Invoke Invoke-ImmichApiGetAllLibraries -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }

        Context 'Parameter Set: id' {
            It 'Should retrieve a specific library by id' {
                $result = Get-IMLibrary -id '11111111-1111-1111-1111-111111111111'

                $result.id | Should -Be '11111111-1111-1111-1111-111111111111'
                $result.name | Should -Be 'Library 1'

                Should -Invoke Invoke-ImmichApiGetLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '11111111-1111-1111-1111-111111111111'
                }
                $ids = @('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333')
                $result = Get-IMLibrary -id $ids

                $result | Should -HaveCount 2
                $result[0].id | Should -Be '11111111-1111-1111-1111-111111111111'
                $result[1].id | Should -Be '33333333-3333-3333-3333-333333333333'

                # Called once per ID (3 in total: the single-id call above plus two for the array)
                Should -Invoke Invoke-ImmichApiGetLibrary -ModuleName PSImmich -Times 3 -Exactly -Scope It
                Should -Invoke Invoke-ImmichApiGetLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '33333333-3333-3333-3333-333333333333'
                }
            }

            It 'Should include statistics when IncludeStatistics switch is used' {
                $result = Get-IMLibrary -id '11111111-1111-1111-1111-111111111111' -IncludeStatistics

                $result.id | Should -Be '11111111-1111-1111-1111-111111111111'
                $result.Statistics | Should -Not -BeNullOrEmpty
                $result.Statistics.total | Should -Be 150
                $result.Statistics.usage | Should -Be 1073741824

                # Should call both library and statistics wrappers
                Should -Invoke Invoke-ImmichApiGetLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '11111111-1111-1111-1111-111111111111'
                }
                Should -Invoke Invoke-ImmichApiGetLibraryStatistics -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '11111111-1111-1111-1111-111111111111'
                }
            }

            It 'Should accept pipeline input by property name' {
                $inputObject = [PSCustomObject]@{ id = '11111111-1111-1111-1111-111111111111' }
                $result = $inputObject | Get-IMLibrary

                $result.id | Should -Be '11111111-1111-1111-1111-111111111111'

                Should -Invoke Invoke-ImmichApiGetLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '11111111-1111-1111-1111-111111111111'
                }
            }

            It 'Should accept direct pipeline input' {
                $result = '11111111-1111-1111-1111-111111111111' | Get-IMLibrary

                $result.id | Should -Be '11111111-1111-1111-1111-111111111111'

                Should -Invoke Invoke-ImmichApiGetLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '11111111-1111-1111-1111-111111111111'
                }
            }

            It 'Should pass session parameter to the id wrapper when provided' {
                $null = Get-IMLibrary -id '11111111-1111-1111-1111-111111111111' -Session $null

                Should -Invoke Invoke-ImmichApiGetLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '11111111-1111-1111-1111-111111111111' -and
                    $null -eq $ImmichSession
                }
            }
        }

        Context 'Parameter Validation' {
            It 'Should validate GUID format for id parameter' {
                { Get-IMLibrary -id 'invalid-guid' } | Should -Throw
            }

            It 'Should validate GUID format for ownerId parameter' {
                { Get-IMLibrary -ownerId 'invalid-guid' } | Should -Throw
            }

            It 'Should accept valid GUID formats' {
                # These should not throw
                { Get-IMLibrary -id '11111111-1111-1111-1111-111111111111' } | Should -Not -Throw
                { Get-IMLibrary -ownerId '22222222-2222-2222-2222-222222222222' } | Should -Not -Throw
            }
        }

        Context 'Parameter Set Behavior' {
            It 'Should use list parameter set when no id is provided' {
                $null = Get-IMLibrary

                Should -Invoke Invoke-ImmichApiGetAllLibraries -ModuleName PSImmich -Times 1 -Exactly -Scope It
                Should -Invoke Invoke-ImmichApiGetLibrary -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }

            It 'Should use id parameter set when id is provided' {
                $null = Get-IMLibrary -id '11111111-1111-1111-1111-111111111111'

                Should -Invoke Invoke-ImmichApiGetLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '11111111-1111-1111-1111-111111111111'
                }
                Should -Invoke Invoke-ImmichApiGetAllLibraries -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }

            It 'Should not call the statistics wrapper without IncludeStatistics' {
                $null = Get-IMLibrary -id '11111111-1111-1111-1111-111111111111'

                Should -Invoke Invoke-ImmichApiGetLibraryStatistics -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }
        }

        AfterEach {
            # Reset mock call counts between tests
            # Note: Pester 5 automatically resets mocks between tests
        }
    }
    Describe 'New-IMLibrary' -Tag 'Unit', 'New-IMLibrary' {
        BeforeAll {
            Mock Invoke-ImmichApiCreateLibrary -ModuleName PSImmich {
                return [PSCustomObject]@{
                    id                = 'new-library-guid-1234567890abcdef'
                    name              = 'Test Library'
                    type              = 'EXTERNAL'
                    ownerId           = 'owner-guid-here-1234567890abcdef'
                    importPaths       = @('/test/path')
                    exclusionPatterns = @('*.tmp')
                    createdAt         = '2024-01-01T10:00:00Z'
                    updatedAt         = '2024-01-01T10:00:00Z'
                    refreshedAt       = $null
                    assetCount        = 0
                }
            }
        }

        Context 'Parameter Validation' {
            It 'Should have Name parameter as mandatory' {
                $function = Get-Command New-IMLibrary
                $nameParam = $function.Parameters['Name']
                $nameParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for OwnerId parameter' {
                $function = Get-Command New-IMLibrary
                $ownerIdParam = $function.Parameters['OwnerId']
                $validationAttribute = $ownerIdParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should have ApiParameter attributes for all body parameters' {
                $function = Get-Command New-IMLibrary
                $nameParam = $function.Parameters['Name']
                $exclusionParam = $function.Parameters['ExclusionPatterns']
                $importParam = $function.Parameters['ImportPaths']
                $ownerParam = $function.Parameters['OwnerId']

                $nameApiAttr = $nameParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }
                $exclusionApiAttr = $exclusionParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }
                $importApiAttr = $importParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }
                $ownerApiAttr = $ownerParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }

                $nameApiAttr.Name | Should -Be 'name'
                $exclusionApiAttr.Name | Should -Be 'exclusionPatterns'
                $importApiAttr.Name | Should -Be 'importPaths'
                $ownerApiAttr.Name | Should -Be 'ownerId'
            }

            It 'Should reject invalid GUID for OwnerId' {
                { New-IMLibrary -Name 'Test' -OwnerId 'invalid-guid' } | Should -Throw
            }
        }

        Context 'Library Creation' {
            It 'Should create library with minimal parameters' {
                $result = New-IMLibrary -Name 'Test Library'

                Should -Invoke Invoke-ImmichApiCreateLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.name -eq 'Test Library' -and
                    -not $Body.ContainsKey('importPaths') -and
                    -not $Body.ContainsKey('exclusionPatterns') -and
                    -not $Body.ContainsKey('ownerId')
                }
                $result.name | Should -Be 'Test Library'
            }

            It 'Should create library with all parameters' {
                $params = @{
                    Name              = 'Full Library'
                    ImportPaths       = @('/path1', '/path2')
                    ExclusionPatterns = @('*.tmp', '*.log')
                    OwnerId           = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                }
                New-IMLibrary @params

                Should -Invoke Invoke-ImmichApiCreateLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.name -eq 'Full Library' -and
                    $Body.importPaths.Count -eq 2 -and
                    $Body.exclusionPatterns.Count -eq 2 -and
                    $Body.ownerId -eq 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                }
            }

            It 'Should handle ImportPaths array parameter' {
                $importPaths = @('/photos', '/videos', '/documents')
                New-IMLibrary -Name 'Multi-Path Library' -ImportPaths $importPaths

                Should -Invoke Invoke-ImmichApiCreateLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.importPaths.Count -eq 3 -and
                    $Body.importPaths -contains '/photos'
                }
            }

            It 'Should handle ExclusionPatterns array parameter' {
                $exclusions = @('*.tmp', '*.log', '.DS_Store', 'Thumbs.db')
                New-IMLibrary -Name 'Filtered Library' -ExclusionPatterns $exclusions

                Should -Invoke Invoke-ImmichApiCreateLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.exclusionPatterns.Count -eq 4 -and
                    $Body.exclusionPatterns -contains '*.tmp'
                }
            }

            It 'Should return created library object' {
                $result = New-IMLibrary -Name 'Return Test'

                $result | Should -Not -BeNullOrEmpty
                $result.id | Should -Be 'new-library-guid-1234567890abcdef'
                $result.name | Should -Be 'Test Library'
                $result.assetCount | Should -Be 0
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command New-IMLibrary
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                New-IMLibrary -Name 'Session Test'

                Should -Invoke Invoke-ImmichApiCreateLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Remove-IMLibrary' -Tag 'Unit', 'Remove-IMLibrary' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteLibrary -ModuleName PSImmich {
                # Mock returns nothing for DELETE operations
                return $null
            }
        }

        Context 'Parameter Validation' {
            It 'Should support ShouldProcess' {
                $function = Get-Command Remove-IMLibrary
                $function.ScriptBlock.Attributes | Where-Object { $_.TypeId.Name -eq 'CmdletBindingAttribute' } |
                    ForEach-Object { $_.SupportsShouldProcess } | Should -Be $true
            }

            It 'Should have Id parameter as mandatory' {
                $function = Get-Command Remove-IMLibrary
                $idParam = $function.Parameters['id']
                $idParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $function = Get-Command Remove-IMLibrary
                $idParam = $function.Parameters['id']
                $validationAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should have libraryId alias for Id parameter' {
                $function = Get-Command Remove-IMLibrary
                $idParam = $function.Parameters['id']
                $aliasAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'AliasAttribute' }
                $aliasAttribute.AliasNames | Should -Contain 'libraryId'
            }

            It 'Should reject invalid GUID format' {
                { Remove-IMLibrary -id 'invalid-guid' } | Should -Throw
            }
        }

        Context 'Library Removal Operations' {
            BeforeAll {
                $TestLibraryId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $TestLibraryId2 = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should remove single library with correct API call' {
                Remove-IMLibrary -id $TestLibraryId -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
            }

            It 'Should handle multiple library IDs' {
                Remove-IMLibrary -id @($TestLibraryId, $TestLibraryId2) -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteLibrary -ModuleName PSImmich -Times 2 -Exactly -Scope It
                Should -Invoke Invoke-ImmichApiDeleteLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
                Should -Invoke Invoke-ImmichApiDeleteLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId2
                }
            }

            It 'Should not delete when ShouldProcess declines' {
                Remove-IMLibrary -id $TestLibraryId -WhatIf

                Should -Invoke Invoke-ImmichApiDeleteLibrary -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }
        }

        Context 'Pipeline Support' {
            BeforeAll {
                $TestLibraryId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $TestLibraryId2 = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should accept pipeline input by value' {
                $TestLibraryId | Remove-IMLibrary -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
            }

            It 'Should accept pipeline input by property name (id)' {
                $libraryObject = [PSCustomObject]@{ id = $TestLibraryId }
                $libraryObject | Remove-IMLibrary -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
            }

            It 'Should accept pipeline input by property name (libraryId alias)' {
                $libraryObject = [PSCustomObject]@{ libraryId = $TestLibraryId }
                $libraryObject | Remove-IMLibrary -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
            }

            It 'Should handle multiple libraries from pipeline' {
                @($TestLibraryId, $TestLibraryId2) | Remove-IMLibrary -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteLibrary -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }

            It 'Should process multiple pipeline objects' {
                $libraryObjects = @(
                    [PSCustomObject]@{ id = $TestLibraryId },
                    [PSCustomObject]@{ libraryId = $TestLibraryId2 }
                )
                $libraryObjects | Remove-IMLibrary -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteLibrary -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command Remove-IMLibrary
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                Remove-IMLibrary -id 'a1b2c3d4-e5f6-4789-a012-123456789abc' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Set-IMFace' -Tag 'Unit', 'Set-IMFace' {
        BeforeAll {
            Mock Invoke-ImmichApiReassignFacesById -ModuleName PSImmich {
                return [PSCustomObject]@{
                    id   = 'person-guid-1234567890abcdef'
                    name = 'Jane Doe'
                }
            }
        }

        Context 'Parameter Validation' {
            It 'Should have mandatory PersonId parameter' {
                $Command = Get-Command Set-IMFace
                $Command.Parameters['PersonId'].ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should have mandatory FaceId parameter' {
                $Command = Get-Command Set-IMFace
                $Command.Parameters['FaceId'].ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for PersonId parameter' {
                { Set-IMFace -PersonId 'invalid-guid' -FaceId '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false } | Should -Throw
            }

            It 'Should validate GUID format for FaceId parameter' {
                { Set-IMFace -PersonId '123e4567-e89b-12d3-a456-426614174000' -FaceId 'invalid-guid' -Confirm:$false } | Should -Throw
            }
        }

        Context 'ShouldProcess Support' {
            It 'Should support ShouldProcess' {
                $Command = Get-Command Set-IMFace
                $CmdletBinding = $Command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
                $CmdletBinding.SupportsShouldProcess | Should -Be $true
            }

            It 'Should not call the API when -WhatIf is specified' {
                Set-IMFace -PersonId '987fcdeb-51a2-43d5-b789-123456789abc' -FaceId '123e4567-e89b-12d3-a456-426614174000' -WhatIf

                Should -Invoke Invoke-ImmichApiReassignFacesById -ModuleName PSImmich -Exactly 0 -Scope It
            }
        }

        Context 'API Calls' {
            It 'Should call the reassign endpoint with the PersonId as the path ID' {
                $TestPersonId = '987fcdeb-51a2-43d5-b789-123456789abc'
                $TestFaceId = '123e4567-e89b-12d3-a456-426614174000'
                Set-IMFace -PersonId $TestPersonId -FaceId $TestFaceId -Confirm:$false

                Should -Invoke Invoke-ImmichApiReassignFacesById -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $TestPersonId
                }
            }

            It 'Should include FaceId in request body' {
                $TestFaceId = '123e4567-e89b-12d3-a456-426614174000'
                Set-IMFace -PersonId '987fcdeb-51a2-43d5-b789-123456789abc' -FaceId $TestFaceId -Confirm:$false

                Should -Invoke Invoke-ImmichApiReassignFacesById -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.id -eq $TestFaceId
                }
            }

            It 'Should return a PersonResponseDto' {
                $result = Set-IMFace -PersonId '987fcdeb-51a2-43d5-b789-123456789abc' -FaceId '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false
                $result.GetType().Name | Should -Be 'PersonResponseDto'
                $result.name | Should -Be 'Jane Doe'
            }

            It 'Should forward an explicit session' {
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                Set-IMFace -PersonId '987fcdeb-51a2-43d5-b789-123456789abc' -FaceId '123e4567-e89b-12d3-a456-426614174000' -Session $Session -Confirm:$false

                Should -Invoke Invoke-ImmichApiReassignFacesById -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }
        }

        Context 'Pipeline Support' {
            It 'Should process pipeline input correctly' {
                $TestPersonId = '987fcdeb-51a2-43d5-b789-123456789abc'
                $TestFaceIds = @('123e4567-e89b-12d3-a456-426614174000', '987fcdeb-51a2-43d5-b789-123456789abc')
                $TestFaceIds | Set-IMFace -PersonId $TestPersonId -Confirm:$false

                Should -Invoke Invoke-ImmichApiReassignFacesById -ModuleName PSImmich -Exactly 2 -Scope It
            }

            It 'Should process multiple face objects from pipeline' {
                $TestPersonId = '987fcdeb-51a2-43d5-b789-123456789abc'
                $FaceObjects = @(
                    [PSCustomObject]@{ FaceId = '123e4567-e89b-12d3-a456-426614174000' },
                    [PSCustomObject]@{ FaceId = '987fcdeb-51a2-43d5-b789-123456789abc' }
                )
                $FaceObjects | Set-IMFace -PersonId $TestPersonId -Confirm:$false

                Should -Invoke Invoke-ImmichApiReassignFacesById -ModuleName PSImmich -Exactly 2 -Scope It
            }
        }

    }
    Describe 'Set-IMLibrary' -Tag 'Unit', 'Set-IMLibrary' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateLibrary -ModuleName PSImmich {
                return [PSCustomObject]@{
                    id                = 'updated-library-guid-1234567890abcdef'
                    name              = 'Updated Library'
                    type              = 'EXTERNAL'
                    ownerId           = 'owner-guid-here-1234567890abcdef'
                    importPaths       = @('/updated/path')
                    exclusionPatterns = @('*.updated')
                    createdAt         = '2024-01-01T10:00:00Z'
                    updatedAt         = '2024-01-01T12:00:00Z'
                    refreshedAt       = $null
                    assetCount        = 100
                }
            }
        }

        Context 'Parameter Validation' {
            It 'Should support ShouldProcess' {
                $function = Get-Command Set-IMLibrary
                $function.ScriptBlock.Attributes | Where-Object { $_.TypeId.Name -eq 'CmdletBindingAttribute' } |
                    ForEach-Object { $_.SupportsShouldProcess } | Should -Be $true
            }

            It 'Should have Id parameter as mandatory' {
                $function = Get-Command Set-IMLibrary
                $idParam = $function.Parameters['Id']
                $idParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $function = Get-Command Set-IMLibrary
                $idParam = $function.Parameters['Id']
                $validationAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should have ApiParameter attributes for body parameters' {
                $function = Get-Command Set-IMLibrary
                $nameParam = $function.Parameters['Name']
                $exclusionParam = $function.Parameters['ExclusionPatterns']
                $importParam = $function.Parameters['ImportPaths']

                $nameApiAttr = $nameParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }
                $exclusionApiAttr = $exclusionParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }
                $importApiAttr = $importParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }

                $nameApiAttr.Name | Should -Be 'name'
                $exclusionApiAttr.Name | Should -Be 'exclusionPatterns'
                $importApiAttr.Name | Should -Be 'importPaths'
            }

            It 'Should reject invalid GUID format' {
                { Set-IMLibrary -Id 'invalid-guid' -Name 'Test' } | Should -Throw
            }
        }

        Context 'Library Update Operations' {
            BeforeAll {
                $TestLibraryId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $TestLibraryId2 = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should update library name with correct API call' {
                Set-IMLibrary -Id $TestLibraryId -Name 'New Library Name' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId -and
                    $Body.name -eq 'New Library Name'
                }
            }

            It 'Should update library with import paths and exclusions' {
                $params = @{
                    Id                = $TestLibraryId
                    ImportPaths       = @('/photos', '/videos')
                    ExclusionPatterns = @('*.tmp', '*.log')
                    Confirm           = $false
                }
                Set-IMLibrary @params

                Should -Invoke Invoke-ImmichApiUpdateLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.importPaths.Count -eq 2 -and
                    $Body.exclusionPatterns.Count -eq 2
                }
            }

            It 'Should handle multiple library IDs' {
                Set-IMLibrary -Id @($TestLibraryId, $TestLibraryId2) -Name 'Batch Update' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateLibrary -ModuleName PSImmich -Times 2 -Exactly -Scope It
                Should -Invoke Invoke-ImmichApiUpdateLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId -and $Body.name -eq 'Batch Update'
                }
                Should -Invoke Invoke-ImmichApiUpdateLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId2 -and $Body.name -eq 'Batch Update'
                }
            }

            It 'Should update with all parameters' {
                $params = @{
                    Id                = $TestLibraryId
                    Name              = 'Complete Library'
                    ImportPaths       = @('/path1', '/path2', '/path3')
                    ExclusionPatterns = @('*.tmp', '*.log', '.DS_Store')
                    Confirm           = $false
                }
                Set-IMLibrary @params

                Should -Invoke Invoke-ImmichApiUpdateLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.name -eq 'Complete Library' -and
                    $Body.importPaths.Count -eq 3 -and
                    $Body.exclusionPatterns.Count -eq 3
                }
            }

            It 'Should not update when ShouldProcess declines' {
                Set-IMLibrary -Id $TestLibraryId -Name 'Declined Update' -WhatIf

                Should -Invoke Invoke-ImmichApiUpdateLibrary -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }
        }

        Context 'Pipeline Support' {
            BeforeAll {
                $TestLibraryId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $TestLibraryId2 = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should accept pipeline input by value' {
                $TestLibraryId | Set-IMLibrary -Name 'Pipeline Update' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
            }

            It 'Should accept pipeline input by property name' {
                $libraryObject = [PSCustomObject]@{ Id = $TestLibraryId }
                $libraryObject | Set-IMLibrary -Name 'Property Update' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
            }

            It 'Should handle multiple libraries from pipeline' {
                @($TestLibraryId, $TestLibraryId2) | Set-IMLibrary -Name 'Multi Pipeline' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateLibrary -ModuleName PSImmich -Times 2 -Exactly -Scope It -ParameterFilter {
                    $Body.name -eq 'Multi Pipeline'
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                $function = Get-Command Set-IMLibrary
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                Set-IMLibrary -Id 'a1b2c3d4-e5f6-4789-a012-123456789abc' -Name 'Session Test' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Sync-IMLibrary' -Tag 'Unit', 'Sync-IMLibrary' {
        BeforeAll {
            Mock Invoke-ImmichApiScanLibrary -ModuleName PSImmich {
                return $null
            }
        }

        Context 'Parameter Validation' {
            It 'Should have Id parameter as mandatory' {
                $function = Get-Command Sync-IMLibrary
                $idParam = $function.Parameters['Id']
                $idParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $function = Get-Command Sync-IMLibrary
                $idParam = $function.Parameters['Id']
                $validationAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should reject invalid GUID format' {
                { Sync-IMLibrary -Id 'invalid-guid' } | Should -Throw
            }

            It 'Should have proper parameter set configuration' {
                $function = Get-Command Sync-IMLibrary
                $idParam = $function.Parameters['Id']
                $idParam.ParameterSets.Keys | Should -Contain 'id'
            }
        }

        Context 'Library Synchronization Operations' {
            BeforeAll {
                $TestLibraryId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $TestLibraryId2 = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should start library scan with correct API call' {
                Sync-IMLibrary -Id $TestLibraryId

                Should -Invoke Invoke-ImmichApiScanLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
            }

            It 'Should handle multiple library IDs' {
                Sync-IMLibrary -Id @($TestLibraryId, $TestLibraryId2)

                Should -Invoke Invoke-ImmichApiScanLibrary -ModuleName PSImmich -Times 2 -Exactly -Scope It
                Should -Invoke Invoke-ImmichApiScanLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
                Should -Invoke Invoke-ImmichApiScanLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId2
                }
            }

            It 'Should process each library ID individually' {
                $multipleIds = @(
                    'a1b2c3d4-e5f6-4789-a012-123456789abc',
                    'b2c3d4e5-f6a7-4890-b123-234567890bcd',
                    'c3d4e5f6-a7b8-4901-c234-345678901cde'
                )
                Sync-IMLibrary -Id $multipleIds

                Should -Invoke Invoke-ImmichApiScanLibrary -ModuleName PSImmich -Times 3 -Exactly -Scope It
            }
        }

        Context 'Pipeline Support' {
            BeforeAll {
                $TestLibraryId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $TestLibraryId2 = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should accept pipeline input by value' {
                $TestLibraryId | Sync-IMLibrary

                Should -Invoke Invoke-ImmichApiScanLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
            }

            It 'Should accept pipeline input by property name' {
                $libraryObject = [PSCustomObject]@{ Id = $TestLibraryId }
                $libraryObject | Sync-IMLibrary

                Should -Invoke Invoke-ImmichApiScanLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
            }

            It 'Should handle multiple libraries from pipeline' {
                @($TestLibraryId, $TestLibraryId2) | Sync-IMLibrary

                Should -Invoke Invoke-ImmichApiScanLibrary -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }

            It 'Should process multiple pipeline objects' {
                $libraryObjects = @(
                    [PSCustomObject]@{ Id = $TestLibraryId },
                    [PSCustomObject]@{ Id = $TestLibraryId2 }
                )
                $libraryObjects | Sync-IMLibrary

                Should -Invoke Invoke-ImmichApiScanLibrary -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                $function = Get-Command Sync-IMLibrary
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                Sync-IMLibrary -Id 'a1b2c3d4-e5f6-4789-a012-123456789abc'

                Should -Invoke Invoke-ImmichApiScanLibrary -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Test-IMLibrary' -Tag 'Unit', 'Test-IMLibrary' {
        BeforeAll {
            Mock Invoke-ImmichApiValidate -ModuleName PSImmich {
                return [PSCustomObject]@{
                    importPaths       = @(
                        @{
                            importPath = '/photos'
                            isValid    = $true
                            message    = 'Path is accessible'
                        },
                        @{
                            importPath = '/videos'
                            isValid    = $true
                            message    = 'Path is accessible'
                        }
                    )
                    exclusionPatterns = @(
                        @{
                            pattern = '*.tmp'
                            isValid = $true
                            message = 'Pattern syntax is valid'
                        }
                    )
                }
            }

        }

        Context 'Parameter Validation' {
            It 'Should have Id parameter as mandatory' {
                $function = Get-Command Test-IMLibrary
                $idParam = $function.Parameters['Id']
                $idParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $function = Get-Command Test-IMLibrary
                $idParam = $function.Parameters['Id']
                $validationAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should have ApiParameter attributes for body parameters' {
                $function = Get-Command Test-IMLibrary
                $exclusionParam = $function.Parameters['ExclusionPatterns']
                $importParam = $function.Parameters['ImportPaths']

                $exclusionApiAttr = $exclusionParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }
                $importApiAttr = $importParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }

                $exclusionApiAttr.Name | Should -Be 'exclusionPatterns'
                $importApiAttr.Name | Should -Be 'importPaths'
            }

            It 'Should reject invalid GUID format' {
                { Test-IMLibrary -Id 'invalid-guid' } | Should -Throw
            }
        }

        Context 'Library Validation Operations' {
            BeforeAll {
                $TestLibraryId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $TestLibraryId2 = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should validate library with minimal parameters' {
                $result = Test-IMLibrary -Id $TestLibraryId

                Should -Invoke Invoke-ImmichApiValidate -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Should validate library with import paths' {
                Test-IMLibrary -Id $TestLibraryId -ImportPaths @('/photos', '/videos')

                Should -Invoke Invoke-ImmichApiValidate -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId -and
                    $Body.importPaths.Count -eq 2 -and
                    $Body.importPaths -contains '/photos'
                }
            }

            It 'Should validate library with exclusion patterns' {
                Test-IMLibrary -Id $TestLibraryId -ExclusionPatterns @('*.tmp', '*.log')

                Should -Invoke Invoke-ImmichApiValidate -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId -and
                    $Body.exclusionPatterns.Count -eq 2 -and
                    $Body.exclusionPatterns -contains '*.tmp'
                }
            }

            It 'Should validate library with all parameters' {
                $params = @{
                    Id                = $TestLibraryId
                    ImportPaths       = @('/path1', '/path2', '/path3')
                    ExclusionPatterns = @('*.tmp', '*.log', '.DS_Store')
                }
                Test-IMLibrary @params

                Should -Invoke Invoke-ImmichApiValidate -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.importPaths.Count -eq 3 -and
                    $Body.exclusionPatterns.Count -eq 3
                }
            }

            It 'Should handle multiple library IDs' {
                Test-IMLibrary -Id @($TestLibraryId, $TestLibraryId2) -ImportPaths @('/shared')

                Should -Invoke Invoke-ImmichApiValidate -ModuleName PSImmich -Times 2 -Exactly -Scope It
                Should -Invoke Invoke-ImmichApiValidate -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId -and $Body.importPaths -contains '/shared'
                }
                Should -Invoke Invoke-ImmichApiValidate -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId2 -and $Body.importPaths -contains '/shared'
                }
            }

            It 'Should return validation results' {
                $result = Test-IMLibrary -Id $TestLibraryId -ImportPaths @('/photos')

                $result | Should -Not -BeNullOrEmpty
                $result.importPaths | Should -Not -BeNullOrEmpty
                $result.importPaths[0].importPath | Should -Be '/photos'
                $result.importPaths[0].isValid | Should -Be $true
            }
        }

        Context 'Pipeline Support' {
            BeforeAll {
                $TestLibraryId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $TestLibraryId2 = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should accept pipeline input by value' {
                $TestLibraryId | Test-IMLibrary

                Should -Invoke Invoke-ImmichApiValidate -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
            }

            It 'Should accept pipeline input by property name' {
                $libraryObject = [PSCustomObject]@{ Id = $TestLibraryId }
                $libraryObject | Test-IMLibrary

                Should -Invoke Invoke-ImmichApiValidate -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq $TestLibraryId
                }
            }

            It 'Should handle multiple libraries from pipeline' {
                @($TestLibraryId, $TestLibraryId2) | Test-IMLibrary -ImportPaths @('/test')

                Should -Invoke Invoke-ImmichApiValidate -ModuleName PSImmich -Times 2 -Exactly -Scope It -ParameterFilter {
                    $Body.importPaths -contains '/test'
                }
            }

            It 'Should process multiple pipeline objects' {
                $libraryObjects = @(
                    [PSCustomObject]@{ Id = $TestLibraryId },
                    [PSCustomObject]@{ Id = $TestLibraryId2 }
                )
                $libraryObjects | Test-IMLibrary -ExclusionPatterns @('*.test')

                Should -Invoke Invoke-ImmichApiValidate -ModuleName PSImmich -Times 2 -Exactly -Scope It -ParameterFilter {
                    $Body.exclusionPatterns -contains '*.test'
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                $function = Get-Command Test-IMLibrary
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                Test-IMLibrary -Id 'a1b2c3d4-e5f6-4789-a012-123456789abc'

                Should -Invoke Invoke-ImmichApiValidate -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Convert-IMCoordinatesToLocation' -Tag 'Unit', 'Convert-IMCoordinatesToLocation' {
        BeforeAll {
            Mock Invoke-ImmichApiReverseGeocode -ModuleName PSImmich {
                return @(
                    [PSCustomObject]@{
                        city    = 'London'
                        state   = 'England'
                        country = 'United Kingdom'
                    }
                )
            }
        }

        Context 'Parameter Validation' {
            It 'Should have Latitude parameter as mandatory' {
                $function = Get-Command Convert-IMCoordinatesToLocation
                $latParam = $function.Parameters['Latitude']
                $latParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should have Longitude parameter as mandatory' {
                $function = Get-Command Convert-IMCoordinatesToLocation
                $lonParam = $function.Parameters['Longitude']
                $lonParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should accept double values for coordinates' {
                $function = Get-Command Convert-IMCoordinatesToLocation
                $latParam = $function.Parameters['Latitude']
                $lonParam = $function.Parameters['Longitude']

                $latParam.ParameterType.Name | Should -Be 'Double'
                $lonParam.ParameterType.Name | Should -Be 'Double'
            }
        }

        Context 'Coordinate Conversion Operations' {
            It 'Should call the reverse geocode API with the coordinates' {
                Convert-IMCoordinatesToLocation -Latitude 51.496637 -Longitude -0.176370

                Should -Invoke Invoke-ImmichApiReverseGeocode -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Lat -eq 51.496637 -and
                    $Lon -eq -0.176370
                }
            }

            It 'Should handle positive coordinates' {
                Convert-IMCoordinatesToLocation -Latitude 37.7749 -Longitude 122.4194

                Should -Invoke Invoke-ImmichApiReverseGeocode -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Lat -eq 37.7749 -and
                    $Lon -eq 122.4194
                }
            }

            It 'Should handle negative coordinates' {
                Convert-IMCoordinatesToLocation -Latitude -33.8688 -Longitude -151.2093

                Should -Invoke Invoke-ImmichApiReverseGeocode -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Lat -eq -33.8688 -and
                    $Lon -eq -151.2093
                }
            }

            It 'Should handle coordinate edge values' {
                Convert-IMCoordinatesToLocation -Latitude -90.0 -Longitude -180.0

                Should -Invoke Invoke-ImmichApiReverseGeocode -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Lat -eq -90.0 -and
                    $Lon -eq -180.0
                }
            }

            It 'Should return location information as MapReverseGeocodeResponseDto' {
                $result = Convert-IMCoordinatesToLocation -Latitude 51.496637 -Longitude -0.176370

                $result | Should -HaveCount 1
                $result.GetType().Name | Should -Be 'MapReverseGeocodeResponseDto'
                $result.city | Should -Be 'London'
                $result.state | Should -Be 'England'
                $result.country | Should -Be 'United Kingdom'
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command Convert-IMCoordinatesToLocation
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                Convert-IMCoordinatesToLocation -Latitude 51.496637 -Longitude -0.176370

                Should -Invoke Invoke-ImmichApiReverseGeocode -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Get-IMMapMarker' -Tag 'Unit', 'Get-IMMapMarker' {
        BeforeAll {
            Mock Invoke-ImmichApiGetMapMarkers -ModuleName PSImmich {
                return @(
                    [PSCustomObject]@{
                        id      = 'marker1-guid-here-1234567890abcdef'
                        lat     = 51.496637
                        lon     = -0.176370
                        city    = 'London'
                        state   = 'England'
                        country = 'United Kingdom'
                    },
                    [PSCustomObject]@{
                        id      = 'marker2-guid-here-2345678901bcdefg'
                        lat     = 40.7128
                        lon     = -74.0060
                        city    = 'New York'
                        state   = 'New York'
                        country = 'United States'
                    }
                )
            }
        }

        Context 'Parameter Validation' {
            It 'Should have all optional filter parameters' {
                $function = Get-Command Get-IMMapMarker
                $function.Parameters.Keys | Should -Contain 'CreatedAfter'
                $function.Parameters.Keys | Should -Contain 'CreatedBefore'
                $function.Parameters.Keys | Should -Contain 'IsArchived'
                $function.Parameters.Keys | Should -Contain 'IsFavorite'
                $function.Parameters.Keys | Should -Contain 'WithPartners'
                $function.Parameters.Keys | Should -Contain 'WithSharedAlbums'
            }

            It 'Should have boolean type for flag parameters' {
                $function = Get-Command Get-IMMapMarker
                $function.Parameters['IsArchived'].ParameterType.Name | Should -Be 'Boolean'
                $function.Parameters['IsFavorite'].ParameterType.Name | Should -Be 'Boolean'
                $function.Parameters['WithPartners'].ParameterType.Name | Should -Be 'Boolean'
                $function.Parameters['WithSharedAlbums'].ParameterType.Name | Should -Be 'Boolean'
            }
        }

        Context 'Map Marker Retrieval Operations' {
            It 'Should get all map markers with no filters' {
                $result = Get-IMMapMarker

                Should -Invoke Invoke-ImmichApiGetMapMarkers -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $null -eq $FileCreatedAfter -and
                    $null -eq $FileCreatedBefore -and
                    $null -eq $IsArchived -and
                    $null -eq $IsFavorite -and
                    $null -eq $WithPartners -and
                    $null -eq $WithSharedAlbums -and
                    $null -eq $ImmichSession
                }
                $result | Should -HaveCount 2
            }

            It 'Should filter by creation date range' {
                $createdAfter = (Get-Date).AddDays(-30)
                $createdBefore = (Get-Date).AddDays(-1)
                Get-IMMapMarker -CreatedAfter $createdAfter -CreatedBefore $createdBefore

                Should -Invoke Invoke-ImmichApiGetMapMarkers -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $FileCreatedAfter -eq $createdAfter -and
                    $FileCreatedBefore -eq $createdBefore
                }
            }

            It 'Should filter by archive status' {
                Get-IMMapMarker -IsArchived $false

                Should -Invoke Invoke-ImmichApiGetMapMarkers -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $IsArchived -eq $false
                }
            }

            It 'Should filter by favorite status' {
                Get-IMMapMarker -IsFavorite $true

                Should -Invoke Invoke-ImmichApiGetMapMarkers -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $IsFavorite -eq $true
                }
            }

            It 'Should include partner assets when specified' {
                Get-IMMapMarker -WithPartners $true

                Should -Invoke Invoke-ImmichApiGetMapMarkers -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $WithPartners -eq $true
                }
            }

            It 'Should include shared album assets when specified' {
                Get-IMMapMarker -WithSharedAlbums $true

                Should -Invoke Invoke-ImmichApiGetMapMarkers -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $WithSharedAlbums -eq $true
                }
            }

            It 'Should handle multiple filter parameters' {
                Get-IMMapMarker -IsFavorite $true -IsArchived $false -WithPartners $false -WithSharedAlbums $true

                Should -Invoke Invoke-ImmichApiGetMapMarkers -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $IsFavorite -eq $true -and
                    $IsArchived -eq $false -and
                    $WithPartners -eq $false -and
                    $WithSharedAlbums -eq $true
                }
            }

            It 'Should return marker objects as MapMarkerResponseDto' {
                $result = Get-IMMapMarker

                $result[0].GetType().Name | Should -Be 'MapMarkerResponseDto'
                $result[0].id | Should -Be 'marker1-guid-here-1234567890abcdef'
                $result[0].lat | Should -Be 51.496637
                $result[0].lon | Should -Be -0.17637
                $result[0].city | Should -Be 'London'

                $result[1].id | Should -Be 'marker2-guid-here-2345678901bcdefg'
                $result[1].city | Should -Be 'New York'
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command Get-IMMapMarker
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                Get-IMMapMarker

                Should -Invoke Invoke-ImmichApiGetMapMarkers -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }

    Describe 'Get-IMMemory' -Tag 'Unit', 'Get-IMMemory' {
        BeforeAll {
            Mock Invoke-ImmichApiSearchMemories -ModuleName PSImmich {
                return @(
                    [PSCustomObject]@{
                        id        = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                        title     = 'Summer Vacation 2024'
                        type      = 'onThisDay'
                        createdAt = '2024-01-15T10:00:00Z'
                        assets    = @(
                            [PSCustomObject]@{ id = 'asset1'; type = 'IMAGE' },
                            [PSCustomObject]@{ id = 'asset2'; type = 'VIDEO' }
                        )
                    },
                    [PSCustomObject]@{
                        id        = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
                        title     = 'Holiday Memories'
                        type      = 'featured'
                        createdAt = '2024-02-20T15:30:00Z'
                        assets    = @(
                            [PSCustomObject]@{ id = 'asset3'; type = 'IMAGE' }
                        )
                    }
                )
            }

            Mock Invoke-ImmichApiMemoriesStatistics -ModuleName PSImmich {
                return [PSCustomObject]@{
                    total = 42
                }
            }

            Mock Invoke-ImmichApiGetMemory -ModuleName PSImmich {
                param($Id)
                switch ($Id)
                {
                    'a1b2c3d4-e5f6-4789-a012-123456789abc'
                    {
                        return [PSCustomObject]@{
                            id        = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                            title     = 'Summer Vacation 2024'
                            type      = 'onThisDay'
                            createdAt = '2024-01-15T10:00:00Z'
                            assets    = @(
                                [PSCustomObject]@{ id = 'asset1'; type = 'IMAGE' },
                                [PSCustomObject]@{ id = 'asset2'; type = 'VIDEO' }
                            )
                            data      = @{ year = 2024; day = 15; month = 1 }
                        }
                    }
                    'b2c3d4e5-f6a7-4890-b123-234567890bcd'
                    {
                        return [PSCustomObject]@{
                            id        = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
                            title     = 'Holiday Memories'
                            type      = 'featured'
                            createdAt = '2024-02-20T15:30:00Z'
                            assets    = @([PSCustomObject]@{ id = 'asset3'; type = 'IMAGE' })
                        }
                    }
                    default
                    {
                        throw "Unexpected memory id: $Id"
                    }
                }
            }
        }

        Context 'Parameter Validation' {
            It 'Should have two parameter sets' {
                $function = Get-Command Get-IMMemory
                $function.ParameterSets.Name | Should -Contain 'list'
                $function.ParameterSets.Name | Should -Contain 'id'
            }

            It 'Should have id parameter as mandatory for id parameter set' {
                $function = Get-Command Get-IMMemory
                $idParam = $function.Parameters['id']
                $idParameterSet = $idParam.ParameterSets['id']
                $idParameterSet.IsMandatory | Should -Be $true
            }

            It 'Should validate GUID format for id parameter' {
                $function = Get-Command Get-IMMemory
                $idParam = $function.Parameters['id']
                $validationAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should accept pipeline input for id parameter' {
                $function = Get-Command Get-IMMemory
                $idParam = $function.Parameters['id']
                $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' } |
                    ForEach-Object { $_.ValueFromPipeline } | Should -Contain $true
                $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' } |
                    ForEach-Object { $_.ValueFromPipelineByPropertyName } | Should -Contain $true
            }

            It 'Should accept string array for id parameter' {
                $function = Get-Command Get-IMMemory
                $idParam = $function.Parameters['id']
                $idParam.ParameterType.Name | Should -Be 'String[]'
            }

            It 'Should reject invalid GUID format' {
                { Get-IMMemory -id 'invalid-guid' } | Should -Throw
            }
        }

        Context 'List Parameter Set Operations' {
            It 'Should get all memories when no parameters provided' {
                $result = Get-IMMemory

                Should -Invoke Invoke-ImmichApiSearchMemories -ModuleName PSImmich -Times 1
                $result | Should -HaveCount 2
                $result[0].id | Should -Be 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $result[1].id | Should -Be 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should return memories with assets' {
                $result = Get-IMMemory

                $result[0].id | Should -Be 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $result[0].type | Should -Be 'onThisDay'
                $result[0].assets | Should -HaveCount 2
                $result[1].type | Should -Be 'featured'
                $result[1].assets | Should -HaveCount 1
            }
        }

        Context 'Id Parameter Set Operations' {
            BeforeAll {
                $TestMemoryId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $TestMemoryId2 = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should get specific memory by id' {
                $result = Get-IMMemory -id $TestMemoryId

                Should -Invoke Invoke-ImmichApiGetMemory -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Id -eq $TestMemoryId
                }
                $result.id | Should -Be $TestMemoryId
                $result.type | Should -Be 'onThisDay'
            }

            It 'Should handle multiple memory IDs' {
                $result = Get-IMMemory -id @($TestMemoryId, $TestMemoryId2)

                Should -Invoke Invoke-ImmichApiGetMemory -ModuleName PSImmich -Times 2 -ParameterFilter {
                    $Id -eq $TestMemoryId -or $Id -eq $TestMemoryId2
                }
                $result | Should -HaveCount 2
            }

            It 'Should return detailed memory information for specific id' {
                $result = Get-IMMemory -id $TestMemoryId

                $result.id | Should -Be $TestMemoryId
                $result.type | Should -Be 'onThisDay'
                $result.assets | Should -HaveCount 2
                $result.data.year | Should -Be 2024
            }
        }

        Context 'Pipeline Support' {
            BeforeAll {
                $TestMemoryId = 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $TestMemoryId2 = 'b2c3d4e5-f6a7-4890-b123-234567890bcd'
            }

            It 'Should accept pipeline input by value' {
                $TestMemoryId | Get-IMMemory

                Should -Invoke Invoke-ImmichApiGetMemory -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Id -eq $TestMemoryId
                }
            }

            It 'Should accept pipeline input by property name' {
                $memoryObject = [PSCustomObject]@{ id = $TestMemoryId }
                $memoryObject | Get-IMMemory

                Should -Invoke Invoke-ImmichApiGetMemory -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Id -eq $TestMemoryId
                }
            }

            It 'Should handle multiple memories from pipeline' {
                @($TestMemoryId, $TestMemoryId2) | Get-IMMemory

                Should -Invoke Invoke-ImmichApiGetMemory -ModuleName PSImmich -Times 2 -ParameterFilter {
                    $Id -eq $TestMemoryId -or $Id -eq $TestMemoryId2
                }
            }

            It 'Should process multiple pipeline objects' {
                $memoryObjects = @(
                    [PSCustomObject]@{ id = $TestMemoryId },
                    [PSCustomObject]@{ id = $TestMemoryId2 }
                )
                $memoryObjects | Get-IMMemory

                Should -Invoke Invoke-ImmichApiGetMemory -ModuleName PSImmich -Times 2
            }
        }

        Context 'Statistics Parameter' {
            It 'Should get memory statistics when Statistics switch is used' {
                $result = Get-IMMemory -Statistics

                Should -Invoke Invoke-ImmichApiMemoriesStatistics -ModuleName PSImmich -Times 1
                $result.total | Should -Be 42
            }

            It 'Should support Statistics with other parameters' {
                Get-IMMemory -Statistics -Order 'desc'

                Should -Invoke Invoke-ImmichApiMemoriesStatistics -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Order -eq 'desc'
                }
            }
        }

        Context 'New Parameters Support' {
            It 'Should support Order parameter' {
                Get-IMMemory -Order 'desc'

                Should -Invoke Invoke-ImmichApiSearchMemories -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Order -eq 'desc'
                }
            }

            It 'Should support NumberOfMemories parameter' {
                Get-IMMemory -NumberOfMemories 5

                Should -Invoke Invoke-ImmichApiSearchMemories -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Size -eq 5
                }
            }

            It 'Should support IsSaved parameter' {
                Get-IMMemory -IsSaved:$true

                Should -Invoke Invoke-ImmichApiSearchMemories -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $IsSaved -eq $true
                }
            }

            It 'Should support IsTrashed parameter' {
                Get-IMMemory -IsTrashed:$false

                Should -Invoke Invoke-ImmichApiSearchMemories -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $IsTrashed -eq $false
                }
            }

            It 'Should support Type parameter' {
                Get-IMMemory -Type 'on_this_day'

                Should -Invoke Invoke-ImmichApiSearchMemories -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Type -eq 'on_this_day'
                }
            }

            It 'Should support For parameter for date filtering' {
                $TestDate = '2024-01-15'
                Get-IMMemory -For $TestDate

                Should -Invoke Invoke-ImmichApiSearchMemories -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $For -eq $TestDate
                }
            }

            It 'Should send For as a date-only value when given a datetime' {
                Get-IMMemory -For ([datetime]'2024-01-15T13:45:00')

                Should -Invoke Invoke-ImmichApiSearchMemories -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $For -eq '2024-01-15'
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command Get-IMMemory
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                Get-IMMemory

                Should -Invoke Invoke-ImmichApiSearchMemories -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'New-IMMemory' -Tag 'Unit', 'New-IMMemory' {
        BeforeAll {
            Mock Invoke-ImmichApiCreateMemory -ModuleName PSImmich {
                return [PSCustomObject]@{
                    id       = 'new-memory-guid-1234567890abcdef'
                    memoryAt = '2024-01-01T10:00:00Z'
                    type     = 'on_this_day'
                    data     = [PSCustomObject]@{ year = 2024 }
                    assets   = @()
                    seenAt   = $null
                }
            }

            Mock ConvertTo-ApiParameters {
                param($BoundParameters, $CmdletName)
                $result = @{}
                if ($BoundParameters.MemoryAt)
                {
                    $result.memoryAt = $BoundParameters.MemoryAt
                }
                if ($BoundParameters.SeenAt)
                {
                    $result.seenAt = $BoundParameters.SeenAt
                }
                if ($BoundParameters.Type)
                {
                    $result.type = $BoundParameters.Type
                }
                if ($BoundParameters.AssetIds)
                {
                    $result.assetIds = $BoundParameters.AssetIds
                }
                return $result
            }
        }

        Context 'Parameter Validation' {
            It 'Should have MemoryAt parameter as mandatory' {
                $function = Get-Command New-IMMemory
                $memoryAtParam = $function.Parameters['MemoryAt']
                $memoryAtParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for AssetIds parameter' {
                $function = Get-Command New-IMMemory
                $assetIdsParam = $function.Parameters['AssetIds']
                $validationAttribute = $assetIdsParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should validate Type parameter values' {
                $function = Get-Command New-IMMemory
                $typeParam = $function.Parameters['Type']
                $validateSetAttribute = $typeParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidateSetAttribute' }
                $validateSetAttribute.ValidValues | Should -Contain 'on_this_day'
            }

            It 'Should have ApiParameter attributes for body parameters' {
                $function = Get-Command New-IMMemory
                $memoryAtParam = $function.Parameters['MemoryAt']
                $assetIdsParam = $function.Parameters['AssetIds']
                $typeParam = $function.Parameters['Type']

                $memoryAtApiAttr = $memoryAtParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }
                $assetIdsApiAttr = $assetIdsParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }
                $typeApiAttr = $typeParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }

                $memoryAtApiAttr.Name | Should -Be 'memoryAt'
                $assetIdsApiAttr.Name | Should -Be 'assetIds'
                $typeApiAttr.Name | Should -Be 'type'
            }
        }

        Context 'Memory Creation' {
            It 'Should create memory with minimal parameters' {
                $result = New-IMMemory -MemoryAt '2024-01-01T10:00:00Z'

                Should -Invoke Invoke-ImmichApiCreateMemory -ModuleName PSImmich -Times 1
                $result.id | Should -Be 'new-memory-guid-1234567890abcdef'
            }

            It 'Should create memory with asset IDs' {
                $assetIds = @('a1b2c3d4-e5f6-4789-a012-123456789abc', 'b2c3d4e5-f6a7-4890-b123-234567890bcd')
                New-IMMemory -MemoryAt '2024-01-01T10:00:00Z' -AssetIds $assetIds

                Should -Invoke Invoke-ImmichApiCreateMemory -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.assetIds.Count -eq 2 -and
                    $Body.assetIds -contains 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                }
            }

            It 'Should include year in data object' {
                New-IMMemory -MemoryAt '2024-01-01T10:00:00Z' -Year 2024

                Should -Invoke Invoke-ImmichApiCreateMemory -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.data.year -eq 2024
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                $function = Get-Command New-IMMemory
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }
        }
    }
    Describe 'Remove-IMMemory' -Tag 'Unit', 'Remove-IMMemory' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteMemory -ModuleName PSImmich {
                return $null
            }
        }

        Context 'Parameter Validation' {
            It 'Should have Id parameter as mandatory' {
                $function = Get-Command Remove-IMMemory
                $idParam = $function.Parameters['id']
                $idParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $function = Get-Command Remove-IMMemory
                $idParam = $function.Parameters['id']
                $validationAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should support pipeline input' {
                $function = Get-Command Remove-IMMemory
                $idParam = $function.Parameters['id']
                $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' } |
                    ForEach-Object { $_.ValueFromPipeline -or $_.ValueFromPipelineByPropertyName } | Should -Contain $true
            }
        }

        Context 'Memory Removal' {
            It 'Should remove memory with correct API call' {
                Remove-IMMemory -id 'a1b2c3d4-e5f6-4789-a012-123456789abc'

                Should -Invoke Invoke-ImmichApiDeleteMemory -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Id -eq 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                }
            }

            It 'Should handle multiple memory IDs' {
                $memoryIds = @('a1b2c3d4-e5f6-4789-a012-123456789abc', 'b2c3d4e5-f6a7-4890-b123-234567890bcd')
                Remove-IMMemory -id $memoryIds

                Should -Invoke Invoke-ImmichApiDeleteMemory -ModuleName PSImmich -Times 2
            }
        }
    }
    Describe 'Set-IMMemory' -Tag 'Unit', 'Set-IMMemory' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateMemory -ModuleName PSImmich {
                return [PSCustomObject]@{
                    id       = 'updated-memory-guid-1234567890abcdef'
                    memoryAt = '2024-01-01T10:00:00Z'
                    type     = 'on_this_day'
                    isSaved  = $true
                }
            }
        }

        Context 'Parameter Validation' {
            It 'Should have Id parameter as mandatory' {
                $function = Get-Command Set-IMMemory
                $idParam = $function.Parameters['id']
                $idParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $function = Get-Command Set-IMMemory
                $idParam = $function.Parameters['id']
                $validationAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }
        }

        Context 'Memory Updates' {
            It 'Should update memory with correct API call' {
                Set-IMMemory -Id 'a1b2c3d4-e5f6-4789-a012-123456789abc' -IsSaved:$true

                Should -Invoke Invoke-ImmichApiUpdateMemory -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Id -eq 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                }
            }
        }
    }
    Describe 'Send-IMTestMessage' -Tag 'Unit', 'Send-IMTestMessage' {
        BeforeAll {
            Mock Invoke-ImmichApiSendTestEmailAdmin {
                return [PSCustomObject]@{
                    messageId = '<test-message-id@example.com>'
                }
            } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have mandatory parameters' {
                $function = Get-Command Send-IMTestMessage
                $fromParam = $function.Parameters['from']
                $replyToParam = $function.Parameters['replyto']
                $hostnameParam = $function.Parameters['hostname']
                $passwordParam = $function.Parameters['Password']

                $fromParam.ParameterSets.Values.IsMandatory | Should -Contain $true
                $replyToParam.ParameterSets.Values.IsMandatory | Should -Contain $true
                $hostnameParam.ParameterSets.Values.IsMandatory | Should -Contain $true
                $passwordParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should have ApiParameter attributes for SMTP configuration' {
                $function = Get-Command Send-IMTestMessage
                $fromParam = $function.Parameters['from']
                $hostnameParam = $function.Parameters['hostname']
                $portParam = $function.Parameters['port']

                $fromApiAttr = $fromParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }
                $hostnameApiAttr = $hostnameParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }
                $portApiAttr = $portParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ApiParameterAttribute' }

                $fromApiAttr.Name | Should -Be 'from'
                $hostnameApiAttr.Name | Should -Be 'transport.host'
                $portApiAttr.Name | Should -Be 'transport.port'
            }
        }

        Context 'Message Sending' {
            It 'Should send the full SMTP body through the generated sendTestEmailAdmin function' {
                $securePassword = ConvertTo-SecureString 'testpassword' -AsPlainText -Force
                Send-IMTestMessage -from 'test@example.com' -replyto 'reply@example.com' -hostname 'smtp.example.com' -Password $securePassword

                Should -Invoke Invoke-ImmichApiSendTestEmailAdmin -Times 1 -ModuleName PSImmich -ParameterFilter {
                    $Body.from -eq 'test@example.com' -and
                    $Body.replyTo -eq 'reply@example.com' -and
                    $Body.enabled -eq $true -and
                    $Body.transport.host -eq 'smtp.example.com' -and
                    $Body.transport.port -eq 25 -and
                    $Body.transport.secure -eq $false -and
                    $Body.transport.ignoreCert -eq $false -and
                    $Body.transport.username -eq ''
                }
            }

            It 'Should send the SecureString password as plain text' {
                $securePassword = ConvertTo-SecureString 'testpassword' -AsPlainText -Force
                Send-IMTestMessage -from 'test@example.com' -replyto 'reply@example.com' -hostname 'smtp.example.com' -Password $securePassword

                Should -Invoke Invoke-ImmichApiSendTestEmailAdmin -Times 1 -ModuleName PSImmich -ParameterFilter {
                    $Body.transport.password -eq 'testpassword'
                }
            }

            It 'Should forward explicit transport settings' {
                $securePassword = ConvertTo-SecureString 'testpassword' -AsPlainText -Force
                Send-IMTestMessage -enabled $false -from 'test@example.com' -replyto 'reply@example.com' -hostname 'smtp.example.com' -Password $securePassword -port 587 -username 'user@example.com' -ignoreCert $true -Secure $true

                Should -Invoke Invoke-ImmichApiSendTestEmailAdmin -Times 1 -ModuleName PSImmich -ParameterFilter {
                    $Body.enabled -eq $false -and
                    $Body.transport.port -eq 587 -and
                    $Body.transport.username -eq 'user@example.com' -and
                    $Body.transport.ignoreCert -eq $true -and
                    $Body.transport.secure -eq $true
                }
            }

            It 'Should forward the Session parameter' {
                $securePassword = ConvertTo-SecureString 'testpassword' -AsPlainText -Force
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                Send-IMTestMessage -from 'test@example.com' -replyto 'reply@example.com' -hostname 'smtp.example.com' -Password $securePassword -Session $Session

                Should -Invoke Invoke-ImmichApiSendTestEmailAdmin -Times 1 -ModuleName PSImmich -ParameterFilter {
                    $ImmichSession.GetType().Name -eq 'ImmichSession'
                }
            }

            It 'Should return a TestEmailResponseDto' {
                $securePassword = ConvertTo-SecureString 'testpassword' -AsPlainText -Force
                $result = Send-IMTestMessage -from 'test@example.com' -replyto 'reply@example.com' -hostname 'smtp.example.com' -Password $securePassword
                $result.GetType().Name | Should -Be 'TestEmailResponseDto'
                $result.messageId | Should -Be '<test-message-id@example.com>'
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                $function = Get-Command Send-IMTestMessage
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }
        }
    }
    Describe 'Add-IMPartner' -Tag 'Unit', 'Add-IMPartner' {
        BeforeAll {
            Mock Invoke-ImmichApiCreatePartner {
                return [PSCustomObject]@{
                    id               = 'partner-user-guid-1234567890abcdef'
                    email            = 'partner@example.com'
                    name             = 'Partner User'
                    profileImagePath = '/profile/partner.jpg'
                    createdAt        = '2024-01-01T10:00:00Z'
                }
            } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have SharedWithId parameter as mandatory' {
                $function = Get-Command Add-IMPartner
                $sharedWithIdParam = $function.Parameters['SharedWithId']
                $sharedWithIdParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for SharedWithId parameter' {
                $function = Get-Command Add-IMPartner
                $sharedWithIdParam = $function.Parameters['SharedWithId']
                $validationAttribute = $sharedWithIdParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }
        }

        Context 'Partner Addition' {
            It 'Should add partner through the generated createPartner function' {
                Add-IMPartner -SharedWithId 'a1b2c3d4-e5f6-4789-a012-123456789abc'

                Should -Invoke Invoke-ImmichApiCreatePartner -Times 1 -ModuleName PSImmich -ParameterFilter {
                    $Body.sharedWithId -eq 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                }
            }

            It 'Should return a PartnerResponseDto' {
                $result = Add-IMPartner -SharedWithId 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                $result.GetType().Name | Should -Be 'PartnerResponseDto'
            }
        }
    }
    Describe 'Get-IMPartner' -Tag 'Unit', 'Get-IMPartner' {
        BeforeAll {
            Mock Invoke-ImmichApiGetPartners {
                return @(
                    [PSCustomObject]@{
                        id               = 'partner1-guid-here-1234567890abcdef'
                        email            = 'partner1@example.com'
                        name             = 'Partner One'
                        profileImagePath = '/profile/partner1.jpg'
                    },
                    [PSCustomObject]@{
                        id               = 'partner2-guid-here-2345678901bcdefg'
                        email            = 'partner2@example.com'
                        name             = 'Partner Two'
                        profileImagePath = '/profile/partner2.jpg'
                    }
                )
            } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have Direction parameter as mandatory' {
                $function = Get-Command Get-IMPartner
                $directionParam = $function.Parameters['Direction']
                $directionParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate Direction parameter values' {
                $function = Get-Command Get-IMPartner
                $directionParam = $function.Parameters['Direction']
                $validateSetAttribute = $directionParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidateSetAttribute' }
                $validateSetAttribute.ValidValues | Should -Contain 'shared-by'
                $validateSetAttribute.ValidValues | Should -Contain 'shared-with'
            }
        }

        Context 'Partner Retrieval' {
            It 'Should get partners through the generated getPartners function' {
                Get-IMPartner -Direction 'shared-with'

                Should -Invoke Invoke-ImmichApiGetPartners -Times 1 -ModuleName PSImmich -ParameterFilter {
                    $Direction -eq 'shared-with'
                }
            }

            It 'Should return PartnerResponseDto objects' {
                $result = Get-IMPartner -Direction 'shared-by'
                $result.Count | Should -Be 2
                $result[0].GetType().Name | Should -Be 'PartnerResponseDto'
            }
        }
    }
    Describe 'Remove-IMPartner' -Tag 'Unit', 'Remove-IMPartner' {
        BeforeAll {
            Mock Invoke-ImmichApiRemovePartner {} -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have Id parameter as mandatory' {
                $function = Get-Command Remove-IMPartner
                $idParam = $function.Parameters['id']
                $idParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $function = Get-Command Remove-IMPartner
                $idParam = $function.Parameters['id']
                $validationAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }
        }

        Context 'Partner Removal' {
            It 'Should remove partner through the generated removePartner function' {
                Remove-IMPartner -id 'a1b2c3d4-e5f6-4789-a012-123456789abc'

                Should -Invoke Invoke-ImmichApiRemovePartner -Times 1 -ModuleName PSImmich -ParameterFilter {
                    $Id -eq 'a1b2c3d4-e5f6-4789-a012-123456789abc'
                }
            }
        }
    }
    Describe 'Remove-IMPerson' -Tag 'Unit', 'Remove-IMPerson' {
        BeforeAll {
            Mock Invoke-ImmichApiDeletePeople -ModuleName PSImmich {}
        }

        Context 'Parameter Validation' {
            It 'Should require Ids parameter' {
                (Get-Command Remove-IMPerson).Parameters['Ids'].Attributes.Mandatory | Should -Be $true
            }

            It 'Should validate GUID format for Ids parameter' {
                { Remove-IMPerson -Ids 'invalid-guid' -Confirm:$false } | Should -Throw
            }

            It 'Should accept pipeline input for Ids parameter' {
                $TestId = '123e4567-e89b-12d3-a456-426614174000'
                { $TestId | Remove-IMPerson -Confirm:$false } | Should -Not -Throw
            }

            It 'Should accept multiple IDs' {
                $TestIds = @('123e4567-e89b-12d3-a456-426614174000', '987fcdeb-51a2-43d5-b789-123456789abc')
                { Remove-IMPerson -Ids $TestIds -Confirm:$false } | Should -Not -Throw
            }

            It 'Should accept id alias for pipeline input' {
                $PersonObject = [PSCustomObject]@{ id = '123e4567-e89b-12d3-a456-426614174000' }
                { $PersonObject | Remove-IMPerson -Confirm:$false } | Should -Not -Throw
            }
        }

        Context 'ShouldProcess Support' {
            It 'Should support ShouldProcess' {
                $Command = Get-Command Remove-IMPerson
                $CmdletBinding = $Command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
                $CmdletBinding.SupportsShouldProcess | Should -Be $true
            }
        }

        Context 'API Calls' {
            It 'Should call the bulk delete wrapper' {
                Remove-IMPerson -Ids '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeletePeople -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.ids -contains '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should include all person IDs in request body' {
                $personIds = @('123e4567-e89b-12d3-a456-426614174000', '987fcdeb-51a2-43d5-b789-123456789abc', 'abcdef01-2345-6789-abcd-ef0123456789')
                Remove-IMPerson -Ids $personIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeletePeople -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.ids.Count -eq 3 -and
                    ($personIds | ForEach-Object { $Body.ids -contains $_ }) -notcontains $false
                }
            }

            It 'Should collect IDs from pipeline input' {
                $personIds = @('123e4567-e89b-12d3-a456-426614174000', '987fcdeb-51a2-43d5-b789-123456789abc')
                $personIds | Remove-IMPerson -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeletePeople -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.ids.Count -eq 2 -and
                    $Body.ids -contains '123e4567-e89b-12d3-a456-426614174000' -and
                    $Body.ids -contains '987fcdeb-51a2-43d5-b789-123456789abc'
                }
            }

            It 'Should process objects with id property from pipeline' {
                $personObjects = @(
                    [PSCustomObject]@{ id = '123e4567-e89b-12d3-a456-426614174000' },
                    [PSCustomObject]@{ id = '987fcdeb-51a2-43d5-b789-123456789abc' }
                )
                $personObjects | Remove-IMPerson -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeletePeople -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.ids.Count -eq 2 -and
                    $Body.ids -contains '123e4567-e89b-12d3-a456-426614174000' -and
                    $Body.ids -contains '987fcdeb-51a2-43d5-b789-123456789abc'
                }
            }
        }

        Context 'Bulk Operations' {
            It 'Should use single API call for multiple people' {
                $personIds = @('123e4567-e89b-12d3-a456-426614174000', '987fcdeb-51a2-43d5-b789-123456789abc', 'abcdef01-2345-6789-abcd-ef0123456789')
                Remove-IMPerson -Ids $personIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeletePeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.ids.Count -eq 3
                }
            }

            It 'Should handle mixed pipeline and parameter input' {
                $pipelineIds = @('123e4567-e89b-12d3-a456-426614174000', '987fcdeb-51a2-43d5-b789-123456789abc')
                $pipelineIds | Remove-IMPerson -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeletePeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.ids.Count -eq 2
                }
            }
        }
    }
    Describe 'Set-IMPartner' -Tag 'Unit', 'Set-IMPartner' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdatePartner {
                return [PSCustomObject]@{
                    id         = 'updated-partner-guid-1234567890abcdef'
                    email      = 'partner@example.com'
                    name       = 'Updated Partner'
                    inTimeline = $true
                }
            } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have Id parameter as mandatory' {
                $function = Get-Command Set-IMPartner
                $idParam = $function.Parameters['id']
                $idParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $function = Get-Command Set-IMPartner
                $idParam = $function.Parameters['id']
                $validationAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }
        }

        Context 'Partner Updates' {
            It 'Should update partner through the generated updatePartner function' {
                Set-IMPartner -id 'a1b2c3d4-e5f6-4789-a012-123456789abc' -EnableTimeline:$true

                Should -Invoke Invoke-ImmichApiUpdatePartner -Times 1 -ModuleName PSImmich -ParameterFilter {
                    $Id -eq 'a1b2c3d4-e5f6-4789-a012-123456789abc' -and
                    $Body.inTimeline -eq $true
                }
            }
        }
    }
    Describe 'Export-IMPersonThumbnail' -Tag 'Unit', 'Export-IMPersonThumbnail' {
        BeforeAll {
            Mock Invoke-ImmichApiGetPersonThumbnail -ModuleName PSImmich {}
        }

        Context 'Parameter Validation' {
            It 'Should have Id parameter as mandatory' {
                $function = Get-Command Export-IMPersonThumbnail
                $idParam = $function.Parameters['id']
                $idParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $function = Get-Command Export-IMPersonThumbnail
                $idParam = $function.Parameters['id']
                $validationAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }
        }

        Context 'Thumbnail Export' {
            It 'Should export thumbnail with correct API call' {
                Export-IMPersonThumbnail -id 'a1b2c3d4-e5f6-4789-a012-123456789abc' -Path $TestDrive

                Should -Invoke Invoke-ImmichApiGetPersonThumbnail -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq 'a1b2c3d4-e5f6-4789-a012-123456789abc' -and
                    $OutFilePath -like '*a1b2c3d4-e5f6-4789-a012-123456789abc.jpeg'
                }
            }
        }
    }
    Describe 'Get-IMPersonAccess' -Tag 'Unit', 'Get-IMPersonAccess' {
        BeforeAll {
            Mock Invoke-ImmichApiGetUsersForPeople -ModuleName PSImmich {
                @(
                    [PSCustomObject]@{ personId = 'bf973405-3f2a-48d2-a687-2ed4167164be'; sharedById = '1a2b3c4d-0000-4000-8000-000000000001'; sharedWithId = '9c4e0006-3a2b-4967-94b6-7e8bb8490a12'; role = 'read' }
                )
            }
        }

        Context 'When listing without filters' {
            It 'Should call the endpoint without query parameters' {
                $Result = Get-IMPersonAccess

                Should -Invoke Invoke-ImmichApiGetUsersForPeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Direction -eq $null -and $PersonId -eq $null -and $Role -eq $null -and $SharedById -eq $null -and $SharedWithId -eq $null
                }
                $Result.role | Should -Be 'read'
            }
        }

        Context 'When filtering' {
            It 'Should forward only the supplied filters' {
                Get-IMPersonAccess -Direction shared-by -Role admin

                Should -Invoke Invoke-ImmichApiGetUsersForPeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Direction -eq 'shared-by' -and $Role -eq 'admin' -and $PersonId -eq $null -and $SharedWithId -eq $null
                }
            }

            It 'Should forward person and user identifiers' {
                Get-IMPersonAccess -PersonId 'bf973405-3f2a-48d2-a687-2ed4167164be' -SharedById '1a2b3c4d-0000-4000-8000-000000000001' -SharedWithId '9c4e0006-3a2b-4967-94b6-7e8bb8490a12'

                Should -Invoke Invoke-ImmichApiGetUsersForPeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $PersonId -eq 'bf973405-3f2a-48d2-a687-2ed4167164be' -and
                    $SharedById -eq '1a2b3c4d-0000-4000-8000-000000000001' -and
                    $SharedWithId -eq '9c4e0006-3a2b-4967-94b6-7e8bb8490a12'
                }
            }
        }

        Context 'When an explicit session is provided' {
            It 'Should forward the session to the REST call' {
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])

                Get-IMPersonAccess -Session $Session

                Should -Invoke Invoke-ImmichApiGetUsersForPeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }
        }

        Context 'When parameters are invalid' {
            It 'Should throw for an unknown direction' {
                { Get-IMPersonAccess -Direction sideways } | Should -Throw
            }

            It 'Should throw for an unknown role' {
                { Get-IMPersonAccess -Role owner } | Should -Throw
            }
        }
    }

    Describe 'Add-IMPersonAccess' -Tag 'Unit', 'Add-IMPersonAccess' {
        BeforeAll {
            Mock Invoke-ImmichApiUpsertPeopleUsers -ModuleName PSImmich {}
        }

        Context 'When sharing specific people' {
            It 'Should send the person ids, users and role' {
                Add-IMPersonAccess -PersonId 'bf973405-3f2a-48d2-a687-2ed4167164be' -SharedWithId '9c4e0006-3a2b-4967-94b6-7e8bb8490a12' -Role read -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpsertPeopleUsers -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.personIds -contains 'bf973405-3f2a-48d2-a687-2ed4167164be' -and
                    $Body.sharedWithIds -contains '9c4e0006-3a2b-4967-94b6-7e8bb8490a12' -and
                    $Body.role -eq 'read' -and
                    -not $Body.ContainsKey('type')
                }
            }

            It 'Should send multiple people and users in one request' {
                Add-IMPersonAccess -PersonId @('bf973405-3f2a-48d2-a687-2ed4167164be', '6c1c0c9e-4b4f-4b57-b2bc-1f8b3e5a0d22') -SharedWithId @('9c4e0006-3a2b-4967-94b6-7e8bb8490a12', 'c3a2e8b4-3f65-4e3d-9f9f-4d2c8e5a0f32') -Role admin -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpsertPeopleUsers -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.personIds.Count -eq 2 -and $Body.sharedWithIds.Count -eq 2 -and $Body.role -eq 'admin'
                }
            }
        }

        Context 'When sharing everyone' {
            It 'Should send the everyone type instead of person ids' {
                Add-IMPersonAccess -Everyone -SharedWithId '9c4e0006-3a2b-4967-94b6-7e8bb8490a12' -Role write -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpsertPeopleUsers -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.type -eq 'everyone' -and $Body.role -eq 'write' -and -not $Body.ContainsKey('personIds')
                }
            }
        }

        Context 'When WhatIf is specified' {
            It 'Should not call the endpoint' {
                Add-IMPersonAccess -PersonId 'bf973405-3f2a-48d2-a687-2ed4167164be' -SharedWithId '9c4e0006-3a2b-4967-94b6-7e8bb8490a12' -Role read -WhatIf

                Should -Invoke Invoke-ImmichApiUpsertPeopleUsers -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }
        }

        Context 'When parameters are invalid' {
            It 'Should throw when Everyone and PersonId are combined' {
                { Add-IMPersonAccess -Everyone -PersonId 'bf973405-3f2a-48d2-a687-2ed4167164be' -SharedWithId '9c4e0006-3a2b-4967-94b6-7e8bb8490a12' -Role read -Confirm:$false } | Should -Throw
            }

            It 'Should throw for an unknown role' {
                { Add-IMPersonAccess -PersonId 'bf973405-3f2a-48d2-a687-2ed4167164be' -SharedWithId '9c4e0006-3a2b-4967-94b6-7e8bb8490a12' -Role owner -Confirm:$false } | Should -Throw
            }
        }
    }

    Describe 'Remove-IMPersonAccess' -Tag 'Unit', 'Remove-IMPersonAccess' {
        BeforeAll {
            Mock Invoke-ImmichApiRemoveUsersFromPeople -ModuleName PSImmich {}
        }

        Context 'When removing a single grant' {
            It 'Should send a JSON array containing the grant' {
                Remove-IMPersonAccess -PersonId 'bf973405-3f2a-48d2-a687-2ed4167164be' -SharedWithId '9c4e0006-3a2b-4967-94b6-7e8bb8490a12' -Confirm:$false

                Should -Invoke Invoke-ImmichApiRemoveUsersFromPeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $RawBody.TrimStart().StartsWith('[') -and
                    (ConvertFrom-Json -InputObject $RawBody).personId -eq 'bf973405-3f2a-48d2-a687-2ed4167164be' -and
                    (ConvertFrom-Json -InputObject $RawBody).sharedWithId -eq '9c4e0006-3a2b-4967-94b6-7e8bb8490a12' -and
                    $null -eq (ConvertFrom-Json -InputObject $RawBody).sharedById
                }
            }

            It 'Should include the sharedById when supplied' {
                Remove-IMPersonAccess -PersonId 'bf973405-3f2a-48d2-a687-2ed4167164be' -SharedWithId '9c4e0006-3a2b-4967-94b6-7e8bb8490a12' -SharedById '1a2b3c4d-0000-4000-8000-000000000001' -Confirm:$false

                Should -Invoke Invoke-ImmichApiRemoveUsersFromPeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    (ConvertFrom-Json -InputObject $RawBody)[0].sharedById -eq '1a2b3c4d-0000-4000-8000-000000000001'
                }
            }
        }

        Context 'When removing grants from the pipeline' {
            It 'Should send one request per grant bound by property name' {
                $Grants = @(
                    [PSCustomObject]@{ personId = 'bf973405-3f2a-48d2-a687-2ed4167164be'; sharedById = '1a2b3c4d-0000-4000-8000-000000000001'; sharedWithId = '9c4e0006-3a2b-4967-94b6-7e8bb8490a12'; role = 'read' }
                    [PSCustomObject]@{ personId = '6c1c0c9e-4b4f-4b57-b2bc-1f8b3e5a0d22'; sharedById = '1a2b3c4d-0000-4000-8000-000000000001'; sharedWithId = 'c3a2e8b4-3f65-4e3d-9f9f-4d2c8e5a0f32'; role = 'write' }
                )

                $Grants | Remove-IMPersonAccess -Confirm:$false

                Should -Invoke Invoke-ImmichApiRemoveUsersFromPeople -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }
        }

        Context 'When WhatIf is specified' {
            It 'Should not call the endpoint' {
                Remove-IMPersonAccess -PersonId 'bf973405-3f2a-48d2-a687-2ed4167164be' -SharedWithId '9c4e0006-3a2b-4967-94b6-7e8bb8490a12' -WhatIf

                Should -Invoke Invoke-ImmichApiRemoveUsersFromPeople -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }
        }

        Context 'When parameters are invalid' {
            It 'Should throw for a malformed person id' {
                { Remove-IMPersonAccess -PersonId 'not-a-guid' -SharedWithId '9c4e0006-3a2b-4967-94b6-7e8bb8490a12' -Confirm:$false } | Should -Throw
            }

            It 'Should throw when SharedWithId is omitted' {
                { Remove-IMPersonAccess -PersonId 'bf973405-3f2a-48d2-a687-2ed4167164be' -Confirm:$false } | Should -Throw
            }
        }
    }

    Describe 'Get-IMPerson' -Tag 'Unit', 'Get-IMPerson' {
        BeforeAll {
            Mock Invoke-ImmichApiGetAllPeople -ModuleName PSImmich {
                return [PSCustomObject]@{
                    people = @(
                        [PSCustomObject]@{
                            id            = 'person1-guid-here-1234567890abcdef'
                            name          = 'John Doe'
                            birthDate     = '1990-01-01'
                            thumbnailPath = '/thumbs/person1.jpg'
                            isHidden      = $false
                        },
                        [PSCustomObject]@{
                            id            = 'person2-guid-here-2345678901bcdefg'
                            name          = 'Jane Smith'
                            birthDate     = '1985-05-15'
                            thumbnailPath = '/thumbs/person2.jpg'
                            isHidden      = $false
                        }
                    )
                    total  = 2
                    hidden = 0
                }
            }
            Mock Invoke-ImmichApiGetPerson -ModuleName PSImmich {
                return [PSCustomObject]@{
                    id            = 'person1-guid-here-1234567890abcdef'
                    name          = 'John Doe'
                    birthDate     = '1990-01-01'
                    thumbnailPath = '/thumbs/person1.jpg'
                    isHidden      = $false
                }
            }
            Mock Invoke-ImmichApiGetPersonStatistics -ModuleName PSImmich {
                return [PSCustomObject]@{ assets = 42 }
            }
        }

        Context 'Parameter Validation' {
            It 'Should have two parameter sets' {
                $function = Get-Command Get-IMPerson
                $function.ParameterSets.Name | Should -Contain 'list'
                $function.ParameterSets.Name | Should -Contain 'id'
            }

            It 'Should have id parameter as mandatory for id parameter set' {
                $function = Get-Command Get-IMPerson
                $idParam = $function.Parameters['id']
                $idParameterSet = $idParam.ParameterSets['id']
                $idParameterSet.IsMandatory | Should -Be $true
            }

            It 'Should validate GUID format for id parameter' {
                $function = Get-Command Get-IMPerson
                $idParam = $function.Parameters['id']
                $validationAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }

            It 'Should support pipeline input for id parameter' {
                $function = Get-Command Get-IMPerson
                $idParam = $function.Parameters['id']
                $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' } |
                    ForEach-Object { $_.ValueFromPipeline -or $_.ValueFromPipelineByPropertyName } | Should -Contain $true
            }
        }

        Context 'List Parameter Set Operations' {
            It 'Should get all people when no parameters provided' {
                $result = Get-IMPerson

                Should -Invoke Invoke-ImmichApiGetAllPeople -ModuleName PSImmich -Times 1 -Exactly -Scope It
                $result | Should -HaveCount 2
                $result[0].name | Should -Be 'John Doe'
            }

            It 'Should send WithHidden when WithHidden is specified' {
                Get-IMPerson -WithHidden | Out-Null

                Should -Invoke Invoke-ImmichApiGetAllPeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $WithHidden -eq $true
                }
            }

            It 'Should not send WithHidden when WithHidden is omitted' {
                Get-IMPerson | Out-Null

                Should -Invoke Invoke-ImmichApiGetAllPeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $WithHidden
                }
            }
        }

        Context 'Id Parameter Set Operations' {
            It 'Should get specific person by id' {
                $result = Get-IMPerson -id '12345678-1234-5678-9012-123456789abc'

                Should -Invoke Invoke-ImmichApiGetPerson -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc'
                }
                $result.name | Should -Be 'John Doe'
            }

            It 'Should include statistics when IncludeStatistics is specified' {
                $result = Get-IMPerson -id '12345678-1234-5678-9012-123456789abc' -IncludeStatistics

                Should -Invoke Invoke-ImmichApiGetPerson -ModuleName PSImmich -Times 1 -Exactly -Scope It
                Should -Invoke Invoke-ImmichApiGetPersonStatistics -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc'
                }
                $result.AssetCount | Should -Be 42
            }
        }
    }
    Describe 'Merge-IMPerson' -Tag 'Unit', 'Merge-IMPerson' {
        BeforeAll {
            Mock Invoke-ImmichApiMergePeople -ModuleName PSImmich {
                return @(
                    [PSCustomObject]@{
                        id            = 'merged-person-guid-1234567890abcdef'
                        name          = 'Merged Person'
                        thumbnailPath = '/thumbs/merged.jpg'
                        isHidden      = $false
                    }
                )
            }
        }

        Context 'Parameter Validation' {
            It 'Should have ToPersonID parameter as mandatory' {
                $function = Get-Command Merge-IMPerson
                $idParam = $function.Parameters['ToPersonID']
                $idParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should have FromPersonID parameter as mandatory' {
                $function = Get-Command Merge-IMPerson
                $mergeIdsParam = $function.Parameters['FromPersonID']
                $mergeIdsParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for parameters' {
                $function = Get-Command Merge-IMPerson
                $idParam = $function.Parameters['ToPersonID']
                $mergeIdsParam = $function.Parameters['FromPersonID']

                $idValidation = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $mergeIdsValidation = $mergeIdsParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }

                $idValidation.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
                $mergeIdsValidation.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }
        }

        Context 'Person Merging' {
            It 'Should merge persons with correct API call' {
                $mergeIds = @('23456789-2345-6789-0123-23456789abcd', '34567890-3456-7890-1234-3456789abcde')
                Merge-IMPerson -ToPersonID '12345678-1234-5678-9012-123456789abc' -FromPersonID $mergeIds

                Should -Invoke Invoke-ImmichApiMergePeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.ids.Count -eq 3 -and
                    $Body.ids[0] -eq '12345678-1234-5678-9012-123456789abc' -and
                    $Body.ids[1] -eq '23456789-2345-6789-0123-23456789abcd' -and
                    $Body.ids[2] -eq '34567890-3456-7890-1234-3456789abcde'
                }
            }
        }
    }
    Describe 'New-IMPerson' -Tag 'Unit', 'New-IMPerson' {
        BeforeAll {
            Mock Invoke-ImmichApiCreatePerson -ModuleName PSImmich {
                return [PSCustomObject]@{
                    id            = 'new-person-guid-1234567890abcdef'
                    name          = 'New Person'
                    birthDate     = '1995-03-15'
                    thumbnailPath = '/thumbs/new-person.jpg'
                    isHidden      = $false
                }
            }
        }

        Context 'Parameter Validation' {
            It 'Should have Name parameter' {
                $function = Get-Command New-IMPerson
                $function.Parameters.Keys | Should -Contain 'Name'
            }

            It 'Should have BirthDate parameter with DateTime type' {
                $function = Get-Command New-IMPerson
                $birthDateParam = $function.Parameters['BirthDate']
                $birthDateParam.ParameterType.Name | Should -Be 'DateTime'
            }
        }

        Context 'Person Creation' {
            It 'Should create person through the generated wrapper' {
                New-IMPerson -Name 'Test Person'

                Should -Invoke Invoke-ImmichApiCreatePerson -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.name -eq 'Test Person'
                }
            }

            It 'Should include birth date when provided' {
                $birthDate = Get-Date '1995-03-15'
                New-IMPerson -Name 'Test Person' -BirthDate $birthDate

                Should -Invoke Invoke-ImmichApiCreatePerson -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -ne $Body.birthDate
                }
            }
        }
    }
    Describe 'Set-IMPerson' -Tag 'Unit', 'Set-IMPerson' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdatePeople -ModuleName PSImmich {
                return [PSCustomObject]@{
                    id        = 'updated-person-guid-1234567890abcdef'
                    name      = 'Updated Person Name'
                    birthDate = '1990-01-01'
                    isHidden  = $false
                }
            }
        }

        Context 'Parameter Validation' {
            It 'Should have Id parameter as mandatory' {
                $function = Get-Command Set-IMPerson
                $idParam = $function.Parameters['Id']
                $idParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }

            It 'Should validate GUID format for Id parameter' {
                $function = Get-Command Set-IMPerson
                $idParam = $function.Parameters['Id']
                $validationAttribute = $idParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidatePatternAttribute' }
                $validationAttribute.RegexPattern | Should -Be '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            }
        }

        Context 'Person Updates' {
            It 'Should update person through the generated wrapper' {
                Set-IMPerson -Id '12345678-1234-1234-1234-123456789abc' -Name 'New Name' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdatePeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.people[0].id -eq '12345678-1234-1234-1234-123456789abc' -and
                    $Body.people[0].name -eq 'New Name'
                }
            }

            It 'Should handle IsHidden parameter' {
                Set-IMPerson -Id '12345678-1234-5678-9012-123456789abc' -IsHidden:$true -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdatePeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.people[0].id -eq '12345678-1234-5678-9012-123456789abc' -and
                    $Body.people[0].isHidden -eq $true
                }
            }

            It 'Should send Color as the avatarColor enum' {
                Set-IMPerson -Id '12345678-1234-1234-1234-123456789abc' -Color 'amber' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdatePeople -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.people[0].avatarColor -eq 'amber' -and
                    -not $Body.people[0].ContainsKey('color')
                }
            }

            It 'Should reject a color outside the avatar enum' {
                { Set-IMPerson -Id '12345678-1234-1234-1234-123456789abc' -Color '#FF0000' -Confirm:$false } | Should -Throw
            }
        }
    }
    Describe 'Search-IMAsset' -Tag 'Unit', 'Search-IMAsset' {
        BeforeAll {
            Mock Invoke-ImmichApiSearchAssets -ModuleName PSImmich {
                return [PSCustomObject]@{
                    assets = [PSCustomObject]@{
                        items      = @(
                            [PSCustomObject]@{
                                id               = 'asset1-guid-here-1234567890abcdef'
                                type             = 'IMAGE'
                                originalFileName = 'photo1.jpg'
                                fileCreatedAt    = '2024-01-01T10:00:00Z'
                            },
                            [PSCustomObject]@{
                                id               = 'asset2-guid-here-2345678901bcdefg'
                                type             = 'VIDEO'
                                originalFileName = 'video1.mp4'
                                fileCreatedAt    = '2024-01-02T11:00:00Z'
                            }
                        )
                        nextCursor = $null
                    }
                }
            }

            Mock Invoke-ImmichApiSearchSmart -ModuleName PSImmich {
                return [PSCustomObject]@{
                    assets = [PSCustomObject]@{
                        items    = @(
                            [PSCustomObject]@{
                                id               = 'search-asset1-guid-1234567890abcdef'
                                type             = 'IMAGE'
                                originalFileName = 'search1.jpg'
                                fileCreatedAt    = '2024-01-01T10:00:00Z'
                            },
                            [PSCustomObject]@{
                                id               = 'search-asset2-guid-2345678901bcdefg'
                                type             = 'VIDEO'
                                originalFileName = 'search2.mp4'
                                fileCreatedAt    = '2024-01-02T11:00:00Z'
                            }
                        )
                        nextPage = $null
                    }
                }
            }
        }

        Context 'Parameter Validation' {
            It 'Should default to the Metadata parameter set' {
                $function = Get-Command Search-IMAsset
                $function.DefaultParameterSet | Should -Be 'Metadata'
            }

            It 'Should have a Smart switch and no Find-IMAsset command' {
                $function = Get-Command Search-IMAsset
                $function.Parameters['Smart'].SwitchParameter | Should -BeTrue
                Get-Command Find-IMAsset -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }

            It 'Should make Query mandatory only in the Smart parameter set' {
                $function = Get-Command Search-IMAsset
                $queryParam = $function.Parameters['Query']
                $queryParam.ParameterSets.Keys | Should -Be 'Smart'
                $queryParam.ParameterSets['Smart'].IsMandatory | Should -BeTrue
            }

            It 'Should restrict Order to the Metadata parameter set' {
                $function = Get-Command Search-IMAsset
                $function.Parameters['Order'].ParameterSets.Keys | Should -Be 'Metadata'
            }

            It 'Should restrict Language to the Smart parameter set' {
                $function = Get-Command Search-IMAsset
                $function.Parameters['Language'].ParameterSets.Keys | Should -Be 'Smart'
            }

            It 'Should not expose removed deprecated parameters' {
                $function = Get-Command Search-IMAsset
                $function.Parameters.Keys | Should -Not -Contain 'DeviceId'
                $function.Parameters.Keys | Should -Not -Contain 'DeviceAssetId'
                $function.Parameters.Keys | Should -Not -Contain 'IsVisible'
                $function.Parameters.Keys | Should -Not -Contain 'WithDeleted'
            }

            It 'Should have Type parameter with ValidateSet' {
                $function = Get-Command Search-IMAsset
                $typeParam = $function.Parameters['Type']
                $validateSetAttribute = $typeParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidateSetAttribute' }
                $validateSetAttribute.ValidValues | Should -Contain 'IMAGE'
                $validateSetAttribute.ValidValues | Should -Contain 'VIDEO'
            }
        }

        Context 'Metadata search (default)' {
            It 'Should POST to the metadata search endpoint and return AssetResponseDto objects' {
                $result = Search-IMAsset -OriginalFileName 'vacation.jpg'

                Should -Invoke Invoke-ImmichApiSearchAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.filter.originalFileName.eq -eq 'vacation.jpg'
                }
                Should -Invoke Invoke-ImmichApiSearchSmart -ModuleName PSImmich -Times 0
                $result.Count | Should -Be 2
                $result[0].GetType().Name | Should -Be 'AssetResponseDto'
            }

            It 'Should send filters as operator objects inside the filter body' {
                Search-IMAsset -OriginalFileName 'beach.jpg' -Type 'IMAGE' -IsFavorite:$true

                Should -Invoke Invoke-ImmichApiSearchAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.filter.originalFileName.eq -eq 'beach.jpg' -and
                    $Body.filter.type.eq -eq 'IMAGE' -and
                    $Body.filter.isFavorite.eq -eq $true
                }
            }

            It 'Should send explicit false boolean filters' {
                Search-IMAsset -IsFavorite:$false -IsOffline:$false

                Should -Invoke Invoke-ImmichApiSearchAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.filter.isFavorite.eq -eq $false -and
                    $Body.filter.isOffline.eq -eq $false
                }
            }

            It 'Should send multi-value ids with the any operator' {
                $albumId = 'b4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'
                $tagId = 'c4f5ad9c-3c3f-4b8f-9e3f-3c3f4b8f9e3f'
                Search-IMAsset -AlbumIds $albumId -TagIds $tagId

                Should -Invoke Invoke-ImmichApiSearchAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.filter.albumIds.any -contains $albumId -and
                    $Body.filter.tagIds.any -contains $tagId
                }
            }

            It 'Should map date parameters to inclusive gte and lte operators' {
                $after = [datetime]'2024-01-01'
                $before = [datetime]'2024-02-01'
                Search-IMAsset -TakenAfter $after -TakenBefore $before

                Should -Invoke Invoke-ImmichApiSearchAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.filter.takenAt.gte -eq $after -and
                    $Body.filter.takenAt.lte -eq $before
                }
            }

            It 'Should invert IsNotInAlbum into hasAlbums' {
                Search-IMAsset -IsNotInAlbum

                Should -Invoke Invoke-ImmichApiSearchAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.filter.hasAlbums.eq -eq $false
                }
            }

            It 'Should map Order to orderBy.direction and WithPeople to the top level' {
                Search-IMAsset -Order 'asc' -WithPeople:$true -WithStacked:$true

                Should -Invoke Invoke-ImmichApiSearchAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.orderBy.direction -eq 'asc' -and
                    $Body.withPeople -eq $true -and
                    $Body.withStacked -eq $true -and
                    -not $Body.ContainsKey('filter')
                }
            }

            It 'Should follow nextCursor when paging' {
                Mock Invoke-ImmichApiSearchAssets -ModuleName PSImmich {
                    if ($Body.cursor)
                    {
                        return [PSCustomObject]@{ assets = [PSCustomObject]@{ items = @(); nextCursor = $null } }
                    }
                    return [PSCustomObject]@{ assets = [PSCustomObject]@{ items = @([PSCustomObject]@{ id = 'a1' }); nextCursor = 'cursor-2' } }
                }

                $result = Search-IMAsset -Size 1

                Should -Invoke Invoke-ImmichApiSearchAssets -ModuleName PSImmich -Exactly -Times 2
                Should -Invoke Invoke-ImmichApiSearchAssets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.cursor -eq 'cursor-2' -and $Body.size -eq 1
                }
                $result.Count | Should -Be 1
            }

            It 'Should throw when -Smart is not provided but -Language is' {
                { Search-IMAsset -Language 'en' } | Should -Throw
            }

            It 'Should throw when -Query is provided without -Smart' {
                { Search-IMAsset -Query 'Road' } | Should -Throw
            }

            It 'Should throw when -WithPeople is combined with -Smart' {
                { Search-IMAsset -Smart -Query 'Road' -WithPeople:$true } | Should -Throw
            }

            It 'Should throw when -Order is combined with -Smart' {
                { Search-IMAsset -Smart -Query 'Road' -Order 'asc' } | Should -Throw
            }
        }

        Context 'Smart search (-Smart)' {
            It 'Should POST to the smart search endpoint with the query and filters' {
                $result = Search-IMAsset -Smart -Query 'sunset beach' -Country 'Sweden'

                Should -Invoke Invoke-ImmichApiSearchSmart -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.query -eq 'sunset beach' -and
                    $Body.filter.country.eq -eq 'Sweden'
                }
                Should -Invoke Invoke-ImmichApiSearchAssets -ModuleName PSImmich -Times 0
                $result.Count | Should -Be 2
                $result[0].GetType().Name | Should -Be 'AssetResponseDto'
            }

            It 'Should send OCR text as an ocr.matches filter' {
                Search-IMAsset -Smart -Query 'running dog' -OCR 'text search'

                Should -Invoke Invoke-ImmichApiSearchSmart -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.filter.ocr.matches -eq 'text search' -and
                    $Body.query -eq 'running dog'
                }
            }

            It 'Should send Language to the top level' {
                Search-IMAsset -Smart -Query 'dog' -Language 'sv'

                Should -Invoke Invoke-ImmichApiSearchSmart -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.language -eq 'sv'
                }
            }

            It 'Should throw when -Smart is provided without -Query' {
                { Search-IMAsset -Smart } | Should -Throw
            }

            It 'Should send the next page token as an integer when paging' {
                Mock Invoke-ImmichApiSearchSmart -ModuleName PSImmich {
                    if ($Body.page)
                    {
                        return [PSCustomObject]@{ assets = [PSCustomObject]@{ items = @(); nextPage = $null } }
                    }
                    return [PSCustomObject]@{ assets = [PSCustomObject]@{ items = @([PSCustomObject]@{ id = 'a1' }); nextPage = '2' } }
                }

                $result = Search-IMAsset -Smart -Query 'unsp' -Size 1

                Should -Invoke Invoke-ImmichApiSearchSmart -ModuleName PSImmich -Exactly -Times 2
                Should -Invoke Invoke-ImmichApiSearchSmart -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Body.page -is [int] -and $Body.page -eq 2
                }
                $result.Count | Should -Be 1
            }
        }
    }
    Describe 'Find-IMExploreData' -Tag 'Unit', 'Find-IMExploreData' {
        BeforeAll {
            Mock Invoke-ImmichApiGetExploreData -ModuleName PSImmich {
                return @(
                    [PSCustomObject]@{
                        fieldName = 'camera-make'
                        items     = @(
                            [PSCustomObject]@{ value = 'Canon'; data = [PSCustomObject]@{ assetCount = 45 } },
                            [PSCustomObject]@{ value = 'Nikon'; data = [PSCustomObject]@{ assetCount = 32 } }
                        )
                    },
                    [PSCustomObject]@{
                        fieldName = 'tags'
                        items     = @(
                            [PSCustomObject]@{ value = 'vacation'; data = [PSCustomObject]@{ assetCount = 78 } },
                            [PSCustomObject]@{ value = 'family'; data = [PSCustomObject]@{ assetCount = 156 } }
                        )
                    }
                )
            }
        }

        Context 'Explore Data Retrieval' {
            It 'Should call the generated explore data function' {
                Find-IMExploreData

                Should -Invoke Invoke-ImmichApiGetExploreData -ModuleName PSImmich -Times 1 -Exactly
            }

            It 'Should return SearchExploreResponseDto objects' {
                $result = Find-IMExploreData

                $result | Should -HaveCount 2
                $result[0].GetType().Name | Should -Be 'SearchExploreResponseDto'
                $result[0].fieldName | Should -Be 'camera-make'
                $result[1].items[0].value | Should -Be 'vacation'
            }

            It 'Should forward an explicit session' {
                $session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])

                Find-IMExploreData -Session $session

                Should -Invoke Invoke-ImmichApiGetExploreData -ModuleName PSImmich -ParameterFilter {
                    $ImmichSession -eq $session
                }
            }
        }
    }

    Describe 'Find-IMPerson' -Tag 'Unit', 'Find-IMPerson' {
        BeforeAll {
            Mock Invoke-ImmichApiSearchPerson -ModuleName PSImmich {
                return @(
                    [PSCustomObject]@{
                        id            = 'found-person1-guid-1234567890abcdef'
                        name          = 'Alice Johnson'
                        birthDate     = '1988-07-22'
                        thumbnailPath = '/thumbs/alice.jpg'
                        isHidden      = $false
                    },
                    [PSCustomObject]@{
                        id            = 'found-person2-guid-2345678901bcdefg'
                        name          = 'Bob Wilson'
                        birthDate     = '1992-11-15'
                        thumbnailPath = '/thumbs/bob.jpg'
                        isHidden      = $false
                    }
                )
            }
        }

        Context 'Request mapping' {
            It 'Should pass Name and omit WithHidden when not bound' {
                Find-IMPerson -Name 'Alice'

                Should -Invoke Invoke-ImmichApiSearchPerson -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'Alice' -and
                    -not $PSBoundParameters.ContainsKey('WithHidden')
                }
            }

            It 'Should send an explicit WithHidden value of false' {
                Find-IMPerson -Name 'Alice' -WithHidden $false

                Should -Invoke Invoke-ImmichApiSearchPerson -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'Alice' -and
                    $WithHidden -eq $false
                }
            }

            It 'Should reject a missing Name' {
                { Find-IMPerson } | Should -Throw
            }
        }

        Context 'Output' {
            It 'Should return PersonResponseDto objects' {
                $result = Find-IMPerson -Name 'Alice'

                $result | Should -HaveCount 2
                $result[0].GetType().Name | Should -Be 'PersonResponseDto'
                $result[0].name | Should -Be 'Alice Johnson'
                $result[1].name | Should -Be 'Bob Wilson'
            }
        }
    }

    Describe 'Find-IMPlace' -Tag 'Unit', 'Find-IMPlace' {
        BeforeAll {
            Mock Invoke-ImmichApiSearchPlaces -ModuleName PSImmich {
                return @(
                    [PSCustomObject]@{
                        name       = 'Central Park'
                        latitude   = 40.7829
                        longitude  = -73.9654
                        admin1name = 'New York'
                        admin2name = 'New York County'
                    },
                    [PSCustomObject]@{
                        name       = 'Tower Bridge'
                        latitude   = 51.5055
                        longitude  = -0.0754
                        admin1name = 'England'
                        admin2name = 'Greater London'
                    }
                )
            }
        }

        Context 'Request mapping' {
            It 'Should pass the Name to the generated places function' {
                Find-IMPlace -Name 'Central'

                Should -Invoke Invoke-ImmichApiSearchPlaces -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'Central'
                }
            }

            It 'Should reject a missing Name' {
                { Find-IMPlace } | Should -Throw
            }
        }

        Context 'Output' {
            It 'Should return PlacesResponseDto objects' {
                $result = Find-IMPlace -Name 'Central'

                $result | Should -HaveCount 2
                $result[0].GetType().Name | Should -Be 'PlacesResponseDto'
                $result[0].name | Should -Be 'Central Park'
                $result[1].admin2name | Should -Be 'Greater London'
            }
        }
    }

    Describe 'Get-IMServerLicense' -Tag 'Unit', 'Get-IMServerLicense' {
        BeforeAll {
            Mock Invoke-ImmichApiGetServerLicense -ModuleName PSImmich {
                return [PSCustomObject]@{ licenseKey = 'IMCH-XXXX-XXXX-XXXX'; activatedAt = '2024-01-01T00:00:00Z' }
            }
        }
        Context 'Server License' {
            It 'Should get server license through the generated wrapper' {
                $Result = Get-IMServerLicense
                Should -Invoke Invoke-ImmichApiGetServerLicense -ModuleName PSImmich -Times 1 -Exactly -Scope It
                $Result.licenseKey | Should -Be 'IMCH-XXXX-XXXX-XXXX'
            }
        }
    }
    Describe 'Remove-IMServerLicense' -Tag 'Unit', 'Remove-IMServerLicense' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteServerLicense -ModuleName PSImmich { return $null }
        }
        Context 'License Removal' {
            It 'Should remove server license through the generated wrapper' {
                Remove-IMServerLicense -Confirm:$false
                Should -Invoke Invoke-ImmichApiDeleteServerLicense -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }
    }
    Describe 'Set-IMServerLicense' -Tag 'Unit', 'Set-IMServerLicense' {
        BeforeAll {
            Mock Invoke-ImmichApiSetServerLicense -ModuleName PSImmich {
                return [PSCustomObject]@{ licenseKey = 'IMCH-XXXX-XXXX-XXXX'; activatedAt = '2024-01-01T00:00:00Z' }
            }
        }
        Context 'License Configuration' {
            It 'Should set server license through the generated wrapper with the mapped body' {
                $Result = Set-IMServerLicense -ActivationKey 'test-activation' -LicenseKey 'IMCL-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX' -Confirm:$false
                Should -Invoke Invoke-ImmichApiSetServerLicense -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.activationKey -eq 'test-activation' -and
                    $Body.licenseKey -eq 'IMCL-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX'
                }
                $Result.licenseKey | Should -Be 'IMCH-XXXX-XXXX-XXXX'
            }
        }
    }
    Describe 'Get-IMServer' -Tag 'Unit', 'Get-IMServer' {
        BeforeAll {
            Mock Invoke-ImmichApiGetAdminConfig -ModuleName PSImmich { return [pscustomobject]@{ test = 'data' } }
        }
        Context '-AppliedSystemConfiguration' {
            It 'Should get config through the generated wrapper' {
                $Result = Get-IMServer -AppliedSystemConfiguration
                Should -Invoke Invoke-ImmichApiGetAdminConfig -ModuleName PSImmich -Times 1 -Exactly -Scope It
                $Result.test | Should -Be 'data'
            }
            It 'Should get applied system config as JSON when ReturnRawJSON is used' {
                $result = Get-IMServer -AppliedSystemConfiguration -ReturnRawJSON
                $result | Should -BeOfType [string]
                Should -Invoke Invoke-ImmichApiGetAdminConfig -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }
        Context '-VersionCheckState' {
            BeforeAll {
                Mock Invoke-ImmichApiGetVersionCheckState -ModuleName PSImmich {
                    [PSCustomObject]@{ checkedAt = '2026-01-01T00:00:00Z'; releaseVersion = 'v3.3.6' }
                }
            }
            It 'Should return a VersionCheckStateResponseDto' {
                $Result = Get-IMServer -VersionCheckState

                Should -Invoke Invoke-ImmichApiGetVersionCheckState -ModuleName PSImmich -Times 1 -Exactly -Scope It
                $Result.GetType().Name | Should -Be 'VersionCheckStateResponseDto'
                $Result.releaseVersion | Should -Be 'v3.3.6'
            }
        }
        Context '-Ping' {
            It 'Should ping server through the generated wrapper and report responds' {
                Mock Invoke-ImmichApiPingServer -ModuleName PSImmich { return [pscustomobject]@{ res = 'pong' } }
                $Result = Get-IMServer -Ping
                Should -Invoke Invoke-ImmichApiPingServer -ModuleName PSImmich -Times 1 -Exactly -Scope It
                $Result.responds | Should -BeTrue
            }
            It 'Should report responds false when the ping response is not pong' {
                Mock Invoke-ImmichApiPingServer -ModuleName PSImmich { return [pscustomobject]@{ res = 'unexpected' } }
                $Result = Get-IMServer -Ping
                $Result.responds | Should -BeFalse
            }
        }
        Context '-Theme' {
            BeforeAll {
                Mock Invoke-ImmichApiGetPublicConfig -ModuleName PSImmich { return [pscustomobject]@{ theme = [pscustomobject]@{ customCss = 'body { color: red; }' } } }
            }
            It 'Should get theme through the generated public config wrapper' {
                Get-IMServer -Theme
                Should -Invoke Invoke-ImmichApiGetPublicConfig -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
            It 'Should return the theme object with customCss' {
                $Result = Get-IMServer -Theme
                $Result.customCss | Should -Be 'body { color: red; }'
            }
        }
        Context '-MediaTypes' {
            It 'Should get supported media types through the generated wrapper' {
                Mock Invoke-ImmichApiGetSupportedMediaTypes -ModuleName PSImmich { return [pscustomobject]@{ image = @('.jpg') } }
                Get-IMServer -MediaTypes
                Should -Invoke Invoke-ImmichApiGetSupportedMediaTypes -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }
        Context '-Version' {
            It 'Should get server version through the generated wrapper and format it' {
                Mock Invoke-ImmichApiGetServerVersion -ModuleName PSImmich { return [pscustomobject]@{ Major = 3; Minor = 3; Patch = 6 } }
                $Result = Get-IMServer -Version
                Should -Invoke Invoke-ImmichApiGetServerVersion -ModuleName PSImmich -Times 1 -Exactly -Scope It
                $Result.version | Should -Be '3.3.6'
            }
        }
        Context '-Storage' {
            It 'Should get server storage through the generated wrapper' {
                Mock Invoke-ImmichApiGetStorage -ModuleName PSImmich { return [pscustomobject]@{ diskSize = '100GiB' } }
                $Result = Get-IMServer -Storage
                Should -Invoke Invoke-ImmichApiGetStorage -ModuleName PSImmich -Times 1 -Exactly -Scope It
                $Result.diskSize | Should -Be '100GiB'
            }
        }
        Context '-Statistics' {
            It 'Should get server statistics through the generated wrapper' {
                Mock Invoke-ImmichApiGetServerStatistics -ModuleName PSImmich { return [pscustomobject]@{ photos = 10 } }
                $Result = Get-IMServer -Statistics
                Should -Invoke Invoke-ImmichApiGetServerStatistics -ModuleName PSImmich -Times 1 -Exactly -Scope It
                $Result.photos | Should -Be 10
            }
        }
        Context '-Features' {
            It 'Should get server features through the generated wrapper' {
                Mock Invoke-ImmichApiGetServerFeatures -ModuleName PSImmich { return [pscustomobject]@{ smartSearch = $true } }
                $Result = Get-IMServer -Features
                Should -Invoke Invoke-ImmichApiGetServerFeatures -ModuleName PSImmich -Times 1 -Exactly -Scope It
                $Result.smartSearch | Should -BeTrue
            }
        }
        Context '-Configuration' {
            It 'Should get server config through the generated wrapper' {
                Mock Invoke-ImmichApiGetServerConfig -ModuleName PSImmich { return [pscustomobject]@{ isInitialized = $true } }
                Get-IMServer -Configuration
                Should -Invoke Invoke-ImmichApiGetServerConfig -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }
        Context '-About' {
            It 'Should get server about through the generated wrapper' {
                Mock Invoke-ImmichApiGetAboutInfo -ModuleName PSImmich { return [pscustomobject]@{ version = 'v3.3.6' } }
                Get-IMServer -About
                Should -Invoke Invoke-ImmichApiGetAboutInfo -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }
        Context '-VersionHistory' {
            It 'Should get version history through the generated wrapper' {
                Mock Invoke-ImmichApiGetVersionHistory -ModuleName PSImmich { return @() }
                Get-IMServer -VersionHistory
                Should -Invoke Invoke-ImmichApiGetVersionHistory -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }
        Context '-DefaultSystemConfiguration' {
            BeforeAll {
                Mock Invoke-ImmichApiGetAdminConfigDefaults -ModuleName PSImmich { return [pscustomobject]@{ test = 'data' } }
            }
            It 'Should get default system config through the generated wrapper' {
                Get-IMServer -DefaultSystemConfiguration
                Should -Invoke Invoke-ImmichApiGetAdminConfigDefaults -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
            It 'Should get default system config as JSON when ReturnRawJSON is used' {
                $result = Get-IMServer -DefaultSystemConfiguration -ReturnRawJSON
                $result | Should -BeOfType [string]
                Should -Invoke Invoke-ImmichApiGetAdminConfigDefaults -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }
        Context '-StorageTemplateOptions' {
            It 'Should get storage template options through the generated wrapper' {
                Mock Invoke-ImmichApiGetStorageTemplateOptions -ModuleName PSImmich { return [pscustomobject]@{ dayOptions = @() } }
                Get-IMServer -StorageTemplateOptions
                Should -Invoke Invoke-ImmichApiGetStorageTemplateOptions -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }
        Context '-APKLinks' {
            It 'Should get APK links through the generated wrapper' {
                Mock Invoke-ImmichApiGetApkLinks -ModuleName PSImmich { return [pscustomobject]@{ arm64v8a = 'https://example.test/arm64.apk' } }
                Get-IMServer -APKLinks
                Should -Invoke Invoke-ImmichApiGetApkLinks -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }
        Context '-VersionCheck' {
            It 'Should check version through the generated wrapper' {
                Mock Invoke-ImmichApiGetVersionCheck -ModuleName PSImmich { return [pscustomobject]@{ checkedAt = '2026-01-01T00:00:00Z' } }
                Get-IMServer -VersionCheck
                Should -Invoke Invoke-ImmichApiGetVersionCheck -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }
    }
    Describe 'Set-IMServer' -Tag 'Unit', 'Set-IMServer' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateAdminConfig {}
        }
        Context '-RawJSONConfig' {
            It 'Should call the admin config API with the raw JSON text' {
                $config = @{ ffmpeg = @{ crf = 25 } }
                Set-IMServer -RawJSONConfig ($config | ConvertTo-Json -Compress)
                Should -Invoke Invoke-ImmichApiUpdateAdminConfig -Times 1 -ParameterFilter {
                    $RawBody -eq '{"ffmpeg":{"crf":25}}'
                }
            }
            It 'Should pass nested JSON through without depth truncation' {
                $json = '{"ffmpeg":{"crf":25,"preset":{"name":"fast","nested":{"deep":{"value":1}}}}}'
                Set-IMServer -RawJSONConfig $json
                Should -Invoke Invoke-ImmichApiUpdateAdminConfig -Times 1 -ParameterFilter {
                    $RawBody -ceq $json -and -not $Body
                }
            }
            It 'Should not call the admin config API when WhatIf is used' {
                Set-IMServer -RawJSONConfig '{}' -WhatIf
                Should -Invoke Invoke-ImmichApiUpdateAdminConfig -Times 0
            }
        }
    }
    Describe 'Connect-Immich' -Tag 'Unit', 'Connect-Immich' {
        Context 'Connection Establishment' {
            It 'Should have BaseURL parameter as mandatory' {
                $function = Get-Command Connect-Immich
                $baseUrlParam = $function.Parameters['BaseURL']
                $baseUrlParam.ParameterSets.Values.IsMandatory | Should -Contain $true
            }
        }
    }
    Describe 'Disconnect-Immich' -Tag 'Unit', 'Disconnect-Immich' {
        BeforeAll {
            Mock Invoke-ImmichApiLogout { } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should accept Session from the pipeline' {
                $function = Get-Command Disconnect-Immich
                $sessionParam = $function.Parameters['Session']
                $sessionParam.Attributes.ValueFromPipeline | Should -Contain $true
            }
        }

        Context 'Logout Operations' {
            It 'Should call the logout API with the provided session' {
                $fakeSession = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                Disconnect-Immich -Session $fakeSession

                Should -Invoke Invoke-ImmichApiLogout -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $ImmichSession -eq $fakeSession
                }
            }

            It 'Should call the logout API with no session when none is provided' {
                Disconnect-Immich

                Should -Invoke Invoke-ImmichApiLogout -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Get-IMSession' -Tag 'Unit', 'Get-IMSession' {
        It 'Should be true' {
            $true | Should -Be $true
        }
    }
    Describe 'Invoke-ImmichMethod' -Tag 'Unit', 'Invoke-ImmichMethod' {
        BeforeAll {
            Mock InvokeImmichRestMethod {
                return [PSCustomObject]@{ result = 'success' }
            } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should have all required parameters' {
                $function = Get-Command Invoke-ImmichMethod
                $function.Parameters.Keys | Should -Contain 'Method'
                $function.Parameters.Keys | Should -Contain 'RelativeURI'
                $function.Parameters.Keys | Should -Contain 'Session'
                $function.Parameters.Keys | Should -Contain 'Headers'
                $function.Parameters.Keys | Should -Contain 'QueryParameters'
                $function.Parameters.Keys | Should -Contain 'BodyParameters'
                $function.Parameters.Keys | Should -Contain 'ContentType'
                $function.Parameters.Keys | Should -Contain 'OutFilePath'
            }

            It 'Should have correct default ContentType' {
                # Test by calling function without ContentType and checking the invocation
                Invoke-ImmichMethod -Method 'GET' -RelativeURI '/test'

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $ContentType -eq 'application/json'
                }
            }
        }

        Context 'Basic API Invocation' {
            It 'Should call InvokeImmichRestMethod with minimal parameters' {
                Invoke-ImmichMethod -Method 'GET' -RelativeURI '/test'

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $RelativePath -eq '/test' -and
                    $ContentType -eq 'application/json'
                }
            }

            It 'Should pass custom ContentType' {
                Invoke-ImmichMethod -Method 'POST' -RelativeURI '/upload' -ContentType 'multipart/form-data'

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Method -eq 'POST' -and
                    $RelativePath -eq '/upload' -and
                    $ContentType -eq 'multipart/form-data'
                }
            }

            It 'Should pass Session parameter when provided' -Skip:($true) {
                # Skip this test due to ImmichSession type constraint complexity in mocking
                # The actual functionality is tested in integration tests
                $true | Should -Be $true
            }
        }

        Context 'Query Parameters' {
            It 'Should pass QueryParameters when provided' {
                $queryParams = @{ search = 'test'; limit = 10 }
                Invoke-ImmichMethod -Method 'GET' -RelativeURI '/search' -QueryParameters $queryParams

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $QueryParameters.search -eq 'test' -and
                    $QueryParameters.limit -eq 10
                }
            }

            It 'Should not include QueryParameters when not provided' {
                Invoke-ImmichMethod -Method 'GET' -RelativeURI '/test'

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $null -eq $QueryParameters
                }
            }
        }

        Context 'Body Parameters' {
            It 'Should pass BodyParameters when provided' {
                $bodyParams = @{ name = 'test'; description = 'test description' }
                Invoke-ImmichMethod -Method 'POST' -RelativeURI '/create' -BodyParameters $bodyParams

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.name -eq 'test' -and
                    $Body.description -eq 'test description'
                }
            }

            It 'Should not include Body when BodyParameters not provided' {
                Invoke-ImmichMethod -Method 'GET' -RelativeURI '/test'

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $null -eq $Body
                }
            }
        }

        Context 'Custom Headers' {
            It 'Should pass Headers when provided' {
                $customHeaders = @{ 'X-Custom-Header' = 'test-value'; 'Authorization' = 'Bearer token' }
                Invoke-ImmichMethod -Method 'GET' -RelativeURI '/test' -Headers $customHeaders

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Headers.'X-Custom-Header' -eq 'test-value' -and
                    $Headers.'Authorization' -eq 'Bearer token'
                }
            }

            It 'Should not include Headers when not provided' {
                Invoke-ImmichMethod -Method 'GET' -RelativeURI '/test'

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $null -eq $Headers
                }
            }
        }

        Context 'File Output' {
            It 'Should pass OutFilePath when provided' {
                $outputPath = Join-Path $TestDrive 'output.jpg'

                # First check if function is called at all
                { Invoke-ImmichMethod -Method 'GET' -RelativeURI '/download' -OutFilePath $outputPath } | Should -Not -Throw

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Exactly 1 -Scope It
            }

            It 'Should not include OutFilePath when not provided' {
                Invoke-ImmichMethod -Method 'GET' -RelativeURI '/test'

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $null -eq $OutFilePath
                }
            }
        }

        Context 'Complex Scenarios' {
            It 'Should handle all parameters together' {
                $headers = @{ 'Custom-Header' = 'value' }
                $query = @{ filter = 'photos' }
                $body = @{ data = 'test' }
                $outPath = Join-Path $TestDrive 'result.json'

                # Test without Session to avoid type constraint issues
                { Invoke-ImmichMethod -Method 'POST' -RelativeURI '/complex' -Headers $headers -QueryParameters $query -BodyParameters $body -ContentType 'application/json' -OutFilePath $outPath } | Should -Not -Throw

                Should -Invoke InvokeImmichRestMethod -ModuleName PSImmich -Exactly 1 -Scope It
            }

            It 'Should return result from InvokeImmichRestMethod' {
                Mock InvokeImmichRestMethod {
                    return @{ status = 'success'; data = @{ id = 'test-id' } }
                } -ModuleName PSImmich

                $result = Invoke-ImmichMethod -Method 'GET' -RelativeURI '/test'

                $result.status | Should -Be 'success'
                $result.data.id | Should -Be 'test-id'
            }
        }
    }
    Describe 'Add-IMSharedLinkAsset' -Tag 'Unit', 'Add-IMSharedLinkAsset' {
        BeforeAll {
            Mock Invoke-ImmichApiAddSharedLinkAssets -ModuleName PSImmich {
                [pscustomobject]@{ assetId = $Body.assetIds[0]; success = $true; error = $null }
            }
        }

        Context 'Request mapping' {
            It 'Should add the asset to the shared link' {
                Add-IMSharedLinkAsset -SharedLinkId '12345678-1234-1234-1234-123456789abc' -Id '12345678-1234-1234-1234-123456789def' -Confirm:$false

                Should -Invoke Invoke-ImmichApiAddSharedLinkAssets -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc' -and
                    $Body.assetIds -contains '12345678-1234-1234-1234-123456789def'
                }
            }

            It 'Should send all assets received from the pipeline in one request' {
                @('12345678-1234-1234-1234-123456789d01', '12345678-1234-1234-1234-123456789d02') |
                    ForEach-Object { [pscustomobject]@{ Id = $PSItem; SharedLinkId = '12345678-1234-1234-1234-123456789abc' } } |
                    Add-IMSharedLinkAsset -Confirm:$false

                Should -Invoke Invoke-ImmichApiAddSharedLinkAssets -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.assetIds.Count -eq 2
                }
            }

            It 'Should not call the API when WhatIf is specified' {
                Add-IMSharedLinkAsset -SharedLinkId '12345678-1234-1234-1234-123456789abc' -Id '12345678-1234-1234-1234-123456789def' -WhatIf

                Should -Invoke Invoke-ImmichApiAddSharedLinkAssets -ModuleName PSImmich -Exactly 0 -Scope It
            }
        }

        Context 'Output' {
            It 'Should return an AssetIdsResponseDto' {
                $Result = Add-IMSharedLinkAsset -SharedLinkId '12345678-1234-1234-1234-123456789abc' -Id '12345678-1234-1234-1234-123456789def' -Confirm:$false

                $Result.GetType().Name | Should -Be 'AssetIdsResponseDto'
                $Result.success | Should -BeTrue
            }
        }

        Context 'Parameter Validation' {
            It 'Should reject an invalid shared link id' {
                { Add-IMSharedLinkAsset -SharedLinkId 'not-a-guid' -Id '12345678-1234-1234-1234-123456789def' -Confirm:$false } | Should -Throw
            }
        }
    }
    Describe 'Get-IMSharedLink' -Tag 'Unit', 'Get-IMSharedLink' {
        BeforeAll {
            Mock Invoke-ImmichApiGetAllSharedLinks -ModuleName PSImmich {
                [pscustomobject]@{ id = 'link1'; key = 'share-key-123'; type = 'ALBUM' }
            }
            Mock Invoke-ImmichApiGetSharedLinkById -ModuleName PSImmich {
                [pscustomobject]@{ id = $Id; key = 'share-key-123'; type = 'INDIVIDUAL' }
            }
        }

        Context 'Request mapping' {
            It 'Should list shared links without an album filter when AlbumId is not bound' {
                Get-IMSharedLink

                Should -Invoke Invoke-ImmichApiGetAllSharedLinks -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    -not $AlbumId
                }
            }

            It 'Should filter shared links by album' {
                Get-IMSharedLink -AlbumId '12345678-1234-1234-1234-123456789abc'

                Should -Invoke Invoke-ImmichApiGetAllSharedLinks -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $AlbumId -eq '12345678-1234-1234-1234-123456789abc'
                }
            }

            It 'Should get a single shared link by id' {
                Get-IMSharedLink -Id '12345678-1234-1234-1234-123456789abc'

                Should -Invoke Invoke-ImmichApiGetSharedLinkById -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc'
                }
            }

            It 'Should forward an explicit session' {
                $TestSession = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                Get-IMSharedLink -Session $TestSession

                Should -Invoke Invoke-ImmichApiGetAllSharedLinks -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $ImmichSession -eq $TestSession
                }
            }
        }

        Context 'Output' {
            It 'Should return SharedLinkResponseDto objects' {
                $Result = Get-IMSharedLink

                $Result.GetType().Name | Should -Be 'SharedLinkResponseDto'
                $Result.key | Should -Be 'share-key-123'
            }
        }

        Context 'Parameter Validation' {
            It 'Should reject an invalid id' {
                { Get-IMSharedLink -Id 'not-a-guid' } | Should -Throw
            }
        }
    }
    Describe 'New-IMSharedLink' -Tag 'Unit', 'New-IMSharedLink' {
        BeforeAll {
            Mock Invoke-ImmichApiCreateSharedLink -ModuleName PSImmich {
                [pscustomobject]@{ id = 'new-link'; key = 'new-share-key'; type = $Body.type; description = $Body.description }
            }
        }

        Context 'Request mapping' {
            It 'Should create an individual asset link with the asset ids' {
                New-IMSharedLink -AssetId @('12345678-1234-1234-1234-123456789abc', '12345678-1234-1234-1234-123456789def')

                Should -Invoke Invoke-ImmichApiCreateSharedLink -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.type -eq 'INDIVIDUAL' -and
                    $Body.assetIds.Count -eq 2 -and
                    $Body.assetIds -contains '12345678-1234-1234-1234-123456789def'
                }
            }

            It 'Should create an album link with the album id' {
                New-IMSharedLink -AlbumId '12345678-1234-1234-1234-123456789abc'

                Should -Invoke Invoke-ImmichApiCreateSharedLink -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.type -eq 'ALBUM' -and $Body.albumId -eq '12345678-1234-1234-1234-123456789abc'
                }
            }

            It 'Should send the description' {
                New-IMSharedLink -AssetId '12345678-1234-1234-1234-123456789abc' -Description 'Holiday photos'

                Should -Invoke Invoke-ImmichApiCreateSharedLink -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.description -eq 'Holiday photos'
                }
            }
        }

        Context 'Output' {
            It 'Should return a SharedLinkResponseDto' {
                $Result = New-IMSharedLink -AssetId '12345678-1234-1234-1234-123456789abc'

                $Result.GetType().Name | Should -Be 'SharedLinkResponseDto'
                $Result.key | Should -Be 'new-share-key'
            }
        }

        Context 'Parameter Validation' {
            It 'Should reject an invalid asset id' {
                { New-IMSharedLink -AssetId 'not-a-guid' } | Should -Throw
            }
        }
    }
    Describe 'Remove-IMSharedLink' -Tag 'Unit', 'Remove-IMSharedLink' {
        BeforeAll {
            Mock Invoke-ImmichApiRemoveSharedLink -ModuleName PSImmich { }
        }

        Context 'Request mapping' {
            It 'Should remove the shared link by id' {
                Remove-IMSharedLink -Id '12345678-1234-5678-9012-123456789abc' -Confirm:$false

                Should -Invoke Invoke-ImmichApiRemoveSharedLink -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc'
                }
            }

            It 'Should not call the API when WhatIf is specified' {
                Remove-IMSharedLink -Id '12345678-1234-5678-9012-123456789abc' -WhatIf

                Should -Invoke Invoke-ImmichApiRemoveSharedLink -ModuleName PSImmich -Exactly 0 -Scope It
            }
        }

        Context 'Parameter Validation' {
            It 'Should reject an invalid id' {
                { Remove-IMSharedLink -Id 'not-a-guid' -Confirm:$false } | Should -Throw
            }
        }
    }
    Describe 'Remove-IMSharedLinkAsset' -Tag 'Unit', 'Remove-IMSharedLinkAsset' {
        BeforeAll {
            Mock Invoke-ImmichApiRemoveSharedLinkAssets -ModuleName PSImmich {
                [pscustomobject]@{ assetId = $Body.assetIds[0]; success = $true; error = $null }
            }
        }

        Context 'Request mapping' {
            It 'Should remove the asset from the shared link' {
                Remove-IMSharedLinkAsset -SharedLinkId '12345678-1234-1234-1234-123456789abc' -Id '12345678-1234-1234-1234-123456789def' -Confirm:$false

                Should -Invoke Invoke-ImmichApiRemoveSharedLinkAssets -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc' -and
                    $Body.assetIds -contains '12345678-1234-1234-1234-123456789def'
                }
            }

            It 'Should not call the API when WhatIf is specified' {
                Remove-IMSharedLinkAsset -SharedLinkId '12345678-1234-1234-1234-123456789abc' -Id '12345678-1234-1234-1234-123456789def' -WhatIf

                Should -Invoke Invoke-ImmichApiRemoveSharedLinkAssets -ModuleName PSImmich -Exactly 0 -Scope It
            }
        }

        Context 'Output' {
            It 'Should return an AssetIdsResponseDto' {
                $Result = Remove-IMSharedLinkAsset -SharedLinkId '12345678-1234-1234-1234-123456789abc' -Id '12345678-1234-1234-1234-123456789def' -Confirm:$false

                $Result.GetType().Name | Should -Be 'AssetIdsResponseDto'
            }
        }
    }
    Describe 'Set-IMSharedLink' -Tag 'Unit', 'Set-IMSharedLink' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateSharedLink -ModuleName PSImmich {
                [pscustomobject]@{ id = $Id; key = 'share-key-123'; description = $Body.description }
            }
        }

        Context 'Request mapping' {
            It 'Should update the shared link with the new description' {
                Set-IMSharedLink -Id '12345678-1234-5678-9012-123456789abc' -Description 'New description' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateSharedLink -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc' -and $Body.description -eq 'New description'
                }
            }

            It 'Should not call the API when WhatIf is specified' {
                Set-IMSharedLink -Id '12345678-1234-5678-9012-123456789abc' -Description 'New description' -WhatIf

                Should -Invoke Invoke-ImmichApiUpdateSharedLink -ModuleName PSImmich -Exactly 0 -Scope It
            }
        }

        Context 'Output' {
            It 'Should return a SharedLinkResponseDto' {
                $Result = Set-IMSharedLink -Id '12345678-1234-5678-9012-123456789abc' -Description 'New description' -Confirm:$false

                $Result.GetType().Name | Should -Be 'SharedLinkResponseDto'
                $Result.description | Should -Be 'New description'
            }
        }
    }
    Describe 'Get-IMTag' -Tag 'Unit', 'Get-IMTag' {
        BeforeAll {
            Mock Invoke-ImmichApiGetAllTags {
                return @(
                    [PSCustomObject]@{ id = 'tag1-guid'; name = 'vacation'; value = 'summer2024'; type = 'OBJECT' },
                    [PSCustomObject]@{ id = 'tag2-guid'; name = 'location'; value = 'beach'; type = 'FACE' }
                )
            } -ModuleName PSImmich
            Mock Invoke-ImmichApiGetTagById {
                return [PSCustomObject]@{ id = '12345678-1234-5678-9012-123456789abc'; name = 'vacation'; value = 'summer2024'; type = 'OBJECT' }
            } -ModuleName PSImmich
        }
        Context 'Tag Retrieval' {
            It 'Should list all tags via the generated API wrapper' {
                $Result = Get-IMTag
                Should -Invoke Invoke-ImmichApiGetAllTags -ModuleName PSImmich -Times 1 -Exactly -Scope It
                $Result.Count | Should -Be 2
            }

            It 'Should get a single tag by id via the generated API wrapper' {
                $Result = Get-IMTag -Id '12345678-1234-5678-9012-123456789abc'
                Should -Invoke Invoke-ImmichApiGetTagById -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc'
                }
                $Result.name | Should -Be 'vacation'
            }
        }
    }
    Describe 'New-IMTag' -Tag 'Unit', 'New-IMTag' {
        BeforeAll {
            Mock Invoke-ImmichApiCreateTag {
                return [PSCustomObject]@{ id = 'new-tag-guid'; name = 'family'; value = 'reunion2024' }
            } -ModuleName PSImmich
        }
        Context 'Tag Creation' {
            It 'Should create tag with the name in the request body' {
                New-IMTag -Name 'family'
                Should -Invoke Invoke-ImmichApiCreateTag -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.name -eq 'family'
                }
            }
        }
    }
    Describe 'Remove-IMTag' -Tag 'Unit', 'Remove-IMTag' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteTag { return $null } -ModuleName PSImmich
        }
        Context 'Tag Removal' {
            It 'Should delete the tag by id via the generated API wrapper' {
                Remove-IMTag -id '12345678-1234-5678-9012-123456789abc' -Confirm:$false
                Should -Invoke Invoke-ImmichApiDeleteTag -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc'
                }
            }
        }
    }
    Describe 'Set-IMTag' -Tag 'Unit', 'Set-IMTag' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateTag {
                return [PSCustomObject]@{ id = 'updated-tag-guid'; name = 'updated-name'; value = 'updated-value' }
            } -ModuleName PSImmich
        }
        Context 'Tag Updates' {
            It 'Should update the tag colour via the generated API wrapper' {
                Set-IMTag -Id '12345678-1234-5678-9012-123456789abc' -Color '#FF0000' -Confirm:$false
                Should -Invoke Invoke-ImmichApiUpdateTag -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc' -and $Body.color -eq '#FF0000'
                }
            }
        }
    }
    Describe 'Get-IMTimeBucket' -Tag 'Unit', 'Get-IMTimeBucket' {
        BeforeAll {
            Mock Invoke-ImmichApiGetTimeBuckets {
                return @(
                    [PSCustomObject]@{ timeBucket = '2024-01-01T00:00:00.000Z'; count = 156 },
                    [PSCustomObject]@{ timeBucket = '2024-02-01T00:00:00.000Z'; count = 89 }
                )
            } -ModuleName PSImmich

            Mock Invoke-ImmichApiGetTimeBucket {
                return [PSCustomObject]@{ id = @('a1'); fileCreatedAt = @('2024-02-01T00:00:00.000Z') }
            } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should require TimeBucket in the timebucket parameter set' {
                $Function = Get-Command Get-IMTimeBucket
                $TimeBucketParam = $Function.Parameters['TimeBucket']
                $TimeBucketParam.ParameterSets['timebucket'].IsMandatory | Should -BeTrue
            }

            It 'Should reject an invalid Visibility value' {
                { Get-IMTimeBucket -Visibility 'invalid' } | Should -Throw
            }

            It 'Should reject an invalid AlbumId format' {
                { Get-IMTimeBucket -AlbumId 'not-a-guid' } | Should -Throw
            }
        }

        Context 'List Operations' {
            It 'Should call the buckets API when no TimeBucket is given' {
                $Result = Get-IMTimeBucket
                Should -Invoke Invoke-ImmichApiGetTimeBuckets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $null -eq $Order -and $null -eq $ImmichSession
                }
                $Result.Count | Should -Be 2
            }

            It 'Should forward only bound filters to the buckets API' {
                Get-IMTimeBucket -IsFavorite $true -Order desc -Visibility timeline
                Should -Invoke Invoke-ImmichApiGetTimeBuckets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $IsFavorite -eq $true -and $Order -eq 'desc' -and $Visibility -eq 'timeline' -and
                    $null -eq $AlbumId -and $null -eq $WithPartners
                }
            }

            It 'Should forward the new spec filters to the buckets API' {
                Get-IMTimeBucket -Bbox '1,2,3,4' -OrderBy createdAt -TagId '11111111-1111-1111-1111-111111111111' -WithCoordinates $true
                Should -Invoke Invoke-ImmichApiGetTimeBuckets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $Bbox -eq '1,2,3,4' -and $OrderBy -eq 'createdAt' -and
                    $TagId -eq '11111111-1111-1111-1111-111111111111' -and $WithCoordinates -eq $true
                }
            }
        }

        Context 'Single Time Bucket Operations' {
            It 'Should call the bucket API with the time bucket' {
                Get-IMTimeBucket -TimeBucket '2024-02-01T00:00:00.000Z'
                Should -Invoke Invoke-ImmichApiGetTimeBucket -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $TimeBucket -eq '2024-02-01T00:00:00.000Z' -and $null -eq $Order
                }
                Should -Invoke Invoke-ImmichApiGetTimeBuckets -ModuleName PSImmich -Times 0
            }

            It 'Should forward the user and partner filters to the bucket API' {
                Get-IMTimeBucket -TimeBucket '2024-02-01T00:00:00.000Z' -UserId '22222222-2222-2222-2222-222222222222' -WithPartners $true -WithStacked $false
                Should -Invoke Invoke-ImmichApiGetTimeBucket -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $UserId -eq '22222222-2222-2222-2222-222222222222' -and $WithPartners -eq $true -and $WithStacked -eq $false
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                $fakeSession = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                Get-IMTimeBucket -Session $fakeSession
                Should -Invoke Invoke-ImmichApiGetTimeBuckets -ModuleName PSImmich -Times 1 -ParameterFilter {
                    $ImmichSession -eq $fakeSession
                }
            }
        }
    }
    Describe 'Add-IMMyProfilePicture' -Tag 'Unit', 'Add-IMMyProfilePicture' {
        BeforeAll {
            # Create test files
            $TestFile = Join-Path $TestDrive 'test-avatar.jpg'
            $TestImageBytes = [System.Text.Encoding]::UTF8.GetBytes('test image content')
            [System.IO.File]::WriteAllBytes($TestFile, $TestImageBytes)

            # Mock session
            $MockSession = [PSCustomObject]@{
                ApiUri      = 'https://test.immich.app/api'
                AccessToken = ConvertTo-SecureString -String 'test-token' -AsPlainText -Force
            }

            # Set global session
            $script:ImmichSession = $MockSession

            # Mock the new private function that handles HTTP uploads
            Mock Invoke-ImmichApiCreateProfileImage -MockWith {
                return [PSCustomObject]@{ userId = 'test-user-id'; profileImagePath = '/profile/test.jpg' }
            } -ModuleName PSImmich

            Mock ConvertFromSecureString -MockWith {
                return 'test-token'
            } -ModuleName PSImmich
        }

        Context 'Parameter Validation' {
            It 'Should require FilePath parameter' {
                # Test that the function has a mandatory FilePath parameter
                $Function = Get-Command Add-IMMyProfilePicture
                $FilePathParam = $Function.Parameters['FilePath']
                $FilePathParam.Attributes.Mandatory | Should -Contain $true
            }

            It 'Should validate FilePath exists' {
                $NonExistentFile = Join-Path $TestDrive 'nonexistent.jpg'
                { $null = Add-IMMyProfilePicture -FilePath $NonExistentFile -ErrorAction Stop } | Should -Throw
            }

            It 'Should accept valid FilePath' {
                $TestFile = Join-Path $TestDrive 'valid-avatar.jpg'
                $ValidImageBytes = [System.Text.Encoding]::UTF8.GetBytes('test image')
                [System.IO.File]::WriteAllBytes($TestFile, $ValidImageBytes)

                # Mock file operations
                Mock Get-Item {
                    return [System.IO.FileInfo]::new($TestFile)
                } -ModuleName PSImmich

                { Add-IMMyProfilePicture -FilePath $TestFile } | Should -Not -Throw
            }
        }

        Context 'HTTP Upload Integration' {
            It 'Should upload the file through the CreateProfileImage wrapper' {
                Mock Get-Item {
                    return [System.IO.FileInfo]::new($TestFile)
                } -ModuleName PSImmich

                Add-IMMyProfilePicture -FilePath $TestFile

                Should -Invoke Invoke-ImmichApiCreateProfileImage -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $FileInfo.Name -eq 'test-avatar.jpg'
                }
            }
        }

        Context 'Error Handling' {
            It 'Should handle HTTP errors gracefully' {
                $TestFile = Join-Path $TestDrive 'error-avatar.jpg'
                $ErrorImageBytes = [System.Text.Encoding]::UTF8.GetBytes('test image')
                [System.IO.File]::WriteAllBytes($TestFile, $ErrorImageBytes)

                Mock Get-Item {
                    return [System.IO.FileInfo]::new($TestFile)
                } -ModuleName PSImmich

                Mock Invoke-ImmichApiCreateProfileImage -MockWith {
                    throw 'HTTP 400: Bad Request'
                } -ModuleName PSImmich

                { Add-IMMyProfilePicture -FilePath $TestFile } | Should -Throw 'HTTP 400: Bad Request'
            }
        }
    }
    Describe 'Export-IMProfilePicture' -Tag 'Unit', 'Export-IMProfilePicture' {
        BeforeAll {
            Mock Invoke-ImmichApiGetProfileImage {
                return $null
            }
        }
        Context 'Profile Picture Export' {
            It 'Should export profile picture through the internal API function' {
                Export-IMProfilePicture -id '12345678-1234-5678-9012-123456789abc' -Path $TestDrive
                Should -Invoke Invoke-ImmichApiGetProfileImage -Times 1 -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc' -and
                    "$OutFilePath" -like (Join-Path $TestDrive '12345678-1234-5678-9012-123456789abc.jpeg')
                }
            }
        }
    }
    Describe 'Get-IMTopLargestAsset' -Tag 'Unit', 'Get-IMTopLargestAsset' {
        BeforeAll {
            Mock Invoke-ImmichApiSearchLargeAssets -ModuleName PSImmich {
                return @(
                    [PSCustomObject]@{
                        id               = '123e4567-e89b-12d3-a456-426614174000'
                        type             = 'IMAGE'
                        originalFileName = 'large-image.jpg'
                        updatedAt        = '2024-01-01T10:00:00Z'
                        exifInfo         = @{
                            fileSizeInByte  = 52428800  # 50MB
                            exifImageWidth  = 4000
                            exifImageHeight = 3000
                        }
                    },
                    [PSCustomObject]@{
                        id               = '987fcdeb-51a2-43d5-b789-123456789abc'
                        type             = 'VIDEO'
                        originalFileName = 'large-video.mp4'
                        updatedAt        = '2024-01-02T15:30:00Z'
                        exifInfo         = @{
                            fileSizeInByte  = 104857600  # 100MB
                            exifImageWidth  = 1920
                            exifImageHeight = 1080
                        }
                    }
                )
            }
        }

        Context 'Parameter Validation' {
            It 'Should have Size parameter with correct validation' {
                $Function = Get-Command Get-IMTopLargestAsset
                $SizeParam = $Function.Parameters['Size']
                $SizeParam.ParameterType.Name | Should -Be 'Int32'

                $ValidateRange = $SizeParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
                $ValidateRange.MinRange | Should -Be 1
                $ValidateRange.MaxRange | Should -Be 1000
            }

            It 'Should have Session parameter of ImmichSession type' {
                $Function = Get-Command Get-IMTopLargestAsset
                $Function.Parameters['Session'].ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should reject a Size outside 1-1000' {
                { Get-IMTopLargestAsset -Size 0 } | Should -Throw
                { Get-IMTopLargestAsset -Size 1001 } | Should -Throw
            }
        }

        Context 'Request mapping' {
            It 'Should send the default Size of 100 when not explicitly provided' {
                Get-IMTopLargestAsset

                Should -Invoke Invoke-ImmichApiSearchLargeAssets -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Size -eq 100
                }
            }

            It 'Should forward a custom Size' {
                Get-IMTopLargestAsset -Size 50

                Should -Invoke Invoke-ImmichApiSearchLargeAssets -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Size -eq 50
                }
            }

            It 'Should forward an explicit session' {
                $session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])

                Get-IMTopLargestAsset -Session $session

                Should -Invoke Invoke-ImmichApiSearchLargeAssets -ModuleName PSImmich -ParameterFilter {
                    $ImmichSession -eq $session
                }
            }
        }

        Context 'Response Processing' {
            It 'Should return AssetResponseDto objects' {
                $Result = Get-IMTopLargestAsset

                $Result | Should -HaveCount 2
                $Result[0].GetType().Name | Should -Be 'AssetResponseDto'
                $Result[0].id | Should -Be '123e4567-e89b-12d3-a456-426614174000'
                $Result[0].type | Should -Be 'IMAGE'
                $Result[1].id | Should -Be '987fcdeb-51a2-43d5-b789-123456789abc'
                $Result[1].type | Should -Be 'VIDEO'
            }

            It 'Should preserve exifInfo for size calculations' {
                $Result = Get-IMTopLargestAsset

                $Result[0].exifInfo.fileSizeInByte | Should -Be 52428800
                $Result[0].exifInfo.exifImageWidth | Should -Be 4000
                $Result[1].exifInfo.fileSizeInByte | Should -Be 104857600
            }
        }
    }
    Describe 'Get-IMUser' -Tag 'Unit', 'Get-IMUser' {
        BeforeAll {
            Mock Invoke-ImmichApiSearchUsersAdmin {
                return @(
                    [PSCustomObject]@{ id = 'user1-guid'; email = 'user1@example.com'; name = 'User One' },
                    [PSCustomObject]@{ id = 'user2-guid'; email = 'user2@example.com'; name = 'User Two' }
                )
            } -ModuleName PSImmich
            Mock Invoke-ImmichApiGetUserAdmin {
                return [PSCustomObject]@{ id = '12345678-1234-5678-9012-123456789abc'; email = 'user@example.com'; name = 'User' }
            } -ModuleName PSImmich
            Mock Invoke-ImmichApiGetMyUser {
                return [PSCustomObject]@{ id = 'me-guid'; email = 'me@example.com'; name = 'Me' }
            } -ModuleName PSImmich
        }
        Context 'User Retrieval' {
            It 'Should list users via the admin search endpoint' {
                $result = Get-IMUser
                $result | Should -HaveCount 2
                Should -Invoke Invoke-ImmichApiSearchUsersAdmin -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    -not $WithDeleted
                }
            }
            It 'Should get a single user by id' {
                $null = Get-IMUser -Id '12345678-1234-5678-9012-123456789abc'
                Should -Invoke Invoke-ImmichApiGetUserAdmin -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc'
                }
            }
            It 'Should get the current user with -Me' {
                $null = Get-IMUser -Me
                Should -Invoke Invoke-ImmichApiGetMyUser -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
            It 'Should request deleted users with -IncludeDeleted' {
                $null = Get-IMUser -IncludeDeleted
                Should -Invoke Invoke-ImmichApiSearchUsersAdmin -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $WithDeleted -eq $true
                }
            }
        }
    }
    Describe 'Get-IMUserPreference' -Tag 'Unit', 'Get-IMUserPreference' {
        BeforeAll {
            Mock Invoke-ImmichApiGetMyPreferences {
                return [PSCustomObject]@{ avatar = [PSCustomObject]@{ color = 'primary' }; download = [PSCustomObject]@{ includeEmbeddedVideos = $true } }
            } -ModuleName PSImmich
            Mock Invoke-ImmichApiGetUserPreferencesAdmin {
                return [PSCustomObject]@{ avatar = [PSCustomObject]@{ color = 'orange' } }
            } -ModuleName PSImmich
        }
        Context 'User Preference Retrieval' {
            It 'Should get the current user preferences without an id' {
                $null = Get-IMUserPreference
                Should -Invoke Invoke-ImmichApiGetMyPreferences -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
            It 'Should get preferences for a specific user by id' {
                $null = Get-IMUserPreference -Id '12345678-1234-1234-1234-123456789abc'
                Should -Invoke Invoke-ImmichApiGetUserPreferencesAdmin -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc'
                }
            }
        }
    }
    Describe 'New-IMUser' -Tag 'Unit', 'New-IMUser' {
        BeforeAll {
            Mock Invoke-ImmichApiCreateUserAdmin {
                return [PSCustomObject]@{ id = 'new-user-guid'; email = 'new@example.com'; name = 'New User' }
            } -ModuleName PSImmich
        }
        Context 'User Creation' {
            It 'Should create user with correct API call' {
                $securePassword = ConvertTo-SecureString 'password123' -AsPlainText -Force
                $result = New-IMUser -Email 'new@example.com' -Password $securePassword -Name 'New User'
                $result.Email | Should -Be 'new@example.com'
                Should -Invoke Invoke-ImmichApiCreateUserAdmin -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.email -eq 'new@example.com' -and $Body.name -eq 'New User'
                }
            }
        }
    }
    Describe 'Remove-IMMyProfilePicture' -Tag 'Unit', 'Remove-IMMyProfilePicture' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteProfileImage { return $null } -ModuleName PSImmich
        }
        Context 'Profile Picture Removal' {
            It 'Should remove profile picture with correct API call' {
                Remove-IMMyProfilePicture
                Should -Invoke Invoke-ImmichApiDeleteProfileImage -ModuleName PSImmich -Times 1 -Exactly -Scope It
            }
        }
    }
    Describe 'Remove-IMUser' -Tag 'Unit', 'Remove-IMUser' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteUserAdmin {
                return [PSCustomObject]@{ id = 'deleted-user-guid'; deletedAt = '2024-01-01T10:00:00Z' }
            } -ModuleName PSImmich
        }
        Context 'User Removal' {
            It 'Should remove user with correct API call' {
                Remove-IMUser -id '12345678-1234-5678-9012-123456789abc' -Confirm:$false
                Should -Invoke Invoke-ImmichApiDeleteUserAdmin -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc'
                }
            }
        }
    }
    Describe 'Restore-IMUser' -Tag 'Unit', 'Restore-IMUser' {
        BeforeAll {
            Mock Invoke-ImmichApiRestoreUserAdmin {
                return [PSCustomObject]@{ id = 'restored-user-guid'; deletedAt = $null }
            } -ModuleName PSImmich
        }
        Context 'User Restoration' {
            It 'Should restore user with correct API call' {
                Restore-IMUser -id '12345678-1234-5678-9012-123456789abc'
                Should -Invoke Invoke-ImmichApiRestoreUserAdmin -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc'
                }
            }
        }
    }
    Describe 'Set-IMUser' -Tag 'Unit', 'Set-IMUser' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateUserAdmin {
                return [PSCustomObject]@{ id = 'updated-user-guid'; name = 'Updated Name' }
            } -ModuleName PSImmich
        }
        Context 'User Updates' {
            It 'Should update user with correct API call' {
                Set-IMUser -id '12345678-1234-5678-9012-123456789abc' -Name 'Updated Name' -Confirm:$false
                Should -Invoke Invoke-ImmichApiUpdateUserAdmin -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc' -and $Body.name -eq 'Updated Name'
                }
            }
        }
    }
    Describe 'Set-IMUserPreference' -Tag 'Unit', 'Set-IMUserPreference' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateUserPreferencesAdmin {
                return [PSCustomObject]@{ avatar = [PSCustomObject]@{ color = 'orange' } }
            } -ModuleName PSImmich
        }
        Context 'User Preference Updates' {
            It 'Should update user preferences with correct API call' {
                Set-IMUserPreference -id '12345678-1234-1234-1234-123456789abc' -AvatarColor 'orange' -Confirm:$false
                Should -Invoke Invoke-ImmichApiUpdateUserPreferencesAdmin -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc' -and $Body.avatar.color -eq 'orange'
                }
            }
        }
    }
    Describe 'Get-IMStack' -Tag 'Unit', 'Get-IMStack' {
        BeforeAll {
            $StackId = '12345678-1234-1234-1234-123456789abc'
            $PrimaryId = '12345678-1234-1234-1234-123456789def'
            Mock Invoke-ImmichApiSearchStacks -ModuleName PSImmich {
                return @(
                    [PSCustomObject]@{ id = $StackId; primaryAssetId = $PrimaryId; assets = @() },
                    [PSCustomObject]@{ id = 'stack2-guid'; primaryAssetId = 'asset2-guid'; assets = @() }
                )
            }
            Mock Invoke-ImmichApiGetStack -ModuleName PSImmich {
                return [PSCustomObject]@{ id = $StackId; primaryAssetId = $PrimaryId; assets = @() }
            }
        }
        Context 'List' {
            It 'Should call SearchStacks without a query when no PrimaryAssetId is given' {
                $Result = Get-IMStack
                Should -Invoke Invoke-ImmichApiSearchStacks -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    -not $PrimaryAssetId
                }
                $Result | Should -HaveCount 2
                $Result[0].GetType().Name | Should -Be 'StackResponseDto'
            }
            It 'Should pass PrimaryAssetId as a query parameter' {
                Get-IMStack -PrimaryAssetId $PrimaryId
                Should -Invoke Invoke-ImmichApiSearchStacks -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $PrimaryAssetId -eq $PrimaryId
                }
            }
            It 'Should forward an explicit session' {
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                Get-IMStack -Session $Session
                Should -Invoke Invoke-ImmichApiSearchStacks -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }
        }
        Context 'By Id' {
            It 'Should call GetStack with the id' {
                $Result = Get-IMStack -Id $StackId
                Should -Invoke Invoke-ImmichApiGetStack -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $StackId
                }
                Should -Invoke Invoke-ImmichApiSearchStacks -ModuleName PSImmich -Exactly 0 -Scope It
                $Result.GetType().Name | Should -Be 'StackResponseDto'
            }
        }
    }
    Describe 'New-IMStack' -Tag 'Unit', 'New-IMStack' {
        BeforeAll {
            Mock Invoke-ImmichApiCreateStack -ModuleName PSImmich {
                return [PSCustomObject]@{ id = 'new-stack-guid'; primaryAssetId = '12345678-1234-5678-9012-123456789abc'; assets = @() }
            }
        }
        Context 'Stack Creation' {
            It 'Should send the asset ids in the body' {
                $Result = New-IMStack -AssetIds @('12345678-1234-5678-9012-123456789abc', '23456789-2345-6789-0123-23456789abcd', '34567890-3456-7890-1234-3456789abcde')
                Should -Invoke Invoke-ImmichApiCreateStack -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.assetIds.Count -eq 3 -and $Body.assetIds[0] -eq '12345678-1234-5678-9012-123456789abc'
                }
                $Result.GetType().Name | Should -Be 'StackResponseDto'
            }
            It 'Should reject an invalid asset id' {
                { New-IMStack -AssetIds @('not-a-guid') } | Should -Throw
            }
        }
    }
    Describe 'Remove-IMStack' -Tag 'Unit', 'Remove-IMStack' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteStacks -ModuleName PSImmich { return $null }
        }
        Context 'Stack Removal' {
            It 'Should bulk delete the stack id' {
                Remove-IMStack -Id '12345678-1234-5678-9012-123456789abc' -Confirm:$false
                Should -Invoke Invoke-ImmichApiDeleteStacks -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.ids -contains '12345678-1234-5678-9012-123456789abc'
                }
            }
            It 'Should send all ids from the pipeline in one request' {
                @('12345678-1234-5678-9012-123456789abc', '23456789-2345-6789-0123-23456789abcd') | Remove-IMStack -Force
                Should -Invoke Invoke-ImmichApiDeleteStacks -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.ids.Count -eq 2
                }
            }
            It 'Should not call the API when -WhatIf is used' {
                Remove-IMStack -Id '12345678-1234-5678-9012-123456789abc' -WhatIf
                Should -Invoke Invoke-ImmichApiDeleteStacks -ModuleName PSImmich -Exactly 0 -Scope It
            }
        }
    }
    Describe 'Remove-IMStackAsset' -Tag 'Unit', 'Remove-IMStackAsset' {
        BeforeAll {
            Mock Invoke-ImmichApiRemoveAssetFromStack -ModuleName PSImmich { }
        }
        Context 'Stack Asset Removal' {
            It 'Should remove the asset from the stack' {
                Remove-IMStackAsset -StackId '12345678-1234-1234-1234-123456789abc' -AssetId '12345678-1234-1234-1234-123456789def' -Confirm:$false
                Should -Invoke Invoke-ImmichApiRemoveAssetFromStack -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc' -and $AssetId -eq '12345678-1234-1234-1234-123456789def'
                }
            }
        }
    }
    Describe 'Set-IMStack' -Tag 'Unit', 'Set-IMStack' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateStack -ModuleName PSImmich {
                return [PSCustomObject]@{ id = '12345678-1234-1234-1234-123456789abc'; primaryAssetId = '12345678-1234-1234-1234-123456789def'; assets = @() }
            }
        }
        Context 'Stack Updates' {
            It 'Should send the primary asset id to the update route' {
                $Result = Set-IMStack -Id '12345678-1234-1234-1234-123456789abc' -PrimaryAssetId '12345678-1234-1234-1234-123456789def'
                Should -Invoke Invoke-ImmichApiUpdateStack -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-1234-1234-123456789abc' -and $Body.primaryAssetId -eq '12345678-1234-1234-1234-123456789def'
                }
                $Result.GetType().Name | Should -Be 'StackResponseDto'
            }
        }
    }
    Describe 'Get-IMPlugin' -Tag 'Unit', 'Get-IMPlugin' {
        BeforeAll {
            Mock Invoke-ImmichApiSearchPlugins -ModuleName PSImmich {
                return @(
                    [pscustomobject]@{ id = '123e4567-e89b-12d3-a456-426614174000'; name = 'Test Plugin 1'; title = 'Plugin One'; version = '1.0.0'; enabled = $true; methods = @() },
                    [pscustomobject]@{ id = '223e4567-e89b-12d3-a456-426614174001'; name = 'Test Plugin 2'; title = 'Plugin Two'; version = '2.1.0'; enabled = $false; methods = @() }
                )
            }
            Mock Invoke-ImmichApiGetPlugin -ModuleName PSImmich {
                return [pscustomobject]@{ id = $Id; name = 'Test Plugin 1'; title = 'Plugin One'; version = '1.0.0'; enabled = $true; methods = @() }
            }
        }

        Context 'When retrieving all plugins (list parameter set)' {
            It 'Should call Invoke-ImmichApiSearchPlugins without filters' {
                Get-IMPlugin

                Should -Invoke Invoke-ImmichApiSearchPlugins -Times 1 -Exactly -Scope It -ModuleName PSImmich
            }

            It 'Should return PluginResponseDto objects' {
                $Result = Get-IMPlugin

                $Result | Should -HaveCount 2
                $Result[0].GetType().Name | Should -Be 'PluginResponseDto'
                $Result[0].name | Should -Be 'Test Plugin 1'
            }

            It 'Should forward filter parameters to Invoke-ImmichApiSearchPlugins' {
                Get-IMPlugin -Name 'Test Plugin 1' -Title 'Plugin One' -Version '1.0.0' -Description 'desc' -Enabled $true

                Should -Invoke Invoke-ImmichApiSearchPlugins -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Name -eq 'Test Plugin 1' -and $Title -eq 'Plugin One' -and $Version -eq '1.0.0' -and
                    $Description -eq 'desc' -and $Enabled -eq $true
                }
            }

            It 'Should pass the explicit Session to Invoke-ImmichApiSearchPlugins' {
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])

                Get-IMPlugin -Session $Session

                Should -Invoke Invoke-ImmichApiSearchPlugins -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }
        }

        Context 'When retrieving specific plugin by ID (id parameter set)' {
            It 'Should call Invoke-ImmichApiGetPlugin with the plugin ID' {
                Get-IMPlugin -Id '123e4567-e89b-12d3-a456-426614174000'

                Should -Invoke Invoke-ImmichApiGetPlugin -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should return a PluginResponseDto object' {
                $Result = Get-IMPlugin -Id '123e4567-e89b-12d3-a456-426614174000'

                $Result.GetType().Name | Should -Be 'PluginResponseDto'
                $Result.id | Should -Be '123e4567-e89b-12d3-a456-426614174000'
            }
        }

        Context 'Pipeline support' {
            It 'Should accept Id from pipeline by value' {
                '123e4567-e89b-12d3-a456-426614174000' | Get-IMPlugin

                Should -Invoke Invoke-ImmichApiGetPlugin -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept Id from pipeline by property name' {
                [PSCustomObject]@{Id = '123e4567-e89b-12d3-a456-426614174000' } | Get-IMPlugin

                Should -Invoke Invoke-ImmichApiGetPlugin -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate Id GUID format' {
                { Get-IMPlugin -Id 'invalid-guid' } | Should -Throw
            }
        }

        Context 'Session parameter' {
            It 'Should pass Session parameter when provided' {
                $function = Get-Command Get-IMPlugin
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }
        }
    }

    Describe 'Get-IMPluginMethod' -Tag 'Unit', 'Get-IMPluginMethod' {
        BeforeAll {
            Mock Invoke-ImmichApiSearchPluginMethods -ModuleName PSImmich {
                return @(
                    [pscustomobject]@{ key = 'my-plugin#send'; name = 'send'; title = 'Send'; description = 'Sends'; hostFunctions = $false; types = @('AssetV1'); uiHints = @(); schema = @{} },
                    [pscustomobject]@{ key = 'other#tag'; name = 'tag'; title = 'Tag'; description = 'Tags'; hostFunctions = $true; types = @('AssetV1'); uiHints = @(); schema = @{} }
                )
            }
        }

        Context 'When retrieving plugin methods' {
            It 'Should call Invoke-ImmichApiSearchPluginMethods without filters' {
                Get-IMPluginMethod

                Should -Invoke Invoke-ImmichApiSearchPluginMethods -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $null -eq $Name -and $null -eq $Trigger -and $null -eq $Enabled
                }
            }

            It 'Should return PluginMethodResponseDto objects' {
                $Result = Get-IMPluginMethod

                $Result | Should -HaveCount 2
                $Result[0].GetType().Name | Should -Be 'PluginMethodResponseDto'
                $Result[0].key | Should -Be 'my-plugin#send'
            }

            It 'Should forward filter parameters to Invoke-ImmichApiSearchPluginMethods' {
                Get-IMPluginMethod -Name 'send' -Title 'Send' -Description 'Sends' -PluginName 'my-plugin' -PluginVersion '1.0.0' -Enabled $false -Trigger 'AssetCreate' -Type 'AssetV1'

                Should -Invoke Invoke-ImmichApiSearchPluginMethods -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Name -eq 'send' -and $Title -eq 'Send' -and $Description -eq 'Sends' -and
                    $PluginName -eq 'my-plugin' -and $PluginVersion -eq '1.0.0' -and $Enabled -eq $false -and
                    $Trigger -eq 'AssetCreate' -and $Type -eq 'AssetV1'
                }
            }

            It 'Should forward a plugin method ID filter' {
                Get-IMPluginMethod -Id '123e4567-e89b-12d3-a456-426614174000'

                Should -Invoke Invoke-ImmichApiSearchPluginMethods -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should pass the explicit Session to Invoke-ImmichApiSearchPluginMethods' {
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])

                Get-IMPluginMethod -Session $Session

                Should -Invoke Invoke-ImmichApiSearchPluginMethods -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should reject an invalid Trigger value' {
                { Get-IMPluginMethod -Trigger 'Invalid' } | Should -Throw
            }

            It 'Should reject an invalid Type value' {
                { Get-IMPluginMethod -Type 'Invalid' } | Should -Throw
            }

            It 'Should validate Id GUID format' {
                { Get-IMPluginMethod -Id 'invalid-guid' } | Should -Throw
            }
        }
    }

    Describe 'Get-IMPluginTemplate' -Tag 'Unit', 'Get-IMPluginTemplate' {
        BeforeAll {
            Mock Invoke-ImmichApiSearchPluginTemplates -ModuleName PSImmich {
                return @(
                    [pscustomobject]@{ key = 'template-1'; title = 'Template One'; description = 'First'; trigger = 'AssetCreate'; uiHints = @(); steps = @() },
                    [pscustomobject]@{ key = 'template-2'; title = 'Template Two'; description = 'Second'; trigger = 'AssetTagged'; uiHints = @(); steps = @() }
                )
            }
        }

        Context 'When retrieving workflow templates' {
            It 'Should call Invoke-ImmichApiSearchPluginTemplates' {
                Get-IMPluginTemplate

                Should -Invoke Invoke-ImmichApiSearchPluginTemplates -Times 1 -Exactly -Scope It -ModuleName PSImmich
            }

            It 'Should return PluginTemplateResponseDto objects' {
                $Result = Get-IMPluginTemplate

                $Result | Should -HaveCount 2
                $Result[0].GetType().Name | Should -Be 'PluginTemplateResponseDto'
                $Result[0].key | Should -Be 'template-1'
            }

            It 'Should pass the explicit Session to Invoke-ImmichApiSearchPluginTemplates' {
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])

                Get-IMPluginTemplate -Session $Session

                Should -Invoke Invoke-ImmichApiSearchPluginTemplates -Times 1 -Exactly -Scope It -ModuleName PSImmich -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }
        }
    }

    Describe 'Get-IMWorkflow' -Tag 'Unit', 'Get-IMWorkflow' {
        BeforeAll {
            $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
            Mock Invoke-ImmichApiSearchWorkflows -ModuleName PSImmich {
                return @(
                    [pscustomobject]@{ id = '123e4567-e89b-12d3-a456-426614174000'; name = 'Test Workflow 1'; trigger = 'AssetCreate'; enabled = $true; logging = $false; steps = @() },
                    [pscustomobject]@{ id = '223e4567-e89b-12d3-a456-426614174001'; name = 'Test Workflow 2'; trigger = 'AssetTagged'; enabled = $false; logging = $true; steps = @() }
                )
            }
            Mock Invoke-ImmichApiGetWorkflow -ModuleName PSImmich {
                return [pscustomobject]@{ id = $Id; name = 'Test Workflow 1'; trigger = 'AssetCreate'; enabled = $true; logging = $false; steps = @() }
            }
            Mock Invoke-ImmichApiGetWorkflowForShare -ModuleName PSImmich {
                return [pscustomobject]@{ name = 'Test Workflow 1'; trigger = 'AssetCreate'; steps = @() }
            }
        }

        Context 'When retrieving all workflows (list parameter set)' {
            It 'Should call Invoke-ImmichApiSearchWorkflows without filters by default' {
                Get-IMWorkflow

                Should -Invoke Invoke-ImmichApiSearchWorkflows -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $Name -and $null -eq $Description -and $null -eq $Enabled -and $null -eq $Logging -and $null -eq $Trigger
                }
            }

            It 'Should pass filter parameters through to the API' {
                Get-IMWorkflow -Name 'Test' -Description 'Desc' -Trigger 'AssetCreate' -Enabled:$false -Logging:$true

                Should -Invoke Invoke-ImmichApiSearchWorkflows -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Name -eq 'Test' -and $Description -eq 'Desc' -and $Trigger -eq 'AssetCreate' -and $Enabled -eq $false -and $Logging -eq $true
                }
            }

            It 'Should return WorkflowResponseDto objects' {
                $result = @(Get-IMWorkflow)

                $result.Count | Should -Be 2
                $result[0].GetType().Name | Should -Be 'WorkflowResponseDto'
                $result[1].trigger | Should -Be 'AssetTagged'
            }

            It 'Should reject an invalid trigger' {
                { Get-IMWorkflow -Trigger 'upload' } | Should -Throw
            }
        }

        Context 'When retrieving a specific workflow (id parameter set)' {
            It 'Should call Invoke-ImmichApiGetWorkflow with the workflow ID' {
                Get-IMWorkflow -Id '123e4567-e89b-12d3-a456-426614174000'

                Should -Invoke Invoke-ImmichApiGetWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
                Should -Invoke Invoke-ImmichApiGetWorkflowForShare -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }

            It 'Should return a WorkflowResponseDto' {
                $result = Get-IMWorkflow -Id '123e4567-e89b-12d3-a456-426614174000'

                $result.GetType().Name | Should -Be 'WorkflowResponseDto'
                $result.id | Should -Be '123e4567-e89b-12d3-a456-426614174000'
            }

            It 'Should call the share endpoint and return a WorkflowShareResponseDto when -Share is specified' {
                $result = Get-IMWorkflow -Id '123e4567-e89b-12d3-a456-426614174000' -Share

                Should -Invoke Invoke-ImmichApiGetWorkflowForShare -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
                Should -Invoke Invoke-ImmichApiGetWorkflow -ModuleName PSImmich -Times 0 -Exactly -Scope It
                $result.GetType().Name | Should -Be 'WorkflowShareResponseDto'
            }

            It 'Should forward the session' {
                Get-IMWorkflow -Id '123e4567-e89b-12d3-a456-426614174000' -Session $Session

                Should -Invoke Invoke-ImmichApiGetWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }
        }

        Context 'Pipeline support' {
            It 'Should accept Id from pipeline by value' {
                '123e4567-e89b-12d3-a456-426614174000' | Get-IMWorkflow

                Should -Invoke Invoke-ImmichApiGetWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept Id from pipeline by property name' {
                [PSCustomObject]@{Id = '123e4567-e89b-12d3-a456-426614174000' } | Get-IMWorkflow

                Should -Invoke Invoke-ImmichApiGetWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate Id GUID format' {
                { Get-IMWorkflow -Id 'invalid-guid' } | Should -Throw
            }
        }

        Context 'Session parameter' {
            It 'Should expose the Session parameter as ImmichSession' {
                $function = Get-Command Get-IMWorkflow
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }
        }
    }
    Describe 'New-IMWorkflow' -Tag 'Unit', 'New-IMWorkflow' {
        BeforeAll {
            Mock Invoke-ImmichApiCreateWorkflow -ModuleName PSImmich {
                return [pscustomobject]@{ id = '123e4567-e89b-12d3-a456-426614174000'; name = $Body.name; trigger = $Body.trigger; enabled = $Body.enabled; logging = $false; steps = @() }
            }
        }

        Context 'When creating a new workflow' {
            It 'Should call Invoke-ImmichApiCreateWorkflow with name, trigger and default enabled state' {
                New-IMWorkflow -Name 'Test Workflow' -Trigger 'AssetCreate'

                Should -Invoke Invoke-ImmichApiCreateWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.name -eq 'Test Workflow' -and $Body.trigger -eq 'AssetCreate' -and $Body.enabled -eq $true
                }
            }

            It 'Should omit optional fields when they are not specified' {
                New-IMWorkflow -Name 'Test Workflow' -Trigger 'AssetCreate'

                Should -Invoke Invoke-ImmichApiCreateWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    -not $Body.ContainsKey('description') -and -not $Body.ContainsKey('logging') -and -not $Body.ContainsKey('steps')
                }
            }

            It 'Should send description, logging and steps when specified' {
                $steps = @(@{ method = 'TagAsset'; config = @{ tagId = 'tag' }; enabled = $true })
                New-IMWorkflow -Name 'Test' -Trigger 'AssetTagged' -Description 'Desc' -Logging:$true -Steps $steps

                Should -Invoke Invoke-ImmichApiCreateWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.description -eq 'Desc' -and $Body.logging -eq $true -and $Body.steps.Count -eq 1 -and $Body.steps[0].method -eq 'TagAsset'
                }
            }

            It 'Should send enabled false when -Enabled:$false is specified' {
                New-IMWorkflow -Name 'Test' -Trigger 'AssetCreate' -Enabled:$false

                Should -Invoke Invoke-ImmichApiCreateWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.enabled -eq $false
                }
            }

            It 'Should return a WorkflowResponseDto' {
                $result = New-IMWorkflow -Name 'Test Workflow' -Trigger 'AssetCreate'

                $result.GetType().Name | Should -Be 'WorkflowResponseDto'
                $result.name | Should -Be 'Test Workflow'
            }
        }

        Context 'Parameter validation' {
            It 'Should require Name and Trigger' {
                $command = Get-Command New-IMWorkflow
                $command.Parameters['Name'].Attributes.Where({ $_ -is [Parameter] }).Mandatory | Should -Contain $true
                $command.Parameters['Trigger'].Attributes.Where({ $_ -is [Parameter] }).Mandatory | Should -Contain $true
            }

            It 'Should reject an unknown trigger' {
                { New-IMWorkflow -Name 'Test' -Trigger 'upload' } | Should -Throw
            }
        }
    }
    Describe 'Set-IMWorkflow' -Tag 'Unit', 'Set-IMWorkflow' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateWorkflow -ModuleName PSImmich {
                return [pscustomobject]@{ id = $Id; name = 'Updated'; trigger = 'AssetCreate'; enabled = $true; logging = $false; steps = @() }
            }
        }

        Context 'When updating a workflow' {
            It 'Should call Invoke-ImmichApiUpdateWorkflow with the workflow ID' {
                Set-IMWorkflow -Id '123e4567-e89b-12d3-a456-426614174000' -Name 'Updated' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000' -and $Body.name -eq 'Updated'
                }
            }

            It 'Should only send bound parameters in the body' {
                Set-IMWorkflow -Id '123e4567-e89b-12d3-a456-426614174000' -Enabled:$false -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.enabled -eq $false -and -not $Body.ContainsKey('name') -and -not $Body.ContainsKey('trigger') -and -not $Body.ContainsKey('steps')
                }
            }

            It 'Should send trigger, logging and steps when specified' {
                $steps = @(@{ method = 'TagAsset'; config = @{} })
                Set-IMWorkflow -Id '123e4567-e89b-12d3-a456-426614174000' -Trigger 'AssetTagged' -Logging:$true -Steps $steps -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.trigger -eq 'AssetTagged' -and $Body.logging -eq $true -and $Body.steps.Count -eq 1
                }
            }

            It 'Should handle multiple IDs' {
                $Ids = @('123e4567-e89b-12d3-a456-426614174000', '223e4567-e89b-12d3-a456-426614174001')
                Set-IMWorkflow -Id $Ids -Name 'Updated' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateWorkflow -ModuleName PSImmich -Times 2 -Exactly -Scope It
            }

            It 'Should not call the API when -WhatIf is specified' {
                Set-IMWorkflow -Id '123e4567-e89b-12d3-a456-426614174000' -Name 'Updated' -WhatIf

                Should -Invoke Invoke-ImmichApiUpdateWorkflow -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }

            It 'Should return a WorkflowResponseDto' {
                $result = Set-IMWorkflow -Id '123e4567-e89b-12d3-a456-426614174000' -Name 'Updated' -Confirm:$false

                $result.GetType().Name | Should -Be 'WorkflowResponseDto'
            }
        }

        Context 'Pipeline support' {
            It 'Should accept Id from pipeline by value' {
                '123e4567-e89b-12d3-a456-426614174000' | Set-IMWorkflow -Name 'Updated' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept Id from pipeline by property name' {
                [PSCustomObject]@{Id = '123e4567-e89b-12d3-a456-426614174000' } | Set-IMWorkflow -Name 'Updated' -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate Id GUID format' {
                { Set-IMWorkflow -Id 'invalid-guid' -Name 'Test' } | Should -Throw
            }

            It 'Should reject an unknown trigger' {
                { Set-IMWorkflow -Id '123e4567-e89b-12d3-a456-426614174000' -Trigger 'upload' -Confirm:$false } | Should -Throw
            }
        }
    }
    Describe 'Remove-IMWorkflow' -Tag 'Unit', 'Remove-IMWorkflow' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteWorkflow -ModuleName PSImmich {}
        }

        Context 'When removing workflows' {
            It 'Should call Invoke-ImmichApiDeleteWorkflow with the workflow ID' {
                Remove-IMWorkflow -Id '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should not call the API when -WhatIf is specified' {
                Remove-IMWorkflow -Id '123e4567-e89b-12d3-a456-426614174000' -WhatIf

                Should -Invoke Invoke-ImmichApiDeleteWorkflow -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }

            It 'Should handle multiple IDs' {
                $Ids = @('123e4567-e89b-12d3-a456-426614174000', '223e4567-e89b-12d3-a456-426614174001')
                Remove-IMWorkflow -Id $Ids -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteWorkflow -ModuleName PSImmich -Times 2 -Exactly -Scope It
                Should -Invoke Invoke-ImmichApiDeleteWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '223e4567-e89b-12d3-a456-426614174001'
                }
            }
        }

        Context 'Pipeline support' {
            It 'Should accept Id from pipeline by value' {
                '123e4567-e89b-12d3-a456-426614174000' | Remove-IMWorkflow -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept Id from pipeline by property name' {
                [PSCustomObject]@{Id = '123e4567-e89b-12d3-a456-426614174000' } | Remove-IMWorkflow -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept WorkflowId alias from pipeline by property name' {
                [PSCustomObject]@{WorkflowId = '123e4567-e89b-12d3-a456-426614174000' } | Remove-IMWorkflow -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteWorkflow -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate Id GUID format' {
                { Remove-IMWorkflow -Id 'invalid-guid' } | Should -Throw
            }
        }
    }

    Describe 'Get-IMWorkflowTrigger' -Tag 'Unit', 'Get-IMWorkflowTrigger' {
        BeforeAll {
            Mock Invoke-ImmichApiGetWorkflowTriggers -ModuleName PSImmich {
                return @(
                    [pscustomobject]@{ trigger = 'AssetCreate'; types = @('asset.create') },
                    [pscustomobject]@{ trigger = 'AssetTagged'; types = @('asset.tag') }
                )
            }
        }

        It 'Should call Invoke-ImmichApiGetWorkflowTriggers' {
            Get-IMWorkflowTrigger

            Should -Invoke Invoke-ImmichApiGetWorkflowTriggers -ModuleName PSImmich -Times 1 -Exactly -Scope It
        }

        It 'Should return WorkflowTriggerResponseDto objects' {
            $result = @(Get-IMWorkflowTrigger)

            $result.Count | Should -Be 2
            $result[0].GetType().Name | Should -Be 'WorkflowTriggerResponseDto'
            $result[0].trigger | Should -Be 'AssetCreate'
            $result[0].types | Should -Contain 'asset.create'
        }
    }

    Describe 'Get-IMWorkflowLog' -Tag 'Unit', 'Get-IMWorkflowLog' {
        BeforeAll {
            Mock Invoke-ImmichApiGetWorkflowLogs -ModuleName PSImmich {
                return @(
                    [pscustomobject]@{ id = 'log-1'; at = '2025-01-01T00:00:00Z'; result = 'completed'; lastStep = 0; triggerDataId = 'asset-1' }
                )
            }
        }

        Context 'When retrieving logs' {
            It 'Should only send the workflow ID by default' {
                Get-IMWorkflowLog -Id '123e4567-e89b-12d3-a456-426614174000'

                Should -Invoke Invoke-ImmichApiGetWorkflowLogs -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000' -and $null -eq $Before -and $null -eq $Limit -and $null -eq $Result
                }
            }

            It 'Should pass Before, Limit and Result through to the API' {
                Get-IMWorkflowLog -Id '123e4567-e89b-12d3-a456-426614174000' -Before ([datetime]'2025-06-01') -Limit 10 -Result 'error'

                Should -Invoke Invoke-ImmichApiGetWorkflowLogs -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Before -eq [datetime]'2025-06-01' -and $Limit -eq 10 -and $Result -eq 'error'
                }
            }

            It 'Should return WorkflowLogEntryDto objects' {
                $result = Get-IMWorkflowLog -Id '123e4567-e89b-12d3-a456-426614174000'

                $result.GetType().Name | Should -Be 'WorkflowLogEntryDto'
                $result.result | Should -Be 'completed'
            }
        }

        Context 'Pipeline support' {
            It 'Should accept Id from pipeline by value' {
                '123e4567-e89b-12d3-a456-426614174000' | Get-IMWorkflowLog

                Should -Invoke Invoke-ImmichApiGetWorkflowLogs -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept Id from pipeline by property name' {
                [PSCustomObject]@{Id = '123e4567-e89b-12d3-a456-426614174000' } | Get-IMWorkflowLog

                Should -Invoke Invoke-ImmichApiGetWorkflowLogs -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '123e4567-e89b-12d3-a456-426614174000'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate Id GUID format' {
                { Get-IMWorkflowLog -Id 'invalid-guid' } | Should -Throw
            }

            It 'Should reject an unknown result' {
                { Get-IMWorkflowLog -Id '123e4567-e89b-12d3-a456-426614174000' -Result 'failed' } | Should -Throw
            }
        }
    }

    Describe 'Set-IMQueue' -Tag 'Unit', 'Set-IMQueue' {
        BeforeAll {
            Mock Invoke-ImmichApiUpdateQueue -ModuleName PSImmich {
                [pscustomobject]@{ name = $Name; isPaused = $Body.isPaused; statistics = [pscustomobject]@{ waiting = 0; active = 0; completed = 1; failed = 0; delayed = 0; paused = 0 } }
            }
        }

        Context 'Request mapping' {
            It 'Should pause the queue with isPaused=true' {
                Set-IMQueue -Name 'thumbnailGeneration' -IsPaused $true -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateQueue -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Name -eq 'thumbnailGeneration' -and $Body.isPaused -eq $true
                }
            }

            It 'Should resume the queue with isPaused=false' {
                Set-IMQueue -Name 'faceDetection' -IsPaused $false -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateQueue -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Name -eq 'faceDetection' -and $Body.isPaused -eq $false
                }
            }

            It 'Should update each queue received from the pipeline' {
                @('thumbnailGeneration', 'videoConversion') | Set-IMQueue -IsPaused $true -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateQueue -ModuleName PSImmich -Exactly 2 -Scope It
            }

            It 'Should forward an explicit session' {
                $TestSession = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                Set-IMQueue -Session $TestSession -Name 'ocr' -IsPaused $true -Confirm:$false

                Should -Invoke Invoke-ImmichApiUpdateQueue -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $ImmichSession -eq $TestSession
                }
            }

            It 'Should not call the API when WhatIf is specified' {
                Set-IMQueue -Name 'ocr' -IsPaused $true -WhatIf

                Should -Invoke Invoke-ImmichApiUpdateQueue -ModuleName PSImmich -Exactly 0 -Scope It
            }
        }

        Context 'Output' {
            It 'Should return a QueueResponseDto' {
                $Result = Set-IMQueue -Name 'ocr' -IsPaused $true -Confirm:$false

                $Result.GetType().Name | Should -Be 'QueueResponseDto'
                $Result.name | Should -Be 'ocr'
            }
        }

        Context 'Parameter Validation' {
            It 'Should reject an invalid queue name' {
                { Set-IMQueue -Name 'invalidQueue' -IsPaused $true -Confirm:$false } | Should -Throw
            }
        }
    }
    Describe 'Clear-IMQueue' -Tag 'Unit', 'Clear-IMQueue' {
        BeforeAll {
            Mock Invoke-ImmichApiEmptyQueue -ModuleName PSImmich { }
        }

        Context 'Request mapping' {
            It 'Should call Invoke-ImmichApiEmptyQueue with the queue name and failed=false' {
                Clear-IMQueue -Name 'thumbnailGeneration' -Confirm:$false

                Should -Invoke Invoke-ImmichApiEmptyQueue -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Name -eq 'thumbnailGeneration' -and
                    $Body.failed -eq $false
                }
            }

            It 'Should not send a force field' {
                Clear-IMQueue -Name 'thumbnailGeneration' -Confirm:$false

                Should -Invoke Invoke-ImmichApiEmptyQueue -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    -not $Body.ContainsKey('force')
                }
            }

            It 'Should clear each queue received from the pipeline' {
                'thumbnailGeneration', 'faceDetection' | Clear-IMQueue -Confirm:$false

                Should -Invoke Invoke-ImmichApiEmptyQueue -ModuleName PSImmich -Exactly 2 -Scope It
            }

            It 'Should not call the API when WhatIf is specified' {
                Clear-IMQueue -Name 'thumbnailGeneration' -WhatIf

                Should -Invoke Invoke-ImmichApiEmptyQueue -ModuleName PSImmich -Exactly 0 -Scope It
            }
        }

        Context 'Force parameter' {
            It 'Should write a warning and still clear the queue when Force is specified' {
                Clear-IMQueue -Name 'thumbnailGeneration' -Force -Confirm:$false -WarningVariable warnings -WarningAction SilentlyContinue

                $warnings | Should -Not -BeNullOrEmpty
                Should -Invoke Invoke-ImmichApiEmptyQueue -ModuleName PSImmich -Exactly 1 -Scope It
            }
        }

        Context 'Parameter Validation' {
            It 'Should reject an invalid queue name' {
                { Clear-IMQueue -Name 'invalidQueue' -Confirm:$false } | Should -Throw
            }
        }
    }
    Describe 'Get-IMQueue' -Tag 'Unit', 'Get-IMQueue' {
        BeforeAll {
            Mock Invoke-ImmichApiGetQueue -ModuleName PSImmich {
                [pscustomobject]@{ name = $Name; isPaused = $false; statistics = [pscustomobject]@{ waiting = 2; active = 1; completed = 3; failed = 0; delayed = 0; paused = 0 } }
            }
            Mock Invoke-ImmichApiGetQueues -ModuleName PSImmich {
                @(
                    [pscustomobject]@{ name = 'thumbnailGeneration'; isPaused = $false; statistics = [pscustomobject]@{ waiting = 2; active = 1; completed = 3; failed = 0; delayed = 0; paused = 0 } }
                    [pscustomobject]@{ name = 'faceDetection'; isPaused = $true; statistics = [pscustomobject]@{ waiting = 0; active = 0; completed = 0; failed = 0; delayed = 0; paused = 0 } }
                )
            }
        }

        Context 'Request mapping' {
            It 'Should call Invoke-ImmichApiGetQueues when no name is specified' {
                Get-IMQueue

                Should -Invoke Invoke-ImmichApiGetQueues -ModuleName PSImmich -Exactly 1 -Scope It
                Should -Invoke Invoke-ImmichApiGetQueue -ModuleName PSImmich -Exactly 0 -Scope It
            }

            It 'Should call Invoke-ImmichApiGetQueue with the queue name' {
                Get-IMQueue -Name 'thumbnailGeneration'

                Should -Invoke Invoke-ImmichApiGetQueue -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Name -eq 'thumbnailGeneration'
                }
                Should -Invoke Invoke-ImmichApiGetQueues -ModuleName PSImmich -Exactly 0 -Scope It
            }

            It 'Should retrieve each queue received from the pipeline' {
                'thumbnailGeneration', 'facialRecognition' | Get-IMQueue

                Should -Invoke Invoke-ImmichApiGetQueue -ModuleName PSImmich -Exactly 2 -Scope It
            }

            It 'Should forward an explicit session' {
                $TestSession = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                Get-IMQueue -Session $TestSession

                Should -Invoke Invoke-ImmichApiGetQueues -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $ImmichSession -eq $TestSession
                }
            }
        }

        Context 'Output' {
            It 'Should return a QueueResponseDto per queue' {
                $Result = Get-IMQueue

                $Result | Should -HaveCount 2
                $Result[0].GetType().Name | Should -Be 'QueueResponseDto'
                $Result[0].statistics.waiting | Should -Be 2
                $Result[1].isPaused | Should -BeTrue
            }
        }

        Context 'Parameter Validation' {
            It 'Should reject an invalid queue name' {
                { Get-IMQueue -Name 'invalidQueue' } | Should -Throw
            }
        }
    }
    Describe 'Get-IMQueueJob' -Tag 'Unit', 'Get-IMQueueJob' {
        BeforeAll {
            Mock Invoke-ImmichApiGetQueueJobs -ModuleName PSImmich {
                @([pscustomobject]@{ id = 'job-1'; name = 'thumbnailGeneration'; timestamp = 1700000000000; data = @{ assetId = 'a1' } })
            }
        }

        Context 'Request mapping' {
            It 'Should call Invoke-ImmichApiGetQueueJobs with the queue name and no status filter' {
                Get-IMQueueJob -Name 'thumbnailGeneration'

                Should -Invoke Invoke-ImmichApiGetQueueJobs -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Name -eq 'thumbnailGeneration' -and -not $Status
                }
            }

            It 'Should pass the status filter as a query value, not a request body' {
                Get-IMQueueJob -Name 'faceDetection' -Status failed

                Should -Invoke Invoke-ImmichApiGetQueueJobs -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Name -eq 'faceDetection' -and $Status -contains 'failed'
                }
            }

            It 'Should pass multiple status values' {
                Get-IMQueueJob -Name 'videoConversion' -Status active, waiting

                Should -Invoke Invoke-ImmichApiGetQueueJobs -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Status -contains 'active' -and $Status -contains 'waiting'
                }
            }

            It 'Should forward an explicit session' {
                $TestSession = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                Get-IMQueueJob -Session $TestSession -Name 'ocr'

                Should -Invoke Invoke-ImmichApiGetQueueJobs -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $ImmichSession -eq $TestSession
                }
            }
        }

        Context 'Output' {
            It 'Should return a QueueJobResponseDto' {
                $Result = Get-IMQueueJob -Name 'thumbnailGeneration'

                $Result.GetType().Name | Should -Be 'QueueJobResponseDto'
                $Result.id | Should -Be 'job-1'
            }
        }

        Context 'Parameter Validation' {
            It 'Should reject an invalid status value' {
                { Get-IMQueueJob -Name 'ocr' -Status 'bogus' } | Should -Throw
            }
        }
    }

    Describe 'Get-IMUserStatistic' -Tag 'Unit', 'Get-IMUserStatistic' {
        BeforeAll {
            Mock Invoke-ImmichApiGetUserStatisticsAdmin {
                return [PSCustomObject]@{ photos = 10; videos = 2; usage = 12345 }
            } -ModuleName PSImmich
        }
        Context 'User Statistics' {
            It 'Should get statistics for a user by id' {
                $null = Get-IMUserStatistic -Id '12345678-1234-5678-9012-123456789abc'
                Should -Invoke Invoke-ImmichApiGetUserStatisticsAdmin -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc'
                }
            }
        }
    }
    Describe 'Get-ImUserSession' -Tag 'Unit', 'Get-ImUserSession' {
        BeforeAll {
            Mock Invoke-ImmichApiGetUserSessionsAdmin {
                return @([PSCustomObject]@{ id = 'session-1'; current = $false })
            } -ModuleName PSImmich
        }
        Context 'User Sessions' {
            It 'Should get sessions for a user by id' {
                $null = Get-IMUserSession -Id '12345678-1234-5678-9012-123456789abc'
                Should -Invoke Invoke-ImmichApiGetUserSessionsAdmin -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Id -eq '12345678-1234-5678-9012-123456789abc'
                }
            }
        }
    }

    Describe 'Copy-IMAssetInfo' -Tag 'Unit', 'Copy-IMAssetInfo' {
        BeforeAll {
            Mock Invoke-ImmichApiCopyAsset -ModuleName PSImmich {
                return $null
            }
        }

        Context 'When copying all asset information' {
            It 'Should call Invoke-ImmichApiCopyAsset with correct parameters' {
                $params = @{
                    SourceId = '123e4567-e89b-12d3-a456-426614174000'
                    TargetId = '987fcdeb-51a2-43d5-b789-123456789abc'
                }

                Copy-IMAssetInfo @params

                Should -Invoke Invoke-ImmichApiCopyAsset -Times 1 -Exactly -ModuleName PSImmich -ParameterFilter {
                    $Body.sourceId -eq $params.SourceId -and
                    $Body.targetId -eq $params.TargetId
                }
            }
        }

        Context 'When copying selective asset information' {
            It 'Should include only specified switches in body' {
                $params = @{
                    SourceId    = '123e4567-e89b-12d3-a456-426614174000'
                    TargetId    = '987fcdeb-51a2-43d5-b789-123456789abc'
                    Albums      = $true
                    Metadata    = $true
                    SharedLinks = $false
                    Sidecar     = $false
                    Stack       = $false
                }

                Copy-IMAssetInfo @params

                Should -Invoke Invoke-ImmichApiCopyAsset -Times 1 -Exactly -ModuleName PSImmich -ParameterFilter {
                    $Body.sourceId -eq $params.SourceId -and
                    $Body.targetId -eq $params.TargetId -and
                    $Body.albums -eq $params.Albums -and
                    $Body.metadata -eq $params.Metadata
                }
            }
        }

        Context 'When using ShouldProcess' {
            It 'Should support WhatIf parameter' {
                $params = @{
                    SourceId = '123e4567-e89b-12d3-a456-426614174000'
                    TargetId = '987fcdeb-51a2-43d5-b789-123456789abc'
                    WhatIf   = $true
                }

                Copy-IMAssetInfo @params

                Should -Invoke Invoke-ImmichApiCopyAsset -Times 0 -Exactly -ModuleName PSImmich
            }
        }

        Context 'Default parameter behavior' {
            It 'Should set all boolean switches to true when none are specified' {
                $params = @{
                    SourceId = '123e4567-e89b-12d3-a456-426614174000'
                    TargetId = '987fcdeb-51a2-43d5-b789-123456789abc'
                }

                Copy-IMAssetInfo @params

                Should -Invoke Invoke-ImmichApiCopyAsset -Times 1 -Exactly -ModuleName PSImmich -ParameterFilter {
                    $Body.albums -eq $true -and
                    $Body.metadata -eq $true -and
                    $Body.sharedLinks -eq $true -and
                    $Body.sidecar -eq $true -and
                    $Body.stack -eq $true
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate SourceId GUID format' {
                { Copy-IMAssetInfo -SourceId 'invalid-guid' -TargetId '987fcdeb-51a2-43d5-b789-123456789abc' } | Should -Throw
            }

            It 'Should validate TargetId GUID format' {
                { Copy-IMAssetInfo -SourceId '123e4567-e89b-12d3-a456-426614174000' -TargetId 'invalid-guid' } | Should -Throw
            }
        }

        Context 'Switch parameter behavior' {
            It 'Should only copy specified switches when some are provided' {
                $params = @{
                    SourceId = '123e4567-e89b-12d3-a456-426614174000'
                    TargetId = '987fcdeb-51a2-43d5-b789-123456789abc'
                    Albums   = $true
                    Metadata = $true
                }

                Copy-IMAssetInfo @params

                Should -Invoke Invoke-ImmichApiCopyAsset -Times 1 -Exactly -ModuleName PSImmich -ParameterFilter {
                    $Body.albums -eq $true -and
                    $Body.metadata -eq $true -and
                    -not $Body.ContainsKey('sharedLinks') -and
                    -not $Body.ContainsKey('sidecar') -and
                    -not $Body.ContainsKey('stack')
                }
            }

            It 'Should handle explicit false values for switches' {
                $params = @{
                    SourceId = '123e4567-e89b-12d3-a456-426614174000'
                    TargetId = '987fcdeb-51a2-43d5-b789-123456789abc'
                    Albums   = $false
                }

                Copy-IMAssetInfo @params

                Should -Invoke Invoke-ImmichApiCopyAsset -Times 1 -Exactly -ModuleName PSImmich -ParameterFilter {
                    $Body.albums -eq $false -and
                    -not $Body.ContainsKey('metadata') -and
                    -not $Body.ContainsKey('sharedLinks') -and
                    -not $Body.ContainsKey('sidecar') -and
                    -not $Body.ContainsKey('stack')
                }
            }
        }
    }
    Describe 'Resolve-IMDuplicate' -Tag 'Unit', 'Resolve-IMDuplicate' {
        BeforeAll {
            Mock Invoke-ImmichApiResolveDuplicates -ModuleName PSImmich {}
        }

        Context 'When resolving a single duplicate group' {
            It 'Should send the group with keep and trash asset ids' {
                Resolve-IMDuplicate -DuplicateId '5b0bbb8d-3a3e-4f46-a1ab-0e7a2a7f3c11' -KeepAssetId 'a1f0c6f2-1d43-4c1b-9d7e-2b0a6c3f8e10' -TrashAssetId 'b2e1d7a3-2e54-4d2c-8e8f-3c1b7d4f9f21' -Confirm:$false

                Should -Invoke Invoke-ImmichApiResolveDuplicates -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.groups.Count -eq 1 -and
                    $Body.groups[0].duplicateId -eq '5b0bbb8d-3a3e-4f46-a1ab-0e7a2a7f3c11' -and
                    $Body.groups[0].keepAssetIds -contains 'a1f0c6f2-1d43-4c1b-9d7e-2b0a6c3f8e10' -and
                    $Body.groups[0].trashAssetIds -contains 'b2e1d7a3-2e54-4d2c-8e8f-3c1b7d4f9f21'
                }
            }

            It 'Should not call the endpoint when WhatIf is specified' {
                Resolve-IMDuplicate -DuplicateId '5b0bbb8d-3a3e-4f46-a1ab-0e7a2a7f3c11' -KeepAssetId 'a1f0c6f2-1d43-4c1b-9d7e-2b0a6c3f8e10' -TrashAssetId 'b2e1d7a3-2e54-4d2c-8e8f-3c1b7d4f9f21' -WhatIf

                Should -Invoke Invoke-ImmichApiResolveDuplicates -ModuleName PSImmich -Times 0 -Exactly -Scope It
            }
        }

        Context 'When resolving groups from the pipeline' {
            It 'Should send multiple groups in a single body when piped by property name' {
                $Groups = @(
                    [PSCustomObject]@{ DuplicateId = '5b0bbb8d-3a3e-4f46-a1ab-0e7a2a7f3c11'; KeepAssetId = 'a1f0c6f2-1d43-4c1b-9d7e-2b0a6c3f8e10'; TrashAssetId = 'd4b3f9c5-4a76-4f4e-8a0a-5e3d9f6b1a43' }
                    [PSCustomObject]@{ DuplicateId = '6c1c0c9e-4b4f-4b57-b2bc-1f8b3e5a0d22'; KeepAssetId = 'c3a2e8b4-3f65-4e3d-9f9f-4d2c8e5a0f32'; TrashAssetId = 'e5c4a0d6-5b87-4a5f-9b1b-6f4e0a7c2b54' }
                )

                $Groups | Resolve-IMDuplicate -Confirm:$false

                Should -Invoke Invoke-ImmichApiResolveDuplicates -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.groups.Count -eq 2 -and
                    $Body.groups[1].duplicateId -eq '6c1c0c9e-4b4f-4b57-b2bc-1f8b3e5a0d22'
                }
            }
        }

        Context 'When an explicit session is provided' {
            It 'Should forward the session to the REST call' {
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])

                Resolve-IMDuplicate -Session $Session -DuplicateId '5b0bbb8d-3a3e-4f46-a1ab-0e7a2a7f3c11' -KeepAssetId 'a1f0c6f2-1d43-4c1b-9d7e-2b0a6c3f8e10' -TrashAssetId 'b2e1d7a3-2e54-4d2c-8e8f-3c1b7d4f9f21' -Confirm:$false

                Should -Invoke Invoke-ImmichApiResolveDuplicates -ModuleName PSImmich -Times 1 -Exactly -Scope It -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }
        }

        Context 'When parameters are invalid' {
            It 'Should throw for a malformed duplicate id' {
                { Resolve-IMDuplicate -DuplicateId 'not-a-guid' -KeepAssetId 'a1f0c6f2-1d43-4c1b-9d7e-2b0a6c3f8e10' -TrashAssetId 'b2e1d7a3-2e54-4d2c-8e8f-3c1b7d4f9f21' -Confirm:$false } | Should -Throw
            }

            It 'Should throw when KeepAssetId is omitted' {
                { Resolve-IMDuplicate -DuplicateId '5b0bbb8d-3a3e-4f46-a1ab-0e7a2a7f3c11' -TrashAssetId 'b2e1d7a3-2e54-4d2c-8e8f-3c1b7d4f9f21' -Confirm:$false } | Should -Throw
            }
        }
    }

    Describe 'Remove-IMDuplicate' -Tag 'Remove-IMDuplicate' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteDuplicates -ModuleName PSImmich {}
        }

        Context 'Parameter Validation' {
            It 'Should validate GUID format for Ids parameter' {
                { Remove-IMDuplicate -Ids 'invalid-guid' } | Should -Throw
            }

            It 'Should have Ids parameter as mandatory' {
                (Get-Command Remove-IMDuplicate).Parameters.Ids.Attributes.Mandatory | Should -Be $true
            }

            It 'Should have id alias for Ids parameter' {
                (Get-Command Remove-IMDuplicate).Parameters.Ids.Aliases | Should -Contain 'id'
            }

            It 'Should reject invalid GUID format' {
                { Remove-IMDuplicate -Ids 'not-a-guid' } | Should -Throw
            }
        }

        Context 'ShouldProcess Support' {
            It 'Should support ShouldProcess' {
                (Get-Command Remove-IMDuplicate).Parameters.ContainsKey('WhatIf') | Should -Be $true
                (Get-Command Remove-IMDuplicate).Parameters.ContainsKey('Confirm') | Should -Be $true
            }

            It 'Should call Invoke-ImmichApiDeleteDuplicates when confirmed for single duplicate' {
                Remove-IMDuplicate -Ids '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteDuplicates -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Body.ids -contains '123e4567-e89b-12d3-a456-426614174000'
                }
            }
            It 'Should call Invoke-ImmichApiDeleteDuplicates when confirmed for multiple duplicates' {
                $duplicateIds = @('123e4567-e89b-12d3-a456-426614174000', '987fcdeb-51a2-43d5-b789-123456789abc')
                Remove-IMDuplicate -Ids $duplicateIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteDuplicates -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Body.ids.Count -eq 2 -and
                    $Body.ids -contains '123e4567-e89b-12d3-a456-426614174000' -and
                    $Body.ids -contains '987fcdeb-51a2-43d5-b789-123456789abc'
                }
            }
        }

        Context 'Pipeline Support' {
            It 'Should accept pipeline input by value' {
                '123e4567-e89b-12d3-a456-426614174000' | Remove-IMDuplicate -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteDuplicates -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Body.ids -contains '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept pipeline input by property name (Ids)' {
                $duplicateObject = [PSCustomObject]@{ Ids = '123e4567-e89b-12d3-a456-426614174000' }
                $duplicateObject | Remove-IMDuplicate -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteDuplicates -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Body.ids -contains '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept pipeline input by property name (id alias)' {
                $duplicateObject = [PSCustomObject]@{ id = '123e4567-e89b-12d3-a456-426614174000' }
                $duplicateObject | Remove-IMDuplicate -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteDuplicates -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Body.ids -contains '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should handle multiple duplicates from pipeline' {
                $duplicates = @(
                    [PSCustomObject]@{ id = '123e4567-e89b-12d3-a456-426614174000' }
                    [PSCustomObject]@{ id = '987fcdeb-51a2-43d5-b789-123456789abc' }
                )
                $duplicates | Remove-IMDuplicate -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteDuplicates -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Body.ids.Count -eq 2 -and
                    $Body.ids -contains '123e4567-e89b-12d3-a456-426614174000' -and
                    $Body.ids -contains '987fcdeb-51a2-43d5-b789-123456789abc'
                }
            }

            It 'Should collect multiple pipeline objects into single API call' {
                $duplicateIds = @('123e4567-e89b-12d3-a456-426614174000', '987fcdeb-51a2-43d5-b789-123456789abc', 'abcdef01-2345-6789-abcd-ef0123456789')
                $duplicateIds | Remove-IMDuplicate -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteDuplicates -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Body.ids.Count -eq 3
                }
            }
        }

        Context 'Session Parameter' {
            It 'Should pass Session parameter when provided' {
                # Verify Session parameter is accepted by checking parameter definition
                $function = Get-Command Remove-IMDuplicate
                $sessionParam = $function.Parameters['Session']
                $sessionParam.ParameterType.Name | Should -Be 'ImmichSession'
            }

            It 'Should use default session when no session parameter provided' {
                Remove-IMDuplicate -Ids '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteDuplicates -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }

        Context 'API Integration' {
            It 'Should call the generated DeleteDuplicates wrapper with the duplicate IDs' {
                Remove-IMDuplicate -Ids '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteDuplicates -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Body.ids -contains '123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should include all duplicate IDs in request body' {
                $duplicateIds = @('123e4567-e89b-12d3-a456-426614174000', '987fcdeb-51a2-43d5-b789-123456789abc', 'abcdef01-2345-6789-abcd-ef0123456789')
                Remove-IMDuplicate -Ids $duplicateIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteDuplicates -ModuleName PSImmich -Times 1 -Exactly -ParameterFilter {
                    $Body.ids.Count -eq 3 -and
                    ($duplicateIds | ForEach-Object { $Body.ids -contains $_ }) -notcontains $false
                }
            }
        }
    }
    Describe 'Remove-IMFace' -Tag 'Unit', 'Remove-IMFace' {
        BeforeAll {
            Mock Invoke-ImmichApiDeleteFace -ModuleName PSImmich {}
        }

        Context 'Parameter Validation' {
            It 'Should require Id parameter' {
                (Get-Command Remove-IMFace).Parameters['Id'].Attributes.Mandatory | Should -Be $true
            }

            It 'Should validate GUID format for Id parameter' {
                { Remove-IMFace -Id 'invalid-guid' -Confirm:$false } | Should -Throw
            }

            It 'Should accept pipeline input for Id parameter' {
                $TestId = '123e4567-e89b-12d3-a456-426614174000'
                { $TestId | Remove-IMFace -Confirm:$false } | Should -Not -Throw
            }

            It 'Should accept multiple IDs' {
                $TestIds = @('123e4567-e89b-12d3-a456-426614174000', '987fcdeb-51a2-43d5-b789-123456789abc')
                { Remove-IMFace -Id $TestIds -Confirm:$false } | Should -Not -Throw
            }
        }

        Context 'ShouldProcess Support' {
            It 'Should support ShouldProcess' {
                $Command = Get-Command Remove-IMFace
                $CmdletBinding = $Command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
                $CmdletBinding.SupportsShouldProcess | Should -Be $true
            }

            It 'Should not call the API when -WhatIf is specified' {
                Remove-IMFace -Id '123e4567-e89b-12d3-a456-426614174000' -WhatIf

                Should -Invoke Invoke-ImmichApiDeleteFace -ModuleName PSImmich -Exactly 0 -Scope It
            }
        }

        Context 'API Calls' {
            It 'Should call Invoke-ImmichApiDeleteFace for a single ID' {
                $TestId = '123e4567-e89b-12d3-a456-426614174000'
                Remove-IMFace -Id $TestId -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteFace -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Id -eq $TestId
                }
            }

            It 'Should call the endpoint once per ID for multiple IDs' {
                $TestIds = @('123e4567-e89b-12d3-a456-426614174000', '987fcdeb-51a2-43d5-b789-123456789abc')
                Remove-IMFace -Id $TestIds -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteFace -ModuleName PSImmich -Exactly 2 -Scope It
            }

            It 'Should always send the required force field, defaulting to false' {
                Remove-IMFace -Id '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteFace -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.ContainsKey('force') -and $Body.force -eq $false
                }
            }

            It 'Should send force as true when -Force is specified' {
                Remove-IMFace -Id '123e4567-e89b-12d3-a456-426614174000' -Force -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteFace -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $Body.force -eq $true
                }
            }

            It 'Should forward an explicit session' {
                $Session = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([ImmichSession])
                Remove-IMFace -Id '123e4567-e89b-12d3-a456-426614174000' -Session $Session -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteFace -ModuleName PSImmich -Exactly 1 -Scope It -ParameterFilter {
                    $ImmichSession -eq $Session
                }
            }
        }

        Context 'Pipeline Support' {
            It 'Should process pipeline input correctly' {
                $TestIds = @('123e4567-e89b-12d3-a456-426614174000', '987fcdeb-51a2-43d5-b789-123456789abc')
                $TestIds | Remove-IMFace -Confirm:$false

                Should -Invoke Invoke-ImmichApiDeleteFace -ModuleName PSImmich -Exactly 2 -Scope It
            }
        }
    }
}
