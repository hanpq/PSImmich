function Convert-IMCoordinatesToLocation
{
    <#
    .DESCRIPTION
        Converts coordinates to a location
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Latitude
        Defines the latitude part of the coordinate.
    .PARAMETER Longitude
        Defines the longitude part of the coordinate.
    .EXAMPLE
        Convert-IMCoordinatesToLocation -Latitude 51.496637 -Longitude -0.176370

        Converts the specified coordinates to a location.
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
