function Convert-IMCoordinatesToLocation
{
    <#
    .SYNOPSIS
        Converts GPS coordinates to a human-readable location name.
    .DESCRIPTION
        The Convert-IMCoordinatesToLocation function performs reverse geocoding to convert
        GPS latitude and longitude coordinates into a human-readable location name or address.
        This is useful for adding location context to assets that have GPS metadata but lack
        descriptive location information.

        The function uses Immich's geocoding service to translate coordinate pairs into
        location names, which can help with organizing and searching assets by location.
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Latitude
        Specifies the latitude coordinate in decimal degrees format. Positive values represent
        locations north of the equator, while negative values represent locations south of the equator.
        Valid range is -90 to +90 degrees.
    .PARAMETER Longitude
        Specifies the longitude coordinate in decimal degrees format. Positive values represent
        locations east of the Prime Meridian, while negative values represent locations west.
        Valid range is -180 to +180 degrees.
    .EXAMPLE
        Convert-IMCoordinatesToLocation -Latitude 51.496637 -Longitude -0.176370

        Converts the coordinates for a location in London, UK to a human-readable address.
    .EXAMPLE
        Convert-IMCoordinatesToLocation -Latitude 40.7128 -Longitude -74.0060

        Converts coordinates for New York City to a location name.
    .EXAMPLE
        $coords = @{Latitude = 37.7749; Longitude = -122.4194}
        Convert-IMCoordinatesToLocation @coords

        Uses splatting to convert San Francisco coordinates to a location name.
    .EXAMPLE
        # Convert multiple coordinates from asset metadata
        $assets | Where-Object {$_.exifInfo.latitude -and $_.exifInfo.longitude} |
            ForEach-Object { Convert-IMCoordinatesToLocation -Latitude $_.exifInfo.latitude -Longitude $_.exifInfo.longitude }

        Processes multiple assets to convert their GPS coordinates to location names.
    .NOTES
        This function requires an active internet connection and access to geocoding services.
        Coordinate precision affects the accuracy of the returned location information.
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ApiParameter('lat')]
        [double]
        $Latitude,

        [Parameter(Mandatory)]
        [ApiParameter('lon')]
        [double]
        $Longitude
    )

    $QueryParameters = @{}
    $QueryParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)

    InvokeImmichRestMethod -Method Get -RelativePath '/map/reverse-geocode' -ImmichSession:$Session -QueryParameters $QueryParameters

}
#endregion
