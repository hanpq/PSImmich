function Get-IMServerStatistic
{
    <#
    .SYNOPSIS
        Retrieves server usage statistics.
    .DESCRIPTION
        Gets server performance metrics and usage statistics.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .EXAMPLE
        Get-IMServerStatistic

        Gets server usage statistics.
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/server/statistics' -ImmichSession:$Session

}
#endregion
