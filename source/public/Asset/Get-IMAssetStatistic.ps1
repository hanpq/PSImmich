function Get-IMAssetStatistic
{
    <#
    .SYNOPSIS
        Retrieves Immich asset statistics
    .DESCRIPTION
        Retrieves comprehensive statistics about assets in the Immich library, including counts by type,
        status, and other criteria. Supports filtering by favorite status, trash status, and visibility.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER IsFavorite
        Filter statistics to include only favorite assets (true) or exclude favorites (false). If not specified, includes both.
    .PARAMETER IsTrashed
        Filter statistics to include only trashed assets (true) or exclude trashed assets (false). If not specified, includes both.
    .PARAMETER Visibility
        Filter statistics by asset visibility. Valid values are 'archive', 'timeline', 'hidden', 'locked'.
    .EXAMPLE
        Get-IMAssetStatistic

        Retrieves comprehensive asset statistics for the entire library.
    .EXAMPLE
        Get-IMAssetStatistic -IsFavorite:$true

        Retrieves statistics for favorite assets only.
    .EXAMPLE
        Get-IMAssetStatistic -IsTrashed:$false -Visibility 'timeline'

        Retrieves statistics for non-trashed assets visible in the timeline.
    .EXAMPLE
        $stats = Get-IMAssetStatistic
        Write-Host "Total images: $($stats.images), Total videos: $($stats.videos)"

        Retrieves statistics and displays specific counts.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [ApiParameter('isFavorite')]
        [boolean]
        $IsFavorite,

        [Parameter()]
        [ApiParameter('isTrashed')]
        [boolean]
        $IsTrashed,

        [Parameter()]
        [ValidateSet('archive', 'timeline', 'hidden', 'locked')]
        [ApiParameter('visibility')]
        [string]
        $Visibility
    )

    begin
    {
        $QueryParameters = @{}
        $QueryParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/assets/statistics' -ImmichSession:$Session -QueryParameters $QueryParameters
    }
}
#endregion
