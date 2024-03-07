<#
    .SYNOPSIS
        Tasks for releasing modules.

    .PARAMETER OutputDirectory
        The base directory of all output. Defaults to folder 'output' relative to
        the $BuildRoot.

    .PARAMETER BuiltModuleSubdirectory
        The parent path of the module to be built.

    .PARAMETER VersionedOutputDirectory
        If the module should be built using a version folder, e.g. ./MyModule/1.0.0.
        Defaults to $true.

    .PARAMETER ChangelogPath
        The path to and the name of the changelog file. Defaults to 'CHANGELOG.md'.

    .PARAMETER ReleaseNotesPath
        The path to and the name of the release notes file. Defaults to 'ReleaseNotes.md'.

    .PARAMETER ProjectName
        The project name.

    .PARAMETER ModuleVersion
        The module version that was built.

    .PARAMETER GalleryApiToken
        The module version that was built.

    .PARAMETER NuGetPublishSource
        The source to publish nuget packages. Defaults to https://www.powershellgallery.com.

    .PARAMETER PSModuleFeed
        The name of the feed (repository) that is passed to command Publish-Module.
        Defaults to 'PSGallery'.

    .PARAMETER SkipPublish
        If publishing should be skipped. Defaults to $false.

    .PARAMETER PublishModuleWhatIf
        If the publish command will be run with '-WhatIf' to show what will happen
        during publishing. Defaults to $false.

    .PARAMETER ChocolateyBuildOutput
        Sub-Folder (or absolute path) of the Chocolatey build output folder (relative
        to $OutputDirectory). Contain the path to one or more Chocolatey packages.
        This variable $ChocolateyBuildOutput also used to determine if the repository
        is building a Chocolatey package. Defaults to 'choco'.
#>

param
(
    [Parameter()]
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $VersionedOutputDirectory = (property VersionedOutputDirectory $true),

    [Parameter()]
    $ChangelogPath = (property ChangelogPath 'CHANGELOG.md'),

    [Parameter()]
    $ReleaseNotesPath = (property ReleaseNotesPath (Join-Path $OutputDirectory 'ReleaseNotes.md')),

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $ModuleVersion = (property ModuleVersion ''),

    [Parameter()]
    [string]
    $GalleryApiToken = (property GalleryApiToken ''),

    [Parameter()]
    [string]
    $NuGetPublishSource = (property NuGetPublishSource 'https://www.powershellgallery.com/'),

    [Parameter()]
    $SkipPublish = (property SkipPublish ''),

    [Parameter()]
    $PublishModuleWhatIf = (property PublishModuleWhatIf ''),

    [Parameter()]
    [string]
    $ChocolateyBuildOutput = (property ChocolateyBuildOutput 'choco')
)

# Synopsis: Publish a built PowerShell module to a gallery.
Task publish_module_to_gallery -if ($GalleryApiToken -and (Get-Command -Name 'Publish-Module' -ErrorAction 'SilentlyContinue')) {
    . Set-SamplerTaskVariable

    Import-Module -name 'ModuleBuilder' -ErrorAction 'Stop'

    # Parse PublishModuleWhatIf to be boolean
    $null = [bool]::TryParse($PublishModuleWhatIf, [ref]$script:PublishModuleWhatIf)

    if (-not $BuiltModuleManifest)
    {
        throw "No valid manifest found for project $ProjectName."
    }

    # Uncomment release notes (the default in Plaster/New-ModuleManifest)
    $ManifestString = Get-Content -Raw $BuiltModuleManifest
    if ( $ManifestString -match '#\sReleaseNotes\s?=')
    {
        $ManifestString = $ManifestString -replace '#\sReleaseNotes\s?=', '  ReleaseNotes ='
        $Utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($False)
        [System.IO.File]::WriteAllLines($BuiltModuleManifest, $ManifestString, $Utf8NoBomEncoding)
    }

    Write-Build DarkGray "`nAbout to release '$BuiltModuleBase'."
    Write-Build DarkGray "APIToken: $($GalleryApiToken.SubString(0,4))..."
    Write-Build DarkGray 'Repository: PSGallery'

    $PublishModuleParams = @{
        Path        = $BuiltModuleBase
        NuGetApiKey = $GalleryApiToken
        Repository  = 'PSGallery'
        ErrorAction = 'Stop'
    }

    if ($PublishModuleWhatIf)
    {
        $PublishModuleParams['WhatIf'] = $true
    }

    if (!$SkipPublish)
    {
        # Release notes will be used from module manifest
        try
        {
            Publish-Module @PublishModuleParams -ErrorAction SilentlyContinue
        }
        catch
        {
            if ($_.Exception.message -like '*is already available in the repository*')
            {
                Write-Build Yellow 'This module version is already published to PSGallery'
            }
            else
            {
                throw $_
            }
        }
    }

    Write-Build Green 'Package Published to PSGallery.'
}
