function Get-IMServerStorage
{
    <#
    .SYNOPSIS
        Retrieves server storage information.
    .DESCRIPTION
        Gets storage usage details and disk space information from Immich server.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .EXAMPLE
        Get-IMServerStorage

        Gets server storage usage information.
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/server/storage' -ImmichSession:$Session

}
#endregion
