[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $ProjectRoot,

    [Parameter()]
    [string]
    $Version
)

if ([string]::IsNullOrWhiteSpace($ProjectRoot))
{
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}

$manifests = @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'source') -Filter '*.psd1' -File -ErrorAction Stop)
if ($manifests.Count -ne 1)
{
    throw "Expected exactly one module manifest in the source directory; found $($manifests.Count)."
}

$manifest = $manifests[0]
$data = Import-PowerShellDataFile -LiteralPath $manifest.FullName -ErrorAction Stop

$trackingManifest = Join-Path $ProjectRoot '.release-please-manifest.json'
if (-not $PSBoundParameters.ContainsKey('Version'))
{
    if (Test-Path -LiteralPath $trackingManifest)
    {
        $tracking = Get-Content -LiteralPath $trackingManifest -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $Version = $tracking.'.'
    }
    else
    {
        $Version = $data.ModuleVersion
        if ($data.PrivateData.PSData.Prerelease)
        {
            $Version += "-$($data.PrivateData.PSData.Prerelease)"
        }
    }
}

$versionMatch = [regex]::Match($Version, '^(?<numeric>(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*))(?:-(?<prerelease>[A-Za-z][A-Za-z0-9]*))?$')
if (-not $versionMatch.Success)
{
    throw "Invalid release version '$Version'. Use Major.Minor.Patch with an optional Gallery-compatible suffix such as '-beta001' (no dots or build metadata)."
}

$numericVersion = $versionMatch.Groups['numeric'].Value
$null = [version]$numericVersion

[pscustomobject]@{
    Name           = $manifest.BaseName
    Version        = $Version
    ModuleVersion  = $numericVersion
    Prerelease     = $versionMatch.Groups['prerelease'].Value
    SourceManifest = $manifest.FullName
}
