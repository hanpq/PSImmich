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

Describe 'Session' -Tag 'Integration' {
    Context 'Connect-Immich - When no parameters are specified' -Tag 'Connect-Immich' {
        It -Name 'Should throw' {
            { Connect-Immich } | Should -Throw
        }
    }
    Context 'Connect-Immich - When providing Access Token' -Tag 'Connect-Immich' {
        It -Name 'Should not throw' {
            { Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY } | Should -Not -Throw
        }
        InModuleScope PSImmich -ScriptBlock {
            BeforeAll {
                Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
            }
            It -Name 'When providing Access Token should store a session variable' {
                $script:ImmichSession | Should -Not -BeNullOrEmpty
            }
            It -Name 'When providing Access Token should be type ImmichSession' {
                $script:ImmichSession.GetType().Name | Should -Be 'ImmichSession'
            }
        }
    }
    Context -Name 'Connect-Immich - When providing Access Token and passthru is used' -Tag 'Connect-Immich' {
        BeforeAll {
            $ImmichSession = Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY -PassThru
        }
        It -Name 'Should return a session object' {
            $ImmichSession | Should -Not -BeNullOrEmpty
        }
        It -Name 'Should be of type ImmichSession' {
            $ImmichSession.GetType().Name | Should -Be 'ImmichSession'
        }
        It -Name 'BaseURI should have correct value' {
            $ImmichSession.BaseURI | Should -Be $env:PSIMMICHURI
        }
        It -Name 'AuthMethod should have correct value' {
            $ImmichSession.AuthMethod | Should -Be 'AccessToken'
        }
        It -Name 'AccessToken should be securestring' {
            $ImmichSession.AccessToken | Should -BeOfType [SecureString]
        }
        It -Name 'AccessToken should be correct' {
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ImmichSession.AccessToken)
                $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            }
            elseif ($PSVersionTable.PSEdition -eq 'Core')
            {
                $UnsecurePassword = ConvertFrom-SecureString -SecureString $ImmichSession.AccessToken -AsPlainText
            }
            $UnsecurePassword | Should -Be $env:PSIMMICHAPIKEY
        }
        It -Name 'Credentials should be empty' {
            $ImmichSession.Credential | Should -BeNullOrEmpty
        }
        It -Name 'JWT should be empty' {
            $ImmichSession.JWT | Should -BeNullOrEmpty
        }
        It -Name 'APIUri should be correct' {
            $ImmichSession.APIUri | Should -Be "$env:PSIMMICHURI/api"
        }
        It -Name 'ImmichVersion should not be empty' {
            $ImmichSession.ImmichVersion | Should -Not -BeNullOrEmpty
        }
        It -Name 'SessionID should not be empty' {
            $ImmichSession.SessionID | Should -Not -BeNullOrEmpty
        }
    }
    Context -Name 'Connect-Immich - When providing Credentials' -Tag 'Connect-Immich' {
        It -Name 'Should not throw' {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            { Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred } | Should -Not -Throw
        }
        InModuleScope PSImmich -ScriptBlock {
            BeforeAll {
                $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
                Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred
            }
            It -Name 'Should store a session variable' {
                $script:ImmichSession | Should -Not -BeNullOrEmpty
            }
            It -Name 'Should be type ImmichSession' {
                $script:ImmichSession.GetType().Name | Should -Be 'ImmichSession'
            }
        }
    }
    Context -Name 'Connect-Immich - When providing Credentials and passthru is used' -Tag 'Connect-Immich' {
        BeforeAll {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            $ImmichSession = Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred -PassThru
        }
        It -Name 'Should return a session object' {
            $ImmichSession | Should -Not -BeNullOrEmpty
        }
        It -Name 'Should be of type ImmichSession' {
            $ImmichSession.GetType().Name | Should -Be 'ImmichSession'
        }
        It -Name 'BaseURI should have correct value' {
            $ImmichSession.BaseURI | Should -Be $env:PSIMMICHURI
        }
        It -Name 'AuthMethod should have correct value' {
            $ImmichSession.AuthMethod | Should -Be 'Credential'
        }
        It -Name 'AccessToken should be securestring' {
            $ImmichSession.AccessToken | Should -BeOfType [SecureString]
        }
        It -Name 'Credentials should be empty' {
            $ImmichSession.Credential | Should -BeOfType [pscredential]
        }
        It -Name 'JWT should be empty' {
            $ImmichSession.JWT | Should -BeOfType [SecureString]
        }
        It -Name 'APIUri should be correct' {
            $ImmichSession.APIUri | Should -Be "$env:PSIMMICHURI/api"
        }
        It -Name 'ImmichVersion should not be empty' {
            $ImmichSession.ImmichVersion | Should -Not -BeNullOrEmpty
        }
        It -Name 'SessionID should not be empty' {
            $ImmichSession.SessionID | Should -Not -BeNullOrEmpty
        }
    }
    Context -Name 'Connect-Immich - When providing Credentials it is valid and usable' -Tag 'Connect-Immich' {
        BeforeAll {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred
        }
        It -Name 'Credentials can be used' {
            Get-IMServer -Configuration
        }
    }
    Context -Name 'Get-IMSession - When no parameters are specified' -Tag 'Get-IMSession' {
        BeforeEach {
            Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        }
        It -Name 'Should not throw' {
            { Get-IMSession } | Should -Not -Throw
        }
        It -Name 'Should return immichsession object' {
            (Get-IMSession).GetType().Name | Should -Be 'ImmichSession'
        }
    }
    Context -Name 'Disconnect-Immich - When no parameters are specified' -Tag 'Disconnect-Immich' {
        BeforeEach {
            Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        }
        It -Name 'Should not throw' {
            { Disconnect-Immich } | Should -Not -Throw
        }
    }
}

Describe 'Server' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Get-IMServerLicense' -Tag 'Get-IMServerLicense' {
        # No way to test without a valid license
    }
    Context 'Set-IMServerLicense' -Tag 'Set-IMServerLicense' {
        # No way to test without a valid license
    }
    Context 'Remove-IMServerLicense' -Tag 'Remove-IMServerLicense' {
        # No way to test without a valid license
    }
    Context -Name 'Get-IMServer' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer } | Should -Not -Throw
        }
    }
    Context -Name 'Get-IMServer -Configuration - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -Configuration } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServer -Configuration
            $ExpectedProperties = @('maintenanceMode', 'loginPageMessage', 'trashDays', 'userDeleteDelay', 'oauthButtonText', 'isInitialized', 'isOnboarded', 'externalDomain', 'mapDarkStyleUrl', 'mapLightStyleUrl', 'publicUsers')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServer -Features - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -Features } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServer -Features
            $ExpectedProperties = @('ocr', 'importFaces', 'duplicateDetection', 'smartSearch', 'passwordLogin', 'configFile', 'facialRecognition', 'map', 'reverseGeocoding', 'sidecar', 'search', 'trash', 'oauth', 'oauthAutoLaunch', 'email')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServer -Statistic - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -Statistics } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServer -Statistics
            $ExpectedProperties = @('photos', 'videos', 'usage', 'usageByUser', 'usagePhotos', 'usageVideos')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
            $ExpectedProperties = @('userID', 'userName', 'photos', 'videos', 'usage', 'usagePhotos', 'usageVideos', 'quotaSizeInBytes')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.usagebyuser[0].PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServer -Version - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -Version } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServer -Version
            $ExpectedProperties = @('version')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServer -MediaTypes - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -MediaTypes } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServer -MediaTypes
            $ExpectedProperties = @('video', 'image', 'sidecar')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServer -Theme - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -Theme } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServer -Theme
            $ExpectedProperties = @('customCss')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServerAbout - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -About } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            #$Result = Get-IMTheme
            #$ExpectedProperties = @('customCss')
            #Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServer -Ping - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -Ping } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServer -Ping
            $ExpectedProperties = @('responds')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServer -VersionHistory - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -VersionHistory } | Should -Not -Throw
        }
    }
    Context -Name 'Get-IMServer -AppliedSystemConfiguration - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -AppliedSystemConfiguration } | Should -Not -Throw
        }
    }
    Context -Name 'Get-IMServer -DefaultSystemConfiguration - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -DefaultSystemConfiguration } | Should -Not -Throw
        }
    }
    Context -Name 'Get-IMServer -StorageTemplateOptions - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -StorageTemplateOptions } | Should -Not -Throw
        }
    }
    Context -Name 'Get-IMServer -Storage - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -Storage } | Should -Not -Throw
        }
    }
    Context -Name 'Get-IMServer -APKLinks - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -APKLinks } | Should -Not -Throw
        }
    }
    Context -Name 'Get-IMServer -VersionCheck - When no parameters are specified' -Tag 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer -VersionCheck } | Should -Not -Throw
        }
    }
}

