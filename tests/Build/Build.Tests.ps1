BeforeAll {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $buildScript = Join-Path $projectRoot 'build.ps1'
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($buildScript, [ref]$null, [ref]$null)
    foreach ($functionName in @('Import-BuildModule', 'Build-ProjectModule', 'Invoke-ModuleTests', 'New-ModulePackage'))
    {
        $definition = $ast.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq $functionName
        }, $true)
        Set-Item -Path "Function:\$functionName" -Value $definition.Body.GetScriptBlock()
    }

    $DependencyManifest = Join-Path $projectRoot 'RequiredModules.psd1'
    $RequiredModulesDirectory = Join-Path $projectRoot 'output\RequiredModules'
    Import-Module (Join-Path $RequiredModulesDirectory 'ModuleBuilder\3.1.8\ModuleBuilder.psd1') -Force
    $OutputDirectory = Join-Path $TestDrive 'output'
    $TestResultsDirectory = Join-Path $OutputDirectory 'testResults'
    $ModuleName = 'ExampleModule'
}

Describe 'Module metadata discovery' {
    BeforeAll {
        $metadataScript = Join-Path $projectRoot 'scripts\Get-BuildProject.ps1'
    }

    BeforeEach {
        $fixtureRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $fixtureSource = Join-Path $fixtureRoot 'source'
        New-Item -ItemType Directory -Path $fixtureSource -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $fixtureSource 'ExampleModule.psd1') -Value "@{ ModuleVersion = '1.2.3' }"
    }

    It 'uses the source manifest name rather than the repository name' {
        $project = & $metadataScript -ProjectRoot $fixtureRoot

        $project.Name | Should -Be 'ExampleModule'
        $project.Version | Should -Be '1.2.3'
        $project.SourceManifest | Should -Be (Join-Path $fixtureSource 'ExampleModule.psd1')
    }

    It 'rejects an ambiguous source directory' {
        Set-Content -LiteralPath (Join-Path $fixtureSource 'OtherModule.psd1') -Value "@{ ModuleVersion = '1.0.0' }"

        { & $metadataScript -ProjectRoot $fixtureRoot } |
            Should -Throw '*exactly one module manifest*'
    }

    It 'splits a tracked prerelease into PowerShell manifest fields' {
        Set-Content -LiteralPath (Join-Path $fixtureRoot '.release-please-manifest.json') -Value '{".":"1.3.0-beta001"}'

        $project = & $metadataScript -ProjectRoot $fixtureRoot

        $project.Version | Should -Be '1.3.0-beta001'
        $project.ModuleVersion | Should -Be '1.3.0'
        $project.Prerelease | Should -Be 'beta001'
    }

    It 'allows a local version override without changing the tracked version' {
        Set-Content -LiteralPath (Join-Path $fixtureRoot '.release-please-manifest.json') -Value '{".":"1.2.3"}'

        $project = & $metadataScript -ProjectRoot $fixtureRoot -Version '1.3.0-beta002'

        $project.Version | Should -Be '1.3.0-beta002'
        (& $metadataScript -ProjectRoot $fixtureRoot).Version | Should -Be '1.2.3'
    }

    It 'keeps stable releases free of a prerelease suffix' {
        $project = & $metadataScript -ProjectRoot $fixtureRoot -Version '1.3.0'

        $project.ModuleVersion | Should -Be '1.3.0'
        $project.Prerelease | Should -BeNullOrEmpty
    }

    It 'reads prerelease metadata from an untracked source template' {
        Set-Content -LiteralPath (Join-Path $fixtureSource 'ExampleModule.psd1') -Value "@{ ModuleVersion = '1.2.3'; PrivateData = @{ PSData = @{ Prerelease = 'beta001' } } }"

        $project = & $metadataScript -ProjectRoot $fixtureRoot

        $project.Version | Should -Be '1.2.3-beta001'
        $project.ModuleVersion | Should -Be '1.2.3'
    }

    It 'rejects unsupported version <ReleaseVersion>' -ForEach @(
        @{ ReleaseVersion = '1.3.0-beta.1' }
        @{ ReleaseVersion = '1.3.0+build123' }
        @{ ReleaseVersion = '1.3' }
        @{ ReleaseVersion = '01.3.0' }
        @{ ReleaseVersion = 'invalid' }
    ) {
        { & $metadataScript -ProjectRoot $fixtureRoot -Version $ReleaseVersion } |
            Should -Throw '*Invalid release version*'
    }

    It 'rejects a tracking manifest without the root package version' {
        Set-Content -LiteralPath (Join-Path $fixtureRoot '.release-please-manifest.json') -Value '{}'

        { & $metadataScript -ProjectRoot $fixtureRoot } | Should -Throw '*Invalid release version*'
    }
}

