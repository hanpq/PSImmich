[CmdletBinding()]
param
(
    [Parameter(Position = 0)]
    [ValidateSet('Verify', 'Build', 'Test', 'Package', 'Clean', 'InstallDependencies')]
    [string]
    $Task = 'Verify',

    [Parameter()]
    [string]
    $Version,

    [Parameter()]
    [string]
    $OutputDirectory,

    [Parameter()]
    [ValidateSet('All', 'Module', 'Infrastructure', 'Integration')]
    [string]
    $TestSuite = 'All',

    # Optional Pester tags to run a subset of tests (for example 'Get-IMAsset'). Coverage is skipped when set.
    [Parameter()]
    [string[]]
    $Tag,

    [Parameter(DontShow)]
    [switch]
    $InBuildProcess
)

$ErrorActionPreference = 'Stop'

if (-not $InBuildProcess)
{
    Write-Host "Starting build process with task [$($Task.ToLowerInvariant())]" -ForegroundColor Cyan
    Write-Host 'Using a fresh PowerShell process to keep build dependencies isolated.'
    $executableName = if ($PSVersionTable.PSEdition -eq 'Desktop') { 'powershell.exe' }
        elseif ($env:OS -eq 'Windows_NT') { 'pwsh.exe' }
        else { 'pwsh' }
    $executable = Join-Path $PSHOME $executableName
    $arguments = @('-NoProfile', '-NonInteractive', '-File', $PSCommandPath, '-InBuildProcess', '-Task', $Task)
    $arguments += @('-TestSuite', $TestSuite)

    if ($PSBoundParameters.ContainsKey('Tag'))
    {
        # Joined into one argument because -File does not preserve array arguments.
        $arguments += @('-Tag', ($Tag -join ','))
    }

    if ($PSBoundParameters.ContainsKey('Version'))
    {
        $arguments += @('-Version', $Version)
    }

    if ($PSBoundParameters.ContainsKey('OutputDirectory'))
    {
        $arguments += @('-OutputDirectory', $OutputDirectory)
    }

    & $executable @arguments
    if ($LASTEXITCODE -ne 0)
    {
        throw "The '$Task' build task failed in the isolated PowerShell process (exit code $LASTEXITCODE). See the output above for details."
    }

    return
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory))
{
    $OutputDirectory = 'output'
}

if ([System.IO.Path]::IsPathRooted($OutputDirectory))
{
    $OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
}
else
{
    $OutputDirectory = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $OutputDirectory))
}
$RequiredModulesDirectory = Join-Path $OutputDirectory 'RequiredModules'
$project = & (Join-Path $PSScriptRoot 'scripts\Get-BuildProject.ps1') -ProjectRoot $PSScriptRoot
$ModuleName = $project.Name
$BuiltModuleDirectory = Join-Path $OutputDirectory $ModuleName
$TestResultsDirectory = Join-Path $OutputDirectory 'testResults'
$SourceManifest = $project.SourceManifest
$DependencyManifest = Join-Path $PSScriptRoot 'RequiredModules.psd1'

function Get-ModuleVersion
{
    if ($Version)
    {
        return (& (Join-Path $PSScriptRoot 'scripts\Get-BuildProject.ps1') -ProjectRoot $PSScriptRoot -Version $Version).Version
    }

    return $project.Version
}