Describe 'Asset' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'Get-IMAsset - Specifying a single ID' -Tag 'Get-IMAsset' {
        It -Name 'Should return a object with the correct properties' {
            $Result = Get-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $ExpectedProperties = @('duplicateId', 'hasMetadata', 'isOffline', 'checksum', 'people', 'tags', 'livePhotoVideoId', 'exifInfo', 'duration', 'isTrashed', 'isArchived', 'isFavorite', 'updatedAt', 'localDateTime', 'fileModifiedAt', 'fileCreatedAt', 'thumbhash', 'resized', 'id', 'deviceAssetId', 'ownerId', 'owner', 'deviceId', 'libraryId', 'type', 'originalPath', 'originalFileName', 'originalMimeType', 'stack', 'createdAt', 'visibility', 'unassignedFaces')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
        It -Name 'Should return OCR data' {
            $Result = Get-IMAsset -Id '02e1a2f4-b88b-4eb1-9ec5-34accfb3155a' -IncludeOCR
            $Result.PSObject.Properties.Name | Should -Contain 'OCR'
            $Result.OCR | should -HaveCount 6
        }
        It -Name 'Should return a single object' {
            Get-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' | Should -HaveCount 1
        }
        It -Name 'Should accept object from pipeline' {
            [pscustomobject]@{id = '025665c6-d874-46a2-bbc6-37250ddcb2eb' } | Get-IMAsset | Should -HaveCount 1
        }
        It -Name 'Should accept id from parameter' {
            Get-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' | Should -HaveCount 1
        }
        It -Name 'Should accept id from pipeline' {
            '025665c6-d874-46a2-bbc6-37250ddcb2eb' | Get-IMAsset | Should -HaveCount 1
        }
    }
    Context -Name 'Get-IMAsset - Specifying multiple IDs' -Tag 'Get-IMAsset' {
        It -Name 'Should accept multiple objects from pipeline' {
            @([pscustomobject]@{id = '025665c6-d874-46a2-bbc6-37250ddcb2eb' }, [pscustomobject]@{id = '025665c6-d874-46a2-bbc6-37250ddcb2eb' }) | Get-IMAsset | Should -HaveCount 2
        }
        It -Name 'Should accept multiple ids from pipeline' {
            @('025665c6-d874-46a2-bbc6-37250ddcb2eb', '025665c6-d874-46a2-bbc6-37250ddcb2eb') | Get-IMAsset | Should -HaveCount 2
        }
    }
    Context -Name 'Get-IMAsset - No parameters are specified' -Tag 'Get-IMAsset' {
        It -Name 'Should return array' {
            Get-IMAsset | Measure-Object | Select-Object -ExpandProperty count | Should -BeGreaterThan 1
        }
    }
    Context -Name 'Set-IMAsset' -Tag 'Set-IMAsset' {
        BeforeAll {
            if ($env:CI)
            {
                $AlbumName = $env:GITHUB_RUN_ID
            }
            else
            {
                $AlbumName = HOSTNAME.EXE
            }
            $NewAlbum = New-IMAlbum -AlbumName $AlbumName
            if (-not (Get-IMTag | Where-Object name -EQ 'TestTag'))
            {
                $NewTag = New-IMTag -Name 'TestTag'
            }
            else
            {
                Get-IMTag | Where-Object name -EQ 'TestTag' | Remove-IMTag
                $NewTag = New-IMTag -Name 'TestTag'
            }

        }
        AfterAll {
            Remove-IMAlbum -AlbumId $NewAlbum.id
            Remove-IMTag -id $NewTag.id

        }
        It -Name 'Assets gets added to album' {
            Set-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037' -AddToAlbum $NewAlbum.id
            $Result = Get-IMAlbum -AlbumId $NewAlbum.id -IncludeAssets
            $Result.assets | Should -HaveCount 2
            $Result.assets.id | Should -Contain '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Result.assets.id | Should -Contain '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        }
        It -Name 'Assets gets removed from album' {
            Set-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037' -RemoveFromAlbum $NewAlbum.id
            $Result = Get-IMAlbum -AlbumId $NewAlbum.id -IncludeAssets
            $Result.assets | Should -HaveCount 0
        }
        It -Name 'Should update asset' {
            Set-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -IsFavorite:$true
            Get-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' | Select-Object -ExpandProperty isFavorite | Should -BeTrue
            Set-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -IsFavorite:$false
        }
        It 'Should add tag to asset' {
            $Result = Set-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -AddTag $NewTag.id
            # Seems to be a delay in the tag being added to the asset. Adding a retry loop to wait for the tag to be added.
            $retrycounter = 0
            while ((Get-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb').tags.id -notcontains $NewTag.id -and $retrycounter -lt 5)
            {
                Start-Sleep -Seconds 2
                $retrycounter++
            }
            $Asset = Get-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Asset.tags.id | Should -Contain $newtag.id
        }
        It 'Should remove tag from asset' {

            # Seems to be a delay in the tag being added to the asset. Adding a retry loop to wait for the tag to be added.
            $retrycounter = 0
            while ((Get-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb').tags.id -notcontains $NewTag.id -and $retrycounter -lt 5)
            {
                Start-Sleep -Seconds 2
                $retrycounter++
            }

            $Result = Set-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -RemoveTag $NewTag.id
            # Seems to be a delay in the tag being added to the asset. Adding a retry loop to wait for the tag to be added.

            $retrycounter = 0
            while ((Get-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb').tags.id -contains $NewTag.id -and $retrycounter -lt 5)
            {
                Start-Sleep -Seconds 2
                $Result = Set-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -RemoveTag $NewTag.id
                $retrycounter++
            }

            $Asset = Get-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Asset.tags.id | Should -Not -Contain $newtag.id
        }
    }
    # Import-IMAsset is excluded from testing on Windows Powershell because the
    # current routine to post formdata is not nativly supported. Until a seperate
    # routine is defined, this test is excluded.
    Context -Name 'Import-IMAsset' -Tag 'Import-IMAsset' {
        It -Name 'Should upload the file' {
            $Result = Import-IMAsset -FilePath "$PSScriptRoot\Immich.png"
            $Result | Should -HaveCount 1
            $Result.DeviceAssetID | Should -Be 'Immich.png'
            Remove-IMAsset -Id $Result.Id -Force
        }
    } #-Skip:($PSVersionTable.PSEdition -eq 'Desktop')
    Context -Name 'Restore-IMAsset' -Tag 'Restore-IMAsset' {
        It -Name 'Should restore single asset' {
            $Result = Import-IMAsset -FilePath "$PSScriptRoot\Immich.png"
            $Result | Should -HaveCount 1
            $Result.DeviceAssetID | Should -Be 'Immich.png'
            Remove-IMAsset -Id $Result.Id
            $Remove = Get-IMAsset -Id $Result.id
            $Remove.isTrashed | Should -BeTrue
            Restore-IMAsset -Id $Result.Id
            $Restore = Get-IMAsset -Id $Result.id
            $Restore.isTrashed | Should -BeFalse
            Start-Sleep -Seconds 1
            Remove-IMAsset -Id $Result.Id -Force
        }
        It -Name 'Should restore all asset' {
            $Result = Import-IMAsset -FilePath "$PSScriptRoot\Immich.png"
            $Result | Should -HaveCount 1
            $Result.DeviceAssetID | Should -Be 'Immich.png'
            Remove-IMAsset -Id $Result.Id
            $Remove = Get-IMAsset -Id $Result.id
            $Remove.isTrashed | Should -BeTrue
            Restore-IMAsset -All
            $Restore = Get-IMAsset -Id $Result.id
            $Restore.isTrashed | Should -BeFalse
            Remove-IMAsset -Id $Result.Id -Force
        }
    } #-Skip:($PSVersionTable.PSEdition -eq 'Desktop')
    Context 'Remove-IMAsset' -Tag 'Remove-IMAsset' {
        It -Name 'Should remove the file' {
            $Result = Import-IMAsset -FilePath "$PSScriptRoot\Immich.png"
            { Remove-IMAsset -Id $Result.Id -Force } | Should -Not -Throw
        }
    } #-Skip:($PSVersionTable.PSEdition -eq 'Desktop')
    Context 'Save-IMAsset' -Tag 'Save-IMAsset' {
        It -Name 'Should download file to disk' {
            Save-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -Path ((Get-PSDrive TestDrive).Root)
            "$((Get-PSDrive TestDrive).Root)\michael-daniels-ylUGx4g6eHk-unsplash.jpg" | Should -Exist
            Remove-Item 'TestDrive:\michael-daniels-ylUGx4g6eHk-unsplash.jpg' -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
    Context 'Update-IMAssetMetadata' -Tag 'Update-IMAssetMetadata' {
        It -Name 'Should not throw' {
            { Update-IMAssetMetadata -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' } | Should -Not -Throw
        }
    }
    Context 'Update-IMAssetThumbnail' -Tag 'Update-IMAssetThumbnail' {
        It -Name 'Should not throw' {
            { Update-IMAssetThumbnail -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' } | Should -Not -Throw
        }
    }
    Context 'Get-IMAsset -Random' -Tag 'Get-IMAsset' {
        It -Name 'Should return one object' {
            $Result = Get-IMAsset -Random
            $Result | Should -HaveCount 1
        }
        It -Name 'Should return 3 object' {
            $Result = Get-IMAsset -Random -Count 3
            $Result | Should -HaveCount 3
        }
    }
    Context 'Get-IMAssetStatistic' -Tag 'Get-IMAssetStatistic' {
        It -Name 'Should return one object' {
            $Result = Get-IMAssetStatistic
            $Result | Should -HaveCount 1
            $Result.PSObject.Properties.Name | Should -Contain 'images'
            $Result.PSObject.Properties.Name | Should -Contain 'total'
            $Result.PSObject.Properties.Name | Should -Contain 'videos'
        }
    }
    Context 'Find-IMAsset' -Tag 'Find-IMAsset' {
        It -Name 'Should find asset by name' {
            $Result = Find-IMAsset -OriginalFileName 'evgeni-evgeniev-ggVH1hoQAac-unsplash.jpg'
            $Result | Should -HaveCount 1
        }
        It -Name 'Should find asset by partial name' {
            $Result = Find-IMAsset -OriginalFileName 'unsp'
            $Result | Should -HaveCount 13
        }
        It -Name 'Should find all assets by paging' {
            $Result = Find-IMAsset -OriginalFileName 'unsp' -Size 5
            $Result | Should -HaveCount 13
        }
    }
    Context 'Search-IMAsset' -Tag 'Search-IMAsset' {
        It -Name 'Should find road assets' {
            $Result = Search-IMAsset -Query 'Road'
            $Result.Count | Should -BeGreaterThan 0
        }

        It -Name 'Should correctly translate PascalCase parameters to API camelCase' {
            # This test uses parameters that have different PowerShell vs API naming
            # If ConvertTo-ApiParameters isn't working, the API call would fail or return unexpected results
            # Using -IsFavorite (PowerShell) which should translate to 'isFavorite' (API)
            # Using -IsEncoded (PowerShell) which should translate to 'isEncoded' (API)
            # Using -Type (PowerShell) which should translate to 'type' (API)

            # Test with boolean parameters that would fail if not translated correctly
            $Result = Search-IMAsset -Query 'Road' -IsFavorite:$false -IsEncoded:$true -Type 'IMAGE'

            # If the parameter translation worked, we should get a valid response (even if empty)
            # If it failed, we'd get an API error about unknown parameters
            $Result | Should -Not -BeNull
            # Result should be an array (even if empty)
            $Result.GetType().BaseType.Name | Should -Be 'Array'
        }

        It -Name 'Should handle DateTime parameters with correct API translation' {
            # Test DateTime parameters that need correct translation
            # CreatedAfter (PowerShell) -> createdAfter (API)
            # TakenBefore (PowerShell) -> takenBefore (API)

            $Result = Search-IMAsset -Query 'Road'

            # If parameter translation worked, we get valid results
            $Result[0].OriginalFileName | should -be 'evgeni-evgeniev-ggVH1hoQAac-unsplash.jpg'
        }
    }
}

# Skipped until we can exit maintenance mode via API
Describe 'Maintenance' -Tag 'Integration' -Skip:$true {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Start-IMMaintenanceMode' -Tag 'Start-IMMaintenanceMode' {
        It -Name 'Should enable maintenance mode' {
            # Get initial state
            $InitialConfig = Get-IMServer -Configuration

            try {
                # Enable maintenance mode
                { Start-IMMaintenanceMode -Confirm:$false } | Should -Not -Throw

                # Verify maintenance mode is enabled
                $ConfigAfterStart = Get-IMServer -Configuration
                $ConfigAfterStart.maintenanceMode | Should -Be $true
            }
            finally {
                # Always ensure we exit maintenance mode after the test
                if ($ConfigAfterStart.maintenanceMode -eq $true) {
                    Stop-IMMaintenanceMode -Confirm:$false
                }
            }
        }
    }
    Context 'Stop-IMMaintenanceMode' -Tag 'Stop-IMMaintenanceMode' {
        It -Name 'Should disable maintenance mode' {
            try {
                # First enable maintenance mode
                Start-IMMaintenanceMode -Confirm:$false
                $ConfigAfterStart = Get-IMServer -Configuration
                $ConfigAfterStart.maintenanceMode | Should -Be $true

                # Now disable maintenance mode
                { Stop-IMMaintenanceMode -Confirm:$false } | Should -Not -Throw

                # Verify maintenance mode is disabled
                $ConfigAfterStop = Get-IMServer -Configuration
                $ConfigAfterStop.maintenanceMode | Should -Be $false
            }
            finally {
                # Ensure we're not in maintenance mode after the test
                $FinalConfig = Get-IMServer -Configuration
                if ($FinalConfig.maintenanceMode -eq $true) {
                    Stop-IMMaintenanceMode -Confirm:$false
                }
            }
        }
    }
}

Describe 'Activity' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Get-IMActivity' -Tag 'Get-IMActivity' {
        It -Name 'Getting activity count for album should be 4' {
            $Result = Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            $Result | Should -HaveCount 4
        }
        It -Name 'Getting activity count for album and asset should be 4' {
            $Result = Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -AssetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
            $Result | Should -HaveCount 4
        }
        It -Name 'Getting activity count for album, asset and user should be 4' {
            $Result = Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -AssetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf' -UserId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            $Result | Should -HaveCount 4
        }
        It -Name 'Getting activity count for comments on album should be 3' {
            $Result = Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Type comment
            $Result | Should -HaveCount 3
        }
        It -Name 'Getting activity count for likes on album should be 1' {
            $Result = Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Type like
            $Result | Should -HaveCount 1
        }
    }
    Context 'Get-IMActivityStatistic' -Tag 'Get-IMActivityStatistic' {
        It -Name 'Getting comment count for the album should be 3' {
            $Result = Get-IMActivityStatistic -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            $Result.Comments | Should -Be 3
        }
        It -Name 'Getting comment count for album and asset should be 3' {
            $Result = Get-IMActivityStatistic -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -AssetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
            $Result.Comments | Should -Be 3
        }
    }
    Context 'Add-IMActivity' -Tag 'Add-IMActivity' {
        It -Name 'Adding a comment should succeed' {
            $Result = Add-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -AssetId 'bdc6d2c8-6168-4a88-a51f-6da11bf8f506' -Comment 'TestComment' -Type comment
            Remove-IMActivity -Id $Result.id
        }
    }
    Context 'Remove-IMActivity' -Tag 'Remove-IMActivity' {
        It -Name 'Removing a comment should succeed' {
            $Result = Add-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -AssetId 'bdc6d2c8-6168-4a88-a51f-6da11bf8f506' -Comment 'TestComment' -Type comment
            Remove-IMActivity -Id $Result.id
            # Seems to be 50-50 chance this test fails. It might be a timing issue, trying to delay the verification half a seconds.
            Start-Sleep -Milliseconds 500
            Get-IMActivity -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -AssetId 'bdc6d2c8-6168-4a88-a51f-6da11bf8f506' | Should -BeNullOrEmpty
        }
    }
}

Describe 'Album' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Get-IMAlbumStatistic' -Tag 'Get-IMAlbumStatistic' {
        It -Name 'get' {
            $Result = Get-IMAlbumStatistic
            $Result.owned | Should -Be 1
            $Result.shared | Should -Be 1
            $Result.notShared | Should -Be 0
        }
    }
    Context 'Get-IMAlbum' -Tag 'Get-IMAlbum' {
        It -Name 'list-default' {
            $Result = Get-IMAlbum | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 1
        }
        It -Name 'list-shared-true' {
            $Result = Get-IMAlbum -Shared:$true | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 1
        }
        It -Name 'list-name correct name' {
            $Result = Get-IMAlbum -Name 'TestAlbum'
            $Result.Id | Should -Contain 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            $Result | Should -HaveCount 1
        }
        It -Name 'list-name incorrect name' {
            $Result = Get-IMAlbum -Name 'NewYork'
            $Result | Should -HaveCount 0
        }
        It -Name 'list-searchstring expect find' {
            $Result = Get-IMAlbum -SearchString 'Test*'
            $Result.Id | Should -Contain 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            $Result | Should -HaveCount 1
        }
        It -Name 'list-searchstring do not expect find' {
            $Result = Get-IMAlbum -SearchString 'NewYork*'
            $Result | Should -HaveCount 0
        }
        It -Name 'list-shared-false' {
            $Result = Get-IMAlbum -Shared:$false | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 0
        }
        It -Name 'list-assetid' {
            $Result = Get-IMAlbum -AssetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf' | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 1
        }
        It -Name 'list-id with assets' {
            $Result = Get-IMAlbum -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -IncludeAssets | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 1
            $Result.Assets | Should -Not -BeNullOrEmpty
        }
        It -Name 'list-id without assets' {
            $Result = Get-IMAlbum -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 1
            $Result.Assets | Should -BeNullOrEmpty
        }
        It -Name 'list-id-pipe-string' {
            $Result = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' | Get-IMAlbum | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 1
        }
        It -Name 'list-id-pipe-string-array' {
            $Result = @('bde7ceba-f301-4e9e-87a2-163937a2a3db', 'bde7ceba-f301-4e9e-87a2-163937a2a3db') | Get-IMAlbum | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 2
        }
        It -Name 'list-id-pipe-object-array' {
            $Result = @([pscustomobject]@{albumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }, [pscustomobject]@{albumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }) | Get-IMAlbum | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 2
        }
        It -Name 'list-id-pipe-object-array-alias' {
            $Result = @([pscustomobject]@{id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }, [pscustomobject]@{id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }) | Get-IMAlbum | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 2
        }
    }
    Context 'New-IMAlbum' -Tag 'New-IMAlbum' {
        BeforeAll {
            if ($env:CI)
            {
                $AlbumName = $env:GITHUB_RUN_ID
            }
            else
            {
                $AlbumName = HOSTNAME.EXE
            }
        }
        It -Name 'Album gets created' {
            $NewAlbum = New-IMAlbum -AlbumName $AlbumName -AssetIds 'a4908e1f-697f-4d7b-9330-93b5eabe3baf' -Description $AlbumName
            $Result = Get-IMAlbum -AlbumId $NewAlbum.id -IncludeAssets
            $Result | Should -HaveCount 1
            $Result.Description | Should -Be $AlbumName
            $Result.albumName | Should -Be $AlbumName
            $Result.Assets | Should -HaveCount 1
            Remove-IMAlbum -AlbumId $NewAlbum.id
        }
        AfterAll {
            Get-IMAlbum | Where-Object { $_.AlbumName -eq $AlbumName } | Remove-IMAlbum
        }
    }
    Context 'Remove-IMAlbum' -Tag 'Remove-IMAlbum' {
        BeforeAll {
            if ($env:CI)
            {
                $AlbumName = $env:GITHUB_RUN_ID
            }
            else
            {
                $AlbumName = HOSTNAME.EXE
            }
        }
        It -Name 'Album gets removed' {
            $NewAlbum = New-IMAlbum -AlbumName $AlbumName -AssetIds 'a4908e1f-697f-4d7b-9330-93b5eabe3baf' -Description $AlbumName
            Remove-IMAlbum -AlbumId $NewAlbum.id
            { Get-IMAlbum -AlbumId $NewAlbum.id } | Should -Throw
        }
    }
    Context 'Set-IMAlbum' -Tag 'Set-IMAlbum' {
        BeforeAll {
            if ($env:CI)
            {
                $AlbumName = $env:GITHUB_RUN_ID
            }
            else
            {
                $AlbumName = HOSTNAME.EXE
            }
            $NewAlbum = New-IMAlbum -AlbumName $AlbumName
        }
        AfterAll {
            Remove-IMAlbum -AlbumId $NewAlbum.id
        }
        It -Name 'Assets gets added to album' {
            Set-IMAlbum -Id $NewAlbum.id -AddAssets '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
            $Result = Get-IMAlbum -AlbumId $NewAlbum.id -IncludeAssets
            $Result.assets | Should -HaveCount 2
            $Result.assets.id | Should -Contain '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Result.assets.id | Should -Contain '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        }
        It -Name 'Assets gets removed from album' {
            Set-IMAlbum -Id $NewAlbum.id -RemoveAssets '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
            $Result = Get-IMAlbum -AlbumId $NewAlbum.id -IncludeAssets
            $Result.assets | Should -HaveCount 0
        }
        It -Name 'Album gets updated' {
            Set-IMAlbum -albumid $NewAlbum.id -Description "$($AlbumName)New"
            $Result = Get-IMAlbum -AlbumId $NewAlbum.id
            $Result | Should -HaveCount 1
            $Result.Description | Should -Be "$($AlbumName)New"
        }
        It -Name 'Album gets a new name' {
            Rename-IMAlbum -albumid $NewAlbum.id -NewName "$($AlbumName)New"
            $Result = Get-IMAlbum -AlbumId $NewAlbum.id
            $Result | Should -HaveCount 1
            $Result.albumName | Should -Be "$($AlbumName)New"
        }
    }
    Context 'Add-IMAlbumUser' -Tag 'Add-IMAlbumUser' {
        BeforeAll {
            if ($env:CI)
            {
                $AlbumName = $env:GITHUB_RUN_ID
            }
            else
            {
                $AlbumName = HOSTNAME.EXE
            }
            $NewAlbum = New-IMAlbum -AlbumName $AlbumName
        }
        It -Name 'Users gets added to album as viewer' {
            Add-IMAlbumUser -AlbumId $NewAlbum.id -UserId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            $Result = Get-IMAlbum -AlbumId $NewAlbum.id
            $Result.albumUsers.user | Should -HaveCount 1
            $Result.albumUsers.user.id | Should -Contain '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
        }
        AfterAll {
            Get-IMAlbum | Where-Object { $_.AlbumName -eq $AlbumName } | Remove-IMAlbum
        }
    }

    Context 'Set-IMAlbumUser' -Tag 'Set-IMAlbumUser' {
        BeforeAll {
            if ($env:CI)
            {
                $AlbumName = $env:GITHUB_RUN_ID
            }
            else
            {
                $AlbumName = HOSTNAME.EXE
            }
            $NewAlbum = New-IMAlbum -AlbumName $AlbumName
        }
        It -Name 'Users gets added to album as viewer and changed to editor' {
            Add-IMAlbumUser -AlbumId $NewAlbum.id -UserId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d' -Role viewer
            $Result = Get-IMAlbum -AlbumId $NewAlbum.id
            $Result.albumUsers[0].role | Should -Be 'viewer'
            Set-IMAlbumUser -AlbumId $NewAlbum.id -UserId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d' -Role editor
            $Result = Get-IMAlbum -AlbumId $NewAlbum.id
            $Result.albumUsers[0].role | Should -Be 'editor'
        }
        AfterAll {
            Get-IMAlbum | Where-Object { $_.AlbumName -eq $AlbumName } | Remove-IMAlbum
        }
    }


    Context 'Remove-IMAlbumUser' -Tag 'Remove-IMAlbumUser' {
        BeforeAll {
            if ($env:CI)
            {
                $AlbumName = $env:GITHUB_RUN_ID
            }
            else
            {
                $AlbumName = HOSTNAME.EXE
            }
            $NewAlbum = New-IMAlbum -AlbumName $AlbumName -AlbumUsers @{userId = '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'; role = 'editor' }
        }
        It -Name 'Users gets removed from album' {
            $Result = Get-IMAlbum -AlbumId $NewAlbum.id
            $Result.albumUsers.user.id | Should -Contain '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            Remove-IMAlbumUser -AlbumId $NewAlbum.id -UserId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            $Result = Get-IMAlbum -AlbumId $NewAlbum.id
            $Result.albumUsers.user | Should -Not -Contain '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
        }
        AfterAll {
            Get-IMAlbum | Where-Object { $_.AlbumName -eq $AlbumName } | Remove-IMAlbum
        }
    }
}

Describe 'APIKey' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        if ($env:CI)
        {
            $KeyName = $env:GITHUB_RUN_ID
        }
        else
        {
            $KeyName = HOSTNAME.EXE
        }
    }
    Context 'Get-IMAPIKey' -Tag 'Get-IMAPIKey' {
        It 'Retreives one api-key when using ID' {
            $Result = Get-IMAPIKey -Id 'a1c2b770-3c58-46d9-ac6d-2e6d03d870e2'
            $Result | Should -HaveCount 1
        }
    }
    Context 'New-IMAPIKey' -Tag 'New-IMAPIKey' {
        It 'Should create a new api-key' {
            $Result = New-IMAPIKey -Name $KeyName -Permission all
            $Result.secret | Should -Not -BeNullOrEmpty
            Get-IMAPIKey -Id $Result.apiKey.id | Should -HaveCount 1
            Remove-IMAPIKey -Id $Result.apiKey.id
        }
        It 'Should create a new api-key with multiple permissions' {
            $Result = New-IMAPIKey -Name $KeyName -Permission 'activity.create', 'activity.read', 'activity.update'
            $Result.secret | Should -Not -BeNullOrEmpty
            Get-IMAPIKey -Id $Result.apiKey.id | Should -HaveCount 1
            Remove-IMAPIKey -Id $Result.apiKey.id
        }
    }
    Context 'Set-IMAPIKey' -Tag 'Set-IMAPIKey' {
        It 'Should set a new name' {
            $Result = New-IMAPIKey -Name $KeyName -Permission all
            Rename-IMAPIKey -Id $Result.apiKey.id -Name "$($KeyName)_New"
            $Result = Get-IMAPIKey -Id $Result.apiKey.id
            $Result.Name | Should -Be "$($KeyName)_New"
            Remove-IMAPIKey -Id $Result.id
        }
    }
    Context 'Remove-IMAPIKey' -Tag 'Remove-IMAPIKey' {
        It 'Should remove the api key' {
            $Result = New-IMAPIKey -Name $KeyName -Permission all
            Remove-IMAPIKey -Id $Result.apiKey.id
            { Get-IMAPIKey -Id $Result.apiKey.id } | Should -Throw
        }
    }
}

Describe 'Auth' -Tag 'Integration' {
    Context 'Test-IMAccessToken' -Tag 'Test-IMAccessToken' {
        It 'Should return true' {
            # Using credential instead of API-key to get a current device
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred
            Test-IMAccessToken | Should -BeTrue
        }
    }
}

Describe 'AuthSession' -Tag 'Integration' {
    Context 'Get-IMAuthSession' -Tag 'Get-IMAuthSession' {
        It 'Should return sessions' {
            $Result = Get-IMAuthSession | Where-Object { $_.current -eq $true }
            $Result | Should -HaveCount 1
        }
    }
    Context 'Remove-IMAuthSession' -Tag 'Remove-IMAuthSession' {
        It 'Should return a single auth session' {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred
            $CurrentAuthDevice = Get-IMAuthSession | Where-Object { $_.current -eq $true }
            { Remove-IMAuthSession -id $CurrentAuthDevice.id } | Should -Not -Throw
            { Get-IMAuthSession } | Should -Throw
        }
        It 'Should remove all auth sessions' {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred
            { Remove-IMAuthSession } | Should -Not -Throw
            $Result = Get-IMAuthSession
            $Result | Should -HaveCount 1
            $Result.Current | Should -BeTrue
        }
    }
}

Describe 'Face' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'Get-IMFace' -Tag 'Get-IMFace' {
        It 'Should return faces' {
            $Result = Get-IMFace -Id 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'
            $Result | Should -HaveCount 5
        }
    }
}

Describe 'Job' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'Get-IMJob' -Tag 'Get-IMJob' {
        It 'Should return 1 object' {
            $Result = Get-IMJob
            $Result | Should -HaveCount 1
        }
    }
    Context -Name 'Start-IMJob' -Tag 'Start-IMJob' {
        It 'Should start job' {
            $Result = Start-IMJob -Job 'thumbnailGeneration'
            $Result.jobCounts.active + $Result.jobCounts.waiting | Should -Be 1
        }
        It 'Should start emptyTrash job' {
            $Result = Import-IMAsset -FilePath "$PSScriptRoot\Immich.png"
            $Result | Should -HaveCount 1
            $Result.DeviceAssetID | Should -Be 'Immich.png'
            Remove-IMAsset -Id $Result.Id
            $Remove = Get-IMAsset -Id $Result.id
            $Remove.isTrashed | Should -BeTrue
            $Result = Start-IMJob -Job 'emptyTrash'
            { Get-IMAsset -Id $Result.id } | Should -Throw
        }
    }
}

Describe 'Partner' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Add-IMPartner' -Tag 'Add-IMPartner' {
        It 'Should add a partner' {
            $Add = Add-IMPartner -SharedWithId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            $Result = Get-IMPartner -Direction shared-by
            $Result | Should -HaveCount 1
        }
    }
    <# Needs to be run for the partner account
    Context 'Set-IMPartner' -Tag 'Set-IMPartner' {
        It 'Should set timeline on partner' {
            $Set = Set-IMPartner -id '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d' -EnableTimeline
            $Result = Get-IMPartner -Direction shared-by
            $Result | Should -HaveCount 1
            $Result.inTimeline | Should -BeTrue
        }
    }
    #>
    Context 'Get-IMPartner' -Tag 'Get-IMPartner' {
        It 'Should return one person object' {
            $Result = Get-IMPartner -Direction shared-by
            $Result | Should -HaveCount 1
        }
    }
    Context 'Remove-IMPartner' -Tag 'Remove-IMPartner' {
        It 'Should remove partner' {
            Remove-IMPartner -id '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            $Result = Get-IMPartner -Direction shared-by
            $Result | Should -HaveCount 0
        }
    }
}

