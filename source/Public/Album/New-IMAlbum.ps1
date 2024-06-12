function New-IMAlbum
{
    <#
    .DESCRIPTION
        Adds a new album
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumName
        Defines the name of the new album
    .PARAMETER assetIds
        Defines a list of assets to add to the album
    .PARAMETER description
        Defines a description for the album
    .PARAMETER albumUsers
        Defines a list of user id to share the album to
    .EXAMPLE
        New-IMAlbum -albumName 'Las Vegas'

        Adds a new an album
    .EXAMPLE
        New-IMAlbum -AlbumName 'Las Vegas' -AlbumUsers @{userId='<userid>';role='editor'}

        Adds a new shared album that is shared to a user
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [string]
        $albumName,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $assetIds,

        [Parameter()]
        [string]
        $description,

        [Parameter()]
        [hashtable[]]
        $albumUsers
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'albumName', 'assetIds', 'description', 'albumUsers')
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/albums' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
