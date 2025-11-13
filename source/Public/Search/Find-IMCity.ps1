function Find-IMCity
{
    <#
    .SYNOPSIS
        Retrieves all cities from asset GPS metadata.
    .DESCRIPTION
        Gets list of cities extracted from photo GPS data for location-based searches.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .EXAMPLE
        Find-IMCity

        Lists all cities found in asset metadata.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method GET -RelativePath '/search/cities' -ImmichSession:$Session -Body $Body

}
#endregion
