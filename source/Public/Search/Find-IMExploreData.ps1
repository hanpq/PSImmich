function Find-IMExploreData
{
    <#
    .SYNOPSIS
        Retrieves data for explore interface.
    .DESCRIPTION
        Gets curated content and suggestions for Immich's explore feature.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .EXAMPLE
        Find-IMExploreData

        Gets explore interface data and suggestions.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method GET -RelativePath '/search/explore' -ImmichSession:$Session -Body $Body

}
#endregion
