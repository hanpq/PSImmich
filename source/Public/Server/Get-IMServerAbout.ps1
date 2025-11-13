function Get-IMServerAbout
{
    <#
    .SYNOPSIS
        Retrieves server about information.
    .DESCRIPTION
        Gets basic server details and identification information.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .EXAMPLE
        Get-IMServerAbout

        Gets server about information.
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/server/about' -ImmichSession:$Session

}
#endregion
