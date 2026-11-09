function Set-IMAssetMetadata
{
    <#
    .SYNOPSIS
        Sets custom key/value metadata on Immich assets
    .DESCRIPTION
        Creates or updates a metadata entry with the given key and value on one or more assets.
        Each asset ID is paired with the key and value in a single bulk request. Existing entries
        with the same key are replaced. Use Remove-IMAssetMetadata to delete entries.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of the asset(s) to set the metadata on. Accepts pipeline input and multiple values.
    .PARAMETER Key
        The metadata key to set.
    .PARAMETER Value
        The metadata value to store. Can be any value that serializes to JSON.
    .EXAMPLE
        Set-IMAssetMetadata -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Key 'mobile-app' -Value @{ note = 'imported' }

        Sets the 'mobile-app' metadata entry on the specified asset.
    .EXAMPLE
        Get-IMAsset -TagId 'vacation-tag' | Set-IMAssetMetadata -Key 'reviewed' -Value $true -Confirm:$false

        Sets the 'reviewed' metadata entry on all assets with a specific tag without confirmation.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before changing metadata.
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
        [string]
        $Key,

        [Parameter(Mandatory)]
        [AllowNull()]
        [object]
        $Value
    )

    begin
    {
        $Items = [System.Collections.Generic.List[hashtable]]::new()
    }

    process
    {
        $Id | ForEach-Object {
            $Items.Add(@{ assetId = $PSItem; key = $Key; value = $Value })
        }
    }

    end
    {
        if ($Items.Count -gt 0 -and $PSCmdlet.ShouldProcess(($Items.assetId -join ','), "Set metadata '$Key'"))
        {
            Invoke-ImmichApiUpdateBulkAssetMetadata -Body @{ items = $Items.ToArray() } -ImmichSession $Session
        }
    }
}
#endregion
