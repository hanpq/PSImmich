function Get-IMAlbumStatistic
{
    <#
    .SYNOPSIS
        Retrieves Immich album statistics
    .DESCRIPTION
        Retrieves statistical information about albums in the Immich server, such as total number of albums,
        shared albums, and other aggregate data.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .EXAMPLE
        Get-IMAlbumStatistic
        
        Retrieves comprehensive album statistics for the current user.
    .EXAMPLE
        $stats = Get-IMAlbumStatistic
        Write-Host "Total albums: $($stats.totalAlbums)"
        
        Retrieves statistics and displays the total number of albums.
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
