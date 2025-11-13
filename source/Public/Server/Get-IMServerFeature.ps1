function Get-IMServerFeature
{
    <#
    .SYNOPSIS
        Retrieves server feature availability.
    .DESCRIPTION
        Gets enabled features and capabilities of the Immich server.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .EXAMPLE
        Get-IMServerFeature

        Lists available server features.
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -noauth -Method Get -RelativePath '/server/features' -ImmichSession:$Session

}
#endregion