function Initialize-BuildDependencies
{
    param
    (
        [switch]
        $IncludeDocumentation
    )

    Write-Host 'Checking module dependencies' -ForegroundColor Cyan
    $dependencyGroups = Import-PowerShellDataFile -Path $DependencyManifest
    $dependencies = @{}

    foreach ($moduleName in $dependencyGroups.Build.Keys)
    {
        $dependencies[$moduleName] = $dependencyGroups.Build[$moduleName]
    }

    if ($IncludeDocumentation)
    {
        foreach ($groupName in @('Publish', 'Documentation'))
        {
            foreach ($moduleName in $dependencyGroups[$groupName].Keys)
            {
                $dependencies[$moduleName] = $dependencyGroups[$groupName][$moduleName]
            }
        }
    }

    New-Item -ItemType Directory -Path $RequiredModulesDirectory -Force | Out-Null
    $dependencyPaths = @()

    foreach ($moduleName in $dependencies.Keys)
    {
        $moduleVersion = $dependencies[$moduleName]
        $modulePath = Join-Path (Join-Path $RequiredModulesDirectory $moduleName) $moduleVersion

        if (Test-Path -LiteralPath $modulePath)
        {
            Write-Host "  Ready: $moduleName $moduleVersion"
            $dependencyPaths += $modulePath
            continue
        }

        Write-Host "Restoring $moduleName $moduleVersion from PSGallery"
        Save-Module -Name $moduleName -RequiredVersion $moduleVersion -Repository PSGallery -Path $RequiredModulesDirectory -Force -ErrorAction Stop
        if (-not (Test-Path -LiteralPath $modulePath))
        {
            throw "Dependency restore did not create the expected path '$modulePath'."
        }

        $dependencyPaths += $modulePath
    }

    if ($env:OS -eq 'Windows_NT')
    {
        foreach ($dependencyPath in $dependencyPaths)
        {
            Get-ChildItem -Path $dependencyPath -File -Recurse |
                Unblock-File -ErrorAction Stop
        }
    }

    $modulePaths = @($RequiredModulesDirectory) + @(
        $env:PSModulePath -split [System.IO.Path]::PathSeparator |
            Where-Object { $_ -and $_ -ne $RequiredModulesDirectory }
    )
    $env:PSModulePath = $modulePaths -join [System.IO.Path]::PathSeparator
    Write-Host 'Module dependencies are ready.' -ForegroundColor Green
}

function Import-BuildModule
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Name
    )

    $dependencyGroups = Import-PowerShellDataFile -Path $DependencyManifest
    $moduleVersion = $dependencyGroups.Build[$Name]
    if (-not $moduleVersion)
    {
        $moduleVersion = $dependencyGroups.Publish[$Name]
    }

    $moduleManifest = Join-Path (Join-Path (Join-Path $RequiredModulesDirectory $Name) $moduleVersion) "$Name.psd1"
    Import-Module -Name $moduleManifest -Global -ErrorAction Stop
}

function Build-ProjectModule
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ModuleVersion
    )

    Write-Host "Building $ModuleName $ModuleVersion from source" -ForegroundColor Cyan
    Import-BuildModule -Name Configuration
    Import-BuildModule -Name ModuleBuilder

    if (Test-Path -LiteralPath $BuiltModuleDirectory)
    {
        Remove-Item -LiteralPath $BuiltModuleDirectory -Recurse -Force
    }

    $buildParameters = @{
        SourcePath               = $SourceManifest
        OutputDirectory          = $OutputDirectory
        SemVer                   = $ModuleVersion
        Encoding                 = 'UTF8'
        ErrorAction              = 'Stop'
    }

    # Optional source layout; modules without these files or folders still build.
    $sourceDirectory = Split-Path -Parent $SourceManifest
    $copyPaths = @(@('en-US', 'include', 'format') | Where-Object { Test-Path -LiteralPath (Join-Path $sourceDirectory $_) })
    if ($copyPaths.Count -gt 0)
    {
        $buildParameters.CopyPaths = $copyPaths
    }
    foreach ($part in @('Prefix', 'Suffix'))
    {
        $partFile = "$($part.ToLowerInvariant()).ps1"
        if (Test-Path -LiteralPath (Join-Path $sourceDirectory $partFile))
        {
            $buildParameters[$part] = $partFile
        }
    }

    Build-Module @buildParameters | Out-Host

    $numericVersion = $ModuleVersion.Split('-')[0]
    $modulePath = Join-Path (Join-Path $BuiltModuleDirectory $numericVersion) "$ModuleName.psd1"
    if (-not (Test-Path -LiteralPath $modulePath))
    {
        throw "ModuleBuilder did not create the expected module manifest: $modulePath"
    }

    Write-Host 'Adding release notes from the changelog.'
    $changelog = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot 'CHANGELOG.md'))
    $releaseTags = & git -C $PSScriptRoot tag --points-at HEAD
    if ($LASTEXITCODE -ne 0)
    {
        throw 'Could not read the Git tags for the current commit.'
    }

    if ($releaseTags -contains "v$ModuleVersion")
    {
        $versionPattern = '(?ms)^## \[' + [regex]::Escape($ModuleVersion) + '\][^\r\n]*\r?\n(?<notes>.*?)(?=^## \[|\z)'
        $releaseNotesMatch = [regex]::Match($changelog, $versionPattern)
    }
    else
    {
        $releaseNotesMatch = [regex]::Match($changelog, '(?ms)^## \[Unreleased\][^\r\n]*\r?\n(?<notes>.*?)(?=^## \[|\z)')
    }

    if (-not $releaseNotesMatch.Success)
    {
        throw "Could not find release notes for $ModuleName $ModuleVersion in CHANGELOG.md."
    }

    Update-Metadata -Path $modulePath -PropertyName PrivateData.PSData.ReleaseNotes -Value $releaseNotesMatch.Groups['notes'].Value.Trim() -ErrorAction Stop

    $builtManifest = Import-PowerShellDataFile -LiteralPath $modulePath
    $expectedPrerelease = ($ModuleVersion -split '-', 2 | Select-Object -Skip 1) -join ''
    if ($builtManifest.ModuleVersion -ne $numericVersion -or
        [string]$builtManifest.PrivateData.PSData.Prerelease -cne $expectedPrerelease)
    {
        throw "The built manifest does not match the requested release version '$ModuleVersion'."
    }

    Write-Host "Module built successfully: $(Split-Path -Parent $modulePath)" -ForegroundColor Green
    return (Split-Path -Parent $modulePath)
}

