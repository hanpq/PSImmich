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

# Read-only. Intentionally excluded: Set-IMServerLicense and Remove-IMServerLicense, because they change
# licensing on the shared live server, which is not reset and requires a real license key.
Describe 'Server' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }

    Context 'Get-IMServer' -Tag 'Get-IMServer' {
        It -Name 'Should return server about information by default' {
            $Result = Get-IMServer
            $Result.PSObject.Properties.Name | Should -Contain 'version'
        }

        It -Name 'Should return server about information with -About' {
            $Result = Get-IMServer -About
            $Result.PSObject.Properties.Name | Should -Contain 'version'
            $Result.PSObject.Properties.Name | Should -Contain 'licensed'
        }

        It -Name 'Should return the server version with -Version' {
            $Result = Get-IMServer -Version
            $Result.version | Should -Not -BeNullOrEmpty
            $Result.version | Should -Match '^\d+\.\d+\.\d+'
        }

        It -Name 'Should return the server ping response with -Ping' {
            $Result = Get-IMServer -Ping
            $Result.responds | Should -BeOfType [System.Boolean]
            $Result.responds | Should -BeTrue
        }

        It -Name 'Should return the server configuration with -Configuration' {
            $Result = Get-IMServer -Configuration
            $Result | Should -Not -BeNullOrEmpty
            $Result.PSObject.Properties.Name | Should -Contain 'loginPageMessage'
        }

        It -Name 'Should return server features with -Features' {
            $Result = Get-IMServer -Features
            $Result.PSObject.Properties.Name | Should -Contain 'smartSearch'
            $Result.PSObject.Properties.Name | Should -Contain 'duplicateDetection'
        }

        It -Name 'Should return server statistics with -Statistics' {
            $Result = Get-IMServer -Statistics
            $Result.PSObject.Properties.Name | Should -Contain 'photos'
            $Result.PSObject.Properties.Name | Should -Contain 'videos'
            $Result.PSObject.Properties.Name | Should -Contain 'usage'
            $Result.PSObject.Properties.Name | Should -Contain 'usageByUser'
        }

        It -Name 'Should return the supported media types with -MediaTypes' {
            $Result = Get-IMServer -MediaTypes
            $Result.PSObject.Properties.Name | Should -Contain 'image'
            $Result.PSObject.Properties.Name | Should -Contain 'video'
        }

        It -Name 'Should return the theme with -Theme' {
            $Result = Get-IMServer -Theme
            $Result | Should -Not -BeNullOrEmpty
        }

        It -Name 'Should return version history with -VersionHistory' {
            $Result = @(Get-IMServer -VersionHistory)
            $Result | Should -Not -BeNullOrEmpty
            $Result[0].PSObject.Properties.Name | Should -Contain 'version'
            $Result[0].PSObject.Properties.Name | Should -Contain 'createdAt'
        }

        It -Name 'Should return the applied system configuration with -AppliedSystemConfiguration' {
            $Result = Get-IMServer -AppliedSystemConfiguration
            $Result | Should -Not -BeNullOrEmpty
        }

        It -Name 'Should return the applied system configuration as raw JSON with -ReturnRawJSON' {
            $Result = Get-IMServer -AppliedSystemConfiguration -ReturnRawJSON
            $Result | Should -BeOfType [System.String]
            { $Result | ConvertFrom-Json } | Should -Not -Throw
        }

        It -Name 'Should return the default system configuration with -DefaultSystemConfiguration' {
            $Result = Get-IMServer -DefaultSystemConfiguration
            $Result | Should -Not -BeNullOrEmpty
        }

        It -Name 'Should return the default system configuration as raw JSON with -ReturnRawJSON' {
            $Result = Get-IMServer -DefaultSystemConfiguration -ReturnRawJSON
            $Result | Should -BeOfType [System.String]
            { $Result | ConvertFrom-Json } | Should -Not -Throw
        }

        It -Name 'Should return storage template options with -StorageTemplateOptions' {
            $Result = Get-IMServer -StorageTemplateOptions
            $Result | Should -Not -BeNullOrEmpty
        }

        It -Name 'Should return storage information with -Storage' {
            $Result = Get-IMServer -Storage
            $Result.PSObject.Properties.Name | Should -Contain 'diskSize'
            $Result.PSObject.Properties.Name | Should -Contain 'diskAvailable'
        }

        It -Name 'Should return APK links with -APKLinks' {
            $Result = Get-IMServer -APKLinks
            $Result | Should -Not -BeNullOrEmpty
        }

        It -Name 'Should return version check information with -VersionCheck' {
            { Get-IMServer -VersionCheck } | Should -Not -Throw
        }

        It -Name 'Should return version check state with -VersionCheckState' {
            { Get-IMServer -VersionCheckState } | Should -Not -Throw
        }

        It -Name 'Should throw when combining -Version and -Ping' {
            { Get-IMServer -Version -Ping } | Should -Throw
        }

    }

    Context 'Get-IMServerLicense' -Tag 'Get-IMServerLicense' {
        It -Name 'Should return the server license or report that none is installed' {
            try
            {
                $Result = Get-IMServerLicense
                $Result | Should -Not -BeNullOrEmpty
            }
            catch
            {
                if ($_.Exception.Message -match '404|not found')
                {
                    Set-ItResult -Skipped -Because 'No server license is installed on the server'
                    return
                }
                throw
            }
        }
    }

    # Changes are limited to loginPageMessage and always restored to the exact JSON read before the test.
    Context 'Set-IMServer' -Tag 'Set-IMServer' {
        BeforeAll {
            $script:OriginalConfig = Get-IMServer -AppliedSystemConfiguration -ReturnRawJSON
            $script:OriginalLoginMessage = ($script:OriginalConfig | ConvertFrom-Json).server.loginPageMessage
        }

        AfterAll {
            Set-IMServer -RawJSONConfig $script:OriginalConfig -Confirm:$false
        }

        It -Name 'Should accept the current configuration unchanged' {
            { Set-IMServer -RawJSONConfig $script:OriginalConfig -Confirm:$false } | Should -Not -Throw
            (Get-IMServer -AppliedSystemConfiguration -ReturnRawJSON | ConvertFrom-Json).server.loginPageMessage | Should -BeExactly $script:OriginalLoginMessage
        }

        It -Name 'Should update a setting and restore the original configuration' {
            $Marker = "PSImmich-Test-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
            $Config = $script:OriginalConfig | ConvertFrom-Json
            $Config.server.loginPageMessage = $Marker
            try
            {
                Set-IMServer -RawJSONConfig ($Config | ConvertTo-Json -Depth 10) -Confirm:$false
                (Get-IMServer -AppliedSystemConfiguration -ReturnRawJSON | ConvertFrom-Json).server.loginPageMessage | Should -BeExactly $Marker
            }
            finally
            {
                Set-IMServer -RawJSONConfig $script:OriginalConfig -Confirm:$false
            }
            (Get-IMServer -AppliedSystemConfiguration -ReturnRawJSON | ConvertFrom-Json).server.loginPageMessage | Should -BeExactly $script:OriginalLoginMessage
        }

        It -Name 'Should not change the configuration with -WhatIf' {
            $Config = $script:OriginalConfig | ConvertFrom-Json
            $Config.server.loginPageMessage = 'PSImmich-WhatIf-Marker'
            Set-IMServer -RawJSONConfig ($Config | ConvertTo-Json -Depth 10) -WhatIf
            (Get-IMServer -AppliedSystemConfiguration -ReturnRawJSON | ConvertFrom-Json).server.loginPageMessage | Should -BeExactly $script:OriginalLoginMessage
        }

        It -Name 'Should throw for invalid JSON' {
            { Set-IMServer -RawJSONConfig '{ not json' -Confirm:$false } | Should -Throw
        }
    }
}
