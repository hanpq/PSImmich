function Remove-IMSharedLinkAsset
{
    <#
    .SYNOPSIS
        Removes assets from a shared link.
    .DESCRIPTION
        Removes specific assets from an existing shared link.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Asset IDs to remove from the shared link.
    .PARAMETER SharedLinkId
        Shared link ID to modify.
    .EXAMPLE
        Remove-IMSharedLinkAsset -Id 'asset-id' -SharedLinkId 'link-id'

        Removes asset from shared link.

        Remove Immich shared link asset
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $SharedLinkId
    )

    begin
    {
        $AssetIDs = [System.Collections.Generic.List[string]]::New()
    }

    process
    {
        $id | ForEach-Object {
            $AssetIDs.Add($PSItem)
        }
    }

    end
    {
        $Body = @{
            assetIds = $AssetIDs
        }
        InvokeImmichRestMethod -Method DELETE -RelativePath "/shared-links/$SharedLinkId/assets" -ImmichSession:$Session -Body $Body
    }
}
#endregion
