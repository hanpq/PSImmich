function Rename-IMTag
{
    <#
    .DESCRIPTION
        Remove Immich tag
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific tag id to be renamed
    .PARAMETER NewName
        Defines a new name for the tag
    .EXAMPLE
        Rename-IMTag -id <tagid> -NewName 'Cats'

        Remove Immich tag
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $id,

        [Parameter(Mandatory)]
        [string]
        $NewName

    )

    $BodyParameters = @{}
    $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'NewName' -NameMapping:@{NewName = 'name' })
    InvokeImmichRestMethod -Method PATCH -RelativePath "/tags/$id" -ImmichSession:$Session -Body:$BodyParameters
}
#endregion
