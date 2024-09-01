function Get-IMAlbumStatistic
{
    <#
    .DESCRIPTION
        Retreives Immich album statistics
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMAlbumStatistics

        Retreives Immich album statistics
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/albums/statistics' -ImmichSession:$Session
}
#endregion
