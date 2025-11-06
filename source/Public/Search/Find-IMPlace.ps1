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
        Find-IMPlace -Name 'Stockholm'

        Search for places named Stockholm
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null,

        [Parameter(Mandatory)]
        [ApiParameter('name')]
        [string]$Name
    )

    $Query = @{}
    $Query += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)

    InvokeImmichRestMethod -Method GET -RelativePath '/search/places' -ImmichSession:$Session -QueryParameters:$Query | AddCustomType IMPlace

}
#endregion
