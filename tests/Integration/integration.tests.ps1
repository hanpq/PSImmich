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
    Context 'Connect-Immich - When no parameters are specified' {
        It -Name 'Should throw' {
            { Connect-Immich } | Should -Throw
        }
    }
    Context 'Connect-Immich - When providing Access Token' {
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
    Context -Name 'Connect-Immich - When providing Access Token and passthru is used' {
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
    Context -Name 'Connect-Immich - When providing Credentials' {
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
    Context -Name 'Connect-Immich - When providing Credentials and passthru is used' {
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
    Context -Name 'Connect-Immich - When providing Credentials it is valid and usable' {
        BeforeAll {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred
        }
        It -Name 'Credentials can be used' {
            Get-IMServerConfig
        }
    }
    Context -Name 'Get-IMSession - When no parameters are specified' {
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
    Context -Name 'Disconnect-Immich - When no parameters are specified' {
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
    Context 'Get-IMServerLicense' {
        # No way to test without a valid license
    }
    Context 'Set-IMServerLicense' {
        # No way to test without a valid license
    }
    Context 'Remove-IMServerLicense' {
        # No way to test without a valid license
    }
    Context -Name 'Get-IMServer' {
        It -Name 'Should not throw' {
            { Get-IMServer } | Should -Not -Throw
        }
    }
    Context -Name 'Get-IMServerConfig - When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMServerConfig } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServerConfig
            $ExpectedProperties = @('loginPageMessage', 'trashDays', 'userDeleteDelay', 'oauthButtonText', 'isInitialized', 'isOnboarded', 'externalDomain','mapDarkStyleUrl','mapLightStyleUrl','publicUsers')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServerFeature - When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMServerFeature } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServerFeature
            $ExpectedProperties = @('ocr','importFaces','duplicateDetection','smartSearch', 'passwordLogin', 'configFile', 'facialRecognition', 'map', 'reverseGeocoding', 'sidecar', 'search', 'trash', 'oauth', 'oauthAutoLaunch','email')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServerStatistic - When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMServerStatistic } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServerStatistic
            $ExpectedProperties = @('photos', 'videos', 'usage', 'usageByUser','usagePhotos','usageVideos')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
            $ExpectedProperties = @('userID', 'userName', 'photos', 'videos', 'usage','usagePhotos','usageVideos', 'quotaSizeInBytes')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.usagebyuser[0].PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServerVersion - When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMServerVersion } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServerVersion
            $ExpectedProperties = @('version')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMSupportedMediaType - When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMSupportedMediaType } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMSupportedMediaType
            $ExpectedProperties = @('video', 'image', 'sidecar')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMTheme - When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMTheme } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMTheme
            $ExpectedProperties = @('customCss')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServerAbout - When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMServerAbout } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            #$Result = Get-IMTheme
            #$ExpectedProperties = @('customCss')
            #Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Test-IMPing - When no parameters are specified' {
        It -Name 'Should not throw' {
            { Test-IMPing } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Test-IMPing
            $ExpectedProperties = @('responds')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
}