Describe 'Module packaging' {
    It 'passes only the optional source parts that exist to ModuleBuilder' -ForEach @(
        @{ Parts = @(); ExpectedCopyPaths = $null; ExpectedPrefix = $null; ExpectedSuffix = $null }
        @{ Parts = @('en-US', 'prefix.ps1'); ExpectedCopyPaths = @('en-US'); ExpectedPrefix = 'prefix.ps1'; ExpectedSuffix = $null }
        @{ Parts = @('en-US', 'include', 'prefix.ps1', 'suffix.ps1'); ExpectedCopyPaths = @('en-US', 'include'); ExpectedPrefix = 'prefix.ps1'; ExpectedSuffix = 'suffix.ps1' }
        @{ Parts = @('en-US', 'include', 'Format', 'prefix.ps1', 'suffix.ps1'); ExpectedCopyPaths = @('en-US', 'include', 'Format'); ExpectedPrefix = 'prefix.ps1'; ExpectedSuffix = 'suffix.ps1' }
    ) {
        function Build-Module
        {
            [CmdletBinding()]
            param($SourcePath, $OutputDirectory, $SemVer, $Encoding, $CopyPaths, $Prefix, $Suffix)
        }
        $sourceDirectory = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $sourceDirectory -Force | Out-Null
        $SourceManifest = Join-Path $sourceDirectory "$ModuleName.psd1"
        Set-Content -LiteralPath $SourceManifest -Value "@{ ModuleVersion = '1.2.3' }"
        foreach ($part in $Parts)
        {
            $type = if ($part -like '*.ps1') { 'File' } else { 'Directory' }
            New-Item -ItemType $type -Path (Join-Path $sourceDirectory $part) -Force | Out-Null
        }
        $BuiltModuleDirectory = Join-Path $OutputDirectory $ModuleName
        Mock Import-BuildModule { }
        Mock Build-Module { throw 'stop after capturing parameters' }

        { Build-ProjectModule -ModuleVersion '1.2.3' } | Should -Throw '*stop after capturing parameters*'

        Should -Invoke Build-Module -Times 1 -Exactly -ParameterFilter {
            "$CopyPaths" -eq "$ExpectedCopyPaths" -and "$Prefix" -eq "$ExpectedPrefix" -and "$Suffix" -eq "$ExpectedSuffix"
        }
    }

    It 'rebuilds rather than packaging a different release from the same numeric directory' {
        $BuiltModuleDirectory = Join-Path $OutputDirectory $ModuleName
        $moduleDirectory = Join-Path $BuiltModuleDirectory '1.2.3'
        New-Item -ItemType Directory -Path $moduleDirectory -Force | Out-Null
        $manifestPath = Join-Path $moduleDirectory "$ModuleName.psd1"
        Set-Content -LiteralPath $manifestPath -Value "@{ ModuleVersion = '1.2.3' }"
        Mock Build-ProjectModule {
            Set-Content -LiteralPath $manifestPath -Value "@{ ModuleVersion = '1.2.3'; PrivateData = @{ PSData = @{ Prerelease = 'beta001' } } }"
            $moduleDirectory
        }

        New-ModulePackage -ModuleVersion '1.2.3-beta001'

        Should -Invoke Build-ProjectModule -Times 1 -Exactly -ParameterFilter { $ModuleVersion -eq '1.2.3-beta001' }
    }

    It 'creates a package for a differently named module at <ReleaseVersion>' -ForEach @(
        @{ ReleaseVersion = '1.2.3'; Label = '' }
        @{ ReleaseVersion = '1.2.3-beta001'; Label = 'beta001' }
        @{ ReleaseVersion = '1.2.3-beta002'; Label = 'beta002' }
    ) {
        $BuiltModuleDirectory = Join-Path $OutputDirectory $ModuleName
        $moduleDirectory = Join-Path $BuiltModuleDirectory '1.2.3'
        New-Item -ItemType Directory -Path $moduleDirectory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $moduleDirectory "$ModuleName.psd1") -Value "@{ ModuleVersion = '1.2.3'; PrivateData = @{ PSData = @{ Prerelease = '$Label' } } }"

        New-ModulePackage -ModuleVersion $ReleaseVersion

        $package = Join-Path $OutputDirectory "ExampleModule.$ReleaseVersion.zip"
        Test-Path -LiteralPath $package | Should -BeTrue
        $archive = [System.IO.Compression.ZipFile]::OpenRead($package)
        try
        {
            $archive.Entries.FullName | Should -Contain 'ExampleModule.psd1'
        }
        finally
        {
            $archive.Dispose()
        }
    }
}