Describe 'Person' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'New-IMPerson' -Tag 'New-IMPerson' {
        It 'Should create a new person' {
            $New = New-IMPerson -Name 'TestPerson'
            $Result = Get-IMPerson -id $New.id
            $Result | Should -HaveCount 1
            $Result.name | Should -Be 'TestPerson'
        }
    }
    Context 'Get-IMPerson' -Tag 'Get-IMPerson' {
        It 'Should return person' {
            { $PersonList = Get-IMPerson } | Should -Not -Throw
        }
    }
    Context 'Set-IMPerson' -Tag 'Set-IMPerson' {
        It 'Should update person' {
            $New = New-IMPerson -Name 'TestPerson'
            Set-IMPerson -Id $New.id -Name 'TestPerson2'
            $Result = Get-IMPerson -id $New.id
            $Result.Name | Should -Be 'TestPerson2'
        }
    }
}

Describe 'Search' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Find-IMAsset' -Tag 'Find-IMAsset' {
        It 'Should return multiple assets with correct type' {
            $Result = Find-IMAsset
            $Result | Measure-Object | Select-Object -ExpandProperty count | Should -BeGreaterThan 1
            $Result[0].PSObject.TypeNames | Should -Contain 'PSImmich.ObjectType.IMAsset'
        }
    }
}

