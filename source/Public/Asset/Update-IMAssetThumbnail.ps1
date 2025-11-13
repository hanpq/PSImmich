function Update-IMAssetThumbnail
{
    <#
    .SYNOPSIS
        Updates Immich asset thumbnails
    .DESCRIPTION
        Triggers a thumbnail regeneration job for one or more assets, causing Immich to recreate
        thumbnail images. This is useful when thumbnails are corrupted or need to be refreshed.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of the asset(s) to regenerate thumbnails for. Accepts pipeline input and multiple values.
    .EXAMPLE
        Update-IMAssetThumbnail -Id 'asset-uuid'

        Triggers thumbnail regeneration for the specified asset with confirmation prompt.
    .EXAMPLE
        @('asset1-uuid', 'asset2-uuid') | Update-IMAssetThumbnail

        Regenerates thumbnails for multiple assets via pipeline.
    .EXAMPLE
        Get-IMAsset -TagId 'corrupted-thumbs' | Update-IMAssetThumbnail -Confirm:$false

        Regenerates thumbnails for all assets with a specific tag without confirmation.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before regenerating thumbnails.
        The operation creates a background job that may take time to complete for large numbers of assets.
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

    begin
    {
        $BodyParameters = @{
            assetIds = @()
            name     = 'regenerate-thumbnail'
        }
    }

    process
    {
        $Id | ForEach-Object {
            $BodyParameters.assetIds += $psitem
        }
    }

    end
    {
        if ($PSCmdlet.ShouldProcess(($BodyParameters.assetIds -join ','), 'Update thumbnail'))
        {
            InvokeImmichRestMethod -Method POST -RelativePath '/assets/jobs' -ImmichSession:$Session -Body:$BodyParameters
        }
    }

}
#endregion
