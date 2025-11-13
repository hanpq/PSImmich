### Set run variables

$here = $PSScriptRoot

# Convert-path required for PS7 or Join-Path fails
$ProjectPath = "$here\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
    ($_.Directory.Name -eq 'source') -and
    $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
).BaseName

$SourcePath = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -eq 'source') -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch { $false }) }
    ).Directory.FullName

$mut = Import-Module -Name $ProjectName -ErrorAction Stop -PassThru -Force
$allModuleFunctions = &$mut { Get-Command -Module $args[0] -CommandType Function } $ProjectName | ForEach-Object {
    [hashtable]@{
        Name = $PSItem.Name
        File = Get-ChildItem -Path $SourcePath -Recurse -Include "$($PSItem.Name).ps1"
    }
}

### Verify Script Analyzer

if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue)
{
    $scriptAnalyzerRules = Get-ScriptAnalyzerRule
}
else
{
    if ($ErrorActionPreference -ne 'Stop')
    {
        Write-Warning 'ScriptAnalyzer not found!'
    }
    else
    {
        Throw 'ScriptAnalyzer not found!'
    }
}

### Tests

BeforeAll {
    function Test-FileEndOfLine
    {
    <#
    .DESCRIPTION
        asd
    .PARAMETER Name
        Description
    .EXAMPLE
        Test-FileEndOfLine
        Description of example
    #>

        [CmdletBinding(DefaultParameterSetName = 'ScriptFilePath')] # Enabled advanced function support
        param(
            [Parameter(Mandatory, ParameterSetName = 'ScriptFilePath')]
            [System.IO.FileInfo]
            $ScriptFilePath,

            [Parameter(Mandatory, ParameterSetName = 'RawCode')]
            [string]
            $RawCode,

            [string]
            $Encoding = 'UTF8'
        )

        BEGIN
        {

            # Import script file
            if ($PSCmdlet.ParameterSetName -eq 'ScriptFilePath')
            {
                try
                {
                    $RawCode = Get-Content $ScriptFilePath -Raw -ErrorAction Stop -Encoding $Encoding
                    Write-Verbose -Message 'Successfully imported file'
                }
                catch
                {
                    Write-Error -Message 'Failed to import file' -ErrorRecord $_
                    break
                }
            }
        }

        PROCESS
        {
            $WindowsRegex = "(`r`n|`n`r)"
            $UnixRegex = "(?<![`r])(`n)(?![`r])"
            $MacRegex = "(?<![`n])(`r)(?![`n])"

            switch -Regex ($RawCode)
            {
                $WindowsRegex
                {
                    return 'Windows'
                }
                $UnixRegex
                {
                    return 'Unix'
                }
                $MacRegex
                {
                    return 'Mac'
                }
                default
                {
                    return 'None'
                }
            }
        }
    }
}

Describe 'Changelog Management' -Tag 'TestQuality' {
    It 'Changelog has been updated' -skip:(
        !([bool](Get-Command git -EA SilentlyContinue) -and
            [bool](&(Get-Process -id $PID).Path -NoProfile -Command 'git rev-parse --is-inside-work-tree 2>$null'))
        ) {
        # Get the list of changed files compared with master
        $HeadCommit = &git rev-parse HEAD
        $MasterCommit = &git rev-parse origin/main
        $filesChanged = &git @('diff', "$MasterCommit...$HeadCommit", '--name-only')

        if ($HeadCommit -ne $MasterCommit) { # if we're not testing same commit (i.e. master..master)
            $filesChanged.Where{ (Split-Path $_ -Leaf) -match '^changelog' } | Should -Not -BeNullOrEmpty
        }
    }

    It 'Changelog format compliant with keepachangelog format' -skip:(![bool](Get-Command git -EA SilentlyContinue)) {
        { Get-ChangelogData (Join-Path $ProjectPath 'CHANGELOG.md') -ErrorAction Stop } | Should -Not -Throw
    }
}