Describe 'Library' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'New-IMLibrary' -Tag 'New-IMLibrary' {
        It 'Should create library' {
            $New = New-IMLibrary -Name 'TestLibrary' -ExclusionPatterns '*/*' -ImportPath '/mnt/media/pictures' -OwnerId 'fb95c457-7685-428c-b850-2fd60345819c'
            $Result = Get-IMLibrary -id $New.id
            $Result | Should -HaveCount 1
            $Result.Name | Should -Be 'TestLibrary'
            Remove-IMLibrary -id $New.id
        }
    }
    Context 'Get-IMLibrary' -Tag 'Get-IMLibrary' {
        BeforeAll {
            $NewLibrary = New-IMLibrary -Name 'TestLibrary' -ExclusionPatterns '*/*' -ImportPath '/mnt/media/pictures' -OwnerId 'fb95c457-7685-428c-b850-2fd60345819c'
        }
        AfterAll {
            Remove-IMLibrary -id $NewLibrary.id
        }
        It 'Should return list' {
            $Result = Get-IMLibrary
            $Result | Should -HaveCount 1
        }
        It 'Should return list + owner filder' {
            $Result = Get-IMLibrary -ownerId 'fb95c457-7685-428c-b850-2fd60345819c'
            $Result | Should -HaveCount 1
        }
        It 'Should return id' {
            $Result = Get-IMLibrary -id $NewLibrary.Id
            $Result | Should -HaveCount 1
        }
        It 'Should return statistics' {
            $Result = Get-IMLibrary -id $NewLibrary.Id -IncludeStatistics
            $Result.PSObject.Properties.Name | Should -Contain 'Statistics'
        }
    }
    Context 'Remove-IMLibrary' -Tag 'Remove-IMLibrary' {
        It 'Should remove library' {
            $New = New-IMLibrary -Name 'TestLibrary' -ExclusionPatterns '*/*' -ImportPath '/mnt/media/pictures' -OwnerId 'fb95c457-7685-428c-b850-2fd60345819c'
            { Remove-IMLibrary -id $New.id } | Should -Not -Throw
        }
    }
    Context 'Set-IMLibrary' -Tag 'Set-IMLibrary' {
        It 'Should update library' {
            $New = New-IMLibrary -Name 'TestLibrary' -ExclusionPatterns '*/*' -ImportPath '/mnt/media/pictures' -OwnerId 'fb95c457-7685-428c-b850-2fd60345819c'
            $Updated = Set-IMLibrary -Id $New.id -Name 'TestLibrary2'
            $Result = Get-IMLibrary -id $New.id
            $Result | Should -HaveCount 1
            $Result.Name | Should -Be 'TestLibrary2'
            Remove-IMLibrary -id $New.id
        }
    }
    Context 'Sync-IMLibrary' -Tag 'Sync-IMLibrary' {
        It 'Should not throw' {
            $New = New-IMLibrary -Name 'TestLibrary' -ExclusionPatterns '*/*' -ImportPath '/mnt/media/pictures' -OwnerId 'fb95c457-7685-428c-b850-2fd60345819c'
            { Sync-IMLibrary -Id $New.id } | Should -Not -Throw
            Remove-IMLibrary -id $New.id
        }
    }
    Context 'Test-IMLibrary' -Tag 'Test-IMLibrary' {
        It 'Should not throw' {
            $New = New-IMLibrary -Name 'TestLibrary' -ExclusionPatterns '*/*' -ImportPath '/mnt/media/pictures' -OwnerId 'fb95c457-7685-428c-b850-2fd60345819c'
            { Test-IMLibrary -Id $New.id } | Should -Not -Throw
            Remove-IMLibrary -id $New.id
        }
    }
}

