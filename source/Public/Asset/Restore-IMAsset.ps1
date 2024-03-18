function Restore-IMAsset
{
    <#
    .DESCRIPTION
        Restore asset from trash
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines an asset id to tag
    .PARAMETER All
        Defines that all assets in trash should be restored.
    .EXAMPLE
        Restore-IMAsset

        Restore asset from trash
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
        $id,

        [Parameter(Mandatory, ParameterSetName = 'all')]
        [switch]
        $All
    )

    BEGIN
    {
        if ($PSCmdlet.ParameterSetName -eq 'id')
        {
            $AssetIDs = [System.Collections.Generic.List[string]]::New()
        }
    }

    PROCESS
    {
        if ($PSCmdlet.ParameterSetName -eq 'id')
        {
            $id | ForEach-Object {
                $AssetIDs.Add($PSItem)
            }
        }
    }

    END
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
