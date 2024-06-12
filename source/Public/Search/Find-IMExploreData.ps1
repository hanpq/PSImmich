function Find-IMExploreData
{
    <#
    .DESCRIPTION
        Find explore data
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Find-IMExploreData

        Retreives explore data
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method GET -RelativePath '/search/explore' -ImmichSession:$Session -Body $Body

}
#endregion
