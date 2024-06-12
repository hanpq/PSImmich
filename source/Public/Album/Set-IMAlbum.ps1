function Set-IMAlbum
{
    <#
    .DESCRIPTION
        Updates an Immich album
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines albums to update
    .PARAMETER albumName
        Defines a new album name
    .PARAMETER albumThumbnailAssetId
        Defines a UUID for a new thumbnail asset
    .PARAMETER description
        Defines a new description for the album
    .PARAMETER isActivityEnabled
        Defines weather activity feed should be enabled
    .PARAMETER AddAssets
        Defines assets to add to the album
    .PARAMETER RemoveAssets
        Defines assets to be removed from the album
    .PARAMETER Order
        Defines the sort order for the album
    .EXAMPLE
        Set-IMAlbum -id <albumid> -description 'Trip to New York'

        Update the description of an Immich album
    .EXAMPLE
        Set-IMAlbum -id <albumid> -AddAssets <assetid>,<assetid>

        Adds to assets to the album
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
        $id,

        [Parameter()]
        [string[]]
        $AddAssets,

        [Parameter()]
        [string[]]
        $RemoveAssets,

        [Parameter()]
        [string]
        $albumName,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $albumThumbnailAssetId,

        [Parameter()]
        [string]
        $description,

        [Parameter()]
        [boolean]
        $isActivityEnabled,

        [Parameter()]
        [string]
        [ValidateSet('asc', 'desc')]
        $Order
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'AlbumName', 'albumThumbnailAssetId', 'description', 'isActivityEnabled', 'Order' -namemapping @{AlbumName = 'albumName'; albumThumbnailAssetId = 'albumThumbnailAssetId'; isActivityEnabled = 'isActivityEnabled'; Order = 'order' })
    }

    PROCESS
    {
        $id | ForEach-Object {
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
