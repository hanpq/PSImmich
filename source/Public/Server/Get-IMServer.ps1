function Get-IMServer
{
    <#
    .SYNOPSIS
        Retrieves comprehensive Immich server information.
    .DESCRIPTION
        Gets detailed server properties including version, features, statistics, and configuration.
        Use different parameter sets to retrieve specific information about the Immich server.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER About
        Retrieves general server information and about details.
    .PARAMETER Version
        Retrieves server version information in a formatted object.
    .PARAMETER VersionHistory
        Retrieves server version history and release information.
    .PARAMETER Features
        Retrieves information about enabled server features.
    .PARAMETER Statistics
        Retrieves server usage statistics.
    .PARAMETER Configuration
        Retrieves server configuration settings.
    .PARAMETER AppliedSystemConfiguration
        Retrieves currently applied system configuration.
    .PARAMETER DefaultSystemConfiguration
        Retrieves default system configuration values.
    .PARAMETER ReturnRawJSON
        Returns system configuration as raw JSON instead of PowerShell object.
        Only valid with AppliedSystemConfiguration or DefaultSystemConfiguration.
    .PARAMETER StorageTemplateOptions
        Retrieves available storage template options.
    .PARAMETER Storage
        Retrieves server storage information and usage.
    .PARAMETER MediaTypes
        Retrieves supported media types and formats.
    .PARAMETER Theme
        Retrieves server theme configuration.
    .PARAMETER APKLinks
        Retrieves mobile application download links.
    .PARAMETER VersionCheck
        Checks for available server updates.
    .PARAMETER Ping
        Tests server connectivity and responsiveness.
    .EXAMPLE
        Get-IMServer

        Retrieves general server information and about details (default).
    .EXAMPLE
        Get-IMServer -Version

        Gets the server version in a formatted object.
    .EXAMPLE
        Get-IMServer -Statistics

        Retrieves server usage statistics.
    .EXAMPLE
        Get-IMServer -AppliedSystemConfiguration -ReturnRawJSON

        Gets current system configuration as raw JSON.
    .EXAMPLE
        Get-IMServer -Ping

        Tests if the server is responding.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP switch parameters used to determine parameter sets')]
    [CmdletBinding(DefaultParameterSetName = 'about')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(ParameterSetName = 'about')]
        [switch]
        $About,

        [Parameter(ParameterSetName = 'version')]
        [switch]
        $Version,

        [Parameter(ParameterSetName = 'version-history')]
        [switch]
        $VersionHistory,

        [Parameter(ParameterSetName = 'features')]
        [switch]
        $Features,

        [Parameter(ParameterSetName = 'statistics')]
        [switch]
        $Statistics,

        [Parameter(ParameterSetName = 'configuration')]
        [switch]
        $Configuration,

        [Parameter(ParameterSetName = 'appliedsystemconfiguration')]
        [switch]
        $AppliedSystemConfiguration,

        [Parameter(ParameterSetName = 'defaultsystemconfiguration')]
        [switch]
        $DefaultSystemConfiguration,

        [Parameter(ParameterSetName = 'appliedsystemconfiguration')]
        [Parameter(ParameterSetName = 'defaultsystemconfiguration')]
        [switch]
        $ReturnRawJSON,

        [Parameter(ParameterSetName = 'storagetemplateoptions')]
        [switch]
        $StorageTemplateOptions,

        [Parameter(ParameterSetName = 'storage')]
        [switch]
        $Storage,

        [Parameter(ParameterSetName = 'mediatypes')]
        [switch]
        $MediaTypes,

        [Parameter(ParameterSetName = 'theme')]
        [switch]
        $Theme,

        [Parameter(ParameterSetName = 'apklinks')]
        [switch]
        $APKLinks,

        [Parameter(ParameterSetName = 'versioncheck')]
        [switch]
        $VersionCheck,

        [Parameter(ParameterSetName = 'ping')]
        [switch]
        $Ping
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'about'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/server/about' -ImmichSession:$Session
        }
        'version'
        {
            $Result = InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server/version' -ImmichSession:$Session
            return [pscustomobject]@{
                version = "$($Result.Major).$($Result.Minor).$($Result.Patch)"
            }
        }
        'version-history'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/server/version-history' -ImmichSession:$Session
        }
        'features'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/server/features' -ImmichSession:$Session
        }
        'statistics'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/server/statistics' -ImmichSession:$Session
        }
        'configuration'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/server/config' -ImmichSession:$Session
        }
        'appliedsystemconfiguration'
        {
            $Result = InvokeImmichRestMethod -Method Get -RelativePath '/system-config' -ImmichSession:$Session
            if ($ReturnRawJSON)
            {
                $Result | ConvertTo-Json -Depth 10
            }
            else
            {
                $Result
            }
        }
        'defaultsystemconfiguration'
        {
            $Result = InvokeImmichRestMethod -Method Get -RelativePath '/system-config/defaults' -ImmichSession:$Session
            if ($ReturnRawJSON)
            {
                $Result | ConvertTo-Json -Depth 10
            }
            else
            {
                $Result
            }
        }
        'storagetemplateoptions'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/system-config/storage-template-options' -ImmichSession:$Session
        }
        'storage'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/server/storage' -ImmichSession:$Session
        }
        'mediatypes'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/server/media-types' -ImmichSession:$Session
        }
        'theme'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/server/theme' -ImmichSession:$Session
        }
        'ping'
        {
            $Result = InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server/ping' -ImmichSession:$Session
            if ($Result.res -eq 'pong')
            {
                return [pscustomobject]@{responds = $true }
            }
            else
            {
                return [pscustomobject]@{responds = $false }
            }
        }
        'apklinks'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/server/apk-links' -ImmichSession:$Session
        }
        'versioncheck'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/server/version-check' -ImmichSession:$Session
        }
    }
}
