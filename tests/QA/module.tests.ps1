### Set run variables

$here = $PSScriptRoot

# Convert-path required for PS7 or Join-Path fails
$ProjectPath = "$here\..\.." | Convert-Path
$SourcePath = Join-Path $ProjectPath 'source'
$moduleManifests = @(Get-ChildItem -LiteralPath $SourcePath -Filter '*.psd1' -File -ErrorAction Stop)
if ($moduleManifests.Count -ne 1)
{
    throw "Expected exactly one module manifest in the source directory; found $($moduleManifests.Count)."
}
$null = Test-ModuleManifest -Path $moduleManifests[0].FullName -ErrorAction Stop
$ProjectName = $moduleManifests[0].BaseName
$sourceFiles = @(Get-ChildItem -LiteralPath $SourcePath -Recurse -File -Filter '*.ps1' -ErrorAction Stop)

$mut = Import-Module -Name $ProjectName -ErrorAction Stop -PassThru -Force
$allModuleFunctions = &$mut { Get-Command -Module $args[0] -CommandType Function } $ProjectName | ForEach-Object {
    $functionName = $PSItem.Name
    [hashtable]@{
        Name = $functionName
        File = $sourceFiles.Where{ $_.Name -eq "$functionName.ps1" }
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
        throw 'ScriptAnalyzer not found!'
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

        begin
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

        process
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
    BeforeAll {
        $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    }

    It 'Changelog format compliant with keepachangelog format' -Skip:(![bool](Get-Command git -EA SilentlyContinue)) {
        $changelog = Get-Content (Join-Path $projectRoot 'CHANGELOG.md') -Raw
        $changelog | Should -Match '(?m)^## \[Unreleased\]\s*$'
        $changelog | Should -Match '(?m)^## \[\d+\.\d+\.\d+[^]]*\] - \d{4}-\d{2}-\d{2}\s*$'
    }
}

Describe 'General module control' -Tag 'TestQuality' {
    BeforeAll {
        $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
        $moduleName = (Get-ChildItem -Path (Join-Path $projectRoot 'source') -Filter '*.psd1' | Select-Object -First 1).BaseName
    }

    It 'imports without errors' {
        { Import-Module -Name $moduleName -Force -ErrorAction Stop } | Should -Not -Throw
        Get-Module $moduleName | Should -Not -BeNullOrEmpty
    }

    It 'Removes without error' {
        { Remove-Module -Name $moduleName -ErrorAction Stop } | Should -Not -Throw
        Get-Module $moduleName | Should -BeNullOrEmpty
    }
}

Describe 'Quality for files' -Tag 'TestQuality' {
    BeforeAll {
        $unitTestLines = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '..\Unit') -File -Recurse -ErrorAction Stop |
                Get-Content -Encoding UTF8 -ErrorAction Stop)
    }

    Describe 'Immich API endpoint validation' -Tag 'APIValidation' {
        BeforeAll {
            $openApiFile = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '..\..\api') -Filter 'api.*.json' -File |
                Sort-Object Name -Descending | Select-Object -First 1
            $openApiDefinition = Get-Content -LiteralPath $openApiFile.FullName -Raw -ErrorAction Stop | ConvertFrom-Json
        }

        It '<Name> uses valid API endpoints' -ForEach $allModuleFunctions {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref]$null, [ref]$null)
            $commands = $ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                $args[0].GetCommandName() -eq 'InvokeImmichRestMethod'
            }, $true)

            foreach ($command in $commands)
            {
                $method = $null
                $relativePath = $null
                for ($i = 0; $i -lt $command.CommandElements.Count - 1; $i++)
                {
                    $element = $command.CommandElements[$i]
                    if ($element -isnot [System.Management.Automation.Language.CommandParameterAst])
                    {
                        continue
                    }

                    $value = $command.CommandElements[$i + 1]
                    if ($element.ParameterName -eq 'Method' -and $value -is [System.Management.Automation.Language.StringConstantExpressionAst])
                    {
                        $method = $value.Value.ToLowerInvariant()
                    }
                    if ($element.ParameterName -eq 'RelativePath' -and
                        ($value -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
                        $value -is [System.Management.Automation.Language.ExpandableStringExpressionAst]))
                    {
                        $relativePath = $value.Value
                    }
                }

                if (-not $method -or -not $relativePath)
                {
                    continue
                }

                $pathPattern = [regex]::Escape($relativePath) -replace '\\\$\w+', '\{[^}]+\}'
                $endpoints = @($openApiDefinition.paths.PSObject.Properties | Where-Object {
                    $_.Name -match "^$pathPattern$" -and $_.Value.PSObject.Properties.Name -contains $method
                })
                $endpoints | Should -Not -BeNullOrEmpty -Because "endpoint $method $relativePath should exist in the OpenAPI specification"
            }
        }
    }

    foreach ($file in $allModuleFunctions)
    {
        Context $File.Name -Tag $File.Name -ForEach $file {
            # Generated internal routes are covered by the generator tests and are not cmdlets, so cmdlet-only checks are skipped.
            $IsGenerated = (Get-Content -LiteralPath $File.FullName -TotalCount 1) -like '*AUTO-GENERATED by tools/New-ImmichApiLayer.ps1*'
            BeforeAll {
                $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Raw $File.FullName), [ref]$null, [ref]$null)
                $AstSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
                $ParsedFunction = $AbstractSyntaxTree.FindAll( $AstSearchDelegate, $true ) |
                    Where-Object Name -EQ $Name

                $FunctionHelp = $ParsedFunction.GetHelpContent()
                $functionParameterNames = $ParsedFunction.Body.ParamBlock.Parameters.name.VariablePath.Foreach{ $_.ToString() }
            }
            It 'Function has unit tests' -Skip:$IsGenerated {
                $Result = $unitTestLines | Select-String -Pattern "Describe '$Name'" -SimpleMatch
                $Result | Should -Not -BeNullOrEmpty
            }
            It 'Script analyzer' {
                $PSSAResult = (Invoke-ScriptAnalyzer -Path $File.FullName)
                $Report = if ($PSSAResult)
                {
                    $PSSAResult | Format-Table -AutoSize | Out-String -Width 110
                }
                $PSSAResult  | Should -BeNullOrEmpty -Because `
                    "some rule triggered.`r`n`r`n $Report"
            } -Skip:(-not $scriptAnalyzerRules)
            It -Name 'File has appropriate line ending' -Test {
                $Result = Test-FileEndOfLine -RawCode (Get-Content -Path $File.FullName -Raw -Encoding UTF8)
                (($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') -and $Result -eq 'Windows') -or (($IsLinux -or $IsMacOS) -and $Result -eq 'Unix') | Should -BeTrue
            }
            It -Name 'File is encoded in UTF8' -Test {
                $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
                $bytes = [System.IO.File]::ReadAllBytes($File.FullName)
                { $utf8.GetCharCount($bytes) } | Should -Not -Throw
            }
            It 'Help.Description Length > 10' -Skip:$IsGenerated {
                $FunctionHelp.Description.Length | Should -BeGreaterThan 10
            }
            It 'Help.Examples.Count > 0' -Skip:$IsGenerated {
                $FunctionHelp.Examples.Count | Should -BeGreaterThan 0
                $FunctionHelp.Examples[0] | Should -Match ([regex]::Escape($function.Name))
                $FunctionHelp.Examples[0].Length | Should -BeGreaterThan ($function.Name.Length + 10)
            }
            It 'Help.Parameters' -Skip:$IsGenerated {
                foreach ($parameter in $functionParameterNames)
                {
                    $FunctionHelp.Parameters.($parameter.ToUpper()) | Should -Not -BeNullOrEmpty
                    $FunctionHelp.Parameters.($parameter.ToUpper()).Length | Should -BeGreaterThan 2
                }

            }
        }
    }
}
