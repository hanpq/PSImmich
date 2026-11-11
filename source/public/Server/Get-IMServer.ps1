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
        Retrieves the server version and its independent feature level in a formatted object.
    .PARAMETER VersionHistory
        Retrieves server version history and release information.
    .PARAMETER Features
        Retrieves information about enabled server features.
    .PARAMETER Statistics
        Retrieves server usage statistics.
    .PARAMETER Configuration
        Retrieves server configuration settings.
    .PARAMETER PublicConfiguration
        Retrieves the public configuration, including passkey and map availability.
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
        Retrieves server theme configuration. Requires permission to read admin configuration.
    .PARAMETER APKLinks
        Retrieves mobile application download links.
    .PARAMETER VersionCheck
        Checks for available server updates.
    .PARAMETER Ping
        Tests server connectivity and responsiveness.
    .PARAMETER VersionCheckState
        Retrieves the state of the last server version check, including the checked time and the latest release version found.
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
        Get-IMServer -PublicConfiguration

        Gets the server's public configuration.
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

        [Parameter(ParameterSetName = 'publicconfiguration')]
        [switch]
        $PublicConfiguration,

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
        $Ping,

        [Parameter(ParameterSetName = 'versioncheckstate')]
        [switch]
        $VersionCheckState
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'about'
        {
            Invoke-ImmichApiGetAboutInfo -ImmichSession:$Session
        }
        'version'
        {
            $Result = Invoke-ImmichApiGetServerVersion -ImmichSession:$Session
            return [pscustomobject]@{
                version      = "$($Result.Major).$($Result.Minor).$($Result.Patch)"
                featureLevel = $Result.featureLevel
            }
        }
        'version-history'
        {
            Invoke-ImmichApiGetVersionHistory -ImmichSession:$Session
        }
        'features'
        {
            Invoke-ImmichApiGetServerFeatures -ImmichSession:$Session
        }
        'statistics'
        {
            Invoke-ImmichApiGetServerStatistics -ImmichSession:$Session
        }
        'configuration'
        {
            Invoke-ImmichApiGetServerConfig -ImmichSession:$Session
        }
        'publicconfiguration'
        {
            Invoke-ImmichApiGetPublicConfig -ImmichSession:$Session
        }
        'appliedsystemconfiguration'
        {
            $Result = Invoke-ImmichApiGetAdminConfig -ImmichSession:$Session
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
            $Result = Invoke-ImmichApiGetAdminConfigDefaults -ImmichSession:$Session
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
            Invoke-ImmichApiGetStorageTemplateOptions -ImmichSession:$Session
        }
        'storage'
        {
            Invoke-ImmichApiGetStorage -ImmichSession:$Session
        }
        'mediatypes'
        {
            Invoke-ImmichApiGetSupportedMediaTypes -ImmichSession:$Session
        }
        'theme'
        {
            $Result = Invoke-ImmichApiGetAdminConfig -ImmichSession:$Session
            $Result.theme
        }
        'ping'
        {
            $Result = Invoke-ImmichApiPingServer -ImmichSession:$Session
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
            Invoke-ImmichApiGetApkLinks -ImmichSession:$Session
        }
        'versioncheck'
        {
            Invoke-ImmichApiGetVersionCheck -ImmichSession:$Session
        }
        'versioncheckstate'
        {
            [VersionCheckStateResponseDto]::new((Invoke-ImmichApiGetVersionCheckState -ImmichSession:$Session))
        }
    }
}
