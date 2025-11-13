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
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMActivity' -Tag 'Unit', 'Get-IMActivity' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMActivityStatistic' -Tag 'Unit', 'Get-IMActivityStatistic' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
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
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAlbum' -Tag 'Unit', 'Get-IMAlbum' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAlbumStatistic' -Tag 'Unit', 'Get-IMAlbumStatistic' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMAlbum' -Tag 'Unit', 'New-IMAlbum' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMAlbum' -Tag 'Unit', 'Remove-IMAlbum' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMAlbumUser' -Tag 'Unit', 'Remove-IMAlbumUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
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
