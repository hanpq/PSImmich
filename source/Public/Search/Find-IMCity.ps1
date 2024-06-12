function Find-IMCity
{
    <#
    .DESCRIPTION
        Find cities
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Find-IMCity

        Retreives all cities
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -Method GET -RelativePath '/search/cities' -ImmichSession:$Session -Body $Body

}
#endregion