Describe 'Asset' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'Get-IMAsset - Specifying a single ID' {
        It -Name 'Should return a object with the correct properties' {
            $Result = Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $ExpectedProperties = @('duplicateId','hasMetadata', 'isOffline', 'checksum', 'people', 'tags', 'livePhotoVideoId', 'exifInfo', 'duration', 'isTrashed', 'isArchived', 'isFavorite', 'updatedAt', 'localDateTime', 'fileModifiedAt', 'fileCreatedAt', 'thumbhash', 'resized', 'id', 'deviceAssetId', 'ownerId', 'owner', 'deviceId', 'libraryId', 'type', 'originalPath', 'originalFileName','originalMimeType','stack','createdAt','visibility','unassignedFaces')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
        It -Name 'Should return a single object' {
            Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb' | Should -HaveCount 1
        }
        It -Name 'Should accept object from pipeline' {
            [pscustomobject]@{id = '025665c6-d874-46a2-bbc6-37250ddcb2eb' } | Get-IMAsset | Should -HaveCount 1
        }
        It -Name 'Should accept id from parameter' {
            Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb' | Should -HaveCount 1
        }
        It -Name 'Should accept id from pipeline' {
            '025665c6-d874-46a2-bbc6-37250ddcb2eb' | Get-IMAsset | Should -HaveCount 1
        }
    }
    Context -Name 'Get-IMAsset - Specifying multiple IDs' {
        It -Name 'Should accept multiple objects from pipeline' {
            @([pscustomobject]@{id = '025665c6-d874-46a2-bbc6-37250ddcb2eb' }, [pscustomobject]@{id = '025665c6-d874-46a2-bbc6-37250ddcb2eb' }) | Get-IMAsset | Should -HaveCount 2
        }
        It -Name 'Should accept multiple ids from pipeline' {
            @('025665c6-d874-46a2-bbc6-37250ddcb2eb', '025665c6-d874-46a2-bbc6-37250ddcb2eb') | Get-IMAsset | Should -HaveCount 2
        }
    }
    Context -Name 'Get-IMAsset - No parameters are specified' {
        It -Name 'Should return array' {
            Get-IMAsset | Measure-Object | Select-Object -ExpandProperty count | Should -BeGreaterThan 1
        }
    }
    Context -Name 'Set-IMAsset' {
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
            if (-not (Get-IMTag | where name -eq 'TestTag')) {
                $NewTag = New-IMTag -Name 'TestTag'
            }
            else
            {
                Get-IMTag | where name -eq 'TestTag' | Remove-IMTag
                $NewTag = New-IMTag -Name 'TestTag'
            }

        }
        AfterAll {
            Remove-IMAlbum -albumId $NewAlbum.id
            Remove-IMTag -id $NewTag.id

        }
        It -Name 'Assets gets added to album' {
            Set-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037' -AddToAlbum $NewAlbum.id
            $Result = Get-IMAlbum -albumId $NewAlbum.id -IncludeAssets
            $Result.assets | Should -HaveCount 2
            $Result.assets.id | Should -Contain '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Result.assets.id | Should -Contain '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        }
        It -Name 'Assets gets removed from album' {
            Set-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037' -RemoveFromAlbum $NewAlbum.id
            $Result = Get-IMAlbum -albumId $NewAlbum.id -IncludeAssets
            $Result.assets | Should -HaveCount 0
        }
        It -Name 'Should update asset' {
            Set-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -isFavorite:$true
            Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb' | Select-Object -ExpandProperty isFavorite | Should -BeTrue
            Set-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -isFavorite:$false
        }
        It 'Should add tag to asset' {
            $Result = Set-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -AddTag $NewTag.id
            # Seems to be a delay in the tag being added to the asset. Adding a retry loop to wait for the tag to be added.
            $retrycounter = 0
            while ((Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb').tags.id -notcontains $NewTag.id -and $retrycounter -lt 5) {
                start-sleep -seconds 2
                $retrycounter++
            }
            $Asset = Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Asset.tags.id | Should -Contain $newtag.id
        }
        It 'Should remove tag from asset' {

            # Seems to be a delay in the tag being added to the asset. Adding a retry loop to wait for the tag to be added.
            $retrycounter = 0
            while ((Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb').tags.id -notcontains $NewTag.id -and $retrycounter -lt 5) {
                start-sleep -seconds 2
                $retrycounter++
            }

            $Result = Set-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -RemoveTag $NewTag.id
            # Seems to be a delay in the tag being added to the asset. Adding a retry loop to wait for the tag to be added.

            $retrycounter = 0
            while ((Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb').tags.id -contains $NewTag.id -and $retrycounter -lt 5) {
                start-sleep -seconds 2
                $Result = Set-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -RemoveTag $NewTag.id
                $retrycounter++
            }

            $Asset = Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Asset.tags.id | Should -not -Contain $newtag.id
        }
    }
    # Import-IMAsset is excluded from testing on Windows Powershell because the
    # current routine to post formdata is not nativly supported. Until a seperate
    # routine is defined, this test is excluded.
    Context -Name 'Import-IMAsset' {
        It -Name 'Should upload the file' {
            $Result = Import-IMAsset -FilePath "$PSScriptRoot\Immich.png"
            $Result | Should -HaveCount 1
            $Result.DeviceAssetID | Should -Be 'Immich.png'
            Remove-IMAsset -Id $Result.Id -force
        }
    } #-Skip:($PSVersionTable.PSEdition -eq 'Desktop')
    Context -Name 'Restore-IMAsset' {
        It -Name 'Should restore single asset' {
            $Result = Import-IMAsset -FilePath "$PSScriptRoot\Immich.png"
            $Result | Should -HaveCount 1
            $Result.DeviceAssetID | Should -Be 'Immich.png'
            Remove-IMAsset -Id $Result.Id
            $Remove = Get-IMAsset -id $Result.id
            $Remove.isTrashed | Should -BeTrue
            Restore-IMAsset -Id $Result.Id
            $Restore = Get-IMAsset -id $Result.id
            $Restore.isTrashed | Should -BeFalse
            Start-Sleep -Seconds 1
            Remove-IMAsset -Id $Result.Id -force
        }
        It -Name 'Should restore all asset' {
            $Result = Import-IMAsset -FilePath "$PSScriptRoot\Immich.png"
            $Result | Should -HaveCount 1
            $Result.DeviceAssetID | Should -Be 'Immich.png'
            Remove-IMAsset -Id $Result.Id
            $Remove = Get-IMAsset -id $Result.id
            $Remove.isTrashed | Should -BeTrue
            Restore-IMAsset -All
            $Restore = Get-IMAsset -id $Result.id
            $Restore.isTrashed | Should -BeFalse
            Remove-IMAsset -Id $Result.Id -force
        }
    } #-Skip:($PSVersionTable.PSEdition -eq 'Desktop')
    Context 'Remove-IMAsset' {
        It -Name 'Should remove the file' {
            $Result = Import-IMAsset -FilePath "$PSScriptRoot\Immich.png"
            { Remove-IMAsset -Id $Result.Id -force } | Should -Not -Throw
        }
    } #-Skip:($PSVersionTable.PSEdition -eq 'Desktop')
    Context 'Save-IMAsset' {
        It -Name 'Should download file to disk' {
            Save-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -Path ((Get-PSDrive TestDrive).Root)
            "$((Get-PSDrive TestDrive).Root)\michael-daniels-ylUGx4g6eHk-unsplash.jpg" | Should -Exist
            Remove-Item 'TestDrive:\michael-daniels-ylUGx4g6eHk-unsplash.jpg' -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
    Context 'Update-IMAssetMetadata' {
        It -Name 'Should not throw' {
            { Update-IMAssetMetadata -id '025665c6-d874-46a2-bbc6-37250ddcb2eb' } | Should -Not -Throw
        }
    }
    Context 'Update-IMAssetThumbnail' {
        It -Name 'Should not throw' {
            { Update-IMAssetThumbnail -id '025665c6-d874-46a2-bbc6-37250ddcb2eb' } | Should -Not -Throw
        }
    }
    Context 'Get-IMAsset -Random' {
        It -Name 'Should return one object' {
            $Result = Get-IMAsset -Random
            $Result | Should -HaveCount 1
        }
        It -Name 'Should return 3 object' {
            $Result = Get-IMAsset -Random -Count 3
            $Result | Should -HaveCount 3
        }
    }
    Context 'Get-IMAssetStatistic' {
        It -Name 'Should return one object' {
            $Result = Get-IMAssetStatistic
            $Result | Should -HaveCount 1
            $Result.PSObject.Properties.Name | Should -Contain 'images'
            $Result.PSObject.Properties.Name | Should -Contain 'total'
            $Result.PSObject.Properties.Name | Should -Contain 'videos'
        }
    }
    Context 'Find-IMAsset' {
        It -Name 'Should find asset by name' {
            $Result = Find-IMAsset -originalFileName 'evgeni-evgeniev-ggVH1hoQAac-unsplash.jpg'
            $Result | Should -HaveCount 1
        }
        It -Name 'Should find asset by partial name' {
            $Result = Find-IMAsset -originalFileName 'unsp'
            $Result | Should -HaveCount 13
        }
        It -Name 'Should find all assets by paging' {
            $Result = Find-IMAsset -originalFileName 'unsp' -Size 5
            $Result | Should -HaveCount 13
        }
    }
    Context 'Search-IMAsset' {
        It -Name 'Should find road assets' {
            $Result = Search-IMAsset -Query 'Road'
            $Result.Count | should -BeGreaterThan 0
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

            $createdAfter = [datetime]"2023-03-10 13:00:00"
            $takenBefore = [datetime]"2023-03-10 13:30:00"

            $Result = Search-IMAsset -Query 'Road' -CreatedAfter $createdAfter -TakenBefore $takenBefore

            # If parameter translation worked, we get valid results
            $Result | Should -Not -BeNull
        }
    }
}

Describe 'Activity' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Get-IMActivity' {
        It -Name 'Getting activity count for album should be 4' {
            $Result = Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            $Result | Should -HaveCount 4
        }
        It -Name 'Getting activity count for album and asset should be 4' {
            $Result = Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
            $Result | Should -HaveCount 4
        }
        It -Name 'Getting activity count for album, asset and user should be 4' {
            $Result = Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf' -userId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            $Result | Should -HaveCount 4
        }
        It -Name 'Getting activity count for comments on album should be 3' {
            $Result = Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -type comment
            $Result | Should -HaveCount 3
        }
        It -Name 'Getting activity count for likes on album should be 1' {
            $Result = Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -type like
            $Result | Should -HaveCount 1
        }
    }
    Context 'Get-IMActivityStatistic' {
        It -Name 'Getting comment count for the album should be 3' {
            $Result = Get-IMActivityStatistic -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            $Result.Comments | Should -Be 3
        }
        It -Name 'Getting comment count for album and asset should be 3' {
            $Result = Get-IMActivityStatistic -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
            $Result.Comments | Should -Be 3
        }
    }
    Context 'Add-IMActivity' {
        It -Name 'Adding a comment should succeed' {
            $Result = Add-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'bdc6d2c8-6168-4a88-a51f-6da11bf8f506' -comment 'TestComment' -type comment
            Remove-IMActivity -id $Result.id
        }
    }
    Context 'Remove-IMActivity' {
        It -Name 'Removing a comment should succeed' {
            $Result = Add-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'bdc6d2c8-6168-4a88-a51f-6da11bf8f506' -comment 'TestComment' -type comment
            Remove-IMActivity -id $Result.id
            # Seems to be 50-50 chance this test fails. It might be a timing issue, trying to delay the verification half a seconds.
            Start-Sleep -Milliseconds 500
            Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'bdc6d2c8-6168-4a88-a51f-6da11bf8f506' | Should -BeNullOrEmpty
        }
    }
}

Describe 'Album' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Get-IMAlbumStatistic' {
        It -Name 'get' {
            $Result = Get-IMAlbumStatistic
            $Result.owned | Should -Be 1
            $Result.shared | Should -Be 1
            $Result.notShared | Should -Be 0
        }
    }
    Context 'Get-IMAlbum' {
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
            $Result.Id | should -contain 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            $Result | should -havecount 1
        }
        It -Name 'list-name incorrect name' {
            $Result = Get-IMAlbum -Name 'NewYork'
            $Result | should -havecount 0
        }
        It -Name 'list-searchstring expect find' {
            $Result = Get-IMAlbum -SearchString 'Test*'
            $Result.Id | should -contain 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
            $Result | should -havecount 1
        }
        It -Name 'list-searchstring do not expect find' {
            $Result = Get-IMAlbum -Searchstring 'NewYork*'
            $Result | should -havecount 0
        }
        It -Name 'list-shared-false' {
            $Result = Get-IMAlbum -Shared:$false | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 0
        }
        It -Name 'list-assetid' {
            $Result = Get-IMAlbum -assetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf' | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 1
        }
        It -Name 'list-id with assets' {
            $Result = Get-IMAlbum -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -IncludeAssets | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 1
            $Result.Assets | Should -Not -BeNullOrEmpty
        }
        It -Name 'list-id without assets' {
            $Result = Get-IMAlbum -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
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
    Context 'New-IMAlbum' {
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
            $NewAlbum = New-IMAlbum -albumName $AlbumName -assetIds 'a4908e1f-697f-4d7b-9330-93b5eabe3baf' -description $AlbumName
            $Result = Get-IMAlbum -albumId $NewAlbum.id -IncludeAssets
            $Result | Should -HaveCount 1
            $Result.Description | Should -Be $AlbumName
            $Result.albumName | Should -Be $AlbumName
            $Result.Assets | Should -HaveCount 1
            Remove-IMAlbum -albumId $NewAlbum.id
        }
        AfterAll {
            Get-IMAlbum | Where-Object { $_.AlbumName -eq $AlbumName } | Remove-IMAlbum
        }
    }
    Context 'Remove-IMAlbum' {
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
            $NewAlbum = New-IMAlbum -albumName $AlbumName -assetIds 'a4908e1f-697f-4d7b-9330-93b5eabe3baf' -description $AlbumName
            Remove-IMAlbum -albumId $NewAlbum.id
            { Get-IMAlbum -albumId $NewAlbum.id } | Should -Throw
        }
    }
    Context 'Set-IMAlbum' {
        BeforeAll {
            if ($env:CI)
            {
                $AlbumName = $env:GITHUB_RUN_ID
            }
            else
            {
                $AlbumName = HOSTNAME.EXE
            }
            $NewAlbum = New-IMAlbum -albumName $AlbumName
        }
        AfterAll {
            Remove-IMAlbum -albumId $NewAlbum.id
        }
        It -Name 'Assets gets added to album' {
            Set-IMAlbum -id $NewAlbum.id -AddAssets '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
            $Result = Get-IMAlbum -albumId $NewAlbum.id -IncludeAssets
            $Result.assets | Should -HaveCount 2
            $Result.assets.id | Should -Contain '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Result.assets.id | Should -Contain '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        }
        It -Name 'Assets gets removed from album' {
            Set-IMAlbum -id $NewAlbum.id -RemoveAssets '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
            $Result = Get-IMAlbum -albumId $NewAlbum.id -IncludeAssets
            $Result.assets | Should -HaveCount 0
        }
        It -Name 'Album gets updated' {
            Set-IMAlbum -albumid $NewAlbum.id -description "$($AlbumName)New"
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result | Should -HaveCount 1
            $Result.Description | Should -Be "$($AlbumName)New"
        }
        It -Name 'Album gets a new name' {
            Rename-IMAlbum -albumid $NewAlbum.id -NewName "$($AlbumName)New"
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result | Should -HaveCount 1
            $Result.albumName | Should -Be "$($AlbumName)New"
        }
    }
    Context 'Add-IMAlbumUser' {
        BeforeAll {
            if ($env:CI)
            {
                $AlbumName = $env:GITHUB_RUN_ID
            }
            else
            {
                $AlbumName = HOSTNAME.EXE
            }
            $NewAlbum = New-IMAlbum -albumName $AlbumName
        }
        It -Name 'Users gets added to album as viewer' {
            Add-IMAlbumUser -albumId $NewAlbum.id -userId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result.albumUsers.user | Should -HaveCount 1
            $Result.albumUsers.user.id | Should -Contain '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
        }
        AfterAll {
            Get-IMAlbum | Where-Object { $_.AlbumName -eq $AlbumName } | Remove-IMAlbum
        }
    }

    Context 'Set-IMAlbumUser' {
        BeforeAll {
            if ($env:CI)
            {
                $AlbumName = $env:GITHUB_RUN_ID
            }
            else
            {
                $AlbumName = HOSTNAME.EXE
            }
            $NewAlbum = New-IMAlbum -albumName $AlbumName
        }
        It -Name 'Users gets added to album as viewer and changed to editor' {
            Add-IMAlbumUser -albumId $NewAlbum.id -userId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d' -Role viewer
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result.albumUsers[0].role | Should -be 'viewer'
            Set-IMAlbumUser -albumid $NewAlbum.id -userId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d' -Role editor
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result.albumUsers[0].role | Should -be 'editor'
        }
        AfterAll {
            Get-IMAlbum | Where-Object { $_.AlbumName -eq $AlbumName } | Remove-IMAlbum
        }
    }


    Context 'Remove-IMAlbumUser' {
        BeforeAll {
            if ($env:CI)
            {
                $AlbumName = $env:GITHUB_RUN_ID
            }
            else
            {
                $AlbumName = HOSTNAME.EXE
            }
            $NewAlbum = New-IMAlbum -albumName $AlbumName -albumUsers @{userId = '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d';role='editor'}
        }
        It -Name 'Users gets removed from album' {
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result.albumUsers.user.id | Should -Contain '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            Remove-IMAlbumUser -albumId $NewAlbum.id -userId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result.albumUsers.user | Should -Not -contain '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
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
    Context 'Get-IMAPIKey' {
        It 'Retreives one api-key when using ID' {
            $Result = Get-IMAPIKey -id 'a1c2b770-3c58-46d9-ac6d-2e6d03d870e2'
            $Result | Should -HaveCount 1
        }
    }
    Context 'New-IMAPIKey' {
        It 'Should create a new api-key' {
            $Result = New-IMAPIKey -name $KeyName -Permission all
            $Result.secret | Should -Not -BeNullOrEmpty
            Get-IMAPIKey -id $Result.apiKey.id | Should -HaveCount 1
            Remove-IMAPIKey -id $Result.apiKey.id
        }
        It 'Should create a new api-key with multiple permissions' {
            $Result = New-IMAPIKey -name $KeyName -Permission "activity.create", "activity.read", "activity.update"
            $Result.secret | Should -Not -BeNullOrEmpty
            Get-IMAPIKey -id $Result.apiKey.id | Should -HaveCount 1
            Remove-IMAPIKey -id $Result.apiKey.id
        }
    }
    Context 'Set-IMAPIKey' {
        It 'Should set a new name' {
            $Result = New-IMAPIKey -name $KeyName -Permission all
            Rename-IMAPIKey -id $Result.apiKey.id -name "$($KeyName)_New"
            $Result = Get-IMAPIKey -id $Result.apiKey.id
            $Result.Name | Should -Be "$($KeyName)_New"
            Remove-IMAPIKey -id $Result.id
        }
    }
    Context 'Remove-IMAPIKey' {
        It 'Should remove the api key' {
            $Result = New-IMAPIKey -name $KeyName -Permission all
            Remove-IMAPIKey -id $Result.apiKey.id
            { Get-IMAPIKey -id $Result.apiKey.id } | Should -Throw
        }
    }
}

Describe 'Auth' -Tag 'Integration' {
    Context 'Test-IMAccessToken' {
        It 'Should return true' {
            # Using credential instead of API-key to get a current device
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred
            Test-IMAccessToken | Should -BeTrue
        }
    }
}

Describe 'AuthSession' -Tag 'Integration' {
    Context 'Get-IMAuthSession' {
        It 'Should return sessions' {
            $Result = Get-IMAuthSession | Where-Object { $_.current -eq $true }
            $Result | Should -HaveCount 1
        }
    }
    Context 'Remove-IMAuthSession' {
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
    Context -Name 'Get-IMFace' {
        It 'Should return faces' {
            $Result = Get-IMFace -id 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'
            $Result | Should -HaveCount 5
        }
    }
}

Describe 'Job' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'Get-IMJob' {
        It 'Should return 1 object' {
            $Result = Get-IMJob
            $Result | Should -HaveCount 1
        }
    }
    Context -Name 'Start-IMJob' {
        It 'Should start job' {
            $Result = Start-IMJob -Job 'thumbnailGeneration'
            $Result.jobCounts.active + $Result.jobCounts.waiting | Should -Be 1
        }
        It 'Should start emptyTrash job' {
            $Result = Import-IMAsset -FilePath "$PSScriptRoot\Immich.png"
            $Result | Should -HaveCount 1
            $Result.DeviceAssetID | Should -Be 'Immich.png'
            Remove-IMAsset -Id $Result.Id
            $Remove = Get-IMAsset -id $Result.id
            $Remove.isTrashed | Should -BeTrue
            $Result = Start-IMJob -Job 'emptyTrash'
            { Get-IMAsset -id $Result.id } | Should -Throw
        }
    }
}

Describe 'Partner' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Add-IMPartner' {
        It 'Should add a partner' {
            $Add = Add-IMPartner -id '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            $Result = Get-IMPartner -Direction shared-by
            $Result | Should -HaveCount 1
        }
    }
    <# Needs to be run for the partner account
    Context 'Set-IMPartner' {
        It 'Should set timeline on partner' {
            $Set = Set-IMPartner -id '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d' -EnableTimeline
            $Result = Get-IMPartner -Direction shared-by
            $Result | Should -HaveCount 1
            $Result.inTimeline | Should -BeTrue
        }
    }
    #>
    Context 'Get-IMPartner' {
        It 'Should return one person object' {
            $Result = Get-IMPartner -Direction shared-by
            $Result | Should -HaveCount 1
        }
    }
    Context 'Remove-IMPartner' {
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
    Context 'New-IMPerson' {
        It 'Should create a new person' {
            $New = New-IMPerson -Name 'TestPerson'
            $Result = Get-IMPerson -id $New.id
            $Result | Should -HaveCount 1
            $Result.name | Should -Be 'TestPerson'
        }
    }
    Context 'Get-IMPerson' {
        It 'Should return person' {
            { $PersonList = Get-IMPerson } | Should -Not -Throw
        }
    }
    Context 'Set-IMPerson' {
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
    Context 'Find-IMAsset' {
        It 'Should return multiple assets with correct type' {
            $Result = Find-IMAsset
            $Result | measure-object | select-object -ExpandProperty count | should -BeGreaterThan 1
            $Result[0].PSObject.TypeNames | should -contain 'PSImmich.ObjectType.IMAsset'
        }
    }
}

Describe 'Library' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'New-IMLibrary' {
        It 'Should create library' {
            $New = New-IMLibrary -name 'TestLibrary' -exclusionPatterns '*/*' -ImportPath '/mnt/media/pictures' -ownerId 'fb95c457-7685-428c-b850-2fd60345819c'
            $Result = Get-IMLibrary -id $New.id
            $Result | Should -HaveCount 1
            $Result.Name | Should -Be 'TestLibrary'
            Remove-IMLibrary -id $New.id
        }
    }
    Context 'Get-IMLibrary' {
        BeforeAll {
            $NewLibrary = New-IMLibrary -name 'TestLibrary' -exclusionPatterns '*/*' -ImportPath '/mnt/media/pictures' -ownerId 'fb95c457-7685-428c-b850-2fd60345819c'
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
    Context 'Remove-IMLibrary' {
        It 'Should remove library' {
            $New = New-IMLibrary -name 'TestLibrary' -exclusionPatterns '*/*' -ImportPath '/mnt/media/pictures' -ownerId 'fb95c457-7685-428c-b850-2fd60345819c'
            { Remove-IMLibrary -id $New.id } | Should -Not -Throw
        }
    }
    Context 'Set-IMLibrary' {
        It 'Should update library' {
            $New = New-IMLibrary -name 'TestLibrary' -exclusionPatterns '*/*' -ImportPath '/mnt/media/pictures' -ownerId 'fb95c457-7685-428c-b850-2fd60345819c'
            $Updated = Set-IMLibrary -id $New.id -Name 'TestLibrary2'
            $Result = Get-IMLibrary -id $New.id
            $Result | Should -HaveCount 1
            $Result.Name | Should -Be 'TestLibrary2'
            Remove-IMLibrary -id $New.id
        }
    }
    Context 'Sync-IMLibrary' {
        It 'Should not throw' {
            $New = New-IMLibrary -name 'TestLibrary' -exclusionPatterns '*/*' -ImportPath '/mnt/media/pictures' -ownerId 'fb95c457-7685-428c-b850-2fd60345819c'
            { Sync-IMLibrary -id $New.id } | Should -Not -Throw
            Remove-IMLibrary -id $New.id
        }
    }
    Context 'Test-IMLibrary' {
        It 'Should not throw' {
            $New = New-IMLibrary -name 'TestLibrary' -exclusionPatterns '*/*' -ImportPath '/mnt/media/pictures' -ownerId 'fb95c457-7685-428c-b850-2fd60345819c'
            { Test-IMLibrary -id $New.id } | Should -Not -Throw
            Remove-IMLibrary -id $New.id
        }
    }
}

Describe 'ServerConfig' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Get-IMConfig' {
        It 'Should return applied config' {
            $Result = Get-IMConfig
            $Result | Should -HaveCount 1
        }
        It 'Should return applied config raw' {
            $Result = Get-IMConfig -ReturnRawJSON
            { $Result | ConvertFrom-Json } | Should -Not -Throw
        }
        It 'Should return default config' {
            $Result = Get-IMConfig -Default
            $Result | Should -HaveCount 1
        }
        It 'Should return default config raw' {
            $Result = Get-IMConfig -Default -ReturnRawJSON
            { $Result | ConvertFrom-Json } | Should -Not -Throw
        }
        It 'Should return storage template config' {
            $Result = Get-IMConfig -StorageTemplate
            $Result | Should -HaveCount 1
        }
        It 'Should update setting' {
            $Result = Get-IMConfig
            $Result.reverseGeocoding.enabled = $false
            Set-IMConfig -RawJson ($Result | ConvertTo-Json -Depth 10)
            $ResultNew = Get-IMConfig
            $ResultNew.reverseGeocoding.enabled | Should -BeFalse
            $Result.reverseGeocoding.enabled = $true
            Set-IMConfig -RawJson ($Result | ConvertTo-Json -Depth 10)
        }
    }
}

