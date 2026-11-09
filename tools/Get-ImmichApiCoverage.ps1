<#
.SYNOPSIS
    Reports which OpenAPI operations the module reaches through the internal API layer.

.DESCRIPTION
    Each operation in the spec maps to one generated function, named
    Invoke-ImmichApi<operationId in PascalCase> (see tools/New-ImmichApiLayer.ps1).
    Every operation is classified as:
    - Excluded:    listed in api/exclusions.json by method and path.
    - Tested:      its function is referenced under the unit test folder (Mock or Should -Invoke).
    - Reachable:   its function is referenced from module source outside source/private/api.
    - Unreachable: none of the above.

    Reachability and testing are static name references, so they show that a route is wired
    and exercised by a test, not that its parameters or response mapping are correct.

.PARAMETER SpecPath
    OpenAPI JSON specification. Defaults to api/api.3.3.6.json.

.PARAMETER ExclusionsPath
    Exclusion list with ExcludedPaths entries (Path, Method, Reason).

.PARAMETER SourcePath
    Module source folder.

.PARAMETER TestPath
    Unit test folder.

.PARAMETER OutputPath
    Optional CSV file to write the per-operation report to.

.PARAMETER PassThru
    Emit the per-operation report objects to the pipeline.

.PARAMETER Strict
    Exit with code 1 when a non-excluded operation is unreachable.

.EXAMPLE
    .\tools\Get-ImmichApiCoverage.ps1 -OutputPath .\output\api-coverage.csv
#>
[CmdletBinding()]
param(
    [string]$SpecPath = (Join-Path $PSScriptRoot '..\api\api.3.3.6.json'),
    [string]$ExclusionsPath = (Join-Path $PSScriptRoot '..\api\exclusions.json'),
    [string]$SourcePath = (Join-Path $PSScriptRoot '..\source'),
    [string]$TestPath = (Join-Path $PSScriptRoot '..\tests\Unit'),
    [string]$OutputPath,
    [switch]$PassThru,
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'

# Must match the HTTP methods and naming used by tools/New-ImmichApiLayer.ps1.
$HttpMethods = @('get', 'post', 'put', 'patch', 'delete')

function ConvertTo-PascalCase([string]$Name)
{
    $Parts = @([regex]::Split($Name, '[^A-Za-z0-9]+') | Where-Object { $_ })
    return (($Parts | ForEach-Object { $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1) }) -join '')
}

function Get-ReferencedFunctionName([string[]]$Folders, [string[]]$ExcludeFolders = @())
{
    $Files = foreach ($Folder in $Folders)
    {
        Get-ChildItem -LiteralPath $Folder -Filter '*.ps1' -Recurse -File |
            Where-Object {
                $FullName = $_.FullName
                -not ($ExcludeFolders | Where-Object { $FullName.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) })
            }
    }

    $Names = @{}
    foreach ($File in $Files)
    {
        foreach ($Match in [regex]::Matches((Get-Content -LiteralPath $File.FullName -Raw), 'Invoke-ImmichApi[A-Za-z0-9]+'))
        {
            $Names[$Match.Value] = $true
        }
    }
    return $Names
}

$SpecFullPath = (Resolve-Path -LiteralPath $SpecPath).Path
$Spec = Get-Content -LiteralPath $SpecFullPath -Raw | ConvertFrom-Json
$Exclusions = (Get-Content -LiteralPath (Resolve-Path -LiteralPath $ExclusionsPath).Path -Raw | ConvertFrom-Json).ExcludedPaths

$SourceFull = (Resolve-Path -LiteralPath $SourcePath).Path
$GeneratedFolder = Join-Path $SourceFull 'private\api'
$ReachableNames = Get-ReferencedFunctionName -Folders @($SourceFull) -ExcludeFolders @($GeneratedFolder)
$TestedNames = Get-ReferencedFunctionName -Folders @((Resolve-Path -LiteralPath $TestPath).Path)

$Report = foreach ($PathProperty in $Spec.paths.PSObject.Properties)
{
    foreach ($Method in $HttpMethods)
    {
        $Operation = $PathProperty.Value.$Method
        if ($null -eq $Operation)
        {
            continue
        }

        $FunctionName = 'Invoke-ImmichApi' + (ConvertTo-PascalCase ([string]$Operation.operationId))
        $Path = $PathProperty.Name
        $MethodUpper = $Method.ToUpperInvariant()

        $Exclusion = $Exclusions | Where-Object { $_.Path -eq $Path -and $_.Method -eq $MethodUpper } | Select-Object -First 1
        $Status = if ($Exclusion) { 'Excluded' }
            elseif ($TestedNames.ContainsKey($FunctionName)) { 'Tested' }
            elseif ($ReachableNames.ContainsKey($FunctionName)) { 'Reachable' }
            else { 'Unreachable' }

        [pscustomobject]@{
            Method     = $MethodUpper
            Path       = $Path
            OperationId = [string]$Operation.operationId
            Function   = $FunctionName
            Deprecated = [bool]$Operation.deprecated
            Status     = $Status
            Reason     = if ($Exclusion) { [string]$Exclusion.Reason } else { '' }
        }
    }
}

$Total = @($Report).Count
$Counts = $Report | Group-Object Status | ForEach-Object { [pscustomobject]@{ Status = $_.Name; Count = $_.Count } }
$Eligible = $Total - (@($Report | Where-Object Status -eq 'Excluded')).Count
$Covered = @($Report | Where-Object { $_.Status -in 'Tested', 'Reachable' }).Count

Write-Host ("Spec: {0} ({1} operations, {2} excluded)" -f (Split-Path $SpecFullPath -Leaf), $Total, (@($Report | Where-Object Status -eq 'Excluded')).Count)
$Counts | Format-Table -AutoSize | Out-String | Write-Host
if ($Eligible -gt 0)
{
    Write-Host ("Wired (reachable or tested) for {0} of {1} non-excluded operations ({2:P1})." -f $Covered, $Eligible, ($Covered / $Eligible))
}

if ($OutputPath)
{
    $Report | Sort-Object Status, Path, Method | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Report written to $OutputPath"
}

if ($PassThru)
{
    $Report
}

if ($Strict -and (@($Report | Where-Object Status -eq 'Unreachable')).Count -gt 0)
{
    Write-Error 'Non-excluded operations are unreachable from the module.'
    exit 1
}
