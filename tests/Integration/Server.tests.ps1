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

# Read-only. Intentionally excluded: Set-IMServer, Set-IMServerLicense and Remove-IMServerLicense, because they change
# configuration or licensing on the shared live server, which is not reset.
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
}
