function Restore-IMAsset
{
    <#
    .SYNOPSIS
        Restores Immich assets from trash
    .DESCRIPTION
        Restores one or more assets from the Immich trash back to the active library. Assets in trash
        can be restored individually by ID or all trash items can be restored at once.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of specific asset(s) to restore from trash. Accepts pipeline input and multiple values.
    .PARAMETER All
        Restores all assets currently in trash back to the active library.
    .EXAMPLE
        Restore-IMAsset -Id 'asset-uuid'

        Restores a specific asset from trash with confirmation prompt.
    .EXAMPLE
        @('asset1-uuid', 'asset2-uuid') | Restore-IMAsset

        Restores multiple specific assets from trash via pipeline.
    .EXAMPLE
        Restore-IMAsset -All

        Restores all assets currently in trash.
    .EXAMPLE
        Restore-IMAsset -Id 'asset-uuid' -Confirm:$false

        Restores an asset without confirmation prompt.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before restoring assets.
        Use Get-IMTrash to view assets currently in trash before restoring.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP')]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'id')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'id')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('assetId')]
        [string[]]
        $Id,

        [Parameter(Mandatory, ParameterSetName = 'all')]
        [switch]
        $All
    )

    begin
    {
        if ($PSCmdlet.ParameterSetName -eq 'id')
        {
            $AssetIDs = [System.Collections.Generic.List[string]]::New()
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'id')
        {
            $Id | ForEach-Object {
                $AssetIDs.Add($PSItem)
            }
        }
    }

    end
    {
        switch ($PSCMdlet.ParameterSetName)
        {
            'id'
            {
                if ($PSCmdlet.ShouldProcess(($AssetIDs -join ','), 'Restore'))
                {
                    $BodyParameters = @{
                        ids = ($AssetIDs -as [string[]])
                    }
                    InvokeImmichRestMethod -Method POST -RelativePath '/trash/restore/assets' -ImmichSession:$Session -Body:$BodyParameters
                }
            }
            'all'
            {
                if ($PSCmdlet.ShouldProcess('All trashed assets', 'Restore'))
                {
                    InvokeImmichRestMethod -Method POST -RelativePath '/trash/restore' -ImmichSession:$Session
                }
            }
        }
    }
}
#endregion
