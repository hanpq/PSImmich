function Remove-IMAsset
{
    <#
    .SYNOPSIS
        Removes Immich assets
    .DESCRIPTION
        Removes one or more assets from Immich. By default, assets are moved to trash and can be restored.
        Use the Force parameter to permanently delete assets, bypassing the trash.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Ids
        The UUID(s) of the asset(s) to remove. Accepts pipeline input and multiple values.
    .PARAMETER Force
        Performs a permanent deletion bypassing the trash. Assets removed with this flag cannot be restored.
    .EXAMPLE
        Remove-IMAsset -Ids 'asset-uuid'

        Moves the specified asset to trash with confirmation prompt.
    .EXAMPLE
        @('asset1-uuid', 'asset2-uuid') | Remove-IMAsset

        Moves multiple assets to trash via pipeline.
    .EXAMPLE
        Remove-IMAsset -Ids 'asset-uuid' -Force

        Permanently deletes the asset, bypassing trash.
    .EXAMPLE
        Get-IMAsset -TagId 'temp-tag' | Remove-IMAsset -Force -Confirm:$false

        Permanently deletes all assets with a specific tag without confirmation.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before removing assets.
        Use caution with the -Force parameter as it permanently deletes assets.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        [Alias('id')]
        $Ids,

        [Parameter()]
        [ApiParameter('force')]
        [switch]
        $Force
    )

    begin
    {
        $BodyParameters = @{
            ids = @()
        }
        $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        $Ids | ForEach-Object {
            $BodyParameters.ids += $psitem
        }
    }

    end
    {
        if ($PSCmdlet.ShouldProcess(($BodyParameters.ids -join ','), 'DELETE'))
        {
            InvokeImmichRestMethod -Method Delete -RelativePath '/assets' -ImmichSession:$Session -Body:$BodyParameters
        }
    }

}
#endregion
