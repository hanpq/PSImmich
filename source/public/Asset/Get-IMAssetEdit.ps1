function Get-IMAssetEdit
{
    <#
    .SYNOPSIS
        Retrieves the non-destructive edits applied to an Immich asset
    .DESCRIPTION
        Retrieves the list of edit actions (crop, rotate, mirror) that are stored for an asset.
        Edits are applied by Immich for display and do not modify the original file.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of the asset whose edits to retrieve. Accepts pipeline input.
    .EXAMPLE
        Get-IMAssetEdit -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retrieves the edit actions stored for the specified asset.
    .EXAMPLE
        Get-IMAsset -TagId 'vacation-tag' | Get-IMAssetEdit

        Retrieves the edit actions for all assets with a specific tag.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id
    )

    process
    {
        Invoke-ImmichApiGetAssetEdits -Id $Id -ImmichSession $Session | ForEach-Object { [AssetEditsResponseDto]::new($PSItem) }
    }
}
#endregion
