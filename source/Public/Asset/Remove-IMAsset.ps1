function Remove-IMAsset
{
    <#
    .DESCRIPTION
        Removes an Immich asset
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER ids
        Defines the asset ids that should be removed. Accepts pipeline input.
    .PARAMETER force
        Performs a hard delete bypassing the Trash
    .EXAMPLE
        Remove-IMAsset

        Removes an Immich asset
    .NOTES
        Covers API deleteAssets
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]
        [Alias('id')]
        $ids,

        [Parameter()]
        [switch]
        $force
    )

    BEGIN
    {
        $BodyParameters = @{
            ids = @()
        }
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'force')
    }

    PROCESS
    {
        $ids | ForEach-Object {
            $BodyParameters.ids += $psitem
        }
    }

    END
    {
        if ($PSCmdlet.ShouldProcess(($BodyParameters.ids -join ','), 'DELETE'))
        {
            InvokeImmichRestMethod -Method Delete -RelativePath '/asset' -ImmichSession:$Session -Body:$BodyParameters
        }
    }

}
#endregion
