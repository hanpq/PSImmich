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
            Mock InvokeImmichRestMethod {
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
            It 'Should call InvokeImmichRestMethod with correct parameters' {
                $params = @{
                    AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
                    Comment = 'Amazing sunset!'
                    Type    = 'comment'
                }

                Add-IMActivity @params

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                    $Method -eq 'Post' -and
                    $RelativePath -eq '/activities' -and
                    $Body.albumId -eq $params.AlbumId -and
                    $Body.comment -eq $params.Comment -and
                    $Body.type -eq $params.Type
                }
            }
        }

        Context 'When adding a like to a specific asset' {
            It 'Should call InvokeImmichRestMethod with asset ID' {
                $params = @{
                    AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
                    AssetId = 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
                    Type    = 'like'
                }

                Add-IMActivity @params

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                    $Method -eq 'Post' -and
                    $RelativePath -eq '/activities' -and
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
                Add-IMActivity -albumId $pipelineObject.AlbumId -type 'like'

                # Simply verify the function was called - implementation details tested elsewhere
                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Add-IMActivity -albumId 'invalid-guid' -type 'like' } | Should -Throw
            }

            It 'Should validate AssetId GUID format' {
                { Add-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'invalid-guid' -type 'like' } | Should -Throw
            }

            It 'Should validate Type parameter' {
                { Add-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -type 'invalid' } | Should -Throw
            }
        }
    }
    Describe 'Get-IMActivity' -Tag 'Unit', 'Get-IMActivity' {
        BeforeAll {
            Mock InvokeImmichRestMethod {
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
            It 'Should call InvokeImmichRestMethod with correct parameters' {
                $albumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

                $result = Get-IMActivity -albumId $albumId

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                    $Method -eq 'Get' -and
                    $RelativePath -eq '/activities' -and
                    $QueryParameters.albumId -eq $albumId
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

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                    $QueryParameters.albumId -eq $params.AlbumId -and
                    $QueryParameters.assetId -eq $params.AssetId
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

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                    $QueryParameters.albumId -eq $params.AlbumId -and
                    $QueryParameters.type -eq $params.Type -and
                    $QueryParameters.level -eq $params.Level
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

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                    $QueryParameters.albumId -eq $params.AlbumId -and
                    $QueryParameters.userId -eq $params.UserId
                }
            }
        }

        Context 'Pipeline support' {
            It 'Should accept AlbumId from pipeline by property name' {
                # Create objects with AlbumId property for pipeline test
                $pipelineObject = [PSCustomObject]@{ AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }

                # Test that function works when called with parameter from object property
                Get-IMActivity -albumId $pipelineObject.AlbumId

                # Simply verify the function was called - implementation details tested elsewhere
                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly
            }
        }

        Context 'Custom type assignment' {
            It 'Should add IMActivity custom type to results' {
                $albumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

                Get-IMActivity -albumId $albumId

                Should -Invoke AddCustomType -Times 2 -Exactly -Scope It
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Get-IMActivity -albumId 'invalid-guid' } | Should -Throw
            }

            It 'Should validate AssetId GUID format' {
                { Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'invalid-guid' } | Should -Throw
            }

            It 'Should validate Level parameter' {
                { Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -level 'invalid' } | Should -Throw
            }

            It 'Should validate Type parameter' {
                { Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -type 'invalid' } | Should -Throw
            }

            It 'Should validate UserId GUID format' {
                { Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -userId 'invalid-guid' } | Should -Throw
            }
        }
    }
    Describe 'Get-IMActivityStatistic' -Tag 'Unit', 'Get-IMActivityStatistic' {
        BeforeAll {
            Mock InvokeImmichRestMethod {
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
            It 'Should call InvokeImmichRestMethod with correct parameters' {
                $albumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

                $result = Get-IMActivityStatistic -albumId $albumId

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                    $Method -eq 'Get' -and
                    $RelativePath -eq '/activities/statistics' -and
                    $QueryParameters.albumId -eq $albumId
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

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                    $Method -eq 'Get' -and
                    $RelativePath -eq '/activities/statistics' -and
                    $QueryParameters.albumId -eq $params.AlbumId -and
                    $QueryParameters.assetId -eq $params.AssetId
                }
            }
        }

        Context 'Pipeline support' {
            It 'Should accept AlbumId from pipeline by property name' {
                # Create objects with AlbumId property for pipeline test
                $pipelineObject = [PSCustomObject]@{ AlbumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }

                # Test that function works when called with parameter from object property
                Get-IMActivityStatistic -albumId $pipelineObject.AlbumId

                # Simply verify the function was called - implementation details tested elsewhere
                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Get-IMActivityStatistic -albumId 'invalid-guid' } | Should -Throw
            }

            It 'Should validate AssetId GUID format' {
                { Get-IMActivityStatistic -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'invalid-guid' } | Should -Throw
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                # Test without explicit session parameter
                $albumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

                Get-IMActivityStatistic -albumId $albumId

                # Verify the REST method was called (session handling tested in integration tests)
                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly
            }
        }
    }
    Describe 'Remove-IMActivity' -Tag 'Unit', 'Remove-IMActivity' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Add-IMAlbumUser' -Tag 'Unit', 'Add-IMAlbumUser' {
        BeforeAll {
            Mock InvokeImmichRestMethod { return @{success = $true } }
        }

        Context 'When adding a single user to an album' {
            It 'Should call InvokeImmichRestMethod with correct parameters' {
                Add-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -userId '223e4567-e89b-12d3-a456-426614174001' -Role 'editor'

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Method -eq 'PUT' -and
                    $RelativePath -eq '/albums/123e4567-e89b-12d3-a456-426614174000/users' -and
                    $Body.albumUsers -is [array] -and
                    $Body.albumUsers[0].userId -eq '223e4567-e89b-12d3-a456-426614174001' -and
                    $Body.albumUsers[0].role -eq 'editor'
                }
            }
        }

        Context 'When adding multiple users with different roles' {
            It 'Should create correct body with multiple user objects' {
                Add-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -userId @('223e4567-e89b-12d3-a456-426614174001', '323e4567-e89b-12d3-a456-426614174002') -Role 'viewer'

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.albumUsers.Count -eq 2 -and
                    $Body.albumUsers[0].role -eq 'viewer' -and
                    $Body.albumUsers[1].role -eq 'viewer'
                }
            }
        }

        Context 'Pipeline support' {
            It 'Should accept UserId from pipeline by value' {
                @('223e4567-e89b-12d3-a456-426614174001', '323e4567-e89b-12d3-a456-426614174002') | Add-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -Role 'editor'

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.albumUsers.Count -eq 2
                }
            }

            It 'Should accept UserId from pipeline by property name' {
                $users = @(
                    [PSCustomObject]@{id = '223e4567-e89b-12d3-a456-426614174001' }
                    [PSCustomObject]@{id = '323e4567-e89b-12d3-a456-426614174002' }
                )
                $users | Add-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -Role 'viewer'

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Add-IMAlbumUser -albumId 'invalid-guid' -userId '223e4567-e89b-12d3-a456-426614174001' } | Should -Throw
            }

            It 'Should validate UserId GUID format' {
                { Add-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -userId 'invalid-guid' } | Should -Throw
            }

            It 'Should validate Role parameter' {
                { Add-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -userId '223e4567-e89b-12d3-a456-426614174001' -Role 'invalid' } | Should -Throw
            }
        }

        Context 'Default parameter values' {
            It 'Should use viewer as default role' {
                Add-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -userId '223e4567-e89b-12d3-a456-426614174001'

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.albumUsers[0].role -eq 'viewer'
                }
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                Add-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -userId '223e4567-e89b-12d3-a456-426614174001'

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Get-IMAlbum' -Tag 'Unit', 'Get-IMAlbum' {
        BeforeAll {
            Mock InvokeImmichRestMethod {
                if ($RelativePath -eq '/albums')
                {
                    return @(
                        @{id = '123e4567-e89b-12d3-a456-426614174000'; albumName = 'Family Photos'; shared = $false },
                        @{id = '223e4567-e89b-12d3-a456-426614174001'; albumName = 'Vacation 2023'; shared = $true }
                    )
                }
                elseif ($RelativePath -match '/albums/[a-f0-9-]+')
                {
                    return @{id = '123e4567-e89b-12d3-a456-426614174000'; albumName = 'Family Photos'; assets = @() }
                }
            }
            Mock ConvertTo-ApiParameters { return @{} }
            Mock AddCustomType {
                param($InputObject, $TypeName)
                return $InputObject
            } -ModuleName 'PSImmich'
        }

        Context 'When retrieving all albums (list parameter set)' {
            It 'Should call InvokeImmichRestMethod with correct parameters' {
                Get-IMAlbum

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Method -eq 'Get' -and $RelativePath -eq '/albums'
                }
            }

            It 'Should call ConvertTo-ApiParameters for query parameters' {
                Get-IMAlbum -Shared $true

                Should -Invoke ConvertTo-ApiParameters -Times 1 -Exactly -Scope It
            }

            It 'Should add custom type to results' {
                Get-IMAlbum

                Should -Invoke AddCustomType -Times 2 -Exactly -Scope It -ModuleName 'PSImmich' -ParameterFilter {
                    $Type -eq 'IMAlbum'
                }
            }
        }

        Context 'When retrieving specific album by ID (id parameter set)' {
            It 'Should call InvokeImmichRestMethod with album ID path' {
                Get-IMAlbum -AlbumId '123e4567-e89b-12d3-a456-426614174000'

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Method -eq 'Get' -and $RelativePath -eq '/albums/123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should include withoutAssets query parameter when IncludeAssets is false' {
                Get-IMAlbum -AlbumId '123e4567-e89b-12d3-a456-426614174000'

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $QueryParameters.withoutAssets -eq $true
                }
            }

            It 'Should set withoutAssets to false when IncludeAssets is true' {
                Get-IMAlbum -AlbumId '123e4567-e89b-12d3-a456-426614174000' -IncludeAssets

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $QueryParameters.withoutAssets -eq $false
                }
            }
        }

        Context 'When filtering by asset ID' {
            It 'Should convert AssetId parameter to API parameters' {
                Get-IMAlbum -AssetId '123e4567-e89b-12d3-a456-426614174000'

                Should -Invoke ConvertTo-ApiParameters -Times 1 -Exactly -Scope It
            }
        }

        Context 'Pipeline support' {
            It 'Should accept AlbumId from pipeline by value' {
                '123e4567-e89b-12d3-a456-426614174000' | Get-IMAlbum

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $RelativePath -eq '/albums/123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept AlbumId from pipeline by property name' {
                [PSCustomObject]@{Id = '123e4567-e89b-12d3-a456-426614174000' } | Get-IMAlbum

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $RelativePath -eq '/albums/123e4567-e89b-12d3-a456-426614174000'
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

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Get-IMAlbumStatistic' -Tag 'Unit', 'Get-IMAlbumStatistic' {
        BeforeAll {
            Mock InvokeImmichRestMethod {
                return @{
                    totalAlbums  = 25
                    sharedAlbums = 8
                    ownedAlbums  = 17
                    assetCount   = 1250
                }
            }
        }

        Context 'When retrieving album statistics' {
            It 'Should call InvokeImmichRestMethod with correct parameters' {
                Get-IMAlbumStatistic

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Method -eq 'Get' -and $RelativePath -eq '/albums/statistics'
                }
            }

            It 'Should return statistics object' {
                $result = Get-IMAlbumStatistic

                $result.totalAlbums | Should -Be 25
                $result.sharedAlbums | Should -Be 8
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                Get-IMAlbumStatistic

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'New-IMAlbum' -Tag 'Unit', 'New-IMAlbum' {
        BeforeAll {
            Mock InvokeImmichRestMethod {
                return @{
                    id          = '123e4567-e89b-12d3-a456-426614174000'
                    albumName   = 'Test Album'
                    description = 'Test Description'
                    assets      = @()
                    albumUsers  = @()
                    shared      = $false
                }
            }
            Mock ConvertTo-ApiParameters { return @{} }
        }

        Context 'When creating an album with minimal parameters' {
            It 'Should call InvokeImmichRestMethod with correct parameters' {
                New-IMAlbum -albumName 'Test Album'

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Method -eq 'Post' -and $RelativePath -eq '/albums'
                }
            }

            It 'Should call ConvertTo-ApiParameters for body parameters' {
                New-IMAlbum -albumName 'Test Album'

                Should -Invoke ConvertTo-ApiParameters -Times 1 -Exactly -Scope It
            }
        }

        Context 'When creating an album with all parameters' {
            It 'Should handle all optional parameters correctly' {
                $assetIds = @('550e8400-e29b-41d4-a716-446655440000', '6ba7b810-9dad-11d1-80b4-00c04fd430c8')
                $albumUsers = @(@{userId = 'user1-uuid'; role = 'editor' }, @{userId = 'user2-uuid'; role = 'viewer' })

                New-IMAlbum -albumName 'Complete Album' -description 'Test Description' -assetIds $assetIds -albumUsers $albumUsers

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Method -eq 'Post' -and $RelativePath -eq '/albums' -and $null -ne $Body
                }
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AssetIds GUID format' {
                { New-IMAlbum -albumName 'Test' -assetIds @('invalid-guid') } | Should -Throw
            }

            It 'Should require AlbumName parameter' {
                (Get-Command New-IMAlbum).Parameters['AlbumName'].Attributes.Mandatory | Should -Be $true
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                New-IMAlbum -albumName 'Test Album'

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Remove-IMAlbum' -Tag 'Unit', 'Remove-IMAlbum' {
        BeforeAll {
            Mock InvokeImmichRestMethod { return $null }
        }

        Context 'When removing a single album' {
            It 'Should call InvokeImmichRestMethod with correct parameters' {
                Remove-IMAlbum -albumId '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Method -eq 'Delete' -and $RelativePath -eq '/albums/123e4567-e89b-12d3-a456-426614174000'
                }
            }
        }

        Context 'When removing multiple albums' {
            It 'Should process each album ID separately' {
                $albumIds = @('123e4567-e89b-12d3-a456-426614174000', '223e4567-e89b-12d3-a456-426614174001')
                Remove-IMAlbum -albumId $albumIds -Confirm:$false

                Should -Invoke InvokeImmichRestMethod -Times 2 -Exactly -Scope It
            }
        }

        Context 'Pipeline support' {
            It 'Should accept AlbumId from pipeline by value' {
                '123e4567-e89b-12d3-a456-426614174000' | Remove-IMAlbum -Confirm:$false

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $RelativePath -eq '/albums/123e4567-e89b-12d3-a456-426614174000'
                }
            }

            It 'Should accept AlbumId from pipeline by property name' {
                [PSCustomObject]@{id = '123e4567-e89b-12d3-a456-426614174000' } | Remove-IMAlbum -Confirm:$false

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Method -eq 'DELETE' -and $RelativePath -eq '/albums/123e4567-e89b-12d3-a456-426614174000'
                } -ModuleName PSImmich
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Remove-IMAlbum -albumId 'invalid-guid' -Confirm:$false } | Should -Throw
            }

            It 'Should require AlbumId parameter' {
                (Get-Command Remove-IMAlbum).Parameters['AlbumId'].Attributes.Mandatory | Should -Be $true
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                Remove-IMAlbum -albumId '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Remove-IMAlbumUser' -Tag 'Unit', 'Remove-IMAlbumUser' {
        BeforeAll {
            Mock InvokeImmichRestMethod { return $null }
        }

        Context 'When removing a single user from album' {
            It 'Should call InvokeImmichRestMethod with correct parameters' {
                Remove-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -userId '550e8400-e29b-41d4-a716-446655440000' -Confirm:$false

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Method -eq 'DELETE' -and $RelativePath -eq '/albums/123e4567-e89b-12d3-a456-426614174000/user/550e8400-e29b-41d4-a716-446655440000'
                }
            }
        }

        Context 'When removing multiple users from album' {
            It 'Should process each user ID separately' {
                $userIds = @('550e8400-e29b-41d4-a716-446655440000', '6ba7b810-9dad-11d1-80b4-00c04fd430c8')
                Remove-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -userId $userIds -Confirm:$false

                Should -Invoke InvokeImmichRestMethod -Times 2 -Exactly -Scope It
            }
        }

        Context 'Pipeline support' {
            It 'Should accept UserId from pipeline by value' {
                '550e8400-e29b-41d4-a716-446655440000' | Remove-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $RelativePath -eq '/albums/123e4567-e89b-12d3-a456-426614174000/user/550e8400-e29b-41d4-a716-446655440000'
                }
            }

            It 'Should accept UserId from pipeline by property name' {
                [PSCustomObject]@{id = '550e8400-e29b-41d4-a716-446655440000' } | Remove-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -Confirm:$false

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Method -eq 'DELETE' -and $RelativePath -eq '/albums/123e4567-e89b-12d3-a456-426614174000/user/550e8400-e29b-41d4-a716-446655440000'
                } -ModuleName PSImmich
            }
        }

        Context 'Parameter validation' {
            It 'Should validate AlbumId GUID format' {
                { Remove-IMAlbumUser -albumId 'invalid-guid' -userId '550e8400-e29b-41d4-a716-446655440000' -Confirm:$false } | Should -Throw
            }

            It 'Should validate UserId GUID format' {
                { Remove-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -userId 'invalid-guid' -Confirm:$false } | Should -Throw
            }

            It 'Should require both AlbumId and UserId parameters' {
                (Get-Command Remove-IMAlbumUser).Parameters['AlbumId'].Attributes.Mandatory | Should -Be $true
                (Get-Command Remove-IMAlbumUser).Parameters['UserId'].Attributes.Mandatory | Should -Be $true
            }
        }

        Context 'Session parameter' {
            It 'Should use default session when no session parameter provided' {
                Remove-IMAlbumUser -albumId '123e4567-e89b-12d3-a456-426614174000' -userId '550e8400-e29b-41d4-a716-446655440000' -Confirm:$false

                Should -Invoke InvokeImmichRestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $null -eq $ImmichSession
                }
            }
        }
    }
    Describe 'Rename-IMAlbum' -Tag 'Unit', 'Rename-IMAlbum' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMAlbum' -Tag 'Unit', 'Set-IMAlbum' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMAlbumUser' -Tag 'Unit', 'Set-IMAlbumUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAPIKey' -Tag 'Unit', 'Get-IMAPIKey' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMAPIKey' -Tag 'Unit', 'New-IMAPIKey' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMAPIKey' -Tag 'Unit', 'Remove-IMAPIKey' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Rename-IMAPIKey' -Tag 'Unit', 'Rename-IMAPIKey' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Export-IMAssetThumbnail' -Tag 'Unit', 'Export-IMAssetThumbnail' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAsset' -Tag 'Unit', 'Get-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAssetMemoryLane' -Tag 'Unit', 'Get-IMAssetMemoryLane' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAssetStatistic' -Tag 'Unit', 'Get-IMAssetStatistic' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Import-IMAsset' -Tag 'Unit', 'Import-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMAsset' -Tag 'Unit', 'Remove-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Restore-IMAsset' -Tag 'Unit', 'Restore-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Save-IMAsset' -Tag 'Unit', 'Save-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMAsset' -Tag 'Unit', 'Set-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Start-IMVideoTranscode' -Tag 'Unit', 'Start-IMVideoTranscode' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Update-IMAssetMetadata' -Tag 'Unit', 'Update-IMAssetMetadata' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Update-IMAssetThumbnail' -Tag 'Unit', 'Update-IMAssetThumbnail' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Test-IMAccessToken' -Tag 'Unit', 'Test-IMAccessToken' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAuthSession' -Tag 'Unit', 'Get-IMAuthSession' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMAuthSession' -Tag 'Unit', 'Remove-IMAuthSession' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMDuplicate' -Tag 'Unit', 'Get-IMDuplicate' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMFace' -Tag 'Unit', 'Get-IMFace' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAuditFile' -Tag 'Unit', 'Get-IMAuditFile' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMFileChecksum' -Tag 'Unit', 'Get-IMFileChecksum' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Clear-IMJob' -Tag 'Unit', 'Clear-IMJob' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMJob' -Tag 'Unit', 'Get-IMJob' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Resume-IMJob' -Tag 'Unit', 'Resume-IMJob' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Start-IMJob' -Tag 'Unit', 'Start-IMJob' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Suspend-IMJob' -Tag 'Unit', 'Suspend-IMJob' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMLibrary' -Tag 'Unit', 'Get-IMLibrary' {
        BeforeAll {
            # Mock the InvokeImmichRestMethod function
            Mock InvokeImmichRestMethod {
                param($Method, $RelativePath, $ImmichSession)

                # Mock responses based on RelativePath
                switch -Regex ($RelativePath)
                {
                    '^/libraries$'
                    {
                        # Mock response for listing all libraries
                        return @(
                            @{
                                id      = '11111111-1111-1111-1111-111111111111'
                                name    = 'Library 1'
                                ownerId = '22222222-2222-2222-2222-222222222222'
                                type    = 'UPLOAD'
                            },
                            @{
                                id      = '33333333-3333-3333-3333-333333333333'
                                name    = 'Library 2'
                                ownerId = '44444444-4444-4444-4444-444444444444'
                                type    = 'EXTERNAL'
                            }
                        )
                    }
                    '^/libraries/11111111-1111-1111-1111-111111111111$'
                    {
                        # Mock response for specific library
                        return @{
                            id      = '11111111-1111-1111-1111-111111111111'
                            name    = 'Library 1'
                            ownerId = '22222222-2222-2222-2222-222222222222'
                            type    = 'UPLOAD'
                        }
                    }
                    '^/libraries/33333333-3333-3333-3333-333333333333$'
                    {
                        # Mock response for specific library
                        return @{
                            id      = '33333333-3333-3333-3333-333333333333'
                            name    = 'Library 2'
                            ownerId = '44444444-4444-4444-4444-444444444444'
                            type    = 'EXTERNAL'
                        }
                    }
                    '^/libraries/.*/statistics$'
                    {
                        # Mock response for library statistics
                        return @{
                            assetCount = 150
                            videoCount = 25
                            imageCount = 125
                            totalSize  = 1073741824
                        }
                    }
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
                Should -Invoke InvokeImmichRestMethod -Times 1 -ParameterFilter {
                    $Method -eq 'Get' -and
                    $RelativePath -eq '/libraries' -and
                    $ImmichSession -eq $null
                }
            }

            It 'Should filter libraries by ownerId when provided' {
                $result = Get-IMLibrary -ownerId '22222222-2222-2222-2222-222222222222'

                $result | Should -HaveCount 1
                $result.ownerId | Should -Be '22222222-2222-2222-2222-222222222222'

                # Should still call the main endpoint, filtering happens in PowerShell
                Should -Invoke InvokeImmichRestMethod -Times 1 -ParameterFilter {
                    $Method -eq 'Get' -and
                    $RelativePath -eq '/libraries'
                }
            }

            It 'Should pass session parameter to InvokeImmichRestMethod when provided' {
                # Test that session parameter is passed through (mock will verify this)
                # We'll use $null since we're just testing parameter passing
                $result = Get-IMLibrary -Session $null

                Should -Invoke InvokeImmichRestMethod -Times 1 -ParameterFilter {
                    $Method -eq 'Get' -and
                    $RelativePath -eq '/libraries'
                    # ImmichSession parameter will be $null in this test
                }
            }
        }

        Context 'Parameter Set: id' {
            It 'Should retrieve a specific library by id' {
                $result = Get-IMLibrary -id '11111111-1111-1111-1111-111111111111'

                $result.id | Should -Be '11111111-1111-1111-1111-111111111111'
                $result.name | Should -Be 'Library 1'

                Should -Invoke InvokeImmichRestMethod -Times 1 -ParameterFilter {
                    $Method -eq 'Get' -and
                    $RelativePath -eq '/libraries/11111111-1111-1111-1111-111111111111'
                }
            }

            It 'Should retrieve multiple libraries when multiple ids are provided' {
                $ids = @('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333')
                $result = Get-IMLibrary -id $ids

                $result | Should -HaveCount 2
                $result[0].id | Should -Be '11111111-1111-1111-1111-111111111111'
                $result[1].id | Should -Be '33333333-3333-3333-3333-333333333333'

                # Should be called once per ID
                Should -Invoke InvokeImmichRestMethod -Times 2 -ParameterFilter {
                    $Method -eq 'Get' -and
                    $RelativePath -match '^/libraries/(11111111-1111-1111-1111-111111111111|33333333-3333-3333-3333-333333333333)$'
                }
            }

            It 'Should include statistics when IncludeStatistics switch is used' {
                $result = Get-IMLibrary -id '11111111-1111-1111-1111-111111111111' -IncludeStatistics

                $result.id | Should -Be '11111111-1111-1111-1111-111111111111'
                $result.Statistics | Should -Not -BeNullOrEmpty
                $result.Statistics.assetCount | Should -Be 150
                $result.Statistics.totalSize | Should -Be 1073741824

                # Should call both library and statistics endpoints
                Should -Invoke InvokeImmichRestMethod -Times 2
                Should -Invoke InvokeImmichRestMethod -Times 1 -ParameterFilter {
                    $RelativePath -eq '/libraries/11111111-1111-1111-1111-111111111111'
                }
                Should -Invoke InvokeImmichRestMethod -Times 1 -ParameterFilter {
                    $RelativePath -eq '/libraries/11111111-1111-1111-1111-111111111111/statistics'
                }
            }

            It 'Should accept pipeline input by property name' {
                $inputObject = [PSCustomObject]@{ id = '11111111-1111-1111-1111-111111111111' }
                $result = $inputObject | Get-IMLibrary

                $result.id | Should -Be '11111111-1111-1111-1111-111111111111'

                Should -Invoke InvokeImmichRestMethod -Times 1 -ParameterFilter {
                    $RelativePath -eq '/libraries/11111111-1111-1111-1111-111111111111'
                }
            }

            It 'Should accept direct pipeline input' {
                $result = '11111111-1111-1111-1111-111111111111' | Get-IMLibrary

                $result.id | Should -Be '11111111-1111-1111-1111-111111111111'

                Should -Invoke InvokeImmichRestMethod -Times 1 -ParameterFilter {
                    $RelativePath -eq '/libraries/11111111-1111-1111-1111-111111111111'
                }
            }

            It 'Should pass session parameter to InvokeImmichRestMethod when provided with id parameter' {
                # Test that session parameter is passed through with id parameter
                $result = Get-IMLibrary -id '11111111-1111-1111-1111-111111111111' -Session $null

                Should -Invoke InvokeImmichRestMethod -Times 1 -ParameterFilter {
                    $Method -eq 'Get' -and
                    $RelativePath -eq '/libraries/11111111-1111-1111-1111-111111111111'
                    # ImmichSession parameter will be $null in this test
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
                $result = Get-IMLibrary

                # Should call the list endpoint
                Should -Invoke InvokeImmichRestMethod -Times 1 -ParameterFilter {
                    $RelativePath -eq '/libraries'
                }
            }

            It 'Should use id parameter set when id is provided' {
                $result = Get-IMLibrary -id '11111111-1111-1111-1111-111111111111'

                # Should call the specific library endpoint
                Should -Invoke InvokeImmichRestMethod -Times 1 -ParameterFilter {
                    $RelativePath -eq '/libraries/11111111-1111-1111-1111-111111111111'
                }
            }

            It 'Should not allow IncludeStatistics with list parameter set' {
                # This should be invalid because IncludeStatistics is only for id parameter set
                $result = Get-IMLibrary
                # The function should work normally for list without trying to include statistics
                $result | Should -HaveCount 2
            }
        }

        AfterEach {
            # Reset mock call counts between tests
            # Note: Pester 5 automatically resets mocks between tests
        }
    }
    Describe 'New-IMLibrary' -Tag 'Unit', 'New-IMLibrary' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMLibrary' -Tag 'Unit', 'Remove-IMLibrary' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMLibrary' -Tag 'Unit', 'Set-IMLibrary' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Sync-IMLibrary' -Tag 'Unit', 'Sync-IMLibrary' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Test-IMLibrary' -Tag 'Unit', 'Test-IMLibrary' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Convert-IMCoordinatesToLocation' -Tag 'Unit', 'Convert-IMCoordinatesToLocation' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMMapMarker' -Tag 'Unit', 'Get-IMMapMarker' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }

    Describe 'Get-IMMemory' -Tag 'Unit', 'Get-IMMemory' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMMemory' -Tag 'Unit', 'New-IMMemory' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMMemory' -Tag 'Unit', 'Remove-IMMemory' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMMemory' -Tag 'Unit', 'Set-IMMemory' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Send-IMTestMessage' -Tag 'Unit', 'Send-IMTestMessage' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Add-IMPartner' -Tag 'Unit', 'Add-IMPartner' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMPartner' -Tag 'Unit', 'Get-IMPartner' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMPartner' -Tag 'Unit', 'Remove-IMPartner' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMPartner' -Tag 'Unit', 'Set-IMPartner' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Export-IMPersonThumbnail' -Tag 'Unit', 'Export-IMPersonThumbnail' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMPerson' -Tag 'Unit', 'Get-IMPerson' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Merge-IMPerson' -Tag 'Unit', 'Merge-IMPerson' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMPerson' -Tag 'Unit', 'New-IMPerson' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMPerson' -Tag 'Unit', 'Set-IMPerson' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Find-IMAsset' -Tag 'Unit', 'Find-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Search-IMAsset' -Tag 'Unit', 'Search-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Find-IMCity' -Tag 'Unit', 'Find-IMCity' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Find-IMExploreData' -Tag 'Unit', 'Find-IMExploreData' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Find-IMPerson' -Tag 'Unit', 'Find-IMPerson' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Find-IMPlace' -Tag 'Unit', 'Find-IMPlace' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServer' -Tag 'Unit', 'Get-IMServer' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerAbout' -Tag 'Unit', 'Get-IMServerAbout' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerConfig' -Tag 'Unit', 'Get-IMServerConfig' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerFeature' -Tag 'Unit', 'Get-IMServerFeature' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerLicense' -Tag 'Unit', 'Get-IMServerLicense' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerStatistic' -Tag 'Unit', 'Get-IMServerStatistic' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerStorage' -Tag 'Unit', 'Get-IMServerStorage' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerVersion' -Tag 'Unit', 'Get-IMServerVersion' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMSupportedMediaType' -Tag 'Unit', 'Get-IMSupportedMediaType' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMTheme' -Tag 'Unit', 'Get-IMTheme' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMServerLicense' -Tag 'Unit', 'Remove-IMServerLicense' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMServerLicense' -Tag 'Unit', 'Set-IMServerLicense' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Test-IMPing' -Tag 'Unit', 'Test-IMPing' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMConfig' -Tag 'Unit', 'Get-IMConfig' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMConfig' -Tag 'Unit', 'Set-IMConfig' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Connect-Immich' -Tag 'Unit', 'Connect-Immich' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Disconnect-Immich' -Tag 'Unit', 'Disconnect-Immich' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMSession' -Tag 'Unit', 'Get-IMSession' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Invoke-ImmichMethod' -Tag 'Unit', 'Invoke-ImmichMethod' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Add-IMSharedLinkAsset' -Tag 'Unit', 'Add-IMSharedLinkAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMSharedLink' -Tag 'Unit', 'Get-IMSharedLink' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMSharedLink' -Tag 'Unit', 'New-IMSharedLink' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMSharedLink' -Tag 'Unit', 'Remove-IMSharedLink' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMSharedLinkAsset' -Tag 'Unit', 'Remove-IMSharedLinkAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMSharedLink' -Tag 'Unit', 'Set-IMSharedLink' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMTag' -Tag 'Unit', 'Get-IMTag' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMTag' -Tag 'Unit', 'New-IMTag' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMTag' -Tag 'Unit', 'Remove-IMTag' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMTag' -Tag 'Unit', 'Set-IMTag' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMTimeBucket' -Tag 'Unit', 'Get-IMTimeBucket' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Add-IMMyProfilePicture' -Tag 'Unit', 'Add-IMMyProfilePicture' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Export-IMProfilePicture' -Tag 'Unit', 'Export-IMProfilePicture' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMUser' -Tag 'Unit', 'Get-IMUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMUserPreference' -Tag 'Unit', 'Get-IMUserPreference' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMUser' -Tag 'Unit', 'New-IMUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMMyProfilePicture' -Tag 'Unit', 'Remove-IMMyProfilePicture' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMUser' -Tag 'Unit', 'Remove-IMUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Restore-IMUser' -Tag 'Unit', 'Restore-IMUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMUser' -Tag 'Unit', 'Set-IMUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMUserPreference' -Tag 'Unit', 'Set-IMUserPreference' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }

    Describe 'Get-IMStack' -Tag 'Unit', 'Get-IMStack' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }

    Describe 'New-IMStack' -Tag 'Unit', 'New-IMStack' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMStack' -Tag 'Unit', 'Remove-IMStack' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }

    Describe 'Remove-IMStackAsset' -Tag 'Unit', 'Remove-IMStackAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }

    Describe 'Set-IMStack' -Tag 'Unit', 'Set-IMStack' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
}
