function Remove-IMAssetEdit
{
    <#
    .SYNOPSIS
        Removes all non-destructive edits from an Immich asset
    .DESCRIPTION
        Removes every edit action (crop, rotate, mirror) stored for an asset, restoring the asset to its original appearance.
        The original file is not modified.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of the asset whose edits to remove. Accepts pipeline input.
    .EXAMPLE
        Remove-IMAssetEdit -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Removes all edits from the specified asset after confirmation.
    .EXAMPLE
        Get-IMAsset -TagId 'vacation-tag' | Remove-IMAssetEdit -Confirm:$false

        Removes all edits from every asset with a specific tag without confirmation.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before removing edits.
    #>
    [CmdletBinding(SupportsShouldProcess)]
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
        if ($PSCmdlet.ShouldProcess($Id, 'Remove asset edits'))
        {
            Invoke-ImmichApiRemoveAssetEdits -Id $Id -ImmichSession $Session
        }
    }
}
#endregion