function Invoke-ModuleTests
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ModuleVersion,

        [ValidateSet('All', 'Module', 'Infrastructure', 'Integration')]
        [string]
        $TestSuite = 'All',

        [string[]]
        $Tag
    )

    Write-Host 'Preparing Pester and PSScriptAnalyzer' -ForegroundColor Cyan
    Import-BuildModule -Name PSScriptAnalyzer
    Import-BuildModule -Name Pester
    Import-BuildModule -Name ModuleBuilder
    $env:PSModulePath = $OutputDirectory + [System.IO.Path]::PathSeparator + $env:PSModulePath

    New-Item -ItemType Directory -Path $TestResultsDirectory -Force | Out-Null

    $configuration = New-PesterConfiguration
    $configuration.Run.Path = switch ($TestSuite)
    {
        'Module' { Join-Path $PSScriptRoot 'tests\Unit'; Join-Path $PSScriptRoot 'tests\QA' }
        'Infrastructure' { Join-Path $PSScriptRoot 'tests\Build' }
        'Integration' { Join-Path $PSScriptRoot 'tests\Integration' }
        'All' { Join-Path $PSScriptRoot 'tests\Unit'; Join-Path $PSScriptRoot 'tests\QA'; Join-Path $PSScriptRoot 'tests\Build' }
    }
    $configuration.Run.PassThru = $true
    $configuration.Output.Verbosity = 'Detailed'
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputFormat = 'NUnitXml'
    $configuration.TestResult.OutputPath = Join-Path $TestResultsDirectory "$ModuleName.Tests.xml"
    $builtModulePath = Join-Path (Join-Path (Join-Path $OutputDirectory $ModuleName) $ModuleVersion.Split('-')[0]) "$ModuleName.psm1"
    if ($Tag)
    {
        $configuration.Filter.Tag = $Tag
    }
    $configuration.CodeCoverage.Enabled = ($TestSuite -in @('All', 'Module')) -and -not $Tag
    $configuration.CodeCoverage.Path = @($builtModulePath)
    $configuration.CodeCoverage.OutputFormat = 'JaCoCo'
    $configuration.CodeCoverage.OutputPath = Join-Path $TestResultsDirectory 'JaCoCo_coverage.xml'
    $configuration.CodeCoverage.CoveragePercentTarget = 1

    $tagDescription = if ($Tag) { "; tags: $($Tag -join ', ')" } else { '' }
    Write-Host "Running Pester tests for $ModuleName $ModuleVersion (suite: $TestSuite; coverage: $($configuration.CodeCoverage.Enabled.Value)$tagDescription)" -ForegroundColor Cyan
    $result = Invoke-Pester -Configuration $configuration

    if ($result.Result -ne 'Passed')
    {
        throw "Pester did not pass (result: $($result.Result); failed tests: $($result.FailedCount); failed containers: $($result.FailedContainersCount)). See the Pester output above for details."
    }

    if ($configuration.CodeCoverage.Enabled.Value)
    {
        & (Join-Path $PSScriptRoot 'scripts\ConvertTo-SourceCoverage.ps1') `
            -ReportPath $configuration.CodeCoverage.OutputPath.Value `
            -BuiltModulePath $builtModulePath `
            -SourceDirectory (Join-Path $PSScriptRoot 'source')

        [xml]$CoverageReport = Get-Content -LiteralPath $configuration.CodeCoverage.OutputPath.Value -Raw
        $InstructionCounter = $CoverageReport.SelectSingleNode('/report/counter[@type="INSTRUCTION"]')
        $CoveredInstructions = [long]$InstructionCounter.covered
        $TotalInstructions = $CoveredInstructions + [long]$InstructionCounter.missed
        if ($TotalInstructions -gt 0)
        {
            $SourcePercent = [math]::Round(100 * $CoveredInstructions / $TotalInstructions, 2)
            Write-Host "Source coverage from JaCoCo (public/private only): $SourcePercent% ($CoveredInstructions of $TotalInstructions instructions)" -ForegroundColor Cyan
        }

        if ($result.CodeCoverage.CommandsAnalyzedCount -eq 0 -or
            $result.CodeCoverage.CoveragePercent -lt $configuration.CodeCoverage.CoveragePercentTarget.Value)
        {
            throw "Code coverage is below the required target: $($result.CodeCoverage.CoveragePercent)% / $($configuration.CodeCoverage.CoveragePercentTarget.Value)%."
        }
    }

    Write-Host "Pester tests passed. Test results and coverage reports: $TestResultsDirectory" -ForegroundColor Green
}

function New-ModulePackage
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ModuleVersion
    )

    $modulePath = Join-Path $BuiltModuleDirectory $ModuleVersion.Split('-')[0]
    $packagePath = Join-Path $OutputDirectory "$ModuleName.$ModuleVersion.zip"
    $manifestPath = Join-Path $modulePath "$ModuleName.psd1"
    $requiresBuild = -not (Test-Path -LiteralPath $manifestPath)

    if (-not $requiresBuild)
    {
        $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
        $builtVersion = [string]$manifest.ModuleVersion
        if ($manifest.PrivateData.PSData.Prerelease)
        {
            $builtVersion += "-$($manifest.PrivateData.PSData.Prerelease)"
        }
        $requiresBuild = $builtVersion -cne $ModuleVersion
    }

    if ($requiresBuild)
    {
        $modulePath = Build-ProjectModule -ModuleVersion $ModuleVersion
    }

    if (Test-Path -LiteralPath $packagePath)
    {
        Remove-Item -LiteralPath $packagePath -Force
    }

    Write-Host "Creating ZIP package for $ModuleName $ModuleVersion" -ForegroundColor Cyan
    Compress-Archive -Path (Join-Path $modulePath '*') -DestinationPath $packagePath -CompressionLevel Optimal
    Write-Host "Package created successfully: $packagePath" -ForegroundColor Green
}

switch ($Task)
{
    'Clean'
    {
        Write-Host 'Cleaning generated modules, test results, and ZIP packages. Restored dependencies will be kept.' -ForegroundColor Cyan
        foreach ($path in @($BuiltModuleDirectory, $TestResultsDirectory))
        {
            if (Test-Path -LiteralPath $path)
            {
                Remove-Item -LiteralPath $path -Recurse -Force
            }
        }

        Get-ChildItem -Path $OutputDirectory -Filter "$ModuleName.*.zip" -File -ErrorAction SilentlyContinue |
            Remove-Item -Force
        break
    }

    'InstallDependencies'
    {
        Initialize-BuildDependencies -IncludeDocumentation
        break
    }

    default
    {
        Initialize-BuildDependencies
        $resolvedVersion = Get-ModuleVersion
        $builtModulePath = Build-ProjectModule -ModuleVersion $resolvedVersion

        if ($Task -in @('Test', 'Verify'))
        {
            $testTags = @($Tag | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
            Invoke-ModuleTests -ModuleVersion $resolvedVersion -TestSuite $TestSuite -Tag $testTags
        }

        if ($Task -eq 'Package')
        {
            New-ModulePackage -ModuleVersion $resolvedVersion
        }

        if ($Task -eq 'Verify')
        {
            Write-Host "Build and tests passed for $ModuleName $resolvedVersion ($builtModulePath)"
        }
    }
}

Write-Host "Build task [$($Task.ToLowerInvariant())] completed successfully." -ForegroundColor Green
