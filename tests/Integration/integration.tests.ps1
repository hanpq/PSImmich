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

Describe 'ServerInfo' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
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
            $ExpectedProperties = @('LoginPageMessage', 'trashDays', 'userDeleteDelay', 'oauthButtonText', 'isInitialized', 'isOnboarded', 'ExternalDomain')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServerFeature - When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMServerFeature } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServerFeature
            $ExpectedProperties = @('smartSearch', 'passwordLogin', 'configFile', 'facialRecognition', 'map', 'reverseGeocoding', 'sidecar', 'search', 'trash', 'oauth', 'oauthAutoLaunch')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServerInfo - When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMServerInfo } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServerInfo
            $ExpectedProperties = @('diskSize', 'diskUse', 'diskAvailable', 'diskSizeRaw', 'diskUseRaw', 'diskAvailableRaw', 'diskUsagePercentage')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
    Context -Name 'Get-IMServerStatistic - When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMServerStatistic } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServerStatistic
            $ExpectedProperties = @('photos', 'videos', 'usage', 'usageByUser')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
            $ExpectedProperties = @('userID', 'userName', 'photos', 'videos', 'usage', 'quotaSizeInBytes')
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
            $ExpectedProperties = @('hasMetadata', 'isReadOnly', 'isOffline', 'isExternal', 'stackCount', 'checksum', 'people', 'tags', 'livePhotoVideoId', 'smartInfo', 'exifInfo', 'duration', 'isTrashed', 'isArchived', 'isFavorite', 'updatedAt', 'localDateTime', 'fileModifiedAt', 'fileCreatedAt', 'thumbhash', 'resized', 'id', 'deviceAssetId', 'ownerId', 'owner', 'deviceId', 'libraryId', 'type', 'originalPath', 'originalFileName')
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
    Context -Name 'Get-IMCuratedLocation - Specifying a single ID' {
        It -Name 'Should return a object with the correct properties' {
            $Result = Get-IMCuratedLocation
            $ExpectedProperties = @('id', 'city', 'resizePath', 'deviceAssetId', 'deviceId')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
        It -Name 'Should return a single object' {
            Get-IMCuratedLocation | Should -HaveCount 1
        }
    }
    Context -Name 'Get-IMCuratedObject - Specifying a single ID' {
        <#
        It -Name 'Should return a object with the correct properties' {
            $Result = Get-IMCuratedObject
            $ExpectedProperties = @('id', 'city', 'resizePath', 'deviceAssetId', 'deviceId')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
        It -Name 'Should return a single object' {
            Get-IMCuratedObject | Should -HaveCount 1
        }
        #>
    }
    Context -Name 'Set-IMAsset - Specifying a single ID' {
        It -Name 'Should update asset' {
            Set-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -isFavorite:$true
            Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb' | Select-Object -ExpandProperty isFavorite | Should -BeTrue
            Set-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -isFavorite:$false
        }
    }
    # Add-IMAsset is excluded from testing on Windows Powershell because the
    # current rutine to post formdata is not nativly supported. Until a seperate
    # routine is defined, this test is excluded.
    Context -Name 'Add-IMAsset' -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
        It -Name 'Should upload the file' {
            $Result = Add-IMAsset -FilePath "$PSScriptRoot\Immich.png"
            $Result | Should -HaveCount 1
            $Result.DeviceAssetID | Should -Be 'Immich.png'
            Remove-IMAsset -Id $Result.Id -force
        }
    }
    Context 'Remove-IMAsset' -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
        It -Name 'Should remove the file' {
            $Result = Add-IMAsset -FilePath "$PSScriptRoot\Immich.png"
            Remove-IMAsset -Id $Result.Id -force
            # Seems to be 50-50 chance this test fails. It might be a timing issue, trying to delay the verification half a seconds.
            Start-Sleep -Milliseconds 1000
            { Get-IMAsset -id $Result.Id } | Should -Throw
        }
    }
    Context 'Save-IMAsset' {
        It -Name 'Should download file to disk' {
            Save-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -Path ((Get-PSDrive TestDrive).Root)
            "$((Get-PSDrive TestDrive).Root)\michael-daniels-ylUGx4g6eHk-unsplash.jpg" | Should -Exist
            Remove-Item 'TestDrive:\michael-daniels-ylUGx4g6eHk-unsplash.jpg' -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
    Context 'Start-IMAssetJob' {
        It -Name 'Should not throw' {
            { Start-IMAssetJob -id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -JobName 'refresh-metadata' } | Should -Not -Throw
        }
    }
    Context 'Get-IMAssetMemoryLane' {
        It -Name 'Should return one object' {
            $Result = Get-IMAssetMemoryLane -Day 10 -Month 3
            $Result | Should -HaveCount 1
        }
    }
    Context 'Get-IMRandomAsset' {
        It -Name 'Should return one object' {
            $Result = Get-IMRandomAsset
            $Result | Should -HaveCount 1
        }
        It -Name 'Should return 3 object' {
            $Result = Get-IMRandomAsset -Count 3
            $Result | Should -HaveCount 3
        }
    }
    Context 'Get-IMAssetSearchTerm' {
        It -Name 'Should return "image"' {
            $Result = Get-IMAssetSearchTerm
            $Result | Should -Be 'image'
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
    Context Get-IMAlbum {
        It -Name 'list-shared' {
            $Result = Get-IMAlbum | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 1
        }
        It -Name 'list-shared-true' {
            $Result = Get-IMAlbum -shared:$true | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 1
        }
        It -Name 'list-shared-false' {
            $Result = Get-IMAlbum -shared:$false | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 0
        }
        It -Name 'list-assetid' {
            $Result = Get-IMAlbum -assetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf' | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 1
        }
        It -Name 'list-id' {
            $Result = Get-IMAlbum -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
            $Result | Should -HaveCount 1
            $Result.Assets | Should -Not -BeNullOrEmpty
        }
        It -Name 'list-id-withoutassets' {
            $Result = Get-IMAlbum -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -withoutAssets | Where-Object { $_.id -eq 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }
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
    Context 'Get-IMAlbumCount' -Skip:([boolean]($env:CI)) {
        It -Name 'Gets correct count' {
            $Result = Get-IMAlbumCount
            $Result.owned | Should -Be 1
            $Result.shared | Should -Be 1
            $Result.notShared | Should -Be 0
        }
    }
    Context New-IMAlbum {
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
            $Result = Get-IMAlbum -albumId $NewAlbum.id
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
        }
        It -Name 'Album gets updated' {
            $NewAlbum = New-IMAlbum -albumName $AlbumName
            Set-IMAlbum -albumid $NewAlbum.id -description "$($AlbumName)New" -albumName "$($AlbumName)New"
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result | Should -HaveCount 1
            $Result.Description | Should -Be "$($AlbumName)New"
            $Result.albumName | Should -Be "$($AlbumName)New"
            Remove-IMAlbum -albumId $NewAlbum.id
        }
        AfterAll {
            Get-IMAlbum | Where-Object { $_.AlbumName -eq $AlbumName } | Remove-IMAlbum
        }
    }
    Context Add-IMAlbumAsset {
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
        It -Name 'Assets gets added to album' {
            $NewAlbum = New-IMAlbum -albumName $AlbumName
            Add-IMAlbumAsset -albumId $NewAlbum.id -assetId '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result.assets | Should -HaveCount 2
            $Result.assets.id | Should -Contain '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $Result.assets.id | Should -Contain '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
            Remove-IMAlbum -albumId $NewAlbum.id
        }
        AfterAll {
            Get-IMAlbum | Where-Object { $_.AlbumName -eq $AlbumName } | Remove-IMAlbum
        }
    }
    Context Remove-IMAlbumAsset {
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
        It -Name 'Assets gets removed from album' {
            $NewAlbum = New-IMAlbum -albumName $AlbumName
            Add-IMAlbumAsset -albumId $NewAlbum.id -assetId '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result.assets | Should -HaveCount 2
            Remove-IMAlbumAsset -albumId $NewAlbum.id -assetId '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result.assets | Should -HaveCount 0
            Remove-IMAlbum -albumId $NewAlbum.id
        }
        AfterAll {
            Get-IMAlbum | Where-Object { $_.AlbumName -eq $AlbumName } | Remove-IMAlbum
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
        It -Name 'Users gets added to album' {
            Add-IMAlbumUser -albumId $NewAlbum.id -userId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result.sharedUsers | Should -HaveCount 1
            $Result.sharedUsers.id | Should -Contain '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
        }
        AfterAll {
            Get-IMAlbum | Where-Object { $_.AlbumName -eq $AlbumName } | Remove-IMAlbum
        }
    }
    Context Remove-IMAlbumUser {
        BeforeAll {
            if ($env:CI)
            {
                $AlbumName = $env:GITHUB_RUN_ID
            }
            else
            {
                $AlbumName = HOSTNAME.EXE
            }
            $NewAlbum = New-IMAlbum -albumName $AlbumName -sharedWithUserIds '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
        }
        It -Name 'Users gets removed from album' {
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result.sharedUsers.id | Should -Contain '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            Remove-IMAlbumUser -albumId $NewAlbum.id -userId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
            $Result = Get-IMAlbum -albumId $NewAlbum.id
            $Result.sharedUsers | Should -HaveCount 0
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
            $Result = New-IMAPIKey -Name $KeyName
            $Result.secret | Should -Not -BeNullOrEmpty
            Get-IMAPIKey -id $Result.apiKey.id | Should -HaveCount 1
            Remove-IMAPIKey -id $Result.apiKey.id
        }
    }
    Context 'Set-IMAPIKey' {
        It 'Should set a new name' {
            $Result = New-IMAPIKey -Name $KeyName
            Set-IMAPIKey -id $Result.apiKey.id -Name "$($KeyName)_New"
            $Result = Get-IMAPIKey -id $Result.apiKey.id
            $Result.Name | Should -Be "$($KeyName)_New"
            Remove-IMAPIKey -id $Result.id
        }
    }
    Context 'RemoveIMAPIKey' {
        It 'Should remove the api key' {
            $Result = New-IMAPIKey -Name $KeyName
            Remove-IMAPIKey -id $Result.apiKey.id
            { Get-IMAPIKey -id $Result.apiKey.id } | Should -Throw
        }
    }
}
