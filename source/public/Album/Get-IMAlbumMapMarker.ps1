function Get-IMAlbumMapMarker
{
    <#
    .SYNOPSIS
        Retrieves the map markers for the assets in an Immich album
    .DESCRIPTION
        Retrieves the geographic markers (asset ID, latitude and longitude, and location details)
        for the assets that have GPS data in an album. Assets without location data are not returned.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of the album to retrieve map markers for. Accepts pipeline input.
    .PARAMETER Key
        The shared link key that grants access to the album, if accessing it through a shared link.
    .PARAMETER Slug
        The shared link slug that grants access to the album, if accessing it through a shared link.
    .EXAMPLE
        Get-IMAlbumMapMarker -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retrieves the map markers for all geotagged assets in the specified album.
    .EXAMPLE
        Get-IMAlbum -Name 'Holiday' | Get-IMAlbumMapMarker

        Retrieves the map markers for the album named Holiday.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Key,

        [Parameter()]
        [string]
        $Slug
    )

    process
    {
        $ApiParams = @{
            Id            = $Id
            ImmichSession = $Session
        }
        if ($PSBoundParameters.ContainsKey('Key')) { $ApiParams.Key = $Key }
        if ($PSBoundParameters.ContainsKey('Slug')) { $ApiParams.Slug = $Slug }

        Invoke-ImmichApiGetAlbumMapMarkers @ApiParams | ForEach-Object { [MapMarkerResponseDto]::new($PSItem) }
    }
}
#endregion
