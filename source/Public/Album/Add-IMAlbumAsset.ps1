function Add-IMAlbumAsset
{
    <#
    .DESCRIPTION
        Add assets to album
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        Defines albumId to add assets to
    .PARAMETER assetid
        Defines the assetIds to add to the album
    .EXAMPLE
        Add-IMAlbumAsset

        Add assets to album
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [string]
        $albumId,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string[]]
        $assetId
    )

    BEGIN
    {
        $BodyParameters = @{
            ids = [string[]]@()
        }
    }

    PROCESS
    {
        $assetId | ForEach-Object {
            $BodyParameters.ids += $PSItem
        }
    }

    END
    {
        InvokeImmichRestMethod -Method PUT -RelativePath "/album/$albumid/assets" -ImmichSession:$Session -Body:$BodyParameters
    }
}
#endregion
