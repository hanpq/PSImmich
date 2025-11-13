function Add-IMSharedLinkAsset
{
    <#
    .SYNOPSIS
        Adds assets to an existing shared link.
    .DESCRIPTION
        Expands shared link content by adding more assets to it.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Asset IDs to add to the shared link.
    .PARAMETER SharedLinkId
        Shared link ID to modify.
    .EXAMPLE
        Add-IMSharedLinkAsset -SharedLinkId 'link-id' -Id 'asset1', 'asset2'

        Adds assets to existing shared link.
    .NOTES
        Supports -WhatIf and -Confirm for safety.
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
        InvokeImmichRestMethod -Method PUT -RelativePath "/shared-links/$SharedLinkId/assets" -ImmichSession:$Session -Body $Body
    }
}
#endregion
