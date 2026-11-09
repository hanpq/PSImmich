function Get-IMMapMarker
{
    <#
    .SYNOPSIS
        Retrieves map markers for assets with GPS coordinates.
    .DESCRIPTION
        The Get-IMMapMarker function retrieves map markers that represent the geographic
        locations of assets in Immich. Map markers are created from assets that contain
        GPS metadata and provide a visual representation for map-based navigation and
        asset discovery.

        The function supports various filters to refine the returned markers based on
        creation dates, archive status, favorites, partner sharing, and shared albums.
        This enables targeted retrieval of location data for specific asset collections.
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER CreatedAfter
        Filters map markers to include only those created after the specified date and time.
        Use this to focus on recently added location data or specific time periods.
    .PARAMETER CreatedBefore
        Filters map markers to include only those created before the specified date and time.
        Useful for historical analysis or excluding recent additions.
    .PARAMETER IsArchived
        Filters map markers based on archive status. Set to $true to include only archived
        assets, $false to exclude archived assets, or omit to include all assets regardless
        of archive status.
    .PARAMETER IsFavorite
        Filters map markers to include only favorite assets when set to $true, or exclude
        favorites when set to $false. Omit to include all assets regardless of favorite status.
    .PARAMETER WithPartners
        Controls whether to include map markers for assets shared with partners.
        Set to $true to include partner-shared assets, $false to exclude them.
    .PARAMETER WithSharedAlbums
        Controls whether to include map markers for assets in shared albums.
        Set to $true to include shared album assets, $false to exclude them.
    .EXAMPLE
        Get-IMMapMarker

        Retrieves all available map markers for assets with GPS coordinates.
    .EXAMPLE
        Get-IMMapMarker -IsFavorite $true

        Retrieves map markers only for assets marked as favorites.
    .EXAMPLE
        Get-IMMapMarker -CreatedAfter (Get-Date).AddMonths(-6) -IsArchived $false

        Gets map markers for non-archived assets created in the last 6 months.
    .EXAMPLE
        Get-IMMapMarker -WithPartners $true -WithSharedAlbums $true

        Retrieves map markers including both partner-shared and shared album assets.
    .NOTES
        Map markers are generated from assets that contain valid GPS coordinates in their metadata.
        The density and distribution of markers depend on the geographic diversity of your asset collection.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [datetime]
        $CreatedAfter,

        [Parameter()]
        [datetime]
        $CreatedBefore,

        [Parameter()]
        [boolean]
        $IsArchived,

        [Parameter()]
        [boolean]
        $IsFavorite,

        [Parameter()]
        [boolean]
        $WithPartners,

        [Parameter()]
        [boolean]
        $WithSharedAlbums
    )

    process
    {
        $ApiParams = @{ ImmichSession = $Session }
        $ParameterMap = [ordered]@{
            CreatedAfter     = 'FileCreatedAfter'
            CreatedBefore    = 'FileCreatedBefore'
            IsArchived       = 'IsArchived'
            IsFavorite       = 'IsFavorite'
            WithPartners     = 'WithPartners'
            WithSharedAlbums = 'WithSharedAlbums'
        }
        foreach ($Name in $ParameterMap.Keys)
        {
            if ($PSBoundParameters.ContainsKey($Name)) { $ApiParams[$ParameterMap[$Name]] = $PSBoundParameters[$Name] }
        }

        Invoke-ImmichApiGetMapMarkers @ApiParams | ForEach-Object { [MapMarkerResponseDto]::new($PSItem) }
    }
}
#endregion
