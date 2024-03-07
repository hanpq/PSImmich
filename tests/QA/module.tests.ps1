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

Describe 'Changelog Management' -Tag 'Changelog' {
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

Describe 'General module control' -Tag 'FunctionalQuality' {

    It 'imports without errors' {
        { Import-Module -Name $ProjectName -Force -ErrorAction Stop } | Should -Not -Throw
        Get-Module $ProjectName | Should -Not -BeNullOrEmpty
    }

    It 'Removes without error' {
        { Remove-Module -Name $ProjectName -ErrorAction Stop } | Should -not -Throw
        Get-Module $ProjectName | Should -beNullOrEmpty
    }
}

Describe "Quality for files" -Tag 'TestQuality' {
    It "Function has unit tests | <Name>" {
        Get-ChildItem "$PSScriptRoot\.." -Recurse -Include "$($Name).Tests.ps1" | Should -Not -BeNullOrEmpty
    } -TestCases $allModuleFunctions

    It "Script Analyzer | <Name>" {
        $PSSAResult = (Invoke-ScriptAnalyzer -Path $File.FullName)
        $Report = $PSSAResult | Format-Table -AutoSize | Out-String -Width 110
        $PSSAResult  | Should -BeNullOrEmpty -Because `
            "some rule triggered.`r`n`r`n $Report"
    } -Skip:(-not $scriptAnalyzerRules) -TestCases $allModuleFunctions

    It -Name 'File has appropriate line ending | <Name>' -Test {
        $Result = Test-FileEndOfLine -RawCode (Get-Content -Path $File.FullName -Raw -Encoding UTF8)
        (($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') -and $Result -eq 'Windows') -or (($IsLinux -or $IsMacOS) -and $Result -eq 'Unix') | Should -BeTrue
    } -TestCases $allModuleFunctions

    It -Name 'File is encoded in UTF8 | <Name>' -Test {
        # Workaround,  apperently the module encoding and subsequently the command Test-Encoding uses aliases for Sort-Object, these aliases are not available on linux and mac by default and the test fails on Linux and Mac. To mitigate this until the Encoding Module is patched, aliases for this are added.
        if ($IsMacOS -or $IsLinux)
        {
            New-Alias -Name 'Sort' -Value 'Sort-Object' -Scope Global -ErrorAction SilentlyContinue
        }
        Test-Encoding -Path $File.FullName -Encoding utf8 | Should -Be $true
    } -TestCases $allModuleFunctions
}
Describe "Help for files" -Tags 'helpQuality' {
    BeforeEach {
        $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::
        ParseInput((Get-Content -Raw $File.FullName), [ref]$null, [ref]$null)
        $AstSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
        $ParsedFunction = $AbstractSyntaxTree.FindAll( $AstSearchDelegate, $true ) |
            Where-Object Name -EQ $Name

        $FunctionHelp = $ParsedFunction.GetHelpContent()
        $parameters = $ParsedFunction.Body.ParamBlock.Parameters.name.VariablePath.Foreach{ $_.ToString() }
    }

    #It '<Name> has a SYNOPSIS' {
    #    $FunctionHelp.Synopsis | Should -Not -BeNullOrEmpty
    #} -TestCases $allModuleFunctions

    It 'Help.Description Length > 25 | <Name>' {
        $FunctionHelp.Description.Length | Should -BeGreaterThan 25
    } -TestCases $allModuleFunctions

    It 'Help.Examples.Count > 0 | <Name>' {
        $FunctionHelp.Examples.Count | Should -BeGreaterThan 0
        $FunctionHelp.Examples[0] | Should -Match ([regex]::Escape($function.Name))
        $FunctionHelp.Examples[0].Length | Should -BeGreaterThan ($function.Name.Length + 10)
    } -TestCases $allModuleFunctions

    It 'Help.Parameters | <Name>' {
        foreach ($parameter in $parameters)
        {
            $FunctionHelp.Parameters.($parameter.ToUpper()) | Should -Not -BeNullOrEmpty
            $FunctionHelp.Parameters.($parameter.ToUpper()).Length | Should -BeGreaterThan 25
        }

    } -TestCases $allModuleFunctions
}
