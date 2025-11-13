function Find-IMPlace
{
    <#
    .SYNOPSIS
        Searches for places by name.
    .DESCRIPTION
        Finds geographic locations from asset GPS metadata by name.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Name
        Place name to search for (supports partial matches).
    .EXAMPLE
        Find-IMPlace -Name 'Paris'

        Searches for places containing 'Paris' in the name.
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
