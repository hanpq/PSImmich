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

Describe Connect-Immich {
    Context -Name 'When no parameters are specified' {
        It -Name 'Should throw' {
            { Connect-Immich } | Should -Throw
        }
    }
    Context -Name 'When providing Access Token' {
        It -Name 'Should not throw' {
            { Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY } | Should -Not -Throw
        }
        InModuleScope PSImmich -ScriptBlock {
            BeforeAll {
                Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
            }
            It -Name 'Should store a session variable' {
                $script:ImmichSession | Should -Not -BeNullOrEmpty
            }
            It -Name 'Should be type ImmichSession' {
                $script:ImmichSession.GetType().Name | Should -Be 'ImmichSession'
            }
        }
    }
    Context -Name 'When providing Access Token and passthru is used' {
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
    Context -Name 'When providing Credentials' {
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
    Context -Name 'When providing Credentials and passthru is used' {
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
    Context -Name 'When providing Credentials it is valid and usable' {
        BeforeAll {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred
        }
        It -Name 'Credentials can be used' {
            Get-IMServerConfig
        }
    }
}

Describe Get-IMSession {
    BeforeEach {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMSession } | Should -Not -Throw
        }
        It -Name 'Should return immichsession object' {
            (Get-IMSession).GetType().Name | Should -Be 'ImmichSession'
        }
    }
}

Describe Disconnect-Immich {
    BeforeEach {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -Name 'Should not throw' {
            { Disconnect-Immich } | Should -Not -Throw
        }
    }
}

Describe Get-IMServerConfig {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMServerConfig } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServerConfig
            $ExpectedProperties = @('LoginPageMessage', 'trashDays', 'userDeleteDelay', 'oauthButtonText', 'isInitialized', 'isOnboarded', 'ExternalDomain')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
}

Describe Get-IMServerFeature {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMServerFeature } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServerFeature
            $ExpectedProperties = @('smartSearch', 'passwordLogin', 'configFile', 'facialRecognition', 'map', 'reverseGeocoding', 'sidecar', 'search', 'trash', 'oauth', 'oauthAutoLaunch')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
}

Describe Get-IMServerInfo {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMServerInfo } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServerInfo
            $ExpectedProperties = @('diskSize', 'diskUse', 'diskAvailable', 'diskSizeRaw', 'diskUseRaw', 'diskAvailableRaw', 'diskUsagePercentage')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
}

Describe Get-IMServerStatistic {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
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
}

Describe Get-IMServerVersion {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMServerVersion } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMServerVersion
            $ExpectedProperties = @('version')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
}

Describe Get-IMSupportedMediaType {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMSupportedMediaType } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMSupportedMediaType
            $ExpectedProperties = @('video', 'image', 'sidecar')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
}

Describe Get-IMTheme {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -Name 'Should not throw' {
            { Get-IMTheme } | Should -Not -Throw
        }
        It -Name 'Should return these properties' {
            $Result = Get-IMTheme
            $ExpectedProperties = @('customCss')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
    }
}

