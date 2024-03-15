﻿function Set-IMAlbum
{
    <#
    .DESCRIPTION
        Updates an Immich album
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER ids
        Defines ids to update
    .PARAMETER albumName
        Defines a new album name
    .PARAMETER albumThumbnailAssetId
        Defines a UUID for a new thumbnail asset
    .PARAMETER description
        Defines a new description for the album
    .PARAMETER isActivityEnabled
        Defines weather activity feed should be enabled
    .EXAMPLE
        Set-IMAlbum

        Update an Immich album
    .NOTES
        Covers updateAssets, updateAsset
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('id', 'albumId')]
        [string[]]
        $ids,

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
        $isActivityEnabled
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'albumName', 'albumThumbnailAssetId', 'description', 'isActivityEnabled')
    }

    PROCESS
    {
        $ids | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'Update'))
            {
                InvokeImmichRestMethod -Method PATCH -RelativePath "/album/$PSItem" -ImmichSession:$Session -Body:$BodyParameters
            }
        }
    }
}
#endregion
