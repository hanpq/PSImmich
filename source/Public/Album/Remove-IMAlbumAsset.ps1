function Remove-IMAlbumAsset
{
    <#
    .DESCRIPTION
        Remove assets from album
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        Defines albumId to remove assets from
    .PARAMETER assetid
        Defines the assetIds to remove from the album
    .EXAMPLE
        Remove-IMAlbumAsset

        Remove assets from album
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $albumId,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
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
        if ($PSCmdlet.ShouldProcess(($BodyParameters.ids -join ','), 'DELETE'))
        {
            InvokeImmichRestMethod -Method DELETE -RelativePath "/album/$albumid/assets" -ImmichSession:$Session -Body:$BodyParameters
        }
    }
}
#endregion
