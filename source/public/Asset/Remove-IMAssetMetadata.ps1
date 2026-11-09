function Remove-IMAssetMetadata
{
    <#
    .SYNOPSIS
        Removes custom key/value metadata from Immich assets
    .DESCRIPTION
        Deletes the metadata entries with the given key(s) from one or more assets in a single bulk request.
        Use Set-IMAssetMetadata to create or update entries.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of the asset(s) to remove the metadata from. Accepts pipeline input and multiple values.
    .PARAMETER Key
        The metadata key(s) to remove.
    .EXAMPLE
        Remove-IMAssetMetadata -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Key 'mobile-app'

        Removes the 'mobile-app' metadata entry from the specified asset.
    .EXAMPLE
        Get-IMAsset -TagId 'vacation-tag' | Remove-IMAssetMetadata -Key 'reviewed' -Confirm:$false

        Removes the 'reviewed' metadata entry from all assets with a specific tag without confirmation.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before removing metadata.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Metadata is an uncountable noun.')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Key
    )

    begin
    {
        $Items = [System.Collections.Generic.List[hashtable]]::new()
    }

    process
    {
        $Id | ForEach-Object {
            $CurrentId = $PSItem
            $Key | ForEach-Object {
                $Items.Add(@{ assetId = $CurrentId; key = $PSItem })
            }
        }
    }

    end
    {
        if ($Items.Count -gt 0 -and $PSCmdlet.ShouldProcess(($Items.assetId -join ','), "Remove metadata '$($Key -join ',')'"))
        {
            Invoke-ImmichApiDeleteBulkAssetMetadata -Body @{ items = $Items.ToArray() } -ImmichSession $Session
        }
    }
}
#endregion
