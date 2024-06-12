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
    .PARAMETER withHidden
        Filter hidden
    .EXAMPLE
        Find-IMPerson -name 'Jim Carrey'

        Search for persons named Jim Carrey
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null,

        [Parameter()]
        [string]$name,

        [Parameter()]
        [boolean]$withHidden
    )

    $Body = @{}
    $Body += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'name', 'withHidden')

    InvokeImmichRestMethod -Method GET -RelativePath '/search/person' -ImmichSession:$Session -Body $Body

}
#endregion