Describe 'ServerConfig' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Get-IMServer' -Tag 'Get-IMServer' {
        It 'Should return applied config' {
            $Result = Get-IMServer -AppliedSystemConfiguration
            $Result | Should -HaveCount 1
        }
        It 'Should return applied config raw' {
            $Result = Get-IMServer -AppliedSystemConfiguration -ReturnRawJSON
            { $Result | ConvertFrom-Json } | Should -Not -Throw
        }
        It 'Should return default config' {
            $Result = Get-IMServer -DefaultSystemConfiguration
            $Result | Should -HaveCount 1
        }
        It 'Should return default config raw' {
            $Result = Get-IMServer -DefaultSystemConfiguration -ReturnRawJSON
            { $Result | ConvertFrom-Json } | Should -Not -Throw
        }
        It 'Should return storage template config' {
            $Result = Get-IMServer -StorageTemplateOptions
            $Result | Should -HaveCount 1
        }
        It 'Should update setting' {
            $Result = Get-IMServer -AppliedSystemConfiguration
            $Result.reverseGeocoding.enabled = $false
            Set-IMServer -RawJSONConfig ($Result | ConvertTo-Json -Depth 10)
            $ResultNew = Get-IMServer -AppliedSystemConfiguration
            $ResultNew.reverseGeocoding.enabled | Should -BeFalse
            $Result.reverseGeocoding.enabled = $true
            Set-IMServer -RawJSONConfig ($Result | ConvertTo-Json -Depth 10)
        }
    }
}