Describe 'General module control' -Tag 'TestQuality' {
    It 'imports without errors' {
        { Import-Module -Name $ProjectName -Force -ErrorAction Stop } | Should -Not -Throw
        Get-Module $ProjectName | Should -Not -BeNullOrEmpty
    }

    It 'Removes without error' {
        { Remove-Module -Name $ProjectName -ErrorAction Stop } | Should -not -Throw
        Get-Module $ProjectName | Should -beNullOrEmpty
    }
}

Describe 'Quality for files' -Tag 'TestQuality' {
    foreach ($file in $allModuleFunctions) {
        BeforeEach {
            $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Raw $File.FullName), [ref]$null, [ref]$null)
            $AstSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
            $ParsedFunction = $AbstractSyntaxTree.FindAll( $AstSearchDelegate, $true ) |
                Where-Object Name -EQ $Name

            $FunctionHelp = $ParsedFunction.GetHelpContent()
            $parameters = $ParsedFunction.Body.ParamBlock.Parameters.name.VariablePath.Foreach{ $_.ToString() }
            $openApiPath = Join-Path $PSScriptRoot '..\..\api\api.2.2.0.json'
            $openApiDefinition = Get-Content -Path $openApiPath -Raw | ConvertFrom-Json
        }
        Context $File.Name {
            It 'Function has unit tests' {
                #Get-ChildItem "$PSScriptRoot\.." -Recurse -Include "$($Name).Tests.ps1" | Should -Not -BeNullOrEmpty
                $Result = Get-ChildItem "$PSScriptRoot\..\Unit" -file -Recurse | foreach-object {
                    Select-String -Path $PSItem.FullName -Pattern "Describe '$Name'" -SimpleMatch
                }
                $Result | should -not -BeNullOrEmpty
            } -ForEach $File
            It 'Script analyzer' {
                $PSSAResult = (Invoke-ScriptAnalyzer -Path $File.FullName)
                $Report = $PSSAResult | Format-Table -AutoSize | Out-String -Width 110
                $PSSAResult  | Should -BeNullOrEmpty -Because `
                    "some rule triggered.`r`n`r`n $Report"
            } -Skip:(-not $scriptAnalyzerRules) -TestCases $File
            It -Name 'File has appropriate line ending' -Test {
                $Result = Test-FileEndOfLine -RawCode (Get-Content -Path $File.FullName -Raw -Encoding UTF8)
                (($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') -and $Result -eq 'Windows') -or (($IsLinux -or $IsMacOS) -and $Result -eq 'Unix') | Should -BeTrue
            } -TestCases $file
            It -Name 'File is encoded in UTF8' -Test {
                # Workaround,  apperently the module encoding and subsequently the command Test-Encoding uses aliases for Sort-Object, these aliases are not available on linux and mac by default and the test fails on Linux and Mac. To mitigate this until the Encoding Module is patched, aliases for this are added.
                if ($IsMacOS -or $IsLinux)
                {
                    New-Alias -Name 'Sort' -Value 'Sort-Object' -Scope Global -ErrorAction SilentlyContinue
                }
                Test-Encoding -Path $File.FullName -Encoding utf8 | Should -Be $true
            } -TestCases $file
            It 'Help.Description Length > 10' {
                $FunctionHelp.Description.Length | Should -BeGreaterThan 10
            } -TestCases $file
            It 'Help.Examples.Count > 0' {
                $FunctionHelp.Examples.Count | Should -BeGreaterThan 0
                $FunctionHelp.Examples[0] | Should -Match ([regex]::Escape($function.Name))
                $FunctionHelp.Examples[0].Length | Should -BeGreaterThan ($function.Name.Length + 10)
            } -TestCases $file
            It 'Help.Parameters' {
                foreach ($parameter in $parameters)
                {
                    $FunctionHelp.Parameters.($parameter.ToUpper()) | Should -Not -BeNullOrEmpty
                    $FunctionHelp.Parameters.($parameter.ToUpper()).Length | Should -BeGreaterThan 2
                }

            } -TestCases $file


            It 'Cmdlet uses valid API' -Tag 'APIValidation' {
                # Extract REST method calls from the function and validate against OpenAPI spec
                $FunctionName = $_.Name -replace '\.ps1$'

                # Extract all REST method calls
                $restMethodCalls = @()

                # Find all InvokeImmichRestMethod command calls
                $invokeCommands = $AbstractSyntaxTree.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                    $args[0].GetCommandName() -eq 'InvokeImmichRestMethod'
                }, $true)

                foreach ($command in $invokeCommands) {
                    $methodParam = $null
                    $relativePathParam = $null

                    # Parse command elements to find Method and RelativePath parameters
                    for ($i = 0; $i -lt $command.CommandElements.Count; $i++) {
                        $element = $command.CommandElements[$i]

                        if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                            if ($element.ParameterName -eq 'Method' -and ($i + 1) -lt $command.CommandElements.Count) {
                                $methodValue = $command.CommandElements[$i + 1]
                                if ($methodValue -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                                    $methodParam = $methodValue.Value
                                }
                            }
                            elseif ($element.ParameterName -eq 'RelativePath' -and ($i + 1) -lt $command.CommandElements.Count) {
                                $relativePathValue = $command.CommandElements[$i + 1]
                                if ($relativePathValue -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                                    $relativePathParam = $relativePathValue.Value
                                } elseif ($relativePathValue -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
                                    # Handle string interpolation like "/tags/$PSitem/assets" or "/assets/device/$DeviceID"
                                    # Keep the original PowerShell path with variables for pattern matching
                                    $relativePathParam = $relativePathValue.Value
                                }
                            }
                        }
                    }

                    # Add to results if we found both method and path
                    if ($methodParam -and $relativePathParam) {
                        $restMethodCalls += [PSCustomObject]@{
                            Method = $methodParam.ToUpper()
                            RelativePath = $relativePathParam
                        }
                    }
                }

                # Skip validation if no REST calls found
                if ($restMethodCalls.Count -eq 0) {
                    $restMethodCalls.Count | Should -BeGreaterOrEqual 0
                    return
                }

                # Validate each REST call against OpenAPI specification
                foreach ($RestCall in $restMethodCalls) {
                    # Find matching endpoint in OpenAPI spec
                    $MatchingEndpoint = $null
                    foreach ($Path in $openApiDefinition.paths.PSObject.Properties) {
                        $isMatch = $false

                        # Check for exact match first
                        if ($RestCall.RelativePath -eq $Path.Name) {
                            $isMatch = $true
                        }
                        # Check for pattern match (PowerShell variables vs OpenAPI parameters)
                        elseif ($RestCall.RelativePath -match '\$\w+') {
                            # Convert PowerShell path to regex pattern for matching OpenAPI paths
                            # Replace PowerShell variables with regex pattern to match any parameter
                            $pathPattern = [regex]::Escape($RestCall.RelativePath) -replace '\\\$\w+', '\{[^}]+\}'
                            if ($Path.Name -match "^$pathPattern$") {
                                $isMatch = $true
                            }
                        }

                        if ($isMatch) {
                            # Check if the HTTP method exists for this path
                            $PathMethods = $Path.Value.PSObject.Properties | Where-Object { $_.Name -eq $RestCall.Method.ToLower() }
                            if ($PathMethods) {
                                $MatchingEndpoint = @{
                                    Path = $Path.Name
                                    Method = $RestCall.Method
                                    Operation = $PathMethods.Value
                                }
                                break
                            }
                        }
                    }

                    # Validate endpoint exists
                    if (-not $MatchingEndpoint) {
                        $false | Should -Be $true -Because "Endpoint $($RestCall.Method) $($RestCall.RelativePath) should exist in OpenAPI specification"
                        continue
                    }

                    # Basic validation passed - endpoint exists
                    $MatchingEndpoint | Should -Not -BeNullOrEmpty
                }
            } -TestCases $file
        }
    }
}
