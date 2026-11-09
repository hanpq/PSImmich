function Set-IMAssetEdit
{
    <#
    .SYNOPSIS
        Replaces the non-destructive edits applied to an Immich asset
    .DESCRIPTION
        Replaces the full list of edit actions stored for an asset. Each edit is a hashtable with an
        action (crop, rotate or mirror) and matching parameters. Passing an empty list is not possible;
        use Remove-IMAssetEdit to clear all edits.
        The original file is not modified.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of the asset to edit. Accepts pipeline input.
    .PARAMETER Edit
        One or more edit actions. Each action is a hashtable with an 'action' key (crop, rotate or mirror)
        and a 'parameters' key:
        - crop: x, y, width, height
        - rotate: angle (0-270)
        - mirror: axis (horizontal or vertical)
    .EXAMPLE
        Set-IMAssetEdit -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Edit @{ action = 'rotate'; parameters = @{ angle = 90 } }

        Rotates the asset by 90 degrees.
    .EXAMPLE
        $Edits = @(
            @{ action = 'crop'; parameters = @{ x = 0; y = 0; width = 800; height = 600 } }
            @{ action = 'mirror'; parameters = @{ axis = 'horizontal' } }
        )
        Set-IMAssetEdit -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Edit $Edits

        Crops the asset and then mirrors it horizontally.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable[]]
        $Edit
    )

    process
    {
        if ($PSCmdlet.ShouldProcess($Id, 'Replace asset edits'))
        {
            $Body = @{
                edits = @($Edit | ForEach-Object { [AssetEditActionItemDto]::new($PSItem) })
            }

            Invoke-ImmichApiEditAsset -Id $Id -Body $Body -ImmichSession $Session | ForEach-Object { [AssetEditsResponseDto]::new($PSItem) }
        }
    }
}
#endregion
