function Update-IMAssetMetadata
{
    <#
    .DESCRIPTION
        Update IM asset metadata
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the asset ids that metadata should be refreshed for. Accepts pipeline input.
    .EXAMPLE
        Update-IMAssetMetadata -id <assetid>

        Update IM asset metadata
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','', Justification='FP')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id
    )

    BEGIN
    {
        $BodyParameters = @{
            assetIds = @()
            name     = 'refresh-metadata'
        }
    }

    PROCESS
    {
        $id | ForEach-Object {
            $BodyParameters.assetIds += $psitem
        }
    }

    END
    {
        if ($PSCmdlet.ShouldProcess(($BodyParameters.assetIds -join ','), 'Update metadata'))
        {
            InvokeImmichRestMethod -Method POST -RelativePath '/assets/jobs' -ImmichSession:$Session -Body:$BodyParameters
        }
    }

}
#endregion
