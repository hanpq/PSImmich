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

Describe Add-IMAsset {
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

Describe Remove-IMAsset {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    It -Name 'Should remove the file' {
        $Result = Add-IMAsset -FilePath "$PSScriptRoot\Immich.png"
        Remove-IMAsset -Id $Result.Id -force
        {Get-IMAsset -Id $Result.Id} | should -throw
    }
    # Must be able to upload a new asset before testing remove
}