Describe Test-IMPing {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
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

Describe Get-IMAsset {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'Specifying a single ID' {
        It -Name 'Should return a object with the correct properties' {
            $Result = Get-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb'
            $ExpectedProperties = @('hasMetadata', 'isReadOnly', 'isOffline', 'isExternal', 'stackCount', 'checksum', 'people', 'tags', 'livePhotoVideoId', 'smartInfo', 'exifInfo', 'duration', 'isTrashed', 'isArchived', 'isFavorite', 'updatedAt', 'localDateTime', 'fileModifiedAt', 'fileCreatedAt', 'thumbhash', 'resized', 'id', 'deviceAssetId', 'ownerId', 'owner', 'deviceId', 'libraryId', 'type', 'originalPath', 'originalFileName')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
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
    Context -Name 'Specifying multiple IDs' {
        It -Name 'Should accept multiple objects from pipeline' {
            @([pscustomobject]@{id = '025665c6-d874-46a2-bbc6-37250ddcb2eb' }, [pscustomobject]@{id = '025665c6-d874-46a2-bbc6-37250ddcb2eb' }) | Get-IMAsset | Should -HaveCount 2
        }
        It -Name 'Should accept multiple ids from pipeline' {
            @('025665c6-d874-46a2-bbc6-37250ddcb2eb', '025665c6-d874-46a2-bbc6-37250ddcb2eb') | Get-IMAsset | Should -HaveCount 2
        }
    }
    Context -Name 'No parameters are specified' {
        It -Name 'Should return array' {
            Get-IMAsset | Measure-Object | Select-Object -ExpandProperty count | Should -BeGreaterThan 1
        }
    }
}

Describe Get-IMCuratedLocation {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'Specifying a single ID' {
        It -Name 'Should return a object with the correct properties' {
            $Result = Get-IMCuratedLocation
            $ExpectedProperties = @('id', 'city', 'resizePath', 'deviceAssetId', 'deviceId')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty inputobject | Should -BeNullOrEmpty
        }
        It -Name 'Should return a single object' {
            Get-IMCuratedLocation | Should -HaveCount 1
        }
    }
}

Describe Get-IMCuratedObject {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'Specifying a single ID' {
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
}

Describe Update-IMAsset {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'Specifying a single ID' {
        It -Name 'Should update asset' {
            Update-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -isFavorite:$true
            Get-IMAsset -id '025665c6-d874-46a2-bbc6-37250ddcb2eb' | Select-Object -ExpandProperty isFavorite | Should -BeTrue
            Update-IMAsset -Id '025665c6-d874-46a2-bbc6-37250ddcb2eb' -isFavorite:$false
        }
    }
}

# Add-IMAsset is excluded from testing on Windows Powershell because the
# current rutine to post formdata is not nativly supported. Until a seperate
# routine is defined, this test is excluded.
Describe Add-IMAsset -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    It -Name 'Should upload the file' {
        $Result = Add-IMAsset -FilePath "$PSScriptRoot\Immich.png"
        $Result | Should -HaveCount 1
        $Result.DeviceAssetID | Should -Be 'Immich.png'
        Remove-IMAsset -Id $Result.Id -force
    }
}

Describe Remove-IMAsset -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    It -Name 'Should remove the file' {
        $Result = Add-IMAsset -FilePath "$PSScriptRoot\Immich.png"
        Remove-IMAsset -Id $Result.Id -force
        # Seems to be 50-50 chance this test fails. It might be a timing issue, trying to delay the verification half a seconds.
        Start-Sleep -Milliseconds 500
        { Get-IMAsset -Id $Result.Id } | Should -Throw
    }
}

Describe Get-IMActivity {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
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

Describe Get-IMActivityStatistic {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    It -Name 'Getting comment count for the album should be 3' {
        $Result = Get-IMActivityStatistic -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
        $Result.Comments | Should -Be 3
    }
    It -Name 'Getting comment count for album and asset should be 3' {
        $Result = Get-IMActivityStatistic -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
        $Result.Comments | Should -Be 3
    }
}

Describe Add-IMActivity {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    It -Name 'Adding a comment should succeed' {
        $Result = Add-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'bdc6d2c8-6168-4a88-a51f-6da11bf8f506' -comment 'TestComment' -type comment
        Remove-IMActivity -id $Result.id
    }
}

Describe Remove-IMActivity {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    It -Name 'Removing a comment should succeed' {
        $Result = Add-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'bdc6d2c8-6168-4a88-a51f-6da11bf8f506' -comment 'TestComment' -type comment
        Remove-IMActivity -id $Result.id
        # Seems to be 50-50 chance this test fails. It might be a timing issue, trying to delay the verification half a seconds.
        Start-Sleep -Milliseconds 500
        Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'bdc6d2c8-6168-4a88-a51f-6da11bf8f506' | Should -BeNullOrEmpty
    }
}

Describe Get-IMAlbum {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    It -Name 'list-shared' {
        $Result = Get-IMAlbum
        $Result | Should -HaveCount 1
    }
    It -Name 'list-shared-true' {
        $Result = Get-IMAlbum -shared:$true
        $Result | Should -HaveCount 1
    }
    It -Name 'list-shared-false' {
        $Result = Get-IMAlbum -shared:$false
        $Result | Should -HaveCount 0
    }
    It -Name 'list-assetid' {
        $Result = Get-IMAlbum -assetid 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'
        $Result | Should -HaveCount 1
    }
    It -Name 'list-id' {
        $Result = Get-IMAlbum -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'
        $Result | Should -HaveCount 1
        $Result.Assets | Should -Not -BeNullOrEmpty
    }
    It -Name 'list-id-withoutassets' {
        $Result = Get-IMAlbum -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -withoutAssets
        $Result | Should -HaveCount 1
        $Result.Assets | Should -BeNullOrEmpty
    }
    It -Name 'list-id-pipe-string' {
        $Result = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' | Get-IMAlbum
        $Result | Should -HaveCount 1
    }
    It -Name 'list-id-pipe-string-array' {
        $Result = @('bde7ceba-f301-4e9e-87a2-163937a2a3db', 'bde7ceba-f301-4e9e-87a2-163937a2a3db') | Get-IMAlbum
        $Result | Should -HaveCount 2
    }
    It -Name 'list-id-pipe-object-array' {
        $Result = @([pscustomobject]@{albumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }, [pscustomobject]@{albumId = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }) | Get-IMAlbum
        $Result | Should -HaveCount 2
    }
    It -Name 'list-id-pipe-object-array-alias' {
        $Result = @([pscustomobject]@{id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }, [pscustomobject]@{id = 'bde7ceba-f301-4e9e-87a2-163937a2a3db' }) | Get-IMAlbum
        $Result | Should -HaveCount 2
    }
}

Describe Get-IMAlbum {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    It -Name 'Gets correct count' {
        $Result = Get-IMAlbumCount
        $Result.owned | Should -Be 1
        $Result.shared | Should -Be 1
        $Result.notShared | Should -Be 0

    }
}

Describe New-IMAlbum {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    It -Name 'Album gets created' {
        $NewAlbum = New-IMAlbum -albumName 'IntegrationTestAlbum' -assetids 'a4908e1f-697f-4d7b-9330-93b5eabe3baf' -description 'IntegrationTestAlbum'
        $Result = Get-IMAlbum -albumId $NewAlbum.id
        $Result | Should -HaveCount 1
        $Result.Description | Should -Be 'IntegrationTestAlbum'
        $Result.albumName | Should -Be 'IntegrationTestAlbum'
        $Result.Assets | Should -HaveCount 1
        Remove-IMAlbum -albumId $NewAlbum.id
    }
    AfterAll {
        Get-IMAlbum | Where-Object { $_.AlbumName -eq 'IntegrationTestAlbum' } | Remove-IMAlbum
    }
}

Describe Remove-IMAlbum {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    It -Name 'Album gets removed' {
        $NewAlbum = New-IMAlbum -albumName 'IntegrationTestAlbum' -assetids 'a4908e1f-697f-4d7b-9330-93b5eabe3baf' -description 'IntegrationTestAlbum'
        Remove-IMAlbum -albumId $NewAlbum.id
        { Get-IMAlbum -albumId $NewAlbum.id } | Should -Throw
    }
}

Describe Update-IMAlbum {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    It -Name 'Album gets updated' {
        $NewAlbum = New-IMAlbum -albumName 'IntegrationTestAlbum'
        Update-IMAlbum -albumid $NewAlbum.id -Description 'IntegrationTestAlbumNew' -albumname 'IntegrationTestAlbumNew'
        $Result = Get-IMAlbum -albumid $NewAlbum.id
        $Result | Should -HaveCount 1
        $Result.Description | Should -Be 'IntegrationTestAlbumNew'
        $Result.albumName | Should -Be 'IntegrationTestAlbumNew'
        Remove-IMAlbum -albumId $NewAlbum.id
    }
    AfterAll {
        Get-IMAlbum | Where-Object { $_.AlbumName -eq 'IntegrationTestAlbum' } | Remove-IMAlbum
    }
}

Describe Add-IMAlbumAsset {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    It -Name 'Assets gets added to album' {
        $NewAlbum = New-IMAlbum -albumName 'IntegrationTestAlbum'
        Add-IMAlbumAsset -albumid $NewAlbum.id -assetid '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        $Result = Get-IMAlbum -albumid $NewAlbum.id
        $Result.assets | Should -HaveCount 2
        $Result.assets.id | Should -Contain '025665c6-d874-46a2-bbc6-37250ddcb2eb'
        $Result.assets.id | Should -Contain '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        Remove-IMAlbum -albumId $NewAlbum.id
    }
    AfterAll {
        Get-IMAlbum | Where-Object { $_.AlbumName -eq 'IntegrationTestAlbum' } | Remove-IMAlbum
    }
}

Describe Remove-IMAlbumAsset {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    It -Name 'Assets gets removed from album' {
        $NewAlbum = New-IMAlbum -albumName 'IntegrationTestAlbum'
        Add-IMAlbumAsset -albumid $NewAlbum.id -assetid '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        $Result = Get-IMAlbum -albumid $NewAlbum.id
        $Result.assets | Should -HaveCount 2
        Remove-IMAlbumAsset -albumid $NewAlbum.id -assetid '025665c6-d874-46a2-bbc6-37250ddcb2eb', '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        $Result = Get-IMAlbum -albumid $NewAlbum.id
        $Result.assets | Should -HaveCount 0
        Remove-IMAlbum -albumId $NewAlbum.id
    }
    AfterAll {
        Get-IMAlbum | Where-Object { $_.AlbumName -eq 'IntegrationTestAlbum' } | Remove-IMAlbum
    }
}

Describe Add-IMAlbumUser {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $NewAlbum = New-IMAlbum -albumName 'IntegrationTestAlbum'
    }
    It -Name 'Users gets added to album' {
        Add-IMAlbumUser -albumid $NewAlbum.id -userId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
        $Result = Get-IMAlbum -albumid $NewAlbum.id
        $Result.sharedUsers | Should -HaveCount 1
        $Result.sharedUsers.id | Should -Contain '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
    }
    AfterAll {
        Get-IMAlbum | Where-Object { $_.AlbumName -eq 'IntegrationTestAlbum' } | Remove-IMAlbum
    }
}

Describe Remove-IMAlbumUser {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $NewAlbum = New-IMAlbum -albumName 'IntegrationTestAlbum' -sharedWithUserIds '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
    }
    It -Name 'Users gets removed from album' {
        $Result = Get-IMAlbum -albumid $NewAlbum.id
        $Result.sharedUsers.id | Should -Contain '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
        Remove-IMAlbumUser -albumId $NewAlbum.id -userId '97eeb1d9-b699-45ae-a06b-3bf4ea43d44d'
        $Result = Get-IMAlbum -albumid $NewAlbum.id
        $Result.sharedUsers | Should -HaveCount 0
    }
    AfterAll {
        Get-IMAlbum | Where-Object { $_.AlbumName -eq 'IntegrationTestAlbum' } | Remove-IMAlbum
    }
}

# TestUser 97eeb1d9-b699-45ae-a06b-3bf4ea43d44d
