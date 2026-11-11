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
    # Intentionally excluded: none. Connect-Immich with no parameters is verified by metadata only,
    # because invoking it would prompt for the mandatory BaseURL and hang a non-interactive run.
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }
    AfterAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }

    Context 'Connect-Immich - When no parameters are specified' -Tag 'Connect-Immich' {
        It 'BaseURL should be a mandatory parameter' {
            (Get-Command Connect-Immich).Parameters['BaseURL'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Select-Object -ExpandProperty Mandatory | Should -Contain $true
        }
    }
    Context 'Connect-Immich - When providing Access Token' -Tag 'Connect-Immich' {
        It 'Should not throw' {
            { Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY } | Should -Not -Throw
        }
        It 'Should store a session variable and be type ImmichSession' {
            InModuleScope PSImmich {
                $script:ImmichSession | Should -Not -BeNullOrEmpty
                $script:ImmichSession.GetType().Name | Should -Be 'ImmichSession'
            }
        }
    }
    Context 'Connect-Immich - When providing Access Token and passthru is used' -Tag 'Connect-Immich' {
        BeforeAll {
            $ImmichSession = Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY -PassThru
        }
        It 'Should return a session object of type ImmichSession' {
            $ImmichSession | Should -Not -BeNullOrEmpty
            $ImmichSession.GetType().Name | Should -Be 'ImmichSession'
        }
        It 'BaseURI should have correct value' {
            $ImmichSession.BaseURI | Should -Be $env:PSIMMICHURI
        }
        It 'AuthMethod should have correct value' {
            $ImmichSession.AuthMethod | Should -Be 'AccessToken'
        }
        It 'AccessToken should be securestring' {
            $ImmichSession.AccessToken | Should -BeOfType [SecureString]
        }
        It 'AccessToken should be correct' {
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
            [string]::Equals($UnsecurePassword, $env:PSIMMICHAPIKEY, [StringComparison]::Ordinal) | Should -BeTrue -Because 'the stored access token must match the supplied API key'
        }
        It 'Credentials should be empty' {
            $ImmichSession.Credential | Should -BeNullOrEmpty
        }
        It 'JWT should be empty' {
            $ImmichSession.JWT | Should -BeNullOrEmpty
        }
        It 'APIUri should be correct' {
            $ImmichSession.APIUri | Should -Be "$env:PSIMMICHURI/api"
        }
        It 'ImmichVersion should not be empty' {
            $ImmichSession.ImmichVersion | Should -Not -BeNullOrEmpty
        }
        It 'SessionID should not be empty' {
            $ImmichSession.SessionID | Should -Not -BeNullOrEmpty
        }
    }
    Context 'Connect-Immich - When providing Credentials' -Tag 'Connect-Immich' {
        BeforeAll {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
        }
        It 'Should not throw' {
            { Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred } | Should -Not -Throw
        }
        It 'Should store a session variable and be type ImmichSession' {
            InModuleScope PSImmich {
                $script:ImmichSession | Should -Not -BeNullOrEmpty
                $script:ImmichSession.GetType().Name | Should -Be 'ImmichSession'
            }
        }
        AfterAll {
            Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        }
    }
    Context 'Connect-Immich - When providing Credentials and passthru is used' -Tag 'Connect-Immich' {
        BeforeAll {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            $ImmichSession = Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred -PassThru
        }
        It 'Should return a session object of type ImmichSession' {
            $ImmichSession | Should -Not -BeNullOrEmpty
            $ImmichSession.GetType().Name | Should -Be 'ImmichSession'
        }
        It 'BaseURI should have correct value' {
            $ImmichSession.BaseURI | Should -Be $env:PSIMMICHURI
        }
        It 'AuthMethod should have correct value' {
            $ImmichSession.AuthMethod | Should -Be 'Credential'
        }
        It 'AccessToken should be securestring' {
            $ImmichSession.AccessToken | Should -BeOfType [SecureString]
        }
        It 'Credentials should be a pscredential' {
            $ImmichSession.Credential | Should -BeOfType [pscredential]
        }
        It 'JWT should be a securestring' {
            $ImmichSession.JWT | Should -BeOfType [SecureString]
        }
        It 'APIUri should be correct' {
            $ImmichSession.APIUri | Should -Be "$env:PSIMMICHURI/api"
        }
        It 'ImmichVersion should not be empty' {
            $ImmichSession.ImmichVersion | Should -Not -BeNullOrEmpty
        }
        It 'SessionID should not be empty' {
            $ImmichSession.SessionID | Should -Not -BeNullOrEmpty
        }
        AfterAll {
            Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        }
    }
    Context 'Connect-Immich - When providing Credentials it is valid and usable' -Tag 'Connect-Immich' {
        BeforeAll {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred
        }
        It 'Credentials can be used to call the server' {
            { Get-IMServer -Configuration } | Should -Not -Throw
        }
        AfterAll {
            Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        }
    }
    Context 'Get-IMSession - When no parameters are specified' -Tag 'Get-IMSession' {
        It 'Should not throw' {
            { Get-IMSession } | Should -Not -Throw
        }
        It 'Should return an ImmichSession object' {
            (Get-IMSession).GetType().Name | Should -Be 'ImmichSession'
        }
        It 'Should return the same AuthMethod as the active connection' {
            (Get-IMSession).AuthMethod | Should -Be 'AccessToken'
        }
    }
    Context 'Get-IMSession - When passing an explicit session' -Tag 'Get-IMSession' {
        It 'Should return the session passed in' {
            $Session = Get-IMSession
            (Get-IMSession -Session $Session).SessionID | Should -Be $Session.SessionID
        }
    }
    Context 'Disconnect-Immich - When no parameters are specified' -Tag 'Disconnect-Immich' {
        AfterEach {
            Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        }
        It 'Should not throw' {
            { Disconnect-Immich } | Should -Not -Throw
        }
        It 'Should clear the module session variable' {
            Disconnect-Immich
            InModuleScope PSImmich {
                $script:ImmichSession | Should -BeNullOrEmpty
            }
        }
    }
    Context 'Invoke-ImmichMethod - When calling read-only GET endpoints' -Tag 'Invoke-ImmichMethod' {
        It 'Should return the server version' {
            $Result = Invoke-ImmichMethod -Method GET -RelativeURI 'server/version'
            $Result | Should -Not -BeNullOrEmpty
            $Result.major | Should -BeGreaterOrEqual 1
        }
        It 'Should return the server ping response' {
            $Result = Invoke-ImmichMethod -Method GET -RelativeURI 'server/ping'
            $Result.res | Should -Be 'pong'
        }
        It 'Should accept query parameters' {
            { Invoke-ImmichMethod -Method GET -RelativeURI 'server/version' -QueryParameters @{} } | Should -Not -Throw
        }
        It 'Should use an explicit session' {
            $Session = Get-IMSession
            $Result = Invoke-ImmichMethod -Method GET -RelativeURI 'server/version' -Session $Session
            $Result | Should -Not -BeNullOrEmpty
        }
        It 'Should throw for an unknown endpoint' {
            { Invoke-ImmichMethod -Method GET -RelativeURI 'pslive-integration/does-not-exist' } | Should -Throw
        }
    }
}
