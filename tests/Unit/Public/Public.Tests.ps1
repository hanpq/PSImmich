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
    Describe 'Add-IMActivity' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMActivity' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMActivityStatistic' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMActivity' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Add-IMAlbumUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAlbum' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAlbumStatistic' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMAlbum' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMAlbum' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMAlbumUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Rename-IMAlbum' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMAlbum' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMAlbumUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAPIKey' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMAPIKey' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMAPIKey' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Rename-IMAPIKey' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Export-IMAssetThumbnail' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAssetMemoryLane' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAssetStatistic' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Import-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Restore-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Save-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Start-IMVideoTranscode' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Update-IMAssetMetadata' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Update-IMAssetThumbnail' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Test-IMAccessToken' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAuthSession' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMAuthSession' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMDuplicate' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMFace' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMAuditFile' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMFileChecksum' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Clear-IMJob' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMJob' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Resume-IMJob' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Start-IMJob' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Suspend-IMJob' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMLibrary' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMLibrary' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMLibrary' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMLibrary' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Sync-IMLibrary' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Test-IMLibrary' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Convert-IMCoordinatesToLocation' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMMapMarker' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMMapStyle' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMMemory' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMMemory' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMMemory' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMMemory' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Send-IMTestMessage' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Add-IMPartner' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMPartner' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMPartner' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMPartner' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Export-IMPersonThumbnail' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMPerson' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Merge-IMPerson' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMPerson' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMPerson' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Find-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Search-IMAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Find-IMCity' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Find-IMExploreData' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Find-IMPerson' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Find-IMPlace' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServer' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerAbout' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerConfig' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerFeature' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerLicense' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerStatistic' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerStorage' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMServerVersion' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMSupportedMediaType' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMTheme' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMServerLicense' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMServerLicense' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Test-IMPing' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMConfig' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMConfig' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Connect-Immich' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Disconnect-Immich' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMSession' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Invoke-ImmichMethod' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Add-IMSharedLinkAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMSharedLink' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMSharedLink' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMSharedLink' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMSharedLinkAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMSharedLink' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMTag' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMTag' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMTag' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMTag' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMTimeBucket' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Add-IMMyProfilePicture' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Export-IMProfilePicture' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Get-IMUserPreference' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'New-IMUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMMyProfilePicture' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Restore-IMUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMUser' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Set-IMUserPreference' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }

    Describe 'Get-IMStack' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }

    Describe 'New-IMStack' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'Remove-IMStack' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }

    Describe 'Remove-IMStackAsset' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }

    Describe 'Set-IMStack' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
}
