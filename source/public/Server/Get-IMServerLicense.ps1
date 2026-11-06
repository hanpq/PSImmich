function Get-IMServerLicense
{
    <#
    .SYNOPSIS
        Retrieves server license information.
    .DESCRIPTION
        Gets current license status and details for Immich server.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .EXAMPLE
        Get-IMServerLicense

        Gets server license information.
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/server/license' -ImmichSession:$Session

}
#endregion