Describe 'Release publication guards' {
    BeforeAll {
        $assertScript = Join-Path $projectRoot 'scripts\Assert-ReleaseMetadata.ps1'
    }

    BeforeEach {
        $fixtureRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $fixtureSource = Join-Path $fixtureRoot 'source'
        New-Item -ItemType Directory -Path $fixtureSource -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $fixtureSource 'ExampleModule.psd1') -Value "@{ ModuleVersion = '1.2.3' }"
        Set-Content -LiteralPath (Join-Path $fixtureRoot '.release-please-manifest.json') -Value '{".":"1.3.0-beta001"}'
    }

    It 'accepts a matching prerelease' {
        $project = & $assertScript -ProjectRoot $fixtureRoot -Tag 'v1.3.0-beta001' -RefTag 'v1.3.0-beta001' -IsPrerelease $true

        $project.Version | Should -Be '1.3.0-beta001'
    }

    It 'accepts promotion to the same numeric stable version' {
        Set-Content -LiteralPath (Join-Path $fixtureRoot '.release-please-manifest.json') -Value '{".":"1.3.0"}'

        $project = & $assertScript -ProjectRoot $fixtureRoot -Tag 'v1.3.0' -RefTag 'v1.3.0' -IsPrerelease $false

        $project.Version | Should -Be '1.3.0'
    }

    It 'rejects a tag that disagrees with the package version' {
        { & $assertScript -ProjectRoot $fixtureRoot -Tag 'v1.3.0-beta002' -IsPrerelease $true } |
            Should -Throw '*tag*does not match*'
    }

    It 'rejects a prerelease incorrectly marked stable on GitHub' {
        { & $assertScript -ProjectRoot $fixtureRoot -Tag 'v1.3.0-beta001' -IsPrerelease $false } |
            Should -Throw '*GitHub prerelease flag*'
    }

    It 'rejects a stable package incorrectly marked as a GitHub prerelease' {
        Set-Content -LiteralPath (Join-Path $fixtureRoot '.release-please-manifest.json') -Value '{".":"1.3.0"}'

        { & $assertScript -ProjectRoot $fixtureRoot -Tag 'v1.3.0' -IsPrerelease $true } |
            Should -Throw '*GitHub prerelease flag*'
    }

    It 'rejects an event tag that differs from the checked-out ref' {
        { & $assertScript -ProjectRoot $fixtureRoot -Tag 'v1.3.0-beta001' -RefTag 'v1.3.0-beta002' -IsPrerelease $true } |
            Should -Throw '*does not match checked-out ref*'
    }

    It 'accepts a built manifest matching the immutable release metadata' {
        $builtModulePath = Join-Path $fixtureRoot 'built'
        New-Item -ItemType Directory -Path $builtModulePath | Out-Null
        Set-Content -LiteralPath (Join-Path $builtModulePath 'ExampleModule.psd1') -Value "@{ ModuleVersion = '1.3.0'; PrivateData = @{ PSData = @{ Prerelease = 'beta001' } } }"

        $project = & $assertScript -ProjectRoot $fixtureRoot -Tag 'v1.3.0-beta001' `
            -RefTag 'v1.3.0-beta001' -IsPrerelease $true -BuiltModulePath $builtModulePath

        $project.Version | Should -Be '1.3.0-beta001'
    }

    It 'rejects a built manifest that disagrees with the immutable release metadata' {
        $builtModulePath = Join-Path $fixtureRoot 'built'
        New-Item -ItemType Directory -Path $builtModulePath | Out-Null
        Set-Content -LiteralPath (Join-Path $builtModulePath 'ExampleModule.psd1') -Value "@{ ModuleVersion = '1.3.0'; PrivateData = @{ PSData = @{ Prerelease = '' } } }"

        { & $assertScript -ProjectRoot $fixtureRoot -Tag 'v1.3.0-beta001' `
            -RefTag 'v1.3.0-beta001' -IsPrerelease $true -BuiltModulePath $builtModulePath } |
            Should -Throw '*does not match tracked version*'
    }
}

