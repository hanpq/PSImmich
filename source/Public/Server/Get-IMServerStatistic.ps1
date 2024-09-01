function Get-IMServerStatistic
{
    <#
    .DESCRIPTION
        Retreives Immich server statistic
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMServerStatistic

        Retreives Immich server statistic
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/server/statistics' -ImmichSession:$Session

}
#endregion
