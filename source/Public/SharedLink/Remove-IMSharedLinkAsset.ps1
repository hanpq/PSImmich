function Remove-IMSharedLinkAsset
{
    <#
    .DESCRIPTION
        Remove Immich shared link asset
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines assets to add to the shared link
    .PARAMETER SharedLinkId
        Defines a shared link to add assets to
    .EXAMPLE
        Remove-IMSharedLinkAsset -id <assetid> -sharedlinkid <sharedlinkid>

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

    BEGIN
    {
        $AssetIDs = [System.Collections.Generic.List[string]]::New()
    }

    PROCESS
    {
        $id | ForEach-Object {
            $AssetIDs.Add($PSItem)
        }
    }

    END
    {
        $Body = @{
            assetIds = $AssetIDs
        }
        InvokeImmichRestMethod -Method DELETE -RelativePath "/shared-links/$SharedLinkId/assets" -ImmichSession:$Session -Body $Body
    }
}
#endregion
