function Find-IMPerson
{
    <#
    .DESCRIPTION
        Find people
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Name
        Name filter
    .PARAMETER WithHidden
        Filter hidden
    .EXAMPLE
        Find-IMPerson -Name 'Jim Carrey'

        Search for persons named Jim Carrey
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
