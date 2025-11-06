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

InModuleScope $ProjectName {

    Describe 'AddCustomType' -Tag 'Unit', 'AddCustomType' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'ConvertFromSecureString' -Tag 'Unit', 'ConvertFromSecureString' {
        Context 'When providing a securestring' {
            It 'Should return the correct string' {
                $SecureString = ConvertTo-SecureString -String 'immich' -AsPlainText -Force
                ConvertFromSecureString -SecureString $SecureString | Should -BeExactly 'immich'
            }
        }
    }
    Describe 'InvokeImmichRestMethod' -Tag 'Unit', 'InvokeImmichRestMethod' {
        BeforeAll {
            Mock -CommandName Invoke-RestMethod -MockWith {

            }
            $Session = [ImmichSession]::New('https://immich.domain.com', 'AccessToken', (ConvertTo-SecureString -String 'accesstoken' -AsPlainText -Force), $true, (New-Object -TypeName pscredential -ArgumentList 'username', (ConvertTo-SecureString -String 'password' -AsPlainText -Force)), (ConvertTo-SecureString -String 'jwt' -AsPlainText -Force), '1.1.1', (New-Guid).Guid)
        }
        Context 'When calling get without query or body' {
            It 'Should not throw' {
                { InvokeImmichRestMethod -Method get -RelativePath '/auth/login' -ImmichSession:$session } | Should -Not -Throw
            }
        }
        Context 'When calling get with query' {
            It 'Should not throw' {
                { InvokeImmichRestMethod -Method get -immichsession:$session -RelativePath '/auth/login' -QueryParameters:@{
                        param1 = 'string'
                        param2 = Get-Date
                        param3 = 1
                    } } | Should -Not -Throw
            }
        }
        Context 'When calling post with body' {
            It 'Should not throw' {
                { InvokeImmichRestMethod -Method post -immichsession:$session -RelativePath '/auth/login' -Body:@{
                        param1 = 'string'
                        param2 = Get-Date
                        param3 = 1
                    } } | Should -Not -Throw
            }
        }
    }
    Describe 'SelectBinding' -Tag 'Unit', 'SelectBinding' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
    Describe 'ValidateToken' -Tag 'Unit', 'ValidateToken' {
        Context 'Default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }

    Describe 'ConvertTo-ApiParameters' -Tag 'Unit', 'ConvertTo-ApiParameters' {
        BeforeAll {
            # Mock Get-Command to simulate cmdlet parameter information
            Mock Get-Command -ParameterFilter { $Name -in @('Test-CmdletWithAttributes', 'Test-CmdletNoAttributes') } {
                param($Name)

                # Create a mock attribute that behaves like ApiParameterAttribute
                function New-MockApiParameterAttribute
                {
                    param([string]$AttributeName)

                    $mockAttr = [PSCustomObject]@{
                        Name = $AttributeName
                    }

                    # Add a GetType method that returns the correct type name
                    $mockAttr | Add-Member -MemberType ScriptMethod -Name 'GetType' -Value {
                        return [PSCustomObject]@{
                            Name = 'ApiParameterAttribute'
                        }
                    } -Force

                    return $mockAttr
                }

                # Create mock command object with parameters
                $mockCommand = [PSCustomObject]@{
                    Parameters = @{}
                }

                # Simulate different cmdlets based on name
                switch ($Name)
                {
                    'Test-CmdletWithAttributes'
                    {
                        $mockCommand.Parameters = @{
                            'Session'                   = [PSCustomObject]@{
                                Attributes = @()
                            }
                            'SimpleParam'               = [PSCustomObject]@{
                                Attributes = @()
                            }
                            'ParamWithAttribute'        = [PSCustomObject]@{
                                Attributes = @(
                                    (New-MockApiParameterAttribute -AttributeName 'customApiName')
                                )
                            }
                            'AnotherParamWithAttribute' = [PSCustomObject]@{
                                Attributes = @(
                                    (New-MockApiParameterAttribute -AttributeName 'anotherCustomName')
                                )
                            }
                            'Verbose'                   = [PSCustomObject]@{
                                Attributes = @()
                            }
                        }
                    }
                    'Test-CmdletNoAttributes'
                    {
                        $mockCommand.Parameters = @{
                            'Session'          = [PSCustomObject]@{
                                Attributes = @()
                            }
                            'FirstParam'       = [PSCustomObject]@{
                                Attributes = @()
                            }
                            'SecondParam'      = [PSCustomObject]@{
                                Attributes = @()
                            }
                            'MyParameterName'  = [PSCustomObject]@{
                                Attributes = @()
                            }
                            'AnotherParameter' = [PSCustomObject]@{
                                Attributes = @()
                            }
                            'XMLHttpRequest'   = [PSCustomObject]@{
                                Attributes = @()
                            }
                            'ID'               = [PSCustomObject]@{
                                Attributes = @()
                            }
                            'Verbose'          = [PSCustomObject]@{
                                Attributes = @()
                            }
                            'Debug'            = [PSCustomObject]@{
                                Attributes = @()
                            }
                            'ErrorAction'      = [PSCustomObject]@{
                                Attributes = @()
                            }
                        }
                    }
                    default
                    {
                        return $null
                    }
                }

                return $mockCommand
            }

            # Clear the script-level cache before tests
            $script:ApiParameterMappings = @{}
        }

        Context 'Parameter Mapping with ApiParameter Attributes' {
            It 'Should map parameters with ApiParameter attributes to custom names' {
                $boundParams = @{
                    'ParamWithAttribute'        = 'value1'
                    'AnotherParamWithAttribute' = 'value2'
                    'SimpleParam'               = 'value3'
                }

                $result = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'Test-CmdletWithAttributes'

                # Should use custom API names from attributes
                $result['customApiName'] | Should -Be 'value1'
                $result['anotherCustomName'] | Should -Be 'value2'
                # Should use camelCase for parameters without attributes
                $result['simpleParam'] | Should -Be 'value3'
                # Should exclude Session and common parameters
                $result.ContainsKey('Session') | Should -Be $false
            }

            It 'Should use camelCase conversion for parameters without ApiParameter attributes' {
                $boundParams = @{
                    'FirstParam'  = 'value1'
                    'SecondParam' = 'value2'
                }

                $result = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'Test-CmdletNoAttributes'

                $result['firstParam'] | Should -Be 'value1'
                $result['secondParam'] | Should -Be 'value2'
            }

            It 'Should exclude common PowerShell parameters' {
                $boundParams = @{
                    'FirstParam'        = 'value1'
                    'Verbose'           = $true
                    'Debug'             = $true
                    'ErrorAction'       = 'Stop'
                    'WarningAction'     = 'Continue'
                    'InformationAction' = 'Continue'
                    'Session'           = $null
                }

                $result = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'Test-CmdletNoAttributes'

                # Should only include the actual parameter
                $result.Keys.Count | Should -Be 1
                $result['firstParam'] | Should -Be 'value1'

                # Should exclude all common parameters
                $result.ContainsKey('Verbose') | Should -Be $false
                $result.ContainsKey('Debug') | Should -Be $false
                $result.ContainsKey('ErrorAction') | Should -Be $false
                $result.ContainsKey('Session') | Should -Be $false
            }
        }

        Context 'Caching Behavior' {
            It 'Should cache parameter mappings to avoid repeated reflection' {
                $boundParams = @{
                    'FirstParam' = 'value1'
                }

                # First call - should invoke Get-Command
                $result1 = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'Test-CmdletNoAttributes'

                # Second call - should use cache
                $result2 = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'Test-CmdletNoAttributes'

                # Should have been called only once due to caching
                Should -Invoke Get-Command -Times 1 -ParameterFilter { $Name -eq 'Test-CmdletNoAttributes' }

                # Results should be identical
                $result1['firstParam'] | Should -Be $result2['firstParam']
            }
        }

        Context 'Error Handling' {
            It 'Should handle non-existent cmdlet gracefully' {
                $boundParams = @{
                    'SomeParam' = 'value'
                }

                $result = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'NonExistentCmdlet'

                # Should return empty hashtable when cmdlet not found
                $result | Should -BeOfType [hashtable]
                $result.Keys.Count | Should -Be 0
            }

            It 'Should handle empty bound parameters' {
                $boundParams = @{}

                $result = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'Test-CmdletNoAttributes'

                $result | Should -BeOfType [hashtable]
                $result.Keys.Count | Should -Be 0
            }

            It 'Should handle parameters not in cmdlet definition' {
                $boundParams = @{
                    'FirstParam'   = 'value1'
                    'UnknownParam' = 'value2'  # Not in cmdlet definition
                }

                $result = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'Test-CmdletNoAttributes'

                # Should only include known parameters
                $result.Keys.Count | Should -Be 1
                $result['firstParam'] | Should -Be 'value1'
                $result.ContainsKey('UnknownParam') | Should -Be $false
            }
        }

        Context 'ApiParameter Attribute Detection' {
            It 'Should correctly identify ApiParameterAttribute by type name' {
                $boundParams = @{
                    'ParamWithAttribute' = 'testValue'
                }

                $result = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'Test-CmdletWithAttributes'

                # Should use the custom name from the attribute, not camelCase conversion
                $result['customApiName'] | Should -Be 'testValue'
                $result.ContainsKey('paramWithAttribute') | Should -Be $false
            }
        }

        Context 'PascalCase to camelCase Conversion' {
            It 'Should correctly convert PascalCase to camelCase' {
                $boundParams = @{
                    'MyParameterName'  = 'value1'
                    'AnotherParameter' = 'value2'
                    'XMLHttpRequest'   = 'value3'  # Edge case
                    'ID'               = 'value4'  # Single letter + uppercase
                }

                $result = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'Test-CmdletNoAttributes'

                $result['myParameterName'] | Should -Be 'value1'
                $result['anotherParameter'] | Should -Be 'value2'
                $result['xMLHttpRequest'] | Should -Be 'value3'
                $result['iD'] | Should -Be 'value4'
            }
        }

        AfterEach {
            # Clear cache between tests to ensure isolation
            $script:ApiParameterMappings = @{}
        }
    }
}
