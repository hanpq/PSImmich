function Set-IMAlbum
{
    <#
    .SYNOPSIS
        Updates an Immich album
    .DESCRIPTION
        Updates various properties of an Immich album including name, description, thumbnail, activity settings,
        and manages assets within the album. Supports adding and removing assets in a single operation.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of the album(s) to update. Accepts pipeline input and multiple values.
    .PARAMETER AlbumName
        The new name for the album.
    .PARAMETER AlbumThumbnailAssetId
        The UUID of an asset to use as the album thumbnail.
    .PARAMETER Description
        The new description for the album.
    .PARAMETER IsActivityEnabled
        Specifies whether the activity feed should be enabled for the album.
    .PARAMETER AddAssets
        An array of asset UUIDs to add to the album.
    .PARAMETER RemoveAssets
        An array of asset UUIDs to remove from the album.
    .PARAMETER Order
        Defines the sort order for assets in the album.
    .EXAMPLE
        Set-IMAlbum -Id 'album-uuid' -Description 'Family vacation photos from summer 2024'

        Updates the album description.
    .EXAMPLE
        Set-IMAlbum -Id 'album-uuid' -AddAssets @('asset1-uuid', 'asset2-uuid')

        Adds two assets to the album.
    .EXAMPLE
        Set-IMAlbum -Id 'album-uuid' -AlbumName 'Vacation 2024' -IsActivityEnabled:$true

        Renames the album and enables the activity feed.
    .EXAMPLE
        Set-IMAlbum -Id 'album-uuid' -AddAssets @('new-asset') -RemoveAssets @('old-asset')

        Adds one asset and removes another in a single operation.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before making changes.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('ids', 'albumId')]
        [string[]]
        $Id,

        [Parameter()]
        [string[]]
        $AddAssets,

        [Parameter()]
        [string[]]
        $RemoveAssets,

        [Parameter()]
        [ApiParameter('albumName')]
        [string]
        $AlbumName,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('albumThumbnailAssetId')]
        [string]
        $AlbumThumbnailAssetId,

        [Parameter()]
        [ApiParameter('description')]
        [string]
        $Description,

        [Parameter()]
        [ApiParameter('isActivityEnabled')]
        [boolean]
        $IsActivityEnabled,

        [Parameter()]
        [ApiParameter('order')]
        [string]
        [ValidateSet('asc', 'desc')]
        $Order
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        $Id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'Update'))
            {
                InvokeImmichRestMethod -Method PATCH -RelativePath "/albums/$PSItem" -ImmichSession:$Session -Body:$BodyParameters

                if ($PSBoundParameters.ContainsKey('AddAssets'))
                {
                    $null = InvokeImmichRestMethod -Method PUT -RelativePath "/albums/$PSItem/assets" -ImmichSession:$Session -Body:@{ids = [string[]]$AddAssets }
                }
                if ($PSBoundParameters.ContainsKey('RemoveAssets'))
                {
                    $null = InvokeImmichRestMethod -Method DELETE -RelativePath "/albums/$PSItem/assets" -ImmichSession:$Session -Body:@{ids = [string[]]$RemoveAssets }
                }
            }
        }
    }
}
#endregion
