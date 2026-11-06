[CmdletBinding()]
param
(
    [Parameter(Mandatory)]
    [string]
    $ModulePath,

    [Parameter(Mandatory)]
    [string]
    $DocsRepositoryPath,

    [Parameter()]
    [string]
    $OutputDirectory
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$project = & (Join-Path $PSScriptRoot 'Get-BuildProject.ps1') -ProjectRoot $ProjectRoot
$moduleName = $project.Name

foreach ($pathVariable in @('ModulePath', 'DocsRepositoryPath'))
{
    $pathValue = Get-Variable -Name $pathVariable -ValueOnly
    if ([System.IO.Path]::IsPathRooted($pathValue))
    {
        $pathValue = [System.IO.Path]::GetFullPath($pathValue)
    }
    else
    {
        $pathValue = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $pathValue))
    }

    Set-Variable -Name $pathVariable -Value $pathValue
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
    $OutputDirectory = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $OutputDirectory))
}

if (-not $env:DOCS_GITHUB_TOKEN)
{
    throw 'Set DOCS_GITHUB_TOKEN to enable the getps.dev documentation update.'
}

if (-not (Test-Path -LiteralPath (Join-Path $DocsRepositoryPath '.git')))
{
    throw "Documentation repository was not checked out at '$DocsRepositoryPath'."
}

$moduleManifest = Join-Path $ModulePath "$moduleName.psd1"
if (-not (Test-Path -LiteralPath $moduleManifest))
{
    throw "Built $moduleName manifest not found at '$moduleManifest'."
}

& (Join-Path $ProjectRoot 'build.ps1') -Task InstallDependencies -OutputDirectory $OutputDirectory

$requiredModulesPath = Join-Path $OutputDirectory 'RequiredModules'
$env:PSModulePath = $requiredModulesPath + [System.IO.Path]::PathSeparator + $env:PSModulePath
Import-Module 'Alt3.Docusaurus.Powershell' -RequiredVersion '1.0.37' -ErrorAction Stop
Import-Module platyPS -RequiredVersion '0.14.2' -ErrorAction Stop

$module = Import-Module -Name $moduleManifest -Force -PassThru -ErrorAction Stop
$docsModulesPath = Join-Path $DocsRepositoryPath 'docs\modules'
New-Item -ItemType Directory -Path $docsModulesPath -Force | Out-Null

$docuSplat = @{
    Module          = $moduleName
    DocsFolder      = $docsModulesPath
    Sidebar         = "$moduleName/03-Command Reference"
    MetaDescription = 'Help page for the Powershell "%1" command'
    MetaKeywords    = @('Powershell', $moduleName, 'Help', 'Documentation')
    AppendMarkdown  = '## EDIT THIS DOC' + "`n`n" +
        'This page was auto-generated from PowerShell comment-based help. To edit this page, update the corresponding command help in the module source repository.'
}
New-DocusaurusHelp @docuSplat -ErrorAction Stop -WarningAction SilentlyContinue
Remove-Module -Name $module.Name -Force -ErrorAction Stop

$destinationModulePath = Join-Path $docsModulesPath $moduleName
if (-not (Test-Path -LiteralPath $destinationModulePath))
{
    throw "Documentation generator did not create '$destinationModulePath'."
}

$changelogPath = Join-Path $ProjectRoot 'CHANGELOG.md'
$readmePath = Join-Path $ProjectRoot 'README.md'
$changelogPrefix = @'
---
id: changelog
title: Changelog
---

'@
$getStartedPrefix = @"
---
id: $moduleName
title: $moduleName
---

"@

$changelog = [System.IO.File]::ReadAllText($changelogPath)
$changelog = [regex]::Replace($changelog, '(?<!\\)([{}])', '\$1')
$readme = [System.IO.File]::ReadAllText($readmePath)
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

[System.IO.File]::WriteAllText(
    (Join-Path $destinationModulePath '02-changelog.md'),
    $changelogPrefix + $changelog,
    $utf8NoBom
)
[System.IO.File]::WriteAllText(
    (Join-Path $destinationModulePath "$moduleName.md"),
    $getStartedPrefix + $readme,
    $utf8NoBom
)

$sidebarPath = Join-Path $destinationModulePath '03-Command Reference\docusaurus.sidebar.js'
if (Test-Path -LiteralPath $sidebarPath)
{
    Remove-Item -LiteralPath $sidebarPath -Force
}

git -C $DocsRepositoryPath config user.name 'github-actions[bot]'
if ($LASTEXITCODE -ne 0) { throw 'Could not configure the documentation commit user name.' }
git -C $DocsRepositoryPath config user.email '41898282+github-actions[bot]@users.noreply.github.com'
if ($LASTEXITCODE -ne 0) { throw 'Could not configure the documentation commit email.' }
git -C $DocsRepositoryPath add -- "docs/modules/$moduleName"
if ($LASTEXITCODE -ne 0) { throw 'Could not stage generated documentation.' }

git -C $DocsRepositoryPath diff --cached --quiet
if ($LASTEXITCODE -eq 0)
{
    Write-Host 'The getps.dev documentation is already up to date.'
    return
}
if ($LASTEXITCODE -ne 1)
{
    throw 'Could not inspect staged documentation changes.'
}

$moduleVersion = (Import-PowerShellDataFile -Path $moduleManifest).ModuleVersion
git -C $DocsRepositoryPath commit -m "docs: update $moduleName documentation for $moduleVersion"
if ($LASTEXITCODE -ne 0) { throw 'Could not commit generated documentation.' }
git -C $DocsRepositoryPath push origin HEAD:main
if ($LASTEXITCODE -ne 0) { throw 'Could not push generated documentation to getps.dev.' }

Write-Host "Updated getps.dev documentation for $moduleName $moduleVersion."
