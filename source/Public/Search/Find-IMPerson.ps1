function Find-IMPerson
{
    <#
    .SYNOPSIS
        Searches for people by name or visibility.
    .DESCRIPTION
        Finds person records using name filtering and hidden status options.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Name
        Search by person name (supports partial matches).
    .PARAMETER WithHidden
        Include hidden people when $true, exclude when $false.
    .EXAMPLE
        Find-IMPerson -Name 'John'

        Searches for people with 'John' in their name.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null,

        [Parameter(Mandatory)]
        [ApiParameter('name')]
        [string]$Name,

        [Parameter()]
        [ApiParameter('withHidden')]
        [boolean]$WithHidden
    )

    $Query = @{}
    $Query += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)

    InvokeImmichRestMethod -Method GET -RelativePath '/search/person' -ImmichSession:$Session -QueryParameters:$Query

}
#endregion