Describe 'Pinned build module imports' {
    It 'imports the pinned analyzer manifest beyond the helper scope' {
        Mock Import-Module {}

        Import-BuildModule -Name PSScriptAnalyzer

        Should -Invoke Import-Module -Times 1 -Exactly -ParameterFilter {
            $Name -eq (Join-Path $RequiredModulesDirectory 'PSScriptAnalyzer\1.24.0\PSScriptAnalyzer.psd1') -and
            $Global -and $ErrorAction -eq 'Stop'
        }
    }
}

Describe 'Build test runner' {
    BeforeEach {
        $originalModulePath = $env:PSModulePath
        $OutputDirectory = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $TestResultsDirectory = Join-Path $OutputDirectory 'testResults'
        $moduleDirectory = Join-Path $OutputDirectory 'ExampleModule\1.2.3'
        New-Item -ItemType Directory -Path $moduleDirectory -Force | Out-Null
        # The runner converts against the real source folder, so map to any existing function file.
        $mappedSourceFile = Get-ChildItem -Path (Join-Path $projectRoot 'source\Public'), (Join-Path $projectRoot 'source\Private') `
            -Filter '*.ps1' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        $mappedSourcePath = './{0}/{1}' -f $mappedSourceFile.Directory.Name, $mappedSourceFile.Name
        Set-Content -LiteralPath (Join-Path $moduleDirectory 'ExampleModule.psm1') -Value @(
            "#Region '$mappedSourcePath' -1", '', 'Write-Output 1'
        )
        Mock Write-Host {}
        Mock Import-BuildModule {}
        Mock Invoke-Pester {
            if ($Configuration.CodeCoverage.Enabled.Value)
            {
                Set-Content -LiteralPath $Configuration.CodeCoverage.OutputPath.Value -Value @'
<report name="ExampleModule"><package name="output"><sourcefile name="ExampleModule.psm1"><line nr="3" mi="0" ci="1" mb="0" cb="0"/></sourcefile></package></report>
'@
            }
            [pscustomobject]@{
                Result                = 'Passed'
                FailedCount           = 0
                FailedContainersCount = 0
                CodeCoverage          = [pscustomobject]@{
                    CommandsAnalyzedCount = 1
                    CoveragePercent       = 100
                }
            }
        }
    }

    AfterEach {
        $env:PSModulePath = $originalModulePath
    }

    It 'loads the analyzer and Pester explicitly before running tests' {
        Invoke-ModuleTests -ModuleVersion '1.2.3'

        Should -Invoke Import-BuildModule -Times 1 -Exactly -ParameterFilter { $Name -eq 'PSScriptAnalyzer' }
        Should -Invoke Import-BuildModule -Times 1 -Exactly -ParameterFilter { $Name -eq 'Pester' }
        Should -Invoke Import-BuildModule -Times 1 -Exactly -ParameterFilter { $Name -eq 'ModuleBuilder' }
        Should -Invoke Invoke-Pester -Times 1 -Exactly -ParameterFilter {
            $Configuration.TestResult.OutputPath.Value -eq (Join-Path $TestResultsDirectory 'ExampleModule.Tests.xml')
        }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -like 'Pester tests passed.*'
        }
    }

    It 'does not start Pester when the analyzer cannot be imported' {
        Mock Import-BuildModule {
            throw 'Analyzer assembly conflict'
        } -ParameterFilter { $Name -eq 'PSScriptAnalyzer' }

        { Invoke-ModuleTests -ModuleVersion '1.2.3' } |
            Should -Throw '*Analyzer assembly conflict*'

        Should -Invoke Invoke-Pester -Times 0 -Exactly
    }

    It 'selects <Suite> tests and coverage' -ForEach @(
        @{ Suite = 'Module'; Directories = @('tests\Unit', 'tests\QA'); Coverage = $true }
        @{ Suite = 'Infrastructure'; Directories = @('tests\Build'); Coverage = $false }
        @{ Suite = 'Integration'; Directories = @('tests\Integration'); Coverage = $false }
        @{ Suite = 'All'; Directories = @('tests\Unit', 'tests\QA', 'tests\Build'); Coverage = $true }
    ) {
        Invoke-ModuleTests -ModuleVersion '1.2.3' -TestSuite $Suite

        Should -Invoke Invoke-Pester -Times 1 -Exactly -ParameterFilter {
            $expected = @($Directories | ForEach-Object { Join-Path $projectRoot $_ })
            @($Configuration.Run.Path.Value).Count -eq $expected.Count -and
            @(Compare-Object @($Configuration.Run.Path.Value) $expected).Count -eq 0 -and
            $Configuration.CodeCoverage.Enabled.Value -eq $Coverage -and
            $Configuration.CodeCoverage.Path.Value[0] -eq (Join-Path $OutputDirectory 'ExampleModule\1.2.3\ExampleModule.psm1')
        }
    }

    It 'fails when coverage is below target or no commands were analyzed' -ForEach @(
        @{ Analyzed = 100; Percent = 0 }
        @{ Analyzed = 100; Percent = 0.5 }
        @{ Analyzed = 0; Percent = 100 }
    ) {
        Mock Invoke-Pester {
            Set-Content -LiteralPath $Configuration.CodeCoverage.OutputPath.Value -Value @'
<report name="ExampleModule"><package name="output"><sourcefile name="ExampleModule.psm1"><line nr="3" mi="1" ci="0" mb="0" cb="0"/></sourcefile></package></report>
'@
            [pscustomobject]@{
                Result       = 'Passed'
                CodeCoverage = [pscustomobject]@{
                    CommandsAnalyzedCount = $Analyzed
                    CoveragePercent       = $Percent
                }
            }
        }

        { Invoke-ModuleTests -ModuleVersion '1.2.3' -TestSuite Module } |
            Should -Throw '*Code coverage is below the required target*'

        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { $Object -like 'Pester tests passed.*' }
    }

    It 'accepts coverage exactly at the required target' {
        Mock Invoke-Pester {
            Set-Content -LiteralPath $Configuration.CodeCoverage.OutputPath.Value -Value @'
<report name="ExampleModule"><package name="output"><sourcefile name="ExampleModule.psm1"><line nr="3" mi="99" ci="1" mb="0" cb="0"/></sourcefile></package></report>
'@
            [pscustomobject]@{
                Result       = 'Passed'
                CodeCoverage = [pscustomobject]@{ CommandsAnalyzedCount = 100; CoveragePercent = 1 }
            }
        }

        { Invoke-ModuleTests -ModuleVersion '1.2.3' -TestSuite Module } | Should -Not -Throw
    }

    It 'fails when discovery fails without any failed tests' {
        Mock Invoke-Pester {
            [pscustomobject]@{
                Result                = 'Failed'
                FailedCount           = 0
                FailedContainersCount = 1
            }
        }

        { Invoke-ModuleTests -ModuleVersion '1.2.3' } |
            Should -Throw '*failed tests: 0; failed containers: 1*'

        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter {
            $Object -like 'Pester tests passed.*'
        }
    }

    It 'fails when a test fails' {
        Mock Invoke-Pester {
            [pscustomobject]@{
                Result                = 'Failed'
                FailedCount           = 1
                FailedContainersCount = 0
            }
        }

        { Invoke-ModuleTests -ModuleVersion '1.2.3' } |
            Should -Throw '*failed tests: 1; failed containers: 0*'
    }
}