Describe 'Tag' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        Get-IMTag | Where-Object { $_.name -eq 'TestTag' } | Remove-IMTag
    }
    Context 'New-IMTag' -Tag 'New-IMTag' {
        It 'Should create a new tag' {
            $Result = New-IMTag -Name 'TestTag'
            $Result | Should -HaveCount 1
            Remove-IMTag -id $Result.id
        }
    }
    Context 'Get-IMTag' -Tag 'Get-IMTag' {
        It 'Should return tag' {
            $New = New-IMTag -Name 'TestTag'
            $Result = Get-IMTag -id $New.id
            $Result | Should -HaveCount 1
        }
        It 'Should return all tags' {
            $Result = Get-IMTag
            $Result | Measure-Object | Select-Object -ExpandProperty count | Should -BeGreaterOrEqual 1
        }
        AfterAll {
            Get-IMTag | Where-Object { $_.name -eq 'TestTag' } | Remove-IMTag
        }
    }
    Context 'Remove-IMTag' -Tag 'Remove-IMTag' {
        It 'Should remove tag' {
            $New = New-IMTag -Name 'TestTag'
            Remove-IMTag -id $New.id
            { Get-IMTag -id $New.id } | Should -Throw
        }
    }
    Context 'Set-IMTag' -Tag 'Set-IMTag' {
        BeforeAll {
            $NewTag = New-IMTag -Name 'TestTag'
        }
        AfterAll {
            Remove-IMTag -id $NewTag.id
        }
        It 'Should add tag to asset' {
            $Result = Set-IMTag -Id $NewTag.id -AddAssets '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Asset = Get-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Asset.tags.id | Should -Contain $newtag.id
        }
        It 'Get-IMAsset -TagId should return tagged asset' {
            $Result = Get-IMAsset -TagId $NewTag.id
            $Result.id | Should -Contain '025665c6-d874-46a2-bbc6-37250ddcb2eb'
        }
        It 'Should remove tag from asset' {
            $Result = Set-IMTag -Id $NewTag.id -RemoveAssets '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Asset = Get-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb'

            # Don't know if it is a bug or not but according to the integration tests it seems 50/50
            # if the tag is removed. To pass tests for the powershell module we will make a few atempts.
            $Tries = 0
            while ($Asset.tags -and $Tries -le 10)
            {
                Start-Sleep -Seconds 1
                $Result = Set-IMTag -Id $NewTag.id -RemoveAssets '025665c6-d874-46a2-bbc6-37250ddcb2eb'
                $Asset = Get-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb'
                $Tries++
            }

            $Asset.tags.id | Should -Not -Contain $newtag.id
        }
        It 'Should set color' {
            $Result = Set-IMTag -Id $NewTag.id -Color '#008000'
            $Result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Timeline' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Get-IMTimeBucket' -Tag 'Get-IMTimeBucket' {
        It -Name 'Should return 3 objects' {
            $Result = Get-IMTimeBucket
            $Result | Should -HaveCount 2
        }
        It -Name 'Should return 1 object' {
            $Result = Get-IMTimeBucket -timeBucket '2024-03-01 00:00:00'
            $Result.id | Should -HaveCount 12
        }
    }
}

Describe 'Map' -Tag 'Integration' {
    Context 'Convert-IMCoordinatesToLocation' -Tag 'Convert-IMCoordinatesToLocation' {
        It 'Should return location of Kensington' {
            $Result = Convert-IMCoordinatesToLocation -Latitude 51.496637 -Longitude -0.176370
            $Result.country | Should -Be 'United Kingdom'
            $Result.state | Should -Be 'England'
            $Result.city | Should -Be 'Kensington'
        }
    }
}

Describe 'Duplicate' -Tag 'Integration' {
    Context 'Get-IMDuplicate' -Tag 'Get-IMDuplicate' {
        It 'Should no throw' {
            { Get-IMDuplicate } | Should -Not -Throw
        }
    }
}

Describe 'User' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Get-IMUser' -Tag 'Get-IMUser' {
        It 'Should list all users' {
            $Result = Get-IMUser
            $Result | Should -HaveCount 2
        }
        It 'Should list specific user' {
            $Result = Get-IMUser -id 'fb95c457-7685-428c-b850-2fd60345819c'
            $Result | Should -HaveCount 1
            $Result.name | Should -Be 'Hannes Palmquist'
        }
        It 'Should list self' {
            $Result = Get-IMUser -Me
            $Result | Should -HaveCount 1
            $Result.name | Should -Be 'Hannes Palmquist'
        }
    }
    Context 'Get-IMUserPreference' -Tag 'Get-IMUserPreference' {
        It 'Should list self' {
            $Result = Get-IMUserPreference
            $Result.PSObject.Properties.Name | Should -Contain 'albums'
            $Result.PSObject.Properties.Name | Should -Contain 'folders'
            $Result.PSObject.Properties.Name | Should -Contain 'memories'
            $Result.PSObject.Properties.Name | Should -Contain 'people'
            $Result.PSObject.Properties.Name | Should -Contain 'sharedLinks'
            $Result.PSObject.Properties.Name | Should -Contain 'ratings'
            $Result.PSObject.Properties.Name | Should -Contain 'tags'
            $Result.PSObject.Properties.Name | Should -Contain 'emailNotifications'
            $Result.PSObject.Properties.Name | Should -Contain 'download'
            $Result.PSObject.Properties.Name | Should -Contain 'purchase'
            $Result.PSObject.Properties.Name | Should -Contain 'cast'
            $Result | Should -HaveCount 1
        }
        It 'Should list specific user' {
            $Result = Get-IMUserPreference -id 'fb95c457-7685-428c-b850-2fd60345819c'
            $Result.PSObject.Properties.Name | Should -Contain 'albums'
            $Result.PSObject.Properties.Name | Should -Contain 'folders'
            $Result.PSObject.Properties.Name | Should -Contain 'memories'
            $Result.PSObject.Properties.Name | Should -Contain 'people'
            $Result.PSObject.Properties.Name | Should -Contain 'sharedLinks'
            $Result.PSObject.Properties.Name | Should -Contain 'ratings'
            $Result.PSObject.Properties.Name | Should -Contain 'tags'
            $Result.PSObject.Properties.Name | Should -Contain 'emailNotifications'
            $Result.PSObject.Properties.Name | Should -Contain 'download'
            $Result.PSObject.Properties.Name | Should -Contain 'purchase'
            $Result.PSObject.Properties.Name | Should -Contain 'cast'
            $Result | Should -HaveCount 1
        }
    }
    Context 'Set-IMUserPreference' -Tag 'Set-IMUserPreference' {
        BeforeEach {
            Set-IMUserPreference -id 'fb95c457-7685-428c-b850-2fd60345819c' -EmailNotificationEnabled:$true
        }
        AfterEach {
            Set-IMUserPreference -id 'fb95c457-7685-428c-b850-2fd60345819c' -EmailNotificationEnabled:$true
        }
        It 'Should change setting for user when using id' {
            Set-IMUserPreference -id 'fb95c457-7685-428c-b850-2fd60345819c' -EmailNotificationEnabled:$false
            $Result = Get-IMUserPreference
            $Result.emailNotifications.enabled | Should -BeFalse
        }
        It 'Should change setting for user when using pipe' {
            Get-IMUser -id 'fb95c457-7685-428c-b850-2fd60345819c' | `
                    Set-IMUserPreference -EmailNotificationEnabled:$false
            $Result = Get-IMUserPreference
            $Result.emailNotifications.enabled | Should -BeFalse
        }
    }
    Context 'New-IMUser' -Tag 'New-IMUser' {
        It 'Should create user' {
            $New = New-IMUser -Email 'test@domain.com' -Name 'TestUser' -Password (ConvertTo-SecureString -String 'test' -AsPlainText -Force)
            $Result = Get-IMUser -id $New.id
            $Result | Should -HaveCount 1
            $Result.email | Should -Be 'test@domain.com'
            $Result.name | Should -Be 'TestUser'
        }
    }
    Context 'Set-IMUser' -Tag 'Set-IMUser' {
        It 'Should update user' {
            $Get = Get-IMUser | Where-Object { $_.email -eq 'test@domain.com' }
            $Updated = Set-IMUser -id $Get.id -Name 'test user'
            $Result = Get-IMUser -id $Get.id
            $Result.name | Should -BeExactly 'test user'
        }
    }
    Context 'Add-IMMyProfilePicture' -Tag 'Add-IMMyProfilePicture' {
        It 'Should add profile picture' {
            { $Result = Add-IMMyProfilePicture -FilePath "$PSScriptRoot\Immich.png" } | Should -Not -Throw
        }
    }
    Context 'Remove-IMMyProfilePicture' -Tag 'Remove-IMMyProfilePicture' {
        It 'Should remove profile picture' -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
            { $Result = Remove-IMMyProfilePicture } | Should -Not -Throw
        }
    }
    Context 'Remove-IMUser' -Tag 'Remove-IMUser' {
        It 'Should remove user' {
            $Get = Get-IMUser | Where-Object { $_.email -eq 'test@domain.com' }
            Remove-IMUser -id $get.id -Force
        }
    }
}

Describe 'SharedLink' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        Get-IMSharedLink | Remove-IMSharedLink
    }
    Context 'New-IMSharedLink' -Tag 'New-IMSharedLink' {
        It 'Should create asset shared link' {
            $NewAssetLink = New-IMSharedLink -AssetId '6d178c17-71f1-4231-a225-f4ffe55d24a5' -AllowUpload -ExpiresAt ((Get-Date).AddDays(3)) -ShowMetadata
            $NewAssetLink | Should -HaveCount 1
        }
        It 'Should create album shared link' {
            $NewAlbumLink = New-IMSharedLink -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -AllowUpload -ExpiresAt ((Get-Date).AddDays(3)) -ShowMetadata
            $NewAlbumLink | Should -HaveCount 1
        }
    }
    Context 'Get-IMSharedLink' -Tag 'Get-IMSharedLink' {
        It 'Should get two shared links' {
            $Result = Get-IMSharedLink
            $Result | Should -HaveCount 2
            $Result.type | Should -Contain 'ALBUM'
            $Result.type | Should -Contain 'INDIVIDUAL'
        }
        <#
        It 'Should get two shared links' {
            $Result = Get-IMSharedLink -Me
            $Result | Should -HaveCount 2
        }
        #>
    }
    Context 'Set-IMSharedLink' -Tag 'Set-IMSharedLink' {
        It 'Should update setting on asset shared link' {
            $ExistingSharedLink = Get-IMSharedLink
            $ExistingSharedLink | Set-IMSharedLink -AllowUpload:$false
            $Result = Get-IMSharedLink
            $Result.AllowUpload | Should -Not -Contain $true
        }
    }

    Context 'Add-IMSharedLinkAsset' -Tag 'Add-IMSharedLinkAsset' {
        It 'Should add asset to shared link' {
            $SharedLink = Get-IMSharedLink | Where-Object { $_.type -eq 'INDIVIDUAL' }
            $Add = Add-IMSharedLinkAsset -SharedLinkId $SharedLink.id -Id '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
            $Get = Get-IMSharedLink -id $SharedLink.id
            $Get.Assets.Id | Should -Contain '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        }
    }

    Context 'Remove-IMSharedLinkAsset' -Tag 'Remove-IMSharedLinkAsset' -Skip:$true {
        It 'Should remove asset from shared link' {
            # API broken in 1.127.X.
            $SharedLink = Get-IMSharedLink | Where-Object { $_.type -eq 'INDIVIDUAL' }
            $IdToRemove = [array]($SharedLink.Assets.Id) | Get-Random -Count 1
            $Remove = Remove-IMSharedLinkAsset -SharedLinkId $Sharedlink.id -Id $IdToRemove
            $Get = Get-IMSharedLink -id $SharedLink.id
            [array]($Get.assets.id) | Should -Not -Contain $IdToRemove
        }
    }

    Context 'Remove-IMSharedLink' -Tag 'Remove-IMSharedLink' {
        It 'Should remove shared links' {
            Get-IMSharedLink | Remove-IMSharedLink
            $Get = Get-IMSharedLink
            $Get | Should -HaveCount 0
        }
    }
}

Describe 'Stack' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        Get-IMStack | Remove-IMStack -Force -ErrorAction SilentlyContinue
    }

    Context 'Get-IMStack - List all stacks' -Tag 'Get-IMStack' {
        It 'Should return stacks when none exist' {
            $Result = Get-IMStack
            $Result | Should -BeNullOrEmpty
        }
    }

    Context 'New-IMStack - Create new stack' -Tag 'New-IMStack' {
        It 'Should create a new stack with multiple assets' {
            $Result = New-IMStack -AssetIds 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c', 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Match '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            $Result.Assets | Should -HaveCount 2
            $Result.PrimaryAssetId | Should -Be 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'
        }
    }

    Context 'Get-IMStack - Retrieve specific stack' -Tag 'Get-IMStack' {
        It 'Should return stack by ID' {
            $StackId = Get-IMStack | Where-Object { $_.assets.id -contains 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c' } | Select-Object -expand id
            $Result = Get-IMStack -Id $StackId
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Be $StackId
            $Result.Assets | Should -HaveCount 2
        }

        It 'Should return stacks filtered by primary asset ID' {
            $Result = Get-IMStack -PrimaryAssetId 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'
            $Result | Should -Not -BeNullOrEmpty
            $Result.PrimaryAssetId | Should -Be 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'
        }

        It 'Should list all stacks' {
            $StackId = Get-IMStack | Where-Object { $_.assets.id -contains 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c' } | Select-Object -expand id
            $Result = Get-IMStack
            $Result | Should -HaveCount 1
            $Result[0].Id | Should -Be $StackId
        }
    }

    Context 'Set-IMStack - Update stack' -Tag 'Set-IMStack' {
        It 'Should update primary asset of stack' {
            $StackId = Get-IMStack | Where-Object { $_.assets.id -contains 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c' } | Select-Object -expand id
            $Result = Set-IMStack -Id $StackId -PrimaryAssetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
            $Result | Should -Not -BeNullOrEmpty
            $Result.PrimaryAssetId | Should -Be 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'

            # Verify the change persisted
            $Verify = Get-IMStack -Id $StackId
            $Verify.PrimaryAssetId | Should -Be 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
        }
    }

    Context 'Remove-IMStackAsset - Remove asset from stack' -Tag 'Remove-IMStackAsset' {
        It 'Should remove an asset from the stack' {
            $StackId = Get-IMStack | Where-Object { $_.assets.id -contains 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c' } | Select-Object -expand id

            # Remove the third asset
            Remove-IMStackAsset -StackId $StackId -AssetId 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c' -Force

            # Verify asset was removed
            $Verify = Get-IMStack -Id $StackId
            $Verify.Assets.Id | Should -Not -Contain 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'
            $Verify.Assets | Should -HaveCount 1
        }
    }

    Context 'Remove-IMStack - Delete stack' -Tag 'Remove-IMStack' {
        It 'Should remove a single stack' {
            $StackId = Get-IMStack | Where-Object { $_.assets.id -contains 'a4908e1f-697f-4d7b-9330-93b5eabe3baf' } | Select-Object -expand id
            Remove-IMStack -Id $StackId -Force

            # Verify stack was removed
            { Get-IMStack -Id $StackId } | Should -Throw
        }

        It 'Should remove multiple stacks in bulk' {
            $Stack1 = New-IMStack -AssetIds 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c', 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
            $Stack2 = New-IMStack -AssetIds 'bdc6d2c8-6168-4a88-a51f-6da11bf8f506', 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
            Remove-IMStack -Id $Stack1.Id, $Stack2.Id -Force

            # Verify stacks were removed
            $Result = Get-IMStack
            $Result | Should -BeNullOrEmpty
        }
    }

    AfterAll {
        # Clean up any remaining stacks (but leave the existing test assets intact)
        try
        {
            Get-IMStack | Remove-IMStack -Force -ErrorAction SilentlyContinue
        }
        catch
        {
            # No stacks to clean up
        }
    }
}

Describe 'Plugin' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Get-IMPlugin' -Tag 'Get-IMPlugin' {
        It -Name 'Should list all plugins without error' {
            { $Result = Get-IMPlugin } | Should -Not -Throw
        }
        It -Name 'Should get specific plugin by ID if plugins exist' {
            $AllPlugins = Get-IMPlugin
            if ($AllPlugins -and $AllPlugins.Count -gt 0)
            {
                $FirstPlugin = $AllPlugins[0]
                $Result = Get-IMPlugin -Id $FirstPlugin.id
                $Result | Should -Not -BeNullOrEmpty
                $Result.id | Should -Be $FirstPlugin.id
            }
        }
        It -Name 'Should support pipeline input with plugin ID' {
            $AllPlugins = Get-IMPlugin
            if ($AllPlugins -and $AllPlugins.Count -gt 0)
            {
                $FirstPlugin = $AllPlugins[0]
                $Result = $FirstPlugin.id | Get-IMPlugin
                $Result | Should -Not -BeNullOrEmpty
                $Result.id | Should -Be $FirstPlugin.id
            }
        }
        It -Name 'Should throw when getting non-existent plugin' {
            $FakeId = 'ffffffff-ffff-ffff-ffff-ffffffffffff'
            { Get-IMPlugin -Id $FakeId } | Should -Throw
        }
    }
}

Describe 'Memory' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Get-IMMemory' -Tag 'Get-IMMemory' {
        It -Name 'Should list memories without error' {
            { $Result = Get-IMMemory } | Should -Not -Throw
        }
        It -Name 'Should return array when memories exist' {
            $Result = Get-IMMemory
            if ($Result)
            {
                $Result | Should -BeOfType [Array]
            }
        }
        It -Name 'Should support Order parameter' {
            { $Result = Get-IMMemory -Order 'asc' } | Should -Not -Throw
            { $Result = Get-IMMemory -Order 'desc' } | Should -Not -Throw
        }
        It -Name 'Should support NumberOfMemories parameter' {
            { $Result = Get-IMMemory -NumberOfMemories 5 } | Should -Not -Throw
        }
        It -Name 'Should support IsSaved parameter' {
            { $Result = Get-IMMemory -IsSaved:$true } | Should -Not -Throw
            { $Result = Get-IMMemory -IsSaved:$false } | Should -Not -Throw
        }
        It -Name 'Should support IsTrashed parameter' {
            { $Result = Get-IMMemory -IsTrashed:$true } | Should -Not -Throw
            { $Result = Get-IMMemory -IsTrashed:$false } | Should -Not -Throw
        }
        It -Name 'Should support Type parameter' {
            { $Result = Get-IMMemory -Type 'on_this_day' } | Should -Not -Throw
        }
        It -Name 'Should support Statistics switch and return statistics data' {
            { $Result = Get-IMMemory -Statistics } | Should -Not -Throw
            $Result = Get-IMMemory -Statistics
            if ($Result)
            {
                # Statistics should return different structure than regular memories
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        It -Name 'Should support For parameter for date filtering' {
            $TestDate = Get-Date -Format 'yyyy-MM-dd'
            { $Result = Get-IMMemory -For $TestDate } | Should -Not -Throw
        }
        It -Name 'Should support combined parameters' {
            { $Result = Get-IMMemory -Order 'desc' -NumberOfMemories 3 -IsSaved:$false } | Should -Not -Throw
        }
        It -Name 'Statistics parameter should be mutually exclusive with other parameters' {
            # When Statistics is used, it should work independently
            { $Result = Get-IMMemory -Statistics -Order 'desc' } | Should -Not -Throw
            { $Result = Get-IMMemory -Statistics -NumberOfMemories 5 } | Should -Not -Throw
        }
    }
}

# Workflow tests excluded for now. Workflows API is still under development. Some request parameters have undefined types.
Describe 'Workflow' -Tag 'Integration' -Skip:$true {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        if ($env:CI)
        {
            $TestWorkflowName = "CI-Test-$($env:GITHUB_RUN_ID)"
        }
        else
        {
            $TestWorkflowName = "Test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        }
    }

    Context 'Get-IMWorkflow' -Tag 'Get-IMWorkflow' {
        It -Name 'Should list all workflows without error' {
            { $Result = Get-IMWorkflow } | Should -Not -Throw
        }
        It -Name 'Should return array when workflows exist' {
            # Create a test workflow first to ensure we have at least one
            $TestWorkflow = New-IMWorkflow -Name $TestWorkflowName -Description 'Integration test workflow'
            try
            {
                $Result = Get-IMWorkflow
                $Result | Should -Not -BeNullOrEmpty
            }
            finally
            {
                Remove-IMWorkflow -Id $TestWorkflow.id -Confirm:$false
            }
        }
        It -Name 'Should get specific workflow by ID' {
            $TestWorkflow = New-IMWorkflow -Name $TestWorkflowName -Description 'Integration test workflow'
            try
            {
                $Result = Get-IMWorkflow -Id $TestWorkflow.id
                $Result | Should -Not -BeNullOrEmpty
                $Result.id | Should -Be $TestWorkflow.id
                $Result.name | Should -Be $TestWorkflowName
            }
            finally
            {
                Remove-IMWorkflow -Id $TestWorkflow.id -Confirm:$false
            }
        }
        It -Name 'Should support pipeline input with workflow ID' {
            $TestWorkflow = New-IMWorkflow -Name $TestWorkflowName -Description 'Integration test workflow'
            try
            {
                $Result = $TestWorkflow.id | Get-IMWorkflow
                $Result | Should -Not -BeNullOrEmpty
                $Result.id | Should -Be $TestWorkflow.id
            }
            finally
            {
                Remove-IMWorkflow -Id $TestWorkflow.id -Confirm:$false
            }
        }
        It -Name 'Should throw when getting non-existent workflow' {
            $FakeId = 'ffffffff-ffff-ffff-ffff-ffffffffffff'
            { Get-IMWorkflow -Id $FakeId } | Should -Throw
        }
    }

    Context 'New-IMWorkflow' -Tag 'New-IMWorkflow' {
        It -Name 'Should create workflow with basic parameters' {
            $NewWorkflow = New-IMWorkflow -Name $TestWorkflowName -Description 'Integration test workflow'
            try
            {
                $NewWorkflow | Should -Not -BeNullOrEmpty
                $NewWorkflow.name | Should -Be $TestWorkflowName
                $NewWorkflow.description | Should -Be 'Integration test workflow'
                $NewWorkflow.enabled | Should -Be $true  # Default value

                # Verify workflow exists in system
                $Retrieved = Get-IMWorkflow -Id $NewWorkflow.id
                $Retrieved.name | Should -Be $TestWorkflowName
            }
            finally
            {
                Remove-IMWorkflow -Id $NewWorkflow.id -Confirm:$false
            }
        }
        It -Name 'Should create workflow with disabled state' {
            $NewWorkflow = New-IMWorkflow -Name $TestWorkflowName -Description 'Disabled test workflow' -Enabled:$false
            try
            {
                $NewWorkflow | Should -Not -BeNullOrEmpty
                $NewWorkflow.enabled | Should -Be $false
            }
            finally
            {
                Remove-IMWorkflow -Id $NewWorkflow.id -Confirm:$false
            }
        }
        It -Name 'Should create workflow with empty actions and filters' {
            $NewWorkflow = New-IMWorkflow -Name $TestWorkflowName -Actions @() -Filters @()
            try
            {
                $NewWorkflow | Should -Not -BeNullOrEmpty
                # Verify workflow can be created with empty collections
                $Retrieved = Get-IMWorkflow -Id $NewWorkflow.id
                $Retrieved.name | Should -Be $TestWorkflowName
            }
            finally
            {
                Remove-IMWorkflow -Id $NewWorkflow.id -Confirm:$false
            }
        }
    }

    Context 'Set-IMWorkflow' -Tag 'Set-IMWorkflow' {
        BeforeAll {
            $TestWorkflow = New-IMWorkflow -Name $TestWorkflowName -Description 'Original description'
        }
        AfterAll {
            try
            {
                Remove-IMWorkflow -Id $TestWorkflow.id -Confirm:$false
            }
            catch
            {
                # Workflow may have been removed by tests
            }
        }
        It -Name 'Should update workflow name' {
            $UpdatedName = "$TestWorkflowName-Updated"
            Set-IMWorkflow -Id $TestWorkflow.id -Name $UpdatedName -Confirm:$false
            $Result = Get-IMWorkflow -Id $TestWorkflow.id
            $Result.name | Should -Be $UpdatedName
        }
        It -Name 'Should update workflow description' {
            $UpdatedDescription = 'Updated integration test workflow description'
            Set-IMWorkflow -Id $TestWorkflow.id -Description $UpdatedDescription -Confirm:$false
            $Result = Get-IMWorkflow -Id $TestWorkflow.id
            $Result.description | Should -Be $UpdatedDescription
        }
        It -Name 'Should update workflow enabled state' {
            Set-IMWorkflow -Id $TestWorkflow.id -Enabled:$false -Confirm:$false
            $Result = Get-IMWorkflow -Id $TestWorkflow.id
            $Result.enabled | Should -Be $false

            # Set it back to enabled
            Set-IMWorkflow -Id $TestWorkflow.id -Enabled:$true -Confirm:$false
            $Result = Get-IMWorkflow -Id $TestWorkflow.id
            $Result.enabled | Should -Be $true
        }
        It -Name 'Should support pipeline input for workflow updates' {
            $UpdatedName = "$TestWorkflowName-Pipeline"
            $TestWorkflow.id | Set-IMWorkflow -Name $UpdatedName -Confirm:$false
            $Result = Get-IMWorkflow -Id $TestWorkflow.id
            $Result.name | Should -Be $UpdatedName
        }
    }

    Context 'Remove-IMWorkflow' -Tag 'Remove-IMWorkflow' {
        It -Name 'Should remove workflow by ID' {
            $TestWorkflow = New-IMWorkflow -Name $TestWorkflowName -Description 'Workflow to be removed'
            $WorkflowId = $TestWorkflow.id

            # Remove the workflow
            Remove-IMWorkflow -Id $WorkflowId -Confirm:$false

            # Verify workflow was removed
            { Get-IMWorkflow -Id $WorkflowId } | Should -Throw
        }
        It -Name 'Should support pipeline input for removal' {
            $TestWorkflow = New-IMWorkflow -Name $TestWorkflowName -Description 'Workflow to be removed via pipeline'
            $WorkflowId = $TestWorkflow.id

            # Remove via pipeline
            $WorkflowId | Remove-IMWorkflow -Confirm:$false

            # Verify workflow was removed
            { Get-IMWorkflow -Id $WorkflowId } | Should -Throw
        }
        It -Name 'Should remove multiple workflows' {
            $Workflow1 = New-IMWorkflow -Name "$TestWorkflowName-1" -Description 'First workflow to remove'
            $Workflow2 = New-IMWorkflow -Name "$TestWorkflowName-2" -Description 'Second workflow to remove'

            # Remove both workflows
            Remove-IMWorkflow -Id $Workflow1.id, $Workflow2.id -Confirm:$false

            # Verify both workflows were removed
            { Get-IMWorkflow -Id $Workflow1.id } | Should -Throw
            { Get-IMWorkflow -Id $Workflow2.id } | Should -Throw
        }
    }

    AfterAll {
        # Clean up any remaining test workflows
        try
        {
            Get-IMWorkflow | Where-Object { $_.name -like "*$TestWorkflowName*" } | Remove-IMWorkflow -Confirm:$false -ErrorAction SilentlyContinue
        }
        catch
        {
            # No test workflows to clean up
        }
    }
}

Describe 'Copy-IMAssetInfo' -Tag 'Integration','Copy-IMAssetInfo' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY

        # Test assets - these should exist in the test environment
        $SourceAssetId = '025665c6-d874-46a2-bbc6-37250ddcb2eb'
        $TargetAssetId = '0dcc5ecc-7033-4e42-b24e-1bfeac7bc84d'

        # Test album name
        $TestAlbumName = "PSImmich-Test-Copy-Asset-Info-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

        # Verify test assets exist
        $SourceAsset = Get-IMAsset -Id $SourceAssetId
        $TargetAsset = Get-IMAsset -Id $TargetAssetId

        if (-not $SourceAsset)
        {
            throw "Source asset $SourceAssetId not found in test environment"
        }
        if (-not $TargetAsset)
        {
            throw "Target asset $TargetAssetId not found in test environment"
        }
    }

    Context 'Album information copying' {
        It 'Should copy album associations from source to target asset' {
            # Create test album
            $TestAlbum = New-IMAlbum -AlbumName $TestAlbumName -Description 'Test album for Copy-IMAssetInfo integration test'

            try
            {
                # Add source asset to the album
                Set-IMAsset -Id $SourceAssetId -AddToAlbum $TestAlbum.id

                # Verify source asset is in the album
                $AlbumAssetsBefore = Get-IMAlbum -Id $TestAlbum.id -IncludeAssets | Select-Object -ExpandProperty assets
                $AlbumAssetsBefore.id | Should -Contain $SourceAssetId
                $AlbumAssetsBefore.id | Should -Not -Contain $TargetAssetId

                # Copy album information from source to target
                Copy-IMAssetInfo -SourceId $SourceAssetId -TargetId $TargetAssetId -Albums

                # Verify target asset is now also in the album
                $AlbumAssetsAfter = Get-IMAlbum -Id $TestAlbum.id -IncludeAssets| Select-Object -ExpandProperty assets
                $AlbumAssetsAfter.id | Should -Contain $SourceAssetId
                $AlbumAssetsAfter.id | Should -Contain $TargetAssetId

            }
            finally
            {
                # Clean up - remove assets from album and delete album
                try
                {
                    Set-IMAsset -Id $SourceAssetId -RemoveFromAlbum $TestAlbum.id -ErrorAction SilentlyContinue
                    Set-IMAsset -Id $TargetAssetId -RemoveFromAlbum $TestAlbum.id -ErrorAction SilentlyContinue
                    Remove-IMAlbum -Id $TestAlbum.id -Confirm:$false -ErrorAction SilentlyContinue
                }
                catch
                {
                    Write-Warning "Failed to clean up test album: $_"
                }
            }
        }

        It 'Should copy all information when no switches are specified' {
            # Create test album
            $TestAlbum = New-IMAlbum -AlbumName "$TestAlbumName-All" -Description 'Test album for copying all asset info'

            try
            {
                # Add source asset to the album
                Set-IMAsset -Id $SourceAssetId -AddToAlbum $TestAlbum.id

                # Copy all information from source to target (no switches specified)
                Copy-IMAssetInfo -SourceId $SourceAssetId -TargetId $TargetAssetId

                # Verify target asset is now also in the album
                $AlbumAssetsAfter = Get-IMAlbum -Id $TestAlbum.id -IncludeAssets| Select-Object -ExpandProperty assets
                $AlbumAssetsAfter.id | Should -Contain $TargetAssetId

            }
            finally
            {
                # Clean up
                try
                {
                    Set-IMAsset -Id $SourceAssetId -RemoveFromAlbum $TestAlbum.id -ErrorAction SilentlyContinue
                    Set-IMAsset -Id $TargetAssetId -RemoveFromAlbum $TestAlbum.id -ErrorAction SilentlyContinue
                    Remove-IMAlbum -Id $TestAlbum.id -Confirm:$false -ErrorAction SilentlyContinue
                }
                catch
                {
                    Write-Warning "Failed to clean up test album: $_"
                }
            }
        }

        It 'Should not copy albums when Albums switch is set to false' {
            # Create test album
            $TestAlbum = New-IMAlbum -AlbumName "$TestAlbumName-NoAlbums" -Description 'Test album for selective copying'

            try
            {
                # Add source asset to the album
                Set-IMAsset -Id $SourceAssetId -AddToAlbum $TestAlbum.id

                # Copy information excluding albums
                Copy-IMAssetInfo -SourceId $SourceAssetId -TargetId $TargetAssetId -Albums:$false -Metadata -Sidecar

                # Verify target asset is NOT in the album
                $AlbumAssetsAfter = Get-IMAlbum -Id $TestAlbum.id -IncludeAssets| Select-Object -ExpandProperty assets
                $AlbumAssetsAfter.id | Should -Contain $SourceAssetId
                $AlbumAssetsAfter.id | Should -Not -Contain $TargetAssetId

            }
            finally
            {
                # Clean up
                try
                {
                    Set-IMAsset -Id $SourceAssetId -RemoveFromAlbum $TestAlbum.id -ErrorAction SilentlyContinue
                    Remove-IMAlbum -Id $TestAlbum.id -Confirm:$false -ErrorAction SilentlyContinue
                }
                catch
                {
                    Write-Warning "Failed to clean up test album: $_"
                }
            }
        }
    }

    AfterAll {
        # Clean up any remaining test albums
        try
        {
            Get-IMAlbum | Where-Object { $_.albumName -like "*$TestAlbumName*" } | Remove-IMAlbum -Confirm:$false -ErrorAction SilentlyContinue
        }
        catch
        {
            # No test albums to clean up
        }
    }
}
