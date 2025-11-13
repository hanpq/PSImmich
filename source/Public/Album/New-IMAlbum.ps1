function New-IMAlbum
{
    <#
    .SYNOPSIS
        Creates a new Immich album
    .DESCRIPTION
        Creates a new album in Immich with the specified name and optional properties. Albums can be created with
        initial assets, descriptions, and shared with other users.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER AlbumName
        The name for the new album. This will be displayed in the Immich interface.
    .PARAMETER AssetIds
        An array of asset UUIDs to add to the album during creation.
    .PARAMETER Description
        A description for the album to provide additional context about its contents.
    .PARAMETER AlbumUsers
        An array of user objects to share the album with. Each object should contain 'userId' and 'role' properties.
    .EXAMPLE
        New-IMAlbum -AlbumName 'Family Vacation 2024'

        Creates a new album named 'Family Vacation 2024'.
    .EXAMPLE
        New-IMAlbum -AlbumName 'Wedding Photos' -Description 'Photos from Sarah and John wedding ceremony'

        Creates a new album with a description.
    .EXAMPLE
        $assets = @('asset1-uuid', 'asset2-uuid')
        New-IMAlbum -AlbumName 'Best of 2024' -AssetIds $assets

        Creates a new album and adds specific assets to it.
    .EXAMPLE
        $users = @(@{userId='user1-uuid'; role='editor'}, @{userId='user2-uuid'; role='viewer'})
        New-IMAlbum -AlbumName 'Shared Memories' -AlbumUsers $users

        Creates a new album shared with multiple users with different roles.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ApiParameter('albumName')]
        [string]
        $AlbumName,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('assetIds')]
        [string[]]
        $AssetIds,

        [Parameter()]
        [ApiParameter('description')]
        [string]
        $Description,

        [Parameter()]
        [ApiParameter('albumUsers')]
        [hashtable[]]
        $AlbumUsers
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/albums' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
