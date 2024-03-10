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
        It -name 'Should throw' {
            { Connect-Immich } | Should -Throw
        }
    }
    Context -Name 'When providing Access Token' {
        It -name 'Should not throw' {
            { Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY } | Should -Not -Throw
        }
        InModuleScope PSImmich -ScriptBlock {
            BeforeAll {
                Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
            }
            It -name 'Should store a session variable' {
                $script:ImmichSession | Should -Not -BeNullOrEmpty
            }
            It -name 'Should be type ImmichSession' {
                $script:ImmichSession.GetType().Name | Should -Be 'ImmichSession'
            }
        }
    }
    Context -Name 'When providing Access Token and passthru is used' {
        BeforeAll {
            $ImmichSession = Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY -PassThru
        }
        It -name 'Should return a session object' {
            $ImmichSession | Should -Not -BeNullOrEmpty
        }
        It -name 'Should be of type ImmichSession' {
            $ImmichSession.GetType().Name | Should -Be 'ImmichSession'
        }
        It -name 'BaseURI should have correct value' {
            $ImmichSession.BaseURI | Should -Be $env:PSIMMICHURI
        }
        It -name 'AuthMethod should have correct value' {
            $ImmichSession.AuthMethod | Should -Be 'AccessToken'
        }
        It -name 'AccessToken should be securestring' {
            $ImmichSession.AccessToken | Should -BeOfType [SecureString]
        }
        It -name 'AccessToken should be correct' {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ImmichSession.AccessToken)
            $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            $UnsecurePassword | Should -Be $env:PSIMMICHAPIKEY
        }
        It -name 'Credentials should be empty' {
            $ImmichSession.Credential | Should -BeNullOrEmpty
        }
        It -name 'JWT should be empty' {
            $ImmichSession.JWT | Should -BeNullOrEmpty
        }
        It -name 'APIUri should be correct' {
            $ImmichSession.APIUri | Should -Be "$env:PSIMMICHURI/api"
        }
        It -name 'ImmichVersion should not be empty' {
            $ImmichSession.ImmichVersion | Should -Not -BeNullOrEmpty
        }
        It -name 'SessionID should not be empty' {
            $ImmichSession.SessionID | Should -Not -BeNullOrEmpty
        }
    }
    Context -Name 'When providing Credentials' {
        It -name 'Should not throw' {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            { Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred } | Should -Not -Throw
        }
        InModuleScope PSImmich -ScriptBlock {
            BeforeAll {
                $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
                Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred
            }
            It -name 'Should store a session variable' {
                $script:ImmichSession | Should -Not -BeNullOrEmpty
            }
            It -name 'Should be type ImmichSession' {
                $script:ImmichSession.GetType().Name | Should -Be 'ImmichSession'
            }
        }
    }
    Context -Name 'When providing Credentials and passthru is used' {
        BeforeAll {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            $ImmichSession = Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred -PassThru
        }
        It -name 'Should return a session object' {
            $ImmichSession | Should -Not -BeNullOrEmpty
        }
        It -name 'Should be of type ImmichSession' {
            $ImmichSession.GetType().Name | Should -Be 'ImmichSession'
        }
        It -name 'BaseURI should have correct value' {
            $ImmichSession.BaseURI | Should -Be $env:PSIMMICHURI
        }
        It -name 'AuthMethod should have correct value' {
            $ImmichSession.AuthMethod | Should -Be 'Credential'
        }
        It -name 'AccessToken should be securestring' {
            $ImmichSession.AccessToken | Should -BeOfType [SecureString]
        }
        It -name 'Credentials should be empty' {
            $ImmichSession.Credential | Should -BeOfType [pscredential]
        }
        It -name 'JWT should be empty' {
            $ImmichSession.JWT | Should -BeOfType [SecureString]
        }
        It -name 'APIUri should be correct' {
            $ImmichSession.APIUri | Should -Be "$env:PSIMMICHURI/api"
        }
        It -name 'ImmichVersion should not be empty' {
            $ImmichSession.ImmichVersion | Should -Not -BeNullOrEmpty
        }
        It -name 'SessionID should not be empty' {
            $ImmichSession.SessionID | Should -Not -BeNullOrEmpty
        }
    }
    Context -Name 'When providing Credentials it is valid and usable' {
        BeforeAll {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred
        }
        It -name 'Credentials can be used' {
            Get-IMServerConfig
        }
    }
}

Describe Get-IMSession {
    BeforeEach {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -name 'Should not throw' {
            { Get-IMSession } | Should -Not -Throw
        }
        It -name 'Should return immichsession object' {
            (Get-IMSession).GetType().Name | Should -Be 'ImmichSession'
        }
    }
}

