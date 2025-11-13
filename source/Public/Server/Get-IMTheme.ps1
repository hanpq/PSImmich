function Get-IMTheme
{
    <#
    .SYNOPSIS
        Retrieves Immich theme CSS.
    .DESCRIPTION
        Gets current theme CSS styling for Immich interface.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .EXAMPLE
        Get-IMTheme

        Gets current theme CSS.
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/server/theme' -ImmichSession:$Session

}
#endregion