Describe 'Tag' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        Get-IMTag | Where-Object { $_.name -eq 'TestTag' } | Remove-IMTag
    }
    Context 'New-IMTag' {
        It 'Should create a new tag' {
            $Result = New-IMTag -Name 'TestTag'
            $Result | Should -HaveCount 1
            Remove-IMTag -Id $Result.id
        }
    }
    Context 'Get-IMTag' {
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
    Context 'Remove-IMTag' {
        It 'Should remove tag' {
            $New = New-IMTag -Name 'TestTag'
            Remove-IMTag -Id $New.id
            { Get-IMTag -id $New.id } | Should -Throw
        }
    }
    Context 'Set-IMTag' {
        BeforeAll {
            $NewTag = New-IMTag -Name 'TestTag'
        }
        AfterAll {
            Remove-IMTag -id $NewTag.id
        }
        It 'Should add tag to asset' {
            $Result = Set-IMTag -Id $NewTag.id -AddAssets '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Asset = Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Asset.tags.id | Should -Contain $newtag.id
        }
        It 'Get-IMAsset -TagId should return tagged asset' {
            $Result = Get-IMAsset -TagId $NewTag.id
            $Result.id | Should -Contain '025665c6-d874-46a2-bbc6-37250ddcb2eb'
        }
        It 'Should remove tag from asset' {
            $Result = Set-IMTag -id $NewTag.id -RemoveAssets '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Asset = Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb'

            # Don't know if it is a bug or not but according to the integration tests it seems 50/50
            # if the tag is removed. To pass tests for the powershell module we will make a few atempts.
            $Tries = 0
            while ($Asset.tags -and $Tries -le 10) {
                Start-Sleep -Seconds 1
                $Result = Set-IMTag -id $NewTag.id -RemoveAssets '025665c6-d874-46a2-bbc6-37250ddcb2eb'
                $Asset = Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb'
                $Tries++
            }

            $Asset.tags.id | Should -not -Contain $newtag.id
        }
        It 'Should set color' {
            $Result = Set-IMTag -id $NewTag.id -Color '#008000'
            $Result | should -not -BeNullOrEmpty
        }
    }
}

