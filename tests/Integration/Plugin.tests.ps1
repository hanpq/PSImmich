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

# Read-only. Intentionally excluded: plugin installation and removal, because the live server is shared and not reset.
Describe 'Plugin' -Tag 'Integration' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $script:AllPlugins = @(Get-IMPlugin)
        $script:AllMethods = @(Get-IMPluginMethod)
        $script:AllTemplates = @(Get-IMPluginTemplate)
    }

    Context 'Get-IMPlugin' -Tag 'Get-IMPlugin' {
        It -Name 'Should list all plugins without error' {
            { $Result = Get-IMPlugin } | Should -Not -Throw
        }

        It -Name 'Should return PluginResponseDto objects with expected properties' {
            if ($script:AllPlugins.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No plugins are installed on the server'
                return
            }
            foreach ($Plugin in $script:AllPlugins)
            {
                $Plugin.GetType().Name | Should -Be 'PluginResponseDto'
                $Plugin.PSObject.Properties.Name | Should -Contain 'id'
                $Plugin.PSObject.Properties.Name | Should -Contain 'name'
                $Plugin.PSObject.Properties.Name | Should -Contain 'title'
                $Plugin.PSObject.Properties.Name | Should -Contain 'version'
                $Plugin.PSObject.Properties.Name | Should -Contain 'methods'
            }
        }

        It -Name 'Should get a specific plugin by ID' {
            if ($script:AllPlugins.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No plugins are installed on the server'
                return
            }
            $FirstPlugin = $script:AllPlugins[0]
            $Result = Get-IMPlugin -Id $FirstPlugin.id
            $Result.id | Should -Be $FirstPlugin.id
            $Result.name | Should -Be $FirstPlugin.name
        }

        It -Name 'Should support pipeline input with a plugin ID' {
            if ($script:AllPlugins.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No plugins are installed on the server'
                return
            }
            $FirstPlugin = $script:AllPlugins[0]
            $Result = $FirstPlugin.id | Get-IMPlugin
            $Result.id | Should -Be $FirstPlugin.id
        }

        It -Name 'Should support pipeline input with a plugin object' {
            if ($script:AllPlugins.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No plugins are installed on the server'
                return
            }
            $FirstPlugin = $script:AllPlugins[0]
            $Result = $FirstPlugin | Get-IMPlugin
            $Result.id | Should -Be $FirstPlugin.id
        }

        It -Name 'Should filter the list by name' {
            if ($script:AllPlugins.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No plugins are installed on the server'
                return
            }
            $FirstPlugin = $script:AllPlugins[0]
            $Result = Get-IMPlugin -Name $FirstPlugin.name
            $Result.id | Should -Contain $FirstPlugin.id
        }

        It -Name 'Should filter the list by title' {
            if ($script:AllPlugins.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No plugins are installed on the server'
                return
            }
            $FirstPlugin = $script:AllPlugins[0]
            $Result = Get-IMPlugin -Title $FirstPlugin.title
            $Result.id | Should -Contain $FirstPlugin.id
        }

        It -Name 'Should filter the list by version' {
            if ($script:AllPlugins.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No plugins are installed on the server'
                return
            }
            $FirstPlugin = $script:AllPlugins[0]
            $Result = Get-IMPlugin -Version $FirstPlugin.version
            $Result.id | Should -Contain $FirstPlugin.id
        }

        It -Name 'Should accept the Description filter without error' {
            { Get-IMPlugin -Description 'integration' } | Should -Not -Throw
        }

        It -Name 'Should throw when getting a non-existent plugin' {
            { Get-IMPlugin -Id 'ffffffff-ffff-ffff-ffff-ffffffffffff' } | Should -Throw
        }

        It -Name 'Should throw for an ID that is not a GUID' {
            { Get-IMPlugin -Id 'not-a-guid' } | Should -Throw
        }

        It -Name 'Should throw when combining -Id with list filters' {
            { Get-IMPlugin -Id 'ffffffff-ffff-ffff-ffff-ffffffffffff' -Name 'x' } | Should -Throw
        }
    }

    Context 'Get-IMPluginMethod' -Tag 'Get-IMPluginMethod' {
        It -Name 'Should list all plugin methods without error' {
            { $Result = Get-IMPluginMethod } | Should -Not -Throw
        }

        It -Name 'Should return PluginMethodResponseDto objects with expected properties' {
            if ($script:AllMethods.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No plugin methods are available on the server'
                return
            }
            foreach ($Method in $script:AllMethods)
            {
                $Method.GetType().Name | Should -Be 'PluginMethodResponseDto'
                $Method.PSObject.Properties.Name | Should -Contain 'key'
                $Method.PSObject.Properties.Name | Should -Contain 'name'
                $Method.PSObject.Properties.Name | Should -Contain 'title'
                $Method.PSObject.Properties.Name | Should -Contain 'types'
            }
        }

        It -Name 'Should filter the methods by name' {
            if ($script:AllMethods.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No plugin methods are available on the server'
                return
            }
            $FirstMethod = $script:AllMethods[0]
            $Result = Get-IMPluginMethod -Name $FirstMethod.name
            $Result.key | Should -Contain $FirstMethod.key
        }

        It -Name 'Should filter the methods by trigger' {
            { Get-IMPluginMethod -Trigger 'AssetCreate' } | Should -Not -Throw
        }

        It -Name 'Should filter the methods by workflow type' {
            $Result = @(Get-IMPluginMethod -Type 'AssetV1')
            foreach ($Method in $Result) {
                $Method.types | Should -Contain 'AssetV1'
            }
        }

        It -Name 'Should filter the methods by plugin name' {
            if ($script:AllPlugins.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No plugins are installed on the server'
                return
            }
            { Get-IMPluginMethod -PluginName $script:AllPlugins[0].name } | Should -Not -Throw
        }

        It -Name 'Should throw for an invalid trigger filter' {
            { Get-IMPluginMethod -Trigger 'NotATrigger' } | Should -Throw
        }

        It -Name 'Should throw for an invalid workflow type filter' {
            { Get-IMPluginMethod -Type 'AssetV9' } | Should -Throw
        }

        It -Name 'Should throw for an ID that is not a GUID' {
            { Get-IMPluginMethod -Id 'not-a-guid' } | Should -Throw
        }
    }

    Context 'Get-IMPluginTemplate' -Tag 'Get-IMPluginTemplate' {
        It -Name 'Should list plugin templates without error' {
            { $Result = Get-IMPluginTemplate } | Should -Not -Throw
        }

        It -Name 'Should return PluginTemplateResponseDto objects with expected properties' {
            if ($script:AllTemplates.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No plugin templates are available on the server'
                return
            }
            foreach ($Template in $script:AllTemplates)
            {
                $Template.GetType().Name | Should -Be 'PluginTemplateResponseDto'
                $Template.PSObject.Properties.Name | Should -Contain 'key'
                $Template.PSObject.Properties.Name | Should -Contain 'title'
                $Template.PSObject.Properties.Name | Should -Contain 'trigger'
                $Template.PSObject.Properties.Name | Should -Contain 'steps'
            }
        }

        It -Name 'Should return templates with a known trigger' {
            if ($script:AllTemplates.Count -eq 0)
            {
                Set-ItResult -Skipped -Because 'No plugin templates are available on the server'
                return
            }
            foreach ($Template in $script:AllTemplates)
            {
                $Template.trigger | Should -BeIn @('AssetCreate', 'AssetMetadataExtraction', 'AssetOcrExtraction', 'AssetTagged')
            }
        }
    }
}
