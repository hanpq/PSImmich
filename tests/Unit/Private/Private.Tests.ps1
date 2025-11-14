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
        Context 'When adding custom type to single object' {
            It 'Should add the correct PSImmich type name to the object' {
                $testObject = [PSCustomObject]@{ Name = 'Test'; Value = 123 }
                $result = $testObject | AddCustomType -Type 'IMAsset'

                $result.PSObject.TypeNames[0] | Should -Be 'PSImmich.ObjectType.IMAsset'
                $result.Name | Should -Be 'Test'
                $result.Value | Should -Be 123
            }
        }

        Context 'When adding custom type to multiple objects' {
            It 'Should add the type name to all objects in the pipeline' {
                $testObjects = @(
                    [PSCustomObject]@{ ID = 1; Name = 'First' },
                    [PSCustomObject]@{ ID = 2; Name = 'Second' }
                )

                $results = $testObjects | AddCustomType -Type 'IMAlbum'

                $results.Count | Should -Be 2
                $results[0].PSObject.TypeNames[0] | Should -Be 'PSImmich.ObjectType.IMAlbum'
                $results[1].PSObject.TypeNames[0] | Should -Be 'PSImmich.ObjectType.IMAlbum'
                $results[0].ID | Should -Be 1
                $results[1].ID | Should -Be 2
            }
        }

        Context 'When object already has the type name' {
            It 'Should not add duplicate type names' {
                $testObject = [PSCustomObject]@{ Name = 'Test' }
                $testObject.PSObject.TypeNames.Insert(0, 'PSImmich.ObjectType.IMAsset')

                $result = $testObject | AddCustomType -Type 'IMAsset'

                # Should only have one instance of the type name
                ($result.PSObject.TypeNames | Where-Object { $_ -eq 'PSImmich.ObjectType.IMAsset' }).Count | Should -Be 1
                $result.PSObject.TypeNames[0] | Should -Be 'PSImmich.ObjectType.IMAsset'
            }
        }

        Context 'When adding different type names' {
            It 'Should handle various type names correctly' {
                $testCases = @(
                    @{ Type = 'IMUser'; Expected = 'PSImmich.ObjectType.IMUser' },
                    @{ Type = 'IMLibrary'; Expected = 'PSImmich.ObjectType.IMLibrary' },
                    @{ Type = 'IMJob'; Expected = 'PSImmich.ObjectType.IMJob' }
                )

                foreach ($case in $testCases)
                {
                    $testObject = [PSCustomObject]@{ Test = 'Value' }
                    $result = $testObject | AddCustomType -Type $case.Type
                    $result.PSObject.TypeNames[0] | Should -Be $case.Expected
                }
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
    Describe 'ValidateToken' -Tag 'Unit', 'ValidateToken' {
        BeforeAll {
            # Mock Invoke-RestMethod for all test scenarios
            Mock -CommandName Invoke-RestMethod -MockWith {
                param($Method, $Uri, $Headers)

                # Simulate successful validation response
                return [PSCustomObject]@{
                    AuthStatus = $true
                    UserEmail  = 'test@example.com'
                    UserId     = 'user-123'
                }
            }

            # Mock ConvertFromSecureString
            Mock -CommandName ConvertFromSecureString -MockWith {
                param($SecureString)
                return 'mocked-token-value'
            }
        }

        Context 'When validating AccessToken authentication' {
            It 'Should call Invoke-RestMethod with correct X-API-Key header' {
                $secureToken = ConvertTo-SecureString -String 'test-api-key' -AsPlainText -Force
                $apiUrl = 'https://immich.test.com/api'

                $result = ValidateToken -Type 'AccessToken' -APIUrl $apiUrl -Secret $secureToken

                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Method -eq 'Post' -and
                    $Uri -eq "$apiUrl/auth/validateToken" -and
                    $Headers.ContainsKey('X-API-Key') -and
                    $Headers['X-API-Key'] -eq 'mocked-token-value'
                }

                $result.AuthStatus | Should -Be $true
            }
        }

        Context 'When validating Credential authentication' {
            It 'Should call Invoke-RestMethod with correct Authorization Bearer header' {
                $secureToken = ConvertTo-SecureString -String 'test-jwt-token' -AsPlainText -Force
                $apiUrl = 'https://immich.test.com/api'

                $result = ValidateToken -Type 'Credential' -APIUrl $apiUrl -Secret $secureToken

                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Method -eq 'Post' -and
                    $Uri -eq "$apiUrl/auth/validateToken" -and
                    $Headers.ContainsKey('Authorization') -and
                    $Headers['Authorization'] -eq 'Bearer mocked-token-value'
                }

                $result.AuthStatus | Should -Be $true
            }
        }

        Context 'When validation fails' {
            BeforeAll {
                # Override mock for failure scenario
                Mock -CommandName Invoke-RestMethod -MockWith {
                    return [PSCustomObject]@{
                        AuthStatus = $false
                        Message    = 'Invalid token'
                    }
                }
            }

            It 'Should return AuthStatus false for invalid tokens' {
                $secureToken = ConvertTo-SecureString -String 'invalid-token' -AsPlainText -Force
                $apiUrl = 'https://immich.test.com/api'

                $result = ValidateToken -Type 'AccessToken' -APIUrl $apiUrl -Secret $secureToken

                $result.AuthStatus | Should -Be $false
            }
        }

        Context 'When API call throws exception' {
            BeforeAll {
                # Override mock to throw exception
                Mock -CommandName Invoke-RestMethod -MockWith {
                    throw 'Network error: Unable to connect to server'
                }
            }

            It 'Should throw the exception from Invoke-RestMethod' {
                $secureToken = ConvertTo-SecureString -String 'test-token' -AsPlainText -Force
                $apiUrl = 'https://immich.test.com/api'

                { ValidateToken -Type 'AccessToken' -APIUrl $apiUrl -Secret $secureToken } | Should -Throw '*Network error*'
            }
        }

        Context 'Parameter validation' {
            It 'Should handle different API URLs correctly' {
                $testUrls = @(
                    'https://immich.example.com/api',
                    'http://localhost:2283/api',
                    'https://photos.myserver.net/api'
                )

                $secureToken = ConvertTo-SecureString -String 'test-token' -AsPlainText -Force

                foreach ($url in $testUrls)
                {
                    ValidateToken -Type 'AccessToken' -APIUrl $url -Secret $secureToken

                    Should -Invoke Invoke-RestMethod -ParameterFilter {
                        $Uri -eq "$url/auth/validateToken"
                    }
                }
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
                # Should NOT include parameters without ApiParameter attributes
                $result.ContainsKey('simpleParam') | Should -Be $false
                $result.ContainsKey('SimpleParam') | Should -Be $false
                # Should exclude Session and common parameters
                $result.ContainsKey('Session') | Should -Be $false
            }

            It 'Should NOT process parameters without ApiParameter attributes' {
                $boundParams = @{
                    'FirstParam'  = 'value1'
                    'SecondParam' = 'value2'
                }

                $result = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'Test-CmdletNoAttributes'

                # Should return empty result since no parameters have [ApiParameter] attributes
                $result.Keys.Count | Should -Be 0
                $result.ContainsKey('firstParam') | Should -Be $false
                $result.ContainsKey('secondParam') | Should -Be $false
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

                # Should return empty result since FirstParam doesn't have [ApiParameter] attribute
                $result.Keys.Count | Should -Be 0

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
                    'ParamWithAttribute' = 'value1'
                }

                # First call - should invoke Get-Command
                $result1 = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'Test-CmdletWithAttributes'

                # Second call - should use cache
                $result2 = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'Test-CmdletWithAttributes'

                # Should have been called only once due to caching
                Should -Invoke Get-Command -Times 1 -ParameterFilter { $Name -eq 'Test-CmdletWithAttributes' }

                # Results should be identical
                $result1['customApiName'] | Should -Be $result2['customApiName']
                $result1.Keys.Count | Should -Be $result2.Keys.Count
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

                # Should return empty result since no parameters have [ApiParameter] attributes
                $result.Keys.Count | Should -Be 0
                $result.ContainsKey('firstParam') | Should -Be $false
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

        Context 'ApiParameter Attribute Only Processing' {
            It 'Should only process parameters with ApiParameter attributes' {
                $boundParams = @{
                    'MyParameterName'  = 'value1'  # No [ApiParameter] attribute
                    'AnotherParameter' = 'value2'  # No [ApiParameter] attribute
                    'XMLHttpRequest'   = 'value3'  # No [ApiParameter] attribute
                    'ID'               = 'value4'  # No [ApiParameter] attribute
                }

                $result = ConvertTo-ApiParameters -BoundParameters $boundParams -CmdletName 'Test-CmdletNoAttributes'

                # Should return empty result since no parameters have [ApiParameter] attributes
                $result.Keys.Count | Should -Be 0
                $result.ContainsKey('myParameterName') | Should -Be $false
                $result.ContainsKey('anotherParameter') | Should -Be $false
                $result.ContainsKey('xMLHttpRequest') | Should -Be $false
                $result.ContainsKey('iD') | Should -Be $false
            }
        }

        AfterEach {
            # Clear cache between tests to ensure isolation
            $script:ApiParameterMappings = @{}
        }
    }
}
