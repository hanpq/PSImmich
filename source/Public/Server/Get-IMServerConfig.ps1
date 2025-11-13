function Get-IMServerConfig
{
    <#
    .SYNOPSIS
        Retrieves server configuration settings.
    .DESCRIPTION
        Gets current server configuration and settings.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .EXAMPLE
        Get-IMServerConfig

        Gets current server configuration.
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server/config' -ImmichSession:$Session

}
#endregion
