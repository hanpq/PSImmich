function Find-IMPlace
{
    <#
    .DESCRIPTION
        Find places
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Name
        Name filter
    .EXAMPLE
        Find-IMPlace -name 'Stockholm'

        Search for places named Stockholm
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null,

        [Parameter()]
        [string]$name
    )

    $Body = @{}
    $Body += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'name')

    InvokeImmichRestMethod -Method GET -RelativePath '/search/places' -ImmichSession:$Session -Body $Body

}
#endregion
