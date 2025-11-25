function Remove-IMDuplicate
{
    <#
    .SYNOPSIS
        Removes duplicate asset groups from Immich
    .DESCRIPTION
        Removes one or more duplicate asset groups from Immich. This function uses the bulk delete endpoint
        to efficiently remove multiple duplicates. When duplicates are removed, Immich will keep one asset
        from each duplicate group and remove the others.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Ids
        The UUID(s) of the duplicate group(s) to remove. Accepts pipeline input and multiple values.
        These are the duplicate group IDs returned by Get-IMDuplicate, not individual asset IDs.
    .EXAMPLE
        Remove-IMDuplicate -Ids 'duplicate-group-uuid'

        Removes the specified duplicate group with confirmation prompt.
    .EXAMPLE
        @('duplicate1-uuid', 'duplicate2-uuid') | Remove-IMDuplicate

        Removes multiple duplicate groups via pipeline.
    .EXAMPLE
        Get-IMDuplicate | Remove-IMDuplicate -Confirm:$false

        Removes all duplicate groups without confirmation prompts.
    .EXAMPLE
        Remove-IMDuplicate -Ids 'duplicate-group-uuid' -WhatIf

        Shows what would be removed without actually performing the deletion.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before removing duplicates.
        The function removes duplicate groups, not individual assets. Immich determines which assets
        to keep and which to remove within each duplicate group.
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
        $Ids
    )

    begin
    {
        $BodyParameters = @{
            ids = @()
        }
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
            InvokeImmichRestMethod -Method Delete -RelativePath '/duplicates' -ImmichSession:$Session -Body:$BodyParameters
        }
    }

}
#endregion