Describe Disconnect-Immich {
    BeforeEach {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -name 'Should not throw' {
            { Disconnect-Immich } | Should -Not -Throw
        }
    }
}

Describe Get-IMServerConfig {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -name 'Should not throw' {
            { Get-IMServerConfig } | Should -Not -Throw
        }
        It -name 'Should return these properties' {
            $Result = Get-IMServerConfig
            $Result.LoginPageMessage | Should -Be 'Site for integration tests'
            $Result.trashDays | Should -Be 30
            $Result.userDeleteDelay | Should -Be 7
            $Result.oauthButtonText | Should -Be 'Login with OAuth'
            $Result.isInitialized  | Should -BeTrue
            $Result.isOnboarded | Should -BeTrue
            $Result.ExternalDomain | Should -Be $env:PSIMMICHURI
        }
    }
}

Describe Get-IMServerFeature {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -name 'Should not throw' {
            { Get-IMServerFeature } | Should -Not -Throw
        }
        It -name 'Should return these properties' {
            $Result = Get-IMServerFeature
            $Result.smartSearch  | Should -BeTrue
            $Result.facialRecognition | Should -BeTrue
            $Result.map | Should -BeTrue
            $Result.reverseGeocoding | Should -BeTrue
            $Result.sidecar | Should -BeTrue
            $Result.search | Should -BeTrue
            $Result.trash | Should -BeTrue
            $Result.oauth | Should -BeFalse
            $Result.oauthAutoLaunch | Should -BeFalse
            $Result.passwordLogin | Should -BeTrue
            $Result.configFile | Should -BeFalse
        }
    }
}

Describe Get-IMServerInfo {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -name 'Should not throw' {
            { Get-IMServerInfo } | Should -Not -Throw
        }
        It -name 'Should return these properties' {
            $Result = Get-IMServerInfo
            $Result.diskSize            | Should  -BeOfType [String]
            $Result.diskUse             | Should  -BeOfType [String]
            $Result.diskAvailable       | Should  -BeOfType [String]
            $Result.diskSizeRaw         | Should  -BeOfType [int64]
            $Result.diskUseRaw          | Should  -BeOfType [int64]
            $Result.diskAvailableRaw    | Should  -BeOfType [int64]
            $Result.diskUsagePercentage | Should  -BeOfType [double]
        }
    }
}

Describe Get-IMServerStatistic {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -name 'Should not throw' {
            { Get-IMServerStatistic } | Should -Not -Throw
        }
        It -name 'Should return these properties' {
            $Result = Get-IMServerStatistic
            $Result.photos | Should -BeOfType [int64]
            $Result.videos | Should -BeOfType [int64]
            $Result.usage | Should -BeOfType [int64]
            , ($Result.usageByUser) | Should -BeOfType [array]
            , ($Result.usageByUser) | Should -HaveCount 1
            $Result.usageByUser[0].userID | Should -Be 'fb95c457-7685-428c-b850-2fd60345819c'
            $Result.usageByUser[0].userName | Should -Be 'Hannes Palmquist'
            $Result.usageByUser[0].photos | Should -BeOfType [int64]
            $Result.usageByUser[0].videos | Should -BeOfType [int64]
            $Result.usageByUser[0].usage | Should -BeOfType [int64]
            $Result.usageByUser[0].quotaSizeInBytes | Should -BeNullOrEmpty
        }
    }
}

Describe Get-IMServerVersion {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -name 'Should not throw' {
            { Get-IMServerVersion } | Should -Not -Throw
        }
        It -name 'Should return these properties' {
            $Result = Get-IMServerVersion
            $Result.version            | Should  -BeOfType [String]
        }
    }
}

Describe Get-IMSupportedMediaType {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -name 'Should not throw' {
            { Get-IMSupportedMediaType } | Should -Not -Throw
        }
        It -name 'Should return these properties' {
            $Result = Get-IMSupportedMediaType
            , ($Result.video) | Should  -BeOfType [array]
            , ($Result.image) | Should  -BeOfType [array]
            , ($Result.sidecar) | Should  -BeOfType [array]
        }
    }
}

Describe Get-IMTheme {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -name 'Should not throw' {
            { Get-IMTheme } | Should -Not -Throw
        }
        It -name 'Should return these properties' {
            $Result = Get-IMTheme
            $Result.customCss | Should  -BeNullOrEmpty
        }
    }
}

Describe Test-IMPing {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    Context -Name 'When no parameters are specified' {
        It -name 'Should not throw' {
            { Test-IMPing } | Should -Not -Throw
        }
        It -name 'Should return these properties' {
            $Result = Test-IMPing
            $Result.responds | Should  -BeTrue
        }
    }
}
