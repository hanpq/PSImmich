function Remove-IMIntegrityReport
{
    <#
    .SYNOPSIS
        Removes an Immich storage integrity report item
    .DESCRIPTION
        Deletes a single storage integrity report item. This only removes the report entry; it does not delete any files on disk.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of the integrity report item to remove. Accepts pipeline input, for example from Get-IMIntegrityReport.
    .EXAMPLE
        Remove-IMIntegrityReport -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Removes the specified integrity report item.
    .EXAMPLE
        Get-IMIntegrityReport -Type 'untracked_file' | Select-Object -ExpandProperty items | Remove-IMIntegrityReport -WhatIf

        Shows which untracked file report items would be removed without removing them.
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
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
        if ($PSCmdlet.ShouldProcess($Id, 'Remove integrity report item'))
        {
            Invoke-ImmichApiDeleteIntegrityReport -Id $Id -ImmichSession $Session
        }
    }
}
