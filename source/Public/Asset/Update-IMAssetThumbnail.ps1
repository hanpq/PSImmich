function Update-IMAssetThumbnail
{
    <#
    .DESCRIPTION
        Update IM asset thumbnails
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the asset ids that thumbnails should be refreshed for. Accepts pipeline input.
    .EXAMPLE
        Update-IMAssetThumbnail -id <assetid>

        Update IM asset thumbnails
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id
    )

    BEGIN
    {
        $BodyParameters = @{
            assetIds = @()
            name     = 'regenerate-thumbnail'
        }
    }

    PROCESS
    {
        $Id | ForEach-Object {
            $BodyParameters.assetIds += $psitem
        }
    }

    END
    {
        if ($PSCmdlet.ShouldProcess(($BodyParameters.assetIds -join ','), 'Update thumbnail'))
        {
            InvokeImmichRestMethod -Method POST -RelativePath '/assets/jobs' -ImmichSession:$Session -Body:$BodyParameters
        }
    }

}
#endregion
