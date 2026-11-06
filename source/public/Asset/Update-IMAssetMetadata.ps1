function Update-IMAssetMetadata
{
    <#
    .SYNOPSIS
        Updates Immich asset metadata
    .DESCRIPTION
        Triggers a metadata refresh job for one or more assets, causing Immich to re-extract and update
        metadata information such as EXIF data, location, and other file properties.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of the asset(s) to refresh metadata for. Accepts pipeline input and multiple values.
    .EXAMPLE
        Update-IMAssetMetadata -Id 'asset-uuid'

        Triggers metadata refresh for the specified asset with confirmation prompt.
    .EXAMPLE
        @('asset1-uuid', 'asset2-uuid') | Update-IMAssetMetadata

        Refreshes metadata for multiple assets via pipeline.
    .EXAMPLE
        Get-IMAsset -TagId 'needs-update' | Update-IMAssetMetadata -Confirm:$false

        Refreshes metadata for all assets with a specific tag without confirmation.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before updating metadata.
        The operation creates a background job that may take time to complete for large numbers of assets.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'FP')]
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
            name     = 'refresh-metadata'
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
        if ($PSCmdlet.ShouldProcess(($BodyParameters.assetIds -join ','), 'Update metadata'))
        {
            InvokeImmichRestMethod -Method POST -RelativePath '/assets/jobs' -ImmichSession:$Session -Body:$BodyParameters
        }
    }

}
#endregion
