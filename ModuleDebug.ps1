$project = & (Join-Path $PSScriptRoot 'scripts\Get-BuildProject.ps1') -ProjectRoot $PSScriptRoot
$moduleManifest = Join-Path $PSScriptRoot "output\$($project.Name)\$($project.ModuleVersion)\$($project.Name).psd1"

if (-not (Test-Path -LiteralPath $moduleManifest))
{
    throw "Built module manifest not found at '$moduleManifest'. Run './build.ps1 -Task Build' first."
}

Import-Module $moduleManifest -Force

# Add manual test scenarios for PSImmich here.