Describe 'Timeline' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Get-IMTimeBucket' {
        It -Name 'Should return 3 objects' {
            $Result = Get-IMTimeBucket
            $Result | Should -HaveCount 3
        }
        It -Name 'Should return 1 object' {
            $Result = Get-IMTimeBucket -timeBucket '2024-03-01 00:00:00'
            $Result.id | Should -HaveCount 12
        }
    }
}

Describe 'Map' -Tag 'Integration' {
    Context 'Convert-IMCoordinatesToLocation' {
        It 'Should return location of Kensington' {
            $Result = Convert-IMCoordinatesToLocation -Latitude 51.496637 -Longitude -0.176370
            $Result.country | should -be 'United Kingdom'
            $Result.state | should -be 'England'
            $Result.city | should -be 'Kensington'
        }
    }
}

Describe 'Duplicate' -Tag 'Integration' {
    Context 'Get-IMDuplicate' {
        It 'Should no throw' {
            {Get-IMDuplicate} | should -not -throw
        }
    }
}

Describe 'User' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context 'Get-IMUser' {
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
            $Result = Get-IMUser -me
            $Result | Should -HaveCount 1
            $Result.name | Should -Be 'Hannes Palmquist'
        }
    }
    Context 'Get-IMUserPreference' {
        It 'Should list self' {
            $Result = Get-IMUserPreference
            $Result.PSObject.Properties.Name | should -Contain 'albums'
            $Result.PSObject.Properties.Name | should -Contain 'folders'
            $Result.PSObject.Properties.Name | should -Contain 'memories'
            $Result.PSObject.Properties.Name | should -Contain 'people'
            $Result.PSObject.Properties.Name | should -Contain 'sharedLinks'
            $Result.PSObject.Properties.Name | should -Contain 'ratings'
            $Result.PSObject.Properties.Name | should -Contain 'tags'
            $Result.PSObject.Properties.Name | should -Contain 'emailNotifications'
            $Result.PSObject.Properties.Name | should -Contain 'download'
            $Result.PSObject.Properties.Name | should -Contain 'purchase'
            $Result.PSObject.Properties.Name | should -Contain 'cast'
            $Result | Should -HaveCount 1
        }
        It 'Should list specific user' {
            $Result = Get-IMUserPreference -id 'fb95c457-7685-428c-b850-2fd60345819c'
            $Result.PSObject.Properties.Name | should -Contain 'albums'
            $Result.PSObject.Properties.Name | should -Contain 'folders'
            $Result.PSObject.Properties.Name | should -Contain 'memories'
            $Result.PSObject.Properties.Name | should -Contain 'people'
            $Result.PSObject.Properties.Name | should -Contain 'sharedLinks'
            $Result.PSObject.Properties.Name | should -Contain 'ratings'
            $Result.PSObject.Properties.Name | should -Contain 'tags'
            $Result.PSObject.Properties.Name | should -Contain 'emailNotifications'
            $Result.PSObject.Properties.Name | should -Contain 'download'
            $Result.PSObject.Properties.Name | should -Contain 'purchase'
            $Result.PSObject.Properties.Name | should -Contain 'cast'
            $Result | Should -HaveCount 1
        }
    }
    Context 'Set-IMUserPreference' {
        BeforeEach {
            Set-IMUserPreference -Id 'fb95c457-7685-428c-b850-2fd60345819c' -EmailNotificationEnabled:$true
        }
        AfterEach {
            Set-IMUserPreference -Id 'fb95c457-7685-428c-b850-2fd60345819c' -EmailNotificationEnabled:$true
        }
        It 'Should change setting for user when using id' {
            Set-IMUserPreference -Id 'fb95c457-7685-428c-b850-2fd60345819c' -EmailNotificationEnabled:$false
            $Result = Get-IMUserPreference
            $Result.emailNotifications.enabled | should -befalse
        }
        It 'Should change setting for user when using pipe' {
            Get-IMUser -Id 'fb95c457-7685-428c-b850-2fd60345819c' | `
            Set-IMUserPreference -EmailNotificationEnabled:$false
            $Result = Get-IMUserPreference
            $Result.emailNotifications.enabled | should -befalse
        }
    }
    Context 'New-IMUser' {
        It 'Should create user' {
            $New = New-IMUser -email 'test@domain.com' -Name 'TestUser' -password (ConvertTo-SecureString -String 'test' -AsPlainText -Force)
            $Result = Get-IMUser -Id $New.id
            $Result | Should -HaveCount 1
            $Result.email | Should -Be 'test@domain.com'
            $Result.name | Should -Be 'TestUser'
        }
    }
    Context 'Set-IMUser' {
        It 'Should update user' {
            $Get = Get-IMUser | Where-Object { $_.email -eq 'test@domain.com' }
            $Updated = Set-IMUser -id $Get.id -Name 'test user'
            $Result = Get-IMUser -id $Get.id
            $Result.name | Should -BeExactly 'test user'
        }
    }
    Context 'Add-IMMyProfilePicture' {
        It 'Should add profile picture' {
            { $Result = Add-IMMyProfilePicture -FilePath "$PSScriptRoot\Immich.png" } | Should -Not -Throw
        }
    }
    Context 'Remove-IMMyProfilePicture' {
        It 'Should remove profile picture' -skip:($PSVersionTable.PSEdition -eq 'Desktop') {
            { $Result = Remove-IMMyProfilePicture } | Should -Not -Throw
        }
    }
    Context 'Remove-IMUser' {
        It 'Should remove user' {
            $Get = Get-IMUser | Where-Object { $_.email -eq 'test@domain.com' }
            Remove-IMUser -id $get.id -force
        }
    }
}

Describe 'SharedLink' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        Get-IMSharedLink | Remove-IMSharedLink
    }
    Context 'New-IMSharedLink' {
        It 'Should create asset shared link' {
            $NewAssetLink = New-IMSharedLink -AssetId '6d178c17-71f1-4231-a225-f4ffe55d24a5' -allowupload -expiresat ((Get-Date).AddDays(3)) -showmetadata
            $NewAssetLink | Should -HaveCount 1
        }
        It 'Should create album shared link' {
            $NewAlbumLink = New-IMSharedLink -AlbumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -allowupload -expiresat ((Get-Date).AddDays(3)) -showmetadata
            $NewAlbumLink | Should -HaveCount 1
        }
    }
    Context 'Get-IMSharedLink' {
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
    Context 'Set-IMSharedLink' {
        It 'Should update setting on asset shared link' {
            $ExistingSharedLink = Get-IMSharedLink
            $ExistingSharedLink | Set-IMSharedLink -AllowUpload:$false
            $Result = Get-IMSharedLink
            $Result.AllowUpload | Should -Not -Contain $true
        }
    }

    Context 'Add-IMSharedLinkAsset' {
        It 'Should add asset to shared link' {
            $SharedLink = Get-IMSharedLink | Where-Object { $_.type -eq 'INDIVIDUAL' }
            $Add = Add-IMSharedLinkAsset -sharedlinkid $SharedLink.id -id '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
            $Get = Get-IMSharedLink -id $SharedLink.id
            $Get.Assets.Id | Should -Contain '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        }
    }

    Context 'Remove-IMSharedLinkAsset' -Skip:$true{
        It 'Should remove asset from shared link' {
            # API broken in 1.127.X.
            $SharedLink = Get-IMSharedLink | Where-Object { $_.type -eq 'INDIVIDUAL' }
            $IdToRemove = [array]($SharedLink.Assets.Id) | Get-Random -Count 1
            $Remove = Remove-IMSharedLinkAsset -sharedlinkid $Sharedlink.id -id $IdToRemove
            $Get = Get-IMSharedLink -id $SharedLink.id
            [array]($Get.assets.id) | Should -Not -Contain $IdToRemove
        }
    }

    Context 'Remove-IMSharedLink' {
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

    Context 'Get-IMStack - List all stacks' {
        It 'Should return stacks when none exist' {
            $Result = Get-IMStack
            $Result | Should -BeNullOrEmpty
        }
    }

    Context 'New-IMStack - Create new stack' {
        It 'Should create a new stack with multiple assets' {
            $Result = New-IMStack -AssetIds 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c','a4908e1f-697f-4d7b-9330-93b5eabe3baf'
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Match '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$'
            $Result.Assets | Should -HaveCount 2
            $Result.PrimaryAssetId | Should -Be 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'
        }
    }

    Context 'Get-IMStack - Retrieve specific stack' {
        It 'Should return stack by ID' {
            $StackId = Get-IMStack | where {$_.assets.id -contains 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'} | select -expand id
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
            $StackId = Get-IMStack | where {$_.assets.id -contains 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'} | select -expand id
            $Result = Get-IMStack
            $Result | Should -HaveCount 1
            $Result[0].Id | Should -Be $StackId
        }
    }

    Context 'Set-IMStack - Update stack' {
        It 'Should update primary asset of stack' {
            $StackId = Get-IMStack | where {$_.assets.id -contains 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'} | select -expand id
            $Result = Set-IMStack -Id $StackId -PrimaryAssetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
            $Result | Should -Not -BeNullOrEmpty
            $Result.PrimaryAssetId | Should -Be 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'

            # Verify the change persisted
            $Verify = Get-IMStack -Id $StackId
            $Verify.PrimaryAssetId | Should -Be 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
        }
    }

    Context 'Remove-IMStackAsset - Remove asset from stack' {
        It 'Should remove an asset from the stack' {
            $StackId = Get-IMStack | where {$_.assets.id -contains 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'} | select -expand id

            # Remove the third asset
            Remove-IMStackAsset -StackId $StackId -AssetId 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c' -Force

            # Verify asset was removed
            $Verify = Get-IMStack -Id $StackId
            $Verify.Assets.Id | Should -Not -Contain 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c'
            $Verify.Assets | Should -HaveCount 1
        }
    }

    Context 'Remove-IMStack - Delete stack' {
        It 'Should remove a single stack' {
            $StackId = Get-IMStack | where {$_.assets.id -contains 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'} | select -expand id
            Remove-IMStack -Id $StackId -Force

            # Verify stack was removed
            { Get-IMStack -Id $StackId } | Should -Throw
        }

        It 'Should remove multiple stacks in bulk' {
            $Stack1 = New-IMStack -AssetIds 'd54f1eb3-076f-4c5b-a9e6-61c694559e3c','a4908e1f-697f-4d7b-9330-93b5eabe3baf'
            $Stack2 = New-IMStack -AssetIds 'bdc6d2c8-6168-4a88-a51f-6da11bf8f506','a4908e1f-697f-4d7b-9330-93b5eabe3baf'
            Remove-IMStack -Id $Stack1.Id, $Stack2.Id -Force

            # Verify stacks were removed
            $Result = Get-IMStack
            $Result | Should -BeNullOrEmpty
        }
    }

    AfterAll {
        # Clean up any remaining stacks (but leave the existing test assets intact)
        try {
            Get-IMStack | Remove-IMStack -Force -ErrorAction SilentlyContinue
        } catch {
            # No stacks to clean up
        }
    }
}
