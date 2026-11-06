[CmdletBinding()]
param
(
    [Parameter(Mandatory)]
    [string]
    $Tag,

    [Parameter(Mandatory)]
    [bool]
    $IsPrerelease,

    [Parameter()]
    [string]
    $RefTag,

    [Parameter()]
    [string]
    $BuiltModulePath,

    [Parameter()]
    [string]
    $ProjectRoot
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ProjectRoot))
{
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}

$project = & (Join-Path $PSScriptRoot 'Get-BuildProject.ps1') -ProjectRoot $ProjectRoot
if ($Tag -cne "v$($project.Version)")
{
    throw "Release tag '$Tag' does not match tracked version 'v$($project.Version)'."
}
if (-not [string]::IsNullOrWhiteSpace($RefTag) -and $Tag -cne $RefTag)
{
    throw "Release event tag '$Tag' does not match checked-out ref '$RefTag'."
}

$hasPrerelease = -not [string]::IsNullOrEmpty($project.Prerelease)
if ($IsPrerelease -ne $hasPrerelease)
{
    throw "The GitHub prerelease flag does not match version '$($project.Version)'."
}

if (-not [string]::IsNullOrWhiteSpace($BuiltModulePath))
{
    $builtManifestPath = Join-Path $BuiltModulePath "$($project.Name).psd1"
    if (-not (Test-Path -LiteralPath $builtManifestPath -PathType Leaf))
    {
        throw "Built module manifest '$builtManifestPath' does not exist."
    }

    $builtManifest = Import-PowerShellDataFile -LiteralPath $builtManifestPath
    $builtVersion = [string]$builtManifest.ModuleVersion
    $builtPrerelease = [string]$builtManifest.PrivateData.PSData.Prerelease
    if ($builtVersion -cne $project.ModuleVersion -or $builtPrerelease -cne $project.Prerelease)
    {
        $builtFullVersion = if ($builtPrerelease) { "$builtVersion-$builtPrerelease" } else { $builtVersion }
        throw "Built module version '$builtFullVersion' does not match tracked version '$($project.Version)'."
    }
}

$project
